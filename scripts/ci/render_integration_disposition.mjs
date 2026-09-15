#!/usr/bin/env node
import fs from "node:fs";
import assert from "node:assert/strict";
import test from "node:test";
import { validateDisposition } from "./collect_integration_disposition.mjs";

const escape = (value) => String(value).replace(/[\\|`<>]/g, "\\$&").replace(/[\r\n]+/g, " ");
const order = (rows, key) => [...rows].sort((a, b) => key(a).localeCompare(key(b)));
function section(title, state, owner, command, evidence, rows = [], headings = []) {
  return ["## " + title, "", `**Fact:** ${escape(evidence)}. **State:** ${escape(state)}. **Owner:** ${escape(owner)}. **Next command:** \`${escape(command)}\`.`, "", ...headings, ...rows, ""];
}

export function renderIntegrationDisposition(disposition, { expectedRepository } = {}) {
  const value = validateDisposition(disposition, { expectedRepository });
  const ancestryRows = order(value.ancestry, (row) => row.gate).map((row) => `| ${escape(row.gate)} | ${escape(row.state)} | ${row.exit_code ?? "\u2014"} | ${escape(row.evidence)} |`);
  const postMergeRows = order(value.post_merge_commits, (row) => `${row.commit}\0${row.owner_plan}`).map((row) => `| \`${row.commit}\` | ${escape(row.reason)} | ${escape(row.owner_plan)} |`);
  const hazardRows = order(value.hazards, (row) => JSON.stringify(row)).map((row) => `| ${escape(row.class ?? "unclassified")} | ${escape(row.state ?? "unknown")} |`);
  const scope = value.scope;
  return [
    "# Integration Disposition", "",
    "Sanitized schema-v1 evidence for the reviewable v1.62 integration candidate. This is a deterministic projection: no raw payloads, actor identities, secret values, or absolute paths are present.", "",
    "## Decisions adopted silently", "",
    "This merge silently carries three decisions a reviewer should know about before approving: the release-please version line moving to **1.5.1**, the **Decimal 3 / ex_money 6** dependency migration (with Ecto 3.14), and the `:branding` `from_email`/`support_email` relaxation to optional. Hazard-level classification of each is Plan 230-03 scope.", "",
    ...section(
      "Candidate identity",
      "recorded",
      "release-engineering",
      `git rev-list --parents -n 1 ${value.candidate.ref}`,
      `merge commit ${value.candidate.object}`,
      [`| ${escape(value.candidate.ref)} | \`${value.candidate.object}\` | \`${value.candidate.tree}\` | ${escape(value.candidate.committed_at)} |`],
      ["| Ref | Object | Tree | Committed at |", "| --- | --- | --- | --- |"]
    ),
    ...section(
      "Binding",
      "recomputed",
      "release-engineering",
      "git rev-parse origin/main",
      "recomputed at collection time from live SHAs, never transcribed (D-15)",
      [
        `| origin_main | \`${value.binding.origin_main}\` |`,
        `| milestone_tip | \`${value.binding.milestone_tip}\` |`,
        `| merge_base | \`${value.binding.merge_base}\` |`
      ],
      ["| Fact | Object |", "| --- | --- |"]
    ),
    ...section(
      "D-05 ancestry gates",
      "proved",
      "release-engineering",
      "node scripts/ci/verify_integration_disposition.mjs --require-ancestry",
      "all five gates re-run live against the candidate",
      ancestryRows,
      ["| Gate | State | Exit code | Evidence |", "| --- | --- | --- | --- |"]
    ),
    ...section(
      "Changed-file and commit scope",
      "recomputed",
      "release-engineering",
      "git diff --name-only <merge-base> <candidate>",
      `${scope.total_changed_files} files changed (${scope.planning_only_changed_files} .planning/-only, ${scope.source_changed_files} source); ${scope.total_commits} commits (${scope.planning_only_commits} .planning/-only)`
    ),
    ...section(
      "Post-merge commits",
      value.post_merge_commit_count === 0 ? "none declared" : "declared",
      "release-engineering",
      `git rev-list <branch-tip> ^${value.candidate.object}`,
      `${value.post_merge_commit_count} commits declared beyond the merge commit itself`,
      postMergeRows.length ? postMergeRows : ["| (none) | \u2014 | \u2014 |"],
      ["| Commit | Reason | Owner plan |", "| --- | --- | --- |"]
    ),
    ...section(
      "Hazards",
      value.hazard_count === 0 ? "not yet classified" : "classified",
      "release-engineering",
      "node scripts/ci/collect_integration_disposition.mjs",
      `${value.hazard_count} hazard rows recorded; hazard classification is Plan 230-03 scope`,
      hazardRows.length ? hazardRows : ["| (none classified in this plan) | \u2014 |"],
      ["| Class | State |", "| --- | --- |"]
    ),
    ""
  ].join("\n");
}

function main() {
  const args = process.argv;
  const input = args[args.indexOf("--input") + 1];
  const out = args[args.indexOf("--out") + 1];
  const repository = args[args.indexOf("--expected-repository") + 1];
  if (!input || !out || !repository) throw new Error("--input, --out, and --expected-repository are required");
  fs.writeFileSync(out, renderIntegrationDisposition(JSON.parse(fs.readFileSync(input, "utf8")), { expectedRepository: repository }));
}
if (!process.env.NODE_TEST_CONTEXT && process.argv[1] === new URL(import.meta.url).pathname) {
  try { main(); } catch (error) { console.error(`integration disposition render: FAIL: ${error.message}`); process.exitCode = 1; }
}

if (process.env.NODE_TEST_CONTEXT && process.argv[1] === new URL(import.meta.url).pathname) {
  test("renders deterministic markdown for a minimal valid disposition", () => {
    const disposition = {
      schema_version: 1,
      repository: "szTheory/accrue",
      candidate: { ref: "refs/heads/integration/v1.62-candidate", object: "a".repeat(40), parents: ["b".repeat(40), "c".repeat(40)], tree: "d".repeat(40), committed_at: "2026-09-15T00:00:00+00:00" },
      ancestry: ["v1_61_identity", "v1_61_ancestor", "origin_main_ancestor", "closure_commits_ancestor", "exactly_one_new_commit"].map((gate) => ({ gate, state: "proved", exit_code: 0, evidence: "ok" })),
      scope: { total_changed_files: 1, planning_only_changed_files: 0, source_changed_files: 1, total_commits: 1, planning_only_commits: 0 },
      binding: { origin_main: "c".repeat(40), milestone_tip: "b".repeat(40), merge_base: "e".repeat(40) },
      hazards: [],
      hazard_count: 0,
      post_merge_commits: [],
      post_merge_commit_count: 0
    };
    const first = renderIntegrationDisposition(disposition, { expectedRepository: "szTheory/accrue" });
    const second = renderIntegrationDisposition(disposition, { expectedRepository: "szTheory/accrue" });
    assert.equal(first, second, "render must be deterministic");
    assert.match(first, /Decisions adopted silently/);
    assert.match(first, /v1_61_identity/);
  });
  test("rejects rendering an invalid disposition", () => {
    assert.throws(() => renderIntegrationDisposition({ schema_version: 2 }, { expectedRepository: "szTheory/accrue" }), /unsupported schema version|missing required field/);
  });
}
