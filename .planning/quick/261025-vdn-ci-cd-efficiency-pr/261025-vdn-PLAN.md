---
phase: quick-261025-vdn
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - .planning/quick/261025-vdn-ci-cd-efficiency-pr/261025-vdn-PLAN.md
  - scripts/ci/verify_pipefail_grep_idiom.mjs
  - scripts/ci/verify_ci_setup_diagnostics.sh
  - scripts/ci/verify_admin_ui_ratchet_ci_contract.sh
  - scripts/ci/verify_phase192_ci_contract.sh
  - scripts/ci/verify_phase192_guardrail_contract.sh
  - scripts/ci/verify_phase200_ci_contract.sh
  - scripts/ci/verify_phase200_guardrail_contract.sh
  - .github/workflows/ci.yml
  - .github/workflows/accrue_admin_browser.yml
  - .github/workflows/accrue_admin_assets.yml
  - .github/workflows/accrue_admin_ratchet_live_uat.yml
  - .github/workflows/accrue_host_uat.yml
  - .github/workflows/publish-hex.yml
  - .github/workflows/release-please.yml
  - scripts/ci/verify_ci_efficiency_contract.mjs
  - scripts/ci/verify_ci_script_contract.mjs
  - scripts/ci/README.md
  - scripts/ci/prune_first_party_build.sh
  - .planning/phases/250-remote-integration/250-VERIFICATION.md
  - .planning/quick/261025-vdn-ci-cd-efficiency-pr/261025-vdn-SUMMARY.md
autonomous: true
requirements:
  - CIEFF-01-build-cache
  - CIEFF-02-concurrency
  - CIEFF-03-partition-count
  - CIEFF-04-docs-dedupe
  - CIEFF-05-needs-decision
  - CIEFF-06-timeouts
  - CIEFF-07-sha-pins
  - CIEFF-08-pipefail-heredoc-and-sl-d

# Per-task projection: T1 about 55k, T2 about 75k, T3 about 95k.
# Each task stays at or under about 10 files and under the per-task budget.
# T3 has an explicit budget exit (see its action).
estimate:
  tokens: 225000
  raw_tokens: 225000
  tasks: 3
  confidence: low

must_haves:
  truths:
    - "In the 6 target scripts there are no more `printf`/`echo` producers piped into `grep -q`/`-v` under pipefail. HEAD b4310a39 had 30 such sites, counted with the ERE gate. Narrowed SL-D reported exactly those 30 against the pre-fix tree and passes after the fix. IDIOM_ALLOWLIST stays empty."
    - "ci.yml and accrue_admin_browser.yml declare `concurrency:`. Its cancel-in-progress is true only for pull_request. main, schedule and dispatch runs get a run_id-unique group, so they are never cancelled and never replaced while pending."
    - "In both files, every job has timeout-minutes at about 2-3x its measured p50, and MIX_OS_DEPS_COMPILE_PARTITION_COUNT=4 is set workflow-wide."
    - "Every `erlef/setup-beam` use in every `.github/workflows/*.yml` file (23 uses in 7 files, including publish-hex.yml and release-please.yml, which hold HEX_API_KEY and RELEASE_PLEASE_TOKEN) is pinned to a 40-hex SHA with a `# v1.x.y` comment."
    - "ex_doc runs only in release-gate cells whose docs output can differ. The evidence that the dropped cells are exact duplicates is in the SUMMARY."
    - "Item 5 is evaluated with no edit, and its rationale is recorded."
    - "Release-gate `_build/test` (accrue, accrue_admin, accrue_portal) and the playwright shards' fixed MIX_BUILD_PATH tree are cached with split restore/save, and first-party lib dirs are pruned after restore. For each cached project, a planted first-party warning gives the same compile exit code on a pruned warm `_build` as on a cold `_build`. The path-dep outcome is recorded as measured."
    - "The PR has cold and warm runs measured against baseline 40236926623 (37.9m wall, about 164 runner-min). It is squash-merged with --match-head-commit only after 250-ci-head-status.mjs reports GREEN on the exact head."
  artifacts:
    - path: scripts/ci/verify_pipefail_grep_idiom.mjs
      provides: "SL-D with the printf/echo exemption narrowed to the `|| true` capture span only"
    - path: scripts/ci/verify_ci_efficiency_contract.mjs
      provides: "Merge-blocking shape contract: items 2, 3, 4, 6, 7 (Task 2) and item 1 (Task 3), with fixture negative controls (D-32 compliant)"
    - path: scripts/ci/prune_first_party_build.sh
      provides: "Deletes first-party app dirs from a restored _build; --self-test with a negative control"
    - path: .planning/quick/261025-vdn-ci-cd-efficiency-pr/261025-vdn-SUMMARY.md
      provides: "Cold/warm/baseline wall and runner-min; docs-dedupe evidence; item-5 decision; warm-vs-cold control matrix; cache footprint; follow-ups; human_judgment: false"
  key_links:
    - from: ".github/workflows/ci.yml docs-contracts-shift-left"
      to: "scripts/ci/verify_ci_efficiency_contract.mjs"
      via: "new merge-blocking step (node --test + --fixtures + --repo .)"
    - from: "each _build restore step (release-gate x3, playwright-e2e)"
      to: "scripts/ci/prune_first_party_build.sh"
      via: "the prune step comes immediately after restore and before the first step whose run invokes mix or a mix-calling script"
    - from: ".github/workflows/ci.yml edits"
      to: ".planning/phases/250-remote-integration/250-VERIFICATION.md covered_digest"
      via: "ci.yml is in phase 250 covered_files; SL-G --require-digest-match is red until re-minted via computeDigest"
    - from: "scripts/ci/verify_phase192_ci_contract.sh:98 and verify_phase200_ci_contract.sh:117"
      to: "pinned setup-beam form"
      via: "the needle `uses: erlef/setup-beam@v1` becomes a pinned-SHA pattern"
