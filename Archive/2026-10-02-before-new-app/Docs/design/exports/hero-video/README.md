# ProTip365 hero video

This is a silent, 10-second, 4:5 product loop designed to replace the static phone in the current right-hand hero column.

## Recommended embed

```html
<video
  autoplay
  muted
  loop
  playsinline
  preload="metadata"
  poster="/media/protip365-hero-loop-poster-720x900.png"
  aria-label="ProTip365 schedule moving from planned shifts to the actual result"
>
  <source src="/media/protip365-hero-loop-720x900.webm" type="video/webm">
  <source src="/media/protip365-hero-loop-720x900.mp4" type="video/mp4">
</video>
```

```css
.hero video {
  display: block;
  width: min(100%, 720px);
  height: auto;
  aspect-ratio: 4 / 5;
  object-fit: cover;
}
```

Keep `muted` and `playsinline`; mobile browsers generally require both for reliable autoplay. The PNG poster provides the static fallback and avoids a blank first paint.

## Provenance

- Visual palette: live ProTip365 landing page, captured July 18, 2026.
- Product UI: `Docs/design/approved/schedule-agenda.png` and `schedule-week.png`.
- Export method: deterministic HTML canvas composition recorded in Chromium with no audio.
- No generated product claims, pricing, testimonials, or replacement UI.

See `manifest.json` for dimensions, codecs, file sizes, and checksums.
