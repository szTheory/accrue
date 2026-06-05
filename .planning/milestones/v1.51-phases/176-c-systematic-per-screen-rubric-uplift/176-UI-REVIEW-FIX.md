---
phase: 176
fixed_at: 2026-06-04T17:03:30Z
review_path: .planning/phases/176-c-systematic-per-screen-rubric-uplift/176-UI-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 2
skipped: 2
status: partial
---

# Phase 176: UI Review Fix Report

**Fixed at:** 2026-06-04T17:03:30Z
**Source review:** .planning/phases/176-c-systematic-per-screen-rubric-uplift/176-UI-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 4
- Fixed: 2
- Skipped: 2

---

## Fixed Issues

### SCR-04: charge_live.ex missing ax-measure on refund intro prose paragraph

**Files modified:** `accrue_admin/lib/accrue_admin/live/charge_live.ex`
**Commit:** c05624fd
**Applied fix:** Changed `<p class="ax-body">` to `<p class="ax-body ax-measure">` at line 216. The introductory prose paragraph "Leave the amount blank to refund the full charge. Existing fee fields surface after the refund is created." was missing the 68ch reading-measure constraint while its 3 sibling Braintree-conditional paragraphs already had it. Now consistent across all four prose blocks in the refund card header.

---

### WR-02: event_live.ex raw string literals bypass the Copy module

**Files modified:** `accrue_admin/lib/accrue_admin/copy/billing_event.ex`, `accrue_admin/lib/accrue_admin/copy.ex`, `accrue_admin/lib/accrue_admin/live/event_live.ex`
**Commit:** 3a9e7225
**Applied fix:**
- Added `event_detail_eyebrow/0` (returns `"Event detail"`) and `event_detail_section_heading/0` (returns `"Event details"`) to `AccrueAdmin.Copy.BillingEvent`.
- Added `defdelegate event_detail_eyebrow(), to: BillingEvent` and `defdelegate event_detail_section_heading(), to: BillingEvent` to `AccrueAdmin.Copy`.
- Added `alias AccrueAdmin.Copy` to `event_live.ex`.
- Replaced `eyebrow="Event detail"` with `eyebrow={Copy.event_detail_eyebrow()}` at line 67.
- Replaced `title="Event details"` with `title={Copy.event_detail_section_heading()}` at line 80.

---

## Skipped Issues

### WR-03: campaign_live.ex test/code discrepancy — no not-found redirect branch

**File:** `accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex`
**Reason:** False alarm confirmed — no fix needed.
**Original issue:** The SCORECARD Wave 5 claimed a "redirects with flash error for invalid subscription_id format" test was added, but `campaign_live.ex mount/3` has no redirect branch. Investigation confirmed the test named `"redirects with flash error for invalid subscription_id format (dim ④)"` actually tests the empty-state branch, not a redirect. The test comment at lines 141-145 explicitly documents: "The dim ④ requirement for CampaignLive is: empty branch rendered when no arcs found." The test name is misleading but the test body correctly asserts `html =~ "No dunning history found"` against a valid UUID that returns no arcs — which is exactly what the code does (Dunning returns empty maps/lists for unknown IDs, CampaignTimeline renders the empty state). Code and test are consistent. No changes required.

---

### WR-01: webhook_live.ex replay_copy/1 hardcodes explanation sentence inline

**File:** `accrue_admin/lib/accrue_admin/live/webhook_live.ex:303`
**Reason:** Skipped — not trivial; no webhook.ex copy module exists.
**Original issue:** The populated-webhook branch of `replay_copy/1` returns a raw inline string "Single replay calls the existing DLQ primitive directly..." bypassing the Copy module. Fixing this requires creating a new `accrue_admin/lib/accrue_admin/copy/webhook.ex` module, adding an alias and delegate to `Copy`, and updating `webhook_live.ex`. This is a multi-file change for a single advisory sentence. Per task instructions ("skip the minor webhook replay_copy string item OR fix if trivial"), it is skipped as non-trivial. The inline string has no user-facing test assertion and is an advisory Pillar 1 gap. Recommended for Phase 179 pre-visual-QA cleanup.

---

## Test Suite

**Result:** 252 tests, 0 failures (run from worktree with symlinked deps/`_build`).

---

_Fixed: 2026-06-04T17:03:30Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
