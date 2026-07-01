---
phase: 193
slug: research-re-baseline-pattern-lock
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-25
updated: 2026-06-30
---

# Phase 193 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `193-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework (Elixir)** | ExUnit (`mix test`) |
| **Framework (E2E)** | Playwright (`mix accrue_admin.e2e.server` + `npx playwright test`) |
| **Config file** | `accrue_admin/playwright.config.js` |
| **Quick run command** | `bash scripts/ci/verify_package_docs.sh` |
| **Focused package-doc tests** | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` |
| **Focused Storybook tests** | `cd accrue_admin && mix test test/accrue_admin/dev/storybook_asset_test.exs test/accrue_admin/dev/storybook_coverage_test.exs` |
| **Focused browser tests** | `cd accrue_admin && npx playwright test e2e/spike-overlay-portal.spec.js --reporter=line --workers=1` + `cd accrue_admin && npx playwright test e2e/admin-storybook-a11y-phase200.spec.js --reporter=line --workers=1` |
| **Union scorecard verifier** | `node scripts/ci/verify_phase200_scorecard.mjs --baseline-only` + `node scripts/ci/verify_phase200_scorecard.mjs` |
| **Host isolation checks** | `cd examples/accrue_host && MIX_ENV=dev mix compile`; `MIX_ENV=prod mix compile`; `MIX_ENV=dev mix phx.routes 2>&1 \| grep storybook \| wc -l` |
| **Estimated runtime** | ~5s guards · ~30s focused ExUnit · ~15s focused browser · ~60s scorecard |

---

## Sampling Rate

- **After every task commit:** Run `bash scripts/ci/verify_package_docs.sh`
- **After every plan wave:** Run `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs`
- **Before `/gsd-verify-work`:** Full `mix test` green + `verify_package_docs.sh` green + host dev/prod compile tests passing + PoC `button` story renders at `/dev/storybook`
- **Max feedback latency:** ~5s (guard) / minutes (full)

---

## Per-Task Verification Map

| Req ID | Plan | Behavior | Test Type | Automated Command / Mechanism | Evidence File(s) | Status |
|--------|------|----------|-----------|-------------------------------|------------------|--------|
| RES-01 | 193-01, 193-05 | Three spec guides exist with stable anchor headings | source guard | `bash scripts/ci/verify_package_docs.sh` checks `## SPEC-OVERVIEW —`, `## SPEC-LIST —`, and `## SPEC-DETAIL — summary-then-drill` | `scripts/ci/verify_package_docs.sh`; `accrue_admin/guides/spec-*.md` | green |
| RES-01 | 193-01, 193-05 | Spec guides wired in `mix.exs` extras + `groups_for_extras` | source guard | `bash scripts/ci/verify_package_docs.sh` checks the three guide paths in `accrue_admin/mix.exs` | `scripts/ci/verify_package_docs.sh`; `accrue_admin/mix.exs` | green |
| RES-01 | 193-05 | `PackageDocsVerifierTest` mirrors the new needles | unit | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` | `accrue/test/accrue/docs/package_docs_verifier_test.exs` | green |
| RES-02 | 193-02 | `baseline.page-flow.cells.json` exists with page-flow cells | file + schema | Node schema/count check: 9,072 p193 rows, 21 surfaces, all `surface_type: "page-flow"`, all required fields present | `.planning/milestones/v1.53-phases/187-audit-baseline/baseline.page-flow.cells.json` | green |
| RES-02 | 193-02, 200-03/06 | Additive baseline folds into zero-regression gate | scorecard verifier | `node scripts/ci/verify_phase200_scorecard.mjs --baseline-only` and full verifier. Phase 200 union baseline contains 30,348 rows = 21,276 p187 + 9,072 p193; full verifier reports 0 regressions. | `.planning/phases/200-idempotent-verification-sign-off/baseline.union.cells.json`; `scripts/ci/verify_phase200_scorecard.mjs` | green |
| RES-03 | 193-03 | Overlay portal hit-test passes the four D-05 proofs | E2E | `cd accrue_admin && npx playwright test e2e/spike-overlay-portal.spec.js --reporter=line --workers=1` | `accrue_admin/e2e/spike-overlay-portal.spec.js` | green |
| RES-03 | 193-04, 200-02 | Storybook dark-mode shim activates in rendered Storybook | E2E | `cd accrue_admin && npx playwright test e2e/admin-storybook-a11y-phase200.spec.js --reporter=line --workers=1` scans settled light/dark Storybook modes. | `accrue_admin/priv/static/storybook.css`; `accrue_admin/e2e/admin-storybook-a11y-phase200.spec.js` | green |
| RES-03 | 193-04 | `inert` browser-floor confirmed + recorded | source decision | Recorded in `storybook.ex` and `registry_story.ex`; browser-floor support remains manual/source-reviewed rather than a deterministic behavior test. | `accrue_admin/lib/accrue_admin/dev/storybook.ex`; `accrue_admin/storybook/_support/registry_story.ex` | manual |
| RES-03 | 193-04, 200-01/02 | Storybook assets served and PoC/registry stories render | unit + E2E | `cd accrue_admin && mix test test/accrue_admin/dev/storybook_asset_test.exs test/accrue_admin/dev/storybook_coverage_test.exs`; Storybook E2E above | `accrue_admin/test/accrue_admin/dev/storybook_asset_test.exs`; `storybook/components/button.story.exs` | green |
| RES-04 | 193-05 | Spacing-literal ban blocks raw px spacing in `app.css` | source guard + negative test | `bash scripts/ci/verify_package_docs.sh`; package-doc ExUnit negative test rejects planted `padding: 16px` | `scripts/ci/verify_package_docs.sh`; `package_docs_verifier_test.exs` | green |
| RES-04 | 193-05 | `:focus-visible` enforcement guard | source guard + negative test | `bash scripts/ci/verify_package_docs.sh`; package-doc ExUnit negative test rejects planted bare `:focus` | `scripts/ci/verify_package_docs.sh`; `package_docs_verifier_test.exs` | green |
| RES-04 | 193-05 | Truncation-without-`min-width:0` guard | source guard + negative test | `bash scripts/ci/verify_package_docs.sh`; package-doc ExUnit negative test rejects planted ellipsis without `min-width:0` | `scripts/ci/verify_package_docs.sh`; `package_docs_verifier_test.exs` | green |
| RES-04 | 193-05 | `PackageDocsVerifierTest` negative tests for the 3 new guards | unit | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` | `accrue/test/accrue/docs/package_docs_verifier_test.exs` | green |
| STY-01 | 193-01, 193-05 | `phoenix_storybook` in `mix.exs` scoped to `only: [:dev, :test]` | source guard + unit | `bash scripts/ci/verify_package_docs.sh`; `storybook_asset_test.exs` asserts exact dep scope | `accrue_admin/mix.exs`; `accrue_admin/test/accrue_admin/dev/storybook_asset_test.exs` | green |
| STY-01 | 193-04, 193-05 | `Code.ensure_loaded?(PhoenixStorybook.Router)` guard in router | source guard + unit | `bash scripts/ci/verify_package_docs.sh`; `storybook_asset_test.exs` verifies dev-only asset routes are absent from prod-like routers | `accrue_admin/lib/accrue_admin/router.ex`; `storybook_asset_test.exs` | green |
| STY-01 | 193-04 | Host dev compile with dep absent, no `/dev/storybook` route | compile + route assertion | `cd examples/accrue_host && MIX_ENV=dev mix compile`; `MIX_ENV=dev mix phx.routes 2>&1 \| grep storybook \| wc -l` -> 0 | `examples/accrue_host` | green |
| STY-01 | 193-04 | Host prod compile with dep absent succeeds | compile test | `cd examples/accrue_host && MIX_ENV=prod mix compile` | `examples/accrue_host` | green |

