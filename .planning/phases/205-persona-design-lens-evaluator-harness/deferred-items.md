# Deferred Items — Phase 205

Out-of-scope discoveries logged during execution. NOT fixed here (see execute-plan scope boundary).

## D1 — plan-03 manifest import path (pre-existing, out of scope for 205-04)

- **Found during:** 205-04 execution (reading `ratchet-propose.mjs`).
- **File:** `accrue_admin/e2e/ratchet/ratchet-propose.mjs` (Guard 3, `await import("./baseline-manifest.js")`).
- **Observation:** `baseline-manifest.js` lives at `accrue_admin/e2e/baseline-manifest.js`, but the dynamic import from `ratchet/ratchet-propose.mjs` uses `./baseline-manifest.js`, which resolves to `ratchet/baseline-manifest.js` (does not exist). This throws `ERR_MODULE_NOT_FOUND` on a LIVE (key-present) run.
- **Why not fixed here:** Introduced by plan 03 (Guard 3), not by any 205-04 change. It sits behind the no-key `exit 0` guard, so `--self-test` and `node --check` (the 205-04 gates) are unaffected, and the live proposer is a non-gating maintainer smoke. Fixing it is a plan-03 correctness change outside this plan's `files_modified` intent.
- **Suggested fix (for a follow-up):** change the import to `../baseline-manifest.js` (and update the two doc-comment references), then run the maintainer live smoke to confirm the design + persona fan-out reaches the model.
