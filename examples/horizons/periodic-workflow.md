# Periodic Notes - Shared Workflow Spec

This is the single source of truth for the vault's periodic notes. It is not a skill of its own: `/horizons` and the eight phase commands (`weekly-outlook`, `weekly-reflection`, ...) all read it, so refining the practice means editing this one file.

## Core idea: the intention -> review loop

Every period note has two sections written at **different times**:

- **`# Outlook`** - written at the **start** of a period. Forward-looking intentions: what to prioritize, how to spend the period, and (weekly/monthly) a realistic schedule.
- **`# Reflection`** - written at the **end** of the period. A review that **grades against the Outlook set at the start**.

Outlook is set before the period and Reflection after, so the reflection can honestly measure against intentions. Never generate both in the same pass. Never write a Reflection without first reading the Outlook it is graded against.

## Phases

| Phase | Writes | Reads | Must preserve |
|-------|--------|-------|---------------|
| **outlook** | the `# Outlook` section only | previous same-tier Reflection (carry-forward), parent-tier current Outlook, profile/job-search context, (weekly) live TODO backlog | `# Reflection`, `# My Notes`, any `> [!personal]` callouts |
| **reflection** | the `# Reflection` section only | the existing `# Outlook` (intentions), what actually happened (lower-tier notes + git) | `# Outlook`, `# My Notes`, any `> [!personal]` callouts |

**Preservation is non-negotiable.** A phase edits only its own section. Never overwrite the whole file. Never touch `# My Notes` or `> [!personal]` callouts (same rule as wiki pages - see the vault `CLAUDE.md`). Replace only the content between the section's `#`-level heading and the next `#`-level heading (or EOF).

## Give your opinion (core requirement)

These notes are a thinking partner, not a transcription service. Every outlook and reflection includes your own assessment, not just a summary:

- **Outlook** - recommend what to work on next and how to spend the period. For weekly and monthly, propose a concrete schedule the user could plausibly keep *and be happy with*, not an aspirational over-packed plan. Flag conflicts between stated priorities and available capacity.
- **Reflection** - grade honestly against the Outlook: what got done, what slipped and likely why, what to carry vs. drop. Be direct; candor over cheerleading. **Downstream consumer:** `/sod` reads completed weeks' `# Reflection` sections to credit month-to-date progress, so name concrete outputs (apps submitted, follow-ups sent, problems solved). If the format is ever restructured, keep a legible record of completed work.

## Always

- **Draft -> review -> write, one note at a time.** Show the drafted section in the terminal and get confirmation before writing the file. When a run covers several notes (e.g. `/horizons`), finish the whole loop for one note - drafted, confirmed, written, logged - before drafting the next; never batch drafts into one message. The yearly reflection warrants more back-and-forth than the others.
- **Voice: these are the user's notes.** Write from their perspective, not Claude's - "What Surprised Me" means what surprised *the user*. Draft in that voice from the evidence, and keep Claude's own assessment to the give-your-opinion content.
- **Link to wiki pages where useful.** When a note mentions a concept, entity, person, or topic that has a wiki page, add a display-text wikilink (`[[path|Name]]`), per the vault's cross-linking rules. Don't force it, and never invent links to pages that don't exist.
- After writing, append one line to `wiki/log.md`:
  `## [TODAY] <phase>-<tier> | <period-id>` (e.g. `## [2026-05-31] reflection-weekly | 2026-W22`). TODAY = `date +%Y-%m-%d`.
- All paths are under `~/vault/`.

---

## Tier definitions

Date commands are macOS/BSD `date`.

### weekly
- **Period id:** ISO week, `date +%G-W%V` (e.g. `2026-W22`).
- **File:** `Weekly Notes/<id>.md`
- **Template:** `Templates/Weekly Notes Template.md`
- **Range:** Monday -> Sunday. Monday = `date -v-$(( $(date +%u) - 1 ))d +%Y-%m-%d`; Sunday = Monday + 6 days.
- **Outlook reads:** previous week's Reflection (carry-forward), the current month's Outlook (alignment), and the live `# TODO` backlog + persistent carries from the most recent daily note(s).
- **Reflection reads:** the 7 daily notes Mon-Sun (`Daily Notes/YYYY-MM-DD.md`, skip missing) - completed `- [x]` across Morning/Afternoon/Evening, `# Meetings`, `# Misc.`, recurring unchecked `# TODO` items; plus `git -C ~/vault log --since=MONDAY --until="SUNDAY 23:59" --oneline --no-merges`.
- **Reflection subheadings:** `## Wins`, `## Carried Forward`, `## Notes`, `## Day by Day`.

### monthly
- **Period id:** `date +%Y-%m` (e.g. `2026-05`).
- **File:** `Monthly Notes/<id>.md`
- **Template:** `Templates/Monthly Notes Template.md`
- **Range:** 1st -> last day of month.
- **Outlook reads:** previous month's Reflection, the current quarter's Outlook.
- **Reflection reads:** this month's weekly Reflections (a weekly note belongs to the month its Monday falls in); fall back to daily notes if fewer than 2 weeklies exist, and say so.
- **Reflection subheadings:** `## ML / AI Progress`, `## Career`, `## Personal`, `## What Surprised Me`, `## Week by Week`. Skip a section if there is genuinely nothing to report (never the timeline).

