import 'package:dio/dio.dart';

/// A Dio client for the FlowWave API. Bodies are JSON; error responses are
/// turned into `AppFailure` by `mapError`. Requests and responses are never
/// logged, because they carry tokens and personal data.
Dio createApiDio(
  Uri baseUrl, {
  HttpClientAdapter? adapter,
  Duration connectTimeout = const Duration(seconds: 10),
  Duration receiveTimeout = const Duration(seconds: 15),
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl.toString(),
      connectTimeout: connectTimeout,
      sendTimeout: receiveTimeout,
      receiveTimeout: receiveTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: const {'accept': 'application/json'},
    ),
  );
  if (adapter != null) dio.httpClientAdapter = adapter;
  return dio;
}
