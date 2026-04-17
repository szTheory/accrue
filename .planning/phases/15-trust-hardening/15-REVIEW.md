---
phase: 15-trust-hardening
reviewed: 2026-04-17T09:52:50Z
depth: standard
files_reviewed: 18
files_reviewed_list:
  - .github/workflows/ci.yml
  - CONTRIBUTING.md
  - RELEASING.md
  - SECURITY.md
  - guides/testing-live-stripe.md
  - scripts/ci/verify_package_docs.sh
  - scripts/ci/accrue_host_seed_e2e.exs
  - accrue/test/accrue/docs/trust_review_test.exs
  - accrue/test/accrue/docs/trust_leakage_test.exs
  - accrue/test/accrue/docs/package_docs_verifier_test.exs
  - accrue/test/accrue/docs/release_guidance_test.exs
  - examples/accrue_host/test/accrue_host_web/trust_smoke_test.exs
  - examples/accrue_host/mix.exs
  - examples/accrue_host/e2e/global-setup.js
  - examples/accrue_host/e2e/phase13-canonical-demo.spec.js
  - examples/accrue_host/playwright.config.js
  - accrue_admin/assets/css/app.css
  - accrue_admin/priv/static/accrue_admin.css
findings:
  critical: 0
  warning: 1
  info: 3
  total: 4
status: issues_found
---

# Phase 15: Code Review Report

**Reviewed:** 2026-04-17T09:52:50Z
**Depth:** standard
**Files Reviewed:** 18
**Status:** issues_found

## Summary

Review covered the Phase 15 workflow/docs updates, the host-browser seed path, the package-docs verifier, and the generated admin CSS artifact. I found one real correctness risk in the E2E seed script: local Playwright reseeds can delete unrelated trust/audit events from an existing test database because the cleanup query is not scoped to the seeded fixture records. I also found a few stale doc references that can misroute maintainers during release and verification work.

## Warnings

### WR-01: E2E reseed deletes unrelated billing events from shared test DB

**File:** `scripts/ci/accrue_host_seed_e2e.exs:67-79`

**Issue:** The script disables the `accrue_events` immutability trigger and then deletes every event whose type is `invoice.payment_failed` or `admin.webhook.replay.completed` for any `Subscription` or `WebhookEvent` subject. In CI this is masked because `verify_browser_command/0` recreates the database first, but local Playwright runs go through [`examples/accrue_host/e2e/global-setup.js`](examples/accrue_host/e2e/global-setup.js) without dropping the database. That means a local reseed can wipe unrelated audit history created by other tests or manual debugging sessions.

**Fix:**
Scope cleanup to the seeded fixture records only. For example, collect the prior seeded subscription ids and webhook ids first, then delete only matching events:

```elixir
previous_subscription_ids =
  Repo.all(
    from(subscription in Subscription,
      where: subscription.processor_id == "sub_host_browser_replay",
      select: subscription.id
    )
  )

previous_webhook_ids =
  Repo.all(
    from(webhook in WebhookEvent,
      where: webhook.processor_event_id in ["evt_host_browser_replay", "evt_host_browser_first_run"],
      select: webhook.id
    )
  )

Repo.delete_all(
  from(event in Event,
    where:
      (event.subject_type == "Subscription" and event.subject_id in ^previous_subscription_ids) or
        (event.subject_type == "WebhookEvent" and event.subject_id in ^previous_webhook_ids)
  )
)
```

## Info

### IN-01: Release runbook still points maintainers at the old Phase 9 gate

**File:** `RELEASING.md:19`

**Issue:** The runbook says maintainers should confirm “the Phase 9 release gate,” but the actual required gate in the reviewed workflow is now the Phase 15 trust-hardening lane (`release-gate` -> `admin-drift-docs` -> `host-integration`). That stale reference is likely to send a release operator to the wrong checklist.

**Fix:** Replace the phase-specific wording with the current workflow names or with a stable label such as “the required deterministic CI gate.”

### IN-02: Live-Stripe guide references a non-existent `test` job

**File:** `guides/testing-live-stripe.md:84-86`

**Issue:** The guide says scheduled failures can be monitored alongside the primary `test` job, but `.github/workflows/ci.yml` does not define a job with that name. Current job names are `release-gate`, `admin-drift-docs`, `host-integration`, `annotation-sweep`, and `live-stripe`.

**Fix:** Update the guide to reference the actual job names, or say “alongside the main CI workflow” instead of naming a nonexistent job.

### IN-03: Contributor setup points browser UAT at the wrong package

**File:** `CONTRIBUTING.md:15`

**Issue:** The setup guide says Node.js is needed “for browser UAT in `accrue_admin`,” but the browser lane in scope runs from `examples/accrue_host` via Playwright. That wording is easy to misread as “install Node only when working on the admin package.”

**Fix:** Reword this to mention the actual host example path, for example: “Node.js for browser UAT in `examples/accrue_host`.”

---

_Reviewed: 2026-04-17T09:52:50Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
