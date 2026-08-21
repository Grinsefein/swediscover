import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;

import 'app_database.dart';

/// Importiert den täglichen GTFS-Sweden-3-Zip in die lokale Drift/SQLite-DB.
/// Der Import ist idempotent (insertOrReplace), baut den FTS5-Index neu auf
/// und wird typischerweise vom Server bzw. einem Daily-Update-Job getriggert.
class GtfsImporter {
  const GtfsImporter(this._db);

  final AppDatabase _db;

  /// Lädt das GTFS-ZIP direkt von Trafiklab und importiert es.
  Future<GtfsImportResult> importFromTrafiklab(String apiKey) async {
    final url = Uri.parse(
      'https://api.trafiklab.se/gtfs-sweden-3/gtfs.zip',
    );
    
    final response = await http.Client().get(
      url,
      headers: {'Authorization': 'Bearer $apiKey'},
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw Exception(
        'GTFS-Download fehlgeschlagen: HTTP ${response.statusCode}',
      );
    }

    return importZip(_db, response.bodyBytes);
  }

  Future<GtfsImportResult> importZip(AppDatabase db, List<int> zipBytes) async {
    final archive = ZipDecoder().decodeBytes(Uint8List.fromList(zipBytes));

    String? readFile(String name) {
      final file = archive.findFile(name);
      if (file == null) return null;
      return String.fromCharCodes(file.content as List<int>);
    }

    final agencies = _parseCsv(readFile('agency.txt'));
    final stops = _parseCsv(readFile('stops.txt'));
    final routes = _parseCsv(readFile('routes.txt'));
    final trips = _parseCsv(readFile('trips.txt'));
    final stopTimes = _parseCsv(readFile('stop_times.txt'));
    final shapes = _parseCsv(readFile('shapes.txt'));

    await db.transaction(() async {
      await db.delete(db.stopTimes).go();
      await db.delete(db.shapes).go();
      await db.delete(db.trips).go();
      await db.delete(db.routes).go();
      await db.delete(db.stops).go();
      await db.delete(db.agencies).go();

      await db.batch((batch) {
        for (final row in agencies) {
          batch.insert(
            db.agencies,
            AgenciesCompanion(
              agencyId: Value(row['agency_id'] ?? 'unknown'),
              agencyName: Value(row['agency_name'] ?? ''),
              agencyUrl: Value(row['agency_url']),
              agencyTimezone: Value(row['agency_timezone'] ?? 'Europe/Stockholm'),
            ),
          );
        }

        for (final row in stops) {
          final stopId = row['stop_id'] ?? '';
          if (stopId.isEmpty) continue;
          batch.insert(
            db.stops,
            StopsCompanion(
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
            ),
            mode: InsertMode.insertOrReplace,
          );
        }

        for (final row in routes) {
          batch.insert(
            db.routes,
            RoutesCompanion(
              routeId: Value(row['route_id'] ?? ''),
              agencyId: Value(row['agency_id']),
              routeShortName: Value(row['route_short_name']),
              routeLongName: Value(row['route_long_name']),
              routeType: Value(int.tryParse(row['route_type'] ?? '') ?? 3),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }

        for (final row in trips) {
          batch.insert(
            db.trips,
            TripsCompanion(
              tripId: Value(row['trip_id'] ?? ''),
              routeId: Value(row['route_id'] ?? ''),
              serviceId: Value(row['service_id'] ?? ''),
              tripHeadsign: Value(row['trip_headsign']),
              directionId: Value(int.tryParse(row['direction_id'] ?? '')),
              shapeId: Value(row['shape_id']),
              tripShortName: Value(row['trip_short_name']),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }

        for (final row in stopTimes) {
          final tripId = row['trip_id'] ?? '';
          final seq = int.tryParse(row['stop_sequence'] ?? '');
          if (tripId.isEmpty || seq == null) continue;
          batch.insert(
            db.stopTimes,
            StopTimesCompanion(
              tripId: Value(tripId),
              stopSequence: Value(seq),
              stopId: Value(row['stop_id'] ?? ''),
              arrivalTime: Value(row['arrival_time']),
              departureTime: Value(row['departure_time']),
              stopHeadsign: Value(row['stop_headsign']),
              pickupType: Value(int.tryParse(row['pickup_type'] ?? '')),
              dropOffType: Value(int.tryParse(row['drop_off_type'] ?? '')),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }

        for (final row in shapes) {
          final shapeId = row['shape_id'] ?? '';
          final seq = int.tryParse(row['shape_pt_sequence'] ?? '');
          if (shapeId.isEmpty || seq == null) continue;
          batch.insert(
            db.shapes,
            ShapesCompanion(
              shapeId: Value(shapeId),
              shapePtSequence: Value(seq),
              shapePtLat: Value(double.tryParse(row['shape_pt_lat'] ?? '') ?? 0),
              shapePtLon: Value(double.tryParse(row['shape_pt_lon'] ?? '') ?? 0),
              shapeDistTraveled: Value(double.tryParse(row['shape_dist_traveled'] ?? '')),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
    });

    await db.reindexAllStopsFts();

    return GtfsImportResult(
      stops: stops.length,
      routes: routes.length,
      trips: trips.length,
      stopTimes: stopTimes.length,
      shapes: shapes.length,
    );
  }

  /// Parst CSV in eine Liste von Header->Wert-Maps. GTFS nutzt LF/CRLF.
  List<Map<String, String>> _parseCsv(String? content) {
    if (content == null || content.trim().isEmpty) return const [];
    final normalized = content.replaceAll('\r\n', '\n').replaceFirst('\uFEFF', '');
    const decoder = CsvDecoder(parseHeaders: true);
    final raw = decoder.convert(normalized);
    if (raw.isEmpty) return const [];

    return raw.map((row) {
      final csvRow = row as CsvRow;
      final map = <String, String>{};
      csvRow.toMap().forEach((key, value) {
        map[key] = value == null ? '' : value.toString().trim();
      });
      return map;
    }).toList();
  }
}

class GtfsImportResult {
  final int stops;
  final int routes;
  final int trips;
  final int stopTimes;
  final int shapes;

  const GtfsImportResult({
    required this.stops,
    required this.routes,
    required this.trips,
    required this.stopTimes,
    required this.shapes,
  });
}