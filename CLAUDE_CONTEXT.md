# CLAUDE_CONTEXT — Johnny Appleseed

Read this before any edit. It replaces 2-3k tokens of re-discovery grep churn.
Written for the agent, not for humans.

---

## App identity

- **Johnny Appleseed** v0.38.0 — social planting network. "Plant. Share. Grow Together."
- AIRIHA LLC (same privacy-first DNA as MyMeds AI: no tracking, no ads, no accounts required to browse)
- Single-file PWA: `index.html` (~1,470 lines) + `sw.js` + `manifest.json`
- Deploy: GitHub → Render static site, auto-deploy on push to `main` — canonical URL https://johnnyappleseed.farm (custom domain, certificate issued); onrender.com mirror works but .farm is the production domain
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

## Photo design decisions (final — from PHOTO_SPEC.md, v0.15.0)

1. **Client-side compression is mandatory:** canvas downscale to max
   1280px longest edge, JPEG quality 0.82, before upload
   (`compressPhoto()`). Free-tier storage math depends on it.
2. **Upload path:** `plant-photos/{auth.uid()}/{crypto.randomUUID()}.jpg`
   — filename independent of plant id, upload BEFORE insert, photo_url
   in the single insert. Insert fails after upload → best-effort
   storage remove in the error branch.
3. **Photos never block a log:** any upload failure → toast +
   confirm-continue sheet offering log-without-photo. Same philosophy
   as the GPS fallback. `closeSheet()` resolves a pending photo-confirm
   as Cancel (no hung promise on backdrop dismiss).
4. **Fallback is a SINGLE universal botanical line-art SVG placeholder**
   (`#photo-placeholder-sprig` symbol) — visibly an illustration
   (stroke 1.6, stone-500 on green-50), generic sprig, aria-label
   "Illustration — no photo yet". Must NOT appear to depict the
   specific species (honest-states). Per-plant sketch library is a
   separate asset-lane project; render order once it exists:
   user photo → per-plant sketch → placeholder.
5. **photo_url rendered escaped; images lazy** (`loading="lazy"`),
   object-fit cover, fixed aspect container (no layout shift). Feed:
   4:3; popup: fixed 110px strip, no placeholder in popups (omit).
6. **Own-plant delete does best-effort storage remove** of its photo
   (orphaned files otherwise accepted, documented). Delete path
   (`confirmDeletePlant`/`doDeletePlant`) was CREATED in v0.15.0 — it
   had been referenced by the card sheet since S4c but never defined
   (dead button, found during this build).
7. **Sign-in caption** under the setup sheet's Google button, exact
   text "Your garden stays yours on any device. Without it, your
   plants live only in this browser." Both clauses literally true.
8. **photo_url key is omitted from the insert when no photo** —
   logging keeps working even if the photo_url column migration is
   not yet applied dashboard-side.

## Location design decisions (final — from LOCATION_SPEC.md, v0.16.0)

1. **Location is never guessed silently** (tripwire 15). The map-center
   fallback never auto-fires; every published coordinate was either a
   classified GPS fix the user saw, a manual map placement, or an
   explicit user tap on "Use map center". No fourth path may ever be
   added. The old silent-fallback `getLogLocation()` was REMOVED in
   v0.16.0 (the spec's "replace the invisible-location behavior").
2. **The preview shows ROUNDED coordinates** (3 decimals, same as the
   DB trigger) — what the user sees is exactly what publishes, privacy
   floor included. Copy notes "neighborhood precision (~100 m)".
3. **Geolocation:** `{ enableHighAccuracy: true, timeout: 10000,
   maximumAge: 0 }`, classified by coords.accuracy: ≤100 m good;
   100–1000 m warn; >1000 m poor (Android approximate-permission
   territory). Poor fixes are shown, never auto-accepted as final —
   the row nudges manual placement: "Turn on precise location for
   Chrome, or place the pin on the map."
4. **Manual placement is a first-class path, not a fallback** — it is
   how discovery-mode users log a plant found earlier elsewhere.
   Found-mode helper: "Log where you found it — place on the map if
   you're logging later." (toggled by selectKind).
5. **Pick mode hides the plant FAB and filter pills** while active
   (`#map-view.picking`); crosshair + confirm controls reuse existing
   tokens, stroke SVG only, z 1050 — below the action sheet (1100).
6. **First Plant-tab visit auto-requests a fix** — allowed because the
   result lands visibly in the row (a seen, classified fix, not a
   silent guess). GPS failure with a prior fix keeps the prior fix.
7. **No location = the one permitted submit block** — a pin without a
   location is meaningless; silence was the old bug.

## Haze design decisions (final — from HAZE_SPEC.md, v0.17.0)

1. **The circle IS the data** (tripwire 16). Radius 75 m = the computed
   rounding-cell extent at ~29.5°N (±55 m lat, ±48 m lng, corner
   ≈ 74 m), centered on the stored coordinate. NEVER jittered, never
   randomized, never resized for aesthetics: jitter is fabricated data,
   and the stored coordinate is already public via the API, so the
   honest circle leaks nothing new.
2. **Two encodings, no conflict:** TYPE keeps color (gold edible /
   green wildlife / violet pollinator / green multi), ACCESS sets
   prominence. public = full-color circle at 0.25 fill + gold stroke
   (the old Open-harvest ring folded in); ask = 0.15 fill, type-color
   stroke; private = stone-500 grey at 0.08 fill, smaller center dot —
   visible, deliberately unenticing, still tappable.
3. **Treasure copy ONLY on access='public' popups:** "Somewhere in this
   circle — happy hunting." Private popups instead: "Private yard — on
   the map, not on the menu." Inviting strangers to search near a
   private yard is the exact harm the floor prevents. Ask-tier gets
   neither line.
4. **Owners see the same circle as strangers** — exact locations were
   never stored anywhere, by design. Public popups state it as a
   feature: "Locations are neighborhood-level for everyone's safety."
5. **Access is a REQUIRED choice:** no preselected option, "Open spot"
   first, submit blocked with a toast until chosen. Location + access
   are the ONLY two legitimate submit blocks. DB default 'private'
   stays as schema backstop; the client always sends an explicit value.
6. **Example pins (PIN_SPOTS) use the same circle path** at the
   ask-tier neutral treatment, keeping the "Example —" popup prefix.
   One rendering path, no special cases. `pinIcon()` + `.aps-pin` CSS
   were removed with the point-pin renderer in v0.17.0.

## Dark theme design decisions (final — from DARKTHEME_SPEC.md, v0.18.0)

1. **Typefaces UNCHANGED.** Fraunces + DM Sans stay — they are Johnny
   Appleseed's identity and what distinguishes it from MyMeds. Do NOT
   introduce Instrument Serif or IBM Plex.
2. **Method: remap the SEMANTIC surface tokens only.** The raw
   green/gold/violet/red scales keep their hex values. Change what
   --stone-100, --stone-200, --stone-300, --stone-500, --stone-700,
   and --ink resolve to. Because components reference the semantic
   tokens, most surfaces re-theme with near-zero per-component edits.
3. **NEW dark surface values:** --stone-100 → #14211A (near-black
   forest), --stone-200 → #1C2B22 (raised surface), --stone-300 →
   rgba(122,153,136,0.22) (sage border), --stone-500 → #8FA398 (dimmed
   sage text), --stone-700 → #C3D2C8 (light sage secondary),
   --ink → #F5F1E8 (warm off-white). Added --glass:
   rgba(28,43,34,0.72), --glass-border: rgba(245,241,232,0.14),
   --glow-amber: rgba(244,161,39,0.22).
