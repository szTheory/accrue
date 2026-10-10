---
phase: "241"
slug: "billing-operator-journeys"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-09"
---

# Phase 241 — Validation Strategy

> Draft execution contract derived from focused research. Planning checks command paths and coverage; execution supplies behavioral evidence and measured timings.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | Existing ExUnit/Phoenix LiveViewTest, Node tests, package Playwright and mounted host Playwright |
| Config | `accrue_admin/playwright.config.js`, `examples/accrue_host/playwright.config.js`, existing Mix/test setup |
| Quick navigation command | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/scoped_path_test.exs` |
| Quick action command | Run the changed action owner's existing LiveView test file, as concretely bound in its PLAN |
| Full Admin server command | `cd accrue_admin && MIX_ENV=test mix compile --warnings-as-errors && MIX_ENV=test mix test` |
| Package browser owner | Existing Phase 191 page-flow and Phase 199 overlay owners; exact focused title/selection must include new cases and report a nonzero executed count |
| Host browser owner | `cd examples/accrue_host && npm run e2e -- e2e/phase237-admin-billing.spec.js --project=chromium-desktop --workers=1` |
| Assets | `cd accrue_admin && mix accrue_admin.assets.build`; host compile and HTTP-served bytes require separate evidence |
| Estimated latency | Not measured during planning. Use a targeted owner per task; execution records cheap feedback latency and separates full/browser gates |

## Sampling Rate

- With each owning implementation task: add focused behavioral assertions and known-positive/negative controls; run that owner's targeted test command before committing accepted work.
- At each dependency boundary: run affected integration and browser owners, with prerequisite build/fixture setup recorded in the plan.
- After the combined phase batch: one complete build/check and one batched desktop/narrow/effective-theme inspection, one corrective batch and at most one confirming inspection (D-20).
- Before phase verification: current automated acceptance and source/built/compiled/served provenance must be green. Phase 240 history is continuity, not fresh Phase 241 evidence.
- Never accept zero selected tests, retries that hide defects, unknown provider outcomes as completion, or URL equality as destination membership proof.

## Per-Task Verification Map

The planner replaces this requirement-level seed with exact task IDs, waves and unique threat references after decomposition. Existing owner paths are present; new scenarios are pending.

| Seed | Requirement | Secure behavior / acceptance | Owner | Command | Status |
|------|-------------|------------------------------|-------|---------|--------|
| Subscription links | JRN-01 | Customer-scoped open invoices and separately labeled scope queue return exact authorized fixture rows; subscription count stays local | Query modules, subscription and invoice LiveView tests | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/queries/query_modules_test.exs test/accrue_admin/live/subscription_live_test.exs test/accrue_admin/live/invoices_live_test.exs` | Pending |
| Bounded returns | JRN-02 | Supported filter/lens/query-free origins and same-customer tabs survive; external/ambiguous/cross-mount/cross-customer origins fail safe and current owner is rebuilt | ScopedPath and list/detail LiveView owners | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/scoped_path_test.exs test/accrue_admin/live/invoice_live_test.exs test/accrue_admin/live/charge_live_test.exs test/accrue_admin/live/subscription_live_test.exs test/accrue_admin/live/customer_live_test.exs` | Pending |
| Recovery | JRN-03 | Direct/invalid/unrelated campaign origin returns scoped Recovery; supported 7d/30d/90d retains scope/window without relabeling historical evidence | Recovery and campaign LiveView owners | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/analytics/recovery_live_test.exs test/accrue_admin/live/analytics/campaign_live_test.exs test/accrue_admin/scoped_path_test.exs` | Pending |
| Reviews | JRN-04 | Exact intent, money, consequence, dismissal/no dispatch, fresh auth/step-up/target/state, duplicate and truthful result controls remain at local owners | Existing invoice, subscription, charge and customer action owners | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/invoice_live_test.exs test/accrue_admin/live/subscription_live_test.exs test/accrue_admin/live/charge_live_test.exs test/accrue_admin/live/customer_live_test.exs test/accrue_admin/components/overlay_components_test.exs` | Pending |
| Mounted propagation | JRN-01..04 | Each changed consumer exercises actual keyboard/correction/Escape/focus, busy/reconnect, narrow/coarse-pointer and effective themes with fresh served bytes | Existing package and mounted host browser owners | Exact runnable selectors, fixture prerequisites and failure signals belong to final PLAN tasks | Pending |

## Wave 0 Requirements

- Extend existing owner tests with decoder/allowlist parity, recognized query-free origins, same-customer validation and safe current-owner rebuilding controls.
- Add subscription link wording plus actual destination membership across multiple customers/subscriptions/owners.
- Add campaign direct and retained-window return cases.
- Enumerate every touched action variant and bind review facts, no-dispatch dismissal, stale/denied/duplicate/unknown controls to it.
- Add deterministic browser cases to existing owners; pair new assertion fixtures with implementation rather than creating a separate scaffolding phase.
- Keep disposable mutation/reset fixtures separate from feedback previews. Existing framework, configuration and CI lanes suffice; no new dependency or matrix.

## Manual-Only Verifications

No required human UAT. All phase acceptance is assigned executable assertions or bounded agent inspection with committed evidence. Subjective owner feedback is optional. Actual browser zoom, physical-device behavior, screen-reader speech and live-provider fidelity are honest evidence limits, not recurring handoff gates.

## CI and Evidence Ownership

Use existing `release-gate`, Admin guardrails, component and `host-integration` lanes where they already execute the changed owners. Preserve Linux baseline guards, approved masks and pixel thresholds; final reviewed Linux goldens belong to Phase 243. Do not claim remote CI ran during planning.

## Validation Sign-Off

- [ ] Final task map has exact IDs/waves and unique `T-241-NN` references.
- [ ] Every task has a runnable automated command and immediately paired observable failure signal.
- [ ] No three consecutive tasks lack automated feedback; no watch mode or zero-test acceptance.
- [ ] New scenarios and fixture prerequisites are covered with owning implementation.
- [ ] Command paths and selected test counts are checked before execution claims.
- [ ] Execution timings, current evidence and automated UAT are recorded.
- [ ] Validation audit sets `nyquist_compliant: true` only after its evidence gate.

**Approval:** Pending execution evidence; no tests ran during planning.
