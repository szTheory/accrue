# Phase 53: auxiliary-admin-connect-events-layout-verify - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`53-CONTEXT.md`**.

**Date:** 2026-04-22  
**Phase:** 53 — auxiliary-admin-connect-events-layout-verify  
**Areas discussed:** VERIFY-01 inventory (AUX-06), Destructive Connect UX, Copy naming, export_copy_strings pipeline  
**Mode:** User selected **all** areas; research via parallel subagents; synthesizer locked coherent recommendations.

---

## VERIFY-01 inventory (AUX-06 vs UI-SPEC)

| Option | Description | Selected |
|--------|-------------|----------|
| A — Connect + events only | Smallest CI; risks under-reading AUX-06 | |
| B — Full URL matrix for AUX-01..04 | Strongest breadth; fights Phase 50 D-19; flake/maintenance cost | |
| C — Hybrid | Connect+events deep paths per UI-SPEC + **one blocking journey each** coupon/promo to close Phase 52 deferral; flow-based not crawl | ✓ |

**User's choice:** Hybrid (delegated to research synthesis).  
**Notes:** Idiomatic split: **ExUnit** in `accrue_admin` + **Playwright+axe** in host; document spec → AUX mapping.

---

## Destructive Connect (deauthorize)

| Option | Description | Selected |
|--------|-------------|----------|
| A — Copy-only / dormant | Low scope; risk if copy implies live control | |
| B — Full affordance + host opt-in | Correct when capability + authz + domain command exist | |
| C — Defer live affordance | Read-only / safe guidance this phase; no surprise platform controls | ✓ |

**User's choice:** Defer live wiring; align with Pay/Cashier/host-owned danger.  
**Notes:** Modal copy in UI-SPEC treated as **reserved** until a future gated phase.

---

## Copy module & function prefixes

| Option | Description | Selected |
|--------|-------------|----------|
| Bare `event_*` / `events_*` | Short; high grep/cognitive collision with LiveView “event” | |
| `connect_*` only | Underspecifies list vs detail | |
| **Plural/singular resource prefixes + `BillingEvent` module** | `connect_accounts_*` / `connect_account_*`; `billing_events_*` / `billing_event_*`; modules **`Copy.Connect`**, **`Copy.BillingEvent`** | ✓ |

**User's choice:** Resource + cardinality prefixes + **`Copy.BillingEvent`**.  
**Notes:** UI-SPEC updated **`Copy.Event` → `Copy.BillingEvent`** for consistency.

---

## export_copy_strings vs Playwright

| Option | Description | Selected |
|--------|-------------|----------|
| Spec-first literals | Fast red; drift / footgun vs D-23 | |
| CI-only JSON (uncommitted) | Fewer conflicts; worse local DX and review | |
| **Copy-first pipeline** | Copy → allowlist → export → Playwright → commit Elixir+JSON; matches CI script order | ✓ |

**User's choice:** Copy-first as single contributor rule; CI follows `accrue_host_verify_browser.sh`.  
**Notes:** Optional **`git diff --exit-code`** on JSON left to maintainer discretion.

---

## Claude's discretion

- Per-path **critical affordance** selection within hybrid VERIFY scope.  
- Optional **strict golden** JSON diff gate in CI.

## Deferred ideas

- Live **deauthorize** UI + reconciliation + host capability contract — future phase.  
- Optional **`git diff`** on `copy_strings.json` — hygiene follow-up.