4. **Tripwire 17 — map frozen, narrow exception consumed by v0.35.0.**
   #leaflet-map, L.circle rendering (radius 75m, access opacity tiers
   0.25/0.15/0.08 UNCHANGED), addHazeCircle, colors, popup CONTENT,
   pick mode are frozen. v0.35.0 (HAZEDOT) consumed a narrow
   exception: dot visibility logic and circle popup bindings were
   edited; all other map elements untouched. After v0.35.0 the map
   re-freezes with NO further exceptions. backdrop-filter is NEVER
   applied over the map (Leaflet pan/zoom + blur destroys framerate
   on mid-range Android).
5. **Contrast floor:** body text on any surface >= 4.5:1, large/
   secondary text >= 3:1. Amber accent (#F4A127) is for glow, emphasis,
   and the wordmark accent — never for body text on dark (fails
   contrast). Existing green/gold/violet status pills keep their
   meaning; backgrounds via the existing -50/-100 scale tokens only.
6. **theme-color meta + manifest background_color** updated to #14211A
   so the PWA shell and status bar match.
7. **Frosted glass cards:** feed post cards, score preview, and action
   sheets get var(--glass) + backdrop-filter: blur(12px) + glass
   border. Explicitly EXCLUDED: anything inside #map-view and all
   Leaflet popups.
8. **Firefly glow:** #splash gets dual radial-gradient pseudo-elements
   (ambient var(--glow-amber) centered slightly above middle, smaller
   offset glow for depth), splash-mark and splash-title em get soft
   amber glow that pulses subtly via @keyframes firefly-pulse (5s
   ease-in-out), respecting prefers-reduced-motion: no pulse, static
   glow only. AMENDED by v0.19.0: the splash-mark uses
   firefly-pulse-box (box-shadow on a square element is correct); the
   italic .splash-title em uses firefly-pulse-text (text-shadow follows
   letterforms, no square). box-shadow on italic = wrong glow shape.
9. **Splash z-index 2000** (v0.19.0) — must fully occlude map controls
   (#map-filter and #plant-fab at z 1000). The pre-v0.19.0 z 500 let
   pills and FAB bleed through on load.

## Overlay fix decisions (final — from OVERLAYFIX_SPEC.md, v0.20.0)

1. **Google button root cause:** background:white with color:var(--ink),
   but --ink is now #F5F1E8 (dark theme), giving white-on-white.
   Google's own button spec is white background + #1F1F1F text +
   full-color G. Hardcoded these (do NOT use --ink here) so the button
   stays correct in any theme. This is a branded third-party button,
   exempt from the app palette by design.
2. **Sheet backdrop root cause:** #action-sheet uses translucent
   var(--glass) + blur. Over the MAP, the pills/FAB (z 1000) show
   through the glass. Fixed by making the backdrop near-opaque
   (rgba(13,26,15,0.92)); the sheet keeps its glass look but now sits
   over an opaque scrim, not the live map. Glass stays; bleed-through
   stops.
3. **Z-INDEX BANDS** (applied in v0.20.0): base content 1-100; map
   chrome (pills/FAB/pick) 1000-1050; overlays + their backdrops
   (action sheet, setup sheet, notif panel) 1100-1199; splash 2000;
   toast 3000 (toast must never be occluded). Violations fixed: toast
   200 → 3000, notif-panel 400/401 → 1150/1151.

## Affiliate plumbing decisions (final — from S-AFF_SPEC.md, v0.38.0)

Ships fully DORMANT — `AFFILIATE_CONFIG.enabled: false`; zero affiliate UI renders on the
live site after this build.

1. **Program-agnostic layer:** one config object (`AFFILIATE_CONFIG`) + one resolver
   (`affiliateUrl`). Activating a real program later = editing config values only, zero
   changes to surface code.
2. **Doctrine:** tier the individual, never the network — no ads, no pay-to-rank, safety info
   never gated. Affiliate is additive convenience only. No click tracking or affiliate
   telemetry of any kind — the anchor tag is the whole feature.
3. **INVASIVE EXCLUSION (correctness invariant, honest-states class):** any `PLANT_DB` entry
   with `inv:true` NEVER resolves an affiliate link, regardless of config or per-plant
   overrides — enforced inside `affiliateUrl()`. Upgrade path (documented, not built): route
   invasives to their alt native instead.
4. **Honest states:** if `affiliateUrl()` returns `null` — disabled, unconfigured, invasive, or
   no resolvable query — NO button, NO disclosure, NO placeholder renders. Null means absent.
5. **FTC disclosure is mandatory UI:** a disclosure line (`t('affiliate_disclosure')`) renders
   directly beneath EVERY affiliate action, always, in the active language.
6. **Every affiliate anchor:** `target="_blank" rel="sponsored noopener noreferrer"`.
7. **Surfaces in v1:** score preview (`#score-affiliate`, in `renderScore`) + DB-pin map popups
   (`dbPinPopupHtml`) only. Feed cards explicitly excluded. `PIN_SPOTS` example pins excluded
   (example content stays commerce-free — `renderMarkers`'s PIN_SPOTS branch never calls
   `dbPinPopupHtml`).
8. **Amazon-class program restrictions on PWAs** are handled by the dormant-by-default config:
   compliance review happens at activation, per program, as a config decision.
9. **No schema changes, no new localStorage keys.** `PLANT_DB` entries gain no new data in this
   build — `buy` (optional absolute-URL override, returned verbatim by `affiliateUrl`) is a
   documented slot only, unused by any current entry.
10. **`affiliate_about` string is reserved,** intentionally unused — no About-section surface
    exists yet to render it.

Roadmap: ✅ Affiliate plumbing (v0.38.0): dormant config + resolver, score-preview CTA, DB-pin
popup CTA, EN/ES strings. Activation is a future config-only change, not a build.

## Contrast token fixes (final — from CONTRAST3_SPEC.md, v0.28.0)

1. **Toast fixed:** #toast color -> var(--ink) (was --stone-100,
   near-black). Every toast readable (map location, all app toasts).
2. **Active filter pill:** .filter-pill.active color -> var(--ink) (was
   --stone-100 on green).
3. **green-700 text sweep:** 13 instances swapped to var(--green-400)
   where rendering TEXT on dark: .icon-btn, .tab-btn.active + .tab-label,
   #map-fallback p, .comment-btn:hover, .avatar, .inspire-btn:hover,
   .found-info-tags, .score-number, .loc-btn, #pick-crosshair,
   .profile-avatar-lg, #location-text strong. Borders using green-700
   unchanged (fine as-is).
4. **Toast label:** "Notifications coming soon" -> "Reminders coming
   soon" (Planting reminders row).
5. **Hero assets replaced:** assets/hero-image.jpg (550KB, was 570KB) +
   assets/hero-video.mp4 (2.3MB, was 2.9MB) — 8% right trim, Gemini
   watermark removed, crossfade alignment preserved.
6. **Coming-soon stub inventory:** Search (topbar), AI key (settings),
   Feed radius (settings), Planting reminders (settings).

## Haze dot decisions (final — from HAZEDOT_SPEC.md, v0.35.0)

1. **DOT_HIDE_ZOOM = 16** (named constant). At map zoom >= 16 the
   center dots are removed from the map; below 16 they render as
   before. Rationale: at zoom 16 the 75m circle is ~55px across — a
   comfortable tap target; the dot has no locator job left and only
   overclaims precision. Hard disappear, no fade.
2. **Popups bind to the CIRCLE** as well as the dot (same content,
   same options). Far zoom: dot is the practical tap target. Close
   zoom: the circle is. Tap behavior works in both regimes.
3. **Implementation:** all dot markers collected in a single
   L.layerGroup (dotMarkers); one 'zoomend' listener adds/removes
   the whole group vs DOT_HIDE_ZOOM. Set initial state from map's
   starting zoom. No per-marker listeners, no opacity animation.
   renderMarkers clears dotMarkers.clearLayers() on rebuild (pins
   reload on tab switch).
4. **Example pins (PIN_SPOTS) follow identical rules** — one
   rendering path, no special cases.
5. **Tripwire 17 exception consumed:** this build edited dot
   visibility logic and circle popup bindings. It did NOT change:
   circle radius (75m), access opacity tiers (0.25/0.15/0.08),
   colors, popup CONTENT, pick mode. After v0.35.0 the map
   re-freezes with NO further exceptions.

## Return fix decisions (final — from RETURNFIX_SPEC.md, v0.34.0)

1. **REDIRECT-BASED ERRORS:** linkIdentity is redirect-based. On
   rejection Supabase never returns an error to the calling code —
   it navigates back to the app with ?error=server_error&error_code=
   identity_already_exists&error_description=Identity+is+already+
   linked+to+another+user. The in-code fallback after linkIdentity()
   is unreachable for this error class. The fallback must live in the
   RETURN path.
2. **AUTO-RECOVER on identity errors:** handleOauthReturn parses BOTH
   query string and hash fragment for error/error_code/error_
   description. If error_code === 'identity_already_exists' OR
   error_description contains 'already linked': console.log, await
   sb.auth.signOut({scope:'local'}), set sessionStorage
   ja_oauth_autoretry='1', then signInWithOAuth. User experiences
   one extra bounce, not an error.
3. **LOOP GUARD:** if ja_oauth_autoretry is ALREADY '1' when an
   identity error arrives again, do NOT retry — clear guard, show
   persistent error dialog with verbatim error_description. Clear
   guard on any successful durable session.
4. **VERBATIM ERROR DIALOG:** ALL other OAuth error params on return
   -> persistent showAuthError rendering error_description VERBATIM.
5. **v0.33 in-code fallback stays** (covers genuinely thrown
   non-redirect errors). TRIPWIRE 18 extended: redirect-based auth
   errors are handled at the RETURN, never assumed to reach the call
   site.

## Auth clean decisions (final — from AUTHCLEAN_SPEC.md, v0.33.0)

1. **RAW ERRORS, ALWAYS:** showAuthError displays the human-readable
   line PLUS the raw error (e.message, e.status/e.code when present)
   in the dialog body. v0.32.0 passed errors but showed only "Could
   not sign in" — the raw provider message was missing, diagnosis took
   longer. An auth failure that hides its reason is a diagnosis tax —
   this dialog exists for exactly one user journey: reporting what
   went wrong.
2. **ZOMBIE PURGE:** in googleSignIn(), when linkIdentity errors on an
   anonymous session, call `await sb.auth.signOut({ scope: 'local' })`
   BEFORE the signInWithOAuth fallback — abandoning the anon session
   is already accepted policy (GOOGLEFIX decision 3), and a corrupt/
   deleted-user session must never poison the clean sign-in.
   scope:'local' only clears this browser's stored session; it cannot
   sign out other devices. Wrapped in try/catch, ignores its own
   errors.
3. **DYNAMIC ORIGIN (supersedes the unpasted ORIGINFIX):** redirectTo
   becomes window.location.origin everywhere — user returns to the
   origin they started from; .farm stays canonical; the onrender
   mirror and installed PWAs work. Zero hardcoded app origins in auth
   opts.
4. **TRIPWIRE 18 extended:** auth flows are origin-agnostic and
   zombie-tolerant; auth errors always surface raw provider text.

## Google fix 2 decisions (final — from GOOGLEFIX2_SPEC.md, v0.32.0)

1. **NEVER pattern-match fragile provider error strings.** New policy:
   if linkIdentity() fails for ANY reason on an anonymous session,
   fall back to signInWithOAuth() unconditionally. v0.30.0 checked for
   literal 'identity_already_exists' but Supabase returns
   "Identity is already linked to another user" — the match failed,
   fallback never fired, returning users stranded. Log the raw link
   error to console for diagnostics before falling back.
2. **Auth errors must be READABLE:** failed auth attempts show a
   persistent, dismissible sheet (not a 2-second toast). New
   showAuthError() function reuses existing sheet styling, includes
   raw provider message so user can report it. Same treatment in
   handleOauthReturn() for return-path errors.
3. **NEVER strand the user:** Profile always renders "Sign in with
   Google" row whenever there is no durable session (no session at
   all, OR session.user.is_anonymous === true) — including after a
   failed attempt. Explicit check in renderEmailRow().
