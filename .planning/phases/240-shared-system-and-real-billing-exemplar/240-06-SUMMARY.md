---
phase: 240-shared-system-and-real-billing-exemplar
plan: "06"
subsystem: testing
tags: [admin, evidence-ledger, asset-provenance, playwright]
requires: [240-01, 240-02, 240-03, 240-04, 240-05]
provides: [current-admin-route-owner-ledger, deterministic-phase240-evidence-cli, mounted-admin-asset-provenance]
affects: [phase-240-verification, phase-237-mounted-admin-owner]
tech-stack:
  added: []
  patterns: [consume-incumbent-route-and-component-authorities, compare-package-compiled-served-bytes, native-junit-red-evidence]
key-files:
  created:
    - .planning/phases/240-shared-system-and-real-billing-exemplar/240-COVERAGE.md
    - scripts/ci/verify_phase240_evidence.mjs
    - .planning/phases/240-shared-system-and-real-billing-exemplar/captures/phase237-exemplar/manifest.json
  modified:
    - examples/accrue_host/e2e/phase237-admin-billing.spec.js
    - .planning/phases/240-shared-system-and-real-billing-exemplar/240-VALIDATION.md
    - .planning/phases/240-shared-system-and-real-billing-exemplar/deferred-items.md
decisions:
  - Use Phase 239 route authority and live ComponentRegistry APIs rather than adding a second route or component registry.
  - Keep first-fresh performance values diagnostic only and keep future behavior guarded by existing owner tests.
  - Preserve the existing host TrustSmoke timing budget and record its independent failure for owner follow-up.
requirements-completed: [DSN-01, DSN-02, DSN-03, DSN-04, DSN-05, UXC-02, EVR-01, EVR-02]
metrics:
  duration: "15 min"
  completed_date: "2026-10-09"
  tasks: 2
  files: 12
status: complete
actuals:
  tokens: 17154
  tasks: 2
  commits: 3
commits: 3
plan_head_before: ec9436e3e42be0d5298de3499278265baec76d56
plan_head_after: b10ff3c00c741328db9404d1a022a8072e8d1fe5
coverage:
  - id: D1
    description: Current Admin route, state and acceptance-owner inventory with route omission rejection.
    requirement: EVR-01
    verification:
      - kind: other
        ref: node scripts/ci/verify_phase240_evidence.mjs --self-test .planning/phases/240-shared-system-and-real-billing-exemplar/240-COVERAGE.md
        status: pass
    human_judgment: false
  - id: D2
    description: Mounted host Admin proof binds package, compiled and served CSS, JS and Geist fonts and restores after stale-response rejection.
    requirement: EVR-02
    verification:
      - kind: e2e
        ref: examples/accrue_host/e2e/phase237-admin-billing.spec.js#Phase 237 served invoice and recovery journeys stay scoped and read-only
        status: pass
    human_judgment: false
  - id: D3
    description: Requirement owners and evidence limits distinguish mounted, historical and source-only coverage.
    verification:
      - kind: other
        ref: .planning/phases/240-shared-system-and-real-billing-exemplar/240-COVERAGE.md
        status: pass
    human_judgment: false
---

# Phase 240 Plan 06: Current Evidence Ledger Summary

**A live-authority-backed Admin route ledger and a mounted host asset manifest now tie package, compiled and served CSS/JS/font bytes to the exercised invoice exemplar.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-10-09T22:41:00Z
- **Completed:** 2026-10-09T22:55:44Z
- **Tasks:** 2/2
- **Files modified:** 9

## Accomplishments

- Recorded all 21 production Admin LiveView routes in six route families with state applicability, owner test paths, recurring acceptance lanes and explicit `exercised`, `source-only` or `historical` evidence labels.
- Kept the incumbent ComponentRegistry authoritative: the verifier reads its current 30-family/42-variant/8-group counts and checks the separate live 43-file source component inventory.
- Added a Node CLI that resolves route expectations from the Phase 239 route ledger, validates all eight requirements and owner/state fields, checks unique route and owner identities, and rejects a disposable ledger copy missing a required route.
- Extended the existing Phase 237 host browser owner to compare package-built, host-compiled and served CSS, JavaScript and loaded Geist/Geist Mono font bytes; it deliberately serves a stale JS response, verifies digest rejection, removes the interceptor and proves the restored bytes match.
- Captured source and package-lock fingerprints, fixture/scope, route/query/action review, stored/effective theme, viewport/pointer mode, Chromium/macOS/Node runner, cold/warm readiness, resource sizes, interaction timing, layout-shift and long-task availability in [the mounted manifest](captures/phase237-exemplar/manifest.json), with four inspectable screenshots.
- Reconciled validation status without claiming actual 400% browser zoom, Linux pixel execution, remote CI success, or original 240-03 RED timing.

