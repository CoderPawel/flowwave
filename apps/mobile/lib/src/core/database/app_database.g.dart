// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalSettingsTable extends LocalSettings
    with TableInfo<$LocalSettingsTable, LocalSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _themePreferenceMeta = const VerificationMeta(
    'themePreference',
  );
  @override
  late final GeneratedColumn<String> themePreference = GeneratedColumn<String>(
    'theme_preference',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('system'),
  );
  static const VerificationMeta _languagePreferenceMeta =
      const VerificationMeta('languagePreference');
  @override
  late final GeneratedColumn<String> languagePreference =
      GeneratedColumn<String>(
        'language_preference',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('system'),
      );
  static const VerificationMeta _onboardingCompletedAtUtcMeta =
      const VerificationMeta('onboardingCompletedAtUtc');
  @override
  late final GeneratedColumn<DateTime> onboardingCompletedAtUtc =
      GeneratedColumn<DateTime>(
        'onboarding_completed_at_utc',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    themePreference,
    languagePreference,
    onboardingCompletedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('theme_preference')) {
      context.handle(
        _themePreferenceMeta,
        themePreference.isAcceptableOrUnknown(
          data['theme_preference']!,
          _themePreferenceMeta,
        ),
      );
    }
    if (data.containsKey('language_preference')) {
      context.handle(
        _languagePreferenceMeta,
        languagePreference.isAcceptableOrUnknown(
          data['language_preference']!,
          _languagePreferenceMeta,
        ),
      );
    }
    if (data.containsKey('onboarding_completed_at_utc')) {
      context.handle(
        _onboardingCompletedAtUtcMeta,
        onboardingCompletedAtUtc.isAcceptableOrUnknown(
          data['onboarding_completed_at_utc']!,
          _onboardingCompletedAtUtcMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      themePreference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_preference'],
      )!,
      languagePreference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language_preference'],
      )!,
      onboardingCompletedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}onboarding_completed_at_utc'],
      ),
    );
  }

  @override
  $LocalSettingsTable createAlias(String alias) {
    return $LocalSettingsTable(attachedDatabase, alias);
  }
}

