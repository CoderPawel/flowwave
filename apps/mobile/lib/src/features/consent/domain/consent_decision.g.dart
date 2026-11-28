// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consent_decision.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ConsentDecision _$ConsentDecisionFromJson(
  Map<String, dynamic> json,
) => _ConsentDecision(
  id: json['id'] as String,
  type: $enumDecode(_$ConsentTypeEnumMap, json['type']),
  sourceId: json['sourceId'] as String?,
  state: $enumDecode(_$ConsentStateEnumMap, json['state']),
  scopes:
      (json['scopes'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  policyVersion: json['policyVersion'] as String,
  decidedAt: ZonedTimestamp.fromJson(json['decidedAt'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ConsentDecisionToJson(_ConsentDecision instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$ConsentTypeEnumMap[instance.type]!,
      'sourceId': instance.sourceId,
      'state': _$ConsentStateEnumMap[instance.state]!,
      'scopes': instance.scopes,
      'policyVersion': instance.policyVersion,
      'decidedAt': instance.decidedAt.toJson(),
    };

const _$ConsentTypeEnumMap = {
  ConsentType.healthData: 'health_data',
  ConsentType.deviceUsage: 'device_usage',
  ConsentType.notifications: 'notifications',
  ConsentType.analytics: 'analytics',
};

const _$ConsentStateEnumMap = {
  ConsentState.granted: 'granted',
  ConsentState.revoked: 'revoked',
};
