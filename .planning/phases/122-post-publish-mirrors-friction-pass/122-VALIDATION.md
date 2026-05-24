---
phase: 122
slug: post-publish-mirrors-friction-pass
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-08
---

# Phase 122 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash inventory verifier + fixed-string `rg` checks across live `.planning/` mirrors |
| **Config file** | none centralized; checks target `.planning/*.md` and `scripts/ci/verify_v1_17_friction_research_contract.sh` directly |
| **Quick run command** | `bash scripts/ci/verify_v1_17_friction_research_contract.sh && rg -F 'Current public linked release line: accrue / accrue_admin / accrue_portal 1.1.1 (published 2026-05-08).' .planning/PROJECT.md .planning/ROADMAP.md` |
| **Full suite command** | `bash scripts/ci/verify_v1_17_friction_research_contract.sh && rg -F 'Current public linked release line: accrue / accrue_admin / accrue_portal 1.1.1 (published 2026-05-08).' .planning/PROJECT.md .planning/MILESTONES.md .planning/STATE.md && ! rg -F 'ready to begin Phase 121 publish proof' .planning/STATE.md && ! rg -F 'The next unused planning phase is now **120**.' .planning/ROADMAP.md && rg -F -- '- [x] **HYG-03**' .planning/REQUIREMENTS.md && rg -F -- '- [x] **INV-08**' .planning/REQUIREMENTS.md` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run the task-level `rg` checks or `bash scripts/ci/verify_v1_17_friction_research_contract.sh` from that task’s `<verify>` block.
- **After every plan wave:** Run `bash scripts/ci/verify_v1_17_friction_research_contract.sh` plus the exact-sentence mirror grep across the touched live files.
- **Before `$gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 122-01-01 | 01 | 1 | HYG-03 | T-122-01 | `PROJECT.md` uses the exact shipped trio sentence and separates shipped-release truth from temporary closeout truth | mirror grep | `rg -F 'Current public linked release line: accrue / accrue_admin / accrue_portal 1.1.1 (published 2026-05-08).' .planning/PROJECT.md && rg -F 'v1.38 remained open briefly after publish to align planning mirrors and record INV-08.' .planning/PROJECT.md && ! rg -F 'No active milestone.' .planning/PROJECT.md` | ✅ | ⬜ pending |
| 122-01-02 | 01 | 1 | HYG-03 | T-122-02 / T-122-03 | `ROADMAP.md` reads as closeout, not as another pending release slice | mirror grep | `rg -F 'Current public linked release line: accrue / accrue_admin / accrue_portal 1.1.1 (published 2026-05-08).' .planning/ROADMAP.md && rg -F 'Phase 122 is the maintainer-facing closeout for live planning mirrors and INV-08, not a new release-proof pass.' .planning/ROADMAP.md && ! rg -F 'The next unused planning phase is now **120**.' .planning/ROADMAP.md` | ✅ | ⬜ pending |
| 122-02-01 | 02 | 1 | INV-08 | T-122-04 / T-122-06 | The inventory file records a dated path-(b) conclusion without unsourced new friction rows | inventory contract | `rg -n '^### v1\\.38 INV-08 maintainer pass \\(2026-05-08\\)$' .planning/research/v1.17-FRICTION-INVENTORY.md && rg -F '.planning/phases/122-post-publish-mirrors-friction-pass/122-VERIFICATION.md' .planning/research/v1.17-FRICTION-INVENTORY.md && bash scripts/ci/verify_v1_17_friction_research_contract.sh` | ✅ | ⬜ pending |
| 122-02-02 | 02 | 1 | INV-08 | T-122-05 | `122-VERIFICATION.md` reuses Phase 121 proof and records only the fresh inventory transcript | artifact grep | `test -f .planning/phases/122-post-publish-mirrors-friction-pass/122-VERIFICATION.md && rg -F 'PR_NUMBER: 23' .planning/phases/122-post-publish-mirrors-friction-pass/122-VERIFICATION.md && rg -F 'TARGET_VERSION: 1.1.1' .planning/phases/122-post-publish-mirrors-friction-pass/122-VERIFICATION.md && rg -F 'RUN_ID: 25554198977' .planning/phases/122-post-publish-mirrors-friction-pass/122-VERIFICATION.md && rg -F 'verify_v1_17_friction_research_contract: OK' .planning/phases/122-post-publish-mirrors-friction-pass/122-VERIFICATION.md` | ✅ | ⬜ pending |
| 122-03-01 | 03 | 2 | HYG-03 | T-122-07 | Final live mirrors are shipped/archive and no longer expose stale Phase 121/120 residue | final mirror grep | `rg -F 'Current public linked release line: accrue / accrue_admin / accrue_portal 1.1.1 (published 2026-05-08).' .planning/PROJECT.md .planning/MILESTONES.md .planning/STATE.md && rg -F '## v1.38 Linked Release Truth (Shipped: 2026-05-08)' .planning/MILESTONES.md && ! rg -F 'ready to begin Phase 121 publish proof' .planning/STATE.md && ! rg -F 'The next unused planning phase is now **120**.' .planning/ROADMAP.md` | ✅ | ⬜ pending |
| 122-03-02 | 03 | 2 | HYG-03, INV-08 | T-122-08 / T-122-09 | Requirements close only after final evidence exists and `122-VERIFICATION.md` is passed | requirements + ledger grep | `rg -F 'status: passed' .planning/phases/122-post-publish-mirrors-friction-pass/122-VERIFICATION.md && rg -F -- '- [x] **HYG-03**' .planning/REQUIREMENTS.md && rg -F -- '- [x] **INV-08**' .planning/REQUIREMENTS.md && rg -F '| HYG-03 | Phase 122 | Complete |' .planning/REQUIREMENTS.md && rg -F '| INV-08 | Phase 122 | Complete |' .planning/REQUIREMENTS.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Canonical public release proof is already present in `121-VERIFICATION.md` with the exact PR, version, and workflow-run identifiers Plan 02 must reuse.
- [x] Existing inventory verifier infrastructure already covers the `v1.17-FRICTION-INVENTORY.md` contract; no new script is required.
- [x] Phase 122 tasks all have deterministic `rg` or bash verification commands; no missing test scaffold is required.

Wave 0 is satisfied by existing repo artifacts and the planned task structure:
- Plan 01 reuses exact-sentence mirror greps.
- Plan 02 reuses `verify_v1_17_friction_research_contract.sh` and a lean `122-VERIFICATION.md`.
- Plan 03 finalizes live-state and requirements only after those artifacts exist.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Sanity-check that final live mirror prose stays concise and does not over-copy Phase 121 proof tables | HYG-03 | The commands prove literals and residue removal, but a human still benefits from one narrative pass | Read `.planning/PROJECT.md`, `.planning/MILESTONES.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` after Plan 03 and confirm they summarize proof rather than duplicating it |
| Confirm no new downstream trust signal was actually discovered during execution that would invalidate path `(b)` | INV-08 | Scripted checks cannot judge newly surfaced maintainer evidence | Review the final `122-VERIFICATION.md` and inventory subsection; if a real new integrator-facing trust issue appeared, reopen the plan instead of shipping path `(b)` silently |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify commands
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all prerequisites
- [x] No watch-mode flags
- [x] Feedback latency < 10s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** ready 2026-05-08
