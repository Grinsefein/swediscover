import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:swediscover/repositories/server_realtime_repository.dart';
import 'package:swediscover/services/app_settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppSettingsService loads env keys from shipped assets', () async {
    final settings = await AppSettingsService.getInstance();

    expect(settings.getKey('TRAFIKLAB_API_KEY'), isNotEmpty);
    expect(settings.getKey('TRAFIKVERKET_API_KEY'), isNotEmpty);
    expect(settings.getKey('SERVER_PORT'), isNotEmpty);
  });

  test('ServerRealtimeRepository uses the configured proxy URL', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), 'http://10.0.2.2:8080/api/departures?stopId=123');
      return http.Response(
        '{"departures":[],"telemetry":{"totalClientRequests":1,"upstreamCallsMade":0,"collapsedRequests":0,"networkSavingsPercent":0,"protobufBytesProcessed":0,"jsonStreamBytesEmitted":0,"activeVehiclesInSweden":0,"activeVehiclesInViewport":0}}',
        200,
      );
    });

    final repo = ServerRealtimeRepository(
      baseUrl: 'http://10.0.2.2:8080',
      client: client,
    );

    final departures = await repo.fetchDepartures('123');
    expect(departures, isEmpty);
  });
}
