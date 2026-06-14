/**
 * assemble.mjs — Deterministic HTML brand book assembler
 *
 * Reads all locked source materials in brandbook/ and writes
 * brandbook/index.html as a self-contained, file://-openable HTML brand book.
 *
 * Zero npm dependencies — Node built-ins only (fs, path, url).
 *
 * Usage:
 *   node brandbook/harness/assemble.mjs
 *
 * Output: brandbook/index.html (committed, deterministic, idempotent)
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// ---------------------------------------------------------------------------
// Path constants (all relative to __dirname via path.resolve)
// ---------------------------------------------------------------------------

const TOKENS_CSS  = path.resolve(__dirname, "../tokens/tokens.css");
const LOGO_DIR    = path.resolve(__dirname, "../logo");
const EXAMPLES_DIR = path.resolve(__dirname, "../examples");
const VOICE_MD    = path.resolve(__dirname, "../voice.md");
const COPY_MD     = path.resolve(__dirname, "../copy.md");
const README_MD   = path.resolve(__dirname, "../README.md");
const LICENSE_TXT = path.resolve(__dirname, "../LICENSE-FONTS.txt");
const OUTPUT_PATH = path.resolve(__dirname, "../index.html");

// ---------------------------------------------------------------------------
// Markdown mini-converter (Option B — no npm deps)
// Covers the 6 constructs present in voice.md and copy.md:
//   1. ## Heading / ### Sub-heading → <h2> / <h3>
//   2. | table | rows | → <table><tr><td>
//   3. Triple-backtick fences → <pre><code>...</code></pre>
//   4. **bold** → <strong>
//   5. *italic* → <em>
//   6. - bullet → <ul><li>
// ---------------------------------------------------------------------------

function mdToHtml(text) {
  const lines = text.split("\n");
  const out = [];
  let inCodeFence = false;
  let codeLang = "";
  let codeLines = [];
  let inTable = false;
  let tableRows = [];
  let inList = false;
  let listItems = [];

  function flushTable() {
    if (tableRows.length === 0) return;
    // First row is headers, second row (if `|---|`) is separator — skip
    const rows = tableRows;
    tableRows = [];
    inTable = false;
    let html = "<table>\n";
    let headerDone = false;
    for (const row of rows) {
      // Skip separator rows like |---|---|
      if (/^\|[\s\-:|]+\|/.test(row)) continue;
      const cells = row
        .replace(/^\|/, "")
        .replace(/\|$/, "")
        .split("|")
        .map((c) => c.trim());
      if (!headerDone) {
        html += "<thead><tr>" + cells.map((c) => `<th>${inlineMarkdown(c)}</th>`).join("") + "</tr></thead>\n<tbody>\n";
        headerDone = true;
      } else {
        html += "<tr>" + cells.map((c) => `<td>${inlineMarkdown(c)}</td>`).join("") + "</tr>\n";
      }
    }
    if (headerDone) html += "</tbody>\n";
    html += "</table>";
    out.push(html);
  }

  function flushList() {
    if (listItems.length === 0) return;
    out.push("<ul>\n" + listItems.map((i) => `<li>${inlineMarkdown(i)}</li>`).join("\n") + "\n</ul>");
    listItems = [];
    inList = false;
  }

  function inlineMarkdown(str) {
    // **bold**
    str = str.replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>");
    // *italic* (not **)
    str = str.replace(/(?<!\*)\*(?!\*)([^*]+)(?<!\*)\*(?!\*)/g, "<em>$1</em>");
    // escape < > that are not HTML tags we just inserted
    // (We do not escape since we're producing HTML; trust source content)
    return str;
  }

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    // Code fence
    if (line.startsWith("```")) {
      if (!inCodeFence) {
        // Opening fence — flush pending list/table
        if (inList) flushList();
        if (inTable) flushTable();
        inCodeFence = true;
        codeLang = line.slice(3).trim();
        codeLines = [];
      } else {
        // Closing fence
        inCodeFence = false;
        const escaped = codeLines.join("\n")
          .replace(/&/g, "&amp;")
          .replace(/</g, "&lt;")
          .replace(/>/g, "&gt;");
        out.push(`<pre><code class="language-${codeLang}">${escaped}</code></pre>`);
        codeLines = [];
        codeLang = "";
      }
      continue;
    }

    if (inCodeFence) {
      codeLines.push(line);
      continue;
    }

    // Table detection (line starts with |)
    if (line.trimStart().startsWith("|")) {
      if (inList) flushList();
      if (!inTable) inTable = true;
      tableRows.push(line.trim());
      continue;
    } else if (inTable) {
      flushTable();
    }

    // Heading
    if (line.startsWith("### ")) {
      if (inList) flushList();
      out.push(`<h3>${inlineMarkdown(line.slice(4).trim())}</h3>`);
      continue;
    }
    if (line.startsWith("## ")) {
      if (inList) flushList();
      out.push(`<h2>${inlineMarkdown(line.slice(3).trim())}</h2>`);
      continue;
    }
    if (line.startsWith("# ")) {
      if (inList) flushList();
      out.push(`<h1>${inlineMarkdown(line.slice(2).trim())}</h1>`);
      continue;
    }

    // List item
    if (line.match(/^[-*] /)) {
      inList = true;
      listItems.push(line.replace(/^[-*] /, "").trim());
      continue;
    } else if (inList && line.trim() === "") {
      flushList();
      out.push("");
      continue;
    } else if (inList) {
      // Non-list-item, non-blank: flush list and process as paragraph
      flushList();
    }

    // Horizontal rule
    if (line.match(/^---+\s*$/)) {
      out.push("<hr>");
      continue;
    }

    // Empty line → paragraph break
    if (line.trim() === "") {
      out.push("");
      continue;
    }

    // Default: paragraph
    out.push(`<p>${inlineMarkdown(line)}</p>`);
  }

  // Flush any pending state
  if (inTable) flushTable();
  if (inList) flushList();

  // Join and collapse multiple blank lines
  return out.join("\n").replace(/\n{3,}/g, "\n\n");
}

// ---------------------------------------------------------------------------
// SVG helpers
// ---------------------------------------------------------------------------

/** Strip <?xml ...?> declaration from SVG string if present. */
function stripXmlDecl(svgStr) {
  return svgStr.replace(/<\?xml[^?]*\?>\s*/i, "");
}

