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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'gtfs_realtime.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'gtfs_realtime.pbenum.dart';

class FeedMessage extends $pb.GeneratedMessage {
  factory FeedMessage({
    FeedHeader? header,
    $core.Iterable<FeedEntity>? entity,
  }) {
    final result = create();
    if (header != null) result.header = header;
    if (entity != null) result.entity.addAll(entity);
    return result;
  }

  FeedMessage._();

  factory FeedMessage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FeedMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FeedMessage',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'transit_realtime'),
      createEmptyInstance: create)
    ..aOM<FeedHeader>(1, _omitFieldNames ? '' : 'header',
        subBuilder: FeedHeader.create)
    ..pPM<FeedEntity>(2, _omitFieldNames ? '' : 'entity',
        subBuilder: FeedEntity.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FeedMessage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FeedMessage copyWith(void Function(FeedMessage) updates) =>
      super.copyWith((message) => updates(message as FeedMessage))
          as FeedMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FeedMessage create() => FeedMessage._();
  @$core.override
  FeedMessage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FeedMessage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FeedMessage>(create);
  static FeedMessage? _defaultInstance;

  @$pb.TagNumber(1)
  FeedHeader get header => $_getN(0);
  @$pb.TagNumber(1)
  set header(FeedHeader value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeader() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeader() => $_clearField(1);
  @$pb.TagNumber(1)
  FeedHeader ensureHeader() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<FeedEntity> get entity => $_getList(1);
}

class FeedHeader extends $pb.GeneratedMessage {
  factory FeedHeader({
    $core.String? gtfsRealtimeVersion,
    FeedHeader_Incrementality? incrementality,
    $fixnum.Int64? timestamp,
  }) {
    final result = create();
    if (gtfsRealtimeVersion != null)
      result.gtfsRealtimeVersion = gtfsRealtimeVersion;
    if (incrementality != null) result.incrementality = incrementality;
    if (timestamp != null) result.timestamp = timestamp;
    return result;
  }

  FeedHeader._();

  factory FeedHeader.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FeedHeader.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FeedHeader',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'transit_realtime'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'gtfsRealtimeVersion')
    ..aE<FeedHeader_Incrementality>(2, _omitFieldNames ? '' : 'incrementality',
        enumValues: FeedHeader_Incrementality.values)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'timestamp', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FeedHeader clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FeedHeader copyWith(void Function(FeedHeader) updates) =>
      super.copyWith((message) => updates(message as FeedHeader)) as FeedHeader;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FeedHeader create() => FeedHeader._();
  @$core.override
  FeedHeader createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FeedHeader getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FeedHeader>(create);
  static FeedHeader? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get gtfsRealtimeVersion => $_getSZ(0);
  @$pb.TagNumber(1)
  set gtfsRealtimeVersion($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasGtfsRealtimeVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearGtfsRealtimeVersion() => $_clearField(1);

  @$pb.TagNumber(2)
  FeedHeader_Incrementality get incrementality => $_getN(1);
  @$pb.TagNumber(2)
  set incrementality(FeedHeader_Incrementality value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasIncrementality() => $_has(1);
  @$pb.TagNumber(2)
  void clearIncrementality() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get timestamp => $_getI64(2);
  @$pb.TagNumber(3)
  set timestamp($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTimestamp() => $_has(2);
  @$pb.TagNumber(3)
  void clearTimestamp() => $_clearField(3);
}

class FeedEntity extends $pb.GeneratedMessage {
  factory FeedEntity({
    $core.String? id,
    $core.bool? isDeleted,
    TripUpdate? tripUpdate,
    Alert? alert,
    VehiclePosition? vehicle,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (isDeleted != null) result.isDeleted = isDeleted;
    if (tripUpdate != null) result.tripUpdate = tripUpdate;
    if (alert != null) result.alert = alert;
    if (vehicle != null) result.vehicle = vehicle;
    return result;
  }

  FeedEntity._();

  factory FeedEntity.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FeedEntity.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FeedEntity',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'transit_realtime'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOB(2, _omitFieldNames ? '' : 'isDeleted')
    ..aOM<TripUpdate>(3, _omitFieldNames ? '' : 'tripUpdate',
        subBuilder: TripUpdate.create)
    ..aOM<Alert>(5, _omitFieldNames ? '' : 'alert', subBuilder: Alert.create)
    ..aOM<VehiclePosition>(8, _omitFieldNames ? '' : 'vehicle',
        subBuilder: VehiclePosition.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FeedEntity clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FeedEntity copyWith(void Function(FeedEntity) updates) =>
      super.copyWith((message) => updates(message as FeedEntity)) as FeedEntity;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FeedEntity create() => FeedEntity._();
  @$core.override
  FeedEntity createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FeedEntity getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FeedEntity>(create);
  static FeedEntity? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get isDeleted => $_getBF(1);
  @$pb.TagNumber(2)
  set isDeleted($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIsDeleted() => $_has(1);
  @$pb.TagNumber(2)
  void clearIsDeleted() => $_clearField(2);

  @$pb.TagNumber(3)
  TripUpdate get tripUpdate => $_getN(2);
  @$pb.TagNumber(3)
  set tripUpdate(TripUpdate value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasTripUpdate() => $_has(2);
  @$pb.TagNumber(3)
  void clearTripUpdate() => $_clearField(3);
  @$pb.TagNumber(3)
  TripUpdate ensureTripUpdate() => $_ensure(2);

  @$pb.TagNumber(5)
  Alert get alert => $_getN(3);
  @$pb.TagNumber(5)
  set alert(Alert value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasAlert() => $_has(3);
  @$pb.TagNumber(5)
  void clearAlert() => $_clearField(5);
  @$pb.TagNumber(5)
  Alert ensureAlert() => $_ensure(3);

  @$pb.TagNumber(8)
  VehiclePosition get vehicle => $_getN(4);
  @$pb.TagNumber(8)
  set vehicle(VehiclePosition value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasVehicle() => $_has(4);
  @$pb.TagNumber(8)
  void clearVehicle() => $_clearField(8);
  @$pb.TagNumber(8)
  VehiclePosition ensureVehicle() => $_ensure(4);
}

class TripUpdate extends $pb.GeneratedMessage {
  factory TripUpdate({
    TripDescriptor? trip,
    VehicleDescriptor? vehicle,
    $fixnum.Int64? timestamp,
    $core.int? delay,
  }) {
    final result = create();
    if (trip != null) result.trip = trip;
    if (vehicle != null) result.vehicle = vehicle;
    if (timestamp != null) result.timestamp = timestamp;
    if (delay != null) result.delay = delay;
    return result;
  }

  TripUpdate._();

  factory TripUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TripUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TripUpdate',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'transit_realtime'),
      createEmptyInstance: create)
    ..aOM<TripDescriptor>(1, _omitFieldNames ? '' : 'trip',
        subBuilder: TripDescriptor.create)
    ..aOM<VehicleDescriptor>(3, _omitFieldNames ? '' : 'vehicle',
        subBuilder: VehicleDescriptor.create)
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'timestamp', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aI(5, _omitFieldNames ? '' : 'delay')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TripUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TripUpdate copyWith(void Function(TripUpdate) updates) =>
      super.copyWith((message) => updates(message as TripUpdate)) as TripUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TripUpdate create() => TripUpdate._();
  @$core.override
  TripUpdate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TripUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TripUpdate>(create);
  static TripUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  TripDescriptor get trip => $_getN(0);
  @$pb.TagNumber(1)
  set trip(TripDescriptor value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTrip() => $_has(0);
  @$pb.TagNumber(1)
  void clearTrip() => $_clearField(1);
  @$pb.TagNumber(1)
  TripDescriptor ensureTrip() => $_ensure(0);

  @$pb.TagNumber(3)
  VehicleDescriptor get vehicle => $_getN(1);
  @$pb.TagNumber(3)
  set vehicle(VehicleDescriptor value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasVehicle() => $_has(1);
  @$pb.TagNumber(3)
  void clearVehicle() => $_clearField(3);
  @$pb.TagNumber(3)
  VehicleDescriptor ensureVehicle() => $_ensure(1);

  @$pb.TagNumber(4)
  $fixnum.Int64 get timestamp => $_getI64(2);
  @$pb.TagNumber(4)
  set timestamp($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(4)
  $core.bool hasTimestamp() => $_has(2);
  @$pb.TagNumber(4)
  void clearTimestamp() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get delay => $_getIZ(3);
  @$pb.TagNumber(5)
  set delay($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(5)
  $core.bool hasDelay() => $_has(3);
  @$pb.TagNumber(5)
  void clearDelay() => $_clearField(5);
}

class VehiclePosition extends $pb.GeneratedMessage {
  factory VehiclePosition({
    TripDescriptor? trip,
    Position? position,
    $core.int? currentStopSequence,
    $core.String? stopId,
    VehiclePosition_VehicleStopStatus? currentStatus,
    $fixnum.Int64? timestamp,
    VehiclePosition_CongestionLevel? congestionLevel,
    VehiclePosition_OccupancyStatus? occupancyStatus,
    $core.int? occupancyPercentage,
  }) {
    final result = create();
    if (trip != null) result.trip = trip;
    if (position != null) result.position = position;
    if (currentStopSequence != null)
      result.currentStopSequence = currentStopSequence;
    if (stopId != null) result.stopId = stopId;
    if (currentStatus != null) result.currentStatus = currentStatus;
    if (timestamp != null) result.timestamp = timestamp;
    if (congestionLevel != null) result.congestionLevel = congestionLevel;
    if (occupancyStatus != null) result.occupancyStatus = occupancyStatus;
    if (occupancyPercentage != null)
      result.occupancyPercentage = occupancyPercentage;
    return result;
  }

  VehiclePosition._();

  factory VehiclePosition.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory VehiclePosition.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VehiclePosition',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'transit_realtime'),
      createEmptyInstance: create)
    ..aOM<TripDescriptor>(1, _omitFieldNames ? '' : 'trip',
        subBuilder: TripDescriptor.create)
    ..aOM<Position>(2, _omitFieldNames ? '' : 'position',
        subBuilder: Position.create)
    ..aI(3, _omitFieldNames ? '' : 'currentStopSequence',
        fieldType: $pb.PbFieldType.OU3)
    ..aOS(4, _omitFieldNames ? '' : 'stopId')
    ..aE<VehiclePosition_VehicleStopStatus>(
        5, _omitFieldNames ? '' : 'currentStatus',
        enumValues: VehiclePosition_VehicleStopStatus.values)
    ..a<$fixnum.Int64>(
        6, _omitFieldNames ? '' : 'timestamp', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aE<VehiclePosition_CongestionLevel>(
        7, _omitFieldNames ? '' : 'congestionLevel',
        enumValues: VehiclePosition_CongestionLevel.values)
    ..aE<VehiclePosition_OccupancyStatus>(
        8, _omitFieldNames ? '' : 'occupancyStatus',
        enumValues: VehiclePosition_OccupancyStatus.values)
    ..aI(9, _omitFieldNames ? '' : 'occupancyPercentage',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VehiclePosition clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VehiclePosition copyWith(void Function(VehiclePosition) updates) =>
      super.copyWith((message) => updates(message as VehiclePosition))
          as VehiclePosition;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static VehiclePosition create() => VehiclePosition._();
  @$core.override
  VehiclePosition createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static VehiclePosition getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<VehiclePosition>(create);
  static VehiclePosition? _defaultInstance;

  @$pb.TagNumber(1)
  TripDescriptor get trip => $_getN(0);
  @$pb.TagNumber(1)
  set trip(TripDescriptor value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTrip() => $_has(0);
  @$pb.TagNumber(1)
  void clearTrip() => $_clearField(1);
  @$pb.TagNumber(1)
  TripDescriptor ensureTrip() => $_ensure(0);

  @$pb.TagNumber(2)
  Position get position => $_getN(1);
  @$pb.TagNumber(2)
  set position(Position value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPosition() => $_has(1);
  @$pb.TagNumber(2)
  void clearPosition() => $_clearField(2);
  @$pb.TagNumber(2)
  Position ensurePosition() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.int get currentStopSequence => $_getIZ(2);
  @$pb.TagNumber(3)
  set currentStopSequence($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCurrentStopSequence() => $_has(2);
  @$pb.TagNumber(3)
  void clearCurrentStopSequence() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get stopId => $_getSZ(3);
  @$pb.TagNumber(4)
  set stopId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasStopId() => $_has(3);
  @$pb.TagNumber(4)
  void clearStopId() => $_clearField(4);

  @$pb.TagNumber(5)
  VehiclePosition_VehicleStopStatus get currentStatus => $_getN(4);
  @$pb.TagNumber(5)
  set currentStatus(VehiclePosition_VehicleStopStatus value) =>
      $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasCurrentStatus() => $_has(4);
  @$pb.TagNumber(5)
  void clearCurrentStatus() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get timestamp => $_getI64(5);
  @$pb.TagNumber(6)
  set timestamp($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasTimestamp() => $_has(5);
  @$pb.TagNumber(6)
  void clearTimestamp() => $_clearField(6);

  @$pb.TagNumber(7)
  VehiclePosition_CongestionLevel get congestionLevel => $_getN(6);
  @$pb.TagNumber(7)
  set congestionLevel(VehiclePosition_CongestionLevel value) =>
      $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasCongestionLevel() => $_has(6);
  @$pb.TagNumber(7)
  void clearCongestionLevel() => $_clearField(7);

  @$pb.TagNumber(8)
  VehiclePosition_OccupancyStatus get occupancyStatus => $_getN(7);
  @$pb.TagNumber(8)
  set occupancyStatus(VehiclePosition_OccupancyStatus value) =>
      $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasOccupancyStatus() => $_has(7);
  @$pb.TagNumber(8)
  void clearOccupancyStatus() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get occupancyPercentage => $_getIZ(8);
  @$pb.TagNumber(9)
  set occupancyPercentage($core.int value) => $_setUnsignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasOccupancyPercentage() => $_has(8);
  @$pb.TagNumber(9)
  void clearOccupancyPercentage() => $_clearField(9);
}

class TripDescriptor extends $pb.GeneratedMessage {
  factory TripDescriptor({
    $core.String? tripId,
    $core.String? startTime,
    $core.String? startDate,
    TripDescriptor_ScheduleRelationship? scheduleRelationship,
    $core.String? routeId,
    $core.int? directionId,
  }) {
    final result = create();
    if (tripId != null) result.tripId = tripId;
    if (startTime != null) result.startTime = startTime;
    if (startDate != null) result.startDate = startDate;
    if (scheduleRelationship != null)
      result.scheduleRelationship = scheduleRelationship;
    if (routeId != null) result.routeId = routeId;
    if (directionId != null) result.directionId = directionId;
    return result;
  }

  TripDescriptor._();

  factory TripDescriptor.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TripDescriptor.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TripDescriptor',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'transit_realtime'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'tripId')
    ..aOS(2, _omitFieldNames ? '' : 'startTime')
    ..aOS(3, _omitFieldNames ? '' : 'startDate')
    ..aE<TripDescriptor_ScheduleRelationship>(
        4, _omitFieldNames ? '' : 'scheduleRelationship',
        enumValues: TripDescriptor_ScheduleRelationship.values)
    ..aOS(5, _omitFieldNames ? '' : 'routeId')
    ..aI(6, _omitFieldNames ? '' : 'directionId',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TripDescriptor clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TripDescriptor copyWith(void Function(TripDescriptor) updates) =>
      super.copyWith((message) => updates(message as TripDescriptor))
          as TripDescriptor;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TripDescriptor create() => TripDescriptor._();
  @$core.override
  TripDescriptor createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TripDescriptor getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TripDescriptor>(create);
  static TripDescriptor? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get tripId => $_getSZ(0);
  @$pb.TagNumber(1)
  set tripId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTripId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTripId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get startTime => $_getSZ(1);
  @$pb.TagNumber(2)
  set startTime($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStartTime() => $_has(1);
  @$pb.TagNumber(2)
  void clearStartTime() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get startDate => $_getSZ(2);
  @$pb.TagNumber(3)
  set startDate($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasStartDate() => $_has(2);
  @$pb.TagNumber(3)
  void clearStartDate() => $_clearField(3);

  @$pb.TagNumber(4)
  TripDescriptor_ScheduleRelationship get scheduleRelationship => $_getN(3);
  @$pb.TagNumber(4)
  set scheduleRelationship(TripDescriptor_ScheduleRelationship value) =>
      $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasScheduleRelationship() => $_has(3);
  @$pb.TagNumber(4)
  void clearScheduleRelationship() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get routeId => $_getSZ(4);
  @$pb.TagNumber(5)
  set routeId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRouteId() => $_has(4);
  @$pb.TagNumber(5)
  void clearRouteId() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get directionId => $_getIZ(5);
  @$pb.TagNumber(6)
  set directionId($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDirectionId() => $_has(5);
  @$pb.TagNumber(6)
  void clearDirectionId() => $_clearField(6);
}

class VehicleDescriptor extends $pb.GeneratedMessage {
  factory VehicleDescriptor({
    $core.String? id,
    $core.String? label,
    $core.String? licensePlate,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (label != null) result.label = label;
    if (licensePlate != null) result.licensePlate = licensePlate;
    return result;
  }

  VehicleDescriptor._();

  factory VehicleDescriptor.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory VehicleDescriptor.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VehicleDescriptor',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'transit_realtime'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'label')
    ..aOS(3, _omitFieldNames ? '' : 'licensePlate')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VehicleDescriptor clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VehicleDescriptor copyWith(void Function(VehicleDescriptor) updates) =>
      super.copyWith((message) => updates(message as VehicleDescriptor))
          as VehicleDescriptor;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static VehicleDescriptor create() => VehicleDescriptor._();
  @$core.override
  VehicleDescriptor createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static VehicleDescriptor getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<VehicleDescriptor>(create);
  static VehicleDescriptor? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get label => $_getSZ(1);
  @$pb.TagNumber(2)
  set label($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLabel() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get licensePlate => $_getSZ(2);
  @$pb.TagNumber(3)
  set licensePlate($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLicensePlate() => $_has(2);
  @$pb.TagNumber(3)
  void clearLicensePlate() => $_clearField(3);
}

class Position extends $pb.GeneratedMessage {
  factory Position({
    $core.double? latitude,
    $core.double? longitude,
    $core.double? bearing,
    $core.double? odometer,
    $core.double? speed,
    $fixnum.Int64? timestamp,
  }) {
    final result = create();
    if (latitude != null) result.latitude = latitude;
    if (longitude != null) result.longitude = longitude;
    if (bearing != null) result.bearing = bearing;
    if (odometer != null) result.odometer = odometer;
    if (speed != null) result.speed = speed;
    if (timestamp != null) result.timestamp = timestamp;
    return result;
  }

  Position._();

  factory Position.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Position.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Position',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'transit_realtime'),
      createEmptyInstance: create)
    ..aD(1, _omitFieldNames ? '' : 'latitude', fieldType: $pb.PbFieldType.OF)
    ..aD(2, _omitFieldNames ? '' : 'longitude', fieldType: $pb.PbFieldType.OF)
    ..aD(3, _omitFieldNames ? '' : 'bearing', fieldType: $pb.PbFieldType.OF)
    ..aD(4, _omitFieldNames ? '' : 'odometer')
    ..aD(5, _omitFieldNames ? '' : 'speed', fieldType: $pb.PbFieldType.OF)
    ..a<$fixnum.Int64>(
        6, _omitFieldNames ? '' : 'timestamp', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Position clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Position copyWith(void Function(Position) updates) =>
      super.copyWith((message) => updates(message as Position)) as Position;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Position create() => Position._();
  @$core.override
  Position createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Position getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Position>(create);
  static Position? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get latitude => $_getN(0);
  @$pb.TagNumber(1)
  set latitude($core.double value) => $_setFloat(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLatitude() => $_has(0);
  @$pb.TagNumber(1)
  void clearLatitude() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get longitude => $_getN(1);
  @$pb.TagNumber(2)
  set longitude($core.double value) => $_setFloat(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLongitude() => $_has(1);
  @$pb.TagNumber(2)
  void clearLongitude() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get bearing => $_getN(2);
  @$pb.TagNumber(3)
  set bearing($core.double value) => $_setFloat(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBearing() => $_has(2);
  @$pb.TagNumber(3)
  void clearBearing() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get odometer => $_getN(3);
  @$pb.TagNumber(4)
  set odometer($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasOdometer() => $_has(3);
  @$pb.TagNumber(4)
  void clearOdometer() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get speed => $_getN(4);
  @$pb.TagNumber(5)
  set speed($core.double value) => $_setFloat(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSpeed() => $_has(4);
  @$pb.TagNumber(5)
  void clearSpeed() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get timestamp => $_getI64(5);
  @$pb.TagNumber(6)
  set timestamp($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasTimestamp() => $_has(5);
  @$pb.TagNumber(6)
  void clearTimestamp() => $_clearField(6);
}

class Alert extends $pb.GeneratedMessage {
  factory Alert({
    $core.String? id,
  }) {
    final result = create();
    if (id != null) result.id = id;
    return result;
  }

  Alert._();

  factory Alert.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Alert.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Alert',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'transit_realtime'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Alert clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Alert copyWith(void Function(Alert) updates) =>
      super.copyWith((message) => updates(message as Alert)) as Alert;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Alert create() => Alert._();
  @$core.override
  Alert createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Alert getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Alert>(create);
  static Alert? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
