---
phase: 177-d-motion-micro-interaction-design
reviewed: 2026-06-04T00:00:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - accrue_admin/assets/js/hooks/command_palette.js
  - accrue_admin/assets/js/hooks/sidebar_collapse.js
  - accrue_admin/lib/accrue_admin/components/data_table.ex
  - accrue_admin/lib/accrue_admin/components/detail_drawer.ex
  - accrue_admin/lib/accrue_admin/components/flash_group.ex
  - accrue_admin/lib/accrue_admin/components/global_search.ex
  - accrue_admin/lib/accrue_admin/components/sidebar.ex
  - accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex
  - accrue_admin/lib/accrue_admin/live/customer_live.ex
findings:
  critical: 3
  warning: 4
  info: 2
  total: 9
status: issues_found
---

# Phase 177: Code Review Report

**Reviewed:** 2026-06-04T00:00:00Z
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

Nine files reviewed across the MOTION phase work (Phase 177). The motion plumbing itself is largely sound: `{ once: true }` is correctly applied to the `transitionend` listener, `data-open` attribute refactor is consistent throughout `command_palette.js` and `global_search.ex`, `phx-mounted`/`phx-remove` `time:` values match CSS duration tokens, and `pointer-events: none` on the closed palette wrapper prevents click interception. No raw ms or cubic-bezier literals were introduced.

Three blockers were found: a reduced-motion stuck-state bug in `sidebar_collapse.js` (the `transitionend` listener fires on a 0ms transition under `prefers-reduced-motion`, causing it to silently never fire), a non-functional close button in `detail_drawer.ex`, and a crash-on-delete bug in `customer_live.ex`. The latter two are pre-existing but fall squarely in scope as they were in the reviewed file set.

---

## Critical Issues

### CR-01: `sidebar_collapse.js` — transitionend never fires under prefers-reduced-motion, leaving collapsed list permanently visible

**File:** `accrue_admin/assets/js/hooks/sidebar_collapse.js:53-62`

**Issue:** `setExpanded(false)` adds `.ax-collapsed` and registers a `transitionend` listener (`{ once: true }`) to set `hidden` and strip the class. Under `prefers-reduced-motion: reduce`, `theme.css` sets `--ax-dur-exit: 0ms`. The `.ax-collapsed` rule uses `transition: opacity var(--ax-dur-exit) var(--ax-ease-in)`, which resolves to `opacity 0ms`. A zero-duration CSS transition does not fire a `transitionend` event on most browsers (or fires it synchronously before the listener is attached). Result: the `{ once: true }` listener never executes, `hidden` is never set, and `.ax-collapsed` is never removed. The list stays visible (opacity 0, pointer-events: none) — accessible to assistive technology as un-hidden content and visible in the DOM but inert, which breaks the screen-reader contract the `hidden` attribute is meant to provide.

This also affects any user who has the `prefers-reduced-motion` OS setting enabled — a non-trivial accessibility-using population.

**Fix:** After adding `.ax-collapsed`, read back the computed `transition-duration`. If it is `0s` or `0ms`, skip the listener and apply the `hidden` state synchronously:

```javascript
setExpanded(expanded) {
  this.el.setAttribute("aria-expanded", String(expanded));
  const list = document.getElementById(this.el.dataset.controls);
  if (!list) return;

  if (expanded) {
    list.removeAttribute("hidden");
    list.classList.remove("ax-collapsed");
  } else {
    list.classList.add("ax-collapsed");

    // Under prefers-reduced-motion the transition duration is 0ms (or 1ms for
    // opacity crossfades). transitionend will not fire for 0ms; guard here so
    // the hidden attribute is always set.
    const duration = parseFloat(
      getComputedStyle(list).getPropertyValue("transition-duration")
    );
    if (!duration || duration <= 0.001) {
      // Reduced-motion path: apply immediately.
      list.hidden = true;
      list.classList.remove("ax-collapsed");
    } else {
      list.addEventListener(
        "transitionend",
        () => {
          list.hidden = true;
          list.classList.remove("ax-collapsed");
        },
        { once: true }
      );
    }
  }
},
```

---

### CR-02: `detail_drawer.ex` — close button has no click handler; drawer cannot be closed without `close_href`

**File:** `accrue_admin/lib/accrue_admin/components/detail_drawer.ex:52-54`

