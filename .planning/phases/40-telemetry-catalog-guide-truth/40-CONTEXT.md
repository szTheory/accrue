# Phase 40: Telemetry catalog + guide truth - Context

**Gathered:** 2026-04-21  
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship **documentation truth** for observability: `guides/telemetry.md` plus `Accrue.Telemetry.Ops` docs are the **authoritative operator-facing catalog** of every `[:accrue, :ops, :*]` emit (measurements + metadata aligned to code); **OBS-3** firehose vs ops split is clear and discoverable; **OBS-4** reconciliation with `.planning/research/v1.9-TELEMETRY-GAP-AUDIT.md` §1 is closed with an explicit maintainer trail.

**Out of this phase:** host metrics wiring / `Telemetry.Metrics` parity work (**Phase 41**), operator runbook narrative beyond what already exists inline in the guide (**Phase 42**), new billing primitives, v1.10 metering API.

</domain>

<decisions>
## Implementation Decisions

### 1 — Catalog shape & single source of truth

- **D-01:** **`guides/telemetry.md` owns the authoritative ops catalog**: one primary table listing every `[:accrue, :ops, :*]` event with measurements, metadata keys, cardinality / PII notes, and (where useful) runbook anchors. This is the surface SREs and hosts bookmark.
- **D-02:** **Anchored domain subsections** (Connect, PDF/ledger, DLQ, etc.) hold **narrative only**—no second competing table for the same events. Cross-link from table rows to subsections where extra context exists.
- **D-03:** **`Accrue.Telemetry.Ops` moduledoc** stays a **short canonical list** of event suffixes + integrity notes (`operation_id`, tamper prefix). It **must not** duplicate the full measurements/metadata schema; link to the guide’s ops table (stable anchor).
- **D-04:** **Cross-cutting emits** (one logical signal, multiple call paths) are documented **once** in the table; use a single **primary owner** column (see §3) rather than duplicating per adapter.

### 2 — OBS-04 reconciliation & drift control (hybrid)

- **D-05:** **Truth hierarchy:** published **`guides/telemetry.md`** (plus tests that lock inventory, when added) is the **long-term operator contract**. The gap audit is an **input artifact**: after reconciliation, mark it **SUPERSEDED** in the audit (date + PR link) so it cannot silently contradict the guide.
- **D-06:** **Footer in the guide:** add **“Last reconciled with v1.9 gap audit §1: YYYY-MM-DD — PR #…”** when OBS-04 closes (cheap trust signal without pretending automation exists on day one).
- **D-07:** **Automation posture (idiomatic Elixir OSS):** prefer **`mix test` contract tests** over grepping Markdown prose. Narrow CI: assert documented **ops event name set** matches a **single code-owned list** or allowlisted emit registry—not editorial quality of paragraphs. Failing tests print **actionable remediation** (which file to update).
- **D-08:** **Release hygiene:** keep a **single checkbox** on release/milestone close (“telemetry inventory tests green; guide footer bumped if ops set changed”)—not a multi-page manual diff ritual.

### 3 — Emit-site traceability (contract-first, medium depth)

- **D-09:** **Required catalog fields** stay **contract-first**: event tuple, purpose (operator language), measurements, metadata semantics, cardinality / stability, sanitized examples where helpful.
- **D-10:** **“Primary owner” per row:** one **stable conceptual anchor**—subsystem or **owning context module**, or `Accrue.Telemetry.Ops` when that is the intentional public emission API. This is **not** an exhaustive call-site map.
- **D-11:** **Explicit non-goals for Phase 40:** no **file:line** references in the guide as normative documentation; no **exhaustive** multi-module call lists unless a future codegen/CI pipeline owns them. Contributor discovery remains **`Ops.emit/3` + `:telemetry.execute` search** for exhaustive enumeration.
- **D-12:** **ExDoc:** keep deep duplication out of scattered `@moduledoc`s; link wrapper APIs (`Ops.emit/3`) back to the guide section.

### 4 — Firehose depth (OBS-3) & OpenTelemetry honesty (audit §4)

- **D-13:** **Firehose = policy + taxonomy, not a second catalog.** Keep (or tighten) one concise subsection: what `Accrue.Telemetry.span/3` covers, high cardinality warning, diagnostics vs paging, explicit pointer to `[:accrue, :ops, :*]` for alerts. **Do not** enumerate every `[:accrue, :billing, …]` action in Phase 40.
- **D-14:** **OTel section = algorithm + verified illustrations + explicit non-exhaustiveness:**
  - Document the **name derivation** (dot-join; base event without `:start`/`:stop`/`:exception` where applicable) and optional `:opentelemetry` gate.
  - **Add** a verified billing example: **`accrue.billing.meter_event.report_usage`** (pairs with ops `meter_reporting_failed` for failures—cross-link).
  - **Relabel or remove** examples that are **not** `Accrue.Telemetry.span/3` spans—e.g. **`accrue.webhooks.dlq.replay`** is an **ops** signal, not an OTel span from the same bridge; treat similarly for any **checkout** / **billing_portal** examples until instrumentation is verified (prefer **delete or move to “aspirational / not emitted”** rather than wrong certainty).
  - Add a short **“Illustrative examples”** callout: not exhaustive; for billing span coverage point to **`billing_span_coverage_test`** (or equivalent) / source search.
  - **Reconcile domain vocabulary** between `Accrue.Telemetry` moduledoc and the guide (e.g. **`:connect`**, **`:storage`** if used by `span/3`) so prose does not imply a closed list that code violates.
  - Optional stretch: a **tiny test** that every OTel example string in the guide matches code-derived patterns or an allowlist—prevents recurrence of stale examples.

