class TransitStop {
  final String id;
  final String name;
  final String city;
  final String rikshallplatsId;
  final String rikshallplatsName;
  final double lat;
  final double lng;
  final List<String> platforms;
  final String operatorName;
  final List<String> availableModes; // tunnelbana, pendeltag, train, bus, tram, ferry
  final int dailyPassengers;

  const TransitStop({
    required this.id,
    required this.name,
    required this.city,
    required this.rikshallplatsId,
    required this.rikshallplatsName,
    required this.lat,
    required this.lng,
    required this.platforms,
    required this.operatorName,
    required this.availableModes,
    this.dailyPassengers = 15000,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'city': city,
        'rikshallplatsId': rikshallplatsId,
        'rikshallplatsName': rikshallplatsName,
        'lat': lat,
        'lng': lng,
        'platforms': platforms.join(','),
        'operatorName': operatorName,
        'availableModes': availableModes.join(','),
        'dailyPassengers': dailyPassengers,
      };

  factory TransitStop.fromMap(Map<String, dynamic> map) => TransitStop(
        id: map['id'],
        name: map['name'],
        city: map['city'],
        rikshallplatsId: map['rikshallplatsId'],
        rikshallplatsName: map['rikshallplatsName'],
        lat: (map['lat'] as num).toDouble(),
        lng: (map['lng'] as num).toDouble(),
        platforms: (map['platforms'] as String).split(','),
        operatorName: map['operatorName'],
        availableModes: (map['availableModes'] as String).split(','),
        dailyPassengers: map['dailyPassengers'] ?? 10000,
      );
}