4. **Success must be UNAMBIGUOUS:** on durable session, Profile shows
   "Signed in with Google" + account email (if available) instead of
   generic "Garden protected". Clear persistent confirmation, not just
   the return toast.
5. **TRIPWIRE 18 (v0.30) strengthened:** every Google entry point
   handles BOTH link and sign-in; fallback must not depend on
   error-string matching (brittle, provider can change wording).

## Domain fix decisions (final — from DOMAINFIX_SPEC.md, v0.31.0)

1. **Canonical domain:** https://johnnyappleseed.farm (custom domain,
   certificate issued). All OAuth redirectTo values point there. The
   onrender.com URL remains a working mirror but is no longer the
   canonical app URL.
2. **SACRED KEY VIOLATION reverted:** v0.30.0 added
   `localStorage.removeItem('ja_profile_prompted')` — DEFECT. That
   key is on the sacred list (BUILD_RULES rule 10); removing it
   re-opens the one-shot setup sheet for users who already dismissed
   it. The removal code was DELETED in v0.31.0. The key persists with
   its original semantics. No spec authorized the removal and none
   will — sacred keys are never removed without an explicit migration
   decision in a spec.
3. **Reaffirm BUILD_RULES:** a build implements ONLY what its spec
   states. Unrequested changes to sacred keys, schema, or protected
   state are defects even when well-intentioned.
