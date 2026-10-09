---
phase: "236"
slug: "portal-billing-self-service"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-08"
---

# Phase 236 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit and Phoenix LiveViewTest in `accrue_portal`; Playwright Test in `examples/accrue_host` |
| **Config file** | Existing Mix configuration and `examples/accrue_host/playwright.config.js` |
| **Quick run command** | `cd accrue_portal && mix test` |
| **Full package command** | `cd accrue_portal && mix test.ci` |
| **Served browser command** | `cd examples/accrue_host && ACCRUE_HOST_BROWSER_USE_BRAINTREE=1 npm run e2e -- --config=playwright.braintree.config.js e2e/phase236-portal-self-service.spec.js` |
| **Measured runtime** | Portal package gate: 4 seconds; served browser contract: 11.4 seconds |

---

## Sampling Rate

- **After every task commit:** Run the focused ExUnit/LiveView/controller or Playwright command listed for that task.
- **After every plan wave:** Run `cd accrue_portal && mix test.ci`; run the Phase 236 served-browser spec after wave 4 when it exists and covers the changed routes.
- **Wave 5:** Run the focused Hosted Fields browser command in default, forced-light, and forced-dark host modes; each mode must pass before validation is marked complete.
- **Before phase verification:** Run the full package command and Phase 236 served-browser spec; both must be green.
- **Max feedback latency:** Target under 5 minutes for focused checks; measure and record actual suite times during execution.

---

## Per-Task Verification Map

The planner must replace “Assigned by plan” with actual plan/task/wave IDs and update commands if the implementation chooses a narrower reliable test seam.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 236-01-T1, 236-05-T2 | 236-01, 236-05 | 1, 4 | POR-01 | T-236-01, T-236-11 | Billed entity and seven branded routes retain owner scope | LiveView + served browser | `cd accrue_portal && mix test.ci`; `cd examples/accrue_host && ACCRUE_HOST_BROWSER_USE_BRAINTREE=1 npm run e2e -- --config=playwright.braintree.config.js e2e/phase236-portal-self-service.spec.js` | Existing route tests and served phase spec | ✓ green |
| 236-02-T1, 236-03-T1 | 236-02, 236-03 | 2, 3 | POR-02 | T-236-03, T-236-06 | Every mutation re-resolves and authorizes the exact customer-owned target | LiveView/controller | `cd accrue_portal && mix test.ci` | Existing payment-method and subscription action/denial suites | ✓ green |
| 236-01-T1, 236-01-T2 | 236-01 | 1 | POR-03 | T-236-01, T-236-02 | Invoice access remains customer-scoped; failed reads are not empty results | LiveView/controller | `cd accrue_portal && mix test.ci`; `cd examples/accrue_host && ACCRUE_HOST_BROWSER_USE_BRAINTREE=1 npm run e2e -- --config=playwright.braintree.config.js e2e/phase236-portal-self-service.spec.js` | Existing invoice isolation, read-failure, and hosted-link assertions | ✓ green |
| 236-01-T2, 236-02-T1, 236-03-T1, 236-04-T1 | 236-01, 236-02, 236-03, 236-04 | 1, 2, 3 | POR-04 | T-236-05, T-236-07, T-236-10 | Displayed outcomes reflect provider/result state and uncertainty | LiveView/controller | `cd accrue_portal && mix test.ci` | Existing empty/unavailable, POST result, checkout decline/uncertainty, and announcement assertions | ✓ green |
| 236-02-T2, 236-05-T2 | 236-02, 236-05 | 2, 4 | POR-05 | T-236-04 | Payment fields stay provider-hosted; app only receives a nonce | LiveView + served browser | `cd accrue_portal && mix test.ci`; `cd examples/accrue_host && ACCRUE_HOST_BROWSER_USE_BRAINTREE=1 npm run e2e -- --config=playwright.braintree.config.js e2e/phase236-portal-self-service.spec.js` | Existing direct-route and served Hosted Fields lifecycle assertions | ✓ green |
| 236-06-T1, 236-06-T2 | 236-06 | 5 | POR-05 | T-236-13, T-236-14 | Served add-card style handoff, contrast, host locks, context-pin patch, and teardown; deterministic SDK mock does not prove live Braintree iframe rendering | Served browser | `ACCRUE_HOST_BROWSER_USE_BRAINTREE=1 npm --prefix examples/accrue_host run e2e -- --config=playwright.braintree.config.js e2e/phase236-portal-self-service.spec.js --grep 'Hosted Fields'` (3 passed); `ACCRUE_HOST_BROWSER_USE_BRAINTREE=1 ACCRUE_HOST_PORTAL_THEME=light npm --prefix examples/accrue_host run e2e -- --config=playwright.braintree.config.js e2e/phase236-portal-self-service.spec.js --grep 'Hosted Fields'` (2 passed); `ACCRUE_HOST_BROWSER_USE_BRAINTREE=1 ACCRUE_HOST_PORTAL_THEME=dark npm --prefix examples/accrue_host run e2e -- --config=playwright.braintree.config.js e2e/phase236-portal-self-service.spec.js --grep 'Hosted Fields'` (2 passed) | `examples/accrue_host/e2e/phase236-portal-self-service.spec.js` | ✓ green |
| 261008-lbv-T1/T2 | 261008-lbv | 1 | POR-05 | T-236-13, T-236-14 | Direct context-pin route remains disabled until setup is ready; post-mount ViewHook wrapper covers both pending SDK create stages, stale cleanup success/failure, theme refresh, pending theme styles, active teardown with concurrent LiveView update, and pagehide non-revival; malformed-token colors pass >=4.5:1 per actual field surface. Teardown errors fail closed with refresh guidance. Deterministic SDK mock and framework wrapper do not prove live provider iframe rendering. | Served browser | `ACCRUE_HOST_BROWSER_USE_BRAINTREE=1 npm --prefix examples/accrue_host run e2e -- --config=playwright.braintree.config.js e2e/phase236-portal-self-service.spec.js --grep 'Hosted Fields'` (10 passed); `ACCRUE_HOST_BROWSER_USE_BRAINTREE=1 ACCRUE_HOST_PORTAL_THEME=light npm --prefix examples/accrue_host run e2e -- --config=playwright.braintree.config.js e2e/phase236-portal-self-service.spec.js --grep 'Hosted Fields'` (7 passed); `ACCRUE_HOST_BROWSER_USE_BRAINTREE=1 ACCRUE_HOST_PORTAL_THEME=dark npm --prefix examples/accrue_host run e2e -- --config=playwright.braintree.config.js e2e/phase236-portal-self-service.spec.js --grep 'Hosted Fields'` (7 passed); mock evidence only; live provider iframe rendering unverified | `examples/accrue_host/e2e/phase236-portal-self-service.spec.js` | ✓ green |
| 236-03-T2, 236-05-T2 | 236-03, 236-05 | 3, 4 | POR-06 | T-236-07 | Known and unknown lifecycle states use truthful labels and claims | ExUnit + served browser | `cd accrue_portal && mix test.ci`; `cd examples/accrue_host && ACCRUE_HOST_BROWSER_USE_BRAINTREE=1 npm run e2e -- --config=playwright.braintree.config.js e2e/phase236-portal-self-service.spec.js` | Existing lifecycle matrix and served route assertions | ✓ green |
| 236-04-T1, 236-04-T2 | 236-04 | 2 | POR-07 | T-236-08, T-236-09 | Return destinations are validated; query strings do not establish success | Controller + LiveView | `cd accrue_portal && mix test.ci` | Existing destination matrix, query-only status, decline, and uncertainty assertions | ✓ green |

