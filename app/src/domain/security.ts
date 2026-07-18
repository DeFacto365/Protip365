export interface LockoutState {
  attempts: number;
  lockUntil: number;
}

/** Five failures trigger a delay; later failures back off up to five minutes. */
export function nextFailedAttempt(state: LockoutState, now: number): LockoutState {
  const attempts = state.attempts + 1;
  if (attempts < 5) return { attempts, lockUntil: state.lockUntil };
  const delaySeconds = Math.min(30 * 2 ** (attempts - 5), 300);
  return { attempts, lockUntil: now + delaySeconds * 1000 };
}

export function remainingLockSeconds(state: LockoutState, now: number): number {
  return Math.max(0, Math.ceil((state.lockUntil - now) / 1000));
}

export function isValidPasscode(value: string): boolean {
  return /^\d{6}$/.test(value);
}

export function normalizeRecoveryKey(value: string): string {
  return value.replace(/[^a-fA-F0-9]/g, '').toUpperCase();
}
