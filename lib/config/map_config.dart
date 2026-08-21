import 'package:maplibre_gl/maplibre_gl.dart';

/// Verfügbare Karten-Provider für die Live-Karte.
enum MapProvider {
  /// MapLibre-Demo-Style (vektor, ohne Key – nur Entwicklungsbetrieb).
  demo,

  /// OpenStreetMap-Raster-Tiles (frei, ohne Key; Nutzungsrichtlinie beachten).
  osm,

  /// CARTO Basemaps GL (vektor, frei für begrenzte Nutzung, kein Key nötig).
  carto,

  /// MapTiler-Vektor-Style (benötigt `MAPTILER_KEY`).
  maptiler,
}

/// Konfiguration der Kartenprovider aus Dart-Defines.
///
///   --dart-define=MAP_PROVIDER=demo|osm|carto|maptiler
///   --dart-define=MAPTILER_KEY=...
class MapConfig {
  final MapProvider provider;
  final String? maptilerKey;

  const MapConfig({required this.provider, this.maptilerKey});

  static MapConfig fromEnvironment() {
    final name =
        const String.fromEnvironment('MAP_PROVIDER', defaultValue: 'demo')
            .toLowerCase();
    final provider =
        MapProvider.values.asNameMap()[name] ?? MapProvider.demo;
    return MapConfig(
      provider: provider,
      maptilerKey: const String.fromEnvironment('MAPTILER_KEY'),
    );
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