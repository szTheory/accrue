# Phase 150: Documentation & Adopter Proof - Pattern Map

**Mapped:** 2026-05-28
**Files analyzed:** 6 (2 create, 4 modify, 2 read/reuse)
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Action | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|--------|------|-----------|----------------|---------------|
| `examples/accrue_host/lib/accrue_host_web/components/layouts.ex` | MODIFY | component (layout) | request-response (SSR render) | self (existing `Layouts.app` + `<.theme_toggle>` private component) | exact (same file) |
| `examples/accrue_host/lib/accrue_host/billing.ex` | READ/REUSE | service (host facade) | request-response | self — `customer_for_scope/1` (lines 93-97) | exact (reuse, no edit) |
| `examples/accrue_host/priv/repo/seeds.exs` | MODIFY | config (seed script) | batch (idempotent inserts) | self (existing dunning-events blocks) + `dunning_wiring_test.exs` subscribe pattern | role-match |
| `examples/accrue_host/test/accrue_host_web/live/dunning_banner_live_test.exs` | CREATE | test (LiveView) | request-response | `examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs` | exact |
| `accrue/guides/dunning.md` | MODIFY | docs (ExDoc guide) | n/a | self — existing `## Over-email warning` section (lines 237-253) | exact (same file) |
| `examples/accrue_host/docs/adoption-proof-matrix.md` + `scripts/ci/verify_adoption_proof_matrix.sh` | MODIFY | docs + config (drift gate) | n/a | self — existing matrix rows (line 27 dunning wiring, line 29 entitlements) + verifier needles (lines 63-68) | exact (same files) |

**Component public API being consumed (DO NOT MODIFY — shipped Phase 149):**
`AccrueAdmin.Components.DunningBanner.dunning_banner/1` — `attr :customer, :any, required: true`; `slot :inner_block, required: false`. Wrapper class `accrue-dunning-banner-wrapper`; default-message class `accrue-default-dunning-banner`; default copy begins `Action Required: We were unable to process your recent payment.` Renders `~H""` (nothing) when not in dunning. Source: `accrue_admin/lib/accrue_admin/components/dunning_banner.ex:15-37`.

---

## Pattern Assignments

### `examples/accrue_host/lib/accrue_host_web/components/layouts.ex` (component, MODIFY)

**Analog:** self — the existing `Layouts.app/1` function component and the sibling private function components in the same file.

**Mount target — the `<main>` block** (`layouts.ex:65-69`). Insert the banner as the **first child of `<main>`**, before the `<div class="mx-auto ...">`:
```elixir
<main class="px-4 py-20 sm:px-6 lg:px-8">
  <div class="mx-auto max-w-2xl space-y-4">
    {render_slot(@inner_block)}
  </div>
</main>
```

**Existing assigns available to `Layouts.app/1`** (`layouts.ex:28-34`) — only `@flash` and `@current_scope`. `@current_scope` defaults to `nil`. There is NO `on_mount` here (stateless function component), so resolve the customer inline.

**Pattern to follow for a private helper component** — the file already defines private function components like `theme_toggle/1` (`layouts.ex:123`) and `flash_group/1` (`layouts.ex:85`) called via `<.theme_toggle />`. Add a private resolver `defp` for the customer (not a component); the banner itself is the external `<AccrueAdmin.Components.DunningBanner.dunning_banner ... />`.

**Customer-resolution helper to add** (grounded in research Pattern 1; reuses `AccrueHost.Billing.customer_for_scope/1`):
```elixir
defp dunning_customer(%AccrueHost.Accounts.Scope{} = scope) do
  case AccrueHost.Billing.customer_for_scope(scope) do
    {:ok, customer} -> customer
    {:error, _} -> nil
  end
end

defp dunning_customer(_), do: nil
```

**Banner mount in the `~H`** (top of `<main>`). Guard with `match?(%Accrue.Billing.Customer{}, ...)` to avoid the get-or-create side effect (Pitfall 1 in RESEARCH):
```elixir
<AccrueAdmin.Components.DunningBanner.dunning_banner
  :let={...}
  customer={dunning_customer(@current_scope)}
/>
```
Note: the banner itself returns empty when not in dunning, but resolving to `%Customer{}` first (never passing the raw `Organization` billable) is mandatory — see Shared Pattern "Side-effect-safe customer resolution" below.

---

### `examples/accrue_host/lib/accrue_host/billing.ex` (service, READ/REUSE — no edit)

**Analog:** self. This is the **org→customer resolution to reuse** (D-09/D-10). Do not invent a new lookup.

