// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AgenciesTable extends Agencies with TableInfo<$AgenciesTable, Agency> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AgenciesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _agencyIdMeta = const VerificationMeta(
    'agencyId',
  );
  @override
  late final GeneratedColumn<String> agencyId = GeneratedColumn<String>(
    'agency_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _agencyNameMeta = const VerificationMeta(
    'agencyName',
  );
  @override
  late final GeneratedColumn<String> agencyName = GeneratedColumn<String>(
    'agency_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _agencyUrlMeta = const VerificationMeta(
    'agencyUrl',
  );
  @override
  late final GeneratedColumn<String> agencyUrl = GeneratedColumn<String>(
    'agency_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _agencyTimezoneMeta = const VerificationMeta(
    'agencyTimezone',
  );
  @override
  late final GeneratedColumn<String> agencyTimezone = GeneratedColumn<String>(
    'agency_timezone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    agencyId,
    agencyName,
    agencyUrl,
    agencyTimezone,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'agencies';
  @override
  VerificationContext validateIntegrity(
    Insertable<Agency> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('agency_id')) {
      context.handle(
        _agencyIdMeta,
        agencyId.isAcceptableOrUnknown(data['agency_id']!, _agencyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_agencyIdMeta);
    }
    if (data.containsKey('agency_name')) {
      context.handle(
        _agencyNameMeta,
        agencyName.isAcceptableOrUnknown(data['agency_name']!, _agencyNameMeta),
      );
    } else if (isInserting) {
      context.missing(_agencyNameMeta);
    }
    if (data.containsKey('agency_url')) {
      context.handle(
        _agencyUrlMeta,
        agencyUrl.isAcceptableOrUnknown(data['agency_url']!, _agencyUrlMeta),
      );
    }
    if (data.containsKey('agency_timezone')) {
      context.handle(
        _agencyTimezoneMeta,
        agencyTimezone.isAcceptableOrUnknown(
          data['agency_timezone']!,
          _agencyTimezoneMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_agencyTimezoneMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {agencyId};
  @override
  Agency map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Agency(
      agencyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agency_id'],
      )!,
      agencyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agency_name'],
      )!,
      agencyUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agency_url'],
      ),
      agencyTimezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agency_timezone'],
      )!,
    );
  }

  @override
  $AgenciesTable createAlias(String alias) {
    return $AgenciesTable(attachedDatabase, alias);
  }
}

