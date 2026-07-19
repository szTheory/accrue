---
phase: 208
slug: prove-convergence-on-the-representative-slice-wire-ci-accept
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-07
---

# Phase 208 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: 208-RESEARCH.md `## Validation Architecture`. The deterministic CI
> plane must stay key-free, non-mutating, and fixture-provable; live convergence
> remains a local maintainer action before freeze and ACCEPT.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Node script self-tests, ExUnit/Mix task tests, and shell workflow contract checks |
| **Config file** | `accrue_admin/package.json`, `accrue_admin/mix.exs`, `.github/workflows/ci.yml` |
| **Quick run command** | `cd accrue_admin && npm run ratchet:ledger:self-test && npm run ratchet:digest:self-test && node e2e/ratchet/ratchet-fix.mjs --self-test && node e2e/ratchet/ratchet-guard-mint.mjs --self-test` |
| **Full suite command** | `cd accrue_admin && npm run ratchet:ledger:self-test && npm run ratchet:digest:self-test && node e2e/ratchet/ratchet-fix.mjs --self-test && node e2e/ratchet/ratchet-guard-mint.mjs --self-test && mix test test/mix/tasks/accrue_admin_ui_round_test.exs test/mix/tasks/accrue_admin_ui_fix_test.exs` |
| **Estimated runtime** | ~30 seconds for deterministic local checks; live convergence round is manual/local and not part of CI |

---

## Sampling Rate

- **After every task commit:** Run the relevant Node `--self-test`, shell contract script, or `mix test <specific file>` for the files touched.
- **After every plan wave:** Run the full suite command plus any new Phase 208 verifier self-tests created in that wave.
- **Before `/gsd:verify-work`:** Full suite green, deterministic CI contract verifier green, sign-off verifier green, read-only frozen-baseline verifier green, existing UI guardrails green, and asset freshness verified.
- **Max feedback latency:** ~30 seconds for deterministic checks.

---

## Per-Task Verification Map

Requirement-level map (per-task IDs filled by the planner). `W0` means the phase must create or extend the test/verifier before relying on it.

| Req ID | Behavior | Test Type | Automated Command | File Exists | Status |
|--------|----------|-----------|-------------------|-------------|--------|
| CONV-01 | Foundation slice has two dry rounds, zero regressions, and all scoped cells have `score >= 2` | unit/integration plus local convergence | New score-floor verifier or ledger self-test, plus `mix accrue_admin.ui.round --slice foundation` for real convergence | Partial; score-floor verifier is W0 | pending |
| CONV-02 | `ledger.baseline.json` is frozen and materially non-placeholder | unit/self-test | New `verify_ratchet_ledger.mjs --verify-frozen` mode or wrapper fixture | W0 | pending |
| CONV-03 | `admin-ui-ratchet-guardrails` passes without a key and blocks synthetic ledger count increase | unit/CI contract | `npm run ratchet:ledger:self-test` plus `bash scripts/ci/verify_admin_ui_ratchet_ci_contract.sh` | W0 | pending |
| CONV-04 | A persona/lens count increase fails even when another persona improves | unit/self-test | New scratch fixture in the ledger verifier or `phase-ratchet-ledger.mjs --self-test` | W0 | pending |
| CONV-05 | Existing UI gates remain green and `accrue_admin.css` stays fresh | CI/smoke | Existing `admin-hardening-guardrails`, `admin-phase200-guardrails`, and asset diff checks | Exists; sign-off evidence is W0 | pending |
| CONV-06 | `UI-RATCHET-SIGN-OFF.md` has exactly one maintainer `ACCEPT` line and required evidence | unit/self-test | `node scripts/ci/verify_ui_ratchet_signoff.mjs --require-accept` | W0 | pending |
| CONV-07 | Follow-on runbook has required headings, bounded language, recovery steps, and artifact refs | unit/self-test | `node scripts/ci/verify_ui_ratchet_signoff.mjs --require-accept` | W0 | pending |

---

## Wave 0 Requirements

- [ ] `scripts/ci/verify_ui_ratchet_signoff.mjs` with fixtures for missing sections, invalid status tokens, missing or duplicate `ACCEPT`, placeholder baseline, non-empty regressions, missing runbook headings, forbidden full-sweep language, and invalid artifact references.
- [ ] `scripts/ci/verify_admin_ui_ratchet_ci_contract.sh` enforcing the stable `admin-ui-ratchet-guardrails` job id/name, no-key/no-secret/no-mutating-command constraints, artifacts/summaries, and annotation-sweep wiring.
- [ ] Read-only frozen-baseline verification mode or wrapper around `scripts/ci/verify_ratchet_ledger.mjs`.
- [ ] Score-floor enforcement helper that maps representative slice surfaces to Phase 200 cell census rows and requires `score >= 2`.
- [ ] Scratch fixture tests for synthetic count increase and cross-persona/lens regression.
- [ ] `UI-RATCHET-SIGN-OFF.md` with UI-SPEC sections, evidence rows, runbook headings, and the final maintainer `ACCEPT` line.

*Framework install: none. Use the existing Node, shell, ExUnit, and package-script patterns.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real representative-slice convergence | CONV-01 | Requires local browser capture and LLM-assisted round/fix loop, which must not run in deterministic CI | Run `cd accrue_admin && mix accrue_admin.ui.round --slice foundation` until the ledger reports `CONVERGED (2 dry rounds)`; preserve the committed evidence rows and regression files |
| Explicit baseline freeze | CONV-02 | Freeze is a locked local maintainer act, never a CI side effect | After deterministic preflight passes, run `cd accrue_admin && node e2e/ratchet/phase-ratchet-ledger.mjs --freeze`, then run the read-only frozen-baseline verifier |
| Maintainer acceptance | CONV-06 | The final `ACCEPT` line is the human decision surface | Update `UI-RATCHET-SIGN-OFF.md` with one final `ACCEPT` line only after the verifier evidence is green |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all missing deterministic verifier references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s for deterministic checks
- [ ] `nyquist_compliant: true` set in frontmatter once mapped checks are green

**Approval:** pending
