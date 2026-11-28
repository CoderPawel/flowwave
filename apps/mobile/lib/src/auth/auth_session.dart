import 'dart:async';

import 'package:flutter/foundation.dart';

import 'auth_api.dart';
import 'auth_tokens.dart';
import 'logout_cleanup.dart';
import 'token_store.dart';

/// No usable session: the user must sign in. Local data stays usable, because
/// the app works offline (rule 8).
class NotSignedInException implements Exception {
  const NotSignedInException([this.reason]);

  /// Why the session ended, for example `refresh_token_reused`.
  final String? reason;

  @override
  String toString() => 'NotSignedInException(${reason ?? 'not signed in'})';
}

/// The signed-in session on this phone: keeps tokens in secure storage,
/// refreshes the access token before it expires, and signs out completely.
class AuthSession extends ChangeNotifier {
  AuthSession({
    required this._api,
    required this._store,
    LogoutCleanup? cleanup,
    DateTime Function()? now,
    this.refreshMargin = const Duration(seconds: 60),
  }) : cleanup = cleanup ?? LogoutCleanup(),
       _now = now ?? DateTime.now;

  final AuthApi _api;
  final TokenStore _store;
  final DateTime Function() _now;

  /// Tasks that delete account data stored on the phone at sign-out.
  final LogoutCleanup cleanup;

  /// Refresh this long before the access token expires.
  final Duration refreshMargin;

  AuthTokens? _tokens;
  Future<AuthTokens>? _refreshing;

  bool get isSignedIn => _tokens != null;
  String? get userId => _tokens?.userId;
  String? get deviceId => _tokens?.deviceId;

  /// Loads the session saved by a previous app start.
  Future<void> restore() async {
    final stored = await _store.read();
    if (stored != null && stored.refreshExpired(_now())) {
      await _clearLocal();
      return;
    }
    _tokens = stored;
    notifyListeners();
  }

  Future<void> signIn({required String email, required String password}) =>
      _start(_api.login(email: email, password: password));

  Future<void> register({
    required String email,
    required String password,
    required String homeTimeZone,
  }) => _start(
    _api.register(email: email, password: password, homeTimeZone: homeTimeZone),
  );

  /// A valid access token, refreshed first when it is about to expire.
  /// Throws [NotSignedInException] when there is no session (any more) and
  /// [AuthNetworkException] when a needed refresh cannot reach the API.
  Future<String> accessToken() async {
    final tokens = _tokens;
    if (tokens == null) throw const NotSignedInException();
    if (!tokens.accessExpiresWithin(refreshMargin, _now())) {
      return tokens.accessToken;
    }
    return (await refresh()).accessToken;
  }

  /// Exchanges the refresh token for a new pair. Concurrent callers share one
  /// request: a second request with the same single-use refresh token would
  /// look like token theft and sign the device out (decision 0013).
  Future<AuthTokens> refresh() {
    return _refreshing ??= _refresh().whenComplete(() => _refreshing = null);
  }

  Future<AuthTokens> _refresh() async {
    final current = _tokens;
    if (current == null) throw const NotSignedInException();
    try {
      final next = await _api.refresh(current.refreshToken);
      await _store.write(next);
      _tokens = next;
      return next;
    } on AuthApiException catch (error) {
      if (error.isUnauthorized) {
        // The server ended the session (expired, signed out elsewhere, or reuse
        // detected). Signing out locally is the only safe answer.
        await _clearLocal();
        throw NotSignedInException(error.reason);
      }
      rethrow;
    }
  }

  /// Signs out this device. Local cleanup always runs, even offline or when
  /// the API call fails; the server session then ends at its expiry.
  ///
  /// Returns the names of cleanup tasks that failed.
  Future<List<String>> signOut({bool allDevices = false}) async {
    final tokens = _tokens;
    if (tokens != null) {
      try {
        if (allDevices) {
          await _api.logoutAll(tokens.accessToken);
        } else {
          await _api.logout(tokens.accessToken);
        }
      } on AuthApiException {
        // Already signed out on the server.
      } on AuthNetworkException {
        // Offline: the local sign-out below still happens.
      }
    }
    return _clearLocal();
  }

  /// A new access token after the API rejected [rejected] with 401. When
  /// another request already refreshed, its token is used without a refresh.
  Future<String> accessTokenAfterRejection(String rejected) async {
    final tokens = _tokens;
    if (tokens == null) throw const NotSignedInException();
    if (tokens.accessToken != rejected) return tokens.accessToken;
    return (await refresh()).accessToken;
  }

  Future<void> _start(Future<AuthTokens> request) async {
    final tokens = await request;
    await _store.write(tokens);
    _tokens = tokens;
    notifyListeners();
  }

  Future<List<String>> _clearLocal() async {
    final hadSession = _tokens != null;
    _tokens = null;
    await _store.clear();
    final failed = await cleanup.runAll();
    if (hadSession) notifyListeners();
    return failed;
  }
}
