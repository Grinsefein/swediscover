import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// GTFS-Agenturen (agency.txt)
class Agencies extends Table {
  TextColumn get agencyId => text()();
  TextColumn get agencyName => text()();
  TextColumn get agencyUrl => text().nullable()();
  TextColumn get agencyTimezone => text()();

  @override
  Set<Column> get primaryKey => {agencyId};
}

/// Haltestellen (stops.txt). Zusätzlich zu den GTFS-Standardfeldern werden
/// SweDiscover-Erweiterungen gepflegt (Rikshållplats-Verknüpfung, Betriebsgebiet).
class Stops extends Table {
  TextColumn get stopId => text()();
  TextColumn get stopName => text()();
  RealColumn get stopLat => real()();
  RealColumn get stopLon => real()();
  TextColumn get stopCode => text().nullable()();
  TextColumn get platformCode => text().nullable()();
  TextColumn get parentStation => text().nullable()();
  IntColumn get locationType => integer().withDefault(const Constant(0))();
  IntColumn get wheelchairBoarding => integer().nullable()();

  // SweDiscover-Erweiterungen (nicht Teil des GTFS-Standards)
  TextColumn get city => text().nullable()();
  TextColumn get operatorName => text().nullable()();
  TextColumn get rikshallplatsId => text().nullable()();
  TextColumn get rikshallplatsName => text().nullable()();
  TextColumn get availableModes => text().nullable()();
  TextColumn get platformList => text().nullable()();
  IntColumn get dailyPassengers => integer().nullable()();

  @override
  Set<Column> get primaryKey => {stopId};
}

/// Linien (routes.txt)
class Routes extends Table {
  TextColumn get routeId => text()();
  TextColumn get agencyId => text().nullable().references(Agencies, #agencyId)();
  TextColumn get routeShortName => text().nullable()();
  TextColumn get routeLongName => text().nullable()();
  IntColumn get routeType => integer()();

  @override
  Set<Column> get primaryKey => {routeId};
}

/// Fahrten (trips.txt)
class Trips extends Table {
  TextColumn get tripId => text()();
  TextColumn get routeId => text().references(Routes, #routeId)();
  TextColumn get serviceId => text()();
  TextColumn get tripHeadsign => text().nullable()();
  IntColumn get directionId => integer().nullable()();
  TextColumn get shapeId => text().nullable()();
  TextColumn get tripShortName => text().nullable()();

  @override
  Set<Column> get primaryKey => {tripId};
}

/// Haltestellen-Zeiten (stop_times.txt)
class StopTimes extends Table {
  TextColumn get tripId => text().references(Trips, #tripId)();
  IntColumn get stopSequence => integer()();
  TextColumn get stopId => text().references(Stops, #stopId)();
  TextColumn get arrivalTime => text().nullable()();
  TextColumn get departureTime => text().nullable()();
  TextColumn get stopHeadsign => text().nullable()();
  IntColumn get pickupType => integer().nullable()();
  IntColumn get dropOffType => integer().nullable()();

  @override
  Set<Column> get primaryKey => {tripId, stopSequence};
}

/// Liniengeometrien (shapes.txt) – Basis der 60-FPS-Vektor-Interpolation
class Shapes extends Table {
  TextColumn get shapeId => text()();
  IntColumn get shapePtSequence => integer()();
  RealColumn get shapePtLat => real()();
  RealColumn get shapePtLon => real()();
  RealColumn get shapeDistTraveled => real().nullable()();

  @override
  Set<Column> get primaryKey => {shapeId, shapePtSequence};
}

@DriftDatabase(tables: [Agencies, Stops, Routes, Trips, StopTimes, Shapes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'swediscover'));

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _ensureFts();
        },
        beforeOpen: (details) async {
          await _ensureFts();
        },
      );

  static const _ftsTableName = 'stops_fts';

