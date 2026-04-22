# Phase 41: Host metrics wiring + cross-domain example - Context

**Gathered:** 2026-04-21  
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver **TEL-01** and **OBS-02** for v1.9: machine-verifiable **parity** (or explicitly documented omissions) between `Accrue.Telemetry.Metrics.defaults/0` and the **OBS-01** ops event set; plus a **host-copyable**, **public-API-only** cross-domain subscription example. Phase 40 owns the ops catalog truth in `guides/telemetry.md` — Phase 41 does **not** duplicate that catalog; it wires and proves host integration.

**Explicitly out of scope:** Phase 42 operator runbook expansion; new billing primitives; full “subscribe to all billing firehose” tutorials; codegen of the entire metrics module unless planner reopens after scope review.

</domain>

<decisions>
## Implementation Decisions

### 1 — TEL-01 closure (metrics vs OBS-01 ops catalog)

- **D-01:** Close TEL-01 with an **ExUnit contract** (new test module, name e.g. `Accrue.Telemetry.MetricsOpsParityTest`) that asserts every canonical `[:accrue, :ops | _]` event from **`OpsEventContractTest`’s allowlist** has a matching **`Telemetry.Metrics`** definition in `Accrue.Telemetry.Metrics.defaults/0` (assert on resolved **metric struct `event_name`**, not string heuristics on source).
- **D-02:** **Reuse a single source** for the ops event atom list — either `import`/`Code.require_file` a tiny shared test helper, or extract `@expected_ops_events` to one module both tests use — avoid three divergent lists (guide literals, ops contract, metrics parity).
- **D-03:** **Intentional metric omissions** (if any) must be **explicit** in test (e.g. `@tel_metric_omissions` with one-line reason + guide anchor) same spirit as ops contract remediation strings (`guides/telemetry.md` + test file names in failure output).
- **D-04:** **Optional `:telemetry_metrics`:** gate or tag tests so CI stays honest when the real `defaults/0` body is not compiled (mirror existing conditional-compile story in `Accrue.Telemetry.Metrics`).
- **D-05:** **Do not** rely on doc-only or release-checklist-only parity as the primary gate; optional release note reminder is fine as **supplement**.
- **D-06:** **Defer** standalone `mix` task for metrics parity **unless** a concrete non-ExUnit workflow appears; `mix test` remains the default enforcement surface.

### 2 — OBS-02 placement (docs + discoverability)

- **D-07:** Add a **short, titled subsection** to **`accrue/guides/telemetry.md`** (e.g. “Cross-domain host subscription”) for the copy-paste story: **public modules only** (`Accrue.Telemetry`, `Accrue.Telemetry.Metrics`, `Accrue.Telemetry.Ops` docs as appropriate); **link** to the existing ops catalog for event names — **no second catalog table**.
- **D-08:** Mirror minimal wiring in **`examples/accrue_host`** with an explicit **maintenance contract** comment (e.g. “Mirrors `guides/telemetry.md` § …”) and a **README** deep link to the guide anchor.
- **D-09:** **Do not** add a separate long **`guides/*.md`** for this unless `telemetry.md` becomes unmaintainable; splitting risks duplicate truth vs Phase 40 SSOT.

### 3 — Cross-domain proof depth (ops vs billing firehose)

- **D-10:** **Primary example:** **one** `:telemetry.attach/4` (or equivalent) at **application / supervision boundary** for **one** high-signal **`[:accrue, :ops, …]`** event — narrative picks **either** webhook pipeline health (**e.g. DLQ dead-lettered**) **or** payment health (**e.g. charge_failed**); planner chooses one coherent story for the guide + host.
- **D-11:** **Do not** use “subscribe to all `[:accrue, :billing, …]`” as the default onboarding path — cardinality and reader overload risk.
- **D-12:** **Optional second snippet** (same guide section): **one** billing span, **only** `:stop` and `:exception`, with explicit prose: **no** customer/subscription IDs (or other unbounded values) as **metric tags**; identifiers belong in traces/logs or scrubbed handlers.
- **D-13:** If a **familiar host namespace** is used in prose (e.g. “Accounts”), implement attach via a **small dedicated module** started **once** from `Application` — **not** per-request attach inside hot context code.

### 4 — Example host (`accrue_host`) and `defaults/0`

