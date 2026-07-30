---
phase: 210-reign-home-certify-answer-first-ia-copy-integrity
plan: 01
subsystem: accrue_admin
tags: [copy, ia, home-reign, copy-strings]
requires: []
provides:
  - "AccrueAdmin.Copy.dashboard_health_verdict_healthy/0"
  - "AccrueAdmin.Copy.dashboard_health_verdict_action_required/0"
  - "AccrueAdmin.Copy.home_attention_priority_heading/0"
  - "AccrueAdmin.Copy.home_customer_search_cta/0"
  - "examples/accrue_host/e2e/generated/copy_strings.json (regenerated)"
affects:
  - "dashboard_live.ex (Plan 02) — sources every Home operator string from Copy"
  - "dashboard_live_test.exs (Plan 03) — asserts against these Copy fns"
tech-stack:
  added: []
  patterns:
    - "Copy SSOT: operator strings live as 0-arity AccrueAdmin.Copy defs, exported to copy_strings.json"
    - "Verdict-language parity: Home reuses Subscriptions' exact literals (Healthy / Action required)"
key-files:
  created: []
  modified:
    - "accrue_admin/lib/accrue_admin/copy.ex"
    - "accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex"
    - "examples/accrue_host/e2e/generated/copy_strings.json"
decisions:
  - "home_launcher_recovery_meta de-jargoned to 'At-risk accounts' (static literal; UI-SPEC frames the dynamic count in the recomposed tile)"
  - "home_intro_copy 'customer workspace' → 'customer queue' — de-jargoned to pass the plan's own no-workspace verify gate (COPY-01 'no workspace jargon everywhere')"
  - "Added the 4 new Copy fns to export_copy_strings @allowlist so they land in copy_strings.json (Task 2 acceptance requires their presence)"
metrics:
  duration: ~8m
  completed: 2026-07-19
status: complete
---

# Phase 210 Plan 01: Home Reign Copy Pass Summary

Landed the plain-language copy pass for the Home reign in `AccrueAdmin.Copy` — four new verdict/heading/customer-lookup defs (verdict language identical to Subscriptions Phase 209) plus de-jargoning of every "workspace" literal — and regenerated the committed `copy_strings.json` so Plan 02's `dashboard_live.ex` recomposition can source every Home operator string from Copy.

## What Was Built

**Task 1 — Copy strings (COPY-01/COPY-02):**
- Added `dashboard_health_verdict_healthy/0` → "Healthy" and `dashboard_health_verdict_action_required/0` → "Action required" (exact literals reused from `copy/subscription.ex` for cross-page verdict parity).
- Added `home_attention_priority_heading/0` → "Priority exceptions" (migrates the inline literal formerly at `dashboard_live.ex` L471) and `home_customer_search_cta/0` → "Find a customer" (sentence case; distinct from the untouched `home_search_customers_title` = "Find one customer").
- De-jargoned (fn name/arity unchanged, only the returned literal): `home_launcher_invoices_title` → "Invoice queue", `home_launcher_recovery_meta` → "At-risk accounts", `dashboard_kpi_invoices_aria_label` → "Open invoice queue", `dashboard_kpi_open_invoice_balance_meta` → "Opens the invoice queue for current receivables", plus `home_intro_copy` ("customer workspace" → "customer queue").
- Wired the 4 new fns into the `export_copy_strings` `@allowlist`.

**Task 2 — Regenerate artifact:**
- Ran `mix accrue_admin.export_copy_strings --out ../examples/accrue_host/e2e/generated/copy_strings.json` (96 strings). The 4 new strings resolve through Copy and appear in the JSON; no "invoice queue workspace" / "recovery workspace" strings remain.

## Verification

- `mix compile --warnings-as-errors` clean in accrue_admin.
- Task 1 no-workspace-jargon grep gate: PASS (no surviving "workspace" in any home_/dashboard_/invoice/recovery string).
- No SHOUTING (all-caps) word in any added/renamed Home string.
- copy_strings.json shows as changed in git, produced by the mix task (not hand-edited), and contains "Find a customer" / "Healthy" / "Action required" / "Priority exceptions".

## Deviations from Plan

### Auto-fixed / auto-added

**1. [Rule 3 - Blocking] Export allowlist did not include the new Copy fns**
- **Found during:** Task 2 setup.
- **Issue:** `export_copy_strings` exports only an explicit `@allowlist`; none of the new `dashboard_*`/`home_*` fns were listed, so they would not appear in `copy_strings.json` — failing Task 2's acceptance criteria.
- **Fix:** Added the 4 new function names to the `@allowlist`.
- **Files modified:** `accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex`.
- **Commit:** 0daaadae.

**2. [Rule 2 - Copy integrity] Extra "workspace" literal in `home_intro_copy`**
- **Found during:** Task 1 verification.
- **Issue:** The plan enumerated four defs to de-jargon, but `home_intro_copy` also contained "customer workspace"; the plan's own Task 1 verify command (`test -z ...invoice|recovery|home_|dashboard_`) matched it and would fail, and COPY-01/UI-SPEC require dropping "workspace" jargon everywhere it appears.
- **Fix:** "customer workspace" → "customer queue" (meaning preserved).
- **Files modified:** `accrue_admin/lib/accrue_admin/copy.ex`.
- **Commit:** 0daaadae.

## Known Stubs

None — this plan only edits a compile-time string module and a generated test fixture.

## Commits

- `0daaadae` — feat(210-01): add Home reign Copy strings + de-jargon workspace literals
- `7d551019` — chore(210-01): regenerate copy_strings.json for Home reign strings

## Self-Check: PASSED
