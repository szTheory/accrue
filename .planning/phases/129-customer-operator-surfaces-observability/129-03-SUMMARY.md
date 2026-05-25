---
phase: 129-customer-operator-surfaces-observability
plan: 03
subsystem: ui
tags: [accrue_portal, liveview, dunning, recovery-banner, phoenix-component, braintree, stripe]

# Dependency graph
requires:
  - phase: 128-campaign-engine-foundation-idempotency
    provides: "Subscription.dunning_campaign_active?/1 + dunning_campaign_started_at anchor (D-08); Subscription.past_due?/1"
provides:
  - "Customer-facing recovery banner in the portal subscription detail LiveView (DUN-06 / SC#1)"
  - "recovery_prompt?/1 visibility gate (past_due OR active campaign)"
  - "update_pm_path/2 provider-aware CTA dispatch (braintree -> add-PM route; others -> in-portal list)"
  - "AccruePortal.Copy.subscription_recovery_heading/body/cta (jargon-free, CTA label shared with card_expiring_soon email)"
  - "AccruePortal.Path.payment_methods_new/1 helper"
affects: [130-provider-honesty-fake-lane-host-wiring, dunning, portal]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Conditional :if banner section reusing existing portal-* classes (no new CSS), gated on already-loaded @subscription"
    - "Provider dispatch via %Subscription{processor: \"braintree\"} pattern-match clauses, mirroring cancel_subscription/1"
    - "Render tests assert decoded element content via has_element?/3 (HTML-entity safe) rather than raw-HTML substring"

key-files:
  created: []
  modified:
    - accrue_portal/lib/accrue_portal/live/subscription_live.ex
    - accrue_portal/lib/accrue_portal/copy.ex
    - accrue_portal/lib/accrue_portal/path.ex
    - accrue_portal/test/accrue_portal/live/subscription_live_test.exs
    - accrue_portal/mix.lock

key-decisions:
  - "Non-Braintree CTA defaults to the in-portal /payment-methods list (RESEARCH A4 safe default), never the Braintree-only hosted-fields form"
  - "update_pm_path/2 implemented as a 2-clause pattern-match helper (mirrors cancel_subscription/1), not the single def the acceptance grep literal assumed"
  - "Banner tone is neutral .portal-card with role=alert (attention, not error) per UI-SPEC; no .portal-inline-error red treatment"

patterns-established:
  - "Recovery banner reuses .portal-card / .portal-actions / .portal-button-primary verbatim — zero new visual vocabulary (UI-SPEC hard rule)"
  - "Provider-aware deep-link helper dispatches on subscription.processor and always returns a real in-portal path (never a dead href)"

requirements-completed: [DUN-06]

# Metrics
duration: 6min
completed: 2026-05-25
---

# Phase 129 Plan 03: Customer Recovery Banner Summary

**Conditional, provider-aware recovery banner in the portal subscription LiveView — a past-due/active-campaign customer sees "Your payment didn't go through" with a single "Update payment method" CTA that deep-links Braintree→/payment-methods/new and Stripe/others→the in-portal /payment-methods list, gated on `recovery_prompt?/1`.**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-05-25T06:29:00Z
- **Completed:** 2026-05-25T06:35:26Z
- **Tasks:** 1 (TDD: RED → GREEN, no refactor needed)
- **Files modified:** 5 (3 implementation, 1 test, 1 lockfile)

## Accomplishments
- Conditional `<section data-role="subscription-recovery-banner">` inserted before the main portal card in `render/1`, gated on `recovery_prompt?/1`.
- `recovery_prompt?/1` calls the canonical predicates `Subscription.past_due?/1` OR `Subscription.dunning_campaign_active?/1` (D-10) — no status-atom comparison in the template.
- `update_pm_path/2` dispatches on `subscription.processor` (D-11): Braintree → `/payment-methods/new`; non-Braintree → in-portal `/payment-methods` list (RESEARCH A4 safe default). Always returns a real path — never a dead/absent href.
- Three `AccruePortal.Copy` defs (`subscription_recovery_heading/body/cta`) with the UI-SPEC prescribed wording; the CTA label "Update payment method" matches the `card_expiring_soon` email verbatim. Copy leaks no internal terms (dunning/campaign/past_due/step).
- `AccruePortal.Path.payment_methods_new/1` helper added (no hardcoded full URL).
- Four render tests (show/hide + provider-correct CTA hrefs) using `live/2` + `has_element?/2,3` (no Chrome).

## Task Commits

1. **Deps lock sync (blocking-issue fix)** — `4609ec17` (chore)
2. **Task 1 RED: failing recovery-banner render tests** — `ba49409e` (test)
3. **Task 1 GREEN: provider-aware recovery banner** — `5113a60b` (feat)

_TDD: RED (test) → GREEN (feat). No refactor commit — implementation was minimal and clean._

