import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/train_composition_model.dart';
import '../models/traffic_cam_model.dart';
import 'app_settings_service.dart';

/// Service für Trafikverket Open API (api.trafikinfo.trafikverket.se).
/// Bietet echte Live-Daten für Verkehrskameras, Zugkomposition und Störungen.
class TrafikverketService {
  static const String _baseUrl = 'https://api.trafikinfo.trafikverket.se/v2/data.json';

  /// Fetches live train composition & delay reasons from Trafiklab Trip Details API
  /// 
  /// API: https://realtime-api.trafiklab.se/v1/trips/{tripId}/{date}
  /// Liefert echte Zugkomposition, Verspätungsursachen und Auslastungsdaten.
  static Future<TrainComposition?> getTrainComposition(String tripId, {String? date}) async {
    final settings = await AppSettingsService.getInstance();
    final apiKey = settings.getKey('TRAFIKLAB_API_KEY');
    
    if (apiKey.isEmpty) {
      throw Exception(
        'TRAFIKLAB_API_KEY nicht gesetzt. '
        'Starte mit: --dart-define=TRAFIKLAB_API_KEY=<key>',
      );
    }
    
    final actualDate = date ?? DateTime.now().toIso8601String().split('T')[0];
    final url = Uri.parse(
      'https://realtime-api.trafiklab.se/v1/trips/$tripId/$actualDate',
    );
    
    final response = await http.Client().get(
      url,
      headers: {'apikey': apiKey},
    ).timeout(const Duration(seconds: 15));
    
    if (response.statusCode == 404) {
      // Keine Kompositionsdaten für diesen Trip verfügbar
      return null;
    }
    
    if (response.statusCode != 200) {
      throw Exception(
        'Trip Details API Fehler: HTTP ${response.statusCode} - ${response.body}',
      );
    }
    
    final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseTripDetails(jsonData);
  }
  
  static TrainComposition _parseTripDetails(Map<String, dynamic> data) {
    final tripInfo = data['Trip'] as Map<String, dynamic>? ?? {};
    final trainNumber = tripInfo['TrainNumber'] as String? ?? 'Unbekannt';
    final operatorName = tripInfo['Operator'] as String? ?? '';
    final trainType = tripInfo['TrainType'] as String? ?? '';
    
    // Verspätungsursache extrahieren
    String? delayReason;
    final delays = tripInfo['Delays'] as Map<String, dynamic>?;
    if (delays != null) {
      final causeCode = delays['CauseCode'] as String?;
      final causeDescription = delays['CauseDescription'] as String?;
      if (causeDescription != null && causeDescription.isNotEmpty) {
        delayReason = causeDescription;
      } else if (causeCode != null) {
        delayReason = 'Ursachen-Code: $causeCode';
      }
    }
    delayReason ??= 'Normal drift';
    
    // Wagenreihung parsen
    final wagons = <WagonUnit>[];
    final cars = tripInfo['Cars'] as List<dynamic>?;
    if (cars != null) {
      for (int i = 0; i < cars.length; i++) {
        final car = cars[i] as Map<String, dynamic>;
        final carriageNumber = (car['CarNumber'] as int?) ?? (i + 1);
        final classType = car['ClassType'] as String? ?? 'Standard';
        final hasWheelchairRamp = car['HasWheelchairAccess'] as bool? ?? false;
        final hasBicycleSpace = car['HasBicycleSpace'] as bool? ?? false;
        final hasPowerSockets = car['HasPowerSockets'] as bool? ?? false;
        final isQuietZone = car['IsQuietZone'] as bool? ?? false;
        final seatingCapacity = (car['Seats'] as int?) ?? 0;
        
        // Auslastung falls verfügbar (einige Betreiber liefern das)
        int currentOccupancyPct = 0;
        final occupancy = car['Occupancy'] as Map<String, dynamic>?;
        if (occupancy != null) {
          currentOccupancyPct = (occupancy['Percentage'] as int?) ?? 0;
        }
        
        wagons.add(WagonUnit(
          carriageNumber: carriageNumber,
          classType: classType,
          hasWheelchairRamp: hasWheelchairRamp,
          hasBicycleSpace: hasBicycleSpace,
          hasPowerSockets: hasPowerSockets,
          isQuietZone: isQuietZone,
          seatingCapacity: seatingCapacity,
          currentOccupancyPct: currentOccupancyPct,
        ));
      }
    }
    
    // Fallback wenn keine Wagondaten vorhanden
    if (wagons.isEmpty) {
      wagons.add(WagonUnit(
        carriageNumber: 1,
        classType: 'Standard',
        hasWheelchairRamp: false,
        hasBicycleSpace: false,
        hasPowerSockets: false,
        isQuietZone: false,
        seatingCapacity: 0,
        currentOccupancyPct: 0,
      ));
    }
    
    return TrainComposition(
      trainNumber: trainNumber,
      trainType: trainType,
      operatorName: operatorName,
      delayReason: delayReason,
      wagons: wagons,
    );
  }

