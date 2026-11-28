import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flowwave_mobile/src/core/database/app_database.dart';
import 'package:flowwave_mobile/src/core/time/zoned_clock.dart';
import 'package:flowwave_mobile/src/core/time/zoned_timestamp.dart';

/// An unencrypted in-memory database. Streams close synchronously so widget
/// tests end without pending timers.
AppDatabase inMemoryDatabase() => AppDatabase(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);

/// A clock in Europe/Warsaw (UTC+1 in winter) that the test moves by hand.
class FixedZonedClock implements ZonedClock {
  FixedZonedClock([DateTime? start])
    : current = start ?? DateTime.utc(2026, 11, 28, 9);

  DateTime current;
  String zone = 'Europe/Warsaw';
  int offsetMinutes = 60;

  void advance(Duration duration) => current = current.add(duration);

  @override
  DateTime nowUtc() => current;

  @override
  Future<String> timeZone() async => zone;

  @override
  Future<ZonedTimestamp> now() async => ZonedTimestamp.at(
    current,
    timeZone: zone,
    utcOffsetMinutes: offsetMinutes,
  );
}
