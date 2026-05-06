---
phase: 104
slug: connect-spike-decision
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-02
---

# Phase 104 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix aliases |
| **Config file** | `accrue/test/test_helper.exs`, `accrue/mix.exs` |
| **Quick run command** | `cd accrue && mix test test/accrue/docs/connect_hyperwallet_decision_test.exs --warnings-as-errors` |
| **Full suite command** | `cd accrue && mix test.all` |
| **Estimated runtime** | `rg` scaffold check: ~2 seconds; docs-only ExUnit checks: ~20 seconds; full phase gate `mix test.all`: ~120 seconds |

---

## Sampling Rate

- **After every task commit:** Run the fastest command that matches the task:
  `rg ... connect_hyperwallet_decision_test.exs` for the scaffold task, then `cd accrue && mix test test/accrue/docs/connect_hyperwallet_decision_test.exs --warnings-as-errors` once the guide content exists
- **After every plan wave:** Run `cd accrue && mix test test/accrue/docs/processor_support_matrix_test.exs --warnings-as-errors`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 20 seconds for per-task docs checks; ~120 seconds applies only to the full phase gate

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 104-01-01 | 01 | 1 | BT-08 | T-104-01 | Create the docs-contract test file that will pin the decision wording before guide content is finalized | docs contract scaffold | `rg -n "ConnectHyperwalletDecisionTest|connect-hyperwallet-decision\\.md|strategically out of bounds unless the project boundary changes|reopening requires an explicit strategy change plus a new milestone|Braintree pay-ins and Hyperwallet payouts are separate truths|minimal seller onboarding \\+ payouts only" accrue/test/accrue/docs/connect_hyperwallet_decision_test.exs` | Created in-task | ⬜ pending |
| 104-01-02 | 01 | 1 | BT-08, BT-09 | T-104-01, T-104-02 | Decision artifact and public Connect boundary note satisfy the docs-contract test with provider-honest wording | docs contract | `cd accrue && mix test test/accrue/docs/connect_hyperwallet_decision_test.exs --warnings-as-errors` | Created by prior task | ⬜ pending |
| 104-02-01 | 02 | 2 | BT-09 | T-104-02 | Support matrix and strategy mirror the same no-go posture and reopen rule | docs contract | `cd accrue && mix test test/accrue/docs/processor_support_matrix_test.exs --warnings-as-errors` | ✅ existing | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- Existing infrastructure already covers this phase. No separate Wave 0 bootstrap plan is required.
- `accrue/test/accrue/docs/connect_hyperwallet_decision_test.exs` is introduced in Plan 01 before the guide-verification task runs.
- `accrue/test/accrue/docs/processor_support_matrix_test.exs` remains the existing matrix-verifier lane for Plan 02.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Confirm cited provider constraints still match live docs before final approval | BT-08 | Commercial/platform docs may change outside the repo | Re-open cited Braintree recurring billing, Hyperwallet onboarding, and PayPal payouts docs; confirm the final decision artifact still describes them accurately |
| Confirm no-go reopening rule is explicit in every touched maintainer-facing doc | BT-09 | Judgment across multiple docs is easier to audit manually than via one string needle | Read the phase decision artifact and any touched support-matrix/strategy docs; verify they say reopening requires an explicit strategy change plus a new milestone |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
