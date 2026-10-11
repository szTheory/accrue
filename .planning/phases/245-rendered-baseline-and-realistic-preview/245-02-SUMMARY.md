---
phase: 245-rendered-baseline-and-realistic-preview
plan: 02
subsystem: testing
tags: [elixir, ecto, seeds, billing-evidence]
requires:
  - phase: 245-01
    provides: Isolated ordinary preview stack and baseline data
provides:
  - Source-linked ordinary billing stories and absence classifications
  - Focused contract for showcase relationships, money, event data, chronology and stable reruns
  - Guarded correction of six standalone showcase invoice billing reasons
affects: [245-rendered-baseline-and-realistic-preview]
actuals:
  tokens: 5925
  tasks: 2
  commits: 3
commits: 3
plan_head_before: a070e19cbf7c736304bf1de6d87326caa6be08c4
plan_head_after: 4e66c751e84c700f6ea652d387c70a71a0047b77
tech-stack:
  added: []
  patterns: [Guarded deterministic seed reconciliation, Event-based TAP test reporting]
key-files:
  created:
    - .planning/phases/245-rendered-baseline-and-realistic-preview/245-ORDINARY-STORIES.md
    - .planning/phases/245-rendered-baseline-and-realistic-preview/245-02-red-evidence.json
    - examples/accrue_host/test/support/tap_formatter.ex
  modified:
    - examples/accrue_host/priv/repo/seeds/showcase.exs
    - examples/accrue_host/test/ordinary_preview_seed_test.exs
key-decisions:
  - "Standalone showcase invoices use manual billing reason because no subscription relationship identifies a subscription-backed reason."
  - "Existing rows are reconciled only when deterministic seed identity and key financial fields still match."
patterns-established:
  - "Seed correction: narrowly guard updates to existing rows by processor identity, customer, status, total, currency and absent FK."
requirements-completed: []
coverage:
  - id: D1
    description: Showcase invoice billing reasons agree with absent subscription links, including guarded repair of existing seeded rows.
    requirement: DEMO-01
    verification:
      - kind: unit
        ref: examples/accrue_host/test/ordinary_preview_seed_test.exs#showcase invoices without subscription links use a manual billing reason
        status: pass
      - kind: unit
        ref: examples/accrue_host/test/ordinary_preview_seed_test.exs#ordinary seed reconciles a stale billing reason on its existing showcase row
        status: pass
    human_judgment: false
  - id: D2
    description: Ordinary stories link selected IDs to stored amounts, relationships, chronology, and observed event evidence while retaining unknowns.
    verification:
      - kind: unit
        ref: examples/accrue_host/test/ordinary_preview_seed_test.exs#showcase paid and refund evidence agrees with stored money and UTC history
        status: pass
      - kind: integration
        ref: .planning/phases/245-rendered-baseline-and-realistic-preview/245-ORDINARY-STORIES.md
        status: pass
    human_judgment: true
    rationale: Ordinary Unicode-name coverage and some contextual lifecycle/promotion assertions remain open; the phase verifier must assess full requirement coverage.
duration: 35min
completed: 2026-10-11
status: complete
---

# Phase 245 Plan 02: Ordinary Preview Evidence Summary

**Standalone showcase invoices now identify as manual, with source-linked tests for ordinary invoice, payment and refund evidence and explicit notes on missing provider history.**

## Performance

- **Duration:** approximately 35 min
- **Started:** 2026-10-11 (exact start time not retained)
- **Completed:** 2026-10-11
- **Tasks:** 2
- **Files modified or created:** 6

## Accomplishments

- Added ordinary preview contracts for stable seed reruns, customer/subscription relationships, exact minor-unit amounts, currency, UTC chronology, event payloads, refunds, failed charges and nil subscription links.
- Corrected all six showcase invoices whose subscription billing reason had no subscription FK. The seed now performs a narrow guarded reconciliation for existing deterministic rows.
- Recorded source IDs, observed histories, fixture-only statuses and preserved data gaps in [245-ORDINARY-STORIES.md](./245-ORDINARY-STORIES.md).
- Reconciled the existing isolated ordinary stack through its seed entrypoint; protected Phase 243 custody assertion passed before and after.

## Verification

- `MIX_ENV=test mix test test/ordinary_preview_seed_test.exs test/seeds_idempotency_test.exs` from `examples/accrue_host`: **6 tests, 0 failures**.
- Fresh TAP RED report was classified with `RED_EVIDENCE_OK`; it demonstrated the original missing-subscription/billing-reason contradiction before implementation.
- `mix format --check-formatted` for the changed Elixir files and `git diff --check` passed.
- Phase 243 protected snapshot custody assertion passed after the ordinary seed reconciliation.

## Task Commits

1. **Task 1 RED:** `3d05b2c7` — `test(245-02): add failing showcase billing integrity contract`
2. **Task 1 GREEN:** `70856fde` — `fix(245-02): reconcile standalone showcase invoice reasons`
3. **Task 2:** `4e66c751` — `docs(245-02): record ordinary billing stories and evidence gaps`

## Decisions Made

- A missing subscription FK does not identify which subscription should be attached. Preserve the FK as null and correct the unsupported billing reason to `manual`.
- Keep fixture statuses without matching events explicitly described as local seed state; do not manufacture processor history, prices, line items or raw payloads.
- Preserve Phase 191 Unicode and edge-state long-name fixture ownership. Ordinary Unicode-name coverage remains unresolved and is left to the phase verifier.

## Deviations from Plan

### Execution tooling deviation

The existing TAP classifier required a real TAP report, while the host app had no reporter configured. Added a minimal host test formatter modeled on the existing portal formatter and generated unchanged ExUnit event output; no dependency was added. The prior Plan 245-01 RED plaintext was not classifier-supported evidence and is not claimed as classifier-accepted.

**Total deviations:** 1 tooling deviation. **Impact:** enabled the required fresh RED evidence gate without changing the normal test path.

## Deferred Evidence

- Ordinary Unicode-name coverage is absent; Phase 191 owns its deliberate Unicode record, while `edge_states` owns the long-name stress record.
- Lifecycle and promotion context rows listed in the story ledger are source-inspected but not all asserted by the focused tests.
- Some showcase invoices and partial-refund rows have no matching event/attempt history. Their statuses and stored amounts remain local fixture evidence only.
- `requirements-completed` is empty. This plan does not claim that Phase 245 requirements are complete; phase-level verification must assess remaining coverage.

## Next Phase Readiness

The isolated ordinary showcase seed is internally consistent for the corrected subscription reason and focused invoice/charge/refund stories. Phase-level capture and verification should proceed against the corrected ordinary stack, while keeping the listed coverage gaps visible.

---
*Phase: 245-rendered-baseline-and-realistic-preview*
*Completed: 2026-10-11*
