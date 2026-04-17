---
phase: 17-milestone-closure-cleanup
reviewed: 2026-04-17T15:30:24Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - CONTRIBUTING.md
  - RELEASING.md
  - accrue/test/accrue/docs/package_docs_verifier_test.exs
  - accrue/test/accrue/docs/release_guidance_test.exs
  - examples/accrue_host/test/accrue_host/seed_e2e_cleanup_test.exs
  - guides/testing-live-stripe.md
  - scripts/ci/accrue_host_seed_e2e.exs
  - scripts/ci/verify_package_docs.sh
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 17: Code Review Report

**Reviewed:** 2026-04-17T15:30:24Z
**Depth:** standard
**Files Reviewed:** 8
**Status:** issues_found

## Summary

Reviewed the phase-scoped docs, verifier coverage, and the new host seed cleanup flow. The docs/test updates are consistent, but the seed cleanup script now deletes every `Accrue.Webhook.DispatchWorker` job in the `accrue_webhooks` queue instead of only removing fixture-owned jobs. That broad delete can erase unrelated queued or failed webhook work in the example host app.

## Warnings

### WR-01: Seed cleanup deletes unrelated webhook jobs

**File:** `scripts/ci/accrue_host_seed_e2e.exs:107`
**Issue:** `cleanup_fixture_footprint!/0` runs `Repo.delete_all` against all `Oban.Job` rows for worker `Accrue.Webhook.DispatchWorker` in queue `accrue_webhooks`. On any rerun, that removes unrelated webhook dispatch jobs created by other tests or by a locally running example app, which makes the cleanup routine broader than the fixture footprint it is supposed to prune.
**Fix:**
```elixir
fixture_webhook_ids =
  Repo.all(
    from(webhook in WebhookEvent,
      where: webhook.processor_event_id in ^@fixture_processor_event_ids,
      select: webhook.id
    )
  )

Repo.delete_all(
  from(job in Oban.Job,
    where:
      job.worker == "Accrue.Webhook.DispatchWorker" and
        job.queue == "accrue_webhooks" and
        fragment("?->>'webhook_event_id' = ANY(?)", job.args, ^Enum.map(fixture_webhook_ids, &to_string/1))
  )
)
```

Also add a regression assertion in [seed_e2e_cleanup_test.exs](/Users/jon/projects/accrue/examples/accrue_host/test/accrue_host/seed_e2e_cleanup_test.exs) that inserts an unrelated `Oban.Job` and verifies it survives `run!/1`.

---

_Reviewed: 2026-04-17T15:30:24Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
