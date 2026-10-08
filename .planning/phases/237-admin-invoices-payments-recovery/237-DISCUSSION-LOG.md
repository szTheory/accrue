# Phase 237: Admin Invoices, Payments & Recovery - Discussion Log

> **Audit trail only.** Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-08
**Phase:** 237-Admin Invoices, Payments & Recovery
**Areas discussed:** Invoice state, amounts, and missing data; Payment action review and result evidence; Recovery window, currency, and return context

Auto mode selected all identified areas and the user instructed us to follow the recommendation. The recommended defaults were derived from the roadmap, prior Admin decisions, and existing source contracts.

---

## Invoice state, amounts, and missing data

| Option | Description | Selected |
|--------|-------------|----------|
| Derive overdue from an open invoice plus a known passed due date | Preserve stored status and show overdue only as a collection fact when its due date has passed. | ✓ Recommended |
| Display only stored processor statuses | Avoid derived overdue facts even when an open invoice has a known passed due date. | |

| Option | Description | Selected |
|--------|-------------|----------|
| Exact currency-aware formatting and unknown money unavailable | Keep minor-unit precision and show missing/unsupported amount or currency as unavailable. | ✓ Recommended |
| Fall back to the configured currency or a zero amount | Display a guessed currency or value when the billing record lacks that evidence. | |

## Payment action review and result evidence

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse staged review-confirm flow with exact action consequences | Review exact target, action, amount, currency, consequence, and current eligibility before confirmation. | ✓ Recommended |
| Introduce a new universal confirmation layer | Add a common confirmation mechanism across the entire Admin surface. | |

| Option | Description | Selected |
|--------|-------------|----------|
| Map outcomes to actual evidence and preserve uncertainty | Distinguish accepted, requires-action, failed, and completed where supported; keep ambiguity unconfirmed and avoid blind retries. | ✓ Recommended |
| Reduce outcomes to a generic success or failure notice | Collapse provider and domain outcomes into one generic result. | |

## Recovery window, currency, and return context

| Option | Description | Selected |
|--------|-------------|----------|
| Preserve selected window, owner scope, and per-currency context | Retain the current window/scope in measures and linked-record return paths; keep totals grouped by currency. | ✓ Recommended |
| Use route defaults and establish fresh context on linked pages | Let recovery links discard source filters and owner/window context. | |

| Option | Description | Selected |
|--------|-------------|----------|
| Separate historical campaign evidence from current billing state | Present prior failures as history and use current invoice/subscription observations for current status. | ✓ Recommended |
| Derive current state from the latest recovery event | Treat the newest campaign event as current billing truth. | |

## the agent's Discretion

- Use existing Admin query, LiveView, money-formatting, confirmation, step-up, and browser-test patterns.
- The planner and implementer may select exact copy, component boundaries, and executable evidence organization within the locked roadmap and inherited guardrails.

## Deferred Ideas

- No new capability was introduced. Phase 238 and existing Portal/milestone scopes retain their assigned work.

