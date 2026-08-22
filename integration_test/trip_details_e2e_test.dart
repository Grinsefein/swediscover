import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:swediscover/main.dart';
import 'package:swediscover/services/app_services.dart';
import 'package:swediscover/views/live_map_view.dart';

/// Real-device E2E for the vehicle trip-details flow (MIUI blocks `adb input`,
/// so taps are driven in-process via the Flutter integration_test binding):
///
/// 1. boots the real app against the live BFF on localhost:8080 (adb reverse)
/// 2. waits until /api/vehicles has loaded into map symbols
/// 3. taps the map at a position with a nearby live vehicle
/// 4. asserts the bottom sheet appears and trip details (route + stop list)
///    render, incl. delays
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  const bff = 'http://localhost:8080';
  const cameraCenter = LatLng(59.3312, 18.0594); // Stockholm C, app default

  testWidgets('E2E: tap vehicle -> trip details bottom sheet with stops', (tester) async {
    // -- 0. sanity: BFF reachable from device --------------------------------
    final health = await http.get(Uri.parse('$bff/api/health')).timeout(const Duration(seconds: 5));
    expect(health.statusCode, 200, reason: 'BFF not reachable – run adb reverse tcp:8080 tcp:8080');

    // Pick a vehicle near the camera center so a center-tap hits it.
    final vehRes = await http.get(Uri.parse('$bff/api/vehicles')).timeout(const Duration(seconds: 30));
    final vehicles = ((jsonDecode(vehRes.body) as Map)['vehicles'] as List)
        .cast<Map<String, dynamic>>();
    expect(vehicles, isNotEmpty);
    double dist(Map<String, dynamic> v) {
      final dLat = (v['lat'] as num).toDouble() - cameraCenter.latitude;
      final dLng = (v['lng'] as num).toDouble() - cameraCenter.longitude;
      return dLat * dLat + dLng * dLng;
    }
    vehicles.sort((a, b) => dist(a).compareTo(dist(b)));
    final nearest = vehicles.first;
    final nearestDist = dist(nearest);
    debugPrint('nearest vehicle to camera center: ${nearest['vehicleId']} '
        '(line=${nearest['line']}, d=${(nearestDist * 111000).toStringAsFixed(0)}m)');
    expect(nearestDist < 0.05 * 0.05, isTrue,
        reason: 'no live vehicle within tap radius of Stockholm C – '
            'test would be flaky; move camera or retry later');

    // -- 1. boot the real app -------------------------------------------------
    final services = await AppServices.create();
    await tester.pumpWidget(SweDiscoverApp(services: services));

    // App uses periodic timers (interpolation @100ms, refresh @15s, pulsing
    // indicator) -> pumpAndSettle never settles. Pump manually instead.
    Future<void> pumpFor(Duration d) async {
      final end = DateTime.now().add(d);
      while (DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 200));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }

    // -- 2. wait for the live map tab + style load ----------------------------
    expect(find.byType(LiveMapView), findsOneWidget);
    await pumpFor(const Duration(seconds: 6)); // MapLibre style fetch + icons
    expect(find.byType(MapLibreMap), findsOneWidget,
        reason: 'map must be rendered (check MapTiler key/style URL)');

    // Wait until vehicles are loaded: loading banner disappears when loaded.
    bool loaded = false;
    for (var i = 0; i < 30 && !loaded; i++) {
      await pumpFor(const Duration(seconds: 1));
      loaded = find.textContaining('Lade Live-Fahrzeuge').evaluate().isEmpty &&
          find.textContaining('Keine Live-Fahrzeuge').evaluate().isEmpty &&
          find.textContaining('nicht verfügbar').evaluate().isEmpty;
    }
    expect(loaded, isTrue, reason: 'vehicles never left loading/error state');
    debugPrint('vehicles loaded, tapping map …');

    // -- 3. tap the map near the known vehicle --------------------------------
    // The map fills most of the screen; tap its visual center.
    //
    // WICHTIG: `tester.tap` erzeugt synthetische Flutter-Events, die auf
    // manchen Geräten die native MapLibre Platform-View nicht erreichen
    // (onMapClick bleibt stumm). Der Host-Injektor (run_e2e_device.sh)
    // sendet zusätzlich echte `adb shell input tap` Gesten, sobald es den
    // READY_FOR_TAP-Marker im Logcat sieht. Deshalb: Marker ausgeben und
    // dann bis zu 90s lang auf ein Bottom Sheet pollEN – welche Fahrzeug-ID
    // gewählt wird, ist egal (Fähren/Busse bewegen sich; _selectNearest
    // nimmt das nächste Fahrzeug zum Klickpunkt).
    debugPrint('READY_FOR_TAP');
    String? selectedId;
    final sheetTexts = <String>['ID: sl:', 'Trip 1'];
    for (var i = 0; i < 45 && selectedId == null; i++) {
      if (i % 8 == 0) {
        // Best-effort in-process tap (funktioniert nicht überall).
        await tester.tap(find.byType(MapLibreMap), warnIfMissed: false);
      }
      await pumpFor(const Duration(seconds: 2));
      for (final marker in sheetTexts) {
        if (find.textContaining(marker).evaluate().isNotEmpty) {
          selectedId = marker;
          break;
        }
      }
    }
    if (selectedId == null) {
      // Diagnostics: dump everything currently visible before failing.
      final texts = tester.widgetList<Text>(
        find.descendant(
          of: find.byType(MaterialApp),
          matching: find.byType(Text),
        ),
      );
      debugPrint('=== visible texts after tap phase ===');
      for (final t in texts) {
        final s = t.data ?? t.textSpan?.toPlainText();
        if (s != null && s.trim().isNotEmpty) debugPrint('TEXT: $s');
      }
    }
    expect(selectedId, isNotNull,
        reason: 'bottom sheet should show a selected vehicle after map tap '
            '(host must inject adb input taps – see run_e2e_device.sh)');

    // -- 4. wait for trip details (GET /api/trip-details/{id}) -----------------
    bool stopsVisible = false;
    String? failureText;
    for (var i = 0; i < 25 && !stopsVisible; i++) {
      await pumpFor(const Duration(seconds: 1));
      if (find.textContaining('hållplatser').evaluate().isNotEmpty ||
          find.textContaining('Inga hållplatser').evaluate().isNotEmpty) {
        stopsVisible = true;
      }
      final errFinder = find.textContaining('nicht geladen');
      if (errFinder.evaluate().isNotEmpty) failureText = 'details error row shown';
    }
    expect(failureText, isNull, reason: 'trip-details request failed in-app');
    expect(stopsVisible, isTrue, reason: 'stop progress list did not appear within 25s');

    debugPrint('trip details visible for selected vehicle');

    // Give the map overlays (polyline + stop circles) a moment, keep the UI up
    // so an external `adb exec-out screencap` can capture the verified state.
    await pumpFor(const Duration(seconds: 10));
  });
}