---

<objective>
Ship one CI/CD efficiency PR from branch `ci/efficiency` (already checked out at b4310a39). The PR must cut wall time and runner-minutes against baseline run 40236926623 (37.9m wall, about 164 runner-min) without weakening any gate. Every change carries a positive control and a negative control. Measure a cold run and a warm run, then squash-merge on an exact-head GREEN verdict.

Revision 1 re-slice:
- Task 1 is item 8 plus committing this PLAN.
- Task 2 is items 2, 3, 4, 6 and 7, plus the efficiency contract. Item 5 is recorded as a no-edit decision.
- Task 3 is item 1, the build cache, with its warm-vs-cold control, then the PR, the measurement and the merge.

Live observations at planning time. These are authoritative and supersede the task description where they differ.
- host-integration already has `needs: [docs-contracts-shift-left]` (ci.yml line 1353), not release-gate. Phase 227 decoupled it, and `newHostNeeds` in scripts/ci/verify_ci_critical_path.mjs pins that edge.
- Only admin-drift-docs still has `needs: [release-gate]` (line 812).
- The critical path is shift-left (6m) → host-integration (17m) → playwright shard (7m). Release-gate (17-18m) runs in parallel.
- `ACCRUE_CI_SIGRA`, `ACCRUE_CI_OPENTELEMETRY` and `ACCRUE_OTEL_MATRIX` are read only by `accrue/test/accrue/telemetry/otel_test.exs` and `scripts/ci/compile_matrix.sh`. accrue/mix.exs and accrue_admin/mix.exs never read them.
- ci.yml is in the `covered_files` of phase 250, the current phase. Any ci.yml edit turns SL-G red until `covered_digest` is re-minted. accrue_admin_browser.yml is not covered.
- The only third-party action is `erlef/setup-beam@v1`: 23 uses across 7 workflow files, latest release v1.24.1. Everything else is `actions/*`.
- `on.push` covers `branches: [main]` only, so a throwaway branch gets no CI without a PR. Run the warm/cold controls locally.
- SL-F scans `git ls-files '*-INTEGRATION-PR.md'`. Never commit this PR's body under that name.
- Local `grep` is ugrep, and BSD grep rejects `-P`. Gates use `grep -E` only, and treat rc>1 as failure.

Item 5 decision. This is evaluated and makes no edit; record it in the SUMMARY.
- host-integration is already release-gate-free. Keep its `docs-contracts-shift-left` edge: shift-left is the cheapest lane (6m) and the one most often red. Failing fast there protects host-integration plus 3 playwright shards, about 35 runner-min per contract-red push. The phase-227 contract also pins it.
- admin-drift-docs keeps `needs: [release-gate]`. It is off the critical path (18+3 = 21m against the 30m host chain), so dropping the edge saves no wall time and only about 3 runner-min of fail-fast.
- Revisit both edges only if the warm run in Task 3 makes release-gate → admin-drift-docs the critical path.
</objective>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@CLAUDE.md
@.github/workflows/ci.yml
@.github/workflows/accrue_admin_browser.yml
@scripts/ci/verify_pipefail_grep_idiom.mjs
@.planning/phases/250-remote-integration/250-ci-head-status.mjs

Baseline raw data: /private/tmp/claude-501/-Users-jon-projects-accrue/48422f75-2b7f-40b8-aba9-40871881caab/scratchpad/ci-efficiency/

Per-job p50 from run 40236926623, in minutes:

| Job | p50 (m) |
|---|---|
| release-gate cells | 17-18 |
| host-integration | 17 |
| browser-uat | about 13 |
| admin-hardening-guardrails | 8 |
| playwright shards | 5-7 |
| docs-contracts-shift-left | 6 |
| admin-phase200-guardrails | 6 |
| release-manifest-ssot | 5 |
| host-docker-smoke | 4 |
| phase18-tax-gate | 3 |
| admin-group-contracts | 3 |
| admin-drift-docs | 3 |
| ios / ratchet / annotation / classifier | about 0-1 |

SWEEP is the local contract sweep, run before every commit that touches workflows or scripts/ci. It covers:
- Replay every `run:` of the docs-contracts-shift-left job through a temp .sh in the scratchpad, with GITHUB_TOKEN from `gh auth token` for SL-F.
- `bash scripts/ci/verify_phase190_automation_contract.sh`
- `bash scripts/ci/verify_phase192_ci_contract.sh`
- `bash scripts/ci/verify_phase200_ci_contract.sh`
- `bash scripts/ci/verify_admin_ui_ratchet_ci_contract.sh`
- `bash scripts/ci/verify_ci_setup_diagnostics.sh`
- `node scripts/ci/verify_phase230_archive_invariants.mjs --repo .`

