import { createContext, ReactNode, useContext, useEffect, useMemo, useState } from "react";
import { Session } from "@supabase/supabase-js";
import { getSupabaseClient } from "../lib/supabase";

type AuthState = {
  isConfigured: boolean;
  isLoading: boolean;
  isSignedIn: boolean;
  session: Session | null;
};

const AuthContext = createContext<AuthState>({
  isConfigured: false,
  isLoading: false,
  isSignedIn: false,
  session: null,
});

type AuthProviderProps = {
  children: ReactNode;
};

export function AuthProvider({ children }: AuthProviderProps) {
  const [session, setSession] = useState<Session | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const supabase = getSupabaseClient();

  useEffect(() => {
    if (!supabase) {
      setIsLoading(false);
      return;
    }

    let mounted = true;

    supabase.auth.getSession().then(({ data }) => {
      if (mounted) {
        setSession(data.session);
        setIsLoading(false);
      }
    });

    const { data } = supabase.auth.onAuthStateChange((_event, nextSession) => {
      setSession(nextSession);
      setIsLoading(false);
    });

    return () => {
      mounted = false;
      data.subscription.unsubscribe();
    };
  }, [supabase]);

  const value = useMemo(
    () => ({
      isConfigured: Boolean(supabase),
      isLoading,
      isSignedIn: Boolean(session),
      session,
    }),
    [isLoading, session, supabase],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  return useContext(AuthContext);
}
