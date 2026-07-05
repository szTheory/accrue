/**
 * ratchet-digest.mjs — the single visual surface Phase 207 produces (ORCH-02). Renders the
 * maintainer's per-round read surface: a self-contained, offline HTML digest of confirmed
 * findings grouped by surface with region overlays, a ranked auto-fixable worklist and a
 * separate IA/product-decision queue, and the sticky summary banner in its 4 locked states.
 * It also assembles the round's `round-NN/` artifact directory (PNGs + `.bbox.json` copied in
 * at render time) and writes the pre-filled `decisions.json` checkpoint (D-42) that 207-06's
 * apply-decisions reader consumes.
 *
 * 207-UI-SPEC.md is the BINDING visual contract for the rendered HTML. This file twins
 * `phase192-gallery.mjs`'s STRUCTURAL idiom (row-builders + a `REQUIRED_FIELDS` validator +
 * `runSelfTest()`/`--self-test`/`import.meta.url` guard) — not its literal Markdown output;
 * this renders HTML.
 *
 * Independence discipline (mirrors `scripts/ci/verify_ratchet_ledger.mjs`): the convergence
 * DISPLAY derived here re-derives round/dry/epoch/status from `rounds.ndjson` for the banner
 * only — it NEVER imports or recomputes 207-01's gate classification. The gate (the ledger
 * reducer + regressions) is authoritative; this digest never re-decides pass/fail.
 *
 * Zero external deps (D-53): only `node:fs`/`node:os`/`node:path`/`node:url` plus `{ fold }`
 * from `./ratchet-ledger.js`. No network, no CDN, no webfont — the emitted HTML opens offline.
 * Deterministic: given identical `findings.ledger.ndjson` + `rounds.ndjson` + `.bbox.json`
 * inputs, the produced HTML is byte-identical (no `Date.now()`/`Math.random()` anywhere).
 */

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { fold } from "./ratchet-ledger.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// -----------------------------------------------------------------------------
// Path constants. `LEDGER_PATH`/`ROUNDS_PATH` match `phase-ratchet-ledger.mjs`'s
// `DEFAULT_PATHS` exactly (same directory). `CAPTURE_DIR` is Phase 205's flat capture root;
// `ROUND_OUTPUT_ROOT` is the gitignored per-round artifact tree this digest assembles into.
// -----------------------------------------------------------------------------
const LEDGER_PATH = path.join(__dirname, "findings.ledger.ndjson");
const ROUNDS_PATH = path.join(__dirname, "rounds.ndjson");
const CAPTURE_DIR = path.join(__dirname, "../../test-results/admin-visuals");
const ROUND_OUTPUT_ROOT = path.join(__dirname, "../../test-results/ui-ratchet");

// -----------------------------------------------------------------------------
// Region-overlay scale (D-55 + RESEARCH Pitfall 2). These are the REAL Playwright capture
// widths, verified against `playwright.config.js`'s explicit `viewport: {width:1280,...}`
// override (desktop) and `devices["Pixel 5"]`'s actual `393` (mobile). This DELIBERATELY
// diverges from `baseline-manifest.js`'s `PROJECTS[...].viewport_width` (1440/390), which is
// stale documentation, not the real capture config — do NOT read `viewport_width` from
// `baseline-manifest.js` for the overlay math.
// -----------------------------------------------------------------------------
const CAPTURE_VIEWPORT_WIDTHS = { "chromium-desktop": 1280, "chromium-mobile": 393 };

// Fixed on-page display width per project so the absolutely-positioned overlay pixels are
// exact against the rendered `<img>` (which is displayed at this width). A uniform scale
// preserves aspect, so bbox y/height map correctly too. Deterministic — no viewport math.
const DISPLAY_WIDTHS = { "chromium-desktop": 960, "chromium-mobile": 393 };

// The theme suffixes/projects a surface may have been captured under (D-09 capture matrix).
const THEME_SUFFIXES = ["", "-dark"];
const CAPTURE_PROJECTS = ["chromium-desktop", "chromium-mobile"];

// Fields every rendered worklist/decisions-needed row must carry non-empty before rendering
// (the UI-SPEC "Data Fields Rendered Per Finding" table). Mirrors phase192-gallery.mjs's
// `validateGalleryRows` failure-collecting pattern.
const REQUIRED_ROW_FIELDS = [
  "finding_id",
  "surface",
  "region_tag",
  "severity",
  "persona_frequency",
  "defect",
  "suggested_fix",
];

