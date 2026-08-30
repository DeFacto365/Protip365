# ProTip365 — Google Play App Content Walkthrough

**Owner action:** Complete these forms in the live Google Play Console for the V4 app, package `com.defacto365.protip365`.

**Source of truth:** `Docs/PLAY_DATA_SAFETY.md`. Its EAS Update disclosures supersede the older “nothing leaves the device” wording in Section 6 of `Docs/PLAY_SUBMISSION.md`.

> Google changes Play Console labels and menu locations. If a label differs, follow the closest equivalent and preserve the answers below. Save each form as a draft first, then compare the generated summary with this walkthrough before submitting it.

## Before you start

1. Sign in to [Google Play Console](https://play.google.com/console).
2. Open the V4 ProTip365 app with package `com.defacto365.protip365`.
3. In the left navigation, open **Policy and programs → App content**. In some layouts, **App content** appears directly under **Policy**.
4. Work through items A–E below. Do not copy answers from an old V3 app entry.

## A. Data Safety

### Open the form

1. On **App content**, find **Data safety**.
2. Select **Start**. If a draft already exists, select **Manage**.
3. Read the overview, then select **Next** until the collection questions appear.

### Data collection and security

Choose these exact answers:

| Play Console question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes** |
| Is all user data collected by your app encrypted in transit? | **Yes** |
| Does the app provide a way for users to request deletion? | **No** |
| Independent security review | **No**, unless the owner has completed a qualifying review not recorded in this repository |

The deletion answer remains **No** until Expo confirms a working end-user deletion process for EAS Update installation tokens and metrics. The app’s local erase function does not delete Expo-held technical data.

“Collect or share” is **Yes** because Expo collects these technical data types for the app. Each individual type is still **Shared: No** because Expo is acting as the app’s service provider.

Select **Next**.

### Select the four collected data types

Tick only these entries:

1. **App activity → App interactions**
2. **App info and performance → Crash logs**
3. **App info and performance → Diagnostics**
4. **Device or other IDs**

Do not select financial information, personal information, files and documents, or any other type. User-entered records stay on the device, and user-initiated sharing through the OS share sheet is not developer collection or sharing.

Select **Next**.

### Complete each data-type card

Open each selected type and enter the following. If Play asks about “sharing,” choose **No** for all four because Expo acts as a service provider.

| Data type | Collected | Shared | Processed ephemerally | Required or optional | Purpose |
|---|---|---|---|---|---|
| **App interactions** | **Yes** | **No** | **No** | **Required / collected automatically** | **Analytics** |
| **Crash logs** | **Yes** | **No** | **No** | **Required / collected automatically** | **App functionality** and **Analytics** |
| **Diagnostics** | **Yes** | **No** | **No** | **Required / collected automatically** | **App functionality** and **Analytics** |
| **Device or other IDs** | **Yes** | **No** | **No** | **Required / collected automatically** | **App functionality** and **Analytics** |

Reason for all four: EAS Update sends limited technical data to Expo over HTTPS to deliver and measure updates. This includes the device operating system, a randomized installation token, update adoption, and failed-install or early-crash diagnostics. It does not include employer names, shifts, schedules, wages, tips, sales, payouts, notes, CSV files, backups, passcodes, or biometric data.

### Review and save

1. Select **Next** to open the Data Safety preview.
2. Confirm the preview says data is encrypted in transit and shows only the four types above.
3. Confirm none of the four types is shown as shared.
4. Save the form as a draft.
5. For the current submission, keep the deletion answer **No** unless the owner obtains and documents a working Expo deletion process. The form can be submitted with **No**; launch-checklist item G may support a future change to this answer.

## B. Content rating questionnaire

### Open and identify the questionnaire

1. Return to **App content**.
2. Find **Content ratings**, then select **Start** or **Manage**.
3. If Play asks for an email address, enter an owner-controlled address that can receive IARC rating notices. This operational value is not specified in the repository.
4. Choose **All Other App Types**.
5. Choose **Productivity** when a category is requested.

### Answer the questionnaire

Choose these exact content answers:

| Topic | Answer |
|---|---|
| Violence or graphic content | **No / None** |
| Sexual content or nudity | **No / None** |
| Profanity or crude humor | **No / None** |
| Alcohol, tobacco, or drugs | **No / None** |
| Fear, horror, or disturbing content | **No / None** |
| Gambling, simulated gambling, or real-money contests | **No / None** |
| User-to-user communication or public user-generated content | **No** |
| Location sharing | **No** |
| Sharing personal information with other users | **No** |
| Digital purchases / in-app purchases | **Yes** |
| Ads | **No** |

The app may be used by bartenders, but it does not depict, sell, or encourage alcohol. Private notes and records are not published or exchanged inside the app. Digital purchases are **Yes** because `lifetime_unlock` and the auto-renewing `monthly` subscription are integrated through Google Play Billing.

### Calculate and verify the rating

1. Select **Save**, **Next**, or the closest equivalent until Play offers to calculate the rating.
2. Select **Calculate rating** or **Submit questionnaire**.
3. Review the IARC result before applying it. The expected result is **Everyone / PEGI 3 or the regional equivalent**.
4. Apply or save the rating only if the generated certificate matches the answers above. A different result needs review before submission.

The IARC content rating measures what appears in the app. The separate **18 and over** target-audience declaration describes whom the product is intended for, so these two results are not contradictory.

## C. Target audience and content

1. Return to **App content**.
2. Find **Target audience and content**, then select **Start** or **Manage**.
3. On **Target age groups**, select **18 and over** only. Do not select a child-inclusive age range.
4. Select **Next**.
5. For **Designed to appeal to children**, choose **No**.
6. If Play separately asks whether the app is primarily child-directed, choose **No**.
7. Do not opt into the Families program or a Families badge.
8. Do not enable a separate **Restrict Minor Access** control unless the owner intentionally decides to block all under-18 discovery, installation, purchases, and renewals.
9. Review the summary, then save it as a draft before submitting.

## D. Ads declaration

1. Return to **App content**.
2. Find **Ads**, then select **Start** or **Manage**.
3. Choose **No, my app does not contain ads**.
4. Save the declaration.

The current app has no advertising SDK and no ad placement.

## E. Financial features declaration

1. Return to **App content**.
2. Find **Financial features**, then select **Start** or **Manage**.
3. Choose **My app doesn't provide any financial features**.
4. Do not select banking, loans, earned-wage access, payments or transfers, wallets, trading, credit monitoring, insurance, financial advice, or any other listed feature.
5. Select **Next**, review the summary, and save the declaration.

ProTip365 is a personal productivity and record-keeping app. User-controlled earnings and deduction estimates are not payroll, tax advice, or a regulated financial product. Google Play Billing purchases unlock app access and do not make ProTip365 a financial service.

## Final owner review

Before submitting A–E, confirm the Play-generated summaries show:

- Data Safety: **Yes**, four technical data types only, encrypted in transit, not shared, and no verified deletion-request path.
- Content rating: all content risks **No / None**, digital purchases **Yes**, ads **No**.
- Target audience: **18 and over** only; not designed for children.
- Ads: **No ads**.
- Financial features: **None**.

If Play displays a materially different question, stop and compare it with `Docs/PLAY_DATA_SAFETY.md` rather than guessing.
