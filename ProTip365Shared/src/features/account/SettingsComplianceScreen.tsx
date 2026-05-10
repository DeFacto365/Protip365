import { ReactNode, useState } from "react";
import { Linking, Pressable, StyleSheet, Text, View } from "react-native";
import { clearShiftRecords } from "../../storage/shiftRepository";
import { clearSubscription } from "../../storage/subscriptionRepository";
import { theme } from "../../theme";
import { complianceLinks, requestAccountDeletion } from "./accountLifecycle";

async function clearLocalAccountData() {
  await Promise.all([clearShiftRecords(), clearSubscription()]);
}

export function SettingsComplianceSection() {
  const [status, setStatus] = useState<string | null>(null);
  const [confirmingDeletion, setConfirmingDeletion] = useState(false);
  const [hourlyRate, setHourlyRate] = useState("$16.00");
  const [employer, setEmployer] = useState("Default restaurant");
  const [tipOut, setTipOut] = useState("3% of sales");

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
    if (!confirmingDeletion) {
      setConfirmingDeletion(true);
      setStatus("Confirm account deletion before local data is cleared or a deletion request opens.");
      return;
    }

    const result = await requestAccountDeletion({
      clearLocalData: clearLocalAccountData,
      openUrl: Linking.openURL,
    });

    if (!result.ok) {
      console.warn("ProTip365 account deletion request failed", result.logMessage);
    }
    setStatus(result.message);
    setConfirmingDeletion(false);
  }

  return (
    <View style={styles.section}>
      <SettingsGroup title="Account" body="Signed in account and local account actions.">
        <SettingRow label="Account status" value="Local app profile" />
        <SettingRow label="Data storage" value="Secure local storage" />
      </SettingsGroup>

      <SettingsGroup title="Subscription" body="Manage plan status and store purchase actions.">
        <SettingRow label="Current plan" value="Free" />
        <SettingRow label="Premium includes" value="Reports, export, backup" />
      </SettingsGroup>

      <SettingsGroup title="Work defaults" body="Used to speed up daily shift entry.">
        <EditableRow label="Default hourly rate" onChange={setHourlyRate} value={hourlyRate} />
        <EditableRow label="Default employer" onChange={setEmployer} value={employer} />
        <EditableRow label="Default tip-out" onChange={setTipOut} value={tipOut} />
      </SettingsGroup>

      <SettingsGroup title="App preferences" body="Launch defaults for the shared mobile app.">
        <SettingRow label="Currency" value="Device locale" />
        <SettingRow label="Language" value="Device language" />
        <SettingRow label="Week starts" value="Sunday" />
      </SettingsGroup>

      <SettingsGroup title="Support" body="Get help or request account deletion.">
        {complianceLinks
          .filter((link) => link.key === "support")
          .map((link) => (
            <Pressable accessibilityRole="link" key={link.key} onPress={() => openLink(link.url)} style={styles.button}>
              <Text style={styles.buttonText}>{link.label}</Text>
            </Pressable>
          ))}
        <Pressable accessibilityRole="button" onPress={handleDeletionRequest} style={[styles.button, styles.dangerButton]}>
          <Text style={[styles.buttonText, styles.dangerText]}>{confirmingDeletion ? "Confirm deletion request" : "Request account deletion"}</Text>
        </Pressable>
        {confirmingDeletion ? (
          <Pressable accessibilityRole="button" onPress={() => setConfirmingDeletion(false)} style={styles.button}>
            <Text style={styles.buttonText}>Cancel deletion</Text>
          </Pressable>
        ) : null}
      </SettingsGroup>

      <SettingsGroup title="Legal" body="Store review links.">
        {complianceLinks
          .filter((link) => link.key !== "support")
          .map((link) => (
            <Pressable accessibilityRole="link" key={link.key} onPress={() => openLink(link.url)} style={styles.button}>
              <Text style={styles.buttonText}>{link.label}</Text>
            </Pressable>
          ))}
      </SettingsGroup>

      {status ? <Text style={styles.status}>{status}</Text> : null}
    </View>
  );
}

function SettingsGroup({ body, children, title }: { body: string; children: ReactNode; title: string }) {
  return (
    <View style={styles.group}>
      <View>
        <Text style={styles.groupTitle}>{title}</Text>
        <Text style={styles.groupBody}>{body}</Text>
      </View>
      <View style={styles.list}>{children}</View>
    </View>
  );
}

function SettingRow({ label, value }: { label: string; value: string }) {
  return (
    <View style={styles.row}>
      <Text style={styles.rowLabel}>{label}</Text>
      <Text style={styles.rowValue}>{value}</Text>
    </View>
  );
}

function EditableRow({ label, onChange, value }: { label: string; onChange: (value: string) => void; value: string }) {
  return (
    <Pressable accessibilityRole="button" onPress={() => onChange(value === "Not set" ? "" : "Not set")} style={styles.row}>
      <Text style={styles.rowLabel}>{label}</Text>
      <Text style={styles.rowValue}>{value}</Text>
    </Pressable>
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
  group: {
    ...theme.cards,
    gap: theme.spacing.md,
  },
  groupBody: {
    ...theme.typography.body,
    color: theme.colors.textMuted,
  },
  groupTitle: {
    ...theme.typography.sectionTitle,
    color: theme.colors.text,
  },
  list: {
    gap: theme.spacing.sm,
  },
  row: {
    alignItems: "center",
    backgroundColor: theme.colors.surfaceMuted,
    borderRadius: theme.radius.md,
    flexDirection: "row",
    justifyContent: "space-between",
    minHeight: 48,
    paddingHorizontal: theme.spacing.md,
  },
  rowLabel: {
    ...theme.typography.body,
    color: theme.colors.text,
    flex: 1,
  },
  rowValue: {
    ...theme.typography.label,
    color: theme.colors.textMuted,
    flex: 1,
    textAlign: "right",
  },
  section: {
    gap: theme.spacing.md,
  },
  status: {
    ...theme.typography.body,
    color: theme.colors.textMuted,
  },
});
