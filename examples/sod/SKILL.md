---
name: sod
description: Start-of-day prep - create today's daily note, carry over incomplete TODOs, surface periodic-note context, and nudge the weekend horizons review. Use when the user says "/sod" or "start of day", or is starting the morning.
allowed-tools: Bash, Read, Write, Edit
---

Start-of-day preparation for the vault's daily notes. Rules only; the incident behind each rule is in `rationale.md` in this folder, which you do not need to read to run the skill.

## 1. Today's note

1. TODAY = `date +%Y-%m-%d`.
2. If `~/vault/Daily Notes/TODAY.md` does not exist, create it as a copy of `~/vault/Templates/Daily Notes Template.md`. If it exists, read it.

## 2. Carry the TODO backlog

1. **Source note:** the most recent existing daily note before TODAY whose `# TODO` section actually holds the backlog. This is usually yesterday, but not always: a note can be pre-created as a stub days ahead and never receive a carry. If the most recent note's `# TODO` is thinner than the one before it, check whether the backlog skipped it, and carry from the last note that really holds it.
2. Read the source note in full. Take its `# TODO` section (to end of file or the next `#`-level heading) and collect every unchecked `- [ ]` item with its indented sub-bullets, keeping the hierarchy. Ignore `- [x]` items. **Only `# TODO` is carried**: never promote unchecked items from the activity log, job-board sections, or anywhere else.
3. **Aging.** GAP = calendar days from the source note's date to TODAY (a normal next-day carry is 1; Thursday to Monday is 4). The counter measures elapsed days, not `/sod` runs; counting runs under-counts exactly the stretches when items sit longest.
   - An item with a carry marker `(×N)` gets N + GAP. An item without one gets `(×GAP)`.
   - The marker sits at the end of the item text but **before** any trailing wikilink: `- [ ] Write CV draft (×3) [[topics/cv]]`.
   - **Match the last `(×N)` anywhere on the line, never one anchored to end-of-line.** An end-anchored match misses a marker followed by a link and appends a second marker, which resets the item's apparent age.
   - Sub-bullets get no marker; they inherit the parent's.
4. Append the aged items to today's `# TODO`, keeping indentation. If today's `# TODO` already has items, append after them and skip any item whose text is already there.
5. After writing, scan today's note for any line carrying two markers, and fix it.

## 3. Periodic context and progress to date

`/sod` runs in its own session, so read generously, but **cover each source once**: never read the same text twice.

**(a) Outlooks, the plan.** Compute the week (`date +%G-W%V`), month (`date +%Y-%m`), calendar quarter (`YYYY-Qn`, Jan-Mar = Q1) and year. Read the `# Outlook` of each that exists in `Weekly Notes/`, `Monthly Notes/`, `Quarterly Notes/` and `Yearly Notes/`. Tier definitions are in `.claude/skills/horizons/periodic-workflow.md`.

**(b) Progress, what actually happened.** An Outlook is set once and goes stale mid-period, so gather actual progress through the rollup hierarchy:
- **This week:** this ISO week's daily notes from Monday through the day before TODAY. Read only their activity sections (`## Morning` / `## Afternoon` / `## Evening`, with `### wiki activity`), stopping at `# TODO`: `awk '/^# TODO/{exit} {print}' "<note>"`. The backlog below it is already in context and repeats from note to note. The source note from section 2 was read in full already; don't read it again.
- **Reflection substitution:** where a filled weekly `# Reflection` already covers a day, read the Reflection instead of that day's daily.
- **Two-note floor, which overrides the substitution:** always read the activity sections of the 2 most recent existing dailies. If the in-week range yields fewer than 2, extend backward across the week boundary until it has 2. On a Monday this pulls in the weekend, when the weekly reviews run and seed the coming week.
- **This month:** the `# Reflection` of each completed week in the month, plus this week's dailies above. Never re-read raw dailies for whole prior weeks.
- **Quarter and year:** only when a candidate focus plausibly ties to a goal at that level, and then through the monthly Reflections.
- **Source-of-truth pages:** read any wiki page whose omission risks recommending something already done or superseded. Whenever an Outlook names application or follow-up targets, read the `[[topics/job-search]]` pipeline table for their actual status.

## 4. Inbox sweep (read-only, `himalaya`)

**Never alter the inbox's read state.** Always read with `himalaya message read --preview <ID>`; the bare form marks the message seen.

### 4a. The span: what's new

**Governing rule: coverage.** Every message that reaches the mailbox must be looked at by some `/sod` run, at least at its envelope line. Unbroken watermark-to-watermark spans deliver that.

