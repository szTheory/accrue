# Phase 227 critical-path v2 experiment

## Current fact

- state: `authorized_unspent`
- owner: maintainer
- budget: `phase-227-gap-dispatch-false-v2`
- candidate slots consumed: 0/3
- restoration slots consumed: 0/1
- old budget: `phase-227-dispatch-false-v1` remains immutable and supplies zero v2 observations
- Phase 228 provider outcome: `failed/selected_assertions_failed` (linked separately; never a candidate)
- next command: `node scripts/ci/verify_ci_critical_path.mjs --verify-workflow --workflow .github/workflows/ci.yml --contract .planning/phases/227-measured-critical-path-improvement/227-ci-contract.json`

The only candidate event is attempt-1 `workflow_dispatch` with `run_live_stripe: false`, fingerprint `phase-227-gap-dispatch-false-v2`, and provider state `non_run`. Reruns and replacements are prohibited. Keep requires exactly three valid independent observations; an unspent authorization cannot satisfy PATH-02.
