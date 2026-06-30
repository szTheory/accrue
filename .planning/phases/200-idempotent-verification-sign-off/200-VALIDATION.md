---
phase: 200
slug: idempotent-verification-sign-off
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-30
---

# Phase 200 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit/Mix 1.19.5 for Phoenix tests; Playwright 1.59.1 for browser tests; Node.js 22.14.0 for artifact verifiers |
| **Config file** | `accrue_admin/playwright.config.js`; `accrue_admin/config/test.exs`; `accrue_admin/package.json` |
| **Quick run command** | `cd accrue_admin && mix test test/accrue_admin/dev/component_registry_test.exs test/accrue_admin/dev/component_group_registry_test.exs` |
| **Full suite command** | `cd accrue_admin && bash scripts/ci/verify_phase200_admin_guardrails.sh` after Wave 0 creates it |
| **Estimated runtime** | Unknown until Wave 0 guardrail script exists; keep focused task checks under 120 seconds where practical |

---

## Sampling Rate

- **After every task commit:** Run the focused ExUnit, Node verifier, or Playwright file touched by the task.
- **After every plan wave:** Run the Phase 200 guardrail subset for that wave plus existing registry/group/reduced-motion/Phase 199 suites.
- **Before `/gsd:verify-work`:** Run the full deterministic Phase 200 guardrails, regenerate scorecard artifacts, run the bounded judge flow, then verify `200-SIGN-OFF.md`, `.planning/REQUIREMENTS.md`, and `.planning/STATE.md`.
- **Max feedback latency:** 120 seconds for focused checks; full closeout may exceed this only for the final scorecard/browser matrix.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 200-W0-01 | TBD | 0 | STY-02 | T-200-01 | Storybook routes stay dev/test-only while registry remains the single source of truth | ExUnit + Storybook smoke | `cd accrue_admin && mix test test/accrue_admin/dev/storybook_coverage_test.exs` | No - W0 | pending |
| 200-W0-02 | TBD | 0 | STY-03 | T-200-02 | Storybook loads committed admin assets and dark-mode shim without adopter runtime leakage | ExUnit + Playwright | `cd accrue_admin && env -u NO_COLOR npx playwright test e2e/admin-storybook-a11y-phase200.spec.js --workers=1` | No - W0 | pending |
| 200-W0-03 | TBD | 0 | VER-01 | T-200-03 | Baselines are read-only and Phase 200 artifacts are generated under the Phase 200 directory | Node verifier | `cd accrue_admin && node scripts/ci/verify_phase200_scorecard.mjs` | No - W0 | pending |
| 200-W0-04 | TBD | 0 | VER-02 | T-200-04 | Accessibility/theme/browser checks exercise rendered routes and stories without bypassing production theme boot for persistence proof | Playwright + ExUnit | `cd accrue_admin && bash scripts/ci/verify_phase200_admin_guardrails.sh` | No - W0 | pending |
| 200-W0-05 | TBD | 0 | VER-03 | T-200-05 | Final sign-off cannot be ACCEPT while regressions, unresolved blocking judge findings, stale requirements, or pending human state remain | Node verifier + manual checkpoint | `cd accrue_admin && node scripts/ci/verify_phase200_signoff.mjs` | No - W0 | pending |

---

## Wave 0 Requirements

- [ ] `accrue_admin/test/accrue_admin/dev/storybook_coverage_test.exs` - dynamic STY-02 coverage for every `ComponentRegistry` family and group contract.
- [ ] `accrue_admin/test/accrue_admin/dev/storybook_asset_test.exs` or extension to `assets_test.exs` - STY-03 committed `storybook.css`/`storybook.js` asset routing and dev/test boundary coverage.
- [ ] `accrue_admin/e2e/admin-storybook-a11y-phase200.spec.js` - rendered Storybook story axe/theming scan for STY-03 and VER-02.
- [ ] `accrue_admin/e2e/admin-page-flow-phase200.spec.js` - page-flow final evidence, settled light/dark route axe, and no-FOUC/theme checks for VER-01/VER-02.
- [ ] `accrue_admin/e2e/phase200-scorecard.mjs` - Phase 200 union/final/delta/regressions artifact generator.
- [ ] `accrue_admin/scripts/ci/verify_phase200_scorecard.mjs` - deterministic VER-01 verifier.
- [ ] `accrue_admin/scripts/ci/verify_phase200_signoff.mjs` - deterministic VER-03 final status verifier.
- [ ] `accrue_admin/scripts/ci/verify_phase200_admin_guardrails.sh` - deterministic CI orchestration for VER-02/STY-02/STY-03.
- [ ] `.github/workflows/*` update - call deterministic Phase 200 guardrails without model-dependent or human gates.

*Existing infrastructure partially covers registry/group contracts, reduced-motion, route axe, and Phase 199 interactions; Wave 0 closes Phase 200-specific gaps.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Maintainer photographic/interaction checkpoint | VER-03 | Human ACCEPT/REJECT is an explicit final-boundary requirement and cannot be automated away | Review `200-SCORECARD.md`, `200-STORYBOOK-COVERAGE.md`, judge findings, curated screenshots/traces, and final artifacts; write exactly one final decision line in `200-SIGN-OFF.md` |

---

## Validation Sign-Off

- [ ] All tasks have automated verify commands or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without an automated verify command.
- [ ] Wave 0 covers all missing references listed above.
- [ ] No watch-mode flags.
- [ ] Focused feedback latency stays below 120 seconds where practical.
- [ ] `nyquist_compliant: true` set in frontmatter after Wave 0 is complete and mapped into PLAN.md tasks.

**Approval:** pending