/**
 * Strip any <script> elements from SVG content (T-186-01 mitigation).
 * Logo SVGs are path-only, but defensive strip is cheap and correct.
 */
function stripScriptElements(svgStr) {
  return svgStr.replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, "");
}

function cleanSvg(svgStr) {
  return stripScriptElements(stripXmlDecl(svgStr));
}

/** Read and clean an SVG file. */
function readSvg(filePath) {
  return cleanSvg(fs.readFileSync(filePath, "utf-8"));
}

// ---------------------------------------------------------------------------
// Main assembler
// ---------------------------------------------------------------------------

function main() {
  // Read all inputs
  const tokensCss = fs.readFileSync(TOKENS_CSS, "utf8");
  const voiceMd = fs.readFileSync(VOICE_MD, "utf8");
  const copyMd = fs.readFileSync(COPY_MD, "utf8");
  const readmeMd = fs.readFileSync(README_MD, "utf8");
  const licenseTxt = fs.readFileSync(LICENSE_TXT, "utf8");

  // Logo SVGs — sorted for determinism
  const logoFiles = fs.readdirSync(LOGO_DIR)
    .filter((f) => f.endsWith(".svg"))
    .sort();

  const logoSvgs = {};
  for (const f of logoFiles) {
    logoSvgs[f] = readSvg(path.join(LOGO_DIR, f));
  }

  // Specimen SVGs — sorted for determinism
  const specimenFiles = fs.readdirSync(EXAMPLES_DIR)
    .filter((f) => f.endsWith(".svg"))
    .sort();

  const specimenSvgs = {};
  for (const f of specimenFiles) {
    specimenSvgs[f] = readSvg(path.join(EXAMPLES_DIR, f));
  }

  // Convert markdown content to HTML
  const voiceHtml = mdToHtml(voiceMd);
  const copyHtml = mdToHtml(copyMd);

  // Extract logo usage section from README.md (from "## Logo System" through "## Regenerating")
  const readmeLogoSection = readmeMd
    .replace(/## Regenerating[\s\S]*$/, "")  // drop regeneration section
    .replace(/^[\s\S]*?## Logo System/, "## Logo System"); // keep from Logo System

  const readmeLogoHtml = mdToHtml(readmeLogoSection);

  // Extract CSS variable table from tokens.css content
  function buildTokenTable(css) {
    const rows = [];
    const varRegex = /\s*(--accrue-[^:]+):\s*([^;]+);/g;
    let m;
    while ((m = varRegex.exec(css)) !== null) {
      const name = m[1].trim();
      const value = m[2].trim();
      rows.push({ name, value });
    }
    if (rows.length === 0) return "<p>No tokens found.</p>";
    let table = '<table class="token-table">\n<thead><tr><th>Variable</th><th>Value</th></tr></thead>\n<tbody>\n';
    for (const row of rows) {
      const swatch = row.value.startsWith("#")
        ? `<span class="swatch" style="background:${row.value}"></span>`
        : "";
      table += `<tr><td><code>${row.name}</code></td><td>${swatch}${row.value}</td></tr>\n`;
    }
    table += "</tbody>\n</table>";
    return table;
  }

  // Build the dark-mode toggle script (IIFE, no imports, no framework)
  const darkModeScript = `<script>
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
</script>`;

  // TOC entries (section IDs must match section elements below)
  const tocEntries = [
    { id: "section-cover",       label: "Cover" },
    { id: "section-logo",        label: "Logo System" },
    { id: "section-color",       label: "Color Palette" },
    { id: "section-typography",  label: "Typography" },
    { id: "section-spacing",     label: "Spacing" },
    { id: "section-voice",       label: "Voice & Tone" },
    { id: "section-copy",        label: "Copy Blocks" },
    { id: "section-favicon",     label: "Favicon & Social Card" },
    { id: "section-tokens",      label: "Token Reference" },
    { id: "section-provenance",  label: "Provenance" },
  ];

  const tocLinks = tocEntries
    .map((e) => `<li><a href="#${e.id}">${e.label}</a></li>`)
    .join("\n      ");

  // Build the assembled HTML
  const html = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Accrue Brand Book v1.52</title>
<style>
/* ---- Design tokens (from tokens/tokens.css) ---- */
${tokensCss}

/* ---- Brand book layout & typography ---- */
*, *::before, *::after { box-sizing: border-box; }

html {
  scroll-behavior: smooth;
}

body {
  font-family: Geist, system-ui, sans-serif;
  max-width: 860px;
  margin: 0 auto;
  padding: 0 16px 64px;
  background: var(--accrue-surface-base);
  color: var(--accrue-content-primary);
  line-height: 1.6;
}

[data-theme="dark"] body {
  background: var(--accrue-dark-base);
  color: var(--accrue-dark-primary);
}

a { color: var(--accrue-interactive-accent); }
[data-theme="dark"] a { color: var(--accrue-dark-info); }

h1 { font-size: 2.25rem; font-weight: 700; line-height: 1.2; margin: 0 0 0.5rem; }
h2 { font-size: 1.5rem; font-weight: 600; border-bottom: 1px solid var(--accrue-fog); padding-bottom: 0.25rem; margin: 2.5rem 0 1rem; }
h3 { font-size: 1.125rem; font-weight: 600; margin: 1.5rem 0 0.5rem; }
[data-theme="dark"] h2 { border-bottom-color: var(--accrue-dark-elevated); }

p { margin: 0 0 0.75rem; }
pre { background: var(--accrue-code-block-surface); color: var(--accrue-code-block-text); border-radius: 6px; padding: 1rem; overflow-x: auto; font-family: "Geist Mono", ui-monospace, monospace; font-size: 0.875rem; }
[data-theme="dark"] pre { background: var(--accrue-dark-elevated); color: var(--accrue-dark-primary); }
code { font-family: "Geist Mono", ui-monospace, monospace; font-size: 0.875em; }
table { width: 100%; border-collapse: collapse; margin: 1rem 0; font-size: 0.9rem; }
th, td { text-align: left; padding: 0.5rem 0.75rem; border: 1px solid var(--accrue-fog); }
[data-theme="dark"] th, [data-theme="dark"] td { border-color: var(--accrue-dark-elevated); }
th { background: var(--accrue-surface-sunken); font-weight: 600; }
[data-theme="dark"] th { background: var(--accrue-dark-sunken); }
tr:nth-child(even) td { background: var(--accrue-callout-surface); }
[data-theme="dark"] tr:nth-child(even) td { background: var(--accrue-dark-elevated); }
ul { margin: 0 0 0.75rem; padding-left: 1.5rem; }
li { margin: 0.25rem 0; }
hr { border: none; border-top: 1px solid var(--accrue-fog); margin: 2rem 0; }
[data-theme="dark"] hr { border-top-color: var(--accrue-dark-elevated); }

/* ---- SVG responsive ---- */
svg { max-width: 100%; height: auto; }

/* ---- Nav / TOC ---- */
.site-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 0;
  margin-bottom: 12px;
  border-bottom: 1px solid var(--accrue-fog);
  position: sticky;
  top: 0;
  background: var(--accrue-surface-base);
  z-index: 100;
}
[data-theme="dark"] .site-header {
  background: var(--accrue-dark-base);
  border-bottom-color: var(--accrue-dark-elevated);
}

.site-header nav ul {
  list-style: none;
  display: flex;
  flex-wrap: wrap;
  gap: 8px 16px;
  margin: 0;
  padding: 0;
}
.site-header nav a {
  font-size: 0.8125rem;
  text-decoration: none;
  color: var(--accrue-content-subtle);
}
.site-header nav a:hover { color: var(--accrue-content-primary); }
[data-theme="dark"] .site-header nav a { color: var(--accrue-dark-muted); }
[data-theme="dark"] .site-header nav a:hover { color: var(--accrue-dark-primary); }

#theme-toggle {
  background: none;
  border: 1px solid var(--accrue-fog);
  border-radius: 6px;
  color: var(--accrue-content-subtle);
  cursor: pointer;
  font-size: 0.8125rem;
  padding: 4px 10px;
  white-space: nowrap;
  flex-shrink: 0;
}
#theme-toggle:hover { border-color: var(--accrue-content-muted); color: var(--accrue-content-primary); }
[data-theme="dark"] #theme-toggle {
  border-color: var(--accrue-dark-elevated);
  color: var(--accrue-dark-muted);
}

