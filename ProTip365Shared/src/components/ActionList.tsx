import { ReactNode } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { ChevronRight } from "lucide-react-native";
import { theme } from "../theme";

type ActionItem = {
  label: string;
  onPress: () => void;
  icon: ReactNode;
};

type ActionListProps = {
  items: ActionItem[];
};

export function ActionList({ items }: ActionListProps) {
  return (
    <View style={styles.list}>
      {items.map((item) => (
        <Pressable
          accessibilityLabel={item.label}
          accessibilityRole="button"
          hitSlop={8}
          key={item.label}
          onPress={item.onPress}
          style={({ pressed }) => [styles.item, pressed && styles.itemPressed]}
        >
          <View style={styles.icon}>{item.icon}</View>
          <Text style={styles.label}>{item.label}</Text>
          <ChevronRight color={theme.colors.textMuted} size={theme.navigation.tabIconSize} />
        </Pressable>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  list: {
    gap: theme.spacing.sm,
  },
  item: {
    alignItems: "center",
    backgroundColor: theme.colors.surface,
    borderColor: theme.colors.border,
    borderRadius: theme.radius.md,
    borderWidth: 1,
    flexDirection: "row",
    gap: theme.spacing.md,
    minHeight: 52,
    paddingHorizontal: theme.spacing.lg,
    paddingVertical: theme.spacing.md,
  },
  itemPressed: {
    backgroundColor: theme.colors.surfaceMuted,
  },
  icon: {
    alignItems: "center",
    backgroundColor: theme.colors.primaryMuted,
    borderRadius: theme.radius.sm,
    height: 34,
    justifyContent: "center",
    width: 34,
  },
  label: {
    ...theme.typography.body,
    color: theme.colors.text,
    flex: 1,
    fontWeight: "700",
  },
});