## Task Commits

| Task | Name | Commit | Files |
|---|---|---|---|
| 1 | Derive current route/state and acceptance-owner ledger | `e805cbef` | `240-COVERAGE.md`, `scripts/ci/verify_phase240_evidence.mjs` |
| 2 RED | Add failing mounted asset assertion and capture JUnit evidence | `e24e1082` | `phase237-admin-billing.spec.js`, `240-06-red-evidence.json` |
| 2 GREEN | Bind package and served assets to mounted evidence | `b10ff3c0` | Phase 237 owner, current ledger, manifest and four screenshots |

## Verification

- `node scripts/ci/verify_phase240_evidence.mjs --self-test .planning/phases/240-shared-system-and-real-billing-exemplar/240-COVERAGE.md` — passed and printed `self-test: valid=1 missing-route-rejected=1`.
- `node scripts/ci/verify_phase240_evidence.mjs .planning/phases/240-shared-system-and-real-billing-exemplar/240-COVERAGE.md` — passed: 21 routes, 8 requirements, live registry 30/42/8, 43 source component modules.
- `npm_config_cache=/private/tmp/accrue240-npm-cache mix accrue_admin.assets.build` — passed.
- `MIX_ENV=test mix compile --warnings-as-errors` in `examples/accrue_host` — passed.
- `CI=1 npx playwright test e2e/phase237-admin-billing.spec.js --project=chromium-desktop` — final run passed 1/1. Package/compiled/served SHA-256s matched for all four assets; the intentionally stale JS response failed its digest assertion and the restored response matched again.
- `GSD_RUNTIME=codex gsd_run check tdd-red-evidence .planning/phases/240-shared-system-and-real-billing-exemplar/240-06-red-evidence.json --raw` — returned `RED_EVIDENCE_OK` / `target_test_failed` for the named mounted test. The actual unchanged JUnit report remains at `/private/tmp/24006-red-asset.xml`; its project record explicitly contains a privacy-safe path-redacted report copy, not the unchanged report.
- Initial `HEX_HOME=/private/tmp/accrue240-hex MIX_ENV=test mix verify.full` — existing `AccrueHostWeb.TrustSmokeTest` measured webhook ingest at 222ms against its 100ms budget.
- One unchanged diagnostic `mix verify.full` rerun on 2026-10-09 resolved pinned dependencies and stopped in the bounded ExUnit stage with `223 tests, 1 failure`; later compile, regression, dev-boot and browser stages did not run. The captured tool output omitted the detailed failure block and no native JUnit/report file or sanitized report copy was produced, so no second latency or failure identity is asserted. The timed interval itself covers `Plug.Test.conn` + `Router.init`/`Router.call` and database work, excluding fixture setup and suite startup. No threshold was changed; disposition and owner path are recorded in `deferred-items.md`.
- The existing Admin full ExUnit owner (617 tests, 0 failures) and Phase 191 lifecycle owner (26 tests, 0 failures) are prior Wave 3 results in `240-WAVE-GATES.md`; this plan did not rerun those suites. Linux pixel comparison remains locally unrun on macOS.

## TDD Gate Compliance

- **RED:** The Playwright test ran in Chromium against the disposable host fixture. A route interceptor changed the first byte of the mounted JS response; the exact test failed on `served response differs from package build`. Native JUnit recorded 1 test, 1 failure, no setup/load error. The JSON record passed the required classifier and semantic inspection before GREEN.
- **GREEN:** The owner asserts equality for package, compiled host and browser-served bytes, detects the isolated stale response, restores the route and asserts the restored digest. The final mounted run passed.
- **REFACTOR:** No separate cleanup commit was needed.
- **Commit order:** RED `e24e1082` precedes GREEN `b10ff3c0`.

## Decisions Made

