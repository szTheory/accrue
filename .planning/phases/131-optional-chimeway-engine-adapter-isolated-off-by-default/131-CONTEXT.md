# Phase 131: Optional Chimeway Engine Adapter (isolated, off by default) - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

> **How these decisions were made:** Three parallel `gsd-advisor-researcher` agents
> researched the three gray areas (engine behaviour contract · Chimeway adapter
> self-containment · cancel-on-recovery mechanism) against idiomatic Elixir/Oban/
> Chimeway practice, the existing Accrue codebase (Phase 127 isolation pattern,
> Phase 128 dunning seam design, Sigra conditional-compile precedent), and the
> Chimeway 1.0.0 codebase. All three returned unanimous decisive recommendations —
> judged additive/reversible per the project's cohesive-one-shot-synthesis posture.
> Everything below is locked. Build on this; do not re-derive.

<domain>
## Phase Boundary

**DUN-03 only.** Add a swappable `Accrue.Dunning.Engine` behaviour at the two
campaign-boundary seam points in `default_handler.ex`, ship a thin built-in
`Accrue.Dunning.Engine.Oban` wrapper (wrapping existing `DunningStep` enqueue/
cancel logic — no internal restructuring), and add an off-by-default, conditionally-
compiled `Accrue.Integrations.Chimeway` adapter with a bundled `DunningNotifier`
that implements `Chimeway.Notifier` using Accrue's own domain models.

**In scope:**
- `Accrue.Dunning.Engine` behaviour module with 2 callbacks: `start_campaign/3` +
  `cancel_campaign/2`
- `Accrue.Dunning.Engine.Oban` built-in wrapper (wraps existing `DunningStep.enqueue_step`
  + `Oban.cancel_all_jobs` calls currently inlined in `default_handler.ex`)
- `default_handler.ex` dispatch change: `maybe_start_dunning_campaign` + cancel path
  route through configured engine module instead of calling DunningStep directly
- `Accrue.Integrations.Chimeway` — conditionally compiled (`Code.ensure_loaded?(Chimeway)`)
  off-by-default adapter implementing `Accrue.Dunning.Engine`
- Bundled `Accrue.Integrations.Chimeway.DunningNotifier` implementing `Chimeway.Notifier`
  using Accrue's `Customer`/`Subscription` models and existing email templates
- `dunning: [engine: Module]` config key (NimbleOptions-validated, default:
  `Accrue.Dunning.Engine.Oban`)
- Static isolation CI gate (`scripts/ci/verify_dunning_chimeway_isolation.sh`) cloned
  from `verify_core_liveview_runtime_free.sh`
- Docs: `guides/dunning.md` opt-in upgrade section + capability-matrix row for Chimeway

**Out of scope (do NOT pull forward):**
- Any change to `DunningStep`'s internal step-delivery, chaining, cancel-guard (D-11),
  or uniqueness (D-16) logic — the Engine behaviour sits OUTSIDE those internals
- Admin LiveView panel for Chimeway-specific orchestration state (deep Chimeway
  introspection stays in Chimeway per REQUIREMENTS.md Out of Scope)
- Multi-channel notification journeys (email-only, Phase 131 is a scaffold)
- Per-step hook callbacks beyond start/cancel at the campaign boundary

</domain>

<decisions>
## Implementation Decisions

### Engine behaviour contract (D-01)
- **D-01 — 2 thin callbacks: `start_campaign/3` + `cancel_campaign/2`.**
  The behaviour sits at exactly the two call sites already in `default_handler.ex`:
  1. `maybe_start_dunning_campaign/2` → calls engine `start_campaign(sub, anchor_at, opts)` after
     the atomic CAS wins (count == 1). The CAS itself and the DB mutation that sets
     `dunning_campaign_started_at` stay in Accrue's reducer, NOT in the engine.
  2. Cancel path (`maybe_finalize_dunning_campaign` / `cancel_dunning_steps`) → calls engine
     `cancel_campaign(sub, iso_anchor, opts)`.
  DB state ownership (anchor CAS, anchor-clear, `Oban.cancel_all_jobs` for built-in) stays
  inside Accrue's `default_handler.ex` where it is atomic with the subscription write.
  The engine only governs what orchestration system to signal after Accrue has made its
  own state change.
  *Callback signatures:*
  - `start_campaign(subscription :: Subscription.t(), anchor_at :: DateTime.t(), opts :: keyword()) :: :ok | {:error, term()}`
  - `cancel_campaign(subscription :: Subscription.t(), iso_anchor :: String.t(), opts :: keyword()) :: :ok | {:error, term()}`

