---
phase: 16
slug: expansion-discovery
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-17
---

# Phase 16 - Validation Strategy

Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit / Mix task contracts plus grep-backed docs contracts |
| **Config file** | none; Mix aliases and checked-in planning artifacts are the operative contracts |
| **Quick run command** | `rg -n "DISC-0[1-5]|Next milestone|Backlog|Planted seed" .planning/phases/16-expansion-discovery/16-EXPANSION-RECOMMENDATION.md .planning/phases/16-expansion-discovery/16-VALIDATION.md` |
| **Full suite command** | `cd accrue && mix test test/accrue/docs/expansion_discovery_test.exs --trace` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `rg -n "DISC-0[1-5]|Next milestone|Backlog|Planted seed" .planning/phases/16-expansion-discovery/16-EXPANSION-RECOMMENDATION.md .planning/phases/16-expansion-discovery/16-VALIDATION.md`
- **After every plan wave:** Run `cd accrue && mix test test/accrue/docs/expansion_discovery_test.exs --trace`
- **Before `$gsd-verify-work`:** The checked-in docs contract and artifact grep must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 16-01-01 | 01 | 1 | DISC-01 | T-16-01 | Tax recommendation preserves Stripe-first architecture, names tax rollout correctness, and captures customer location plus recurring-item migration constraints. | docs contract | `rg -n "Stripe Tax|tax rollout correctness|customer location|recurring-item migration|Stripe-first|Next milestone" .planning/phases/16-expansion-discovery/16-EXPANSION-RECOMMENDATION.md` | yes | green |
| 16-01-02 | 01 | 1 | DISC-02 | T-16-02 | Revenue/export recommendation keeps wrong-audience finance exports constrained through Stripe-owned reporting, Revenue Recognition, Sigma, Data Pipeline, and host-authorized export delivery. | docs contract | `rg -n "Revenue Recognition|Sigma|Data Pipeline|wrong-audience finance exports|host-authorized export delivery|Backlog" .planning/phases/16-expansion-discovery/16-EXPANSION-RECOMMENDATION.md` | yes | green |
| 16-01-03 | 01 | 1 | DISC-03 | T-16-04 | Processor recommendation preserves the Stripe-first boundary, keeps custom processor guidance, and records processor-boundary downgrade risks before any official adapter work. | docs contract | `rg -n "Official second processor adapter|custom processor|Stripe-first|processor-boundary downgrade|Planted seed" .planning/phases/16-expansion-discovery/16-EXPANSION-RECOMMENDATION.md` | yes | green |
| 16-01-04 | 01 | 1 | DISC-04 | T-16-03 | Org billing recommendation respects Sigra, host-owned tenancy, owner_type, owner_id, and cross-tenant billing leakage constraints before any row-scoped org work. | docs contract | `rg -n "Organization / multi-tenant billing|Sigra|owner_type|owner_id|cross-tenant billing leakage|Backlog" .planning/phases/16-expansion-discovery/16-EXPANSION-RECOMMENDATION.md` | yes | green |
| 16-01-05 | 01 | 1 | DISC-05 | T-16-01,T-16-02,T-16-03,T-16-04 | Stronger ranking contract proves the exact ranked candidate-to-outcome mapping: Stripe Tax support -> Next milestone, Organization / multi-tenant billing -> Backlog, Revenue recognition / exports -> Backlog, and Official second processor adapter -> Planted seed. | docs contract | `cd accrue && mix test test/accrue/docs/expansion_discovery_test.exs --trace` | yes | green |

*Status values: pending, green, red, flaky*

---

## Wave 0 Requirements

- [x] Added `accrue/test/accrue/docs/expansion_discovery_test.exs` as the narrow ExUnit docs contract for the checked-in recommendation artifact.
- [x] Added `.planning/phases/16-expansion-discovery/16-EXPANSION-RECOMMENDATION.md` as the canonical Phase 16 decision artifact with ranked outcomes and security language.
- [x] Strengthened the DISC-05 docs contract so exact ranked candidate-to-outcome rows, not loose keyword presence, prove the outcome.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Decision quality of ranking | DISC-05 | Ranking tradeoffs require maintainer judgment, not only string checks | Read `16-EXPANSION-RECOMMENDATION.md` and confirm each candidate includes user value, architecture impact, risk, prerequisites, and placement |

---

## Validation Sign-Off

- [x] All tasks have automated docs-contract verify commands or completed Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers the checked-in artifact and docs contract references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** aligned 2026-04-17
