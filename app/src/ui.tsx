import React, { useState } from "react";
import {
  StyleSheet,
  Text,
  View,
  Pressable,
  TextInput,
  Switch,
  Platform,
} from "react-native";
import Svg, { Path } from "react-native-svg";
export const C = {
  bg: "#FAF8F3",
  surface: "#FFFEFB",
  paper: "#F1EEE8",
  ink: "#3F2A22",
  ink2: "#6B564C",
  ink3: "#8C7D74",
  line: "#E7E2D8",
  sage: "#8A9C7D",
  soft: "#E0E5D6",
  green: "#5B6E4F",
  clay: "#A67B65",
  blush: "#F0E2D8",
  sand: "#D9D6C8",
};
export function Txt({
  children,
  kind = "body",
  style,
  ...props
}: React.ComponentProps<typeof Text> & {
  kind?: "body" | "title" | "display" | "section" | "small" | "eyebrow";
}) {
  return (
    <Text {...props} style={[s.text, s[kind], style]}>
      {children}
    </Text>
  );
}
export function Button({
  label,
  onPress,
  secondary = false,
  disabled = false,
  small = false,
}: {
  label: string;
  onPress: () => void;
  secondary?: boolean;
  disabled?: boolean;
  small?: boolean;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ disabled }}
      disabled={disabled}
      onPress={onPress}
      style={({ pressed }) => [
        s.button,
        secondary && s.secondary,
        small && { minHeight: 44 },
        (pressed || disabled) && { opacity: 0.65 },
      ]}
    >
      <Txt
        style={{
          color: secondary ? C.ink : C.bg,
          textAlign: "center",
          fontFamily: "WorkSans_500Medium",
        }}
      >
        {label}
      </Txt>
    </Pressable>
  );
}
export function Field({
  label,
  value,
  onChange,
  money = false,
  hint,
  multiline = false,
  onBlur,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  money?: boolean;
  hint?: string;
  multiline?: boolean;
  onBlur?: () => void;
}) {
  const [focused, setFocused] = useState(false);
  return (
    <View style={{ gap: 6 }}>
      <Txt style={s.label}>{label}</Txt>
      <View
        style={[
          s.inputWrap,
          focused && { borderColor: C.green, borderWidth: 2 },
        ]}
      >
        {money && <Txt>$</Txt>}
        <TextInput
          accessibilityLabel={label}
          value={value}
          onFocus={() => setFocused(true)}
          onBlur={() => {
            setFocused(false);
            onBlur?.();
          }}
          onChangeText={onChange}
          keyboardType={money ? "decimal-pad" : "default"}
          inputMode={money ? "decimal" : "text"}
          multiline={multiline}
          style={[s.input, multiline && { minHeight: 88 }]}
          placeholder={money ? "—" : undefined}
          placeholderTextColor={C.ink3}
        />
      </View>
      {!!hint && <Txt kind="small">{hint}</Txt>}
    </View>
  );
}
export function Chips({
  items,
  value,
  onChange,
}: {
  items: { value: string; label: string }[];
  value: string;
  onChange: (v: string) => void;
}) {
  return (
    <View style={s.wrap}>
      {items.map((i) => (
        <Pressable
          key={i.value}
          accessibilityRole="radio"
          accessibilityState={{ checked: i.value === value }}
          aria-checked={i.value === value}
          onPress={() => onChange(i.value)}
          style={[
            s.chip,
            i.value === value && { backgroundColor: C.ink, borderColor: C.ink },
          ]}
        >
          <Txt
            style={{ fontSize: 14, color: i.value === value ? C.bg : C.ink }}
          >
            {i.label}
          </Txt>
        </Pressable>
      ))}
    </View>
  );
}
export const Card = ({
  children,
  tint,
  style,
}: React.PropsWithChildren<{ tint?: string; style?: any }>) => (
  <View
    style={[s.card, tint && { backgroundColor: tint, borderWidth: 0 }, style]}
  >
    {children}
  </View>
);
export function Toggle({
  label,
  value,
  onChange,
  hint,
}: {
  label: string;
  value: boolean;
  onChange: (v: boolean) => void;
  hint?: string;
}) {
  return (
    <View style={s.row}>
      <View style={{ flex: 1 }}>
        <Txt>{label}</Txt>
        {!!hint && <Txt kind="small">{hint}</Txt>}
      </View>
      <Switch
        accessibilityLabel={label}
        value={value}
        onValueChange={onChange}
        trackColor={{ true: C.sage }}
        thumbColor={C.surface}
      />
    </View>
  );
}
export function Logo({ size = 44 }: { size?: number }) {
  return (
    <View
      accessibilityLabel="ProTip365"
      style={{
        width: size,
        height: size,
        borderRadius: size / 4,
        backgroundColor: C.sage,
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      <Txt
        style={{
          fontFamily: "Fraunces_600SemiBold",
          fontSize: size * 0.8,
          lineHeight: size,
          color: C.surface,
        }}
      >
        p.
      </Txt>
    </View>
  );
}
export function Leaf() {
  return (
    <Svg
      width="90"
      height="105"
      viewBox="0 0 90 110"
      style={{ position: "absolute", right: 5, top: 5, opacity: 0.6 }}
    >
      <Path
        d="M24 98C48 73 56 39 59 12"
        fill="none"
        stroke="#C3CDB9"
        strokeWidth="2"
      />
      <Path
        d="M43 76C13 73 9 49 10 40C36 39 48 54 43 76ZM51 58C79 55 89 33 83 26C57 28 48 42 51 58ZM56 36C34 32 27 16 30 6C52 8 60 20 56 36ZM59 20C75 17 78 6 75 0C62 2 56 9 59 20Z"
        fill="#C3CDB9"
      />
    </Svg>
  );
}
export const s = StyleSheet.create({
  text: {
    fontFamily: "WorkSans_400Regular",
    color: C.ink,
    fontVariant: ["tabular-nums"],
  },
  body: { fontSize: 16, lineHeight: 24 },
  title: { fontFamily: "Fraunces_500Medium", fontSize: 28, lineHeight: 35 },
  display: { fontFamily: "Fraunces_500Medium", fontSize: 52, lineHeight: 65 },
  section: { fontFamily: "Fraunces_500Medium", fontSize: 22, lineHeight: 29 },
  small: { fontSize: 13, lineHeight: 19, color: C.ink2 },
  eyebrow: {
    fontFamily: "WorkSans_600SemiBold",
    fontSize: 11,
    letterSpacing: 1.7,
    color: C.green,
    lineHeight: 17,
  },
  button: {
    backgroundColor: C.ink,
    borderRadius: 99,
    minHeight: 58,
    paddingVertical: 15,
    paddingHorizontal: 20,
    justifyContent: "center",
  },
  secondary: { backgroundColor: C.paper, borderWidth: 1, borderColor: C.line },
  inputWrap: {
    backgroundColor: C.surface,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: C.line,
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 14,
    minHeight: 56,
  },
  input: {
    flex: 1,
    minWidth: 0,
    fontFamily: "WorkSans_400Regular",
    fontSize: 16,
    color: C.ink,
    paddingVertical: 14,
    ...Platform.select({ web: { outlineStyle: "none" } as any }),
  },
  label: { fontFamily: "WorkSans_500Medium", fontSize: 14 },
  wrap: { flexDirection: "row", flexWrap: "wrap", gap: 8 },
  chip: {
    borderRadius: 99,
    borderWidth: 1.5,
    borderColor: C.line,
    minHeight: 44,
    paddingHorizontal: 14,
    paddingVertical: 10,
    justifyContent: "center",
  },
  card: {
    backgroundColor: C.surface,
    borderWidth: 1,
    borderColor: C.line,
    borderRadius: 22,
    padding: 20,
    gap: 14,
  },
  row: { flexDirection: "row", alignItems: "center", gap: 12 },
  split: { flexDirection: "row", gap: 12 },
  screen: { flex: 1, backgroundColor: C.bg },
  content: { padding: 20, gap: 22, paddingBottom: 30 },
  nav: {
    flexDirection: "row",
    borderTopWidth: 1,
    borderColor: C.line,
    backgroundColor: C.bg,
    alignItems: "center",
    paddingHorizontal: 6,
  },
  navItem: {
    flex: 1,
    minHeight: 64,
    alignItems: "center",
    justifyContent: "center",
    gap: 3,
  },
  navPlus: {
    width: 60,
    height: 60,
    borderRadius: 30,
    backgroundColor: C.ink,
    borderWidth: 4,
    borderColor: C.bg,
    alignItems: "center",
    justifyContent: "center",
    marginTop: -20,
  },
  listItem: { paddingVertical: 14, borderBottomWidth: 1, borderColor: C.line },
  error: { color: "#8F3F2B" },
  dot: { width: 10, height: 10, borderRadius: 5 },
  toolbar: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    padding: 20,
    gap: 16,
  },
});
