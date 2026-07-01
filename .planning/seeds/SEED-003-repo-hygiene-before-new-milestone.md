---
id: SEED-003
status: backlogged
planted: 2026-07-01
planted_during: post-v1.54 repo hygiene
trigger_when: before opening a new milestone, before release prep, or when local/GitHub/GSD state feels stale
scope: Small
---

# SEED-003: Repo hygiene checkpoint before the next milestone or release

## Why This Matters

Accrue's GSD workflow moves quickly, and long milestone runs can leave local
Git, worktrees, GitHub CI, Release Please, and planning mirrors in subtly
different states. A short hygiene checkpoint prevents the next milestone from
starting with stale local commits, dirty generated caches, red scheduled CI, or
untriaged release automation.

## When to Surface

Surface this seed when:

- a milestone has just shipped and archived,
- a new milestone is about to be opened,
- Release Please or Hex release prep is being considered,
- local `main` is ahead of `origin/main`,
- scheduled CI or release automation is red,
- worktrees, PRs, issues, or GSD health are unclear.

## Suggested Checklist

- Verify local `git status --short --branch` and `git worktree list --porcelain`.
- Remove or ignore generated local caches that are not repo artifacts.
- Run GSD health and repair/backfill safe planning gaps.
- Triage open PRs/issues and stale release branches.
- Run targeted local docs/release/GSD gates.
- Push `main` and milestone tags only after local checks are clean.
- Monitor GitHub Actions push CI and scheduled/advisory lanes.
- Stop before merging a Release Please PR or publishing Hex unless explicitly requested.

## Notes

This is an operational hygiene seed, not a product-feature seed. It should help
prepare the repo for the next adventure without changing package behavior or
forcing a Hex publish.
