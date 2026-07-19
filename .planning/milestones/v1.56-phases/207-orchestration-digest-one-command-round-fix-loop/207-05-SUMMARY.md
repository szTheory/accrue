---
phase: 207-orchestration-digest-one-command-round-fix-loop
plan: 05
subsystem: accrue_admin / ui-ratchet orchestration
tags: [mix-task, orchestration, ORCH-01, ratchet, tdd]
requires:
  - "207-01 phase-ratchet-ledger.mjs (.round-next / .round-status markers, --next-round / --seal-round)"
  - "207-02 baseline-manifest.js SLICES map (surface SSOT)"
  - "207-04 ratchet-digest.mjs (round-NN/digest.html assembly)"
provides:
  - "mix accrue_admin.ui.round — one-command ORCH-01 measurement pipeline"
  - "swappable Runner behaviour (run/3 + capture/3) for the ui.round task"
affects:
  - "accrue_admin/package.json (ui:round convenience script)"
tech-stack:
  added: []
  patterns:
    - "twins accrue_admin.assets.build's Runner/ShellRunner/run_step!/Application.get_env idiom"
    - "JS SLICES read via captured node -e — no hand-mirrored Elixir slice constant"
key-files:
  created:
    - accrue_admin/lib/mix/tasks/accrue_admin.ui.round.ex
    - accrue_admin/test/mix/tasks/accrue_admin_ui_round_test.exs
  modified:
    - accrue_admin/package.json
decisions:
  - "Runner gains a capture/3 callback (alongside run/3) so load_slices! consumes stdout while the 7 pipeline steps keep the exact assets.build run/3 shape"
  - "Bare --slice (parse-invalid under strict :string) is detected via argv membership and defaults to \"foundation\""
metrics:
  duration: 8m
  completed: 2026-07-05
status: complete
---

# Phase 207 Plan 05: One-command `mix accrue_admin.ui.round` Summary

Implemented `mix accrue_admin.ui.round [--slice NAME | --surface a,b,c]` — the ORCH-01 one-command measurement pipeline — as a thin, Runner-swappable Elixir orchestrator that sequences the seven ratchet steps, reads the round number and convergence status from 207-01's marker files, always renders the digest, and raises only on the 6-round cap-reached escalation.

## What Was Built

- **`Mix.Tasks.AccrueAdmin.Ui.Round`** twinning `accrue_admin.assets.build`'s `Runner`/`ShellRunner`/`run_step!`/`Application.get_env(:accrue_admin, :accrue_admin_ui_round_runner, ShellRunner)` idiom verbatim. It sequences, all via `run_step!` with `cd: root`:
  1. `next-round` (`phase-ratchet-ledger.mjs --next-round`), then reads `test-results/ui-ratchet/.round-next` → integer round.
  2. `assets.build` (`mix accrue_admin.assets.build`).
  3. `capture` (`npx playwright test e2e/admin-visuals.spec.js`, `env: surfaces_env`).
  4. `propose` (`ratchet-propose.mjs`, `env: [{"RATCHET_ROUND", n} | surfaces_env]`).
  5. `verify` (`ratchet-verify.mjs`, `env: [{"RATCHET_ROUND", n}]`).
  6. `seal-round` (`phase-ratchet-ledger.mjs --seal-round`, `env: [{"RATCHET_ROUND", n} | surfaces_env]`).
  7. `digest` (`ratchet-digest.mjs`) — **always runs**, then reads `.round-status` and `Mix.raise`s only when it reads `cap-reached`.
- **Slice/surface resolution (D-52):** `--slice NAME` (bare `--slice` → `"foundation"`) is resolved by reading `e2e/baseline-manifest.js`'s `SLICES` map DIRECTLY via a captured `node -e "console.log(JSON.stringify(require('./e2e/baseline-manifest.js').SLICES))"` call decoded with `Jason.decode!/1` — there is **no hardcoded slice-contents literal** in the `.ex` (grep for `component-kitchen` returns nothing). `--surface a,b,c` is threaded verbatim. `--slice` + `--surface` together, or an unknown `--slice`, `Mix.raise` before any pipeline subprocess.
- **`Runner.capture/3` callback** added alongside `run/3` so the single stdout-consuming call (`load_slices!`) has a typed return (`{:ok, status, output}`) while the seven pipeline steps keep the exact `run/3` `{:ok, status}` shape of the twinned task.
- **`ui:round` package.json script** (`"cd .. && mix accrue_admin.ui.round"`) as a convenience alias; the mix task is the canonical entry point.
- **FakeRunner ExUnit test** (10 tests) proving the exact 7-step order (strict FIFO `receive`), `--slice`/`--surface` env threading (surfaces into capture/propose/seal-round only), the round-3 marker driving `RATCHET_ROUND=3`, the `cap-reached` → digest-then-raise branch, `continue`/`converged` non-raising completion, and both pre-pipeline raise guards. No live subprocess, server, PNGs, or API key: the FakeRunner returns canned `SLICES` JSON for the one captured `node -e` call.

## Deviations from Plan

None — plan executed as written. The `capture/3` callback and the argv-membership default for bare `--slice` are the two mechanisms the plan's `<action>` explicitly anticipated ("a dedicated `Runner.run` variant or `System.cmd/3` with a captured `into:` accumulator"; "bare `--slice` → `"foundation"`"), not deviations.

## Verification

- `cd accrue_admin && mix compile --warnings-as-errors` → clean (exit 0).
- `cd accrue_admin && mix test test/mix/tasks/accrue_admin_ui_round_test.exs` → **10 tests, 0 failures**.
- Acceptance: no hardcoded slice literal in the `.ex`; mutual-exclusivity and unknown-slice both raise with zero pipeline `:runner_call` messages received.

## Threat Flags

None. `--surface` CSV flows through `System.cmd`'s `env:` keyword list (never interpolated into a shell string), matching the plan's T-207-05 mitigation; no new package installs.

## Commits

- `a62ac9f1` feat(207-05): add accrue_admin.ui.round one-command ratchet task
- `cedc348b` test(207-05): FakeRunner test for ui.round sequence and marker branches

## Self-Check: PASSED

- Files exist: `accrue_admin.ui.round.ex`, `accrue_admin_ui_round_test.exs`, `package.json` (modified).
- Commits exist: `a62ac9f1`, `cedc348b`.