/* ---- Mobile TOC — collapsed details ---- */
@media (max-width: 767px) {
  .site-header { flex-wrap: wrap; gap: 8px; }
  .site-header nav ul { gap: 6px 12px; }
}

/* ---- Sections ---- */
section { padding-top: 1rem; }

/* ---- Hero / Cover ---- */
.hero-logo { max-width: 280px; margin: 2rem auto; display: block; }
.hero-tagline { font-size: 1.375rem; text-align: center; color: var(--accrue-content-subtle); margin: 0 0 2rem; font-style: italic; }
[data-theme="dark"] .hero-tagline { color: var(--accrue-dark-muted); }

/* ---- Logo grid ---- */
.logo-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 16px; margin: 1rem 0; }
.logo-card {
  border: 1px solid var(--accrue-fog);
  border-radius: 8px;
  padding: 16px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  background: var(--accrue-surface-elevated);
}
[data-theme="dark"] .logo-card { border-color: var(--accrue-dark-elevated); background: var(--accrue-dark-elevated); }
.logo-card.dark-bg {
  background: var(--accrue-dark-base);
  border-color: var(--accrue-dark-elevated);
}
[data-theme="dark"] .logo-card.dark-bg { background: var(--accrue-dark-sunken); }
.logo-card .label { font-size: 0.75rem; color: var(--accrue-content-muted); text-align: center; }
[data-theme="dark"] .logo-card .label { color: var(--accrue-dark-muted); }

