---
phase: 124-enforcement-surfaces-plug-liveview-guards
plan: 03
subsystem: payments
tags: [entitlements, guards, plug, router-macros, controller, fail-closed, content-negotiation]

# Dependency graph
requires:
  - phase: 124-enforcement-surfaces-plug-liveview-guards
    plan: 02
    provides: "Accrue.Entitlements.Guard.check/3 (resolve-once + fail-closed delegation + tiered on_deny + bounded ctx) and deny_plug/4 (pure-Plug opaque content-negotiated 403 / redirect / status-body / fn / MFA) — the engine seam this plug delegates to"
  - phase: 124-enforcement-surfaces-plug-liveview-guards
    plan: 01
    provides: "billable / on_deny / deny_path guard keys on the :entitlements config schema (per-guard opt > config global precedence)"
provides:
  - "Accrue.Plug.RequireEntitlement — the controller-pipeline guard (ENT-06): @behaviour Plug, init/1 validate-and-raise (exactly one of :feature atom / :plan atom|String), call/2 thin delegate to Guard.check/3 + deny_plug/4; pure Plug, NO Phoenix.Controller coupling"
  - "Accrue.Router.require_feature/1 + require_plan/1 — single-arg macros expanding to the canonical plug(Accrue.Plug.RequireEntitlement, feature:/plan: …)"
