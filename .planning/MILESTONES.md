# Milestones

## v1.44 Recovered-Revenue Dashboard Completion (Shipped: 2026-05-28)

**Phases completed:** 5 phases (144–148)
**Timeline:** 2026-05-27 → 2026-05-28 (2 days)

**Delivered:** The Recovered-Revenue dashboard in AccrueAdmin, visualizing the funnel query and at-risk table. This builds on the Phase 143 MRR snapshotting foundation. Includes cross-currency widening, recovery-rate API, time-window URL plumbing, and drill-down route. **BREAKING change DAN-07 included**, blocking post-v1.44 Hex publish until released.

**Milestone audit:** `passed` — definition of done **ACHIEVED**, 16/16 requirements satisfied, all 5 phases verified `passed`. See `.planning/v1.44-v1.44-MILESTONE-AUDIT.md`.

**Key accomplishments:**

- **Phase 144:** Funnel query + viz + campaign-anchor retrofit + money formatter polish (DAN-01, DAN-02, DAN-08, DAN-09, DAN-13).
- **Phase 145:** Time-window URL plumbing + window selector (DAN-10).
- **Phase 146:** At-risk query + at-risk table + last-failure enrichment (DAN-03, DAN-04, DAN-11).
- **Phase 147:** Per-subscription drill-down route + CampaignLive (DAN-05, DAN-12).
- **Phase 148:** Cross-currency widening + recovery-rate API + public docs + adopter-proof (DAN-06, DAN-07, DAN-14, DAN-15, DAN-16).

---

## v1.43 v1.43 (Shipped: 2026-05-27)

**Phases completed:** 1 phases, 2 plans, 0 tasks

**Key accomplishments:**

- Snapshotted MRR onto dunning lifecycle events and shipped the `Accrue.Analytics.Dunning` Ecto context that folds the `accrue_events` ledger into a flat recovered-vs-lost MRR map without adding new tables.
- Implemented the AccrueAdmin Recovery Live dashboard and routing to visualize the success of the Dunning Engine.

---

## v1.43 Linked Release 1.2.0 Truth (Shipped: 2026-05-27)

**Phases completed:** 3 phases (140–142)
**Timeline:** 2026-05-27 → 2026-05-27 (1 day)

**Delivered:** Closed the linked release-truth gap by locking the three-package contract for `accrue`, `accrue_admin`, and `accrue_portal`. Published the public `1.2.0` trio to Hex with canonical proof and verified post-publish doc mirrors. Concluded with the final friction inventory maintainer pass and planning closeout.

**Key accomplishments:**

- **Phase 140:** Locked the three-package release contract in release automation and runbooks.
- **Phase 141:** Shipped the `1.2.0` trio to Hex and passed the post-publish contract sweep.
- **Phase 142:** Performed planning-mirror alignment and the maintainer friction inventory pass.

---

## v1.42 Ad-hoc Invoices & Adopter Confidence (Shipped: 2026-05-27)

**Phases completed:** 5 phases (135–139)
**Timeline:** 2026-05-26 → 2026-05-27 (2 days)

**Delivered:** End-to-end adopter demos for checkout and metered usage, recovery wiring in the example host, fixes for entitlement cache robustness and fidelity, and full ad-hoc manual line item support on draft invoices via both API and Admin UI.

**Milestone audit:** `passed` — definition of done **ACHIEVED**, 7/7 requirements satisfied, all 5 phases verified `passed`. See `.planning/v1.42-v1.42-MILESTONE-AUDIT.md`.

**Key accomplishments:**

- **Phase 135:** Demonstrated metered usage and checkout facade in `examples/accrue_host`.
- **Phase 136:** Wired the `DetectExpiringCards` recovery cron in the example host.
- **Phase 137:** Resolved `Ecto.StaleEntryError` (WR-05) via race-safe upsert and fixed sync fidelity gaps (IN-01..04).
- **Phase 138:** Built the `Accrue.Billing` public API and processor extensions to manage manual ad-hoc line items on draft invoices.
- **Phase 139:** Shipped the admin UI in `accrue_admin` for operators to add and remove ad-hoc line items seamlessly.

---

## v1.41 Admin global search (native Postgres) (Shipped: 2026-05-26)

**Phases completed:** 2 phases (133–134)
**Timeline:** 2026-05-26 → 2026-05-26 (1 day)

**Delivered:** Ecto-native global search for Customers, Invoices, and Subscriptions in the admin UI using Postgres native text search (`pg_trgm`), approaching the Stripe Dashboard UX without adding a separate sidecar dependency.

**Milestone audit:** `passed` — definition of done **ACHIEVED**, 4/4 requirements satisfied, all 2 phases verified `passed`. See `.planning/v1.41-v1.41-MILESTONE-AUDIT.md`.

**Key accomplishments:**

- **Phase 133:** Implemented `Accrue.Billing.Search` module with `pg_trgm` similarity queries and added GIN indices for fast fuzzy-matching on core billing tables.
- **Phase 134:** Built the `AccrueAdmin.Components.GlobalSearch` LiveComponent and the `CommandPalette` JS hook, enabling `CMD+K` keyboard-first search navigation across the admin UI.

---

## v1.40 Dunning depth / notification journeys (Shipped: 2026-05-25)

**Phases completed:** 5 phases (128–132), 23 plans
**Timeline:** 2026-05-24 → 2026-05-25 (2 days)

**Delivered:** The headline JTBD — a multi-step configurable dunning journey (reminder → wait → escalate → final notice) with a customer recovery surface, admin visibility, and provider-honest + Fake-proven behavior, without new heavy dependencies. Included an optional, isolated Chimeway engine adapter and completed the v1.39 adopter-proof gap by demonstrating entitlements gating in `examples/accrue_host`.

**Milestone audit:** `passed` — definition of done **ACHIEVED**, 11/11 requirements satisfied, all 5 phases verified `passed`, cross-phase integration 10/10, all 3 E2E flows complete. See `.planning/v1.40-v1.40-MILESTONE-AUDIT.md`.

**Key accomplishments:**

- **Phase 128:** Delivered a durable Oban campaign engine for dunning cadences, solved the `:invoice_payment_failed` idempotency must-fix, and established cancel-on-recovery behavior.
- **Phase 129:** Built customer portal banner for recovery, admin dunning state components, and implemented comprehensive observability with dunning ledger events and a `recovered_vs_lost` counter.
- **Phase 130:** Updated `guides/dunning.md` for provider honesty, shipped deterministic Fake-lane merge-blocking proof, and wired the default campaign into `examples/accrue_host`.
- **Phase 131:** Standardized `Accrue.Dunning.Engine` behaviour, and shipped the off-by-default optional Chimeway engine adapter for multi-channel expansion.
- **Phase 132:** Implemented an entitlement-gated route/page in `examples/accrue_host` and proved the adopter-proof matrix rows for Entitlements.

**Next after ship:** `v1.40` complete; ready for `v1.41` roadmap or release process.

---

## v1.39 Entitlements / Plan-Gating (Shipped: 2026-05-24)

**Phases completed:** 5 phases (123–127), 21 plans, 53 tasks
**Timeline:** 2026-05-22 → 2026-05-24 (3 days) · 32 `feat` commits · 194 files changed (+31,759 / −252)
**Git range:** `4ad23a6` (milestone start) → `15b6709` (milestone audit)

**Delivered:** The headline JTBD — gate features and access on what a customer has paid for — first-party, local-first, fail-closed, with **no new tables and no Stripe dependency** on the core gate path, plus an isolated off-by-default Stripe-native advisory-sync overlay.

**Milestone audit:** `tech_debt` — definition of done **ACHIEVED**, 12/12 requirements satisfied, all 5 phases verified `passed`, cross-phase integration 9.5/10, all 3 E2E flows complete. Status `tech_debt` (not `passed`) only surfaces accumulated non-critical, non-fail-open review follow-ups + partial Nyquist coverage (123–125). See `.planning/v1.39-v1.39-MILESTONE-AUDIT.md`.

**Known deferred items at close:** 4 (see STATE.md → Deferred Items) — 2 stale pre-v1.39 quick tasks, the Phase 127 advisory-cache follow-up todo, and the dormant SEED-002 ecosystem-integrations seed. None block the milestone DoD.

**Key accomplishments:**

