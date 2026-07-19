---
phase: 211
slug: grep-gated-css-retirement-cross-surface-cleanup
status: draft
nyquist_compliant: false
wave_0_complete: false
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

> Filled by the planner. Each retirement/rebuild/cleanup task maps to a grep census assertion,
> a bundle-guard assertion, a storybook-spec-green assertion, or a PNG-parity check.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 211-XX-XX | XX | X | REIGN-04 | — | N/A (cleanup phase) | grep/build/e2e | `{command}` | ✅ | ⬜ pending |

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
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
