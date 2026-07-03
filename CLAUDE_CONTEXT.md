# CLAUDE_CONTEXT — Johnny Appleseed

Read this before any edit. It replaces 2-3k tokens of re-discovery grep churn.
Written for the agent, not for humans.

---

## App identity

- **Johnny Appleseed** v0.4.0 — social planting network. "Plant. Share. Grow Together."
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
| Supabase wiring | `ensureAuth`, `submitPlant`, `loadDbPins`, `loadFeed`, `esc(` | after selectTag |
| Live feed container | `id="feed-live"` | feed view |
| Boot | `DOMContentLoaded` → `initMap()` + `loadFeed()` | end of script |

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
- App-created keys (none yet): prefix `ja_` (e.g. `ja_profile`,
  `ja_feed_radius`)
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
- ⏳ S3: Open-Meteo + USDA PHZM → PlantScore v2 (live frost/soil temp)
- ⏳ S4: BYOK Claude layer · ⏳ S5: PWABuilder → Play Store
