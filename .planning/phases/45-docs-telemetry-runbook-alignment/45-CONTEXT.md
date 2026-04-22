# Phase 45: Docs + telemetry/runbook alignment - Context

**Gathered:** 2026-04-22  
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver **MTR-07** and **MTR-08**: published guides clarify **public** `Accrue.Billing` entry points vs **internal** persistence (outbox / `MeterEvent` / reconciler) vs **processor** `report_meter_event/1` contracts; **`guides/telemetry.md`** and **`guides/operator-runbooks.md`** document **`[:accrue, :ops, :meter_reporting_failed]`** for **`:sync`**, **`:reconciler`**, and **`:webhook`** without contradicting v1.9 catalog rows or Phase 44 durable-transition semantics.

**Explicitly not this phase:** New billing primitives, **PROC-08**, admin meter dashboards, full semver-sensitive **metadata field matrix** across sources (deferred until shapes stabilize).

</domain>

<decisions>
## Implementation Decisions

### 1 — MTR-07 doc spine (research synthesis: Hex idioms + Pay/Cashier/Stripe lessons)

- **D-01:** Ship a **thin** `accrue/guides/metering.md` as the **host-facing architecture map** for MTR-07 — one ExDoc sidebar page that answers “what do I call, what persists, what hits Stripe/Fake?” **without** duplicating the NimbleOptions table (ExDoc on `Accrue.Billing.report_usage/*` + `@report_usage_schema` remain SSOT per Phase 43 **D-07**).
- **D-02:** **`guides/metering.md` contents (bounded):** (a) **Public** — `report_usage/3` / `!` and pointer to ExDoc **## Options**; (b) **Internal** — outbox row lifecycle (`pending` → `reported` / `failed`), reconciler role, webhook error path at **concept** level with links to `MeterEvent`, `MeterEventsReconciler`, `DefaultHandler` in API docs; (c) **Processor** — `Accrue.Processor` + `report_meter_event/1`; Stripe via configured processor + **Fake** for tests; **one explicit sentence** that **PROC-08** / additional processors are **out of v1.10 narrative scope** beyond the behaviour seam.
- **D-03:** **Ops narrative stays out of `metering.md`:** no second ops catalog, no duplicated `meter_reporting_failed` tables — **at most one sentence + link** to `guides/telemetry.md` (and optionally `operator-runbooks.md`) for “what fires when this fails?” (extends Phase 43 **D-09** discipline into Phase 45).
- **D-04 (fallback):** If timeboxed, **omit `metering.md`** and satisfy MTR-07 with **tight `@moduledoc` cross-links + `testing.md` intro paragraph** only — planner must not ship a **thick** guide in a rush; thin-or-skip is the allowed trade space.

### 2 — MTR-08: `telemetry.md` depth (one event, many origins — Oban/telemetry idioms)

- **D-05:** **Preserve the single v1.9 ops catalog row** for `[:accrue, :ops, :meter_reporting_failed]` (tuple, measurements, metadata keys, owners) — **do not fork** the inventory table into runbooks or metering guide.
- **D-06:** Add **one compact “Semantics & sources” block** **immediately under** the ops catalog table in **`guides/telemetry.md`**: (1) **One short paragraph** in operator language: signal fires on **durable terminal `failed` transition** for the row / failure epoch (**Phase 44 D-03**), **not** per HTTP retry, webhook redelivery, or idempotent replay; (2) **Three bullets** — `:sync`, `:reconciler`, `:webhook` — each **one line** of causal origin + pointer (request path vs `MeterEventsReconciler` vs meter error webhook / `DispatchWorker` path as documented in code).
- **D-07:** **Defer full cross-source metadata matrix** (Phase 44 **D-13** stretch) until optional fields (`error_code`, etc.) are **stable** enough to document without semver churn; if a partial matrix is shipped, scope it to **keys already emitted** in code and **default metrics** tags — no speculative columns.

### 3 — Runbook vs catalog split (RUN-01 / v1.9 layered IA)

- **D-08:** **Keep v1.9 architecture:** `guides/telemetry.md` = **contract** (catalog + metrics + compact first-actions); `guides/operator-runbooks.md` = **procedure** (ordered triage, Oban topology, Stripe checks, mini-playbooks) — **no second ops table** in runbooks.
- **D-09:** Extend the **`meter_reporting_failed` mini-playbook** with **source-aware branching** (`:sync` vs `:reconciler` vs `:webhook`) as **ordered steps only** — each branch **elaborates** what the catalog row already claims; **link** to the new **Semantics & sources** subsection in `telemetry.md` instead of redefining the event.
- **D-10:** **Alert / Grafana DX:** document that alert annotations should deep-link to **`telemetry.md`** anchors (tuple + semantics), then **runbook** for “what to do next” — matches least-surprise path for host operators (Stripe product docs alone cannot tell the DB + Oban + library story).

### 4 — README / `testing.md` cross-links (evaluator + least surprise)

- **D-11:** Treat **README** and **`guides/testing.md`** cross-links as **optional stretch** for phase close (per ROADMAP) — **MTR-07/MTR-08** are the **hard bar**; link graph expansion is **evidence-based** (add when a real evaluator gap appears).
- **D-12 (minimal pattern if stretch is done):** **At most** — one **README** line pointing to **`guides/testing.md`** for verification posture; **one** reciprocal or strengthened line in **`guides/testing.md`** for meter failure paths pointing to **`guides/metering.md`** (if present) + **`guides/telemetry.md`** (+ runbook as already partially done in Phase 43). **Do not** build a comprehensive README ↔ every-guide graph (Cashier pattern = single canonical doc hop; Pay pattern = README as **TOC**, not duplicate bodies; stripe-ruby = contextual links where topic arises).

