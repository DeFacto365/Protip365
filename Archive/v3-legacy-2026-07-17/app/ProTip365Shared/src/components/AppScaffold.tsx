import { ReactNode } from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { theme } from "../theme";

type AppScaffoldProps = {
  title: string;
  eyebrow?: string;
  children: ReactNode;
};

export function AppScaffold({ title, eyebrow, children }: AppScaffoldProps) {
  return (
    <SafeAreaView edges={["top"]} style={styles.safeArea}>
      <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
        {eyebrow ? <Text style={styles.eyebrow}>{eyebrow}</Text> : null}
        <Text accessibilityRole="header" style={styles.title}>
          {title}
        </Text>
        {children}
      </ScrollView>
    </SafeAreaView>
  );
}

type CardProps = {
  title: string;
  body: string;
};

export function Card({ title, body }: CardProps) {
  return (
    <View accessible accessibilityLabel={`${title}. ${body}`} style={styles.card}>
      <Text style={styles.cardTitle}>{title}</Text>
      <Text style={styles.body}>{body}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    backgroundColor: theme.colors.background,
    flex: 1,
  },
  content: {
    gap: theme.spacing.lg,
    padding: theme.spacing.xl,
    paddingBottom: theme.spacing.xxxl,
  },
  eyebrow: {
    ...theme.typography.label,
    color: theme.colors.primary,
    textTransform: "uppercase",
  },
  title: {
    ...theme.typography.screenTitle,
    color: theme.colors.text,
  },
  card: {
    ...theme.cards,
    gap: theme.spacing.sm,
  },
  cardTitle: {
    ...theme.typography.sectionTitle,
    color: theme.colors.text,
  },
  body: {
    ...theme.typography.body,
    color: theme.colors.textMuted,
  },
});
