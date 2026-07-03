# S4c SPEC — Comments + Moderation (v0.7.0)

Execution contract. Sonnet default. All decisions final.
Comments, report, and block ship as ONE commit — Apple guideline
1.2 treats them as inseparable for UGC apps, and so do we.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. **Comments live inline** — tapping a feed card's comment
   affordance expands an accordion thread under the card. No
   detail pages, no modals. Lazy-load on first expand.
2. **Report is write-only by design.** Reporters get a thank-you
   toast and nothing else — no status, no outcome visibility.
   The reports table has no read policy; the Supabase dashboard
   IS the moderation queue.
3. **Block = hide-from-me**, consistent with the all-public
   model: blocking filters the blocker's own feed, map pins, and
   comment threads client-side. It does not make anyone's content
   private.
4. **Owner moderation is distributed:** plant owners can delete
   any comment under their own plant (DB policy already grants
   it). Commenters can delete their own anywhere.
5. **Overflow menu is an SVG three-dot icon** (stroke, 1.6,
   currentColor) — never a character glyph or emoji.
6. Comment cap (100/day) and 280-char limit are DB-enforced;
   client mirrors both (maxlength + friendly toast on the DB
   exception).

## Claude Code tasks (one commit, v0.7.0)

### Task 1 — Comment threads
- Feed card footer gains a comment affordance (speech-bubble SVG
  + count when > 0), left of the score badge.
- Tap → accordion expands under the card:
  - Load: `sb.from('comments').select('id,user_id,body,created_at')
    .eq('plant_id', id).order('created_at')` + author names via
    the existing profiles-fetch pattern. Filter blocked authors.
  - Empty state: "Be the first to say something kind."
  - Input row at bottom: 280 maxlength, Send button. ensureAuth()
    on send; optimistic append; revert + toast on error (cap
    message surfaces as-is).
- Comment counts client-aggregated with the same in-list pattern
  as inspires (one query per feed load).

### Task 2 — Overflow menu + Report
- Three-dot SVG button on each feed card header and each comment
  row. Tap → bottom action sheet (reuse existing sheet/tag
  styling): Report · Block planter · Delete (conditional).
- Report → confirm step with optional reason input (280) →
  `sb.from('reports').insert({ target_type, target_id, reason })`
  (reporter_id defaults server-side) → toast "Reported. Thank
  you for keeping the garden safe."
- Delete visibility: own comment anywhere; any comment under
  your own plant; your own plant card (existing delete path if
  present, else add plant delete here — confirm sheet first,
  cascade handles comments/inspires).

### Task 3 — Block
- Action sheet "Block planter" → confirm: "Hide everything from
  this planter? You can unblock in Settings." → insert
  `{ blocker_id: me, blocked_id }` → immediately re-filter feed,
  map DB pins, and open comment threads.
- On app load with session: fetch my blocks once; apply the
  filter set in loadFeed, loadDbPins, and comment loads.
- Profile → Settings: "Blocked planters" row → simple list
  (display_name) with Unblock per row (delete composite).
- Never show block/report on the user's own content — Delete
  only.

### Task 4 — Version, docs
- Fan-out: footer v0.7.0 + sw.js CACHE appleseed-v0-7-0.
- CLAUDE_CONTEXT.md: S4c decisions, landmarks, roadmap; note the
  dashboard-as-mod-queue workflow.

### Task 5 — Post-deploy self-verify (rule 11, four probes)
1. index.html: v0.7.0 + markers (comment accordion fn, report
   sheet fn, block filter fn, "Blocked planters")
2. sw.js cache = appleseed-v0-7-0
3. GET {SUPABASE_URL}/rest/v1/comments?select=id&limit=1 with
   apikey + Bearer → 200 (empty array = pass). Additionally GET
   .../blocks?select=blocker_id&limit=1 → 200 [] (no session ⇒
   own-only policy returns empty — confirms RLS shape).
4. GET .../plants?select=lat,lng&limit=5 → 200, all ≤ 3 decimals.
No data mutation. Report table, stop.

## Your moderation workflow (solo-founder sized)
Supabase → Table Editor → reports (newest first). For each:
open plants or comments by target_id, judge, delete the row via
dashboard if warranted (cascades clean up inspires/comments/
notifications). No admin UI is planned until volume demands it.

## Acceptance (Jason, two-window dance again)
- Comment on your okra from incognito → count appears in normal
  window after refresh → a comment notification row lands
- Delete that comment from the NORMAL window (owner-moderation
  proof — you didn't write it, it's under your plant)
- Report a comment from incognito → row in reports table;
  incognito sees only the thank-you toast
- Block User #2 in normal window → their card and pins vanish →
  Settings list shows them → Unblock restores

## Launch-gate flag (not a build task)
S4c makes UGC real. Before any public promotion of the app:
ToS + community guidelines page, and the AIRIHA DMCA agent
registration (one filing can cover MyMeds AI and Johnny
Appleseed together). Chat-lane work; flag when ready.
