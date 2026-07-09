# CLAUDE_CONTEXT — Johnny Appleseed

Read this before any edit. It replaces 2-3k tokens of re-discovery grep churn.
Written for the agent, not for humans.

---

## App identity

- **Johnny Appleseed** v0.14.0 — social planting network. "Plant. Share. Grow Together."
- AIRIHA LLC (same privacy-first DNA as MyMeds AI: no tracking, no ads, no accounts required to browse)
- Single-file PWA: `index.html` (~1,470 lines) + `sw.js` + `manifest.json`
- Deploy: GitHub → Render static site, auto-deploy on push to `main` — live at https://johnny-appleseed.onrender.com
- Brand: Fraunces (serif, headlines) + DM Sans (body). Deep forest green + harvest gold + violet (pollinators). **No emojis anywhere — inline stroke SVG icons only** (stroke-width 1.6–1.8, currentColor).

## Stack

- Vanilla HTML/CSS/JS, zero build step
- Leaflet 1.9.4 + OpenStreetMap tiles (CDN: cdnjs) — no API key
- Google Fonts CDN
- Supabase (S2, live): supabase-js v2 via **jsdelivr** CDN (cdnjs doesn't
  carry it) — auth + `plants`/`profiles` tables. Schema: `schema.sql`.
  Spec: `S2_SPEC.md`.
- Planned Session 3: Open-Meteo + USDA PHZM live data feeding PlantScore v2

## S2 design decisions (final — from S2_SPEC.md)

1. **RLS is the entire security layer.** The anon key ships in index.html —
   correct and by design for a static PWA. Never treat it as secret; never
   add any other key.
2. **Coordinate privacy is DB-enforced.** `truncate_coords` trigger caps at
   3 decimals (~110 m) server-side; client rounds to 3 decimals before
   insert to match (courtesy + honest UI preview).
3. **Anonymous-first auth.** `ensureAuth()` runs anonymous sign-in on first
   submitPlant(). Browsing never requires auth. Magic-link upgrade nudge
   (after 3rd plant) is designed but NOT yet implemented.
4. **Orphan tradeoff accepted (MVP):** anon user clears site data → pins
   stay public forever, editable by no one. Documented, not a bug.
5. **Spam cap:** 50 plants/user/24h via DB trigger; client surfaces the
   exception message as a toast.
6. **Nearby feed = bounding box** ±0.75° (~50 mi) on the (lat,lng) index,
   client-side distance sort. No PostGIS at MVP scale.
7. **`user_id` NEVER sent from the client** — DB default `auth.uid()` fills it.
8. **User-generated text is escaped** (`esc()`) before any innerHTML —
   popups, feed cards. Never render DB text raw.
9. **Deferred, documented:** photo upload (S2.5 bucket), display-name
   profanity filter, PostGIS, magic-link nudge.

## S4a design decisions (final — from S4A_SPEC.md)

1. **display_name is a NAME, not a handle** — no uniqueness, no reservation.
   Collisions are fine. 40-char cap enforced by DB.
2. **Avatar = palette color only** (5 brand colors, `AVATAR_PALETTE` —
   keep in sync with `handle_new_user()` in schema.sql). Image upload
   waits for the S2.5 storage bucket.
3. **Email upgrade lives in S4a**: `sb.auth.updateUser({ email })` on an
   anonymous session sends a verification link; verified = same
   auth.uid(), account permanent, plants kept. Confirmed state =
   `user.email` present AND `user.is_anonymous === false` → row shows
   "Garden protected".
4. **The nudge NEVER auto-prompts on load** — one toast after the exact
   3rd successful plant log (`ja_log_count`).
5. **Profanity filtering still deferred** — reports table (S4c) is the
   interim backstop.
6. **S4 social schema applied** (`schema_s4.sql`): follows, inspires,
   comments (+100/day cap), reports (write-only for clients), blocks,
   notifications (trigger-written, owner-read). Tables idle until
   S4b–S4d wire them.

## S4b design decisions (final — from S4B_SPEC.md)

1. **Fake people removed; example plants labeled.** The three hardcoded
   feed cards (Maria R., David K., Tasha W.) are gone — invented humans
   violate honest-states. PIN_SPOTS pins stay as seed content with
   popups prefixed "Example — " so no pin pretends to be a neighbor.
