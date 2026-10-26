---
phase: quick-261025-vdn
plan: 01
subsystem: infra
tags: [ci, github-actions, cache, concurrency, setup-beam, exdoc, pipefail]
status: complete
human_judgment: false
requires: []
provides:
  - "Third-party _build cache for release-gate (accrue, accrue_admin, accrue_portal) and the playwright-e2e shard trees, pruned after every restore"
  - "PR-only cancellation concurrency; MIX_OS_DEPS_COMPILE_PARTITION_COUNT=4; per-job timeouts"
  - "erlef/setup-beam SHA-pinned in all 23 uses across 7 workflow files"
  - "release-gate docs keep-set (Floor + Primary off/off)"
  - "SL-D without the printf/echo exemption; 30 sites converted to here-strings"
  - "Merge-blocking verify_ci_efficiency_contract.mjs + prune_first_party_build.sh --self-test"
affects: [ci, release-gate, playwright-e2e, browser-uat]
actuals:
  tokens: 24600   # chars/4 over the realized diff b42eeb4c..671f02d8 (98465 chars)
  tasks: 3
  commits: 6      # git rev-list --count b4310a39..671f02d8, measured before this SUMMARY commit
plan_head_before: b4310a3937c5449ae5557c565d6403511ae715ad
plan_head_after: 671f02d83143807e4ed5f26788549e53ab70383b
tech-stack:
  added: []
  patterns:
    - "Split actions/cache restore/save for _build with a prune step right after restore and ! exclusions on save"
    - "Line-based workflow shape contract with a fixture mutation per rule (D-32)"
key-files:
  created:
    - scripts/ci/verify_ci_efficiency_contract.mjs
    - scripts/ci/prune_first_party_build.sh
  modified:
    - .github/workflows/ci.yml
    - .github/workflows/accrue_admin_browser.yml
    - .github/workflows/accrue_admin_assets.yml
    - .github/workflows/accrue_admin_ratchet_live_uat.yml
    - .github/workflows/accrue_host_uat.yml
    - .github/workflows/publish-hex.yml
    - .github/workflows/release-please.yml
    - scripts/ci/verify_pipefail_grep_idiom.mjs
    - scripts/ci/verify_ci_setup_diagnostics.sh
    - scripts/ci/verify_admin_ui_ratchet_ci_contract.sh
    - scripts/ci/verify_phase192_ci_contract.sh
    - scripts/ci/verify_phase192_guardrail_contract.sh
    - scripts/ci/verify_phase200_ci_contract.sh
    - scripts/ci/verify_phase200_guardrail_contract.sh
    - scripts/ci/verify_ci_script_contract.mjs
    - scripts/ci/README.md
    - .planning/phases/250-remote-integration/250-VERIFICATION.md
key-decisions:
  - "Item 5 (needs: edges) evaluated with no edit: host-integration keeps docs-contracts-shift-left, admin-drift-docs keeps release-gate; the warm critical path confirmed the decision"
  - "_build cache key puts the config hash before the mix.lock hash; the prefix restore-key stops after the config hash, so a fallback restore can cross a mix.lock change but never a config change"
  - "Docs keep-set = Floor + Primary sigra=off/otel=off; sigra=on and otel=on dropped on semantic-identity evidence"
  - "setup-beam pinned to 54075bcc5e249e4758d363f27d099f55d843f124 (v1.24.1, the commit v1 points to) in every workflow file, including publish-hex.yml and release-please.yml"
requirements-completed: [CIEFF-01-build-cache, CIEFF-02-concurrency, CIEFF-03-partition-count, CIEFF-04-docs-dedupe, CIEFF-05-needs-decision, CIEFF-06-timeouts, CIEFF-07-sha-pins, CIEFF-08-pipefail-heredoc-and-sl-d]
completed: 2026-10-26
---

# Quick 261025-vdn: CI/CD efficiency PR Summary

**This PR cuts the CI workflow from 37.9m wall and 151.2 runner-min to 21.1m and 87.6 runner-min warm. The gains come from a pruned third-party `_build` cache, deps compile partitioning, docs dedupe, PR-only cancellation, per-job timeouts and SHA-pinned setup-beam. Every change is shape-pinned by a new merge-blocking contract with a negative control per rule.**