### Built-in engine wrapper (D-02)
- **D-02 — `Accrue.Dunning.Engine.Oban` wraps existing logic.**
  `start_campaign/3` body = the current `enqueue_day_zero_step` logic (calls
  `DunningStep.enqueue_step`). `cancel_campaign/2` body = the current
  `cancel_dunning_steps` logic (queries Oban jobs by worker + subscription_id +
  campaign_started_at, calls `Oban.cancel_all_jobs`). This is a non-breaking
  extraction — existing hosts see zero behavior change. `default_handler.ex`
  dispatches through `Config.dunning_engine/0` which defaults to
  `Accrue.Dunning.Engine.Oban`.

### Config key shape (D-03)
- **D-03 — `dunning: [engine: Module]` (NimbleOptions type: `{:module, Accrue.Dunning.Engine}`),
  default: `Accrue.Dunning.Engine.Oban`.**
  Nested under the existing `:dunning` config key (consistent with `campaign:`,
  `grace_days:`, `terminal_action:` etc. already there). Accessor:
  `Config.dunning_engine/0` → `Keyword.get(dunning(), :engine, Accrue.Dunning.Engine.Oban)`.
  Boot-validated via NimbleOptions. Doc string MUST state: *"Module implementing
  `Accrue.Dunning.Engine`. Default: `Accrue.Dunning.Engine.Oban` (built-in Oban campaign).
  Set to `Accrue.Integrations.Chimeway` to delegate orchestration to Chimeway."*

### Chimeway adapter: conditional compilation + isolation (D-04)
- **D-04 — `Code.ensure_loaded?(Chimeway)` guard, identical to `Integrations.Sigra` pattern.**
  `if Code.ensure_loaded?(Chimeway) do defmodule Accrue.Integrations.Chimeway do ... end end`
  When Chimeway is absent (the default), the module is never defined and core `accrue`
  has zero Chimeway symbols. The Chimeway dep is `{:chimeway, "~> 1.0", optional: true}` in
  `accrue/mix.exs`. Add `@compile {:no_warn_undefined, [Chimeway, Chimeway.Signal]}` to
  silence compiler warnings when Chimeway is absent.
  **Static isolation gate:** `scripts/ci/verify_dunning_chimeway_isolation.sh` — clone
  `verify_core_liveview_runtime_free.sh` (same `^[^#]*` comment-anchor + allowlist-by-
  construction + `exit 1` on hit). Assert no `Accrue.Integrations.Chimeway` or
  `Chimeway` reference is reachable from the always-on dunning path (`billing/dunning.ex`,
  `workers/dunning_step.ex`, `dunning/campaign.ex`, `webhook/default_handler.ex` built-in
  branch). Wire merge-blocking in CI.

### Chimeway adapter: bundled DunningNotifier (D-05)
- **D-05 — Ship `Accrue.Integrations.Chimeway.DunningNotifier` inside the adapter.**
  The adapter is self-contained — hosts enable Chimeway with one config line and zero
  Chimeway code of their own. The DunningNotifier implements `Chimeway.Notifier` using
  Accrue's own domain models:
  - `notification_key/0` → `"accrue.dunning"` (stable, versioned key)
  - `version/0` → `1`
  - `recipients/1` — resolves `subscription_id` from params → `Subscription` →
    `Customer` → email address
  - `build/2` — constructs dunning notification content using the same step templates
    already in Accrue's mailer (`DunningActionRequired`, `DunningFinalNotice` etc.)
  - `channels/2` → `{:ok, [:email]}` (email-only for v1.40; multi-channel is future scope)
  - `orchestration/2` → `{:ok, :immediate}` (workflow defines the sequencing, not this)
  - `workflow/2` → defines the multi-step Chimeway workflow matching the configured
    dunning cadence steps, with `stop_conditions` on every wait step (see D-06)
  - `rendering/2` → delegates to Accrue email rendering

