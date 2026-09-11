# Phase 227 critical-path v2 experiment

## Current fact

- state: `rollback_applied_unverified`
- owner: maintainer
- budget: `phase-227-gap-dispatch-false-v2`
- candidate slots consumed: 2/3
- restoration slots consumed: 0/1
- old budget: `phase-227-dispatch-false-v1` remains immutable and supplies zero v2 observations
- Phase 228 provider outcome: `failed/selected_assertions_failed` (linked separately; never a candidate)
- next command: `none`

The only candidate event is attempt-1 `workflow_dispatch` with `run_live_stripe: false`, fingerprint `phase-227-gap-dispatch-false-v2`, and provider state `non_run`. Reruns and replacements are prohibited. Keep requires exactly three valid independent observations; an unspent authorization cannot satisfy PATH-02.

## Terminal decision

- state: `rollback_applied_unverified`
- PATH-02: `unmet`
- candidate authority: `closed`
- restoration authority: `closed_unspent`
- exact inverse workflow: `sha256:2622f7d8cb3d20ae68cec19db9f57bf8b88151e712cdbb360e9db03642772fb0`
