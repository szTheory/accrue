---
phase: 186-html-brand-book-assembly-quality-gate
reviewed: 2026-06-14T00:00:00Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - brandbook/harness/assemble.mjs
  - brandbook/harness/verify-brandbook.mjs
  - brandbook/harness/package.json
findings:
  critical: 0
  warning: 4
  info: 2
  total: 6
status: fixed
fixed:
  - "WR-01 (c83eb502): sync dark-mode toggle label on initial load"
  - "WR-02 (021eef0c): strip self-closing <script/> tags in SVG cleaner"
  - "WR-03 (af735126): remove dead size-budget subprocess"
  - "WR-04 (c76568f8): HTML-escape angle brackets in inlineMarkdown"
  - "IN-01 (90c67f78): demote embedded document-title <h1> to <h2> (single <h1> per page)"
  - "IN-02 (2e4fe606): make size-budget check inclusive to match <= 2 MB label"
deferred: []
---

# Phase 186: Code Review Report

**Reviewed:** 2026-06-14
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

Three files reviewed: the deterministic HTML assembler (`assemble.mjs`), the quality-gate verifier (`verify-brandbook.mjs`), and the harness manifest (`package.json`). No critical issues found. Four warnings and two info items identified. The most actionable bugs are: (1) the dark-mode toggle button ships with a hardcoded label that is never synchronized to the initial theme state on page load, causing it to display the wrong action when the user's persisted or OS preference is dark; (2) the T-186-01 SVG script-stripping mitigation does not handle self-closing `<script src="..."/>` tags; (3) the size-budget check runs an unnecessary first subprocess whose result is stored and immediately discarded; and (4) the `mdToHtml` function does not escape `<` and `>` in paragraph and heading content, relying entirely on source-file discipline rather than defensive output encoding.

## Warnings

### WR-01: Dark-mode toggle button label wrong on initial load when dark theme is active

**File:** `brandbook/harness/assemble.mjs:289–306` (darkModeScript IIFE), `assemble.mjs:512` (button HTML)

**Issue:** The `<button id="theme-toggle">` is statically rendered with the text "Switch to dark". The IIFE at the bottom of `<body>` reads `localStorage` and `prefers-color-scheme`, sets `document.documentElement.dataset.theme`, and attaches a click listener — but it never updates `btn.textContent` to reflect the initially loaded theme. If a user has previously selected dark mode (stored in `localStorage`) or has an OS dark preference, the page loads in dark mode but the button still reads "Switch to dark" instead of "Switch to light". The label is only corrected after the first click.

**Fix:** Add a single line after setting `root.dataset.theme` to synchronize the button text:

```javascript
root.dataset.theme = stored || prefers;

// Add this line:
if (btn) {
  btn.textContent = root.dataset.theme === 'dark' ? 'Switch to light' : 'Switch to dark';
}
```

Since the script runs after `<button id="theme-toggle">` exists in the DOM (script is at bottom of `<body>`), moving the initial `textContent` sync before the event listener is safe. The simplest fix restructures the IIFE to set theme, then set button text, then add the listener:

```javascript
(function() {
  var root = document.documentElement;
  var stored = localStorage.getItem('accrue-theme');
  var prefers = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  root.dataset.theme = stored || prefers;

  var btn = document.getElementById('theme-toggle');
  if (btn) {
    btn.textContent = root.dataset.theme === 'dark' ? 'Switch to light' : 'Switch to dark';
    btn.addEventListener('click', function() {
      var next = root.dataset.theme === 'dark' ? 'light' : 'dark';
      root.dataset.theme = next;
      localStorage.setItem('accrue-theme', next);
      btn.textContent = next === 'dark' ? 'Switch to light' : 'Switch to dark';
    });
  }
})();
```

---

### WR-02: `stripScriptElements` does not strip self-closing `<script src="..."/>` tags

**File:** `brandbook/harness/assemble.mjs:211`

**Issue:** The T-186-01 mitigation uses `/<script\b[^>]*>[\s\S]*?<\/script>/gi` which requires a closing `</script>` tag. A self-closing form `<script src="evil.js"/>` — valid in SVG (which is XML) — is not matched and passes through unstripped. Verified:

```javascript
stripScriptElements('<svg><script src="evil.js"/></svg>')
// → '<svg><script src="evil.js"/></svg>'  (not stripped)
```

The current logo SVGs contain no such pattern (confirmed: only path data, no script elements). The gap is latent — it would trigger if an SVG file from a third-party source or a future generation pass introduced a self-closing external script reference.

**Fix:** Extend the regex to also strip self-closing script tags:

```javascript
function stripScriptElements(svgStr) {
  // Strip paired <script>...</script>
  svgStr = svgStr.replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, "");
  // Strip self-closing <script ... /> (valid in SVG/XML)
  svgStr = svgStr.replace(/<script\b[^>]*\/>/gi, "");
  return svgStr;
}
```

---

### WR-03: Dead subprocess in size-budget check — first `execSync` result is never read

**File:** `brandbook/harness/verify-brandbook.mjs:138–143`

