---
phase: 212-lattice-stripe-2-x-bump-green-reconciliation
plan: 01
subsystem: infra
tags: [lattice_stripe, stripe, dependency-bump, mix, hex, elixir]

# Dependency graph
requires: []
provides:
  - "accrue/mix.exs pinned to {:lattice_stripe, \"~> 2.0\"} (resolves to 2.1.0)"
  - "All four mix.lock files (accrue, accrue_admin, accrue_portal, examples/accrue_host) resolving lattice_stripe to the identical 2.1.0 version + checksum"
  - "examples/accrue_host/mix.lock free of stale hex-mode :accrue/:accrue_admin/:accrue_portal entries"
  - "212-UPGRADE-EVIDENCE.md documenting the breaking-surface diff, fixture-decoupling proof, and full per-package gate output"
affects: [213-stripe-native-advisory-entitlements-sync, 214-docs-and-truth-reconciliation]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Surgical single-dep lockfile regen (mix deps.update <dep>) instead of blanket mix deps.get, to avoid churning unrelated dep versions"
    - "mix deps.unlock <dep> is required to actually drop a stale hex-mode lock entry for a dependency that is now declared path-mode — plain deps.update/deps.get never removes it, since path deps never get a lock entry written"

key-files:
  created:
    - .planning/phases/212-lattice-stripe-2-x-bump-green-reconciliation/212-UPGRADE-EVIDENCE.md
  modified:
    - accrue/mix.exs
    - accrue/mix.lock
    - accrue_admin/mix.lock
    - accrue_portal/mix.lock
    - examples/accrue_host/mix.lock

key-decisions:
  - "Followed D-01/D-02 exactly: mix.exs pin is `~> 2.0` (not `~> 2.0.0`, not `~> 2.1`); lock resolves to whatever `~> 2.0` yields today (2.1.0), never hand-frozen"
  - "Substituted `mix test --cover` for `mix coveralls` on accrue_admin/accrue_portal (Rule 3): those packages use ExUnit's built-in `test_coverage:` config, not the excoveralls dep — RESEARCH.md's claim that all three packages share excoveralls was inaccurate for admin/portal"
  - "Used `mix deps.unlock accrue accrue_admin accrue_portal` + `mix deps.get` in examples/accrue_host to actually remove the stale hex-mode lock entries (D-05) — a bare `mix deps.update lattice_stripe` or `mix deps.get` alone does not drop them, since Mix never rewrites a lock entry for a dependency that is not itself unlocked, and path deps never receive lock entries in the first place"
  - "Left pre-existing, non-lattice_stripe `mix hex.audit` CVE advisories (postgrex, swoosh, decimal, phoenix, req, hackney) untouched — confirmed via `git show HEAD~1:accrue/mix.lock` that these exact versions predate this bump; fixing them is out of scope (no unrelated dep bumps, no new required deps)"

patterns-established:
  - "Evidence-artifact pattern for dependency-currency phases: sibling-repo tag-range diff + fixture-decoupling grep + full per-package gate output, committed separately from the atomic bump commit"

requirements-completed: [BUMP-01, BUMP-02, BUMP-03]

coverage:
  - id: D1
    description: "accrue/mix.exs lattice_stripe pin bumped from ~> 1.1 to ~> 2.0; all four mix.lock files regenerated to the identical 2.1.0 resolution; host's stale hex-mode accrue/accrue_admin/accrue_portal lock entries removed; committed as one atomic 5-file change"
    requirement: "BUMP-01"
    verification:
      - kind: other
        ref: "grep -n 'lattice_stripe' accrue/mix.exs; grep -h '\"lattice_stripe\":' accrue/mix.lock accrue_admin/mix.lock accrue_portal/mix.lock examples/accrue_host/mix.lock; git show --stat -1 82f659fd"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every LatticeStripe.* call site across all four packages compiles clean against 2.1.0 with zero deprecation warnings, including under --no-optional-deps (proves Finch is genuinely optional); both pre-verified 2.0.0 breaking vectors (fixture rename, Finch pool) reconfirmed needing zero Accrue-side code change"
    requirement: "BUMP-02"
    verification:
      - kind: other
        ref: "mix compile --warnings-as-errors --no-optional-deps (all 4 packages); grep -c 'LatticeStripe\\.Testing' accrue/test/support/stripe_fixtures.ex"
        status: pass
    human_judgment: false
  - id: D3
    description: "Each package's actually-configured Three Zeros gate subset is green with zero new skips/exclusions; dialyzer PLT churn absorbed automatically"
    requirement: "BUMP-03"
    verification:
      - kind: unit
        ref: "mix test --warnings-as-errors (accrue: 1685 tests, accrue_admin: 514 tests, accrue_portal: 37 tests); bash scripts/ci/accrue_host_verify_test_bounded.sh (37 tests)"
        status: pass
      - kind: other
        ref: "mix credo --strict (accrue, accrue_admin, accrue_portal); mix dialyzer --format github (accrue, accrue_admin); mix coveralls / mix test --cover (accrue, accrue_admin, accrue_portal)"
        status: pass
    human_judgment: false

