---
name: mine-transcripts
description: Mine the local Claude Code session transcripts for real usage - slash-command frequency and intent clusters - then surface new command/skill candidates and never-used ones. Use for a periodic retrospective of how Claude Code is being used.
---

# /mine-transcripts

Audit how Claude Code is actually being used, by mining the local session
transcripts, then surface new command/skill candidates and never-used commands.

This is the self-improving meta-workflow: it reads your real usage history and
tells you what to build next and what to prune.

## Steps

1. **Run the miner.** Execute the analysis script bundled with this skill:

   ```bash
   python3 "${CLAUDE_SKILL_DIR}/mine-transcripts.py"
   ```

   It scans every transcript under `~/.claude/projects/*/*.jsonl`, extracts the
   real user prompts (filtering tool results, command stdout, and system
   reminders), and writes `/tmp/transcript_findings.txt` with: per-project
   prompt/session counts and date range, slash-command usage frequency, and
   intent clusters with sample prompts.

2. **Read the findings.** Read `/tmp/transcript_findings.txt` in full.

3. **Inventory existing commands and skills.** List `.claude/commands/*.md` and
   `.claude/skills/*/SKILL.md` (project-level), `~/.claude/commands/*.md` and
   `~/.claude/skills/*/SKILL.md` (user-level), and any enabled plugins' skills,
   so you know what coverage already exists. For each intent cluster, mark it
   covered / partial / none.

4. **Derive recommendations.** Identify:
   - **Build candidates** - high-volume intent clusters with no (or only
     partial) command coverage. Rank by ROI (volume * how mechanical/repeated
     the work is).
   - **Prune candidates** - commands with zero or near-zero invocations.
     Distinguish genuinely unused from merely cadence-based (e.g. a weekly
     review fires weekly; a short window may just not have hit the trigger).
   - Note any caveats about the sampling window (e.g. a month dominated by one
     project skews the intent mix).

5. **Append to the usage log.** The log is the `transcript-usage-log` entry in
   the "Claude Code paths" section of the user's CLAUDE.md (default
   `~/.claude/transcript-usage-log.md`; create it if missing). If the entry
   names a section heading, append inside that section. Add a new dated
   subsection (format: `### YYYY-MM-DD - <window>`), mirroring any earlier
   entry: scope, caveat, slash-command usage table, intent-vs-coverage table,
   headline finding, ranked recommendations. If the file has a
   `## Custom Skill Candidates` table, add any new build candidates there too.
   Never overwrite prior dated subsections - the log is an append-only audit
   trail.

6. **Report to the user.** Summarize the headline finding and the top 2-3
   build/prune actions. Ask before creating any new command or skill files.

## Notes

- The generic intent clusters live in `INTENT_PATTERNS` inside
  `mine-transcripts.py`. Personal clusters go in an optional
  `intent_patterns.local.py` next to it (same dict name; merged on top). If a
  cluster looks too broad/narrow, tune the regexes and re-run rather than
  hand-categorizing.
- Re-run periodically (monthly or quarterly is plenty) - the value is in the
  trend across dated subsections, not any single snapshot.
- **Set `cleanupPeriodDays` before relying on this.** Claude Code deletes
  transcripts older than `cleanupPeriodDays` (default 30), so with the default
  each run only sees about the last month and the trend this skill exists to
  track never builds up. Set it in `~/.claude/settings.json`, e.g.
  `"cleanupPeriodDays": 365`. On the first run, check the findings' date range;
  if it spans only about 30 days, tell the user and suggest raising the setting.
  Transcripts already deleted can't be recovered.
