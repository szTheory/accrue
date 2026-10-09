---
phase: "240"
slug: "shared-system-and-real-billing-exemplar"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-09"
---

# Phase 240 — Validation Strategy

> Existing acceptance owners provide recurring proof with each change. This is a planning contract; no implementation test or current mounted proof has run. The planner reconciles the map below to its concrete tasks and new-file dependencies before plan-checking.

## Test Infrastructure

| Property | Value |
|---|---|
| Framework | ExUnit / Phoenix.LiveViewTest; Node node:test; Playwright 1.59.1; axe; existing Linux pixel owner |
| Config | `accrue_admin/playwright.config.js`, package scripts and existing mounted host verification config |
| Quick check | Changed-owner ExUnit module or Node hook test; fixture startup cost is separate and unmeasured |
| Browser checks | Existing phase196/198/199 and mounted phase237/238 owners as mapped in RESEARCH/PATTERNS; axe is supplementary |
| Full phase gate | Changed owners plus existing blocking CI lanes and current source/build/compiled/served-asset evidence; do not duplicate host full verification and its shards |
| Runtime | Unmeasured; browser/database setup is not a sub-30-second check. Record elapsed setup/assertion at execution; no arbitrary new SLA |

## Sampling Rate

- Every task has a focused automated verify at its semantic owner, or an explicit dependency that creates the check before use.
- Every wave runs the changed-owner bundle and smallest faithful mounted checks; batch builds and inspection.
- Before phase completion: applicable blocking owners pass, focused new-guard negatives fail as intended and are restored, and exemplar provenance/inspection is current.
- No fixed sleeps, new retries, softened pixel thresholds, silent exclusions or paid visual evaluators.

## Requirement Verification Map

| Requirement | Existing owner / automated starting command | Required focused extension | Status |
|---|---|---|---|
| DSN-01 | `cd accrue_admin && mix test test/accrue_admin/live/invoices_live_test.exs test/accrue_admin/live/invoice_live_test.exs test/accrue_admin/live/subscription_live_test.exs` | Real invoice list/detail/review tracer plus dense subscription; shared hierarchy and current mounted geometry | Pending |
| DSN-02 | `cd accrue_admin && npm run e2e:phase196` and `npm run e2e:phase198` | Long/missing content, 320/intermediate/coarse-pointer, enlarged/text-spaced content, truthful browser-zoom method and limits | Pending |
| DSN-03 | `cd accrue_admin && mix test test/accrue_admin/components/theme_picker_test.exs test/accrue_admin/theme_test.exs` | Mounted stored System/effective OS light-dark-light, patch/reload and host-forced precedence | Pending |
| DSN-04 | Existing invoice/subscription ExUnit owners and mounted interaction owner | Controlled actual server busy completion, repeated patches, reconnect/replaced controls, online-alone negative and authoritative no-replay proof | Pending |
| DSN-05 | `cd accrue_admin && node --test test/js/focus_trap_test.mjs`; existing phase199 overlay browser owner | Tab/Shift-Tab wrap, validation/correction, dismiss/submit and replaced/removed-trigger focus restoration; actual reduced-motion teardown | Pending |
| UXC-02 | Existing invoice list/detail ExUnit owners | State matrix of real branches, exact target/money/outcome, supported next step and explicit N/A rationale where no capability exists | Pending |
| EVR-01 | Existing asset/build/drift and mounted provenance owners | Current 21-route/registry-owner pointers, source/fixture/built/compiled/served CSS/JS/fonts, exercised transitions and comparable resource diagnostics | Pending |
| EVR-02 | Existing recurring ExUnit/Node/package/mounted/axe/Linux owners | Early expected snapshot set guard: complete passes, missing-all/missing-partial fail; new guards have focused negatives without demoting pixels | Pending |

## Wave 0 Requirements

- **Before propagation, Wave 1:** `240-01` Task 1 is the production invoice list → detail → review tracer, verified in existing host Phase 237 and invoice ExUnit owners before shared changes. `240-02` Tasks 1–2 create `accrue_admin/e2e/visual-baseline-set.cjs` and `accrue_admin/test/js/visual_baseline_set_test.mjs`, prove complete/all-missing/partial-missing outcomes, and make the existing Linux pixel job unconditionally blocking. All expansion plans depend on these.
- **Wave 2:** `240-03` Tasks 1–3 extend invoice state/responsive/zoom assertions in existing ExUnit and Phase 196/198 mounted owners. `240-04` Tasks 1–2 extend System/effective/forced theme and keyboard review in theme ExUnit, FocusTrap Node, Phase 199 and Phase 238 owners. These plans have no shared modified files.
- **Wave 3:** `240-05` Tasks 1–2 add test-only controlled hold/release and authoritative dispatch/audit evidence to the disposable fixture and existing invoice/subscription owners, then extend Phase 191 reconnect. It follows `240-03` because both modify `invoice_live_test.exs`.
- **Wave 4:** `240-06` Tasks 1–2 create `240-COVERAGE.md` and `scripts/ci/verify_phase240_evidence.mjs`, extend existing Phase 237 host evidence for CSS/JS/fonts and first-fresh resource diagnostics, then reconcile changed acceptance owners. It follows all behavior plans.
- **Environment:** Resolve the pinned Playwright Chromium executable at execution; provision that existing browser if absent. Keep reset/mutation proof in package/host disposable fixtures, separate from Fake feedback preview. Record browser availability and actual zoom limits without owner UAT handoff.

## Concrete Task Gates

