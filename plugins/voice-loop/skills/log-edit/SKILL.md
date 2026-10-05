---
name: log-edit
description: Capture how the user revised a draft - diff the pristine snapshot from /draft-file against the edited version, classify the changes, and append an entry to the draft-edit log. Use when the user says they edited or sent a filed draft, or asks to log an edit.
allowed-tools: Bash, Read, Write, Edit
---

Capture the difference between a draft Claude wrote and the version the user actually sent, and append it to the draft-edit log: the `draft-edit-log` path in the "Claude Code paths" section of the user's CLAUDE.md (default `~/.claude/draft-edit-log.md`; create it if missing).

**Why this exists:** users revise nearly every draft before sending. Those revisions are the only direct record of the user's voice and their judgment about what they are willing to say, and they evaporate the moment the file is overwritten. Voice rules in a CLAUDE.md - contractions, no thematic closing lines, spelling conventions - are typically learned this way, and without a capture step each one gets learned **twice** because nothing recorded the first instance. This log exists to make the second instance visible immediately, and to serve as retrieval material before drafting. Longer term it is a preference-pair corpus (drafted = rejected, sent = chosen).

**Input:** `$ARGUMENTS` may name the draft file (e.g. `~/.claude/drafts/2026-09-11-recruiter-email.txt`) or just its slug. If empty, take the most recently modified file at the **top level** of `~/.claude/drafts/` - that directory is the queue of drafts whose revisions have not been captured yet.

**The file pair:**

| Path | Holds |
|---|---|
| `~/.claude/drafts/<name>.txt` | the working file the user edited - the "after" side |
| `~/.claude/draft-snapshots/<name>.txt` | the pristine draft as Claude wrote it - the "before" side |
| `~/.claude/drafts/logged/`, `~/.claude/draft-snapshots/logged/` | pairs already captured, moved here by step 7 |

Identical basenames pair them, so the raw diff is `diff ~/.claude/draft-snapshots/<name>.txt ~/.claude/drafts/<name>.txt`.

---

## Steps

1. **Resolve the pair.**
   - Read the working file. Its footer carries a `SNAPSHOT:` line naming the "before" side; the matching basename in `~/.claude/draft-snapshots/` is the fallback if the line is missing.
   - If there is no snapshot, say so and stop. **Never reconstruct the draft from memory or from conversation scrollback** - a remembered draft is not evidence, and a wrong "before" side makes the entry worse than no entry.
   - Take the footer's `MODEL:` line for the entry's **Model** field. **If the footer has none, write `not recorded`** - never fill it in from the current session, which may be running a different model or effort than the one that wrote the draft.
   - **Ignore the footer block when diffing.** Everything from the `####` banner down is notes, and the snapshot never contained it; a raw diff will always show the whole footer as an addition. If the footer is the *only* difference, the draft has not been revised - report that and stop without writing an entry. **If it was also sent as drafted** (the user says so, or the step 2 send matches the draft), **retire the pair anyway (step 7)**: nothing is left to capture, and a pair left at the top level would read as a revision still waiting. If it hasn't been sent yet, leave it in the queue - the user may still revise it.

2. **Prefer the actually-sent text over the edited file, for email.** Users often make a final pass in the mail client, so the sent version is authoritative. Read it with the `sent-mail` entry in the "Claude Code paths" section of the user's CLAUDE.md. **If no `sent-mail` entry exists, skip this step** and use the edited file.

   If the `sent-mail` tool is himalaya:

   ```bash
   himalaya envelope list --folder "<sent folder>" --max-width 140
   himalaya message read --folder "<sent folder>" --preview <ID>
   ```

   **`--folder` is required on BOTH commands. IDs are folder-scoped**, and `message read` silently defaults to INBOX - so omitting it returns a completely unrelated message under the same number rather than an error. **If the message you get back is not obviously the one you drafted, this is why** - do not conclude the send is missing.

   If a matching send exists and differs from the edited `.txt`, use the sent text as the "after" side and note the extra delta as its own edits. If nothing has been sent yet, use the edited file and mark the entry `not yet sent`.

3. **Diff and itemize.** Produce one bullet per distinct change - not a line diff. Each carries a class:

   | Class | What it covers |
   |---|---|
   | `voice` | register, contractions, rhythm, word choice, punctuation - how it sounds |
   | `stance` | what the user is willing to concede, claim, or admit about themselves; how much deference or apology they will carry |
   | `substance` | facts, strategy, what is included or withheld, what is asked for |
   | `structure` | order, length, what got cut wholesale |

   `stance` is the class a style guide cannot hold and the one most worth getting right. When a change is ambiguous between classes, tag it with both rather than guessing.

