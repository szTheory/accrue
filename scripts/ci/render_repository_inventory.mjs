#!/usr/bin/env node
import fs from "node:fs";
import { createRepositoryValidationContext, validateInventory } from "./collect_repository_inventory.mjs";

const escape = (value) => String(value).replace(/[\\|`<>]/g, "\\$&").replace(/[\r\n]+/g, " ");
const order = (rows, key) => [...rows].sort((a, b) => key(a).localeCompare(key(b)));
function section(title, state, owner, command, evidence, rows = [], headings = []) {
  return ["## " + title, "", `**Fact:** ${escape(evidence)}. **State:** ${escape(state)}. **Owner:** ${escape(owner)}. **Next command:** \`${escape(command)}\`.`, "", ...headings, ...rows, ""];
}
function remoteRows(remotes) { return order(Object.entries(remotes), ([key, value]) => key).map(([key, value]) => value.available ? `| ${escape(key)} | observed | \`${value.sha}\` | \`${value.observed_at}\` | ${escape(value.request)} |` : `| ${escape(key)} | unavailable:${escape(value.reason)} | — | \`${value.observed_at}\` | ${escape(value.request)} |`); }

export function renderRepositoryInventory(inventory, validationContext) {
  const value = validateInventory(inventory, validationContext);
  const recovery = order(value.recovery.refs, (item) => item.original_ref).map((item) => `| ${escape(item.original_ref)} | \`${item.object}\` | ${escape(item.encoded_ref)} | yes |`);
  const refs = order(Object.entries(value.refs).filter(([name]) => name !== "all"), ([name]) => name).map(([name, sha]) => `| ${escape(name)} | \`${sha}\` | separately named fact |`);
  const allRefs = order(value.refs.all, (item) => `${item.name}\0${item.object}`).map((item) => `| ${escape(item.name)} | \`${item.object}\` | ${escape(item.role)} |`);
  const artifacts = order(value.artifacts.entries, (item) => `${item.path}\0${item.type}`).map((item) => `| ${escape(item.path)} | ${escape(item.type)} | \`${item.sha256}\` |`);
  const workflowMetadata = order(value.artifacts.authorized_workflow_metadata || [], (item) => item.path).map((item) => `| ${escape(item.path)} | ${escape(item.state)} | \`${item.before_sha256}\` | \`${item.after_sha256}\` |`);
  const worktrees = order(value.worktrees, (item) => `${item.branch}\0${item.sha}`).map((item) => `| ${escape(item.branch)} | \`${item.sha}\` | ${item.dirty ? "dirty" : "clean"} |`);
  const windows = value.planning.ship_windows.length ? order(value.planning.ship_windows, String).map((item) => `| ${escape(item)} |`) : ["| (none) |"];
  return [
    "# Repository Inventory", "", "Sanitized schema-v2 repository evidence. This is a deterministic projection: no raw payloads, logs, actors, secret values, content, link text, absolute paths, or external bundle locations are present.", "",
    ...section("Recovery barrier", "verified", "repository-maintainers", "PHASE229_BUNDLE=/secure/location git bundle verify \"$PHASE229_BUNDLE\"", `bundle SHA-256 ${value.recovery.bundle_sha256}`, recovery, ["| Original ref | Object | Preservation ref | Bundle member |", "| --- | --- | --- | --- |"]),
    "Restore individual refs with `git fetch \"$PHASE229_BUNDLE\" refs/accrue-preserve/phase-229/<encoded>:<original-ref>`; the external location is supplied only through `PHASE229_BUNDLE`.", "",
    ...section("Named ref truth", "recorded", "release-engineering", "git show-ref --head", "all named roles retain their independent identity", refs, ["| Fact | Full object ID | Interpretation |", "| --- | --- | --- |"]),
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
if (process.argv[1] === new URL(import.meta.url).pathname) { try { main(); } catch (error) { console.error(`repository inventory render: FAIL: ${error.message}`); process.exitCode = 1; } }