4. **False comment removed:** the comment above googleSignIn ("so
   linkIdentity is correct; never signInWithOAuth here") was FALSE
   and caused the returning-user bug. Replaced with accurate
   description of the link-then-signin fallback.

## Google fix decisions (final — from GOOGLEFIX_SPEC.md, v0.30.0)

1. **AMENDS ONBOARD_GOOGLE (v0.11):** "linkIdentity ONLY, never
   signInWithOAuth" was WRONG. Correct policy: attempt linkIdentity
   FIRST (new-user path, keeps plants on fresh anon session); when it
   fails with identity_already_exists, FALL BACK to signInWithOAuth
   (returning-user path, switches to existing durable account). Both
   flows are legitimate and required — the single-path approach left
   returning users stranded.
2. **Unified googleSignIn()** for both contexts (setup sheet + Profile
   sign-in row). Removed setupSheetGoogle() duplicate. The OAuth
   return flow never needs to know which button was tapped; it gates
   the name-confirm sheet on "myProfile.display_name === 'Planter'",
   not on which button launched the flow.
3. **Error surface:** identity_already_exists is NEVER shown to the
   user — it is an internal signal that the fallback path must run.
   The fallback is attempted silently. Only the SECOND failure
   (signInWithOAuth also failed) OR non-identity errors are surfaced.
4. **ja_profile_prompted renamed to ja_setup_seen** in v0.30.0 setup
   code (getStartedFlow + maybeShowSetupSheet). v0.30.0 WRONGLY added
   a cleanup line removing ja_profile_prompted — REVERTED in v0.31.0
   (sacred-key violation).
5. **ja_oauth_return marker** stays sessionStorage — tab-scoped,
   ephemeral, set BEFORE the redirect (unchanged).

## Profile real data decisions (final — from PROFILE_REAL_SPEC.md, v0.29.0)

1. **Honest-states fix:** all hardcoded fake profile data removed (four
   .plant-log-item rows — Fig tree, American Beautyberry, Blackberry,
   Texas Redbud; three .stat-num hardcoded values 7/3/12). Profile now
   shows REAL data or honest empty states, never fake inventory.
2. **renderMyPlants():** queries session user's plants (user_id eq,
   select id/plant_name/tags/kind/planted_at, order planted_at desc,
   limit 50). Renders each as .plant-log-item with type-colored dot
   (edible tag → .edible), plant name, "Found" chip if kind=discovered,
   and planted_at as "Mon DD" format. Empty state: "Nothing planted
   yet. Your first plant lands here." Called on profile load, after
   plant log, after OAuth return.
3. **renderProfileStats():** queries real counts via head:true —
   "Planted" = count kind='planted', "Found" = count kind='discovered'.
   Third stat removed (Inspires count deferred). Empty/no-session shows
   0, never placeholder numbers.
4. **Feed newest-first:** loadFeed already orders planted_at desc — new
   plants appear at TOP immediately (no change needed, verified).
5. **Pull-to-refresh:** initPullToRefresh() on #feed-view (touch
   gesture at scroll-top, pullDistance > 80px threshold) calls
   refreshFeed() → Promise.all([loadFeed(), loadDbPins()]). Desktop
   refresh: ⟳ control inline in feed-section-label.
