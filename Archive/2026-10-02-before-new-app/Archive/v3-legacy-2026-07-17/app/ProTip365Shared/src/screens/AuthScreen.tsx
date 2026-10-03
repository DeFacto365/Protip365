import { useState } from "react";
import { ActivityIndicator, Alert, Pressable, StyleSheet, Text, TextInput, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { getSupabaseClient } from "../lib/supabase";
import { theme } from "../theme";

export function AuthScreen() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [name, setName] = useState("");
  const [isSignUp, setIsSignUp] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  async function authenticate() {
    const supabase = getSupabaseClient();

    if (!supabase) {
      Alert.alert("Setup required", "Supabase is not configured.");
      return;
    }

    if (!email.trim() || !password) {
      Alert.alert("Missing details", "Enter your email and password.");
      return;
    }

    setIsLoading(true);

    try {
      if (isSignUp) {
        const { error } = await supabase.auth.signUp({
          email: email.trim(),
          options: {
            data: {
              name: name.trim(),
            },
          },
          password,
        });

        if (error) {
          throw error;
        }
      } else {
        const { error } = await supabase.auth.signInWithPassword({
          email: email.trim(),
          password,
        });

        if (error) {
          throw error;
        }
      }
    } catch (error) {
      Alert.alert("Login failed", error instanceof Error ? error.message : "Try again.");
    } finally {
      setIsLoading(false);
    }
  }

  async function resetPassword() {
    const supabase = getSupabaseClient();

    if (!supabase || !email.trim()) {
      Alert.alert("Email required", "Enter your email first.");
      return;
    }

    const { error } = await supabase.auth.resetPasswordForEmail(email.trim(), {
      redirectTo: "protip365://reset-password",
    });

    if (error) {
      Alert.alert("Reset failed", error.message);
      return;
    }

    Alert.alert("Check your email", "Password reset instructions were sent.");
  }

  return (
    <SafeAreaView style={styles.safeArea}>
      <View style={styles.container}>
        <View style={styles.logo}>
          <Text style={styles.logoText}>%</Text>
        </View>
        <Text style={styles.title}>ProTip365</Text>
        <Text style={styles.subtitle}>Track shifts, tips, sales, and real hourly income.</Text>
        <View style={styles.form}>
          {isSignUp ? (
            <TextInput
              accessibilityLabel="Name"
              onChangeText={setName}
              placeholder="Name"
              placeholderTextColor={theme.colors.textMuted}
              style={styles.input}
              value={name}
            />
          ) : null}
          <TextInput
            accessibilityLabel="Email"
            autoCapitalize="none"
            keyboardType="email-address"
            onChangeText={setEmail}
            placeholder="Email"
            placeholderTextColor={theme.colors.textMuted}
            style={styles.input}
            value={email}
          />
          <TextInput
            accessibilityLabel="Password"
            onChangeText={setPassword}
            placeholder="Password"
            placeholderTextColor={theme.colors.textMuted}
            secureTextEntry
            style={styles.input}
            value={password}
          />
          <Pressable
            accessibilityRole="button"
            disabled={isLoading}
            onPress={authenticate}
            style={({ pressed }) => [styles.primaryButton, pressed && styles.pressed, isLoading && styles.disabled]}
          >
            {isLoading ? <ActivityIndicator color={theme.colors.surface} /> : <Text style={styles.primaryText}>{isSignUp ? "Create account" : "Sign in"}</Text>}
          </Pressable>
          {!isSignUp ? (
            <Pressable accessibilityRole="button" onPress={resetPassword}>
              <Text style={styles.link}>Forgot password?</Text>
            </Pressable>
          ) : null}
          <Pressable accessibilityRole="button" onPress={() => setIsSignUp((value) => !value)}>
            <Text style={styles.link}>{isSignUp ? "Already have an account? Sign in" : "New here? Create account"}</Text>
          </Pressable>
        </View>
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
  link: {
    color: theme.colors.primary,
    fontWeight: "700",
    paddingVertical: theme.spacing.sm,
    textAlign: "center",
  },
  logo: {
    alignItems: "center",
    alignSelf: "center",
    backgroundColor: theme.colors.primary,
    borderRadius: theme.radius.lg,
    height: 80,
    justifyContent: "center",
    width: 80,
  },
  logoText: {
    color: theme.colors.surface,
    fontSize: 48,
    fontWeight: "900",
  },
  pressed: {
    opacity: 0.85,
  },
  primaryButton: {
    alignItems: "center",
    backgroundColor: theme.colors.primary,
    borderRadius: theme.radius.md,
    minHeight: 52,
    justifyContent: "center",
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
  subtitle: {
    color: theme.colors.textMuted,
    fontSize: theme.typography.body.fontSize,
    marginTop: theme.spacing.sm,
    textAlign: "center",
  },
  title: {
    ...theme.typography.title,
    color: theme.colors.text,
    marginTop: theme.spacing.lg,
    textAlign: "center",
  },
});
