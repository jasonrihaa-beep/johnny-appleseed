# A11Y SPEC — Keyboard and Screen Readers, Both Languages (v0.42.0)

Execution contract. Sonnet default. All decisions final.
Audit: one :focus style app-wide, no focus management in
sheets, and all aria-labels hardcoded English on a bilingual
app. This build makes the app operable by keyboard and honest
to screen readers in both languages.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. Focus visibility: a single global rule —
   :focus-visible { outline: 2px solid var(--gold-400);
   outline-offset: 2px; } — applies to all interactive
   elements (buttons, links, inputs, pills, tab bar, FAB).
   Mouse/touch users see nothing new (:focus-visible only);
   keyboard users can finally see where they are.
2. Sheets become real dialogs: the action sheet (all variants:
   setup, report, confirm, delete) gets role="dialog"
   aria-modal="true", focus moves INTO the sheet on open
   (first focusable), Tab/Shift-Tab cycle inside (focus trap),
   Escape closes ONLY where closing is non-destructive
   (Escape = the cancel path, never the confirm path), and
   focus RETURNS to the invoking element on close.
3. aria-labels join the i18n system: every hardcoded
   aria-label becomes a STR key applied via the existing
   data-i18n-attr mechanism (Phase 1 built this exact rail).
   New keys in BOTH languages for each: close, remove photo,
   notifications bell, avatar color, search, refresh feed,
   and every other aria-label found by grep. Parity must hold.
4. Tab bar semantics: the four tabs get aria-current="page"
   on the active tab (updated on switchTab); the notification
   bell gets aria-expanded reflecting panel state.
5. Feed photo alts: plant photos use the plant name as alt
   (dynamic, not a static string); the placeholder keeps its
   existing labeled illustration semantics.
6. Interactive-element audit: any onclick on a non-button
   element (div/span) either becomes a <button> or gains
   tabindex="0" + Enter/Space keydown handling. Grep onclick,
   report each non-button case and its fix.
7. No visual redesign: outline on focus is the ONLY visible
   change for sighted mouse users.

## Claude Code tasks (one commit, v0.42.0)

### Task 1 — Global :focus-visible rule (decision 1)
### Task 2 — Sheet dialog semantics + focus trap + Escape +
focus return (decision 2)
### Task 3 — aria-label i18n migration (decision 3) + tab/bell
semantics (decision 4) + photo alts (decision 5)
### Task 4 — Interactive-element audit (decision 6, report the
list)
### Task 5 — Version, docs, self-verify
Fan-out: footer v0.42.0 + sw.js CACHE appleseed-v0-42-0.
CLAUDE_CONTEXT.md: a11y landmarks, the focus-trap component
note, roadmap.
Post-deploy self-verify (rule 11, four probes):
1. index.html: v0.42.0 + :focus-visible rule + aria-modal +
   focus-trap keydown + aria-current + zero hardcoded English
   aria-label strings remaining outside STR (report grep) +
   en/es key parity EQUAL (report counts)
2. sw.js cache = appleseed-v0-42-0
3. GET https://uavtaznzdpmfvkdpqyrv.supabase.co/rest/v1/profiles?select=display_name&limit=1
   with apikey + Bearer (key from index.html, ref exactly as
   in file) -> 200; network unavailable = NOT RUN, never pass
4. Same host: /rest/v1/plants?select=lat,lng&limit=5 -> 200,
   all <= 3 decimals
No data mutation. Report table, stop.

## Acceptance (Jason)
- PC, mouse untouched: Tab through the app — a gold outline
  moves through pills, tabs, buttons; nothing visible changes
  when using the mouse
- Open any sheet with keyboard (Tab to it, Enter): focus jumps
  inside, Tab cycles within it, Escape cancels (never
  confirms), focus lands back where you were
- Delete-account confirm: Escape = cancel; the armed delete
  button still requires deliberate activation
- Switch to Español: (if you use a screen reader, labels read
  in Spanish; otherwise trust the probe's parity check)
