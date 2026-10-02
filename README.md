# dshope-plugins

Claude Code skills and hooks from my daily setup, published two ways: four installable plugins,
and a set of worked examples from the larger system they came out of. Many pieces exist because
something went wrong without them, and this README tells four of those stories.

I've used Claude Code since April 2026 to run an Obsidian vault the agent maintains
(daily notes, a wiki in the style of
[Karpathy's LLM wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f), periodic
reviews), a job search, and a few code projects.

## Install

```
/plugin marketplace add dshope11/dshope-plugins
/plugin install git-guards@dshope-plugins
```

| Plugin | What it does |
|---|---|
| `git-guards` | `/commit` and `/push` that work from the real diff, plus a hook that blocks fragile heredoc commit messages |
| `voice-loop` | `/draft-file` exports drafts to clean paste-ready files; `/log-edit` logs how you revised them |
| `claude-md-hygiene` | `/audit-claude-md` trims a CLAUDE.md; `/mine-transcripts` finds skills worth building in your session history |
| `obsidian-guards` | Blocks markdown writes that would break Obsidian rendering |

`obsidian-guards` checks every `.md` write, so install it per project, from inside the vault:
`claude plugin install obsidian-guards@dshope-plugins --scope project`.

Skills that need a personal file location read it from a `## Claude Code paths` section in
your `~/.claude/CLAUDE.md`, and fall back to a default when a key is missing:

```markdown
## Claude Code paths

- `draft-edit-log`: ~/notes/draft-edit-log.md
- `transcript-usage-log`: ~/notes/claude-usage.md
- `editor-open`: open -a "Visual Studio Code"
- `sent-mail`: himalaya, folder "Sent"
- `long-form-sources`: ~/writing/
```

## Where the rules come from

I keep a log of every error that got past a session into a file, a workflow or a sent message
and needed me to catch it. Each entry records what broke, how far it spread, how long it took
before anyone noticed, and who noticed. Each finding then gets a guard where one is possible: a
rule in `CLAUDE.md`, a step in a skill, or a hook. The difference matters. An instruction is
advice the agent may or may not follow; a hook fires before the tool runs, and the agent can't
get around it.

The log needed a guard of its own. It sat for 15 weeks with a single entry, because nothing ever
asked whether anything had been caught. Now my end-of-session skill asks every time. It looks for
concrete cues (a claim I corrected, a page edited to fix rather than to add) instead of asking the
model to introspect, and it puts each candidate to me instead of writing it down.

The fix can overshoot. A second log records mistakes I catch in drafts before they ship, and
once a session logged a mistake in its own draft that I never caught, because the step said an
entry was expected. That step now counts only corrections I made myself. A made-up entry is worse
than none, because nothing on the page sets it apart from the real ones.

Reading back through the log, many of the failures had something in common: nothing looked
wrong. Here are four, one from each layer of the setup.

## Four failures that looked like success

### A hook that passed by saying nothing

My [atlas-classifier](https://github.com/dshope11/atlas-classifier) project ran a `PostToolUse`
hook after every edit: ruff, pytest and mypy. It printed the results and exited 0, and its
comment and the project README both said Claude would see them. It didn't. On exit 0, Claude
Code sends a hook's stdout to the debug log, not to the model, so a failing test produced exactly
what a passing one did, and the agent carried on. I confirmed it with a headless run against a
deliberately failing test: the old hook gave the agent nothing back, and the rewrite returned the
pytest failure verbatim. The template here exits 2 on failure with the output on stderr, and
stays silent on a pass.

[`templates/python-quality-hook/`](templates/python-quality-hook/)

### A command that never ran

Skills defined in a project's `.claude/` only exist in sessions started in that project. I typed
`/wrap`, my end-of-session skill, which lived in the vault, during a session in a different repo.
It didn't resolve, so the model treated it as conversation and wrote a summary shaped like a
wrap-up. Nothing in the reply showed the difference. What got skipped was the step that asks
whether anything went wrong, which was the error log's only trigger, so the miss recreated the
exact gap that had left the log empty for 15 weeks. `/wrap` and `/handoff` now live at user level
and resolve from any repo. Their relative paths had to become absolute first: a skill promoted
with a vault-relative path half-works and still reports success.

[`examples/wrap/`](examples/wrap/SKILL.md)

### An empty search read as an answer

A morning skill triages my inbox along with the day's notes. Three of its failures had one shape:

- **The window started at the oldest unread message.** I read an interview-stage invite one
  evening, five bulk messages arrived overnight, and the window started after the invite. The
  morning briefing never showed it. Now a watermark, written on every run, sets the window.
- **A sender search for `lin` came back as a clean, empty table.** The mail CLI matches whole
  words, so it never matched `linkedin.com`. An empty table from a bad query looks exactly like
  an empty inbox.
- **A stale tracker row plus a quiet inbox produced "he replied and you never answered."** I'd
  replied that morning on LinkedIn, and a reply sent there never shows up in the mail. Mail
  alone can't show whose turn it is, so the skill now reconstructs both sides of a thread from
  my notes before it says anything about one.

[`examples/sod/`](examples/sod/SKILL.md)

### Revisions nobody kept

I revise nearly every draft Claude writes for me before I send it, and those edits are the best
record there is of how I write. They also vanish: once the draft is overwritten, the "before" side
is gone. The first two voice rules in my `CLAUDE.md` were each learned twice for that reason. I
corrected a habit, nothing recorded it, and it came back in a later draft.

`voice-loop` captures both sides. `/draft-file` saves a pristine snapshot before I touch the draft
and adds a footer asking why I changed it. `/log-edit` diffs the snapshot against what I sent,
quotes my reasons word for word, and appends an entry to the log. The next `/draft-file` reads the
matching entries before it writes anything. The log collected 18 entries in its first three weeks,
and three of the five voice rules in my `CLAUDE.md` were promoted from it.

A pattern in the log becomes a rule once it shows up a second time. At first, two near-identical
messages written an hour apart counted as two, but that's one observation counted twice. Now the
second instance has to be *independent*: a different kind of message, a different recipient, or
a different day.

Each drafted-and-sent pair is also a chosen/rejected example in the format preference tuning
uses, though it would take a few hundred pairs before that's worth anything.

[`plugins/voice-loop/`](plugins/voice-loop/)

## What the log can't tell you

- **There's no denominator.** It holds the errors I found. Whatever is still in the vault has no
  detection latency at all, so I can't give a rate.
- **The checker isn't independent.** The end-of-session check is run by the same agent that made
  the errors, which makes it weakest exactly where it matters most. Cues instead of introspection,
  and my confirmation on every entry, reduce that without fixing it.
- **It can't be pinned on a model.** I switched models several times in six months, and the log
  doesn't record which one was running. The guards were written against whatever model I had at
  the time, so I'd expect to need fewer of them, or different ones, as models change. The method
  is the part I'd expect to carry over.

## How this repo is built

There are two repos, and the flow only goes one way. A private repo is the single source of truth
for my whole Claude Code layer: the global `CLAUDE.md`, skills, hooks and settings, installed with
symlinks. This repo is generated from it by an export script and never edited by hand.

That split is also the privacy design:

- **Skills hold rules only.** The dated incident behind each rule lives in a `rationale.md` beside
  the skill, and the exporter refuses any file with that name.
- **The export is default-deny.** Only files listed in a manifest leave the private repo.
- **Every export is scanned twice:** once against a private list of names and other private
  terms, and once with gitleaks. The same scan runs as a pre-commit hook in this repo's clone. A
  GitHub Action repeats gitleaks plus generic email and phone patterns, since the private list
  can't leave the private repo.

Every plugin was installed from a local marketplace and exercised before publishing. That meant
headless runs that invoked each skill under its plugin namespace and made each hook block a
real tool call. A real install was worth the effort: `claude plugin validate --strict` accepted
this repo's original name, and `claude plugin marketplace add` refused it, because Anthropic
reserves that marketplace name.

[`examples/`](examples/) holds the skills that depend on my vault layout. They won't run as-is,
but many of the rules in them trace to an incident. [`examples/CLAUDE.md`](examples/CLAUDE.md) is an
annotated excerpt of the global instructions file they run under.

## What I'd do differently

- **The rule I most want enforced still has no hook.** File edits should go through Edit or Write,
  never `sed -i` or a heredoc, because hooks only fire on those tools and a shell write skips
  them. I promoted that rule to the global `CLAUDE.md`, and about five hours later the session that
  had just written up the original failure broke it. A Bash hook can't reliably tell a file write
  from a read, so the rule is still only advice.
- **Split rules from their stories from day one.** I only separated them while preparing this
  repo, and the first cleanup pass deleted two skills' stories outright. They
  came back from git history.
- **Record the model in every log entry.** It costs one field, and without it the log can't
  separate what one model got wrong from what the workflow got wrong.

Built with Claude Code: the skills, hooks and export pipeline were all written in Claude Code
sessions.
