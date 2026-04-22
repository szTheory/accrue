# Phase 43: Meter usage happy path + Fake determinism - Context

**Gathered:** 2026-04-21  
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver **MTR-01..MTR-03**: public `Accrue.Billing.report_usage/3` and `report_usage!/3` with documented **NimbleOptions**, **`accrue_meter_events`** lifecycle semantics (**pending → reported** on Fake happy path), and **ExUnit** that proves deterministic outcomes **without** importing private implementation modules — **before** Phase 44 expands sync failure, reconciler, and webhook surfaces.

**Explicitly not this phase:** `meter_reporting_failed` multi-source catalog alignment (Phase **44–45**), new **PROC-08** processor work, Stripe Dashboard meter UX, full telemetry catalog proofs for meter ops.

</domain>

<decisions>
## Implementation Decisions

### 1 — Public assertion surface (MTR-03) and developer ergonomics

- **D-01 (primary):** Treat **durable billing state** as the default contract tests prove: `{:ok, %Accrue.Billing.MeterEvent{}}` from `report_usage/3` plus **Repo-backed** reads of `accrue_meter_events` (status `reported`, expected `identifier` / `value` / timestamps where they are part of the row contract). This matches **Ecto + Sandbox** idioms used across Phoenix host apps and avoids coupling tests to processor-specific map shapes.
- **D-02 (Fake / processor-shaped assertions):** Extend the **existing** public test facade **`Accrue.Test`** (already owns `setup_fake_processor/1` and other setup helpers) with a **`meter_events_for/1`**-class function that **delegates** to `Accrue.Processor.Fake.meter_events_for/1` and **fails fast** when the configured processor is not Fake (same guardrail idea as `Oban.Testing`). Rationale: (a) hosts already discover test helpers through `Accrue.Test`; (b) avoids documenting “import `Accrue.Processor.Fake`” as the primary path; (c) coheres with **Accrue.Test** as the single test-only namespace, keeping **`Accrue.Billing`** free of test-only APIs.
- **D-03:** **Do not** assert via private modules (`MeterEventActions`, internal GenServer callbacks, etc.) in ordinary MTR-01..MTR-03 tests. `Accrue.Processor.Fake` may remain the **implementation** behind `Accrue.Test.meter_events_for/1`; advanced users may call Fake directly, but **published** guidance and examples use **`Accrue.Test`** + Repo assertions.

### 2 — Deterministic identifiers and parallel ExUnit

- **D-04:** For **golden / documented** vectors and idempotency proofs, use **explicit `operation_id`** (and when needed, **fixed `identifier`**) together with a **fixed `timestamp`** passed in opts — never wall-clock for stability across runs and docs.
- **D-05:** For **routine happy-path** tests under `async: true`, prefer **auto-generated per-invocation `operation_id`** built from a readable prefix plus a **process- or test-local uniqueness** source (e.g. `System.unique_integer/1` and/or module-aware seeding). **Do not** use compile-time module attributes as “unique per test” ids. Avoid asserting the **full derived `identifier`** unless that derivation is what the test is meant to lock.
- **D-06:** Document the **levers** in order of preference: **`operation_id` override** (dedupe / replay narratives) → **`timestamp` in opts** (clock stability) → **`identifier` override** only for lower-layer or legacy/import scenarios (overriding `identifier` bypasses derivation you usually want Phase 43 tests to exercise).

### 3 — Documentation placement (MTR-01 pointers, no Phase 45 creep)

- **D-07:** **ExDoc on `Accrue.Billing.report_usage/3` and `report_usage!/3`** is the **single source of truth** for NimbleOptions keys, defaults, and semantics (short structured section; align wording with `@report_usage_schema` so there is no “second schema” in prose).
- **D-08:** Add a **focused fragment** to **`accrue/guides/testing.md`** (“Usage metering (Fake)” or equivalent): happy-path outline, `Accrue.Test.setup_fake_processor/1`, assertion patterns (**Repo row first**, **`Accrue.Test.meter_events_for/1`** when processor-shaped data matters), and **deep links** to HexDocs for options — **without** duplicating the full options table from ExDoc.
- **D-09:** **Do not** add **`guides/metering.md`** in Phase 43 — it invites duplicate ops narrative and preempts Phase **45** (MTR-07..MTR-08). **`guides/telemetry.md`** remains the only ops catalog SSOT (Phase 40/42); Phase 43 may add **at most one sentence + link** to telemetry where a reader asks “what fires when this fails?” and point forward to Phase 44/45 — **no new ops tables** in Phase 43 guides.
- **D-10:** **README / package landing:** at most a **one-line pointer** to the testing guide + `Accrue.Billing.report_usage/3` docs if discoverability gaps show up during implementation — avoid duplicating option lists in README.

### 4 — Telemetry assertions in Phase 43 vs later phases

