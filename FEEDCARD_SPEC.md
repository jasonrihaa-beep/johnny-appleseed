# FEEDCARD SPEC — Photos Earn Their Space (v0.27.0)

Execution contract. Sonnet default. All decisions final.
Photoless feed cards currently render a full-size empty
placeholder slot — ~70% dead space per card. Cards become
text-first; the photo block renders ONLY when a photo exists.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. The universal placeholder is REMOVED from feed cards. A
   card without photo_url renders no media block at all:
   author row, plant name + chips, note, caution line (finds),
   action row — compact. Cards with photo_url keep the current
   full-width 4:3 image exactly as-is.
2. The placeholder SVG asset may remain in the codebase if
   referenced elsewhere; if feed cards were its only use,
   remove the dead markup/CSS (grep for references first —
   report what was found).
3. Spacing: photoless cards get tightened vertical padding so
   they read as intentional compact cards, not cards missing
   something.
4. Map popups unchanged (they already omit placeholders).
   Map render frozen (tripwire 17).

## Claude Code tasks (one commit, v0.27.0)

### Task 1 — Conditional media block
In the feed-card renderer: emit the photo container ONLY when
the row has a non-empty photo_url. No placeholder branch.

### Task 2 — Compact photoless spacing
Apply decision 3; verify a mixed feed (photo + photoless
cards) reads cleanly with consistent gutters.

### Task 3 — Version, docs, self-verify
Fan-out: footer v0.27.0 + sw.js CACHE appleseed-v0-27-0.
CLAUDE_CONTEXT.md: decision notes, placeholder-usage grep
result, roadmap.
Post-deploy self-verify (rule 11, four probes):
1. index.html: v0.27.0 + feed renderer emits media block only
   on photo_url (show the conditional), no placeholder in the
   feed-card path
2. sw.js cache = appleseed-v0-27-0
3. GET {SUPABASE_URL}/rest/v1/plants?select=photo_url&limit=1
   with apikey + Bearer -> 200
4. GET {SUPABASE_URL}/rest/v1/plants?select=lat,lng&limit=5
   with apikey + Bearer -> 200, all <= 3 decimals
No data mutation. Report table, stop.

## Acceptance (Jason)
- Feed: photoless cards are compact text cards — no empty
  slab; photo cards unchanged
- Mixed feed reads clean; nothing feels "missing"
- Map unchanged
