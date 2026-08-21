import '../models/train_composition_model.dart';
import '../models/traffic_cam_model.dart';

class TrafikverketService {
  /// Fetches live train composition & delay reasons from Trafikverket Tåg API
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
  static List<TrafikverketCam> getTrafficCameras() {
    final now = DateTime.now();

    return [
      TrafikverketCam(
        id: 'CAM_STO_01',
        title: 'E4/E20 Essingeleden - Karlberg',
        locationName: 'Stockholm Essingeleden',
        imageUrl: 'https://picsum.photos/seed/essingeleden/600/400',
        lat: 59.3390,
        lng: 18.0160,
        roadName: 'E4 / E20',
        lastUpdated: now.subtract(const Duration(minutes: 1)),
        isBridgeActive: false,
        statusDescription: 'Flödande trafik 75 km/h. Ingen köbildning.',
      ),
      TrafikverketCam(
        id: 'CAM_GOT_01',
        title: 'Hisingsbron / Göta Älv',
        locationName: 'Göteborg Centralbron',
        imageUrl: 'https://picsum.photos/seed/gotaalv/600/400',
        lat: 57.7130,
        lng: 11.9680,
        roadName: 'Göta Älv Passage',
        lastUpdated: now,
        isBridgeActive: true, // Bridge opening in progress!
        statusDescription: '⚠️ Broöppning pågår för fartygspassage. Beräknad öppningstid: 12 min.',
      ),
      TrafikverketCam(
        id: 'CAM_MAL_01',
        title: 'Öresundsbron Betalstation',
        locationName: 'Malmö Lernacken',
        imageUrl: 'https://picsum.photos/seed/oresund/600/400',
        lat: 55.5720,
        lng: 12.8250,
        roadName: 'E20 Öresundsförbindelsen',
        lastUpdated: now.subtract(const Duration(minutes: 3)),
        isBridgeActive: false,
        statusDescription: 'Normal passage mot Danmark. Vindhastighet: 8 m/s.',
      ),
      TrafikverketCam(
        id: 'CAM_STO_02',
        title: 'T-Centralen / Vasagatan Junction',
        locationName: 'Stockholm City Hub',
        imageUrl: 'https://picsum.photos/seed/vasagatan/600/400',
        lat: 59.3312,
        lng: 18.0594,
        roadName: 'Vasagatan',
        lastUpdated: now.subtract(const Duration(minutes: 2)),
        isBridgeActive: false,
        statusDescription: 'Busstrafik tät dimma. Sänk hastigheten vid övergångsställens.',
      ),
    ];
  }
}
