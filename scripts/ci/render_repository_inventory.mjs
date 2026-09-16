#!/usr/bin/env node
import fs from "node:fs";
import assert from "node:assert/strict";
import test from "node:test";
import { isMainModule } from "./main_module.mjs";
import { createRepositoryValidationContext, validateInventory } from "./collect_repository_inventory.mjs";

const escape = (value) => String(value).replace(/[\\|`<>]/g, "\\$&").replace(/[\r\n]+/g, " ");
const order = (rows, key) => [...rows].sort((a, b) => key(a).localeCompare(key(b)));
const shellQuote = (value) => `'${String(value).replace(/'/g, `'"'"'`)}'`;
function section(title, state, owner, command, evidence, rows = [], headings = []) {
  return ["## " + title, "", `**Fact:** ${escape(evidence)}. **State:** ${escape(state)}. **Owner:** ${escape(owner)}. **Next command:** \`${escape(command)}\`.`, "", ...headings, ...rows, ""];
}
function remoteRows(remotes) {
  return order(Object.entries(remotes), ([key]) => key).flatMap(([key, value]) => {
    const provenance = key === "remote_main" ? escape(value.request) : value.requests.map(escape).join(" ; ");
    if (!value.available) return [`| ${escape(key)} | unavailable:${escape(value.reason)} | — | \`${value.observed_at}\` | ${provenance} |`];
    if (!Array.isArray(value.shas)) return [`| ${escape(key)} | observed | \`${value.sha}\` | \`${value.observed_at}\` | ${provenance} |`];
    if (value.shas.length === 0) return [`| ${escape(key)} | observed-empty | — | \`${value.observed_at}\` | ${provenance} |`];
    return [...value.shas].sort().map((sha) => `| ${escape(key)} | observed | \`${sha}\` | \`${value.observed_at}\` | ${provenance} |`);
  });
}

export function renderRepositoryInventory(inventory, validationContext) {
  const value = validateInventory(inventory, validationContext);
  const orderedRecovery = order(value.recovery.refs, (item) => `${item.original_ref}\0${item.object}\0${item.encoded_ref}`);
  const recovery = orderedRecovery.map((item) => `| ${escape(item.original_ref)} | \`${item.object}\` | ${escape(item.encoded_ref)} | yes |`);
  const refs = order(Object.entries(value.refs).filter(([name]) => name !== "all"), ([name, sha]) => `${name}\0${sha}`).map(([name, sha]) => `| ${escape(name)} | \`${sha}\` | separately named fact |`);
  const allRefs = order(value.refs.all, (item) => `${item.name}\0${item.object}`).map((item) => `| ${escape(item.name)} | \`${item.object}\` | ${escape(item.role)} |`);
  const artifacts = order(value.artifacts.entries, (item) => `${item.path}\0${item.type}\0${item.sha256}`).map((item) => `| ${escape(item.path)} | ${escape(item.type)} | \`${item.sha256}\` |`);
  const workflowMetadata = order(value.artifacts.authorized_workflow_metadata || [], (item) => `${item.path}\0${item.before_sha256}\0${item.after_sha256}`).map((item) => `| ${escape(item.path)} | ${escape(item.state)} | \`${item.before_sha256}\` | \`${item.after_sha256}\` |`);
  const worktrees = order(value.worktrees, (item) => `${item.branch}\0${item.sha}\0${item.dirty ? "1" : "0"}`).map((item) => `| ${escape(item.branch)} | \`${item.sha}\` | ${item.dirty ? "dirty" : "clean"} |`);
  const capture = [
    `| active symbolic ref | ${escape(value.capture.active_ref)} | \`${value.capture.commit}\` |`,
    `| primary worktree | ${escape(value.capture.primary_worktree.branch)} | \`${value.capture.primary_worktree.head}\` |`
  ];
  const windows = value.planning.ship_windows.length ? order(value.planning.ship_windows, String).map((item) => `| ${escape(item)} |`) : ["| (none) |"];
  const recoveryProcedure = [
    "## Recovery procedure", "",
    "Supply the private bundle location only at runtime. The following exact commands verify the bundle, fetch each actual original bundle head, and restore it with a separately quoted `git update-ref` operation.", "",
    "```sh",
    'PHASE229_BUNDLE="${PHASE229_BUNDLE:?supply the private recovery bundle path at runtime}"',
    "export PHASE229_BUNDLE",
    'git bundle verify "$PHASE229_BUNDLE"',
    ...orderedRecovery.flatMap((item) => [
      `git fetch "$PHASE229_BUNDLE" ${shellQuote(item.original_ref)}`,
      `git update-ref ${shellQuote(item.original_ref)} ${shellQuote(item.object)}`
    ]),
    "```", ""
  ];
  return [
    "# Repository Inventory", "", "Sanitized schema-v2 repository evidence. This is a deterministic projection: no raw payloads, logs, actors, secret values, content, link text, absolute paths, or external bundle locations are present.", "",
    ...section("Recovery barrier", "verified", "repository-maintainers", 'git bundle verify "$PHASE229_BUNDLE"', `private manifest SHA-256 ${value.recovery.manifest_sha256}; bundle SHA-256 ${value.recovery.bundle_sha256}`, recovery, ["| Original ref | Object | Preservation ref | Bundle member |", "| --- | --- | --- | --- |"]),
    ...recoveryProcedure,
    ...section("Named ref truth", "recorded", "release-engineering", "git show-ref --head", "all named roles retain their independent identity", refs, ["| Fact | Full object ID | Interpretation |", "| --- | --- | --- |"]),
    ...section("Captured-at authority", "point-in-time", "release-engineering", "git merge-base --is-ancestor CAPTURED LIVE", `captured at ${value.capture.captured_at}`, capture, ["| Identity | Symbolic ref | Full object ID |", "| --- | --- | --- |"]),
    ...section("All local and preservation refs", "recorded", "release-engineering", "git for-each-ref", "full object IDs are immutable evidence", allRefs.length ? allRefs : ["| (none) | — | — |"], ["| Ref | Object | Role |", "| --- | --- | --- |"]),
    ...section("Worktrees", "recorded", "repository-maintainers", "git worktree list --porcelain", "paths intentionally omitted", worktrees.length ? worktrees : ["| (none) | — | — |"], ["| Branch | Object | Classification |", "| --- | --- | --- |"]),
    ...section("User-owned artifact evidence", value.artifacts.empty_directory_policy, "repository-maintainers", "git status --porcelain=v1 --untracked-files=all", "non-dereferenced digests only", artifacts.length ? artifacts : ["| (none) | — | — |"], ["| Relative path | Type | SHA-256 or marker |", "| --- | --- | --- |"]),
    ...section("Authorized workflow metadata changes", workflowMetadata.length ? "explicit exact-path authorization" : "none", "GSD workflow", "node scripts/ci/verify_repository_inventory.mjs --require-workflow-metadata-authorization", "before/after hashes are bounded to two named GSD metadata files", workflowMetadata.length ? workflowMetadata : ["| (none) | — | — | — |"], ["| Relative path | State | Before SHA-256 | After SHA-256 |", "| --- | --- | --- | --- |"]),
    ...section("Remote, PR, release branch, and Actions observations", "explicit per row", "release-engineering", "node scripts/ci/collect_repository_inventory.mjs --observe-remote", "repository-bound GET provenance", remoteRows(value.remotes), ["| Category | State | Exact object ID | Observed at | Read-only request |", "| --- | --- | --- | --- | --- |"]),
    ...section("Ship windows and planning", "recorded", "release-engineering", "gsd_run windows status --raw", `milestone ${value.planning.milestone}; state ${value.planning.state}`, windows, ["| Ship window |", "| --- |"]),
    "## Provider-proof interpretation", "", "**Fact:** Actions conclusions are recorded separately from provider proof. **State:** `proved`, `failed`, `misconfigured`, `blocked`, `skipped`, and `non_run` are never collapsed into an Actions conclusion. **Owner:** CI maintainers. **Next command:** `node scripts/ci/ci_monitor.cjs inspect --sha FULL_SHA --repo szTheory/accrue`.", ""
  ].join("\n");
}
function main() { const args = process.argv; const input = args[args.indexOf("--input") + 1]; const out = args[args.indexOf("--out") + 1]; const repository = args[args.indexOf("--expected-repository") + 1]; if (!input || !out || !repository) throw new Error("--input, --out, and --expected-repository are required"); const context = createRepositoryValidationContext({ expectedRepository: repository }); fs.writeFileSync(out, renderRepositoryInventory(JSON.parse(fs.readFileSync(input, "utf8")), context)); }
if (!process.env.NODE_TEST_CONTEXT && isMainModule(import.meta.url)) { try { main(); } catch (error) { console.error(`repository inventory render: FAIL: ${error.message}`); process.exitCode = 1; } }

