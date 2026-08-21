import 'package:latlong2/latlong.dart';

import '../models/departure_model.dart';
import '../models/vehicle_position_model.dart';
import 'realtime_repository.dart';

/// Simulierte BFF-Implementierung (Demo-/Entwicklungsmodus).
/// Reproduziert Request Collapsing & Protobuf-Stream-Telemetrie und liefert
/// Seed-Daten für Abfahrten und Live-Fahrzeuge – ohne Backend oder API-Keys.
class MockRealtimeRepository extends RealtimeRepository {
  int _totalClientRequests = 4850;
  int _upstreamCallsMade = 194;
  int _protobufBytes = 14200000;
  int _jsonBytes = 1180000;

  bool _isBoundingBoxFilterActive = true;
  @override
  bool get isBoundingBoxFilterActive => _isBoundingBoxFilterActive;

  @override
  void toggleBoundingBoxFilter() {
    _isBoundingBoxFilterActive = !_isBoundingBoxFilterActive;
    notifyListeners();
  }

  @override
  RealtimeTelemetry get telemetry {
    final collapsed = _totalClientRequests - _upstreamCallsMade;
    final savings = _totalClientRequests > 0 ? (collapsed / _totalClientRequests) * 100.0 : 0.0;

    return RealtimeTelemetry(
      totalClientRequests: _totalClientRequests,
      upstreamCallsMade: _upstreamCallsMade,
      collapsedRequests: collapsed,
      networkSavingsPercent: savings,
      protobufBytesProcessed: _protobufBytes,
      jsonStreamBytesEmitted: _jsonBytes,
      activeVehiclesInSweden: 14280,
      activeVehiclesInViewport: _isBoundingBoxFilterActive ? 12 : 38,
    );
  }