**Issue:** When `close_href` is nil (the default), a `<button>` is rendered but has no event handler attached. The `@rest` global attr (which accepts `phx-click` and `phx-target`) is spread onto the outer `<section>` at line 30, not onto the button. A caller who omits `close_href` and expects the button to close the drawer by passing `phx-click="close"` as a rest attr on `detail_drawer` will find the rest attrs fire on the section wrapper — but the button itself does nothing. In practice every use of the drawer that omits `close_href` will have an inert close button.

**Fix:** Spread `@rest` directly onto the close `<button>`:

```heex
<button :if={!@close_href} type="button" class="ax-button ax-button-ghost" {@rest}>
  <%= @close_label %>
</button>
```

And remove `{@rest}` from the outer `<section>` (or keep it on the section only if there is a legitimate reason to handle events at that level). The `attr(:rest, :global, include: ~w(phx-click phx-target))` declaration at line 15 already declares the intent — the forwarding target is wrong.

---

### CR-03: `customer_live.ex` — `Repo.delete/1` result is matched destructively inside `reconcile_deleted_payment_method`, crashing the LiveView process on DB failure

**File:** `accrue_admin/lib/accrue_admin/live/customer_live.ex:795`

**Issue:** Line 795 uses a bare match `{:ok, _deleted_payment_method} = Repo.delete(persisted_payment_method)`. If `Repo.delete/1` returns `{:error, changeset}` (e.g., a DB constraint violation, a concurrent deletion, a network error), the match raises `MatchError` and crashes the LiveView process. The function is called from `handle_event("confirm_delete_payment_method", ...)` which runs in the LiveView process. The `Repo.update/1` two lines below is intentionally "best effort" per the comment, but the `Repo.delete/1` immediately above has no such protection.

**Fix:** Wrap the delete in a case expression consistent with the best-effort comment:

```elixir
defp reconcile_deleted_payment_method(socket, payment_method) do
  if persisted_payment_method = Repo.get(PaymentMethod, payment_method.id) do
    case Repo.delete(persisted_payment_method) do
      {:ok, _deleted} ->
        if socket.assigns.customer.default_payment_method_id == payment_method.id do
          socket.assigns.customer
          |> Accrue.Billing.Customer.changeset(%{default_payment_method_id: nil})
          |> Repo.update()
          # intentionally ignoring {:error, _changeset} — best effort
        end

      {:error, _changeset} ->
        # Local DB delete failed (e.g. constraint, concurrent deletion). The
        # payment method was already deleted on Stripe; log and continue so
        # the LiveView process does not crash.
        :ok
    end
  end

  socket
end
```

---

## Warnings

### WR-01: `customer_live.ex` — `payment_method_delete_blocked_reason/2` guard logic is inverted; `:replacement_required` fires when a replacement IS available, not when one is absent

**File:** `accrue_admin/lib/accrue_admin/live/customer_live.ex:730-732`

**Issue:** The condition at line 730 reads:

```elixir
default_payment_method?(customer, payment_method) and
    has_other_payment_methods?(customer, payment_method) ->
  :replacement_required
```

`has_other_payment_methods?/2` returns `true` when there ARE other payment methods (i.e., a replacement already exists). The intent of `:replacement_required` is to block deletion when the default payment method has NO replacement — but the current guard fires when one IS available. This means:

- When a user tries to delete the default payment method and there ARE other methods present, deletion is blocked with a "replacement required" message — even though a replacement exists and deletion should be allowed.
- When there is NO other method, the guard is false, `nil` is returned, and deletion proceeds unblocked — which may leave the customer with no payment method.

The condition should negate `has_other_payment_methods?`:

```elixir
default_payment_method?(customer, payment_method) and
    not has_other_payment_methods?(customer, payment_method) ->
  :replacement_required
```

---

### WR-02: `sidebar_collapse.js` — no guard for missing `data-controls` target on expand path

**File:** `accrue_admin/assets/js/hooks/sidebar_collapse.js:44`

