export type FlowWaveErrorCode =
  | 'validation_failed'
  | 'consent_required'
  | 'forbidden_data'
  | 'idempotency_conflict';

export abstract class FlowWaveError extends Error {
  abstract readonly code: FlowWaveErrorCode;

  constructor(message: string, options?: { cause?: unknown }) {
    super(message, options);
    this.name = new.target.name;
  }
}

export class ValidationError extends FlowWaveError {
  readonly code = 'validation_failed';

  constructor(
    readonly field: string,
    message: string,
    options?: { cause?: unknown },
  ) {
    super(`${field}: ${message}`, options);
  }
}

export class ConsentRequiredError extends FlowWaveError {
  readonly code = 'consent_required';

  constructor(
    readonly sourceId: string,
    readonly scope: string,
  ) {
    super(`No active consent for source "${sourceId}" and scope "${scope}".`);
  }
}

export class ForbiddenDataError extends FlowWaveError {
  readonly code = 'forbidden_data';

  /** Paths of offending keys, e.g. `events[0].windowTitle`. Values are never included. */
  constructor(readonly paths: readonly string[]) {
    super(`Payload contains data FlowWave must never collect at: ${paths.join(', ')}.`);
  }
}

export class IdempotencyConflictError extends FlowWaveError {
  readonly code = 'idempotency_conflict';

  constructor(readonly operationId: string) {
    super(`Operation "${operationId}" was already applied with a different payload.`);
  }
}