SL-G re-mint applies to any commit that edits ci.yml.
- In the same commit, recompute `covered_digest` in `.planning/phases/250-remote-integration/250-VERIFICATION.md`.
- Compute it through `computeDigest(repo, coveredFiles)` from scripts/ci/verify_artifact_fixed_point.mjs, with covered_files read from the file. Prefer a digest-only mode of 250-mint-close-artifacts.mjs if one exists.
- Replace only the `covered_digest:` line, and never type the value by hand.

Hard rules:
- Never force-push, and never push to main or push tags.
- No Docker locally.
- Never weaken a gate.
- Commit each verified change immediately, and never run destructive git while work is uncommitted.
- Plant probe code only in a scratch copy under the scratchpad. Copy deps/ there as real files, never symlinks.
- If a local suite needs Postgres, use the private instance on 5439 (socket /tmp/pg250s).
- Tools: `node ~/.claude/gsd-core/bin/gsd-tools.cjs query <verb>`. Add no new deps.
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Commit PLAN; narrow SL-D's printf/echo exemption; convert the 30 pipefail grep sites to here-strings</name>
  <files>.planning/quick/261025-vdn-ci-cd-efficiency-pr/261025-vdn-PLAN.md, scripts/ci/verify_pipefail_grep_idiom.mjs, scripts/ci/verify_ci_setup_diagnostics.sh, scripts/ci/verify_admin_ui_ratchet_ci_contract.sh, scripts/ci/verify_phase192_ci_contract.sh, scripts/ci/verify_phase192_guardrail_contract.sh, scripts/ci/verify_phase200_ci_contract.sh, scripts/ci/verify_phase200_guardrail_contract.sh</files>
  <read_first>scripts/ci/verify_pipefail_grep_idiom.mjs (whole file: BUILTIN_PRODUCERS, scanFile, findExemptCommandSubstitutionSpans, the fixture table, verifyFixtures); `git show 5561a9a9` (the here-string pattern); each of the six target scripts around their matching lines</read_first>
  <behavior>
    - Fixture: under `set -euo pipefail`, a printf producer piped into `grep -Fq` FAILS. This is the new negative control; before this task the shape was exempt.
    - Fixture: an echo producer piped into `grep -q` under pipefail FAILS.
    - Fixture: grep reading the variable from a `<<<` here-string PASSES.
    - Fixture: printf piped into `grep -v` inside a `$(...)` capture that ends `|| true` still PASSES. This keeps scripts/ci/verify_package_docs.sh lines 521 and 710 legal.
    - Fixture: printf piped into `grep -q` in a file WITHOUT pipefail PASSES, as before.
    - The remediation message for a builtin-producer offender names the here-string fix.
  </behavior>
  <action>Step 0. Commit this PLAN.md first, alone (`docs(quick-261025-vdn): plan`), so Task 3's clean-tree precondition holds.

Pinned-file scope check (per checker):
- "Skip any sha256-pinned script" means only a script listed in the CURRENT phase's `covered_files` (`.planning/phases/250-remote-integration/250-VERIFICATION.md`), or one named in `.planning/hygiene/*.json`.
- Archived VERIFICATION lists under `.planning/milestones/` are frozen by design and are NOT checked.
- At planning time none of the six basenames appeared in either source, so the skip set is empty. Re-run `grep -l <basename>` against those two sources and record the result.
- If a basename now matches, do NOT allowlist it, because `--require-idiom-ban` with an empty allowlist must stay meaningful. Instead, fix the file and re-mint that digest through computeDigest as described in context.

RED. In verify_pipefail_grep_idiom.mjs, stop exempting `printf`/`echo` producers. The `|| true` command-substitution span becomes the only printf/echo exemption.
- Rewrite the header's DETECTION and ALLOWLIST paragraphs to give the reason: a builtin producer is not race-free. In CI job 121312543518 a 7551-byte printf lost the SIGPIPE race in `verify_release_contract.sh` (fixed in 5561a9a9).
- Give builtin-producer offenders a here-string remediation hint.
- Add the five fixtures above.
- Run the narrowed verifier on the live tree before fixing any site. It MUST fail with exactly 30 offenders:

  | Script | Offenders |
  |---|---|
  | verify_ci_setup_diagnostics.sh | 5 |
  | verify_admin_ui_ratchet_ci_contract.sh | 4 |
  | verify_phase192_ci_contract.sh | 3 |
  | verify_phase192_guardrail_contract.sh | 5 |
  | verify_phase200_ci_contract.sh | 3 |
  | verify_phase200_guardrail_contract.sh | 10 |

  This is the positive control. Record the count in the SUMMARY.

GREEN. Convert each site to the 5561a9a9 form, with grep reading the variable from a here-string.
- Keep the original control flow, `if grep ...; then` or `grep ... ||`.
- Keep every pattern and every flag cluster byte-identical.
- If a pipeline has an intermediate external stage (printf → tr/sed/awk → grep), capture that stage into a variable first, then grep the variable from a here-string.
- Comments must not spell out the banned pipe form; cite commit 5561a9a9 instead.

