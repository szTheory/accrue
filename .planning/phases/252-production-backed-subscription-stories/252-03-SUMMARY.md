---
phase: 252-production-backed-subscription-stories
plan: "03"
subsystem: testing
tags: [node, postgres, phoenix, playwright, e2e]

requires:
  - phase: 252-01
    provides: guarded E2E identity and the test-only endpoint runtime
provides:
  - Owned Phase 252 CLI for disposable test and review databases, ports, and processes
  - Real two-database reset isolation evidence with positive and negative controls
  - Dedicated non-reusing Playwright review lane and safe interactive review guide
affects: [252-04, 252-07, 252-08, 253]

actuals:
  tokens: 18981
  tasks: 2
  commits: 6

tech-stack:
  added: []
  patterns:
    - Exact manifest identity gates cleanup of launcher-owned child processes and databases.
    - Reset-capable and review endpoints use separate numeric database namespaces and ports.
    - Browser readiness requires the exact endpoint identity and a ready health response.

key-files:
  created:
    - scripts/dev/phase252_lab.mjs
    - scripts/dev/phase252_lab.test.mjs
    - scripts/dev/phase252_isolation.test.mjs
    - accrue_admin/playwright.phase252.config.js
    - accrue_admin/e2e/phase252-review.spec.js
    - guides/ui-story-lab.md
    - .planning/phases/252-production-backed-subscription-stories/252-03-01-red-evidence.json
    - .planning/phases/252-production-backed-subscription-stories/252-03-02-red-evidence.json
    - .planning/phases/252-production-backed-subscription-stories/252-03-02-browser-red-evidence.json
  modified:
    - accrue_admin/config/test.exs
    - accrue_admin/test/support/e2e_server.ex
    - accrue_admin/test/support/e2e_plug.ex
    - accrue_admin/package.json
    - storybook/components/subscription_detail.story.exs

key-decisions:
  - "Use fresh numeric partitions to derive exact disposable database names and reject existing targets before mutation."
  - "Keep review and reset lanes on distinct databases, ports, and server processes; the browser lane always disables server reuse."
  - "Preserve the host-heldout lane's existing fixed port and guard contract."

patterns-established:
  - "Only a matching PID, start identity, parent identity, command, database, port, and nonce authorize process cleanup."
  - "A mounted browser review first verifies the launcher's exact ready health identity."

requirements-completed: [LAB-01, SCEN-04]

coverage:
  - id: D1
    description: "Maintainers can launch an owned disposable endpoint, reject occupied or mismatched resources before mutation, and remove only resources whose process and database identity still match."
    requirement: LAB-01
    verification:
      - kind: unit
        ref: "scripts/dev/phase252_lab.test.mjs#checks server, database and port before creating the owned target"
        status: pass
      - kind: unit
        ref: "scripts/dev/phase252_lab.test.mjs#accepts cleanup only when pid, start identity, command, DB, port and nonce all match"
        status: pass
      - kind: integration
        ref: "node --test scripts/dev/phase252_lab.test.mjs scripts/dev/phase252_isolation.test.mjs (12 passed)"
        status: pass
      - kind: e2e
        ref: "accrue_admin/e2e/phase252-review.spec.js#owned review server identity and production-backed subscription story are available (1 passed)"
        status: pass
    human_judgment: false
  - id: D2
    description: "A real normal-lane reset deletes its own marker while independently persisted review customer, subscription, and item rows remain byte-for-byte unchanged; held-out stress data remains a separate guarded lane."
    requirement: SCEN-04
    verification:
      - kind: integration
        ref: "scripts/dev/phase252_isolation.test.mjs#ordinary reset deletes its marker and preserves review relationships byte-for-byte"
        status: pass
      - kind: integration
        ref: "scripts/dev/phase252_isolation.test.mjs#occupied listeners, wrong health identity, failed bootstrap and duplicate namespaces fail closed"
        status: pass
      - kind: unit
        ref: "scripts/dev/phase252_lab.test.mjs#keeps the host-heldout numeric database and fixed port contract"
        status: pass
    human_judgment: false

commits: 6
plan_head_before: b249da0e49697ee5442dfa5a9326d8d4acdb7c4e
plan_head_after: 4ea9ba4875668775f1065df60f02d4a780fd7fe3
duration: 43min
completed: 2026-10-26
status: complete
---

