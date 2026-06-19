---
phase: 192
slug: idempotent-verification-sign-off
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-19
---

# Phase 192 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Playwright 1.59.x, axe-core/playwright, Node 22 scripts, ExUnit where component-lab coverage uses server-side registry checks |
| **Config file** | `accrue_admin/playwright.config.js`; `.github/workflows/ci.yml`; phase scripts under `scripts/ci/` and `accrue_admin/e2e/` |
| **Quick run command** | `cd accrue_admin && npm run baseline:parse && cd .. && node scripts/ci/verify_phase191_ax187_coverage.mjs` |
| **Full suite command** | `cd accrue_admin && npm run baseline:parse && cd .. && node scripts/ci/verify_phase191_ax187_coverage.mjs && cd accrue_admin && npm run e2e:group-contracts && npm run e2e:phase191 && npm run e2e:a11y && npx playwright test e2e/reduced-motion.spec.js --workers=1` |
| **Estimated runtime** | ~10-30 minutes depending on browser startup and CI cache state |

---

## Sampling Rate

- **After every task commit:** Run the quick command or the task-specific script named in PLAN.md.
- **After every plan wave:** Run the full deterministic guardrail command list plus the component-lab coverage check selected by the plan.
- **Before `/gsd:verify-work`:** Full guardrails, final scorecard verifier, and sign-off verifier must be green or explicitly blocked by maintainer sign-off.
- **Max feedback latency:** One task commit; no three consecutive implementation tasks may lack an automated verifier.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 192-01-01 | 01 | 1 | VER-02 | T-192-01 | Reject malformed or missing scorecard artifacts without eval/dynamic code | Node artifact verifier | `node scripts/ci/verify_phase192_scorecard.mjs` | no - W0 | pending |
| 192-01-02 | 01 | 1 | VER-02 | T-192-02 | Preserve repo-relative evidence refs under allowed roots only | Node artifact verifier | `node scripts/ci/verify_phase192_scorecard.mjs --manifest` | no - W0 | pending |
| 192-02-01 | 02 | 1 | VER-02, VER-04 | T-192-03 | Generate markdown from structured artifacts; do not let markdown override JSON/NDJSON | Node reducer/verifier | `cd accrue_admin && npm run phase192:scorecard && cd .. && node scripts/ci/verify_phase192_scorecard.mjs` | no - W0 | pending |
| 192-03-01 | 03 | 2 | VER-03 | T-192-04 | Run deterministic browser/a11y/motion guardrails serially without secrets | CI / Playwright | full guardrail command list from this file | partial | pending |
| 192-04-01 | 04 | 2 | VER-04 | T-192-05 | Sign-off package exposes explicit maintainer accept/block checklist and artifact links | Static doc verifier | `node scripts/ci/verify_phase192_signoff.mjs` | no - W0 | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [ ] `scripts/ci/verify_phase192_scorecard.mjs` - validates `final.cells.json`, `scorecard.delta.json`, `regressions.ndjson`, and `artifacts.manifest.json` against strict comparison rules.
- [ ] `scripts/ci/verify_phase192_signoff.mjs` - verifies `192-SIGN-OFF.md` has executive status, curated gallery rows, CI guardrail status, artifact links, and explicit checklist outcome.
- [ ] `accrue_admin/e2e/phase192-scorecard.mjs` or equivalent - creates final cells from raw evidence without mutating Phase 187 artifacts.
- [ ] Component-lab structural coverage command selected and wired into CI, using existing registry/ExUnit/verifier patterns.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Maintainer final screenshot and curated gallery approval | VER-04 | The maintainer must explicitly approve JTBD clarity, brand fit, screenshot evidence, and checklist state | Review `.planning/phases/192-idempotent-verification-sign-off/192-SIGN-OFF.md`, linked gallery rows, artifact manifest refs, and record accept/block outcome in the checklist |
| Subjective brand/microcopy accept/block rows | VER-02, VER-04 | Brand and microcopy lens can use advisory scoring, but final subjective approval requires explicit status and evidence refs | Confirm every subjective row cites deterministic screenshot/trace evidence and has accept/block status |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all missing references
- [ ] No watch-mode flags
- [ ] Feedback latency < one task commit
- [ ] `nyquist_compliant: true` set in frontmatter after Wave 0 verifier files exist

**Approval:** pending