## Files Created/Modified
- `accrue_portal/lib/accrue_portal/live/subscription_live.ex` — banner markup in `render/1` + `recovery_prompt?/1` + `update_pm_path/2` helpers
- `accrue_portal/lib/accrue_portal/copy.ex` — `subscription_recovery_heading/body/cta`
- `accrue_portal/lib/accrue_portal/path.ex` — `payment_methods_new/1`
- `accrue_portal/test/accrue_portal/live/subscription_live_test.exs` — `describe "recovery banner (DUN-06)"` with 4 tests + 2 private helpers
- `accrue_portal/mix.lock` — synced transitive `rendro` 0.1.0 → 0.3.0 to match `accrue` core's requirement (blocking deps drift)

## Decisions Made
- **Non-Braintree CTA destination = in-portal `/payment-methods` list** (RESEARCH A4 / UI-SPEC default). A Stripe customer never lands on the Braintree-only hosted-fields form, which would be a dead recovery path (revenue loss / T-129-10).
- **`update_pm_path/2` as a 2-clause pattern-match helper** mirroring the existing `cancel_subscription/1` (2 clauses) and `preview_supported?/1` precedents — the plan body explicitly mandates the `%Subscription{processor: "braintree"}` pattern-match shape.
- **Neutral `.portal-card` + `role="alert"`** (attention, not alarm) per UI-SPEC banner-tone decision — not the red `.portal-inline-error` treatment.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Synced accrue_portal mix.lock to rendro ~> 0.3.0**
- **Found during:** Task 1 (first test run)
- **Issue:** `mix test` aborted with "rendro does not match the requirement \"~> 0.3.0\", got \"0.1.0\"". The `accrue` core (path dep) requires `rendro ~> 0.3.0` and locks it at 0.3.0, but the `accrue_portal` lock was stale at 0.1.0 — a pre-existing transitive lock drift that blocked the portal from compiling at all.
- **Fix:** `mix deps.get` in `accrue_portal` (resolved rendro 0.1.0 → 0.3.0 plus minor transitive bumps already permitted by the version constraints). NOT a package substitution — same package, version aligned with what core already locks.
- **Files modified:** `accrue_portal/mix.lock`
- **Verification:** `mix compile --warnings-as-errors` and full `mix test` (34 tests, 0 failures) both green.
- **Committed in:** `4609ec17` (separate chore commit, ahead of the test commit)

### Acceptance-criteria literalism notes (not deviations — implementation matches plan intent)

- **`grep -c "defp update_pm_path"` returns 2, not the literal `1` in the acceptance grep.** The plan body mandates a 2-clause Braintree/non-Braintree dispatch "mirroring the `cancel_subscription/1` `%Subscription{processor: \"braintree\"}` pattern-match shape" — and the `cancel_subscription/1` precedent itself is 2 `defp` lines. The 2-clause form is the required implementation; the `==1` was a spec-wording oversight that assumed a single line.
- **`grep -ci "dunning\|campaign\|past_due" copy.ex` returns 2 (whole file).** Both hits are pre-existing `Subscription.past_due?(subscription)` *function calls* in `subscription_lifecycle_label/summary`, not customer-facing copy and not added by this plan. The three NEW recovery def bodies (lines 177–184) contain none of the forbidden terms — the criterion's actual intent.

---

**Total deviations:** 1 auto-fixed (1 blocking deps-lock drift).
**Impact on plan:** The deps fix was required to compile/test the portal at all; no scope creep. Feature implementation followed the plan and UI-SPEC exactly.

## Issues Encountered
- **HTML-entity escaping in render assertions:** the served markup encodes the apostrophe in "Your payment didn't go through" as `&#39;`, so a raw `html =~ "...didn't..."` substring assert failed even though the banner rendered correctly. Resolved by asserting decoded element content via `has_element?(view, selector, text)` (which compares against decoded text), making the tests robust to escaping. The CTA-href regex still works on raw HTML since href values aren't entity-encoded.

## Threat Model Compliance
- **T-129-08 (broken access control):** banner reads ONLY `@subscription` (loaded via `Authorize.subscription/2` in `mount/3` under the customer's session). No new data path added. ✓
- **T-129-09 (info disclosure):** copy is static jargon-free wording; CTA href is an in-portal relative path. No PII, no Stripe/Braintree secrets, no card data. ✓
- **T-129-10 (broken recovery path):** `update_pm_path/2` dispatches on processor and always returns a real path; a Stripe customer never lands on the Braintree-only form. ✓

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- DUN-06 / SC#1 shipped: portal banner is live and provider-correct.
- Companion admin read-only dunning-state panel (DUN-07) and observability (DUN-08) are the remaining Phase 129 surfaces, tracked in their own plans.
- The `payment_methods_new/1` Path helper and the `update_pm_path/2` provider-dispatch shape are reusable seams for any future portal deep-links.

## Self-Check: PASSED

- All 4 modified source/test files present on disk; SUMMARY present.
- All 3 task commits (`4609ec17`, `ba49409e`, `5113a60b`) exist in git history.
- `mix compile --warnings-as-errors` clean; full `accrue_portal` suite 34 tests / 0 failures.

---
*Phase: 129-customer-operator-surfaces-observability*
*Completed: 2026-05-25*
