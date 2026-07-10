# HERO SPEC — Splash Video + Fireflies + Welcome Back (v0.22.0)

Execution contract. Sonnet default. All decisions final.
The splash gains a cinematic hero: still image base, video
overlay that plays then crossfades to the still, falling
firefly particles, and a returning-user welcome-back panel.

## Assets (already committed, do not create)
- assets/hero-image.jpg (570KB) — still base layer
- assets/hero-video.mp4 (2.9MB) — plays once per load, then
  crossfades to the still. Image is close-but-not-exact to the
  video's last frame; a slow crossfade masks the difference.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. Still image is the BASE layer, always present — the video
   layers ON TOP and fades away. This guarantees no blank
   splash even if the video is slow or fails to load.
2. Video: muted autoplay playsinline, NO loop. On the 'ended'
   event, crossfade (opacity, ~900ms) the video out to reveal
   the still beneath. Video plays every app load (decision:
   Jason wants the animation each visit).
3. Video is EXCLUDED from the service-worker precache (2.9MB
   must never block the app shell from caching). It loads from
   network; the still image MAY be precached (small, and it's
   the fallback). Add sw.js cache-strategy note.
4. prefers-reduced-motion: skip the video entirely, show the
   still image immediately, no firefly animation. Respect
   reduced-motion at all layers.
5. Firefly particles: CSS-only particle system (~12 divs,
   randomized left offset + animation-delay), 6–8s fall with
   fade + slight horizontal drift, created on splash mount,
   cleared on dismiss. No canvas overhead, no JS animation loop.
6. WELCOME-BACK panel: ONLY shown if localStorage ja_user_id
   exists (returning user). Floats center-bottom of the splash
   above the title, ~300ms fade-in after 800ms delay. "Welcome
   back, [display_name]" + tiny muted "Ready to log another?"
   with a single CTA ("Let's go" closes splash → jumps to Add
   tab). If the user taps anywhere else or waits, the normal
   splash-dismiss (tap-to-explore) flow applies.
7. SCREEN TRANSITIONS: new localStorage flag `ja_splash_seen`
   (boolean, set on first dismiss). FIRST-TIME USERS: splash →
   onboard flow (existing). RETURNING USERS (ja_splash_seen
   true): splash with welcome panel → straight to map tab
   (skip onboard). The "Let's go" CTA in the welcome panel
   dismisses splash + jumps to Add tab.
8. z-index: firefly particles at 1999 (below the splash title
   2000 but above the video ~10), welcome panel at 2001 (above
   title so it's always readable).

## Claude Code tasks (one commit, v0.22.0)

### Task 1 — Hero image + video layers
Add inside #splash, BEFORE .splash-content (so the content
layers above the media):

```html
<div class="splash-hero">
  <img src="assets/hero-image.jpg" alt="" class="hero-still">
  <video class="hero-video" muted playsinline autoplay>
    <source src="assets/hero-video.mp4" type="video/mp4">
  </video>
</div>
```

CSS for .splash-hero: position absolute, inset 0, overflow
hidden, z-index 1. .hero-still: width 100%, height 100%,
object-fit cover, display block. .hero-video: same sizing,
position absolute inset 0, opacity 1, transition opacity 900ms
ease-out, z-index 2 (above the still).

Add .hero-video.fadeout class: opacity 0.

JS (inline <script>): select .hero-video, listen for 'ended',
add .fadeout class. Wrap in DOMContentLoaded. Guard:
`if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) { video.style.display = 'none'; }`
at the top of the event setup so reduced-motion users never see
the video.

### Task 2 — Firefly particle system
CSS @keyframes firefly-fall: 0% transform translateY(-20px)
opacity 0; 10% opacity 0.6; 90% opacity 0.4; 100% translateY(100vh)
translateX(±15px randomized per particle) opacity 0.

Create 12 .firefly divs inside #splash (after .splash-hero,
before .splash-content), each: position absolute, top 0, width
3px, height 3px, border-radius 50%, background rgba(244,161,39,0.7),
z-index 1999, pointer-events none. Inline style per div:
left: (random 10–90%), animation-delay: (random 0–4s),
animation-duration: (random 6–8s). Animation: firefly-fall
linear infinite.