if (process.env.NODE_TEST_CONTEXT && isMainModule(import.meta.url)) {
  test("CR-04 plural remote rows retain every ordered producing request", () => {
    const repository = "szTheory/accrue";
    const observedAt = "2026-09-13T00:00:00.000Z";
    const requests = {
      pull: `GET /repos/${repository}/pulls?state=open&per_page=100&page=1`,
      release1: `GET /repos/${repository}/git/matching-refs/heads/release/?per_page=100&page=1`,
      release2: `GET /repos/${repository}/git/matching-refs/heads/release/?per_page=100&page=2`,
      actions: `GET /repos/${repository}/actions/runs?per_page=100&page=1`,
      main: `GET /repos/${repository}/git/ref/heads/main`
    };
    const rows = remoteRows({
      remote_main: { observed_at: observedAt, request: requests.main, available: true, state: "observed", sha: "a".repeat(40) },
      pull_requests: { observed_at: observedAt, requests: [requests.pull], available: true, state: "observed", shas: [] },
      release_branches: { observed_at: observedAt, requests: [requests.release1, requests.release2], available: true, state: "observed", shas: ["c".repeat(40), "b".repeat(40)] },
      actions: { observed_at: observedAt, requests: [requests.actions], available: false, state: "unavailable", reason: "network" }
    });
    assert.deepEqual(rows, [
      `| actions | unavailable:network | — | \`${observedAt}\` | ${requests.actions} |`,
      `| pull_requests | observed-empty | — | \`${observedAt}\` | ${requests.pull} |`,
      `| release_branches | observed | \`${"b".repeat(40)}\` | \`${observedAt}\` | ${requests.release1} ; ${requests.release2} |`,
      `| release_branches | observed | \`${"c".repeat(40)}\` | \`${observedAt}\` | ${requests.release1} ; ${requests.release2} |`,
      `| remote_main | observed | \`${"a".repeat(40)}\` | \`${observedAt}\` | ${requests.main} |`
    ]);
    assert.equal(rows.some((row) => row.includes("undefined")), false, "no absent provenance field is serialized");
    assert.deepEqual(remoteRows({
      pull_requests: { observed_at: observedAt, requests: [requests.pull], available: true, state: "observed", shas: ["d".repeat(40)] }
    }), [`| pull_requests | observed | \`${"d".repeat(40)}\` | \`${observedAt}\` | ${requests.pull} |`], "one-result plural evidence retains its producing request");
  });
}
