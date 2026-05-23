---
phase: 124-enforcement-surfaces-plug-liveview-guards
plan: 02
subsystem: payments
tags: [entitlements, guards, plug, liveview, telemetry, fail-closed, decision-engine]

# Dependency graph
requires:
  - phase: 124-enforcement-surfaces-plug-liveview-guards
    plan: 01
    provides: "billable / on_deny / deny_path keys on Accrue.Config.entitlements/0 (defaulted nil / :forbidden / \"/\"), the surface: additive opt on Accrue.Entitlements.entitled?/3 + has_active_plan?/3, and the :surface OTel allowlist entry"
  - phase: 123-config-core-gate-api-foundation
    provides: "fail-closed entitled?/has_active_plan? predicates + the [:accrue, :entitlements, :check] telemetry/OTel span"
provides:
  - "Accrue.Entitlements.Guard.check/3 — the always-compiled, LiveView-runtime-free shared decision engine both surfaces call: billable resolution (precedence + resolve-once + fail-closed), fail-closed delegation to the Phase 123 gate carrying surface:, tiered on_deny, bounded no-PII ctx"
  - "Accrue.Entitlements.Guard.deny_plug/4 — pure-Plug opaque content-negotiated 403 / redirect / status-body / fn / MFA deny translation (no Phoenix.Controller)"
  - "Accrue.Entitlements.Guard.deny_path/0 — config deny_path for the Plan 04 LiveView surface's deny_live/3"
  - "the engine_contract blueprint (check/3, deny_plug/4, deny_path/0, ctx shape) the Plan 03 plug + Plan 04 LiveView surfaces consume"
