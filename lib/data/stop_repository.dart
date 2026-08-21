import 'dart:math';

import '../models/stop_model.dart';
import 'app_database.dart';
import 'demo_stops.dart';

/// Ergebnis einer lokalen Haltestellen-Suche (FTS5 bzw. Demo-Fallback).
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
/// Implementierungen: [DriftStopRepository] (SQLite/FTS5, Produktion)
/// und [DemoStopRepository] (In-Memory-Fallback ohne native DB).
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

/// In-Memory-Fallback ohne native SQLite (Tests, Debug ohne DB).
class DemoStopRepository implements StopRepository {
  @override
  Future<FtsSearchResult> search(String query, {double? userLat, double? userLng}) async {
    final stopwatch = Stopwatch()..start();
    await Future.delayed(const Duration(milliseconds: 1));

    final trimmed = query.trim().toLowerCase();
    List<TransitStop> results;
    if (trimmed.isEmpty) {
      results = List.from(demoStops);
    } else {
      results = demoStops.where((s) {
        return s.name.toLowerCase().contains(trimmed) ||
            s.city.toLowerCase().contains(trimmed) ||
            s.operatorName.toLowerCase().contains(trimmed) ||
            s.rikshallplatsName.toLowerCase().contains(trimmed);
      }).toList();
    }

    if (userLat != null && userLng != null) {
      results.sort((a, b) {
        final da = _distanceKm(userLat, userLng, a.lat, a.lng);
        final db = _distanceKm(userLat, userLng, b.lat, b.lng);
        return da.compareTo(db);
      });
    }

    stopwatch.stop();
    return FtsSearchResult(
      stops: results,
      executionMs: stopwatch.elapsedMilliseconds,
      totalStopsInDb: demoStops.length * 4200,
      query: query,
    );
  }

  @override
  Future<TransitStop> getStopById(String id) async {
    return demoStops.firstWhere((s) => s.id == id, orElse: () => demoStops.first);
  }

  static double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }
}