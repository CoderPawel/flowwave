import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_failure.freezed.dart';

/// Every failure the app can show or react to. Network, API and storage
/// errors are mapped to one of these in `mapError` (decision 0015), so
/// screens and services never handle Dio or SQLite exceptions directly.
@freezed
sealed class AppFailure with _$AppFailure implements Exception {
  const AppFailure._();

  /// The API could not be reached (offline, DNS, timeout, TLS).
  const factory AppFailure.network() = NetworkFailure;

  /// This build has no API configured; the app runs offline only.
  const factory AppFailure.notConfigured() = NotConfiguredFailure;

  /// No usable session on this phone: the user must sign in. [reason] tells
  /// why the server ended it, for example `refresh_token_reused`.
  const factory AppFailure.notSignedIn({String? reason}) = NotSignedInFailure;

  /// `401`: wrong credentials or an ended session. [reason] is the API's
  /// stable reason, for example `invalid_credentials`.
  const factory AppFailure.unauthorized({String? reason}) = UnauthorizedFailure;

  /// `403` that is not about consent, for example a wrong password when
  /// confirming account deletion (`reauthentication_failed`).
  const factory AppFailure.forbidden({String? reason}) = ForbiddenFailure;

  /// `403 consent_required`: the user has not consented to [subject].
  const factory AppFailure.consentRequired({String? subject, String? scope}) =
      ConsentRequiredFailure;

  /// `400` or `422`: the request was invalid. [field] names the input when
  /// the API reports one.
  const factory AppFailure.validation({String? field}) = ValidationFailure;

  /// `409`: for example an email that is already registered, or an operation
  /// ID reused for different content.
  const factory AppFailure.conflict({String? field}) = ConflictFailure;

  const factory AppFailure.notFound() = NotFoundFailure;

  /// `429`: try again after [retryAfter] when the API says how long.
  const factory AppFailure.rateLimited({Duration? retryAfter}) =
      RateLimitedFailure;

  /// `5xx` or a response the app cannot read.
  const factory AppFailure.server({int? statusCode}) = ServerFailure;

  /// The local database failed.
  const factory AppFailure.storage() = StorageFailure;

  const factory AppFailure.unknown() = UnknownFailure;

  /// Worth retrying later without any user action.
  bool get isTransient => switch (this) {
    NetworkFailure() || RateLimitedFailure() || ServerFailure() => true,
    _ => false,
  };
}