# Phase 252 Plan 03: Production-backed Subscription Stories Summary

**Two-database reset isolation and browser review now run through fresh, identity-checked Phoenix endpoints with exact resource cleanup.**

## Performance

- **Duration:** 43 min
- **Started:** 2026-10-26T19:31:55-04:00
- **Completed:** 2026-10-26T20:15:05-04:00
- **Tasks:** 2
- **Files modified:** 14

## Accomplishments

- Added an owned launcher for explicit numeric test partitions, derived database names, loopback ports, nonce-bound health identity, exclusive namespace locks, and exact process/database cleanup.
- Proved the ordinary reset's positive control by deleting its inserted customer and cascading subscription/item rows. The review database's joined snapshot remained byte-for-byte identical after reload.
- Added fail-closed controls for occupied listeners, mismatched health identity, interrupted bootstrap, duplicate namespace ownership, and stale lock metadata.
- Added a dedicated single-worker Playwright project that never reuses an existing server, validates the owned server identity, and opens the mounted subscription story. Documented browser, serve, isolation, held-out, cleanup, and evidence-lane commands.
- Verified the explicit browser partition `9252100624` was absent before launch and absent after the successful Playwright run; the launcher's session manifest directory was empty after cleanup.

## Task Commits

1. **252-03-01: Refuse unknown database/server reuse and own the lab lifecycle** — `424b217e` (RED), `a11b851b` (GREEN), `b9e5fa6f` (readiness fix).
2. **252-03-02: Prove normal reset isolation and document safe interactive review** — `a07e4be0` (loopback identity RED), `cad6a830` (browser RED), `4ea9ba48` (GREEN).

Measured plan commits: 6, from `b249da0e49697ee5442dfa5a9326d8d4acdb7c4e` through `4ea9ba4875668775f1065df60f02d4a780fd7fe3`.

## Files Created/Modified

- `scripts/dev/phase252_lab.mjs` and `scripts/dev/phase252_lab.test.mjs` — launcher lifecycle, boundary checks, and local identity normalization.
- `scripts/dev/phase252_isolation.test.mjs` — real two-database reset positive and negative controls.
- `accrue_admin/playwright.phase252.config.js` and `accrue_admin/e2e/phase252-review.spec.js` — dedicated owned browser review.
- `accrue_admin/test/support/e2e_server.ex`, `accrue_admin/test/support/e2e_plug.ex`, and `accrue_admin/config/test.exs` — opt-in runtime identity, readiness, and test configuration.
- `storybook/components/subscription_detail.story.exs` — removes Phoenix Storybook's injected `:id` before validating scenario assigns.
- `accrue_admin/package.json` and `guides/ui-story-lab.md` — launcher scripts and safe-use documentation.
- Three RED evidence records — launcher ownership, PostgreSQL inet identity, and mounted browser review.

## TDD Gate Compliance

- Task 1 RED evidence in `252-03-01-red-evidence.json` was classified `RED_EVIDENCE_OK`; the named partition assertion failed before the owned launcher existed. The launcher and readiness changes passed their tests.
- Task 2's loopback identity RED in `252-03-02-red-evidence.json` was classified `RED_EVIDENCE_OK` (9 passed, named assertion failed). Its supported Node reporter emitted complete TAP from the actual test run.
- Task 2's mounted browser RED in `252-03-02-browser-red-evidence.json` was classified `RED_EVIDENCE_OK` (one executed Playwright test, one failed assertion). The raw JUnit report came from a private project mirror so repository path hooks remained enabled.
- GREEN verification passed: 12 Node tests, including both real-database isolation tests; one owned browser test; JavaScript syntax checks; `git diff --check`; and `mix format --check-formatted` for changed Elixir files.

## Decisions Made

