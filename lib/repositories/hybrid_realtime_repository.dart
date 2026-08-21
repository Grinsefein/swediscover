import 'dart:async';

import '../models/departure_model.dart';
import '../models/vehicle_position_model.dart';
import '../services/app_settings_service.dart';
import 'direct_realtime_repository.dart';
import 'realtime_repository.dart';
import 'server_realtime_repository.dart';

/// Dynamic Hybrid Repository that automatically switches between Direct API calls
/// and Go BFF Server Mode based on the user's settings.
class HybridRealtimeRepository extends RealtimeRepository {
  final AppSettingsService settings;
  final DirectRealtimeRepository directRepo;
  ServerRealtimeRepository serverRepo;

  HybridRealtimeRepository({
    required this.settings,
    DirectRealtimeRepository? directRepo,
    ServerRealtimeRepository? serverRepo,
  })  : directRepo = directRepo ?? DirectRealtimeRepository(),
        serverRepo = serverRepo ?? ServerRealtimeRepository(baseUrl: settings.bffServerUrl) {
    settings.addListener(_onSettingsChanged);
    directRepo?.addListener(notifyListeners);
    serverRepo?.addListener(notifyListeners);
  }

  void _onSettingsChanged() {
    if (!settings.useDirectApi) {
      serverRepo = ServerRealtimeRepository(baseUrl: settings.bffServerUrl);
      serverRepo.addListener(notifyListeners);
    }
    notifyListeners();
  }

  @override
  RealtimeTelemetry get telemetry =>
      settings.useDirectApi ? directRepo.telemetry : serverRepo.telemetry;

  @override
  bool get isBoundingBoxFilterActive =>
      settings.useDirectApi
          ? directRepo.isBoundingBoxFilterActive
          : serverRepo.isBoundingBoxFilterActive;

  @override
  void toggleBoundingBoxFilter() {
    if (settings.useDirectApi) {
      directRepo.toggleBoundingBoxFilter();
    } else {
      serverRepo.toggleBoundingBoxFilter();
    }
  }

  @override
  Future<List<TransitDeparture>> fetchDepartures(String stopId) async {
    if (settings.useDirectApi) {
      return directRepo.fetchDepartures(stopId);
    } else {
      return serverRepo.fetchDepartures(stopId);
    }
  }

  @override
  Future<List<RealtimeVehiclePosition>> fetchVehicles() async {
    if (settings.useDirectApi) {
      return directRepo.fetchVehicles();
    } else {
      return serverRepo.fetchVehicles();
    }
  }

  @override
  void dispose() {
    settings.removeListener(_onSettingsChanged);
    directRepo.dispose();
    serverRepo.dispose();
    super.dispose();
  }
}
