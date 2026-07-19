# Phase 207: Orchestration + digest + one-command round/fix loop - Pattern Map

**Mapped:** 2026-07-07
**Files analyzed:** 19
**Analogs found:** 19 / 19

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `accrue_admin/lib/mix/tasks/accrue_admin.ui.round.ex` | task/orchestrator | batch + file-I/O + process orchestration | `accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex` | exact role |
| `accrue_admin/lib/mix/tasks/accrue_admin.ui.fix.ex` | task/orchestrator | batch + file-I/O + mutation orchestration | `accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex` + `accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex` | role-match |
| `accrue_admin/test/mix/tasks/accrue_admin_ui_round_test.exs` | test | batch + fake subprocess events | `accrue_admin/test/mix/tasks/accrue_admin_assets_build_test.exs` | exact role |
| `accrue_admin/test/mix/tasks/accrue_admin_ui_fix_test.exs` | test | batch + fake subprocess events | `accrue_admin/test/mix/tasks/accrue_admin_assets_build_test.exs` | exact role |
| `accrue_admin/e2e/ratchet/ratchet-digest.mjs` | utility/static artifact renderer | transform + file-I/O | `accrue_admin/e2e/phase192-gallery.mjs` | structural |
| `accrue_admin/e2e/ratchet/rounds.ndjson` | model/event log | append-only event-driven | `accrue_admin/e2e/ratchet/reopen-markers.ndjson` + `accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs` | data-flow |
| `accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs` | utility/reducer | batch + transform + file-I/O | `accrue_admin/e2e/phase200-scorecard.mjs` + same file | exact data-flow |
| `accrue_admin/e2e/ratchet/ratchet-fix.mjs` | utility/mutation service | batch + file-I/O + lifecycle events | `accrue_admin/e2e/ratchet/ratchet-ledger.js` | role-match |
| `accrue_admin/e2e/ratchet/ratchet-guard-mint.mjs` | utility/codegen-data writer | file-I/O + transform | `accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs` + guard-home specs | partial |
| `accrue_admin/e2e/ratchet/ratchet-propose.mjs` | external-service client | batch + file-I/O + request-response | same file request-builder/discovery seams | exact modification |
| `accrue_admin/e2e/ratchet/ratchet-verify.mjs` | external-service client/verifier | batch + file-I/O + request-response | same file request-builder/verify loop | exact modification |
| `accrue_admin/e2e/admin-visuals.spec.js` | browser test/capture spec | browser-driven + file-I/O | same file capture loop | exact modification |
| `accrue_admin/e2e/baseline-manifest.js` | config/manifest | transform | same file `SURFACES`/exports | exact modification |
| `accrue_admin/e2e/foundation-tokens.spec.js` | test/guard home | browser-driven assertion table | same file token/contrast helpers | exact modification |
| `accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js` | test/guard home | browser-driven assertion table | same file focus/overlay helpers | exact modification |
| `accrue_admin/e2e/reduced-motion.spec.js` | test/guard home | browser-driven assertion table | same file reduced-motion helpers | exact modification |
| `accrue_admin/e2e/admin-page-flow-phase200.spec.js` | test/guard home | browser-driven assertion table | same file page-flow helpers | exact modification |
| `accrue_admin/package.json` | config | command wiring | existing `ratchet:*` scripts | exact modification |
| `scripts/ci/verify_ratchet_ledger.mjs` | utility/verifier | batch + file-I/O | same file independent verifier discipline | conditional |

## Pattern Assignments

### `accrue_admin/lib/mix/tasks/accrue_admin.ui.round.ex` (task/orchestrator, batch + file-I/O)

**Analog:** `accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex`

**Imports/module pattern** (lines 17-25):
```elixir
use Mix.Task

@runner_env_key :accrue_admin_assets_build_runner

defmodule Runner do
  @moduledoc false
  @callback run(String.t(), [String.t()], keyword()) :: {:ok, integer()} | {:error, term()}
end
```

**ShellRunner + swappable runner pattern** (lines 28-59):
```elixir
defmodule ShellRunner do
  @moduledoc false
  @behaviour Runner

  @impl true
  def run(command, args, opts) do
    {_, status} =
      System.cmd(command, args,
        cd: Keyword.fetch!(opts, :cd),
        env: [{"BROWSERSLIST_IGNORE_OLD_DATA", "1"}],
        stderr_to_stdout: true,
        into: IO.stream(:stdio, :line)
      )

    {:ok, status}
  rescue
    error -> {:error, error}
  end
end

runner = Application.get_env(:accrue_admin, @runner_env_key, ShellRunner)
run_step!(runner, "tailwind", "npx", tailwind_args(root), cd: root)
```

