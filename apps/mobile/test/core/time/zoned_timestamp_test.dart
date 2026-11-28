import 'package:flowwave_mobile/src/core/ids.dart';
import 'package:flowwave_mobile/src/core/time/zoned_clock.dart';
import 'package:flowwave_mobile/src/core/time/zoned_timestamp.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps at most milliseconds, as the API requires', () {
    final stamp = ZonedTimestamp.at(
      DateTime.utc(2026, 11, 28, 9, 30, 15, 123, 456),
      timeZone: 'Europe/Warsaw',
      utcOffsetMinutes: 60,
    );
    expect(stamp.utc, '2026-11-28T09:30:15.123Z');
    expect(stamp.instant, DateTime.utc(2026, 11, 28, 9, 30, 15, 123));
  });

  test('stores local times as UTC instants', () {
    final local = DateTime(2026, 11, 28, 10);
    final stamp = ZonedTimestamp.at(
      local,
      timeZone: 'Europe/Warsaw',
      utcOffsetMinutes: local.timeZoneOffset.inMinutes,
    );
    expect(stamp.utc, endsWith('Z'));
    expect(stamp.instant, local.toUtc());
  });

  test('serializes to the API shape', () {
    final stamp = ZonedTimestamp.at(
      DateTime.utc(2026, 11, 28, 9),
      timeZone: 'Europe/Warsaw',
      utcOffsetMinutes: 60,
    );
    expect(stamp.toJson(), {
      'utc': '2026-11-28T09:00:00.000Z',
      'timeZone': 'Europe/Warsaw',
      'utcOffsetMinutes': 60,
    });
    expect(ZonedTimestamp.fromJson(stamp.toJson()), stamp);
  });

  test('the device clock uses the looked-up IANA zone', () async {
    final clock = DeviceZonedClock(lookupTimeZone: () async => 'Europe/Warsaw');
    final stamp = await clock.now();
    expect(stamp.timeZone, 'Europe/Warsaw');
    expect(stamp.utcOffsetMinutes, DateTime.now().timeZoneOffset.inMinutes);
  });

  test('IDs are random version 4 UUIDs', () {
    final ids = {for (var i = 0; i < 100; i++) newUuid()};
    expect(ids, hasLength(100));
    for (final id in ids) {
      expect(
        id,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    }
  });
}
