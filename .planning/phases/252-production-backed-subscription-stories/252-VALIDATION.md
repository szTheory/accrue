---
phase: "252"
slug: "production-backed-subscription-stories"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-26"
---

# Phase 252 — Validation Strategy

> Executed task map for eight plans / five waves. All 17 tasks and ten requirements have automated coverage in the passing 18-command aggregate. Planning-era commands below are retained; the executed map records the authoritative lane IDs and command corrections.

## Test Infrastructure

| Property | Value |
|---|---|
| Framework | ExUnit, installed Playwright Test 1.59.1, Node node:test |
| Config files | accrue_admin/mix.exs; accrue_admin/config/test.exs; accrue_admin/playwright.config.js |
| Quick existing command | `cd accrue_admin && mix test test/accrue_admin/dev/storybook_coverage_test.exs` |
| Full existing owner command | `cd accrue_admin && npm run phase200:guardrails` |
| Full phase command | `npm --prefix accrue_admin run phase252:check` — NEW target created by 252-08-02; guarded infrastructure created in 252-03 |
| Runtime | Measure cold bootstrap separately from warm checks; budgets remain provisional until measured |

## Sampling Rate

- After every task: smallest relevant pure ExUnit or Node contract; every task has automated verification with stated failure signal.
- After each plan wave: relevant Repo/browser/production-boundary integration commands after DB, port and process preflight.
- Before phase verification: focused phase252 suite and existing required owner checks, generated automated UAT, no manual confirmation substitute.
- Fast feedback target: under 60 seconds where feasible; browser integration target under 3 minutes warm, CI incremental target under 5 minutes. Measure rather than assert.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---|---|---|---|---|---|---|---|---|---|
| 252-01-01 | 252-01 | 1 | SBK-02, SBK-03, SCEN-01 | T-252-01, T-252-02 | Actual active declared story data reaches the same production summary/facts/actions function. | DB-free ExUnit | `cd accrue_admin && MIX_ENV=test mix run --no-start test/accrue_admin/dev/subscription_story_slice_test.exs` | Confirmed in executed source | pass |
| 252-01-02 | 252-01 | 1 | SBK-02, SBK-03, SCEN-01 | T-252-01, T-252-02 | Exact UI-SPEC names appear once for both Change actions. | DB-free ExUnit | `cd accrue_admin && MIX_ENV=test mix run --no-start test/accrue_admin/components/subscription_area_test.exs` | Confirmed in executed source | pass |
| 252-02-01 | 252-02 | 2 | SCEN-01, SCEN-02, SBK-03 | T-252-03, T-252-04 | Both adopter situations use one factual source and real domain validators. | DB-free ExUnit | `cd accrue_admin && MIX_ENV=test mix run --no-start test/accrue_admin/dev/subscription_scenarios_test.exs` | Confirmed in executed source | pass |
| 252-02-02 | 252-02 | 2 | SCEN-01, SCEN-02, SBK-03 | T-252-03, T-252-04 | Three canonical variation IDs exist and render through the shared owner. | DB-free ExUnit | `cd accrue_admin && MIX_ENV=test mix run --no-start test/accrue_admin/components/subscription_area_test.exs && MIX_ENV=test mix run --no-start test/accrue_admin/dev/subscription_story_slice_test.exs` | Confirmed in executed source | pass |
| 252-03-01 | 252-03 | 2 | LAB-01, SCEN-04 | T-252-05, T-252-06, T-252-07 | CLI exists before later plans invoke it. | Node + DB/process integration | `node --test scripts/dev/phase252_lab.test.mjs` | Confirmed in executed source | pass |
| 252-03-02 | 252-03 | 2 | LAB-01, SCEN-04 | T-252-05, T-252-06, T-252-07 | Reset isolation is measured with real database writes and reloads, not configuration text. | Node + DB/process integration | `node --test scripts/dev/phase252_lab.test.mjs scripts/dev/phase252_isolation.test.mjs` | Confirmed in executed source | pass |
| 252-04-01 | 252-04 | 3 | SCEN-03, SCEN-04, SCEN-01 | T-252-08, T-252-09, T-252-10 | Both launch/team persisted graphs match the one source. | Repo/seed integration | `node scripts/dev/phase252_lab.mjs exec --lane admin-test -- mix test test/accrue_admin/dev/subscription_scenario_repo_test.exs` | Confirmed in executed source | pass |
| 252-04-02 | 252-04 | 3 | SCEN-03, SCEN-04, SCEN-01 | T-252-08, T-252-09, T-252-10 | Story/test/seed adapters share semantic facts while database writing stays local. | Repo/seed integration | `node scripts/dev/phase252_lab.mjs exec --lane host-heldout -- mix test test/accrue_host/phase252_scenario_cleanup_test.exs && node --test scripts/ci/phase248_heldout_isolation.test.mjs` | Confirmed in executed source | pass |
| 252-05-01 | 252-05 | 3 | SBK-01, SBK-02 | T-252-11, T-252-12 | Backend declarations are the single discovery owner. | DB-free ExUnit | `cd accrue_admin && MIX_ENV=test mix run --no-start test/accrue_admin/dev/subscription_manifest_test.exs` | Confirmed in executed source | pass |
| 252-05-02 | 252-05 | 3 | SBK-01, SBK-02 | T-252-11, T-252-12 | A reviewer can follow the full production composition chain and see uncovered/N/A states. | DB-free ExUnit | `cd accrue_admin && MIX_ENV=test mix run --no-start test/accrue_admin/dev/subscription_manifest_test.exs` | Confirmed in executed source | pass |
| 252-06-01 | 252-06 | 4 | SBK-02, SBK-03, SCEN-04 | T-252-13, T-252-14 | Twelve separately identified canonical cases prove both themes and exact widths. | Playwright + regression | `node scripts/dev/phase252_lab.mjs browser --spec e2e/subscription-stories-phase252.spec.js` | Confirmed in executed source | pass |
| 252-06-02 | 252-06 | 4 | SBK-02, SBK-03, SCEN-04 | T-252-13, T-252-14 | All twenty approved UI predicates have explicit test/evidence references. | Playwright + regression | `node scripts/dev/phase252_lab.mjs browser --spec e2e/subscription-stories-phase252.spec.js && node scripts/dev/phase252_lab.mjs exec --lane admin-test -- mix test test/accrue_admin/live/subscription_live_test.exs` | Confirmed in executed source | pass |
| 252-07-01 | 252-07 | 4 | LAB-02 | T-252-15, T-252-16 | Dev-positive/prod-negative assertions use real route tables. | route/compile/package | `node scripts/dev/phase252_lab.mjs exec --lane admin-test -- mix test test/accrue_admin/dev/storybook_asset_test.exs test/accrue_admin/dev/subscription_production_boundary_test.exs test/accrue_admin/dev/component_registry_test.exs test/accrue_admin/dev/component_group_registry_test.exs` | Confirmed in executed source | pass |
| 252-07-02 | 252-07 | 4 | LAB-02 | T-252-15, T-252-16 | Actual fresh prod artifacts compile separately from test outputs. | route/compile/package | `node --test scripts/ci/verify_phase252_production_boundary.test.mjs && node scripts/ci/verify_phase252_production_boundary.mjs` | Confirmed in executed source | pass |
| 252-08-01 | 252-08 | 5 | CIQ-01, SBK-01, SBK-02, SBK-03, SCEN-01, SCEN-02, SCEN-03, SCEN-04, LAB-01, LAB-02 | T-252-17, T-252-18 | All consumed categories have positive single-path controls. | Node/CI + integration | `node --test scripts/ci/verify_phase252_ci_contract.test.mjs` | Confirmed in executed source | pass |
| 252-08-02 | 252-08 | 5 | CIQ-01, SBK-01, SBK-02, SBK-03, SCEN-01, SCEN-02, SCEN-03, SCEN-04, LAB-01, LAB-02 | T-252-17, T-252-18 | The exact complete phase command is executed by the existing required owner. | Node/CI + integration | `node --test scripts/ci/verify_phase252_ci_contract.test.mjs && bash scripts/ci/verify_phase200_guardrail_contract.sh && npm --prefix accrue_admin run phase252:check` | Confirmed in executed source | pass |
| 252-08-03 | 252-08 | 5 | CIQ-01, SBK-01, SBK-02, SBK-03, SCEN-01, SCEN-02, SCEN-03, SCEN-04, LAB-01, LAB-02 | T-252-17, T-252-18 | Generated automated UAT covers actual assertion evidence for every acceptance item. | Node/CI + integration | `node --test scripts/ci/generate_phase252_acceptance.test.mjs scripts/ci/verify_phase252_ci_contract.test.mjs && npm --prefix accrue_admin run phase252:check` | Confirmed in executed source | pass |