6. **OAuth re-render:** handleOauthReturn() explicitly calls
   renderProfileHero(), renderMyPlants(), renderProfileStats() after
   loadOwnProfile() so real display_name and real plants show
   immediately, no stale "Planter" after sign-in.
7. **Map unchanged** (tripwire 17 — haze dot fix is the next build).

## Feed card photo decisions (final — from FEEDCARD_SPEC.md, v0.27.0)

1. **Photos earn their space:** photo block renders ONLY when photo_url
   exists. Photoless cards are compact text cards (author, plant name +
   chips, note, actions) — no empty placeholder slab.
2. **Placeholder removed:** photo-placeholder-sprig SVG + CSS deleted.
   Grep found zero references outside the feed card renderer (only
   usage). Map popups already omit placeholders (unchanged).
3. **Cards with photos:** full-width 4:3 image exactly as before.
4. **Spacing:** photoless cards read as intentional compact cards via
   existing card padding; mixed feed (photo + photoless) gutters
   consistent.

## Polish 26 decisions (final — from POLISH26_SPEC.md, v0.26.0)

1. **Wordmark legibility:** #topbar-wordmark and .splash-title both
   color:var(--ink) so "Johnny" reads on dark backgrounds. Gold span on
   "Appleseed" unchanged.
2. **AI banner title legible:** .ai-banner-text strong color:var(--ink),
   body color:var(--stone-700) for contrast on banner fill.
3. **Banner alignment:** .ai-banner margin 0 12px (was 0 20px) — edges
   now align with .post-card horizontal margins.
4. **HONEST FOOTER:** "Your data stays on your device" replaced with
   "No data selling" in BOTH locations (splash .splash-privacy +
   profile footer). Old claim false since Supabase (S2), legal-review
   liability. New claim: "No tracking. No ads. No data selling." —
   every clause literally true.

## Contrast sweep 2 decisions (final — from CONTRAST2_SPEC.md, v0.25.0)

1. **Dark theme completed:** systematic sweep of ALL light-value
   backgrounds (white, green-50, gold-100, violet-50). Converted to
   dark-compatible rgba tints over dark base or appropriate dark tokens.
2. **Notification rows:** unread accent rgba(85,136,102,0.15) on dark,
   visually distinct from read state, text legible.
3. **Photo placeholder:** .post-photo bg #1C2B22 (dark illustration
   slot), SVG stroke #8FA398 (muted light sage) — no longer a light
   slab.
4. **All UI chips/tags:** green/gold/violet family now rgba tints with
   dark-compatible text (green-400, gold-400, violet-400). Selected
   states use slightly higher alpha for distinction.
5. **.google-btn ONLY intentional white** (branded, exempt) — all other
   surfaces dark.

## Filter wrap decisions (final — from FILTERWRAP_SPEC.md, v0.24.0)

1. **Wrap replaces scroll:** #map-filter now flex-wrap:wrap (was
   overflow-x:auto with hidden scrollbar). Pills flow to second row
   instead of clipping; horizontal scroll removed. Bar height grows to
   fit rows.
2. **Compact pills:** padding 5px 12px (was 6px 14px), font-size
   11.5px (was 12px), min-height 30px tap target. Keeps border/radius/
   active/gold-active styling intact.
3. **Position unchanged:** bar stays position:absolute top:12px
   left/right:12px, z-index:10 (map chrome band). Two rows accepted.
4. **Future-proofing (NOT built):** if filter count grows past ~10
   (two rows full), next step is a "Filters" button opening a sheet —
   NOT more rows.
5. **Map render frozen (tripwire 17):** no circle/popup/pin changes.
   Filter chrome only.

## Hero splash decisions (final — from HERO_SPEC.md, v0.22.0)

1. **Still image BASE layer:** assets/hero-image.jpg always present;
   video layers ON TOP and fades away. Guarantees no blank splash if
   video is slow or fails.
2. **Video plays every load:** muted autoplay playsinline, NO loop. On
   'ended' event, ~900ms opacity crossfade to still beneath. Jason
   wants the animation each visit.
3. **SW cache strategy:** video (2.9MB) excluded from precache —
   network-only. Still image network-fallback.
4. **prefers-reduced-motion:** skip video entirely (display:none), no
   firefly animation. Still image + welcome panel (if returning) only.
5. **Firefly particles:** CSS-only system, 12 divs with randomized
   left/delay/duration, 6-8s fall with fade + slight horizontal drift.
   No canvas, no JS loop. Wrapped in @media (prefers-reduced-motion:
   no-preference).
6. **Welcome-back panel:** ONLY shown if ja_user_id exists AND
   ja_splash_seen='true' (returning user). Floats center-bottom,
   ~300ms fade-in after 800ms delay. "Welcome back, [display_name]"
   + "Ready to log another?" + "Let's go" CTA (closes splash → Add
   tab). If user taps anywhere else, dismisses → Map tab.
7. **Screen transitions:** new localStorage flag ja_splash_seen
   (boolean, set on first dismiss). FIRST-TIME: splash → onboard flow
   (existing). RETURNING: splash with welcome panel → Map tab (skip
   onboard). "Let's go" CTA → Add tab.
8. **Z-index (v0.23.0 fix):** .splash-hero z:1, firefly particles
   z:1999, .splash-content wrapper z:3 (lifts wordmark/tagline/buttons
   above hero+fireflies — they were invisible at v0.22.0 due to no
   positioning context). welcome panel z:2001 (absolute positioned,
   above content).
9. **Legibility scrim (v0.23.0):** .splash-hero::after overlay
   rgba(20,33,26,0.35) z:10 — subtle dark scrim between hero media
   and content so text stays readable over bright video frames.
10. **New localStorage keys:** ja_splash_seen (boolean, first-dismiss
    flag). Repurposed ja_display_name for welcome greeting.

## Contrast fix decisions (final — from CONTRAST_SPEC.md, v0.21.0)