  /// Request-Collapsing-Demo: nur jeder 25. Client-Request erreicht das
  /// (rate-limitierte) Trafiklab-Upstream-API.
  @override
  Future<List<TransitDeparture>> fetchDepartures(String stopId) async {
    _totalClientRequests += 1;
    if (_totalClientRequests % 25 == 0) {
      _upstreamCallsMade += 1;
    }
    _protobufBytes += 1280;
    _jsonBytes += 340;
    notifyListeners();

    final now = DateTime.now();

    if (stopId == '740000001') {
      // T-Centralen (Stockholm)
      return [
        TransitDeparture(
          id: 'DEP_STO_101',
          stopId: stopId,
          line: '14',
          destination: 'Mörby centrum',
          mode: TransitMode.tunnelbana,
          scheduledTime: now.add(const Duration(minutes: 2)),
          realtimeTime: now.add(const Duration(minutes: 2)),
          delaySeconds: 0,
          status: DepartureStatus.onTime,
          track: 'Spår 1',
          operatorName: 'SL',
          occupancy: OccupancyStatus.manySeats,
        ),
        TransitDeparture(
          id: 'DEP_STO_102',
          stopId: stopId,
          line: 'SJ 524',
          destination: 'Göteborg C',
          mode: TransitMode.fjarrtag,
          scheduledTime: now.add(const Duration(minutes: 5)),
          realtimeTime: now.add(const Duration(minutes: 9)),
          delaySeconds: 240,
          status: DepartureStatus.delayed,
          track: 'Spår 10b',
          originalTrack: 'Spår 8',
          operatorName: 'SJ High-Speed (X2000)',
          occupancy: OccupancyStatus.standingRoom,
          hasBicycleAccess: true,
        ),
        TransitDeparture(
          id: 'DEP_STO_103',
          stopId: stopId,
          line: '43',
          destination: 'Bålsta',
          mode: TransitMode.pendeltag,
          scheduledTime: now.add(const Duration(minutes: 7)),
          realtimeTime: now.add(const Duration(minutes: 7)),
          delaySeconds: 0,
          status: DepartureStatus.onTime,
          track: 'Spår 15',
          operatorName: 'SL Pendeltåg',
          occupancy: OccupancyStatus.fewSeats,
        ),
        TransitDeparture(
          id: 'DEP_STO_104',
          stopId: stopId,
          line: 'Mälartåg 912',
          destination: 'Örebro C via Västerås',
          mode: TransitMode.fjarrtag,
          scheduledTime: now.add(const Duration(minutes: 12)),
          realtimeTime: now.add(const Duration(minutes: 12)),
          delaySeconds: 0,
          status: DepartureStatus.platformChange,
          track: 'Spår 4',
          originalTrack: 'Spår 2',
          operatorName: 'Mälartåg',
          occupancy: OccupancyStatus.manySeats,
        ),
        TransitDeparture(
          id: 'DEP_STO_105',
          stopId: stopId,
          line: '11',
          destination: 'Akalla',
          mode: TransitMode.tunnelbana,
          scheduledTime: now.add(const Duration(minutes: 15)),
          realtimeTime: now.add(const Duration(minutes: 21)),
          delaySeconds: 360,
          status: DepartureStatus.delayed,
          track: 'Spår 3',
          operatorName: 'SL',
          occupancy: OccupancyStatus.full,
        ),
        TransitDeparture(
          id: 'DEP_STO_106',
          stopId: stopId,
          line: 'Arlanda Express',
          destination: 'Arlanda Norra',
          mode: TransitMode.fjarrtag,
          scheduledTime: now.add(const Duration(minutes: 18)),
          realtimeTime: now.add(const Duration(minutes: 18)),
          delaySeconds: 0,
          status: DepartureStatus.onTime,
          track: 'Spår 1',
          operatorName: 'A-Train',
          occupancy: OccupancyStatus.manySeats,
        ),
        TransitDeparture(
          id: 'DEP_STO_107',
          stopId: stopId,
          line: '54',
          destination: 'Reimersholme',
          mode: TransitMode.bus,
          scheduledTime: now.add(const Duration(minutes: 22)),
          realtimeTime: now.add(const Duration(minutes: 22)),
          delaySeconds: 0,
          status: DepartureStatus.cancelled,
          track: 'Läge C',
          operatorName: 'SL Stadsbuss',
          occupancy: OccupancyStatus.empty,
        ),
      ];
    } else if (stopId == '740000002') {
      // Göteborg C
      return [
        TransitDeparture(
          id: 'DEP_GOT_201',
          stopId: stopId,
          line: 'Spårvagn 4',
          destination: 'Mölndal via Korsvägen',
          mode: TransitMode.tram,
          scheduledTime: now.add(const Duration(minutes: 1)),
          realtimeTime: now.add(const Duration(minutes: 1)),
          delaySeconds: 0,
          status: DepartureStatus.onTime,
          track: 'Läge A',
          operatorName: 'Västtrafik',
          occupancy: OccupancyStatus.fewSeats,
        ),
        TransitDeparture(
          id: 'DEP_GOT_202',
          stopId: stopId,
          line: 'Västtågen 3205',
          destination: 'Vänersborg C',
          mode: TransitMode.fjarrtag,
          scheduledTime: now.add(const Duration(minutes: 4)),
          realtimeTime: now.add(const Duration(minutes: 8)),
          delaySeconds: 240,
          status: DepartureStatus.delayed,
          track: 'Spår 6',
          operatorName: 'Västtrafik / Vy',
          occupancy: OccupancyStatus.manySeats,
        ),
        TransitDeparture(
          id: 'DEP_GOT_203',
          stopId: stopId,
          line: 'Buss X1',
          destination: 'Partille Centrum',
          mode: TransitMode.bus,
          scheduledTime: now.add(const Duration(minutes: 6)),
          realtimeTime: now.add(const Duration(minutes: 6)),
          delaySeconds: 0,
          status: DepartureStatus.onTime,
          track: 'Läge B',
          operatorName: 'Västtrafik Express',
          occupancy: OccupancyStatus.standingRoom,
        ),
      ];
    } else {
      // Generische Haltestelle
      return [
        TransitDeparture(
          id: 'DEP_GEN_301',
          stopId: stopId,
          line: 'Linje 1',
          destination: 'Centrum',
          mode: TransitMode.bus,
          scheduledTime: now.add(const Duration(minutes: 3)),
          realtimeTime: now.add(const Duration(minutes: 3)),
          delaySeconds: 0,
          status: DepartureStatus.onTime,
          track: 'Läge A',
          operatorName: 'Länstrafiken',
          occupancy: OccupancyStatus.manySeats,
        ),
        TransitDeparture(
          id: 'DEP_GEN_302',
          stopId: stopId,
          line: 'Regiotåg 88',
          destination: 'Huvudstation',
          mode: TransitMode.fjarrtag,
          scheduledTime: now.add(const Duration(minutes: 10)),
          realtimeTime: now.add(const Duration(minutes: 13)),
          delaySeconds: 180,
          status: DepartureStatus.delayed,
          track: 'Spår 2',
          operatorName: 'Öresundståg',
          occupancy: OccupancyStatus.fewSeats,
        ),
      ];
    }
  }

