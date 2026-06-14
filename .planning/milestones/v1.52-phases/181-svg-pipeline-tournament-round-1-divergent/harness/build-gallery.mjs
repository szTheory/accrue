/**
 * build-gallery.mjs — Gallery HTML assembler
 *
 * Reads candidates/index.json and screenshots/, inlines each candidate's
 * SVG directly into the HTML, and writes round-1-gallery.html at the
 * phase root. The gallery is self-contained and opens via file:// in a browser.
 *
 * Each candidate section includes:
 *   - Inlined SVG preview
 *   - 8 context-matrix tile images (referenced by relative path from gallery)
 *   - Winner checkbox, keep/change note textareas
 *
 * Footer includes a "Copy verdict block" button + always-visible <pre> fallback.
 * The verdict-block JS (~60 lines vanilla, no deps) produces the D-11 schema.
 *
 * Usage:
 *   node harness/build-gallery.mjs   # build round-1-gallery.html
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

const argOutputDir = (() => {
  const i = process.argv.indexOf("--output-dir");
  return i !== -1 ? path.resolve(process.argv[i + 1]) : null;
})();
const argGalleryName = (() => {
  const i = process.argv.indexOf("--gallery-name");
  return i !== -1 ? process.argv[i + 1] : null;
})();

const PHASE_DIR = argOutputDir ?? path.resolve(__dirname, "..");
const CANDIDATES_DIR = path.join(PHASE_DIR, "candidates");
const SCREENSHOTS_DIR = path.join(PHASE_DIR, "screenshots");
const GALLERY_PATH = path.join(PHASE_DIR, argGalleryName ?? "round-1-gallery.html");

// Derive round label from gallery name (e.g. "round-2-gallery.html" → "Round 2")
const ROUND_LABEL = (() => {
  const name = argGalleryName ?? "";
  const m = name.match(/round-(\d+)/i);
  return m ? `Round ${m[1]}` : "Round 1";
})();

const TILES = [
  { id: "paper-light",   label: "Paper (light)" },
  { id: "ink-dark",      label: "Ink (dark)" },
  { id: "32px-favicon",  label: "32px favicon" },
  { id: "16px-favicon",  label: "16px favicon" },
  { id: "avatar-circle", label: "Avatar circle" },
  { id: "readme-header", label: "README header" },
  { id: "social-card",   label: "Social card" },
  { id: "mono",          label: "Monochrome" },
];

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Render a single candidate section */
function renderCandidate(candidate, svgContent) {
  const { id, direction, rationale, colorTreatment } = candidate;

  // Badge: show color treatment when available, otherwise direction
  const badgeLabel = colorTreatment ? `Color: ${colorTreatment}` : `Direction ${direction}`;

  // Build tile images (relative paths from gallery at phase root)
  const tilesHtml = TILES.map(tile => {
    const relPath = `screenshots/${id}/${tile.id}.png`;
    const absPath = path.join(SCREENSHOTS_DIR, id, `${tile.id}.png`);
    const exists = fs.existsSync(absPath);
    if (!exists) {
      return `<div class="tile tile-missing">
        <div class="tile-label">${tile.label}</div>
        <div class="tile-placeholder">screenshot missing</div>
      </div>`;
    }
    return `<div class="tile">
      <div class="tile-label">${tile.label}</div>
      <img src="${relPath}" alt="${tile.label}" loading="lazy">
    </div>`;
  }).join("\n      ");

  return `<section class="candidate" data-id="${id}">
  <div class="candidate-header">
    <h2 class="candidate-id">${id}</h2>
    <span class="direction-badge">${badgeLabel}</span>
  </div>
  <p class="rationale">${escapeHtml(rationale || "")}</p>

  <div class="svg-preview">
    ${svgContent}
  </div>

  <div class="context-matrix">
    ${tilesHtml}
  </div>

  <div class="verdict-controls">
    <label class="winner-label">
      <input type="checkbox" class="winner-cb">
      Pick as winner
    </label>
    <div class="notes-row">
      <label class="note-label">
        keep:<br>
        <textarea class="keep-note" rows="2" placeholder="What to keep from this candidate…"></textarea>
      </label>
      <label class="note-label">
        change:<br>
        <textarea class="change-note" rows="2" placeholder="What to change or refine…"></textarea>
      </label>
    </div>
  </div>
</section>`;
}

