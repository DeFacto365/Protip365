import { decryptBackupPayload, encryptBackupPayload } from '../backup';

describe('encrypted backup envelope', () => {
  const password = 'correct horse battery staple';

  it('round-trips structured data', () => {
    const payload = { employers: [{ id: 'e1', name: 'Cafe' }], count: 1 };
    const encrypted = encryptBackupPayload(payload, password);

    expect(encrypted).not.toContain('Cafe');
    expect(decryptBackupPayload(encrypted, password)).toEqual(payload);
  });

  it('rejects a wrong password', () => {
    const encrypted = encryptBackupPayload({ private: true }, password);

    expect(() => decryptBackupPayload(encrypted, 'incorrect password')).toThrow(
      'backup_authentication_failed'
    );
  });

  it('rejects a modified ciphertext before decryption', () => {
    const envelope = JSON.parse(encryptBackupPayload({ private: true }, password)) as {
      ciphertext: string;
    };
    envelope.ciphertext = `${envelope.ciphertext.slice(0, -2)}AA`;

    expect(() => decryptBackupPayload(JSON.stringify(envelope), password)).toThrow(
      'backup_authentication_failed'
    );
  });

  it('requires a backup password of at least eight characters', () => {
    expect(() => encryptBackupPayload({}, 'short')).toThrow('backup_password_too_short');
  });
});
