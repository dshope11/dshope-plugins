---
name: lint
description: Wiki health check - find orphans, contradictions, stale claims, and missing concept pages. Use when the user asks to lint the wiki or for a wiki health check.
allowed-tools: Bash, Glob, Grep, Read, Edit, Write, Agent
---

Wiki lint pass for the vault's knowledge base.

**Interruption-safe by design.** /lint is often run at the end of the week to spend leftover usage budget, so a run can die partway through at the usage limit. Every intermediate result goes to disk in the run's own directory under `.lint-run/` (vault root, gitignored, hidden from Obsidian) the moment it exists, and a new `/lint` **resumes** an unfinished run instead of starting over. Nothing finished is ever held only in the conversation. (Added 2026-10-10 after the 2026-10-03 `/lint deep` lost all eleven content slices to the session limit.)

**Each run keeps its own directory, and no run deletes another.** The run id is the start date (`YYYY-MM-DD`, with `-2`, `-3` for a second or third run started the same day). An earlier run's report is what its fix pass works from, often days later, and what the next run compares against to tell new findings from unfixed ones. (Changed 2026-10-22: the old single-directory layout cleared the 10/10 report, with its ~200 findings still unfixed, the moment a new run started.) A run directory is ~150 KB, so there's no retention rule; prune by hand if it ever matters.

```
.lint-run/
  <run-id>/         e.g. 2026-10-10/
    run.md          manifest: started date, mode, slice plan in launch order, status: in-progress | complete
    structural.md   orphan / missing-page / stale results (steps 2-4)
    slice-<ID>.md   one per content slice (recency, A, B1, ...), written by that slice's own subagent
    report.md       the assembled report (step 7)
```

Below, `<run>` means `.lint-run/<run-id>/` for the current run.

Every slice file's first line is `status: in-progress` or `status: complete`, with a `pages read:` line below it. **A slice counts as done only if its file says complete.**

**Steps:**

0. **Context tip** - print once, then continue:

   - `Tip: /lint is most reliable when run at the start of a fresh session, not mid-session. Context already in use reduces reliability of the structural checks; the content checks run in their own subagent context either way.`

0.5. **Read `wiki/lint-notes.md` first.** It's the lint skill's persistent memory: *known-accepted* items (do NOT re-flag these - e.g. intentional forward-marker links, expected dead-ends), *tool quirks* (adjust how you run the scans), and *deferred decisions*. Apply it throughout: suppress known-accepted items from the report, and run the structural checks the way the quirks section advises (e.g. the `obsidian unresolved` blind spots).

0.7. **Resume check.** Look for a run directory under `.lint-run/` whose `run.md` says `status: in-progress` (newest first, by run id).
   - **Found -> resume it.** Print one line: the run id, the mode, and which slices are complete, partial (file exists, still in-progress) or not started. Keep the completed slice files. Re-run steps 1-4 only if `structural.md` is missing or wasn't written today (it's cheap, and a week-old structural pass is stale). Then go to step 5 and launch only the slices that aren't done. A **partial** slice is relaunched on just the pages its `pages read:` line doesn't list, and its subagent appends to the existing file. (Cross-page contradictions between the two halves can be missed; say so in the report.) If the invocation names a different mode than the saved run, ask whether to resume it, mark it `status: abandoned` and start fresh, or leave it and start fresh. Never delete it.
   - **None in progress -> start fresh.** Create `.lint-run/<today>/` (suffix `-2` etc. if that exists) and write its `run.md`: today's date, the mode, the slice plan (recency first, then partition IDs in cursor order), `status: in-progress`. Leave every earlier run directory alone. Note the newest earlier run with a `report.md` as the **previous run**, for step 6.

1. Read `wiki/index.md` to get the full list of wiki pages and their locations.

