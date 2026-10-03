import React, {useEffect, useRef, useState} from 'react';
import {AppState, View, TextInput, ActivityIndicator} from 'react-native';
import {Button, Txt, C} from '../ui';
import {getLockConfig, setDatabaseUnlocked, verifyPasscode, verifyRecoveryKey, authenticateBiometric} from './appLock';
import {closeForLock} from '../storage';
/** An inherited lock gates all record loading; backgrounding revokes storage access immediately. */
export function LockGate({children}: {children: React.ReactNode}) {
  const [ready, setReady] = useState(false), [checked, setChecked] = useState(false);
  const [secret, setSecret] = useState(''), [recovery, setRecovery] = useState(false), [busy, setBusy] = useState(false), [message, setMessage] = useState('');
  const generation = useRef(0);
  const [biometricEnabled, setBiometricEnabled] = useState(false);
  const unlock = () => {setDatabaseUnlocked(true); setSecret(''); setMessage(''); setReady(true);};
  useEffect(() => {
    try {const config = getLockConfig(); setBiometricEnabled(config.biometricEnabled); if (!config.enabled) unlock(); setChecked(true);} catch {setMessage('Unable to read the existing app lock. Retry after restarting. / Impossible de lire le verrou existant.'); setChecked(true);}
    const subscription = AppState.addEventListener('change', state => {
      if (state !== 'active') {
        generation.current += 1;
        try {if (getLockConfig().enabled) {setDatabaseUnlocked(false); setReady(false); setSecret(''); void closeForLock();}} catch {setDatabaseUnlocked(false); setReady(false);}
      }
    });
    return () => {subscription.remove(); setDatabaseUnlocked(false); void closeForLock();};
  }, []);
  if (ready) return <>{children}</>;
  if (!checked) return <ActivityIndicator />;
  const verify = async () => {
    const attempt = generation.current;
    setBusy(true);
    try {const result = await (recovery ? verifyRecoveryKey(secret) : verifyPasscode(secret));
      if (result.ok && attempt === generation.current && AppState.currentState === 'active') unlock(); else setMessage(result.remainingSeconds ? `Try again in ${result.remainingSeconds}s / Réessaie dans ${result.remainingSeconds}s` : 'Incorrect code / Code incorrect');
    } catch {setMessage('Unable to unlock / Impossible de déverrouiller');} finally {setBusy(false);}
  };
  return <View style={{flex: 1, justifyContent: 'center', padding: 28, gap: 20, backgroundColor: C.bg}}>
    <Txt kind="title">ProTip365</Txt><Txt>Unlock with your existing code / Déverrouille avec ton code existant</Txt>
    <TextInput accessibilityLabel={recovery ? 'Recovery key / Clé de récupération' : 'Passcode / Code'} secureTextEntry={!recovery} keyboardType={recovery ? 'default' : 'number-pad'} value={secret} onChangeText={setSecret} maxLength={recovery ? 39 : 6} style={{borderWidth: 1, padding: 16, fontSize: 20, color: C.ink}} />
    {!!message && <View accessibilityLiveRegion="polite"><Txt>{message}</Txt></View>}
    <Button label="Unlock / Déverrouiller" disabled={busy} onPress={() => void verify()} />
    <Button secondary label={recovery ? 'Use passcode / Utiliser le code' : 'Use recovery key / Clé de récupération'} onPress={() => {setRecovery(!recovery); setSecret(''); setMessage('');}} />
    {biometricEnabled && <Button secondary label="Biometrics / Biométrie" disabled={busy} onPress={() => {const attempt = generation.current; setBusy(true); void authenticateBiometric('Unlock ProTip365').then(ok => {if(ok && attempt === generation.current && AppState.currentState === 'active') unlock();}).catch(() => setMessage('Unable to unlock / Impossible de déverrouiller')).finally(() => setBusy(false));}} />}
  </View>;
}
