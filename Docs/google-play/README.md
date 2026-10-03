# Google Play redesign assets

Prepared 2026-10-03 for `com.defacto365.protip365`, in the existing DeFacto365 developer account. Publish these listing changes with the redesigned Android release, after native and purchase testing. The production build is still version 1.0.0 (11).

Saved in Play Console as draft changes: en-US, en-CA, fr-CA, fr-FR, es-419, es-ES and es-US descriptions; new default icon and English graphics; localized French graphics in both French listings. The final editor confirmed saved changes and the draft badge. No listing review or publication was submitted. `console-draft-proof.jpg` records the saved French listing, and `gallery.html` previews the assets locally.

## Assets and story

The cream background, sage `p.` logo, brown text, Fraunces headings and Work Sans body match https://www.protip365.com/. The logo uses the app's canonical vector path, with a full square background so Google Play applies its own mask.

- `play-icon.png`: 512 × 512.
- `en-US/en-US-feature-graphic.jpg` and `fr-CA/fr-CA-feature-graphic.jpg`: 1024 × 500.
- Six screenshots in each language: 1080 × 1920, JPEG, below 8 MB each.
- Order: `01-home`, `02-tips`, `03-calendar`, `04-stats`, `05-jobs`, `06-exports`.
- English assets serve en-US, en-CA and the Spanish store translations. French assets serve fr-CA and fr-FR. Spanish descriptions explicitly state that the app interface supports French and English.

Screens inside the artwork were captured from the current Expo web interface with isolated, fictional demonstration data. They are not Android emulator screenshots. Compare them with the final native build before publication, especially PDF sharing, keyboard and system UI. The fixture is a development tool; it never changes real app data or enters the production bundle.

## Copy and release notes

`listing-copy.json` holds short/full descriptions and release notes in English, French and Spanish. Short descriptions are 63 / 77 / 74 characters; full descriptions are 1667 / 2040 / 1761. Each release note is below 500 characters.

`release-notes.txt` is ready to paste into the new Android release's “Release notes” field, with all seven existing locale tags. Notes are not attached to the old production build.

Do not submit this listing alone while Google Play still distributes the previous interface. Review the new AAB and listing together.

## Regeneration

From the repository root, run `node app/scripts/create-store-preview.cjs` after exporting the current web app to `app/dist-web`. This serves an isolated capture fixture on port 8084 and creates HTML poster sources. Capture the app at 414 × 800, then render the posters at 1080 × 1920 using a **full-page** browser screenshot (viewport-only screenshots can be height-limited). Feature graphics use 1024 × 500.

The locally copied web bundle and fonts are ignored by Git. Final JPEGs, SVG/PNG logo, HTML templates, copy and source screen captures are versioned.
