---
phase: 226-ci-baseline-proof-semantics
reviewed: 2026-08-12T17:21:00Z
depth: standard
files_reviewed: 18
files_reviewed_list:
  - .github/workflows/ci.yml
  - accrue/test/accrue/live_proof_formatter_test.exs
  - accrue/test/support/live_proof_formatter.ex
  - accrue/test/test_helper.exs
  - examples/accrue_host/README.md
  - examples/accrue_host/package.json
  - guides/testing-live-stripe.md
  - scripts/ci/README.md
  - scripts/ci/accrue_host_uat.sh
  - scripts/ci/accrue_host_verify_browser.sh
  - scripts/ci/ci_setup_diagnostic.sh
  - scripts/ci/collect_ci_baseline.mjs
  - scripts/ci/provider_proof.mjs
  - scripts/ci/render_ci_baseline.mjs
  - scripts/ci/render_provider_summary.mjs
  - scripts/ci/verify_ci_baseline.mjs
  - scripts/ci/verify_ci_setup_diagnostics.sh
  - scripts/ci/verify_provider_proof.mjs
findings:
  critical: 1
  warning: 1
  info: 0
  total: 2
status: issues_found
---

# Phase 226: Code Review Report

**Reviewed:** 2026-08-12T17:21:00Z
**Depth:** standard
**Files Reviewed:** 18
**Status:** issues_found

## Summary

The CI proof, host diagnostic, baseline, and documentation changes were reviewed in context. The supplied fixture verifiers pass, but a direct `ACCRUE_PROVIDER_MANIFEST=<temp> mix test.live --trace` run produced `10 tests, 0 failures, 10 skipped (2114 excluded)` while the emitted manifest recorded `selected_count: 2124`, `failed_count: 2114`, and `skipped_count: 10`. Consequently, the required periodic provider-proof job classifies a valid live suite as `misconfigured`/`failed`, rather than `proved`.

## Critical Issues

### CR-01: Excluded tests are recorded as selected failures in the live-provider manifest

**File:** `accrue/test/support/live_proof_formatter.ex:31-49`

**Issue:** `mix test.live` is implemented as `mix test --only live_stripe`, so ExUnit emits `{:excluded, ...}` completion states for every untagged test. The formatter only treats `nil` as passed and `{:skipped, ...}` as skipped; its catch-all increments `failed_count`. In the direct run, 2,114 excluded tests became failures. The workflow finalizer then rejects the manifest (`skipped_count > 0` or `failed_count > 0`), so the scheduled/manual live-Stripe job can never produce its intended `proved` record even when all selected provider tests pass.

**Fix:** Ignore excluded completions entirely and add an integration test that runs the formatter against `mix test --only live_stripe` semantics (or explicitly sends `{:excluded, _}`), asserting only selected tests enter the manifest.

```elixir
defp increment(state, {:excluded, _reason}), do: state

defp increment(state, nil),
  do: %{state | selected_count: state.selected_count + 1, passed_count: state.passed_count + 1}

defp increment(state, {:skipped, _reason}),
  do: %{state | selected_count: state.selected_count + 1, skipped_count: state.skipped_count + 1}
```

## Warnings

### WR-01: Live-Stripe enforcement documentation contradicts the workflow

**File:** `guides/testing-live-stripe.md:125-132`

**Issue:** The guide states that `continue-on-error: true` makes the manual-dispatch job advisory. The actual `live-stripe` job has no `continue-on-error` and passes `--policy required` to the finalizer in `.github/workflows/ci.yml:1254-1333`. This gives maintainers the wrong incident-response expectation when the periodic proof fails.

**Fix:** Replace the advisory/`continue-on-error` claim with the current required periodic-proof policy, and explain that it is scheduled/manual-only rather than a pull-request gate.

---

_Reviewed: 2026-08-12T17:21:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
