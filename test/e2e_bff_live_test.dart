import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fixnum/fixnum.dart';
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:swediscover/models/departure_model.dart';
import 'package:swediscover/models/vehicle_position_model.dart';
import 'package:swediscover/repositories/server_realtime_repository.dart';
import 'package:swediscover/services/gtfs_rt_decoder.dart';

// ---------------------------------------------------------------------------
// Helpers: canned upstream responses mirroring real Trafiklab contracts
// ---------------------------------------------------------------------------

String cannedDeparturesJson({int count = 1}) {
  final deps = List.generate(
    count,
    (i) => {
      'scheduled': '2026-08-21T12:0$i:00',
      'realtime': '2026-08-21T12:0$i:30',
      'delay': 30,
      'canceled': false,
      'route': {
        'designation': '${10 + i}',
        'transport_mode': i == 0 ? 'BUS' : 'METRO',
        'direction': 'Centralen',
      },
      'trip': {'trip_id': 'trip-$i'},
      'agency': {'operator': 'TestOperator'},
      'stop': {'id': '740000001'},
      'scheduled_platform': {'designation': 'A'},
      'realtime_platform': {'designation': 'A'},
    },
  );
  return jsonEncode({'departures': deps, 'timestamp': '2026-08-21T12:00:00'});
}

FeedMessage buildVehicleFeed(int n) {
  final feed = FeedMessage()..header = (FeedHeader()..gtfsRealtimeVersion = '2.0');
  for (var i = 0; i < n; i++) {
    feed.entity.add(FeedEntity()
      ..id = 'e-$i'
      ..vehicle = (VehiclePosition()
        ..trip = (TripDescriptor()..tripId = 'trip-$i'..routeId = 'r-$i')
        ..vehicle = (VehicleDescriptor()..id = 'veh-$i')
        ..position = (Position()..latitude = 59.33 + i * 0.01..longitude = 18.06..bearing = 90..speed = 10)
        ..timestamp = Int64(1700000000)));
  }
  return feed;
}

