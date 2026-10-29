import assert from "node:assert/strict";
import test from "node:test";
import { isMainModule } from "./main_module.mjs";

export const REQUIRED_OWNER = "admin-phase200-guardrails";

export const REQUIRED_ROOT_IDS = Object.freeze([
  "root-storybook",
  "ui-scenarios",
  "admin-storybook-support",
  "shared-components",
  "subscription-renderer",
  "copy-owner",
  "scoped-path-owner",
  "component-registry",
  "generated-story-manifest",
  "admin-css-tokens",
  "admin-built-css",
  "brandbook-tokens",
  "browser-specs",
  "browser-config",
  "browser-workflow",
  "admin-test-support",
  "phase252-lab-runner",
  "phase252-lab-support",
  "phase252-ci-runners",
  "phase252-ci-generators",
  "phase252-transparency-fixtures",
  "phase252-transparency-guide",
  "phase252-transparency-reporters",
  "phase252-evidence-resolver",
  "phase252-lab-prohibition-plan",
  "phase252-heldout-prohibition-plan",
  ...[2, 3, 5, 6, 7, 8, 9, 10].map((number) => `phase252-acceptance-plan-${number}`),
  "phase252-validation-accounting",
  "phase200-owner-contracts",
  "required-ci-workflow",
  "phase252-package-script",
  "phase253-collection-renderer",
  "phase253-focused-runner",
  "phase253-focused-runner-tests",
  "phase253-acceptance-generator",
  "phase253-ci-imported-module",
  "phase253-historical-unclassified-summary",
  "phase253-transparency-fixtures",
  "phase253-prohibition-plan",
  "phase253-validation",
  "phase253-presentation-controls",
  "phase253-collection-story",
  "phase253-whole-page-story",
  "phase253-admin-adapters",
  "phase253-admin-tests",
  "phase253-browser-spec",
  "phase253-browser-helper",
  "phase254-ci-scripts",
  "phase254-verifiers",
  "phase254-budget",
  "phase254-selection-projection",
  "subscription-curation-ledger",
  "phase254-selection-fixtures",
  "playwright-default-config",
]);

