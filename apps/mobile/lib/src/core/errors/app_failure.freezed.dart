// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppFailure {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AppFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AppFailure()';
}


}

/// @nodoc
class $AppFailureCopyWith<$Res>  {
$AppFailureCopyWith(AppFailure _, $Res Function(AppFailure) __);
}


/// Adds pattern-matching-related methods to [AppFailure].
extension AppFailurePatterns on AppFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NetworkFailure value)?  network,TResult Function( NotConfiguredFailure value)?  notConfigured,TResult Function( NotSignedInFailure value)?  notSignedIn,TResult Function( UnauthorizedFailure value)?  unauthorized,TResult Function( ForbiddenFailure value)?  forbidden,TResult Function( ConsentRequiredFailure value)?  consentRequired,TResult Function( ValidationFailure value)?  validation,TResult Function( ConflictFailure value)?  conflict,TResult Function( NotFoundFailure value)?  notFound,TResult Function( RateLimitedFailure value)?  rateLimited,TResult Function( ServerFailure value)?  server,TResult Function( StorageFailure value)?  storage,TResult Function( UnknownFailure value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NetworkFailure() when network != null:
return network(_that);case NotConfiguredFailure() when notConfigured != null:
return notConfigured(_that);case NotSignedInFailure() when notSignedIn != null:
return notSignedIn(_that);case UnauthorizedFailure() when unauthorized != null:
return unauthorized(_that);case ForbiddenFailure() when forbidden != null:
return forbidden(_that);case ConsentRequiredFailure() when consentRequired != null:
return consentRequired(_that);case ValidationFailure() when validation != null:
return validation(_that);case ConflictFailure() when conflict != null:
return conflict(_that);case NotFoundFailure() when notFound != null:
return notFound(_that);case RateLimitedFailure() when rateLimited != null:
return rateLimited(_that);case ServerFailure() when server != null:
return server(_that);case StorageFailure() when storage != null:
return storage(_that);case UnknownFailure() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NetworkFailure value)  network,required TResult Function( NotConfiguredFailure value)  notConfigured,required TResult Function( NotSignedInFailure value)  notSignedIn,required TResult Function( UnauthorizedFailure value)  unauthorized,required TResult Function( ForbiddenFailure value)  forbidden,required TResult Function( ConsentRequiredFailure value)  consentRequired,required TResult Function( ValidationFailure value)  validation,required TResult Function( ConflictFailure value)  conflict,required TResult Function( NotFoundFailure value)  notFound,required TResult Function( RateLimitedFailure value)  rateLimited,required TResult Function( ServerFailure value)  server,required TResult Function( StorageFailure value)  storage,required TResult Function( UnknownFailure value)  unknown,}){
final _that = this;
switch (_that) {
case NetworkFailure():
return network(_that);case NotConfiguredFailure():
return notConfigured(_that);case NotSignedInFailure():
return notSignedIn(_that);case UnauthorizedFailure():
return unauthorized(_that);case ForbiddenFailure():
return forbidden(_that);case ConsentRequiredFailure():
return consentRequired(_that);case ValidationFailure():
return validation(_that);case ConflictFailure():
return conflict(_that);case NotFoundFailure():
return notFound(_that);case RateLimitedFailure():
return rateLimited(_that);case ServerFailure():
return server(_that);case StorageFailure():
return storage(_that);case UnknownFailure():
return unknown(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NetworkFailure value)?  network,TResult? Function( NotConfiguredFailure value)?  notConfigured,TResult? Function( NotSignedInFailure value)?  notSignedIn,TResult? Function( UnauthorizedFailure value)?  unauthorized,TResult? Function( ForbiddenFailure value)?  forbidden,TResult? Function( ConsentRequiredFailure value)?  consentRequired,TResult? Function( ValidationFailure value)?  validation,TResult? Function( ConflictFailure value)?  conflict,TResult? Function( NotFoundFailure value)?  notFound,TResult? Function( RateLimitedFailure value)?  rateLimited,TResult? Function( ServerFailure value)?  server,TResult? Function( StorageFailure value)?  storage,TResult? Function( UnknownFailure value)?  unknown,}){
final _that = this;
switch (_that) {
case NetworkFailure() when network != null:
return network(_that);case NotConfiguredFailure() when notConfigured != null:
return notConfigured(_that);case NotSignedInFailure() when notSignedIn != null:
return notSignedIn(_that);case UnauthorizedFailure() when unauthorized != null:
return unauthorized(_that);case ForbiddenFailure() when forbidden != null:
return forbidden(_that);case ConsentRequiredFailure() when consentRequired != null:
return consentRequired(_that);case ValidationFailure() when validation != null:
return validation(_that);case ConflictFailure() when conflict != null:
return conflict(_that);case NotFoundFailure() when notFound != null:
return notFound(_that);case RateLimitedFailure() when rateLimited != null:
return rateLimited(_that);case ServerFailure() when server != null:
return server(_that);case StorageFailure() when storage != null:
return storage(_that);case UnknownFailure() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  network,TResult Function()?  notConfigured,TResult Function( String? reason)?  notSignedIn,TResult Function( String? reason)?  unauthorized,TResult Function( String? reason)?  forbidden,TResult Function( String? subject,  String? scope)?  consentRequired,TResult Function( String? field)?  validation,TResult Function( String? field)?  conflict,TResult Function()?  notFound,TResult Function( Duration? retryAfter)?  rateLimited,TResult Function( int? statusCode)?  server,TResult Function()?  storage,TResult Function()?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NetworkFailure() when network != null:
return network();case NotConfiguredFailure() when notConfigured != null:
return notConfigured();case NotSignedInFailure() when notSignedIn != null:
return notSignedIn(_that.reason);case UnauthorizedFailure() when unauthorized != null:
return unauthorized(_that.reason);case ForbiddenFailure() when forbidden != null:
return forbidden(_that.reason);case ConsentRequiredFailure() when consentRequired != null:
return consentRequired(_that.subject,_that.scope);case ValidationFailure() when validation != null:
return validation(_that.field);case ConflictFailure() when conflict != null:
return conflict(_that.field);case NotFoundFailure() when notFound != null:
return notFound();case RateLimitedFailure() when rateLimited != null:
return rateLimited(_that.retryAfter);case ServerFailure() when server != null:
return server(_that.statusCode);case StorageFailure() when storage != null:
return storage();case UnknownFailure() when unknown != null:
return unknown();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  network,required TResult Function()  notConfigured,required TResult Function( String? reason)  notSignedIn,required TResult Function( String? reason)  unauthorized,required TResult Function( String? reason)  forbidden,required TResult Function( String? subject,  String? scope)  consentRequired,required TResult Function( String? field)  validation,required TResult Function( String? field)  conflict,required TResult Function()  notFound,required TResult Function( Duration? retryAfter)  rateLimited,required TResult Function( int? statusCode)  server,required TResult Function()  storage,required TResult Function()  unknown,}) {final _that = this;
switch (_that) {
case NetworkFailure():
return network();case NotConfiguredFailure():
return notConfigured();case NotSignedInFailure():
return notSignedIn(_that.reason);case UnauthorizedFailure():
return unauthorized(_that.reason);case ForbiddenFailure():
return forbidden(_that.reason);case ConsentRequiredFailure():
return consentRequired(_that.subject,_that.scope);case ValidationFailure():
return validation(_that.field);case ConflictFailure():
return conflict(_that.field);case NotFoundFailure():
return notFound();case RateLimitedFailure():
return rateLimited(_that.retryAfter);case ServerFailure():
return server(_that.statusCode);case StorageFailure():
return storage();case UnknownFailure():
return unknown();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  network,TResult? Function()?  notConfigured,TResult? Function( String? reason)?  notSignedIn,TResult? Function( String? reason)?  unauthorized,TResult? Function( String? reason)?  forbidden,TResult? Function( String? subject,  String? scope)?  consentRequired,TResult? Function( String? field)?  validation,TResult? Function( String? field)?  conflict,TResult? Function()?  notFound,TResult? Function( Duration? retryAfter)?  rateLimited,TResult? Function( int? statusCode)?  server,TResult? Function()?  storage,TResult? Function()?  unknown,}) {final _that = this;
switch (_that) {
case NetworkFailure() when network != null:
return network();case NotConfiguredFailure() when notConfigured != null:
return notConfigured();case NotSignedInFailure() when notSignedIn != null:
return notSignedIn(_that.reason);case UnauthorizedFailure() when unauthorized != null:
return unauthorized(_that.reason);case ForbiddenFailure() when forbidden != null:
return forbidden(_that.reason);case ConsentRequiredFailure() when consentRequired != null:
return consentRequired(_that.subject,_that.scope);case ValidationFailure() when validation != null:
return validation(_that.field);case ConflictFailure() when conflict != null:
return conflict(_that.field);case NotFoundFailure() when notFound != null:
return notFound();case RateLimitedFailure() when rateLimited != null:
return rateLimited(_that.retryAfter);case ServerFailure() when server != null:
return server(_that.statusCode);case StorageFailure() when storage != null:
return storage();case UnknownFailure() when unknown != null:
return unknown();case _:
  return null;

}
}

}

