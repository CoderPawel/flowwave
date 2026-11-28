// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'consent_decision.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ConsentDecision {

 String get id; ConsentType get type;/// The external source for health data, otherwise `null`.
 String? get sourceId; ConsentState get state;/// Granted scopes, sorted. Empty for revocations and types without
/// scopes.
 List<String> get scopes; String get policyVersion; ZonedTimestamp get decidedAt;
/// Create a copy of ConsentDecision
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConsentDecisionCopyWith<ConsentDecision> get copyWith => _$ConsentDecisionCopyWithImpl<ConsentDecision>(this as ConsentDecision, _$identity);

  /// Serializes this ConsentDecision to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ConsentDecision;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConsentDecision&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.sourceId, _this.sourceId) || other.sourceId == _this.sourceId)&&(identical(other.state, _this.state) || other.state == _this.state)&&const DeepCollectionEquality().equals(other.scopes, _this.scopes)&&(identical(other.policyVersion, _this.policyVersion) || other.policyVersion == _this.policyVersion)&&(identical(other.decidedAt, _this.decidedAt) || other.decidedAt == _this.decidedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ConsentDecision;
  return Object.hash(runtimeType,_this.id,_this.type,_this.sourceId,_this.state,const DeepCollectionEquality().hash(_this.scopes),_this.policyVersion,_this.decidedAt);
}

@override
String toString() {
  final _this = this as ConsentDecision;
  return 'ConsentDecision(id: ${_this.id}, type: ${_this.type}, sourceId: ${_this.sourceId}, state: ${_this.state}, scopes: ${_this.scopes}, policyVersion: ${_this.policyVersion}, decidedAt: ${_this.decidedAt})';
}


}

/// @nodoc
abstract mixin class $ConsentDecisionCopyWith<$Res>  {
  factory $ConsentDecisionCopyWith(ConsentDecision value, $Res Function(ConsentDecision) _then) = _$ConsentDecisionCopyWithImpl;
@useResult
$Res call({
 String id, ConsentType type, String? sourceId, ConsentState state, List<String> scopes, String policyVersion, ZonedTimestamp decidedAt
});


$ZonedTimestampCopyWith<$Res> get decidedAt;

}
/// @nodoc
class _$ConsentDecisionCopyWithImpl<$Res>
    implements $ConsentDecisionCopyWith<$Res> {
  _$ConsentDecisionCopyWithImpl(this._self, this._then);

  final ConsentDecision _self;
  final $Res Function(ConsentDecision) _then;

/// Create a copy of ConsentDecision
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? sourceId = freezed,Object? state = null,Object? scopes = null,Object? policyVersion = null,Object? decidedAt = null,}) {
  return _then(ConsentDecision(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ConsentType,sourceId: freezed == sourceId ? _self.sourceId : sourceId // ignore: cast_nullable_to_non_nullable
as String?,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as ConsentState,scopes: null == scopes ? _self.scopes : scopes // ignore: cast_nullable_to_non_nullable
as List<String>,policyVersion: null == policyVersion ? _self.policyVersion : policyVersion // ignore: cast_nullable_to_non_nullable
as String,decidedAt: null == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as ZonedTimestamp,
  ));
}
/// Create a copy of ConsentDecision
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ZonedTimestampCopyWith<$Res> get decidedAt {
  
  return $ZonedTimestampCopyWith<$Res>(_self.decidedAt, (value) {
    return _then(_self.copyWith(decidedAt: value));
  });
}
}


