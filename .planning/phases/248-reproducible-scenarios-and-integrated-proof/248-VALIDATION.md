---
phase: "248"
slug: "reproducible-scenarios-and-integrated-proof"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-11"
---

# Phase 248 — Validation Strategy

## Test Infrastructure

| Property | Value |
|---|---|
| Framework | Existing Playwright browser tests, Node built-in assertions, host ExUnit contracts |
| Config | `examples/accrue_host/playwright.phase247-ordinary.config.js` and `playwright.phase247.config.js`; Phase 248 needs its own inclusion config or a compatible command override |
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
| 248-01-01 | 01 | 1 | DEMO-02, PROOF-01 | T-248-01 | Ordinary target and authenticated route match; current assets and source bound | Playwright/Node | Targeted ordinary Phase 248 Playwright case plus render verifier | ❌ W0 | ⬜ pending |
| 248-01-02 | 01 | 1 | DEMO-02 | T-248-02 | Held-out 4102 states cannot alias protected/ordinary data; no destructive action | Playwright/Node | Targeted held-out Phase 248 cases plus custody contract | ❌ W0 | ⬜ pending |
| 248-02-01 | 02 | 2 | PROOF-01 | T-248-03 | All 13 owner topics and five accepted findings have evidence or explicit disposition | Node | Integrated proof checker | ❌ W0 | ⬜ pending |
| 248-02-02 | 02 | 2 | PROOF-01, DEMO-02 | T-248-04 | Current screenshot, source and served assets agree; uncovered states explicit | Playwright/Node | Both mounted lanes, manifest and ledger checkers | ❌ W0 | ⬜ pending |

## Wave 0 Requirements

- Create `phase248-scenarios.spec.js` with one ordinary path and deterministic isolated exceptional states.
- Create `verify_phase248_render_proof.mjs` and `verify_phase248_integrated_proof.mjs` with focused negative fixture tests; reuse Phase 247 manifest shape and custody rules.
- No package install.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|---|---|---|---|
| Full-size image inspection | PROOF-01 | Automated hashes do not assess composition or clipping | Open every accepted 248 PNG at original resolution, record inspection time and observations; retain uncovered states. |

## Validation Sign-Off

- [ ] Each task has automated verification.
- [ ] All four scenario states have executed mounted assertions.
- [ ] All accepted owner topics have an executed owning check or justified evidence limitation.
- [ ] Current proof is bound to exact tested revision and served CSS/JS.
- [ ] `nyquist_compliant: true` after execution evidence exists.

**Approval:** pending execution
