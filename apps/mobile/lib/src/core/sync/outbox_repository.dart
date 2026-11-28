import 'outbox_operation.dart';

/// The offline write queue. Callers enqueue inside the same database
/// transaction as the entity write (decision 0007).
abstract interface class OutboxRepository {
  /// Adds [operation] unless an operation with the same ID exists.
  /// Returns whether it was added.
  Future<bool> enqueue(OutboxOperation operation);

  /// Pending operations due at [now], oldest first.
  Future<List<OutboxOperation>> due(DateTime now, {int limit = 50});

  /// The earliest time a pending operation becomes due, or `null`.
  Future<DateTime?> nextDueAt();

  /// Removes the sent operation and runs [onSent] (for example marking the
  /// entity synced) in the same transaction.
  Future<void> complete(String id, {Future<void> Function()? onSent});

  Future<void> scheduleRetry(
    String id, {
    required int attempts,
    required DateTime nextAttemptAt,
    required String error,
  });

  Future<void> markRejected(String id, {required String error});

  /// Makes every operation due now, for "sync now" and after sign-in.
  Future<void> resetBackoff(DateTime now);

  Stream<OutboxSummary> watchSummary();

  Future<OutboxSummary> summary();

  Future<void> deleteAll();
}
