#!/usr/bin/env node

// Phase 229 starts test-first: the production modules are intentionally absent
// until the fixture contract below is made green.
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import {
  createRepositoryValidationContext,
  validateInventory,
  collectRepositoryInventory,
  normalizeRemoteFact
} from "./collect_repository_inventory.mjs";
import { renderRepositoryInventory } from "./render_repository_inventory.mjs";

export function verifyFixtures() {
  const context = createRepositoryValidationContext({ expectedRepository: "szTheory/accrue" });
  const inventory = {
    schema_version: 2,
    repository: "szTheory/accrue",
    mode: "local_only",
    recovery: { verified: true, bundle_sha256: "a".repeat(64), refs: [{ original_ref: "refs/heads/main", object: "b".repeat(40), encoded_ref: "refs/accrue-preserve/phase-229/726566732f68656164732f6d61696e", bundle_member: true }] },
    artifacts: { empty_directory_policy: "not_surfaced_by_git", entries: [{ path: "link", type: "symlink", sha256: "d".repeat(64) }, { path: "nested/file.txt", type: "regular", sha256: "c".repeat(64) }] },
    refs: { local_main: "b".repeat(40), cached_origin_main: "b".repeat(40), milestone_branch: "b".repeat(40), v161_tag: "b".repeat(40), all: [{ name: "refs/heads/main", object: "b".repeat(40), role: "local_main" }] },
    remotes: Object.fromEntries(["remote_main", "pull_requests", "release_branches", "actions"].map((key) => [key, { repository: "szTheory/accrue", observed_at: "2026-09-13T00:00:00.000Z", request: `GET /repos/szTheory/accrue/${key}`, available: false, state: "unavailable", reason: "network" }])),
    planning: { ship_windows: [], milestone: "absent", state: "absent" },
    worktrees: [{ branch: "phase/229", sha: "b".repeat(40), dirty: false }]
  };
  const validated = validateInventory(inventory, context);
  assert.equal(renderRepositoryInventory(validated, context), renderRepositoryInventory(structuredClone(validated), context));
  const permuted = structuredClone(validated); permuted.recovery.refs.reverse(); permuted.artifacts.entries.reverse(); permuted.refs.all.reverse();
  assert.equal(renderRepositoryInventory(validated, context), renderRepositoryInventory(permuted, context), "permutations must render identical bytes");
  assert.throws(() => validateInventory({ ...inventory, actor: "forbidden" }, context), /forbidden field/);
  assert.throws(() => validateInventory({ ...inventory, artifacts: { ...inventory.artifacts, entries: [{ path: "../secret", type: "regular", sha256: "c".repeat(64) }] } }, context), /relative path/);
  const workflowMetadata = [{ path: ".planning/milestone.lock", type: "regular", before_sha256: "1".repeat(64), after_sha256: "2".repeat(64), state: "workflow_metadata_refreshed" }, { path: ".planning/state.json", type: "regular", before_sha256: "3".repeat(64), after_sha256: "4".repeat(64), state: "workflow_metadata_refreshed" }];
  assert.equal(validateInventory({ ...inventory, artifacts: { ...inventory.artifacts, authorized_workflow_metadata: workflowMetadata } }, context).artifacts.authorized_workflow_metadata.length, 2);
  assert.throws(() => validateInventory({ ...inventory, artifacts: { ...inventory.artifacts, authorized_workflow_metadata: [workflowMetadata[0]] } }, context), /two exact workflow metadata paths/);
  assert.throws(() => validateInventory({ ...inventory, remotes: {} }, context), /remote/);

  // Phase 229 complete-inventory contract: this intentionally exercises APIs
  // before they exist, so the first TDD run must fail.
  assert.equal(typeof collectRepositoryInventory, "function");
  assert.equal(typeof normalizeRemoteFact, "function");
  const remote = normalizeRemoteFact({
    repository: "szTheory/accrue", observed_at: "2026-09-13T00:00:00.000Z",
    request: "GET /repos/szTheory/accrue/git/ref/heads/main", sha: "e".repeat(40)
  }, context);
  assert.equal(remote.available, true);
  assert.throws(() => normalizeRemoteFact({ repository: "szTheory/accrue", observed_at: "bad", request: "GET /repos/szTheory/accrue/git/ref/heads/main", sha: "e".repeat(40) }, context), /observed_at/);
  const unavailable = normalizeRemoteFact({ repository: "szTheory/accrue", observed_at: "2026-09-13T00:00:00.000Z", request: "GET /repos/szTheory/accrue/git/ref/heads/main", available: false, reason: "network" }, context);
  assert.equal(unavailable.sha, undefined);
  assert.throws(() => normalizeRemoteFact({ ...unavailable, sha: "f".repeat(40) }, context), /no claimed remote value/);
  assert.equal(assertCommandProvenance(validated, context), true);
  assert.throws(() => assertCommandProvenance({ ...validated, remotes: { ...validated.remotes, actions: { ...validated.remotes.actions, request: "GET /repos/other/repo/actions" } } }, context), /provenance/);
  assert.throws(() => renderRepositoryInventory({ ...inventory, planning: { ...inventory.planning, raw_payload: "forbidden" } }, context), /forbidden field/);
  const scratch = fs.mkdtempSync(path.join(os.tmpdir(), "phase229-inventory-"));
  try {
    const source = path.join(scratch, "source.json"); const rendered = path.join(scratch, "rendered.md");
    fs.writeFileSync(source, `${JSON.stringify(validated)}\n`); fs.writeFileSync(rendered, renderRepositoryInventory(validated, context));
    assert.equal(fs.readFileSync(rendered, "utf8"), renderRepositoryInventory(JSON.parse(fs.readFileSync(source, "utf8")), context));
    assert.equal(fs.existsSync(path.join(scratch, "invalid.md")), false, "invalid input must not render output");
  } finally { fs.rmSync(scratch, { recursive: true, force: true }); }
}

