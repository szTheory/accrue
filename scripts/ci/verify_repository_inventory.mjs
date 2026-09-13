#!/usr/bin/env node

// Phase 229 starts test-first: the production modules are intentionally absent
// until the fixture contract below is made green.
import assert from "node:assert/strict";
import fs from "node:fs";
import { createRepositoryValidationContext, validateInventory } from "./collect_repository_inventory.mjs";
import { renderRepositoryInventory } from "./render_repository_inventory.mjs";

export function verifyFixtures() {
  const context = createRepositoryValidationContext({ expectedRepository: "szTheory/accrue" });
  const inventory = {
    schema_version: 1,
    repository: "szTheory/accrue",
    mode: "local_only",
    recovery: { verified: true, bundle_sha256: "a".repeat(64), refs: [{ original_ref: "refs/heads/main", object: "b".repeat(40), encoded_ref: "refs/accrue-preserve/phase-229/726566732f68656164732f6d61696e", bundle_member: true }] },
    artifacts: { empty_directory_policy: "not_surfaced_by_git", entries: [{ path: "link", type: "symlink", sha256: "d".repeat(64) }, { path: "nested/file.txt", type: "regular", sha256: "c".repeat(64) }] },
    refs: { local_main: "b".repeat(40), cached_origin_main: "b".repeat(40), milestone_branch: "b".repeat(40), v161_tag: "b".repeat(40) },
    remotes: { available: false, state: "unavailable" }
  };
  const validated = validateInventory(inventory, context);
  assert.equal(renderRepositoryInventory(validated, context), renderRepositoryInventory(structuredClone(validated), context));
  assert.throws(() => validateInventory({ ...inventory, actor: "forbidden" }, context), /forbidden field/);
  assert.throws(() => validateInventory({ ...inventory, artifacts: { ...inventory.artifacts, entries: [{ path: "../secret", type: "regular", sha256: "c".repeat(64) }] } }, context), /relative path/);
  assert.throws(() => validateInventory({ ...inventory, remotes: { available: true, state: "unavailable" } }, context), /remote/);
}

function options(argv) {
  const result = new Set(); const values = {};
  for (let index = 0; index < argv.length; index += 1) {
    if (!argv[index].startsWith("--")) throw new Error(`unexpected argument: ${argv[index]}`);
    const key = argv[index].slice(2); result.add(key);
    if (!["fixtures", "require-recovery", "require-all-ref-recovery", "require-typed-artifacts", "require-local-only"].includes(key)) values[key] = argv[++index];
  }
  return { flags: result, values };
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
  assert.equal(fs.readFileSync(rendered, "utf8"), renderRepositoryInventory(inventory, context), "rendered Markdown must be byte-reproducible");
  console.log("repository inventory verification: PASS");
}
main().catch((error) => { console.error(`repository inventory fixtures: FAIL: ${error.message}`); process.exitCode = 1; });
