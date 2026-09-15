#!/usr/bin/env node
import fs from "node:fs";
import assert from "node:assert/strict";
import test from "node:test";
import { validateDisposition, validateDispositionLedger, HAZARD_CLASSES } from "./collect_integration_disposition.mjs";

const escape = (value) => String(value).replace(/[\\|`<>]/g, "\\$&").replace(/[\r\n]+/g, " ");
const order = (rows, key) => [...rows].sort((a, b) => key(a).localeCompare(key(b)));
function section(title, state, owner, command, evidence, rows = [], headings = []) {
  return ["## " + title, "", `**Fact:** ${escape(evidence)}. **State:** ${escape(state)}. **Owner:** ${escape(owner)}. **Next command:** \`${escape(command)}\`.`, "", ...headings, ...rows, ""];
}

// D-39: a stable start/end HTML comment marker pair so Phase 232 can splice this
// block into the integration PR body without re-deriving the content.
export const SPLICE_START = "<!-- phase230-integration-disposition:start -->";
export const SPLICE_END = "<!-- phase230-integration-disposition:end -->";

// D-39: sort key ending in a tiebreak on the repository-relative path (and, for
// commit-bearing rows, the 40-hex object id) so rows that compare equal on class
// and state still have one specified order across re-renders.
function hazardSortKey(row) {
  return `${row.path}\0${row.evidence?.left_blob ?? ""}\0${row.evidence?.right_blob ?? ""}`;
}