/// Adds pattern-matching-related methods to [ConsentDecision].
extension ConsentDecisionPatterns on ConsentDecision {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConsentDecision value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConsentDecision() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConsentDecision value)  $default,){
final _that = this;
switch (_that) {
case _ConsentDecision():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConsentDecision value)?  $default,){
final _that = this;
switch (_that) {
case _ConsentDecision() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  ConsentType type,  String? sourceId,  ConsentState state,  List<String> scopes,  String policyVersion,  ZonedTimestamp decidedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConsentDecision() when $default != null:
return $default(_that.id,_that.type,_that.sourceId,_that.state,_that.scopes,_that.policyVersion,_that.decidedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  ConsentType type,  String? sourceId,  ConsentState state,  List<String> scopes,  String policyVersion,  ZonedTimestamp decidedAt)  $default,) {final _that = this;
switch (_that) {
case _ConsentDecision():
return $default(_that.id,_that.type,_that.sourceId,_that.state,_that.scopes,_that.policyVersion,_that.decidedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  ConsentType type,  String? sourceId,  ConsentState state,  List<String> scopes,  String policyVersion,  ZonedTimestamp decidedAt)?  $default,) {final _that = this;
switch (_that) {
case _ConsentDecision() when $default != null:
return $default(_that.id,_that.type,_that.sourceId,_that.state,_that.scopes,_that.policyVersion,_that.decidedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ConsentDecision extends ConsentDecision {
  const _ConsentDecision({required this.id, required this.type, this.sourceId, required this.state,  List<String> scopes = const <String>[], required this.policyVersion, required this.decidedAt}): _scopes = scopes,super._();
  factory _ConsentDecision.fromJson(Map<String, dynamic> json) => _$ConsentDecisionFromJson(json);

@override final  String id;
@override final  ConsentType type;
/// The external source for health data, otherwise `null`.
@override final  String? sourceId;
@override final  ConsentState state;
/// Granted scopes, sorted. Empty for revocations and types without
/// scopes.
 final  List<String> _scopes;
/// Granted scopes, sorted. Empty for revocations and types without
/// scopes.
@override@JsonKey() List<String> get scopes {
  if (_scopes is EqualUnmodifiableListView) return _scopes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_scopes);
}

@override final  String policyVersion;
@override final  ZonedTimestamp decidedAt;

/// Create a copy of ConsentDecision
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConsentDecisionCopyWith<_ConsentDecision> get copyWith => __$ConsentDecisionCopyWithImpl<_ConsentDecision>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConsentDecisionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConsentDecision&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.sourceId, sourceId) || other.sourceId == sourceId)&&(identical(other.state, state) || other.state == state)&&const DeepCollectionEquality().equals(other.scopes, _scopes)&&(identical(other.policyVersion, policyVersion) || other.policyVersion == policyVersion)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,type,sourceId,state,const DeepCollectionEquality().hash(_scopes),policyVersion,decidedAt);
}

@override
String toString() {
    return 'ConsentDecision(id: $id, type: $type, sourceId: $sourceId, state: $state, scopes: $scopes, policyVersion: $policyVersion, decidedAt: $decidedAt)';
}


}

/// @nodoc
abstract mixin class _$ConsentDecisionCopyWith<$Res> implements $ConsentDecisionCopyWith<$Res> {
  factory _$ConsentDecisionCopyWith(_ConsentDecision value, $Res Function(_ConsentDecision) _then) = __$ConsentDecisionCopyWithImpl;
@override @useResult
$Res call({
 String id, ConsentType type, String? sourceId, ConsentState state, List<String> scopes, String policyVersion, ZonedTimestamp decidedAt
});


@override $ZonedTimestampCopyWith<$Res> get decidedAt;

}
/// @nodoc
class __$ConsentDecisionCopyWithImpl<$Res>
    implements _$ConsentDecisionCopyWith<$Res> {
  __$ConsentDecisionCopyWithImpl(this._self, this._then);

  final _ConsentDecision _self;
  final $Res Function(_ConsentDecision) _then;

/// Create a copy of ConsentDecision
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? sourceId = freezed,Object? state = null,Object? scopes = null,Object? policyVersion = null,Object? decidedAt = null,}) {
  return _then(_ConsentDecision(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ConsentType,sourceId: freezed == sourceId ? _self.sourceId : sourceId // ignore: cast_nullable_to_non_nullable
as String?,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as ConsentState,scopes: null == scopes ? _self._scopes : scopes // ignore: cast_nullable_to_non_nullable
as List<String>,policyVersion: null == policyVersion ? _self.policyVersion : policyVersion // ignore: cast_nullable_to_non_nullable
as String,decidedAt: null == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as ZonedTimestamp,
  ));
}

/// Create a copy of ConsentDecision
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ZonedTimestampCopyWith<$Res> get decidedAt {
  
  return $ZonedTimestampCopyWith<$Res>(_self.decidedAt, (value) {
    return _then(_self.copyWith(decidedAt: value));
  });
}
}

// dart format on
