# Phase 205: Persona + design-lens evaluator harness - Pattern Map

**Mapped:** 2026-07-03
**Files analyzed:** 7 (5 new, 2 modified)
**Analogs found:** 7 / 7 (all grounded in verified file paths + symbols)

All new files live under `accrue_admin/e2e/ratchet/` (dev/test-only, never in adopter runtime).
Every excerpt below is copied from a file that exists today; line numbers are current as of this map.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `accrue_admin/e2e/ratchet/ratchet-propose.mjs` | CLI harness (proposer) | request-response (LLM vision) + file-I/O | `accrue_admin/e2e/score-visuals.mjs` | exact (fork base) |
| `accrue_admin/e2e/ratchet/region-tags.js` | SSOT constant + pure utility module | transform (deterministic identity) | `accrue_admin/e2e/baseline-manifest.js` | role-match (new vocab, same grammar) |
| `accrue_admin/e2e/ratchet/ratchet-propose.mjs` `--self-test` block | test (pure fixture reducer) | batch/transform | `accrue_admin/e2e/phase200-scorecard.mjs` `runSelfTest()` | exact (twin) |
| `accrue_admin/e2e/ratchet/DESIGN-LENS-RUBRIC.md` | doc (scoring sub-rubric) | — | `.../187-audit-baseline/187-RUBRIC.md` | exact |
| `accrue_admin/e2e/ratchet/candidates.ndjson` (row schema) | data contract | event-driven (append rows) | `.../187-audit-baseline/defects.ndjson` + `schemas/baseline-cell.schema.json` | role-match |
| `accrue_admin/e2e/ratchet/exemplars/PROVENANCE.json` | config/provenance manifest | file-I/O | `.../187-audit-baseline/schemas/baseline-cell.schema.json` (shape precedent only) | partial (no direct provenance analog) |
| `accrue_admin/package.json` | config (npm scripts) | — | existing `score-visuals` / `phase200:*` scripts | exact |
| `accrue_admin/e2e/admin-visuals.spec.js` (bbox emit, D-09) | test/spec (capture) | file-I/O (geometry) | `captureThemes()` in same file | exact (extend in place) |

---

## Pattern Assignments

### `accrue_admin/e2e/ratchet/ratchet-propose.mjs` (CLI harness, request-response + file-I/O)

**Analog:** `accrue_admin/e2e/score-visuals.mjs` (fork base — KEEP the load-bearing scaffolding, DROP the census invariant/score).
**Read first:** `accrue_admin/e2e/score-visuals.mjs` (whole file, 340 lines), `accrue_admin/e2e/phase200-scorecard.mjs:841-969` (self-test + arg parse), `accrue_admin/e2e/ratchet/region-tags.js` (new SSOT, this phase).

**Guard-ordering pattern — self-test → no-key → SDK import** (extend `score-visuals.mjs:30-44`). The no-key guard is verbatim; a `--self-test` branch is inserted BEFORE it (D-05/EVAL-03, Research Pitfall 4):
```javascript
// score-visuals.mjs:35-38 — KEEP VERBATIM as guard #2, but insert --self-test as guard #1 above it
if (!process.env.ANTHROPIC_API_KEY) {
  console.log("[score-visuals] ANTHROPIC_API_KEY not set — skipping (human/CI gate only)");
  process.exit(0);
}
const { default: manifest } = await import("./baseline-manifest.js"); // score-visuals.mjs:40
const { default: Anthropic } = await import("@anthropic-ai/sdk");      // score-visuals.mjs:43 — dynamic, post-guard
```

**Config pattern** (`score-visuals.mjs:49-52`) — reuse `SCORE_MODEL` default + `MAX_B64_BYTES`, keep `RESULTS_DIR`:
```javascript
const model = process.env.SCORE_MODEL || "claude-sonnet-4-5"; // :49 — Sonnet 4.5 accepts temperature (Pitfall 1)
const RESULTS_DIR = path.join(__dirname, "../test-results/admin-visuals"); // :50
const MAX_B64_BYTES = 5 * 1024 * 1024; // :51 — 5 MB per-image guard (EVAL-03)
```

