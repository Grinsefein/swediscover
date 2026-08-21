/// Mappt ResRobot-v2.1-Departures auf das Abfahrts-JSON der Flutter-App
/// (vgl. `TransitDeparture.fromJson`).
class DepartureMapper {
  static const _occupied = ['manySeats'];

  /// Liefert null, wenn die Zeile nicht sinnvoll mappbar ist.
  static Map<String, dynamic>? fromResRobot(Map<String, dynamic> d) {
    final product = d['Product'] as Map<String, dynamic>? ?? const {};
    final catCode = int.tryParse(product['catCode']?.toString() ?? '') ?? 0;

    final scheduled = _parseDateTime(d['date'], d['time']);
    if (scheduled == null) return null;

    final realtime = _parseDateTime(d['rtDate'], d['rtTime']) ?? scheduled;
    final delaySeconds = realtime.difference(scheduled).inSeconds;

    return {
      'id': '${d['stopExtId']}-${d['transportNumber']}-${scheduled.toIso8601String()}',
      'stopId': d['stopExtId'] ?? '',
      'line': d['transportNumber'] ?? product['line'] ?? product['num'] ?? '',
      'destination': d['direction'] ?? '',
      'mode': _modeFromCatCode(catCode),
      'scheduledTime': scheduled.toIso8601String(),
      'realtimeTime': realtime.toIso8601String(),
      'delaySeconds': delaySeconds,
      'status': delaySeconds >= 60 ? 'delayed' : 'onTime',
      'track': d['rtTrack'] ?? d['track'] ?? '',
      'originalTrack': d['track'] as String?,
      'operatorName': product['operator'] ?? '',
      'occupancy': _occupied[0],
      'hasWheelchairAccess': true,
      'hasBicycleAccess': false,
      'hasWifi': true,
    };
  }

  static String _modeFromCatCode(int catCode) {
    switch (catCode) {
      case 2: // Hochgeschwindigkeits-/Expresszüge
      case 4: // Regional- und InterCity-Züge
        return 'fjarrtag';
      case 16: // Lokale Züge
        return 'pendeltag';
      case 32: // Tunnelbana
        return 'tunnelbana';
      case 64: // Spårvagn / Stadtbahn
        return 'tram';
      case 128: // Lokale Busse
        return 'bus';
      case 256: // Fähren
        return 'ferry';
      default:
        return 'bus';
    }
  }

  static DateTime? _parseDateTime(dynamic date, dynamic time) {
    if (date is! String || time is! String) return null;
    final normalizedTime =
        time.length == 5 ? '$time:00' : time; // HH:MM → HH:MM:SS
    return DateTime.tryParse('${date}T$normalizedTime');
  }
}