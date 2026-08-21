import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/train_composition_model.dart';
import '../models/traffic_cam_model.dart';
import 'api_exception.dart';
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
      throw ApiException.missingKey('TRAFIKLAB_API_KEY');
    }

    final actualDate = date ?? DateTime.now().toIso8601String().split('T')[0];
    // Trafiklab realtime APIs authentifizieren per Query-Param 'key'.
    final url = Uri.parse(
      'https://realtime-api.trafiklab.se/v1/trips/$tripId/$actualDate?key=$apiKey',
    );

    final response = await http.Client()
        .get(url)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 404) {
      // Keine Kompositionsdaten für diesen Trip verfügbar
      return null;
    }

    if (response.statusCode != 200) {
      throw ApiException.http(
        response.statusCode,
        'Trip Details API',
        bodySnippet: response.body,
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
  /// Auf Android-Geräten schlägt der direkte HTTPS-Call gelegentlich mit
  /// `CERTIFICATE_VERIFY_FAILED` fehl. In dem Fall wird automatisch einmal
  /// über den Go-BFF (`/api/cameras`) geladen, bevor ein Fehler angezeigt wird.
  ///
  /// API-Dokumentation: https://api.trafikinfo.trafikverket.se/
  /// Objecttype: Camera (für Kamerabilder), Situation (für Brückenöffnungen)
  static Future<List<TrafikverketCam>> fetchTrafficCameras() async {
    Object? directError;
    try {
      return await _fetchCamerasDirect();
    } on ApiException catch (e) {
      // Missing key / 401 (demo-key) / TLS – der BFF hat seinen eigenen
      // Server-seitigen Key, also lohnt der Fallback in allen Fällen.
      directError = e;
    } on HandshakeException catch (e) {
      directError = e;
    } on SocketException catch (e) {
      directError = e;
    } on TimeoutException catch (e) {
      directError = e;
    }

    // Direkter Aufruf fehlgeschlagen → einmal über den Go-BFF versuchen.
    try {
      return await _fetchCamerasViaBff();
    } catch (bffError) {
      final original = directError;
      if (original is ApiException) {
        throw ApiException(
          kind: original.kind,
          statusCode: original.statusCode,
          userMessage: '${original.userMessage} (Proxy-Fallback schlug ebenfalls fehl.)',
          technicalDetail: 'direct: ${original.technicalDetail ?? original} | bff: $bffError',
        );
      }
      if (original is HandshakeException) {
        throw ApiException.tls('direct: $original | bff: $bffError');
      }
      throw ApiException.network('direct: $original | bff: $bffError');
    }
  }

  static Future<List<TrafikverketCam>> _fetchCamerasViaBff() async {
    final settings = await AppSettingsService.getInstance();
    final baseUrl = settings.bffServerUrl;

    final response = await http.Client()
        .get(Uri.parse('$baseUrl/api/cameras'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw ApiException.http(response.statusCode, 'BFF /api/cameras', bodySnippet: response.body);
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = json['cameras'] as List<dynamic>? ?? [];

    return list.whereType<Map<String, dynamic>>().map((cam) {
      final lastUpdatedRaw = cam['lastUpdated']?.toString();
      return TrafikverketCam(
        id: cam['id']?.toString() ?? 'CAM_BFF',
        title: cam['name']?.toString() ?? 'Unbekannte Kamera',
        locationName: cam['roadNumber']?.toString() ?? '',
        imageUrl: cam['imageUrl']?.toString() ?? 'https://via.placeholder.com/600x400?text=No+Image',
        lat: (num.tryParse('${cam['latitude']}') ?? 0).toDouble(),
        lng: (num.tryParse('${cam['longitude']}') ?? 0).toDouble(),
        roadName: cam['roadName']?.toString() ?? '',
        lastUpdated: DateTime.tryParse(lastUpdatedRaw ?? '') ?? DateTime.now(),
        isBridgeActive: cam['isBridgeActive'] as bool? ?? false,
        statusDescription: cam['statusDescription']?.toString() ?? 'Keine Informationen',
      );
    }).toList();
  }

  static Future<List<TrafikverketCam>> _fetchCamerasDirect() async {
    final settings = await AppSettingsService.getInstance();
    final apiKey = settings.getKey('TRAFIKVERKET_API_KEY');

    if (apiKey.isEmpty) {
      throw ApiException.missingKey('TRAFIKVERKET_API_KEY');
    }

    // Trafikverket Open API v2 (Doku): POST mit XML-Body
    // <REQUEST><LOGIN authenticationkey="…"/><QUERY objecttype="…" schemaversion="1">…
    // Der Key gehört in den LOGIN-Block, NICHT in einen Bearer-Header.
    String requestXml(String queryXml) => '''
<REQUEST>
  <LOGIN authenticationkey="$apiKey" />
  $queryXml
</REQUEST>''';

    // Camera-Objekte (aktiv) inkl. Foto-URL und Geometrie.
    final cameraQuery = '''
  <QUERY objecttype="Camera" schemaversion="1" limit="200">
    <FILTER>
      <EQ name="Active" value="true" />
    </FILTER>
  </QUERY>''';

    // Laufende Situationen (u.a. Brückenöffnungen) – nur zukünftige EndTime.
    final situationQuery = '''
  <QUERY objecttype="Situation" schemaversion="1" limit="100">
    <FILTER>
      <GT name="EndTime" value="\$now" />
    </FILTER>
  </QUERY>''';

    Future<http.Response> post(String body, {required Duration timeout}) =>
        http.Client().post(
          Uri.parse(_baseUrl),
          headers: {'Content-Type': 'application/xml'},
          body: body,
        ).timeout(timeout);

    final responses = await Future.wait([
      post(requestXml(cameraQuery), timeout: const Duration(seconds: 15)),
      post(requestXml(situationQuery), timeout: const Duration(seconds: 15)),
    ]);
    final cameraResponse = responses[0];
    final situationResponse = responses[1];

    if (cameraResponse.statusCode != 200) {
      throw ApiException.http(
        cameraResponse.statusCode,
        'Trafikverket Camera API',
        bodySnippet: cameraResponse.body,
      );
    }

    if (situationResponse.statusCode != 200) {
      debugPrint('Trafikverket Situation query failed (HTTP ${situationResponse.statusCode}) – proceeding without bridge info');
    }

    // Antwortstruktur: {"RESPONSE":{"RESULT":[{"Camera":[ … ]}]}}
    Map<String, dynamic>? responseOf(http.Response r) {
      try {
        final decoded = jsonDecode(r.body);
        if (decoded is! Map<String, dynamic>) return null;
        return decoded;
      } catch (_) {
        return null;
      }
    }

    List<Map<String, dynamic>> resultList(Map<String, dynamic>? json, String objectType) {
      final result =
          json?['RESPONSE']?['RESULT'] as List<dynamic>? ?? const [];
      for (final entry in result) {
        if (entry is Map<String, dynamic> && entry[objectType] is List<dynamic>) {
          return (entry[objectType] as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              .toList();
        }
      }
      return const [];
    }

    final cameraDataList = resultList(responseOf(cameraResponse), 'Camera');
    final situationDataList = situationResponse.statusCode == 200
        ? resultList(responseOf(situationResponse), 'Situation')
        : const <Map<String, dynamic>>[];

    if (cameraDataList.isEmpty) {
      throw const ApiException(
        kind: ApiExceptionKind.noData,
        userMessage: 'Inga trafikkameror returnedes från Trafikverket.',
      );
    }
    
    // Laufende Situationen auf brückenrelevante Ereignisse prüfen
    // (Broöppning/Bridge opening). TV-Situationen sind stark verschachtelt –
    // wir suchen tolerant im serialisierten Objekt.
    final hasBridgeSituation = situationDataList.any((sit) {
      final text = jsonEncode(sit).toLowerCase();
      return text.contains('broöppning') ||
          text.contains('broklaff') ||
          text.contains('bridge opening') ||
          text.contains('bridge opens');
    });

    final cameras = <TrafikverketCam>[];
    for (final camJson in cameraDataList) {
      final cam = camJson;

      // Foto-URL: je nach Schema "PhotoUrl" (Liste/String) oder "Photo".
      String? imageUrl;
      final photoUrlRaw = cam['PhotoUrl'];
      if (photoUrlRaw is List<dynamic> && photoUrlRaw.isNotEmpty) {
        imageUrl = photoUrlRaw.first?.toString();
      } else if (photoUrlRaw is String && photoUrlRaw.isNotEmpty) {
        imageUrl = photoUrlRaw;
      } else {
        final photoList = cam['Photo'] as List<dynamic>? ?? const [];
        if (photoList.isNotEmpty && photoList.first is Map<String, dynamic>) {
          final p = photoList.first as Map<String, dynamic>;
          imageUrl = p['URL']?.toString() ?? p['Url']?.toString();
        }
      }

      // Geometrie: WKT "POINT (<lon> <lat>)" in Geometry.WGS84, alternativ
      // numerische Positionsfelder.
      double lat = 0;
      double lng = 0;
      final wgs84 = cam['Geometry']?['WGS84']?.toString() ??
          cam['LocationGeometry']?['WGS84']?.toString();
      final wktMatch =
          wgs84 != null ? RegExp(r'POINT\s*\(\s*([-\d.]+)\s+([-\d.]+)\s*\)', caseSensitive: false).firstMatch(wgs84) : null;
      if (wktMatch != null) {
        lng = double.tryParse(wktMatch.group(1)!) ?? 0;
        lat = double.tryParse(wktMatch.group(2)!) ?? 0;
      } else {
        final position = cam['Position'] as Map<String, dynamic>?;
        lat = (position?['WGS84Lat'] as num?)?.toDouble() ?? 0;
        lng = (position?['WGS84Lon'] as num?)?.toDouble() ?? 0;
      }

      final name = cam['Name']?.toString() ?? 'Okänd kamera';
      final adress = cam['Adress']?.toString() ?? '';
      final roadName = cam['RoadNumber']?.toString() ?? '';
      final camId = cam['Id']?.toString() ?? 'CAM_${lat}_$lng';
      final photoTime = cam['PhotoTime']?.toString() ??
          cam['ModifiedTime']?.toString() ?? '';

      final nameAndAdress = '$name $adress'.toLowerCase();
      final isBridgeActive = hasBridgeSituation &&
          (nameAndAdress.contains('bro') || nameAndAdress.contains('bridge'));

      cameras.add(TrafikverketCam(
        id: camId,
        title: name,
        locationName: adress,
        imageUrl: imageUrl ?? 'https://via.placeholder.com/600x400?text=No+Image',
        lat: lat,
        lng: lng,
        roadName: roadName,
        lastUpdated: DateTime.tryParse(photoTime) ?? DateTime.now(),
        isBridgeActive: isBridgeActive,
        statusDescription: cam['Description']?.toString() ?? 'Keine Informationen',
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
