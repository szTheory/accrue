# Phase 150: Documentation & Adopter Proof - Context

**Gathered:** 2026-05-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Final phase of milestone **v1.45 — Multi-channel Dunning (In-App Banners)**. Delivers two things, both built on Phase 149's already-shipped artifacts:

- **BAN-03 — Integration documentation:** update the existing `accrue/guides/dunning.md` with an "In-App Banners" section showing how to use the dunning state API and banner component.
- **BAN-04 — Adopter proof:** wire the banner into `examples/accrue_host` so it visibly appears when a logged-in user's subscription is past due, plus the adopter-proof matrix row.

**Phase 149 shipped (the building blocks — do NOT rebuild):**
- `Accrue.Dunning.requires_attention?/1` (boolean) in core `accrue` — `accrue/lib/accrue/dunning.ex`, delegates to `Accrue.Billing.Query.in_active_dunning_campaign/1`.
- `AccrueAdmin.Components.DunningBanner` — `accrue_admin/lib/accrue_admin/components/dunning_banner.ex`. Function component `dunning_banner/1` accepting `:customer`, an `inner_block` slot for custom content, and a minimally-styled default message. **Lives in `accrue_admin`, not core.**

**No new banner features.** This phase documents and demonstrates the existing capability only. New surfaces (SMS/push, real-time refresh, etc.) are deferred — see Deferred Ideas.
</domain>

<decisions>
## Implementation Decisions

### Demo dunning scenario (BAN-04)
- **D-01:** Produce the in-dunning state via a **seeded scenario** in `examples/accrue_host/priv/repo/seeds.exs` — always-on, reproducible (`mix ecto.setup` + log in = banner visible). No dev-only trigger buttons, no manual-steps-only approach. Matches the Phase 132 adopter-proof demo pattern.
- **D-02:** Seed a **dedicated past-due demo account** (e.g. `past-due@example.com`) — a user whose active organization has a past-due subscription and an active dunning campaign — **alongside the existing healthy primary account**. A reviewer can log in as either to see banner-on vs banner-off side by side. The default/healthy user is NOT permanently nagged.
- **D-03:** Drive the past-due/dunning state through the **Fake processor** (no live Stripe/Braintree dependency in the example seed).

### Banner placement & style (BAN-04)
- **D-04:** Mount the banner at the **top of `<main>` in `Layouts.app`** (`examples/accrue_host/lib/accrue_host_web/components/layouts.ex`) so it appears **globally on every authenticated page**.
- **D-05:** The example uses the component's **zero-config default styling/message** (no custom `inner_block` in the demo) — demonstrates the truest "drop it in" headless path adopters copy first. The customized/CTA variant is shown in the guide (D-08), not the example.

### Guide depth & structure (BAN-03)
- **D-06:** Add a new top-level **`## In-App Banners`** section to `accrue/guides/dunning.md`, placed **immediately after the "Over-email warning" section** (in-app banners read as the natural non-email alternative). Add a **cross-link from the over-email warning into the new section**.
- **D-07:** Document **both integration paths**:
  - the `accrue_admin` `<.dunning_banner>` component path, and
  - a **core-only DIY path** using just `Accrue.Dunning.requires_attention?/1` for hosts that don't pull `accrue_admin` (roll-your-own markup).
  - Be explicit about the dependency boundary: the ready-made component requires `accrue_admin`; the helper is core.
