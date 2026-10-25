# Phase 249 Host Replay Ledger (249-14)

- Replayed at HEAD: `3494680b4ac7f40a48436f2a7ef699155592c33a` (scratch clone via `git clone --no-local`)
- Tool: `249-replay-ci-job.py`, sha256 `6e191296814eda299ca465f757ef928d5b7e85408e93270929512e1393eefb07`
- Date: 2026-10-24

## Tokens regenerate and determinism (docs-contracts-shift-left steps 45-47)

Command: `python3 249-replay-ci-job.py --job docs-contracts-shift-left --run --only 'Install tokens harness' --only 'Regenerate tokens' --only 'Tokens/specimens are reproducible'` run inside the clone.

| # | Step | Result | Seconds |
|---|------|--------|---------|
| 45 | Install tokens harness | PASS | 1.1 |
| 46 | Regenerate tokens + specimens | PASS | 0.5 |
| 47 | Tokens/specimens are reproducible (determinism gate, D-17) | PASS | 0.6 |

`git status --porcelain --untracked-files=no` in the clone after the run: empty (no tracked diff). Clone removed.

## Clone status classification (host-integration)

Every line of `git -C <clone> status --porcelain` after host-integration must appear verbatim in this block.

<!-- classified-clone-changes:begin -->
<!-- classified-clone-changes:end -->

## Routed to Phase 250

`host-docker-smoke` is NOT run in Phase 249. By orchestrator decision it is routed to Phase 250, because the maintainer marks Docker volumes and images off-limits. No docker or docker compose command was run in this plan.
