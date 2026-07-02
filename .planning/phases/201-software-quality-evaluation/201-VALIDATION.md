---
phase: 201
slug: software-quality-evaluation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-02
---

# Phase 201 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Artifact validation with shell checks. Existing project test infrastructure is ExUnit plus Playwright, but this phase should not require full test execution. |
| **Config file** | `.planning/config.json`; project test/tooling references in `.github/workflows/ci.yml`, `accrue/mix.exs`, `accrue_admin/mix.exs`, `accrue_portal/mix.exs`, and Playwright configs. |
| **Quick run command** | `test -f .planning/phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md && rg -n "QLT-0[1-5]|Top 5|Evidence|Assumption|Phase 204" .planning/phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md` |
| **Full suite command** | Artifact review plus diff-boundary check; do not require `mix verify.full` for Phase 201. |
| **Estimated runtime** | ~30 seconds for artifact checks; reviewer spot-check time varies with evidence depth. |

---

## Sampling Rate

- **After every task commit:** Run the quick artifact inspection command and review low-score rows for local path evidence.
- **After every plan wave:** Run artifact inspection, diff-boundary check, and spot-check top-five deep dives against cited paths.
- **Before `/gsd:verify-work`:** Confirm the audit artifact satisfies QLT-01 through QLT-05 and that only Phase 201 planning/audit artifacts changed.
- **Max feedback latency:** 60 seconds for automated shell checks, excluding manual evidence review.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 201-01-01 | 01 | 1 | QLT-01 | T-201-01 | N/A - audit artifact only | artifact inspection | `rg -n "Dimension Ranking|Adoption|Production|Maintainer|Security|OSS|Upgrade|Release" .planning/phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md` | yes | pending |
| 201-01-02 | 01 | 1 | QLT-02 | T-201-02 | N/A - audit artifact only | artifact inspection | `rg -n "Top 5 Weakness|Do not over-fix|Fix first|Evidence from repo" .planning/phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md` | yes | pending |
| 201-01-03 | 01 | 1 | QLT-03 | T-201-03 | N/A - audit artifact only | artifact inspection | `rg -n "Adoption Friction|Production Readiness|Maintainer Friction|GSD Sanity|Missing-Dimension" .planning/phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md` | yes | pending |
| 201-01-04 | 01 | 1 | QLT-04 | T-201-04 | N/A - audit artifact only | artifact inspection | `rg -n "N/A|Score|maintain|not worth now|Do not overbuild" .planning/phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md` | yes | pending |
| 201-01-05 | 01 | 1 | QLT-05 | T-201-05 | N/A - audit artifact only | artifact inspection | `rg -n "Evidence|Assumption|Evidence from repo|static inspection|metrics needed" .planning/phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md` | yes | pending |
| 201-01-06 | 01 | 1 | QLT-01, QLT-02, QLT-05 | T-201-06 | N/A - audit artifact only | boundary check | `git diff --name-only -- . | rg -v '^(.planning/phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md|.planning/phases/201-software-quality-evaluation/201-RESEARCH.md|.planning/phases/201-software-quality-evaluation/201-VALIDATION.md|.planning/phases/201-software-quality-evaluation/201-01-PLAN.md|.planning/ROADMAP.md|.planning/STATE.md)$'` | yes | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [ ] Strengthen an explicit evidence appendix in `201-SOFTWARE-QUALITY-AUDIT.md` if inline evidence is not enough to satisfy QLT-05.
- [ ] Add an artifact checklist or recommendation table that Phase 204 can rank by impact, effort, risk reduction, timing, and done criteria if the existing seeded audit does not already provide it.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Low scores cite concrete repository evidence rather than generic OSS advice. | QLT-02, QLT-05 | Evidence quality requires judgment against the cited file path and claim. | For each top-five weakness, open at least one cited path and verify the consequence follows from the local evidence. |
| The audit stays inside Phase 201 scope and does not prescribe hidden implementation work. | QLT-01, QLT-03 | Scope boundary is semantic. | Confirm product behavior, public API, DB defaults, CI required-check topology, and release automation are not changed or planned as part of this phase. |
| Phase 204 can rank follow-up work. | QLT-03, QLT-05 | Ranking readiness depends on clarity of impact, effort, risk reduction, timing, and done criteria. | Review the final recommendations table and ensure each candidate follow-up has enough structure for hardening-roadmap prioritization. |

---

## Validation Sign-Off

- [ ] All tasks have automated verify commands or manual evidence review instructions.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [ ] Wave 0 covers all missing validation references.
- [ ] No watch-mode flags.
- [ ] Feedback latency < 60s for automated checks.
- [ ] `nyquist_compliant: true` set in frontmatter after execution validates the strategy.

**Approval:** pending