- **D-14:** **`AccrueHostWeb.Telemetry.metrics/0`** must **`++ Accrue.Telemetry.Metrics.defaults()`** so the canonical host matches **`Accrue.Telemetry.Metrics` moduledoc** and the guide’s default recipe — closes current mismatch (deps present without Accrue metrics).
- **D-15:** Keep **reporter** as **commented** supervisor child (or equivalent pointer) so beginners understand metrics are inert without a reporter; align **`telemetry_metrics`** semver in the example **`mix.exs`** with the guide / core optional pin when touched (`~> 1.1` per guide direction).
- **D-16:** **Document** empty `telemetry_poller` / periodic measurements as **Phoenix default** or add a trivial justified measurement — avoid unexplained dead weight where easy.
- **D-17:** **Secondary path (callout only):** teams using **OTel-only** may skip `Telemetry.Metrics` — one short paragraph pointing to attach-only pattern; **not** the default cloned-host story.

### 5 — Requirements / traceability hygiene

- **D-18:** When Phase 41 ships, **reconcile** `.planning/REQUIREMENTS.md` — TEL-01 checkbox vs traceability table (OBS-02/TEL-01 Phase 41 rows) so published REQ state matches closure.

### Claude's Discretion

- Exact **subsection title** and **which single ops event** anchors the primary narrative (DLQ vs charge failed).
- Whether the optional **billing span** snippet ships in Phase 41 or is deferred if scope tightens — preference is **include** if copy stays short.
- Exact test module naming and small refactors to share `@expected_ops_events` without over-engineering.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & planning
- `.planning/ROADMAP.md` — Phase 41 goal; v1.9 milestone success criteria (TEL-01)
- `.planning/REQUIREMENTS.md` — **TEL-01**, **OBS-02** (reconcile checkbox vs table on close)
- `.planning/PROJECT.md` — v1.9 vision: discoverable telemetry, host recipes, no Stripe Dashboard parity
- `.planning/research/v1.9-TELEMETRY-GAP-AUDIT.md` — §2 metrics vs ops history (§1 superseded by guide)

### Phase 40 handoff
- `.planning/phases/40-telemetry-catalog-guide-truth/40-CONTEXT.md` — catalog SSOT, `OpsEventContractTest` pattern, deferred Phase 41 items

### Ship targets (code + docs)
- `accrue/guides/telemetry.md` — ops catalog + new cross-domain / metrics wiring subsection
- `accrue/lib/accrue/telemetry/metrics.ex` — `defaults/0` implementation and moduledoc contract
- `accrue/test/accrue/telemetry/ops_event_contract_test.exs` — ops allowlist to align with for parity tests
- `examples/accrue_host/lib/accrue_host_web/telemetry.ex` — append `defaults/0`, reporter comments
- `examples/accrue_host/mix.exs` — `telemetry_metrics` version alignment
- `examples/accrue_host/lib/accrue_host/application.ex` (or new small module) — attach lifecycle for cross-domain example

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets
- **`Accrue.Telemetry.OpsEventContractTest`** — `@expected_ops_events` / guide + lib scan pattern; extend or share for metrics parity.
- **`Accrue.Telemetry.Metrics.defaults/0`** — already lists ops counters including PDF, ledger upcast, Connect; parity test proves ongoing alignment.
- **`examples/accrue_host`** — already declares `:telemetry_metrics` / poller; missing **`++ Accrue.Telemetry.Metrics.defaults()`** — natural integration surface for D-14.

### Established patterns
- **Ops** = `[:accrue, :ops, …]` low-cardinality SRE signals; **billing spans** = high-volume firehose — docs must not teach tagging unbounded ids on metrics.
- **Conditional compile** on `Telemetry.Metrics` in core — tests must respect the optional-dep split.

### Integration points
- Host **`Application.start/2`** or dedicated **`Observability`** child for `:telemetry.attach/4` (idiomatic attach-once).
- ExDoc **extras** already pull `guides/*.md` — keep one primary observability guide for Hex readers.

</code_context>

<specifics>
## Specific Ideas

- Subagent research consensus: **machine-verifiable** parity like OBS-01 (ExUnit), **guide + compile-checked example** like Stripe-style SDK docs, **ops-first** tutorial default with optional bounded billing snippet, **production-shaped** `Telemetry.metrics/0` in the example host.
- Ecosystem lessons: avoid Rails-style string-only notification drift; prefer AppSignal/Honeybadger-style explicit contracts for library telemetry.

</specifics>

<deferred>
## Deferred Ideas

- **Standalone `mix` task** for metrics–ops parity (only if non-ExUnit consumers need it).
- **Dedicated second guide** `guides/host_observability.md` (only if `telemetry.md` splits later).
- **Phase 42:** full operator runbook narrative per **RUN-01**.
- **v1.10+:** metering API documentation per metering spike.

### Reviewed Todos (not folded)

- None — `todo.match-phase` returned no matches for phase 41.

</deferred>

---

*Phase: 41-host-metrics-wiring-cross-domain-example*  
*Context gathered: 2026-04-21*
