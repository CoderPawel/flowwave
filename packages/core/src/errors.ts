export type FlowWaveErrorCode =
  | 'validation_failed'
  | 'consent_required'
  | 'forbidden_data'
  | 'idempotency_conflict'
  | 'authentication_failed'
  | 'not_found'
  | 'conflict'
  | 'rate_limited';

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

  /** `subject` is an external source (with a scope) or a consent type such as `device_usage`. */
  constructor(
    readonly subject: string,
    readonly scope?: string,
  ) {
    super(
      scope === undefined
        ? `No active consent for "${subject}".`
        : `No active consent for source "${subject}" and scope "${scope}".`,
    );
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

export type AuthenticationFailureReason =
  | 'invalid_credentials'
  | 'invalid_token'
  | 'token_expired'
  | 'session_revoked'
  | 'refresh_token_reused'
  | 'reauthentication_failed';

const AUTHENTICATION_MESSAGES: Record<AuthenticationFailureReason, string> = {
  invalid_credentials: 'Email or password is incorrect.',
  invalid_token: 'The token is not valid.',
  token_expired: 'The token has expired.',
  session_revoked: 'This session was signed out.',
  refresh_token_reused: 'This refresh token was already used; the session was signed out for safety.',
  reauthentication_failed: 'The password is incorrect.',
};

/** Messages are fixed per reason and never echo the email, password, or token. */
export class AuthenticationError extends FlowWaveError {
  readonly code = 'authentication_failed';

  constructor(readonly reason: AuthenticationFailureReason) {
    super(AUTHENTICATION_MESSAGES[reason]);
  }
}

export class NotFoundError extends FlowWaveError {
  readonly code = 'not_found';

  constructor(readonly resource: string) {
    super(`${resource} was not found.`);
  }
}

export class ConflictError extends FlowWaveError {
  readonly code = 'conflict';

  constructor(
    readonly field: string,
    message: string,
  ) {
    super(`${field}: ${message}`);
  }
}

export class RateLimitedError extends FlowWaveError {
  readonly code = 'rate_limited';

  constructor(readonly retryAfterSeconds: number) {
    super(`Too many requests. Try again in ${retryAfterSeconds} seconds.`);
  }
}
