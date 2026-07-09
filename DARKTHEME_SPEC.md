# DARKTHEME SPEC — Premium Dark + Firefly Glow (v0.18.0)

Execution contract. Sonnet default. All decisions final.
A dark, warm, premium reskin driven by SURFACE-TOKEN remapping,
not component rewrites. The map and its haze circles are
deliberately untouched this build.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. TYPEFACES UNCHANGED. Fraunces + DM Sans stay — they are
   Johnny Appleseed's identity and what distinguishes it from
   MyMeds. Do NOT introduce Instrument Serif or IBM Plex.
2. Method: remap the SEMANTIC surface tokens only. The raw
   green/gold/violet/red scales keep their hex values. Change
   what --stone-100, --stone-200, --stone-300, --stone-500,
   --stone-700, and --ink resolve to. Because components
   reference the semantic tokens, most surfaces re-theme with
   near-zero per-component edits.
3. NEW dark surface values:
   --stone-100 (was warm white) -> #14211A  (near-black forest)
   --stone-200 (was pale)       -> #1C2B22  (raised surface)
   --stone-300 (was border)     -> rgba(122,153,136,0.22) (sage border)
   --stone-500 (muted text)     -> #8FA398  (dimmed sage)
   --stone-700 (secondary text) -> #C3D2C8  (light sage)
   --ink       (primary text)   -> #F5F1E8  (warm off-white)
   Add --glass: rgba(28,43,34,0.72) and --glass-border:
   rgba(245,241,232,0.14) for frosted cards.
   Add --glow-amber: rgba(244,161,39,0.22) for firefly light.
4. TRIPWIRE 17 — the map is off-limits this build. #leaflet-map,
   L.circle rendering, addHazeCircle, the access opacity tiers
   (0.25/0.15/0.08) and all popup styling are NOT touched.
   backdrop-filter is NEVER applied over the map (Leaflet
   pan/zoom + blur destroys framerate on mid-range Android).
   The map keeps its current appearance; a later build re-tunes
   circles for dark deliberately.
5. Contrast floor: body text on any surface >= 4.5:1, large/
   secondary text >= 3:1. Amber accent (#F4A127) is for glow,
   emphasis, and the wordmark accent — never for body text on
   dark (fails contrast). Existing green/gold/violet status
   pills keep their meaning; verify each stays legible on the
   new dark surfaces and darken pill backgrounds via the
   existing -50/-100 scale tokens only where a pill becomes
   unreadable.
6. theme-color meta + manifest background_color update to
   #14211A so the PWA shell and status bar match.

## Claude Code tasks (one commit, v0.18.0)

### Task 1 — Dark token remap
In :root, change the six semantic surface tokens and --ink to
the decision-3 values; add --glass, --glass-border,
--glow-amber. Do not alter the green/gold/violet/red raw
scales. Update <meta name="theme-color"> to #14211A.

### Task 2 — Frosted glass cards (NON-map surfaces only)
Apply to feed post cards, the score preview, profile stat
cards, and the setup/action sheets: background var(--glass);
backdrop-filter: blur(12px); -webkit-backdrop-filter:
blur(12px); border: 1px solid var(--glass-border); keep
existing radii. Explicitly EXCLUDE anything inside #map-view
and all Leaflet popups (tripwire 17).

### Task 3 — Firefly glow: splash + hero
On #splash: a fixed radial-gradient pseudo-element behind the
content, amber var(--glow-amber) fading to transparent,
centered slightly above middle, evoking firefly light. Add a
second, smaller offset glow for depth. On the splash-mark and
splash-title em (the amber accent): a soft text-shadow/
box-shadow amber glow that pulses subtly via a slow (4-6s)
ease-in-out keyframe at low intensity. Respect
prefers-reduced-motion: no pulse, static glow only.

### Task 4 — Topbar + tab bar + chrome
Ensure #topbar, #tab-bar, #location-bar, form inputs, and the
sticky #submit-bar read correctly on dark: backgrounds to the
new --stone-100/200, borders to the new --stone-300, the gold
active-tab indicator and green active states unchanged. Form
inputs get a subtly raised --stone-200 fill with the sage
border.

### Task 5 — Contrast sweep
Walk every text/background pairing changed by the remap and
fix any that fall below decision-5 floors, adjusting ONLY via
existing tokens (or the new sage text values). Give special
attention to: muted captions (--stone-500), the plant-suggest
dropdown, score-reason text, and the sign-in caption line.

### Task 6 — Version, docs, manifest
Fan-out: footer v0.18.0 + sw.js CACHE appleseed-v0-18-0.
manifest.json background_color -> #14211A. CLAUDE_CONTEXT.md:
tripwire 17, decisions above, dark-token landmark, roadmap
(map dark-tuning pass pending; DB research at v0.19.0).

### Task 7 — Post-deploy self-verify (rule 11, four probes)
1. index.html: v0.18.0 + markers (--glass token, --glow-amber
   token, backdrop-filter present, theme-color #14211A, splash
   glow keyframe)
2. sw.js cache = appleseed-v0-18-0
3. GET {SUPABASE_URL}/rest/v1/profiles?select=display_name&limit=1
   with apikey + Bearer -> 200 JSON
4. GET {SUPABASE_URL}/rest/v1/plants?select=lat,lng&limit=5
   with apikey + Bearer -> 200, all <= 3 decimals
No data mutation. Report table, stop.

## Acceptance (Jason)
- Splash: dark forest background, amber firefly glow behind the
  wordmark, subtle pulse; Fraunces wordmark intact
- Feed: dark glass cards, off-white text readable, status pills
  and Found chip still legible
- Plant form + sheets: dark surfaces, inputs readable, sticky
  submit bar correct, sign-in caption legible
- Map tab: UNCHANGED — circles and popups exactly as v0.17.0
  (if anything on the map looks different, that's a tripwire-17
  violation, report it)
- Reduced-motion OS setting: glow static, no pulse
