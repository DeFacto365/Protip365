export type ComplianceLinkKey = "support" | "privacy" | "terms";

export type ComplianceLink = {
  key: ComplianceLinkKey;
  label: string;
  url: string;
};

export const complianceLinks: ComplianceLink[] = [
  {
    key: "support",
    label: "Support",
    url: "mailto:support@protip365.com?subject=ProTip365%20support",
  },
  {
    key: "privacy",
    label: "Privacy policy",
    url: "https://protip365.com/privacy",
  },
  {
    key: "terms",
    label: "Terms",
    url: "https://protip365.com/terms",
  },
];

export type AccountDeletionResult =
  | { ok: true; message: string }
  | { ok: false; message: string; logMessage: string };

export function buildDeletionRequestEmail(userEmail?: string) {
  const encodedUser = encodeURIComponent(userEmail ?? "unknown account");
  return `mailto:support@protip365.com?subject=ProTip365%20account%20deletion&body=Please%20delete%20my%20ProTip365%20account.%0AAccount:%20${encodedUser}`;
}

export async function requestAccountDeletion({
  clearLocalData,
  openUrl,
  userEmail,
}: {
  clearLocalData: () => Promise<void>;
  openUrl: (url: string) => Promise<void>;
  userEmail?: string;
}): Promise<AccountDeletionResult> {
  try {
    await clearLocalData();
    await openUrl(buildDeletionRequestEmail(userEmail));
    return {
      message: "Deletion request prepared. Send the email to complete the request.",
      ok: true,
    };
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown deletion request error";
    return {
      logMessage: message,
      message: "Account deletion could not be started. Contact support from Settings.",
      ok: false,
    };
  }
}