### Cancel-on-recovery: signal-driven (D-06)
- **D-06 — `Chimeway.Signal.track/4` with `"payment_recovered"` signal.**
  `cancel_campaign/2` in the adapter calls:
  `Chimeway.Signal.track(tenant_id, actor_id, "payment_recovered", %{subscription_id: sub.id})`
  This is durable (Signal row + SignalRouterWorker enqueued in a single `Ecto.Multi`),
  survives node restarts, and produces `{:stopped, run}` terminal state for the entire
  `WorkflowRun` — the only mechanism in Chimeway 1.0.0 that achieves a race-free
  whole-run termination.
  **MANDATORY:** The `DunningNotifier.workflow/2` definition MUST declare
  `stop_conditions: [%{type: :signal_received, signal_type: "payment_recovered"}]`
  on EVERY `:wait` step in the workflow. A missing `stop_conditions` on any wait step
  leaves a gap where Chimeway can still advance to the next step after a recovery signal.
  The adapter's acceptance test MUST assert that no further steps fire after the signal.
  `tenant_id` = `sub.customer_id`; `actor_id` = `"accrue.dunning"` (system actor, not a
  human user).

### Docs (D-07)
- **D-07 — Docs scope.**
  Extend `accrue/guides/dunning.md` with an opt-in upgrade section: "Upgrading to Chimeway
  orchestration" (install steps, config key, what changes, what stays the same). Add a new
  `dunning.engine` row to `.planning/processor-support-matrix.md`:
  stripe/braintree/fake: `built-in (Oban)` + chimeway: `optional adapter (v1.0.0)`.
  Extend `scripts/ci/verify_package_docs.sh` needles. No `accrue_admin` changes (deep
  Chimeway introspection stays out of scope per REQUIREMENTS.md).

### Claude's Discretion
- Exact module layout for `Engine.Oban` (same file as `Engine` behaviour vs. separate
  `engine/oban.ex`) — planner decides; keep it readable.
- Whether `cancel_campaign/2` receives the ISO anchor string or the DateTime struct —
  planner decides based on what `maybe_finalize_dunning_campaign` already passes.
- Exact test tag strategy for the `with_chimeway` matrix cell (`@tag :with_chimeway` vs.
  a mock-based approach since Chimeway requires its own schema/migrations) — planner decides,
  but must not require a running Chimeway instance in the standard `mix test` suite.
- `tenant_id` resolution in `cancel_campaign/2` — `sub.customer_id` is the natural value,
  but confirm against what `start_campaign` threads through.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase requirements and roadmap
- `.planning/ROADMAP.md` — Phase 131 goal + success criteria SC#1–4 (especially SC#4:
  "targeting Chimeway's published 1.0.0 API, resolving guide-vs-code surface mismatch
  before coding")
- `.planning/REQUIREMENTS.md` — DUN-03 (the single requirement for this phase)

### Phase research / context (binding inputs)
- `.planning/phases/128-campaign-engine-foundation-idempotency-must-fix/128-CONTEXT.md` —
  Phase 128 design decisions; DunningStep cancel-guard (D-11), uniqueness (D-16), the
  "future engine seam clean" design note. Engine behaviour sits OUTSIDE DunningStep internals.
- `.planning/phases/127-optional-stripe-native-sync-isolated-off-by-default/127-CONTEXT.md` —
  The precedent for this exact isolation pattern: D-03 (enum config key), D-04 (runtime
  config-gate + isolation gate), conditional compilation approach.
- `.planning/threads/dunning-depth-milestone-prep.md` — Chimeway dependency verdict (option B),
  idiomatic architecture sketch, the verified API surface mismatch warning (guide vs. code).