duration: 20min
completed: 2026-07-30
status: complete
---

# Phase 212 Plan 01: lattice_stripe 1.7.13 → 2.1.0 Bump & Green Reconciliation Summary

**Bumped `:lattice_stripe` from `~> 1.1` to `~> 2.0` (resolving to 2.1.0) across all four monorepo packages with zero Accrue-side code changes — both pre-verified breaking vectors (fixture-builder rename, Finch-optional relaxation) confirmed no-ops.**

## Performance

- **Duration:** ~20 min
- **Completed:** 2026-07-30T19:14:35Z
- **Tasks:** 3
- **Files modified:** 6 (5 in bump commit + 1 evidence artifact)

## Accomplishments
- `accrue/mix.exs` pin raised from `{:lattice_stripe, "~> 1.1"}` to `{:lattice_stripe, "~> 2.0"}` — the sole pin location in the monorepo.
- All four `mix.lock` files (`accrue`, `accrue_admin`, `accrue_portal`, `examples/accrue_host`) regenerated in dev/path mode, all resolving `lattice_stripe` to the identical `2.1.0` version and checksum.
- `examples/accrue_host/mix.lock`'s stale hex-mode `{:hex, :accrue, "1.4.0", ...}` / `:accrue_admin` / `:accrue_portal` leftover entries removed, restoring genuine path-mode resolution.
- Every package's actually-configured Three Zeros gate subset (asymmetric per package) run and green: `accrue` + `accrue_admin` (compile x2, test, credo, dialyzer, coverage, hex.audit), `accrue_portal` (same minus dialyzer), `examples/accrue_host` (compile x2 + bounded test script only).
- Fixture-rename breaking vector (D-09) reconfirmed a no-op at bump time: `accrue/test/support/stripe_fixtures.ex` has zero references to `LatticeStripe.Testing.*`.
- Evidence artifact (`212-UPGRADE-EVIDENCE.md`) captures the sibling-repo `lib/` diff-surface across `v1.7.13..v2.1.0`, the fixture-decoupling statement, and the full per-package gate output.

## Task Commits

Each task was committed per the plan's atomic-commit design (D-03: pin + all four locks bundled together in one commit, separate from the evidence-artifact docs commit):

1. **Task 1 (pin + lockfile regen) + Task 2 (gate verification, zero code changes)** — folded into the Task 3 atomic commit per the plan's explicit D-03 instruction (no code changes resulted from Task 2, so nothing to commit separately): `82f659fd` (chore)
2. **Task 3: evidence artifact** - `00de8954` (docs)

_Note: the plan's own design (D-03/D-07) explicitly defers the pin+lock commit to Task 3, after Task 1's regen and Task 2's gate-verification both complete cleanly with zero reconciliation edits — this is not a deviation from the generic "commit every task" default, it is the plan's authored commit shape._

## Files Created/Modified
- `accrue/mix.exs` — lattice_stripe pin `~> 1.1` → `~> 2.0`
- `accrue/mix.lock` — lattice_stripe 1.7.13 → 2.1.0, plus its subtree (hpax, mint, plug, plug_crypto)
- `accrue_admin/mix.lock` — same subtree bump
- `accrue_portal/mix.lock` — same subtree bump
- `examples/accrue_host/mix.lock` — same subtree bump, plus removal of stale hex-mode `:accrue`/`:accrue_admin`/`:accrue_portal` entries (and their now-orphaned transitive deps), restoring full path-mode consistency
- `.planning/phases/212-lattice-stripe-2-x-bump-green-reconciliation/212-UPGRADE-EVIDENCE.md` — new evidence artifact (D-10)

