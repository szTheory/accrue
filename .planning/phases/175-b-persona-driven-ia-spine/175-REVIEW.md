---
phase: 175-b-persona-driven-ia-spine
reviewed: 2026-06-04T00:00:00Z
depth: standard
iteration: 2
files_reviewed: 8
files_reviewed_list:
  - accrue_admin/lib/accrue_admin/controllers/redirect_controller.ex
  - accrue_admin/lib/accrue_admin/components/global_search.ex
  - accrue_admin/lib/accrue_admin/queries/invoices.ex
  - accrue_admin/lib/accrue_admin/queries/subscriptions.ex
  - accrue_admin/lib/accrue_admin/queries/charges.ex
  - accrue_admin/lib/accrue_admin/live/customer_live.ex
  - accrue_admin/lib/accrue_admin/components/sidebar.ex
  - accrue_admin/lib/accrue_admin/attention_counts.ex
findings:
  critical: 0
  warning: 0
  info: 1
  total: 1
status: clean
---

# Phase 175-b: Code Review Report (Iteration 2 — Post-Fix Verification)

**Reviewed:** 2026-06-04T00:00:00Z
**Depth:** standard
**Iteration:** 2 (--auto fix loop)
**Files Reviewed:** 8
**Status:** clean

## Summary

Iteration-1 fixed 8 findings (CR-01 through CR-04, WR-01, WR-05 through WR-07).
All 8 fixes are confirmed correct with no new Critical or Warning issues introduced.
WR-02 (stale `current_owner_scope` in `handle_params`) and WR-04 (tab data queries
in `render/1`) remain as accepted/deferred architectural findings per the context
note; they are not re-flagged.

One new Info item is noted: the `tabs/4` private function in `customer_live.ex`
is dead code left over from the refactor to `primary_tab_list/4` and
`more_tab_list/4`.

### Fix verification summary

| Finding | Fix | Verified |
|---------|-----|---------|
| CR-01 open-redirect | Allowlist guard (`String.contains?` on `[".", "/", "\\", "%"]`) + `URI.encode(id, &URI.char_unreserved?/1)` + `raw_id` used to build suffix | Correct — guard fires before any path arithmetic; `char_unreserved?` encodes `/` as `%2F` |
| CR-02/WR-05 GlobalSearch crash | `@max_query_length 100` cap + `on_timeout: :kill_task` + `{:exit, _}` handled in reduce | Correct — all three risk dimensions addressed |
| CR-03 invoice status allowlist | `@valid_invoice_statuses ~w(draft open paid uncollectible void)` + `Enum.filter` before atom conversion | Correct — both single-value and multi-value paths now gated |
| CR-04 tax_risk N+1 | `assign(:tax_risk, tax_risk_summary(customer))` in `mount/3` and `refresh_customer_detail/1`; render uses `@tax_risk` | Correct |
| WR-01 `Repo.update!` crash | Replaced with `Repo.update/1`; error tuple silently dropped (best-effort comment present) | Correct |
| WR-06 `chunk_by` → `group_by` | `Enum.group_by/2` used; first-occurrence ordering preserved via `Enum.uniq` on the original list | Correct |
| WR-07 AttentionCounts org scope | `compute(%OwnerScope{mode: :organization, organization_id: org_id})` clause added; recovery query joins Customer and filters by org | Correct. Note: `developer:` (WebhookEvent) is intentionally not org-scoped in both clauses — webhooks are cross-tenant infrastructure, which is defensible |

### Accepted/deferred findings (not re-flagged)

**WR-02** (`handle_params` stale `current_owner_scope` in list-page push_patch): not present in these 8 files; architectural; accepted as deferred.

**WR-04** (tab data DB queries in `render/1` for subscriptions/invoices/charges tabs, and `active_subscription_payment_method?` calling `subscriptions()` per payment-method row during render): still present in `customer_live.ex`. This is the accepted/deferred pattern per iteration-1 context. The entitlements case was correctly moved to `assign_entitlements_view/2` in `handle_params`; the remaining three tab queries are a known pre-existing architectural pattern.

---

## Info

### IN-01: Dead function `tabs/4` in `customer_live.ex`

**File:** `accrue_admin/lib/accrue_admin/live/customer_live.ex:578`

**Issue:** `defp tabs(customer, mount_path, counts, owner_scope)` is never called.
The refactor that introduced `primary_tab_list/4` and `more_tab_list/4` replaced
all call sites but left the original `tabs/4` in place. The Elixir compiler will
warn on this under `mix compile --warnings-as-errors` / Dialyzer. The function
also contains a `String.to_existing_atom(tab)` call on line 587 — unused, but a
minor code-smell to carry.

**Fix:** Delete the dead function (lines 578–590).

---

_Reviewed: 2026-06-04T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
_Iteration: 2_
