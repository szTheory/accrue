---
quick_id: 260622-nob
slug: fix-two-host-playwright-e2e-spec-drift-a
date: 2026-06-22
status: complete
commit: c0353d02
files_changed:
  - examples/accrue_host/e2e/verify01-admin-a11y.spec.js
  - examples/accrue_host/e2e/phase13-canonical-demo.spec.js
---

# Quick Task 260622-nob Summary

Repointed two drifted host Playwright e2e assertions to the redesigned admin DOM, fixing the merge-blocking `host-integration` + `playwright-e2e` CI jobs.

## Changes

1. **`verify01-admin-a11y.spec.js` (line 172)** — replaced the `.toBeVisible()` assertion on the now-hidden Connect "Apply filters" submit button (`ax-visually-hidden`, form auto-applies on `phx-change`) with an assertion on the visible filter form: `page.locator("[data-role='filter-form']")`.

2. **`phase13-canonical-demo.spec.js` (line 237)** — replaced the dead `getByText("Append-only billing and admin activity")` locator (string exists nowhere in the repo post-redesign) with `getByRole("heading", { name: "Event log" })`, matching the renamed `billing_events_heading`. Used `getByRole('heading')` rather than `getByText` to avoid the fql nav/h1 strict-mode collision. The sibling `label: "audit heading"` line was left unchanged.

This dead locator was the root cause of the reported "Target page closed" + Ecto `Sandbox :checkin` crash (scrollIntoViewIfNeeded timeout on a never-resolving locator).

## Verification

- `grep -rn 'getByRole("button", { name: copyStrings.connect_accounts_apply_filters })' examples/accrue_host/e2e/` → no matches
- `grep -rn "Append-only billing and admin activity" examples/accrue_host/e2e/` → no matches
- `git diff --stat` → exactly the two `.js` spec files (1 insertion + 1 deletion each); `examples/accrue_host/mix.lock` untouched.

Playwright suite execution and end-to-end verification are handled by the orchestrator (requires DB setup + lock restoration).

## Deviations from Plan

None — plan executed exactly as written.

## Additional Fixes (commit 0a2f25ba)

Local full-suite verification surfaced two MORE host e2e drifts beyond the two above.

3. **`e2e/generated/copy_strings.json` — regenerated committed copy.** The host e2e suite reads admin UI copy from this COMMITTED generated file. CI's `host-integration` job regenerates it at runtime, but the `playwright-e2e` shard reads the committed file as-is, so it must be refreshed. Re-ran `cd accrue_admin && mix accrue_admin.export_copy_strings --out .../e2e/generated/copy_strings.json`. Verified exactly 5 keys changed (old → new):
   - `coupon_index_headline`: "Coupons backed by local discount projections" → "Coupons"
   - `invoices_index_headline`: "Collections and invoice review" → "Invoices"
   - `connect_accounts_headline`: "Connected accounts and payout readiness" → "Connected accounts"
   - `billing_events_heading_organization`: "Billing activity for the active organization" → "Event log"
   - `promotion_codes_index_headline`: "Promotion codes as a dedicated admin surface" → "Promotion codes"

4. **`verify01-admin-mounted.spec.js` — repointed "Billing signals" assertions.** The customers index was redesigned (columns now Customer / Payment method / ID), removing the "Billing signals" column.
   - Desktop branch (~line 32): `columnheader` name `"Billing signals"` → `"Payment method"`.
   - Mobile branch (~line 28): `article` filter `hasText: "Billing signals"` (+ `"Org"` filter dropped) → `hasText: "Payment method"`; adjacent comment updated to "assert the card shows the Payment method field".
   - `timeout: 15_000` lines left unchanged.

`git diff --stat` for commit 0a2f25ba: `copy_strings.json` (1 ±), `verify01-admin-mounted.spec.js` (6, 3 insertions + 3 deletions); `examples/accrue_host/mix.lock` left dirty and uncommitted per orchestrator instruction.

## Self-Check: PASSED

- FOUND: examples/accrue_host/e2e/verify01-admin-a11y.spec.js
- FOUND: examples/accrue_host/e2e/phase13-canonical-demo.spec.js
- FOUND: examples/accrue_host/e2e/generated/copy_strings.json
- FOUND: examples/accrue_host/e2e/verify01-admin-mounted.spec.js
- FOUND commit: c0353d02
- FOUND commit: 0a2f25ba
