# Phase 123: Config + Core Gate API Foundation - Context

**Gathered:** 2026-05-22
**Status:** Ready for planning

<domain>
## Phase Boundary

A Phoenix developer can declare a **plan→feature/quota map** and gate code on what a
customer has paid for — `Accrue.has_active_plan?/2`, `entitled?/2`, `features_for/1`,
`entitlement_quantity/2` — resolved **entirely from local subscription state** with a
**fail-closed** contract. This is the headline JTBD with **no new tables and no Stripe
dependency**. Covers ENT-01..05.

**In scope:** the `:entitlements` config schema (NimbleOptions, boot-validated); the
`Accrue.Entitlements` context + `Resolver` behaviour seam (`LocalMap` default impl);
the four public gate functions delegated from `Accrue`; the fail-closed property test;
`[:accrue, :entitlements, :check]` telemetry/OTel spans.

**Out of scope (later phases — do not build here):** Plug/LiveView guards (124);
`entitlements:` capability-matrix rows + drift gate (125, ENT-08); admin view + guides
(126); optional Stripe-native webhook→cache sync + `grant`/`revoke` + ledger writes (127,
ENT-10). Atomic seat *enforcement* is host-owned (documented recipe, never a core API).
</domain>

<decisions>
## Implementation Decisions

> Discussion ran in **cohesive-synthesis mode** (standing user preference): 5 parallel
> `gsd-advisor-researcher` agents researched each gray area (pros/cons, idiomatic
> Elixir/Phoenix/Plug/Ecto, cross-language lessons from Pay/Cashier/Stripe/LaunchDarkly/
> Unleash/OpenFeature/pricing_plans, DX, footguns, project-research dir). All decisions
> below are research-backed and mutually coherent. **Zero open forks** — the one
> public-API question (dual-API) was deep-researched and auto-resolved per the sharpened
> `discuss_high_impact_confirm_bar` (additive-safe ⇒ Claude decides).

### A — Plan→Feature/Quota Config Schema (ENT-01)

- **D-01 — Namespace & boundary:** one **top-level `:entitlements`** keyword list,
  **runtime** (declarable in `config/runtime.exs` or `config/config.exs`; read via
  `Application.get_env`, **NOT** `Application.compile_env!` — it is host-owned catalog data
  that legitimately differs per env, e.g. test-mode vs live-mode price_ids, like
  `:branding`/`:dunning`). Still **boot-validated loudly** via the existing
  `Accrue.Config.validate_at_boot!/0` plus a custom loader check.
