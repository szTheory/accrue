---
phase: 240-shared-system-and-real-billing-exemplar
status: in_progress
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
