# Phase 126: Admin Surface + Docs / JTBD Spine - Context

**Gathered:** 2026-05-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the now-shipped entitlements feature (phases 123–125) **visible to operators and
documented end-to-end** — with **no new core gate behavior**. Covers **ENT-11** (read-only
admin entitlements view surfacing unmapped-plan drift) and **ENT-12** (`guides/entitlements.md`
+ JTBD ⛔→✅ flip + First Hour/README "Start here" spine + green package-doc verifiers).

**In scope:**
- A **read-only entitlements TAB** on the existing `accrue_admin` customer detail LiveView,
  rendering a customer's resolved active plans / granted features / quantities / grace state,
  and **surfacing unmapped-plan drift "by eye"** (active subscriptions whose `price_id` has no
  plan mapping — which the resolver silently drops).
- A new public guide **`accrue/guides/entitlements.md`** documenting the full story (gate API,
  Plug guard, LiveView guard, provider matrix, lifecycle truth table) — fail-closed-first,
  summarize-and-link to the SSOTs (never re-derive truth).
- The **JTBD ⛔→✅ flip** in `accrue/guides/jobs_to_be_done.md` (public) **and** the internal
  `.planning/research/JTBD-FRONTIER.md`, per the established JTBD re-run convention.
- The **"Start here" spine wiring**: README + quickstart pointers to the entitlements guide
  (a "next, when you need to gate" pointer, NOT a new day-1 install step).
- **Green package-doc verifiers**: fold in the pre-existing `gateway subscription core` needle
  fix (PROJECT.md), add a tight set of new entitlements-spine needles, and update the Elixir
  verifier-test fixture seed list.

**Out of scope (later phase — do not build here):** the **optional Stripe-native webhook→cache
sync** + `grant`/`revoke` + ledger writes + a `native` entitlements capability row (Phase 127,
ENT-10, off by default). **No new public `Accrue.*` gate/diagnostic API** (Phase 123 D-07's
`fetch_entitled/2` stays deferred). **No change to the gate decision logic, resolver truth,
lifecycle truth table, or provider matrix** — those are SSOTs this phase *surfaces and
documents*, not redefines. Atomic seat *enforcement* stays host-owned (documented recipe).
</domain>

<decisions>
## Implementation Decisions

> Ran in **cohesive-synthesis mode** (standing user preference, config-enforced via
> `discuss_auto_all_gray_areas` + `discuss_high_impact_confirm` + `discuss_auto_resolve_low_impact`,
> bar = `discuss_high_impact_confirm_bar`). **Four parallel `gsd-advisor-researcher` agents**
> researched each gray area (one per success criterion): idiomatic Phoenix LiveView / ExDoc-guide
> patterns, cross-lib lessons (Stripe Dashboard Entitlements, Laravel Cashier, Pay, LaunchDarkly/
> Unleash, Bodyguard/Pundit), and the in-repo precedents. All decisions below are research-backed,
> mutually coherent, and grounded against the live code (resolver signature, verifier script,
> guide anchors). **ZERO open forks** — every decision is additive/reversible, mandated by
> ENT-11/ENT-12 wording, or a coherent doc reconciliation; none crosses the confirm bar (consistent
> with phases 123–125).

### A — Admin entitlements view: placement & shape (ENT-11, SC#1)

- **D-01 — Add an "entitlements" TAB to the existing `AccrueAdmin.Live.CustomerLive` detail view**
  (`/customers/:id?tab=entitlements`). Do NOT build a dedicated nested route
  (`/customers/:id/entitlements`) or a standalone `/entitlements` index. *Rationale:* entitlements
  are inherently **per-customer** (no standalone identity / no `id`); CustomerLive is already the
  read-only **tabbed** detail view (subscriptions / invoices / charges / payment_methods / events /
  metadata), so a new tab reuses the entire mount / `owner_scope` / `AuthHook` / breadcrumb spine
  for free and lands the feature exactly where operators already look — matching how Stripe's
  Dashboard nests an Entitlements section inside the customer record. Lowest-ceremony, consistent,
  reversible (delete one `case @tab` clause). Add `"entitlements"` to the `@tabs` allowlist
  (`customer_live.ex:31`) and a render clause in the `case @tab` block (`:223`). The tab count in
  `tab_counts/1` (`:387`) is optional for this tab (count of resolved active plans, or omit a count).

