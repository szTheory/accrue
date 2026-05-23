---
phase: 124-enforcement-surfaces-plug-liveview-guards
plan: 06
subsystem: payments
tags: [entitlements, guards, ci, merge-gate, fail-closed, property-test, liveview-runtime-free]

# Dependency graph
requires:
  - phase: 124-enforcement-surfaces-plug-liveview-guards
    plan: 02
    provides: "Accrue.Entitlements.Guard.check(:plug | :live, container, opts) -> {:allow, container} | {:deny, deny_form, ctx} — the always-compiled LiveView-runtime-free decision engine the cross-surface fail-closed property drives"
  - phase: 124-enforcement-surfaces-plug-liveview-guards
    plan: 04
    provides: "accrue/lib/accrue/live/entitlements.ex — the cond-compiled on_mount/4 surface (now contains `def on_mount`) that the static gate's /accrue/live/ exclusion is exercised against"
  - phase: 124-enforcement-surfaces-plug-liveview-guards
    plan: 03
    provides: "Accrue.Plug.RequireEntitlement (the :plug surface the property's deny path also covers via Guard.check(:plug, …))"
provides:
  - "scripts/ci/verify_core_liveview_runtime_free.sh — the static merge gate (D-05): fails the build if any always-compiled core module references the LiveView socket runtime (import/alias Phoenix.LiveView, Phoenix.LiveView.Socket, Phoenix.Socket, def on_mount), with the ^[^#]* doc-comment allowlist and the /accrue/live/ cond-compiled-guard exclusion"
  - "the ci.yml merge-blocking wiring of the gate in the docs-contracts-shift-left job"
  - "accrue/test/property/guard_fail_closed_property_test.exs — the cross-surface fail-closed property (SC#4): nil/garbage/raising/no-active-sub all DENY on BOTH :plug and :live; allow reachable only via an affirmative resolved match"
