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
  deleteItemAsync: jest.fn(() => Promise.resolve()),
}));

jest.mock('../../security/appLock', () => ({
  clearAppLock: jest.fn(() => Promise.resolve()),
  getLockConfig: jest.fn(() => ({ enabled: false, biometricEnabled: false })),
}));

import * as SecureStore from 'expo-secure-store';
import { deleteDatabaseSync, openDatabaseSync } from 'expo-sqlite';
import { clearAppLock, getLockConfig } from '../../security/appLock';
import {
  closeDatabaseForLock,
  eraseAllData,
  getDb,
} from '../../data/db';
import {
  hasDatabaseUnlockCapability,
  issueDatabaseUnlockCapability,
  revokeDatabaseUnlockCapability,
} from '../../security/databaseCapability';

const openDatabase = openDatabaseSync as jest.MockedFunction<typeof openDatabaseSync>;
const deleteDatabase = deleteDatabaseSync as jest.MockedFunction<typeof deleteDatabaseSync>;
const lockConfig = getLockConfig as jest.MockedFunction<typeof getLockConfig>;
const clearLock = clearAppLock as jest.MockedFunction<typeof clearAppLock>;
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
  clearLock.mockResolvedValue();
  secureStore.getItem.mockReturnValue('stored-database-key');
  secureStore.deleteItemAsync.mockResolvedValue();
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

  it('erases the database before revoking the unlock capability', async () => {
    lockConfig.mockReturnValue({ enabled: true, biometricEnabled: false });
    issueDatabaseUnlockCapability();
    expect(getDb()).toBe(database);

    deleteDatabase.mockImplementation((name: string) => {
      if (name === 'protip365.db') {
        expect(hasDatabaseUnlockCapability()).toBe(true);
      }
    });

    await eraseAllData();

    expect(database.execSync).toHaveBeenCalledWith('PRAGMA wal_checkpoint(TRUNCATE);');
    expect(database.closeSync).toHaveBeenCalled();
    expect(deleteDatabase).toHaveBeenCalledWith('protip365.db');
    expect(deleteDatabase).toHaveBeenCalledWith('protip365.db-wal');
    expect(deleteDatabase).toHaveBeenCalledWith('protip365.db-shm');
    expect(secureStore.deleteItemAsync).toHaveBeenCalledWith('protip365.database-key.v1');
    expect(clearLock).toHaveBeenCalled();
    expect(hasDatabaseUnlockCapability()).toBe(false);
  });
});
