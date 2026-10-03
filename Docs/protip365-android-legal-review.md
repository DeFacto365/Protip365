# ProTip365: Android release legal review

Reviewed 3 October 2026. This is a product/legal risk review, not a legal opinion or certification of compliance. A qualified lawyer should approve the final terms, particularly consumer protections, age eligibility and international availability.

## Scope and conclusion

Reviewed the published English [Terms of Service](https://www.protip365.com/terms), [Privacy Policy](https://www.protip365.com/privacy) and [Support page](https://www.protip365.com/support) against the planned global Android specification. French and Spanish versions need the same approved substantive changes. The Android source code, release binary, SDK inventory, actual billing configuration and Google Play Console declarations were not audited.

**Do not treat the current policies as ready for a cloud-enabled Android release.** They describe an app with no accounts and strictly device-local data, while the planned specification allows optional Supabase backup. There is also an unresolved age-policy mismatch and an unresolved commercial model.

The contact address has been changed to **info@protip365.com**. This updates the website contact information; it does not establish that the mailbox is configured or monitored.

## Launch blockers and owner decisions

| Priority | Finding | Required decision or evidence |
|---|---|---|
| P0 | Privacy and support promise no accounts, no cloud uploads and device-only storage; the spec includes optional cloud backup. | Confirm whether the initial Android release is strictly local-only or includes cloud accounts. Draft and implement the matching policy before enabling cloud collection. |
| P0 | Product audience includes ages 15–17; privacy describes a working-adult audience. | Set actual eligibility and age handling by launch market. Do not use an app-store content rating as proof of legal consent eligibility. |
| P0 | Exact security promises include encrypted SQLCipher storage and OS-keystore protection. | Verify the shipped Android implementation, backups, exports and SDKs. Planned encryption is not evidence of implemented encryption. |
| P0 | Terms specify a 30-day trial, paid editing and monthly/lifetime options, while the spec requires no employer cap/paywall and free CSV export without fully defining the commercial model. | Approve a complete entitlement matrix, trial behaviour, subscription and lifetime-purchase treatment. Ensure landing copy, paywall, terms and code agree. |
| P0 if accounts launch | Published deletion language assumes there is no account. | Implement discoverable in-app and web account deletion, including cloud records and defined retention exceptions. Google requires both deletion entry points where an app allows in-app account creation. ([Google Play User data policy](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en-GB)) |
| P1 | Legal operator is presented as Defacto365, but entity identity and address were not established by this review. | Confirm the contracting entity’s full legal name, contact details and consistency with store accounts and privacy disclosures. |
| P1 | Broad liability exclusion, a last-12-month payment cap, and continued-use acceptance of changes. | Have counsel test enforceability for consumers and paid lifetime users in the intended markets. |

## Recommended initial release scope

The lowest-complexity path is a genuinely local-first, **local-only initial release**, with no cloud accounts, advertising or new analytics SDKs, and with cloud backup deferred. This is a recommendation, not a decision already made. Verify that platform purchases, update services and support communications are still accurately disclosed even when shift records stay on the device.

If optional cloud backup is required at launch, it needs its own release gate: explicit opt-in, a verified data inventory, processor and region details, deletion and retention workflows, secure authentication, transfer safeguards where applicable, and corresponding store declarations. The GDPR can apply to a provider outside the EU when its offering or monitoring falls within Article 3; the disclosure and processing obligations depend on the actual activity and legal basis. ([GDPR, Articles 3, 13, 17, 28 and 44–46](https://eur-lex.europa.eu/eli/reg/2016/679))

## Privacy wording and implementation

- **Local versus cloud:** Replace absolute “no account/no cloud” claims only when a cloud feature actually exists and the owner approves its scope. Distinguish the default local core from optional synchronized records, credentials and backup metadata.
- **Retention and deletion:** Define what stays on device, what is removed when users erase records, what uninstall does, how user-controlled exports persist, and how support emails are retained. If cloud accounts exist, specify deletion processing and backup-expiration windows using verified operational values, not invented promises.
- **Processors and transfers:** For a cloud release, identify the actual services, data categories, purposes, locations and safeguards. Do not list Supabase merely because it appears in the plan, or promise a region before it is configured.
- **Permissions and SDKs:** Check every network request and library in the shipped build. “No analytics” and “no uploads” must match reality, including crash-reporting or diagnostic SDKs.
- **Privacy-policy completeness:** Google Play requires a public privacy policy and an in-app link, including developer contact information, data handling, security and retention/deletion disclosures. Its prominent-disclosure and consent rules must also be assessed against actual collection. ([Google Play User data policy](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en-GB))
- **Website separation:** The website uses hosting, font requests and a language preference in the legal/demo experience. These should not be described as Android app behaviour. Search Console reporting is distinct from adding an on-site visitor-tracking SDK.

### Conditional draft: storage

Use this only if optional cloud backup is approved and implemented:

> ProTip365’s core shift and tip records are stored on your device. You do not need an account to use the local features. If you choose to enable cloud backup, we process the account information and records needed to provide that feature. Before you enable it, we explain what will be uploaded, why it is needed and how you can disable backup or request deletion. Further details are provided in our Privacy Policy.

This draft must be supplemented with actual providers, retention periods, deletion behaviour and applicable rights. Do not publish it while the policy still states that records are never uploaded.

## Young users and global positioning

“Global” is product positioning, not a representation that every country’s privacy, labour, tax and consumer rules have been addressed. Keep neutral earnings-tracking language and avoid jurisdiction-specific tax thresholds or a claim that the app produces official tax documents.

The 15–30 target audience includes minors. A blanket adult-only statement contradicts that plan; equally, a universal “15+ with parental consent” rule is not a sufficient international compliance strategy. Determine whether consent is the relevant legal basis, which markets are offered, and what child-specific rules apply. GDPR Article 8 addresses consent-based information-society services offered directly to children, with the applicable threshold depending on member-state law. ([GDPR, Article 8](https://eur-lex.europa.eu/eli/reg/2016/679))

An exclusion for under-13 users does not by itself address older teenagers’ rights. COPPA concerns certain services directed to children under 13 or with actual knowledge of collecting their personal information; its scope should be assessed separately from the older-teen audience. ([FTC COPPA rule](https://www.ftc.gov/legal-library/browse/rules/childrens-online-privacy-protection-rule-coppa))

### Conditional draft: eligibility

> You may use ProTip365 only if you meet the legal requirements applicable to you for using the service and accepting these Terms. Where permission from a parent or legal guardian is legally required, that permission must be obtained before using features that require it. Any age limits or additional requirements for account-based features will be explained before those features are enabled.

This is a drafting starting point, not an implemented age-verification process or a complete child-privacy notice. Counsel should replace it with the approved minimum age and market-specific approach.

## Purchases, trial and access to records

Approve the entitlement matrix before rewriting this section. Specify which core functions remain available after trial expiration; whether existing records remain viewable, exportable and deletable; whether encrypted-backup restore requires paid access; and how a lifetime purchase differs from a recurring subscription.

Google Play requires clear subscription cost, billing frequency, automatic-renewal terms, trial conversion and cancellation information, properly localized for the customer. It also requires an easy online way to manage or cancel subscriptions through the app’s settings or equivalent page. ([Google Play subscriptions policy](https://support.google.com/googleplay/android-developer/answer/9900533?hl=en))

Recommended product rule: do not trap historical financial records behind a payment gate. Preserve viewing, free CSV export and deletion; explicitly resolve whether restore is free so the support page and terms cannot describe incompatible access.

### Conditional draft: subscriptions

> Any optional paid plan, its price, billing period, included features and renewal terms will be shown before purchase. If a free trial converts to a paid subscription, the conversion date and charge will be disclosed before you accept the trial. You can manage or cancel a Google Play subscription through Google Play. Refund rights depend on the applicable store rules and law; these Terms do not limit rights that cannot legally be excluded.

Keep or remove the free-trial sentence according to the actual offer. The checkout and entitlement implementation must support the same promise.

## Liability, changes and governing law

- **Liability cap:** A “fees paid in the preceding 12 months” cap may be zero for free users and for lifetime purchasers who paid earlier. Review proportionality and mandatory-law limits rather than relying only on “to the maximum extent permitted.”
- **Exclusions:** Québec’s Consumer Protection Act, section 10, prohibits a merchant from excluding the consequences of its own acts or those of its representative in the covered context. Whether the Act applies to a particular app transaction needs counsel’s assessment. ([Québec Consumer Protection Act](https://www.legisquebec.gouv.qc.ca/fr/document/lc/p-40.1))
- **Changes:** “Continued use means acceptance” and release notes alone may not be sufficient for material contract changes. Section 11.2 contains specific unilateral-change constraints and notice/refusal protections where applicable. ([Québec Consumer Protection Act](https://www.legisquebec.gouv.qc.ca/fr/document/lc/p-40.1))
- **Governing law:** Removing Québec from marketing does not require deleting the legal governing-law clause. Retain an accurate operator-related choice of law, while preserving mandatory consumer protections that may apply where users live.

### Draft: material changes

> We will notify you of material changes to these Terms through an appropriate channel before they take effect, where required by applicable law. The notice will explain the changes, their effective date and any rights you have to refuse them or end the service. No change will reduce rights that applicable law does not permit us to limit.

Counsel should add the required notice period and specific cancellation mechanics after confirming jurisdictions and contract structure.

## Release checklist

- **Owner approvals:** Confirm launch storage scope, commercial model, age eligibility and legal operator.
- **Engineering evidence:** Verify encryption, SDK network behaviour, exports, deletion, backup/restore and purchase entitlements against policy promises.
- **Google Play:** Align the Data safety form, app privacy-policy URL, support contact, subscription presentation and account-deletion URL where required.
- **Languages:** Apply approved wording consistently in English, French and Spanish; legal translation review is recommended.
- **Website/store consistency:** Confirm Android and iOS release availability before changing “coming soon” copy. An official ProTip365 iOS listing exists, but whether it matches the planned product experience remains an owner confirmation. ([Apple App Store listing](https://apps.apple.com/us/app/protip365/id6751759695))
- **Publication gate:** Publish substantive policy changes only after the owner approves the scope and counsel reviews legal clauses. This review did not silently change the commercial model, liability wording or privacy architecture on the live site.
