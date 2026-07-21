# ORPHAN SPEC — Still There? (v0.43.0)

Execution contract. Sonnet default. All decisions final.
Account deletion now RETAINS access='public' plantings as
anonymized orphans (user_id null, note/photo scrubbed) unless
the user opts out. Orphans render as dashed open-harvest
circles inviting adoption: any signed-in user can claim one,
which restores it to normal life under their stewardship.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. Orphan state IS user_id null. No enum, no extra table.
   Adoption = UPDATE setting user_id to the claimant +
   confirmed_at = now (RLS policy plants_adopt_orphan permits
   exactly this). Adopted pins re-enter the normal lifecycle;
   if the adopter leaves, the pin orphans again.
2. TRIPWIRE 17 — NARROW SCOPED EXCEPTION for this build only:
   addHazeCircle may add, for plants where user_id is null AND
   access='public': dashArray '6 6' on the circle stroke and
   fillOpacity reduced to 0.15 (from the public 0.25). NOTHING
   else in the map renderer changes — radius, colors, tiers
   for owned pins, dot logic, pick mode all frozen. Exception
   is consumed by this build; map re-freezes after.
3. Orphan popups: byline shows t('profile_default_name')
   ("Planter"/"Jardinero"), a chip t('orphan_chip'), and a
   button t('orphan_confirm') that runs adoptPlant(id):
   ensureAuth() -> sb.from('plants').update({ user_id:
   session.user.id, confirmed_at: new Date().toISOString() })
   .eq('id', id).is('user_id', null) -> on success toast
   t('toast_adopted') + reload pins/feed; on error toast the
   message. The .is('user_id', null) guard makes double-
   adoption a clean no-op race (second tap errors/0 rows).
4. Orphan feed cards: byline falls back the same way; NO
   follow button (no user), overflow sheet shows Report only
   (no Block — nobody to block). Comment thread stays live
   (the plant is still community property).
5. Delete-confirm sheet v2 (truth update): body becomes
   t('delete_confirm_body') NEW TEXT (below); add a secondary
   toggle row t('delete_override_label') default OFF; when ON,
   doDeleteAccount() POSTs body {"retainPublic": false},
   otherwise {"retainPublic": true}. Countdown + danger
   button + cancel unchanged.
6. NEW i18n keys (BOTH languages, parity holds):
   delete_confirm_body en:"Your account, name, photos, notes,
   comments, and private plantings are permanently erased.
   Open-harvest plantings stay on the map without your name,
   waiting for a neighbor to tend them." es:"Tu cuenta,
   nombre, fotos, notas, comentarios y plantaciones privadas
   se borran permanentemente. Las plantaciones de cosecha
   abierta quedan en el mapa sin tu nombre, esperando a que
   un vecino las cuide."
   delete_override_label en:"Also remove my open-harvest
   plantings" es:"Eliminar también mis plantaciones de
   cosecha abierta"
   orphan_chip en:"Still there?" es:"¿Sigue ahí?"
   orphan_confirm en:"It's still here" es:"Aquí sigue"
   toast_adopted en:"It's yours to tend now." es:"Ahora te
   toca cuidarla."
7. DEFERRED, documented: photo/note attach at adoption moment
   (no edit-existing-plant path exists yet); orphan auto-fade
   after long unconfirmed periods (future decision).
8. Renderer hardening: every byline/avatar render site must
   null-check user_id (orphans have no profile row). Grep the
   profile-join patterns and handle null cleanly everywhere.

## Claude Code tasks (one commit, v0.43.0)

### Task 1 — Orphan rendering: map (decision 2-3) + feed
(decision 4) + null hardening (decision 8)
### Task 2 — adoptPlant() (decision 3)
### Task 3 — Delete-confirm sheet v2 + override wiring
(decision 5) + i18n keys (decision 6)
### Task 4 — Version, docs
Fan-out: footer v0.43.0 + sw.js CACHE appleseed-v0-43-0.
CLAUDE_CONTEXT.md: orphan/adoption decisions, tripwire-17
exception consumed + re-freeze, deferred list, roadmap.
### Task 5 — Post-deploy self-verify (rule 11, four probes)
1. index.html: v0.43.0 + dashArray marker + adoptPlant +
   delete_override_label + orphan_chip in BOTH dicts + en/es
   parity EQUAL (report counts) + retainPublic in the POST
   body
2. sw.js cache = appleseed-v0-43-0
3. GET https://uavtaznzdpmfvkdpqyrv.supabase.co/rest/v1/plants?select=id&user_id=is.null&limit=1
   with apikey + Bearer (key from index.html, ref exactly as
   in file) -> 200 (empty array = pass; no orphans exist yet).
   Network unavailable = NOT RUN, never pass.
4. Same host: /rest/v1/plants?select=lat,lng&limit=5 -> 200,
   all <= 3 decimals
No data mutation. Report table, stop.

## Acceptance (Jason — two throwaways, in this order)
- Throwaway A (incognito): log ONE public-access plant and ONE
  private plant -> Settings -> Delete account, override OFF ->
  confirm. Then as yourself: private pin GONE; public pin
  remains as a DASHED dimmer circle, byline "Planter", chip
  "Still there?", note/photo absent
- Adopt it from your main account: tap "It's still here" ->
  toast -> circle turns solid, byline is you
- Throwaway B: log one public plant -> Delete with override ON
  -> everything gone including the public pin
- Español: chip reads "¿Sigue ahí?", button "Aquí sigue"
- Supabase spot-check: throwaway users gone from
  Authentication > Users; orphaned row shows user_id null +
  note null + photo_url null before adoption
