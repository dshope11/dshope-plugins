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
# Plan usage (subscription plans only): 5-hour session and 7-day weekly, percent used,
# rounded (the weekly figure keeps one decimal when there is one); empty when Claude Code
# has no usage data yet
limit_5h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty | . + 0.5 | floor')
limit_7d=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty | . + 0.5 | floor')
reset_5h=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty | floor')
raw_7d=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
reset_7d=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty | floor')

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

# Usage-limit segment: [5h pct% (time to reset) · wk pct% (pace)]. Only the percentages
# and the pace are colored; labels and the reset time stay dim. Percentage thresholds
# follow the claude.ai usage page (under 75, from 75, from 90), in the same cyan, yellow
# and red as the context bar. Shows whichever windows were reported.
limit_color() {
  if   [ "$1" -ge 90 ]; then printf '%s' "$red"
  elif [ "$1" -ge 75 ]; then printf '%s' "$yellow"
  else                       printf '%s' "$cyan"
  fi
}
# Weekly pace: how many days of usage ahead of (+) or behind (-) an even spread across
# the 7-day window (window start = reset time - 7 days). Gray at or under pace, yellow
# up to half a day ahead, red beyond that. Half a day is the overnight catch-up: spending
# one day's share across a 9am-9pm workday peaks at +0.5 and the 12 hours off bring it
# back to 0, so past +0.5 the next day starts in deficit. Printed as "(+0.4 days)".
pace_segment=""
if [ -n "$raw_7d" ] && [ -n "$reset_7d" ]; then
  pace_segment=$(awk -v used="$raw_7d" -v reset="$reset_7d" -v now="$(date +%s)" \
    -v dim="$dim" -v yellow="$yellow" -v red="$red" \
    'BEGIN {
      week = 7 * 86400
      elapsed = (now - (reset - week)) / 86400
      if (elapsed < 0) elapsed = 0; if (elapsed > 7) elapsed = 7
      d = used / 100 * 7 - elapsed
      s = sprintf("%+.1f", d); if (s == "-0.0") s = "+0.0"
      color = (d <= 0) ? dim : (d <= 0.5 ? yellow : red)
      printf "%s(%s days)", color, s
    }')
fi
limits_segment=""
if [ -n "$limit_5h" ]; then
  limits_segment="${dim}5h $(limit_color "$limit_5h")${limit_5h}%${dim}"
  if [ -n "$reset_5h" ]; then
    left=$(( reset_5h - $(date +%s) ))
    if [ "$left" -gt 0 ]; then
      mins=$(( (left + 59) / 60 ))
      if [ "$mins" -ge 60 ]; then
        limits_segment="${limits_segment} ($(( mins / 60 ))h$(printf '%02d' $(( mins % 60 )))m)"
      else
        limits_segment="${limits_segment} (${mins}m)"
      fi
    fi
  fi
fi
if [ -n "$limit_7d" ]; then
  # Weekly percent gets one decimal when Claude Code reports a fraction (as of 2026-10 it
  # sends whole numbers, so this prints "5%"); the rounded integer still drives the color
  disp_7d=$(awk -v p="$raw_7d" 'BEGIN { if (p == int(p)) printf "%d", p; else printf "%.1f", p }')
  [ -n "$limits_segment" ] && limits_segment="${limits_segment}${dim} · "
  limits_segment="${limits_segment}wk $(limit_color "$limit_7d")${disp_7d}%"
  [ -n "$pace_segment" ] && limits_segment="${limits_segment} ${pace_segment}"
fi
[ -n "$limits_segment" ] && limits_segment="${dim}[${limits_segment}${dim}]${reset}"

left_part=$(printf "${lightgray}[${white}%s${lightgray}%s  %s${reset}]%s" \
  "$folder" "$git_info" "$model" "$ctx_segment")

# Right-align the usage segment. Claude Code passes the terminal width in COLUMNS;
# without it, or when the line is too narrow, the segment follows the context bar.
visible_len() {
  printf '%s' "$1" | sed $'s/\033\\[[0-9;]*m//g' | LC_ALL=en_US.UTF-8 wc -m | tr -d ' '
}
printf '%s' "$left_part"
if [ -n "$limits_segment" ]; then
  margin=4  # Claude Code indents the status line; keep clear of the right edge
  pad=$(( ${COLUMNS:-0} - $(visible_len "$left_part") - $(visible_len "$limits_segment") - margin ))
  [ "$pad" -lt 2 ] && pad=1
  printf '%*s%s' "$pad" '' "$limits_segment"
fi
