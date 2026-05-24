# Phase 126: Admin Surface + Docs / JTBD Spine - Pattern Map

**Mapped:** 2026-05-23
**Files analyzed:** 16 (5 new, 11 modified)
**Analogs found:** 16 / 16 (every file clones an in-repo analog — zero new components/schemas/migrations)

> Read-only map for `gsd-planner`. Every new file CLONES an existing analog; every
> modified file EXTENDS an existing in-file pattern. All excerpts below were read
> from live code with file:line anchors. Two workstreams: (A) the read-only
> entitlements tab + read seam, (B) the docs/verifier pass.

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| **NEW** `accrue/lib/accrue/entitlements/admin.ex` | service (read seam) | request-response (read-only fold) | `accrue/lib/accrue/entitlements/resolver/local_map.ex` (fold + catalog privates) | role-match (new thin module wrapping existing privates) |
| **MOD** `accrue/lib/accrue/entitlements/resolver/local_map.ex` (+2 `@doc false` delegations) | service | request-response | self (`fold_active/1` `:96`, `catalog/0` `:253`, `active_items/1` `:150`) | exact (in-file extension) |
| **NEW** `accrue_admin/lib/accrue_admin/copy/entitlements.ex` | config (copy SSOT) | static | `accrue_admin/lib/accrue_admin/copy/customer_payment_methods.ex` | exact |
| **MOD** `accrue_admin/lib/accrue_admin/copy.ex` (+`defdelegate`s) | config | static | self (the `CustomerPaymentMethods` defdelegate block `:434-499`) | exact |
| **MOD** `accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex` (+allowlist) | config | static | self (`@allowlist` `:18-60`) | exact |
| **MOD** `accrue_admin/lib/accrue_admin/live/customer_live.ex` (entitlements tab) | component (LiveView) | request-response (SSR) | self (`"payment_methods"` clause `:264`, `@tabs` `:31`, `tab_counts/1` `:387`, `tabs/4` `:410`) | exact (in-file extension) |
| **NEW** `accrue/guides/entitlements.md` | docs | static | `accrue/guides/connect.md` (peer skeleton) + `accrue/guides/webhooks.md` (terse SSOT-defer) | exact |
| **MOD** `accrue/guides/jobs_to_be_done.md` (flip + spine) | docs | static | self (`## The customer changes their mind` `:116`, `## Scope and maturity` `:318`, Update log `:350`) | exact (in-file extension) |
| **MOD** `accrue/README.md` (Start here bullet) | docs | static | self (`## Start here` list `:9-22`) | exact |
| **MOD** `accrue/guides/quickstart.md` (focused-guides bullet) | docs | static | self (focused-guides list) | exact |
| **MOD** `.planning/research/JTBD-FRONTIER.md` (internal flip) | docs | static | self (gap rows `:85`/`:110`, TL;DR `:21`, diminishing-returns `:142`/`:158`, Update log `:160`) | exact (in-file extension) |
| **MOD** `.planning/PROJECT.md` (`gateway subscription core` phrase) | docs | static | self (Current posture / PROC-08 prose `:37`) | exact |
| **MOD** `scripts/ci/verify_package_docs.sh` (D-13 phrase + 5 needles) | config (CI verifier) | static | self (`require_fixed` block `:97-109`, `:219-223`) | exact (in-file extension) |
| **MOD** `accrue/test/accrue/docs/package_docs_verifier_test.exs` (+2 seed fixtures) | test | static | self (`seed_tmp_dir!` `copy_fixture!` list `:254-274`) | exact (in-file extension) |
| **NEW** `accrue/test/accrue/entitlements/admin_test.exs` | test (unit) | request-response | `accrue/test/accrue/entitlements/local_map_test.exs` | exact |
| **NEW** `accrue_admin/test/accrue_admin/live/entitlements_live_test.exs` | test (LiveView) | request-response | `accrue_admin/test/accrue_admin/live/customer_live_test.exs` + `local_map_test.exs` config setup | exact |

---

## Pattern Assignments

### NEW `accrue/lib/accrue/entitlements/admin.ex` (service / read seam) — D-04

**Analog:** `accrue/lib/accrue/entitlements/resolver/local_map.ex` (the privates it reuses).

