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

- Admin asset build reports unavailable development Storybook CSS/JS asset paths, while completing the package build successfully.
  status: open
  **Found during:** Plan 240-05 Task 2 (`mix accrue_admin.assets.build`)
  **Scope:** Existing development Storybook asset resolution; no runtime or build failure in the package hook change.

- ExMoney reports automatic exchange-rate service startup is deprecated during the Admin ExUnit suite.
  status: open
  **Found during:** Plan 240-05 Task 1 (`mix test`)
  **Scope:** Existing test/application exchange-rate startup configuration; unrelated to the disposable cancellation fixture.

- Full host `mix verify.full` stopped in the existing `AccrueHostWeb.TrustSmokeTest`: webhook ingest measured 222ms against its 100ms release smoke budget.
  status: open
  **Found during:** Plan 240-06 Task 2 (`HEX_HOME=/private/tmp/accrue240-hex MIX_ENV=test mix verify.full`)
  **Diagnostic follow-up (2026-10-09):** One unchanged run of `HEX_HOME=/private/tmp/accrue240-hex MIX_ENV=test mix verify.full` resolved the pinned dependencies and entered the bounded host ExUnit stage. The runner summary was `223 tests, 1 failure`; the alias stopped there before compile, post-compile regression, dev-boot and browser stages. The captured tool output omitted the detailed failure block; no native JUnit/report file or sanitized report copy was produced, so the rerun does not establish a second exact latency or independently confirm the failing test identity.
  **Timing boundary:** `TrustSmokeTest` starts its timer around `post_webhook/2`, which builds a `Plug.Test` connection and calls `Router.init/1` and `Router.call/2`; the request interval includes signature verification, persistence and job enqueue/database work. Account/subscription/payload setup, DB reset, suite startup and compilation are outside that interval. Therefore the 222ms observation is not explained by fixture setup or suite cold startup alone; this combined request-path measurement does not isolate an individual backend operation.
  **Disposition and owner:** No test, threshold, backend capability or public contract was changed: this UI evidence follow-up did not introduce the webhook path and the captured rerun lacks enough failure detail to justify a test or implementation correction. Keep this item open for the existing automated host owner `cd examples/accrue_host && HEX_HOME=/private/tmp/accrue240-hex MIX_ENV=test mix verify.full`; preserve its complete failure output on the next owner investigation. No human UAT or provider call is needed.
