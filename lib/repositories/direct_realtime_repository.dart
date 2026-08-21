import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/departure_model.dart';
import '../models/vehicle_position_model.dart';
import '../services/app_settings_service.dart';
import 'realtime_repository.dart';

/// Direct API Repository for client-side fetching straight from Trafiklab
/// without going through the Go BFF Server.
class DirectRealtimeRepository extends RealtimeRepository {
  final http.Client _client;
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

  DirectRealtimeRepository({http.Client? client}) : _client = client ?? http.Client();

  @override
  RealtimeTelemetry get telemetry => _telemetry;

  @override
  bool get isBoundingBoxFilterActive => _isBoundingBoxFilterActive;

  @override
  void toggleBoundingBoxFilter() {
    _isBoundingBoxFilterActive = !_isBoundingBoxFilterActive;
    notifyListeners();
  }

  @override
  Future<List<TransitDeparture>> fetchDepartures(String stopId) async {
    final settings = await AppSettingsService.getInstance();
    final apiKey = settings.getKey('TRAFIKLAB_API_KEY');

    if (apiKey.isEmpty) {
      throw Exception('TRAFIKLAB_API_KEY nicht in Settings / .env gesetzt');
    }

    // Trafiklab Realtime v2 DepartureBoard Endpoint
    final url = Uri.parse(
      'https://realtime-api.trafiklab.se/v2/StopPoints/$stopId/DepartureBoard?apikey=$apiKey',
    );

    try {
      final response = await _client.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        // Fallback or error format
        return _fetchDeparturesFallback(stopId, apiKey);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final departureBoard = json['DepartureBoard'] as Map<String, dynamic>? ?? json;
      final rawList = (departureBoard['timetabledDepartureWithCalls'] as List<dynamic>?) ??
          (departureBoard['departures'] as List<dynamic>?) ??
          [];

      final departures = <TransitDeparture>[];
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          departures.add(TransitDeparture.fromJson(item));
        }
      }

      _telemetry = RealtimeTelemetry(
        totalClientRequests: _telemetry.totalClientRequests + 1,
        upstreamCallsMade: _telemetry.upstreamCallsMade + 1,
        collapsedRequests: _telemetry.collapsedRequests,
        networkSavingsPercent: 0,
        protobufBytesProcessed: _telemetry.protobufBytesProcessed,
        jsonStreamBytesEmitted: _telemetry.jsonStreamBytesEmitted + response.bodyBytes.length,
        activeVehiclesInSweden: _telemetry.activeVehiclesInSweden,
        activeVehiclesInViewport: _telemetry.activeVehiclesInViewport,
      );
      notifyListeners();

      return departures;
    } catch (_) {
      return _fetchDeparturesFallback(stopId, apiKey);
    }
  }

  Future<List<TransitDeparture>> _fetchDeparturesFallback(String stopId, String apiKey) async {
    // Alternative ResRobot / Trafiklab Departureboard endpoint
    final url = Uri.parse(
      'https://api.trafiklab.se/v2/departureBoard?key=$apiKey&stopId=$stopId&time=${DateTime.now().toIso8601String()}',
    );
    final response = await _client.get(url).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      return [];
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final departures = <TransitDeparture>[];
    final list = json['Departure'] as List<dynamic>? ?? [];

    for (int i = 0; i < list.length; i++) {
      final dep = list[i] as Map<String, dynamic>;
      final name = dep['name']?.toString() ?? 'Tåg/Buss';
      final line = dep['Product']?['displayNumber']?.toString() ?? dep['line']?.toString() ?? '$i';
      final dest = dep['direction']?.toString() ?? dep['destination']?.toString() ?? 'Okänd';
      final timeStr = dep['time']?.toString() ?? dep['date']?.toString();
      final time = timeStr != null ? DateTime.tryParse(timeStr) ?? DateTime.now() : DateTime.now();

      departures.add(TransitDeparture(
        id: 'DIR_$i',
        stopId: stopId,
        line: line,
        destination: dest,
        mode: name.toLowerCase().contains('buss') ? TransitMode.bus : TransitMode.fjarrtag,
        scheduledTime: time,
        realtimeTime: time,
        delaySeconds: 0,
        status: DepartureStatus.onTime,
        track: dep['rtTrack']?.toString() ?? dep['track']?.toString() ?? '1',
        operatorName: dep['Product']?['operator']?.toString() ?? 'Trafiklab',
      ));
    }

    return departures;
  }

  @override
  Future<List<RealtimeVehiclePosition>> fetchVehicles() async {
    final settings = await AppSettingsService.getInstance();
    final gtfsRtKey = settings.getKey('GTFS_SWEDEN_3_REALTIME');

    if (gtfsRtKey.isEmpty) {
      return [];
    }

    final url = Uri.parse(
      'https://realtime-api.trafiklab.se/v1/gtfs-rt/vehicle-positions?apikey=$gtfsRtKey',
    );

    try {
      final response = await _client.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final bodyText = response.body;
        final vehicles = <RealtimeVehiclePosition>[];

        if (bodyText.trim().startsWith('{') || bodyText.trim().startsWith('[')) {
          final decoded = jsonDecode(bodyText);
          final list = decoded is List ? decoded : ((decoded as Map<String, dynamic>)['vehicles'] as List<dynamic>? ?? []);
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              vehicles.add(RealtimeVehiclePosition.fromJson(item));
            }
          }
        }

        _telemetry = RealtimeTelemetry(
          totalClientRequests: _telemetry.totalClientRequests + 1,
          upstreamCallsMade: _telemetry.upstreamCallsMade + 1,
          collapsedRequests: _telemetry.collapsedRequests,
          networkSavingsPercent: 0,
          protobufBytesProcessed: _telemetry.protobufBytesProcessed + response.bodyBytes.length,
          jsonStreamBytesEmitted: _telemetry.jsonStreamBytesEmitted,
          activeVehiclesInSweden: vehicles.length,
          activeVehiclesInViewport: vehicles.length,
        );
        notifyListeners();

        return vehicles;
      }
    } catch (_) {}

    return [];
  }
}
