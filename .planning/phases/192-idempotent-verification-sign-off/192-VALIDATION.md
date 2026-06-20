---
phase: 192
slug: idempotent-verification-sign-off
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-19
finalized: 2026-06-20
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
| 192-02-01 | 02 | 2 | VER-02 | T-192-03 | Build reducer and validate fixture output shapes; do not let markdown override JSON/NDJSON | Node reducer self-test / dry-run | `node accrue_admin/e2e/phase192-scorecard.mjs --self-test`; `cd accrue_admin && npm run phase192:scorecard -- --self-test`; `node accrue_admin/e2e/phase192-scorecard.mjs --dry-run` | no - W0 planned by 192-02 | pending |
| 192-03-01 | 03 | 1 | VER-03 | T-192-04 | Run deterministic browser/a11y/motion guardrails serially without secrets | CI / Playwright | `bash scripts/ci/verify_phase192_guardrail_contract.sh`; `cd accrue_admin && npm run phase192:component-lab`; `bash scripts/ci/verify_phase192_admin_guardrails.sh` | partial - W0 planned by 192-03 | pending |
| 192-04-01 | 04 | 2 | VER-03 | T-192-05 | Wire deterministic guardrails into CI without promoting final evidence commands to PR gates | CI static verifier | `bash scripts/ci/verify_phase192_ci_contract.sh` | no - depends on 192-03 | pending |
| 192-05-01 | 05 | 3 | VER-04 | T-192-05 | Sign-off package exposes explicit maintainer accept/block checklist and artifact links | Static doc verifier | `node accrue_admin/e2e/phase192-gallery.mjs --self-test`; `cd accrue_admin && npm run phase192:signoff && cd .. && node scripts/ci/verify_phase192_signoff.mjs` | no - W0 planned by 192-05 | pending |
| 192-06-02 | 06 | 4 | VER-02, VER-04 | T-192-06-02 | Final evidence inventory preserves Phase 187 artifacts and writes final artifacts only under the Phase 192 directory | Final evidence inventory / scorecard | `node -e "...execFileSync('node',['accrue_admin/e2e/phase192-scorecard.mjs','--dry-run'])..."`; `cd accrue_admin && npm run phase192:scorecard`; `cd accrue_admin && npm run phase192:signoff` | no - depends on 192-01, 192-02, 192-05 | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

`nyquist_compliant` remains `false` until these planned Wave 0 verifier dependencies have been executed and their files exist. The unchecked boxes below are not open design gaps; each item names the owning plan and command chain that creates or proves it.

- [ ] Plan 192-01 owns `scripts/ci/verify_phase192_scorecard.mjs`; execute `node scripts/ci/verify_phase192_scorecard.mjs --self-test` and `node --check scripts/ci/verify_phase192_scorecard.mjs`. This verifier validates `final.cells.json`, `scorecard.delta.json`, `regressions.ndjson`, and `artifacts.manifest.json` against strict comparison rules after Plan 192-06 regenerates them from the final evidence workflow.
- [ ] Plan 192-01 owns `scripts/ci/verify_phase192_signoff.mjs`; execute `node scripts/ci/verify_phase192_signoff.mjs --self-test` and `node --check scripts/ci/verify_phase192_signoff.mjs`. This verifier checks `192-SIGN-OFF.md` after Plan 192-05 generates it.
- [ ] Plan 192-02 owns `accrue_admin/e2e/phase192-scorecard.mjs` and package-script wiring; execute `node accrue_admin/e2e/phase192-scorecard.mjs --self-test`, `cd accrue_admin && npm run phase192:scorecard -- --self-test`, and `node accrue_admin/e2e/phase192-scorecard.mjs --dry-run`. The dry-run is the Phase-192-only evidence inventory path used by Plan 192-06 and must not mutate `.planning/phases/187-audit-baseline/*` or write final scorecard artifacts before Plan 192-06.
- [ ] Plan 192-03 owns component-lab structural coverage through `phase192:component-lab`; execute `cd accrue_admin && npm run phase192:component-lab` and `bash scripts/ci/verify_phase192_guardrail_contract.sh`. Plan 192-04 then proves CI wiring with `bash scripts/ci/verify_phase192_ci_contract.sh`.
- [ ] Plan 192-05 owns `accrue_admin/e2e/phase192-gallery.mjs` and `phase192:signoff`; execute `node accrue_admin/e2e/phase192-gallery.mjs --self-test`, `cd accrue_admin && npm run phase192:signoff`, and `node scripts/ci/verify_phase192_signoff.mjs`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Maintainer final screenshot and curated gallery approval | VER-04 | The maintainer must explicitly approve JTBD clarity, brand fit, screenshot evidence, and checklist state | Review `.planning/phases/192-idempotent-verification-sign-off/192-SIGN-OFF.md`, linked gallery rows, artifact manifest refs, and record accept/block outcome in the checklist |
| Subjective brand/microcopy accept/block rows | VER-02, VER-04 | Brand and microcopy lens can use advisory scoring, but final subjective approval requires explicit status and evidence refs | Confirm every subjective row cites deterministic screenshot/trace evidence and has accept/block status |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or named Wave 0 dependencies owned by Plans 192-01 through 192-05.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [ ] Wave 0 covers all missing references through the owner-plan command chain listed above.
- [ ] No watch-mode flags.
- [ ] Feedback latency < one task commit.
- [ ] `nyquist_compliant: true` set in frontmatter after Wave 0 verifier files exist

**Approval:** pending