/* ---- Color swatches ---- */
.swatch {
  display: inline-block;
  width: 14px;
  height: 14px;
  border-radius: 3px;
  border: 1px solid var(--accrue-fog);
  vertical-align: middle;
  margin-right: 4px;
}

/* ---- Token table ---- */
.token-table code { font-size: 0.8125rem; }

/* ---- Favicon grid ---- */
.favicon-grid { display: flex; flex-wrap: wrap; gap: 16px; align-items: center; margin: 1rem 0; }
.favicon-grid figure { text-align: center; margin: 0; }
.favicon-grid figcaption { font-size: 0.75rem; color: var(--accrue-content-muted); margin-top: 4px; }
[data-theme="dark"] .favicon-grid figcaption { color: var(--accrue-dark-muted); }

/* ---- Provenance / footer ---- */
.provenance pre { white-space: pre-wrap; word-break: break-word; font-size: 0.8125rem; }
.milestone-tag { display: inline-block; background: var(--accrue-surface-sunken); border: 1px solid var(--accrue-fog); border-radius: 4px; padding: 2px 8px; font-size: 0.75rem; color: var(--accrue-content-muted); font-family: "Geist Mono", ui-monospace, monospace; margin-top: 1rem; }
[data-theme="dark"] .milestone-tag { background: var(--accrue-dark-sunken); border-color: var(--accrue-dark-elevated); color: var(--accrue-dark-muted); }

