# Phase 155: StripeFixtures Polish + Telemetry Counters - Context

**Gathered:** 2026-05-31
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship the two additive polish items deferred from Phase 154: make the livemode-absent Stripe entitlement-summary fixture path first-class for tests, and expose the already-emitted malformed/orphan entitlement-summary webhook events through the default `Telemetry.Metrics` recipe.

- **In scope:** `Accrue.Test.StripeFixtures.entitlement_summary_event/2` `:omit_livemode` option, StripeFixtures moduledoc/package-boundary wording, default metrics counters for `[:accrue, :webhooks, :malformed_entitlement_summary]` and `[:accrue, :webhooks, :orphan_entitlement_summary]`, focused tests proving the fixture option and metric definitions.
- **Out of scope:** Any new runtime API surface, telemetry namespace migration, new `Accrue.Telemetry.Ops` events, new database/schema changes, changes to entitlement gating behavior, changes to Phase 154 advisory-cache reducer semantics beyond replacing manual test setup with the fixture option.

</domain>

<decisions>
## Implementation Decisions

### Fixture option semantics (POL-03)
- **D-01:** Add `omit_livemode: true` as the first-class fixture option for `Accrue.Test.StripeFixtures.entitlement_summary_event/2`. When true, the summary object must omit the `"livemode"` key entirely.
- **D-02:** Keep `livemode: false` as the default and preserve existing `livemode: true | false` behavior. `omit_livemode: true` wins if a caller passes both `omit_livemode: true` and `livemode: ...`; document this precedence in the fixture docs.
- **D-03:** Do not use `livemode: :omit`. The sentinel overload makes a normally boolean option type-surprising and creates a footgun where the atom could leak into payload construction if future edits miss the guard.
- **D-04:** Do not leave tests to hand-delete `"livemode"` from nested payloads. Manual `Map.delete` setup is easy to put at the wrong path, duplicates fixture internals in tests, and fails the phase goal of giving test authors a direct fixture option.

### StripeFixtures moduledoc positioning (POL-03)
- **D-05:** Update `Accrue.Test.StripeFixtures` `@moduledoc` to say the module is test support under `test/support`, not a published Hex API, and not part of Accrue's runtime/public support contract.
- **D-06:** Keep adopter guidance narrow: adopters who want similar fixtures should copy the needed fixture shape into their own test support or temporarily inspect/use the repo via a path/git checkout while iterating. Do not imply a stable importable fixture API from the published package.

### Telemetry Metrics defaults (POL-04)
- **D-07:** Add exact default metrics matching the already-emitted webhook tuples:
  - `counter("accrue.webhooks.malformed_entitlement_summary.count", tags: [:reason])`
  - `counter("accrue.webhooks.orphan_entitlement_summary.count")`
- **D-08:** Keep these under the existing `accrue.webhooks.*` metric namespace. Do not move or bridge them into `Accrue.Telemetry.Ops`; that would be a broader compatibility-managed telemetry migration and conflicts with the roadmap wording for Phase 155.
- **D-09:** `:reason` is acceptable as a metric tag for malformed summaries because current reasons are bounded atoms from internal validation. Do not add high-cardinality tags such as customer ID, event ID, or raw payload fields.
- **D-10:** Do not update `Accrue.TestSupport.TelemetryOpsInventory` for these two events. That inventory is explicitly `:ops` namespace parity; widening it with non-ops webhooks events would blur the contract. If broader non-ops parity is wanted later, add a separate inventory/gate.

### Verification placement
- **D-11:** Replace the existing manual `Map.delete` setup in `default_handler_entitlement_summary_test.exs` with `StripeFixtures.entitlement_summary_event(omit_livemode: true, ...)` so the reducer test proves the new fixture option while continuing to prove POL-02 carry-forward.
- **D-12:** Add focused assertions in `metrics_test.exs` that `Accrue.Telemetry.Metrics.defaults/0` includes metrics whose `event_name` equals `[:accrue, :webhooks, :malformed_entitlement_summary]` and `[:accrue, :webhooks, :orphan_entitlement_summary]`. Prefer named/event tuple presence over brittle list length or order assertions.
- **D-13:** Keep verification proportional: no new test module is required unless the planner finds the existing test structure awkward. Existing behavior-centered `describe` blocks are the preferred home.

### Folded Todos
- **ENT-10 advisory-cache code-review follow-ups (WR-05 + INFO)** — Filed 2026-05-24 from Phase 127 code review, `resolves_phase: 154`, but the Phase 154 context explicitly deferred IN-03 and IN-04 here. Folded into Phase 155 for StripeFixtures moduledoc/fixture-option polish and missing default metrics counters. Source file references: `accrue/test/support/stripe_fixtures.ex:3`, `accrue/lib/accrue/telemetry/metrics.ex:88`, `accrue/lib/accrue/webhook/default_handler.ex:570`, `accrue/lib/accrue/webhook/default_handler.ex:786`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap
- `.planning/ROADMAP.md` §"Phase 155: StripeFixtures Polish + Telemetry Counters" — phase goal and three success criteria.
- `.planning/REQUIREMENTS.md` §"Advisory Cache Polish (IN-01..04)" — POL-03 and POL-04 are the locked requirements for this phase.
- `.planning/STATE.md` §"v1.47 Phase Summary" and §"Key Planning Decisions for v1.47" — confirms Phase 155 is additive polish after Phase 154.

