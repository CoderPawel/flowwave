import { ValidationError } from '@flowwave/core';

/** Version of this package's calculation rules; bumped whenever a formula or threshold changes. */
export const ANALYTICS_ENGINE_VERSION = '0.1.0';

const SEMVER = /^\d+\.\d+\.\d+$/;

/** How many of the expected inputs were actually present for a calculation. */
export interface InputCoverage {
  readonly expected: number;
  readonly present: number;
  /** `present / expected`, from 0 to 1. */
  readonly ratio: number;
}

/**
 * Metadata every analytics output must carry: which calculation produced it,
 * how complete its inputs were, why it says what it says, and what it cannot tell.
 */
export interface CalculationMetadata {
  readonly calculationVersion: string;
  readonly inputCoverage: InputCoverage;
  readonly explanation: string;
  readonly limitations: readonly string[];
}

export function inputCoverage(present: number, expected: number): InputCoverage {
  if (!Number.isInteger(expected) || expected <= 0) {
    throw new ValidationError('expected', 'Must be a positive integer.');
  }
  if (!Number.isInteger(present) || present < 0 || present > expected) {
    throw new ValidationError('present', `Must be an integer from 0 to ${expected}.`);
  }
  return { expected, present, ratio: present / expected };
}

export function calculationMetadata(input: {
  readonly calculationVersion: string;
  readonly inputCoverage: InputCoverage;
  readonly explanation: string;
  readonly limitations: readonly string[];
}): CalculationMetadata {
  if (!SEMVER.test(input.calculationVersion)) {
    throw new ValidationError('calculationVersion', 'Must be a semantic version like 1.0.0.');
  }
  if (input.explanation.trim().length === 0) {
    throw new ValidationError('explanation', 'Every output must explain itself.');
  }
  if (input.limitations.length === 0 || input.limitations.some((item) => item.trim().length === 0)) {
    throw new ValidationError('limitations', 'Every output must state at least one non-empty limitation.');
  }
  return {
    calculationVersion: input.calculationVersion,
    inputCoverage: input.inputCoverage,
    explanation: input.explanation,
    limitations: [...input.limitations],
  };
}
