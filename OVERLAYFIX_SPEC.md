# OVERLAYFIX SPEC — Legible Buttons, Opaque Overlays (v0.20.0)

Execution contract. Sonnet default. All decisions final.
Two dark-theme regressions: a white-on-white Google button,
and translucent sheets letting map controls show through.
Plus a small z-index audit so this class of bug closes.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. ROOT CAUSE, Google button: background:white with
   color:var(--ink), but --ink is now #F5F1E8 (dark theme),
   giving white-on-white. Google's own button spec is white
   background + #1F1F1F text + full-color G. Hardcode these
   (do NOT use --ink here) so the button stays correct in any
   theme. This is a branded third-party button, exempt from
   the app palette by design.
2. ROOT CAUSE, sheets: #action-sheet uses translucent
   var(--glass) + blur. Over the MAP, the pills/FAB (z 1000)
   show through the glass. Fix by making the sheet's backdrop
   fully opaque enough to hide map chrome AND/OR raising the
   sheet system above a clean overlay band. Chosen fix: the
   backdrop becomes near-opaque (rgba(13,26,15,0.92)); the
   sheet keeps its glass look but now sits over an opaque
   scrim, not the live map. Glass stays; bleed-through stops.
3. Z-INDEX BANDS (document in CLAUDE_CONTEXT, apply where
   wrong): base content 1-100; map chrome (pills/FAB/pick)
   1000-1050; overlays + their backdrops (action sheet, setup
   sheet, notif panel) 1100-1199; splash 2000; toast 3000
   (toast must never be occluded). Audit each z-index against
   these bands; fix only those that violate — do not restyle
   anything that already complies.
4. The Google button "G" mark must be the recognizable
   multi-color Google G OR a neutral dark stroke G on white —
   NOT var(--green-700) stroke (near-invisible on white).
   Use a dark-neutral (#1F1F1F) or the standard colored G.
5. Map untouched (tripwire 17): no edits inside #map-view, no
   circle/popup changes. Overlays and buttons only.

## Claude Code tasks (one commit, v0.20.0)

### Task 1 — Google button to spec
.google-btn: background #FFFFFF, color #1F1F1F, border
1px solid #DADCE0 (Google's spec grey). The G mark: dark
#1F1F1F stroke (or colored Google G) at proper size — never
--green-700. Applies everywhere .google-btn renders (setup
sheet + Profile Keep-your-garden). The sign-in caption below
it keeps the app's muted token (it's app copy, not the
button).

### Task 2 — Opaque sheet backdrop
#action-sheet-backdrop background -> rgba(13,26,15,0.92)
(near-opaque; hides map pills/FAB behind it). The sheet itself
keeps var(--glass)+blur for the frosted look — it now sits
over an opaque scrim, so nothing bleeds through. Verify the
setup sheet, action sheet, and report sheet all use this
backdrop.

### Task 3 — Z-index audit
Walk every z-index against decision-3 bands. Toast: ensure it
is 3000 (currently lower — must never be hidden by a sheet).
Confirm notif-panel and its context sit in 1100-1199. Fix
only violations; note the band map in CLAUDE_CONTEXT. Do not
touch map chrome values (tripwire 7) or the splash 2000.

### Task 4 — Version, docs
Fan-out: footer v0.20.0 + sw.js CACHE appleseed-v0-20-0.
CLAUDE_CONTEXT.md: z-index band map, the two dark-theme
root causes, roadmap.

### Task 5 — Post-deploy self-verify (rule 11, four probes)
1. index.html: v0.20.0 + markers (.google-btn background
   #FFFFFF or #fff with #1F1F1F text, backdrop
   rgba(13,26,15,0.92), toast z-index 3000)
2. sw.js cache = appleseed-v0-20-0
3. GET {SUPABASE_URL}/rest/v1/profiles?select=display_name&limit=1
   with apikey + Bearer -> 200 JSON
4. GET {SUPABASE_URL}/rest/v1/plants?select=lat,lng&limit=5
   with apikey + Bearer -> 200, all <= 3 decimals
No data mutation. Report table, stop.

## Acceptance (Jason)
- Setup sheet: Continue with Google button is white with dark
  readable text and a visible G; no filter pills or FAB show
  through the sheet or its backdrop
- Profile Keep-your-garden: same corrected Google button
- Open any sheet over the map: map chrome fully hidden behind
  the backdrop
- Toast still appears above an open sheet
- Map tab: unchanged from v0.19.0
