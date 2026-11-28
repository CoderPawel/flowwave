import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { describe, it } from 'node:test';
import {
  CURRENT_CONSENT_POLICY_VERSIONS,
  EXTERNAL_DATA_SOURCES,
  consentStatus,
  createConsentDecision,
  latestConsentDecisionFor,
  type ConsentDecision,
  type ConsentType,
  type ExternalDataSourceId,
  type NewConsentDecision,
} from '../src/index.js';

interface ConsentVectors {
  readonly currentPolicyVersions: Record<string, string>;
  readonly healthDataSources: Record<string, string[]>;
  readonly cases: ReadonlyArray<{
    readonly name: string;
    readonly subject: { readonly type: ConsentType; readonly sourceId: ExternalDataSourceId | null };
    readonly log: NewConsentDecision[];
    readonly expected: { readonly status: string; readonly scopes: string[] };
  }>;
}

// Compiled tests run from dist/test; the vectors stay next to the sources.
const vectors = JSON.parse(
  readFileSync(new URL('../../test-vectors/consent-status.json', import.meta.url), 'utf8'),
) as ConsentVectors;

describe('shared consent vectors (also checked by the Flutter app)', () => {
  it('list the current consent text versions', () => {
    assert.deepEqual(vectors.currentPolicyVersions, CURRENT_CONSENT_POLICY_VERSIONS);
  });

  it('list the health data sources and their scopes', () => {
    const sources = Object.fromEntries(
      Object.entries(EXTERNAL_DATA_SOURCES).map(([id, definition]) => [id, [...definition.scopes]]),
    );
    assert.deepEqual(vectors.healthDataSources, sources);
  });

  for (const vector of vectors.cases) {
    it(vector.name, () => {
      const log: ConsentDecision[] = vector.log.map((entry) => createConsentDecision(entry));
      const { type, sourceId } = vector.subject;
      const status = consentStatus(log, type, sourceId);
      const latest = latestConsentDecisionFor(log, type, sourceId);
      assert.equal(status, vector.expected.status);
      assert.deepEqual(status === 'granted' && latest ? [...latest.scopes] : [], vector.expected.scopes);
    });
  }
});