export const CONSUMED_ROOTS = Object.freeze([
  { id: "root-storybook", path: "storybook/", mode: "prefix", owner: REQUIRED_OWNER },
  { id: "ui-scenarios", path: "dev_support/ui_scenarios/", mode: "prefix", owner: REQUIRED_OWNER },
  { id: "admin-storybook-support", path: "accrue_admin/storybook/_support/", mode: "prefix", owner: REQUIRED_OWNER },
  { id: "shared-components", path: "accrue_admin/lib/accrue_admin/components/", mode: "prefix", owner: REQUIRED_OWNER },
  { id: "subscription-renderer", path: "accrue_admin/lib/accrue_admin/live/subscription_live.ex", mode: "exact", owner: REQUIRED_OWNER },
  { id: "copy-owner", path: "accrue_admin/lib/accrue_admin/copy.ex", mode: "exact", owner: REQUIRED_OWNER },
  { id: "copy-owner-submodules", path: "accrue_admin/lib/accrue_admin/copy/", mode: "prefix", owner: REQUIRED_OWNER },
  { id: "scoped-path-owner", path: "accrue_admin/lib/accrue_admin/scoped_path.ex", mode: "exact", owner: REQUIRED_OWNER },
  { id: "component-registry", path: "accrue_admin/lib/accrue_admin/dev/component_registry.ex", mode: "exact", owner: REQUIRED_OWNER },
  { id: "generated-story-manifest", path: "storybook/phase252-manifest.json", mode: "exact", owner: REQUIRED_OWNER },
  { id: "admin-css-tokens", path: "accrue_admin/assets/css/", mode: "prefix", owner: REQUIRED_OWNER },
  { id: "admin-built-css", path: "accrue_admin/priv/static/accrue_admin.css", mode: "exact", owner: REQUIRED_OWNER },
  { id: "admin-built-storybook-css", path: "accrue_admin/priv/static/storybook.css", mode: "exact", owner: REQUIRED_OWNER },
  { id: "brandbook-tokens", path: "brandbook/tokens/", mode: "prefix", owner: REQUIRED_OWNER },
  { id: "browser-specs", path: "accrue_admin/e2e/", mode: "prefix", owner: REQUIRED_OWNER },
  { id: "browser-config", path: "accrue_admin/playwright.phase252.config.js", mode: "exact", owner: REQUIRED_OWNER },
  { id: "browser-workflow", path: ".github/workflows/accrue_admin_browser.yml", mode: "exact", owner: REQUIRED_OWNER },
  { id: "admin-test-support", path: "accrue_admin/test/accrue_admin/", mode: "prefix", owner: REQUIRED_OWNER },
  { id: "phase252-lab-runner", path: "scripts/dev/phase252_lab.mjs", mode: "exact", owner: REQUIRED_OWNER },
  { id: "phase252-lab-support", path: "scripts/dev/phase252_", mode: "prefix", owner: REQUIRED_OWNER },
  { id: "phase252-ci-runners", path: "scripts/ci/verify_phase252_", mode: "prefix", owner: REQUIRED_OWNER },
  { id: "phase252-ci-generators", path: "scripts/ci/generate_phase252_", mode: "prefix", owner: REQUIRED_OWNER },
  { id: "phase252-path-classifier", path: "scripts/ci/phase252_paths.mjs", mode: "exact", owner: REQUIRED_OWNER },
  { id: "phase252-transparency-fixtures", path: "scripts/ci/fixtures/phase252-transparency/", mode: "prefix", owner: REQUIRED_OWNER },
  { id: "phase252-transparency-guide", path: "guides/ui-story-lab.md", mode: "exact", owner: REQUIRED_OWNER },
  { id: "phase252-transparency-reporters", path: "scripts/ci/phase252_reporters.mjs", mode: "exact", owner: REQUIRED_OWNER },
  { id: "phase252-evidence-resolver", path: "scripts/ci/phase_evidence_path.mjs", mode: "exact", owner: REQUIRED_OWNER },
  { id: "phase252-lab-prohibition-plan", path: ".planning/phases/252-production-backed-subscription-stories/252-01-PLAN.md", mode: "exact", owner: REQUIRED_OWNER },
  { id: "phase252-heldout-prohibition-plan", path: ".planning/phases/252-production-backed-subscription-stories/252-04-PLAN.md", mode: "exact", owner: REQUIRED_OWNER },
  ...[2, 3, 5, 6, 7, 8, 9, 10].map((number) => ({ id: `phase252-acceptance-plan-${number}`, path: `.planning/phases/252-production-backed-subscription-stories/252-${String(number).padStart(2, "0")}-PLAN.md`, mode: "exact", owner: REQUIRED_OWNER })),
  { id: "phase252-validation-accounting", path: ".planning/phases/252-production-backed-subscription-stories/252-VALIDATION.md", mode: "exact", owner: REQUIRED_OWNER },
  { id: "phase200-owner-contracts", path: "scripts/ci/verify_phase200_", mode: "prefix", owner: REQUIRED_OWNER },
  { id: "required-ci-workflow", path: ".github/workflows/ci.yml", mode: "exact", owner: REQUIRED_OWNER },
  { id: "phase252-package-script", path: "accrue_admin/package.json", mode: "exact", owner: REQUIRED_OWNER },
  { id: "phase253-collection-renderer", path: "accrue_admin/lib/accrue_admin/live/subscriptions_live.ex", mode: "exact", owner: REQUIRED_OWNER },
  { id: "phase253-focused-runner", path: "scripts/ci/verify_phase253_compositions.mjs", mode: "exact", owner: REQUIRED_OWNER },
  { id: "phase253-focused-runner-tests", path: "scripts/ci/verify_phase253_compositions.test.mjs", mode: "exact", owner: REQUIRED_OWNER },
  { id: "phase253-acceptance-generator", path: "scripts/ci/generate_phase253_acceptance.mjs", mode: "exact", owner: REQUIRED_OWNER },
  { id: "phase253-ci-imported-module", path: "scripts/ci/main_module.mjs", mode: "exact", owner: REQUIRED_OWNER },
  { id: "phase253-historical-unclassified-summary", path: ".planning/phases/252-production-backed-subscription-stories/252-08-SUMMARY.md", mode: "exact", owner: REQUIRED_OWNER },
  { id: "phase253-transparency-fixtures", path: "scripts/ci/fixtures/phase253-transparency/", mode: "prefix", owner: REQUIRED_OWNER },
  { id: "phase253-prohibition-plan", path: ".planning/phases/253-real-groups-and-a-whole-subscription-job/253-05-PLAN.md", mode: "exact", owner: REQUIRED_OWNER },
  { id: "phase253-validation", path: ".planning/phases/253-real-groups-and-a-whole-subscription-job/253-VALIDATION.md", mode: "exact", owner: REQUIRED_OWNER },
  { id: "phase253-presentation-controls", path: "scripts/ci/verify_phase253_presentation.test.mjs", mode: "exact", owner: REQUIRED_OWNER },
  { id: "phase253-collection-story", path: "storybook/groups/subscriptions_collection.story.exs", mode: "exact", owner: REQUIRED_OWNER },
  { id: "phase253-whole-page-story", path: "storybook/pages/subscription.story.exs", mode: "exact", owner: REQUIRED_OWNER },
  { id: "phase253-admin-adapters", path: "accrue_admin/storybook/_support/subscription_collection.ex", mode: "exact", owner: REQUIRED_OWNER },
  { id: "phase253-admin-tests", path: "accrue_admin/test/accrue_admin/dev/subscription_collection_transport_test.exs", mode: "exact", owner: REQUIRED_OWNER },
  { id: "phase253-browser-spec", path: "accrue_admin/e2e/subscription-compositions-phase253.spec.js", mode: "exact", owner: REQUIRED_OWNER },
  { id: "phase253-browser-helper", path: "accrue_admin/e2e/phase253-composition-helpers.js", mode: "exact", owner: REQUIRED_OWNER },
  // Phase 254: every path the required owner reads for recurring quality and selection. The
  // three storybook JSON files are exact roots on purpose: there is no accrue_admin/storybook/
  // prefix, so an unrelated JSON file there stays unmapped (and the selector broadens, FC-1).
  { id: "phase254-ci-scripts", path: "scripts/ci/phase254_", mode: "prefix", owner: REQUIRED_OWNER },
  { id: "phase254-verifiers", path: "scripts/ci/verify_phase254_", mode: "prefix", owner: REQUIRED_OWNER },
  { id: "phase254-budget", path: "accrue_admin/storybook/phase254-budget.json", mode: "exact", owner: REQUIRED_OWNER },
  { id: "phase254-selection-projection", path: "accrue_admin/storybook/phase254-selection.json", mode: "exact", owner: REQUIRED_OWNER },
  { id: "subscription-curation-ledger", path: "accrue_admin/storybook/subscription-curation.json", mode: "exact", owner: REQUIRED_OWNER },
  { id: "phase254-selection-fixtures", path: "scripts/ci/fixtures/phase254-selection/", mode: "prefix", owner: REQUIRED_OWNER },
  { id: "playwright-default-config", path: "accrue_admin/playwright.config.js", mode: "exact", owner: REQUIRED_OWNER },
]);

