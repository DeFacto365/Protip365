import { useState } from "react";
import { Linking, Pressable, StyleSheet, Text, View } from "react-native";
import { Card } from "../../components/AppScaffold";
import { clearShiftRecords } from "../../storage/shiftRepository";
import { clearSubscription } from "../../storage/subscriptionRepository";
import { theme } from "../../theme";
import { complianceLinks, requestAccountDeletion } from "./accountLifecycle";

async function clearLocalAccountData() {
  await Promise.all([clearShiftRecords(), clearSubscription()]);
}

export function SettingsComplianceSection() {
  const [status, setStatus] = useState<string | null>(null);

  async function openLink(url: string) {
    try {
      await Linking.openURL(url);
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unknown link error";
      console.warn("ProTip365 settings link failed", message);
      setStatus("Could not open link. Try again from your browser or email app.");
    }
  }

  async function handleDeletionRequest() {
    const result = await requestAccountDeletion({
      clearLocalData: clearLocalAccountData,
      openUrl: Linking.openURL,
    });

    if (!result.ok) {
      console.warn("ProTip365 account deletion request failed", result.logMessage);
    }
    setStatus(result.message);
  }

  return (
    <View style={styles.section}>
      <Card body="Store compliance links and account lifecycle actions." title="Account" />
      <View style={styles.list}>
        {complianceLinks.map((link) => (
          <Pressable accessibilityRole="link" key={link.key} onPress={() => openLink(link.url)} style={styles.button}>
            <Text style={styles.buttonText}>{link.label}</Text>
          </Pressable>
        ))}
        <Pressable accessibilityRole="button" onPress={handleDeletionRequest} style={[styles.button, styles.dangerButton]}>
          <Text style={[styles.buttonText, styles.dangerText]}>Request account deletion</Text>
        </Pressable>
      </View>
      {status ? <Text style={styles.status}>{status}</Text> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  button: {
    backgroundColor: theme.colors.surface,
    borderColor: theme.colors.border,
    borderRadius: theme.radius.md,
    borderWidth: 1,
    minHeight: 50,
    justifyContent: "center",
    paddingHorizontal: theme.spacing.lg,
  },
  buttonText: {
    ...theme.typography.body,
    color: theme.colors.text,
    fontWeight: "700",
  },
  dangerButton: {
    borderColor: theme.colors.danger,
  },
  dangerText: {
    color: theme.colors.danger,
  },
  list: {
    gap: theme.spacing.sm,
  },
  section: {
    gap: theme.spacing.md,
  },
  status: {
    ...theme.typography.body,
    color: theme.colors.textMuted,
  },
});
