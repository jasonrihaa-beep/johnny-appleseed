# SPLASHFIX SPEC — Clean the First Impression (v0.19.0)

Execution contract. Sonnet default. All decisions final.
Three visible defects on the production splash: a square glow
box around the italic wordmark, low-contrast amber text, and
map controls bleeding through the splash overlay.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. box-shadow draws a rectangle — wrong for glowing an italic
   word. The wordmark accent glow becomes text-shadow only
   (follows letterforms). The firefly-pulse keyframe must
   animate text-shadow, not box-shadow, on .splash-title em.
   The splash-mark (the square app icon) MAY keep a box-shadow
   glow — a box glow on a square element is correct.
2. The amber wordmark stays --gold-400 but gets a layered
   text-shadow glow strong enough to lift it off the dark
   background for legibility; the accent is decorative emphasis
   on a 2-word title, not body text, so it is exempt from the
   4.5:1 body floor but must be comfortably readable.
3. Splash must fully occlude the app. Root cause: #splash is
   z-index 500 while #map-filter and #plant-fab are z-index
   1000. Raise #splash to z-index 2000 (above map controls,
   below nothing that matters). Do not lower the map controls
   (they must stay above Leaflet panes — tripwire 7).
4. Map untouched (tripwire 17 still in force): no edits inside
   #map-view, no circle/popup changes. This is splash-only.

## Claude Code tasks (one commit, v0.19.0)

### Task 1 — Fix the square: box-shadow -> text-shadow
On .splash-title em: replace any box-shadow glow with a
layered text-shadow (e.g. two stacked amber shadows at
increasing blur, low alpha) that hugs the letterforms — no
rectangle. Update the firefly-pulse keyframes so the pulsing
animates text-shadow intensity on the em (and keep the
splash-mark's box-shadow pulse as-is, since the mark is a
square). prefers-reduced-motion path unchanged (static glow).

### Task 2 — Wordmark legibility
Give .splash-title em a strong enough base text-shadow glow
(per decision 2) that the amber reads clearly against
#14211A. Verify the whole title "Johnny Appleseed" is
comfortably legible.

### Task 3 — Splash occlusion
#splash z-index 500 -> 2000. Confirm map-filter pills and
plant-fab no longer appear over the splash on load. Leave
#map-filter and #plant-fab at 1000.

### Task 4 — Version, docs, self-verify
Fan-out: footer v0.19.0 + sw.js CACHE appleseed-v0-19-0.
CLAUDE_CONTEXT.md: note the box-shadow-on-italic lesson and
the splash z-index, roadmap.
Post-deploy self-verify (rule 11, four probes):
1. index.html: v0.19.0 + markers (#splash z-index 2000,
   text-shadow on .splash-title em, no box-shadow on
   .splash-title em)
2. sw.js cache = appleseed-v0-19-0
3. GET {SUPABASE_URL}/rest/v1/profiles?select=display_name&limit=1
   with apikey + Bearer -> 200 JSON
4. GET {SUPABASE_URL}/rest/v1/plants?select=lat,lng&limit=5
   with apikey + Bearer -> 200, all <= 3 decimals
No data mutation. Report table, stop.

## Acceptance (Jason)
- Splash: no square around "Appleseed"; the amber word glows
  along its letters and is clearly readable
- Splash on load: NO filter pills, NO green + button visible
  over it — the splash fully covers the app
- Reduced-motion: glow static, no pulse
- Map tab after dismissing splash: unchanged from v0.18.0