affects: [125 (resolver behaviour + drift gate inherit the now-enforced runtime-LiveView-free invariant), 126 (guides/entitlements.md documents the merge gate + fail-closed guarantee)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Static merge gate as a repo-root scripts/ci/ grep contract cloned from verify_processor_support_matrix.sh: ^[^#]* anchor allowlists doc comments by construction (matched alternative must precede any # on the line); grep -v '/accrue/live/' exempts the single sanctioned cond-compiled LiveView file"
    - "Cross-surface fail-closed property drives the SHARED engine (Guard.check/3) on both :plug (Plug.Test conn) and :live (bare %{assigns: %{}} map) with the same garbage input carried in via a billable: fn — one property proves both surfaces fail closed, since both delegate to the same engine seam"
    - "Affirmative-match leg pins {:allow, _} to a single real path (active sub on a mapped plan whose feature set contains the gated feature) + a same-billable per-feature deny leg, so a fail-OPEN regression on any untested input shape is caught (allow is per-feature, never blanket)"

key-files:
  created:
    - "scripts/ci/verify_core_liveview_runtime_free.sh - the D-05 static merge gate (repo root, executable, scans accrue/lib for real LiveView socket-runtime refs; passes clean, fails on a planted real ref outside /accrue/live/)"
    - "accrue/test/property/guard_fail_closed_property_test.exs - Accrue.Property.GuardFailClosedPropertyTest: 1 property + 6 tests proving cross-surface fail-closed through Accrue.Entitlements.Guard.check/3 on :plug and :live"
  modified:
    - ".github/workflows/ci.yml - added the 'Core stays LiveView-runtime-free (ENT-07 D-05)' step to the merge-blocking docs-contracts-shift-left job, after the Processor support matrix contract step"

key-decisions:
  - "The gate lives at REPO-ROOT scripts/ci/ (NOT accrue/scripts/ci/ which does not exist) with lib=${repo_root}/accrue/lib — per the load-bearing PATTERNS.md path correction; all sibling verify_* scripts live at repo root and ci.yml invokes them with cwd = repo root"
  - "The gate is a static grep contract (D-05), NOT a without-LiveView compile-matrix cell — D-05 explicitly rejects the compile-cell approach; the gate scans always-compiled core source (comments included) and relies on the ^[^#]* + /accrue/live/ allowlists rather than a build permutation"
  - "The property aliases Accrue.Entitlements.Guard and calls Guard.check(:plug, …) / Guard.check(:live, …) — the key_links pattern (Accrue\\.Entitlements\\.Guard) matches via the alias; both surfaces are driven through the one shared engine, which is the substantive SC#4 requirement"
  - "Garbage inputs are carried in as the RESOLVED billable via a billable: fn (fn _ -> input end) rather than as the container itself — this exercises the engine's resolve-then-delegate path on garbage of every shape (nil/term/integer/string/atom) identically on both surfaces"

patterns-established:
  - "scripts/ci/verify_core_liveview_runtime_free.sh is the canonical home of the runtime-LiveView-free invariant; /accrue/live/entitlements.ex is the single sanctioned exception, exercised by the gate's path exclusion"

requirements-completed: [ENT-06, ENT-07]

# Metrics
duration: 2min
completed: 2026-05-23
---

# Phase 124 Plan 06: Static Merge Gate + Cross-Surface Fail-Closed Property Summary

**Locked the phase's two hardest invariants behind automated, merge-blocking enforcement: (1) `scripts/ci/verify_core_liveview_runtime_free.sh` — the D-05 static gate that fails the build if any always-compiled core module references the LiveView socket runtime, wired as a merge-blocking step in the already-required `docs-contracts-shift-left` job (passes clean today, exits 1 with the offending line on a planted real ref outside `/accrue/live/`, allowlisting doc comments via `^[^#]*` and the cond-compiled guard via `/accrue/live/`); and (2) `guard_fail_closed_property_test.exs` — the SC#4 cross-surface property proving that nil/garbage/raising/no-active-sub inputs all DENY through the shared `Accrue.Entitlements.Guard.check/3` on BOTH `:plug` and `:live`, with `{:allow, _}` pinned to the single affirmative-resolved-match path.**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-05-23T12:42:22Z
- **Completed:** 2026-05-23T12:45:02Z
- **Tasks:** 3
- **Files created:** 2 (1 CI script, 1 property test); 1 modified (ci.yml)

## Accomplishments

- **Static merge gate (Task 1, D-05):** `scripts/ci/verify_core_liveview_runtime_free.sh` at repo root, executable, scans `${repo_root}/accrue/lib` with `grep -rnE '^[^#]*((import|alias)[[:space:]]+Phoenix\.LiveView|Phoenix\.LiveView\.Socket|Phoenix\.Socket|def[[:space:]]+on_mount)' --include='*.ex' | grep -v '/accrue/live/'`. Passes clean on the current tree (`verify_core_liveview_runtime_free: OK`, exit 0). **Negative proof:** planting `import Phoenix.LiveView` into `accrue/lib/accrue.ex` (a non-`/accrue/live/` core file) made the gate exit 1 with `.../accrue.ex:65:  import Phoenix.LiveView` on stderr; the scratch line was reverted byte-for-byte (no working-tree diff). The gate does NOT flag `oban/middleware.ex` (doc comment, `^[^#]*` allowlisted), `live/entitlements.ex` (path-excluded), or `entitlements/guard.ex` (no socket-runtime refs).
- **Merge-blocking CI wiring (Task 2):** added `- name: Core stays LiveView-runtime-free (ENT-07 D-05) / run: bash scripts/ci/verify_core_liveview_runtime_free.sh` to the `docs-contracts-shift-left` job (merge-blocking per ci.yml header lines 6-8), right after the `Processor support matrix contract` step. `python3 -c "yaml.safe_load(...)"` confirms valid YAML; it is NOT a new job and NOT a compile-matrix cell (D-05 rejects that).
- **Cross-surface fail-closed property (Task 3, SC#4):** `Accrue.Property.GuardFailClosedPropertyTest` (1 property + 6 tests, 0 failures) drives `Accrue.Entitlements.Guard.check/3` on BOTH `:plug` (a `Plug.Test` conn) and `:live` (a bare `%{assigns: %{}}` map) for: all garbage inputs (`nil | term | integer | string | atom` carried as the resolved billable via a `billable:` fn) → `{:deny, _, _}` never `{:allow, _}`; a raising `billable:` fn (feature AND plan targets) → `{:deny, _, _}`; a billable with no customer / an unmapped price_id → `{:deny, _, _}`; and the affirmative-match leg (active sub on mapped `:p1` whose features contain `:reports`) → `{:allow, _}` on both surfaces, with a same-billable `:api` (outside `:p1`) deny leg proving allow is per-feature, not blanket. `async: false` (mutates `:accrue, :entitlements`).

## Task Commits

Each task was committed atomically:

1. **Task 1: verify_core_liveview_runtime_free.sh static merge gate** — `3fcd7d3` (feat)
2. **Task 2: wire the gate into ci.yml as a merge-blocking step** — `4644d7b` (chore)
3. **Task 3: guard_fail_closed_property_test.exs — cross-surface fail-closed property (SC#4)** — `952485a` (test, TDD)

## Files Created

- `scripts/ci/verify_core_liveview_runtime_free.sh` — repo-root executable static gate cloning `verify_processor_support_matrix.sh`'s header / `repo_root` resolution / fail-to-stderr+`exit 1` / `echo "...: OK"` shape. Header comment documents D-05, the `^[^#]*` doc-comment allowlist, and the `/accrue/live/` cond-compiled-guard exclusion.
- `accrue/test/property/guard_fail_closed_property_test.exs` — `Accrue.Property.GuardFailClosedPropertyTest` (`use Accrue.BillingCase, async: false` + `use ExUnitProperties`): clones the entitlements fail-closed property scaffolding (`garbage_gen/0`, env save/restore `on_exit`, `TestUser`, `@plans`), adapts `assert_fail_closed/1` to drive the GUARD on both surfaces, and adds the raising-fn, no-active-sub, and affirmative-match legs.

## Files Modified

- `.github/workflows/ci.yml` — one step added to `docs-contracts-shift-left`.

## Decisions Made

- **Repo-root gate path (not under `accrue/`).** Per the load-bearing PATTERNS.md path correction, `accrue/scripts/ci/` does not exist; all sibling `verify_*` scripts live at repo-root `scripts/ci/` and ci.yml runs them with cwd = repo root, so the gate goes there with `lib="${repo_root}/accrue/lib"`.
- **Static grep, not a compile cell.** D-05 explicitly rejects a without-LiveView compile-matrix cell; the gate is a low-ceremony static contract over always-compiled source (comments included), relying on the `^[^#]*` + `/accrue/live/` allowlists.
- **Garbage carried as the resolved billable via `billable:` fn.** `fn _ -> input end` exercises the engine's resolve-then-delegate path on garbage of every shape on both surfaces, which is the truest analog of a real resolver returning a non-billable term.
- **`alias Accrue.Entitlements.Guard` + `Guard.check(:plug/:live, …)`.** The `key_links` pattern (`Accrue\.Entitlements\.Guard`) matches via the alias; the substantive SC#4 requirement (both surfaces driven through the one shared engine) is met.

## Deviations from Plan

None — plan executed exactly as written. The static gate, the ci.yml wiring, and the cross-surface fail-closed property shipped per the `<action>` blocks; no auto-fixes (Rules 1-3) and no architectural decisions (Rule 4) were needed. The Guard engine the property exercises already existed (Plan 02 GREEN), so the TDD task's test landed GREEN on first run against already-correct behavior — this is a verification gate for a Wave 2 deliverable, not new behavior, so the RED-passes-unexpectedly fail-fast rule does not apply (the engine is intentionally pre-built and correct).

## Threat Model Coverage

All three `mitigate` dispositions are verified; the two `accept` dispositions hold:

- **T-124-17 (Tampering / merge-gate evasion or advisory-only gate):** the gate is a merge-BLOCKING step in the already-required `docs-contracts-shift-left` job (not advisory); the negative-proof in Task 1 confirms it exits 1 on a real reference. ✅
- **T-124-18 (EoP / fail-OPEN on an untested input shape):** the property exhausts garbage/nil/raising/no-active-sub inputs across BOTH surfaces asserting `{:deny, _, _}`; the affirmative-match leg + same-billable per-feature deny leg pin `:allow` to a single real path. ✅
- **T-124-19 (Info Disclosure / gate output leaking source structure):** accept — the gate prints only `file:line:source` to CI stderr (public source, no secrets/PII). ✅ (held)
- **T-124-SC (Tampering / package installs):** accept — zero external packages installed this phase; no Package Legitimacy Gate applies. ✅ (held)

## Issues Encountered

None from this plan's changes. The full-suite regression (`cd accrue && mix test`) shows `49 properties, 1416 tests, 7 failures (11 excluded)`; all 7 are the documented pre-existing baseline failures — 6 `Accrue.Docs.PackageDocsVerifierTest` (the PROJECT.md "gateway subscription core" needle issue since 2026-05-08) and 1 flaky `Accrue.Billing.PdfTest` (Rendro/UnicodeData `script_from_codepoint/1` undefined). None are related to this plan's CI script, ci.yml step, or property test; this plan's new `1 property + 6 tests` are all green (and warnings-clean + format-clean). Out of scope per the deviation scope boundary, already tracked in project memory — not re-logged.

## User Setup Required

None — no external service configuration required. The gate runs in CI on every PR via the existing `docs-contracts-shift-left` job.

## Next Phase Readiness

- **Phase 125 (resolver behaviour + drift gate):** the runtime-LiveView-free invariant is now machine-enforced on every PR, so new core modules inherit it for free.
- **Phase 126 (`guides/entitlements.md`):** the merge gate and the cross-surface fail-closed guarantee are now concrete, citable artifacts (`scripts/ci/verify_core_liveview_runtime_free.sh`, `guard_fail_closed_property_test.exs`) ready to document.
- No blockers.

## Self-Check: PASSED

- `scripts/ci/verify_core_liveview_runtime_free.sh` — FOUND (executable; passes clean `exit 0`; negative-proof exits 1)
- `accrue/test/property/guard_fail_closed_property_test.exs` — FOUND (1 property + 6 tests green; both `Guard.check(:plug` and `Guard.check(:live` present; `async: false`; raising-fn + affirmative-match legs present)
- `.github/workflows/ci.yml` — FOUND (gate step in `docs-contracts-shift-left`; valid YAML)
- Commit `3fcd7d3` — FOUND
- Commit `4644d7b` — FOUND
- Commit `952485a` — FOUND

---
*Phase: 124-enforcement-surfaces-plug-liveview-guards*
*Completed: 2026-05-23*