/// @nodoc


class NetworkFailure extends AppFailure {
  const NetworkFailure(): super._();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AppFailure.network()';
}


}




/// @nodoc


class NotConfiguredFailure extends AppFailure {
  const NotConfiguredFailure(): super._();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is NotConfiguredFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AppFailure.notConfigured()';
}


}




/// @nodoc


class NotSignedInFailure extends AppFailure {
  const NotSignedInFailure({this.reason}): super._();
  

 final  String? reason;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotSignedInFailureCopyWith<NotSignedInFailure> get copyWith => _$NotSignedInFailureCopyWithImpl<NotSignedInFailure>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is NotSignedInFailure&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode {
    return Object.hash(runtimeType,reason);
}

@override
String toString() {
    return 'AppFailure.notSignedIn(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $NotSignedInFailureCopyWith<$Res> implements $AppFailureCopyWith<$Res> {
  factory $NotSignedInFailureCopyWith(NotSignedInFailure value, $Res Function(NotSignedInFailure) _then) = _$NotSignedInFailureCopyWithImpl;
@useResult
$Res call({
 String? reason
});




}
/// @nodoc
class _$NotSignedInFailureCopyWithImpl<$Res>
    implements $NotSignedInFailureCopyWith<$Res> {
  _$NotSignedInFailureCopyWithImpl(this._self, this._then);

  final NotSignedInFailure _self;
  final $Res Function(NotSignedInFailure) _then;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = freezed,}) {
  return _then(NotSignedInFailure(
reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure({this.reason}): super._();
  

 final  String? reason;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnauthorizedFailureCopyWith<UnauthorizedFailure> get copyWith => _$UnauthorizedFailureCopyWithImpl<UnauthorizedFailure>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is UnauthorizedFailure&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode {
    return Object.hash(runtimeType,reason);
}

@override
String toString() {
    return 'AppFailure.unauthorized(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $UnauthorizedFailureCopyWith<$Res> implements $AppFailureCopyWith<$Res> {
  factory $UnauthorizedFailureCopyWith(UnauthorizedFailure value, $Res Function(UnauthorizedFailure) _then) = _$UnauthorizedFailureCopyWithImpl;
@useResult
$Res call({
 String? reason
});




}
/// @nodoc
class _$UnauthorizedFailureCopyWithImpl<$Res>
    implements $UnauthorizedFailureCopyWith<$Res> {
  _$UnauthorizedFailureCopyWithImpl(this._self, this._then);

  final UnauthorizedFailure _self;
  final $Res Function(UnauthorizedFailure) _then;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = freezed,}) {
  return _then(UnauthorizedFailure(
reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class ForbiddenFailure extends AppFailure {
  const ForbiddenFailure({this.reason}): super._();
  

 final  String? reason;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ForbiddenFailureCopyWith<ForbiddenFailure> get copyWith => _$ForbiddenFailureCopyWithImpl<ForbiddenFailure>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ForbiddenFailure&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode {
    return Object.hash(runtimeType,reason);
}

@override
String toString() {
    return 'AppFailure.forbidden(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $ForbiddenFailureCopyWith<$Res> implements $AppFailureCopyWith<$Res> {
  factory $ForbiddenFailureCopyWith(ForbiddenFailure value, $Res Function(ForbiddenFailure) _then) = _$ForbiddenFailureCopyWithImpl;
@useResult
$Res call({
 String? reason
});




}
/// @nodoc
class _$ForbiddenFailureCopyWithImpl<$Res>
    implements $ForbiddenFailureCopyWith<$Res> {
  _$ForbiddenFailureCopyWithImpl(this._self, this._then);

  final ForbiddenFailure _self;
  final $Res Function(ForbiddenFailure) _then;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = freezed,}) {
  return _then(ForbiddenFailure(
reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class ConsentRequiredFailure extends AppFailure {
  const ConsentRequiredFailure({this.subject, this.scope}): super._();
  

 final  String? subject;
 final  String? scope;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConsentRequiredFailureCopyWith<ConsentRequiredFailure> get copyWith => _$ConsentRequiredFailureCopyWithImpl<ConsentRequiredFailure>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ConsentRequiredFailure&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.scope, scope) || other.scope == scope));
}


@override
int get hashCode {
    return Object.hash(runtimeType,subject,scope);
}

@override
String toString() {
    return 'AppFailure.consentRequired(subject: $subject, scope: $scope)';
}


}

/// @nodoc
abstract mixin class $ConsentRequiredFailureCopyWith<$Res> implements $AppFailureCopyWith<$Res> {
  factory $ConsentRequiredFailureCopyWith(ConsentRequiredFailure value, $Res Function(ConsentRequiredFailure) _then) = _$ConsentRequiredFailureCopyWithImpl;
@useResult
$Res call({
 String? subject, String? scope
});




}
/// @nodoc
class _$ConsentRequiredFailureCopyWithImpl<$Res>
    implements $ConsentRequiredFailureCopyWith<$Res> {
  _$ConsentRequiredFailureCopyWithImpl(this._self, this._then);

  final ConsentRequiredFailure _self;
  final $Res Function(ConsentRequiredFailure) _then;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? subject = freezed,Object? scope = freezed,}) {
  return _then(ConsentRequiredFailure(
subject: freezed == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String?,scope: freezed == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class ValidationFailure extends AppFailure {
  const ValidationFailure({this.field}): super._();
  

 final  String? field;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ValidationFailureCopyWith<ValidationFailure> get copyWith => _$ValidationFailureCopyWithImpl<ValidationFailure>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ValidationFailure&&(identical(other.field, field) || other.field == field));
}


@override
int get hashCode {
    return Object.hash(runtimeType,field);
}

@override
String toString() {
    return 'AppFailure.validation(field: $field)';
}


}

/// @nodoc
abstract mixin class $ValidationFailureCopyWith<$Res> implements $AppFailureCopyWith<$Res> {
  factory $ValidationFailureCopyWith(ValidationFailure value, $Res Function(ValidationFailure) _then) = _$ValidationFailureCopyWithImpl;
@useResult
$Res call({
 String? field
});




}
/// @nodoc
class _$ValidationFailureCopyWithImpl<$Res>
    implements $ValidationFailureCopyWith<$Res> {
  _$ValidationFailureCopyWithImpl(this._self, this._then);

  final ValidationFailure _self;
  final $Res Function(ValidationFailure) _then;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field = freezed,}) {
  return _then(ValidationFailure(
field: freezed == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class ConflictFailure extends AppFailure {
  const ConflictFailure({this.field}): super._();
  

 final  String? field;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConflictFailureCopyWith<ConflictFailure> get copyWith => _$ConflictFailureCopyWithImpl<ConflictFailure>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ConflictFailure&&(identical(other.field, field) || other.field == field));
}


@override
int get hashCode {
    return Object.hash(runtimeType,field);
}

@override
String toString() {
    return 'AppFailure.conflict(field: $field)';
}


}

/// @nodoc
abstract mixin class $ConflictFailureCopyWith<$Res> implements $AppFailureCopyWith<$Res> {
  factory $ConflictFailureCopyWith(ConflictFailure value, $Res Function(ConflictFailure) _then) = _$ConflictFailureCopyWithImpl;
@useResult
$Res call({
 String? field
});




}
/// @nodoc
class _$ConflictFailureCopyWithImpl<$Res>
    implements $ConflictFailureCopyWith<$Res> {
  _$ConflictFailureCopyWithImpl(this._self, this._then);

  final ConflictFailure _self;
  final $Res Function(ConflictFailure) _then;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field = freezed,}) {
  return _then(ConflictFailure(
field: freezed == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class NotFoundFailure extends AppFailure {
  const NotFoundFailure(): super._();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is NotFoundFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AppFailure.notFound()';
}


}




/// @nodoc


class RateLimitedFailure extends AppFailure {
  const RateLimitedFailure({this.retryAfter}): super._();
  

 final  Duration? retryAfter;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RateLimitedFailureCopyWith<RateLimitedFailure> get copyWith => _$RateLimitedFailureCopyWithImpl<RateLimitedFailure>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RateLimitedFailure&&(identical(other.retryAfter, retryAfter) || other.retryAfter == retryAfter));
}


@override
int get hashCode {
    return Object.hash(runtimeType,retryAfter);
}

@override
String toString() {
    return 'AppFailure.rateLimited(retryAfter: $retryAfter)';
}


}

/// @nodoc
abstract mixin class $RateLimitedFailureCopyWith<$Res> implements $AppFailureCopyWith<$Res> {
  factory $RateLimitedFailureCopyWith(RateLimitedFailure value, $Res Function(RateLimitedFailure) _then) = _$RateLimitedFailureCopyWithImpl;
@useResult
$Res call({
 Duration? retryAfter
});




}
/// @nodoc
class _$RateLimitedFailureCopyWithImpl<$Res>
    implements $RateLimitedFailureCopyWith<$Res> {
  _$RateLimitedFailureCopyWithImpl(this._self, this._then);

  final RateLimitedFailure _self;
  final $Res Function(RateLimitedFailure) _then;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? retryAfter = freezed,}) {
  return _then(RateLimitedFailure(
retryAfter: freezed == retryAfter ? _self.retryAfter : retryAfter // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}


}

/// @nodoc


class ServerFailure extends AppFailure {
  const ServerFailure({this.statusCode}): super._();
  

 final  int? statusCode;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServerFailureCopyWith<ServerFailure> get copyWith => _$ServerFailureCopyWithImpl<ServerFailure>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerFailure&&(identical(other.statusCode, statusCode) || other.statusCode == statusCode));
}


@override
int get hashCode {
    return Object.hash(runtimeType,statusCode);
}

@override
String toString() {
    return 'AppFailure.server(statusCode: $statusCode)';
}


}

/// @nodoc
abstract mixin class $ServerFailureCopyWith<$Res> implements $AppFailureCopyWith<$Res> {
  factory $ServerFailureCopyWith(ServerFailure value, $Res Function(ServerFailure) _then) = _$ServerFailureCopyWithImpl;
@useResult
$Res call({
 int? statusCode
});




}
/// @nodoc
class _$ServerFailureCopyWithImpl<$Res>
    implements $ServerFailureCopyWith<$Res> {
  _$ServerFailureCopyWithImpl(this._self, this._then);

  final ServerFailure _self;
  final $Res Function(ServerFailure) _then;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? statusCode = freezed,}) {
  return _then(ServerFailure(
statusCode: freezed == statusCode ? _self.statusCode : statusCode // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc


class StorageFailure extends AppFailure {
  const StorageFailure(): super._();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is StorageFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AppFailure.storage()';
}


}




/// @nodoc


class UnknownFailure extends AppFailure {
  const UnknownFailure(): super._();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is UnknownFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AppFailure.unknown()';
}


}




// dart format on
