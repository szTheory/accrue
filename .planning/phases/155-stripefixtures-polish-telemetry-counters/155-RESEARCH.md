# Phase 155: StripeFixtures Polish + Telemetry Counters - Research

**Researched:** 2026-05-31
**Domain:** Elixir test fixtures and Telemetry.Metrics defaults for webhook observability
**Confidence:** HIGH

## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Add `omit_livemode: true` as the first-class fixture option for `Accrue.Test.StripeFixtures.entitlement_summary_event/2`. When true, the summary object must omit the `"livemode"` key entirely.
- **D-02:** Keep `livemode: false` as the default and preserve existing `livemode: true | false` behavior. `omit_livemode: true` wins if a caller passes both `omit_livemode: true` and `livemode: ...`; document this precedence in the fixture docs.
- **D-03:** Do not use `livemode: :omit`. The sentinel overload makes a normally boolean option type-surprising and creates a footgun where the atom could leak into payload construction if future edits miss the guard.
- **D-04:** Do not leave tests to hand-delete `"livemode"` from nested payloads. Manual `Map.delete` setup is easy to put at the wrong path, duplicates fixture internals in tests, and fails the phase goal of giving test authors a direct fixture option.
- **D-05:** Update `Accrue.Test.StripeFixtures` `@moduledoc` to say the module is test support under `test/support`, not a published Hex API, and not part of Accrue's runtime/public support contract.
- **D-06:** Keep adopter guidance narrow: adopters who want similar fixtures should copy the needed fixture shape into their own test support or temporarily inspect/use the repo via a path/git checkout while iterating. Do not imply a stable importable fixture API from the published package.
- **D-07:** Add exact default metrics matching the already-emitted webhook tuples:
  - `counter("accrue.webhooks.malformed_entitlement_summary.count", tags: [:reason])`
  - `counter("accrue.webhooks.orphan_entitlement_summary.count")`
- **D-08:** Keep these under the existing `accrue.webhooks.*` metric namespace. Do not move or bridge them into `Accrue.Telemetry.Ops`; that would be a broader compatibility-managed telemetry migration and conflicts with the roadmap wording for Phase 155.
- **D-09:** `:reason` is acceptable as a metric tag for malformed summaries because current reasons are bounded atoms from internal validation. Do not add high-cardinality tags such as customer ID, event ID, or raw payload fields.
- **D-10:** Do not update `Accrue.TestSupport.TelemetryOpsInventory` for these two events. That inventory is explicitly `:ops` namespace parity; widening it with non-ops webhooks events would blur the contract. If broader non-ops parity is wanted later, add a separate inventory/gate.
- **D-11:** Replace the existing manual `Map.delete` setup in `default_handler_entitlement_summary_test.exs` with `StripeFixtures.entitlement_summary_event(omit_livemode: true, ...)` so the reducer test proves the new fixture option while continuing to prove POL-02 carry-forward.
- **D-12:** Add focused assertions in `metrics_test.exs` that `Accrue.Telemetry.Metrics.defaults/0` includes metrics whose `event_name` equals `[:accrue, :webhooks, :malformed_entitlement_summary]` and `[:accrue, :webhooks, :orphan_entitlement_summary]`. Prefer named/event tuple presence over brittle list length or order assertions.
- **D-13:** Keep verification proportional: no new test module is required unless the planner finds the existing test structure awkward. Existing behavior-centered `describe` blocks are the preferred home.

### the agent's Discretion
- No separate `the agent's Discretion` block was present in `155-CONTEXT.md`; treat all implementation choices above as locked for planning. [VERIFIED: codebase grep]

### Deferred Ideas (OUT OF SCOPE)
- A general non-ops telemetry parity inventory for all emitted `[:accrue, ...]` events could be useful later, but it is out of scope for Phase 155. Do not overload the existing ops inventory to get that coverage.
- A broader telemetry namespace migration that bridges malformed/orphan entitlement summaries into `Accrue.Telemetry.Ops` may be reasonable only as a future compatibility-managed observability phase. It is not polish.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| POL-03 | Developer can write a test exercising livemode-absent path via fixture `:omit_livemode`; `StripeFixtures` moduledoc clarifies test-only | Add `omit_livemode` branch in `entitlement_summary_event/2`, update moduledoc in test fixture module, and swap manual payload mutation test setup for fixture option. [VERIFIED: codebase grep] |
| POL-04 | `Accrue.Telemetry.Metrics.defaults/0` includes malformed/orphan entitlement summary counters | Add two counters in `defaults/0` and assert by `event_name` tuple presence in `metrics_test.exs`. [VERIFIED: codebase grep] |

