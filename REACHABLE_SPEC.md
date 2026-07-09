# REACHABLE SPEC — The Primary Action Never Hides (v0.14.0)

Execution contract. Sonnet default. All decisions final.
The Plant form outgrew the viewport. Submit gets pinned,
desktop gets a scrollbar, and a fade shows content continues.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. No "keep scrolling" text or arrow. An affordance that
   instructs work is weaker than removing the work: the
   primary action is pinned instead.
2. NEW TRIPWIRE 14 — sticky, never fixed. The submit bar uses
   position: sticky inside the #content scroll container.
   position: fixed is displaced by the mobile soft keyboard
   and will jump over the input being typed in. Any future
   bottom-pinned control follows this rule.
3. Hidden scrollbars stay on touch (native app feel, original
   design intent). Fine-pointer devices get a slim brand-token
   scrollbar — desktop users read a scrollbar as the signal
   that content continues.
4. Non-destructive: #submit-plant-btn keeps its id, class, and
   onclick. selectKind() swaps its textContent between "Log
   this planting" and "Log this find" — that wiring must keep
   working untouched.
5. Layering: the bar sits above form fields but strictly BELOW
   the autocomplete dropdown, and far below the action sheet
   (z 1100/1101). Grep #plant-suggest's z-index and choose a
   value one less; do not raise the dropdown.

## Claude Code tasks (one commit, v0.14.0)

### Task 1 — Sticky submit bar
Wrap the existing #submit-plant-btn in <div id="submit-bar">
as the LAST child of #plant-view (button markup unchanged).
CSS: position: sticky; bottom: 0; background var(--stone-100);
horizontal margins that cancel #plant-view's 20px side padding
so the bar spans full width; padding 12px 20px calc(12px +
var(--safe-bottom)); z-index per decision 5.

### Task 2 — Fade scrim
A ::before pseudo-element on #submit-bar: absolutely
positioned directly above the bar, ~24px tall, full width,
linear-gradient(to top, var(--stone-100), transparent),
pointer-events: none. Visual only — no text, no glyph, no
emoji.

### Task 3 — Desktop scrollbar
Inside @media (hover: hover) and (pointer: fine) only:
#content::-webkit-scrollbar { width: 8px } with a
var(--stone-300) rounded thumb and transparent track; plus
scrollbar-width: thin and scrollbar-color: var(--stone-300)
transparent for Firefox. The existing hidden-scrollbar rule
remains the default for touch devices. Verify the Plant tab's
last form element is fully readable when scrolled to the
bottom (sticky elements occupy flow space — nothing should be
permanently hidden behind the bar).

### Task 4 — Version, docs
Fan-out: footer v0.14.0 + sw.js CACHE appleseed-v0-14-0.
CLAUDE_CONTEXT.md: decisions above, tripwire 14 (sticky never
fixed), landmark row for #submit-bar, roadmap.

### Task 5 — Post-deploy self-verify (rule 11, four probes)
1. index.html: v0.14.0 + markers (id="submit-bar",
   position: sticky on #submit-bar, "(pointer: fine)" media
   query, #submit-plant-btn id still present)
2. sw.js cache = appleseed-v0-14-0
3. GET {SUPABASE_URL}/rest/v1/profiles?select=display_name&limit=1
   with apikey + Bearer → 200 JSON
4. GET {SUPABASE_URL}/rest/v1/plants?select=lat,lng&limit=5
   with apikey + Bearer → 200, all ≤ 3 decimals
No data mutation. Report table, stop.

## Acceptance (Jason)
- PC, Plant tab, without scrolling: "Log this planting" is
  visible pinned at the bottom; a slim scrollbar is visible;
  scrolling shows the rest of the form passing under the fade
- Phone: bar pinned; tap the Note field so the keyboard opens
  — the bar must not jump over the input or disappear
- Found mode: label still swaps to "Log this find"
- Scrolled fully to the bottom: the last field and the score
  preview are fully readable, nothing trapped behind the bar