**Error handling pattern** (lines 87-97):
```elixir
defp run_step!(runner, label, command, args, opts) do
  case runner.run(command, args, opts) do
    {:ok, 0} -> :ok
    {:ok, status} -> Mix.raise("#{label} build failed with exit status #{status}")
    {:error, reason} -> Mix.raise("#{label} build failed: #{Exception.message(reason)}")
  end
end
```

**Boot/capture pattern source:** `accrue_admin/playwright.config.js` lines 19-24. `ui.round` should rely on Playwright `webServer` instead of hand-booting Phoenix:
```js
webServer: {
  command: `MIX_ENV=test ACCRUE_ADMIN_E2E_PORT=${port} mix accrue_admin.e2e.server`,
  url: `${baseURL}/__e2e__/health`,
  reuseExistingServer: !process.env.CI,
  timeout: 120_000
}
```

### `accrue_admin/lib/mix/tasks/accrue_admin.ui.fix.ex` (task/orchestrator, batch + mutation)

**Analogs:** `accrue_admin.assets.build.ex`, `accrue_admin.export_copy_strings.ex`, `ratchet-fix.mjs`

**Noninteractive option/file pattern** (`export_copy_strings.ex` lines 107-132):
```elixir
def run(argv) do
  {opts, _, _} = OptionParser.parse(argv, strict: [out: :string], aliases: [o: :out])

  out_path =
    case opts[:out] do
      nil -> Mix.raise("mix accrue_admin.export_copy_strings requires --out PATH")
      path -> path
    end

  File.mkdir_p!(Path.dirname(out_path))
  File.write!(out_path, Jason.encode!(map) <> "\n")
end
```

**Apply/finalize command boundary** (`ratchet-fix.mjs` lines 172-224):
```js
function applyDecisions({ round, dryRun, ledgerPath, decisionsPath, roundsPath, fixContextPath }) {
  const rows = readJson(decisionsPath);
  if (!Array.isArray(rows)) {
    throw new Error(`applyDecisions: decisions file is not a JSON array: ${decisionsPath}`);
  }

  const { approves, rejects, invalidRows } = validateDecisionsBatch(rows);
  if (invalidRows.length > 0) {
    throw new Error(`applyDecisions: refusing the ENTIRE batch ...`);
  }

  console.log(buildBanner(approves, rejects));
  if (dryRun) return { round, applied: 0, suppressed: 0, dryRun: true };

  for (const row of approves) appendResolved(row.finding_id, ledgerPath, { resolved_round: round });
  for (const row of rejects) appendSuppressed(row.finding_id, ledgerPath, {
    suppressed_reason: row.suppressed_reason,
    suppressed_note: row.suppressed_note != null ? row.suppressed_note : null,
  });
}
```

### Mix Task Tests (test, fake subprocess events)

**Analog:** `accrue_admin/test/mix/tasks/accrue_admin_assets_build_test.exs`

**Fake runner pattern** (lines 8-23):
```elixir
defmodule FakeRunner do
  @behaviour Build.Runner

  @impl true
  def run("npx", ["--yes", tool | args], opts) do
    send(self(), {:runner_call, tool, args, opts[:cd]})
    File.mkdir_p!(Path.dirname(output_path))
    File.write!(output_path, "generated by #{tool}")
    {:ok, 0}
  end
end
```

**Env swap + cleanup pattern** (lines 38-61):
```elixir
setup do
  Mix.Task.reenable("accrue_admin.assets.build")

  prior = Application.get_env(:accrue_admin, :accrue_admin_assets_build_runner)
  Application.put_env(:accrue_admin, :accrue_admin_assets_build_runner, FakeRunner)

  on_exit(fn ->
    Mix.Task.reenable("accrue_admin.assets.build")
    if prior, do: Application.put_env(:accrue_admin, :accrue_admin_assets_build_runner, prior),
      else: Application.delete_env(:accrue_admin, :accrue_admin_assets_build_runner)
  end)
end
```

**Assertion pattern** (lines 66-85):
```elixir
output = capture_io(fn -> Build.run([]) end)
assert_received {:runner_call, "tailwindcss@3.4.17", tailwind_args, cwd}
assert_received {:runner_call, "esbuild@0.25.3", esbuild_args, ^cwd}
assert output =~ "Rebuilt AccrueAdmin assets"
```

### `accrue_admin/e2e/ratchet/ratchet-digest.mjs` (utility/static artifact renderer, transform + file-I/O)

**Analog:** `accrue_admin/e2e/phase192-gallery.mjs`

