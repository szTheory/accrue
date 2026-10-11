---
phase: "245"
slug: "rendered-baseline-and-realistic-preview"
status: validated
nyquist_compliant: false
wave_0_complete: true
created: "2026-10-11"
---

# Phase 245 — Validation Strategy

## Test Infrastructure

Use existing ExUnit/Mix host owners for ordinary seed integrity and Playwright for mounted captures. Phase 245 adds `examples/accrue_host/test/ordinary_preview_seed_test.exs`, `examples/accrue_host/test/ordinary_preview_story_contract_test.exs`, `examples/accrue_host/e2e/phase245-admin-baseline.spec.js`, the dedicated exact-origin `examples/accrue_host/playwright.phase245.config.js`, and `scripts/ci/verify_phase245_baseline.mjs`. The existing `playwright.config.js` reserves `ACCRUE_HOST_PREVIEW_BASE_URL` for Phase 243 preservation and must not be used to target the ordinary preview. No new framework or dependency.

## Sampling Rate

Run the relevant focused check after each implementation task. At the wave boundary, reconcile the route ledger, integrity checks and capture manifest against the tested revision. Run the bounded mounted capture owner once after source and served assets stabilize; repeat only after changes or demonstrated failures. Full unrelated suites do not substitute for these checks. Ordinary preview uses an isolated stack; protected Phase 243 preview custody is checked around tooling changes.

## Per-Task Verification Map

| Task | Requirement | Exact focused command | Evidence and threat |
|---|---|---|---|
| 245-01 Task 1 | DEMO-01, BASE-01, BASE-02 | `ACCRUE_HOST_ORDINARY_BASE_URL=http://accrue-host-phase245-ordinary.localhost/ npm --prefix examples/accrue_host run e2e -- --config=playwright.phase245.config.js e2e/phase245-admin-baseline.spec.js --project=chromium-desktop --workers=1 --grep 'tracer'` | **Pass for the task scope.** The final clean Phase 245 capture run recorded 5/5 Playwright tests passing in 49.6s. The tracer proves the authenticated ordinary invoice list/detail journey, Fake processor, current served assets and a digest-bound screenshot. Route/state breadth is covered by 245-03 below. |
| 245-01 Task 2 | DEMO-01 | `cd examples/accrue_host && MIX_ENV=test mix test test/ordinary_preview_seed_test.exs` plus `rg -n 'accrue-host-phase245-ordinary|ACCRUE_HOST_SKIP_SEEDS=1|seeds/ordinary.exs|assert-preserved' README.md` | **Pass.** Rerun behaviorally asserts stable invoice/customer/subscription identity, counts, money and fixture exclusion; README exact-token check also passed. |
| 245-02 Task 1 | DEMO-01 | `cd examples/accrue_host && MIX_ENV=test mix test test/ordinary_preview_story_contract_test.exs test/ordinary_preview_seed_test.exs test/seeds_idempotency_test.exs` | **Pass for the asserted ordinary stories.** Re-run in this audit: 11 tests, 0 failures. Contracts cover exact stored Unicode identity and owner relationship across reruns; promotion/coupon totals and eligibility; lifecycle markers and UTC periods; invoice/charge event, exact/adjacent stored times and minor-unit money; refund limits, fees and preserved missing history. Standalone invoice/attempt rows without corresponding history remain deliberately classified as fixture state/unknown, not provider evidence. |
| 245-02 Task 2 | DEMO-01 | `rg -n 'processor_id|currency|UTC|unknown|unavailable|history|source' .planning/phases/245-rendered-baseline-and-realistic-preview/245-ORDINARY-STORIES.md` | **Partial; source review plus contracts.** Story ledger maps the rows to persisted-data tests and classifies absences. Tests now cover Unicode, lifecycle and promotion data. Narrative plausibility still requires judgment, and the ledger explicitly retains records with no processor events/attempts as local fixture state. |
| 245-03 Task 1 | BASE-01 | `node scripts/ci/verify_phase245_baseline.mjs --coverage .planning/phases/245-rendered-baseline-and-realistic-preview/245-COVERAGE.md --routes-only` and `node scripts/ci/verify_phase245_baseline.mjs --self-test` | **Pass for route accounting and verifier behavior.** Both passed in this audit; self-test negatives rejected stale source digest, mismatched route, duplicate owner topic and generic unavailable claims. All 21 mounted production templates reconcile and material states are explicitly classified. Rendering still lacks Connect/Webhooks detail IDs and several state variants, recorded below. |
| 245-03 Task 2 | BASE-01, BASE-02 | `ACCRUE_HOST_ORDINARY_BASE_URL=http://accrue-host-phase245-ordinary.localhost/ npm --prefix examples/accrue_host run e2e -- --config=playwright.phase245.config.js e2e/phase245-admin-baseline.spec.js --project=chromium-desktop --workers=1` then `node scripts/ci/verify_phase245_baseline.mjs --coverage .planning/phases/245-rendered-baseline-and-realistic-preview/245-COVERAGE.md --manifest .planning/phases/245-rendered-baseline-and-realistic-preview/captures/manifest.json` | **Partial, with clean current evidence.** Final suite recorded 5/5 passed in 49.6s; this audit reran the full verifier successfully. The manifest has 24 PNGs at `a8d39ea4`, `source_dirty: false`, with source, package/compiled/served asset and PNG digests checked. It includes 19 route renders and five supplemental states. Connect and webhook detail, unfiltered empty, overflow, role/scope, touch, and other state combinations remain unavailable. |
| 245-03 Task 3 | BASE-02 | `node scripts/ci/verify_phase245_baseline.mjs --coverage .planning/phases/245-rendered-baseline-and-realistic-preview/245-COVERAGE.md --manifest .planning/phases/245-rendered-baseline-and-realistic-preview/captures/manifest.json --findings .planning/phases/245-rendered-baseline-and-realistic-preview/245-FINDINGS.md` | **Partial, with recorded visual review.** Full verifier passed. Main 19-route cohort received a bounded image critique; five supplemental states were inspected for their evidence; all 13 owner-brief topics have dispositions. Interaction evidence is limited to exercised examples: filtered-zero, search open/keyboard selection plus pointer hover, customer Invoices tab, and Activity disclosure open (lazy-load prompt remains). Other disclosures, keyboard activation/focus restoration, touch and broad filter/result behavior remain unverified. |

