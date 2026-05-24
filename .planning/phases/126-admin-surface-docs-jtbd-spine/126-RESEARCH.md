# Phase 126: Admin Surface + Docs / JTBD Spine - Research

**Researched:** 2026-05-23
**Domain:** Phoenix LiveView read-only admin tab + ExDoc guide authoring + bash/Elixir doc-contract verifiers (Elixir 1.17+/Phoenix 1.8+, accrue + accrue_admin monorepo)
**Confidence:** HIGH (every claim grounded against live source with file:line; verifier confirmed RED by running it)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
The CONTEXT.md locked **15 decisions D-01..D-15**, all auto-resolved (zero forks). Copied verbatim by group:

- **D-01** — Add an `"entitlements"` TAB to `AccrueAdmin.Live.CustomerLive` (`/customers/:id?tab=entitlements`). NOT a nested route, NOT a standalone index. Add `"entitlements"` to `@tabs` allowlist and a render clause in the `case @tab` block. Tab count optional.
- **D-02** — Render resolved state first, then drift. Show active plans, granted features, quantities/limits, grace state (`grace_plans`, `grace_features`, `expired_grace_plans`) using existing components (`KpiCard`, `StatusBadge`, list rows, `JsonViewer`).
- **D-03** — Surface unmapped-plan drift by listing the customer's entitling subscriptions and badging any whose `price_id` is NOT in the plan reverse-index with a "⚠ Unmapped plan" badge. The resolver silently drops unmapped active items (`handle_unmapped/3 :deny`), so the resolved map can structurally never show them. Reject telemetry-only surfacing; reject a full diff table.
- **D-04** — Reuse the resolver's SSOT fold; do NOT re-implement in admin; do NOT add a public `Accrue.*` gate/diagnostic API. Need a minimal additive read seam that (a) accepts a `%Customer{}` and reuses the fold for the resolved map, and (b) surfaces the unmapped entitling `price_id`s. Researcher/planner picks exact shape. **Hard constraints:** no fold drift (reuse, don't copy), no public boolean gate API (Phase 123 D-07 `fetch_entitled/2` stays deferred), one-way dependency (admin/entitlements → billing only).
- **D-05** — Copy/VERIFY-01 discipline: operator strings in a new `AccrueAdmin.Copy.Entitlements` submodule, `defdelegate` in `AccrueAdmin.Copy`, added to the `mix accrue_admin.export_copy_strings` allowlist. Test with `AccrueAdmin.LiveCase` + `Factory` + `Fake.transition` covering: resolved features render, unmapped-sub badge, empty/no-entitlements state.
- **D-06** — Single authoritative `entitlements.md` guide, fail-closed-first, summarize-and-link to SSOTs. Section order: gate API + fail-closed → config → Plug guard → LiveView guard → lifecycle truth (trimmed inline table + link) → provider matrix (prose + link) → telemetry → Related guides. Auto-globs into HexDocs (no mix.exs edit). Mirror `connect.md`'s shape.
- **D-07** — Inline-vs-link policy: inline only ~4-5 lifecycle truth-table rows, defer to `lifecycle_semantics.md#lifecycle--entitlement-truth-table`. Footnote grace nuance lives only in the SSOT. Provider matrix: prose only ("local-identical across Stripe/Braintree/Fake"), link to the matrix + `Processor.Capabilities`.
- **D-08** — Hub-and-spoke cross-linking. entitlements.md links OUT to lifecycle_semantics.md, processor matrix + `Processor.Capabilities`, telemetry.md, auth_adapters.md. Inbound links come TO it from jobs_to_be_done.md, quickstart.md, First Hour pointer. SSOTs do NOT link back for truth. Keep depth ≤ connect.md length; one runnable snippet per topic.
- **D-09** — New body-tour section `## Gate access on what they paid for` between `## The customer changes their mind` and `## When payments fail`. Spine as a "next, when you need to gate" pointer (Option B), NOT a day-1 step. Flip the Scope-and-maturity prose and scope row ⛔→✅.
- **D-10** — Honest phrasing: "core entitlements ✅ shipped — gate API, Plug + LiveView guards, provider-honest and lifecycle-truthful; the optional Stripe-native sync is a deferred, off-by-default add-on (Phase 127)." Never claim sync ships now.
- **D-11** — Mirror the flip in `.planning/research/JTBD-FRONTIER.md` per the JTBD re-run convention: move entitlements row Gap→Shipped (with deferred-sync note), rewrite the TL;DR "exactly one item", the delta-table "Entitlements ⛔" row, and "5 of 6 / the sixth" → "6 of 6 shipped". Keep deferred items internal-only. Append dated Update log to BOTH files. Re-verify cells against code.
- **D-12** — Spine wiring (minimal): ONE bullet to README "Start here" → `guides/entitlements.md`, ONE bullet to quickstart's focused-guides list. Leave First Hour's pinned spine untouched (optional non-structural cross-link). NOTE: README/quickstart/maturity have UNCOMMITTED local edits.
- **D-13** — Fold in the pre-existing `gateway subscription core` needle fix. Verifier is RED on main; `verify_package_docs.sh:220` requires the literal phrase in PROJECT.md and it's missing (red since 2026-05-08). SC#4 is unsatisfiable without this. Add the phrase to PROJECT.md ~line 37 (Current posture / PROC-08). Reject relaxing the assertion.
- **D-14** — Add a TIGHT set of new spine needles: (1) README `[…](guides/entitlements.md)` link, (2) entitlements.md `entitled?`, (3) entitlements.md `Accrue.Plug.RequireEntitlement`, (4) entitlements.md `[:accrue, :entitlements, :check]` (once, here only), (5) jobs_to_be_done.md positive `entitlements` shipped marker + `require_absent_regex` flip-guard. **Caveat:** "headline gap" also appears in the historical Update log (`jobs_to_be_done.md:354`) — scope the guard or reword. (6) only-if-exists quickstart/first_hour pointer. Do NOT pin: deny-redirect prose, quota numbers, matrix wording, replicated gate-fn names.
- **D-15** — Mandatory Elixir verifier-test co-update. Add `accrue/guides/entitlements.md` (new) AND `accrue/guides/jobs_to_be_done.md` (currently NOT seeded) to `seed_tmp_dir!`'s `copy_fixture!` list or negative fixtures fail "No such file." Verify green: `bash scripts/ci/verify_package_docs.sh` (exit 0) + `mix test test/accrue/docs/package_docs_verifier_test.exs` (8/0) + `mix docs`.

### Claude's Discretion
Per the standing synthesis preference, NO decision crosses the confirm bar — every choice is additive/reversible. The single discretion item left to the researcher/planner is **D-04's exact seam shape** (see Architecture Pattern 1 below for the concrete recommendation). All else is locked.

