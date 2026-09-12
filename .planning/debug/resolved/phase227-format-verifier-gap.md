---
status: resolved
trigger: "Diagnose and repair the Phase 227 gap-closure blockers after both bounded v2 candidate runs failed required release lanes at Accrue format and Plan 227-06 found the planned --require-kept verifier option unavailable. Preserve rollback and closed external-run authority; make no new CI dispatches."
created: 2026-09-11T23:33:20Z
updated: 2026-09-12T00:06:00Z
---

## Current Focus

bug_class: bohrbug
reasoning_checkpoint:
  hypothesis: "The Accrue format lane fails because test/accrue/backend_automation_contract_test.exs contains a committed line that differs from mix format output; the strict CLI refactor removed the documented --require-kept modifier, so Plan 227-06 cannot enforce its kept-only condition."
  confirming_evidence:
    - "CI-pinned Elixir 1.19.5/OTP 28 reproduces the formatter failure and names backend_automation_contract_test.exs with its exact replacement layout."
    - "The current parser allowlist rejects --require-kept as unknown, while git history shows the option existed before the strict CLI refactor."
    - "The current --require-final-decision only checks for any gap_decision, and verifyGapV2Evidence distinguishes kept from rollback."
  falsification_test: "If the formatter passes after applying its shown layout, or a current supported modifier both exists and rejects rollback terminal evidence as non-kept, this diagnosis is false."
  fix_rationale: "Apply only the formatter's reported layout and restore --require-kept as a strict modifier that delegates to validated v2 decision state and rejects every non-kept terminal."
  blind_spots: "The two historic remote runs cannot be re-executed under closed authority; local validation can prove source formatting and terminal-record semantics but cannot make rollback evidence become kept."
  candidate_causes:
    - "code: committed Accrue test source is not mix-format compliant; strict CLI option table omitted an existing kept-only contract."
    - "environment: local asdf lacked a selected Erlang/Elixir version, blocking initial reproduction but not explaining the CI failure because CI pins its toolchain."
  and_gate: "no — these are independent deterministic blockers: either alone prevents its respective required action; both require separate targeted repairs."
hypothesis: The Accrue test formatting and omitted kept-only verifier modifier were confirmed independent code defects.
test: Local repair verification and the required human-verification checkpoint are complete; preserve the recorded rollback and closed v2 authority.
expecting: The existing rollback remains rejected by --require-kept, while a future genuine kept terminal (only if separately authorized) can satisfy the restored guard.
next_action: Archive this resolved session only; do not dispatch, rerun, push, or alter refs.

## Symptoms

expected: The locally staged one-edge candidate passes all required release-lane preflight checks, and Plan 227-06 can invoke a documented strict kept-only verifier action after a genuinely kept decision.
actual: Both bounded v2 candidate runs (34637686199 and 34638355743) failed required release lanes at Accrue format; exact inverse rollback was applied and all v2 authority closed. Plan 227-06 then halted because the latest decision was rollback and its planned --require-kept verifier option was unavailable.
errors: "Required release lane failed at Accrue format; --require-kept verifier option unavailable."
reproduction: Reproduce the Accrue format job command from .github/workflows/ci.yml against the candidate changes/commits, then inspect scripts/ci/verify_ci_critical_path.mjs CLI action parsing and Plan 227-06 verification commands.
started: Observed during the 2026-09-11 Phase 227 gap-closure execution.

## Eliminated

## Evidence

- timestamp: 2026-09-11T23:33:20Z
  checked: Phase 227 Plan 227-05 terminal summary and Plan 227-06 precondition checkpoint.
  found: Both v2 runs are retained as required-release-lane failures; rollback is exact, authority is closed, no restoration run was created, and PATH-02 remains unmet.
  implication: Debugging must be local-only and must not authorize or create another external run.

- timestamp: 2026-09-11T23:37:00Z
  checked: Working-tree scope and relevant project artifacts.
  found: The debug session is untracked; unrelated planning, Stripe-fixture, and tool-version changes are already present. The failure is reported as a reproducible required-format lane and unavailable verifier option, so it is classified as a deterministic Bohrbug; no runnable per-test coverage evidence is yet available for SBFL.
  implication: Preserve all pre-existing changes and use deterministic local reproduction plus differential inspection rather than CI dispatches or flaky-run analysis.

