import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:swediscover/main.dart';

/// Im Widget-Test gibt es keine native MapLibre-Engine. Diese Fake-Plattform
/// verhindert das Rendern der Karte, ohne den Method-Channel zu berühren
/// (sonst wirft die Karte bei der Disposal eine LateError).
class _FakeMapLibrePlatform extends MapLibreMethodChannel {
  @override
  Widget buildView(
    Map<String, dynamic> creationParams,
    OnPlatformViewCreatedCallback onPlatformViewCreated,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
  ) {
    return const SizedBox.expand();
  }

  @override
  // ignore: must_call_super
  void dispose() {
    // Kein echter Channel im Test – bewusst leer. super.dispose() würde
    // `_channel` (late, nie initialisiert) berühren und eine LateError werfen.
  }
}

void main() {
  testWidgets('SweDiscover App smoke test', (WidgetTester tester) async {
    MapLibrePlatform.createInstance = () => _FakeMapLibrePlatform();

    await tester.pumpWidget(const SweDiscoverApp());
    // Fake-Zeit vorspulen, damit die asynchronen Demo-Suchen abschließen
    // und flutter_animate-Delay-Timer abfeuern können.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('SweDiscover'), findsWidgets);
  });
}