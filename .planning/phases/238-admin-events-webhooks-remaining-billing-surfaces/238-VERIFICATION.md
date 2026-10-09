---
phase: 238-admin-events-webhooks-remaining-billing-surfaces
verified: 2026-10-09T06:02:26Z
status: passed
score: 32/32 must-haves verified
covered_files:
  - ".github/workflows/ci.yml"
  - ".planning/phases/238-admin-events-webhooks-remaining-billing-surfaces/238-01-PLAN.md"
  - ".planning/phases/238-admin-events-webhooks-remaining-billing-surfaces/238-01-SUMMARY.md"
  - ".planning/phases/238-admin-events-webhooks-remaining-billing-surfaces/238-02-PLAN.md"
  - ".planning/phases/238-admin-events-webhooks-remaining-billing-surfaces/238-02-SUMMARY.md"
  - ".planning/phases/238-admin-events-webhooks-remaining-billing-surfaces/238-03-PLAN.md"
  - ".planning/phases/238-admin-events-webhooks-remaining-billing-surfaces/238-03-SUMMARY.md"
  - ".planning/phases/238-admin-events-webhooks-remaining-billing-surfaces/238-04-PLAN.md"
  - ".planning/phases/238-admin-events-webhooks-remaining-billing-surfaces/238-04-SUMMARY.md"
  - ".planning/phases/238-admin-events-webhooks-remaining-billing-surfaces/238-05-PLAN.md"
  - ".planning/phases/238-admin-events-webhooks-remaining-billing-surfaces/238-05-SUMMARY.md"
  - "accrue/guides/branding.md"
  - "accrue/lib/accrue/config.ex"
  - "accrue/test/accrue/config_branding_test.exs"
  - "accrue_admin/assets/js/hooks/focus_trap.js"
  - "accrue_admin/lib/accrue_admin/brand_plug.ex"
  - "accrue_admin/lib/accrue_admin/components/app_shell.ex"
  - "accrue_admin/lib/accrue_admin/components/overlay.ex"
  - "accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex"
  - "accrue_admin/lib/accrue_admin/components/topbar.ex"
  - "accrue_admin/lib/accrue_admin/layouts.ex"
  - "accrue_admin/lib/accrue_admin/live/connect_account_live.ex"
  - "accrue_admin/lib/accrue_admin/live/webhooks_live.ex"
  - "accrue_admin/priv/static/accrue_admin.js"
  - "accrue_admin/test/accrue_admin/theme_test.exs"
  - "examples/accrue_host/config/test.exs"
  - "examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js"
  - "scripts/ci/accrue_host_seed_e2e.exs"
covered_digest: "v3:sha256:4ac33592945cbae69b7bb172309bbe1eff33996995435bedfa2e99b47012d02f"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 31/32
  gaps_closed:
    - "The full replay keyboard journey now passes under ACCRUE_HOST_ADMIN_THEME=dark after the FocusTrap initial-focus race fix."
  gaps_remaining: []
  regressions: []
advisory: []
---

# Phase 238: Admin Events, Webhooks & Remaining Billing Surfaces Verification Report

**Phase Goal:** Operators can investigate local events and delivery history, retry or replay only eligible work, and inspect remaining existing billing surfaces without implied capabilities.
**Verified:** 2026-10-09T06:02:26Z
**Status:** passed
**Re-verification:** Yes — after gap closure

## Goal Achievement

The four roadmap criteria are the phase contract. Re-verification fully rechecked the previous failure: the post-fix full forced-dark Phase 238 lane passes on three consecutive runs, including its replay confirmation Tab assertion. The host-forced test independently sets a conflicting light cookie and verifies that the host policy wins.

