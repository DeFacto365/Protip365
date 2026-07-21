import React, { useState } from 'react';
import { Alert, ScrollView } from 'react-native';
import { Stack } from 'expo-router';
import { useTranslation } from 'react-i18next';

import { isValidPasscode } from '../src/domain/security';
import { useAppLockStore, withAppLockSystemPrompt } from '../src/state/appLockStore';
import { Card, Chip, Field, GhostButton, PrimaryButton } from '../src/ui/components';
import { useTokens } from '../src/ui/tokens';
import { Text } from '../src/ui/typography';

export default function SecurityScreen() {
  const { t } = useTokens();
  const { t: tr } = useTranslation();
  const enabled = useAppLockStore((state) => state.enabled);
  const biometricEnabled = useAppLockStore((state) => state.biometricEnabled);
  const enable = useAppLockStore((state) => state.enable);
  const disable = useAppLockStore((state) => state.disable);
  const setBiometrics = useAppLockStore((state) => state.setBiometrics);
  const [passcode, setPasscode] = useState('');
  const [confirmation, setConfirmation] = useState('');
  const [acknowledged, setAcknowledged] = useState(false);
  const [recoveryKey, setRecoveryKey] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const normalizePasscode = (value: string) => value.replace(/\D/g, '').slice(0, 6);

  const activate = async () => {
    if (!isValidPasscode(passcode) || passcode !== confirmation || !acknowledged) {
      setError(tr('security.setupError'));
      return;
    }
    const key = await enable(passcode);
    setRecoveryKey(key);
    setPasscode('');
    setConfirmation('');
    setError(null);
  };

  const deactivate = async () => {
    if (!(await disable(passcode))) {
      setError(tr('security.incorrectPasscode'));
      return;
    }
    setPasscode('');
    setRecoveryKey(null);
  };

  const toggleBiometrics = async () => {
    const ok = await withAppLockSystemPrompt(() =>
      setBiometrics(!biometricEnabled, tr('security.biometricPrompt'))
    );
    if (!ok) Alert.alert(tr('security.biometricUnavailable'));
  };

  return (
    <ScrollView
      style={{ flex: 1, backgroundColor: t.bg }}
      contentContainerStyle={{ padding: 16, paddingBottom: 48 }}
      keyboardShouldPersistTaps="handled"
    >
      <Stack.Screen options={{ title: tr('security.title') }} />
      <Text style={{ color: t.softText, marginBottom: 14 }}>{tr('security.explanation')}</Text>

      {recoveryKey ? (
        <Card style={{ padding: 16, marginBottom: 14 }}>
          <Text style={{ color: t.ink, fontWeight: '700', fontSize: 16 }}>
            {tr('security.saveRecoveryKey')}
          </Text>
          <Text selectable style={{ color: t.cobaltLink, backgroundColor: t.cobaltSoft, padding: 8, fontWeight: '700', fontSize: 18, marginVertical: 12 }}>
            {recoveryKey}
          </Text>
          <Text style={{ color: t.softText }}>{tr('security.recoveryShownOnce')}</Text>
        </Card>
      ) : null}

      {!enabled ? (
        <Card style={{ padding: 16 }}>
          <Text style={{ color: t.amber, backgroundColor: t.amberSoft, padding: 8, marginBottom: 12 }}>
            {tr('security.setupWarning')}
          </Text>
          <Field
            label={tr('security.newPasscode')}
            value={passcode}
            onChangeText={(value) => {
              setPasscode(normalizePasscode(value));
              setError(null);
            }}
            keyboardType="number-pad"
            secureTextEntry
          />
          <Field
            label={tr('security.confirmPasscode')}
            value={confirmation}
            onChangeText={(value) => {
              setConfirmation(normalizePasscode(value));
              setError(null);
            }}
            keyboardType="number-pad"
            secureTextEntry
            error={error}
          />
          <Chip
            label={tr('security.understandReset')}
            selected={acknowledged}
            onPress={() => setAcknowledged((value) => !value)}
          />
          <PrimaryButton label={tr('security.enablePasscode')} onPress={() => void activate()} style={{ marginTop: 12 }} />
        </Card>
      ) : (
        <Card style={{ padding: 16 }}>
          <Chip
            label={tr('security.biometricLock')}
            selected={biometricEnabled}
            onPress={() => void toggleBiometrics()}
          />
          <Field
            label={tr('security.currentPasscode')}
            value={passcode}
            onChangeText={(value) => {
              setPasscode(normalizePasscode(value));
              setError(null);
            }}
            keyboardType="number-pad"
            secureTextEntry
            error={error}
          />
          <GhostButton label={tr('security.disablePasscode')} onPress={() => void deactivate()} danger />
        </Card>
      )}
    </ScrollView>
  );
}
