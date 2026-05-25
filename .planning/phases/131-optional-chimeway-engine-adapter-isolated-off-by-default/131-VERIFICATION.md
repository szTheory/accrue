---
phase: 131-optional-chimeway-engine-adapter-isolated-off-by-default
verified: 2026-05-25T18:45:00Z
status: passed
score: 9/9 must-haves verified
overrides_applied: 0
re_verification: null
gaps: []
deferred: []
human_verification: []
---

# Phase 131: Optional Chimeway Engine Adapter Verification Report

**Phase Goal:** A host can optionally upgrade the dunning engine to Chimeway's orchestration engine without changing any call site, while core `accrue` never requires Chimeway and the default built-in campaign remains the always-on path.
**Verified:** 2026-05-25T18:45:00Z
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `Accrue.Dunning.Engine` behaviour exists with exactly `start_campaign/3` and `cancel_campaign/3` callbacks | VERIFIED | `engine.ex` defines both `@callback` with arity 3; `behaviour_info(:callbacks)` returns `[start_campaign: 3, cancel_campaign: 3]`; `engine_test.exs` (7/7 tests pass) asserts both arities |
| 2 | `Accrue.Integrations.Chimeway` conditionally compiles — loaded-or-`:nofile`, never crashes with Chimeway absent | VERIFIED | `chimeway.ex` wraps the entire `defmodule` in `if Code.ensure_loaded?(Chimeway) do ... end`; `chimeway_test.exs` passes 2/2 with `:nofile` branch exercised; compile with Chimeway absent exits 0 |
| 3 | Static isolation gate (`verify_dunning_chimeway_isolation.sh`) prevents always-on dunning files from referencing Chimeway | VERIFIED | Gate script exists at `scripts/ci/verify_dunning_chimeway_isolation.sh`, is executable, exits 0 against HEAD; scans only `billing/dunning.ex`, `workers/dunning_step.ex`, `dunning/campaign.ex` (all have 0 Chimeway refs); wired into CI at line 55-56 of `ci.yml` |
| 4 | `guides/dunning.md` has an opt-in "Upgrading to Chimeway orchestration" section | VERIFIED | `dunning.md` contains `## Upgrading to Chimeway orchestration` heading at line 128; contains all required needle content; 0 `stop_conditions` occurrences; 0 `Chimeway.Workflow` occurrences |
| 5 | `Config.dunning_engine/0` exists and returns `Accrue.Dunning.Engine.Oban` by default | VERIFIED | `config.ex` line 893: `def dunning_engine do Keyword.get(dunning(), :engine, Accrue.Dunning.Engine.Oban) end`; `:dunning` schema adds `engine: Accrue.Dunning.Engine.Oban` to both `default:` and `keys:` |
| 6 | `default_handler.ex` dispatches start and cancel through `Config.dunning_engine()` | VERIFIED | Line 1188: `Accrue.Config.dunning_engine().start_campaign(sub, now_usec, opts)`; line 914: `Accrue.Config.dunning_engine().cancel_campaign(sub, iso_anchor, [])`; process-dict stash at line 877 carries `{updated, iso_anchor}` (full struct); `enqueue_day_zero_step` and `cancel_dunning_steps` are fully removed (grep returns 0) |
| 7 | All tests pass | VERIFIED | `mix test --seed 0` → 1587 tests, 57 properties, 0 failures (11 excluded); dunning suite 16/16; engine + chimeway tests 7/7; PackageDocsVerifierTest 8/8 |
| 8 | No Chimeway references in always-on dunning path | VERIFIED | `billing/dunning.ex`: 0 Chimeway refs; `workers/dunning_step.ex`: 0 Chimeway refs; `dunning/campaign.ex`: 0 Chimeway refs; isolation gate exits 0 |
| 9 | `verify_package_docs.sh` contains Chimeway needles; `PackageDocsVerifierTest` seeds `dunning.md` | VERIFIED | 3 `require_fixed` lines targeting `dunning.md` at lines 138-140 of `verify_package_docs.sh`; `copy_fixture!("accrue/guides/dunning.md", tmp_dir)` at line 262 of `package_docs_verifier_test.exs`; `verify_package_docs.sh` exits 0; PackageDocsVerifierTest 8/8 pass |

