import { Injectable } from '@nestjs/common';
import { hash, verify } from '@node-rs/argon2';
import { ValidationError } from '@flowwave/core';

/** OWASP minimum for Argon2id. Stored in each hash, so it can be raised later (decision 0013). */
export const ARGON2ID_PARAMETERS = { memoryCost: 19_456, timeCost: 2, parallelism: 1 } as const;

export const PASSWORD_MIN_LENGTH = 12;
export const PASSWORD_MAX_LENGTH = 128;

/** Length limits only, no composition rules (NIST SP 800-63B). Counted in characters, not bytes. */
export function assertPasswordPolicy(password: string): void {
  const length = [...password].length;
  if (length < PASSWORD_MIN_LENGTH || length > PASSWORD_MAX_LENGTH) {
    throw new ValidationError('password', `Must be ${PASSWORD_MIN_LENGTH}–${PASSWORD_MAX_LENGTH} characters.`);
  }
}

const PHC_PARAMETERS = /^\$argon2id\$v=19\$m=(\d+),t=(\d+),p=(\d+)\$/;

@Injectable()
export class PasswordHasher {
  private dummyHash: Promise<string> | undefined;

  async hash(password: string): Promise<string> {
    const hashed = await hash(password, ARGON2ID_PARAMETERS);
    if (!hashed.startsWith('$argon2id$')) {
      throw new Error('Password hashing did not produce an Argon2id hash.');
    }
    return hashed;
  }

  /** False for a wrong password and for a malformed hash; never throws for user input. */
  async verify(hashed: string, password: string): Promise<boolean> {
    try {
      return await verify(hashed, password);
    } catch {
      return false;
    }
  }

  /** Spends the same time as a real check, so unknown emails cannot be told apart by response time. */
  async verifyAgainstDummy(password: string): Promise<false> {
    this.dummyHash ??= hash('flowwave-dummy-password', ARGON2ID_PARAMETERS);
    await this.verify(await this.dummyHash, password);
    return false;
  }

  needsRehash(hashed: string): boolean {
    const match = PHC_PARAMETERS.exec(hashed);
    if (!match) return true;
    const [, memoryCost, timeCost, parallelism] = match.map(Number);
    return (
      memoryCost !== ARGON2ID_PARAMETERS.memoryCost ||
      timeCost !== ARGON2ID_PARAMETERS.timeCost ||
      parallelism !== ARGON2ID_PARAMETERS.parallelism
    );
  }
}
