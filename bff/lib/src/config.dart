import 'dart:io';

// Trafiklab-API-Keys (lokal entwickelte Defaults; in Produktion per
// Umgebungsvariablen überschreiben, damit die Keys nicht im Repo landen).
const _defaultResrobotKey = '782db852-05b4-43d0-b79d-a10518de9caa';
const _defaultStopsKey = '0fa5304a78e54f53b9b95b2bbd3d9572';
const _defaultGtfsRtKey = '5b4203043a8547c5a95259d0a0687914';
const _defaultGtfsStaticKey = '223e1d41da1d431d91ad28efba929ac5';

/// Umgebungsbasierte Konfiguration des BFF. Alle Werte haben sinnvolle
/// Defaults, damit der Server sofort `dart run bin/server.dart` lauffähig ist.
class BffConfig {
  final String host;
  final int port;

  /// ResRobot-v2.1-Key (Abfahrten).
  final String? resrobotApiKey;

  /// ResRobot-StopLookup-Key (Stops).
  final String? stopsApiKey;

  /// GTFS-Sweden-3-Key (statische Daten, für den App-Importer).
  final String? gtfsStaticApiKey;

  /// Operatoren, deren GTFS-RT-VehiclePositions-Feeds gepollt werden.
  final List<String> gtfsRtOperators;

  /// GTFS-RT-Key (GTFS Sweden 3 Realtime).
  final String? gtfsRtApiKey;

  /// Optional: explizite GTFS-RT-URL (überschreibt die Operator-Feeds).
  final String? gtfsRtUrl;

  /// Intervall der GTFS-RT-Polling-Schleife.
  final Duration gtfsRtPollInterval;

  /// Intervall der WebSocket-Broadcasts.
  final Duration broadcastInterval;

  /// Zeitfenster, in dem identische Client-Requests zusammengefasst werden.
  final Duration collapseWindow;

  BffConfig._({
    required this.host,
    required this.port,
    this.resrobotApiKey,
    this.stopsApiKey,
    this.gtfsStaticApiKey,
    this.gtfsRtOperators = const [],
    this.gtfsRtApiKey,
    this.gtfsRtUrl,
    required this.gtfsRtPollInterval,
    required this.broadcastInterval,
    required this.collapseWindow,
  });

  /// Konfiguration für Tests bzw. programmatischen Einsatz.
  BffConfig({
    this.host = '0.0.0.0',
    this.port = 8080,
    this.resrobotApiKey,
    this.stopsApiKey,
    this.gtfsStaticApiKey,
    this.gtfsRtOperators = const [],
    this.gtfsRtApiKey,
    this.gtfsRtUrl,
    this.gtfsRtPollInterval = const Duration(seconds: 30),
    this.broadcastInterval = const Duration(milliseconds: 500),
    this.collapseWindow = const Duration(milliseconds: 1500),
  });

  factory BffConfig.fromEnvironment() {
    final env = Platform.environment;
    final operators = (env['GTFS_RT_OPERATORS'] ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return BffConfig._(
      host: env['BFF_HOST'] ?? '0.0.0.0',
      port: int.tryParse(env['BFF_PORT'] ?? '') ?? 8080,
      resrobotApiKey: env['RESROBOT_API_KEY'] ?? _defaultResrobotKey,
      stopsApiKey: env['STOPS_API_KEY'] ?? _defaultStopsKey,
      gtfsStaticApiKey: env['GTFS_STATIC_API_KEY'] ?? _defaultGtfsStaticKey,
      gtfsRtOperators:
          operators.isNotEmpty ? operators : const ['sl', 'vasttrafik', 'skanetrafiken', 'xt'],
      gtfsRtApiKey: env['GTFS_RT_API_KEY'] ?? _defaultGtfsRtKey,
      gtfsRtUrl: env['GTFS_RT_URL'],
      gtfsRtPollInterval: Duration(
        seconds: int.tryParse(env['GTFS_RT_POLL_SECONDS'] ?? '') ?? 30,
      ),
      broadcastInterval: Duration(
        milliseconds: int.tryParse(env['BROADCAST_MS'] ?? '') ?? 500,
      ),
      collapseWindow: Duration(
        milliseconds: int.tryParse(env['COLLAPSE_WINDOW_MS'] ?? '') ?? 1500,
      ),
    );
  }

  /// GTFS-RT-Feed-URLs aus den Operatoren.
  List<String> get gtfsRtFeedUrls {
    if (gtfsRtUrl != null) return [gtfsRtUrl!];
    final key = gtfsRtApiKey ?? '';
    return [
      for (final operator in gtfsRtOperators)
        'https://opendata.samtrafiken.se/gtfs-rt-sweden/$operator/VehiclePositionsSweden.pb?key=$key',
    ];
  }
}