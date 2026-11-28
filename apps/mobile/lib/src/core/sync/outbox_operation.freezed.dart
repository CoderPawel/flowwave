// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'outbox_operation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OutboxOperation {

/// Equal to the ID of the entity it uploads, so enqueuing twice is a
/// no-op and the API can replay it safely (rule 7).
 String get id; String get kind; String get payload; DateTime get createdAt; int get attempts; DateTime get nextAttemptAt; OutboxStatus get status; String? get lastError;
/// Create a copy of OutboxOperation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutboxOperationCopyWith<OutboxOperation> get copyWith => _$OutboxOperationCopyWithImpl<OutboxOperation>(this as OutboxOperation, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OutboxOperation;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OutboxOperation&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.payload, _this.payload) || other.payload == _this.payload)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.attempts, _this.attempts) || other.attempts == _this.attempts)&&(identical(other.nextAttemptAt, _this.nextAttemptAt) || other.nextAttemptAt == _this.nextAttemptAt)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.lastError, _this.lastError) || other.lastError == _this.lastError));
}


@override
int get hashCode {
  final _this = this as OutboxOperation;
  return Object.hash(runtimeType,_this.id,_this.kind,_this.payload,_this.createdAt,_this.attempts,_this.nextAttemptAt,_this.status,_this.lastError);
}

@override
String toString() {
  final _this = this as OutboxOperation;
  return 'OutboxOperation(id: ${_this.id}, kind: ${_this.kind}, payload: ${_this.payload}, createdAt: ${_this.createdAt}, attempts: ${_this.attempts}, nextAttemptAt: ${_this.nextAttemptAt}, status: ${_this.status}, lastError: ${_this.lastError})';
}


}

/// @nodoc
abstract mixin class $OutboxOperationCopyWith<$Res>  {
  factory $OutboxOperationCopyWith(OutboxOperation value, $Res Function(OutboxOperation) _then) = _$OutboxOperationCopyWithImpl;
@useResult
$Res call({
 String id, String kind, String payload, DateTime createdAt, int attempts, DateTime nextAttemptAt, OutboxStatus status, String? lastError
});




}
/// @nodoc
class _$OutboxOperationCopyWithImpl<$Res>
    implements $OutboxOperationCopyWith<$Res> {
  _$OutboxOperationCopyWithImpl(this._self, this._then);

  final OutboxOperation _self;
  final $Res Function(OutboxOperation) _then;

/// Create a copy of OutboxOperation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? payload = null,Object? createdAt = null,Object? attempts = null,Object? nextAttemptAt = null,Object? status = null,Object? lastError = freezed,}) {
  return _then(OutboxOperation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int,nextAttemptAt: null == nextAttemptAt ? _self.nextAttemptAt : nextAttemptAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OutboxStatus,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [OutboxOperation].
extension OutboxOperationPatterns on OutboxOperation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OutboxOperation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OutboxOperation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OutboxOperation value)  $default,){
final _that = this;
switch (_that) {
case _OutboxOperation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OutboxOperation value)?  $default,){
final _that = this;
switch (_that) {
case _OutboxOperation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String kind,  String payload,  DateTime createdAt,  int attempts,  DateTime nextAttemptAt,  OutboxStatus status,  String? lastError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OutboxOperation() when $default != null:
return $default(_that.id,_that.kind,_that.payload,_that.createdAt,_that.attempts,_that.nextAttemptAt,_that.status,_that.lastError);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String kind,  String payload,  DateTime createdAt,  int attempts,  DateTime nextAttemptAt,  OutboxStatus status,  String? lastError)  $default,) {final _that = this;
switch (_that) {
case _OutboxOperation():
return $default(_that.id,_that.kind,_that.payload,_that.createdAt,_that.attempts,_that.nextAttemptAt,_that.status,_that.lastError);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String kind,  String payload,  DateTime createdAt,  int attempts,  DateTime nextAttemptAt,  OutboxStatus status,  String? lastError)?  $default,) {final _that = this;
switch (_that) {
case _OutboxOperation() when $default != null:
return $default(_that.id,_that.kind,_that.payload,_that.createdAt,_that.attempts,_that.nextAttemptAt,_that.status,_that.lastError);case _:
  return null;

}
}

}

/// @nodoc


class _OutboxOperation implements OutboxOperation {
  const _OutboxOperation({required this.id, required this.kind, required this.payload, required this.createdAt, this.attempts = 0, required this.nextAttemptAt, this.status = OutboxStatus.pending, this.lastError});
  

/// Equal to the ID of the entity it uploads, so enqueuing twice is a
/// no-op and the API can replay it safely (rule 7).
@override final  String id;
@override final  String kind;
@override final  String payload;
@override final  DateTime createdAt;
@override@JsonKey() final  int attempts;
@override final  DateTime nextAttemptAt;
@override@JsonKey() final  OutboxStatus status;
@override final  String? lastError;

/// Create a copy of OutboxOperation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OutboxOperationCopyWith<_OutboxOperation> get copyWith => __$OutboxOperationCopyWithImpl<_OutboxOperation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OutboxOperation&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.payload, payload) || other.payload == payload)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.nextAttemptAt, nextAttemptAt) || other.nextAttemptAt == nextAttemptAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.lastError, lastError) || other.lastError == lastError));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,kind,payload,createdAt,attempts,nextAttemptAt,status,lastError);
}