PR: https://github.com/szTheory/accrue/pull/52 (branch `ci/efficiency`).

## Measurements

All runs use one method, re-applied to the baseline:
- Wall time is max(completedAt) minus min(startedAt) over non-skipped jobs.
- Runner-min is the sum of non-skipped job durations.

The baseline is run 40236926623 (CI) plus 40236926603 (browser). Cold is head `671f02d8` attempt 1, with no `_build` entries (all misses). Warm is the whole-workflow rerun of the same runs (attempt 2), with every `_build` restore hitting.

| Workflow / job | Baseline | Cold | Warm |
|---|---|---|---|
| **CI wall** | 37.9m | 26.4m | 21.1m |
| **CI runner-min** | 151.2 | 120.5 | 87.6 |
| **Browser UAT (wall = runner-min)** | 12.7 | 18.4 | 18.3 |
| **Combined runner-min** | 163.9 | 138.9 | 105.9 |
| Release gate Floor | 18.8 | 12.6 | 7.0 |
| Release gate Primary off/off | 17.3 | 14.6 | 8.3 |
| Release gate Primary otel=on | 17.5 | 9.7 | 4.3 |
| Release gate Primary sigra=on [advisory] | 18.4 | 10.1 | 3.3 |
| Host integration | 17.3 | 14.9 | 11.2 |
| Playwright shards 1/2/3 | 7.1 / 5.6 / 5.3 | 6.1 / 5.6 / 5.0 | 4.3 / 2.9 / 3.1 |
| Docs and bash contracts (shift-left) | 6.5 | 5.2 | 5.2 |

Notes on the table:
- **Browser UAT.** The baseline's 12.7m is a fast outlier. The last 8 successful browser runs took 12.7-20.1m, and their "Run browser UAT" step took 9.6-14.9m. This PR does not cache browser-uat (see follow-ups). Its 18.3m falls within the observed range, and it runs in parallel off the CI critical path.
- **Host integration.** This job is not cached. Its 17.3 → 14.9 → 11.2 drop comes from the partition count plus runner variance.

Release-gate Primary off/off step timings (from step timestamps):

| Step | Baseline | Cold | Warm |
|---|---|---|---|
| Accrue compile | 2.6m | 1.9m | 0.2m |
| Accrue admin compile | 3.1m | 2.4m | 0.4m |
| Accrue portal compile | 2.7m | 2.1m | 0.2m |
| Accrue docs | 2.6m | 2.0m | 1.9m |
| Accrue admin docs | 2.8m | 2.2m | 2.1m |

In warm cells, the docs time is a `_build/dev` deps compile (see follow-ups).

The warm critical path is shift-left (5.2m) → host-integration (11.2m) → playwright (4.3m), about 21m. Release-gate → admin-drift-docs is 8.3 + 1.8 = 10.1m. This does not overturn the item-5 decision, so no edge changed.

