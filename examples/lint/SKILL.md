---
name: lint
description: Wiki health check - find orphans, contradictions, stale claims, and missing concept pages. Use when the user asks to lint the wiki or for a wiki health check.
allowed-tools: Bash, Glob, Grep, Read, Edit, Agent
---

Wiki lint pass for the vault's knowledge base.

**Steps:**

0. **Context tip** - print once, then continue:

   - `Tip: /lint is most reliable when run at the start of a fresh session, not mid-session. Context already in use reduces reliability of the structural checks; the content checks run in their own subagent context either way.`

0.5. **Read `wiki/lint-notes.md` first.** It's the lint skill's persistent memory: *known-accepted* items (do NOT re-flag these - e.g. intentional forward-marker links, expected dead-ends), *tool quirks* (adjust how you run the scans), and *deferred decisions*. Apply it throughout: suppress known-accepted items from the report, and run the structural checks the way the quirks section advises (e.g. the `obsidian unresolved` blind spots).

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

5. **Content pass (delegated, partitioned)** - the wiki is divided into **domain partitions** for content scanning; the authoritative partition list and the **rotation cursor** (which partition is next) live in `wiki/lint-notes.md`, section "Content-pass partitions & rotation cursor". Depth is controlled by the invocation:

   - **`/lint` (default, depth 1):** launch **two Explore subagents in parallel** (both run_in_background: false, in one tool-call block):
     1. *Recency slice* - the 3-5 most recently updated wiki pages (by `updated:` frontmatter) plus the pages they link to.
     2. *Rotation slice* - every page in the **next partition** per the cursor. Advance the cursor after the run.
   - **`/lint deep N`:** same recency subagent, plus the next **N** partitions per the cursor, one subagent each, all in parallel. Advance the cursor by N.
   - **`/lint deep` (no number):** recency subagent + **all** partitions in parallel - a full-wiki content pass. Reset the cursor to the first partition.

   Every subagent gets the same two checks, with its page list filled in:
   - **Contradiction scan** - read the assigned pages (recency slice: also the pages they link to; partition slices: just the partition), and report factual claims that conflict between pages (page A says X, page B says not-X), with file paths and the conflicting sentences quoted. Partition subagents should also flag *internally* stale claims (a page contradicting itself or a clearly superseded status).
   - **Missing concept suggestions** - while reading, note technical terms, techniques, or named frameworks that are mentioned repeatedly but have no `wiki/concepts/` or `wiki/entities/` page. Report the top 3-5 most-referenced gaps with where they're mentioned.
   - Tell it to return ONLY the findings in a compact list (no file dumps), and to report "none found" per category if clean.

6. Fold all subagents' findings into the report below (deduplicate overlapping findings; note which slice caught each). If a subagent fails or times out, note that slice was skipped rather than silently omitting it. After the run, update the rotation cursor in `wiki/lint-notes.md` (partition(s) scanned + date).

7. **Output a lint report** - print it directly in the conversation in this format:

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

9. **Update `wiki/lint-notes.md`.** Append any durable findings from this pass that a future lint should know: new known-accepted items (intentional links/dead-ends that were confirmed fine), new tool quirks discovered, or deferred decisions. Add a dated entry to its Change log. Skip if nothing durable surfaced - don't pad it. Prune entries that are no longer true.

**Rules:**
- Read-only pass - do not modify any wiki files unless the user explicitly asks after seeing the report.
- Focus on the `wiki/` directory only; do not lint `raw/`, `Daily Notes/`, or other vault directories.
- If the index is the only file with a link to a page (i.e. the index itself is the only inbound link), still flag it as an orphan - the index doesn't count.
- Log the lint run to `wiki/log.md` after the report: `## [YYYY-MM-DD] lint | Health check`
