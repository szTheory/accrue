---
quick_id: 260622-nob
slug: fix-two-host-playwright-e2e-spec-drift-a
date: 2026-06-22
status: ready
plan_count: 1
must_haves:
  truths:
    - "Host e2e asserts the user-facing filter form, not the now-hidden Apply button"
    - "phase13 admin replay-audit step targets the real 'Event log' heading"
  artifacts:
    - "examples/accrue_host/e2e/verify01-admin-a11y.spec.js (line 172 repointed)"
    - "examples/accrue_host/e2e/phase13-canonical-demo.spec.js (line 237 repointed)"
  key_links:
    - "accrue_admin/lib/accrue_admin/components/data_table.ex (data-role=filter-form, ax-visually-hidden submit)"
    - "accrue_admin/lib/accrue_admin/copy/billing_event.ex (billing_events_heading = 'Event log')"
---

# Quick Task 260622-nob: Fix two host Playwright e2e spec-drift assertions

## Problem

`main` CI is red in the merge-blocking `host-integration` and `playwright-e2e` jobs. Both run the
host Playwright e2e suite (`examples/accrue_host/e2e/`) in path-deps mode against the local
redesigned admin source. Two assertions drifted from the olr filter redesign + fql heading rename.
A whole-suite grep confirmed these are the **only** two remaining drifts (no KPI-card or
bulk-replay drift exists; heading-collision fixes already shipped at HEAD 065eca5e).

## Task 1 — repoint both drifted assertions

**Files:**
- `examples/accrue_host/e2e/verify01-admin-a11y.spec.js`
- `examples/accrue_host/e2e/phase13-canonical-demo.spec.js`

**Action:**

1. In `verify01-admin-a11y.spec.js`, line 172 — the Connect filter "Apply filters" submit button
   is now `class="ax-visually-hidden" tabindex="-1"` (the form auto-applies on `phx-change`), so
   `.toBeVisible()` on it fails. Replace exactly:

   ```js
   await expect(page.getByRole("button", { name: copyStrings.connect_accounts_apply_filters })).toBeVisible();
   ```

   with:

   ```js
   await expect(page.locator("[data-role='filter-form']")).toBeVisible();
   ```

   (`data-role="filter-form"` is on the filter `<form>` in
   `accrue_admin/lib/accrue_admin/components/data_table.ex`. The line-171 heading assertion above
   already proves the page rendered.)

2. In `phase13-canonical-demo.spec.js`, the `assertResponsiveState` "admin replay audit event"
   step (around lines 236–238) targets a stale heading string that exists nowhere else in the
   repo. The events page h1 is now "Event log" (`billing_events_heading`). Replace exactly:

   ```js
   locator: page.getByText("Append-only billing and admin activity"),
   ```

   with:

   ```js
   locator: page.getByRole("heading", { name: "Event log" }),
   ```

   Keep the sibling `label: "audit heading"` line unchanged. (Use `getByRole('heading')` not
   `getByText` — fql made the h1 label equal its nav label, so `getByText` would hit a strict-mode
   collision.) This dead locator was the root cause of the reported "Target page closed" +
   Ecto `Sandbox :checkin` crash: `scrollIntoViewIfNeeded` on a never-resolving locator times out,
   closing the page, and the lingering events LiveView's sandbox checkin is a downstream artifact.

**Constraint — DO NOT touch `examples/accrue_host/mix.lock`.** The committed Hex-mode lock is
required by `scripts/ci/accrue_host_hex_smoke.sh`. If local verification rewrites it (path-mode
`mix deps.get`), restore with `git checkout examples/accrue_host/mix.lock`. The commit must contain
only the two `.js` spec files.

**Verify:** `git diff --stat` shows exactly the two spec files changed; the two old strings
(`getByRole("button", { name: copyStrings.connect_accounts_apply_filters })` and
`"Append-only billing and admin activity"`) no longer appear in the suite
(`grep -rn` returns nothing).

**Done:** Both spec files edited, staged, and committed atomically; `mix.lock` unchanged.

## Verification (orchestrator-driven, post-commit)

Local end-to-end per the approved plan:
```
cd examples/accrue_host
MIX_ENV=test mix ecto.drop && MIX_ENV=test mix ecto.create
mix deps.get                      # path mode (rewrites mix.lock locally)
npx playwright test               # full host e2e — expect 0 failures
git checkout mix.lock             # restore committed hex-mode lock
```
Then push and confirm `host-integration` + `playwright-e2e` go green.
