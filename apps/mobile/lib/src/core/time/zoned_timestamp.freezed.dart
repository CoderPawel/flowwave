// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'zoned_timestamp.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ZonedTimestamp {

/// ISO 8601 UTC instant with millisecond precision, ending in `Z`.
 String get utc; String get timeZone; int get utcOffsetMinutes;
/// Create a copy of ZonedTimestamp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ZonedTimestampCopyWith<ZonedTimestamp> get copyWith => _$ZonedTimestampCopyWithImpl<ZonedTimestamp>(this as ZonedTimestamp, _$identity);

  /// Serializes this ZonedTimestamp to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ZonedTimestamp;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ZonedTimestamp&&(identical(other.utc, _this.utc) || other.utc == _this.utc)&&(identical(other.timeZone, _this.timeZone) || other.timeZone == _this.timeZone)&&(identical(other.utcOffsetMinutes, _this.utcOffsetMinutes) || other.utcOffsetMinutes == _this.utcOffsetMinutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ZonedTimestamp;
  return Object.hash(runtimeType,_this.utc,_this.timeZone,_this.utcOffsetMinutes);
}

@override
String toString() {
  final _this = this as ZonedTimestamp;
  return 'ZonedTimestamp(utc: ${_this.utc}, timeZone: ${_this.timeZone}, utcOffsetMinutes: ${_this.utcOffsetMinutes})';
}


}

/// @nodoc
abstract mixin class $ZonedTimestampCopyWith<$Res>  {
  factory $ZonedTimestampCopyWith(ZonedTimestamp value, $Res Function(ZonedTimestamp) _then) = _$ZonedTimestampCopyWithImpl;
@useResult
$Res call({
 String utc, String timeZone, int utcOffsetMinutes
});




}
/// @nodoc
class _$ZonedTimestampCopyWithImpl<$Res>
    implements $ZonedTimestampCopyWith<$Res> {
  _$ZonedTimestampCopyWithImpl(this._self, this._then);

  final ZonedTimestamp _self;
  final $Res Function(ZonedTimestamp) _then;

/// Create a copy of ZonedTimestamp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? utc = null,Object? timeZone = null,Object? utcOffsetMinutes = null,}) {
  return _then(ZonedTimestamp(
utc: null == utc ? _self.utc : utc // ignore: cast_nullable_to_non_nullable
as String,timeZone: null == timeZone ? _self.timeZone : timeZone // ignore: cast_nullable_to_non_nullable
as String,utcOffsetMinutes: null == utcOffsetMinutes ? _self.utcOffsetMinutes : utcOffsetMinutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ZonedTimestamp].
extension ZonedTimestampPatterns on ZonedTimestamp {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ZonedTimestamp value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ZonedTimestamp() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ZonedTimestamp value)  $default,){
final _that = this;
switch (_that) {
case _ZonedTimestamp():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ZonedTimestamp value)?  $default,){
final _that = this;
switch (_that) {
case _ZonedTimestamp() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String utc,  String timeZone,  int utcOffsetMinutes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ZonedTimestamp() when $default != null:
return $default(_that.utc,_that.timeZone,_that.utcOffsetMinutes);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String utc,  String timeZone,  int utcOffsetMinutes)  $default,) {final _that = this;
switch (_that) {
case _ZonedTimestamp():
return $default(_that.utc,_that.timeZone,_that.utcOffsetMinutes);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String utc,  String timeZone,  int utcOffsetMinutes)?  $default,) {final _that = this;
switch (_that) {
case _ZonedTimestamp() when $default != null:
return $default(_that.utc,_that.timeZone,_that.utcOffsetMinutes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ZonedTimestamp extends ZonedTimestamp {
  const _ZonedTimestamp({required this.utc, required this.timeZone, required this.utcOffsetMinutes}): super._();
  factory _ZonedTimestamp.fromJson(Map<String, dynamic> json) => _$ZonedTimestampFromJson(json);

/// ISO 8601 UTC instant with millisecond precision, ending in `Z`.
@override final  String utc;
@override final  String timeZone;
@override final  int utcOffsetMinutes;

/// Create a copy of ZonedTimestamp
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ZonedTimestampCopyWith<_ZonedTimestamp> get copyWith => __$ZonedTimestampCopyWithImpl<_ZonedTimestamp>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ZonedTimestampToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ZonedTimestamp&&(identical(other.utc, utc) || other.utc == utc)&&(identical(other.timeZone, timeZone) || other.timeZone == timeZone)&&(identical(other.utcOffsetMinutes, utcOffsetMinutes) || other.utcOffsetMinutes == utcOffsetMinutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,utc,timeZone,utcOffsetMinutes);
}

@override
String toString() {
    return 'ZonedTimestamp(utc: $utc, timeZone: $timeZone, utcOffsetMinutes: $utcOffsetMinutes)';
}


}

/// @nodoc
abstract mixin class _$ZonedTimestampCopyWith<$Res> implements $ZonedTimestampCopyWith<$Res> {
  factory _$ZonedTimestampCopyWith(_ZonedTimestamp value, $Res Function(_ZonedTimestamp) _then) = __$ZonedTimestampCopyWithImpl;
@override @useResult
$Res call({
 String utc, String timeZone, int utcOffsetMinutes
});




}
/// @nodoc
class __$ZonedTimestampCopyWithImpl<$Res>
    implements _$ZonedTimestampCopyWith<$Res> {
  __$ZonedTimestampCopyWithImpl(this._self, this._then);

  final _ZonedTimestamp _self;
  final $Res Function(_ZonedTimestamp) _then;

/// Create a copy of ZonedTimestamp
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? utc = null,Object? timeZone = null,Object? utcOffsetMinutes = null,}) {
  return _then(_ZonedTimestamp(
utc: null == utc ? _self.utc : utc // ignore: cast_nullable_to_non_nullable
as String,timeZone: null == timeZone ? _self.timeZone : timeZone // ignore: cast_nullable_to_non_nullable
as String,utcOffsetMinutes: null == utcOffsetMinutes ? _self.utcOffsetMinutes : utcOffsetMinutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
