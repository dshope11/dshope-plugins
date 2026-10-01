---
name: audit-claude-md
description: Audit a CLAUDE.md - remove bloat, duplicates, contradictions, and rules made obsolete by model improvements. Use when the user asks to audit, trim, or clean up a CLAUDE.md.
allowed-tools: Read, Edit
---

Audit the `CLAUDE.md` in the current working directory and propose a trimmed version.

**Steps:**

1. Find and read `CLAUDE.md` in the current working directory. If none exists, report that and stop.
2. Analyze the file for:
   - **Bloat** - verbose explanations of things the model already knows without being told
   - **Duplicates** - rules or instructions that say the same thing in two places
   - **Contradictions** - instructions that conflict with each other
   - **Obsolete rules** - constraints that existed to work around older model limitations but are likely unnecessary now (e.g. "always explain your reasoning step by step", overly specific formatting mandates, reminders about basic task hygiene)
   - **Over-engineering** - rules added defensively for hypothetical edge cases that haven't actually caused problems
3. For each proposed removal or consolidation, note:
   - What you'd remove/merge
   - Why (which of the above categories)
   - Risk: could removing this cause a real regression, or is it safe to drop?
4. Present the full list of proposed changes to the user **before editing anything**. Format as:

   ```
   REMOVE - [section/line]: <reason>
   MERGE - [section A] + [section B] -> [proposed merged text]: <reason>
   KEEP - [anything you considered but decided to keep, and why]
   ```

5. Ask: "Apply these changes? [yes / no / pick and choose]"
6. Only after confirmation: apply the approved edits. Prefer `Edit` over full rewrite - make targeted removals and consolidations so the diff is reviewable.
7. Report the before/after line count.

**Rules:**
- Never remove project-specific facts, structure definitions, file paths, or domain conventions - only remove generic instructions the model doesn't need to be told.
- When in doubt about a rule, keep it and flag it as "low-confidence remove" so the user can decide.
- Do not rewrite or rephrase content that isn't being removed - only cut and consolidate.
