import 'package:flutter_test/flutter_test.dart';

import 'package:swediscover/models/vehicle_trip_details.dart';

// Mirrors the JSON contract emitted by GET /api/trip-details/{vehicleId}
// (backend/vehicle_trip_handler.go).
Map<String, dynamic> cannedTripDetailsJson() => {
      'vehicleId': 'sl:veh-1',
      'tripId': 'sl:trip-42',
      'rawTripId': 'trip-42',
      'vehicle': {
        'vehicleId': 'sl:veh-1',
        'tripId': 'sl:trip-42',
        'line': '10',
        'mode': 'bus',
        'lat': 59.3310,
        'lng': 18.0620,
        'bearing': 90.0,
        'speedKmh': 36.0,
        'lastGpsReport': '2026-08-22T12:00:00Z',
        'occupancy': 'manySeats',
        'nextStopName': 'Slussen',
        'delayMinutes': 2,
        'routePolyline': [],
        'progressFraction': 0.25,
      },
      'route': {
        'routeId': 'sl:route-10',
        'shortName': '10',
        'longName': '',
        'type': 3,
      },
      'tripHeadsign': 'Sickla',
      'stops': [
        {
          'stopId': '740000001',
          'name': 'T-Centralen',
          'lat': 59.3300,
          'lng': 18.0590,
          'stopSequence': 1,
          'arrivalTime': '12:00:00',
          'departureTime': '12:01:00',
          'arrivalDelaySeconds': 0,
          'departureDelaySeconds': 30,
        },
        {
          'stopId': '740000002',
          'name': 'Slussen',
          'lat': 59.3200,
          'lng': 18.0710,
          'stopSequence': 2,
          'arrivalTime': '12:04:00',
          'departureTime': '12:05:00',
          'arrivalDelaySeconds': 120,
          'departureDelaySeconds': 150,
        },
        {
          // Missing coords -> position must be null (lat/lng == 0 sentinel)
          'stopId': '740000003',
          'name': 'Skansen',
          'lat': 0,
          'lng': 0,
          'stopSequence': 3,
          'arrivalTime': '',
          'departureTime': '',
          'arrivalDelaySeconds': 0,
          'departureDelaySeconds': 0,
        },
      ],
      'shape': [
        [59.33, 18.06],
        [59.32, 18.07],
        [59.31, 18.08],
      ],
      'currentStopSequence': 1,
      'currentStatus': 'IN_TRANSIT_TO',
      'nextStopId': '740000002',
      'gtfsReady': true,
    };

void main() {
  group('VehicleTripDetails.fromJson contract', () {
    late VehicleTripDetails d;

    setUp(() => d = VehicleTripDetails.fromJson(cannedTripDetailsJson()));

    test('parses identity + route + headsign', () {
      expect(d.vehicleId, 'sl:veh-1');
      expect(d.tripId, 'sl:trip-42');
      expect(d.rawTripId, 'trip-42');
      expect(d.route.routeId, 'sl:route-10');
      expect(d.route.displayName, '10');
      expect(d.tripHeadsign, 'Sickla');
      expect(d.gtfsReady, isTrue);
    });

    test('resolves embedded vehicle position', () {
      expect(d.vehicle.vehicleId, 'sl:veh-1');
      expect(d.vehicle.currentPosition.latitude, 59.331);
      expect(d.vehicle.currentPosition.longitude, 18.062);
      expect(d.vehicle.delayMinutes, 2);
    });

    test('parses ordered stops with delays', () {
      expect(d.stops, hasLength(3));
      expect(d.stops.map((s) => s.stopSequence).toList(), [1, 2, 3]);
      expect(d.stops[0].name, 'T-Centralen');
      expect(d.stops[1].hasDelay, isTrue);
      expect(d.stops[1].effectiveDelay, 150); // dep delay preferred
      expect(d.stops[0].position, isNotNull);
    });

    test('zero lat/lng -> null position', () {
      expect(d.stops[2].position, isNull);
    });

    test('decodes shape polyline pairs', () {
      expect(d.shape, hasLength(3));
      expect(d.shape.first.latitude, 59.33);
      expect(d.shape.last.longitude, 18.08);
    });

    test('nextStopIndex resolves via nextStopId', () {
      expect(d.nextStopIndex, 1); // Slussen
      expect(d.stops[d.nextStopIndex].name, 'Slussen');
    });

    test('nextStopIndex falls back to currentStopSequence+1', () {
      final json = cannedTripDetailsJson()..['nextStopId'] = '';
      final d2 = VehicleTripDetails.fromJson(json);
      expect(d2.nextStopIndex, 1);
    });
  });

  group('VehicleTripDetails robustness', () {
    test('empty/null-safe defaults', () {
      final d = VehicleTripDetails.fromJson(const {});
      expect(d.vehicleId, '');
      expect(d.stops, isEmpty);
      expect(d.shape, isEmpty);
      expect(d.route.displayName, ''); // empty routeId fallback
      expect(d.gtfsReady, isFalse);
      expect(d.nextStopIndex, -1);
    });

    test('null route object falls back to type 3 (bus)', () {
      final d = VehicleTripDetails.fromJson({'stops': []});
      expect(d.route.type, 3);
    });
  });
}