**Issue:** `setExpanded(expanded)` already guards `if (!list) return` at line 44. On the **expand** path (`expanded == true`, lines 47-50) this is safe. However, `mounted()` calls `setExpanded(stored === "true")` at line 21 before the DOM is fully stable (e.g., during a LiveView reconnect/patch where the controlled list's `id` may differ from `data-controls`). If `document.getElementById(...)` returns null, the function returns silently but `aria-expanded` has already been mutated (line 42) — so `aria-expanded` disagrees with the visible state. This is a narrow edge case but leaves ARIA state inconsistent after a bad mount.

**Fix:** Move the `aria-expanded` write inside the guard, or only write it if `list` is non-null:

```javascript
setExpanded(expanded) {
  const list = document.getElementById(this.el.dataset.controls);
  if (!list) return; // guard before any mutation

  this.el.setAttribute("aria-expanded", String(expanded));
  // ... rest of function
}
```

---

### WR-03: `global_search.ex` — `mount_path` initialised to hardcoded `"/billing"` in `mount/1`; silently wrong if `update/2` is not called before render

**File:** `accrue_admin/lib/accrue_admin/components/global_search.ex:14`

**Issue:** `mount/1` sets `mount_path: "/billing"`. The correct value is passed as the `mount_path` assign from `app_shell.ex` line 48, which reaches `GlobalSearch` via the catch-all `update/2` clause. In the normal LiveComponent lifecycle `update/2` is always called before the first render, so the override happens before any navigation links are built. However, the `"/billing"` default is semantically wrong — it will silently produce broken navigation links if, for any reason, `update/2` is not invoked with `mount_path` (e.g., during a hot-reload partial update or if `app_shell` is ever refactored to omit the assign). The mount default should match the actual default or be `nil` with a guard.

**Fix:** Either use `nil` as the default and guard in `path/2`, or remove the hardcoded string:

```elixir
def mount(socket) do
  {:ok,
   assign(socket,
     mount_path: nil,   # will be set by update/2 from app_shell
     ...
   )}
end
```

---

### WR-04: `detail_drawer.ex` — `aria-labelledby` uses a hardcoded static ID; two simultaneous drawers produce duplicate IDs

**File:** `accrue_admin/lib/accrue_admin/components/detail_drawer.ex:27,43`

**Issue:** Both `aria-labelledby="detail-drawer-title"` (line 27) and `id="detail-drawer-title"` (line 43) are hardcoded. If two `detail_drawer` components are ever rendered in the DOM at the same time — even with `@open` gating — duplicate IDs will violate HTML uniqueness and the `aria-labelledby` association will be ambiguous or broken. Since `detail_drawer` is a function component with no `id` attr, callers have no way to customise this. The component does have an `@id`-like prop available via `@rest`, but it is not used to disambiguate the label ID.

**Fix:** Accept an `id` attr and derive the `aria-labelledby` from it:

```elixir
attr(:id, :string, default: "detail-drawer")
```

Then in the template:
```heex
<section
  :if={@open}
  id={@id}
  aria-labelledby={"#{@id}-title"}
  ...
>
  ...
  <h2 id={"#{@id}-title"} class="ax-heading"><%= @title %></h2>
```

---

## Info

### IN-01: `customer_live.ex` — `tabs/4` private function is dead code; never called

**File:** `accrue_admin/lib/accrue_admin/live/customer_live.ex:578-590`

**Issue:** `defp tabs/4` at line 578 is never called anywhere in the file. `primary_tab_list/4` and `more_tab_list/4` replaced it as the split was introduced, but `tabs/4` was not removed.

**Fix:** Delete lines 578–590. The function duplicates the logic of `primary_tab_list/4` and `more_tab_list/4` with the full `@tabs` module attribute.

---

### IN-02: `customer_live.ex` — `active_subscription_payment_method?/2` hardcodes `"braintree"` processor check; always returns `false` for Stripe customers

**File:** `accrue_admin/lib/accrue_admin/live/customer_live.ex:711`

**Issue:** The function filters subscriptions to `subscription.processor == "braintree"` before checking the `payment_method_token` data path. Accrue uses Stripe as its primary processor (`lattice_stripe`). Stripe-based subscriptions have a different data schema for payment method identity. As written, `active_subscription_payment_method?/2` always returns `false` for Stripe customers — the `:in_use` block reason and the in-use badge in the template are therefore dead for all Stripe users. This is the only non-Stripe processor guard in the file.

**Fix:** If Braintree support is intentional (legacy data), document it explicitly and add a Stripe path. If it is vestigial copy-paste, remove the `processor == "braintree"` guard and update the `payment_method_token` key lookup to match the Stripe data schema for subscription payment methods.

---

_Reviewed: 2026-06-04T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
