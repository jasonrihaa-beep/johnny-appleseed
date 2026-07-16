# PUBLICSHELL SPEC — A Front Door With a Doorknob (v0.40.0)

Execution contract. Sonnet default. All decisions final.
Audit findings: the site has no meta description, no
OpenGraph/Twitter tags, no favicon link, no apple-touch-icon,
no contact channel, no robots.txt — sharing the URL renders a
blank card. Plus six computed WCAG contrast failures.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. NO new binary assets: favicon and apple-touch-icon LINK to
   the existing icons/icon-192.png and icon-512.png (browsers
   accept PNG favicons; Apple scales 192 fine). The share
   image is the existing assets/hero-image.jpg via absolute
   URL.
2. Head block (insert after theme-color meta):
   - <title>Johnny Appleseed — Plant something. Feed someone.</title>
   - meta description: "A free community map of planted and
     found plants. Log what you grow, discover what's near
     you, and help feed your neighborhood. English y Español."
   - <link rel="icon" type="image/png" sizes="192x192"
     href="icons/icon-192.png"> and a 512 variant
   - <link rel="apple-touch-icon" href="icons/icon-192.png">
   - OpenGraph: og:title (same as title), og:description
     (same as meta), og:type website, og:url
     https://johnnyappleseed.farm/, og:image
     https://johnnyappleseed.farm/assets/hero-image.jpg,
     og:site_name Johnny Appleseed, og:locale en_US and
     og:locale:alternate es_MX
   - twitter:card summary_large_image + twitter:title/
     description/image mirroring OG
3. Contrast fixes (computed WCAG failures, all text-token
   swaps, no layout changes):
   - #pick-confirm color -> var(--ink)
   - .follow-btn.following color -> var(--ink)
   - .sheet-btn.danger color -> var(--red-400); if --red-400
     is not defined in :root, add --red-400: #E8836F
   - .found-info-warn color -> var(--red-400) (same token rule)
   - .splash-lang-link color -> var(--green-400)
   - .leaflet-popup-content .pin-insp-count and
     .score-badge span color -> var(--green-400)
   (Popup rule edits are within the consumed tripwire-17 popup
   exception; the map RENDER stays frozen.)
4. Contact channel: in the Profile footer, directly under the
   existing honesty line, a small muted mailto link — new
   i18n keys footer_contact en:"Contact" / es:"Contacto" —
   href mailto:JASON-REPLACE-EMAIL. Same muted styling as the
   footer, no emoji.
5. New file robots.txt in repo root, exactly:
   User-agent: *
   Allow: /
6. manifest.json: "lang" -> "en" (bilingual app; keep neutral).

## Claude Code tasks (one commit, v0.40.0)

### Task 1 — Head block per decision 2 (verify no duplicate
title/meta remains)
### Task 2 — Contrast fixes per decision 3
### Task 3 — Contact link per decision 4 (add the two STR keys
to BOTH en and es; key parity must remain equal)
### Task 4 — robots.txt per decision 5
### Task 5 — manifest lang per decision 6
### Task 6 — Version, docs, self-verify
Fan-out: footer v0.40.0 + sw.js CACHE appleseed-v0-40-0.
CLAUDE_CONTEXT.md: head/SEO landmark, contrast-fix note,
contact link, roadmap.
Post-deploy self-verify (rule 11, four probes):
1.
