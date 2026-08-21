// This is a generated file - do not edit.
//
// Generated from gtfs_realtime.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use feedMessageDescriptor instead')
const FeedMessage$json = {
  '1': 'FeedMessage',
  '2': [
    {
      '1': 'header',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.transit_realtime.FeedHeader',
      '10': 'header'
    },
    {
      '1': 'entity',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.transit_realtime.FeedEntity',
      '10': 'entity'
    },
  ],
};

/// Descriptor for `FeedMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List feedMessageDescriptor = $convert.base64Decode(
    'CgtGZWVkTWVzc2FnZRI0CgZoZWFkZXIYASABKAsyHC50cmFuc2l0X3JlYWx0aW1lLkZlZWRIZW'
    'FkZXJSBmhlYWRlchI0CgZlbnRpdHkYAiADKAsyHC50cmFuc2l0X3JlYWx0aW1lLkZlZWRFbnRp'
    'dHlSBmVudGl0eQ==');

@$core.Deprecated('Use feedHeaderDescriptor instead')
const FeedHeader$json = {
  '1': 'FeedHeader',
  '2': [
    {
      '1': 'gtfs_realtime_version',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'gtfsRealtimeVersion'
    },
    {
      '1': 'incrementality',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.transit_realtime.FeedHeader.Incrementality',
      '10': 'incrementality'
    },
    {'1': 'timestamp', '3': 3, '4': 1, '5': 4, '10': 'timestamp'},
  ],
  '4': [FeedHeader_Incrementality$json],
};

@$core.Deprecated('Use feedHeaderDescriptor instead')
const FeedHeader_Incrementality$json = {
  '1': 'Incrementality',
  '2': [
    {'1': 'FULL_DATASET', '2': 0},
    {'1': 'DIFFERENTIAL', '2': 1},
  ],
};

/// Descriptor for `FeedHeader`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List feedHeaderDescriptor = $convert.base64Decode(
    'CgpGZWVkSGVhZGVyEjIKFWd0ZnNfcmVhbHRpbWVfdmVyc2lvbhgBIAEoCVITZ3Rmc1JlYWx0aW'
    '1lVmVyc2lvbhJTCg5pbmNyZW1lbnRhbGl0eRgCIAEoDjIrLnRyYW5zaXRfcmVhbHRpbWUuRmVl'
    'ZEhlYWRlci5JbmNyZW1lbnRhbGl0eVIOaW5jcmVtZW50YWxpdHkSHAoJdGltZXN0YW1wGAMgAS'
    'gEUgl0aW1lc3RhbXAiNAoOSW5jcmVtZW50YWxpdHkSEAoMRlVMTF9EQVRBU0VUEAASEAoMRElG'
    'RkVSRU5USUFMEAE=');

@$core.Deprecated('Use feedEntityDescriptor instead')
const FeedEntity$json = {
  '1': 'FeedEntity',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'is_deleted', '3': 2, '4': 1, '5': 8, '10': 'isDeleted'},
    {
      '1': 'trip_update',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.transit_realtime.TripUpdate',
      '10': 'tripUpdate'
    },
    {
      '1': 'vehicle',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.transit_realtime.VehiclePosition',
      '10': 'vehicle'
    },
    {
      '1': 'alert',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.transit_realtime.Alert',
      '10': 'alert'
    },
  ],
};

/// Descriptor for `FeedEntity`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List feedEntityDescriptor = $convert.base64Decode(
    'CgpGZWVkRW50aXR5Eg4KAmlkGAEgASgJUgJpZBIdCgppc19kZWxldGVkGAIgASgIUglpc0RlbG'
    'V0ZWQSPQoLdHJpcF91cGRhdGUYAyABKAsyHC50cmFuc2l0X3JlYWx0aW1lLlRyaXBVcGRhdGVS'
    'CnRyaXBVcGRhdGUSOwoHdmVoaWNsZRgIIAEoCzIhLnRyYW5zaXRfcmVhbHRpbWUuVmVoaWNsZV'
    'Bvc2l0aW9uUgd2ZWhpY2xlEi0KBWFsZXJ0GAUgASgLMhcudHJhbnNpdF9yZWFsdGltZS5BbGVy'
    'dFIFYWxlcnQ=');

