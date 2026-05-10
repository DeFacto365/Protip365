import { describe, expect, it, vi } from "vitest";
import { buildDeletionRequestEmail, complianceLinks, requestAccountDeletion } from "./accountLifecycle";

describe("accountLifecycle", () => {
  it("defines support, privacy, and terms links", () => {
    expect(complianceLinks.map((link) => link.key)).toEqual(["support", "privacy", "terms"]);
  });

  it("builds account deletion request email", () => {
    expect(buildDeletionRequestEmail("user@example.com")).toContain("user%40example.com");
  });

  it("clears local data and opens deletion request", async () => {
    const clearLocalData = vi.fn(() => Promise.resolve());
    const openUrl = vi.fn(() => Promise.resolve());

    await expect(
      requestAccountDeletion({
        clearLocalData,
        openUrl,
        userEmail: "user@example.com",
      }),
    ).resolves.toMatchObject({ ok: true });

    expect(clearLocalData).toHaveBeenCalledOnce();
    expect(openUrl).toHaveBeenCalledWith(expect.stringContaining("account%20deletion"));
  });

  it("returns user-safe failure and log message", async () => {
    const result = await requestAccountDeletion({
      clearLocalData: vi.fn(() => Promise.reject(new Error("storage unavailable"))),
      openUrl: vi.fn(),
    });

    expect(result).toMatchObject({
      logMessage: "storage unavailable",
      ok: false,
    });
  });
});