**PNG discovery loop — KEEP verbatim** (`score-visuals.mjs:114-148`). Surface is derived from filename and injected, never model-chosen (D-04):
```javascript
const projects = ["chromium-desktop", "chromium-mobile"]; // :121
for (const projectName of projects) {
  const projectDir = path.join(RESULTS_DIR, projectName);
  if (!fs.existsSync(projectDir)) continue;
  const files = fs.readdirSync(projectDir).filter((f) => f.endsWith(".png"));
  for (const file of files) {
    const isDark = file.endsWith("-dark.png"); // :132
    const theme = isDark ? "dark" : "light";
    const screen = isDark ? file.slice(0, -"-dark.png".length) : file.slice(0, -".png".length);
    // screen → surface via SURFACES.find(e => e.surface === screen) — harness-injected identity
  }
}
```

**Authoritative-metadata enrichment pattern — ADAPT** (`score-visuals.mjs:87-103`). Keep the `SURFACES.find` + `cellId()` shape; drop `default-populated`-only hardcoding to accept the `state` field, and drop the `dimensionId`-per-row census assumption:
```javascript
function metadataForImage(screen, viewport, theme, dimensionId) {           // :87
  const surface = SURFACES.find((entry) => entry.surface === screen);       // :88 — injected, authoritative
  const project = PROJECTS.find((entry) => entry.name === viewport || entry.mode === viewport);
  const dimension = DIMENSIONS.find((entry) => entry.id === dimensionId);
  if (!surface || !project || !dimension || !surface.themes.includes(theme)) return null; // :91
  return {
    cell_id: cellId(surface.surface, project.name, theme, "default-populated", dimension.id), // :94 — cell_refs FK
    surface: surface.surface, surface_type: surface.surface_type,
    persona_job: surface.persona_job, dimension: dimension.id, dimension_name: dimension.name, // :96-101
  };
}
```

**Truncate-on-rerun** (`score-visuals.mjs:168-171`) — KEEP for `candidates.ndjson`:
```javascript
findingsPath = path.join(RESULTS_DIR, "findings.ndjson"); // :168 → rename output to candidates.ndjson
fs.writeFileSync(findingsPath, ""); // :170 — truncate so reruns don't concatenate stale rows
```

**Model-call pattern — REPLACE with forced tool-use** (fork base is at `score-visuals.mjs:192-214`). CRITICAL (Research Pitfall 6): the fork base parses `response.content[0]?.text` (`score-visuals.mjs:216`) which breaks under forced tool-use. Read the `tool_use` block `.input` instead. Keep the image content-block shape verbatim:
```javascript
// KEEP the image block shape from score-visuals.mjs:199-206:
content: [
  { type: "image", source: { type: "base64", media_type: "image/png", data: b64 } },
  { type: "text", text: lensPrompt },
]
// REPLACE the response parse (was score-visuals.mjs:216):
const raw = response.content.find(b => b.type === "tool_use")?.input?.findings ?? []; // NOT content[0].text
```

**DROP from the fork base:** `hasExpectedDimensions()` (`score-visuals.mjs:105-109`, the "exactly 12 rows" invariant) and the per-dimension 0–3 `score` validation (`:261-267`). The proposer emits variable 0..N defect rows; empty `[]` is valid (D-11).

**Error-handling pattern — KEEP** (`score-visuals.mjs:313-316`): wrap the loop in try/catch, `console.error` + `process.exit(1)` on API error; per-image parse failures `continue` without aborting the run.

---

### `accrue_admin/e2e/ratchet/region-tags.js` (SSOT constant + pure utility module, transform)

**Analog:** `accrue_admin/e2e/baseline-manifest.js` (reuse the `__`-join / `dNN` grammar and `OVERLAY_TAGS`; `REGION_TAGS` is NEW this milestone).
**Read first:** `accrue_admin/e2e/baseline-manifest.js:29-44` (OVERLAY_TAGS), `:192-197` (slug), `:263-276` (cellId grammar), `:312-322` (module.exports); `accrue_admin/e2e/phase200-scorecard.mjs:238` (sha256).

