# HAZE SPEC — The Honest Circle (v0.17.0)

Execution contract. Sonnet default. All decisions final.
Point-pins overclaim: they say "exactly here" while the data
says "within a block." Circles render the truth, turn the
privacy floor into discovery gameplay, and private pins stop
competing for attention.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. NEW TRIPWIRE 16 — the circle IS the data. Radius 75 m,
   the computed rounding-cell extent at ~29.5°N (±55 m lat,
   ±48 m lng, corner ≈ 74 m). Centered on the stored
   coordinate. NEVER jittered, never randomized, never
   resized for aesthetics: jitter is fabricated data and the
   stored coordinate is already public via the API, so the
   honest circle leaks nothing new.
2. Two encodings, no conflict: TYPE keeps color (gold edible /
   green wildlife / violet pollinator / green multi), ACCESS
   sets prominence. public = full-color circle, 0.25 fill
   opacity, gold ring stays; ask = same circle at 0.15 fill;
   private = stone-500 grey circle, 0.08 fill, smaller center
   dot — visible, deliberately unenticing, still tappable.
3. Treasure copy ONLY on access='public' popups: "Somewhere
   in this circle — happy hunting." Private popups instead:
   "Private yard — on the map, not on the menu." Inviting
   strangers to search near a private yard is the exact harm
   the floor prevents.
4. Owners see the same circle as strangers — exact locations
   were never stored anywhere, by design. Public-pin popups
   state it as a feature: "Locations are neighborhood-level
   for everyone's safety."
5. Access becomes a REQUIRED choice: no preselected option,
   "Open spot" listed first, submit blocked with a toast
   pointing at the selector until chosen (same pattern as the
   location block — the only two legitimate blocks in the
   form). DB default 'private' stays as schema backstop; the
   client always sends an explicit value.
6. Example pins (PIN_SPOTS) adopt the circle rendering at the
   ask-tier neutral treatment, keeping their "Example —"
   popup prefix. One rendering path, no special cases.

## Claude Code tasks (one commit, v0.17.0)

### Task 1 — Circle rendering
Replace DB-pin markers with L.circle (meters radius — scales
with zoom) per decisions 1-2, plus a small center dot marker
(divIcon, type color, private = smaller + grey) carrying the
existing popup binding. Popups keep all current content
(photo strip, byline, score/facts, edible caution) and add
the decision 3-4 copy lines per access value. PIN_SPOTS
render per decision 6. The gold "Open harvest" ring styling
folds into the public-tier circle treatment.

### Task 2 — Forced access choice
Remove the default 'private' selection from the access
selector; reorder buttons "Open spot" / "Ask first" /
"My yard". submitPlant blocks with a toast if no access
chosen. selectAccess handler otherwise untouched (scoping
rules per tripwires 10/13 unchanged).

### Task 3 — Filter interaction
Existing filter pills operate on the circle layer identically
(type pills filter by tags; "Open harvest" filters
access='public'). Verify pick-mode (v0.16.0) still hides
pills/FAB and that circles don't intercept crosshair taps
while pick mode is active.

### Task 4 — Version, docs
Fan-out: footer v0.17.0 + sw.js CACHE appleseed-v0-17-0.
CLAUDE_CONTEXT.md: tripwire 16, decisions above, landmarks
(circle renderer, access validation), roadmap (DB research
slides to v0.18.0).

### Task 5 — Post-deploy self-verify (rule 11, four probes)
1. index.html: v0.17.0 + markers (L.circle usage in the DB-pin
   renderer, "happy hunting", "not on the menu", access
   validation in submitPlant, no preselected access option)
2. sw.js cache = appleseed-v0-17-0
3. GET {SUPABASE_URL}/rest/v1/plants?select=access&limit=1
   with apikey + Bearer → 200 JSON
4. GET {SUPABASE_URL}/rest/v1/plants?select=lat,lng&limit=5
   with apikey + Bearer → 200, all ≤ 3 decimals
No data mutation. Report table, stop.

## Acceptance (Jason)
- Public-access pin: colored circle roughly a block wide at
  street zoom, hunting copy in popup, gold treatment
- Your private okra: faint grey circle, blunt popup copy,
  still tappable
- New log: no access preselected, "Open spot" first, submit
  without choosing → blocked with toast
- Zoom out: circles shrink with the map (real-world scale),
  never balloon
- Pick mode (Place on map): pills/FAB hidden, crosshair taps
  unobstructed by circles
