import { ValidationError } from '../errors.js';
import { isPresent, type Measurement, type MissingReason } from '../data/measurement.js';

/** Shown with every estimate. FlowWave scores are not medical assessments. */
export const ENERGY_ESTIMATE_DISCLAIMER =
  'This is a personal rhythm estimate based only on the inputs listed. ' +
  'It is not a medical assessment or diagnosis.';

export const SELF_REPORTED_ENERGY_MIN = 1;
export const SELF_REPORTED_ENERGY_MAX = 5;
export const SLEEP_GOAL_MINUTES_MIN = 180;
export const SLEEP_GOAL_MINUTES_MAX = 900;
const MINUTES_PER_DAY = 1440;

export interface EnergyEstimateInputs {
  /** User's own rating, integer 1–5. */
  readonly selfReportedEnergy: Measurement<number>;
  /** Duration of the most recent main sleep, in minutes. */
  readonly sleepDurationMinutes: Measurement<number>;
}

export interface EnergyEstimateSettings {
  /** The user's own sleep goal; sleep is compared to this, not to a clinical norm. */
  readonly sleepGoalMinutes: number;
}

export type EnergyFactorId = 'self_reported_energy' | 'sleep_vs_goal';

export const ENERGY_FACTOR_WEIGHTS: Readonly<Record<EnergyFactorId, number>> = {
  self_reported_energy: 0.6,
  sleep_vs_goal: 0.4,
};

export interface FactorExplanation {
  readonly factor: EnergyFactorId;
  readonly status: 'used' | 'missing';
  /** Configured weight of the factor. */
  readonly weight: number;
  /** Weight actually applied after excluding missing factors; 0 when missing. */
  readonly appliedWeight: number;
  /** Factor value scaled to 0–1, or `null` when missing. */
  readonly normalizedValue: number | null;
  /** Points this factor contributed to the 0–100 estimate, or `null` when missing. */
  readonly contributionPoints: number | null;
  readonly missingReason: MissingReason | null;
  readonly summary: string;
}

export type RecommendationId = 'deep_focus_block' | 'light_tasks' | 'recovery_break' | 'log_check_in';

export interface Recommendation {
  readonly id: RecommendationId;
  readonly title: string;
  /** Why this was suggested, in terms of the input factors. Always present. */
  readonly explanation: string;
  readonly basedOn: readonly EnergyFactorId[];
}

export type EnergyBand = 'higher' | 'moderate' | 'lower';

interface EstimateBase {
  readonly kind: 'energy_rhythm_estimate';
  readonly factors: readonly FactorExplanation[];
  readonly recommendation: Recommendation;
  readonly disclaimer: string;
}

export interface ScoredEnergyEstimate extends EstimateBase {
  readonly status: 'estimated';
  /** 0–100. */
  readonly score: number;
  readonly band: EnergyBand;
  readonly inputCoverage: 'all_inputs' | 'partial_inputs';
}

export interface InsufficientEnergyEstimate extends EstimateBase {
  readonly status: 'insufficient_data';
}

export type EnergyEstimate = ScoredEnergyEstimate | InsufficientEnergyEstimate;

const MISSING_REASON_TEXT: Readonly<Record<MissingReason, string>> = {
  not_recorded: 'not recorded',
  user_skipped: 'skipped',
  no_consent: 'not shared (no consent)',
  source_unavailable: 'source unavailable',
  not_yet_synced: 'not synced yet',
};

const FACTOR_LABEL: Readonly<Record<EnergyFactorId, string>> = {
  self_reported_energy: 'Self-reported energy',
  sleep_vs_goal: 'Sleep compared with your goal',
};

export function formatDuration(minutes: number): string {
  const total = Math.round(minutes);
  const hours = Math.floor(total / 60);
  const rest = total % 60;
  if (hours === 0) return `${rest} min`;
  return rest === 0 ? `${hours} h` : `${hours} h ${rest} min`;
}

function validate(inputs: EnergyEstimateInputs, settings: EnergyEstimateSettings): void {
  const goal = settings.sleepGoalMinutes;
  if (!Number.isFinite(goal) || goal < SLEEP_GOAL_MINUTES_MIN || goal > SLEEP_GOAL_MINUTES_MAX) {
    throw new ValidationError(
      'sleepGoalMinutes',
      `Must be between ${SLEEP_GOAL_MINUTES_MIN} and ${SLEEP_GOAL_MINUTES_MAX} minutes.`,
    );
  }
  const energy = inputs.selfReportedEnergy;
  if (
    isPresent(energy) &&
    !(
      Number.isInteger(energy.value) &&
      energy.value >= SELF_REPORTED_ENERGY_MIN &&
      energy.value <= SELF_REPORTED_ENERGY_MAX
    )
  ) {
    throw new ValidationError(
      'selfReportedEnergy',
      `Must be an integer from ${SELF_REPORTED_ENERGY_MIN} to ${SELF_REPORTED_ENERGY_MAX}.`,
    );
  }
  const sleep = inputs.sleepDurationMinutes;
  if (isPresent(sleep) && !(Number.isFinite(sleep.value) && sleep.value >= 0 && sleep.value <= MINUTES_PER_DAY)) {
    throw new ValidationError('sleepDurationMinutes', `Must be between 0 and ${MINUTES_PER_DAY} minutes.`);
  }
}

interface RawFactor {
  readonly factor: EnergyFactorId;
  readonly normalizedValue: number | null;
  readonly missingReason: MissingReason | null;
  readonly summary: string;
}