This is the ONE load-bearing technical file. It is a brand-new thin module that
must NOT re-implement the fold — it calls back into `LocalMap`. Research Pattern 1
locks the recommended shape (candidate iii: new `Accrue.Entitlements.Admin` +
two `@doc false` delegations on `LocalMap`).

**Module + alias header to mirror** (clone the moduledoc-then-alias shape from `local_map.ex:1-50`):
```elixir
defmodule Accrue.Entitlements.Admin do
  @moduledoc """
  Internal read-only diagnostic seam for the accrue_admin entitlements tab
  (ENT-11). NOT a public gate API — no boolean entitled?-style surface
  (Phase 123 D-07 stays deferred). One-way dependency: admin → billing.
  Hard-codes the default LocalMap resolver (custom resolvers out of scope
  for this read-only diagnostic).
  """
  alias Accrue.Entitlements.Resolver.LocalMap

  @spec resolve_for_customer(Accrue.Billing.Customer.t()) ::
          {resolved :: map(), unmapped_price_ids :: [String.t()]}
  def resolve_for_customer(%Accrue.Billing.Customer{} = customer) do
    {LocalMap.fold_for_customer(customer), LocalMap.unmapped_entitling_price_ids(customer)}
  end
end
```

**Why it returns `{resolved, unmapped}`:** the resolver structurally discards
unmapped price_ids — `handle_unmapped(acc, _price_id, :deny), do: acc`
(`local_map.ex:244`), so the resolved map can NEVER show drift. The seam re-reads
subs independently for the drift list.

---

### MOD `accrue/lib/accrue/entitlements/resolver/local_map.ex` (+2 `@doc false` delegations)

**Analog:** self — the existing privates `fold_active/1` (`:96`), `catalog/0`
(`:253`), `active_items/1` (`:150`).

The resolved-map shape these return (the contract the admin renders), from
`@empty` at `local_map.ex:53-61`:
```elixir
%{
  plan: atom() | nil,                          # last representative active plan (display only)
  active_plans: MapSet.t(atom()),              # membership SSOT
  features: MapSet.t(atom()),                  # UNION of all active plans' features
  quantities: %{atom() => non_neg_integer()},  # quota_key => min(cap, quantity)
  grace_plans: MapSet.t(atom()),
  grace_features: MapSet.t(atom()),
  expired_grace_plans: MapSet.t(atom())
}
```
(`:non_grace_features` is an internal accumulator stripped before return — `local_map.ex:111-112`.)

**Add these two `@doc false` delegations** (NO fold copy — they wrap the privates;
note `active_items/1` returns `{price_id, quantity, via_grace?}` 3-tuples per
`:171`/`:181`, and `catalog/0` returns `{reverse_index, plans, unmapped_action}` per `:265`):
```elixir
# Public seam for the admin diagnostic (ENT-11). Reuses fold_active/1 — the
# SSOT fold — so there is zero drift. Does NOT widen the gate API.
@doc false
def fold_for_customer(%Customer{} = customer), do: fold_active(customer)

# The entitling price_ids the resolver structurally discards under :deny.
@doc false
def unmapped_entitling_price_ids(%Customer{id: customer_id}) do
  {reverse_index, _plans, _action} = catalog()

  customer_id
  |> active_items()
  |> Enum.map(fn {price_id, _qty, _via} -> price_id end)
  |> Enum.reject(&Map.has_key?(reverse_index, &1))
  |> Enum.uniq()
end
```

**`catalog/0` reverse-index build to reuse (do NOT rebuild in admin)** (`local_map.ex:253-266`):
```elixir
defp catalog do
  config = Accrue.Config.entitlements()
  plans = Keyword.get(config, :plans, [])
  unmapped_action = Keyword.get(config, :unmapped_action, :deny)

  reverse_index =
    Enum.reduce(plans, %{}, fn {plan_atom, entry}, acc ->
      entry
      |> Keyword.get(:price_ids, [])
      |> Enum.reduce(acc, fn price_id, inner -> Map.put(inner, price_id, plan_atom) end)
    end)

  {reverse_index, plans, unmapped_action}
end
```

---

### NEW `accrue_admin/lib/accrue_admin/copy/entitlements.ex` (config / copy SSOT) — D-05

**Analog:** `accrue_admin/lib/accrue_admin/copy/customer_payment_methods.ex` (read in full, 60 lines).