2. **inspires/follows have NO column defaults** (unlike plants.user_id) —
   see tripwire 11.
3. **Counts are client-aggregated.** One in-list inspires query per feed
   load; PostgREST aggregates are the upgrade path, not now.
4. **Follows have a consumption surface from day one** — feed pills
   Nearby (default) | Following. Following with zero follows shows a
   dedicated empty state.
5. **Notifications accumulate silently until S4d** — expected, documented.
6. **Blocks table exists but has no client logic until S4c.**
7. Self-inspire allowed; DB trigger suppresses self-notification.

## S4c design decisions (final — from S4C_SPEC.md)

1. **Comments live inline** — accordion thread under each feed card,
   lazy-loaded on first expand. No detail pages, no modals.
2. **Report is write-only by design.** Thank-you toast, nothing else —
   no status, no outcome visibility. Reports table has no read policy;
   **the Supabase dashboard IS the moderation queue** (Table Editor →
   reports, newest first; judge by target_id; dashboard delete cascades
   cleanup). No admin UI until volume demands it.
3. **Block = hide-from-me.** Filters the blocker's own feed, map pins,
   and comment threads client-side (`isBlocked()` / `blockedIds`).
   Does not make anyone's content private.
4. **Owner moderation is distributed:** plant owners delete any comment
   under their plant (DB policy grants it); commenters delete their own
   anywhere. Delete never shows next to Report/Block — own content gets
   Delete only.
5. **Overflow menu is an SVG three-dot icon** — never a glyph or emoji.
6. **Comment caps are DB-enforced** (100/day, 280 chars); client mirrors
   with maxlength + surfaces the DB exception as a toast.
7. **comments.user_id HAS a DB default** (like plants, unlike
   inspires/follows) — client sends { plant_id, body } only.
8. **Launch gate before public promotion:** ToS + community guidelines
   page, AIRIHA DMCA agent registration (can cover MyMeds AI too).
   Chat-lane work, not a build task.

## S4d design decisions (final — from S4D_SPEC.md)

1. **No realtime subscriptions.** Badge count fetched on load and after
   user actions (rides every loadFeed); panel refreshes on open.
   Supabase Realtime is the documented upgrade path, not MVP.
2. **Notification taps switch to the Feed tab** — deep-linking to a
   specific plant/profile is S4e's job (profile pages are the real
   destinations; don't fake it early).
3. **Google-only OAuth on web.** Sign in with Apple joins the
   pre-App-Store checklist (S5 era). Anonymous session + Google =
   `linkIdentity` (same auth.uid(), plants kept); no session =
   `signInWithOAuth`. Dashboard side: Google provider enabled +
   "manual linking" ON, redirect URI = the Supabase callback.
4. **Sign out ONLY for non-anonymous sessions** — tripwire 12.
5. **Setup sheet fires ONCE — AMENDED by ONBOARD_SPEC (v0.10.0):** on the
   FIRST successful plant log OR an explicit Get-started tap; never
   automatically on app open. Browse path creates no session, shows no
   sheet. One-shot flag `ja_profile_prompted` (sacred); set at show, so
   once '1' neither trigger can fire the sheet again. Get started with
   the flag already '1' just enters the app (device-local, accepted).
   If ensureAuth() fails at splash: toast, enter app, flag NOT set.
   Sheet copy is parameterized: first-log "You're on the map." /
   splash "Welcome to the neighborhood."
6. **The bell lives in the topbar** which hides on the Map tab —
   accepted; badge visible on Feed/Plant/Profile.

## Map-inspire design decisions (final — from MAP_INSPIRE_SPEC.md, v0.9.0)

1. **DB pins ONLY get the engagement popup.** PIN_SPOTS example pins keep
   simple popups — they aren't DB rows; an inspire insert would violate
   the FK and a non-persisting button violates honest-states.
2. **Count is lazy** — fetched on Leaflet `popupopen` for that one
   plant_id, never prefetched for all pins. No realtime; fresh on each
   open, optimistic on own taps.
3. **All user-originated popup text goes through `esc()`** — plant_name,
   sci, note, display_name.
4. **Feed cards and map popups may briefly disagree on count** (each
   loads independently). Accepted at MVP scale.
5. Self-inspire allowed, no self-notification (DB handles it).

## Discovery design decisions (final — from DISCOVERY_SPEC.md, v0.13.0)