// -----------------------------------------------------------------------------
// Small IO helper (absence-safe, twin of the sibling ledger scripts' convention).
// -----------------------------------------------------------------------------

/** readNdjsonRows(absPath) — an absent or empty file parses to `[]`; never throws on absence. */
function readNdjsonRows(absPath) {
  let raw;
  try {
    raw = fs.readFileSync(absPath, "utf8");
  } catch (err) {
    if (err && err.code === "ENOENT") return [];
    throw err;
  }
  const text = raw.trim();
  if (!text) return [];
  return text.split("\n").map((line) => JSON.parse(line));
}

// -----------------------------------------------------------------------------
// Convergence DISPLAY (banner only — never the gate). Independent re-derivation of
// round/dry/epoch/consecutiveDry/status from `rounds.ndjson`, using the identical K=2 /
// round-6 thresholds as 207-01's `classifyRoundStatus`, WITHOUT importing it.
// -----------------------------------------------------------------------------

/**
 * computeConvergenceDisplay(roundsRows) — pure. Returns the latest round's
 * `{round, dry, epoch, consecutiveDry, status}` for the banner. Latest = max `round`
 * (ties broken by max `seq`). `consecutiveDry` is the trailing run-length of `dry === true`
 * among rows in the latest row's epoch, in `seq` order (a streak never leaks across an epoch
 * boundary, D-49). `status ∈ {"converged","cap-reached","continue"}` via K=2 / 6-cap. An
 * empty log yields the neutral `{round:0, dry:false, epoch:0, consecutiveDry:0, status:"continue"}`.
 */
function computeConvergenceDisplay(roundsRows) {
  if (!Array.isArray(roundsRows) || roundsRows.length === 0) {
    return { round: 0, dry: false, epoch: 0, consecutiveDry: 0, status: "continue" };
  }
  const latest = roundsRows.reduce((best, row) => {
    if (best === null) return row;
    const r = row.round || 0;
    const br = best.round || 0;
    if (r > br) return row;
    if (r === br && (row.seq || 0) > (best.seq || 0)) return row;
    return best;
  }, null);

  const epoch = latest.epoch;
  const scoped = roundsRows
    .filter((row) => row.epoch === epoch)
    .slice()
    .sort((a, b) => (a.seq || 0) - (b.seq || 0));
  let consecutiveDry = 0;
  for (let i = scoped.length - 1; i >= 0; i--) {
    if (scoped[i].dry === true) consecutiveDry += 1;
    else break;
  }

  const round = latest.round || 0;
  let status;
  if (consecutiveDry >= 2) status = "converged";
  else if (round >= 6) status = "cap-reached";
  else status = "continue";

  return { round, dry: latest.dry === true, epoch, consecutiveDry, status };
}

// -----------------------------------------------------------------------------
// Summary banner copy (the 4 locked UI-SPEC states). Pure — returns a structured object whose
// `headline` is the EXACT copy string; the renderer maps it to markup.
// -----------------------------------------------------------------------------

/**
 * buildSummaryBanner({round, confirmed, rootCause, iaDecisions, status, consecutiveDry}) —
 * returns `{state, headline, badge, emptyHeading, emptyBody}` matching exactly one of the 4
 * UI-SPEC banner states. Precedence: converged > cap-reached > empty > normal (a converged
 * round has 0 open findings, so it must win over the empty state and still show the
 * `CONVERGED` badge over the standard headline).
 */
function buildSummaryBanner({ round, confirmed, rootCause, iaDecisions, status, consecutiveDry }) {
  const normalHeadline =
    `Round ${round} — ${confirmed} confirmed, ${rootCause} root-cause, ${iaDecisions} IA decisions`;

  if (status === "converged") {
    return {
      state: "converged",
      headline: normalHeadline,
      badge: { glyph: "✓", text: `CONVERGED (${consecutiveDry} dry rounds)`, tone: "accent" },
      emptyHeading: null,
      emptyBody: null,
    };
  }
  if (status === "cap-reached") {
    return {
      state: "cap-reached",
      headline: `CAP REACHED — 6 rounds, ${confirmed} open, not converged`,
      badge: { glyph: "⚠", text: "CAP REACHED", tone: "danger" },
      emptyHeading: null,
      emptyBody: null,
    };
  }
  if (confirmed === 0) {
    return {
      state: "empty",
      headline: `Round ${round} — 0 confirmed findings`,
      badge: null,
      emptyHeading: "No confirmed findings this round",
      emptyBody:
        `Round ${round} re-verified every surface in scope and found nothing new to fix. ` +
        `If this continues for one more round, the loop reports CONVERGED.`,
    };
  }
  return {
    state: "normal",
    headline: normalHeadline,
    badge: null,
    emptyHeading: null,
    emptyBody: null,
  };
}

