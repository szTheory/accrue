---
phase: 174
slug: a-design-system-gap-closure-token-completeness
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-03
---

# Phase 174 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17+) — `accrue_admin` package |
| **Config file** | `accrue_admin/test/test_helper.exs` (existing) |
| **Quick run command** | `cd accrue_admin && mix test test/accrue_admin/dev/component_registry_test.exs` |
| **Full suite command** | `cd accrue_admin && mix test` |
| **Token-bypass guard** | `scripts/ci/verify_package_docs.sh` (grep guard; gains first CSS token needle this phase) + `PackageDocsVerifierTest` negative-seed coupling |
| **Asset build (post-CSS edit)** | `cd accrue_admin && mix accrue_admin.assets.build` then commit `priv/static` |
| **Estimated runtime** | ~30–60 seconds (admin test subset) |

---

## Sampling Rate

- **After every task commit:** Run the quick run command (drift/registry test) + the relevant grep guard
- **After every plan wave:** Run `cd accrue_admin && mix test`
- **Before `/gsd:verify-work`:** Full suite green + `verify_package_docs.sh` exits 0 + asset bundle rebuilt and committed
- **Max feedback latency:** ~60 seconds

---

## Per-Task Verification Map

> Populated by the planner/executor. Source signals (from RESEARCH.md §Validation Architecture):

| Success Criterion | Observable signal that proves it TRUE |
|-------------------|----------------------------------------|
| SC1 — every line-height/letter-spacing/breakpoint/transition value resolves from `ax-*` | Grep guard returns ZERO un-tokenized `line-height:`/`letter-spacing:`/`min-width:`/`max-width:`/multi-line `transition:` literals in `app.css` not registered or token-commented; the new breakpoint needle present in BOTH `verify_package_docs.sh` AND `PackageDocsVerifierTest` seed |
| SC2 — zero inline-hex fallbacks / zero inline styles on dunning + invoice render paths | `grep -rn 'style=' accrue_admin/lib/accrue_admin/components/dunning_banner.ex` returns zero; exhaustive `style=` sweep on invoice surfaces returns zero; banner still renders via `.ax-banner.ax-banner-danger` |
| SC3 — `/dev/components` enumerates every button/badge/status/card variant + token mapping | `ComponentRegistryTest` renders the page, asserts every registry variant appears, asserts registry `ax_class` set == component class outputs (adding a 5th variant without a registry entry fails CI). Must include `Button` `danger` variant |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `accrue_admin/test/accrue_admin/dev/component_registry_test.exs` — drift-prevention test stub for DSY-03 (D-21)
- [ ] New breakpoint/token needle added to `PackageDocsVerifierTest` `seed_tmp_dir!` fixture in the SAME change as the `verify_package_docs.sh` guard needle (verify_package_docs ↔ test coupling)

*Otherwise: existing ExUnit + LiveViewTest infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Light/dark side-by-side token resolution on `/dev/components` reads correctly (D-20) | DSY-03 | Visual fidelity not fully assertable in unit test | Open `/dev/components` in dev; confirm each row shows live swatch + copy-paste `ax-*` class + resolved `--ax-*` tokens in both themes |
| Reduced-motion bundle override collapses transitions (D-15) | DSY-01 | Requires OS-level prefers-reduced-motion | Enable reduced motion; confirm color/shadow cross-fades go instant, transform-lift collapses to 0ms |

*Screenshot regression of `/dev/components` is deferred to Phase F (noted as intent only).*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
