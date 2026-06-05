---
phase: 175-b-persona-driven-ia-spine
reviewed: 2026-06-04T00:00:00Z
depth: standard
files_reviewed: 30
files_reviewed_list:
  - accrue_admin/assets/js/app.js
  - accrue_admin/assets/js/hooks/sidebar_collapse.js
  - accrue_admin/lib/accrue_admin/attention_counts.ex
  - accrue_admin/lib/accrue_admin/components/app_shell.ex
  - accrue_admin/lib/accrue_admin/components/filter_chip_bar.ex
  - accrue_admin/lib/accrue_admin/components/global_search.ex
  - accrue_admin/lib/accrue_admin/components/sidebar.ex
  - accrue_admin/lib/accrue_admin/components/topbar.ex
  - accrue_admin/lib/accrue_admin/controllers/redirect_controller.ex
  - accrue_admin/lib/accrue_admin/copy.ex
  - accrue_admin/lib/accrue_admin/live/charge_live.ex
  - accrue_admin/lib/accrue_admin/live/charges_live.ex
  - accrue_admin/lib/accrue_admin/live/connect_account_live.ex
  - accrue_admin/lib/accrue_admin/live/coupon_live.ex
  - accrue_admin/lib/accrue_admin/live/customer_live.ex
  - accrue_admin/lib/accrue_admin/live/dashboard_live.ex
  - accrue_admin/lib/accrue_admin/live/event_live.ex
  - accrue_admin/lib/accrue_admin/live/events_live.ex
  - accrue_admin/lib/accrue_admin/live/invoice_live.ex
  - accrue_admin/lib/accrue_admin/live/invoices_live.ex
  - accrue_admin/lib/accrue_admin/live/promotion_code_live.ex
  - accrue_admin/lib/accrue_admin/live/subscription_live.ex
  - accrue_admin/lib/accrue_admin/live/subscriptions_live.ex
  - accrue_admin/lib/accrue_admin/live/webhook_live.ex
  - accrue_admin/lib/accrue_admin/nav.ex
  - accrue_admin/lib/accrue_admin/nav_badge_hook.ex
  - accrue_admin/lib/accrue_admin/queries/charges.ex
  - accrue_admin/lib/accrue_admin/queries/invoices.ex
  - accrue_admin/lib/accrue_admin/queries/subscriptions.ex
  - accrue_admin/lib/accrue_admin/router.ex
findings:
  critical: 4
  warning: 7
  info: 3
  total: 14
status: issues_found
---

# Phase 175-b: Code Review Report

**Reviewed:** 2026-06-04T00:00:00Z
**Depth:** standard
**Files Reviewed:** 30
**Status:** issues_found

## Summary

Phase 175-b ships the persona-driven IA spine: nav tiering with attention-count
badges, work-queue list defaults (`push_patch` + `?view=all` sentinel), the
`/charges` → `/payments` redirect, cross-screen `RelatedResources` threading,
the new `EventLive` detail page, and the compliance actor-lens filter.

The implementation is structurally sound and test-suite clean. However, four
blockers exist: an open-redirect vector in `RedirectController.charges_show/2`
where `URI.encode/1` is the wrong mitigation; an unthrottled synchronous global
search that executes three concurrent DB-backed tasks inside a LiveComponent
event with no input cap; `String.to_existing_atom` usage on untrusted status
params that degrades to an atom-leak under certain conditions; and N+1 DB
queries in `customer_live.ex`'s render path for `tax_risk_summary`.

Seven warnings cover logic issues, edge-case data races, and two places where
direct `Repo` operations bypass audit/changeset boundaries. Three info items
cover dead/unused code and minor quality issues.

---

## Critical Issues

### CR-01: Open-redirect via path-traversal in `RedirectController.charges_show/2`

**File:** `accrue_admin/lib/accrue_admin/controllers/redirect_controller.ex:24-29`