## Wave 0 Requirements

- Create the named test files and dedicated Playwright config in 245-01 before their commands run.
- Create the manifest/coverage verifier in 245-03 Task 1 before capture expansion.
- Bootstrap with `ACCRUE_HOST_SKIP_SEEDS=1 make up INSTANCE=accrue-host-phase245-ordinary` from `examples/accrue_host`, then explicitly run `docker compose -p accrue-host-phase245-ordinary exec -T web mix run priv/repo/seeds/ordinary.exs`. Snapshot/assert-preserved on the Phase 243 instance around the operation.

## Manual-Only Verifications

| Behavior | Requirement | Why manual | Instructions |
|---|---|---|---|
| Task-oriented composition and copy assessment | BASE-02 | Screenshot existence and detector success cannot judge hierarchy or comprehension | Inspect captured images, record primary anchor and source-linked findings, deduplicate shared defects and explicitly account for gaps. |
| Plausibility of ordinary billing stories | DEMO-01 | Structural checks cannot establish narrative plausibility | Review relationships, amounts, chronology and observed outcomes together; retain genuine unknowns. |
| Ordinary billing attempt/provider-event behavior | DEMO-01 | Several local invoice statuses intentionally have no corresponding event or attempt history; no action may be inferred from the fixture status | Keep the source-linked absence classifications; add ordinary attempt scenarios only if a real safe fixture supports them. Do not present local status as observed processor behavior. |
| Material UI states omitted from the bounded capture | BASE-01, BASE-02 | Captures cover representative filtered-zero/search/tab/disclosure examples, but unfiltered truly-empty, overflow, alternate role/scope, touch, action outcomes, other details, and systematic filter/query/result behavior remain unavailable | Exercise safe deterministic states in a follow-up capture/test plan; do not count Phase 243-only detail screenshots as Phase 245 ordinary evidence. |
| Unavailable Connect and webhook detail renders | BASE-01, BASE-02 | Ordinary Fake dataset has no rows from which those routes' detail IDs can be formed | Seed a safe ordinary record or keep the route explicitly unavailable; obtain a current authenticated render before claiming detail coverage. |

## Validation Sign-Off

- [x] Every planned task has an automated check or explicit Wave 0 dependency.
- [x] No three consecutive tasks lack automated feedback.
- [x] Missing owners are created before use; no watch flags.
- [x] Executed capture evidence includes source digests and served-asset digests; the current manifest records `source_dirty: false`.
- [x] `nyquist_compliant` remains false because material behavior and visual-state gaps remain.

**Audit outcome:** validated with partial coverage. New persisted-data contracts pass and the latest route/capture evidence is clean and self-validated. Remaining state and judgment gaps keep phase-wide compliance false. See [245-VALIDATION-REPORT.md](./245-VALIDATION-REPORT.md). Phase 245-01's plaintext ExUnit RED was not classifier-accepted; the Plan 245-02 story-contract RED was accepted for the named Unicode and coupon targets, per its ledger.

## Validation Audit

| Gaps found | Resolved by this audit | Escalated |
|---:|---:|---:|
| 4 | 2 | 0 |

Final capture safeguard follow-up: source `a8d39ea4` independently checks the Fake processor before bulk capture; positive/negative guard test and authenticated suite passed (5/5, 49.6s). Refreshed evidence is committed in `da24ebf7`.
