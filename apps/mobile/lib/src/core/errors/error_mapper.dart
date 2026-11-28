import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
// Errors from the background isolate arrive wrapped in DriftRemoteException.
// ignore: experimental_member_use
import 'package:drift/remote.dart';
import 'package:sqlite3/sqlite3.dart';

import 'app_failure.dart';

/// Maps any error to an [AppFailure]. The single place that knows how Dio,
/// the API error body and the database report failures (decision 0015).
AppFailure mapError(Object error) {
  return switch (error) {
    AppFailure() => error,
    DioException() => _mapDio(error),
    SqliteException() ||
    DriftWrappedException() ||
    DriftRemoteException() ||
    InvalidDataException() => const AppFailure.storage(),
    SocketException() ||
    TimeoutException() ||
    HttpException() => const AppFailure.network(),
    _ => const AppFailure.unknown(),
  };
}

AppFailure _mapDio(DioException error) {
  final cause = error.error;
  if (cause is AppFailure) return cause;
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
    case DioExceptionType.connectionError:
    case DioExceptionType.badCertificate:
      return const AppFailure.network();
    case DioExceptionType.cancel:
      return const AppFailure.unknown();
    case DioExceptionType.unknown:
      return cause is SocketException ||
              cause is HttpException ||
              cause is TimeoutException
          ? const AppFailure.network()
          : const AppFailure.unknown();
    case DioExceptionType.badResponse:
      final response = error.response;
      if (response == null) return const AppFailure.server();
      return mapErrorResponse(
        response.statusCode ?? 0,
        response.data,
        retryAfterHeader: response.headers.value('retry-after'),
      );
  }
}

/// A short, stable code for logs and the write queue. Never contains server
/// messages or user data.
String failureCode(AppFailure failure) => switch (failure) {
  NetworkFailure() => 'network',
  NotConfiguredFailure() => 'not_configured',
  NotSignedInFailure() => 'not_signed_in',
  UnauthorizedFailure() => 'unauthorized',
  ForbiddenFailure(:final reason) => reason ?? 'forbidden',
  ConsentRequiredFailure() => 'consent_required',
  ValidationFailure(:final field) =>
    field == null ? 'validation_failed' : 'validation_failed:$field',
  ConflictFailure(:final field) =>
    field == null ? 'conflict' : 'conflict:$field',
  NotFoundFailure() => 'not_found',
  RateLimitedFailure() => 'rate_limited',
  ServerFailure(:final statusCode) =>
    statusCode == null ? 'server_error' : 'server_error:$statusCode',
  StorageFailure() => 'storage',
  UnknownFailure() => 'unknown',
};

/// Maps an API error response (`{statusCode, error, message, reason?,
/// field?, subject?, scope?}`). The human-readable `message` is ignored:
/// screens show localized text instead.
AppFailure mapErrorResponse(
  int statusCode,
  Object? body, {
  String? retryAfterHeader,
}) {
  final json = body is Map ? body : const <Object?, Object?>{};
  String? text(String key) {
    final value = json[key];
    return value is String && value.isNotEmpty ? value : null;
  }

  final code = text('error');
  if (statusCode == 401) return AppFailure.unauthorized(reason: text('reason'));
  if (statusCode == 403) {
    return code == 'consent_required'
        ? AppFailure.consentRequired(
            subject: text('subject'),
            scope: text('scope'),
          )
        : AppFailure.forbidden(reason: text('reason'));
  }
  if (statusCode == 400 || statusCode == 422) {
    return AppFailure.validation(field: text('field'));
  }
  if (statusCode == 404) return const AppFailure.notFound();
  if (statusCode == 409) return AppFailure.conflict(field: text('field'));
  if (statusCode == 429) {
    final seconds = int.tryParse(retryAfterHeader?.trim() ?? '');
    return AppFailure.rateLimited(
      retryAfter: seconds == null || seconds < 0
          ? null
          : Duration(seconds: seconds),
    );
  }
  return AppFailure.server(statusCode: statusCode);
}
