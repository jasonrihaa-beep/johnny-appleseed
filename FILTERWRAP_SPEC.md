# FILTERWRAP SPEC — Filters That Wrap, Not Clip (v0.24.0)

Execution contract. Sonnet default. All decisions final.
The map filter bar scrolls horizontally but the scrollbar is
hidden — on desktop (no swipe) the overflow pills are
unreachable, and "Open harvest" clips off the right edge. Fix:
compact the pills and wrap to two rows so all are visible and
reachable on every device. No horizontal scroll.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. Replace horizontal-scroll with wrap. #map-filter switches
   from overflow-x:auto / nowrap behavior to flex-wrap:wrap so
   pills flow onto a second row instead of clipping. Remove the
   horizontal-scroll overflow (no longer needed); the bar's
   height grows to fit its rows.
2. Compact the pills modestly so more fit per row: reduce
   padding and font slightly (still comfortably tappable — min
   ~30px tap height). Keep the pill shape, border, active
   state, and the gold active treatment.
3. The bar stays pinned top over the map (position absolute,
   the existing left/right insets), z-index unchanged (map
   chrome band, must stay above Leaflet panes — tripwire 7).
   Wrapping means it may occupy two rows; that's accepted and
   expected.
4. Future-proofing note only (NOT built now): if filter count
   grows past what two rows holds cleanly (~10), the plan is a
   dedicated "Filters" button opening a sheet — not more rows.
   Document this as the next step, do not implement.
5. Map render still frozen (tripwire 17): no circle/popup/pin
   changes. This is filter-chrome only.

## Claude Code tasks (one commit, v0.24.0)

### Task 1 — Wrap the filter bar
#map-filter: change to flex-wrap: wrap; remove overflow-x:auto
and the hidden-scrollbar rules (no longer needed). Keep gap
(tighten slightly if helpful, ~6px). Keep position/insets/
z-index. The bar now grows vertically to fit wrapped rows.
Add a small row-gap so two rows don't touch.

### Task 2 — Compact pills
.filter-pill: reduce padding (e.g. 5px 12px) and font-size
(e.g. 11.5-12px) modestly; keep min tap height comfortable,
keep border/radius/active/gold-active styling intact. Verify
all six current pills (All plants, Edible, Wildlife,
Pollinators, Near me, Open harvest) fit cleanly.

### Task 3 — Version, docs, self-verify
Fan-out: footer v0.24.0 + sw.js CACHE appleseed-v0-24-0.
CLAUDE_CONTEXT.md: note the wrap fix, compact pill sizing,
future-proofing plan (sheet at >10), roadmap.
Post-deploy self-verify (rule 11, four probes):
1. index.html: v0.24.0 + markers (#map-filter flex-wrap:wrap,
   .filter-pill compact padding/font, no overflow-x:auto)
2. sw.js cache = appleseed-v0-24-0
3. GET {SUPABASE_URL}/rest/v1/profiles?select=display_name&limit=1
   with apikey + Bearer -> 200 JSON
4. GET {SUPABASE_URL}/rest/v1/plants?select=lat,lng&limit=5
   with apikey + Bearer -> 200, all <= 3 decimals
No data mutation. Report table, stop.

## Acceptance (Jason)
- Desktop map: all six filter pills visible and reachable, no
  horizontal scroll, no clipping
- Pills wrap to two rows cleanly on narrow viewports
- Pills remain tappable (min 30px height preserved)
- Active pill (gold) styling unchanged
- Map render unchanged (circles, pins, popups — tripwire 17)
