import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A request as the fake server saw it.
class FakeRequest {
  FakeRequest(this.method, this.path, this.headers, this.body);

  final String method;
  final String path;
  final Map<String, Object?> headers;

  /// The decoded JSON body, or `null`.
  final Object? body;

  String? get authorization => headers['authorization'] as String?;
}

class FakeResponse {
  const FakeResponse(this.status, {this.body = '', this.headers = const {}});

  factory FakeResponse.json(
    Object? json, {
    int status = 200,
    Map<String, String> headers = const {},
  }) => FakeResponse(status, body: jsonEncode(json), headers: headers);

  const FakeResponse.empty([int status = 204]) : this(status);

  final int status;
  final String body;
  final Map<String, String> headers;
}

typedef FakeHandler = FutureOr<FakeResponse> Function(FakeRequest request);

/// A Dio transport that answers from [handler] instead of the network.
/// Throwing from the handler (for example a `SocketException`) simulates a
/// network failure.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter([FakeHandler? handler])
    : handler = handler ?? ((_) => const FakeResponse(500));

  FakeHandler handler;
  final List<FakeRequest> requests = [];

  List<String> get paths => [for (final r in requests) r.path];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Object? body;
    if (requestStream != null) {
      final bytes = await requestStream.expand((chunk) => chunk).toList();
      if (bytes.isNotEmpty) body = jsonDecode(utf8.decode(bytes));
    }
    final request = FakeRequest(
      options.method,
      options.uri.path,
      Map.of(options.headers),
      body,
    );
    requests.add(request);
    final response = await handler(request);
    return ResponseBody.fromString(
      response.body,
      response.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        for (final entry in response.headers.entries) entry.key: [entry.value],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
