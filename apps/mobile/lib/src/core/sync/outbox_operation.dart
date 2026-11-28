import 'package:freezed_annotation/freezed_annotation.dart';

part 'outbox_operation.freezed.dart';

enum OutboxStatus {
  /// Waiting to be sent, now or after [OutboxOperation.nextAttemptAt].
  pending,

  /// Refused by the API for good; kept so the user can see it.
  rejected,
}

/// One queued write (decision 0007).
@freezed
abstract class OutboxOperation with _$OutboxOperation {
  const factory OutboxOperation({
    /// Equal to the ID of the entity it uploads, so enqueuing twice is a
    /// no-op and the API can replay it safely (rule 7).
    required String id,
    required String kind,
    required String payload,
    required DateTime createdAt,
    @Default(0) int attempts,
    required DateTime nextAttemptAt,
    @Default(OutboxStatus.pending) OutboxStatus status,
    String? lastError,
  }) = _OutboxOperation;
}

/// Counts shown on the data and privacy screen.
@freezed
abstract class OutboxSummary with _$OutboxSummary {
  const factory OutboxSummary({
    @Default(0) int pending,
    @Default(0) int rejected,
  }) = _OutboxSummary;
}
