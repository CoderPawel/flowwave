import 'dart:io';

// Errors from the background isolate arrive wrapped in DriftRemoteException.
// ignore: experimental_member_use
import 'package:drift/remote.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart';

import 'app_database.dart';
import 'database_key_store.dart';

/// The key does not decrypt the database file, for example because secure
/// storage was cleared while the file stayed. The data cannot be recovered;
/// the user decides whether to reset local data.
class DatabaseKeyMismatchException implements Exception {
  const DatabaseKeyMismatchException();

  @override
  String toString() => 'DatabaseKeyMismatchException';
}

/// The bundled SQLite has no encryption support. The app refuses to store
/// data unencrypted instead of silently falling back.
class EncryptionUnavailableException implements Exception {
  const EncryptionUnavailableException();

  @override
  String toString() => 'EncryptionUnavailableException';
}

const String databaseFileName = 'flowwave.sqlite';

final RegExp _hexKey = RegExp(r'^[0-9a-f]{64}$');

/// Unlocks a freshly opened connection with [hexKey]. Runs before Drift uses
/// the connection, also in the background isolate.
void applyEncryptionKey(CommonDatabase database, String hexKey) {
  if (!_hexKey.hasMatch(hexKey)) {
    throw ArgumentError.value('<redacted>', 'hexKey', 'Expected 64 hex digits');
  }
  // Plain SQLite ignores unknown pragmas and returns no rows.
  if (database.select('PRAGMA cipher').isEmpty) {
    throw const EncryptionUnavailableException();
  }
  database.execute("PRAGMA hexkey = '$hexKey'");
  // Reading the schema fails with SQLITE_NOTADB when the key is wrong.
  database.select('SELECT count(*) FROM sqlite_master');
}

/// True when [error] means the file cannot be decrypted with the given key.
bool isKeyMismatch(Object error) {
  final cause = error is DriftRemoteException ? error.remoteCause : error;
  if (cause is DatabaseKeyMismatchException) return true;
  if (cause is SqliteException) return cause.resultCode == 26;
  return cause.toString().contains('file is not a database');
}

bool _isEncryptionUnavailable(Object error) {
  final cause = error is DriftRemoteException ? error.remoteCause : error;
  return cause is EncryptionUnavailableException ||
      cause.toString().contains('EncryptionUnavailableException');
}

Future<File> defaultDatabaseFile() async => File(
  p.join((await getApplicationSupportDirectory()).path, databaseFileName),
);

/// Opens the encrypted app database (decision 0015) and checks that it can be
/// read. Throws [DatabaseKeyMismatchException] or
/// [EncryptionUnavailableException].
Future<AppDatabase> openEncryptedDatabase({
  required DatabaseKeyStore keys,
  Future<File> Function() file = defaultDatabaseFile,
}) async {
  final key = await keys.readOrCreate();
  final path = (await file()).path;
  final database = AppDatabase(
    driftDatabase(
      name: 'flowwave',
      native: DriftNativeOptions(
        databasePath: () async => path,
        setup: (raw) => applyEncryptionKey(raw, key),
      ),
    ),
  );
  await verifyReadable(database);
  return database;
}

/// Runs the first query, which opens the file and applies migrations, and
/// translates key problems. Closes [database] when it fails.
Future<void> verifyReadable(AppDatabase database) async {
  try {
    await database.customSelect('SELECT count(*) FROM local_settings').get();
  } catch (error) {
    await database.close();
    if (isKeyMismatch(error)) throw const DatabaseKeyMismatchException();
    if (_isEncryptionUnavailable(error)) {
      throw const EncryptionUnavailableException();
    }
    rethrow;
  }
}

/// Deletes the database file and its key, for a reset after a lost key or
/// for "delete data on this device".
Future<void> deleteDatabaseFiles({
  required DatabaseKeyStore keys,
  Future<File> Function() file = defaultDatabaseFile,
}) async {
  final base = (await file()).path;
  for (final suffix in const ['', '-wal', '-shm', '-journal']) {
    final candidate = File('$base$suffix');
    if (await candidate.exists()) await candidate.delete();
  }
  await keys.delete();
}
