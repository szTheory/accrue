---
phase: 130-provider-honesty-fake-lane-proof-example-host-wiring
plan: "01"
subsystem: processor-capabilities
tags: [dunning, capabilities, provider-honesty, drift-gate, support-matrix]
dependency_graph:
  requires: []
  provides: [dunning-capability-group-ssot, dunning-matrix-rows, dunning-drift-gate]
  affects: [accrue/lib/accrue/processor/capabilities.ex, accrue/lib/accrue/processor/fake.ex, accrue/lib/accrue/processor/stripe.ex, accrue/lib/accrue/processor/braintree.ex, .planning/processor-support-matrix.md, scripts/ci/verify_processor_support_matrix.sh]
tech_stack:
  added: []
  patterns: [capability-group-extension, convergence-divergence-row-pattern, require_substring-drift-pin, negative-convergence-guard]
key_files:
  created: []
  modified:
    - accrue/lib/accrue/processor/capabilities.ex
    - accrue/lib/accrue/processor/fake.ex
    - accrue/lib/accrue/processor/stripe.ex
    - accrue/lib/accrue/processor/braintree.ex
    - .planning/processor-support-matrix.md
    - scripts/ci/verify_processor_support_matrix.sh
decisions:
  - dunning.campaign is a convergence row (local-identical x3) because the campaign cadence is Accrue-clock-driven with zero processor calls; smart_retry_alignment is a divergence row reflecting genuine per-provider payment-retry differences
  - braintree smart_retry_alignment: false (not false-label string) because Braintree has no native smart-retry overlay; campaign: true because Accrue's clock-driven cadence works identically
  - Negative guard targets dunning.campaign row specifically (grep -Eq '^| dunning\.campaign |.*\b(native|unsupported|bounded)\b') and is exempt for the smart_retry_alignment divergence row by name
  - Three load-bearing pinned prose substrings: "the campaign cadence behaves identically across Stripe, Braintree, and Fake", "Braintree is not retry-aligned", "Stripe has adaptive Smart Retries"
metrics:
  duration: 8min
  completed_date: "2026-05-25"
  tasks: 2
  files: 6
---

# Phase 130 Plan 01: Provider-Honest Dunning Capability Group + Drift Gate Summary

Dunning capability group added to the processor support-contract stack: `dunning.campaign` as a convergence row (local-identical across Fake/Stripe/Braintree) and `dunning.smart_retry_alignment` as a divergence row (Stripe native Smart Retries / Braintree clock-driven only / Fake testing lane), with the published matrix mirroring code labels and the existing drift gate extended with `require_substring` pins + a negative convergence guard.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add dunning capability group to Capabilities + three adapters | 0009c2bc | capabilities.ex, fake.ex, stripe.ex, braintree.ex |
| 2 | Add dunning rows + prose to support matrix and extend drift gate | 5ec0ece3 | processor-support-matrix.md, verify_processor_support_matrix.sh |

## Key Decisions

**1. Dunning label vocabulary (locked verbatim for Plan 02/03):**

Convergence row (`dunning.campaign`):
- fake / stripe / braintree: `"local-identical"`
- public label: `"all first-party"`

Divergence row (`dunning.smart_retry_alignment`):
- fake: `"testing/local-only"`
- stripe: `"native (Smart Retries)"`
- braintree: `"unsupported (clock-driven only)"`
- public label: `"provider-divergent (see dunning guide)"`

**2. Braintree adapter `smart_retry_alignment: false`** (boolean, not a string label) — genuine absence of a smart-retry overlay; `campaign: true` because the Accrue-clock-driven cadence works identically.

**3. Negative convergence guard scoped to `dunning.campaign` row only** — the `dunning.smart_retry_alignment` divergence row's `native (Smart Retries)` / `unsupported (clock-driven only)` labels are intentional and exempt.

**4. Three pinned prose substrings** (for Plan 02 guide pins and Plan 03 D-09 label-mirror test):
- `"the campaign cadence behaves identically across Stripe, Braintree, and Fake"`
- `"Braintree is not retry-aligned"`
- `"Stripe has adaptive Smart Retries"`

## Deviations from Plan

None — plan executed exactly as written. `provider_support_label/2` required no changes (path-generic via `get_in/2` as confirmed).

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes. Documentation and capability-label additions only. T-130-01 (label drift) mitigated by the drift gate as planned.

## Known Stubs

None.

## Self-Check: PASSED

- `accrue/lib/accrue/processor/capabilities.ex` — exists and contains `smart_retry_alignment` (2 occurrences)
- `accrue/lib/accrue/processor/fake.ex` — exists and contains `dunning: %{campaign: true, smart_retry_alignment: true}`
- `accrue/lib/accrue/processor/stripe.ex` — exists and contains `dunning: %{campaign: true, smart_retry_alignment: true}`
- `accrue/lib/accrue/processor/braintree.ex` — exists and contains `dunning: %{campaign: true, smart_retry_alignment: false}`
- `.planning/processor-support-matrix.md` — exists with dunning rows and ## Dunning prose
- `scripts/ci/verify_processor_support_matrix.sh` — exits 0 (verified)
- Task 1 commit 0009c2bc — verified in git log
- Task 2 commit 5ec0ece3 — verified in git log
