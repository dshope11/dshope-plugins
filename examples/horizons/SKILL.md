---
name: horizons
description: Weekend horizons review (GTD) - close any periods that just ended and open the ones now beginning, across week/month/quarter/year. Use when the user asks for the weekend review or the horizons review.
allowed-tools: Bash, Read, Write, Edit
---

The **horizons review** is the weekend ritual for the vault's periodic notes. Named for GTD's Horizons of Focus: in one sitting it climbs the altitude ladder (week -> month -> quarter -> year), closing the periods that just ended and opening the ones now beginning.

It is **state-aware**: normally run on a weekend, but it checks file state too, so a skipped weekend gets caught the next time it runs.

Read `periodic-workflow.md` in this skill's folder (`.claude/skills/horizons/`) first - it defines every tier's parameters and the OUTLOOK / REFLECTION workflows this command orchestrates.

## Step 1 - Establish dates

Run `date +%Y-%m-%d` (TODAY), `date +%u` (day of week, 1=Mon..7=Sun).

Compute **SUN** = the Sunday of this weekend (the natural anchor for boundary ownership):
- If today is Sunday, SUN = today.
- If today is Saturday, SUN = tomorrow.
- Otherwise (weekday - off-cadence run), use the nearest upcoming Sunday: SUN = `date -v+$(( 7 - $(date +%u) ))d +%Y-%m-%d`.

Also compute **NEXTMON** = the Monday that begins next week = SUN + 1 day.

## Step 2 - Decide which tiers fire (nearest-weekend rule)

A period boundary is **owned by the weekend whose Sunday is nearest to it**. Since Sundays are 7 days apart, exactly one Sunday is within 3 days of any boundary date. So:

> A tier fires this weekend iff there exists a tier-boundary date `F` with `|SUN - F| <= 3 days`.
> When it fires, the period being **closed** is the one ending at `F` (the period containing `F - 1 day`), and the period being **opened** is the one starting at `F`.

Boundary dates `F` to test (use `date` arithmetic; compute day-distance as an absolute integer):
- **weekly** - always fires. (Close the week ending SUN; open the week starting NEXTMON.)
- **monthly** - `F` = the 1st of a month. Test the 1st of SUN's month and the 1st of the following month; fire if either is within 3 days of SUN.
- **quarterly** - `F` in {Jan 1, Apr 1, Jul 1, Oct 1} (calendar quarters). Fire if any is within 3 days of SUN.
- **yearly** - `F` = Jan 1. Fire if within 3 days of SUN.

Boundaries nest: Jul 1 is simultaneously a month and quarter boundary, Jan 1 is month+quarter+year - so the higher tiers naturally pull the lower ones in.

## Step 3 - State backstop (catch missed reviews)

Independently of the calendar, for each tier check for unfinished work and add it to the plan:
- **Missed close:** the most recently *ended* period's note exists with a filled `# Outlook` but an empty `# Reflection` -> its reflection is overdue; include it.
- **Missed open:** the *current* period's note is missing or has an empty `# Outlook` -> its outlook is overdue; include it.

If the calendar (Step 2) and the backstop disagree, prefer doing the work - it's idempotent (re-opening an already-filled Outlook just asks before changing).

## Step 4 - Present the plan, then execute

Print the resolved plan first, e.g.:

```
Horizons review - Sun 2026-05-31
  reflections (close):  weekly 2026-W22, monthly 2026-05
  outlooks   (open):    weekly 2026-W23, monthly 2026-06
  (quarterly/yearly: not due - Q2 closes Jun 30, nearest weekend Jun 27/28)
```

Then execute in this order so each step can build on the previous:

1. **Reflections, bottom-up** (weekly -> monthly -> quarterly -> yearly): higher tiers synthesize from the lower reflections you just wrote.
2. **Outlooks, top-down** (yearly -> quarterly -> monthly -> weekly): each outlook can reference the fresh higher-tier outlook above it.

For each item, run the corresponding OUTLOOK or REFLECTION workflow from `periodic-workflow.md` (same procedure the `*-outlook` / `*-reflection` commands use). Write each section in place; never overwrite `# Outlook` when reflecting, or `# My Notes` / `> [!personal]` ever.

**One note at a time, strictly serial.** Draft item 1, present it, get confirmation, write it to the file and append its log line - and only then start drafting item 2. **Never present two drafts in one message, even to save a round trip.** Each later item is supposed to build on the *written* version of the one before it, and the user's edits to a reflection routinely change what the next outlook should say; a batched review also splits their attention, so a defect shared by both drafts gets caught in one and approved in the other.

## Step 5 - Wrap up

Append one `wiki/log.md` line per item written (per the spec), and print a one-line summary of what was closed and opened.