CRITICAL (Research Pitfall 3): `slug()` is defined at `baseline-manifest.js:192` but is **NOT** in `module.exports` (`:312-322`). Reimplement it byte-identically here (do not touch the frozen manifest):
```javascript
// baseline-manifest.js:192-197 — copy VERBATIM into region-tags.js (module-private there, not exported)
function slug(value) {
  return String(value)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}
```

**Closed overlay vocab — import/reuse** (`baseline-manifest.js:29-44`, the 14 `OVERLAY_TAGS`) as the identity vocab for `overlay_tags` validation. `REGION_TAGS` (14 values, D-06) is authored fresh here — no analog exists (it did not exist pre-milestone).

**`__`-join / `dNN` grammar — mirror from `cellId()`** (`baseline-manifest.js:263-276`) so `claim_key` looks native and `cell_refs` match byte-for-byte:
```javascript
// baseline-manifest.js:268-275 — the join+padStart grammar the claim_key must mirror
return [
  "p187", slug(surface), slug(projectInfo.mode), slug(theme), slug(state),
  `d${String(dimensionInfo.id).padStart(2, "0")}`, // dNN convention — reuse for claim_key
].join("__");
// claim_key (D-01): `${slug(surface)}__d${nn}__${region||'noregion'}__ov-${sorted.join('+')||'none'}`
```

**sha256 → finding_id** (`phase200-scorecard.mjs:238`) — reuse `node:crypto` `createHash`, slice(0,16):
```javascript
// phase200-scorecard.mjs:238 pattern (operates on a string here, not a file)
function findingId(claim_key) {
  return "f-" + createHash("sha256").update(claim_key, "utf8").digest("hex").slice(0, 16);
}
```

**Export shape** — mirror `baseline-manifest.js:312-322` `module.exports` object literal, OR use ESM `export` (the harness `import * as regionTags`). Export: `REGION_TAGS`, `OVERLAY_TAGS`, allowed-subset map, synonym table, and pure fns `slug`, `claimKey`, `findingId`, `normalizeRegion`, `normalizeOverlays`, `assertDimension`, `isAdmissibleToken`, `runSelfTest`. Keep SDK-free (importable by the self-test).

---

### `--self-test` block (pure fixture reducer, batch/transform)

**Analog:** `accrue_admin/e2e/phase200-scorecard.mjs` `assertSelfTest()` (`:841-844`) + `runSelfTest()` (`:846-946`) + `parseArgs`/`main` (`:948-969`).
**Read first:** `accrue_admin/e2e/phase200-scorecard.mjs:841-969`.

**assertSelfTest helper — copy VERBATIM** (`phase200-scorecard.mjs:841-844`):
```javascript
function assertSelfTest(name, condition, details = "") {
  if (!condition) throw new Error(`Self-test failed: ${name}${details ? ` (${details})` : ""}`);
  console.log(`self-test pass: ${name}`);
}
```

**Structure pattern** (`phase200-scorecard.mjs:846-942`) — twin the "hand-written fixtures → assert over reducer output → final pass line" shape. The 200 version builds tmp dirs; the ratchet version needs NO tmp dir (pure claim-key fns), so drop the `mkdtempSync`/`rmSync` wrapper (`:847,943-944`) and assert directly over `claimKey()`/`findingId()`. Cover the 7 D-05 classes: idempotence, prose-independence, overlay order/dup invariance, empty-normalization, intended-distinctness negatives, closed-enum-throws, golden-hash snapshot.

**Golden-hash discipline** — mirror the 200 golden-count guard idea (`phase200-scorecard.mjs:864` asserts a locked structural fact). Pin one `findingId(...)` output; a separator/field-order change flips it.

**Arg parse** (`phase200-scorecard.mjs:948-969`) — reuse the `--self-test` branch pattern:
```javascript
if (options.selfTest) { runSelfTest(); return { ok: true }; } // :966-968
```

