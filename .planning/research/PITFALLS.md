# v1.36 Pitfall Research — Dual-Provider Core Completion

## Main Risks

### Promoting labels without proof

If a staged row becomes `all first-party` without deterministic coverage, the repo reintroduces the exact supportability drift that v1.35 just cleaned up.

### Mixing supported cancel paths with out-of-slice lifecycle work

`cancel`, `cancel_immediately`, `cancel_at_period_end`, `pause`, and `resume` are adjacent in code but not equal in scope. Pulling the whole lifecycle family into this milestone would turn a closure milestone into another expansion sweep.

### Matrix/runtime mismatch

The public matrix, `Capabilities.support_label/1`, and adapter booleans must move together. Updating only one creates immediate contract confusion.

### Doc cleanup without merge blockers

If package docs or example-host proof change without a corresponding gate, staged-vs-first-party drift will come back.

## Prevention Strategy

- Promote only rows backed by current runtime truth and explicit tests.
- Keep unsupported lifecycle branches explicitly out of slice.
- Update capability labels, matrix prose, and docs in the same phase.
- Add or extend tests/scripts that fail when the contract drifts again.
