---
name: neetcode
description: Run one full NeetCode problem cycle interview-style - discuss the approach, gate on a sound solution, then (after the user accepts it on neetcode.io) pull the auto-commit, review the code, and log the solve. Use when the user wants to work a NeetCode problem.
allowed-tools: Bash, Read, Edit, Grep
---

Drive one complete problem cycle for Phase B of the DSA prep (see `wiki/topics/coding-interview-prep.md`). This is the per-**problem** loop.

**The pattern page is written AFTER the first solve, never before.** If the section is brand new (no `wiki/concepts/<pattern>.md` yet), do **not** create it up front - run this loop on the section's first problem with only the **foundation page** (the "Builds on" column of the Patterns table) in hand, and create the pattern page in Phase 3 (step 12), grounded in the solve that just happened. Rationale on the hub page: a page written up front is abstraction-first (it explains the pattern in the vocabulary of someone who already has it) and it pre-spoils the section's own warm-up problems.

Argument (optional): a problem name or LeetCode number. If omitted, propose the next unsolved problem from the **Problem Plan** in `wiki/topics/coding-interview-prep.md` (Blind-75 first within the current section) and confirm it with the user.

**Interviewer stance (applies to the whole discussion phase):** act like a real interviewer, matching the user's quiz-session style. Probe out loud, push on edges, flag strong talking points. **Do NOT reveal the optimal approach or hand over code** - lead the user there with Socratic questions. Only volunteer a technique the user explicitly asks about (e.g. "how does `Counter` work?"). Confirm complexity and correctness by getting the user to state them, not by stating them for him.

---

## Phase 0 - Setup

1. Resolve the problem (from the argument, or propose the next from the Problem Plan and confirm). Note its LeetCode number, difficulty, and `[B]` status.
2. Identify the section's **concept page** from the Patterns table in `wiki/topics/coding-interview-prep.md` (e.g. Arrays & Hashing -> `wiki/concepts/arrays-and-hashing.md`). **If it does not exist yet, this is the section opener** - that is expected and correct (see the rule above); use the **"Builds on" foundation page** instead, and note that the pattern page is this cycle's step-12 deliverable.
3. **Prime yourself for accurate feedback:**
   - **Read the concept page** - recognition triggers, templates, gotchas - so the interview pushes the canonical patterns, not improvised ones. (Section opener: read the foundation page instead.)
   - **Fetch the neetcode.io problem page and take the constraints from it - REQUIRED, not best-effort.** `WebFetch https://neetcode.io/problems/<slug>/question` renders fine despite the site being JS-heavy; it returns the statement and the full `Constraints:` block. **NeetCode's constraints are frequently tighter than LeetCode's for the same problem, and NeetCode is the judge the user actually submits to, so NeetCode's bounds govern every complexity and feasibility argument in the cycle.** Never quote a bound from LeetCode, from the `neetcode-gh` mirror, or from memory - those are a different problem statement wearing the same number. (Worked example: Course Schedule is `numCourses <= 2000, prerequisites.length <= 5000` on LeetCode but **`<= 1000` and `<= 1000`** on NeetCode.) If the fetch genuinely fails, **ask the user to paste the constraints** rather than substituting LeetCode's.
   - **Scan the official/reference solution (best-effort).** Try, in order: the public `neetcode-gh/leetcode` GitHub mirror, or a web search. If none is fetchable, fall back on well-established canonical knowledge of the problem. This is to calibrate your guidance against the intended optimal - **never reveal or hint at it during Phase 1.** It is for your own accuracy only. Note the mirror is LeetCode-shaped: use it for the *approach*, never for bounds.

## Phase 1 - Interview discussion (BEFORE the user implements)

4. Ask the user to restate the problem and propose an approach with its time/space complexity, narrating as in an interview.
5. Interview the approach (Socratic, no spoilers). Make sure these are covered before greenlighting:
   - **Brute force first, then optimize** - get the naive approach + its Big-O on the table, then push for the improvement.
   - **Edge / corner cases** (empty input, single element, duplicates, length mismatch, etc.).
   - **Cheap early-bail checks** (e.g. unequal lengths -> immediate `False`).
   - **Time AND space complexity**, including assumption caveats (e.g. "O(1) space *if* the alphabet is fixed; O(k) for arbitrary Unicode").
   - **Data-structure choice** and *why* (e.g. `set` for pure membership vs `dict` when a value/index is needed).
   - **A common follow-up** the interviewer would ask (e.g. "can you do it in O(1) space?" -> sort-first trade).
6. When the approach, edge cases, and complexity are sound, **say so explicitly** and tell the user to implement it on **neetcode.io**. They code **only the optimal solution** (no need to paste anything else) - the alternative implementations get added as comments later, by you, in Phase 3 after the pull. Then **STOP and wait** - the user will report back when the solution is accepted.

