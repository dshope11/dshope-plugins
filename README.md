# claude-code-plugins

Claude Code skills and hooks, each built to prevent a specific failure seen in daily use.

*Work in progress - the full write-up is coming.*

## Install

```
/plugin marketplace add dshope11/claude-code-plugins
/plugin install git-guards@claude-code-plugins
```

| Plugin | What it does |
|---|---|
| `git-guards` | `/commit` and `/push` that work from the real diff, plus a hook that blocks fragile heredoc commit messages |
| `voice-loop` | `/draft-file` exports drafts to clean paste-ready files; `/log-edit` logs how you revised them |
| `claude-md-hygiene` | `/audit-claude-md` trims a CLAUDE.md; `/mine-transcripts` finds skills worth building in your session history |
| `obsidian-guards` | Blocks markdown writes that would break Obsidian rendering (enable per vault project) |

## Personal paths

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

Built with Claude Code.
