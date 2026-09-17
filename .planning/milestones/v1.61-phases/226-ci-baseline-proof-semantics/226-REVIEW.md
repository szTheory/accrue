---
phase: 226-ci-baseline-proof-semantics
reviewed: 2026-08-12T23:27:29Z
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

**Reviewed:** 2026-08-12T23:27:29Z
**Depth:** standard
**Files Reviewed:** 18
**Status:** issues_found

## Summary

The CI evidence, formatter, provider-proof, baseline, and host diagnostic changes were reviewed in context. The supplied fixture suites and shell syntax checks pass, but the host wrapper mishandles the documented `PGDATABASE` setting and its test double masks that breakage.

## Critical Issues

### CR-01: [BLOCKER] `PGDATABASE` is passed to `pg_isready` as a single malformed argument

**File:** `scripts/ci/accrue_host_uat.sh:39`
**Issue:** The unquoted conditional expansion makes a set database value expand to one argument such as `"-d billing_database"`, rather than the required two arguments `-d` and `billing_database`. Consequently, the wrapper's initial readiness check fails or does not test the configured database whenever a caller supplies the documented `PGDATABASE` environment variable. CI happens to omit that variable, so it does not expose the broken supported path.
**Fix:** Construct the optional flag as an argument array, then expand that array quoted.

```bash
pg_args=(-h "${PGHOST:-localhost}" -p "${PGPORT:-5432}" -U "${PGUSER:-postgres}")
if [ -n "${PGDATABASE:-}" ]; then
  pg_args+=(-d "$PGDATABASE")
fi
pg_isready "${pg_args[@]}"
```

## Warnings

### WR-01: The readiness regression fixture cannot detect malformed `pg_isready` arguments

**File:** `scripts/ci/verify_ci_setup_diagnostics.sh:129-136`
**Issue:** The `pg_isready` test double only chooses an exit code from an environment variable and ignores its argument vector. The test at lines 141-156 sets `PGDATABASE`, but therefore still passes even though the wrapper supplies the malformed single `-d database` argument. This is a test-reliability defect that allowed CR-01 through.
**Fix:** Have the fake assert the exact argument sequence (including separate `-d` and database-name arguments) in the successful readiness case, and fail the fixture if it differs.

---

_Reviewed: 2026-08-12T23:27:29Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
