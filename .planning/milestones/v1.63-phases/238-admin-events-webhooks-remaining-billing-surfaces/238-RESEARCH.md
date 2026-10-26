# Phase 238: Admin Events, Webhooks & Remaining Billing Surfaces — Research

**Researched:** 2026-10-08  
**Domain:** Phoenix LiveView operator workflows, billing event evidence, retry safety, accessible Admin UI  
**Confidence:** HIGH for repository behavior and test seams; MEDIUM for external framework guidance

## User Constraints

- “Automate stable acceptance at the cheapest credible seam, put recurring checks in blocking CI, target zero human UAT, and hand off only irreducible external/subjective/product decisions.”
- Phase scope: investigate local events and webhook deliveries; retry/replay only eligible work; inspect existing coupon, promotion-code, and Connect surfaces without implying unsupported capabilities.
- Preserve existing evidence and CI machinery; add only checks tied to named failure modes, not a wholesale CI rearchitecture. [VERIFIED: `.planning/notes/2026-10-07-accrue-ui-refinement-scope.md:239-265`; exact guardrail: “Exhaustive automation can become its own project. Reuse registries, fixtures, jobs and required GSD evidence; add only checks with a named failure they can discriminate, including a known-positive control for absence guards.”]

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADM-07 | Operators can investigate events and webhook deliveries and replay only eligible deliveries with precise evidence, step-up, and honest partial-selection outcomes. | Existing Events/Webhooks LiveViews, DLQ replay flows and tests; the bulk replay edge below needs focused failure/partial-result coverage. |
| ADM-08 | Operators can inspect existing coupon, promotion-code, and Connect states and actions without the UI implying unsupported capabilities. | Existing list/detail LiveViews and tests already define the bounded read surfaces and local Connect fee-override action. |

## Summary

Use the existing Phoenix LiveViews, query modules, fixtures, and Playwright host lane. Keep event rows as local audit/billing history and webhook rows as delivery/processing evidence. Detail pages already expose actor/subject/source links, lazy activity and payload sections, and dispatch attempts. Single replay already gates the button on failed/dead status, requires fresh step-up, calls the DLQ primitive, and presents its outcome. [VERIFIED: `accrue_admin/lib/accrue_admin/live/webhook_live.ex:369-370`; verbatim: `defp replayable?(%WebhookEvent{status: status}), do: status in [:failed, :dead]`]

Prioritize safe selection semantics and evidence. The current bulk path snapshots selected IDs/count, scopes IDs at confirmation, then requeues sequentially and halts on the first error. Its success audit stores both submitted count and actual requeued count, while the visible success message uses the submitted count. That creates a concrete plan target: revalidate eligibility at execution, preserve per-row outcomes (including already-ineligible and mid-batch failures), audit attempted/requeued/skipped/failed counts accurately, and never announce full success from submitted selection size. Do not expand delivery semantics or introduce new billing actions. [VERIFIED: `accrue_admin/lib/accrue_admin/live/webhooks_live.ex:110-145,491-507`; exact success branch: `Copy.webhooks_retry_success(count)`]

