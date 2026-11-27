import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { createZonedTimestamp, isMissingReason, isPresent, missing, present } from '../src/index.js';

describe('Measurement', () => {
  const recordedAt = createZonedTimestamp('2026-11-26T07:00:00Z', 'Europe/Budapest');

  it('represents present values with their source and time', () => {
    const value = present(3, 'manual_check_in', recordedAt);
    assert.equal(isPresent(value), true);
    assert.deepEqual(value, { status: 'present', value: 3, source: 'manual_check_in', recordedAt });
  });

  it('represents missing values with an explicit reason and no value', () => {
    const value = missing('not_yet_synced');
    assert.equal(isPresent(value), false);
    assert.deepEqual(value, { status: 'missing', reason: 'not_yet_synced' });
    assert.equal('value' in value, false);
  });

  it('recognizes only declared missing reasons', () => {
    assert.equal(isMissingReason('no_consent'), true);
    assert.equal(isMissingReason('zero'), false);
    assert.equal(isMissingReason(undefined), false);
  });
});
