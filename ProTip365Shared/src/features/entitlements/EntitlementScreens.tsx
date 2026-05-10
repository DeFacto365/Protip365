import { StyleSheet, Text, View } from "react-native";
import { AppScaffold } from "../../components/AppScaffold";
import { theme } from "../../theme";
import { freeFeatureLabels, premiumFeatureLabels } from "./entitlements";
import { getSandboxProducts, simulateSandboxPurchase } from "../subscriptions/subscriptionSandbox";
import { mapStoreStateToEntitlement, refreshSubscriptionState } from "../subscriptions/subscriptionStatus";

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
  const products = getSandboxProducts("ios");
  const trialResult = simulateSandboxPurchase({
    outcome: "success",
    productId: "protip365_premium_monthly",
  });
  const refreshed = refreshSubscriptionState(
    {
      expiresAt: "2026-06-01T00:00:00.000Z",
      productId: "protip365_premium_monthly",
      state: "trial",
    },
    new Date().toISOString(),
  );

  return (
    <AppScaffold eyebrow="Premium" title="Upgrade when you need more than logging">
      <View style={styles.card}>
        <Text style={styles.title}>Free keeps the core habit open</Text>
        <FeatureList items={freeFeatureLabels()} />
      </View>

      <View style={styles.card}>
        <Text style={styles.title}>Premium adds analysis and records</Text>
        <FeatureList items={premiumFeatureLabels()} />
        <Text style={styles.body}>Start the 7-day trial after you have logged a few shifts. Core logging stays available without upgrading.</Text>
      </View>
      <View style={styles.card}>
        <Text style={styles.title}>Sandbox products</Text>
        <FeatureList items={products.map((product) => `${product.title} ${product.priceLabel}`)} />
        <Text style={styles.body}>Local sandbox success result: {trialResult.status}</Text>
        <Text style={styles.body}>Current entitlement model: {mapStoreStateToEntitlement(refreshed)}</Text>
      </View>
    </AppScaffold>
  );
}

export function SubscriptionStatusCard() {
  return (
    <View style={styles.card}>
      <Text style={styles.title}>Plan</Text>
      <Text style={styles.body}>Free plan active. Premium is only needed for advanced reports, export, sync, and reconciliation.</Text>
    </View>
  );
}

const styles = StyleSheet.create({
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
  list: {
    gap: theme.spacing.sm,
  },
  title: {
    ...theme.typography.sectionTitle,
    color: theme.colors.text,
  },
});
