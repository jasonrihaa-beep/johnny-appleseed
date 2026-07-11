# GOOGLEFIX2 SPEC — Fallback That Actually Fires (v0.32.0)

Execution contract. Sonnet default. All decisions final.
v0.30.0's fallback checks error.message for the literal string
'identity_already_exists', but Supabase returns human-readable
text ("Identity is already linked to another user"). The match
fails, the signInWithOAuth fallback never fires, and returning
users are stranded. Also: auth errors flash past unreadably and
a failed sign-in leaves no retry path.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. NEVER pattern-match fragile provider error strings. New
   policy: if linkIdentity() fails for ANY reason on an
   anonymous session, fall back to signInWithOAuth()
   unconditionally. Worst case the sign-in also fails and we
   surface that error; best case the returning user reaches
   their real account. Log the raw link error to console for
   diagnostics before falling back.
2. Auth errors must be READABLE: a failed auth attempt shows a
   persistent, dismissible message (not a 2-second toast).
   Reuse the existing sheet/dialog styling; include the raw
   provider message so the user can report it.
3. NEVER strand the user: the Profile must always render a
   working "Sign in with Google" row whenever there is no
   durable (non-anonymous) session — including after a failed
   attempt. Verify #sign-in-row visibility logic covers the
   post-failure state.
4. Success must be UNAMBIGUOUS: on a successful durable
   sign-in, show a persistent confirmation in Profile ("Signed
   in with Google" + the account email if available) in
   addition to the return toast.
5. TRIPWIRE 18 (v0.30) stands and is strengthened: every Google
   entry point handles BOTH link and sign-in, and the fallback
   must not depend on error-string matching.

## Claude Code tasks (one commit, v0.32.0)

### Task 1 — Unconditional fallback
In googleSignIn(): if the session is anonymous, call
linkIdentity(); if it returns ANY error, console.error the raw
error, then immediately call signInWithOAuth() with the same
options. Only if THAT also errors do we surface a failure.
Remove the 'identity_already_exists' string check entirely.
If there is no session at all, or the session is already
durable, call signInWithOAuth() directly.

### Task 2 — Persistent, readable auth errors
Replace the transient toast on auth failure with a persistent
dismissible message showing the human-readable error plus the
raw provider message. Same treatment in handleOauthReturn()
for return-path errors (currently "Google sign-in didn't
complete" — make it persistent and include the underlying
error text from the URL params).

### Task 3 — Never strand: always offer sign-in
Audit the Profile sign-in row logic: whenever there is no
durable session (no session at all, OR session.user
.is_anonymous === true), the Sign in with Google row MUST be
visible and functional. Verify this holds after a failed
attempt and after a failed OAuth return.

### Task 4 — Unambiguous success state
On durable session, Profile shows a clear persistent "Signed
in with Google" state (with email if present). This replaces
guessing whether sign-in worked.

### Task 5 — Version, docs, self-verify
Fan-out: footer v0.32.0 + sw.js CACHE appleseed-v0-32-0.
CLAUDE_CONTEXT.md: no-string-matching policy, persistent auth
errors, never-strand rule, roadmap (haze-dot fix still
pending).
Post-deploy self-verify (rule 11, four probes):
1. index.html: v0.32.0 + zero occurrences of
   'identity_already_exists' + signInWithOAuth called
   unconditionally after any link error + persistent auth
   error UI present + sign-in row visible when anonymous
2. sw.js cache = appleseed-v0-32-0
3. GET https://uavtaznzdpmfvkdpqyrv.supabase.co/rest/v1/profiles?select=display_name&limit=1
   with apikey + Bearer (read the anon key from index.html) ->
   200. Use the project ref EXACTLY as it appears in
   index.html; do not invent a URL. If the network is
   unavailable, say so and mark the probe as NOT RUN, never
   as passed.
4. Same host: /rest/v1/plants?select=lat,lng&limit=5 -> 200,
   all <= 3 decimals
No data mutation. Report table, stop.

## Acceptance (Jason)
- At johnnyappleseed.farm: clear site data -> Continue with
  Google -> lands SIGNED IN to the original account: real
  name, real plants, correct counts. No "identity linked"
  error.
- Any auth error now shows a readable persistent message
- After a failed attempt, a working Sign in option is still
  visible in Profile (never stranded)
- Profile clearly shows "Signed in with Google" when durable
