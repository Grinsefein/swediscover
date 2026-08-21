import 'dart:typed_data';

import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart';
import 'package:latlong2/latlong.dart';

import '../models/departure_model.dart';
import '../models/vehicle_position_model.dart';

/// Dekodiert GTFS-RT-Protobuf-Feeds (offizielle Bindings) in die App-Modelle.
///
/// Spiegelbildlich zum Go-BFF (backend/gtfs_transform.go): gleiche Feld-Mappings,
/// gleiche Occupancy-Umsetzung, gleicher TripUpdate-Delay-Join.
class GtfsRtDecoder {
  const GtfsRtDecoder._();

  /// Parst einen VehiclePositions-Feed und wendet optional den Delay-Join aus
  /// dem TripUpdates-Feed an (tripId -> delaySeconds).
  static List<RealtimeVehiclePosition> decodeVehicles(
    Uint8List bytes, {
    Map<String, int> delays = const {},
  }) {
    final feed = FeedMessage.fromBuffer(bytes);
    final vehicles = <RealtimeVehiclePosition>[];
    final seenIds = <String>{};

    for (final entity in feed.entity) {
      final vp = entity.vehicle;
      if (!vp.hasPosition()) continue;

      final position = vp.position;
      final pos = LatLng(
        position.latitude.toDouble(),
        position.longitude.toDouble(),
      );

      var vehicleId = vp.vehicle.id;
      if (vehicleId.isEmpty) vehicleId = entity.id;

      // Deduplizierung nach vehicleId (letzter Eintrag gewinnt)
      if (!seenIds.add(vehicleId)) {
        vehicles.removeWhere((v) => v.vehicleId == vehicleId);
      }

      final tripId = vp.trip.tripId;
      final delaySeconds = delays[tripId] ?? 0;

      vehicles.add(RealtimeVehiclePosition(
        vehicleId: vehicleId,
        tripId: tripId,
        line: vp.trip.routeId,
        mode: TransitMode.bus,
        currentPosition: pos,
        startPosition: pos,
        targetPosition: pos,
        bearing: position.bearing.toDouble(),
        speedKmh: position.speed * 3.6,
        lastGpsReport: vp.hasTimestamp()
            ? DateTime.fromMillisecondsSinceEpoch(vp.timestamp.toInt() * 1000,
                isUtc: true)
            : DateTime.now().toUtc(),
        occupancy: _mapOccupancy(vp.occupancyStatus),
        nextStopName: vp.stopId,
        delayMinutes: delaySeconds ~/ 60,
        routePolyline: const [],
        progressFraction: 0,
      ));
    }
    return vehicles;
  }

  /// Parst einen TripUpdates-Feed zu tripId -> delaySeconds.
  static Map<String, int> decodeTripDelays(Uint8List bytes) {
    final feed = FeedMessage.fromBuffer(bytes);
    final delays = <String, int>{};

    for (final entity in feed.entity) {
      final tu = entity.tripUpdate;
      if (!tu.hasTrip()) continue;
      final tripId = tu.trip.tripId;
      if (tripId.isEmpty) continue;

      if (tu.delay != 0) {
        delays[tripId] = tu.delay;
        continue;
      }
      for (final stu in tu.stopTimeUpdate) {
        if (stu.arrival.delay != 0) {
          delays[tripId] = stu.arrival.delay;
          break;
        }
        if (stu.departure.delay != 0) {
          delays[tripId] = stu.departure.delay;
          break;
        }
      }
    }
    return delays;
  }

  static OccupancyStatus _mapOccupancy(VehiclePosition_OccupancyStatus status) {
    switch (status) {
      case VehiclePosition_OccupancyStatus.EMPTY:
        return OccupancyStatus.empty;
      case VehiclePosition_OccupancyStatus.MANY_SEATS_AVAILABLE:
        return OccupancyStatus.manySeats;
      case VehiclePosition_OccupancyStatus.FEW_SEATS_AVAILABLE:
        return OccupancyStatus.fewSeats;
      case VehiclePosition_OccupancyStatus.STANDING_ROOM_ONLY:
        return OccupancyStatus.standingRoom;
      case VehiclePosition_OccupancyStatus.CRUSHED_STANDING_ROOM_ONLY:
      case VehiclePosition_OccupancyStatus.FULL:
      case VehiclePosition_OccupancyStatus.NOT_ACCEPTING_PASSENGERS:
        return OccupancyStatus.full;
      default:
        return OccupancyStatus.manySeats;
    }
  }
}