### B — Admin view: what to render + how to surface drift (ENT-11, SC#1)

- **D-02 — Render resolved state first, then the drift signal.** Show (via existing components —
  `KpiCard`, `StatusBadge`, list rows, `JsonViewer` for the raw resolved map): **active plans**,
  **granted features**, **quantities/limits**, and **grace state** (`grace_plans`, `grace_features`,
  `expired_grace_plans` from the resolved map). Borrow LaunchDarkly's "evaluation reason on the
  per-subject detail page" idea: answer first, then *why*.
- **D-03 — Surface unmapped-plan drift by listing the customer's entitling subscriptions and
  badging any whose `price_id` is NOT in the plan reverse-index with a "⚠ Unmapped plan" badge.**
  This is the ONLY way to make drift visible "by eye": the resolver **silently drops** unmapped
  active items (`LocalMap.handle_unmapped/3` under the default `:deny` returns the accumulator
  unchanged — verified `local_map.ex:244`), so the resolved map can *structurally never* show them.
  Reject surfacing via telemetry `reason: :unmapped_plan` (fire-and-forget, not queryable from a
  mount) and reject a full config-vs-active diff table (information overload defeats "by eye"; the
  one urgent cell is "active price_id with no plan").

### C — Admin view: data path (ENT-11, SC#1) — the one load-bearing technical decision

- **D-04 — Reuse the resolver's SSOT fold; do NOT re-implement it in admin; do NOT add a public
  `Accrue.*` gate/diagnostic API.** Grounding fact: `LocalMap.resolve/2` takes a **billable** (a
  host struct implementing `__accrue__/1`) and looks the `%Customer{}` up *backwards* via
  `(owner_type, owner_id)` — but admin already **holds** a `%Customer{}`, and `fold_active/1`,
  `catalog/0` (the `price_id → plan` reverse-index), and `active_items/1` (entitling subs by
  `customer_id`) are all **private** to `LocalMap` (verified `local_map.ex:69,96,150,253`). So the
  admin needs a **minimal additive read seam** that (a) accepts a `%Customer{}` and reuses the
  resolver's fold for the resolved map, and (b) surfaces the **unmapped entitling `price_id`s** —
  the one thing the resolver structurally discards. **Researcher/planner picks the exact shape**
  (candidates: a `LocalMap.resolve_for_customer/2` arity that skips `lookup_customer/1` + a sibling
  that returns the unmapped price_ids; OR a single `Accrue.Entitlements` diagnostic returning
  `{resolved_map, unmapped_price_ids}`). **Hard constraints on the choice:** must NOT drift from
  `LocalMap`'s fold (reuse, don't copy — PITFALLS #2 / SSOT discipline); must NOT add a public
  boolean `Accrue.fetch_entitled/2`-style gate API (Phase 123 D-07 stays deferred); must respect
  the one-way dependency (admin/entitlements → billing, never reverse). Reading
  `Accrue.Config.entitlements/0` for the reverse-index and `Billing.Query.entitling/1` for entitling
  subs is the in-repo idiom either way. *This is additive/reversible — auto-resolves, no fork.*
- **D-05 — Copy/VERIFY-01 discipline:** all operator-facing strings go in a new
  `AccrueAdmin.Copy.Entitlements` submodule, registered via `defdelegate` in `AccrueAdmin.Copy`
  and added to the `mix accrue_admin.export_copy_strings` allowlist — never hardcoded in the
  template. Test the tab with `AccrueAdmin.LiveCase` + `Factory` + `Fake.transition` (clone
  `customer_live_test.exs`), covering: resolved features render, an unmapped-sub badge appears, and
  the empty/no-entitlements state.

### D — `guides/entitlements.md`: structure, depth, SSOT-linking (ENT-12, SC#2)

