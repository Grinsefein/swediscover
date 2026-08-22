import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/app_database.dart';
import '../data/gtfs_importer.dart';
import '../data/stop_repository.dart';
import '../repositories/hybrid_realtime_repository.dart';
import '../repositories/realtime_repository.dart';
import 'app_settings_service.dart';

/// Composition Root für alle App-Services.
/// Wird beim App-Start erstellt und via Provider bereitgestellt.
class AppServices {
  final AppDatabase database;
  final StopRepository stopRepository;
  final RealtimeRepository realtimeRepository;

  AppServices._({
    required this.database,
    required this.stopRepository,
    required this.realtimeRepository,
  });

  /// Erstellt alle Services in der richtigen Reihenfolge.
  static Future<AppServices> create() async {
    final database = AppDatabase();
    
    // Prüfen ob DB leer ist -> GTFS-Import anstoßen
    final stopCount = await database.countStops();
    if (stopCount == 0) {
      debugPrint('GTFS-DB ist leer, starte Import...');
      // Hinweis: Der eigentliche Import läuft asynchron im Hintergrund
      // um den App-Start nicht zu blockieren
      unawaited(_triggerGtfsImport(database));    }

    final settings = await AppSettingsService.getInstance();
    final stopRepository = DriftStopRepository(database);
    final realtimeRepository = HybridRealtimeRepository(settings: settings);

    return AppServices._(
      database: database,
      stopRepository: stopRepository,
      realtimeRepository: realtimeRepository,
    );
  }

  /// Trigger für den GTFS-Import bei leerer DB.
  /// Läuft im Hintergrund, um den App-Start nicht zu verzögern.
  static Future<void> _triggerGtfsImport(AppDatabase database) async {
    try {
      final settings = await AppSettingsService.getInstance();
      final importer = GtfsImporter(database);
      final gtfsStaticKey = settings.getKey('GTFS_SWEDEN_3_STATIC');
      
      if (gtfsStaticKey.isEmpty) {
        debugPrint('⚠️ GTFS_SWEDEN_3_STATIC nicht gesetzt. GTFS-Import übersprungen.');
        return;
      }

      await importer.importFromTrafiklab(gtfsStaticKey);
      debugPrint('GTFS-Import erfolgreich abgeschlossen.');
    } catch (e, st) {
      debugPrint('Fehler beim GTFS-Import: $e');
      debugPrint('$st');
    }
  }

  void dispose() {
    database.close();
    realtimeRepository.dispose();
  }
}
