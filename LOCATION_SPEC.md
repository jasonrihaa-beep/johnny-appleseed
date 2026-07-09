# LOCATION SPEC — See Where It Lands (v0.16.0)

Execution contract. Sonnet default. All decisions final.
Fixes wildly wrong pins and an honest-states gap: the app
published locations the user never saw. Location becomes
visible, sourced, and manually placeable before submit.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. NEW TRIPWIRE 15 — location is never guessed silently. The
   map-center fallback must never auto-fire; every published
   coordinate was either a classified GPS fix the user saw, a
   manual map placement, or an explicit user tap on "Use map
   center". No fourth path may ever be added.
2. The preview shows ROUNDED coordinates (3 decimals, same as
   the DB trigger) — what the user sees is exactly what
   publishes, privacy floor included. Copy notes "neighborhood
   precision (~100 m)".
3. Geolocation requests use { enableHighAccuracy: true,
   timeout: 10000, maximumAge: 0 } and classify by
   coords.accuracy: ≤100 m = good; 100–1000 m = warn;
   >1000 m = poor (Android approximate-permission territory).
   Poor fixes are shown, never auto-accepted as final — the
   row nudges manual placement and hints: "Turn on precise
   location for Chrome, or place the pin on the map."
4. Manual placement is a first-class path, not a fallback —
   it is how discovery-mode users log a plant found earlier
   elsewhere. Found-mode helper copy: "Log where you found it
   — place on the map if you're logging later."
5. Pick mode hides the plant FAB and filter pills while
   active (reduces mis-taps); crosshair and confirm controls
   reuse existing tokens, stroke SVG only, z below the action
   sheet (1100).

## Claude Code tasks (one commit, v0.16.0)

### Task 1 — Location row in the Plant form
Replace the current invisible-location behavior with a
visible row (id="location-row") above the access selector:
status dot (green/gold/red via existing tokens), primary text
(neighborhood if resolvable, else rounded lat,lng), source
label ("GPS ±Xm" / "Approximate ±X km" / "Placed manually" /
"Map center" / "No location yet"), and two small actions:
"Refresh" (re-request GPS) and "Place on map".

### Task 2 — High-accuracy wrapper
One function wrapping getCurrentPosition with decision-3
options and classification. On error/denied/timeout: row
enters failed state with the two actions; NO coordinates are
set (tripwire 15). Success: store raw fix, display rounded
per decision 2.

### Task 3 — Map pick mode
"Place on map" → switchTab('map') in pick mode: fixed
crosshair at viewport center of the map, map pans/zooms
freely beneath it; a confirm pill ("Use this spot") and a
cancel control at bottom-center; FAB + filter pills hidden
while active (decision 5). Confirm → coords = map center,
rounded → return to Plant tab, row shows "Placed manually".
Cancel → return with prior state untouched.

### Task 4 — Submit wiring
submitPlant uses ONLY the location-row state. If no location
is set: block with a toast pointing at the row (this is the
one thing that may block a log — publishing a pin with no
location is meaningless, and silence was the old bug).
Explicit "Use map center" remains available in the row's
failed state as a labeled, deliberate choice. Client rounding
before insert stays; DB trigger remains the guarantee.

### Task 5 — Version, docs
Fan-out: footer v0.16.0 + sw.js CACHE appleseed-v0-16-0.
CLAUDE_CONTEXT.md: tripwire 15, decisions above, landmarks
(location row, wrapper fn, pick mode), roadmap.

### Task 6 — Post-deploy self-verify (rule 11, four probes)
1. index.html: v0.16.0 + markers (location-row,
   enableHighAccuracy, pick-mode fn, "Place on map",
   "Use this spot")
2. sw.js cache = appleseed-v0-16-0
3. GET {SUPABASE_URL}/rest/v1/profiles?select=display_name&limit=1
   with apikey + Bearer → 200 JSON
4. GET {SUPABASE_URL}/rest/v1/plants?select=lat,lng&limit=5
   with apikey + Bearer → 200, all ≤ 3 decimals
No data mutation. Report table, stop.

## Acceptance (Jason)
- Pixel, precise location ON: row shows GPS with small ±,
  neighborhood text; logged pin lands at block-level accuracy
  (the ~100 m floor is design, not error)
- Pixel, precise location OFF: row shows Approximate with a
  large ±, nudge copy appears, nothing auto-publishes
- Place on map: put a pin deliberately across town → published
  pin lands exactly there
- Found mode: helper copy present; couch-log a "trail find"
  via map placement
- Attempt submit with no location: blocked with a toast
  pointing at the row
