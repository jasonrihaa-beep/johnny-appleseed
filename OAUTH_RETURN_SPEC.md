# OAUTH RETURN SPEC — Acknowledge the Landing (v0.12.0)

Execution contract. Sonnet default. All decisions final.
Fixes the silent OAuth return: success gets a confirmation
moment and a name-confirm sheet; errors get surfaced instead
of swallowed.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. AMENDS ONBOARD_GOOGLE decision 3: the return flow prefills
   the display-name input with the user's Google FIRST name
   as an editable suggestion the user must Save. Never the
   full name, never auto-assigned — user-confirmed publish
   only. Rationale: public location-tagged map; first names
   are neighbor names, surnames are doxxing surface.
2. Return detection uses sessionStorage key ja_oauth_return —
   set immediately before linkIdentity in BOTH Google entry
   points. sessionStorage is tab-scoped and ephemeral; this is
   explicitly NOT a sacred ja_ localStorage key and must not
   be added to the sacred list.
3. The return-side name-confirm sheet is gated by the
   sessionStorage marker + a default display_name, NOT by
   ja_profile_prompted (which was correctly set before the
   redirect). It neither reads nor writes that flag.
4. Error surfacing: OAuth error parameters arriving in the
   return URL are toasted verbatim, then stripped from the
   URL. Errors never leave the user guessing again.

## Claude Code tasks (one commit, v0.12.0)

### Task 1 — Mark the departure
In setupSheetGoogle() AND the Profile Keep-your-garden Google
handler: sessionStorage.setItem('ja_oauth_return','1')
immediately before the linkIdentity call.

### Task 2 — Handle the landing
On app load, after supabase-js session pickup (in or after the
existing boot sequence):
a) Parse location.hash and location.search for error /
   error_description params. If present: toast the
   error_description (or error) verbatim, then
   history.replaceState to clean the URL. Do not clear the
   sessionStorage marker on this path — a retry may follow.
b) Else if sessionStorage ja_oauth_return === '1': remove the
   marker. After the profile load resolves and the session
   user has is_anonymous === false: toast "Garden protected —
   Google". Then fetch own profile: if display_name is still
   'Planter', open the setup sheet in a new confirm context —
   title "Garden protected." body "What should neighbors call
   you?" — with the name input prefilled from
   user_metadata.given_name, falling back to the first
   whitespace-token of user_metadata.full_name or
   user_metadata.name, falling back to empty. Save uses the
   existing profile update path; Skip closes and leaves
   'Planter'. Neither touches ja_profile_prompted.
c) If the marker is set but the session is still anonymous
   (link failed upstream), toast "Google sign-in didn't
   complete. Try again from your Profile." and remove the
   marker.

### Task 3 — Version, docs
Fan-out: footer v0.12.0 + sw.js CACHE appleseed-v0-12-0.
CLAUDE_CONTEXT.md: decision-3 amendment, ja_oauth_return
sessionStorage note (non-sacred, tab-scoped), return-handler
landmark, roadmap.

### Task 4 — Post-deploy self-verify (rule 11, four probes)
1. index.html: v0.12.0 + markers (ja_oauth_return in both
   entry points, return handler fn, error_description parse,
   given_name prefill)
2. sw.js cache = appleseed-v0-12-0
3. GET {SUPABASE_URL}/rest/v1/profiles?select=display_name&limit=1
   with apikey + Bearer → 200 JSON
4. GET {SUPABASE_URL}/rest/v1/plants?select=lat,lng&limit=5
   with apikey + Bearer → 200, all ≤ 3 decimals
No data mutation. Report table, stop.

## Acceptance (Jason)
- Fresh incognito: Get started → Continue with Google →
  consent → return shows "Garden protected — Google" toast AND
  the confirm sheet with your first name prefilled → Save →
  feed card and Profile show the name
- Named-account variant: an account that already has a
  display_name links Google from the Profile path → toast
  only, no sheet
- If your earlier silent test was actually a failure, the
  retest now toasts the real error text — relay it verbatim
