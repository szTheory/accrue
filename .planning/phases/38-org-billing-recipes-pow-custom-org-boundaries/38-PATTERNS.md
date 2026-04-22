# Phase 38 — Pattern Map

**Phase:** 38 — Org billing recipes — Pow + custom org boundaries  
**Outputs:** `accrue/guides/organization_billing.md`, `accrue/guides/auth_adapters.md`, `accrue/test/accrue/docs/organization_billing_guide_test.exs`

## Analog: Phase 37 doc + contract test

| New / modified | Role | Closest analog | Excerpt pattern |
|----------------|------|----------------|------------------|
| `organization_billing.md` | ORG-05/06 spine | Phase 37 shipped file | H2 sections + ORG-03 markdown table + `MyApp.*` / `AccrueHost.*` split |
| `organization_billing_guide_test.exs` | Literal guardrails | `accrue/test/accrue/docs/organization_billing_guide_test.exs` | `File.read!(@guide)` + `assert guide =~ needle` list |
| `auth_adapters.md` Pow block | Adapter SSOT | Lines ~83–128 today | Full `MyApp.Auth.Pow` module — Phase 38 adds **one** spine cross-link sentence |

## Code excerpts (reference)

**Contract test module shape** — from Phase 37:

```elixir
defmodule Accrue.Docs.OrganizationBillingGuideTest do
  use ExUnit.Case, async: true
  @guide "guides/organization_billing.md"
  # ...
end
```

**Pow adapter identity** — from `auth_adapters.md`:

```elixir
def current_user(conn), do: Pow.Plug.current_user(conn)
```

## PATTERN MAPPING COMPLETE

*Generated 2026-04-21 for `/gsd-plan-phase 38`.*