2. **Orphan check** - find wiki pages with no inbound wikilinks from other wiki pages.
   - Run: `obsidian orphans | grep "^wiki/"` - this uses Obsidian's resolved link graph (more accurate than regex).
   - From that list, exclude `wiki/index.md`, `wiki/log.md`, and `wiki/lint-notes.md` (structural files that don't need inbound links).
   - Flag any remaining page with zero inbound links. If the index is the only inbound link, still flag it as an orphan.

3. **Missing page check** - find broken wikilinks originating from wiki pages.
   - Run: `obsidian unresolved | grep "^wiki/"` - returns wikilinks Obsidian cannot resolve to a file.
   - Flag each unresolved target and note which file it appears in.

4. **Stale source check** - find wiki pages whose `updated:` frontmatter date is more than 60 days before today, or that reference `raw/` sources which no longer exist.
   - Read frontmatter `updated:` from all wiki pages and flag those older than 60 days.
   - For each `sources:` field referencing a `raw/` path, check that the file exists.

4.5. **Save the structural results now.** Write steps 2-4 to `<run>/structural.md`, in the report's section format, before starting the content pass.

5. **Content pass (delegated, partitioned)** - the wiki is divided into **domain partitions** for content scanning; the authoritative partition list and the **rotation cursor** (which partition is next) live in `wiki/lint-notes.md`, section "Content-pass partitions & rotation cursor". Depth is controlled by the invocation:

   - **`/lint` (default, depth 1):** two slices:
     1. *Recency slice* (`recency`) - the 3-5 most recently updated wiki pages (by `updated:` frontmatter) plus the pages they link to.
     2. *Rotation slice* - every page in the **next partition** per the cursor.
   - **`/lint deep N`:** the recency slice plus the next **N** partitions per the cursor.
   - **`/lint deep` (no number):** the recency slice plus **all** partitions, for a full-wiki content pass. This is the right mode for spending leftover budget: the run goes until it's done or the limit hits, and anything that finished is kept.
   - **`/lint <ID> [<ID>...]`** (e.g. `/lint E1 E2`): just the named partitions, no recency slice. For a section that's never been scanned or was just heavily edited. The cursor doesn't move.

   **How slices are launched (this is what makes a run interruption-safe):**
   - **Subagent type: `general-purpose`, `model: "sonnet"`, `run_in_background: true`.** Not Explore: Explore can't write files, and each slice has to save its own findings. Otherwise its result exists only as a notification to a parent session that may already be out of budget. Sonnet because a slice is ~75-105k words of reading, and 11 parallel Opus slices are what exhausted the limit on 10/03.
   - **At most 3 slices in flight.** Launch the first three in plan order. As each completion notification arrives, launch the next pending slice. If the limit hits, at most three slices of in-progress work are lost, and even those keep whatever they checkpointed.
   - **After each completion:** check that the slice file says `status: complete`. If it doesn't, note the slice as partial in `run.md`. Then advance the cursor line in `wiki/lint-notes.md` to the next partition that isn't done, with today's date (one Edit). This keeps the cursor right even if the run is later abandoned rather than resumed.

   Every subagent prompt contains the same two checks with its page list filled in (full paths), plus the write discipline:
   - **Contradiction scan** - read the assigned pages (recency slice: also the pages they link to; partition slices: just the partition), and report factual claims that conflict between pages (page A says X, page B says not-X), with file paths and the conflicting sentences quoted. Partition subagents should also flag *internally* stale claims (a page contradicting itself or a clearly superseded status).
   - **Missing concept suggestions** - while reading, note technical terms, techniques, or named frameworks that are mentioned repeatedly but have no `wiki/concepts/` or `wiki/entities/` page. Report the top 3-5 most-referenced gaps with where they're mentioned.
   - **Write discipline (paste verbatim, with the path filled in):** "Your ONLY file write is `<abs vault path>/.lint-run/<run-id>/slice-<ID>.md`. Do not modify any other file. Create it first with `status: in-progress` on line 1, a `pages read:` line, and empty `## Contradictions` and `## Missing concepts` sections. After every ~5 pages read, rewrite the whole file with your findings so far and the updated `pages read:` list. When finished, set line 1 to `status: complete`, and write `none found` under any empty section. Findings are compact bullets, with no file dumps. If a write is blocked by the markdown-safety hook, paraphrase the quoted text (spell out operators in words) and retry. Your final reply is one line of counts only. The file is the deliverable."

6. **Fold from disk, not from replies.** Read `<run>/structural.md` and every `<run>/slice-*.md`, and ignore the agents' return messages. Deduplicate overlapping findings and note which slice caught each. Report any slice that's missing or still `in-progress` as skipped or partial (with its pages-read count). Never omit a slice silently. **If there's a previous run** (step 0.7), mark each finding that repeats one in its `report.md` as `(open since <previous run id>)`, so an unfixed finding shows as carried over rather than new, and give the count of carried-over findings in the report's first lines.

7. **Output a lint report** - write it to `<run>/report.md` first, then print it in the conversation, in this format:

```
## Wiki Lint Report - YYYY-MM-DD

### Orphan pages (no inbound links)
- [[page]] - reason / suggestion

### Missing pages (dead wikilinks)
- [[target]] - referenced in [[source]]

### Stale pages (>60 days or missing source file)
- [[page]] - last updated YYYY-MM-DD / missing source: path

### Possible contradictions
- [[page-a]] vs [[page-b]] - description of conflict

### Missing concept pages (mentioned but not created)
- `term` - mentioned in [[page]], [[page]]

### All clear
*(section only if nothing to report in a category)*
```

8. Ask the user: "Want me to fix any of these now?"

9. **Update `wiki/lint-notes.md`.** Append any durable findings from this pass that a future lint should know: new known-accepted items (intentional links/dead-ends that were confirmed fine), new tool quirks discovered, or deferred decisions. Add a dated entry to its Change log. Skip if nothing durable surfaced - don't pad it. Prune entries that are no longer true. When a `/lint deep` completes every partition, reset the cursor to the first partition.

10. **Close the run.** Set `<run>/run.md` to `status: complete`. Leave the directory in place: the fix pass after the report reads from it, and the next run compares against it.

**Rules:**
- Read-only pass - do not modify any wiki files unless the user explicitly asks after seeing the report. The exceptions are `.lint-run/` (run state), and in `wiki/lint-notes.md` the cursor line and the step 9 notes.
- Focus on the `wiki/` directory only; do not lint `raw/`, `Daily Notes/`, or other vault directories.
- If the index is the only file with a link to a page (i.e. the index itself is the only inbound link), still flag it as an orphan - the index doesn't count.
- Log the lint run to `wiki/log.md` after the report: `## [YYYY-MM-DD] lint | Health check`
