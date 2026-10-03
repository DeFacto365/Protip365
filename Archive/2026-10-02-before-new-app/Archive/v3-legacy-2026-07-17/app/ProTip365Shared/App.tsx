import "react-native-gesture-handler";
import { StatusBar } from "expo-status-bar";
import { SafeAreaProvider } from "react-native-safe-area-context";
import { AuthProvider } from "./src/auth/AuthProvider";
import { SetupErrorScreen } from "./src/components/SetupErrorScreen";
import { getSupabaseConfig } from "./src/config/env";
import { AppNavigator } from "./src/navigation/AppNavigator";

export default function App() {
  const supabaseConfig = getSupabaseConfig();

  return (
    <SafeAreaProvider>
      {supabaseConfig.ok ? (
        <AuthProvider>
          <AppNavigator />
        </AuthProvider>
      ) : (
        <SetupErrorScreen missingKeys={supabaseConfig.missingKeys} />
      )}
      <StatusBar style="dark" />
    </SafeAreaProvider>
  );
}