- **D-11:** **Primary proof in Phase 43** remains **MTR-01..MTR-03** (API + persistence + Fake determinism), not full observability catalog coverage.
- **D-12 (minimal smoke):** Allow **at most one** thin telemetry regression per concern: e.g. attach handler and assert **exactly one** expected **stop** (or start+stop pair) on successful `report_usage`, and **no `:exception`** on the happy path — assert only **event prefix / name** and **1–2 metadata keys** the project is willing to treat as semver-sensitive alongside `guides/telemetry.md`. Prefer centralizing this in a **small helper** (pattern already exists in repo test support) rather than scattering raw `:telemetry.attach` across many tests.
- **D-13:** **Defer** substantive assertions for **`meter_reporting_failed`**, multi-source metadata parity, exception-path instrumentation matrices, and runbook-aligned language to **Phases 44–45**, where roadmap already owns failure + doc alignment — avoids splitting “what telemetry means” across two milestone goals.

### Claude's Discretion

- Exact helper name on `Accrue.Test` (`meter_events_for/1` vs slightly more explicit `fake_meter_events_for/1`) if naming collision or clarity issues arise.
- Whether Phase 43 ships **zero** dedicated telemetry tests vs **one** smoke module — follow **D-12** ceiling either way.
- Exact wording and anchor headings in `guides/testing.md`; optional `import Accrue.Test` macro extension only if it measurably improves host DX without polluting default imports.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and milestone
- `.planning/REQUIREMENTS.md` — **MTR-01**, **MTR-02**, **MTR-03** (Phase 43 rows)
- `.planning/ROADMAP.md` — v1.10 table; Phase 43 goal and success criteria
- `.planning/PROJECT.md` — v1.10 narrative; Fake parity; telemetry expectations at milestone level
- `.planning/research/v1.10-METERING-SPIKE.md` — public vs internal split; suggested acceptance scenarios (full set spans 43–45)

### Prior phase constraints (non-negotiable patterns)
- `.planning/phases/40-telemetry-catalog-guide-truth/40-CONTEXT.md` — **`guides/telemetry.md`** ops catalog SSOT
- `.planning/phases/42-operator-runbooks/42-CONTEXT.md` — compact runbook table + `operator-runbooks.md`; **`meter_reporting_failed`** mini-playbook class (implementation mostly Phase 44+)

### Code entry points (implementation anchors)
- `accrue/lib/accrue/billing.ex` — `report_usage/3`, `report_usage!/3`
- `accrue/lib/accrue/billing/meter_event_actions.ex` — `@report_usage_schema`, transactional outbox + processor call ordering
- `accrue/lib/accrue/billing/meter_event.ex` — schema and state semantics
- `accrue/lib/accrue/processor/fake.ex` — `report_meter_event/1`, `meter_events_for/1` (test helper implementation)
- `accrue/lib/accrue/test.ex` — public test facade; extend for meter assertions per **D-02**

### Docs ship targets
- `accrue/guides/testing.md` — Phase 43 fragment per **D-08**
- ExDoc for `Accrue.Billing` — options SSOT per **D-07**

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets
- **`Accrue.Test`** — already provides **`setup_fake_processor/1`**; same module should expose **`meter_events_for/1`** facade per **D-02** (matches existing `Accrue.Test.*` assertion modules pattern).
- **`Accrue.Processor.Fake.meter_events_for/1`** — returns captured meter events in insertion order; becomes implementation behind the facade.
- **`Accrue.Billing.MeterEvent`** and **`MeterEventActions`** — outbox lifecycle and NimbleOptions validation already implemented; Phase 43 is proof + docs + public test ergonomics.

### Established patterns
- **Transactional outbox** — insert `pending` inside `Repo.transact/2`, processor call **outside** transaction (documented in `MeterEventActions` moduledoc).
- **Idempotency** — `identifier` uniqueness at audit layer; tests should prefer **`operation_id`** as the human-controlled dedupe lever (see **D-04..D-06**).

### Integration points
- Host **`DataCase`** tests: `Accrue.Test.setup_fake_processor/1` in `setup`; assertions via **Repo** + optional **`Accrue.Test.meter_events_for/1`**.
- Phase **44** hooks reconciler + sync failure telemetry; Phase **45** expands guides/telemetry/runbook narrative for meters.

</code_context>

<specifics>
## Specific Ideas

- Cross-ecosystem research consensus (Pay, Cashier, Stripe test-mode patterns): **durable app/DB billing state** is what production ultimately trusts; **processor payload** assertions are secondary and should not be the only layer; **test-only helpers** belong in a **`*.Test`** namespace, not domain modules — Accrue already follows this with **`Accrue.Test`**.
- Rails **ActiveSupport::Testing::NotificationAssertions** and OpenTelemetry SDK testing culture: assert **narrow** instrumentation contracts (event fired, no exception), not entire metadata matrices in early phases.

</specifics>

<deferred>
## Deferred Ideas

- **`guides/metering.md`** full narrative — Phase **45** (MTR-07..MTR-08) unless roadmap explicitly reprioritizes.
- **Deep telemetry + runbook** assertions for `meter_reporting_failed` (**sync / reconciler / webhook** sources) — Phase **44–45** per roadmap and **D-13**.
- **PROC-08** second processor — explicitly out of milestone per **PROJECT.md**.

### Reviewed Todos (not folded)

- None — `todo.match-phase` returned no matches for phase 43.

</deferred>

---

*Phase: 43-meter-usage-happy-path-fake-determinism*  
*Context gathered: 2026-04-21*
