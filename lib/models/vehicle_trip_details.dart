import 'package:latlong2/latlong.dart';

import 'vehicle_position_model.dart';

class TripStopDetail {
  final String stopId;
  final String name;
  final LatLng? position; // null wenn lat==0
  final int stopSequence;
  final String arrivalTime; // "12:05:00" aus static GTFS
  final String departureTime;
  final int arrivalDelaySeconds;
  final int departureDelaySeconds;

  const TripStopDetail({
    required this.stopId,
    required this.name,
    required this.position,
    required this.stopSequence,
    required this.arrivalTime,
    required this.departureTime,
    required this.arrivalDelaySeconds,
    required this.departureDelaySeconds,
  });

  bool get hasDelay =>
      arrivalDelaySeconds != 0 || departureDelaySeconds != 0;

  int get effectiveDelay => departureDelaySeconds != 0
      ? departureDelaySeconds
      : arrivalDelaySeconds;

  factory TripStopDetail.fromJson(Map<String, dynamic> json) {
    final lat = (json['lat'] as num?)?.toDouble() ?? 0;
    final lng = (json['lng'] as num?)?.toDouble() ?? 0;
    return TripStopDetail(
      stopId: json['stopId'] as String? ?? '',
      name: json['name'] as String? ?? json['stopId'] as String? ?? '',
      position: (lat != 0 || lng != 0) ? LatLng(lat, lng) : null,
      stopSequence: (json['stopSequence'] as num?)?.toInt() ?? 0,
      arrivalTime: json['arrivalTime'] as String? ?? '',
      departureTime: json['departureTime'] as String? ?? '',
      arrivalDelaySeconds: (json['arrivalDelaySeconds'] as num?)?.toInt() ?? 0,
      departureDelaySeconds: (json['departureDelaySeconds'] as num?)?.toInt() ?? 0,
    );
  }
}

class TripRouteInfo {
  final String routeId;
  final String shortName;
  final String longName;
  final int type;

  const TripRouteInfo({
    required this.routeId,
    required this.shortName,
    required this.longName,
    required this.type,
  });

  String get displayName =>
      shortName.isNotEmpty ? shortName : longName.isNotEmpty ? longName : routeId;

  factory TripRouteInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const TripRouteInfo(routeId: '', shortName: '', longName: '', type: 3);
    }
    return TripRouteInfo(
      routeId: json['routeId'] as String? ?? '',
      shortName: json['shortName'] as String? ?? '',
      longName: json['longName'] as String? ?? '',
      type: (json['type'] as num?)?.toInt() ?? 3,
    );
  }
}

class VehicleTripDetails {
  final String vehicleId;
  final String tripId;
  final String rawTripId;
  final RealtimeVehiclePosition vehicle;
  final TripRouteInfo route;
  final String tripHeadsign;
  final List<TripStopDetail> stops;
  final List<LatLng> shape;
  final int currentStopSequence;
  final String currentStatus;
  final String nextStopId;
  final bool gtfsReady;

  const VehicleTripDetails({
    required this.vehicleId,
    required this.tripId,
    required this.rawTripId,
    required this.vehicle,
    required this.route,
    required this.tripHeadsign,
    required this.stops,
    required this.shape,
    required this.currentStopSequence,
    required this.currentStatus,
    required this.nextStopId,
    required this.gtfsReady,
  });

  factory VehicleTripDetails.fromJson(Map<String, dynamic> json) {
    final vehicleJson = json['vehicle'] as Map<String, dynamic>? ?? {};
    // Explicit nulls would override RealtimeVehiclePosition's fallbacks, so
    // only forward keys that are actually present.
    final resolvedVehicle = RealtimeVehiclePosition.fromJson({
      'lat': 0,
      'lng': 0,
      if (json['vehicleId'] != null) 'vehicleId': json['vehicleId'],
      if (json['tripId'] != null) 'tripId': json['tripId'],
      ...vehicleJson,
    });

    // Polyline shape: [[lat,lng],...]
    final rawShape = json['shape'] as List<dynamic>? ?? const [];
    final shape = rawShape.map((e) {
      final pair = e as List<dynamic>;
      return LatLng((pair[0] as num).toDouble(), (pair[1] as num).toDouble());
    }).toList();

    final rawStops = json['stops'] as List<dynamic>? ?? const [];
    final stops = rawStops
        .map((e) => TripStopDetail.fromJson(e as Map<String, dynamic>))
        .toList();

    return VehicleTripDetails(
      vehicleId: json['vehicleId'] as String? ?? '',
      tripId: json['tripId'] as String? ?? '',
      rawTripId: json['rawTripId'] as String? ?? '',
      vehicle: resolvedVehicle,
      route: TripRouteInfo.fromJson(json['route'] as Map<String, dynamic>?),
      tripHeadsign: json['tripHeadsign'] as String? ?? '',
      stops: stops,
      shape: shape,
      currentStopSequence: (json['currentStopSequence'] as num?)?.toInt() ?? 0,
      currentStatus: json['currentStatus'] as String? ?? '',
      nextStopId: json['nextStopId'] as String? ?? '',
      gtfsReady: json['gtfsReady'] as bool? ?? false,
    );
  }

  // Progress: index des nächsten Stops (basierend auf nextStopId oder currentStatus)
  int get nextStopIndex {
    if (stops.isEmpty) return -1;
    final idx = stops.indexWhere((s) => s.stopId == nextStopId);
    if (idx >= 0) return idx;
    // Fallback: currentStopSequence -> nächster
    if (currentStopSequence > 0) {
      final bySeq = stops.indexWhere((s) => s.stopSequence == currentStopSequence + 1);
      if (bySeq >= 0) return bySeq;
    }
    return -1;
  }
}