**Exact module + `@doc false` 0-arity fn pattern to clone** (`customer_payment_methods.ex:1-60`):
```elixir
defmodule AccrueAdmin.Copy.CustomerPaymentMethods do
  @moduledoc false

  @doc false
  def section_heading, do: "Payment methods"

  @doc false
  def empty_copy, do: "No payment methods on file."

  @doc false
  def delete_blocked_in_use, do: "This payment method still funds an active subscription."
  # ... one @doc false 0-arity fn per operator string
end
```

Mirror exactly for `AccrueAdmin.Copy.Entitlements` — one `@doc false` 0-arity fn
per UI-SPEC Copywriting-Contract row (`126-UI-SPEC.md:115-129`):
`entitlements_drift_section_title/0`, `entitlements_active_plans_label/0`,
`entitlements_features_label/0`, `entitlements_quantities_label/0`,
`entitlements_grace_label/0`, `entitlements_unmapped_badge/0` (`"⚠ Unmapped plan"`),
`entitlements_empty_title/0`, `entitlements_empty_copy/0`,
`entitlements_no_drift_copy/0`, `entitlements_raw_map_label/0`,
`entitlements_error_copy/0` (fail-closed honesty — must say "no access is granted").

---

### MOD `accrue_admin/lib/accrue_admin/copy.ex` (+`defdelegate`s)

**Analog:** self — the `CustomerPaymentMethods` block (`copy.ex:434-499`).

**Add the alias** (alongside `copy.ex:9-15`): `alias AccrueAdmin.Copy.Entitlements`.

**Exact `defdelegate ... as:` pattern to clone** (`copy.ex:434-438`):
```elixir
defdelegate customer_payment_methods_section_heading(),
  to: CustomerPaymentMethods,
  as: :section_heading

defdelegate customer_payment_methods_empty_copy(), to: CustomerPaymentMethods, as: :empty_copy
```
Mirror as `defdelegate entitlements_*(), to: Entitlements, as: :<shortname>` for each
new copy fn. (The `as:` strips the `entitlements_` prefix so the submodule fn is
short, exactly like the payment-methods block.)

---

### MOD `accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex` (+allowlist)

**Analog:** self — the `@allowlist` sigil-w block (`:18-60`).

**Exact pattern** (`accrue_admin.export_copy_strings.ex:42-59`): add each new 0-arity
`AccrueAdmin.Copy.entitlements_*` fn name to the `~w( ... )a` allowlist, alongside the
existing `customer_payment_methods_*` entries:
```elixir
@allowlist ~w(
  ...
  customer_payment_methods_section_heading
  customer_payment_methods_empty_copy
  ...
  customer_payment_methods_in_use_badge
)a
```
The export loop only emits 0-arity fns present in BOTH the allowlist and
`AccrueAdmin.Copy.__info__(:functions)` (`:80-84`) — so the `defdelegate`s above must
be 0-arity (they are).

---

### MOD `accrue_admin/lib/accrue_admin/live/customer_live.ex` (entitlements tab) — D-01/D-02/D-03

**Analog:** self — the `"payment_methods"` tab clause (`:264-354`) is the richest
clone target; the `"metadata"` clause (`:366-367`) shows the bare `JsonViewer` call.

**1. `@tabs` allowlist** (`customer_live.ex:31`) — add `entitlements` (drives `normalize_tab/1` `:670` + `tabs/4` `:410`):
```elixir
@tabs ~w(subscriptions invoices charges payment_methods events metadata)
# → ~w(subscriptions invoices charges payment_methods entitlements events metadata)
```

**2. Add `import AccrueAdmin.Components.StatusBadge` / alias** — `StatusBadge` is NOT
yet in the alias block (`customer_live.ex:17-27`); add it. `KpiCard`, `JsonViewer`,
`Tabs` are already aliased.

**3. `case @tab do` render clause** (`:223`) — clone the `"payment_methods"` clause
shape (`ax-card` section, Copy-backed heading via `Copy.*`, `:for` list rows, `:if`
empty state). Use a private helper (consistent with `subscriptions(@customer)` at
`:424`) that calls the seam ONCE: `entitlements_view(@customer)` returning
`{resolved, unmapped}`. The clause skeleton (mirrors `"payment_methods"` `:264-280` +
`"metadata"` `:366`):
```elixir
<% "entitlements" -> %>
  <section class="ax-card">
    <h3 class="ax-heading"><%= Copy.entitlements_section_title() %></h3>
    <div :for={plan <- active_plans(@customer)} class="ax-list-row">
      <StatusBadge.status_badge status={plan} tone="moss" />
    </div>
    <%!-- features, quantities (KpiCard), grace section, unmapped badges --%>
    <p :if={no_entitlements?(@customer)} class="ax-body"><%= Copy.entitlements_empty_copy() %></p>
    <JsonViewer.json_viewer id="customer-entitlements" label={Copy.entitlements_raw_map_label()} payload={display_map(@customer)} />
  </section>
```

