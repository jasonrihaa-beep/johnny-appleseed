# S4a SPEC — Identity (v0.5.0)

Execution contract. Sonnet default. All decisions final.
Fixes: every user is "Planter" with no way to change it.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. display_name is a NAME, not a handle — no uniqueness, no
   reservation. Collisions are fine. 40-char cap enforced by DB.
2. Avatar stays a palette color (5 brand colors) — image upload
   waits for the S2.5 storage bucket.
3. The email upgrade lives HERE, not later: the moment a user
   names their garden is the moment it becomes worth keeping.
   `sb.auth.updateUser({ email })` on an anonymous session sends
   a verification link; verified = same auth.uid(), account now
   permanent, plants kept.
4. Profanity filtering on names: still deferred, still a
   documented gap. Reports table (S4c) is the interim backstop.

## Prerequisite (Jason, one paste)

Run `schema_s4.sql` in Supabase SQL Editor → expect
"Success. No rows returned" (43 statements). Tables sit idle
until wired; running it now saves four future migrations.

## Claude Code tasks (one commit)

### Task 1 — Profile editing UI
- Profile tab: display name becomes tappable → inline edit
  (input, 40 max, Save/Cancel). Save → `sb.from('profiles')
  .update({ display_name }).eq('id', user.id)` → optimistic UI
  + toast on error. Trim; reject empty.
- Avatar: tapping the avatar circle cycles the 5-color brand
  palette; persists to `avatar_color` on selection.
- On app load with a session: fetch own profile once, render
  real name + color in Profile hero. No session → show
  "Planter" + prompt to log a first plant (identity begins at
  first action, keep it that way).

### Task 2 — Keep-your-garden email upgrade
- Profile → Settings: new row "Add email to keep your garden"
  (replaces nothing; sits above AI key row).
- Tap → inline email input → `sb.auth.updateUser({ email })`
  → toast: "Check your inbox to confirm." On confirmed sessions
  (user.email present and user.is_anonymous false), row shows
  the email, disabled state "Garden protected".
- Error surface: duplicate email → toast the Supabase message.
- NEVER auto-prompt on load. The nudge appears once as a toast
  after a user's 3rd successful plant log (count via localStorage
  `ja_log_count` — add key to sacred list).

### Task 3 — Version + docs
- Fan-out: footer v0.5.0 + sw.js CACHE appleseed-v0-5-0.
- CLAUDE_CONTEXT.md: add `ja_log_count`, S4a decisions, roadmap.
- All three validation checks. Push.

## Acceptance (Jason, live URL)
- Rename Planter → Jason in-app → feed card shows Jason
- Cycle avatar color → persists after hard refresh
- Add email → verification arrives → Settings shows protected
- Incognito: your profile name renders on your pins (public read)

## Explicitly NOT in S4a
Follows, real inspires, comments, reports UI, notifications
panel — those are S4b–S4d, one scoped session each, in order.