// -----------------------------------------------------------------------------
// Ranking / partition (D-54 predicate + D-56 sort keys, zero non-determinism).
// -----------------------------------------------------------------------------

const SEVERITY_ORDER = { real: 0, minor: 1 };
const EFFORT_ORDER = { css: 0, null: 1 };

/** severityRank(sev) — real→0, minor→1, anything else→2 (sorts last, deterministically). */
function severityRank(sev) {
  return sev in SEVERITY_ORDER ? SEVERITY_ORDER[sev] : 2;
}

/** effortRank(effortClass) — `"css"`→0, `null`→1 (cheap auto-fixable wins first). */
function effortRank(effortClass) {
  if (effortClass === "css") return 0;
  return 1; // null (or any non-css worklist value)
}

/**
 * partitionFindings(foldedOpenFindings) — splits `open` findings into `{worklist,
 * decisionsNeeded}` by the D-54 predicate (`effort_class === "ia-product-decision"` →
 * decisionsNeeded; else → worklist) and sorts each per the exact D-56 keys. Defensively
 * filters to `status === "open"` so a caller may pass the full folded set. Fully deterministic:
 * every comparator ends on `finding_id` ascending, so ordering never depends on sort stability.
 */
function partitionFindings(foldedOpenFindings) {
  const open = (foldedOpenFindings || []).filter((f) => f.status === "open");
  const worklist = [];
  const decisionsNeeded = [];
  for (const f of open) {
    if (f.effort_class === "ia-product-decision") decisionsNeeded.push(f);
    else worklist.push(f);
  }

  const byFindingId = (a, b) => String(a.finding_id).localeCompare(String(b.finding_id));
  const bySeverityThenFreq = (a, b) => {
    const sev = severityRank(a.severity) - severityRank(b.severity);
    if (sev !== 0) return sev;
    return (b.persona_frequency || 0) - (a.persona_frequency || 0); // desc
  };

  worklist.sort((a, b) => {
    const base = bySeverityThenFreq(a, b);
    if (base !== 0) return base;
    const eff = effortRank(a.effort_class) - effortRank(b.effort_class);
    if (eff !== 0) return eff;
    return byFindingId(a, b);
  });
  decisionsNeeded.sort((a, b) => {
    const base = bySeverityThenFreq(a, b);
    if (base !== 0) return base;
    return byFindingId(a, b);
  });

  return { worklist, decisionsNeeded };
}

// -----------------------------------------------------------------------------
// decisions.json row-builder (D-42) — the CONTRACT 207-06's apply-decisions reader depends on.
// -----------------------------------------------------------------------------

/**
 * buildDecisionsJsonRows(worklist) — one pre-filled `approve` row per worklist finding:
 * `{finding_id, decision, surface, summary, region_tag}`. `summary` is the finding's `defect`
 * prose (the human-readable one-liner the maintainer edits before running `ui.fix`).
 */
function buildDecisionsJsonRows(worklist) {
  return (worklist || []).map((f) => ({
    finding_id: f.finding_id,
    decision: "approve",
    surface: f.surface,
    summary: f.defect,
    region_tag: f.region_tag,
  }));
}

// -----------------------------------------------------------------------------
// Row validator (twins phase192-gallery.mjs's `validateGalleryRows`: collect failures, throw a
// joined message). Run before rendering so a malformed ledger row fails loud, not silently.
// -----------------------------------------------------------------------------

/**
 * validateDigestRows(rows, sectionLabel) — asserts every `REQUIRED_ROW_FIELDS` value is present
 * and non-empty on each row. Throws a single joined message listing every failure, or returns
 * the rows unchanged on success.
 */
