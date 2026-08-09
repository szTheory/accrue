---
phase: 225
slug: required-lane-signal-repair
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-08
---

# Phase 225 — Validation Strategy

> Per-task validation contract for trace-backed release/Admin CI repair and fresh-commit proof.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Frameworks** | ExUnit/Ecto integration tests; Playwright Test 1.59.1; shell/static contracts; GitHub CLI + `jq` for fresh Actions evidence |
| **Config files** | `accrue_admin/playwright.config.js`, `accrue/mix.exs`, `.github/workflows/ci.yml` |
| **Quick run commands** | `cd accrue && mix test test/accrue/webhook/ingest_test.exs --warnings-as-errors`; `bash scripts/ci/verify_phase192_ci_contract.sh && bash scripts/ci/verify_phase192_guardrail_contract.sh` |
| **Full local commands** | `cd accrue && mix test --warnings-as-errors`; `cd accrue_admin && npm run e2e:phase191` |
| **Phase gate** | Fresh `workflow_dispatch` run bound to the repair SHA, with three required release jobs and `Admin hardening guardrails (Phase 192)` green; advisory Sigra recorded separately |
| **Estimated feedback** | Focused checks under 60 seconds; browser/full-suite and fresh Actions proof are phase gates |

## Sampling Rate

- **After Plan 225-01 Task 1:** Run the incident-record/static triage contract.
- **After Plan 225-01 Task 2:** Run the focused webhook ExUnit file.
- **After Plan 225-01 Task 3:** Run the `COVERAGE.md` declaration contract.
- **After Plan 225-02 Task 1:** Run the Page 191 Playwright package and the source-level 5 × 2 × 21 invariant.
- **After Plan 225-02 Task 2:** Run both Phase 192 static contract scripts.
- **After Plan 225-03 Task 1:** Run focused and full local suites before any remote dispatch.
- **Phase completion:** Validate one fresh repair-SHA Actions run, required/advisory job identity, and both required Phase 192 artifacts before closing incidents.
- **Continuity:** Every task has an automated check; no three-task gap exists.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure / truthful behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------------------|-----------|-------------------|-------------|--------|
| 225-01-01 | 01 | 1 | REL-01, REL-03 | T-225-01, T-225-03 | Exactly two privacy-safe incident records expose all D-01 fields and separate required cells from advisory Sigra. | documentation/static contract | `test -f .planning/phases/225-required-lane-signal-repair/225-CI-INCIDENTS.md && test "$(rg -c '^## INC-225-' .planning/phases/225-required-lane-signal-repair/225-CI-INCIDENTS.md)" -eq 2 && rg -F '[required]' .planning/phases/225-required-lane-signal-repair/225-CI-INCIDENTS.md && rg -F 'Sigra [advisory]' .planning/phases/225-required-lane-signal-repair/225-CI-INCIDENTS.md && rg -F 'Triage: Phase 225 required-lane incidents' scripts/ci/README.md` | Created by task | pending |
| 225-01-02 | 01 | 1 | REL-01, REL-03 | T-225-02 | Event-owned webhook/job/ledger facts and same-identity duplicate rejection replace global observations without changing production code. | ExUnit/Ecto integration | `cd accrue && mix test test/accrue/webhook/ingest_test.exs --warnings-as-errors` | ✅ | pending |
| 225-01-03 | 01 | 1 | REL-01 | T-225-01 | The detector disposition is explicit and does not misrepresent first-party test/CI surfaces as a new external API integration. | documentation/static contract | `DOC=.planning/phases/225-required-lane-signal-repair/COVERAGE.md && test -s "$DOC" && rg -F 'No external API integration' "$DOC" && rg -F 'ExUnit' "$DOC" && rg -F 'Playwright' "$DOC" && rg -F 'GitHub Actions' "$DOC"` | Created by task | pending |
| 225-02-01 | 02 | 2 | REL-02 | T-225-05, T-225-06, T-225-08 | Five independently named viewport tests preserve both themes, all 21 flows, original assertions, single-worker execution, and zero retries. | Playwright browser integration + source invariant | `cd accrue_admin && npm run e2e:phase191 && test "$(rg -c 'test\\(' e2e/admin-page-flow-phase191.spec.js)" -ge 1 && rg -F 'PHASE191_VIEWPORTS' e2e/admin-page-flow-phase191.spec.js && rg -F 'PHASE191_THEMES' e2e/admin-page-flow-phase191.spec.js && rg -F 'phase191PageFlows' e2e/admin-page-flow-phase191.spec.js` | ✅ | pending |
| 225-02-02 | 02 | 2 | REL-02 | T-225-07 | Generated-evidence paths name five checked-in Phase 192 outputs and fail closed if any disappears while existing report/test-results behavior remains intact. | shell/static CI contract | `for file in final.cells.json scorecard.delta.json regressions.ndjson artifacts.manifest.json 192-SCORECARD.md; do test -e ".planning/milestones/v1.53-phases/192-idempotent-verification-sign-off/$file" || exit 1; done && bash scripts/ci/verify_phase192_ci_contract.sh && bash scripts/ci/verify_phase192_guardrail_contract.sh` | ✅ | pending |
| 225-03-01 | 03 | 3 | REL-01, REL-02, REL-03 | T-225-09, T-225-11, T-225-12 | Both repairs have focused negative controls and full local proof tied to the current repair SHA before dispatch. | ExUnit + shell contract + Playwright | `cd accrue && mix test test/accrue/webhook/ingest_test.exs --warnings-as-errors && mix test --warnings-as-errors && cd .. && bash scripts/ci/verify_phase192_ci_contract.sh && bash scripts/ci/verify_phase192_guardrail_contract.sh && cd accrue_admin && npm run e2e:phase191` | Commands/files exist | pending |
| 225-03-02 | 03 | 3 | REL-01, REL-02, REL-03 | T-225-09, T-225-10, T-225-11 | A new workflow-dispatch run is SHA-bound; exactly three non-advisory release jobs plus the stable Admin job pass; advisory Sigra and artifact evidence remain separate. | GitHub Actions metadata contract | `DOC=.planning/phases/225-required-lane-signal-repair/225-CI-INCIDENTS.md && RUN_ID=$(sed -n 's/^Fresh repair run ID: \\([0-9][0-9]*\\)$/\\1/p' "$DOC" | head -1) && REPAIR_SHA=$(sed -n 's/^Fresh repair SHA: \\([0-9a-f][0-9a-f]*\\)$/\\1/p' "$DOC" | head -1) && test -n "$RUN_ID" && test -n "$REPAIR_SHA" && gh run view "$RUN_ID" --json event,headSha,status,conclusion,jobs,url | jq -e --arg sha "$REPAIR_SHA" '.event == "workflow_dispatch" and .headSha == $sha and .status == "completed" and .conclusion == "success" and ([.jobs[] | select(.name | startswith("Release gate (")) | select((.name | contains("[advisory]")) | not)] | length == 3) and all(.jobs[] | select(.name | startswith("Release gate (")) | select((.name | contains("[advisory]")) | not); .conclusion == "success") and any(.jobs[]; .name == "Admin hardening guardrails (Phase 192)" and .conclusion == "success")'` | Produced after dispatch | pending |

