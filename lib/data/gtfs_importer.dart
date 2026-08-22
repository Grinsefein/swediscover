import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'app_database.dart';

/// Importiert den täglichen GTFS-Sweden-3-Zip in die lokale Drift/SQLite-DB.
///
/// Die komplette Pipeline ist speichereffizient gestreamt:
///  - Download: `response.stream` -> Temp-Datei (+ `.meta` mit erwarteter
///    Größe für Neustart-Erkennung), nichts im RAM gepuffert
///  - Zip: lazy geöffnet (`InputFileStream` + `decodeStream`); benötigte
///    Einträge werden per `writeContent` **auf Platte** dekomprimiert –
///    `getContent()` wäre hier ein RAM-Fallback und lädt ganze Einträge
///  - CSV: zeilenweise via `CsvToListConverter.bind(Stream<String>)`
///  - DB: Batches à [_batchSize] Zeilen innerhalb *einer* Transaktion
///    (RAM bleibt klein, Abbruch rollt atomar zurück)
///
/// Bewusst NICHT importiert werden `stop_times.txt` (~663 MB) und
/// `shapes.txt` (~2,4 GB): keine Query in der App liest `StopTimes`/`Shapes`.
/// Der Offline-Modus deckt Stopsuche/-details ab; Trip-Details inkl.
/// Shape-Polylines liefert der Backend-Job `/api/trip-details/{vehicleId}`.
class GtfsImporter {
  const GtfsImporter(this._db, {Directory? tempDir})
      : _tempDirOverride = tempDir;

  final AppDatabase _db;

  /// Überschreibt das System-Temp-Verzeichnis (für Tests).
  final Directory? _tempDirOverride;

  /// Zeilen pro Drift-Batch.
  static const int _batchSize = 5000;

  Future<Directory> get _tmp async =>
      _tempDirOverride ?? await getTemporaryDirectory();

  /// Lädt das GTFS-ZIP direkt von Trafiklab (GTFS Sweden) und importiert es.
  /// Korrekte URL per gtfsSwedenStatic.yaml: opendata.samtrafiken.se
  /// Auth via Query ?key= (nicht Header), benötigt Accept-Encoding: gzip
  /// (setzt dart:io implizit und dekomprimiert transparent).
  ///
  /// [onProgress] optionaler Fortschritts-Callback (Phase, ggf. 0..1).
  Future<GtfsImportResult> importFromTrafiklab(
    String apiKey, {
    GtfsImportProgress? onProgress,
  }) async {
    final url = Uri.parse(
      'https://opendata.samtrafiken.se/gtfs-sweden/sweden.zip?key=$apiKey',
    );

    final tmpDir = await _tmp;
    final zipFile = File('${tmpDir.path}/sweden.zip.tmp');
    final metaFile = File('${zipFile.path}.meta');

    // Vollständigen Download aus einem vorherigen Lauf wiederverwenden,
    // statt erneut mehrere hundert MB zu laden.
    if (await _isCompleteDownload(zipFile, metaFile)) {
      return _importZipFile(zipFile, onProgress: onProgress);
    }
    await _cleanupTemp(zipFile, metaFile);

    onProgress?.call(GtfsImportPhase.download);
    final client = http.Client();
    try {
      final response = await client.send(http.Request('GET', url)).timeout(
            const Duration(seconds: 60),
          );

      if (response.statusCode != 200) {
        throw Exception(
          'GTFS-Download fehlgeschlagen: HTTP ${response.statusCode}',
        );
      }

      // Erwartete Größe persistieren, damit ein späterer Start eine bei z.B.
      // 99% abgebrochene Datei zuverlässig als unvollständig erkennt.
      final expectedLength = response.contentLength;
      await metaFile.writeAsString('${expectedLength ?? -1}');

      var received = 0;
      final sink = zipFile.openWrite();
      try {
        await response.stream
            .map((chunk) {
              received += chunk.length;
              if (expectedLength != null) {
                onProgress?.call(
                  GtfsImportPhase.download,
                  progress: received / expectedLength,
                );
              }
              return chunk;
            })
            .pipe(sink)
            .timeout(const Duration(seconds: 540));
      } on Object {
        await sink.close();
        await _cleanupTemp(zipFile, metaFile);
        rethrow;
      }

      if (expectedLength != null && received != expectedLength) {
        await _cleanupTemp(zipFile, metaFile);
        throw Exception(
          'GTFS-Download unvollständig: $received von $expectedLength Bytes',
        );
      }

      return await _importZipFile(zipFile, onProgress: onProgress);
    } finally {
      await _cleanupTemp(zipFile, metaFile);
      client.close();
    }
  }

