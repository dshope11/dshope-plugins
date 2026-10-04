# Status line with a cache countdown and plan usage (template)

A status line that shows the folder, git branch, model and effort level, plus a context bar that
also counts down to when the prompt cache goes cold, and your plan's session and weekly usage. It ships as a template rather than a plugin
because a plugin can't set `statusLine`: Claude Code drops that key from a plugin's settings.

```
[my-repo (main *)  Opus 5.5 ● high] [█████░░░░░ 48% · 43m]
[my-repo (main *)  Opus 5.5 ● high] [█████░░░░░ 48% · 12m]
[my-repo (main *)  Opus 5.5 ● high] [█████░░░░░ 48% · 4m]
[my-repo (main *)  Opus 5.5 ● high] [█████░░░░░ 48% · cold 96k]
```

- `*` and `+` after the branch mark unstaged and staged changes. Untracked files don't count.
- The bar is context use: cyan, then yellow from 30%, red from 60%.
- The minutes are time left before the cached prefix expires: gray above 15, yellow from 15 to
  5, red under 5. Once it's cold, the number is the tokens your next message would write to the
  cache again.

On a Claude subscription, plan usage sits right-aligned on the same line:

```
[my-repo (main *)  Opus 5.5 ● high] [█████░░░░░ 48% · 43m]        [5h 23% (1h40m) · wk 30% (+0.1 days)]
```

- `5h` is the session limit, with the time until it resets; `wk` is the weekly limit. The
  percentages are cyan, then yellow from 75%, red from 90%, the thresholds the usage page uses.
- The parenthesis after `wk` is pace: how many days of usage you are ahead of (+) or behind (-)
  an even spread across the week, counted from the reset time. Gray at or under pace, yellow up
  to a day ahead, red beyond that.
- Claude Code passes the terminal width in `COLUMNS`; without it, or on a narrow window, the
  segment follows the context bar instead. It's absent until the first reply of a session, and
  on API-key billing, which has no plan limits.

## Install

1. Copy `statusline-command.sh` to `~/.claude/statusline-command.sh`.
2. Merge `settings.json` into `~/.claude/settings.json`.

It needs `bash`, `jq`, `awk` and `git`, a font with the effort glyphs (○ ◐ ● ◉ ◈), and Claude Code
v2.1.251 or later for the cache data.

## Why `refreshInterval`

A status line re-runs on events, such as a new message, and once more when the cache expires. A
countdown matters most while you're idle, which is exactly when no events arrive, so without a
timer it freezes at the last value and then jumps straight to cold. `refreshInterval: 60` re-runs
it every minute.

The script reads the cache's own `expires_at` rather than assuming a lifetime, because the TTL
depends on billing: one hour on a Claude subscription within its included usage, five minutes on
usage credits or an API key, unless you set `promptCacheTtl` yourself.

## Why `git status` and not `git diff`

With `refreshInterval` set, the script runs git every minute in every open session. `git diff`
can rewrite the index as a side effect, which takes `.git/index.lock`, and a commit that runs at
the same moment then fails. `git status` with `GIT_OPTIONAL_LOCKS=0` skips that write, so the
script gets both markers from one `git status --porcelain` call.
