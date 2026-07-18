import React, { useState } from 'react';
import { Alert, ScrollView, Text } from 'react-native';
import * as DocumentPicker from 'expo-document-picker';
import { File, Paths } from 'expo-file-system';
import { useRouter } from 'expo-router';
import * as Sharing from 'expo-sharing';
import { useTranslation } from 'react-i18next';

import {
  assertBackupFileSize,
  createEncryptedFullBackup,
  restoreEncryptedFullBackup,
} from '../src/data/backup';
import { useEmployersStore } from '../src/state/employersStore';
import { useGoalsStore } from '../src/state/goalsStore';
import { useSettingsStore } from '../src/state/settingsStore';
import { useEntitlementStore } from '../src/state/entitlementStore';
import { useShiftsStore } from '../src/state/shiftsStore';
import { useTemplatesStore } from '../src/state/templatesStore';
import { Card, Field, GhostButton, PrimaryButton } from '../src/ui/components';
import { useTokens } from '../src/ui/tokens';
import { cancelAllAppOwnedNotifications } from '../src/notifications/shiftReminders';

function backupErrorKey(error: unknown): string {
  const message = error instanceof Error ? error.message : '';
  if (message === 'backup_password_too_short') return 'backup.errors.passwordTooShort';
  if (message === 'backup_authentication_failed') return 'backup.errors.authentication';
  if (message === 'backup_unsupported') return 'backup.errors.unsupported';
  if (message === 'backup_file_too_large') return 'backup.errors.tooLarge';
  if (message === 'backup_invalid_payload' || message === 'backup_invalid_format') {
    return 'backup.errors.invalid';
  }
  return 'backup.errors.failed';
}

export default function BackupScreen() {
  const router = useRouter();
  const { t } = useTokens();
  const { t: tr } = useTranslation();
  const [exportPassword, setExportPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [restorePassword, setRestorePassword] = useState('');
  const [busy, setBusy] = useState(false);
  const hydrateSettings = useSettingsStore((state) => state.hydrate);
  const loadEmployers = useEmployersStore((state) => state.load);
  const loadShifts = useShiftsStore((state) => state.load);
  const loadTemplates = useTemplatesStore((state) => state.load);
  const loadGoals = useGoalsStore((state) => state.load);
  const rehydrateEntitlement = useEntitlementStore((state) => state.rehydrateAfterDataChange);

  const exportBackup = async () => {
    if (exportPassword.length < 8) {
      Alert.alert(tr('backup.errors.passwordTooShort'));
      return;
    }
    if (exportPassword !== confirmPassword) {
      Alert.alert(tr('backup.errors.passwordMismatch'));
      return;
    }
    setBusy(true);
    try {
      const encrypted = createEncryptedFullBackup(exportPassword);
      const date = new Date().toISOString().slice(0, 10);
      const file = new File(Paths.cache, `protip365-backup-${date}.pt365`);
      if (file.exists) file.delete();
      file.write(encrypted);
      await Sharing.shareAsync(file.uri, { mimeType: 'application/json' });
      setExportPassword('');
      setConfirmPassword('');
    } catch (error) {
      Alert.alert(tr(backupErrorKey(error)));
    } finally {
      setBusy(false);
    }
  };

  const chooseRestore = async () => {
    if (restorePassword.length < 8) {
      Alert.alert(tr('backup.errors.passwordTooShort'));
      return;
    }
    const result = await DocumentPicker.getDocumentAsync({
      type: ['application/json', 'application/octet-stream', 'text/plain'],
      copyToCacheDirectory: true,
    });
    if (result.canceled || !result.assets[0]) return;
    const asset = result.assets[0];
    const restoreFile = new File(asset.uri);
    try {
      assertBackupFileSize(asset.size ?? restoreFile.size);
    } catch (error) {
      Alert.alert(tr(backupErrorKey(error)));
      return;
    }
    Alert.alert(tr('backup.restoreConfirmTitle'), tr('backup.restoreConfirmMessage'), [
      { text: tr('common.cancel'), style: 'cancel' },
      {
        text: tr('backup.restoreConfirmAction'),
        style: 'destructive',
        onPress: () => {
          void (async () => {
            setBusy(true);
            try {
              const encrypted = await restoreFile.text();
              await cancelAllAppOwnedNotifications(false);
              restoreEncryptedFullBackup(encrypted, restorePassword);
              hydrateSettings();
              rehydrateEntitlement();
              loadEmployers();
              await loadShifts();
              loadTemplates();
              loadGoals();
              setRestorePassword('');
              Alert.alert(tr('backup.restoreComplete'), undefined, [
                { text: tr('common.confirm'), onPress: () => router.back() },
              ]);
            } catch (error) {
              Alert.alert(tr(backupErrorKey(error)));
            } finally {
              setBusy(false);
            }
          })();
        },
      },
    ]);
  };

  return (
    <ScrollView
      style={{ flex: 1, backgroundColor: t.bg }}
      contentContainerStyle={{ padding: 16, paddingBottom: 48 }}
      keyboardShouldPersistTaps="handled"
    >
      <Text style={{ color: t.ink, fontSize: 15, lineHeight: 22, marginBottom: 16 }}>
        {tr('backup.explanation')}
      </Text>
      <Card style={{ padding: 16, marginBottom: 16 }}>
        <Text style={{ color: t.ink, fontSize: 18, fontWeight: '700', marginBottom: 8 }}>
          {tr('backup.exportTitle')}
        </Text>
        <Text style={{ color: t.softText, lineHeight: 20, marginBottom: 12 }}>
          {tr('backup.passwordWarning')}
        </Text>
        <Field
          label={tr('backup.password')}
          value={exportPassword}
          onChangeText={setExportPassword}
          secureTextEntry
          autoCapitalize="none"
        />
        <Field
          label={tr('backup.confirmPassword')}
          value={confirmPassword}
          onChangeText={setConfirmPassword}
          secureTextEntry
          autoCapitalize="none"
        />
        <PrimaryButton label={tr('backup.exportAction')} onPress={() => void exportBackup()} disabled={busy} />
      </Card>

      <Card style={{ padding: 16 }}>
        <Text style={{ color: t.ink, fontSize: 18, fontWeight: '700', marginBottom: 8 }}>
          {tr('backup.restoreTitle')}
        </Text>
        <Text style={{ color: t.softText, lineHeight: 20, marginBottom: 12 }}>
          {tr('backup.restoreHint')}
        </Text>
        <Field
          label={tr('backup.password')}
          value={restorePassword}
          onChangeText={setRestorePassword}
          secureTextEntry
          autoCapitalize="none"
        />
        <GhostButton label={tr('backup.restoreAction')} onPress={() => void chooseRestore()} danger />
      </Card>
    </ScrollView>
  );
}
