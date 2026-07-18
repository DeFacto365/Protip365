import React, { useState } from 'react';
import { Alert, Linking, Pressable, ScrollView, Text, View } from 'react-native';
import { useTranslation } from 'react-i18next';

import { eraseAllData } from '../data/db';
import { cancelAllAppOwnedNotifications } from '../notifications/shiftReminders';
import { useAppLockStore } from '../state/appLockStore';
import { Card, Field, GhostButton, PrimaryButton } from './components';
import { useTokens } from './tokens';

export function LockScreen() {
  const { t } = useTokens();
  const { t: tr } = useTranslation();
  const biometricEnabled = useAppLockStore((state) => state.biometricEnabled);
  const unlockWithPasscode = useAppLockStore((state) => state.unlockWithPasscode);
  const unlockWithRecovery = useAppLockStore((state) => state.unlockWithRecovery);
  const unlockWithBiometrics = useAppLockStore((state) => state.unlockWithBiometrics);
  const resetLock = useAppLockStore((state) => state.reset);
  const [passcode, setPasscode] = useState('');
  const [recoveryKey, setRecoveryKey] = useState('');
  const [showRecovery, setShowRecovery] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const unlock = async () => {
    const result = await unlockWithPasscode(passcode);
    if (!result.ok) {
      setError(
        result.remainingSeconds > 0
          ? tr('security.tryLater', { seconds: result.remainingSeconds })
          : tr('security.incorrectPasscode')
      );
    }
  };

  const recover = async () => {
    const result = await unlockWithRecovery(recoveryKey);
    if (!result.ok) setError(tr('security.incorrectRecoveryKey'));
  };

  const resetAccess = () => {
    Alert.alert(tr('security.resetTitle'), tr('security.resetWarning'), [
      { text: tr('common.cancel'), style: 'cancel' },
      {
        text: tr('security.resetAction'),
        style: 'destructive',
        onPress: () => {
          void (async () => {
            try {
              await cancelAllAppOwnedNotifications(false);
              eraseAllData();
              resetLock();
            } catch {
              setError(tr('reminders.cancelFailed'));
            }
          })();
        },
      },
    ]);
  };

  return (
    <ScrollView
      style={{ flex: 1, backgroundColor: t.bg }}
      contentContainerStyle={{ flexGrow: 1, justifyContent: 'center', padding: 24 }}
      keyboardShouldPersistTaps="handled"
    >
      <Text style={{ color: t.ink, fontSize: 28, fontWeight: '700', marginBottom: 6 }}>
        ProTip365
      </Text>
      <Text style={{ color: t.softText, marginBottom: 18 }}>{tr('security.lockedSubtitle')}</Text>
      <Card style={{ padding: 16 }}>
        <Field
          label={tr('security.passcode')}
          value={passcode}
          onChangeText={(value) => {
            setPasscode(value.replace(/\D/g, '').slice(0, 6));
            setError(null);
          }}
          keyboardType="number-pad"
          secureTextEntry
          error={error}
        />
        <PrimaryButton label={tr('security.unlock')} onPress={() => void unlock()} />
        {biometricEnabled ? (
          <GhostButton
            label={tr('security.useBiometrics')}
            onPress={() => void unlockWithBiometrics(tr('security.biometricPrompt'))}
            style={{ marginTop: 8 }}
          />
        ) : null}
        <GhostButton
          label={tr('security.useRecoveryKey')}
          onPress={() => setShowRecovery((value) => !value)}
          style={{ marginTop: 8 }}
        />
        {showRecovery ? (
          <View style={{ marginTop: 10 }}>
            <Field
              label={tr('security.recoveryKey')}
              value={recoveryKey}
              onChangeText={(value) => {
                setRecoveryKey(value);
                setError(null);
              }}
              autoCapitalize="characters"
            />
            <PrimaryButton label={tr('security.recover')} onPress={() => void recover()} />
          </View>
        ) : null}
      </Card>
      <Text style={{ color: t.softText, fontSize: 12, marginTop: 16 }}>
        {tr('security.localPrivacy')}
      </Text>
      <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 14 }}>
        {[
          [tr('security.privacyLink'), 'https://protip365.vercel.app/privacy'],
          [tr('security.termsLink'), 'https://protip365.vercel.app/terms'],
          [tr('security.supportLink'), 'mailto:info@defacto365.com'],
        ].map(([label, url]) => (
          <Pressable
            key={url}
            accessibilityRole="link"
            accessibilityLabel={label}
            onPress={() => void Linking.openURL(url)}
            style={({ pressed }) => ({
              minHeight: 48,
              justifyContent: 'center',
              borderWidth: 1,
              borderColor: t.cobalt,
              backgroundColor: t.cobaltSoft,
              paddingHorizontal: 12,
              opacity: pressed ? 0.7 : 1,
            })}
          >
            <Text style={{ color: t.cobaltLink, fontWeight: '600' }}>{label}</Text>
          </Pressable>
        ))}
      </View>
      <GhostButton
        label={tr('security.resetAction')}
        onPress={resetAccess}
        danger
        style={{ marginTop: 14 }}
      />
    </ScrollView>
  );
}