### Deferred Ideas (OUT OF SCOPE)
- Optional Stripe-native webhook→cache sync + `grant`/`revoke` + ledger writes + `native` capability row (ENT-10) → Phase 127, off by default.
- Public `Accrue.fetch_entitled/2` / `fetch_entitlement_quantity/2` boolean-diagnostic API (Phase 123 D-07) → still deferred; the admin read seam is internal/additive, NOT this.
- Standalone `/entitlements` fleet index → post-v1.0.
- Dedicated drift dashboard / grant-override admin actions → future; this phase is read-only.
- Atomic seat enforcement / membership management → host-owned, documented recipe, never a core API.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ENT-11 | An operator can view a customer's currently-active entitlements/features in `accrue_admin` (read-only). | Architecture Pattern 1 (read seam) + Pattern 2 (tab clone). The resolved map shape and drift-detection inputs are fully specified below; `KpiCard`/`StatusBadge`/`JsonViewer`/`Tabs` cover the render with no new components. |
| ENT-12 | `guides/entitlements.md` documents the full story; JTBD flips ⛔→✅; README "Start here" + First Hour reference it; package-doc verifiers stay green. | Guide skeleton (Pattern 3), JTBD flip targets (exact line refs below), verifier needle set + seed-list co-update (Pattern 4), and a confirmed-RED→green verifier plan. |
</phase_requirements>

## Summary

Phase 126 is **two independent, low-risk workstreams** that share one merge: (A) a read-only entitlements tab on the existing `AccrueAdmin.Live.CustomerLive`, and (B) a documentation pass (new guide + JTBD ⛔→✅ flip + spine pointers + a confirmed-RED doc verifier turned green). There are **no migrations, no schema changes, no webhook code, no gate-decision-logic changes, no new public `Accrue.*` API**. Every SSOT this phase touches (resolver fold, lifecycle truth table, provider matrix) is surfaced/documented, not redefined.

The single load-bearing technical decision is **D-04's read seam**. The resolver's fold (`fold_active/1`, `catalog/0`, `active_items/1`) is fully private to `Accrue.Entitlements.Resolver.LocalMap`, and `resolve/2` takes a *billable* and looks the customer up backwards — but the admin already holds a `%Customer{}`. The resolver also **structurally discards** unmapped active price_ids (`handle_unmapped/3` under `:deny` returns the accumulator unchanged — confirmed `local_map.ex:244`), so the resolved map can never show drift. The admin therefore needs a minimal additive helper that (a) folds from a `%Customer{}` and (b) independently returns the unmapped price_ids. **I recommend a single new module `Accrue.Entitlements.Admin` exposing `resolve_for_customer/1` returning `{resolved_map, unmapped_price_ids}` — see Pattern 1 for the exact signature and why it beats making `LocalMap`'s privates public.**

The verifier is **confirmed RED right now** (I ran it: `EXIT CODE: 1`, `PROJECT.md is missing: gateway subscription core`). This is a `grep -F` short-circuit at `verify_package_docs.sh:220` that masks the rest of the script and fails 6 of 8 Elixir verifier-test cases because `seed_tmp_dir!` copies the live red PROJECT.md into every negative fixture. SC#4 ("verifiers stay green") is literally unsatisfiable without the D-13 fix, so it ships here.

**Primary recommendation:** Build the read seam as `Accrue.Entitlements.Admin.resolve_for_customer/1` (additive, reuses the LocalMap fold via a delegated arity, returns `{resolved, unmapped}`), clone the CustomerLive payment-methods tab pattern for the entitlements tab, write `entitlements.md` mirroring `connect.md`, flip both JTBD artifacts, fix PROJECT.md + add the 5 new needles + co-update the 2 seed fixtures, and verify green with the 3-command gate.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Resolve a customer's entitlements (fold) | API / Backend (`accrue` core) | — | The resolver fold is core domain logic; admin must reuse it, never re-derive (PITFALLS #2). |
| Detect unmapped-plan drift | API / Backend (`accrue` core read seam) | Frontend (badge render) | The reverse-index + entitling-sub query live in core; the admin only renders the result. |
| Render the entitlements tab | Frontend Server (SSR / `accrue_admin` LiveView) | — | Read-only display of an already-resolved map; reuses CustomerLive's mount/auth/breadcrumb spine. |
| Operator copy | Frontend Server (`AccrueAdmin.Copy.Entitlements`) | — | VERIFY-01 SSOT; never hardcoded in template. |
| Document the gate story | Docs (`accrue/guides/entitlements.md`) | — | Summarize-and-link; truth flows one direction from SSOTs. |
| Enforce doc contract | CI (`verify_package_docs.sh` + Elixir wrapper) | — | Merge-blocking drift gate. |

**Tier-correctness note for the planner:** The temptation is to put drift detection in the LiveView (it has the `%Customer{}` and could query subs directly). Resist — the reverse-index comparison must live in the core read seam so it stays consistent with `catalog/0`. The LiveView receives `{resolved, unmapped_price_ids}` and only renders.

## Standard Stack

No new packages. This phase uses only what is already in the monorepo.

### Core (already present — no install)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:phoenix_live_view` | `~> 1.1` (admin) | The entitlements tab | Admin already hard-deps LiveView; CustomerLive is the clone target. |
| `:ecto` / `:ecto_sql` | `~> 3.13` | The entitling-sub query in the read seam | Same `Query.entitling/1` the resolver composes on. |
| `:ex_doc` | `~> 0.40` (dev) | Build `entitlements.md` into HexDocs | Guides auto-glob (`Path.wildcard("guides/*.md")`). |

### Package Legitimacy Audit
**N/A — this phase installs no external packages.** No `mix.exs` dependency edits. (`accrue/mix.exs` docs config is read-only here — the new guide auto-globs.) Per protocol, when a phase installs nothing, the audit table is omitted.

## Architecture Patterns

### System Architecture Diagram

```
                          ┌─────────────────────────────────────────┐
  Operator (browser)      │  accrue_admin (Frontend Server / SSR)    │
       │                  │                                          │
       │  GET /customers/:id?tab=entitlements                       │
       ▼                  │  AccrueAdmin.Live.CustomerLive           │
  ┌──────────┐            │   mount → %Customer{} (owner-scoped)     │
  │  Tabs    │◀───────────│   case @tab "entitlements" ─┐            │
  └──────────┘            │                              │           │
                          └──────────────────────────────┼──────────┘
                                                          │ (one-way: admin → core)
                                          ┌───────────────▼────────────────────┐
                                          │  Accrue.Entitlements.Admin           │  ◀── NEW seam (D-04)
                                          │   resolve_for_customer(%Customer{})  │
                                          │     ├─ {resolved_map}  ◀─ reuses ────┼──┐
                                          │     └─ unmapped_price_ids ◀──────────┼─┐│
                                          └──────────────────────────────────────┘ ││
                                                          │                          ││
              ┌───────────────────────────────────────────┼──────────────────────────┼┘
              │                                            │ reuse fold (no drift)     │ independent read
              ▼                                            ▼                            ▼
   Accrue.Config.entitlements/0          LocalMap.fold_active(%Customer{})   Billing.Query.entitling/1
   (price_id → plan reverse-index)        → %{active_plans, features,         + join SubscriptionItem
                                             quantities, grace_plans,          → [{price_id, quantity}]
                                             grace_features,                   → reject those IN reverse-index
                                             expired_grace_plans}              → unmapped_price_ids
```

The operator traces input (tab click) → CustomerLive case clause → `Admin.resolve_for_customer/1` → which BOTH reuses the LocalMap fold (resolved state) AND independently re-reads entitling subs to compute drift → render via existing components. No write path, no processor calls.