- timestamp: 2026-09-11T23:40:00Z
  checked: CI lane definition, Phase 227 Plan 05 summary, and Plan 227-06 command.
  found: The required lane is exactly `cd accrue && mix format --check-formatted`. Plan 05 identifies candidate SHA `1bbda64e3b2dd6e6b9b6ed1281979376903346d7` and says its change was only removal of the authorized `host-integration` prerequisite; Plan 227-06 nevertheless invokes `--require-kept`.
  implication: The format and verifier symptoms may be independent; the next tests must directly distinguish a tree-format defect from a release-run/environment failure and inspect actual parser support.

- timestamp: 2026-09-11T23:43:00Z
  checked: Candidate commit differential, verifier CLI symbol table, and exact local format command.
  found: `1bbda64e` changes `.github/workflows/ci.yml`, Phase 227 NDJSON, and the verifier only; it contains no path under `accrue/`. The verifier allowlist contains `--require-final-decision` and no `--require-kept`. The exact command could not begin because local asdf has no Elixir version selected for `accrue`, whereas CI pins Elixir 1.19.5/OTP 28.
  implication: A source-format regression from the candidate edge edit is disproven; local verification must select the same runtime, and Plan 227-06 names an unavailable modifier.

- timestamp: 2026-09-11T23:46:00Z
  checked: Complete strict CLI parser and direct modifier probes.
  found: `--require-kept` deterministically exits 1 as an unknown option. `--require-final-decision` is only an allowed modifier and, by design, also requires one primary action. Its implementation checks merely for a `gap_decision` record, so it cannot establish the Plan 227-06 kept-only precondition. The pinned Elixir command remained blocked because asdf also has no Erlang runtime selected.
  implication: Replacing `--require-kept` with `--require-final-decision` would weaken the plan's safety contract; the correct repair direction is a dedicated kept-only modifier with a regression test, unless historical intent proves the plan itself is obsolete.

- timestamp: 2026-09-11T23:50:00Z
  checked: CI-compatible local format command, verifier history, and v2 decision validator.
  found: With `ASDF_ERLANG_VERSION=28.4.1 ASDF_ELIXIR_VERSION=1.19.5-otp-28`, the exact lane fails only for `accrue/test/accrue/backend_automation_contract_test.exs` and supplies the required formatted layout. `--require-kept` existed in commit 0da9450f, but the later strict parser removed it. Current `verifyGapV2Evidence` explicitly returns `state: kept|rollback_verified|rollback_applied_unverified`, so a kept-only modifier has an exact, locally testable predicate.
  implication: Both root causes are confirmed with direct deterministic evidence; implement two separate minimal code changes and retain the closed rollback state.

- timestamp: 2026-09-11T23:52:00Z
  checked: Focused kept-only CLI regression test.
  found: The new test is RED: `--verify-evidence ... --require-kept` reaches the current parser and fails specifically with `unknown option: --require-kept`, rather than with a non-kept terminal-state rejection.
  implication: The test directly reproduces the omitted modifier defect and will distinguish a real semantic restoration from an alias or no-op.

- timestamp: 2026-09-11T23:55:00Z
  checked: Minimal implementation diff.
  found: The verifier now accepts `--require-kept` only for evidence/live primary actions and explicitly fails every terminal decision whose validated state is not `kept`; the reported Accrue assertion now exactly matches the formatter's suggested multiline layout.
  implication: The implementation addresses both confirmed code defects without altering the restored workflow, evidence ledger, remote authority, or unrelated working-tree changes.

- timestamp: 2026-09-11T23:58:00Z
  checked: Target regression, expected negative terminal check, CI-pinned formatting, focused Accrue test, JavaScript syntax, fixture contract, and scoped diff check.
  found: All checks pass. The agent-authored specified-oracle regression confirms the existing rollback evidence fails as `v2 terminal decision is not kept`; the exact CI-pinned format lane is green; the focused Accrue test has 3 passing tests; `node --check`, verifier fixtures, and `git diff --check` pass.
  implication: Functional and adjacent local verification are green; remaining acceptance signals are mutation availability, no-op review, and revert/reconfirm.