1. **Span start = the earlier of:**
   - the **last-sweep watermark** (see 4d): look in today's note first (for a re-run), then walk back one note at a time, up to 7 days;
   - the **oldest unread message**: `himalaya envelope list --page-size 100 -- "not flag seen"`.

   The watermark is the floor. The unread set can only move the start *earlier*; it is never the start on its own, because anything the user read before the oldest unread would fall outside the span.
2. **No watermark within 7 days:** start at 17:00 local on the day before the walk-back window began, and **say so in the briefing, naming the uncovered gap.**
3. List all envelopes (`himalaya envelope list --page-size 100`) and select **every** message from the span start onward, **including ones already marked read**. The user often opens personally addressed mail before `/sod` runs, and those are the high-signal messages.
4. **Scan the envelope line of every message in the span**, however long the span is. The cap of about 40 applies to full reads only. On a long span, triage everything from envelopes, full-read only what's consequential, and report how many were envelope-triaged versus read.
5. **Triage.** Full-read anything plausibly consequential: a human sender, a recruiter, a company domain, a reply on a live thread, anything referencing an application. Bulk and automated senders (job alerts, social networks, retail and service promos) are counted, not read. Surface flagged mail.

**CLI rules:**
- Options precede the query, separated by `--`: `himalaya envelope list --page-size 100 -- "not flag seen"`. Trailing options are parsed as part of the query.
- In the FLAGS column, `*` is IMAP `\Recent`, not unread. The first session to examine the mailbox clears it, including this skill's own first list call, so never key off it. `flag seen` is the durable signal.
- `!` is `\Flagged` (starred) and persists.
- The DATE column mixes timezones. **Normalize to local before comparing against the span start.** The `before` / `after` filters are date-granular, so apply the span start after listing.

Fold anything that changes today's plan into the briefing, and record it per 4c. Never add TODO items for it.

### 4b. Awaited mail: has the thing arrived?

The span answers "what's new?", not "has the awaited thing arrived?". **Never conclude an awaited message is absent because it isn't in the span, and never assume a message was handled because it's marked read.**

**Watch list**, built fresh each run:
- `[[topics/job-search]]` pipeline rows whose Status or Next-action implies an inbound is owed;
- outbound messages named in the last few daily notes with no logged reply;
- anything the session handoff or today's carried TODOs flag as blocked on someone else.

**Search each item** with `himalaya envelope list --page-size 20 -- "<query>"`, and compare the newest hit's date with what the wiki records:
- `body <company-or-product>` first: it's the most reliable key. Then `subject <term>` and `from <name-or-domain>`.
- **Search the company or product name, never only a person's name.** Platform relays (YC/WaaS, Greenhouse, Ashby, Lever) send from the platform, so a person-name miss is not evidence of absence.
- **`from` matches whole words, not substrings.** Search a whole token (`linkedin`, `hit-reply`, `greenhouse`); a fragment returns an empty table that looks exactly like a real absence.
- **The inbox holds only one side of each thread.** Replies the user sends inside LinkedIn, WaaS, or an ATS portal never reach this mailbox, so mail can show what arrived but never whether a reply went out. Never infer inaction from mail.

**Two standing LinkedIn queries, run every sweep:**
- `from hit-reply`: recruiter InMail. It arrives from LinkedIn's `hit-reply` / `inmail-hit-reply` addresses, with the recruiter's real name in the From display and their own subject, so no template matches it (the word "InMail" appears only in the body). Replies on a thread arrive as `Message replied: <original subject>`. Connection invitations come through here too. This is the main recruiter-inbound channel.
- `from messaging-digest`: ordinary LinkedIn direct messages, as `<Name> just messaged you`. **The message body is not in the email**, only the sender's name, their title, and a link. Report each hit as "needs LinkedIn opened manually; the body is not in the mail", naming the sender and title. Never report one as read or triaged, and never guess its content.

**Reconstruct both sides before reporting any watch-list item.** What the user needs is whose turn it is, not whether mail arrived:
1. **Last inbound:** the newest mail hit, with its date.
2. **Last outbound:** from the vault, never from mail. Check the entity page's thread-of-record section, then the thread file if the entity page links one, then the daily notes since the last inbound.
3. **Whose turn:** outbound newer than inbound means waiting on them; inbound newer means the user owes a reply.
4. **Days elapsed** since the newer of the two, plus any offered window that has now lapsed.

**The pipeline row is not authoritative for thread state.** When the row and the entity page disagree, the entity page wins, and the row gets corrected in the same pass.

**Dated triggers.** Check every watch-list item for a pre-committed rule of the shape "if X hasn't happened by `<date>`, do Y", and report any that fires today or has passed, naming the rule and the date. A fired trigger is a due decision and ranks above a quiet thread. When you find one that isn't mirrored into the pipeline row's Next-action cell, mirror it there with its date.