## Decisions Made
- Pin precision followed D-01/D-02 exactly: `~> 2.0`, resolving to `2.1.0` (not hand-frozen to `2.0.0`).
- Coverage command substitution (Rule 3): `accrue_admin`/`accrue_portal` don't declare `excoveralls` (only `accrue` does) — they use ExUnit's built-in `test_coverage:` threshold config, so `mix test --cover` was substituted for `mix coveralls` on those two packages. Both passed their configured thresholds (80.25% ≥ 80%, 77.76% ≥ 75%).
- Host lockfile reconciliation: a bare `mix deps.update lattice_stripe` (and even a bare `mix deps.get`) did not remove the stale hex-mode `:accrue`/`:accrue_admin`/`:accrue_portal` lock entries in `examples/accrue_host/mix.lock`, because Mix never rewrites a lock entry unless the dependency itself is explicitly unlocked, and path-mode dependencies never receive lock entries at all. Used `mix deps.unlock accrue accrue_admin accrue_portal` followed by `mix deps.get` to force the removal, per D-05's intent.
- Pre-existing, unrelated `mix hex.audit` CVE advisories (postgrex, swoosh, decimal, phoenix, req, hackney across the four packages) were left untouched — confirmed via `git show HEAD~1:accrue/mix.lock` that these exact versions predate this bump. Zero `lattice_stripe` advisories or retired-package flags appear in any audit output, which is the load-bearing check D-08 assigns to `hex.audit`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Host lockfile's stale hex-mode entries required explicit `deps.unlock`, not just `deps.update`**
- **Found during:** Task 1 (lockfile regeneration)
- **Issue:** The plan (and D-05) expected `mix deps.update lattice_stripe` to "incidentally" drop `examples/accrue_host/mix.lock`'s stale `{:hex, :accrue, "1.4.0", ...}` entry. In practice, neither `mix deps.update lattice_stripe` nor a full `mix deps.get` removed it — Mix only rewrites/removes a lock entry for a dependency that is itself explicitly unlocked; path-mode deps never get a lock entry at all, so the orphaned hex entry from a prior state persisted indefinitely.
- **Fix:** Ran `mix deps.unlock accrue accrue_admin accrue_portal` (surgical, scoped to exactly the three top-level deps with stale entries) followed by `mix deps.get` to force genuine path-mode re-resolution.
- **Files modified:** examples/accrue_host/mix.lock (already in scope for Task 1)
- **Verification:** `grep -c '{:hex, :accrue,' examples/accrue_host/mix.lock` → 0; `mix deps` confirms `accrue`/`accrue_admin`/`accrue_portal` all resolve via path.
- **Committed in:** 82f659fd (bump commit)

**2. [Rule 3 - Blocking] `mix coveralls` task not available for accrue_admin/accrue_portal**
- **Found during:** Task 2 (gate verification)
- **Issue:** RESEARCH.md claimed `excoveralls` is a dep in `accrue`/`accrue_admin`/`accrue_portal` with 80%/75% thresholds. Live repo state shows only `accrue` declares `excoveralls`; `accrue_admin`/`accrue_portal` use ExUnit's built-in `test_coverage: [summary: [threshold: N]]` instead — `mix coveralls` fails with "task could not be found" for those two packages.
- **Fix:** Substituted `mix test --cover` (the correct command for built-in `test_coverage` config) for those two packages.
- **Files modified:** none (verification-command substitution only)
- **Verification:** Both packages pass their configured coverage thresholds (accrue_admin 80.25% ≥ 80%, accrue_portal 77.76% ≥ 75%).
- **Committed in:** N/A (verification-only, documented in the evidence artifact)

---

**Total deviations:** 2 auto-fixed (both Rule 3 — blocking issues preventing the plan's stated acceptance criteria from being met).
**Impact on plan:** Both fixes were mechanical corrections needed to actually satisfy the plan's own acceptance criteria (D-05's stale-entry removal, the coverage gate running at all) — no scope creep, no new dependencies, no code changes.

## Issues Encountered
- `mix hex.audit` flags several pre-existing, unrelated CVE advisories (postgrex, swoosh, decimal, phoenix, req, hackney) across all four packages. Confirmed via `git show HEAD~1:accrue/mix.lock` these are pre-existing and untouched by this bump — no `lattice_stripe` advisories or retired-package flags appear anywhere. Documented in the evidence artifact as out-of-scope for this phase; not fixed (would require unrelated dep version bumps, violating the scope fence).
- `examples/accrue_host`'s `mix deps.update lattice_stripe` triggered broader transitive dep churn (hackney, braintree, req, phoenix, etc.) than the other three packages, reflecting that the host's pre-bump lock had drifted out of sync with the monorepo's path-mode graph (same underlying stale-entry condition as the D-05 finding). All resulting compiles and the bounded test slice pass clean.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
Phase 213 (Stripe-native advisory entitlements sync) is unblocked: the `LatticeStripe.Entitlements.*` modules now exist in the resolved dependency graph across all four packages, ready for adoption. Phase 214 (docs & truth reconciliation) can proceed once 213 ships, to update `CLAUDE.md`'s stale `~> 0.2`/`1.1.0` references against the now-live `~> 2.0`/`2.1.0` state.

---
*Phase: 212-lattice-stripe-2-x-bump-green-reconciliation*
*Completed: 2026-07-30*

## Self-Check: PASSED

All created/modified files verified present on disk:
- accrue/mix.exs — FOUND
- accrue/mix.lock — FOUND
- accrue_admin/mix.lock — FOUND
- accrue_portal/mix.lock — FOUND
- examples/accrue_host/mix.lock — FOUND
- .planning/phases/212-lattice-stripe-2-x-bump-green-reconciliation/212-UPGRADE-EVIDENCE.md — FOUND

All commit hashes verified present in git log:
- 82f659fd (bump commit) — FOUND
- 00de8954 (evidence docs commit) — FOUND