## Phase 2 - Implementation (the user, on neetcode.io)

7. (No action - the user solves on the platform, whose judge runs the tests, and says when it is accepted.)

## Phase 3 - Review & capture (AFTER the user says it is accepted)

8. Pull the auto-committed solution:
   ```
   git -C ~/neetcode-submissions pull
   ```
   If `~/neetcode-submissions` is not cloned yet, clone it first:
   `git clone https://github.com/dshope11/neetcode-submissions.git ~/neetcode-submissions`.
9. Find the file the pull just added (NeetCode uses its **own slug**, not the LC number, so don't guess the path):
   ```
   git -C ~/neetcode-submissions diff --name-only ORIG_HEAD HEAD
   ```
   If nothing changed, the auto-sync may not have fired - tell the user to check GitHub Sync (and that it is set to **accepted-only**). For a **re-solve**, the new file is a higher `submission-N.py` in the same problem folder; review it by `diff`-ing against the prior submission (spaced-review signal).
10. Read the new submission and **code-review it interview-style** (as done for prior problems):
    - Correctness + does it match the agreed approach.
    - **Conventions** per `~/.claude/CLAUDE.md`: `snake_case` for variables/functions, `PascalCase` only for classes; no Unicode in source; PEP 8.
    - **Type hints** (the user's standing habit): the **active curated code must be fully type-annotated** - parameters and return types on every method **and on the nested helper `def`s** (e.g. `def dfs(node: Optional[TreeNode]) -> None:`, `def dfs() -> Optional[TreeNode]:`). neetcode.io pre-imports the typing names, so a typed submission may omit the `from typing import ...` line; add it in the curated file so it is honest/portable, and note the omission in the header the same way `Optional` is already handled. If the user's typed submission lacks hints (or only types the outer methods), **add them in the active code** and list "added type hints incl. nested helpers" as one of the "What changed" items. Alt 1 stays verbatim (do not add hints to the preserved submission).
    - Pythonic idioms / simplifications (`Counter`, `dict.get`, `defaultdict`, comprehensions, etc.).
    - At least one **sharp insight** (a subtle correctness dependency, a hidden assumption, a complexity nuance).
    - Confirm the stated complexity actually holds.
10a. **Discuss the improvements with the user, then bake them in.** After the review, walk the user through how the submitted code can be improved - both **logic/algorithm** cleanups (redundant state, an O(1) crossing check vs a snapshot, a tighter loop shape) and **style** (naming, `.get` vs `Counter`, dead inits, PEP 8). Agree on which to apply. The **cleaned/improved version becomes the active code** in the curated file (the user's default; confirm if unsure), and **the user's verbatim accepted submission is preserved as the first commented alternative (Alt 1)** so the practice record stays honest. The curated file must **document every change** from the typed submission to the cleaned active code (a "What changed" comment block). Any convention slips in the typed version are noted there too - they're fixed in the active cleaned code, and visible in the preserved Alt 1.
10b. **Write the curated copy** (the durable, organized home - full convention in `neetcode-submissions/solutions/README.md`). The repo has **two zones**: the **raw zone** `Data Structures & Algorithms/<neetcode-slug>/submission-N.py` is NeetCode's automated, verbatim dump - **leave it 100% untouched**; the **curated zone** `solutions/<NN-pattern>/<LLLL-slug>.py` is hand-maintained. They never collide because Sync only writes under `Data Structures & Algorithms/`. Create (or, for a re-solve, update) the curated file:
    - **Path:** `NN` = the pattern's NeetCode-roadmap order from the Patterns table in `wiki/topics/coding-interview-prep.md` (zero-padded 2 digits); `LLLL` = zero-padded 4-digit LC number; `slug` = kebab problem name. E.g. `solutions/01-arrays-and-hashing/0049-group-anagrams.py`.
    - **Header comment:** problem name + LC + pattern + list; `Solved <date> | outcome: <marker>`; a `# Raw:` pointer to the verbatim submission path; a note that the active code is the **cleaned** version (per step 10a); and any **style notes** on the typed submission (they're fixed in the active code and preserved in Alt 1).
    - **Cleaned/improved solution active** (the agreed cleanups from step 10a applied, and **fully type-annotated including nested helpers** per the typing convention in step 10), plus a **"What changed" comment block** listing each improvement over the typed submission.
    - **Alt 1 = the user's accepted submission, verbatim** (the honest practice record), as a commented block. **Every other instructive implementation** follows as its own commented block, each with a one-line `# <name>: O(...) time, O(...) space` annotation (+ assumption caveats). Two-to-three alternatives is the common case (verbatim typed + brute force, plus any genuinely distinct variant - a one-liner, an O(1)-space form, the official reference). Capture the approaches reasoned in Phase 1 - don't invent filler.
    - **Re-solve:** update the existing curated file, repoint `# Raw:` at the new `submission-N.py`, and note what changed.
    Then **commit + push** to `neetcode-submissions` (write the message to a temp file, `git commit -F`; uncommitted local edits would otherwise pile up against the auto-sync).
11. **Log the solve** on the concept page's solve-log table. Fill the row: date (run `date +%Y-%m-%d`), outcome, and a short note. **Confirm the outcome marker with the user** rather than assuming - `solo` (no help) / `hint` (a nudge) / `looked-up` (read the solution). Optionally add a light time estimate if the user is tracking it.
12. **Distill only *new* reusable templates/gotchas** onto the concept page (Templates or Gotchas section). Do not duplicate what is already there - the concept page is the durable knowledge home; commented alternatives in the solution file are convenience only.
    - **Section opener (no pattern page yet): this is where you create it.** Scaffold with `obsidian create name="<pattern>" path="wiki/concepts" template="Wiki Concept Template"`, then write it **bottom-up from the problem just solved** - lead with the concrete solve and generalize outward from it, rather than opening with the pattern's abstract statement. Cover only what the solve actually earned; leave the rest of the section's techniques as named stubs to be filled in as their problems land. Then do the usual link enrichment, `wiki/index.md` row, and `wiki/log.md` entry, and flip the Patterns-table row to `learning`.
13. If a genuine new gotcha/bug surfaced, **offer to add it to the bugs table** in `wiki/topics/interview-prep.md` (per the user's standing rule).
14. **kata-py promotion watch.** This is a *watch, not a per-problem action*. When a pattern's **template has crystallized** - the same reusable skeleton has now shown up reliably across several problems (e.g. sliding-window skeleton, binary-search bounds, Kadane's, complement-map) and is muscle-memory-worthy - **offer to promote that template into `kata-py`** (`~/kata-py`) as a kata: stub + solution + test, per its README. Promote the *template*, never an individual problem (individual NeetCode problems stay in `neetcode-submissions`; kata-py is the cold-drill harness for stabilized skeletons only). If no template has stabilized this cycle, skip silently.
15. **Log to the daily note.** Append a `- [x]` activity bullet to the current time block (Morning < 12:00, Afternoon 12:00-16:59, Evening 17:00+) of `Daily Notes/<today>.md`, noting the problem, approach, and any concept covered. Wiki-page edits go under that block's `### wiki activity` subsection; the solve itself is a normal activity bullet above it.
16. **Coverage-tracker check.** If the section now has enough problems done to change its confidence, propose bumping its status in the Patterns table of `wiki/topics/coding-interview-prep.md` (`learning` -> `solid`).
17. **Settle the next problem, then offer to close the session with it.** Two beats, in this order - the order is the point:
    a. **Propose the next problem** (next Blind-first in the section) and **get the user's answer**. They may take the proposal, pick a different one, or say they're not continuing. Do not skip ahead to (b) on an assumed answer.
    b. **Then offer `/wrap --handoff`** as a single closing action, seeded with whatever was agreed in (a). Phrase it as one offer, not two: `/wrap` runs the checkpoint daily-note logic and commits the vault, and `--handoff` emits a resume prompt whose "what's next" is that agreed problem.
    **Do not offer a bare vault commit here** - `/wrap` already commits, so a separate commit offer just splits the same work into two prompts. The one thing `/wrap` does **not** do is push, so mention `/push` as a separate follow-up if the vault has unpushed commits.
    If the user declines the next problem or wants to stop, still offer `/wrap` (with or without `--handoff` as they prefer) - the session's work needs committing either way.

---

## Rules

- **Never spoil the solution in Phase 1.** Probing questions only, until the user has it or explicitly asks for a specific technique.
- Solve on **neetcode.io** (its free judge covers Premium-locked problems); the accepted (optimal) solution auto-syncs verbatim to the **raw zone** (`Data Structures & Algorithms/`) of `neetcode-submissions` - never hand-edit that zone. the user pastes nothing extra; in Phase 3 (steps 10a-10b) you discuss improvements, then write the enriched **curated copy** under `solutions/<NN-pattern>/<LLLL-slug>.py` (cleaned optimal active + "what changed" block + header + commented alternatives, Alt 1 being the verbatim typed submission) and commit + push it.
- **The active curated code is the cleaned/improved version** (agreed in step 10a); **the user's verbatim accepted submission is preserved as commented Alt 1** so the practice record stays honest, and every change from it to the active code is documented in a "what changed" block. Style slips in the typed version are fixed in the active code, not left in place.
- Preserve `# My Notes` and `> [!personal]` callouts on any wiki page (per project CLAUDE.md) - append above them, never overwrite.
- Obey the markdown-safety rules in the project CLAUDE.md when editing `.md` files (the PreToolUse hook enforces the worst footguns, but the wikilink-in-table-cell and bare-`<`-in-prose rules are on you).
- Do not invent a solve outcome - confirm it with the user.
