import { ConsentRequiredError, ValidationError } from '../errors.js';
import { compareZonedTimestamps, type ZonedTimestamp } from '../time/zonedTimestamp.js';
import {
  EXTERNAL_DATA_SOURCES,
  isExternalDataSourceId,
  type ExternalDataSourceId,
} from './dataSources.js';

/**
 * Bump when the consent text shown to users changes materially. Consent given
 * under an older version is no longer active and must be requested again.
 */
export const CURRENT_CONSENT_POLICY_VERSION = '2026-11-26';

export type ConsentState = 'granted' | 'revoked';

/** One immutable entry in the append-only consent log. */
export interface ConsentDecision {
  readonly id: string;
  readonly sourceId: ExternalDataSourceId;
  readonly state: ConsentState;
  /** Scopes granted by this decision. Empty for revocations. */
  readonly scopes: readonly string[];
  readonly policyVersion: string;
  readonly decidedAt: ZonedTimestamp;
}

export interface NewConsentDecision {
  readonly id: string;
  readonly sourceId: string;
  readonly state: ConsentState;
  readonly scopes: readonly string[];
  readonly decidedAt: ZonedTimestamp;
  readonly policyVersion?: string;
}

export function createConsentDecision(input: NewConsentDecision): ConsentDecision {
  if (!input.id) {
    throw new ValidationError('id', 'Consent decision id is required.');
  }
  if (!isExternalDataSourceId(input.sourceId)) {
    throw new ValidationError('sourceId', `"${input.sourceId}" is not a declared external data source.`);
  }
  const allowed: readonly string[] = EXTERNAL_DATA_SOURCES[input.sourceId].scopes;
  const scopes = [...new Set(input.scopes)].sort();

  if (input.state === 'granted') {
    if (scopes.length === 0) {
      throw new ValidationError('scopes', 'Granting consent requires at least one scope.');
    }
    const unknown = scopes.filter((scope) => !allowed.includes(scope));
    if (unknown.length > 0) {
      throw new ValidationError(
        'scopes',
        `Scopes not offered by "${input.sourceId}": ${unknown.join(', ')}.`,
      );
    }
  } else if (input.state === 'revoked') {
    if (scopes.length > 0) {
      throw new ValidationError('scopes', 'A revocation withdraws all scopes and must not list any.');
    }
  } else {
    throw new ValidationError('state', `Unknown consent state "${String(input.state)}".`);
  }

  return {
    id: input.id,
    sourceId: input.sourceId,
    state: input.state,
    scopes,
    policyVersion: input.policyVersion ?? CURRENT_CONSENT_POLICY_VERSION,
    decidedAt: input.decidedAt,
  };
}

/** The most recent decision for a source, or `undefined` if the user was never asked. */
export function latestConsentDecision(
  log: readonly ConsentDecision[],
  sourceId: ExternalDataSourceId,
): ConsentDecision | undefined {
  let latest: ConsentDecision | undefined;
  for (const decision of log) {
    if (decision.sourceId !== sourceId) continue;
    if (!latest || compareZonedTimestamps(decision.decidedAt, latest.decidedAt) >= 0) {
      latest = decision;
    }
  }
  return latest;
}

export function hasActiveConsent(
  log: readonly ConsentDecision[],
  sourceId: ExternalDataSourceId,
  scope: string,
  policyVersion: string = CURRENT_CONSENT_POLICY_VERSION,
): boolean {
  const latest = latestConsentDecision(log, sourceId);
  return (
    latest !== undefined &&
    latest.state === 'granted' &&
    latest.policyVersion === policyVersion &&
    latest.scopes.includes(scope)
  );
}

/** Call before reading any data from an external source. */
export function assertConsent(
  log: readonly ConsentDecision[],
  sourceId: ExternalDataSourceId,
  scope: string,
  policyVersion: string = CURRENT_CONSENT_POLICY_VERSION,
): void {
  if (!hasActiveConsent(log, sourceId, scope, policyVersion)) {
    throw new ConsentRequiredError(sourceId, scope);
  }
}
