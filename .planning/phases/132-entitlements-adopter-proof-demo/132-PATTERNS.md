# Phase 132: Entitlements Adopter-Proof Demo - Pattern Map

**Mapped:** 2026-05-25 (simulated)
**Files analyzed:** 6
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `examples/accrue_host/docs/adoption-proof-matrix.md` | documentation | N/A | `examples/accrue_host/docs/adoption-proof-matrix.md` | exact |
| `scripts/ci/verify_adoption_proof_matrix.sh` | utility/ci | N/A | `scripts/ci/verify_adoption_proof_matrix.sh` | exact |
| `examples/accrue_host/lib/accrue_host_web/router.ex` | route | request-response | `examples/accrue_host/lib/accrue_host_web/router.ex` | exact |
| `examples/accrue_host/lib/accrue_host_web/controllers/premium_feature_controller.ex` | controller | request-response | `examples/accrue_host/lib/accrue_host_web/controllers/page_controller.ex` | role-match |
| `examples/accrue_host/lib/accrue_host_web/controllers/premium_feature_html.ex` | component | request-response | `examples/accrue_host/lib/accrue_host_web/controllers/page_html.ex` | role-match |
| `examples/accrue_host/test/accrue_host_web/controllers/premium_feature_controller_test.exs` | test | request-response | `examples/accrue_host/test/accrue_host_web/org_billing_access_test.exs` | role-match |

## Pattern Assignments

### `examples/accrue_host/docs/adoption-proof-matrix.md` (documentation, N/A)

**Analog:** `examples/accrue_host/docs/adoption-proof-matrix.md`

**Core Pattern (Matrix row structure)** (lines 28-39):
```markdown
| Concern | Proof | Where |
|--------|--------|--------|
| Billing **`Accrue.Billing.create_checkout_session/2`** facade + **`[:accrue, :billing, :checkout_session, :create]`** telemetry contract | `checkout_session_facade_test.exs` + First Hour / `guides/telemetry.md` | `accrue` package |
```

---

### `scripts/ci/verify_adoption_proof_matrix.sh` (utility/ci, validation)

**Analog:** `scripts/ci/verify_adoption_proof_matrix.sh`

**Core Pattern (Validation)** (lines 14-22):
```bash
require_substring() {
  local needle="$1"
  local label="$2"
  if ! grep -Fq "${needle}" "${matrix}"; then
    echo "verify_adoption_proof_matrix: matrix missing ${label} (expected substring: ${needle})" >&2
    exit 1
  fi
}

require_substring "## Layering note (local proof vs merge-blocking CI)" "Layer B/C layering heading"
```

---

### `examples/accrue_host/lib/accrue_host_web/router.ex` (route, request-response)

**Analog:** `examples/accrue_host/lib/accrue_host_web/router.ex`

**Core Pattern (Pipeline with custom plugs)** (lines 8-16):
```elixir
  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {AccrueHostWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:fetch_current_scope_for_user)
  end
```

**Route Gating Pattern (Pipeline with authentication)** (lines 42-45):
```elixir
  scope "/", AccrueHostWeb do
    pipe_through([:browser, :require_authenticated_user])

    post("/app/organization-scope", OrganizationScopeController, :update)
```

---

### `examples/accrue_host/lib/accrue_host_web/controllers/premium_feature_controller.ex` (controller, request-response)

**Analog:** `examples/accrue_host/lib/accrue_host_web/controllers/page_controller.ex`

**Imports and Core Pattern** (lines 1-7):
```elixir
defmodule AccrueHostWeb.PageController do
  use AccrueHostWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
```

---

### `examples/accrue_host/lib/accrue_host_web/controllers/premium_feature_html.ex` (component, request-response)

**Analog:** `examples/accrue_host/lib/accrue_host_web/controllers/page_html.ex`

**Core Pattern** (lines 1-9):
```elixir
defmodule AccrueHostWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use AccrueHostWeb, :html

  embed_templates "page_html/*"
end
```

---

### `examples/accrue_host/test/accrue_host_web/controllers/premium_feature_controller_test.exs` (test, request-response)

**Analog:** `examples/accrue_host/test/accrue_host_web/org_billing_access_test.exs` and `examples/accrue_host/test/accrue_host_web/controllers/page_controller_test.exs`

**Imports Pattern** (lines 1-8):
```elixir
defmodule AccrueHostWeb.OrgBillingAccessTest do
  use AccrueHost.HostFlowProofCase, async: false

  import Ecto.Query
  import Phoenix.LiveViewTest

  alias Accrue.Billing.{Customer, Subscription}
  alias AccrueHost.Billing
  alias AccrueHost.Repo
```

**Core Gating Assertions Pattern** (lines 53-61):
```elixir
    assert_denied_redirect(
      live(conn, "/admin/customers/#{outsider_customer.id}?org=#{allowed_org.slug}"),
      "/admin/customers?org=#{allowed_org.slug}"
    )
```
```elixir
  defp assert_denied_redirect(result, expected_path) do
    assert {:error,
            {:redirect,
             %{
               to: ^expected_path,
               flash: %{"error" => "You don't have access to billing for this organization."}
             }}} =
             result
  end
```

## Shared Patterns

### Entitlement Plug Usage (to be added)
**Apply to:** `examples/accrue_host/lib/accrue_host_web/router.ex`
```elixir
pipeline :require_premium_entitlement do
  plug Accrue.Plug.RequireEntitlement, feature: :premium
end
```

## Metadata

**Analog search scope:** `/Users/jon/projects/accrue/examples/accrue_host` and `/Users/jon/projects/accrue/scripts`
**Files scanned:** 6
**Pattern extraction date:** 2026-05-25 (simulated)
