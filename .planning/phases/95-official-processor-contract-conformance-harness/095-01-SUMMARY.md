---
phase: 095-official-processor-contract-conformance-harness
plan: 01
subsystem: api
tags: [processor-support, capabilities, fake, stripe]

# Dependency graph
requires:
  - phase: 094-strategy-capability-matrix-target-lock
    provides: locked processor-support matrix and CI verifier
provides:
  - Explicit executable capability declarations for Stripe and Fake
  - Public support-label helpers on `Accrue.Processor`
  - Removal of optimistic legacy capability inheritance as first-party truth
affects: [phase-95-02, phase-95-03, processor support docs, conformance tests]

# Tech tracking
tech-stack:
  added: []
  patterns: [capability-label-ssot, explicit-adapter-capabilities]

key-files:
  created: []
  modified:
    - .planning/processor-support-matrix.md
    - accrue/lib/accrue/processor/capabilities.ex
    - accrue/lib/accrue/processor.ex
    - accrue/lib/accrue/processor/stripe.ex
    - accrue/lib/accrue/processor/fake.ex
    - accrue/test/accrue/processor/capabilities_test.exs

key-decisions:
  - "Stop treating legacy broad defaults as the executable first-party contract."
  - "Keep actual adapter capability truth explicit while separating it from public support labels."
  - "Expose support-label helpers on `Accrue.Processor` so downstream guards do not re-derive matrix semantics."

requirements-completed: [PROC-10]

# Metrics
duration: ~35m
completed: 2026-04-29
---

# Phase 95 Plan 01: Make the processor contract executable

**Phase 95 now treats processor support as an explicit executable contract: Stripe and Fake declare their real capability rows directly, the public matrix labels are available from `Accrue.Processor`, and optimistic legacy capability inheritance no longer defines first-party truth.**

## Accomplishments
- Replaced the legacy deep-merge default in `Accrue.Processor.Capabilities` with explicit adapter declarations plus support-label helpers.
- Expanded Stripe and Fake capability maps to cover the staged Phase 95 slice, including vault acquisition and lifecycle projection rows.
- Tightened `.planning/processor-support-matrix.md` so staged rows such as `customer.update` and `subscription.cancel` are documented honestly.
- Extended `accrue/test/accrue/processor/capabilities_test.exs` to prove explicit adapter rows and first-party label semantics.

## Verification
- `bash scripts/ci/verify_processor_support_matrix.sh`
- `cd accrue && mix test test/accrue/processor/capabilities_test.exs --max-cases 1`

## Task Commits

1. **Task 1: Replace optimistic capability defaults with explicit support truth** — `PENDING`
2. **Task 2: Expose support-label helpers and prove matrix/code parity** — `PENDING`

## Self-Check: PASSED

---
*Phase: 095-official-processor-contract-conformance-harness*
*Completed: 2026-04-29*
