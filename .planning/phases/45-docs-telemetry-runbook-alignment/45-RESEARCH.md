# Phase 45 — Technical research (docs + telemetry/runbook alignment)

**Question:** What do we need to know to plan MTR-07 / MTR-08 well?

## Scope recap

- **MTR-07:** Published guides separate **public** `Accrue.Billing` APIs (`report_usage/*`), **internal** persistence (outbox / `MeterEvent` / reconciler concepts), and **processor** `report_meter_event/1` — without duplicating NimbleOptions tables (ExDoc + `@report_usage_schema` remain SSOT per Phase 43 D-07).
- **MTR-08:** `guides/telemetry.md` and `guides/operator-runbooks.md` explain **`[:accrue, :ops, :meter_reporting_failed]`** for **`:sync`**, **`:reconciler`**, **`:webhook`** — one durable terminal failure transition per row (Phase 44 D-03), not per HTTP retry; catalog row in `telemetry.md` stays authoritative.

## Code truth (emit sites and semantics)

| Source | Module | Contract |
|--------|--------|----------|
| `:sync` | `Accrue.Billing.MeterEventActions` | Calls `Accrue.Billing.MeterEvents.mark_failed_with_telemetry/4` with `source: :sync` on guarded transition |
| `:reconciler` | `Accrue.Jobs.MeterEventsReconciler` | Same helper with `source: :reconciler` when retry path exhausts |
| `:webhook` | `Accrue.Webhook.DefaultHandler` + `MeterEvents.mark_failed_by_identifier/2` | Stripe meter error report; `from_statuses` may include `reported` |
| Guarded emit | `Accrue.Billing.MeterEvents` | `@moduledoc` documents `:sync \| :reconciler \| :webhook`; telemetry only when `count == 1` on update |

**Metrics:** `Accrue.Telemetry.Metrics` documents `counter("accrue.ops.meter_reporting_failed.count", tags: [:source])` — keep prose aligned.

## Doc IA (v1.9 carry-forward)

- **`guides/telemetry.md`:** SSOT for ops catalog table — extend with a **short** “Semantics & sources” subsection **under** the existing table (CONTEXT D-06); do not fork the table into runbooks or `metering.md`.
- **`guides/operator-runbooks.md`:** RUN-01 procedural depth; meter mini-playbook already lists `source` — extend with **ordered branches** that **link** to the new telemetry subsection instead of re-stating measurements/metadata columns.
- **`guides/metering.md` (new):** Thin “architecture map”: public API → row lifecycle (concept) → processor seam → one sentence + link to telemetry/runbooks for ops (CONTEXT D-03). No second ops catalog.
- **ExDoc:** `Accrue.Billing.report_usage/3` already has “## Error tuples vs persisted rows”; optional **one** “See also” line to `guides/metering.md` once that file exists (CONTEXT discretion).

## Ecosystem / anti-patterns

- **Pay / Cashier lesson:** Docs must stress **once per durable `failed` transition** so operators do not page on every retry (CONTEXT D-13).
- **Hex norm:** Guides for mental models; API reference for option keys — do not copy `@report_usage_schema` into markdown tables.

## Pitfalls to avoid

1. Duplicating the ops catalog markdown table in `metering.md` or expanding runbooks into a second table (forbidden by D-08 / D-03).
2. Implying `meter_reporting_failed` fires on every processor HTTP error — contradicts Phase 44 guarded-update semantics.
3. Speculative metadata columns (Phase 44 D-13 deferred matrix) — if mentioning keys, limit to what code emits today.

## Deliverable checklist (planning input)

- [ ] New `accrue/guides/metering.md` (unless explicit D-04 fallback invoked in execute).
- [ ] `telemetry.md`: paragraph + three bullets for `:sync` / `:reconciler` / `:webhook`.
- [ ] `operator-runbooks.md`: source-aware ordered steps under existing meter playbook heading.
- [ ] Greps: forbidden duplicate table headers (planner defines exact patterns).
- [ ] `mix docs` succeeds after changes (`cd accrue && mix docs`).

## Validation Architecture

**Nyquist dimension 8 (feedback sampling) for this doc-only phase:**

| Dimension | Strategy |
|-----------|----------|
| Automated doc build | After each plan wave touching `accrue/guides/*.md` or `billing.ex`: `cd accrue && mix docs` — must exit 0 |
| Contract greps | `rg` for required strings: event tuple `[:accrue, :ops, :meter_reporting_failed]`, `source`, `:sync`, `:reconciler`, `:webhook`, “durable” or equivalent operator phrasing per CONTEXT |
| Forbidden patterns | Assert **absence** of a second markdown ops table in `metering.md` / `operator-runbooks.md` (e.g. duplicate `\| Event \|` catalog header in wrong files) |
| Cross-link integrity | Relative links `telemetry.md`, `operator-runbooks.md`, `metering.md` resolve from `guides/` |
| Tests | No production Elixir behavior change required; optional `mix test` unchanged baseline — not primary gate |

Wave 0: **Not required** — no new test framework; validation is `mix docs` + grep + human readability of diffs.

---

## RESEARCH COMPLETE

Phase 45 planning can proceed with CONTEXT.md as decision SSOT and this file for code anchors + validation strategy.