**Primary recommendation:** Cover invariant-heavy selection/eligibility/step-up/audit behavior with ExUnit; cover the rendered keyboard, responsive, theme, and end-to-end evidence journey in the existing required host-integration Playwright lane. Keep coupon and promotion-code work inspection-only; treat Connect readiness as provider-reported Stripe state and fee override as a local setting. No new package is needed.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Event and delivery query/scope | API / Backend | Browser / Client | Ecto/query code owns authoritative owner filtering and facts; LiveView renders links and filters. |
| Replay eligibility, step-up, queueing and audit | API / Backend | Browser / Client | Server-side action handlers must recheck current eligibility and scope; the browser only confirms intent and communicates accepted/failed/partial results. |
| Coupon and promotion-code inspection | API / Backend | Browser / Client | Existing query modules supply persisted facts; detail/list views clarify terms, usage, restrictions, and relationships. |
| Connect readiness and fee override | API / Backend | Browser / Client | Persisted Stripe account observation and local override are distinct state sources; validate/save remains server-owned. |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix LiveView | `~> 1.1` | Stateful Admin pages and event handling | Existing Admin architecture; use current LiveView test helpers and browser-rendered tests. [VERIFIED: `accrue_admin/mix.exs:39-44`; verbatim dependency: `{:phoenix_live_view, "~> 1.1"}`] |
| Phoenix | `~> 1.8` | HTTP/router and LiveView integration | Existing mounted Admin package. [VERIFIED: `accrue_admin/mix.exs:39-44`; verbatim dependency: `{:phoenix, "~> 1.8"}`] |
| ExUnit + Ecto test repo | Existing | Deterministic domain/LiveView behavior tests | Current tests use isolated test repositories and explicit fixtures; avoid real processor/network calls. |
| Playwright Test | `1.59.1` in Admin package | Chromium desktop/mobile interaction proof | Existing browser suite and CI job already run mounted Admin/host journeys. [VERIFIED: `accrue_admin/package.json:21-25`; verbatim: `"@playwright/test": "1.59.1"`] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `@axe-core/playwright` | `^4.11.3` in Admin | Automated detectable accessibility checks | Scan changed route states (especially confirmation, step-up, partial/error) in existing browser tests. [VERIFIED: `accrue_admin/package.json:21-25`; verbatim: `"@axe-core/playwright": "^4.11.3"`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing ExUnit + Playwright lanes | New test framework or standalone CI system | Adds dependencies and maintenance. No identified gap requires a new framework; add a narrowly targeted test to the current host integration lane. |
| Human UAT for stable acceptance | Deterministic fixtures and browser assertions | Human inspection is not repeatable CI evidence. Keep only bounded subjective taste feedback optional; do not make it a recurring completion gate. |

**Installation:** None. Reuse locked dependencies.

## Package Legitimacy Audit

No external packages are recommended or installed by this phase; package legitimacy checks are not applicable.

## Architecture Patterns

### System Architecture Diagram

```text
Operator selects/filter records
          ↓
Phoenix LiveView ──→ owner-scoped Ecto query ──→ local event / delivery facts
      │                                           │
      ├─ detail links, activity, payload          └─ attempts + derived event evidence
      │
      └─ retry intent → fresh owner/status check → fresh step-up → DLQ requeue
                                                    ↓
                                         audit result + truthful outcome

Coupon / promotion-code / Connect views → existing query + local persisted state
                                        → read-only inspection, except local fee override
```

### Recommended Project Structure

Keep the existing ownership: `accrue_admin/lib/accrue_admin/live/` for view behavior, `accrue_admin/lib/accrue_admin/queries/` for scoped reads, adjacent `accrue_admin/test/accrue_admin/live/` for LiveView tests, and `examples/accrue_host/e2e/` for mounted browser journeys. Do not add a parallel registry or evidence framework.

### Pattern 1: Revalidate then perform replay

**What:** Treat browser-selected IDs and counts as untrusted intent. At confirmation, re-resolve each record within the current owner scope and current eligible status, perform the existing DLQ requeue only for eligible rows, and retain an outcome per row. Apply fresh step-up to the bulk mutation as well as the single-row mutation if bulk currently bypasses it.

**When to use:** Bulk or single operator actions that can enqueue work or write audit history.

**Example:** Existing single replay handles the error/result around `DLQ.requeue`; keep that primitive and the current audit boundary. For bulk, use a reduction that accumulates outcomes instead of halting after the first failure. Do not claim that enqueued/accepted means downstream processing completed.

### Pattern 2: Keep source facts distinct

**What:** Render local event/audit evidence separately from incoming webhook delivery state, attempts, and derived events. Lazy-load payload/activity only through explicit disclosure; link related objects using the active mount and owner scope.

**When to use:** Events/Webhooks list and detail routes; preserve evidence context during return/navigation.

### Anti-Patterns to Avoid

- Using selected count as attempted, eligible, requeued, or processed count.
- Treating DLQ acceptance/requeue as proof the downstream handler processed successfully.
- Enabling bulk replay based only on client checkbox state or checking owner scope without rechecking status.
- Describing coupon or promotion-code create/edit actions when this scope is inspection-only.
- Presenting a local Connect fee override as Stripe account readiness or a remote Stripe mutation.
- Treating an empty/unavailable evidence read as a real empty history.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Scoped record listing and links | New ad hoc query / link builder | Existing query modules, `ScopedPath`, and `DataTable` | Avoid drift in owner scope, filter/return context, and list state. |
| Replay operation | New queue or processor API | Existing `Accrue.Webhooks.DLQ.requeue/1` and current audit mechanism | Phase refines the operator contract; it does not expand billing/provider capabilities. |
| Confirmation and step-up UI | Custom overlay/auth mechanism | Existing detail drawer, step-up modal, and `StepUp` helper | Keeps established focus and freshness behavior. |
| Accessible browser evidence | CSS-only or screenshot-only assertions | Role/name assertions, keyboard operations, axe scan on revealed states, narrow viewport checks | Pixel equality and static markup cannot prove interaction/accessibility behavior. |

## Common Pitfalls

### Pitfall 1: Bulk replay reports a false full success

**What goes wrong:** A partially eligible or mid-batch failing selection gets a blanket success message based on the original selection count.  
**Why it happens:** Selection count is captured before confirmation, ownership filtering is not eligibility revalidation, and `replay_scoped_rows/1` halts at first error.  
**How to avoid:** Add mixed-status, changed-before-confirmation, wrong-owner, duplicate-ID, and injected mid-batch failure cases. Persist/audit explicit selected, eligible, attempted, requeued, skipped, failed counts and row outcomes.  
**Warning signs:** UI says “retried N” where N exceeds actual requeue count; audit has a count but no accepted/failed distinction.

### Pitfall 2: Queue acceptance is presented as processing completion

**What goes wrong:** Operators assume the target handler has finished when a retry has only been accepted/requeued.  
**Why it happens:** “Retry succeeded” collapses queueing and processing into one state.  
**How to avoid:** Say “queued/requeued” for acceptance; show processing only from a later observed attempt/event. Test success, timeout/unknown, and failure copy separately.

### Pitfall 3: Provider observations and local policy collapse

**What goes wrong:** Stripe Connect readiness is confused with local platform fee override; coupon and promotion-code nouns or unsupported controls are conflated.  
**Why it happens:** Similar cards and badges hide different authorities and actions.  
**How to avoid:** Label provider-specific observation, local override/default policy, coupon terms, code restrictions/usage, and their links independently. Cover unknown/unavailable states explicitly.

### Pitfall 4: UI-only tests substitute for server guarantees

**What goes wrong:** The browser hides an ineligible button, but forged/stale events still replay work.  
**Why it happens:** Eligibility is checked at render time only.  
**How to avoid:** ExUnit must invoke event handlers with stale/foreign IDs and assert no queue mutation/audit success; browser tests then verify understandable interaction and evidence.

## Code Examples

Current eligibility uses the literal statuses `[:failed, :dead]`. [VERIFIED: `accrue_admin/lib/accrue_admin/live/webhook_live.ex:369-370`; exact source: `defp replayable?(%WebhookEvent{status: status}), do: status in [:failed, :dead]`]

Bulk handling currently enters through `handle_event("confirm_retry_selected", ...)`, then resolves selected IDs via `scope_selected_ids/2` before calling `replay_scoped_rows/1`. [VERIFIED: `accrue_admin/lib/accrue_admin/live/webhooks_live.ex:110-153`; exact source: `def handle_event("confirm_retry_selected", _params, socket) do`]

Official Phoenix LiveViewTest guidance describes process-based view assertions and separate disconnected/connected mount testing; apply that to deterministic server-render/handler contracts. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveViewTest.html] Official Playwright guidance says automated scans detect common issues but not all accessibility violations; use axe and keyboard automation as repeatable evidence, with no claim of full WCAG certification. [CITED: https://playwright.dev/docs/accessibility-testing]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Human UAT as recurring proof of deterministic states | ExUnit for invariants plus rendered Playwright journeys in required CI | Phase 238 planning default | Repeatable stable acceptance; hand off only subjective/external questions. |
| Screenshot-only acceptance | Semantic state and action assertions plus screenshots as supporting evidence | Current project guardrail | Prevents visual snapshots from substituting for truth or interaction coverage. |

**Deprecated/outdated:** Manual-only host UAT is not sufficient as the recurring gate for phase-owned stable behavior; route phase checks through the required CI workflow.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The existing `ci.yml` host-integration and Playwright shard are the lowest-cost merge-blocking home for Phase 238 browser coverage. | Validation Architecture | A changed path filter or branch protection configuration could make the lane non-required; verify the actual required-check bundle in the plan/verification. |
| A2 | Current coupons and promotion codes remain inspection-only for this milestone. | Architecture Patterns | Adding create/edit would expand committed product scope and needs a separate explicit requirement. |

## Open Questions (RESOLVED)

1. **Bulk replay confirmation and step-up — RESOLVED:** Require fresh server-side step-up after explicit confirmation, matching the single-row replay safety boundary. Plan 238-01 covers rejection without mutation and per-row revalidation before each queue call.
2. **Partial result contract — RESOLVED:** Record `selected`, `eligible`, `attempted`, `queued`, `skipped`, and `failed` counts from ordered per-row outcomes. User-facing copy reports queue acceptance and reserves “processed” for later observed delivery evidence. Plan 238-01 tests mixed, stale, duplicate, and mid-batch failure cases.
3. **CI check requirement — RESOLVED:** Add the phase browser spec to the existing `.github/workflows/ci.yml` host-integration Playwright shard, which is labeled as the required deterministic gate and runs the shard. Local configuration proves selection, not repository branch-protection settings; execution must record the actual CI result without claiming more. [VERIFIED: `.github/workflows/ci.yml:1329-1341,1573-1583`; exact label: `name: Host integration (required deterministic gate)`]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Phoenix dependencies | ExUnit and LiveView implementation | ✓ in project/CI definition | Elixir `~> 1.19`; Phoenix `~> 1.8`; LiveView `~> 1.1` | Existing CI setup; no package install beyond lockfiles. |
| Node / Playwright | Browser evidence | ✓ in project/CI definition | Admin Playwright `1.59.1`; Node 22 in CI | Use ExUnit for invariants if local browser is unavailable; merge gate still runs browser lane. |
| Chromium | Browser lane | ✓ installed by CI | CI-installed Chromium | CI install step. |

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit / Phoenix LiveViewTest; Playwright Test `1.59.1` |
| Config file | `accrue_admin/playwright.config.js` |
| Quick run command | `cd accrue_admin && mix test test/accrue_admin/live/webhook_replay_test.exs test/accrue_admin/live/events_live_test.exs test/accrue_admin/live/coupons_live_test.exs test/accrue_admin/live/promotion_codes_live_test.exs test/accrue_admin/live/connect_accounts_live_test.exs` |
| Full browser suite | `cd examples/accrue_host && npm run e2e` |
| Merge-blocking gate | `.github/workflows/ci.yml` job `host-integration`, Playwright shard; keep the focused mounted route journey in its existing suite. |

Commands use existing scripts/dependencies, not new tooling. The Admin browser package defines `"e2e": "env -u NO_COLOR playwright test --project=chromium-desktop --project=chromium-mobile"`. [VERIFIED: `accrue_admin/package.json:4-6`; exact source: `"e2e": "env -u NO_COLOR playwright test --project=chromium-desktop --project=chromium-mobile"`]

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ADM-07 | Event links, owner scope, filters, lazy activity/payload | LiveView + mounted browser | Focused ExUnit files above; `cd examples/accrue_host && npx playwright test e2e/phase13-canonical-demo.spec.js` | ✅ existing tests; extend changed journey |
| ADM-07 | Single/bulk eligibility revalidation, step-up, audit, partial/failure outcomes | ExUnit + mounted browser | Focused ExUnit files above; targeted host Playwright spec | ✅ replay tests exist; add named counterexamples for current bulk gap |
| ADM-08 | Existing coupon/promo inspection, exact relationships and unavailable/empty states | LiveView + browser route smoke | Focused ExUnit files above; targeted host route journey | ✅ existing list/detail tests |
| ADM-08 | Stripe Connect readiness versus local fee override, validation/step-up/result | LiveView + browser interaction | Focused ExUnit files above; targeted host route journey | ✅ existing list/detail tests |
| ADM-07/08 | Keyboard, responsive, theme, overlays, action outcomes | Playwright browser | `cd examples/accrue_host && npx playwright test e2e/phase13-canonical-demo.spec.js` plus focused new/extended route spec | ✅ existing host Playwright setup; expand route/state coverage |

### Sampling Rate

- **Per task commit:** Focused ExUnit test file(s) for changed behavior.
- **Per wave merge:** Full affected package tests plus named mounted browser route journey.
- **Phase gate:** All phase-owned deterministic checks green in required CI; no confirmation-only human UAT for stable acceptance.

### Wave 0 Gaps

- [ ] Add regression cases for bulk stale/ineligible IDs, mixed eligibility, ownership change, and mid-batch requeue failure/partial audit/result.
- [ ] Add or extend mounted browser coverage for selection confirmation, step-up, accepted-versus-processed wording, partial result, coupon/promotion-code inspection, and Connect local override outcomes.
- [ ] Ensure the phase-owned browser test is selected by the required `ci.yml` host Playwright shard; avoid relying on the manual-only host UAT workflow.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Existing Admin authentication adapter and fresh step-up for consequential replay/override. |
| V3 Session Management | yes | Freshness must be checked server-side at action time; do not trust rendered state. |
| V4 Access Control | yes | Re-resolve every selected event/delivery under the active owner scope at confirmation. |
| V5 Input Validation | yes | Treat IDs/counts as untrusted; validate row state and action arguments server-side. |
| V6 Cryptography | no new crypto | Reuse existing step-up token/verification helpers; no new cryptographic code. |

### Known Threat Patterns for Phoenix LiveView / billing operations

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Forged or stale replay event | Tampering / Elevation of privilege | Recheck owner and eligibility in the action handler; require fresh step-up; audit only actual results. |
| Cross-owner selected IDs | Information disclosure / Tampering | Resolve IDs under current owner scope and never report inaccessible foreign-record details. |
| Payload rendering leaks or unsafe JSON output | Information disclosure / Tampering | Preserve escaped structured rendering; test sensitive-field omission and hostile JSON strings. |
| Duplicate bulk submission | Repudiation / Tampering | Preserve existing replay primitive semantics; disable pending submission and test repeat confirmation/idempotency at the action boundary. |

## Sources

### Primary (HIGH confidence)

- `.planning/REQUIREMENTS.md` — ADM-07/ADM-08 exact scope.
- `.planning/notes/2026-10-07-accrue-ui-refinement-scope.md` — route surfaces, replay pitfalls, CI/accessibility guardrails, and scope exclusions.
- `accrue_admin/lib/accrue_admin/live/{events,event,webhooks,webhook,coupons,coupon,promotion_codes,promotion_code,connect_accounts,connect_account}_live.ex` — current LiveView behavior.
- `accrue_admin/test/accrue_admin/live/` and `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs` — existing deterministic contracts.
- `.github/workflows/ci.yml` — required host integration and Playwright shard.

### Secondary (MEDIUM confidence)

- [Phoenix LiveViewTest](https://phoenix-live-view.hexdocs.pm/Phoenix.LiveViewTest.html) — process-based LiveView testing and disconnected/connected mount tests. Retrieved through web search; seam classified websearch confidence LOW, so framework guidance is supplementary to existing repo practice.
- [Playwright accessibility testing](https://playwright.dev/docs/accessibility-testing) — automated accessibility testing catches only some issue classes and should not be presented as full conformance. Retrieved through web search; seam classified websearch confidence LOW.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — read from package/mix definitions and existing test harness.
- Architecture: HIGH — direct inspection of existing LiveViews, helpers, and current handlers.
- Pitfalls: HIGH — bulk replay discrepancy is visible in current handler/count/audit path.
- External testing guidance: LOW — official docs, but fetched through websearch and used only as supporting guidance.

**Research date:** 2026-10-08  
**Valid until:** 2026-11-07
