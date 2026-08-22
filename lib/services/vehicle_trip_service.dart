import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/vehicle_trip_details.dart';
import 'api_exception.dart';
import 'app_settings_service.dart';

class VehicleTripService {
  final http.Client _client;

  VehicleTripService({http.Client? client}) : _client = client ?? http.Client();

  Future<VehicleTripDetails> fetchTripDetails(String vehicleId) async {
    final settings = await AppSettingsService.getInstance();
    final baseUrl = settings.bffServerUrl;
    if (baseUrl.isEmpty) {
      throw ApiException.bffOffline(baseUrl);
    }

    // Hybrid repo nutzt BFF für GTFS-RT; Direct-Mode hat keinen GTFS-Zugriff -> auch BFF nutzen.
    final url = Uri.parse('$baseUrl/api/trip-details/${Uri.encodeComponent(vehicleId)}');
    final res = await _client.get(url).timeout(const Duration(seconds: 12));
    if (res.statusCode == 404) {
      throw ApiException.http(404, 'trip-details/$vehicleId', bodySnippet: res.body);
    }
    if (res.statusCode != 200) {
      throw ApiException.http(res.statusCode, 'trip-details/$vehicleId', bodySnippet: res.body);
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return VehicleTripDetails.fromJson(json);
  }
}