| Plan/task | Recurring owner | Focused failure control |
|---|---|---|
| 01/1 | Phase 237 host + invoice ExUnit | Missing list/detail/review target, amount mismatch, stale/foreign dispatch; zero tests fail |
| 01/2 | Phase 198 mounted detail | Confirmed geometry or served stylesheet mismatch; zero tests fail |
| 01/3 | Subscription list/detail ExUnit | Scope, plan money/period or action regression; zero tests fail |
| 02/1–2 | Node expected-set + existing Linux visual job | Complete passes; all-missing and partial-missing exit nonzero; no pixel skip |
| 03/1 | Invoice list/detail ExUnit | State collapse, unsupported next action or stale result; inverted guard fails |
| 03/2–3 | Phase 196/198 mounted + axe | Width, coarse-pointer, enlarged/spacing/zoom, clipped fact/action or overflow failure |
| 04/1 | Theme ExUnit + Phase 199/238 | Stored System versus computed OS/forced mismatch; stale-style negative |
| 04/2 | FocusTrap Node + Phase 199 | Tab/Shift-Tab, correction/submission or removed-trigger focus failure |
| 05/1–2 | Fixture/invoice/subscription ExUnit + Phase 191 | Hold/release, early unlock, replaced disabled control or dispatch count above one |
| 06/1–2 | `node scripts/ci/verify_phase240_evidence.mjs --self-test .planning/phases/240-shared-system-and-real-billing-exemplar/240-COVERAGE.md` followed by the normal ledger CLI, plus Phase 237/asset owners | Self-test requires valid ledger exit 0 and a disposable copy with one required route row removed to exit nonzero naming that route; stale CSS/JS/font digest also fails |

The `06/1–2` verifier is created by `240-06` Task 1 before either command runs. Its self-test must report `self-test: valid=1 missing-route-rejected=1`; both Task 1 and the final Task 2 gate invoke it before normal ledger validation. The six `T-240-SC` rows are the security template's reserved per-plan package-installation sentinel, not six distinct phase threats; actual threat IDs `T-240-01` through `T-240-12` are unique.

## Manual-Only Verifications

None requiring the maintainer. The executor performs the bounded visual inspection through available browser/capture tools. Subjective owner feedback is optional afterward. CSS zoom, accessibility-tree checks, axe and touch emulation are explicitly limited evidence; do not call them actual browser zoom, screen-reader speech, physical-device or universal certification. If a tool cannot exercise a method, record the limit and use the smallest faithful available automation; do not silently claim proof or invent required owner UAT.

Proof/reset/mutation work uses isolated package/host test fixtures. The canonical Fake feedback preview is separate. HTTP-only request collectors cannot establish absence of LiveView writes; use authoritative state/dispatch/audit evidence or a narrower claim.

## Validation Sign-Off

- [x] Every concrete task has automated verification or a prerequisite that creates its owner
- [x] Wave 0 and missing-file dependencies reconciled to final plans
- [x] All eight requirements mapped to plan tasks and threat references
- [x] No watch-mode commands or invented timing promises
- [ ] Existing recurring CI owners retained and new checks wired once
- [ ] Execution evidence complete; `nyquist_compliant: true` set only by the appropriate validation audit

**Approval:** Planning contract passed independent plan-checking on 2026-10-09. Execution validation remains pending; Nyquist execution compliance is not claimed by plan approval.

## Execution evidence through 240-06

Recorded on 2026-10-09 from local commands and the prior plan summaries. These rows report observed acceptance only; they do not set `nyquist_compliant` or claim remote CI success.

| Requirement | Observed evidence | Remaining boundary |
|---|---|---|
| DSN-01 | Invoice list/detail/review and subscription owner suites; Admin full ExUnit at 617 passed, 0 failed; Phase 237 mounted list/detail/action-review test passed | Other route-family pages remain mapped to their existing recurring owners |
| DSN-02 | Phase 196 and 198 browser evidence; narrow/intermediate/coarse-pointer cases recorded by 240-03 | Actual 400% browser zoom unavailable locally; CSS/pinch scaling is not zoom proof; Linux window 27 remains remote CI owner |
| DSN-03 | Theme preference owners and Phase 199/238 mounted evidence; Phase 237 stores System preference separately from effective light/dark CSS evidence | OS theme is browser-emulated, not a physical OS change |
| DSN-04 | Phase 191 lifecycle owner: 26 tests passed; held-action fixture/owning Admin tests: 71 passed; no replay/duplicate dispatch covered by authoritative fixture assertions | No new host invoice mutation was dispatched in the Phase 237 read-only exemplar |
| DSN-05 | FocusTrap Node owner: 41 passed; Phase 199 keyboard/overlay owner passed after its recorded selector/fixture repairs | Axe/tree evidence does not claim screen-reader speech |
| UXC-02 | Invoice state/action owners and full Admin suite cover distinct supported/unsupported and outcome states | N/A review/result states remain justified on read-only endpoints in `240-COVERAGE.md` |
| EVR-01 | 240-06 ledger validates 21 production routes, all 8 requirements, live incumbent registry 30/42/8 and 43 component modules; mounted CSS/JS/Geist bytes match package build, host compile and served response | The ledger is a durable inventory, not a recurring point-in-time CI gate |
| EVR-02 | New verifier self-test reports `self-test: valid=1 missing-route-rejected=1`; Phase 237 browser owner passes and detects/restores a deliberately stale JS response | Host `verify.full`: initial TrustSmoke result 222ms vs 100ms; one unchanged diagnostic rerun reported 223 tests/1 failure in the bounded ExUnit stage, with no detailed failure block preserved. Final reviewed Linux baselines belong to Phase 243. |

Local execution limits retained: remote CI is unobserved; Phase 243 owns final reviewed goldens; actual browser zoom was unavailable; the original 240-03 execution did not preserve pre-GREEN RED timing, and its retrospective reports are explicitly not original timing evidence. The phase remains open for the parent executor's independent gates.