/* ---- Callout ---- */
.callout { background: var(--accrue-callout-surface); color: var(--accrue-callout-text); border-left: 3px solid var(--accrue-moss); border-radius: 0 6px 6px 0; padding: 0.75rem 1rem; margin: 1rem 0; font-size: 0.9rem; }
[data-theme="dark"] .callout { background: var(--accrue-dark-elevated); color: var(--accrue-dark-primary); border-left-color: var(--accrue-moss); }
</style>
</head>
<body>

<!-- ---- Sticky site header with TOC navigation ---- -->
<header class="site-header">
  <nav aria-label="Brand book sections">
    <ul>
      ${tocLinks}
    </ul>
  </nav>
  <button id="theme-toggle" aria-label="Toggle dark mode">Switch to dark</button>
</header>

<!-- =====================================================================
     Section 1: Cover / Hero
     ===================================================================== -->
<section id="section-cover">
  <div style="text-align:center; padding: 2rem 0 1rem;">
    <div class="hero-logo">
      ${logoSvgs["accrue-logo.svg"] || "<!-- accrue-logo.svg not found -->"}
    </div>
    <p class="hero-tagline">Billing state, modeled clearly.</p>
    <p style="color: var(--accrue-content-muted); font-size:0.875rem;">Accrue v1.52 Brand Book — the locked visual identity for the Accrue billing library.</p>
  </div>
</section>

<!-- =====================================================================
     Section 2: Logo System
     ===================================================================== -->
<section id="section-logo">
  <h2>Logo System</h2>
  <p>The Accrue logo system consists of 13 SVG source files and 8 raster exports. All logo SVGs use fully outlined paths — no live text elements, no embedded fonts.</p>

  <h3>Primary Lockups</h3>
  <div class="logo-grid">
    <div class="logo-card">
      ${logoSvgs["accrue-logo.svg"] || ""}
      <span class="label">Primary lockup (light)</span>
    </div>
    <div class="logo-card dark-bg">
      ${logoSvgs["accrue-logo-on-dark.svg"] || ""}
      <span class="label">Primary lockup (dark)</span>
    </div>
    <div class="logo-card">
      ${logoSvgs["accrue-logo-subtitle.svg"] || ""}
      <span class="label">With subtitle</span>
    </div>
  </div>

  <h3>Wordmark & Mark</h3>
  <div class="logo-grid">
    <div class="logo-card">
      ${logoSvgs["accrue-wordmark.svg"] || ""}
      <span class="label">Wordmark only</span>
    </div>
    <div class="logo-card">
      ${logoSvgs["accrue-mark.svg"] || ""}
      <span class="label">Mark only</span>
    </div>
    <div class="logo-card dark-bg">
      ${logoSvgs["accrue-mark-on-dark.svg"] || ""}
      <span class="label">Mark (dark)</span>
    </div>
  </div>

  <h3>Monochrome Variants</h3>
  <div class="logo-grid">
    <div class="logo-card">
      ${logoSvgs["accrue-logo-mono.svg"] || ""}
      <span class="label">Mono lockup</span>
    </div>
    <div class="logo-card dark-bg">
      ${logoSvgs["accrue-logo-mono-inverse.svg"] || ""}
      <span class="label">Mono inverse lockup</span>
    </div>
    <div class="logo-card">
      ${logoSvgs["accrue-mark-mono.svg"] || ""}
      <span class="label">Mono mark</span>
    </div>
    <div class="logo-card dark-bg">
      ${logoSvgs["accrue-mark-mono-inverse.svg"] || ""}
      <span class="label">Mono inverse mark</span>
    </div>
  </div>

  <h3>Clearspace Specification</h3>
  <div style="max-width:480px; margin:0 auto;">
    ${logoSvgs["accrue-clearspace.svg"] || ""}
  </div>
  <p style="font-size:0.875rem; color: var(--accrue-content-muted); margin-top:0.5rem;">Clearspace equals one step-height of the mark on all four sides.</p>

  <h3>Logo Usage Rules</h3>
  <div class="logo-usage">
    ${readmeLogoHtml}
  </div>