  /// Kompatibilitäts-Wrapper für bestehende Aufrufer/Tests mit In-Memory-
  /// Bytes. Schreibt die Bytes in eine Temp-Datei und delegiert in die
  /// Streaming-Pipeline.
  Future<GtfsImportResult> importZip(AppDatabase db, List<int> zipBytes) async {
    final tmpDir = await _tmp;
    final zipFile = File('${tmpDir.path}/sweden.zip.inmemory.tmp');
    await zipFile.writeAsBytes(Uint8List.fromList(zipBytes), flush: true);
    try {
      return await _importZipFile(zipFile);
    } finally {
      if (await zipFile.exists()) await zipFile.delete();
    }
  }

  Future<GtfsImportResult> _importZipFile(
    File zipFile, {
    GtfsImportProgress? onProgress,
  }) async {
    final tmpDir = await _tmp;

    final input = InputFileStream(zipFile.path, bufferSize: 256 * 1024);
    late final Archive archive;
    final extracted = <String, File>{};
    try {
      // Liest nur das Central Directory; die Eintrags-Views bleiben lazily
      // über denselben FileBuffer mit der Datei verbunden und dürfen daher
      // erst nach der Extraktion geschlossen werden.
      archive = ZipDecoder().decodeStream(input);

      onProgress?.call(GtfsImportPhase.parse);

      // Benötigte Einträge auf Platte dekomprimieren (gestreamt, nicht im RAM),
      // bevor die DB-Transaktion startet.
      for (final name
          in const ['agency.txt', 'stops.txt', 'routes.txt', 'trips.txt']) {
        final entry = archive.findFile(name);
        if (entry == null || entry.size <= 0) continue;
        final outFile = File('${tmpDir.path}/gtfs_$name.tmp');
        final output = OutputFileStream(outFile.path);
        try {
          entry.writeContent(output);
        } finally {
          output.closeSync();
        }
        extracted[name] = outFile;
      }

      final counts = <String, int>{};
      await _db.transaction(() async {
        // Alte Daten löschen; die eine Transaktion stellt sicher, dass bei
        // Abbruch weder halbe Tabellen noch Leerstand zurückbleibt.
        await _db.delete(_db.stopTimes).go();
        await _db.delete(_db.shapes).go();
        await _db.delete(_db.trips).go();
        await _db.delete(_db.routes).go();
        await _db.delete(_db.stops).go();
        await _db.delete(_db.agencies).go();

        counts['agencies'] = await _importCsvFile(
          extracted['agency.txt'], _db.agencies, _buildAgency,
        );
        counts['stops'] = await _importCsvFile(
          extracted['stops.txt'], _db.stops, _buildStop,
        );
        counts['routes'] = await _importCsvFile(
          extracted['routes.txt'], _db.routes, _buildRoute,
        );
        counts['trips'] = await _importCsvFile(
          extracted['trips.txt'], _db.trips, _buildTrip,
        );
      });

      await _db.reindexAllStopsFts();

      return GtfsImportResult(
        agencies: counts['agencies'] ?? 0,
        stops: counts['stops'] ?? 0,
        routes: counts['routes'] ?? 0,
        trips: counts['trips'] ?? 0,
        stopTimes: 0,
        shapes: 0,
      );
    } finally {
      input.closeSync();
      for (final file in extracted.values) {
        if (await file.exists()) await file.delete();
      }
    }
  }

