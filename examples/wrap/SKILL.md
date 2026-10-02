---
name: wrap
description: End-of-session wrap-up - run the checkpoint daily-note logging, then a single commit of everything, and (with --handoff) emit a resume prompt. Use when the user says "/wrap" or "wrap up", or is ending a session.
allowed-tools: Bash, Read, Write, Edit
---

End-of-session wrap for the vault: the **checkpoint** daily-note logging and the **commit** in one pass, with no double commit, and optionally a **handoff** prompt. The incident behind each phase is in `rationale.md` in this folder; you don't need it to run the skill.

**Arguments:** `$ARGUMENTS`

- `--handoff` (or a bare `handoff`) -> run Phase 4 at the end, passing any remaining text through as the "what's next" context.
- Otherwise -> skip Phase 4.

This skill is a thin orchestrator. It reads the canonical skill files at runtime and follows them, so improvements to those skills are inherited automatically. Don't duplicate their logic here.

All vault paths below are absolute, so `/wrap` works the same from any working directory.

---

## Phase 1 - Checkpoint (daily-note logging)

Read `~/vault/.claude/skills/checkpoint/SKILL.md` and follow it in full. Checkpoint doesn't commit: it captures mtimes for routing, adds current-session work, checks off completed TODOs, and appends `### wiki activity` bullets to the right daily-note blocks. Its edits land in the same single commit as the session's work in Phase 3.

If the working tree was already clean and there's no session-only work to log, say so, then still run Phase 4 if `--handoff` was passed.

## Phase 2 - Failure log (cheap, non-blocking)

Ask once whether anything this session met the entry bar on `~/vault/wiki/topics/ai-failure-modes.md`. This runs before the commit so any edit rides in the same commit.

**The bar is on the page; don't restate the taxonomy here.** In short: an error that **survived into the vault, a workflow, or an outgoing artifact, and needed the user to catch it.** Out of scope: in-session corrections caught before anything was written, typos, formatting slips, and anything flagged as uncertain at the time.

**Don't rely on introspection.** Scan the session for concrete cues:

- The user corrected a claim, a number, a date, or a recommendation.
- A page or skill was edited **to fix something that was wrong**, rather than to add something new.
- A `CORRECTION`, `WRONG`, `superseded`, or `retired` marker was written into any page this session.
- An estimate was given and then materially revised.
- A command produced wrong output while exiting clean (the silent-procedural-defect class).

**The default is nothing, and that must stay cheap.** Most sessions have no qualifying instance: say `no failure-log entries this session` in one line and move on. Never pad the log; a false entry is worse than a missing one, because the page's value is entirely in its signal.

**If something qualifies:** add a row to the instance table (class, detection latency, caught-by), bump `updated`, and add a detail section **only** if it teaches something the row can't carry. Don't restructure the taxonomy; that's a separate, deliberate act.

**Surface, don't write silently.** The agent asked to self-report its errors is the agent that made them, so this check is weakest exactly where it matters most. Name the candidate to the user in one line and let them confirm before writing. If they don't engage, log it and note that it was unconfirmed.

### Phase 2b - Draft review catches (same pass, opposite default)

**Second question, in the same breath:** did the user's review of any drafted prose this session catch something before it shipped? If so it belongs on `~/vault/wiki/topics/draft-review-catches.md`, not the failure log.

**The boundary is shipping, and both pages state it.** An error that **escaped** into the vault, a workflow, or a sent artifact goes to ai-failure-modes. An error **caught pre-ship** goes to draft-review-catches. Borderline cases go to draft-review-catches with a cross-reference. Don't loosen the failure log's bar to absorb these; that page's value is its selectivity.

**In scope:** any prose the user sends as themselves (cover letters, application free-text, essays, recruiter and founder messages, emails, resume variants), **plus drafted wiki pages, periodic notes, and tracker rows.** "Shipped" is read per medium: **sent** for outgoing prose, **written to the file** for vault content, **committed** for a commit message. A wrong claim corrected in the terminal before its `Edit` call is a pre-ship catch; the same claim written to the file and found afterward escaped, and goes to ai-failure-modes with its latency. So this applies to `/horizons`, ingests, and any session where the user corrected a drafted page in the terminal, not only to application sessions.

**THE HARD PRECONDITION, which outranks everything else in this phase: the user must have made a correction themselves.** Not a directive that improved the draft, not a decision they were asked for, not a clarifying question that came back fine, not a style preference - **and never a defect you noticed in your own draft and wrote up yourself.** If the user didn't identify something wrong, there is **no entry**, and `no draft-review catches this session` is the complete and correct output. A self-generated entry is worse than none. The full bar, with a table of tempting near-misses, is the page's THE ENTRY BAR section; read it before writing anything.