4. **Take the user's reasons verbatim.** Copy the `WHY I CHANGED IT` and `ALMOST CHANGED BUT DIDN'T` fields from the footer **word for word into a blockquote**. Never paraphrase, tidy, or expand them - the user's own wording is the highest-value content in the entry. If a field is empty, write `(none given)` and move on; do not interrogate the user for one.

5. **Set the status.** Compare against the voice rules in the user's CLAUDE.md and against earlier entries in the log:
   - `new pattern` - nothing in the log or CLAUDE.md covers it
   - `Nth instance of <rule>` - name the rule
   - **If this is the second instance of a pattern not yet written down, say so explicitly in the report and offer to promote it to the voice rules in the user's CLAUDE.md.** That promotion is the point of the log; do not let it pass silently.

6. **Append the entry** to the draft-edit log, at the **end of the file** (append-only, forward chronological). Use the entry template below exactly - it is meant to stay machine-parseable.

7. **Retire the pair** once the entry is written - move both halves into their `logged/` subdirectories, keeping the basename:

   ```bash
   mv ~/.claude/drafts/<name>.txt           ~/.claude/drafts/logged/
   mv ~/.claude/draft-snapshots/<name>.txt  ~/.claude/draft-snapshots/logged/
   ```

   **Move, never delete.** The log entry holds both texts verbatim, so the files are redundant - but a mis-parsed diff is recoverable from them and not from the entry. Moving is also what keeps the top level meaningful as a queue of uncaptured drafts.

8. **Report in a few lines:** how many edits, their classes, and any promotion candidate. Do not restate the message.

---

## Entry template

```markdown
## [YYYY-MM-DD] <slug> | <genre> -> <audience>

- **Situation:** <one line from the footer>
- **Draft:** `~/.claude/draft-snapshots/YYYY-MM-DD-<slug>.txt`
- **Final:** `<path>` | Sent Mail ID `<n>`, <date> | not yet sent
- **Status:** <new pattern | Nth instance of X | promoted to CLAUDE.md YYYY-MM-DD>
- **Model:** <the footer's MODEL line verbatim, or "not recorded">

### Edits

1. **`class`** - *drafted:* "<span>" -> *revised:* "<span>"   (use *cut* or *added* where there is no counterpart)

### Why, in their words

> <verbatim WHY field>

**Almost changed but didn't:** <verbatim, or "(none given)">

### Drafted

(full draft text, inside a fenced `text` code block)

### Sent

(full sent text, inside a fenced `text` code block)
```

The two verbatim blocks are fenced `text` code blocks in the real entry - fenced so the text stays exactly as written and so a later script can extract the pairs cleanly.

**Size control:** include the full before/after only when the piece is under roughly 300 words - which covers nearly every message. For a cover letter or a long essay, include **only the changed passages** as before/after pairs. If the piece lives in a git-tracked source (the `long-form-sources` entry in the "Claude Code paths" section of the user's CLAUDE.md), point at it and name the commit if one exists - the full diff is already recoverable there, and duplicating it into the log is waste.

**Multi-message files:** one entry per message, not per file. Three variants of the same note to three recipients are three entries sharing a situation line - the per-recipient differences are exactly what the log is for.

---

## Scrapped drafts - a draft the user decided not to send at all

**Log it when the user gave a reason about the writing or about whether the message should exist** - that judgment is exactly what this log is for, and a scrapped message is often where stance shows most plainly. **Skip it when the draft died for reasons unrelated to it** (circumstances changed, the thread moved on, it became moot); nothing was learned about the user's voice, and an entry would be noise.

**Four differences from a normal entry:**

1. **`Final:` reads `not sent - scrapped YYYY-MM-DD`**, and the `### Sent` section says so in words rather than holding text. Never leave it empty, and never fabricate a "would have sent" version.
2. **`### Edits` becomes one wholesale-cut bullet** (`structure`, plus whatever class the reason belongs to), followed by **the specific spans the user's reason points at, quoted**. There is no diff, so the spans are the only thing that makes the entry retrievable later as evidence about a sentence rather than about a decision.
3. **Separate the strategic reason from the voice reason when both are present, and say which came first.** "This won't change the outcome" says nothing about how the user writes; "it reads as too apologetic" does. Conflating them produces a bogus rule about the genre.
4. **The snapshot rule relaxes, and the entry must say so.** A scrapped draft usually never went through `/draft-file`, so the before-side is quoted from the session that produced it. **That is allowed only when the draft text is present verbatim in the current conversation** - quoting a message Claude itself wrote in-session is not reconstruction from memory. **The entry states plainly that there is no snapshot and that it is a weaker record**.

**Promotion weight is lower, and this is the substantive point.** A scrapped draft has a rejected side and **no chosen alternative**, so there is no evidence of what the user would have written instead. It can corroborate a pattern already visible elsewhere; **it should not be the second instance that promotes a rule into the user's CLAUDE.md on its own.**

---

## Rules

- **Never edit the message text.** This command reads and records; it does not improve anything.
- **Never write an entry for a diff you cannot see.** No snapshot, no entry - **the one exception is a scrapped draft whose text is verbatim in the current conversation; see "Scrapped drafts" above**, which is a weaker record and is labeled as one.
- **Nothing here is time-sensitive.** A draft can sit in the queue for days across any number of reboots and session restarts; both halves are on disk and neither expires. Never pressure the user to run this before they have sent the thing.
- **The user's reasons are quoted, never summarized.**
- Entries are appended at the end of the file with the correct date, never inserted mid-file to fix ordering.
- When the log outgrows comfortable reading, archive by quarter to a sibling `<log>-archive.md`, leaving a one-line italic pointer in the log.
