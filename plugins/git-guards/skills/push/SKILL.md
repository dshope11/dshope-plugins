---
name: push
description: Push the current branch to its remote and print the commits being pushed, with no confirmation step. Use when the user asks to push.
allowed-tools: Bash
---

Push the current branch to its remote tracking branch. Invoking `/push` is the confirmation - don't ask again, on any branch, including `main`/`master`.

**Steps:**

1. Run `git status --short` and `git log @{u}..HEAD --oneline` (if there's no upstream yet, use `git log --oneline -20` and treat every listed commit as new):
   - Warn if the working tree has uncommitted changes, but don't block
   - If no commits are ahead of the remote, say so and exit

2. Print the commits about to be pushed, one per line (`<hash> <subject>`), under a header naming the target: `Pushing N commit(s) to origin/<branch>:`. Then push straight away.

3. Run `git push` (or `git push -u origin <branch>` if no upstream is set).

4. In your reply text (not only inside the Bash output, which the user sees collapsed), print a one-line confirmation followed by the pushed commits, one per line:
   ```
   Pushed <branch> -> origin/<branch> (<N> commit(s)):
   - <hash> <subject>
   ```

**Rules:**
- Never use --force or --force-with-lease unless the user explicitly asked for it
- Never push tags unless the user explicitly asked for it
