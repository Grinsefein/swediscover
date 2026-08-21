// This is a generated file - do not edit.
//
// Generated from gtfs_realtime.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class FeedHeader_Incrementality extends $pb.ProtobufEnum {
  static const FeedHeader_Incrementality FULL_DATASET =
      FeedHeader_Incrementality._(0, _omitEnumNames ? '' : 'FULL_DATASET');
  static const FeedHeader_Incrementality DIFFERENTIAL =
      FeedHeader_Incrementality._(1, _omitEnumNames ? '' : 'DIFFERENTIAL');

  static const $core.List<FeedHeader_Incrementality> values =
      <FeedHeader_Incrementality>[
    FULL_DATASET,
    DIFFERENTIAL,
  ];

  static final $core.List<FeedHeader_Incrementality?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static FeedHeader_Incrementality? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const FeedHeader_Incrementality._(super.value, super.name);
}

class VehiclePosition_VehicleStopStatus extends $pb.ProtobufEnum {
  static const VehiclePosition_VehicleStopStatus INCOMING_AT =
      VehiclePosition_VehicleStopStatus._(
          0, _omitEnumNames ? '' : 'INCOMING_AT');
  static const VehiclePosition_VehicleStopStatus STOPPED_AT =
      VehiclePosition_VehicleStopStatus._(
          1, _omitEnumNames ? '' : 'STOPPED_AT');
  static const VehiclePosition_VehicleStopStatus IN_TRANSIT_TO =
      VehiclePosition_VehicleStopStatus._(
          2, _omitEnumNames ? '' : 'IN_TRANSIT_TO');

  static const $core.List<VehiclePosition_VehicleStopStatus> values =
      <VehiclePosition_VehicleStopStatus>[
    INCOMING_AT,
    STOPPED_AT,
    IN_TRANSIT_TO,
  ];

  static final $core.List<VehiclePosition_VehicleStopStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static VehiclePosition_VehicleStopStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const VehiclePosition_VehicleStopStatus._(super.value, super.name);
}

class VehiclePosition_CongestionLevel extends $pb.ProtobufEnum {
  static const VehiclePosition_CongestionLevel UNKNOWN_CONGESTION_LEVEL =
      VehiclePosition_CongestionLevel._(
          0, _omitEnumNames ? '' : 'UNKNOWN_CONGESTION_LEVEL');
  static const VehiclePosition_CongestionLevel RUNNING_SMOOTHLY =
      VehiclePosition_CongestionLevel._(
          1, _omitEnumNames ? '' : 'RUNNING_SMOOTHLY');
  static const VehiclePosition_CongestionLevel STOP_AND_GO =
      VehiclePosition_CongestionLevel._(2, _omitEnumNames ? '' : 'STOP_AND_GO');
  static const VehiclePosition_CongestionLevel CONGESTION =
      VehiclePosition_CongestionLevel._(3, _omitEnumNames ? '' : 'CONGESTION');
  static const VehiclePosition_CongestionLevel SEVERE_CONGESTION =
      VehiclePosition_CongestionLevel._(
          4, _omitEnumNames ? '' : 'SEVERE_CONGESTION');

  static const $core.List<VehiclePosition_CongestionLevel> values =
      <VehiclePosition_CongestionLevel>[
    UNKNOWN_CONGESTION_LEVEL,
    RUNNING_SMOOTHLY,
    STOP_AND_GO,
    CONGESTION,
    SEVERE_CONGESTION,
  ];

  static final $core.List<VehiclePosition_CongestionLevel?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static VehiclePosition_CongestionLevel? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const VehiclePosition_CongestionLevel._(super.value, super.name);
}

class VehiclePosition_OccupancyStatus extends $pb.ProtobufEnum {
  static const VehiclePosition_OccupancyStatus EMPTY =
      VehiclePosition_OccupancyStatus._(0, _omitEnumNames ? '' : 'EMPTY');
  static const VehiclePosition_OccupancyStatus MANY_SEATS_AVAILABLE =
      VehiclePosition_OccupancyStatus._(
          1, _omitEnumNames ? '' : 'MANY_SEATS_AVAILABLE');
  static const VehiclePosition_OccupancyStatus FEW_SEATS_AVAILABLE =
      VehiclePosition_OccupancyStatus._(
          2, _omitEnumNames ? '' : 'FEW_SEATS_AVAILABLE');
  static const VehiclePosition_OccupancyStatus STANDING_ROOM_ONLY =
      VehiclePosition_OccupancyStatus._(
          3, _omitEnumNames ? '' : 'STANDING_ROOM_ONLY');
  static const VehiclePosition_OccupancyStatus CRUSHED_STANDING_ROOM_ONLY =
      VehiclePosition_OccupancyStatus._(
          4, _omitEnumNames ? '' : 'CRUSHED_STANDING_ROOM_ONLY');
  static const VehiclePosition_OccupancyStatus FULL =
      VehiclePosition_OccupancyStatus._(5, _omitEnumNames ? '' : 'FULL');
  static const VehiclePosition_OccupancyStatus NOT_ACCEPTING_PASSENGERS =
      VehiclePosition_OccupancyStatus._(
          6, _omitEnumNames ? '' : 'NOT_ACCEPTING_PASSENGERS');
  static const VehiclePosition_OccupancyStatus NO_DATA_AVAILABLE =
      VehiclePosition_OccupancyStatus._(
          7, _omitEnumNames ? '' : 'NO_DATA_AVAILABLE');

  static const $core.List<VehiclePosition_OccupancyStatus> values =
      <VehiclePosition_OccupancyStatus>[
    EMPTY,
    MANY_SEATS_AVAILABLE,
    FEW_SEATS_AVAILABLE,
    STANDING_ROOM_ONLY,
    CRUSHED_STANDING_ROOM_ONLY,
    FULL,
    NOT_ACCEPTING_PASSENGERS,
    NO_DATA_AVAILABLE,
  ];

  static final $core.List<VehiclePosition_OccupancyStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 7);
  static VehiclePosition_OccupancyStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const VehiclePosition_OccupancyStatus._(super.value, super.name);
}

class TripDescriptor_ScheduleRelationship extends $pb.ProtobufEnum {
  static const TripDescriptor_ScheduleRelationship SCHEDULED =
      TripDescriptor_ScheduleRelationship._(
          0, _omitEnumNames ? '' : 'SCHEDULED');
  static const TripDescriptor_ScheduleRelationship ADDED =
      TripDescriptor_ScheduleRelationship._(1, _omitEnumNames ? '' : 'ADDED');
  static const TripDescriptor_ScheduleRelationship UNSCHEDULED =
      TripDescriptor_ScheduleRelationship._(
          2, _omitEnumNames ? '' : 'UNSCHEDULED');
  static const TripDescriptor_ScheduleRelationship CANCELED =
      TripDescriptor_ScheduleRelationship._(
          3, _omitEnumNames ? '' : 'CANCELED');

  static const $core.List<TripDescriptor_ScheduleRelationship> values =
      <TripDescriptor_ScheduleRelationship>[
    SCHEDULED,
    ADDED,
    UNSCHEDULED,
    CANCELED,
  ];

  static final $core.List<TripDescriptor_ScheduleRelationship?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static TripDescriptor_ScheduleRelationship? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const TripDescriptor_ScheduleRelationship._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
