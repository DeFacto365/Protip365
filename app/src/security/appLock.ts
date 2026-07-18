import { CryptoDigestAlgorithm, digestStringAsync, getRandomBytes } from 'expo-crypto';
import * as LocalAuthentication from 'expo-local-authentication';
import * as SecureStore from 'expo-secure-store';

import {
  isValidPasscode,
  nextFailedAttempt,
  normalizeRecoveryKey,
  remainingLockSeconds,
  type LockoutState,
} from '../domain/security';

const KEYS = {
  enabled: 'protip365.lock.enabled',
  passcodeHash: 'protip365.lock.passcode-hash',
  salt: 'protip365.lock.salt',
  recoveryHash: 'protip365.lock.recovery-hash',
  biometric: 'protip365.lock.biometric',
  attempts: 'protip365.lock.attempts',
  lockUntil: 'protip365.lock.lock-until',
} as const;

function randomHex(bytes: number): string {
  return Array.from(getRandomBytes(bytes), (byte) => byte.toString(16).padStart(2, '0')).join('');
}

async function hash(secret: string, salt: string): Promise<string> {
  return digestStringAsync(CryptoDigestAlgorithm.SHA256, `${salt}:${secret}`);
}

function readLockout(): LockoutState {
  return {
    attempts: Number(SecureStore.getItem(KEYS.attempts) ?? 0) || 0,
    lockUntil: Number(SecureStore.getItem(KEYS.lockUntil) ?? 0) || 0,
  };
}

function writeLockout(state: LockoutState): void {
  SecureStore.setItem(KEYS.attempts, String(state.attempts));
  SecureStore.setItem(KEYS.lockUntil, String(state.lockUntil));
}

function resetLockout(): void {
  writeLockout({ attempts: 0, lockUntil: 0 });
}

export interface LockConfig {
  enabled: boolean;
  biometricEnabled: boolean;
}

export function getLockConfig(): LockConfig {
  return {
    enabled: SecureStore.getItem(KEYS.enabled) === '1',
    biometricEnabled: SecureStore.getItem(KEYS.biometric) === '1',
  };
}

export async function enablePasscode(passcode: string): Promise<string> {
  if (!isValidPasscode(passcode)) throw new Error('invalid_passcode');
  const salt = randomHex(16);
  const recoveryRaw = randomHex(16).toUpperCase();
  const recoveryKey = recoveryRaw.match(/.{1,4}/g)?.join('-') ?? recoveryRaw;
  SecureStore.setItem(KEYS.salt, salt);
  SecureStore.setItem(KEYS.passcodeHash, await hash(passcode, salt));
  SecureStore.setItem(KEYS.recoveryHash, await hash(recoveryRaw, salt));
  SecureStore.setItem(KEYS.enabled, '1');
  SecureStore.setItem(KEYS.biometric, '0');
  resetLockout();
  return recoveryKey;
}

export interface UnlockResult {
  ok: boolean;
  remainingSeconds: number;
}

async function verify(secret: string, storedKey: string): Promise<UnlockResult> {
  const now = Date.now();
  const lockout = readLockout();
  const remaining = remainingLockSeconds(lockout, now);
  if (remaining > 0) return { ok: false, remainingSeconds: remaining };
  const salt = SecureStore.getItem(KEYS.salt);
  const expected = SecureStore.getItem(storedKey);
  if (salt && expected && (await hash(secret, salt)) === expected) {
    resetLockout();
    return { ok: true, remainingSeconds: 0 };
  }
  const failed = nextFailedAttempt(lockout, now);
  writeLockout(failed);
  return { ok: false, remainingSeconds: remainingLockSeconds(failed, now) };
}

export function verifyPasscode(passcode: string): Promise<UnlockResult> {
  return verify(passcode, KEYS.passcodeHash);
}

export function verifyRecoveryKey(recoveryKey: string): Promise<UnlockResult> {
  return verify(normalizeRecoveryKey(recoveryKey), KEYS.recoveryHash);
}

export async function biometricAvailable(): Promise<boolean> {
  return (
    (await LocalAuthentication.hasHardwareAsync()) &&
    (await LocalAuthentication.isEnrolledAsync()) &&
    (await LocalAuthentication.supportedAuthenticationTypesAsync()).length > 0
  );
}

export async function authenticateBiometric(promptMessage: string): Promise<boolean> {
  if (!(await biometricAvailable())) return false;
  const result = await LocalAuthentication.authenticateAsync({
    promptMessage,
    cancelLabel: undefined,
    disableDeviceFallback: true,
  });
  return result.success;
}

export async function setBiometricEnabled(enabled: boolean, promptMessage: string): Promise<boolean> {
  if (enabled && !(await authenticateBiometric(promptMessage))) return false;
  SecureStore.setItem(KEYS.biometric, enabled ? '1' : '0');
  return true;
}

export function clearAppLock(): void {
  for (const key of Object.values(KEYS)) SecureStore.setItem(key, '');
}
