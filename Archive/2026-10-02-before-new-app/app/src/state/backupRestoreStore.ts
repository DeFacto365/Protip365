import { restoreEncryptedFullBackup } from '../data/backup';
import { assertWriteAccess } from './entitlementStore';

/** State-layer restore entrypoint. Export remains available while read-only. */
export function restoreEncryptedBackupWithWriteAccess(text: string, password: string): void {
  assertWriteAccess();
  restoreEncryptedFullBackup(text, password);
}
