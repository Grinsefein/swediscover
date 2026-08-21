import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_exception.dart';
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

  /// ResRobot v2.1 Route planner (Trafiklab-Doku):
  /// GET https://api.resrobot.se/v2.1/trip?accessId=KEY&originId=…&destId=…&format=json
  /// Stop-IDs im 740xxxxx-Format (GTFS Sverige / Stop lookup).
  Future<List<JourneyTrip>> searchTrip({
    required String originId,
    required String destId,
    String? time,
    String? date,
  }) async {
    final settings = await AppSettingsService.getInstance();
    final apiKey = settings.getKey('RES_ROBOT_V2_1');

    if (apiKey.isEmpty) {
      throw ApiException.missingKey('RES_ROBOT_V2_1');
    }

    final uri = Uri.parse('https://api.resrobot.se/v2.1/trip').replace(
      queryParameters: {
        'accessId': apiKey,
        'originId': originId,
        'destId': destId,
        'format': 'json',
        'passlist': 'false',
        if (time != null && time.isNotEmpty) 'time': time,
        if (date != null && date.isNotEmpty) 'date': date,
      },
    );

    late final http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 15));
    } on TimeoutException catch (e) {
      throw ApiException.network('ResRobot /trip timeout: $e');
    } on SocketException catch (e) {
      throw ApiException.network('api.resrobot.se unreachable: $e');
    }

    // ResRobot meldet Fehler (z.B. unbekannte Haltestellen) als HTTP-Fehler.
    if (response.statusCode != 200) {
      throw ApiException.http(
        response.statusCode,
        'ResRobot /v2.1/trip',
        bodySnippet: response.body.isNotEmpty && response.body.length > 300
            ? '${response.body.substring(0, 300)}…'
            : response.body,
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException catch (e) {
      throw ApiException(
        kind: ApiExceptionKind.noData,
        userMessage: 'Ogiltigt svar från ResRobot.',
        technicalDetail: 'JSON parse failed: $e',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException(
        kind: ApiExceptionKind.noData,
        userMessage: 'Oväntat svar från ResRobot.',
      );
    }

    final json = decoded;
    final tripsRaw = json['Trip'] as List<dynamic>? ?? [];

    final results = <JourneyTrip>[];

    for (int i = 0; i < tripsRaw.length; i++) {
      final tripMap = tripsRaw[i] as Map<String, dynamic>;
      final legListRaw = tripMap['LegList']?['Leg'] as List<dynamic>? ?? [];

      final legs = <JourneyLeg>[];
      int transfers = 0;
      for (final legRaw in legListRaw) {
        if (legRaw is! Map<String, dynamic>) continue;
        final product = legMapProduct(legRaw);
        final legType = legRaw['type']?.toString() ?? '';

        // TRSF/WALK sind Umstiege bzw. Fußwege – keine Fahrzeug-Legs.
        if (legType == 'TRSF' || legType == 'WALK') {
          transfers++;
          continue;
        }

        legs.add(JourneyLeg(
          originName: legRaw['Origin']?['name']?.toString() ?? 'Start',
          destinationName: legRaw['Destination']?['name']?.toString() ?? 'Slut',
          departureTime: _shortTime(legRaw['Origin']?['time']?.toString()),
          arrivalTime: _shortTime(legRaw['Destination']?['time']?.toString()),
          line: product['num']?.toString().isNotEmpty == true
              ? product['num'].toString()
              : legRaw['name']?.toString() ?? '',
          transportType: product['catOutL']?.toString() ?? 'Tåg/Buss',
          operatorName: product['operator']?.toString() ?? '',
        ));
      }

      final depFirst = legs.isNotEmpty ? legs.first.departureTime : '--:--';
      final arrLast = legs.isNotEmpty ? legs.last.arrivalTime : '--:--';
      final duration = formatIsoDuration(tripMap['duration']?.toString()) ?? '';

      results.add(JourneyTrip(
        id: 'TRIP_$i',
        departureTime: depFirst,
        arrivalTime: arrLast,
        duration: duration,
        transfers: transfers > 0
            ? transfers
            : (legs.length > 1 ? legs.length - 1 : 0),
        legs: legs,
      ));
    }

    return results;
  }
}

Map<String, dynamic> legMapProduct(Map<String, dynamic> leg) {
  final p = leg['Product'];
  if (p is Map<String, dynamic>) return p;
  if (p is List<dynamic> && p.isNotEmpty && p.first is Map<String, dynamic>) {
    return p.first as Map<String, dynamic>;
  }
  return const {};
}

/// "11:41:00" → "11:41" (ResRobot liefert HH:MM[:SS]).
String _shortTime(String? t) {
  if (t == null || t.isEmpty) return '--:--';
  final parts = t.split(':');
  return parts.length >= 2 ? '${parts[0]}:${parts[1]}' : t;
}

/// ISO8601-Dauer ("PT9H32M") → "9h 32m".
String? formatIsoDuration(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  final m = RegExp(r'^P(?:(\d+)D)?T?(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?$').firstMatch(iso);
  if (m == null) return iso;
  final d = int.tryParse(m.group(1) ?? '') ?? 0;
  final h = int.tryParse(m.group(2) ?? '') ?? 0;
  final min = int.tryParse(m.group(3) ?? '') ?? 0;
  final totalHours = d * 24 + h;
  if (totalHours == 0 && min == 0) return iso;
  return totalHours > 0 ? '$totalHours h $min min' : '$min min';
}
