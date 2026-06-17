import { AppScaffold, Card } from "../components/AppScaffold";
import { strings } from "./shared/screenShared";

export function OnboardingScreen() {
  return (
    <AppScaffold title={strings.screens.onboarding}>
      <Card body="Create employers, add shifts, then record income against those shifts." title="Welcome" />
    </AppScaffold>
  );
}

export function PaywallScreen() {
  return (
    <AppScaffold title={strings.screens.paywall}>
      <Card body="Subscription controls will be restored after the core waiter workflow is complete." title={strings.screens.paywall} />
    </AppScaffold>
  );
}
