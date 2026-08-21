import 'dart:math' as math;

/// Demo-Feed im JSON-Format der App (`RealtimeVehiclePosition.fromJson` /
/// `TransitDeparture.fromJson`). Läuft ohne API-Keys; sobald GTFS-RT
/// konfiguriert ist, übernimmt der Poller die Datenversorgung.
class RouteStop {
  final double lat;
  final double lng;
  final String name;

  const RouteStop(this.lat, this.lng, this.name);
}

class FeedRoute {
  final String vehicleId;
  final String tripId;
  final String line;
  final String mode;
  final String occupancy;
  final double speedKmh;
  final double phase;
  final List<RouteStop> stops;

  const FeedRoute({
    required this.vehicleId,
    required this.tripId,
    required this.line,
    required this.mode,
    this.occupancy = 'manySeats',
    this.speedKmh = 60,
    this.phase = 0,
    required this.stops,
  });

  List<List<double>> get polyline => [
        for (final s in stops) [s.lat, s.lng],
      ];
}

/// Ergebnis einer Interpolation entlang einer Route.
class RoutePoint {
  final double lat;
  final double lng;
  final double bearing;
  final String nextStopName;
  final double progress;

  const RoutePoint(this.lat, this.lng, this.bearing, this.nextStopName, this.progress);
}

/// Liefert Fahrzeug-Positionen und Abfahrten für den Demo-Betrieb.
class MockFeed {
  static const _fullTraversalSeconds = 480.0;

  final List<FeedRoute> routes = _buildRoutes();

  /// Positionen aller Fahrzeuge zum Zeitpunkt [now].
  List<Map<String, dynamic>> vehiclesAt(DateTime now) {
    final elapsed = now.millisecondsSinceEpoch / 1000.0;
    return [
      for (final route in routes)
        _vehicleJson(route, elapsed),
    ];
  }

  Map<String, dynamic> _vehicleJson(FeedRoute route, double elapsed) {
    final t = (elapsed / _fullTraversalSeconds + route.phase) % 1.0;
    final p = _pointAt(route, t);
    return {
      'vehicleId': route.vehicleId,
      'tripId': route.tripId,
      'line': route.line,
      'mode': route.mode,
      'lat': p.lat,
      'lng': p.lng,
      'bearing': p.bearing,
      'speedKmh': route.speedKmh,
      'lastGpsReport': DateTime.now().toIso8601String(),
      'occupancy': route.occupancy,
      'nextStopName': p.nextStopName,
      'delayMinutes': (route.vehicleId.hashCode.abs() % 3),
      'routePolyline': route.polyline,
      'progressFraction': p.progress,
    };
  }

  /// Interpoliert entlang der Stops anhand des Fortschritts [t] (0..1).
  RoutePoint _pointAt(FeedRoute route, double t) {
    final stops = route.stops;
    if (stops.isEmpty) {
      return const RoutePoint(59.3293, 18.0686, 0, '', 0);
    }
    if (stops.length == 1) {
      return RoutePoint(stops[0].lat, stops[0].lng, 0, stops[0].name, t);
    }

    final segLen = <double>[];
    var total = 0.0;
    for (var i = 0; i < stops.length - 1; i++) {
      final d = _distance(stops[i], stops[i + 1]);
      segLen.add(d);
      total += d;
    }
    if (total == 0) {
      return RoutePoint(stops[0].lat, stops[0].lng, 0, stops[1].name, t);
    }

    var target = (t * total).clamp(0.0, total);
    for (var i = 0; i < segLen.length; i++) {
      final next = i == segLen.length - 1 || target <= segLen[i];
      if (next) {
        final f = segLen[i] == 0 ? 0.0 : target / segLen[i];
        final a = stops[i];
        final b = stops[i + 1];
        final lat = a.lat + (b.lat - a.lat) * f;
        final lng = a.lng + (b.lng - a.lng) * f;
        final bearingRad = math.atan2(
          (b.lng - a.lng) * math.cos(a.lat * math.pi / 180),
          b.lat - a.lat,
        );
        final bearing = (bearingRad * 180 / math.pi + 360) % 360;
        return RoutePoint(lat, lng, bearing, b.name, t);
      }
      target -= segLen[i];
    }
    final last = stops[stops.length - 1];
    return RoutePoint(last.lat, last.lng, 0, last.name, t);
  }

