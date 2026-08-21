import 'dart:async';

/// Hält den aktuellen Fahrzeug-Snapshot und verbreitet Aktualisierungen an
/// alle WebSocket-Abonnenten (Broadcast).
class VehicleCache {
  final StreamController<List<Map<String, dynamic>>> _controller =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  List<Map<String, dynamic>> _vehicles = const [];

  List<Map<String, dynamic>> get vehicles => _vehicles;

  Stream<List<Map<String, dynamic>>> get updates => _controller.stream;

  void update(List<Map<String, dynamic>> vehicles) {
    _vehicles = List.unmodifiable(vehicles);
    if (!_controller.isClosed) {
      _controller.add(_vehicles);
    }
  }

  void dispose() => _controller.close();
}