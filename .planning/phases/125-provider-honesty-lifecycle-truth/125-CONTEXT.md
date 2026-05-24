# Phase 125: Provider Honesty + Lifecycle Truth - Context

**Gathered:** 2026-05-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Make entitlement resolution **provably identical across Stripe, Braintree, and Fake**
via a documented provider-honest contract (it is *local* for all three — the milestone
thesis), and pin **entitlement-vs-lifecycle truth** as a single source of truth — both
protected by merge-blocking gates. Covers **ENT-08** (provider honesty: capability-matrix
rows + Fake-lane proof + drift gate) and **ENT-09** (lifecycle→entitlement truth-table
SSOT + past-due grace knob).

**In scope:**
- An `entitlements:` capability slice in `Accrue.Processor.Capabilities`
  (`@support_labels` + `@provider_support_labels`) + matching `capabilities/0` rows in the
  Fake/Stripe/Braintree adapters, stating that local plan→feature mapping is **identical**
  across all three providers (Phase 123 D-15 forecast this exact additive change).
- A **Fake-lane deterministic merge-blocking proof** that `LocalMap.resolve/2` is byte-identical
  across providers with zero processor calls.
- A **merge-blocking drift gate** (extends `scripts/ci/verify_processor_support_matrix.sh` +
  `.planning/processor-support-matrix.md`) mirroring the SCM-06 / PROC-24 support-contract pattern.
- A pure-lifecycle billing predicate `Accrue.Billing.Subscription.entitling?/1` + mirrored
  `Accrue.Billing.Query.entitling/1` — the **SSOT for which lifecycle states grant entitlement**,
  which also **closes a current paused fail-OPEN gap** in the resolver.
- The **lifecycle→entitlement truth table** documented in `accrue/guides/lifecycle_semantics.md`
  (the existing lifecycle SSOT guide) + a behavioral pin test over all 8 statuses.
- A **past-due grace knob** (`:entitlements` config) reusing the dunning grace overlay, default
  **fail-closed (`:none`)**.

**Out of scope (later phases — do not build here):** the read-only admin entitlements view +
the PUBLIC `accrue/guides/entitlements.md` + the JTBD ⛔→✅ flip + First Hour/README spine
(126, ENT-11/12); the optional Stripe-native webhook→cache sync + `grant`/`revoke` + ledger
writes + a `native` entitlements capability row (127, ENT-10). Adding a `capabilities/0`
callback to the `Resolver` behaviour is **declined** (see D-01). Atomic seat *enforcement*
stays host-owned (documented recipe, never a core API).
</domain>

<decisions>
## Implementation Decisions

> Ran in **cohesive-synthesis mode** (standing user preference, config-enforced via
> `discuss_auto_all_gray_areas` + `discuss_high_impact_confirm` + `discuss_auto_resolve_low_impact`,
> bar = `discuss_high_impact_confirm_bar`). **Four parallel `gsd-advisor-researcher` agents**
> researched each gray area (pros/cons/tradeoffs; idiomatic Elixir/Ecto/Plug; cross-lib lessons
> from Stripe Entitlements, Pay (Rails), Laravel Cashier, Chargebee, LaunchDarkly/Unleash; the
> SCM-06/PROC-24 + dunning-overlay precedents; `.planning/research/`). All decisions below are
> research-backed and mutually coherent. **ZERO open forks** — every decision is additive/reversible,
> mandated by ENT-08/ENT-09 wording, or a fail-open correction; none crosses the confirm bar.

### A — Provider-honesty capability surface (ENT-08, SC#1)

- **D-01 — Do NOT add a `capabilities/0` callback to `Accrue.Entitlements.Resolver`.** Honesty is
  a **provider** claim (entitlement resolution is identical local derivation across all providers),
  NOT a per-resolver self-description. Honors Phase 123 D-12's explicit deferral ("no `capabilities/0`
  callback yet"). Keeps the resolver single-method (`resolve/2`), avoids inventing a second capability
  vocabulary with no consumer in 125, and keeps Phase 127's `StripeNative` free to introduce a source
  seam *only if it earns its keep*. The one genuinely irreversible move here (adding a callback to a
  published behaviour) is the one we **decline**.
