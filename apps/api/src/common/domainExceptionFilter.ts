import { type ArgumentsHost, Catch, HttpStatus } from '@nestjs/common';
import { BaseExceptionFilter } from '@nestjs/core';
import {
  AuthenticationError,
  ConflictError,
  ConsentRequiredError,
  FlowWaveError,
  RateLimitedError,
  ValidationError,
  type FlowWaveErrorCode,
} from '@flowwave/core';

const STATUS_BY_CODE: Record<FlowWaveErrorCode, number> = {
  validation_failed: HttpStatus.BAD_REQUEST,
  consent_required: HttpStatus.FORBIDDEN,
  forbidden_data: HttpStatus.UNPROCESSABLE_ENTITY,
  idempotency_conflict: HttpStatus.CONFLICT,
  authentication_failed: HttpStatus.UNAUTHORIZED,
  not_found: HttpStatus.NOT_FOUND,
  conflict: HttpStatus.CONFLICT,
  rate_limited: HttpStatus.TOO_MANY_REQUESTS,
};

export interface ErrorBody {
  readonly statusCode: number;
  readonly error: FlowWaveErrorCode;
  readonly message: string;
  readonly reason?: string;
  readonly field?: string;
  readonly subject?: string;
  readonly scope?: string;
}

interface HeaderResponse {
  status(code: number): HeaderResponse;
  setHeader(name: string, value: string): void;
  json(body: unknown): void;
}

export function errorStatus(error: FlowWaveError): number {
  // A wrong password while already signed in must not look like an expired
  // session, or clients would refresh and retry.
  if (error instanceof AuthenticationError && error.reason === 'reauthentication_failed') {
    return HttpStatus.FORBIDDEN;
  }
  return STATUS_BY_CODE[error.code];
}

export function errorBody(error: FlowWaveError): ErrorBody {
  const statusCode = errorStatus(error);
  const base = { statusCode, error: error.code, message: error.message };
  if (error instanceof AuthenticationError) return { ...base, reason: error.reason };
  if (error instanceof ValidationError || error instanceof ConflictError) return { ...base, field: error.field };
  if (error instanceof ConsentRequiredError) {
    return error.scope === undefined ? { ...base, subject: error.subject } : { ...base, subject: error.subject, scope: error.scope };
  }
  return base;
}

/** Maps domain errors to HTTP responses; everything else keeps Nest's default handling. */
@Catch()
export class DomainExceptionFilter extends BaseExceptionFilter {
  override catch(exception: unknown, host: ArgumentsHost): void {
    if (!(exception instanceof FlowWaveError) || host.getType() !== 'http') {
      super.catch(exception, host);
      return;
    }
    const response = host.switchToHttp().getResponse<HeaderResponse>();
    if (exception instanceof RateLimitedError) {
      response.setHeader('Retry-After', String(exception.retryAfterSeconds));
    }
    if (exception instanceof AuthenticationError && exception.reason !== 'reauthentication_failed') {
      response.setHeader('WWW-Authenticate', 'Bearer');
    }
    response.status(errorStatus(exception)).json(errorBody(exception));
  }
}