  /// Fetches Trafikverket live traffic cameras and bridge opening alerts
  /// aus der echten Trafikverket Open API statt statischer Mock-Daten.
  /// 
  /// API-Dokumentation: https://api.trafikinfo.trafikverket.se/
  /// Objecttype: Camera (für Kamerabilder), Situation (für Brückenöffnungen)
  static Future<List<TrafikverketCam>> fetchTrafficCameras() async {
    final settings = await AppSettingsService.getInstance();
    final apiKey = settings.getKey('TRAFIKVERKET_API_KEY');

    if (apiKey.isEmpty) {
      throw Exception(
        'TRAFIKVERKET_API_KEY nicht gesetzt in Settings / .env',
      );
    }

    // XML-Query für Camera-Objekte mit Position und Bild-URL
    final cameraQuery = '''
      <QUERY OBJECTTYPE="Camera">
        <FILTER>
          <EQ NAME="Status" VALUE="Active"/>
        </FILTER>
        <ORDER>
          <COLUMN NAME="Name"/>
        </ORDER>
      </QUERY>
    ''';

    // XML-Query für Situation-Objekte (Brückenöffnungen, Sperrungen)
    final situationQuery = '''
      <QUERY OBJECTTYPE="Situation">
        <FILTER>
          <EQ NAME="Status" VALUE="Active"/>
        </FILTER>
        <ORDER>
          <COLUMN NAME="StartTime"/>
        </ORDER>
      </QUERY>
    ''';

    // Parallele Abfrage von Kameras und Situationen
    final cameraResponseFuture = http.Client().post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/xml',
        'Authorization': 'Bearer $apiKey',
      },
      body: cameraQuery,
    ).timeout(const Duration(seconds: 15));

    final situationResponseFuture = http.Client().post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/xml',
        'Authorization': 'Bearer $apiKey',
      },
      body: situationQuery,
    ).timeout(const Duration(seconds: 15));

    final responses = await Future.wait([cameraResponseFuture, situationResponseFuture]);
    final cameraResponse = responses[0];
    final situationResponse = responses[1];

    if (cameraResponse.statusCode != 200) {
      throw Exception(
        'Trafikverket Camera API Fehler: HTTP ${cameraResponse.statusCode} - ${cameraResponse.body}',
      );
    }

    if (situationResponse.statusCode != 200) {
      throw Exception(
        'Trafikverket Situation API Fehler: HTTP ${situationResponse.statusCode} - ${situationResponse.body}',
      );
    }

    // Response ist JSON mit Camera-Array
    final cameraJsonData = jsonDecode(cameraResponse.body) as Map<String, dynamic>;
    final cameraDataList = cameraJsonData['Response']?['Cameras'] as List<dynamic>? ?? [];

    // Parse Situations für Brückenöffnungen
    final situationJsonData = jsonDecode(situationResponse.body) as Map<String, dynamic>;
    final situationDataList = situationJsonData['Response']?['Situations'] as List<dynamic>? ?? [];
    
    // Extrahiere Brücken-IDs aus aktiven Situationen
    final activeBridgeIds = <String>{};
    for (final sitJson in situationDataList) {
      final sit = sitJson as Map<String, dynamic>;
      final type = sit['Type'] as String? ?? '';
      final description = sit['Description'] as String? ?? '';
      
      // Prüfe auf Brückenöffnung oder ähnliche Ereignisse
      if (type.contains('Bridge') || 
          type.contains('bridge') ||
          description.toLowerCase().contains('bridge opening') ||
          description.toLowerCase().contains('brücke') ||
          description.toLowerCase().contains('broöppning')) {
        // Extrahiere betroffene Locations/IDs
        final affectedLocations = sit['AffectedLocations'] as List<dynamic>? ?? [];
        for (final loc in affectedLocations) {
          final locMap = loc as Map<String, dynamic>;
          final locationId = locMap['Id'] as String?;
          if (locationId != null) {
            activeBridgeIds.add(locationId);
          }
        }
      }
    }

    final cameras = <TrafikverketCam>[];
    for (final camJson in cameraDataList) {
      final cam = camJson as Map<String, dynamic>;
      
      // Extrahiere Position
      final position = cam['Position'] as Map<String, dynamic>?;
      final lat = (position?['WGS84Lat'] as num?)?.toDouble() ?? 0.0;
      final lng = (position?['WGS84Lon'] as num?)?.toDouble() ?? 0.0;

      // Extrahiere Bild-URLs
      final media = cam['Media'] as List<dynamic>? ?? [];
      String? imageUrl;
      if (media.isNotEmpty) {
        final firstMedia = media.first as Map<String, dynamic>?;
        imageUrl = firstMedia?['Url'] as String?;
      }

      // Statusbeschreibung
      final statusDesc = cam['Description'] as String? ?? 'Keine Informationen';
      final name = cam['Name'] as String? ?? 'Unbekannte Kamera';
      final locationName = cam['Location'] as String? ?? '';
      final roadName = cam['RoadName'] as String? ?? '';
      final camId = cam['Id'] as String? ?? 'CAM_${lat}_$lng';
      
      // Prüfe ob diese Kamera eine Brücke überwacht und ob diese gerade öffnet
      final isBridgeActive = activeBridgeIds.contains(camId) || 
                             roadName.toLowerCase().contains('bro') || // Schwedisch für Brücke
                             roadName.toLowerCase().contains('bridge');

      cameras.add(TrafikverketCam(
        id: camId,
        title: name,
        locationName: locationName,
        imageUrl: imageUrl ?? 'https://via.placeholder.com/600x400?text=No+Image',
        lat: lat,
        lng: lng,
        roadName: roadName,
        lastUpdated: DateTime.now(),
        isBridgeActive: isBridgeActive,
        statusDescription: statusDesc,
      ));
    }

    return cameras;
  }

  /// Legacy-Methode für Rückwärtskompatibilität.
  /// @deprecated Verwende [fetchTrafficCameras()] für echte Live-Daten.
  @Deprecated('Verwende fetchTrafficCameras() für echte API-Daten')
  static List<TrafikverketCam> getTrafficCameras() {
    // Fallback auf leere Liste - sollte nicht mehr verwendet werden
    return [];
  }
}