**Component call idioms to copy (verified signatures):**

- `StatusBadge.status_badge` (`status_badge.ex:8-10`): `attr :status (required, :any)`,
  `attr :label (:string, default nil)`, `attr :tone (:string, default nil)`. Tone
  fallback for unknown atoms is `"ink"` (`:39`) — pass explicit `tone="moss"` for
  active plans, `tone="amber"` for grace + the unmapped badge. `:past_due`/`:grace_period`
  map to `"amber"` automatically (`:34-36`).
- `KpiCard.kpi_card` (`kpi_card.ex:11-19`): `attr :label (required)`, `attr :value
  (required, :string — MUST be a string, use Integer.to_string/1)`, `attr :delta`,
  `attr :delta_tone (default "slate")`, `slot :meta`. In-file usage example
  (`customer_live.ex:191-198`):
  ```elixir
  <KpiCard.kpi_card label="Subscriptions" value={Integer.to_string(@tab_counts.subscriptions)}
    delta={...} delta_tone="cobalt"><:meta>...</:meta></KpiCard.kpi_card>
  ```
- `JsonViewer.json_viewer` (`json_viewer.ex:8-12`): `attr :id (required)`,
  `attr :payload (required, :any)`, `attr :label`. In-file usage (`customer_live.ex:367`):
  `<JsonViewer.json_viewer id="customer-metadata" label="Customer metadata" payload={metadata_payload(@customer)} />`.
  **PITFALL (research Pitfall 2):** `normalize_payload/1` renders a `MapSet` struct as
  `%{"__struct__" => "MapSet"}` (`json_viewer.ex:146-164`). Build a plain display map
  first: `%{active_plans: MapSet.to_list(resolved.active_plans) |> Enum.sort(), ...}`.
- `Tabs.tabs` (`tabs.ex:8-21`): renders count badge only `:if={tab[:count]}` (`:21`),
  so a `nil` count = no badge. Safe to OMIT the entitlements count (D-01).

**4. `tab_counts/1`** (`:387-408`) — OMIT an `:entitlements` key (research recommendation
+ D-01). `tabs/4` (`:410-422`) does `Map.get(counts, String.to_existing_atom(tab))`
(`:419`); a missing key returns `nil` → no badge. `:entitlements` atom already exists
(config key) so `String.to_existing_atom/1` won't raise.

**Empty-state Copy idiom to mirror** (`copy.ex:430`): `def customer_detail_no_subscriptions, do: "No subscriptions for this customer yet."` and its template use (`customer_live.ex:236`): `<p :if={subscriptions(@customer) == []} class="ax-body"><%= Copy.customer_detail_no_subscriptions() %></p>`.

---

### NEW `accrue/guides/entitlements.md` (docs) — D-06/D-07/D-08

**Analog:** `accrue/guides/connect.md` (414 lines — the peer skeleton) +
`accrue/guides/webhooks.md` (terse SSOT-defer voice).

**`connect.md` skeleton to mirror** (verified section order):
`# Title` → opening prose + a `> **boundary:**` blockquote → `## Getting Started — <subtitle>`
(`:23`) → topic `## sections` each with fenced runnable snippets (`## Separate charges
+ transfers` `:147`, `## Scoped operations` `:173`, `## Platform fee computation` `:224`,
`## Testing — Fake keyspace scoping` `:290`) → `## Pitfalls` (`:334`) → `## Related guides`
(`:400`) → `## References` (`:407`).

**`webhooks.md` SSOT-defer voice to mirror** (`webhooks.md:1-6`): opens by pointing at
the SSOT — *"For the canonical lifecycle glossary ... see [Lifecycle Semantics]
(lifecycle_semantics.md). Use that guide for the meaning of `active` ...; use this guide
for delivery ..."* — clone this "defer truth, own the how" framing.

