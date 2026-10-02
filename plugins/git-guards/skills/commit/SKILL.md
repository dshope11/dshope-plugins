---
name: commit
description: Stage all changes and commit them with a message generated from the actual diff. Use when the user asks to commit ("/commit", "commit this") or says yes to a commit offer. Takes repo-specific message rules from the repo's CLAUDE.md section "Commit messages" when one exists.
allowed-tools: Bash, Read
---

Stage all changes in the current repo and commit with a descriptive message.

**Steps:**

1. Run `git status --short` to see what's changed. If the working tree is clean, say so and exit.

   **Repo-specific rules:** if the repo root's `CLAUDE.md` has a `## Commit messages` section, read it now. Its message patterns replace the generic guidance in step 4, and any extra sanity checks it lists are added to step 2.

2. **Sanity-check untracked and modified files before staging anything.** For each file in the status output, flag it if any of the following are true:
   - Size > 1 MB: run `find . -name "<filename>" -size +1M` to confirm
   - **Untracked files only** (`??` in the status): path looks like a secret or credential, i.e. contains words like `secret`, `token`, `key`, `password`, `credential`, `.env`. A tracked file was vetted when it was first added, so a modification to it isn't flagged.
   - Path is in a directory that shouldn't be committed: `node_modules/`, `.venv/`, `venv/`, `__pycache__/`, `dist/`, `build/`

   If any flags fire, **stop and list the flagged files with a one-line reason each**, then ask: "Proceed with all files, skip the flagged ones, or abort?" Wait for a response before continuing.

   If nothing is flagged, proceed silently - no need to say "all clear."

3. Run `git diff HEAD` to read the actual diffs. For large diffs, focus on file names and summary to understand scope.

4. Derive a commit message:
   - Imperative mood, no period at the end
   - <= 72 characters on the first line
   - No generic fillers ("update files", "misc changes", "wip")
   - If multiple unrelated things changed, join with `; ` on one line or add a short body after a blank line
   - Match the tense and style of recent commits in this repo (`git log --oneline -5`)

5. Stage and commit. Stage every file from step 1 by name rather than `git add -A`; if the user chose to skip flagged files in step 2, leave those out.
   - One-line message with no quotes, backticks or `$`: `git add <files> && git commit -m "<message>"`
   - Anything else (a body, special characters): write the message to a temp file with the Write tool and run `git add <files> && git commit -F <file>`. Never build the message with an inline heredoc - the shell layer re-parses it and breaks on apostrophes and backticks.

6. Print a one-line confirmation: `Committed: <message> (<hash>)`

**Rules:**
- Never amend a previous commit - always create a new one
- Never use --no-verify
- The user invoked this command explicitly - no additional confirmation step needed