### 5 — Ecosystem lessons explicitly encoded

- **D-13:** **Pay / Cashier lesson:** alerting on **every retry** trains operators to ignore signals — docs must reinforce **D-03** “once per durable transition” in **both** telemetry semantics and runbook language.
- **D-14:** **Phoenix/Ecto/Oban / Hex norm:** API reference for contracts; **guides** for mental models; **one ops namespace** (`[:accrue, :ops, :*]`) with **metadata dimensions** (`source`) for “many origins,” not three separate event names.
- **D-15:** **Stripe lesson:** Stripe docs own Dashboard/API money truth; Accrue docs own **library-local** “DB + Oban + processor + webhook” **coherent** story — metering guide bridges to Stripe only where host configuration matters, not as a second ledger narrative.

### Claude's Discretion

- Exact heading anchors and subsection titles in `telemetry.md` / `metering.md`.
- Whether **D-04** fallback (no `metering.md`) triggers based on plan sizing — prefer **thin `metering.md`** if any planner capacity exists.
- Wording of the three `:source` bullets (implementation names vs operator-facing labels) as long as tuples stay accurate.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and milestone
- `.planning/REQUIREMENTS.md` — **MTR-07**, **MTR-08**
- `.planning/ROADMAP.md` — v1.10 Phase 45 goal and success criteria
- `.planning/PROJECT.md` — v1.10 narrative; Fake parity; observability expectations

### Research and prior constraints
- `.planning/research/v1.10-METERING-SPIKE.md` — public vs internal vs processor; acceptance outline
- `.planning/research/v1.9-TELEMETRY-GAP-AUDIT.md` — catalog completeness discipline
- `.planning/phases/43-meter-usage-happy-path-fake-determinism/43-CONTEXT.md` — ExDoc/testing/telemetry SSOT split (**D-07..D-10**)
- `.planning/phases/44-meter-failures-idempotency-reconciler-webhook/44-CONTEXT.md` — **D-01** `source` enum, **D-03** durable transition, **D-13** deferred metadata table
- `.planning/phases/40-telemetry-catalog-guide-truth/40-CONTEXT.md` — ops catalog SSOT
- `.planning/phases/42-operator-runbooks/42-CONTEXT.md` — RUN-01 mini-playbook pattern

### Doc ship targets (edit in Phase 45)
- `accrue/guides/metering.md` — **new** thin spine (per **D-01..D-03**); register in `accrue/mix.exs` extras if not picked up by wildcard
- `accrue/guides/telemetry.md` — semantics block (**D-05..D-07**)
- `accrue/guides/operator-runbooks.md` — mini-playbook extension (**D-08..D-10**)
- `accrue/guides/testing.md` — optional link reinforcement (**D-11..D-12**)
- `accrue/README.md` — optional one-liner (**D-12**)
- `accrue/lib/accrue/billing.ex` — cross-link from `@doc` to `guides/metering.md` if helpful (Claude discretion)

### Code anchors (for doc accuracy)
- `accrue/lib/accrue/billing/meter_event_actions.ex` — sync path, failure telemetry
- `accrue/lib/accrue/jobs/meter_events_reconciler.ex` — reconciler
- `accrue/lib/accrue/webhook/default_handler.ex` — webhook meter error path
- `accrue/lib/accrue/webhook/dispatch_worker.ex` — production webhook ctx

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets
- Existing **`guides/testing.md`** “Usage metering (Fake)” fragment and link to `telemetry.md` — extend per **D-12**, do not replace.
- **`guides/telemetry.md`** ops table + “first actions” pattern — extend with semantics block (**D-06**).
- **`guides/operator-runbooks.md`** mini-playbook shell + DRY banner — extend, never duplicate catalog (**D-08**).

### Established patterns
- **ExDoc extras** from `guides/*.md` — new `metering.md` is first-class Hexdocs navigation.
- **v1.9 contract:** catalog SSOT in `telemetry.md`; runbooks procedural only.

### Integration points
- **`mix.exs`** `docs` extras — ensure `metering.md` included if not globbed.
- Phase 45 verification should **grep** for forbidden duplicate catalog tables in runbook/metering guide.

</code_context>

<specifics>
## Specific Ideas

- Subagent research (2026-04-22) compared **dedicated metering guide vs layered-only vs folding into quickstart vs external wiki**; consensus: **thin dedicated guide** wins for pasteable URL + MTR-07 clarity if it respects telemetry SSOT.
- Telemetry depth consensus: **subsection under catalog** beats row-only (insufficient for MTR-08) and beats full metadata matrix pre-stability (footgun).
- Runbook/catalog consensus matches **RUN-01**: layered **alert → telemetry → runbook**, not runbook-heavy duplication.
- README/testing links: **minimal high-signal** optional stretch, aligned with Cashier/Pay/stripe-ruby README patterns.

</specifics>

<deferred>
## Deferred Ideas

- **Full cross-source metadata matrix** — when **D-13** fields and `Accrue.Telemetry.Metrics` tags are stable (**D-07**).
- **PROC-08** multi-processor how-to — out of milestone.
- **Comprehensive cross-link graph** across all guides — only if evidence shows evaluator confusion (**D-11**).

### Reviewed Todos (not folded)

- None (`todo.match-phase` returned empty for phase 45).

</deferred>

---

*Phase: 45-docs-telemetry-runbook-alignment*  
*Context gathered: 2026-04-22*
