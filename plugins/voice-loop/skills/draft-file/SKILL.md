---
name: draft-file
description: Write text drafted in the conversation to a clean .txt file and open it in an editor. Use when a draft the user will paste or send (an email, a message, an application answer) is ready to leave the chat. Voice artifacts go to ~/.claude/drafts with a pristine snapshot for /log-edit; scratch goes to /tmp. Paste-able output is ASCII with single-line paragraphs.
allowed-tools: Bash, Write
---

Export a piece of text drafted together in the current conversation into a clean, directly copy-pasteable `.txt` file and open it in the user's editor. This solves the problem of copying out of the terminal, which introduces unwanted line breaks and whitespace.

**Input:** `$ARGUMENTS` may name which drafted text to export and/or a destination path. If empty, default to the most recent substantial piece of text drafted together in this conversation (e.g. an email, message, cover letter, LinkedIn blurb, or code/text snippet).

**Steps:**

1. Identify the target text:
   - If `$ARGUMENTS` names what to export (e.g. "the recruiter email", "the cover letter intro"), use that.
   - Otherwise, use the most recently drafted standalone text block from the conversation.
   - If it is genuinely ambiguous which text is meant, ask once before writing.

1b. **Check the text against the edit log first** - for voice artifacts only (the step 5 test), and **before writing the file**. See *Retrieval before export* below. If the draft repeats something the user has previously revised away, fix it now and say so in one line when reporting. **Fixing a known-revised phrasing is not "altering the wording" in the sense of the rule below** - it is applying the user's own prior correction rather than Claude's judgment.

2. Determine the output path. **Two defaults, decided by whether the text is a voice artifact** (see step 5 for the test):
   - **Prose the user will send in their own voice -> `~/.claude/drafts/YYYY-MM-DD-<slug>.txt`.** Durable, because these get edited over hours or days and `/tmp` can be cleared at reboot - which would destroy the user's revision, the one half of the pair that cannot be regenerated.
   - **Everything else (code, config, data, scratch) -> `/tmp`.** Genuinely throwaway; nothing is lost if it disappears.
   - Filename: a short kebab-case slug derived from the content, date-prefixed in `~/.claude/drafts` (e.g. `2026-09-11-recruiter-email.txt`), bare in `/tmp` (e.g. `cover-letter-intro.txt`).
   - If `$ARGUMENTS` gives a path or filename, honor it. If the directory is neither default, confirm the parent directory exists first.

3. Write the text VERBATIM as drafted - this is export-only, not an editing pass. Format for clean pasting:
   - **ASCII characters only** - no smart/curly quotes, em or en dashes, or other non-keyboard Unicode. Convert any that slipped in (`-` for dashes, `'`/`"` straight quotes).
   - **Each paragraph on a SINGLE line** (no hard line-wrapping inside a paragraph), with a blank line between paragraphs. This is what prevents the unwanted-whitespace problem on paste.
   - **No leading indentation** on any paste-ready line - keep answers flush to the left margin so a triple-click selects the whole answer cleanly and nothing extra rides along into the form field.
   - Include relevant surrounding metadata only if it is part of the draft (e.g. `To:` / `Subject:` lines for an email). Nothing else - no commentary, no markdown fences.

4. **Snapshot the pristine draft** (see *Edit-log capture* below) - required whenever step 5 applies:

   ```bash
   mkdir -p ~/.claude/drafts/logged ~/.claude/draft-snapshots/logged
   cp ~/.claude/drafts/<name>.txt ~/.claude/draft-snapshots/<name>.txt
   ```

   **Identical basename in both directories** - that is what pairs them, and it makes the diff a one-liner. This is the "before" side; the user edits the working file in place, so without the snapshot the original is gone.

   **Snapshot BEFORE appending the footer**, so the snapshot holds only the message text.

5. **Append the edit-log footer** (template below) - for prose the user will send or publish **in their own voice**: emails, recruiter and InMail replies, founder and warm-contact messages, LinkedIn text, cover-letter prose, application free-text. **Skip the footer** for code, config, data, command output, and scratch snippets - those are not voice artifacts and their diffs teach nothing.

6. Open the file with the `editor-open` command in the "Claude Code paths" section of the user's CLAUDE.md: `<editor-open> <path>`. If that key is missing, use the OS opener (`open` on macOS, `xdg-open` on Linux). (For VS Code on macOS, prefer `open -a "Visual Studio Code"` over the `code` CLI - `open -a` goes through Launch Services and reliably focuses the document, whereas `code <file>` can open it behind the current window.)

7. Print a one-line confirmation with the full path: `Wrote <path> and opened it`. If a footer was added, add a second line naming the snapshot path and reminding the user that `/log-edit <path>` captures the diff once they have revised it.

---

## Retrieval before export

**The log is only worth keeping if it is read before writing, not just appended to after.** This step makes past revisions operative without encoding any of them as a rule in `CLAUDE.md` - which is the point: a pattern seen twice in one batch is not yet a rule, but it is already evidence, and evidence is usable the moment it is retrievable.

