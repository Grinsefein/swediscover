import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/departure_model.dart';
import '../models/vehicle_position_model.dart';
import '../services/api_exception.dart';
import '../services/app_settings_service.dart';
import '../services/gtfs_rt_decoder.dart';
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

    // Trafiklab realtime APIs - Timetables Endpoint:
    // GET https://realtime-api.trafiklab.se/v1/departures/{stopId}?key=...
    final url = Uri.parse(
      'https://realtime-api.trafiklab.se/v1/departures/$stopId?key=$apiKey',
    );

    try {
      final response = await _client.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        // Fallback or error format
        return _fetchDeparturesFallback(stopId, apiKey);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final rawList = (json['departures'] as List<dynamic>?) ?? [];

      final departures = <TransitDeparture>[];
      for (int i = 0; i < rawList.length; i++) {
        final item = rawList[i];
        if (item is Map<String, dynamic>) {
          departures.add(_departureFromTimetableApi(item, stopId, i));
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

  /// Mappt ein Departure-Item des Trafiklab Timetables Endpoints auf das
  /// App-Contract (Spiegelstück zu backend/api_transformers.go).
  TransitDeparture _departureFromTimetableApi(
    Map<String, dynamic> item,
    String stopId,
    int index,
  ) {
    final route = item['route'] as Map<String, dynamic>? ?? const {};
    final trip = item['trip'] as Map<String, dynamic>? ?? const {};
    final agency = item['agency'] as Map<String, dynamic>? ?? const {};

    final scheduled = (item['scheduled'] as String?) ?? '';
    final realtime = (item['realtime'] as String?) ?? scheduled;
    final delaySeconds = (item['delay'] as num?)?.toInt() ?? 0;
    final canceled = item['canceled'] == true;

    final status = canceled
        ? DepartureStatus.cancelled
        : delaySeconds > 60
            ? DepartureStatus.delayed
            : DepartureStatus.onTime;

    String platform(Map<String, dynamic> source, String key) {
      final p = source[key] as Map<String, dynamic>?;
      return p?['designation']?.toString() ?? '';
    }

    return TransitDeparture(
      id: '${trip['trip_id'] ?? 'dep'}-$index',
      stopId: stopId,
      line: (route['designation'] ?? route['name'])?.toString() ?? '',
      destination: route['direction']?.toString() ?? 'Okänd',
      mode: _mapTransportMode(route['transport_mode']?.toString()),
      scheduledTime: DateTime.tryParse(scheduled) ?? DateTime.now(),
      realtimeTime: DateTime.tryParse(realtime) ?? DateTime.now(),
      delaySeconds: delaySeconds,
      status: status,
      track: platform(item, 'realtime_platform').isNotEmpty
          ? platform(item, 'realtime_platform')
          : platform(item, 'scheduled_platform'),
      originalTrack: platform(item, 'scheduled_platform'),
      operatorName:
          (agency['operator'] ?? agency['name'])?.toString() ?? '',
    );
  }

  static TransitMode _mapTransportMode(String? mode) {
    switch ((mode ?? '').trim().toUpperCase()) {
      case 'METRO':
        return TransitMode.tunnelbana;
      case 'TRAM':
        return TransitMode.tram;
      case 'FERRY':
      case 'BOAT':
        return TransitMode.ferry;
      case 'TRAIN':
      case 'RAIL':
        return TransitMode.fjarrtag;
      default:
        return TransitMode.bus;
    }
  }

  Future<List<TransitDeparture>> _fetchDeparturesFallback(String stopId, String apiKey) async {
    // ResRobot v2.1 Timetables DepartureBoard (Trafiklab-Doku):
    // https://api.resrobot.se/v2.1/departureBoard?id=<stopId>&accessId=<KEY>&format=json
    final settings = await AppSettingsService.getInstance();
    final resRobotKey = settings.getKey('RES_ROBOT_V2_1');
    if (resRobotKey.isEmpty) {
      throw ApiException.missingKey('RES_ROBOT_V2_1');
    }
    final url = Uri.parse('https://api.resrobot.se/v2.1/departureBoard').replace(
      queryParameters: {
        'accessId': resRobotKey,
        'id': stopId,
        'format': 'json',
      },
    );
    final response = await _client.get(url).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      return [];
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final departures = <TransitDeparture>[];
    final list = (json['DepartureBoard']?['Departure'] ?? json['Departure']) as List<dynamic>? ?? [];

    for (int i = 0; i < list.length; i++) {
      final dep = list[i] as Map<String, dynamic>;
      final name = dep['name']?.toString() ?? 'Tåg/Buss';
      final product = dep['Product'] is Map<String, dynamic>
          ? dep['Product'] as Map<String, dynamic>
          : const {};
      final line = product['num']?.toString() ??
          dep['transportNumber']?.toString() ??
          '$i';
      final dest = dep['direction']?.toString() ?? 'Okänd';
      final timeStr = dep['rtTime']?.toString() ?? dep['time']?.toString();
      final dateStr = dep['rtDate']?.toString() ?? dep['date']?.toString();
      final time = DateTime.tryParse('${dateStr ?? ''} ${timeStr ?? ''}'.trim()) ?? DateTime.now();

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
        operatorName: product['operator']?.toString() ?? 'ResRobot',
      ));
    }

    return departures;
  }

  /// Lokaler 15s-Cache für den TripUpdates-Delay-Join (optional, Fehler toleriert).
  Map<String, int> _tripDelays = const {};
  DateTime? _tripDelaysFetchedAt;

  @override
  Future<List<RealtimeVehiclePosition>> fetchVehicles() async {
    final settings = await AppSettingsService.getInstance();
    final gtfsRtKey = settings.getKey('GTFS_SWEDEN_3_REALTIME');

    if (gtfsRtKey.isEmpty) {
      throw ApiException.missingKey('GTFS_SWEDEN_3_REALTIME');
    }

    // GTFS-RT ist immer Protobuf (Trafiklab), kein JSON.
    final url = Uri.parse(
      'https://realtime-api.trafiklab.se/v1/gtfs-rt/vehicle-positions?apikey=$gtfsRtKey',
    );

    try {
      final response = await _client.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw ApiException.http(response.statusCode, 'gtfs-rt/vehicle-positions');
      }

      final delays = await _fetchTripDelays(gtfsRtKey);
      final vehicles = GtfsRtDecoder.decodeVehicles(response.bodyBytes, delays: delays);

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
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.network(e);
    }
  }

  /// Verspätungen aus dem TripUpdates-Feed (tripId -> delaySeconds) für den
  /// Vehicle-Delay-Join. Optional: Bei Fehlern wird der letzte Stand wiederverwendet.
  Future<Map<String, int>> _fetchTripDelays(String apiKey) async {
    final now = DateTime.now();
    final fetchedAt = _tripDelaysFetchedAt;
    if (fetchedAt != null && now.difference(fetchedAt) < const Duration(seconds: 15)) {
      return _tripDelays;
    }

    try {
      final url = Uri.parse(
        'https://realtime-api.trafiklab.se/v1/gtfs-rt/trip-updates?apikey=$apiKey',
      );
      final response = await _client.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        _tripDelays = GtfsRtDecoder.decodeTripDelays(response.bodyBytes);
        _tripDelaysFetchedAt = now;
      }
    } catch (_) {
      // Delay-Anreicherung ist optional – alte Werte behalten.
    }
    return _tripDelays;
  }
}
