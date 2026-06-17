import { useEffect, useState } from "react";
import { Alert, Linking, Pressable, Switch, Text, View } from "react-native";
import { useAuth } from "../auth/AuthProvider";
import {
  AppLockDelay,
  AppLockSettings,
  clearAppLock,
  getAppLockSettings,
  getBiometricSupport,
  saveAppLockSettings,
} from "../lib/appLock";
import { addEmployer, deleteEmployer, formatCurrency, parseMoney, saveProfile } from "../lib/protipData";
import { getSupabaseClient } from "../lib/supabase";
import { DataScaffold, FormInput, InfoRow, PickerRow, PrimaryButton, strings, styles, useAppData } from "./shared/screenShared";

const supportEmail = "support@protip365.com";
const privacyUrl = "https://protip365.com/privacy";
const termsUrl = "https://protip365.com/terms";

const appLockDelayLabels: Record<AppLockDelay, string> = {
  five_minutes: "After 5 minutes",
  launch: "On launch",
  resume: "On launch and resume",
};

export function SettingsScreen() {
  const { session } = useAuth();
  const { employers, isLoading, profile, reload, setProfile } = useAppData();
  const [newEmployerName, setNewEmployerName] = useState("");
  const [newEmployerRate, setNewEmployerRate] = useState("");
  const [isSaving, setIsSaving] = useState(false);
  const [pin, setPin] = useState("");
  const [appLock, setAppLock] = useState<AppLockSettings>({
    biometricEnabled: false,
    enabled: false,
    lockDelay: "resume",
  });
  const [biometricLabel, setBiometricLabel] = useState("Biometric unlock");
  const [biometricReason, setBiometricReason] = useState<string | null>(null);

  useEffect(() => {
    let mounted = true;

    Promise.all([getAppLockSettings(), getBiometricSupport()])
      .then(([settings, support]) => {
        if (!mounted) {
          return;
        }

        setAppLock(settings);
        setBiometricLabel(support.label);
        setBiometricReason(support.reason);
      })
      .catch(() => {
        if (mounted) {
          setBiometricReason("Security settings could not be loaded.");
        }
      });

    return () => {
      mounted = false;
    };
  }, []);

  async function handleProfileSave() {
    if (!profile) {
      return;
    }

    setIsSaving(true);

    try {
      await saveProfile(profile);
      Alert.alert("Settings saved", "Your settings were updated.");
      await reload();
    } catch (error) {
      Alert.alert("Save failed", error instanceof Error ? error.message : "Could not save settings.");
    } finally {
      setIsSaving(false);
    }
  }

  async function handleAppLockSave() {
    try {
      if (!appLock.enabled) {
        await clearAppLock();
        Alert.alert("App lock disabled", "PIN lock is turned off.");
        setPin("");
        return;
      }

      await saveAppLockSettings(appLock, pin.trim() || undefined);
      Alert.alert("App lock saved", "Your PIN lock settings were updated.");
      setPin("");
    } catch (error) {
      Alert.alert("App lock failed", error instanceof Error ? error.message : "Could not save app lock settings.");
    }
  }

  function toggleAppLock(value: boolean) {
    setAppLock((current) => ({
      ...current,
      biometricEnabled: value ? current.biometricEnabled : false,
      enabled: value,
    }));
  }

  function cycleLockDelay() {
    const nextDelay: Record<AppLockDelay, AppLockDelay> = {
      five_minutes: "launch",
      launch: "resume",
      resume: "five_minutes",
    };

    setAppLock((current) => ({ ...current, lockDelay: nextDelay[current.lockDelay] }));
  }

  async function openUrl(url: string, failureTitle: string) {
    try {
      const supported = await Linking.canOpenURL(url);

      if (!supported) {
        throw new Error("No app is available to open this link.");
      }

      await Linking.openURL(url);
    } catch (error) {
      Alert.alert(failureTitle, error instanceof Error ? error.message : "Could not open this link.");
    }
  }

  function openSupportEmail(subject: string, body: string) {
    const url = `mailto:${supportEmail}?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;

    void openUrl(url, "Support unavailable");
  }

  function confirmDeleteAccount() {
    Alert.alert(
      "Delete account?",
      "This sends a deletion request to support. You will get confirmation before the account is removed.",
      [
        { style: "cancel", text: "Cancel" },
        {
          onPress: () =>
            openSupportEmail(
              "Delete my ProTip365 account",
              `Please delete my ProTip365 account.\n\nEmail: ${session?.user.email ?? ""}\nUser ID: ${session?.user.id ?? ""}`,
            ),
          style: "destructive",
          text: "Request deletion",
        },
      ],
    );
  }

  async function handleAddEmployer() {
    if (!newEmployerName.trim()) {
      Alert.alert("Employer name required", "Enter an employer name.");
      return;
    }

    try {
      await addEmployer(newEmployerName.trim(), parseMoney(newEmployerRate) || profile?.default_hourly_rate || 15);
      setNewEmployerName("");
      setNewEmployerRate("");
      await reload();
    } catch (error) {
      Alert.alert("Employer failed", error instanceof Error ? error.message : "Could not add employer.");
    }
  }

  function confirmArchiveEmployer(id: string, name: string) {
    Alert.alert("Archive employer?", `${name} will be hidden from new shifts but stays visible on existing history.`, [
      { style: "cancel", text: "Cancel" },
      {
        onPress: async () => {
          try {
            await deleteEmployer(id);
            await reload();
          } catch (error) {
            Alert.alert("Archive failed", error instanceof Error ? error.message : "Could not archive employer.");
          }
        },
        style: "destructive",
        text: "Archive",
      },
    ]);
  }

  async function signOut() {
    await getSupabaseClient()?.auth.signOut();
  }

  return (
    <DataScaffold isLoading={isLoading} onRefresh={reload} title={strings.screens.settings}>
      {profile ? (
        <View style={styles.formCard}>
          <Text style={styles.formTitle}>Account</Text>
          <Text style={styles.body}>{session?.user.email}</Text>
          <FormInput label="Name" onChangeText={(value) => setProfile({ ...profile, name: value })} placeholder="Your name" value={profile.name ?? ""} />
          <FormInput label="Language" onChangeText={(value) => setProfile({ ...profile, language: value.toLowerCase(), preferred_language: value.toLowerCase() })} placeholder="en, fr, es" value={profile.preferred_language ?? profile.language} />
          <FormInput keyboardType="decimal-pad" label="Default hourly rate" onChangeText={(value) => setProfile({ ...profile, default_hourly_rate: parseMoney(value) })} placeholder="15.00" value={`${profile.default_hourly_rate}`} />
          <FormInput keyboardType="decimal-pad" label="Week start day" onChangeText={(value) => setProfile({ ...profile, week_start: Math.max(0, Math.min(6, Math.round(parseMoney(value)))) })} placeholder="0 Sunday, 1 Monday" value={`${profile.week_start}`} />
          <View style={styles.switchRow}>
            <Text style={styles.label}>Use multiple employers</Text>
            <Switch onValueChange={(value) => setProfile({ ...profile, use_multiple_employers: value })} value={profile.use_multiple_employers} />
          </View>
          <View style={styles.switchRow}>
            <Text style={styles.label}>Variable schedule</Text>
            <Switch onValueChange={(value) => setProfile({ ...profile, has_variable_schedule: value })} value={Boolean(profile.has_variable_schedule)} />
          </View>
        </View>
      ) : null}
      {profile ? (
        <View style={styles.formCard}>
          <Text style={styles.formTitle}>Alerts</Text>
          <FormInput
            keyboardType="decimal-pad"
            label="Default alert minutes"
            onChangeText={(value) =>
              setProfile({
                ...profile,
                default_alert_minutes: value.trim() ? Math.max(0, Math.round(parseMoney(value))) : null,
              })
            }
            placeholder="Off"
            value={profile.default_alert_minutes === null || profile.default_alert_minutes === undefined ? "" : `${profile.default_alert_minutes}`}
          />
          <InfoRow label="Per-shift alerts" value="Set on Add Shift" />
          <InfoRow label="Missing-entry alert" value="1 hour after planned end time" />
          <PrimaryButton isLoading={isSaving} label="Save alert settings" onPress={handleProfileSave} />
        </View>
      ) : null}
      <View style={styles.formCard}>
        <Text style={styles.formTitle}>Security</Text>
        <View style={styles.switchRow}>
          <Text style={styles.label}>PIN lock</Text>
          <Switch onValueChange={toggleAppLock} value={appLock.enabled} />
        </View>
        {appLock.enabled ? (
          <>
            <FormInput keyboardType="decimal-pad" label="PIN" onChangeText={setPin} placeholder="4+ digits" value={pin} />
            <PickerRow label="Prompt" onPress={cycleLockDelay} value={appLockDelayLabels[appLock.lockDelay]} />
            <View style={styles.switchRow}>
              <View style={styles.flex}>
                <Text style={styles.label}>{biometricLabel}</Text>
                {biometricReason ? <Text style={styles.body}>{biometricReason}</Text> : null}
              </View>
              <Switch
                disabled={Boolean(biometricReason)}
                onValueChange={(value) => setAppLock({ ...appLock, biometricEnabled: value })}
                value={appLock.biometricEnabled && !biometricReason}
              />
            </View>
          </>
        ) : null}
        <PrimaryButton label="Save security settings" onPress={handleAppLockSave} />
      </View>
      {profile ? (
        <View style={styles.formCard}>
          <Text style={styles.formTitle}>Targets</Text>
          <View style={styles.row}>
            <FormInput keyboardType="decimal-pad" label="Daily tips" onChangeText={(value) => setProfile({ ...profile, target_tip_daily: parseMoney(value) })} placeholder="0.00" value={`${profile.target_tip_daily}`} />
            <FormInput keyboardType="decimal-pad" label="Weekly tips" onChangeText={(value) => setProfile({ ...profile, target_tip_weekly: parseMoney(value) })} placeholder="0.00" value={`${profile.target_tip_weekly}`} />
          </View>
          <FormInput keyboardType="decimal-pad" label="Monthly tips" onChangeText={(value) => setProfile({ ...profile, target_tip_monthly: parseMoney(value) })} placeholder="0.00" value={`${profile.target_tip_monthly}`} />
          <View style={styles.row}>
            <FormInput keyboardType="decimal-pad" label="Daily sales" onChangeText={(value) => setProfile({ ...profile, target_sales_daily: parseMoney(value) })} placeholder="0.00" value={`${profile.target_sales_daily}`} />
            <FormInput keyboardType="decimal-pad" label="Weekly sales" onChangeText={(value) => setProfile({ ...profile, target_sales_weekly: parseMoney(value) })} placeholder="0.00" value={`${profile.target_sales_weekly}`} />
          </View>
          <FormInput keyboardType="decimal-pad" label="Monthly sales" onChangeText={(value) => setProfile({ ...profile, target_sales_monthly: parseMoney(value) })} placeholder="0.00" value={`${profile.target_sales_monthly}`} />
          <View style={styles.row}>
            <FormInput keyboardType="decimal-pad" label="Daily hours" onChangeText={(value) => setProfile({ ...profile, target_hours_daily: parseMoney(value) })} placeholder="0.00" value={`${profile.target_hours_daily}`} />
            <FormInput keyboardType="decimal-pad" label="Weekly hours" onChangeText={(value) => setProfile({ ...profile, target_hours_weekly: parseMoney(value) })} placeholder="0.00" value={`${profile.target_hours_weekly}`} />
          </View>
          <FormInput keyboardType="decimal-pad" label="Monthly hours" onChangeText={(value) => setProfile({ ...profile, target_hours_monthly: parseMoney(value) })} placeholder="0.00" value={`${profile.target_hours_monthly}`} />
          <View style={styles.row}>
            <FormInput keyboardType="decimal-pad" label="Target tip %" onChangeText={(value) => setProfile({ ...profile, tip_target_percentage: parseMoney(value) })} placeholder="0" value={`${profile.tip_target_percentage ?? 0}`} />
            <FormInput keyboardType="decimal-pad" label="Deduction %" onChangeText={(value) => setProfile({ ...profile, average_deduction_percentage: parseMoney(value) })} placeholder="0" value={`${profile.average_deduction_percentage ?? 0}`} />
          </View>
          <PrimaryButton isLoading={isSaving} label="Save settings" onPress={handleProfileSave} />
        </View>
      ) : null}
      <View style={styles.formCard}>
        <Text style={styles.formTitle}>Employers</Text>
        <FormInput label="Employer name" onChangeText={setNewEmployerName} placeholder="Restaurant or venue" value={newEmployerName} />
        <FormInput keyboardType="decimal-pad" label="Hourly rate" onChangeText={setNewEmployerRate} placeholder="15.00" value={newEmployerRate} />
        <PrimaryButton label="Add employer" onPress={handleAddEmployer} />
        {employers.map((employer) => (
          <View key={employer.id} style={styles.listRow}>
            <View>
              <Text style={styles.listTitle}>{employer.name}</Text>
              <Text style={styles.body}>
                {formatCurrency(employer.hourly_rate)}/hr{employer.active === false ? " - archived" : ""}
              </Text>
            </View>
            {employer.active === false ? null : (
              <Pressable accessibilityRole="button" onPress={() => confirmArchiveEmployer(employer.id, employer.name)}>
                <Text style={styles.dangerText}>Archive</Text>
              </Pressable>
            )}
          </View>
        ))}
      </View>
      <View style={styles.formCard}>
        <Text style={styles.formTitle}>Support</Text>
        <PickerRow label="Contact support" onPress={() => openSupportEmail("ProTip365 support", `Email: ${session?.user.email ?? ""}\n\nHow can we help?`)} value={supportEmail} />
      </View>
      <View style={styles.formCard}>
        <Text style={styles.formTitle}>Legal</Text>
        <PickerRow label="Privacy Policy" onPress={() => void openUrl(privacyUrl, "Privacy unavailable")} value="Open" />
        <PickerRow label="Terms of Use" onPress={() => void openUrl(termsUrl, "Terms unavailable")} value="Open" />
        <Pressable accessibilityRole="button" onPress={confirmDeleteAccount} style={styles.signOutButton}>
          <Text style={styles.dangerText}>Delete account</Text>
          <Text style={styles.body}>Requests are handled by support and confirmed before removal.</Text>
        </Pressable>
      </View>
      <Pressable accessibilityRole="button" onPress={signOut} style={styles.signOutButton}>
        <Text style={styles.dangerText}>Sign out</Text>
      </Pressable>
    </DataScaffold>
  );
}