@$core.Deprecated('Use tripUpdateDescriptor instead')
const TripUpdate$json = {
  '1': 'TripUpdate',
  '2': [
    {
      '1': 'trip',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.transit_realtime.TripDescriptor',
      '10': 'trip'
    },
    {
      '1': 'vehicle',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.transit_realtime.VehicleDescriptor',
      '10': 'vehicle'
    },
    {'1': 'timestamp', '3': 4, '4': 1, '5': 4, '10': 'timestamp'},
    {'1': 'delay', '3': 5, '4': 1, '5': 5, '10': 'delay'},
  ],
};

/// Descriptor for `TripUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tripUpdateDescriptor = $convert.base64Decode(
    'CgpUcmlwVXBkYXRlEjQKBHRyaXAYASABKAsyIC50cmFuc2l0X3JlYWx0aW1lLlRyaXBEZXNjcm'
    'lwdG9yUgR0cmlwEj0KB3ZlaGljbGUYAyABKAsyIy50cmFuc2l0X3JlYWx0aW1lLlZlaGljbGVE'
    'ZXNjcmlwdG9yUgd2ZWhpY2xlEhwKCXRpbWVzdGFtcBgEIAEoBFIJdGltZXN0YW1wEhQKBWRlbG'
    'F5GAUgASgFUgVkZWxheQ==');

@$core.Deprecated('Use vehiclePositionDescriptor instead')
const VehiclePosition$json = {
  '1': 'VehiclePosition',
  '2': [
    {
      '1': 'trip',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.transit_realtime.TripDescriptor',
      '10': 'trip'
    },
    {
      '1': 'position',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.transit_realtime.Position',
      '10': 'position'
    },
    {
      '1': 'current_stop_sequence',
      '3': 3,
      '4': 1,
      '5': 13,
      '10': 'currentStopSequence'
    },
    {'1': 'stop_id', '3': 4, '4': 1, '5': 9, '10': 'stopId'},
    {
      '1': 'current_status',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.transit_realtime.VehiclePosition.VehicleStopStatus',
      '10': 'currentStatus'
    },
    {'1': 'timestamp', '3': 6, '4': 1, '5': 4, '10': 'timestamp'},
    {
      '1': 'congestion_level',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.transit_realtime.VehiclePosition.CongestionLevel',
      '10': 'congestionLevel'
    },
    {
      '1': 'occupancy_status',
      '3': 8,
      '4': 1,
      '5': 14,
      '6': '.transit_realtime.VehiclePosition.OccupancyStatus',
      '10': 'occupancyStatus'
    },
    {
      '1': 'occupancy_percentage',
      '3': 9,
      '4': 1,
      '5': 13,
      '10': 'occupancyPercentage'
    },
  ],
  '4': [
    VehiclePosition_VehicleStopStatus$json,
    VehiclePosition_CongestionLevel$json,
    VehiclePosition_OccupancyStatus$json
  ],
};

@$core.Deprecated('Use vehiclePositionDescriptor instead')
const VehiclePosition_VehicleStopStatus$json = {
  '1': 'VehicleStopStatus',
  '2': [
    {'1': 'INCOMING_AT', '2': 0},
    {'1': 'STOPPED_AT', '2': 1},
    {'1': 'IN_TRANSIT_TO', '2': 2},
  ],
};

@$core.Deprecated('Use vehiclePositionDescriptor instead')
const VehiclePosition_CongestionLevel$json = {
  '1': 'CongestionLevel',
  '2': [
    {'1': 'UNKNOWN_CONGESTION_LEVEL', '2': 0},
    {'1': 'RUNNING_SMOOTHLY', '2': 1},
    {'1': 'STOP_AND_GO', '2': 2},
    {'1': 'CONGESTION', '2': 3},
    {'1': 'SEVERE_CONGESTION', '2': 4},
  ],
};

@$core.Deprecated('Use vehiclePositionDescriptor instead')
const VehiclePosition_OccupancyStatus$json = {
  '1': 'OccupancyStatus',
  '2': [
    {'1': 'EMPTY', '2': 0},
    {'1': 'MANY_SEATS_AVAILABLE', '2': 1},
    {'1': 'FEW_SEATS_AVAILABLE', '2': 2},
    {'1': 'STANDING_ROOM_ONLY', '2': 3},
    {'1': 'CRUSHED_STANDING_ROOM_ONLY', '2': 4},
    {'1': 'FULL', '2': 5},
    {'1': 'NOT_ACCEPTING_PASSENGERS', '2': 6},
    {'1': 'NO_DATA_AVAILABLE', '2': 7},
  ],
};

