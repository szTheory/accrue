---
phase: 243-integrated-evidence-and-feedback-preview
plan: 03
subsystem: testing
tags: [playwright, asset-provenance, preview-custody, evidence-ledger]
requires:
  - phase: 243-integrated-evidence-and-feedback-preview
    provides: Reviewed Linux baselines and isolated Fake preview with preservation evidence
provides:
  - Fresh mounted package/compiled/HTTP/browser CSS and JS identity with stale-response negative control
  - Additive Phase 243 evidence in the existing 21-route Phase 240 ledger
  - Integrated preview handoff with explicit current evidence limits and open custody gap
affects: [EVR-03, EVR-04, preview-operations, admin-evidence]
actuals:
  tokens: 5290
  tasks: 2
  commits: 2
  plan_head_before: f3b9a7a715832a71f4a4925bea1f985b5898c5af
  plan_head_after: 06f9053edd48daff35699390c20b2780e36ebe3e
tech-stack:
  added: []
  patterns: [hash actual browser response bodies, stale asset response negative control, additive route evidence]
key-files:
  created:
    - .planning/phases/243-integrated-evidence-and-feedback-preview/243-HANDOFF.md
  modified:
    - examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js
    - .planning/phases/240-shared-system-and-real-billing-exemplar/240-COVERAGE.md
    - .planning/WINDOWS.md
key-decisions:
  - "Hash the actual browser response body independently from the HTTP API request and package/compiled files."
  - "Preserve the existing Phase 240 route and component registry as the sole inventory authority."
  - "Leave the unrelated broken-logo source unchanged after the current mounted host screenshot showed a working wordmark."
requirements-completed: [EVR-03, EVR-04]
coverage:
  - id: D1
    description: Corrected CSS and JS bytes agree across package, host compile, HTTP, and browser; stale CSS is rejected and the restored response is accepted.
    requirement: EVR-04
    verification:
      - kind: e2e
        ref: "CI=1 npm --prefix examples/accrue_host run e2e -- e2e/phase238-admin-events-webhooks.spec.js --project=chromium-desktop --workers=1 (2 passed)"
        status: pass
      - kind: integration
        ref: "MIX_ENV=test mix accrue_admin.assets.build (passed; CSS SHA-256 089878ed3cba5377be66c12c1958d728873d327c4666c7ec293e21cc8188633e)"
        status: pass
    human_judgment: false
  - id: D2
    description: Current changed-consumer evidence is additive to the 21-route ledger and the handoff identifies present evidence and limits.
    requirement: EVR-03
    verification:
      - kind: other
        ref: "node scripts/ci/verify_phase240_evidence.mjs .planning/phases/240-shared-system-and-real-billing-exemplar/240-COVERAGE.md (21 routes; registry 30/42/8)"
        status: pass
      - kind: other
        ref: "node scripts/ci/verify_phase240_evidence.mjs --self-test .planning/phases/240-shared-system-and-real-billing-exemplar/240-COVERAGE.md (valid=1 missing-route-rejected=1)"
        status: pass
    human_judgment: false
duration: 10min
completed: 2026-10-10
status: complete
human_judgment: false
---

# Phase 243 Plan 03: Integrated Evidence and Preview Handoff Summary

**Mounted CSS proof now hashes browser response bytes and the existing 21-route ledger records current Phase 243 owners and preview limits.**

## Performance

- **Duration:** about 10 minutes
- **Started:** 2026-10-10T21:13:20Z
- **Completed:** 2026-10-10T21:23:30Z
- **Tasks:** 2
- **Plan files modified:** 4, including the broken-windows entry for the open custody gap

## Accomplishments