- **D-06 — Single authoritative narrative guide, fail-closed-first, summarize-and-link to SSOTs.**
  Section order (Option A from research): **gate API + fail-closed contract → config (`plans`,
  `price_ids`, `unmapped_action: :deny`, `past_due_grace`) → Plug guard (`require_feature`/
  `require_plan` + opaque-403 default + `on_deny`) → LiveView guard (`on_mount`) → lifecycle truth
  (trimmed inline table + link to SSOT) → provider matrix (one-sentence prose + link) → telemetry →
  Related guides.** Mirrors `connect.md`'s peer shape; puts `Accrue.entitled?/2` returning `false`
  on any ambiguity at line one (PITFALLS #1). Ships in HexDocs automatically — guides are
  auto-globbed via `Path.wildcard("guides/*.md")` (no `mix.exs` edit required; planner MAY add a
  `groups_for_extras` grouping entry).
- **D-07 — Inline-vs-link policy (no drift):** for the **lifecycle truth table**, inline only the
  ~4–5 reader-critical rows (trialing/active ✅, paused/canceled ✗, the `past_due` ✗-default /
  ✅-in-grace knob row) then defer: "Canonical source:
  `lifecycle_semantics.md#lifecycle--entitlement-truth-table` — `entitling?/1` is the SSOT"
  (anchor verified to exist). Footnote-level grace nuance (`past_due_since`, `Accrue.Clock`,
  `:past_due_grace`/`:past_due_expired` reasons, `:unpaid` exclusion) lives **only** in the SSOT.
  For the **provider matrix**, do NOT inline a table — state the one load-bearing fact in prose
  ("entitlement resolution is `local-identical` across Stripe/Braintree/Fake — reads local
  subscription state, never the processor") and link to the `entitlements.local_mapping` row in
  `.planning/processor-support-matrix.md` + `Accrue.Processor.Capabilities`.
- **D-08 — Hub-and-spoke cross-linking (truth flows one direction).** entitlements.md links **out**
  to lifecycle_semantics.md (truth SSOT), the processor matrix + `Processor.Capabilities` (provider
  SSOT), telemetry.md (the span), auth_adapters.md (`billable:` / `Accrue.Auth` boundary). Inbound
  links come **to** it from jobs_to_be_done.md, quickstart.md, and a one-line First Hour pointer.
  SSOTs do NOT link back to entitlements.md for *truth* (avoids reciprocal drift). Keep depth tight
  and example-forward (≤ ~connect.md length; one runnable snippet per topic).

### E — JTBD ⛔→✅ flip + "Start here" spine (ENT-12, SC#3)

- **D-09 — New body-tour section + Scope flip; spine as a "next, when you need to gate" pointer
  (Option B), NOT a new day-1 onboarding step.** In `jobs_to_be_done.md`: add a
  `## Gate access on what they paid for` section **between `## The customer changes their mind`
  (`:116`) and `## When payments fail` (`:156`)** — the natural slot (subscribe → change/cancel →
  **gate** → recover), matching Cashier's "Checking Subscription Status" placement *after*
  subscription setup. Flip the Scope-and-maturity prose (`:339` "The most useful thing still **on
  the table** is **entitlements**…") and the scope row ⛔→✅.
- **D-10 — Honest phrasing (don't over-claim):** "**core entitlements ✅ shipped** — gate API
  (`has_active_plan?`/`entitled?`), Plug + LiveView `on_mount` guards, provider-honest and
  lifecycle-truthful; the **optional** Stripe-native sync (`entitlements.active_entitlement_summary.updated`)
  is a **deferred, off-by-default** add-on (Phase 127)." Never claim the optional sync ships now.
- **D-11 — Mirror the flip internally per the JTBD re-run convention.** In
  `.planning/research/JTBD-FRONTIER.md`: move the entitlements row from the Gap table to **Shipped**
  (✅, with the deferred-sync note), and rewrite the three places that lean on it as the gap (the
  TL;DR "exactly one item", the delta-table "Entitlements ⛔" row, and the diminishing-returns
  "5 of 6 / the sixth" definition-of-done → "6 of 6 shipped"). Keep deferred/future items
  internal-only (no public roadmap). **Append a dated Update log entry to BOTH files.** Re-verify
  every status cell against current code per the convention (trust code, not memory).
- **D-12 — Spine wiring (minimal, leave First Hour's pinned spine intact):** add ONE bullet to
  README "Start here" (`accrue/README.md:9`) pointing at `guides/entitlements.md`, and ONE bullet to
  quickstart's focused-guides list. Leave First Hour's verifier-pinned
  `deps→install→runtime→migrations→Oban→webhooks→admin→proof` numbered spine untouched (optionally
  add a single non-structural "Next: gate features → Entitlements" cross-link). This avoids new
  structural needles in the most heavily-gated file and the same-PR host-README co-update burden.

### F — Green package-doc verifiers (ENT-12, SC#4)

- **D-13 — Fold in the pre-existing `gateway subscription core` needle fix (Option A).** The
  verifier is **RED on `main` right now**: `verify_package_docs.sh:220` does
  `require_fixed .planning/PROJECT.md "gateway subscription core"` and PROJECT.md lacks the literal
  phrase (red since 2026-05-08, commit d1be4f3). It is a `grep -F` short-circuit that masks the rest
  of the script and fails **6 of 8** `Accrue.Docs.PackageDocsVerifierTest` cases (the test's
  `seed_tmp_dir!` copies the live red PROJECT.md into every negative-drift fixture, so each
  short-circuits before reaching its intended mutation). SC#4 ("verifiers stay green") is **literally
  unsatisfiable without this**, so it ships here. Add the true, already-elsewhere-pinned phrase to
  PROJECT.md (the phrase already lives in README.md, STRATEGY.md, testing.md, and the host README —
  PROJECT.md is the lone holdout, so this restores SSOT parity; insert into the existing
  "Current posture / PROC-08" positioning prose ~`PROJECT.md:37`, written to read naturally and stay
  true to the bounded dual-provider scope). Reject relaxing the assertion (Option B) — it would
  create exactly the asymmetric drift the verifier exists to prevent. *Coherent doc reconciliation
  serving the phase goal — auto-resolves per the bar; flagged as "absorbing pre-existing drift" for
  traceability.*
- **D-14 — Add a TIGHT set of new spine needles (lock SC#2/#3 without brittle prose-pinning):**
  1. `accrue/README.md` → a `[…](guides/entitlements.md)` link in the "Start here" list.
  2. `accrue/guides/entitlements.md` → `entitled?` (canonical gate-fn anchor).
  3. `accrue/guides/entitlements.md` → `Accrue.Plug.RequireEntitlement` (enforcement anchor).
  4. `accrue/guides/entitlements.md` → `[:accrue, :entitlements, :check]` (telemetry event — pinned
     **once, here only**, mirroring how first_hour.md pins `[:accrue, :billing, :checkout_session, :create]`).
  5. `accrue/guides/jobs_to_be_done.md` → a positive `entitlements` shipped marker; **flip-guard:**
     a `require_absent_regex` for the old gap wording (e.g. "headline gap" / "on the table"). **NOTE
     for planner:** the phrase "headline gap" currently also appears in the historical **Update log**
     (`jobs_to_be_done.md:354`) — the absent-regex must not be defeated by the historical line, so
     either reword that log reference or scope the guard pattern to the body/scope sections.
  6. (Only if quickstart/first_hour actually gain an entitlements pointer) pin that link too — never
     pin a link that doesn't exist.
  Do NOT pin: deny-redirect prose, quota numbers, per-provider matrix wording, or gate-fn names
  replicated across README+first_hour+host.
- **D-15 — Mandatory Elixir verifier-test co-update.** The Elixir test shells out to the SAME bash
  script against `seed_tmp_dir!` fixtures, so fixing the script auto-greens the 6 failing tests AND
  exercises the new needles — **but any NEW file a needle references must be in `seed_tmp_dir!`'s
  `copy_fixture!` list or the negative fixtures fail with "No such file."** Add
  `accrue/guides/entitlements.md` (new) **and** `accrue/guides/jobs_to_be_done.md` (currently NOT
  seeded — verified `package_docs_verifier_test.exs:254-274`) to the copy list. Verify green at phase
  end: `bash scripts/ci/verify_package_docs.sh` (exit 0) + `cd accrue && mix test
  test/accrue/docs/package_docs_verifier_test.exs` (8/0) + `cd accrue && mix docs`.

### Claude's Discretion (auto-applied; ZERO forks surfaced)
Per the standing synthesis preference + `discuss_high_impact_confirm_bar`, **no decision crosses the
bar** (no irreversible move, no externally-published-maintainer commitment, no genuine product-vision
fork; additive/reversible and coherent-doc-reconciliation decisions auto-resolve even when
public-surface-shaped):
- Admin view = tab on CustomerLive (D-01) — reversible UI placement; the obvious consistent choice.
- Unmapped-drift = badge entitling subs missing from the reverse-index (D-03) — the only way to show
  silently-dropped subs.
- Admin data path = reuse the resolver fold via a minimal additive helper, no public gate API (D-04)
  — additive/reversible; D-07's `fetch_entitled/2` deferral preserved; exact shape left to planner.
- entitlements.md = narrative guide deferring truth to SSOTs (D-06/D-07/D-08) — reversible doc.
- JTBD flip = new body section + scope flip + spine pointer, honest "core shipped / sync deferred"
  (D-09..D-12) — coherent doc reconciliation.
- Fold the pre-existing `gateway subscription core` needle fix into this phase (D-13) — coherent
  reconciliation required to make SC#4 true.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope & requirements
- `.planning/ROADMAP.md` §"Phase 126" — goal, depends-on (Phase 123 read API, Phase 125 provider
  matrix + truth table), the 4 success criteria.
- `.planning/REQUIREMENTS.md` — ENT-11, ENT-12 (and the milestone goal / out-of-scope table).

### Prior-phase contracts this phase surfaces & documents (read first)
- `.planning/phases/123-config-core-gate-api-foundation/123-CONTEXT.md` — gate API (D-06), fail-closed
  contract (D-08/D-10), telemetry `[:accrue, :entitlements, :check]` + `reason` atoms (D-16..D-20),
  ledger boundary (D-21), one-way dependency (D-14), **`fetch_entitled/2` diagnostic API deferred
  (D-07 — stays deferred this phase)**.
- `.planning/phases/124-enforcement-surfaces-plug-liveview-guards/124-CONTEXT.md` — Plug guard
  (`Accrue.Plug.RequireEntitlement`, `require_feature`/`require_plan`, opaque-403 default, `on_deny`/
  `deny_path`), LiveView `on_mount` guard, `surface` telemetry dim, "LiveView-runtime-free" framing
  (now the doc-reconciled wording).
- `.planning/phases/125-provider-honesty-lifecycle-truth/125-CONTEXT.md` — provider matrix
  (`entitlements.local_mapping`, local-identical), lifecycle truth table SSOT + `entitling?/1`/
  `Query.entitling/1`, past-due grace knob + `grace_plans`/`grace_features`/`expired_grace_plans`,
  the "don't re-derive truth — derive from `entitling?/1`" mandate.

### Source files — admin view (clone/extend)
- `accrue_admin/lib/accrue_admin/live/customer_live.ex` — **the clone target**: `@tabs` allowlist
  (`:31`), `case @tab` render block (`:223`), `tab_counts/1` (`:387`), `tabs/4` (`:410`), mount /
  `owner_scope` / breadcrumb spine.
- `accrue_admin/lib/accrue_admin/router.ex` — live_session `:accrue_admin`, `AuthHook` on_mount
  (no route change needed for the tab option).
- `accrue_admin/lib/accrue_admin/components/` — reusable function components: `KpiCard.kpi_card`,
  `StatusBadge.status_badge`, `Breadcrumbs`, `Tabs.tabs`, `JsonViewer.json_viewer`, `FlashGroup`,
  `AppShell.app_shell`.
- `accrue_admin/lib/accrue_admin/copy.ex` + `copy/` — Copy/VERIFY-01 discipline; add
  `copy/entitlements.ex` + `defdelegate`s + export-allowlist entry.
- `accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex` — the copy allowlist export task.
- `accrue_admin/test/accrue_admin/live/customer_live_test.exs` — the LiveView test template
  (`AccrueAdmin.LiveCase` + `Factory` + `Fake.transition`).

### Source files — entitlements read path (reuse, do NOT re-implement)
- `accrue/lib/accrue/entitlements/resolver/local_map.ex` — `resolve/2` (`:69`, takes a **billable**),
  private `fold_active/1` (`:96`), `active_items/1`/`none_lane_items/1` (`:150`/`:164`), `catalog/0`
  reverse-index (`:253`), `handle_unmapped/3 :deny` silent-drop (`:244`). The fold to reuse for the
  admin view; the silent-drop is why D-03 must read subs independently.
- `accrue/lib/accrue/entitlements.ex` — the 4 public gate fns + the `[:accrue, :entitlements, :check]`
  span (the API entitlements.md documents).
- `accrue/lib/accrue/billing/query.ex` — `entitling/1` (the entitling-sub fetch).
- `accrue/lib/accrue/config.ex` — `entitlements/0` (`:plans` reverse-index source), `past_due_grace/0`.
- `accrue/lib/accrue/billing/customer.ex` — the `%Customer{}` admin holds (`owner_type`/`owner_id`).

### Docs — SSOTs to link (NEVER re-derive) + spine files to edit
- `accrue/guides/lifecycle_semantics.md` — `## Lifecycle → entitlement truth table` (`:173`, anchor
  `#lifecycle--entitlement-truth-table`) + `### entitling` glossary (`:162`). **Truth SSOT.**
- `.planning/processor-support-matrix.md` — the `entitlements.local_mapping` (local-identical) row.
  **Provider SSOT.**
- `accrue/guides/jobs_to_be_done.md` — PUBLIC JTBD tour; "The customer changes their mind" (`:116`),
  "When payments fail" (`:156`), "Scope and maturity" (`:318`, the ⛔ prose at `:339`), Update log
  (`:350`).
- `.planning/research/JTBD-FRONTIER.md` — INTERNAL frontier map (flip per re-run convention).
- `accrue/README.md` — "## Start here" (`:9`).
- `accrue/guides/quickstart.md`, `accrue/guides/first_hour.md`, `accrue/guides/maturity-and-maintenance.md`
  — existing spine cross-links (note: README/quickstart/maturity have uncommitted local edits).
- `accrue/guides/connect.md`, `accrue/guides/webhooks.md` — peer guide shapes to mirror for
  entitlements.md.

### Verifier
- `scripts/ci/verify_package_docs.sh` — the drift gate; `gateway subscription core` needle (`:220`),
  the "Start here"/spine needle region (`:70-105`), helpers `require_fixed`/`require_regex`/
  `require_absent_regex`.
- `accrue/test/accrue/docs/package_docs_verifier_test.exs` — Elixir wrapper; `seed_tmp_dir!` /
  `copy_fixture!` list (`:247-274`) — add entitlements.md + jobs_to_be_done.md.

### Project conventions & research
- `.planning/PROJECT.md` — config-vs-runtime boundary; telemetry mandate; **the `gateway subscription
  core` needle holdout to fix (D-13)**; "ship complete" philosophy.
- `.planning/research/PITFALLS.md` — #1 (fail-open: fail-closed is the easy/front-and-center path),
  **#2 (don't re-derive lifecycle truth — derive from `entitling?/1`)**.
- `.planning/research/JTBD-FRONTIER.md`, `FEATURES.md` — entitlements = the (now-closing) #1 gap;
  local-first thesis.
- `CLAUDE.md` — SSOT-mirror co-update discipline (code/doc labels + verifier needles in the same PR);
  guide-style conventions.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`AccrueAdmin.Live.CustomerLive`**: the read-only tabbed detail view — add an `"entitlements"`
  tab clause; reuse mount / `owner_scope` / `AuthHook` / breadcrumbs verbatim.
- **`accrue_admin` components** (`KpiCard`, `StatusBadge`, `JsonViewer`, `Tabs`, `FlashGroup`,
  `AppShell`): render resolved plans/features/quantities/grace + the unmapped badge with no new
  components.
- **`AccrueAdmin.Copy` + `copy/` submodules + export task**: VERIFY-01 copy SSOT — add an
  `Entitlements` submodule.
- **`Accrue.Entitlements.Resolver.LocalMap` fold** (`fold_active`/`catalog`/`active_items`): the
  resolver truth to **reuse** via a minimal additive helper — never re-implement (drift).
- **`Accrue.Billing.Query.entitling/1`** + **`Accrue.Config.entitlements/0`**: the entitling-sub
  fetch + the `price_id → plan` reverse-index — the inputs for unmapped-drift detection.
- **`connect.md` / `webhooks.md`**: peer guide shapes (Getting Started → topic sections w/ examples →
  Related guides; defer truth to SSOT) to mirror for `entitlements.md`.
- **`scripts/ci/verify_package_docs.sh` helpers** + **`package_docs_verifier_test.exs` seed list**:
  the drift-gate template to extend (in place) + the fixture list to co-update.

### Established Patterns
- **Read-only admin detail = tabbed CustomerLive**; per-customer sub-views are tabs, not routes.
- **Copy/VERIFY-01**: operator strings live in `AccrueAdmin.Copy.*`, allowlist-exported, never
  hardcoded.
- **SSOT-mirror co-update discipline**: doc labels + their verifier needles co-updated in the SAME
  PR (Phase 124 D-06 / 125 D-09).
- **Don't re-derive truth (PITFALLS #2)**: derive entitlement from `entitling?/1`; link the SSOT
  tables, don't duplicate.
- **One-way dependency**: admin/entitlements → billing; nothing reverse.
- **JTBD two-artifact re-run convention**: public `jobs_to_be_done.md` + internal
  `JTBD-FRONTIER.md`, both updated with an Update-log entry; re-verify cells against code.

### Integration Points
- Edit `accrue_admin/lib/accrue_admin/live/customer_live.ex` (entitlements tab) + new
  `accrue_admin/lib/accrue_admin/copy/entitlements.ex` + `copy.ex` defdelegates + export allowlist.
- Minimal additive read seam in `accrue/lib/accrue/entitlements/` (resolver-level helper reusing the
  fold + surfacing unmapped price_ids) — NO public `Accrue.*` gate API.
- New `accrue/guides/entitlements.md`; edits to `jobs_to_be_done.md`, `README.md`, `quickstart.md`
  (+ optional `first_hour.md` cross-link), `.planning/research/JTBD-FRONTIER.md`, `.planning/PROJECT.md`.
- Extend `scripts/ci/verify_package_docs.sh` (needles) + `accrue/test/accrue/docs/package_docs_verifier_test.exs`
  (seed list).
- **No migrations, no Ecto schema change, no webhook code, no `accrue_events` writes, no change to
  gate decision logic.**
</code_context>

<specifics>
## Specific Ideas

- The admin entitlements tab should read like LaunchDarkly's per-subject detail: **resolved state
  first** (active plans / features / quantities / grace), **then the "why"** — a "⚠ Unmapped plan"
  badge on any active subscription the resolver couldn't map. Operator gets the answer and the drift
  signal on one read-only screen.
- entitlements.md opens with the fail-closed easy path: `if Accrue.entitled?(user, :pro), do: …,
  else: upsell()` — impossible to fail open — before any happy-path config (PITFALLS #1).
- JTBD flip phrasing must be honest: "core entitlements shipped; optional Stripe-native sync is a
  deferred, off-by-default add-on" — never imply the sync ships now.
- The pre-existing `gateway subscription core` needle: PROJECT.md is the lone holdout among 5 files
  that pin it — adding it restores parity, it's not inventing new scope.

</specifics>

<deferred>
## Deferred Ideas

- **Optional Stripe-native webhook→cache sync + `grant`/`revoke` + ledger writes + a `native`
  entitlements capability row (ENT-10)** → Phase 127 (off by default, needs-deeper-research).
- **Public `Accrue.fetch_entitled/2` / `fetch_entitlement_quantity/2` boolean-diagnostic API**
  (Phase 123 D-07) → still deferred; the admin view's read seam is internal/additive, not this.
- **A standalone `/entitlements` fleet index** ("show me every customer on an unmapped price_id") →
  post-v1.0, only if operators ask; ENT-11 is per-customer.
- **A dedicated entitlements drift dashboard / grant-override admin actions** → future; this phase
  is read-only.
- **Atomic seat enforcement / membership management** — host-owned; documented recipe, never a core
  API (standing out-of-scope).

### Reviewed Todos (not folded)
None — no pending todos matched this phase.

</deferred>

---

*Phase: 126-admin-surface-docs-jtbd-spine*
*Context gathered: 2026-05-23*
