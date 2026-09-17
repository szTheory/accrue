---
phase: "232"
slug: "bounded-hygiene-release-handoff"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-16"
---

# Phase 232 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Seeded from `232-RESEARCH.md` § Validation Architecture. Every SHA and count below
> inherits D-00 / D-15: **re-measure at execution time, never transcribe.**

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Node.js built-in `node:test` (`node --test`, with `--test-reporter=tap` wherever child output is asserted — D-33) for `.mjs` verifiers; Bash `set -e` + explicit `fail()` for shell verifiers |
| **Config file** | none — `node --test` auto-discovers; no `package.json` runner config for `scripts/ci/` |
| **Quick run command** | `node --test --test-reporter=tap scripts/ci/<changed_verifier>.mjs` |
| **Full suite command** | the `docs-and-bash-contracts-shift-left` job `run:` block in `.github/workflows/ci.yml` |
| **Estimated runtime** | ~1–5s per verifier; ~60–120s for the full shift-left job |

---

## Sampling Rate

- **After every task commit:** Run the specific new/changed verifier in `--fixtures` mode (hermetic, fast)
- **After every plan wave:** Run the full `docs-and-bash-contracts-shift-left` job locally, plus a `workflow_dispatch` re-run once the re-cut SHA is pushed
- **Before `/gsd-verify-work`:** `--fixtures` + one real (non-`--fixtures`) invocation of `verify_window_dispositions.mjs` against committed `.planning/WINDOWS.md` (D-16's new wiring)
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

> Populated by `/gsd-plan-phase` output and refined by `/gsd-validate-phase`. Requirement-level
> map below is the binding contract; task IDs bind once PLAN.md files exist.

| Req ID | Behavior | Test Type | Automated Command | File Exists | Status |
|--------|----------|-----------|-------------------|-------------|--------|
| HYG-01 | Every untracked file / worktree / debug session / remote branch classified, with completeness **and** soundness proof (D-46) | unit + integration | `node scripts/ci/verify_hygiene_dispositions.mjs --require-completeness --require-soundness` | ❌ W0 | ⬜ pending |
| HYG-02 | GSD health, planning mirrors, generated artifacts, package metadata, changelogs, release docs agree with the candidate; no release-blocking drift | integration | `scripts/ci/verify_release_manifest_alignment.sh` (exists; extended by 260916-hl9) + new release-docs-truth check for `RELEASING.md`'s stale "Last verified" line | ⚠️ partial / W0 | ⬜ pending |
| HYG-03 | Cleanup limited to objective, command-backed findings; bounded passes; stops when only nits remain (D-55/D-57/D-58) | integration | `node scripts/ci/verify_hygiene_dispositions.mjs --require-cleanup-findings-join` against `232-CLEANUP-FINDINGS.json` | ❌ W0 | ⬜ pending |
| REL-04 | Integration PR carries risk summary, exact verification evidence, rollback instructions, no unrelated scope (D-59/D-60/D-61) | structural lint | section-presence + density assertion over the PR body contract | ❌ W0 | ⬜ pending |
| REL-05 | Release Please ready to produce a version-and-changelog-consistent PR, without merge or publish (D-39) | integration (external CLI dry-run) | `scripts/ci/verify_release_pr_readiness.sh` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/ci/main_module.mjs` + its own `node:test` self-test — foundational; every `.mjs` touched by this phase depends on it (D-29)
- [ ] `scripts/ci/collect_hygiene_dispositions.mjs` / `render_hygiene_dispositions.mjs` / `verify_hygiene_dispositions.mjs` — HYG-01/02/03 artifact triad (D-45)
- [ ] `scripts/ci/verify_ci_script_contract.mjs` — D-32 meta-verifier; carries a committed non-empty expected file count (re-measure; 42 at research time)
- [ ] `scripts/ci/verify_release_pr_readiness.sh` — REL-05's entire proof surface (D-39); **confirm token availability before this task starts**
- [ ] `232-CLEANUP-FINDINGS.json` schema + its join-completeness assertion inside the hygiene verifier (D-58)

---

## Manual-Only Verifications

All phase behaviors have automated verification. Per CLAUDE.md's **Executable Acceptance Policy**
(Phase 218 onward), post-hoc human verification and manual UAT are **not** completion gates for
this phase; every requirement above resolves to a deterministic command with `human_judgment: false`.

The two maintainer decisions that remain genuinely human are product decisions already made and
recorded in CONTEXT.md (D-47 classify-only/delete-nothing; D-15 heading vocabulary), plus D-50's
open `.tool-versions` tracking-reversal confirmation — none is a recurring UAT.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
