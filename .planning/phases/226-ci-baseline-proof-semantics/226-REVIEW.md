---
phase: 226-ci-baseline-proof-semantics
reviewed: 2026-08-12T00:00:00Z
depth: standard
files_reviewed: 16
files_reviewed_list:
  - accrue/test/accrue/live_proof_formatter_test.exs
  - accrue/test/support/live_proof_formatter.ex
  - accrue/test/test_helper.exs
  - examples/accrue_host/README.md
  - examples/accrue_host/package.json
  - guides/testing-live-stripe.md
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
  critical: 0
  warning: 2
  info: 0
  total: 2
status: issues_found
---

# Phase 226: Code Review Report

**Reviewed:** 2026-08-12T00:00:00Z
**Depth:** standard
**Files Reviewed:** 16
**Status:** issues_found

## Summary

The reviewed proof scripts now fetch and parse each run's workflow at its head SHA, and summary fields are escaped before Markdown rendering. The focused baseline, provider-proof, and setup-diagnostic verification suites pass. Two warnings remain: one breaks valid Postgres connection inputs, and one leaves conflicting operator guidance about live-provider enforcement.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Database name is not passed as one shell argument

**File:** `scripts/ci/accrue_host_uat.sh:39`

**Issue:** `${PGDATABASE:+-d "$PGDATABASE"}` is unquoted as a whole. Quotes produced inside a parameter expansion do not protect its result from word splitting or pathname expansion. A valid database name containing whitespace (or shell glob characters) is split into multiple arguments, so the readiness preflight can check the wrong database or fail before the host proof runs.

**Fix:** Build an argument array and append the database only when set.

```bash
pg_args=(-h "${PGHOST:-localhost}" -p "${PGPORT:-5432}" -U "${PGUSER:-postgres}")
if [ -n "${PGDATABASE:-}" ]; then
  pg_args+=(-d "$PGDATABASE")
fi
pg_isready "${pg_args[@]}"
```

### WR-02: Host README contradicts the selected provider lane's required policy

**File:** `examples/accrue_host/README.md:394-397`

**Issue:** This section calls live Stripe “optional and advisory only,” while the phase's provider guide and implementation classify scheduled/manual selected executions with `policy: required` and fail that lane on missing configuration, invalid manifests, zero selection, or assertion failures. The contradictory instruction can lead maintainers to treat a failed selected provider proof as advisory and skip the required remediation.

**Fix:** Distinguish merge-gate scope from selected-lane enforcement. For example: “Live Stripe is not a PR merge check; however, every scheduled/manual selected execution is a required provider-parity lane and must be remediated when it fails.”

---

_Reviewed: 2026-08-12T00:00:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