export function renderIntegrationDisposition(disposition, { expectedRepository } = {}) {
  const value = validateDisposition(disposition, { expectedRepository });
  const ancestryRows = order(value.ancestry, (row) => row.gate).map((row) => `| ${escape(row.gate)} | ${escape(row.state)} | ${row.exit_code ?? "\u2014"} | ${escape(row.evidence)} |`);
  const postMergeRows = order(value.post_merge_commits, (row) => `${row.commit}\0${row.owner_plan}`).map((row) => `| \`${row.commit}\` | ${escape(row.reason)} | ${escape(row.owner_plan)} |`);
  const handoffRows = order(value.handoffs, (row) => row.item).map((row) => `| ${escape(row.item)} | ${escape(row.reason)} |`);
  const scope = value.scope;

  // Bucket every hazard row by its closed class (D-14), so a class with zero rows
  // still renders an explicit zero-count section rather than being omitted (D-39).
  const hazardsByClass = new Map([...HAZARD_CLASSES].map((cls) => [cls, []]));
  for (const row of value.hazards) hazardsByClass.get(row.class).push(row);
  for (const rows of hazardsByClass.values()) rows.sort((a, b) => hazardSortKey(a).localeCompare(hazardSortKey(b)));

  const owingClasses = [...HAZARD_CLASSES].filter((cls) => cls !== "convergent-identical");
  const owingSections = owingClasses.flatMap((cls) => {
    const rows = hazardsByClass.get(cls);
    const tableRows = rows.map((row) => `| ${escape(row.path)} | ${escape(row.state)} | ${row.exit_code ?? "\u2014"} | ${escape(row.owner)} | ${escape(JSON.stringify(row.evidence))} |`);
    return section(
      `Hazard: ${cls}`,
      rows.length ? `${rows.length} row(s) classified` : "0 rows",
      "release-engineering",
      "node scripts/ci/collect_integration_disposition.mjs",
      `${rows.length} co-touched file(s) of class ${cls}`,
      tableRows.length ? tableRows : ["| (none) | \u2014 | \u2014 | \u2014 | \u2014 |"],
      ["| Path | State | Exit code | Owner | Evidence |", "| --- | --- | --- | --- | --- |"]
    );
  });

  const laneRows = order(value.lanes, (row) => row.lane).map((row) => `| ${escape(row.lane)} | ${escape(row.state)} | ${escape(row.owner)} | \`${escape(row.command.join(" "))}\` | ${escape(row.reason)} |`);

  const convergentRows = order(hazardsByClass.get("convergent-identical"), (row) => row.path).map((row) => `| ${escape(row.path)} | \`${row.evidence.left_blob}\` | \`${row.evidence.right_blob}\` |`);

  return [
    "# Integration Disposition", "",
    "Sanitized schema-v1 evidence for the reviewable v1.62 integration candidate. This is a deterministic projection: no raw payloads, actor identities, secret values, or absolute paths are present.", "",
    SPLICE_START, "",
    "## Decisions adopted silently", "",
    "This merge silently carries three decisions a reviewer should know about before approving: the release-please version line moving to **1.5.1**, the **Decimal 3 / ex_money 6** dependency migration (with Ecto 3.14), and the `:branding` `from_email`/`support_email` relaxation to optional. Each is classified below with an evidence-backed disposition.", "",
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
      `${scope.total_changed_files} files changed (${scope.planning_only_changed_files} .planning/-only, ${scope.source_changed_files} source); ${scope.total_commits} commits (${scope.planning_only_commits} .planning/-only). integration/v1.62-candidate is the provenance branch (answers "how did this get here" -- link it, do not diff it); review/v1.62-candidate-code-only is the code-only review branch, proved byte-identical to the candidate on every non-.planning path, and answers "what source behavior changed" (diff it)`
    ),
    ...section(
      "Phase-232 handoffs (recorded, not acted on)",
      value.handoff_count === 0 ? "none recorded" : "recorded",
      "release-engineering",
      "node scripts/ci/verify_integration_disposition.mjs --require-hazard-universe",
      `${value.handoff_count} items Phase 230 records with a reason and does not act on; Phase 232 owns disposition`,
      handoffRows.length ? handoffRows : ["| (none) | — |"],
      ["| Item | Reason |", "| --- | --- |"]
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
    `Recomputed co-touched file count: **${value.co_touched_file_count}**. Every co-touched file below owes a recorded, machine-recomputable disposition; convergent-identical rows owe nothing and are collapsed last.`, "",
    ...owingSections,
    ...section(
      "Phase-231-owned lanes (D-21 boundary)",
      `${value.lane_count} lanes explicitly excluded`,
      "release-engineering",
      "node scripts/ci/verify_integration_disposition.mjs --require-hazard-universe",
      "the mechanical corollary of D-20: a check with the same result on origin/main alone belongs to Phase 231, not Phase 230",
      laneRows.length ? laneRows : ["| (none) | \u2014 | \u2014 | \u2014 | \u2014 |"],
      ["| Lane | State | Owner | Command | Reason |", "| --- | --- | --- | --- | --- |"]
    ),
    ...section(
      "Convergent-identical (owe nothing)",
      convergentRows.length ? `${convergentRows.length} row(s) proved` : "0 rows",
      "release-engineering",
      "node scripts/ci/collect_integration_disposition.mjs",
      `${convergentRows.length} co-touched file(s) blob-identical on both merge parents, proved by SHA equality`,
      convergentRows.length ? convergentRows : ["| (none) | \u2014 | \u2014 |"],
      ["| Path | Left blob | Right blob |", "| --- | --- | --- |"]
    ),
    SPLICE_END,
    ""
  ].join("\n");
}

// D-07/D-36/D-39: renders 230-DISPOSITIONS.md from 230-DISPOSITIONS.json. Same
// validate-then-render ordering and escape()/order() discipline as the disposition
// renderer above. Leads with the dispositions that change a reader's mental model
// (excluded-rejected, carried-on-candidate), then collapses the bulk of the abandoned
// line (excluded-superseded, all sharing the same wholesale-exclusion evidence) into
// one explainable group rather than dozens of individually-read rows. Every commit's
// full, unescaped, untruncated 40-hex id is rendered so `grep <sha>` finds its row.
function ledgerRowLine(row) {
  return `| \`${row.commit}\` | ${escape(row.subject)} | ${row.patch_id_occurrences_main} | ${row.patch_id_occurrences_candidate} | ${escape(row.published_elsewhere)} |`;
}

