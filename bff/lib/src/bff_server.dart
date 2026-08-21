import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

import 'api.dart';
import 'config.dart';
import 'gtfs_rt_poller.dart';
import 'resrobot_service.dart' show ResRobotService;
import 'telemetry.dart' show BffTelemetry;
import 'vehicle_cache.dart' show VehicleCache;

/// Assembliert Konfiguration, Telemetrie, ResRobot, GTFS-RT-Poller,
/// Cache und API zu einem lauffähigen Server.
class BffServer {
  final BffConfig config;
  final BffTelemetry telemetry = BffTelemetry();
  final VehicleCache cache = VehicleCache();

  ResRobotService? _resRobot;
  GtfsRtPoller? _gtfsRtPoller;
  HttpServer? _server;

  BffServer({BffConfig? config}) : config = config ?? BffConfig.fromEnvironment() {
    final cfg = config!; // lokale Variable für Null-Sicherheit im Konstruktor
    // ResRobot (echte Abfahrten)
    if (cfg.resrobotApiKey != null && cfg.resrobotApiKey!.isNotEmpty) {
      _resRobot = ResRobotService(apiKey: cfg.resrobotApiKey!);
    }

    // GTFS-RT-Poller (echte Fahrzeugpositionen)
    if (cfg.gtfsRtFeedUrls.isNotEmpty) {
      _gtfsRtPoller = GtfsRtPoller(
        urls: cfg.gtfsRtFeedUrls,
        interval: cfg.gtfsRtPollInterval,
        cache: cache,
        telemetry: telemetry,
      );
    }
  }

  Future<void> start() async {
    _gtfsRtPoller?.start();

    final api = BffApi(
      config: config,
      telemetry: telemetry,
      cache: cache,
      resRobot: _resRobot,
    );

    final pipeline = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(Cascade().add(api.webSocketHandler).add(api.handler).handler);

    _server = await serve(pipeline, config.host, config.port);
  }

  Future<void> stop() async {
    _gtfsRtPoller?.stop();
    cache.dispose();
    await _server?.close(force: true);
    _server = null;
  }
}
