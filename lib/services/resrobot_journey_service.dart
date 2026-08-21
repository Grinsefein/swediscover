import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_settings_service.dart';

class JourneyLeg {
  final String originName;
  final String destinationName;
  final String departureTime;
  final String arrivalTime;
  final String line;
  final String transportType;
  final String operatorName;

  const JourneyLeg({
    required this.originName,
    required this.destinationName,
    required this.departureTime,
    required this.arrivalTime,
    required this.line,
    required this.transportType,
    required this.operatorName,
  });
}

class JourneyTrip {
  final String id;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final int transfers;
  final List<JourneyLeg> legs;

  const JourneyTrip({
    required this.id,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.transfers,
    required this.legs,
  });
}

class ResRobotJourneyService {
  final http.Client _client;

  ResRobotJourneyService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<JourneyTrip>> searchTrip({
    required String originId,
    required String destId,
    String? time,
    String? date,
  }) async {
    final settings = await AppSettingsService.getInstance();
    final apiKey = settings.getKey('RES_ROBOT_V2_1');

    if (apiKey.isEmpty) {
      throw Exception('RES_ROBOT_V2_1 Key nicht in Settings / .env gesetzt');
    }

    final uri = Uri.parse('https://api.trafiklab.se/v2.1/TravelPlanner/SearchTrip').replace(
      queryParameters: {
        'key': apiKey,
        'originId': originId,
        'destId': destId,
        'format': 'json',
        if (time != null && time.isNotEmpty) 'time': time,
        if (date != null && date.isNotEmpty) 'date': date,
      },
    );

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception('ResRobot API HTTP ${response.statusCode}: ${response.body}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final tripsRaw = json['Trip'] as List<dynamic>? ?? [];

      final results = <JourneyTrip>[];

      for (int i = 0; i < tripsRaw.length; i++) {
        final tripMap = tripsRaw[i] as Map<String, dynamic>;
        final legListRaw = tripMap['LegList']?['Leg'] as List<dynamic>? ?? [];

        final legs = <JourneyLeg>[];
        for (final legRaw in legListRaw) {
          final legMap = legRaw as Map<String, dynamic>;
          final origin = legMap['Origin']?['name']?.toString() ?? 'Start';
          final dest = legMap['Destination']?['name']?.toString() ?? 'Ziel';
          final depTime = legMap['Origin']?['time']?.toString() ?? '--:--';
          final arrTime = legMap['Destination']?['time']?.toString() ?? '--:--';
          final line = legMap['Product']?['displayNumber']?.toString() ?? legMap['name']?.toString() ?? '';
          final type = legMap['category']?.toString() ?? legMap['type']?.toString() ?? 'Tåg/Buss';
          final op = legMap['Product']?['operator']?.toString() ?? '';

          legs.add(JourneyLeg(
            originName: origin,
            destinationName: dest,
            departureTime: depTime,
            arrivalTime: arrTime,
            line: line,
            transportType: type,
            operatorName: op,
          ));
        }

        final depFirst = legs.isNotEmpty ? legs.first.departureTime : '--:--';
        final arrLast = legs.isNotEmpty ? legs.last.arrivalTime : '--:--';
        final duration = tripMap['duration']?.toString() ?? '30m';
        final transfers = legs.length > 1 ? legs.length - 1 : 0;

        results.add(JourneyTrip(
          id: 'TRIP_$i',
          departureTime: depFirst,
          arrivalTime: arrLast,
          duration: duration,
          transfers: transfers,
          legs: legs,
        ));
      }

      return results;
    } catch (e) {
      throw Exception('ResRobot Fehler: $e');
    }
  }
}
