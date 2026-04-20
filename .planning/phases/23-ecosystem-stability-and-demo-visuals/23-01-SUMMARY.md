---
phase: 23-ecosystem-stability-and-demo-visuals
plan: "01"
subsystem: infra
tags: [hex, lattice_stripe, mix]
requirements-completed:
  - STAB-01
key-files:
  created: []
  modified: []
completed: 2026-04-20
---

# Phase 23 plan 01: lattice_stripe lockfiles

**All three Mix trees resolve `lattice_stripe` 1.1.0 on `~> 1.1` — already the latest published line Hex could serve without authenticated Hex.**

## Accomplishments

- Ran `printf 'n\n' | mix deps.update lattice_stripe` in `accrue/` and `accrue_admin/` (Hex token refresh declined; resolution used public index). Output listed `lattice_stripe 1.1.0` under **Unchanged** for both.
- Attempted the same in `examples/accrue_host/`; Mix blocked on `Waiting for lock on the deps directory (held by process …)` (external long-running `mix deps.get`). **No `mix.lock` edits** were required: existing host lock already pins the same `lattice_stripe` 1.1.0 digest as the other trees.
- Ran `mix compile` in `accrue/` as a smoke check after resolution — succeeded.

## Deviations

- **examples/accrue_host `mix deps.update`:** Not re-run to completion due to deps directory lock held by another local Mix process. Lockfile parity was confirmed by reading `mix.lock` (`lattice_stripe` 1.1.0). Retry when no concurrent `mix` holds the lock if you want a fresh resolver transcript.

## CHANGELOG

- Resolved version did not change from 1.1.0; no package `CHANGELOG.md` line was added.

## Self-Check: PASSED (lockfile + compile)

- [x] `accrue/mix.lock`, `accrue_admin/mix.lock`, and `examples/accrue_host/mix.lock` all record `lattice_stripe` `1.1.0` for `~> 1.1`.
- [x] Compile smoke (`accrue`): PASS.
- [ ] Full `mix test` in `accrue/` (2026-04-20): **6 failures** in `Accrue.Docs.PackageDocsVerifierTest` — verifier exits `package versions diverged` because `accrue/mix.exs` `@version "0.2.0"` and `accrue_admin/mix.exs` `@version "0.3.0"` disagree. Unrelated to `lattice_stripe` lockfiles; align package versions in a dedicated release/docs task if you need a green full suite.
