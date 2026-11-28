/// Tokens issued by `POST /v1/auth/login`, `/register`, and `/refresh`.
///
/// Times are UTC instants. Tokens are opaque; the app never parses them.
class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.refreshTokenExpiresAt,
    required this.userId,
    required this.sessionId,
    required this.deviceId,
  });

  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String refreshToken;
  final DateTime refreshTokenExpiresAt;
  final String userId;
  final String sessionId;
  final String deviceId;

  /// True when the access token is expired or expires within [margin].
  bool accessExpiresWithin(Duration margin, DateTime now) =>
      !now.toUtc().add(margin).isBefore(accessTokenExpiresAt);

  bool refreshExpired(DateTime now) =>
      !now.toUtc().isBefore(refreshTokenExpiresAt);

  /// Parses an API token response or a stored copy. Throws [FormatException]
  /// when a field is missing or malformed.
  factory AuthTokens.fromJson(Map<String, Object?> json) {
    String text(String key) {
      final value = json[key];
      if (value is! String || value.isEmpty) {
        throw FormatException('Token response field "$key" is missing.');
      }
      return value;
    }

    DateTime instant(String key) {
      final parsed = DateTime.tryParse(text(key));
      if (parsed == null || !parsed.isUtc) {
        throw FormatException(
          'Token response field "$key" is not a UTC instant.',
        );
      }
      return parsed;
    }

    return AuthTokens(
      accessToken: text('accessToken'),
      accessTokenExpiresAt: instant('accessTokenExpiresAt'),
      refreshToken: text('refreshToken'),
      refreshTokenExpiresAt: instant('refreshTokenExpiresAt'),
      userId: text('userId'),
      sessionId: text('sessionId'),
      deviceId: text('deviceId'),
    );
  }

  Map<String, Object?> toJson() => {
    'accessToken': accessToken,
    'accessTokenExpiresAt': accessTokenExpiresAt.toUtc().toIso8601String(),
    'refreshToken': refreshToken,
    'refreshTokenExpiresAt': refreshTokenExpiresAt.toUtc().toIso8601String(),
    'userId': userId,
    'sessionId': sessionId,
    'deviceId': deviceId,
  };

  /// Never prints the tokens themselves.
  @override
  String toString() =>
      'AuthTokens(session: $sessionId, access expires: $accessTokenExpiresAt)';
}