1. **Root cause:** hardcoded background:white + dark-theme text tokens
   (now light) = light-on-light. Worst instance: Leaflet popup heading
   (--ink, near-white, on white — invisible; the reported Beautyberry
   bug). Fixed by moving surfaces to var(--stone-200) so they darken
   with the app.
2. **Tripwire 17 scoped exception** (v0.21.0): Leaflet POPUP surfaces
   (.leaflet-popup-content-wrapper, -tip, popup content classes) MAY
   be styled to fix the invisible heading. #leaflet-map, L.circle,
   addHazeCircle, access opacity tiers, markers, pick mode remain
   frozen. Popups are chrome; the map render is still untouched.
3. **Converted background:white -> var(--stone-200):** sheet-btn,
   suggest-item, tag-option, kind-option, found-info, name-edit-btn,
   stat-card, location-bar. The .google-btn is NOT in this list — it
   correctly stays white (shipped v0.20.0).
4. **Leaflet popup dark:** wrapper + tip bg #1C2B22; heading #F5F1E8;
   pin-meta/pin-sci/pin-haze #8FA398; pin-note #C3D2C8; pin-score
   --green-400 (more legible on dark than --green-600). Chips +
   box-shadow unchanged.
5. **Map placeholder backgrounds:** #E8F0E4 -> #14211A so no light
   flash before tiles load (the map CONTAINER background, not the map
   render — allowed).

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
| Photo picker (v0.15.0) | `id="plant-photo-input"`, `#photo-picker`, `onPhotoPick`, `removePhoto` | plant form, below Note |
| Photo compress + upload | `compressPhoto`, `confirmLogWithoutPhoto`, `resolvePhotoContinue` | before submitPlant |
| Photo placeholder symbol | `#photo-placeholder-sprig` (svg symbol) + `.post-photo`/`.pin-photo` CSS | top of body; CSS after submit-bar |
| Plant delete + photo hygiene | `confirmDeletePlant`, `doDeletePlant` | before openCommentSheet |
| Sign-in caption | `.google-caption` | inside openSetupSheet googleBlock |
| Location row (v0.16.0) | `id="location-row"`, `#loc-dot/-primary/-source`, `renderLocRow`, `logLoc` state | plant form, above access selector |
| Location wrapper | `refreshLocation` (high-accuracy + classify), `useMapCenter`, `roundCoord` | where getLogLocation used to be |
| Map pick mode | `startMapPick`/`confirmMapPick`/`cancelMapPick`, `#pick-crosshair`, `#pick-controls`, `#map-view.picking` | map view; exit hook at top of switchTab |
| Haze circles (v0.17.0) | `HAZE_RADIUS_M`, `addHazeCircle`, `dotIcon`, `.aps-dot`, `.pin-haze` | replaces pinIcon; called from renderMarkers |
| Access validation (v0.17.0) | `selectedAccess = null` + block in submitPlant | with location block |
| Dark tokens (v0.18.0) | `:root` remapped --stone-100/200/300/500/700, --ink, plus --glass/--glass-border/--glow-amber | top of style block |
| Firefly glow (v0.18.0) | `#splash::before` dual radial gradients, `@keyframes firefly-pulse`, motion-safe guards | splash CSS |
| Affiliate config + resolver (v0.38.0, dormant) | `const AFFILIATE_CONFIG`, `function affiliateUrl` | after `sb` init / after `dbFind` |
| Affiliate score-preview surface (v0.38.0, dormant) | `id="score-affiliate"`, `.affiliate-btn`, `.affiliate-disclosure` | inside `#score-preview`, set in `renderScore` |
| Affiliate popup surface (v0.38.0, dormant) | `.pin-affiliate-row/-btn/-disclosure` | end of `dbPinPopupHtml` |
| Boot | `DOMContentLoaded` → `initMap()` + `loadFeed()` + `loadOwnProfile()` | end of script |
| Build validator (RIDER v0.38.0) | `scripts/validate.js` — CSS brace balance, HTML tag balance, inline JS `node --check`, version fan-out (BUILD_RULES rule 6+7) | repo root, `scripts/` dir |

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

## I18N architecture (v0.37.0) — bilingual (en/es)

- **let LANG** (line ~2100) — resolved on boot: ja_lang if set → else navigator.language starts with 'es' → 'es' → else 'en'. Auto-detect fires only when ja_lang is unset.
- **const STR** — `{ en: {...}, es: {...} }`. 180 keys each (exact parity, +3 in v0.38.0 for the
  dormant affiliate strings). Lookup via `t(key, vars)`.
- **t(key, vars)** — template interpolation for `{name}`-style placeholders, falls back to `STR[LANG][key]`, console.warns on missing keys, NEVER returns undefined (returns the key itself as last resort).
- **applyStrings()** — walker for static markup: `data-i18n="key"` sets textContent, `data-i18n-attr="attr:key"` sets attributes. Runs once on DOMContentLoaded.
- **Dynamic sentences use templates**, never concatenation: `t('splash_welcome_back', { name: displayName })` → "Welcome back, {name}". Word order must be free to differ per language.
- **Not extracted** (stays literal): "Johnny Appleseed" brand, "AIRIHA LLC", scientific names (translate="no"), PLANT_DB data content, version footer, console/log strings.
- **ja_lang** — SACRED localStorage key, 'en' | 'es'. setLang(lang) writes with read-back verify, then location.reload().
- **Language switch UI**: Settings row "Language / Idioma" shows current language name (English | Español), tap toggles. Splash link below Browse button shows opposite language, tap switches.
- **translate="no"** on: topbar wordmark, splash title, scientific names (suggest dropdown when not invasive), version footer. document.documentElement.lang set to LANG on boot and after switch.
- **months_short** — both dictionaries have localized month abbreviations. Scorer uses t('months_short').split(',') for best-months lists.
- **Logic guard**: 'Planter' comparisons use the LITERAL string (DB default), never t('profile_default_name') — "Jardinero" is presentation only.
- **Tripwire 17 exception consumed** — map popup copy extracted v0.36.0. Map re-frozen after v0.36.0.
- **Roadmap**: Phase 1 (v0.36.0-v0.36.2) extraction SHIPPED. Phase 2 (v0.37.0) Spanish dictionary SHIPPED. Phase 3 = Spanish plant search akas + safety-text review.

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
- **`ja_lang` is SACRED** (v0.37.0) — user language preference, 'en' | 'es'.
  Snapshot → mutate → verify read-back lives in `setLang()`. After write,
  location.reload() re-renders the entire app in the new language.
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
15. **Location is never guessed silently.** The map-center fallback
    must never auto-fire; every published coordinate was either a
    classified GPS fix the user saw, a manual map placement, or an
    explicit user tap on "Use map center". No fourth path may ever be
    added. (The pre-v0.16.0 `getLogLocation()` silent fallback is the
    cautionary tale — pins published at locations the user never saw.)