  static double _distance(RouteStop a, RouteStop b) {
    final dLat = (b.lat - a.lat) * 111320.0;
    final dLng = (b.lng - a.lng) * 111320.0 * math.cos(a.lat * math.pi / 180);
    return math.sqrt(dLat * dLat + dLng * dLng);
  }

  /// Abfahrten für eine Haltestelle. Deterministisch pro Stop + 2-Minuten-Bucket,
  /// damit sich die Liste im Testbetrieb fortlaufend verändert.
  List<Map<String, dynamic>> departuresFor(String stopId, DateTime now) {
    final profile = _profiles[stopId] ?? _genericProfile(stopId);
    final seed = (stopId.hashCode * 31) ^ ((now.minute ~/ 2) * 7);
    final rng = math.Random(seed);

    final count = 5 + rng.nextInt(4);
    final list = <Map<String, dynamic>>[];
    var offsetMinutes = 0;
    for (var i = 0; i < count; i++) {
      offsetMinutes += 1 + rng.nextInt(3);
      final roll = rng.nextDouble();
      final status = roll < 0.80
          ? 'onTime'
          : (roll < 0.95 ? 'delayed' : 'cancelled');
      final delaySeconds = status == 'delayed'
          ? 60 + rng.nextInt(240)
          : (status == 'cancelled' ? 0 : rng.nextInt(30));
      final scheduled = now.add(Duration(minutes: offsetMinutes));
      list.add({
        'id': '$stopId-$i-${now.minute}',
        'stopId': stopId,
        'line': profile.lines[rng.nextInt(profile.lines.length)],
        'destination':
            profile.destinations[rng.nextInt(profile.destinations.length)],
        'mode': profile.modes[rng.nextInt(profile.modes.length)],
        'scheduledTime': scheduled.toIso8601String(),
        'realtimeTime': scheduled.add(Duration(seconds: delaySeconds)).toIso8601String(),
        'delaySeconds': delaySeconds,
        'status': status,
        'track': rng.nextInt(2) == 0 ? '${1 + rng.nextInt(12)}' : '',
        'operatorName': profile.operator,
        'occupancy': _occupancies[rng.nextInt(_occupancies.length)],
        'hasWheelchairAccess': true,
        'hasBicycleAccess': rng.nextBool(),
        'hasWifi': rng.nextBool(),
      });
    }
    return list;
  }

  static const _occupancies = ['empty', 'manySeats', 'fewSeats', 'standingRoom', 'full'];

  static _StopProfile _genericProfile(String stopId) {
    final h = stopId.hashCode.abs();
    return _StopProfile(
      lines: ['Linje ${1 + h % 9}', 'Buss ${1 + h % 40}'],
      destinations: ['Okänt mål'],
      modes: ['bus', 'pendeltag'],
      operator: 'Okänd operatör',
    );
  }

  static _StopProfile _profile({
    required List<String> lines,
    required List<String> destinations,
    required List<String> modes,
    required String operator,
  }) =>
      _StopProfile(
        lines: lines,
        destinations: destinations,
        modes: modes,
        operator: operator,
      );

