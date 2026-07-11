# AUTHCLEAN SPEC — Purge Zombies, Name the Error (v0.33.0)

Execution contract. Sonnet default. All decisions final.
Diagnostic evidence: sign-in fails BEFORE any redirect to
Google (no picker, no OAuth params ever appear), while the
stored session's queries return 401 — a zombie local session
(token for a user that can no longer authenticate) breaks the
authorize step. Also: the v0.32 error dialog shows only
"Could not sign in" — the raw provider message the spec
required is missing, which is why diagnosis took this long.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. RAW ERRORS, ALWAYS: showAuthError must display the
   human-readable line PLUS the raw error (e.message, and
   e.status/e.code when present) in smaller muted text. An
   auth failure that hides its reason is a diagnosis tax —
   this dialog exists for exactly one user journey: reporting
   what went wrong.
2. ZOMBIE PURGE: in googleSignIn(), when the link path errors,
   call `await sb.auth.signOut({ scope: 'local' })` BEFORE the
   signInWithOAuth fallback — abandoning the anon session is
   already accepted policy (GOOGLEFIX decision 3), and a
   corrupt/deleted-user session must never poison the clean
   sign-in. scope:'local' only clears this browser's stored
   session; it cannot sign out other devices.
3. DYNAMIC ORIGIN (supersedes the unpasted ORIGINFIX):
   redirectTo becomes window.location.origin everywhere —
   user returns to the origin they started from; .farm stays
   canonical; the onrender mirror and installed PWAs work.
   Grep for redirectTo and update every occurrence; report
   them.
4. TRIPWIRE 18 extended: auth flows are origin-agnostic and
   zombie-tolerant; auth errors always surface raw provider
   text.

## Claude Code tasks (one commit, v0.33.0)

### Task 1 — Raw error surfacing
Update showAuthError(title, rawError) usage so every call
passes the caught error; the dialog renders title + raw
message/status in muted small text + Dismiss. Update the
handleOauthReturn failure path the same way (include any
error/error_description URL params verbatim).

### Task 2 — Zombie purge in the fallback
In googleSignIn(): on any linkIdentity error -> console.error
the raw error -> await sb.auth.signOut({ scope: 'local' })
(wrapped in try/catch, ignore its own errors) -> then
signInWithOAuth. Also purge before the direct-sign-in path IF
getSession() returned a session but a lightweight authed check
fails — keep it simple: purge only on the fallback path unless
trivial.

### Task 3 — Dynamic origin
Per decision 3.

### Task 4 — Version, docs, self-verify
Fan-out: footer v0.33.0 + sw.js CACHE appleseed-v0-33-0.
CLAUDE_CONTEXT.md: decisions above, ORIGINFIX superseded note,
roadmap (haze-dot still pending).
Post-deploy self-verify (rule 11, four probes):
1. index.html: v0.33.0 + signOut scope local in the fallback +
   redirectTo: window.location.origin (zero hardcoded app
   origins in auth opts) + showAuthError renders raw error
2. sw.js cache = appleseed-v0-33-0
3. GET https://uavtaznzdpmfvkdpqyrv.supabase.co/rest/v1/profiles?select=display_name&limit=1
   with apikey + Bearer (key from index.html; project ref
   EXACTLY as in the file) -> 200; if network unavailable,
   mark NOT RUN, never passed
4. Same host: /rest/v1/plants?select=lat,lng&limit=5 -> 200,
   all <= 3 decimals
No data mutation. Report table, stop.

## Acceptance (Jason)
- Normal browser (after ONE full site-data clear to evict the
  current zombie): johnnyappleseed.farm -> Continue with
  Google -> signed in, real name, real plants
- If anything fails, the dialog now shows the RAW error text —
  screenshot it and the cause is named
- Incognito still works; onrender mirror sign-in also works