16. **The circle IS the data.** Haze circles are radius 75 m (the
    rounding-cell extent at ~29.5°N), centered on the stored
    coordinate. NEVER jittered, never randomized, never resized for
    aesthetics — jitter is fabricated data (honest-states violation),
    and the stored coordinate is already public via the API, so the
    honest circle leaks nothing new.
17. **The map render is off-limits during dark-theme work.**
    #leaflet-map, L.circle rendering, addHazeCircle, access opacity
    tiers, markers, and pick mode are NOT touched when implementing
    dark surfaces. SCOPED EXCEPTION (v0.21.0): Leaflet POPUP styling
    (.leaflet-popup-content-wrapper, -tip, popup content classes) MAY
    be modified to fix contrast bugs — popups are chrome, not the map
    render. The map render itself stays frozen. backdrop-filter is
    NEVER applied over the map (Leaflet pan/zoom + blur destroys
    framerate on mid-range Android).
18. **Auth flows are origin-agnostic and zombie-tolerant.** (Backfilled
    RIDER v0.38.0 — referenced by the Auth clean/Return fix/Google fix 2
    decisions above since v0.30.0 but never given its own list entry
    until now; no behavior changed, this is a documentation fix.) Every
    Google entry point handles BOTH link and sign-in via an
    unconditional fallback — if linkIdentity() fails for any reason on
    an anonymous session, fall back to signInWithOAuth() unconditionally;
    never pattern-match fragile provider error strings. Auth errors
    ALWAYS surface raw provider text (e.message plus e.status/e.code
    when present), never a generic "Could not sign in". Redirect-based
    auth errors (linkIdentity rejections navigate back with
    ?error_code=... rather than throwing) are handled at the RETURN path
    only — `handleOauthReturn` parses both the query string and the hash
    fragment — never assumed to reach the call site directly.
19. **LOCALHOST TALKS TO PRODUCTION.** There is no staging environment —
    a locally served `index.html` uses the live Supabase URL + anon key,
    so localhost sessions hit production auth and the production
    database. Localhost acceptance testing is READ-AND-RENDER ONLY:
    never submit plants, never sign in (anonymous or Google) from a
    localhost origin. Google sign-in also fails there by design (the
    redirect allowlist covers production origins only).

## Validate-after-edit checklist — skip none