  static final Map<String, _StopProfile> _profiles = {
    '740000001': _profile(
      lines: ['14', '11', '43', 'T-Bana 17'],
      destinations: ['Mörby centrum', 'Fruängen', 'Södertälje C', 'Kungsträdgården'],
      modes: ['tunnelbana', 'pendeltag'],
      operator: 'SL / SJ',
    ),
    '740000002': _profile(
      lines: ['Spårvagn 4', 'Västtågen 3205', 'SJ 524'],
      destinations: ['Mölndal', 'Varberg', 'Stockholm C'],
      modes: ['tram', 'fjarrtag'],
      operator: 'Västtrafik / SJ',
    ),
    '740000003': _profile(
      lines: ['Pågatågen 30', 'Öresundståg 3', 'Buss X1'],
      destinations: ['Lund C', 'Köpenhamn H', 'Ystad'],
      modes: ['pendeltag', 'bus'],
      operator: 'Skånetrafiken',
    ),
    '740000004': _profile(
      lines: ['Mälartåg 912', 'Upptåget 6'],
      destinations: ['Stockholm C', 'Gävle C'],
      modes: ['fjarrtag', 'pendeltag'],
      operator: 'Mälartåg / SJ',
    ),
    '740000005': _profile(
      lines: ['T-Bana 18', 'Buss 401'],
      destinations: ['Alvik', 'Nacka'],
      modes: ['tunnelbana', 'bus'],
      operator: 'SL',
    ),
    '740000006': _profile(
      lines: ['14', '11', 'Buss 507'],
      destinations: ['Mörby centrum', 'T-Centralen', 'Södermalm'],
      modes: ['tunnelbana', 'bus'],
      operator: 'SL',
    ),
    '740000007': _profile(
      lines: ['Spårvagn 1', 'Spårvagn 5'],
      destinations: ['Göteborg C', 'Linnéplatsen'],
      modes: ['tram'],
      operator: 'Västtrafik',
    ),
    '740000008': _profile(
      lines: ['Buss 16', 'Buss 27'],
      destinations: ['Göteborg C', 'Särö'],
      modes: ['bus'],
      operator: 'Västtrafik',
    ),
    '740000009': _profile(
      lines: ['Pågatågen 30', 'Öresundståg 3'],
      destinations: ['Malmö C', 'Helsingborg C'],
      modes: ['pendeltag'],
      operator: 'Skånetrafiken',
    ),
    '740000010': _profile(
      lines: ['SJ 71', 'Värmlandstrafik 40'],
      destinations: ['Stockholm C', 'Oslo S'],
      modes: ['fjarrtag', 'pendeltag'],
      operator: 'SJ / Värmlandstrafik',
    ),
    '740000011': _profile(
      lines: ['SJ Nattåg 94', 'Buss 99'],
      destinations: ['Stockholm C', 'Abisko'],
      modes: ['fjarrtag', 'bus'],
      operator: 'SJ / Länstrafiken',
    ),
    '740000012': _profile(
      lines: ['Arlanda Express', 'Buss 801'],
      destinations: ['Stockholm C', 'Märsta'],
      modes: ['fjarrtag', 'bus'],
      operator: 'Arlanda Express / SL',
    ),
  };

