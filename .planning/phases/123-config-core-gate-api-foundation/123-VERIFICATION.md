---
phase: 123-config-core-gate-api-foundation
verified: 2026-05-23T01:15:00Z
status: passed
score: 5/5 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: none
  note: "Initial verification (no prior VERIFICATION.md). A standard code review (123-REVIEW.md) ran earlier; its BLOCKER + 3 warnings were fixed before this verification."
---

# Phase 123: Config + Core Gate API Foundation Verification Report

**Phase Goal:** A Phoenix developer can declare a plan→feature/quota map and gate code on what a customer has paid for, resolved entirely from local subscription state with a fail-closed contract — the headline JTBD, with no new tables and no Stripe dependency.
**Verified:** 2026-05-23T01:15:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

The phase goal is achieved. A host declares a `NimbleOptions`-validated `:entitlements` catalog (config.ex), the four fail-closed gate functions (`entitled?`, `has_active_plan?`, `features_for`, `entitlement_quantity`) resolve entirely from local subscription state with zero processor calls, and the public surface is wired onto the top-level `Accrue` module via `defdelegate`. No new tables (the `%Plan{}` struct is a pure value type, not Ecto), no Stripe dependency on the read path. Verified by reading every source file, manually tracing all key links, running the full phase test suite (52 tests + 2 properties, 0 failures), and a runtime behavioral spot-check of the fail-closed contract.

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
| - | ----- | ------ | -------- |
| 1 | Host declares a `NimbleOptions`-validated plan/price→feature (+seat/quota) map; invalid/unmapped config fails loudly at boot, never silently allows | ✓ VERIFIED | `config.ex:356-401` `:entitlements` schema key (plans/resolver/unmapped_action, nested keys typed); `entitlements/0` accessor `config.ex:850`; cross-plan `price_id`-collision guard `validate_entitlements_price_ids!/1` (config.ex:873-903) raises `Accrue.ConfigError` naming both plans + price_id; wired into `maybe_validate_boot_setup!/1` (config.ex:863) → `validate_at_boot!/0` (config.ex:485) → called from `Accrue.Application.start/2` (application.ex:62). Default `unmapped_action: :deny` fails closed. `config_entitlements_test.exs` GREEN. |
| 2 | `has_active_plan?` is a boolean from `Subscription.active?/1` lifecycle truth (never raw `.status`); `entitled?`/`features_for` resolve from local state with zero processor API calls | ✓ VERIFIED | LocalMap uses `Query.active/1` (`status in [:active,:trialing]` + `is_nil(ended_at)`), never raw `s.status` (grep: 0 matches for `s.status`/`Accrue.Processor`/`Billing.customer\b` in local_map.ex). Read-only `accrue_customers` lookup cloned, not the effectful get-or-create path (local_map.ex:48-62). Test SQL log confirms `SELECT ... WHERE status IN ('active','trialing') AND ended_at IS NULL` actually executes. `local_map_test.exs` + `entitlements_test.exs` GREEN. |
| 3 | Fail-closed contract holds under property tests: only path to true is an affirmative resolved match; errors/`nil`/unmapped/exceptions → false | ✓ VERIFIED | `entitlements_fail_closed_property_test.exs`: never-true-on-garbage property (200 runs, nil/term/integer/string/atom), explicit no-customer/canceled-only/unmapped legs, raising-resolver stub (D-08), CR-01 non-stringable-`:id` regression (line 141-145), true-iff-affirmative-match property. `entitlements.ex:143-153` `resolve/2` wraps dispatch in `try/rescue/catch`; `subject_id/1` total via `inspect/1` fallback (entitlements.ex:204-208). Runtime spot-check: `%{id: {1,2}}`/`%{id: %{}}`/`%{id: [:a,:b]}`/`%{id: self()}`/nil/42/"garbage"/:atom all → false/[]/0, none raised. 2 properties GREEN. |
| 4 | `entitlement_quantity/2` returns read-only entitled seat/quantity from local subscription quantity; atomic seat enforcement documented host-owned (not a core API) | ✓ VERIFIED | `entitlement_quantity/2` defined (entitlements.ex:120) + delegated (accrue.ex:62); read-only `Map.fetch` on resolved quantities, fail-closed `0`; quantities merged `min(cap,qty)` per quota_key (local_map.ex:97-121, WR-01 max-merge fix). Host-owned atomic seat enforcement documented in REQUIREMENTS.md ENT-04 (line 21) + Out of Scope (line 58). |
| 5 | Entitlement checks emit `[:accrue, :entitlements, :check]` telemetry/OTel spans; per-check decisions NOT written to the immutable event ledger | ✓ VERIFIED | `entitlements.ex:223` `Accrue.Telemetry.span([:accrue, :entitlements, :check], metadata, fun)` (plural literal). OTel `@allowed_attributes` extended with 6 D-19 keys (atom + string forms, otel.ex:20-40). Ledger boundary: 0 `Events.record`/`record_multi` in entitlements.ex; `entitlements_test.exs:271-289` counts `accrue_events` before/after a batch of checks, asserts unchanged. Telemetry test attaches to plural `:start`/`:stop`, asserts D-18 metadata + PII absence. `otel_test.exs` GREEN. |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `accrue/lib/accrue/config.ex` | `:entitlements` schema + `entitlements/0` + boot collision guard | ✓ VERIFIED | gsd-sdk artifacts pass; schema L356-401, accessor L850, guard L873-903 wired into boot path L863/485/app:62. |
| `accrue/lib/accrue/entitlements.ex` | 4 fail-closed gate fns + inline span + fail-closed wrapper | ✓ VERIFIED | All 4 fns + `Telemetry.span([:accrue, :entitlements, :check]`, `try/rescue/catch`, `MapSet.member?`, `MapSet.to_list`; 0 `Events.record`/`fetch_entitled`. |
| `accrue/lib/accrue/entitlements/resolver.ex` | `@callback resolve/2` (+ active_plans SET) + `__impl__/0` | ✓ VERIFIED | `@callback resolve` L53, `__impl__` L58 reads `Application.get_env(:accrue, :entitlements)`; 0 `capabilities`. |
| `accrue/lib/accrue/entitlements/resolver/local_map.ex` | default resolver, read-only, zero processor calls | ✓ VERIFIED | `@behaviour` + `resolve/2`; `Query.active` reuse; 0 processor/`Billing.customer\b`/`s.status`; WR-01 + WR-04 fixes present. |
| `accrue/lib/accrue/entitlements/plan.ex` | `%Plan{}` value struct, no Ecto | ✓ VERIFIED | `defstruct plan_id/features(MapSet)/quantities`; no `use Ecto.Schema`. |
| `accrue/lib/accrue/telemetry/otel.ex` | `@allowed_attributes` + 6 entitlement keys | ✓ VERIFIED | 6 keys (atom + `accrue.<key>` string forms) added; `@prohibited_keys` untouched. |
| `accrue/lib/accrue.ex` | 4 `defdelegate` to `Accrue.Entitlements` | ✓ VERIFIED | All 4 delegates L35/44/53/62 with @doc + @spec. |
| `accrue/test/property/entitlements_fail_closed_property_test.exs` | dual property + multi-active-plan + CR-01 regression | ✓ VERIFIED | `use ExUnitProperties`, 2 `property` blocks + explicit legs; runs GREEN. |