Per-script controls:
- Run each of the six scripts live; each must PASS.
- In a scratch copy under the scratchpad (`git archive HEAD | tar -x`, never the live tree), delete one needle that the script requires from the file it reads. The script must exit non-zero and name that needle.

IDIOM_ALLOWLIST stays empty. Run SWEEP, then commit `fix(ci): ban builtin-producer grep -q pipelines under pipefail (SL-D)`.</action>
  <verify>
    <automated>node --test --test-reporter=tap scripts/ci/verify_pipefail_grep_idiom.mjs && node scripts/ci/verify_pipefail_grep_idiom.mjs --fixtures --require-idiom-ban && node scripts/ci/verify_pipefail_grep_idiom.mjs --repo . --require-idiom-ban && R='(^|[^[:alnum:]_])(printf|echo)[[:space:]][^|]*\|[[:space:]]*grep[[:space:]]+-[a-zA-Z]*[qv]' && for f in verify_ci_setup_diagnostics verify_admin_ui_ratchet_ci_contract verify_phase192_ci_contract verify_phase192_guardrail_contract verify_phase200_ci_contract verify_phase200_guardrail_contract; do src=$(cat "scripts/ci/$f.sh") || exit 1; body=$(grep -v '^[[:space:]]*#' <<<"$src"); rc=0; grep -nE "$R" <<<"$body" || rc=$?; if [ "$rc" -eq 0 ]; then echo "FAIL $f: builtin-producer site remains"; exit 1; elif [ "$rc" -gt 1 ]; then echo "FAIL $f: grep error rc=$rc"; exit 1; fi; bash "scripts/ci/$f.sh" || exit 1; done</automated>
  </verify>
  <fails_when>
    - Any target script still has a matching pipeline (grep rc 0).
    - The gate's grep errors (rc>1).
    - SL-D's fixtures do not fail on the builtin-producer shapes.
    - Narrowed SL-D did not report exactly 30 offenders against the pre-fix tree.
    - Any of the six scripts fails live, or passes with a needle removed.
  </fails_when>
  <done>
    - The ERE gate counts 0 sites in the six scripts. At HEAD it counted 30; this was measured with this exact ERE under ugrep.
    - The SL-D fixtures, including the 5 new ones, pass.
    - The 30 to 0 positive control is recorded.
    - All six scripts pass live and fail when a needle is removed.
    - PLAN.md and the fix are committed as two commits.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Concurrency, partition count, timeouts, setup-beam pins and docs dedupe behind a new efficiency contract (items 2, 3, 4, 6, 7)</name>
  <files>.github/workflows/ci.yml, .github/workflows/accrue_admin_browser.yml, scripts/ci/verify_ci_efficiency_contract.mjs, scripts/ci/verify_ci_script_contract.mjs, scripts/ci/verify_phase192_ci_contract.sh, scripts/ci/verify_phase200_ci_contract.sh, scripts/ci/README.md, .planning/phases/250-remote-integration/250-VERIFICATION.md</files>
  <read_first>.github/workflows/ci.yml release-gate (lines 538-756, docs steps 669-673 and 728-729); scripts/ci/verify_phase192_ci_contract.sh line 98; scripts/ci/verify_phase200_ci_contract.sh line 117; scripts/ci/verify_artifact_fixed_point.mjs (computeDigest at line 292); scripts/ci/verify_exdoc_since_badges.sh (does it read doc/?)</read_first>
  <behavior>
    verify_ci_efficiency_contract.mjs runs fixture-driven checks. Each of these mutations of a passing fixture must FAIL:
    - A job without timeout-minutes.
    - cancel-in-progress not gated to pull_request.
    - A concurrency group that is not run_id-unique for non-PR events.
    - A workflow missing `MIX_OS_DEPS_COMPILE_PARTITION_COUNT: 4`.
    - A third-party `uses:` that is not a 40-hex SHA, or lacks a `# v` comment.
    - A release-gate `mix docs` step (or a doc/-consuming step) without the keep-set `if:`.
    The live ci.yml and accrue_admin_browser.yml PASS.
  </behavior>
  <action>(a) Create the contract and wire it in first.
- Create scripts/ci/verify_ci_efficiency_contract.mjs modeled on verify_pipefail_grep_idiom.mjs:
  - import isMainModule from ./main_module.mjs;
  - register node:test tests;
  - provide `--fixtures` and `--repo .` modes (D-32);
  - parse YAML line-based by indentation (no YAML dep).
- Scope it to ci.yml and accrue_admin_browser.yml.
- Wire it into docs-contracts-shift-left after the SL-D step, as `node --test`, then `--fixtures`, then `--repo .`.
- Re-measure `git ls-files 'scripts/ci/*.mjs' | wc -l`. Raise COMMITTED_COHORT_FLOOR in verify_ci_script_contract.mjs to the new live count, with a dated re-measure note. The floor only ratchets upward.
- Add a row to scripts/ci/README.md.
- While (b) to (d) are unapplied, `--repo .` must fail; that is the RED. Commit (a) together with (b) so every commit is green.

(b) Items 2, 3 and 6, in both workflow files.

Item 2, concurrency. Add workflow-level:
- `concurrency.group: ${{ github.workflow }}-${{ github.event_name == 'pull_request' && github.ref || github.run_id }}`
- `cancel-in-progress: ${{ github.event_name == 'pull_request' }}`