## Wave 0 Requirements

- Add pure facts/validator tests and explicit invalid controls with implementation task; do not add vacuous stubs as acceptance evidence.
- Add focused Repo adapter, exact-child cleanup preservation, two-namespace reset, occupied-port/server refusal tests.
- Add backend-generated actual variation manifest, direct browser route and viewport/theme proof.
- Add prod compile/package/route boundary and CI admission/classifier contracts, including known-negative fixtures.
- Existing frameworks suffice; no dependency installation campaign.

## Manual-Only Verifications

All phase acceptance behaviors have automated verification. Design quality claims are bounded; static rendering does not prove persistence, mounted authorization, provider effects or aesthetic excellence.

## Validation Sign-Off

- [x] Final task map matches PLAN files and names concrete executable commands
- [x] All 17 tasks have automated verification and immediately following fails_when signals
- [x] New test references are created by their owning tasks or explicit dependencies before invocation
- [x] No watch-mode flags or owner manual-UAT gates
- [x] Every absence assertion plans a positive or violation control
- [x] Sampling continuity and execution evidence checked against the complete current aggregate
- [x] nyquist_compliant set after current aggregate and acceptance-validator checks

Approval: planning contract approved 2026-10-26 after independent recheck; 8 plans / 17 tasks / 10 requirements covered. Execution evidence and Nyquist completion were verified on 2026-10-27; historical planning/probe notes below retain their original scope.

