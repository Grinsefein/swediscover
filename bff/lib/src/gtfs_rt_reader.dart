import 'gtfs_rt/gtfs_realtime.pb.dart';

/// Wandelt GTFS-RT-VehiclePositions-Protobufs in das kompakte Fahrzeug-JSON
/// der Flutter-App um (vgl. `RealtimeVehiclePosition.fromJson`).
class GtfsRtReader {
  static List<Map<String, dynamic>> parseVehicles(
    List<int> bytes, {
    DateTime? now,
  }) {
    final feed = FeedMessage.fromBuffer(bytes);
    // now is used directly below
    final result = <Map<String, dynamic>>[];

    for (final entity in feed.entity) {
      if (entity.isDeleted || !entity.hasVehicle()) continue;
      final vehicle = entity.vehicle;
      final position = vehicle.position;
      if (!position.hasLatitude() || !position.hasLongitude()) continue;

      // Workaround für Analyzer: VehiclePosition.vehicle Getter wird per dynamic zugegriffen
      final vDesc = (vehicle as dynamic).vehicle as VehicleDescriptor?;

      result.add({
        'vehicleId': vDesc?.id ?? entity.id,
        'tripId': vehicle.trip.hasTripId() ? vehicle.trip.tripId : '',
        'line': vehicle.trip.hasRouteId() ? vehicle.trip.routeId : '',
        // Ohne Join auf die statischen GTFS-Daten ist der Verkehrsmitteltyp
        // nicht bekannt; wird mit dem statischen Importer ergänzt.
        'mode': 'bus',
        'lat': position.latitude,
        'lng': position.longitude,
        'bearing': position.hasBearing() ? position.bearing : 0.0,
        'speedKmh': position.hasSpeed() ? position.speed * 3.6 : 0.0,
        'lastGpsReport': _timestampToIso(vehicle, position, DateTime.now()),
        'occupancy': _occupancy(vehicle.occupancyStatus),
        'nextStopName': vehicle.hasStopId() ? vehicle.stopId : '',
        'delayMinutes': 0,
        'routePolyline': <List<double>>[],
        'progressFraction': 0.0,
      });
    }
    return result;
  }

  static String _timestampToIso(
    VehiclePosition vehicle,
    Position position,
    DateTime fallback,
  ) {
    final seconds = vehicle.hasTimestamp()
        ? vehicle.timestamp
        : (position.hasTimestamp() ? position.timestamp : null);
    if (seconds == null) return fallback.toIso8601String();
    return DateTime.fromMillisecondsSinceEpoch(
      seconds.toInt() * 1000,
      isUtc: true,
    ).toIso8601String();
  }

  static String _occupancy(VehiclePosition_OccupancyStatus status) {
    switch (status) {
      case VehiclePosition_OccupancyStatus.EMPTY:
        return 'empty';
      case VehiclePosition_OccupancyStatus.MANY_SEATS_AVAILABLE:
      case VehiclePosition_OccupancyStatus.NO_DATA_AVAILABLE:
        return 'manySeats';
      case VehiclePosition_OccupancyStatus.FEW_SEATS_AVAILABLE:
        return 'fewSeats';
      case VehiclePosition_OccupancyStatus.STANDING_ROOM_ONLY:
      case VehiclePosition_OccupancyStatus.CRUSHED_STANDING_ROOM_ONLY:
        return 'standingRoom';
      case VehiclePosition_OccupancyStatus.FULL:
        return 'full';
      default:
        return 'manySeats';
    }
  }
}
