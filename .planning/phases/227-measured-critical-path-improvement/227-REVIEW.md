---
phase: 227-measured-critical-path-improvement
reviewed: 2026-09-12T16:32:57Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - .github/workflows/ci.yml
  - accrue/test/accrue/backend_automation_contract_test.exs
  - scripts/ci/README.md
  - scripts/ci/preflight_phase227_candidate.sh
  - scripts/ci/verify_ci_critical_path.mjs
  - scripts/ci/verify_ci_critical_path.test.mjs
findings:
  critical: 3
  warning: 1
  info: 0
  total: 4
status: issues_found
---

# Phase 227: Code Review Report

**Reviewed:** 2026-09-12T16:32:57Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

The candidate workflow edge, local preflight wrapper, NDJSON state machine, and verifier tests were reviewed. The v3 verifier has material evidence-integrity and remote-effect-safety gaps: it does not enforce ledger ordering, cannot prove the dispatch Boolean against Actions data, and silently ignores two accepted terminal-state modifiers in the local-evidence path.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: BLOCKER — Activation can be recorded after the remote candidate runs

**File:** `scripts/ci/verify_ci_critical_path.mjs:350-516`

**Issue:** The state machine builds maps by record kind and checks timestamps only within each reservation/consumption pair; it never requires the activation record to precede reservations, consumptions, candidate terminals, or the decision in the append-only ledger. Moving the real `gap_v3_activation` record from line 31 of `227-CI-CRITICAL-PATH.ndjson` to the end of the record array still returns `{"state":"kept","admitted_observations":3,"reserved":3,"consumed":3}` from `verifyFinalDecision`. This permits retroactive activation evidence to bless already-dispatched remote work, defeating the declared "activation before remote effects" control.

**Fix:** Track each record's ledger index (or require immutable sequence numbers) and reject any reservation unless a validated activation appears earlier. Also require reservation → consumption → terminal/advisory → decision ordering, and add a regression test that moves activation after a consumption and expects failure.

### CR-02: BLOCKER — Live verification never proves `run_live_stripe: false`

**File:** `scripts/ci/verify_ci_critical_path.mjs:403-408, 653-671`

**Issue:** The ledger comparison verifies `inputs: {run_live_stripe: false}` only against the reservation record. `verifyLiveGapV3` fetches the run, SHA, branch, event, conclusion, jobs, timings, and artifact names, but never validates the actual workflow-dispatch inputs. An operator can dispatch the same ref with `run_live_stripe: true`, invoke Stripe, and write `false` into NDJSON; all current live checks still pass because the Actions run API facts used here do not bind that input. The verifier therefore labels an externally effectful run as `non_run` provider evidence.

**Fix:** Have a job in the pinned candidate workflow emit a sanitized, immutable input-attestation artifact (containing only the Boolean, run ID, SHA, and workflow revision), download and validate it during `--verify-live-actions`, and bind it to the recorded run. Reject the candidate unless the attestation reports `run_live_stripe: false` and the provider lane is absent/skipped as expected.

### CR-03: BLOCKER — Accepted terminal-state modifiers are ignored by `--verify-evidence`

**File:** `scripts/ci/verify_ci_critical_path.mjs:978, 1007-1012`

**Issue:** The parser permits `--require-final-decision` and `--require-rollback-verified` with `--verify-evidence`, but that execution branch checks only `--require-kept`. Thus an authorized or activated-but-undecided v3 ledger passes despite `--require-final-decision`, and a non-verified rollback passes despite `--require-rollback-verified`. These are fail-open assurance flags, contrary to their names and the phase's terminal-safety contract.

**Fix:** Apply modifier validation centrally after `verifyFinalDecision`: require a terminal decision for `--require-final-decision`, and require `result.state === "rollback_verified"` for `--require-rollback-verified`. Add negative CLI tests using a ledger with its final decision removed and one whose terminal state is `rollback_applied_unverified`.

## Warnings

### WR-01: WARNING — `--rendered` is ignored by the live v3 verifier

**File:** `scripts/ci/verify_ci_critical_path.mjs:981, 1019-1024`

**Issue:** `--verify-live-actions` explicitly accepts `--rendered`, and the rendered report advertises a command containing it, but the v3 live branch never reads or compares that file. Running the documented live command with `--rendered /dev/null --require-kept` exits successfully. A stale or altered human-facing report can therefore accompany a passing live verification.

**Fix:** Before returning from every `--verify-live-actions` branch, when `--rendered` is supplied, compare its bytes with `renderCriticalPathEvidence(records)` exactly as the `--verify-evidence` branch does. Add a test that passes a deliberately incorrect rendered path/content and expects a nonzero result.

---

_Reviewed: 2026-09-12T16:32:57Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
