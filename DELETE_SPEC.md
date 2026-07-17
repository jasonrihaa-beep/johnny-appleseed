# DELETE SPEC — The Right to Leave (v0.41.0)

Execution contract. Sonnet default. All decisions final.
Account deletion: store requirement, GDPR/CCPA erasure answer,
and basic dignity. Server side: the delete-account Edge
Function (deployed via dashboard) sweeps storage then deletes
the auth user, which cascades every table (verified against
both schema files). This build is the CLIENT side only.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. Settings gains a "Delete account" row, danger-styled
   (var(--red-400) text), positioned BELOW "Clear my data".
   Visible ONLY for durable (non-anonymous) sessions —
   anonymous users have "Clear my data" as their erasure path
   already, and the function requires auth anyway.
2. Two-step confirm, no single-tap destruction: tapping the
   row opens a confirm sheet (reuse action-sheet component)
   stating exactly what happens — account, plants, photos,
   comments, follows, notifications: everything, permanently,
   unrecoverable. The confirm button carries a 3-second
   disabled countdown before it becomes tappable (prevents
   reflex taps). Cancel is the prominent default.
3. The call: POST to
   {SUPABASE_URL}/functions/v1/delete-account with headers
   Authorization: Bearer {session access token} and apikey:
   {anon key}. On {deleted:true}: clear ALL ja_* keys and the
   sb-* session locally, toast the goodbye, and reload to the
   splash as a fresh visitor. On error: persistent dismissible
   error dialog with the raw message (auth-error pattern),
   account untouched.
4. NEW i18n keys (BOTH languages, parity must hold):
   settings_delete_account en:"Delete account" es:"Eliminar
   cuenta"; delete_confirm_title en:"Delete your account?"
   es:"¿Eliminar tu cuenta?"; delete_confirm_body en:"This
   permanently erases your account, plants, photos, comments,
   and follows. There is no undo and no recovery."
   es:"Esto borra permanentemente tu cuenta, plantas, fotos,
   comentarios y seguidores. No hay deshacer ni
   recuperación."; delete_confirm_btn en:"Delete everything"
   es:"Eliminar todo"; delete_cancel en:"Keep my garden"
   es:"Conservar mi jardín"; delete_done en:"Account deleted.
   Thank you for planting." es:"Cuenta eliminada. Gracias por
   plantar."; delete_failed en:"Could not delete account"
   es:"No se pudo eliminar la cuenta".
5. Sacred-key note: this flow is the ONE sanctioned mass-clear
   of ja_* and sb-* keys — it runs only after the server
   confirms {deleted:true}. Document in CLAUDE_CONTEXT.

## Claude Code tasks (one commit, v0.41.0)

### Task 1 — Settings row + visibility (decision 1)
### Task 2 — Confirm sheet with countdown (decision 2) +
i18n keys (decision 4)
### Task 3 — The call + success/error paths (decision 3)
### Task 4 — Version, docs, self-verify
Fan-out: footer v0.41.0 + sw.js CACHE appleseed-v0-41-0.
CLAUDE_CONTEXT.md: Edge Function landmark (delete-account,
dashboard-deployed), the sanctioned mass-clear note, roadmap.
Post-deploy self-verify (rule 11, four probes):
1. index.html: v0.41.0 + settings_delete_account key in BOTH
   dictionaries (report en/es counts, must be equal) +
   functions/v1/delete-account URL present + countdown logic
   present
2. sw.js cache = appleseed-v0-41-0
3. OPTIONS https://uavtaznzdpmfvkdpqyrv.supabase.co/functions/v1/delete-account
   -> expect 200/204 (function deployed and reachable). If it
   404s, report "Edge Function not deployed — Box A pending"
   and mark FAIL. Never invent a URL; read the project ref
   from index.html.
4. GET same host /rest/v1/plants?select=lat,lng&limit=5 with
   apikey + Bearer -> 200, all <= 3 decimals
No data mutation. Report table, stop.

## Acceptance (Jason)
- Signed in with Google: Delete account row visible, red,
  below Clear my data; anonymous session: row absent
- Tap it: confirm sheet, countdown ticks 3-2-1 before the
  delete button arms; Cancel works
- ON A THROWAWAY TEST ACCOUNT ONLY (incognito, fresh Google
  or email): confirm deletion -> goodbye toast -> splash as a
  stranger; Supabase Table Editor shows the test user's rows
  gone from profiles AND plants; Authentication > Users shows
  the user gone; Storage shows their photo folder gone
- Both languages render the new copy
