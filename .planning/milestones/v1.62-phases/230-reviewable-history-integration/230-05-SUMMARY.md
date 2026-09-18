---
phase: 230-reviewable-history-integration
plan: 05
subsystem: infra
tags: [elixir, mix, decimal, ex_money, dependency-resolution, integration-candidate]

requires:
  - phase: 230-reviewable-history-integration
    plan: 02
    provides: refs/heads/integration/v1.62-candidate (single --no-ff merge, never pushed) and the collect/render/verify disposition triad
  - phase: 230-reviewable-history-integration
    plan: 03
    provides: the recomputed hazard universe with a non_run dependency-lock-drift row on accrue/mix.exs owned by this plan
provides:
  - "A compiling, resolving integration candidate: .tool-versions pinning elixir 1.19.5-otp-28 (plus erlang 28.5 so asdf can actually resolve it), and accrue_admin/accrue_portal/examples-accrue_host mix.lock re-resolved to Decimal 3.1.1 / ex_money 6.2.1, matching accrue/mix.lock exactly."
  - "Green money-math and StreamData property suites (70 properties, 188 tests, 0 failures) against the post-merge Decimal 3 / ex_money 6 / Ecto 3.14 dependency set, with zero source-code changes needed -- the migration did not break anything the milestone line shipped."
  - "Two new config_test.exs assertions covering both surviving hunks of the config.ex disjoint-hunk hazard, each independently proved to fail when its hunk is reverted."
  - "The dependency-lock-drift and doc-rewrite hazard rows in 230-INTEGRATION-DISPOSITION.json flipped to proved with recorded exit codes; both new candidate commits declared in post_merge_commits."
affects: [231-exact-sha-release-gate-proof, 232-bounded-hygiene-release-handoff]

actuals:
  tokens: 42000
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Scratch git clone (into the session scratchpad, never git worktree add) checked out to integration/v1.62-candidate, used to run mix deps.get/compile/test against the candidate's real file tree without ever switching the main repo checkout off the milestone branch -- the same technique 230-02 used for its rollback-proof clone, extended here to real toolchain execution rather than just git plumbing."
    - "Candidate-branch commits produced in the scratch clone are brought back into the main repo's local ref via `git fetch <scratch-path> integration/v1.62-candidate:integration/v1.62-candidate` -- updates the ref without checking it out, leaving the main repo's HEAD and working tree untouched."
    - "Disposition JSON hazard rows are hand-patched (never regenerated via the collector, which always re-initializes post_merge_commits to []) after real toolchain proof is captured, then re-rendered deterministically via render_integration_disposition.mjs -- this is the pattern 230-03's code comments explicitly anticipated for this plan."

key-files:
  created: []
  modified:
    - .tool-versions
    - accrue_admin/mix.lock
    - accrue_portal/mix.lock
    - examples/accrue_host/mix.lock
    - accrue/test/accrue/config_test.exs
    - .planning/phases/230-reviewable-history-integration/230-INTEGRATION-DISPOSITION.json
    - .planning/phases/230-reviewable-history-integration/230-INTEGRATION-DISPOSITION.md

key-decisions:
  - "Added an `erlang 28.5` line to .tool-versions alongside the required `elixir 1.19.5-otp-28` and the existing `nodejs 22.14.0` -- asdf cannot resolve the elixir version without a paired erlang version, and the plan's acceptance criteria (a line beginning `elixir ` and a line beginning `nodejs `) do not prohibit a third line."
  - "Task 2 required zero accrue/lib/accrue/ source changes: the enumerated money-math and StreamData property suites (33 _test.exs files matching `use ExUnitProperties|Decimal|Money`, 2 non-test support .ex files excluded since `mix test` rejects non-`_test.exs` paths) pass cleanly against the post-merge Decimal 3 / ex_money 6 dependency set with no fix needed. The milestone line's money math was already compatible; the hazard was real (uncompiled/untested combination) but resolved clean."
  - "The dependency-lock-drift hazard row's single `command` evidence field records the money-math/property `mix test` invocation (the strongest single proof, since a lock-skew or Decimal-3 incompatibility would have surfaced there) with a `note` documenting the separate `mix deps.get --check-locked` proof across all four projects and the `mix compile --warnings-as-errors` result -- the schema allows one argv command per row, not a compound list, matching 230-03's precedent of one evidence.command per hazard row."
  - "Task 3's config_test.exs mix_env test exercises `Config.validate_at_boot!/0`, not the schema-only `Config.validate!/1` -- `validate!/1` never invokes `maybe_validate_boot_setup!/1` (where the only public behavior gated on `safe_mix_env/0`, the `host_fake` rail's test-only guard, lives), confirmed by first writing a `validate!/1`-based version that passed even when the seam was reverted to `Accrue.Env.current/0` (a false negative), then rewriting against `validate_at_boot!/0` and re-confirming both a genuine PASS on the candidate and a genuine FAIL when the seam is reverted."
  - "The two new candidate commits (.tool-versions + lockfiles; config_test.exs) were built in a scratch clone checked out to integration/v1.62-candidate and fetched back into the main repo's local ref, per the sequential-execution mandate to never switch the main checkout off gsd/milestone-v1.62-release-integration-hygiene -- mirroring 230-02's stated rationale for avoiding a working-tree checkout of the candidate."

