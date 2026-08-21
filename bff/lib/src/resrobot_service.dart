import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'departure_mapper.dart';

/// ResRobot-v2.1-Client für echte Abfahrten (Trafiklab).
class ResRobotService {
  static const _baseUrl = 'https://api.resrobot.se/v2.1';

  final String apiKey;
  final http.Client _client;
  final Duration timeout;

  ResRobotService({
    required this.apiKey,
    http.Client? client,
    this.timeout = const Duration(seconds: 8),
  }) : _client = client ?? http.Client();

  Future<List<Map<String, dynamic>>> departuresFor(String stopId) async {
    final uri = Uri.parse('$_baseUrl/departureBoard').replace(
      queryParameters: {
        'id': stopId,
        'format': 'json',
        'accessId': apiKey,
        'maxJourneys': '20',
        'duration': '60',
      },
    );

    final response = await _client.get(uri).timeout(timeout);
    if (response.statusCode != 200) {
      throw ResRobotException(
        'ResRobot departureBoard → HTTP ${response.statusCode}: ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final departures = body['Departure'] as List<dynamic>? ?? const [];
    return departures
        .map((d) => DepartureMapper.fromResRobot(d as Map<String, dynamic>))
        .whereType<Map<String, dynamic>>()
        .toList();
  }
}

class ResRobotException implements Exception {
  final String message;
  ResRobotException(this.message);

  @override
  String toString() => message;
}