Run via `node scripts/validate.js` (covers the four checks below in one
pass — see the "index.html landmarks" table for the script's own row).

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
- ✅ Photos / S2.5 (v0.15.0): photo picker on the Plant form, client
  compression (1280px / q0.82) → Storage `plant-photos` bucket
  (dashboard-created), photo on feed cards (4:3) + pin popups (110px
  strip), universal sprig placeholder (honest illustration), delete
  hygiene, sign-in caption. Per-plant sketch library = pending asset
  lane. Own-plant delete path created (was a dead reference since S4c).
- ✅ Location (v0.16.0): visible location row on the Plant form (status
  dot, rounded coords, source label, Refresh / Place on map), high-
  accuracy GPS with accuracy classification, map pick mode with
  crosshair + "Use this spot", explicit "Use map center" in failed
  state only. Silent map-center fallback removed — tripwire 15.
- ✅ Haze (v0.17.0): point-pins replaced by honest 75 m circles
  (tripwire 16) + center dots, access sets prominence (public/ask/
  private tiers), treasure-hunt copy on public popups only, access now
  a required explicit choice.
- ✅ Dark theme (v0.18.0): semantic surface-token remap (--stone-100 →
  near-black forest #14211A, --ink → warm off-white, plus --glass/
  --glow-amber), frosted glass cards (feed/score/sheets), firefly glow
  on splash with motion-safe pulse, Fraunces + DM Sans unchanged.
  Tripwire 17: map deliberately untouched.
- ✅ Splash fix (v0.19.0): box-shadow on italic wordmark → layered
  text-shadow (follows letterforms, no square), firefly-pulse split
  into -box/-text variants, splash z-index 500 → 2000 (occludes map
  controls). Map unchanged (tripwire 17).
- ✅ Overlay fix (v0.20.0): Google button to spec (#FFFFFF bg, #1F1F1F
  text, dark G stroke — exempt from app palette), sheet backdrop
  near-opaque (0.92) to hide map chrome behind glass, z-index band map
  enforced (toast 3000, notif 1150/1151). Map unchanged (tripwire 17).
- ✅ Contrast fix (v0.21.0): converted 9 light-island surfaces
  (sheet-btn, suggest, tag/kind options, found-info, name-edit, stats,
  location-bar) to var(--stone-200); Leaflet popup dark (#1C2B22 bg,
  light text) fixing the invisible Beautyberry heading; map placeholder
  #14211A. Tripwire 17 scoped exception: popup styling allowed, map
  render frozen. Google button unchanged (stays white, v0.20.0).
- ✅ Hero splash (v0.22.0): cinematic video hero (still base + video
  overlay, ~900ms crossfade on end), 12 falling firefly particles
  (CSS-only, 6-8s), welcome-back panel for returning users (ja_splash_seen
  flag). Screen transitions: first-time → onboard, returning → Map tab
  (skip onboard), "Let's go" CTA → Add tab. Video excluded from SW
  precache (2.9MB network-only). prefers-reduced-motion: still only, no
  video/fireflies.
- ✅ Hero z-index fix (v0.23.0): .splash-content wrapper z:3 lifts
  wordmark/tagline/buttons above hero (z:1) and fireflies (z:1999) — they
  were invisible at v0.22.0. Legibility scrim (hero::after
  rgba(20,33,26,0.35)) so text stays readable over bright video frames.
- ✅ Filter wrap (v0.24.0): map filter bar now flex-wrap:wrap (was
  overflow-x:auto with hidden scrollbar). Pills flow to two rows, all
  visible/reachable on desktop. Compact sizing (5px 12px padding, 11.5px
  font, 30px min tap height). Future: >10 filters → sheet, not more rows.
- ✅ Contrast sweep 2 (v0.25.0): completed dark theme, converted ALL
  light-value backgrounds (green-50, gold-100, violet-50, remaining white)
  to dark-compatible rgba tints. Notification rows, photo placeholder,
  all chips/tags now dark. Google button ONLY white element (branded).
- ✅ Polish 26 (v0.26.0): wordmark/splash-title var(--ink) so "Johnny"
  reads on dark (was dark-on-dark). AI banner title/body light, margins
  12px to align with feed cards. HONEST FOOTER: "Your data stays on your
  device" → "No data selling" (both locations) — old claim false since
  Supabase S2, legal liability.
- ✅ Feed card photos (v0.27.0): photo block renders ONLY when photo_url
  exists. Photoless cards = compact text cards, no empty placeholder slab
  (~70% space saved). Placeholder SVG + CSS removed (zero other uses).
  Cards with photos unchanged (4:3 full-width).
- ✅ Contrast token fixes (v0.28.0): toast + active filter pill color
  var(--ink) (was --stone-100, near-black). 13 green-700-as-text instances
  -> green-400 (light on dark). Hero assets replaced (watermark removed,
  8% smaller). "Reminders coming soon" label fix.
- ✅ Profile real data (v0.29.0): removed ALL hardcoded fake profile data
  (4 plant rows, 3 stat numbers) — honest-states fix. renderMyPlants()
  queries real user plants (newest first), renderProfileStats() queries
  real counts (Planted/Found). Feed already newest-first. Pull-to-refresh
  gesture + desktop ⟳ control on feed. OAuth return re-renders profile
  with real name + plants. Map unchanged (haze-dot fix is the next build).
- ✅ Google fix (v0.30.0): unified googleSignIn() tries linkIdentity FIRST
  (new-user path), silently falls back to signInWithOAuth on
  identity_already_exists (returning-user path). Fixes "already linked to
  another account" stranding. Removed setupSheetGoogle() duplicate.
  ja_profile_prompted → ja_setup_seen; one-time cleanup on boot.
- ✅ Domain fix (v0.31.0): canonical URL → https://johnnyappleseed.farm
  (custom domain, all OAuth redirects point there). onrender.com works
  but .farm is production. REVERTED sacred-key violation: v0.30.0
  removal of ja_profile_prompted was unauthorized; deletion code
  removed, key persists. False comment deleted (the one that caused the
  Google bug). Reaffirm: builds implement ONLY their spec, no
  unrequested changes to sacred keys or schema.
- ✅ Google fix 2 (v0.32.0): unconditional fallback — if linkIdentity
  fails for ANY reason on anonymous session, fall back to signInWithOAuth
  (no fragile error-string matching). v0.30.0 checked for literal
  'identity_already_exists' but Supabase returns "Identity is already
  linked" — match failed, fallback never fired. Persistent auth errors
  (dismissible sheet, not toast) with raw provider message. Never strand:
  Profile always shows "Sign in with Google" when session is anonymous.
  Unambiguous success: "Signed in with Google" + email.
- ✅ Auth clean (v0.33.0): raw errors ALWAYS displayed (e.message,
  e.status/e.code) in auth error dialogs — v0.32.0 passed errors but
  showed only title. Zombie purge: signOut scope:local BEFORE
  signInWithOAuth fallback (corrupt/deleted-user session never poisons
  clean sign-in). Dynamic origin: redirectTo = window.location.origin
  (supersedes unpasted ORIGINFIX) — .farm canonical, onrender mirror
  works, PWAs work. TRIPWIRE 18 extended: auth flows origin-agnostic,
  zombie-tolerant, raw-error-surfacing.
- ✅ Return fix (v0.34.0): linkIdentity is redirect-based — on rejection
  Supabase navigates back with ?error_code=identity_already_exists, not
  an in-code error. handleOauthReturn parses error/error_code/
  error_description from BOTH query+hash. AUTO-RECOVER on identity
  errors: signOut scope:local, set ja_oauth_autoretry guard,
  signInWithOAuth (one extra bounce, not a stranding). Loop guard: if
  autoretry already '1', stop and show verbatim error. Clear guard on
  durable session. All OAuth errors now show verbatim error_description.
  TRIPWIRE 18: redirect-based auth errors handled at RETURN, never
  assumed to reach call site.
- ✅ Haze dot (v0.35.0): DOT_HIDE_ZOOM = 16. At zoom >= 16 center dots
  disappear entirely (circle is sufficient tap target, dot overclaims
  precision). Popups bind to BOTH circle and dot — tap works in both
  regimes. All dots in L.layerGroup, one zoomend listener toggles the
  group. Access tiers 0.25/0.15/0.08 UNCHANGED (regression check
  passed). TRIPWIRE 17 exception consumed: dot visibility + circle
  popups edited; all else frozen. Map re-freezes after v0.35.0, NO
  further exceptions. Acceptance list fully cleared.
- ✅ Affiliate plumbing (v0.38.0, SHIPS DORMANT): program-agnostic
  `AFFILIATE_CONFIG` + `affiliateUrl()` resolver, invasive-exclusion
  invariant, score-preview + DB-pin popup CTA surfaces (feed cards and
  PIN_SPOTS excluded), mandatory FTC disclosure line, EN/ES strings.
  `enabled: false` — zero affiliate UI renders live. Activation is a
  future config-only change. No schema/localStorage changes.
- ⏳ S3: Open-Meteo + USDA PHZM → PlantScore v2 (live frost/soil temp)
- ⏳ BYOK Claude layer · ⏳ PWABuilder → Play Store
