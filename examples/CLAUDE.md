# My global CLAUDE.md, annotated

This is an excerpt of `~/.claude/CLAUDE.md`, which loads into every Claude Code session I run, in
every repo. The full file is about 350 lines and private. Below is its outline, then four of its
rules, shortened and with names and dates removed, each followed by the incident behind it.

Much of the file wasn't planned. The longer rules each came out of something going wrong and
note what happened, so a later reader (me or the model) can judge whether a rule still applies.

## Outline

| Section | What it holds |
|---|---|
| Who I Am | Background, current level, target roles, so the model calibrates explanations instead of guessing |
| How to Work with Me | Skip the basics, use industry framing, don't overstate my ML depth, push back on completionism, be concise, and suggest a higher effort level before high-stakes work |
| Hardware | The laptop runs PyTorch on MPS, not CUDA, so CUDA-only ops get flagged |
| Git Behavior | Ask before every commit |
| Programming Environment | Languages and tooling |
| Character Encoding Conventions | ASCII only in source code, LaTeX math in rendered READMEs, and a table of replacements |
| Spelling: US English, always | Below |
| Text Suggestions for Human Typing or Sending | Anything I'll paste uses keyboard characters only, with one line per paragraph |
| Voice rules | Five rules for prose I send as myself, each learned from a draft I revised (see the `voice-loop` plugin) |
| Email Access | A read-only mail CLI, and a standing rule never to send on my behalf |
| File edits | Below |
| Claude Code config | Skills, hooks, settings and this file live in a private repo installed by symlinks; this public repo is exported from it |
| Claude Code paths | Personal file locations that published skills look up by key |
| Name the thing, don't refer to it | Below |
| Working Style Notes | My pull toward closing every loop, and an instruction to push back on it |
| Active Projects | Where each project's own context lives |

## Four rules

### Name the thing, don't refer to it

> **Do not use a definite noun phrase for a decision, rule, correction, or finding that I could
> not identify from the current conversation alone.** State the thing instead of labeling it.
>
> **The tell:** a definite article in front of a noun phrase naming a *decision* rather than an
> object - *the* retired trigger, *the* dated rule, *the* correction, *the* audit finding, *the*
> gap - with no antecedent in the current conversation.
>
> **The fix is a rewrite, not an addition**, and it usually costs nothing. "The retired trigger"
> becomes "the rule we set yesterday to nudge a contact if their company went quiet past the
> 21st".
>
> **This does NOT mean explaining everything.** Spelling out all context makes responses longer
> and worse. The rule is narrow: it applies to referring expressions with no antecedent, not to
> background generally.
>
> **Standing trigger: whenever I point out a reference I couldn't identify, log it as an
> instance.** This class can't be self-detected - the sentence looks complete from the writing
> side, because the writer has the referent - so my flag is the only detector there is.

**Why it's there.** A briefing told me "the retired trigger is worth keeping the shape of rather
than just deleting." Every word was accurate, but the trigger had been set in a different session
and nothing in this one had introduced it. It was the first logged instance of something I'd
noticed repeatedly. The model's notes and its memory live in the same place, so after a session of
writing there, a term that's precise on the page starts acting as if it were shared. It isn't. I
haven't read the page; I'm being briefed on it. Two days later, with the rule already in place, a
prep briefing was organized around question numbers I'd never been shown.

### File edits: use Edit/Write, never shell redirection

> When changing a file, use the **Edit** or **Write** tools - not `sed -i`, not a heredoc, not a
> Python script that rewrites the file.
>
> - **The diff renders in real time.** A shell command that mutates a file shows me nothing.
> - **`PreToolUse` hooks only fire on Edit/Write/MultiEdit.** A shell write silently skips any
>   guardrail hooked there.
>
> **Mutations only.** Reading and searching through Bash is fine. **This outranks any general
> "prefer Bash" session preference, including auto mode.** Where it's genuinely impractical - a
> computed insert, one transform across many files - say so in one line and proceed.

**Why it's there.** It started in one repo's `CLAUDE.md` and was ignored for a whole session in
that same repo: an auto-mode directive preferring Bash was followed instead, and the conflict was
never surfaced. So it moved to the global file, with a line saying explicitly that it outranks
the session-level preference.

### Claim only what I personally did (voice rule 5)

> Never pair a skill I did with one I was only exposed to, and never let a list of named subfields
> imply command of a field. Claim the half I can defend on a follow-up question and drop the rest.
> **Test: check each item in a claim separately - could I describe my own hands-on part in it?**
> If I only used it, sat near it, or read about it, cut it or say what my real contact was.
> **Applies to cover-letter bodies too** - unlike two of the other voice rules, no carve-out.

**Why it's there.** Two drafts six days apart made the same move. One listed three named efforts
in a field where my real contact was a single paper I'd referenced, and I rewrote it to name that
paper. The other paired "distributed processing and multi-threading", where I'd done the first
and only been exposed to the second, and I cut the second. Neither sentence was false as a whole,
which is why a sentence-level check passes it: Claude's own pre-send fact check on the second one
cut a different claim from that sentence and left multi-threading standing. The second instance
is what made it a rule.

### Spelling: US English, always

> Every word written for me is US English: applications, messages, READMEs, code comments,
> commit messages. A British spelling in a cover letter reads as careless, or as text lifted from
> somewhere else. **Check before shipping, don't trust the eye:** grep the rendered text for
> British forms. **Read the rendered prose end to end before declaring a letter done** - page
> count and a spelling grep don't catch grammar.

**Why it's there.** I spent six years at European universities inside a CERN collaboration that
writes British English, so my source material uses British spellings, and copying a phrase from
it carries the spelling along. "Programme" reached a finished, page-verified cover letter, and I
caught it on my own read; no check in the pipeline did. The same read turned up a wrong
preposition, a sentence missing its complement, and a dropped relative pronoun. Those three are
why the rule pairs the grep with a full read.
