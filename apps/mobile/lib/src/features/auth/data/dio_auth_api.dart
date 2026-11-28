import 'package:dio/dio.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/errors/error_mapper.dart';
import '../domain/auth_api.dart';
import '../domain/auth_tokens.dart';

/// Calls the authentication endpoints with an unauthenticated Dio client.
class DioAuthApi implements AuthApi {
  DioAuthApi({required this._dio, this.platform = 'android', this.appVersion});

  final Dio _dio;
  final String platform;
  final String? appVersion;

  Map<String, Object?> get _device => {
    'platform': platform,
    if (appVersion != null) 'appVersion': appVersion,
  };

  @override
  Future<AuthTokens> register({
    required String email,
    required String password,
    required String homeTimeZone,
  }) async => _tokens(
    await _post('v1/auth/register', {
      'email': email,
      'password': password,
      'homeTimeZone': homeTimeZone,
      'device': _device,
    }),
  );

  @override
  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async => _tokens(
    await _post('v1/auth/login', {
      'email': email,
      'password': password,
      'device': _device,
    }),
  );

  @override
  Future<AuthTokens> refresh(String refreshToken) async =>
      _tokens(await _post('v1/auth/refresh', {'refreshToken': refreshToken}));

  @override
  Future<void> logout(String accessToken) =>
      _post('v1/auth/logout', null, accessToken: accessToken);

  @override
  Future<void> logoutAll(String accessToken) =>
      _post('v1/auth/logout-all', null, accessToken: accessToken);

  Future<Object?> _post(
    String path,
    Map<String, Object?>? body, {
    String? accessToken,
  }) async {
    try {
      final response = await _dio.post<Object?>(
        path,
        data: body,
        options: Options(
          headers: {
            if (accessToken != null) 'authorization': 'Bearer $accessToken',
          },
        ),
      );
      return response.data;
    } on DioException catch (error) {
      throw mapError(error);
    }
  }

  static AuthTokens _tokens(Object? data) {
    if (data is! Map<String, Object?>) {
      throw const AppFailure.server();
    }
    try {
      return AuthTokens.fromJson(data);
    } on FormatException {
      throw const AppFailure.server();
    }
  }
}

/// Used when the build has no API configured: the app stays offline.
class UnconfiguredAuthApi implements AuthApi {
  const UnconfiguredAuthApi();

  Never _fail() => throw const AppFailure.notConfigured();

  @override
  Future<AuthTokens> register({
    required String email,
    required String password,
    required String homeTimeZone,
  }) async => _fail();

  @override
  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async => _fail();

  @override
  Future<AuthTokens> refresh(String refreshToken) async => _fail();

  @override
  Future<void> logout(String accessToken) async => _fail();

  @override
  Future<void> logoutAll(String accessToken) async => _fail();
}