**Imports/path constants pattern** (lines 1-21):
```js
import fs from "fs";
import os from "os";
import path from "path";
import { fileURLToPath, pathToFileURL } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const adminRoot = path.resolve(__dirname, "..");
const repoRoot = path.resolve(adminRoot, "..");
const DEFAULT_OUTPUT = path.join(phaseDir, "192-SIGN-OFF.md");
```

**Pure row builder + validator pattern** (lines 401-454):
```js
function validateGalleryRows(rows) {
  const failures = [];
  rows.forEach((row, index) => {
    for (const field of REQUIRED_GALLERY_FIELDS) {
      if (!String(row[field] || "").trim()) failures.push(`gallery row ${index + 1} missing ${field}`);
    }
  });
  if (failures.length > 0) throw new Error(failures.join("; "));
}

export function generatePhase192Gallery(options = {}) {
  const rows = options.rows || generateEvidenceRows(refs, artifactPackage.status);
  validateGalleryRows(rows);
  return { rows, traceRefs, status: artifactPackage.status };
}
```

**Self-test + CLI guard pattern** (lines 625-730):
```js
function assertSelfTest(name, condition, details = "") {
  if (!condition) throw new Error(`Self-test failed: ${name}${details ? ` (${details})` : ""}`);
  console.log(`self-test pass: ${name}`);
}

async function runSelfTest() {
  const tempRoot = fs.mkdtempSync(path.join(os.tmpdir(), "phase192-gallery-"));
  try {
    const inputs = completeFixture(tempRoot);
    const complete = await generatePhase192Signoff({ inputs, outputPath: path.join(tempRoot, "192-SIGN-OFF.md") });
    assertSelfTest("complete fixture renders ACCEPT", complete.status === "ACCEPT");
  } finally {
    fs.rmSync(tempRoot, { recursive: true, force: true });
  }
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch((error) => {
    console.error(`Phase 192 sign-off generator failed: ${error.message}`);
    process.exitCode = 1;
  });
}
```

**Gap:** no exact existing HTML digest renderer. Copy the structure above, but add digest-specific HTML escaping for all ledger/free-text fields per `207-RESEARCH.md` Security Domain.

### `accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs` and `rounds.ndjson` (utility/reducer + event log)

**Analogs:** `phase200-scorecard.mjs`, `ratchet-ledger.js`, same file reducer patterns

**Default committed paths pattern** (lines 49-55):
```js
const DEFAULT_PATHS = {
  ledgerPath: path.join(__dirname, "findings.ledger.ndjson"),
  baselinePath: path.join(__dirname, "ledger.baseline.json"),
  reopenMarkersPath: path.join(__dirname, "reopen-markers.ndjson"),
  regressionsPath: path.join(__dirname, "finding-regressions.ndjson"),
  roundsPath: path.join(__dirname, "rounds.ndjson"),
};
```

**Absent-safe NDJSON + 0-byte-on-empty writes** (lines 106-130):
```js
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

function writeNdjson(absPath, rows) {
  fs.mkdirSync(path.dirname(absPath), { recursive: true });
  const text = rows.map((row) => JSON.stringify(row)).join("\n") + (rows.length ? "\n" : "");
  fs.writeFileSync(absPath, text);
}
```

**Dry-round pure helpers** (lines 171-229):
```js
function computeNextRound(roundsRows) {
  return Math.max(0, ...roundsRows.map((row) => row.round || 0)) + 1;
}

function computeClauseNewOpens(foldedFindings, currentRound) {
  return !foldedFindings.some((f) => f.event === "confirm" && f.round === currentRound);
}

function computeClauseZeroOpen(foldedFindings) {
  return !foldedFindings.some((f) => f.status === "open");
}

function computeDryRound(clauses) {
  return clauses.every(Boolean);
}
```

**Round seal append pattern** (lines 562-622):
```js
function sealRound(paths = DEFAULT_PATHS) {
  const rawRound = process.env.RATCHET_ROUND;
  const currentRound = Number(rawRound);
  if (rawRound === undefined || String(rawRound).trim() === "" || !Number.isFinite(currentRound)) {
    console.error("[phase-ratchet-ledger] --seal-round: RATCHET_ROUND is missing or non-numeric; appending nothing to rounds.ndjson.");
    process.exitCode = 1;
    return;
  }

  const rawScope = process.env.RATCHET_SURFACES || "all";
  const { baseline } = runReducer(paths);
  const foldedFindings = Array.from(fold(readNdjsonRows(paths.ledgerPath)).values());
  const dry = computeDryRound([clause1, clause2, clause3, clause4]);

  const newRow = {
    schema_version: "ratchet-round-seal/1",
    round: currentRound,
    dry,
    epoch: baseline.epoch,
    scope: rawScope,
    bundle_sha256: bundleSha256(),
    seq: existingRoundsRows.length + 1,
  };
  writeNdjson(paths.roundsPath, [...existingRoundsRows, newRow]);
}
```