1. **plants.kind: 'planted' | 'discovered'**, DB default 'planted'
   (migration in schema.sql appendix, applied dashboard-side). Client
   treats missing kind as 'planted' defensively.
2. **Kind toggle is a THIRD single-select** — see tripwire 13. Own
   `.kind-option` class + `selectKind()`; never shares `.tag-option`.
3. **PlantScore stays silent for finds** — it answers a planting-timing
   question. Found mode: no score preview, `score: null` on insert.
   Replacement = identity line (`#found-info`, PLANT_DB facts only):
   tags, Texas native, invasive warning + native alternative, warn
   note. Unknown plant keeps the honest not-in-database state.
4. **Safety caption** (misidentified wild edibles are the harm vector):
   found mode always shows "Community identification — verify before
   eating anything you find." Rendered surfaces (feed card, pin popup)
   repeat "Community ID — verify before harvesting." only when the
   find carries the edible tag.
5. **Copy branches:** "Log this planting" ↔ "Log this find"; popup
   byline "by" ↔ "Found by"; feed cards for finds carry a Found chip.
6. **Access default stays 'private' for both kinds** — one rule. Daily
   cap (50) shared across kinds — same table.
7. **First-log setup sheet fires on the first successful log of EITHER
   kind** — unchanged.

## Reachable design decisions (final — from REACHABLE_SPEC.md, v0.14.0)

1. **No "keep scrolling" text or arrow.** An affordance that instructs
   work is weaker than removing the work: the primary action is pinned
   instead.
2. **Sticky, never fixed** (tripwire 14). The submit bar uses
   `position: sticky` inside the `#content` scroll container.
   `position: fixed` is displaced by the mobile soft keyboard and will
   jump over the input being typed in. Any future bottom-pinned control
   follows this rule.
3. **Hidden scrollbars stay on touch** (native app feel, original design
   intent). Fine-pointer devices (`@media (hover: hover) and
   (pointer: fine)`) get a slim `--stone-300` scrollbar — desktop users
   read a scrollbar as the signal that content continues.
4. **Non-destructive:** `#submit-plant-btn` keeps its id, class, and
   onclick. `selectKind()` swaps its textContent between "Log this
   planting" and "Log this find" — that wiring works untouched.
5. **Layering:** the bar (z 49) sits above form fields but strictly
   BELOW the autocomplete dropdown (`#plant-suggest`, z 50), and far
   below the action sheet (z 1100/1101). Never raise the dropdown.

## index.html landmarks (lines drift — grep, don't trust numbers)

