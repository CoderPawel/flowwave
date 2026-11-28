import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flowwave_mobile/src/core/database/app_database.dart';
import 'package:flowwave_mobile/src/core/database/database_key_store.dart';
import 'package:flowwave_mobile/src/core/database/encrypted_database.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../support/test_database.dart';

String _key(int seed) {
  final random = Random(seed);
  return List.generate(
    32,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

void main() {
  late Directory directory;
  late File file;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('flowwave-db-');
    file = File('${directory.path}/flowwave.sqlite');
  });

  tearDown(() => directory.delete(recursive: true));

  Future<AppDatabase> open(String key) async {
    final database = AppDatabase(
      NativeDatabase(file, setup: (raw) => applyEncryptionKey(raw, key)),
    );
    await verifyReadable(database);
    return database;
  }

  test('the bundled SQLite supports encryption', () {
    final raw = sqlite3.openInMemory();
    addTearDown(raw.close);
    expect(raw.select('PRAGMA cipher'), isNotEmpty);
  });

  test('data written with a key is readable with the same key', () async {
    final first = await open(_key(1));
    await first
        .into(first.outboxOperations)
        .insert(
          OutboxOperationsCompanion.insert(
            id: 'op-1',
            kind: 'consent_decision',
            payload: '{}',
            createdAtUtc: DateTime.utc(2026, 11, 28),
            nextAttemptAtUtc: DateTime.utc(2026, 11, 28),
          ),
        );
    await first.close();

    final again = await open(_key(1));
    addTearDown(again.close);
    final rows = await again.select(again.outboxOperations).get();
    expect(rows.single.id, 'op-1');
  });

  test('the file cannot be opened without the key', () async {
    await (await open(_key(1))).close();

    final header = (await file.openRead(0, 16).first).take(15).toList();
    expect(
      String.fromCharCodes(header),
      isNot('SQLite format 3'),
      reason: 'an unencrypted file starts with this header',
    );

    final plain = sqlite3.open(file.path);
    addTearDown(plain.close);
    expect(
      () => plain.select('SELECT count(*) FROM sqlite_master'),
      throwsA(isA<SqliteException>()),
    );
  });

  test('a wrong key is reported as a key mismatch', () async {
    await (await open(_key(1))).close();
    await expectLater(
      open(_key(2)),
      throwsA(isA<DatabaseKeyMismatchException>()),
    );
  });

  test('keys must be 64 hex digits and are never echoed', () {
    final raw = sqlite3.openInMemory();
    addTearDown(raw.close);
    expect(
      () => applyEncryptionKey(raw, 'secret'),
      throwsA(
        isA<ArgumentError>().having(
          (e) => e.toString(),
          'message',
          isNot(contains('secret')),
        ),
      ),
    );
  });

  test('deleting the files removes the database and forgets the key', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final keys = SecureDatabaseKeyStore();
    final key = await keys.readOrCreate();
    await (await open(key)).close();

    await deleteDatabaseFiles(keys: keys, file: () async => file);

    expect(await file.exists(), isFalse);
    expect(await keys.readOrCreate(), isNot(key));
  });

  group('key store', () {
    late Map<String, String> platformData;

    setUp(() {
      platformData = {};
      FlutterSecureStorage.setMockInitialValues(platformData);
    });

    test('creates a 256-bit key once and keeps it', () async {
      final keys = SecureDatabaseKeyStore();
      final key = await keys.readOrCreate();
      expect(key, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(await keys.readOrCreate(), key);
      expect(platformData.keys, [SecureDatabaseKeyStore.storageKey]);
    });

    test('refuses a malformed stored key instead of replacing it', () async {
      platformData[SecureDatabaseKeyStore.storageKey] = 'not-a-key';
      await expectLater(
        SecureDatabaseKeyStore().readOrCreate(),
        throwsStateError,
      );
      expect(platformData[SecureDatabaseKeyStore.storageKey], 'not-a-key');
    });
  });

  group('schema', () {
    test('creates the single settings row with defaults', () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final rows = await db.select(db.localSettings).get();
      expect(rows.single.id, 1);
      expect(rows.single.themePreference, 'system');
      expect(rows.single.onboardingCompletedAtUtc, isNull);
    });

    test('allows no second settings row', () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      await expectLater(
        db
            .into(db.localSettings)
            .insert(const LocalSettingsCompanion(id: Value(2))),
        throwsA(isA<SqliteException>()),
      );
    });

    test('keeps UTC instants with milliseconds', () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final instant = DateTime.utc(2026, 11, 28, 9, 30, 15, 123);
      await db
          .into(db.outboxOperations)
          .insert(
            OutboxOperationsCompanion.insert(
              id: 'op-1',
              kind: 'k',
              payload: '{}',
              createdAtUtc: instant,
              nextAttemptAtUtc: instant,
            ),
          );
      final row = await db.select(db.outboxOperations).getSingle();
      expect(row.createdAtUtc.toUtc(), instant);
    });

    test('deleting everything restores default settings', () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      await (db.update(db.localSettings)).write(
        LocalSettingsCompanion(
          themePreference: const Value('dark'),
          onboardingCompletedAtUtc: Value(DateTime.utc(2026, 11, 28)),
        ),
      );
      await db.deleteEverything();
      final row = await db.select(db.localSettings).getSingle();
      expect(row.themePreference, 'system');
      expect(row.onboardingCompletedAtUtc, isNull);
    });
  });
}
