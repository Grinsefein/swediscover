import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';

import '../services/app_settings_service.dart';

/// Verfügbare Karten-Provider für die Live-Karte.
enum MapProvider {
  /// MapLibre-Demo-Style (vektor, ohne Key – nur Entwicklungsbetrieb).
  demo,

  /// OpenStreetMap-Raster-Tiles (frei, ohne Key; Nutzungsrichtlinie beachten).
  osm,

  /// CARTO Basemaps GL (vektor, frei für begrenzte Nutzung, kein Key nötig).
  carto,

  /// MapTiler-Vektor-Style (benötigt `MAP_TILER_API_KEY` aus Settings/.env).
  maptiler,
}

/// Konfiguration der Kartenprovider.
///
/// Priorität beim Auto-Modus: MapTiler (Key vorhanden & erreichbar) →
/// CARTO Positron → OSM Raster. Per Dart-Define überschreibbar:
///
///   --dart-define=MAP_PROVIDER=demo|osm|carto|maptiler
class MapConfig {
  final MapProvider provider;
  final String? maptilerKey;

  const MapConfig({required this.provider, this.maptilerKey});

  /// Manueller Override per --dart-define, sonst null (= Auto-Fallback-Kette).
  static MapProvider? _dartDefineOverride() {
    final name =
        const String.fromEnvironment('MAP_PROVIDER', defaultValue: '')
            .toLowerCase();
    if (name.isEmpty) return null;
    return MapProvider.values.asNameMap()[name];
  }

  /// Lädt die Config asynchron aus den App-Settings (.env / gespeicherte Keys)
  /// und validiert den MapTiler-Key per Pre-Flight-Check. Schlägt der fehl,
  /// wird automatisch auf den nächsten freien Provider gefallen.
  static Future<MapConfig> resolve() async {
    final override = _dartDefineOverride();
    if (override != null) {
      debugPrint('MapConfig: dart-define override → ${override.name}');
      return MapConfig(provider: override);
    }

    final settings = await AppSettingsService.getInstance();
    final key = settings.getKey('MAP_TILER_API_KEY');

    // 1. MapTiler – bester Look, aber nur mit gültigem Key.
    if (key.isNotEmpty) {
      final ok = await _styleReachable(
        'https://api.maptiler.com/maps/streets-v2/style.json?key=$key',
      );
      if (ok) {
        debugPrint('MapConfig: using MapTiler streets-v2');
        return MapConfig(provider: MapProvider.maptiler, maptilerKey: key);
      }
      debugPrint('MapConfig: MapTiler style not reachable/invalid key – falling back');
    }

    // 2. CARTO Positron – freier Vektor-Stil ohne Key.
    if (await _styleReachable(
      'https://basemaps.cartocdn.com/gl/positron-gl-style/style.json',
    )) {
      debugPrint('MapConfig: using CARTO Positron fallback');
      return const MapConfig(provider: MapProvider.carto);
    }

    // 3. OSM Raster – funktioniert praktisch immer.
    debugPrint('MapConfig: using OSM raster fallback');
    return const MapConfig(provider: MapProvider.osm);
  }

  static Future<bool> _styleReachable(String url) async {
    try {
      final res = await http.Client()
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 6));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Style-URL bzw. Style-JSON, das MapLibre direkt versteht.
  String get styleString {
    switch (provider) {
      case MapProvider.demo:
        return MapLibreStyles.demo;
      case MapProvider.osm:
        return _osmRasterStyle;
      case MapProvider.carto:
        return 'https://basemaps.cartocdn.com/gl/positron-gl-style/style.json';
      case MapProvider.maptiler:
        if (maptilerKey == null || maptilerKey!.isEmpty) {
          return MapLibreStyles.demo;
        }
        return 'https://api.maptiler.com/maps/streets-v2/style.json?key=$maptilerKey';
    }
  }

  String get label {
    switch (provider) {
      case MapProvider.demo:
        return 'MapLibre Demo';
      case MapProvider.osm:
        return 'OSM Raster';
      case MapProvider.carto:
        return 'CARTO Positron';
      case MapProvider.maptiler:
        return 'MapTiler';
    }
  }

  static const _osmRasterStyle = '''
{
  "version": 8,
  "name": "OpenStreetMap Raster",
  "sources": {
    "osm": {
      "type": "raster",
      "tiles": ["https://tile.openstreetmap.org/{z}/{x}/{y}.png"],
      "tileSize": 256,
      "maxzoom": 19,
      "attribution": "© OpenStreetMap-Mitwirkende"
    }
  },
  "layers": [
    {"id": "osm", "type": "raster", "source": "osm"}
  ]
}''';
}