**Issue:** `URI.encode/1` encodes percent-signs and spaces but it does NOT encode
forward-slashes (`/`). A request to `/charges/..%2F..%2Fevil` arrives at Phoenix
with `id = "../evil"` (already decoded by the router) and `URI.encode("../evil")`
produces `"../evil"` unchanged (slashes are reserved characters that `URI.encode`
leaves intact). The resulting redirect target becomes
`{mount_path}/payments/../evil`, which a browser resolves to `{mount_path}/evil`,
defeating the path-confinement goal.

Additionally, `mount_path` itself is derived from
`String.replace_suffix(conn.request_path, "/charges/#{id}", "")`. If an attacker
controls `id` and the router has already decoded the path, this suffix replacement
can strip more of the request path than intended.

The threat model comment in the code (T-175-03-02) acknowledges the risk but the
chosen mitigation is insufficient.

**Fix:** Replace `URI.encode/1` with `URI.encode_path_segment/1` (available in
Elixir 1.17+, which is the project floor) or equivalently
`URI.encode(id, &URI.char_unreserved?/1)`. `char_unreserved?` only permits
`[A-Za-z0-9._~-]` through, which encodes `/` as `%2F` and prevents traversal.
Then validate the encoded id does not contain `%2F` (percent-encoded slash) to
fully close the vector, or — simpler and safer — refuse any id that contains `/`
or `..` before building the redirect:

```elixir
def charges_show(conn, %{"id" => id}) do
  if String.contains?(id, [".", "/", "\\", "%"]) do
    # id contains traversal chars; the router should have caught non-UUID patterns
    # but defend in depth
    send_resp(conn, 400, "Bad request")
  else
    qs = if conn.query_string != "", do: "?" <> conn.query_string, else: ""
    mount_path = String.replace_suffix(conn.request_path, "/charges/#{id}", "")
    redirect(conn, to: mount_path <> "/payments/" <> URI.encode(id, &URI.char_unreserved?/1) <> qs)
  end
end
```

Note: if the `:id` param is always a UUID (as strongly implied by the rest of the
codebase), the simplest defence is a UUID format guard at the top.

---

### CR-02: `GlobalSearch` executes unthrottled synchronous search with no input length cap

**File:** `accrue_admin/lib/accrue_admin/components/global_search.ex:63-89`

**Issue:** The `handle_event("search", ...)` handler fires on every `phx-debounce`
tick (150ms). When the query is non-empty it calls `fetch_results/1`, which opens
a `Task.async_stream/2` over three anonymous functions. Each function calls a
`Billing.*` search function and `Enum.take(5)`. This means:

1. **No input-length cap.** A malicious or accidental paste of kilobyte-sized
   text creates an expensive SQL `ilike` with a multi-KB pattern every 150ms.
2. **`Task.async_stream` default timeout is 5000ms.** If all three search tasks
   time out (e.g. DB under load), `Enum.reduce` over the stream will raise
   `{:exit, :timeout}` because the default `on_timeout: :exit` will produce
   `{:exit, :timeout}` elements — not `{:ok, ...}` — and the pattern
   `{:ok, {key, data}}` in the reduce will cause a `FunctionClauseError`,
   crashing the LiveComponent process.
3. The `loading` assign is set to `true` only in theory; the code path that
   sets it is missing (search runs synchronously, `loading` never becomes true
   in the current code because the assignment `loading: true` is never made
   before the fetch).

**Fix:**
```elixir
def handle_event("search", %{"q" => query}, socket) do
  trimmed = String.trim(query)
  cond do
    trimmed == "" ->
      {:noreply, assign(socket, query: "", results: empty_results(), loading: false)}

    String.length(trimmed) > 100 ->
      # Reject absurdly long queries before hitting the DB
      {:noreply, assign(socket, query: trimmed, results: empty_results(), loading: false)}

    true ->
      results = fetch_results(trimmed)
      {:noreply, assign(socket, query: trimmed, results: results, loading: false)}
  end
end
```

For the Task crash risk, add `on_timeout: :kill_task` and handle
`{:exit, _}` in the reduce:

```elixir
|> Task.async_stream(fn {key, func} -> {key, func.()} end,
     on_timeout: :kill_task, timeout: 3_000)
|> Enum.reduce(empty_results(), fn
  {:ok, {key, data}}, acc -> Map.put(acc, key, data)
  {:exit, _}, acc -> acc
end)
```

---

### CR-03: `String.to_existing_atom` on untrusted `status` param in `queries/invoices.ex` degrades to latent atom-space enumeration

**File:** `accrue_admin/lib/accrue_admin/queries/invoices.ex:142-149`

**Issue:** The `filter_status/2` multi-value branch calls
`Enum.map(multiple, &String.to_existing_atom/1)` — where `multiple` is a
comma-split of the raw URL `status` query parameter. While a single `rescue
ArgumentError` wraps the entire map, this means:

1. Any atom that happens to already exist in the BEAM atom table is silently
   accepted — including atoms for Ecto internals, OTP modules, process names, or
   any atom that the running node has interned through other means. An attacker
   who knows the atom table contents can pass `status=:something_internal` and get
   a valid filter rather than an empty result.
2. The single-value branch on line 142 calls `String.to_existing_atom(single)`
   directly inside the `where` clause. This is wrapped with `rescue ArgumentError`
   at the outer `filter_status/2` level (line 148), but the entire `filter_status`
   call is within the `filter_query` reduce, so a rescue there drops the filter
   entirely and silently returns unfiltered results — potentially a correctness
   bug (a bad status param returns ALL invoices instead of 0).

The correct fix (already correctly done in `queries/subscriptions.ex`'s named
statuses, though that module also calls `String.to_existing_atom` in the fallback
path) is to validate against an explicit allowlist before converting:

**Fix:**
```elixir
@valid_statuses ~w(draft open paid uncollectible void)

defp filter_status(query, status) when is_binary(status) do
  values =
    status
    |> String.split(",", trim: true)
    |> Enum.filter(&(&1 in @valid_statuses))

  case values do
    [] -> query
    [single] -> where(query, [invoice, _customer], invoice.status == ^String.to_existing_atom(single))
    multiple ->
      atoms = Enum.map(multiple, &String.to_existing_atom/1)
      where(query, [invoice, _customer], invoice.status in ^atoms)
  end
end
```

Note: the same pattern exists in `queries/subscriptions.ex` in the `status_dynamic/1`
fallback (line 196-200) and `filter_single_status/2` fallback (line 165-173) —
those fallback clauses are unreachable given the named guard clauses above them,
but their `String.to_existing_atom` calls would also benefit from the allowlist
treatment if the guard list ever diverges.

---

### CR-04: N+1 DB queries inside `render/1` in `customer_live.ex` via `tax_risk_summary/1`

**File:** `accrue_admin/lib/accrue_admin/live/customer_live.ex:232-237`

**Issue:** The `render/1` function calls `tax_risk_summary(@customer)` three times
in the KPI grid section (lines 232, 233, 234), and `tax_risk_summary/1` (line
819-852) executes **two raw Repo queries** — one for subscriptions and one for
invoices — on every call. Because `render/1` is called on every assign change
(LiveView re-renders eagerly), these two DB queries are executed three times per
render cycle, and potentially on every LiveView update that touches any assign.

In a busy admin session (badge refreshes, flash events, tab changes), this can
result in dozens of DB round-trips per minute for a single customer view page,
with no visible sign to the operator.

**Fix:** Move `tax_risk_summary` computation to `mount/3` and/or `handle_params/3`
as a cached socket assign, identical to the `assign_entitlements_view` pattern
already present in the same file:

```elixir
# In mount/3, after assign(:customer, customer):
|> assign(:tax_risk, tax_risk_summary(customer))

# In render:
# Replace all three tax_risk_summary(@customer) calls with @tax_risk.headline,
# @tax_risk.detail, @tax_risk.tone respectively.
```

Also refresh in `refresh_customer_detail/1` alongside the `:tab_counts` update.

