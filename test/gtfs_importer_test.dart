import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:swediscover/data/app_database.dart';
import 'package:swediscover/data/gtfs_importer.dart';

/// Baut ein kleines GTFS-Fixture-Zip im Speicher.
Uint8List buildFixtureZip() {
  final archive = Archive();
  void addEntry(String name, String content) {
    final bytes = Uint8List.fromList(utf8.encode(content));
    archive.addFile(ArchiveFile.bytes(name, bytes));
  }

  addEntry('agency.txt', 'agency_id,agency_name,agency_url,agency_timezone\n'
      'SL,Storstockholms Lokaltrafik,https://sl.se,Europe/Stockholm\n');
  addEntry('stops.txt', 'stop_id,stop_name,stop_lat,stop_lon,stop_code\n'
      '740020101,T-Centralen,59.329672,18.061294,TC\n'
      '"1,000",Slussen,59.319,18.072,S2\n'
      ',Kein Name,0,0,\n');
  addEntry('routes.txt', 'route_id,agency_id,route_short_name,route_long_name,route_type\n'
      '9011001,SL,10,Hägersten – Ropsten,1\n');
  addEntry('trips.txt', 'trip_id,route_id,service_id,trip_headsign,direction_id,shape_id\n'
      '14010000151130221,9011001,SL20260822,Helsingborg,1,shape-42\n');
  // Darf NICHT importiert werden (bewusst deaktiviert).
  addEntry('stop_times.txt', 'trip_id,stop_sequence,stop_id\n'
      'x,1,y\n');
  addEntry('shapes.txt', 'shape_id,shape_pt_sequence,shape_pt_lat,shape_pt_lon\n'
      's,1,0,0\n');

  return Uint8List.fromList(ZipEncoder().encode(archive));
}

void main() {
  late AppDatabase db;
  late Directory tempDir;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('gtfs_importer_test');
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  test('importZip streamt alle relevanten Tabellen und skippt stop_times/shapes',
      () async {
    final importer = GtfsImporter(db, tempDir: tempDir);
    final result = await importer.importZip(db, buildFixtureZip());

    expect(result.agencies, 1);
    expect(result.stops, 2);
    expect(result.routes, 1);
    expect(result.trips, 1);
    expect(result.stopTimes, 0);
    expect(result.shapes, 0);

    expect(await db.stopTimes.count().getSingle(), 0);
    expect(await db.shapes.count().getSingle(), 0);

    // Quoted Field mit Komma korrekt geparst, leere stop_id übersprungen.
    final slussen = await (db.select(db.stops)
          ..where((t) => t.stopId.equals('1,000')))
        .getSingleOrNull();
    expect(slussen?.stopName, 'Slussen');

    // FTS-Index wurde aufgebaut.
    expect(await db.countStops(), 2);

    // Temp-Artefakte wurden aufgeräumt.
    expect(tempDir.listSync(), isEmpty);
  });

  test('Import ist idempotent (erneuter Lauf ersetzt Daten ohne Duplikate)',
      () async {
    final importer = GtfsImporter(db, tempDir: tempDir);
    await importer.importZip(db, buildFixtureZip());
    await importer.importZip(db, buildFixtureZip());

    expect(await db.stops.count().getSingle(), 2);
    expect(await db.trips.count().getSingle(), 1);
  });
}