  static List<FeedRoute> _buildRoutes() => [
        const FeedRoute(
          vehicleId: 'TUB-14-01',
          tripId: 'T-14-1',
          line: '14',
          mode: 'tunnelbana',
          speedKmh: 70,
          stops: [
            RouteStop(59.3312, 18.0594, 'T-Centralen'),
            RouteStop(59.3355, 18.0628, 'Hötorget'),
            RouteStop(59.3429, 18.0498, 'Odenplan'),
            RouteStop(59.3520, 18.0650, 'Tekniska högskolan'),
            RouteStop(59.3700, 18.0700, 'Universitetet'),
            RouteStop(59.3980, 18.0350, 'Mörby centrum'),
          ],
        ),
        const FeedRoute(
          vehicleId: 'PEND-43-02',
          tripId: 'P-43-2',
          line: '43',
          mode: 'pendeltag',
          speedKmh: 110,
          phase: 0.3,
          stops: [
            RouteStop(59.3312, 18.0594, 'Stockholm C'),
            RouteStop(59.1980, 17.6270, 'Södertälje Syd'),
            RouteStop(58.9850, 16.2050, 'Katrineholm C'),
            RouteStop(58.4109, 15.6216, 'Linköping C'),
            RouteStop(57.7089, 11.9731, 'Göteborg C'),
          ],
        ),
        const FeedRoute(
          vehicleId: 'SJ-524-03',
          tripId: 'SJ-524-3',
          line: 'SJ 524',
          mode: 'fjarrtag',
          speedKmh: 160,
          phase: 0.55,
          stops: [
            RouteStop(59.3312, 18.0594, 'Stockholm C'),
            RouteStop(58.4109, 15.6216, 'Linköping C'),
            RouteStop(57.7089, 11.9731, 'Göteborg C'),
          ],
        ),
        const FeedRoute(
          vehicleId: 'TRAM-GB4-04',
          tripId: 'GB-4-4',
          line: 'Spårvagn 4',
          mode: 'tram',
          speedKmh: 40,
          phase: 0.1,
          stops: [
            RouteStop(57.7089, 11.9731, 'Göteborg C'),
            RouteStop(57.7069, 11.9698, 'Brunnsparken'),
            RouteStop(57.6957, 11.9891, 'Korsvägen'),
          ],
        ),
        const FeedRoute(
          vehicleId: 'PAGA-30-05',
          tripId: 'P-30-5',
          line: 'Pågatågen 30',
          mode: 'pendeltag',
          speedKmh: 120,
          phase: 0.4,
          stops: [
            RouteStop(55.6090, 13.0008, 'Malmö C'),
            RouteStop(55.7028, 13.1928, 'Lund C'),
            RouteStop(55.8730, 12.8300, 'Landskrona'),
          ],
        ),
        const FeedRoute(
          vehicleId: 'MALART-912-06',
          tripId: 'M-912-6',
          line: 'Mälartåg 912',
          mode: 'fjarrtag',
          speedKmh: 150,
          phase: 0.7,
          stops: [
            RouteStop(59.8586, 17.6389, 'Uppsala C'),
            RouteStop(59.6490, 17.9350, 'Knivsta'),
            RouteStop(59.3312, 18.0594, 'Stockholm C'),
          ],
        ),
        const FeedRoute(
          vehicleId: 'BUS-54-07',
          tripId: 'B-54-7',
          line: '54',
          mode: 'bus',
          speedKmh: 35,
          phase: 0.2,
          stops: [
            RouteStop(59.3312, 18.0594, 'T-Centralen'),
            RouteStop(59.3205, 18.0730, 'Slussen'),
            RouteStop(59.3123, 18.0815, 'Medborgarplatsen'),
          ],
        ),
        const FeedRoute(
          vehicleId: 'BUS-X1-08',
          tripId: 'X1-8',
          line: 'Buss X1',
          mode: 'bus',
          speedKmh: 45,
          phase: 0.6,
          stops: [
            RouteStop(55.6090, 13.0008, 'Malmö C'),
            RouteStop(55.6049, 12.9868, 'Triangeln'),
            RouteStop(55.5800, 13.0200, 'Hyllie'),
          ],
        ),
        const FeedRoute(
          vehicleId: 'ALV-01-09',
          tripId: 'ALV-9',
          line: 'Älvsnabben',
          mode: 'ferry',
          speedKmh: 25,
          phase: 0.8,
          stops: [
            RouteStop(57.7089, 11.9731, 'Göteborg C'),
            RouteStop(57.6900, 11.9000, 'Lindholmen'),
            RouteStop(57.7000, 11.9300, 'Stenpiren'),
          ],
        ),
        const FeedRoute(
          vehicleId: 'NATTAG-94-10',
          tripId: 'N-94-10',
          line: 'SJ Nattåg 94',
          mode: 'fjarrtag',
          speedKmh: 130,
          phase: 0.15,
          stops: [
            RouteStop(59.3312, 18.0594, 'Stockholm C'),
            RouteStop(59.8586, 17.6389, 'Uppsala C'),
            RouteStop(63.8258, 20.2630, 'Umeå C'),
            RouteStop(67.8558, 20.2253, 'Kiruna'),
          ],
        ),
      ];
}

class _StopProfile {
  final List<String> lines;
  final List<String> destinations;
  final List<String> modes;
  final String operator;

  const _StopProfile({
    required this.lines,
    required this.destinations,
    required this.modes,
    required this.operator,
  });
}