## Planning Validation and Probe Accounting

- Eight PLAN frontmatter validations and eight plan-structure validations pass with no errors or warnings; every file ends with `</output>` and has no write-continuation sentinel. This is plan validity, not application behavior evidence.
- Waves: 1 = 01; 2 = 02/03; 3 = 04/05; 4 = 06/07; 5 = 08. Same-wave plans have no file ownership overlap. All ten requirement IDs occur in plan frontmatter. Calibration reports factor 1, sample_count 0 and confidence low.
- Existing command/package/source paths were checked with `git ls-files`; new target paths are explicitly created by their owning tasks. Pure tests use self-starting ExUnit scripts through `mix run --no-start` because the existing shared test helper always starts/migrates Repo. All DB/browser targets use the guarded launcher created in 252-03, with fresh numeric partitions compatible with the current host authority guard.
- Edge probe: 17 surfaced items = 13 classified explicit acceptance truths plus four unclassified unresolved flagged assumptions (SBK-03, SCEN-01, LAB-02, CIQ-01). Their concrete behavior coverage is assigned explicitly in 01/06, 02/04/07, 07 and 08 respectively. No silent drops and no backstop claims.
- UI probe: all 20 E1/E2/E3 predicates are present in 252-06 must_haves and receive assertion/evidence mapping. Twelve canonical state/width/theme cases remain separately identified.
- Prohibition recall retained two bespoke transparency items using the actual `projectProhibitions` serializer. Both remain descriptor-less, unresolved and flagged-unverified in 01/04; no check descriptor or green probe verdict was fabricated. Generic security/privacy-law canon is referred to the security owner, rather than minted as bespoke prohibitions.
- API coverage detector examined the full nonempty phase section plus eight plans: detected false (exit 1 is the detector's real negative verdict). No external integration matrix is required. Assumption-delta detector: detected false. Schema-push hook: none of its ORM file patterns is introduced or modified; existing Ecto migrations are applied only in disposable verification lanes. ASVS L1; high/critical open threats block.
- No application tests, package builds, browser cases, DB writes or phase acceptance generators ran during planning. `wave_0_complete` and behavior statuses remain false/pending. Final automated UAT, committed SUMMARY coverage with `human_judgment: false`, and `VERIFICATION.md` with `status: passed` / `behavior_unverified: 0` are execution outputs, not prewritten planning evidence.

## Revision 1 Disposition

- Research resolution blocker: all three research questions are marked RESOLVED with the selected facts path `dev_support/ui_scenarios/cadence_subscriptions.exs`, unconditional required owner `admin-phase200-guardrails` (the narrower Browser UAT workflow is not assigned ownership), and private temporary ownership manifest/namespace-lock contract from 252-03-01. Original repository evidence remains recorded.
- Scope warning: 252-03-02 owns all guide documentation, including the final `npm --prefix accrue_admin run phase252:check` invocation, availability after 252-08 and evidence/cost limits. 252-08-03 reads and contract-tests guide agreement with mutation controls; it does not modify the guide. Plan 252-08 now owns nine files. Eight plans, seventeen tasks, five waves and existing dependencies remain unchanged.
- Threat-register warning: numbered threats T-252-01 through T-252-18 remain unique phase-wide. Preserve reserved T-252-SC in every plan per `$HOME/.codex/agents/gsd-planner.toml:366` and `gsd-core/references/planner-gap-closure.md:64`; `gsd-core/workflows/plan-phase.md` threat-ID uniqueness rule explicitly excludes the reserved SC row from duplicate detection. The checker warning for repeated SC is a false positive under that authoritative exception, not a missing mitigation or a decision conflict.
- Revision verification: frontmatter schema and plan structure pass for modified plans 252-03 and 252-08 with zero errors/warnings. Current-tree consistency assertions pass for all eight plans/seventeen validation-map commands, five waves, dependency ordering, zero same-wave file overlap, every task file declared in its owning plan, all ten requirements, three resolved research questions, eighteen unique numbered threat rows and one reserved SC row per plan. Both modified plans end with `</output>` and contain no continuation sentinel. No application tests or commits ran in this revision.

## Executed Coverage Audit — 2026-10-27

Run `25208-1793102721082-59067-6ba5536df2dd` passed all 18 serial commands. The fresh evidence validator passed all ten requirements, thirteen classified edges and twenty UI predicates; the generated UAT has 66/66 passing items. A fresh rerun of the generator/CI contract suites passed 22/22. No requirement is PARTIAL or MISSING; no manual acceptance gate is needed.

| Task | Executed lane IDs | Status |
|---|---|---|
| 252-01-01 | `story-slice` | COVERED |
| 252-01-02 | `subscription-area` | COVERED |
| 252-02-01 | `scenario-domain` | COVERED |
| 252-02-02 | `subscription-area`, `story-slice` | COVERED |
| 252-03-01 | `phase252-lab-contract` | COVERED |
| 252-03-02 | `phase252-lab-contract`, `isolation-reset` | COVERED |
| 252-04-01 | `scenario-repo` | COVERED |
| 252-04-02 | `heldout-cleanup`, `phase248-heldout-contract` | COVERED |
| 252-05-01 | `manifest-contract` | COVERED |
| 252-05-02 | `manifest-contract`, `registry-kitchen-mount-scoped-path` | COVERED |
| 252-06-01 | `subscription-render-browser` | COVERED |
| 252-06-02 | `subscription-render-browser`, `mounted-subscription-regressions` | COVERED |
| 252-07-01 | `production-boundary-db-free`, `registry-kitchen-mount-scoped-path` | COVERED |
| 252-07-02 | `production-boundary-controls`, `production-packages` | COVERED |
| 252-08-01 | `phase252-ci-contract` | COVERED |
| 252-08-02 | `phase252-ci-contract` | COVERED |
| 252-08-03 | `phase252-acceptance-contract` | COVERED |

Actual commands, cwd, assertions, exit codes, durations and log digests are recorded in `accrue_admin/tmp/phase252/ci-results/25208-1793102721082-59067-6ba5536df2dd/results.json`; each mapped lane exited 0. Guarded Mix commands use the appropriate project cwd; browser selection is forwarded after `--`, correcting the planning-era `--spec` examples. Current compile/package, disposable database, race/rollback, browser and negative controls are all present.

The four unclassified assumptions and two descriptor-less prohibitions remain unresolved exactly as planned; they are not reclassified as behavioral proof. Static rendering claims remain bounded. Planning-era statements below describe what had not run at planning time.

## Validation Audit 2026-10-27

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

## Remediation Coverage Recheck — 2026-10-27

The current aggregate also requires real descendant interruption, exited-leader cleanup, and unrelated sentinel preservation. All eighteen commands passed after the cleanup correction, bounded compile deadline and settled-theme polling. Independent security re-audit passed 37 focused controls and 2 real interruption tests. Earlier run references in the executed map were refreshed to the passing current bundle; original historical artifacts remain unchanged.

## Final Review Correction Recheck — 2026-10-27

Current source commit `3991d890` passed all eighteen owner commands in run `25208-1793102721082-59067-6ba5536df2dd`. Reporter-backed execution requires actual test identities and rejects skipped/excluded/missing output; the browser lane executed sixteen tests with zero skips or failures and produced fifteen render rows. The acceptance lane passed twenty tests; a fresh combined acceptance/CI contract invocation passed thirty tests with zero skips. Generated UAT has 67/67 passing items. Real sandbox token scope and light primary/link paint are proved by focused and canonical browser checks; host accent override remains supported.
