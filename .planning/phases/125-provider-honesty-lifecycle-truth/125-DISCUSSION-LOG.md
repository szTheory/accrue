# Phase 125: Provider Honesty + Lifecycle Truth - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-23
**Phase:** 125-provider-honesty-lifecycle-truth
**Areas discussed:** Provider-honesty capability surface (ENT-08), Drift gate + matrix home (ENT-08), Lifecycle-truth predicate SSOT (ENT-09), Past-due grace knob (ENT-09)
**Mode:** cohesive-synthesis (4 parallel `gsd-advisor-researcher` agents; `discuss_auto_all_gray_areas` + `discuss_high_impact_confirm` + `discuss_auto_resolve_low_impact`). **Zero open forks** — no decision crossed the confirm bar, so no `AskUserQuestion` was surfaced.

---

## Provider-honesty capability surface (ENT-08)

| Option | Description | Selected |
|--------|-------------|----------|
| No `Resolver.capabilities/0`; honesty in `Processor.Capabilities` rows + adapters | Single `local_mapping` capability, identical across all 3 providers; declines the irreversible behaviour-callback | ✓ |
| Add `capabilities/0` to the `Resolver` behaviour (`%{source: :local}`) | Self-describing resolver seam; re-litigates D-12, invents a 2nd vocabulary with no 125 consumer | |
| Multiple per-gate-function rows (feature/quota/membership) | Granular but over-decomposes — all four are the same local fold | |
| Add a `native` row now (Stripe deferred/out-of-slice) | Pre-stages Phase 127; over-promises a deferred path | |

**Choice:** No resolver callback; one `local_mapping` row in `Processor.Capabilities` (per Phase 123 D-15) + `entitlements: %{local_mapping: true}` in each adapter; `local-identical` lane label; Fake-lane parametrized proof test.
**Notes:** Honesty is a *provider* claim, not a resolver claim — resolution is provider-INDEPENDENT local derivation (zero processor calls), so identity is structural. Stripe-native deferred to 127.

---

## Drift gate + matrix home (ENT-08)

| Option | Description | Selected |
|--------|-------------|----------|
| Extend `verify_processor_support_matrix.sh` + `.planning/processor-support-matrix.md` | One code module → one doc → one gate; most faithful SCM-06/PROC-24 mirror | ✓ |
| New dedicated `verify_entitlements_support_matrix.sh` + new `.planning/entitlements-support-matrix.md` | Cleaner layer-separation, but split-brain SSOT vs shared code labels + 2nd artifact for Phase 126 | |
| Put the matrix in the public `accrue/guides/entitlements.md` | Front-runs Phase 126 (ENT-12); trips `verify_package_docs.sh` prematurely | |

**Choice:** Extend the existing processor matrix doc + gate; planning-level SSOT only (not the public guide); negative stale-row guard against per-provider divergence labels; rides existing `docs-contracts-shift-left` + `release-gate` CI.
**Notes:** D-15 LOCKED the code labels into `Processor.Capabilities`, so the doc/gate mirror the same module. Dedicated-file alternative kept as a deferred revisit if the section bloats the script.

---

## Lifecycle-truth predicate SSOT (ENT-09)

| Option | Description | Selected |
|--------|-------------|----------|
| Billing-layer `Subscription.entitling?/1` + `Query.entitling/1`, grace overlay in entitlements layer | D-14-clean; SSOT next to sibling predicates; keeps predicate⇔fragment invariant; closes the paused gap | ✓ |
| Keep the filter inline in `LocalMap` only | Localizes the fix but re-derives truth outside `Subscription` (Pitfall #2); future resolvers drift | |
| Put the whole predicate (incl. grace) in entitlements | Grace is config-coupled (OK there) but the pure lifecycle truth belongs in billing | |

**Choice:** `entitling?/1` = `active?(s) and not paused?(s) and not canceled?(s)` + mirrored `Query.entitling/1` (adds `is_nil(pause_collection)`); `LocalMap.fold_active/1` retargets to it; truth table in `lifecycle_semantics.md` + a table-driven pin test over all 8 statuses.
**Notes:** Closes a real fail-OPEN gap — a `status: :active` + `pause_collection` row currently grants entitlement despite being paused. This is a security correction, not new policy (ENT-09 + `paused?/1` already say paused ✗).

---

## Past-due grace knob (ENT-09)

| Option | Description | Selected |
|--------|-------------|----------|
| Strict fail-closed default (`past_due_grace: :none`), grace opt-in | Preserves shipped `active?/1` behavior + headline fail-closed contract; convention is deny-by-default-with-opt-in | ✓ |
| Honor-dunning-grace by default (`:dunning`) | Best revenue/UX out of the box, but the only variant that materially changes who-gets-access → fork direction | |

**Choice:** Default `:none`; one config key `past_due_grace: {:or, [{:in, [:dunning, :none]}, :pos_integer]}`; pure `PastDueGrace.within_grace?/2` (Clock-driven) OR-ed onto the lifecycle predicate in the entitlements layer; widen the fold query only when enabled; add `:past_due_grace` / `:past_due_expired` telemetry reasons; `:unpaid` excluded from grace (terminal).
**Notes:** Auto-resolved, NOT escalated — `:none` preserves current behavior and the fail-closed contract; a grace grant (when enabled) is an affirmative configured decision, not a fail-open. Stripe/Cashier/Pay all default to "app decides / not valid" for past_due.

## Claude's Discretion

All four areas auto-resolved via parallel advisor research per the standing cohesive-synthesis preference and the `discuss_high_impact_confirm_bar`. The closest product-flavored candidate (the past-due grace default) auto-resolved to `:none` because choosing `:dunning` would be the fork direction. Cosmetic/internal calls (the `local-identical` lane label; extend-existing-matrix vs dedicated-file; the two new telemetry reason atoms) were made at Claude's discretion as additive/reversible.

## Deferred Ideas

- `Resolver.capabilities/0` callback / per-resolver source seam — declined; reconsider in Phase 127.
- `native` entitlements row + Stripe-native sync + `grant`/`revoke` + ledger writes (ENT-10) → Phase 127.
- Read-only admin view + public `guides/entitlements.md` + JTBD ⛔→✅ flip + First Hour/README spine (ENT-11/12) → Phase 126.
- Dedicated `verify_entitlements_support_matrix.sh` + `.planning/entitlements-support-matrix.md` — alternative to D-06; revisit only if the processor script bloats.
- Atomic seat enforcement / membership management — host-owned recipe, never a core API.
- `fetch_entitled/2` diagnostic API — additive-only on a sourced host need.
</content>
