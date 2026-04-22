# Phase 42: Operator runbooks - Context

**Gathered:** 2026-04-22  
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship **RUN-01**: Accrue-maintained operator material mapping high-signal **`[:accrue, :ops, :*]`** events to **first actions**, **Stripe-side verification**, and **Oban-oriented triage** — especially DLQ, meters, dunning, revenue-adjacent signals, and Connect failures — **without** duplicating Stripe Dashboard accounting/reporting semantics or adding billing primitives.

**Doc surface:** Roadmap allows **guide section or linked doc**; this context locks **split reference vs procedure** aligned with Phase **40** (catalog SSOT in `guides/telemetry.md`).

</domain>

<decisions>
## Implementation Decisions

### 1 — Doc topology (reference SSOT vs runbook narrative)

- **D-01:** Add **`accrue/guides/operator-runbooks.md`** as the canonical home for **procedural** RUN-01 depth (ordered triage, Oban atlas, expanded Stripe verification pattern). This matches Elixir ecosystem idioms (**Oban** / **Phoenix**: multiple focused extras, grouped sidebars) and vendor patterns (**Stripe**: separate integration narrative from reference; **APM tools**: short in-ui text + deeper runbooks).
- **D-02:** **`guides/telemetry.md` remains the only ops event catalog SSOT** (Phase 40). The new guide **must not** introduce a competing ops-inventory table; it links to catalog anchors / event tuples by name.
- **D-03:** Keep the existing **compact** `## Operator runbooks (first actions)` **table** in `telemetry.md` as the **fast-scan** surface (bookmark-friendly, matches Datadog/Honeybadger-style “signal → one-line action”). Add a **short preface** immediately before that section: deep procedures, Oban matrix, and mini-playbooks live in **`operator-runbooks.md`** (stable URL for on-call).
- **D-04:** **ExDoc:** `accrue/mix.exs` already includes `Path.wildcard("guides/*.md")` — the new guide is picked up automatically. Optional later: refine **`groups_for_extras`** (e.g. subgroup “Operations”) if the Guides sidebar becomes crowded — planner’s call.

### 2 — Oban queue documentation (drift-resistant)

- **D-05:** Maintain a **single canonical appendix** in **`operator-runbooks.md`**: Accrue-relevant **queue names → worker modules → purpose → typical symptoms → safe actions**, with an explicit intro that **queue names are host-configured** (Accrue documents **defaults / intended** topology; hosts may remap — principle of least surprise).
- **D-06:** In **`telemetry.md`** runbook table rows (and anywhere else scan-optimized), use **hybrid pointers**: at most **one line** per row — primary queue slug + **stable anchor** into the appendix (e.g. `§ Oban topology`) — **never** duplicate the full matrix per row (avoids SRE-class drift footguns).
- **D-07:** **Stretch / planner discretion:** CI or codegen that asserts documented default queue names match **`use Oban.Worker, queue:`** / config patterns — strong defense against rename drift.

### 3 — Action granularity (cognitive load vs maintenance)

- **D-08:** **Default for all ops signals:** remain **one-line “Suggested first actions”** in the `telemetry.md` table (library-appropriate; hosts extend in their own wiki/PagerDuty).
- **D-09:** **Numbered mini-playbooks (3–7 steps)** **only** in **`operator-runbooks.md`** for these four classes where **wrong order** or **unsafe replay** materially worsens billing/data posture:
  1. `[:accrue, :ops, :webhook_dlq, :dead_lettered]`
  2. `[:accrue, :ops, :events_upcast_failed]`
  3. `[:accrue, :ops, :meter_reporting_failed]`
  4. `[:accrue, :ops, :revenue_loss]`
- **D-10:** **Do not** ship full multi-page playbooks per signal in-repo (**C** rejected): fights host customization, rots quickly, hides warnings in length. **Connect**, **dunning exhaustion**, **charge_failed**, **incomplete_expired**, **replay/prune**, **PDF**, etc. stay **one-liners** unless a future phase narrows a gap with evidence.

### 4 — Stripe / Dashboard boundary (Stripe-native finance handoff)

- **D-11:** Use a **two-layer pattern** everywhere expanded runbook prose touches Stripe:
  1. **Accrue layer (stable):** admin / local rows / telemetry / stored foreign keys (`in_*`, `pi_*`, `cus_*`, Connect account ids, etc.).
  2. **Stripe layer (delegated):** verification anchored on **Stripe resource type + identifier** plus **one canonical `https://stripe.com/docs/...` link per check class** — not a retyped Stripe manual.
