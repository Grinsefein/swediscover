import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';

import '../config/map_config.dart';
import '../models/vehicle_position_model.dart';
import '../models/vehicle_trip_details.dart';
import '../models/departure_model.dart';
import '../repositories/realtime_repository.dart';
import '../services/api_exception.dart';
import '../services/vehicle_interpolation_isolate.dart';
import '../services/vehicle_trip_service.dart';

enum _VehicleLoadState { loading, loaded, empty, error }

class LiveMapView extends StatefulWidget {
  const LiveMapView({super.key});
  @override State<LiveMapView> createState() => _LiveMapViewState();
}

class _LiveMapViewState extends State<LiveMapView> {
  MapLibreMapController? _mapController;
  Timer? _animationTimer;
  Timer? _refreshTimer;
  List<RealtimeVehiclePosition> _vehicles = [];
  RealtimeVehiclePosition? _selectedVehicle;
  VehicleTripDetails? _selectedDetails;
  bool _detailsLoading = false;
  String? _detailsError;

  _VehicleLoadState _loadState = _VehicleLoadState.loading;
  String? _errorDetail;

  final Map<String, Symbol> _symbols = {};
  final Map<String, Line> _lines = {};
  final Map<String, Circle> _stopCircles = {};
  Line? _tripLine;

  bool _mapReady = false;
  bool _markerIconsRegistered = false;
  Future<MapConfig>? _mapConfigFuture;

  final VehicleTripService _tripService = VehicleTripService();

  static LatLng _toMapLibre(ll.LatLng p) => LatLng(p.latitude, p.longitude);

