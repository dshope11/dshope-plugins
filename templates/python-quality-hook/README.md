# Python quality hook (template)

After every `Edit` or `Write`, run `ruff check --fix`, the pytest suite and mypy, and hand any
failure straight back to Claude in the same turn. It ships as a template rather than a plugin
because the paths and the interpreter are project-specific.

## Install

1. Copy `check.sh` to `.claude/hooks/check.sh` in your project and make it executable.
2. Merge `settings.json` into your project's `.claude/settings.json`.
3. Point `PROJECT_PYTHON` at the interpreter that has ruff, pytest and mypy (a conda or venv
   `bin/python`), or leave it unset to use `python3` from `PATH`. Adjust the `src/` and `tests/`
   paths in `check.sh` to match your layout.

## Why it exits 2

A `PostToolUse` hook that prints its results and exits 0 is invisible to the model: Claude Code
sends plain stdout to the debug log. Exit code 2 sends stderr to Claude. So the script is silent
when everything passes and speaks only on failure, which also keeps passing runs out of the
context window.
