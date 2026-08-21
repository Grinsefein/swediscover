import 'package:flutter/foundation.dart';

import '../data/app_database.dart';
import '../data/gtfs_importer.dart';
import '../data/stop_repository.dart';
import '../repositories/bff_realtime_repository.dart';
import '../repositories/realtime_repository.dart';

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
    final database = await AppDatabase.create();
    
    // Prüfen ob DB leer ist -> GTFS-Import anstoßen
    final stopCount = await database.countStops();
    if (stopCount == 0) {
      debugPrint('GTFS-DB ist leer, starte Import...');
      // Hinweis: Der eigentliche Import läuft asynchron im Hintergrund
      // um den App-Start nicht zu blockieren
      unawaited(_triggerGtfsImport(database));
    }

    final stopRepository = StopRepository(database);
    final realtimeRepository = BffRealtimeRepository();

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
      final importer = GtfsImporter(database);
      // Key aus dart-define oder Fallback (nur für Dev!)
      const gtfsStaticKey = String.fromEnvironment(
        'TRAFIKLAB_GTFS_STATIC_KEY',
        defaultValue: '', // In Production MUSS ein Key gesetzt werden
      );
      
      if (gtfsStaticKey.isEmpty) {
        debugPrint('⚠️ TRAFIKLAB_GTFS_STATIC_KEY nicht gesetzt. GTFS-Import übersprungen.');
        debugPrint('   Starte mit: flutter run --dart-define=TRAFIKLAB_GTFS_STATIC_KEY=<key>');
        return;
      }

      await importer.importFromTrafiklab(gtfsStaticKey);
      debugPrint('GTFS-Import erfolgreich abgeschlossen.');
    } catch (e, st) {
      debugPrint('Fehler beim GTFS-Import: $e');
      debugPrint('$st');
    }
  }

  @override
  void dispose() {
    database.close();
    if (realtimeRepository is ChangeNotifier) {
      (realtimeRepository as ChangeNotifier).dispose();
    }
  }
}

// Helper für unawaited (falls nicht in dart:async verfügbar)
Future<void> unawaited(Future<void> future) async {
  try {
    await future;
  } catch (e, st) {
    debugPrint('Uncaught error in unawaited future: $e\n$st');
  }
}
