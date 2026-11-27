import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { ValidationError } from '@flowwave/core';
import { ANALYTICS_ENGINE_VERSION, calculationMetadata, inputCoverage } from '../src/index.js';

describe('inputCoverage', () => {
  it('computes the share of expected inputs that were present', () => {
    assert.deepEqual(inputCoverage(3, 4), { expected: 4, present: 3, ratio: 0.75 });
    assert.equal(inputCoverage(0, 48).ratio, 0);
  });

  it('rejects impossible counts', () => {
    assert.throws(() => inputCoverage(1, 0), ValidationError);
    assert.throws(() => inputCoverage(5, 4), ValidationError);
    assert.throws(() => inputCoverage(-1, 4), ValidationError);
    assert.throws(() => inputCoverage(1.5, 4), ValidationError);
  });
});

describe('calculationMetadata', () => {
  const valid = {
    calculationVersion: ANALYTICS_ENGINE_VERSION,
    inputCoverage: inputCoverage(2, 3),
    explanation: 'Based on 2 of 3 expected inputs.',
    limitations: ['Sleep data was not available.'],
  };

  it('accepts complete metadata', () => {
    assert.deepEqual(calculationMetadata(valid), valid);
  });

  it('requires a version, an explanation, and at least one limitation', () => {
    assert.throws(() => calculationMetadata({ ...valid, calculationVersion: 'v1' }), ValidationError);
    assert.throws(() => calculationMetadata({ ...valid, explanation: '  ' }), ValidationError);
    assert.throws(() => calculationMetadata({ ...valid, limitations: [] }), ValidationError);
    assert.throws(() => calculationMetadata({ ...valid, limitations: [''] }), ValidationError);
  });
});
