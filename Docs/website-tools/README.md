# Landing-page localization

The production landing pages are static HTML under `Docs/website-live/`: English at `/`, French at `/fr/`, and Spanish at `/es/`. Each contains the 12 walkthrough screens plus a hero phone mockup.

`localize-landing.cjs` replaces the mockups in every route with copies of the English mockups, then applies a complete French or Spanish UI dictionary, date and number formatting, calendar weekdays, input placeholders and the selected language. It leaves the already translated surrounding page copy and SEO metadata intact. The output does not need a localization script at runtime.

Install Playwright in your development environment and its Chromium browser. Start a static server serving `Docs/website-live/`, then run:

```sh
node Docs/website-tools/localize-landing.cjs Docs/website-live http://localhost:4317
node Docs/website-tools/check-localization.cjs http://localhost:4317
```

An optional `CHROME_PATH` environment variable selects an existing Chromium binary. The check script accepts a third argument for a screenshot output directory. Tests cover all three routes with JavaScript disabled, 13 phone mockups per route, untranslated English dictionary strings, language metadata, and desktop/mobile page overflow.

When adding or changing English UI text, update the dictionary and rerun both commands before deploying. Keep company names and the language-picker endonyms (Français, English, Español) unchanged; do not mistake those intentional names for untranslated UI.

These tools localize the noninteractive landing-page mockups. They do not change the separate interactive demo or mobile app implementation.
