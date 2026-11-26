import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  CURRENT_CONSENT_POLICY_VERSION,
  ConsentRequiredError,
  ValidationError,
  assertConsent,
  createConsentDecision,
  createZonedTimestamp,
  hasActiveConsent,
  isDataSourceId,
  isExternalDataSourceId,
  latestConsentDecision,
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
    assert.throws(() => grant('c1', '2026-11-26T10:00:00Z', { scopes: ['heart_rate'] }), ValidationError);
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
