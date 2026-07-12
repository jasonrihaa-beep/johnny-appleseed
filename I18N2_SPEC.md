# I18N PHASE 2 SPEC — Español (v0.37.0)

Execution contract. Sonnet default. All decisions final.
The Spanish dictionary arrives as STR_ES.js (repo root,
translated and reviewed in the design lane). This build splices
it, adds the language system, and makes the app bilingual.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. NEW SACRED KEY ja_lang: 'en' | 'es'. Language resolution on
   boot: ja_lang if set -> else navigator.language starts with
   'es' -> 'es' -> else 'en'. Auto-detect fires only when
   ja_lang is unset (first run); an explicit choice always
   wins thereafter.
2. Language switch = set ja_lang (read-back verify) then
   location.reload(). A reload guarantees every surface —
   feed cards, popups, dynamic sentences — re-renders in the
   new language with zero per-surface re-render code. The
   brief flash is the accepted cost.
3. months_short is added to BOTH dictionaries: en gets
   "Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec"; es
   arrives in the file. The scorer's month-name rendering
   switches to t('months_short').split(',') so best-months
   lists localize. After this, en and es key counts are EQUAL
   — the final probe checks exact parity.
4. LOGIC GUARD: grep for any comparison against the literal
   'Planter' (the setup-sheet gate and profile defaults).
   Those comparisons must use the LITERAL string 'Planter'
   (the DB default), NEVER t('profile_default_name') — the
   Spanish display value "Jardinero" is presentation only.
   Report each comparison site verified.
5. Surfaces: Settings gains a "Language / Idioma" row showing
   the current language's name; tap toggles en<->es per
   decision 2. The splash gains a small text link under the
   secondary button: shows "Español" when running in English,
   "English" when in Spanish; tap = same toggle. Stroke SVG
   only if any icon is used; no flags, no emoji.
6. translate="no" attributes on: the topbar wordmark, splash
   wordmark, scientific-name elements (suggest dropdown sci
   line, popup sci line), and the version footer. Set
   document.documentElement.lang to the active language on
   boot and after switch (prevents Chrome offering to
   translate the already-Spanish app; aids screen readers).
7. STR_ES.js is spliced INTO index.html's STR object as the
   es: {...} member, then the loose STR_ES.js file is DELETED
   from the repo in the same commit — index.html stays the
   single source of truth.

## Claude Code tasks (one commit, v0.37.0)

### Task 1 — Splice + months_short
Insert the es object from STR_ES.js into STR alongside en.
Add months_short to en per decision 3. Switch the scorer's
month-abbreviation source to t('months_short').split(',').
Delete STR_ES.js. Verify t() resolves es keys when LANG='es'.

### Task 2 — Language resolution + sacred key
Implement decision 1. LANG becomes a resolved variable, not a
constant. ja_lang added to the sacred-keys list with read-back
verify on write (snapshot -> mutate -> verify pattern).

### Task 3 — The two switch surfaces
Settings row + splash link per decision 5, both calling one
setLang(lang) implementing decision 2.

### Task 4 — Logic guard
Decision 4's grep + verification. Also verify no OTHER logic
compares against any t() output (search for t( inside if/===
comparisons and clear each as presentation-only).

### Task 5 — translate=no + document lang
Decision 6.

### Task 6 — Version, docs, self-verify
Fan-out: footer v0.37.0 + sw.js CACHE appleseed-v0-37-0.
CLAUDE_CONTEXT.md: ja_lang sacred, language system landmarks,
splash link, roadmap (Phase 3 = Spanish plant search akas +
safety-text review).
Post-deploy self-verify (rule 11, four probes):
1. index.html: v0.37.0 + STR.es present + en/es key counts
   EXACTLY EQUAL (report both numbers) + ja_lang + setLang +
   splash language link + translate="no" on sci elements +
   zero STR_ES.js file in repo
2. sw.js cache = appleseed-v0-37-0
3. GET https://uavtaznzdpmfvkdpqyrv.supabase.co/rest/v1/profiles?select=display_name&limit=1
   with apikey + Bearer (key from index.html, ref exactly as
   in file) -> 200; network unavailable = NOT RUN, never pass
4. Same host: /rest/v1/plants?select=lat,lng&limit=5 -> 200,
   all <= 3 decimals
No data mutation. Report table, stop.

## Acceptance (Jason)
- Settings -> Language/Idioma -> app reloads in Spanish: tabs,
  plant form, score preview, toasts, popups all Spanish
- Score a plant in es: reason sentence reads naturally, months
  show ene/feb/... style
- Refresh: Spanish persists. Toggle back: English persists.
- Splash shows "Español" link in en (and "English" in es);
  tapping switches
- Set phone/browser language to Spanish, clear site data,
  open fresh: app auto-opens in Spanish
- Scientific names and the wordmark stay untranslated in both
- Setup sheet still fires only once (Planter-gate logic intact)