- **D-08:** For the component path, document **both the default (zero-config) usage AND `inner_block` customization** (e.g. a styled "Update your card" message with a CTA link to the host's payment/subscription route).

### Customer resolution (BAN-04, and the pattern the guide shows)
- **D-09:** Resolve the current scope's **active organization → its Accrue customer**, and pass that as the banner's `:customer`. Matches the example's **org-level billing model** (subscriptions/dunning hang off the organization, not the user). User-level resolution was rejected as contradicting the model.
- **D-10:** Put the org→customer lookup in a **small helper** (e.g. in `AccrueHost.Billing` or as a layout assign) so `Layouts.app` stays clean. **Reuse the existing org→customer resolution pattern already in `subscription_live.ex` / `AccrueHost.Billing`** rather than inventing a new one — researcher/planner should read that code and match it exactly.

### Claude's Discretion
- Exact prose/wording of the guide section, code-snippet formatting, and the seeded account's display name/email.
- Whether the org→customer helper lives in `AccrueHost.Billing` vs a layout `on_mount`/assign — pick whichever matches the existing `subscription_live.ex` pattern.
- Exact form of the BAN-04 adopter-proof matrix row (follow the existing matrix convention in `.planning/processor-support-matrix.md` / prior adopter-proof rows).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone scope (read first)
- `.planning/ROADMAP.md` §"Phase 150: Documentation & Adopter Proof" — goal + success criteria.
- `.planning/REQUIREMENTS.md` — BAN-03, BAN-04 (and BAN-01/BAN-02 for context on what shipped).

### Phase 149 shipped artifacts (the things being documented/demoed — do NOT rebuild)
- `accrue/lib/accrue/dunning.ex` — `Accrue.Dunning.requires_attention?/1` (the core API).
- `accrue_admin/lib/accrue_admin/components/dunning_banner.ex` — `AccrueAdmin.Components.DunningBanner.dunning_banner/1` (the component; `:customer` attr + `inner_block` slot + default message).
- `.planning/phases/149-dunning-state-api-and-headless-component/149-01-SUMMARY.md` — API details.
- `.planning/phases/149-dunning-state-api-and-headless-component/149-02-SUMMARY.md` — component details.

### BAN-03 doc target
- `accrue/guides/dunning.md` — existing guide to UPDATE (sections: Overview → Per-provider → Configuration → Chimeway → Observability → Over-email warning → Lifecycle & entitlements). New `## In-App Banners` section goes after "Over-email warning".

### BAN-04 example-host wiring targets
- `examples/accrue_host/lib/accrue_host_web/components/layouts.ex` — `Layouts.app` mount point (top of `<main>`).
- `examples/accrue_host/priv/repo/seeds.exs` — seed the dedicated past-due demo account.
- `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` + `examples/accrue_host/lib/accrue_host/billing.ex` (+ `billing/`) — existing org→customer resolution pattern to reuse.
- `examples/accrue_host/mix.exs` — confirms `accrue_host` already depends on `accrue_admin` (component is available).
- `.planning/processor-support-matrix.md` — adopter-proof matrix convention for the BAN-04 row.

### Prior-phase precedent (patterns to follow)
- `.planning/phases/132-entitlements-adopter-proof-demo/132-CONTEXT.md` — adopter-proof demo pattern.
- `.planning/phases/130-provider-honesty-fake-lane-proof-example-host-wiring/130-CONTEXT.md` — prior example-host dunning wiring (Fake-lane proof).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `AccrueAdmin.Components.DunningBanner` — the headless component; the example just mounts `<.dunning_banner customer={...} />`.
- `Accrue.Dunning.requires_attention?/1` — the core boolean helper for the DIY path and the component's internal check.
- Existing org→customer resolution in `subscription_live.ex` / `AccrueHost.Billing` — reuse for D-09/D-10.
- `examples/accrue_host/priv/repo/seeds.exs` — existing seed script to extend with the past-due account.

### Established Patterns
- Example host bills at the **organization** level; subscriptions already carry dunning columns (migrations `..._add_dunning_and_pause_columns_to_subscriptions`, `..._add_dunning_campaign_started_at_to_subscriptions`). Dunning state hangs off the org's subscription.
- Phoenix 1.8 layout style: `Layouts.app` function component with `@current_scope` (scope exposes `current_scope.user`); root shell in `layouts/root.html.heex`.
- `accrue_host` already depends on `accrue` (path) AND `accrue_admin` (path) — no new dependency needed.
- Adopter-proof demos (Phases 130/132) ship via seeds + example-host wiring, not throwaway demo routes.

### Integration Points
- `Layouts.app` `<main>` region ← new `<.dunning_banner>` mount.
- `seeds.exs` ← new past-due user/org/subscription/dunning-campaign records (via Fake processor).
- `accrue/guides/dunning.md` ← new `## In-App Banners` section + cross-link from "Over-email warning".
- `.planning/processor-support-matrix.md` (or the adopter-proof matrix) ← new banner row.
</code_context>

<specifics>
## Specific Ideas

- Demo account naming intent: a clearly-labeled past-due account (e.g. `past-due@example.com`) so the banner-on state is obvious to a reviewer; healthy primary account stays banner-free.
- The guide's customization snippet should show an actionable "Update your card" CTA linking to the host's payment/subscription route (since the example itself uses the bare default).
- Side-by-side proof: a reviewer logs in as the healthy account (no banner) vs the past-due account (banner) to see the conditional rendering work end-to-end.
</specifics>

<deferred>
## Deferred Ideas

- **Multi-channel (SMS/push) dunning via Chimeway** — explicit standing non-goal (compliance risk); deferred per STATE.md 2026-05-28.
- **Real-time PubSub-driven banner refresh** — out of scope; banner reflects state on page load/navigation. (Coupled to broader real-time dunning work, deferred from v1.44.)
- **A polished customer-facing payment-update flow in the example** — the banner's CTA can link to the existing subscription page; building a dedicated dunning resolution UI is its own concern, not this phase.
- **Promoting the banner component into core `accrue`** (so core-only hosts get a ready-made component without `accrue_admin`) — would re-open Phase 149's placement decision; out of scope here. The core-only DIY doc path (D-07) is the v1.45 answer.

None of the above belong in Phase 150 — discussion stayed within the documentation + adopter-proof boundary.
</deferred>

---

*Phase: 150-documentation-adopter-proof*
*Context gathered: 2026-05-28*
