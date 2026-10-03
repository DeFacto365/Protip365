import { StyleSheet, Text, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { theme } from "../theme";

type SetupErrorScreenProps = {
  missingKeys: string[];
};

export function SetupErrorScreen({ missingKeys }: SetupErrorScreenProps) {
  return (
    <SafeAreaView style={styles.safeArea}>
      <View accessible accessibilityRole="alert" style={styles.card}>
        <Text style={styles.title}>Supabase config required</Text>
        <Text style={styles.body}>
          Add these values to `ProTip365Shared/.env.local`, then restart Expo.
        </Text>
        <View style={styles.keyList}>
          {missingKeys.map((key) => (
            <Text key={key} style={styles.key}>
              {key}
            </Text>
          ))}
        </View>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    alignItems: "center",
    backgroundColor: theme.colors.background,
    flex: 1,
    justifyContent: "center",
    padding: theme.spacing.xl,
  },
  card: {
    ...theme.cards,
    gap: theme.spacing.md,
    width: "100%",
  },
  title: {
    ...theme.typography.screenTitle,
    color: theme.colors.text,
  },
  body: {
    ...theme.typography.body,
    color: theme.colors.textMuted,
  },
  keyList: {
    gap: theme.spacing.sm,
  },
  key: {
    color: theme.colors.danger,
    fontSize: 15,
    fontWeight: "700",
    lineHeight: 21,
  },
});
