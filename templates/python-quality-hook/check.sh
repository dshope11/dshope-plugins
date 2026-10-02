#!/usr/bin/env bash
# PostToolUse hook: after every Edit/Write, run ruff --fix, pytest and mypy.
#
# Silent when all three pass. On any failure it prints the failing output to
# stderr and exits 2: for PostToolUse that is how text gets back to Claude in
# the same turn. Plain stdout on exit 0 only reaches the debug log, so a hook
# that just prints its results is invisible to the model.
#
# PROJECT_PYTHON selects the interpreter (e.g. a conda env's bin/python), so the
# hook doesn't depend on shell init. Adjust the paths below to your layout.

PY="${PROJECT_PYTHON:-python3}"
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

report=""
run() {  # run <label> <command...>
  local label="$1" out
  shift
  if ! out="$("$@" 2>&1)"; then
    report+="== $label failed"$'\n'"$(printf '%s\n' "$out" | tail -30)"$'\n'
  fi
}

run ruff   "$PY" -m ruff check src/ tests/ --fix
run pytest "$PY" -m pytest tests/ -x -q --tb=short
run mypy   "$PY" -m mypy src/ --ignore-missing-imports

[ -z "$report" ] && exit 0
printf '%s' "$report" >&2
exit 2