class LocalSettingsRow extends DataClass
    implements Insertable<LocalSettingsRow> {
  final int id;

  /// `system`, `light` or `dark`.
  final String themePreference;

  /// `system`, `en` or `pl`.
  final String languagePreference;

  /// When the user finished onboarding; `null` until then.
  final DateTime? onboardingCompletedAtUtc;
  const LocalSettingsRow({
    required this.id,
    required this.themePreference,
    required this.languagePreference,
    this.onboardingCompletedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['theme_preference'] = Variable<String>(themePreference);
    map['language_preference'] = Variable<String>(languagePreference);
    if (!nullToAbsent || onboardingCompletedAtUtc != null) {
      map['onboarding_completed_at_utc'] = Variable<DateTime>(
        onboardingCompletedAtUtc,
      );
    }
    return map;
  }

  LocalSettingsCompanion toCompanion(bool nullToAbsent) {
    return LocalSettingsCompanion(
      id: Value(id),
      themePreference: Value(themePreference),
      languagePreference: Value(languagePreference),
      onboardingCompletedAtUtc: onboardingCompletedAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(onboardingCompletedAtUtc),
    );
  }

  factory LocalSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSettingsRow(
      id: serializer.fromJson<int>(json['id']),
      themePreference: serializer.fromJson<String>(json['themePreference']),
      languagePreference: serializer.fromJson<String>(
        json['languagePreference'],
      ),
      onboardingCompletedAtUtc: serializer.fromJson<DateTime?>(
        json['onboardingCompletedAtUtc'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'themePreference': serializer.toJson<String>(themePreference),
      'languagePreference': serializer.toJson<String>(languagePreference),
      'onboardingCompletedAtUtc': serializer.toJson<DateTime?>(
        onboardingCompletedAtUtc,
      ),
    };
  }

  LocalSettingsRow copyWith({
    int? id,
    String? themePreference,
    String? languagePreference,
    Value<DateTime?> onboardingCompletedAtUtc = const Value.absent(),
  }) => LocalSettingsRow(
    id: id ?? this.id,
    themePreference: themePreference ?? this.themePreference,
    languagePreference: languagePreference ?? this.languagePreference,
    onboardingCompletedAtUtc: onboardingCompletedAtUtc.present
        ? onboardingCompletedAtUtc.value
        : this.onboardingCompletedAtUtc,
  );
  LocalSettingsRow copyWithCompanion(LocalSettingsCompanion data) {
    return LocalSettingsRow(
      id: data.id.present ? data.id.value : this.id,
      themePreference: data.themePreference.present
          ? data.themePreference.value
          : this.themePreference,
      languagePreference: data.languagePreference.present
          ? data.languagePreference.value
          : this.languagePreference,
      onboardingCompletedAtUtc: data.onboardingCompletedAtUtc.present
          ? data.onboardingCompletedAtUtc.value
          : this.onboardingCompletedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSettingsRow(')
          ..write('id: $id, ')
          ..write('themePreference: $themePreference, ')
          ..write('languagePreference: $languagePreference, ')
          ..write('onboardingCompletedAtUtc: $onboardingCompletedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    themePreference,
    languagePreference,
    onboardingCompletedAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSettingsRow &&
          other.id == this.id &&
          other.themePreference == this.themePreference &&
          other.languagePreference == this.languagePreference &&
          other.onboardingCompletedAtUtc == this.onboardingCompletedAtUtc);
}

class LocalSettingsCompanion extends UpdateCompanion<LocalSettingsRow> {
  final Value<int> id;
  final Value<String> themePreference;
  final Value<String> languagePreference;
  final Value<DateTime?> onboardingCompletedAtUtc;
  const LocalSettingsCompanion({
    this.id = const Value.absent(),
    this.themePreference = const Value.absent(),
    this.languagePreference = const Value.absent(),
    this.onboardingCompletedAtUtc = const Value.absent(),
  });
  LocalSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.themePreference = const Value.absent(),
    this.languagePreference = const Value.absent(),
    this.onboardingCompletedAtUtc = const Value.absent(),
  });
  static Insertable<LocalSettingsRow> custom({
    Expression<int>? id,
    Expression<String>? themePreference,
    Expression<String>? languagePreference,
    Expression<DateTime>? onboardingCompletedAtUtc,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (themePreference != null) 'theme_preference': themePreference,
      if (languagePreference != null) 'language_preference': languagePreference,
      if (onboardingCompletedAtUtc != null)
        'onboarding_completed_at_utc': onboardingCompletedAtUtc,
    });
  }

  LocalSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? themePreference,
    Value<String>? languagePreference,
    Value<DateTime?>? onboardingCompletedAtUtc,
  }) {
    return LocalSettingsCompanion(
      id: id ?? this.id,
      themePreference: themePreference ?? this.themePreference,
      languagePreference: languagePreference ?? this.languagePreference,
      onboardingCompletedAtUtc:
          onboardingCompletedAtUtc ?? this.onboardingCompletedAtUtc,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (themePreference.present) {
      map['theme_preference'] = Variable<String>(themePreference.value);
    }
    if (languagePreference.present) {
      map['language_preference'] = Variable<String>(languagePreference.value);
    }
    if (onboardingCompletedAtUtc.present) {
      map['onboarding_completed_at_utc'] = Variable<DateTime>(
        onboardingCompletedAtUtc.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSettingsCompanion(')
          ..write('id: $id, ')
          ..write('themePreference: $themePreference, ')
          ..write('languagePreference: $languagePreference, ')
          ..write('onboardingCompletedAtUtc: $onboardingCompletedAtUtc')
          ..write(')'))
        .toString();
  }
}

class $ConsentDecisionsTable extends ConsentDecisions
    with TableInfo<$ConsentDecisionsTable, ConsentDecisionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConsentDecisionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _consentTypeMeta = const VerificationMeta(
    'consentType',
  );
  @override
  late final GeneratedColumn<String> consentType = GeneratedColumn<String>(
    'consent_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> scopes =
      GeneratedColumn<String>(
        'scopes',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>($ConsentDecisionsTable.$converterscopes);
  static const VerificationMeta _policyVersionMeta = const VerificationMeta(
    'policyVersion',
  );
  @override
  late final GeneratedColumn<String> policyVersion = GeneratedColumn<String>(
    'policy_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _decidedAtUtcMeta = const VerificationMeta(
    'decidedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> decidedAtUtc = GeneratedColumn<DateTime>(
    'decided_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _decidedTimeZoneMeta = const VerificationMeta(
    'decidedTimeZone',
  );
  @override
  late final GeneratedColumn<String> decidedTimeZone = GeneratedColumn<String>(
    'decided_time_zone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _decidedUtcOffsetMinutesMeta =
      const VerificationMeta('decidedUtcOffsetMinutes');
  @override
  late final GeneratedColumn<int> decidedUtcOffsetMinutes =
      GeneratedColumn<int>(
        'decided_utc_offset_minutes',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _syncedAtUtcMeta = const VerificationMeta(
    'syncedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAtUtc = GeneratedColumn<DateTime>(
    'synced_at_utc',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    consentType,
    sourceId,
    state,
    scopes,
    policyVersion,
    decidedAtUtc,
    decidedTimeZone,
    decidedUtcOffsetMinutes,
    syncedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'consent_decisions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConsentDecisionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('consent_type')) {
      context.handle(
        _consentTypeMeta,
        consentType.isAcceptableOrUnknown(
          data['consent_type']!,
          _consentTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_consentTypeMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('policy_version')) {
      context.handle(
        _policyVersionMeta,
        policyVersion.isAcceptableOrUnknown(
          data['policy_version']!,
          _policyVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_policyVersionMeta);
    }
    if (data.containsKey('decided_at_utc')) {
      context.handle(
        _decidedAtUtcMeta,
        decidedAtUtc.isAcceptableOrUnknown(
          data['decided_at_utc']!,
          _decidedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_decidedAtUtcMeta);
    }
    if (data.containsKey('decided_time_zone')) {
      context.handle(
        _decidedTimeZoneMeta,
        decidedTimeZone.isAcceptableOrUnknown(
          data['decided_time_zone']!,
          _decidedTimeZoneMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_decidedTimeZoneMeta);
    }
    if (data.containsKey('decided_utc_offset_minutes')) {
      context.handle(
        _decidedUtcOffsetMinutesMeta,
        decidedUtcOffsetMinutes.isAcceptableOrUnknown(
          data['decided_utc_offset_minutes']!,
          _decidedUtcOffsetMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_decidedUtcOffsetMinutesMeta);
    }
    if (data.containsKey('synced_at_utc')) {
      context.handle(
        _syncedAtUtcMeta,
        syncedAtUtc.isAcceptableOrUnknown(
          data['synced_at_utc']!,
          _syncedAtUtcMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConsentDecisionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConsentDecisionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      consentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}consent_type'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      scopes: $ConsentDecisionsTable.$converterscopes.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}scopes'],
        )!,
      ),
      policyVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}policy_version'],
      )!,
      decidedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}decided_at_utc'],
      )!,
      decidedTimeZone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}decided_time_zone'],
      )!,
      decidedUtcOffsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}decided_utc_offset_minutes'],
      )!,
      syncedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at_utc'],
      ),
    );
  }

  @override
  $ConsentDecisionsTable createAlias(String alias) {
    return $ConsentDecisionsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $converterscopes =
      const StringListConverter();
}

class ConsentDecisionRow extends DataClass
    implements Insertable<ConsentDecisionRow> {
  /// UUID generated on the phone; also the idempotency key of the upload.
  final String id;

  /// `health_data`, `device_usage`, `notifications` or `analytics`.
  final String consentType;

  /// The external source for `health_data`, otherwise `null`.
  final String? sourceId;

  /// `granted` or `revoked`.
  final String state;

  /// Granted scopes as a JSON array; empty for revocations and other types.
  final List<String> scopes;
  final String policyVersion;
  final DateTime decidedAtUtc;
  final String decidedTimeZone;
  final int decidedUtcOffsetMinutes;

  /// When the server confirmed the decision; `null` while only on the phone.
  final DateTime? syncedAtUtc;
  const ConsentDecisionRow({
    required this.id,
    required this.consentType,
    this.sourceId,
    required this.state,
    required this.scopes,
    required this.policyVersion,
    required this.decidedAtUtc,
    required this.decidedTimeZone,
    required this.decidedUtcOffsetMinutes,
    this.syncedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['consent_type'] = Variable<String>(consentType);
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    map['state'] = Variable<String>(state);
    {
      map['scopes'] = Variable<String>(
        $ConsentDecisionsTable.$converterscopes.toSql(scopes),
      );
    }
    map['policy_version'] = Variable<String>(policyVersion);
    map['decided_at_utc'] = Variable<DateTime>(decidedAtUtc);
    map['decided_time_zone'] = Variable<String>(decidedTimeZone);
    map['decided_utc_offset_minutes'] = Variable<int>(decidedUtcOffsetMinutes);
    if (!nullToAbsent || syncedAtUtc != null) {
      map['synced_at_utc'] = Variable<DateTime>(syncedAtUtc);
    }
    return map;
  }

  ConsentDecisionsCompanion toCompanion(bool nullToAbsent) {
    return ConsentDecisionsCompanion(
      id: Value(id),
      consentType: Value(consentType),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      state: Value(state),
      scopes: Value(scopes),
      policyVersion: Value(policyVersion),
      decidedAtUtc: Value(decidedAtUtc),
      decidedTimeZone: Value(decidedTimeZone),
      decidedUtcOffsetMinutes: Value(decidedUtcOffsetMinutes),
      syncedAtUtc: syncedAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAtUtc),
    );
  }

  factory ConsentDecisionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConsentDecisionRow(
      id: serializer.fromJson<String>(json['id']),
      consentType: serializer.fromJson<String>(json['consentType']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      state: serializer.fromJson<String>(json['state']),
      scopes: serializer.fromJson<List<String>>(json['scopes']),
      policyVersion: serializer.fromJson<String>(json['policyVersion']),
      decidedAtUtc: serializer.fromJson<DateTime>(json['decidedAtUtc']),
      decidedTimeZone: serializer.fromJson<String>(json['decidedTimeZone']),
      decidedUtcOffsetMinutes: serializer.fromJson<int>(
        json['decidedUtcOffsetMinutes'],
      ),
      syncedAtUtc: serializer.fromJson<DateTime?>(json['syncedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'consentType': serializer.toJson<String>(consentType),
      'sourceId': serializer.toJson<String?>(sourceId),
      'state': serializer.toJson<String>(state),
      'scopes': serializer.toJson<List<String>>(scopes),
      'policyVersion': serializer.toJson<String>(policyVersion),
      'decidedAtUtc': serializer.toJson<DateTime>(decidedAtUtc),
      'decidedTimeZone': serializer.toJson<String>(decidedTimeZone),
      'decidedUtcOffsetMinutes': serializer.toJson<int>(
        decidedUtcOffsetMinutes,
      ),
      'syncedAtUtc': serializer.toJson<DateTime?>(syncedAtUtc),
    };
  }

  ConsentDecisionRow copyWith({
    String? id,
    String? consentType,
    Value<String?> sourceId = const Value.absent(),
    String? state,
    List<String>? scopes,
    String? policyVersion,
    DateTime? decidedAtUtc,
    String? decidedTimeZone,
    int? decidedUtcOffsetMinutes,
    Value<DateTime?> syncedAtUtc = const Value.absent(),
  }) => ConsentDecisionRow(
    id: id ?? this.id,
    consentType: consentType ?? this.consentType,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    state: state ?? this.state,
    scopes: scopes ?? this.scopes,
    policyVersion: policyVersion ?? this.policyVersion,
    decidedAtUtc: decidedAtUtc ?? this.decidedAtUtc,
    decidedTimeZone: decidedTimeZone ?? this.decidedTimeZone,
    decidedUtcOffsetMinutes:
        decidedUtcOffsetMinutes ?? this.decidedUtcOffsetMinutes,
    syncedAtUtc: syncedAtUtc.present ? syncedAtUtc.value : this.syncedAtUtc,
  );
  ConsentDecisionRow copyWithCompanion(ConsentDecisionsCompanion data) {
    return ConsentDecisionRow(
      id: data.id.present ? data.id.value : this.id,
      consentType: data.consentType.present
          ? data.consentType.value
          : this.consentType,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      state: data.state.present ? data.state.value : this.state,
      scopes: data.scopes.present ? data.scopes.value : this.scopes,
      policyVersion: data.policyVersion.present
          ? data.policyVersion.value
          : this.policyVersion,
      decidedAtUtc: data.decidedAtUtc.present
          ? data.decidedAtUtc.value
          : this.decidedAtUtc,
      decidedTimeZone: data.decidedTimeZone.present
          ? data.decidedTimeZone.value
          : this.decidedTimeZone,
      decidedUtcOffsetMinutes: data.decidedUtcOffsetMinutes.present
          ? data.decidedUtcOffsetMinutes.value
          : this.decidedUtcOffsetMinutes,
      syncedAtUtc: data.syncedAtUtc.present
          ? data.syncedAtUtc.value
          : this.syncedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConsentDecisionRow(')
          ..write('id: $id, ')
          ..write('consentType: $consentType, ')
          ..write('sourceId: $sourceId, ')
          ..write('state: $state, ')
          ..write('scopes: $scopes, ')
          ..write('policyVersion: $policyVersion, ')
          ..write('decidedAtUtc: $decidedAtUtc, ')
          ..write('decidedTimeZone: $decidedTimeZone, ')
          ..write('decidedUtcOffsetMinutes: $decidedUtcOffsetMinutes, ')
          ..write('syncedAtUtc: $syncedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    consentType,
    sourceId,
    state,
    scopes,
    policyVersion,
    decidedAtUtc,
    decidedTimeZone,
    decidedUtcOffsetMinutes,
    syncedAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConsentDecisionRow &&
          other.id == this.id &&
          other.consentType == this.consentType &&
          other.sourceId == this.sourceId &&
          other.state == this.state &&
          other.scopes == this.scopes &&
          other.policyVersion == this.policyVersion &&
          other.decidedAtUtc == this.decidedAtUtc &&
          other.decidedTimeZone == this.decidedTimeZone &&
          other.decidedUtcOffsetMinutes == this.decidedUtcOffsetMinutes &&
          other.syncedAtUtc == this.syncedAtUtc);
}

class ConsentDecisionsCompanion extends UpdateCompanion<ConsentDecisionRow> {
  final Value<String> id;
  final Value<String> consentType;
  final Value<String?> sourceId;
  final Value<String> state;
  final Value<List<String>> scopes;
  final Value<String> policyVersion;
  final Value<DateTime> decidedAtUtc;
  final Value<String> decidedTimeZone;
  final Value<int> decidedUtcOffsetMinutes;
  final Value<DateTime?> syncedAtUtc;
  final Value<int> rowid;
  const ConsentDecisionsCompanion({
    this.id = const Value.absent(),
    this.consentType = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.state = const Value.absent(),
    this.scopes = const Value.absent(),
    this.policyVersion = const Value.absent(),
    this.decidedAtUtc = const Value.absent(),
    this.decidedTimeZone = const Value.absent(),
    this.decidedUtcOffsetMinutes = const Value.absent(),
    this.syncedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConsentDecisionsCompanion.insert({
    required String id,
    required String consentType,
    this.sourceId = const Value.absent(),
    required String state,
    required List<String> scopes,
    required String policyVersion,
    required DateTime decidedAtUtc,
    required String decidedTimeZone,
    required int decidedUtcOffsetMinutes,
    this.syncedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       consentType = Value(consentType),
       state = Value(state),
       scopes = Value(scopes),
       policyVersion = Value(policyVersion),
       decidedAtUtc = Value(decidedAtUtc),
       decidedTimeZone = Value(decidedTimeZone),
       decidedUtcOffsetMinutes = Value(decidedUtcOffsetMinutes);
  static Insertable<ConsentDecisionRow> custom({
    Expression<String>? id,
    Expression<String>? consentType,
    Expression<String>? sourceId,
    Expression<String>? state,
    Expression<String>? scopes,
    Expression<String>? policyVersion,
    Expression<DateTime>? decidedAtUtc,
    Expression<String>? decidedTimeZone,
    Expression<int>? decidedUtcOffsetMinutes,
    Expression<DateTime>? syncedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (consentType != null) 'consent_type': consentType,
      if (sourceId != null) 'source_id': sourceId,
      if (state != null) 'state': state,
      if (scopes != null) 'scopes': scopes,
      if (policyVersion != null) 'policy_version': policyVersion,
      if (decidedAtUtc != null) 'decided_at_utc': decidedAtUtc,
      if (decidedTimeZone != null) 'decided_time_zone': decidedTimeZone,
      if (decidedUtcOffsetMinutes != null)
        'decided_utc_offset_minutes': decidedUtcOffsetMinutes,
      if (syncedAtUtc != null) 'synced_at_utc': syncedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConsentDecisionsCompanion copyWith({
    Value<String>? id,
    Value<String>? consentType,
    Value<String?>? sourceId,
    Value<String>? state,
    Value<List<String>>? scopes,
    Value<String>? policyVersion,
    Value<DateTime>? decidedAtUtc,
    Value<String>? decidedTimeZone,
    Value<int>? decidedUtcOffsetMinutes,
    Value<DateTime?>? syncedAtUtc,
    Value<int>? rowid,
  }) {
    return ConsentDecisionsCompanion(
      id: id ?? this.id,
      consentType: consentType ?? this.consentType,
      sourceId: sourceId ?? this.sourceId,
      state: state ?? this.state,
      scopes: scopes ?? this.scopes,
      policyVersion: policyVersion ?? this.policyVersion,
      decidedAtUtc: decidedAtUtc ?? this.decidedAtUtc,
      decidedTimeZone: decidedTimeZone ?? this.decidedTimeZone,
      decidedUtcOffsetMinutes:
          decidedUtcOffsetMinutes ?? this.decidedUtcOffsetMinutes,
      syncedAtUtc: syncedAtUtc ?? this.syncedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (consentType.present) {
      map['consent_type'] = Variable<String>(consentType.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (scopes.present) {
      map['scopes'] = Variable<String>(
        $ConsentDecisionsTable.$converterscopes.toSql(scopes.value),
      );
    }
    if (policyVersion.present) {
      map['policy_version'] = Variable<String>(policyVersion.value);
    }
    if (decidedAtUtc.present) {
      map['decided_at_utc'] = Variable<DateTime>(decidedAtUtc.value);
    }
    if (decidedTimeZone.present) {
      map['decided_time_zone'] = Variable<String>(decidedTimeZone.value);
    }
    if (decidedUtcOffsetMinutes.present) {
      map['decided_utc_offset_minutes'] = Variable<int>(
        decidedUtcOffsetMinutes.value,
      );
    }
    if (syncedAtUtc.present) {
      map['synced_at_utc'] = Variable<DateTime>(syncedAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConsentDecisionsCompanion(')
          ..write('id: $id, ')
          ..write('consentType: $consentType, ')
          ..write('sourceId: $sourceId, ')
          ..write('state: $state, ')
          ..write('scopes: $scopes, ')
          ..write('policyVersion: $policyVersion, ')
          ..write('decidedAtUtc: $decidedAtUtc, ')
          ..write('decidedTimeZone: $decidedTimeZone, ')
          ..write('decidedUtcOffsetMinutes: $decidedUtcOffsetMinutes, ')
          ..write('syncedAtUtc: $syncedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxOperationsTable extends OutboxOperations
    with TableInfo<$OutboxOperationsTable, OutboxOperationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxOperationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtUtcMeta = const VerificationMeta(
    'nextAttemptAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAtUtc =
      GeneratedColumn<DateTime>(
        'next_attempt_at_utc',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    payload,
    createdAtUtc,
    attempts,
    nextAttemptAtUtc,
    status,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_operations';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxOperationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('next_attempt_at_utc')) {
      context.handle(
        _nextAttemptAtUtcMeta,
        nextAttemptAtUtc.isAcceptableOrUnknown(
          data['next_attempt_at_utc']!,
          _nextAttemptAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextAttemptAtUtcMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxOperationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxOperationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_utc'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      nextAttemptAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at_utc'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $OutboxOperationsTable createAlias(String alias) {
    return $OutboxOperationsTable(attachedDatabase, alias);
  }
}

class OutboxOperationRow extends DataClass
    implements Insertable<OutboxOperationRow> {
  /// Operation ID, equal to the ID of the entity it uploads (rule 7).
  final String id;

  /// Which transport sends it, for example `consent_decision`.
  final String kind;

  /// The request body as JSON.
  final String payload;
  final DateTime createdAtUtc;
  final int attempts;
  final DateTime nextAttemptAtUtc;

  /// `pending`, or `rejected` when the API refused it for good.
  final String status;

  /// Stable failure code of the last attempt, never a server message.
  final String? lastError;
  const OutboxOperationRow({
    required this.id,
    required this.kind,
    required this.payload,
    required this.createdAtUtc,
    required this.attempts,
    required this.nextAttemptAtUtc,
    required this.status,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['payload'] = Variable<String>(payload);
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    map['attempts'] = Variable<int>(attempts);
    map['next_attempt_at_utc'] = Variable<DateTime>(nextAttemptAtUtc);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  OutboxOperationsCompanion toCompanion(bool nullToAbsent) {
    return OutboxOperationsCompanion(
      id: Value(id),
      kind: Value(kind),
      payload: Value(payload),
      createdAtUtc: Value(createdAtUtc),
      attempts: Value(attempts),
      nextAttemptAtUtc: Value(nextAttemptAtUtc),
      status: Value(status),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory OutboxOperationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxOperationRow(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextAttemptAtUtc: serializer.fromJson<DateTime>(json['nextAttemptAtUtc']),
      status: serializer.fromJson<String>(json['status']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'payload': serializer.toJson<String>(payload),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
      'attempts': serializer.toJson<int>(attempts),
      'nextAttemptAtUtc': serializer.toJson<DateTime>(nextAttemptAtUtc),
      'status': serializer.toJson<String>(status),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  OutboxOperationRow copyWith({
    String? id,
    String? kind,
    String? payload,
    DateTime? createdAtUtc,
    int? attempts,
    DateTime? nextAttemptAtUtc,
    String? status,
    Value<String?> lastError = const Value.absent(),
  }) => OutboxOperationRow(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    payload: payload ?? this.payload,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    attempts: attempts ?? this.attempts,
    nextAttemptAtUtc: nextAttemptAtUtc ?? this.nextAttemptAtUtc,
    status: status ?? this.status,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  OutboxOperationRow copyWithCompanion(OutboxOperationsCompanion data) {
    return OutboxOperationRow(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextAttemptAtUtc: data.nextAttemptAtUtc.present
          ? data.nextAttemptAtUtc.value
          : this.nextAttemptAtUtc,
      status: data.status.present ? data.status.value : this.status,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxOperationRow(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('payload: $payload, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAtUtc: $nextAttemptAtUtc, ')
          ..write('status: $status, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    payload,
    createdAtUtc,
    attempts,
    nextAttemptAtUtc,
    status,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxOperationRow &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.payload == this.payload &&
          other.createdAtUtc == this.createdAtUtc &&
          other.attempts == this.attempts &&
          other.nextAttemptAtUtc == this.nextAttemptAtUtc &&
          other.status == this.status &&
          other.lastError == this.lastError);
}

class OutboxOperationsCompanion extends UpdateCompanion<OutboxOperationRow> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> payload;
  final Value<DateTime> createdAtUtc;
  final Value<int> attempts;
  final Value<DateTime> nextAttemptAtUtc;
  final Value<String> status;
  final Value<String?> lastError;
  final Value<int> rowid;
  const OutboxOperationsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAtUtc = const Value.absent(),
    this.status = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxOperationsCompanion.insert({
    required String id,
    required String kind,
    required String payload,
    required DateTime createdAtUtc,
    this.attempts = const Value.absent(),
    required DateTime nextAttemptAtUtc,
    this.status = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       payload = Value(payload),
       createdAtUtc = Value(createdAtUtc),
       nextAttemptAtUtc = Value(nextAttemptAtUtc);
  static Insertable<OutboxOperationRow> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? payload,
    Expression<DateTime>? createdAtUtc,
    Expression<int>? attempts,
    Expression<DateTime>? nextAttemptAtUtc,
    Expression<String>? status,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (payload != null) 'payload': payload,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (attempts != null) 'attempts': attempts,
      if (nextAttemptAtUtc != null) 'next_attempt_at_utc': nextAttemptAtUtc,
      if (status != null) 'status': status,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxOperationsCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String>? payload,
    Value<DateTime>? createdAtUtc,
    Value<int>? attempts,
    Value<DateTime>? nextAttemptAtUtc,
    Value<String>? status,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return OutboxOperationsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      payload: payload ?? this.payload,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      attempts: attempts ?? this.attempts,
      nextAttemptAtUtc: nextAttemptAtUtc ?? this.nextAttemptAtUtc,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextAttemptAtUtc.present) {
      map['next_attempt_at_utc'] = Variable<DateTime>(nextAttemptAtUtc.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxOperationsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('payload: $payload, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAtUtc: $nextAttemptAtUtc, ')
          ..write('status: $status, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalSettingsTable localSettings = $LocalSettingsTable(this);
  late final $ConsentDecisionsTable consentDecisions = $ConsentDecisionsTable(
    this,
  );
  late final $OutboxOperationsTable outboxOperations = $OutboxOperationsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localSettings,
    consentDecisions,
    outboxOperations,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$LocalSettingsTableCreateCompanionBuilder =
    LocalSettingsCompanion Function({
      Value<int> id,
      Value<String> themePreference,
      Value<String> languagePreference,
      Value<DateTime?> onboardingCompletedAtUtc,
    });
typedef $$LocalSettingsTableUpdateCompanionBuilder =
    LocalSettingsCompanion Function({
      Value<int> id,
      Value<String> themePreference,
      Value<String> languagePreference,
      Value<DateTime?> onboardingCompletedAtUtc,
    });

class $$LocalSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themePreference => $composableBuilder(
    column: $table.themePreference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get languagePreference => $composableBuilder(
    column: $table.languagePreference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get onboardingCompletedAtUtc => $composableBuilder(
    column: $table.onboardingCompletedAtUtc,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themePreference => $composableBuilder(
    column: $table.themePreference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get languagePreference => $composableBuilder(
    column: $table.languagePreference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get onboardingCompletedAtUtc => $composableBuilder(
    column: $table.onboardingCompletedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get themePreference => $composableBuilder(
    column: $table.themePreference,
    builder: (column) => column,
  );

  GeneratedColumn<String> get languagePreference => $composableBuilder(
    column: $table.languagePreference,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get onboardingCompletedAtUtc => $composableBuilder(
    column: $table.onboardingCompletedAtUtc,
    builder: (column) => column,
  );
}

class $$LocalSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSettingsTable,
          LocalSettingsRow,
          $$LocalSettingsTableFilterComposer,
          $$LocalSettingsTableOrderingComposer,
          $$LocalSettingsTableAnnotationComposer,
          $$LocalSettingsTableCreateCompanionBuilder,
          $$LocalSettingsTableUpdateCompanionBuilder,
          (
            LocalSettingsRow,
            BaseReferences<
              _$AppDatabase,
              $LocalSettingsTable,
              LocalSettingsRow
            >,
          ),
          LocalSettingsRow,
          PrefetchHooks Function()
        > {
  $$LocalSettingsTableTableManager(_$AppDatabase db, $LocalSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> themePreference = const Value.absent(),
                Value<String> languagePreference = const Value.absent(),
                Value<DateTime?> onboardingCompletedAtUtc =
                    const Value.absent(),
              }) => LocalSettingsCompanion(
                id: id,
                themePreference: themePreference,
                languagePreference: languagePreference,
                onboardingCompletedAtUtc: onboardingCompletedAtUtc,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> themePreference = const Value.absent(),
                Value<String> languagePreference = const Value.absent(),
                Value<DateTime?> onboardingCompletedAtUtc =
                    const Value.absent(),
              }) => LocalSettingsCompanion.insert(
                id: id,
                themePreference: themePreference,
                languagePreference: languagePreference,
                onboardingCompletedAtUtc: onboardingCompletedAtUtc,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalSettingsTable, LocalSettingsRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalSettingsTable,
                    LocalSettingsRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSettingsTable,
      LocalSettingsRow,
      $$LocalSettingsTableFilterComposer,
      $$LocalSettingsTableOrderingComposer,
      $$LocalSettingsTableAnnotationComposer,
      $$LocalSettingsTableCreateCompanionBuilder,
      $$LocalSettingsTableUpdateCompanionBuilder,
      (
        LocalSettingsRow,
        BaseReferences<_$AppDatabase, $LocalSettingsTable, LocalSettingsRow>,
      ),
      LocalSettingsRow,
      PrefetchHooks Function()
    >;
typedef $$ConsentDecisionsTableCreateCompanionBuilder =
    ConsentDecisionsCompanion Function({
      required String id,
      required String consentType,
      Value<String?> sourceId,
      required String state,
      required List<String> scopes,
      required String policyVersion,
      required DateTime decidedAtUtc,
      required String decidedTimeZone,
      required int decidedUtcOffsetMinutes,
      Value<DateTime?> syncedAtUtc,
      Value<int> rowid,
    });
typedef $$ConsentDecisionsTableUpdateCompanionBuilder =
    ConsentDecisionsCompanion Function({
      Value<String> id,
      Value<String> consentType,
      Value<String?> sourceId,
      Value<String> state,
      Value<List<String>> scopes,
      Value<String> policyVersion,
      Value<DateTime> decidedAtUtc,
      Value<String> decidedTimeZone,
      Value<int> decidedUtcOffsetMinutes,
      Value<DateTime?> syncedAtUtc,
      Value<int> rowid,
    });

class $$ConsentDecisionsTableFilterComposer
    extends Composer<_$AppDatabase, $ConsentDecisionsTable> {
  $$ConsentDecisionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get consentType => $composableBuilder(
    column: $table.consentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get scopes => $composableBuilder(
    column: $table.scopes,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get policyVersion => $composableBuilder(
    column: $table.policyVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get decidedAtUtc => $composableBuilder(
    column: $table.decidedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get decidedTimeZone => $composableBuilder(
    column: $table.decidedTimeZone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get decidedUtcOffsetMinutes => $composableBuilder(
    column: $table.decidedUtcOffsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAtUtc => $composableBuilder(
    column: $table.syncedAtUtc,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConsentDecisionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConsentDecisionsTable> {
  $$ConsentDecisionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get consentType => $composableBuilder(
    column: $table.consentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopes => $composableBuilder(
    column: $table.scopes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get policyVersion => $composableBuilder(
    column: $table.policyVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get decidedAtUtc => $composableBuilder(
    column: $table.decidedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get decidedTimeZone => $composableBuilder(
    column: $table.decidedTimeZone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get decidedUtcOffsetMinutes => $composableBuilder(
    column: $table.decidedUtcOffsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAtUtc => $composableBuilder(
    column: $table.syncedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConsentDecisionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConsentDecisionsTable> {
  $$ConsentDecisionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get consentType => $composableBuilder(
    column: $table.consentType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get scopes =>
      $composableBuilder(column: $table.scopes, builder: (column) => column);

  GeneratedColumn<String> get policyVersion => $composableBuilder(
    column: $table.policyVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get decidedAtUtc => $composableBuilder(
    column: $table.decidedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get decidedTimeZone => $composableBuilder(
    column: $table.decidedTimeZone,
    builder: (column) => column,
  );

  GeneratedColumn<int> get decidedUtcOffsetMinutes => $composableBuilder(
    column: $table.decidedUtcOffsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAtUtc => $composableBuilder(
    column: $table.syncedAtUtc,
    builder: (column) => column,
  );
}

class $$ConsentDecisionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConsentDecisionsTable,
          ConsentDecisionRow,
          $$ConsentDecisionsTableFilterComposer,
          $$ConsentDecisionsTableOrderingComposer,
          $$ConsentDecisionsTableAnnotationComposer,
          $$ConsentDecisionsTableCreateCompanionBuilder,
          $$ConsentDecisionsTableUpdateCompanionBuilder,
          (
            ConsentDecisionRow,
            BaseReferences<
              _$AppDatabase,
              $ConsentDecisionsTable,
              ConsentDecisionRow
            >,
          ),
          ConsentDecisionRow,
          PrefetchHooks Function()
        > {
  $$ConsentDecisionsTableTableManager(
    _$AppDatabase db,
    $ConsentDecisionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConsentDecisionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConsentDecisionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConsentDecisionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> consentType = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<List<String>> scopes = const Value.absent(),
                Value<String> policyVersion = const Value.absent(),
                Value<DateTime> decidedAtUtc = const Value.absent(),
                Value<String> decidedTimeZone = const Value.absent(),
                Value<int> decidedUtcOffsetMinutes = const Value.absent(),
                Value<DateTime?> syncedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConsentDecisionsCompanion(
                id: id,
                consentType: consentType,
                sourceId: sourceId,
                state: state,
                scopes: scopes,
                policyVersion: policyVersion,
                decidedAtUtc: decidedAtUtc,
                decidedTimeZone: decidedTimeZone,
                decidedUtcOffsetMinutes: decidedUtcOffsetMinutes,
                syncedAtUtc: syncedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String consentType,
                Value<String?> sourceId = const Value.absent(),
                required String state,
                required List<String> scopes,
                required String policyVersion,
                required DateTime decidedAtUtc,
                required String decidedTimeZone,
                required int decidedUtcOffsetMinutes,
                Value<DateTime?> syncedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConsentDecisionsCompanion.insert(
                id: id,
                consentType: consentType,
                sourceId: sourceId,
                state: state,
                scopes: scopes,
                policyVersion: policyVersion,
                decidedAtUtc: decidedAtUtc,
                decidedTimeZone: decidedTimeZone,
                decidedUtcOffsetMinutes: decidedUtcOffsetMinutes,
                syncedAtUtc: syncedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ConsentDecisionsTable, ConsentDecisionRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $ConsentDecisionsTable,
                    ConsentDecisionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConsentDecisionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConsentDecisionsTable,
      ConsentDecisionRow,
      $$ConsentDecisionsTableFilterComposer,
      $$ConsentDecisionsTableOrderingComposer,
      $$ConsentDecisionsTableAnnotationComposer,
      $$ConsentDecisionsTableCreateCompanionBuilder,
      $$ConsentDecisionsTableUpdateCompanionBuilder,
      (
        ConsentDecisionRow,
        BaseReferences<
          _$AppDatabase,
          $ConsentDecisionsTable,
          ConsentDecisionRow
        >,
      ),
      ConsentDecisionRow,
      PrefetchHooks Function()
    >;
typedef $$OutboxOperationsTableCreateCompanionBuilder =
    OutboxOperationsCompanion Function({
      required String id,
      required String kind,
      required String payload,
      required DateTime createdAtUtc,
      Value<int> attempts,
      required DateTime nextAttemptAtUtc,
      Value<String> status,
      Value<String?> lastError,
      Value<int> rowid,
    });
typedef $$OutboxOperationsTableUpdateCompanionBuilder =
    OutboxOperationsCompanion Function({
      Value<String> id,
      Value<String> kind,
      Value<String> payload,
      Value<DateTime> createdAtUtc,
      Value<int> attempts,
      Value<DateTime> nextAttemptAtUtc,
      Value<String> status,
      Value<String?> lastError,
      Value<int> rowid,
    });

class $$OutboxOperationsTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxOperationsTable> {
  $$OutboxOperationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAtUtc => $composableBuilder(
    column: $table.nextAttemptAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxOperationsTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxOperationsTable> {
  $$OutboxOperationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAtUtc => $composableBuilder(
    column: $table.nextAttemptAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxOperationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxOperationsTable> {
  $$OutboxOperationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAtUtc => $composableBuilder(
    column: $table.nextAttemptAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$OutboxOperationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxOperationsTable,
          OutboxOperationRow,
          $$OutboxOperationsTableFilterComposer,
          $$OutboxOperationsTableOrderingComposer,
          $$OutboxOperationsTableAnnotationComposer,
          $$OutboxOperationsTableCreateCompanionBuilder,
          $$OutboxOperationsTableUpdateCompanionBuilder,
          (
            OutboxOperationRow,
            BaseReferences<
              _$AppDatabase,
              $OutboxOperationsTable,
              OutboxOperationRow
            >,
          ),
          OutboxOperationRow,
          PrefetchHooks Function()
        > {
  $$OutboxOperationsTableTableManager(
    _$AppDatabase db,
    $OutboxOperationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxOperationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxOperationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxOperationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime> nextAttemptAtUtc = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxOperationsCompanion(
                id: id,
                kind: kind,
                payload: payload,
                createdAtUtc: createdAtUtc,
                attempts: attempts,
                nextAttemptAtUtc: nextAttemptAtUtc,
                status: status,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                required String payload,
                required DateTime createdAtUtc,
                Value<int> attempts = const Value.absent(),
                required DateTime nextAttemptAtUtc,
                Value<String> status = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxOperationsCompanion.insert(
                id: id,
                kind: kind,
                payload: payload,
                createdAtUtc: createdAtUtc,
                attempts: attempts,
                nextAttemptAtUtc: nextAttemptAtUtc,
                status: status,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxOperationsTable, OutboxOperationRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $OutboxOperationsTable,
                    OutboxOperationRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxOperationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxOperationsTable,
      OutboxOperationRow,
      $$OutboxOperationsTableFilterComposer,
      $$OutboxOperationsTableOrderingComposer,
      $$OutboxOperationsTableAnnotationComposer,
      $$OutboxOperationsTableCreateCompanionBuilder,
      $$OutboxOperationsTableUpdateCompanionBuilder,
      (
        OutboxOperationRow,
        BaseReferences<
          _$AppDatabase,
          $OutboxOperationsTable,
          OutboxOperationRow
        >,
      ),
      OutboxOperationRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalSettingsTableTableManager get localSettings =>
      $$LocalSettingsTableTableManager(_db, _db.localSettings);
  $$ConsentDecisionsTableTableManager get consentDecisions =>
      $$ConsentDecisionsTableTableManager(_db, _db.consentDecisions);
  $$OutboxOperationsTableTableManager get outboxOperations =>
      $$OutboxOperationsTableTableManager(_db, _db.outboxOperations);
}
