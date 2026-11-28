import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Holds the key that encrypts the local database (decision 0015).
abstract interface class DatabaseKeyStore {
  /// The key as 64 hex characters (256 bits), created on first use.
  Future<String> readOrCreate();

  /// Forgets the key. The database it encrypted becomes unreadable.
  Future<void> delete();
}

/// Keeps the key in Android Keystore-backed storage or the iOS Keychain,
/// readable only on this device. It is never logged or backed up.
class SecureDatabaseKeyStore implements DatabaseKeyStore {
  SecureDatabaseKeyStore({FlutterSecureStorage? storage, Random? random})
    : _storage = storage ?? const FlutterSecureStorage(),
      _random = random ?? Random.secure();

  static const String storageKey = 'flowwave.database.key.v1';

  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
    synchronizable: false,
  );

  static final RegExp _validKey = RegExp(r'^[0-9a-f]{64}$');

  final FlutterSecureStorage _storage;
  final Random _random;

  @override
  Future<String> readOrCreate() async {
    final stored = await _storage.read(key: storageKey, iOptions: _iosOptions);
    if (stored != null && _validKey.hasMatch(stored)) return stored;
    if (stored != null) {
      throw StateError('The stored database key is malformed.');
    }
    final key = List<int>.generate(
      32,
      (_) => _random.nextInt(256),
    ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await _storage.write(key: storageKey, value: key, iOptions: _iosOptions);
    return key;
  }

  @override
  Future<void> delete() =>
      _storage.delete(key: storageKey, iOptions: _iosOptions);
}