### `accrue_admin/e2e/ratchet/ratchet-fix.mjs` (utility/mutation service)

**Analog:** `accrue_admin/e2e/ratchet/ratchet-ledger.js`

**Suppression validation source** (`ratchet-ledger.js` lines 186-193, 424-442):
```js
function isValidSuppressedReason(reason) {
  if (typeof reason !== "string") return false;
  if (reason === "duplicate-of") return false;
  if (SUPPRESSED_REASONS.includes(reason)) return true;
  if (!reason.startsWith("duplicate-of:")) return false;
  const suffix = reason.slice("duplicate-of:".length);
  return FINDING_ID_RE.test(suffix);
}

function appendSuppressed(finding_id, ledgerPath, extraFields = {}) {
  const reason = extraFields.suppressed_reason;
  if (!isValidSuppressedReason(reason)) {
    throw new Error(`appendSuppressed: suppressed_reason not admissible: ${JSON.stringify(reason)}`);
  }
  return appendLifecycleEvent(finding_id, ledgerPath, "suppress", extraFields);
}
```

**Lifecycle append source** (`ratchet-ledger.js` lines 357-405):
```js
function appendLifecycleEvent(finding_id, ledgerPath, event, extraFields = {}) {
  const rows = readLedgerRows(ledgerPath);
  const prior = latestRowForFindingId(rows, finding_id);
  if (!prior) throw new Error(`appendLifecycleEvent: no existing row found for finding_id=${JSON.stringify(finding_id)}`);
  assertIdentity(prior);
  if (!LEGAL_TRANSITIONS[prior.status] || !LEGAL_TRANSITIONS[prior.status].includes(event)) {
    throw new Error(`appendLifecycleEvent: illegal transition ${JSON.stringify(prior.status)} -> ${JSON.stringify(event)}`);
  }

  const row = {
    schema_version: "ratchet-finding-event/1",
    seq: nextSeq(rows),
    event,
    status: EVENT_STATUS[event],
    ...pick(prior, IDENTITY_FIELDS),
    ...pick(prior, CARRY_FIELDS),
    ...extraFields,
  };
  appendRow(ledgerPath, row);
  return row;
}
```

**Finalize/mint source** (`ratchet-fix.mjs` lines 239-267):
```js
function finalizeFixes({ round, ledgerPath, repoRoot, probeResults }) {
  const folded = fold(readNdjsonRows(ledgerPath));
  const result = { promoted: 0, minted: 0, ledgerCount: 0, leftResolved: 0 };

  for (const finding of folded.values()) {
    if (finding.status !== "resolved" || finding.resolved_round !== round) continue;
    const probe = probeResults ? probeResults[finding.finding_id] : undefined;
    if (!probe || probe.present !== false) {
      result.leftResolved += 1;
      continue;
    }

    const { guard_ref, targetSpecPath, row } = mintGuardRow(finding, probe.probed || {});
    if (targetSpecPath && row) appendMintedRow(targetSpecPath, row, repoRoot);
    appendVerifiedClosed(finding.finding_id, ledgerPath, { guard_ref });
    result.promoted += 1;
  }
  return result;
}
```

### `accrue_admin/e2e/ratchet/ratchet-guard-mint.mjs` (utility/codegen-data writer)

**Analogs:** `phase-ratchet-ledger.mjs` guard check, guard-home specs marker regions

**Kind-routing table** (lines 48-111):
```js
function kindForFinding({ dimension, defect_bucket, effort_class } = {}) {
  if (effort_class === "ia-product-decision") return "ledger-count";
  switch (dimension) {
    case 1: return "design-token";
    case 3: return defect_bucket === "inconsistent-rhythm" ? "spacing-scale" : "ledger-count";
    case 6: return "contrast";
    case 7: return "focus-ring";
    case 9: return "motion";
    case 12: return "microcopy";
    default: return "ledger-count";
  }
}

function homeSpecForKind(kind) {
  switch (kind) {
    case "design-token":
    case "contrast":
    case "spacing-scale":
      return "accrue_admin/e2e/foundation-tokens.spec.js";
    case "microcopy":
      return "accrue_admin/e2e/admin-page-flow-phase200.spec.js";
    case "focus-ring":
      return "accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js";
    case "motion":
      return "accrue_admin/e2e/reduced-motion.spec.js";
    case "ledger-count":
      return null;
  }
}
```

