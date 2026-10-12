---
phase: "248"
slug: "reproducible-scenarios-and-integrated-proof"
status: validated
nyquist_compliant: false
wave_0_complete: true
created: "2026-10-11"
---

# Phase 248 — Validation Strategy

## Test Infrastructure

| Property | Value |
|---|---|
| Framework | Existing Playwright browser tests, Node built-in assertions, host ExUnit contracts |
| Config | `examples/accrue_host/playwright.phase248-ordinary.config.js` and `playwright.phase248-heldout.config.js` |
| Quick run | `node --check examples/accrue_host/e2e/phase248-scenarios.spec.js && node --check scripts/ci/verify_phase248_render_proof.mjs` |
| Full gate | Targeted ordinary and 4102 held-out Playwright lanes, current manifest validator, integrated ledger checker, and referenced Phase 245–247 owner checks |
| Expected feedback | Syntax and ledger checks under 60 seconds; mounted runs may take longer and are phase gates |

## Sampling Rate

- After each code task: run its focused syntax/contract command and targeted mounted path when available.
- After each plan wave: run the relevant mounted lane and verifier.
- Before phase verification: rerun both mounted lanes and current manifest/ledger validators; cite executed owner checks rather than claiming old checks ran again.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---|---|---|---|---|---|---|---|---|
| 248-01-01 | 01 | 1 | DEMO-02, PROOF-01 | T-248-01 | Ordinary target and authenticated route match; current assets and source bound | Playwright/Node | Targeted ordinary Phase 248 Playwright case plus render verifier | ✅ yes | ✅ automated commands covered |
| 248-01-02 | 01 | 1 | DEMO-02 | T-248-02 | Held-out 4102 states cannot alias protected/ordinary data; no destructive action | Playwright/Node | Targeted held-out Phase 248 cases plus custody contract | ✅ yes | ✅ automated commands covered |
| 248-02-01 | 02 | 2 | PROOF-01 | T-248-03 | All 13 owner topics and five accepted findings have evidence or explicit disposition | Node | Integrated proof checker | ✅ yes | ✅ automated commands covered |
| 248-02-02 | 02 | 2 | PROOF-01, DEMO-02 | T-248-04 | Current screenshot, source and served assets agree; uncovered states explicit | Playwright/Node | Both mounted lanes, manifest and ledger checkers | ✅ yes | ✅ automated commands covered |

## Wave 0 Requirements

- Create `phase248-scenarios.spec.js` with one ordinary path and deterministic isolated exceptional states.
- Create `verify_phase248_render_proof.mjs` and `verify_phase248_integrated_proof.mjs` with focused negative fixture tests; reuse Phase 247 manifest shape and custody rules.
- No package install.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|---|---|---|---|
| Full-size image inspection | PROOF-01 | Automated hashes do not assess composition or clipping | Open every accepted 248 PNG at original resolution, record inspection time and observations; retain uncovered states. |

## Validation Sign-Off

- [x] Each task has automated verification.
- [ ] Exact full Unicode boundary assertion must be corrected and executed (WR-01); existing prefix-only Plan 01 run remains recorded.
- [x] All accepted owner topics have an executed owning check or justified evidence limitation.
- [x] Current proof is bound to exact tested revision and served CSS/JS.
- [x] `nyquist_compliant: false` after execution evidence exists.

**Approval:** partial pending proof correction; phase advancement remains orchestrator-owned

## Validation Audit

- Gaps found: 1 direct render rejection-test gap.
- Resolved: 1; `verify_phase248_render_proof.test.mjs` passes seven CLI negative cases for missing/uninspected captures, route/lane identity, genuine empty count, image hash and served assets.
- Escalated: 0.
- Additional security correction coverage: `phase248_heldout_isolation.test.mjs` passes three cases proving disabled SQL sandbox is rejected before lifecycle/fixture mutation and supported setup retains seed/teardown.
- Fresh commands: `node --test scripts/ci/verify_phase248_integrated_proof.test.mjs` (9/9), `node --test scripts/ci/verify_phase248_render_proof.test.mjs scripts/ci/phase248_heldout_isolation.test.mjs` (10/10), both current proof validators (8 captures; 13 topics/5 findings), and custody contract (13/13).
- Mounted executions remain the actual Plan 01 ordinary 1/1 and held-out 3/3 at source `5548e3fd60d31f256c6bfd5322883066855cc872`. No product UI/source changed in closeout; harness-only sandbox guard correction does not relabel old images or imply new browser execution.
- Manual full-size inspections remain manifest-recorded Plan 01 observations for eight captures. Missing visual surfaces and interaction/role combinations remain explicit in `248-COVERAGE.md`; automated coverage is not owner acceptance or accessibility conformance.
- Global workflow TDD is false; Plan 02's missing RED-first history remains documented in its summary rather than retroactively claimed.

## Review Escalations

Code review WR-01 found that boundary `exact_identity_accessible=true` rests on a prefix-only locator rather than the full Unicode name. UI review UI248-01 found the required empty-state explanation outside the viewport; UI248-02 found invoice identity/status obscured by the drawer. These required scenario proof gaps are unresolved and are not waived. Correct exact identity assertion and bounded screenshot framing, execute focused mounted scenarios, inspect new PNGs and regenerate honest source/asset evidence before final validation sign-off. Other absent owner surfaces and interactions remain the explicit representative-coverage limits in the ledger.