- **D-12:** Prefer **functional Dashboard language** where a human path is still fastest (e.g. “Developers → Webhooks → event deliveries”) over brittle **deep `dashboard.stripe.com` URLs** or screenshots (Cashier-style URLs help for webhooks but rot; Stripe **docs** URLs are more durable).
- **D-13:** **Forbidden tone:** language that implies Accrue or this runbook is the **finance system of record**, explains **ledger/accounting** semantics, or duplicates **Sigma / reporting** workflows — keep aligned with **PROJECT.md** / **REQUIREMENTS.md** Stripe-native handoff.

### 5 — Cross-cutting research consensus (subagents, 2026-04-22)

- **D-14:** Ecosystem “do right”: **multi-guide Hex extras**, **central inventories** for volatile topology (Oban), **short signal-layer + linked procedure-layer** (Datadog-class), **honest library vs host boundary** (Pay-style deferral of processor truth + Cashier-style concrete operational URLs only where justified).
- **D-15:** Ecosystem “avoid”: **duplicate ops tables**, **stale inline duplicated matrices**, **encyclopedic in-repo playbooks** that imply per-host truth.

### Claude's Discretion

- Exact section titles / anchors in `operator-runbooks.md`; ordering of mini-playbooks; whether the telemetry runbook table eventually slimifies to “summary + link” only after first ship based on reader feedback.
- Optional `groups_for_extras` refinement and optional CI guard for queue-name drift.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & milestone
- `.planning/REQUIREMENTS.md` — **RUN-01** definition; out-of-scope table (no Dashboard parity, no FIN-03)
- `.planning/ROADMAP.md` — Phase 42 goal; v1.9 success criterion **#3** (runbook entries per RUN-01)
- `.planning/PROJECT.md` — v1.9 vision; observability + operator runbooks; Stripe-native finance posture

### Prior phase handoff (non-negotiable patterns)
- `.planning/phases/40-telemetry-catalog-guide-truth/40-CONTEXT.md` — **`guides/telemetry.md`** ops catalog SSOT; narrative subsections; no competing tables
- `.planning/phases/41-host-metrics-wiring-cross-domain-example/41-CONTEXT.md` — metrics parity + cross-domain example; deferred Phase 42 narrative

### Research inputs
- `.planning/research/v1.9-TELEMETRY-GAP-AUDIT.md` — historical gap inventory (§1 superseded by catalog; still useful context)
- `.planning/phases/42-operator-runbooks/42-RESEARCH.md` — phase research stub (open questions pre-discussion)

### Ship targets (code + docs)
- `accrue/guides/telemetry.md` — ops catalog + compact runbook table + link to expanded runbooks
- `accrue/guides/operator-runbooks.md` — **new** procedural home (mini-playbooks, Oban appendix, Stripe two-layer pattern)
- `accrue/mix.exs` — `:extras` already glob-includes `guides/*.md` (no change required for new file)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets
- **`accrue/guides/telemetry.md`** already contains **`## Operator runbooks (first actions)`** with RUN-01-class rows — extend via **preface + deep link**, not a rewrite of Phase 40 catalog ownership.
- **`Accrue.Telemetry.Ops`**, **`Accrue.Telemetry.Metrics`**, and webhook/DLQ/meter/Connect emit sites — source of truth for which queues/workers exist; appendix should trace to these.

### Established patterns
- **Ops** = low-cardinality `[:accrue, :ops, …]`; procedures should not encourage tagging unbounded ids on metrics (Phase 41).
- **Host owns Oban** — runbooks must not imply Accrue starts the job runner.

### Integration points
- **ExDoc extras** publish both guides; **README** or **telemetry.md** header may warrant a one-line pointer to operator runbooks for discoverability (planner decides).

</code_context>

<specifics>
## Specific Ideas

- User requested **all four** gray areas in one shot with **subagent research**; decisions above synthesize parallel research into a **single coherent** architecture: **linked `operator-runbooks.md`**, **hybrid Oban appendix + row pointers**, **table one-liners + four mini-playbooks**, **Stripe resource + docs links** (no finance-dashboard duplication).

</specifics>

<deferred>
## Deferred Ideas

- **CI/codegen** for Oban queue appendix parity — optional stretch (D-07).
- **`groups_for_extras` sidebar** subgroup — only if navigation pain appears.
- **v1.10+ metering** public API docs — `.planning/research/v1.10-METERING-SPIKE.md` (separate milestone).

### Reviewed Todos (not folded)

- None — `todo.match-phase` returned no matches for phase 42.

</deferred>

---

*Phase: 42-operator-runbooks*  
*Context gathered: 2026-04-22*
