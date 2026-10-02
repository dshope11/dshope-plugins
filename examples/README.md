# Worked examples

These are skills from my own setup, published as reading material rather than plugins. They
assume a specific Obsidian vault layout (daily notes, periodic notes, an
[LLM-maintained wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)) and
a read-only mail CLI, so they won't run as-is anywhere else. What carries over is the shape: many
rules exist because something went wrong without them, and most of those are about state the
model can't see on its own.

Vault paths appear as `~/vault`. [`CLAUDE.md`](CLAUDE.md) is an annotated excerpt of the global
instructions file these skills run under.

| Example | What it does | What to look at |
|---|---|---|
| [`sod/`](sod/SKILL.md) | Start-of-day note: carries the TODO backlog with an age counter, reads the period's plans and progress, sweeps the inbox, briefs the day | The inbox coverage rule (a watermark, not the unread set, decides where "new" starts), and the rule that mail alone can never show whose turn it is |
| [`horizons/`](horizons/SKILL.md) | Weekend review across week, month, quarter and year | The nearest-weekend rule for which periods roll over, and the shared spec in `periodic-workflow.md` that eight smaller commands also read |
| [`wrap/`](wrap/SKILL.md) | End of session: log the work to the daily note, ask about failures and review catches, commit once | The failure-log phase, which scans for concrete cues instead of asking the model to introspect |
| [`checkpoint/`](checkpoint/SKILL.md) | Log session work to the right daily note by file mtime | Routing by mtime, so work committed the next day still lands on the day it was done |
| [`handoff/`](handoff/SKILL.md) | A paste-ready prompt for the next session | It opens with a hold instruction, so a pasted handoff doesn't pre-read stale context |
| [`lint/`](lint/SKILL.md), [`relink/`](relink/SKILL.md), [`note/`](note/SKILL.md) | Wiki health checks, cross-link sweeps, inline personal notes | Content checks delegated to subagents on a rotating partition |
| [`neetcode/`](neetcode/SKILL.md) | One interview-style coding-problem cycle | Gating on a sound approach before any code, and taking constraints from the judge actually used |
