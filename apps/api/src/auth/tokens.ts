import { createHash, randomBytes } from 'node:crypto';

export const ACCESS_TOKEN_PREFIX = 'fwat_';
export const REFRESH_TOKEN_PREFIX = 'fwrt_';
export type TokenPrefix = typeof ACCESS_TOKEN_PREFIX | typeof REFRESH_TOKEN_PREFIX;

const TOKEN_BYTES = 32;
const BODY = /^[A-Za-z0-9_-]{43}$/;

/** 256 random bits in base64url, with a prefix that secret scanners can recognize. */
export function generateToken(prefix: TokenPrefix): string {
  return prefix + randomBytes(TOKEN_BYTES).toString('base64url');
}

export function isWellFormedToken(value: unknown, prefix: TokenPrefix): value is string {
  return typeof value === 'string' && value.startsWith(prefix) && BODY.test(value.slice(prefix.length));
}

/**
 * Only this hash is stored. Tokens are long and random, so a fast hash is
 * enough: there is nothing to guess.
 */
export function hashToken(token: string): string {
  return createHash('sha256').update(token, 'utf8').digest('hex');
}

/** Extracts the token from `Authorization: Bearer <token>`. */
export function bearerToken(header: string | undefined): string | undefined {
  if (!header) return undefined;
  const match = /^Bearer\s+(\S+)$/i.exec(header);
  return match?.[1];
}