A new head also ran warm. Head `e853e754` (this SUMMARY's first commit) ran CI 40272153004 and browser 40272153003. They were the first runs on a new SHA, and they hit the PR-scope caches that 671f02d8 seeded:

| Workflow / job | Head e853e754 (warm, new SHA) |
|---|---|
| CI wall / runner-min | 22.8m / 87.5 |
| Browser UAT | 15.1m |
| Combined runner-min | 102.6 |
| Release gate Floor / Primary off-off / otel=on / sigra=on | 6.1 / 5.9 / 3.1 / 4.3 |
| Host integration | 14.5 |
| Playwright shards 1/2/3 | 4.0 / 3.6 / 3.1 |

`250-ci-head-status.mjs --event pull_request --pr-base origin/main` was GREEN at e853e754.

## Cache hit/miss and footprint

| Attempt | Job | `_build` hits | misses | saved | prune removals |
|---|---|---|---|---|---|
| cold | each of the 4 release-gate cells | 0 | 3 | 3 | 0 (3x "nothing restored") |
| cold | each of the 3 playwright shards | 0 | 1 | 1 | 0 (1x "nothing restored") |
| warm | each of the 4 release-gate cells | 3 | 0 | 0 (exact hit, save skipped) | 5 per cell |
| warm | each of the 3 playwright shards | 1 | 0 | 0 | 5 per shard |

The warm logs also show first-party code compiling fresh after the prune. For example, release-gate Primary printed `Compiling 282 files (.ex)` / `Generated accrue app`, and the playwright shards regenerated accrue, accrue_admin, accrue_portal and accrue_host.

Footprint and scope:
- **Size.** `gh cache list` shows 15 new `-build-test-cfg` entries totalling **506 MiB**, against the 3 GB ceiling, so no trim was needed. The repo total is 1.32 GiB across 77 entries.
- **Scope.** All entries are scoped to `refs/pull/52/merge`. **Main has zero `_build` caches until the first post-merge push seeds them.** The first main push run is cold, and later main and PR runs are warm.

## Item 1: warm-vs-cold control (CIEFF-01)

This control ran locally in a scratch copy (`git ls-files` tar plus real-file `deps/` copies, 0 symlinks), with MIX_ENV=test and Elixir 1.19.5 / OTP 28. The plant is a new module with an unused variable in each project's own app.

| Project | Row | rc_cold | rc_warm | Prune evidence | Verdict |
|---|---|---|---|---|---|
| accrue | own-app | 1 (warning printed) | 1 (warning printed) | lib/accrue gone, jason kept | PASS |
| accrue_admin | own-app | 1 | 1 | lib/accrue_admin gone, jason kept | PASS |
| accrue_admin | path-dep (plant in accrue/lib) | 0 (warned) | 0 (warned) | — | PASS (equal) |
| accrue_portal | own-app | 1 | 1 | lib/accrue_portal gone, jason kept | PASS |
| accrue_portal | path-dep | 0 | 0 | — | PASS (equal) |
| examples/accrue_host | own-app | 1 | 1 | lib/accrue_host gone, jason kept | PASS |
| examples/accrue_host | path-dep | 0 | 0 | — | PASS (equal) |
| all | revert, clean compile | 0 | — | — | PASS |

Path-dep rows give rc 0 because Mix does not apply `--warnings-as-errors` to deps. The required property is rc_warm == rc_cold, and it holds for every row.

A discrimination probe was also run (accrue). It compiled the plant without `-Werr` so it was cached, then ran `--warnings-as-errors` on an *unpruned* warm `_build`. The result was rc 1, the same as pruned. Elixir 1.19's Mix re-reports stored warnings, so no local scenario was found where the cache changes a compile outcome even without the prune. The prune is therefore defense-in-depth against Mix staleness edge cases, not a demonstrated fix.

The controls on the cache itself:
- **Prune self-test.** `prune_first_party_build.sh --self-test` covers the positive case (removes the 5 first-party dirs and keeps jason and plug) and the missing-dir case. Its negative control empties the prune list, and the same assertion then fails. A copy with `FIRST_PARTY_APPS=()` makes the self-test exit 1.
- **Contract fixtures.** 12 cache fixture mutations fail:
  - a missing prune, or a prune of the wrong dir;
  - a save not right after a `--warnings-as-errors` compile;
  - a save without the cache-hit guard, or with a foreign key;
  - the combined `actions/cache`;
  - a key missing runner.os, OTP, Elixir, MIX_ENV, mix.lock or config;
  - a key missing matrix.sigra, matrix.opentelemetry or matrix.shard;
  - a path missing a first-party or PLT `!` exclusion;
  - restore/save path drift;
  - a missing expected restore.

## Item 2-3, 6: concurrency, partition count, timeouts

- **Concurrency.** Both workflows use `group: ${{ github.workflow }}-${{ github.event_name == 'pull_request' && github.ref || github.run_id }}` with `cancel-in-progress: ${{ github.event_name == 'pull_request' }}`. Fixtures fail on an ungated cancel, a missing cancel, a group without run_id, and a missing block.
- **Partition count.** `MIX_OS_DEPS_COMPILE_PARTITION_COUNT: 4` is set workflow-wide. Fixtures fail when it is missing, when it is set to 2, and on a job-level override.
- **Timeouts.** These were set at about 2.5x p50 from baseline 40236926623, with a minimum of 10. Fixtures fail on a missing timeout and on values outside [10, 60].

| Job | Source p50 | timeout-minutes |
|---|---|---|
| release-gate | 17.3-18.8 | 45 |
| host-integration | 17.3 | 45 |
| browser-uat | 12.7 (history 12.7-20.1) | 35 |
| visual-baselines-mint | (dispatch-only, same shape as browser-uat) | 35 |
| admin-hardening-guardrails | 8.6 | 20 |
| playwright-e2e | 5.3-7.1 | 20 |
| docs-contracts-shift-left | 6.5 | 15 |
| admin-phase200-guardrails | 6.8 | 15 |
| release-manifest-ssot | 5.3 | 15 |
| host-docker-smoke | 4.7 | 12 |
| phase18-tax-gate | 3.2 | 10 |
| admin-group-contracts | 3.7 | 10 |
| admin-drift-docs | 3.7 | 10 |
| ios-offline-client | 0.8 | 10 |
| admin-ui-ratchet-selftests / -guardrails, annotation-sweep | 0.2 | 10 |
| provider-proof-trigger | 0.2 (runs 40257272946..39378999100) | 10 |
| live-stripe | p50 3.7 of last 5 non-skipped (3.9, 3.1, 3.9, 3.7, 2.8; runs 40247684345, 40168207009, 40069197912, 39910095851, 39732472050) | 10 |
| provider-proof-incident | p50 0.2 of last 5 non-skipped (runs 40247684345..39732472050) | 10 |

## Item 4: docs dedupe evidence and keep-set

- **(i) Static grep.** `ACCRUE_CI_SIGRA`, `ACCRUE_CI_OPENTELEMETRY` and `ACCRUE_OTEL_MATRIX` appear only in ci.yml, `accrue/test/accrue/telemetry/otel_test.exs` and `scripts/ci/compile_matrix.sh`. No mix.exs or config reads them.
- **(ii) Local `MIX_ENV=dev mix docs --warnings-as-errors`.** This ran in a scratch copy under off, sigra and otel, plus an off repeat as the determinism control. Every run gave rc 0, with 673 files (accrue) and 177 files (accrue_admin).
  - Raw trees differ between any two runs, including off vs off-repeat. The causes are Makeup's random `data-group-id`, ExDoc's run-dependent JSON key order in `search_data-<hash>.js`, and the epub uuid and timestamp.
  - After normalizing only those, every set has the same semantic tree hash: accrue `9058f12e3583fac8` and accrue_admin `fbaedc0f04c20778` for off, sigra, otel and off_repeat.
  - The comparator's positive controls hold. Accrue vs admin differs, and a planted one-word edit to `Accrue.Billable.html` is detected.
  - Warning lines appear only on the first (deps-compiling) run, and are the same set as in CI.
- **(iii) Baseline 40236926623 docs-step logs.** After stripping timestamps, the warning sets are identical in all 4 cells: accrue `bb24aec59b492eea` (10 lines) and accrue_admin `d889810489fea9a2` (13 lines). The full step logs differ only in the echoed env lines and one compile-timing line ("taking more than 10s").
- **Keep-set.** Floor and Primary sigra=off/otel=off keep docs. Floor keeps them because it runs a different Elixir version that cannot be reproduced locally. The `if: matrix.sigra == 'off' && matrix.opentelemetry == 'off'` guard is on `Accrue docs`, `Verify ExDoc @doc since: badges` (it reads `accrue/doc/`) and `Accrue admin docs`. The sigra=on and otel=on cells drop about 4.2m each.
- **Fixtures.** These fail on a docs step without the `if:`, a doc/-reader without it, a weaker `if:`, a missing `mix docs` step, and fewer than 2 off/off cells.

Raw evidence (scratchpad): `docs_evidence_table.md`, `doc_compare2.jsonl`, `docs_log_compare.tsv`, `docs_log_normalized.txt`.

## Item 5: needs: edges (no edit)

- host-integration keeps `needs: [docs-contracts-shift-left]`. Shift-left is the cheapest lane and the one most often red. Failing fast there protects host-integration plus 3 playwright shards, about 35 runner-min per contract-red push. Phase 227's `newHostNeeds` also pins this edge.
- admin-drift-docs keeps `needs: [release-gate]`. Warm, it finishes at about 10m, against the 21m host chain, so dropping the edge saves no wall time.
- The warm run did not make release-gate → admin-drift-docs critical, so the decision stands.

## Item 7: setup-beam pin

- `erlef/setup-beam@54075bcc5e249e4758d363f27d099f55d843f124 # v1.24.1`.
  - `refs/tags/v1.24.1` is a lightweight tag pointing to that commit.
  - `refs/tags/v1` is an annotated tag `0f75c294…` that dereferences to the same commit, so behavior is identical.
- Count: 23 of 23 uses are pinned across 7 files (accrue_admin_assets, accrue_admin_browser, accrue_admin_ratchet_live_uat, accrue_host_uat, ci, publish-hex, release-please). At HEAD b4310a39 the count was 0 of 23.
- Controls:
  - The efficiency contract scans every `.github/workflows/*.yml` file and fails on `@v1`, a 39-hex SHA, and a missing or non-`# vX.Y.Z` comment.
  - The phase192 and phase200 CI contracts now require `uses: erlef/setup-beam@[0-9a-f]{40} # v1\.[0-9]+\.[0-9]+$` and reject `erlef/setup-beam@v[0-9]`.
  - In a scratch copy, the phase192, phase200 and efficiency contracts each fail on an unpinned `@v1` and on a 39-hex SHA.

## Item 8: SL-D narrowing (30 → 0)

- **Scope check.** None of the six basenames, nor the SL-D script, appears in phase 250's `covered_files` or in `.planning/hygiene/*.json`. A positive control confirmed the grep can hit: `ci.yml` and `verify_release_contract.sh` are found. The skip set is empty.
- **Before the fix.** Narrowed SL-D on the pre-fix tree reported **exactly 30 offenders**: verify_ci_setup_diagnostics 5, verify_admin_ui_ratchet_ci_contract 4, verify_phase192_ci_contract 3, verify_phase192_guardrail_contract 5, verify_phase200_ci_contract 3, verify_phase200_guardrail_contract 10.
  - Reaching 30 required one detector fix (Rule 1). `! printf … | grep -Fq …` (a bare negation, with no `if`) was invisible to producer extraction. Without the fix the count was 29.
- **After the fix.** The ERE gate counts 0 sites (grep rc 1 in each script). SL-D `--repo . --require-idiom-ban` passes: 57 files, 27 pipelines, 0 offenders. IDIOM_ALLOWLIST stays empty.
- **Fixtures.** Six new fixtures run, for 18 scenarios total:
  - printf, echo and bare-negated pipelines fail;
  - here-string, a `$(printf…|grep -v…|| true)` capture, and printf without pipefail pass.
- **Per-script controls.** All six scripts pass live. Each fails, naming the needle, when a scratch copy removes one required needle:
  - setup_diagnostics `id: host_setup_summary`;
  - ratchet `npm run ratchet:ci-contract`;
  - 192-ci `phase192-admin-playwright-report`;
  - 192-guardrail `component_registry_test.exs`;
  - 200-ci `name: Phase 200 CI contract`;
  - 200-guardrail `theme_test.exs`.

## SWEEP and SL-G

- SWEEP passed before every commit that touched workflows or scripts/ci (all 50 shift-left steps plus the six extra contracts, 0 failures).
  - The replayer's positive control: a synthetic job with a failing step and a `false | true` pipeline under pipefail reports 2 failures.
- **SL-G.** Each commit that edits ci.yml re-mints `250-VERIFICATION.md` `covered_digest` through `scanArtifact` + `computeDigest`, replacing only that line. SL-G was red before each re-mint (shown at 8be29354) and green after.

## Commits

| Commit | Message |
|---|---|
| b42eeb4c | docs(quick-261025-vdn): plan |
| 5e98e69c | fix(ci): ban builtin-producer grep -q pipelines under pipefail (SL-D) |
| 8be29354 | ci: PR-only cancellation, deps partition count, per-job timeouts |
| 49d61475 | ci: pin erlef/setup-beam to the v1.24.1 commit SHA in every workflow |
| a11989c9 | ci: build release-gate docs only in the sigra=off/otel=off cells |
| 671f02d8 | ci: cache third-party _build for release-gate and playwright shards |

## Deviations from Plan

1. **[Rule 1 - Bug] SL-D missed bare-negated pipelines.**
   - **Found during:** Task 1.
   - **Issue:** `LEADING_KEYWORD_PATTERN` stripped `if !` but not a bare `!`, so `! printf … | grep -Fq` had no producer. With it missing, the narrowed count was 29, not 30.
   - **Fix:** An optional keyword followed by an optional `!`, plus a fixture. Commit 5e98e69c.
2. **[Rule 2 - Correctness] Cache key order.**
   - **Found during:** Task 3.
   - **Issue:** The plan's key template puts the mix.lock hash before the config hash. A prefix restore-key could then restore a `_build` across a config change.
   - **Fix:** The key is `…-build-${{ env.MIX_ENV }}-cfg<config hash>-lock<lock hash>`, and the restore-key stops after `-lock`. The contract checks presence, not order. Commit 671f02d8.
3. **[Rule 2 - Strengthening] The pin check covers every workflow file.** The plan scoped the contract to two files. The third-party pin check scans all `.github/workflows/*.yml`, because publish-hex.yml and release-please.yml hold the highest-privilege tokens. Commit 49d61475.
4. **[Rule 2 - Strengthening] The prune self-test is merge-blocking.** `prune_first_party_build.sh --self-test` was added to the shift-left efficiency step. Commit 671f02d8.
5. **Docs evidence uses a semantic, not byte, comparison.** ExDoc output is not byte-reproducible run to run, even under the same env. The evidence therefore normalizes only the sources shown to vary between two identical-env runs, and proves the comparator detects a one-word edit.

## Next Steps (follow-ups)

- Extend the `_build` cache to:
  - **host-integration**, which needs an explicit compile step or a fixed build path; today the compile happens inside `mix verify.full`, and `verify.install` mutates the tree;
  - **browser-uat**;
  - the **admin guardrail jobs**;
  - release-gate **`_build/dev`**, where warm docs time is about 2m per project, all of it deps compile for ExDoc.
- Post-merge STATE.md bookkeeping beyond this branch stays local or rides on the next PR, never a direct push to main.

## Known Stubs

None.

## Self-Check: PASSED

- Files: scripts/ci/verify_ci_efficiency_contract.mjs, scripts/ci/prune_first_party_build.sh and this SUMMARY exist.
- Commits: b42eeb4c, 5e98e69c, 8be29354, 49d61475, a11989c9 and 671f02d8 are ancestors of HEAD.
- Head 671f02d8: `250-ci-head-status.mjs --event pull_request --pr-base origin/main` was GREEN on both attempt 1 (cold) and attempt 2 (warm). The parked ratchet lane was the only exclusion.

## Post-merge: main push RED, and the timeout fix

PR #52 was squash-merged as `f10249085d07c18f871e24a30e89450a1dceb94d` on an exact-head GREEN at 233da24e. The first main push run, CI 40276194774, was then judged by `250-ci-head-status.mjs --event push --baseline-run 40257272946`, and it was **RED**:

- `Admin group contracts (Phase 190)` was **cancelled** at 10.2m by its new `timeout-minutes: 10`. The cause was `Install Chromium` running more than 8 minutes. That step normally takes 0-4.2m, and the job normally takes 4.7m p50 and 5.6m max.
- `Annotation sweep` then failed downstream.

This is a defect in item 6. The timeouts came from one PR run's p50. A 15-run sample across PR and push events (n per job 11-54) gives higher numbers for the Chromium-installing admin jobs:

| Job | p50 | max |
|---|---|---|
| Admin Phase 200 | 9.7 | 14.2 |
| Admin hardening | 9.8 | 12.9 |
| Admin group contracts | 4.7 | 5.6 |
| Browser UAT | — | up to 20.1 |

The Phase 200 max sits under its 15-minute timeout by only 0.8 minutes.

The fix sets each timeout to at least max(2.5 x p50, 2 x the observed max, 10), rounded up to 5:

| Job | Old | New |
|---|---|---|
| admin-group-contracts | 10 | 20 |
| admin-hardening-guardrails | 20 | 30 |
| admin-phase200-guardrails | 15 | 30 |
| browser-uat | 35 | 45 |
| visual-baselines-mint | 35 | 45 |

Every other job already meets that rule: release-gate 45 vs max 27.9, host-integration 45 vs 17.6, playwright 20 vs 7.1, shift-left 15 vs 6.5, release-manifest 15 vs 6.7, host-docker-smoke 12 vs 5.4, phase18 10 vs 3.5, ios 10 vs 1.5, admin-drift-docs 10 vs 3.8.