  @override
  void initState() {
    super.initState();
    _mapConfigFuture = MapConfig.resolve();
    _loadVehicles();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_mapReady || _mapController == null) return;
      if (_vehicles.isEmpty) return;
      final stepped = VehicleInterpolationIsolate.stepVehiclePositions(_vehicles, 0.1);
      if (mounted) {
        setState(() {
          _vehicles = stepped;
          if (_selectedVehicle != null) {
            _selectedVehicle = stepped.firstWhere((v) => v.vehicleId == _selectedVehicle!.vehicleId, orElse: () => _selectedVehicle!);
          }
        });
        _upsertSymbols();
      }
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _refreshVehicles());
  }

  void _loadVehicles() {
    setState(() { _loadState = _VehicleLoadState.loading; _errorDetail = null; });
    Provider.of<RealtimeRepository>(context, listen: false).fetchVehicles().then((vehicles) {
      if (!mounted) return;
      setState(() { _vehicles = vehicles; _loadState = vehicles.isEmpty ? _VehicleLoadState.empty : _VehicleLoadState.loaded; });
      _upsertSymbols();
    }).catchError((Object e) {
      if (!mounted) return;
      setState(() { _loadState = _VehicleLoadState.error; _errorDetail = e is ApiException ? e.userMessage : '$e'; });
    });
  }

  Future<void> _refreshVehicles() async {
    if (!mounted) return;
    try {
      final vehicles = await Provider.of<RealtimeRepository>(context, listen: false).fetchVehicles();
      if (!mounted) return;
      setState(() {
        _vehicles = vehicles;
        if (_selectedVehicle != null) {
          _selectedVehicle = vehicles.firstWhere((v) => v.vehicleId == _selectedVehicle!.vehicleId, orElse: () => _selectedVehicle!);
        }
      });
      _upsertSymbols();
      if (_selectedVehicle != null && _selectedDetails != null) {
        _loadVehicleDetails(_selectedVehicle!, silent: true);
      }
    } catch (_) {}
  }

  @override void dispose() { _animationTimer?.cancel(); _refreshTimer?.cancel(); _mapController?.dispose(); super.dispose(); }
  void _onMapCreated(MapLibreMapController c) => _mapController = c;
  void _onStyleLoaded() {
    if (!mounted) return;
    _mapReady = true;
    _registerMarkerIcons().then((_) async {
      if (!mounted) return;
      final sm = _mapController?.symbolManager;
      if (sm != null) {
        await sm.setIconAllowOverlap(true);
        await sm.setTextAllowOverlap(true);
        await sm.setIconIgnorePlacement(true);
        await sm.setTextIgnorePlacement(true);
      }
      _drawLines();
      _upsertSymbols();
    });
  }

  Future<void> _registerMarkerIcons() async {
    final c = _mapController;
    if (c == null || _markerIconsRegistered) return;
    final dpr = MediaQuery.of(context).devicePixelRatio.clamp(1.0, 3.0);
    for (final mode in TransitMode.values) {
      final bytes = await _renderPinPng(const Size(28, 36), dpr, _getModeColor(mode), _glyphForMode(mode));
      await c.addImage('marker_${mode.name}', bytes);
      final selBytes = await _renderPinPng(const Size(34, 44), dpr, _getModeColor(mode), _glyphForMode(mode), selected: true);
      await c.addImage('marker_${mode.name}_sel', selBytes);
    }
    _markerIconsRegistered = true;
  }

  IconData _glyphForMode(TransitMode m) {
    switch (m) {
      case TransitMode.tunnelbana: return Icons.subway_rounded;
      case TransitMode.pendeltag: return Icons.train_rounded;
      case TransitMode.fjarrtag: return Icons.directions_railway_rounded;
      case TransitMode.tram: return Icons.tram_rounded;
      case TransitMode.bus: return Icons.directions_bus_rounded;
      case TransitMode.ferry: return Icons.directions_boat_rounded;
    }
  }

  Future<Uint8List> _renderPinPng(Size size, double dpr, Color color, IconData glyph, {bool selected = false}) async {
    final w = (size.width * dpr).round();
    final h = (size.height * dpr).round();
    final rec = ui.PictureRecorder();
    final canvas = ui.Canvas(rec);
    final fill = ui.Paint()..color = color;
    final stroke = ui.Paint()..color = Colors.white..style = ui.PaintingStyle.stroke..strokeWidth = (selected ? 4 : 3) * dpr;
    final shadow = ui.Paint()..color = Colors.black.withValues(alpha: 0.25)..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 4 * dpr);
    final cx = w/2; final cy = h*0.34; final r = w*0.32;
    final tip = ui.Path()..moveTo(cx - r*0.72, cy + r*0.70)..lineTo(cx, h - 2*dpr)..lineTo(cx + r*0.72, cy + r*0.70)..close();
    if (selected) { canvas.drawPath(tip, shadow); canvas.drawCircle(ui.Offset(cx, cy), r, shadow); }
    canvas.drawPath(tip, fill); canvas.drawCircle(ui.Offset(cx, cy), r, fill);
    canvas.drawCircle(ui.Offset(cx, cy), r, stroke); canvas.drawPath(tip, stroke);
    // Glyph – MaterialIcons bereits global geladen
    final tp = TextPainter(text: TextSpan(text: String.fromCharCode(glyph.codePoint), style: TextStyle(fontFamily: 'MaterialIcons', fontSize: r*1.1, color: Colors.white, height: 1.0)), textDirection: ui.TextDirection.ltr, textAlign: TextAlign.center);
    tp.layout();
    final gx = cx - tp.width/2; final gy = cy - tp.height/2 + 1*dpr;
    tp.paint(canvas, Offset(gx, gy));
    final img = await rec.endRecording().toImage(w, h);
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return bd!.buffer.asUint8List();
  }

  Future<void> _drawLines() async {
    final c = _mapController; if (c == null) return;
    for (final v in _vehicles) {
      if (v.routePolyline.length < 2) continue;
      final key = v.tripId; if (_lines.containsKey(key)) continue;
      final line = await c.addLine(LineOptions(geometry: v.routePolyline.map(_toMapLibre).toList(), lineColor: _modeColorHex(v.mode), lineWidth: 5.0, lineOpacity: 0.7));
      _lines[key] = line;
    }
  }

  Future<void> _upsertSymbols() async {
    final c = _mapController; if (c == null || !_mapReady) return;
    final ids = _vehicles.map((v) => v.vehicleId).toSet();
    for (final v in _vehicles) {
      final isSel = _selectedVehicle?.vehicleId == v.vehicleId;
      final opts = SymbolOptions(
        geometry: _toMapLibre(v.currentPosition),
        iconImage: isSel ? 'marker_${v.mode.name}_sel' : 'marker_${v.mode.name}',
        iconSize: isSel ? 1.1 : 0.9,
        iconRotate: v.bearing,
        iconAnchor: 'center',
        textField: v.line,
        textSize: 11,
        textOffset: const Offset(0, 2.4),
        textColor: '#ffffff',
        textHaloColor: _modeColorHex(v.mode),
        textHaloWidth: 1.8,
        fontNames: const ['Noto Sans Regular'],
        zIndex: isSel ? 100 : 10,
      );
      final ex = _symbols[v.vehicleId];
      if (ex != null) { await c.updateSymbol(ex, opts); } else { final s = await c.addSymbol(opts); _symbols[v.vehicleId] = s; }
    }
    for (final id in _symbols.keys.toList()) {
      if (!ids.contains(id)) { final s = _symbols.remove(id); if (s != null) await c.removeSymbol(s); }
    }
  }

  Future<void> _loadVehicleDetails(RealtimeVehiclePosition v, {bool silent = false}) async {
    if (!silent) setState(() { _detailsLoading = true; _detailsError = null; });
    try {
      final details = await _tripService.fetchTripDetails(v.vehicleId);
      if (!mounted) return;
      setState(() { _selectedDetails = details; _detailsLoading = false; });
      await _drawTripDetails(details);
    } catch (e) {
      if (!mounted) return;
      setState(() { _detailsLoading = false; _detailsError = e is ApiException ? e.userMessage : '$e'; });
    }
  }

  Future<void> _drawTripDetails(VehicleTripDetails d) async {
    final c = _mapController; if (c == null) return;
    await _clearTripDetails();
    if (d.shape.isNotEmpty) {
      try {
        _tripLine = await c.addLine(LineOptions(geometry: d.shape.map(_toMapLibre).toList(), lineColor: _modeColorHex(d.vehicle.mode), lineWidth: 4.0, lineOpacity: 0.9, lineJoin: 'round'));
      } catch (_) {}
    }
    for (final stop in d.stops) {
      if (stop.position == null) continue;
      try {
        final circle = await c.addCircle(CircleOptions(
          geometry: _toMapLibre(stop.position!),
          circleRadius: 6,
          circleColor: _toHex(_stopColor(stop, d)),
          circleStrokeColor: '#ffffff',
          circleStrokeWidth: 2,
          circleOpacity: 0.95,
        ));
        _stopCircles[stop.stopId] = circle;
      } catch (_) {}
    }
  }

  Color _stopColor(TripStopDetail s, VehicleTripDetails d) {
    final nextIdx = d.nextStopIndex;
    final idx = d.stops.indexOf(s);
    if (nextIdx >= 0) {
      if (idx < nextIdx) return Colors.grey;
      if (idx == nextIdx) return Colors.orange;
    }
    if (s.hasDelay) return const Color(0xFFEF4444);
    return _getModeColor(d.vehicle.mode).withValues(alpha: 0.7);
  }

  Future<void> _clearTripDetails() async {
    final c = _mapController;
    if (_tripLine != null && c != null) { try { await c.removeLine(_tripLine!); } catch (_) {} }
    _tripLine = null;
    for (final circle in _stopCircles.values) { try { await c?.removeCircle(circle); } catch (_) {} }
    _stopCircles.clear();
  }

  void _selectNearest(LatLng point) async {
    RealtimeVehiclePosition? nearest; double best = 0.05;
    for (final v in _vehicles) {
      final d = math.sqrt(math.pow(v.currentPosition.latitude - point.latitude, 2) + math.pow(v.currentPosition.longitude - point.longitude, 2));
      if (d < best) { best = d; nearest = v; }
    }
    if (nearest != null) {
      setState(() { _selectedVehicle = nearest; _selectedDetails = null; _detailsError = null; });
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_toMapLibre(nearest.currentPosition), 14.5));
      _upsertSymbols();
      await _loadVehicleDetails(nearest);
      _upsertSymbols();
    }
  }

  Color _getModeColor(TransitMode m) {
    switch (m) {
      case TransitMode.tunnelbana: return const Color(0xFFEF4444);
      case TransitMode.pendeltag: return const Color(0xFF3B82F6);
      case TransitMode.fjarrtag: return const Color(0xFF10B981);
      case TransitMode.tram: return const Color(0xFFF59E0B);
      case TransitMode.bus: return const Color(0xFF8B5CF6);
      case TransitMode.ferry: return const Color(0xFF06B6D4);
    }
  }
  String _modeColorHex(TransitMode m) {
    final c = _getModeColor(m);
    final rgb = (c.r*255).round()<<16 | (c.g*255).round()<<8 | (c.b*255).round();
    return '#${rgb.toRadixString(16).padLeft(6,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = Provider.of<RealtimeRepository>(context);
    return FutureBuilder<MapConfig>(
      future: _mapConfigFuture,
      builder: (context, snap) {
        final mapWidget = snap.connectionState==ConnectionState.done && snap.hasData
          ? MapLibreMap(initialCameraPosition: const CameraPosition(target: LatLng(59.3312,18.0594),zoom:12.5), styleString: snap.data!.styleString, onMapCreated: _onMapCreated, onStyleLoadedCallback: _onStyleLoaded, onMapClick: (p,c)=>_selectNearest(c))
          : const Center(child: CircularProgressIndicator());
        return Stack(children: [
          mapWidget,
          Positioned(top:16,left:16,right:16,child: SafeArea(child: Card(elevation:4,child: Padding(padding: const EdgeInsets.symmetric(horizontal:16,vertical:12),child: Row(children:[
            Container(padding: const EdgeInsets.all(8),decoration: BoxDecoration(color: theme.colorScheme.primaryContainer,borderRadius: BorderRadius.circular(12)),child: Icon(Icons.sensors_rounded,color: theme.colorScheme.onPrimaryContainer,size:20)),
            const SizedBox(width:12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,mainAxisSize: MainAxisSize.min,children:[
              Row(children:[Flexible(child: Text(Intl.message('Trafiklab GTFS-RT Live',desc:'Header'),maxLines:1,overflow:TextOverflow.ellipsis,style: theme.textTheme.labelLarge?.copyWith(fontWeight:FontWeight.bold))), const SizedBox(width:6), Container(width:8,height:8,decoration: const BoxDecoration(color: Color(0xFF10B981),shape: BoxShape.circle)).animate(onPlay:(c)=>c.repeat(reverse:true)).scale(begin: const Offset(0.8,0.8),end: const Offset(1.3,1.3))]),
              Text('${snap.data?.label??"Karte"} • 60 FPS • ${repo.telemetry.activeVehiclesInViewport} in Viewport',style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ])),
            FilterChip(selected: repo.isBoundingBoxFilterActive,label: Text(Intl.message(repo.isBoundingBoxFilterActive?'BBox Active':'All Sweden',desc:'toggle'),style: const TextStyle(fontSize:12)),onSelected: (_)=>repo.toggleBoundingBoxFilter(),avatar: Icon(repo.isBoundingBoxFilterActive?Icons.crop_free_rounded:Icons.public_rounded,size:16)),
          ]))))),
          Positioned(top:96,left:16,right:16,child: SingleChildScrollView(scrollDirection: Axis.horizontal,child: Row(children:[
            _buildCityChip(Intl.message('Stockholm C',desc:'Stockholm'), const LatLng(59.3312,18.0594)),
            const SizedBox(width:8),_buildCityChip(Intl.message('Göteborg C',desc:'Göteborg'), const LatLng(57.7089,11.9731)),
            const SizedBox(width:8),_buildCityChip(Intl.message('Malmö C',desc:'Malmö'), const LatLng(55.6091,13.0007)),
            const SizedBox(width:8),_buildCityChip(Intl.message('Uppsala C',desc:'Uppsala'), const LatLng(59.8586,17.6461)),
          ]))),
          if (_loadState != _VehicleLoadState.loaded) Positioned(top:148,left:16,right:16,child: SafeArea(child: _buildStatusBanner(theme))),
          if (_selectedVehicle != null) Positioned(bottom:16,left:16,right:16,child: _buildSelectedCard(theme)),
        ]);
      },
    );
  }

  Widget _buildSelectedCard(ThemeData theme) {
    final v = _selectedVehicle!;
    final d = _selectedDetails;
    return Card(elevation:8,shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),child: Padding(padding: const EdgeInsets.all(16),child: Column(mainAxisSize: MainAxisSize.min,crossAxisAlignment: CrossAxisAlignment.start,children:[
      Row(children:[
        Container(padding: const EdgeInsets.symmetric(horizontal:12,vertical:6),decoration: BoxDecoration(color: _getModeColor(v.mode),borderRadius: BorderRadius.circular(14)),child: Row(mainAxisSize: MainAxisSize.min,children:[Icon(_glyphForMode(v.mode),size:16,color:Colors.white), const SizedBox(width:6), Text(v.line.isNotEmpty? v.line : (d?.route.displayName ?? ''),style: const TextStyle(color:Colors.white,fontWeight:FontWeight.bold)) ])),
        const SizedBox(width:10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,children:[
          Text(d?.tripHeadsign.isNotEmpty==true ? d!.tripHeadsign : v.nextStopName.isNotEmpty ? 'Nästa: ${v.nextStopName}' : 'Trip ${v.tripId.split(":").last}',maxLines:1,overflow:TextOverflow.ellipsis,style: theme.textTheme.titleSmall?.copyWith(fontWeight:FontWeight.bold)),
          Text('ID: ${v.vehicleId} • ${v.speedKmh.toStringAsFixed(0)} km/h • ${v.bearing.round()}°',style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant,fontSize:11)),
        ])),
        IconButton(icon: const Icon(Icons.my_location_rounded),tooltip: 'Zentrieren',onPressed: ()=>_mapController?.animateCamera(CameraUpdate.newLatLngZoom(_toMapLibre(v.currentPosition),15))),
        IconButton(icon: const Icon(Icons.close_rounded),onPressed: () async { await _clearTripDetails(); setState((){ _selectedVehicle=null; _selectedDetails=null;}); _upsertSymbols(); }),
      ]),
      const SizedBox(height:12),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround,children:[
        _buildMetric(icon: Icons.speed_rounded,label: Intl.message('Hastighet',desc:'speed'),value: '${v.speedKmh.toStringAsFixed(0)} km/h'),
        _buildMetric(icon: Icons.explore_rounded,label: Intl.message('Bäring',desc:'bearing'),value: '${v.bearing.round()}°'),
        _buildMetric(icon: Icons.groups_rounded,label: Intl.message('Beläggning',desc:'occ'),value: _getOccupancyText(v.occupancy)),
        _buildMetric(icon: Icons.timer_rounded,label: 'Delay',value: v.delayMinutes==0? Intl.message('I tid',desc:'ontime') : '+${v.delayMinutes} min',color: v.delayMinutes>3? Colors.redAccent : null),
      ]),
      if (_detailsLoading) const Padding(padding: EdgeInsets.only(top:12),child: LinearProgressIndicator()),
      if (_detailsError != null) Padding(padding: const EdgeInsets.only(top:8),child: Row(children:[const Icon(Icons.error_outline,size:16,color:Colors.redAccent), const SizedBox(width:6), Expanded(child: Text(_detailsError!,style: const TextStyle(fontSize:12,color:Colors.redAccent))), TextButton(onPressed: ()=>_loadVehicleDetails(v),child: const Text('Retry'))])),
      if (d != null) ...[
        const Divider(height:16),
        Row(children:[Icon(Icons.route_rounded,size:16,color: theme.colorScheme.primary), const SizedBox(width:6), Expanded(child: Text('${d.route.displayName.isNotEmpty ? "${d.route.displayName} • " : ""}${d.stops.length} hållplatser${d.gtfsReady ? "" : " (GTFS ej redo)"}',style: theme.textTheme.labelSmall?.copyWith(fontWeight:FontWeight.bold,color: theme.colorScheme.primary))), if (d.shape.isNotEmpty) Text('${d.shape.length} pts',style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))]),
        const SizedBox(height:8),
        SizedBox(height: 180,child: d.stops.isEmpty ? Center(child: Text(Intl.message('Inga hållplatser hittades för denna resa.',desc:'no stops'),style: theme.textTheme.bodySmall)) : ListView.separated(
          itemCount: d.stops.length,
          separatorBuilder: (_, _) => const Divider(height:1,indent:32),
          itemBuilder: (ctx,i){
            final s = d.stops[i];
            final isNext = i == d.nextStopIndex;
            final isPast = d.nextStopIndex>=0 ? i < d.nextStopIndex : false;
            final delay = s.effectiveDelay;
            return ListTile(
              dense:true, contentPadding: const EdgeInsets.symmetric(horizontal:8,vertical:0),
              leading: Container(width:28,height:28,decoration: BoxDecoration(color: isNext? Colors.orange : isPast? Colors.grey : _getModeColor(v.mode).withValues(alpha:0.85),shape: BoxShape.circle,border: Border.all(color: Colors.white,width:2)),child: Center(child: Text('${s.stopSequence}',style: const TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.bold)))),
              title: Text(s.name,style: TextStyle(fontSize:13,fontWeight: isNext? FontWeight.bold : FontWeight.normal,color: isPast? Colors.grey : null),maxLines:1,overflow:TextOverflow.ellipsis),
              subtitle: s.arrivalTime.isNotEmpty ? Text('${s.arrivalTime} → ${s.departureTime}',style: const TextStyle(fontSize:11)) : null,
              trailing: delay!=0 ? Container(padding: const EdgeInsets.symmetric(horizontal:8,vertical:4),decoration: BoxDecoration(color: delay>0? Colors.redAccent:Colors.green,borderRadius: BorderRadius.circular(10)),child: Text('${delay>0?"+":""}${delay~/60} min',style: const TextStyle(color:Colors.white,fontSize:11,fontWeight:FontWeight.bold)) ) : (isNext? const Icon(Icons.my_location,size:16,color:Colors.orange):null),
            );
          },
        )),
      ] else if (!_detailsLoading && _detailsError==null) const Padding(padding: EdgeInsets.only(top:8),child: Text('Tippe erneut, um Route & Halte zu laden',style: TextStyle(fontSize:11,color: Colors.grey))),
    ]))).animate().slideY(begin:0.3,end:0,duration: const Duration(milliseconds:220));
  }

  Widget _buildStatusBanner(ThemeData t) {
    final (icon,color,msg) = switch(_loadState){
      _VehicleLoadState.loading => (Icons.hourglass_top_rounded,t.colorScheme.primary,Intl.message('Lade Live-Fahrzeuge …',desc:'loading')),
      _VehicleLoadState.empty => (Icons.sensors_off_rounded,t.colorScheme.tertiary,Intl.message('Keine Live-Fahrzeuge verfügbar.',desc:'empty')),
      _VehicleLoadState.error => (Icons.error_outline_rounded,t.colorScheme.error,Intl.message('Live-Daten nicht verfügbar.',desc:'error')),
      _VehicleLoadState.loaded => (Icons.sensors_rounded,t.colorScheme.primary,''),
    };
    return Card(elevation:4,color: t.colorScheme.surface.withValues(alpha:0.95),child: Padding(padding: const EdgeInsets.symmetric(horizontal:14,vertical:10),child: Row(children:[
      if (_loadState==_VehicleLoadState.loading) SizedBox(width:16,height:16,child: CircularProgressIndicator(strokeWidth:2,color:color)) else Icon(icon,size:20,color:color),
      const SizedBox(width:10), Expanded(child: Text(_loadState==_VehicleLoadState.error && _errorDetail!=null ? '$msg $_errorDetail':msg,style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant))),
      if (_loadState!=_VehicleLoadState.loading) TextButton.icon(icon: Icon(Icons.refresh_rounded,size:16,color:color),label: Text(Intl.message('Erneut versuchen',desc:'retry')),style: TextButton.styleFrom(visualDensity: VisualDensity.compact,textStyle: const TextStyle(fontSize:12)),onPressed: _loadVehicles),
    ])));
  }
  Widget _buildCityChip(String n,LatLng c)=> ActionChip(avatar: const Icon(Icons.location_on_rounded,size:16),label: Text(n),onPressed: ()=>_mapController?.animateCamera(CameraUpdate.newLatLngZoom(c,13.0)));
  Widget _buildMetric({required IconData icon,required String label,required String value,Color? color})=> Column(children:[Icon(icon,size:18,color: color ?? Theme.of(context).colorScheme.primary), const SizedBox(height:2), Text(value,style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight:FontWeight.bold,color: color)), Text(label,style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant,fontSize:10))]);
  String _getOccupancyText(OccupancyStatus s)=> switch(s){ OccupancyStatus.empty => Intl.message('Tomt',desc:'empty'), OccupancyStatus.manySeats => Intl.message('Gott om plats',desc:'many'), OccupancyStatus.fewSeats => Intl.message('Få platser',desc:'few'), OccupancyStatus.standingRoom => Intl.message('Ståplats',desc:'standing'), OccupancyStatus.full => Intl.message('Fullsatt',desc:'full'), };
  String _toHex(Color c) => '#${(c.r*255).round().toRadixString(16).padLeft(2,'0')}${(c.g*255).round().toRadixString(16).padLeft(2,'0')}${(c.b*255).round().toRadixString(16).padLeft(2,'0')}';
}