**Report each item definitively** ("waiting on them, 4 days, nudge trigger fires today"; "nothing since the 8/02 relay"). A plain "searched, absent" beats silence. **Never state or imply that the user hasn't replied** unless step 2 actually came up empty.

### 4c. Record the mail in the wiki

A finding that is only reported disappears when the session ends. Fix the pages it made stale while the message is open.

**Trigger:** a full-read message (bulk never qualifies) that changes a fact the vault records: a decision on a live process, a new recruiter contact, a scheduling change, an answer to an open question, an arrival that satisfies a watch-list item. If it changes nothing recorded, say so and move on.

**Walk outward from the thread, in this order:**
1. **The entity page, first; it's authoritative.** `wiki/entities/<company-or-person>.md`: a dated section with the verbatim message (or its substantive part), what it settles, what it doesn't settle, and the resulting status. Bump `updated`. If the contact is live and has no page, create one.
2. **The tracker row, in the same pass:** status, Next-action, Last-action date, notes.
3. **Retire any dated trigger the message answers, in both the entity page and the row.** Strike it and say in the text that it's retired and must not fire, with one line on why. A trigger that's merely deleted looks like an oversight to the next reader.
4. **Promote the evergreen finding.** Ask what the message establishes beyond this one company (a channel result, a corrected self-assessment, a pattern across contacts, a durable background fact) and put it in `[[topics/career-story-bank]]` or `wiki/profile.md`, with the entity page referencing it. This step is skipped most often and compounds most.
5. **`wiki/log.md`:** one `## [YYYY-MM-DD] query | ...` entry naming what arrived, what it closed, and every page touched.
6. **Today's daily note:** a bullet in the current time block for the arrival, and the page edits under `### wiki activity`.

**Limits:** record what arrived; don't do the work it implies (a rejection gets written down, and what to do next is the user's call). Don't invent status the message doesn't carry: template language isn't evidence. Write what's established and leave what's ambiguous flagged as ambiguous. When it's genuinely unclear whether a message meets the bar, ask in the briefing; otherwise default to writing it.

### 4d. Watermark

Append one line to the `# Misc.` section of today's note, below anything already there, without disturbing the rest:

```markdown
*Inbox swept through YYYY-MM-DD HH:MM TZ (`/sod`). Awaited: <item> - none since <date>; <item> - none.*
```

Use the real local time (`date "+%Y-%m-%d %H:%M %Z"`). **Write it on every run without exception**: when the sweep found nothing, when everything was bulk, and when the rest of `/sod` is cut short. It's the other half of the coverage rule in 4a. If the sweep was partial (span truncated, a query failed, himalaya errored), record the point actually reached and say what wasn't covered.

## 5. Open the note

`obsidian open path="Daily Notes/TODAY.md"`, with the real date.

## 6. Briefing (terminal, short)

- How many TODO items were carried, and whether today's note was new or already existed.
- **Items with a carry count >= 7**, listed by name as candidates for `/task-review`.
- Meetings in the source note that suggest recurring commitments.
- **Today's focus:** 1-3 things, drawn from the Outlooks, the progress from section 3, and the carried TODOs. **Credit what's done:** never resurface a target the dailies or the pipeline table show as completed, dropped, or superseded, and let a met weekly quota shift the recommendation to the next-highest-leverage work. A suggestion only: never add it to `# TODO`.
- **Awaited threads:** one line per watch-list item, in whose-turn terms ("waiting on them, N days since the user's `<date>` reply"; "user owes a reply, inbound `<date>`"; "nothing since `<date>`"), with what it says and how it changes today. **Lead with any dated trigger that fires today or has passed.** A thread quiet long enough to need a nudge or a decision to stop waiting is a focus candidate.
- **LinkedIn:** report InMail and direct-message hits from 4b like any other mail, and log a live recruiter conversation into the pipeline table. Ask the user to open the app only when the mail implies an in-app thread they need to act on (always the case for a `messaging-digest` hit).
- **Weekend horizons nudge**, anchored exactly as `/horizons` anchors it. On a weekend, close-week = `date +%G-W%V` (its `# Reflection` should be filled) and open-week = `date -v+1d +%G-W%V` (its `# Outlook` should be filled). On Sunday the current ISO week is the one being closed, never the one being opened; never reach back to the week before it for the Reflection.
  - **Saturday:** recommend `/horizons`; no state check.
  - **Sunday:** recommend `/horizons` if close-week's Reflection or open-week's Outlook is empty. For any month, quarter or year boundary within 3 days, also check the Reflection of the period ending there and the Outlook of the one starting there. If everything is filled, say nothing.
  - **Weekdays:** no nudge.

## Rules

- Never modify the source note or any earlier note.
- Never overwrite content already in today's note.
- **Never create TODO items.** If something outside `# TODO` looks like it should be one (an unresolved task in the Evening log, say), flag it in the briefing and ask.
