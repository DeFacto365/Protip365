import { useCallback, useEffect, useState } from "react";
import { ActivityIndicator, Alert, Linking, Pressable, StyleSheet, Text, TextInput, View } from "react-native";
import { CommonActions, useNavigation } from "@react-navigation/native";
import { SafeAreaView } from "react-native-safe-area-context";
import { useAuth } from "../auth/AuthProvider";
import { getSupabaseClient } from "../lib/supabase";
import { theme } from "../theme";

type RecoveryState = "checking" | "ready" | "missing-session" | "error";

function getUrlParams(url: string) {
  const params = new URLSearchParams();
  const [, query = ""] = url.split("?");
  const [queryPart, hashPart = ""] = query.split("#");
  const hash = url.includes("#") ? url.slice(url.indexOf("#") + 1) : hashPart;

  new URLSearchParams(queryPart).forEach((value, key) => params.set(key, value));
  new URLSearchParams(hash).forEach((value, key) => params.set(key, value));

  return params;
}

export function UpdatePasswordScreen() {
  const navigation = useNavigation();
  const { isSignedIn } = useAuth();
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [status, setStatus] = useState<RecoveryState>("checking");
  const [message, setMessage] = useState("Checking reset link...");
  const [isSaving, setIsSaving] = useState(false);

  const prepareRecoverySession = useCallback(async (url?: string | null) => {
    const supabase = getSupabaseClient();

    if (!supabase) {
      setMessage("Supabase is not configured.");
      setStatus("error");
      return;
    }

    try {
      if (url) {
        const params = getUrlParams(url);
        const accessToken = params.get("access_token");
        const refreshToken = params.get("refresh_token");
        const code = params.get("code");

        if (accessToken && refreshToken) {
          const { error } = await supabase.auth.setSession({
            access_token: accessToken,
            refresh_token: refreshToken,
          });

          if (error) {
            throw error;
          }
        } else if (code) {
          const { error } = await supabase.auth.exchangeCodeForSession(code);

          if (error) {
            throw error;
          }
        }
      }

      const { data, error } = await supabase.auth.getSession();

      if (error) {
        throw error;
      }

      if (!data.session) {
        setMessage("This reset link is expired or incomplete. Request a new password reset email.");
        setStatus("missing-session");
        return;
      }

      setMessage("Enter a new password for your account.");
      setStatus("ready");
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "We could not open this reset link. Request a new password reset email.");
      setStatus("error");
    }
  }, []);

  useEffect(() => {
    Linking.getInitialURL().then(prepareRecoverySession).catch(() => {
      setMessage("We could not read this reset link. Request a new password reset email.");
      setStatus("error");
    });

    const subscription = Linking.addEventListener("url", ({ url }) => {
      prepareRecoverySession(url);
    });

    return () => subscription.remove();
  }, [prepareRecoverySession]);

  async function updatePassword() {
    const supabase = getSupabaseClient();

    if (!supabase) {
      Alert.alert("Setup required", "Supabase is not configured.");
      return;
    }

    if (password.length < 6) {
      Alert.alert("Password too short", "Enter at least 6 characters.");
      return;
    }

    if (password !== confirmPassword) {
      Alert.alert("Passwords do not match", "Enter the same password twice.");
      return;
    }

    setIsSaving(true);

    try {
      const { error } = await supabase.auth.updateUser({ password });

      if (error) {
        throw error;
      }

      Alert.alert("Password updated", "You can continue using ProTip365.");
      navigation.dispatch(
        CommonActions.reset({
          index: 0,
          routes: [{ name: "MainTabs" }],
        }),
      );
    } catch (error) {
      Alert.alert("Update failed", error instanceof Error ? error.message : "Try requesting a new reset link.");
    } finally {
      setIsSaving(false);
    }
  }

  function returnToSignIn() {
    navigation.dispatch(
      CommonActions.reset({
        index: 0,
        routes: [{ name: isSignedIn ? "MainTabs" : "Auth" }],
      }),
    );
  }

  const canSubmit = status === "ready" && !isSaving;

  return (
    <SafeAreaView style={styles.safeArea}>
      <View style={styles.container}>
        <Text style={styles.title}>Update password</Text>
        <Text style={styles.subtitle}>{message}</Text>
        {status === "checking" ? <ActivityIndicator color={theme.colors.primary} size="large" style={styles.loader} /> : null}
        {status === "ready" ? (
          <View style={styles.form}>
            <TextInput
              accessibilityLabel="New password"
              onChangeText={setPassword}
              placeholder="New password"
              placeholderTextColor={theme.colors.textMuted}
              secureTextEntry
              style={styles.input}
              value={password}
            />
            <TextInput
              accessibilityLabel="Confirm new password"
              onChangeText={setConfirmPassword}
              placeholder="Confirm new password"
              placeholderTextColor={theme.colors.textMuted}
              secureTextEntry
              style={styles.input}
              value={confirmPassword}
            />
            <Pressable
              accessibilityRole="button"
              disabled={!canSubmit}
              onPress={updatePassword}
              style={({ pressed }) => [styles.primaryButton, pressed && styles.pressed, !canSubmit && styles.disabled]}
            >
              {isSaving ? <ActivityIndicator color={theme.colors.surface} /> : <Text style={styles.primaryText}>Save password</Text>}
            </Pressable>
          </View>
        ) : (
          <Pressable accessibilityRole="button" onPress={returnToSignIn} style={({ pressed }) => [styles.secondaryButton, pressed && styles.pressed]}>
            <Text style={styles.secondaryText}>{isSignedIn ? "Back to app" : "Back to sign in"}</Text>
          </Pressable>
        )}
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: "center",
    padding: theme.spacing.xl,
  },
  disabled: {
    opacity: 0.7,
  },
  form: {
    gap: theme.spacing.md,
    marginTop: theme.spacing.xl,
  },
  input: {
    backgroundColor: theme.colors.surface,
    borderColor: theme.colors.border,
    borderRadius: theme.radius.md,
    borderWidth: 1,
    color: theme.colors.text,
    fontSize: theme.typography.body.fontSize,
    minHeight: theme.forms.inputHeight,
    paddingHorizontal: theme.spacing.md,
  },
  loader: {
    marginTop: theme.spacing.xl,
  },
  pressed: {
    opacity: 0.85,
  },
  primaryButton: {
    alignItems: "center",
    backgroundColor: theme.colors.primary,
    borderRadius: theme.radius.md,
    justifyContent: "center",
    minHeight: 52,
  },
  primaryText: {
    color: theme.colors.surface,
    fontSize: theme.typography.body.fontSize,
    fontWeight: "800",
  },
  safeArea: {
    backgroundColor: theme.colors.background,
    flex: 1,
  },
  secondaryButton: {
    alignItems: "center",
    marginTop: theme.spacing.xl,
    paddingVertical: theme.spacing.md,
  },
  secondaryText: {
    color: theme.colors.primary,
    fontSize: theme.typography.body.fontSize,
    fontWeight: "700",
  },
  subtitle: {
    color: theme.colors.textMuted,
    fontSize: theme.typography.body.fontSize,
    marginTop: theme.spacing.sm,
    textAlign: "center",
  },
  title: {
    ...theme.typography.title,
    color: theme.colors.text,
    textAlign: "center",
  },
});
