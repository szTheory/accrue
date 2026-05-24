---
phase: 126-admin-surface-docs-jtbd-spine
reviewed: 2026-05-23T21:04:09Z
depth: standard
files_reviewed: 10
files_reviewed_list:
  - accrue/lib/accrue/entitlements/admin.ex
  - accrue/lib/accrue/entitlements/resolver/local_map.ex
  - accrue/test/accrue/entitlements/admin_test.exs
  - accrue/test/accrue/docs/package_docs_verifier_test.exs
  - accrue_admin/lib/accrue_admin/copy.ex
  - accrue_admin/lib/accrue_admin/copy/entitlements.ex
  - accrue_admin/lib/accrue_admin/live/customer_live.ex
  - accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex
  - accrue_admin/test/accrue_admin/live/entitlements_live_test.exs
  - scripts/ci/verify_package_docs.sh
findings:
  critical: 1
  warning: 4
  info: 3
  total: 8
status: fixed
fix_status: partial
fixed:
  - CR-01
  - WR-01
  - WR-02
  - WR-03
  - WR-04
  - IN-01
deferred:
  - IN-02
  - IN-03
fixed_at: 2026-05-23
---

# Phase 126: Code Review Report

**Reviewed:** 2026-05-23T21:04:09Z
**Depth:** standard
**Files Reviewed:** 10
**Status:** fixed (CR-01, WR-01, WR-02, WR-03, WR-04, IN-01 resolved; IN-02, IN-03 deferred)

> **Fix pass 2026-05-23:** CR-01, WR-01, WR-02, WR-03, WR-04, and IN-01 are resolved
> (see commits prefixed `fix(126):` / `test(126):`). IN-02 (silent allowlist drop)
> and IN-03 (acronym humanization) are intentionally deferred — pre-existing,
> cosmetic, no Phase-126 regression. Verification: `accrue` admin_test 9/9,
> `accrue_admin` full suite 132/132, both packages compile clean with
> `--warnings-as-errors`.

## Summary

Phase 126 adds an additive, read-only entitlements admin surface: a core read seam (`Accrue.Entitlements.Admin.resolve_for_customer/1`) reusing the resolver's SSOT fold and surfacing unmapped entitling `price_id`s, a read-only LiveView entitlements tab on `CustomerLive`, an operator copy submodule, and package-doc verifier needles.

The one-way `admin → core` dependency is respected, the seam correctly reuses `LocalMap.fold_active/1` (no fold re-implementation), and the resolver's fail-closed posture (`handle_unmapped/3` drops under `:deny`) is intact. PII handling is clean — no logging/telemetry of customer fields was introduced, and the JsonViewer normalizes MapSets safely.

The headline defect is a **render-time crash path**: the entitlements tab calls the seam directly inside `render/1` with no `try/rescue`. Under the supported `unmapped_action: :raise` config (or any DB/config error during resolution), the resolver raises mid-render and takes down the entire LiveView — a hard fail rather than the graceful fail-closed state the codebase already authored copy for (`AccrueAdmin.Copy.entitlements_error_copy/0`), which is defined, delegated, allowlisted, and never rendered anywhere. There is also a drift-classification mismatch in the grace lane and several quality nits.

## Critical Issues

### CR-01: Entitlements tab raises inside `render/1` under `unmapped_action: :raise` — LiveView crashes instead of failing closed gracefully [RESOLVED]

**File:** `accrue_admin/lib/accrue_admin/live/customer_live.ex:358` (and helper at `:510-512`)

**Issue:** The entitlements tab resolves entitlements *during render*:

```elixir
<% {resolved, unmapped} = entitlements_view(@customer) %>
...
defp entitlements_view(customer) do
  Accrue.Entitlements.Admin.resolve_for_customer(customer)
end
```

`resolve_for_customer/1` → `LocalMap.fold_for_customer/1` → `fold_active/1` folds active items, and an unmapped entitling `price_id` under `unmapped_action: :raise` hits `LocalMap.handle_unmapped/3`:

```elixir
defp handle_unmapped(_acc, price_id, :raise) do
  raise "Accrue.Entitlements: active price_id #{inspect(price_id)} is unmapped ..."
end
```

`unmapped_action: :raise` is a fully supported config value (`accrue/lib/accrue/config.ex:391`, `type: {:in, [:deny, :raise]}`). Any host running `:raise` (a reasonable strict-mode choice) who opens the entitlements tab for a customer with a single unmapped entitling subscription will raise *inside the render template*. There is no `try/rescue`, so the exception propagates and crashes the LiveView process — a 500 / disconnected dashboard for the operator, not a contained, fail-closed empty state.