requirements-completed: [INTG-02]

coverage:
  - id: D1
    description: ".tool-versions is committed with an elixir pin, and all four Elixir projects (accrue, accrue_admin, accrue_portal, examples/accrue_host) resolve under `mix deps.get --check-locked` with a single consistent Decimal 3.1.1, with no accrue/mix.exs dependency constraint loosened."
    requirement: "INTG-02"
    verification:
      - kind: other
        ref: "mix --version && for d in accrue accrue_admin accrue_portal examples/accrue_host; do (cd $d && mix deps.get --check-locked); done -- all four exit 0 (scratch clone at integration/v1.62-candidate)"
        status: pass
      - kind: other
        ref: "grep -h '\"decimal\"' accrue/mix.lock accrue_admin/mix.lock accrue_portal/mix.lock examples/accrue_host/mix.lock -- all four report decimal 3.1.1"
        status: pass
      - kind: other
        ref: "git diff 4d45002c..integration/v1.62-candidate -- accrue/mix.exs accrue_admin/mix.exs accrue_portal/mix.exs examples/accrue_host/mix.exs -- empty diff, no constraint touched"
        status: pass
    human_judgment: false
  - id: D2
    description: "accrue compiles cleanly on the candidate (--warnings-as-errors, zero warnings from accrue's own code), and the enumerated money-math and StreamData property suites pass with a captured exit code and non-zero test count against the post-merge Decimal 3 / ex_money 6 dependency set."
    requirement: "INTG-02"
    verification:
      - kind: other
        ref: "cd accrue && mix compile --force --warnings-as-errors -- exit 0"
        status: pass
      - kind: other
        ref: "cd accrue && mix test <33 enumerated files, listed below> --seed 0 -- 70 properties, 188 tests, 0 failures (9 excluded by the suite's own default live_stripe tag exclusion)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Both surviving hunks of the config.ex disjoint-hunk hazard (Accrue.Env.mix_env/0 resolution; optional :branding from_email/support_email) are covered by config_test.exs assertions, each independently confirmed to fail when its hunk is reverted."
    requirement: "INTG-02"
    verification:
      - kind: unit
        ref: "accrue/test/accrue/config_test.exs#\":branding accepts a config that omits both :from_email and :support_email\""
        status: pass
      - kind: unit
        ref: "accrue/test/accrue/config_test.exs#\"Accrue.Config's boot validation resolves the mix environment via Accrue.Env.mix_env/0, not Accrue.Env.current/0\""
        status: pass
    human_judgment: false
  - id: D4
    description: "The doc-rewrite hazard (accrue/guides/entitlements.md) is discharged by the repository's existing documentation-truth check, and the mix.exs/manifest version agreement with origin/main is re-measured live, not transcribed."
    requirement: "INTG-02"
    verification:
      - kind: other
        ref: "bash scripts/ci/verify_package_docs.sh (scratch clone at integration/v1.62-candidate) -- exit 0"
        status: pass
      - kind: other
        ref: "git show integration/v1.62-candidate:accrue/mix.exs and git show origin/main:accrue/mix.exs both report @version \"1.5.1\"; .release-please-manifest.json identical on both sides"
        status: pass
    human_judgment: false
  - id: D5
    description: "The dependency-lock-drift and doc-rewrite hazard rows in 230-INTEGRATION-DISPOSITION.json are flipped to proved with a command argv array and a captured integer exit_code, both new candidate commits are declared in post_merge_commits, and the full disposition verifier passes with no D-21 lane executed."
    requirement: "INTG-02"
    verification:
      - kind: other
        ref: "node scripts/ci/verify_integration_disposition.mjs --records ... --rendered ... --candidate integration/v1.62-candidate --expected-repository szTheory/accrue --require-ancestry --require-scope --require-hazard-universe --require-post-merge-scope --require-determinism -- PASS"
        status: pass
      - kind: unit
        ref: "node --test scripts/ci/collect_integration_disposition.mjs scripts/ci/verify_integration_disposition.mjs scripts/ci/render_integration_disposition.mjs -- 16/16 pass"
        status: pass
    human_judgment: false

