# Phase 52 — Pattern map

Analogs and insertion points for execution agents.

| New / changed area | Role | Closest analog | Notes |
|--------------------|------|----------------|-------|
| `AccrueAdmin.Copy` facade growth | Copy SSOT entry | `accrue_admin/lib/accrue_admin/copy.ex` + `defdelegate` to `Copy.Subscription` | Add `alias` + `defdelegate` rows only; bodies live in new `copy/coupon.ex`, `copy/promotion_code.ex`. |
| Domain copy module | Isolated strings | `accrue_admin/lib/accrue_admin/copy/subscription.ex` | Same `@moduledoc false`, small pure functions returning strings. |
| Coupon / promo LiveViews | HEEx consumer | `accrue_admin/lib/accrue_admin/live/coupons_live.ex`, `coupon_live.ex`, `promotion_codes_live.ex`, `promotion_code_live.ex` | Replace literal eyebrow/title/empty/table copy with `AccrueAdmin.Copy.*` calls. |
| Version doc gate | CI enforcement | `scripts/ci/verify_package_docs.sh` | Follow `extract_version`, `require_fixed`, `require_regex` patterns at EOF cluster. |
| README VERIFY contract | Literal gate | `scripts/ci/verify_verify01_readme_contract.sh` | Add needles only when README gains new SSOT strings. |
| Matrix literals | Literal gate | `scripts/ci/verify_adoption_proof_matrix.sh` | Add `require_substring` when matrix documents new stable rows. |
| Copy export (optional) | Playwright anti-drift | `accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex` | Extend allowlist keys if D-15 Playwright added. |

## Code excerpts (signatures)

**Delegate pattern (`copy.ex`):**

```elixir
alias AccrueAdmin.Copy.Subscription
defdelegate subscription_page_title(), to: Subscription
```

**Subscription module shape (`copy/subscription.ex`):**

```elixir
defmodule AccrueAdmin.Copy.Subscription do
  @moduledoc false
  def subscription_page_title, do: "…"
end
```

Apply the same shape for **`Copy.Coupon`** / **`Copy.PromotionCode`** (exact module names per executor; **52-CONTEXT** allows discretion on internal function names if prefixes hold).

---

## PATTERN MAPPING COMPLETE
