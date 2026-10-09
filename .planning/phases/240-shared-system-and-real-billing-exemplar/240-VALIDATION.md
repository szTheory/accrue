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

- Extend the existing expected Linux snapshot owner with deterministic complete-set validation and isolated all-missing/partial-missing controls before propagation.
- Create controlled busy/reconnect fixture support only in disposable test environments; protect production auth/action ownership and preview custody.
- Add the focused System/effective theme, full overlay/focus and responsive long-content scenarios in the existing owners.
- Create current exemplar coverage/provenance/resource records. Reuse the 30-family/42-variant/8-group registry; the 43-module source enumeration is a separate provenance count, not a second variant inventory.
- Provision the existing Playwright Chromium environment/cache during execution if absent; installing pinned existing test tooling is routine reversible setup, not a new product dependency or owner UAT handoff. Record actual availability and failures.

## Manual-Only Verifications

None requiring the maintainer. The executor performs the bounded visual inspection through available browser/capture tools. Subjective owner feedback is optional afterward. CSS zoom, accessibility-tree checks, axe and touch emulation are explicitly limited evidence; do not call them actual browser zoom, screen-reader speech, physical-device or universal certification. If a tool cannot exercise a method, record the limit and use the smallest faithful available automation; do not silently claim proof or invent required owner UAT.

Proof/reset/mutation work uses isolated package/host test fixtures. The canonical Fake feedback preview is separate. HTTP-only request collectors cannot establish absence of LiveView writes; use authoritative state/dispatch/audit evidence or a narrower claim.

## Validation Sign-Off

- [ ] Every concrete task has automated verification or a prerequisite that creates its owner
- [ ] Wave 0 and missing-file dependencies reconciled to final plans
- [ ] All eight requirements mapped to plan tasks and threat references
- [ ] No watch-mode commands or invented timing promises
- [ ] Existing recurring CI owners retained and new checks wired once
- [ ] Execution evidence complete; `nyquist_compliant: true` set only by the appropriate validation audit

**Approval:** Pending execution validation; plan-checker reviews this contract before execution.