- Read expected Admin route identities from the existing Phase 239 route ledger and component counts from `AccrueAdmin.Dev.ComponentRegistry`; no duplicate registry or allowlist was created.
- Keep the evidence CLI as a point-in-time validation tool rather than a recurring CI gate; recurring behavior remains protected by existing owner suites.
- Treat one-run readiness/resource figures as diagnostics, not a performance SLA. Host `/admin` is Admin, host `/billing` is Portal, and package fixture `/billing` is Admin.
- Keep `action_confirmed_or_dispatched: false` because the mounted flow opened review and did not submit an action; no absence-of-mutation claim is inferred from HTTP methods.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test assertion] Measure warm readiness from visible route content**
- **Found during:** Task 2 validation.
- **Issue:** The fresh route contains an invoice card that is hidden in the current list state, so using that card as the warm readiness target failed despite the route heading being visible.
- **Fix:** Measure warm task readiness from the visible open-receivables heading after LiveView readiness.
- **Files modified:** `examples/accrue_host/e2e/phase237-admin-billing.spec.js`.
- **Verification:** Final Phase 237 owner passed 1/1.
- **Committed in:** `b10ff3c0`.

**2. [Rule 3 - Local cache] Use task-scoped writable npm and Hex caches**
- **Found during:** Task 2 asset build and host integration verification.
- **Issue:** Default user caches rejected writes (`npm` cache ownership error; Hex registry `:eaccess`).
- **Fix:** Reran with `/private/tmp/accrue240-npm-cache` and `HEX_HOME=/private/tmp/accrue240-hex`; locked dependencies were unchanged.
- **Files modified:** None.
- **Verification:** Package asset build and host `verify.full` progressed using the task-scoped caches.
- **Commit:** Not applicable.

### Deferred Issues

- Host `verify.full` remains open after its unchanged diagnostic rerun: the bounded suite reported 223 tests and 1 failure, but the captured output did not preserve the detailed failure block. This task did not edit the smoke assertion, its 100ms budget or backend behavior. The existing automated owner path and required evidence capture are recorded in `deferred-items.md`.
- Actual 400% browser zoom and local Linux pixel comparison remain unavailable; Phase 243 owns final reviewed Linux goldens.

**Total deviations:** 2 auto-fixed (1 Rule 1 test assertion, 1 Rule 3 cache blocker); 1 unrelated host integration failure deferred. **Impact:** The planned current ledger and mounted asset evidence are complete; the broader host suite's independent timing failure remains visible and unchanged.

## Issues Encountered

- The first sandboxed Chromium launch was denied by macOS Mach rendezvous and did not execute the test. The authorized process-permission rerun reached the mounted assertion and supplied valid RED evidence.
- The initial npm cache and default Hex cache paths were unwritable; task-scoped caches resolved those environment blockers without package substitution or lockfile changes.

## Known Stubs

None. The ledger distinguishes unavailable evidence and N/A states with explicit rationale rather than placeholder proof.

## Threat Flags

None. The change adds no endpoint, authorization path, schema, or non-test file-access surface; it compares existing static asset responses and records test evidence.

## Next Phase Readiness

- All eight Phase 240 requirements are mapped to existing recurring owners and current evidence statuses.
- Phase 240 remains open for the parent's independent gates. No Phase 241–243 deferred journey or final-golden scope was pulled forward.

---
*Phase: 240-shared-system-and-real-billing-exemplar*
*Completed: 2026-10-09*

## Self-Check: PASSED

- Summary and current evidence ledger exist.
- Evidence verifier and mounted capture manifest exist.
- Task commits `e805cbef`, `e24e1082` and `b10ff3c0` are ancestors of HEAD.

## Parent final acceptance and review follow-up

- **Follow-up task commit:** `9eaa9cc1` — existing Phase 234 browser evidence roots/price-versus-amount assertions, archived Phase 239 route and docs owners, and restored inherited-size type exception annotations. Source paths: `examples/accrue_host/e2e/phase234-admin-customers-subscriptions.spec.js`, `examples/accrue_host/e2e/phase234-post-layout.spec.js`, `examples/accrue_host/test/accrue_host_web/phase239_route_coverage_contract_test.exs`, `scripts/ci/verify_package_docs.sh`, `accrue_admin/assets/css/app.css`.
- Final host gate exited 0 (64 bounded, 223 full, dev boot, 37 default browser / 16 incumbent skips, 14 checkout browser checks). This resolves the historical deferred full-gate item above without changing its original observation or the 100ms smoke budget.
- Admin full suite 618/0; Node 41/0; package browser bundle 89 passed / 19 incumbent skips / 0 failures; ledger valid and missing-route negative passed; eight-baseline and docs/contrast guards passed.
- Review fixes `5623c421`, `b0336989`, `25af07fa` and their evidence/disposition are recorded in `240-REVIEW-FIX.md` and `240-REVIEW-DISPOSITION.md`.
- Current refreshed screenshots and manifest replace the earlier point-in-time exemplar. Native report privacy copies and final results are explicitly labeled under `captures/final-gates/`; raw native reports remain in task temporary storage. Original timing/report limitations remain disclosed.
