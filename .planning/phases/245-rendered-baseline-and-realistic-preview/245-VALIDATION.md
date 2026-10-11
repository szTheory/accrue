---
phase: "245"
slug: "rendered-baseline-and-realistic-preview"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-11"
---

# Phase 245 — Validation Strategy

## Test Infrastructure

Use existing ExUnit/Mix host owners for ordinary seed integrity and Playwright for mounted captures. Phase 245 adds `examples/accrue_host/test/ordinary_preview_seed_test.exs`, `examples/accrue_host/e2e/phase245-admin-baseline.spec.js`, the dedicated exact-origin `examples/accrue_host/playwright.phase245.config.js`, and `scripts/ci/verify_phase245_baseline.mjs`. The existing `playwright.config.js` reserves `ACCRUE_HOST_PREVIEW_BASE_URL` for Phase 243 preservation and must not be used to target the ordinary preview. No new framework or dependency.

## Sampling Rate

Run the relevant focused check after each implementation task. At the wave boundary, reconcile the route ledger, integrity checks and capture manifest against the tested revision. Run the bounded mounted capture owner once after source and served assets stabilize; repeat only after changes or demonstrated failures. Full unrelated suites do not substitute for these checks. Ordinary preview uses an isolated stack; protected Phase 243 preview custody is checked around tooling changes.

## Per-Task Verification Map

| Task | Requirement | Exact focused command | Evidence and threat |
|---|---|---|---|
| 245-01 Task 1 | DEMO-01, BASE-01, BASE-02 | `ACCRUE_HOST_ORDINARY_BASE_URL=http://accrue-host-phase245-ordinary.localhost/ npm --prefix examples/accrue_host run e2e -- --config=playwright.phase245.config.js e2e/phase245-admin-baseline.spec.js --project=chromium-desktop --workers=1 --grep 'tracer'` | Mounted invoice path, current served asset digest and PNG provenance; T-245-01/02. Requires isolated stack booted and ordinary seed run. |
| 245-01 Task 2 | DEMO-01 | `cd examples/accrue_host && MIX_ENV=test mix test test/ordinary_preview_seed_test.exs` plus README `rg` check in plan | Repeatable ordinary seed and explicit safe boot/recovery; T-245-01. |
| 245-02 Task 1 | DEMO-01 | `cd examples/accrue_host && MIX_ENV=test mix test test/ordinary_preview_seed_test.exs test/seeds_idempotency_test.exs` | Amount/currency in minor units, exact relationship and UTC chronology; T-245-03. |
| 245-02 Task 2 | DEMO-01 | `rg -n 'processor_id|currency|UTC|unknown|unavailable|history|source' .planning/phases/245-rendered-baseline-and-realistic-preview/245-ORDINARY-STORIES.md` | Story/source review with classified absences; T-245-04. |
| 245-03 Task 1 | BASE-01 | `node scripts/ci/verify_phase245_baseline.mjs --coverage .planning/phases/245-rendered-baseline-and-realistic-preview/245-COVERAGE.md --routes-only` | Exact mounted route reconciliation, unique ordered state IDs and reasoned statuses; T-245-07. |
| 245-03 Task 2 | BASE-01, BASE-02 | `ACCRUE_HOST_ORDINARY_BASE_URL=http://accrue-host-phase245-ordinary.localhost/ npm --prefix examples/accrue_host run e2e -- --config=playwright.phase245.config.js e2e/phase245-admin-baseline.spec.js --project=chromium-desktop --workers=1` then, only after success, `node scripts/ci/verify_phase245_baseline.mjs --coverage .planning/phases/245-rendered-baseline-and-realistic-preview/245-COVERAGE.md --manifest .planning/phases/245-rendered-baseline-and-realistic-preview/captures/manifest.json` | Current browser renders and correlated revision/fixture/source/served asset/PNG identity; T-245-05/06/07. |
| 245-03 Task 3 | BASE-02 | `node scripts/ci/verify_phase245_baseline.mjs --coverage .planning/phases/245-rendered-baseline-and-realistic-preview/245-COVERAGE.md --manifest .planning/phases/245-rendered-baseline-and-realistic-preview/captures/manifest.json --findings .planning/phases/245-rendered-baseline-and-realistic-preview/245-FINDINGS.md` | Source-linked owner item disposition and image inspection record; T-245-05/06. Human visual judgment remains an explicit evidence input. |

## Wave 0 Requirements

- Create the named test files and dedicated Playwright config in 245-01 before their commands run.
- Create the manifest/coverage verifier in 245-03 Task 1 before capture expansion.
- Bootstrap with `ACCRUE_HOST_SKIP_SEEDS=1 make up INSTANCE=accrue-host-phase245-ordinary` from `examples/accrue_host`, then explicitly run `docker compose -p accrue-host-phase245-ordinary exec -T web mix run priv/repo/seeds/ordinary.exs`. Snapshot/assert-preserved on the Phase 243 instance around the operation.

## Manual-Only Verifications

| Behavior | Requirement | Why manual | Instructions |
|---|---|---|---|
| Task-oriented composition and copy assessment | BASE-02 | Screenshot existence and detector success cannot judge hierarchy or comprehension | Inspect captured images, record primary anchor and source-linked findings, deduplicate shared defects and explicitly account for gaps. |
| Plausibility of ordinary billing stories | DEMO-01 | Structural checks cannot establish narrative plausibility | Review relationships, amounts, chronology and observed outcomes together; retain genuine unknowns. |

## Validation Sign-Off

- [x] Every planned task has an automated check or explicit Wave 0 dependency.
- [ ] No three consecutive tasks lack automated feedback.
- [ ] Missing owners are created before use; no watch flags.
- [ ] Executed evidence is tied to the revision and served assets it tested.
- [ ] nyquist_compliant updated only after evidence supports it.

**Approval:** pending plan verification and execution evidence.
