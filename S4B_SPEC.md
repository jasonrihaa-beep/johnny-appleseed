# S4b SPEC — Engagement (v0.6.0)

Execution contract. Sonnet default. All decisions final.
Makes the inspire button real, adds follows, and removes the
last dishonest surface in the app.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. **Fake people are removed; example plants are labeled.**
   The three hardcoded feed cards (Maria R., David K., Tasha W.)
   are deleted — a real network showing invented humans violates
   honest-states. The PIN_SPOTS map pins STAY as seed content but
   their popups gain the prefix "Example — " so no pin pretends
   to be a neighbor. Empty-map problem solved without deception.
2. **inspires/follows have NO column defaults** (unlike plants.
   user_id). Client sends ids explicitly; RLS `with check` is the
   enforcement. Add as tripwire 11 in CLAUDE_CONTEXT.
3. **Counts are client-aggregated.** Feed pages are ≤ ~20 plants;
   one in-list query per load beats server-side aggregates at MVP
   scale. PostgREST aggregate syntax is the upgrade path, not now.
4. **Follows get a consumption surface immediately** — a
   write-only follow is vanity. Two feed pills: Nearby (default,
   current behavior) | Following.
5. **Notifications accumulate silently until S4d.** Expected,
   documented, not a bug.
6. Blocks table exists but has no client logic until S4c (list is
   necessarily empty — no UI can populate it yet).

## Claude Code tasks (one commit, v0.6.0)

### Task 1 — Honest feed
- Delete the three hardcoded demo post cards from #feed-view.
  Live cards + existing empty state are the whole feed.
- In renderMarkers popups for PIN_SPOTS entries, prefix the note
  with "Example — ". DB pins unchanged.

### Task 2 — Real inspires (feed cards)
- On loadFeed, after plants arrive, fetch inspires for visible
  plant ids: `sb.from('inspires').select('plant_id,user_id')
  .in('plant_id', ids)`. Client-aggregate: count per plant +
  whether current session user is in each set.
- Render on each live card: inspire button (existing style) +
  count when > 0.
- Tap: ensureAuth() first (anon session created if needed —
  inspiring is a valid first action). Optimistic toggle.
  Not inspired → `.insert({ plant_id, user_id: session.user.id })`
  Inspired → `.delete().eq('plant_id', id).eq('user_id', me)`
  On error: revert UI + toast the message.
- Self-inspire allowed (no self-notification — DB handles it).

### Task 3 — Follows
- Feed card author row gains a small Follow / Following text
  button (right-aligned, .filter-pill styling at reduced size).
  Hidden on the user's own cards.
- On loadFeed: `sb.from('follows').select('followed_id')
  .eq('follower_id', me)` once per load → render states.
- Tap: ensureAuth(); insert `{ follower_id: me, followed_id:
  author }` / delete composite on unfollow. Optimistic + revert
  on error.

### Task 4 — Feed pills
- Two pills above the feed (below location bar): Nearby (default,
  current bounding-box query) | Following (plants
  `.in('user_id', followedIds)`, same ordering/limit).
- Following with zero follows → dedicated empty state: "Follow a
  planter and their gardens show up here."

### Task 5 — Version, docs, standing rule
- Fan-out: footer v0.6.0 + sw.js CACHE appleseed-v0-6-0.
- CLAUDE_CONTEXT.md: S4b decisions, tripwire 11 (no-defaults),
  landmarks, roadmap.
- BUILD_RULES.md rule 11: enumerate the FOUR standard probes so
  none can silently drop again: (1) footer version + feature
  markers, (2) sw.js cache name, (3) REST read probe on a
  relevant table, (4) plants lat/lng ≤ 3 decimals.

### Task 6 — Post-deploy self-verify (rule 11)
Poll live URL for v0.6.0 (≤3 min), then pass/fail table:
1. index.html: v0.6.0 + markers (loadInspires or equivalent fn,
   follow button class, Following pill) + "Maria R." ABSENT
2. sw.js cache = appleseed-v0-6-0
3. GET {SUPABASE_URL}/rest/v1/inspires?select=plant_id&limit=1
   with apikey + Bearer → 200 (empty array = pass)
4. GET .../plants?select=lat,lng&limit=5 → 200, all values ≤ 3
   decimal places
No data mutation during verification. Report table, stop.

## Acceptance (Jason, being user #1 — not QA)
- Inspire your own okra → count appears → survives hard refresh
- Second device/incognito anon session: inspire it again →
  count 2; Supabase notifications table shows a row for you
- Follow flow testable once a second account posts (S4c+ era);
  Following pill empty state renders meanwhile
