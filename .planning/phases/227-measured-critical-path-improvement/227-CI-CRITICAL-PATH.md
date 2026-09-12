# Phase 227 critical-path v3 authorization

## Current fact

- state: `authorized_pending_candidate`
- owner: maintainer
- budget: `phase-227-gap-dispatch-false-v3`
- PATH-02: `unmet`
- candidate slots reserved: 0/3
- candidate slots consumed: 0/3
- restoration slots consumed: 0/1
- remote effects: `disabled`
- old budgets: `phase-227-dispatch-false-v1`, `phase-227-gap-dispatch-false-v2` remain closed and supply zero v3 observations
- next command: `node scripts/ci/preflight_phase227_candidate.sh --commit <candidate-sha> --expected-state candidate --evidence-out .planning/phases/227-measured-critical-path-improvement/227-CANDIDATE-PREFLIGHT.json`

This is local preparation, not live proof. Candidate authority is finite: exactly three unique attempt-1 manual-false runs at one committed candidate after an append-only activation binds passing exact-tree preflight evidence. Reruns, replacements, and concurrency are prohibited; restoration is one conditional inverse-only slot.