*Status values: green · manual*

---

## Wave 0 Requirements

- [x] `accrue/test/accrue/docs/package_docs_verifier_test.exs` — added `seed_tmp_dir!` copies for the 3 spec guides (D-08 coupling invariant)
- [x] `accrue/test/accrue/docs/package_docs_verifier_test.exs` — added 3 negative tests for the new CSS guards (spacing-literal, `:focus-visible`, truncation)
- [x] `accrue_admin/e2e/spike-overlay-portal.spec.js` — added overlay hit-test spec (4 proofs per D-05)
- [x] Host-absence compile test — `examples/accrue_host` dev+prod compile assertions pass
- [x] `accrue_admin/mix.exs` — extended `elixirc_paths(:dev)` and `:test` with `storybook/_support`; current compiled helper lives at `accrue_admin/storybook/_support/registry_story.ex`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions | Status |
|----------|-------------|------------|-------------------|--------|
| Spec prose reads as higher-signal design contract | RES-01 | Taste/compositional — judged by 12-dim rubric, not lintable | Maintainer reads each spec; confirms machine vs. prose split per D-10/D-11 | retained manual-only |
| Page-flow rubric cell scoring (visual hierarchy, density) | RES-02 | Judge-graded dimensions are not deterministic source assertions | Phase 200 judge/sign-off owns final rubric scoring; deterministic verifier enforces p193 closure and zero regressions | completed in Phase 200 sign-off |
| `inert` browser-floor decision rationale | RES-03 | Browser support assumption can age; source records the decision but cannot prove future browser floors | Review support matrix when target browser floor changes; fallback remains `aria-hidden` + focus guard | retained manual-only |

---

## Validation Sign-Off

- [x] All tasks have automated verify or explicit manual-only rationale
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 gaps were filled by Phase 193 execution
- [x] No watch-mode flags
- [x] Feedback latency < ~5s for source guards; focused ExUnit/browser checks available for higher-risk rows
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated by audit on 2026-06-30

---

## Validation Audit 2026-06-30

| Metric | Count |
|--------|-------|
| Stale pending rows found | 17 |
| Automated rows green | 16 |
| Manual-only rows retained | 2 |
| Test files generated | 0 |
| Implementation files changed | 0 |

Focused verification rerun:

| Command | Result |
|---------|--------|
| `bash scripts/ci/verify_package_docs.sh` | passed |
| `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` | 33 tests, 0 failures |
| `cd accrue_admin && mix test test/accrue_admin/dev/storybook_asset_test.exs test/accrue_admin/dev/storybook_coverage_test.exs` | 7 tests, 0 failures |
| `cd examples/accrue_host && MIX_ENV=dev mix compile` | passed |
| `cd examples/accrue_host && MIX_ENV=prod mix compile` | passed |
| `cd examples/accrue_host && MIX_ENV=dev mix phx.routes 2>&1 \| grep storybook \| wc -l` | 0 |
| `node scripts/ci/verify_phase200_scorecard.mjs --baseline-only` | passed; baseline 30,348 |
| `node scripts/ci/verify_phase200_scorecard.mjs` | passed; final 30,348, regressions 0 |
| `cd accrue_admin && npx playwright test e2e/spike-overlay-portal.spec.js --reporter=line --workers=1` | 8 passed |
| `cd accrue_admin && npx playwright test e2e/admin-storybook-a11y-phase200.spec.js --reporter=line --workers=1` | 3 passed, 1 skipped |
