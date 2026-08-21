import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';

import '../config/map_config.dart';
import '../models/vehicle_position_model.dart';
import '../models/departure_model.dart';
import '../repositories/realtime_repository.dart';
import '../services/api_exception.dart';
import '../services/vehicle_interpolation_isolate.dart';

/// Zustand der Live-Fahrzeugdaten für sichtbares Nutzer-Feedback.
enum _VehicleLoadState { loading, loaded, empty, error }

class LiveMapView extends StatefulWidget {
  const LiveMapView({super.key});

  @override
  State<LiveMapView> createState() => _LiveMapViewState();
}

class _LiveMapViewState extends State<LiveMapView> {
  MapLibreMapController? _mapController;
  Timer? _animationTimer;
  List<RealtimeVehiclePosition> _vehicles = [];
  RealtimeVehiclePosition? _selectedVehicle;

  /// Sichtbarer Zustand der Live-Daten statt stiller Leere:
  /// warum ist die Karte leer (lädt / wirklich keine Fahrzeuge / Fehler)?
  _VehicleLoadState _loadState = _VehicleLoadState.loading;
  String? _errorDetail;

  final Map<String, Symbol> _symbols = {};
  final Map<String, Line> _lines = {};

  bool _mapReady = false;
  Future<MapConfig>? _mapConfigFuture;

  /// Konvertiert einen latlong2-Punkt in den MapLibre-eigenen [LatLng].
  static LatLng _toMapLibre(ll.LatLng p) => LatLng(p.latitude, p.longitude);

