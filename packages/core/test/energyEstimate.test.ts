import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  ENERGY_ESTIMATE_DISCLAIMER,
  ValidationError,
  createZonedTimestamp,
  estimateEnergy,
  formatDuration,
  missing,
  present,
  type EnergyEstimate,
} from '../src/index.js';

const recordedAt = createZonedTimestamp('2026-11-26T07:30:00Z', 'Europe/Budapest');
const energy = (value: number) => present(value, 'manual_check_in', recordedAt);
const sleep = (minutes: number) => present(minutes, 'manual_check_in', recordedAt);
const settings = { sleepGoalMinutes: 480 };

const MEDICAL_TERMS = /\b(diagnos(is|e|ed)|disorder|disease|symptom|clinical|patient|treatment|insomnia|depression|fatigue syndrome)\b/i;

function allText(estimate: EnergyEstimate): string {
  return [
    estimate.recommendation.title,
    estimate.recommendation.explanation,
    ...estimate.factors.map((f) => f.summary),
  ].join(' ');
}

describe('estimateEnergy', () => {
  it('combines all inputs and explains each factor', () => {
    const estimate = estimateEnergy({ selfReportedEnergy: energy(4), sleepDurationMinutes: sleep(432) }, settings);

    assert.equal(estimate.status, 'estimated');
    if (estimate.status !== 'estimated') return;
    // 0.6 * 0.75 + 0.4 * 0.9 = 0.81
    assert.equal(estimate.score, 81);
    assert.equal(estimate.band, 'higher');
    assert.equal(estimate.inputCoverage, 'all_inputs');
    assert.equal(estimate.recommendation.id, 'deep_focus_block');
    assert.deepEqual(estimate.recommendation.basedOn, ['self_reported_energy', 'sleep_vs_goal']);
    assert.match(estimate.recommendation.explanation, /rated your energy 4\/5/);
    assert.match(estimate.recommendation.explanation, /slept 7 h 12 min, 90% of your 8 h goal/);
    assert.deepEqual(
      estimate.factors.map((f) => [f.factor, f.status, f.contributionPoints]),
      [
        ['self_reported_energy', 'used', 45],
        ['sleep_vs_goal', 'used', 36],
      ],
    );
  });

  it('excludes missing inputs instead of assuming values, and says so', () => {
    const estimate = estimateEnergy(
      { selfReportedEnergy: energy(2), sleepDurationMinutes: missing('no_consent') },
      settings,
    );

    assert.equal(estimate.status, 'estimated');
    if (estimate.status !== 'estimated') return;
    assert.equal(estimate.score, 25);
    assert.equal(estimate.band, 'lower');
    assert.equal(estimate.inputCoverage, 'partial_inputs');
    assert.equal(estimate.recommendation.id, 'recovery_break');
    assert.deepEqual(estimate.recommendation.basedOn, ['self_reported_energy']);
    assert.match(estimate.recommendation.explanation, /Not included: Sleep compared with your goal: not shared \(no consent\)/);

    const sleepFactor = estimate.factors.find((f) => f.factor === 'sleep_vs_goal');
    assert.deepEqual(sleepFactor && {
      status: sleepFactor.status,
      appliedWeight: sleepFactor.appliedWeight,
      normalizedValue: sleepFactor.normalizedValue,
      contributionPoints: sleepFactor.contributionPoints,
      missingReason: sleepFactor.missingReason,
    }, {
      status: 'missing',
      appliedWeight: 0,
      normalizedValue: null,
      contributionPoints: null,
      missingReason: 'no_consent',
    });
  });

  it('returns insufficient_data with an explained prompt when nothing is available', () => {
    const estimate = estimateEnergy(
      { selfReportedEnergy: missing('user_skipped'), sleepDurationMinutes: missing('not_recorded') },
      settings,
    );
    assert.equal(estimate.status, 'insufficient_data');
    assert.equal('score' in estimate, false);
    assert.equal(estimate.recommendation.id, 'log_check_in');
    assert.match(estimate.recommendation.explanation, /Self-reported energy: skipped/);
    assert.match(estimate.recommendation.explanation, /Sleep compared with your goal: not recorded/);
  });

  it('places scores into bands with lighter tasks in the middle', () => {
    const estimate = estimateEnergy({ selfReportedEnergy: energy(3), sleepDurationMinutes: sleep(360) }, settings);
    assert.equal(estimate.status === 'estimated' && estimate.band, 'moderate');
    assert.equal(estimate.recommendation.id, 'light_tasks');
  });

  it('caps sleep at the personal goal so extra sleep does not exceed 100', () => {
    const estimate = estimateEnergy({ selfReportedEnergy: energy(5), sleepDurationMinutes: sleep(700) }, settings);
    assert.equal(estimate.status === 'estimated' && estimate.score, 100);
  });

  it('always carries the non-medical disclaimer and avoids medical wording', () => {
    const cases = [
      estimateEnergy({ selfReportedEnergy: energy(1), sleepDurationMinutes: sleep(0) }, settings),
      estimateEnergy({ selfReportedEnergy: energy(5), sleepDurationMinutes: sleep(480) }, settings),
      estimateEnergy({ selfReportedEnergy: missing('user_skipped'), sleepDurationMinutes: missing('not_recorded') }, settings),
    ];
    for (const estimate of cases) {
      assert.equal(estimate.kind, 'energy_rhythm_estimate');
      assert.equal(estimate.disclaimer, ENERGY_ESTIMATE_DISCLAIMER);
      assert.match(estimate.disclaimer, /not a medical assessment or diagnosis/);
      assert.doesNotMatch(allText(estimate), MEDICAL_TERMS);
      assert.ok(estimate.recommendation.explanation.length > 0);
    }
  });

  it('rejects out-of-range inputs rather than clamping them', () => {
    const bad = [
      () => estimateEnergy({ selfReportedEnergy: energy(0), sleepDurationMinutes: sleep(400) }, settings),
      () => estimateEnergy({ selfReportedEnergy: energy(3.5), sleepDurationMinutes: sleep(400) }, settings),
      () => estimateEnergy({ selfReportedEnergy: energy(3), sleepDurationMinutes: sleep(-5) }, settings),
      () => estimateEnergy({ selfReportedEnergy: energy(3), sleepDurationMinutes: sleep(1441) }, settings),
      () => estimateEnergy({ selfReportedEnergy: energy(3), sleepDurationMinutes: sleep(Number.NaN) }, settings),
      () => estimateEnergy({ selfReportedEnergy: energy(3), sleepDurationMinutes: sleep(400) }, { sleepGoalMinutes: 60 }),
    ];
    for (const run of bad) {
      assert.throws(run, ValidationError);
    }
  });
});

describe('formatDuration', () => {
  it('formats minutes for explanations', () => {
    assert.equal(formatDuration(45), '45 min');
    assert.equal(formatDuration(480), '8 h');
    assert.equal(formatDuration(432), '7 h 12 min');
  });
});
