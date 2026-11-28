import 'dart:convert';

import '../../../core/errors/app_failure.dart';
import '../../../core/sync/outbox_operation.dart';
import '../../../core/sync/sync_service.dart';
import '../domain/consent_repository.dart';
import 'drift_consent_repository.dart';

/// Uploads consent decisions and, when sync turns on, merges the server's
/// history so decisions made on another device show here too.
class ConsentSyncHandler implements SyncHandler, SyncParticipant {
  ConsentSyncHandler({
    required this._repository,
    required this._remote,
    DateTime Function()? now,
  }) : _now = now ?? (() => DateTime.now().toUtc());

  final ConsentRepository _repository;
  final ConsentRemoteDataSource _remote;
  final DateTime Function() _now;

  @override
  String get kind => consentDecisionOperationKind;

  @override
  Future<void> send(OutboxOperation operation) =>
      _remote.upload(jsonDecode(operation.payload) as Map<String, Object?>);

  @override
  Future<void> markSent(OutboxOperation operation) =>
      _repository.markSynced(operation.id, _now());

  @override
  Future<void> prepareForSync() async {
    try {
      await _repository.importConfirmed(await _remote.history());
    } on AppFailure {
      // Offline or not configured: the local decisions are still queued
      // below, and the history is merged on the next sign-in.
    }
    await _repository.enqueueUnsynced();
  }
}
