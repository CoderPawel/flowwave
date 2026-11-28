import 'package:drift/drift.dart';

import 'tables.dart';

export 'tables.dart';

part 'app_database.g.dart';

/// The on-device source of truth (decision 0007). Opened encrypted by
/// `openEncryptedDatabase`; tests pass an in-memory executor.
@DriftDatabase(tables: [LocalSettings, ConsentDecisions, OutboxOperations])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await into(localSettings)
          .insert(const LocalSettingsCompanion(id: Value(1)));
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Deletes every row, for "delete data on this device". The single
  /// settings row is recreated with defaults.
  Future<void> deleteEverything() => transaction(() async {
    for (final table in allTables) {
      await delete(table).go();
    }
    await into(localSettings)
        .insert(const LocalSettingsCompanion(id: Value(1)));
  });
}
