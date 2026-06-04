---
phase: 176-c-systematic-per-screen-rubric-uplift
reviewed: 2026-06-04T00:00:00Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - accrue_admin/lib/accrue_admin/copy.ex
  - accrue_admin/lib/accrue_admin/copy/billing_event.ex
  - accrue_admin/lib/accrue_admin/copy/coupon.ex
  - accrue_admin/lib/accrue_admin/copy/promotion_code.ex
  - accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex
  - accrue_admin/lib/accrue_admin/live/charge_live.ex
  - accrue_admin/lib/accrue_admin/live/connect_account_live.ex
  - accrue_admin/lib/accrue_admin/live/coupon_live.ex
  - accrue_admin/lib/accrue_admin/live/event_live.ex
  - accrue_admin/lib/accrue_admin/live/invoice_live.ex
  - accrue_admin/lib/accrue_admin/live/promotion_code_live.ex
  - accrue_admin/lib/accrue_admin/live/webhook_live.ex
  - accrue_admin/lib/accrue_admin/live/webhooks_live.ex
  - accrue_admin/lib/accrue_admin/router.ex
findings:
  critical: 1
  warning: 3
  info: 2
  total: 6
status: issues_found
---

# Phase 176: Code Review Report

**Reviewed:** 2026-06-04T00:00:00Z
**Depth:** standard
**Files Reviewed:** 14
**Status:** issues_found

## Summary

This phase is a presentation-layer rubric uplift: adding `Detail.*` components, `ax-measure` prose wrappers, `summary_card` heroes, `dl/dt/dd` semantics, and `put_flash` on not-found redirects. The router gains `plug(:fetch_live_flash)` in the `:accrue_admin_browser` pipeline.

The router change is correctly placed (`fetch_live_flash` after `fetch_session`, before `protect_from_forgery`) and the import is correctly scoped inside the `quote` block so it injects into the host router rather than the `AccrueAdmin.Router` module itself. The `put_flash` + `redirect` pattern in `CouponLive`, `PromotionCodeLive`, and `EventLive` is correct LiveView idiom and will work with the new pipeline plug. The `Detail.summary_card` and `Detail.detail_section` refactoring is mechanically sound.

One pre-existing logic defect in `WebhookLive.safe_utf8/1` is escalated to BLOCKER because it causes a non-binary value to be passed to `Jason.decode/1` for invalid-UTF-8 webhook payloads. Three warnings cover inconsistent not-found flash coverage, a stale redirect target in `ChargeLive`, and floating-point money arithmetic in `CouponLive`. Two info items cover the `source_event_select` label/select id disconnection and a dead-code false alarm around `safe_utf8`.

---

## Critical Issues

### CR-01: `safe_utf8/1` passes error tuple to `Jason.decode/1` for invalid UTF-8 webhook payloads

**File:** `accrue_admin/lib/accrue_admin/live/webhook_live.ex:454-460`

**Issue:** `:unicode.characters_to_binary/1` does **not** always raise `ArgumentError`. For input that is a valid Erlang binary but contains illegal UTF-8 sequences (e.g., `<<0xFF, 0xFE>>`), it returns `{:error, "", rest_binary}` rather than raising. `safe_utf8/1` wraps every return value unconditionally in `{:ok, ...}`:

```elixir
defp safe_utf8(raw_body) do
  try do
    {:ok, :unicode.characters_to_binary(raw_body)}   # BUG: wraps error tuple
  rescue
    ArgumentError -> :error
  end
end
```

When the input is invalid UTF-8, the return is `{:ok, {:error, "", <<...>>}}`. The `with {:ok, text} <- safe_utf8(raw_body)` arm in `decode_raw_body/1` matches, binding `text` to the 3-tuple. `Jason.decode/1` receives a tuple instead of a binary; it returns `{:error, %Jason.DecodeError{}}`, which is caught by the `else _ -> nil` arm. End result: the raw payload is silently discarded and the `data` field fallback is used instead. In practice this means a webhook whose `raw_body` is a byte-for-byte copy of the original Stripe payload (stored as a latin-1 binary by older middleware) will silently lose its payload display in the admin inspector.

**Fix:**
```elixir
defp safe_utf8(raw_body) do
  try do
    case :unicode.characters_to_binary(raw_body) do
      text when is_binary(text) -> {:ok, text}
      _error_or_incomplete -> :error
    end
  rescue
    ArgumentError -> :error
  end
end
```

---

## Warnings

### WR-01: `ChargeLive` not-found redirect targets the legacy `/charges` path

**File:** `accrue_admin/lib/accrue_admin/live/charge_live.ex:35`

**Issue:** The nil-charge branch redirects to `admin_path(admin, "/charges")`, which is the pre-IA-06 path. The live routes expose charges under `/payments`; `/charges` is only handled by `AccrueAdmin.RedirectController` which itself issues a 301 to `/payments`. The redirect-on-404 path therefore bounces through an extra hop: `LiveView redirect -> /charges (controller) -> 301 -> /payments (live)`. Every other detail Live redirects to its own canonical path. This is also inconsistent with `assign_shell` on line 326, which sets `:current_path` to `/payments`.

**Fix:**
```elixir
# line 35
{:ok, redirect(socket, to: admin_path(admin, "/payments"))}
```

---

### WR-02: Inconsistent `put_flash` coverage on not-found redirects

**File:** `accrue_admin/lib/accrue_admin/live/invoice_live.ex:37-38`, `accrue_admin/lib/accrue_admin/live/charge_live.ex:34-35`, `accrue_admin/lib/accrue_admin/live/connect_account_live.ex:20-21`

**Issue:** This phase added `put_flash(:error, ...)` before redirect for `CouponLive`, `PromotionCodeLive`, and `EventLive`. Three detail lives still silently redirect without any flash:

