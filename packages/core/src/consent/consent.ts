import { ConsentRequiredError, ValidationError } from '../errors.js';
import { compareZonedTimestamps, type ZonedTimestamp } from '../time/zonedTimestamp.js';
import {
  EXTERNAL_DATA_SOURCES,
  isExternalDataSourceId,
  type ExternalDataSourceId,
} from './dataSources.js';

/**
 * What a consent decision is about. `health_data` decisions name one external
 * source and its scopes; the other types are single switches without scopes.
 */
export const CONSENT_TYPES = ['health_data', 'device_usage', 'notifications', 'analytics'] as const;
export type ConsentType = (typeof CONSENT_TYPES)[number];

export function isConsentType(value: unknown): value is ConsentType {
  return typeof value === 'string' && (CONSENT_TYPES as readonly string[]).includes(value);
}

/**
 * Bump when the consent text shown to users changes materially. Consent given
 * under an older version is no longer active and must be requested again.
 * Kept for health data, the first consent type.
 */
export const CURRENT_CONSENT_POLICY_VERSION = '2026-11-26';

/** Current consent text version per type, so changing one text does not invalidate the others. */
export const CURRENT_CONSENT_POLICY_VERSIONS: Readonly<Record<ConsentType, string>> = {
  health_data: CURRENT_CONSENT_POLICY_VERSION,
  device_usage: '2026-11-28',
  notifications: '2026-11-28',
  analytics: '2026-11-28',
};

export type ConsentState = 'granted' | 'revoked';

/** One immutable entry in the append-only consent log. */
export interface ConsentDecision {
  readonly id: string;
  readonly type: ConsentType;
  /** The external source for `health_data`; `null` for the other types. */
  readonly sourceId: ExternalDataSourceId | null;
  readonly state: ConsentState;
  /** Scopes granted by this decision. Empty for revocations and for types without scopes. */
  readonly scopes: readonly string[];
  readonly policyVersion: string;
  readonly decidedAt: ZonedTimestamp;
}

export interface NewConsentDecision {
  readonly id: string;
  /** Defaults to `health_data`, the only type that existed before consent types. */
  readonly type?: string;
  readonly sourceId?: string | null;
  readonly state: ConsentState;
  readonly scopes: readonly string[];
  readonly decidedAt: ZonedTimestamp;
  readonly policyVersion?: string;
}

export function createConsentDecision(input: NewConsentDecision): ConsentDecision {
  if (!input.id) {
    throw new ValidationError('id', 'Consent decision id is required.');
  }
  const type = input.type ?? 'health_data';
  if (!isConsentType(type)) {
    throw new ValidationError('type', `"${type}" is not a consent type.`);
  }
  if (input.state !== 'granted' && input.state !== 'revoked') {
    throw new ValidationError('state', `Unknown consent state "${String(input.state)}".`);
  }
  const scopes = [...new Set(input.scopes)].sort();
  const policyVersion = input.policyVersion ?? CURRENT_CONSENT_POLICY_VERSIONS[type];

  if (type !== 'health_data') {
    if (input.sourceId !== undefined && input.sourceId !== null) {
      throw new ValidationError('sourceId', `Consent type "${type}" is not tied to a data source.`);
    }
    if (scopes.length > 0) {
      throw new ValidationError('scopes', `Consent type "${type}" has no scopes.`);
    }
    return { id: input.id, type, sourceId: null, state: input.state, scopes, policyVersion, decidedAt: input.decidedAt };
  }

  if (!isExternalDataSourceId(input.sourceId)) {
    throw new ValidationError('sourceId', `"${String(input.sourceId)}" is not a declared external data source.`);
  }
  const allowed: readonly string[] = EXTERNAL_DATA_SOURCES[input.sourceId].scopes;
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
  } else if (scopes.length > 0) {
    throw new ValidationError('scopes', 'A revocation withdraws all scopes and must not list any.');
  }

  return {
    id: input.id,
    type,
    sourceId: input.sourceId,
    state: input.state,
    scopes,
    policyVersion,
    decidedAt: input.decidedAt,
  };
}

/** The most recent decision of a type (and source, for `health_data`), or `undefined` if the user was never asked. */
export function latestConsentDecisionFor(
  log: readonly ConsentDecision[],
  type: ConsentType,
  sourceId: ExternalDataSourceId | null = null,
): ConsentDecision | undefined {
  let latest: ConsentDecision | undefined;
  for (const decision of log) {
    if (decision.type !== type || decision.sourceId !== sourceId) continue;
    if (!latest || compareZonedTimestamps(decision.decidedAt, latest.decidedAt) >= 0) {
      latest = decision;
    }
  }
  return latest;
}

/** The most recent health data decision for a source, or `undefined` if the user was never asked. */
export function latestConsentDecision(
  log: readonly ConsentDecision[],
  sourceId: ExternalDataSourceId,
): ConsentDecision | undefined {
  return latestConsentDecisionFor(log, 'health_data', sourceId);
}

export function hasActiveConsent(
  log: readonly ConsentDecision[],
  sourceId: ExternalDataSourceId,
  scope: string,
  policyVersion: string = CURRENT_CONSENT_POLICY_VERSIONS.health_data,
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
  policyVersion: string = CURRENT_CONSENT_POLICY_VERSIONS.health_data,
): void {
  if (!hasActiveConsent(log, sourceId, scope, policyVersion)) {
    throw new ConsentRequiredError(sourceId, scope);
  }
}

export type ConsentStatus = 'granted' | 'revoked' | 'not_asked' | 'outdated';

/**
 * `outdated` means the latest decision is a grant under an older policy
 * version: the user must be asked again before the feature may run.
 */
export function consentStatus(
  log: readonly ConsentDecision[],
  type: ConsentType,
  sourceId: ExternalDataSourceId | null = null,
): ConsentStatus {
  const latest = latestConsentDecisionFor(log, type, sourceId);
  if (!latest) return 'not_asked';
  if (latest.state === 'revoked') return 'revoked';
  return latest.policyVersion === CURRENT_CONSENT_POLICY_VERSIONS[type] ? 'granted' : 'outdated';
}

/** Call before any feature that depends on a consent type without a source (device usage, notifications, analytics). */
export function assertTypeConsent(log: readonly ConsentDecision[], type: Exclude<ConsentType, 'health_data'>): void {
  if (consentStatus(log, type) !== 'granted') {
    throw new ConsentRequiredError(type);
  }
}
