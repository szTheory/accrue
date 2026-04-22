---
phase: 42
slug: operator-runbooks
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-21
---

# Phase 42 — Validation Strategy

Operator-facing documentation for **RUN-01**. Concrete checks to be filled after planning.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Primary gate** | Doc review + optional ExUnit on runbook strings if contracts are added |
| **Quick run command** | `cd accrue && mix test` (if string/contract tests ship) |
| **Full suite command** | `cd accrue && mix test` |

## Coverage targets (draft)

- Every **RUN-01** ops class has a runbook entry with first action and Stripe/Oban pointers.
- No duplicate Stripe Dashboard accounting UI; links out where appropriate.
