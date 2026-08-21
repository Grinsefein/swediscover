import 'package:flutter/foundation.dart';

import '../models/departure_model.dart';
import '../models/vehicle_position_model.dart';

/// Realtime-Telemetrie des BFF (Request Collapsing / Protobuf-Stream-Metriken).
class RealtimeTelemetry {
  final int totalClientRequests;
  final int upstreamCallsMade;
  final int collapsedRequests;
  final double networkSavingsPercent;
  final int protobufBytesProcessed;
  final int jsonStreamBytesEmitted;
  final int activeVehiclesInSweden;
  final int activeVehiclesInViewport;

  const RealtimeTelemetry({
    required this.totalClientRequests,
    required this.upstreamCallsMade,
    required this.collapsedRequests,
    required this.networkSavingsPercent,
    required this.protobufBytesProcessed,
    required this.jsonStreamBytesEmitted,
    required this.activeVehiclesInSweden,
    required this.activeVehiclesInViewport,
  });
}

/// Datenvertrag zwischen Flutter-Client und Backend-for-Frontend.
///
/// Implementierungen:
///  - [MockRealtimeRepository]: simuliert den BFF (Demo/Dev, kein Backend nötig)
///  - [BffRealtimeRepository]: echter HTTP/WebSocket-Client gegen das BFF
abstract class RealtimeRepository extends ChangeNotifier {
  RealtimeTelemetry get telemetry;

  bool get isBoundingBoxFilterActive;
  void toggleBoundingBoxFilter();

  /// Abfahrtsmonitor für eine Haltestelle (BFF collapst parallele Requests).
  Future<List<TransitDeparture>> fetchDepartures(String stopId);

  /// Aktueller Fahrzeug-Snapshot (Live-Positionen inkl. Routen-Polylines).
  Future<List<RealtimeVehiclePosition>> fetchVehicles();
}