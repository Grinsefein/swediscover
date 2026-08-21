import 'dart:math';

import '../models/stop_model.dart';
import 'app_database.dart';

/// Ergebnis einer lokalen Haltestellen-Suche (FTS5).
class FtsSearchResult {
  final List<TransitStop> stops;
  final int executionMs;
  final int totalStopsInDb;
  final String query;

  const FtsSearchResult({
    required this.stops,
    required this.executionMs,
    required this.totalStopsInDb,
    required this.query,
  });
}

/// Abstraktion über die lokale Haltestellen-Topologie.
/// Implementierung: [DriftStopRepository] (SQLite/FTS5, Produktion).
abstract class StopRepository {
  Future<FtsSearchResult> search(String query, {double? userLat, double? userLng});
  Future<TransitStop> getStopById(String id);
}

/// Produktions-Repository auf Basis der Drift/SQLite-DB mit FTS5-Engine.
class DriftStopRepository implements StopRepository {
  final AppDatabase db;

  DriftStopRepository(this.db);

  @override
  Future<FtsSearchResult> search(String query, {double? userLat, double? userLng}) async {
    final stopwatch = Stopwatch()..start();
    final rows = await db.searchStops(query, lat: userLat, lng: userLng);
    stopwatch.stop();

    final total = await db.countStops();

    return FtsSearchResult(
      stops: rows.map(_toModel).toList(),
      executionMs: stopwatch.elapsedMilliseconds,
      totalStopsInDb: total,
      query: query,
    );
  }

  @override
  Future<TransitStop> getStopById(String id) async {
    final row = await (db.select(db.stops)..where((t) => t.stopId.equals(id))).getSingleOrNull();
    if (row == null) {
      throw StateError('Unbekannte Haltestelle: $id');
    }
    final platforms = await _resolvePlatforms(row);
    return _toModel(row, platforms: platforms);
  }

  Future<List<TransitStop>> nearbyStops(double lat, double lng, {int limit = 20}) async {
    final rows = await db.searchStops('', lat: lat, lng: lng);
    return rows.take(limit).map(_toModel).toList();
  }

  /// Ermittelt die Stege/Gleise: enthält der Haltestellen-Datensatz eine
  /// kommagetrennte `platformList`, wird diese genutzt; andernfalls werden
  /// Kind-Haltestellen (parentStation) abgefragt – so funktioniert das auch
  /// mit echten GTFS-Sweden-3-Daten.
  Future<List<String>> _resolvePlatforms(Stop row) async {
    if (row.platformList != null) {
      return row.platformList!.split('|').where((e) => e.isNotEmpty).toList();
    }
    final children = await (db.select(db.stops)..where((t) => t.parentStation.equals(row.stopId))).get();
    final derived = children
        .map((c) => c.platformCode)
        .whereType<String>()
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    if (derived.isNotEmpty) return derived;
    if (row.platformCode != null && row.platformCode!.isNotEmpty) return [row.platformCode!];
    return const [];
  }

  TransitStop _toModel(Stop row, {List<String>? platforms}) {
    return TransitStop(
      id: row.stopId,
      name: row.stopName,
      city: row.city ?? '',
      rikshallplatsId: row.rikshallplatsId ?? '',
      rikshallplatsName: row.rikshallplatsName ?? '',
      lat: row.stopLat,
      lng: row.stopLon,
      platforms: platforms ?? const [],
      operatorName: row.operatorName ?? 'Okänd operatör',
      availableModes: _split(row.availableModes),
      dailyPassengers: row.dailyPassengers ?? 10000,
    );
  }

  List<String> _split(String? value) {
    if (value == null || value.isEmpty) return const [];
    return value.split(',').where((e) => e.isNotEmpty).toList();
  }
}