- `.planning/seeds/SEED-002-ecosystem-integrations.md` — Chimeway as optional integration
  engine, not a hard dep.

### Existing Accrue code (read before planning)
- `accrue/lib/accrue/integrations/sigra.ex` — **The conditional-compile clone target** for
  `Accrue.Integrations.Chimeway`. Follow the 4-pattern exactly.
- `accrue/lib/accrue/webhook/default_handler.ex` — `maybe_start_dunning_campaign/2` (lines
  ~1181–1230) and `maybe_finalize_dunning_campaign/2` / `cancel_dunning_steps` — the two
  seam points the Engine behaviour replaces.
- `accrue/lib/accrue/dunning/campaign.ex` — The pure step resolver (untouched by Phase 131).
- `accrue/lib/accrue/workers/dunning_step.ex` — The built-in Oban campaign worker (internals
  untouched; `Engine.Oban` wraps only the `enqueue_step` entry and the `Oban.cancel_all_jobs`
  cancel path).
- `accrue/lib/accrue/config.ex` — Existing `dunning:` config key (add `engine:` key here).
- `scripts/ci/verify_core_liveview_runtime_free.sh` — **Clone target** for the Chimeway
  isolation CI gate.

### Chimeway 1.0.0 (local + published)
- `/Users/jon/projects/chimeway/lib/chimeway.ex` — Public entry point: `Chimeway.trigger/3`,
  `Chimeway.recover_event/2`, `Chimeway.recover_delivery/2`
- `/Users/jon/projects/chimeway/lib/chimeway/notifier.ex` — `Chimeway.Notifier` behaviour
  callbacks (notification_key, version, recipients, build, channels, rendering,
  delayed_fallback_channels, orchestration, workflow — workflow is optional)
- `/Users/jon/projects/chimeway/lib/chimeway/signal.ex` — `Chimeway.Signal.track/4` (the
  cancel-on-recovery mechanism: Signal row + SignalRouterWorker in `Ecto.Multi`)
- `/Users/jon/projects/chimeway/lib/chimeway/trigger.ex` — `Chimeway.Trigger.trigger/3`
  (the actual trigger implementation; idempotency_key is REQUIRED in opts)
- ⚠️ **API SURFACE MISMATCH (from milestone-prep thread):** The local `mix.exs` says
  version `0.1.0` but Hex has `1.0.0`; the guides may reference old APIs
  (`Chimeway.Workflow`, `Chimeway.Trigger.trigger` directly). **Pin to and target the
  published 1.0.0 API surface** (`Chimeway.trigger/3` public entrypoint, not internal
  modules). Verify current API before coding.

### Idiomatic Elixir/Oban corpus (sibling lib)
- `/Users/jon/projects/lattice_stripe/prompts/elixir-best-practices-deep-research.md`
- `/Users/jon/projects/lattice_stripe/prompts/elixir-opensource-libs-best-practices-deep-research.md`

