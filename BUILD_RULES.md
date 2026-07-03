# BUILD_RULES — Johnny Appleseed

Ten rules. Committed to the repo. Every Claude Code session follows all ten.

1. **Read CLAUDE_CONTEXT.md first.** Before any grep, any edit, any plan.

2. **Plan before edit.** State what will change and which files it touches.
   Wait for approval on anything structural.

3. **Grep anchors immediately before editing.** Line numbers drift. Never
   edit from memory of a previous view.

4. **Scope discipline.** Edit exactly what was identified — never file-wide
   automated sweeps (emoji strips, token replaces, formatters). Over-extension
   wastes tokens and ships regressions.

5. **Non-destructive.** Never delete, rename, or refactor existing IDs,
   classes, functions, or features unless explicitly instructed.

6. **Validate after every edit.** CSS brace count, HTML tag balance,
   `node --check` on inline JS. All three pass or the work is not done.
   Do not declare victory early.

7. **Version fan-out on every ship.** Footer + sw.js cache name move in
   lockstep. A shipped edit without a cache bump is a bug delivery system.

8. **No emojis, ever, anywhere in the UI.** Inline stroke SVG icons only
   (1.6–1.8 stroke, currentColor, 14–22px).

9. **Honest states only.** No fake scores, no placeholder data presented as
   real, no dead buttons implying features that don't exist. Unknown means
   the UI says unknown. If it can't be computed truthfully, don't render it.

10. **localStorage keys are sacred** once created (`ja_` prefix). Never
    rename without a migration. Never ship anything that could lose a
    user's data. Snapshot → mutate → verify read-back.

11. **Task 4 self-verify — post-deploy verification on every ship.**
    After pushing, poll the live URL until the new footer version
    appears (up to 3 min). Then verify and report a pass/fail table:
    (1) live index.html carries the new version and this build's UI
    markers; (2) live sw.js cache name matches the fan-out; (3) a
    read-only Supabase REST probe (URL + anon key read from the live
    page's config constants) returns 200 JSON. Never mutate data
    during verification.

---

## Session-end definition of done

- All validation checks pass
- Changed files listed explicitly
- Version bumped if shipping
- CLAUDE_CONTEXT.md updated if architecture changed (new key, new tripwire,
  new fan-out location) — not for routine content edits
