import 'package:flutter_timezone/flutter_timezone.dart';

import 'zoned_timestamp.dart';

/// The current time with the device's IANA time zone (rule 9).
abstract interface class ZonedClock {
  /// The current UTC instant.
  DateTime nowUtc();

  /// The device's IANA time zone, for example `Europe/Budapest`.
  Future<String> timeZone();

  /// The current moment as a [ZonedTimestamp].
  Future<ZonedTimestamp> now();
}

/// Reads the zone from the platform. Flutter alone only exposes abbreviations
/// such as "CET", which the API cannot interpret.
class DeviceZonedClock implements ZonedClock {
  DeviceZonedClock({Future<String> Function()? lookupTimeZone})
    : _lookupTimeZone = lookupTimeZone ?? _platformTimeZone;

  final Future<String> Function() _lookupTimeZone;

  static Future<String> _platformTimeZone() async =>
      (await FlutterTimezone.getLocalTimezone()).identifier;

  @override
  DateTime nowUtc() => DateTime.now().toUtc();

  /// Looked up each time, because the user may travel while the app runs.
  @override
  Future<String> timeZone() => _lookupTimeZone();

  @override
  Future<ZonedTimestamp> now() async {
    final zone = await timeZone();
    final local = DateTime.now();
    return ZonedTimestamp.at(
      local,
      timeZone: zone,
      utcOffsetMinutes: local.timeZoneOffset.inMinutes,
    );
  }
}