export function renderExcludedLedger(ledger, { expectedRepository } = {}) {
  const value = validateDispositionLedger(ledger, { expectedRepository });
  const rejected = order(value.rows.filter((row) => row.disposition === "excluded-rejected"), (row) => row.commit);
  const carried = order(value.rows.filter((row) => row.disposition === "carried-on-candidate"), (row) => row.commit);
  const superseded = order(value.rows.filter((row) => row.disposition === "excluded-superseded"), (row) => row.commit);
  const rowHeadings = ["| Commit | Subject | Patch-id occurrences (main) | Patch-id occurrences (candidate) | Published elsewhere |", "| --- | --- | --- | --- | --- |"];

  const sharedEvidence = value.rows[0]?.supersession_evidence ?? null;
  const treeRows = sharedEvidence ? order(sharedEvidence.tree_level.files, (row) => row.path).map((row) => `| ${escape(row.path)} | ${row.exists_on_candidate} | ${escape(row.superseded_by_path ?? "—")} |`) : [];
  const reqRows = sharedEvidence ? order(sharedEvidence.requirement_level.requirements, (row) => row.id).map((row) => `| ${escape(row.id)} | ${escape(row.matched_text)} |`) : [];

  const pr = value.pr_44;
  const matchedRows = order(pr.matched_commits, (row) => row.pr_branch_commit).map((row) => `| \`${row.pr_branch_commit}\` | \`${row.milestone_commit}\` | \`${row.patch_id}\` |`);

  return [
    "# Excluded-Commit Ledger", "",
    "Answers \"where did commit X go?\" for every commit reachable from local `main` and not reachable from the reviewable v1.62 integration candidate. `grep` any 40-hex commit id below and its row is the answer -- no session memory required.", "",
    `Candidate: \`${escape(value.candidate.ref)}\` @ \`${value.candidate.object}\` (committed ${escape(value.candidate.committed_at)}). Local main: \`${value.local_main}\`. Recomputed excluded-commit count: **${value.excluded_commit_count}**.`, "",
    ...section(
      "Rejected salvage (excluded-rejected)",
      `${rejected.length} row(s)`,
      "release-engineering",
      "node scripts/ci/verify_integration_disposition.mjs --require-excluded-ledger",
      "landing these commits would put two competing baseline contracts on main and resurrect a rejected shell verifier as a live gate (D-08)",
      rejected.length ? rejected.map(ledgerRowLine) : ["| (none) | — | — | — | — |"],
      rowHeadings
    ),
    ...section(
      "Carried on candidate (carried-on-candidate)",
      `${carried.length} row(s)`,
      "release-engineering",
      "git merge-base --is-ancestor <commit> <candidate>",
      "already present on the candidate; recorded so nobody re-cherry-picks it (D-12)",
      carried.length ? carried.map(ledgerRowLine) : ["| (none) | — | — | — | — |"],
      rowHeadings
    ),
    ...section(
      "Superseded, collapsed (excluded-superseded)",
      `${superseded.length} row(s), one shared supersession proof`,
      "release-engineering",
      "node scripts/ci/collect_integration_disposition.mjs",
      "excluded wholesale (D-07): the abandoned line's entire unique non-planning surface is superseded, proved once below and shared by every row in this section",
      superseded.length ? superseded.map(ledgerRowLine) : ["| (none) | — | — | — | — |"],
      rowHeadings
    ),
    ...section(
      "Shared supersession evidence",
      "proved",
      "release-engineering",
      "git cat-file -e <candidate>:<path>",
      "tree-level file-existence sweep plus the BASE-01/BASE-02 requirement-level completion citation, shared by every excluded-superseded and carried-on-candidate row above",
      [
        "**Tree level:**", "",
        "| Path | Exists on candidate | Superseded by |", "| --- | --- | --- |",
        ...treeRows, "",
        sharedEvidence ? `Plan inventory: abandoned line reached plan ${sharedEvidence.tree_level.plan_inventory.abandoned_line_max_plan}, milestone line reached plan ${sharedEvidence.tree_level.plan_inventory.milestone_line_max_plan}.` : "(no rows to prove)",
        "",
        "**Requirement level:**", "",
        `File: \`${sharedEvidence ? escape(sharedEvidence.requirement_level.file) : "—"}\``, "",
        "| Requirement | Matched text |", "| --- | --- |",
        ...reqRows
      ]
    ),
    ...section(
      "PR #44 disposition",
      pr.disposition,
      "release-engineering",
      "gh pr view 44",
      `head \`${pr.head_ref}\` @ \`${pr.head_object}\` is base \`${pr.base_ref}\` @ \`${pr.base_object}\` plus ${pr.ahead_of_base} commit(s), ${pr.behind_base} behind; state=${pr.state}, mergeable=${pr.mergeable}`,
      [
        escape(pr.note), "",
        "| PR-branch commit | Milestone-branch commit | Patch id |", "| --- | --- | --- |",
        ...matchedRows
      ]
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
  // Bug fix (230-06): when --ledger-input/--ledger-out are both absent,
  // `args[args.indexOf(flag) + 1]` previously resolved to `args[0]` (the node
  // executable path) for both, which is truthy and made this branch attempt
  // to JSON.parse the node binary itself. Gate on explicit presence instead.
  const ledgerInput = args.includes("--ledger-input") ? args[args.indexOf("--ledger-input") + 1] : undefined;
  const ledgerOut = args.includes("--ledger-out") ? args[args.indexOf("--ledger-out") + 1] : undefined;
  if (ledgerInput && ledgerOut) {
    fs.writeFileSync(ledgerOut, renderExcludedLedger(JSON.parse(fs.readFileSync(ledgerInput, "utf8")), { expectedRepository: repository }));
  }
}
if (!process.env.NODE_TEST_CONTEXT && process.argv[1] === new URL(import.meta.url).pathname) {
  try { main(); } catch (error) { console.error(`integration disposition render: FAIL: ${error.message}`); process.exitCode = 1; }
}

if (process.env.NODE_TEST_CONTEXT && process.argv[1] === new URL(import.meta.url).pathname) {
  function laneRow(lane, overrides = {}) {
    return { lane, state: "non_run", owner: "231", command: ["mix", "test"], reason: "belongs to Phase 231", ...overrides };
  }
  function minimalDisposition(overrides = {}) {
    return {
      schema_version: 1,
      repository: "szTheory/accrue",
      candidate: { ref: "refs/heads/integration/v1.62-candidate", object: "a".repeat(40), parents: ["b".repeat(40), "c".repeat(40)], tree: "d".repeat(40), committed_at: "2026-09-15T00:00:00+00:00" },
      ancestry: ["v1_61_identity", "v1_61_ancestor", "origin_main_ancestor", "closure_commits_ancestor", "exactly_one_new_commit"].map((gate) => ({ gate, state: "proved", exit_code: 0, evidence: "ok" })),
      scope: { total_changed_files: 1, planning_only_changed_files: 0, source_changed_files: 1, total_commits: 1, planning_only_commits: 0 },
      binding: { origin_main: "c".repeat(40), milestone_tip: "b".repeat(40), merge_base: "e".repeat(40) },
      co_touched_file_count: 0,
      hazards: [],
      hazard_count: 0,
      lanes: [],
      lane_count: 0,
      post_merge_commits: [],
      post_merge_commit_count: 0,
      handoffs: [],
      handoff_count: 0,
      ...overrides
    };
  }

  test("renders deterministic markdown for a minimal valid disposition", () => {
    const disposition = minimalDisposition();
    const first = renderIntegrationDisposition(disposition, { expectedRepository: "szTheory/accrue" });
    const second = renderIntegrationDisposition(disposition, { expectedRepository: "szTheory/accrue" });
    assert.equal(first, second, "render must be deterministic");
    assert.match(first, /Decisions adopted silently/);
    assert.match(first, /v1_61_identity/);
  });

  test("rejects rendering an invalid disposition", () => {
    assert.throws(() => renderIntegrationDisposition({ schema_version: 2 }, { expectedRepository: "szTheory/accrue" }), /unsupported schema version|missing required field/);
  });

  test("the first ## heading is decisions-adopted-silently and the last ## heading is convergent-identical", () => {
    const rendered = renderIntegrationDisposition(minimalDisposition(), { expectedRepository: "szTheory/accrue" });
    const headings = rendered.split("\n").filter((line) => line.startsWith("## "));
    assert.equal(headings[0], "## Decisions adopted silently");
    assert.equal(headings[headings.length - 1], "## Convergent-identical (owe nothing)");
  });

  test("fences the rendered disposition with a stable phase-230 splice marker pair", () => {
    const rendered = renderIntegrationDisposition(minimalDisposition(), { expectedRepository: "szTheory/accrue" });
    assert.match(rendered, /<!-- phase230-integration-disposition:start -->/);
    assert.match(rendered, /<!-- phase230-integration-disposition:end -->/);
    assert.ok(rendered.indexOf(SPLICE_START) < rendered.indexOf(SPLICE_END), "start marker must precede end marker");
  });

  test("a hazard class with zero rows renders an explicit zero-count heading", () => {
    const rendered = renderIntegrationDisposition(minimalDisposition(), { expectedRepository: "szTheory/accrue" });
    assert.match(rendered, /## Hazard: schema-relaxation[\s\S]*?0 rows/);
  });

  test("shuffling the input hazard/lane row order and re-rendering produces identical output", () => {
    const hazards = [
      { path: "b.md", class: "doc-rewrite", state: "advisory", evidence: { command: ["git", "diff"] }, owner: "230-03" },
      { path: "a.exs", class: "dependency-lock-drift", state: "non_run", evidence: { command: ["mix", "deps.get"], note: "x" }, owner: "230-05" },
      { path: "z.exs", class: "convergent-identical", state: "proved", exit_code: 0, evidence: { left_blob: "1".repeat(40), right_blob: "1".repeat(40), command: ["git", "rev-parse"] }, owner: "230-03" }
    ];
    const lanes = [laneRow("github-actions-dispatch"), laneRow("full-mix-test"), laneRow("dialyzer-plt")];
    const forward = minimalDisposition({ co_touched_file_count: hazards.length, hazards, hazard_count: hazards.length, lanes, lane_count: lanes.length });
    const shuffled = minimalDisposition({ co_touched_file_count: hazards.length, hazards: [...hazards].reverse(), hazard_count: hazards.length, lanes: [...lanes].reverse(), lane_count: lanes.length });
    assert.equal(
      renderIntegrationDisposition(forward, { expectedRepository: "szTheory/accrue" }),
      renderIntegrationDisposition(shuffled, { expectedRepository: "szTheory/accrue" })
    );
  });

  // ===================================================================================
  // renderExcludedLedger (D-07/D-36/D-39)
  // ===================================================================================

  function ledgerRow(commit, overrides = {}) {
    return {
      commit,
      subject: `subject for ${commit.slice(0, 7)}`,
      disposition: "excluded-superseded",
      superseded_by: "no-equivalent",
      supersession_evidence: {
        tree_level: {
          command: ["git", "cat-file", "-e"],
          files: [
            { path: "scripts/ci/capture_ci_baseline.sh", exists_on_candidate: false, superseded_by_path: "scripts/ci/collect_ci_baseline.mjs" },
            { path: "scripts/ci/verify_ci_baseline_contract.sh", exists_on_candidate: false, superseded_by_path: "scripts/ci/verify_ci_baseline.mjs" },
            { path: "scripts/ci/ci_baseline_workflow_policy.json", exists_on_candidate: false, superseded_by_path: null }
          ],
          plan_inventory: { command: ["git", "ls-tree", "-r", "--name-only"], abandoned_line_max_plan: 11, milestone_line_max_plan: 21 }
        },
        requirement_level: {
          command: ["git", "show"],
          file: ".planning/milestones/v1.61-REQUIREMENTS.md",
          requirements: [
            { id: "BASE-01", matched_text: "| BASE-01 | Phase 226 | Complete |" },
            { id: "BASE-02", matched_text: "| BASE-02 | Phase 226 | Complete |" }
          ]
        }
      },
      patch_id_occurrences_main: 1,
      patch_id_occurrences_candidate: 0,
      published_elsewhere: "none",
      ...overrides
    };
  }

  function minimalLedger(rows, overrides = {}) {
    return {
      schema_version: 1,
      repository: "szTheory/accrue",
      candidate: { ref: "refs/heads/integration/v1.62-candidate", object: "a".repeat(40), committed_at: "2026-09-15T00:00:00+00:00" },
      local_main: "b".repeat(40),
      excluded_commit_count: rows.filter((row) => row.disposition !== "carried-on-candidate").length,
      rows,
      pr_44: {
        number: 44,
        head_ref: "fix/release-boot-env-resolver",
        head_object: "c".repeat(40),
        base_ref: "main",
        base_object: "b".repeat(40),
        state: "open",
        mergeable: "MERGEABLE",
        ahead_of_base: 4,
        behind_base: 0,
        matched_commits: [{ pr_branch_commit: "d".repeat(40), milestone_commit: "e".repeat(40), patch_id: "f".repeat(40) }],
        disposition: "close-unmerged-cite-superseding",
        note: "close unmerged, citing superseding SHAs"
      },
      ...overrides
    };
  }

  test("renders deterministic markdown for a minimal valid ledger", () => {
    const ledger = minimalLedger([ledgerRow("1".repeat(40))]);
    const first = renderExcludedLedger(ledger, { expectedRepository: "szTheory/accrue" });
    const second = renderExcludedLedger(ledger, { expectedRepository: "szTheory/accrue" });
    assert.equal(first, second, "render must be deterministic");
  });

  test("every row's full 40-hex commit id is rendered verbatim and greppable", () => {
    const rows = [
      ledgerRow("1".repeat(40), { disposition: "excluded-rejected" }),
      ledgerRow("2".repeat(40), { disposition: "carried-on-candidate", superseded_by: ["2".repeat(40)] }),
      ledgerRow("3".repeat(40))
    ];
    const rendered = renderExcludedLedger(minimalLedger(rows), { expectedRepository: "szTheory/accrue" });
    for (const row of rows) assert.ok(rendered.includes(row.commit), `expected ${row.commit} to appear verbatim`);
  });

  test("published_elsewhere renders prominently for a row that carries it", () => {
    const rows = [ledgerRow("4".repeat(40), { published_elsewhere: "origin/phase-226-baseline-5da8e6b88735" })];
    const rendered = renderExcludedLedger(minimalLedger(rows), { expectedRepository: "szTheory/accrue" });
    assert.match(rendered, /origin\/phase-226-baseline-5da8e6b88735/);
  });

  test("excluded-rejected and carried-on-candidate sections precede the excluded-superseded section", () => {
    const rendered = renderExcludedLedger(minimalLedger([ledgerRow("5".repeat(40))]), { expectedRepository: "szTheory/accrue" });
    const headings = rendered.split("\n").filter((line) => line.startsWith("## "));
    assert.deepEqual(headings, [
      "## Rejected salvage (excluded-rejected)",
      "## Carried on candidate (carried-on-candidate)",
      "## Superseded, collapsed (excluded-superseded)",
      "## Shared supersession evidence",
      "## PR #44 disposition"
    ]);
  });

  test("re-running the renderer over the committed JSON produces byte-identical output regardless of input row order", () => {
    const rows = [
      ledgerRow("6".repeat(40), { disposition: "excluded-rejected" }),
      ledgerRow("7".repeat(40)),
      ledgerRow("8".repeat(40), { disposition: "carried-on-candidate", superseded_by: ["8".repeat(40)] })
    ];
    const forward = minimalLedger(rows);
    const shuffled = minimalLedger([...rows].reverse());
    assert.equal(
      renderExcludedLedger(forward, { expectedRepository: "szTheory/accrue" }),
      renderExcludedLedger(shuffled, { expectedRepository: "szTheory/accrue" })
    );
  });

  test("rejects rendering an invalid ledger", () => {
    assert.throws(() => renderExcludedLedger({ schema_version: 2 }, { expectedRepository: "szTheory/accrue" }), /unsupported schema version|missing required field/);
  });
}