</section>

<!-- =====================================================================
     Section 3: Color Palette
     ===================================================================== -->
<section id="section-color">
  <h2>Color Palette</h2>
  <p>The Accrue color palette is documented in the specimen SVG below. Light-surface tokens use <code>--accrue-*</code> names; dark-surface tokens use <code>--accrue-dark-*</code> names and must be referenced explicitly in dark-mode CSS.</p>
  <div style="overflow-x:auto; margin:1rem 0;">
    ${specimenSvgs["palette.svg"] || "<!-- palette.svg not found -->"}
  </div>
  <div class="callout">
    <strong>Dark-mode note:</strong> The dark block defines new <code>--accrue-dark-*</code> variables — it does not override the light variable names. Dark-surface elements must explicitly reference <code>--accrue-dark-base</code>, <code>--accrue-dark-primary</code>, etc.
  </div>
</section>

<!-- =====================================================================
     Section 4: Typography
     ===================================================================== -->
<section id="section-typography">
  <h2>Typography</h2>
  <p>Accrue uses the Geist font family. All logo SVGs use fully outlined paths derived from Geist Sans Regular and Geist Mono Regular — no embedded font data. For body copy and UI text, declare <code>font-family: Geist, system-ui, sans-serif</code>.</p>
  <div style="overflow-x:auto; margin:1rem 0;">
    ${specimenSvgs["typography.svg"] || "<!-- typography.svg not found -->"}
  </div>
  <p style="font-size:0.875rem; color: var(--accrue-content-muted);">Type scale tokens are in <code>brandbook/tokens/</code> as admin <code>--ax-type-*</code> tokens. See the Token Reference section for brand-layer tokens.</p>
</section>

<!-- =====================================================================
     Section 5: Spacing
     ===================================================================== -->
<section id="section-spacing">
  <h2>Spacing</h2>
  <p>Spacing scale for layout and component composition. Admin <code>--ax-space-*</code> tokens are the implementation reference; brand-layer spacing is reference-only.</p>
  <div style="overflow-x:auto; margin:1rem 0;">
    ${specimenSvgs["spacing.svg"] || "<!-- spacing.svg not found -->"}
  </div>
</section>

<!-- =====================================================================
     Section 6: Voice & Tone
     ===================================================================== -->
<section id="section-voice">
  <h2>Voice &amp; Tone</h2>
  <div class="voice-content">
    ${voiceHtml}
  </div>
</section>

<!-- =====================================================================
     Section 7: Copy Blocks
     ===================================================================== -->
<section id="section-copy">
  <h2>Copy Blocks</h2>
  <p>Ready-to-paste copy blocks for GitHub, Hex.pm, HexDocs, landing pages, release notes, and microcopy. All blocks ratified in Phase 185.</p>
  <div class="copy-content">
    ${copyHtml}
  </div>
</section>

<!-- =====================================================================
     Section 8: Favicon & Social Card
     ===================================================================== -->
