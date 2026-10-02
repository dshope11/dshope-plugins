---
name: relink
description: Wiki cross-link sweep - find unlinked mentions of known wiki pages and add wikilinks. Use when the user asks to relink the wiki or add missing wikilinks.
allowed-tools: Bash, Glob, Grep, Read, Edit
---

Scan the vault wiki for unlinked mentions of known wiki pages and add `[[wikilinks]]` where missing.

**Scope:** Run on all wiki pages by default. If an argument is given (e.g. `/relink concepts/attention-mechanism`), restrict the sweep to that page and pages that mention it.

---

**Steps:**

1. **Build the page registry** - read `wiki/index.md` and extract every known wiki page: its slug path (e.g. `concepts/mixture-of-experts`) and display name (e.g. "Mixture of Experts"). For each entry also derive common aliases and name variants a human might write in prose (e.g. "MoE", "mixture of experts", "attention mechanism", "KV-cache", "ROC/AUC"). Use your knowledge of the domain to generate reasonable aliases - don't just split the slug.

   Build a list of `(search_term, slug, display_hint)` tuples. Multiple rows per page are fine.

2. **Collect candidate pages** - list all `.md` files under `wiki/` excluding `wiki/index.md` and `wiki/log.md`.
   ```bash
   find ~/vault/wiki -name "*.md" \
     ! -name "index.md" ! -name "log.md"
   ```

3. **Scan for unlinked mentions** - for each wiki page, read its content and find lines where a search term from the registry appears *without* already being inside a `[[...]]` link. Apply these filters:
   - Skip frontmatter (between `---` delimiters at top of file)
   - Skip code blocks (between ` ``` ` fences)
   - Skip lines that already contain the target slug as a wikilink
   - Skip the page's *own* entry (a page shouldn't link to itself)
   - Prefer the **first substantive mention** per page per target - don't flag every occurrence
   - Only flag matches where the term appears in a context that warrants a link (i.e., the sentence is *about* that concept, not just using the word in passing)

   You may use Grep to find candidate lines, then Read the full page to make context judgments.

4. **Build a findings table** - group by target file:

   ```
   ## wiki/concepts/attention-mechanism.md
   - Line 14: "the residual connections help" -> [[concepts/residual-connections|residual connections]]
   - Line 42: "used in RAG pipelines" -> [[concepts/rag|RAG]]

   ## wiki/topics/interview-prep.md
   - Line 88: "confusion matrix" -> [[concepts/confusion-matrix|confusion matrix]]
   ```

   For each finding, show: line number, current text excerpt, proposed wikilink with display text.

   If a page has no missing links, omit it from the table.

5. **Show the summary** - print the full findings table and a count:
   ```
   Found N unlinked mentions across M pages.
   ```
   Then ask:
   > "Apply all? Or tell me which pages or specific links to skip. [all / list exceptions / none]"

6. **Apply approved changes** - for each confirmed finding, use Edit to replace the plain text with the wikilink. Preserve surrounding text exactly - only replace the matched term. Use display-text links (`[[slug|display text]]`) when the prose wording differs from the page title.

7. **Report** - print a short summary of changes made (N links added across M pages). Do not update `wiki/log.md` unless changes were actually made, in which case append:
   ```
   ## [YYYY-MM-DD] relink | Cross-link sweep - N links added across M pages
   ```

---

**Rules:**
- Never link inside frontmatter YAML, code blocks, or existing `[[wikilinks]]`
- Never link a page to itself
- When in doubt about whether a mention warrants a link, include it in the findings and let the user decide - don't silently skip it
- Prefer adding a link to the *first* substantive occurrence on a page rather than every occurrence
- Use display text whenever the prose wording is cleaner than the raw slug
- If a page was already well-linked in today's session, skip it to avoid redundant work - focus on pages not recently touched