**Exact shape the planner must match** (`billing.ex:93-97`):
```elixir
def customer_for_scope(%Scope{} = scope) do
  with {:ok, organization} <- organization_from_scope(scope) do
    customer_for(organization)
  end
end
```

**Underlying contract** — returns `{:ok, %Accrue.Billing.Customer{}}` on success, `{:error, :no_active_organization}` when the scope has no active org:
- `organization_from_scope(%Scope{active_organization: nil})` → `{:error, :no_active_organization}` (`billing.ex:185-186`)
- `organization_from_scope(%Scope{active_organization: org})` → `{:ok, org}` (`billing.ex:188`)
- `customer_for(billable)` → delegates to `Billing.customer(billable)` (`billing.ex:51-53`) — **NOTE: this is get-or-create**; that is why the layout guards on `%Customer{}` rather than passing a billable to the banner.

**Alternative (heavier) helper** if the planner needs the subscription too: `billing_state_for_scope/1` (`billing.ex:99-103`) returns `{:ok, %{customer: customer, subscription: subscription}}`. `customer_for_scope/1` is the leaner fit for the banner.

---

### `examples/accrue_host/priv/repo/seeds.exs` (config/seed, MODIFY)

**Analog A (same file):** the existing deterministic dunning-events blocks (`seeds.exs:22-88`). Note the established conventions: top-level `alias`, `now = Accrue.Clock.utc_now()`, a `days_ago` closure, and additive `Events.record(...)` calls. **Keep these blocks; the past-due account is additive.**

**Analog B (Fake-backed subscribe + dunning anchor):** `examples/accrue_host/test/accrue_host/dunning_wiring_test.exs` and the subscribe call in `subscription_live_test.exs:34` — `Billing.subscribe(organization, "price_basic")`.

**Account/org creation primitives (confirmed signatures):**
- `AccrueHost.Accounts.register_user(attrs)` → `{:ok, %User{}}` (`accounts.ex:77-81`) — creates an **unconfirmed, password-less** user.
- `AccrueHost.Accounts.update_user_password(user, %{password: ...})` → `{:ok, {user, _expired_tokens}}` (`accounts.ex:164-168`) — note the **nested tuple** return shape; destructure accordingly.
- `AccrueHost.Organizations.create_organization(Scope.for_user(owner), attrs)` → `{:ok, %Organization{}}` (mirrors `AccountsFixtures.organization_fixture/1` at `accounts_fixtures.ex:68-80`).
- Membership: mirror `AccountsFixtures.organization_membership_fixture/1` (`accounts_fixtures.ex:82-115`) — builds `%OrganizationMembership{} |> OrganizationMembership.changeset(attrs) |> Repo.insert()` with `organization_id`, `user_id`, `role: :owner`. **It already guards idempotency via `Repo.get_by(OrganizationMembership, organization_id:, user_id:)`** — copy that guard style.

**The dunning anchor flip (the one column that drives `requires_attention?/1`):** use `force_status_changeset/2`, the only changeset that casts `dunning_campaign_started_at` (cast fields confirmed at `subscription.ex:89-99`):
```elixir
{:ok, _sub} = AccrueHost.Billing.subscribe(org, "price_basic")  # Fake-backed customer + subscription

{:ok, %{subscription: sub}} = AccrueHost.Billing.billing_state_for(org)

sub
|> Accrue.Billing.Subscription.force_status_changeset(%{
     status: :past_due,
     past_due_since: now,
     dunning_campaign_started_at: now
   })
|> AccrueHost.Repo.update!()
```

**Idempotency (mandatory — Pitfall 2):** the existing event seeds use fresh `Ecto.UUID.generate()` so they tolerate re-runs; the account seed needs an **explicit existence guard** before insert (e.g. `Repo.get_by(User, email: "past-due@example.com")` / `unless`), or `mix ecto.reset` will crash on the second run via unique email/slug constraints.

**Login note (Pitfall 5):** seeded user is unconfirmed + password-less by default. Set a password via `update_user_password/2` (and confirm if the password-login guard requires it — planner must verify the auth flow). Document the demo credentials in a seed comment.

---

### `examples/accrue_host/test/accrue_host_web/live/dunning_banner_live_test.exs` (test, CREATE)

**Analog:** `examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs` — copy its module shell, setup block, and assertion style.

**Module header + imports** (`subscription_live_test.exs:1-12`):
```elixir
defmodule AccrueHostWeb.DunningBannerLiveTest do
  use AccrueHostWeb.ConnCase, async: false

  alias AccrueHost.AccountsFixtures
  alias AccrueHost.Billing
  alias AccrueHost.Repo

  import Ecto.Query
  import Phoenix.LiveViewTest
```

