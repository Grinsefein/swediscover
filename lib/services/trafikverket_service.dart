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
    final query = '''
      <QUERY OBJECTTYPE="Camera">
        <FILTER>
          <EQ NAME="Status" VALUE="Active"/>
        </FILTER>
        <ORDER>
          <COLUMN NAME="Name"/>
        </ORDER>
      </QUERY>
    ''';

    final response = await http.Client().post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/xml',
        'Authorization': 'Bearer $_apiKey',
      },
      body: query,
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'Trafikverket API Fehler: HTTP ${response.statusCode} - ${response.body}',
      );
    }

    // Response ist JSON mit Camera-Array
    final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
    final cameraDataList = jsonData['Response']?['Cameras'] as List<dynamic>? ?? [];

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
      
      // Brückenstatus: Aktuell hardcoded false, da dies über einen separaten
      // Situation-Objecttype abgefragt werden müsste.
      // TODO: Separate API-Anfrage für Situation-Objekte mit Bridge-Opening-Info
      final isBridgeActive = false;

      cameras.add(TrafikverketCam(
        id: cam['Id'] as String? ?? 'CAM_${lat}_$lng',
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
