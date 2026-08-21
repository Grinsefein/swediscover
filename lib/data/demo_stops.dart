import 'package:drift/drift.dart';

import '../models/stop_model.dart';
import 'app_database.dart';

/// Seed-Datensatz für den Demo-/Entwicklungsmodus.
/// Wird beim ersten Start in die echte SQLite-Datenbank (inkl. FTS5) importiert,
/// sodass alle Features ohne GTFS-Download und ohne Backend nutzbar bleiben.
const List<TransitStop> demoStops = [
  TransitStop(
    id: '740000001',
    name: 'T-Centralen',
    city: 'Stockholm',
    rikshallplatsId: 'RIK_STO_01',
    rikshallplatsName: 'Stockholm Central Hub',
    lat: 59.3312,
    lng: 18.0594,
    platforms: ['Spår 1', 'Spår 2', 'Spår 3', 'Spår 4', 'Spår 5', 'Spår 6', 'Läge A', 'Läge B'],
    operatorName: 'SL',
    availableModes: ['tunnelbana', 'pendeltag', 'train', 'bus'],
    dailyPassengers: 320000,
  ),
  TransitStop(
    id: '740000002',
    name: 'Göteborg Centralstation',
    city: 'Göteborg',
    rikshallplatsId: 'RIK_GOT_01',
    rikshallplatsName: 'Göteborg Central Hub',
    lat: 57.7089,
    lng: 11.9731,
    platforms: ['Spår 1', 'Spår 2', 'Spår 3', 'Spår 4', 'Spår 5', 'Spår 6', 'Läge A', 'Läge B', 'Läge C'],
    operatorName: 'Västtrafik',
    availableModes: ['train', 'tram', 'bus'],
    dailyPassengers: 140000,
  ),
  TransitStop(
    id: '740000003',
    name: 'Malmö Centralstation',
    city: 'Malmö',
    rikshallplatsId: 'RIK_MAL_01',
    rikshallplatsName: 'Malmö Central Hub',
    lat: 55.6091,
    lng: 13.0007,
    platforms: ['Spår 1', 'Spår 2', 'Spår 3', 'Spår 4', 'Läge A', 'Läge B'],
    operatorName: 'Skånetrafiken',
    availableModes: ['train', 'bus'],
    dailyPassengers: 95000,
  ),
  TransitStop(
    id: '740000004',
    name: 'Uppsala Centralstation',
    city: 'Uppsala',
    rikshallplatsId: 'RIK_UPP_01',
    rikshallplatsName: 'Uppsala Central Hub',
    lat: 59.8586,
    lng: 17.6461,
    platforms: ['Spår 1', 'Spår 2', 'Spår 3', 'Spår 4', 'Spår 5', 'Läge A'],
    operatorName: 'UL / Mälartåg',
    availableModes: ['train', 'bus'],
    dailyPassengers: 55000,
  ),
  TransitStop(
    id: '740000005',
    name: 'Slussen',
    city: 'Stockholm',
    rikshallplatsId: 'RIK_STO_02',
    rikshallplatsName: 'Slussen Hub',
    lat: 59.3197,
    lng: 18.0717,
    platforms: ['Spår 1', 'Spår 2', 'Läge A', 'Läge B', 'Läge C', 'Kaj 1'],
    operatorName: 'SL',
    availableModes: ['tunnelbana', 'bus', 'ferry'],
    dailyPassengers: 160000,
  ),
  TransitStop(
    id: '740000006',
    name: 'Odenplan',
    city: 'Stockholm',
    rikshallplatsId: 'RIK_STO_03',
    rikshallplatsName: 'Odenplan Hub',
    lat: 59.3429,
    lng: 18.0498,
    platforms: ['Spår 1', 'Spår 2', 'Spår 3', 'Spår 4', 'Läge A', 'Läge B'],
    operatorName: 'SL',
    availableModes: ['tunnelbana', 'pendeltag', 'bus'],
    dailyPassengers: 110000,
  ),
  TransitStop(
    id: '740000007',
    name: 'Brunnsparken',
    city: 'Göteborg',
    rikshallplatsId: 'RIK_GOT_02',
    rikshallplatsName: 'Brunnsparken Tram Hub',
    lat: 57.7069,
    lng: 11.9698,
    platforms: ['Läge A', 'Läge B', 'Läge C', 'Läge D', 'Läge E'],
    operatorName: 'Västtrafik',
    availableModes: ['tram', 'bus'],
    dailyPassengers: 120000,
  ),
  TransitStop(
    id: '740000008',
    name: 'Korsvägen',
    city: 'Göteborg',
    rikshallplatsId: 'RIK_GOT_03',
    rikshallplatsName: 'Korsvägen Hub',
    lat: 57.6966,
    lng: 11.9872,
    platforms: ['Läge A', 'Läge B', 'Läge C', 'Läge D'],
    operatorName: 'Västtrafik',
    availableModes: ['tram', 'bus'],
    dailyPassengers: 70000,
  ),
  TransitStop(
    id: '740000009',
    name: 'Triangeln',
    city: 'Malmö',
    rikshallplatsId: 'RIK_MAL_02',
    rikshallplatsName: 'Triangeln Underground Hub',
    lat: 55.5936,
    lng: 13.0009,
    platforms: ['Spår 1', 'Spår 2', 'Läge A', 'Läge B'],
    operatorName: 'Skånetrafiken',
    availableModes: ['train', 'bus'],
    dailyPassengers: 48000,
  ),
  TransitStop(
    id: '740000010',
    name: 'Karlstad Centralstation',
    city: 'Karlstad',
    rikshallplatsId: 'RIK_KRL_01',
    rikshallplatsName: 'Karlstad Hub',
    lat: 59.3776,
    lng: 13.4996,
    platforms: ['Spår 1', 'Spår 2', 'Spår 3', 'Läge A'],
    operatorName: 'Värmlandstrafik',
    availableModes: ['train', 'bus'],
    dailyPassengers: 22000,
  ),
  TransitStop(
    id: '740000011',
    name: 'Kiruna Station',
    city: 'Kiruna',
    rikshallplatsId: 'RIK_KRN_01',
    rikshallplatsName: 'Kiruna Lapland Hub',
    lat: 67.8557,
    lng: 20.2253,
    platforms: ['Spår 1', 'Spår 2', 'Läge A'],
    operatorName: 'Länstrafiken Norrbotten / Vy',
    availableModes: ['train', 'bus'],
    dailyPassengers: 8500,
  ),
  TransitStop(
    id: '740000012',
    name: 'Arlanda Centralstation',
    city: 'Sigtuna / Arlanda',
    rikshallplatsId: 'RIK_ARL_01',
    rikshallplatsName: 'Arlanda Airport Hub',
    lat: 59.6496,
    lng: 17.9292,
    platforms: ['Spår 1', 'Spår 2', 'Spår 11', 'Spår 12'],
    operatorName: 'Arlanda Express / SL / SJ',
    availableModes: ['train', 'bus'],
    dailyPassengers: 62000,
  ),
];

/// Überführt Demo-Haltestellen in Drift-Companions (Basis für Batch-Insert).
List<StopsCompanion> demoStopCompanions() {
  return demoStops.map((s) {
    return StopsCompanion(
      stopId: Value(s.id),
      stopName: Value(s.name),
      stopLat: Value(s.lat),
      stopLon: Value(s.lng),
      city: Value(s.city),
      operatorName: Value(s.operatorName),
      rikshallplatsId: Value(s.rikshallplatsId),
      rikshallplatsName: Value(s.rikshallplatsName),
      availableModes: Value(s.availableModes.join(',')),
      platformList: Value(s.platforms.join('|')),
      dailyPassengers: Value(s.dailyPassengers),
    );
  }).toList();
}

/// Seeds die Demo-Haltestellen in die SQLite-DB (nur wenn leer) und indexiert FTS5.
Future<void> seedDemoStops(AppDatabase db) async {
  final count = await db.countStops();
  if (count > 0) return;

  await db.batch((batch) {
    batch.insertAll(db.stops, demoStopCompanions());
  });
  await db.reindexAllStopsFts();
}