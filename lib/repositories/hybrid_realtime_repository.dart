import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/departure_model.dart';
import '../models/vehicle_position_model.dart';
import '../services/app_settings_service.dart';
import '../services/api_exception.dart';
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
      try {
        return await directRepo.fetchDepartures(stopId);
      } catch (e) {
        return _fallbackToServer(
          () => serverRepo.fetchDepartures(stopId),
          'fetchDepartures($stopId)',
          e,
        );
      }
    } else {
      return serverRepo.fetchDepartures(stopId);
    }
  }

  @override
  Future<List<RealtimeVehiclePosition>> fetchVehicles() async {
    if (settings.useDirectApi) {
      try {
        final result = await directRepo.fetchVehicles();
        if (result.isEmpty) {
          // Direct mode verschluckt Netzwerk-/TLS-Fehler und liefert dann [] –
          // einmal den BFF probieren, bevor eine leere Karte angezeigt wird.
          return _fallbackToServer(serverRepo.fetchVehicles, 'fetchVehicles', 'empty result');
        }
        return result;
      } catch (e) {
        return _fallbackToServer(serverRepo.fetchVehicles, 'fetchVehicles', e);
      }
    } else {
      return serverRepo.fetchVehicles();
    }
  }

  /// Direkt-Modus fehlgeschlagen (z.B. TLS-/Netzwerkfehler): ein Retry über
  /// den BFF, bevor dem Nutzer ein Fehler angezeigt wird. Ist der BFF selbst
  /// nicht erreichbar, gibt es eine klare Offline-Meldung mit der URL.
  Future<T> _fallbackToServer<T>(Future<T> Function() call, String op, Object? cause) async {
    debugPrint('HybridRepository: direct mode failed for $op ($cause) – retrying via BFF …');

    if (!await _isBffReachable()) {
      throw ApiException.bffOffline(settings.bffServerUrl, cause: cause);
    }

    try {
      return await call();
    } catch (bffError) {
      throw ApiException(
        kind: ApiExceptionKind.network,
        userMessage: 'Kunde inte hämta trafikdata.',
        technicalDetail: 'direct: $cause | bff(${settings.bffServerUrl}): $bffError',
      );
    }
  }

  /// Kurzer Reachability-Probe gegen den BFF (2s Timeout).
  Future<bool> _isBffReachable() async {
    final url = settings.bffServerUrl;
    if (url.isEmpty) return false;
    try {
      final res = await http.get(Uri.parse('$url/api/vehicles')).timeout(const Duration(seconds: 2));
      return res.statusCode < 500;
    } catch (_) {
      return false;
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
