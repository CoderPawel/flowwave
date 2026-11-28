import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

/// Rule 4: every column the app stores must be listed in the data inventory.
void main() {
  test('every local table and column is in the data inventory', () async {
    final inventory = File('../../docs/privacy/data-inventory.md')
        .readAsStringSync();
    final db = inMemoryDatabase();
    addTearDown(db.close);

    final missing = <String>[];
    for (final table in db.allTables) {
      final section = _section(inventory, table.actualTableName);
      if (section == null) {
        missing.add('${table.actualTableName} (whole table)');
        continue;
      }
      for (final column in table.$columns) {
        if (!section.contains('`${column.name}`')) {
          missing.add('${table.actualTableName}.${column.name}');
        }
      }
    }
    expect(missing, isEmpty, reason: 'Add these to the "On the phone" section');
  });
}

String? _section(String markdown, String table) {
  final lines = markdown.split('\n');
  final start = lines.indexWhere(
    (line) => line.startsWith('### Phone table `$table`'),
  );
  if (start == -1) return null;
  final end = lines.indexWhere((line) => line.startsWith('#'), start + 1);
  return lines.sublist(start, end == -1 ? null : end).join('\n');
}