---

## Wave 0 Requirements

- [x] Invoice and payment-method read failures are injected and visibly distinguished from successful empty results.
- [x] The Phase 236 served-host Playwright spec covers route/action states and is included in the blocking CI Playwright lane.
- [x] Deterministic provider/result failure assertions cover user-visible outcome copy.
- [x] Planner mapped each POR requirement to concrete plan/task/wave IDs and automated commands; execution evidence is recorded below.

---

## Manual-Only Verifications

All stable, in-scope acceptance behaviors have automated ExUnit/LiveView or served-browser verification; no human UAT is required for phase acceptance. The only manual-only evidence boundary is live Braintree iframe rendering fidelity: the repeatable suite injects a deterministic SDK mock, so it proves application-supplied style values and lifecycle behavior but cannot establish the appearance or behavior inside Braintree's cross-origin iframe. Keep that claim explicitly unverified unless checked against the live provider. This is an external fidelity limitation, not a gap in the deterministic acceptance contract.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify commands or explicit Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Focused feedback latency measured and documented
- [x] `nyquist_compliant: true` set after passing validation evidence

**Approval:** validated 2026-10-08 after three focused Wave 5 browser runs passed in default, forced-light, and forced-dark modes. D-08 limits these results to served browser surfaces, application-supplied styles, and deterministic mock lifecycle; live-provider iframe fidelity remains outside this evidence.

## Validation Audit 2026-10-08 — Wave 5

| Metric | Count |
|---|---|
| Focused commands passed | 3 |
| Browser results recorded | 3 positive `N passed` results |
| Live-provider rendering claims | 0 |

## Validation Audit 2026-10-08

| Metric | Count |
|---|---|
| Gaps found | 7 |
| Resolved | 7 |
| Escalated | 0 |

## Validation Addendum — 261008-lbv

| Metric | Count |
|---|---|
| Focused commands passed | 3 |
| Browser results recorded | 3 positive results: 10, 7, and 7 passed |
| Malformed-token themes checked | 2 (forced light and forced dark) |
| Post-mount lifecycle stages checked | 2 (client creation and Hosted Fields creation) |
| Teardown failure paths checked | 2 (async setup and theme refresh stay disabled; no replacement starts) |
| Theme timing paths checked | 2 (style snapshot during create; concurrent LiveView update during active teardown) |
| Manual-only verification added | 0 |

