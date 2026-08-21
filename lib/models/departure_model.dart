enum TransitMode {
  tunnelbana,
  pendeltag,
  fjarrtag,
  bus,
  tram,
  ferry,
}

enum OccupancyStatus {
  empty,
  manySeats,
  fewSeats,
  standingRoom,
  full,
}

enum DepartureStatus {
  onTime,
  delayed,
  cancelled,
  platformChange,
}

class TransitDeparture {
  final String id;
  final String stopId;
  final String line;
  final String destination;
  final TransitMode mode;
  final DateTime scheduledTime;
  final DateTime realtimeTime;
  final int delaySeconds;
  final DepartureStatus status;
  final String track;
  final String? originalTrack;
  final String operatorName;
  final OccupancyStatus occupancy;
  final bool hasWheelchairAccess;
  final bool hasBicycleAccess;
  final bool hasWifi;

  const TransitDeparture({
    required this.id,
    required this.stopId,
    required this.line,
    required this.destination,
    required this.mode,
    required this.scheduledTime,
    required this.realtimeTime,
    required this.delaySeconds,
    required this.status,
    required this.track,
    this.originalTrack,
    required this.operatorName,
    this.occupancy = OccupancyStatus.manySeats,
    this.hasWheelchairAccess = true,
    this.hasBicycleAccess = false,
    this.hasWifi = true,
  });

  factory TransitDeparture.fromJson(Map<String, dynamic> json) {
    final mode = TransitMode.values.asNameMap()[json['mode']] ?? TransitMode.bus;
    final status = DepartureStatus.values.asNameMap()[json['status']] ?? DepartureStatus.onTime;
    final occupancy = OccupancyStatus.values.asNameMap()[json['occupancy']] ?? OccupancyStatus.manySeats;

    return TransitDeparture(
      id: json['id'] as String,
      stopId: json['stopId'] as String,
      line: json['line'] as String,
      destination: json['destination'] as String,
      mode: mode,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      realtimeTime: DateTime.parse(json['realtimeTime'] as String),
      delaySeconds: (json['delaySeconds'] as num?)?.toInt() ?? 0,
      status: status,
      track: json['track'] as String? ?? '',
      originalTrack: json['originalTrack'] as String?,
      operatorName: json['operatorName'] as String? ?? '',
      occupancy: occupancy,
      hasWheelchairAccess: json['hasWheelchairAccess'] as bool? ?? true,
      hasBicycleAccess: json['hasBicycleAccess'] as bool? ?? false,
      hasWifi: json['hasWifi'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'stopId': stopId,
        'line': line,
        'destination': destination,
        'mode': mode.name,
        'scheduledTime': scheduledTime.toIso8601String(),
        'realtimeTime': realtimeTime.toIso8601String(),
        'delaySeconds': delaySeconds,
        'status': status.name,
        'track': track,
        'originalTrack': originalTrack,
        'operatorName': operatorName,
        'occupancy': occupancy.name,
        'hasWheelchairAccess': hasWheelchairAccess,
        'hasBicycleAccess': hasBicycleAccess,
        'hasWifi': hasWifi,
      };

  int get delayMinutes => (delaySeconds / 60).round();

  String get formattedDelay {
    if (status == DepartureStatus.cancelled) return 'Inställt';
    if (delayMinutes == 0) return 'I tid';
    if (delayMinutes > 0) return '+$delayMinutes min';
    return '$delayMinutes min';
  }
}
