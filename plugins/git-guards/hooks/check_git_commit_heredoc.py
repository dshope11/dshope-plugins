#!/usr/bin/env python3
"""PreToolUse guard: block fragile inline-message git commits.

Building a multi-line commit message inline - `git commit -m "$(cat <<'EOF'
... EOF)"` - is re-parsed by this harness's eval layer, where apostrophes,
backticks, and `$` in the body break the command (a recurring failure). The
robust path has zero shell quoting: write the message with the Write tool to a
temp file, then `git commit -F <file>`.

This hook reads the PreToolUse Bash payload on stdin and exits 2 (block, with
stderr fed back to the model) when a `git commit` command contains a heredoc.
Plain `git commit -m "short message"` and `git commit -F <file>` are untouched.
Fails open on any parse error so it never wedges a legitimate command.
"""
import json
import re
import sys


def main() -> int:
    try:
        data = json.load(sys.stdin)
    except Exception:
        return 0  # fail open

    if data.get("tool_name") != "Bash":
        return 0

    cmd = (data.get("tool_input", {}) or {}).get("command", "") or ""

    if not re.search(r"\bgit\s+commit\b", cmd):
        return 0

    # A heredoc is the recurring fragile construction. `<<` also covers `<<-`
    # and `<<'EOF'`. Note: `<<<` (here-string) would match too, but it's not
    # used for commit messages, so the rare false positive is acceptable.
    if "<<" in cmd:
        sys.stderr.write(
            "BLOCKED: git commit with a heredoc is fragile in this harness - "
            "apostrophes, backticks, and $ in the body get re-parsed by the "
            "eval layer and break the command.\n"
            "Instead, with zero shell quoting: write the message to a temp file "
            "with the Write tool, then run:\n"
            "  git commit -F /tmp/commit_msg.txt\n"
            "For a true one-liner, plain git commit -m \"short message\" is fine.\n"
        )
        return 2

    return 0


if __name__ == "__main__":
    sys.exit(main())
