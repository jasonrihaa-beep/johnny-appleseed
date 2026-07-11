# DOMAINFIX SPEC — Real Domain + Restore a Sacred Key (v0.31.0)

Execution contract. Sonnet default. All decisions final.
Three defects found by independent audit of v0.30.0: OAuth
redirects to the old onrender URL though the custom domain is
live; a SACRED localStorage key was deleted without
authorization; and the false comment that caused the original
Google bug is still in place.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. The production domain is now https://johnnyappleseed.farm
   (verified, certificate issued). All OAuth redirectTo values
   point there. The onrender.com URL remains a working mirror
   but is no longer the canonical app URL.
2. SACRED KEY VIOLATION, must be reverted: v0.30.0 added
   `localStorage.removeItem('ja_profile_prompted')`. That key
   is on the sacred list; removing it re-opens the one-shot
   setup sheet for users who already dismissed it. DELETE the
   removal code. The key stays, its semantics unchanged. No
   spec authorized this and none will — sacred keys are never
   removed without an explicit migration decision in a spec.
3. Reaffirm BUILD_RULES: a build implements ONLY what its spec
   states. Unrequested changes to sacred keys, schema, or
   protected state are defects even when well-intentioned.
4. The comment above googleSignIn ("so linkIdentity is
   correct; never signInWithOAuth here") is FALSE and caused
   the returning-user bug. Delete it; replace with an accurate
   note describing the link-then-signin fallback.

## Claude Code tasks (one commit, v0.31.0)

### Task 1 — Domain migration in code
Replace every hardcoded 'https://johnny-appleseed.onrender.com'
with 'https://johnnyappleseed.farm'. Grep the whole file
(index.html, sw.js, manifest.json) and report every occurrence
changed — including OAuth redirectTo options, any canonical
URL, manifest start_url/scope if they reference the old host.
Do NOT change the Supabase project URL (uavtaznz...supabase.co)
— that is the auth server, not the app.

### Task 2 — Restore the sacred key
Delete lines that remove ja_profile_prompted from localStorage
(the v0.30.0 cleanup at ~4147-4148). The key must persist as
the one-shot setup-sheet gate exactly as before v0.30.0.

### Task 3 — Fix the false comment
Delete the "never signInWithOAuth here" comment above
googleSignIn; replace with an accurate description: link for
new anonymous users, fall back to sign-in when the identity
already exists (returning user).

### Task 4 — Version, docs
Fan-out: footer v0.31.0 + sw.js CACHE appleseed-v0-31-0.
CLAUDE_CONTEXT.md: canonical domain is johnnyappleseed.farm;
the sacred-key violation and its revert; reaffirm "spec-only
changes" as a build rule; roadmap (haze-dot fix still pending).

### Task 5 — Post-deploy self-verify (rule 11, four probes)
1. index.html: v0.31.0 + zero occurrences of
   'johnny-appleseed.onrender.com' as a redirectTo + zero
   occurrences of removeItem('ja_profile_prompted') + the
   false comment gone
2. sw.js cache = appleseed-v0-31-0
3. GET {SUPABASE_URL}/rest/v1/profiles?select=display_name&limit=1
   with apikey + Bearer -> 200
4. GET {SUPABASE_URL}/rest/v1/plants?select=lat,lng&limit=5
   with apikey + Bearer -> 200, all <= 3 decimals
If the network is unavailable, say so explicitly and do not
mark the probe passed.
No data mutation. Report table, stop.

## Acceptance (Jason)
- Sign in with Google FROM johnnyappleseed.farm: returns to
  johnnyappleseed.farm signed in, real name, real plants
- The setup sheet does NOT re-prompt users who already
  dismissed it
- The app works at both URLs; the .farm domain is canonical