/// Descriptor for `VehiclePosition`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List vehiclePositionDescriptor = $convert.base64Decode(
    'Cg9WZWhpY2xlUG9zaXRpb24SNAoEdHJpcBgBIAEoCzIgLnRyYW5zaXRfcmVhbHRpbWUuVHJpcE'
    'Rlc2NyaXB0b3JSBHRyaXASNgoIcG9zaXRpb24YAiABKAsyGi50cmFuc2l0X3JlYWx0aW1lLlBv'
    'c2l0aW9uUghwb3NpdGlvbhIyChVjdXJyZW50X3N0b3Bfc2VxdWVuY2UYAyABKA1SE2N1cnJlbn'
    'RTdG9wU2VxdWVuY2USFwoHc3RvcF9pZBgEIAEoCVIGc3RvcElkEloKDmN1cnJlbnRfc3RhdHVz'
    'GAUgASgOMjMudHJhbnNpdF9yZWFsdGltZS5WZWhpY2xlUG9zaXRpb24uVmVoaWNsZVN0b3BTdG'
    'F0dXNSDWN1cnJlbnRTdGF0dXMSHAoJdGltZXN0YW1wGAYgASgEUgl0aW1lc3RhbXASXAoQY29u'
    'Z2VzdGlvbl9sZXZlbBgHIAEoDjIxLnRyYW5zaXRfcmVhbHRpbWUuVmVoaWNsZVBvc2l0aW9uLk'
    'Nvbmdlc3Rpb25MZXZlbFIPY29uZ2VzdGlvbkxldmVsElwKEG9jY3VwYW5jeV9zdGF0dXMYCCAB'
    'KA4yMS50cmFuc2l0X3JlYWx0aW1lLlZlaGljbGVQb3NpdGlvbi5PY2N1cGFuY3lTdGF0dXNSD2'
    '9jY3VwYW5jeVN0YXR1cxIxChRvY2N1cGFuY3lfcGVyY2VudGFnZRgJIAEoDVITb2NjdXBhbmN5'
    'UGVyY2VudGFnZSJHChFWZWhpY2xlU3RvcFN0YXR1cxIPCgtJTkNPTUlOR19BVBAAEg4KClNUT1'
    'BQRURfQVQQARIRCg1JTl9UUkFOU0lUX1RPEAIifQoPQ29uZ2VzdGlvbkxldmVsEhwKGFVOS05P'
    'V05fQ09OR0VTVElPTl9MRVZFTBAAEhQKEFJVTk5JTkdfU01PT1RITFkQARIPCgtTVE9QX0FORF'
    '9HTxACEg4KCkNPTkdFU1RJT04QAxIVChFTRVZFUkVfQ09OR0VTVElPThAEIsYBCg9PY2N1cGFu'
    'Y3lTdGF0dXMSCQoFRU1QVFkQABIYChRNQU5ZX1NFQVRTX0FWQUlMQUJMRRABEhcKE0ZFV19TRU'
    'FUU19BVkFJTEFCTEUQAhIWChJTVEFORElOR19ST09NX09OTFkQAxIeChpDUlVTSEVEX1NUQU5E'
    'SU5HX1JPT01fT05MWRAEEggKBEZVTEwQBRIcChhOT1RfQUNDRVBUSU5HX1BBU1NFTkdFUlMQBh'
    'IVChFOT19EQVRBX0FWQUlMQUJMRRAH');

@$core.Deprecated('Use tripDescriptorDescriptor instead')
const TripDescriptor$json = {
  '1': 'TripDescriptor',
  '2': [
    {'1': 'trip_id', '3': 1, '4': 1, '5': 9, '10': 'tripId'},
    {'1': 'start_time', '3': 2, '4': 1, '5': 9, '10': 'startTime'},
    {'1': 'start_date', '3': 3, '4': 1, '5': 9, '10': 'startDate'},
    {
      '1': 'schedule_relationship',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.transit_realtime.TripDescriptor.ScheduleRelationship',
      '10': 'scheduleRelationship'
    },
    {'1': 'route_id', '3': 5, '4': 1, '5': 9, '10': 'routeId'},
    {'1': 'direction_id', '3': 6, '4': 1, '5': 13, '10': 'directionId'},
  ],
  '4': [TripDescriptor_ScheduleRelationship$json],
};