---

### `accrue_admin/e2e/ratchet/DESIGN-LENS-RUBRIC.md` (doc)

**Analog:** `.planning/milestones/v1.53-phases/187-audit-baseline/187-RUBRIC.md`.
**Read first:** `187-RUBRIC.md:1-40` (structured-data-wins + brandbook precedence + dimension table).

**Precedence note — reuse verbatim tone** (`187-RUBRIC.md:8-13`): "structured data wins" + "`brandbook/` supersedes `prompts/accrue-brand-book.md`" (D-22 cites this exact note):
```markdown
`brandbook/` supersedes `prompts/accrue-brand-book.md` wherever they conflict. The older prompt
remains historical context only.
```
**Dimension anchoring** (`187-RUBRIC.md:20-33` canonical list + `:35-40` the passing-signal/anchors table) — sharpen only dims 2/3/5/8 with 1/6 support (D-22). Do NOT add a 13th dimension. d3 must penalize BOTH cramped AND wasteful. Comparative (no absolute award score).

---

### `accrue_admin/e2e/ratchet/candidates.ndjson` (data contract, event-driven append)

**Analogs:** `.planning/milestones/v1.53-phases/187-audit-baseline/defects.ndjson` (NDJSON row precedent — one JSON object per line: `severity`, `surface`, `surface_type`, `persona_job`, `reproduction`, `expected`, …) + `schemas/baseline-cell.schema.json` (closed-enum field discipline).
**Read first:** `.planning/milestones/v1.53-phases/187-audit-baseline/defects.ndjson` (first 3 lines), `schemas/baseline-cell.schema.json` (whole file).

