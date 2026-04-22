# Phase 48: Admin metering & billing signals - Context

**Gathered:** 2026-04-22  
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship **ADM-01**: at least one **credible metering- or usage-adjacent** operator signal on the **admin entry path** (`AccrueAdmin.Live.DashboardLive`), with **honest** navigation into **existing** operator surfaces — **no** new accounting semantics, **no** PROC-08 / FIN-03.

Visual structure, placement, tokens, and copy discipline are locked by **`48-UI-SPEC.md`** (one new `KpiCard`, first position in `ax-kpi-grid`, `AccrueAdmin.Copy` SSOT, no new UI kits).

</domain>

<spec_lock>
## Requirements (locked artifacts)

**Functional:** **ADM-01** in `.planning/REQUIREMENTS.md` — metering/usage-adjacent signal consistent with **v1.10** semantics and telemetry/runbook narratives.

**Presentation:** **`48-UI-SPEC.md`** — route scope, component choice (`KpiCard`), grid placement, typography/color/spacing contracts, verification hints.

Downstream agents MUST read **`48-UI-SPEC.md`** before implementing UI. Do not duplicate its tables here.

**In scope (combined):** One new dashboard KPI + supporting query/assigns + `AccrueAdmin.Copy` entries + tests per decisions below.  
**Out of scope:** New meter-event LiveView index, query-param filters that are not provably row-aligned with the KPI aggregate, new third-party UI, core schema/processor changes.

</spec_lock>

<decisions>
## Implementation Decisions

### 1 — Primary aggregate (gray area 1)

- **D-01:** The new KPI **primary value** is **`COUNT(*)` of `accrue_meter_events` where `stripe_status == "failed"`** (same owner/org scoping rules as existing `dashboard_stats/0` queries). This is **durable local billing state**, aligned with Phase 44 semantics for **`[:accrue, :ops, :meter_reporting_failed]`** (first transition into terminal `failed`, not per HTTP retry).
- **D-02:** **Do not** use raw **`pending`** count as the primary panic signal — healthy in-flight `report_usage` calls also sit in `pending` (false positives, Pay/Stripe-style alert fatigue).
- **D-03 (optional secondary line):** If a cheap second query is justified in the same mount, a **24h window** on rows that **entered** `failed` recently (e.g. `updated_at` within sliding 24h, documented in Copy meta) may appear as **delta text only** — not a second KPI card. If `updated_at` semantics are ambiguous in code review, **omit** the delta and ship value-only (Claude discretion bounded by D-02 honesty).
- **D-04:** Compute counts with **idiomatic `Ecto.Query` + `Repo.aggregate(:count, :id)`** (or equivalent single-query count) in the same style as existing dashboard aggregates — **no** `Repo.all` + `length/1`, no N+1 from preloads for numeric-only assigns.

### 2 — Deep link & href honesty (gray area 2)

- **D-05:** **`href` targets the existing LiveView route `/events`** via **`ScopedPath.build/3`** (no extra query map in Phase 48 unless implementation proves **byte-for-byte** filter parity with `AccrueAdmin.Queries.Events` for that aggregate — **defer** `?type=` and similar until a dedicated meter-event index or provably matching filter exists).
- **D-06:** **`aria_label` + meta** must **not** imply the events table row count equals the KPI number. Copy pattern: primary number = **`accrue_meter_events` terminal failures**; link = **open billing event ledger for correlated audit activity** (principle of least surprise: operators land somewhere true, not a fake pre-filtered list).
- **D-07:** **Do not** point at `/webhooks` as the primary link for this card **unless** the planner documents **provable** parity between the KPI SQL and `Webhooks.list/1` + `scope_rows/2` behavior — today’s webhook pipeline KPI already owns **`/webhooks`**; splitting “meter failed rows” vs “failed webhook rows” without parity erodes trust (research consensus).

### 3 — Coexistence with Webhook backlog KPI (gray area 3)

- **D-08:** **Cognitive split:** existing card = **cross-cutting webhook ingestion queue** (`accrue_webhook_events` failed/dead backlog + 24h volume context). New card = **meter reporting / `MeterEvent` row health** (`accrue_meter_events` terminal `failed`).
- **D-09:** **Label/meta discipline:** new strings live under **`AccrueAdmin.Copy`** with a `dashboard_meter_*` (or `dashboard_usage_*`) prefix per UI-SPEC; **never** reuse `dashboard_kpi_webhook_backlog_*` keys; **forbidden** vague **“Usage”** / **“Meters”** labels without tying to the stored aggregate (UI-SPEC).
- **D-10:** **`delta_tone`** derives from **this card’s query only** — do not couple amber/moss to the webhook card’s assigns. Avoid parallel “backlog” vocabulary in **both** labels; prefer “failed meter events” / “meter reporting failures” style scoped nouns.
- **D-11:** If meta needs one clause bridging infrastructure: e.g. failures may correlate with webhook or sync paths per **`guides/telemetry.md`** — **one short sentence**, not a second paragraph.

### 4 — Verification posture (gray area 4)

