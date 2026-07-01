---
phase: 196
slug: exemplar-c-subscriptions-list-pageheader
status: passed
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-26
audited: 2026-07-01
verification_report: .planning/phases/196-exemplar-c-subscriptions-list-pageheader/196-VERIFICATION.md
---

# Phase 196 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix.LiveViewTest + Playwright |
| **Config file** | `accrue_admin/mix.exs`, `accrue_admin/package.json`, `accrue_admin/playwright.config.js` |
| **Quick run command** | `cd accrue_admin && mix test test/accrue_admin/components/page_header_test.exs test/accrue_admin/components/filter_chip_bar_test.exs test/accrue_admin/components/data_table_test.exs test/accrue_admin/live/subscriptions_live_test.exs` |
| **Full suite command** | `cd accrue_admin && mix test --warnings-as-errors && npm run e2e:phase196` |
| **Estimated runtime** | ExUnit focused run under 60 seconds; full suite plus Playwright under 3 minutes |

---

## Sampling Rate

- **After every task commit:** Run `cd accrue_admin && mix test test/accrue_admin/components/page_header_test.exs test/accrue_admin/components/filter_chip_bar_test.exs test/accrue_admin/components/data_table_test.exs test/accrue_admin/live/subscriptions_live_test.exs`
- **After every plan wave:** Run `cd accrue_admin && mix test --warnings-as-errors && npm run e2e:phase196`
- **Before `/gsd:verify-work`:** Run package docs guard, asset build if CSS or JS changed, full ExUnit, and `npm run e2e:phase196`
- **Max feedback latency:** 3 minutes

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|

## Validation Audit 2026-07-01

| Metric | Count |
|--------|-------|
| Requirements audited | 2 |
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
| Manual-only requirements | 0 |

Phase 196 is Nyquist-compliant for EXE-03 and PGH-01. `196-VERIFICATION.md` verifies PageHeader extraction, one-h1 enforcement, Subscriptions LIST state coverage, URL-backed filters, row-card degradation, focused ExUnit coverage, package-doc guards, and the Phase 196 browser contract with no verifier-blocking gaps.
| 196-00-01 | TBD | 0 | PGH-01 | T-196-01 | PageHeader is stateless and does not own filter/query state | component | `cd accrue_admin && mix test test/accrue_admin/components/page_header_test.exs` | No, W0 | pending |
| 196-00-02 | TBD | 0 | EXE-03 | T-196-02 | Filter clear-all keeps owner scope and does not leak cross-tenant paths | component + browser | `cd accrue_admin && mix test test/accrue_admin/components/filter_chip_bar_test.exs && npm run e2e:phase196` | Partial, W0 | pending |
| 196-00-03 | TBD | 0 | EXE-03 | T-196-03 | LIST state markers distinguish populated, first-run-empty, filtered-empty, and loading-skeleton | component + LiveView + browser | `cd accrue_admin && mix test test/accrue_admin/components/data_table_test.exs test/accrue_admin/live/subscriptions_live_test.exs && npm run e2e:phase196` | Partial, W0 | pending |
| 196-00-04 | TBD | 0 | EXE-03 | T-196-04 | Identity/state/money/time columns are prioritized and raw plumbing IDs are de-emphasized | LiveView + browser | `cd accrue_admin && mix test test/accrue_admin/live/subscriptions_live_test.exs && npm run e2e:phase196` | Partial, W0 | pending |
| 196-00-05 | TBD | 0 | PGH-01 | T-196-05 | Subscriptions renders through PageHeader with exactly one page h1 | LiveView | `cd accrue_admin && mix test test/accrue_admin/live/subscriptions_live_test.exs` | Yes | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] `accrue_admin/test/accrue_admin/components/page_header_test.exs` - covers PGH-01 slot contract, breadcrumbs, stable markers, and one h1.
- [ ] `accrue_admin/e2e/admin-spec-list-phase196.spec.js` - covers EXE-03 rendered states across desktop/mobile and light/dark.
- [ ] `accrue_admin/package.json` includes `e2e:phase196` following the Phase 195 Playwright script pattern.
- [ ] DataTable loading fixture/test hook exists so `loading-skeleton` can be verified without fake production async.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual density and hierarchy rubric | EXE-03 | Some judgment-grade UI hierarchy checks are not fully captured by DOM selectors | Review Subscriptions in desktop and mobile after `npm run e2e:phase196`; confirm identity/state/money/time scan order and raw ID de-emphasis match SPEC-LIST. |

---

## Validation Sign-Off

- [ ] All tasks have automated verify commands or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all missing references
- [ ] No watch-mode flags
- [ ] Feedback latency under 3 minutes
- [ ] `nyquist_compliant: true` set in frontmatter after Wave 0 passes

**Approval:** pending