### Roadmap Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Operators can inspect local events and webhook deliveries with useful context, accessible identifiers, and linked evidence. | ✓ VERIFIED | `EventsLive`, `EventLive`, `WebhookLive`, and `WebhooksLive` use scoped local queries and render exact identifiers, event actor/subject/source, delivery status/time, attempts, payload/activity disclosure, and related links. The named Events, Event, Webhook, and DataTable ExUnit cases cover exact scoped links, unavailable-versus-empty reads, and retry recovery; mounted Playwright opens seeded event/delivery records and payload/activity disclosures. |
| 2 | Retry/replay is limited to eligible deliveries with required confirmation and step-up; accepted versus processed results and partial selections are stated honestly. | ✓ VERIFIED | `WebhooksLive` canonicalizes IDs, consumes pending confirmation, requires fresh `StepUp`, reloads owner/status and claims through the DLQ transaction, records per-row queued/skipped/failed counts, and reports queue acceptance without claiming processing. `webhook_replay_test.exs` covers empty, duplicate, stale, foreign, repeated, mid-batch failure, and organization revalidation cases; `webhook_live_test.exs` covers current status/owner checks. Phase browser test proves rejection correction, successful queue copy, and no processed-success claim. |
| 3 | Existing coupon, promotion-code, and Connect states and actions are understandable, provider-specific where needed, and never imply unsupported create/edit behavior. | ✓ VERIFIED | Coupon and promotion-code routes render existing records read-only with exact reciprocal links and do not render action bands; Connect labels last stored Stripe observations separately from local fee override and only saves local policy behind validation/step-up. Named coupon/promotion/Connect ExUnit tests and seeded browser assertions verify absent observations stay unknown and create/edit affordances are absent. No live Stripe parity is claimed. |
| 4 | Each changed filter, payload, action, and empty/error state has relevant keyboard, responsive, theme, and interaction evidence in this slice. | ✓ VERIFIED | Default mounted journey exercises keyboard replay, StepUp, Connect override, focus containment/restoration, axe, 320px, zoom, long IDs, and theme selection. The forced-dark run executes the same replay journey and passes its Tab traversal; the host-forced test checks the conflicting preference, status text, filter, and axe. |

**Score:** 32/32 must-haves verified (0 present, behavior-unverified).

### Plan-Specific Must-Haves

The following plan truths were merged in addition to the roadmap contract. Evidence refers to existing passing runs in `238-VALIDATION.md`; tests were not rerun for this verification.

