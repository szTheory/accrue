---
phase: 245-rendered-baseline-and-realistic-preview
plan: "03"
subsystem: ui
tags: [phoenix-liveview, playwright, screenshots, visual-review]
requires:
  - phase: 245-01
    provides: isolated ordinary Fake preview and capture tracer
  - phase: 245-02
    provides: realistic ordinary billing stories and fixture provenance
provides:
  - mounted Admin route/state coverage and historical route reconciliation
  - bounded 24-image current render set with source, asset, scenario and PNG provenance
  - source-linked findings and dispositions for all high-signal owner-brief sections
affects: [phase-246, phase-247, phase-248]
tech-stack:
  added: []
  patterns: [Playwright authenticated exact-origin capture, manifest SHA-256 verification, source-derived route inventory]
key-files:
  created:
    - .planning/phases/245-rendered-baseline-and-realistic-preview/245-FINDINGS.md
    - .planning/phases/245-rendered-baseline-and-realistic-preview/captures/manifest.json
    - scripts/ci/verify_phase245_baseline.mjs
  modified:
    - .planning/phases/245-rendered-baseline-and-realistic-preview/245-COVERAGE.md
    - examples/accrue_host/e2e/phase245-admin-baseline.spec.js
decisions:
  - Keep Phase243 browser observations supplemental; only ordinary-instance PNGs count as Phase245 capture evidence.
  - Record absent ordinary detail IDs and inactive development routes as distinct, reasoned gaps.
  - Keep visual findings as later-phase handoffs; make no production UI changes.
metrics:
  duration: "about 90 minutes across initial capture and evidence reconciliation"
  completed: 2026-10-11
  tasks: 3
  files: 42
  status: complete
actuals:
  tokens: 171991
  tasks: 3
  commits: 25
commits: 25
plan_head_before: 9aea54bdbdb136c8e76161c6844bfb48e169ad06
plan_head_after: 5ed89ad44721daccd1d89d6818b7ba22c13c5830
---

# Phase 245 Plan 03: Rendered route coverage and findings summary

**Authenticated 24-image Admin baseline with a 21-route inventory, reasoned UI-state gaps, and source-linked owner handoff.**

## Accomplishments

- Derived all 21 production LiveView templates from the package router and host mount, reconciled them with the historical 21-route count, and listed conditional dev routes and support endpoints separately.
- Captured all 19 reachable mounted routes in four representative theme/viewport combinations from the isolated `accrue-host-phase245-ordinary` Fake preview. Each PNG binds route/state, fixture, capture revision/dirty flag, source digests, requested and byte-matched served CSS/JS, browser user-agent, viewport, theme, time and SHA-256.
- Classified the missing Connect and webhook details as unavailable because the ordinary instance contains no rows/IDs. Marked five dev routes not applicable because the host mount disables them and direct requests return 404. Supplemental Phase243 detail observations are explicitly separate from ordinary evidence.
- Waited up to 15 seconds for source-backed Recovery ready markers. The final capture observed the at-risk table in `no-pagination` and supporting funnel in `ready`; populated metrics were inspected rather than mislabeled as loading.
- Recorded the bounded Impeccable critique (22/40) for the 19-route cohort, five deduplicated rendered findings, and concrete owner follow-ups for all 13 brief topics. The five supplemental state screenshots were opened for their specific evidence; the 22/40 score is not presented as a second full critique. The detector returned `[]`; this is limited static evidence, not UI acceptance.
- Captured three filtered-zero views (customer impossible query, Connect Needs attention, Webhooks Needs replay), global search open and pointer/keyboard state, customer Invoices tab, and the Activity disclosure open state. C22 shows pointer hover moved `.ax-active` from the previously keyboard-selected subscription result to the customer result; one active path is visible after hover. Keyboard activation is unverified. C24 still shows “Open this section to load customer activity,” so loaded timeline evidence is not claimed.
- Corrected Connect findings F02/F05 from the old R14-populated label to `R14-filtered-to-zero` while preserving PNG SHA-256 `d85bce5413fa06deb86988c6f313415b2c5c2e22ff3d5faf4dee237d6e3d0a49`. Coverage distinguishes filtered-zero views from unfiltered-empty states.

## Verification

- `npm --prefix examples/accrue_host run e2e -- --config=playwright.phase245.config.js e2e/phase245-admin-baseline.spec.js --project=chromium-desktop --workers=1` — **5/5 passed in 49.6s** on the final clean-source capture run.
- `node scripts/ci/verify_phase245_baseline.mjs --coverage .planning/phases/245-rendered-baseline-and-realistic-preview/245-COVERAGE.md --manifest .planning/phases/245-rendered-baseline-and-realistic-preview/captures/manifest.json --findings .planning/phases/245-rendered-baseline-and-realistic-preview/245-FINDINGS.md` — **passed** after reconciliation. `--self-test` and `--routes-only` also passed.
- The final clean capture manifest revision is `a8d39ea4`; `source_dirty: false`, with per-capture source digests and 24 PNG hashes. It was captured after the capture-owner source commit and after the ordinary seed custody check passed.

## Commits

The measured plan range contains 25 commits (`plan_head_before` through `plan_head_after`). It includes the initial route/capture ledger, review fixes, capture-owner checks and the fresh baseline. The clean rendered capture was committed at `655cec36`; source digest verification was committed at `a8d39ea4`; this evidence reconciliation is `5ed89ad4`.

## Decisions and limits

The audit did not trigger production actions, mutate or reseed the preserved Phase243 database, or implement Phase246/247 changes. Unfiltered truly-empty views, alternate role/scope, other detail disclosures, keyboard activation/focus restoration, non-customer filter/query/result agreement, copy feedback, physical touch, overflow, and adversarial text remain explicit gaps. C22 captured keyboard selection followed by pointer hover; C24 opened Activity but retained its lazy-load prompt, so loaded history is not claimed. Phase243-only Connect/webhook details have no Phase245 PNG/hash and are not presented as captured ordinary states.

All 13 owner feedback sections now retain concrete downstream questions and shared-owner routing. F02 and F05 point to the corrected Connect filtered-zero state R14 with the same PNG hash. No auth gate, known stub, threat flag, or production change was introduced. Existing unrelated `.planning/ROADMAP.md` and `.planning/milestone.lock` changes were left untouched; parent owns STATE/ROADMAP updates.

## Self-Check: PASSED

- Coverage, findings, manifest, verifier, E2E owner and all manifest PNGs exist.
- Task commits `c020a84f`, `dd89ff78`, `2902bea6`, and `95061b36` are present in the current branch history.
- The provenance/finding verifier, `--self-test` (stale digest, wrong route, duplicate owner topic, generic gap negatives), and `--routes-only` passed after the final route/state and owner ledger reconciliation.
- The 25-commit count was measured from `9aea54bdbdb136c8e76161c6844bfb48e169ad06` to `5ed89ad44721daccd1d89d6818b7ba22c13c5830`.

Final capture safeguard follow-up: source `a8d39ea4` independently checks the Fake processor before bulk capture; positive/negative guard test and authenticated suite passed (5/5, 49.6s). Refreshed evidence is committed in `da24ebf7`.
