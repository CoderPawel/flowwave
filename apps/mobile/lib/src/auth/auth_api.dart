import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_tokens.dart';

/// The API answered with an error status.
class AuthApiException implements Exception {
  const AuthApiException(this.statusCode, {this.error, this.reason});

  final int statusCode;

  /// Stable error code from the API, for example `authentication_failed`.
  final String? error;

  /// Why authentication failed, for example `refresh_token_reused`.
  final String? reason;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() =>
      'AuthApiException($statusCode, ${error ?? '-'}, ${reason ?? '-'})';
}

/// The API could not be reached. Tokens stay valid; try again later.
class AuthNetworkException implements Exception {
  const AuthNetworkException(this.cause);

  final Object cause;

  @override
  String toString() => 'AuthNetworkException(${cause.runtimeType})';
}

/// Calls the authentication endpoints of the FlowWave API.
class AuthApi {
  AuthApi({
    required this._baseUrl,
    http.Client? client,
    this.platform = 'android',
    this.appVersion,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  final Uri _baseUrl;
  final http.Client _client;
  final String platform;
  final String? appVersion;
  final Duration timeout;

  Map<String, Object?> get _device => {
    'platform': platform,
    if (appVersion != null) 'appVersion': appVersion,
  };

  Future<AuthTokens> register({
    required String email,
    required String password,
    required String homeTimeZone,
  }) async => AuthTokens.fromJson(
    await _post('v1/auth/register', {
      'email': email,
      'password': password,
      'homeTimeZone': homeTimeZone,
      'device': _device,
    }, expected: 201),
  );

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async => AuthTokens.fromJson(
    await _post('v1/auth/login', {
      'email': email,
      'password': password,
      'device': _device,
    }),
  );

  Future<AuthTokens> refresh(String refreshToken) async => AuthTokens.fromJson(
    await _post('v1/auth/refresh', {'refreshToken': refreshToken}),
  );

  Future<void> logout(String accessToken) =>
      _post('v1/auth/logout', null, accessToken: accessToken, expected: 204);

  Future<void> logoutAll(String accessToken) =>
      _post('v1/auth/logout-all', null, accessToken: accessToken);

  Future<Map<String, Object?>> _post(
    String path,
    Map<String, Object?>? body, {
    String? accessToken,
    int expected = 200,
  }) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            _baseUrl.resolve(path),
            headers: {
              'accept': 'application/json',
              if (body != null) 'content-type': 'application/json',
              if (accessToken != null) 'authorization': 'Bearer $accessToken',
            },
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(timeout);
    } on http.ClientException catch (error) {
      throw AuthNetworkException(error);
    } on TimeoutException catch (error) {
      throw AuthNetworkException(error);
    }

    final decoded = _decode(response.body);
    if (response.statusCode != expected) {
      throw AuthApiException(
        response.statusCode,
        error: decoded['error'] is String ? decoded['error'] as String : null,
        reason: decoded['reason'] is String
            ? decoded['reason'] as String
            : null,
      );
    }
    return decoded;
  }

  static Map<String, Object?> _decode(String body) {
    if (body.isEmpty) return const {};
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, Object?> ? decoded : const {};
    } on FormatException {
      return const {};
    }
  }

  void close() => _client.close();
}
