import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  CURRENT_CONSENT_POLICY_VERSION,
  CURRENT_CONSENT_POLICY_VERSIONS,
  ConsentRequiredError,
  ValidationError,
  assertConsent,
  assertTypeConsent,
  consentStatus,
  createConsentDecision,
  createZonedTimestamp,
  hasActiveConsent,
  isDataSourceId,
  isExternalDataSourceId,
  latestConsentDecision,
  latestConsentDecisionFor,
  type ConsentDecision,
} from '../src/index.js';

const at = (iso: string) => createZonedTimestamp(iso, 'Europe/Budapest');

const grant = (id: string, iso: string, extra: Partial<Parameters<typeof createConsentDecision>[0]> = {}) =>
  createConsentDecision({
    id,
    sourceId: 'apple_health',
    state: 'granted',
    scopes: ['sleep_duration'],
    decidedAt: at(iso),
    ...extra,
  });

const revoke = (id: string, iso: string) =>
  createConsentDecision({ id, sourceId: 'apple_health', state: 'revoked', scopes: [], decidedAt: at(iso) });

describe('data sources', () => {
  it('distinguishes internal and external sources', () => {
    assert.equal(isExternalDataSourceId('apple_health'), true);
    assert.equal(isExternalDataSourceId('manual_check_in'), false);
    assert.equal(isDataSourceId('manual_check_in'), true);
    assert.equal(isDataSourceId('toString'), false);
    assert.equal(isDataSourceId('browser_history'), false);
  });
});

describe('createConsentDecision', () => {
  it('normalizes scopes and stamps the current policy version', () => {
    const decision = grant('c1', '2026-11-26T10:00:00Z', { scopes: ['sleep_duration', 'sleep_duration'] });
    assert.deepEqual(decision.scopes, ['sleep_duration']);
    assert.equal(decision.policyVersion, CURRENT_CONSENT_POLICY_VERSION);
  });

  it('rejects undeclared sources and scopes', () => {
    assert.throws(() => grant('c1', '2026-11-26T10:00:00Z', { sourceId: 'browser_history' }), ValidationError);
    assert.throws(() => grant('c1', '2026-11-26T10:00:00Z', { scopes: ['blood_glucose'] }), ValidationError);
  });

  it('rejects empty grants, scoped revocations, and missing ids', () => {
    assert.throws(() => grant('c1', '2026-11-26T10:00:00Z', { scopes: [] }), ValidationError);
    assert.throws(
      () =>
        createConsentDecision({
          id: 'c2',
          sourceId: 'apple_health',
          state: 'revoked',
          scopes: ['sleep_duration'],
          decidedAt: at('2026-11-26T10:00:00Z'),
        }),
      ValidationError,
    );
    assert.throws(() => grant('', '2026-11-26T10:00:00Z'), ValidationError);
  });
});

describe('active consent', () => {
  it('is absent when the user was never asked', () => {
    assert.equal(hasActiveConsent([], 'apple_health', 'sleep_duration'), false);
    assert.throws(() => assertConsent([], 'apple_health', 'sleep_duration'), ConsentRequiredError);
  });

  it('follows the latest decision by instant, not by log order', () => {
    const log: ConsentDecision[] = [revoke('c2', '2026-11-26T12:00:00Z'), grant('c1', '2026-11-26T10:00:00Z')];
    assert.equal(latestConsentDecision(log, 'apple_health')?.id, 'c2');
    assert.equal(hasActiveConsent(log, 'apple_health', 'sleep_duration'), false);

    const regranted = [...log, grant('c3', '2026-11-26T14:00:00Z')];
    assert.equal(hasActiveConsent(regranted, 'apple_health', 'sleep_duration'), true);
    assert.doesNotThrow(() => assertConsent(regranted, 'apple_health', 'sleep_duration'));
  });

  it('is scoped per source', () => {
    const log = [grant('c1', '2026-11-26T10:00:00Z')];
    assert.equal(hasActiveConsent(log, 'health_connect', 'sleep_duration'), false);
  });

  it('expires when the consent policy version changes', () => {
    const log = [grant('c1', '2026-11-26T10:00:00Z', { policyVersion: '2025-01-01' })];
    assert.equal(hasActiveConsent(log, 'apple_health', 'sleep_duration'), false);
    assert.equal(hasActiveConsent(log, 'apple_health', 'sleep_duration', '2025-01-01'), true);
  });
});

