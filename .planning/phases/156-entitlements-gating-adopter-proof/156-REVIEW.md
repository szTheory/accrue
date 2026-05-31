---
phase: 156-entitlements-gating-adopter-proof
reviewed: 2026-05-31T15:25:52Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - accrue/lib/accrue/entitlements/guard.ex
  - examples/accrue_host/test/accrue_host_web/live/entitlements_guard_test.exs
  - examples/accrue_host/config/config.exs
  - examples/accrue_host/lib/accrue_host_web/router.ex
  - accrue/guides/entitlements.md
  - accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex
  - examples/accrue_host/e2e/support/overflow.js
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
status: clean
resolved_findings:
  - CR-01
  - WR-01
  - WR-02
---

# Phase 156: Code Review Report

**Reviewed:** 2026-05-31T15:25:52Z  
**Depth:** standard  
**Files Reviewed:** 7  
**Status:** clean after fixes

## Summary

Reviewed all scoped Phase 156 files with focus on fail-closed entitlement handling, example host resolver/router regression coverage, bounded recovery analytics currency conversion, and e2e overflow tolerance. The initial review found one blocker-level correctness defect and two warning-level security/reliability defects; all three were fixed in `c6273bdf`.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Unknown currency is mislabeled and formatted as USD

**Classification:** BLOCKER  
**Status:** RESOLVED in `c6273bdf`  
**File:** `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:71`  
**Issue:** `currency_atom/1` falls back to `:usd` for any unknown currency string, but the UI label still uses the original currency string (`kpi.currency`). For example, `"cad"` will render label `CAD` while amount is formatted with USD rules/symbol. This silently corrupts monetary analytics output.  
**Fix:**
```elixir
# Keep canonical currency from data; only normalize case for matching.
defp currency_atom(currency) when is_binary(currency) do
  currency
  |> String.downcase()
  |> String.to_existing_atom()
rescue
  ArgumentError -> nil
end

# In handle_params/3
currency_arg = currency_atom(currency)

formatted_recovered =
  if currency_arg, do: Accrue.Invoices.Render.format_money(recovered.cents, currency_arg, locale), else: "#{recovered.cents} #{String.upcase(to_string(currency))}"
```

## Warnings

### WR-01: External link uses `target="_blank"` without `rel` protections

**Classification:** WARNING  
**Status:** RESOLVED in `c6273bdf`  
**File:** `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:95`  
**Issue:** External docs link opens a new tab with `target="_blank"` but omits `rel="noopener noreferrer"`, which allows reverse-tabnabbing in browsers that still expose `window.opener`.  
**Fix:**
```heex
<a
  href="https://hexdocs.pm/accrue/analytics.html#cutoff-semantics"
  target="_blank"
  rel="noopener noreferrer"
  class="text-xs text-slate-500 hover:text-slate-700 bg-slate-100 px-2 py-1 rounded border border-slate-200 ml-4"
>
```

### WR-02: Viewport helper does not assert right/bottom bounds

**Classification:** WARNING  
**Status:** RESOLVED in `c6273bdf`  
**File:** `examples/accrue_host/e2e/support/overflow.js:28`  
**Issue:** `expectVisibleInViewport` only checks left/top clipping (`box.x`, `box.y`), so elements clipped on the right or below viewport still pass. This weakens route-regression/e2e coverage and can hide real layout breakage.  
**Fix:**
```js
expect(
  box.x + box.width,
  `${label} should not be clipped on the right`
).toBeLessThanOrEqual(viewport.width + SUBPIXEL_TOLERANCE_PX);

expect(
  box.y + box.height,
  `${label} should not be clipped below the viewport`
).toBeLessThanOrEqual(viewport.height + SUBPIXEL_TOLERANCE_PX);
```

---

## Resolution Verification

- `cd examples/accrue_host && mix test test/accrue_host_web/live/recovery_analytics_test.exs --seed 0`
- `cd examples/accrue_host && npm run e2e -- e2e/phase13-canonical-demo.spec.js --project=chromium-desktop`

_Reviewed: 2026-05-31T15:25:52Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