### Guides to extend
- `accrue/guides/dunning.md` — add opt-in Chimeway upgrade section (D-07)
- `.planning/processor-support-matrix.md` — add `dunning.engine` row (D-07)
- `scripts/ci/verify_package_docs.sh` — add needles for new Chimeway docs (D-07)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets (clone, don't reinvent)
- `accrue/lib/accrue/integrations/sigra.ex` — **Clone target** for `Accrue.Integrations.Chimeway`.
  Same 4-pattern: optional dep, `@compile {:no_warn_undefined, [...]}`, `Code.ensure_loaded?` guard,
  runtime config dispatch.
- `accrue/lib/accrue/webhook/default_handler.ex` `maybe_start_dunning_campaign/2` (lines ~1181–1230)
  + `cancel_dunning_steps` — exact logic that `Engine.Oban` wraps; `default_handler.ex` changes
  to dispatch through `Config.dunning_engine/0` instead.
- `scripts/ci/verify_core_liveview_runtime_free.sh` — **Clone target** for
  `verify_dunning_chimeway_isolation.sh`.
- `accrue/lib/accrue/config.ex` — Add `engine:` key to existing `dunning:` schema (after `campaign:`,
  before NimbleOptions close bracket). Follow `unmapped_action: {:in, [...]}` enum precedent for
  type validation.
- `accrue/lib/accrue/dunning/campaign.ex` — Pure step resolver, **completely untouched** by Phase 131.
- `accrue/lib/accrue/workers/dunning_step.ex` — Built-in campaign worker, **completely untouched**
  by Phase 131 (Engine.Oban wraps the two entry points, nothing inside).

### Established Patterns (constrain this phase)
- **Conditional compile guard** (`Code.ensure_loaded?/1`) — already established by Sigra; follow
  exactly.
- **Runtime config dispatch** — `Config.dunning_engine/0` resolves at call time, not compile time.
  Matches `Config.dunning_campaign_enabled?/0` and `Config.past_due_grace/0` precedents.
- **Off-by-default with default module** — `dunning: [engine: Accrue.Dunning.Engine.Oban]` is
  the default; no config change needed for existing hosts.
- **Isolation gate pattern** — cloned shell script with comment-anchor grep and `exit 1`.

### Integration Points
- `default_handler.ex` `maybe_start_dunning_campaign/2`: change the `1 ->` branch from calling
  `enqueue_day_zero_step/3` directly to calling `Config.dunning_engine().start_campaign(sub, anchor, opts)`.
- `default_handler.ex` cancel path (`maybe_finalize_dunning_campaign` / `cancel_dunning_steps`):
  change from `Oban.cancel_all_jobs` call to `Config.dunning_engine().cancel_campaign(sub, iso_anchor, opts)`.
- `accrue/mix.exs`: add `{:chimeway, "~> 1.0", optional: true}` to `deps/0`.

</code_context>

<specifics>
## Specific Ideas

- **`stop_conditions` gap is the correctness risk** for the Chimeway adapter: every `:wait` step
  in `DunningNotifier.workflow/2` MUST declare `stop_conditions: [%{type: :signal_received, signal_type: "payment_recovered"}]`.
  The adapter acceptance test must assert zero further steps fire after `Chimeway.Signal.track/4`
  is called with `"payment_recovered"`.
- **`Chimeway.trigger/3` requires `idempotency_key` in opts** — the adapter's `start_campaign/3`
  must construct a stable key, e.g. `"accrue.dunning:" <> sub.id <> ":" <> iso_anchor`. This
  prevents duplicate triggers from concurrent webhooks (mirrors the Phase 128 atomic CAS design).
- The `Accrue.Dunning.Engine` behaviour module docstring should state plainly: "Engines control
  what orchestration system is invoked at campaign boundaries. DB state (dunning_campaign_started_at)
  is managed by Accrue regardless of engine choice."
- `Accrue.Dunning.Engine.Oban` is the always-shipped built-in — it MUST be loadable without Chimeway
  present (it only references `Accrue.Workers.DunningStep` and `Oban`, both always-on deps).

</specifics>

<deferred>
## Deferred Ideas

- **Multi-channel dunning** (SMS / push / in-app via Chimeway) — unlocked by this adapter; v1.40
  is email-only. The bundled `DunningNotifier.channels/2` returns `[:email]` and that is correct
  for v1.40.
- **Admin Chimeway state visibility** — deep Chimeway introspection (workflow run traces, step history)
  stays in Chimeway's own UI. Admin shows only Accrue's dunning state fields (already shipped in
  Phase 129). Explicitly excluded by REQUIREMENTS.md "Out of Scope."
- **Per-customer cadence override** via Chimeway — global config + Chimeway's workflow handles
  the sequencing. Per-customer journey customization is out of scope for v1.40.
- **`BillingPortal.Configuration` / Chimeway scheduler configuration** from accrue_admin — future.

</deferred>

---

*Phase: 131-optional-chimeway-engine-adapter-isolated-off-by-default*
*Context gathered: 2026-05-25*
