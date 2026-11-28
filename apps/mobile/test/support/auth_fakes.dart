import 'package:flowwave_mobile/src/features/auth/domain/auth_tokens.dart';
import 'package:flowwave_mobile/src/features/auth/domain/token_store.dart';

import 'fake_http_adapter.dart';

final Uri testBaseUrl = Uri.parse('https://api.flowwave.test/');

class InMemoryTokenStore implements TokenStore {
  AuthTokens? tokens;
  int clears = 0;

  @override
  Future<AuthTokens?> read() async => tokens;

  @override
  Future<void> write(AuthTokens value) async => tokens = value;

  @override
  Future<void> clear() async {
    clears += 1;
    tokens = null;
  }
}

/// A clock the test moves by hand.
class TestClock {
  TestClock([DateTime? start])
    : current = start ?? DateTime.utc(2026, 11, 28, 9);

  DateTime current;

  DateTime now() => current;

  void advance(Duration duration) => current = current.add(duration);
}

/// Token pair number [n], issued at [issuedAt].
AuthTokens tokensFor(
  int n,
  DateTime issuedAt, {
  Duration accessLifetime = const Duration(minutes: 15),
}) => AuthTokens(
  accessToken: 'fwat_access$n',
  accessTokenExpiresAt: issuedAt.add(accessLifetime),
  refreshToken: 'fwrt_refresh$n',
  refreshTokenExpiresAt: issuedAt.add(const Duration(days: 30)),
  userId: '6f1c2c1e-7d1a-4d2e-9b1a-0c8d7e6f5a40',
  sessionId: '0b7e6a52-3c1f-4d7e-9a3b-2f8c1d4e5a6b',
  deviceId: '9a8b7c6d-5e4f-4a3b-8c2d-1e0f9a8b7c6d',
);

FakeResponse tokenResponse(AuthTokens tokens, {int status = 200}) =>
    FakeResponse.json(tokens.toJson(), status: status);

FakeResponse unauthorized(String reason) => FakeResponse.json({
  'statusCode': 401,
  'error': 'authentication_failed',
  'message': 'Authentication failed.',
  'reason': reason,
}, status: 401);
