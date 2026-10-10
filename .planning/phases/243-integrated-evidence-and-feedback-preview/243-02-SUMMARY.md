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
  commits: 3
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
  - Preserve the existing halted Plan 243-01 state while recording this plan's execution evidence.
requirements-completed: []
coverage:
  - id: D1
    description: Custody checks reject preview aliases before direct setup or wrapper mutations and isolate browser/dev proof targets.
    requirement: EVR-04
    verification:
      - kind: unit
        ref: scripts/ci/test_accrue_host_preview_custody.mjs (10 controls)
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
    description: Complete verifier wrappers preserve the preview snapshot, with one unrelated existing Phase 234 browser assertion failing.
    requirement: EVR-04
    verification:
      - kind: e2e
        ref: cd examples/accrue_host && mix verify.full
        status: fail
    human_judgment: false
duration: 80min
completed: 2026-10-10
status: halted
human_judgment: false
plan_head_before: bc37538659ee75d575813c8fddbfeeb3f74a72f8
plan_head_after: de9e4d5d4571677a053abf66a8321703ce3608c1
---

# Phase 243 Plan 02: Integrated Evidence and Feedback Preview Summary

**Fresh and warm Fake `/admin` preview works with isolated verifier targets and exact invoice/audit/dispatch preservation checks; the complete verifier remains halted on an unrelated existing Phase 234 browser failure.**

## Performance

- **Duration:** about 80 minutes
- **Tasks:** 3 implementation tasks executed; complete-wrapper acceptance is halted on a failing existing test
- **Files modified:** 11 plan-owned source, test, and documentation files

## Accomplishments

- Added a fail-closed custody preflight shared by verifier wrappers, Playwright config, and global setup. It checks effective host/database/connection, Compose identity/volume, listener ownership, and build paths before mutations.
- Isolated dev boot in `accrue_host_dev_boot_proof`; browser and admin asset compilation now use per-proof build directories.
- Booted a fresh dedicated preview Compose project `accrue-host-phase243-preview`, selected `Accrue.Processor.Fake`, authenticated the operator, and exercised `/admin`, invoice list/detail, and Events search at `http://accrue-host-phase243-preview.localhost/admin`.
- Recreated that preview with `ACCRUE_HOST_SKIP_SEEDS=1`; the stable URL remained reachable and the seeded invoice, audit, webhook, and Oban dispatch JSON snapshot was identical. The dedicated preview's loopback port changed from 52221 to 53577 across the warm restart.
- Wrapped browser and dev verifier runs with an authoritative read-only preview snapshot and cleanup comparison. The full verifier's outer and inner preservation assertions passed.
- Restored the pre-existing Phase 240 screenshot and manifest evidence files after full-suite browser tests regenerated them; removed the one newly generated evidence image so prior evidence destinations remain as they were.

## Runtime Target Evidence

| Segment | Effective target observed | Evidence |
|---|---|---|
| Preview | Compose project `accrue-host-phase243-preview`; volume `accrue-host-phase243-preview_pgdata`; DB `accrue_host_dev`; stable host `accrue-host-phase243-preview.localhost`; loopback port 52221 fresh / 53577 warm | `docker volume inspect`, startup output, ready checks, authenticated Playwright navigation |
| Browser proof | Native PostgreSQL host `localhost`; DB `accrue_host_test`; isolated Playwright listener port 4199 because incumbent port 4101 was occupied; project-local per-run host and admin build directories | custody output, collision rejection, full wrapper run, Playwright report |
| Dev boot proof | Native PostgreSQL host `localhost`; DB `accrue_host_dev_boot_proof`; listener port 4100; per-run project-local dev build directory | complete `mix verify.full`, dev boot logs, cleanup snapshot assertion |

