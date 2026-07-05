# MAP INSPIRE SPEC — Popup Engagement (v0.9.0)

Execution contract. Sonnet default. All decisions final.
Map pins for real plants become an engagement surface: richer
popup, inspire button, live-on-open count.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. DB pins ONLY. PIN_SPOTS example pins keep their current
   simple popups — they are not database rows; an inspire
   insert would violate the FK and a non-persisting button
   violates honest-states.
2. Count is lazy: fetched on Leaflet 'popupopen' for that one
   plant_id, never prefetched for all pins. No realtime —
   fresh on each open, optimistic on own taps (S4d decision 1
   stands).
3. All user-originated text in popup HTML goes through esc()
   — plant_name, sci, note, display_name (S2 decision 8).
4. Feed cards and map popups may briefly disagree on count
   (each loads independently). Accepted at MVP scale.
5. Self-inspire allowed, no self-notification (DB handles it).

## Claude Code tasks (one commit, v0.9.0)

### Task 1 — Richer DB-pin popup
Popup content for DB pins (builder fn, esc() everywhere):
plant name (strong, Fraunces), sci italic on next line, planter
line "by [display_name]" using the existing profiles in-list
pattern from loadDbPins, note if present, access chip "Open
harvest" only when access='public' (reuse gold styling), score
badge, and an inspire row: button (compact .inspire-btn variant
sized for popup width) + count span with id keyed by plant id,
placeholder "–" until fetched.

### Task 2 — Lazy count fetch
On map 'popupopen' for a DB pin: sb.from('inspires')
.select('user_id').eq('plant_id', id) → render count (hide at
0, show number otherwise) + set button state if session user is
in the set. No session → button renders in un-inspired state.

### Task 3 — Toggle from popup
Tap → ensureAuth() (anon session is a valid first action) →
optimistic flip of button + count. Not inspired → .insert({
plant_id, user_id: session.user.id }) — user_id EXPLICIT,
tripwire 11. Inspired → .delete().eq('plant_id', id)
.eq('user_id', me). On error revert + toast the message.
Popup DOM updates in place; no popup close/reopen.

### Task 4 — Version, docs
Fan-out: footer v0.9.0 + sw.js CACHE appleseed-v0-9-0.
CLAUDE_CONTEXT.md: decisions above, landmarks (popup builder,
popupopen handler, popup toggle fn), roadmap.

### Task 5 — Post-deploy self-verify (rule 11, four probes)
1. index.html: v0.9.0 + markers (popup builder fn, popupopen
   handler, popup toggle fn name)
2. sw.js cache = appleseed-v0-9-0
3. GET {SUPABASE_URL}/rest/v1/inspires?select=plant_id&limit=1
   with apikey + Bearer → 200
4. GET .../plants?select=lat,lng&limit=5 → 200, all ≤ 3 decimals
No data mutation. Report table, stop.

## Acceptance (Jason — this run also retires the outstanding
S4b/S4d verification debt)
- Normal window: tap your okra PIN on the map → popup shows
  sci name, "by Jason", score → tap inspire → count 1 →
  close/reopen popup → still 1
- Incognito: tap same pin → count 1 visible → tap inspire →
  2 → normal window reopens popup → 2
- Normal window bell: new inspire notification row appears
- Example pin popup: unchanged, no inspire button anywhere
