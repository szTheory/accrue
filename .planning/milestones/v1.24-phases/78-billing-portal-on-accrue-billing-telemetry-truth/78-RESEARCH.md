# Phase 78 — Research

**Question:** What do we need to know to plan **Billing portal on `Accrue.Billing` + telemetry truth** well?

## Source of truth

- **`.planning/REQUIREMENTS.md` — BIL-04, BIL-05:** `Accrue.Billing.create_billing_portal_session/2` and `!`, customer struct + validated attrs (`return_url`, `configuration`, optional `flow_data`, `locale`, `on_behalf_of`, `operation_id`), delegate to `Accrue.BillingPortal.Session.create/1` after resolving Stripe customer id from `%Accrue.Billing.Customer{}`. Wrap in `Accrue.Telemetry.span/3` via the same `[:accrue, :billing, resource, :action]` pattern as other `Accrue.Billing` delegates — **`:billing_portal`** + **`:create`** — **PII-safe metadata** (no portal URL in logs/attrs). Fake-backed ExUnit: happy path + ≥1 failure class. BIL-05: `guides/telemetry.md`, `guides/operator-runbooks.md` cross-links when revenue/support-adjacent, `CHANGELOG.md`, optional First Hour pointers.
- **`.planning/ROADMAP.md` — Phase 78:** Success criteria tie to `78-VERIFICATION.md`, Fake tests, and alignment with `billing_span_coverage_test.exs`.

## Existing code patterns (verified)

1. **`Accrue.BillingPortal.Session`** (`accrue/lib/accrue/billing_portal/session.ex`): `@create_schema` with `customer`, `return_url`, `configuration`, `flow_data`, `locale`, `on_behalf_of`, `operation_id`. `create/1` validates and calls `Processor.__impl__().portal_session_create/2`. Customer may be `%Accrue.Billing.Customer{}` (uses `processor_id`) or binary Stripe id.
2. **`Accrue.Billing` telemetry** (`accrue/lib/accrue/billing.ex`): `span_billing/5` → `Accrue.Telemetry.span([:accrue, :billing, resource, action], billing_metadata(...), fun)`. Payment methods use `span_billing(:payment_method, :attach | :detach | :set_default | :list, ...)`.
3. **`billing_metadata/4`:** `processor`, `operation`, `customer_id`, `subscription_id`, `invoice_id`, `event_type` from opts — no URL field; keep it that way for portal.
4. **`Accrue.BillingPortal`** (`accrue/lib/accrue/billing_portal.ex`): thin `defdelegate` to `Session` — BIL-04 adds the **Billing context** entry point so integrators stay on `Accrue.Billing` for subscription + portal flows.
5. **`Accrue.Telemetry.BillingSpanCoverageTest`:** Asserts every **public** `Accrue.Billing` function body references `Accrue.Telemetry.span` (via `span_billing` which calls it) and matches `def name` / `defdelegate name`. New `create_billing_portal_session` / `!` must satisfy this grep-style audit.
6. **Prior tests:** `accrue/test/accrue/billing_portal_test.exs` covers `Session.create/1` and `BillingPortal.create_session/1`; Phase 78 adds **Billing** facade tests (telemetry + error path), not duplicate Session unit coverage.

## Failure classes suitable for Fake facade tests

- **Option A:** `{:error, _}` from `Session.create/1` when processor returns error — Fake may support forcing errors; grep `portal_session` / `billing_portal` in `processor/fake.ex`.
- **Option B:** Invalid attrs — if we validate attrs in Billing before delegate, `NimbleOptions` / `ArgumentError` on unknown keys (match project convention for other Billing APIs).
- Prefer **processor-level error** if Fake exposes a hook; otherwise **missing/blank `configuration` when Stripe would reject** is less portable. Simplest portable path: assert **telemetry `:exception'`** or `{:error, _}` using whatever scripted response Fake already supports for `portal_session_create`.

## Docs gaps (BIL-05)

- **`guides/telemetry.md`:** Add `accrue.billing.billing_portal.create` / `[:accrue, :billing, :billing_portal, :create]` alongside existing billing examples; confirm **attach / detach / set_default** payment_method tuples are listed consistently with `billing_span_coverage_test.exs` (code already spans them; doc may only mention `list` today — extend bullet list if incomplete).
- **`operator-runbooks.md`:** Add short cross-link where billing triage mentions correlating spans — portal session failures are support-adjacent (customer cannot open portal).

## Validation Architecture

Phase validation is **ExUnit-first** in the `accrue` package:

| Layer | Command | Role |
|-------|---------|------|
| **Focused** | `mix test test/accrue/path_to_new_test.exs` | Fast loop per task |
| **Telemetry audit** | `mix test test/accrue/telemetry/billing_span_coverage_test.exs` | Merge-blocking span coverage |
| **Package** | `cd accrue && mix test` | Wave / pre-verify |

Sampling: after each implementation task, run the focused test file; after all plans, full `accrue` test suite. No new external services — `Accrue.BillingCase` + Fake processor.

## RESEARCH COMPLETE