function fail(message) {
  throw new Error(`Phase 252 CI contract: ${message}`);
}

export function normalizeRepoPath(value) {
  if (typeof value !== "string" || value.length === 0 || value.includes("\0")) return null;
  const normalized = value.replaceAll("\\", "/");
  if (normalized.startsWith("/") || /^[A-Za-z]:\//.test(normalized)) return null;
  const segments = normalized.split("/");
  if (segments.some((segment) => segment === ".." || segment === "." || segment === "")) return null;
  return segments.join("/");
}

export function matchesRule(repoPath, rule) {
  const isDirectoryPrefix = rule.path.endsWith("/");
  const root = rule.path.replace(/\/$/, "");
  if (rule.mode === "exact") return repoPath === root;
  if (rule.mode === "prefix") {
    return isDirectoryPrefix
      ? repoPath === root || repoPath.startsWith(`${root}/`)
      : repoPath.startsWith(root);
  }
  return false;
}

function manifestSourcePaths(manifest) {
  const values = manifest?.source_digests;
  if (!values || typeof values !== "object" || Array.isArray(values)) return [];
  return Object.keys(values);
}

export function classifyPath(value, { roots = CONSUMED_ROOTS, manifest } = {}) {
  const repoPath = normalizeRepoPath(value);
  if (!repoPath) return null;
  if (roots.some((rule) => rule.owner === REQUIRED_OWNER && matchesRule(repoPath, rule))) {
    return REQUIRED_OWNER;
  }
  if (manifestSourcePaths(manifest).some((source) => normalizeRepoPath(source) === repoPath)) {
    return REQUIRED_OWNER;
  }
  return null;
}

export function assertOwnerMap(roots = CONSUMED_ROOTS, manifest) {
  if (!Array.isArray(roots)) fail("consumed roots must be an array");
  const ids = new Set();
  for (const rule of roots) {
    if (!rule || typeof rule !== "object") fail("consumed root entry is malformed");
    if (typeof rule.id !== "string" || !rule.id) fail("consumed root is missing its id");
    if (ids.has(rule.id)) fail(`duplicate consumed root id: ${rule.id}`);
    ids.add(rule.id);
    if (!normalizeRepoPath(rule.path.replace(/\/$/, ""))) fail(`${rule.id} has an unsafe root path`);
    if (!new Set(["exact", "prefix"]).has(rule.mode)) fail(`${rule.id} has unsupported match mode`);
    if (rule.owner !== REQUIRED_OWNER) fail(`${rule.id} has no named required owner`);
  }

  const missing = REQUIRED_ROOT_IDS.filter((id) => !ids.has(id));
  if (missing.length > 0) fail(`consumed root map omits required roots: ${missing.join(", ")}`);

  if (manifest !== undefined) {
    for (const source of manifestSourcePaths(manifest)) {
      if (classifyPath(source, { roots, manifest }) !== REQUIRED_OWNER) {
        fail(`manifest source has no required owner: ${source}`);
      }
    }
  }
  return true;
}

function indentedBlock(source, header, nextHeaderPattern) {
  const start = source.search(header);
  if (start < 0) return null;
  const rest = source.slice(start);
  const end = rest.slice(1).search(nextHeaderPattern);
  return end < 0 ? rest : rest.slice(0, end + 1);
}

function pullRequestEvent(workflow) {
  return indentedBlock(workflow, /^  pull_request:\s*$/m, /^  [A-Za-z0-9_-]+:\s*$/m);
}

function requiredJob(workflow) {
  const jobsAt = workflow.search(/^jobs:\s*$/m);
  if (jobsAt < 0) return null;
  return indentedBlock(workflow.slice(jobsAt), /^  admin-phase200-guardrails:\s*$/m, /^  [A-Za-z0-9_-]+:\s*$/m);
}

export function assertCiContract({
  workflow,
  ownerRunner,
  manifest,
  requirePhase252 = false,
  requirePhase253 = false,
  requirePhase254Selection = false,
  requirePhase254Budget = false,
  roots = CONSUMED_ROOTS,
}) {
  if (typeof workflow !== "string" || typeof ownerRunner !== "string") {
    fail("workflow and required owner runner source are required");
  }
  assertOwnerMap(roots, manifest);

  const event = pullRequestEvent(workflow);
  if (!event) fail("workflow does not admit pull_request events");
  const uncommentedEvent = event.split("\n").map((line) => line.replace(/\s+#.*$/, "")).join("\n");
  if (/^\s{4}paths(?:-ignore)?:/m.test(uncommentedEvent)) {
    fail("pull_request path filters can exclude consumed roots");
  }

  const job = requiredJob(workflow);
  if (!job) fail(`workflow is missing required job ${REQUIRED_OWNER}`);
  if (!/^    name:\s*Admin Phase 200 deterministic guardrails\s*$/m.test(job)) {
    fail("named required CI owner has changed or is missing");
  }
  const condition = job.match(/^    if:\s*(.*?)\s*$/m)?.[1];
  if (condition && (
    /^(?:false|0|never)\s*$/i.test(condition.replace(/^\$\{\{|\}\}$/g, "").trim()) ||
    /github\.event_name\s*!=\s*['"]pull_request['"]/i.test(condition) ||
    /github\.event_name\s*==\s*['"](?:push|schedule|workflow_dispatch)['"]/i.test(condition)
  )) {
    fail(`required job condition can skip pull requests: ${condition}`);
  }
  if (/^    continue-on-error:\s*(?:true|\$\{\{\s*true\s*\}\})\s*$/mi.test(job)) {
    fail("required CI owner is optional because continue-on-error is enabled");
  }
  if (!job.includes("bash scripts/ci/verify_phase200_admin_guardrails.sh")) {
    fail("required workflow job does not invoke the existing phase200 owner runner");
  }
  if (!/^set -e(?:uo pipefail)?\s*$/m.test(ownerRunner)) {
    fail("required owner runner must stop on a failed focused command");
  }
  const phase252Step = /^run_step "Phase 252 complete subscription story acceptance" npm --prefix accrue_admin run phase252:check$/m;
  const phase253Step = /^run_step "Phase 253 focused composition acceptance" node scripts\/ci\/verify_phase253_compositions\.mjs$/m;
  const phase254BudgetStep = /^run_step "Phase 254 recurring budget check" node scripts\/ci\/phase254_budget\.mjs check$/m;
  const phase252Match = phase252Step.exec(ownerRunner);
  if ((requirePhase252 || requirePhase253 || requirePhase254Budget) && !phase252Match) {
    fail("required owner runner does not invoke npm --prefix accrue_admin run phase252:check");
  }
  if (requirePhase253 || requirePhase254Budget) {
    const phase253Match = phase253Step.exec(ownerRunner);
    if (!phase253Match) fail("required owner runner does not invoke node scripts/ci/verify_phase253_compositions.mjs");
    if (phase253Match.index < phase252Match.index) {
      fail("Phase 253 composition acceptance must run after the complete Phase 252 check");
    }
    // Phase 254 CIQ-04 (D-23): the budget check reads the Phase 252/253 results bundles, so it
    // runs after both aggregates, unconditionally, as its own named step.
    if (requirePhase254Budget) {
      const budgetMatch = phase254BudgetStep.exec(ownerRunner);
      if (!budgetMatch) fail("required owner runner does not invoke node scripts/ci/phase254_budget.mjs check as an unconditional Phase 254 recurring budget check step");
      if (budgetMatch.index < phase253Match.index) fail("the Phase 254 recurring budget check must run after the Phase 253 composition acceptance");
    }
  }
  if (requirePhase254Selection) assertPhase254Selection(workflow, job);
  return true;
}

// Phase 254 CIQ-02 (D-10, FC-3, T-254-16, T-254-17): the required job computes the selection from
// full history before the guardrail runner, never takes its inputs from interpolated script text,
// and never uses the local-only --changed-paths-file option.
function stepBlock(job, name) {
  const header = `      - name: ${name}\n`;
  const start = job.indexOf(header);
  if (start < 0) return null;
  const rest = job.slice(start + header.length);
  const end = rest.search(/^      - /m);
  return { start, text: end < 0 ? rest : rest.slice(0, end) };
}

function withoutComments(text) {
  return text.split("\n").map((line) => line.replace(/^\s*#.*$/, "").replace(/\s+#.*$/, "")).join("\n");
}

export function assertPhase254Selection(workflow, job = requiredJob(workflow)) {
  if (!job) fail(`workflow is missing required job ${REQUIRED_OWNER}`);
  const uncommentedJob = withoutComments(job);
  if (!/^      - uses: actions\/checkout@[^\n]*\n        with:\n(?:          [^\n]*\n)*?          fetch-depth:\s*0\s*$/m.test(uncommentedJob)) {
    fail("the required CI owner checkout must use fetch-depth: 0 so the selection diff has full history");
  }
  const step = stepBlock(uncommentedJob, "Phase 254 selection");
  if (!step) fail("the required CI owner has no Phase 254 selection step");
  const runnerAt = uncommentedJob.indexOf("bash scripts/ci/verify_phase200_admin_guardrails.sh");
  if (runnerAt < 0 || step.start > runnerAt) fail("the Phase 254 selection step must run before the guardrail runner");
  const runBody = step.text.split(/^        run: \|\n/m)[1] ?? "";
  if (!/node scripts\/ci\/phase254_selection\.mjs select\b/.test(runBody)) fail("the Phase 254 selection step does not invoke the selector select verb");
  if (!/--summary\b/.test(runBody)) fail("the Phase 254 selection step must render the report with --summary");
  if (!/--out "\$report"/.test(runBody) || !/accrue_admin\/tmp\/phase254\/selection-\$\{PHASE254_RUN_ID\}\.json/.test(runBody)) {
    fail("the Phase 254 selection report must be written to accrue_admin/tmp/phase254/selection-<run_id>.json");
  }
  if (!/echo "PHASE254_SELECTION=\$report" >> "\$GITHUB_ENV"/.test(runBody)) fail("the Phase 254 selection step must export PHASE254_SELECTION through GITHUB_ENV");
  for (const [name, expression] of [
    ["PHASE254_EVENT", "github.event_name"],
    ["PHASE254_BASE", "github.event.pull_request.base.sha"],
    ["PHASE254_HEAD", "github.sha"],
    ["PHASE254_RUN_ID", "github.run_id"],
  ]) {
    if (!new RegExp(`^          ${name}: \\$\\{\\{ ${expression.replaceAll(".", "\\.")} \\}\\}\\s*$`, "m").test(step.text)) {
      fail(`the Phase 254 selection step must pass ${expression} through env ${name}`);
    }
  }
  if (runBody.includes("${{")) fail("the Phase 254 selection step must pass event values through env, not interpolate them into the script");
  if (/--changed-paths-file/.test(withoutComments(workflow))) fail("--changed-paths-file is local-only and must not appear in any workflow");
  return true;
}

// Module-boundary guard (PATTERNS S1). This module is a library with no CLI:
// the guard exists so that running it under `node --test` registers real,
// named fixture tests instead of one vacuous implicit test.
let invokedAsEntrypoint = false;
try {
  invokedAsEntrypoint = isMainModule(import.meta.url);
} catch {
  invokedAsEntrypoint = false;
}
if (invokedAsEntrypoint && process.env.NODE_TEST_CONTEXT) {
  test("classifyPath maps a representative path under every consumed root to the required owner", () => {
    for (const rule of CONSUMED_ROOTS) {
      const representative = rule.mode === "prefix" && rule.path.endsWith("/")
        ? `${rule.path}representative`
        : rule.path;
      assert.equal(classifyPath(representative), REQUIRED_OWNER, rule.id);
    }
  });

  test("classifyPath returns null for an unrelated path and for unsafe paths", () => {
    assert.equal(classifyPath("docs/architecture/unrelated.md"), null);
    assert.equal(classifyPath("../accrue_admin/lib/accrue_admin/copy.ex"), null);
    assert.equal(classifyPath("/etc/passwd"), null);
  });

  test("assertOwnerMap accepts the shipped roots and rejects a map missing a required root", () => {
    assert.doesNotThrow(() => assertOwnerMap(CONSUMED_ROOTS));
    assert.throws(() => assertOwnerMap(CONSUMED_ROOTS.slice(1)));
  });
}