### Prior phase context
- `.planning/phases/154-advisory-cache-core-correctness/154-CONTEXT.md` — Phase 154 decisions and explicit deferral of IN-03/IN-04 to Phase 155. MUST read to avoid reopening reducer semantics already decided.
- `.planning/phases/154-advisory-cache-core-correctness/154-01-PLAN.md` — verification details for the current advisory-cache reducer path and telemetry branch, useful context for where the Phase 155 test should plug in.

### Research and prompt corpus
- `.planning/research/SUMMARY.md` — v1.47 summary naming exact Phase 155 file targets and recommended counters.
- `.planning/research/PITFALLS.md` §"Pitfall IN-03-01" and §"Pitfall IN-04-01" — precise fixture and telemetry footguns this phase closes.
- `.planning/research/STACK.md` §"Telemetry.Metrics defaults" — identifies the two missing webhook events and recommended counter names.
- `prompts/MILESTONE-NEXT-STEP-ASSESSMENT.md` — recurring maintainer preference for subagent-backed research, idiomatic Elixir/Phoenix lens, least-surprise DX, and adopter/operator proof posture.

### Source files
- `accrue/test/support/stripe_fixtures.ex` — `Accrue.Test.StripeFixtures` moduledoc and `entitlement_summary_event/2` implementation/doc block.
- `accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs` — existing POL-02 test manually deletes `"livemode"`; update it to consume `omit_livemode: true`.
- `accrue/lib/accrue/telemetry/metrics.ex` — `Accrue.Telemetry.Metrics.defaults/0`, where the two counters belong.
- `accrue/lib/accrue/webhook/default_handler.ex` — existing emits for `[:accrue, :webhooks, :orphan_entitlement_summary]`, `[:accrue, :webhooks, :malformed_entitlement_summary]`, and `[:accrue, :entitlements, :summary_synced]`.
- `accrue/test/accrue/telemetry/metrics_test.exs` — add named/event tuple presence assertions for the new default metrics.
- `accrue/test/support/telemetry_ops_inventory.ex` and `accrue/test/accrue/telemetry/metrics_ops_parity_test.exs` — read only to confirm these should remain ops-only and unchanged.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `entitlement_summary_event/2` already builds a central `summary_object` map before wrapping it in `webhook_event/3`; adding an `omit_livemode` branch there keeps absence semantics in one fixture helper instead of duplicating nested `Map.delete` calls.
- `maybe_put/3` already exists in `stripe_fixtures.ex` for optional envelope fields. The planner can either use a similarly small helper or an explicit `if omit_livemode, do: Map.delete(summary_object, "livemode"), else: summary_object`.
- `metrics_test.exs` already has `has_metric?/1` and `metric_name_to_string/1`; extend with event-name assertions if needed, rather than testing list length/order.

### Established Patterns
- Accrue's default metrics recipe uses dot-separated metric names that map directly to telemetry event tuples. Follow that convention exactly for `accrue.webhooks.malformed_entitlement_summary.count` and `accrue.webhooks.orphan_entitlement_summary.count`.
- Metric tags stay low-cardinality. Existing moduledoc explicitly forbids customer IDs, subscription IDs, and unbounded identifiers as tags.
- `TelemetryOpsInventory` is a parity gate for `[:accrue, :ops, ...]` events only. Non-ops webhook metrics belong in `metrics_test.exs`, not the ops inventory.

### Integration Points
- `default_handler.ex` emits orphan summary telemetry directly when no customer row exists; no emit-path change is needed for Phase 155.
- `emit_summary_malformed/2` emits malformed summary telemetry with `reason`; the default metric should tag only `:reason`.
- The POL-02 carry-forward behavior is already implemented in Phase 154. Phase 155 should only improve test ergonomics and default metric exposure.

</code_context>

<specifics>
## Specific Ideas

- Advisor research compared `omit_livemode: true`, `livemode: :omit`, and manual test mutation; the cohesive recommendation is `omit_livemode: true` because it is explicit, backward-compatible, and idiomatic for keyword fixture options.
- Advisor research compared exact webhook metrics, ops-namespace migration, and documented omission; the cohesive recommendation is exact webhook metrics because it satisfies POL-04 with minimal churn and preserves current namespace semantics.
- Advisor research recommends no new broad docs unless the planner sees a nearby telemetry guide section that already lists default metrics. The phase success criteria are satisfied by code docs and tests.
- If both `omit_livemode: true` and `livemode: false/true` are passed, treat omission as intentional and let it win. This prevents ambiguous tests from silently exercising the wrong branch.

</specifics>

<deferred>
## Deferred Ideas

- A general non-ops telemetry parity inventory for all emitted `[:accrue, ...]` events could be useful later, but it is out of scope for Phase 155. Do not overload the existing ops inventory to get that coverage.
- A broader telemetry namespace migration that bridges malformed/orphan entitlement summaries into `Accrue.Telemetry.Ops` may be reasonable only as a future compatibility-managed observability phase. It is not polish.

</deferred>

---

*Phase: 155-StripeFixtures-Polish-Telemetry-Counters*
*Context gathered: 2026-05-31*