function validateDigestRows(rows, sectionLabel = "row") {
  const failures = [];
  (rows || []).forEach((row, index) => {
    for (const field of REQUIRED_ROW_FIELDS) {
      const value = row[field];
      if (value === null || value === undefined || String(value).trim() === "") {
        failures.push(`${sectionLabel} ${index + 1} missing ${field}`);
      }
    }
  });
  if (failures.length > 0) throw new Error(failures.join("; "));
  return rows;
}

// -----------------------------------------------------------------------------
// HTML escaping (T-207-04 mitigation). Ledger prose (`defect`/`suggested_fix`) originates as
// LLM free-text (Phase 205) and is the FIRST place in the repo rendered as HTML rather than
// Markdown/plain data — every interpolated string field passes through here.
// -----------------------------------------------------------------------------

/** escapeHtml(value) — standard `&<>"'` entity escaping; null/undefined → "". */
function escapeHtml(value) {
  if (value === null || value === undefined) return "";
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

// -----------------------------------------------------------------------------
// Region overlay scale (D-55). `computeOverlayScale(renderedWidth, project)` =
// `renderedWidth / CAPTURE_VIEWPORT_WIDTHS[project]` — the REAL capture width (1280/393), NOT
// baseline-manifest.js's stale 1440/390.
// -----------------------------------------------------------------------------

/** computeOverlayScale(renderedWidth, project) — rendered/captured width ratio for the project. */
function computeOverlayScale(renderedWidth, project) {
  const captureWidth = CAPTURE_VIEWPORT_WIDTHS[project];
  if (!captureWidth) throw new Error(`computeOverlayScale: unknown project ${JSON.stringify(project)}`);
  return renderedWidth / captureWidth;
}

/**
 * scaleBox(bbox, project) — apply the display scale to a capture-viewport `{x,y,width,height}`
 * box, yielding on-page CSS px against the rendered `<img>` (displayed at `DISPLAY_WIDTHS`).
 * Returns `null` for a `null`/absent box (selector wasn't present at capture time, D-55).
 */
function scaleBox(bbox, project) {
  if (!bbox || typeof bbox !== "object") return null;
  const scale = computeOverlayScale(DISPLAY_WIDTHS[project], project);
  return {
    left: bbox.x * scale,
    top: bbox.y * scale,
    width: bbox.width * scale,
    height: bbox.height * scale,
  };
}

// -----------------------------------------------------------------------------
// round-NN artifact assembly (RESEARCH Pitfall 1's resolution). Copies FROM the flat Phase-205
// capture dir INTO a new round-scoped directory — never mutates the capture dir or the
// hardcoded flat paths in `admin-visuals.spec.js` / `ratchet-propose.mjs`.
// -----------------------------------------------------------------------------

/** resolveRoundDir(round) — `test-results/ui-ratchet/round-NN/` (zero-padded). */
function resolveRoundDir(round) {
  return path.join(ROUND_OUTPUT_ROOT, `round-${String(round).padStart(2, "0")}`);
}

/**
 * assembleRoundArtifacts(round, findings) — makes the round dir, then for every surface
 * referenced by a confirmed finding copies that surface's PNG(s) + `.bbox.json` sidecar(s)
 * (light/dark × each capture project) from `CAPTURE_DIR/{project}/` into
 * `roundDir/{project}/` (per-project subdir avoids the desktop/mobile filename collision on a
 * shared surface name). A missing source combination is skipped silently — capture may not
 * have produced every surface × project × theme. Returns the round dir path.
 */
function assembleRoundArtifacts(round, findings) {
  const roundDir = resolveRoundDir(round);
  fs.mkdirSync(roundDir, { recursive: true });

  const surfaces = new Set((findings || []).map((f) => f.surface).filter(Boolean));
  for (const surface of surfaces) {
    for (const project of CAPTURE_PROJECTS) {
      const srcProjectDir = path.join(CAPTURE_DIR, project);
      const destProjectDir = path.join(roundDir, project);
      for (const suffix of THEME_SUFFIXES) {
        for (const kind of [".png", ".bbox.json"]) {
          const name = `${surface}${suffix}${kind}`;
          const src = path.join(srcProjectDir, name);
          if (!fs.existsSync(src)) continue; // additive — never require every combination
          fs.mkdirSync(destProjectDir, { recursive: true });
          fs.cpSync(src, path.join(destProjectDir, name));
        }
      }
    }
  }
  return roundDir;
}

/**
 * buildGalleryGroups(roundDir, findings) — reads the assembled `.bbox.json` sidecars and
 * resolves each confirmed finding's per-project/per-theme overlay box into on-page px, returning
 * the pure `galleryGroups` structure `renderDigestHtml` consumes (so the renderer stays
 * fs-free/testable). Findings are grouped by `surface`; each group lists the images actually
 * present in `roundDir` with their scaled overlays and any region-absent notes.
 */
function buildGalleryGroups(roundDir, findings) {
  const bySurface = new Map();
  for (const f of findings || []) {
    if (!f.surface) continue;
    if (!bySurface.has(f.surface)) bySurface.set(f.surface, []);
    bySurface.get(f.surface).push(f);
  }

  const groups = [];
  for (const surface of Array.from(bySurface.keys()).sort()) {
    const surfaceFindings = bySurface.get(surface);
    const images = [];
    for (const project of CAPTURE_PROJECTS) {
      for (const suffix of THEME_SUFFIXES) {
        const theme = suffix === "-dark" ? "dark" : "light";
        const pngRel = `./${project}/${surface}${suffix}.png`;
        const pngAbs = path.join(roundDir, project, `${surface}${suffix}.png`);
        if (!fs.existsSync(pngAbs)) continue;

        let bbox = {};
        const bboxAbs = path.join(roundDir, project, `${surface}${suffix}.bbox.json`);
        if (fs.existsSync(bboxAbs)) {
          try {
            bbox = JSON.parse(fs.readFileSync(bboxAbs, "utf8")) || {};
          } catch {
            bbox = {};
          }
        }

        const overlays = [];
        const absentRegions = [];
        for (const f of surfaceFindings) {
          const box = bbox[f.region_tag];
          const scaled = scaleBox(box, project);
          if (scaled) {
            overlays.push({ finding_id: f.finding_id, region_tag: f.region_tag, ...scaled });
          } else {
            absentRegions.push({ finding_id: f.finding_id, region_tag: f.region_tag });
          }
        }
        images.push({ project, theme, src: pngRel, displayWidth: DISPLAY_WIDTHS[project], overlays, absentRegions });
      }
    }
    groups.push({ surface, findings: surfaceFindings, images });
  }
  return groups;
}

/**
 * writeDecisionsJson(roundDir, rows) — writes `decisions.json` (2-space indent + trailing
 * newline, matching the repo's `export_copy_strings`-style JSON convention). This is the
 * checkpoint file the maintainer edits and 207-06's apply-decisions reader consumes.
 */
function writeDecisionsJson(roundDir, rows) {
  const dest = path.join(roundDir, "decisions.json");
  fs.writeFileSync(dest, `${JSON.stringify(rows, null, 2)}\n`);
  return dest;
}

// -----------------------------------------------------------------------------
// HTML rendering (207-UI-SPEC.md is the binding contract). Single self-contained document:
// inline <style>, no external requests, `prefers-color-scheme` (not `data-theme`), system Geist
// (no webfont), severity glyph+color pairing (never color alone), relative image src.
// -----------------------------------------------------------------------------

const SEVERITY_DISPLAY = {
  real: { glyph: "■", label: "REAL", cls: "sev-real" },
  minor: { glyph: "△", label: "MINOR", cls: "sev-minor" },
};

/** renderSeverity(sev) — glyph + label span pair (D-56: shape+color, never color alone). */
function renderSeverity(sev) {
  const d = SEVERITY_DISPLAY[sev] || { glyph: "•", label: escapeHtml(sev || "—"), cls: "sev-unknown" };
  return `<span class="sev ${d.cls}"><span class="sev-glyph" aria-hidden="true">${d.glyph}</span> ${escapeHtml(
    d.label
  )}</span>`;
}

/** renderFindingRow(f) — one `<tr>` for the worklist/decisions-needed tables. */
function renderFindingRow(f) {
  return `        <tr>
          <td class="col-sev">${renderSeverity(f.severity)}</td>
          <td class="col-id"><code>${escapeHtml(f.finding_id)}</code></td>
          <td class="col-loc"><code>${escapeHtml(f.surface)}</code> · <code>${escapeHtml(
    f.region_tag
  )}</code><br><span class="muted mono">${escapeHtml(f.claim_key)}</span></td>
          <td class="col-freq"><span class="freq">×${escapeHtml(String(f.persona_frequency))}</span></td>
          <td class="col-defect"><p class="defect">${escapeHtml(f.defect)}</p><p class="fix muted">${escapeHtml(
    f.suggested_fix
  )}</p></td>
        </tr>`;
}

/** renderTableSection(id, heading, rows, emptyNote) — a `<section>` with a findings `<table>`. */
function renderTableSection(id, heading, rows, emptyNote) {
  const body = rows.length
    ? rows.map(renderFindingRow).join("\n")
    : `        <tr><td colspan="5" class="muted">${escapeHtml(emptyNote)}</td></tr>`;
  return `  <section id="${id}">
    <h2>${escapeHtml(heading)}</h2>
    <table>
      <thead>
        <tr><th>Severity</th><th>Finding</th><th>Location</th><th>Freq</th><th>Defect &amp; suggested fix</th></tr>
      </thead>
      <tbody>
${body}
      </tbody>
    </table>
  </section>`;
}

/** renderOverlay(o) — one absolutely-positioned outline box + finding_id label chip. */
function renderOverlay(o) {
  const style = `left:${o.left}px;top:${o.top}px;width:${o.width}px;height:${o.height}px;`;
  return `<div class="overlay" style="${style}"><span class="overlay-label">${escapeHtml(
    o.finding_id
  )}</span></div>`;
}

/** renderGalleryGroup(group) — a per-surface `<details>` with each image + its overlays. */
function renderGalleryGroup(group) {
  const imagesHtml = group.images
    .map((img) => {
      const overlays = img.overlays.map(renderOverlay).join("");
      const absentNotes = img.absentRegions
        .map(
          (a) =>
            `<p class="muted absent-note">${escapeHtml(a.region_tag)} not present on this surface/theme at capture time — no overlay drawn.</p>`
        )
        .join("\n        ");
      return `      <figure class="shot">
        <figcaption class="muted">${escapeHtml(group.surface)} · ${escapeHtml(img.project)} · ${escapeHtml(
        img.theme
      )}</figcaption>
        <div class="shot-frame" style="width:${img.displayWidth}px">
          <img src="${escapeHtml(img.src)}" alt="${escapeHtml(group.surface)} ${escapeHtml(
        img.theme
      )} screenshot" width="${img.displayWidth}">
          ${overlays}
        </div>
        ${absentNotes}
      </figure>`;
    })
    .join("\n");
  return `    <details>
      <summary>${escapeHtml(group.surface)}</summary>
${imagesHtml}
    </details>`;
}

/** renderBanner(banner) — the sticky summary banner in whichever of its 4 states. */
function renderBanner(banner) {
  const badge = banner.badge
    ? `<span class="badge badge-${banner.badge.tone}"><span class="badge-glyph" aria-hidden="true">${banner.badge.glyph}</span> ${escapeHtml(
        banner.badge.text
      )}</span>`
    : "";
  const empty =
    banner.state === "empty"
      ? `\n    <div class="empty">
      <p class="empty-heading">${escapeHtml(banner.emptyHeading)}</p>
      <p class="empty-body muted">${escapeHtml(banner.emptyBody)}</p>
    </div>`
      : "";
  return `  <header id="summary" class="banner banner-${banner.state}">
    <p class="banner-headline">${escapeHtml(banner.headline)} ${badge}</p>${empty}
  </header>`;
}

const DIGEST_STYLE = `    :root {
      --bg: #fafbfc; --elevated: #ffffff; --accent: #5d79f6; --danger: #d64b4b;
      --warning: #c8923b; --border: #e9eef2; --muted: #5d6a73; --text: #1a2229;
    }
    @media (prefers-color-scheme: dark) {
      :root {
        --bg: #0f1318; --elevated: #171d24; --accent: #4a90b8; --danger: #d64b4b;
        --warning: #c8923b; --border: #171d24; --muted: #a8b2bc; --text: #e6ebef;
      }
    }
    * { box-sizing: border-box; }
    body {
      margin: 0; background: var(--bg); color: var(--text);
      font-family: Geist, system-ui, sans-serif; font-size: 16px; line-height: 1.6;
    }
    code, .mono { font-family: "Geist Mono", ui-monospace, monospace; font-size: 13px; line-height: 1.4; }
    .muted { color: var(--muted); }
    h2 { font-size: 20px; font-weight: 600; line-height: 1.2; margin: 0 0 16px; }
    .banner {
      position: sticky; top: 0; z-index: 10; background: var(--elevated);
      border-bottom: 1px solid var(--border); padding: 16px 24px;
    }
    .banner-cap-reached { border-bottom: 2px solid var(--danger); }
    .banner-headline { margin: 0; font-size: 16px; }
    .badge {
      display: inline-flex; align-items: center; gap: 8px; padding: 2px 8px;
      border-radius: 6px; font-size: 13px; font-weight: 600; margin-left: 8px;
    }
    .badge-accent { border: 1px solid var(--accent); color: var(--accent); background: var(--elevated); }
    .badge-danger { border: 1px solid var(--danger); color: #fff; background: var(--danger); }
    .empty { margin-top: 8px; }
    .empty-heading { margin: 0; font-weight: 600; }
    .empty-body { margin: 4px 0 0; }
    section { padding: 16px 24px; margin-top: 24px; }
    #decisions-needed {
      border-left: 3px solid var(--warning);
      background: color-mix(in srgb, var(--warning) 6%, var(--elevated));
    }
    table { width: 100%; border-collapse: collapse; background: var(--elevated); }
    th, td { text-align: left; padding: 8px; border-bottom: 1px solid var(--border); vertical-align: top; font-size: 14px; line-height: 1.4; }
    th { color: var(--muted); font-weight: 600; }
    .sev { display: inline-flex; align-items: center; gap: 8px; font-weight: 600; }
    .sev-real { color: var(--danger); }
    .sev-minor { color: var(--warning); }
    .freq { font-family: "Geist Mono", ui-monospace, monospace; }
    .defect { margin: 0; }
    .fix { margin: 4px 0 0; }
    details { margin-top: 32px; background: var(--elevated); border: 1px solid var(--border); border-radius: 8px; padding: 16px; }
    summary { font-size: 20px; font-weight: 600; line-height: 1.2; cursor: pointer; }
    .shot { margin: 16px 0 0; }
    .shot-frame { position: relative; overflow: hidden; border: 1px solid var(--border); }
    .shot-frame img { display: block; width: 100%; height: auto; }
    .overlay { position: absolute; border: 2px solid var(--accent); pointer-events: none; }
    .overlay-label {
      position: absolute; top: -1px; left: -1px; font-family: "Geist Mono", ui-monospace, monospace;
      font-size: 13px; padding: 0 4px; border: 1px solid var(--accent); color: var(--accent);
      background: var(--elevated); white-space: nowrap;
    }
    .absent-note { margin: 8px 0 0; font-size: 14px; }`;

/**
 * renderDigestHtml({banner, worklist, decisionsNeeded, galleryGroups}) — the full offline HTML
 * document per the UI-SPEC. Pure: takes already-built data, produces a string, touches no fs.
 * Every ledger-row string field is `escapeHtml`'d before interpolation.
 */
function renderDigestHtml({ banner, worklist, decisionsNeeded, galleryGroups }) {
  const gallery = (galleryGroups || []).map(renderGalleryGroup).join("\n");
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${escapeHtml(banner.headline)}</title>
  <style>
${DIGEST_STYLE}
  </style>
</head>
<body>
${renderBanner(banner)}
${renderTableSection("worklist", "Worklist", worklist, "No auto-fixable findings this round.")}
${renderTableSection(
    "decisions-needed",
    "Decisions needed",
    decisionsNeeded,
    "No IA/product-decision items this round."
  )}
  <section id="gallery">
    <h2>Gallery</h2>
${gallery}
  </section>
</body>
</html>
`;
}

export {
  LEDGER_PATH,
  ROUNDS_PATH,
  CAPTURE_DIR,
  ROUND_OUTPUT_ROOT,
  CAPTURE_VIEWPORT_WIDTHS,
  DISPLAY_WIDTHS,
  readNdjsonRows,
  computeConvergenceDisplay,
  buildSummaryBanner,
  partitionFindings,
  buildDecisionsJsonRows,
  validateDigestRows,
  escapeHtml,
  computeOverlayScale,
  scaleBox,
  resolveRoundDir,
  assembleRoundArtifacts,
  buildGalleryGroups,
  writeDecisionsJson,
  renderDigestHtml,
};
