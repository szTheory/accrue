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
  "phase200-owner-contracts",
  "required-ci-workflow",
  "phase252-package-script",
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
  { id: "phase200-owner-contracts", path: "scripts/ci/verify_phase200_", mode: "prefix", owner: REQUIRED_OWNER },
  { id: "required-ci-workflow", path: ".github/workflows/ci.yml", mode: "exact", owner: REQUIRED_OWNER },
  { id: "phase252-package-script", path: "accrue_admin/package.json", mode: "exact", owner: REQUIRED_OWNER },
]);

function fail(message) {
  throw new Error(`Phase 252 CI contract: ${message}`);
}

function normalizeRepoPath(value) {
  if (typeof value !== "string" || value.length === 0 || value.includes("\0")) return null;
  const normalized = value.replaceAll("\\", "/");
  if (normalized.startsWith("/") || /^[A-Za-z]:\//.test(normalized)) return null;
  const segments = normalized.split("/");
  if (segments.some((segment) => segment === ".." || segment === "." || segment === "")) return null;
  return segments.join("/");
}

function matchesRule(repoPath, rule) {
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
  if (requirePhase252 && !ownerRunner.includes("npm --prefix accrue_admin run phase252:check")) {
    fail("required owner runner does not invoke npm --prefix accrue_admin run phase252:check");
  }
  return true;
}
