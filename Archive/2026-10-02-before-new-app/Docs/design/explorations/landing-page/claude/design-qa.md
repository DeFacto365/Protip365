# Design QA — ProTip365 landing screenshots

## Inputs

- Source: `C:\Users\jack_\AppData\Local\Temp\protip365-screen-contact-sheet.png`
- Desktop implementation: `C:\Users\jack_\AppData\Local\Temp\protip365-landing-local-gallery.png`
- Mobile implementation: `C:\Users\jack_\AppData\Local\Temp\protip365-landing-local-mobile-gallery.png`
- Combined comparison: `C:\Users\jack_\AppData\Local\Temp\protip365-design-qa-comparison.png`

## Viewports and state

- Desktop: 1280 × 900, English, screenshot gallery at its initial position.
- Mobile: 390 × 844, English, screenshot gallery at its initial position.
- Source: all 12 supplied screens shown as a contact sheet.

## Full-view comparison

The supplied Home screen now appears in the hero without reconstruction. The 12 supplied screens appear in source order in a horizontally scrollable gallery. Color, type, screen content, and aspect ratio match because the implementation uses the captured source assets directly.

## Focused comparison

- Hero: the captured Home screen is shown at its native 360:768 ratio with no clipping or stretching.
- Gallery: cards preserve the same ratio, use consistent spacing, and expose the next card to communicate horizontal scrolling.
- Mobile: heading, controls, first card, and the next-card preview fit without page-level horizontal overflow.

## Findings and fixes

1. P2 — Nested caption spans inherited the card-label display rule. Replaced the nested title element so numbering and title remain on one line.
2. Verified gallery previous/next controls, English/French switching, all 12 asset paths, desktop and mobile layouts, and zero browser console errors.
3. No open P0, P1, or P2 visual issues.

Final result: passed
