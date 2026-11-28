import 'dart:math';

import '../errors/app_failure.dart';
import '../errors/error_mapper.dart';
import 'outbox_operation.dart';
import 'outbox_repository.dart';

/// Sends one kind of queued operation to the API.
abstract interface class SyncHandler {
  /// The [OutboxOperation.kind] this handler sends.
  String get kind;

  /// Sends [operation]. The API must treat a repeated operation ID as a
  /// replay (rule 7). Throws on failure.
  Future<void> send(OutboxOperation operation);

  /// Records that [operation] reached the server, for example by setting
  /// the entity's `synced_at`. Runs in the transaction that removes the
  /// operation from the queue.
  Future<void> markSent(OutboxOperation operation);
}

/// A feature whose data was written while sync was off. When sync turns on
/// it enqueues what the server does not have yet.
abstract interface class SyncParticipant {
  Future<void> prepareForSync();
}

enum SyncStop {
  /// Every due operation was handled.
  completed,

  /// Sync is off: the user is not signed in.
  disabled,

  /// The session ended; operations wait until the user signs in again.
  needsSignIn,

  /// Offline, rate limited or a server error; retried with backoff.
  willRetry,
}

class SyncReport {
  const SyncReport({
    required this.stop,
    this.sent = 0,
    this.rejected = 0,
    this.failure,
  });

  final SyncStop stop;
  final int sent;
  final int rejected;

  /// Why the run stopped early, when it did.
  final AppFailure? failure;

  @override
  String toString() =>
      'SyncReport(${stop.name}, sent: $sent, rejected: $rejected)';
}

/// Drains the outbox oldest first (decision 0015).
class SyncService {
  SyncService({
    required this._outbox,
    required Iterable<SyncHandler> handlers,
    required this._isEnabled,
    DateTime Function()? now,
    this.baseBackoff = const Duration(seconds: 30),
    this.maxBackoff = const Duration(hours: 1),
  }) : _handlers = {for (final handler in handlers) handler.kind: handler},
       _now = now ?? (() => DateTime.now().toUtc());

  final OutboxRepository _outbox;
  final Map<String, SyncHandler> _handlers;
  final bool Function() _isEnabled;
  final DateTime Function() _now;
  final Duration baseBackoff;
  final Duration maxBackoff;

  Future<SyncReport>? _running;

  /// Runs one sync pass. Concurrent calls share the pass in progress, so an
  /// operation is never sent twice at the same time.
  Future<SyncReport> syncNow() =>
      _running ??= _run().whenComplete(() => _running = null);

  /// Delay before attempt number [attempts] + 1: doubles from [baseBackoff]
  /// up to [maxBackoff].
  Duration backoffAfter(int attempts) {
    final factor = pow(2, max(0, attempts - 1)).toInt();
    final delay = baseBackoff * factor;
    return delay > maxBackoff || delay.isNegative ? maxBackoff : delay;
  }

  Future<SyncReport> _run() async {
    if (!_isEnabled()) return const SyncReport(stop: SyncStop.disabled);
    var sent = 0;
    var rejected = 0;
    while (true) {
      final batch = await _outbox.due(_now());
      if (batch.isEmpty) break;
      for (final operation in batch) {
        if (!_isEnabled()) {
          return SyncReport(
            stop: SyncStop.disabled,
            sent: sent,
            rejected: rejected,
          );
        }
        final handler = _handlers[operation.kind];
        if (handler == null) {
          await _outbox.markRejected(operation.id, error: 'unknown_kind');
          rejected += 1;
          continue;
        }
        try {
          await handler.send(operation);
        } catch (error) {
          final failure = mapError(error);
          switch (failure) {
            case NotSignedInFailure() ||
                UnauthorizedFailure() ||
                NotConfiguredFailure():
              return SyncReport(
                stop: SyncStop.needsSignIn,
                sent: sent,
                rejected: rejected,
                failure: failure,
              );
            case ValidationFailure() ||
                ConflictFailure() ||
                ForbiddenFailure() ||
                ConsentRequiredFailure() ||
                NotFoundFailure():
              await _outbox.markRejected(
                operation.id,
                error: failureCode(failure),
              );
              rejected += 1;
              continue;
            case NetworkFailure() ||
                RateLimitedFailure() ||
                ServerFailure() ||
                StorageFailure() ||
                UnknownFailure():
              final attempts = operation.attempts + 1;
              final retryAfter = failure is RateLimitedFailure
                  ? failure.retryAfter
                  : null;
              await _outbox.scheduleRetry(
                operation.id,
                attempts: attempts,
                nextAttemptAt: _now().add(retryAfter ?? backoffAfter(attempts)),
                error: failureCode(failure),
              );
              // Keep the order: later operations wait for this one.
              return SyncReport(
                stop: SyncStop.willRetry,
                sent: sent,
                rejected: rejected,
                failure: failure,
              );
          }
        }
        await _outbox.complete(
          operation.id,
          onSent: () => handler.markSent(operation),
        );
        sent += 1;
      }
    }
    return SyncReport(stop: SyncStop.completed, sent: sent, rejected: rejected);
  }
}
