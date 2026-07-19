---
phase: 207
slug: orchestration-digest-one-command-round-fix-loop
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-04
---

# Phase 207 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from 207-RESEARCH.md `## Validation Architecture`. All gate-path tests are
> deterministic and LLM-free (invariant carried from Phases 205/206); ORCH-07's
> cache-hit proof is a documented live smoke, never a CI gate.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Node built-in self-test idiom (`runSelfTest`/`--self-test`, no external runner) for all `.mjs` reducers/renderers; ExUnit for the Mix tasks (fake `Runner` behaviour) |
| **Config file** | none — each `.mjs` is directly executable (`node e2e/ratchet/<file>.mjs --self-test`); ExUnit via `mix test` |
| **Quick run command** | `cd accrue_admin && npm run ratchet:ledger:self-test` (extend once round-seal/dry-round logic lands) — or the single `--self-test` / `mix test <file>` for whichever file the task touched |
| **Full suite command** | `cd accrue_admin && npm run ratchet:ledger && node ../scripts/ci/verify_ratchet_ledger.mjs && node e2e/ratchet/ratchet-digest.mjs --self-test && mix test test/mix/tasks/accrue_admin_ui_round_test.exs test/mix/tasks/accrue_admin_ui_fix_test.exs` |
| **Estimated runtime** | ~30 seconds (node self-tests are sub-second; ExUnit fake-Runner tests avoid any real shell-out) |

---

## Sampling Rate

- **After every task commit:** Run the relevant `--self-test` (node) or `mix test <specific file>` (Elixir) for the file the task touched.
- **After every plan wave:** `npm run ratchet:ledger:self-test` + `node e2e/ratchet/ratchet-digest.mjs --self-test` + `mix test test/mix/tasks/accrue_admin_ui_round_test.exs test/mix/tasks/accrue_admin_ui_fix_test.exs`.
- **Before `/gsd-verify-work`:** Full suite green, PLUS a documented (not CI-gated — 207 wires no CI) live smoke proving ORCH-07's cache-hit (`cache_read_input_tokens > 0` on a second identical run).
- **Max feedback latency:** ~30 seconds.

---

## Per-Task Verification Map

Requirement-level map (per-task IDs filled by the planner). Every gate-path row is deterministic.

| Req ID | Behavior | Test Type | Automated Command | File Exists | Status |
|--------|----------|-----------|-------------------|-------------|--------|
| ORCH-01 | `ui.round` sequences build→boot→seed→capture→propose→dedup→verify→rank→digest→seal in the right order | unit (fake Runner) | `mix test test/mix/tasks/accrue_admin_ui_round_test.exs` | ❌ W0 | ⬜ pending |
| ORCH-02 | Digest row-builder + validator produce well-formed worklist/decisions-needed/gallery rows; `--self-test` covers empty/normal/converged/cap-reached | unit (`--self-test`) | `node e2e/ratchet/ratchet-digest.mjs --self-test` | ❌ W0 | ⬜ pending |
| ORCH-03 | `ui.fix` refuses missing/invalid `suppressed_reason`; batch-approve applies all pre-filled `approve` rows with zero edits | unit (fake Runner + fixture `decisions.json`) | `mix test test/mix/tasks/accrue_admin_ui_fix_test.exs` | ❌ W0 | ⬜ pending |
| ORCH-04 | `ui.fix` sequences apply→build→commit→re-capture→re-score→ledger-advance→mint in order | unit (fake Runner) | `mix test test/mix/tasks/accrue_admin_ui_fix_test.exs` | ❌ W0 | ⬜ pending |
| ORCH-05 | Guard-mint appends idempotently (re-run never duplicates a row for the same `finding_id`); minted `guard_ref` passes the ledger's guard-ref check | unit (`--self-test` on mint, `fs.mkdtempSync` fixture specs) | `node e2e/ratchet/phase-ratchet-ledger.mjs --self-test` (extend) | ❌ W0 (extend) | ⬜ pending |
| ORCH-06 | Dry-round 4-clause conjunction fires correctly; K=2 consecutive dry → CONVERGED; 6th non-converged round → non-zero exit | unit (`--self-test` fixtures: all-clauses-true vs. each clause individually false; K-run + cap) | `node e2e/ratchet/phase-ratchet-ledger.mjs --self-test` (extend) | ❌ W0 (extend) | ⬜ pending |
| ORCH-07 | Cache hit on a second identical-prefix call — `cache_read_input_tokens > 0`; identity + no-key/`--self-test` paths unchanged | **live smoke (manual, NOT a CI gate)** + unit for request-shape (`cache_control` present, no reorder) | request-shape assertion in `--self-test`; live: run `ratchet:propose` twice, diff `usage.cache_read_input_tokens` | N/A (live) / ❌ W0 (shape unit) | ⬜ pending |
| ORCH-08 | `RATCHET_SURFACES=dashboard` captures/proposes ONLY dashboard; unset covers the full configured set | integration (Playwright asserting filtered `shots.length`) + unit (`discoverPngs()` filter) | `RATCHET_SURFACES=dashboard npx playwright test e2e/admin-visuals.spec.js`; `node -e` on `discoverPngs()` filter | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `accrue_admin/test/mix/tasks/accrue_admin_ui_round_test.exs` — fake-`Runner` stub asserting the ORCH-01 `System.cmd` sequence
- [ ] `accrue_admin/test/mix/tasks/accrue_admin_ui_fix_test.exs` — fake-`Runner` + fixture `decisions.json` for ORCH-03/ORCH-04
- [ ] Extend `accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs`'s existing `runSelfTest()` with new fixtures for round-seal, the dry-round 4-clause conjunction, K=2/6-cap convergence (ORCH-06), and idempotent guard-mint (ORCH-05)
- [ ] `accrue_admin/e2e/ratchet/ratchet-digest.mjs` (net-new) with its own `runSelfTest()` covering all four banner states (ORCH-02)
- [ ] Framework install: **none** — ExUnit and the node self-test idiom are already present project-wide.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Prompt-cache hit (`cache_read_input_tokens > 0`) | ORCH-07 | Requires a live `ANTHROPIC_API_KEY` and real model round-trip; must never sit on the deterministic CI gate (invariant: LLM never on the gate path) | Run `ratchet:propose` twice against unchanged PNGs; diff `usage.cache_read_input_tokens` in a debug log line; expect >0 on the second run |
| End-to-end `ui.round` → digest render on a real slice | ORCH-01/ORCH-02 | Boots the real admin (4017), captures via Playwright, calls the live model — integration-level, not unit-gated | `mix accrue_admin.ui.round --slice foundation`; open the emitted `round-NN/digest.html` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
