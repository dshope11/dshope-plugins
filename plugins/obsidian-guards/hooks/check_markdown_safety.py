#!/usr/bin/env python3
"""PreToolUse guard: block markdown writes containing a known render-breaking token.

Catches three confirmed Obsidian/Dataview footguns in content destined for a .md
file (rule 3 is documented at LEADING_EQUALS_SPAN_RE below). The hook fails open
on any parse error so a legitimate write is never wedged.

1. Equals-only code span - an inline code span whose entire content is nothing
   but '=' characters: the single-equals span (backtick-equals-backtick) and the
   double-equals span (backtick-equals-equals-backtick) are both confirmed to
   trip Dataview's inline-field parser ("(inline field ''): PARSING FAILED") and
   silently break rendering for the rest of the block. Longer spans that contain
   a non-'=' char (`<=`, `>=`, `a = b`) and a bare equals in prose are all fine;
   the '==' span was previously believed safe but was observed breaking a daily
   note (2026-07-04), so it is now blocked alongside the lone-equals span.

2. Highlight-pattern double-equals - a `==X==` sequence where the markers hug
   non-space text (the literal Obsidian highlight markup). Two such markers on a
   line get paired by the highlight/Dataview parser, even across inline-code
   boundaries, into a runaway highlight that breaks rendering (this fired on a
   changelog bullet that described the bug using the literal tokens). A SPACED
   comparison like `a == b`, a standalone `==`, and `===`/`!==` operators are all
   left alone - only the no-space highlight shape `==word ... word==` is blocked.

Reads the PreToolUse hook payload on stdin, inspects the content destined for a
.md file (Write.content / Edit.new_string / MultiEdit edits), and exits 2 (block,
with stderr fed back to the model) if an offending token is present.
"""
import json
import re
import sys

# 1. Equals-only code spans: a span whose entire content is one or more '='.
#    Both the single- and double-equals forms are confirmed render-breakers.
EQUALS_ONLY_SPANS = ("`=`", "`==`")

# 2. Highlight markup: '==' hugging at least one non-space, non-'=' char on each
#    side. Matches '==x==', '==...==', and the runaway cross-span case
#    '==needle` ... `==' ; does NOT match spaced 'a == b', a standalone '==',
#    or '===' / '!==' (the char after the opening '==' would be space or '=').
HIGHLIGHT_RE = re.compile(r"==[^\s=][^=]*==")

# 3. Leading-'==' code span: a span whose content OPENS with '==' (backtick
#    immediately followed by '==' then a non-backtick, non-'=' char), e.g.
#    `== target`, `== k`, `==foo`. The opening '==' reads as a stray Obsidian
#    highlight marker even inside backticks and breaks rendering for the rest of
#    the block (observed on a daily note, 2026-07-21). This sits in the seam
#    between rules 1 and 2: it is neither an equals-only span (it has other text)
#    nor a hugging '==x==' highlight (no closing '=='). Excludes `==` (rule 1)
#    and `===`/`====` operators (the char after '==' would be a backtick or '=').
LEADING_EQUALS_SPAN_RE = re.compile(r"`==[^`=]")


def find_issues(text: str) -> list[str]:
    issues = []
    if any(span in text for span in EQUALS_ONLY_SPANS):
        issues.append(
            "equals-only code span (`=` or `==`): a code span whose entire content "
            "is only '=' chars breaks Dataview ((inline field ''): PARSING FAILED) "
            "and swallows the rest of the block. Fix: write the word ('equals', "
            "'exact-equality') or fold it into a longer span (e.g. `a = b`)."
        )
    if HIGHLIGHT_RE.search(text):
        issues.append(
            "highlight-pattern '==X==': a double-equals hugging text reads as "
            "Obsidian highlight markup; two on a line (even inside backticks) "
            "pair into a runaway highlight that breaks rendering. Fix: don't "
            "reproduce the token literally - describe it in words "
            "('double-equals'), or space the operator (`a == b`)."
        )
    if LEADING_EQUALS_SPAN_RE.search(text):
        issues.append(
            "leading-'==' code span (`== target`, `== k`, `==foo`): a span whose "
            "content opens with '==' reads as a stray Obsidian highlight marker "
            "and breaks rendering for the rest of the block. Fix: don't start a "
            "code span with '==' - embed the operator (`count == k`), or describe "
            "it in words (exact-equality, `x == target`)."
        )
    return issues


def main() -> int:
    try:
        data = json.load(sys.stdin)
    except Exception:
        return 0  # fail open - never block on a malformed payload

    tool = data.get("tool_name", "")
    ti = data.get("tool_input", {}) or {}
    fp = ti.get("file_path", "") or ""

    if not fp.endswith(".md"):
        return 0

    texts = []
    if tool == "Write":
        texts.append(ti.get("content", "") or "")
    elif tool == "Edit":
        texts.append(ti.get("new_string", "") or "")
    elif tool == "MultiEdit":
        for edit in ti.get("edits", []) or []:
            texts.append(edit.get("new_string", "") or "")
    else:
        return 0

    issues = []
    for t in texts:
        issues.extend(find_issues(t))

    if issues:
        sys.stderr.write(
            f"BLOCKED: markdown render-breaking token in {fp}.\n"
            + "".join(f"- {msg}\n" for msg in issues)
            + "Rewrite the token as described above and retry the write.\n"
        )
        return 2

    return 0


if __name__ == "__main__":
    sys.exit(main())
