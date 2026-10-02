---
name: handoff
description: Session handoff - generate a self-contained resume prompt so a new Claude session can pick up exactly where we left off. Use when the user says "handoff", "next session prompt", "resume prompt", or "wrap up session".
allowed-tools: Bash, Read
---

Generate a session handoff prompt for the vault.

**Arguments:** `$ARGUMENTS`

- `--priorities` -> do a priority investigation (step 5).
- Any other text -> treat it as the "what's next" context (don't ask).
- No arguments -> infer what you can, then ask for "what's next".

---

**Steps:**

1. **Get the date and gather source material in parallel:**
   - `date +%Y-%m-%d` -> TODAY
   - `git -C ~/vault log --since=midnight --oneline --no-merges` -> recent commits
   - Read `~/vault/Daily Notes/TODAY.md` -> today's activity

2. **Infer what was done this session.** Combine the daily note's time-block bullets and `### wiki activity` entries with the git log, in 3-6 concise bullets. Focus on what was *created or changed*, not process steps.

3. **Identify active workflow conventions.** From the conversation, extract non-obvious workflow patterns in use this session that a new session wouldn't know from the wiki or `CLAUDE.md`. For example: "after each video ingest, run an interview Q&A discussion and save the Q&As to interview-prep.md". Skip conventions already documented in `CLAUDE.md`.

4. **Determine "what's next".**
   - Non-flag argument text -> use it directly.
   - No arguments -> print the inferred summary so far, ask *"What's the next task?"*, and wait for the answer.
   - Keep it to one sentence or a short phrase.

5. **Priority investigation (only with `--priorities`).** Read `~/vault/wiki/topics/ml-learning-roadmap.md`, `~/vault/wiki/topics/job-search.md`, and today's `# TODO` section. From what was done today and the stated priorities, suggest 2-3 concrete next tasks ranked by urgency and importance, and ask which to use as "what's next".

6. **Identify pages to pre-read.** From "what's next", pick 1-3 wiki pages a new session should read before starting; prefer specific pages over broad ones. **List them as paths only; the handoff tells the receiving session not to open them until the go-ahead** (step 7). **Write every path in absolute `~/`-prefixed form** (`~/vault/wiki/topics/foo.md`): a handoff is often pasted into a session running in a different repo, where a bare `wiki/...` path doesn't resolve.

7. **Emit the handoff prompt** as a single markdown blockquote (`>` on every line) that the user can paste into a new session. It must be fully self-contained: no assumed context, no "as we discussed".

   **It always opens with the hold instruction** (the `**Do not start yet.**` line below): acknowledge in one line, then take no action - no file reads, no tool calls, no pre-reading - until the user says go. A handoff is often pasted long before the work starts; pre-reading on arrival loads context that is stale by then, after the prompt cache has expired. Reading at go time costs the same tokens and gets current content.

---

**Output format:**

```
> **Session handoff - YYYY-MM-DD**
>
> **Do not start yet.** Acknowledge this in one line and then wait. Take no
> action until I say go - no file reads, no tool calls, not even the pre-read
> below. I often paste a handoff well before I actually begin the work.
>
> **What was done:**
> - bullet
> - bullet
>
> **Active workflow:**
> - bullet (only include if non-obvious conventions were in use)
>
> **What's next:** [one sentence]
>
> **Pre-read before starting:**
> - `~/vault/wiki/path/to/page.md` - why it's relevant
```

Omit the `**Active workflow:**` block if there are no non-obvious conventions worth flagging. Never omit the `**Do not start yet.**` block. Keep the whole prompt under about 250 words, paste-ready without editing.