describe('consent types', () => {
  const decide = (id: string, type: string, state: 'granted' | 'revoked', iso: string, extra: object = {}) =>
    createConsentDecision({ id, type, state, scopes: [], decidedAt: at(iso), ...extra });

  it('keeps existing source decisions as health data', () => {
    const decision = grant('c1', '2026-11-26T10:00:00Z');
    assert.equal(decision.type, 'health_data');
    assert.equal(decision.sourceId, 'apple_health');
  });

  it('stamps the current version of each type', () => {
    for (const type of ['device_usage', 'notifications', 'analytics'] as const) {
      assert.equal(decide('c1', type, 'granted', '2026-11-28T10:00:00Z').policyVersion, CURRENT_CONSENT_POLICY_VERSIONS[type]);
    }
  });

  it('rejects unknown types, sources on switch types, and scopes on switch types', () => {
    assert.throws(() => decide('c1', 'location', 'granted', '2026-11-28T10:00:00Z'), ValidationError);
    assert.throws(() => decide('c1', 'analytics', 'granted', '2026-11-28T10:00:00Z', { sourceId: 'health_connect' }), ValidationError);
    assert.throws(() => decide('c1', 'notifications', 'granted', '2026-11-28T10:00:00Z', { scopes: ['daily'] }), ValidationError);
    assert.throws(() => decide('c1', 'health_data', 'granted', '2026-11-28T10:00:00Z', { scopes: ['steps'] }), ValidationError);
  });

  it('keeps each type independent', () => {
    const log = [decide('c1', 'device_usage', 'granted', '2026-11-28T10:00:00Z'), decide('c2', 'analytics', 'revoked', '2026-11-28T11:00:00Z')];
    assert.equal(consentStatus(log, 'device_usage'), 'granted');
    assert.equal(consentStatus(log, 'analytics'), 'revoked');
    assert.equal(consentStatus(log, 'notifications'), 'not_asked');
    assert.equal(consentStatus(log, 'health_data', 'health_connect'), 'not_asked');
    assert.equal(latestConsentDecisionFor(log, 'device_usage')?.id, 'c1');
  });

  it('stops counting a consent after withdrawal, and counts a new grant again', () => {
    const granted = [decide('c1', 'device_usage', 'granted', '2026-11-28T10:00:00Z')];
    assert.doesNotThrow(() => assertTypeConsent(granted, 'device_usage'));

    const withdrawn = [...granted, decide('c2', 'device_usage', 'revoked', '2026-11-28T12:00:00Z')];
    assert.equal(consentStatus(withdrawn, 'device_usage'), 'revoked');
    assert.throws(() => assertTypeConsent(withdrawn, 'device_usage'), (error: unknown) => {
      assert.ok(error instanceof ConsentRequiredError);
      assert.equal(error.subject, 'device_usage');
      assert.equal(error.scope, undefined);
      return true;
    });

    const regranted = [...withdrawn, decide('c3', 'device_usage', 'granted', '2026-11-28T14:00:00Z')];
    assert.equal(consentStatus(regranted, 'device_usage'), 'granted');
  });

  it('reports grants under an older policy version as outdated', () => {
    const log = [decide('c1', 'notifications', 'granted', '2026-11-28T10:00:00Z', { policyVersion: '2025-01-01' })];
    assert.equal(consentStatus(log, 'notifications'), 'outdated');
    assert.throws(() => assertTypeConsent(log, 'notifications'), ConsentRequiredError);
  });

  it('withdrawing health data for one source keeps the other source', () => {
    const log = [
      grant('c1', '2026-11-26T10:00:00Z'),
      grant('c2', '2026-11-26T10:00:00Z', { sourceId: 'health_connect', scopes: ['steps', 'heart_rate'] }),
      createConsentDecision({ id: 'c3', sourceId: 'health_connect', state: 'revoked', scopes: [], decidedAt: at('2026-11-26T12:00:00Z') }),
    ];
    assert.equal(hasActiveConsent(log, 'apple_health', 'sleep_duration'), true);
    assert.equal(hasActiveConsent(log, 'health_connect', 'steps'), false);
    assert.equal(consentStatus(log, 'health_data', 'health_connect'), 'revoked');
  });
});