Wrap firefly creation in @media (prefers-reduced-motion: no-preference)
so the particles don't render at all for reduced-motion users.

### Task 3 — Welcome-back panel
Add inside #splash (after .splash-content):

```html
<div id="welcome-back" style="display:none">
  <p class="wb-greeting">Welcome back, <span id="wb-name"></span></p>
  <p class="wb-prompt">Ready to log another?</p>
  <button class="wb-cta">Let's go</button>
</div>
```

CSS #welcome-back: position absolute, bottom 180px (above the
tap-to-explore hint), left 50%, transform translateX(-50%),
z-index 2001, background var(--glass), backdrop-filter blur(12px),
border 1px solid var(--glass-border), border-radius 16px,
padding 20px 24px, text-align center, max-width 280px, opacity 0,
transition opacity 300ms ease-out.

#welcome-back.show: opacity 1.

.wb-greeting: font-family var(--font-serif), font-size 18px,
color var(--ink), margin 0 0 4px. .wb-prompt: font-size 13px,
color var(--stone-500), margin 0 0 16px. .wb-cta: background
var(--green-700), color white, border none, border-radius 8px,
padding 10px 20px, font-size 14px, font-weight 600, cursor pointer.

JS (inline): on splash mount, if (localStorage.ja_user_id exists
AND localStorage.ja_splash_seen === 'true'), fetch the user's
display_name from localStorage ja_display_name (default "Gardener"
if missing), set #wb-name textContent, show #welcome-back
(display block), then setTimeout 800ms add .show class.

.wb-cta click: dismiss splash (existing dismissSplash()), then
setTimeout 100ms setActiveTab('add').

### Task 4 — Screen transition logic
Modify dismissSplash() (the existing splash-dismiss handler):
set localStorage.ja_splash_seen = 'true', then check: if
ja_user_id does NOT exist (first-time user), call showOnboard()
as it does now. If ja_user_id DOES exist (returning user),
setActiveTab('map') — skip onboard, land on map.

The welcome panel's "Let's go" CTA already dismisses + jumps to
Add (task 3), so it bypasses this logic.

### Task 5 — Service-worker cache strategy note
Add comment in sw.js above the PRECACHE array:
`// Hero video (assets/hero-video.mp4) excluded — 2.9MB, network-only.`
Do NOT add the video to the precache array. The still image
(hero-image.jpg) MAY be added if bandwidth allows; if not, note
it as network-fallback too.

### Task 6 — Version, docs
Fan-out: footer v0.22.0 + sw.js CACHE appleseed-v0-22-0.
CLAUDE_CONTEXT.md: add "Hero splash decisions" section covering
design points 1–8 above, note the two new localStorage keys
(ja_splash_seen, repurposed ja_display_name). Update roadmap.

### Task 7 — Post-deploy self-verify (rule 11, four probes)
1. index.html: v0.22.0 + markers (.splash-hero exists,
   .hero-video src="assets/hero-video.mp4", #welcome-back exists,
   firefly @keyframes present)
2. sw.js cache = appleseed-v0-22-0
3. GET {SUPABASE_URL}/rest/v1/profiles?select=display_name&limit=1
   with apikey + Bearer -> 200 JSON
4. GET {SUPABASE_URL}/rest/v1/plants?select=lat,lng&limit=5
   with apikey + Bearer -> 200, all <= 3 decimals
No data mutation. Report table, stop.

## Acceptance (Jason)
- First load (no ja_user_id): splash plays video, fireflies
  fall, tap-to-explore dismisses → onboard flow
- Returning user (ja_user_id + ja_splash_seen): splash plays
  video, fireflies fall, welcome panel fades in with correct
  display_name, "Let's go" → Add tab, tap anywhere else → Map tab
- prefers-reduced-motion: still image only, no video, no
  fireflies, welcome panel (if returning) still appears
- Video crossfade is smooth (~900ms), no jarring cut
- Fireflies feel ambient, not distracting (12 particles, slow
  6–8s fall)
