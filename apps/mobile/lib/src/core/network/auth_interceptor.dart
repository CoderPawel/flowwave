import 'package:dio/dio.dart';

import '../errors/app_failure.dart';
import '../errors/error_mapper.dart';

/// What [AuthInterceptor] needs from the signed-in session.
abstract interface class AccessTokenSource {
  /// A valid access token, refreshed first when it is about to expire.
  /// Throws [AppFailure] when there is no session.
  Future<String> accessToken();

  /// A new token after the API rejected [rejected] with `401`.
  Future<String> accessTokenAfterRejection(String rejected);
}

/// Adds the access token to every request, refreshes it before it expires,
/// and retries once with a renewed token after a `401` (decision 0013).
/// Requests without a session fail with `AppFailure.notSignedIn` and never
/// reach the network.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this._tokens, required this._dio});

  final AccessTokenSource _tokens;

  /// The client this interceptor belongs to, used for the single retry.
  final Dio _dio;

  static const String _retriedKey = 'flowwave.auth.retried';
  static const String _tokenKey = 'flowwave.auth.token';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _tokens.accessToken();
      options.headers['authorization'] = 'Bearer $token';
      options.extra[_tokenKey] = token;
      handler.next(options);
    } catch (error) {
      handler.reject(
        DioException(requestOptions: options, error: mapError(error)),
      );
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final rejected = options.extra[_tokenKey];
    if (err.response?.statusCode != 401 ||
        options.extra[_retriedKey] == true ||
        rejected is! String) {
      handler.next(err);
      return;
    }
    try {
      final renewed = await _tokens.accessTokenAfterRejection(rejected);
      options.extra[_retriedKey] = true;
      options.headers['authorization'] = 'Bearer $renewed';
      options.extra[_tokenKey] = renewed;
      handler.resolve(await _dio.fetch<Object?>(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    } catch (error) {
      handler.next(
        DioException(requestOptions: options, error: mapError(error)),
      );
    }
  }
}