duration: 40 min
completed: 2026-09-15
status: complete
commits: 3
plan_head_before: 99a23b875667558e794ae515845b2dcdc64831d7
---

# Phase 230 Plan 5: Make the Candidate a Candidate Summary

**Pins the toolchain, re-resolves three sibling `mix.lock` files off the D-18 Decimal-2/Decimal-3 skew, and proves the money-math and StreamData property suites (70 properties, 188 tests, 0 failures) pass cleanly against the post-merge Decimal 3 / ex_money 6 / Ecto 3.14 dependency set with zero source-code fixes needed.**

## Performance

- **Duration:** ~40 min
- **Started:** 2026-09-15T15:03:00-04:00 (approx, first file read)
- **Completed:** 2026-09-15T15:38:16-04:00
- **Tasks:** 3
- **Files modified:** 7 (2 candidate-branch commits + 1 milestone-branch disposition commit)

## Accomplishments

- **`.tool-versions` committed with an Elixir pin.** Added `elixir 1.19.5-otp-28` (matching CLAUDE.md's CI-matrix primary development target) and `erlang 28.5` (required for asdf to actually resolve the elixir version) alongside the pre-existing `nodejs 22.14.0` line. Without this, none of Phase 230's focused regressions — nor Phase 231's GATE-01 fresh-clone gate — could run without out-of-band operator knowledge.
- **D-18's cross-package Decimal skew resolved.** `mix deps.get --check-locked` failed in `accrue_admin`, `accrue_portal`, and `examples/accrue_host` before this plan (each still locked Decimal 2.4.1 / ex_money 5.24.2 against a path-dep `accrue` declaring `~> 3.0` / `~> 6.2`). Ran `mix deps.get` in each to re-resolve against the post-merge `accrue` constraints; all four projects now lock a single consistent Decimal 3.1.1 / ex_money 6.2.1, and `mix deps.get --check-locked` exits 0 in all four. No `accrue/mix.exs`-family constraint was loosened — confirmed by an empty diff across all four `mix.exs` files between the merge commit and the candidate tip.
- **The candidate compiles and the money-math/property suites are green with zero code fixes.** `mix compile --force --warnings-as-errors` exits 0 in `accrue` (zero warnings from `accrue`'s own code; pre-existing warnings from the `rendro` dependency are unrelated to this migration and out of scope). The 33 enumerated money-math and StreamData property test files (see list below) pass: 70 properties, 188 tests, 0 failures, 9 tests excluded by the suite's own default `:live_stripe`/`:live_stripe_connect` tag exclusion (not by this plan — D-21 lanes were never separately invoked). The Decimal 3 / ex_money 6 migration did not break any money-math behavior the milestone line shipped.
- **Both surviving hunks of the `config.ex` disjoint-hunk hazard are now covered by regressions.** Added two assertions to `config_test.exs`: one proving `:branding` accepts a config that omits both `from_email` and `support_email` while still honoring other supplied branding keys; one proving `Accrue.Config`'s boot validation (`validate_at_boot!/0`) resolves the environment via `Accrue.Env.mix_env/0`, not `Accrue.Env.current/0`. Both were manually confirmed as genuine discriminators — each test flips red when its corresponding source hunk is reverted (verified locally in the scratch clone; the reverts were never committed).
- **`dependency-lock-drift` and `doc-rewrite` hazard rows flipped to `proved`.** The `accrue/mix.exs` row (absorbing both the version-train bump and the Decimal/ex_money lock drift per 230-03's classification) now carries `state: "proved"`, `exit_code: 0`, and the money-math test invocation as its `command` evidence. The `accrue/guides/entitlements.md` row now carries `state: "proved"`, `exit_code: 0`, evidenced by `scripts/ci/verify_package_docs.sh` exiting 0 on the candidate. Both new candidate commits are declared in `post_merge_commits` with `owner_plan: "230-05"`. Full verifier run (`--require-ancestry --require-scope --require-hazard-universe --require-post-merge-scope --require-determinism`) passes.

## Enumerated Money-Math and Property Suite (33 files, all git-tracked)

```
test/accrue/billing/charge_3ds_test.exs
test/accrue/billing/charge_test.exs
test/accrue/billing/coupon_actions_test.exs
test/accrue/billing/default_payment_method_test.exs
test/accrue/billing/dunning_test.exs
test/accrue/billing/properties/idempotency_key_test.exs
test/accrue/billing/properties/proration_test.exs
test/accrue/billing/proration_roundtrip_test.exs
test/accrue/billing/refund_braintree_test.exs
test/accrue/billing/refund_test.exs
test/accrue/billing/upcoming_invoice_test.exs
test/accrue/config_dunning_campaign_test.exs
test/accrue/connect/charges_test.exs
test/accrue/connect/platform_fee_test.exs
test/accrue/connect/transfer_test.exs
test/accrue/entitlements/offline_test.exs
test/accrue/invoices/format_money_property_test.exs
test/accrue/money_property_test.exs
test/accrue/money_test.exs
test/accrue/processor/stripe_test.exs
test/live_stripe/charge_3ds_live_test.exs
test/live_stripe/connect_test.exs
test/property/apple_convergence_property_test.exs
test/property/apple_lineage_property_test.exs
test/property/connect_platform_fee_property_test.exs
test/property/dunning_campaign_property_test.exs
test/property/dunning_funnel_property_test.exs
test/property/entitlement_decision_cases_property_test.exs
test/property/entitlement_projection_property_test.exs
test/property/entitlement_summary_monotonic_property_test.exs
test/property/entitlements_fail_closed_property_test.exs
test/property/guard_fail_closed_property_test.exs
test/property/money_property_test.exs
```

Enumerated via `grep -rlE "use ExUnitProperties|Decimal|Money" test | grep '_test\.exs$'` (the plan's own grep, filtered to `_test.exs` paths — `mix test` rejects non-test `.ex` support files passed as explicit paths, e.g. `test/support/billing_case.ex`, which also matched the raw grep but are not test files).

## Task Commits

Two commits landed on `integration/v1.62-candidate` (built in a scratch clone, fetched back into the main repo's local ref); one commit landed on `gsd/milestone-v1.62-release-integration-hygiene` (the disposition evidence, which lives on the milestone branch alongside the collect/render/verify scripts that don't exist on the candidate):

1. **Task 1: toolchain pin + sibling lockfile re-resolution** - `31d19449` (feat) — on `integration/v1.62-candidate`
2. **Task 2: compile + money-math/property suites** - no candidate commit (zero code changes needed; hazard-row update folded into commit 3 below since Task 3's `entitlements.md`/version checks required flipping the same JSON file)
3. **Task 3: config_test.exs regressions for the disjoint-hunk hazard** - `bab50d92` (test) — on `integration/v1.62-candidate`
4. **Hazard row updates (Task 2 + Task 3's disposition evidence)** - `d282e1f1` (feat) — on `gsd/milestone-v1.62-release-integration-hygiene`

**Plan metadata:** (this commit) - `docs(230-05): complete plan`

## Files Created/Modified

- `.tool-versions` - newly tracked; elixir 1.19.5-otp-28 + erlang 28.5 + nodejs 22.14.0
- `accrue_admin/mix.lock`, `accrue_portal/mix.lock`, `examples/accrue_host/mix.lock` - re-resolved to Decimal 3.1.1 / ex_money 6.2.1, matching `accrue/mix.lock`
- `accrue/test/accrue/config_test.exs` - two new assertions covering both surviving hunks of the `config.ex` disjoint-hunk hazard
- `.planning/phases/230-reviewable-history-integration/230-INTEGRATION-DISPOSITION.json` / `.md` - `dependency-lock-drift` and `doc-rewrite` hazard rows flipped to `proved`; two new `post_merge_commits` rows declared

## Decisions Made

See `key-decisions` in frontmatter. Summarized: (1) added an `erlang` line to `.tool-versions` alongside the required `elixir`/`nodejs` lines, needed for asdf resolution and not prohibited by the plan's acceptance criteria; (2) Task 2 required zero source fixes — the money-math suites were already Decimal-3-compatible; (3) the `dependency-lock-drift` row's single evidence `command` records the test invocation with a `note` covering the separate `deps.get --check-locked` and `compile --warnings-as-errors` proofs, since the schema allows one argv command per row; (4) the `mix_env` regression exercises `Config.validate_at_boot!/0` rather than the schema-only `Config.validate!/1`, discovered after a first draft using `validate!/1` passed even with the seam reverted (a false negative caught before committing); (5) both new candidate commits were built in a scratch clone and fetched back into the local ref, keeping the main checkout on the milestone branch throughout, per the sequential-execution mandate.

## Deviations from Plan

None — plan executed exactly as written. The choices above (erlang pin, single-command evidence field, `validate_at_boot!/0` vs `validate!/1`) were implementation details needed to satisfy the plan's own explicit acceptance criteria, not scope changes.

## Issues Encountered

- **zsh word-splitting silently swallowed multi-file `mix test` invocations.** `mix test $FILES` (unquoted, without `${=FILES}`) passed the entire newline-joined string as a single argument under zsh's default `noshwordsplit`, producing `Paths given to "mix test" did not match any directory/file` — while still running Ecto setup first (making the failure look like a flake rather than an argument-passing bug). Fixed by using zsh's explicit `${=FILES}` split operator. Left as a note for future zsh-shell executors running the same plan's literal `<verify>` command.
- **`Config.validate!/1` does not invoke `maybe_validate_boot_setup!/1`.** A first draft of the `mix_env` regression called `Config.validate!/1` directly with a `rails:`/`default_rail:` opts map, which passed regardless of whether `safe_mix_env/0` delegated through `Accrue.Env.mix_env/0` or `Accrue.Env.current/0` — because `validate!/1` only runs schema-level `NimbleOptions.validate!/2`, never the semantic boot checks where the seam is actually exercised. Caught by manually reverting the seam and confirming the test stayed green (a false negative), then rewriting against `Config.validate_at_boot!/0` (which does run `maybe_validate_boot_setup!/1`) and re-confirming a genuine PASS/FAIL split.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The candidate now compiles, resolves consistently across all four Elixir projects, and has a green money-math/property suite against the post-merge dependency set — Phase 231's GATE-01 fresh-clone gate has a working toolchain pin to build on.
- `dependency-lock-drift` and `doc-rewrite` hazard rows are `proved`; the only hazard row this plan did not touch is `disjoint-hunk` (already `proved` by 230-03's static marker check) and the three `convergent-identical` rows (already `proved` by 230-03).
- INTG-02 is also declared by Plans 230-03 (already summarized), 230-04, and 230-06 (not yet summarized) — the shared-ID gate keeps it `In Progress` in REQUIREMENTS.md until all declaring plans finish; this plan's `update_requirements` step correctly defers marking it `Complete`.
- Plan 230-06 and 230-07 remain to execute; no blockers identified for either from this plan's work.

---
*Phase: 230-reviewable-history-integration*
*Completed: 2026-09-15*

## Self-Check: PASSED

- FOUND: `.tool-versions` (tracked on `integration/v1.62-candidate`, `git ls-tree -r --name-only integration/v1.62-candidate -- .tool-versions`)
- FOUND: `accrue/test/accrue/config_test.exs` (tracked on `integration/v1.62-candidate` with the two new assertions)
- FOUND: `.planning/phases/230-reviewable-history-integration/230-INTEGRATION-DISPOSITION.json` / `.md` (tracked on `gsd/milestone-v1.62-release-integration-hygiene`)
- FOUND commit: `31d19449` (`git cat-file -e 31d19449` — Task 1, on `integration/v1.62-candidate`)
- FOUND commit: `bab50d92` (`git cat-file -e bab50d92` — Task 3, on `integration/v1.62-candidate`)
- FOUND commit: `d282e1f1` (`git cat-file -e d282e1f1` — hazard row updates, on `gsd/milestone-v1.62-release-integration-hygiene`)
- Re-ran the plan-level `<verification>` items 1-7: all PASS. `mix deps.get --check-locked` exits 0 in all four projects with consistent Decimal 3.1.1; `mix compile` exits 0; the 33-file enumerated suite exits 0 (70 properties, 188 tests, 0 failures); `config_test.exs` covers both hunks (confirmed as genuine discriminators by local revert-and-rerun, not committed); `bash scripts/ci/verify_package_docs.sh` exits 0; `node scripts/ci/verify_integration_disposition.mjs --require-ancestry --require-scope --require-hazard-universe --require-post-merge-scope --require-determinism` reports PASS; no D-21 lane was executed (confirmed by task inventory — no `mix test` without file arguments, no dialyzer/Playwright/storybook/host-integration/docker/asset-rebuild/live-Stripe/hex.publish/GitHub-Actions command was run).