**Guard-ref generation and safety pattern** (lines 140-168):
```js
function mintGuardRow(finding, probedFields = {}) {
  const kind = kindForFinding(finding);
  if (kind === "ledger-count") {
    return { guard_ref: "ledger-count", targetSpecPath: null, row: null };
  }

  const targetSpecPath = homeSpecForKind(kind);
  if (!isSafeSpecPath(targetSpecPath) || !GUARD_HOME_SPECS.includes(targetSpecPath)) {
    throw new Error(`mintGuardRow: kind ${JSON.stringify(kind)} resolved to a non-allowlisted home spec`);
  }

  const guard_ref = `${targetSpecPath}::@ratchet:${finding.finding_id}`;
  const row = buildRow(kind, finding, probedFields);
  return { guard_ref, targetSpecPath, row };
}
```

**Marker-region append pattern** (lines 177-239):
```js
function locateRegion(text) {
  const openIdx = text.indexOf(OPEN_MARKER);
  if (openIdx === -1) throw new Error(`locateRegion: open marker not found (${OPEN_MARKER})`);
  const bodyStart = openIdx + OPEN_MARKER.length;
  const closeIdx = text.indexOf(CLOSE_MARKER, bodyStart);
  if (closeIdx === -1) throw new Error(`locateRegion: close marker not found (${CLOSE_MARKER})`);
  return { bodyStart, closeIdx };
}

function appendMintedRow(targetSpecPath, row, repoRoot) {
  if (!isSafeSpecPath(targetSpecPath)) throw new Error(`appendMintedRow: refusing unsafe/non-allowlisted spec path`);
  const absPath = path.join(repoRoot, targetSpecPath);
  const text = fs.readFileSync(absPath, "utf8");
  const { bodyStart, closeIdx } = locateRegion(text);
  const body = text.slice(bodyStart, closeIdx);
  const token = `@ratchet:${row.finding_id}`;
  if (body.includes(token)) return { changed: false };

  const rows = sortByFindingId([...parseExistingRows(body), row]);
  const newBody = `\n${serializeDeclaration(rows)}\n`;
  fs.writeFileSync(absPath, text.slice(0, bodyStart) + newBody + text.slice(closeIdx));
  return { changed: true };
}
```

### `accrue_admin/e2e/ratchet/ratchet-propose.mjs` (external service client, request-response)

**Analog:** same file, existing request/discovery seams

**Key-free guard ordering** (lines 51-60, 157-167):
```js
if (process.argv.includes("--self-test")) {
  regionTags.runSelfTest();
  runProposeSelfTest();
  process.exit(0);
}

if (!process.env.ANTHROPIC_API_KEY) {
  console.log("[ratchet-propose] ANTHROPIC_API_KEY not set - skipping (human/CI gate only)");
  process.exit(0);
}

const { default: manifest } = await import("../baseline-manifest.js");
const { default: Anthropic } = await import("@anthropic-ai/sdk");
```

**Surface filter pattern** (lines 413-459):
```js
export function filterPngsBySurfaces(pngs, surfacesCsv) {
  if (!surfacesCsv) return pngs;
  const wanted = new Set(String(surfacesCsv).split(",").map((s) => s.trim()).filter(Boolean));
  if (wanted.size === 0) return pngs;
  return pngs.filter((png) => wanted.has(png.screen));
}

function discoverPngs() {
  // ... derive `screen` from PNG filename ...
  return filterPngsBySurfaces(pngs, process.env.RATCHET_SURFACES);
}
```

**Cache-control request builder pattern** (lines 540-583):
```js
function buildPersonaRequest(model, systemPreamble, toolSchema, b64, persona) {
  const request = {
    model,
    max_tokens: 2048,
    system: [{ type: "text", text: systemPreamble, cache_control: { type: "ephemeral" } }],
    tools: [{ ...toolSchema, cache_control: { type: "ephemeral" } }],
    tool_choice: { type: "tool", name: "emit_findings" },
    messages: [{ role: "user", content: [
      { type: "image", source: { type: "base64", media_type: "image/png", data: b64 }, cache_control: { type: "ephemeral" } },
      { type: "text", text: buildLensPrompt(persona) },
    ] }],
  };
  if (supportsSampling(model)) request.temperature = 0;
  return request;
}
```