**The log lives at the `draft-edit-log` path in the "Claude Code paths" section of the user's CLAUDE.md** (default `~/.claude/draft-edit-log.md`). **The lookup is cheap and must stay cheap as the log grows.** Every entry's heading carries its own index:

```bash
grep -n "^## \[" <draft-edit-log>
```

Each line reads `## [date] <slug> | <genre> -> <audience>`. From that listing:

- **Read the entries matching this draft's genre first**, then those matching the audience. Use `sed -n '<start>,<end>p'` on the line ranges to pull just those entries.
- **Read only the `### Edits` and `### Why, in their words` sections.** The verbatim `### Drafted` / `### Sent` blocks are the bulk of the file and exist for the corpus, not for drafting guidance - skip them unless a specific edit is unclear without its context.
- **If nothing matches on genre or audience, read the three most recent entries anyway.** Several patterns are cross-genre - hedging claims about a third party's process, say, or reframing a self-indictment into a neutral statement.
- **If the log has no entries yet, skip silently.** Do not mention having looked.

**If the log has a "Promoted voice rules" section, it holds the long form of the rules that have already graduated to the user's CLAUDE.md** - reasoning, worked examples, scope edge cases. CLAUDE.md carries each one compressed to a few lines and is already loaded, so **do not read that section routinely**; read it only when a rule seems to be misfiring or an edge case is genuinely unclear.

**What to do with what you find:** if the draft repeats a phrasing the user has already revised away, change it before writing the file and note it in one line (*"applied two prior revisions from the edit log: X, Y"*). If it is a judgment call rather than a repeat, leave the text alone and raise it as a question instead - **prior revisions are evidence about the user's preferences, not license to rewrite their content.**

**Known limitation, stated so nobody mistakes this for full coverage:** `/draft-file` is an *export* command, so by the time it runs the drafting has already happened in conversation. This check is therefore a late pass - it catches what it can before the text reaches the user, but it cannot inform the original draft. **The only thing that reliably fires at drafting time is a pointer in the user's CLAUDE.md** telling Claude to consult this log before writing prose the user sends in their own voice. That is one line, it encodes no style claim, and it stays one line however large the log grows - but adding it is the user's call.

## Edit-log capture

Users revise nearly every draft before sending, and those revisions are the best available record of their voice and judgment. They are invisible unless the pre-revision text is preserved. The footer and the snapshot exist to make `/log-edit` possible; `/log-edit` appends the entry to the `draft-edit-log` file.

**The two directories are a pair, and the top level is a work queue:**

| Path | Holds |
|---|---|
| `~/.claude/drafts/<name>.txt` | the working file the user edits - **this is what gets opened in the editor** |
| `~/.claude/draft-snapshots/<name>.txt` | the pristine draft as Claude wrote it |
| `~/.claude/drafts/logged/`, `~/.claude/draft-snapshots/logged/` | pairs already captured into the log, moved there by `/log-edit` |

So **anything sitting at the top level of `~/.claude/drafts/` is a draft whose revision has not been captured yet.** Both halves survive a reboot, a session restart, and an arbitrarily long gap between drafting and sending.

**Footer template** - append below the draft, after a blank line:

```
################################################################################
# EDIT LOG - notes only, never part of the message. Revise the draft above in
# place, then fill in WHY and run /log-edit on this file. Delete this block if
# you would rather the edit not be logged.
################################################################################

GENRE:     <warm-contact email | recruiter reply | founder outreach | cover-letter prose | application free-text | LinkedIn | other>
AUDIENCE:  <senior ex-colleague | reference | recruiter | founder / hiring principal | stranger | ...>
SITUATION: <one line: what is being said, and what has already passed between them>
SNAPSHOT:  ~/.claude/draft-snapshots/<name>.txt

WHY I CHANGED IT:
-

ALMOST CHANGED BUT DIDN'T:
-
```

**Rules for the footer:**

- **Claude fills GENRE, AUDIENCE, SITUATION and SNAPSHOT at write time.** The user should never have to supply what Claude already knows. They fill only the two free-text fields, and even those are optional - a diff with no reason attached is still worth logging.
- **The footer goes at the very bottom, below every paste-able block**, so it can never ride along into a paste.
- **If the file holds several messages** (e.g. three variants of one note to different recipients), give `WHY I CHANGED IT` one bullet per message, each prefixed with the recipient's name in caps.
- `ALMOST CHANGED BUT DIDN'T` captures near-misses - phrasings the user considered cutting and kept. These never appear in a diff and are otherwise unrecoverable.

**Rules:**
- Never alter the wording of the drafted text. If it needs changes, that is a separate editing step done before this command.
- **Never write a voice artifact to `/tmp`.** It can be cleared at reboot (macOS does), and a lost revision is unrecoverable - it is the one half of the pair that cannot be regenerated.
- Overwrite an existing file at the same path without prompting. **Re-snapshot only if no snapshot exists for that name** - overwriting a snapshot with a later version destroys the "before" side of a diff that has not been captured yet.
