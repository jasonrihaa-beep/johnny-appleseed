# S4d SPEC — The Bell + Identity Polish (v0.8.0)

Execution contract. Sonnet default. All decisions final.
Opens the notifications the platform has been silently minting,
gives new users an identity moment, and makes accounts durable
with Google sign-in.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. No realtime subscriptions. Badge count fetched on load and
   after user actions; panel refreshes on open. Supabase Realtime
   is the documented upgrade path, not MVP.
2. Notification taps switch to the Feed tab — deep-linking to
   a specific plant/profile is S4e's job (profile pages are the
   real destinations; don't fake it early).
3. Google-only OAuth on web. Apple guideline 4.8 binds the
   App Store build; Sign in with Apple joins the pre-App-Store
   checklist (S5 era), not this commit.
4. NEVER render Sign out for anonymous sessions — signOut on
   an anon user orphans their garden permanently. Sign out
   appears ONLY when user.is_anonymous is false. Add as tripwire
   12; this is sacred-keys-adjacent.
5. Setup sheet fires ONCE, after the FIRST successful plant log —
   never on app open ("no account required to browse" is a
   shipped promise). One-shot flag ja_profile_prompted
   (new sacred localStorage key).
6. The bell lives in the topbar, which hides on the Map tab —
   accepted; badge is visible on Feed/Plant/Profile.

## Dashboard prerequisites (Jason — credentials, your hands)

1. Google Cloud console OAuth client exists with redirect URI
   https://uavtaznzdpmfvkdpqyrv.supabase.co/auth/v1/callback
2. Supabase → Authentication → Providers → Google: enabled,
   Client ID + Secret pasted, saved.
3. Supabase → Authentication → settings: "manual linking" ON
   (required for linkIdentity on anonymous users).
If 1-2 aren't done, the Google button will error with a provider
message — build is still safe to ship; the button starts working
the moment the dashboard side exists.

## Claude Code tasks (one commit, v0.8.0)

### Task 1 — Notifications panel
- Topbar bell (existing stub) gains an unread badge dot with
  count (hidden at 0). On load with session:
  sb.from('notifications').select('id', { count: 'exact',
  head: true }).eq('user_id', me).eq('read', false).
- Tap bell → right slide-in panel (match existing sheet
  styling): fetch latest 50 own notifications ordered desc;
  resolve actor names via the profiles in-list pattern and plant
  names via plants in-list. Rows: "[Name] inspired your [plant]"
  / "[Name] commented on your [plant]" / "[Name] followed you"
  + relative time. Empty state: "Quiet for now. Plant something
  worth talking about."
- On panel open: mark all unread read
  (update({ read: true }).eq('user_id', me).eq('read', false))
  and zero the badge. Row tap → close panel, switchTab('feed').
- Blocked actors filtered out of the panel (reuse block set).

### Task 2 — First-log profile setup sheet
- After the first successful submitPlant insert AND when
  localStorage ja_profile_prompted is unset: bottom sheet —
  title "You're on the map." body "What should neighbors call
  you?" name input (40 max, prefilled Planter), the 5-color
  avatar row, buttons Save / Skip. Either choice sets
  ja_profile_prompted = 1. Save reuses the existing profile
  update path. Never shown again; never shown on open.

### Task 3 — Google sign-in (keep your garden, durable accounts)
- Profile → the "Add email" row becomes "Keep your garden" and
  expands to two options: Continue with Google (inline SVG G
  mark, stroke style, no emoji) and the existing email flow
  beneath as "or use email".
- Anonymous session + Google tap →
  sb.auth.linkIdentity({ provider: 'google', options: {
  redirectTo: 'https://johnny-appleseed.onrender.com' } }) —
  same auth.uid(), plants kept.
- Signed-out / fresh device: Profile tab shows a "Sign in" row
  when no session exists → sb.auth.signInWithOAuth same
  options. (Browsing stays gated on nothing.)
- On redirect return, supabase-js picks up the session
  automatically; re-run the profile + badge loads.
- Protected state: when user.is_anonymous is false, the row
  shows the linked identity ("Garden protected — Google" or the
  email) in disabled state.

### Task 4 — Sign out (guarded)
- Settings row "Sign out", rendered ONLY when a session exists
  AND user.is_anonymous is false (decision 4). Confirm sheet →
  sb.auth.signOut() → reload state to signed-out browse mode.

### Task 5 — Version, docs
- Fan-out: footer v0.8.0 + sw.js CACHE appleseed-v0-8-0.
- CLAUDE_CONTEXT.md: S4d decisions, tripwire 12 (anon sign-out),
  sacred key ja_profile_prompted, landmarks, roadmap.

### Task 6 — Post-deploy self-verify (rule 11, four probes)
1. index.html: v0.8.0 + markers (notification panel fn, badge
   fn, setup-sheet fn, linkIdentity, is_anonymous guard)
2. sw.js cache = appleseed-v0-8-0
3. GET {SUPABASE_URL}/rest/v1/notifications?select=id&limit=1
   with apikey + Bearer → 200 [] (own-only policy, no session)
4. GET .../plants?select=lat,lng&limit=5 → 200, all ≤ 3 decimals
No data mutation. Report table, stop.

## Acceptance (Jason)
- Incognito inspires your okra → badge count appears in normal
  window on refresh → open bell → row reads correctly → badge
  zeroes → survives refresh (read persisted)
- Fresh incognito: log a plant → setup sheet appears exactly
  once → name it → feed card uses the name
- Normal window: Continue with Google → consent → returns →
  "Garden protected — Google" → your plants still yours
- Sign out appears only AFTER the Google link; tap it → browse
  mode; sign back in → same garden