affects: [124-04 (LiveView surface mirrors this plug's delegate-to-Guard shape on the :live side), 124-06 (merge gate greps the always-compiled plug/router for LiveView refs — none present)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "The plug is a thin transport adapter: init/1 owns only opts validation (raise on ambiguous intent), call/2 owns only the {:allow, conn} -> conn / {:deny, form, ctx} -> deny_plug delegation. ALL decision + deny-translation logic lives in the Wave 2 Guard engine — one code path, no duplication."
    - "init/1 validate-and-raise clones the put_connected_account.ex case…raise ArgumentError discipline (T-124-08): a misconfigured plug raises at compile, never registers with ambiguous intent. Bad billable:/on_deny:/status: runtime VALUES are NOT shape-validated here — they fail closed via the Guard (D-08/D-14)."
    - "Router macros stay single-arg sugar (require_feature :x / require_plan :y); the documented split routes status:/on_deny:/billable: overrides through the explicit plug form, keeping the macros least-surprise."

key-files:
  created:
    - "accrue/lib/accrue/plug/require_entitlement.ex - Accrue.Plug.RequireEntitlement (@behaviour Plug; init/1 validate-and-raise; call/2 delegating to Accrue.Entitlements.Guard; canonical-usage + ## Security moduledoc; zero Phoenix.Controller refs)"
    - "accrue/test/accrue/plug/require_entitlement_test.exs - 16 tests: init validate/raise (8), call allow (1), call deny content-neg + opacity (3), deny overrides status:/on_deny:/config-global on_deny/billable (4)"
    - "accrue/test/accrue/router_test.exs - 5 tests (NEW file): require_feature/require_plan macro-expansion to the canonical plug (atom + String targets) + single-arg arity assertions"
  modified:
    - "accrue/lib/accrue/router.ex - added require_feature/1 + require_plan/1 macros (sugar over the plug) and a controller-pipeline moduledoc section with the advanced-override split note"

key-decisions:
  - "init/1 catch-all raises the same 'requires feature: atom or plan: atom|String' message for neither-present AND wrong-type, matching the put_connected_account.ex two-arm shape; the both-present leg gets its own 'exactly one of' message (T-124-08, two distinct failure modes the plan's <behavior> distinguishes)"
  - "the full plug test (incl. Task 2's status:/on_deny:/config-global override legs) was authored in Task 1's RED because the plug supports every leg out of the box via Guard delegation — no implementation change was needed between Task 1 GREEN and Task 2, so the override legs were already green; the RED commit covered them"
  - "router_test.exs asserts macro expansion via Macro.expand_once round-trip (not a Plug.Builder host module) — deterministic, no controller framework needed, matches the plan's 'lighter deterministic check' guidance"

patterns-established:
  - "Controller enforcement surface = thin Plug adapter over the shared Guard engine; the LiveView surface (Plan 04) is the mirror adapter on the :live side. Both delegate to one check/3, one deny enum, one billable convention."

requirements-completed: [ENT-06]

# Metrics
duration: 2min
completed: 2026-05-23
---

# Phase 124 Plan 03: Controller Enforcement Surface (RequireEntitlement Plug + Router Macros) Summary

**Shipped the route-level entitlement gate a Phoenix developer reaches for first: `Accrue.Plug.RequireEntitlement` — a pure-Plug `@behaviour Plug` whose `init/1` raises `ArgumentError` at compile on ambiguous intent (both / neither / wrong-type `feature:`/`plan:`, T-124-08) and whose `call/2` is a thin delegate to the Wave 2 `Accrue.Entitlements.Guard` engine (allow → conn untouched; deny → content-negotiated opaque 403 / redirect / status override) — plus the `require_feature/1` / `require_plan/1` router macros that expand to the canonical plug, proven by 21 tests with ZERO `Phoenix.Controller` coupling.**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-05-23T12:33:00Z
- **Completed:** 2026-05-23T12:34:54Z
- **Tasks:** 2 (both TDD: RED → GREEN)
- **Files created:** 2 (1 source, 1 test); **modified:** 1 (router); **NEW test file:** 1 (router_test)

## Accomplishments

- **`Accrue.Plug.RequireEntitlement`** (`@behaviour Plug`, ENT-06):
  - **`init/1`** matches on `{Keyword.fetch(opts, :feature), Keyword.fetch(opts, :plan)}` and returns `opts` on the valid single-target leg (`feature:` must be an atom; `plan:` an atom or String). It raises `ArgumentError` with `"exactly one of …"` when BOTH are present, and `"requires `feature: atom` or `plan: atom | String.t()`"` when NEITHER is present OR a target is the wrong type (T-124-08 — the plug cannot register with ambiguous intent). It deliberately does NOT shape-validate `billable:`/`on_deny:`/`status:` (bad runtime values fail closed via the Guard, D-08/D-14).
  - **`call/2`** is a thin delegate: `case Guard.check(:plug, conn, opts) do {:allow, conn} -> conn; {:deny, form, ctx} -> Guard.deny_plug(conn, form, ctx, opts) end`. Allow returns the conn untouched (unhalted); deny returns the Guard's content-negotiated opaque response.
  - **NO Phoenix coupling:** `grep 'Phoenix.Controller' lib/accrue/plug/require_entitlement.ex` returns nothing (the Plan 06 merge gate will pass).
  - **Moduledoc** carries the canonical `plug Accrue.Plug.RequireEntitlement, feature: :api_access` usage, the `status:`/`on_deny: {:redirect, _}`/`billable:` override examples, the macro-vs-plug split, and a `## Security` note (server-side assigns only; `accept` header negotiates not authorizes; fail-closed default).
- **`Accrue.Router.require_feature/1` + `require_plan/1`** — single-arg macros cloning the `accrue_webhook/2` `defmacro … quote do … end` shape, expanding to `plug(Accrue.Plug.RequireEntitlement, feature: unquote(feature))` / `plug(…, plan: unquote(plan))`. The moduledoc gains a controller-pipeline example and documents that advanced overrides use the explicit plug form.
- **Coverage (21 tests, all green):**
  - Plug (16): init validate/raise (8 — both/neither/wrong-type/valid-atom/valid-String/opts-preserved), call allow passthrough (1), call deny content-negotiated JSON + text + unmapped-billable with opacity (3), deny overrides — `status: 402`, per-guard `on_deny: {:redirect, "/pricing"}` → 302+location+halt, config-global `on_deny` honored, config-global `billable` honored (4).
  - Router (5, NEW file): `require_feature :x` / `require_plan :y` / `require_plan "price_pro"` expand to the canonical `plug(Accrue.Plug.RequireEntitlement, …)`; both are arity-1 macros (not arity-2).

## Task Commits

Each task followed the TDD RED → GREEN gate, committed atomically:

1. **Task 1 (RED):** failing plug test — `9d93584` (test)
2. **Task 1 (GREEN):** `Accrue.Plug.RequireEntitlement` plug — `6ec7906` (feat)
3. **Task 2 (RED):** failing router macro-expansion test — `ed1c44f` (test)
4. **Task 2 (GREEN):** `require_feature/1` + `require_plan/1` macros — `3fb098d` (feat)

## Files Created / Modified

- **Created** `accrue/lib/accrue/plug/require_entitlement.ex` — the controller guard plug (delegate-to-Guard `call/2`, validate-and-raise `init/1`, canonical-usage + `## Security` moduledoc, zero Phoenix.Controller refs).
- **Created** `accrue/test/accrue/plug/require_entitlement_test.exs` — 16 tests (`async: false`, env-restore `setup` cloned from the guard/property tests).
- **Created** `accrue/test/accrue/router_test.exs` — 5 tests (NEW; `async: true`, `Macro.expand_once` round-trip — no DB, no Plug.Builder host).
- **Modified** `accrue/lib/accrue/router.ex` — added the two macros + the controller-pipeline moduledoc section.

## Decisions Made

- **`init/1` two-message shape (T-124-08).** Cloning `put_connected_account.ex`, the both-present leg gets a distinct `"exactly one of `:feature` or `:plan`, got both"` message; the catch-all (neither-present OR wrong-type target) shares one `"requires `feature: atom` or `plan: atom | String.t()`"` message. The plan's `<behavior>` distinguishes both-present from neither/wrong-type, so the two messages are asserted by separate regex legs (`~r/exactly one of/` vs `~r/requires/`).
- **The full plug test (incl. Task 2's override legs) was authored in Task 1's RED.** The plug delegates every deny override (`status:`, per-guard/config-global `on_deny:`, config-global `billable:`) straight to `Guard.deny_plug/4` and `Guard.check/3`, which already shipped those behaviors in Plan 02. So no implementation change was needed between Task 1 GREEN and Task 2 for the override legs — they were green the moment the plug existed. The Task 2 commit therefore added only the router macros + router_test; the plug test was complete after Task 1.
- **Router expansion asserted via `Macro.expand_once`.** Rather than build a `Plug.Builder` host module (which would require a controller-framework context for `plug/2`), the test expands the macro AST and pattern-matches the resulting `{:plug, _, [{:__aliases__, _, [:Accrue, :Plug, :RequireEntitlement]}, opts]}` node — deterministic, DB-free, `async: true`.

## Deviations from Plan

None — both tasks executed exactly as written. The plan anticipated that Task 1's RED would create the plug test and Task 2 would "EXTEND/COMPLETE" it with the override legs; in practice the override legs were authored alongside the core legs in Task 1's RED (they require no extra implementation), so Task 2 only added the router macros + the NEW router_test. This is a sequencing nuance within the plan's intent, not a behavioral deviation: every acceptance criterion across both tasks is met and committed.

## Threat Model Coverage

All three `mitigate` dispositions verified; the one `accept` disposition confirmed N/A:

- **T-124-08 (EoP / a misconfigured plug silently allowing):** `init/1` raises `ArgumentError` on both-present / neither-present / wrong-type `feature:`/`plan:`. Tested: 4 init-raise legs (`feature:+plan:`, `[]`, `feature: "notatom"`, `plan: 42`). ✅
- **T-124-09 (Info Disclosure / deny response leaking entitlement structure):** deny delegates to `Guard.deny_plug/4`'s opaque body; the JSON, text, and unmapped-plan deny legs each `refute conn.resp_body =~ "reports"` / `=~ "p1"` (D-10). ✅
- **T-124-10 (DoS / open-redirect via `on_deny: {:redirect, _}`):** the redirect target is a host-declared static path (per-guard opt or config global), never request input; the moduledoc documents it must live OUTSIDE the gated pipeline. No redirect default (default is the opaque 403). ✅
- **T-124-SC (Tampering / package installs):** ZERO external packages installed (all deps pre-locked in `mix.lock`); no Package Legitimacy Gate applied. ✅

## Issues Encountered

None. The verbose Ecto SQL debug logging during the plug test run is normal `BillingCase` output (the entitled-billable legs hit the DB via the factory), not a failure. The router test is DB-free.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- **Plan 04** (LiveView surface) can mirror this plug's delegate shape on the `:live` side: `Guard.check(:live, socket, [{kind, required}])` → `deny_live/3` (using `Guard.deny_path/0`). The plug proves the `:plug` adapter pattern; the LiveView adapter is its `:live` twin.
- **Plan 06** (merge gate): `grep 'Phoenix.Controller' lib/accrue/plug/require_entitlement.ex` and the router macros are clean — no always-compiled core file references the controller/LiveView runtime.
- No blockers.

## Self-Check: PASSED

- `accrue/lib/accrue/plug/require_entitlement.ex` — FOUND (@behaviour Plug, init/1 validate-and-raise, call/2 delegate to Accrue.Entitlements.Guard; no Phoenix.Controller)
- `accrue/lib/accrue/router.ex` — FOUND (defmacro require_feature, defmacro require_plan, each → plug(Accrue.Plug.RequireEntitlement, …))
- `accrue/test/accrue/plug/require_entitlement_test.exs` — FOUND (16 tests green)
- `accrue/test/accrue/router_test.exs` — FOUND (5 tests green, NEW file)
- Commit `9d93584` (RED plug test) — FOUND
- Commit `6ec7906` (GREEN plug) — FOUND
- Commit `ed1c44f` (RED router test) — FOUND
- Commit `3fb098d` (GREEN router macros) — FOUND
- `mix compile --warnings-as-errors` — exit 0
- `mix test test/accrue/plug/require_entitlement_test.exs test/accrue/router_test.exs` — 21 tests, 0 failures
- `grep 'Phoenix.Controller' lib/accrue/plug/require_entitlement.ex` — empty (clean)

---
*Phase: 124-enforcement-surfaces-plug-liveview-guards*
*Completed: 2026-05-23*
