# ONBOARD GOOGLE SPEC — Durable Accounts at Minute Zero (v0.11.0)

Execution contract. Sonnet default. All decisions final.
The setup sheet gains Continue with Google. Provider is
confirmed live in production (linkIdentity path verified).

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. The Google option appears in BOTH sheet contexts (splash
   Get-started and first-log) — one component, two triggers.
2. Tapping Google sets ja_profile_prompted = '1' (read-back
   verify) BEFORE initiating the redirect — the OAuth redirect
   leaves the page, so the flag must not depend on returning.
   Tradeoff accepted and documented: if linkIdentity throws
   before redirect, toast the error and keep the sheet open for
   this presentation; future sessions skip the sheet (flag set).
3. No name prefill from Google metadata. The user returns as
   "Garden protected — Google" with display_name still
   editable via Profile. Honest and minimal.
4. Existing Save / Skip behavior unchanged. Email path in
   Profile unchanged.

## Claude Code tasks (one commit, v0.11.0)

### Task 1 — Google option in the setup sheet
Below the avatar row, above Save/Skip: divider, then a
"Continue with Google" button (reuse the existing inline SVG G
mark and button styling from the S4d Keep-your-garden row —
stroke style, no emoji). Tap → set ja_profile_prompted = '1'
with read-back verify → sb.auth.linkIdentity({ provider:
'google', options: { redirectTo:
'https://johnny-appleseed.onrender.com' } }). Session is
anonymous at this point in both contexts (getStartedFlow and
first-log both run ensureAuth first) — linkIdentity is correct;
do not use signInWithOAuth here. On thrown error: toast the
message, keep the sheet open (decision 2).

### Task 2 — Version, docs
Fan-out: footer v0.11.0 + sw.js CACHE appleseed-v0-11-0.
CLAUDE_CONTEXT.md: decisions above, landmark for the sheet
Google handler, roadmap.

### Task 3 — Post-deploy self-verify (rule 11, four probes)
1. index.html: v0.11.0 + markers (sheet Google handler fn,
   linkIdentity within the sheet component, flag-before-
   redirect ordering visible in source)
2. sw.js cache = appleseed-v0-11-0
3. GET {SUPABASE_URL}/rest/v1/profiles?select=display_name&limit=1
   with apikey + Bearer → 200 JSON
4. GET {SUPABASE_URL}/rest/v1/plants?select=lat,lng&limit=5
   with apikey + Bearer → 200, all ≤ 3 decimals
No data mutation. Report table, stop.

## Acceptance (Jason)
- Fresh incognito: Get started → sheet shows Continue with
  Google → tap → consent → return to the live app signed in,
  "Garden protected — Google", no sheet re-fire
- Second fresh incognito: Get started → Save a name instead →
  unchanged v0.10.0 behavior
- Email-verification link from the Profile path now lands on
  johnny-appleseed.onrender.com, not localhost (Site URL fix
  proof — run this once after correcting Site URL)