@override
String toString() {
    return 'OutboxOperation(id: $id, kind: $kind, payload: $payload, createdAt: $createdAt, attempts: $attempts, nextAttemptAt: $nextAttemptAt, status: $status, lastError: $lastError)';
}


}

/// @nodoc
abstract mixin class _$OutboxOperationCopyWith<$Res> implements $OutboxOperationCopyWith<$Res> {
  factory _$OutboxOperationCopyWith(_OutboxOperation value, $Res Function(_OutboxOperation) _then) = __$OutboxOperationCopyWithImpl;
@override @useResult
$Res call({
 String id, String kind, String payload, DateTime createdAt, int attempts, DateTime nextAttemptAt, OutboxStatus status, String? lastError
});




}
/// @nodoc
class __$OutboxOperationCopyWithImpl<$Res>
    implements _$OutboxOperationCopyWith<$Res> {
  __$OutboxOperationCopyWithImpl(this._self, this._then);

  final _OutboxOperation _self;
  final $Res Function(_OutboxOperation) _then;

/// Create a copy of OutboxOperation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? payload = null,Object? createdAt = null,Object? attempts = null,Object? nextAttemptAt = null,Object? status = null,Object? lastError = freezed,}) {
  return _then(_OutboxOperation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int,nextAttemptAt: null == nextAttemptAt ? _self.nextAttemptAt : nextAttemptAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OutboxStatus,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$OutboxSummary {

 int get pending; int get rejected;
/// Create a copy of OutboxSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutboxSummaryCopyWith<OutboxSummary> get copyWith => _$OutboxSummaryCopyWithImpl<OutboxSummary>(this as OutboxSummary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OutboxSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OutboxSummary&&(identical(other.pending, _this.pending) || other.pending == _this.pending)&&(identical(other.rejected, _this.rejected) || other.rejected == _this.rejected));
}


@override
int get hashCode {
  final _this = this as OutboxSummary;
  return Object.hash(runtimeType,_this.pending,_this.rejected);
}

@override
String toString() {
  final _this = this as OutboxSummary;
  return 'OutboxSummary(pending: ${_this.pending}, rejected: ${_this.rejected})';
}


}

/// @nodoc
abstract mixin class $OutboxSummaryCopyWith<$Res>  {
  factory $OutboxSummaryCopyWith(OutboxSummary value, $Res Function(OutboxSummary) _then) = _$OutboxSummaryCopyWithImpl;
@useResult
$Res call({
 int pending, int rejected
});




}
/// @nodoc
class _$OutboxSummaryCopyWithImpl<$Res>
    implements $OutboxSummaryCopyWith<$Res> {
  _$OutboxSummaryCopyWithImpl(this._self, this._then);

  final OutboxSummary _self;
  final $Res Function(OutboxSummary) _then;

/// Create a copy of OutboxSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pending = null,Object? rejected = null,}) {
  return _then(OutboxSummary(
pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as int,rejected: null == rejected ? _self.rejected : rejected // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [OutboxSummary].
extension OutboxSummaryPatterns on OutboxSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OutboxSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OutboxSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OutboxSummary value)  $default,){
final _that = this;
switch (_that) {
case _OutboxSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OutboxSummary value)?  $default,){
final _that = this;
switch (_that) {
case _OutboxSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int pending,  int rejected)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OutboxSummary() when $default != null:
return $default(_that.pending,_that.rejected);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int pending,  int rejected)  $default,) {final _that = this;
switch (_that) {
case _OutboxSummary():
return $default(_that.pending,_that.rejected);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int pending,  int rejected)?  $default,) {final _that = this;
switch (_that) {
case _OutboxSummary() when $default != null:
return $default(_that.pending,_that.rejected);case _:
  return null;

}
}

}

/// @nodoc


class _OutboxSummary implements OutboxSummary {
  const _OutboxSummary({this.pending = 0, this.rejected = 0});
  

@override@JsonKey() final  int pending;
@override@JsonKey() final  int rejected;

/// Create a copy of OutboxSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OutboxSummaryCopyWith<_OutboxSummary> get copyWith => __$OutboxSummaryCopyWithImpl<_OutboxSummary>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OutboxSummary&&(identical(other.pending, pending) || other.pending == pending)&&(identical(other.rejected, rejected) || other.rejected == rejected));
}


@override
int get hashCode {
    return Object.hash(runtimeType,pending,rejected);
}

@override
String toString() {
    return 'OutboxSummary(pending: $pending, rejected: $rejected)';
}


}

/// @nodoc
abstract mixin class _$OutboxSummaryCopyWith<$Res> implements $OutboxSummaryCopyWith<$Res> {
  factory _$OutboxSummaryCopyWith(_OutboxSummary value, $Res Function(_OutboxSummary) _then) = __$OutboxSummaryCopyWithImpl;
@override @useResult
$Res call({
 int pending, int rejected
});




}
/// @nodoc
class __$OutboxSummaryCopyWithImpl<$Res>
    implements _$OutboxSummaryCopyWith<$Res> {
  __$OutboxSummaryCopyWithImpl(this._self, this._then);

  final _OutboxSummary _self;
  final $Res Function(_OutboxSummary) _then;

/// Create a copy of OutboxSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pending = null,Object? rejected = null,}) {
  return _then(_OutboxSummary(
pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as int,rejected: null == rejected ? _self.rejected : rejected // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