- timestamp: 2026-09-12T00:03:00Z
  checked: Guardrail mutation availability, diff shape, and manual revert/reapply for each independent repair.
  found: No Stryker configuration or dependency exists. The diff is additive verifier behavior plus one formatter-prescribed layout change and an agent-authored regression test; it removes no behavior. Reverting the verifier repair restores `unknown option: --require-kept`, and reapplying restores `v2 terminal decision is not kept`. Reverting the format layout restores the exact reported file failure, and reapplying restores formatting compliance.
  implication: Mutation is the only degraded signal; the no-op/deletion and revert-and-reconfirm signals pass for both fixes without altering workflow, ledger, remote refs, or external-run authority.

- timestamp: 2026-09-12T00:05:00Z
  checked: Final local verification after both repairs were reapplied.
  found: `node --test scripts/ci/verify_ci_critical_path.test.mjs` passes (3/3); offline `--require-kept` rejects the recorded rollback as `v2 terminal decision is not kept`; CI-pinned Accrue format passes; the focused Accrue test passes (3/3); JavaScript syntax, restored-workflow fixtures, and `git diff --check` pass.
  implication: Both local deterministic blockers are repaired and verified. The current terminal rollback correctly remains non-kept and v2 authority remains closed.

- timestamp: 2026-09-12T00:06:00Z
  checked: Human-verification checkpoint response.
  found: The user explicitly approved finalization and archive of this session.
  implication: The verified local repairs may be recorded as resolved; the preserved rollback, closed v2 authority, and prohibition on new CI dispatches remain unchanged.

## Resolution

root_cause: "Committed format drift in accrue/test/accrue/backend_automation_contract_test.exs; strict CLI refactor removed the documented --require-kept terminal-state guard, leaving only weaker --require-final-decision."
fix: "Formatted the reported Accrue test expression and restored --require-kept as a strict verifier modifier that rejects any terminal state other than kept."
verification:
  target_test: { result: pass, command: "node --test scripts/ci/verify_ci_critical_path.test.mjs (3/3)" }
  mutation_check: { result: skipped, reason_if_skipped: "No Stryker configuration or dependency is present in the repository." }
  no_op_deletion: { result: pass, deletion_justified_by_rca: false, evidence: "Diff is additive verifier enforcement/test plus formatter-prescribed layout only." }
  adjacent_tests: { result: pass, suites_run: ["ASDF_ERLANG_VERSION=28.4.1 ASDF_ELIXIR_VERSION=1.19.5-otp-28 cd accrue && mix format --check-formatted", "ASDF_ERLANG_VERSION=28.4.1 ASDF_ELIXIR_VERSION=1.19.5-otp-28 cd accrue && mix test test/accrue/backend_automation_contract_test.exs --warnings-as-errors", "node scripts/ci/verify_ci_critical_path.mjs --fixtures --workflow-fixture .planning/phases/227-measured-critical-path-improvement/fixtures/ci-workflow-restored-v2.yml --contract .planning/phases/227-measured-critical-path-improvement/227-ci-contract.json"] }
  revert_and_reconfirm: { result: pass, bug_returned_on_revert: true, fixed_on_reapply: true, evidence: "Verifier reverted to unknown --require-kept; formatter reverted to exact named file failure; both green after reapply." }
  guardrail_verdict: accepted
oracle_type: specified — Plan 227-06 requires a kept decision, and the regression asserts the exact non-kept rejection for the recorded rollback terminal.
files_changed:
  - accrue/test/accrue/backend_automation_contract_test.exs
  - scripts/ci/verify_ci_critical_path.mjs
  - scripts/ci/verify_ci_critical_path.test.mjs

## Prevention

- **Code branch:** The strict CLI refactor narrowed the accepted-option table without retaining the documented kept-only predicate. The regression at `scripts/ci/verify_ci_critical_path.test.mjs` (`requires a kept v2 terminal decision when requested`) now verifies the predicate against the recorded rollback terminal.
- **Environment branch:** An unselected local asdf runtime initially prevented direct reproduction. The CI-pinned `ASDF_ERLANG_VERSION=28.4.1 ASDF_ELIXIR_VERSION=1.19.5-otp-28` format command is now part of the recorded validation, separating local tool selection from source correctness.
- **Why not caught:** No pre-merge verifier CLI contract test covered the documented `--require-kept` option, and the committed Accrue test was not checked with the CI-pinned formatter before the candidate run.
- **Recurrence guard:** `scripts/ci/verify_ci_critical_path.test.mjs` covers the strict rollback rejection; the CI-pinned `mix format --check-formatted` lane rejects future Accrue format drift.
