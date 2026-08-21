/// Laufende Telemetrie-Metriken des BFF. Ein Snapshot wird an jede
/// API-Antwort angehängt, damit die App die Kennzahlen anzeigen kann
/// (vgl. `RealtimeTelemetry` in der Flutter-App).
class BffTelemetry {
  int totalClientRequests = 0;
  int upstreamCallsMade = 0;
  int collapsedRequests = 0;
  int protobufBytesProcessed = 0;
  int jsonStreamBytesEmitted = 0;
  int activeVehiclesInSweden = 0;
  int activeVehiclesInViewport = 0;

  void onClientRequest() => totalClientRequests++;

  void onUpstreamCall() => upstreamCallsMade++;

  void onCollapsedRequest() => collapsedRequests++;

  void onProtobufBytes(int bytes) => protobufBytesProcessed += bytes;

  void onJsonBytes(int bytes) => jsonStreamBytesEmitted += bytes;

  double get networkSavingsPercent {
    final total = totalClientRequests + collapsedRequests;
    if (total <= 0) return 0;
    return collapsedRequests / total * 100;
  }

  Map<String, dynamic> snapshot() => {
        'totalClientRequests': totalClientRequests,
        'upstreamCallsMade': upstreamCallsMade,
        'collapsedRequests': collapsedRequests,
        'networkSavingsPercent': networkSavingsPercent,
        'protobufBytesProcessed': protobufBytesProcessed,
        'jsonStreamBytesEmitted': jsonStreamBytesEmitted,
        'activeVehiclesInSweden': activeVehiclesInSweden,
        'activeVehiclesInViewport': activeVehiclesInViewport,
      };
}