This contradicts the phase's own stated intent. The codebase already authored the graceful fallback copy: `AccrueAdmin.Copy.entitlements_error_copy/0` ("Entitlements couldn't be resolved... The gate fails closed, so no access is granted on error — retry shortly."). It is defined (`copy/entitlements.ex:44`), delegated (`copy.ex:527`), and in the export allowlist (`export_copy_strings.ex:72`) — but **never rendered**. The error-handling path was specified and copy-staged but not wired into the LiveView, leaving a crash where a contained error state was intended.

The same crash surface also covers any transient `Accrue.Repo` failure during the two queries the seam runs (`fold_for_customer` and `unmapped_entitling_price_ids` each hit the DB) — a DB blip becomes a render crash rather than the "retry shortly" state.

**Fix:** Resolve outside the template (e.g. in `handle_params`/`mount` or a guarded helper) and catch resolution failures, rendering the already-authored error copy:

```elixir
defp entitlements_view(customer) do
  try do
    {resolved, unmapped} = Accrue.Entitlements.Admin.resolve_for_customer(customer)
    {:ok, resolved, unmapped}
  rescue
    _ -> :error
  end
end
```

```elixir
<% "entitlements" -> %>
  <% case entitlements_view(@customer) do %>
    <% :error -> %>
      <section class="ax-card">
        <p class="ax-body"><%= Copy.entitlements_error_copy() %></p>
      </section>
    <% {:ok, resolved, unmapped} -> %>
      ... existing render ...
  <% end %>
```

Add a LiveView test that sets `unmapped_action: :raise` with an unmapped entitling subscription and asserts the page renders the error copy (status 200) rather than crashing.

## Warnings

### WR-01: Drift section mis-classifies out-of-grace `:past_due` rows as "unmapped" when grace is enabled [RESOLVED]

**File:** `accrue/lib/accrue/entitlements/resolver/local_map.ex:106-114`

**Issue:** `unmapped_entitling_price_ids/1` derives the operator's "drift" signal from `active_items/1`:

```elixir
customer_id
|> active_items()
|> Enum.map(fn {price_id, _qty, _via} -> price_id end)
|> Enum.reject(&Map.has_key?(reverse_index, &1))
|> Enum.uniq()
```

When `past_due_grace` is enabled, `active_items/1` widens to the grace lane and tags out-of-window `:past_due` rows as `:expired` (`grace_row/1:216`). An `:expired` row is **not** an entitling item — the fold deliberately does not grant it (`fold_item({_, _, :expired}, ...)`). But `unmapped_entitling_price_ids/1` ignores the `via` tag and counts the `price_id` if it is unmapped. So an out-of-grace, unmapped `:past_due` subscription is reported in the admin "Plan mapping" drift section with the hint *"This subscription's price isn't in your :plans config, so the resolver drops it"* — which is misleading: the row was dropped because it is out of the grace window, not because the price is unmapped. This can send operators chasing a phantom catalog-config problem.

Note this is only reachable when `past_due_grace` is `:dunning` or an integer; the default `:none` lane always tags `false`, so the drift set is exact there.

**Fix:** Restrict the drift derivation to rows the fold would actually treat as entitling (exclude `:expired`):

```elixir
customer_id
|> active_items()
|> Enum.reject(fn {_price_id, _qty, via} -> via == :expired end)
|> Enum.map(fn {price_id, _qty, _via} -> price_id end)
|> Enum.reject(&Map.has_key?(reverse_index, &1))
|> Enum.uniq()
```

Add a grace-lane test asserting an out-of-window unmapped `:past_due` row does NOT appear in `unmapped`.

### WR-02: Drift-only customer renders empty "Active plans / Granted features" labels with no empty-state explanation [RESOLVED]

**File:** `accrue_admin/lib/accrue_admin/live/customer_live.ex:406-408`

**Issue:** The empty-state copy is gated on BOTH lists being empty:

```elixir
<p :if={active_plans == [] and unmapped == []} class="ax-body">
  <%= Copy.entitlements_empty_title() %> · <%= Copy.entitlements_empty_copy() %>
</p>
```

For a customer whose only entitling subscription is on an unmapped price (the exact "drift" case the tab exists to surface — e.g. the factory default `price_basic`), `active_plans == []` but `unmapped != []`. The "Active entitlements" card then renders the "Active plans" and "Granted features" labels (`:359-380`) with no rows under them and no empty-state sentence — bare dangling labels. The operator gets the drift card below it but an unexplained blank section above.

**Fix:** Either render the empty-state when `active_plans == []` regardless of `unmapped`, or suppress the per-label sub-blocks when their list is empty. Example for the active-plans block:

```elixir
<div :if={active_plans != []} class="ax-stack-sm">
  <p class="ax-label"><%= Copy.entitlements_active_plans_label() %></p>
  <div :for={plan <- active_plans} class="ax-list-row">
    <StatusBadge.status_badge status={plan} tone="moss" />
  </div>
</div>
```