### Recommended Project Structure
```
accrue/lib/accrue/entitlements/
├── admin.ex                 # NEW — Accrue.Entitlements.Admin read seam (D-04)
├── entitlements.ex          # UNCHANGED — public gate API (do not extend)
└── resolver/local_map.ex    # add ONE delegating arity (see Pattern 1), keep fold private

accrue_admin/lib/accrue_admin/
├── live/customer_live.ex    # add "entitlements" to @tabs + case clause + (optional) tab_counts
└── copy/entitlements.ex     # NEW — AccrueAdmin.Copy.Entitlements submodule

accrue_admin/lib/accrue_admin/copy.ex                          # add defdelegates
accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex # add to @allowlist

accrue/guides/entitlements.md          # NEW guide (auto-globs into HexDocs)
accrue/guides/jobs_to_be_done.md       # flip + spine (currently UNTRACKED — see Pitfall 3)
accrue/README.md / quickstart.md       # spine pointers (currently UNCOMMITTED — see Pitfall 3)
.planning/PROJECT.md                   # add "gateway subscription core" phrase (D-13)
.planning/research/JTBD-FRONTIER.md    # internal mirror flip (D-11)
scripts/ci/verify_package_docs.sh      # add 5 needles (D-14)
accrue/test/accrue/docs/package_docs_verifier_test.exs  # add 2 seed fixtures (D-15)
```

### Pattern 1: The D-04 read seam — `Accrue.Entitlements.Admin.resolve_for_customer/1` (THE load-bearing decision)

**Grounding facts (all verified):**
- `LocalMap.resolve/2` takes a **billable** and looks the customer up backwards via `lookup_customer/1` → `(owner_type, owner_id)` (`local_map.ex:69-94`). The admin already holds a `%Customer{}`, so calling `resolve/2` would force a redundant backwards lookup.
- `fold_active/1` (`local_map.ex:96`), `catalog/0` (`:253`), `active_items/1` (`:150`), `none_lane_items/1` (`:164`), `grace_lane_items/2` (`:174`) are all **private** to `LocalMap`.
- `fold_active/1` returns the resolved map shape (verified via `@empty` at `local_map.ex:53-61` and `local_map_test.exs:70-75`):
  ```elixir
  %{
    plan: atom() | nil,                  # last representative active plan (display only)
    active_plans: MapSet.t(atom()),      # membership SSOT
    features: MapSet.t(atom()),          # UNION of all active plans' features
    quantities: %{atom() => non_neg_integer()},  # quota_key => min(cap, quantity)
    grace_plans: MapSet.t(atom()),
    grace_features: MapSet.t(atom()),
    expired_grace_plans: MapSet.t(atom())
  }
  ```
  (`:non_grace_features` is an internal accumulator stripped before return — `local_map.ex:111-112`.)
