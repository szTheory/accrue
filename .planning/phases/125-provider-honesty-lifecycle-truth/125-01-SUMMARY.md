---
phase: 125-provider-honesty-lifecycle-truth
plan: 01
subsystem: entitlements / processor-support-contract
tags: [entitlements, capabilities, provider-honesty, drift-gate, ssot, ENT-08]
requires:
  - "Accrue.Processor.Capabilities (@support_labels, @provider_support_labels, accessors)"
  - "Accrue.Entitlements.Resolver.LocalMap.resolve/2 (provider-independent, Phase 123)"
  - "scripts/ci/verify_processor_support_matrix.sh (require_substring + stale-row guards)"
  - ".planning/processor-support-matrix.md (capability contract table)"
provides:
  - "entitlements: capability group in code labels (support + provider lanes)"
  - "entitlements: %{local_mapping: true} key on all three adapters (byte-identical)"
  - "entitlements.local_mapping convergence row + identity prose in the matrix SSOT doc"
  - "drift-gate positive asserts + negative divergence guard for entitlements rows"
  - "provider_honesty_test.exs: Fake-lane merge-blocking proof (== across providers, zero processor calls)"
affects:
  - "Phase 126 (ENT-11/12) admin view + public guide derive from this provider matrix"
  - "Phase 127 (ENT-10) Stripe-native overlay must keep entitlements rows convergence-only"
tech-stack:
  added: []
  patterns:
    - "SSOT-mirror same-PR co-update (capabilities code <-> matrix doc <-> bash gate)"
    - "convergence capability row (local-identical) vs the existing divergence lanes"
    - "telemetry-never-fired regression guard for zero-processor-call proof"
key-files:
  created:
    - "accrue/test/accrue/entitlements/provider_honesty_test.exs"
  modified:
    - "accrue/lib/accrue/processor/capabilities.ex"
    - "accrue/lib/accrue/processor/fake.ex"
    - "accrue/lib/accrue/processor/stripe.ex"
    - "accrue/lib/accrue/processor/braintree.ex"
    - ".planning/processor-support-matrix.md"
    - "scripts/ci/verify_processor_support_matrix.sh"
    - "accrue/test/accrue/processor/capabilities_test.exs"
decisions:
  - "Divergence-guard regex widened from [^|]* to a whole-row scan so a divergence token in the Stripe or Braintree column is caught, not just the Fake column (Rule 1 bug fix; T-125-01 requires any-cell)."
  - "Zero-processor-call proof uses a telemetry-never-fired guard on [:accrue, :processor, :customer, *] as the regression mechanism on top of the structural argument (resolve/2 takes no :processor arg)."
metrics:
  duration: ~5min
  tasks: 3
  files: 7
  completed: 2026-05-23
---

# Phase 125 Plan 01: Provider-Honesty Capability Surface (ENT-08) Summary