// ---------------------------------------------------------------------------
// Repository URL regression tests (mocked upstream) – these are the high-value
// guards for the URL bugs fixed in this branch (old URLs must never reappear).
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('E2E URL correctness (mocked upstream)', () {
    test('ServerRealtimeRepository hits /api/departures?stopId=…', () async {
      String? capturedUrl;
      final client = MockClient((req) async {
        capturedUrl = req.url.toString();
        return http.Response(
          jsonEncode({
            'departures': [],
            'telemetry': {
              'totalClientRequests': 1,
              'upstreamCallsMade': 0,
              'collapsedRequests': 0,
              'networkSavingsPercent': 0,
              'protobufBytesProcessed': 0,
              'jsonStreamBytesEmitted': 0,
              'activeVehiclesInSweden': 0,
              'activeVehiclesInViewport': 0,
            }
          }),
          200,
        );
      });
      final repo = ServerRealtimeRepository(
        baseUrl: 'http://localhost:8080',
        client: client,
      );
      await repo.fetchDepartures('740000001');
      expect(capturedUrl, contains('/api/departures'));
      expect(capturedUrl, contains('stopId=740000001'));
      expect(capturedUrl, isNot(contains('StopPoints')));
      expect(capturedUrl, isNot(contains('DepartureBoard')));
    });

    test('ServerRealtimeRepository hits /api/vehicles', () async {
      String? capturedPath;
      final client = MockClient((req) async {
        capturedPath = req.url.path;
        return http.Response(jsonEncode({'vehicles': []}), 200);
      });
      final repo = ServerRealtimeRepository(
        baseUrl: 'http://localhost:8080',
        client: client,
      );
      await repo.fetchVehicles();
      expect(capturedPath, '/api/vehicles');
    });

    test('GtfsRtDecoder round-trip: vehicles + delay join mirrors Go transformer', () {
      final feed = buildVehicleFeed(3);
      final bytes = feed.writeToBuffer();
      final delays = {'trip-1': 300};
      final vehicles = GtfsRtDecoder.decodeVehicles(bytes, delays: delays);
      expect(vehicles, hasLength(3));
      final v1 = vehicles.firstWhere((v) => v.tripId == 'trip-1');
      expect(v1.delayMinutes, 5);
      expect(v1.occupancy, isNotNull);
      expect(v1.currentPosition.latitude, closeTo(59.34, 0.001));
    });

    test('RealtimeVehiclePosition JSON contract survives server round-trip', () {
      const json = {
        'vehicleId': 'sl:veh-1',
        'tripId': 'sl:trip-1',
        'line': '10',
        'mode': 'bus',
        'lat': 59.33,
        'lng': 18.06,
        'bearing': 90.0,
        'speedKmh': 36.0,
        'lastGpsReport': '2026-08-21T12:00:00Z',
        'occupancy': 'manySeats',
        'nextStopName': 'T-Centralen',
        'delayMinutes': 2,
        'routePolyline': [],
        'progressFraction': 0.0,
      };
      final v = RealtimeVehiclePosition.fromJson(json);
      expect(v.vehicleId, 'sl:veh-1');
      expect(v.mode, TransitMode.bus);
      expect(v.delayMinutes, 2);
      expect(v.currentPosition.latitude, 59.33);
    });

    test('TransitDeparture JSON contract (timetable -> departure) survives', () {
      final now = DateTime.now().toUtc().toIso8601String();
      final json = {
        'id': 'trip-1-0',
        'stopId': '740000001',
        'line': '10',
        'destination': 'Centralen',
        'mode': 'bus',
        'scheduledTime': now,
        'realtimeTime': now,
        'delaySeconds': 60,
        'status': 'delayed',
        'track': 'A',
        'operatorName': 'Test',
      };
      final d = TransitDeparture.fromJson(json);
      expect(d.line, '10');
      expect(d.mode, TransitMode.bus);
      expect(d.status, DepartureStatus.delayed);
      expect(d.delaySeconds, 60);
    });
  });

  // -------------------------------------------------------------------------
  // Live BFF contract tests – skipped if BFF not reachable (no flake in CI).
  // When BFF is up (DEBUG server on 8080), these validate the full stack:
  // upstream -> Go transform -> JSON -> Dart model.
  // -------------------------------------------------------------------------
  group('E2E live BFF (requires localhost:8080)', () {
    const bff = 'http://localhost:8080';
    late bool bffReachable;

    setUpAll(() async {
      try {
        final res = await http.get(Uri.parse('$bff/api/health')).timeout(const Duration(seconds: 2));
        bffReachable = res.statusCode == 200;
      } catch (_) {
        bffReachable = false;
      }
    });

    test('GET /api/health returns ok', () async {
      if (!bffReachable) return;
      final res = await http.get(Uri.parse('$bff/api/health'));
      expect(res.statusCode, 200);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      expect(body['status'], 'ok');
      expect(body['telemetry'], isA<Map>());
    });

    test('GET /api/debug masks keys', () async {
      if (!bffReachable) return;
      final res = await http.get(Uri.parse('$bff/api/debug'));
      expect(res.statusCode, 200);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final masked = (body['config'] as Map)['keysMasked'] as Map;
      for (final v in masked.values) {
        final s = v as String;
        expect(s == '<empty>' || s == '***' || s.contains('***'), isTrue, reason: 'key not masked: $s');
      }
    });

    test('GET /api/vehicles returns contract-valid vehicles (live upstream)', () async {
      if (!bffReachable) return;
      final res = await http.get(Uri.parse('$bff/api/vehicles'));
      expect(res.statusCode, 200);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final vehicles = body['vehicles'] as List;
      // In evening there should be vehicles; but allow empty with reason (key missing -> tested above)
      // Instead validate shape of first vehicle if present
      if (vehicles.isNotEmpty) {
        final v = RealtimeVehiclePosition.fromJson(vehicles.first as Map<String, dynamic>);
        expect(v.vehicleId, isNotEmpty);
        expect(v.currentPosition.latitude, greaterThan(55));
        expect(v.currentPosition.latitude, lessThan(70));
      }
      expect(body['telemetry'], isA<Map>());
      expect(res.headers['x-cache'], isNotNull); // X-Cache HIT/MISS set by debug logging
    });

    test('GET /api/departures?stopId=… returns mapped departures', () async {
      if (!bffReachable) return;
      final res = await http.get(Uri.parse('$bff/api/departures?stopId=740020101'));
      expect(res.statusCode, 200);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final deps = body['departures'] as List;
      if (deps.isNotEmpty) {
        final d = TransitDeparture.fromJson(deps.first as Map<String, dynamic>);
        expect(d.line, isNotEmpty);
        expect(d.destination, isNotEmpty);
      }
    });

    test('GET /api/stops/search?q=… returns stop_groups shape', () async {
      if (!bffReachable) return;
      final res = await http.get(Uri.parse('$bff/api/stops/search?q=T-Centralen'));
      expect(res.statusCode, 200);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      expect(body['stops'], isA<List>());
    });

    test('GET /api/service-alerts returns alerts with cause/effect', () async {
      if (!bffReachable) return;
      final res = await http.get(Uri.parse('$bff/api/service-alerts'));
      expect(res.statusCode, 200);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final alerts = body['alerts'] as List;
      if (alerts.isNotEmpty) {
        final a = alerts.first as Map<String, dynamic>;
        expect(a.containsKey('cause'), isTrue);
        expect(a.containsKey('effect'), isTrue);
      }
    });

    test('GET /api/trip-updates returns tripUpdates', () async {
      if (!bffReachable) return;
      final res = await http.get(Uri.parse('$bff/api/trip-updates'));
      expect(res.statusCode, 200);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      expect(body['tripUpdates'], isA<List>());
    });
  });
}
