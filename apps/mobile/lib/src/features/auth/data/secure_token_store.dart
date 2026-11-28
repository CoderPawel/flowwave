import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/auth_tokens.dart';
import '../domain/token_store.dart';

/// Keeps tokens in the platform's secure storage: Android Keystore-backed
/// encryption, the iOS Keychain. Tokens never go to shared preferences, files,
/// logs, or backups (decision 0013).
class SecureTokenStore implements TokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String storageKey = 'flowwave.auth.tokens.v1';

  /// Readable only on this device after the first unlock; never synced to
  /// iCloud and never restored onto another device.
  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
    synchronizable: false,
  );

  final FlutterSecureStorage _storage;

  @override
  Future<AuthTokens?> read() async {
    final stored = await _storage.read(key: storageKey, iOptions: _iosOptions);
    if (stored == null) return null;
    try {
      final decoded = jsonDecode(stored);
      if (decoded is! Map<String, Object?>) throw const FormatException();
      return AuthTokens.fromJson(decoded);
    } on FormatException {
      // Unreadable leftovers (for example from an older format) mean signed out.
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(AuthTokens tokens) => _storage.write(
    key: storageKey,
    value: jsonEncode(tokens.toJson()),
    iOptions: _iosOptions,
  );

  @override
  Future<void> clear() =>
      _storage.delete(key: storageKey, iOptions: _iosOptions);
}