**Issue:** The size check runs two `execSync` calls. The first (lines 138–143) runs `git ls-files brandbook/ | xargs du -c 2>/dev/null | tail -1` and stores the result in `const output`, which is never referenced again. The comment immediately below it explains the problem it was trying to solve, then re-solves it by running a second `execSync` with `du -ck`. The first call is entirely dead — it forks a shell, runs git, pipes through du, and discards the result. This is also a latent correctness risk if the two commands ever diverge (e.g., file list changes between calls on a busy filesystem).

**Fix:** Remove the dead first `execSync` call entirely:

```javascript
// Remove lines 138–143:
//   const output = execSync(
//     "git ls-files brandbook/ | xargs du -c 2>/dev/null | tail -1",
//     { encoding: "utf8", cwd: path.resolve(__dirname, "../..") }
//   ).trim();
//   // Output format comment ...
//   // Re-run with -k flag gives KB; without flag on macOS = 512-byte blocks
//   // Re-run with -k to get KB for reliable parse

// Keep only:
const outputK = execSync(
  "git ls-files brandbook/ | xargs du -ck 2>/dev/null | tail -1",
  { encoding: "utf8", cwd: path.resolve(__dirname, "../..") }
).trim();
```

---

### WR-04: `mdToHtml` does not HTML-escape `<` and `>` in paragraph and heading content

**File:** `brandbook/harness/assemble.mjs:97–98`, `assemble.mjs:186`

**Issue:** The `inlineMarkdown` function explicitly opts out of escaping with the comment "We do not escape since we're producing HTML; trust source content". This means any literal `<` or `>` in voice.md or copy.md paragraph text or heading text is emitted verbatim into the HTML output. The current source files are safe (verified: no unescaped angle brackets outside code fences in voice.md; copy.md's angle-bracket content at line 110 is inside a code fence which is correctly escaped). However the invariant is invisible — there is no guard, and a future edit to either markdown file that adds something like `<component>` in a paragraph would silently inject raw HTML. For a document that inline-embeds content from markdown files, this is an encoding discipline gap.

**Fix:** Apply minimal escaping in `inlineMarkdown` — escape only `<` and `>` that are not part of the `<strong>` and `<em>` tags the function itself just produced. The cleanest approach is to escape first, then apply the bold/italic replacements:

```javascript
function inlineMarkdown(str) {
  // Escape raw < > first (before inserting any <strong>/<em> tags)
  str = str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  // **bold**
  str = str.replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>");
  // *italic* (not **)
  str = str.replace(/(?<!\*)\*(?!\*)([^*]+)(?<!\*)\*(?!\*)/g, "<em>$1</em>");
  return str;
}
```

Note: this also escapes `&` to `&amp;`, preventing any `&entity;` sequences in markdown prose from being interpreted as HTML entities. The code-fence path already escapes correctly (lines 116–119).

---

## Info

### IN-01: `mdToHtml` emits `<h1>` tags for source documents that open with a single-`#` heading

**File:** `brandbook/harness/assemble.mjs:153–157`

**Issue:** Both `voice.md` and `copy.md` open with a `# Title` (h1) heading. `mdToHtml` converts this to `<h1>`, so the assembled HTML has multiple `<h1>` elements: one in the cover section (the hero logo section implies a page title via structure) and one each in the Voice & Tone and Copy Blocks sections. This is a mild accessibility concern — a well-structured document should have exactly one `<h1>`. The current output passes all structural gates because none of the acceptance criteria check `<h1>` count.

**Fix (two options):**
- Option A (minimal): Strip the document title `<h1>` from each source file's HTML output, since the section `<h2>` headings already contextualise the content. Replace `<h1>` → `<h2>` in the rendered section HTML after calling `mdToHtml`, e.g.: `voiceHtml.replace(/^<h1>/, "<h2>").replace(/<\/h1>/, "</h2>")`.
- Option B (principled): Pre-strip the `# Title` lines from the markdown before passing to `mdToHtml`, since the HTML section already has its own `<h2>` header.

---

### IN-02: Size-budget assertion label claims `<= 2 MB` but code uses strict less-than

**File:** `brandbook/harness/verify-brandbook.mjs:158–161`

**Issue:** The assertion message says `"committed weight <= 2 MB"` but the condition is `totalBytes < 2097152` (exclusive). At exactly 2 MB (2097152 bytes), the assertion fails with a message claiming the threshold is `<= 2 MB`. This is a minor label/code inconsistency that would only surface at exactly the boundary, but it means a repo that weighs exactly 2 MB gets a misleading error message.

**Fix:** Either change the assertion to `totalBytes <= 2097152` (to match the label), or change the label to `"< 2 MB"`. Since the intent is a 2 MB ceiling, `<= 2097152` (inclusive) is the cleaner fix:

```javascript
assert(
  totalBytes <= 2097152,
  `committed weight <= 2 MB (found ${MB.toFixed(2)} MB — ${totalBytes} bytes via git ls-files)`
);
```

---

_Reviewed: 2026-06-14_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
