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
| **Quick run command** | `rg -n "DISC-0[1-5]" .planning/phases/16-expansion-discovery/*.md` |
| **Full suite command** | `cd examples/accrue_host && mix verify.full` |
| **Estimated runtime** | ~120 seconds |

---

## Sampling Rate

- **After every task commit:** Run `rg -n "DISC-0[1-5]" .planning/phases/16-expansion-discovery/*.md`
- **After every plan wave:** Run `cd examples/accrue_host && mix verify.full`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 16-01-01 | 01 | 1 | DISC-01 | T-16-01 | Tax recommendation preserves Stripe-first architecture and names rollout risks | docs contract | `rg -n "Stripe Tax|automatic tax|customer location" .planning/phases/16-expansion-discovery/*.md` | no W0 | pending |
| 16-01-02 | 01 | 1 | DISC-02 | T-16-02 | Revenue/export recommendation avoids custom accounting surfaces without a consumer | docs contract | `rg -n "Revenue Recognition|Sigma|Data Pipeline|CSV" .planning/phases/16-expansion-discovery/*.md` | no W0 | pending |
| 16-01-03 | 01 | 1 | DISC-03 | T-16-03 | Processor recommendation preserves the Stripe-first boundary | docs contract | `rg -n "planted seed|single provider|separate package|custom processor" .planning/phases/16-expansion-discovery/*.md` | no W0 | pending |
| 16-01-04 | 01 | 1 | DISC-04 | T-16-04 | Org billing recommendation respects Sigra and host-owned tenancy constraints | docs contract | `rg -n "Sigra|owner_type|owner_id|foreign keys|query prefixes" .planning/phases/16-expansion-discovery/*.md` | no W0 | pending |
| 16-01-05 | 01 | 1 | DISC-05 | T-16-05 | Candidate ranking assigns each option to next milestone, backlog, or seed | docs contract | `rg -n "Next milestone|Backlog|Planted seed|Ranked Recommendation" .planning/phases/16-expansion-discovery/*.md` | no W0 | pending |

*Status values: pending, green, red, flaky*

---

## Wave 0 Requirements

- [ ] Add or update a narrow docs-contract artifact that asserts the Phase 16 recommendation includes all four candidate areas plus ranking outcome.
- [ ] Decide whether the contract lives as an ExUnit docs test or a simple grep-backed script in `scripts/ci/`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Decision quality of ranking | DISC-05 | Ranking tradeoffs require maintainer judgment, not only string checks | Read the final recommendation artifact and confirm each candidate includes user value, architecture impact, risk, prerequisites, and placement |

---

## Validation Sign-Off

- [x] All tasks have automated docs-contract verify commands or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