**Setup block — Fake processor + cleanup + fixtures** (`subscription_live_test.exs:14-27`):
```elixir
setup do
  case Accrue.Processor.Fake.start_link([]) do
    {:ok, _pid} -> :ok
    {:error, {:already_started, _pid}} -> :ok
  end

  :ok = Accrue.Processor.Fake.reset()
  cleanup_fake_billing_rows!()

  user = AccountsFixtures.user_fixture()
  organization = AccountsFixtures.organization_fixture(%{owner: user})

  %{user: user, organization: organization}
end
```
Also copy the private `cleanup_fake_billing_rows!/0` helper verbatim (`subscription_live_test.exs:210-232`) — it deletes `MeterEvent`, `SubscriptionItem`, `Subscription`, `Customer` rows matching `*_fake_*` processor ids.

**Log-in + live mount + assertion shape** (`subscription_live_test.exs:34-41`). The `log_in_user/3` ConnCase helper takes `active_organization_id:` (`conn_case.ex:65-74`, which puts `:active_organization_id` in the session):
```elixir
{:ok, view, html} =
  conn
  |> log_in_user(user, active_organization_id: organization.id)
  |> live(~p"/app/billing")

assert html =~ "Action Required"      # default banner copy (banner-ON)
# or: assert has_element?(view, ".accrue-default-dunning-banner")
```

**Banner-ON test:** subscribe the org, then flip the dunning anchor via `force_status_changeset/2` (same pattern as the seed above), then assert the banner copy/class is present.

**Banner-OFF test:** subscribe the org WITHOUT setting `dunning_campaign_started_at`, then `refute html =~ "Action Required"` (or `refute has_element?(view, ".accrue-default-dunning-banner")`). This proves the side-by-side D-02 contrast.

---

### `accrue/guides/dunning.md` (docs, MODIFY)

**Analog:** self. Section structure: top-level `## Title`, sub-sections `### Title`, fenced ```elixir blocks, `>` blockquote for warnings (see `## Over-email warning` at `dunning.md:237-253`). Config snippets use `# config/runtime.exs` comments. The guide already cross-references `lifecycle_semantics.md#past_due` — keep that discipline; do not re-derive `past_due` truth.