The native development database data-only dump SHA256 remained `f221026bfbfb92bf81f99b02c4f876a3c82fc13cb123db1f2eaa86ff9a1f69bd`, matching its pre-run baseline. The default `accrue-host_pgdata` volume was only mounted read-only for inspection and was never targeted by the isolated preview. Its aggregate read-only file hash from the final check was `4cf4aab0b66c433e5abbb0c1d33a6965c8e74fd3e95733306cc9dc7946c23e5a`, which differs from the earlier recorded `1ac3e6523efe8aeb912b163f583d53fe380d9376bf8c64d3ac157dda54d290e6`; the exact prior fingerprint procedure could not be reproduced, so that historical comparison remains unresolved. The preview instance used for acceptance had an identical before/after authoritative DB snapshot.

## Task Commits

1. **Task 1: Guard whole-command proof custody before mutation** - `5ceab3c5` (feat)
2. **Task 2: Prove fresh preview and warm preservation** - `9eace18f` (feat)
3. **Task 3: Prove the complete verifier remains separate** - `de9e4d5d` (fix)

The plan metadata commit is pending.

## Files Created/Modified

- `scripts/ci/accrue_host_preview_custody.sh` - Target preflight and authoritative snapshot/assert-preserved owner.
- `scripts/ci/accrue_host_verify_browser.sh` and `scripts/ci/accrue_host_verify_dev_boot.sh` - Custody snapshots, target isolation, and cleanup assertions.
- `scripts/ci/test_accrue_host_preview_custody.mjs` - Ten positive, collision, and wrapper-order controls.
- `examples/accrue_host/playwright.config.js` and `e2e/global-setup.js` - Direct invocation preflight before fixture or database work.
- `examples/accrue_host/config/dev.exs` - Explicit proof-only dev database override.
- `examples/accrue_host/e2e/phase243-preview-preservation.spec.js` - Fresh/warm preview and authenticated route proof.
- `examples/accrue_host/e2e/phase237-admin-billing.spec.js` and `phase238-admin-events-webhooks.spec.js` - Resolve compiled asset paths under isolated build outputs.
- `examples/accrue_host/README.md` - Fresh startup, warm recovery, URL, and operator navigation guidance.

## Decisions Made

- Kept runtime proof on an isolated Compose project and native proof databases so the pre-existing preview volume and databases were not used for mutations.
- Compared complete row JSON for the seeded invoice and related audit, webhook, and dispatch records instead of treating a successful HTTP response as preservation evidence.
- Preserved Plan 243-01's halted tracking and did not mark EVR-04 complete because complete-wrapper verification exited non-zero.

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

### Deferred Existing Issue

`mix verify.full` exited 1 after 36 browser tests passed and 17 were skipped. The existing Phase 234 test “served Admin journeys preserve scope, focus, reflow, theme and asset provenance” failed because the expected “Back to results” link was absent after navigating to a related subscription, while the URL retained `return_to`. This is outside Plan 243-02's changes and is recorded in `deferred-items.md`; no unrelated application behavior was changed.

**Total deviations:** 3 auto-fixed blockers plus 1 deferred pre-existing issue.

## Verification

- `node scripts/ci/test_accrue_host_preview_custody.mjs`: 10/10 pass.
- Fresh and warm dedicated-preview E2E: 1/1 pass, including authenticated route checks and exact snapshot comparison.
- `mix verify.full`: failed overall on the existing Phase 234 browser assertion above. Dev-boot completed, 36 browser tests passed, 17 skipped, and the preview snapshot assertions passed.
- Native development DB checksum matched baseline. Historical default-volume aggregate checksum comparison is unresolved as recorded above.
- `git diff --check` and shell wrapper syntax checks passed.

## Next Phase Readiness

Plan 243-03 can use the custody preflight and runtime evidence. Plan 243-02 remains halted until the Phase 234 failure and default-volume fingerprint comparison are resolved or independently explained, then the full verifier must pass.

---
*Phase: 243-integrated-evidence-and-feedback-preview*
*Completed: 2026-10-10*

## Self-Check: PASSED

The summary and preservation spec exist, and task commits `5ceab3c5`, `9eace18f`, and `de9e4d5d` are ancestors of the current branch head.
