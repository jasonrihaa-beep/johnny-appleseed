# S2 SPEC — Supabase Integration

Design was done at Fable level in chat; this file is the execution
contract. Claude Code runs this mechanically on Sonnet default —
zero schema or security decisions remain open.

## Design decisions (fold into CLAUDE_CONTEXT.md after S2 ships)

1. **RLS is the entire security layer.** The anon key ships in
   index.html — that is correct and by design for a static PWA.
   Never treat the anon key as a secret; never add any other key.
2. **Coordinate privacy is DB-enforced.** `truncate_coords` trigger
   guarantees ≤3 decimals (~110 m) server-side. Client also
   truncates before insert (courtesy + honesty in the UI preview).
3. **Anonymous-first auth.** Anonymous sign-in on first plant log —
   no gate to browse. Upgrade nudge ("add email to keep your
   garden") after 3rd plant via magic link → converts the same
   auth.uid(), plants are kept.
4. **Orphan tradeoff accepted (MVP):** anon user clears site data →
   identity unrecoverable → their pins stay public forever, editable
   by no one. Documented, not a bug.
5. **`sb-*` localStorage keys are SACRED** (supabase-js session).
   The future "Clear my data" setting must exclude them or show a
   permanent-loss confirm for anonymous users. Add to the sacred-keys
   list in CLAUDE_CONTEXT.md the moment supabase-js first runs.
6. **Spam cap:** 50 plants/user/24h via DB trigger. Client shows the
   raised exception message as a toast.
7. **Nearby feed = bounding box** on the (lat,lng) index (±0.75° ≈
   50 mi), client-side distance sort. No PostGIS at MVP scale.
8. **Deferred, documented:** photo upload (S2.5 storage bucket),
   display-name profanity filter, PostGIS.

## One-time dashboard steps (Jason, ~5 min)

1. supabase.com → New project (name: johnny-appleseed, region:
   US East or Central). Save the DB password in your password
   manager — needed only for dashboard access, never in code.
2. SQL Editor → paste schema.sql → Run. Expect "Success" —
   23 statements.
3. Authentication → Sign In / Up → enable **Anonymous sign-ins**.
4. Authentication → Rate Limits → confirm defaults are on.
5. Project Settings → API → copy **Project URL** and **anon public
   key** for the client wiring below.

## Claude Code task list (in order, one commit each)

### Task 1 — commit schema + spec
- Add `schema.sql` and `S2_SPEC.md` to repo root. No app changes,
  no version bump (docs/schema only).

### Task 2 — client wiring (version → 0.4.0)
- Add supabase-js v2 via CDN in <head>:
  `https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2` (jsdelivr,
  not cdnjs — cdnjs doesn't carry it).
- Add config constants near top of script:
  `const SUPABASE_URL = '...'` / `const SUPABASE_ANON_KEY = '...'`
  (values supplied by Jason at build time).
- Init: `const sb = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY)`.
- **ensureAuth()**: on first submitPlant() call, if no session →
  `sb.auth.signInAnonymously()`. Never block browsing on auth.
- **submitPlant()** (replace toast-only stub):
  1. ensureAuth()
  2. Truncate lat/lng to 3 decimals client-side
  3. `sb.from('plants').insert({ plant_name, sci, tags, lat, lng,
     neighborhood, score, note })` — user_id comes from DB default;
     NEVER send user_id from the client
  4. Surface DB errors (incl. daily-cap message) via toast(msg)
  5. On success: existing toast + switch to feed
- **Map load**: on initMap success, fetch plants in current map
  bounds (`.gte/.lte` on lat & lng, `.order('planted_at',
  {ascending:false}).limit(200)`) and render as pins alongside
  PIN_SPOTS demo pins. Filter pills apply to both sets.
- **Feed load**: same bounding-box query around user's stored
  region center, render post cards (author = profiles.display_name
  via a second query keyed on distinct user_ids; no joins needed
  at MVP scale).
- **Access selector** (new form group on Plant tab, below Type):
  label "Who can reach it?" — three tag-option buttons:
  "Open spot" (access='public') / "Ask first" (access='ask') /
  "My yard" (access='private', default selected). Include `access`
  in the insert. One caption line under the group, exact copy:
  "Open spots mean parks, parkways, and community gardens —
  where planting is permitted."
- **Map filter**: add "Open harvest" pill → query `access = 'public'`;
  public-access pins get a gold ring (2px stroke) around the pin.
- **Location for logging**: navigator.geolocation with graceful
  fallback → map-center coordinates + toast explaining fallback.
  Never block a log on GPS permission.
- Error handling: every sb call in try/catch; failures degrade to
  toasts, never break the tab.
- Version fan-out: footer 0.4.0 + sw.js CACHE appleseed-v0-4-0.
- All three validation checks before declaring done.

### Task 3 — CLAUDE_CONTEXT.md update (rides with Task 2 commit)
- Add S2 design decisions above, the sb-* sacred-keys rule, and
  bump the roadmap state.

## Acceptance checks (Jason, on the live URL after deploy)
- Log a plant on the Pixel → pin appears on map after reload
- Same plant visible in a desktop incognito window (public read)
- Supabase dashboard → Table Editor → plants: lat/lng show exactly
  3 decimals (trigger proof)
- Attempt a row edit from incognito SQL/API without auth → denied
  (RLS proof)
