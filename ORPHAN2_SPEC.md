# ORPHAN2 SPEC — A Real Question Deserves Both Answers (v0.43.1)

Execution contract. Sonnet default. All decisions final.
Acceptance finding (Jason): one-tap adoption is too abrupt —
consequential, irreversible, mis-tappable. And "Still there?"
is a genuine question whose NO answer is valuable data: dead
or removed plants should be reportable so the map stays
truthful. One sheet fixes both.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. The orphan popup button now reads t('orphan_chip')
   ("Still there?" / "¿Sigue ahí?") and opens
   openOrphanSheet(plantId) instead of adopting directly.
   The chip stays as-is. The old direct-tap adoption path is
   removed; adoptPlant(id) itself is unchanged and is now
   called only from the sheet's Yes.
2. The sheet (reuse the v0.42 dialog infrastructure —
   showActionSheet builder, focus trap, Escape=cancel):
   - Title: t('orphan_chip')
   - Body: t('orphan_sheet_body')
   - Primary: t('orphan_adopt_yes') -> adoptPlant(id)
     (existing toast_adopted on success)
   - Secondary: t('orphan_gone_no') -> ensureAuth() ->
     sb.from('reports').insert({ target_type: 'plant',
     target_id: id, reason: 'orphan-gone' }) -> toast
     t('orphan_gone_thanks'). The pin stays on the map —
     removal is a moderation decision via the dashboard
     reports queue (write-only reports rail, by design).
   - Cancel: existing cancel styling/key. Escape = cancel.
3. NEW i18n keys (BOTH languages; parity must hold — expect
   +4 per dictionary):
   orphan_sheet_body en:"If it's still growing, you can adopt
   it and become its steward — it joins your garden. If it's
   gone, let us know and we'll tidy the map." es:"Si sigue
   creciendo, puedes adoptarla y convertirte en su cuidador —
   se une a tu jardín. Si ya no está, avísanos y limpiamos el
   mapa."
   orphan_adopt_yes en:"Yes — I'll tend it" es:"Sí — yo la
   cuido"
   orphan_gone_no en:"No — it's gone" es:"No — ya no está"
   orphan_gone_thanks en:"Thanks — we'll check on it."
   es:"Gracias — lo revisaremos."
4. Moderation note for CLAUDE_CONTEXT: reports with reason
   'orphan-gone' are the stale-pin cleanup queue — judge in
   the dashboard, delete the plant row if confirmed gone
   (service role; no client delete path for orphans exists,
   correctly).

## Claude Code tasks (one commit, v0.43.1)

### Task 1 — openOrphanSheet + rewired popup button
(decisions 1-2)
### Task 2 — i18n keys (decision 3)
### Task 3 — Version, docs, self-verify
Fan-out: footer v0.43.1 + sw.js CACHE appleseed-v0-43-1.
CLAUDE_CONTEXT.md: decisions above, moderation note, roadmap.
Post-deploy self-verify (rule 11, four probes):
1. index.html: v0.43.1 + openOrphanSheet present + direct
   adoptPlant call REMOVED from the popup HTML (button calls
   openOrphanSheet) + orphan_adopt_yes in BOTH dicts + en/es
   parity EQUAL (report counts)
2. sw.js cache = appleseed-v0-43-1
3. GET https://uavtaznzdpmfvkdpqyrv.supabase.co/rest/v1/profiles?select=display_name&limit=1
   with apikey + Bearer (key from index.html, ref exactly as
   in file) -> 200; network unavailable = NOT RUN, never pass
4. Same host: /rest/v1/plants?select=lat,lng&limit=5 -> 200,
   all <= 3 decimals
No data mutation. Report table, stop.

## Acceptance (Jason — needs a fresh orphan: throwaway logs
ONE public plant, deletes with override OFF)
- Tap the dashed pin's "Still there?" button: the sheet opens,
  Tab cycles inside it, Escape cancels
- Tap "No — it's gone": thank-you toast; pin STAYS dashed;
  Supabase dashboard -> reports shows a row with reason
  orphan-gone
- Reopen the sheet, tap "Yes — I'll tend it": adoption toast,
  circle turns solid, byline is you
- Español: sheet renders "¿Sigue ahí?" / "Sí — yo la cuido" /
  "No — ya no está"