| Plan truth | Status | Evidence |
|---|---|---|
| 238-01.1 Eligible owner-scoped failed/dead delivery requires confirmation and fresh step-up; UI says queue acceptance only. | ✓ VERIFIED | `webhook_replay_test.exs` single and bulk confirmation/step-up tests; mounted replay journey asserts queued-not-processed copy. |
| 238-01.2 Empty selection has no confirmation/audit; duplicate IDs collapse; deterministic ordering. | ✓ VERIFIED | Named empty-selection and duplicate/mixed ordered-outcomes tests in `webhook_replay_test.exs`; ordered per-row implementation in `WebhooksLive`. |
| 238-01.3 Repeated intent queues at most once; stale, foreign, and ineligible rows skip. | ✓ VERIFIED | Replay claim-once, status-changed-after-selection, foreign-owner, and transaction ownership tests. |
| 238-01.4 Owner/status reloaded before queue; mid-batch failure preserves earlier and continues later outcomes. | ✓ VERIFIED | `replay_outcome/2` calls the owner-scoped DLQ claim for eligible rows; named organization-ownership and mid-batch failure tests. |
| 238-01.5 Counts come from per-row outcomes; zero/one/many copy is accurate. | ✓ VERIFIED | Result counters derive from `outcomes`; tests assert exact result/audit counts and mounted spec checks singular/plural confirmation. |
| 238-01.6 Rejected/expired/unavailable step-up yields actionable error and no mutation. | ✓ VERIFIED | Rejected-step-up ExUnit and mounted correction-path assertions; phase browser test has no queued status before corrected challenge. |
| 238-02.1 Events/delivery histories show distinct local evidence, exact IDs, status/time/context, scoped links. | ✓ VERIFIED | LiveView templates use local `Events`/`Webhooks` queries and scoped paths; named list/detail tests assert exact links and evidence. |
| 238-02.2 Activity/payload are disclosed explicitly and long IDs/payload remain accessible. | ✓ VERIFIED | Detail `<details>` disclosures and payload components; ExUnit lazy payload tests; Playwright uses Enter on payload disclosure and checks long-ID containment. |
| 238-02.3 Lists use stable timestamp/ID ordering and links preserve exact active-owner records. | ✓ VERIFIED | Query order clauses and Events/Connect exact-link and timestamp-tie tests; scoped paths retain organization context. |
| 238-02.4 Empty, no-match, unavailable local history, and absent provider facts differ; missing facts stay unknown. | ✓ VERIFIED | DataTable/LiveView unavailable retry states and Connect `unavailable` rendering; named empty/no-match/read-failure tests plus browser no-match/unknown-observation checks. |
| 238-02.5 Single replay permits failed/dead only with fresh step-up; queue differs from processing. | ✓ VERIFIED | `WebhookLive` action-time owner/status reload and fresh step-up; stale/ineligible and rejected-step-up tests plus exact copy assertions. |
| 238-03.1 Coupons/codes keep separate identities, terms/restrictions, reciprocal parent-child links. | ✓ VERIFIED | Coupon/code detail summaries and exact related links; named read-only detail/link tests. |
| 238-03.2 Lists sort deterministically; filters preserve route context and exact record navigation. | ✓ VERIFIED | Scoped route/query construction and list query ordering; list/detail tests assert IDs, filter states, and preserved organization path context. |
| 238-03.3 True empty, filtered no-match, and unavailable reads differ actionably. | ✓ VERIFIED | Distinct list state and detail unavailable/retry render paths; coupon/code list and detail recovery tests. |
| 238-03.4 Coupon/code refresh is read-only and implies no create/edit/remote mutation. | ✓ VERIFIED | Detail pages render no action band/overflow menu; mounted coupon/code paths assert no create/edit controls. |
| 238-04.1 Stripe-observed facts and local fee override remain separate. | ✓ VERIFIED | Connect templates label “Last stored Stripe snapshot” and “Local platform fee override”; list/detail and same-value save tests preserve both. |
| 238-04.2 Absent/failed provider observation stays unknown/unavailable; local override independent. | ✓ VERIFIED | `readiness_summary` derives display from stored provider observation rather than false defaults; tests assert unavailable/unknown and separate override. Freshness is explicitly disclosed as untracked. |
| 238-04.3 Connect list/detail links stay owner-scoped and stable; refresh does not mix owners. | ✓ VERIFIED | Exact account ID is reloaded under active owner scope; scoped link and equal-timestamp tie tests; review fixed and tested the owner-race finding. |
| 238-04.4 Same-value fee save is local, step-up protected, validated, and honest. | ✓ VERIFIED | Save path mutates local account data and audit only; same-value preservation and rejected-step-up unchanged-state tests. |
| 238-05.1 Required Playwright shard discovers/runs phase spec; no live-provider or processed claim. | ✓ VERIFIED | Direct `--list` checks discover 2 default tests and 3 with `ACCRUE_HOST_ADMIN_THEME=dark`; `.github/workflows/ci.yml` retains unrestricted sharded selection and adds the forced-dark invocation. Ordinary spec run passed 2/2. |
| 238-05.2 Populated evidence and billing rows show scoped IDs, status/time, links, provider/local separation. | ✓ VERIFIED | Mounted fixture journey checks exact scoped event/webhook/coupon/code/Connect links, status, and local/provider facts; ExUnit covers fuller event/delivery rows. |
| 238-05.3 ExUnit covers empty/unavailable/partial results; browser covers no-match, zero selection, unavailable Connect. | ✓ VERIFIED | ExUnit list/detail/retry and mixed replay tests; mounted browser checks filtered no-match, no bulk CTA at zero selection, and Unknown Connect observation. |
| 238-05.4 Pending confirmation/step-up announces feedback, avoids duplicate submission, keeps disclosure controls operable. | ✓ VERIFIED | LiveView result roles and replay gating; Playwright exercises pending/rejected step-up, axe states, and details controls; ExUnit covers one-use replay intent. |
| 238-05.5 Rejected step-up shows correction without mutation; failed save/replay and read retry are covered. | ✓ VERIFIED | Browser correction path plus ExUnit state-preservation and unavailable-read retry cases. |
| 238-05.6 Exact replay counts and copy, zero cannot confirm, singular/plural, queue != processed. | ✓ VERIFIED | Exact per-row ExUnit assertions and mounted zero/singular/plural/queued copy assertions. |
| 238-05.7 Keyboard, names, focus entry/containment/restoration, axe on revealed states. | ✓ VERIFIED | Current spec checks initial replay-confirmation focus, Tab to “Keep deliveries”, step-up traversal and correction, Escape dismissal, restoration, and Connect drawer keyboard flow. The normal journey passed 2/2; after the FocusTrap race fix the entire forced-dark spec passed 2 tests with its theme-picker journey intentionally skipped, in three consecutive runs. |
| 238-05.8 At 320px and zoom, no page overflow; filters/long values stay discoverable and contained. | ✓ VERIFIED | Mounted Playwright asserts no document overflow at 320px and 200% zoom; long unbreakable identifier is contained. |
| 238-05.9 Light/dark/system/host-forced themes retain readable controls/text-backed status. | ✓ VERIFIED | The browser theme test passes 1/1 with host-forced dark, a conflicting light cookie, hidden picker, “Dark theme set by host” status, readable Dead status text, enabled filter, and axe. The default test also checks light/dark/system. |

