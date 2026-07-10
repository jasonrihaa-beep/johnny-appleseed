# CONTRAST3 SPEC — Fix the Tokens, Not the Sightings (v0.28.0)

Execution contract. Sonnet default. All decisions final.
Root causes found by audit: #toast uses --stone-100 (now
near-black) as text — every popup in the app is unreadable;
the active filter pill has the same defect; ten instances of
dark --green-700 as TEXT on dark surfaces. Plus: commit the
recropped hero assets (Gemini watermark removed).

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. #toast: color -> var(--ink). Background var(--green-900)
   stays (dark pill, light text — correct). This fixes EVERY
   toast at once, including the map-open location toast.
2. .filter-pill.active: color -> var(--ink) (was --stone-100,
   near-black on green). Inactive pills already correct.
3. Text-color sweep: every `color: var(--green-700)` where it
   renders TEXT on a dark surface -> var(--green-400) (lighter
   green, palette-consistent): tab-btn.active + .tab-label,
   found-info-tags, comment/inspire hover text colors, topbar
   icon color (line ~136), and the others found by grep.
   BORDERS using green-700 stay green-700 (borders read fine).
   Verify each swap >= 4.5:1 for body-size text.
4. The Planting-reminders row toast text is wrong: change
   'Notifications coming soon' -> 'Reminders coming soon'.
5. Commit the two replaced files in assets/ (recropped, 8%
   right trim, watermark removed; video also smaller). The
   crossfade alignment is preserved (identical relative crop).
6. Map render frozen (tripwire 17).

## Claude Code tasks (one commit, v0.28.0)

### Task 1 — Toast + active pill (decisions 1-2)
### Task 2 — green-700-as-text sweep (decision 3)
Grep `color: var(--green-700)`, apply swaps, report each line
changed with its element.
### Task 3 — Toast label fix (decision 4)
### Task 4 — Commit replaced assets (decision 5)
git add assets/hero-image.jpg assets/hero-video.mp4 with the
build commit. Confirm new sizes in the report (~538KB / ~2.3MB).
### Task 5 — Version, docs, self-verify
Fan-out: footer v0.28.0 + sw.js CACHE appleseed-v0-28-0 (the
cache bump is REQUIRED for the new hero image to reach
returning visitors — the old one may be precached).
CLAUDE_CONTEXT.md: token-fix notes, coming-soon stub inventory
(Search, AI key, Feed radius, Planting reminders), roadmap.
Post-deploy self-verify (rule 11, four probes):
1. index.html: v0.28.0 + #toast color var(--ink) +
   filter-pill.active color var(--ink) + zero remaining
   `color: var(--green-700)` on text elements (report grep)
2. sw.js cache = appleseed-v0-28-0
3. GET {SUPABASE_URL}/rest/v1/plants?select=access&limit=1
   with apikey + Bearer -> 200
4. GET {SUPABASE_URL}/rest/v1/plants?select=lat,lng&limit=5
   with apikey + Bearer -> 200, all <= 3 decimals
No data mutation. Report table, stop.

## Acceptance (Jason)
- Tap Planting reminders: toast reads "Reminders coming soon"
  in crisp light text on the dark pill
- Open the Map tab: whatever toast fires is readable
- Active filter pill: text clearly legible; active tab label
  brighter green, matching the palette
- Splash: hero image/video play with NO diamond in the corner
- Map circles unchanged