  /// Streamt eine CSV-Datei zeilenweise als Header->Wert-Maps und fügt sie
  /// in Batches à [_batchSize] ein. Liefert die Anzahl der eingefügten Zeilen.
  Future<int> _importCsvFile<T extends Table, D>(
    File? csvFile,
    TableInfo<T, D> table,
    Insertable<D>? Function(Map<String, String> row) buildRow,
  ) async {
    if (csvFile == null || !await csvFile.exists()) return 0;

    Map<String, int>? header;
    var count = 0;
    var buffer = <Insertable<D>>[];

    final rows = const CsvDecoder()
        .bind(csvFile.openRead().transform(const Utf8Decoder()));

    await for (final fields in rows) {
      if (header == null) {
        header = {
          for (var i = 0; i < fields.length; i++)
            '${fields[i]}'.replaceAll('\uFEFF', '').trim(): i,
        };
        continue;
      }
      final companion = buildRow({
        for (final entry in header.entries)
          entry.key:
              entry.value < fields.length ? '${fields[entry.value]}'.trim() : '',
      });
      if (companion == null) continue;
      buffer.add(companion);
      count++;
      if (buffer.length >= _batchSize) {
        await _flush(table, buffer);
        buffer = <Insertable<D>>[];
      }
    }
    if (buffer.isNotEmpty) await _flush(table, buffer);
    return count;
  }

  Future<void> _flush<T extends Table, D>(
    TableInfo<T, D> table,
    List<Insertable<D>> rows,
  ) async {
    await _db.batch((batch) {
      for (final row in rows) {
        batch.insert(table, row, mode: InsertMode.insertOrReplace);
      }
    });
  }

  AgenciesCompanion _buildAgency(Map<String, String> row) => AgenciesCompanion(
        agencyId: Value(row['agency_id']?.isNotEmpty == true
            ? row['agency_id']!
            : 'unknown'),
        agencyName: Value(row['agency_name'] ?? ''),
        agencyUrl: Value(row['agency_url']),
        agencyTimezone: Value(row['agency_timezone'] ?? 'Europe/Stockholm'),
      );

  StopsCompanion? _buildStop(Map<String, String> row) {
    final stopId = row['stop_id'] ?? '';
    if (stopId.isEmpty) return null;
    return StopsCompanion(
      stopId: Value(stopId),
      stopName: Value(row['stop_name'] ?? stopId),
      stopLat: Value(double.tryParse(row['stop_lat'] ?? '') ?? 0),
      stopLon: Value(double.tryParse(row['stop_lon'] ?? '') ?? 0),
      stopCode: Value(row['stop_code']),
      platformCode: Value(row['platform_code']),
      parentStation: Value(row['parent_station']),
      locationType: Value(int.tryParse(row['location_type'] ?? '0') ?? 0),
      wheelchairBoarding: Value(int.tryParse(row['wheelchair_boarding'] ?? '')),
      city: Value(row['stop_area'] ?? row['municipality']),
    );
  }

  RoutesCompanion _buildRoute(Map<String, String> row) => RoutesCompanion(
        routeId: Value(row['route_id'] ?? ''),
        agencyId: Value(row['agency_id']),
        routeShortName: Value(row['route_short_name']),
        routeLongName: Value(row['route_long_name']),
        routeType: Value(int.tryParse(row['route_type'] ?? '') ?? 3),
      );

  TripsCompanion _buildTrip(Map<String, String> row) => TripsCompanion(
        tripId: Value(row['trip_id'] ?? ''),
        routeId: Value(row['route_id'] ?? ''),
        serviceId: Value(row['service_id'] ?? ''),
        tripHeadsign: Value(row['trip_headsign']),
        directionId: Value(int.tryParse(row['direction_id'] ?? '')),
        shapeId: Value(row['shape_id']),
        tripShortName: Value(row['trip_short_name']),
      );

  /// Prüft, ob `.tmp` + `.meta` einen vollständigen Download beschreiben.
  Future<bool> _isCompleteDownload(File zipFile, File metaFile) async {
    if (!await zipFile.exists() || !await metaFile.exists()) return false;
    final expected = int.tryParse((await metaFile.readAsString()).trim());
    if (expected == null || expected < 0) return false;
    return await zipFile.length() == expected;
  }

  Future<void> _cleanupTemp(File zipFile, File metaFile) async {
    if (await zipFile.exists()) await zipFile.delete();
    if (await metaFile.exists()) await metaFile.delete();
  }
}

/// Phase des laufenden Imports.
enum GtfsImportPhase { download, parse }

typedef GtfsImportProgress = void Function(
  GtfsImportPhase phase, {
  double? progress,
});

class GtfsImportResult {
  final int agencies;
  final int stops;
  final int routes;
  final int trips;
  final int stopTimes;
  final int shapes;

  const GtfsImportResult({
    required this.agencies,
    required this.stops,
    required this.routes,
    required this.trips,
    required this.stopTimes,
    required this.shapes,
  });
}