Add a comment explaining why the run_id half is load-bearing. With a shared main group, a newer pending run would replace a pending push, schedule or dispatch run even with cancel-in-progress false.

Item 3, partition count. Add workflow-level `env: MIX_OS_DEPS_COMPILE_PARTITION_COUNT: 4` (ubuntu-24.04 has 4 vCPU).

Item 6, timeouts. Set timeout-minutes per job at about 2.5x p50, with a minimum of 10:

| Job | timeout-minutes |
|---|---|
| release-gate | 45 |
| host-integration | 45 |
| browser-uat | 35 |
| visual-baselines-mint | 35 |
| admin-hardening-guardrails | 20 |
| playwright-e2e | 20 |
| docs-contracts-shift-left | 15 |
| admin-phase200-guardrails | 15 |
| release-manifest-ssot | 15 |
| host-docker-smoke | 12 |
| every other job | 10 |

For live-stripe and provider-proof-incident, use the p50 of their last 5 non-skipped runs (`gh run list` / `gh run view --json jobs`). Record each source p50 in the SUMMARY.

(c) Item 7, setup-beam pins.
- Resolve v1.24.1 with `gh api repos/erlef/setup-beam/git/ref/tags/v1.24.1`. If it is an annotated tag, dereference it.
- Confirm it is the commit `v1` points to. If not, use the newest v1.x tag that `v1` does point to.
- Replace every `erlef/setup-beam@v1` in every `.github/workflows/*.yml` file (all 23 uses, 7 files) with `erlef/setup-beam@<40-hex> # v1.24.1`. Pinning the same commit is behavior-identical.
- This includes the 5 non-CI workflows (accrue_admin_assets, accrue_admin_ratchet_live_uat, accrue_host_uat, publish-hex, release-please). The highest-privilege workflows must not keep the mutable tag. These are one-line edits, and none of the 5 files is in phase 250's covered_files or has a contract needle.
- In verify_phase192_ci_contract.sh line 98 and verify_phase200_ci_contract.sh line 117, change the needle to an ERE that accepts only `erlef/setup-beam@` + 40 hex + ` # v1.`. Use a here-string (Task 1 form).
- Negative controls, run in a scratch copy: restore an unpinned `@v1`, then separately cut the SHA to 39 hex. Both contracts must FAIL on each.

(d) Item 4, docs dedupe. Gather the evidence before editing.
- (i) Re-run the static `git grep` for the three env flags.
- (ii) In a scratch copy, for accrue and accrue_admin, run `MIX_ENV=dev mix docs --warnings-as-errors` under three env sets:
  - no flags;
  - ACCRUE_CI_SIGRA=1;
  - ACCRUE_CI_OPENTELEMETRY=1 with ACCRUE_OTEL_MATRIX=with_opentelemetry.

  Clean doc/ between runs. Record the exit codes, the warning lines, and a sha256 over the sorted per-file hashes of each doc/ tree.
- (iii) Pull the docs-step log lines of all 4 release-gate cells from baseline 40236926623 (`gh run view --job <id> --log`) and compare their warnings.

Then decide which cells keep docs.
- Keep docs in the Floor cell: it runs a different Elixir version that cannot be reproduced locally.
- Keep docs in the Primary sigra=off/otel=off cell.
- Drop docs only from cells whose output is proven byte-identical to Primary off/off. The expected drops are sigra=on and otel=on.
- Gate both docs steps, and any step that reads doc/ (check verify_exdoc_since_badges.sh), with `if: matrix.sigra == 'off' && matrix.opentelemetry == 'off'`.
- If any evidence shows a difference, keep that cell and record why.