**Score:** 9/9 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `accrue/lib/accrue/dunning/engine.ex` | `Accrue.Dunning.Engine` behaviour with `start_campaign/3` + `cancel_campaign/3` | VERIFIED | 46 lines; exactly 2 arity-3 `@callback` declarations; no facade functions; moduledoc describes the seam contract |
| `accrue/lib/accrue/dunning/engine/oban.ex` | `@behaviour Accrue.Dunning.Engine` with both callbacks implemented | VERIFIED | 103 lines; `@behaviour` declared; `@impl` on both; `start_campaign/3` delegates to `DunningStep.enqueue_step`; `cancel_campaign/3` has `rescue -> :ok` contract; zero Chimeway references |
| `accrue/lib/accrue/integrations/chimeway.ex` | Conditionally-compiled adapter with `Code.ensure_loaded?(Chimeway)` guard | VERIFIED | 159 lines; outer `if Code.ensure_loaded?(Chimeway)` guard; `@behaviour Accrue.Dunning.Engine`; `@compile {:no_warn_undefined, [Chimeway, Chimeway.Signal]}`; bundled `DunningNotifier` with 6 callbacks; 0 `stop_conditions`; 0 `def workflow` |
| `accrue/lib/accrue/config.ex` | `:engine` key in `:dunning` schema + `dunning_engine/0` accessor | VERIFIED | `engine:` key at line 291 with `type: :atom`, `default: Accrue.Dunning.Engine.Oban`, doc containing all 3 required substrings; `def dunning_engine` at line 893 |
| `accrue/lib/accrue/webhook/default_handler.ex` | Both campaign seams dispatched through `Config.dunning_engine()` | VERIFIED | `start_campaign` dispatch at line 1188; `cancel_campaign` dispatch at line 914; stash at line 877 holds full `%Subscription{}` struct; `enqueue_day_zero_step` and `cancel_dunning_steps` removed (grep count 0) |
| `scripts/ci/verify_dunning_chimeway_isolation.sh` | Isolation gate scanning 3 always-on files, exits 1 on real Chimeway ref | VERIFIED | 66 lines; `set -euo pipefail`; scans exact 3 file paths; `^[^#]*` anchor to strip comment lines; `|| true` + empty-check pattern; exits 0 against HEAD |
| `.github/workflows/ci.yml` | Named CI step running the isolation gate | VERIFIED | Lines 55-56: `name: Dunning core stays Chimeway-free (DUN-03 D-04)` + `run: bash scripts/ci/verify_dunning_chimeway_isolation.sh` |
| `accrue/guides/dunning.md` | `## Upgrading to Chimeway orchestration` section with all required content | VERIFIED | Section exists at line 128; contains `Accrue.Dunning.Engine`, `Accrue.Integrations.Chimeway`, `dunning: [engine:`, `{:chimeway, "~> 1.0"}`, `Chimeway.trigger/3`, `Chimeway.Signal.track/4`; 0 `stop_conditions`; 0 `Chimeway.Workflow` |
| `.planning/processor-support-matrix.md` | `dunning.engine` row with `built-in (Oban)` x3 + Chimeway optional note | VERIFIED | Row at line 62: `\| dunning.engine \| built-in (Oban) \| built-in (Oban) \| built-in (Oban) \| optional adapter (Chimeway v1.0.0) \|`; prose paragraph at line 77 |
| `scripts/ci/verify_package_docs.sh` | 3 `require_fixed` needles targeting `dunning.md` | VERIFIED | Lines 138-140: `Accrue.Dunning.Engine`, `Accrue.Integrations.Chimeway`, `dunning: [engine:`; `bash verify_package_docs.sh` exits 0 |
| `accrue/test/accrue/docs/package_docs_verifier_test.exs` | `dunning.md` seeded in `seed_tmp_dir!` | VERIFIED | Line 262: `copy_fixture!("accrue/guides/dunning.md", tmp_dir)`; 8/8 tests pass including all 6 negative tests |
| `accrue/mix.exs` | `{:chimeway, "~> 1.0", optional: true}` dep | VERIFIED | Line 100: `{:chimeway, "~> 1.0", optional: true}` in optional-deps block |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `default_handler.ex` | `Accrue.Config.dunning_engine()` | `start_campaign` dispatch | WIRED | Line 1188: `Accrue.Config.dunning_engine().start_campaign(sub, now_usec, opts)` |
| `default_handler.ex` | `Accrue.Config.dunning_engine()` | `cancel_campaign` dispatch | WIRED | Line 914: `Accrue.Config.dunning_engine().cancel_campaign(sub, iso_anchor, [])` |
| `config.ex` | `Accrue.Dunning.Engine.Oban` | default `:engine` key | WIRED | Lines 267, 293: `engine: Accrue.Dunning.Engine.Oban` in both `default:` and `keys:` |
| `engine/oban.ex` | `Accrue.Workers.DunningStep` | `enqueue_step` delegation | WIRED | Line 56: `DunningStep.enqueue_step(sub.id, step_key, anchor, %{...})` |
| `integrations/chimeway.ex` | `Chimeway.trigger/3` | `start_campaign` | WIRED | Line 81: `Chimeway.trigger(__MODULE__.DunningNotifier, ..., idempotency_key: ..., tenant_id: sub.customer_id)` |
| `integrations/chimeway.ex` | `Chimeway.Signal.track/4` | `cancel_campaign` | WIRED | Line 101: `Chimeway.Signal.track(sub.customer_id, "accrue.dunning", "payment_recovered", %{...})` |
| `ci.yml` | `verify_dunning_chimeway_isolation.sh` | `run:` step | WIRED | Lines 55-56 of `ci.yml` |
| `verify_package_docs.sh` | `accrue/guides/dunning.md` | `require_fixed` needles | WIRED | Lines 138-140: 3 require_fixed calls against dunning.md |
| `package_docs_verifier_test.exs` | `accrue/guides/dunning.md` | `copy_fixture!` | WIRED | Line 262: `copy_fixture!("accrue/guides/dunning.md", tmp_dir)` |

