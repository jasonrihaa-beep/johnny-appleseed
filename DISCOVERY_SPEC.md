# DISCOVERY SPEC — Found Plants (v0.13.0)

Execution contract. Sonnet default. All decisions final.
One form, two truths: "I planted this" and "I found this."
Found plants join the map honestly — labeled, unscored,
safety-captioned.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. plants.kind: 'planted' | 'discovered', DB default
   'planted' (migration applied separately). Client treats a
   missing kind as 'planted' defensively.
2. TRIPWIRE 10 COROLLARY (add as tripwire 13): the kind
   toggle is a THIRD single-select group. It must NOT reuse
   the .tag-option class — it gets its own .kind-option class
   and its own selectKind() handler scoped to .kind-option
   only, so selectTag and selectAccess never touch it and
   vice versa. Styling may mirror tag-option via duplicated
   rules; class sharing is forbidden.
3. PlantScore is a PLANTING-timing answer and stays silent
   for finds: in found mode the score preview never renders
   and the insert carries score: null. Replacement is an
   identity line (PLANT_DB facts only): tags, "Texas native"
   when native, invasive warning with native alternative when
   inv, warn note when present. Unknown plant keeps the
   existing honest not-in-database state — no fabricated
   info.
4. Safety caption (harm vector: misidentified wild edibles):
   found mode always shows "Community identification — verify
   before eating anything you find." under the form; rendered
   surfaces repeat a short caution only when the find carries
   the edible tag.
5. Copy branches: submit button "Log this planting" ↔ "Log
   this find". Popup byline "by [name]" ↔ "Found by [name]".
   Feed cards for finds carry a small "Found" chip.
6. Access default stays 'private' for both kinds — one rule,
   no special case; the found-mode caption text nudges trail
   finds toward Open spot. Daily cap (50) is shared across
   kinds — same table, documented.
7. First-log setup sheet fires on the first successful log of
   EITHER kind — unchanged.

## Claude Code tasks (one commit, v0.13.0)

### Task 1 — Kind toggle on the Plant form
New form group ABOVE Plant name: two buttons "I planted this"
(default selected) / "I found this", class .kind-option only
(decision 2), handler selectKind() scoped to .kind-option.
Selecting "I found this" additionally: hides the score
preview, shows the safety caption line (decision 4), and
swaps the submit button label per decision 5. Selecting back
restores planted behavior fully.

### Task 2 — Found-mode identity line
New small div (id="found-info") under the plant-name group,
visible only in found mode when the current input exactly
matches a PLANT_DB entry (reuse dbFind): render tags, native
status, invasive warning + alt, and warn per decision 3.
PLANT_DB-sourced text only; anything user-typed that appears
goes through esc(). Hidden when no match (autocomplete's
honest unknown state already covers it).

### Task 3 — Insert + rendering
submitPlant includes kind from the toggle; score: null when
kind is 'discovered' (skip plantScore for finds). Feed cards:
when p.kind === 'discovered', add a "Found" chip (own modest
styling consistent with post-plant-tag, stone/green-50 tones)
and, if tags include edible, a one-line small-text caution
"Community ID — verify before harvesting." Map DB-pin popups:
byline becomes "Found by [name]" for finds, same edible-only
caution appended in the pin-meta line. Planted rendering
unchanged. Missing kind on old cached rows renders as
planted.

### Task 4 — Migration to repo schema
Append to schema.sql a clearly commented migration section:
"-- v0.13.0 MIGRATION (applied in dashboard)" followed by the
exact ALTER: add column if not exists kind varchar(12) not
null default 'planted' check (kind in
('planted','discovered')). No other schema file changes.

### Task 5 — Version, docs
Fan-out: footer v0.13.0 + sw.js CACHE appleseed-v0-13-0.
CLAUDE_CONTEXT.md: decisions above, tripwire 13, landmarks
(selectKind, found-info, Found chip), roadmap; note schema.sql
now carries a migration appendix.

### Task 6 — Post-deploy self-verify (rule 11, four probes)
1. index.html: v0.13.0 + markers (kind-option class,
   selectKind, "Log this find", "Found by")
2. sw.js cache = appleseed-v0-13-0
3. GET {SUPABASE_URL}/rest/v1/plants?select=kind&limit=1 with
   apikey + Bearer → 200 JSON = migration proof. A 400
   naming an unknown "kind" column = FAIL: report that the
   dashboard ALTER is still pending; do not work around it.
4. GET {SUPABASE_URL}/rest/v1/plants?select=lat,lng&limit=5
   with apikey + Bearer → 200, all ≤ 3 decimals
No data mutation. Report table, stop.

## Acceptance (Jason)
- Found mode + "Agarita": no score anywhere, identity line
  shows pollinator/wildlife/edible tags + Texas native, safety
  caption visible → log it → feed card carries the Found chip
  + harvest caution → its map popup reads "Found by Jason"
- Found mode + "Tropical Lantana": identity line shows the
  invasive warning with the native alternative — informational
  tone, since nobody planted anything
- Planted mode: log anything in-window → score renders exactly
  as before (regression check)