**Row shape (D-17)** — four field groups. Identity fields are closed-enum/harness-derived (mirror the schema's `enum` discipline at `baseline-cell.schema.json:32-84`); free text (`defect`, `suggested_fix`, `exemplar_ref`, `direction`) is excluded from identity. Reuse `surface_type` enum from `baseline-cell.schema.json:32-34` and `dimension`/`dimension_name` enums from `:63-84`. NDJSON append + truncate-on-rerun from `score-visuals.mjs:170,300-304`.

---

### `accrue_admin/e2e/ratchet/exemplars/PROVENANCE.json` (provenance manifest)

**Analog (shape precedent only):** `.planning/milestones/v1.53-phases/187-audit-baseline/schemas/baseline-cell.schema.json` (JSON object-per-entry with closed enums). No direct provenance analog exists in the repo.
**Read first:** `schemas/baseline-cell.schema.json` (for the closed-enum + `additionalProperties:false` discipline).

Per-PNG entry (D-23): `source_commit_sha`, capture route/spec, `viewport`+`theme` (reuse the `mode`/`theme` enums from `baseline-cell.schema.json:36-47`), exact capture command, max-dimensions, curator note (`role: good|bad`, density pole, why). Version-pinned; refresh only via a deliberate "re-baseline exemplars" commit.

---

### `accrue_admin/package.json` (config — npm scripts)

**Analog:** existing `score-visuals` (`package.json:17`) and `phase200:*` (`:24-27`) scripts.
**Read first:** `accrue_admin/package.json` (whole file, 34 lines).

Add alongside `"score-visuals": "node e2e/score-visuals.mjs"` (`:17`):
```json
"ratchet:propose": "node e2e/ratchet/ratchet-propose.mjs",
"ratchet:self-test": "node e2e/ratchet/ratchet-propose.mjs --self-test"
```
No new `devDependencies` — `@anthropic-ai/sdk ^0.100.1` and `@playwright/test ^1.57.0` (`:30-32`) are already present.

---

### `accrue_admin/e2e/admin-visuals.spec.js` (test/spec — optional bbox emit, D-09)

**Analog:** `captureThemes()` in the same file (`admin-visuals.spec.js:21-28`).
**Read first:** `accrue_admin/e2e/admin-visuals.spec.js:1-80`.

Extend the capture flow with a sibling bbox emitter (per surface/viewport/theme). Reuse the `test-results/admin-visuals/${project}` dir convention (`:23`) and the `-dark` filename convention (`:26-27`). Geometry writes to a `.bbox.json` sibling and NEVER enters the claim-key (D-09). Playwright `locator().boundingBox()` is native — `null` for an absent selector is the intended presence-cross-check fallback.
```javascript
// admin-visuals.spec.js:21-28 — the capture shape to mirror for bbox emit
async function captureThemes(page, name, project) {
  const dir = `test-results/admin-visuals/${project}`; // :23 — reuse dir convention
  await page.evaluate(() => document.documentElement.setAttribute("data-theme", "light"));
  await page.screenshot({ path: `${dir}/${name}.png`, fullPage: true }); // :25
  // add: for each ax-* region → boxes[sel] = (await loc.count()) ? await loc.boundingBox() : null;
}
```

---

## Shared Patterns

### Deterministic identity from closed-enum coordinates (the gate spine)
**Source:** `accrue_admin/e2e/baseline-manifest.js:263-276` (`cellId()` grammar) + `phase200-scorecard.mjs:238` (`sha256`).
**Apply to:** `region-tags.js` (authoritative), consumed by `ratchet-propose.mjs`.
Identity = `slug(surface) + dNN + region_tag + sorted(overlay_tags)` ONLY. Model output is advisory; the harness re-derives every identity field and ignores model-supplied `claim_key`/`finding_id` (D-04/D-16). Sort = default codepoint `.sort()`, NOT `localeCompare` (Research Anti-Patterns).

### No-key `exit 0` + oversized-image guard (safe CI paths)
**Source:** `accrue_admin/e2e/score-visuals.mjs:35-38` (no-key) + `:51,182-188` (`MAX_B64_BYTES`).
**Apply to:** `ratchet-propose.mjs`. Both guards KEEP verbatim; `--self-test` inserted above the no-key guard so CI never needs a key (EVAL-03).

### Pure fixture self-test, never a live API call (DEDUP-02 proof)
**Source:** `accrue_admin/e2e/phase200-scorecard.mjs:841-946`.
**Apply to:** `region-tags.js` / `ratchet-propose.mjs --self-test`. No test framework is installed — raw-Node `assertSelfTest` is the repo idiom.

### Authoritative-metadata override (surface injected, never model-chosen)
**Source:** `accrue_admin/e2e/score-visuals.mjs:87-103` (`metadataForImage`) + `baseline-manifest.js:263-276` (`cellId` for `cell_refs`).
**Apply to:** every emitted `candidates.ndjson` row (D-04/EVAL-05).

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `exemplars/good/*.png`, `exemplars/bad/*.png` | binary assets | — | ZERO admin PNGs have ever been committed (D-18, verified `git ls-files '*.png' \| grep -iE 'admin\|visual\|exemplar\|ratchet'` → empty). Must be captured-and-curated fresh; no file-pull analog. |
| `exemplars/PROVENANCE.json` | provenance manifest | file-I/O | Only a shape precedent (`baseline-cell.schema.json`); no prior provenance manifest exists. Planner authors fresh per D-23. |
| `REGION_TAGS` enum + synonym/subset maps in `region-tags.js` | closed-enum vocab | — | `region_tag` is NEW this milestone; does not exist in `baseline-manifest.js` (only `OVERLAY_TAGS`/`STATE_TAXONOMY` do). Author fresh from D-06/D-08. |

---

## Metadata

**Analog search scope:** `accrue_admin/e2e/`, `accrue_admin/package.json`, `.planning/milestones/v1.53-phases/187-audit-baseline/`, `.planning/research/v1.51-admin-ui-depth-design.md`.
**Files scanned:** 8 (score-visuals.mjs, baseline-manifest.js, phase200-scorecard.mjs, admin-visuals.spec.js, package.json, 187-RUBRIC.md, baseline-cell.schema.json, defects.ndjson).
**Pattern extraction date:** 2026-07-03
