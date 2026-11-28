import 'consent_decision.dart';

/// The consent log on this phone, the source of truth for what the user
/// allowed (decision 0015).
abstract interface class ConsentRepository {
  /// Every decision in recording order.
  Stream<List<ConsentDecision>> watchLog();

  Future<List<ConsentDecision>> log();

  /// Stores [decision] and, while sync is on, queues its upload in the same
  /// transaction. Recording the same decision again changes nothing.
  Future<void> record(ConsentDecision decision);

  /// Stores decisions the server already has (from another device), marked
  /// as synced. Existing IDs are left alone.
  Future<void> importConfirmed(List<ConsentDecision> decisions);

  /// Queues every decision the server does not have yet. Returns how many
  /// operations were added.
  Future<int> enqueueUnsynced();

  Future<void> markSynced(String id, DateTime at);

  /// Number of decisions not confirmed by the server yet.
  Stream<int> watchUnsyncedCount();

  Future<void> deleteAll();
}

/// The consent endpoints of the API.
abstract interface class ConsentRemoteDataSource {
  /// `POST /v1/consents` with [body] (a decision's JSON). Safe to repeat.
  Future<void> upload(Map<String, Object?> body);

  /// `GET /v1/consents/history`.
  Future<List<ConsentDecision>> history();
}
