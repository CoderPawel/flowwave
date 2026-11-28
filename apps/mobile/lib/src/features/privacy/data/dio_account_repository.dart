import 'package:dio/dio.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/errors/error_mapper.dart';
import '../domain/account_repository.dart';

/// Uses the authenticated Dio client (with `AuthInterceptor`).
class DioAccountRepository implements AccountRepository {
  DioAccountRepository(this._dio);

  final Dio _dio;

  @override
  Future<void> deleteAccount({required String password}) async {
    try {
      await _dio.delete<Object?>('v1/account', data: {'password': password});
    } on DioException catch (error) {
      throw mapError(error);
    }
  }
}

/// Used when the build has no API configured.
class UnconfiguredAccountRepository implements AccountRepository {
  const UnconfiguredAccountRepository();

  @override
  Future<void> deleteAccount({required String password}) async =>
      throw const AppFailure.notConfigured();
}
