import 'dart:io';

import 'package:swediscover_bff/swediscover_bff.dart';

/// Startet den SweDiscover BFF.
Future<void> main() async {
  final config = BffConfig.fromEnvironment();
  final server = BffServer(config: config);
  
  try {
    await server.start();
    stdout.writeln('SweDiscover BFF läuft auf http://${config.host}:${config.port}');
    stdout.writeln(
      'Mock-Feed aktiv${config.gtfsRtUrl != null ? ' · GTFS-RT-Polling auf ${config.gtfsRtUrl}' : ''}',
    );
    
    // Keep the isolate alive - HttpServer keeps it alive
    // Just wait forever
    await Future<void>.delayed(const Duration(days: 365));
  } catch (e, st) {
    stderr.writeln('FATAL ERROR: $e');
    stderr.writeln(st);
    exit(1);
  }
}
