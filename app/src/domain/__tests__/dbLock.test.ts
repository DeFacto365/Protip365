jest.mock('expo-sqlite', () => ({
  openDatabaseSync: jest.fn(),
  deleteDatabaseSync: jest.fn(),
}));

jest.mock('expo-crypto', () => ({
  getRandomBytes: jest.fn(() => new Uint8Array(32)),
}));

jest.mock('expo-secure-store', () => ({
  getItem: jest.fn(() => 'stored-database-key'),
  setItem: jest.fn(),
}));

jest.mock('../../security/appLock', () => ({
  getLockConfig: jest.fn(() => ({ enabled: false, biometricEnabled: false })),
}));

import * as SecureStore from 'expo-secure-store';
import { openDatabaseSync } from 'expo-sqlite';
import { getLockConfig } from '../../security/appLock';
import {
  closeDatabaseForLock,
  getDb,
} from '../../data/db';
import {
  issueDatabaseUnlockCapability,
  revokeDatabaseUnlockCapability,
} from '../../security/databaseCapability';

const openDatabase = openDatabaseSync as jest.MockedFunction<typeof openDatabaseSync>;
const lockConfig = getLockConfig as jest.MockedFunction<typeof getLockConfig>;
const secureStore = SecureStore as jest.Mocked<typeof SecureStore>;

const database = {
  execSync: jest.fn(),
  getFirstSync: jest.fn(() => ({ user_version: 1 })),
  withTransactionSync: jest.fn((callback: () => void) => callback()),
  closeSync: jest.fn(),
};

beforeEach(() => {
  closeDatabaseForLock();
  revokeDatabaseUnlockCapability();
  jest.clearAllMocks();
  openDatabase.mockReturnValue(database as never);
  lockConfig.mockReturnValue({ enabled: false, biometricEnabled: false });
  secureStore.getItem.mockReturnValue('stored-database-key');
});

describe('SQLCipher app-unlock capability gate', () => {
  it('refuses before keychain access when app lock is enabled and no capability exists', () => {
    lockConfig.mockReturnValue({ enabled: true, biometricEnabled: false });

    expect(() => getDb()).toThrow('database_locked');
    expect(secureStore.getItem).not.toHaveBeenCalled();
    expect(openDatabase).not.toHaveBeenCalled();

    issueDatabaseUnlockCapability();
    expect(getDb()).toBe(database);
    expect(secureStore.getItem).toHaveBeenCalledWith('protip365.database-key.v1');
    expect(openDatabase).toHaveBeenCalledWith('protip365.db');
  });

  it('gates an already-open handle after the capability is revoked', () => {
    expect(getDb()).toBe(database);
    lockConfig.mockReturnValue({ enabled: true, biometricEnabled: false });
    revokeDatabaseUnlockCapability();

    expect(() => getDb()).toThrow('database_locked');
  });

  it('allows local database initialization without a capability when app lock is disabled', () => {
    expect(getDb()).toBe(database);
    expect(openDatabase).toHaveBeenCalledTimes(1);
  });
});