affects: [124-03 (RequireEntitlement plug calls check/3 + deny_plug/4), 124-04 (Live.Entitlements calls check/3 + deny_path/0 for deny_live/3), 124-06 (merge gate greps this always-compiled engine for LiveView/socket refs)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Shared decision engine takes an opaque container term (conn for :plug, socket/%{assigns:} for :live) so it stays LiveView-runtime-free yet serves both surfaces — surface modules become thin transport adapters"
    - "Resolve-once for :plug stashes the billable TERM on the conn (read :accrue_billable first, assign only if absent); :live returns the resolved billable for the surface to assign_new — keeps the Component module out of always-compiled core"
    - "Host billable fn wrapped in the entitlements.ex rescue/catch -> nil idiom so a raising fn fails closed; the nil then flows to the Phase 123 gate which denies"
    - "ctx.reason is coarse-by-design (:not_entitled / :no_active_subscription) — the precise reason atom lives in the inherited :check telemetry span, NOT in ctx (one gate call, no second lookup)"

key-files:
  created:
    - "accrue/lib/accrue/entitlements/guard.ex - the shared Accrue.Entitlements.Guard decision engine (check/3, resolve_billable/3, deny_plug/4, deny_path/0)"
    - "accrue/test/accrue/entitlements/guard_test.exs - billable precedence + resolve-once + fail-closed legs + opaque content-negotiated deny (13 tests)"
    - "accrue/test/accrue/entitlements/guard_telemetry_test.exs - surface: dimension reaches the :check span for :plug and :live (3 tests)"
  modified: []

key-decisions:
  - "ctx.reason is coarse-by-design: :no_active_subscription when no billable resolved, else :not_entitled — the precise Phase 123 reason atom lives in the :check span metadata, not ctx (D-08/D-12/D-17, one gate call)"
  - "guard.ex moduledoc/comments avoid the literal Phoenix.LiveView/Component/Socket/Controller dotted tokens so the Plan 06 merge-gate regex grep returns nothing even when scanning prose"
  - "the :live container is read as container.assigns only — tests pass a bare %{assigns: %{}} map, no full socket needed; documented in the test"
  - "deny_plug/4 redirect is pure Plug (put_resp_header location + send_resp(302) + halt), never Phoenix; the {status, body} clause is last so the {:redirect, _} / {m,f,a} tuples match first"

patterns-established:
  - "All guard decision/deny logic lives in the always-compiled Guard engine; the cond-compiled live surface (Plan 04) and the plug (Plan 03) stay logic-free transport adapters — one billable fn, one deny enum, one code path"
  - "guard_target!/1 enforces exactly one of :feature / :plan (raises on both/neither), so the surfaces inherit input validation"

requirements-completed: [ENT-06, ENT-07]

# Metrics
duration: 3min
completed: 2026-05-23
---

# Phase 124 Plan 02: Shared Entitlements Guard Engine Summary

**Built `Accrue.Entitlements.Guard` — the always-compiled, LiveView-runtime-free decision engine both enforcement surfaces call: it resolves the billable once (per-guard opt → config global → `current_scope.user`/`current_user` probe), delegates the allow/deny decision fail-closed to the Phase 123 gate carrying the `surface:` telemetry dimension, resolves the tiered `on_deny` (per-guard → config → `:forbidden`), builds a bounded no-PII `ctx`, and translates plug denies opaquely — with zero LiveView/Phoenix.Controller coupling, proven by 16 unit + telemetry tests.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-05-23T12:26:53Z
- **Completed:** 2026-05-23T12:30:13Z
- **Tasks:** 3
- **Files created:** 3 (1 source, 2 test)

## Accomplishments

- **`check/3`** resolves the billable exactly once with the D-14/D-15 precedence (per-guard `billable:` opt → `config :accrue, :entitlements, billable:` → default `current_scope.user`/`current_user` probe → `nil`), stashes it billable-only on the conn (`:accrue_billable`, never the boolean), delegates the decision to `Accrue.Entitlements.entitled?/3` / `has_active_plan?/3` with `surface:` (D-08), and returns `{:allow, container}` or `{:deny, deny_form, ctx}`.
- **Fail-closed by construction:** a `nil` billable, a raising `billable:` fn (wrapped in the `entitlements.ex` `rescue`/`catch → nil` idiom), or an unmapped billable all deny — the `nil` flows to the Phase 123 gate which fails closed (T-124-04).
- **Tiered `on_deny`** (D-11): per-guard `on_deny:` opt → config global → built-in `:forbidden`. **`deny_plug/4`** translates the deny enum on the Plug surface: content-negotiated opaque 403 (`{"error":"forbidden"}` for JSON `accept`, else `"Forbidden"`, with a `status:` override), `{:redirect, path}` → pure-Plug 302, `{status, body}`, a 2-arity fn, and an MFA `{m,f,a}` — all `halt`ed, body always opaque (D-10, T-124-06).
- **Bounded no-PII `ctx`** (D-12): `%{guard:, required:, reason:, billable:, surface:}` with `reason` coarse-by-design (the precise reason atom lives in the `:check` span, documented in the moduledoc).
- **`surface:`** provably reaches the inherited `[:accrue, :entitlements, :check]` span for both `:plug` and `:live` (no new guard event, one span — D-18).
- **Engine stays LiveView/Phoenix-runtime-free:** `grep -E 'Phoenix\.(LiveView|Component|Socket|Controller)'` on the source returns nothing (the Plan 06 merge gate will pass), achieved by reading only an opaque `container.assigns` and keeping the `assign_new` stash in the surface (Plan 04).

## Task Commits

Each task was committed atomically:

1. **Task 1: Build the Accrue.Entitlements.Guard engine** — `c4726bc` (feat, TDD GREEN)
2. **Task 2: guard_test.exs — precedence, resolve-once, fail-closed, opaque deny** — `1f9eb61` (test, TDD)
3. **Task 3: guard_telemetry_test.exs — surface: reaches the :check span** — `d1b7974` (test)

## Files Created

- `accrue/lib/accrue/entitlements/guard.ex` — `Accrue.Entitlements.Guard`: `check/3` (resolve-once + delegate + tiered on_deny + ctx), `resolve_billable/3` (total, fail-closed), `deny_plug/4` (pure-Plug opaque content-negotiated deny translation), `deny_path/0` (config read for Plan 04). `## Security` and `## Deny reason` moduledoc notes document the server-side-assigns-only billable source and the coarse-by-design `ctx.reason` contract.
- `accrue/test/accrue/entitlements/guard_test.exs` — 13 tests: billable precedence (5), resolve-once billable-only stash (1), fail-closed legs (3), `deny_plug/4` content negotiation + opacity + `:status` override + redirect (4).
- `accrue/test/accrue/entitlements/guard_telemetry_test.exs` — 3 tests: `surface: :plug` (conn), `surface: :live` (`%{assigns: %{}}` map), and a denied check still carrying the dimension.

## Decisions Made

- **`ctx.reason` is coarse-by-design.** The boolean predicate the Guard delegates to returns no reason, and D-08/D-17 mandate exactly one gate call per check — so `ctx.reason` is `:no_active_subscription` when no billable resolved, else `:not_entitled`. The precise Phase 123 reason atom (`:not_entitled | :no_active_subscription | :unmapped_plan | :error`) lives in the `[:accrue, :entitlements, :check]` span. The moduledoc converts this narrowing into a documented contract (WARNING 2 / D-12).
- **Moduledoc prose avoids the literal dotted Phoenix tokens.** The plan's acceptance-criteria grep (and the Plan 06 merge gate) match `Phoenix\.(LiveView|Component|Socket|Controller)`. The descriptive notes (which legitimately discuss the *absence* of those refs) were reworded to drop the dotted form so the grep returns nothing — the gate scans always-compiled core including comments.
- **The `:live` container is `container.assigns`-only.** The engine never touches a socket-specific API, so tests pass a bare `%{assigns: %{}}` map. This is exactly what keeps the engine LiveView-runtime-free and lets Plan 04 own the `assign_new` stash.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Reworded moduledoc/comment prose to drop the literal `Phoenix.LiveView`/`Component`/`Socket`/`Controller` tokens**
- **Found during:** Task 1 (acceptance-criteria grep verification)
- **Issue:** The plan instructs the moduledoc to explain that the engine holds NO LiveView refs, but writing that explanation with the literal dotted module names (`Phoenix.LiveView`, etc.) made the acceptance-criteria grep (`grep -E 'Phoenix\.(LiveView|Component|Socket|Controller)' guard.ex`) match the prose — which would fail both this plan's verification AND the Plan 06 merge gate (which greps always-compiled core, comments included).
- **Fix:** Reworded the moduledoc and three inline comments to describe the absence without the dotted tokens (e.g. "none of the LiveView, Component, Socket, or Controller Phoenix modules", "no `assign_new`/Component reference", "NO Controller module"). The substantive documentation is unchanged; only the token spelling avoids the regex.
- **Files modified:** accrue/lib/accrue/entitlements/guard.ex
- **Verification:** `grep -E 'Phoenix\.(LiveView|Component|Socket|Controller)' accrue/lib/accrue/entitlements/guard.ex` returns nothing; `mix compile --warnings-as-errors` clean; all 16 tests green.
- **Committed in:** `c4726bc` (Task 1 commit)

**2. [Rule 3 - Blocking] `put_req_header/3` is `Plug.Conn`, not `Plug.Test` — added a scoped import**
- **Found during:** Task 2 (first guard_test.exs run)
- **Issue:** The test builds conns with a JSON `accept` header via `put_req_header/3`, but that fn lives in `Plug.Conn`, not `Plug.Test`; the initial compile failed with `undefined function put_req_header/3`.
- **Fix:** Added `import Plug.Conn, only: [put_req_header: 3, get_resp_header: 2]` to the test module.
- **Files modified:** accrue/test/accrue/entitlements/guard_test.exs
- **Verification:** `mix test test/accrue/entitlements/guard_test.exs` → 13 tests, 0 failures.
- **Committed in:** `1f9eb61` (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 3 blocking — a verification-blocking grep collision and a missing test import). No scope creep: `check/3`, `resolve_billable/3`, `deny_plug/4`, and `deny_path/0` shipped exactly as the engine_contract specified.
**Impact on plan:** None on behavior — both fixes are mechanical (token spelling, import scope). The engine and its contract match the plan's `<engine_contract>` blueprint, so Plan 03 (plug) and Plan 04 (LiveView) have stable seams.

## Threat Model Coverage

All four threat-register dispositions are `mitigate` and verified:

- **T-124-04 (EoP / fail-OPEN on resolver error):** `resolve_billable/3` wraps the host fn in `rescue`/`catch → nil`; the raising-fn leg in `guard_test.exs` proves deny. ✅
- **T-124-05 (Spoofing / billable via request input):** the default probe + host fn read ONLY `container.assigns`; the `accept` header is read only for content negotiation. Source-asserted (no params/headers feed the billable). ✅
- **T-124-06 (Info Disclosure / deny body leak):** `deny_plug/4` body is opaque; the opacity assertion (`refute resp_body =~ "reports"`) passes for both JSON and text. ✅
- **T-124-07 (Tampering / boolean stash):** the resolve-once test asserts `:accrue_billable` present (billable term) and `:accrue_entitled` absent. ✅

## Issues Encountered

None beyond the two deviations above. The verbose Ecto SQL debug logging during the test run is normal `BillingCase` output, not a failure.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- The engine contract is stable for **Plan 03** (RequireEntitlement plug): call `Guard.check(:plug, conn, opts)` then `Guard.deny_plug(conn, deny_form, ctx, opts)`.
- Stable for **Plan 04** (Live.Entitlements `on_mount`): call `Guard.check(:live, socket, [{kind, required}])`, then `deny_live/3` translates `deny_form` + `ctx` using `Guard.deny_path/0` (the surface owns its own `assign_new(:accrue_billable, …)` stash).
- Stable for **Plan 06** (merge gate): `grep -E 'Phoenix\.(LiveView|Component|Socket|Controller)' lib/accrue/entitlements/guard.ex` returns nothing.
- No blockers.

## Self-Check: PASSED

- `accrue/lib/accrue/entitlements/guard.ex` — FOUND (check/3, deny_plug/4, deny_path/0, both delegates, rescue/catch, coarse-reason moduledoc; no Phoenix runtime refs)
- `accrue/test/accrue/entitlements/guard_test.exs` — FOUND (13 tests green)
- `accrue/test/accrue/entitlements/guard_telemetry_test.exs` — FOUND (3 tests green)
- Commit `c4726bc` — FOUND
- Commit `1f9eb61` — FOUND
- Commit `d1b7974` — FOUND

---
*Phase: 124-enforcement-surfaces-plug-liveview-guards*
*Completed: 2026-05-23*