@$core.Deprecated('Use tripDescriptorDescriptor instead')
const TripDescriptor_ScheduleRelationship$json = {
  '1': 'ScheduleRelationship',
  '2': [
    {'1': 'SCHEDULED', '2': 0},
    {'1': 'ADDED', '2': 1},
    {'1': 'UNSCHEDULED', '2': 2},
    {'1': 'CANCELED', '2': 3},
  ],
};

/// Descriptor for `TripDescriptor`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tripDescriptorDescriptor = $convert.base64Decode(
    'Cg5UcmlwRGVzY3JpcHRvchIXCgd0cmlwX2lkGAEgASgJUgZ0cmlwSWQSHQoKc3RhcnRfdGltZR'
    'gCIAEoCVIJc3RhcnRUaW1lEh0KCnN0YXJ0X2RhdGUYAyABKAlSCXN0YXJ0RGF0ZRJqChVzY2hl'
    'ZHVsZV9yZWxhdGlvbnNoaXAYBCABKA4yNS50cmFuc2l0X3JlYWx0aW1lLlRyaXBEZXNjcmlwdG'
    '9yLlNjaGVkdWxlUmVsYXRpb25zaGlwUhRzY2hlZHVsZVJlbGF0aW9uc2hpcBIZCghyb3V0ZV9p'
    'ZBgFIAEoCVIHcm91dGVJZBIhCgxkaXJlY3Rpb25faWQYBiABKA1SC2RpcmVjdGlvbklkIk8KFF'
    'NjaGVkdWxlUmVsYXRpb25zaGlwEg0KCVNDSEVEVUxFRBAAEgkKBUFEREVEEAESDwoLVU5TQ0hF'
    'RFVMRUQQAhIMCghDQU5DRUxFRBAD');

@$core.Deprecated('Use vehicleDescriptorDescriptor instead')
const VehicleDescriptor$json = {
  '1': 'VehicleDescriptor',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'label', '3': 2, '4': 1, '5': 9, '10': 'label'},
    {'1': 'license_plate', '3': 3, '4': 1, '5': 9, '10': 'licensePlate'},
  ],
};

/// Descriptor for `VehicleDescriptor`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List vehicleDescriptorDescriptor = $convert.base64Decode(
    'ChFWZWhpY2xlRGVzY3JpcHRvchIOCgJpZBgBIAEoCVICaWQSFAoFbGFiZWwYAiABKAlSBWxhYm'
    'VsEiMKDWxpY2Vuc2VfcGxhdGUYAyABKAlSDGxpY2Vuc2VQbGF0ZQ==');

@$core.Deprecated('Use positionDescriptor instead')
const Position$json = {
  '1': 'Position',
  '2': [
    {'1': 'latitude', '3': 1, '4': 1, '5': 2, '10': 'latitude'},
    {'1': 'longitude', '3': 2, '4': 1, '5': 2, '10': 'longitude'},
    {'1': 'bearing', '3': 3, '4': 1, '5': 2, '10': 'bearing'},
    {'1': 'odometer', '3': 4, '4': 1, '5': 1, '10': 'odometer'},
    {'1': 'speed', '3': 5, '4': 1, '5': 2, '10': 'speed'},
    {'1': 'timestamp', '3': 6, '4': 1, '5': 4, '10': 'timestamp'},
  ],
};

/// Descriptor for `Position`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List positionDescriptor = $convert.base64Decode(
    'CghQb3NpdGlvbhIaCghsYXRpdHVkZRgBIAEoAlIIbGF0aXR1ZGUSHAoJbG9uZ2l0dWRlGAIgAS'
    'gCUglsb25naXR1ZGUSGAoHYmVhcmluZxgDIAEoAlIHYmVhcmluZxIaCghvZG9tZXRlchgEIAEo'
    'AVIIb2RvbWV0ZXISFAoFc3BlZWQYBSABKAJSBXNwZWVkEhwKCXRpbWVzdGFtcBgGIAEoBFIJdG'
    'ltZXN0YW1w');

@$core.Deprecated('Use alertDescriptor instead')
const Alert$json = {
  '1': 'Alert',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `Alert`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List alertDescriptor =
    $convert.base64Decode('CgVBbGVydBIOCgJpZBgBIAEoCVICaWQ=');
