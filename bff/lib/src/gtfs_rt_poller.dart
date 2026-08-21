import 'dart:typed_data';
import 'dart:async';
import 'dart:io';

import 'gtfs_rt_reader.dart';
import 'telemetry.dart';
import 'vehicle_cache.dart';

/// Pollt periodisch die GTFS-RT-VehiclePositions-Feeds, dekodiert die
/// Protobufs und aktualisiert den Fahrzeug-Cache.
class GtfsRtPoller {
  final List<String> urls;
  final Duration interval;
  final VehicleCache cache;
  final BffTelemetry telemetry;

  Timer? _timer;
  HttpClient? _client;

  GtfsRtPoller({
    required this.urls,
    required this.interval,
    required this.cache,
    required this.telemetry,
  });

  void start() {
    stop();
    _client = HttpClient();
    _timer = Timer.periodic(interval, (_) => _pollAll());
    _pollAll();
  }

  Future<void> _pollAll() async {
    final results = await Future.wait(
      urls.map(_poll),
      eagerError: false,
    );
    final vehicles = [
      for (final batch in results) ...batch,
    ];
    if (vehicles.isNotEmpty) {
      telemetry.activeVehiclesInSweden = vehicles.length;
      cache.update(vehicles);
    }
  }

  Future<List<Map<String, dynamic>>> _poll(String url) async {
    telemetry.onUpstreamCall();
    final client = _client;
    if (client == null) return const [];
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      final builder = BytesBuilder();
      await for (final chunk in response) {
        builder.add(chunk);
      }
      final bytes = builder.toBytes();
      telemetry.onProtobufBytes(bytes.length);
      return GtfsRtReader.parseVehicles(bytes);
    } catch (_) {
      // Ein fehlgeschlagener Feed soll die übrigen nicht blockieren.
      return const [];
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _client?.close(force: true);
    _client = null;
  }
}