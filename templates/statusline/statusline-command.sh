#!/usr/bin/env bash
# Claude Code status line - a prompt-style [dir (branch)  model effort] look, plus a
# context bar with a prompt-cache countdown: [bar pct% - minutes-to-cold]

input=$(cat)

# Extract fields
cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
# Effort: same glyphs as Claude Code's own effort indicator; absent for models without effort
effort=$(echo "$input" | jq -r '
  (.effort.level // empty) as $l
  | ({low: "○", medium: "◐", high: "●", xhigh: "◉", max: "◈"}[$l] // "●")
    + " " + $l')
[ -n "$effort" ] && model="$model $effort"
used_pct=$(echo "$input" | jq -r '
  if .context_window == null then empty
  elif .context_window.used_percentage != null then .context_window.used_percentage
  elif .context_window.remaining_percentage != null then (100 - .context_window.remaining_percentage)
  else empty end')
# Prompt cache: expiry (epoch s) and tokens a cold cache would re-cache; empty when absent
cache_exp=$(echo "$input" | jq -r 'if .prompt_cache.caching_observed == true then (.prompt_cache.expires_at | if type == "number" then floor else "none" end) else empty end')
cache_recache=$(echo "$input" | jq -r '.prompt_cache.recache_tokens_if_cold | if type == "number" then floor else empty end')

# Folder: basename of cwd
folder=$(basename "$cwd")

# Git status. This runs on every refresh in every open session, so it must not take
# .git/index.lock, or a commit running at the same moment fails. git diff rewrites the
# index even with GIT_OPTIONAL_LOCKS=0; git status honors it, so one porcelain call
# gives both markers: column 1 is staged, column 2 unstaged. Untracked files don't count.
git_info=""
if git -C "$cwd" -c core.fsmonitor=false rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cwd" -c core.fsmonitor=false symbolic-ref --short HEAD 2>/dev/null \
           || git -C "$cwd" -c core.fsmonitor=false rev-parse --short HEAD 2>/dev/null)
  porcelain=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" -c core.fsmonitor=false \
              status --porcelain --untracked-files=no 2>/dev/null)
  dirty=""
  staged=""
  printf '%s\n' "$porcelain" | grep -q '^.[^ ]' && dirty="*"
  printf '%s\n' "$porcelain" | grep -q '^[^ ]' && staged="+"
  indicators="${dirty}${staged}"
  if [ -n "$indicators" ]; then
    git_info=" ($branch $indicators)"
  else
    git_info=" ($branch)"
  fi
fi

# ANSI colors (no \[ \] wrappers - status line is not a PS1)
reset=$'\033[0m'
lightgray=$'\033[0;37m'
white=$'\033[1;37m'
cyan=$'\033[36m'
yellow=$'\033[33m'
red=$'\033[31m'
dim=$'\033[90m'

# Cache segment: minutes until the prompt cache goes cold, or "cold" plus the
# tokens the next message would re-cache. Colored on its own: dim above 15 min,
# yellow from 15 to 5, red under 5 (a 5m TTL is therefore always red).
cache_segment=""
if [ -n "$cache_exp" ]; then
  now=$(date +%s)
  if [ "$cache_exp" != "none" ] && [ "$cache_exp" -gt "$now" ]; then
    mins=$(( (cache_exp - now + 59) / 60 ))
    if   [ "$mins" -lt 5 ];  then ccolor=$red
    elif [ "$mins" -le 15 ]; then ccolor=$yellow
    else                          ccolor=$dim
    fi
    cache_segment="${ccolor}${mins}m"
  else
    cache_segment="${dim}cold"
    if [ -n "$cache_recache" ]; then
      cache_segment="$cache_segment $(( (cache_recache + 500) / 1000 ))k"
    fi
  fi
fi

# Context bar segment (only when data is available), with the cache segment
# inside the same bracket: [bar pct% - cache]
ctx_segment=""
if [ -n "$used_pct" ]; then
  ctx_color=$(awk -v pct="$used_pct" -v cyan="$cyan" -v yellow="$yellow" -v red="$red" \
    'BEGIN { pct = int(pct + 0.5); if (pct >= 60) print red; else if (pct >= 30) print yellow; else print cyan }')
  ctx_segment=$(awk -v pct="$used_pct" -v color="$ctx_color" \
    'BEGIN {
      pct = int(pct + 0.5)
      filled = int(pct / 10 + 0.5)
      if (filled > 10) filled = 10
      empty = 10 - filled
      bar = ""
      for (i = 0; i < filled; i++) bar = bar "█"
      for (i = 0; i < empty; i++) bar = bar "░"
      printf " %s[%s %d%%", color, bar, pct
    }')
  if [ -n "$cache_segment" ]; then
    ctx_segment="${ctx_segment} · ${cache_segment}${ctx_color}"
  fi
  ctx_segment="${ctx_segment}]${reset}"
fi

printf "${lightgray}[${white}%s${lightgray}%s  %s${reset}]" \
  "$folder" \
  "$git_info" \
  "$model"
printf '%s' "$ctx_segment"
