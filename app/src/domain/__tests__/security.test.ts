import {
  isValidPasscode,
  nextFailedAttempt,
  normalizeRecoveryKey,
  remainingLockSeconds,
} from '../security';

describe('local app-lock policy', () => {
  it('requires exactly six digits', () => {
    expect(isValidPasscode('123456')).toBe(true);
    expect(isValidPasscode('12345')).toBe(false);
    expect(isValidPasscode('12345a')).toBe(false);
  });

  it('rate-limits the fifth failed attempt and increases the delay', () => {
    const now = 1_000_000;
    let state = { attempts: 0, lockUntil: 0 };
    for (let index = 0; index < 4; index++) state = nextFailedAttempt(state, now);
    expect(remainingLockSeconds(state, now)).toBe(0);
    state = nextFailedAttempt(state, now);
    expect(remainingLockSeconds(state, now)).toBe(30);
    state = nextFailedAttempt(state, now + 30_000);
    expect(remainingLockSeconds(state, now + 30_000)).toBe(60);
  });

  it('normalizes a user-entered recovery key', () => {
    expect(normalizeRecoveryKey('ab12-cd34 ef56')).toBe('AB12CD34EF56');
  });
});
