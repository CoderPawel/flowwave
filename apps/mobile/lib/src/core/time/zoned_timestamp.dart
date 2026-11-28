import 'package:freezed_annotation/freezed_annotation.dart';

part 'zoned_timestamp.freezed.dart';
part 'zoned_timestamp.g.dart';

/// A moment as the API stores it (rule 9): the UTC instant, the IANA time
/// zone where it happened, and the offset in effect there at that instant.
@freezed
abstract class ZonedTimestamp with _$ZonedTimestamp {
  const ZonedTimestamp._();

  const factory ZonedTimestamp({
    /// ISO 8601 UTC instant with millisecond precision, ending in `Z`.
    required String utc,
    required String timeZone,
    required int utcOffsetMinutes,
  }) = _ZonedTimestamp;

  /// Builds a timestamp for [instant]. The API accepts at most three
  /// fractional digits, so microseconds are dropped.
  factory ZonedTimestamp.at(
    DateTime instant, {
    required String timeZone,
    required int utcOffsetMinutes,
  }) {
    final millis = DateTime.fromMillisecondsSinceEpoch(
      instant.millisecondsSinceEpoch,
      isUtc: true,
    );
    return ZonedTimestamp(
      utc: millis.toIso8601String(),
      timeZone: timeZone,
      utcOffsetMinutes: utcOffsetMinutes,
    );
  }

  factory ZonedTimestamp.fromJson(Map<String, Object?> json) =>
      _$ZonedTimestampFromJson(json);

  DateTime get instant => DateTime.parse(utc);
}
