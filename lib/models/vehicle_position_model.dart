import 'package:latlong2/latlong.dart';
import 'departure_model.dart';

class RealtimeVehiclePosition {
  final String vehicleId;
  final String tripId;
  final String line;
  final TransitMode mode;
  final LatLng currentPosition;
  final LatLng startPosition;
  final LatLng targetPosition;
  final double bearing; // 0..360 degrees
  final double speedKmh;
  final DateTime lastGpsReport;
  final OccupancyStatus occupancy;
  final String nextStopName;
  final int delayMinutes;
  final List<LatLng> routePolyline;
  final double progressFraction; // 0.0 .. 1.0 along polyline

  const RealtimeVehiclePosition({
    required this.vehicleId,
    required this.tripId,
    required this.line,
    required this.mode,
    required this.currentPosition,
    required this.startPosition,
    required this.targetPosition,
    required this.bearing,
    required this.speedKmh,
    required this.lastGpsReport,
    required this.occupancy,
    required this.nextStopName,
    required this.delayMinutes,
    required this.routePolyline,
    required this.progressFraction,
  });

  factory RealtimeVehiclePosition.fromJson(Map<String, dynamic> json) {
    final mode = TransitMode.values.asNameMap()[json['mode']] ?? TransitMode.bus;
    final occupancy = OccupancyStatus.values.asNameMap()[json['occupancy']] ?? OccupancyStatus.manySeats;

    final polyRaw = (json['routePolyline'] as List<dynamic>?) ?? const [];
    final polyline = polyRaw.map((p) {
      final coords = p as List<dynamic>;
      return LatLng((coords[0] as num).toDouble(), (coords[1] as num).toDouble());
    }).toList();

    final pos = LatLng(
      (json['lat'] as num).toDouble(),
      (json['lng'] as num).toDouble(),
    );

    return RealtimeVehiclePosition(
      vehicleId: json['vehicleId'] as String,
      tripId: json['tripId'] as String? ?? '',
      line: json['line'] as String? ?? '',
      mode: mode,
      currentPosition: pos,
      startPosition: polyline.isNotEmpty ? polyline.first : pos,
      targetPosition: polyline.isNotEmpty ? polyline.last : pos,
      bearing: (json['bearing'] as num?)?.toDouble() ?? 0,
      speedKmh: (json['speedKmh'] as num?)?.toDouble() ?? 0,
      lastGpsReport: json['lastGpsReport'] != null
          ? DateTime.tryParse(json['lastGpsReport'] as String) ?? DateTime.now()
          : DateTime.now(),
      occupancy: occupancy,
      nextStopName: json['nextStopName'] as String? ?? '',
      delayMinutes: (json['delayMinutes'] as num?)?.toInt() ?? 0,
      routePolyline: polyline,
      progressFraction: (json['progressFraction'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'vehicleId': vehicleId,
        'tripId': tripId,
        'line': line,
        'mode': mode.name,
        'lat': currentPosition.latitude,
        'lng': currentPosition.longitude,
        'bearing': bearing,
        'speedKmh': speedKmh,
        'lastGpsReport': lastGpsReport.toIso8601String(),
        'occupancy': occupancy.name,
        'nextStopName': nextStopName,
        'delayMinutes': delayMinutes,
        'routePolyline': routePolyline
            .map((p) => [p.latitude, p.longitude])
            .toList(),
        'progressFraction': progressFraction,
      };

  RealtimeVehiclePosition copyWith({
    LatLng? currentPosition,
    double? bearing,
    double? speedKmh,
    double? progressFraction,
  }) {
    return RealtimeVehiclePosition(
      vehicleId: vehicleId,
      tripId: tripId,
      line: line,
      mode: mode,
      currentPosition: currentPosition ?? this.currentPosition,
      startPosition: startPosition,
      targetPosition: targetPosition,
      bearing: bearing ?? this.bearing,
      speedKmh: speedKmh ?? this.speedKmh,
      lastGpsReport: lastGpsReport,
      occupancy: occupancy,
      nextStopName: nextStopName,
      delayMinutes: delayMinutes,
      routePolyline: routePolyline,
      progressFraction: progressFraction ?? this.progressFraction,
    );
  }
}
