---
phase: 243-integrated-evidence-and-feedback-preview
plan: 02
subsystem: testing
tags: [playwright, docker-compose, postgres, preview-custody]
requires:
  - phase: 243-integrated-evidence-and-feedback-preview
    provides: Existing evidence workflow and Fake-backed host preview contract
provides:
  - Reusable custody preflight and authoritative preview-state snapshot around verifier wrappers
  - Fresh and warm Fake preview browser proof with operator navigation
  - Isolated host/admin build outputs and explicit dev-boot database identity
affects: [243-03, host-verification, preview-operations]
actuals:
  tokens: 10195
  tasks: 3
  commits: 4
tech-stack:
  added: []
  patterns: [custody preflight before mutation, authoritative read-only database snapshot, per-run build output isolation]
key-files:
  created:
    - examples/accrue_host/e2e/phase243-preview-preservation.spec.js
    - scripts/ci/accrue_host_preview_custody.sh
    - scripts/ci/test_accrue_host_preview_custody.mjs
  modified:
    - examples/accrue_host/README.md
    - examples/accrue_host/e2e/global-setup.js
    - examples/accrue_host/config/dev.exs
    - examples/accrue_host/playwright.config.js
    - scripts/ci/accrue_host_verify_browser.sh
    - scripts/ci/accrue_host_verify_dev_boot.sh
decisions:
  - Keep preview recovery and verifier proof in separate Compose projects, databases, ports, and build directories.
  - Use an exact read-only database JSON snapshot for invoice, audit, webhook, and dispatch preservation checks.
  - Preserve Plan 243-01's accepted Linux evidence and status while recording Plan02 execution evidence.
requirements-completed: [EVR-04]
coverage:
  - id: D1
    description: Custody checks reject preview aliases before direct setup or wrapper mutations and isolate browser/dev proof targets.
    requirement: EVR-04
    verification:
      - kind: unit
        ref: scripts/ci/test_accrue_host_preview_custody.mjs (11 controls)
        status: pass
    human_judgment: false
  - id: D2
    description: Fresh Fake preview boots and warm skip-seed recovery preserves authoritative state while authenticated operator routes remain usable.
    requirement: EVR-04
    verification:
      - kind: e2e
        ref: CI=1 npm --prefix examples/accrue_host run e2e -- e2e/phase243-preview-preservation.spec.js --project=chromium-desktop --workers=1
        status: pass
    human_judgment: false
  - id: D3
    description: Complete verifier wrappers pass with the authoritative preview snapshot unchanged.
    requirement: EVR-04
    verification:
      - kind: e2e
        ref: cd examples/accrue_host && mix verify.full
        status: pass
    human_judgment: false
  - id: D4
    description: Direct Playwright invocation accepts only its own server and the Phase234 customer journey returns to its exact scoped origin while restoring action focus.
    requirement: EVR-04
    verification:
      - kind: e2e
        ref: direct Phase234 spec run 6721 with chromium-desktop and one worker (2 tests)
        status: pass
    human_judgment: false
duration: 173min
completed: 2026-10-10
status: complete
human_judgment: false
plan_head_before: bc37538659ee75d575813c8fddbfeeb3f74a72f8
plan_head_after: b93d15404a8e6426fe858ab5bc55ce7f705eeee2
---

# Phase 243 Plan 02: Integrated Evidence and Feedback Preview Summary

**Fresh and warm Fake `/admin` preview works with isolated verifier targets, direct browser ownership proof, and complete verifier acceptance.**

## Performance

- **Duration:** about 173 minutes, including the resumed direct-custody and final acceptance work
- **Tasks:** 3 implementation tasks completed, including the acceptance repair
- **Files modified:** 17 plan-owned source, test, documentation, and metadata files

## Accomplishments

- Added a fail-closed custody preflight shared by verifier wrappers, Playwright config, and global setup. It checks effective host/database/connection, Compose identity/volume, listener ownership, and build paths before mutations.
- Isolated dev boot in `accrue_host_dev_boot_proof`; browser and admin asset compilation now use per-proof build directories.
- Booted a fresh dedicated preview Compose project `accrue-host-phase243-preview`, selected `Accrue.Processor.Fake`, authenticated the operator, and exercised `/admin`, invoice list/detail, and Events search at `http://accrue-host-phase243-preview.localhost/admin`.
- Recreated that preview with `ACCRUE_HOST_SKIP_SEEDS=1`; the stable URL remained reachable and the seeded invoice, audit, webhook, and Oban dispatch JSON snapshot was identical. The dedicated preview's loopback port changed from 52221 to 53577 across the warm restart.
- Wrapped browser and dev verifier runs with an authoritative read-only preview snapshot and cleanup comparison. The full verifier's outer and inner preservation assertions passed.
- Direct Playwright invocation now recognizes only the exact listener PID created by its private, per-run server marker; worker config reload retains the marker until global teardown. Collision, foreign PID, and multi-owner controls reject before mutation.
- Repaired the named Phase234 E2E: its customer return link now asserts the approved “Back to customers” label and exact customer destination; its subscription assertion follows the customer-linked subscription. The step-up modal now restores focus to the unique visible confirmation button.
- Restored the pre-existing Phase 240 screenshot and manifest evidence files after full-suite browser tests regenerated them; removed the one newly generated evidence image so prior evidence destinations remain as they were.

