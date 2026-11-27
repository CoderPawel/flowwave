import { randomUUID } from 'node:crypto';
import type { IncomingMessage, ServerResponse } from 'node:http';
import type { Params } from 'nestjs-pino';
import type { AppConfig } from '../config/appConfig.js';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** Path without query string, so query parameters never reach the logs. */
export function pathOnly(url: string | undefined): string {
  if (!url) return '';
  const end = url.search(/[?#]/);
  return end === -1 ? url : url.slice(0, end);
}

export function requestId(request: IncomingMessage, response: ServerResponse): string {
  const incoming = request.headers['x-request-id'];
  const id = typeof incoming === 'string' && UUID.test(incoming) ? incoming : randomUUID();
  response.setHeader('x-request-id', id);
  return id;
}

/**
 * Structured JSON logs. Requests are logged as id, method, path, status, and
 * duration only: no headers, cookies, query strings, or bodies, so tokens and
 * health values cannot leak into logs.
 */
export function loggerOptions(config: AppConfig): Params {
  return {
    pinoHttp: {
      level: config.logLevel,
      genReqId: requestId,
      autoLogging: {
        ignore: (request) => pathOnly(request.url).startsWith('/v1/health'),
      },
      serializers: {
        req: (request: { id: string; method: string; url: string }) => ({
          id: request.id,
          method: request.method,
          path: pathOnly(request.url),
        }),
        res: (response: { statusCode: number }) => ({ statusCode: response.statusCode }),
      },
      redact: {
        paths: ['password', 'token', 'accessToken', 'refreshToken', 'authorization', '*.password', '*.token', '*.accessToken', '*.refreshToken', '*.authorization'],
        censor: '[REDACTED]',
      },
    },
  };
}