Before each commit: run SWEEP and the SL-G re-mint, then commit. The commits are (a)+(b), then (c), then (d), each green.</action>
  <verify>
    <automated>node --test --test-reporter=tap scripts/ci/verify_ci_efficiency_contract.mjs && node scripts/ci/verify_ci_efficiency_contract.mjs --fixtures && node scripts/ci/verify_ci_efficiency_contract.mjs --repo . && node scripts/ci/verify_ci_script_contract.mjs --repo . --expected-repository szTheory/accrue --require-guard-coverage --require-non-vacuity --require-cohort-floor && node scripts/ci/verify_artifact_fixed_point.mjs --repo . --require-acyclic --require-fixed-point --require-digest-match && bash scripts/ci/verify_phase192_ci_contract.sh && bash scripts/ci/verify_phase200_ci_contract.sh && bash scripts/ci/verify_ci_setup_diagnostics.sh && node scripts/ci/verify_phase230_archive_invariants.mjs --repo . && node -e 'const fs=require("fs");let all=0,pinned=0;for(const f of fs.readdirSync(".github/workflows").filter(n=>/\.ya?ml$/.test(n)).map(n=>".github/workflows/"+n)){for(const l of fs.readFileSync(f,"utf8").split("\n")){if(/uses:\s*erlef\/setup-beam@/.test(l)){all++;if(/erlef\/setup-beam@[0-9a-f]{40} # v1\.\d+\.\d+\s*$/.test(l))pinned++;}}}if(all<1||pinned!==all){console.error(`setup-beam uses=${all} pinned=${pinned}`);process.exit(1)}console.log(`setup-beam pinned ${pinned}/${all}`)'</automated>
  </verify>
  <fails_when>
    - Any efficiency-contract fixture mutation passes.
    - Live --repo fails.
    - SL-G digest mismatch.
    - The phase192/200 contracts accept an unpinned or 39-hex setup-beam.
    - Any setup-beam use in the two files is unpinned. At HEAD the pin check counts 0 pinned of 23 uses across all workflow files, so it fails at HEAD by construction.
    - A docs cell is dropped without byte-identical evidence.
  </fails_when>
  <done>
    - The contract passes live and fails on every fixture mutation.
    - The setup-beam uses in both files are pinned, and the phase192/200 needles reject the unpinned and 39-hex forms.
    - The concurrency, partition-count and timeout settings are present.
    - The docs keep-set is applied, with its evidence table saved to the scratchpad for the SUMMARY.
    - SL-G is green after the re-mint.
    - There are 3 green commits.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 3: Release-gate and playwright `_build` cache with warm-vs-cold control (item 1); then PR, cold/warm measurement, SUMMARY and exact-head squash-merge</name>
  <files>.github/workflows/ci.yml, scripts/ci/prune_first_party_build.sh, scripts/ci/verify_ci_efficiency_contract.mjs, scripts/ci/README.md, .planning/phases/250-remote-integration/250-VERIFICATION.md, .planning/quick/261025-vdn-ci-cd-efficiency-pr/261025-vdn-SUMMARY.md</files>
  <read_first>.github/workflows/ci.yml release-gate (the three `mix compile --warnings-as-errors` steps at about lines 632, 692 and 748, plus the PLT cache steps) and playwright-e2e lines 1504-1600 (fixed MIX_BUILD_PATH; explicit `Compile host` step at about line 1588); .planning/phases/250-remote-integration/250-ci-head-status.mjs header (usage, exit codes 0/1/2, D1 exclusions)</read_first>
  <precondition>`gh auth status` is logged in to szTheory/accrue. `git status --short` shows only `?? .planning/milestone.lock`, with Task 1-2 work committed.</precondition>
  <behavior>
    - prune_first_party_build.sh --self-test, positive case: on a fake `_build/test/lib` containing accrue, accrue_admin, accrue_portal, accrue_host, sigra, jason and plug, it removes exactly the first five and keeps jason and plug.
    - Self-test, missing-dir case: a missing dir exits 0 and prints "nothing restored".
    - Self-test, negative control: with the prune list emptied, the self-test assertion fails.
    - Contract extension: these fixture mutations FAIL:
      - a `_build` restore not followed by a prune step before the first step whose `run:` invokes `mix` or a scripts/ci script;
      - a save step not directly after a `mix compile --warnings-as-errors` step;
      - a key missing any of runner.os, otp, elixir, MIX_ENV, a mix.lock hashFiles, or a config/**/*.exs hashFiles;
      - a release-gate key missing matrix.sigra or matrix.opentelemetry;
      - a save path without `!` exclusions for the first-party lib dirs or `*.plt*`.
  </behavior>
  <action>Cache scope, per orchestrator direction: a smaller scope that is fully checkable. Measured rationale for the exclusions:

| Target | In scope? | Why |
|---|---|---|
| release-gate `accrue/_build/test`, `accrue_admin/_build/test`, `accrue_portal/_build/test` | Yes | About 9m of deps compile per cell, and each has an explicit compile step |
| playwright-e2e fixed `MIX_BUILD_PATH` tree (`examples/accrue_host/tmp/accrue-host-proof-playwright-shard-N/test`) | Yes | Explicit `Compile host` step |
| host-integration | No | Its compile happens inside `accrue_host_uat.sh` → `mix verify.full`, with no explicit compile step, and `verify.install` mutates the source tree. The browser proof tree is pid-random. |
| release-gate `_build/dev` | No | Compiled only by `mix docs` |
| browser-uat and the admin guardrail jobs | No | Off the critical path |

Record the excluded jobs as SUMMARY follow-ups.

(a) Create scripts/ci/prune_first_party_build.sh.
- Use `set -euo pipefail`, take `<build_env_dir>`, and support `--self-test`.
- It removes `lib/accrue`, `lib/accrue_admin`, `lib/accrue_portal`, `lib/accrue_host` and `lib/sigra` (sigra is a path dep at examples/accrue_host/mix.exs line 115), printing each removal.
- Extend verify_ci_efficiency_contract.mjs with the item-1 checks in <behavior>, plus fixtures.
- Add a README row.

(b) For each in-scope project, add three steps.

1. Restore: `actions/cache/restore@v5`, with `id: <proj>_build_cache` and this key:
   `${{ runner.os }}-<job-id>[-shard-${{ matrix.shard }}]-otp<otp>-elixir<elixir>[-sigra-${{ matrix.sigra }}-otel-${{ matrix.opentelemetry }}]-<project>-build-test-${{ hashFiles(<every mix.lock the project resolves>) }}-${{ hashFiles('<project>/config/**/*.exs') }}`
   Add a matching prefix restore-key.
