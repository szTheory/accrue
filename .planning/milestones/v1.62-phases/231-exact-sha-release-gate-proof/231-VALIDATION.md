---
phase: "231"
slug: "exact-sha-release-gate-proof"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-15"
---

# Phase 231 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Node built-in `node:test` for `scripts/ci/*.mjs`; ExUnit (`mix test`) for Elixir packages; Playwright for browser E2E |
| **Config file** | none centralized — each `scripts/ci/*.mjs` is directly executable and self-testing via `--fixtures` / `--self-test`; ExUnit config per package `mix.exs` / `test_helper.exs`; Playwright config at `examples/accrue_host/playwright.config.js` and `accrue_admin/playwright.config.js` |
| **Quick run command** | `node scripts/ci/<script>.mjs --fixtures` (hermetic, no live repo state) |
| **Full suite command** | The GATE-01 declared merge-blocking cohort (see 231-RESEARCH.md § CI Cohort Enumeration) plus every new verifier's `--fixtures` self-test wired into `docs-contracts-shift-left` |
| **Estimated runtime** | `--fixtures` self-tests: seconds. Full scratch-clone cohort: cost-driver itemized, not timed end-to-end (cold Dialyzer PLT, Chromium download, Docker daemon boot) — see 231-RESEARCH.md § Local Cost and Environment Prerequisites |

---

## Sampling Rate

- **After every task commit:** Run the relevant new/extended verifier's `--fixtures` self-test (hermetic, seconds)
- **After every plan wave:** Re-run the real (non-fixture) verifier against the actual committed evidence
- **Before `/gsd-verify-work`:** All three gate artifacts pass strict/real verification; `.planning/WINDOWS.md` shows `open_count: 0`; `231-REPOSITORY-INVENTORY.json` minted last (D-28) and passes
- **Max feedback latency:** 60 seconds for the `--fixtures` tier

---

## Per-Task Verification Map

> Seeded from 231-RESEARCH.md § Validation Architecture. The planner binds concrete task IDs, artifact
> filenames, and commands; filenames below marked *(discretion)* are settled by the planner under
> CONTEXT.md § Claude's Discretion.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | 1 | GATE-01 | — | Candidate re-cut asserts ancestry/shape invariants before anything binds to a SHA (D-03, D-04) | integration | `node scripts/ci/verify_<gate01-artifact>.mjs --fixtures` *(discretion)* | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | GATE-01 | — | Scratch-clone cohort run captures real exit codes; no cache restore, no worktree row added (D-12, D-13) | integration | `node scripts/ci/verify_<gate01-artifact>.mjs` (real) *(discretion)* | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | GATE-02 | — | Per-lane records keep the closed `PROVIDER_STATES` enum; no `success`/`green` alias reachable; no `proved` without a recorded exit code (D-21, D-29) | unit + fixture contract | `node --test scripts/ci/collect_ci_baseline.mjs` | ✅ (extend, D-19) | ⬜ pending |
| TBD | TBD | TBD | GATE-02 | — | Required-job set derived from the in-repo declaration and asserted against the live job graph; drift fails the gate (D-18) | fixture contract | `node scripts/ci/verify_ci_baseline.mjs --fixtures` | ✅ (extend) | ⬜ pending |
| TBD | TBD | TBD | GATE-02 | — | Event class recorded as a first-class field; `workflow_dispatch` proof never readable as pull-request proof (D-17) | fixture contract | `node scripts/ci/verify_ci_baseline.mjs --fixtures` | ✅ (extend) | ⬜ pending |
| TBD | TBD | TBD | GATE-03 | — | Every non-`open` WINDOWS.md row joins 1:1 by row id to a rich disposition row carrying owner, rationale, release impact, current evidence (D-26) | unit + fixture contract | `node --test scripts/ci/collect_window_dispositions.mjs` *(discretion)* | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | GATE-03 | — | Exact set equality on the row-id join via `exactMap` / `assertSameMultiset`; never a non-empty check (D-30) | fixture contract | `node scripts/ci/verify_window_dispositions.mjs --fixtures` *(discretion)* | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | GATE-03 | — | Re-rendering the JSON byte-equals the committed Markdown; timestamps from `git show -s --format=%cI`, never `Date.now()` (D-31) | fixture contract | `node scripts/ci/verify_window_dispositions.mjs --fixtures` *(discretion)* | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] GATE-01 evidence `collect → render → verify` triad (or equivalent) — does not exist yet
- [ ] GATE-03 `collect_window_dispositions.mjs` / `render_window_dispositions.mjs` / `verify_window_dispositions.mjs` — D-26's fourth triad instance, does not exist yet *(names at planner discretion)*
- [ ] GATE-02 extension to `collect_ci_baseline.mjs` for the required-job-set drift assertion (D-18) — does not exist yet; planner's discretion whether it lands there or in a new checker
- [ ] `231-ROLLBACK-POINT.json` re-mint — reuse Phase 230's pattern (`git revert -m 1` proof executed in a scratch clone, D-07); no new framework needed
- [ ] New verifiers wired into `docs-contracts-shift-left`, following `verify_phase230_archive_invariants.mjs`'s three-step CI wiring
- [ ] New artifacts resolve through `scripts/ci/phase_evidence_path.mjs` and get a row in `scripts/ci/README.md` (D-32)

---

## Manual-Only Verifications

All phase behaviors have automated verification.

CONTEXT.md D-33 and the project's post-218 executable-acceptance policy (CLAUDE.md) forbid human-judgment
gates where an executable assertion can decide the outcome: `behavior_unverified: 0` is required to close
the phase, and no `type="tracer"`, `checkpoint:human-verify`, or `<human-check>` may stand in for an
assertion.

Two actions in this phase are irreversible external operations rather than acceptance criteria, and are
already authorized in CONTEXT.md — they are not manual *verifications*:

- Pushing `integration/v1.62-candidate` to `origin` (D-14; one-way in practice — the SHA becomes public)
- Dispatching `gh workflow run ci.yml --ref integration/v1.62-candidate` (D-14, D-16)

Their *outcomes* are verified automatically by the GATE-02 evidence triad.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s for the `--fixtures` tier
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