---

## Warnings

### WR-01: `reconcile_deleted_payment_method/2` in `customer_live.ex` bypasses changeset validation

**File:** `accrue_admin/lib/accrue_admin/live/customer_live.ex:791-803`

**Issue:** After confirming a payment-method delete, `reconcile_deleted_payment_method/2`
calls `Repo.delete(persisted_payment_method)` and then directly
`Accrue.Billing.Customer.changeset(%{default_payment_method_id: nil}) |> Repo.update!/1`.
Both operations bypass the `Billing` context functions and the audit event system.
If the customer update fails (e.g. a concurrent DB constraint), `Repo.update!/1`
raises an unhandled exception that crashes the LiveView process, resetting the
user's session.

**Fix:** Use `Billing.delete_payment_method/2` (already used in line 153 for the
API-level delete) for the local projection cleanup, or at minimum replace
`Repo.update!` with `Repo.update` and handle the `{:error, _}` case:

```elixir
case socket.assigns.customer
     |> Accrue.Billing.Customer.changeset(%{default_payment_method_id: nil})
     |> Repo.update() do
  {:ok, _} -> :ok
  {:error, _changeset} -> :ok   # best effort; the PM is already deleted
end
```

---

### WR-02: `handle_params` empty-params clause triggers re-patch loop risk on second navigation

**File:** `accrue_admin/lib/accrue_admin/live/invoices_live.ex:34-40`
(same pattern in `charges_live.ex:34-40`, `subscriptions_live.ex:49-55`)

**Issue:** The `handle_params` clause for `map_size(params) == 0` only fires
`push_patch` when `connected?(socket)` is true. This is correctly gated, so the
primary redirect loop is prevented. However, if the user navigates away and back
to the same list page within the same LiveSocket connection, `handle_params` fires
again with `params == %{}` and the `push_patch` executes again, which is the
intended work-queue default behaviour.

The real risk is: if the `push_patch` target URL produced by
`build_default_params/2` contains `?org=<slug>` and the `current_owner_scope`
changes between navigations (e.g. the user switches org scope), the
`socket.assigns[:current_owner_scope]` read on line 36 uses the already-mounted
scope, not the params-derived scope. Since `current_owner_scope` is assigned by
an `on_mount` hook and not updated by `handle_params`, this can produce a default
redirect with a stale org slug.

**Fix:** Verify that `current_owner_scope` is refreshed by `handle_params` or
the `on_mount` hook on every navigation. If not, read scope from params in
`build_default_params` rather than from socket assigns.

---

### WR-03: `charges_show/2` in `RedirectController` derives `mount_path` by stripping the raw `:id` from `request_path` — breaks if id contains percent-encoded characters

**File:** `accrue_admin/lib/accrue_admin/controllers/redirect_controller.ex:27`

**Issue:** `String.replace_suffix(conn.request_path, "/charges/#{id}", "")` —
`id` is the already-decoded param, but `conn.request_path` is the raw (still
percent-encoded) path. If the original id was `abc%20def` in the URL, the router
decodes it to `"abc def"`, but the raw path still contains `abc%20def`. The suffix
`"/charges/abc def"` is not present in the raw path, so `replace_suffix` does
nothing and `mount_path` equals the full `request_path`. The redirect destination
becomes `{full_request_path}/payments/{id}`, not `{mount_path}/payments/{id}`.

**Fix:** Use `conn.request_path |> URI.parse() |> Map.get(:path)` decoded, or
re-encode `id` before building the suffix:

```elixir
raw_id = URI.encode(id, &URI.char_unreserved?/1)
mount_path = String.replace_suffix(conn.request_path, "/charges/#{raw_id}", "")
```

---

### WR-04: `customer_live.ex` calls `subscriptions/1`, `invoices/1`, `charges/1`, and `payment_methods/1` directly in `render/1` template branches — DB queries inside render

**File:** `accrue_admin/lib/accrue_admin/live/customer_live.ex:290-321`

