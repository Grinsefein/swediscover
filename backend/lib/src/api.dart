import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart' as ws;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'config.dart';
import 'resrobot_service.dart';
import 'telemetry.dart' show BffTelemetry;
import 'vehicle_cache.dart';

/// HTTP-/WebSocket-API des BFF. Vertrag entspricht `BffRealtimeRepository`
/// in der Flutter-App:
///   GET /health              → Status
///   GET /api/departures      → {departures, …Telemetrie}
///   GET /api/vehicles        → {vehicles, …Telemetrie}
///   WS  /ws?broadcast=vehicles&bbox=… → {"type":"vehicles","items":[…]}
class BffApi {
  final BffConfig config;
  final BffTelemetry telemetry;
  final VehicleCache cache;
  final ResRobotService? resRobot;

  late final Router _router = _buildRouter();

  // Für Request-Collapsing bei Abfahrten
  final Map<String, _CachedDepartures> _departureCache = {};

  // Für Request-Collapsing bei Fahrzeugen (BBox)
  String _lastCollapseKey = '';
  DateTime _lastCollapseAt = DateTime.fromMillisecondsSinceEpoch(0);

  BffApi({
    required this.config,
    required this.telemetry,
    required this.cache,
    this.resRobot,
  });

  Handler get handler => _router.call;

  /// WebSocket-Handler, der vor dem Router geprüft wird.
  Handler get webSocketHandler => (Request request) {
        final bbox = _parseBbox(request.url.queryParameters);
        return _wsHandler(bbox).call(request);
      };

  Router _buildRouter() {
    return Router()
      ..get('/health', _health)
      ..get('/api/departures', _departures)
      ..get('/api/vehicles', _vehicles);
  }

  Handler _wsHandler(List<({double minLat, double minLng, double maxLat, double maxLng})>? bbox) {
    return ws.webSocketHandler((WebSocketChannel socket, String? subprotocol) {
      StreamSubscription<List<Map<String, dynamic>>>? sub;

      void send(List<Map<String, dynamic>> vehicles) {
        final payload = jsonEncode({'type': 'vehicles', 'items': vehicles});
        telemetry.onJsonBytes(utf8.encode(payload).length);
        socket.sink.add(payload);
      }

      final initial = _filter(cache.vehicles, bbox);
      telemetry.activeVehiclesInViewport = initial.length;
      send(initial);

      sub = cache.updates.listen((vehicles) {
        final filtered = _filter(vehicles, bbox);
        telemetry.activeVehiclesInViewport = filtered.length;
        if (filtered.isNotEmpty) {
          send(filtered);
        }
      });

      socket.stream.listen(
        (_) {},
        onError: (_) => sub?.cancel(),
        onDone: () => sub?.cancel(),
        cancelOnError: true,
      );
    });
  }

  Response _health(Request request) => Response.ok(
        jsonEncode({
          'status': 'ok',
          'service': 'swediscover_bff',
          'vehicles': cache.vehicles.length,
          'resrobot': resRobot != null,
          'gtfs_rt_poller': config.gtfsRtFeedUrls.isNotEmpty,
        }),
        headers: _jsonHeaders,
      );

  FutureOr<Response> _departures(Request request) {
    telemetry.onClientRequest();
    final stopId = request.url.queryParameters['stopId'] ?? 'unknown';

    // Request-Collapsing: Cache-Prüfung
    final now = DateTime.now();
    final cached = _departureCache[stopId];
    if (cached != null && now.difference(cached.timestamp) < config.collapseWindow) {
      telemetry.onCollapsedRequest();
      return _json({'departures': cached.departures});
    }

    // Echte ResRobot-Abfrage wenn Key vorhanden
    if (resRobot != null) {
      telemetry.onUpstreamCall();
      return resRobot!.departuresFor(stopId).then((departures) {
        // Cache aktualisieren
        _departureCache[stopId] = _CachedDepartures(departures, DateTime.now());
        // Cache aufräumen (einfaches LRU)
        if (_departureCache.length > 200) {
          final oldest = _departureCache.entries
              .reduce((a, b) => a.value.timestamp.isBefore(b.value.timestamp) ? a : b);
          _departureCache.remove(oldest.key);
        }
        return _json({'departures': departures});
      }).catchError((e) {
        // Fehler → leere Liste zurückgeben
        print('ResRobot Fehler für $stopId: $e');
        return _json({'departures': <Map<String, dynamic>>[]});
      });
    } else {
      // Kein ResRobot-Key → leere Liste
      _collapse('departures:$stopId');
      return _json({'departures': <Map<String, dynamic>>[]});
    }
  }

  Response _vehicles(Request request) {
    telemetry.onClientRequest();
    _collapse('vehicles');
    final bbox = _parseBbox(request.url.queryParameters);
    var items = cache.vehicles;
    if (bbox != null) items = _filter(items, bbox);
    telemetry.activeVehiclesInSweden = cache.vehicles.length;
    telemetry.activeVehiclesInViewport = items.length;
    return _json({'vehicles': items});
  }

  void _collapse(String key) {
    final now = DateTime.now();
    if (key == _lastCollapseKey &&
        now.difference(_lastCollapseAt) < config.collapseWindow) {
      telemetry.onCollapsedRequest();
    }
    _lastCollapseKey = key;
    _lastCollapseAt = now;
  }

  Response _json(Map<String, dynamic> body) {
    final full = {...body, ...telemetry.snapshot()};
    final encoded = jsonEncode(full);
    telemetry.onJsonBytes(utf8.encode(encoded).length);
    return Response.ok(encoded, headers: _jsonHeaders);
  }

  static const _jsonHeaders = {
    'content-type': 'application/json; charset=utf-8',
  };

  List<({double minLat, double minLng, double maxLat, double maxLng})>?
      _parseBbox(Map<String, String> query) {
    List<double>? numbers;
    final bboxParam = query['bbox'];
    if (bboxParam != null) {
      numbers = bboxParam
          .split(',')
          .map(double.tryParse)
          .whereType<double>()
          .toList();
    } else {
      final minLat = double.tryParse(query['minLat'] ?? '');
      final minLng = double.tryParse(query['minLng'] ?? '');
      final maxLat = double.tryParse(query['maxLat'] ?? '');
      final maxLng = double.tryParse(query['maxLng'] ?? '');
      if (minLat != null && minLng != null && maxLat != null && maxLng != null) {
        numbers = [minLat, minLng, maxLat, maxLng];
      }
    }
    if (numbers == null || numbers.length != 4) return null;
    return [
      (
        minLat: numbers[0],
        minLng: numbers[1],
        maxLat: numbers[2],
        maxLng: numbers[3],
      ),
    ];
  }

  List<Map<String, dynamic>> _filter(
    List<Map<String, dynamic>> vehicles,
    List<({double minLat, double minLng, double maxLat, double maxLng})>? bbox,
  ) {
    if (bbox == null || bbox.isEmpty) return vehicles;
    final box = bbox.first;
    return vehicles.where((v) {
      final lat = (v['lat'] as num).toDouble();
      final lng = (v['lng'] as num).toDouble();
      return lat >= box.minLat &&
          lat <= box.maxLat &&
          lng >= box.minLng &&
          lng <= box.maxLng;
    }).toList();
  }
}

class _CachedDepartures {
  final List<Map<String, dynamic>> departures;
  final DateTime timestamp;

  _CachedDepartures(this.departures, this.timestamp);
}