## Summary

Phase 155 is additive polish over Phase 154: no schema migration, no runtime API expansion, and no telemetry namespace migration are required. [VERIFIED: codebase grep]  
The code already emits `[:accrue, :webhooks, :malformed_entitlement_summary]` and `[:accrue, :webhooks, :orphan_entitlement_summary]`, but `Accrue.Telemetry.Metrics.defaults/0` does not currently expose matching default counters. [VERIFIED: codebase grep]

`StripeFixtures.entitlement_summary_event/2` currently always includes `"livemode"` and does not yet support an omission option; existing tests still hand-edit nested payload maps to simulate missing livemode. [VERIFIED: codebase grep]  
Primary recommendation: implement `omit_livemode: true` directly in fixture construction, wire the two missing webhook counters in `defaults/0`, and verify via existing test modules using tuple-presence assertions. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Build livemode-absent entitlement summary fixture | Test support module (`test/support`) | Webhook reducer tests | Fixture shape ownership is in test helpers, consumed by reducer tests. [VERIFIED: codebase grep] |
| Expose malformed/orphan counters in defaults | API/Backend telemetry module | Operator metrics reporter integration | `Accrue.Telemetry.Metrics.defaults/0` defines backend-emitted telemetry metric recipes. [VERIFIED: codebase grep] |
| Clarify fixture publication boundary | Documentation (test module docs) | Hex package expectations | `@moduledoc` drives intended support contract visibility. [CITED: https://elixir.hexdocs.pm/writing-documentation.html] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `telemetry_metrics` | `1.1.0` (released 2025-01-24) | Define counter/summary metric specs from telemetry events | Existing optional dep and current defaults implementation target this API. [VERIFIED: npm registry] |
| `telemetry` | `1.4.2` (released 2026-05-11) | Event emission (`:telemetry.execute`) for webhook outcomes | Existing webhook code already emits the target events. [VERIFIED: npm registry] |
| `ex_unit` (built-in) | bundled with Elixir | Test verification for fixture and metrics behavior | Existing tests are ExUnit modules and should be extended in place. [VERIFIED: codebase grep] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Telemetry.Metrics` | v1.1 API docs | Supports `counter/2`, inferred or explicit `:event_name`, `:tags` | Use for low-cardinality default counters only. [CITED: https://telemetry-metrics.hexdocs.pm/Telemetry.Metrics.html] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `omit_livemode: true` | `livemode: :omit` sentinel | Type-surprising option and easier misuse; rejected by locked decision D-03. [VERIFIED: codebase grep] |
| Webhook namespace counters in defaults | Add to ops parity inventory | Breaks existing ops-only inventory contract and exceeds phase scope. [VERIFIED: codebase grep] |

**Installation:**
```bash
# No new packages required for Phase 155.
```

**Version verification:**
```bash
cd accrue && mix hex.info telemetry_metrics
cd accrue && mix hex.info telemetry
```

## Architecture Patterns

### System Architecture Diagram
```text
Stripe fixture builder (test/support/stripe_fixtures.ex)
  -> entitlement_summary_event(opts)
    -> summary_object map (optional omit "livemode")
      -> webhook event payload
        -> DefaultHandler entitlement-summary tests

Webhook handler runtime emits events
  -> [:accrue, :webhooks, :malformed_entitlement_summary] (metadata: reason)
  -> [:accrue, :webhooks, :orphan_entitlement_summary]
    -> Accrue.Telemetry.Metrics.defaults/0 defines counters
      -> Host telemetry reporter consumes defaults list
```

### Recommended Project Structure
```text
accrue/
├── test/support/stripe_fixtures.ex                  # fixture construction + moduledoc contract
├── lib/accrue/telemetry/metrics.ex                  # default Telemetry.Metrics recipe
├── test/accrue/webhook/default_handler_entitlement_summary_test.exs  # livemode-absent path test
└── test/accrue/telemetry/metrics_test.exs           # default metrics presence assertions
```

### Pattern 1: Option-Driven Fixture Shape
**What:** Build omission behavior into fixture helper instead of downstream test mutation. [VERIFIED: codebase grep]  
**When to use:** Whenever a reducer/path depends on key absence vs key value. [VERIFIED: codebase grep]  
**Example:**
```elixir
# Source: codebase pattern + phase locked decisions
summary_object =
  %{
    "object" => "entitlements.active_entitlement_summary",
    "customer" => customer,
    "livemode" => livemode,
    "entitlements" => %{"object" => "list", "data" => data, "has_more" => has_more, "url" => url}
  }

summary_object =
  if omit_livemode, do: Map.delete(summary_object, "livemode"), else: summary_object
```

### Pattern 2: Metrics Assertions by Event Tuple
**What:** Assert `event_name` tuple existence for stability across list order changes. [VERIFIED: codebase grep]  
**When to use:** `defaults/0` tests where output list may grow over time. [VERIFIED: codebase grep]  
**Example:**
```elixir
# Source: Telemetry.Metrics event_name semantics + existing test style
assert Enum.any?(M.defaults(), &(&1.event_name == [:accrue, :webhooks, :orphan_entitlement_summary]))
```

### Anti-Patterns to Avoid
- **Manual nested `Map.delete` in tests:** duplicates fixture internals and weakens reuse/readability. [VERIFIED: codebase grep]
- **High-cardinality metric tags (`customer_id`, `event_id`):** cardinality explosion risk; keep `:reason` only for malformed. [CITED: https://telemetry-metrics.hexdocs.pm/Telemetry.Metrics.html]
- **Updating ops-only parity inventory for non-ops events:** violates current inventory contract. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Telemetry metric structs | Custom struct detection/parsing | `Telemetry.Metrics.counter/2` + `event_name` assertions | Standard API already models event mapping and tags. [CITED: https://telemetry-metrics.hexdocs.pm/Telemetry.Metrics.html] |
| Livemode-absent payload setup | Ad hoc per-test map surgery | Fixture option `omit_livemode: true` | Single source of payload truth and clearer intent. [VERIFIED: codebase grep] |

**Key insight:** This phase should modify existing helper and metrics defaults, not introduce parallel abstractions. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Presence vs. value confusion for `livemode`
**What goes wrong:** Tests set `livemode: nil` or mutate wrong path instead of omitting key. [VERIFIED: codebase grep]  
**Why it happens:** Fixture currently always includes `"livemode"`; omission is not first-class. [VERIFIED: codebase grep]  
**How to avoid:** Implement and document `omit_livemode: true` precedence over `livemode:`. [VERIFIED: codebase grep]  
**Warning signs:** Tests still call nested `Map.delete` after fixture call. [VERIFIED: codebase grep]

### Pitfall 2: Metrics list assertions coupled to count/order
**What goes wrong:** Tests fail on additive metrics unrelated to behavior. [VERIFIED: codebase grep]  
**Why it happens:** Existing test includes minimum-length assertion pattern. [VERIFIED: codebase grep]  
**How to avoid:** Assert tuple presence for required events. [VERIFIED: codebase grep]  
**Warning signs:** Failures caused by list growth, not missing required counters. [ASSUMED]

## Code Examples

### Add missing webhook defaults
```elixir
# Source: default metrics recipe in codebase + Telemetry.Metrics docs
counter("accrue.webhooks.malformed_entitlement_summary.count", tags: [:reason]),
counter("accrue.webhooks.orphan_entitlement_summary.count"),
```

### Hide internal/test-only module from generated docs
```elixir
# Source: Elixir Writing Documentation
@moduledoc false
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual payload mutation in test body | Fixture option controls key omission | Planned in Phase 155 | Less brittle tests and clearer intent. [VERIFIED: codebase grep] |
| Emitted webhook telemetry not in defaults | Include explicit default counters for malformed/orphan | Planned in Phase 155 | Operators can wire both signals without custom per-app metric definitions. [VERIFIED: codebase grep] |

**Deprecated/outdated:**
- `livemode: :omit` sentinel proposal: rejected by locked decision D-03. [VERIFIED: codebase grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Count/order-coupled test failures are likely as defaults grow | Common Pitfalls | Low; tests can still be updated to tuple-presence checks |

## Open Questions

1. **Should `StripeFixtures` moduledoc use `@moduledoc false` or explicit warning text?**
   - What we know: Elixir supports hidden modules via `@moduledoc false`. [CITED: https://elixir.hexdocs.pm/writing-documentation.html]
   - What's unclear: project preference between hidden docs vs visible warning prose in test support.
   - Recommendation: follow locked D-05 text requirement; keep module visible but explicit test-only/non-Hex-contract wording unless maintainers prefer full hide.

## Environment Availability

Step 2.6: SKIPPED (no new external runtime/tool dependencies identified for this phase). [VERIFIED: codebase grep]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Mix test) [VERIFIED: codebase grep] |
| Config file | `accrue/test/test_helper.exs` [VERIFIED: codebase grep] |
| Quick run command | `cd accrue && mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs test/accrue/telemetry/metrics_test.exs` [ASSUMED] |
| Full suite command | `cd accrue && mix test.all` [VERIFIED: codebase grep] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| POL-03 | Fixture can omit `livemode` key and reducer path remains covered | unit/integration | `cd accrue && mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs` | ✅ |
| POL-04 | defaults includes malformed/orphan entitlement summary events | unit | `cd accrue && mix test test/accrue/telemetry/metrics_test.exs` | ✅ |

### Sampling Rate
- **Per task commit:** `cd accrue && mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs test/accrue/telemetry/metrics_test.exs`
- **Per wave merge:** `cd accrue && mix test.all`
- **Phase gate:** Full suite green before `$gsd-verify-work`

### Wave 0 Gaps
- None — existing test infrastructure and target files already exist. [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | N/A — phase modifies fixtures and metrics registration only. [VERIFIED: codebase grep] |
| V3 Session Management | no | N/A — no session logic touched. [VERIFIED: codebase grep] |
| V4 Access Control | no | N/A — no authorization path changes. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Keep malformed event reasons bounded and low-cardinality in metrics tags (`:reason`). [VERIFIED: codebase grep] |
| V6 Cryptography | no | N/A — no cryptographic behavior touched. [VERIFIED: codebase grep] |

### Known Threat Patterns for Elixir Telemetry + Webhook Fixtures

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| High-cardinality telemetry tags causing monitoring DoS/cost blowups | Denial of service | Restrict tags to bounded enums (here `:reason` only). [CITED: https://telemetry-metrics.hexdocs.pm/Telemetry.Metrics.html] |
| Test-only helper misconstrued as public contract | Tampering | Explicit moduledoc contract warning (`test/support`, not published API). [VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)
- Repository source files (inspected directly):  
  - `accrue/test/support/stripe_fixtures.ex`  
  - `accrue/lib/accrue/telemetry/metrics.ex`  
  - `accrue/lib/accrue/webhook/default_handler.ex`  
  - `accrue/test/accrue/telemetry/metrics_test.exs`  
  - `accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs`  
  - `accrue/test/support/telemetry_ops_inventory.ex`  
  - `accrue/test/accrue/telemetry/metrics_ops_parity_test.exs`
- Hex package info via `mix hex.info`:  
  - `telemetry_metrics` (1.1.0; 2025-01-24)  
  - `telemetry` (1.4.2; 2026-05-11)

### Secondary (MEDIUM confidence)
- Telemetry.Metrics official docs: https://telemetry-metrics.hexdocs.pm/Telemetry.Metrics.html
- Elixir writing docs guide: https://elixir.hexdocs.pm/writing-documentation.html
- telemetry_metrics package page: https://hex.pm/packages/telemetry_metrics

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - verified in codebase lock + Hex release metadata.
- Architecture: HIGH - all affected codepaths and tests exist and were inspected directly.
- Pitfalls: HIGH - directly tied to currently-observed code/test patterns; one low-risk assumption explicitly logged.

**Research date:** 2026-05-31  
**Valid until:** 2026-06-30