**Deterministic identity emit pattern** (lines 740-853):
```js
function emitCandidates(png, surface, collected, provenance) {
  const rows = [];
  for (const item of collected) {
    const dimension = regionTags.assertDimension(f.dimension);
    const region_tag = regionTags.normalizeRegion(surface, f.region_tag);
    const overlay_tags = regionTags.normalizeOverlays(f.overlay_tags);
    if (!regionTags.isAdmissibleToken(f.justification_token)) continue;

    const claim_key = regionTags.claimKey(surface, dimension, region_tag, overlay_tags);
    const finding_id = regionTags.findingId(claim_key);

    rows.push({
      schema_version: "ratchet-candidate/1",
      run_id: provenance.run_id,
      round,
      claim_key,
      finding_id,
      effort_hint: validEffortHint(f.effort_hint),
    });
  }
  return rows;
}
```

### `accrue_admin/e2e/ratchet/ratchet-verify.mjs` (external-service verifier, request-response)

**Analog:** same file, existing verifier loop

**Key-free guard ordering** (lines 210-229):
```js
if (process.argv.includes("--self-test")) {
  runSelfTest();
  process.exit(0);
}

if (!process.env.ANTHROPIC_API_KEY) {
  console.log("[ratchet-verify] ANTHROPIC_API_KEY not set - skipping (human/CI gate only)");
  process.exit(0);
}

const { default: Anthropic } = await import("@anthropic-ai/sdk");
```

**Cache-control verifier request** (lines 393-417):
```js
function buildPanelRequest(model, systemAndRubric, panelTool, b64, findingsText) {
  const request = {
    model,
    max_tokens: 4096,
    system: [{ type: "text", text: systemAndRubric, cache_control: { type: "ephemeral" } }],
    tools: [{ ...panelTool, cache_control: { type: "ephemeral" } }],
    tool_choice: { type: "tool", name: "emit_verdicts" },
    messages: [{ role: "user", content: [
      { type: "image", source: { type: "base64", media_type: "image/png", data: b64 }, cache_control: { type: "ephemeral" } },
      { type: "text", text: findingsText },
    ] }],
  };
  if (supportsSampling(model)) request.temperature = 0;
  return request;
}
```

**Collapse -> verify -> append pattern** (lines 463-523):
```js
const candidateRows = raw ? raw.split("\n").map((line) => JSON.parse(line)) : [];
const collapsed = ratchetLedger.collapseByFindingId(candidateRows);
const collapsedByFindingId = buildValidatedCandidateMap(collapsed);
const groups = groupByPngRef(collapsed);

for (const [pngRef, group] of groups) {
  const verdicts = await verifyImageGroup(pngRef, group);
  for (const verdict of verdicts) {
    appendEphemeralVerdict(verdict);
    const result = confirmAndWrite(verdict, collapsedByFindingId, LEDGER_PATH);
    if (result.written) confirmedCount++;
  }
}
```

### `accrue_admin/e2e/admin-visuals.spec.js` (browser test/capture spec)

**Analog:** same file

**Capture + bbox sidecar pattern** (lines 41-50, 69-92):
```js
async function captureThemes(page, name, project) {
  const dir = `test-results/admin-visuals/${project}`;
  await page.evaluate(() => document.documentElement.setAttribute("data-theme", "light"));
  await page.screenshot({ path: `${dir}/${name}.png`, fullPage });
  await captureBBoxes(page, name, project, "light");
  await page.evaluate(() => document.documentElement.setAttribute("data-theme", "dark"));
  await page.screenshot({ path: `${dir}/${name}-dark.png`, fullPage });
  await captureBBoxes(page, name, project, "dark");
}

async function captureBBoxes(page, name, project, theme) {
  if (!REGION_SELECTORS) return;
  const boxes = {};
  for (const [regionTag, selector] of Object.entries(REGION_SELECTORS)) {
    let box = null;
    try {
      const loc = page.locator("." + selector).first();
      if (await loc.count()) box = await loc.boundingBox();
    } catch {
      box = null;
    }
    boxes[regionTag] = box || null;
  }
  await fs.promises.writeFile(`${dir}/${name}${suffix}.bbox.json`, JSON.stringify(boxes, null, 2));
}
```

**Surface subset filter** (lines 140-153):
```js
const surfacesCsv = process.env.RATCHET_SURFACES;
let selectedShots = shots;
if (surfacesCsv) {
  const wanted = new Set(surfacesCsv.split(",").map((s) => s.trim()).filter(Boolean));
  selectedShots = shots.filter(([name]) => wanted.has(name));
}

for (const [name, path] of selectedShots) {
  await login(page, path);
  await captureThemes(page, name, project);
}
```

### `accrue_admin/e2e/baseline-manifest.js` (config/manifest)

**Analog:** same file

