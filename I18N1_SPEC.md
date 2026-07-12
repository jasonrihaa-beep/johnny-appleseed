# I18N PHASE 1 SPEC — Extract Every String (v0.36.0)

Execution contract. Sonnet default. All decisions final.
Foundation for the Spanish build: every user-facing string
moves into a STR dictionary behind t(key). ENGLISH ONLY this
build — the app must render IDENTICALLY before and after.
Success is invisibility.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. One dictionary: const STR = { en: { key: "text", ... } }.
   Lookup: t(key, vars) — interpolates {name}-style vars,
   falls back to STR.en[key], console.warns on a missing key,
   NEVER returns undefined (returns the key itself as last
   resort). Language constant LANG='en' hardcoded this phase.
2. Dynamic sentences become TEMPLATES with named slots, never
   concatenation: "{name} inspired your {plant}", "{name}
   commented on your {plant}", "{name} followed you", score
   reasons, toast messages with values. Word order must be
   free to differ per language.
3. Static markup: elements whose text is UI copy get
   data-i18n="key"; one applyStrings() walker sets textContent
   from t(). Attributes (placeholder, aria-label, alt) use
   data-i18n-attr="attr:key". Walker runs once on boot.
4. NOT extracted (stays literal): "Johnny Appleseed" brand,
   "AIRIHA LLC", scientific names, PLANT_DB data content
   (names/warns/notes — that is Phase 3 data work, not UI),
   the version footer line, console/log strings.
5. Scoped tripwire-17 note: fixed UI copy inside map popups
   ("Somewhere in this circle — happy hunting.", "Private yard
   — on the map, not on the menu.", "Found by", "Example — ")
   IS extracted through t() with byte-identical English
   output; the render pipeline, tiers, and dot logic are NOT
   touched. Exception consumed; map re-freezes after.
6. Sacred key reserved (not used yet): ja_lang arrives in
   Phase 2. Note it in CLAUDE_CONTEXT now.
7. Coverage surfaces (extraction checklist — walk ALL):
   splash + welcome-back panel, topbar, tab labels, location
   bar, feed (pills, empty states, card chips/labels, caution
   line), plant form (labels, kind toggle, access options +
   caption, location row states, photo group, submit labels),
   score preview strings + scorer reason templates, discovery
   identity/safety lines, profile (stats labels, My Plants
   empty state, settings rows incl. coming-soon toasts),
   sheets (setup, action, report, block, auth error dialog),
   notifications panel rows + empty state, toasts (every
   toast() call), popup fixed copy per decision 5.

## Claude Code tasks (one commit, v0.36.0)

### Task 1 — STR + t() + applyStrings()
Implement decisions 1-3. Place STR near the top of the script
(above first use), t() and applyStrings() beside it.

### Task 2 — Extraction sweep
Walk decision 7's surfaces. Replace literals with t() calls /
data-i18n attributes. Templates per decision 2. Report the
final key COUNT and list any user-facing string deliberately
left unextracted with a one-line reason each.

### Task 3 — Identity verification (the core check)
After extraction, verify the rendered app is textually
IDENTICAL: for at least 12 known strings across surfaces
(splash tagline, a tab label, access caption, an empty state,
a toast, popup haze copy, a score reason, a settings row...),
grep/execute to confirm the exact same English text is
produced. Any visible diff is a defect.

### Task 4 — Guard rails
Confirm t() fallback behavior with a deliberate missing-key
test in console (then remove the test). node --check passes.

### Task 5 — Version, docs, self-verify
Fan-out: footer v0.37?? NO — footer v0.36.0 + sw.js CACHE
appleseed-v0-36-0. CLAUDE_CONTEXT.md: i18n architecture,
STR/t()/applyStrings landmarks, ja_lang reserved, tripwire-17
exception consumed, roadmap (Phase 2 Spanish dictionary next).
Post-deploy self-verify (rule 11, four probes):
1. index.html: v0.36.0 + const STR + function t( +
   applyStrings + data-i18n present + the 12 identity strings
   render byte-identical (list them)
2. sw.js cache = appleseed-v0-36-0
3. GET https://uavtaznzdpmfvkdpqyrv.supabase.co/rest/v1/profiles?select=display_name&limit=1
   with apikey + Bearer (key from index.html, ref exactly as
   in file) -> 200; network unavailable = NOT RUN, never pass
4. Same host: /rest/v1/plants?select=lat,lng&limit=5 -> 200,
   all <= 3 decimals
No data mutation. Report table, stop.

## Acceptance (Jason)
- The app looks and reads EXACTLY as before — every tab, every
  sheet, every toast. If you can find ANY changed text, that
  is a bug to report.
- Everything still functions: log a plant, open popups, open
  notifications, trigger a toast.