and relax the empty-state guard to `active_plans == [] and features == []`.

### WR-03: `:raise` unmapped path is untested for both the seam and the LiveView [RESOLVED]

**File:** `accrue/test/accrue/entitlements/admin_test.exs` (whole file) and `accrue_admin/test/accrue_admin/live/entitlements_live_test.exs` (whole file)

**Issue:** Every test fixes `unmapped_action: :deny`. The `:raise` branch — which is what makes CR-01 a crash rather than a contained error — has zero coverage at either the seam or the LiveView level. Because the resolver raises and the LiveView has no guard, this is precisely the untested edge that ships broken. Adversarially: the test suite proves the happy `:deny` path and the absence of the `:raise` path is what let the crash through.

**Fix:** Add a unit test asserting `Admin.resolve_for_customer/1` raises (or, if CR-01 is fixed at the seam, returns a contained result) under `unmapped_action: :raise` with an unmapped entitling sub, and a LiveView test asserting the tab renders `entitlements_error_copy()` instead of crashing.

### WR-04: `entitlements_view/1` is not strictly render-pure — runs two DB queries every render and shares the unguarded crash surface [RESOLVED]

**File:** `accrue_admin/lib/accrue_admin/live/customer_live.ex:357-358,510-512`

**Issue:** The brief calls for "LiveView render-only safety." The entitlements branch executes two `Accrue.Repo` round-trips (`fold_for_customer` and `unmapped_entitling_price_ids` each call `active_items/1` → `Repo.all`) on *every* render of that tab, inside the `~H` template. Beyond the crash exposure already noted in CR-01, doing data resolution in the template (rather than assigns computed in `mount`/`handle_params`) is the structural reason the failure cannot be contained and the result cannot be reused. This is a maintainability/robustness defect independent of the raw query cost (which is out of v1 perf scope). Other tabs in this same module already pull data per-render too (`subscriptions/1`, `tax_risk_summary/1`), so this matches a pre-existing pattern — but the new code inherits the unguarded-crash consequence.

**Fix:** Compute `{resolved, unmapped}` (or the `:error` sentinel from CR-01) into a socket assign in `handle_params` when `tab == "entitlements"`, and have `render/1` read the assign. This makes render pure, lets CR-01's error state be assigned once, and avoids re-querying on unrelated re-renders.

## Info

### IN-01: `entitlements_error_copy/0` is defined, delegated, and allowlisted but never used [RESOLVED]

**File:** `accrue_admin/lib/accrue_admin/copy/entitlements.ex:44`, `accrue_admin/lib/accrue_admin/copy.ex:527`, `accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex:72`

**Issue:** Dead operator copy. The string exists across three layers but has no render site (confirmed by grep — no `entitlements_error_copy` reference under `accrue_admin/lib/.../live/`). It is the fail-closed error message the tab should show; its presence-without-use is the fingerprint of the missing CR-01 wiring.

**Fix:** Wire it in as part of the CR-01 fix. Once rendered, no further action — it is correct copy.

### IN-02: `export_copy_strings` silently drops allowlisted names that are not 0-arity exports [DEFERRED]

**File:** `accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex:92-97`

**Issue:** The comprehension `for name <- @allowlist, {^name, 0} <- exports, into: %{}` silently skips any allowlisted name that is not present as a 0-arity function (typo, rename, or arity change). The generated anti-drift JSON would shrink with no error, weakening the VERIFY-01 guard the task exists to feed. Not a Phase-126 regression (all 13 new entitlements names verified present as 0-arity delegates), but the silent-skip behavior is a latent foot-gun for future copy churn.

**Fix:** After building `map`, assert coverage and fail loudly on a miss:

```elixir
missing = @allowlist -- (Map.keys(map) |> Enum.map(&String.to_atom/1))
missing == [] || Mix.raise("export_copy_strings: allowlisted names not exported: #{inspect(missing)}")
```

### IN-03: `StatusBadge` humanize lowercases acronym features (`:api` → "Api") [DEFERRED]

**File:** `accrue_admin/lib/accrue_admin/live/customer_live.ex:377-379` via `accrue_admin/lib/accrue_admin/components/status_badge.ex:43-48`

**Issue:** Feature/plan atoms render through `StatusBadge` `humanize/1`, which does `String.capitalize/1` per word — capitalizing the first letter and lowercasing the rest. A feature atom like `:api` renders as "Api", `:sso` as "Sso". Purely cosmetic, no behavioral impact, but operator-facing in the new entitlements card. Pre-existing component behavior; flagged only because Phase 126 is the first surface to route arbitrary host-defined entitlement atoms through it.

**Fix:** Optional — pass an explicit `label` for known-acronym features, or leave as-is (host feature naming is host-controlled). No action required for ship.

---

_Reviewed: 2026-05-23T21:04:09Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