function rawFactors(inputs: EnergyEstimateInputs, settings: EnergyEstimateSettings): RawFactor[] {
  const energy = inputs.selfReportedEnergy;
  const sleep = inputs.sleepDurationMinutes;

  return [
    isPresent(energy)
      ? {
          factor: 'self_reported_energy',
          normalizedValue: (energy.value - SELF_REPORTED_ENERGY_MIN) / (SELF_REPORTED_ENERGY_MAX - SELF_REPORTED_ENERGY_MIN),
          missingReason: null,
          summary: `you rated your energy ${energy.value}/${SELF_REPORTED_ENERGY_MAX}`,
        }
      : {
          factor: 'self_reported_energy',
          normalizedValue: null,
          missingReason: energy.reason,
          summary: `${FACTOR_LABEL.self_reported_energy}: ${MISSING_REASON_TEXT[energy.reason]}`,
        },
    isPresent(sleep)
      ? {
          factor: 'sleep_vs_goal',
          normalizedValue: Math.min(sleep.value / settings.sleepGoalMinutes, 1),
          missingReason: null,
          summary:
            `you slept ${formatDuration(sleep.value)}, ` +
            `${Math.round((sleep.value / settings.sleepGoalMinutes) * 100)}% of your ${formatDuration(settings.sleepGoalMinutes)} goal`,
        }
      : {
          factor: 'sleep_vs_goal',
          normalizedValue: null,
          missingReason: sleep.reason,
          summary: `${FACTOR_LABEL.sleep_vs_goal}: ${MISSING_REASON_TEXT[sleep.reason]}`,
        },
  ];
}

function bandFor(score: number): EnergyBand {
  if (score >= 70) return 'higher';
  if (score >= 40) return 'moderate';
  return 'lower';
}

const BAND_RECOMMENDATION: Readonly<Record<EnergyBand, { id: RecommendationId; title: string; lead: string }>> = {
  higher: {
    id: 'deep_focus_block',
    title: 'Good moment for a focused work block',
    lead: 'Your estimate is in the higher part of the range',
  },
  moderate: {
    id: 'light_tasks',
    title: 'Consider lighter or routine tasks',
    lead: 'Your estimate is in the middle of the range',
  },
  lower: {
    id: 'recovery_break',
    title: 'Consider a short break before demanding work',
    lead: 'Your estimate is in the lower part of the range',
  },
};

/**
 * Combines the available inputs into a 0–100 personal rhythm estimate.
 * Missing inputs are excluded and reported, never replaced by assumed values.
 */
export function estimateEnergy(inputs: EnergyEstimateInputs, settings: EnergyEstimateSettings): EnergyEstimate {
  validate(inputs, settings);

  const raw = rawFactors(inputs, settings);
  const used = raw.filter((f) => f.normalizedValue !== null);
  const missingFactors = raw.filter((f) => f.normalizedValue === null);
  const missingNote =
    missingFactors.length > 0
      ? ` Not included: ${missingFactors.map((f) => f.summary).join('; ')}.`
      : '';

  if (used.length === 0) {
    const factors = raw.map<FactorExplanation>((f) => ({
      factor: f.factor,
      status: 'missing',
      weight: ENERGY_FACTOR_WEIGHTS[f.factor],
      appliedWeight: 0,
      normalizedValue: null,
      contributionPoints: null,
      missingReason: f.missingReason,
      summary: f.summary,
    }));
    return {
      kind: 'energy_rhythm_estimate',
      status: 'insufficient_data',
      factors,
      recommendation: {
        id: 'log_check_in',
        title: 'Add a quick check-in to get a suggestion',
        explanation: `No inputs are available, so no estimate was made.${missingNote}`,
        basedOn: [],
      },
      disclaimer: ENERGY_ESTIMATE_DISCLAIMER,
    };
  }

  const usedWeight = used.reduce((sum, f) => sum + ENERGY_FACTOR_WEIGHTS[f.factor], 0);
  const factors = raw.map<FactorExplanation>((f) => {
    const weight = ENERGY_FACTOR_WEIGHTS[f.factor];
    if (f.normalizedValue === null) {
      return {
        factor: f.factor,
        status: 'missing',
        weight,
        appliedWeight: 0,
        normalizedValue: null,
        contributionPoints: null,
        missingReason: f.missingReason,
        summary: f.summary,
      };
    }
    const appliedWeight = weight / usedWeight;
    return {
      factor: f.factor,
      status: 'used',
      weight,
      appliedWeight,
      normalizedValue: f.normalizedValue,
      contributionPoints: Math.round(appliedWeight * f.normalizedValue * 1000) / 10,
      missingReason: null,
      summary: f.summary,
    };
  });

  const score = Math.round(
    factors.reduce((sum, f) => sum + (f.normalizedValue === null ? 0 : f.appliedWeight * f.normalizedValue), 0) * 100,
  );
  const band = bandFor(score);
  const template = BAND_RECOMMENDATION[band];

  return {
    kind: 'energy_rhythm_estimate',
    status: 'estimated',
    score,
    band,
    inputCoverage: missingFactors.length === 0 ? 'all_inputs' : 'partial_inputs',
    factors,
    recommendation: {
      id: template.id,
      title: template.title,
      explanation: `${template.lead} (${score}/100) because ${used.map((f) => f.summary).join(' and ')}.${missingNote}`,
      basedOn: used.map((f) => f.factor),
    },
    disclaimer: ENERGY_ESTIMATE_DISCLAIMER,
  };
}
