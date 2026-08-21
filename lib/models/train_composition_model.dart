class WagonUnit {
  final int carriageNumber;
  final String classType; // 1a klass, 2a klass, Bistro, Tyst avdelning
  final bool hasWheelchairRamp;
  final bool hasBicycleSpace;
  final bool hasPowerSockets;
  final bool isQuietZone;
  final int seatingCapacity;
  final int currentOccupancyPct;

  const WagonUnit({
    required this.carriageNumber,
    required this.classType,
    required this.hasWheelchairRamp,
    required this.hasBicycleSpace,
    required this.hasPowerSockets,
    required this.isQuietZone,
    required this.seatingCapacity,
    required this.currentOccupancyPct,
  });
}

class TrainComposition {
  final String trainNumber;
  final String trainType; // SJ X2000, Mälartåg ER1, Snälltåget, SL Pendeltåg X60
  final String operatorName;
  final String delayReason;
  final List<WagonUnit> wagons;
  final bool isPetFriendly;

  const TrainComposition({
    required this.trainNumber,
    required this.trainType,
    required this.operatorName,
    required this.delayReason,
    required this.wagons,
    this.isPetFriendly = true,
  });
}
