---
phase: 124-enforcement-surfaces-plug-liveview-guards
plan: 01
subsystem: payments
tags: [entitlements, nimble_options, telemetry, opentelemetry, config, plug, liveview, guards]

# Dependency graph
requires:
  - phase: 123-config-core-gate-api-foundation
    provides: ":entitlements config schema + boot validator, the [:accrue, :entitlements, :check] telemetry/OTel split, entitled?/2 + has_active_plan?/2 fail-closed predicates with span/5 builder"
provides:
  - "billable / on_deny / deny_path keys on the :entitlements config schema, defaulted (nil / :forbidden / \"/\") and boot-validated"
  - "validate_on_deny/1 custom validator — a malformed global on_deny fails loud at boot, never fails open"
  - ":surface allowlist entry (atom + accrue.surface string) on the OTel attribute bridge"
  - "additive surface: opt threaded onto Accrue.Entitlements.entitled?/3 + has_active_plan?/3, merged onto the existing :check span"
affects: [124-02 (Plug + LiveView guard surfaces consume these config keys, surface-aware predicates, and :surface telemetry dimension)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Custom NimbleOptions {:custom, __MODULE__, :validate_on_deny, []} validator cloning the validate_descending/1 shape for a union type NimbleOptions cannot express"
    - "entitlements/0 surfaces only the three top-level scalar guard-key defaults via Keyword.put_new (raw :plans read kept intact)"
    - "Additive opts \\ [] on a predicate + merge of one allowlisted metadata key keeps 2-arity public delegates non-breaking (D-18)"

key-files:
  created: []
  modified:
    - "accrue/lib/accrue/config.ex - +3 guard keys on :entitlements schema, +validate_on_deny/1, entitlements/0 surfaces guard-key defaults"
    - "accrue/lib/accrue/telemetry/otel.ex - +:surface allowlist (atom + string)"
    - "accrue/lib/accrue/entitlements.ex - entitled?/3 + has_active_plan?/3 additive surface: opt, span/5 -> span/6"
    - "accrue/test/accrue/config_entitlements_test.exs - guard-config + on_deny/deny_path boot-validation + validate_on_deny/1 cases"
    - "accrue/test/accrue/entitlements_test.exs - surface-metadata telemetry cases"

key-decisions:
  - "on_deny uses a {:custom, validate_on_deny} validator (not type: :any) so a malformed global on_deny fails loud at boot — T-124-01 mitigation"
  - "billable uses {:or, [nil, {:fun, 1}]} — NimbleOptions 1.1.1 supports both nil and {:fun, 1} subtypes (verified against deps), so the :any fallback was NOT needed"
  - ":surface stays a distinct OTel key (not folded into :status/:result), mirroring the D-19 :result-stays-distinct discipline"
  - "surface: is internal telemetry only — predicates go to arity 3 internally, but the public Accrue.entitled?/2 + has_active_plan?/2 facade delegates stay arity 2 (no Accrue.entitled?/3 added)"

patterns-established:
  - "Guard config keys live under :entitlements (not a new top-level config key), boot-validated for free via validate_at_boot!/0"
  - "entitlements/0 is the single read point that surfaces guard-key defaults for downstream surfaces"

requirements-completed: [ENT-06, ENT-07]

# Metrics
duration: 3min
completed: 2026-05-23
---

# Phase 124 Plan 01: Guard Config + Surface Telemetry Contract Summary

**Extended the Phase 123 entitlement foundation with the three host-supplied guard config keys (billable / on_deny / deny_path, boot-validated via a custom validate_on_deny/1), an OTel :surface allowlist entry, and an additive surface: opt on entitled?/3 + has_active_plan?/3 — the contract layer both Plug and LiveView guards consume, with zero breakage to any Phase 123 caller.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-05-23T12:12:51Z
- **Completed:** 2026-05-23T12:15:42Z
- **Tasks:** 3
- **Files modified:** 5 (3 source, 2 test)

## Accomplishments

- Three Phase 124 guard keys on the `:entitlements` schema — `billable` (`{:or, [nil, {:fun, 1}]}`, default `nil`), `on_deny` (custom-validated, default `:forbidden`), `deny_path` (`:string`, default `"/"`) — boot-validated for free by the existing `validate_at_boot!/0`.
- `validate_on_deny/1` custom validator: accepts `:forbidden | {:redirect, path} | {status, body} | fun/2 | {m,f,a}`, rejects everything else with a descriptive message so a malformed global `on_deny` fails loud at boot (T-124-01).
- `:surface => "accrue.surface"` allowlisted in both the atom and string blocks of the OTel `@allowed_attributes` map (D-18), distinct from `:status`/`:result`.
- `entitled?/3` + `has_active_plan?/3` accept an additive `opts \\ []`; `span/5` became `span/6` merging `surface: Keyword.get(opts, :surface)` onto the same `[:accrue, :entitlements, :check]` span — `nil` for direct callers, `:plug`/`:live` for guard calls.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add billable/on_deny/deny_path to the :entitlements config schema + boot validator** - `c80f254` (feat, TDD)
2. **Task 2: Add :surface to the OTel @allowed_attributes allowlist (atom + string)** - `d176650` (feat)
3. **Task 3: Thread additive surface: opts through entitled?/2 and has_active_plan?/2** - `4527bd3` (feat, TDD)

_TDD tasks 1 and 3 combined RED + GREEN into single commits (RED test additions + GREEN implementation staged together)._

## Files Created/Modified

- `accrue/lib/accrue/config.ex` - Added `billable`/`on_deny`/`deny_path` keys to the `:entitlements` schema, the public `validate_on_deny/1` custom validator, and made `entitlements/0` surface the three guard-key defaults via `Keyword.put_new`.
- `accrue/lib/accrue/telemetry/otel.ex` - Added `:surface => "accrue.surface"` (atom block) and `"accrue.surface" => "accrue.surface"` (string block).
- `accrue/lib/accrue/entitlements.ex` - `entitled?/2 -> /3` and `has_active_plan?/2 -> /3` with `opts \\ []`; `span/5 -> span/6` merging `surface:`; moduledoc documents the D-18 surface dimension.
- `accrue/test/accrue/config_entitlements_test.exs` - New describe blocks: guard-config defaults, on_deny boot validation (valid + malformed forms), deny_path boot validation, and `validate_on_deny/1` direct cases. Updated two stale `entitlements() == []` assertions (see Deviations).
- `accrue/test/accrue/entitlements_test.exs` - New telemetry cases: `:surface == nil` for 2-arity, `:plug`/`:live` for guard calls.

## Decisions Made

- **`{:fun, 1}` works — no `:any` fallback.** The plan allowed a `type: :any` fallback if NimbleOptions rejected `{:fun, 1}`. Verified against the installed NimbleOptions 1.1.1 (`deps/nimble_options/lib/nimble_options.ex`) that both `nil` (line 784) and `{:fun, arity}` (line 762) are valid subtypes, so `billable` uses the stricter `{:or, [nil, {:fun, 1}]}` and the fallback was not needed.
- **`on_deny` uses a custom validator, not `:any`.** The RESEARCH note flagged `type: :any` + a `{:custom, ...}` validator as the cleanest fail-loud route; the plan's `<action>` mandated the custom validator. Implemented `validate_on_deny/1` cloning `validate_descending/1`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `entitlements/0` does not apply nested defaults — guard-key defaults had to be surfaced explicitly**
- **Found during:** Task 1 (config schema + boot validator)
- **Issue:** The plan's `<action>` asserted "Leave `entitlements/0` as-is — it already returns the whole validated keyword list including the new keys with their defaults applied." This premise is factually wrong: `entitlements/0` is a documented **raw** runtime read (config.ex:834-847) that does NOT apply NimbleOptions defaults. With it left as-is, the plan's own Task 1 behavior ("With no config, `Accrue.Config.entitlements()` returns defaults including `billable: nil`, `on_deny: :forbidden`, `deny_path: "/"`") and the acceptance criterion (`entitlements() |> Keyword.get(:deny_path) == "/"` when unset) would both fail.
- **Fix:** `entitlements/0` now surfaces only the three top-level scalar guard-key defaults via `Keyword.put_new(:billable, nil) |> Keyword.put_new(:on_deny, :forbidden) |> Keyword.put_new(:deny_path, "/")`. The raw `:plans` read is left untouched (resolver and `reverse_index` use `Keyword.get(:plans, [])` and are unaffected — both callers verified). Host-supplied values still win (`put_new` is a no-op when the key is present).
- **Files modified:** accrue/lib/accrue/config.ex
- **Verification:** New `guard config defaults` describe block (3 tests) passes; full entitlements + resolver + property suite (40 tests) green — no resolver regression.
- **Committed in:** `c80f254` (Task 1 commit)

**2. [Rule 1 - Bug] Two stale Phase 123 `entitlements() == []` assertions updated for the defaults-surfaced shape**
- **Found during:** Task 1
- **Issue:** `config_entitlements_test.exs` had two assertions (`entitlements() == []` for absent and empty config) that became stale once `entitlements/0` surfaces the three guard-key defaults — they would falsely fail.
- **Fix:** Rewrote both to `refute Keyword.has_key?(Config.entitlements(), :plans)` (the Phase 123 catalog stays absent), which is the substantive invariant they were guarding. No production behavior changed for the `:plans` catalog.
- **Files modified:** accrue/test/accrue/config_entitlements_test.exs
- **Verification:** Both updated tests pass; full config suite (57 tests) green.
- **Committed in:** `c80f254` (Task 1 commit)

**3. [Rule 3 - Blocking] RED/GREEN config tests written into `config_entitlements_test.exs`, not `config_test.exs`**
- **Found during:** Task 1
- **Issue:** The plan's automated verify references `test/accrue/config_test.exs`, but the Phase 123 `:entitlements` config tests actually live in a dedicated `test/accrue/config_entitlements_test.exs` (`config_test.exs` has no entitlements coverage). Writing the new guard-config tests into `config_test.exs` would have split entitlements coverage across two files.
- **Fix:** Added the new guard-config and `validate_on_deny/1` tests to `config_entitlements_test.exs` alongside the existing ENT-01 coverage. Ran BOTH `config_test.exs` and `config_entitlements_test.exs` in verification to satisfy the plan's intent.
- **Files modified:** accrue/test/accrue/config_entitlements_test.exs
- **Verification:** `mix test test/accrue/config_test.exs test/accrue/config_entitlements_test.exs` → 57 tests, 0 failures.
- **Committed in:** `c80f254` (Task 1 commit)

---

**Total deviations:** 3 auto-fixed (2 Rule 1 bugs, 1 Rule 3 blocking)
**Impact on plan:** All three are corrections to incorrect plan premises about the existing codebase (raw-read `entitlements/0`, stale assertions, test-file location). No scope creep — the schema keys, validator, OTel entry, and additive opts shipped exactly as specified.

## Issues Encountered

None beyond the deviations above. The threat-model mitigations (T-124-01 fail-loud `on_deny`, T-124-03 non-breaking additive opts) were verified directly: malformed `on_deny` raises at boot, and the unchanged Phase 123 fail-closed property test passes against the 2-arity delegates.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The config + telemetry contract is stable for Plan 02 (Wave 2 Guard engine + Plug/LiveView surfaces): guards read `billable`/`on_deny`/`deny_path` from `Accrue.Config.entitlements()` (defaults guaranteed surfaced), call `Accrue.Entitlements.entitled?(billable, feature, surface: surface)` / `has_active_plan?(billable, plan, surface: surface)`, and the `:surface` dimension survives the OTel bridge.
- Contract note honored: the surface-aware entry points are the INTERNAL `Accrue.Entitlements.entitled?/3` + `has_active_plan?/3`; the public `Accrue` facade stays arity 2.
- No blockers.

## Self-Check: PASSED

- `accrue/lib/accrue/config.ex` — FOUND (deny_path, validate_on_deny, billable all present)
- `accrue/lib/accrue/telemetry/otel.ex` — FOUND (accrue.surface ×3)
- `accrue/lib/accrue/entitlements.ex` — FOUND (entitled?/3, has_active_plan?/3, surface merge)
- Commit `c80f254` — FOUND
- Commit `d176650` — FOUND
- Commit `4527bd3` — FOUND

---
*Phase: 124-enforcement-surfaces-plug-liveview-guards*
*Completed: 2026-05-23*
