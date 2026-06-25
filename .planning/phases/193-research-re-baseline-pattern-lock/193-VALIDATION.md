---
phase: 193
slug: research-re-baseline-pattern-lock
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-25
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
| **Quick run command** | `bash scripts/ci/verify_package_docs.sh` (source guards, <5s) |
| **Full suite command** | `cd accrue && mix test` + `npx playwright test` |
| **Estimated runtime** | ~5s (guards) · ~minutes (full mix test + Playwright) |

---

## Sampling Rate

- **After every task commit:** Run `bash scripts/ci/verify_package_docs.sh`
- **After every plan wave:** Run `cd accrue && mix test accrue/test/accrue/docs/package_docs_verifier_test.exs`
- **Before `/gsd-verify-work`:** Full `mix test` green + `verify_package_docs.sh` green + host dev/prod compile tests passing + PoC `button` story renders at `/dev/storybook`
- **Max feedback latency:** ~5s (guard) / minutes (full)

---

## Per-Task Verification Map

| Req ID | Behavior | Test Type | Automated Command / Mechanism | File Exists | Status |
|--------|----------|-----------|-------------------------------|-------------|--------|
| RES-01 | Three spec guides exist with stable anchor headings | source guard | `require_fixed` needles in `verify_package_docs.sh` (e.g. `## SPEC-DETAIL — summary-then-drill`) | guides NEW | ⬜ pending |
| RES-01 | Spec guides wired in `mix.exs` extras + `groups_for_extras` | source guard | `require_fixed "guides/spec-overview.md"` (×3) in `mix.exs` | mix.exs ✅ update | ⬜ pending |
| RES-01 | `PackageDocsVerifierTest` mirrors the new needles | unit | `seed_tmp_dir!` copies 3 spec guide files (D-08 coupling) | ✅ W0 gap | ⬜ pending |
| RES-02 | `baseline.page-flow.cells.json` exists with page-flow cells | file + schema | additive sibling next to `baseline.cells.json`; gated via `regressions.ndjson` | NEW | ⬜ pending |
| RES-02 | Additive baseline folds into zero-regression gate | E2E | `regressions.ndjson` gate stays zero-regression over both baselines | gate ✅ | ⬜ pending |
| RES-03 | Overlay portal hit-test passes the four D-05 proofs | E2E | `accrue_admin/e2e/spike-overlay-portal.spec.js` (`assertTopPointerTarget` etc.) | NEW | ⬜ pending |
| RES-03 | Storybook `data-theme` dark-mode shim activates correct tokens | E2E/manual | Playwright `getComputedStyle` on `.psb-sandbox` in dark mode | NEW | ⬜ pending |
| RES-03 | `inert` browser-floor confirmed + recorded | manual + code comment | decision comment in portal hook source (per RES-03) | NEW | ⬜ pending |
| RES-03 | Storybook assets served (PoC story renders) | E2E/manual | Playwright navigates `/dev/storybook`; `button` story visible | NEW | ⬜ pending |
| RES-04 | Spacing-literal ban blocks raw px in `app.css` | source guard (neg.) | new perl guard in `verify_package_docs.sh` | guard NEW | ⬜ pending |
| RES-04 | `:focus-visible` enforcement guard | source guard | new grep guard | guard NEW | ⬜ pending |
| RES-04 | Truncation-without-`min-width:0` guard | source guard (neg.) | new perl guard | guard NEW | ⬜ pending |
| RES-04 | `PackageDocsVerifierTest` negative tests for the 3 new guards | unit | 3 new cases in `package_docs_verifier_test.exs` | ✅ W0 gap | ⬜ pending |
| STY-01 | `phoenix_storybook` in `mix.exs` `only: [:dev, :test]` | source guard | `require_fixed "accrue_admin/mix.exs" ':phoenix_storybook'` | mix.exs NEW | ⬜ pending |
| STY-01 | `Code.ensure_loaded?(PhoenixStorybook.Router)` guard in router | source guard | `grep -q "Code.ensure_loaded?(PhoenixStorybook.Router)"` | router NEW | ⬜ pending |
| STY-01 | Host dev compile w/ dep absent, no `/dev/storybook` route | compile test | `cd examples/accrue_host && MIX_ENV=dev mix compile` + route assertion | NEW | ⬜ pending |
| STY-01 | Host prod compile w/ dep absent succeeds | compile test | `cd examples/accrue_host && MIX_ENV=prod mix compile` | NEW | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `accrue/test/accrue/docs/package_docs_verifier_test.exs` — add `seed_tmp_dir!` copies for the 3 spec guides (D-08 coupling invariant)
- [ ] `accrue/test/accrue/docs/package_docs_verifier_test.exs` — add 3 negative tests for the new CSS guards (spacing-literal, `:focus-visible`, truncation)
- [ ] `accrue_admin/e2e/spike-overlay-portal.spec.js` — new overlay hit-test spec (4 proofs per D-05)
- [ ] Host-absence compile test — `examples/accrue_host` dev+prod compile assertions
- [ ] `accrue_admin/mix.exs` — extend `elixirc_paths(:dev)` to `["lib", "storybook/_support"]` so `RegistryStory` compiles

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Spec prose reads as higher-signal design contract | RES-01 | Taste/compositional — judged by 12-dim rubric, not lintable | Maintainer reads each spec; confirms machine vs. prose split per D-10/D-11 |
| Page-flow rubric cell scoring (visual hierarchy, density) | RES-02 | Judge-graded dimensions, not deterministic | 12-dim adversarial judge scores new page-flow cells |
| `inert` browser-floor decision rationale | RES-03 | Browser-matrix assumption (A1) | Record decision + fallback (`aria-hidden`+focusguard) in provenance artifact |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < ~5s (guards) per task
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
