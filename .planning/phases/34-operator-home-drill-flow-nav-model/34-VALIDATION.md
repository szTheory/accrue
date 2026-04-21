---
phase: 34
slug: operator-home-drill-flow-nav-model
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-21
---

# Phase 34 — Validation strategy

> Per-phase validation contract. Update after `34-*-PLAN.md` waves exist.

---

## Test infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (`accrue`, `accrue_admin`) + host Playwright where VERIFY-01 already covers mounted admin |
| **Quick run command** | TBD after plans (expect `mix test` scoped paths + optional `cd examples/accrue_host && mix verify` slices) |
| **Full suite command** | Repository default CI path for touched apps |

---

## Wave 0

Plans materialized (`34-01`..`34-03`). Update per-wave checks as execution completes.

| Plan | Wave | Automated checks |
|------|------|------------------|
| 34-01 | 1 | `mix test test/accrue_admin/scoped_path_test.exs`, `navigation_components_test.exs`, `mix accrue_admin.assets.build`, `mix compile --warnings-as-errors` |
| 34-02 | 2 (after 01) | `mix test` (package scope as in plan), `mix compile --warnings-as-errors` |
| 34-03 | 1 | `mix test test/accrue_admin/nav_test.exs`, `navigation_components_test.exs` |

Set `nyquist_compliant: true` and `wave_0_complete: true` after all plan tasks have a mapped check and summaries exist.

---

## Manual-only (expected)

| Behavior | Requirement | Why manual |
|----------|-------------|------------|
| First-open operator value | OPS-01 | Human judgment on information density vs noise |
| Drill smoothness | OPS-02 | Compare baseline vs improved path on real fixture data |
