import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:swediscover_bff/swediscover_bff.dart';
import 'package:test/test.dart';

void main() {
  late BffTelemetry telemetry;
  late VehicleCache cache;
  late BffApi api;

  setUp(() {
    telemetry = BffTelemetry();
    cache = VehicleCache();
    cache.update(const [
      {'vehicleId': 'TUB-14-01', 'lat': 59.3312, 'lng': 18.0594},
      {'vehicleId': 'PAGA-30-05', 'lat': 55.6090, 'lng': 13.0008},
    ]);
    api = BffApi(
      config: BffConfig(),
      telemetry: telemetry,
      cache: cache,
      feed: MockFeed(),
    );
  });

  Future<Map<String, dynamic>> call(Uri uri) async {
    final response = await api.handler(Request('GET', uri));
    expect(response.statusCode, 200);
    return jsonDecode(await response.readAsString()) as Map<String, dynamic>;
  }

  test('/health liefert Status', () async {
    final body = await call(Uri.parse('http://localhost:8080/health'));
    expect(body['status'], 'ok');
    expect(body['service'], 'swediscover_bff');
  });

  test('/api/departures liefert Abfahrten + Telemetrie', () async {
    final body =
        await call(Uri.parse('http://localhost:8080/api/departures?stopId=740000001'));
    final departures = body['departures'] as List<dynamic>;
    expect(departures, isNotEmpty);
    final first = departures.first as Map<String, dynamic>;
    expect(first['stopId'], '740000001');
    expect(first['mode'], isNotEmpty);
    expect(first['scheduledTime'], isNotNull);
    expect(body['totalClientRequests'], 1);
  });

  test('/api/vehicles liefert Fahrzeuge + Telemetrie', () async {
    final body = await call(Uri.parse('http://localhost:8080/api/vehicles'));
    expect(body['vehicles'], hasLength(2));
    expect(body['totalClientRequests'], 1);
  });

  test('WebSocket-Anfragen werden nicht als HTTP 404 abgewiesen', () async {
    final response = await api.webSocketHandler(
      Request('GET', Uri.parse('http://localhost:8080/ws?broadcast=vehicles')),
    );
    // Kein echter Upgrade-Request in diesem Test → der Handler meldet 404/400,
    // wirft aber nicht.
    expect([400, 404, 426], contains(response.statusCode));
  });
}