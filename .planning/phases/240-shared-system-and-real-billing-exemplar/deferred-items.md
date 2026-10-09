## Deferred Items

- Existing Admin Node suite had 9 FocusTrap/command-palette failures because its test harness did not provide `window` / `requestAnimationFrame` required by focus restoration.
  status: resolved
  **Found during:** Plan 240-02 Task 2 validation (`node --test test/js/*.mjs`)
  **Resolved during:** Plan 240-04 Task 2 by supplying browser focus APIs in the affected Node harnesses; production focus behavior remains under the existing tests. `node --test --test-reporter=tap test/js/*.mjs` passes 41/41.
  **Scope:** Pre-existing harness failures in `test/js/focus_trap_test.mjs` and `test/js/command_palette_test.mjs`; no production hook change was needed.

- Full Phase 199 E2E suite has three unrelated failures: recovery fixture route link absent on desktop, and the interaction focus-ring ratchet guard cannot find its attention rail on desktop/mobile.
  status: open
  **Found during:** Plan 240-04 Task 2 validation (`CI=1 npm run e2e:phase199`)
  **Scope:** Broader existing Phase 199 recovery fixture and ratchet guard failures; task-owned focused keyboard case passed. Needs separate investigation.