- **D-12:** Phase **48** proves the slice with **`Phoenix.LiveViewTest` + sandbox-backed fixtures**: mount assigns, rendered KPI, **`href`/`aria-` attributes**, zero vs non-zero branches, and **direct unit tests** for new **`AccrueAdmin.Copy`** functions (no new raw literals in `dashboard_live.ex`).
- **D-13:** **Defer expanded Playwright + axe** for mounted admin home to **Phase 50 (ADM-06)** unless an **existing** merge-blocking VERIFY-01 spec would **break** on the new DOM — then apply the **smallest** fix (prefer accessible selectors; **at most one** stable `data-test-id` on the new KPI root if required). **Do not** add a new CI lane or change merge-blocking vs advisory VERIFY-01 policy in Phase 48.
- **D-14:** **`data-test-id` policy:** add **only** if needed for stability; name with a clear prefix (e.g. `admin-dashboard-kpi-meter-failed`); avoid sprinkling across child nodes.

### 5 — Ecosystem / product lessons (research synthesis, non-normative but guides tradeoffs)

- **D-15:** Follow **Stripe-style** drill-down honesty: tiles may aggregate broadly, but **links must not overclaim filtering**. Follow **Pay/Cashier** lesson: **entity counts** operators understand, but separate **transport health** from **domain row state** to avoid collapsing incidents into one misleading red dot.
- **D-16:** Prefer **“durable state, not retry volume”** everywhere copy touches metering — matches v1.10 docs and prevents Grafana-style alert fatigue from retry-shaped metrics.

### Claude's Discretion

- Exact **`Copy.*` function names** and final label strings (within UI-SPEC honesty rules).
- Whether **D-03** delta ships in 48 or is deferred after inspecting `MeterEvent` timestamp columns in plan review.
- Minor CSS tweak scope inside **`ax-kpi-grid`** only if five tiles stress layout (per UI-SPEC).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone & requirements
- `.planning/REQUIREMENTS.md` — **ADM-01**
- `.planning/ROADMAP.md` — v1.12 Phase 48 row
- `.planning/PROJECT.md` — v1.12 admin UX goals; PROC-08 / FIN-03 non-goals

### Locked contracts
- `.planning/phases/48-admin-metering-billing-signals/48-UI-SPEC.md` — UI/visual/copy structure

### Metering + ops narrative (honest copy + telemetry alignment)
- `accrue/guides/metering.md` — host-facing metering architecture
- `accrue/guides/telemetry.md` — **`meter_reporting_failed`** semantics + `:source` enum
- `accrue/guides/operator-runbooks.md` — meter mini-playbook + triage layering
- `.planning/phases/44-meter-failures-idempotency-reconciler-webhook/44-CONTEXT.md` — durable `failed` transition, webhook `DispatchWorker` path
- `.planning/phases/45-docs-telemetry-runbook-alignment/45-CONTEXT.md` — doc/runbook split discipline

### Code anchors
- `accrue_admin/lib/accrue_admin/live/dashboard_live.ex` — mount, `dashboard_stats/0`, KPI grid
- `accrue_admin/lib/accrue_admin/components/kpi_card.ex` — linked card pattern
- `accrue_admin/lib/accrue_admin/copy.ex` — dashboard string SSOT
- `accrue_admin/lib/accrue_admin/scoped_path.ex` — org-safe paths + optional query merge
- `accrue_admin/lib/accrue_admin/queries/events.ex` — event ledger filters (**do not** add URL filters in 48 without parity proof)
- `accrue/lib/accrue/billing/meter_event.ex` — schema + `accrue_meter_events_failed_idx` intent
- `accrue/lib/accrue/billing/meter_events.ex` — guarded `failed` transition + telemetry
- `accrue/lib/accrue/billing/meter_event_actions.ex` — outbox + ledger insert semantics

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets
- **`AccrueAdmin.Components.KpiCard`** — same linked-card pattern as Customers / Webhooks rows on `DashboardLive`.
- **`ScopedPath.build/3`** — matches existing dashboard `href`s for scope correctness.
- **`dashboard_stats/0`** style — add one more aggregate query alongside `customer_count`, webhook counts, etc.

### Established patterns
- **Mount-time `Repo.aggregate` / `Repo.one`** — keep dashboard load predictable; no association preload for counts.
- **`AccrueAdmin.Copy`** — all new/changed operator strings for this phase.

### Integration points
- **First slot inside `section.ax-kpi-grid`** — insert **before** the Customers `KpiCard` per UI-SPEC (current file order may need reordering in implementation).
- **VERIFY-01** — unchanged policy; touch Playwright only if an existing blocking spec requires a minimal selector update.

</code_context>

<specifics>
## Specific Ideas

- Research consensus: **terminal `failed` `MeterEvent` rows** are the best single-number mirror of the library’s **“durable failure, not retry noise”** story for operators landing on admin home.
- Deep link choice **`/events` without query** balances **Phoenix/LiveView honesty** (no fake filters) with the dashboard’s existing **“billing event ledger”** narrative in the lower panel.

</specifics>

<deferred>
## Deferred Ideas

- **Dedicated `MeterEvent` admin index** with row-level drill-down and URL filters that match KPI SQL — new capability; not Phase 48.
- **`/webhooks?type=...` or multi-status filters** tied to this KPI — only if parity with `AccrueAdmin.Queries.Webhooks` + org scoping is proven in a later phase.
- **Full Playwright + axe** for admin home — Phase **50** / **ADM-06** unless minimal unblock per **D-13**.

### Reviewed Todos (not folded)

- None (`todo.match-phase` returned no matches).

</deferred>

---

*Phase: 48-admin-metering-billing-signals*  
*Context gathered: 2026-04-22*