  /// Initiale Schweden-weite Live-Fahrzeug-Seed-Daten mit Routen-Polylines.
  @override
  Future<List<RealtimeVehiclePosition>> fetchVehicles() async {
    final now = DateTime.now();

    final sthlmL14Poly = const [
      LatLng(59.3312, 18.0594), // T-Centralen
      LatLng(59.3355, 18.0628), // Hötorget
      LatLng(59.3429, 18.0498), // Odenplan
      LatLng(59.3520, 18.0650), // Tekniska Högskolan
      LatLng(59.3700, 18.0700), // Universitetet
      LatLng(59.3980, 18.0350), // Mörby centrum
    ];

    final sj2000Poly = const [
      LatLng(59.3312, 18.0594), // Stockholm C
      LatLng(59.1980, 17.6270), // Södertälje Syd
      LatLng(58.9850, 16.2050), // Katrineholm C
      LatLng(58.4109, 15.6216), // Linköping C
      LatLng(57.7089, 11.9731), // Göteborg C
    ];

    final goteborgTramPoly = const [
      LatLng(57.7089, 11.9731), // Göteborg C
      LatLng(57.7069, 11.9698), // Brunnsparken
      LatLng(57.7000, 11.9750), // Valand
      LatLng(57.6966, 11.9872), // Korsvägen
      LatLng(57.6550, 12.0150), // Mölndal
    ];

    final malmoOresundPoly = const [
      LatLng(55.6091, 13.0007), // Malmö C
      LatLng(55.5936, 13.0009), // Triangeln
      LatLng(55.5630, 12.9770), // Hyllie
      LatLng(55.5720, 12.8250), // Öresundsbron
      LatLng(55.6761, 12.5683), // København H
    ];

    return [
      RealtimeVehiclePosition(
        vehicleId: 'SL_METRO_1402',
        tripId: 'TRIP_STO_14',
        line: '14',
        mode: TransitMode.tunnelbana,
        currentPosition: sthlmL14Poly[0],
        startPosition: sthlmL14Poly[0],
        targetPosition: sthlmL14Poly[1],
        bearing: 35.0,
        speedKmh: 48.5,
        lastGpsReport: now,
        occupancy: OccupancyStatus.fewSeats,
        nextStopName: 'Hötorget',
        delayMinutes: 0,
        routePolyline: sthlmL14Poly,
        progressFraction: 0.1,
      ),
      RealtimeVehiclePosition(
        vehicleId: 'SJ_X2000_524',
        tripId: 'TRIP_SJ_524',
        line: 'SJ 524',
        mode: TransitMode.fjarrtag,
        currentPosition: sj2000Poly[0],
        startPosition: sj2000Poly[0],
        targetPosition: sj2000Poly[1],
        bearing: 215.0,
        speedKmh: 195.0,
        lastGpsReport: now,
        occupancy: OccupancyStatus.standingRoom,
        nextStopName: 'Södertälje Syd',
        delayMinutes: 4,
        routePolyline: sj2000Poly,
        progressFraction: 0.05,
      ),
      RealtimeVehiclePosition(
        vehicleId: 'VT_TRAM_404',
        tripId: 'TRIP_GOT_TRAM4',
        line: 'Spårvagn 4',
        mode: TransitMode.tram,
        currentPosition: goteborgTramPoly[0],
        startPosition: goteborgTramPoly[0],
        targetPosition: goteborgTramPoly[1],
        bearing: 180.0,
        speedKmh: 28.0,
        lastGpsReport: now,
        occupancy: OccupancyStatus.manySeats,
        nextStopName: 'Brunnsparken',
        delayMinutes: 0,
        routePolyline: goteborgTramPoly,
        progressFraction: 0.25,
      ),
      RealtimeVehiclePosition(
        vehicleId: 'SKANE_ORESUND_1042',
        tripId: 'TRIP_MAL_1042',
        line: 'Öresundståg 1042',
        mode: TransitMode.fjarrtag,
        currentPosition: malmoOresundPoly[0],
        startPosition: malmoOresundPoly[0],
        targetPosition: malmoOresundPoly[1],
        bearing: 175.0,
        speedKmh: 110.0,
        lastGpsReport: now,
        occupancy: OccupancyStatus.fewSeats,
        nextStopName: 'Triangeln',
        delayMinutes: 1,
        routePolyline: malmoOresundPoly,
        progressFraction: 0.15,
      ),
    ];
  }
}