All artifacts pass Levels 1-4 (exist, substantive, wired, data-flowing). The LocalMap data path is confirmed FLOWING by the test-suite SQL log showing real `accrue_subscriptions`/`accrue_subscription_items` queries returning `{price_id, quantity}` tuples folded into the resolved map.

### Key Link Verification

(Manually grep-verified — the `gsd-sdk verify.key-links` tool reported "Source file not found" because the plan `from:` fields are descriptive strings, not bare file paths; this is a tool-format limitation, not a wiring gap.)

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| config `maybe_validate_boot_setup!/1` | `validate_entitlements_price_ids!/1` | cross-plan reduce raising ConfigError | ✓ WIRED | config.ex:863 invokes; L873-903 defines + raises. |
| `Config.entitlements/0` | `:entitlements` key | `get!/1` fallback to `[]` | ✓ WIRED | config.ex:850 `get!(:entitlements)`. |
| `OTel.sanitize_attributes/1` | `@allowed_attributes` | strict allowlist forward | ✓ WIRED | otel.ex:119 `Map.fetch(@allowed_attributes, key)`. |
| `LocalMap.resolve/2` | `Query.active/1` + Subscription/Item/Customer | read-only Ecto query | ✓ WIRED | local_map.ex:69 `Query.active()` joined to items, scoped to customer. |
| `Entitlements` (each fn) | `[:accrue, :entitlements, :check]` | inline `Telemetry.span/3` | ✓ WIRED | entitlements.ex:223 plural literal. |
| `has_active_plan?/2` | resolved `active_plans` MapSet | `MapSet.member?` | ✓ WIRED | entitlements.ex:80 tests `active_plans` set, not `:plan`. |
| `Entitlements` | `Resolver.__impl__/0` | runtime dispatch | ✓ WIRED | entitlements.ex:144 `Resolver.__impl__().resolve(...)`. |
| `Accrue` (top-level) | `Accrue.Entitlements` | `defdelegate` (4 fns) | ✓ WIRED | accrue.ex:35/44/53/62. |
| billing/** (D-14 invariant) | NOT `Accrue.Entitlements.*` | one-way dependency | ✓ HOLDS | `grep -r Accrue.Entitlements accrue/lib/accrue/billing/ accrue/lib/accrue/billing.ex` → 0 matches. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| `entitlements.ex` gate fns | `resolved.{features,active_plans,quantities}` | `Resolver.__impl__().resolve/2` → LocalMap Ecto query | Yes — SQL log shows real `SELECT price_id, quantity FROM accrue_subscriptions JOIN accrue_subscription_items WHERE status IN (...) AND ended_at IS NULL` returning rows | ✓ FLOWING |
| `local_map.ex` `fold_active/1` | `active_items` | `Accrue.Repo.all` over Query.active join | Yes — real DB read, no static `[]`/`{}` fallback in the populated path | ✓ FLOWING |
| `config.ex` `entitlements/0` | `:entitlements` keyword | `Application.get_env` runtime read | Yes — host-supplied catalog, boot-validated | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| `mix compile --warnings-as-errors` | `cd accrue && mix compile --warnings-as-errors` | clean, no warnings | ✓ PASS |
| Phase-scoped test suite | `cd accrue && mix test <6 phase files>` | 2 properties, 52 tests, 0 failures (1 excluded) | ✓ PASS |
| CR-01 fail-closed at runtime | `mix run --no-start /tmp/cr01_check.exs` (non-stringable `:id` + garbage via public `Accrue.*`) | all 8 inputs → false/[]/0, none raised | ✓ PASS |
| OTel + config subset isolation | `cd accrue && mix test otel_test.exs config_entitlements_test.exs` | 12 tests, 0 failures | ✓ PASS |

### Probe Execution

No conventional `scripts/*/tests/probe-*.sh` declared for this phase (Elixir/mix project). The phase verification gate is the `mix test` subset + `mix compile --warnings-as-errors`, both executed above. N/A — no probe scripts.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| ENT-01 | 123-01 | NimbleOptions-validated plan→feature/quota config, canonical source | ✓ SATISFIED | Schema + accessor + boot collision guard; `config_entitlements_test.exs` green. |
| ENT-02 | 123-03, 123-04 | `has_active_plan?` boolean from `Subscription.active?/1` (never raw `.status`) | ✓ SATISFIED | set-membership on `active_plans`; `Query.active/1` reuse; multi-active-plan test green. |
| ENT-03 | 123-03, 123-04 | `entitled?`/`features_for` fail-closed (property-tested) | ✓ SATISFIED | Dual property + raising-stub + CR-01 regression green. |
| ENT-04 | 123-03, 123-04 | `entitlement_quantity/2` read-only seat/quantity; atomic enforcement host-owned | ✓ SATISFIED | Read-only fn + delegate; host-ownership documented. |
| ENT-05 | 123-02, 123-03, 123-04 | `[:accrue, :entitlements, :check]` telemetry/OTel; per-check NOT ledgered | ✓ SATISFIED | Plural span literal + 6 OTel keys + ledger-boundary row-count test green. |

All 5 requirement IDs declared in plan frontmatter and present in REQUIREMENTS.md — no orphaned requirements, no double-mapping. REQUIREMENTS.md marks ENT-01..05 "Complete" and uses the reconciled plural `[:accrue, :entitlements, :check]` event name (D-16, line 22).

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| (none) | — | No `TBD`/`FIXME`/`XXX`/`TODO`/`HACK`/`PLACEHOLDER` in any phase-modified source file | — | Clean. Grep returned 0 matches across all 7 source files. |

No blocker or warning anti-patterns. No stubs (no `return null`/empty-data hardcoding feeding rendering). `@empty` map in local_map.ex is the intentional fail-closed sentinel, not a stub — overwritten by the real fold when data exists.

### Code-Review Disposition (123-REVIEW.md)

The earlier standard review found 1 BLOCKER + 4 warnings + 3 info. Verification confirms remediation:

- **CR-01 (BLOCKER — fail-closed crash on non-stringable `:id`)**: FIXED. `subject_id/1` is now total (`is_binary/is_integer/is_atom` → `to_string`, else `inspect/1` which never raises; entitlements.ex:204-208). Regression test added (property test L141-145) + runtime spot-check confirms no raise.
- **WR-01 (quota-merge determinism)**: FIXED. `Map.update/4` with `max/2` (local_map.ex:108-112); order-independence test added (local_map_test.exs:134-162).
- **WR-03 (entitlements/0 docstring)**: FIXED. Docstring now states "raw runtime read… does NOT apply nested per-plan defaults" (config.ex:842-847).
- **WR-04 (ended-subscription fail-open)**: FIXED. `where([s], is_nil(s.ended_at))` added locally (local_map.ex:77); test added (local_map_test.exs:195+).
- **WR-02 (subject_id OTel cardinality)** + **IN-01/IN-02/IN-03**: Deliberately deferred as accepted follow-ups per phase context — not gaps. `subject_id` remains in the OTel allowlist by design pending the cardinality decision.

### Human Verification Required

None. All five success criteria are observable programmatically: config boot-validation is unit-tested and wired into `Application.start/2`; the fail-closed contract is property-tested (2 properties, 200+100 runs) AND runtime-spot-checked; telemetry/OTel attribute retention and the zero-ledger-write boundary are unit-tested with row-count assertions. No visual/UX/external-service/real-time behavior is in scope for this phase.

### Gaps Summary

No gaps. All 5 ROADMAP success criteria are VERIFIED with codebase evidence; all 8 artifacts pass all four verification levels; all 9 key links (incl. the D-14 one-way-dependency invariant) are wired; all 5 requirement IDs are covered with no orphans; the full phase test suite passes (52 tests + 2 properties, 0 failures) and compiles warnings-as-errors clean. The one BLOCKER and three actionable warnings from the prior code review are fixed with regression tests. The phase goal — local-state, fail-closed plan/feature gating with no new tables and no Stripe dependency — is achieved.

---

_Verified: 2026-05-23T01:15:00Z_
_Verifier: Claude (gsd-verifier)_