2. Prune: placed IMMEDIATELY after the restore and before the first step that invokes mix. In release-gate that step is `Install accrue deps`; in playwright it is `Install host deps`.
3. Save: `actions/cache/save@v5`, placed DIRECTLY after that project's `mix compile --warnings-as-errors` step, before tests, so a later test failure still saves.
   - Condition: `if: steps.<id>.outputs.cache-hit != 'true'`.
   - Key: `${{ steps.<id>.outputs.cache-primary-key }}`.
   - Path: the env dir, plus `!` exclusions for the five first-party lib dirs and for `**/*.plt*`. In release-gate the save precedes the PLT steps anyway.

For playwright the save goes after `Compile host`. Then run SWEEP and the SL-G re-mint, and commit `ci: cache third-party _build for release-gate and playwright shards`.

(c) Warm-vs-cold control, run locally in a scratch copy with deps/ copied, never the live tree.
- For each project P in {accrue, accrue_admin, accrue_portal, examples/accrue_host}:
  1. Plant an unused variable in a first-party module of P's OWN app.
  2. COLD: `rm -rf _build` (the scratch copy's only), then `MIX_ENV=test mix compile --warnings-as-errors`. Record the rc.
  3. WARM: revert the plant, compile clean to warm `_build`, run the prune script on `_build/test`, and show lib/<P> is gone while a third-party dir remains. Re-plant and compile again; record the rc.
  4. Assert rc_warm == rc_cold != 0.
- Path-dep row, measured not assumed: plant the warning in `accrue/lib` and compile accrue_admin, accrue_portal and the host. Record rc_cold and rc_warm for each. Mix does not apply `--warnings-as-errors` to deps, so both may be 0. The required property is rc_warm == rc_cold. If they differ, STOP and fix the prune before pushing.
- Revert the plant and confirm the compile passes.
- Run `git status --short` in the live repo and confirm only intended files changed.
- Put the full rc matrix in the SUMMARY.

(d) PR.
- `git push -u origin ci/efficiency`. Never force.
- Write the PR body in the scratchpad, not under a `*-INTEGRATION-PR.md` name. It lists items 1-8, each with its controls, ends with the PR attribution line, and carries the item-5 decision.
- `gh pr create --base main --head ci/efficiency --title "ci: CI/CD efficiency (build cache, concurrency, timeouts, SHA pins, docs dedupe, pipefail)" --body-file <file>`

(e) Cold run.
- `node .planning/phases/250-remote-integration/250-ci-head-status.mjs --repo szTheory/accrue --sha <head> --event pull_request --pr-base origin/main --wait-minutes 60`
- If it is red, fix at source with a new commit, running SWEEP first, and never weaken a gate. Record whether each re-run head saw `_build` hits, from the cache-hit outputs and logs. A head with hits counts as partial-warm, not cold.

(f) Measure. Use one method for every run, and re-apply it to baseline 40236926623 from `gh run view <id> --json jobs`.
- Wall time is max(completedAt) minus min(startedAt) over non-skipped jobs.
- Runner-min is the sum of each non-skipped job's duration, in minutes.
- Report ci.yml and accrue_admin_browser.yml separately. Break out the release-gate cells, host-integration, the playwright shards and browser-uat per job.
- In one release-gate cell, time the deps-compile and docs steps from log timestamps.

(g) Warm run.
- `gh run rerun <ci_run_id>` and `gh run rerun <browser_run_id>`, as whole-workflow reruns with the same head and the same PR cache scope.
- Wait with the helper again, then measure.
- Confirm the restore steps report cache-hit=true and the prune steps print their removals.
- If the warm critical path overturns the item-5 decision, land that edge change as its own commit, with SWEEP and the re-mint, then re-measure. Otherwise keep the decision.

(h) Cache footprint.
- Run `gh cache list --key` for the new entries.
- Ceiling: the new `_build` entries total at most 3 GB of the 10 GB repo budget.
- If they exceed it, trim in this order and re-measure after each step:
  1. the advisory sigra cell's entries;
  2. the otel cell's entries;
  3. the accrue_portal entries.

(i) SUMMARY.
- Write .planning/quick/261025-vdn-ci-cd-efficiency-pr/261025-vdn-SUMMARY.md with `human_judgment: false`.
- Contents:
  - a baseline/cold/warm table (wall time and runner-min, per workflow and per key job);
  - the cache hit/miss table and footprint;
  - a note that main has zero caches until the first post-merge push seeds them;
  - the docs evidence and keep-set;
  - the item-5 decision;
  - the timeout table with its source p50s;
  - the setup-beam SHA and tag;
  - Task 1's 30 to 0 counts and its controls;
  - the warm-vs-cold rc matrix;
  - all commit SHAs.
- Next steps:
  - extend the `_build` cache to host-integration (it needs an explicit compile step or a fixed build path), browser-uat and the admin jobs;
  - post-merge STATE.md bookkeeping stays local or rides on the next PR, never a push to main.
- Commit and push. The new head runs warm; add its numbers to the SUMMARY.

Budget exit, to use only if context runs short before (b) is committed: do not half-land the cache. Drop the uncommitted cache work by editing it out (never with a destructive git command while work is uncommitted). Write the follow-up quick-task stub (scope = (a)-(c) above) into the SUMMARY's Next Steps, and continue from (d) with items 2-8 only. A cache already committed with its (c) controls stays. On this path item 1 (CIEFF-01) is reported as NOT DELIVERED, and the work is a phase split, not a completion. The SUMMARY records `status: partial` for CIEFF-01. The cache-hit success criterion and the cache-hit `<fails_when>` are explicitly replaced by: a SUMMARY Next Steps entry carrying the follow-up stub, and an unchanged cold-run timing table. Never claim the build-cache speedup on this path.

(j) Merge.
- Merge only when the helper reports GREEN (rc 0) for the exact final head, run with `--event pull_request --pr-base origin/main`. The parked `Admin UI ratchet guardrails [parked]` lane is the only exclusion.
- `gh pr merge <n> --squash --match-head-commit <head>`
- Never merge on a red head, a pending head, or a different head.
- Afterwards, with a clean tree apart from milestone.lock: `git fetch origin && git switch main && git merge --ff-only origin/main` (local ref only). Report the squash SHA.
- Never push to main or push tags.</action>
  <verify>
    <automated>bash scripts/ci/prune_first_party_build.sh --self-test && node scripts/ci/verify_ci_efficiency_contract.mjs --fixtures && node scripts/ci/verify_ci_efficiency_contract.mjs --repo . && node scripts/ci/verify_artifact_fixed_point.mjs --repo . --require-acyclic --require-fixed-point --require-digest-match && node .planning/phases/250-remote-integration/250-ci-head-status.mjs --repo szTheory/accrue --sha "$(git rev-parse ci/efficiency)" --event pull_request --pr-base origin/main && grep -q 'human_judgment: false' .planning/quick/261025-vdn-ci-cd-efficiency-pr/261025-vdn-SUMMARY.md && test "$(gh pr view ci/efficiency --json state --jq .state)" = MERGED</automated>
  </verify>
  <fails_when>
    - The prune self-test passes with an emptied prune list.
    - A cache fixture mutation passes.
    - For any project, the warm rc differs from the cold rc, or a own-app planted warning gives rc 0.
    - The warm run shows no `_build` cache-hit.
    - The cache footprint exceeds 3 GB and is untrimmed.
    - The merge happens on a head the helper did not judge GREEN.
  </fails_when>
  <done>
    - The `_build` cache is live for release-gate (3 projects) and the playwright shards, and the warm run reports hits.
    - The rc matrix shows warm == cold for every own-app and path-dep row.
    - The PR is squash-merged with --match-head-commit on a GREEN exact head.
    - The SUMMARY holds the baseline/cold/warm measurements, the footprint and the follow-ups.
    - Local main is fast-forwarded.
    - Nothing was force-pushed or pushed to main.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| GitHub Actions cache → job workspace | Restored `_build` artifacts are trusted as compiled third-party code. A poisoned or stale entry could mask first-party warnings or failures. |
| third-party action (erlef/setup-beam) → runner | Code from a mutable tag runs with the job's token. |
| PR event → concurrency group | The group expression decides which runs are cancelled. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-vdn-01 | Tampering | `_build` cache restore | high | mitigate | A prune step after every restore, together with `!` exclusions on save, keeps first-party code compiling fresh. The warm == cold rc matrix proves the cache cannot change a compile outcome, and the efficiency contract enforces prune placement. PR-scope caches cannot write main's scope. |
| T-vdn-02 | Tampering | erlef/setup-beam mutable `@v1` | medium | mitigate | Pin to a 40-hex SHA with a version comment in ci.yml and the browser workflow, enforced by the efficiency and phase192/200 contracts. The other 5 workflows are a recorded follow-up. |
| T-vdn-03 | Denial of Service | concurrency cancel on main/schedule/dispatch | high | mitigate | A run_id-unique group for non-PR events, plus a contract fixture that fails on any other shape. |
| T-vdn-04 | Repudiation | gate weakening hidden in efficiency edits | high | mitigate | Docs are dropped only on byte-identical evidence. Item 5 makes no edit. Every change has controls, and the SL-G re-mint goes through computeDigest only. |
| T-vdn-05 | Tampering | SL-D narrowing flips a gate silently | medium | mitigate | The pre-fix tree shows 30 live offenders, there are fixtures for every shape, and the allowlist is empty. |
| T-vdn-06 | Information Disclosure | cached `_build` | low | accept | Third-party lib builds carry no secrets: Stripe keys are runtime-only, and caches are repo-scoped. |
| T-vdn-SC | Tampering | npm/pip/cargo installs | low | accept | No new packages; existing lockfiles are unchanged. |
</threat_model>

<verification>
- The Task 1, 2 and 3 automated commands all pass, and SWEEP passes on the final head locally.
- 250-ci-head-status.mjs reports GREEN (rc 0) on the exact PR head before the merge.
- The SUMMARY records cold and warm measurements against baseline 40236926623.
</verification>

<success_criteria>
- Items 1-4 and 6-8 are delivered with positive and negative controls. Item 5 is decided with recorded evidence. No gate is weakened.
- The warm run shows `_build` cache hits, and wall time and runner-min fall measurably against 37.9m and about 164 runner-min.
- The PR is squash-merged on an exact-head GREEN verdict.
</success_criteria>

<output>
Create `.planning/quick/261025-vdn-ci-cd-efficiency-pr/261025-vdn-SUMMARY.md` when done
</output>