Made the local-first entitlements thesis machine-honest: added one additive `entitlements:` capability group whose provider lanes all read `local-identical` (the matrix's first convergence row), mirrored it byte-for-byte across the code labels, the matrix SSOT doc, and a merge-blocking drift gate, and proved with a Fake-lane test that `LocalMap.resolve/2` returns identical maps across Fake/Stripe/Braintree with zero processor calls.

## What Was Built

### Task 1 — entitlements: capability group (code labels + 3 adapters) [TDD]
- `Accrue.Processor.Capabilities`:
  - `@support_labels` gained `entitlements: %{local_mapping: "all first-party"}`.
  - `@provider_support_labels` gained the first **convergence** lane: `entitlements: %{local_mapping: %{fake: "local-identical", stripe: "local-identical", braintree: "local-identical"}}`. Every existing lane encodes divergence (`native`/`bounded first-party`/`unsupported`/`testing/local-only`); `"local-identical"` is the new convergence term.
  - Accessors (`support_label/1`, `provider_support_label/2`, `for/1`, `supports?/2`) reused verbatim — they resolve the new path via `get_in/2` with no edit.
- `Accrue.Processor.{Fake,Stripe,Braintree}.capabilities/0` each append a byte-identical `entitlements: %{local_mapping: true}` key; every other (gateway-divergent) key left untouched.
- RED: added a failing convergence-row test to `capabilities_test.exs` (committed first). GREEN: implementation passed it. No REFACTOR needed.

### Task 2 — matrix SSOT doc mirror
- `.planning/processor-support-matrix.md`:
  - Added the exact row `| entitlements.local_mapping | local-identical | local-identical | local-identical | all first-party |` to the capability contract table.
  - Added an **Entitlements** section that *inverts* the checkout/portal honesty framing — for entitlements both the public API shape AND the implementation are identical by construction — carrying the three gate-pinned strings verbatim: "behaves identically across Stripe, Braintree, and Fake", "zero processor calls", "local mapping remains the canonical default".
  - No `native`/`unsupported`/`bounded` entitlements row; public guide `accrue/guides/entitlements.md` not touched (Phase 126 owns it, D-07).

### Task 3 — drift gate + Fake-lane proof [TDD]
- `scripts/ci/verify_processor_support_matrix.sh`:
  - 4 positive `require_substring` asserts (the entitlements row literal + the three prose strings), reusing the existing helper.
  - A **negative divergence guard** that exits 1 if any entitlements row carries a `native`/`unsupported`/`bounded` label (drift toward the deferred Phase 127 path).
  - Rides the existing `docs-contracts-shift-left` CI job — no new CI step (D-09).
- `accrue/test/accrue/entitlements/provider_honesty_test.exs` (NEW): loops `[Fake, Stripe, Braintree]` as `:processor` against identical seeded local state (a customer with two active mapped subs), asserts the three `resolved` maps are `==`, proves zero processor calls via a telemetry-never-fired guard, and mirrors the doc capability labels code-side. Rides the merge-blocking `release-gate` `mix test`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Negative divergence-guard regex only scanned the Fake column**
- **Found during:** Task 3
- **Issue:** The plan/PATTERNS-specified guard regex `\| entitlements\.[a-z_]+ \|[^|]*\b(native|unsupported|bounded)\b` uses `[^|]*`, which can only match within the first provider cell (Fake). A `native`/`unsupported`/`bounded` token in the Stripe (col 2) or Braintree (col 3) column slips past — directly contradicting threat T-125-01 and the Task 3 acceptance criterion, which tests `local-identical | native | local-identical` (native in the Stripe column) and requires the gate to exit non-zero.
- **Fix:** Widened the pattern to `^\| entitlements\.[a-z_]+ \|.*\b(native|unsupported|bounded)\b` so it scans the entire row across pipe-delimited cells, anchored to an entitlements row. Verified it trips on a divergence token in any of the three provider columns, and does not false-trip on the correct all-`local-identical` row.
- **Files modified:** `scripts/ci/verify_processor_support_matrix.sh`
- **Commit:** 30012a3

## Verification

- `cd accrue && mix test test/accrue/processor/capabilities_test.exs test/accrue/entitlements/provider_honesty_test.exs --warnings-as-errors` — 0 failures.
- `bash scripts/ci/verify_processor_support_matrix.sh` — `OK`, exit 0.
- Scratch-edit proof (per Task 3 acceptance): injecting `native` into the Stripe column → gate exits 1 (positive row assert fires); adding a separate divergent entitlements row while keeping the convergence row intact → the **negative guard** itself fires its distinct error and exits 1.
- `mix credo --strict` on all touched files — no issues.
- Full `release-gate` (`cd accrue && mix test --warnings-as-errors`) — 1422 tests, 6 failures, all 6 being the documented pre-existing `Accrue.Docs.PackageDocsVerifierTest` baseline (PROJECT.md missing the "gateway subscription core" needle since 2026-05-08; out of scope, not a regression — this plan touches no PROJECT.md or docs-verifier code). The flaky PdfTest passed this run.

## Notes

- Scope: this plan (125-01) is Slice A+B of ENT-08 only (provider-honesty capability surface + drift gate + Fake-lane proof). The lifecycle-truth predicate (`entitling?/1`), the past-due grace knob (`PastDueGrace`, config, resolver widening), and the truth-table SSOT (ENT-09, D-10..D-20) belong to later plans in this phase and were intentionally not built here.
- A benign telemetry info-log appears during the proof test ("the function passed as a handler ... is a local function") — a cosmetic performance note from `:telemetry`, not a warning-as-error; the test passes under `--warnings-as-errors`.

## Self-Check: PASSED