function escapeHtml(str) {
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

// ---------------------------------------------------------------------------
// CSS
// ---------------------------------------------------------------------------

const CSS = `
* { box-sizing: border-box; }
body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  background: #F5F7FA;
  color: #1a1a1a;
  margin: 0;
  padding: 0 0 80px;
}
header {
  background: #fff;
  border-bottom: 1px solid #E2E8F0;
  padding: 24px 32px;
  position: sticky;
  top: 0;
  z-index: 100;
}
header h1 {
  font-size: 1.4rem;
  font-weight: 600;
  margin: 0 0 6px;
}
header p {
  font-size: 0.875rem;
  color: #555;
  margin: 0;
}
main {
  max-width: 1400px;
  margin: 0 auto;
  padding: 32px;
}
h2.section-title {
  font-size: 1rem;
  font-weight: 600;
  color: #666;
  margin: 40px 0 16px;
  text-transform: uppercase;
  letter-spacing: 0.06em;
}
.candidate-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(640px, 1fr));
  gap: 24px;
}
.candidate {
  background: #fff;
  border: 1px solid #E2E8F0;
  border-radius: 10px;
  padding: 24px;
  transition: border-color 0.15s;
}
.candidate.selected {
  border-color: #3B82F6;
  box-shadow: 0 0 0 3px rgba(59,130,246,0.15);
}
.candidate-header {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 8px;
}
.candidate-id {
  font-size: 1.25rem;
  font-weight: 700;
  margin: 0;
}
.direction-badge {
  font-size: 0.75rem;
  font-weight: 500;
  background: #EFF6FF;
  color: #1D4ED8;
  padding: 2px 10px;
  border-radius: 20px;
}
.rationale {
  font-size: 0.875rem;
  color: #555;
  margin: 0 0 16px;
  line-height: 1.5;
}
.svg-preview {
  background: #FAFBFC;
  border: 1px solid #E2E8F0;
  border-radius: 6px;
  padding: 16px;
  margin-bottom: 16px;
  overflow: hidden;
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 80px;
}
.svg-preview svg {
  max-width: 100%;
  max-height: 120px;
}
.context-matrix {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 8px;
  margin-bottom: 16px;
}
.tile {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.tile-label {
  font-size: 0.7rem;
  color: #888;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.tile img {
  width: 100%;
  height: auto;
  border: 1px solid #E2E8F0;
  border-radius: 3px;
  background: #FAFBFC;
  image-rendering: pixelated;
}
.tile-missing .tile-placeholder {
  font-size: 0.7rem;
  color: #ccc;
  padding: 8px 0;
}
.verdict-controls {
  border-top: 1px solid #E9EEF2;
  padding-top: 16px;
}
.winner-label {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 0.875rem;
  font-weight: 600;
  cursor: pointer;
  margin-bottom: 12px;
}
.winner-label input[type=checkbox] {
  width: 16px;
  height: 16px;
  cursor: pointer;
  accent-color: #3B82F6;
}
.notes-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}
.note-label {
  font-size: 0.8rem;
  color: #555;
  font-weight: 500;
}
.keep-note, .change-note {
  width: 100%;
  font-size: 0.8rem;
  font-family: inherit;
  border: 1px solid #D1D5DB;
  border-radius: 4px;
  padding: 6px 8px;
  resize: vertical;
  margin-top: 4px;
  color: #1a1a1a;
}
.keep-note:focus, .change-note:focus {
  outline: none;
  border-color: #3B82F6;
  box-shadow: 0 0 0 2px rgba(59,130,246,0.15);
}
.verdict-section {
  background: #fff;
  border: 1px solid #E2E8F0;
  border-radius: 10px;
  padding: 28px 32px;
  margin-top: 40px;
}
.verdict-section h2 {
  font-size: 1.1rem;
  font-weight: 600;
  margin: 0 0 8px;
}
.verdict-section p {
  font-size: 0.875rem;
  color: #555;
  margin: 0 0 16px;
}
#copy-btn {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  background: #1a1a1a;
  color: #fff;
  border: none;
  border-radius: 6px;
  padding: 10px 20px;
  font-size: 0.875rem;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.15s;
  margin-bottom: 16px;
}
#copy-btn:hover { background: #333; }
#copy-btn.copied { background: #16A34A; }
#verdict-pre {
  background: #F8FAFC;
  border: 1px solid #E2E8F0;
  border-radius: 6px;
  padding: 16px;
  font-family: 'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, monospace;
  font-size: 0.8rem;
  line-height: 1.6;
  white-space: pre-wrap;
  word-break: break-word;
  color: #1a1a1a;
  min-height: 120px;
  cursor: text;
  user-select: all;
}
`;

// ---------------------------------------------------------------------------
// Verdict JS (~60 lines vanilla)
// ---------------------------------------------------------------------------

const VERDICT_JS = `
function buildVerdictBlock() {
  var winners = [], killed = [], notes = {};
  document.querySelectorAll('.candidate').forEach(function(el) {
    var id = el.dataset.id;
    if (el.querySelector('.winner-cb').checked) {
      winners.push(id);
      notes[id] = {
        keep: el.querySelector('.keep-note').value.trim(),
        change: el.querySelector('.change-note').value.trim()
      };
    } else {
      killed.push(id);
    }
  });

  var today = new Date().toISOString().split('T')[0];
  var lines = [];
  lines.push('## ROUND_LABEL_PLACEHOLDER — ' + today);
  lines.push('**Winners:** ' + winners.join(', '));
  lines.push('**Killed:** ' + killed.join(' '));
  lines.push('');

  for (var i = 0; i < winners.length; i++) {
    var id = winners[i];
    lines.push('### ' + id);
    lines.push('- keep: "' + (notes[id].keep || '') + '"');
    lines.push('- change: "' + (notes[id].change || '') + '"');
    lines.push('');
  }

  lines.push('### Constraints (extracted by agent, user-confirmed)');
  lines.push('(leave blank — agent fills after round)');
  lines.push('');

  return lines.join('\\n');
}

document.getElementById('copy-btn').addEventListener('click', function() {
  var block = buildVerdictBlock();
  document.getElementById('verdict-pre').textContent = block;

  var btn = document.getElementById('copy-btn');
  if (navigator.clipboard) {
    navigator.clipboard.writeText(block).then(function() {
      btn.textContent = 'Copied!';
      btn.classList.add('copied');
      setTimeout(function() {
        btn.textContent = 'Copy verdict block';
        btn.classList.remove('copied');
      }, 2000);
    }).catch(function() {
      // Clipboard API denied — pre fallback is always visible
    });
  }
});

// Highlight winner candidates as user checks them
document.querySelectorAll('.winner-cb').forEach(function(cb) {
  cb.addEventListener('change', function() {
    var section = cb.closest('.candidate');
    if (cb.checked) {
      section.classList.add('selected');
    } else {
      section.classList.remove('selected');
    }
  });
});
`;

// ---------------------------------------------------------------------------
// Build gallery HTML
// ---------------------------------------------------------------------------

function buildGallery(candidates) {
  // Determine if any candidate uses colorTreatment (Round 2 grouping)
  const hasColorTreatment = candidates.some(c => c.colorTreatment);

  let sections = "";
  const totalCount = candidates.length;

  if (hasColorTreatment) {
    // Round 2: group by colorTreatment — ink → moss → two-tone
    const colorTreatmentNames = {
      "ink":      "Ink — Monochrome Baseline",
      "moss":     "Full Moss (#5E9E84)",
      "two-tone": "Two-tone: Ink + Moss Accent",
    };

    const byColorTreatment = {};
    for (const c of candidates) {
      const key = c.colorTreatment ?? "ink";
      if (!byColorTreatment[key]) byColorTreatment[key] = [];
      byColorTreatment[key].push(c);
    }

    for (const treatment of ["ink", "moss", "two-tone"]) {
      const treatmentCandidates = byColorTreatment[treatment];
      if (!treatmentCandidates || treatmentCandidates.length === 0) continue;

      const cards = treatmentCandidates.map(c => {
        const svgPath = path.join(CANDIDATES_DIR, `${c.id}.svg`);
        const svgContent = fs.existsSync(svgPath)
          ? fs.readFileSync(svgPath, "utf8")
          : `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 80"><text x="10" y="50" fill="#ccc">SVG missing</text></svg>`;
        return renderCandidate(c, svgContent);
      }).join("\n");

      sections += `
  <h2 class="section-title">${colorTreatmentNames[treatment] || treatment}</h2>
  <div class="candidate-grid">
    ${cards}
  </div>`;
    }
  } else {
    // Round 1 (backward compatibility): group by direction letter
    const byDirection = {};
    for (const c of candidates) {
      if (!byDirection[c.direction]) byDirection[c.direction] = [];
      byDirection[c.direction].push(c);
    }

    const directionNames = {
      A: "Direction A — Accumulation Strata",
      B: "Direction B — Stepped Intervals",
      C: "Direction C — Layered Arcs",
      D: "Direction D — Integrated Typemark",
    };

    for (const dir of ["A", "B", "C", "D"]) {
      const dirCandidates = byDirection[dir];
      if (!dirCandidates || dirCandidates.length === 0) continue;

      const cards = dirCandidates.map(c => {
        const svgPath = path.join(CANDIDATES_DIR, `${c.id}.svg`);
        const svgContent = fs.existsSync(svgPath)
          ? fs.readFileSync(svgPath, "utf8")
          : `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 80"><text x="10" y="50" fill="#ccc">SVG missing</text></svg>`;
        return renderCandidate(c, svgContent);
      }).join("\n");

      sections += `
  <h2 class="section-title">${directionNames[dir] || `Direction ${dir}`}</h2>
  <div class="candidate-grid">
    ${cards}
  </div>`;
    }
  }

  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Accrue ${ROUND_LABEL} Gallery</title>
<style>${CSS}</style>
</head>
<body>
<header>
  <h1>Accrue Logo Tournament — ${ROUND_LABEL}</h1>
  <p>
    ${totalCount} candidates.
    Check the winners below, add keep/change notes, then click <strong>Copy verdict block</strong>.
    Paste the result into TOURNAMENT.md at the <code>&lt;!-- ROUND-2-APPEND-BELOW --&gt;</code> marker.
  </p>
</header>

<main>
${sections}

  <div class="verdict-section">
    <h2>Verdict Block</h2>
    <p>
      Select winners above, add notes, then copy. If the Copy button fails (some browsers
      restrict clipboard on file:// pages), select all text from the box below.
    </p>
    <button id="copy-btn">Copy verdict block</button>
    <p>Or select all from the box below (click to select):</p>
    <pre id="verdict-pre" onclick="this.select()" title="Click to select all">Click 'Copy verdict block' above — or click here to select the text manually.</pre>
  </div>
</main>

<script>
${VERDICT_JS.replace("ROUND_LABEL_PLACEHOLDER", ROUND_LABEL)}
</script>
</body>
</html>`;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  // Step 1 — Guard: check candidates exist
  const indexPath = path.join(CANDIDATES_DIR, "index.json");
  if (!fs.existsSync(indexPath)) {
    console.error(`[gallery] No candidates/index.json found in ${CANDIDATES_DIR} — run generate.mjs first`);
    process.exit(1);
  }

  const candidates = JSON.parse(fs.readFileSync(indexPath, "utf8"));
  if (!Array.isArray(candidates) || candidates.length === 0) {
    console.error(`[gallery] No candidates found in ${CANDIDATES_DIR} — run generate.mjs first`);
    process.exit(1);
  }

  console.log(`[gallery] Building gallery for ${candidates.length} candidates…`);

  // Warn if below minimum
  const MIN_GALLERY = 12;
  if (candidates.length < MIN_GALLERY) {
    console.warn(`[gallery] WARN: only ${candidates.length} candidates — below minimum ${MIN_GALLERY}`);
  }

  // Check which candidates have screenshots
  let missingScreenshots = 0;
  for (const c of candidates) {
    const screenshotDir = path.join(SCREENSHOTS_DIR, c.id);
    if (!fs.existsSync(screenshotDir)) {
      console.warn(`[gallery] WARN: no screenshots for ${c.id} — run render-matrix.mjs first`);
      missingScreenshots++;
    }
  }
  if (missingScreenshots > 0) {
    console.warn(`[gallery] WARN: ${missingScreenshots} candidates missing screenshots — tiles will show placeholder`);
  }

  // Step 2 — Build HTML
  const html = buildGallery(candidates);

  // Step 3 — Write gallery
  fs.writeFileSync(GALLERY_PATH, html);

  const fileSizeKB = Math.round(fs.statSync(GALLERY_PATH).size / 1024);
  console.log(`[gallery] Written ${GALLERY_PATH} (${fileSizeKB} KB, ${candidates.length} candidates)`);

  if (fileSizeKB > 5 * 1024) {
    console.warn(`[gallery] WARN: gallery file size ${fileSizeKB} KB exceeds 5 MB — check for accidental base64 data`);
  }
}

await main();