- Extended the incumbent Phase238 host owner to hash the package-built, host-compiled, HTTP-served, and actual browser response bodies for CSS and JS. Added an intercepted altered-CSS negative control, verified that the identity assertion rejects it, and confirmed the original response hash after removing interception.
- Exercised the corrected invoice action band on the mounted host: computed gap `4px`, with `--ax-space-xs` set to `0.25rem`. The focused desktop Phase238 command passed both tests.
- Added current Phase243 owners to the existing Phase240 coverage ledger without changing its 21 production route rows or the separate component registry counts of 30 families, 42 variants, and 8 groups. The normal ledger verifier and missing-route negative control both passed.
- Created a maintainer handoff linked to the existing README preview instructions. It records the Fake preview entry, optional external feedback boundaries, provenance, local/remote and emulated/physical limits, and the pending generic preview URL routing gap.
- Inspected the current mounted screenshot. The sidebar displays the Accrue mark and wordmark without a broken-image indicator; the earlier `example.test/logo.svg` observation came from a different disposable package fixture, so no logo code was changed.

## Task Commits

1. **Task 243-03-01: Observe corrected CSS at the mounted host HTTP and browser boundary** — `e4ba82cf` (test)
2. **Task 243-03-02: Reconcile the 21-route inventory and close the bounded handoff** — `06f9053e` (docs)

## Files Created/Modified

- `examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js` — captures browser response bytes, checks package identity and corrected invoice spacing, and rejects/restores altered CSS.
- `.planning/phases/240-shared-system-and-real-billing-exemplar/240-COVERAGE.md` — additive current Phase243 owners, provenance, route applicability and evidence limits.
- `.planning/phases/243-integrated-evidence-and-feedback-preview/243-HANDOFF.md` — preview and integrated evidence handoff.
- `.planning/WINDOWS.md` — open deviation tracking the generic preview URL routing/custody gap for root remediation.

## Verification and Provenance

- `MIX_ENV=test mix accrue_admin.assets.build` passed with Node 22.14.0 and the existing dependency lock. CSS source SHA-256: `6d6af462d2b1f9717ba5fae6f5aba8a3703978be3f49e1c21f2b930ae25e62dc`.
- `CI=1 npm --prefix examples/accrue_host run e2e -- e2e/phase238-admin-events-webhooks.spec.js --project=chromium-desktop --workers=1` passed 2/2 on checkout HEAD `f3b9a7a715832a71f4a4925bea1f985b5898c5af` with owner spec SHA-256 `07918db345530a379e084e5d5d02eae205c2be380e1f84f22b18811342ab27d6`.
- The browser fixture used the isolated native `accrue_host_test` database, owned proof listener `127.0.0.1:4183`, and per-run host/admin build paths. The preview remained on Compose project `accrue-host-phase243-preview`, database `accrue_host_dev`, volume `accrue-host-phase243-preview_pgdata`, and port 56466. Its authoritative sentinel/audit/webhook/dispatch snapshot matched before and after the successful proof.
- CSS package, compiled host, HTTP and browser bodies were 129,813 bytes and shared SHA-256 `089878ed3cba5377be66c12c1958d728873d327c4666c7ec293e21cc8188633e`. JS bodies were 161,130 bytes and shared SHA-256 `36974c751ef3c9df6f40a2ff7fa09c04d85819dac2de74804d8438f6c3be3085`. The altered CSS response SHA was `9748beceab1eb9e5b57b282e83a86410f73a4572b20ad8f4f81ef4e42ad89ec6` and failed the package identity assertion.
- `node scripts/ci/verify_phase240_evidence.mjs .planning/phases/240-shared-system-and-real-billing-exemplar/240-COVERAGE.md` passed with 21 routes and registry 30/42/8. `node scripts/ci/verify_phase240_evidence.mjs --self-test .planning/phases/240-shared-system-and-real-billing-exemplar/240-COVERAGE.md` printed `self-test: valid=1 missing-route-rejected=1`.
- The existing Linux selected visual comparison passed in run `38083267168` at source `0197f4ba`. That accepted result remains attached to its historical revision and is not represented as a post-Plan02/Plan03 same-SHA run.

## Deviations from Plan