## Wave 0 Requirements

- [x] Existing ExUnit, Playwright, shell-contract, GitHub CLI, and `jq` infrastructure covers every task; no test framework or package installation is needed.
- [x] Plan 225-01's tracer creates `225-CI-INCIDENTS.md` before its static contract runs.
- [x] Plan 225-01 Task 3 creates `COVERAGE.md` before its declaration contract runs.
- [x] Plan 225-02 uses the existing Page 191 spec and Phase 192 contract scripts; the five archived generated-evidence inputs already exist.

## Requirement Coverage

| Requirement | Automated coverage | Completion evidence |
|-------------|--------------------|---------------------|
| REL-01 | 225-01-01, 225-01-02, 225-01-03, 225-03-01, 225-03-02 | Two classified incidents, narrow commands, targeted/full-local proof, and fresh SHA-bound run evidence |
| REL-02 | 225-02-01, 225-02-02, 225-03-01, 225-03-02 | Bounded Admin tests, truthful artifacts, full suites, and green stable required jobs |
| REL-03 | 225-01-01, 225-01-02, 225-03-01, 225-03-02 | One normalized release incident across three required cells and separately labeled advisory Sigra |

## Manual / External Verification Boundary

No behavior is manual-only. GitHub Actions completion is external, but Plan 225-03 validates it through automated `gh`/`jq` metadata and artifact gates. Human review may inspect linked traces and reports for diagnosis; it is not accepted as a substitute for the commands above.

## Validation Sign-Off

- [x] Every planned task has a matching automated command.
- [x] Sampling continuity has no three-task verification gap.
- [x] All validation infrastructure exists or is created by the owning task before verification.
- [x] No watch-mode flags are used.
- [x] Required and advisory evidence remain machine-distinguishable.
- [x] Fresh-run proof is bound to the exact repair SHA and cannot be satisfied by a rerun.
- [x] `nyquist_compliant: true` is set.

**Approval:** ready for execution; task rows remain pending until their commands pass on the implementation commits.