- The launcher derives the target database from a fresh numeric partition and refuses a pre-existing target, occupied port, non-loopback server, or identity mismatch before creation.
- Review and reset-capable processes stay on independent databases, ports, and process identities. Browser startup has `reuseExistingServer: false`; SIGTERM lets the launcher verify and clean its own child before Playwright exits.
- The existing held-out lane keeps its fixed port and guard instead of gaining broader host authority.
- Static Storybook rendering remains separate from mounted authorization, provider completion, action dispatch, and persistence evidence.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Canonicalized PostgreSQL loopback and partition identity**
- **Found during:** Task 2 integration.
- **Issue:** `inet_server_addr()::text` returned `127.0.0.1/32`, which the launcher rejected, and the E2E runtime formatted an already-string partition as an integer.
- **Fix:** Query `host(inet_server_addr())`, accept only canonical loopback host masks defensively, and compare the partition as a string.
- **Files modified:** `scripts/dev/phase252_lab.mjs`, `accrue_admin/test/support/e2e_server.ex`.
- **Verification:** The focused RED/GREEN test and the full 12-test plan command passed.
- **Committed in:** `a07e4be0`, `4ea9ba48`.

**2. [Rule 1 - Bug] Keep browser readiness false until migrations finish**
- **Found during:** Task 1 browser startup integration.
- **Issue:** The opt-in health route returned HTTP 200 before migrations completed, allowing Playwright to start against an unready endpoint.
- **Fix:** Return HTTP 503 while the identity reports `ready: false`; readiness polling then waits for the fully initialized server.
- **Files modified:** `accrue_admin/test/support/e2e_plug.ex`, `accrue_admin/test/support/e2e_server.ex`, `scripts/dev/phase252_lab.mjs`.
- **Verification:** Owned browser review passed after the readiness change.
- **Committed in:** `b9e5fa6f`.

**3. [Rule 1 - Bug] Preserve exact cleanup across executable shims and Playwright shutdown**
- **Found during:** Task 2 process cleanup integration.
- **Issue:** The Mix shim execs into `beam.smp` under the same PID, changing the command identity; Playwright's process-group shutdown could also kill its server before the launcher completed owned cleanup.
- **Fix:** Refresh the observed command only after PID, start identity, parent PID, parent start identity, and parent command hash match; run the owned server detached and configure graceful SIGTERM shutdown.
- **Files modified:** `scripts/dev/phase252_lab.mjs`, `accrue_admin/playwright.phase252.config.js`.
- **Verification:** The isolation suite cleaned its exact databases; the browser suite passed and the explicit review database and manifest were absent after shutdown.
- **Committed in:** `4ea9ba48`.

**4. [Rule 1 - Bug] Ignore Phoenix Storybook's injected variation identifier**
- **Found during:** Task 2 mounted browser review.
- **Issue:** Phoenix Storybook injects `:id` into variation assigns, while the scenario validator accepts only scenario attributes; the review story failed to render.
- **Fix:** Remove `:id` and `:__changed__` before validating scenario facts.
- **Files modified:** `storybook/components/subscription_detail.story.exs`.
- **Verification:** The browser RED failed before the fix and the owned review browser test passed after it.
- **Committed in:** `cad6a830`, `4ea9ba48`.

**Total deviations:** 4 auto-fixed bugs (Rule 1). No architectural changes or dependencies were added.

## Issues Encountered

- Node 26's default test reporters did not produce a format accepted by the RED classifier. A supported custom TAP reporter captured the unchanged test events, and the classifier accepted the complete report.
- The first browser JUnit report contained the checkout's absolute home path and was rejected by the commit hook. The test was rerun in a private mirror with its own build directory; the unchanged JUnit report passed classification, and no hook was disabled.
- The first GREEN run exposed that `assert.doesNotReject` returns no callback value. The test now captures the result inside the callback and verifies the canonical address directly.
- No shared database or pre-existing listener was mutated. The integration checks removed only their launcher-created disposable targets.

## Known Stubs

None.

## User Setup Required

None. Local PostgreSQL, Mix, Node, and already-installed Playwright dependencies are prerequisites for the documented commands; no package was installed.

## Next Phase Readiness

Plan 252-04 can use the launcher and the separate test/review lanes. The final `npm --prefix accrue_admin run phase252:check` gate remains unavailable until plan 252-08 adds it. No provider-completion, mounted-authorization, persistence, or visual-judgment claims are made here.

---
*Phase: 252-production-backed-subscription-stories*
*Completed: 2026-10-26*

## Self-Check: PASSED

- Summary, all plan artifacts, and all three RED evidence records exist.
- All six measured task commits are ancestors of the plan head recorded above.
