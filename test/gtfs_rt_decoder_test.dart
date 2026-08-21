import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart';

import 'package:swediscover/models/departure_model.dart';
import 'package:swediscover/services/gtfs_rt_decoder.dart';

/// Round-Trip-Tests: Fixtures werden mit den offiziellen Bindings gebaut und
/// via writeToBuffer in echtes GTFS-RT-Wire-Format serialisiert, dann durch
/// den Decoder gejagt. Spiegelstück zu backend/gtfs_transform_test.go.
void main() {
  FeedMessage buildFeed() {
    final feed = FeedMessage()
      ..header = (FeedHeader()
        ..gtfsRealtimeVersion = '2.0'
        ..timestamp = Int64(1700000000));

    feed.entity.add(FeedEntity()
      ..id = 'entity-1'
      ..vehicle = (VehiclePosition()
        ..trip = (TripDescriptor()
          ..tripId = 'trip-1'
          ..routeId = 'route-17')
        ..vehicle = (VehicleDescriptor()..id = 'veh-42')
        ..position = (Position()
          ..latitude = 59.3293
          ..longitude = 18.0686
          ..bearing = 90.0
          ..speed = 12.5)
        ..stopId = 'stop-740000001'
        ..timestamp = Int64(1699999999)
        ..occupancyStatus = VehiclePosition_OccupancyStatus.FEW_SEATS_AVAILABLE));

    // Entity ohne Position muss ignoriert werden
    feed.entity.add(FeedEntity()
      ..id = 'entity-empty'
      ..alert = (Alert()..headerText = (TranslatedString()
        ..translation.add(TranslatedString_Translation()..text = 'Störung'))));

    return feed;
  }

  test('decodeVehicles parst VehiclePositions inklusive Delay-Join', () {
    final bytes = buildFeed().writeToBuffer();
    final vehicles = GtfsRtDecoder.decodeVehicles(bytes, delays: {'trip-1': 300});

    expect(vehicles, hasLength(1));
    final v = vehicles.single;

    expect(v.vehicleId, 'veh-42');
    expect(v.tripId, 'trip-1');
    expect(v.line, 'route-17');
    expect(v.currentPosition.latitude, closeTo(59.3293, 0.0001));
    expect(v.currentPosition.longitude, closeTo(18.0686, 0.0001));
    expect(v.bearing, 90.0);
    expect(v.speedKmh, closeTo(45.0, 0.01)); // 12.5 m/s * 3.6
    expect(v.occupancy, OccupancyStatus.fewSeats);
    expect(v.nextStopName, 'stop-740000001');
    expect(v.delayMinutes, 5); // 300s aus TripUpdates-Join
    expect(v.lastGpsReport.year, greaterThan(2020));
  });

  test('decodeVehicles dedupliziert nach vehicleId', () {
    final feed = buildFeed();
    final second = FeedEntity()
      ..id = 'entity-2'
      ..vehicle = (VehiclePosition()
        ..vehicle = (VehicleDescriptor()..id = 'veh-42')
        ..position = (Position()
          ..latitude = 57.7
          ..longitude = 11.97));
    feed.entity.add(second);

    final vehicles = GtfsRtDecoder.decodeVehicles(feed.writeToBuffer());
    expect(vehicles, hasLength(1));
    expect(vehicles.single.currentPosition.latitude, closeTo(57.7, 0.0001));
  });

  test('decodeVehicles fällt auf Entity-ID zurück ohne VehicleDescriptor', () {
    final feed = FeedMessage()
      ..header = (FeedHeader()..gtfsRealtimeVersion = '2.0')
      ..entity.add(FeedEntity()
        ..id = 'only-entity-id'
        ..vehicle = (VehiclePosition()
          ..position = (Position()
            ..latitude = 1.0
            ..longitude = 2.0)));

    final vehicles = GtfsRtDecoder.decodeVehicles(feed.writeToBuffer());
    expect(vehicles.single.vehicleId, 'only-entity-id');
  });

  test('decodeTripDelays extrahiert Trip- und StopTime-Delays', () {
    final feed = FeedMessage()
      ..header = (FeedHeader()..gtfsRealtimeVersion = '2.0');

    feed.entity.add(FeedEntity()
      ..id = 'tu-1'
      ..tripUpdate = (TripUpdate()
        ..trip = (TripDescriptor()..tripId = 'trip-a')
        ..delay = 120));

    feed.entity.add(FeedEntity()
      ..id = 'tu-2'
      ..tripUpdate = (TripUpdate()
        ..trip = (TripDescriptor()..tripId = 'trip-b')
        ..stopTimeUpdate.add(TripUpdate_StopTimeUpdate()
          ..arrival = (TripUpdate_StopTimeEvent()..delay = -60))));

    final delays = GtfsRtDecoder.decodeTripDelays(feed.writeToBuffer());

    expect(delays['trip-a'], 120);
    expect(delays['trip-b'], -60);
    expect(delays, hasLength(2));
  });
}
