---
phase: 124
slug: enforcement-surfaces-plug-liveview-guards
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-23
---

# Phase 124 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `124-RESEARCH.md` §"Validation Architecture".

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir stdlib) + `stream_data ~> 1.3` (property tests) |
| **Config file** | `accrue/test/test_helper.exs` (existing) |
| **Quick run command** | `cd accrue && mix test test/accrue/<area>_test.exs` (single file, <10s) |
| **Full suite command** | `cd accrue && mix test` |
| **Static merge gate** | `bash scripts/ci/verify_core_liveview_runtime_free.sh` (exit 0 = no LiveView runtime coupling in always-compiled core) |
| **Plug test helper** | `Plug.Test` (`conn/3`, `put_req_header/3`) — ships with `:plug` |
| **LiveView test helper** | `on_mount/4` is a plain function — unit-call with a stub `%Phoenix.LiveView.Socket{assigns: …}` over a full live mount for speed |
| **Estimated runtime** | quick <10s; full core suite ~1–3 min |

---

## Sampling Rate

- **After every task commit:** Run the single relevant test file (`mix test test/accrue/<area>_test.exs`)
- **After every plan wave:** Run `cd accrue && mix test` (full core suite) + `bash scripts/ci/verify_core_liveview_runtime_free.sh`
- **Before `/gsd:verify-work`:** Full suite green + static gate green + `mix credo --strict` + `mix compile --warnings-as-errors`
- **Max feedback latency:** ~10s (single file)

---

## Per-Task Verification Map

> Populated as plans are written (task IDs don't exist until planning completes). Each plan task
> must carry an `<automated>` verify command or a Wave 0 dependency. SC→test mapping below drives it.

| SC | Behavior | Test Type | Automated Command |
|----|----------|-----------|-------------------|
| SC#1 | Plug denies (content-neg 403; JSON vs text; opaque body; `status:`/`on_deny:` override); allows when entitled | unit (`Plug.Test`) | `mix test test/accrue/plug/require_entitlement_test.exs` |
| SC#1 | `require_feature`/`require_plan` macros expand to the plug | unit | `mix test test/accrue/router_test.exs` |
| SC#2 | Host-configurable billable resolution on BOTH surfaces (per-guard fn, config global, default `current_scope.user → current_user → nil`) | unit | `mix test test/accrue/entitlements/guard_test.exs` |
| SC#2 | LiveView `on_mount` `{:require_feature,…}`/`{:require_plan,…}` → `{:cont,…}`/`{:halt,…}` with deny→redirect degradation | unit (stub socket) | `mix test test/accrue/live/entitlements_test.exs` |
| SC#3 | Cond-compile 4-pattern present (source assertion, mirrors `sigra_test.exs`) | source-assertion | `mix test test/accrue/live/entitlements_test.exs` |
| SC#3 | No always-compiled core module references the LiveView socket runtime (doc-comment allowlist) | CI-gate (grep) | `bash scripts/ci/verify_core_liveview_runtime_free.sh` |
| SC#3 | (optional) core boots without `:phoenix_live_view` in `extra_applications` (`== [:logger]`) | unit | `mix test test/accrue/application_test.exs` |
| SC#4 | Resolve-once: billable resolved exactly once per request/mount; stash is billable-only (not the boolean) | unit (resolver call count == 1) | `mix test test/accrue/entitlements/guard_test.exs` |
| SC#4 | Fail-closed: `nil` billable, raising resolver, exception → DENY (both surfaces) | property (`stream_data`) | `mix test test/property/guard_fail_closed_property_test.exs` |
| SC#4 | `surface: :plug \| :live` reaches `[:accrue, :entitlements, :check]` telemetry metadata | unit (`:telemetry` attach) | `mix test test/accrue/entitlements/guard_telemetry_test.exs` |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/accrue/plug/require_entitlement_test.exs` — SC#1 (deny/allow/content-neg/override)
- [ ] `test/accrue/live/entitlements_test.exs` — SC#2/#3 (on_mount + cond-compile source assertion)
- [ ] `test/accrue/entitlements/guard_test.exs` — SC#2/#4 (billable resolution + resolve-once)
- [ ] `test/accrue/entitlements/guard_telemetry_test.exs` — SC#4 (`surface:` dimension)
- [ ] `test/property/guard_fail_closed_property_test.exs` — SC#4 (fail-closed property; clone `test/property/entitlements_fail_closed_property_test.exs`)
- [ ] `scripts/ci/verify_core_liveview_runtime_free.sh` + `.github/workflows/ci.yml` wiring — SC#3 (static gate)
- [ ] (extend) `test/accrue/router_test.exs` if it exists, else add macro-expansion test
- [ ] No framework install needed — ExUnit + `stream_data` already present.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| — | — | — | — |

*All phase behaviors have automated verification. The D-06 doc/wording reconciliation (CLAUDE.md / ROADMAP SC#3 / REQUIREMENTS ENT-07 / PITFALLS.md / `oban/middleware.ex` comment / `mix.exs` comment) is verified via source-assertion greps, not manual review.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s (single file)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
