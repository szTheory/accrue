# Phase 125: Provider Honesty + Lifecycle Truth - Research

**Researched:** 2026-05-23
**Domain:** Entitlement resolution provider-honesty contract + lifecycle→entitlement truth SSOT (Elixir/Phoenix billing library, Accrue)
**Confidence:** HIGH — every canonical_ref in CONTEXT.md was opened and verified against live source; line numbers checked; no codebase drift found.

## Summary

This phase is **codebase-mirroring work, not greenfield**. CONTEXT.md already locks 20 research-backed decisions (D-01→D-20) across four sub-areas with ZERO open forks, derived by four parallel advisor agents. My job was to verify the named source anchors are still accurate ground truth so the planner can plan against them without re-reading, surface exact signatures/excerpts for `read_first` + `acceptance_criteria`, and flag any gotchas. **Every canonical_ref verified clean** — all line numbers in CONTEXT.md `<canonical_refs>` are accurate as of this commit (capabilities, subscription predicates, query fragments, config schema/accessors, dunning sweeper, clock, all three adapters' `capabilities/0`). `entitling`, `past_due_grace`, `PastDueGrace`, `past_due_expired`, and `via_grace` are confirmed **net-new** (zero existing references anywhere in lib/test/scripts/guides) — no naming collisions, no accidental shadowing.

The work splits into four mechanically-independent slices that share two established SSOT-mirror disciplines: (A) an additive `entitlements:` capability row in `Processor.Capabilities` + three adapter `capabilities/0` edits + a Fake-lane provider-honesty proof; (B) extending the existing `verify_processor_support_matrix.sh` drift gate + `.planning/processor-support-matrix.md` (same-PR co-update, rides existing `docs-contracts-shift-left` CI job — no new step); (C) a pure-lifecycle `Subscription.entitling?/1` + mirrored `Query.entitling/1` (the SSOT predicate, which also closes a paused fail-OPEN gap) + a truth-table moduledoc/guide entry + an all-8-status pin test; (D) a `past_due_grace` config knob (default fail-closed `:none`) + a pure `Accrue.Entitlements.PastDueGrace.within_grace?/2` helper + conditional resolver fold-widening + two additive telemetry reason atoms.

**Primary recommendation:** Plan four small, independently-mergeable slices (A/B can co-merge in one PR per the same-PR SSOT-mirror rule; C/D are billing+entitlements code). Use struct-literal table-driven tests for the lifecycle pin (the existing `subscription_predicates_test.exs` pattern), reuse the `local_map_test.exs` env-mutation/`async: false` harness for the resolver/grace tests, and reuse `dunning_sweep_candidates/2`'s cutoff math (inverted) for `within_grace?/2`. Do NOT touch the public `guides/entitlements.md` (Phase 126), do NOT add a `native` entitlements row (Phase 127), do NOT add a `Resolver.capabilities/0` callback (declined, D-01).

## Project Constraints (from CLAUDE.md)

These directives bind the planner with the same authority as locked decisions:

- **Config-vs-runtime boundary:** `:entitlements` (incl. the new `past_due_grace`) is **host-owned runtime data** — read via `Application.get_env`/`get!/1`, boot-validated by `validate_at_boot!/0`. NEVER `Application.compile_env!/2`. (Verified: `entitlements/0` @config.ex:874 uses `get!/1`, not compile_env.)
- **Telemetry/observability mandate:** all public entry points emit `:telemetry` start/stop/exception. The grace reason atoms (`:past_due_grace`, `:past_due_expired`) ride the EXISTING `[:accrue, :entitlements, :check]` span — additive `:reason` values only, no new event (D-19, matches D-21 ledger boundary: per-check decisions are telemetry-only, never `accrue_events`).
- **Behaviour/runtime-dispatch culture:** resolution dispatches via `Resolver.__impl__/0`; `entitling?/1` composes existing predicates, never raw `.status` (enforced by `Accrue.Credo.NoRawStatusAccess` — see Pitfall 4).
- **SSOT-mirror same-PR co-update discipline:** code labels in `Processor.Capabilities` and the matrix doc + bash gate MUST be updated in the SAME PR (the `processor_support_matrix_public_ssot_capabilities_code_mirror_same_pr_co_update` rule, Phase 124 D-06).
- **LiveView-runtime-free posture:** untouched by this phase (no LiveView code here). Do not regress it.
- **Money/correctness:** `stream_data` is mandated for math; the grace-window math is integer-day arithmetic, so a table-driven enumeration is acceptable, but a `stream_data` property over the 8 statuses is also in-budget (D-14 allows either).
- **Security:** webhook signature posture, PII-never-logged — untouched here (no webhook code, `subject_id` already PII-safe per entitlements.ex:216-226).

## User Constraints (from CONTEXT.md)

> CONTEXT.md is the authoritative spec. The 20 decisions below are LOCKED — the planner researches/plans THESE, not alternatives. Reproduced faithfully (condensed where verbatim text appears in CONTEXT.md `<decisions>`).

### Locked Decisions

**A — Provider-honesty capability surface (ENT-08, SC#1)**
- **D-01** — Do NOT add a `capabilities/0` callback to `Accrue.Entitlements.Resolver`. The one irreversible move, declined. Resolver stays single-method (`resolve/2`).
- **D-02** — Add an `entitlements:` group to `Accrue.Processor.Capabilities` (`@support_labels` + `@provider_support_labels`) + `entitlements: %{local_mapping: true}` to each adapter `capabilities/0` (Fake @220, Stripe @79, Braintree @17). ONE core `local_mapping` capability; `@support_labels` label `"all first-party"`; provider lanes state *sameness* (`fake/stripe/braintree: "local-identical"` — a new lane term). Bias minimal — do NOT over-decompose per gate function. MAY add a single `unmapped_plan_fail_closed` honesty row but resist matrix bloat.
- **D-03** — The honest claim: entitlement resolution is provider-INDEPENDENT local derivation (zero processor calls; structural, not coincidental). Do NOT add a `native` entitlements row now.
- **D-04** — Two layers stay cleanly separated: processor capabilities = gateway behaviour (providers diverge); the `entitlements:` row = read-over-billing, identical by construction. Co-location makes the contrast legible.
- **D-05** — Fake-lane deterministic merge-blocking proof: `accrue/test/accrue/entitlements/provider_honesty_test.exs` loops `[Fake, Stripe, Braintree]` as `:processor`, seeds identical local state, calls `LocalMap.resolve/2`, asserts the three `resolved` maps are `==` AND zero processor calls. Also asserts the new `Capabilities` `:entitlements` labels equal the doc literals. Runs under `release-gate` `mix test`.

**B — Drift gate + matrix home (ENT-08, SC#2)**
- **D-06** — EXTEND existing artifacts (`.planning/processor-support-matrix.md` + `scripts/ci/verify_processor_support_matrix.sh`). Do NOT create a dedicated entitlements matrix/gate.
- **D-07** — Do NOT touch the public `accrue/guides/entitlements.md` — Phase 126 owns it. This phase's drift-gate target is `.planning/`-level SSOT only.
- **D-08** — Gate assertions mirror `require_substring` + stale-row guards: pin the entitlements row(s) with the identical-across-providers label; the local-first identity prose; the ENT-10 deferral honesty; and a NEGATIVE guard that fails the build if an entitlements row ever sprouts a per-provider `native`/`unsupported`/`bounded` divergence label.
- **D-09** — CI wiring: extended gate rides the existing `docs-contracts-shift-left` job (no new CI step); Fake-lane proof rides `release-gate` `mix test`. Co-update code labels + matrix doc in the SAME PR.

**C — Lifecycle-truth predicate SSOT (ENT-09, SC#3/#4) + paused fail-OPEN fix**
- **D-10** — Add pure-lifecycle `Accrue.Billing.Subscription.entitling?/1` = `active?(s) and not paused?(s) and not canceled?(s)` + mirrored `Accrue.Billing.Query.entitling/1` Ecto fragment. The SSOT for "which lifecycle states grant entitlement." Lives in **billing** (pure lifecycle, zero entitlement-config coupling — keeps Phase 123 D-14 clean). Composes existing predicates (`active?` @147, `paused?` @201, `canceled?` @163); `canceling?` @175 (paid-through) already covered (such rows are `status: :active`).
- **D-11** — Closes a fail-OPEN gap (security correction). Today `fold_active/1` fetches via `Query.active/1` and only excludes non-nil `ended_at`. A `status: :active` + non-nil `pause_collection` row is paused per `paused?/1` yet `Query.active/1` includes it → currently GRANTS, violating ENT-09 "paused ✗". `Query.entitling/1` adds `is_nil(s.pause_collection)`. `Query.active/1` KEEPS its semantics for other callers.
- **D-12** — The exact pure-lifecycle truth table (see below, reproduced verbatim).
- **D-13** — `LocalMap.fold_active/1` swaps `Query.active() |> where(is_nil(ended_at))` for `Query.entitling()` as base fetch (grace overlay widens conditionally, D-18).
- **D-14** — SSOT home THIS phase: extend `accrue/guides/lifecycle_semantics.md` (add `entitling` glossary entry + truth table) + `@doc`/moduledoc anchor on `entitling?/1`. Behavioral pin = table-driven or `stream_data` test over all 8 `@statuses` × modifiers → expected ✅/✗ (merge-blocking via `release-gate`). Do NOT write public `guides/entitlements.md`.

**D — Past-due grace knob (ENT-09, SC#3/#4)**
- **D-15** — DEFAULT = strict fail-closed (`past_due_grace: :none`). Preserves shipped `active?/1` behavior + headline fail-closed contract. `:dunning` default would be the only fork direction; `:none` is the non-fork choice.
- **D-16** — Config: ONE new key under `:entitlements`:
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
  Boot-validated by existing `validate_at_boot!/0` (NimbleOptions 1.1 handles the union natively — no custom validator). Add `past_due_grace/0` accessor (mirror `dunning/0`).
- **D-17** — Mechanism: new pure helper `Accrue.Entitlements.PastDueGrace.within_grace?/2` (config-aware, clock-driven via `Accrue.Clock.utc_now/0`). `within_grace?(sub, grace_days)` ≡ `sub.past_due_since != nil AND now - past_due_since <= grace_days*86_400`; `past_due_since == nil → false`. Lives in entitlements layer, never on `Subscription` (D-14). Composes as OR-ed clause: entitlement-bearing iff `entitling?(sub) OR (sub.status == :past_due AND within_grace?(sub, grace_days))`. `:unpaid` does NOT receive grace.
- **D-18** — Resolver fold widening (cost only when enabled): `past_due_grace == :none` → leave `fold_active/1` fetch as `Query.entitling/1` (zero query change). Enabled → widen fetch to include `:past_due` rows (new fragment adds `:past_due` to status set, keeps `is_nil(ended_at)` + `is_nil(pause_collection)`), apply `within_grace?/2` PER-ROW in Elixir, drop past_due rows that fail the window before folding.
- **D-19** — Telemetry: add TWO `reason` atoms (`:past_due_grace`, `:past_due_expired`) to the Phase 123 set. Additive per D-18; `:reason` already OTel-allowlisted. No new event, no `Telemetry.Ops.emit`. Resolver `resolved` map gains a small additive field (`:via_grace` boolean or `:grace_plans` set) so `Accrue.Entitlements` can select the reason.
- **D-20** — Truth-table rendering: `:past_due` is the ONLY knob-controlled row: ✗ with `:none`; ✅ within window with `:dunning`/N. Render inline in `lifecycle_semantics.md` with a footnote.

### Claude's Discretion (auto-applied; ZERO forks surfaced)
- Decline `Resolver.capabilities/0` (D-01).
- Past-due grace default `:none` (D-15).
- New `local-identical` lane label (D-02).
- Extend processor matrix/gate vs dedicated (D-06).
- New `:past_due_grace`/`:past_due_expired` reason atoms (D-19).

### Deferred Ideas (OUT OF SCOPE — do not build here)
- `Resolver.capabilities/0` callback / per-resolver source seam → Phase 127 only.
- `native` entitlements row + Stripe-native webhook→cache sync + `grant`/`revoke` + ledger writes (ENT-10) → Phase 127. **Do NOT add the `native` row now.**
- Read-only admin entitlements view + public `guides/entitlements.md` + JTBD ⛔→✅ flip + First Hour/README spine + green package-doc verifiers (ENT-11/12) → Phase 126.
- Dedicated `verify_entitlements_support_matrix.sh` + `.planning/entitlements-support-matrix.md` → revisit only if entitlements section bloats the processor script.
- Atomic seat enforcement / membership management → host-owned recipe, never core API.
- `fetch_entitled/2` / `fetch_entitlement_quantity/2` diagnostic API → additive-only on sourced need.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ENT-08 | Provider-honest entitlement resolution via capability-matrix rows + merge-blocking drift gate (mirroring SCM-06/PROC-24). | Slices A+B. Verified `Processor.Capabilities` (`@support_labels`/`@provider_support_labels`/`support_label/1`/`provider_support_label/2`) is the exact mirror template (capabilities.ex:11-153). Verified `verify_processor_support_matrix.sh` `require_substring` + stale-row guard structure (script lines 13-99). Verified the matrix doc header literal + table shape. The Fake-lane proof reuses `local_map_test.exs` harness + the `resolver` swap pattern via `Application.put_env(:accrue, :processor, ...)`. |
| ENT-09 | Lifecycle→entitlement truth-table SSOT (trialing ✅, canceling ✅, paused ✗, canceled ✗) + past-due grace fail-safe knob reusing dunning overlay; documented truth table. | Slices C+D. Verified the three composed predicates (`active?` @147, `paused?` @201, `canceled?` @163) and the `Query.*` "one fragment per predicate" invariant. Verified the paused fail-OPEN gap is real (`fold_active/1` uses `Query.active/1` which is status-only @query.ex:30-32; `paused?/1` admits `status:active + pause_collection map` @subscription.ex:201-205). Verified `dunning_sweep_candidates/2` cutoff math (query.ex:80-92) as the `within_grace?/2` template (inverted). Verified `Config.dunning()` exposes `grace_days` (config.ex:228-242, accessor :744) and `Clock.utc_now/0` (clock.ex:25-31). |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Provider-honesty capability labels | API / Backend (core lib `Processor.Capabilities`) | CI/static (drift gate) | Capabilities are a code-declared support contract; the matrix doc + bash gate are the published mirror + merge guard. |
| Lifecycle→entitlement predicate (`entitling?/1`) | API / Backend (`Accrue.Billing`) | Database (`Query.entitling/1` fragment) | Pure lifecycle truth belongs in billing (D-14 one-way dep); the Ecto fragment lets multi-row queries use identical semantics (PITFALLS #2 "row query == predicate"). |
| Past-due grace decision (`within_grace?/2`) | API / Backend (`Accrue.Entitlements`) | Database (conditional grace-widen fragment) | Config-coupled grace reads `:entitlements`/`:dunning` → entitlements layer (never billing, D-14). The widen fragment fetches candidate rows; the clock check stays in Elixir (D-18). |
| Resolver fold (`LocalMap.fold_active/1`) | API / Backend (entitlements) | Database (read-only) | Already provider-independent local derivation; this phase retargets its base fetch + conditionally widens. Zero processor calls (structural, D-03). |
| Truth-table documentation | Docs (`lifecycle_semantics.md` + moduledoc) | Test (8-status pin) | One canonical operator-readable table; the pin test is the merge-blocking enforcement (cheaper + stronger than a doc-substring gate, D-14). |

## Standard Stack

No new external dependencies. Every tool needed is already in `mix.lock` and verified present.

### Core (all already declared — NO new deps)
| Library | Version (verified in mix.lock) | Purpose in this phase |
|---------|-------------------------------|----------------------|
| `nimble_options` | `~> 1.0` (lattice_stripe + finch pull `~> 1.0`; CLAUDE.md pins `~> 1.1`) | Validate the `past_due_grace` `{:or, [{:in, [:dunning, :none]}, :pos_integer]}` union at boot. The `{:or, ...}` + `:pos_integer` + `{:in, ...}` subtypes are all native NimbleOptions 1.x features — Phase 123/124 already use `{:or, [...]}` and `{:in, [...]}` in the same `:entitlements` schema (config.ex:152, :390, :398, :405), so no custom validator is needed (D-16 confirmed). |
| `ecto` / `ecto_sql` | `~> 3.13` | `Query.entitling/1` + grace-widen fragment (`is_nil/1` jsonb IS NULL on `pause_collection`). |
| `ex_unit` (stdlib) | — | Table-driven 8-status pin test + Fake-lane provider-honesty proof. |
| `stream_data` | `~> 1.3` (test) | OPTIONAL for the lifecycle pin (D-14 allows table-driven OR stream_data). Table-driven is recommended here (8 enumerable statuses × a handful of modifiers — exhaustive, not sampled). |

**Installation:** None. `mix deps.get` already satisfied.

**Version verification:** Performed against `accrue/mix.lock` — `nimble_options ~> 1.0` confirmed as a transitive constraint from `finch 0.21.0` and `lattice_stripe 1.1.0`. No registry install in this phase; all packages are first-party or pre-existing transitive deps. No `[ASSUMED]` package names introduced.

## Package Legitimacy Audit

> **N/A — this phase installs ZERO external packages.** All code uses already-declared, in-tree dependencies (`ecto`, `nimble_options`, `ex_unit`, `stream_data`) and first-party modules. No `mix deps.get` change, no new `mix.exs` entry. slopcheck not applicable.

## Architecture Patterns

### System Architecture Diagram

```
                      ┌─────────────────────────────────────────────────┐
   gate call          │             Accrue.Entitlements                  │
   entitled?/2  ─────▶│  (4 fns: entitled? / has_active_plan? /          │
   has_active_plan?/2 │   features_for / entitlement_quantity)           │
                      │   - fail-closed try/rescue → :error sentinel     │
                      │   - reason selection (incl. NEW grace atoms via   │
                      │     resolved.via_grace / resolved.grace_plans)    │
                      └───────────────┬─────────────────────────────────┘
                                      │ Resolver.__impl__().resolve(billable, [])
                                      ▼
                      ┌─────────────────────────────────────────────────┐
                      │   Accrue.Entitlements.Resolver.LocalMap          │
                      │   (provider-INDEPENDENT — takes NO :processor arg)│
                      │   fold_active/1:                                  │
                      │     base fetch = Query.entitling/1   ◀── NEW      │
                      │       (active ∧ ¬paused ∧ ¬ended)                 │
                      │     IF past_due_grace ≠ :none:                    │
                      │       widen fetch → +:past_due rows  ◀── NEW      │
                      │       per-row within_grace?/2 in Elixir ◀── NEW   │
                      │       drop expired rows before folding           │
                      └──────┬──────────────────────┬───────────────────┘
                             │                      │
              reads local    │                      │ config-coupled grace
              subscription   ▼                      ▼
        ┌──────────────────────────┐   ┌─────────────────────────────────┐
        │ Accrue.Billing.Query     │   │ Accrue.Entitlements.PastDueGrace │
        │   .entitling/1   ◀── NEW │   │   .within_grace?/2   ◀── NEW     │
        │   .entitling_with_grace  │   │   reads Config.dunning()/        │
        │       /1 (or similar)◀NEW│   │   entitlements()[:past_due_grace]│
        │  mirrors Subscription    │   │   clock = Accrue.Clock.utc_now/0 │
        │  predicates 1:1          │   └─────────────────────────────────┘
        └──────────┬───────────────┘
                   │ composes (in-memory predicate twin)
                   ▼
        ┌──────────────────────────────────────────┐
        │ Accrue.Billing.Subscription              │
        │   .entitling?/1 = active? ∧ ¬paused? ∧    │
        │                   ¬canceled?   ◀── NEW     │
        │   (composes existing active?/paused?/      │
        │    canceled?; canceling? auto-covered)     │
        └──────────────────────────────────────────┘

   ── separate, parallel slice (provider-honesty contract) ──

   Adapters' capabilities/0 ──┐
   (Fake/Stripe/Braintree:    │   declare    ┌──────────────────────────────┐
    entitlements:             ├─────────────▶│ Processor.Capabilities        │
     %{local_mapping: true})  │              │  @support_labels.entitlements │
                              │              │  @provider_support_labels.    │
                              │              │    entitlements (local-       │
                              │              │    identical × 3)   ◀── NEW   │
                              │              └──────────────┬───────────────┘
                              │                             │ same-PR mirror
                              │                             ▼
                              │       ┌──────────────────────────────────────┐
                              │       │ .planning/processor-support-matrix.md │
                              │       │   + Entitlements rows        ◀── NEW  │
                              │       └──────────────┬───────────────────────┘
                              │                      │ pinned by
                              │                      ▼
                              │       ┌──────────────────────────────────────┐
                              │       │ verify_processor_support_matrix.sh    │
                              │       │   + require_substring (positive) +    │
                              │       │     NEGATIVE divergence guard ◀── NEW │
                              │       │   (rides docs-contracts-shift-left)   │
                              │       └──────────────────────────────────────┘
                              ▼
   provider_honesty_test.exs (Fake-lane proof): loops [Fake,Stripe,Braintree]
   as :processor, asserts resolve/2 outputs == and zero processor calls.
```

### Component Responsibilities

| File | Change | Verified anchor |
|------|--------|-----------------|
| `accrue/lib/accrue/processor/capabilities.ex` | Add `entitlements:` group to `@support_labels` (label `"all first-party"`) + `@provider_support_labels` (`%{fake/stripe/braintree: "local-identical"}`). Accessors `support_label/1`/`provider_support_label/2` reused verbatim. | @11-99 (both attrs); accessors @123-143 |
| `accrue/lib/accrue/processor/fake.ex` | Add `entitlements: %{local_mapping: true}` to `capabilities/0`. | `capabilities/0` @220 (verified) |
| `accrue/lib/accrue/processor/stripe.ex` | Same. | `capabilities/0` @79 (verified) |
| `accrue/lib/accrue/processor/braintree.ex` | Same. | `capabilities/0` @17 (verified) |
| `scripts/ci/verify_processor_support_matrix.sh` | Add `require_substring` lines for entitlements row(s) + identity prose + ENT-10 deferral honesty; add a NEGATIVE `grep -Fq`/`grep -Eq` guard against per-provider `native`/`unsupported`/`bounded` divergence on an entitlements row. | `require_substring` @13-20; stale-row guards @60-98; `echo OK` @100 |
| `.planning/processor-support-matrix.md` | Add an Entitlements section/rows to the `\| Capability \| Fake \| Stripe \| Braintree \| Public label \|` table + identity prose. | header literal @31; table @31-58 |
| `accrue/lib/accrue/billing/subscription.ex` | Add `entitling?/1` (composes `active?`/`paused?`/`canceled?`) + truth-table moduledoc anchor. Add to `@statuses` doc if needed (no — `@statuses` unchanged). | predicates @137-220; `@statuses` @37-46 |
| `accrue/lib/accrue/billing/query.ex` | Add `entitling/1` (active filter + `is_nil(s.pause_collection)` + `is_nil(s.ended_at)`) + a grace-widen fragment (adds `:past_due` to status set, keeps both nil guards). | `active/1` @30; `paused/1` @69; `dunning_sweep_candidates/2` cutoff @80-92 |
| `accrue/lib/accrue/entitlements/resolver/local_map.ex` | `fold_active/1` swaps base fetch to `Query.entitling/1`; conditional grace-widen + per-row `within_grace?/2` + drop-expired; fold the WR-04 `ended_at` exclusion INTO the fragment (now redundant local `where` can be dropped — it moves into `Query.entitling/1`). Set `:via_grace`/`:grace_plans` on the returned map. | `fold_active/1` @66-95; current WR-04 `where(is_nil(ended_at))` @77 |
| `accrue/lib/accrue/entitlements/resolver.ex` | Extend the `resolved` `@type` with the additive `:via_grace`/`:grace_plans` field. Do NOT add `capabilities/0` (D-01). | `@type resolved` @38-43 |
| `accrue/lib/accrue/entitlements.ex` | Reason computation: select `:past_due_grace` / `:past_due_expired` from the resolved map's new field. | gate fns + `span/6` @61-244; reason atoms @67-149 |
| `accrue/lib/accrue/config.ex` | Add `past_due_grace` key to the nested `:entitlements` schema `keys:` + a `past_due_grace/0` accessor (mirror `dunning/0`). | `:entitlements` schema @355-426; `entitlements/0` @874; `dunning/0` @744-747 |
| `accrue/lib/accrue/entitlements/past_due_grace.ex` | **NEW** pure helper `within_grace?/2` (clock-driven, fail-closed on nil `past_due_since`). | mirrors `dunning_sweep_candidates/2` math (inverted): `now - past_due_since <= grace_days*86_400` |
| `accrue/guides/lifecycle_semantics.md` | Add `entitling` to the State glossary + the D-12 truth table with the D-20 past-due footnote. | State glossary @127-160 |
| `accrue/test/accrue/entitlements/provider_honesty_test.exs` | **NEW** Fake-lane proof (D-05). | harness pattern from `local_map_test.exs` |
| `accrue/test/accrue/billing/subscription_predicates_test.exs` (or a new `entitling_test.exs`) | Add the all-8-status × modifiers `entitling?/1` pin + a `Query.entitling/1` DB-fragment test. | struct-literal pattern @24-78 |

### Pattern 1: SSOT-mirror (capabilities code ↔ matrix doc ↔ bash gate)
**What:** A code-declared support label has exactly one published doc home and one merge-blocking drift gate, co-updated in the same PR.
**When to use:** D-02/D-06/D-08/D-09 — the entitlements capability surface.
**Example (extend in place):**
```elixir
# Source: accrue/lib/accrue/processor/capabilities.ex (verified @11-99)
@support_labels %{
  # ... existing groups ...
  entitlements: %{
    local_mapping: "all first-party"
  }
}

@provider_support_labels %{
  # ... existing subscription/subscription_item/invoice groups ...
  entitlements: %{
    local_mapping: %{
      fake: "local-identical",
      stripe: "local-identical",
      braintree: "local-identical"
    }
  }
}
```
```bash
# Source: scripts/ci/verify_processor_support_matrix.sh (verified @13-20, mirror this helper)
require_substring "| entitlements.local_mapping | local-identical | local-identical | local-identical | all first-party |" "entitlements local-mapping row"
require_substring "behaves identically across Stripe, Braintree, and Fake" "entitlements identity prose"
require_substring "zero processor calls" "entitlements zero-call prose"
require_substring "local mapping remains the canonical default" "ENT-10 deferral honesty"
# NEGATIVE divergence guard (D-08): fail if an entitlements row drifts toward implied provider divergence
if grep -Eq '\| entitlements\.[a-z_]+ \|[^|]*\b(native|unsupported|bounded)\b' "${matrix}"; then
  echo "verify_processor_support_matrix: entitlements row sprouted a per-provider divergence label (drift toward Phase 127 ahead of schedule)" >&2
  exit 1
fi
```

### Pattern 2: Predicate ↔ Query fragment twin (the load-bearing invariant)
**What:** Every `Subscription` boolean predicate has a matching `Query` fragment with identical semantics. New `entitling?/1` MUST get a new `entitling/1` fragment.
**When to use:** D-10. The invariant is enforced by convention + the moduledoc contracts in both files.
**Example:**
```elixir
# Source: accrue/lib/accrue/billing/subscription.ex (composes verified predicates @147/@201/@163)
@doc """
True iff the subscription's pure lifecycle grants entitlement:
active (incl. trialing and paid-through cancel_at_period_end) AND not paused AND not terminated.
This is the single source of truth for which lifecycle states grant entitlement.
See guides/lifecycle_semantics.md for the truth table.
"""
@spec entitling?(%__MODULE__{} | map()) :: boolean()
def entitling?(sub), do: active?(sub) and not paused?(sub) and not canceled?(sub)
```
```elixir
# Source: accrue/lib/accrue/billing/query.ex (mirrors active/1 @30 + paused/1 @69 + canceled/1 @55-61)
@doc "Subscriptions whose lifecycle grants entitlement: active/trialing, not paused, not ended."
@spec entitling(Ecto.Queryable.t()) :: Ecto.Query.t()
def entitling(query \\ Subscription) do
  from(s in query,
    where: s.status in [:active, :trialing] and
           is_nil(s.pause_collection) and
           is_nil(s.ended_at)
  )
end
```
**CRITICAL gotcha:** `Query.entitling/1` must NOT add `s.status == :paused or ...` (the full `paused/1` fragment) — `active/1` already excludes `:paused` status (it only admits `:active`/`:trialing`). The ONLY thing `paused?/1` adds beyond status that `active/1` misses is the `pause_collection` map on a `status: :active` row — so the fragment needs ONLY `is_nil(s.pause_collection)`. Adding `s.status != :paused` is harmless but redundant; adding the legacy-paused OR clause from `paused/1` verbatim would be a copy-paste error.

### Pattern 3: Conditional cost-aware fold widening (D-18)
**What:** The common case (`past_due_grace == :none`) does zero extra query/compute. Only when grace is enabled does the resolver widen the fetch and do per-row clock checks.
**When to use:** `fold_active/1`.
**Example sketch:**
```elixir
# Source: accrue/lib/accrue/entitlements/resolver/local_map.ex (fold_active/1 @66, retarget the base fetch)
defp base_query(customer_id) do
  case Accrue.Config.past_due_grace() do
    :none ->
      Query.entitling()  # zero query change vs today (sans the WR-04 local where, now in the fragment)
    _grace ->
      Query.entitling_with_grace_candidates()  # active|trialing|past_due, ¬paused, ¬ended
  end
  |> where([s], s.customer_id == ^customer_id)
end
# Then for the grace lane, per-row in Elixir (clock check stays out of SQL, D-18):
#   - keep the row if Subscription.entitling?/1 (the active lane), OR
#   - keep it AND tag via_grace if status==:past_due AND PastDueGrace.within_grace?(sub, grace_days)
#   - drop past_due rows that fail the window BEFORE folding price_id into active_plans/features/quantities
```
**Note:** The grace-widen fetch must select enough columns to evaluate `within_grace?/2` per row — i.e. `status`, `past_due_since`, plus the joined `{price_id, quantity}`. The current `fold_active/1` selects only `{i.price_id, i.quantity}` (local_map.ex:80); the grace path needs the subscription row too. Plan for a select shape change ONLY on the grace lane (the `:none` lane keeps the lean `{price_id, quantity}` select).

### Pattern 4: Clock-driven grace window (mirror dunning, inverted)
**What:** `within_grace?/2` is the inverse of `dunning_sweep_candidates/2`'s cutoff: the sweeper picks rows OLDER than grace; entitlement keeps rows YOUNGER than (or equal to) grace.
**Example:**
```elixir
# Source: NEW accrue/lib/accrue/entitlements/past_due_grace.ex
# Math template (inverted): accrue/lib/accrue/billing/query.ex:83
#   sweeper cutoff = Clock.utc_now() - grace_days*86_400 ; sweep if past_due_since < cutoff
# entitlement:    grant if past_due_since != nil AND past_due_since >= cutoff (still inside window)
defmodule Accrue.Entitlements.PastDueGrace do
  @moduledoc "Pure, clock-driven past-due grace-window check. Fail-closed on missing past_due_since."
  @spec within_grace?(map(), pos_integer()) :: boolean()
  def within_grace?(%{past_due_since: nil}, _grace_days), do: false
  def within_grace?(%{past_due_since: %DateTime{} = since}, grace_days)
      when is_integer(grace_days) and grace_days > 0 do
    cutoff = DateTime.add(Accrue.Clock.utc_now(), -grace_days * 86_400, :second)
    DateTime.compare(since, cutoff) != :lt   # since >= cutoff -> still in window
  end
  def within_grace?(_sub, _grace_days), do: false
end
```
**Grace-days resolution:** `:dunning` → `Config.dunning() |> Keyword.fetch!(:grace_days)` (verified default 14, config.ex:233); a `pos_integer N` → use N directly. The `past_due_grace/0` accessor returns the raw config value (`:none | :dunning | pos_integer`); the resolver resolves it to a concrete day count only when widening.

### Anti-Patterns to Avoid
- **Re-deriving lifecycle truth from raw `.status`** in the entitlements layer or the docs/admin (PITFALLS #2). `entitling?/1` is THE source; Phase 126's admin view + guide MUST derive from it.
- **Putting grace logic on `Subscription`** — violates D-14 (billing must not read `:entitlements`/`:dunning` config). Grace lives in `Accrue.Entitlements.PastDueGrace`.
- **Changing `Query.active/1` semantics** to add the pause/ended guards — D-11 is explicit: `active/1` keeps its meaning for OTHER callers (the dunning sweeper, projections). Only `entitling/1` carries the entitlement-grade guards.
- **Adding a `native` entitlements row or a per-provider divergence label** — over-promises the Phase 127 deferred path; the negative bash guard exists to catch exactly this.
- **A new telemetry EVENT for grace** — D-19 forbids it; the grace reasons are additive `:reason` VALUES on the existing `:check` span.
- **Over-decomposing the capability row** into one row per gate function — D-02 says ONE `local_mapping` row (optionally one `unmapped_plan_fail_closed`); resist matrix bloat.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Union config validation (`:dunning`/`:none`/N) | A custom NimbleOptions `{:custom, ...}` validator | `type: {:or, [{:in, [:dunning, :none]}, :pos_integer]}` | NimbleOptions 1.x validates this union natively (D-16); Phase 123/124 already use `{:or, [...]}` + `{:in, [...]}` in the SAME schema. A custom validator only adds surface area + a bypass risk. |
| Grace-window time math | A bespoke seconds calc with `DateTime.utc_now/0` | Mirror `dunning_sweep_candidates/2` (`DateTime.add(Accrue.Clock.utc_now(), -grace_days*86_400, :second)`) | Reuses the testable clock (deterministic via `Accrue.Test.Clock`); `DateTime.utc_now/0` directly would be untestable and violate the clock mandate. |
| Lifecycle edge-case predicates | A new status-string switch | Compose `active?`/`paused?`/`canceled?` | The edges (trialing-as-active, cancel_at_period_end-as-paid-through, pause_collection-map, ended_at-terminal, incomplete_expired) are ALREADY correct in the predicates; re-deriving will get them wrong (PITFALLS #2 lists 5 specific traps). |
| "Zero processor calls" proof | Manual mock-counting plumbing | Snapshot Fake `state.counters` (reset → resolve → assert unchanged) OR attach a `:telemetry` handler to `[:accrue, :processor, ...]` and assert no events | Fake already tracks per-resource counters (`state.counters`, fake.ex:855+); the structural fact (resolver takes no `:processor` arg) is the real proof, the counter/telemetry assertion is the regression guard. |

**Key insight:** This phase's correctness comes almost entirely from *reuse* — the predicates, the query-fragment twin invariant, the dunning grace math, the clock, the capabilities mirror, the SSOT-gate template, and the resolver fail-closed harness all exist. The danger is divergence (a fragment that doesn't match its predicate, a grace clock that bypasses `Accrue.Clock`, a capability row that implies divergence). Plan tasks to reuse, not reinvent.

## Runtime State Inventory

> N/A — this is NOT a rename/refactor/migration phase. Per CONTEXT.md `<code_context>`: "**No migrations, no Ecto schema change, no webhook code, no `accrue_events` writes** in this phase." All `Subscription` fields needed (`status`, `pause_collection`, `past_due_since`, `ended_at`, `current_period_end`, `cancel_at_period_end`) already exist in the schema (verified subscription.ex:53-85). No stored data, live-service config, OS-registered state, secrets/env-var, or build-artifact changes. New config key `past_due_grace` is read-from-env only (no data migration — defaulting to `:none` is the shipped behavior, so existing deployments are unaffected).

## Common Pitfalls

### Pitfall 1: The paused fail-OPEN gap is subtle — `status: :active` + `pause_collection` map
**What goes wrong:** A subscription Stripe paused via `pause_collection` keeps `status: :active` (modern Stripe). `Query.active/1` is status-only (`s.status in [:active, :trialing]`) so it INCLUDES the row → entitlement is currently GRANTED for a paused sub, violating ENT-09 "paused ✗".
**Why it happens:** `paused?/1` correctly checks BOTH `status: :paused` AND `is_map(pause_collection)` (subscription.ex:201-205), but `fold_active/1` fetches via `Query.active/1`, which only catches the legacy `:paused` STATUS, not the `pause_collection` MAP on an active-status row.
**How to avoid:** `Query.entitling/1` adds `is_nil(s.pause_collection)` (Postgres jsonb IS NULL). The pin test MUST include a row with `%Subscription{status: :active, pause_collection: %{"behavior" => "void"}}` → expect ✗, and a DB-fragment test that seeds such a row and asserts `Query.entitling/1 |> Repo.all()` excludes it.
**Warning signs:** A truth-table test that only sets `.status` and never exercises the `pause_collection`-on-active case; an `entitling/1` fragment that filters on status alone.

### Pitfall 2: Predicate/fragment drift (the twin invariant)
**What goes wrong:** `entitling?/1` (in-memory) and `Query.entitling/1` (SQL) disagree on an edge — e.g. the predicate excludes `pause_collection` but the fragment forgets the `is_nil` guard, so single-record checks deny while multi-record queries grant.
**Why it happens:** They're written separately; SQL can't call the Elixir predicate.
**How to avoid:** Author them together; write a cross-check test that seeds each of the 8 statuses (+ the pause/ended/cancel_at_period_end modifiers) and asserts `Subscription.entitling?(row) == (row in Query.entitling() |> Repo.all())` for the same row. This is the strongest guard against drift.
**Warning signs:** Only one of the two has a test; the truth table is asserted only in-memory.

### Pitfall 3: Grace-lane select shape + `:unpaid` leakage
**What goes wrong:** (a) The grace-widen fetch keeps the lean `{price_id, quantity}` select, leaving no `status`/`past_due_since` to evaluate `within_grace?/2` per row. (b) The widen fragment uses `Subscription.past_due?/1` semantics (`:past_due` OR `:unpaid`) and accidentally grants grace to `:unpaid` rows — but D-17 is explicit: `:unpaid` does NOT receive grace (it's dunning-terminal, matching `dunning_sweepable?/1` which is strictly `:past_due`, subscription.ex:217-220).
**How to avoid:** The grace fragment adds ONLY `:past_due` to the status set (NOT `:unpaid`), and the grace-lane select must include the subscription row (or `status` + `past_due_since`) so `within_grace?/2` runs in Elixir. Use `dunning_sweep_candidates/2`'s strict-`:past_due` precedent (query.ex:87) as the model.
**Warning signs:** A grace test that grants an `:unpaid` sub; a widen fragment referencing `Query.past_due/1` (which includes `:unpaid`).

### Pitfall 4: Raw `.status` access trips the Credo rule
**What goes wrong:** Writing `s.status == :active` in `entitling?/1` or the resolver instead of composing predicates → `Accrue.Credo.NoRawStatusAccess` fails `mix credo --strict` (CI release-gate, ci.yml:115).
**Why it happens:** Habit; the truth table is phrased in status terms.
**How to avoid:** `entitling?/1` composes `active?`/`paused?`/`canceled?` (no raw `.status`). The ONE legitimate raw-status site is the grace clause `sub.status == :past_due` — confirm whether the Credo rule allows it in the entitlements layer (it's not a billing-logic gate, it's a grace-eligibility narrowing) or whether a `Subscription.past_due_strict?/1`-style helper is needed. **Open question for the planner** (see below) — but `dunning_sweepable?/1` already encapsulates strict-`:past_due`, so reuse it: `Subscription.dunning_sweepable?(sub)` is exactly `status == :past_due` (verified subscription.ex:217-220) and is Credo-clean.
**Warning signs:** `mix credo --strict` failure on `NoRawStatusAccess`; a bare `s.status ==` in entitlements code.

### Pitfall 5: Forgetting the same-PR co-update (drift gate self-trip)
**What goes wrong:** Editing `Processor.Capabilities` labels without updating `processor-support-matrix.md` (or vice-versa) makes the bash gate fail — OR worse, editing both but not adding the gate assertion, so future drift goes uncaught.
**How to avoid:** D-09 mandates code + doc + gate in ONE PR. Plan slice A (capabilities + adapters) and slice B (matrix doc + bash gate) to land in the same plan/PR.

## Code Examples

### Truth table to render (D-12, verbatim from CONTEXT.md — this IS the spec)

| Status / modifier | Entitled? | Basis |
|---|:---:|---|
| `:trialing` | ✅ | `active?` includes trialing |
| `:active` | ✅ | normal paid-active |
| `:active` + `cancel_at_period_end`, period future (`canceling?`) | ✅ | paid-through |
| `:active` + `pause_collection` non-nil | ✗ | **the gap (D-11)** — `paused?` overrides status |
| `:active` + `ended_at` non-nil | ✗ | WR-04 — `canceled?` terminal override |
| `:paused` (legacy status) | ✗ | `paused?` |
| `:past_due` | ✗ default / ✅ in-grace | **knob (D-15..D-20)** |
| `:unpaid` | ✗ | dunning-terminal; grace does NOT extend |
| `:canceled` / `:incomplete_expired` / any `ended_at` | ✗ | `canceled?` |
| `:incomplete` | ✗ | initial payment not yet succeeded — fail-closed |

### 8-status pin test pattern (struct literals — verified harness)
```elixir
# Source pattern: accrue/test/accrue/billing/subscription_predicates_test.exs:24-78 (verified)
# Pure struct construction needs only the Fake clock started (for canceling?'s Clock.utc_now/0).
test "entitling?/1 truth table over all statuses and modifiers" do
  now = Accrue.Clock.utc_now()
  future = DateTime.add(now, 7, :day)
  past = DateTime.add(now, -1, :day)

  assert Subscription.entitling?(%Subscription{status: :trialing})
  assert Subscription.entitling?(%Subscription{status: :active})
  assert Subscription.entitling?(%Subscription{status: :active, cancel_at_period_end: true, current_period_end: future})
  refute Subscription.entitling?(%Subscription{status: :active, pause_collection: %{"behavior" => "void"}})  # D-11 gap
  refute Subscription.entitling?(%Subscription{status: :active, ended_at: past})                              # WR-04
  refute Subscription.entitling?(%Subscription{status: :paused})
  refute Subscription.entitling?(%Subscription{status: :past_due})    # pure-lifecycle, pre-grace
  refute Subscription.entitling?(%Subscription{status: :unpaid})
  refute Subscription.entitling?(%Subscription{status: :canceled})
  refute Subscription.entitling?(%Subscription{status: :incomplete})
  refute Subscription.entitling?(%Subscription{status: :incomplete_expired})
end
```

### Fake-lane provider-honesty proof (D-05) harness
```elixir
# Source pattern: accrue/test/accrue/entitlements/local_map_test.exs (verified env-mutation + async:false)
# Loop the three processors as :processor; identical local state -> identical resolved map; zero processor calls.
for processor <- [Accrue.Processor.Fake, Accrue.Processor.Stripe, Accrue.Processor.Braintree] do
  Application.put_env(:accrue, :processor, processor)
  # seed identical local state (customer + active sub on a mapped price_id) ONCE, shared across iterations
  {:ok, resolved} = LocalMap.resolve(billable, [])
  # collect resolved into a list; after the loop assert all three == each other
end
# Zero-call proof: snapshot Fake state.counters before/after (Fake.reset/0 then resolve, assert counters unchanged),
# OR attach :telemetry.attach to [:accrue, :processor, :_, :_] and assert handler never fired.
# Plus: assert Capabilities.support_label([:entitlements, :local_mapping]) == "all first-party"
#       and provider_support_label(p, [:entitlements, :local_mapping]) == "local-identical" for each p
#       == the matrix-doc literals (code-side mirror of the bash gate).
```
**Note for the planner:** Stripe/Braintree adapters make real network/SDK calls if invoked — but the WHOLE POINT (D-03) is that `LocalMap.resolve/2` never dispatches to `:processor` (it takes no processor arg and reads only `Accrue.Repo`). So swapping `:processor` is safe precisely because the resolver ignores it. The test proves this structurally; no Stripe/Braintree network access occurs.

## State of the Art

| Old Approach | Current Approach | When | Impact |
|--------------|------------------|------|--------|
| Resolve entitlement from `status == :active` (raw) | Compose lifecycle predicates; `entitling?/1` as SSOT | This phase | Catches trialing/canceling/paused/ended/incomplete_expired edges correctly |
| Stripe-native Entitlements API as source of truth | Local-first derivation across all providers | v1.39 milestone (lattice_stripe 1.1 has no Entitlements API — verified mix.lock) | Provider-independent, fast auth checks; Stripe itself recommends local persistence (PITFALLS #3) |
| Past-due = hardcoded allow/deny | Documented host-configurable knob, fail-safe default | This phase (D-15..D-20) | Operators choose grace policy; default `:none` preserves shipped behavior |

**Deprecated/outdated in this context:** Nothing being removed. All changes are additive (new predicate, new fragment, new config key, new capability row, new helper module, new tests, additive telemetry reasons, additive resolved-map field).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The `Accrue.Credo.NoRawStatusAccess` rule will reject a bare `sub.status == :past_due` in the grace clause, so the planner should route through `Subscription.dunning_sweepable?/1` (strict `:past_due`). I verified `dunning_sweepable?/1` is strict-`:past_due` (subscription.ex:217-220) but did NOT read the Credo rule's exact allowlist/exemptions. | Pitfall 4 | LOW — if the rule exempts entitlements/* or the grace-clause site, a direct `status == :past_due` works; if not, `dunning_sweepable?/1` is the clean reuse. Either way the math is identical. Planner should confirm by reading `accrue/lib/accrue/credo/no_raw_status_access.ex` (or running `mix credo --strict` on a draft). |
| A2 | The "zero processor calls" assertion is best done via Fake `state.counters` snapshot or a `:telemetry` handler. I verified Fake HAS per-resource `state.counters` and increments them in handle_call clauses, but did not confirm a public read accessor for arbitrary counters (only `reset/0` and the connect-preserve path were read). | Code Examples (D-05) | LOW — if no public counter accessor exists, the telemetry-handler approach (Stripe/Braintree emit `[:accrue, :processor, ...]` spans; Fake dispatches via `call/1`) is the fallback, OR the structural argument (resolver takes no `:processor` arg) suffices with a code-comment + the `==` equality assertion. Planner picks the mechanism; both prove the same fact. |
| A3 | NimbleOptions `{:or, [{:in, [...]}, :pos_integer]}` validates the union without a custom validator. I verified the SAME schema already uses `{:or, [...]}` (config.ex:152, :281, :398) and `{:in, [...]}` (config.ex:209, :391), and the installed constraint is `~> 1.0`. I did not run a live `NimbleOptions.validate!/2` of this exact union shape. | Standard Stack / D-16 | LOW — both subtypes are documented NimbleOptions 1.x primitives and combine via `{:or, ...}` per its docs; the in-repo precedents make this near-certain. Boot validation will surface any issue immediately (fail-loud). |

## Open Questions

1. **Capability row count: one or two?**
   - What we know: D-02 mandates ONE `local_mapping` row and explicitly PERMITS a single optional `unmapped_plan_fail_closed` honesty row.
   - What's unclear: whether the second row earns its keep (it documents that an unmapped active price_id fails closed identically across providers — a real honesty claim, verified in `LocalMap.handle_unmapped/3`, local_map.ex:123-128).
   - Recommendation: Default to the ONE `local_mapping` row (minimal). The planner MAY add `unmapped_plan_fail_closed` if it strengthens the contrast without bloat — it's reversible. Lean minimal.

2. **`resolved` map field: `:via_grace` boolean vs `:grace_plans` set?**
   - What we know: D-19 says "e.g. `:via_grace` boolean or `:grace_plans` set" — either is acceptable, additive, non-breaking.
   - What's unclear: a boolean is simplest but loses which plans came via grace; a set is richer for future reason granularity.
   - Recommendation: Use a `:grace_plans` MapSet (consistent with the existing `:active_plans` MapSet shape, resolver.ex:38-43) — it lets `Accrue.Entitlements` pick `:past_due_grace` vs `:past_due_expired` precisely AND keeps the door open for per-feature grace reasoning without another schema bump. Default `MapSet.new()` when grace disabled (zero-cost).

3. **Grace-clause raw-status routing (ties to A1):**
   - What we know: `dunning_sweepable?/1` is the existing Credo-clean strict-`:past_due` predicate.
   - Recommendation: Use `Subscription.dunning_sweepable?(sub)` as the grace-eligibility status check (it's exactly `status == :past_due`, reuse over re-derive). Confirm against the Credo rule during planning.

## Environment Availability

> N/A for blocking purposes — this phase is pure code/config/docs/tests with no NEW external dependency. The existing test+CI toolchain (already used by Phases 123/124) covers it:

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/OTP toolchain | compile + test | ✓ (CI matrix 1.17/1.18 × OTP 27/28, ci.yml) | per CLAUDE.md floor | — |
| PostgreSQL 14+ | `Query.entitling/1` DB-fragment tests | ✓ (release-gate runs DB tests) | 14+ | — |
| `bash` + `grep` | drift-gate script | ✓ (docs-contracts-shift-left job) | — | — |
| Stripe/Braintree network | NOT required — Fake-lane proof is hermetic (D-05) | n/a | — | structural proof; no network |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None.

## Validation Architecture

> Nyquist validation is ENABLED for this phase (config has no `workflow.nyquist_validation: false`).

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir stdlib); `stream_data ~> 1.3` available for properties |
| Config file | `accrue/test/test_helper.exs` + `mix.exs` test config (existing) |
| Quick run command | `cd accrue && mix test test/accrue/entitlements/provider_honesty_test.exs test/accrue/billing/subscription_predicates_test.exs --warnings-as-errors` |
| Full suite command | `cd accrue && mix test --warnings-as-errors` (the `release-gate` job, ci.yml:111-112) |
| Drift gate command | `bash scripts/ci/verify_processor_support_matrix.sh` (the `docs-contracts-shift-left` job, ci.yml:47) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ENT-08 | `LocalMap.resolve/2` byte-identical across Fake/Stripe/Braintree, zero processor calls | unit (Fake-lane proof) | `mix test test/accrue/entitlements/provider_honesty_test.exs` | ❌ Wave 0 |
| ENT-08 | Capabilities `:entitlements` labels == matrix-doc literals | unit | (same file, asserts `support_label`/`provider_support_label`) | ❌ Wave 0 |
| ENT-08 | Matrix doc ↔ code labels drift gate (incl. negative divergence guard) | static/bash | `bash scripts/ci/verify_processor_support_matrix.sh` | ✅ extend existing |
| ENT-09 | `entitling?/1` correct over all 8 statuses × modifiers (incl. paused-on-active gap) | unit (table-driven pin) | `mix test test/accrue/billing/subscription_predicates_test.exs` (or new `entitling_test.exs`) | ✅ extend / ❌ new |
| ENT-09 | `Query.entitling/1` DB fragment == `entitling?/1` per row (twin invariant) | integration (Repo) | `mix test test/accrue/billing/query_test.exs` (or new) | check existing query_test |
| ENT-09 | Paused fail-OPEN gap closed in resolver read path | integration | `mix test test/accrue/entitlements/local_map_test.exs` (add a case) | ✅ extend |
| ENT-09 | `past_due_grace: :none` denies past_due; `:dunning`/N grants within window, denies after | integration (clock-driven) | new grace test (advance `Accrue.Test.Clock` past window) | ❌ Wave 0 |
| ENT-09 | `:unpaid` never granted grace | integration | (same grace test) | ❌ Wave 0 |
| ENT-09 | Telemetry `:reason` = `:past_due_grace` / `:past_due_expired` on grant/deny | unit (telemetry capture) | extend an entitlements telemetry test | check `guard_telemetry_test.exs` pattern |
| ENT-09 | `past_due_grace` boot-validates the union; rejects garbage | unit | extend a config validation test | check existing config test |

### Sampling Rate
- **Per task commit:** the quick-run command (the two net-new + the touched predicate/resolver files).
- **Per wave merge:** full `mix test --warnings-as-errors` + `mix credo --strict` + `bash scripts/ci/verify_processor_support_matrix.sh`.
- **Phase gate:** full suite green + drift gate green before `/gsd:verify-work`. Both are already merge-blocking CI jobs (release-gate, docs-contracts-shift-left).

### Wave 0 Gaps
- [ ] `accrue/test/accrue/entitlements/provider_honesty_test.exs` — NEW, covers ENT-08 (Fake-lane proof + capability-label mirror).
- [ ] `accrue/test/accrue/entitlements/past_due_grace_test.exs` (or fold into local_map_test) — NEW, covers the grace knob + `:unpaid`-no-grace + clock-driven window.
- [ ] `entitling?/1` 8-status pin — extend `subscription_predicates_test.exs` OR new `entitling_test.exs`.
- [ ] `Query.entitling/1` DB-fragment test + twin-invariant cross-check — extend/create the query test.
- [ ] Drift-gate extension is to an EXISTING script + doc (not a new file) — D-06.
- [ ] No new framework install needed; ExUnit + stream_data already present.

*Behavioral pin choice (D-14): table-driven struct-literal enumeration is recommended over `stream_data` for the 8-status truth table — the status set is small and finite, so exhaustive is stronger than sampled. Reserve `stream_data` for the grace-window math if a property ("for all past_due_since within N days → granted; beyond → denied") is desired.*

## Security Domain

> `security_enforcement` posture: this phase's security relevance is the **fail-closed entitlement contract** (a paid-feature gate). It does NOT touch auth, sessions, crypto, or webhooks.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Host-owned; entitlements is read-over-billing, not identity. |
| V3 Session Management | no | — |
| V4 Access Control | **yes** | Fail-closed authorization gate: `entitling?/1` + resolver collapse all error/edge/nil to deny (the only path to grant is an affirmative resolved match — entitlements.ex:62-77, PITFALLS #1). The paused fail-OPEN fix (D-11) is a V4 broken-access-control correction. Grace grants are affirmative, configured, resolved decisions — never fail-open (D-15). |
| V5 Input Validation | yes | `past_due_grace` union boot-validated by NimbleOptions (fail-loud at boot); `entitling?/1` has a catch-all `false` head (no input shape grants). |
| V6 Cryptography | no | — |
| V7 Error Handling/Logging | yes | Telemetry-only per-check decisions (never PII; `subject_id` is internal id only, entitlements.ex:216-226); additive grace reasons aid operator observability without leaking. |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Fail-open on paused-but-active subscription (D-11 gap) | Elevation of Privilege | `Query.entitling/1` `is_nil(pause_collection)` guard + pin test asserting ✗ |
| Predicate/fragment drift granting via the SQL path | Elevation of Privilege | Twin-invariant cross-check test (in-memory predicate == DB fragment per row) |
| Grace mis-applied to `:unpaid` (dunning-terminal) | Elevation of Privilege | Grace strictly keyed to `:past_due` (`dunning_sweepable?/1` precedent); `:unpaid` excluded by construction |
| Capability row implying provider divergence (over-promise) | Repudiation / honesty | Negative bash guard rejecting `native`/`unsupported`/`bounded` on entitlements rows |
| Clock-bypass making grace untestable / wall-clock-dependent | Tampering | `Accrue.Clock.utc_now/0` mandate (never `DateTime.utc_now/0` directly) |

## Sources

### Primary (HIGH confidence)
- Live codebase (read this session, line numbers verified): `accrue/lib/accrue/processor/capabilities.ex`, `processor/{fake,stripe,braintree}.ex`, `billing/subscription.ex`, `billing/query.ex`, `entitlements/resolver/local_map.ex`, `entitlements/resolver.ex`, `entitlements.ex`, `config.ex`, `jobs/dunning_sweeper.ex`, `clock.ex`, `lib/accrue/test/factory.ex`.
- `scripts/ci/verify_processor_support_matrix.sh`, `.planning/processor-support-matrix.md`, `.github/workflows/ci.yml` (jobs `docs-contracts-shift-left` @30-50, `release-gate` @84-115).
- Tests: `test/accrue/entitlements/local_map_test.exs`, `test/accrue/processor/capabilities_test.exs`, `test/accrue/billing/subscription_predicates_test.exs`.
- `accrue/guides/lifecycle_semantics.md` (State glossary @127-160 — the SSOT to extend).
- `.planning/phases/125-provider-honesty-lifecycle-truth/125-CONTEXT.md` (20 locked decisions, the authoritative spec).
- `.planning/REQUIREMENTS.md` (ENT-08/ENT-09), `.planning/STATE.md`, `.planning/research/PITFALLS.md` (Pitfalls #1 fail-open, #2 lifecycle-predicate reuse — directly back D-10/D-15).
- `accrue/mix.lock` (dependency versions: `nimble_options ~> 1.0`, `lattice_stripe 1.1.0`, `finch 0.21.0`).
- `CLAUDE.md` (project constraints — config-vs-runtime, telemetry mandate, SSOT-mirror discipline).

### Secondary (MEDIUM confidence)
- None required — every claim is grounded in first-party source read this session.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Canonical-ref verification: HIGH — every file + line number in CONTEXT.md `<canonical_refs>` opened and confirmed accurate; `entitling`/`past_due_grace`/`PastDueGrace`/`via_grace` confirmed net-new (zero existing refs).
- Standard stack: HIGH — no new deps; union-validation + clock + fragment patterns all have in-repo precedents.
- Architecture/patterns: HIGH — all four slices mirror existing, verified patterns (capabilities mirror, predicate/fragment twin, dunning grace math, fail-closed resolver harness).
- Pitfalls: HIGH — the paused fail-OPEN gap was independently confirmed by reading `Query.active/1` (status-only) against `paused?/1` (status OR pause_collection map); PITFALLS.md research corroborates.
- Open questions: LOW-impact only (capability-row count, resolved-field shape, Credo grace-clause routing) — all reversible, all with a clear recommended default.

**Research date:** 2026-05-23
**Valid until:** ~2026-06-22 (stable — internal codebase, no fast-moving external deps; re-verify line numbers only if Phases land between research and planning).
