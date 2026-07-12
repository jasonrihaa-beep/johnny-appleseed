# HAZEDOT SPEC — The Dot Yields to the Circle (v0.35.0)

Execution contract. Sonnet default. All decisions final.
Acceptance finding (Jason): the center dot contradicts the
haze circle — a dot says "the plant is exactly here," people
will walk to the dot. At close zoom the circle IS the honest
answer; the dot must disappear entirely there.

## Tripwire-17 exception, scoped
This build MAY edit the DB-pin dot markers' visibility logic
and popup bindings. It may NOT change: circle radius (75m),
access opacity tiers (0.25/0.15/0.08), colors, popup CONTENT,
pick mode, or anything else in the map renderer. After this
build the map re-freezes; update tripwire 17 wording to note
the exception was consumed by v0.35.0.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. DOT_HIDE_ZOOM = 16 (named constant). At map zoom >= 16 the
   center dots are removed from the map; below 16 they render
   as today. Rationale: at zoom 16 the 75m circle is ~55px
   across — a comfortable tap target; the dot has no locator
   job left and only overclaims precision. Hard disappear, no
   fade (Jason's call).
2. Popups bind to the CIRCLE as well as the dot (same content,
   same options). Far zoom: dot is the practical tap target.
   Close zoom: the circle is. Tap behavior must work in both
   regimes.
3. Implementation: keep all dot markers in a single
   L.layerGroup; one 'zoomend' listener adds/removes the whole
   group vs DOT_HIDE_ZOOM. Set initial state from the map's
   starting zoom. No per-marker listeners, no opacity
   animation.
4. Example pins (PIN_SPOTS) follow identical rules — one
   rendering path, no special cases.

## Claude Code tasks (one commit, v0.35.0)

### Task 1 — Circle popup binding
In addHazeCircle: bindPopup on the L.circle with the same
popupHtml the dot receives. Verify popup opens from a circle
tap when dots are hidden AND from a dot tap when visible.

### Task 2 — Dot layer group + zoom toggle
Collect dot markers into a dedicated layerGroup; implement the
zoomend listener + DOT_HIDE_ZOOM per decisions 1 and 3; apply
initial visibility from current zoom on map init and after
renderMarkers rebuilds (pins reload on tab switch — the group
must rebuild consistently).

### Task 3 — Pick-mode sanity
Verify pick mode still hides/ignores interactive layers as
shipped (pointer-events guard) with the new group in place.

### Task 4 — Version, docs, self-verify
Fan-out: footer v0.35.0 + sw.js CACHE appleseed-v0-35-0.
CLAUDE_CONTEXT.md: DOT_HIDE_ZOOM decision, circle popup
binding, tripwire 17 exception consumed + map re-frozen,
roadmap (acceptance list fully cleared).
Post-deploy self-verify (rule 11, four probes):
1. index.html: v0.35.0 + DOT_HIDE_ZOOM constant + zoomend
   listener + bindPopup on the circle + access tiers
   0.25/0.15/0.08 STILL PRESENT UNCHANGED (regression check)
2. sw.js cache = appleseed-v0-35-0
3. GET https://uavtaznzdpmfvkdpqyrv.supabase.co/rest/v1/plants?select=access&limit=1
   with apikey + Bearer (key from index.html, ref exactly as
   in file) -> 200; network unavailable = NOT RUN, never pass
4. Same host: /rest/v1/plants?select=lat,lng&limit=5 -> 200,
   all <= 3 decimals
No data mutation. Report table, stop.

## Acceptance (Jason)
- Zoomed out: dots visible as today; tap a dot -> popup opens
- Zoom in past street level: dots vanish entirely; only
  circles; tap a circle -> same popup opens
- Zoom back out: dots return
- Tiers unchanged: public bright/gold, ask standard, private
  faint grey
- Pick mode (Place on map): crosshair taps unobstructed