- The resolver **silently drops** unmapped price_ids: `handle_unmapped(acc, _price_id, :deny), do: acc` (`local_map.ex:244`). So the resolved map can structurally never show drift.
- `Billing.Query.entitling/1` takes a **queryable** (default `Subscription`), NOT a customer_id — the resolver composes `where customer_id` + a `join SubscriptionItem` + `select {price_id, quantity}` on top (`local_map.ex:164-172`; `query.ex:51-59`). The admin seam must do the same composition.
- `Accrue.Config.entitlements/0` returns the raw catalog keyword list with `:plans` (and Phase-124 guard keys put_new'd); the `price_id → plan` reverse-index is built by `LocalMap.catalog/0` from `plans[*][:price_ids]` (`config.ex:897-910`; `local_map.ex:253-266`).

**Recommended shape (evaluated against both CONTEXT candidates):**

Create a **new module `Accrue.Entitlements.Admin`** with one public function:

```elixir
defmodule Accrue.Entitlements.Admin do
  @moduledoc """
  Internal read-only diagnostic seam for the accrue_admin entitlements tab
  (ENT-11). NOT a public gate API — has no boolean entitled?-style surface
  (Phase 123 D-07 stays deferred). One-way dependency: admin → billing.
  """
  alias Accrue.Entitlements.Resolver.LocalMap

  @spec resolve_for_customer(Accrue.Billing.Customer.t()) ::
          {resolved :: map(), unmapped_price_ids :: [String.t()]}
  def resolve_for_customer(%Accrue.Billing.Customer{} = customer) do
    resolved = LocalMap.fold_for_customer(customer)        # reuses the SSOT fold
    unmapped = LocalMap.unmapped_entitling_price_ids(customer)
    {resolved, unmapped}
  end
end
```

In `LocalMap`, add **two thin public delegations** that reuse the existing privates (NO fold copy):

```elixir
# Public seam for the admin diagnostic (ENT-11). Reuses fold_active/1 — the
# SSOT fold — so there is zero drift. Does NOT widen the gate API.
@doc false
def fold_for_customer(%Customer{} = customer), do: fold_active(customer)

# The entitling price_ids the resolver structurally discards under :deny.
# Re-reads the SAME entitling-sub query the fold uses, then keeps only the
# price_ids NOT present in the catalog/0 reverse-index.
@doc false
def unmapped_entitling_price_ids(%Customer{id: customer_id}) do
  {reverse_index, _plans, _action} = catalog()

  customer_id
  |> active_items()                       # reuses the existing private fetch
  |> Enum.map(fn {price_id, _qty, _via} -> price_id end)
  |> Enum.reject(&Map.has_key?(reverse_index, &1))
  |> Enum.uniq()
end
```

**Why this shape (and why it beats the alternatives):**

| Candidate | Verdict | Reasoning |
|-----------|---------|-----------|
| (i) `LocalMap.resolve_for_customer/2` + sibling on `LocalMap` | Acceptable but worse | Puts admin-only concerns directly on the behaviour-implementing resolver. The resolver is keyed to the `Accrue.Entitlements.Resolver` behaviour; bolting an admin diagnostic onto it muddies its single responsibility. |
| (ii) Single `Accrue.Entitlements` diagnostic returning `{resolved, unmapped}` | **Rejected** | `Accrue.Entitlements` is the *public fail-closed gate API*. Adding ANY new public function there risks looking like the deferred `fetch_entitled/2` (D-07) and crosses the "no new public gate/diagnostic API" hard constraint. |
| **(iii, recommended) New `Accrue.Entitlements.Admin` module + 2 `@doc false` delegations on `LocalMap`** | **Recommended** | Keeps the admin seam in its own internal module (clear "this is for the admin, not a gate"), reuses the fold via thin `@doc false` delegations (no drift, no copy), and never touches the public `Accrue.Entitlements` surface. The `@doc false` markers keep these out of the published API docs, preserving the "no public gate API" posture. |

**Resolver-coupling note:** `Admin.resolve_for_customer/1` references `LocalMap` directly (the default resolver) rather than the configured resolver. This is correct for ENT-11 because the admin tab documents/surfaces the *default* local resolution; a host with a custom resolver is out of scope for this read-only diagnostic. If the planner wants resolver-agnosticism, gate it behind `Resolver.__impl__()` — but that adds the requirement that custom resolvers implement the two `@doc false` functions, which is scope creep. **Recommend hard-coding `LocalMap` and noting the limitation in the moduledoc.**

**HARD CONSTRAINT compliance check (all satisfied):**
- ✅ No fold drift — `fold_for_customer/1` literally calls `fold_active/1`.
- ✅ No public boolean gate API — `Admin` is internal-purpose, returns a map+list (not a boolean), and adds nothing to `Accrue.Entitlements`. The `LocalMap` additions are `@doc false`.
- ✅ One-way dependency — `Admin` lives in `accrue` core; the admin LiveView calls into it. Nothing in billing/entitlements calls the admin.

### Pattern 2: CustomerLive entitlements tab — mechanical clone of the payment-methods tab

**Verified edit points in `accrue_admin/lib/accrue_admin/live/customer_live.ex`:**
- `@tabs ~w(subscriptions invoices charges payment_methods events metadata)` at **line 31** → add `entitlements`. Place it where it reads best (e.g. after `payment_methods`). This list also drives `normalize_tab/1` (`:670`) and `tabs/4` (`:410`).
- `case @tab do` block at **line 223** → add a `<% "entitlements" -> %>` clause (mirror the `"payment_methods"` clause structure: an `ax-card` section, Copy-backed heading/body, list rows, empty state).
- `tab_counts/1` at **line 387** returns a map; `tabs/4` (`:410`) reads `Map.get(counts, String.to_existing_atom(tab))`. **Gotcha:** if `"entitlements"` is in `@tabs` but NOT a key in the `tab_counts/1` map, `tabs/4` calls `Map.get(counts, :entitlements)` which returns `nil` → the `Tabs` component renders no count badge (`tabs.ex:21` guards `:if={tab[:count]}`). So **omitting a count is safe** (D-01 says count is optional). If a count IS wanted, add `entitlements: <count of resolved active plans>` to the `tab_counts/1` map — but that means calling the read seam in `tab_counts/1` AND in the render clause (two calls). **Recommend: omit the count** (simpler, one read-seam call, matches D-01's "or omit a count").
- The render clause should call the read seam once and assign, OR compute inline. The cleanest pattern matching this file's idiom (e.g. `subscriptions(@customer)` helper at `:424`) is a private helper `entitlements_view(@customer)` that returns `{resolved, unmapped}`, called in the render clause. Note this file computes several things inline in render (`tax_risk_summary/1`); a helper is consistent.

**Render contract for the clause (using existing components — NO new components):**
- **Active plans** — `MapSet.to_list(resolved.active_plans) |> Enum.sort()`. Render each as a `StatusBadge.status_badge` (tone defaults to `"moss"` for unknown atoms via `status_tone/1` fallback `"ink"` — pass an explicit `tone="moss"` or label). `StatusBadge` signature: `attr :status (required, :any)`, `attr :label (:string, default nil)`, `attr :tone (:string, default nil)` (`status_badge.ex:8-10`).
- **Granted features** — `MapSet.to_list(resolved.features) |> Enum.sort()`, rendered as list rows or badges.
- **Quantities/limits** — `resolved.quantities` is `%{quota_key => count}`; render as `KpiCard.kpi_card label=<key> value=<count>` or list rows. `KpiCard` signature: `attr :label (required), :value (required, :string), :delta, :delta_tone, :meta slot` (`kpi_card.ex:11-19`). Note `value` must be a **string** (`Integer.to_string/1`).
- **Grace state** — `resolved.grace_plans`, `resolved.grace_features`, `resolved.expired_grace_plans` (all MapSets). Show with an amber `StatusBadge` (the badge maps `:grace_period`/`:past_due` → `"amber"`, `status_badge.ex:34-36`). Only render the grace section if any are non-empty (avoid noise when `past_due_grace: :none`, the default).
- **Raw resolved map** — `JsonViewer.json_viewer id="customer-entitlements" label="Resolved entitlements" payload={resolved}`. `JsonViewer` normalizes MapSets? **NO — verify:** `normalize_payload/1` (`json_viewer.ex:146-164`) handles `%mod{}` structs as `%{"__struct__" => inspect(mod)}` and maps/lists/atoms, but a `MapSet` is a struct → it would render as `%{"__struct__" => "MapSet"}` losing contents. **Planner action:** convert MapSets to sorted lists BEFORE passing to JsonViewer, e.g. build a plain display map `%{active_plans: Enum.sort(MapSet.to_list(...)), ...}`.
- **Unmapped drift** — for each `price_id` in `unmapped`, render a list row with a "⚠ Unmapped plan" badge (`StatusBadge` with `tone="amber"` or `"ink"`, label from Copy). This is the D-03 "by eye" signal.
- **Empty state** — when `active_plans` is empty AND `unmapped` is empty: a Copy-backed "No entitlements resolved for this customer" line (mirror `customer_detail_no_subscriptions/0` at `copy.ex:430`).

### Pattern 3: `entitlements.md` guide skeleton (mirror `connect.md`)

**Peer guide shape (verified `connect.md`):** `# Title` → `## Getting Started` → topic `## sections` each with `### Example N` runnable snippets → `## Pitfalls` (`### Pitfall N`) → (implicit Related). `webhooks.md` is terser: `## Route and raw body` → `## Host handler boundary` → `## Signature failures` → `## Replay`.

**Recommended section order (D-06 Option A), one runnable snippet each:**
1. `# Entitlements — gate features on what they paid for`
2. Fail-closed easy path FIRST (PITFALLS #1):
   ```elixir
   if Accrue.entitled?(user, :pro), do: render_pro_dashboard(), else: upsell()
   ```
   State: the only path to `true` is an affirmative resolved match; `nil`/error/unmapped/exception all → `false`. (Source: `Accrue.Entitlements` moduledoc, `entitlements.ex:16-22`.)
3. `## Configure the catalog` — `plans` (features/limits/price_ids), `unmapped_action: :deny`, `past_due_grace`. (Source: `config.ex:355-436`.) Note the boot guard: a `price_id` may not map to two plans (`config.ex:933-963`).
4. `## Gate a controller route` — Plug guard `Accrue.Plug.RequireEntitlement` + the `require_feature/1` / `require_plan/1` router macros (`router.ex:79,93`), opaque-403 default + `on_deny`/`deny_path`. **This section must contain the literal `Accrue.Plug.RequireEntitlement` (needle D-14 #3).**
5. `## Gate a LiveView` — `Accrue.Live.Entitlements` `on_mount({:require_feature, feature}, ...)` / `({:require_plan, plan}, ...)` (`live/entitlements.ex:104,108`), conditionally compiled (core stays LiveView-runtime-free).
6. `## Lifecycle truth` — inline ONLY these ~5 rows (verbatim from `lifecycle_semantics.md:182-191`), then link:
   | Status / modifier | Entitled? |
   |---|:---:|
   | `:trialing` | ✅ |
   | `:active` | ✅ |
   | `:active` + `cancel_at_period_end` (paid-through) | ✅ |
   | `:paused` / `pause_collection` | ✗ |
   | `:past_due` | ✗ default / ✅ in-grace |
   | `:canceled` / ended | ✗ |
   Then: "Canonical source: [`lifecycle_semantics.md#lifecycle--entitlement-truth-table`](lifecycle_semantics.md#lifecycle--entitlement-truth-table) — `entitling?/1` is the SSOT." (Anchor VERIFIED to exist: heading `## Lifecycle → entitlement truth table` at `lifecycle_semantics.md:173`; `### entitling` glossary at `:162`.) Footnote-level grace nuance (`past_due_since`, `Accrue.Clock`, `:past_due_grace`/`:past_due_expired` reasons, `:unpaid` exclusion) stays ONLY in the SSOT.
7. `## Provider honesty` — prose only, NO table: "Entitlement resolution is `local-identical` across Stripe/Braintree/Fake — it reads local subscription state, never the processor." Link to the `entitlements.local_mapping` row in `.planning/processor-support-matrix.md` (row VERIFIED at `:59`, prose at `:65`) and `Accrue.Processor.Capabilities`. (Note: `.planning/` is internal; the public-doc link should point at the matrix's published location or `Processor.Capabilities` — planner to confirm whether `processor-support-matrix.md` is HexDocs-published; it appears `.planning`-only, so prefer linking `Accrue.Processor.Capabilities` for the public guide.)
8. `## Telemetry` — `[:accrue, :entitlements, :check]` start/stop/exception with metadata `%{feature, result, resolver, reason, surface, subject_type, subject_id}`; `subject_id` is internal id only, never PII; per-check is telemetry-only, never ledgered (`entitlements.ex:32-47`). **This section must contain the literal `[:accrue, :entitlements, :check]` (needle D-14 #4).**
9. `## Related guides` — links OUT to lifecycle_semantics.md, telemetry.md, auth_adapters.md, the admin guide (D-08 hub-and-spoke).
- **Must contain `entitled?`** somewhere (needle D-14 #2 — satisfied by section 2).
- **Length:** ≤ `connect.md` (~350 lines). One snippet per topic.
- **No mix.exs edit** — `accrue/mix.exs:134-135` globs `Path.wildcard("guides/*.md")` for BOTH `extras` and `groups_for_extras: [Guides: ...]` (VERIFIED). New guide auto-appears. Planner MAY (optional) add an explicit `groups_for_extras` grouping entry, but it's unnecessary.

### Pattern 4: Verifier fix + needles + seed-list co-update (D-13/D-14/D-15)

See the dedicated **Verifier State & Edit Plan** section below — this is the most edit-precise part of the phase.

### Anti-Patterns to Avoid
- **Re-deriving entitlement truth in the admin** — never query `.status` or rebuild the reverse-index in the LiveView. Always go through the read seam (PITFALLS #2).
- **Passing MapSets to `JsonViewer`** — they render as `%{"__struct__" => "MapSet"}`. Convert to sorted lists first.
- **Adding a public function to `Accrue.Entitlements`** — that's the deferred `fetch_entitled/2` trap (D-07). Use the internal `Accrue.Entitlements.Admin` module instead.
- **Pinning a doc needle for a link that doesn't exist** (D-14 #6) — only pin the quickstart/first_hour pointer IF you actually add it.
- **Forgetting to seed a new fixture** — any file a needle references must be in `seed_tmp_dir!` or the negative fixtures fail "No such file" (D-15).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Resolve a customer's entitlements | A new fold in the admin | Reuse `LocalMap.fold_active/1` via the `@doc false` delegation | Drift between two folds is the #1 SSOT hazard (PITFALLS #2). |
| Build the price_id→plan reverse-index | A fresh `Enum.reduce` in admin | `LocalMap.catalog/0` (via the seam) | The boot guard + reverse-index logic already exist and are tested. |
| Fetch entitling subs | A raw `where status in [...]` query | `Billing.Query.entitling/1` (composed in the seam) | It closes the paused/ended fail-open gaps; raw `.status` misses them (`query.ex:34-59`). |
| Render plans/features/quantities/grace | New components | `KpiCard`, `StatusBadge`, `JsonViewer`, list rows | All exist with the right signatures (CONTEXT D-02). |
| Operator strings | Hardcoded template strings | `AccrueAdmin.Copy.Entitlements` + defdelegate + allowlist | VERIFY-01 anti-drift (D-05). |
| Lifecycle truth table | Re-derive a full table in the guide | Inline ~5 rows + link to the SSOT | Reciprocal drift; the SSOT is `entitling?/1` (D-07). |

**Key insight:** This phase's entire risk surface is *drift* — two copies of the fold, two truth tables, a needle that references an unseeded file. Every "don't hand-roll" here is a drift-prevention measure.

## Runtime State Inventory

This is **not** a rename/refactor/migration phase (it's an additive admin tab + docs). Per the protocol, stating each category explicitly:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — no DB writes, no schema change, no new columns. The read seam is read-only. | None — verified: no migration, no `accrue_events` write (CONTEXT code_context). |
| Live service config | None — no external service config touched. | None. |
| OS-registered state | None. | None. |
| Secrets/env vars | None — no new config keys (the `:entitlements` schema is unchanged from Phase 123-125). | None. |
| Build artifacts | The new `accrue/guides/entitlements.md` auto-globs into the next `mix docs` build; no stale artifacts (no package rename, no egg-info equivalent in Elixir). | Run `mix docs` once at phase end to confirm the new guide builds (part of the D-15 gate). |

**The canonical question — "after every file is updated, what runtime systems still have stale state?":** None. This phase adds a read-only display surface and documentation; there is no cached/registered/stored runtime state to migrate.

## Common Pitfalls

### Pitfall 1: The factory's default `price_basic` is UNMAPPED — both a hazard and a gift
**What goes wrong:** `Accrue.Test.Factory` defaults to `@default_price "price_basic"` (`factory.ex:46`). The existing `customer_live_test.exs` setup uses `Billing.subscribe(customer, "price_basic")`. If the test config's `:entitlements` `plans` don't include `"price_basic"`, that sub is **unmapped** → it never appears in `active_plans` but DOES appear in the unmapped-drift list.
**Why it happens:** The resolver silently drops unmapped price_ids (`local_map.ex:244`).
**How to use it (gift):** This makes the **unmapped-badge test trivial** — a default-factory sub IS an unmapped sub. For the "resolved features render" test, set `:entitlements` app env with a plan mapping `"price_basic"` (or a custom price) to features, exactly like `local_map_test.exs:28-38` does (`Application.put_env(:accrue, :entitlements, ...)` with `on_exit` restore, `async: false`).
**Warning signs:** If the resolved-features test shows empty `active_plans`, the price_id isn't in the test's `:entitlements` config.

### Pitfall 2: `JsonViewer` mangles MapSets
**What goes wrong:** Passing the raw resolved map (with `MapSet` values) to `JsonViewer.json_viewer` renders `%{"__struct__" => "MapSet"}` — contents lost (`json_viewer.ex:152-154`).
**How to avoid:** Build a plain display map first: `%{active_plans: resolved.active_plans |> MapSet.to_list() |> Enum.sort(), features: ..., quantities: resolved.quantities, ...}`.
**Warning signs:** The JSON tree shows `__struct__: MapSet` instead of the plan/feature lists.

### Pitfall 3: Uncommitted on-disk edits and an untracked new file (D-12 flag, confirmed)
**What goes wrong:** The planner must edit current **on-disk** state, not git HEAD. `git status` confirms:
- `accrue/README.md` — **M** (uncommitted local edits)
- `accrue/guides/quickstart.md` — **M**
- `accrue/guides/maturity-and-maintenance.md` — **M**
- `accrue/guides/jobs_to_be_done.md` — **untracked (??)** — `git ls-files` errors: "did not match any file" → this file is NEW, never committed.
**Implications:**
1. The JTBD flip targets (lines 116/156/318/339/350/354) are valid against the **on-disk** file (I read it directly). The planner should re-read on-disk before editing, since line numbers may shift if other edits land first.
2. Because `jobs_to_be_done.md` is untracked, the verifier-test `copy_fixture!` uses `File.cp!` from the working tree (not git) — so the on-disk file IS what gets seeded (D-15 works regardless of git tracking). But CI that does a clean checkout would NOT have an untracked file → **the planner must ensure `jobs_to_be_done.md` is committed in this phase's PR**, or the new needle + seed fixture reference a file CI can't see.
**How to avoid:** Read all four files fresh on-disk at plan time; commit `jobs_to_be_done.md` as part of this phase.

### Pitfall 4: The `require_absent_regex` flip-guard is defeated by the historical Update log
**What goes wrong:** D-14 #5 wants a `require_absent_regex` proving the old gap wording is gone. But "headline gap" appears at `jobs_to_be_done.md:354` (Update log) AND "on the table" at `:339` (scope prose). VERIFIED both exist. A naive `require_absent_regex ... 'headline gap'` would still fail after the flip because the historical log line legitimately records the prior state.
**How to avoid (two options, planner picks):**
- (a) **Reword the historical log reference** when appending the new Update log entry (e.g. change line 354 to "entitlements flagged as the then-current gap" or fold it into the new dated entry). Then `require_absent_regex 'headline gap'` works globally.
- (b) **Scope the guard pattern** to the body/scope section only — but `grep -E` is line-based, not section-scoped, so this is hard in pure bash. Prefer (a): pick a distinctive flip-marker that the body MUST drop (e.g. the exact phrase "still **on the table** is **entitlements**" at `:339`) and pin its absence: `require_absent_regex jobs_to_be_done.md 'on the table\*\* is \*\*entitlements'`. That phrase is unique to the scope prose and won't collide with the Update log. **Recommend (b) with the precise scope-prose phrase**, plus rewording line 354 in the same edit for cleanliness.

### Pitfall 5: Adding `"entitlements"` to `@tabs` without a `tab_counts` key
**What goes wrong:** `tabs/4` (`:419`) does `Map.get(counts, String.to_existing_atom(tab))`. `String.to_existing_atom("entitlements")` requires the atom `:entitlements` to already exist — it DOES (it's a config key and used throughout), so no `ArgumentError`. `Map.get` returns `nil` for a missing key → no count badge. **Safe.** But if the planner adds `entitlements: ...` to `tab_counts/1`, it must also handle the `refresh_customer_detail/1` path (`:514`) which rebuilds `tab_counts`.
**How to avoid:** Omit the count (D-01 allows it). If counting, add the key in BOTH `tab_counts/1` and ensure `refresh_customer_detail` recomputes — though entitlements has no write actions, so refresh isn't triggered by this tab.

## Code Examples

### Reading entitling subs the way the resolver does (for the unmapped-drift seam)
```elixir
# Source: accrue/lib/accrue/entitlements/resolver/local_map.ex:164-172 (none_lane_items/1)
import Ecto.Query
alias Accrue.Billing.{Subscription, SubscriptionItem, Query}

Subscription
|> Query.entitling()                      # active/trialing, not paused, not ended
|> where([s], s.customer_id == ^customer_id)
|> join(:inner, [s], i in SubscriptionItem, on: i.subscription_id == s.id)
|> select([_s, i], {i.price_id, i.quantity})
|> Accrue.Repo.all()
# The recommended seam REUSES active_items/1 instead of re-writing this — shown
# only to document the exact query the resolver runs.
```

### Test scaffolding for the entitlements tab (clone of customer_live_test.exs + local_map_test.exs)
```elixir
# Source: composed from customer_live_test.exs:36-49 + local_map_test.exs:28-49
use AccrueAdmin.LiveCase, async: false   # async: false REQUIRED — mutates app env

setup do
  prev = Application.get_env(:accrue, :entitlements)
  Application.put_env(:accrue, :entitlements,
    plans: [pro: [features: [:reports], limits: [seats: 5], price_ids: ["price_pro"]]],
    unmapped_action: :deny)
  on_exit(fn ->
    if prev, do: Application.put_env(:accrue, :entitlements, prev),
             else: Application.delete_env(:accrue, :entitlements)
  end)

  Application.put_env(:accrue, :auth_adapter, AuthAdapter)  # see customer_live_test.exs:16-34
  %{customer: customer} = Factory.customer(%{email: "ent@example.com"})
  {:ok, sub} = Billing.subscribe(customer, "price_pro")
  {:ok, _} = Fake.transition(sub.processor_id, :active, synthesize_webhooks: false)
  {:ok, customer: customer}
end

test "entitlements tab renders resolved features", %{conn: conn, customer: customer} do
  conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
  assert {:ok, _v, html} = live(conn, "/billing/customers/#{customer.id}?tab=entitlements")
  assert html =~ "reports"   # granted feature
end
# For the unmapped-badge test: subscribe to "price_basic" (factory default, NOT mapped)
# → it appears in the unmapped list with the "⚠ Unmapped plan" badge.
# For the empty test: a bare Factory.customer with no subscription.
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Entitlements = "headline gap" / "on the table" | Core entitlements ✅ shipped (123-125); admin + docs ship in 126 | This phase | JTBD flips ⛔→✅; "5 of 6" → "6 of 6" |
| Verifier RED on `main` | Verifier GREEN (PROJECT.md gains the phrase) | This phase (D-13) | 6 failing Elixir tests auto-green |

**Deprecated/outdated:** Nothing deprecated. This phase only adds.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `processor-support-matrix.md` is `.planning`-only (not HexDocs-published), so the public guide should link `Accrue.Processor.Capabilities` rather than the matrix path. | Pattern 3 §7 | LOW — if the matrix IS published, linking it is also fine; planner confirms the published location. The grep showed it only under `.planning/`, supporting the assumption. |
| A2 | Hard-coding `LocalMap` (not the configured resolver) in `Accrue.Entitlements.Admin` is acceptable for the read-only diagnostic. | Pattern 1 | LOW — a host running a custom resolver would see default-resolver output in admin; acceptable for ENT-11's read-only scope. Documented as a moduledoc limitation. |
| A3 | The Plug guard section's literal `Accrue.Plug.RequireEntitlement` and telemetry `[:accrue, :entitlements, :check]` are sufficient as the only needles for those anchors. | Pattern 4 / D-14 | LOW — these are exact strings VERIFIED in source; needles are `grep -F`/`-E` against them. |

## Open Questions

1. **Should the entitlements tab show a count badge?**
   - What we know: D-01 says optional; `tabs/4` safely renders no badge when the count key is absent.
   - Recommendation: **Omit** (one read-seam call, simpler). If a count is desired later, it's `MapSet.size(resolved.active_plans)`.

2. **Public link target for the provider matrix.**
   - What we know: the `entitlements.local_mapping` row lives in `.planning/processor-support-matrix.md` (internal). `Accrue.Processor.Capabilities` is a public module.
   - Recommendation: link `Accrue.Processor.Capabilities` in the public guide (assumption A1); keep the `.planning` matrix as an internal reference only.

3. **`first_hour.md` optional cross-link.**
   - What we know: D-12 says leave the pinned spine intact; an optional non-structural "Next: gate features → Entitlements" cross-link is allowed.
   - Recommendation: add the cross-link ONLY if it's a plain prose line (no new structural needle), and ONLY pin a needle for it if added (D-14 #6). Default: skip it to minimize churn in the most heavily-gated file.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix` / Elixir 1.17+ | Build, test, `mix docs` | ✓ (project toolchain) | per `.tool-versions` | — |
| `bash` | `verify_package_docs.sh` | ✓ | system | — |
| PostgreSQL (test) | LiveView tests via Ecto Sandbox | ✓ (assumed — full suite runs today) | 14+ | — |

No external runtime tools (no Chrome/Ghostscript — PDF path untouched). **No blocking missing dependencies.**

## Validation Architecture

> `workflow.nyquist_validation = true` (confirmed in `.planning/config.json`). Section included.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.17), `AccrueAdmin.LiveCase` for LiveView (`test/support/live_case.ex`) |
| Config file | `accrue_admin/test/test_helper.exs` + `accrue/test/test_helper.exs` (existing) |
| Quick run command | `cd accrue_admin && mix test test/accrue_admin/live/entitlements_live_test.exs` (new file) |
| Full suite command | `cd accrue && mix test` + `cd accrue_admin && mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ENT-11 | Tab renders resolved features for a mapped sub | LiveView | `cd accrue_admin && mix test test/accrue_admin/live/entitlements_live_test.exs -x` | ❌ Wave 0 (new) |
| ENT-11 | Tab badges an unmapped sub ("⚠ Unmapped plan") | LiveView | same file, distinct test | ❌ Wave 0 |
| ENT-11 | Empty state (no subscription) renders Copy line | LiveView | same file, distinct test | ❌ Wave 0 |
| ENT-11 | Read seam `Accrue.Entitlements.Admin.resolve_for_customer/1` returns `{resolved, unmapped}` | unit | `cd accrue && mix test test/accrue/entitlements/admin_test.exs -x` | ❌ Wave 0 (new) |
| ENT-12 | `entitlements.md` builds in HexDocs | smoke | `cd accrue && mix docs` (exit 0, no new actionable warnings) | n/a (build) |
| ENT-12 | Verifier green end-to-end (8/0) | integration | `bash scripts/ci/verify_package_docs.sh` (exit 0) + `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` (8 tests, 0 failures) | ✅ exists (currently 6 failing — see below) |
| ENT-12 | JTBD flip-guard regex (old gap wording absent) | integration | covered by the verifier run (the new `require_absent_regex` needle) | ✅ via verifier |

### Sampling Rate
- **Per task commit:** the relevant quick command (the new LiveView file, or the verifier `bash` run for doc tasks).
- **Per wave merge:** `cd accrue && mix test` + `cd accrue_admin && mix test`.
- **Phase gate (D-15, all three must pass):**
  1. `bash scripts/ci/verify_package_docs.sh` → exit 0
  2. `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` → 8 tests, 0 failures
  3. `cd accrue && mix docs` → builds, new `entitlements.html` present.

### Wave 0 Gaps
- [ ] `accrue_admin/test/accrue_admin/live/entitlements_live_test.exs` — covers ENT-11 (3 render states). Clone `customer_live_test.exs` structure + `local_map_test.exs` config setup.
- [ ] `accrue/test/accrue/entitlements/admin_test.exs` — covers the read seam `resolve_for_customer/1` (mapped, unmapped, empty, grace).
- [ ] No new framework install needed — ExUnit + LiveCase + Factory all exist.
- [ ] Baseline caveat (from project memory): the full `accrue` `mix test` baseline has 6 PRE-EXISTING `PackageDocsVerifier` failures (this exact verifier RED state) + a flaky `PdfTest`. The 6 verifier failures are EXPECTED to GREEN via D-13 — that is the validation signal, not a regression. Do not re-triage them as new.

## Verifier State & Edit Plan (D-13 / D-14 / D-15 — the edit-precise core)

### Confirmed-RED state (I ran the verifier)
```
$ bash scripts/ci/verify_package_docs.sh
[verify_package_docs] package docs verification failed:
  /Users/jon/projects/accrue/.planning/PROJECT.md is missing: gateway subscription core
EXIT CODE: 1
```
- The failing assertion is `verify_package_docs.sh:220`: `require_fixed "$ROOT_DIR/.planning/PROJECT.md" "gateway subscription core"`.
- `grep -n "gateway subscription core" .planning/PROJECT.md` → **empty** (confirmed holdout).
- The phrase IS already pinned/present in: `accrue/README.md:105`, `.planning/STRATEGY.md:207`, `accrue/guides/testing.md:129`, `examples/accrue_host/README.md:189`, plus `.planning/processor-support-matrix.md`. PROJECT.md is the lone holdout — D-13's "restore parity" is accurate.

### D-13 — PROJECT.md edit (exact)
Insert the literal phrase `gateway subscription core` into the **Current posture / PROC-08** prose at `PROJECT.md:37`:
> Current line 37: "The active strategy remains **PROC-08**: a bounded dual-provider core centered on **Stripe-first** defaults plus one Stripe-like gateway. ..."

Reword to naturally include the phrase, e.g.: "...a bounded dual-provider **gateway subscription core** centered on **Stripe-first** defaults plus one Stripe-like gateway." This stays true to the bounded dual-provider scope and is a `grep -F` match. (Note `PROJECT.md:222` already pins `Accrue.Billing.subscribe/3`, `Braintree`, `Fake`, `Stripe-first` — the phrase fits the same posture block.)

### D-14 — new needles to ADD to `verify_package_docs.sh` (verbatim strings)
Add these `require_*` lines (place near the existing README/guide pins, after `:109`/before `:110`, or in a logical entitlements block):
```bash
# Entitlements spine (Phase 126, ENT-12)
require_fixed "$ROOT_DIR/accrue/README.md" '[Entitlements](guides/entitlements.md)'      # needle 1 — adjust to the exact link text used in README "Start here"
require_fixed "$ROOT_DIR/accrue/guides/entitlements.md" 'entitled?'                        # needle 2
require_fixed "$ROOT_DIR/accrue/guides/entitlements.md" 'Accrue.Plug.RequireEntitlement'   # needle 3
require_fixed "$ROOT_DIR/accrue/guides/entitlements.md" '[:accrue, :entitlements, :check]'  # needle 4
require_fixed "$ROOT_DIR/accrue/guides/jobs_to_be_done.md" 'entitlements'                   # needle 5a — positive shipped marker (use a more specific shipped phrase, see below)
require_absent_regex "$ROOT_DIR/accrue/guides/jobs_to_be_done.md" 'on the table\*\* is \*\*entitlements'  # needle 5b — flip-guard (Pitfall 4)
```
**Needle precision notes:**
- Needle 1: the exact string MUST match the README "Start here" bullet you write. Choose a stable markdown link, e.g. `[Entitlements](guides/entitlements.md)`, and pin THAT exact text. (`grep -F` is literal — including brackets/parens.)
- Needle 5a: `'entitlements'` is too loose (appears many times). Use a precise SHIPPED marker the new body section introduces, e.g. the section heading `## Gate access on what they paid for` is not great either. **Recommend** pinning a distinctive shipped-state phrase you author in the scope-row flip, e.g. `require_fixed jobs_to_be_done.md 'entitlements ✅'` or the new scope-table cell text. Pick something that ONLY exists in the post-flip body.
- Needle 5b: the flip-guard. Per Pitfall 4, the precise scope-prose phrase `on the table** is **entitlements` is unique to line 339 and won't collide with the Update log's "headline gap" at line 354. ALSO reword line 354 in the same edit to remove "headline gap" as a belt-and-suspenders measure, so a future broader guard can't be tripped.
- **Do NOT pin** (D-14 explicit): deny-redirect prose, quota numbers, per-provider matrix wording, or gate-fn names already replicated across README+first_hour+host.
- Needle 6 (quickstart/first_hour pointer): pin ONLY if you add the pointer. If you add a quickstart focused-guides bullet `[Entitlements](entitlements.md)`, pin it: `require_fixed "$ROOT_DIR/accrue/guides/quickstart.md" '[Entitlements](entitlements.md)'`.

### D-15 — `package_docs_verifier_test.exs` seed-list co-update (exact)
In `seed_tmp_dir!/1` (`package_docs_verifier_test.exs:247-275`), add to the `copy_fixture!` calls (after `:265` `accrue/guides/testing.md`, alongside the other `accrue/guides/*` copies):
```elixir
copy_fixture!("accrue/guides/entitlements.md", tmp_dir)       # NEW guide referenced by needles 2/3/4
copy_fixture!("accrue/guides/jobs_to_be_done.md", tmp_dir)    # referenced by needles 5a/5b; NOT currently seeded (verified :254-274)
```
**Why both:** any file a needle references must exist in the seeded tmp dir or the NEGATIVE-drift fixture tests (which call `seed_tmp_dir!` then mutate one file) will fail with "No such file" when the verifier hits the new `require_fixed`/`require_absent_regex` against an absent file. `jobs_to_be_done.md` is currently NOT in the seed list (confirmed — it's not among the 21 `copy_fixture!` calls at `:254-274`) and is also UNTRACKED in git (commit it this phase, Pitfall 3).

**Note:** `.planning/PROJECT.md` IS already seeded (`:258`), so the D-13 fix auto-greens the 6 failing negative-fixture tests without a seed change — each currently short-circuits on the missing phrase before reaching its intended mutation.

### Green proof (the D-15 gate, run all three)
```bash
bash scripts/ci/verify_package_docs.sh                                  # expect: exit 0
cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs   # expect: 8 tests, 0 failures
cd accrue && mix docs                                                   # expect: builds; guides/entitlements.html present
```

## Security Domain

> `security_enforcement` absent in config → treat as enabled. This is a read-only admin display + docs phase; the applicable controls are narrow.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes (inherited) | The entitlements tab inherits CustomerLive's `AuthHook` on_mount + `owner_scope` (`customer_live.ex:34-61`, `live_case.ex` AuthAdapter). No new auth surface. |
| V3 Session Management | no | No new sessions. |
| V4 Access Control | yes (inherited) | `Customers.detail/2` enforces owner-scope (`customer_live.ex:37`); out-of-scope customers redirect before render (tested `customer_live_test.exs:197-230`). The entitlements tab is gated by the SAME mount path — no new access surface. |
| V5 Input Validation | minimal | Only the `tab` query param; `normalize_tab/1` (`:670`) allowlists against `@tabs`, defaulting to `"subscriptions"`. Adding `"entitlements"` to `@tabs` is the only validation change. |
| V6 Cryptography | no | None. |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| PII leak in the resolved-map display | Information Disclosure | The resolved map contains only plan atoms, feature atoms, and integer quantities — NO customer PII. `subject_id` PII concern (entitlements.ex:36-39) is telemetry-only and not rendered. Confirm the JsonViewer payload excludes any customer email/name (it shows `resolved`, not `customer`). |
| Cross-tenant entitlement view | Elevation / Info Disclosure | Inherited owner-scope gating; no new route, no new query that bypasses `Customers.detail/2`. The read seam queries by `customer.id` which is already owner-validated at mount. |
| Drift signal misread as enforcement | (operational) | The "⚠ Unmapped plan" badge is informational ONLY (read-only). Copy must make clear it's a visibility signal, not an action. |

## Sources

### Primary (HIGH confidence — read directly with line numbers)
- `accrue/lib/accrue/entitlements/resolver/local_map.ex` — fold, catalog, active_items, handle_unmapped, resolved-map shape (lines cited inline).
- `accrue/lib/accrue/entitlements.ex` — public gate API + telemetry span (do-not-extend surface).
- `accrue/lib/accrue/billing/query.ex` — `entitling/1` (queryable, not customer_id).
- `accrue/lib/accrue/config.ex` — `entitlements/0`, `past_due_grace/0`, `:entitlements` schema, price_id boot guard.
- `accrue/lib/accrue/billing/customer.ex` / `subscription_item.ex` — `%Customer{}` + `price_id`/`quantity` fields.
- `accrue_admin/lib/accrue_admin/live/customer_live.ex` — clone target (@tabs:31, case:223, tab_counts:387, tabs:410).
- `accrue_admin/lib/accrue_admin/copy.ex` + `copy/customer_payment_methods.ex` + `mix/tasks/accrue_admin.export_copy_strings.ex` — Copy/VERIFY-01 pattern.
- `accrue_admin/lib/accrue_admin/components/{kpi_card,status_badge,tabs,json_viewer}.ex` — component signatures.
- `accrue_admin/test/accrue_admin/live/customer_live_test.exs` + `test/support/live_case.ex` + `accrue/lib/accrue/test/factory.ex` — test idiom.
- `accrue/test/accrue/entitlements/local_map_test.exs` — resolved-map shape + config-mutation setup.
- `scripts/ci/verify_package_docs.sh` (read in full) + `accrue/test/accrue/docs/package_docs_verifier_test.exs` (seed list) — verifier + co-update.
- `accrue/guides/{lifecycle_semantics,jobs_to_be_done,connect,webhooks}.md` + `accrue/README.md` + `accrue/guides/quickstart.md` — anchors, flip targets, peer shapes, spine.
- `.planning/{PROJECT.md,research/JTBD-FRONTIER.md,processor-support-matrix.md}` — needle holdout, internal flip, matrix row.
- `accrue/lib/accrue/plug/require_entitlement.ex` + `accrue/lib/accrue/live/entitlements.ex` + `accrue/lib/accrue/router.ex` — guard module names for guide needles.
- **Verifier run:** `bash scripts/ci/verify_package_docs.sh` → exit 1, confirming RED.
- **git status / git ls-files** — confirmed uncommitted README/quickstart/maturity + untracked jobs_to_be_done.md.
- `.planning/config.json` — `nyquist_validation: true`.

### Secondary (MEDIUM) / Tertiary (LOW)
- None needed — this is an internal-codebase phase; no external library research was required (no new packages, no version lookups). CONTEXT.md's prior 4-advisor research already covered the cross-lib lessons (Stripe Dashboard, Cashier, LaunchDarkly) and is incorporated by reference in D-02/D-03.

## Metadata

**Confidence breakdown:**
- Read seam (D-04 shape): HIGH — every private fn, the resolved-map shape, and the silent-drop are confirmed at exact lines; the recommended module is the minimal additive choice satisfying all 3 hard constraints.
- Admin tab clone: HIGH — clone target read in full; component signatures verified; the `tab_counts`/`String.to_existing_atom` gotcha checked.
- Guide skeleton: HIGH — peer shapes + the truth-table anchor + matrix row all verified verbatim.
- Verifier fix + needles + seed list: HIGH — verifier RUN (confirmed RED), holdout grep'd, seed list line-checked, flip-guard collision confirmed at line 354.
- JTBD flip targets: HIGH — both files read; exact line refs for every flip point (public 116/156/318/339/350/354; internal 21/85/110/151/162).

**Research date:** 2026-05-23
**Valid until:** ~2026-06-22 (stable internal codebase; only invalidated if phases 123-125 SSOTs or the verifier script change before planning).

## RESEARCH COMPLETE