class Agency extends DataClass implements Insertable<Agency> {
  final String agencyId;
  final String agencyName;
  final String? agencyUrl;
  final String agencyTimezone;
  const Agency({
    required this.agencyId,
    required this.agencyName,
    this.agencyUrl,
    required this.agencyTimezone,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['agency_id'] = Variable<String>(agencyId);
    map['agency_name'] = Variable<String>(agencyName);
    if (!nullToAbsent || agencyUrl != null) {
      map['agency_url'] = Variable<String>(agencyUrl);
    }
    map['agency_timezone'] = Variable<String>(agencyTimezone);
    return map;
  }

  AgenciesCompanion toCompanion(bool nullToAbsent) {
    return AgenciesCompanion(
      agencyId: Value(agencyId),
      agencyName: Value(agencyName),
      agencyUrl: agencyUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(agencyUrl),
      agencyTimezone: Value(agencyTimezone),
    );
  }

  factory Agency.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Agency(
      agencyId: serializer.fromJson<String>(json['agencyId']),
      agencyName: serializer.fromJson<String>(json['agencyName']),
      agencyUrl: serializer.fromJson<String?>(json['agencyUrl']),
      agencyTimezone: serializer.fromJson<String>(json['agencyTimezone']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'agencyId': serializer.toJson<String>(agencyId),
      'agencyName': serializer.toJson<String>(agencyName),
      'agencyUrl': serializer.toJson<String?>(agencyUrl),
      'agencyTimezone': serializer.toJson<String>(agencyTimezone),
    };
  }

  Agency copyWith({
    String? agencyId,
    String? agencyName,
    Value<String?> agencyUrl = const Value.absent(),
    String? agencyTimezone,
  }) => Agency(
    agencyId: agencyId ?? this.agencyId,
    agencyName: agencyName ?? this.agencyName,
    agencyUrl: agencyUrl.present ? agencyUrl.value : this.agencyUrl,
    agencyTimezone: agencyTimezone ?? this.agencyTimezone,
  );
  Agency copyWithCompanion(AgenciesCompanion data) {
    return Agency(
      agencyId: data.agencyId.present ? data.agencyId.value : this.agencyId,
      agencyName: data.agencyName.present
          ? data.agencyName.value
          : this.agencyName,
      agencyUrl: data.agencyUrl.present ? data.agencyUrl.value : this.agencyUrl,
      agencyTimezone: data.agencyTimezone.present
          ? data.agencyTimezone.value
          : this.agencyTimezone,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Agency(')
          ..write('agencyId: $agencyId, ')
          ..write('agencyName: $agencyName, ')
          ..write('agencyUrl: $agencyUrl, ')
          ..write('agencyTimezone: $agencyTimezone')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(agencyId, agencyName, agencyUrl, agencyTimezone);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Agency &&
          other.agencyId == this.agencyId &&
          other.agencyName == this.agencyName &&
          other.agencyUrl == this.agencyUrl &&
          other.agencyTimezone == this.agencyTimezone);
}

class AgenciesCompanion extends UpdateCompanion<Agency> {
  final Value<String> agencyId;
  final Value<String> agencyName;
  final Value<String?> agencyUrl;
  final Value<String> agencyTimezone;
  final Value<int> rowid;
  const AgenciesCompanion({
    this.agencyId = const Value.absent(),
    this.agencyName = const Value.absent(),
    this.agencyUrl = const Value.absent(),
    this.agencyTimezone = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AgenciesCompanion.insert({
    required String agencyId,
    required String agencyName,
    this.agencyUrl = const Value.absent(),
    required String agencyTimezone,
    this.rowid = const Value.absent(),
  }) : agencyId = Value(agencyId),
       agencyName = Value(agencyName),
       agencyTimezone = Value(agencyTimezone);
  static Insertable<Agency> custom({
    Expression<String>? agencyId,
    Expression<String>? agencyName,
    Expression<String>? agencyUrl,
    Expression<String>? agencyTimezone,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (agencyId != null) 'agency_id': agencyId,
      if (agencyName != null) 'agency_name': agencyName,
      if (agencyUrl != null) 'agency_url': agencyUrl,
      if (agencyTimezone != null) 'agency_timezone': agencyTimezone,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AgenciesCompanion copyWith({
    Value<String>? agencyId,
    Value<String>? agencyName,
    Value<String?>? agencyUrl,
    Value<String>? agencyTimezone,
    Value<int>? rowid,
  }) {
    return AgenciesCompanion(
      agencyId: agencyId ?? this.agencyId,
      agencyName: agencyName ?? this.agencyName,
      agencyUrl: agencyUrl ?? this.agencyUrl,
      agencyTimezone: agencyTimezone ?? this.agencyTimezone,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (agencyId.present) {
      map['agency_id'] = Variable<String>(agencyId.value);
    }
    if (agencyName.present) {
      map['agency_name'] = Variable<String>(agencyName.value);
    }
    if (agencyUrl.present) {
      map['agency_url'] = Variable<String>(agencyUrl.value);
    }
    if (agencyTimezone.present) {
      map['agency_timezone'] = Variable<String>(agencyTimezone.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AgenciesCompanion(')
          ..write('agencyId: $agencyId, ')
          ..write('agencyName: $agencyName, ')
          ..write('agencyUrl: $agencyUrl, ')
          ..write('agencyTimezone: $agencyTimezone, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StopsTable extends Stops with TableInfo<$StopsTable, Stop> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StopsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _stopIdMeta = const VerificationMeta('stopId');
  @override
  late final GeneratedColumn<String> stopId = GeneratedColumn<String>(
    'stop_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stopNameMeta = const VerificationMeta(
    'stopName',
  );
  @override
  late final GeneratedColumn<String> stopName = GeneratedColumn<String>(
    'stop_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stopLatMeta = const VerificationMeta(
    'stopLat',
  );
  @override
  late final GeneratedColumn<double> stopLat = GeneratedColumn<double>(
    'stop_lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stopLonMeta = const VerificationMeta(
    'stopLon',
  );
  @override
  late final GeneratedColumn<double> stopLon = GeneratedColumn<double>(
    'stop_lon',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stopCodeMeta = const VerificationMeta(
    'stopCode',
  );
  @override
  late final GeneratedColumn<String> stopCode = GeneratedColumn<String>(
    'stop_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _platformCodeMeta = const VerificationMeta(
    'platformCode',
  );
  @override
  late final GeneratedColumn<String> platformCode = GeneratedColumn<String>(
    'platform_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parentStationMeta = const VerificationMeta(
    'parentStation',
  );
  @override
  late final GeneratedColumn<String> parentStation = GeneratedColumn<String>(
    'parent_station',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationTypeMeta = const VerificationMeta(
    'locationType',
  );
  @override
  late final GeneratedColumn<int> locationType = GeneratedColumn<int>(
    'location_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _wheelchairBoardingMeta =
      const VerificationMeta('wheelchairBoarding');
  @override
  late final GeneratedColumn<int> wheelchairBoarding = GeneratedColumn<int>(
    'wheelchair_boarding',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cityMeta = const VerificationMeta('city');
  @override
  late final GeneratedColumn<String> city = GeneratedColumn<String>(
    'city',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _operatorNameMeta = const VerificationMeta(
    'operatorName',
  );
  @override
  late final GeneratedColumn<String> operatorName = GeneratedColumn<String>(
    'operator_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rikshallplatsIdMeta = const VerificationMeta(
    'rikshallplatsId',
  );
  @override
  late final GeneratedColumn<String> rikshallplatsId = GeneratedColumn<String>(
    'rikshallplats_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rikshallplatsNameMeta = const VerificationMeta(
    'rikshallplatsName',
  );
  @override
  late final GeneratedColumn<String> rikshallplatsName =
      GeneratedColumn<String>(
        'rikshallplats_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _availableModesMeta = const VerificationMeta(
    'availableModes',
  );
  @override
  late final GeneratedColumn<String> availableModes = GeneratedColumn<String>(
    'available_modes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _platformListMeta = const VerificationMeta(
    'platformList',
  );
  @override
  late final GeneratedColumn<String> platformList = GeneratedColumn<String>(
    'platform_list',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dailyPassengersMeta = const VerificationMeta(
    'dailyPassengers',
  );
  @override
  late final GeneratedColumn<int> dailyPassengers = GeneratedColumn<int>(
    'daily_passengers',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    stopId,
    stopName,
    stopLat,
    stopLon,
    stopCode,
    platformCode,
    parentStation,
    locationType,
    wheelchairBoarding,
    city,
    operatorName,
    rikshallplatsId,
    rikshallplatsName,
    availableModes,
    platformList,
    dailyPassengers,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stops';
  @override
  VerificationContext validateIntegrity(
    Insertable<Stop> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('stop_id')) {
      context.handle(
        _stopIdMeta,
        stopId.isAcceptableOrUnknown(data['stop_id']!, _stopIdMeta),
      );
    } else if (isInserting) {
      context.missing(_stopIdMeta);
    }
    if (data.containsKey('stop_name')) {
      context.handle(
        _stopNameMeta,
        stopName.isAcceptableOrUnknown(data['stop_name']!, _stopNameMeta),
      );
    } else if (isInserting) {
      context.missing(_stopNameMeta);
    }
    if (data.containsKey('stop_lat')) {
      context.handle(
        _stopLatMeta,
        stopLat.isAcceptableOrUnknown(data['stop_lat']!, _stopLatMeta),
      );
    } else if (isInserting) {
      context.missing(_stopLatMeta);
    }
    if (data.containsKey('stop_lon')) {
      context.handle(
        _stopLonMeta,
        stopLon.isAcceptableOrUnknown(data['stop_lon']!, _stopLonMeta),
      );
    } else if (isInserting) {
      context.missing(_stopLonMeta);
    }
    if (data.containsKey('stop_code')) {
      context.handle(
        _stopCodeMeta,
        stopCode.isAcceptableOrUnknown(data['stop_code']!, _stopCodeMeta),
      );
    }
    if (data.containsKey('platform_code')) {
      context.handle(
        _platformCodeMeta,
        platformCode.isAcceptableOrUnknown(
          data['platform_code']!,
          _platformCodeMeta,
        ),
      );
    }
    if (data.containsKey('parent_station')) {
      context.handle(
        _parentStationMeta,
        parentStation.isAcceptableOrUnknown(
          data['parent_station']!,
          _parentStationMeta,
        ),
      );
    }
    if (data.containsKey('location_type')) {
      context.handle(
        _locationTypeMeta,
        locationType.isAcceptableOrUnknown(
          data['location_type']!,
          _locationTypeMeta,
        ),
      );
    }
    if (data.containsKey('wheelchair_boarding')) {
      context.handle(
        _wheelchairBoardingMeta,
        wheelchairBoarding.isAcceptableOrUnknown(
          data['wheelchair_boarding']!,
          _wheelchairBoardingMeta,
        ),
      );
    }
    if (data.containsKey('city')) {
      context.handle(
        _cityMeta,
        city.isAcceptableOrUnknown(data['city']!, _cityMeta),
      );
    }
    if (data.containsKey('operator_name')) {
      context.handle(
        _operatorNameMeta,
        operatorName.isAcceptableOrUnknown(
          data['operator_name']!,
          _operatorNameMeta,
        ),
      );
    }
    if (data.containsKey('rikshallplats_id')) {
      context.handle(
        _rikshallplatsIdMeta,
        rikshallplatsId.isAcceptableOrUnknown(
          data['rikshallplats_id']!,
          _rikshallplatsIdMeta,
        ),
      );
    }
    if (data.containsKey('rikshallplats_name')) {
      context.handle(
        _rikshallplatsNameMeta,
        rikshallplatsName.isAcceptableOrUnknown(
          data['rikshallplats_name']!,
          _rikshallplatsNameMeta,
        ),
      );
    }
    if (data.containsKey('available_modes')) {
      context.handle(
        _availableModesMeta,
        availableModes.isAcceptableOrUnknown(
          data['available_modes']!,
          _availableModesMeta,
        ),
      );
    }
    if (data.containsKey('platform_list')) {
      context.handle(
        _platformListMeta,
        platformList.isAcceptableOrUnknown(
          data['platform_list']!,
          _platformListMeta,
        ),
      );
    }
    if (data.containsKey('daily_passengers')) {
      context.handle(
        _dailyPassengersMeta,
        dailyPassengers.isAcceptableOrUnknown(
          data['daily_passengers']!,
          _dailyPassengersMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {stopId};
  @override
  Stop map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Stop(
      stopId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stop_id'],
      )!,
      stopName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stop_name'],
      )!,
      stopLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stop_lat'],
      )!,
      stopLon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stop_lon'],
      )!,
      stopCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stop_code'],
      ),
      platformCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}platform_code'],
      ),
      parentStation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_station'],
      ),
      locationType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}location_type'],
      )!,
      wheelchairBoarding: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wheelchair_boarding'],
      ),
      city: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city'],
      ),
      operatorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operator_name'],
      ),
      rikshallplatsId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rikshallplats_id'],
      ),
      rikshallplatsName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rikshallplats_name'],
      ),
      availableModes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}available_modes'],
      ),
      platformList: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}platform_list'],
      ),
      dailyPassengers: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_passengers'],
      ),
    );
  }

  @override
  $StopsTable createAlias(String alias) {
    return $StopsTable(attachedDatabase, alias);
  }
}

class Stop extends DataClass implements Insertable<Stop> {
  final String stopId;
  final String stopName;
  final double stopLat;
  final double stopLon;
  final String? stopCode;
  final String? platformCode;
  final String? parentStation;
  final int locationType;
  final int? wheelchairBoarding;
  final String? city;
  final String? operatorName;
  final String? rikshallplatsId;
  final String? rikshallplatsName;
  final String? availableModes;
  final String? platformList;
  final int? dailyPassengers;
  const Stop({
    required this.stopId,
    required this.stopName,
    required this.stopLat,
    required this.stopLon,
    this.stopCode,
    this.platformCode,
    this.parentStation,
    required this.locationType,
    this.wheelchairBoarding,
    this.city,
    this.operatorName,
    this.rikshallplatsId,
    this.rikshallplatsName,
    this.availableModes,
    this.platformList,
    this.dailyPassengers,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['stop_id'] = Variable<String>(stopId);
    map['stop_name'] = Variable<String>(stopName);
    map['stop_lat'] = Variable<double>(stopLat);
    map['stop_lon'] = Variable<double>(stopLon);
    if (!nullToAbsent || stopCode != null) {
      map['stop_code'] = Variable<String>(stopCode);
    }
    if (!nullToAbsent || platformCode != null) {
      map['platform_code'] = Variable<String>(platformCode);
    }
    if (!nullToAbsent || parentStation != null) {
      map['parent_station'] = Variable<String>(parentStation);
    }
    map['location_type'] = Variable<int>(locationType);
    if (!nullToAbsent || wheelchairBoarding != null) {
      map['wheelchair_boarding'] = Variable<int>(wheelchairBoarding);
    }
    if (!nullToAbsent || city != null) {
      map['city'] = Variable<String>(city);
    }
    if (!nullToAbsent || operatorName != null) {
      map['operator_name'] = Variable<String>(operatorName);
    }
    if (!nullToAbsent || rikshallplatsId != null) {
      map['rikshallplats_id'] = Variable<String>(rikshallplatsId);
    }
    if (!nullToAbsent || rikshallplatsName != null) {
      map['rikshallplats_name'] = Variable<String>(rikshallplatsName);
    }
    if (!nullToAbsent || availableModes != null) {
      map['available_modes'] = Variable<String>(availableModes);
    }
    if (!nullToAbsent || platformList != null) {
      map['platform_list'] = Variable<String>(platformList);
    }
    if (!nullToAbsent || dailyPassengers != null) {
      map['daily_passengers'] = Variable<int>(dailyPassengers);
    }
    return map;
  }

  StopsCompanion toCompanion(bool nullToAbsent) {
    return StopsCompanion(
      stopId: Value(stopId),
      stopName: Value(stopName),
      stopLat: Value(stopLat),
      stopLon: Value(stopLon),
      stopCode: stopCode == null && nullToAbsent
          ? const Value.absent()
          : Value(stopCode),
      platformCode: platformCode == null && nullToAbsent
          ? const Value.absent()
          : Value(platformCode),
      parentStation: parentStation == null && nullToAbsent
          ? const Value.absent()
          : Value(parentStation),
      locationType: Value(locationType),
      wheelchairBoarding: wheelchairBoarding == null && nullToAbsent
          ? const Value.absent()
          : Value(wheelchairBoarding),
      city: city == null && nullToAbsent ? const Value.absent() : Value(city),
      operatorName: operatorName == null && nullToAbsent
          ? const Value.absent()
          : Value(operatorName),
      rikshallplatsId: rikshallplatsId == null && nullToAbsent
          ? const Value.absent()
          : Value(rikshallplatsId),
      rikshallplatsName: rikshallplatsName == null && nullToAbsent
          ? const Value.absent()
          : Value(rikshallplatsName),
      availableModes: availableModes == null && nullToAbsent
          ? const Value.absent()
          : Value(availableModes),
      platformList: platformList == null && nullToAbsent
          ? const Value.absent()
          : Value(platformList),
      dailyPassengers: dailyPassengers == null && nullToAbsent
          ? const Value.absent()
          : Value(dailyPassengers),
    );
  }

  factory Stop.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Stop(
      stopId: serializer.fromJson<String>(json['stopId']),
      stopName: serializer.fromJson<String>(json['stopName']),
      stopLat: serializer.fromJson<double>(json['stopLat']),
      stopLon: serializer.fromJson<double>(json['stopLon']),
      stopCode: serializer.fromJson<String?>(json['stopCode']),
      platformCode: serializer.fromJson<String?>(json['platformCode']),
      parentStation: serializer.fromJson<String?>(json['parentStation']),
      locationType: serializer.fromJson<int>(json['locationType']),
      wheelchairBoarding: serializer.fromJson<int?>(json['wheelchairBoarding']),
      city: serializer.fromJson<String?>(json['city']),
      operatorName: serializer.fromJson<String?>(json['operatorName']),
      rikshallplatsId: serializer.fromJson<String?>(json['rikshallplatsId']),
      rikshallplatsName: serializer.fromJson<String?>(
        json['rikshallplatsName'],
      ),
      availableModes: serializer.fromJson<String?>(json['availableModes']),
      platformList: serializer.fromJson<String?>(json['platformList']),
      dailyPassengers: serializer.fromJson<int?>(json['dailyPassengers']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'stopId': serializer.toJson<String>(stopId),
      'stopName': serializer.toJson<String>(stopName),
      'stopLat': serializer.toJson<double>(stopLat),
      'stopLon': serializer.toJson<double>(stopLon),
      'stopCode': serializer.toJson<String?>(stopCode),
      'platformCode': serializer.toJson<String?>(platformCode),
      'parentStation': serializer.toJson<String?>(parentStation),
      'locationType': serializer.toJson<int>(locationType),
      'wheelchairBoarding': serializer.toJson<int?>(wheelchairBoarding),
      'city': serializer.toJson<String?>(city),
      'operatorName': serializer.toJson<String?>(operatorName),
      'rikshallplatsId': serializer.toJson<String?>(rikshallplatsId),
      'rikshallplatsName': serializer.toJson<String?>(rikshallplatsName),
      'availableModes': serializer.toJson<String?>(availableModes),
      'platformList': serializer.toJson<String?>(platformList),
      'dailyPassengers': serializer.toJson<int?>(dailyPassengers),
    };
  }

  Stop copyWith({
    String? stopId,
    String? stopName,
    double? stopLat,
    double? stopLon,
    Value<String?> stopCode = const Value.absent(),
    Value<String?> platformCode = const Value.absent(),
    Value<String?> parentStation = const Value.absent(),
    int? locationType,
    Value<int?> wheelchairBoarding = const Value.absent(),
    Value<String?> city = const Value.absent(),
    Value<String?> operatorName = const Value.absent(),
    Value<String?> rikshallplatsId = const Value.absent(),
    Value<String?> rikshallplatsName = const Value.absent(),
    Value<String?> availableModes = const Value.absent(),
    Value<String?> platformList = const Value.absent(),
    Value<int?> dailyPassengers = const Value.absent(),
  }) => Stop(
    stopId: stopId ?? this.stopId,
    stopName: stopName ?? this.stopName,
    stopLat: stopLat ?? this.stopLat,
    stopLon: stopLon ?? this.stopLon,
    stopCode: stopCode.present ? stopCode.value : this.stopCode,
    platformCode: platformCode.present ? platformCode.value : this.platformCode,
    parentStation: parentStation.present
        ? parentStation.value
        : this.parentStation,
    locationType: locationType ?? this.locationType,
    wheelchairBoarding: wheelchairBoarding.present
        ? wheelchairBoarding.value
        : this.wheelchairBoarding,
    city: city.present ? city.value : this.city,
    operatorName: operatorName.present ? operatorName.value : this.operatorName,
    rikshallplatsId: rikshallplatsId.present
        ? rikshallplatsId.value
        : this.rikshallplatsId,
    rikshallplatsName: rikshallplatsName.present
        ? rikshallplatsName.value
        : this.rikshallplatsName,
    availableModes: availableModes.present
        ? availableModes.value
        : this.availableModes,
    platformList: platformList.present ? platformList.value : this.platformList,
    dailyPassengers: dailyPassengers.present
        ? dailyPassengers.value
        : this.dailyPassengers,
  );
  Stop copyWithCompanion(StopsCompanion data) {
    return Stop(
      stopId: data.stopId.present ? data.stopId.value : this.stopId,
      stopName: data.stopName.present ? data.stopName.value : this.stopName,
      stopLat: data.stopLat.present ? data.stopLat.value : this.stopLat,
      stopLon: data.stopLon.present ? data.stopLon.value : this.stopLon,
      stopCode: data.stopCode.present ? data.stopCode.value : this.stopCode,
      platformCode: data.platformCode.present
          ? data.platformCode.value
          : this.platformCode,
      parentStation: data.parentStation.present
          ? data.parentStation.value
          : this.parentStation,
      locationType: data.locationType.present
          ? data.locationType.value
          : this.locationType,
      wheelchairBoarding: data.wheelchairBoarding.present
          ? data.wheelchairBoarding.value
          : this.wheelchairBoarding,
      city: data.city.present ? data.city.value : this.city,
      operatorName: data.operatorName.present
          ? data.operatorName.value
          : this.operatorName,
      rikshallplatsId: data.rikshallplatsId.present
          ? data.rikshallplatsId.value
          : this.rikshallplatsId,
      rikshallplatsName: data.rikshallplatsName.present
          ? data.rikshallplatsName.value
          : this.rikshallplatsName,
      availableModes: data.availableModes.present
          ? data.availableModes.value
          : this.availableModes,
      platformList: data.platformList.present
          ? data.platformList.value
          : this.platformList,
      dailyPassengers: data.dailyPassengers.present
          ? data.dailyPassengers.value
          : this.dailyPassengers,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Stop(')
          ..write('stopId: $stopId, ')
          ..write('stopName: $stopName, ')
          ..write('stopLat: $stopLat, ')
          ..write('stopLon: $stopLon, ')
          ..write('stopCode: $stopCode, ')
          ..write('platformCode: $platformCode, ')
          ..write('parentStation: $parentStation, ')
          ..write('locationType: $locationType, ')
          ..write('wheelchairBoarding: $wheelchairBoarding, ')
          ..write('city: $city, ')
          ..write('operatorName: $operatorName, ')
          ..write('rikshallplatsId: $rikshallplatsId, ')
          ..write('rikshallplatsName: $rikshallplatsName, ')
          ..write('availableModes: $availableModes, ')
          ..write('platformList: $platformList, ')
          ..write('dailyPassengers: $dailyPassengers')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    stopId,
    stopName,
    stopLat,
    stopLon,
    stopCode,
    platformCode,
    parentStation,
    locationType,
    wheelchairBoarding,
    city,
    operatorName,
    rikshallplatsId,
    rikshallplatsName,
    availableModes,
    platformList,
    dailyPassengers,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Stop &&
          other.stopId == this.stopId &&
          other.stopName == this.stopName &&
          other.stopLat == this.stopLat &&
          other.stopLon == this.stopLon &&
          other.stopCode == this.stopCode &&
          other.platformCode == this.platformCode &&
          other.parentStation == this.parentStation &&
          other.locationType == this.locationType &&
          other.wheelchairBoarding == this.wheelchairBoarding &&
          other.city == this.city &&
          other.operatorName == this.operatorName &&
          other.rikshallplatsId == this.rikshallplatsId &&
          other.rikshallplatsName == this.rikshallplatsName &&
          other.availableModes == this.availableModes &&
          other.platformList == this.platformList &&
          other.dailyPassengers == this.dailyPassengers);
}

class StopsCompanion extends UpdateCompanion<Stop> {
  final Value<String> stopId;
  final Value<String> stopName;
  final Value<double> stopLat;
  final Value<double> stopLon;
  final Value<String?> stopCode;
  final Value<String?> platformCode;
  final Value<String?> parentStation;
  final Value<int> locationType;
  final Value<int?> wheelchairBoarding;
  final Value<String?> city;
  final Value<String?> operatorName;
  final Value<String?> rikshallplatsId;
  final Value<String?> rikshallplatsName;
  final Value<String?> availableModes;
  final Value<String?> platformList;
  final Value<int?> dailyPassengers;
  final Value<int> rowid;
  const StopsCompanion({
    this.stopId = const Value.absent(),
    this.stopName = const Value.absent(),
    this.stopLat = const Value.absent(),
    this.stopLon = const Value.absent(),
    this.stopCode = const Value.absent(),
    this.platformCode = const Value.absent(),
    this.parentStation = const Value.absent(),
    this.locationType = const Value.absent(),
    this.wheelchairBoarding = const Value.absent(),
    this.city = const Value.absent(),
    this.operatorName = const Value.absent(),
    this.rikshallplatsId = const Value.absent(),
    this.rikshallplatsName = const Value.absent(),
    this.availableModes = const Value.absent(),
    this.platformList = const Value.absent(),
    this.dailyPassengers = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StopsCompanion.insert({
    required String stopId,
    required String stopName,
    required double stopLat,
    required double stopLon,
    this.stopCode = const Value.absent(),
    this.platformCode = const Value.absent(),
    this.parentStation = const Value.absent(),
    this.locationType = const Value.absent(),
    this.wheelchairBoarding = const Value.absent(),
    this.city = const Value.absent(),
    this.operatorName = const Value.absent(),
    this.rikshallplatsId = const Value.absent(),
    this.rikshallplatsName = const Value.absent(),
    this.availableModes = const Value.absent(),
    this.platformList = const Value.absent(),
    this.dailyPassengers = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : stopId = Value(stopId),
       stopName = Value(stopName),
       stopLat = Value(stopLat),
       stopLon = Value(stopLon);
  static Insertable<Stop> custom({
    Expression<String>? stopId,
    Expression<String>? stopName,
    Expression<double>? stopLat,
    Expression<double>? stopLon,
    Expression<String>? stopCode,
    Expression<String>? platformCode,
    Expression<String>? parentStation,
    Expression<int>? locationType,
    Expression<int>? wheelchairBoarding,
    Expression<String>? city,
    Expression<String>? operatorName,
    Expression<String>? rikshallplatsId,
    Expression<String>? rikshallplatsName,
    Expression<String>? availableModes,
    Expression<String>? platformList,
    Expression<int>? dailyPassengers,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (stopId != null) 'stop_id': stopId,
      if (stopName != null) 'stop_name': stopName,
      if (stopLat != null) 'stop_lat': stopLat,
      if (stopLon != null) 'stop_lon': stopLon,
      if (stopCode != null) 'stop_code': stopCode,
      if (platformCode != null) 'platform_code': platformCode,
      if (parentStation != null) 'parent_station': parentStation,
      if (locationType != null) 'location_type': locationType,
      if (wheelchairBoarding != null) 'wheelchair_boarding': wheelchairBoarding,
      if (city != null) 'city': city,
      if (operatorName != null) 'operator_name': operatorName,
      if (rikshallplatsId != null) 'rikshallplats_id': rikshallplatsId,
      if (rikshallplatsName != null) 'rikshallplats_name': rikshallplatsName,
      if (availableModes != null) 'available_modes': availableModes,
      if (platformList != null) 'platform_list': platformList,
      if (dailyPassengers != null) 'daily_passengers': dailyPassengers,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StopsCompanion copyWith({
    Value<String>? stopId,
    Value<String>? stopName,
    Value<double>? stopLat,
    Value<double>? stopLon,
    Value<String?>? stopCode,
    Value<String?>? platformCode,
    Value<String?>? parentStation,
    Value<int>? locationType,
    Value<int?>? wheelchairBoarding,
    Value<String?>? city,
    Value<String?>? operatorName,
    Value<String?>? rikshallplatsId,
    Value<String?>? rikshallplatsName,
    Value<String?>? availableModes,
    Value<String?>? platformList,
    Value<int?>? dailyPassengers,
    Value<int>? rowid,
  }) {
    return StopsCompanion(
      stopId: stopId ?? this.stopId,
      stopName: stopName ?? this.stopName,
      stopLat: stopLat ?? this.stopLat,
      stopLon: stopLon ?? this.stopLon,
      stopCode: stopCode ?? this.stopCode,
      platformCode: platformCode ?? this.platformCode,
      parentStation: parentStation ?? this.parentStation,
      locationType: locationType ?? this.locationType,
      wheelchairBoarding: wheelchairBoarding ?? this.wheelchairBoarding,
      city: city ?? this.city,
      operatorName: operatorName ?? this.operatorName,
      rikshallplatsId: rikshallplatsId ?? this.rikshallplatsId,
      rikshallplatsName: rikshallplatsName ?? this.rikshallplatsName,
      availableModes: availableModes ?? this.availableModes,
      platformList: platformList ?? this.platformList,
      dailyPassengers: dailyPassengers ?? this.dailyPassengers,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (stopId.present) {
      map['stop_id'] = Variable<String>(stopId.value);
    }
    if (stopName.present) {
      map['stop_name'] = Variable<String>(stopName.value);
    }
    if (stopLat.present) {
      map['stop_lat'] = Variable<double>(stopLat.value);
    }
    if (stopLon.present) {
      map['stop_lon'] = Variable<double>(stopLon.value);
    }
    if (stopCode.present) {
      map['stop_code'] = Variable<String>(stopCode.value);
    }
    if (platformCode.present) {
      map['platform_code'] = Variable<String>(platformCode.value);
    }
    if (parentStation.present) {
      map['parent_station'] = Variable<String>(parentStation.value);
    }
    if (locationType.present) {
      map['location_type'] = Variable<int>(locationType.value);
    }
    if (wheelchairBoarding.present) {
      map['wheelchair_boarding'] = Variable<int>(wheelchairBoarding.value);
    }
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (operatorName.present) {
      map['operator_name'] = Variable<String>(operatorName.value);
    }
    if (rikshallplatsId.present) {
      map['rikshallplats_id'] = Variable<String>(rikshallplatsId.value);
    }
    if (rikshallplatsName.present) {
      map['rikshallplats_name'] = Variable<String>(rikshallplatsName.value);
    }
    if (availableModes.present) {
      map['available_modes'] = Variable<String>(availableModes.value);
    }
    if (platformList.present) {
      map['platform_list'] = Variable<String>(platformList.value);
    }
    if (dailyPassengers.present) {
      map['daily_passengers'] = Variable<int>(dailyPassengers.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StopsCompanion(')
          ..write('stopId: $stopId, ')
          ..write('stopName: $stopName, ')
          ..write('stopLat: $stopLat, ')
          ..write('stopLon: $stopLon, ')
          ..write('stopCode: $stopCode, ')
          ..write('platformCode: $platformCode, ')
          ..write('parentStation: $parentStation, ')
          ..write('locationType: $locationType, ')
          ..write('wheelchairBoarding: $wheelchairBoarding, ')
          ..write('city: $city, ')
          ..write('operatorName: $operatorName, ')
          ..write('rikshallplatsId: $rikshallplatsId, ')
          ..write('rikshallplatsName: $rikshallplatsName, ')
          ..write('availableModes: $availableModes, ')
          ..write('platformList: $platformList, ')
          ..write('dailyPassengers: $dailyPassengers, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RoutesTable extends Routes with TableInfo<$RoutesTable, Route> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoutesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _routeIdMeta = const VerificationMeta(
    'routeId',
  );
  @override
  late final GeneratedColumn<String> routeId = GeneratedColumn<String>(
    'route_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _agencyIdMeta = const VerificationMeta(
    'agencyId',
  );
  @override
  late final GeneratedColumn<String> agencyId = GeneratedColumn<String>(
    'agency_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES agencies (agency_id)',
    ),
  );
  static const VerificationMeta _routeShortNameMeta = const VerificationMeta(
    'routeShortName',
  );
  @override
  late final GeneratedColumn<String> routeShortName = GeneratedColumn<String>(
    'route_short_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _routeLongNameMeta = const VerificationMeta(
    'routeLongName',
  );
  @override
  late final GeneratedColumn<String> routeLongName = GeneratedColumn<String>(
    'route_long_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _routeTypeMeta = const VerificationMeta(
    'routeType',
  );
  @override
  late final GeneratedColumn<int> routeType = GeneratedColumn<int>(
    'route_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    routeId,
    agencyId,
    routeShortName,
    routeLongName,
    routeType,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'routes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Route> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('route_id')) {
      context.handle(
        _routeIdMeta,
        routeId.isAcceptableOrUnknown(data['route_id']!, _routeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_routeIdMeta);
    }
    if (data.containsKey('agency_id')) {
      context.handle(
        _agencyIdMeta,
        agencyId.isAcceptableOrUnknown(data['agency_id']!, _agencyIdMeta),
      );
    }
    if (data.containsKey('route_short_name')) {
      context.handle(
        _routeShortNameMeta,
        routeShortName.isAcceptableOrUnknown(
          data['route_short_name']!,
          _routeShortNameMeta,
        ),
      );
    }
    if (data.containsKey('route_long_name')) {
      context.handle(
        _routeLongNameMeta,
        routeLongName.isAcceptableOrUnknown(
          data['route_long_name']!,
          _routeLongNameMeta,
        ),
      );
    }
    if (data.containsKey('route_type')) {
      context.handle(
        _routeTypeMeta,
        routeType.isAcceptableOrUnknown(data['route_type']!, _routeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_routeTypeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {routeId};
  @override
  Route map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Route(
      routeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route_id'],
      )!,
      agencyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agency_id'],
      ),
      routeShortName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route_short_name'],
      ),
      routeLongName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route_long_name'],
      ),
      routeType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}route_type'],
      )!,
    );
  }

  @override
  $RoutesTable createAlias(String alias) {
    return $RoutesTable(attachedDatabase, alias);
  }
}

class Route extends DataClass implements Insertable<Route> {
  final String routeId;
  final String? agencyId;
  final String? routeShortName;
  final String? routeLongName;
  final int routeType;
  const Route({
    required this.routeId,
    this.agencyId,
    this.routeShortName,
    this.routeLongName,
    required this.routeType,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['route_id'] = Variable<String>(routeId);
    if (!nullToAbsent || agencyId != null) {
      map['agency_id'] = Variable<String>(agencyId);
    }
    if (!nullToAbsent || routeShortName != null) {
      map['route_short_name'] = Variable<String>(routeShortName);
    }
    if (!nullToAbsent || routeLongName != null) {
      map['route_long_name'] = Variable<String>(routeLongName);
    }
    map['route_type'] = Variable<int>(routeType);
    return map;
  }

  RoutesCompanion toCompanion(bool nullToAbsent) {
    return RoutesCompanion(
      routeId: Value(routeId),
      agencyId: agencyId == null && nullToAbsent
          ? const Value.absent()
          : Value(agencyId),
      routeShortName: routeShortName == null && nullToAbsent
          ? const Value.absent()
          : Value(routeShortName),
      routeLongName: routeLongName == null && nullToAbsent
          ? const Value.absent()
          : Value(routeLongName),
      routeType: Value(routeType),
    );
  }

  factory Route.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Route(
      routeId: serializer.fromJson<String>(json['routeId']),
      agencyId: serializer.fromJson<String?>(json['agencyId']),
      routeShortName: serializer.fromJson<String?>(json['routeShortName']),
      routeLongName: serializer.fromJson<String?>(json['routeLongName']),
      routeType: serializer.fromJson<int>(json['routeType']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'routeId': serializer.toJson<String>(routeId),
      'agencyId': serializer.toJson<String?>(agencyId),
      'routeShortName': serializer.toJson<String?>(routeShortName),
      'routeLongName': serializer.toJson<String?>(routeLongName),
      'routeType': serializer.toJson<int>(routeType),
    };
  }

  Route copyWith({
    String? routeId,
    Value<String?> agencyId = const Value.absent(),
    Value<String?> routeShortName = const Value.absent(),
    Value<String?> routeLongName = const Value.absent(),
    int? routeType,
  }) => Route(
    routeId: routeId ?? this.routeId,
    agencyId: agencyId.present ? agencyId.value : this.agencyId,
    routeShortName: routeShortName.present
        ? routeShortName.value
        : this.routeShortName,
    routeLongName: routeLongName.present
        ? routeLongName.value
        : this.routeLongName,
    routeType: routeType ?? this.routeType,
  );
  Route copyWithCompanion(RoutesCompanion data) {
    return Route(
      routeId: data.routeId.present ? data.routeId.value : this.routeId,
      agencyId: data.agencyId.present ? data.agencyId.value : this.agencyId,
      routeShortName: data.routeShortName.present
          ? data.routeShortName.value
          : this.routeShortName,
      routeLongName: data.routeLongName.present
          ? data.routeLongName.value
          : this.routeLongName,
      routeType: data.routeType.present ? data.routeType.value : this.routeType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Route(')
          ..write('routeId: $routeId, ')
          ..write('agencyId: $agencyId, ')
          ..write('routeShortName: $routeShortName, ')
          ..write('routeLongName: $routeLongName, ')
          ..write('routeType: $routeType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(routeId, agencyId, routeShortName, routeLongName, routeType);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Route &&
          other.routeId == this.routeId &&
          other.agencyId == this.agencyId &&
          other.routeShortName == this.routeShortName &&
          other.routeLongName == this.routeLongName &&
          other.routeType == this.routeType);
}

class RoutesCompanion extends UpdateCompanion<Route> {
  final Value<String> routeId;
  final Value<String?> agencyId;
  final Value<String?> routeShortName;
  final Value<String?> routeLongName;
  final Value<int> routeType;
  final Value<int> rowid;
  const RoutesCompanion({
    this.routeId = const Value.absent(),
    this.agencyId = const Value.absent(),
    this.routeShortName = const Value.absent(),
    this.routeLongName = const Value.absent(),
    this.routeType = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoutesCompanion.insert({
    required String routeId,
    this.agencyId = const Value.absent(),
    this.routeShortName = const Value.absent(),
    this.routeLongName = const Value.absent(),
    required int routeType,
    this.rowid = const Value.absent(),
  }) : routeId = Value(routeId),
       routeType = Value(routeType);
  static Insertable<Route> custom({
    Expression<String>? routeId,
    Expression<String>? agencyId,
    Expression<String>? routeShortName,
    Expression<String>? routeLongName,
    Expression<int>? routeType,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (routeId != null) 'route_id': routeId,
      if (agencyId != null) 'agency_id': agencyId,
      if (routeShortName != null) 'route_short_name': routeShortName,
      if (routeLongName != null) 'route_long_name': routeLongName,
      if (routeType != null) 'route_type': routeType,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoutesCompanion copyWith({
    Value<String>? routeId,
    Value<String?>? agencyId,
    Value<String?>? routeShortName,
    Value<String?>? routeLongName,
    Value<int>? routeType,
    Value<int>? rowid,
  }) {
    return RoutesCompanion(
      routeId: routeId ?? this.routeId,
      agencyId: agencyId ?? this.agencyId,
      routeShortName: routeShortName ?? this.routeShortName,
      routeLongName: routeLongName ?? this.routeLongName,
      routeType: routeType ?? this.routeType,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (routeId.present) {
      map['route_id'] = Variable<String>(routeId.value);
    }
    if (agencyId.present) {
      map['agency_id'] = Variable<String>(agencyId.value);
    }
    if (routeShortName.present) {
      map['route_short_name'] = Variable<String>(routeShortName.value);
    }
    if (routeLongName.present) {
      map['route_long_name'] = Variable<String>(routeLongName.value);
    }
    if (routeType.present) {
      map['route_type'] = Variable<int>(routeType.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoutesCompanion(')
          ..write('routeId: $routeId, ')
          ..write('agencyId: $agencyId, ')
          ..write('routeShortName: $routeShortName, ')
          ..write('routeLongName: $routeLongName, ')
          ..write('routeType: $routeType, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TripsTable extends Trips with TableInfo<$TripsTable, Trip> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TripsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _routeIdMeta = const VerificationMeta(
    'routeId',
  );
  @override
  late final GeneratedColumn<String> routeId = GeneratedColumn<String>(
    'route_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES routes (route_id)',
    ),
  );
  static const VerificationMeta _serviceIdMeta = const VerificationMeta(
    'serviceId',
  );
  @override
  late final GeneratedColumn<String> serviceId = GeneratedColumn<String>(
    'service_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tripHeadsignMeta = const VerificationMeta(
    'tripHeadsign',
  );
  @override
  late final GeneratedColumn<String> tripHeadsign = GeneratedColumn<String>(
    'trip_headsign',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _directionIdMeta = const VerificationMeta(
    'directionId',
  );
  @override
  late final GeneratedColumn<int> directionId = GeneratedColumn<int>(
    'direction_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _shapeIdMeta = const VerificationMeta(
    'shapeId',
  );
  @override
  late final GeneratedColumn<String> shapeId = GeneratedColumn<String>(
    'shape_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tripShortNameMeta = const VerificationMeta(
    'tripShortName',
  );
  @override
  late final GeneratedColumn<String> tripShortName = GeneratedColumn<String>(
    'trip_short_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tripId,
    routeId,
    serviceId,
    tripHeadsign,
    directionId,
    shapeId,
    tripShortName,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trips';
  @override
  VerificationContext validateIntegrity(
    Insertable<Trip> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('route_id')) {
      context.handle(
        _routeIdMeta,
        routeId.isAcceptableOrUnknown(data['route_id']!, _routeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_routeIdMeta);
    }
    if (data.containsKey('service_id')) {
      context.handle(
        _serviceIdMeta,
        serviceId.isAcceptableOrUnknown(data['service_id']!, _serviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serviceIdMeta);
    }
    if (data.containsKey('trip_headsign')) {
      context.handle(
        _tripHeadsignMeta,
        tripHeadsign.isAcceptableOrUnknown(
          data['trip_headsign']!,
          _tripHeadsignMeta,
        ),
      );
    }
    if (data.containsKey('direction_id')) {
      context.handle(
        _directionIdMeta,
        directionId.isAcceptableOrUnknown(
          data['direction_id']!,
          _directionIdMeta,
        ),
      );
    }
    if (data.containsKey('shape_id')) {
      context.handle(
        _shapeIdMeta,
        shapeId.isAcceptableOrUnknown(data['shape_id']!, _shapeIdMeta),
      );
    }
    if (data.containsKey('trip_short_name')) {
      context.handle(
        _tripShortNameMeta,
        tripShortName.isAcceptableOrUnknown(
          data['trip_short_name']!,
          _tripShortNameMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tripId};
  @override
  Trip map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Trip(
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      )!,
      routeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route_id'],
      )!,
      serviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}service_id'],
      )!,
      tripHeadsign: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_headsign'],
      ),
      directionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}direction_id'],
      ),
      shapeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shape_id'],
      ),
      tripShortName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_short_name'],
      ),
    );
  }

  @override
  $TripsTable createAlias(String alias) {
    return $TripsTable(attachedDatabase, alias);
  }
}

class Trip extends DataClass implements Insertable<Trip> {
  final String tripId;
  final String routeId;
  final String serviceId;
  final String? tripHeadsign;
  final int? directionId;
  final String? shapeId;
  final String? tripShortName;
  const Trip({
    required this.tripId,
    required this.routeId,
    required this.serviceId,
    this.tripHeadsign,
    this.directionId,
    this.shapeId,
    this.tripShortName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['trip_id'] = Variable<String>(tripId);
    map['route_id'] = Variable<String>(routeId);
    map['service_id'] = Variable<String>(serviceId);
    if (!nullToAbsent || tripHeadsign != null) {
      map['trip_headsign'] = Variable<String>(tripHeadsign);
    }
    if (!nullToAbsent || directionId != null) {
      map['direction_id'] = Variable<int>(directionId);
    }
    if (!nullToAbsent || shapeId != null) {
      map['shape_id'] = Variable<String>(shapeId);
    }
    if (!nullToAbsent || tripShortName != null) {
      map['trip_short_name'] = Variable<String>(tripShortName);
    }
    return map;
  }

  TripsCompanion toCompanion(bool nullToAbsent) {
    return TripsCompanion(
      tripId: Value(tripId),
      routeId: Value(routeId),
      serviceId: Value(serviceId),
      tripHeadsign: tripHeadsign == null && nullToAbsent
          ? const Value.absent()
          : Value(tripHeadsign),
      directionId: directionId == null && nullToAbsent
          ? const Value.absent()
          : Value(directionId),
      shapeId: shapeId == null && nullToAbsent
          ? const Value.absent()
          : Value(shapeId),
      tripShortName: tripShortName == null && nullToAbsent
          ? const Value.absent()
          : Value(tripShortName),
    );
  }

  factory Trip.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Trip(
      tripId: serializer.fromJson<String>(json['tripId']),
      routeId: serializer.fromJson<String>(json['routeId']),
      serviceId: serializer.fromJson<String>(json['serviceId']),
      tripHeadsign: serializer.fromJson<String?>(json['tripHeadsign']),
      directionId: serializer.fromJson<int?>(json['directionId']),
      shapeId: serializer.fromJson<String?>(json['shapeId']),
      tripShortName: serializer.fromJson<String?>(json['tripShortName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tripId': serializer.toJson<String>(tripId),
      'routeId': serializer.toJson<String>(routeId),
      'serviceId': serializer.toJson<String>(serviceId),
      'tripHeadsign': serializer.toJson<String?>(tripHeadsign),
      'directionId': serializer.toJson<int?>(directionId),
      'shapeId': serializer.toJson<String?>(shapeId),
      'tripShortName': serializer.toJson<String?>(tripShortName),
    };
  }

  Trip copyWith({
    String? tripId,
    String? routeId,
    String? serviceId,
    Value<String?> tripHeadsign = const Value.absent(),
    Value<int?> directionId = const Value.absent(),
    Value<String?> shapeId = const Value.absent(),
    Value<String?> tripShortName = const Value.absent(),
  }) => Trip(
    tripId: tripId ?? this.tripId,
    routeId: routeId ?? this.routeId,
    serviceId: serviceId ?? this.serviceId,
    tripHeadsign: tripHeadsign.present ? tripHeadsign.value : this.tripHeadsign,
    directionId: directionId.present ? directionId.value : this.directionId,
    shapeId: shapeId.present ? shapeId.value : this.shapeId,
    tripShortName: tripShortName.present
        ? tripShortName.value
        : this.tripShortName,
  );
  Trip copyWithCompanion(TripsCompanion data) {
    return Trip(
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      routeId: data.routeId.present ? data.routeId.value : this.routeId,
      serviceId: data.serviceId.present ? data.serviceId.value : this.serviceId,
      tripHeadsign: data.tripHeadsign.present
          ? data.tripHeadsign.value
          : this.tripHeadsign,
      directionId: data.directionId.present
          ? data.directionId.value
          : this.directionId,
      shapeId: data.shapeId.present ? data.shapeId.value : this.shapeId,
      tripShortName: data.tripShortName.present
          ? data.tripShortName.value
          : this.tripShortName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Trip(')
          ..write('tripId: $tripId, ')
          ..write('routeId: $routeId, ')
          ..write('serviceId: $serviceId, ')
          ..write('tripHeadsign: $tripHeadsign, ')
          ..write('directionId: $directionId, ')
          ..write('shapeId: $shapeId, ')
          ..write('tripShortName: $tripShortName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tripId,
    routeId,
    serviceId,
    tripHeadsign,
    directionId,
    shapeId,
    tripShortName,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Trip &&
          other.tripId == this.tripId &&
          other.routeId == this.routeId &&
          other.serviceId == this.serviceId &&
          other.tripHeadsign == this.tripHeadsign &&
          other.directionId == this.directionId &&
          other.shapeId == this.shapeId &&
          other.tripShortName == this.tripShortName);
}

class TripsCompanion extends UpdateCompanion<Trip> {
  final Value<String> tripId;
  final Value<String> routeId;
  final Value<String> serviceId;
  final Value<String?> tripHeadsign;
  final Value<int?> directionId;
  final Value<String?> shapeId;
  final Value<String?> tripShortName;
  final Value<int> rowid;
  const TripsCompanion({
    this.tripId = const Value.absent(),
    this.routeId = const Value.absent(),
    this.serviceId = const Value.absent(),
    this.tripHeadsign = const Value.absent(),
    this.directionId = const Value.absent(),
    this.shapeId = const Value.absent(),
    this.tripShortName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TripsCompanion.insert({
    required String tripId,
    required String routeId,
    required String serviceId,
    this.tripHeadsign = const Value.absent(),
    this.directionId = const Value.absent(),
    this.shapeId = const Value.absent(),
    this.tripShortName = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tripId = Value(tripId),
       routeId = Value(routeId),
       serviceId = Value(serviceId);
  static Insertable<Trip> custom({
    Expression<String>? tripId,
    Expression<String>? routeId,
    Expression<String>? serviceId,
    Expression<String>? tripHeadsign,
    Expression<int>? directionId,
    Expression<String>? shapeId,
    Expression<String>? tripShortName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tripId != null) 'trip_id': tripId,
      if (routeId != null) 'route_id': routeId,
      if (serviceId != null) 'service_id': serviceId,
      if (tripHeadsign != null) 'trip_headsign': tripHeadsign,
      if (directionId != null) 'direction_id': directionId,
      if (shapeId != null) 'shape_id': shapeId,
      if (tripShortName != null) 'trip_short_name': tripShortName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TripsCompanion copyWith({
    Value<String>? tripId,
    Value<String>? routeId,
    Value<String>? serviceId,
    Value<String?>? tripHeadsign,
    Value<int?>? directionId,
    Value<String?>? shapeId,
    Value<String?>? tripShortName,
    Value<int>? rowid,
  }) {
    return TripsCompanion(
      tripId: tripId ?? this.tripId,
      routeId: routeId ?? this.routeId,
      serviceId: serviceId ?? this.serviceId,
      tripHeadsign: tripHeadsign ?? this.tripHeadsign,
      directionId: directionId ?? this.directionId,
      shapeId: shapeId ?? this.shapeId,
      tripShortName: tripShortName ?? this.tripShortName,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (routeId.present) {
      map['route_id'] = Variable<String>(routeId.value);
    }
    if (serviceId.present) {
      map['service_id'] = Variable<String>(serviceId.value);
    }
    if (tripHeadsign.present) {
      map['trip_headsign'] = Variable<String>(tripHeadsign.value);
    }
    if (directionId.present) {
      map['direction_id'] = Variable<int>(directionId.value);
    }
    if (shapeId.present) {
      map['shape_id'] = Variable<String>(shapeId.value);
    }
    if (tripShortName.present) {
      map['trip_short_name'] = Variable<String>(tripShortName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TripsCompanion(')
          ..write('tripId: $tripId, ')
          ..write('routeId: $routeId, ')
          ..write('serviceId: $serviceId, ')
          ..write('tripHeadsign: $tripHeadsign, ')
          ..write('directionId: $directionId, ')
          ..write('shapeId: $shapeId, ')
          ..write('tripShortName: $tripShortName, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StopTimesTable extends StopTimes
    with TableInfo<$StopTimesTable, StopTime> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StopTimesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES trips (trip_id)',
    ),
  );
  static const VerificationMeta _stopSequenceMeta = const VerificationMeta(
    'stopSequence',
  );
  @override
  late final GeneratedColumn<int> stopSequence = GeneratedColumn<int>(
    'stop_sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stopIdMeta = const VerificationMeta('stopId');
  @override
  late final GeneratedColumn<String> stopId = GeneratedColumn<String>(
    'stop_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stops (stop_id)',
    ),
  );
  static const VerificationMeta _arrivalTimeMeta = const VerificationMeta(
    'arrivalTime',
  );
  @override
  late final GeneratedColumn<String> arrivalTime = GeneratedColumn<String>(
    'arrival_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _departureTimeMeta = const VerificationMeta(
    'departureTime',
  );
  @override
  late final GeneratedColumn<String> departureTime = GeneratedColumn<String>(
    'departure_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stopHeadsignMeta = const VerificationMeta(
    'stopHeadsign',
  );
  @override
  late final GeneratedColumn<String> stopHeadsign = GeneratedColumn<String>(
    'stop_headsign',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pickupTypeMeta = const VerificationMeta(
    'pickupType',
  );
  @override
  late final GeneratedColumn<int> pickupType = GeneratedColumn<int>(
    'pickup_type',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dropOffTypeMeta = const VerificationMeta(
    'dropOffType',
  );
  @override
  late final GeneratedColumn<int> dropOffType = GeneratedColumn<int>(
    'drop_off_type',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tripId,
    stopSequence,
    stopId,
    arrivalTime,
    departureTime,
    stopHeadsign,
    pickupType,
    dropOffType,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stop_times';
  @override
  VerificationContext validateIntegrity(
    Insertable<StopTime> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('stop_sequence')) {
      context.handle(
        _stopSequenceMeta,
        stopSequence.isAcceptableOrUnknown(
          data['stop_sequence']!,
          _stopSequenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stopSequenceMeta);
    }
    if (data.containsKey('stop_id')) {
      context.handle(
        _stopIdMeta,
        stopId.isAcceptableOrUnknown(data['stop_id']!, _stopIdMeta),
      );
    } else if (isInserting) {
      context.missing(_stopIdMeta);
    }
    if (data.containsKey('arrival_time')) {
      context.handle(
        _arrivalTimeMeta,
        arrivalTime.isAcceptableOrUnknown(
          data['arrival_time']!,
          _arrivalTimeMeta,
        ),
      );
    }
    if (data.containsKey('departure_time')) {
      context.handle(
        _departureTimeMeta,
        departureTime.isAcceptableOrUnknown(
          data['departure_time']!,
          _departureTimeMeta,
        ),
      );
    }
    if (data.containsKey('stop_headsign')) {
      context.handle(
        _stopHeadsignMeta,
        stopHeadsign.isAcceptableOrUnknown(
          data['stop_headsign']!,
          _stopHeadsignMeta,
        ),
      );
    }
    if (data.containsKey('pickup_type')) {
      context.handle(
        _pickupTypeMeta,
        pickupType.isAcceptableOrUnknown(data['pickup_type']!, _pickupTypeMeta),
      );
    }
    if (data.containsKey('drop_off_type')) {
      context.handle(
        _dropOffTypeMeta,
        dropOffType.isAcceptableOrUnknown(
          data['drop_off_type']!,
          _dropOffTypeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tripId, stopSequence};
  @override
  StopTime map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StopTime(
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      )!,
      stopSequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stop_sequence'],
      )!,
      stopId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stop_id'],
      )!,
      arrivalTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}arrival_time'],
      ),
      departureTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}departure_time'],
      ),
      stopHeadsign: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stop_headsign'],
      ),
      pickupType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pickup_type'],
      ),
      dropOffType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}drop_off_type'],
      ),
    );
  }

  @override
  $StopTimesTable createAlias(String alias) {
    return $StopTimesTable(attachedDatabase, alias);
  }
}

class StopTime extends DataClass implements Insertable<StopTime> {
  final String tripId;
  final int stopSequence;
  final String stopId;
  final String? arrivalTime;
  final String? departureTime;
  final String? stopHeadsign;
  final int? pickupType;
  final int? dropOffType;
  const StopTime({
    required this.tripId,
    required this.stopSequence,
    required this.stopId,
    this.arrivalTime,
    this.departureTime,
    this.stopHeadsign,
    this.pickupType,
    this.dropOffType,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['trip_id'] = Variable<String>(tripId);
    map['stop_sequence'] = Variable<int>(stopSequence);
    map['stop_id'] = Variable<String>(stopId);
    if (!nullToAbsent || arrivalTime != null) {
      map['arrival_time'] = Variable<String>(arrivalTime);
    }
    if (!nullToAbsent || departureTime != null) {
      map['departure_time'] = Variable<String>(departureTime);
    }
    if (!nullToAbsent || stopHeadsign != null) {
      map['stop_headsign'] = Variable<String>(stopHeadsign);
    }
    if (!nullToAbsent || pickupType != null) {
      map['pickup_type'] = Variable<int>(pickupType);
    }
    if (!nullToAbsent || dropOffType != null) {
      map['drop_off_type'] = Variable<int>(dropOffType);
    }
    return map;
  }

  StopTimesCompanion toCompanion(bool nullToAbsent) {
    return StopTimesCompanion(
      tripId: Value(tripId),
      stopSequence: Value(stopSequence),
      stopId: Value(stopId),
      arrivalTime: arrivalTime == null && nullToAbsent
          ? const Value.absent()
          : Value(arrivalTime),
      departureTime: departureTime == null && nullToAbsent
          ? const Value.absent()
          : Value(departureTime),
      stopHeadsign: stopHeadsign == null && nullToAbsent
          ? const Value.absent()
          : Value(stopHeadsign),
      pickupType: pickupType == null && nullToAbsent
          ? const Value.absent()
          : Value(pickupType),
      dropOffType: dropOffType == null && nullToAbsent
          ? const Value.absent()
          : Value(dropOffType),
    );
  }

  factory StopTime.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StopTime(
      tripId: serializer.fromJson<String>(json['tripId']),
      stopSequence: serializer.fromJson<int>(json['stopSequence']),
      stopId: serializer.fromJson<String>(json['stopId']),
      arrivalTime: serializer.fromJson<String?>(json['arrivalTime']),
      departureTime: serializer.fromJson<String?>(json['departureTime']),
      stopHeadsign: serializer.fromJson<String?>(json['stopHeadsign']),
      pickupType: serializer.fromJson<int?>(json['pickupType']),
      dropOffType: serializer.fromJson<int?>(json['dropOffType']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tripId': serializer.toJson<String>(tripId),
      'stopSequence': serializer.toJson<int>(stopSequence),
      'stopId': serializer.toJson<String>(stopId),
      'arrivalTime': serializer.toJson<String?>(arrivalTime),
      'departureTime': serializer.toJson<String?>(departureTime),
      'stopHeadsign': serializer.toJson<String?>(stopHeadsign),
      'pickupType': serializer.toJson<int?>(pickupType),
      'dropOffType': serializer.toJson<int?>(dropOffType),
    };
  }

  StopTime copyWith({
    String? tripId,
    int? stopSequence,
    String? stopId,
    Value<String?> arrivalTime = const Value.absent(),
    Value<String?> departureTime = const Value.absent(),
    Value<String?> stopHeadsign = const Value.absent(),
    Value<int?> pickupType = const Value.absent(),
    Value<int?> dropOffType = const Value.absent(),
  }) => StopTime(
    tripId: tripId ?? this.tripId,
    stopSequence: stopSequence ?? this.stopSequence,
    stopId: stopId ?? this.stopId,
    arrivalTime: arrivalTime.present ? arrivalTime.value : this.arrivalTime,
    departureTime: departureTime.present
        ? departureTime.value
        : this.departureTime,
    stopHeadsign: stopHeadsign.present ? stopHeadsign.value : this.stopHeadsign,
    pickupType: pickupType.present ? pickupType.value : this.pickupType,
    dropOffType: dropOffType.present ? dropOffType.value : this.dropOffType,
  );
  StopTime copyWithCompanion(StopTimesCompanion data) {
    return StopTime(
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      stopSequence: data.stopSequence.present
          ? data.stopSequence.value
          : this.stopSequence,
      stopId: data.stopId.present ? data.stopId.value : this.stopId,
      arrivalTime: data.arrivalTime.present
          ? data.arrivalTime.value
          : this.arrivalTime,
      departureTime: data.departureTime.present
          ? data.departureTime.value
          : this.departureTime,
      stopHeadsign: data.stopHeadsign.present
          ? data.stopHeadsign.value
          : this.stopHeadsign,
      pickupType: data.pickupType.present
          ? data.pickupType.value
          : this.pickupType,
      dropOffType: data.dropOffType.present
          ? data.dropOffType.value
          : this.dropOffType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StopTime(')
          ..write('tripId: $tripId, ')
          ..write('stopSequence: $stopSequence, ')
          ..write('stopId: $stopId, ')
          ..write('arrivalTime: $arrivalTime, ')
          ..write('departureTime: $departureTime, ')
          ..write('stopHeadsign: $stopHeadsign, ')
          ..write('pickupType: $pickupType, ')
          ..write('dropOffType: $dropOffType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tripId,
    stopSequence,
    stopId,
    arrivalTime,
    departureTime,
    stopHeadsign,
    pickupType,
    dropOffType,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StopTime &&
          other.tripId == this.tripId &&
          other.stopSequence == this.stopSequence &&
          other.stopId == this.stopId &&
          other.arrivalTime == this.arrivalTime &&
          other.departureTime == this.departureTime &&
          other.stopHeadsign == this.stopHeadsign &&
          other.pickupType == this.pickupType &&
          other.dropOffType == this.dropOffType);
}

class StopTimesCompanion extends UpdateCompanion<StopTime> {
  final Value<String> tripId;
  final Value<int> stopSequence;
  final Value<String> stopId;
  final Value<String?> arrivalTime;
  final Value<String?> departureTime;
  final Value<String?> stopHeadsign;
  final Value<int?> pickupType;
  final Value<int?> dropOffType;
  final Value<int> rowid;
  const StopTimesCompanion({
    this.tripId = const Value.absent(),
    this.stopSequence = const Value.absent(),
    this.stopId = const Value.absent(),
    this.arrivalTime = const Value.absent(),
    this.departureTime = const Value.absent(),
    this.stopHeadsign = const Value.absent(),
    this.pickupType = const Value.absent(),
    this.dropOffType = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StopTimesCompanion.insert({
    required String tripId,
    required int stopSequence,
    required String stopId,
    this.arrivalTime = const Value.absent(),
    this.departureTime = const Value.absent(),
    this.stopHeadsign = const Value.absent(),
    this.pickupType = const Value.absent(),
    this.dropOffType = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tripId = Value(tripId),
       stopSequence = Value(stopSequence),
       stopId = Value(stopId);
  static Insertable<StopTime> custom({
    Expression<String>? tripId,
    Expression<int>? stopSequence,
    Expression<String>? stopId,
    Expression<String>? arrivalTime,
    Expression<String>? departureTime,
    Expression<String>? stopHeadsign,
    Expression<int>? pickupType,
    Expression<int>? dropOffType,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tripId != null) 'trip_id': tripId,
      if (stopSequence != null) 'stop_sequence': stopSequence,
      if (stopId != null) 'stop_id': stopId,
      if (arrivalTime != null) 'arrival_time': arrivalTime,
      if (departureTime != null) 'departure_time': departureTime,
      if (stopHeadsign != null) 'stop_headsign': stopHeadsign,
      if (pickupType != null) 'pickup_type': pickupType,
      if (dropOffType != null) 'drop_off_type': dropOffType,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StopTimesCompanion copyWith({
    Value<String>? tripId,
    Value<int>? stopSequence,
    Value<String>? stopId,
    Value<String?>? arrivalTime,
    Value<String?>? departureTime,
    Value<String?>? stopHeadsign,
    Value<int?>? pickupType,
    Value<int?>? dropOffType,
    Value<int>? rowid,
  }) {
    return StopTimesCompanion(
      tripId: tripId ?? this.tripId,
      stopSequence: stopSequence ?? this.stopSequence,
      stopId: stopId ?? this.stopId,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      departureTime: departureTime ?? this.departureTime,
      stopHeadsign: stopHeadsign ?? this.stopHeadsign,
      pickupType: pickupType ?? this.pickupType,
      dropOffType: dropOffType ?? this.dropOffType,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (stopSequence.present) {
      map['stop_sequence'] = Variable<int>(stopSequence.value);
    }
    if (stopId.present) {
      map['stop_id'] = Variable<String>(stopId.value);
    }
    if (arrivalTime.present) {
      map['arrival_time'] = Variable<String>(arrivalTime.value);
    }
    if (departureTime.present) {
      map['departure_time'] = Variable<String>(departureTime.value);
    }
    if (stopHeadsign.present) {
      map['stop_headsign'] = Variable<String>(stopHeadsign.value);
    }
    if (pickupType.present) {
      map['pickup_type'] = Variable<int>(pickupType.value);
    }
    if (dropOffType.present) {
      map['drop_off_type'] = Variable<int>(dropOffType.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StopTimesCompanion(')
          ..write('tripId: $tripId, ')
          ..write('stopSequence: $stopSequence, ')
          ..write('stopId: $stopId, ')
          ..write('arrivalTime: $arrivalTime, ')
          ..write('departureTime: $departureTime, ')
          ..write('stopHeadsign: $stopHeadsign, ')
          ..write('pickupType: $pickupType, ')
          ..write('dropOffType: $dropOffType, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShapesTable extends Shapes with TableInfo<$ShapesTable, Shape> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShapesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _shapeIdMeta = const VerificationMeta(
    'shapeId',
  );
  @override
  late final GeneratedColumn<String> shapeId = GeneratedColumn<String>(
    'shape_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shapePtSequenceMeta = const VerificationMeta(
    'shapePtSequence',
  );
  @override
  late final GeneratedColumn<int> shapePtSequence = GeneratedColumn<int>(
    'shape_pt_sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shapePtLatMeta = const VerificationMeta(
    'shapePtLat',
  );
  @override
  late final GeneratedColumn<double> shapePtLat = GeneratedColumn<double>(
    'shape_pt_lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shapePtLonMeta = const VerificationMeta(
    'shapePtLon',
  );
  @override
  late final GeneratedColumn<double> shapePtLon = GeneratedColumn<double>(
    'shape_pt_lon',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shapeDistTraveledMeta = const VerificationMeta(
    'shapeDistTraveled',
  );
  @override
  late final GeneratedColumn<double> shapeDistTraveled =
      GeneratedColumn<double>(
        'shape_dist_traveled',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    shapeId,
    shapePtSequence,
    shapePtLat,
    shapePtLon,
    shapeDistTraveled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shapes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Shape> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('shape_id')) {
      context.handle(
        _shapeIdMeta,
        shapeId.isAcceptableOrUnknown(data['shape_id']!, _shapeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shapeIdMeta);
    }
    if (data.containsKey('shape_pt_sequence')) {
      context.handle(
        _shapePtSequenceMeta,
        shapePtSequence.isAcceptableOrUnknown(
          data['shape_pt_sequence']!,
          _shapePtSequenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_shapePtSequenceMeta);
    }
    if (data.containsKey('shape_pt_lat')) {
      context.handle(
        _shapePtLatMeta,
        shapePtLat.isAcceptableOrUnknown(
          data['shape_pt_lat']!,
          _shapePtLatMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_shapePtLatMeta);
    }
    if (data.containsKey('shape_pt_lon')) {
      context.handle(
        _shapePtLonMeta,
        shapePtLon.isAcceptableOrUnknown(
          data['shape_pt_lon']!,
          _shapePtLonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_shapePtLonMeta);
    }
    if (data.containsKey('shape_dist_traveled')) {
      context.handle(
        _shapeDistTraveledMeta,
        shapeDistTraveled.isAcceptableOrUnknown(
          data['shape_dist_traveled']!,
          _shapeDistTraveledMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {shapeId, shapePtSequence};
  @override
  Shape map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Shape(
      shapeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shape_id'],
      )!,
      shapePtSequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shape_pt_sequence'],
      )!,
      shapePtLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}shape_pt_lat'],
      )!,
      shapePtLon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}shape_pt_lon'],
      )!,
      shapeDistTraveled: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}shape_dist_traveled'],
      ),
    );
  }

  @override
  $ShapesTable createAlias(String alias) {
    return $ShapesTable(attachedDatabase, alias);
  }
}

class Shape extends DataClass implements Insertable<Shape> {
  final String shapeId;
  final int shapePtSequence;
  final double shapePtLat;
  final double shapePtLon;
  final double? shapeDistTraveled;
  const Shape({
    required this.shapeId,
    required this.shapePtSequence,
    required this.shapePtLat,
    required this.shapePtLon,
    this.shapeDistTraveled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['shape_id'] = Variable<String>(shapeId);
    map['shape_pt_sequence'] = Variable<int>(shapePtSequence);
    map['shape_pt_lat'] = Variable<double>(shapePtLat);
    map['shape_pt_lon'] = Variable<double>(shapePtLon);
    if (!nullToAbsent || shapeDistTraveled != null) {
      map['shape_dist_traveled'] = Variable<double>(shapeDistTraveled);
    }
    return map;
  }

  ShapesCompanion toCompanion(bool nullToAbsent) {
    return ShapesCompanion(
      shapeId: Value(shapeId),
      shapePtSequence: Value(shapePtSequence),
      shapePtLat: Value(shapePtLat),
      shapePtLon: Value(shapePtLon),
      shapeDistTraveled: shapeDistTraveled == null && nullToAbsent
          ? const Value.absent()
          : Value(shapeDistTraveled),
    );
  }

  factory Shape.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Shape(
      shapeId: serializer.fromJson<String>(json['shapeId']),
      shapePtSequence: serializer.fromJson<int>(json['shapePtSequence']),
      shapePtLat: serializer.fromJson<double>(json['shapePtLat']),
      shapePtLon: serializer.fromJson<double>(json['shapePtLon']),
      shapeDistTraveled: serializer.fromJson<double?>(
        json['shapeDistTraveled'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'shapeId': serializer.toJson<String>(shapeId),
      'shapePtSequence': serializer.toJson<int>(shapePtSequence),
      'shapePtLat': serializer.toJson<double>(shapePtLat),
      'shapePtLon': serializer.toJson<double>(shapePtLon),
      'shapeDistTraveled': serializer.toJson<double?>(shapeDistTraveled),
    };
  }

  Shape copyWith({
    String? shapeId,
    int? shapePtSequence,
    double? shapePtLat,
    double? shapePtLon,
    Value<double?> shapeDistTraveled = const Value.absent(),
  }) => Shape(
    shapeId: shapeId ?? this.shapeId,
    shapePtSequence: shapePtSequence ?? this.shapePtSequence,
    shapePtLat: shapePtLat ?? this.shapePtLat,
    shapePtLon: shapePtLon ?? this.shapePtLon,
    shapeDistTraveled: shapeDistTraveled.present
        ? shapeDistTraveled.value
        : this.shapeDistTraveled,
  );
  Shape copyWithCompanion(ShapesCompanion data) {
    return Shape(
      shapeId: data.shapeId.present ? data.shapeId.value : this.shapeId,
      shapePtSequence: data.shapePtSequence.present
          ? data.shapePtSequence.value
          : this.shapePtSequence,
      shapePtLat: data.shapePtLat.present
          ? data.shapePtLat.value
          : this.shapePtLat,
      shapePtLon: data.shapePtLon.present
          ? data.shapePtLon.value
          : this.shapePtLon,
      shapeDistTraveled: data.shapeDistTraveled.present
          ? data.shapeDistTraveled.value
          : this.shapeDistTraveled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Shape(')
          ..write('shapeId: $shapeId, ')
          ..write('shapePtSequence: $shapePtSequence, ')
          ..write('shapePtLat: $shapePtLat, ')
          ..write('shapePtLon: $shapePtLon, ')
          ..write('shapeDistTraveled: $shapeDistTraveled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    shapeId,
    shapePtSequence,
    shapePtLat,
    shapePtLon,
    shapeDistTraveled,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Shape &&
          other.shapeId == this.shapeId &&
          other.shapePtSequence == this.shapePtSequence &&
          other.shapePtLat == this.shapePtLat &&
          other.shapePtLon == this.shapePtLon &&
          other.shapeDistTraveled == this.shapeDistTraveled);
}

class ShapesCompanion extends UpdateCompanion<Shape> {
  final Value<String> shapeId;
  final Value<int> shapePtSequence;
  final Value<double> shapePtLat;
  final Value<double> shapePtLon;
  final Value<double?> shapeDistTraveled;
  final Value<int> rowid;
  const ShapesCompanion({
    this.shapeId = const Value.absent(),
    this.shapePtSequence = const Value.absent(),
    this.shapePtLat = const Value.absent(),
    this.shapePtLon = const Value.absent(),
    this.shapeDistTraveled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShapesCompanion.insert({
    required String shapeId,
    required int shapePtSequence,
    required double shapePtLat,
    required double shapePtLon,
    this.shapeDistTraveled = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : shapeId = Value(shapeId),
       shapePtSequence = Value(shapePtSequence),
       shapePtLat = Value(shapePtLat),
       shapePtLon = Value(shapePtLon);
  static Insertable<Shape> custom({
    Expression<String>? shapeId,
    Expression<int>? shapePtSequence,
    Expression<double>? shapePtLat,
    Expression<double>? shapePtLon,
    Expression<double>? shapeDistTraveled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (shapeId != null) 'shape_id': shapeId,
      if (shapePtSequence != null) 'shape_pt_sequence': shapePtSequence,
      if (shapePtLat != null) 'shape_pt_lat': shapePtLat,
      if (shapePtLon != null) 'shape_pt_lon': shapePtLon,
      if (shapeDistTraveled != null) 'shape_dist_traveled': shapeDistTraveled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShapesCompanion copyWith({
    Value<String>? shapeId,
    Value<int>? shapePtSequence,
    Value<double>? shapePtLat,
    Value<double>? shapePtLon,
    Value<double?>? shapeDistTraveled,
    Value<int>? rowid,
  }) {
    return ShapesCompanion(
      shapeId: shapeId ?? this.shapeId,
      shapePtSequence: shapePtSequence ?? this.shapePtSequence,
      shapePtLat: shapePtLat ?? this.shapePtLat,
      shapePtLon: shapePtLon ?? this.shapePtLon,
      shapeDistTraveled: shapeDistTraveled ?? this.shapeDistTraveled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (shapeId.present) {
      map['shape_id'] = Variable<String>(shapeId.value);
    }
    if (shapePtSequence.present) {
      map['shape_pt_sequence'] = Variable<int>(shapePtSequence.value);
    }
    if (shapePtLat.present) {
      map['shape_pt_lat'] = Variable<double>(shapePtLat.value);
    }
    if (shapePtLon.present) {
      map['shape_pt_lon'] = Variable<double>(shapePtLon.value);
    }
    if (shapeDistTraveled.present) {
      map['shape_dist_traveled'] = Variable<double>(shapeDistTraveled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShapesCompanion(')
          ..write('shapeId: $shapeId, ')
          ..write('shapePtSequence: $shapePtSequence, ')
          ..write('shapePtLat: $shapePtLat, ')
          ..write('shapePtLon: $shapePtLon, ')
          ..write('shapeDistTraveled: $shapeDistTraveled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AgenciesTable agencies = $AgenciesTable(this);
  late final $StopsTable stops = $StopsTable(this);
  late final $RoutesTable routes = $RoutesTable(this);
  late final $TripsTable trips = $TripsTable(this);
  late final $StopTimesTable stopTimes = $StopTimesTable(this);
  late final $ShapesTable shapes = $ShapesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    agencies,
    stops,
    routes,
    trips,
    stopTimes,
    shapes,
  ];
}

typedef $$AgenciesTableCreateCompanionBuilder =
    AgenciesCompanion Function({
      required String agencyId,
      required String agencyName,
      Value<String?> agencyUrl,
      required String agencyTimezone,
      Value<int> rowid,
    });
typedef $$AgenciesTableUpdateCompanionBuilder =
    AgenciesCompanion Function({
      Value<String> agencyId,
      Value<String> agencyName,
      Value<String?> agencyUrl,
      Value<String> agencyTimezone,
      Value<int> rowid,
    });

final class $$AgenciesTableReferences
    extends BaseReferences<_$AppDatabase, $AgenciesTable, Agency> {
  $$AgenciesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RoutesTable, List<Route>> _routesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.routes,
    aliasName: 'agencies__agency_id__routes__agency_id',
  );

  $$RoutesTableProcessedTableManager get routesRefs {
    final manager = $$RoutesTableTableManager($_db, $_db.routes).filter(
      (f) => f.agencyId.agencyId.sqlEquals($_itemColumn<String>('agency_id')!),
    );

    final cache = $_typedResult.readTableOrNull(_routesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AgenciesTableFilterComposer
    extends Composer<_$AppDatabase, $AgenciesTable> {
  $$AgenciesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get agencyId => $composableBuilder(
    column: $table.agencyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get agencyName => $composableBuilder(
    column: $table.agencyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get agencyUrl => $composableBuilder(
    column: $table.agencyUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get agencyTimezone => $composableBuilder(
    column: $table.agencyTimezone,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> routesRefs(
    Expression<bool> Function($$RoutesTableFilterComposer f) f,
  ) {
    final $$RoutesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.agencyId,
      referencedTable: $db.routes,
      getReferencedColumn: (t) => t.agencyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutesTableFilterComposer(
            $db: $db,
            $table: $db.routes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AgenciesTableOrderingComposer
    extends Composer<_$AppDatabase, $AgenciesTable> {
  $$AgenciesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get agencyId => $composableBuilder(
    column: $table.agencyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get agencyName => $composableBuilder(
    column: $table.agencyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get agencyUrl => $composableBuilder(
    column: $table.agencyUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get agencyTimezone => $composableBuilder(
    column: $table.agencyTimezone,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AgenciesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AgenciesTable> {
  $$AgenciesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get agencyId =>
      $composableBuilder(column: $table.agencyId, builder: (column) => column);

  GeneratedColumn<String> get agencyName => $composableBuilder(
    column: $table.agencyName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get agencyUrl =>
      $composableBuilder(column: $table.agencyUrl, builder: (column) => column);

  GeneratedColumn<String> get agencyTimezone => $composableBuilder(
    column: $table.agencyTimezone,
    builder: (column) => column,
  );

  Expression<T> routesRefs<T extends Object>(
    Expression<T> Function($$RoutesTableAnnotationComposer a) f,
  ) {
    final $$RoutesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.agencyId,
      referencedTable: $db.routes,
      getReferencedColumn: (t) => t.agencyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutesTableAnnotationComposer(
            $db: $db,
            $table: $db.routes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AgenciesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AgenciesTable,
          Agency,
          $$AgenciesTableFilterComposer,
          $$AgenciesTableOrderingComposer,
          $$AgenciesTableAnnotationComposer,
          $$AgenciesTableCreateCompanionBuilder,
          $$AgenciesTableUpdateCompanionBuilder,
          (Agency, $$AgenciesTableReferences),
          Agency,
          PrefetchHooks Function({bool routesRefs})
        > {
  $$AgenciesTableTableManager(_$AppDatabase db, $AgenciesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AgenciesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AgenciesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AgenciesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> agencyId = const Value.absent(),
                Value<String> agencyName = const Value.absent(),
                Value<String?> agencyUrl = const Value.absent(),
                Value<String> agencyTimezone = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgenciesCompanion(
                agencyId: agencyId,
                agencyName: agencyName,
                agencyUrl: agencyUrl,
                agencyTimezone: agencyTimezone,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String agencyId,
                required String agencyName,
                Value<String?> agencyUrl = const Value.absent(),
                required String agencyTimezone,
                Value<int> rowid = const Value.absent(),
              }) => AgenciesCompanion.insert(
                agencyId: agencyId,
                agencyName: agencyName,
                agencyUrl: agencyUrl,
                agencyTimezone: agencyTimezone,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AgenciesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({routesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (routesRefs) db.routes],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (routesRefs)
                    await $_getPrefetchedData<Agency, $AgenciesTable, Route>(
                      currentTable: table,
                      referencedTable: $$AgenciesTableReferences
                          ._routesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$AgenciesTableReferences(db, table, p0).routesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.agencyId == item.agencyId,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$AgenciesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AgenciesTable,
      Agency,
      $$AgenciesTableFilterComposer,
      $$AgenciesTableOrderingComposer,
      $$AgenciesTableAnnotationComposer,
      $$AgenciesTableCreateCompanionBuilder,
      $$AgenciesTableUpdateCompanionBuilder,
      (Agency, $$AgenciesTableReferences),
      Agency,
      PrefetchHooks Function({bool routesRefs})
    >;
typedef $$StopsTableCreateCompanionBuilder =
    StopsCompanion Function({
      required String stopId,
      required String stopName,
      required double stopLat,
      required double stopLon,
      Value<String?> stopCode,
      Value<String?> platformCode,
      Value<String?> parentStation,
      Value<int> locationType,
      Value<int?> wheelchairBoarding,
      Value<String?> city,
      Value<String?> operatorName,
      Value<String?> rikshallplatsId,
      Value<String?> rikshallplatsName,
      Value<String?> availableModes,
      Value<String?> platformList,
      Value<int?> dailyPassengers,
      Value<int> rowid,
    });
typedef $$StopsTableUpdateCompanionBuilder =
    StopsCompanion Function({
      Value<String> stopId,
      Value<String> stopName,
      Value<double> stopLat,
      Value<double> stopLon,
      Value<String?> stopCode,
      Value<String?> platformCode,
      Value<String?> parentStation,
      Value<int> locationType,
      Value<int?> wheelchairBoarding,
      Value<String?> city,
      Value<String?> operatorName,
      Value<String?> rikshallplatsId,
      Value<String?> rikshallplatsName,
      Value<String?> availableModes,
      Value<String?> platformList,
      Value<int?> dailyPassengers,
      Value<int> rowid,
    });

final class $$StopsTableReferences
    extends BaseReferences<_$AppDatabase, $StopsTable, Stop> {
  $$StopsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$StopTimesTable, List<StopTime>>
  _stopTimesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.stopTimes,
    aliasName: 'stops__stop_id__stop_times__stop_id',
  );

  $$StopTimesTableProcessedTableManager get stopTimesRefs {
    final manager = $$StopTimesTableTableManager($_db, $_db.stopTimes).filter(
      (f) => f.stopId.stopId.sqlEquals($_itemColumn<String>('stop_id')!),
    );

    final cache = $_typedResult.readTableOrNull(_stopTimesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StopsTableFilterComposer extends Composer<_$AppDatabase, $StopsTable> {
  $$StopsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get stopId => $composableBuilder(
    column: $table.stopId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stopName => $composableBuilder(
    column: $table.stopName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stopLat => $composableBuilder(
    column: $table.stopLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stopLon => $composableBuilder(
    column: $table.stopLon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stopCode => $composableBuilder(
    column: $table.stopCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get platformCode => $composableBuilder(
    column: $table.platformCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentStation => $composableBuilder(
    column: $table.parentStation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get locationType => $composableBuilder(
    column: $table.locationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wheelchairBoarding => $composableBuilder(
    column: $table.wheelchairBoarding,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operatorName => $composableBuilder(
    column: $table.operatorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rikshallplatsId => $composableBuilder(
    column: $table.rikshallplatsId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rikshallplatsName => $composableBuilder(
    column: $table.rikshallplatsName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get availableModes => $composableBuilder(
    column: $table.availableModes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get platformList => $composableBuilder(
    column: $table.platformList,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyPassengers => $composableBuilder(
    column: $table.dailyPassengers,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> stopTimesRefs(
    Expression<bool> Function($$StopTimesTableFilterComposer f) f,
  ) {
    final $$StopTimesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stopId,
      referencedTable: $db.stopTimes,
      getReferencedColumn: (t) => t.stopId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StopTimesTableFilterComposer(
            $db: $db,
            $table: $db.stopTimes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StopsTableOrderingComposer
    extends Composer<_$AppDatabase, $StopsTable> {
  $$StopsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get stopId => $composableBuilder(
    column: $table.stopId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stopName => $composableBuilder(
    column: $table.stopName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stopLat => $composableBuilder(
    column: $table.stopLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stopLon => $composableBuilder(
    column: $table.stopLon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stopCode => $composableBuilder(
    column: $table.stopCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get platformCode => $composableBuilder(
    column: $table.platformCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentStation => $composableBuilder(
    column: $table.parentStation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get locationType => $composableBuilder(
    column: $table.locationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wheelchairBoarding => $composableBuilder(
    column: $table.wheelchairBoarding,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operatorName => $composableBuilder(
    column: $table.operatorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rikshallplatsId => $composableBuilder(
    column: $table.rikshallplatsId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rikshallplatsName => $composableBuilder(
    column: $table.rikshallplatsName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get availableModes => $composableBuilder(
    column: $table.availableModes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get platformList => $composableBuilder(
    column: $table.platformList,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyPassengers => $composableBuilder(
    column: $table.dailyPassengers,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StopsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StopsTable> {
  $$StopsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get stopId =>
      $composableBuilder(column: $table.stopId, builder: (column) => column);

  GeneratedColumn<String> get stopName =>
      $composableBuilder(column: $table.stopName, builder: (column) => column);

  GeneratedColumn<double> get stopLat =>
      $composableBuilder(column: $table.stopLat, builder: (column) => column);

  GeneratedColumn<double> get stopLon =>
      $composableBuilder(column: $table.stopLon, builder: (column) => column);

  GeneratedColumn<String> get stopCode =>
      $composableBuilder(column: $table.stopCode, builder: (column) => column);

  GeneratedColumn<String> get platformCode => $composableBuilder(
    column: $table.platformCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get parentStation => $composableBuilder(
    column: $table.parentStation,
    builder: (column) => column,
  );

  GeneratedColumn<int> get locationType => $composableBuilder(
    column: $table.locationType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wheelchairBoarding => $composableBuilder(
    column: $table.wheelchairBoarding,
    builder: (column) => column,
  );

  GeneratedColumn<String> get city =>
      $composableBuilder(column: $table.city, builder: (column) => column);

  GeneratedColumn<String> get operatorName => $composableBuilder(
    column: $table.operatorName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rikshallplatsId => $composableBuilder(
    column: $table.rikshallplatsId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rikshallplatsName => $composableBuilder(
    column: $table.rikshallplatsName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get availableModes => $composableBuilder(
    column: $table.availableModes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get platformList => $composableBuilder(
    column: $table.platformList,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dailyPassengers => $composableBuilder(
    column: $table.dailyPassengers,
    builder: (column) => column,
  );

  Expression<T> stopTimesRefs<T extends Object>(
    Expression<T> Function($$StopTimesTableAnnotationComposer a) f,
  ) {
    final $$StopTimesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stopId,
      referencedTable: $db.stopTimes,
      getReferencedColumn: (t) => t.stopId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StopTimesTableAnnotationComposer(
            $db: $db,
            $table: $db.stopTimes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StopsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StopsTable,
          Stop,
          $$StopsTableFilterComposer,
          $$StopsTableOrderingComposer,
          $$StopsTableAnnotationComposer,
          $$StopsTableCreateCompanionBuilder,
          $$StopsTableUpdateCompanionBuilder,
          (Stop, $$StopsTableReferences),
          Stop,
          PrefetchHooks Function({bool stopTimesRefs})
        > {
  $$StopsTableTableManager(_$AppDatabase db, $StopsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StopsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StopsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StopsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> stopId = const Value.absent(),
                Value<String> stopName = const Value.absent(),
                Value<double> stopLat = const Value.absent(),
                Value<double> stopLon = const Value.absent(),
                Value<String?> stopCode = const Value.absent(),
                Value<String?> platformCode = const Value.absent(),
                Value<String?> parentStation = const Value.absent(),
                Value<int> locationType = const Value.absent(),
                Value<int?> wheelchairBoarding = const Value.absent(),
                Value<String?> city = const Value.absent(),
                Value<String?> operatorName = const Value.absent(),
                Value<String?> rikshallplatsId = const Value.absent(),
                Value<String?> rikshallplatsName = const Value.absent(),
                Value<String?> availableModes = const Value.absent(),
                Value<String?> platformList = const Value.absent(),
                Value<int?> dailyPassengers = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StopsCompanion(
                stopId: stopId,
                stopName: stopName,
                stopLat: stopLat,
                stopLon: stopLon,
                stopCode: stopCode,
                platformCode: platformCode,
                parentStation: parentStation,
                locationType: locationType,
                wheelchairBoarding: wheelchairBoarding,
                city: city,
                operatorName: operatorName,
                rikshallplatsId: rikshallplatsId,
                rikshallplatsName: rikshallplatsName,
                availableModes: availableModes,
                platformList: platformList,
                dailyPassengers: dailyPassengers,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String stopId,
                required String stopName,
                required double stopLat,
                required double stopLon,
                Value<String?> stopCode = const Value.absent(),
                Value<String?> platformCode = const Value.absent(),
                Value<String?> parentStation = const Value.absent(),
                Value<int> locationType = const Value.absent(),
                Value<int?> wheelchairBoarding = const Value.absent(),
                Value<String?> city = const Value.absent(),
                Value<String?> operatorName = const Value.absent(),
                Value<String?> rikshallplatsId = const Value.absent(),
                Value<String?> rikshallplatsName = const Value.absent(),
                Value<String?> availableModes = const Value.absent(),
                Value<String?> platformList = const Value.absent(),
                Value<int?> dailyPassengers = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StopsCompanion.insert(
                stopId: stopId,
                stopName: stopName,
                stopLat: stopLat,
                stopLon: stopLon,
                stopCode: stopCode,
                platformCode: platformCode,
                parentStation: parentStation,
                locationType: locationType,
                wheelchairBoarding: wheelchairBoarding,
                city: city,
                operatorName: operatorName,
                rikshallplatsId: rikshallplatsId,
                rikshallplatsName: rikshallplatsName,
                availableModes: availableModes,
                platformList: platformList,
                dailyPassengers: dailyPassengers,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$StopsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({stopTimesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (stopTimesRefs) db.stopTimes],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (stopTimesRefs)
                    await $_getPrefetchedData<Stop, $StopsTable, StopTime>(
                      currentTable: table,
                      referencedTable: $$StopsTableReferences
                          ._stopTimesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$StopsTableReferences(db, table, p0).stopTimesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.stopId == item.stopId),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$StopsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StopsTable,
      Stop,
      $$StopsTableFilterComposer,
      $$StopsTableOrderingComposer,
      $$StopsTableAnnotationComposer,
      $$StopsTableCreateCompanionBuilder,
      $$StopsTableUpdateCompanionBuilder,
      (Stop, $$StopsTableReferences),
      Stop,
      PrefetchHooks Function({bool stopTimesRefs})
    >;
typedef $$RoutesTableCreateCompanionBuilder =
    RoutesCompanion Function({
      required String routeId,
      Value<String?> agencyId,
      Value<String?> routeShortName,
      Value<String?> routeLongName,
      required int routeType,
      Value<int> rowid,
    });
typedef $$RoutesTableUpdateCompanionBuilder =
    RoutesCompanion Function({
      Value<String> routeId,
      Value<String?> agencyId,
      Value<String?> routeShortName,
      Value<String?> routeLongName,
      Value<int> routeType,
      Value<int> rowid,
    });

final class $$RoutesTableReferences
    extends BaseReferences<_$AppDatabase, $RoutesTable, Route> {
  $$RoutesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AgenciesTable _agencyIdTable(_$AppDatabase db) =>
      db.agencies.createAlias('routes__agency_id__agencies__agency_id');

  $$AgenciesTableProcessedTableManager? get agencyId {
    final $_column = $_itemColumn<String>('agency_id');
    if ($_column == null) return null;
    final manager = $$AgenciesTableTableManager(
      $_db,
      $_db.agencies,
    ).filter((f) => f.agencyId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_agencyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TripsTable, List<Trip>> _tripsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.trips,
    aliasName: 'routes__route_id__trips__route_id',
  );

  $$TripsTableProcessedTableManager get tripsRefs {
    final manager = $$TripsTableTableManager($_db, $_db.trips).filter(
      (f) => f.routeId.routeId.sqlEquals($_itemColumn<String>('route_id')!),
    );

    final cache = $_typedResult.readTableOrNull(_tripsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RoutesTableFilterComposer
    extends Composer<_$AppDatabase, $RoutesTable> {
  $$RoutesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get routeId => $composableBuilder(
    column: $table.routeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routeShortName => $composableBuilder(
    column: $table.routeShortName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routeLongName => $composableBuilder(
    column: $table.routeLongName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get routeType => $composableBuilder(
    column: $table.routeType,
    builder: (column) => ColumnFilters(column),
  );

  $$AgenciesTableFilterComposer get agencyId {
    final $$AgenciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.agencyId,
      referencedTable: $db.agencies,
      getReferencedColumn: (t) => t.agencyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AgenciesTableFilterComposer(
            $db: $db,
            $table: $db.agencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> tripsRefs(
    Expression<bool> Function($$TripsTableFilterComposer f) f,
  ) {
    final $$TripsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routeId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.routeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableFilterComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RoutesTableOrderingComposer
    extends Composer<_$AppDatabase, $RoutesTable> {
  $$RoutesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get routeId => $composableBuilder(
    column: $table.routeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routeShortName => $composableBuilder(
    column: $table.routeShortName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routeLongName => $composableBuilder(
    column: $table.routeLongName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get routeType => $composableBuilder(
    column: $table.routeType,
    builder: (column) => ColumnOrderings(column),
  );

  $$AgenciesTableOrderingComposer get agencyId {
    final $$AgenciesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.agencyId,
      referencedTable: $db.agencies,
      getReferencedColumn: (t) => t.agencyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AgenciesTableOrderingComposer(
            $db: $db,
            $table: $db.agencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoutesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoutesTable> {
  $$RoutesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get routeId =>
      $composableBuilder(column: $table.routeId, builder: (column) => column);

  GeneratedColumn<String> get routeShortName => $composableBuilder(
    column: $table.routeShortName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get routeLongName => $composableBuilder(
    column: $table.routeLongName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get routeType =>
      $composableBuilder(column: $table.routeType, builder: (column) => column);

  $$AgenciesTableAnnotationComposer get agencyId {
    final $$AgenciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.agencyId,
      referencedTable: $db.agencies,
      getReferencedColumn: (t) => t.agencyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AgenciesTableAnnotationComposer(
            $db: $db,
            $table: $db.agencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> tripsRefs<T extends Object>(
    Expression<T> Function($$TripsTableAnnotationComposer a) f,
  ) {
    final $$TripsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routeId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.routeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableAnnotationComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RoutesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RoutesTable,
          Route,
          $$RoutesTableFilterComposer,
          $$RoutesTableOrderingComposer,
          $$RoutesTableAnnotationComposer,
          $$RoutesTableCreateCompanionBuilder,
          $$RoutesTableUpdateCompanionBuilder,
          (Route, $$RoutesTableReferences),
          Route,
          PrefetchHooks Function({bool agencyId, bool tripsRefs})
        > {
  $$RoutesTableTableManager(_$AppDatabase db, $RoutesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoutesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoutesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoutesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> routeId = const Value.absent(),
                Value<String?> agencyId = const Value.absent(),
                Value<String?> routeShortName = const Value.absent(),
                Value<String?> routeLongName = const Value.absent(),
                Value<int> routeType = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoutesCompanion(
                routeId: routeId,
                agencyId: agencyId,
                routeShortName: routeShortName,
                routeLongName: routeLongName,
                routeType: routeType,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String routeId,
                Value<String?> agencyId = const Value.absent(),
                Value<String?> routeShortName = const Value.absent(),
                Value<String?> routeLongName = const Value.absent(),
                required int routeType,
                Value<int> rowid = const Value.absent(),
              }) => RoutesCompanion.insert(
                routeId: routeId,
                agencyId: agencyId,
                routeShortName: routeShortName,
                routeLongName: routeLongName,
                routeType: routeType,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$RoutesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({agencyId = false, tripsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (tripsRefs) db.trips],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (agencyId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.agencyId,
                                referencedTable: $$RoutesTableReferences
                                    ._agencyIdTable(db),
                                referencedColumn: $$RoutesTableReferences
                                    ._agencyIdTable(db)
                                    .agencyId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (tripsRefs)
                    await $_getPrefetchedData<Route, $RoutesTable, Trip>(
                      currentTable: table,
                      referencedTable: $$RoutesTableReferences._tripsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$RoutesTableReferences(db, table, p0).tripsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.routeId == item.routeId,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RoutesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RoutesTable,
      Route,
      $$RoutesTableFilterComposer,
      $$RoutesTableOrderingComposer,
      $$RoutesTableAnnotationComposer,
      $$RoutesTableCreateCompanionBuilder,
      $$RoutesTableUpdateCompanionBuilder,
      (Route, $$RoutesTableReferences),
      Route,
      PrefetchHooks Function({bool agencyId, bool tripsRefs})
    >;
typedef $$TripsTableCreateCompanionBuilder =
    TripsCompanion Function({
      required String tripId,
      required String routeId,
      required String serviceId,
      Value<String?> tripHeadsign,
      Value<int?> directionId,
      Value<String?> shapeId,
      Value<String?> tripShortName,
      Value<int> rowid,
    });
typedef $$TripsTableUpdateCompanionBuilder =
    TripsCompanion Function({
      Value<String> tripId,
      Value<String> routeId,
      Value<String> serviceId,
      Value<String?> tripHeadsign,
      Value<int?> directionId,
      Value<String?> shapeId,
      Value<String?> tripShortName,
      Value<int> rowid,
    });

final class $$TripsTableReferences
    extends BaseReferences<_$AppDatabase, $TripsTable, Trip> {
  $$TripsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RoutesTable _routeIdTable(_$AppDatabase db) =>
      db.routes.createAlias('trips__route_id__routes__route_id');

  $$RoutesTableProcessedTableManager get routeId {
    final $_column = $_itemColumn<String>('route_id')!;

    final manager = $$RoutesTableTableManager(
      $_db,
      $_db.routes,
    ).filter((f) => f.routeId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_routeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$StopTimesTable, List<StopTime>>
  _stopTimesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.stopTimes,
    aliasName: 'trips__trip_id__stop_times__trip_id',
  );

  $$StopTimesTableProcessedTableManager get stopTimesRefs {
    final manager = $$StopTimesTableTableManager($_db, $_db.stopTimes).filter(
      (f) => f.tripId.tripId.sqlEquals($_itemColumn<String>('trip_id')!),
    );

    final cache = $_typedResult.readTableOrNull(_stopTimesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TripsTableFilterComposer extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serviceId => $composableBuilder(
    column: $table.serviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tripHeadsign => $composableBuilder(
    column: $table.tripHeadsign,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get directionId => $composableBuilder(
    column: $table.directionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shapeId => $composableBuilder(
    column: $table.shapeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tripShortName => $composableBuilder(
    column: $table.tripShortName,
    builder: (column) => ColumnFilters(column),
  );

  $$RoutesTableFilterComposer get routeId {
    final $$RoutesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routeId,
      referencedTable: $db.routes,
      getReferencedColumn: (t) => t.routeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutesTableFilterComposer(
            $db: $db,
            $table: $db.routes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> stopTimesRefs(
    Expression<bool> Function($$StopTimesTableFilterComposer f) f,
  ) {
    final $$StopTimesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.stopTimes,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StopTimesTableFilterComposer(
            $db: $db,
            $table: $db.stopTimes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TripsTableOrderingComposer
    extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serviceId => $composableBuilder(
    column: $table.serviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tripHeadsign => $composableBuilder(
    column: $table.tripHeadsign,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get directionId => $composableBuilder(
    column: $table.directionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shapeId => $composableBuilder(
    column: $table.shapeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tripShortName => $composableBuilder(
    column: $table.tripShortName,
    builder: (column) => ColumnOrderings(column),
  );

  $$RoutesTableOrderingComposer get routeId {
    final $$RoutesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routeId,
      referencedTable: $db.routes,
      getReferencedColumn: (t) => t.routeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutesTableOrderingComposer(
            $db: $db,
            $table: $db.routes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TripsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tripId =>
      $composableBuilder(column: $table.tripId, builder: (column) => column);

  GeneratedColumn<String> get serviceId =>
      $composableBuilder(column: $table.serviceId, builder: (column) => column);

  GeneratedColumn<String> get tripHeadsign => $composableBuilder(
    column: $table.tripHeadsign,
    builder: (column) => column,
  );

  GeneratedColumn<int> get directionId => $composableBuilder(
    column: $table.directionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get shapeId =>
      $composableBuilder(column: $table.shapeId, builder: (column) => column);

  GeneratedColumn<String> get tripShortName => $composableBuilder(
    column: $table.tripShortName,
    builder: (column) => column,
  );

  $$RoutesTableAnnotationComposer get routeId {
    final $$RoutesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routeId,
      referencedTable: $db.routes,
      getReferencedColumn: (t) => t.routeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutesTableAnnotationComposer(
            $db: $db,
            $table: $db.routes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> stopTimesRefs<T extends Object>(
    Expression<T> Function($$StopTimesTableAnnotationComposer a) f,
  ) {
    final $$StopTimesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.stopTimes,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StopTimesTableAnnotationComposer(
            $db: $db,
            $table: $db.stopTimes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TripsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TripsTable,
          Trip,
          $$TripsTableFilterComposer,
          $$TripsTableOrderingComposer,
          $$TripsTableAnnotationComposer,
          $$TripsTableCreateCompanionBuilder,
          $$TripsTableUpdateCompanionBuilder,
          (Trip, $$TripsTableReferences),
          Trip,
          PrefetchHooks Function({bool routeId, bool stopTimesRefs})
        > {
  $$TripsTableTableManager(_$AppDatabase db, $TripsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TripsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TripsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TripsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tripId = const Value.absent(),
                Value<String> routeId = const Value.absent(),
                Value<String> serviceId = const Value.absent(),
                Value<String?> tripHeadsign = const Value.absent(),
                Value<int?> directionId = const Value.absent(),
                Value<String?> shapeId = const Value.absent(),
                Value<String?> tripShortName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TripsCompanion(
                tripId: tripId,
                routeId: routeId,
                serviceId: serviceId,
                tripHeadsign: tripHeadsign,
                directionId: directionId,
                shapeId: shapeId,
                tripShortName: tripShortName,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tripId,
                required String routeId,
                required String serviceId,
                Value<String?> tripHeadsign = const Value.absent(),
                Value<int?> directionId = const Value.absent(),
                Value<String?> shapeId = const Value.absent(),
                Value<String?> tripShortName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TripsCompanion.insert(
                tripId: tripId,
                routeId: routeId,
                serviceId: serviceId,
                tripHeadsign: tripHeadsign,
                directionId: directionId,
                shapeId: shapeId,
                tripShortName: tripShortName,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TripsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({routeId = false, stopTimesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (stopTimesRefs) db.stopTimes],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (routeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.routeId,
                                referencedTable: $$TripsTableReferences
                                    ._routeIdTable(db),
                                referencedColumn: $$TripsTableReferences
                                    ._routeIdTable(db)
                                    .routeId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (stopTimesRefs)
                    await $_getPrefetchedData<Trip, $TripsTable, StopTime>(
                      currentTable: table,
                      referencedTable: $$TripsTableReferences
                          ._stopTimesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TripsTableReferences(db, table, p0).stopTimesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.tripId == item.tripId),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TripsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TripsTable,
      Trip,
      $$TripsTableFilterComposer,
      $$TripsTableOrderingComposer,
      $$TripsTableAnnotationComposer,
      $$TripsTableCreateCompanionBuilder,
      $$TripsTableUpdateCompanionBuilder,
      (Trip, $$TripsTableReferences),
      Trip,
      PrefetchHooks Function({bool routeId, bool stopTimesRefs})
    >;
typedef $$StopTimesTableCreateCompanionBuilder =
    StopTimesCompanion Function({
      required String tripId,
      required int stopSequence,
      required String stopId,
      Value<String?> arrivalTime,
      Value<String?> departureTime,
      Value<String?> stopHeadsign,
      Value<int?> pickupType,
      Value<int?> dropOffType,
      Value<int> rowid,
    });
typedef $$StopTimesTableUpdateCompanionBuilder =
    StopTimesCompanion Function({
      Value<String> tripId,
      Value<int> stopSequence,
      Value<String> stopId,
      Value<String?> arrivalTime,
      Value<String?> departureTime,
      Value<String?> stopHeadsign,
      Value<int?> pickupType,
      Value<int?> dropOffType,
      Value<int> rowid,
    });

final class $$StopTimesTableReferences
    extends BaseReferences<_$AppDatabase, $StopTimesTable, StopTime> {
  $$StopTimesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TripsTable _tripIdTable(_$AppDatabase db) =>
      db.trips.createAlias('stop_times__trip_id__trips__trip_id');

  $$TripsTableProcessedTableManager get tripId {
    final $_column = $_itemColumn<String>('trip_id')!;

    final manager = $$TripsTableTableManager(
      $_db,
      $_db.trips,
    ).filter((f) => f.tripId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tripIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $StopsTable _stopIdTable(_$AppDatabase db) =>
      db.stops.createAlias('stop_times__stop_id__stops__stop_id');

  $$StopsTableProcessedTableManager get stopId {
    final $_column = $_itemColumn<String>('stop_id')!;

    final manager = $$StopsTableTableManager(
      $_db,
      $_db.stops,
    ).filter((f) => f.stopId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_stopIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StopTimesTableFilterComposer
    extends Composer<_$AppDatabase, $StopTimesTable> {
  $$StopTimesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get stopSequence => $composableBuilder(
    column: $table.stopSequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get arrivalTime => $composableBuilder(
    column: $table.arrivalTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get departureTime => $composableBuilder(
    column: $table.departureTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stopHeadsign => $composableBuilder(
    column: $table.stopHeadsign,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pickupType => $composableBuilder(
    column: $table.pickupType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dropOffType => $composableBuilder(
    column: $table.dropOffType,
    builder: (column) => ColumnFilters(column),
  );

  $$TripsTableFilterComposer get tripId {
    final $$TripsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableFilterComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StopsTableFilterComposer get stopId {
    final $$StopsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stopId,
      referencedTable: $db.stops,
      getReferencedColumn: (t) => t.stopId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StopsTableFilterComposer(
            $db: $db,
            $table: $db.stops,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StopTimesTableOrderingComposer
    extends Composer<_$AppDatabase, $StopTimesTable> {
  $$StopTimesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get stopSequence => $composableBuilder(
    column: $table.stopSequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get arrivalTime => $composableBuilder(
    column: $table.arrivalTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get departureTime => $composableBuilder(
    column: $table.departureTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stopHeadsign => $composableBuilder(
    column: $table.stopHeadsign,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pickupType => $composableBuilder(
    column: $table.pickupType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dropOffType => $composableBuilder(
    column: $table.dropOffType,
    builder: (column) => ColumnOrderings(column),
  );

  $$TripsTableOrderingComposer get tripId {
    final $$TripsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableOrderingComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StopsTableOrderingComposer get stopId {
    final $$StopsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stopId,
      referencedTable: $db.stops,
      getReferencedColumn: (t) => t.stopId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StopsTableOrderingComposer(
            $db: $db,
            $table: $db.stops,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StopTimesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StopTimesTable> {
  $$StopTimesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get stopSequence => $composableBuilder(
    column: $table.stopSequence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get arrivalTime => $composableBuilder(
    column: $table.arrivalTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get departureTime => $composableBuilder(
    column: $table.departureTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stopHeadsign => $composableBuilder(
    column: $table.stopHeadsign,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pickupType => $composableBuilder(
    column: $table.pickupType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dropOffType => $composableBuilder(
    column: $table.dropOffType,
    builder: (column) => column,
  );

  $$TripsTableAnnotationComposer get tripId {
    final $$TripsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableAnnotationComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StopsTableAnnotationComposer get stopId {
    final $$StopsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stopId,
      referencedTable: $db.stops,
      getReferencedColumn: (t) => t.stopId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StopsTableAnnotationComposer(
            $db: $db,
            $table: $db.stops,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StopTimesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StopTimesTable,
          StopTime,
          $$StopTimesTableFilterComposer,
          $$StopTimesTableOrderingComposer,
          $$StopTimesTableAnnotationComposer,
          $$StopTimesTableCreateCompanionBuilder,
          $$StopTimesTableUpdateCompanionBuilder,
          (StopTime, $$StopTimesTableReferences),
          StopTime,
          PrefetchHooks Function({bool tripId, bool stopId})
        > {
  $$StopTimesTableTableManager(_$AppDatabase db, $StopTimesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StopTimesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StopTimesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StopTimesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tripId = const Value.absent(),
                Value<int> stopSequence = const Value.absent(),
                Value<String> stopId = const Value.absent(),
                Value<String?> arrivalTime = const Value.absent(),
                Value<String?> departureTime = const Value.absent(),
                Value<String?> stopHeadsign = const Value.absent(),
                Value<int?> pickupType = const Value.absent(),
                Value<int?> dropOffType = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StopTimesCompanion(
                tripId: tripId,
                stopSequence: stopSequence,
                stopId: stopId,
                arrivalTime: arrivalTime,
                departureTime: departureTime,
                stopHeadsign: stopHeadsign,
                pickupType: pickupType,
                dropOffType: dropOffType,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tripId,
                required int stopSequence,
                required String stopId,
                Value<String?> arrivalTime = const Value.absent(),
                Value<String?> departureTime = const Value.absent(),
                Value<String?> stopHeadsign = const Value.absent(),
                Value<int?> pickupType = const Value.absent(),
                Value<int?> dropOffType = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StopTimesCompanion.insert(
                tripId: tripId,
                stopSequence: stopSequence,
                stopId: stopId,
                arrivalTime: arrivalTime,
                departureTime: departureTime,
                stopHeadsign: stopHeadsign,
                pickupType: pickupType,
                dropOffType: dropOffType,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StopTimesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({tripId = false, stopId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (tripId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tripId,
                                referencedTable: $$StopTimesTableReferences
                                    ._tripIdTable(db),
                                referencedColumn: $$StopTimesTableReferences
                                    ._tripIdTable(db)
                                    .tripId,
                              )
                              as T;
                    }
                    if (stopId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.stopId,
                                referencedTable: $$StopTimesTableReferences
                                    ._stopIdTable(db),
                                referencedColumn: $$StopTimesTableReferences
                                    ._stopIdTable(db)
                                    .stopId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$StopTimesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StopTimesTable,
      StopTime,
      $$StopTimesTableFilterComposer,
      $$StopTimesTableOrderingComposer,
      $$StopTimesTableAnnotationComposer,
      $$StopTimesTableCreateCompanionBuilder,
      $$StopTimesTableUpdateCompanionBuilder,
      (StopTime, $$StopTimesTableReferences),
      StopTime,
      PrefetchHooks Function({bool tripId, bool stopId})
    >;
typedef $$ShapesTableCreateCompanionBuilder =
    ShapesCompanion Function({
      required String shapeId,
      required int shapePtSequence,
      required double shapePtLat,
      required double shapePtLon,
      Value<double?> shapeDistTraveled,
      Value<int> rowid,
    });
typedef $$ShapesTableUpdateCompanionBuilder =
    ShapesCompanion Function({
      Value<String> shapeId,
      Value<int> shapePtSequence,
      Value<double> shapePtLat,
      Value<double> shapePtLon,
      Value<double?> shapeDistTraveled,
      Value<int> rowid,
    });

class $$ShapesTableFilterComposer
    extends Composer<_$AppDatabase, $ShapesTable> {
  $$ShapesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get shapeId => $composableBuilder(
    column: $table.shapeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get shapePtSequence => $composableBuilder(
    column: $table.shapePtSequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get shapePtLat => $composableBuilder(
    column: $table.shapePtLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get shapePtLon => $composableBuilder(
    column: $table.shapePtLon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get shapeDistTraveled => $composableBuilder(
    column: $table.shapeDistTraveled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShapesTableOrderingComposer
    extends Composer<_$AppDatabase, $ShapesTable> {
  $$ShapesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get shapeId => $composableBuilder(
    column: $table.shapeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get shapePtSequence => $composableBuilder(
    column: $table.shapePtSequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get shapePtLat => $composableBuilder(
    column: $table.shapePtLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get shapePtLon => $composableBuilder(
    column: $table.shapePtLon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get shapeDistTraveled => $composableBuilder(
    column: $table.shapeDistTraveled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShapesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShapesTable> {
  $$ShapesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get shapeId =>
      $composableBuilder(column: $table.shapeId, builder: (column) => column);

  GeneratedColumn<int> get shapePtSequence => $composableBuilder(
    column: $table.shapePtSequence,
    builder: (column) => column,
  );

  GeneratedColumn<double> get shapePtLat => $composableBuilder(
    column: $table.shapePtLat,
    builder: (column) => column,
  );

  GeneratedColumn<double> get shapePtLon => $composableBuilder(
    column: $table.shapePtLon,
    builder: (column) => column,
  );

  GeneratedColumn<double> get shapeDistTraveled => $composableBuilder(
    column: $table.shapeDistTraveled,
    builder: (column) => column,
  );
}

class $$ShapesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShapesTable,
          Shape,
          $$ShapesTableFilterComposer,
          $$ShapesTableOrderingComposer,
          $$ShapesTableAnnotationComposer,
          $$ShapesTableCreateCompanionBuilder,
          $$ShapesTableUpdateCompanionBuilder,
          (Shape, BaseReferences<_$AppDatabase, $ShapesTable, Shape>),
          Shape,
          PrefetchHooks Function()
        > {
  $$ShapesTableTableManager(_$AppDatabase db, $ShapesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShapesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShapesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShapesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> shapeId = const Value.absent(),
                Value<int> shapePtSequence = const Value.absent(),
                Value<double> shapePtLat = const Value.absent(),
                Value<double> shapePtLon = const Value.absent(),
                Value<double?> shapeDistTraveled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShapesCompanion(
                shapeId: shapeId,
                shapePtSequence: shapePtSequence,
                shapePtLat: shapePtLat,
                shapePtLon: shapePtLon,
                shapeDistTraveled: shapeDistTraveled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String shapeId,
                required int shapePtSequence,
                required double shapePtLat,
                required double shapePtLon,
                Value<double?> shapeDistTraveled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShapesCompanion.insert(
                shapeId: shapeId,
                shapePtSequence: shapePtSequence,
                shapePtLat: shapePtLat,
                shapePtLon: shapePtLon,
                shapeDistTraveled: shapeDistTraveled,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShapesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShapesTable,
      Shape,
      $$ShapesTableFilterComposer,
      $$ShapesTableOrderingComposer,
      $$ShapesTableAnnotationComposer,
      $$ShapesTableCreateCompanionBuilder,
      $$ShapesTableUpdateCompanionBuilder,
      (Shape, BaseReferences<_$AppDatabase, $ShapesTable, Shape>),
      Shape,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AgenciesTableTableManager get agencies =>
      $$AgenciesTableTableManager(_db, _db.agencies);
  $$StopsTableTableManager get stops =>
      $$StopsTableTableManager(_db, _db.stops);
  $$RoutesTableTableManager get routes =>
      $$RoutesTableTableManager(_db, _db.routes);
  $$TripsTableTableManager get trips =>
      $$TripsTableTableManager(_db, _db.trips);
  $$StopTimesTableTableManager get stopTimes =>
      $$StopTimesTableTableManager(_db, _db.stopTimes);
  $$ShapesTableTableManager get shapes =>
      $$ShapesTableTableManager(_db, _db.shapes);
}
