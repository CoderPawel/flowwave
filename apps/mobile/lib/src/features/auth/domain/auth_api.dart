import 'auth_tokens.dart';

/// The authentication endpoints of the FlowWave API (decision 0013).
/// Implementations throw `AppFailure`.
abstract interface class AuthApi {
  Future<AuthTokens> register({
    required String email,
    required String password,
    required String homeTimeZone,
  });

  Future<AuthTokens> login({required String email, required String password});

  Future<AuthTokens> refresh(String refreshToken);

  Future<void> logout(String accessToken);

  Future<void> logoutAll(String accessToken);
}
