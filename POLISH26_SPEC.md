# POLISH26 SPEC — Wordmark, Banner, and an Honest Footer (v0.26.0)

Execution contract. Sonnet default. All decisions final.
Three visual defects and one false claim: "Johnny" invisible
in the topbar (dark-on-dark), the intelligence banner's title
line too dark and the banner misaligned, and a shipped privacy
claim ("data stays on your device") that has been false since
Supabase shipped.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. #topbar-wordmark base color -> var(--ink) (light) so
   "Johnny" reads on the dark topbar; the gold span on
   "Appleseed" stays exactly as-is. Check the splash-title
   too: if .splash-title also uses a dark green for "Johnny",
   apply the same fix (screenshot suggests the splash version
   may share the defect via --stone-100-as-text being correct
   there — verify, fix only if dark).
2. .ai-banner-text strong -> a light token (var(--ink) or
   --green-200) so the title line reads; body text verify
   >= 4.5:1 on the banner fill (bump --green-700 to a lighter
   green token if it fails).
3. .ai-banner alignment: match the feed-card gutter exactly —
   same horizontal margins as .post-card so left/right edges
   line up with the cards below it. Visual symmetry, no other
   layout changes.
4. HONEST FOOTER: replace BOTH instances of "Your data stays
   on your device." (splash .splash-privacy and the profile
   footer line) with "No data selling. Your pins, your call."
   -> exact final copy: "No tracking. No ads. No data selling."
   Every clause must be literally true; the old claim has been
   false since Supabase (S2) and is a legal-review liability.
5. Map render frozen (tripwire 17).

## Claude Code tasks (one commit, v0.26.0)

### Task 1 — Wordmark legibility
Apply decision 1. Verify "Johnny" clearly legible in the
topbar on all tabs where the topbar shows.

### Task 2 — Banner fix
Apply decisions 2-3. Title line and body both legible; banner
edges aligned with feed cards.

### Task 3 — Honest footer
Apply decision 4 to both locations. Grep to confirm zero
remaining instances of "stays on your device" anywhere.

### Task 4 — Version, docs, self-verify
Fan-out: footer v0.26.0 + sw.js CACHE appleseed-v0-26-0.
CLAUDE_CONTEXT.md: notes + roadmap.
Post-deploy self-verify (rule 11, four probes):
1. index.html: v0.26.0 + #topbar-wordmark color var(--ink) +
   zero instances of "stays on your device" + ai-banner strong
   light token
2. sw.js cache = appleseed-v0-26-0
3. GET {SUPABASE_URL}/rest/v1/profiles?select=display_name&limit=1
   with apikey + Bearer -> 200
4. GET {SUPABASE_URL}/rest/v1/plants?select=lat,lng&limit=5
   with apikey + Bearer -> 200, all <= 3 decimals
No data mutation. Report table, stop.

## Acceptance (Jason)
- Topbar: "Johnny" clearly visible, "Appleseed" still gold
- Feed banner: both lines readable, edges aligned with cards
- Splash + Profile footer: new claim text, old claim gone
- Map unchanged
