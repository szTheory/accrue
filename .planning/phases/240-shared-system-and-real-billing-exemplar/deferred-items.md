## Deferred Items

- Existing Admin Node suite has 9 FocusTrap/command-palette failures because its test harness does not provide `window` / `requestAnimationFrame` required by focus restoration.
  status: open
  **Found during:** Plan 240-02 Task 2 validation (`node --test test/js/*.mjs`)
  **Scope:** Pre-existing failures in `assets/js/hooks/focus_trap.js`, `test/js/focus_trap_test.mjs`, and `test/js/command_palette_test.mjs`; none are changed by the baseline-set guard.
