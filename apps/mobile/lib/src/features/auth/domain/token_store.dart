import 'auth_tokens.dart';

/// Where the signed-in session's tokens live between app starts.
abstract interface class TokenStore {
  Future<AuthTokens?> read();
  Future<void> write(AuthTokens tokens);
  Future<void> clear();
}
