const capabilityBrand: unique symbol = Symbol('protip365.database-unlock');

export interface DatabaseUnlockCapability {
  readonly [capabilityBrand]: true;
}

let activeCapability: DatabaseUnlockCapability | null = null;

/** Called only after the app-lock flow has authenticated or enabled a passcode. */
export function issueDatabaseUnlockCapability(): void {
  activeCapability = Object.freeze({ [capabilityBrand]: true as const });
}

export function revokeDatabaseUnlockCapability(): void {
  activeCapability = null;
}

/** Returns the process-local capability; it is never persisted or exported. */
export function requireDatabaseUnlockCapability(): DatabaseUnlockCapability {
  if (!activeCapability) throw new Error('database_locked');
  return activeCapability;
}

export function hasDatabaseUnlockCapability(): boolean {
  return activeCapability != null;
}
