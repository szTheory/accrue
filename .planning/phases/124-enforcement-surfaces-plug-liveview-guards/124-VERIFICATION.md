---
phase: 124-enforcement-surfaces-plug-liveview-guards
verified: 2026-05-23T15:05:00Z
status: passed
score: 4/4 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: none
  previous_score: none
  note: "Initial verification (no prior VERIFICATION.md). CR-01/WR-01 BLOCKER fix in commit aecd640 verified live against code + tests."
---

# Phase 124: Enforcement Surfaces — Plug + LiveView Guards Verification Report

**Phase Goal:** A developer can gate both controller routes and host LiveViews on entitlement, with the same fail-closed contract, while core `accrue` remains runtime-LiveView-free for headless/API hosts.
**Verified:** 2026-05-23T15:05:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| #   | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| 1   | A developer can gate a Phoenix controller route with a Plug guard (`require_plan`/`require_feature`) that halts with a configurable fail response (redirect or 403) when the billable is not entitled. | ✓ VERIFIED | `accrue/lib/accrue/plug/require_entitlement.ex` (`@behaviour Plug`, `init/1` raises on bad opts, `call/2` delegates to `Guard.check/3`). `accrue/lib/accrue/router.ex` `defmacro require_feature/1` + `require_plan/1` expand to the canonical plug (router_test.exs asserts the expanded AST). Deny is content-negotiated: opaque JSON `{"error":"forbidden"}` for JSON accept, `"Forbidden"` text otherwise, configurable `status:` (402 tested), and `on_deny: {:redirect, "/pricing"}` → 302 (require_entitlement_test.exs:146-261). 16 plug tests + 5 router tests pass. |
| 2   | A developer can gate a host LiveView with an `on_mount` guard whose billable-resolution key is host-configurable and adapter-thin, with no required Sigra/Lockspire coupling. | ✓ VERIFIED | `accrue/lib/accrue/live/entitlements.ex` exports `on_mount/4` ({:require_feature, x}/{:require_plan, y}) returning `{:cont, socket}`/`{:halt, socket}`. Billable resolution is shared via `Guard.check(:live, …)` → `resolve_billable/3`: per-guard `billable:` fn → `config :accrue, :entitlements, billable:` → default probe `current_scope.user`/`current_user`/nil (guard.ex:136-141, 253-289). No Sigra/Lockspire reference anywhere in the guard path (server-side assigns only). 10 live tests pass. |
| 3   | The LiveView guard ships via conditional compilation, and a merge-blocking CI check proves no always-compiled core module references the LiveView socket runtime — core stays runtime-LiveView-free even though `phoenix_live_view` is a required core dep. | ✓ VERIFIED | `live/entitlements.ex` wraps `defmodule` in `if Code.ensure_loaded?(Phoenix.LiveView)` + `@compile {:no_warn_undefined, …}` (Sigra 4-pattern). `scripts/ci/verify_core_liveview_runtime_free.sh` RAN → `OK`, exit 0. Independent grep cross-check: zero `import/alias Phoenix.LiveView`, `Phoenix.LiveView.Socket`, `Phoenix.Socket`, or `def on_mount` in `accrue/lib` outside `lib/accrue/live/`. Gate wired into `.github/workflows/ci.yml:49-50` (merge-blocking `docs-contracts-shift-left` job). `mix.exs:86` `{:phoenix_live_view, "~> 1.1"}` non-optional. |
| 4   | Both guards resolve entitlement once per request/mount and reuse the Phase 123 fail-closed contract — a guard whose check cannot resolve denies rather than allows. | ✓ VERIFIED | Resolve-once (D-17): `:plug` stashes billable on `conn.assigns[:accrue_billable]`, second check reads stash (guard_test.exs "billable fn runs exactly once across two checks" — Agent count == 1). `:live` CR-01 FIX (commit aecd640) verified live: `resolve_once(:live, …)` stashes billable onto `%{container | assigns: Map.put(...)}` (guard.ex:229-251) — Guard-level test asserts `container.assigns[:accrue_billable] == b` (guard_test.exs:148-157) and live test asserts `socket2.assigns.accrue_billable == billable` (entitlements_test.exs:127, value not just key). Cross-surface fail-closed property (guard_fail_closed_property_test.exs, 200 runs): nil/garbage/raising-fn/exception/no-sub/unmapped-plan all DENY on BOTH surfaces; the SOLE allow is an affirmative resolved match. `surface:` reaches the inherited `[:accrue, :entitlements, :check]` span (guard_telemetry_test.exs). |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `accrue/lib/accrue/entitlements/guard.ex` | Always-compiled shared decision engine, NO LiveView refs | ✓ VERIFIED | 331 lines. `check/3` resolves once, delegates to `Accrue.Entitlements.entitled?/3`/`has_active_plan?/3` (never makes own allow), tiered `on_deny`, bounded ctx, fail-closed `safe_apply`/`default_probe`. Zero socket-runtime refs (only doc-comment mention of `on_mount`). |
| `accrue/lib/accrue/live/entitlements.ex` | Cond-compiled on_mount guard; ONLY core file allowed LiveView refs | ✓ VERIFIED | 146 lines. `Code.ensure_loaded?(Phoenix.LiveView)` wrapper + `@compile {:no_warn_undefined, …}` + thin `on_mount/4` delegating to Guard. |
| `accrue/lib/accrue/plug/require_entitlement.ex` | @behaviour Plug guard delegating to Guard | ✓ VERIFIED | 83 lines. `@behaviour Plug`, `init/1` raises ArgumentError on both/neither feature/plan, `call/2` → `Guard.check/3` + `Guard.deny_plug/4`. |
| `accrue/lib/accrue/router.ex` | require_feature/1 + require_plan/1 macros | ✓ VERIFIED | `defmacro require_feature/1` + `require_plan/1` expand to `plug Accrue.Plug.RequireEntitlement, feature:/plan: …`. |
| `accrue/lib/accrue/config.ex` | billable/on_deny/deny_path keys + boot validator | ✓ VERIFIED | Schema keys at lines 396-414, `validate_on_deny/1` at 1024-1036, defaults surfaced in `entitlements/0` (883-885). |
| `accrue/lib/accrue/entitlements.ex` | additive surface: opts on entitled?/3 + has_active_plan?/3 | ✓ VERIFIED | `entitled?(billable, feature, opts \\ [])` and `has_active_plan?(…, opts \\ [])`; `span/6` merges `surface: Keyword.get(opts, :surface)` (line 238). Public `Accrue` facade stays arity 2. |
| `accrue/lib/accrue/telemetry/otel.ex` | :surface OTel allowlist (atom + string) | ✓ VERIFIED | `:surface => "accrue.surface"` + `"accrue.surface" => "accrue.surface"`; `grep -o accrue.surface` = 3. |
| `scripts/ci/verify_core_liveview_runtime_free.sh` | static grep merge-gate | ✓ VERIFIED | RAN, exit 0, prints OK. Scans `accrue/lib`, allowlists comments + `/accrue/live/`. |
| `.github/workflows/ci.yml` | merge-blocking gate wiring | ✓ VERIFIED | Lines 49-50 run the gate in `docs-contracts-shift-left` (a merge-blocking PR job). |
| `accrue/test/property/guard_fail_closed_property_test.exs` | cross-surface fail-closed property (SC#4) | ✓ VERIFIED | 3 invariants × both surfaces; 200-run garbage property + raising/no-sub/unmapped + affirmative-allow leg. |
| `accrue/mix.exs` | clarified non-optional phoenix_live_view comment | ✓ VERIFIED | Lines 78-86 document Component spine + cond-compiled guard, no socket runtime. |
| `CLAUDE.md` / `.planning/ROADMAP.md` / `PITFALLS.md` / `oban/middleware.ex` | LiveView-runtime-free doc reconciliation | ✓ VERIFIED | All carry "runtime-free"/"socket runtime" framing; oban middleware moduledoc corrected (line 21-26). |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| `plug/require_entitlement.ex` | `Accrue.Entitlements.Guard.check/3` | `call/2` delegation | ✓ WIRED | `call/2` matches `Guard.check(:plug, conn, opts)` (line 78). |
| `router.ex` | `Accrue.Plug.RequireEntitlement` | macro → plug/2 | ✓ WIRED | Both macros emit `plug(Accrue.Plug.RequireEntitlement, …)`; router_test asserts AST. |
| `live/entitlements.ex` | `Accrue.Entitlements.Guard.check/3` | on_mount delegation | ✓ WIRED | `decide/3` calls `Guard.check(:live, socket, …)` (line 115). |
| `guard.ex` | `Accrue.Entitlements.entitled?/3` + `has_active_plan?/3` | surface-aware predicate delegation | ✓ WIRED | guard.ex:104-105 calls both with `surface: surface`; public facade stays arity 2. |
| `entitlements.ex` | `[:accrue, :entitlements, :check]` span | `span/6` surface merge | ✓ WIRED | `span/6` merges `surface:`; guard_telemetry_test confirms it reaches `:check.stop` meta. |
| `.github/workflows/ci.yml` | `scripts/ci/verify_core_liveview_runtime_free.sh` | merge-blocking run step | ✓ WIRED | Line 50 `run: bash scripts/ci/verify_core_liveview_runtime_free.sh`. |
| `guard_fail_closed_property_test.exs` | `Accrue.Entitlements.Guard.check/3` | fail-closed property | ✓ WIRED | Property drives `Guard.check` over garbage/raising inputs on both surfaces. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Core compiles clean (warnings-as-errors) | `cd accrue && mix compile --warnings-as-errors` | exit 0, no warnings | ✓ PASS |
| LiveView-runtime-free merge gate | `bash scripts/ci/verify_core_liveview_runtime_free.sh` | "OK", exit 0 | ✓ PASS |
| All phase 124 test suites | `mix test` (10 phase suites) | 3 properties, 105 tests, 0 failures (1 excluded) | ✓ PASS |
| Independent SC#3 socket-runtime grep | `grep -rnE '(import\|alias) Phoenix.LiveView\|Phoenix.LiveView.Socket\|Phoenix.Socket\|def on_mount' accrue/lib (excl. /live/)` | NONE | ✓ PASS |
| OTel `:surface` allowlist count | `grep -o 'accrue.surface' otel.ex \| wc -l` | 3 | ✓ PASS |

### Probe Execution

| Probe | Command | Result | Status |
| ----- | ------- | ------ | ------ |
| `scripts/ci/verify_core_liveview_runtime_free.sh` | `bash scripts/ci/verify_core_liveview_runtime_free.sh` | exit 0, "verify_core_liveview_runtime_free: OK" | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| ENT-06 | 124-01, 124-02, 124-03, 124-06 | Gate a controller route with a Plug guard (`require_plan`/`require_feature`) halting with configurable fail response (redirect/403) when not entitled. | ✓ SATISFIED | Plug + router macros + content-neg deny + boot-validated `on_deny` (SC#1, SC#4 evidence above). Marked `[x]` in REQUIREMENTS.md, no orphans. |
| ENT-07 | 124-01, 124-02, 124-04, 124-05, 124-06 | Gate a host LiveView with an `on_mount` guard via conditional compilation; core stays runtime-LiveView-free; host-configurable adapter-thin billable resolution, no required Sigra/Lockspire. | ✓ SATISFIED | Cond-compiled on_mount + merge gate + shared resolution + doc reconciliation (SC#2, SC#3, SC#4 evidence above). Marked `[x]` in REQUIREMENTS.md, no orphans. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| — | — | No TBD/FIXME/XXX in any phase-modified source | — | None |
| — | — | No TODO/HACK/PLACEHOLDER/not-implemented stubs | — | None |
| `accrue/lib/accrue/entitlements/guard.ex` | 180, config.ex:1028 | WR-03 (open): `{status, body}` deny accepts out-of-HTTP-range integers; misconfig → per-request 500 on deny path (does NOT fail open) | ⚠️ Warning | Robustness only. Documented open in 124-REVIEW.md; does not break SC#1 default/redirect/valid-status paths. |
| `accrue/lib/accrue/entitlements/guard.ex` | 224-227 | WR-02 (open): non-`%Plug.Conn{}` plug fallback re-resolves (resolve-once not guaranteed for undocumented non-conn containers) | ⚠️ Warning | Maintainability only. Resolve-once holds for the documented `%Plug.Conn{}` path (SC#4 satisfied). Documented open in 124-REVIEW.md. |

### Human Verification Required

None. This phase delivers library guard code (Plug `call/2`, LiveView `on_mount/4`, shared decision engine, CI gate) with fully deterministic, unit/property-tested behavior. No visual rendering of dynamic data, no real-time UI, and no external-service integration is introduced. The redirect/flash/halt/telemetry/content-negotiation behaviors are all asserted programmatically (105 tests + 3 properties, all green) and the merge gate was executed in this verifier's own process (exit 0). No `<human-check>` blocks were deferred in any plan.

### Gaps Summary

No gaps. All four ROADMAP success criteria are observably true in the codebase:

1. **SC#1 (Plug guard)** — `Accrue.Plug.RequireEntitlement` + `require_feature`/`require_plan` router macros gate routes with content-negotiated opaque 403 / configurable redirect / custom status, boot-validated `on_deny`.
2. **SC#2 (LiveView guard)** — `Accrue.Live.Entitlements.on_mount/4` gates host LiveViews with host-configurable, adapter-thin billable resolution (no Sigra/Lockspire coupling).
3. **SC#3 (cond-compile + merge gate)** — guard is cond-compiled (Sigra 4-pattern); the merge-blocking static gate runs clean (exit 0) and is wired into ci.yml; independent grep confirms zero socket-runtime refs in always-compiled core outside `lib/accrue/live/`.
4. **SC#4 (resolve-once + fail-closed)** — resolve-once verified on BOTH surfaces (plug stash + the CR-01 live-stash fix in commit aecd640, now asserted by value at both Guard and surface level); cross-surface fail-closed property proves nil/garbage/raising/exception/no-sub/unmapped all DENY, with the sole allow pinned to an affirmative resolved match; `surface:` reaches the inherited Phase 123 `:check` span.

The BLOCKER from code review (CR-01: LiveView resolve-once stashed nil) is confirmed FIXED in commit aecd640 and locked by two tests (Guard-level `:live` resolve-once asserting the container assign value, and the live `on_mount` test asserting `socket2.assigns.accrue_billable == billable`). Two robustness WARNINGs (WR-02, WR-03) remain open as explicitly-documented follow-ups in 124-REVIEW.md; neither fails open nor undermines any success criterion.

Pre-existing baseline failures (6 `Accrue.Docs.PackageDocsVerifierTest` + 1 flaky `Accrue.PdfTest`) were excluded from the phase-relevant suite run per the verification notes and are not phase 124 regressions.

---

_Verified: 2026-05-23T15:05:00Z_
_Verifier: Claude (gsd-verifier)_
