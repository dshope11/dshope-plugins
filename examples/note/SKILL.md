---
name: note
description: Insert a personal callout into the most appropriate wiki page. Use when the user wants to attach a quick personal note or reaction to a wiki page ("/note [target] \"text\"").
---

Insert a personal callout into the most appropriate wiki page.

## Usage

```
/note [target] "your personal note"
```

- `target` (optional): a wiki page path (e.g. `wiki/concepts/harness-engineering`) or a topic keyword (e.g. `harness`, `pkm`, `roc-auc`)
- `"text"`: the note content in quotes - this becomes the body of the callout

## Steps

1. **Parse input** - extract:
   - The quoted string as the note content (strip surrounding quotes)
   - Everything before the quote as the optional target (path or keyword); may be empty

2. **Route to the right page**:
   - If a full file path was given (contains `/` or ends in `.md`): use that page directly
   - If a keyword was given: read `wiki/index.md`, identify the single most relevant page based on the summaries, and tell the user which page you chose before proceeding
   - If nothing was given: read `wiki/index.md`, pick the most relevant page based on the note content, and ask the user to confirm the target before proceeding

3. **Read the target page** in full.

4. **Find the best insertion point** - identify the section or paragraph in the page that is most semantically relevant to the note content. Rules:
   - The callout should follow the most relevant paragraph, immediately after it
   - Do NOT append to the end of the document - that's what `# My Notes` is for
   - Do NOT insert inside a `# My Notes` section
   - Do NOT insert inside `## Related Pages` or `## Questions & Resolutions`
   - If no specific section is clearly more relevant, insert just above `## Related Pages`
   - If multiple sections are equally relevant, choose the first one

5. **Show a preview** - display:
   - Target page path
   - The section heading where the callout will appear
   - A short excerpt of the surrounding text (2-3 lines before/after the insertion point)
   - The callout block as it will be written
   Then ask: **"Insert here? [yes / no / different location]"**
   - If "no": abort, do nothing
   - If "different location": list the other candidate sections by heading and let the user choose by number

6. **Write** - on confirmation, insert the callout at the chosen location. Do not modify any other content on the page.

## Output format

```markdown
> [!personal]
> {note text}
```

Insert with a blank line before and after.

## Rules

- Never overwrite or rewrite existing content
- Never insert inside a `# My Notes` section or an existing `> [!personal]` callout
- The note content should be inserted verbatim - do not paraphrase or edit it
- Always show the preview and get confirmation before writing
- If the target page cannot be found or the path is ambiguous, say so and ask the user to clarify
