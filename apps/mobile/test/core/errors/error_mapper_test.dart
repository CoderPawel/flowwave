import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flowwave_mobile/src/core/errors/app_failure.dart';
import 'package:flowwave_mobile/src/core/errors/error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  final request = RequestOptions(path: '/v1/test');

  DioException response(int status, Object? body, {String? retryAfter}) =>
      DioException.badResponse(
        statusCode: status,
        requestOptions: request,
        response: Response<Object?>(
          requestOptions: request,
          statusCode: status,
          data: body,
          headers: Headers.fromMap({
            if (retryAfter != null) 'retry-after': [retryAfter],
          }),
        ),
      );

  group('API error bodies', () {
    test('401 keeps the reason', () {
      expect(
        mapError(
          response(401, {
            'error': 'authentication_failed',
            'reason': 'token_expired',
          }),
        ),
        const AppFailure.unauthorized(reason: 'token_expired'),
      );
    });

    test('403 separates consent from other refusals', () {
      expect(
        mapError(
          response(403, {
            'error': 'consent_required',
            'subject': 'health_connect',
            'scope': 'steps',
          }),
        ),
        const AppFailure.consentRequired(
          subject: 'health_connect',
          scope: 'steps',
        ),
      );
      expect(
        mapError(
          response(403, {
            'error': 'authentication_failed',
            'reason': 'reauthentication_failed',
          }),
        ),
        const AppFailure.forbidden(reason: 'reauthentication_failed'),
      );
    });

    test('400 and 422 are validation failures with the field', () {
      expect(
        mapError(
          response(400, {'error': 'validation_failed', 'field': 'decidedAt'}),
        ),
        const AppFailure.validation(field: 'decidedAt'),
      );
      expect(
        mapError(
          response(400, {
            'message': ['email must be an email'],
            'error': 'Bad Request',
          }),
        ),
        const AppFailure.validation(),
        reason: 'Nest validation errors carry no field',
      );
      expect(
        mapError(
          response(422, {'error': 'forbidden_data', 'field': 'windowTitle'}),
        ),
        const AppFailure.validation(field: 'windowTitle'),
      );
    });

    test('409, 404, 429 and 5xx', () {
      expect(
        mapError(response(409, {'field': 'email'})),
        const AppFailure.conflict(field: 'email'),
      );
      expect(mapError(response(404, null)), const AppFailure.notFound());
      expect(
        mapError(response(429, {'error': 'rate_limited'}, retryAfter: '120')),
        const AppFailure.rateLimited(retryAfter: Duration(minutes: 2)),
      );
      expect(
        mapError(response(429, null, retryAfter: 'soon')),
        const AppFailure.rateLimited(),
      );
      expect(
        mapError(response(503, '<html>')),
        const AppFailure.server(statusCode: 503),
      );
    });
  });

  group('transport', () {
    test('timeouts and connection errors are network failures', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
      ]) {
        expect(
          mapError(DioException(requestOptions: request, type: type)),
          const AppFailure.network(),
        );
      }
      expect(
        mapError(
          DioException(
            requestOptions: request,
            error: const SocketException('down'),
          ),
        ),
        const AppFailure.network(),
      );
    });

    test('a failure carried by Dio is passed through', () {
      expect(
        mapError(
          DioException(
            requestOptions: request,
            error: const AppFailure.notSignedIn(),
          ),
        ),
        const AppFailure.notSignedIn(),
      );
    });
  });

  test('database errors are storage failures', () {
    expect(
      mapError(SqliteException(extendedResultCode: 13, message: 'full')),
      const AppFailure.storage(),
    );
  });

  test('anything else is unknown', () {
    expect(mapError(StateError('bug')), const AppFailure.unknown());
  });

  test('failure codes never contain messages', () {
    expect(
      failureCode(const AppFailure.validation(field: 'decidedAt')),
      'validation_failed:decidedAt',
    );
    expect(
      failureCode(const AppFailure.server(statusCode: 502)),
      'server_error:502',
    );
    expect(failureCode(const AppFailure.forbidden()), 'forbidden');
  });

  test('only network, rate-limit and server failures are transient', () {
    expect(const AppFailure.network().isTransient, isTrue);
    expect(const AppFailure.rateLimited().isTransient, isTrue);
    expect(const AppFailure.server().isTransient, isTrue);
    expect(const AppFailure.validation().isTransient, isFalse);
    expect(const AppFailure.unauthorized().isTransient, isFalse);
  });
}