- `InvoiceLive` (line 37-38): no flash, no `invoice_not_found` copy string
- `ChargeLive` (line 34-35): no flash, no `charge_not_found` copy string
- `ConnectAccountLive` (line 20-21): no flash, no `connect_account_not_found` copy string

A user who follows a stale bookmarked URL to a deleted invoice/charge/account gets silently dropped on the index with no indication of what happened. The inconsistency also makes the pattern non-systematic despite the phase goal of systematic uplift.

**Fix:** Add copy strings and `put_flash` for each. Example for `InvoiceLive`:

```elixir
# In AccrueAdmin.Copy.Invoice:
def invoice_not_found, do: "Invoice not found."

# In AccrueAdmin.Copy, add defdelegate:
defdelegate invoice_not_found(), to: Invoice

# In InvoiceLive.mount/3:
nil ->
  {:ok,
   socket
   |> put_flash(:error, Copy.invoice_not_found())
   |> redirect(to: admin_path(admin, "/invoices"))}
```

Apply the same pattern to `ChargeLive` (targeting `/payments`) and `ConnectAccountLive`.

---

### WR-03: `format_minor/2` in `CouponLive` uses floating-point division for money display

**File:** `accrue_admin/lib/accrue_admin/live/coupon_live.ex:200-203`

**Issue:** The `discount_summary/1` helper formats `amount_off_minor` and `amount_off_cents` via `format_minor/2`, which divides by 100 using integer-to-float division:

```elixir
defp format_minor(amount_minor, currency) when is_integer(amount_minor) do
  dollars = amount_minor / 100          # float division
  code = currency |> to_string() |> String.upcase()
  :erlang.float_to_binary(dollars, decimals: 2) <> " " <> code
end
```

Two distinct problems:

1. **Zero-decimal currencies** (JPY, KRW, etc.): dividing by 100 and displaying two decimal places produces wrong amounts. 500 JPY minor units display as "5.00 JPY" instead of "500 JPY".
2. **Floating-point imprecision**: amounts that are not exactly representable as IEEE 754 doubles (e.g., minor-unit values like 10 → `0.1` cannot be represented exactly) can produce off-by-one in the last decimal.

The module already imports `Accrue.Money` and `Accrue.Invoices.Render.format_money/3` is used in `charge_live.ex`. This `format_minor/2` function bypasses all of that.

**Fix:**
```elixir
defp format_minor(amount_minor, currency) when is_integer(amount_minor) do
  Accrue.Invoices.Render.format_money(
    amount_minor,
    normalize_currency(currency),
    Accrue.Config.default_locale()
  )
end

# Add the same normalize_currency/1 helper already present in charge_live.ex and invoice_live.ex
defp normalize_currency(currency) when is_atom(currency), do: currency
defp normalize_currency(currency) when is_binary(currency) do
  code = String.downcase(currency)
  try do
    String.to_existing_atom(code)
  rescue
    ArgumentError -> :usd
  end
end
defp normalize_currency(_), do: :usd
```

---

## Info

### IN-01: `source_event_select` label `for=` attribute does not match any input/select `id`

**File:** `accrue_admin/lib/accrue_admin/live/charge_live.ex:304-307`, `accrue_admin/lib/accrue_admin/live/invoice_live.ex:478-481`

**Issue:** Both `source_event_select/1` private components generate a dynamic `for` attribute on the `<label>` using `System.unique_integer([:positive])`, but neither the `<select>` element nor any `<input>` carries a matching `id` attribute. The label is therefore not programmatically associated with its control, breaking screen-reader and click-to-focus behaviour.

Note: this is pre-existing (not introduced by this phase) but is a presentation-layer defect that this rubric-uplift phase is well-placed to fix.

**Fix:** Assign a stable `id` to `<select name="source_event_id">`. Because this component can render multiple times per page (four forms in `invoice_live.ex`), the component itself should receive an `id` attribute:

```elixir
attr(:id, :string, required: true)
attr(:events, :list, required: true)

defp source_event_select(assigns) do
  ~H"""
  <label class="ax-label" for={@id <> "-select"}>
    Source event
  </label>
  <select id={@id <> "-select"} name="source_event_id" class="ax-select">
    ...
  </select>
  """
end
```

Then pass a stable id at each call site: `<.source_event_select id="finalize-source-event" events={@timeline_events} />`.

---

### IN-02: `maybe_decimal/3` payload accumulation would break silently if ever moved from first position in `override_opts/1`

**File:** `accrue_admin/lib/accrue_admin/live/connect_account_live.ex:328-342`

**Issue:** `maybe_decimal/3` always returns `{:ok, nil, %{}}` (a **fresh** empty map) when the value is absent, whereas `maybe_money/4` returns `{:ok, nil, payload}` (threading the accumulated payload through). In the current `override_opts/1` with-chain, `maybe_decimal` is always first, so the empty-map return is benign. However, if a future maintainer reorders the chain or adds a second decimal field, earlier accumulated keys will be silently dropped.

**Fix:** Mirror `maybe_money`'s nil clause by accepting and threading a payload parameter:

```elixir
defp maybe_decimal(form, key, payload_key, payload \\ %{}) do
  label = override_field_label(key)
  case Map.get(form, key) do
    nil ->
      {:ok, nil, payload}                    # thread through, don't discard
    value ->
      try do
        decimal = Decimal.new(value)
        {:ok, decimal, Map.put(payload, payload_key, value)}
      rescue
        _ ->
          {:error, AccrueAdmin.Copy.connect_account_error_field_must_be_decimal(label)}
      end
  end
end
```

---

_Reviewed: 2026-06-04T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