### quarterly
- **Quarters are CALENDAR quarters:** Jan-Mar = Q1, Apr-Jun = Q2, Jul-Sep = Q3, Oct-Dec = Q4. Map from `date +%-m`.
- **Period id:** `YYYY-Qn` (e.g. `2026-Q2`).
- **File:** `Quarterly Notes/<id>.md`
- **Template:** `Templates/Quarterly Notes Template.md`
- **Range:** the 3 months of the quarter (Q2 = Apr/May/Jun).
- **Outlook reads:** previous quarter's Reflection, the current year's Outlook.
- **Reflection reads:** this quarter's monthly Reflections; fall back to weeklies if monthlies are missing.
- **Reflection subheadings:** `## What I Built or Shipped`, `## What I Learned`, `## What I Avoided or Slipped On`, `## How I Feel About This Quarter`, `## Month by Month`.

### yearly
- **Period id:** `date +%Y`.
- **File:** `Yearly Notes/<id>.md`
- **Template:** `Templates/Yearly Notes Template.md`
- **Range:** the 4 quarters of the year.
- **Outlook reads:** previous year's Reflection.
- **Reflection reads:** this year's quarterly Reflections; fall back to monthlies if missing. If it is not yet December, this is a mid-year review - label it as such.
- **Reflection subheadings:** `## Biggest Wins`, `## Biggest Growth`, `## Biggest Regret or Missed Opportunity`, `## How This Year Changed My Direction`, `## One Line Summary`, `## Quarter by Quarter`.

---

## OUTLOOK workflow (any tier)

1. Resolve the tier params for the **target period** (for a fresh open, the period about to begin).
2. Ensure the note file exists; if missing, copy the tier's template. If `# Outlook` is already non-empty, do **not** silently replace it - show it and ask the user before changing (they may have hand-written it).
3. Gather context per the tier's "Outlook reads". Also skim `wiki/profile.md` and `wiki/topics/job-search.md` for current priorities when relevant.
4. Draft the `# Outlook`: intentions + your recommendation + (weekly/monthly) a realistic schedule. Flag priority/capacity conflicts.
   - **Fill the days; keep the bar separate from the schedule (weekly).** The graded bar is the floor; the schedule is a full day's work. Each scheduled day gets a **primary** (the bar item) and a named **backup** to pull in if the primary finishes early - and to drop without guilt if the primary runs long. Also list 3-5 ranked **backup items** for the week (job-search items under an hour first) that open time draws from. Unscheduled time tends to go unused, so a defined next item is a support, not a formality. (Added 2026-10-03 after W40, where every planned day was done by midday and the week's plan was exhausted by Wednesday.)
   - **Estimate from logged durations**, not intuition: the dailies record `~time` for completed items. Reference points as of 2026-10: an application = a morning to most of a day; a cold outreach message ~40 min with revisions; a thank-you/heads-up note 30-60 min.
5. **Verify before presenting.** Every dated trigger, status and next action the outlook states must match the entity page and the tracker row; when the outlook *changes* one (moves a trigger, retires a row), mirror it into both in the same pass, striking the old date and saying it must not fire. Check consistency with the higher-tier outlook written just before it and with the reflections it builds on. (Added 2026-10-03: a follow-up nudge was moved in the outlooks while the tracker row still showed the old date - the row the next `/sod` reads.)
6. Show the draft, get confirmation, then write **only** the `# Outlook` section.
7. Append the log line.

## REFLECTION workflow (any tier)

1. Resolve the tier params for the **period that just ended**.
2. Read the note file and extract the existing `# Outlook`. If there is none, say so and reflect on the period as observed.
3. Gather what actually happened per the tier's "Reflection reads".
4. Draft the `# Reflection` with the tier's subheadings, grading explicitly against the Outlook (what was done, what slipped and why, what to carry). Include your honest assessment.
   - **Timeline section, always last** (`## Day by Day` / `## Week by Week` / `## Month by Month` / `## Quarter by Quarter`): one bullet per sub-period in chronological order, `- **<label>** - <the main things that happened>`, built from the same lower-tier notes the reflection already reads (no extra reads). Labels: `Mon 9/28`, `W40 (9/28-10/4)`, `September`, `Q3`. Facts only - the assessment lives in the sections above. Include sub-periods with nothing logged (`- **Sun 10/4** - nothing logged`) so a gap reads as a gap, not an omission. A sub-period that hasn't ended yet (reflection written early) is marked `(planned: ...)` rather than filled in. (Added 2026-10-03.)
5. **Verify before presenting.** Check every date, count, quote and status claim in the draft against its source - the lower-tier note, the entity page, the tracker row, git - not against memory or an earlier summary. **A claim inherited from an earlier reflection gets re-checked at its source**, because errors propagate down the tiers (W39's "four hours" reached September's draft before it was caught). Quotation marks are for verbatim text only; mark paraphrase as paraphrase. Keep categories consistent across the notes in one run (e.g. a recruiter screen is not an interview with a hiring team). (Added 2026-10-03: an xhigh final pass found nine errors in four already-approved notes - wrong counts and dates, a quoted paraphrase, a miscategorized screen, contradictions between notes.)
6. Show the draft, get confirmation, then write **only** the `# Reflection` section.
7. Append the log line.