**SURFACES + SLICES export pattern** (lines 244-261, 325-336):
```js
const SURFACES = [
  ...PAGE_FLOWS.map(pageSurface),
  ...COMPONENT_FAMILIES.map(componentSurface),
  ...COMPONENT_GROUPS.map(componentGroupSurface),
];

const SLICES = {
  foundation: ["component-kitchen", "dashboard", "subscription-detail", "subscriptions"],
};

module.exports = {
  DIMENSIONS,
  STATE_TAXONOMY,
  SURFACES,
  SLICES,
  cellId,
  cellsForSurface,
};
```

### Guard Home Specs (test/guard homes, browser-driven assertions)

**Analogs:** same files, marker loops

**Foundation token/contrast/spacing home** (`foundation-tokens.spec.js` lines 174-217):
```js
// >>> @ratchet:auto-guards >>>
const RATCHET_AUTO_GUARDS = [];
// <<< @ratchet:auto-guards <<<

test("auto-minted ratchet guards - foundation tokens (design-token / contrast / spacing-scale)", async ({ page }) => {
  test.skip(RATCHET_AUTO_GUARDS.length === 0, "no minted ratchet guards yet");
  for (const row of RATCHET_AUTO_GUARDS) {
    if (row.kind === "design-token") {
      const actual = await styleOf(locator, row.property);
      const expected = await rootToken(page, row.expected_token);
      expect(actual).toBe(expected);
    } else if (row.kind === "contrast") {
      expectContrastAtLeast(await styleOf(locator, "color"), await styleOf(locator, "backgroundColor"), row.min_ratio);
    } else if (row.kind === "spacing-scale") {
      expect(row.allowed_values).toContain(actual);
    }
  }
});
```

**Focus-ring home** (`admin-interaction-overlay-phase199.spec.js` lines 964-991):
```js
// >>> @ratchet:auto-guards >>>
const RATCHET_AUTO_GUARDS = [];
// <<< @ratchet:auto-guards <<<

test("auto-minted ratchet guards - interaction focus-ring", async ({ page }) => {
  test.skip(RATCHET_AUTO_GUARDS.length === 0, "no minted ratchet guards yet");
  for (const row of RATCHET_AUTO_GUARDS) {
    if (row.kind !== "focus-ring") throw new Error(`unexpected kind`);
    await login(page, row.route || "/billing/dev/components");
    const locator = page.locator(row.selector).first();
    await locator.focus();
    const outlineStyle = await locator.evaluate((el) => window.getComputedStyle(el).outlineStyle);
    expect(outlineStyle).not.toBe("none");
  }
});
```

**Motion home** (`reduced-motion.spec.js` lines 365-398) and **microcopy home** (`admin-page-flow-phase200.spec.js` lines 350-378) follow the same marker-region + table-loop pattern.

### `accrue_admin/package.json` (config, command wiring)

**Analog:** existing npm script block lines 18-27:
```json
"ratchet:propose": "node e2e/ratchet/ratchet-propose.mjs",
"ratchet:self-test": "node e2e/ratchet/ratchet-propose.mjs --self-test",
"ratchet:verify": "node e2e/ratchet/ratchet-verify.mjs",
"ratchet:verify:self-test": "node e2e/ratchet/ratchet-verify.mjs --self-test",
"ratchet:ledger": "node e2e/ratchet/phase-ratchet-ledger.mjs && node ../scripts/ci/verify_ratchet_ledger.mjs",
"ratchet:ledger:self-test": "node e2e/ratchet/phase-ratchet-ledger.mjs --self-test && node ../scripts/ci/verify_ratchet_ledger.mjs --self-test",
"ratchet:digest": "node e2e/ratchet/ratchet-digest.mjs",
"ratchet:digest:self-test": "node e2e/ratchet/ratchet-digest.mjs --self-test",
"ui:round": "cd .. && mix accrue_admin.ui.round",
"ui:fix": "cd .. && mix accrue_admin.ui.fix"
```

### `scripts/ci/verify_ratchet_ledger.mjs` (conditional verifier)

**Analog:** same file independent verifier discipline.

**Independence discipline** (lines 1-40):
```js
/**
 * This file deliberately does NOT import the deterministic reducer module it cross-checks,
 * nor the shared lifecycle/fold helper module ... genuine code independence.
 *
 * It NEVER reads `ledger.baseline.json`'s own stored `confirmed_open` numbers as an input
 * to the recompute - only as the thing being cross-checked against.
 */
```