function options(argv) {
  const result = new Set(); const values = {};
  for (let index = 0; index < argv.length; index += 1) {
    if (!argv[index].startsWith("--")) throw new Error(`unexpected argument: ${argv[index]}`);
    const key = argv[index].slice(2); result.add(key);
    if (!["fixtures", "require-recovery", "require-all-ref-recovery", "require-typed-artifacts", "require-local-only", "require-complete-categories", "require-edge-cases", "require-privacy-controls", "require-determinism", "require-command-provenance", "require-workflow-metadata-authorization"].includes(key)) values[key] = argv[++index];
  }
  return { flags: result, values };
}
function assertCommandProvenance(inventory, context) {
  for (const key of ["remote_main", "pull_requests", "release_branches", "actions"]) {
    const fact = inventory.remotes[key];
    if (!fact || fact.repository !== context.expectedRepository || typeof fact.observed_at !== "string" || !new RegExp(`^GET /repos/${context.expectedRepository.replace("/", "\\/")}/`).test(fact.request || "")) {
      throw new Error(`command provenance is required for ${key}`);
    }
    normalizeRemoteFact(fact, context);
  }
  return true;
}
function assertWorkflowMetadataAuthorization(inventory) {
  const changes = inventory.artifacts.authorized_workflow_metadata;
  if (!changes) throw new Error("workflow metadata authorization evidence is required");
  if (changes.length !== 2 || changes.some((change) => ![".planning/milestone.lock", ".planning/state.json"].includes(change.path))) throw new Error("workflow metadata authorization must remain exact-path bounded");
  return true;
}
async function main() {
  const parsed = options(process.argv.slice(2));
  if (parsed.flags.has("fixtures")) { verifyFixtures(); console.log("repository inventory fixtures: PASS"); return; }
  const { records, rendered, "expected-repository": expectedRepository } = parsed.values;
  if (!records || !rendered || !expectedRepository) throw new Error("--records, --rendered, and --expected-repository are required");
  const context = createRepositoryValidationContext({ expectedRepository });
  const inventory = validateInventory(JSON.parse(fs.readFileSync(records, "utf8")), context);
  if (parsed.flags.has("require-recovery") && inventory.recovery.verified !== true) throw new Error("verified recovery is required");
  if (parsed.flags.has("require-all-ref-recovery") && inventory.recovery.refs.length === 0) throw new Error("all-ref recovery is required");
  if (parsed.flags.has("require-typed-artifacts") && !inventory.artifacts.entries.every((entry) => ["regular", "symlink", "empty_directory"].includes(entry.type))) throw new Error("typed artifacts are required");
  if (parsed.flags.has("require-local-only") && inventory.mode !== "local_only") throw new Error("local-only inventory is required");
  if (parsed.flags.has("require-complete-categories") && (!inventory.refs.all || !inventory.worktrees || !inventory.planning || Object.keys(inventory.remotes).length !== 4)) throw new Error("complete categories are required");
  if (parsed.flags.has("require-edge-cases") && inventory.artifacts.empty_directory_policy !== "not_surfaced_by_git") throw new Error("edge-case policy is required");
  if (parsed.flags.has("require-command-provenance")) assertCommandProvenance(inventory, context);
  if (parsed.flags.has("require-workflow-metadata-authorization")) assertWorkflowMetadataAuthorization(inventory);
  assert.equal(fs.readFileSync(rendered, "utf8"), renderRepositoryInventory(inventory, context), "rendered Markdown must be byte-reproducible");
  console.log("repository inventory verification: PASS");
}
main().catch((error) => { console.error(`repository inventory fixtures: FAIL: ${error.message}`); process.exitCode = 1; });
