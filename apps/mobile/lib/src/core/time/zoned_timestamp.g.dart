// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'zoned_timestamp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ZonedTimestamp _$ZonedTimestampFromJson(Map<String, dynamic> json) =>
    _ZonedTimestamp(
      utc: json['utc'] as String,
      timeZone: json['timeZone'] as String,
      utcOffsetMinutes: (json['utcOffsetMinutes'] as num).toInt(),
    );

Map<String, dynamic> _$ZonedTimestampToJson(_ZonedTimestamp instance) =>
    <String, dynamic>{
      'utc': instance.utc,
      'timeZone': instance.timeZone,
      'utcOffsetMinutes': instance.utcOffsetMinutes,
    };