**Given that precondition, search properly**: real catches are invisible a day later. The cue is **the user identifying something wrong in drafted material**, in any form: *is this strictly true, how would I defend it, isn't that the wrong person, do I actually have more than one, that's too dramatic, that reads as presumptuous.* Look hard for one you might be about to forget; don't produce one.

**What to write:** continue the entry numbering across sessions, under a `## Session YYYY-MM-DD` heading (add a parenthetical such as `(evening)` when a date already has one). Each entry carries **the draft text, the user's question verbatim, what was wrong, and what it became**. The question is the unit, because the page's output is a reusable checklist. Then **promote anything generalizable into the THE CHECKLIST section** and bump `updated`. Never rewrite or remove existing entries.

### Phase 2c - Uncaptured draft revisions (a directory listing, not a judgment)

**This phase asks the filesystem, not the model.** `/draft-file` writes voice artifacts to `~/.claude/drafts/` with a pristine copy under the same basename in `~/.claude/draft-snapshots/`; `/log-edit` records the diff and then moves **both** halves into their `logged/` subdirectories. So the top level of `~/.claude/drafts/` *is* the queue of uncaptured revisions:

```bash
ls ~/.claude/drafts/*.txt 2>/dev/null
```

For each file, one diff decides whether to mention it:

```bash
diff ~/.claude/draft-snapshots/<name>.txt ~/.claude/drafts/<name>.txt
```

- **Only the footer block differs** -> not revised yet. **Say nothing.** An unrevised draft is a normal resting state and may sit for days; nagging about it trains the user to ignore the phase.
- **Real divergence in the message text** -> revised and never captured. **Name it in one line and offer `/log-edit <name>`.**
- **No files at top level** -> say nothing.

**Surface, never act.** Don't run `/log-edit` on the user's behalf: they may still be mid-edit, and capture writes a wiki entry that would ride into this commit unreviewed. This phase runs before Phase 3 so that a capture they *do* ask for lands in the same commit.

## Phase 3 - Commit (single, everything)

Read `~/.claude/skills/commit/SKILL.md` and follow it to produce one commit **in the vault**, whatever the session's working directory: run every git command as `git -C ~/vault ...`, and take the repo-specific rules from the "Commit messages" section of `~/vault/CLAUDE.md`. **With these additions:**

- It stages every changed file, so leftover changes from earlier sessions are included by design.
- **Leftover flag (non-blocking):** compare `git status` against what this session touched (Phases 1-2 plus the daily-note edits). If the commit also sweeps in clearly unrelated earlier work, still commit it, but **name those files in the confirmation line**, e.g. `note: also committed 3 leftover files unrelated to this session (foo.md, bar.md, baz.md)`. Don't turn this into a prompt; the commit skill's own secret/large-file/junk-dir scan is the only thing allowed to stop and ask.

The message describes the dominant change of *this* session. If leftovers make the diff span unrelated topics, keep the first line on the session's work and, if useful, add a short body line noting the leftovers.

### 3b - Config repo (only if it has changes)

Skills, commands, hooks, settings and the global `CLAUDE.md` live in `~/claude-config`, not the vault, so the vault commit never includes them. Run `git -C ~/claude-config status --short`. If it's clean, say nothing. If not, follow the same commit procedure there as a **second, separate commit** (`git -C ~/claude-config ...`, generic message rules). Also run `~/claude-config/install.sh --check` and report anything it flags (a managed path that's no longer the expected link); don't fix it unasked.

## Phase 4 - Handoff (only with `--handoff` / `handoff`)

Read `~/.claude/skills/handoff/SKILL.md` and follow it, passing through any non-flag argument text as the "what's next" context. This runs **after** the commit so the git log and daily note it reads are current.

---

**Rules:**
- One commit per `/wrap` run in the vault (Phase 3), plus at most one in `~/claude-config` (3b). Never leave Phase 1's daily-note edits or Phase 2's log edits uncommitted.
- Phases 2, 2b and 2c are non-blocking and their normal outcome is "nothing". They never delay or gate the commit.
- No push: `/wrap` never pushes. Use `/push` separately.
- Don't amend; never `--no-verify`.
- The user invoked this explicitly: no extra confirmation beyond the safety scan and the leftover flag.