<section id="section-favicon">
  <h2>Favicon &amp; Social Card</h2>

  <h3>Favicon Suite</h3>
  <div class="favicon-grid">
    <figure>
      ${logoSvgs["favicon.svg"] || ""}
      <figcaption>favicon.svg</figcaption>
    </figure>
    <figure>
      <img src="logo/favicon-16.png" width="16" height="16" alt="16×16 favicon">
      <figcaption>16×16 PNG</figcaption>
    </figure>
    <figure>
      <img src="logo/favicon-32.png" width="32" height="32" alt="32×32 favicon">
      <figcaption>32×32 PNG</figcaption>
    </figure>
    <figure>
      <img src="logo/favicon-48.png" width="48" height="48" alt="48×48 favicon">
      <figcaption>48×48 PNG</figcaption>
    </figure>
    <figure>
      <img src="logo/apple-touch-icon.png" width="60" height="60" alt="Apple touch icon 180×180">
      <figcaption>apple-touch-icon.png (180×180)</figcaption>
    </figure>
    <figure>
      <img src="logo/icon-192.png" width="64" height="64" alt="PWA icon 192×192">
      <figcaption>icon-192.png (192×192)</figcaption>
    </figure>
    <figure>
      <img src="logo/icon-512.png" width="64" height="64" alt="PWA icon 512×512">
      <figcaption>icon-512.png (512×512)</figcaption>
    </figure>
  </div>

  <h3>Social Card</h3>
  <div style="max-width:600px; margin:0 auto;">
    ${logoSvgs["accrue-social-card.svg"] || ""}
    <p style="font-size:0.75rem; color: var(--accrue-content-muted); margin-top:0.5rem;">SVG source — 1200×630</p>
    <img src="logo/accrue-social-card.png" style="width:100%; max-width:600px; margin-top:8px;" alt="Accrue social card raster 1200×630">
    <p style="font-size:0.75rem; color: var(--accrue-content-muted); margin-top:0.25rem;">PNG export — use as <code>&lt;meta property="og:image"&gt;</code></p>
  </div>

  <h3>HTML &lt;head&gt; Snippet</h3>
  <pre><code class="language-html">&lt;link rel="icon" type="image/svg+xml" href="/favicon.svg"&gt;
&lt;link rel="icon" type="image/png" sizes="16x16" href="/favicon-16.png"&gt;
&lt;link rel="icon" type="image/png" sizes="32x32" href="/favicon-32.png"&gt;
&lt;link rel="shortcut icon" href="/favicon.ico"&gt;
&lt;link rel="apple-touch-icon" href="/apple-touch-icon.png"&gt;
&lt;meta property="og:image" content="/accrue-social-card.png"&gt;</code></pre>
</section>

<!-- =====================================================================
     Section 9: Token Reference
     ===================================================================== -->
<section id="section-tokens">
  <h2>Token Reference</h2>
  <p>All <code>--accrue-*</code> CSS custom properties defined in <code>brandbook/tokens/tokens.css</code>. Light tokens are in <code>:root</code>; dark tokens are in <code>:root[data-theme="dark"]</code>.</p>
  <div style="overflow-x:auto;">
    ${buildTokenTable(tokensCss)}
  </div>
  <p style="font-size:0.875rem; color: var(--accrue-content-muted); margin-top:0.75rem;">
    The <code>brandbook/tokens/tokens.json</code> DTCG SSOT contains the full token tree with role descriptions and admin <code>ax-*</code> mapping. The admin <code>ax-*</code> tokens in <code>accrue_admin/assets/css/theme.css</code> are the implementation SSOT — <code>--accrue-*</code> brand tokens are documentation references only.
  </p>
</section>

<!-- =====================================================================
     Section 10: Provenance / Footer
     ===================================================================== -->
<section id="section-provenance" class="provenance">
  <h2>Provenance</h2>
  <p>Font provenance statement for outlined letterform paths in the Accrue brand SVG files:</p>
  <pre>${licenseTxt.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")}</pre>
  <span class="milestone-tag">v1.52 — Accrue Brand System</span>
</section>

<!-- Dark-mode toggle script — vanilla JS, no imports, no framework -->
${darkModeScript}

</body>
</html>
`;

  // Ensure trailing newline
  const output = html.endsWith("\n") ? html : html + "\n";

  fs.writeFileSync(OUTPUT_PATH, output, "utf8");
  console.log("[assemble-brandbook] Wrote: brandbook/index.html");
}

// isMain guard
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  main();
}
