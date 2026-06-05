---
phase: 177
slug: d-motion-micro-interaction-design
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-04
---

# Phase 177 — Validation Strategy

> Per-phase validation contract for the motion & micro-interaction work. From RESEARCH.md `## Validation Architecture`.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) + Playwright (`e2e/reduced-motion.spec.js`) |
| **Config file** | `accrue_admin/test/test_helper.exs`; `accrue_admin/e2e/` |
| **Quick run command** | `cd accrue_admin && mix test test/<touched>_test.exs --seed 0` |
| **Full suite command** | `cd accrue_admin && mix test --seed 0` |
| **Reduced-motion e2e** | `cd accrue_admin && npx playwright test e2e/reduced-motion.spec.js` |
| **Estimated runtime** | ~30–60s (ExUnit); e2e longer |

---

## Sampling Rate

- **After every task commit:** focused `mix test` + `mix accrue_admin.assets.build` if CSS/JS changed
- **After every wave:** full suite (stay 252+ green)
- **Before sign-off:** full suite green; assets built no drift; reduced-motion e2e green; antipattern guard green (script + negative-test fixture)
- **Max feedback latency:** ~60s

---

## Per-Task Verification Map

| Area | Requirement | Test Type | What it proves | Automated Command |
|------|-------------|-----------|----------------|-------------------|
| Motion routes through `--ax-transition-*` bundles (no raw ms/curves) | MOT-02 | grep guard | every animated surface uses a bundle/atom, never a literal | antipattern guard in `verify_package_docs.sh` |
| Antipattern guard: ban `transition: all`, raw `cubic-bezier(`, raw `ms`/`s`, layout props | MOT-01 | grep guard + negative test | guard fires on violations | `package_docs_verifier_test.exs` (needle added to BOTH script + `seed_tmp_dir!`) |
| Reduced-motion collapse per new surface (drawer/dropdown/palette) | MOT-03 | Playwright | bundles collapse to instant under `prefers-reduced-motion: reduce`; no transform travel | `npx playwright test e2e/reduced-motion.spec.js` |
| Per-surface motion applied + functional | MOT-02 | LiveView/CSS assertion | surface has the contracted transition class/token | `mix test test/.../<component>_test.exs` + `grep` |
| motion.md spec exists + catalogs all 9 surfaces | MOT-01 | source assertion | doc present with per-element entries | `test -f accrue_admin/guides/motion.md` + grep surface names |
| Regression | all | full suite | 252+ tests stay green | `cd accrue_admin && mix test --seed 0` |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Verify `Phoenix.LiveView.JS` transition API shape against the installed LiveView 1.1 (RESEARCH MEDIUM-confidence item — check before writing JS.transition tuples; mirror step_up_auth_modal.ex).
- [ ] Confirm `e2e/reduced-motion.spec.js` D-15 two-test pattern + `buttonTransitionDurations` helper as the extension template.
- [ ] Locate the guard script (`scripts/ci/verify_package_docs.sh`) + its negative-test fixture (`package_docs_verifier_test.exs` `seed_tmp_dir!/1`) — both get the motion needles in the same commit.

*Existing ExUnit + Playwright infrastructure covers the phase — no framework install.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Motion reads as functional/restrained (not janky/decorative) | MOT-02 | requires watching animation play | Phase 179 Playwright trace/video pass (static PNGs can't see motion) |
| Enter/exit asymmetry feels right | MOT-02 | subjective timing feel | Phase 179 trace review |

*Structural + reduced-motion behaviors are automated; the "does it look good in motion" confirmation is Phase 179's trace pass.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Reduced-motion e2e extended to new surfaces and green
- [ ] Antipattern guard added to BOTH script and negative-test fixture (coupling honored)
- [ ] No watch-mode flags
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
