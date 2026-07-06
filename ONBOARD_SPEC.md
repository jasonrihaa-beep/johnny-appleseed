# ONBOARD SPEC — Get Started Setup Flow (v0.10.0)

Execution contract. Sonnet default. All decisions final.
The splash's Get started button becomes a real onboarding
entry: explicit-choice profile setup, reusing the S4d sheet.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. AMENDS S4d decision 5: the setup sheet fires on the FIRST
   successful plant log OR on an explicit Get-started tap —
   never automatically on app open. "No account required to
   browse" remains a shipped promise; the Browse path creates
   no session and shows no sheet.
2. ja_profile_prompted semantics unchanged and still sacred:
   any presentation of the sheet sets it on Save OR Skip;
   once '1' the sheet never fires again from either trigger.
3. The sheet gains parameterized title/body. First-log
   context keeps "You're on the map." Splash context uses
   "Welcome to the neighborhood." / "What should neighbors
   call you?" (honest states — the splash user is not on the
   map yet).
4. Get started on a device where ja_profile_prompted is
   already '1' simply enters the app (returning-visitor
   guard; flag is device-local, accepted).
5. Entry is never blocked: if ensureAuth() fails at splash
   (offline, provider issue), toast the message and enter the
   app without the sheet.
6. This build ships name + avatar only; the Google option
   joins this same sheet in the immediately following build
   (v0.11.0). The existing Profile > Keep your garden path is
   unchanged.

## Claude Code tasks (one commit, v0.10.0)

### Task 1 — Split the splash handlers
Get started button → new getStartedFlow(): if localStorage
ja_profile_prompted === '1' → enterApp() only. Otherwise →
enterApp(), then ensureAuth(), then open the existing setup
sheet in splash context (decision 3 copy), sheet appearing
over the map view. Browse without an account → enterApp()
unchanged, no auth call, no sheet.

### Task 2 — Parameterize the setup sheet
Existing S4d sheet function accepts title/body params with
first-log defaults preserved. Save reuses the existing
profile update path; Save and Skip both set
ja_profile_prompted = 1 with the existing read-back verify.
First-log trigger behavior is unchanged for Browse-path users.

### Task 3 — ensureAuth failure path
Wrap the splash-context ensureAuth in try/catch: on failure,
toast the error message and continue into the app without the
sheet (decision 5). Do not set the flag on this path — the
user was never shown the sheet.

### Task 4 — Version, docs
Fan-out: footer v0.10.0 + sw.js CACHE appleseed-v0-10-0.
CLAUDE_CONTEXT.md: decision-5 amendment, sheet
parameterization landmark, getStartedFlow landmark, roadmap.

### Task 5 — Post-deploy self-verify (rule 11, four probes)
1. index.html: v0.10.0 + markers (getStartedFlow, splash-
   context sheet title "Welcome to the neighborhood",
   ja_profile_prompted guard in getStartedFlow)
2. sw.js cache = appleseed-v0-10-0
3. GET {SUPABASE_URL}/rest/v1/profiles?select=display_name&limit=1
   with apikey + Bearer → 200 JSON
4. GET {SUPABASE_URL}/rest/v1/plants?select=lat,lng&limit=5
   with apikey + Bearer → 200, all ≤ 3 decimals
No data mutation. Report table, stop.

## Acceptance (Jason)
- Fresh incognito: Get started → sheet appears over the map
  with "Welcome to the neighborhood." → name it → Profile
  shows the name → close incognito, reopen same window:
  Get started → straight in, no sheet (flag held)
- Second fresh incognito: Browse without an account → no
  sheet, and Supabase auth Users gains NO new row until a
  first action (browse is truly accountless)
- Browse-path user logs a first plant → first-log sheet still
  fires once with "You're on the map."
