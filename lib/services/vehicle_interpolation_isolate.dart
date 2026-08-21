import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../models/vehicle_position_model.dart';

/// Vehicle Position Interpolation Engine running high-frequency vector steps.
/// Computes 60 FPS continuous movement along route polylines between sparse GTFS-RT updates.
class VehicleInterpolationIsolate {
  /// Linearly interpolates position between start coordinate and target coordinate based on fraction t (0.0 .. 1.0)
  static LatLng interpolatePosition(LatLng start, LatLng target, double t) {
    final clampedT = t.clamp(0.0, 1.0);
    final lat = start.latitude + (target.latitude - start.latitude) * clampedT;
    final lng = start.longitude + (target.longitude - start.longitude) * clampedT;
    return LatLng(lat, lng);
  }

  /// Calculates bearing angle (in degrees 0..360) between start and target GPS points
  static double calculateBearing(LatLng start, LatLng target) {
    final lat1 = start.latitude * (pi / 180.0);
    final lat2 = target.latitude * (pi / 180.0);
    final dLon = (target.longitude - start.longitude) * (pi / 180.0);

    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    final radians = atan2(y, x);
    final degrees = (radians * (180.0 / pi) + 360.0) % 360.0;
    return degrees;
  }

  /// Step update for a list of active real-time vehicles.
  /// Advances each vehicle along its polyline trajectory with smooth vector interpolation.
  static List<RealtimeVehiclePosition> stepVehiclePositions(
    List<RealtimeVehiclePosition> vehicles,
    double deltaSeconds,
  ) {
    return vehicles.map((vehicle) {
      if (vehicle.routePolyline.isEmpty) return vehicle;

      // Increment progress fraction (simulating ~15 second leg completion time)
      final speedFactor = max(0.02, vehicle.speedKmh / 800.0);
      double nextProgress = vehicle.progressFraction + (deltaSeconds * speedFactor);

      if (nextProgress >= 1.0) {
        nextProgress = 0.0; // Loop polyline route for continuous live demo simulation
      }

      final poly = vehicle.routePolyline;
      final totalSegments = poly.length - 1;
      if (totalSegments <= 0) return vehicle;

      // Find current polyline segment indices
      final segmentProgress = nextProgress * totalSegments;
      final currentIndex = segmentProgress.floor().clamp(0, totalSegments - 1);
      final nextIndex = (currentIndex + 1).clamp(0, totalSegments);

      final segmentFraction = segmentProgress - currentIndex;

      final startPt = poly[currentIndex];
      final targetPt = poly[nextIndex];

      final newPos = interpolatePosition(startPt, targetPt, segmentFraction);
      final newBearing = calculateBearing(startPt, targetPt);

      return vehicle.copyWith(
        currentPosition: newPos,
        bearing: newBearing,
        progressFraction: nextProgress,
      );
    }).toList();
  }
}
