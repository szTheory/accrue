---
phase: 211
slug: grep-gated-css-retirement-cross-surface-cleanup
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-19
---

# Phase 211 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (`mix test`) + Playwright admin e2e (`e2e/`) + PhoenixStorybook specs |
| **Config file** | `accrue_admin/mix.exs` (aliases), `accrue_admin/e2e/` (playwright) |
| **Quick run command** | `cd accrue_admin && mix test` (unit + storybook specs) |
| **Full suite command** | `cd accrue_admin && mix test && <admin e2e gates>` (3 e2e gates per phase 209/210) |
| **Estimated runtime** | ~unit fast; e2e minutes |

---

## Sampling Rate

- **After every task commit:** Run the relevant `grep` census guard + `mix compile`
- **After the deletion wave:** Rebuild the bundle (`mix accrue_admin.assets.build`) + recompose `storybook.css`, then run `mix test`
- **Before phase sign-off:** Full `mix test` + admin e2e suite green; subscription detail page PNG-verified unbroken
- **Max feedback latency:** grep/compile seconds; full e2e minutes

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 211-01-01 | 01 | 1 | REIGN-04 | — | N/A (cleanup phase) | script | `node accrue_admin/e2e/verify-css-census.mjs --self-test` (exit 0) | ❌ W1 (new script) | ⬜ pending |
| 211-01-02 | 01 | 1 | REIGN-04 | — | N/A | script/unit | pre-phase `cd accrue_admin && mix test` baseline captured; guard extraction cross-validated vs RESEARCH.md census | ✅ | ⬜ pending |
| 211-02-01 | 02 | 2 | REIGN-04 | — | N/A | grep | Home/Launcher/Attention/HealthSummary dead families + 5 D-01 adjacent rules gone; live `.ax-home*` rules present (`rg` exact-token) | ✅ | ⬜ pending |
| 211-02-02 | 02 | 2 | REIGN-04 | — | N/A | grep/build | Subscriptions/SubscriptionRow dead families gone; `.ax-subscription-setup-gap` preserved; `mix accrue_admin.assets.build` run; `accrue_admin.css`/`.js` committed | ✅ | ⬜ pending |
| 211-03-01 | 03 | 3 | REIGN-04 | — | N/A | script/unit | `storybook.css` recomposed per D-04 recipe (D-17 shim tail byte-preserved); `npm run phase200:storybook` green | ✅ | ⬜ pending |
| 211-03-02 | 03 | 3 | REIGN-04 | — | N/A | script | `node accrue_admin/e2e/verify-css-census.mjs` against retired `app.css` exits 0; `mix compile` clean | ✅ (post-W1) | ⬜ pending |
| 211-04-01 | 04 | 4 | REIGN-04 | — | N/A | grep | `region-tags.js` `attention-rail` → `[data-ax-zone='attention-rail']`; TODO-marker count decreases by exactly 1 | ✅ | ⬜ pending |
| 211-04-02 | 04 | 4 | REIGN-04 | — | N/A | unit/e2e | `cd accrue_admin && mix test` + `npm run e2e` green; `git diff --stat -- ../accrue/lib` empty; no nav room added | ✅ | ⬜ pending |
| 211-04-03 | 04 | 4 | REIGN-04 | — | Detail page unbroken | manual/e2e | PNG-parity of subscription detail page (light+dark) via `checkpoint:human-verify` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements — `mix test`, the admin e2e gates, and the phase200 storybook specs already exist. No new framework install needed. The only new tooling is the cheap orphan/dangling `ax-*` guard (success criterion 3), which the planner scopes as a small grep-based check reusing repo conventions.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Subscription **detail** page renders unbroken after retirement | REIGN-04 | Visual/layout regression on preserved shared classes is invisible to source-text CI | Load `/admin` subscription detail route, capture PNG, compare against pre-retirement baseline; confirm `.ax-inline-worklist*` / `.ax-audit-summary-row` render intact |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify (grep census / bundle guard / storybook spec / e2e) or a documented manual PNG check
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (none — existing infra)
- [ ] No watch-mode flags
- [ ] Feedback latency acceptable (grep/compile seconds)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-07-19