### Advisory (New Scope, Unevidenced)

None. The refreshed UI audit's screenshot limitation and code-derived quality recommendations are recorded below as advisory context; they do not contradict a roadmap truth or identify an untested in-scope behavior.

## Required Artifacts

The `verify.artifacts` and `verify.key-links` verbs returned `total: 0` for each of the five plans despite their frontmatter declaring artifacts and links. I therefore checked those declarations manually rather than treating the empty tool result as verification.

| Artifact group | Expected | Status | Details |
|---|---|---|---|
| `webhooks_live.ex`, `copy.ex`, `webhook_replay_test.exs` | Confirmed, scoped bulk replay and audited outcomes | ✓ VERIFIED | Substantive LiveView handler traces confirmation → fresh StepUp → owner-scoped detail → DLQ claim → event/audit; tests cover adverse cases. |
| `data_table.ex`, `events_live.ex`, `event_live.ex`, `webhook_live.ex` | Local evidence, exact links, unavailable/retry states | ✓ VERIFIED | Real scoped Ecto query modules feed rendered rows/details; state flows through LiveView assigns into alerts, links, and disclosures. |
| `coupon_live.ex`, `promotion_code_live.ex` and tests | Existing catalog detail and exact relations, inspection-only | ✓ VERIFIED | Repo reads/preloads feed detail fields and related-resource links; no write action bands. |
| `connect_accounts_live.ex`, `connect_account_live.ex` and tests | Scoped Stripe snapshot and separate local override | ✓ VERIFIED | Scoped account reads feed provider snapshot and local override; save handler revalidates account and writes local data after StepUp. |
| `phase238-admin-events-webhooks.spec.js`, seed fixture script, `.github/workflows/ci.yml` | Mounted browser evidence in recurring shard, including forced host theme | ✓ VERIFIED | The spec, deterministic fixtures, and mounted assertions are substantive. The normal sharded job includes the unrestricted spec; shard 1 adds the full spec with `ACCRUE_HOST_ADMIN_THEME=dark` and global seed skipped. Local post-fix evidence: normal 2/2; forced-dark 2 passed, 1 expected skip, repeated three times against the same DB. |

## Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Webhooks selection | Current owner-scoped delivery | `Webhooks.detail/2` | WIRED | Selection IDs are canonicalized and each row is re-resolved; inaccessible/foreign IDs skip. |
| Confirmation | Step-up and replay continuation | `StepUp.require_fresh/3`, `StepUp.verify/2` | WIRED | Confirmation consumes the pending intent before requesting fresh authorization. |
| Replay claim | Existing local DLQ and audit | `requeue_delivery/2`, `Events.record`, `Auth.log_audit` | WIRED | Locked claim path rechecks owner/status; outcomes drive both audit data and user copy. |
| Events/Webhooks routes | Local record queries | `Events`, `Webhooks` query modules | WIRED | List/detail render actual DB query values, not static return fixtures; test failure seam only affects test env. |
| Coupon list/detail | Promotion-code detail | Exact record IDs + `ScopedPath` | WIRED | Reciprocal links resolve exact catalog IDs and retain route context. |
| Connect query | Provider observation and local override | Scoped query + separate data fields | WIRED | Snapshot facts and local fee setting render separately; missing provider values stay unavailable/unknown. |
| Override submit | Current owner/account → fresh StepUp → local save/audit | LiveView handler | WIRED | No Stripe write call is present; tests assert provider fields survive local save. |
| Phase spec | Host Playwright runner/required CI shard | Existing Playwright config and normal plus forced-theme CI invocations | WIRED | Discovery reports 2 normal tests and 3 with forced theme. The required shard is unrestricted; forced-theme invokes the entire spec, including the keyboard replay journey. Only the theme-picker-only journey is skipped when the host policy locks the picker. |

## Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| Events list/detail | event rows and summary | Owner-scoped Ecto `Events` queries | Yes | ✓ FLOWING |
| Webhooks list/detail | delivery rows, attempts, derived events | Owner-scoped `Webhooks` queries and local attempt history | Yes | ✓ FLOWING |
| Coupon/code detail | coupon and promotion-code records | `Repo.get`/list queries and parent-coupon preload | Yes | ✓ FLOWING |
| Connect list/detail | account fields and local override | Scoped `ConnectAccounts` query and account `data` | Yes | ✓ FLOWING |
| Browser journeys | visible state | Seeded host DB fixtures rendered by mounted LiveViews | Yes | ✓ FLOWING |

## Behavioral Spot-Checks

The ExUnit totals below are recorded in `238-VALIDATION.md` and were not rerun. Browser evidence was rerun in this verification.

| Behavior | Command/evidence | Result | Status |
|---|---|---|---|
| Core package regression | `cd accrue && mix test` (recorded validation) | 2,078 passed, 11 excluded | ✓ PASS (recorded) |
| Admin package regression | `cd accrue_admin && mix test --warnings-as-errors` (recorded validation) | 612 passed | ✓ PASS (recorded) |
| Default mounted Phase 238 journey | `npx playwright test e2e/phase238-admin-events-webhooks.spec.js --project=chromium-desktop` | 2/2 passed after the final focus fix (recorded in `238-VALIDATION.md`) | ✓ PASS (recorded local evidence) |
| Named keyboard/focus journey | `npx playwright test ... --grep "keyboard reachable"` | 1/1 passed | ✓ PASS |
| Default test discovery | `npx playwright test --list e2e/phase238-admin-events-webhooks.spec.js` | 2 tests discovered | ✓ PASS |
| Forced-theme discovery | `ACCRUE_HOST_ADMIN_THEME=dark npx playwright test --list ...` | 3 tests discovered; theme-specific test is conditional | ✓ PASS |
| Full host-forced dark lane | `ACCRUE_HOST_ADMIN_THEME=dark ACCRUE_HOST_SKIP_PLAYWRIGHT_GLOBAL_SEED=1 npx playwright test e2e/phase238-admin-events-webhooks.spec.js --project=chromium-desktop` | Post-fix: 2 passed, 1 expected skip in three consecutive runs after the mutating default lane; same fixture DB and SQL Sandbox rollback isolation | ✓ PASS (recorded local evidence) |
| Asset and browser-spec syntax | `NPM_CONFIG_CACHE=/private/tmp/accrue-npm-cache mix accrue_admin.assets.build`; `node --check examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js` | Asset build succeeded; syntax check exited 0. Warnings only for absent Storybook-built assets. | ✓ PASS |
| Named host-forced theme test | Same env, with `--grep "host-forced Admin theme"` | 1/1 passed | ✓ PASS |
| Generic root `mix test` | Repository root | Not a Mix project; inapplicable | N/A |

The previous failing assertion is directly exercised in both the default and forced-dark full lanes and now passes. The forced-dark run also verifies the forced policy against a conflicting stored preference. All browser results above are local evidence; remote CI was not run.

## Probe Execution

No probe-based verification is declared or implied by the Phase 238 plans or success criteria. No phase probe paths were found.

## Requirements Coverage

