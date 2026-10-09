## Deferred Items

- Existing Admin Node suite had 9 FocusTrap/command-palette failures because its test harness did not provide `window` / `requestAnimationFrame` required by focus restoration.
  status: resolved
  **Found during:** Plan 240-02 Task 2 validation (`node --test test/js/*.mjs`)
  **Resolved during:** Plan 240-04 Task 2 by supplying browser focus APIs in the affected Node harnesses; production focus behavior remains under the existing tests. `node --test --test-reporter=tap test/js/*.mjs` passes 41/41.
  **Scope:** Pre-existing harness failures in `test/js/focus_trap_test.mjs` and `test/js/command_palette_test.mjs`; no production hook change was needed.

- Full Phase 199 E2E suite's recovery route and focus-ring ratchet failures are resolved.
  status: resolved
  **Resolved during:** Plan 240-04 acceptance follow-up by aligning the recovery fixture with `Accrue.Clock.utc_now()` and retargeting the two stale focus-ring rows to the current `/billing` keyboard search control.
  **Verification:** `CI=1 npm run e2e:phase199` passes 21 tests with 15 existing skips; separate route and ratchet JUnit reports pass (the ratchet runs on desktop and mobile).
