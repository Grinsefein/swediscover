import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/departure_model.dart';
import '../models/vehicle_position_model.dart';
import 'realtime_repository.dart';

/// Echter HTTP/WebSocket-Client gegen das SweDiscover Backend-for-Frontend.
///
/// Alle Trafiklab-/Trafikverket-Zugriffe laufen serverseitig (API-Keys verbleiben
/// im Server). Der Client konsumiert ausschließlich die kompakten JSON-Streams.
class ServerRealtimeRepository extends RealtimeRepository {
  final String baseUrl;
  final http.Client _client;
  final Duration timeout;

  bool _isBoundingBoxFilterActive = true;

  RealtimeTelemetry _telemetry = const RealtimeTelemetry(
    totalClientRequests: 0,
    upstreamCallsMade: 0,
    collapsedRequests: 0,
    networkSavingsPercent: 0,
    protobufBytesProcessed: 0,
    jsonStreamBytesEmitted: 0,
    activeVehiclesInSweden: 0,
    activeVehiclesInViewport: 0,
  );

  ServerRealtimeRepository({
    String? baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 8),
  })  : baseUrl = baseUrl ?? _defaultBackendUrl(),
        _client = client ?? http.Client();

  @override
  RealtimeTelemetry get telemetry => _telemetry;

  @override
  bool get isBoundingBoxFilterActive => _isBoundingBoxFilterActive;

  @override
  void toggleBoundingBoxFilter() {
    _isBoundingBoxFilterActive = !_isBoundingBoxFilterActive;
    notifyListeners();
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final joined = path.startsWith('/') ? '$baseUrl$path' : '$baseUrl/$path';
    return Uri.parse(joined).replace(queryParameters: query);
  }

  /// Backend-Server URL mit sinnvollen Defaults für verschiedene Umgebungen
  /// - Android Emulator: http://10.0.2.2:8080 (Loopback zu localhost)
  /// - iOS Simulator: http://localhost:8080
  /// - Web/Desktop: http://localhost:8080
  /// - Produktion: über Server_URL Environment Variable setzen
  static String _defaultBackendUrl() {
    const envUrl = String.fromEnvironment('Server_URL', defaultValue: '');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    
    // Platform-spezifische Defaults
    // Für Android Emulator ist 10.0.2.2 der Host-Loopback
    // Für alle anderen Plattformen verwenden wir localhost
    return 'http://localhost:8080';
  }

  Future<T> _getJson<T>(
    String path,
    T Function(Map<String, dynamic>) parse, {
    Map<String, String>? query,
  }) async {
    final res = await _client.get(_uri(path, query)).timeout(timeout);
    if (res.statusCode != 200) {
      throw HttpException('Server $path → HTTP ${res.statusCode}: ${res.body}');
    }
    return parse(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Abfahrtsmonitor: Request-Collapsing erfolgt im Server.
  @override
  Future<List<TransitDeparture>> fetchDepartures(String stopId) async {
    final res = await _getJson('api/departures', (json) => json, query: {
      'stopId': stopId,
    });
    final list = (res['departures'] as List<dynamic>? ?? [])
        .map((e) => TransitDeparture.fromJson(e as Map<String, dynamic>))
        .toList();
    _updateTelemetry(res);
    return list;
  }

  /// Fahrzeug-Snapshot aus dem Server-Cache (aktuelle Bounding-Box-Filterung).
  @override
  Future<List<RealtimeVehiclePosition>> fetchVehicles() async {
    final res = await _getJson('api/vehicles', (json) => json);
    final list = (res['vehicles'] as List<dynamic>? ?? [])
        .map((e) => RealtimeVehiclePosition.fromJson(e as Map<String, dynamic>))
        .toList();
    _updateTelemetry(res);
    return list;
  }

  /// Live-Stream der Fahrzeugpositionen über den Server-WebSocket.
  /// Der Server filtert anhand der übermittelten Bounding-Box.
  Stream<List<RealtimeVehiclePosition>> subscribeVehicles({
    double? minLat,
    double? minLng,
    double? maxLat,
    double? maxLng,
  }) {
    final controller = StreamController<List<RealtimeVehiclePosition>>.broadcast();

    final wsScheme = baseUrl.startsWith('https') ? 'wss' : 'ws';
    final wsHost = baseUrl.replaceFirst(RegExp('^https?://'), '');

    final hasBbox = minLat != null && minLng != null && maxLat != null && maxLng != null;
    final bbox = hasBbox
        ? '&bbox=${minLat.toStringAsFixed(5)},${minLng.toStringAsFixed(5)},${maxLat.toStringAsFixed(5)},${maxLng.toStringAsFixed(5)}'
        : '';

    void connect() {
      final channel = WebSocketChannel.connect(Uri.parse('$wsScheme://$wsHost/ws?broadcast=vehicles$bbox'));
      channel.stream.listen(
        (message) {
          final decoded = jsonDecode(message as String) as Map<String, dynamic>;
          if (decoded['type'] != 'vehicles') return;
          final items = (decoded['items'] as List<dynamic>? ?? [])
              .map((e) => RealtimeVehiclePosition.fromJson(e as Map<String, dynamic>))
              .toList();
          if (controller.isClosed) return;
          controller.add(items);
        },
        onError: (_) => _scheduleReconnect(connect),
        onDone: () => _scheduleReconnect(connect),
        cancelOnError: true,
      );
    }

    connect();

    controller.onCancel = () => controller.close();
    return controller.stream;
  }

  static const _reconnectDelay = Duration(seconds: 3);
  void _scheduleReconnect(void Function() connect) {
    Timer(_reconnectDelay, connect);
  }

  /// Aktualisiert die gecachten Telemetrie-Metriken aus der Server-Antwort.
  void _updateTelemetry(Map<String, dynamic> json) {
    _telemetry = RealtimeTelemetry(
      totalClientRequests: (json['totalClientRequests'] as num?)?.toInt() ?? _telemetry.totalClientRequests,
      upstreamCallsMade: (json['upstreamCallsMade'] as num?)?.toInt() ?? _telemetry.upstreamCallsMade,
      collapsedRequests: (json['collapsedRequests'] as num?)?.toInt() ?? _telemetry.collapsedRequests,
      networkSavingsPercent: (json['networkSavingsPercent'] as num?)?.toDouble() ?? _telemetry.networkSavingsPercent,
      protobufBytesProcessed: (json['protobufBytesProcessed'] as num?)?.toInt() ?? _telemetry.protobufBytesProcessed,
      jsonStreamBytesEmitted: (json['jsonStreamBytesEmitted'] as num?)?.toInt() ?? _telemetry.jsonStreamBytesEmitted,
      activeVehiclesInSweden: (json['activeVehiclesInSweden'] as num?)?.toInt() ?? _telemetry.activeVehiclesInSweden,
      activeVehiclesInViewport: (json['activeVehiclesInViewport'] as num?)?.toInt() ?? _telemetry.activeVehiclesInViewport,
    );
    notifyListeners();
  }
}

class HttpException implements Exception {
  final String message;
  HttpException(this.message);

  @override
  String toString() => message;
}