- NimbleOptions-validated `:entitlements` plan->feature/quota config schema with a runtime `entitlements/0` accessor and a boot-time `price_id`-collision guard that fails loud (`Accrue.ConfigError`) when one price_id maps to two plans.
- Extended the strict OTel `@allowed_attributes` allowlist with the six D-19 entitlement keys (`:feature`, `:result`, `:resolver`, `:reason`, `:subject_type`, `:subject_id`) so entitlement spans carry their decision metadata across the OTel bridge instead of being silently dropped.
- `Accrue.Entitlements` context tree — `%Plan{}` value struct + `Resolver` behaviour, the read-only `LocalMap` resolver that folds active subscription state into an `active_plans` SET / features UNION / merged quantities, and four fail-closed gate functions (`entitled?`, `has_active_plan?`, `features_for`, `entitlement_quantity`) wrapped in inline `[:accrue, :entitlements, :check]` telemetry with zero audit-ledger writes.
- Four `defdelegate` shims wire the entitlement gate API onto the top-level `Accrue` module (`has_active_plan?/2`, `entitled?/2`, `features_for/1`, `entitlement_quantity/2`), backed by the load-bearing D-10 fail-closed property test (never-true-on-garbage + true-iff-affirmative-match + a multi-active-plan affirmative leg) exercised through those public delegates, with the D-14 one-way-dependency invariant certified and the D-16 ROADMAP/REQUIREMENTS event name reconciled to the plural `[:accrue, :entitlements, :check]`.
- Extended the Phase 123 entitlement foundation with the three host-supplied guard config keys (billable / on_deny / deny_path, boot-validated via a custom validate_on_deny/1), an OTel :surface allowlist entry, and an additive surface: opt on entitled?/3 + has_active_plan?/3 — the contract layer both Plug and LiveView guards consume, with zero breakage to any Phase 123 caller.
- Built `Accrue.Entitlements.Guard` — the always-compiled, LiveView-runtime-free decision engine both enforcement surfaces call: it resolves the billable once (per-guard opt → config global → `current_scope.user`/`current_user` probe), delegates the allow/deny decision fail-closed to the Phase 123 gate carrying the `surface:` telemetry dimension, resolves the tiered `on_deny` (per-guard → config → `:forbidden`), builds a bounded no-PII `ctx`, and translates plug denies opaquely — with zero LiveView/Phoenix.Controller coupling, proven by 16 unit + telemetry tests.
- Shipped the route-level entitlement gate a Phoenix developer reaches for first: `Accrue.Plug.RequireEntitlement` — a pure-Plug `@behaviour Plug` whose `init/1` raises `ArgumentError` at compile on ambiguous intent (both / neither / wrong-type `feature:`/`plan:`, T-124-08) and whose `call/2` is a thin delegate to the Wave 2 `Accrue.Entitlements.Guard` engine (allow → conn untouched; deny → content-negotiated opaque 403 / redirect / status override) — plus the `require_feature/1` / `require_plan/1` router macros that expand to the canonical plug, proven by 21 tests with ZERO `Phoenix.Controller` coupling.
- Shipped `Accrue.Live.Entitlements` — the conditionally-compiled `on_mount/4` LiveView enforcement surface for ENT-07: `{:require_feature, x}` / `{:require_plan, y}` clauses that delegate the decision to the Wave 2 `Accrue.Entitlements.Guard.check(:live, …)` engine and only surface-translate the deny enum (`{:redirect, path}` → `redirect`; `:forbidden` and the `{status, body}` degradation → opaque `put_flash` + `redirect(to: deny_path())`), with a resolve-once billable-only `assign_new(:accrue_billable, …)` stash. It is the ONLY always-shipped core file permitted LiveView refs — all confined inside the `Code.ensure_loaded?(Phoenix.LiveView)` block (the Sigra 4-pattern) — proven by 10 tests including the cond-compile source assertion and the cont/halt legs.
- Every project artifact that claimed core `accrue` is 'LiveView-FREE / compiles with no LiveView present / phoenix_live_view absent-or-optional in core' is now reconciled to the accurate 'core stays LiveView-runtime-free' posture, with ROADMAP SC#3 pointing at the static merge-gate invariant instead of the infeasible compile-cell.
- Provider-honesty capability surface — an `Accrue.Entitlements.Resolver` behaviour plus additive `entitlements:` capability-matrix rows making local plan→feature mapping byte-identical across Stripe/Braintree/Fake, with a merge-blocking `verify_processor_support_matrix.sh` drift gate (positive byte-match asserts + a negative divergence guard) and the deterministic Fake-lane merge-blocking proof.
- Added `Subscription.entitling?/1` + its `Query.entitling/1` Ecto twin as the single source of truth for which lifecycle states grant entitlement, retargeted the LocalMap resolver to it (closing the paused fail-OPEN broken-access-control gap where a `status: :active` + `pause_collection` subscription still granted access), and documented + merge-blocking-pinned the canonical lifecycle truth table.
- Delivered the fail-safe `past_due_grace` knob (ENT-09 SC#3/#4): a boot-validated `:entitlements` config key (default fail-closed `:none`), a pure clock-driven `PastDueGrace.within_grace?/2` helper, a cost-aware conditional fold-widening in `LocalMap` (zero query change when `:none`, `:past_due`-widen + per-row clock filter when enabled), additive `:grace_plans` / `:grace_features` / `:expired_grace_plans` resolved signals, the additive `:past_due_grace` / `:past_due_expired` telemetry reasons, and the truth-table footnote — so a `:past_due` subscription within a configured window grants entitlement as an affirmative, resolved decision while `:unpaid` never does and the default preserves the shipped fail-closed contract.
- `Accrue.Entitlements.Admin.resolve_for_customer/1` — an internal read-only diagnostic seam that returns `{resolved_map, unmapped_price_ids}` by reusing the resolver's SSOT fold and independently surfacing the entitling price_ids the resolver structurally discards under `:deny`.
- A read-only `entitlements` tab on `AccrueAdmin.Live.CustomerLive` (`/customers/:id?tab=entitlements`) that renders a customer's resolved active plans, granted features, seats & limits, and grace state, then badges any active subscription whose `price_id` is unmapped with a self-explaining "⚠ Unmapped plan" drift signal — calling the Plan 01 read seam once and routing every operator string through the VERIFY-01 three-part Copy contract.
- The fail-closed-first `guides/entitlements.md` (gate API, Plug + LiveView guards, provider matrix, lifecycle truth table), the honest entitlements ⛔→✅ JTBD flip in both the public `jobs_to_be_done.md` and internal `JTBD-FRONTIER.md`, and the README + quickstart "Start here" spine pointers — with the package-doc verifiers restored to green.
- New `accrue_entitlement_summaries` advisory cache table (Ecto schema + forward-only migration), the off-by-default `stripe_native_sync: {:disabled, :advisory}` config enum that gates the entire Stripe-native sync path, and three RED test scaffolds encoding the full ENT-10 reducer/isolation contract.
- The heart of ENT-10: a config-gated, off-by-default webhook reducer that writes the advisory entitlement-summary cache with monotonic ordering, on-change-only ledgering, full span/event/ops telemetry, and orphan/malformed tolerance — plus a one-way read seam that exposes the cache without ever touching the gate path. Turns all three Plan 01 RED scaffolds GREEN.
- New `entitlements.stripe_native_sync` capability row (Stripe `native (advisory)`, Fake out-of-slice, Braintree unsupported) landed across code labels + matrix markdown + a tightened drift gate, plus a new merge-blocking static gate proving the advisory cache is unreachable from the always-on entitlement gate path.
- The human-facing half of D-12: guides/entitlements.md now tells the optional Stripe-native sync story end-to-end — the plain "advisory = observational, does NOT change `entitled?`" disclaimer, the two-step enable (config `:advisory` + host Stripe Dashboard event-enable), the eventual-consistency window, the 10-entitlement inline cap, and the deferred `lattice_stripe >= 1.2` paginated read — guides/telemetry.md catalogs the new sync span/event, and verify_package_docs.sh pins it all merge-blocking with four new byte-exact needles.

---

## v1.38 Linked Release Truth (Shipped: 2026-05-08)

**Planning opened:** 2026-05-07

**Phases completed:** **3** phases (**120–122**).

**Theme:** Close the linked release-truth gap by locking the three-package contract, shipping the public `1.1.1` trio with canonical proof, and finishing the post-publish planning-mirror plus inventory closeout.

Current public linked release line: accrue / accrue_admin / accrue_portal 1.1.1 (published 2026-05-08).

**Depends on:** **v1.37** shipped.

**Key accomplishments:**

- **120:** **REL-09**, **PPX-15** — locked the three-package release contract, aligned the runbook/workflows, and made release truth merge-blocking.
- **121:** **REL-10**, **REL-11**, **PPX-13**, **PPX-14** — published the linked `1.1.1` trio, recorded canonical public proof in `121-VERIFICATION.md`, and reran the post-publish docs/adoption/shift-left bundle.
- **122:** **HYG-03**, **INV-08** — aligned the live planning mirrors to the shipped trio line, recorded the dated path-`(b)` maintainer certification, and finalized the planning closeout ledger in `122-VERIFICATION.md`.

**Outcome:** Phases **120–122** closed the **v1.38** Linked Release Truth milestone with one coherent maintainer story: the public `1.1.1` trio is shipped, the canonical publish proof lives in `121-VERIFICATION.md`, and the live planning closeout proof lives in `122-VERIFICATION.md`.

**Key proof artifacts:**

- **`.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md`**
- **`.planning/phases/122-post-publish-mirrors-friction-pass/122-VERIFICATION.md`**

**Next after ship:** Open the next bounded milestone from the shipped `1.1.1` trio baseline.

---

## v1.37 Subscription Change Management (Shipped: 2026-05-07)

**Planning opened:** 2026-05-07

**Phases completed:** **3** phases (**117–119**).

**Theme:** Promote active subscription changes into a first-party contract across
the billing facade, admin/operator UI, customer self-serve portal, package
docs, host mirrors, and verifier gates, while keeping Braintree explicitly
bounded to resolver-backed plan swaps.

**Depends on:** **v1.36** shipped.

**Key accomplishments:**

- **117:** **SCM-01..SCM-02** — promoted `swap_plan/3` and `preview_upcoming_invoice/2` into the official active-subscription-change contract, aligned package/host docs to the same preview-before-commit story, and made drift in that wording merge-blocking.
- **118:** **SCM-03..SCM-05** — promoted Stripe/Fake quantity and subscription-item mutations into the first-party contract, added preview-backed admin flows, and shipped bounded customer self-serve plan-change support with provider-honest Braintree copy.
- **119:** **SCM-06** — finalized the bounded Braintree `:plan_resolver` contract across runtime, package docs, host mirrors, and support-contract verifier needles.

**Outcome:** Phases **117–119** closed the **v1.37** Subscription Change
Management milestone with all `SCM-01..06` requirements satisfied.

**Known gaps accepted at close:**

- No dedicated `v1.37` milestone audit artifact was run before archival; closeout proceeded on targeted phase verification plus a clean open-artifact audit.

**Archives:**

- **`.planning/milestones/v1.37-ROADMAP.md`**
- **`.planning/milestones/v1.37-REQUIREMENTS.md`**
- **`.planning/milestones/v1.37-phases/`**

**Git tag:** `v1.37`

**Next after ship:** Run the linked release-readiness pass or open the next
milestone with `$gsd-new-milestone`.

---

## v1.36 Dual-Provider Core Completion (Shipped: 2026-05-07)

**Planning opened:** 2026-05-06

**Phases completed:** **5** phases (**112–116**).

**Theme:** Close the remaining staged rows in the official Stripe + Braintree gateway-subscription-core contract, then restore the missing verification artifacts so the shipped support surface, planning mirrors, and drift gates all tell one merge-blocking story.

**Depends on:** **v1.35** shipped.

**Key accomplishments:**

- **112:** **PROC-21** — promoted `Accrue.Billing.update_customer/2` to an explicit bounded first-party contract across Fake, Stripe, and Braintree, with host/helper proof.
- **113:** **PROC-22..PROC-23** — promoted immediate cancellation to first-party support, kept Braintree scheduled-end semantics explicit, and aligned docs, portal/admin copy, and drift gates to the same provider-honest contract.
- **114:** **PROC-24** — settled the canonical support matrix, thinned package/example-host mirrors to point back to it, and documented the support-contract verifier bundle and CI home.
- **115–116:** restored `113-VERIFICATION.md` and `114-VERIFICATION.md`, cleared the audit orphan gaps, and flipped the `v1.36` milestone audit to `passed`.

**Outcome:** Phases **112–116** closed the **v1.36** Dual-Provider Core Completion milestone with all `PROC-21..24` requirements satisfied and represented by verification artifacts.

**Archives:**

- **`.planning/milestones/v1.36-ROADMAP.md`**
- **`.planning/milestones/v1.36-REQUIREMENTS.md`**
- **`.planning/v1.36-v1.36-MILESTONE-AUDIT.md`**

**Git tag:** `v1.36`

**Next after ship:** Run the linked release-readiness pass, then choose the next bounded milestone with `$gsd-new-milestone`.

---

## v1.34 Rendro Native Invoice PDF Default (Shipped: 2026-05-06)

**Planning opened:** 2026-05-06

**Phases completed:** **3** phases (**106–108**).

**Theme:** Make Rendro the default invoice PDF engine so the normal Accrue install story no longer requires Chrome. Preserve the existing invoice API and lazy render semantics, keep ChromicPDF as an explicit compatibility path, and finish by publishing the required Rendro version to Hex instead of leaving Accrue on a local path dependency.

**Depends on:** **v1.33** shipped.

**Phase execution trees:** **`.planning/milestones/v1.34-phases/106-invoice-renderer-seam-rendro-default/`**, **`107-rendro-release-optional-chromic-path/`**, **`108-docs-migration-proof-closeout/`**.

**Key accomplishments:**

- **106:** **PDF-01..PDF-05** — invoice-renderer seam, Rendro default, stable billing facade semantics, and billing/mailer/admin parity proof.
- **107:** **PDF-06..PDF-07** — typed explicit-Chromic compatibility contract, migration-safe warnings/telemetry, and Hex-backed Rendro dependency proof.
- **108:** **PDF-08..PDF-09** — Rendro-first install/migration docs, advanced guide cleanup, package-doc and HexDocs verification, and final closeout proof.

**Outcome:** Phases **106–108** closed the **v1.34** Rendro Native Invoice PDF Default milestone with all `PDF-01..PDF-09` requirements satisfied.

**Archives:**

- **`.planning/milestones/v1.34-ROADMAP.md`**
- **`.planning/milestones/v1.34-REQUIREMENTS.md`**
- **`.planning/v1.34-v1.34-MILESTONE-AUDIT.md`**

---

## v1.33 Braintree Full Maturity (Planning)

**Planning opened:** 2026-05-01

**Phases planned:** **4** phases (**101–104**).

**Theme:** Achieve full Braintree maturity and parity with Stripe. Addresses critical gaps by building a first-party Accrue Portal/Checkout UI (since Braintree lacks hosted versions), local coupon/discount mapping, a custom metered usage engine, and evaluating Connect parity.

**Depends on:** **v1.32** shipped.

**Phase execution trees (planned):** **`.planning/milestones/v1.33-phases/`**

**Archives:**

- **`.planning/milestones/v1.33-ROADMAP.md`**
- **`.planning/milestones/v1.33-REQUIREMENTS.md`**

---

## v1.32 Braintree Production Parity (Shipped: 2026-05-01)

**Planning opened:** 2026-04-30

**Phases completed:** **4** phases (**97–100**).

**Theme:** Expand the Braintree integration (v1.31 "thin slice") to achieve deeper feature parity with Stripe for production usage, adhering to Accrue's "direct gateway" explicit-capability strategy.

**Depends on:** **v1.31** shipped.

**Phase execution trees:** **`.planning/milestones/v1.32-phases/097-advanced-subscription-lifecycle/`**, **`098-payment-method-crud-operator-admin/`**, **`099-refunds-and-invoice-parity/`**, **`100-billing-portal-semantics/`**.

**Key accomplishments:**

- **97:** **PROC-14**, **PROC-15** — Advanced Subscription Lifecycle (Braintree subscription mutations, plan swaps, pause/resume, and webhook convergence).
- **98:** **PROC-16**, **PROC-17** — Payment Method CRUD & Operator Admin for Braintree payment methods.
- **99:** **PROC-18**, **PROC-19** — Refunds and Invoice Parity for Braintree.
- **100:** **PROC-20** — Billing Portal Semantics (explicit capability rejection and documentation for Braintree self-serve portal).

**Outcome:** Phases **97–100** closed the **v1.32** Braintree Production Parity milestone.

**Archives:**

- **`.planning/milestones/v1.32-ROADMAP.md`**
- **`.planning/milestones/v1.32-REQUIREMENTS.md`**

---

## v1.31 PROC-08 Phase 1: boundary hardening + thin slice (Shipped: 2026-04-29)

**Planning opened:** 2026-04-28

**Phases completed:** **3** phases (**94–96**).

**Theme:** Deliberately reopen **PROC-08** after the `1.0.0` declaration by keeping Stripe as the default first-user story while starting the official dual-provider track. This milestone locks the processor capability model, chooses a Stripe-like target provider, hardens the official processor boundary, and ships one real second-provider vertical slice through the documented public facade. **FIN-03** remains out of scope.

**Depends on:** **v1.30** shipped.

**Research:** Milestone-internal — provider selection is an explicit output of Phase 94 rather than a prerequisite external milestone.

**Phase execution trees:** **`.planning/milestones/v1.31-phases/094-strategy-capability-matrix-target-lock/`**, **`095-official-processor-contract-conformance-harness/`**, **`096-chosen-second-provider-thin-slice/`**.

**Key accomplishments:**

- **94:** **PROC-09** — Strategy + capability matrix + target-provider lock.
- **95:** **PROC-10**, **PROC-11** — Official processor contract + conformance harness + boundary hardening.
- **96:** **PROC-12**, **PROC-13** — Chosen second-provider thin slice + public positioning updates.

**Outcome:** Phases **94–96** closed the **v1.31** PROC-08 phase 1 without leaking FIN-03.

**Archives:**

- **`.planning/milestones/v1.31-ROADMAP.md`**
- **`.planning/milestones/v1.31-REQUIREMENTS.md`**

---

## v1.30 `1.0.0` Declaration (Spine A) (Shipped: 2026-04-28)

**Planning opened:** 2026-04-26

**Phases completed:** **3** phases (**91–93**), with the linked **`accrue` / `accrue_admin` `1.0.0`** declaration closed on the same day as the publish proof.

**Theme:** Declare the stable **`1.0.0`** pair, complete the post-publish contract sweep, align the maintainer planning mirrors, and finish the dated post-1.0 maintainer pass. **No** **PROC-08** / **FIN-03**.

**Depends on:** **v1.29** shipped.

**Research:** Brownfield from the v1.11 / v1.23 / v1.28 release-continuity pattern, with the canonical linked publish proof living in **`092-VERIFICATION.md`**.

**Phase execution trees:** **`.planning/milestones/v1.30-phases/091-pre-publish-prep/`**, **`092-linked-1-0-0-publish-post-publish-contract-sweep/`**, **`093-hyg-mirror-inv-tag/`**.

**Key accomplishments:**

- **91:** **REL-06**, **REL-07**, **DOC-03**, **DOC-04** — `CHANGELOG` stable entries, `RELEASING.md` post-1.0 cadence, README stability flip, and explicit `PROC-08` / `FIN-03` non-goal reaffirmation. Evidence: **`091-VERIFICATION.md`** and Phase 91 summaries.
- **92:** **REL-05**, **PPX-09..12** — linked `1.0.0` Hex publish for both packages, ordered workflow proof, `release-manifest-ssot`, the six-script `docs-contracts-shift-left` bundle, and host/adoption parity at `1.0.0`. Canonical publish proof: **`092-VERIFICATION.md`**.
- **93:** **HYG-02**, **INV-07**, **REL-08** — planning mirrors aligned to the published pair, dated maintainer-closeout artifacts recorded, and the planning tag closed after the final milestone state landed.

**Outcome:** Phases **91–93** closed the **v1.30** `1.0.0` declaration without reopening public release-surface work beyond the proof already captured in **`092-VERIFICATION.md`**. No **PROC-08** / **FIN-03**.

**Archives:**

- Roadmap: [`milestones/v1.30-ROADMAP.md`](milestones/v1.30-ROADMAP.md)
- Requirements: [`milestones/v1.30-REQUIREMENTS.md`](milestones/v1.30-REQUIREMENTS.md)

**Git tag:** `v1.30`

**Next after ship:** Next milestone pending reprioritization; the `1.0.0` declaration is closed.

---

## v1.29 Mailglass Integration (Shipped: 2026-04-26)

**Planning opened:** 2026-04-25

**Phases completed:** **3** phases (**88–90**), **MG-01..MG-07** validated.

**Theme:** Replace `mjml_eex` and `phoenix_swoosh` with the [Mailglass](https://github.com/szTheory/mailglass) framework as a path dependency. Mailglass provides HEEx-native components (no Node MJML compile), an append-only event ledger, native database-level idempotency via `idempotency_key`, and a LiveView dev-preview dashboard mounted at `/dev/mail` in `accrue_admin`. **No** **PROC-08** / **FIN-03**.

**Depends on:** **v1.28** planning closure.

**Research:** Brownfield from v1.28's `phoenix_swoosh`/`mjml_eex` baseline; sibling Mailglass repo as the canonical reference.

**Phase execution trees:** **`.planning/milestones/v1.29-phases/088-mailglass-foundation/`**, **`089-proof-of-concept-templates-pipeline/`**, **`090-full-template-port-cleanup/`**.

**Key accomplishments:**

- **88:** **MG-01..MG-03** — Mailglass and `mailglass_admin` path deps; `/dev/mail` LiveView mounted via sibling scope; install + email guides updated for the three Mailglass migrations. **`088-VERIFICATION.md`** (5/5).
- **89:** **MG-04..MG-06** — `Accrue.Workers.Mailer` dispatches via `Mailglass.deliver/1` with explicit `idempotency_key` (Oban `unique: [period: 60]` removed); `Receipt` and `PaymentFailed` ported to Mailglass HEEx with PDF attachment preserved. **`089-01-SUMMARY.md`** / **`089-02-SUMMARY.md`**.
- **90:** **MG-07** — All 13 transactional templates Mailglass-backed (including `payment_succeeded`); `mjml_eex` + `phoenix_swoosh` removed from `accrue/mix.exs`; 26 legacy `.mjml.eex`/`.text.eex` assets deleted; `mix accrue.mail.preview`, `Accrue.Emails.HtmlBridge`, and `Accrue.Workers.Mailer.template_for/1` retired; `mailglass_cleanup_test` guards regressions; email guide rewritten around `/dev/email-preview`. **`090-VERIFICATION.md`** (6/6) + **`090-UAT.md`** (7/7 automated).

**Archives:**

- Roadmap: [`milestones/v1.29-ROADMAP.md`](milestones/v1.29-ROADMAP.md)
- Requirements: [`milestones/v1.29-REQUIREMENTS.md`](milestones/v1.29-REQUIREMENTS.md)

**Git tag:** `v1.29`

**Next after ship:** **`/gsd-new-milestone`** when the next era is ready.

---

## v1.28 Next linked publish continuity (Planning opened: 2026-04-24)

**Planning opened:** 2026-04-24

**Phases planned:** **2** phases (**86–87**), **PPX-05..08** + **INV-06**. **Phases 86–87** evidence **Complete** **2026-04-24** (**`086-VERIFICATION.md`**, **`087-VERIFICATION.md`**).

**Theme:** **Spine B** from strategic wrap-up plan — **post-publish contract alignment** on the **next linked Hex publish** for **`accrue` / `accrue_admin`** (same obligation family as **v1.23** **PPX-01..04**), then **INV-06** friction-inventory maintainer pass per inventory **revisit triggers**. **No** **PROC-08** / **FIN-03**; **not** a **1.0.0** declaration unless reprioritized.

**Depends on:** **v1.27** shipped.

**Research:** Skipped — brownfield **v1.23** pattern; prior **`.planning/research/SUMMARY.md`** context.

**Live artifacts:** **`.planning/REQUIREMENTS.md`**, **`.planning/ROADMAP.md`** (Phases **86–87**).

**Key accomplishments (Phase 86):**

- **86:** **PPX-05..08** — **`verify_package_docs`**, **`package_docs_verifier_test.exs`**, **`verify_adoption_proof_matrix`**, full **`docs-contracts-shift-left`** six-script bundle, **`.planning/`** **0.3.1** mirrors — **`milestones/v1.28-phases/086-post-publish-contract-alignment/086-VERIFICATION.md`**.

**v1.28 closure (planning):** **Phase 87** (**INV-06**) **Complete** **2026-04-24** — **`087-VERIFICATION.md`** + **`### v1.28 INV-06 maintainer pass (2026-04-24)`** in **`v1.17-FRICTION-INVENTORY.md`**. **Next forcing function:** **linked Hex publish** per **`RELEASING.md`** (outside this planning milestone’s in-repo scope).

---

## v1.27 Pre-1.0 closure narrative (Shipped: 2026-04-24)

**Planning opened:** 2026-04-24

**Phases completed:** **2** phases (**84–85**), inline verification.

**Theme:** **CLS-01..03** — integrator-facing **maintenance posture** + **`RELEASING.md`** / **`upgrade.md`** wrap-up semantics for the **`0.3.x`** line. **INV-05** — dated friction inventory maintainer pass **(b)** after **CLS** doc landings. **No** **PROC-08** / **FIN-03**; **no** Hex-release theme.

**Depends on:** **v1.26** shipped.

**Research:** Skipped — maintainer narrative + inventory certification (brownfield).

**Phase execution trees:** **`.planning/milestones/v1.27-phases/84-pre-1-0-closure-narrative/`**, **`85-friction-inventory-post-closure/`**.

**Key accomplishments:**

- **84:** **CLS-01..03** — root **`README.md`** **Maintenance posture**; **`accrue/README.md`** maturity link + **Stability** clarification; **`RELEASING.md`** **Pre-1.0 closure**; **`upgrade.md`** **Pre-1.0 wrap-up semantics** — **`084-VERIFICATION.md`**.
- **85:** **INV-05** — **`### v1.27 INV-05 maintainer pass (2026-04-24)`** in **`v1.17-FRICTION-INVENTORY.md`** + **`085-VERIFICATION.md`** verifier transcripts.

**Archives:**

- Roadmap: [`milestones/v1.27-ROADMAP.md`](milestones/v1.27-ROADMAP.md)
- Requirements: [`milestones/v1.27-REQUIREMENTS.md`](milestones/v1.27-REQUIREMENTS.md)

**Git tag:** `v1.27`

**Next after ship:** **`/gsd-new-milestone`** when the next era is ready.

---

## v1.26 First-hour billing facade spine (Shipped: 2026-04-24)

**Planning opened:** 2026-04-24

**Phases completed:** **2** phases (**82–83**), **3** plans total (**2+1**).

**Theme:** **INT-13** — **`Accrue.Billing.create_billing_portal_session/2`** on **First Hour** + **`examples/accrue_host` README** + **adoption proof matrix** + merge-blocking verifiers (same-PR discipline). **INV-04** — post-touch **`v1.17-FRICTION-INVENTORY.md`** maintainer certification path **(b)**. **No** **PROC-08** / **FIN-03**; **no** Hex-release theme unless amended.

**Depends on:** **v1.25** shipped.

**Research:** Skipped — brownfield integrator parity; prior **`.planning/research/SUMMARY.md`** context.

**Phase execution trees:** **`.planning/milestones/v1.26-phases/082-first-hour-portal-spine/`**, **`083-friction-inventory-post-touch/`**.

**Key accomplishments:**

- **82:** **INT-13** — telemetry anchor, First Hour portal paragraph, adoption matrix blocking row, host README observability capsule; **`verify_package_docs`** / **`verify_adoption_proof_matrix`** needles + **`082-VERIFICATION.md`** (**`082-01`**, **`082-02`**).
- **83:** **INV-04** path **(b)** — **`### v1.26 INV-04 maintainer pass (2026-04-24)`** in **`v1.17-FRICTION-INVENTORY.md`** + **`083-VERIFICATION.md`** verifier transcripts.

**Archives:**

- Roadmap: [`milestones/v1.26-ROADMAP.md`](milestones/v1.26-ROADMAP.md)
- Requirements: [`milestones/v1.26-REQUIREMENTS.md`](milestones/v1.26-REQUIREMENTS.md)

**Git tag:** `v1.26`

**Next after ship:** **`/gsd-new-milestone`** for **v1.27+** priorities.

---

## v1.25 Evidence-bound triad (friction + integrator + billing depth) (Shipped: 2026-04-24)

**Planning opened:** 2026-04-24

**Phases completed:** **3** phases (**79–81**), **3** plans total (**1+1+1**).

**Theme:** Post–**v1.24** **FRG-01** maintainer pass (**INV-03**); **`Accrue.Billing.create_checkout_session/2`** (**Fake** + **`:telemetry` / span**, **BIL-06**); **telemetry/catalog/changelog** + integrator needles (**BIL-07**, **INT-12**). **No** **PROC-08** / **FIN-03**.

**Depends on:** **v1.24** shipped.

**Research:** `.planning/research/SUMMARY.md` (milestone pass **2026-04-24**).

**Phase execution trees:** **`.planning/milestones/v1.25-phases/079-friction-inventory-maintainer-pass/`**, **`080-checkout-session-on-accrue-billing/`**, **`081-telemetry-truth-integrator-contracts/`**.

**Key accomplishments:**

- **79:** **INV-03** path **(b)** — dated maintainer certification + **`079-VERIFICATION.md`** verifier transcripts.
- **80:** **BIL-06** — **`create_checkout_session/2`** (+ **`!`**) + **Fake** **`checkout_session_facade_test.exs`** + **PII-safe** span metadata — **`080-VERIFICATION.md`**.
- **81:** **BIL-07** + **INT-12** — **`guides/telemetry.md`** / **`operator-runbooks.md`** / **`CHANGELOG`**; **First Hour**, host README, adoption matrix, **`verify_package_docs`**, **`verify_adoption_proof_matrix`** — **`081-VERIFICATION.md`**.

**Archives:**

- Roadmap: [`milestones/v1.25-ROADMAP.md`](milestones/v1.25-ROADMAP.md)
- Requirements: [`milestones/v1.25-REQUIREMENTS.md`](milestones/v1.25-REQUIREMENTS.md)

**Git tag:** `v1.25`

**Next after ship:** **`/gsd-new-milestone`** for **v1.26+** priorities.

---

## v1.24 Billing portal facade + customer PM operator surfaces (Shipped: 2026-04-24)

**Planning opened:** 2026-04-24

**Phases completed:** **3** phases (**76–78**), **6** plans total (**2+2+2**).

**Theme:** **ADM-13..ADM-16**, **BIL-04..BIL-05** — **`Accrue.Billing.create_billing_portal_session/2`** (+ **`!`**) with **Fake** + **`:telemetry` / span** parity; **`guides/telemetry.md`** / runbook / **CHANGELOG**; **customer** **`payment_methods`** **Copy** / **`ax-*`** / **VERIFY-01** / **`export_copy_strings`**. **No** **PROC-08** / **FIN-03**.

**Depends on:** **v1.23** shipped.

**Phase execution trees:** **`.planning/milestones/v1.24-phases/76-customer-pm-tab-inventory-copy-burn-down/`**, **`77-customer-pm-tab-verify-theme-copy-export/`**, **`78-billing-portal-on-accrue-billing-telemetry-truth/`**.

**Key accomplishments:**

- **76:** **ADM-13** inventory + **ADM-14** **`AccrueAdmin.Copy`** / **`ax-*`** burn-down — **`76-VERIFICATION.md`**.
- **77:** **ADM-15** VERIFY-01 Playwright + **axe**; **ADM-16** theme exceptions + **`export_copy_strings`** — **`77-VERIFICATION.md`**.
- **78:** **BIL-04** billing-portal facade + span coverage tests; **BIL-05** telemetry + runbook + **CHANGELOG** — **`78-VERIFICATION.md`**.

**Archives:**

- Roadmap: [`milestones/v1.24-ROADMAP.md`](milestones/v1.24-ROADMAP.md)
- Requirements: [`milestones/v1.24-REQUIREMENTS.md`](milestones/v1.24-REQUIREMENTS.md)

**Git tag:** `v1.24`

**Next after ship:** **`/gsd-new-milestone`** for **v1.25+** priorities.

---

## v1.23 Post-publish contract alignment (Shipped: 2026-04-24)

**Planning opened:** 2026-04-24

**Phases completed:** **1** phase (**75**), contract verification at published **0.3.1** (no new SemVer bump in-tree).

**Theme:** **PPX-01..PPX-04** — **`verify_package_docs`**, **`verify_adoption_proof_matrix`**, **docs-contracts-shift-left** (including **`verify_production_readiness_discoverability.sh`**), **`verify_v1_17_friction_research_contract.sh`** (five-row inventory); **`v1.17-P1-002`** **closed**. **Branch A**. **No** **PROC-08** / **FIN-03**.

**Depends on:** **v1.22** shipped.

**Phase execution tree:** [`milestones/v1.23-phases/75-post-publish-contract-alignment/`](milestones/v1.23-phases/75-post-publish-contract-alignment/)

**Key accomplishments:**

- **75:** **PPX-01..04** — local **`docs-contracts-shift-left`** bash suite green; **`scripts/ci/README.md`** triage text updated for **5** inventory rows; **`75-VERIFICATION.md`** sign-off.

**Archives:**

- Roadmap: [`milestones/v1.23-ROADMAP.md`](milestones/v1.23-ROADMAP.md)
- Requirements: [`milestones/v1.23-REQUIREMENTS.md`](milestones/v1.23-REQUIREMENTS.md)

**Git tag:** `v1.23`

**Next after ship:** **`/gsd-new-milestone`** for **v1.24+** priorities.

---

## v1.22 Production path discoverability (Shipped: 2026-04-24)

**Planning opened:** 2026-04-23

**Phases completed:** **1** phase (**74**), bootstrap verification (no multi-plan breakdown).

**Theme:** **PRS-01..PRS-03** — repository root + **`accrue` package README** discoverability for **`accrue/guides/production-readiness.md`**; merge-blocking **`scripts/ci/verify_production_readiness_discoverability.sh`** for **§1–§10** checklist spine stability. **No** **PROC-08** / **FIN-03**.

**Depends on:** **v1.21** shipped.

**Phase execution tree:** [`milestones/v1.22-phases/74-production-path-discoverability/`](milestones/v1.22-phases/74-production-path-discoverability/)

**Key accomplishments:**

- **74:** **PRS-01..PRS-03** — root **`README.md`** + **`accrue/README.md`** ship-path links; **`verify_production_readiness_discoverability.sh`** in **`docs-contracts-shift-left`**; **`scripts/ci/README.md`** PRS gate map + co-update rule.

**Archives:**

- Roadmap: [`milestones/v1.22-ROADMAP.md`](milestones/v1.22-ROADMAP.md)
- Requirements: [`milestones/v1.22-REQUIREMENTS.md`](milestones/v1.22-REQUIREMENTS.md)

**Git tag:** `v1.22`

**Next after ship:** **`/gsd-new-milestone`** for **v1.23+** priorities.

---

## v1.21 Maturity posture and diminishing returns (Shipped: 2026-04-23)

**Planning opened:** 2026-04-23

**Phases completed:** **2** phases (**72–73**), bootstrap verification (no multi-plan breakdown).

**Theme:** **MAT-01..MAT-02** — **`.planning/PROJECT.md`** library maintenance posture + **`accrue/guides/maturity-and-maintenance.md`** + cross-links; **INT-11** — **`scripts/ci/README.md`** capsule parity checklist; **`.planning/research/v1.17-FRICTION-INVENTORY.md`** row **`v1.17-P2-001`** closed. **No** **PROC-08** / **FIN-03**.

**Depends on:** **v1.20** shipped.

**Phase execution trees (v1.21):** [`.planning/milestones/v1.21-phases/72-maturity-posture/`](milestones/v1.21-phases/72-maturity-posture/), [`73-capsule-parity-checklist/`](milestones/v1.21-phases/73-capsule-parity-checklist/)

**Key accomplishments:**

- **72:** **MAT-01..MAT-02** — maintenance bar + integrator-facing **maturity-and-maintenance** guide + **First Hour** / **production-readiness** / **CONTRIBUTING** links.
- **73:** **INT-11** — contributor same-PR checklist; **v1.17-P2-001** **closed**.

**Archives:**

- Roadmap: [`milestones/v1.21-ROADMAP.md`](milestones/v1.21-ROADMAP.md)
- Requirements: [`milestones/v1.21-REQUIREMENTS.md`](milestones/v1.21-REQUIREMENTS.md)

**Git tag:** `v1.21`

**Next after ship:** **`/gsd-new-milestone`** for **v1.22+** priorities.

---

## v1.20 Professional adoption confidence (Shipped: 2026-04-24)

**Planning opened:** 2026-04-24

**Phases completed:** **2** phases (**70–71**), bootstrap verification (no multi-plan breakdown).

**Theme:** Post–**0.3.1** **friction inventory** evidence pass (**INV-01..02**) — closes **`v1.17-P1-001`** with **v1.19** **PRF** pointers + **production readiness** doc spine (**PRD-01..02**) cross-linked from **First Hour**, **configuration**, and **`examples/accrue_host` README**. **No** **PROC-08** / **FIN-03**.

**Depends on:** **v1.19** shipped; **v1.19** execution trees under [`.planning/milestones/v1.19-phases/`](milestones/v1.19-phases/).

**Phase execution trees (v1.20):** [`.planning/milestones/v1.20-phases/70-friction-evidence-refresh/`](milestones/v1.20-phases/70-friction-evidence-refresh/), [`71-production-readiness-spine/`](milestones/v1.20-phases/71-production-readiness-spine/)

**Key accomplishments:**

- **70:** **`v1.17-P1-001`** closed in **`.planning/research/v1.17-FRICTION-INVENTORY.md`** with **v1.19** **PRF** evidence pointers + maintainer revisit note (**INV-01..02**).
- **71:** **`accrue/guides/production-readiness.md`** checklist spine + **First Hour** / **configuration** / **`examples/accrue_host` README** cross-links (**PRD-01..02**).

**Archives:**

- Roadmap: [`milestones/v1.20-ROADMAP.md`](milestones/v1.20-ROADMAP.md)
- Requirements: [`milestones/v1.20-REQUIREMENTS.md`](milestones/v1.20-REQUIREMENTS.md)

**Git tag:** `v1.20`

**Next after ship:** **`/gsd-new-milestone`** for **v1.21+** priorities.

---

## v1.19 Release continuity + proof resilience (Shipped: 2026-04-24)

**Planning opened:** 2026-04-23

**Phases completed:** **3** phases (**67–69**), **5** plans (**67-01**, **68-01**..**68-02**, **69-01**..**69-02**).

**Theme:** Proof-contract hardening (**PRF-01..02**, closes **v1.17-P1-001** drift class) → linked **Hex** publish **0.3.1** (**REL-01..03**) → **First Hour** / **`verify_package_docs`** + **`.planning/`** Hex mirrors (**DOC-01..02**, **HYG-01**). **No** **PROC-08** / **FIN-03**.

**Milestone audit:** No standalone **`v1.19-MILESTONE-AUDIT.md`**; closure used **`REQUIREMENTS.md`** (8/8 **Complete**), per-phase **`*-VERIFICATION.md`**, **`audit-open`** (all clear), and merge-blocking **`verify_package_docs`** / adoption-proof CI.

**Key accomplishments:**

- **67-01:** Merge-blocking **`verify_adoption_proof_matrix.sh`** needles for Layer C + **ORG-05** / **ORG-06**; contributor triage in **`scripts/ci/README.md`**; matrix co-commit with script (**PRF-01..02**).
- **68-01:** **`RELEASING.md`** publish ordering (**`publish-accrue-admin`** **`needs:`**), manual-merge default path, changelog ship-boundary section (**REL-01..REL-02** docs).
- **68-02:** **`68-VERIFICATION.md`** URL-first **0.3.1** Hex + GitHub tag + changelog-at-tag evidence; **REL-01..REL-03** traceability closed.
- **69-01:** **`69-VERIFICATION.md`** DOC integrator proof; **`verify_package_docs.sh`** + **`package_docs_verifier_test.exs`** green on **0.3.1** pins (**DOC-01..02**).
- **69-02:** **PROJECT** / **MILESTONES** / **STATE** **0.3.1** mirror pass; **HYG-01** closed.

**Depends on:** **v1.18** shipped; **v1.18** Phase **66** tree under [`.planning/milestones/v1.18-phases/66-onboarding-confidence/`](milestones/v1.18-phases/66-onboarding-confidence/).

**Phase execution trees (v1.19):** [`milestones/v1.19-phases/67-proof-contracts/`](milestones/v1.19-phases/67-proof-contracts/), [`68-release-train/`](milestones/v1.19-phases/68-release-train/), [`69-doc-planning-mirrors/`](milestones/v1.19-phases/69-doc-planning-mirrors/)

**Archives:**

- Roadmap: [`milestones/v1.19-ROADMAP.md`](milestones/v1.19-ROADMAP.md)
- Requirements: [`milestones/v1.19-REQUIREMENTS.md`](milestones/v1.19-REQUIREMENTS.md)

**Git tag:** `v1.19`

**Next after ship:** **`/gsd-new-milestone`** when **v1.20+** priorities are set.

---

## v1.18 Onboarding confidence (Shipped: 2026-04-23)

**Planning opened:** 2026-04-23

**Phases completed:** **1** phase (**66**), **3** plans (**66-01**..**66-03**).

**Theme:** Proof-first onboarding confidence — **UAT-01..UAT-05** (archived **62-UAT** baseline + friction/north-star SSOT contracts) + **PROOF-01** (adoption matrix / walkthrough / **`verify_adoption_proof_matrix.sh`** alignment). **No** **PROC-08** / **FIN-03**.

**Milestone audit:** No standalone **`v1.18-MILESTONE-AUDIT.md`**; closure used **`REQUIREMENTS.md`** (6/6 **Satisfied**), **`66-VERIFICATION.md`** (`status: passed`), **`audit-open`** (all clear), and merge-blocking doc-contract CI.

**Key accomplishments:**

- **66-01:** **`66-VERIFICATION.md`** matrix for **UAT-01..UAT-05** + **`62-UAT.md`** supersession banner (body preserved under **`milestones/v1.17-phases/`**).
- **66-02:** **`STATE.md`** deferred **62-UAT** row **closed**; **`verify_v1_17_friction_research_contract.sh`** archive gate + ExUnit + CI README row; **UAT-04** proof refreshed.
- **66-03:** **PROOF-01** semantic alignment (matrix, walkthrough, host README, verifier, org matrix ExUnit); **`.planning/REQUIREMENTS.md`** traceability closed.

**v1.17 phase tree archive:** [`.planning/milestones/v1.17-phases/`](milestones/v1.17-phases/)

**Archives:**

- Roadmap: [`milestones/v1.18-ROADMAP.md`](milestones/v1.18-ROADMAP.md)
- Requirements: [`milestones/v1.18-REQUIREMENTS.md`](milestones/v1.18-REQUIREMENTS.md)

**Git tag:** `v1.18`

**Next after ship:** **`/gsd-discuss-phase 68`** / **`/gsd-plan-phase 68`** (**v1.19**).

---

## v1.17 Friction-led developer readiness (Shipped: 2026-04-23)

**Planning opened:** 2026-04-23

**Phases completed:** **4** phases (**62–65**), **8** plans (Phase **64** ships verification + research closure on an empty billing **P0** queue).

**Known deferred items at close:** **1** (see [STATE.md](STATE.md) § **Deferred Items** — Phase **62** **UAT** scenarios acknowledged at milestone close).

**Key accomplishments:**

- **Phase 62 (FRG-01..FRG-03):** **`research/v1.17-FRICTION-INVENTORY.md`** + **`v1.17-north-star.md`**; scoped **FRG-03** backlog anchors for **INT-10** / **BIL-03** / **ADM-12** with explicit empty-queue rows where applicable.
- **Phase 63 (INT-10):** **First Hour** + package README **Hex vs branch** skimmable facts (**63-01**); stable **`[host-integration] phase=…`** stderr slugs + contributor map (**63-02**); remaining **INT-10** slice per **63-VERIFICATION.md** (**63-03**).
- **Phase 64 (BIL-03):** Maintainer-signed empty billing **P0** queue certification + **`64-VERIFICATION.md`** + friction research contract tests green.
- **Phase 65 (ADM-12):** **`65-VERIFICATION.md`** + inventory maintainer line; empty admin **P0** queue certification aligned to **63/64** verification table family.

**Theme:** Triage-led **P0** closure — **no** **PROC-08** / **FIN-03**; no broad **v1.16**-style sweeps without **FRG-01** evidence.

**Milestone audit:** No standalone **`v1.17-MILESTONE-AUDIT.md`**; closure used **`REQUIREMENTS.md`** (6/6 **Complete**), per-phase **`*-VERIFICATION.md`**, and **`audit-open`** with the **Phase 62 UAT** gap acknowledged in **STATE.md**.

**Note:** **`.planning/phases/`** was cleared (**`phases.clear`**, **43** trees) at milestone open; phases **62–65** directories were created by **`/gsd-plan-phase`**.

**Archives:**

- Roadmap: [`milestones/v1.17-ROADMAP.md`](milestones/v1.17-ROADMAP.md)
- Requirements: [`milestones/v1.17-REQUIREMENTS.md`](milestones/v1.17-REQUIREMENTS.md)

**Git tag:** `v1.17`

**Next after ship:** **`/gsd-new-milestone`** when priorities for **v1.18+** are set.

---

## v1.16 Integrator + proof continuity (Shipped: 2026-04-23)

**Planning opened:** 2026-04-23

**Phases completed:** 3 phases (**59–61**), **6** plans

**Key accomplishments:**

- **Phase 59 (INT-06):** **First Hour** trust boundary + **Sigra** capsule framing; **quickstart** auth routing hub; **CONTRIBUTING** doc preflight trio; **`verify_package_docs.sh`** quickstart hub + capsule structure + **`package_docs_verifier_test`** coverage.
- **Phase 60 (INT-07):** **Adoption proof matrix** + **evaluator walkthrough** trust/versioning stub with walkthrough ↔ matrix traceability; **`scripts/ci/README.md`** INT-06/INT-07 contributor map rows; **CONTRIBUTING** routes editors to the map.
- **Phase 61 (INT-08, INT-09):** **`verify_package_docs.sh`** **INT-08** ownership + root **README** merge-blocking line pin; **INT-09** **MILESTONES** / **PROJECT** Current State dual-track (**`@version`** vs **public Hex**) + CI README row + **CONTRIBUTING** pre-publish **`mix deps.get`** sharp edge.

**Theme:** Integrator + proof continuity after **v1.15** — **no** **PROC-08** / **FIN-03**; **no** new billing primitives.

**Milestone audit:** No standalone `v1.16-MILESTONE-AUDIT.md`; closure used **`audit-open`** (all clear), merge-blocking doc verifiers, and requirements archive (**4/4 Complete**).

**Phase directories:** **`phases.clear` not run** — preserves prior phase trees under `.planning/phases/`.

**Archives:**

- Roadmap: [`milestones/v1.16-ROADMAP.md`](milestones/v1.16-ROADMAP.md)
- Requirements: [`milestones/v1.16-REQUIREMENTS.md`](milestones/v1.16-REQUIREMENTS.md)

**Git tag:** `v1.16`

**Next after ship:** **`/gsd-new-milestone`** when priorities for **v1.17+** are set.

---

## v1.15 Release / trust semantics (Shipped: 2026-04-23)

**Planning opened:** 2026-04-23

**Phases completed:** 2 phases (57–58), docs-only (no new `.planning/phases/57-*` / `58-*` trees)

**Forcing function:** **B** (release / trust semantics — adoption readiness sanity check).

**Key accomplishments:**

- **Phase 57 (TRT-01..TRT-03):** **`accrue/guides/upgrade.md`** replaces stale **`v0.1.2` baseline** with **Hex + `mix.exs` `@version`** SSOT and **`.planning/` vs SemVer** explanation; **`RELEASING.md`** + root **`README.md`** call out internal milestone labels vs consumer pins.
- **Phase 58 (TRT-04):** **`examples/accrue_host/README.md`** **Sigra vs `Accrue.Auth`** callout above the fold; **`accrue/README.md`** **Stability** clarifies **`0.x`** deprecation discipline + **`RELEASING`** appendix; **`scripts/ci/verify_package_docs.sh`** aligned to current **`accrue_admin/mix.exs`** **extras** list.

**Theme:** Evaluator **trust** without new billing primitives — **no** **PROC-08** / **FIN-03**.

**Milestone audit:** No standalone `v1.15-MILESTONE-AUDIT.md`; closure used **`audit-open`** (all clear), **`verify_package_docs`**, package docs ExUnit, and requirements archive (**4/4 Complete**).

**Archives:**

- Roadmap: [`milestones/v1.15-ROADMAP.md`](milestones/v1.15-ROADMAP.md)
- Requirements: [`milestones/v1.15-REQUIREMENTS.md`](milestones/v1.15-REQUIREMENTS.md)

**Git tag:** `v1.15`

**Next after ship:** **`/gsd-new-milestone`** when priorities for **v1.16+** are set.

---

## v1.14 Companion admin + billing depth (Shipped: 2026-04-23)

**Planning opened:** 2026-04-22

**Phases completed:** 3 phases (54–56), **6** plans

**Key accomplishments:**

- **Phase 54 (ADM-07, ADM-08):** **`guides/core-admin-parity.md`** router-derived **ADM-07** matrix; **`AccrueAdmin.Copy.Invoice`** + **`InvoicesLive`** / **`InvoiceLive`** operator chrome burn-down on the invoice money-primary spine.
- **Phase 55 (ADM-09..ADM-11):** Merge-blocking **VERIFY-01** **`core-admin-invoices-*`** flows; host **E2E** deterministic **`invoice_id`**; **`verify_core_admin_invoice_verify_ids.sh`**; **`theme-exceptions.md`** + **`export_copy_strings`** / **`copy_strings.json`** hygiene and core list **org scoping** fixes.
- **Phase 56 (BIL-01, BIL-02):** **`Accrue.Billing.list_payment_methods/2`** and **`!/2`** with **`span_billing(:payment_method, :list, …)`**, Fake **`payment_method_list_test.exs`**, **`guides/telemetry.md`** + **CHANGELOG** + installer **`billing.ex.eex`** + **`first_hour.md`** alignment.

**Theme:** **Core `accrue_admin`** parity on money-primary surfaces, then **one** scoped **Billing** read API + honest telemetry/docs — **no** **PROC-08** / **FIN-03**; **integrator** and **Hex release-train** milestones **explicitly later**.

**Milestone audit:** No standalone `v1.14-MILESTONE-AUDIT.md`; closure used per-phase verification, **`ROADMAP.md`** progress table, and requirements archive (**7/7 Complete**).

**Known deferred items at close:** same **audit-open** carry-forward as prior closes (see `.planning/STATE.md` § Deferred Items).

**Phase directories:** **`phases.clear` not run** — preserves **1–53** trees under `.planning/phases/`.

**Archives:**

- Roadmap: [`milestones/v1.14-ROADMAP.md`](milestones/v1.14-ROADMAP.md)
- Requirements: [`milestones/v1.14-REQUIREMENTS.md`](milestones/v1.14-REQUIREMENTS.md)

**Git tag:** `v1.14`

**Next after ship:** `/gsd-new-milestone` when priorities for **v1.15+** are set.

---

## v1.13 Integrator path + secondary admin parity (Shipped: 2026-04-23)

**Planning opened:** 2026-04-22

**Phases completed:** 3 phases (51–53), **8** plans

**Key accomplishments:**

- **Phase 51 (INT-01..INT-03):** Single **First Hour** ↔ **`accrue_host` README** integrator spine with H/M/R capsules; repo-root **VERIFY-01** discoverability; **troubleshooting** / webhooks anchors with stable slugs and bounded first-run failure callouts.
- **Phase 52 (INT-04, INT-05, AUX-01, AUX-02):** Honest **adoption proof matrix** + **Hex** / **`verify_package_docs`** alignment; **`AccrueAdmin.Copy.Coupon`** + **`Copy.PromotionCode`** with LiveView + ExUnit literal discipline on coupon/promo paths.
- **Phase 53 (AUX-03..AUX-06):** **`AccrueAdmin.Copy.Connect`** + **`Copy.BillingEvent`** for Connect/events surfaces; **theme-exceptions** note; **VERIFY-01** Playwright + **axe** on auxiliary mounted routes; **`export_copy_strings`** allowlist + **`copy_strings.json`** regeneration.

**Theme:** **Integrator golden path** docs + **auxiliary admin** parity with **`AccrueAdmin.Copy`**, **`ax-*`**, and **VERIFY-01** — **no** **PROC-08** / **FIN-03** / new UI kits.

**Milestone audit:** No standalone `v1.13-MILESTONE-AUDIT.md`; closure used per-phase verification, **`ROADMAP.md`** shipped table, and requirements archive (**11/11 Complete**).

**Known deferred items at close:** same **audit-open** carry-forward as prior closes (see `.planning/STATE.md` § Deferred Items).

**Phase directories:** **`phases.clear` not run** — preserves **1–50** trees under **`.planning/phases/`** for traceability.

**Archives:**

- Roadmap: [`milestones/v1.13-ROADMAP.md`](milestones/v1.13-ROADMAP.md)
- Requirements: [`milestones/v1.13-REQUIREMENTS.md`](milestones/v1.13-REQUIREMENTS.md)

**Git tag:** `v1.13`

**Next after ship:** `/gsd-new-milestone` when priorities for **v1.14+** are set.

---

## v1.12 Admin & operator UX (Shipped: 2026-04-22)

**Planning opened:** 2026-04-22

**Phases completed:** 3 phases (48–50), **6** plans

**Key accomplishments:**

- **Phase 48 (ADM-01):** Dashboard **MeterEvent** terminal-failed KPI with honest **`/events`** deep link and **`AccrueAdmin.Copy`**-backed operator strings.
- **Phase 49 (ADM-02, ADM-03):** **SubscriptionLive** drill parity (**`ScopedPath`**, related billing card); automated drill href proofs at admin + mounted host; README **router vs sidebar** note.
- **Phase 50 (ADM-04..ADM-06):** **`AccrueAdmin.Copy.Subscription`** + LiveView migration; **`theme-exceptions.md`** register + contributor checklist; **`mix accrue_admin.export_copy_strings`** with CI **`copy_strings.json`**; VERIFY-01 **subscriptions** axe/spec fed from exported copy.

**Theme:** Post-metering **admin signals**, **drill/nav** polish, **Copy + token** discipline, **VERIFY-01** gates on touched mounted paths — **no** **PROC-08** / **FIN-03**.

**Milestone audit:** No standalone `v1.12-MILESTONE-AUDIT.md`; closure used per-phase **`*-VERIFICATION.md`** / **`50-VERIFICATION.md`** and requirements traceability (6/6 Complete).

**Known deferred items at close:** same **audit-open** carry-forward as prior closes (see `.planning/STATE.md` § Deferred Items).

**Phase directories:** **`phases.clear` not run** — preserves **40–50** trees under **`.planning/phases/`** for traceability.

**Archives:**

- Roadmap: [`milestones/v1.12-ROADMAP.md`](milestones/v1.12-ROADMAP.md)
- Requirements: [`milestones/v1.12-REQUIREMENTS.md`](milestones/v1.12-REQUIREMENTS.md)

**Git tag:** `v1.12`

**Next after ship:** `/gsd-new-milestone` when priorities for **v1.13+** are set.

---

## v1.11 Public Hex release + post-release continuity (Shipped: 2026-04-22)

**Planning opened:** 2026-04-22

**Phases:** **46–47** (see root `.planning/ROADMAP.md`) — **6** plans total, **Complete 2026-04-22**.

**Theme:** Publish **`accrue`** / **`accrue_admin`** to Hex via Release Please **linked versions**, then align **`RELEASING.md`**, **`first_hour`**, **`verify_package_docs`**, and planning Hex version callouts. **PROC-08** / **FIN-03** remain non-goals.

**Current public Hex (lockstep):** **`accrue` 0.3.0** and **`accrue_admin` 0.3.0** — mirror **`accrue/mix.exs`** / **`accrue_admin/mix.exs`** **`@version`** (not a second SSOT).

**Requirements:** archived in [`milestones/v1.11-REQUIREMENTS.md`](milestones/v1.11-REQUIREMENTS.md) (**REL-**, **DOC-**, **HYG-**); all **7/7** complete.

**Next after ship:** `/gsd-discuss-phase 48` or `/gsd-new-milestone` for the next implementation slice.

**Archives:**

- Roadmap: [`milestones/v1.11-ROADMAP.md`](milestones/v1.11-ROADMAP.md)
- Requirements: [`milestones/v1.11-REQUIREMENTS.md`](milestones/v1.11-REQUIREMENTS.md)

**Git tag:** `v1.11`

---

## v1.10 Metered usage + Fake parity (Shipped: 2026-04-22)

**Phases completed:** 3 phases (43–45), **10** plans

**Key accomplishments:**

- **Phase 43 (MTR-01..MTR-03):** Public `Accrue.Billing.report_usage` NimbleOptions + ExDoc SSOT; `accrue_meter_events` lifecycle semantics; Fake happy-path determinism without private-module assertions for ordinary cases.
- **Phase 44 (MTR-04..MTR-06):** Guarded `MeterEvents` failure + `meter_reporting_failed` telemetry (`:sync`, `:reconciler`, `:webhook`); idempotent retries on terminal rows; reconciler + webhook meter error coverage aligned to `DefaultHandler`.
- **Phase 45 (MTR-07..MTR-08):** `guides/metering.md` for public vs internal vs processor boundaries; `guides/telemetry.md` + `guides/operator-runbooks.md` alignment for metering failure sources.

**Theme:** Usage metering provable on **Fake** in CI with stable ops telemetry keys; **PROC-08** / **FIN-03** remain non-goals.

**Milestone audit:** No standalone `v1.10-MILESTONE-AUDIT.md`; closure used **research/v1.10-METERING-SPIKE.md**, per-phase verification, and requirements traceability (8/8 Complete).

**Known deferred items at close:** same **audit-open** carry-forward as prior closes (see `.planning/STATE.md` § Deferred Items).

**Archives:**

- Roadmap: [`milestones/v1.10-ROADMAP.md`](milestones/v1.10-ROADMAP.md)
- Requirements: [`milestones/v1.10-REQUIREMENTS.md`](milestones/v1.10-REQUIREMENTS.md)

**Git tag:** `v1.10`

---

## v1.9 Observability & operator runbooks (Shipped: 2026-04-22)

**Phases completed:** 3 phases (40–42), **8** plans

**Key accomplishments:**

- **Phase 40 (OBS-01, OBS-03, OBS-04):** Authoritative `guides/telemetry.md` ops catalog with measurements/metadata; firehose vs ops split; `OpsEventContractTest` anti-drift; `[:accrue, :ops, :webhook_dlq, :dead_lettered]` on exhausted dispatch; gap audit §1 reconciled in guide + research doc.
- **Phase 41 (OBS-02, TEL-01):** `MetricsOpsParityTest` (or documented omissions) vs ops signals; cross-domain host `Telemetry` example in docs + `examples/accrue_host`.
- **Phase 42 (RUN-01):** `accrue/guides/operator-runbooks.md` (Oban topology, Stripe verification, D-09 mini-playbooks); `telemetry.md` preface and row-level links to runbooks.

**Theme:** Telemetry discoverability, metrics wiring parity, operator first-response runbooks — **no** new billing primitives. **PROC-08** / **FIN-03** remain non-goals.

**Research:**

- [`.planning/research/v1.9-TELEMETRY-GAP-AUDIT.md`](research/v1.9-TELEMETRY-GAP-AUDIT.md)
- [`.planning/research/v1.10-METERING-SPIKE.md`](research/v1.10-METERING-SPIKE.md) (input to **v1.10+**)

**Milestone audit:** No standalone `v1.9-MILESTONE-AUDIT.md`; closure used gap-audit research, per-phase verification, and requirements traceability (6/6 Complete).

**Known deferred items at close:** same **audit-open** carry-forward as prior closes (see `.planning/STATE.md` § Deferred Items).

**Archives:**

- Roadmap: [`milestones/v1.9-ROADMAP.md`](milestones/v1.9-ROADMAP.md)
- Requirements: [`milestones/v1.9-REQUIREMENTS.md`](milestones/v1.9-REQUIREMENTS.md)

**Git tag:** `v1.9`

---

## v1.8 Org billing recipes & host integration depth (Shipped: 2026-04-22)

**Phases completed:** 3 phases (37–39), **8** plans

**Key accomplishments:**

- **Phase 37 (ORG-05, ORG-06):** Single `organization_billing.md` spine for session → billable + ORG-03; phx.gen.auth checklist; installer/README/quickstart/finance-handoff discoverability and guide tests.
- **Phase 38 (ORG-07, ORG-08):** Pow-oriented recipe with maintenance honesty; custom org obligations, admin scoping, webhook replay alignment, and ORG-03 anti-pattern table.
- **Phase 39 (ORG-09):** Adoption proof matrix non-Sigra org archetype; merge-blocking `verify_adoption_proof_matrix.sh`; contributor map in `scripts/ci/README.md`; guide + ExUnit gates from `accrue` package.

**Theme:** Deferred **ORG-04** — non-Sigra org billing recipes + VERIFY/adoption-proof alignment. **PROC-08** and **FIN-03** remain out of scope.

**Known deferred items at close:** same **audit-open** carry-forward as prior closes (see `.planning/STATE.md` § Deferred Items).

**Archives:**

- Roadmap: [`milestones/v1.8-ROADMAP.md`](milestones/v1.8-ROADMAP.md)
- Requirements: [`milestones/v1.8-REQUIREMENTS.md`](milestones/v1.8-REQUIREMENTS.md)

**Git tag:** `v1.8`

---

## v1.7 Adoption DX + operator admin depth (Shipped: 2026-04-21)

**Phases completed:** 5 phases (32–36), **14** plans

**Key accomplishments:**

- **Phase 32–33 (ADOPT):** VERIFY-01 reachable within two hops from the repo root; host README single authoritative Fake-first subsection; guides cross-linked; installer rerun semantics + doc anchors enforced by verifiers; CI/docs keep merge-blocking vs advisory Stripe lanes without renaming job ids.
- **Phase 34 (OPS-01..03):** Operator home KPIs with deep links; customer→invoice drill and invoice breadcrumbs; `AccrueAdmin.Nav` labels/order aligned with README **Admin routes** inventory.
- **Phase 35 (OPS-04..05):** Dashboard surfaces stay on `ax-*` / tokens; operator-visible strings centralized in `AccrueAdmin.Copy` with Playwright + ExUnit alignment (`copy_dashboard.js` where needed).
- **Phase 36:** Three-source traceability for Phase 32–33 plans; `scripts/ci/README.md` maps ADOPT-01..06 to owning verifiers + `[verify_package_docs]` stderr prefix; dual-contract notes in `accrue/guides/testing.md`; forward-coupling doc for OPS-03..05.

**Verification:** `32-VERIFICATION.md` through `36-VERIFICATION.md` (all **passed**).

**Milestone audit:** [`milestones/v1.7-MILESTONE-AUDIT.md`](milestones/v1.7-MILESTONE-AUDIT.md) — **passed** (refreshed 2026-04-21).

**Known deferred items at close:** same **audit-open** carry-forward as prior closes (2 missing quick-task stubs + Phase 21 UAT metadata); see `.planning/STATE.md` § Deferred Items.

**Archives:**

- Roadmap: [`milestones/v1.7-ROADMAP.md`](milestones/v1.7-ROADMAP.md)
- Requirements: [`milestones/v1.7-REQUIREMENTS.md`](milestones/v1.7-REQUIREMENTS.md)
- Audit: [`milestones/v1.7-MILESTONE-AUDIT.md`](milestones/v1.7-MILESTONE-AUDIT.md)

**Git tag:** `v1.7`

---

## v1.6 Admin UI / UX polish (Shipped: 2026-04-20)

**Phases completed:** 5 phases (25–29), 16 plans

**Key accomplishments:**

- Maintainer route matrix, component coverage vs `ComponentKitchenLive`, and Phase 20/21 UI-SPEC alignment tables shipped for v1.6 (INV-01..03); see **`.planning/milestones/v1.6-ROADMAP.md`** — prior **`25-admin-ux-inventory`** tree in **git history** after **2026-04-23** `.planning/phases/` prune.
- Money indexes, detail pages, and webhook surfaces aligned to `ax-*` hierarchy and typography; theme tokens default with documented exceptions (UX-01..04).
- Plain-language empty/error/confirm copy plus `AccrueAdmin.Copy` module for stable Playwright and LiveView literals (COPY-01..03).
- Step-up focus, table captions on customers/webhooks, VERIFY-01 axe (serious/critical) on mounted admin, and verification notes for contrast (A11Y-01..04).
- Mobile overflow/nav assertions, `verify01-admin-mobile.spec.js`, and README **Mounted admin — mobile shell** documentation for VERIFY-01 (MOB-01..03).

**Verification:** Phase `25-VERIFICATION.md`, `26-VERIFICATION.md`, `28-VERIFICATION.md`, `29-VERIFICATION.md`; host Playwright mobile + desktop gates per existing CI.

**Known deferred items at close:** 3 (see `.planning/STATE.md` § Deferred Items — `audit-open` at milestone close, acknowledged under yolo workflow).

**Archives:**

- Roadmap: [`milestones/v1.6-ROADMAP.md`](milestones/v1.6-ROADMAP.md)
- Requirements: [`milestones/v1.6-REQUIREMENTS.md`](milestones/v1.6-REQUIREMENTS.md)

---

## v1.6 audit gap closure — post-ship (Closed: 2026-04-21)

**Phases completed:** 2 phases (30–31), 5 plans (2 + 3)

**Key accomplishments:**

- **Phase 30 — Audit corpus:** COPY-01..03 requirement coverage table added to `27-VERIFICATION.md`; `requirements-completed` YAML backfilled on all Phase **26** and **29** plan summaries for strict 3-source traceability.
- **Phase 31 — Advisory integration:** VERIFY-01 README/CI contract enforces mobile spec anchors and `npm run e2e:mobile`; step-up modal operator chrome uses `AccrueAdmin.Copy`; fixture Playwright + `accrue_admin` browser workflow + README align on host VERIFY-01 as the merge-blocking mounted-admin path.

**Verification:** Phase summaries `30-01`, `30-02`, `31-01`..`31-03`; milestone audit refreshed to **passed** in [`milestones/v1.6-MILESTONE-AUDIT.md`](milestones/v1.6-MILESTONE-AUDIT.md).

**Known deferred items at planning line close:** 3 (`audit-open` 2026-04-21 — same carry-forward class as v1.6 ship: Phase 21 UAT metadata + two missing quick-task stubs; acknowledged per `/gsd-complete-milestone`, see `.planning/STATE.md` § Deferred Items).

**Git tag:** Existing **`v1.6`** tag unchanged (no duplicate tag); this slice is planning/audit closure only.

---

## v1.5 Adoption proof hardening (Shipped: 2026-04-18)

**Phases completed:** 1 phase (24), documentation-only execution

**Key accomplishments:**

- Host adoption proof matrix (`examples/accrue_host/docs/adoption-proof-matrix.md`) tying Fake VERIFY-01, bounded/full ExUnit, Playwright, and advisory Stripe test-mode parity.
- Evaluator screen-recording checklist (`evaluator-walkthrough-script.md`) linked from the host README.
- README VERIFY-01 contract extended; CI job display name clarifies Stripe test mode; `accrue/guides/testing.md` and `guides/testing-live-stripe.md` cross-linked for contributor clarity.

**Verification:** `verify_verify01_readme_contract.sh` + existing `mix test` for `accrue` docs guide tests.

**Known deferred items at close:** 3 (see `.planning/STATE.md` § Deferred Items — `audit-open` carry-forward).

**Archives:**

- Roadmap: [`milestones/v1.5-ROADMAP.md`](milestones/v1.5-ROADMAP.md)
- Requirements: [`milestones/v1.5-REQUIREMENTS.md`](milestones/v1.5-REQUIREMENTS.md)

---

## v1.4 Ecosystem stability + demo visuals (Shipped: 2026-04-17)

**Phases completed:** 1 phase (23), 2 plans

**Key accomplishments:**

- `lattice_stripe` lockfile refresh across monorepo packages on latest 1.1.x.
- Visual walkthrough (`e2e:visuals`), CI screenshot artifact documentation, committed real `accrue_admin` esbuild static bundle for mounted LiveView.

**Archives:** v1.4 requirements captured historically in git; see `PROJECT.md` Shipped v1.4 section.

---

## v1.3 Tax + Organization Billing (Shipped: 2026-04-17)

**Phases completed:** 5 phases (18–22), 23 plans

**Key accomplishments:**

- Stripe Tax core with automatic-tax projections, checkout parity, and Fake-backed regression coverage.
- Customer tax-location capture/validation, invalid-location recovery, finalization-failure surfacing, and rollout-safety documentation (including non-retroactive Stripe Tax enablement).
- Sigra-first organization billing in `examples/accrue_host` with active-organization scope, row-scoped admin queries, webhook replay proof, and cross-org denial UX.
- Admin/host UX proof: BillingPresentation, money-index signals, tenant chrome, Tax & ownership card, README VERIFY-01 + CI `host-integration` contract.
- Finance handoff guide (`accrue/guides/finance-handoff.md`) for Stripe Revenue Recognition, Sigma, Data Pipeline, audit-ledger positioning, and explicit non-accounting boundaries; doc contract test.

**Verification:**

- Milestone audit: [`milestones/v1.3-MILESTONE-AUDIT.md`](milestones/v1.3-MILESTONE-AUDIT.md) (passed; see STATE.md for acknowledged `audit-open` carry-forward).
- VERIFY-01: CI-backed host integration + `mix verify.full`; Phase 22 doc test for finance guide.

**Known deferred items at close:** see `.planning/STATE.md` § Deferred Items (quick-task stubs; GSD audit tooling flag on Phase 21 UAT).

**Archives:**

- Roadmap: [`milestones/v1.3-ROADMAP.md`](milestones/v1.3-ROADMAP.md)
- Requirements: [`milestones/v1.3-REQUIREMENTS.md`](milestones/v1.3-REQUIREMENTS.md)
- Audit: [`milestones/v1.3-MILESTONE-AUDIT.md`](milestones/v1.3-MILESTONE-AUDIT.md)

---

## v1.2 Adoption + Trust (Shipped: 2026-04-17)

**Phases completed:** 5 phases, 13 plans, 26 tasks

**Key accomplishments:**

- Manifest-backed demo modes with host-local `mix verify` and `mix verify.full`, plus a repo-root wrapper that now delegates to the same full gate
- Manifest-backed tutorial parity tests plus a narrow shell verifier for command labels, links, anchors, and package versions
- A Fake-first host tutorial, mirrored First Hour guide, and compact package README that now teach one coherent subscription, webhook, admin-inspection, and proof flow
- Root repository front door with a proof-backed package map, stable public setup boundaries, and downstream admin positioning
- Structured GitHub issue intake with no-secrets warnings, private security routing, and public-boundary support taxonomy
- Release guidance that locks Fake as the required deterministic lane while Stripe test mode and live Stripe stay separate provider-parity and advisory checks
- Checked-in trust review plus executable leakage and release-language contracts for trust evidence, secret-safe docs, and failure-only retained artifacts
- Seeded webhook latency smoke in `mix verify` plus desktop/mobile admin trust coverage with blocking Axe and responsiveness checks
- CI now encodes the support floor, primary target, advisory cells, and Phase 15 host trust artifact policy inside the existing workflow
- Ranked Phase 16 expansion decisions with a checked-in recommendation artifact, ExUnit docs contract, and artifact-first validation map
- Phase 16 verification evidence plus durable roadmap, requirements, and project guidance for the ranked Stripe Tax, org billing, revenue/export, and second-processor recommendations
- Exact ranked candidate-to-outcome docs contract for the Phase 16 expansion recommendation
- Canonical-demo bookkeeping is closed, host browser seed cleanup is fixture-scoped, and release/contributor docs now track the current trust lanes only

**Verification:**

- Milestone audit: 23/23 requirements, 4/4 pre-cleanup phases, 23/23 integrations, 6/6 flows; non-critical tech debt closed by Phase 17.
- Phase 17 verification: 5/5 must-haves passed after traceability cleanup.
- Security audit: 5/5 Phase 17 threats closed; `threats_open: 0`.

**Deferred / carry-forward:**

- Recommended next implementation candidate: Stripe Tax support.
- Backlog candidates: Organization / multi-tenant billing and Revenue recognition / exports.
- Planted seed: Official second processor adapter.

**Archives:**

- Roadmap archive: [`milestones/v1.2-ROADMAP.md`](milestones/v1.2-ROADMAP.md)
- Requirements archive: [`milestones/v1.2-REQUIREMENTS.md`](milestones/v1.2-REQUIREMENTS.md)
- Audit archive: [`milestones/v1.2-MILESTONE-AUDIT.md`](milestones/v1.2-MILESTONE-AUDIT.md)

---

## v1.1 Stabilization + Adoption (Shipped: 2026-04-17)

**Delivered:** Real host-app proof, CI integration gate, hermetic host-flow tests, and first-user DX/docs stabilization for the published Accrue packages.

**Phases completed:** 10-12 plus 11.1 (4 phases, 22 plans, 42 tasks)

**Key accomplishments:**

- Built `examples/accrue_host` as a realistic Phoenix dogfood app using the public installer, generated billing facade, scoped webhook route, Fake processor, and mounted `accrue_admin`.
- Proved signed-in billing, signed webhook ingest, admin inspect/replay, audit events, clean-checkout rebuild, and local boot paths with executable host tests.
- Promoted the host-app proof into CI with a Playwright browser gate, retained failure artifacts, ordered release jobs, Hex-mode smoke validation, and warning/error annotation sweeps.
- Closed the audit-discovered host-flow hermeticity gap by making focused subscription/webhook/admin proof files self-isolating outside the canonical UAT wrapper.
- Hardened first-user DX with installer no-clobber reruns, conflict sidecars, setup diagnostics, host-first First Hour/troubleshooting docs, strict package-doc verification, and correct `:webhook_signing_secrets` guidance.

**Verification:**

- Milestone audit: 21/21 scoped requirements, 4/4 phases, 21/21 integrations, 6/6 flows.
- Status: tech debt only; no requirement, integration, or flow blockers.
- Audit archive: [`milestones/v1.1-MILESTONE-AUDIT.md`](milestones/v1.1-MILESTONE-AUDIT.md)

**Deferred / carry-forward:**

- Adoption assets, quality hardening, and expansion discovery remain candidate next-milestone themes.
- Known debt at close: requirements traceability drift in the archived source, Phase 11.1 validation metadata cleanup, and legacy raw browser smoke retirement.

**Archives:**

- Roadmap archive: [`milestones/v1.1-ROADMAP.md`](milestones/v1.1-ROADMAP.md)
- Requirements archive: [`milestones/v1.1-REQUIREMENTS.md`](milestones/v1.1-REQUIREMENTS.md)
- Audit archive: [`milestones/v1.1-MILESTONE-AUDIT.md`](milestones/v1.1-MILESTONE-AUDIT.md)

---

## v1.0 Initial Release (Shipped: 2026-04-16)

**Status:** shipped  
**Public package versions:** `accrue` 0.1.2 and `accrue_admin` 0.1.2  
**Phases completed:** 9 phases, 69 plans, 117 tasks  
**Git range:** `3feb44f` through `e93efd0`

### Key Accomplishments

- Built the core Accrue billing domain: money safety, processor abstraction, Fake processor, polymorphic customers, subscriptions, invoices, charges, refunds, coupons, payment methods, checkout, portal, and Stripe Connect support.
- Shipped hardened webhook infrastructure with scoped raw-body capture, signature verification, transactional ingest, Oban dispatch, DLQ/replay tooling, out-of-order reconciliation, and event-ledger history.
- Added customer communication surfaces: transactional email catalogue, shared HEEx rendering, PDF adapters, branded invoice layouts, storage abstraction, and test assertion helpers.
- Delivered `accrue_admin` as a companion Phoenix LiveView package with dashboard, list/detail pages, destructive-action step-up, webhook inspector, replay controls, Connect administration, and dev-only Fake tools.
- Built installer and host-app DX: `mix accrue.install`, route/auth/test snippets, public `Accrue.Test` helpers, OpenTelemetry spans, and Fake-first testing documentation.
- Set up public OSS release infrastructure: CI matrix with warnings-as-errors, Credo, Dialyzer, docs, Hex audit, Release Please, Hex publishing, changelogs, ExDoc/HexDocs, MIT license, contributing, conduct, and security policies.

### Verification

- Phase 09 verification passed 12/12 must-have checks.
- Release Please PR #3 published `accrue` 0.1.2.
- Release Please PR #4 published `accrue_admin` 0.1.2.
- Main CI, Browser UAT, and Release Please completed successfully after both release merges.
- GitHub annotation sweeps found no warnings or errors, only the expected Browser UAT notice.
- HexDocs pages were checked after the docs hotfix and show `~> 0.1.2` snippets with internal guide links.

### Archives

- Roadmap archive: [`milestones/v1.0-ROADMAP.md`](milestones/v1.0-ROADMAP.md)
- Requirements archive: [`milestones/v1.0-REQUIREMENTS.md`](milestones/v1.0-REQUIREMENTS.md)
- Phase execution history: [`milestones/v1.0-phases/`](milestones/v1.0-phases/)

### Deferred Items

- No open GSD artifacts were reported by the pre-close audit.
- No standalone `.planning/v1.0-MILESTONE-AUDIT.md` existed at close. Phase-level verification, validation, release CI, Hex publishing, and post-release HexDocs checks were used as closure evidence.

---