  @override
  void initState() {
    super.initState();
    _mapConfigFuture = MapConfig.resolve();
    _loadVehicles();

    // 10 FPS Vektor-Interpolation entlang der Routen-Polylines; MapLibre
    // rendert nativ weiter mit 60 FPS. Symbol-Updates an die Native-Engine
    // werden bewusst limitiert, um Frame-Stutter auf der Karte zu vermeiden.
    _animationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_mapReady || _mapController == null) return;
      if (_vehicles.isEmpty) return; // Keine Rebuilds/Akku ohne Fahrzeuge
      final stepped = VehicleInterpolationIsolate.stepVehiclePositions(_vehicles, 0.1);
      if (mounted) {
        setState(() {
          _vehicles = stepped;
          if (_selectedVehicle != null) {
            _selectedVehicle = stepped.firstWhere(
              (v) => v.vehicleId == _selectedVehicle!.vehicleId,
              orElse: () => _selectedVehicle!,
            );
          }
        });
        _upsertSymbols();
      }
    });
  }

  void _loadVehicles() {
    setState(() {
      _loadState = _VehicleLoadState.loading;
      _errorDetail = null;
    });

    Provider.of<RealtimeRepository>(context, listen: false)
        .fetchVehicles()
        .then((vehicles) {
      if (!mounted) return;
      setState(() {
        _vehicles = vehicles;
        _loadState = vehicles.isEmpty ? _VehicleLoadState.empty : _VehicleLoadState.loaded;
      });
      _upsertSymbols();
    }).catchError((Object e) {
      if (!mounted) return;
      setState(() {
        _loadState = _VehicleLoadState.error;
        _errorDetail = e is ApiException ? e.userMessage : '$e';
      });
    });
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
  }

  void _onStyleLoaded() {
    if (!mounted) return;
    _mapReady = true;
    _drawLines();
    _upsertSymbols();
  }

  Future<void> _drawLines() async {
    final controller = _mapController;
    if (controller == null) return;

    for (final vehicle in _vehicles) {
      if (vehicle.routePolyline.length < 2) continue;
      final key = vehicle.tripId;
      if (_lines.containsKey(key)) continue;

      final line = await controller.addLine(
        LineOptions(
          geometry: vehicle.routePolyline.map(_toMapLibre).toList(),
          lineColor: _modeColorHex(vehicle.mode),
          lineWidth: 5.0,
          lineOpacity: 0.7,
        ),
      );
      _lines[key] = line;
    }
  }

  Future<void> _upsertSymbols() async {
    final controller = _mapController;
    if (controller == null || !_mapReady) return;

    final currentIds = _vehicles.map((v) => v.vehicleId).toSet();

    for (final vehicle in _vehicles) {
      final options = SymbolOptions(
        geometry: _toMapLibre(vehicle.currentPosition),
        iconImage: 'marker',
        iconSize: 1.4,
        iconAnchor: 'center',
        iconColor: _modeColorHex(vehicle.mode),
        iconHaloColor: '#ffffff',
        iconHaloWidth: 1.5,
        textField: vehicle.line,
        textSize: 12,
        textOffset: const Offset(0, 2.5),
        textColor: '#ffffff',
        textHaloColor: _modeColorHex(vehicle.mode),
        textHaloWidth: 2,
        fontNames: const ['Noto Sans Regular'],
        zIndex: 10,
      );

      final existing = _symbols[vehicle.vehicleId];
      if (existing != null) {
        await controller.updateSymbol(existing, options);
      } else {
        final symbol = await controller.addSymbol(options);
        _symbols[vehicle.vehicleId] = symbol;
      }
    }

    for (final entry in _symbols.keys.toList()) {
      if (!currentIds.contains(entry)) {
        final symbol = _symbols.remove(entry);
        if (symbol != null) {
          await controller.removeSymbol(symbol);
        }
      }
    }
  }

  void _selectNearest(LatLng point) {
    RealtimeVehiclePosition? nearest;
    double bestDistance = 0.05; // ~5 km Schwellenwert für die Auswahl
    for (final vehicle in _vehicles) {
      final dLat = (vehicle.currentPosition.latitude - point.latitude).abs();
      final dLng = (vehicle.currentPosition.longitude - point.longitude).abs();
      final distance = math.sqrt(dLat * dLat + dLng * dLng);
      if (distance < bestDistance) {
        bestDistance = distance;
        nearest = vehicle;
      }
    }
    if (nearest != null) {
      setState(() => _selectedVehicle = nearest);
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_toMapLibre(nearest.currentPosition), 14.0),
      );
    }
  }

  Color _getModeColor(TransitMode mode) {
    switch (mode) {
      case TransitMode.tunnelbana:
        return const Color(0xFFEF4444); // SL Red / Red Line
      case TransitMode.pendeltag:
        return const Color(0xFF3B82F6); // SL Blue
      case TransitMode.fjarrtag:
        return const Color(0xFF10B981); // SJ Emerald Green
      case TransitMode.tram:
        return const Color(0xFFF59E0B); // Tram Amber/Gold
      case TransitMode.bus:
        return const Color(0xFF8B5CF6); // Bus Violet
      case TransitMode.ferry:
        return const Color(0xFF06B6D4); // Cyan
    }
  }

  String _modeColorHex(TransitMode mode) {
    final color = _getModeColor(mode);
    final rgb = (color.r * 255).round() << 16 | (color.g * 255).round() << 8 | (color.b * 255).round();
    return '#${rgb.toRadixString(16).padLeft(6, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final realtimeRepository = Provider.of<RealtimeRepository>(context);

    return FutureBuilder<MapConfig>(
      future: _mapConfigFuture,
      builder: (context, configSnapshot) {
        final mapWidget = configSnapshot.connectionState == ConnectionState.done &&
                configSnapshot.hasData
            ? MapLibreMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(59.3312, 18.0594), // Stockholm C default
                  zoom: 12.5,
                ),
                styleString: configSnapshot.data!.styleString,
                onMapCreated: _onMapCreated,
                onStyleLoadedCallback: _onStyleLoaded,
                onMapClick: (point, coordinates) => _selectNearest(coordinates),
              )
            : const Center(child: CircularProgressIndicator());

        return Stack(
      children: [
        // MapLibre GL Native Vector Engine
        mapWidget,

        // Top Overlay: Material 3 Bounding Box & Active Filters Header
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: SafeArea(
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.sensors_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                              Intl.message(
                                'Trafiklab GTFS-RT Live',
                                desc: 'Header text in the map view',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.3, 1.3)),
                            ],
                          ),
                          Text(
                            '${configSnapshot.data?.label ?? "Karte"} • 60 FPS Interpolation • ${realtimeRepository.telemetry.activeVehiclesInViewport} in Viewport',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bounding Box Filter Toggle Switch
                    FilterChip(
                      selected: realtimeRepository.isBoundingBoxFilterActive,
label: Text(
                          Intl.message(
                            realtimeRepository.isBoundingBoxFilterActive
                                ? 'BBox Active'
                                : 'All Sweden',
                            desc: 'Bounding box filter toggle label',
                          ),
                          style: const TextStyle(fontSize: 12),
                        ),
                      onSelected: (_) => realtimeRepository.toggleBoundingBoxFilter(),
                      avatar: Icon(
                        realtimeRepository.isBoundingBoxFilterActive ? Icons.crop_free_rounded : Icons.public_rounded,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Quick City Jump Floating Action Pills
        Positioned(
          top: 96,
          left: 16,
          right: 16,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCityChip(Intl.message('Stockholm C', desc: 'City chip label for Stockholm'), const LatLng(59.3312, 18.0594)),
                const SizedBox(width: 8),
                _buildCityChip(Intl.message('Göteborg C', desc: 'City chip label for Göteborg'), const LatLng(57.7089, 11.9731)),
                const SizedBox(width: 8),
                _buildCityChip(Intl.message('Malmö C', desc: 'City chip label for Malmö'), const LatLng(55.6091, 13.0007)),
                const SizedBox(width: 8),
                _buildCityChip(Intl.message('Uppsala C', desc: 'City chip label for Uppsala'), const LatLng(59.8586, 17.6461)),
              ],
            ),
          ),
        ),

        // Status-Banner: sichtbarer Grund, warum (k)eine Fahrzeuge zu sehen sind
        if (_loadState != _VehicleLoadState.loaded)
          Positioned(
            top: 148,
            left: 16,
            right: 16,
            child: SafeArea(child: _buildStatusBanner(theme)),
          ),

        // Bottom Selected Vehicle Card Sheet
        if (_selectedVehicle != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _getModeColor(_selectedVehicle!.mode),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _selectedVehicle!.line,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nästa: ${_selectedVehicle!.nextStopName}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'ID: ${_selectedVehicle!.vehicleId}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(() => _selectedVehicle = null),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildVehicleMetric(
                          icon: Icons.speed_rounded,
                          label: Intl.message('Hastighet', desc: 'Vehicle metric label for speed'),
                          value: '${_selectedVehicle!.speedKmh.toStringAsFixed(1)} km/h',
                        ),
                        _buildVehicleMetric(
                          icon: Icons.explore_rounded,
                          label: Intl.message('Bäring', desc: 'Vehicle metric label for bearing'),
                          value: '${_selectedVehicle!.bearing.round()}°',
                        ),
                        _buildVehicleMetric(
                          icon: Icons.groups_rounded,
                          label: Intl.message('Beläggning', desc: 'Vehicle metric label for occupancy'),
                          value: _getOccupancyText(_selectedVehicle!.occupancy),
                        ),
                        _buildVehicleMetric(
                          icon: Icons.timer_rounded,
                          label: Intl.message('Status', desc: 'Vehicle metric label for status'),
                          value: _selectedVehicle!.delayMinutes == 0
                              ? Intl.message('I tid', desc: 'On time status')
                              : Intl.message('+${_selectedVehicle!.delayMinutes} min', desc: 'Delayed minutes status'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ).animate().slideY(begin: 0.3, end: 0, duration: const Duration(milliseconds: 250)),
          ),
      ],
        );
      },
    );
  }

  Widget _buildStatusBanner(ThemeData theme) {
    final (icon, color, message) = switch (_loadState) {
      _VehicleLoadState.loading => (
          Icons.hourglass_top_rounded,
          theme.colorScheme.primary,
          Intl.message(
            'Lade Live-Fahrzeuge …',
            desc: 'Live map: loading vehicles',
          ),
        ),
      _VehicleLoadState.empty => (
          Icons.sensors_off_rounded,
          theme.colorScheme.tertiary,
          Intl.message(
            'Keine Live-Fahrzeuge verfügbar – außerhalb des Betriebs oder Feed leer.',
            desc: 'Live map: no vehicles available',
          ),
        ),
      _VehicleLoadState.error => (
          Icons.error_outline_rounded,
          theme.colorScheme.error,
          Intl.message(
            'Live-Daten nicht verfügbar.',
            desc: 'Live map: live data unavailable',
          ),
        ),
      _VehicleLoadState.loaded => (
          Icons.sensors_rounded,
          theme.colorScheme.primary,
          '',
        ),
    };

    return Card(
      elevation: 4,
      color: theme.colorScheme.surface.withValues(alpha: 0.95),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            if (_loadState == _VehicleLoadState.loading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            else
              Icon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _loadState == _VehicleLoadState.error && _errorDetail != null
                    ? '$message $_errorDetail'
                    : message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (_loadState != _VehicleLoadState.loading)
              TextButton.icon(
                icon: Icon(Icons.refresh_rounded, size: 16, color: color),
                label: Text(Intl.message(
                  'Erneut versuchen',
                  desc: 'Retry button for live data loading',
                )),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontSize: 12),
                ),
                onPressed: _loadVehicles,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCityChip(String cityName, LatLng coords) {
    return ActionChip(
      avatar: const Icon(Icons.location_on_rounded, size: 16),
      label: Text(cityName),
      onPressed: () {
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(coords, 13.0));
      },
    );
  }

  Widget _buildVehicleMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  String _getOccupancyText(OccupancyStatus status) {
    switch (status) {
      case OccupancyStatus.empty:
        return Intl.message('Tomt', desc: 'Occupancy status: empty');
      case OccupancyStatus.manySeats:
        return Intl.message('Gott om plats', desc: 'Occupancy status: many seats available');
      case OccupancyStatus.fewSeats:
        return Intl.message('Få platser', desc: 'Occupancy status: few seats available');
      case OccupancyStatus.standingRoom:
        return Intl.message('Ståplats', desc: 'Occupancy status: standing room');
      case OccupancyStatus.full:
        return Intl.message('Fullsatt', desc: 'Occupancy status: full');
    }
  }
}