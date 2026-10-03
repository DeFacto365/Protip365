# Website analytics — October 3, 2026

Configured in Google Analytics while signed in as defacto365@gmail.com. Reused the existing account/property rather than creating duplicates.

- Account: ProTip365 (`371055923`).
- Property: ProTip365 (`508257094`), renamed from Protip365.dom; Toronto time zone, CAD reporting currency.
- Web stream: ProTip365 Website (`12280543916`), https://www.protip365.com.
- Measurement ID: `G-E1C2B8QG1G`.
- Realtime: https://analytics.google.com/analytics/web/#/a371055923p508257094/realtime/overview
- Existing app and legacy MonsterInsights streams were not modified.

## Collection and consent

`Docs/website-live/analytics.js` loads on the English, French and Spanish landing pages and privacy, terms and support pages. Google is loaded only after opt-in, only on the public production hostnames. The interactive demo has no analytics script and its form contents are not collected. Cookie settings in the footer let visitors withdraw consent. The preference expires after 180 days; withdrawal removes site GA cookies and reloads to unload tracking. Advertising consent stays denied; Google signals and ad personalization are disabled. Site search and form-interaction enhanced measurement were switched off. Localized privacy disclosures describe collection and withdrawal.

## Events and interpretation

| Event | Trigger | Interpretation |
| --- | --- | --- |
| `page_view` | Consented public page visit | Website visit |
| `app_store_click` | Google Play link clicked | Store interest, not an install or purchase |
| `demo_open` | Interactive demo link clicked | Demo interest; no demo contents collected |
| `facebook_click` | Website Facebook link clicked | Outbound social interest |

Custom events include `page_language`, `link_url` (query removed), and `cta_location`. `app_store_click` is marked as a key event, once per session, without a default monetary value. Event parameters are sent; custom dimensions have not been registered. Standard enhanced-measurement events may accompany the custom events, so do not sum them as separate conversions.

Page URLs retain only validated campaign parameters. Other query parameters and fragments are omitted; referrer queries are removed. Same-tab tracked navigation has a short callback/fallback window to allow delivery without trapping visitors if Google is blocked.

## Facebook attribution

Page: https://www.facebook.com/profile.php?id=61595241323593

Saved and reread both existing website destinations:

- Profile website: `https://www.protip365.com/?utm_source=facebook&utm_medium=social&utm_campaign=page_profile&utm_content=website_link`
- Learn more button: `https://www.protip365.com/?utm_source=facebook&utm_medium=social&utm_campaign=page_profile&utm_content=learn_more`

For future organic posts, use the relevant language path with `utm_source=facebook&utm_medium=social&utm_campaign=<campaign>&utm_content=<post>`; use lowercase identifiers with underscores/hyphens. No posts or ads were published by this setup. GA measures consenting visitors who arrive at the website; Facebook page impressions, followers, reactions and messages remain in Meta Insights.

## Verification and deployment

- Implementation commits: `874249a`, `0a3d586`; remote branch `website/protip365-landing-2026-10`.
- Production deployment: `dpl_GocrNiHpJvWbHua2timiE6UdLybk`, READY, commit `0a3d5866590e1055e32ac1a7a5cdd3d666f5ed8c`, aliases include apex and www.protip365.com.
- Production analytics.js fetched successfully and contains the navigation callback fix.
- Fresh production load before consent: zero Google Analytics/Tag Manager network requests, no Google loader.
- After consent: exactly one loader; `page_view` and `app_store_click` collection responses HTTP 204. Page-view request retained Facebook campaign parameters, with advertising disabled.
- GA Realtime displayed the test visitor, page views, `demo_open`, and `app_store_click`; the latter appeared in key events.
- French and Spanish consent controls worked; withdrawal left zero Google loaders and no site cookies in the inspected browser. Preview acceptance did not load Google.
- Spanish privacy disclosure rendered the added analytics text. French/English disclosures are committed in the corresponding localization sources.
- Test campaign: `analytics_validation`; exclude this from launch-performance interpretation. Standard acquisition reports may take time to populate; campaign attribution in those reports was not yet independently verified.
- Final test browser left opted out. Facebook identity restored to Jacques after Page editing.

This configuration does not measure app installs, mobile app income records, billing or actual purchases. No company address changes were made.