The direct context-pin URL patch is observed separately. The lifecycle regression invokes the mounted hook through LiveView's `ViewHook.__updated` wrapper to simulate a post-mount DOM update; it does not claim that the URL-only patch itself invokes `updated()`. The deterministic SDK mock proves application-side style handoff and lifecycle behavior, not live provider iframe rendering. The final security re-audit returned `SECURED`: 15/15 threats closed, zero open.

## Nyquist Recheck 2026-10-08

Audited all six Phase 236 plan/summary pairs, POR-01 through POR-07, and the existing task verification map. Stable acceptance coverage is already present in ExUnit/LiveView and the blocking Phase 236 Playwright CI lane; no additional test file was needed. Re-ran the focused Hosted Fields browser matrix against the current suite:

| Host theme | Automated command | Result |
|---|---|---|
| Default | `ACCRUE_HOST_BROWSER_USE_BRAINTREE=1 npm run e2e -- --config=playwright.braintree.config.js e2e/phase236-portal-self-service.spec.js --grep 'Hosted Fields'` | 10 passed (17.1s) |
| Forced light | `ACCRUE_HOST_BROWSER_USE_BRAINTREE=1 ACCRUE_HOST_PORTAL_THEME=light npm run e2e -- --config=playwright.braintree.config.js e2e/phase236-portal-self-service.spec.js --grep 'Hosted Fields'` | 7 passed (14.8s) |
| Forced dark | `ACCRUE_HOST_BROWSER_USE_BRAINTREE=1 ACCRUE_HOST_PORTAL_THEME=dark npm run e2e -- --config=playwright.braintree.config.js e2e/phase236-portal-self-service.spec.js --grep 'Hosted Fields'` | 7 passed (18.2s) |

The first sandboxed browser launch was blocked by local Chromium process permissions; the same default run succeeded with browser process access, followed by successful forced-light and forced-dark runs. CI registers the default served contract and both forced-theme Hosted Fields runs as blocking checks. The mocked SDK remains the evidence boundary; no live-provider rendering assertion is inferred from these results.

## Shared Hook Regression — Phase 235 Checkout

The changed Hosted Fields hook is also used by the existing checkout flow. Re-ran its served Braintree contract after the Phase 236 lifecycle changes:

| Command | Result |
|---|---|
| `ACCRUE_HOST_BROWSER_USE_BRAINTREE=1 npm --prefix examples/accrue_host run e2e -- --config=playwright.braintree.config.js e2e/phase233-braintree-checkout.spec.js --workers=1` | 12 passed (23.0s) |

The run covers tokenization and nonce transport, retries, teardown, abandonment, and return handling through the shared hook. It uses the deterministic SDK fixture and does not claim live Braintree iframe fidelity.

## Nyquist Recheck — Current Integration Evidence (2026-10-08)

Audited all six Phase 236 plan/summary pairs and the POR-01 through POR-07 verification map against the current test commands and the available post-source-commit evidence (`b24092fa`). Every stable acceptance behavior already has an automated behavioral assertion in the package or served-browser suites; this audit found no genuine coverage gap and required no new test file.

| Automated lane | Result | Evidence scope |
|---|---:|---|
| Core package | 2,077 passed, 0 failed (11 excluded) | Current core package regression suite |
| Admin package | 581 passed, 0 failed | Current Admin package regression suite |
| Portal package | 110 passed, 0 failed | Current Portal package regression suite |
| Host package | 222 passed, 0 failed | Current host package regression suite |
| Package documentation verifier | 46 passed, 0 failed | Current package documentation checks |
| Phase 234 browser contract | 1 passed, 0 failed | Shared subscription browser journey regression |
| Phase 237 browser contract | 1 passed, 0 failed | Current Admin regression journey |
| Phase 233 Braintree browser lane | 12 passed, 0 failed | Shared Hosted Fields checkout consumer, deterministic SDK fixture |
| Phase 236 Braintree browser lane | 14 passed, 0 failed | Portal billing and Hosted Fields journey, deterministic SDK fixture |
| Standard Fake browser lane | 14 passed, 0 failed | Standard provider fixture regression |
| Real-query search browser check | 1 passed, 0 failed | Search path using real query behavior |

The existing focused Phase 236 Hosted Fields theme and lifecycle evidence remains recorded above (10 default, 7 forced-light, and 7 forced-dark tests); the current 14-test lane adds regression evidence for the complete Phase 236 served journey. Browser SDK fixtures prove application-side behavior and do not establish rendering inside Braintree's cross-origin iframe. No deterministic acceptance criterion requires human UAT.

| Audit result | Count |
|---|---:|
| Phase requirements audited | 7 (POR-01 through POR-07) |
| Deterministic coverage gaps found | 0 |
| New tests required | 0 |
| Unresolved human verification for stable acceptance | 0 |