**1. [Rule 1 - Test assertion correction] Corrected the expected custom-property serialization.**
- **Found during:** Task 243-03-01 verification
- **Issue:** The rendered gap was correctly `4px`, while the CSS token serializes as `0.25rem`; the initial new assertion incorrectly expected the token string `4px`.
- **Fix:** Kept the rendered gap assertion at `4px` and asserted the token's actual `0.25rem` value.
- **Files modified:** `examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js`
- **Verification:** Final focused run passed both tests and all asset identity assertions.
- **Commit:** `e4ba82cf`.

**2. [Rule 3 - Custody blocker surfaced] Generic preview URL routing remains open for root remediation.**
- **Found during:** Task 243-03-01 setup
- **Issue:** `ACCRUE_HOST_PREVIEW_BASE_URL` globally changes Playwright's base URL and disables its owned server, while global setup may still create/migrate/seed the native test DB. The first generic Phase238 attempt therefore posted its sandbox request to preview and failed before test bodies.
- **Fix:** The successful proof omitted the preview URL override and used the isolated proof server. The authoritative preview sentinel/audit/webhook/dispatch snapshot immediately after the failed attempt matched its captured baseline. The global config issue is left to the phase orchestrator as directed and recorded as open entry 35 in `.planning/WINDOWS.md`.
- **Files modified:** Handoff and coverage provenance; open issue recorded against `examples/accrue_host/playwright.config.js`.
- **Verification:** Immediate and post-success authoritative preview snapshot comparisons passed; the corrected direct-origin Phase238 run passed 2/2.
- **Impact:** This plan's mounted proof and handoff are complete, but phase acceptance remains pending the root-owned fail-closed routing fix and regression check.

**3. [Plan command correction] Used the existing evidence verifier's supported self-test argument order.**
- **Found during:** Task 243-03-02 verification
- **Issue:** The plan's `--self-test`-only command is parsed as a ledger file path by the existing script.
- **Fix:** Ran `node scripts/ci/verify_phase240_evidence.mjs --self-test <ledger>` as implemented by the script.
- **Verification:** `self-test: valid=1 missing-route-rejected=1`.

**Total deviations:** 3; one test assertion was corrected, one custody gap is assigned to root remediation, and one verifier invocation used its existing supported argument order.

## Issues Encountered

An initial asset-build shell selected Node 26 from the package version file; it was stopped before asset output, then the planned build passed with Node 22 first on `PATH`. The first generic browser invocation inherited the preview URL and failed before test assertions; no test body ran, and the authoritative preview snapshot was unchanged. The clean direct proof passed. No package was installed or lockfile updated.

The plan's intended red/green change was an extension to an existing test owner. Project `workflow.tdd_mode` is disabled, and no separate valid RED commit was created; the first failing run was caused by the wrong preview origin, followed by an incorrect token-string expectation. The final test and its negative control pass, but those setup failures are not presented as valid RED evidence.

## Known Stubs

None.

## Threat Flags

None. No endpoint, authentication path, filesystem trust boundary, or schema changed.

## Self-Check: PASSED

- Created handoff and task summary files exist; modified test, ledger, and broken-windows entry are present.
- Task commits `e4ba82cf` and `06f9053e` are ancestors of the current branch HEAD.
- Plan acceptance commands passed: mounted Phase238 2/2; normal Phase240 ledger verifier passed; self-test rejected the missing route as expected.
- Preview authoritative snapshot comparison passed after the failed misrouted attempt and after the successful direct proof.

## Next Phase Readiness

The mounted asset gap, additive coverage ledger, and preview handoff are complete. The phase orchestrator must resolve and retest the generic `ACCRUE_HOST_PREVIEW_BASE_URL` routing/custody gap before claiming Phase243 acceptance. Independent phase verification and ordered executable-UAT generation remain with the orchestrator.

---
*Phase: 243-integrated-evidence-and-feedback-preview*
*Completed: 2026-10-10*