- **D-02 — Key on logical plan atoms, not raw price_ids.** Each plan entry:
  `features: [atom]` (boolean features), `limits: [atom: pos_integer]` (seat/quota caps),
  `price_ids: [string]` (every processor price — monthly/annual/legacy/test/live — that
  maps to this plan). *Rationale:* robust to price_id churn, one canonical plan identity,
  native NimbleOptions `keys: [*: …]` validation, matches `pricing_plans`/Pay/Stripe
  `lookup_key`; price_id keying (Cashier's coupling pain) rejected.
- **D-03 — Inner keys:** `:plans` (atom-keyed map), `:resolver` (module, default
  `Accrue.Entitlements.Resolver.LocalMap`), `:unmapped_action` (`:deny` | `:raise`,
  **default `:deny`**).
- **D-04 — Unmapped = loud fail-closed (both layers).** Boot builds a `price_id → plan`
  reverse index; the **same price_id under two plans raises at boot** (`Accrue.ConfigError`,
  clone the `validate_descending/1` custom-check pattern, wire into
  `maybe_validate_boot_setup!/1`). At check time an unmapped price_id → `false` (when
  `:deny`) + `reason: :unmapped_plan` telemetry; `:raise` for strict envs. **Never
  silent-allow.**
- **D-05 — One source of truth for plan identity.** Do not duplicate/conflict with the
  existing `Accrue.PlanResolver` (it answers processor-mechanics: "what processor plan is
  this price"); the entitlement map answers *feature* questions, joined on the same
  `SubscriptionItem.price_id`.

**Locked NimbleOptions fragment** (add to `@schema` in `accrue/lib/accrue/config.ex`):

```elixir
entitlements: [
  type: :keyword_list,
  default: [],
  keys: [
    plans: [
      type: :keyword_list, default: [],
      keys: [*: [type: :keyword_list, keys: [
        features:  [type: {:list, :atom}, default: []],
        limits:    [type: {:keyword_list, :pos_integer}, default: []],
        price_ids: [type: {:list, :string}, default: []]
      ]]],
      doc: "Logical plan name (atom) -> entitlement entry …"
    ],
    resolver: [type: :atom, default: Accrue.Entitlements.Resolver.LocalMap,
      doc: "Resolver module (Accrue.Entitlements.Resolver behaviour). Default LocalMap."],
    unmapped_action: [type: {:in, [:deny, :raise]}, default: :deny,
      doc: "Behaviour when an active price_id is unmapped. :deny fails closed; never silent-allow."]
  ]
]
```

**Example host config** (`config/runtime.exs`):

```elixir
config :accrue, entitlements: [
  plans: [
    free: [features: [:basic_reports], limits: [seats: 1, projects: 3]],
    pro:  [features: [:basic_reports, :api_access, :advanced_reports],
           limits: [seats: 10, projects: 100],
           price_ids: ["price_pro_monthly", "price_pro_annual"]],
    enterprise: [features: [:basic_reports, :api_access, :advanced_reports, :sso, :audit_log],
                 limits: [seats: 250], price_ids: ["price_ent_monthly", "price_ent_annual"]]
  ],
  unmapped_action: :deny
]
```

### B — Public Gate API Surface & Fail-Closed Contract (ENT-02, ENT-03, ENT-04)

- **D-06 — Four total functions on `Accrue`, `defdelegate` → `Accrue.Entitlements`:**
  - `has_active_plan?(billable, plan) :: boolean()` — `plan :: atom() | String.t()`
    (atom canonical; a price_id string is also accepted and resolves through the same map)
  - `entitled?(billable, feature) :: boolean()` — `feature :: atom()`
  - `features_for(billable) :: [atom()]` — **sorted, deduped, UNION across all active
    subscriptions** (use `MapSet` internally, `MapSet.to_list |> Enum.sort` at the boundary;
    never leak `MapSet` into the public return)
  - `entitlement_quantity(billable, quota_key) :: non_neg_integer()` — fail-closed `0`;
    returns `min(plan :limits cap, subscription quantity)` when a cap exists, else the
    subscription `quantity`. (`quota_key` is a `:limits` atom, e.g. `:seats`.)
- **D-07 — DUAL-API RESOLVED → boolean-only. Do NOT ship a tuple/`fetch_entitled/2`
  `{:ok,bool}|{:error,_}` variant in Phase 123.** Deep-research verdict: a `?`-predicate +
  `fetch_`-tuple pairing exists **nowhere** in Accrue (the `customer/1`+`customer!/1`
  tuple/bang pair is I/O-only); requirements ENT-03/04/05 enumerate only boolean/value fns
  and route the "denied vs couldn't-check" diagnostic to **telemetry** (the `reason`
  metadata), not a code API; a truthy `{:error,_}` tuple would ship the exact fail-open
  footgun the milestone exists to prevent. PITFALLS.md's "offer a variant" note is
  *conditional* ("for callers who need to"), not "ship now." `fetch_entitled/2` is
  **additive/non-breaking** — defer to a sourced host need.
- **D-08 — Fail-closed mechanics.** A single private resolver returns
  `{:ok, true} | {:ok, false} | {:error, reason}`; the public fn pattern-matches
  `{:ok, true} -> true` as the **sole** true-path, `{:ok, false} | {:error, _} -> false`,
  wrapped in `try/rescue/catch` so exceptions/throws/exits also collapse to the fail-closed
  value. `nil` and wrong-type billable resolve to `{:ok, false}` (not `{:error,_}`).
  Fail-closed values: `false` / `[]` / `0`.
- **D-09 — Read path (zero processor calls, no cross-request cache):**
  `billable → read-only Customer lookup → Billing.Query.active/1 → SubscriptionItem.price_id
  → reverse-index plan → features/limits`. Reuse **`Subscription.active?/1`** as the
  lifecycle predicate (never raw `.status`). **Do NOT call `Accrue.Billing.customer/1`** —
  it is fetch-or-create / effectful; use a read-only customer lookup. billable is an opaque
  host type via the `Accrue.Auth` behaviour, never a concrete Sigra/Lockspire/user struct.
- **D-10 — Property test (`stream_data`) invariant:** for all generated inputs — `nil`,
  arbitrary non-billable terms, billable with no customer, no active sub, active sub whose
  price_id is unmapped, and a Repo/resolver stub that raises — `entitled?/2` → `false`,
  `entitlement_quantity/2` → `0`, `features_for/1` → `[]`. `entitled?/2` is `true` **iff**
  the resolved active-subscription feature set contains the feature.
  *(never-true-on-garbage + true-iff-affirmative-match.)*

### C — Module Layout & Resolver Seam (architecture; ENT-08 honesty stays in Phase 125)

- **D-11 — Ship the `Resolver` behaviour seam NOW** with a single `LocalMap` impl. Matches
  Accrue's behaviour-first habit (`Processor`/`Auth`/`PlanResolver` were each born with their
  default impl on day one — Accrue never extracts behaviours later). Makes Phases 125 & 127
  **purely additive** (no refactor of 123's public API). The YAGNI objection doesn't apply:
  127's `StripeNative` is an already-roadmapped second consumer.
- **D-12 — New files under `accrue/lib/accrue/entitlements/`:**
  - `entitlements.ex` — public context (`entitled?/2`, `has_active_plan?/2`, `features_for/1`,
    `entitlement_quantity/2`), each wrapped in `Accrue.Telemetry.span/3` inline.
  - `entitlements/resolver.ex` — `@behaviour` + `@callback resolve(billable, opts) ::
    {:ok, %{plan: term, features: MapSet.t, quantities: map}} | {:error, term}` +
    `__impl__/0` dispatch. **No `capabilities/0` callback yet** (that's ENT-08/125).
  - `entitlements/resolver/local_map.ex` — default impl (folds active subs' price_ids →
    plan → `%Plan{}`).
  - `entitlements/plan.ex` — value struct `%Accrue.Entitlements.Plan{plan_id, features:
    MapSet.t, quantities: map}`. Pure value type, **no Ecto** (the cache schema is a 127
    concern).
  - MODIFY `config.ex` (the `:entitlements` schema + accessor + boot collision check) and
    `accrue.ex` (the 4 delegates).
- **D-13 — Dispatch (runtime, idiomatic):** `Application.get_env(:accrue, :entitlements, [])
  |> Keyword.get(:resolver, Accrue.Entitlements.Resolver.LocalMap)` — same idiom as
  `Processor.__impl__/0` / `Config.plan_resolver/0`. Resolution is **local-only** in 123
  (never a processor/Stripe call).
- **D-14 — One-way dependency (LOCKED):** `Accrue.Entitlements.*` reads
  `Accrue.Billing.Query`/`Subscription`/`SubscriptionItem`; **nothing under
  `lib/accrue/billing/` may reference `Accrue.Entitlements.*`.** Enforce with a grep/Credo
  check in the 123 verify step. Acyclic — no compile-time hazard.
- **D-15 — Additive-proof for later phases:** 125 adds `entitlements:` rows to
  `Processor.Capabilities` (`@support_labels` + `@provider_support_labels`) + support-matrix
  doc + merge-blocking drift gate (ENT-08) — zero edits to 123's public path. 127 adds
  `resolver/stripe_native.ex` + optional `grant.ex` Ecto schema + gated migration +
  `DefaultHandler` webhook→cache clause behind `stripe_sync: true` — no edit to 123's API.

### D — Telemetry / Observability Contract (ENT-05)

- **D-16 — Canonical events (PLURAL, LOCKED):** `[:accrue, :entitlements, :check,
  :start | :stop | :exception]`; OTel span `accrue.entitlements.check`. This **supersedes**
  the singular `[:accrue, :entitlement, :check]` written in ROADMAP success-criterion #5 and
  ENT-05 — a wording slip. House style = domain segment is the layer name (`Accrue.Entitlements`
  context; `:webhooks` plural precedent verified in `lib/`). **Action:** reconcile ROADMAP
  SC#5 + REQUIREMENTS ENT-05 to the plural form (small doc fix during this phase).
- **D-17 — Span helper:** reuse `Accrue.Telemetry.span/3` **inline** in
  `Accrue.Entitlements.*` (mirror the 3-level-domain template in `storage.ex`/`pdf.ex`/
  `mailer.ex`). **No `span_entitlement` wrapper** in 123 (single-op domain doesn't earn one).
- **D-18 — Metadata map:** `%{feature, result: boolean, resolver: :local_map,
  reason: :entitled | :not_entitled | :unmapped_plan | :no_active_subscription | :error,
  subject_type, subject_id}`. Measurements: **none hand-rolled** (rely on `:telemetry.span/3`
  `duration`). PII rule: `subject_id` = internal UUID, span/event metadata **only**, never a
  default metric tag; never email/name/external ids. The `reason` atom set is
  **telemetry-internal**, not a public function return contract.
- **D-19 — OTel allowlist additions** in `lib/accrue/telemetry/otel.ex` (atom + string
  forms): `:feature`, `:result`, `:resolver`, `:reason`, `:subject_type`, `:subject_id`.
  Bridge no-ops when `:opentelemetry` is absent (guaranteed by existing `OTel.span/3`).
- **D-20 — Fail-closed visibility:** unmapped-plan deny emits `reason: :unmapped_plan` in
  `:stop` metadata so operators see config drift in the firehose. No separate `:unmapped`
  event and no `Telemetry.Ops.emit` in 123 (no SRE-pageable condition yet).
- **D-21 — Ledger boundary (CONFIRMED):** Phase 123 writes **ZERO** `accrue_events` rows.
  `Accrue.Events.record/1` / `record_multi/3` are NOT called in the check path — per-check
  decisions are telemetry-only **forever**. *Forward note (Phase 127, do NOT build now):*
  deliberate grant/revoke/sync ops will record to the immutable ledger
  (`type: "entitlement.granted" | "entitlement.revoked" | "entitlement.synced"`).

### Claude's Discretion (auto-applied; no fork surfaced)

All research-backed and reversible/additive-safe per the standing synthesis preference:
logical-plan keying (D-02), `unmapped_action: :deny` (D-03), `min(cap, quantity)` seats
(D-06), resolver seam in 123 (D-11), plural telemetry name + ROADMAP/ENT-05 reconcile
(D-16), and **boolean-only gate API / no tuple variant (D-07)** — deep-researched, decided
without a user fork.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope & requirements
- `.planning/ROADMAP.md` §"Phase 123" — goal, depends-on, the 5 success criteria.
- `.planning/REQUIREMENTS.md` — ENT-01..05 (and the milestone goal/out-of-scope table).

### Milestone research (HIGH confidence; no external research needed for this phase)
- `.planning/research/SUMMARY.md` — convergent design; Pitfalls 1–5; Phase-1 deliverables.
- `.planning/research/ARCHITECTURE.md` — `Accrue.Entitlements` context + Resolver seam +
  build order (the integration design this phase implements).
- `.planning/research/PITFALLS.md` — Pitfall #1 (fail-open, the dual-API note), #2
  (lifecycle predicates), #3/#4 (local-only read path), #5 (ledger/telemetry split), #7
  (config/mapping drift, unmapped→deny). The "looks done but isn't" checklist.
- `.planning/research/FEATURES.md` — competitor delta + must-have/anti-feature list.
- `.planning/research/JTBD-FRONTIER.md` — entitlements = #1 gap; "thin layer over local state."
- `.planning/seeds/SEED-002-ecosystem-integrations.md` §#4 — adapter-thin identity tie-in.

### Project guides & conventions
- `accrue/guides/lifecycle_semantics.md` — `active` = "counts for entitlement purposes";
  the lifecycle vocabulary the truth table (Phase 125) will pin.
- `.planning/PROJECT.md` — config-vs-runtime boundary, conditional-compilation pattern,
  behaviour/runtime-dispatch culture, telemetry/observability mandate.

### Source files to clone/extend (full paths)
- `accrue/lib/accrue/config.ex` — `@schema` + `validate_at_boot!/0` + custom-check pattern.
- `accrue/lib/accrue.ex` — top-level delegation style (add the 4 delegates here).
- `accrue/lib/accrue/billing/subscription.ex` — `active?/1` (line ~147); `quantity` field.
- `accrue/lib/accrue/billing/query.ex` — `active/1` read fragment (the read path).
- `accrue/lib/accrue/billing/subscription_item.ex` — `price_id` + `quantity`.
- `accrue/lib/accrue/auth.ex`, `accrue/lib/accrue/plan_resolver.ex`,
  `accrue/lib/accrue/processor.ex` (+ `processor/capabilities.ex`) — behaviour +
  runtime-dispatch precedents for the Resolver seam.
- `accrue/lib/accrue/telemetry.ex` (`span/3`) + `accrue/lib/accrue/telemetry/otel.ex`
  (`@allowed_attributes`) + `accrue/lib/accrue/storage.ex` (cleanest 3-level-domain span
  template) — telemetry contract.
- `accrue/lib/accrue/events.ex` — the ledger API (confirm it is NOT called in 123).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`Accrue.Config` (`config.ex`)**: extend `@schema` with the `:entitlements` key; clone
  the merge-with-defaults accessor (e.g. `branding/0`) and the `validate_descending/1`-style
  custom boot check for the price_id-collision guard.
- **`Subscription.active?/1`**: the locked lifecycle predicate (`status in [:active,
  :trialing]`, catch-all `false`). Reuse verbatim; never re-derive from raw `.status`.
- **`Billing.Query.active/1`**: read-only fetch of a billable's active subscriptions — the
  spine of the gate read path.
- **`SubscriptionItem.price_id` / `.quantity`**: the join key to the plan map and the seat
  source for `entitlement_quantity/2`.
- **`Accrue.Telemetry.span/3`**: emits `:start`/`:stop`/`:exception`, merges actor, bridges
  OTel, no-ops when `:opentelemetry` absent. Use inline (storage.ex pattern).
- **`Processor.__impl__/0` / `Config.plan_resolver/0`**: the runtime-dispatch idiom for the
  Resolver seam.
- **`Accrue` top-level module**: currently moduledoc-only — the 4 `defdelegate`s are net-new.

### Established Patterns
- **Behaviour-first:** introduce `Resolver` with its default impl on day one (never extract
  later). One-way context dependency (entitlements → billing, never the reverse).
- **Fail-closed predicate:** boolean `?` fn with a catch-all `false` clause; tuple/bang
  pairs are I/O-only in this codebase.
- **Telemetry house style:** `[:accrue, <domain-layer>, <op>, :start|:stop|:exception]`;
  bounded-cardinality metadata; PII never logged; internal UUIDs on spans only.
- **Config-vs-runtime:** adapter *modules* via `compile_env!`; host *data*/flags via runtime
  `get_env`, boot-validated.

### Integration Points
- `config.ex` `@schema` + boot validation; `accrue.ex` delegates; the new
  `lib/accrue/entitlements/` tree reading `lib/accrue/billing/`; `telemetry/otel.ex`
  allowlist. No migrations, no Ecto schema, no webhook/Plug/LiveView code in this phase.
</code_context>

<specifics>
## Specific Ideas

- Public API names mirror Pay/Cashier intuition but stay Accrue-idiomatic: `has_active_plan?`
  (cf. Pay `subscribed?`), `entitled?`, `features_for`, `entitlement_quantity`.
- Caller ergonomics target: `if Accrue.entitled?(user, :pro), do: …, else: upsell()` — clean,
  impossible to fail open.
- Fail-closed is the *easy* path and the doc-front-and-center function (PITFALLS #1 mandate).
</specifics>

<deferred>
## Deferred Ideas

- **`fetch_entitled/2` (`{:ok, bool} | {:error, reason}`) + `fetch_entitlement_quantity/2`** —
  the diagnostic/"couldn't-check" code API. Additive/non-breaking; ship only on a sourced
  host need (decided against for 123 per D-07). Captured durably in
  `config.json#discuss_default_entitlements_gate_api_surface`.
- **`entitlements:` capability-matrix rows + merge-blocking drift gate (ENT-08)** → Phase 125.
- **Lifecycle→entitlement truth-table SSOT + `past_due` grace knob (ENT-09)** → Phase 125
  (123 simply inherits whatever `Subscription.active?/1` decides).
- **Plug `require_plan`/`require_feature` + LiveView `on_mount` guards (ENT-06/07)** → Phase
  124 (verify the live `accrue/mix.exs` LiveView posture there — it currently declares
  `phoenix_live_view ~> 1.1` **non-optional**).
- **Read-only admin entitlements view + `guides/entitlements.md` + JTBD ⛔→✅ flip
  (ENT-11/12)** → Phase 126.
- **Optional Stripe-native webhook→cache sync + `grant`/`revoke` + ledger writes (ENT-10)** →
  Phase 127 (off by default, needs-deeper-research).
- **Atomic seat enforcement / membership management** — host-owned; documented recipe, never
  a core API (standing out-of-scope).

### Reviewed Todos (not folded)
None — no pending todos matched this phase.
</deferred>

---

*Phase: 123-config-core-gate-api-foundation*
*Context gathered: 2026-05-22*
</content>
</invoke>