- **D-02 — Add an `entitlements:` group to `Accrue.Processor.Capabilities`** (`@support_labels` +
  `@provider_support_labels`) and an `entitlements: %{local_mapping: true}` map to each adapter's
  `capabilities/0` (Fake @220, Stripe @79, Braintree @17). This is exactly the additive change Phase
  123 **D-15** forecast — zero edit to 123/124's public API. Honest shape: **ONE core `local_mapping`
  capability**, `@support_labels` label `"all first-party"`, provider lanes stating *sameness*
  (e.g. `fake/stripe/braintree: "local-identical"` — a small new lane term, since the existing vocab
  — `native`/`bounded first-party`/`unsupported`/`testing/local-only` — all encode *divergence*, and
  this row's whole point is *convergence*). **Bias minimal — do NOT over-decompose** into a row per
  gate function (`entitled?`/`has_active_plan?`/`features_for`/`entitlement_quantity` are all the same
  local fold). Planner MAY add a single `unmapped_plan_fail_closed` honesty row but should resist matrix
  bloat.
- **D-03 — The honest claim:** entitlement resolution is **provider-INDEPENDENT local derivation** —
  `LocalMap` reads `accrue_customers` + active subs + the `price_id → plan` config and makes **zero
  processor calls**, so Stripe/Braintree/Fake produce identical results from identical local state.
  This identity is *structural* (the resolver takes no processor argument), not coincidental. Stripe's
  native Entitlements API stays **out of the core resolution path** (deferred to the Phase 127 optional
  overlay); **do NOT add a `native` entitlements row now** — it would over-promise a deferred path.
  External practice backs local-first: Stripe itself recommends persisting entitlements locally for
  fast auth checks; LaunchDarkly evaluates flags locally in-SDK.
- **D-04 — Two layers stay cleanly separated.** PROCESSOR capabilities describe Stripe-shaped *gateway*
  behaviour (where providers genuinely diverge — `swap_plan` native vs bounded vs local-only); the
  `entitlements:` row is a read-over-billing concern *identical by construction*. Co-locating it in the
  provider-columned matrix is honest precisely because it makes the contrast legible: "here providers
  differ; here they're identical."
- **D-05 — Fake-lane deterministic merge-blocking proof (SC#1):** new
  `accrue/test/accrue/entitlements/provider_honesty_test.exs` loops `[Accrue.Processor.Fake,
  Accrue.Processor.Stripe, Accrue.Processor.Braintree]` as `:processor`, seeds identical local state,
  calls `Accrue.Entitlements.Resolver.LocalMap.resolve/2`, and asserts the three `resolved` maps are
  `==` **and** that zero processor calls were issued (the proof *that* swapping `:processor` cannot
  change output). Also asserts the new `Capabilities` `:entitlements` labels equal the doc literals
  (the code-side mirror of the bash gate). Runs under the merge-blocking `release-gate` `mix test`.

### B — Drift gate + matrix home (ENT-08, SC#2)

- **D-06 — EXTEND the existing artifacts, do NOT create a dedicated entitlements matrix/gate.**
  Add a clearly-demarcated **Entitlements** section/rows to `.planning/processor-support-matrix.md`
  and `require_substring`/stale-row lines to `scripts/ci/verify_processor_support_matrix.sh`.
  *Rationale:* Phase 123 **D-15 LOCKED** the code labels into `Processor.Capabilities` — one code
  module → one doc SSOT → one gate is the lowest-drift mirror; "mirroring the SCM-06 / PROC-24
  support-contract pattern" most faithfully means *extending that exact artifact*; avoids a second
  matrix doc Phase 126 would have to reconcile. *(Considered + rejected:* a dedicated
  `verify_entitlements_support_matrix.sh` + `.planning/entitlements-support-matrix.md` — cleaner
  layer-separation, but creates a split-brain SSOT against shared code labels and a second artifact
  for 126. Planner may revisit **only** if the entitlements section materially bloats the processor
  script — a reversible call.)
- **D-07 — Do NOT touch the public `accrue/guides/entitlements.md` — Phase 126 owns it (ENT-12).**
  This phase's drift-gate target is the `.planning/`-level SSOT only. No JTBD flip, no public guide,
  no `verify_package_docs.sh` doc-ordering changes here.
- **D-08 — Gate assertions** mirror the `require_substring` + stale-row-guard style: pin the
  entitlements row(s) with the identical-across-providers label; the local-first identity prose
  ("behaves identically across Stripe, Braintree, and Fake", "zero processor calls"); the ENT-10
  deferral honesty ("Stripe-native Entitlements API is not wrapped by `lattice_stripe` 1.1", "local
  mapping remains the canonical default"); and a **NEGATIVE guard** that fails the build if an
  entitlements row ever sprouts a per-provider `native`/`unsupported`/`bounded` divergence label
  (drift back toward implied provider divergence ahead of Phase 127).
- **D-09 — CI wiring + co-update discipline.** The extended gate rides the existing merge-blocking
  `docs-contracts-shift-left` job in `.github/workflows/ci.yml` (it already invokes
  `verify_processor_support_matrix.sh` — extending the script needs **no new CI step**); the Fake-lane
  proof rides the existing merge-blocking `release-gate` `mix test`. **Co-update code labels + matrix
  doc in the SAME PR** (the established `processor_support_matrix_public_ssot_capabilities_code_mirror_same_pr_co_update`
  rule, mirroring Phase 124 D-06).

### C — Lifecycle-truth predicate SSOT (ENT-09, SC#3/#4) + the paused fail-OPEN fix

- **D-10 — Add a pure-lifecycle billing predicate `Accrue.Billing.Subscription.entitling?/1`
  = `active?(s) and not paused?(s) and not canceled?(s)`** + a **mirrored `Accrue.Billing.Query.entitling/1`**
  Ecto fragment. This is the **single source of truth** for "which lifecycle states grant entitlement."
  It lives in **billing** (not entitlements) because it is *pure lifecycle* with zero entitlement-config
  coupling — keeping Phase 123 **D-14** (one-way dependency: entitlements→billing, never reverse) clean —
  and it preserves the codebase's load-bearing "every `Subscription` predicate has a matching `Query`
  fragment" invariant. It composes the three existing predicates (`active?` @147, `paused?` @201,
  `canceled?` @163); `canceling?/1` @175 (paid-through) is already covered because such rows are
  `status: :active` (so `active?` true, `paused?`/`canceled?` false).
- **D-11 — This CLOSES a fail-OPEN gap (security correction, not new policy).** Today
  `LocalMap.fold_active/1` fetches via `Query.active/1` (`status in [:active, :trialing]`) and only
  excludes non-nil `ended_at` (the WR-04 fix). A subscription with `status: :active` + a non-nil
  `pause_collection` payload is **paused** per `Subscription.paused?/1` (a map OR `status == :paused`),
  yet `Query.active/1` **includes it → it currently GRANTS entitlement**, violating ENT-09 "paused ✗".
  `entitling?/1` / `Query.entitling/1` exclude it. `Query.entitling/1` adds `is_nil(s.pause_collection)`
  (Postgres jsonb `IS NULL`) to the active filter; **`Query.active/1` keeps its semantics for other
  callers** (the WR-04 comment's contract). (`status: :paused` rows are already excluded because
  `active?` only admits `:active`/`:trialing`; the gap is specifically the `status: :active` +
  `pause_collection` case.)
- **D-12 — The exact pure-lifecycle truth table** (before the past-due grace overlay):

  | Status / modifier | Entitled? | Basis |
  |---|:---:|---|
  | `:trialing` | ✅ | `active?` includes trialing (Stripe/Pay/Cashier agree) |
  | `:active` | ✅ | normal paid-active |
  | `:active` + `cancel_at_period_end`, period future (`canceling?`) | ✅ | paid-through — revoking strips paid access |
  | `:active` + `pause_collection` non-nil | ✗ | **the gap (D-11)** — `paused?` overrides status |
  | `:active` + `ended_at` non-nil | ✗ | WR-04 — `canceled?` terminal override |
  | `:paused` (legacy status) | ✗ | `paused?` |
  | `:past_due` | ✗ default / ✅ in-grace | **knob (D-15..D-20)** |
  | `:unpaid` | ✗ | dunning-terminal; grace does NOT extend (matches `dunning_sweepable?/1`) |
  | `:canceled` / `:incomplete_expired` / any `ended_at` | ✗ | `canceled?` |
  | `:incomplete` | ✗ | initial payment not yet succeeded — fail-closed until paid |

- **D-13 — `LocalMap.fold_active/1` swaps `Query.active() |> where(is_nil(ended_at))` for
  `Query.entitling()`** as its base fetch (the grace overlay widens this *conditionally* — D-18).
- **D-14 — SSOT home THIS phase:** extend `accrue/guides/lifecycle_semantics.md` (the existing lifecycle
  SSOT guide — add an `entitling` glossary entry + the truth table, consistent with its
  `active`/`canceling`/`paused`/`past_due`/`ended` entries) + a `@doc`/moduledoc anchor on `entitling?/1`.
  The **behavioral pin** is a table-driven (or `stream_data`) test enumerating all 8 `@statuses` ×
  modifiers → expected ✅/✗ (merge-blocking via `release-gate` `mix test`) — cheaper and stronger than a
  doc-substring gate, and consistent with Phase 123 D-10's fail-closed property posture. Do NOT write the
  public `guides/entitlements.md` (Phase 126 references this SSOT). Phase 126's admin view + guide
  **derive from `entitling?/1`** — never re-derive lifecycle truth (PITFALLS #2).

### D — Past-due grace knob (ENT-09, SC#3/#4)

- **D-15 — DEFAULT = strict fail-closed (`past_due_grace: :none`).** A `:past_due` subscription grants
  **no** entitlement by default. *Rationale (auto-resolved, NOT a fork):* this preserves today's shipped
  `active?/1` behavior (already denies past_due) **and** the milestone's headline fail-closed contract
  (Phase 123 D-08/D-10: "the only path to `true` is an affirmative *resolved* match") with zero new
  default-state caveat; the convention is deny-by-default-with-opt-in (Stripe: "your application decides";
  Cashier `valid()` excludes past_due; Pay `active?` = false for past_due — its `on_grace_period?` is
  *cancellation* grace, a different axis); ENT-09's "fail-**safe** knob" reads as "deny is the safe resting
  position, grace is the operator-turned knob." Defaulting to `:dunning` would be the **only** variant that
  materially changes who-gets-access out of the box — *that* is the fork direction; `:none` is the
  conservative, reversible, non-fork choice. A grace grant, when enabled, is still an affirmative,
  *resolved*, configured decision — never a fail-open, so it does not violate D-10.
- **D-16 — Config surface:** ONE new key under the existing `:entitlements` keyword list:
  ```elixir
  past_due_grace: [
    type: {:or, [{:in, [:dunning, :none]}, :pos_integer]},
    default: :none,
    doc: "Entitlement access for :past_due subscriptions. :none (default) fails closed " <>
         "immediately. :dunning honors the dunning grace window (reuses " <>
         "Accrue.Config.dunning()[:grace_days]). A positive integer N honors an " <>
         "entitlement-specific N-day window. Grace grants are affirmative, resolved, " <>
         "configured decisions — never a fail-open."
  ]
  ```
  Boot-validated by the existing `validate_at_boot!/0` (NimbleOptions 1.1 handles the union natively —
  **no custom validator needed**, unlike the price_id-collision check). Add a `past_due_grace/0` accessor
  (mirror `dunning/0`; `entitlements() |> Keyword.get(:past_due_grace, :none)`). Runtime host data under
  `:entitlements`, consistent with Phase 123 D-01..D-03.
- **D-17 — Mechanism + home:** new **pure** helper `Accrue.Entitlements.PastDueGrace.within_grace?/2`
  (config-aware, clock-driven via `Accrue.Clock.utc_now/0` — **never** `DateTime.utc_now/0` directly).
  `within_grace?(sub, grace_days)` ≡ `sub.past_due_since != nil AND now - past_due_since <=
  grace_days*86_400`; `past_due_since == nil → false` (fail-closed). Lives in the **entitlements** layer
  (reads `:entitlements`/`:dunning` config), **never on `Subscription`** (D-14). Composes as an **OR-ed
  clause on top of** the lifecycle predicate: a row is entitlement-bearing iff
  `entitling?(sub) OR (sub.status == :past_due AND within_grace?(sub, grace_days))`. The grace clause only
  ever **adds** `:past_due`-within-window rows; it can never make an otherwise-entitling row deny.
  **`:unpaid` does NOT receive grace** (post-grace dunning-terminal — reconciles the two advisors: grace
  is keyed to `:past_due` only, matching `dunning_sweepable?/1`).
- **D-18 — Resolver fold widening (cost only when enabled):** when `past_due_grace == :none` (default),
  leave `fold_active/1`'s fetch **exactly** as `Query.entitling/1` — zero query change, zero cost for the
  common case. When grace is enabled, widen the fetch to also include `:past_due` rows (a new fragment
  that adds `:past_due` to the status set while keeping the `is_nil(ended_at)` + `is_nil(pause_collection)`
  guards), then apply `within_grace?/2` **per-row in Elixir** (the clock check must stay test-driven —
  awkward in SQL) and **drop** past_due rows that fail the window *before* folding their `price_id` into
  `active_plans`/`features`/`quantities`.
- **D-19 — Telemetry:** add TWO `reason` atoms to the Phase 123 set
  (`:entitled | :not_entitled | :unmapped_plan | :no_active_subscription | :error`):
  **`:past_due_grace`** (granted via the grace window) and **`:past_due_expired`** (denied because the
  grace window lapsed — distinct from `:no_active_subscription`). Telemetry-internal/additive per Phase
  123 **D-18**; `:reason` is already OTel-allowlisted (D-19) — only the atom *values* change. **No** new
  event, **no** `Telemetry.Ops.emit` (no SRE-pageable condition, per D-20). To pick the reason without
  re-querying, the resolver's `resolved` map gains a small **additive** field (e.g. `:via_grace` boolean
  or `:grace_plans` set) so `Accrue.Entitlements` can select the reason.
- **D-20 — Truth-table rendering (SC#4):** `:past_due` is the **only** knob-controlled (conditional) row:
  ✗ with `:none` (default); ✅ within window with `:dunning` / N days. Render it inline in the
  `lifecycle_semantics.md` truth table with a footnote: grace is an affirmative configured grant (the
  fail-closed contract is preserved), measured from `past_due_since` via `Accrue.Clock`, surfaced as
  `reason: :past_due_grace` / `:past_due_expired`. This satisfies "read one canonical table and know
  exactly how the past-due grace knob behaves."

### Config surface added this phase (extends Phase 123/124's `:entitlements` keyword list)
- `past_due_grace:` — `{:or, [{:in, [:dunning, :none]}, :pos_integer]}`, default `:none` (D-16).
- Resolver `resolved` type gains an additive `:via_grace` / `:grace_plans` field for telemetry-reason
  selection (D-19) — non-breaking.
All remain **runtime** host-owned data (read via `Application.get_env`, boot-validated), consistent with
Phase 123 D-01.

### Claude's Discretion (auto-applied; ZERO forks surfaced)
Per the standing synthesis preference + `discuss_high_impact_confirm_bar` (confirm only
irreversible / externally-published-maintainer-commitment / genuine-product-vision forks; additive-safe
or reversible decisions auto-resolve even when public-API-shaped), **no decision crosses the bar**:
- **Decline** the `Resolver.capabilities/0` callback (D-01) — the one irreversible move, declined.
- **Past-due grace default = `:none`** (D-15) — the closest product-flavored candidate; auto-resolves
  because it preserves shipped behavior + the headline contract (`:dunning` default would be the fork).
- New `local-identical` lane label vs reusing existing vocab (D-02) — cosmetic, reversible; chose the
  honest convergence term.
- Extend the processor matrix/gate vs a dedicated entitlements matrix/gate (D-06) — internal file-org,
  reversible; chose extend per the D-15 code-home lock.
- New `:past_due_grace` / `:past_due_expired` reason atoms (D-19) — telemetry-internal/additive.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope & requirements
- `.planning/ROADMAP.md` §"Phase 125" — goal, depends-on (Phase 123), the 4 success criteria.
- `.planning/REQUIREMENTS.md` — ENT-08, ENT-09 (and the milestone goal / out-of-scope table).

### Phase 123/124 (the locked contract this phase extends — read first)
- `.planning/phases/123-config-core-gate-api-foundation/123-CONTEXT.md` — D-11 (Resolver seam shipped),
  D-12 (no `capabilities/0` yet — 125's call), **D-14 (one-way dependency LOCKED)**, **D-15 (the exact
  additive forecast: `entitlements:` rows in `Processor.Capabilities` + support-matrix doc + drift gate)**,
  D-08/D-10 (fail-closed contract + property test), D-18/D-19/D-20 (telemetry reason atoms / OTel allowlist /
  no Ops.emit), D-21 (ledger boundary — entitlement checks stay telemetry-only).
- `.planning/phases/124-enforcement-surfaces-plug-liveview-guards/124-CONTEXT.md` — D-05 (low-ceremony
  static merge gate), D-06 (same-PR SSOT-mirror doc-reconciliation discipline), D-18 (`surface` reason/
  metadata precedent).

### Source files to clone/extend (full paths)
- `accrue/lib/accrue/processor/capabilities.ex` — **the** pattern to mirror: `@support_labels`,
  `@provider_support_labels`, `support_label/1`, `provider_support_label/2`, `for/1`, `supports?/2`
  (add the `entitlements:` group).
- `accrue/lib/accrue/processor/{fake,stripe,braintree}.ex` — `capabilities/0` (Fake @220, Stripe @79,
  Braintree @17) — add `entitlements: %{local_mapping: true}`.
- `scripts/ci/verify_processor_support_matrix.sh` — the drift-gate script to extend (require_substring
  helper + stale-row `grep -Fq`/`grep -Eq` guards + `: OK` echo).
- `.planning/processor-support-matrix.md` — the published SSOT doc to extend (`| Capability | Fake |
  Stripe | Braintree | Public label |` table).
- `accrue/lib/accrue/billing/subscription.ex` — predicates `active?/1` @147, `trialing?/1` @137,
  `past_due?/1` @153, `canceled?/1` @163, `canceling?/1` @175, `paused?/1` @201, `dunning_sweepable?/1`,
  `dunning_exhausted_status/1`; `@statuses` @37; fields `cancel_at_period_end`, `pause_collection`,
  `past_due_since`, `ended_at`, `current_period_end` (add `entitling?/1` + truth-table moduledoc).
- `accrue/lib/accrue/billing/query.ex` — fragments `active/1` @30, `canceling/1` @44, `canceled/1` @55,
  `past_due/1` @64, `paused/1` @69, `dunning_sweep_candidates/2` @80 (add `entitling/1` + the grace-widen
  fragment; mirror the `dunning_sweep_candidates` cutoff math style).
- `accrue/lib/accrue/entitlements/resolver/local_map.ex` — `fold_active/1` @66 (swap base fetch to
  `Query.entitling/1`; conditional grace-widen) and the WR-04 `ended_at` exclusion to fold in.
- `accrue/lib/accrue/entitlements/resolver.ex` — the `resolved` type (add `:via_grace`/`:grace_plans`;
  do NOT add `capabilities/0`).
- `accrue/lib/accrue/entitlements.ex` — the 4 gate fns (reason computation for the grace atoms).
- `accrue/lib/accrue/config.ex` — `:entitlements` schema + `entitlements/0` accessor (add `past_due_grace`),
  `:dunning` schema @228 + `dunning/0` @744, `validate_at_boot!/0`.
- `accrue/lib/accrue/jobs/dunning_sweeper.ex` — how the existing overlay uses `Config.dunning()` + the
  grace window (the math `within_grace?/2` mirrors, inverted).
- `accrue/lib/accrue/clock.ex` — `utc_now/0` (the testable clock the grace check MUST use).
- `.github/workflows/ci.yml` — the merge-blocking `docs-contracts-shift-left` job (runs
  `verify_processor_support_matrix.sh`) + `release-gate` (`mix test`).

### Project guides & conventions
- `accrue/guides/lifecycle_semantics.md` — the existing lifecycle SSOT guide (state glossary:
  active/canceling/paused/past_due/ended). **Extend here** with the `entitling` entry + truth table; the
  new truth must be consistent with this guide's existing definitions.
- `.planning/research/PITFALLS.md` — Pitfall #1 (fail-open), **#2 (lifecycle predicates / "don't re-derive
  truth")**.
- `.planning/research/ARCHITECTURE.md`, `.planning/research/FEATURES.md` — entitlements integration design,
  competitor delta, local-first thesis.
- `CLAUDE.md` — config-vs-runtime boundary; telemetry/observability mandate; behaviour/runtime-dispatch
  culture; the SSOT-mirror co-update discipline.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`Accrue.Processor.Capabilities`**: extend `@support_labels` + `@provider_support_labels` with an
  `entitlements:` group; reuse `support_label/1` / `provider_support_label/2` accessors verbatim.
- **`scripts/ci/verify_processor_support_matrix.sh`**: `require_substring` helper + stale-row guards +
  `: OK` echo — the exact drift-gate template (extend in place).
- **`Subscription.active?/1` / `paused?/1` / `canceled?/1`**: the three predicates `entitling?/1` composes;
  reuse verbatim, never re-derive from raw `.status`.
- **`Accrue.Billing.Query.*`**: the "matching fragment per predicate" pattern — add `entitling/1` + a
  grace-widen fragment; the `dunning_sweep_candidates/2` cutoff math is the grace-window template.
- **`Accrue.Config.dunning/0` + `:dunning` schema**: the grace overlay to reuse (`grace_days`,
  `past_due_since`) — do NOT invent a parallel one.
- **`Accrue.Clock.utc_now/0`**: the testable clock for `within_grace?/2`.
- **`LocalMap.fold_active/1`**: the read path to retarget (`Query.entitling/1`) + conditionally widen.

### Established Patterns
- **Support-contract SSOT (SCM-06 / PROC-24):** capabilities code labels ↔ published matrix doc, pinned
  by a merge-blocking drift gate, co-updated same PR.
- **One-way dependency (Phase 123 D-14):** `Accrue.Entitlements.*` reads billing + config; nothing under
  `billing/` references entitlements. Pure lifecycle truth → billing; config-coupled grace → entitlements.
- **Fail-closed predicate:** boolean `?` fn with a catch-all `false`; the only path to `true` is an
  affirmative resolved match (D-10 property posture).
- **Config-vs-runtime:** host data/flags under `:entitlements`, runtime `get_env`, boot-validated.
- **Telemetry house style:** additive `reason` atoms; bounded-cardinality; no new event without a
  pageable condition; per-check decisions telemetry-only (D-21).

### Integration Points
- Edit `accrue/lib/accrue/processor/capabilities.ex` + `processor/{fake,stripe,braintree}.ex` (capability rows).
- Edit `scripts/ci/verify_processor_support_matrix.sh` + `.planning/processor-support-matrix.md` (drift gate + doc).
- Edit `accrue/lib/accrue/billing/subscription.ex` (`entitling?/1` + moduledoc) + `billing/query.ex`
  (`entitling/1` + grace-widen fragment).
- Edit `accrue/lib/accrue/entitlements/resolver/local_map.ex` (`fold_active/1`), `resolver.ex` (resolved type),
  `entitlements.ex` (reason computation).
- Edit `accrue/lib/accrue/config.ex` (`:entitlements` schema `past_due_grace` + accessor).
- New `accrue/lib/accrue/entitlements/past_due_grace.ex` (pure grace helper).
- Edit `accrue/guides/lifecycle_semantics.md` (entitling glossary + truth table).
- New tests: `accrue/test/accrue/entitlements/provider_honesty_test.exs` (Fake-lane proof) + a lifecycle
  truth-table pin test (all 8 statuses).
- **No migrations, no Ecto schema change, no webhook code, no `accrue_events` writes** in this phase.
</code_context>

<specifics>
## Specific Ideas

- The provider-columned matrix should make the contrast legible: rows like `subscription.swap_plan`
  (native / bounded / local-only) show divergence; the new `entitlements.local_mapping`
  (local-identical across all three) shows convergence — that contrast IS the honesty statement.
- Caller-visible truth target: one canonical table in `lifecycle_semantics.md` where an operator reads
  "trialing ✅, active ✅, canceling ✅, paused ✗, canceled ✗, past_due ✗ (✅ within grace when enabled)"
  and knows exactly how the knob behaves.
- The paused fix is framed as a **fail-OPEN correction**, not a feature: ENT-09 and the existing
  `paused?/1` already declare paused ✗.
- `past_due_grace` ergonomics: `config :accrue, :entitlements, past_due_grace: :dunning` is the one-line
  opt-in for "honor my dunning window"; the default `:none` needs no thought and stays fail-closed.
</specifics>

<deferred>
## Deferred Ideas

- **`Resolver.capabilities/0` callback / a per-resolver source seam** — declined here (D-01); reconsider in
  Phase 127 only if `StripeNative` genuinely needs to self-describe its source.
- **A `native` entitlements capability row + Stripe-native webhook→cache sync + `grant`/`revoke` + ledger
  writes (ENT-10)** → Phase 127 (off by default, needs-deeper-research). Do NOT add the `native` row now.
- **Read-only admin entitlements view + the PUBLIC `accrue/guides/entitlements.md` + JTBD ⛔→✅ flip +
  First Hour/README spine + green package-doc verifiers (ENT-11/12)** → Phase 126 (derives from this
  phase's `entitling?/1` + truth table + provider matrix).
- **A dedicated `verify_entitlements_support_matrix.sh` + `.planning/entitlements-support-matrix.md`** —
  the layer-separated alternative to D-06; revisit only if the entitlements section bloats the processor
  script.
- **Atomic seat enforcement / membership management** — host-owned; documented recipe, never a core API
  (standing out-of-scope).
- **`fetch_entitled/2` / `fetch_entitlement_quantity/2` diagnostic API** — additive-only on a sourced host
  need (Phase 123 D-07; denied-vs-couldn't-check lives in telemetry `reason`).

### Reviewed Todos (not folded)
None — no pending todos matched this phase.
</deferred>

---

*Phase: 125-provider-honesty-lifecycle-truth*
*Context gathered: 2026-05-23*
</content>
</invoke>