---

### Data-Flow Trace (Level 4)

Not applicable — this phase delivers a behaviour seam and conditional adapter, not a user-visible data-rendering component. The data flow through the engine dispatch is verified at Level 3 (key link wiring) and confirmed by the full test suite (1587 tests, 0 failures).

---

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Isolation gate passes against HEAD | `bash scripts/ci/verify_dunning_chimeway_isolation.sh` | `verify_dunning_chimeway_isolation: OK` (exit 0) | PASS |
| `verify_package_docs.sh` passes with dunning.md needles | `bash scripts/ci/verify_package_docs.sh` | exits 0, "package docs verified for accrue 1.1.2..." | PASS |
| Engine + Chimeway tests pass | `cd accrue && mix test test/accrue/dunning/engine_test.exs test/accrue/integrations/chimeway_test.exs --seed 0` | 7 tests, 0 failures | PASS |
| Full dunning suite passes | `cd accrue && mix test test/accrue/dunning/ --seed 0` | 16 tests, 0 failures | PASS |
| PackageDocsVerifierTest passes (incl. 6 negative tests) | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs --seed 0` | 8 tests, 0 failures | PASS |
| Full test suite passes | `cd accrue && mix test --seed 0` | 1587 tests, 57 properties, 0 failures | PASS |

---

### Probe Execution

No probes declared in plans. The isolation gate (`verify_dunning_chimeway_isolation.sh`) was run directly and passed.

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| DUN-03 SC#1 | Plans 01, 02, 03 | `Accrue.Dunning.Engine` behaviour with `start_campaign/3` + `cancel_campaign/3`; call sites unchanged | SATISFIED | `engine.ex` declares both callbacks; `engine/oban.ex` implements both; `default_handler.ex` dispatches through `Config.dunning_engine()` |
| DUN-03 SC#2 | Plans 01, 04 | `Accrue.Integrations.Chimeway` conditionally compiled; loaded-or-`:nofile`, never crashes absent | SATISFIED | `if Code.ensure_loaded?(Chimeway)` guard; `chimeway_test.exs` 2/2 pass; `mix compile --warnings-as-errors` exits 0 with Chimeway absent |
| DUN-03 SC#3 | Plans 01, 05 | Static isolation gate prevents always-on dunning files from referencing Chimeway | SATISFIED | Gate script exists, passes against HEAD, wired in CI; `billing/dunning.ex`, `workers/dunning_step.ex`, `dunning/campaign.ex` each have 0 Chimeway refs |
| DUN-03 SC#4 | Plan 06 | Chimeway adapter documented as opt-in upgrade targeting published 1.0.0 API | SATISFIED | `dunning.md` has full upgrade section; references `Chimeway.trigger/3` + `Chimeway.Signal.track/4`; 0 `stop_conditions`; 0 `Chimeway.Workflow` |

---

### Anti-Patterns Found

No anti-patterns found in any files modified by this phase. Specific checks:

- Zero `TBD`, `FIXME`, or `XXX` markers in `engine.ex`, `engine/oban.ex`, `chimeway.ex`, `default_handler.ex`, `config.ex`, `verify_dunning_chimeway_isolation.sh`, `dunning.md`
- Zero `stop_conditions` references in `chimeway.ex`, `chimeway_test.exs`, `dunning.md`
- Zero `def workflow` in `chimeway.ex` (intentionally omitted per v1.40 email-only path)
- No stub returns (`return null`, `return {}`, `return []`, placeholder text) in implementation files
- `enqueue_day_zero_step` and `cancel_dunning_steps` fully extracted from `default_handler.ex` (grep count 0) — no dead code

---

### Human Verification Required

None — all success criteria are programmatically verifiable. The phase delivers behaviour contracts, conditional compilation, a shell gate, and documentation — no visual UI, real-time behavior, or external service integration that requires human eyes.

---

## Gaps Summary

No gaps. All 4 ROADMAP success criteria and all 9 must-have truths are verified in the codebase. The test suite is green across the full suite (1587 tests, 0 failures). The isolation gate passes. The docs contain all required content with no forbidden content.

---

_Verified: 2026-05-25T18:45:00Z_
_Verifier: Claude (gsd-verifier)_
