export const CLOCK = Symbol('CLOCK');

/** Injected wherever expiry is decided, so tests can move time forward. */
export interface Clock {
  now(): Date;
}

export const systemClock: Clock = {
  now: () => new Date(),
};

export function addSeconds(date: Date, seconds: number): Date {
  return new Date(date.getTime() + seconds * 1000);
}

export function addDays(date: Date, days: number): Date {
  return addSeconds(date, days * 86_400);
}
