import 'dart:io';

/// Umgebungsbasierte Konfiguration des BFF. Alle Werte haben sinnvolle
/// Defaults, damit der Server sofort `dart run bin/server.dart` lauffähig ist.
/// 
/// WICHTIG: API-Keys müssen über Umgebungsvariablen bereitgestellt werden.
/// Keine Default-Keys im Code verwenden - diese würden sonst im Repo landen.
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
    
    // API-Keys MÜSSEN über Umgebungsvariablen gesetzt werden
    // Keine Fallback-Keys im Code - das wäre ein Sicherheitsrisiko
    final resrobotKey = env['RESROBOT_API_KEY'];
    final stopsKey = env['STOPS_API_KEY'];
    final gtfsStaticKey = env['GTFS_STATIC_API_KEY'];
    final gtfsRtKey = env['GTFS_RT_API_KEY'];
    
    if (resrobotKey == null || stopsKey == null || gtfsRtKey == null) {
      throw StateError(
        'API-Keys fehlen. Bitte setzen Sie folgende Umgebungsvariablen:\n'
        '  RESROBOT_API_KEY\n'
        '  STOPS_API_KEY\n'
        '  GTFS_RT_API_KEY\n'
        '  GTFS_STATIC_API_KEY (optional, für GTFS-Import)\n'
        '\n'
        'Erstellen Sie eine .env-Datei basierend auf .env.example',
      );
    }
    
    return BffConfig._(
      host: env['BFF_HOST'] ?? '0.0.0.0',
      port: int.tryParse(env['BFF_PORT'] ?? '') ?? 8080,
      resrobotApiKey: resrobotKey,
      stopsApiKey: stopsKey,
      gtfsStaticApiKey: gtfsStaticKey,
      gtfsRtOperators:
          operators.isNotEmpty ? operators : const ['sl', 'vasttrafik', 'skanetrafiken', 'xt'],
      gtfsRtApiKey: gtfsRtKey,
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