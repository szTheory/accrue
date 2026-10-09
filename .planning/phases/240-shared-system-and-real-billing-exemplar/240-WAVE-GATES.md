---
phase: 240-shared-system-and-real-billing-exemplar
status: passed
---

# Phase 240 Wave Gates

## Wave 1 — passed

- `accrue_admin`: `MIX_ENV=test mix compile --warnings-as-errors && MIX_ENV=test mix test` exited 0; 614 tests, 0 failures.
- Baseline-set Node guard: 12 passed; committed exact eight-file set passed CLI preflight.
- Schema and UI capability checks: `block: false`. Codebase drift explicitly skipped (`no-structure-md`).
- Server restart reconciled 240-02 task commits and existing summary; recovery metadata committed in `a588121f`. No repeated implementation.

## Wave 2 — passed

- First full Admin gate: 616 tests, 1 failure. CPY-01 source-contract test still expected `Copy.resource_state_copy(:invoices` after the unavailable-action branch moved to `Copy.Invoice.invoice_action_unavailable()`.
- Aligned that exact call-site expectation with the canonical domain copy helper. Shared-copy routing remains asserted; targeted behavior is covered by invoice LiveView tests. No source behavior or test threshold was weakened.
- Fresh rerun: build with warnings as errors exited 0; 616 tests, 0 failures.
- Full Phase 199 acceptance after fixture/selector repair: 21 passed, 15 existing skips, 0 failed; Node suite 41/41. Both discovered deferred items are resolved.
- Schema and UI capability checks: `block: false`; codebase drift explicitly skipped (`no-structure-md`).
- 240-03 historical RED-report timing deviation is retained in its summary. Three isolated original-behavior reports were classified `RED_EVIDENCE_OK`; each matching current-source target passed. Retrospective evidence is not represented as original pre-GREEN evidence.

## Outstanding platform-specific work

Linux pixel comparison remains unrun locally on macOS (WINDOWS item 27). Existing Linux CI owns recurring comparison; Phase 243 owns final reviewed goldens. This is separate from the passing eight-file guard and semantic browser evidence. Actual 400% browser zoom was not exposed by the headless environment; pinch/visual scaling is explicitly distinguished in 240-03.

## Wave 3 — passed

- Admin build with warnings as errors exited 0; fresh full ExUnit run: 617 tests, 0 failures.
- Plan 240-05 owning unit suite: 71 tests, 0 failures; Phase 191 desktop/mobile lifecycle owner: 26 tests, 0 failures.
- Schema and UI gates returned `block: false`; codebase drift explicitly skipped (`no-structure-md`).
- Controlled fixture, real LiveView readiness, overlay replacement/focus and original disabled-state assertions are committed. No staged mutation replay was observed in authoritative fixture counts.

## Wave 4 — passed

- Final Admin compile with warnings as errors and full ExUnit: 618 tests, 0 failures.
- Final host `mix verify.full` exited 0: 64 bounded tests, 223 full-suite tests, dev boot, 37 browser checks (16 incumbent skips), and 14 separate Braintree checkout checks passed.
- Package desktop/mobile Phase 191/196/198/199 bundle: 89 passed, 19 incumbent skips, 0 failures/errors. Node: 41/41; baseline-set controls: 12/12; all eight required PNGs present.
- Ledger positive and omission-negative controls passed: 21 routes, eight requirements, live registry 30/42/8 and 43 source modules. Package docs/contrast guard passed.
- Fresh schema and UI safety gates: `block: false`; codebase drift explicitly skipped (`no-structure-md`).
- Complete logs identified archived Phase 239 path/hash evolution and Phase 234 mixed capture roots/stale price assertion. Current owner repairs are committed in `9eaa9cc1`; no threshold, retry, missing-baseline policy or production capability was weakened. Initial TrustSmoke timing remains historical rather than reclassified as a second observed latency defect.
- Three code-review findings fixed; original review and 13/24 UI audit remain historical, with dispositions linked separately. Final gate results and privacy-labeled native report copies are in `captures/final-gates/`. Independent goal verification remains the completion authority.
