# RETURNFIX SPEC — Handle the Error Where It Arrives (v0.34.0)

Execution contract. Sonnet default. All decisions final.
Diagnostic proof: linkIdentity is REDIRECT-BASED. On rejection
Supabase never returns an error to the calling code — it
navigates back to the app with ?error=server_error&error_code=
identity_already_exists&error_description=Identity+is+already+
linked+to+another+user. The in-code fallback after
linkIdentity() is unreachable for this error class. The
fallback must live in the RETURN path.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. On app load, handleOauthReturn (or a new early handler)
   parses BOTH query string and hash fragment for error,
   error_code, error_description. This runs before the params
   are cleared.
2. If error_code === 'identity_already_exists' (structured
   code field — this is not prose matching) OR
   error_description contains 'already linked': AUTO-RECOVER —
   console.log the event, await sb.auth.signOut({scope:
   'local'}) in try/catch, set a one-shot guard
   sessionStorage['ja_oauth_autoretry']='1', then call
   signInWithOAuth({ provider:'google', options:{ redirectTo:
   window.location.origin } }). The page redirects to Google
   and returns durable. The user experiences one extra bounce,
   not an error.
3. LOOP GUARD: if ja_oauth_autoretry is ALREADY '1' when an
   identity error arrives again, do NOT retry — clear the
   guard and show the persistent error dialog with the
   verbatim error_description. Clear the guard on any
   successful durable session.
4. ALL other OAuth error params on return -> persistent
   showAuthError dialog rendering error_description VERBATIM
   in the muted line (the diagnostic proved the dialog still
   shows only "Could not sign in" — that gap closes now, and
   the self-verify must check for it).
5. The v0.33 in-code fallback stays (covers genuinely thrown
   non-redirect errors). Tripwire 18 extended: redirect-based
   auth errors are handled at the RETURN, never assumed to
   reach the call site.

## Claude Code tasks (one commit, v0.34.0)

### Task 1 — Early return-error parser
Implement decisions 1-2: parse error params from
location.search AND location.hash on load, before any other
auth logic consumes/clears them. Auto-recover per decision 2.

### Task 2 — Loop guard + success cleanup
Implement decision 3. Clear ja_oauth_autoretry whenever a
durable (non-anonymous) session is confirmed on load.

### Task 3 — Verbatim error dialog
Implement decision 4: every return-path error shows
error_description verbatim in the dialog's muted line.

### Task 4 — Version, docs, self-verify
Fan-out: footer v0.34.0 + sw.js CACHE appleseed-v0-34-0.
CLAUDE_CONTEXT.md: redirect-error mechanism note, auto-retry
+ guard, tripwire 18 extension, roadmap (haze-dot pending).
Post-deploy self-verify (rule 11, four probes):
1. index.html: v0.34.0 + error_code parsing on load +
   ja_oauth_autoretry guard + signOut scope local in the
   return path + error_description rendered in showAuthError
2. sw.js cache = appleseed-v0-34-0
3. GET https://uavtaznzdpmfvkdpqyrv.supabase.co/rest/v1/profiles?select=display_name&limit=1
   with apikey + Bearer (key from index.html, ref exactly as
   in file) -> 200; if network unavailable mark NOT RUN
4. Same host: /rest/v1/plants?select=lat,lng&limit=5 -> 200,
   all <= 3 decimals
No data mutation. Report table, stop.

## Acceptance (Jason)
- Normal browser, NO clearing needed: johnnyappleseed.farm ->
  Continue with Google -> possibly one visible bounce -> Google
  consent/picker -> lands SIGNED IN: real name, real plants
- Incognito still works
- Any residual failure shows the verbatim Supabase error text
  in the dialog