## Runtime Target Evidence

| Segment | Effective target observed | Evidence |
|---|---|---|
| Preview | Compose project `accrue-host-phase243-preview`; volume `accrue-host-phase243-preview_pgdata`; DB `accrue_host_dev`; stable host `accrue-host-phase243-preview.localhost`; final loopback port 56466 | Docker Compose identity, startup output, ready checks, authenticated Playwright navigation |
| Browser proof | Native PostgreSQL host `localhost`; DB `accrue_host_test`; isolated Playwright listener port 4101; per-run host/admin build directories | custody preflight, direct Phase234 run 2/2, complete wrapper |
| Dev boot proof | Native PostgreSQL host `localhost`; DB `accrue_host_dev_boot_proof`; listener port 4100; per-run project-local dev build directory | complete `mix verify.full`, dev boot logs, cleanup snapshot assertion |

The native development database data-only dump SHA256 remained `f221026bfbfb92bf81f99b02c4f876a3c82fc13cb123db1f2eaa86ff9a1f69bd`, matching its pre-run baseline. The default `accrue-host_pgdata` volume was never targeted by a service or mutation. The original relative-path `postgres:15-alpine`, `LC_ALL=C` fingerprint procedure returned `1ac3e6523efe8aeb912b163f583d53fe380d9376bf8c64d3ac157dda54d290e6` both initially and after verification/reboot, resolving the earlier mismatch; `4cf4aab0...` came from a different image/path/sort procedure and was incomparable. The dedicated preview's authoritative before/after snapshot remained identical.

## Task Commits

1. **Task 1: Guard whole-command proof custody before mutation** - `5ceab3c5` (feat)
2. **Task 2: Prove fresh preview and warm preservation** - `9eace18f` (feat)
3. **Task 3: Prove the complete verifier remains separate** - `de9e4d5d` (fix)
4. **Acceptance repair: direct custody and named Phase234 E2E** - `b93d1540` (fix)

Plan metadata commits: `f1045971` and `f64a06e2` (original status/self-check records); `b93d1540` contains the final acceptance repair. The final canonical summary/state update follows in the metadata commit.

## Files Created/Modified

- `scripts/ci/accrue_host_preview_custody.sh` - Target preflight and authoritative snapshot/assert-preserved owner.
- `scripts/ci/accrue_host_verify_browser.sh` and `scripts/ci/accrue_host_verify_dev_boot.sh` - Custody snapshots, target isolation, and cleanup assertions.
- `scripts/ci/test_accrue_host_preview_custody.mjs` - Eleven positive, collision, direct ownership, and wrapper-order controls.
- `examples/accrue_host/playwright.config.js` and `e2e/global-setup.js` - Private direct-server PID proof, preflight before fixture/database work, and teardown cleanup.
- `examples/accrue_host/config/dev.exs` - Explicit proof-only dev database override.
- `examples/accrue_host/e2e/phase243-preview-preservation.spec.js` - Fresh/warm preview and authenticated route proof.
- `examples/accrue_host/e2e/phase237-admin-billing.spec.js` and `phase238-admin-events-webhooks.spec.js` - Resolve compiled asset paths under isolated build outputs.
- `examples/accrue_host/README.md` - Fresh startup, warm recovery, URL, and operator navigation guidance.

## Decisions Made

- Kept runtime proof on an isolated Compose project and native proof databases so the pre-existing preview volume and databases were not used for mutations.
- Compared complete row JSON for the seeded invoice and related audit, webhook, and dispatch records instead of treating a successful HTTP response as preservation evidence.
- Marked EVR-04 complete after fresh/warm preview evidence and the complete verifier passed with human judgment false.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed missing Node `os` import in direct Playwright setup.**
- **Found during:** Task 2
- **Issue:** Direct config failed while constructing temporary output paths.
- **Fix:** Added the missing built-in module import.
- **Files modified:** `examples/accrue_host/e2e/global-setup.js`
- **Verification:** Direct Playwright preservation run passed.
- **Committed in:** `9eace18f`

