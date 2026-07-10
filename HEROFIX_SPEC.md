# HEROFIX SPEC — Splash Content Above the Hero (v0.23.0)

Execution contract. Sonnet default. All decisions final.
The hero media and fireflies cover the wordmark, tagline, and
buttons — splash content renders BELOW the hero layer because
it has no z-index while .splash-hero is z-index 1. Fix the
stack.

## Root cause
.splash-hero is position:absolute z-index:1 (hero image+video).
.firefly particles are z-index 2. But .splash-mark,
.splash-title, .splash-tagline, .splash-cta, .splash-secondary,
.splash-privacy have NO z-index and no position, so they stack
below the positioned hero layer and are fully covered. Only the
fireflies (explicit z-index) were visible.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. Correct splash stack, bottom to top: hero still image ->
   hero video -> firefly particles -> [amber glow] -> splash
   content (wordmark, tagline, buttons, privacy). Splash
   content must be the TOP layer — it's the interactive/legible
   layer.
2. Give the splash content a positioning context + high
   z-index so it sits above hero media and fireflies. Simplest:
   wrap the content children in position:relative with a
   z-index above the fireflies (e.g. z-index 3), OR set each
   content element position:relative; z-index:3. Prefer a
   single wrapper if one exists; else apply to the content
   elements.
3. Legibility: since content now sits over the video, add a
   subtle dark scrim between the hero media and the content —
   a gradient overlay (transparent center to slightly darker
   top/bottom, or a flat rgba(20,33,26,0.35)) on the hero
   layer — so text stays readable over bright video frames.
   Keep it subtle; the media should still read clearly.

## Claude Code tasks (one commit, v0.23.0)

### Task 1 — Raise splash content above hero
Ensure the splash content (.splash-mark, .splash-title,
.splash-tagline, .splash-cta, .splash-secondary,
.splash-privacy) renders above .splash-hero and .firefly.
Give them position:relative and z-index:3 (or wrap them in a
single positioned container at z-index 3). Do NOT change the
hero (z1) or firefly (z2) values — only lift the content above
them.

### Task 2 — Legibility scrim
Add a subtle dark overlay on the hero layer (between media and
content) so the wordmark/tagline/buttons stay readable over
bright video frames. A gradient or flat low-alpha dark scrim,
kept subtle. The amber wordmark glow (existing text-shadow)
stays.

### Task 3 — Version, docs, self-verify
Fan-out: footer v0.23.0 + sw.js CACHE appleseed-v0-23-0.
CLAUDE_CONTEXT.md: note the splash z-order (hero 1 / fireflies
2 / content 3), scrim, roadmap.
Post-deploy self-verify (rule 11, four probes):
1. index.html: v0.23.0 + markers (splash content z-index 3 or
   wrapper, scrim overlay present, .splash-hero still z-index
   1)
2. sw.js cache = appleseed-v0-23-0
3. GET {SUPABASE_URL}/rest/v1/profiles?select=display_name&limit=1
   with apikey + Bearer -> 200 JSON
4. GET {SUPABASE_URL}/rest/v1/plants?select=lat,lng&limit=5
   with apikey + Bearer -> 200, all <= 3 decimals
No data mutation. Report table, stop.

## Acceptance (Jason)
- Splash: hero video/image plays in the background, fireflies
  drift, AND the "Johnny Appleseed" wordmark, tagline, Get
  started + Browse buttons are all visible and readable ON TOP
- Text stays legible over bright video frames (scrim working)
- Buttons are tappable (content is the top layer, not just
  visually — z-index restores click access too)
- Reduced-motion: still image + readable content, no video/
  fireflies