| Requirement | Source plans | Description | Status | Evidence |
|---|---|---|---|---|
| ADM-07 | 238-01, 238-02, 238-05 | Investigate events/deliveries and replay only eligible deliveries with precise evidence, step-up, and honest partial results. | ✓ SATISFIED | Scoped LiveViews, safe replay handlers, named ExUnit cases, and mounted Playwright evidence. |
| ADM-08 | 238-03, 238-04, 238-05 | Inspect coupon, promotion-code, and Connect states/actions without unsupported capabilities. | ✓ SATISFIED | Read-only catalog pages, provider/local Connect separation, local override tests, and mounted checks. |

No additional requirements are mapped to Phase 238 in `REQUIREMENTS.md`; no orphaned requirement was found.

### Decision Coverage

No `CONTEXT.md` exists in the phase directory, so the decision-coverage gate skipped: “No CONTEXT.md - nothing to check.”

## Test Quality Audit

| Test file group | Linked requirements | Disabled tests | Circular fixture generation | Assertion strength | Verdict |
|---|---|---:|---:|---|---|
| Phase 238 LiveView/ExUnit suites | ADM-07, ADM-08 | 0 found | 0 found | Behavioral and value assertions: exact IDs, statuses, mutations, audit counts, rendered copy | ✓ PASS |
| `phase238-admin-events-webhooks.spec.js` | ADM-07, ADM-08 | 1 intentional skip when theme is forced (theme-picker journey only) | Seed fixture script is independent setup, not expected-value generation from the system under test | Mounted behavior and value assertions; forced-dark run also exercises replay keyboard journey | ✓ PASS |

No disabled requirement-linked tests (the one conditional skip is only the theme-picker journey under a locked host policy) or circular expected-value generation patterns were found.

### Prohibition Checks

| Plan | Must not happen | Deterministic enforcement evidence | Status |
|---|---|---|---|
| 238-01 | Queue acceptance presented as completed processing | `copy_test.exs` exact queue wording; mounted spec asserts queue is not processing and rejects “processed successfully” claim | ✓ VERIFIED |
| 238-03 | Inspection surfaces imply unsupported coupon/code create or edit | Mounted spec asserts create/edit controls absent; route tests and read-only LiveViews verify no mutation surface | ✓ VERIFIED |
| 238-04 | Provider readiness conflated with local override | `connect_account_live_test.exs` and `ConnectAccountLive` render/provider-field tests verify separate labels and local-only save | ✓ VERIFIED |

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| — | — | No debt markers, placeholder implementations, empty handlers, or static data stubs found in the changed Phase 238 implementation paths. | — | Filter `placeholder` attributes are standard input hints, not placeholder implementations. |

Code review: the original 24-path review and latest incremental review of `focus_trap.js`, `webhooks_live.ex`, and the browser spec are clean with zero findings. Review disposition lists 10 earlier findings, all fixed. Nyquist validation reports zero gaps. The security audit records 14 threats closed and zero open threats. The apparent `return null` anti-pattern at `layouts.ex` is only the intentional malformed-cookie decode fallback in `safeDecodeTheme`, not a placeholder path.

## Human Verification Required

None. All stable in-scope behavior has deterministic source, test, or mounted-browser evidence; no human UAT is required.

## Gaps Summary

Core event/delivery behavior, replay eligibility, coupon/promotion inspection, Connect provider/local separation, and the responsive/theme journeys have passing deterministic evidence. The prior gap is closed by the single-attempt initial-focus behavior and three passing forced-dark full-lane runs, including keyboard traversal. CI selects this spec in its normal required Playwright shard and runs the full forced-dark spec on shard 1. The required result is supported by local runs; no remote CI run is claimed.

The refreshed UI audit is advisory and records no blockers. It could not inspect screenshots because the served local endpoint was not confirmed to be the Admin app; it flags copy/spacing and visual balance for later inspection. The changed behavior, theme policy, responsiveness, and keyboard paths have repeatable mounted evidence. The earlier focus failure was caused by delayed repeat focus; the current hook performs one initial-focus attempt and mounted tests verify traversal. The report uses recorded local test evidence and makes no claim that remote CI ran. Phase context decision coverage was skipped because no `CONTEXT.md` exists. No additional unverified new-scope concern was found.

---

_Verified: 2026-10-09T06:02:26Z_  
_Verifier: the agent (gsd-verifier)_