**Duplicated allowlist + independent guard check** (lines 85-90, 265-305):
```js
const GUARD_HOME_SPECS = [
  "accrue_admin/e2e/foundation-tokens.spec.js",
  "accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js",
  "accrue_admin/e2e/reduced-motion.spec.js",
  "accrue_admin/e2e/admin-page-flow-phase200.spec.js",
];

function checkGuardRefIndependent(guardRef, findingId, repoRoot) {
  if (guardRef === "ledger-count") return { ok: true };
  const parts = guardRef.split("::");
  if (parts.length !== 2 || !parts[0] || !parts[1]) return { ok: false };
  const [specPath, token] = parts;
  if (!validGuardHomePath(specPath)) return { ok: false };
  const tokenMatch = /^@ratchet:(f-[0-9a-f]{16})$/.exec(token);
  if (!tokenMatch || tokenMatch[1] !== findingId) return { ok: false };
  const contents = fs.readFileSync(path.join(repoRoot, specPath), "utf8");
  if (!contents.includes(token)) return { ok: false };
  return { ok: true };
}
```

## Shared Patterns

### Thin Mix Tasks Over Node/Playwright
**Source:** `accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex` lines 23-59, 87-97  
**Apply to:** `accrue_admin.ui.round.ex`, `accrue_admin.ui.fix.ex`

Use `Runner`/`ShellRunner`, `Application.get_env/3` runner injection, sequenced `run_step!`, and `Mix.raise` on non-zero. Do not put ledger/dry/convergence reasoning in Elixir.

### File-Driven Checkpoints
**Source:** `accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex` lines 107-132; `ratchet-fix.mjs` lines 125-224  
**Apply to:** `decisions.json`, `.fix-context.json`, `ui.fix`

Use `OptionParser`/`File`/`Jason` in Mix tasks and JSON array validation in Node. Reject invalid rows before any partial ledger mutation.

### Self-Test Discipline
**Source:** `phase192-gallery.mjs` lines 625-730; `phase-ratchet-ledger.mjs` lines 666-970; `ratchet-fix.mjs` lines 330-585  
**Apply to:** all new `.mjs` utilities

Every script gets a key-free `--self-test` that runs first, uses `fs.mkdtempSync` scratch fixtures, and cleans up in `finally`. No self-test mutates committed files.

### Append-Only Ledger Events
**Source:** `ratchet-ledger.js` lines 21-31, 286-345, 357-405, 472-548  
**Apply to:** `rounds.ndjson`, `findings.ledger.ndjson` lifecycle advances, dry-round fold logic

Rows are append-only NDJSON with monotonic `seq`. Reducers fold latest-event-wins by ID and throw on non-monotonic sequence.

### Guard-Ref Safety
**Source:** `phase-ratchet-ledger.mjs` lines 342-399; `scripts/ci/verify_ratchet_ledger.mjs` lines 258-305  
**Apply to:** guard minting, verified-close promotion, guard-home spec writes

Only closed allowlisted spec paths are valid; `guard_ref` is `path::@ratchet:f-<16hex>`, and the spec must contain the literal token. `ledger-count` is the explicit sentinel for no real guard.

### Prompt Caching
**Source:** `ratchet-propose.mjs` lines 540-583; `ratchet-verify.mjs` lines 393-417  
**Apply to:** proposer/verifier request builders

Use exactly three `cache_control: { type: "ephemeral" }` breakpoints: system text block, tool schema, first image block. Do not cache the variable prompt/findings text block.

### Surface Subset Filtering
**Source:** `admin-visuals.spec.js` lines 140-153; `ratchet-propose.mjs` lines 413-459; `baseline-manifest.js` lines 250-261  
**Apply to:** `--slice`, `--surface`, `RATCHET_SURFACES`

Resolve named slices into the same CSV vocabulary the capture spec and proposer both consume. Unknown names match nothing and never expand scope.

## No Exact Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `accrue_admin/e2e/ratchet/ratchet-digest.mjs` | utility/static artifact renderer | transform + file-I/O | No prior literal HTML digest/gallery renderer exists; use `phase192-gallery.mjs` structure and add HTML escaping. |
| `accrue_admin/e2e/ratchet/rounds.ndjson` | model/event log | append-only event-driven | Existing NDJSON logs establish append-only shape, but round-seal/dry/convergence schema is new. |
| `accrue_admin/e2e/ratchet/ratchet-guard-mint.mjs` | utility/codegen-data writer | file-I/O + transform | No prior marker-region data-row writer exists; use guard-ref allowlist checks plus guard-home table-loop specs. |

## Metadata

**Analog search scope:** `accrue_admin/lib/mix/tasks`, `accrue_admin/test/mix/tasks`, `accrue_admin/e2e`, `accrue_admin/e2e/ratchet`, `scripts/ci`, `accrue_admin/package.json`  
**Files scanned:** 80+ via `rg --files`; 24 files/ranges read for pattern extraction  
**Pattern extraction date:** 2026-07-07