**Insertion point:** new `## In-App Banners` section goes **immediately after** the `## Over-email warning` block (after line 253's blockquote and the `---` at line 254, before `## Lifecycle and entitlements interaction` at line 256). Add a **cross-link from the over-email warning into the new section** (D-06).

**Content paths required (D-07/D-08):**
1. **Component path** (`accrue_admin` — be explicit it requires `accrue_admin`): document zero-config default usage AND `inner_block` customization with an "Update your card" CTA. Reference `AccrueAdmin.Components.DunningBanner.dunning_banner/1`, `:customer` attr, `inner_block` slot. Default copy (verbatim for the doc): *"Action Required: We were unable to process your recent payment. Please update your payment method to avoid service interruption."*
2. **Core-only DIY path** (`Accrue.Dunning.requires_attention?/1` — core, no `accrue_admin`). Verbatim helper source for accurate snippets (`accrue/lib/accrue/dunning.ex:20-33`):
   ```elixir
   <%= if Accrue.Dunning.requires_attention?(@customer) do %>
     <div class="my-dunning-banner">
       Update your card — <a href={~p"/app/billing"}>fix payment</a>
     </div>
   <% end %>
   ```
   Be explicit about the dependency boundary: ready-made component = `accrue_admin`; helper = core.

---

### `examples/accrue_host/docs/adoption-proof-matrix.md` + `scripts/ci/verify_adoption_proof_matrix.sh` (docs + drift gate, MODIFY)

**Matrix-location decision (RESEARCH Open Question 1 / Assumption A1):** put the BAN-04 row in the **host** `examples/accrue_host/docs/adoption-proof-matrix.md` (NOT `.planning/processor-support-matrix.md` as CONTEXT literally says) — this matches the Phase 130/132 precedent and the existing gated rows. Flag to user if uncertain.

**Analog row (same file)** — add to the **"Blocking: Fake-backed host + browser"** table (`adoption-proof-matrix.md:14-31`). Follow the 3-column shape `| Concern | Proof | Where |`. Closest precedent rows:
- Dunning wiring (`adoption-proof-matrix.md:27`)
- Entitlement gating (`adoption-proof-matrix.md:29`)

The new BAN-04 row should reference the new LiveView test path `test/accrue_host_web/live/dunning_banner_live_test.exs`, the banner component (`AccrueAdmin.Components.DunningBanner`), and the seeded `past-due@example.com` proof.

**Verifier needle (co-update pair — Pitfall 4):** add a matching `require_substring "<token>" "<label>"` line to `scripts/ci/verify_adoption_proof_matrix.sh`. The needle pattern (lines 63-68):
```bash
require_substring "dunning_wiring_test.exs" "dunning wiring host smoke test path in matrix"
require_substring "Entitlement gating" "Entitlement gating row"
require_substring "Accrue.Live.Entitlements" "Accrue.Live.Entitlements API reference"
```
Pick a stable token unique to the new row (e.g. `dunning_banner_live_test.exs` and/or `AccrueAdmin.Components.DunningBanner`) and add it as a new `require_substring`. **Do NOT disturb the ~50 existing needles** — editing surrounding matrix text can break an existing pinned substring. Run `bash scripts/ci/verify_adoption_proof_matrix.sh` from repo root to confirm green.

---

## Shared Patterns

### Side-effect-safe customer resolution (Pitfall 1 — applies to layout)
**Source:** `examples/accrue_host/lib/accrue_host/billing.ex:93-97` (`customer_for_scope/1`) + `accrue/lib/accrue/dunning.ex:21-33`.
**Apply to:** `layouts.ex` banner mount and the guide's component-path snippet.
Resolve `{:ok, %Customer{}}` first and pass the `%Customer{}` (or `nil`) to `dunning_banner`. Never pass a raw `Organization` billable — `requires_attention?/1`'s billable fallback (`dunning.ex:28-33`) calls `Accrue.Billing.customer/1`, a **get-or-create** that inserts a customer row on every render. Guard the mount with `match?(%Accrue.Billing.Customer{}, customer)`.

### Fake processor test/seed setup
**Source:** `subscription_live_test.exs:14-27` (setup) + `:210-232` (`cleanup_fake_billing_rows!/0`).
**Apply to:** the new LiveView test; the seed reuses `Billing.subscribe(org, "price_basic")` through the configured Fake processor (no live Stripe — D-03).
Start `Accrue.Processor.Fake` tolerantly (`{:already_started, _}` → `:ok`), `reset()`, then clean `*_fake_*` rows.

### Dunning anchor write (the one column that matters)
**Source:** `accrue/lib/accrue/billing/subscription.ex:89-99,108-114` + `accrue/lib/accrue/billing/query.ex:149-151`.
**Apply to:** the seed and the banner-ON test.
The entire dunning predicate is `where: not is_nil(s.dunning_campaign_started_at)`. `force_status_changeset/2` is the **only** changeset casting `dunning_campaign_started_at`. No webhook replay / clock advance needed for static demo state.

### Idempotent seed guard
**Source:** `accounts_fixtures.ex:100-114` (`Repo.get_by(...)` before insert) + existing `seeds.exs` UUID-fresh pattern.
**Apply to:** `seeds.exs` past-due account block. Guard `register_user`/`create_organization`/membership inserts so `mix ecto.reset` re-runs cleanly.

### Matrix ↔ verifier co-update discipline
**Source:** `scripts/ci/verify_adoption_proof_matrix.sh:13-20` (`require_substring`) + matrix rows it pins.
**Apply to:** any matrix edit. Every new row needs a matching `require_substring`; never break existing needles. (See also MEMORY: `verify_package_docs ↔ test coupling` — if a `verify_package_docs.sh` needle is touched for the guide, the `PackageDocsVerifierTest` seed must match.)

## No Analog Found

None. Every file has an exact or strong in-repo analog (most are self-edits or direct copies of `subscription_live_test.exs`). This phase is assembly + documentation; all primitives shipped in Phases 130/132/149.

## Metadata

**Analog search scope:** `examples/accrue_host/lib`, `examples/accrue_host/test`, `examples/accrue_host/priv/repo`, `examples/accrue_host/docs`, `accrue/lib/accrue`, `accrue/guides`, `accrue_admin/lib`, `scripts/ci`.
**Files scanned (read this session):** layouts.ex, billing.ex, subscription_live_test.exs, seeds.exs, dunning_banner.ex, accounts_fixtures.ex, adoption-proof-matrix.md, verify_adoption_proof_matrix.sh, dunning.ex, dunning.md (sections), conn_case.ex (log_in_user), accounts.ex (register_user/update_user_password), subscription.ex (cast fields/force_status_changeset).
**Pattern extraction date:** 2026-05-28
