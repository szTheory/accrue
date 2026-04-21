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

Planning materialized; **no plans executed yet.** Set `nyquist_compliant: true` and `wave_0_complete: true` once `34-VALIDATION.md` maps every plan task to an automated or explicit manual check.

---

## Manual-only (expected)

| Behavior | Requirement | Why manual |
|----------|-------------|------------|
| First-open operator value | OPS-01 | Human judgment on information density vs noise |
| Drill smoothness | OPS-02 | Compare baseline vs improved path on real fixture data |
