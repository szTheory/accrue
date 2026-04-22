# Phase 40: Telemetry catalog + guide truth - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in `40-CONTEXT.md`.

**Date:** 2026-04-21  
**Phase:** 40 — Telemetry catalog + guide truth  
**Areas discussed:** (1) Catalog shape & source of truth, (2) OBS-04 reconciliation discipline, (3) Emit-site traceability, (4) Firehose & OTel depth, (5) Guide versioning & headings  
**Method:** User requested **all** areas + parallel subagent research (ecosystem patterns, tradeoffs, coherent recommendations). Outcomes synthesized into locked decisions **D-01–D-17** in CONTEXT.

---

## 1 — Catalog shape & source of truth

| Approach | Description | Selected |
|----------|-------------|----------|
| A — Guide-only mega table | Single table, moduledoc minimal | Partial |
| B — Split domain sections | Per-domain narrative + examples | Partial |
| C — Moduledoc as full duplicate | Full schemas in `Ops` moduledoc | ✗ |

**User's choice (via research synthesis):** **Hybrid A+B with strict anti-drift rule** — one authoritative ops table in `guides/telemetry.md` plus anchored domain subsections for narrative only; `Accrue.Telemetry.Ops` moduledoc holds canonical **list** + link, not duplicate measurement/metadata schemas.

**Notes:** Aligns with Phoenix (guide-first), Stripe (stable flat catalog for names), ExDoc norms (reference vs narrative split).

---

## 2 — OBS-04 reconciliation discipline

| Approach | Description | Selected |
|----------|-------------|----------|
| A — Manual only | Release checklist | Partial (lightweight checkbox) |
| B — Footer only | “Last reconciled” note | Partial |
| C — CI grep on prose | Markdown diff gates | ✗ |
| D — Hybrid | Tests + guide + superseded audit | ✓ |

**User's choice:** **Hybrid (D)** — guide + optional narrow `mix test` inventory contract; audit superseded with PR link; footer date; avoid prose-diff CI.

---

## 3 — Emit-site traceability

| Level | Description | Selected |
|-------|-------------|----------|
| Sparse | Event + metadata only | Partial |
| Medium | Primary owner module / subsystem | ✓ |
| Rich | file:line / exhaustive call sites | ✗ |

**User's choice:** **Contract-first + medium traceability** — primary owner per event; no normative file:line; no exhaustive lists without codegen.

---

## 4 — Firehose & OpenTelemetry depth

| Option | Description | Selected |
|--------|-------------|----------|
| A — Minimal only | Status quo bullets | Partial (keep tight) |
| B — Representative verified examples | e.g. `meter_event.report_usage` | ✓ |
| C — Gaps / non-exhaustive callout | Honest scope box | ✓ |
| D — Full firehose enumeration | Every span | ✗ |

**User's choice:** **B + C for OTel**; **OBS-3** stays one concise firehose subsection; fix misleading OTel examples (e.g. DLQ replay = ops not span); verify checkout/billing_portal; reconcile `Accrue.Telemetry` domain list with guide.

---

## 5 — Guide versioning & headings

| Pattern | Description | Selected |
|---------|-------------|----------|
| SemVer in `##` headings | e.g. “Ops events in v1.0” | ✗ |
| Evergreen catalog headings | Semantic `##` titles | ✓ |
| Since / CHANGELOG | Per-row or timeline | ✓ |

**User's choice:** Rename stale versioned ops heading; version contract in guide intro + CHANGELOG + optional `@since` on APIs.

---

## Claude's Discretion

- Minor editorial structure in `guides/telemetry.md` and optional OTel-example test placement (Phase 40 vs 41) left to planner.

## Deferred Ideas

- Phase 41 metrics / cross-domain examples; Phase 42 runbooks; v1.10 metering API docs (see CONTEXT `<deferred>`).
