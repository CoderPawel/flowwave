import 'dart:async';

import '../errors/error_mapper.dart';
import 'outbox_operation.dart';
import 'outbox_repository.dart';
import 'sync_service.dart';

/// Decides when [SyncService] runs while the app is open: after something is
/// enqueued, when sync turns on, when the app returns to the foreground, and
/// when a retry becomes due (decision 0015). Background sync arrives with
/// roadmap step 10.
class SyncScheduler {
  SyncScheduler({
    required this._service,
    required this._outbox,
    required Iterable<SyncParticipant> participants,
    DateTime Function()? now,
  }) : _participants = List.unmodifiable(participants),
       _now = now ?? (() => DateTime.now().toUtc());

  final SyncService _service;
  final OutboxRepository _outbox;
  final List<SyncParticipant> _participants;
  final DateTime Function() _now;

  StreamSubscription<OutboxSummary>? _summaries;
  Timer? _retryTimer;
  bool _disposed = false;
  int _lastPending = 0;

  void start() {
    _summaries ??= _outbox.watchSummary().listen((summary) {
      final grew = summary.pending > _lastPending;
      _lastPending = summary.pending;
      if (grew) unawaited(run());
    });
    unawaited(run());
  }

  /// Sync just turned on (the user signed in): queue what the server does
  /// not have yet and send it without waiting for backoff.
  Future<SyncReport> onSyncEnabled() => _guard(() async {
    for (final participant in _participants) {
      await participant.prepareForSync();
    }
    await _outbox.resetBackoff(_now());
    return run();
  });

  /// The user asked to sync now.
  Future<SyncReport> syncNow() => _guard(() async {
    await _outbox.resetBackoff(_now());
    return run();
  });

  void onAppResumed() => unawaited(run());

  /// Never throws: callers trigger it without waiting for the result.
  Future<SyncReport> run() => _guard(() async {
    if (_disposed) return const SyncReport(stop: SyncStop.disabled);
    final report = await _service.syncNow();
    await _scheduleRetry();
    return report;
  });

  Future<SyncReport> _guard(Future<SyncReport> Function() body) async {
    if (_disposed) return const SyncReport(stop: SyncStop.disabled);
    try {
      return await body();
    } catch (error) {
      if (_disposed) return const SyncReport(stop: SyncStop.disabled);
      return SyncReport(stop: SyncStop.willRetry, failure: mapError(error));
    }
  }

  Future<void> _scheduleRetry() async {
    _retryTimer?.cancel();
    _retryTimer = null;
    if (_disposed) return;
    final next = await _outbox.nextDueAt();
    if (next == null || _disposed) return;
    final wait = next.difference(_now());
    if (wait <= Duration.zero) return;
    _retryTimer = Timer(wait, () => unawaited(run()));
  }

  Future<void> dispose() async {
    _disposed = true;
    _retryTimer?.cancel();
    await _summaries?.cancel();
  }
}
