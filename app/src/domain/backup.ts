import CryptoJS from 'crypto-js';

const FORMAT = 'protip365-encrypted-backup';
const VERSION = 1;
const ITERATIONS = 210_000;

interface EncryptedEnvelope {
  format: typeof FORMAT;
  version: typeof VERSION;
  kdf: 'PBKDF2-SHA256';
  cipher: 'AES-256-CBC-HMAC-SHA256';
  iterations: number;
  salt: string;
  iv: string;
  ciphertext: string;
  mac: string;
}

function splitKeys(derived: CryptoJS.lib.WordArray) {
  return {
    encryptionKey: CryptoJS.lib.WordArray.create(derived.words.slice(0, 8), 32),
    macKey: CryptoJS.lib.WordArray.create(derived.words.slice(8, 16), 32),
  };
}

function deriveKeys(password: string, salt: CryptoJS.lib.WordArray, iterations: number) {
  return splitKeys(
    CryptoJS.PBKDF2(password, salt, {
      keySize: 512 / 32,
      iterations,
      hasher: CryptoJS.algo.SHA256,
    })
  );
}

function macInput(envelope: Omit<EncryptedEnvelope, 'mac'>): string {
  return [
    envelope.format,
    envelope.version,
    envelope.iterations,
    envelope.salt,
    envelope.iv,
    envelope.ciphertext,
  ].join('|');
}

function constantTimeEqual(left: string, right: string): boolean {
  let difference = left.length ^ right.length;
  const length = Math.max(left.length, right.length);
  for (let index = 0; index < length; index += 1) {
    difference |= (left.charCodeAt(index) || 0) ^ (right.charCodeAt(index) || 0);
  }
  return difference === 0;
}

export function encryptBackupPayload(payload: unknown, password: string): string {
  if (password.length < 8) throw new Error('backup_password_too_short');
  const salt = CryptoJS.lib.WordArray.random(16);
  const iv = CryptoJS.lib.WordArray.random(16);
  const { encryptionKey, macKey } = deriveKeys(password, salt, ITERATIONS);
  const encrypted = CryptoJS.AES.encrypt(JSON.stringify(payload), encryptionKey, {
    iv,
    mode: CryptoJS.mode.CBC,
    padding: CryptoJS.pad.Pkcs7,
  });
  const withoutMac: Omit<EncryptedEnvelope, 'mac'> = {
    format: FORMAT,
    version: VERSION,
    kdf: 'PBKDF2-SHA256',
    cipher: 'AES-256-CBC-HMAC-SHA256',
    iterations: ITERATIONS,
    salt: salt.toString(CryptoJS.enc.Base64),
    iv: iv.toString(CryptoJS.enc.Base64),
    ciphertext: encrypted.ciphertext.toString(CryptoJS.enc.Base64),
  };
  const mac = CryptoJS.HmacSHA256(macInput(withoutMac), macKey).toString(CryptoJS.enc.Hex);
  return JSON.stringify({ ...withoutMac, mac } satisfies EncryptedEnvelope);
}

export function decryptBackupPayload<T>(text: string, password: string): T {
  let envelope: EncryptedEnvelope;
  try {
    envelope = JSON.parse(text) as EncryptedEnvelope;
  } catch {
    throw new Error('backup_invalid_format');
  }
  if (
    envelope.format !== FORMAT ||
    envelope.version !== VERSION ||
    envelope.kdf !== 'PBKDF2-SHA256' ||
    envelope.cipher !== 'AES-256-CBC-HMAC-SHA256' ||
    envelope.iterations !== ITERATIONS
  ) {
    throw new Error('backup_unsupported');
  }
  const salt = CryptoJS.enc.Base64.parse(envelope.salt);
  const iv = CryptoJS.enc.Base64.parse(envelope.iv);
  const { encryptionKey, macKey } = deriveKeys(password, salt, envelope.iterations);
  const { mac, ...withoutMac } = envelope;
  const expectedMac = CryptoJS.HmacSHA256(macInput(withoutMac), macKey).toString(CryptoJS.enc.Hex);
  if (!constantTimeEqual(mac, expectedMac)) throw new Error('backup_authentication_failed');
  try {
    const decrypted = CryptoJS.AES.decrypt(
      { ciphertext: CryptoJS.enc.Base64.parse(envelope.ciphertext) } as CryptoJS.lib.CipherParams,
      encryptionKey,
      { iv, mode: CryptoJS.mode.CBC, padding: CryptoJS.pad.Pkcs7 }
    );
    return JSON.parse(decrypted.toString(CryptoJS.enc.Utf8)) as T;
  } catch {
    throw new Error('backup_invalid_payload');
  }
}
