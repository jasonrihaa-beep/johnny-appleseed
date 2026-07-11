# GOOGLEFIX SPEC — Link OR Sign In (v0.30.0)

Execution contract. Sonnet default. All decisions final.
Returning users hit "already linked to another account" and end
up stranded in a fresh anonymous session. Root cause: the setup
sheet calls linkIdentity() unconditionally. Correct behavior is
LINK for new users, SIGN IN for returning ones.

## Root cause
Clearing site data destroys the anonymous session; a NEW
anonymous user is minted. The Google button then tries to LINK
Google to that new user — but Google is already linked to the
original account, so Supabase (correctly) refuses with
"already linked to another account" / identity_already_exists.
The session stays anonymous, so handleOauthReturn reports
"Google sign-in didn't complete." The user's real account,
name, and plants are intact on the server but unreachable.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. AMENDS ONBOARD_GOOGLE (v0.11) decision: "linkIdentity ONLY,
   never signInWithOAuth" was WRONG. Correct policy: attempt
   linkIdentity FIRST (the new-user path, keeps plants on a
   fresh anon session); when it fails with identity_already_
   exists, FALL BACK to signInWithOAuth (the returning-user
   path, switches to the existing durable account). Both flows
   are legitimate and required.
2. googleSignIn() unified for both contexts (setup sheet +
   Profile sign-in row). Removed setupSheetGoogle() — it was a
   duplicate, and the return flow never needs to know which
   button was tapped. The marker ja_profile_prompted is NO
   LONGER USED (was the setup-sheet-seen flag); remove all
   references to it from code and localStorage — the OAuth
   return flow gates the name-confirm sheet on "still Planter",
   not on which button launched the flow.
3. Error surface: identity_already_exists is NEVER shown to
   the user as an error — it is an internal signal that the
   fallback path must run. The fallback is attempted silently.
   Only the SECOND failure (signInWithOAuth also failed) is
   surfaced. Other OAuth errors (user cancelled, network) are
   still toasted verbatim.
4. ja_oauth_return marker stays sessionStorage — tab-scoped,
   ephemeral, set BEFORE the redirect (unchanged).
5. The Profile sign-in row and setup sheet Google button call
   the SAME function with the SAME flow. No "which context"
   branches.

## Claude Code tasks (one commit, v0.30.0)

### Task 1 — Unify and fix googleSignIn()
Replace setupSheetGoogle() with a single googleSignIn() that:
1) sets ja_oauth_return marker, 2) attempts linkIdentity, 3) if
identity_already_exists → silently fall back to signInWithOAuth,
4) any other error → toast + clean up marker, 5) success →
redirect happens. Both buttons call googleSignIn(). Remove all
ja_profile_prompted writes (it is no longer used).

### Task 2 — Clean up the return flow
handleOauthReturn() no longer checks ja_profile_prompted
(already removed in v0.12.0 per the existing code). Verify it
gates the name-confirm sheet ONLY on "myProfile.display_name
=== 'Planter'" (already correct per OAUTH_RETURN spec). Remove
any lingering references to ja_profile_prompted.

### Task 3 — localStorage hygiene
Add a one-time cleanup on boot: if ja_profile_prompted exists,
remove it (legacy key, no longer used). This runs once per
device and is harmless if the key is already gone.

### Task 4 — Version, docs, self-verify
Fan-out: footer v0.30.0 + sw.js CACHE appleseed-v0-30-0.
CLAUDE_CONTEXT.md: Google fix decisions (v0.30.0), amended
ONBOARD_GOOGLE note (both paths legitimate), roadmap.
Post-deploy self-verify (rule 11, four probes):
1. index.html: v0.30.0 + googleSignIn does linkIdentity with
   identity_already_exists fallback to signInWithOAuth +
   zero references to ja_profile_prompted in code
2. sw.js cache = appleseed-v0-30-0
3. GET {SUPABASE_URL}/rest/v1/profiles?select=id&limit=1 with
   apikey + Bearer -> 200
4. GET {SUPABASE_URL}/rest/v1/plants?select=lat,lng&limit=5
   with apikey + Bearer -> 200, all <= 3 decimals
No data mutation. Report table, stop.

## Acceptance (Jason)
- Clear site data → Google sign in: it works, you're back in
  your real account with your real name and plants
- New anon user → Google link: it works, plants kept
- Never see "already linked to another account"
