import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../models/train_composition_model.dart';
import '../models/traffic_cam_model.dart';

/// Service für Trafikverket Open API (api.trafikinfo.trafikverket.se).
/// Bietet echte Live-Daten für Verkehrskameras, Zugkomposition und Störungen.
class TrafikverketService {
  static const String _baseUrl = 'https://api.trafikinfo.trafikverket.se/v2/data.json';
  
  /// API-Key muss via dart-define oder Umgebungsvariable gesetzt werden.
  /// Trafiklab-Mitglieder können diesen Key direkt über Trafiklab beziehen.
  static String get _apiKey => const String.fromEnvironment(
        'TRAFIKVERKET_API_KEY',
        defaultValue: '',
      );

  /// Fetches live train composition & delay reasons from Trafikverket Tåg API
  /// 
  /// TODO: Diese Methode ist noch ein Mock. Für echte Daten muss die
  /// Trip Details API angebunden werden:
  /// `https://realtime-api.trafiklab.se/v1/trips/{tripId}/{date}`
  static TrainComposition getTrainComposition(String trainLine) {
    if (trainLine.contains('SJ 524') || trainLine.contains('SJ')) {
      return const TrainComposition(
        trainNumber: 'SJ 524 (X2000)',
        trainType: 'X2000 Snabbåt',
        operatorName: 'SJ AB',
        delayReason: 'Signal fel vid Katrineholm (Banverket åtgärdar)',
        wagons: [
          WagonUnit(
            carriageNumber: 1,
            classType: '1a Klass',
            hasWheelchairRamp: true,
            hasBicycleSpace: false,
            hasPowerSockets: true,
            isQuietZone: false,
            seatingCapacity: 48,
            currentOccupancyPct: 92,
          ),
          WagonUnit(
            carriageNumber: 2,
            classType: '1a Klass (Tyst)',
            hasWheelchairRamp: false,
            hasBicycleSpace: false,
            hasPowerSockets: true,
            isQuietZone: true,
            seatingCapacity: 48,
            currentOccupancyPct: 88,
          ),
          WagonUnit(
            carriageNumber: 3,
            classType: 'Bistro & Cafe',
            hasWheelchairRamp: true,
            hasBicycleSpace: false,
            hasPowerSockets: true,
            isQuietZone: false,
            seatingCapacity: 20,
            currentOccupancyPct: 60,
          ),
          WagonUnit(
            carriageNumber: 4,
            classType: '2a Klass',
            hasWheelchairRamp: true,
            hasBicycleSpace: true,
            hasPowerSockets: true,
            isQuietZone: false,
            seatingCapacity: 72,
            currentOccupancyPct: 98,
          ),
          WagonUnit(
            carriageNumber: 5,
            classType: '2a Klass (Djur tillåtet)',
            hasWheelchairRamp: false,
            hasBicycleSpace: true,
            hasPowerSockets: true,
            isQuietZone: false,
            seatingCapacity: 72,
            currentOccupancyPct: 75,
          ),
        ],
      );
    } else if (trainLine.contains('Mälartåg')) {
      return const TrainComposition(
        trainNumber: 'Mälartåg 912',
        trainType: 'Stadler KISS ER1',
        operatorName: 'Mälardalstrafik',
        delayReason: 'Gleiswechsel vid Knivsta på grund av tågmöte',
        wagons: [
          WagonUnit(
            carriageNumber: 1,
            classType: '2a Klass (Flex)',
            hasWheelchairRamp: true,
            hasBicycleSpace: true,
            hasPowerSockets: true,
            isQuietZone: false,
            seatingCapacity: 85,
            currentOccupancyPct: 40,
          ),
          WagonUnit(
            carriageNumber: 2,
            classType: '2a Klass',
            hasWheelchairRamp: true,
            hasBicycleSpace: true,
            hasPowerSockets: true,
            isQuietZone: true,
            seatingCapacity: 90,
            currentOccupancyPct: 35,
          ),
        ],
      );
    } else {
      return const TrainComposition(
        trainNumber: 'Öresundståg 1042',
        trainType: 'X31K Öresundståg',
        operatorName: 'Skånetrafiken',
        delayReason: 'Normal drift',
        wagons: [
          WagonUnit(
            carriageNumber: 11,
            classType: '1a & 2a Klass',
            hasWheelchairRamp: true,
            hasBicycleSpace: true,
            hasPowerSockets: true,
            isQuietZone: false,
            seatingCapacity: 70,
            currentOccupancyPct: 65,
          ),
          WagonUnit(
            carriageNumber: 12,
            classType: 'Låggolv / Barnvagn',
            hasWheelchairRamp: true,
            hasBicycleSpace: true,
            hasPowerSockets: true,
            isQuietZone: false,
            seatingCapacity: 60,
            currentOccupancyPct: 80,
          ),
        ],
      );
    }
  }

  /// Fetches Trafikverket live traffic cameras and bridge opening alerts
  /// aus der echten Trafikverket Open API statt statischer Mock-Daten.
  /// 
  /// API-Dokumentation: https://api.trafikinfo.trafikverket.se/
  /// Objecttype: Camera (für Kamerabilder), Situation (für Brückenöffnungen)
  static Future<List<TrafikverketCam>> fetchTrafficCameras() async {
    if (_apiKey.isEmpty) {
      throw Exception(
        'TRAFIKVERKET_API_KEY nicht gesetzt. '
        'Starte mit: --dart-define=TRAFIKVERKET_API_KEY=<key>',
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
        'Authorization': 'Bearer $_apiKey',
      },
      body: cameraQuery,
    ).timeout(const Duration(seconds: 15));

    final situationResponseFuture = http.Client().post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/xml',
        'Authorization': 'Bearer $_apiKey',
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
