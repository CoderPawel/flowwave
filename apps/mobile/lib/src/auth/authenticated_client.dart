import 'package:http/http.dart' as http;

import 'auth_session.dart';

/// An HTTP client that adds the access token to every request, refreshes it
/// before it expires, and retries once after a 401.
///
/// Only [http.Request] (a body known up front) can be retried; streamed and
/// multipart requests return the 401 to the caller.
class AuthenticatedClient extends http.BaseClient {
  AuthenticatedClient(this._session, {http.Client? inner})
    : _inner = inner ?? http.Client();

  final AuthSession _session;
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final retry = request is http.Request ? _copy(request) : null;
    final token = await _session.accessToken();
    request.headers['authorization'] = 'Bearer $token';
    final response = await _inner.send(request);
    if (response.statusCode != 401 || retry == null) return response;

    await response.stream.drain<void>();
    final renewed = await _session.accessTokenAfterRejection(token);
    retry.headers['authorization'] = 'Bearer $renewed';
    return _inner.send(retry);
  }

  static http.Request _copy(http.Request original) {
    final copy = http.Request(original.method, original.url)
      ..headers.addAll(original.headers)
      ..followRedirects = original.followRedirects
      ..maxRedirects = original.maxRedirects
      ..persistentConnection = original.persistentConnection;
    if (original.bodyBytes.isNotEmpty) copy.bodyBytes = original.bodyBytes;
    return copy;
  }

  @override
  void close() => _inner.close();
}
