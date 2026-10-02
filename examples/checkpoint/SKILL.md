---
name: checkpoint
description: Session checkpoint - append session activity as log bullets to the correct time block in the correct daily note, using file modification timestamps to route work to when it was actually done. Logs only; does NOT commit. Use when the user asks to checkpoint or log the session so far without committing.
allowed-tools: Bash, Read, Edit
---

Session checkpoint for the vault's daily notes.

Work is often committed a day after it was done, and sessions often span several days. Route each changed file to its daily note and time block by **file modification time (mtime)**, not by commit time or the current clock.

**This skill doesn't commit.** It only writes to daily notes (activity log and TODO check-offs). To commit, run `/commit`, or `/wrap`, which does checkpoint plus a single commit in one pass.

**Steps:**

1. TODAY = `date +%Y-%m-%d`; HOUR = `date +%H`.
2. **Current-session block** (the fallback for session work with no pending file change): HOUR < 12 -> `## Morning`; 12-16 -> `## Afternoon`; >= 17 -> `## Evening`. Call it SESSION_BLOCK.

3. **Capture file timestamps for routing.** Run:
   ```
   git -C ~/vault status --short
   ```
   Stat each modified or untracked file under `wiki/` (excluding daily notes) right away:
   ```
   stat -f "%Sm" -t "%Y-%m-%d %H" "~/vault/FILE"
   ```
   The output is `YYYY-MM-DD HH`. Record FILE -> (DATE, BLOCK), deriving BLOCK from HH with the same cut-offs as step 2. Git doesn't touch mtimes on commit, so this routing stays valid however late the commit comes.

   If the working tree is clean, skip to step 4.

4. **Add current-session work** that no pending file change reflects (from the conversation), assigned to (TODAY, SESSION_BLOCK).

5. **Check off completed TODOs.** From the conversation, find items in TODAY's `# TODO` section (including sub-sections such as `## TODO: Job search`) that this session's work actually resolved. For each one you can confirm:
   a. Remove the item, with its sub-bullets and any `(×N)` carry marker, from `# TODO`.
   b. Add it to the relevant time BLOCK of TODAY's note as `- [x] <task> (~time)`.
   c. If the resolution isn't obvious from the TODO's own wording, add an indented sub-bullet recording how it was resolved (the decision or outcome, with a wikilink if relevant). Skip it when the checked box tells the whole story.

   When in doubt whether a TODO is fully resolved, leave it. Only check off TODOs in TODAY's note, never a prior day's.

6. **Group all work items by (DATE, BLOCK)** and summarize each group as concise bullets: one line per distinct task, not per file.

7. **For each (DATE, BLOCK) group**, oldest date first:
   a. Read `~/vault/Daily Notes/DATE.md` in full. If it doesn't exist, skip.
   b. Collect every existing `### wiki activity` bullet from **all blocks** in that note: the per-date dedup list.
   c. Build the new bullets, skipping anything on the dedup list (match on substance, not exact wording).
   d. If any remain, append them under `### wiki activity` inside BLOCK, inserting that subsection first if it doesn't exist.

8. Print one line per modified daily note, `Logged N items to DATE.md > BLOCK > ### wiki activity`, and one per checked-off TODO, `Checked off TODO in DATE.md > BLOCK: <task>`. If nothing was new anywhere, say so and exit.

**Rules:**
- **Never commit.** Committing is a separate, explicit step (`/commit` or `/wrap`).
- Append session activity only inside `### wiki activity` subsections; don't modify other block content or anything you didn't add.
- The only permitted `# TODO` change is checking off a completed TODO per step 5. Make no other edits to `# TODO`.
- Don't create daily notes that don't already exist.
- Don't touch daily notes for dates with no new file changes, session work, or resolved TODOs.
