import { useState } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { AppScaffold } from "../../components/AppScaffold";
import { theme } from "../../theme";
import { freeFeatureLabels, premiumFeatureLabels } from "./entitlements";

function FeatureList({ items }: { items: string[] }) {
  return (
    <View style={styles.list}>
      {items.map((item) => (
        <Text key={item} style={styles.item}>
          {item}
        </Text>
      ))}
    </View>
  );
}

export function PaywallScreen() {
  const [status, setStatus] = useState<string | null>(null);

  return (
    <AppScaffold eyebrow="Premium" title="Keep every shift, report, and export in one place">
      <View style={styles.hero}>
        <Text style={styles.heroText}>Core shift logging stays free. Upgrade when you need full history, reports, export, and backup.</Text>
      </View>

      <View style={styles.planGrid}>
        <View style={styles.planCard}>
          <Text style={styles.title}>Free</Text>
          <Text style={styles.price}>$0</Text>
          <FeatureList items={freeFeatureLabels()} />
        </View>

        <View style={[styles.planCard, styles.premiumCard]}>
          <Text style={styles.title}>Premium</Text>
          <Text style={styles.price}>7-day trial</Text>
          <FeatureList items={premiumFeatureLabels()} />
        </View>
      </View>

      <View style={styles.actionCard}>
        <Pressable accessibilityRole="button" onPress={() => setStatus("Purchase setup is ready for store product wiring.")} style={styles.primaryButton}>
          <Text style={styles.primaryButtonText}>Start free trial</Text>
        </Pressable>
        <Pressable accessibilityRole="button" onPress={() => setStatus("Restore purchase checked. No active purchase found on this device.")} style={styles.secondaryButton}>
          <Text style={styles.secondaryButtonText}>Restore purchases</Text>
        </Pressable>
        {status ? <Text style={styles.status}>{status}</Text> : null}
      </View>

      <Text style={styles.legal}>Subscription renews automatically after trial unless canceled. Manage or cancel in your App Store or Google Play account. Terms and privacy apply.</Text>
    </AppScaffold>
  );
}

export function SubscriptionStatusCard() {
  return (
    <View style={styles.card}>
      <Text style={styles.title}>Plan</Text>
      <Text style={styles.body}>Free plan active. Premium adds full history, weekly/monthly/yearly reports, export, and backup.</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  actionCard: {
    ...theme.cards,
    gap: theme.spacing.md,
  },
  body: {
    ...theme.typography.body,
    color: theme.colors.textMuted,
  },
  card: {
    ...theme.cards,
    gap: theme.spacing.md,
  },
  item: {
    ...theme.typography.body,
    color: theme.colors.text,
  },
  hero: {
    ...theme.cards,
    backgroundColor: theme.colors.primaryMuted,
    borderColor: theme.colors.primary,
  },
  heroText: {
    ...theme.typography.body,
    color: theme.colors.text,
  },
  legal: {
    ...theme.typography.label,
    color: theme.colors.textMuted,
  },
  list: {
    gap: theme.spacing.sm,
  },
  planCard: {
    ...theme.cards,
    flex: 1,
    gap: theme.spacing.md,
    minWidth: 0,
  },
  planGrid: {
    gap: theme.spacing.md,
  },
  premiumCard: {
    borderColor: theme.colors.primary,
  },
  price: {
    ...theme.typography.screenTitle,
    color: theme.colors.primary,
  },
  primaryButton: {
    alignItems: "center",
    backgroundColor: theme.colors.primary,
    borderRadius: theme.radius.md,
    justifyContent: "center",
    minHeight: 52,
    paddingHorizontal: theme.spacing.lg,
  },
  primaryButtonText: {
    ...theme.typography.label,
    color: "#FFFFFF",
    fontSize: 16,
  },
  secondaryButton: {
    alignItems: "center",
    backgroundColor: theme.colors.surface,
    borderColor: theme.colors.border,
    borderRadius: theme.radius.md,
    borderWidth: 1,
    justifyContent: "center",
    minHeight: 48,
    paddingHorizontal: theme.spacing.lg,
  },
  secondaryButtonText: {
    ...theme.typography.label,
    color: theme.colors.text,
  },
  status: {
    ...theme.typography.body,
    color: theme.colors.textMuted,
  },
  title: {
    ...theme.typography.sectionTitle,
    color: theme.colors.text,
  },
});