| What | Anchor | Approx |
|---|---|---|
| Design tokens | `:root {` | ~L14 |
| Topbar + map-mode variant | `#topbar.map-mode` | ~L60 |
| Tab bar + gold active border | `.tab-btn.active` | ~L120 |
| Leaflet container + fallback | `#leaflet-map`, `#map-fallback` | ~L190 |
| Autocomplete CSS | `#plant-suggest` | ~L385 |
| Score preview CSS | `#score-preview` | ~L610 |
| Map view HTML | `id="map-view"` | ~L1030 |
| Feed view + empty state | `id="feed-view"`, `id="feed-empty"` | ~L1100 |
| Plant form + suggest div | `id="plant-name"`, `id="plant-suggest"` | ~L1140 |
| Profile + version footer | `Johnny Appleseed v` | ~L1249 |
| PLANT_DB | `const PLANT_DB` | ~L1290 |
| Scoring engine | `function plantScore(` | after DB |
| Map pins | `const PIN_SPOTS`, `renderMarkers` | after scorer |
| Autocomplete JS | `onPlantInput`, `pickPlant`, `renderScore` | ~L1560 |
| Supabase config | `const SUPABASE_URL` | top of script |
| Access selector | `selectAccess`, `.access-option` | plant form |
| Kind toggle (v0.13.0) | `selectKind`, `.kind-option`, `renderPlantFacts` | plant form, above name |
| Found identity line | `renderFoundInfo`, `id="found-info"`, `id="found-caption"` | under name group |
| Found chip + caution | `.found-chip`, `.found-caution` | feed card template + popup builder |
| Supabase wiring | `ensureAuth`, `submitPlant`, `loadDbPins`, `loadFeed`, `esc(` | after selectTag |
| Live feed container | `id="feed-live"` | feed view |
| Map-inspire popup | `dbPinPopupHtml`, `onPinPopupOpen`, `togglePinInspire`, `dbPinAuthors` | after renderMarkers |
| S4b feed pills | `id="feed-pills"`, `setFeedMode` | feed view, below location bar |
| S4b inspires | `toggleInspireDb`, `setInspireBtn` | after loadFeed |
| S4b follows | `toggleFollowDb`, `setFollowBtns`, `.follow-btn` | after inspires |
| S4c comments | `toggleComments`, `loadComments`, `sendComment`, `.comment-thread` | after follows |
| S4c action sheet | `openSheet`, `openCardSheet`, `openCommentSheet`, `#action-sheet` | after comments |
| S4c report | `openReportSheet`, `submitReport` | after sheet |
| S4c block | `doBlock`, `unblockPlanter`, `isBlocked`, `blockedIds`, `#blocked-list` | after report |
| S4d notifications | `openNotifPanel`, `loadNotifBadge`, `#notif-panel`, `#notif-badge` | after block |
| S4d setup sheet | `maybeShowSetupSheet`, `openSetupSheet(title, body)`, `ja_profile_prompted` | after notifications |
| Onboard flow | `getStartedFlow` (splash Get started) | before maybeShowSetupSheet |
| Sheet Google handler | `setupSheetGoogle` — flag-before-redirect, linkIdentity only | after pickSetupColor |
| OAuth return handler | `handleOauthReturn` — error toast + confirm sheet | after setupSheetGoogle; called from boot |
| Action sheet z-index | 1100/1101 — must beat map pills/FAB (z 1000); sheet opens over Map since v0.10.0 | CSS `#action-sheet` |
| S4d auth | `googleSignIn`, `doSignOut`, `renderEmailRow`, `#sign-in-row`, `#sign-out-row` | with S4a email upgrade |
| S4a identity JS | `loadOwnProfile`, `saveNameEdit`, `cycleAvatar`, `AVATAR_PALETTE` | after setup sheet |
| S4a email upgrade | `startEmailUpgrade`, `renderEmailRow`, `bumpLogCount` | after identity |
| Profile hero (dynamic) | `id="profile-avatar"`, `id="profile-name-display"` | profile view |
| Email upgrade row | `id="email-upgrade-row"` | settings, above AI key |
| Sticky submit bar (v0.14.0) | `id="submit-bar"` (last child of #plant-view, z 49) + desktop scrollbar `@media (hover: hover) and (pointer: fine)` | wraps #submit-plant-btn; CSS after .submit-btn |
| Boot | `DOMContentLoaded` → `initMap()` + `loadFeed()` + `loadOwnProfile()` | end of script |

## PLANT_DB schema — the core asset

~80 Central/South Texas entries. Fields:

- `n` name · `sci` scientific · `tags` array of `edible|wildlife|pollinator`
- `native` (TX) · `inv` (invasive in TX — never plantable) · `alt` (native alternative, invasives only)
- `warn` (safety note: toxicity, monarch OE) · `m` planting months 1–12 (San Antonio–area windows, Bexar Co. Master Gardeners / TX A&M AgriLife) · `note`

**Scoring tiers (deterministic — same input, same answer):**
94 native+in-window · 88 in-window · 62 window edge (±1 month) · 30 wrong season · 8 invasive.

**Never reintroduce randomness or placeholder scores.** The v0.1 fake scorer
(string-length hash) is the documented cautionary tale. Unknown plant = honest
"not in database" state, no score. This is a correctness invariant, same class
as MyMeds' FDA `product_description` query rule.

`REGION` constant = Cibolo TX, zone 8b/9a. Session 3 replaces static months
with live frost/soil-temp data; the tier structure stays.

## Version fan-out — ALL must change together (currently 2)

1. `index.html` footer: `Johnny Appleseed vX.Y.Z · AIRIHA LLC`
2. `sw.js` line 1: `const CACHE = 'appleseed-vX-Y-Z';`

Add new locations to this list the moment they exist (splash tag, What's New,
etc.). MyMeds' fan-out grew from an undocumented 2 to 8 — document as you go.

## localStorage rules

- **`sb-*` keys are SACRED** — supabase-js session storage, created the
  moment supabase-js runs. For anonymous users they ARE the identity:
  clearing them orphans that user's plants permanently. The "Clear my
  data" setting must exclude them or show a permanent-loss confirm for
  anonymous users.
- **`ja_log_count` is SACRED** (S4a) — successful-plant-log counter; the
  one-time email nudge fires on exactly 3. Snapshot → mutate → verify
  read-back lives in `bumpLogCount()`.
- **`ja_profile_prompted` is SACRED** (S4d) — one-shot flag for the
  first-log setup sheet. Set at show time (with read-back verify in
  `maybeShowSetupSheet()`); once '1' the sheet can never fire again.
- **`ja_oauth_return` is sessionStorage, NOT sacred** (v0.12.0) —
  tab-scoped OAuth-return marker, set before linkIdentity, consumed by
  `handleOauthReturn()`. Do not add it to the sacred list; do not move
  it to localStorage.
- Future app keys: prefix `ja_` (e.g. `ja_profile`, `ja_feed_radius`)
- Once created, keys are **sacred — never rename without migration**
- Snapshot before mutate, verify read-back (MyMeds `ProfileSystem` pattern)
- Never ship an update that could lose user data

## Known tripwires

1. **Stale service worker.** Bump `CACHE` in sw.js on EVERY ship or Chrome
   serves the old build and you'll debug ghosts. Testing: DevTools →
   Application → Clear site data → hard refresh. Serve via http-server, not
   `file://` (SW won't register from file://).
2. **Leaflet gray tiles.** `map.invalidateSize()` is required after any
   `display:none → block` (tab switch) and after splash removal. Both calls
   exist in `switchTab` and `enterApp` — don't remove them.
3. **Map height.** `#leaflet-map` needs explicit height; `body.tab-map`
   swaps the calc when the topbar hides on the map tab. Touch one, check both.
4. **Autocomplete quoting.** Plant names contain apostrophes (Turk's Cap,
   Gregg's Mistflower). The `pickPlant` onclick generator escapes them —
   don't "simplify" the escaping.
5. **`#score-preview` must never ship with `.visible` hardcoded in HTML** —
   JS adds it on valid input. (Shipped broken once.)
6. **`#feed-empty` lives INSIDE `#feed-view`.** A stray `</div>` once
   orphaned it. HTML tag-balance check catches this class of bug — run it.
7. **Filter pills + FAB use z-index 1000** to beat Leaflet's panes.
8. **Tag selector is single-select**; "All of the above" = all three tags.
9. **Container ephemera (chat sessions only):** /home/claude resets between
   sessions. Canonical copy = the repo, never a scratch directory.
10. **Two independent single-selects share `.tag-option`.** `selectTag`
    scopes with `:not(.access-option)`; `selectAccess` scopes to
    `.access-option`. Remove either scope and picking a Type silently
    deselects the access level (or vice versa).
11. **inspires/follows have NO column defaults.** Unlike plants.user_id
    (DB default auth.uid()), the client MUST send ids explicitly on
    insert; RLS `with check` enforces they match the session. Copying
    the plants insert pattern (omitting user_id) fails with a
    not-null violation.
12. **NEVER render Sign out for anonymous sessions.** signOut on an
    anon user orphans their garden permanently (sb-* keys are the only
    identity). Sign out appears ONLY when `user.is_anonymous === false`;
    `doSignOut()` re-checks the session before calling signOut. This is
    sacred-keys-adjacent — treat any change here as data-loss surface.
13. **The kind toggle must NEVER share `.tag-option`** (tripwire 10
    corollary). Three independent single-selects live on the Plant form:
    Type (`.tag-option:not(.access-option)`), access (`.access-option`),
    kind (`.kind-option`). Kind styling mirrors tag-option via
    DUPLICATED CSS rules; class sharing is forbidden — sharing would let
    any selector clear another group's selection.
14. **Sticky, never fixed, for bottom-pinned controls.** `#submit-bar`
    uses `position: sticky` inside the `#content` scroll container.
    `position: fixed` is displaced by the mobile soft keyboard and will
    jump over the input being typed in. Any future bottom-pinned control
    follows this rule.

## Validate-after-edit checklist — skip none

- [ ] grep confirms the edit landed; no stray duplicates of old pattern
- [ ] CSS brace count matches per style block
- [ ] HTML tag stack balanced (Python HTMLParser or regex-stack check)
- [ ] Inline JS passes `node --check` (extract non-src script blocks)
- [ ] If shipping: version fan-out done (both locations)
- [ ] New listener/animation? Re-read tripwires above first

## Model strategy (Claude Code)

- **Fable 5** (`/model claude-fable-5`): architecture, Supabase schema + RLS
  security review, PlantScore algorithm changes, anything touching data
  integrity or the DB's factual content
- **Sonnet 4.6**: mechanical edits, CSS polish, copy tweaks — preserves the
  Fable budget for work that needs it

## Roadmap state

- ✅ S1 shell · ✅ real Leaflet map · ✅ PLANT_DB + honest scorer + autocomplete
- ✅ S2 core: Supabase wired — anonymous auth, plants insert + map pins +
  live feed, access selector, Open harvest filter, RLS + coord truncation
  DB-side. Remaining from S2 design: magic-link upgrade nudge, photo
  upload (S2.5), profanity filter.
- ✅ S4a identity: profile name edit, avatar color cycle, keep-your-garden
  email upgrade + 3rd-log nudge. S4 social schema applied.
- ✅ S4b engagement: real inspires (client-aggregated counts), follows +
  Nearby/Following feed pills, fake feed cards removed, example pins
  labeled. Notifications accumulate silently until S4d.
- ✅ S4c moderation: inline comment threads, overflow action sheet,
  write-only reports (dashboard = mod queue), hide-from-me blocks with
  Settings list. Launch gate before promotion: ToS/guidelines + DMCA
  agent registration.
- ✅ S4d bell + identity polish: notifications panel with unread badge
  (poll-on-load, no realtime), first-log setup sheet, Google sign-in
  (linkIdentity for anon → durable), guarded sign-out. Deep links +
  profile pages = S4e.
- ✅ Map-inspire (v0.9.0): richer DB-pin popups (sci, byline, note,
  Open-harvest chip, score) + inspire from the map with lazy
  popupopen count fetch. Example pins unchanged.
- ✅ Onboard (v0.10.0): Get started → explicit setup sheet over the map
  ("Welcome to the neighborhood."), Browse stays accountless, entry
  never blocked.
- ✅ Onboard Google (v0.11.0): Continue with Google in the setup sheet,
  both contexts. `setupSheetGoogle()` sets `ja_profile_prompted` BEFORE
  the redirect (leaving the page can't lose the flag; error-before-
  redirect keeps the sheet open this once, future sessions skip — an
  accepted tradeoff). linkIdentity ONLY — both triggers arrive with an
  anonymous session; ~~no name prefill from Google metadata~~ AMENDED by
  OAUTH_RETURN (v0.12.0): the return flow prefills the FIRST name from
  Google metadata (given_name → first token of full_name/name → empty)
  as an editable suggestion the user must Save. Never the full name,
  never auto-assigned — surnames are doxxing surface on a public
  location-tagged map. Save/Skip and the Profile email path unchanged.
- ✅ OAuth return (v0.12.0): `handleOauthReturn()` on boot — toasts URL
  error params verbatim then cleans the URL (marker kept for retry);
  on marked successful return: "Garden protected — Google" toast +
  name-confirm sheet (only when display_name is still 'Planter'),
  gated by the sessionStorage marker, never by ja_profile_prompted.
  Marker `ja_oauth_return` is sessionStorage — tab-scoped, ephemeral,
  explicitly NOT sacred. Confirm-context sheet hides the Google button
  (already linked — a live one would be a dead button, rule 9).
- ✅ Discovery (v0.13.0): "I planted this" / "I found this" kind toggle
  (third single-select, tripwire 13), finds ship unscored with a
  PLANT_DB identity line + safety captions, Found chip on feed cards,
  "Found by" popup bylines. plants.kind migration lives as a schema.sql
  appendix ("-- v0.13.0 MIGRATION"), applied dashboard-side.
- ✅ Reachable (v0.14.0): sticky submit bar pins the primary action at
  the bottom of the Plant form (sticky never fixed — tripwire 14), fade
  scrim above it, slim brand scrollbar for fine-pointer devices (touch
  keeps hidden scrollbars).
- ⏳ S3: Open-Meteo + USDA PHZM → PlantScore v2 (live frost/soil temp)
- ⏳ BYOK Claude layer · ⏳ PWABuilder → Play Store