  /// FTS5-Virtual Table über die durchsuchbaren Haltestellen-Spalten.
  Future<void> _ensureFts() {
    return customStatement(
      'CREATE VIRTUAL TABLE IF NOT EXISTS $_ftsTableName USING fts5('
      'stop_id UNINDEXED, name, city, operator_name, rikshallplats_name)',
    );
  }

  /// Indexiert eine Haltestelle in den FTS5-Baum (wird bei Import/Seed gepflegt).
  Future<void> indexStopFts(Stop stop) async {
    final safeName = _escapeFts(stop.stopName);
    final safeCity = _escapeFts(stop.city ?? '');
    final safeOp = _escapeFts(stop.operatorName ?? '');
    final safeRiks = _escapeFts(stop.rikshallplatsName ?? '');
    await customInsert(
      'INSERT INTO $_ftsTableName (stop_id, name, city, operator_name, rikshallplats_name) '
      'VALUES (?, ?, ?, ?, ?)',
      variables: [Variable(stop.stopId), Variable(safeName), Variable(safeCity), Variable(safeOp), Variable(safeRiks)],
    );
  }

  Future<void> deleteStopFts(String stopId) async {
    await customStatement('DELETE FROM $_ftsTableName WHERE stop_id = ?', [stopId]);
  }

  static String _escapeFts(String value) => value.replaceAll('"', '""');

  Future<int> countStops() {
    return stops.count().getSingle();
  }

  /// Baut den FTS5-Index aus dem aktuellen Bestand neu auf (z.B. nach Import).
  Future<void> reindexAllStopsFts() async {
    await customStatement('DELETE FROM $_ftsTableName');
    final all = await select(stops).get();
    for (final stop in all) {
      await indexStopFts(stop);
    }
  }

  /// Sub-10ms Full-Text-Suche über die lokale FTS5-Engine.
  /// Ergebnis wird zusätzlich optional räumlich (GPS-Distanz) sortiert.
  Future<List<Stop>> searchStops(String query, {double? lat, double? lng}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return _nearbyStops(lat: lat, lng: lng);
    }

    final escaped = _escapeFts(trimmed);
    final match = 'name:"$escaped"* OR city:"$escaped"* OR operator_name:"$escaped"* OR rikshallplats_name:"$escaped"*';

    final result = await customSelect(
      'SELECT '
      's.stop_id AS stopId, s.stop_name AS stopName, s.stop_lat AS stopLat, '
      's.stop_lon AS stopLon, s.stop_code AS stopCode, s.platform_code AS platformCode, '
      's.parent_station AS parentStation, s.location_type AS locationType, '
      's.wheelchair_boarding AS wheelchairBoarding, s.city AS city, '
      's.operator_name AS operatorName, s.rikshallplats_id AS rikshallplatsId, '
      's.rikshallplats_name AS rikshallplatsName, s.available_modes AS availableModes, '
      's.platform_list AS platformList, s.daily_passengers AS dailyPassengers '
      'FROM $_ftsTableName f JOIN stops s ON s.stop_id = f.stop_id '
      'WHERE $_ftsTableName MATCH ? ORDER BY rank LIMIT 50',
      variables: [Variable(match)],
      readsFrom: {stops},
    ).get();

    final found = result.map((row) => Stop.fromJson(row.data)).toList();
    return _sortByDistance(found, lat: lat, lng: lng);
  }

  Future<List<Stop>> _nearbyStops({double? lat, double? lng}) async {
    final all = await (select(stops)..orderBy([(t) => OrderingTerm.asc(t.stopName)])).get();
    return _sortByDistance(all, lat: lat, lng: lng);
  }

  List<Stop> _sortByDistance(List<Stop> stops, {double? lat, double? lng}) {
    if (lat == null || lng == null) return stops;
    final sorted = [...stops]..sort((a, b) {
        final da = _distanceKm(lat, lng, a.stopLat, a.stopLon);
        final db = _distanceKm(lat, lng, b.stopLat, b.stopLon);
        return da.compareTo(db);
      });
    return sorted;
  }

  static double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }
}