**Issue:** The tab-rendering case in `render/1` calls `subscriptions(@customer)`,
`invoices(@customer)`, and `charges(@customer)` directly from the template. These
are all `Repo.all` queries. LiveView calls `render/1` on every assign update.
While each call is guarded behind a `case @tab` branch, LiveView still evaluates
the entire case expression structure. Critically, the functions are passed as bare
function calls in HEEx assign expressions — if LiveView's compiler evaluates them
eagerly (which HEEx may do for template function arguments), these run on every
render.

Additionally, `active_subscription_payment_method?/2` (called from the
`payment_methods` tab template at lines 345-350) calls `subscriptions(@customer)`
inside itself — this is a nested DB query executed per payment method row per
render.

**Fix:** Load and cache the tab's data as a socket assign in `handle_params/3`
when the tab changes, matching the `assign_entitlements_view/2` pattern already
present in the same file. For example:

```elixir
defp assign_tab_data(socket, "subscriptions") do
  assign(socket, :tab_data, subscriptions(socket.assigns.customer))
end
defp assign_tab_data(socket, _tab), do: assign(socket, :tab_data, [])
```

---

### WR-05: `GlobalSearch.fetch_results/1` calls `Task.async_stream` without linking supervision — orphaned tasks on LiveComponent crash

**File:** `accrue_admin/lib/accrue_admin/components/global_search.ex:78-89`

**Issue:** `Task.async_stream/2` spawns tasks that are linked to the calling
process. If the LiveComponent process is killed (e.g. by a LiveView crash or
process exit) while tasks are running, the linked tasks will also be killed — this
is the intended behaviour. However, if a DB query in one of the tasks raises an
exception (not a timeout), the exception propagates back via the stream as
`{:exit, {reason, stacktrace}}`. The current reduce only pattern-matches on
`{:ok, {key, data}}`, so an `{:exit, ...}` element causes a `FunctionClauseError`
in `Enum.reduce`, crashing the LiveComponent. The component will be restarted by
LiveView but the user sees a momentary blank state.

This is a second dimension of the CR-02 crash risk and deserves a dedicated
warning even if CR-02 is addressed, because the fix requires handling both the
`{:exit, :timeout}` and `{:exit, {exception, _stacktrace}}` variants.

**Fix:** See CR-02 fix — handle `{:exit, _}` in the reduce.

---

### WR-06: `sidebar.ex` `grouped_items/1` uses `Enum.chunk_by` — non-contiguous same-group items produce duplicate groups

**File:** `accrue_admin/lib/accrue_admin/components/sidebar.ex:89-99`

**Issue:** `Enum.chunk_by/2` groups consecutive elements with the same key. In
`Nav.items/3`, items are already sorted by group, so this works today. But if
`Nav.items/3` ever returns items out of group order (e.g. a plugin injects items),
`chunk_by` produces multiple groups with the same name, and `sidebar.ex` will
render duplicate group sections with duplicate HTML `id` attributes
(`sidebar-group-section-billing`, `sidebar-group-links-billing` etc.), which is
invalid HTML and can break accessibility tools and the JS `SidebarCollapse` hook.

**Fix:** Replace `Enum.chunk_by` with `Enum.group_by` followed by deterministic
ordering, or add a comment documenting the ordering invariant so callers of
`Nav.items/3` know not to break it:

```elixir
# Option A: group_by (order-independent)
defp grouped_items(items) do
  items
  |> Enum.group_by(&Map.get(&1, :group))
  |> Enum.map(fn {group, group_items} ->
    [first | _] = group_items
    ...
  end)
end
```

---

### WR-07: `attention_counts.ex` `compute/1` runs two separate DB queries on every badge refresh — not scoped by `owner_scope`

**File:** `accrue_admin/lib/accrue_admin/attention_counts.ex:11-19`

**Issue:** `compute/1` accepts `_owner_scope` but ignores it, always performing a
global count. This means:

1. In a multi-tenant admin where a user's `current_owner_scope` restricts them to
   a specific organization, the sidebar badges show the **global** counts rather
   than the per-organization counts. An operator scoped to org A sees org B's
   past-due subscriptions in their Recovery badge.
2. Depending on admin configuration, this could constitute an information
   disclosure: the operator can infer that there is *some* billing work in other
   orgs by observing the badge count.

**Fix:** Thread `owner_scope` into the two queries:

```elixir
def compute(%AccrueAdmin.OwnerScope{mode: :organization, organization_id: org_id}) do
  %{
    recovery:
      Subscription
      |> join(:inner, [sub], customer in assoc(sub, :customer))
      |> where([_sub, customer], customer.owner_type == "Organization" and customer.owner_id == ^org_id)
      |> Query.past_due()
      |> Repo.aggregate(:count, :id),
    developer:
      WebhookEvent
      |> where([e], e.status in [:failed, :dead])
      |> Repo.aggregate(:count, :id)  # webhooks are not tenant-scoped currently
  }
end

def compute(_owner_scope) do
  # global or nil scope: original behaviour
  %{ ... }
end
```

---

## Info

### IN-01: Dead assign `load_subscription/1` is defined but never called in `subscription_live.ex`

**File:** `accrue_admin/lib/accrue_admin/live/subscription_live.ex:571-578`

**Issue:** `load_subscription/1` is defined as a private function but never called
— `mount/3` uses `Subscriptions.detail/2` for the initial load and
`refresh_subscription/2` uses it again via `load_subscription` at line 926... on
closer inspection `refresh_subscription` does call `load_subscription`, so this
function is used. However, the function accepts a `subscription_id` and queries
via `Repo.get` WITHOUT applying the owner-scope filter, while `Subscriptions.detail/2`
in `mount/3` does apply owner-scope. After a subscription action completes,
`refresh_subscription/2` calls `load_subscription/1` directly, which loads the
subscription without scoping — consistent with edit operations on an already-owned
resource, but worth noting as a divergence from the initial load path.

**Fix:** Consider passing owner_scope to `refresh_subscription` and routing through
`Subscriptions.detail/2` for consistency, or add a doc comment explaining why the
unscoped reload is intentional post-action.

---

### IN-02: `tab_counts/1` in `customer_live.ex` limits event count by calling `Events.timeline_for` with `limit: 25` but uses `length/1` on the result

**File:** `accrue_admin/lib/accrue_admin/live/customer_live.ex:572-575`

**Issue:**
```elixir
events: length(Events.timeline_for("Customer", customer.id, limit: 25)),
```
This fetches up to 25 events from the DB and counts them in Elixir. If the customer
has more than 25 events, the tab badge shows "25" not the true count, misleading
the operator. A customer with 100 events looks identical to one with 25.

**Fix:** Replace with a `Repo.aggregate(:count)` query scoped to the Customer
subject, or document the intentional cap with a trailing `+` label in the UI
(e.g. "25+").

---

### IN-03: `sidebar_collapse.js` stores raw `mountPath` from `data-mount-path` in localStorage key without sanitisation

**File:** `accrue_admin/assets/js/hooks/sidebar_collapse.js:49-54`

**Issue:** The localStorage key is `"ax-sidebar-" + mountPath + "-" + group`.
If the mount path contains characters that are unusual in localStorage keys
(e.g. if an attacker can influence `data-mount-path` via server-side XSS), the
key could collide with other storage entries. In normal use this is harmless, but
since `mountPath` is server-controlled, a defensive sanitisation step would
prevent accidental key collisions if the admin is ever mounted at a path with
special characters:

```js
storageKey() {
  const mountEl = this.el.closest("[data-mount-path]");
  const mountPath = mountEl ? mountEl.dataset.mountPath : "/billing";
  // Replace non-alphanum to avoid storage key collisions
  const safePath = mountPath.replace(/[^a-z0-9]/gi, "_");
  return "ax-sidebar-" + safePath + "-" + this.el.dataset.group;
}
```

---

_Reviewed: 2026-06-04T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