**Section order (D-06 Option A) + load-bearing needle anchors:**
1. `# Entitlements — gate features on what they paid for`
2. Fail-closed easy path FIRST (must contain literal `entitled?` — needle D-14 #2;
   source `entitlements.ex:1-22`): `if Accrue.entitled?(user, :pro), do: render_pro(), else: upsell()`
3. `## Configure the catalog` — `plans`/`unmapped_action: :deny`/`past_due_grace`
4. `## Gate a controller route` — MUST contain literal `Accrue.Plug.RequireEntitlement`
   (needle D-14 #3; module confirmed `require_entitlement.ex:1`) + `require_feature`/
   `require_plan` router macros (confirmed `router.ex:79,93`)
5. `## Gate a LiveView` — `Accrue.Live.Entitlements` `on_mount({:require_feature, ...})`
   / `({:require_plan, ...})` (confirmed `live/entitlements.ex:104,108`)
6. `## Lifecycle truth` — inline ~5 rows + link to
   `lifecycle_semantics.md#lifecycle--entitlement-truth-table` (anchor CONFIRMED:
   `## Lifecycle → entitlement truth table` at `lifecycle_semantics.md:173`)
7. `## Provider honesty` — prose only ("local-identical across Stripe/Braintree/Fake"),
   link `Accrue.Processor.Capabilities` (the `.planning/processor-support-matrix.md`
   is internal-only — research A1)
8. `## Telemetry` — MUST contain literal `[:accrue, :entitlements, :check]` (needle
   D-14 #4; source `entitlements.ex:34`)
9. `## Related guides` — links OUT to lifecycle_semantics.md, telemetry.md, auth_adapters.md (D-08)

**Length:** ≤ connect.md (~414 lines). **No mix.exs edit** — guides auto-glob.

---

### MOD `accrue/guides/jobs_to_be_done.md` (flip + spine) — D-09/D-10/D-14 #5

**Analog:** self — peer body sections + the scope table + Update log.

**1. New body section** — insert `## Gate access on what they paid for` BETWEEN
`## The customer changes their mind` (`:116`) and `## When payments fail` (`:156`).
Clone the existing body-section shape (verified `:116-154`): `**The job:**` line →
prose → fenced ```elixir snippet → `→ **In admin:**` pointer → `→ **Deep dive:**` link.
The in-admin pointer should reference the new entitlements tab; deep-dive →
`[Entitlements](entitlements.md)`.

**2. Scope-and-maturity flip** (`:339-342`) — the EXACT prose to flip:
```
The most useful thing still **on the table** is **entitlements** — first-party
helpers to *gate features* on a subscription (`has_active_plan?`, plugs, guards).
Today that's the host's job via [`Accrue.Auth`](auth_adapters.md); subscription
state is all local, so it's a thin layer rather than a missing foundation.
```
Flip to "core entitlements ✅ shipped — gate API, Plug + LiveView guards,
provider-honest, lifecycle-truthful; optional Stripe-native sync is deferred,
off-by-default (Phase 127)" (D-10 honest phrasing). The phrase `on the table** is
**entitlements` is the `require_absent_regex` flip-guard target (D-14 #5b, Pitfall 4) —
the flip MUST drop it.

**3. Update-log line 354** (`jobs_to_be_done.md:354`): currently ends *"entitlements
flagged as the headline gap."* Reword to remove "headline gap" (Pitfall 4 belt-and-
suspenders) AND append a new dated entry. Add a positive shipped marker (needle D-14
#5a — pick a distinctive post-flip phrase, e.g. `entitlements ✅`).

---

### MOD `accrue/README.md` (Start here bullet) — D-12/D-14 #1

**Analog:** self — the `## Start here` bullet list (`:9-22`).

**Exact bullet shape to clone** (`README.md:18`):
```markdown
- [Webhooks](guides/webhooks.md) — signing, retries, and operational notes.
```
Add ONE peer bullet: `- [Entitlements](guides/entitlements.md) — gate features on what
they paid for; the next read when you need to lock paid surfaces.` The exact link text
`[Entitlements](guides/entitlements.md)` is needle D-14 #1 (pin THAT literal). NOTE:
README has uncommitted local edits — re-read on-disk before editing (Pitfall 3).

---

### MOD `accrue/guides/quickstart.md` (focused-guides bullet) — D-12/D-14 #6

**Analog:** self — quickstart's focused-guides list (uses `[First Hour](first_hour.md)`
+ `auth_adapters.md`, both already pinned at `verify_package_docs.sh:73,75`).

Add ONE bullet `[Entitlements](entitlements.md)` to the focused-guides list (relative
to the guides dir, so NO `guides/` prefix). Pin needle D-14 #6 ONLY if added:
`require_fixed quickstart.md '[Entitlements](entitlements.md)'`. NOTE: quickstart has
uncommitted local edits (Pitfall 3).

---

### MOD `.planning/research/JTBD-FRONTIER.md` (internal flip) — D-11

**Analog:** self — verified flip targets:
- TL;DR "exactly one item" (`:21`) + "spend it on entitlements" (`:23`) → "6 of 6 shipped"
- Coverage-map gap row (`:85`): `| Entitlements / plan-gating ... | ⛔ | ... | **SEED-002 #4 — the headline gap** |` → move to **✅ Shipped** with deferred-sync note
- Delta-table row (`:110`): `| **Entitlements / feature-gating** | ⛔ | ...` → flip the Accrue cell ⛔→✅
- Diminishing-returns prose (`:118`, `:125`, `:142`, `:154`, `:158`) — rewrite the "the one capability ... Accrue lacks" + "the last high-value point" + "the highest-leverage thing left"
- Update log (`:160-162`) — append a dated entry; re-verify cells against code

**Update-log append shape to clone** (`JTBD-FRONTIER.md:162`):
```markdown
- **2026-05-22** — Initial frontier map. As-of accrue 1.1.1 / v1.38. Verified all status cells against source ... Verdict: feature-complete on core; entitlements is the single headline gap.
```

---

### MOD `.planning/PROJECT.md` (`gateway subscription core` phrase) — D-13

**Analog:** self — Current posture / PROC-08 prose (`PROJECT.md:37`). The phrase is
the lone holdout among 5 files that pin it (README `:105`, STRATEGY `:207`).

**Exact line to reword** (`PROJECT.md:37`):
```
- The active strategy remains **PROC-08**: a bounded dual-provider core centered on **Stripe-first** defaults plus one Stripe-like gateway. ...
```
Insert the literal `gateway subscription core`, e.g. "...a bounded dual-provider
**gateway subscription core** centered on **Stripe-first** defaults plus one
Stripe-like gateway." (`grep -F` match for `verify_package_docs.sh:220`).

---

### MOD `scripts/ci/verify_package_docs.sh` (D-13 already-present + 5 new needles) — D-14

**Analog:** self — the `require_fixed` README/guide block (`:97-109`) and the PROJECT.md
posture block (`:219-223`).

**Helper idioms (verified `:23-44`):**
```bash
require_fixed() { grep -Fq "$2" "$1" || fail "$1 is missing: $2"; }            # literal
require_regex() { grep -Eq "$2" "$1" || fail "$1 does not match: $2"; }        # ERE present
require_absent_regex() { if grep -Eq "$2" "$1"; then fail "$1 must not match: $2"; fi; }  # ERE absent
```

The `gateway subscription core` assertion ALREADY EXISTS at `:220` (`require_fixed
"$ROOT_DIR/.planning/PROJECT.md" "gateway subscription core"`) — D-13 satisfies it by
editing PROJECT.md, no script change for that needle.

**Add the 5 new needles** (mirror the `:97-109` README block + the `:73-76` quickstart
block; place in a labeled entitlements block):
```bash
# Entitlements spine (Phase 126, ENT-12)
require_fixed "$ROOT_DIR/accrue/README.md" '[Entitlements](guides/entitlements.md)'        # D-14 #1
require_fixed "$ROOT_DIR/accrue/guides/entitlements.md" 'entitled?'                          # D-14 #2
require_fixed "$ROOT_DIR/accrue/guides/entitlements.md" 'Accrue.Plug.RequireEntitlement'     # D-14 #3
require_fixed "$ROOT_DIR/accrue/guides/entitlements.md" '[:accrue, :entitlements, :check]'    # D-14 #4
require_fixed "$ROOT_DIR/accrue/guides/jobs_to_be_done.md" 'entitlements ✅'                   # D-14 #5a (use the exact post-flip marker authored in jobs_to_be_done.md)
require_absent_regex "$ROOT_DIR/accrue/guides/jobs_to_be_done.md" 'on the table\*\* is \*\*entitlements'  # D-14 #5b flip-guard
```
The literal link text in needle #1 MUST byte-match the README bullet authored above
(`grep -F` is literal incl. brackets/parens). Do NOT pin deny-redirect prose, quota
numbers, matrix wording, or replicated gate-fn names (D-14 explicit).

---

### MOD `accrue/test/accrue/docs/package_docs_verifier_test.exs` (+2 seed fixtures) — D-15

**Analog:** self — the `seed_tmp_dir!/1` `copy_fixture!` list (`:254-274`).

**Exact pattern** (`package_docs_verifier_test.exs:260-266`):
```elixir
copy_fixture!("accrue/README.md", tmp_dir)
copy_fixture!("accrue/guides/custom_processors.md", tmp_dir)
copy_fixture!("accrue/guides/first_hour.md", tmp_dir)
copy_fixture!("accrue/guides/quickstart.md", tmp_dir)
copy_fixture!("accrue/guides/production-readiness.md", tmp_dir)
copy_fixture!("accrue/guides/testing.md", tmp_dir)
```
Add the two files any new needle references (or negative fixtures fail "No such file"):
```elixir
copy_fixture!("accrue/guides/entitlements.md", tmp_dir)       # NEW — needles 2/3/4
copy_fixture!("accrue/guides/jobs_to_be_done.md", tmp_dir)    # needles 5a/5b; NOT currently seeded (verified :254-274)
```
`copy_fixture!/2` (`:241-245`) uses `File.cp!` from the working tree, so the untracked
`jobs_to_be_done.md` seeds fine — but COMMIT it this phase or clean-checkout CI can't
see it (Pitfall 3). `.planning/PROJECT.md` is ALREADY seeded (`:258`), so D-13 auto-
greens the 6 failing negative-fixture tests with no seed change.

---

### NEW `accrue/test/accrue/entitlements/admin_test.exs` (unit) — Wave 0

**Analog:** `accrue/test/accrue/entitlements/local_map_test.exs` (read `:1-90`).

**Config-mutation setup to clone** (`local_map_test.exs:28-49`):
```elixir
use Accrue.BillingCase, async: false   # async: false REQUIRED — mutates app env

@entitlements [
  plans: [
    p1: [features: [:reports, :export], limits: [seats: 5], price_ids: ["price_p1"]],
    p2: [features: [:export, :api], limits: [api_calls: 100], price_ids: ["price_p2"]]
  ],
  unmapped_action: :deny
]

setup do
  prev = Application.get_env(:accrue, :entitlements)
  Application.put_env(:accrue, :entitlements, @entitlements)
  on_exit(fn ->
    if prev, do: Application.put_env(:accrue, :entitlements, prev),
             else: Application.delete_env(:accrue, :entitlements)
  end)
  :ok
end
```

**Customer-seeding idiom** (`local_map_test.exs:67-68`):
`%{customer: c} = Accrue.Test.Factory.active_subscription(%{owner_id: oid, price_id: "price_p1"})`
— but `admin_test.exs` calls `Admin.resolve_for_customer(c)` (it HOLDS a `%Customer{}`),
unlike `LocalMap.resolve(billable, [])` which takes a billable. Cover: mapped (resolved
features non-empty + unmapped empty), unmapped (`price_basic` factory default → in unmapped
list, NOT in active_plans — Pitfall 1), empty (no sub → `{@empty, []}`), grace state.

---

### NEW `accrue_admin/test/accrue_admin/live/entitlements_live_test.exs` (LiveView) — Wave 0

**Analog:** `accrue_admin/test/accrue_admin/live/customer_live_test.exs` (read `:1-198`)
for the LiveCase + AuthAdapter + Factory + Fake.transition idiom; `local_map_test.exs`
for the `:entitlements` config setup.

**AuthAdapter + setup idioms to clone** (`customer_live_test.exs:1-47`):
```elixir
use AccrueAdmin.LiveCase, async: false

defmodule AuthAdapter do
  @behaviour Accrue.Auth
  @impl Accrue.Auth
  def current_user(%{"admin_token" => "admin"}), do: %{id: "admin_1", role: :admin}
  def current_user(_session), do: nil
  @impl Accrue.Auth
  def require_admin_plug, do: fn conn, _opts -> conn end
  @impl Accrue.Auth
  def user_schema, do: nil
  @impl Accrue.Auth
  def log_audit(_user, _event), do: :ok
  @impl Accrue.Auth
  def actor_id(user), do: user[:id]
end

setup do
  prior = Application.get_env(:accrue, :auth_adapter)
  Application.put_env(:accrue, :auth_adapter, AuthAdapter)
  on_exit(fn -> Application.put_env(:accrue, :auth_adapter, prior) end)
  # ... + the :entitlements config block from local_map_test.exs:36-49
  %{customer: customer} = Factory.customer(%{email: "ent@example.com"})
  {:ok, sub} = Billing.subscribe(customer, "price_pro")
  {:ok, _} = Fake.transition(sub.processor_id, :active, synthesize_webhooks: false)
  {:ok, customer: customer}
end
```

**LiveView assertion idiom to clone** (`customer_live_test.exs:162-184`):
```elixir
conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
assert {:ok, _view, html} = live(conn, "/billing/customers/#{customer.id}?tab=entitlements")
assert html =~ "reports"   # granted feature
```
Three render states (research Validation map): resolved features render, unmapped-sub
badge (`"price_basic"` factory default = unmapped, Pitfall 1 gift), empty state (bare
`Factory.customer` no sub).

---

## Shared Patterns

### Copy / VERIFY-01 discipline (D-05)
**Source:** `accrue_admin/lib/accrue_admin/copy/customer_payment_methods.ex` (submodule) +
`copy.ex:434-499` (defdelegate) + `accrue_admin.export_copy_strings.ex:18-60` (allowlist).
**Apply to:** every operator string in the entitlements tab. Three-part contract: new
`@doc false` 0-arity fn in `Copy.Entitlements` → `defdelegate ... as:` in `Copy` →
allowlist entry in the export task. NEVER hardcode a string in the template.

### Read-through-the-seam, never re-derive truth (PITFALLS #2)
**Source:** `local_map.ex` (`fold_active/1` `:96`, `catalog/0` `:253`, `active_items/1` `:150`).
**Apply to:** `admin.ex` + the LiveView clause. The LiveView receives `{resolved,
unmapped}` from `Accrue.Entitlements.Admin.resolve_for_customer/1` and ONLY renders —
never queries `.status` or rebuilds the reverse-index. One-way dependency: admin → core.

### SSOT-mirror co-update (CLAUDE.md / Phase 124 D-06)
**Source:** `verify_package_docs.sh` needle block (`:97-109`) + `package_docs_verifier_test.exs`
seed list (`:254-274`).
**Apply to:** every doc-label change in this phase ships its verifier needle in the SAME
PR, and every needle's target file is in the seed list. The Elixir test shells out to the
SAME bash script, so a script edit auto-greens the 6 failing tests AND exercises the new
needles — provided the referenced files are seeded.

### Summarize-and-link, defer truth one direction (D-07/D-08)
**Source:** `webhooks.md:1-6` (defer-to-SSOT voice) + `connect.md:400` (`## Related guides`).
**Apply to:** entitlements.md — inline ≤5 lifecycle rows then link the truth-table anchor;
provider matrix in prose then link `Processor.Capabilities`; SSOTs never link back for truth.

---

## No Analog Found

None. Every new file has a direct in-repo clone target and every modification extends an
existing in-file pattern. This is an additive admin-tab + docs phase with no new component,
schema, migration, or public API.

---

## Metadata

**Analog search scope:** `accrue/lib/accrue/entitlements/`, `accrue_admin/lib/accrue_admin/{live,copy,components}/`,
`accrue_admin/lib/mix/tasks/`, `accrue/guides/`, `accrue/test/accrue/entitlements/`,
`accrue_admin/test/accrue_admin/live/`, `accrue/test/accrue/docs/`, `scripts/ci/`, `.planning/`.
**Files scanned (read directly):** customer_live.ex, local_map.ex, copy.ex,
customer_payment_methods.ex, export_copy_strings.ex, status_badge.ex, kpi_card.ex,
json_viewer.ex, tabs.ex, entitlements.ex, customer_live_test.exs, local_map_test.exs,
package_docs_verifier_test.exs, verify_package_docs.sh, connect.md, webhooks.md,
jobs_to_be_done.md, JTBD-FRONTIER.md, README.md, PROJECT.md + targeted greps for guard
module names + anchors.
**Pattern extraction date:** 2026-05-23