### 5 — Headings, versioning & reader UX

- **D-15:** **Rename** `## Ops events in v1.0` to an **evergreen** title (e.g. **`## Ops event catalog (`[:accrue, :ops, :*]`)`**). Do **not** encode package SemVer in `##` headings for reference sections.
- **D-16:** **Version truth lives:** (1) **Guide header** — 2–4 lines stating the doc tracks published `accrue` telemetry contracts and how `main` may diverge from Hex; (2) **`CHANGELOG.md`** — timeline for new/changed ops events; (3) **per-row `Since: x.y.z`** only when adding **new** ops signals after baseline catalog work; (4) **`@doc since:`** on public telemetry helpers where ExDoc should show version history.
- **D-17:** **README** keeps **ecosystem floors** (Elixir/OTP/Phoenix/PG, optional OTel)—not per-event SemVer history.

### Claude's Discretion

- Exact subsection titles and row ordering in `guides/telemetry.md` may be adjusted for readability as long as **D-01–D-17** invariants hold.
- Whether to add the optional “OTel example string” test in Phase 40 vs Phase 41 is **planner’s call** based on remaining scope after doc edits.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & planning
- `.planning/ROADMAP.md` — Phase 40 goal, milestone boundary (v1.9 Phases 40–42)
- `.planning/REQUIREMENTS.md` — **OBS-01**, **OBS-03**, **OBS-04** definitions and traceability
- `.planning/research/v1.9-TELEMETRY-GAP-AUDIT.md` — §1 ops inventory input; mark SUPERSEDED after reconciliation PR
- `.planning/PROJECT.md` — v1.9 vision: discoverable telemetry, honest docs, no new billing primitives this milestone

### Code & docs (ship targets)
- `accrue/guides/telemetry.md` — primary edit surface for catalog + firehose + OTel narrative
- `accrue/lib/accrue/telemetry/ops.ex` — moduledoc alignment with guide (list + link, no full duplicate schema)
- `accrue/lib/accrue/telemetry.ex` — span / domain vocabulary to reconcile with guide prose
- `accrue/lib/accrue/telemetry/otel.ex` (if present) — OTel name + attribute allowlist must match documented examples
- `accrue/lib/accrue/billing.ex` — `span_billing/5` inventory for OTel example verification (`meter_event.report_usage`, etc.)
- `accrue/test/**/*billing*span*` or `**/*span*coverage*` — search for tests that enumerate billing spans for “non-exhaustive” pointers

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets
- **`guides/telemetry.md`** already implements namespace split, a wide ops table (incl. PDF, ledger upcast, Connect), firehose bullets, metrics recipe, and substantial runbook column—Phase 40 is **tightening truth**, not greenfield.
- **`Accrue.Telemetry.Ops`** moduledoc already lists 13 canonical suffixes aligned with the guide table—use as **secondary** surface linked from guide.

### Established patterns
- **Ops signals** use `Ops.emit/3` with hardcoded `[:accrue, :ops | suffix]`; some curated `:telemetry.execute/3` for PDF/ledger—document both as first-class ops.
- **Billing firehose** uses `span_billing/5` in `billing.ex`—large surface; documentation should reference **tests** or naming rules instead of full enumeration.

### Integration points
- **ExDoc** pulls `guides/*.md` as extras—heading stability matters for deep links from host runbooks and issues.
- **Hex / GitHub readers** may view guides **without** HexDocs version switcher—evergreen headings + header version contract reduce confusion.

</code_context>

<specifics>
## Specific Ideas

- Research consensus: **Stripe-like flat catalogs** for stable names + **Phoenix-like guides** for wiring + **ExDoc** for API-local summaries—Accrue should combine all three without duplicate “sources of truth.”
- **OpenTelemetry upstream style**: naming convention + small verified examples + explicit non-exhaustiveness—avoid implying every internal span is documented.
- **Honeybadger / AppSignal style**: integration + troubleshooting first; event catalog reads as **contract**, not stack-frame database.

</specifics>

<deferred>
## Deferred Ideas

- **Phase 41 (TEL-01 / OBS-02):** deepen `Accrue.Telemetry.Metrics.defaults/0` narrative, cross-domain host subscription examples—out of Phase 40.
- **Phase 42 (RUN-01):** full operator runbook section expansion—out of Phase 40 unless copy already lives inline in the ops table.
- **v1.10 metering API** surface documentation — see `.planning/research/v1.10-METERING-SPIKE.md`.

### Reviewed Todos (not folded)

- None — `todo.match-phase` returned no matches for phase 40.

</deferred>

---

*Phase: 40-telemetry-catalog-guide-truth*  
*Context gathered: 2026-04-21*
