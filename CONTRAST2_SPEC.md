# CONTRAST2 SPEC — The Last Light Islands (v0.25.0)

Execution contract. Sonnet default. All decisions final.
The v0.21 sweep converted background:white elements but missed
light surfaces using other values (green-50 family). Reported:
notification rows are white cards with near-invisible light
text; the feed photo-placeholder is a glaring light box.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. Complete the dark theme: NO light-family surface may pair
   with light-remapped text tokens anywhere. Sweep ALL
   background declarations using light values (white, #fff,
   green-50/#E8F0E4-family, stone light hexes) — not just
   "background: white".
2. Notification panel rows -> var(--stone-200) surface, light
   text tokens, unread accent kept legible. The panel itself
   verified opaque enough over any tab.
3. Feed photo-placeholder container -> dark tint
   (rgba green over --stone-200 or #1C2B22 with the sprig SVG
   in a muted light sage stroke) — visibly an illustration
   slot, no longer a light slab. Same treatment anywhere the
   placeholder renders.
4. The .google-btn remains the ONLY intentionally-white
   element (branded, hardcoded dark text) — exempt.
5. Map render frozen (tripwire 17, popup exception already
   applied in v0.21 stands — no further popup changes needed
   unless a light surface is found inside one).

## Claude Code tasks (one commit, v0.25.0)

### Task 1 — Systematic light-surface sweep
Grep ALL background/background-color declarations; list every
one resolving to a light value (white/#fff variants, #E8F0E4,
green-50 token usages, any hex with high luminance). For each:
convert to the appropriate dark token per decisions 2-3, then
verify the text/icons on it meet the floor (body 4.5:1). The
google-btn is exempt (decision 4).

### Task 2 — Notification rows
Apply decision 2. Verify actor name, message text, and
timestamp are all clearly legible; unread vs read state still
visually distinct on dark.

### Task 3 — Placeholder container
Apply decision 3 in feed cards (and any other placeholder
render sites).

### Task 4 — Version, docs, self-verify
Fan-out: footer v0.25.0 + sw.js CACHE appleseed-v0-25-0.
CLAUDE_CONTEXT.md: sweep-completion note, roadmap.
Post-deploy self-verify (rule 11, four probes):
1. index.html: v0.25.0 + no light-value backgrounds outside
   .google-btn (report the grep evidence), notification row
   dark marker, placeholder dark marker
2. sw.js cache = appleseed-v0-25-0
3. GET {SUPABASE_URL}/rest/v1/notifications?select=id&limit=1
   with apikey + Bearer -> 200
4. GET {SUPABASE_URL}/rest/v1/plants?select=lat,lng&limit=5
   with apikey + Bearer -> 200, all <= 3 decimals
No data mutation. Report table, stop.

## Acceptance (Jason)
- Notifications panel: rows dark, text crisp, timestamps
  readable, unread still distinguishable
- Feed: placeholder slot reads as a subtle dark illustration
  card, not a light slab
- Nothing else visually regressed; Google button still white
- Map unchanged
