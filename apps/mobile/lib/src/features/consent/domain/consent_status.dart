import 'consent_catalog.dart';
import 'consent_decision.dart';

/// The current state of one consent subject: a type, plus a source for
/// health data. Ported from `consentStatus` in `@flowwave/core` and checked
/// against the shared test vectors.
class ConsentSubjectState {
  const ConsentSubjectState({
    required this.type,
    required this.sourceId,
    required this.status,
    required this.scopes,
    this.latest,
  });

  final ConsentType type;
  final String? sourceId;
  final ConsentStatus status;

  /// Active scopes; empty unless [status] is granted.
  final List<String> scopes;

  /// The decision that determines the state, `null` when never asked.
  final ConsentDecision? latest;

  bool get isGranted => status == ConsentStatus.granted;
}

/// The most recent decision for the subject. [log] is in recording order;
/// for equal decision times the one recorded later wins.
ConsentDecision? latestConsentDecision(
  List<ConsentDecision> log,
  ConsentType type, {
  String? sourceId,
}) {
  ConsentDecision? latest;
  for (final decision in log) {
    if (decision.type != type || decision.sourceId != sourceId) continue;
    if (latest == null ||
        !decision.decidedAt.instant.isBefore(latest.decidedAt.instant)) {
      latest = decision;
    }
  }
  return latest;
}

ConsentSubjectState consentState(
  List<ConsentDecision> log,
  ConsentType type, {
  String? sourceId,
}) {
  final latest = latestConsentDecision(log, type, sourceId: sourceId);
  final ConsentStatus status;
  if (latest == null) {
    status = ConsentStatus.notAsked;
  } else if (latest.state == ConsentState.revoked) {
    status = ConsentStatus.revoked;
  } else if (latest.policyVersion == currentConsentPolicyVersions[type]) {
    status = ConsentStatus.granted;
  } else {
    status = ConsentStatus.outdated;
  }
  return ConsentSubjectState(
    type: type,
    sourceId: sourceId,
    status: status,
    scopes: status == ConsentStatus.granted ? latest!.scopes : const [],
    latest: latest,
  );
}
