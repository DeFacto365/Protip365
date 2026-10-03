# Landing-page localization

The production landing pages are static HTML under `Docs/website-live/`: English at `/`, French at `/fr/`, and Spanish at `/es/`. Each contains the 12 walkthrough screens plus a hero phone mockup.

`localize-landing.cjs` replaces the mockups in every route with copies of the English mockups, then applies a complete French or Spanish UI dictionary, date and number formatting, calendar weekdays, input placeholders and the selected language. It leaves the already translated surrounding page copy and SEO metadata intact. The output does not need a localization script at runtime.

The tool now also loads the shared caption dictionaries from the demo and applies every translated screen heading, explanatory bullet and next-screen label. French UI consistently uses “employeur/employeurs,” and the French sharing button is “Partager mon relevé.”

Install Playwright in your development environment and its Chromium browser. Start a static server serving `Docs/website-live/`, then run:

```sh
node Docs/website-tools/build-demo-translations.cjs
node Docs/website-tools/localize-landing.cjs Docs/website-live http://localhost:4317
node Docs/website-tools/check-localization.cjs http://localhost:4317
node Docs/website-tools/check-demo.cjs http://localhost:4317
```

An optional `CHROME_PATH` environment variable selects an existing Chromium binary. The check script accepts a third argument for a screenshot output directory. Tests cover all three routes with JavaScript disabled, 13 phone mockups per route, untranslated English dictionary strings, language metadata, and desktop/mobile page overflow.

When adding or changing English UI text, update the dictionary and rerun both commands before deploying. Keep company names and the language-picker endonyms (Français, English, Español) unchanged; do not mistake those intentional names for untranslated UI.

`build-demo-translations.cjs` generates `demo-translations.js` from the shared UI dictionary and additional interactive states/messages. `demo-i18n.js` localizes the live demo on each render, including computed messages, dates, amounts and accessible labels. The app preserves internal action identifiers and numeric state when the language changes. Decimal-comma input is accepted without changing the selected currency.

The demo header, welcome screen and settings offer all three languages. Landing-page demo links pass `?lang=en`, `?lang=fr` or `?lang=es`, and the back link returns to the corresponding landing route. Export/import/PDF messages are explicitly demonstration previews, not claims that files were generated.

These website changes do not change the mobile app implementation.