**2. [Rule 3 - Blocking] Kept isolated Mix build outputs inside the project checkout.**
- **Found during:** Task 3
- **Issue:** A `/tmp` build path resolved through macOS `/private/tmp` and broke relative symlinks in compiled dependencies.
- **Fix:** Use ignored per-proof directories within each Mix project and make asset checks follow the active build path.
- **Files modified:** verifier wrappers, Playwright config, Phase 237 and 238 specs
- **Verification:** full wrapper advanced through host tests, dev boot, and Playwright execution.
- **Committed in:** `de9e4d5d`

**3. [Rule 3 - Blocking] Refreshed stale dependency checkouts from existing lockfiles.**
- **Found during:** Task 3
- **Issue:** Existing checked-out `hackney`/`idna` sources did not match the locked versions; dependency compilation failed before verification.
- **Fix:** Refreshed source checkouts with `mix deps.get --force` in the host and admin projects; lockfiles and dependency identities were unchanged.
- **Verification:** `mix verify.full` advanced to the browser suite.
- **Committed in:** No lockfile or source change was committed for this environment refresh.

**4. [Rule 1 - Bug] Completed direct-run custody and Phase234 acceptance.**
- **Found during:** Task 3 acceptance continuation
- **Issue:** Direct Playwright worker reload could not establish ownership of its own listener; the named journey also contained a stale return label, an unrelated first-row subscription selection, and missing step-up focus restoration.
- **Fix:** Use a private run-scoped PID marker created by the server command and removed at global teardown; preserve foreign and multi-owner collision rejection. Assert the current scoped customer return link, follow that customer's related subscription, and restore modal focus to a unique visible confirmation control.
- **Files modified:** `scripts/ci/accrue_host_preview_custody.sh`, `examples/accrue_host/playwright.config.js`, `examples/accrue_host/e2e/global-setup.js`, `scripts/ci/test_accrue_host_preview_custody.mjs`, `examples/accrue_host/e2e/phase234-admin-customers-subscriptions.spec.js`, `accrue_admin/lib/accrue_admin/live/subscription_live.ex`
- **Verification:** Custody controls 11/11, direct Phase234 spec 2/2, full `mix verify.full` exit 0 with preview preserved.
- **Commit:** `b93d1540`

### Acceptance Failures and Resolutions

The first complete wrapper run exited 1 after 36 browser tests passed and 17 were skipped; Phase234 expected stale “Back to results” text although the approved customer-specific return label is “Back to customers.” The first direct focused run then exposed a stale first-row subscription selection and a real step-up focus restoration gap. The spec now follows the customer-linked subscription and checks exact return destination; `SubscriptionLive` supplies a unique visible focus-return target. A direct focused rerun passed 2/2. An initial focused attempt under the sandbox could not launch Chromium; the authorized unsandboxed test run passed.

Several earlier wrapper attempts stopped before completion because of Hex cache permissions, a reboot-stopped preview, Node 26 instead of required Node 22, and npm cache permissions. Private caches, Node 22, and the preserved dedicated preview resolved those environment blockers. One temporary marker cleanup ordering bug was caught by worker config reload and fixed before final acceptance. Final `mix verify.full` exited 0; browser tests completed with no failures, the Braintree browser lane passed 14/14, allowed existing skips were unchanged, and the preview snapshot assertion passed.

**Total deviations:** 4 auto-fixed blockers/acceptance defects; all acceptance blockers resolved.

## Verification

- `node scripts/ci/test_accrue_host_preview_custody.mjs`: 11/11 pass.
- Fresh and warm dedicated-preview E2E: 1/1 pass, including authenticated route checks and exact snapshot comparison.
- Direct named Phase234 Playwright run: 2/2 pass, including exact customer return URL and focus restoration.
- `mix verify.full`: exit 0; complete wrapper pass, Braintree lane 14/14, preview snapshot preserved.
- Native development DB checksum matched baseline; exact-procedure default-volume fingerprint matched its initial value.
- `git diff --check` and shell wrapper syntax checks passed.

## Next Phase Readiness

Plan 243-03 can use the custody preflight and runtime evidence. Plan 243-02 is complete; the phase remains in progress for Plan 243-03.

---
*Phase: 243-integrated-evidence-and-feedback-preview*
*Completed: 2026-10-10*

## Self-Check: PASSED

The summary and preservation spec exist, and task commits `5ceab3c5`, `9eace18f`, `de9e4d5`, and `b93d1540` plus metadata commits `f1045971` and `f64a06e2` are ancestors of the current branch head.
