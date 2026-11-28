import 'package:dio/dio.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/errors/error_mapper.dart';
import '../domain/consent_decision.dart';
import '../domain/consent_repository.dart';

/// Uses the authenticated Dio client (with `AuthInterceptor`).
class DioConsentRemoteDataSource implements ConsentRemoteDataSource {
  DioConsentRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<void> upload(Map<String, Object?> body) async {
    try {
      await _dio.post<Object?>('v1/consents', data: body);
    } on DioException catch (error) {
      throw mapError(error);
    }
  }

  @override
  Future<List<ConsentDecision>> history() async {
    final Object? data;
    try {
      data = (await _dio.get<Object?>('v1/consents/history')).data;
    } on DioException catch (error) {
      throw mapError(error);
    }
    if (data is! List) throw const AppFailure.server();
    try {
      return [
        for (final item in data)
          ConsentDecision.fromJson((item as Map).cast<String, Object?>()),
      ];
    } on Object {
      throw const AppFailure.server();
    }
  }
}

/// Used when the build has no API configured.
class UnconfiguredConsentRemoteDataSource implements ConsentRemoteDataSource {
  const UnconfiguredConsentRemoteDataSource();

  @override
  Future<void> upload(Map<String, Object?> body) async =>
      throw const AppFailure.notConfigured();

  @override
  Future<List<ConsentDecision>> history() async =>
      throw const AppFailure.notConfigured();
}
