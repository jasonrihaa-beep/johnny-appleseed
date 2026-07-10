# CONTRAST SPEC — Finish the Dark Theme (v0.21.0)

Execution contract. Sonnet default. All decisions final.
v0.18.0 remapped text tokens but left elements on hardcoded
light backgrounds — light islands, several with invisible
light-on-light text. This converts the remaining ones to theme
surfaces. The Google button, sheet backdrop, and toast band
already shipped in v0.20.0 and are OUT OF SCOPE.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. ROOT CAUSE: hardcoded background:white + dark-theme text
   tokens (now light) = light-on-light. Fix by moving these
   surfaces to var(--stone-200) so they darken with the app.
   Worst instance: Leaflet popup heading (--ink, near-white,
   on white — invisible; the reported Beautyberry bug).
2. TRIPWIRE 17 SCOPED EXCEPTION: this build MAY style Leaflet
   POPUP surfaces (.leaflet-popup-content-wrapper, -tip, popup
   content classes) to fix the invisible heading. It may NOT
   touch #leaflet-map, L.circle, addHazeCircle, the access
   opacity tiers, markers, or pick mode. Popups are chrome;
   the map render stays frozen. Update tripwire 17 wording.
3. Convert background:white -> var(--stone-200), text verified
   against contrast floor (body 4.5:1), for: sheet-btn,
   suggest-item, tag-option, kind-option, found-info,
   name-edit-btn, stat-card, location-bar. The .google-btn is
   NOT in this list — it correctly stays white (shipped
   v0.20.0), do not change it.
4. Leaflet popup: wrapper + tip bg -> #1C2B22; heading
   (strong) -> #F5F1E8; pin-meta -> #8FA398; pin-note ->
   #C3D2C8; pin-sci -> #8FA398; pin-score -> --green-400 if
   --green-600 reads too dark on the new bg; chips + haze copy
   verified legible. Box-shadow stays.
5. #E8F0E4 map placeholder/loading backgrounds (lines ~197,
   ~264) -> #14211A so no light flash before tiles load. This
   is the map CONTAINER background, not the map render.

## Claude Code tasks (one commit, v0.21.0)

### Task 1 — Convert light-island surfaces
sheet-btn, suggest-item, tag-option, kind-option, found-info,
name-edit-btn, stat-card, location-bar: background:white ->
var(--stone-200); verify each element's text/icon reads on the
dark surface via existing tokens. Selected/active tints
(tag/kind) keep their green/gold/violet meaning; verify they
read on dark, darken via -50/-100 tokens only if needed.

### Task 2 — Leaflet popup dark (scoped tripwire-17 exception)
Per decision 4. This fixes the reported invisible-heading bug.

### Task 3 — Map placeholder background
#E8F0E4 -> #14211A in the map loading/placeholder state only.

### Task 4 — Contrast sweep
Walk every surface changed here; body text >= 4.5:1, secondary
>= 3:1. Special attention: popup heading, suggest dropdown,
found-info facts, stat-card numbers.

### Task 5 — Version, docs
Fan-out: footer v0.21.0 + sw.js CACHE appleseed-v0-21-0.
CLAUDE_CONTEXT.md: root-cause note, tripwire 17 scoped
exception, roadmap.

### Task 6 — Post-deploy self-verify (rule 11, four probes)
1. index.html: v0.21.0 + markers (leaflet-popup-content-wrapper
   background #1C2B22, no "background: white" on stat-card /
   tag-option, map placeholder #14211A)
2. sw.js cache = appleseed-v0-21-0
3. GET {SUPABASE_URL}/rest/v1/plants?select=access&limit=1
   with apikey + Bearer -> 200 JSON
4. GET {SUPABASE_URL}/rest/v1/plants?select=lat,lng&limit=5
   with apikey + Bearer -> 200, all <= 3 decimals
No data mutation. Report table, stop.

## Acceptance (Jason)
- Map popup: "American Beautyberry" heading clearly readable
  (dark popup, light text); score, note, chips legible
- Plant form: tag/kind buttons, found-info, autocomplete
  dropdown readable on dark
- Profile: stat cards readable
- Map circles + pins: UNCHANGED (popups restyled only — a
  changed circle is a violation, report it)
- Google button: still white with dark text (unchanged from
  v0.20.0)
