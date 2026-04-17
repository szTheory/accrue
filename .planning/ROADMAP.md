# Roadmap: Accrue

## Milestones

- ✅ **v1.0 Initial Release** — Phases 1-9 shipped on 2026-04-16. Public Hex packages: `accrue` 0.1.2 and `accrue_admin` 0.1.2. Full archive: [`milestones/v1.0-ROADMAP.md`](milestones/v1.0-ROADMAP.md).
- ✅ **v1.1 Stabilization + Adoption** — Phases 10-12 plus 11.1 shipped on 2026-04-17. Proved Accrue in a realistic Phoenix host app, promoted that proof into CI, closed host-flow hermeticity gaps, and hardened first-user DX/docs. Full archive: [`milestones/v1.1-ROADMAP.md`](milestones/v1.1-ROADMAP.md).
- ✅ **v1.2 Adoption + Trust** — Phases 13-17 shipped on 2026-04-17. Polished the canonical local demo/tutorial, adoption front door, trust evidence, expansion recommendation, and final milestone cleanup. Full archive: [`milestones/v1.2-ROADMAP.md`](milestones/v1.2-ROADMAP.md).
- 🚧 **v1.3 Tax + Organization Billing** — Phases 18-22 planned on 2026-04-17. Adds Stripe Tax orchestration, Sigra-first organization billing, admin/host proof, and Stripe-native finance handoff.

## v1.3 Tax + Organization Billing

**Milestone Goal:** Let Phoenix SaaS teams bill organizations with Stripe Tax enabled, preserve tenant boundaries through Sigra or equivalent host-owned scopes, and hand finance workflows to Stripe-native reporting without Accrue owning accounting semantics.

## Phases

**Phase Numbering:**
- Integer phases continue from prior milestone work.
- Decimal phases are reserved for urgent insertions.

- [x] **Phase 18: Stripe Tax Core** — Add tax enablement options to billing actions, processor/Fake support, automatic-tax projections, and focused tests. Completed 2026-04-17.
- [x] **Phase 19: Tax Location and Rollout Safety** — Add customer tax-location capture/update/validation paths, invalid-location recovery behavior, docs, and migration guidance for existing subscriptions. Completed 2026-04-17.
- [ ] **Phase 20: Organization Billing With Sigra** — Add Sigra-first org billing proof using active organization scope, memberships, org admin boundaries, and row-scoped billable ownership. In progress: `20-01`, `20-02`, and `20-03` shipped 2026-04-17.
- [ ] **Phase 21: Admin and Host UX Proof** — Surface org-owned billing/tax states in the host/admin demo with browser coverage for user billing, org billing, tax-invalid states, and webhook/admin replay boundaries.
- [ ] **Phase 22: Finance Handoff and Milestone Verification** — Add finance handoff docs for Stripe Revenue Recognition, Sigma scheduled queries, Data Pipeline, tax evidence, and event-ledger boundaries; run end-to-end verification and archive the milestone.

## Phase Details

### Phase 18: Stripe Tax Core

**Goal:** Developers can enable Stripe Tax on new recurring and checkout flows through Accrue's public API, with Fake-backed behavior and local projections that make automatic tax state observable.

**Depends on:** Phase 17

**Requirements:** TAX-01

**Success Criteria:**
1. `Accrue.Billing` subscription and checkout entry points accept a clear tax enablement option without changing Accrue's Stripe-first processor strategy.
2. The Stripe processor passes automatic-tax intent through to Stripe-backed calls, while the Fake processor represents enabled/disabled tax states deterministically for tests.
3. Subscription, invoice, and checkout projections preserve relevant automatic-tax status and tax amount data from processor payloads without requiring 1:1 Stripe column parity.
4. Focused unit and integration tests prove tax-enabled and tax-disabled flows remain backward-compatible for existing non-tax users.

**Plans:** 4 plans

Plans:
- [x] `18-01-PLAN.md` — Add the subscription automatic-tax public contract and regression coverage.
- [x] `18-02-PLAN.md` — Keep Stripe and Fake automatic-tax payloads in parity and prove it in adapter tests.
- [x] `18-03-PLAN.md` — Persist and project narrow automatic-tax observability for subscriptions and invoices.
- [x] `18-04-PLAN.md` — Add checkout automatic-tax input/projection support and focused checkout tests.

### Phase 19: Tax Location and Rollout Safety

**Goal:** Tax-enabled recurring billing cannot fail silently: customer location capture, immediate validation, invalid-location recovery, and legacy recurring-item migration guidance are explicit.

**Depends on:** Phase 18

**Requirements:** TAX-02, TAX-03, TAX-04

**Success Criteria:**
1. Developers can set/update customer address or tax-location details through a public Accrue path before creating tax-enabled subscriptions.
2. Customer location validation failures produce actionable Accrue errors and documentation rather than hidden Stripe API failures.
3. Invoice finalization failure or automatic-tax invalid-location states are visible in local projections, admin surfaces, or troubleshooting docs.
4. Existing subscription rollout docs explain that enabling Stripe Tax/configuring automatic collection does not update existing subscriptions, invoices, or payment links automatically.

**Plans:** 5 plans

Plans:
- [x] `19-01-PLAN.md` — Add processor-side tax-location validation, safe error mapping, and deterministic Fake invalid-location behavior.
- [x] `19-02-PLAN.md` — Add the public `Accrue.Billing.update_customer_tax_location/2` path and focused TAX-02 billing coverage.
- [x] `19-03-PLAN.md` — Persist and reconcile disabled-reason / finalization-failure state for recurring invalid-location rollout issues.
- [x] `19-04-PLAN.md` — Surface local tax-risk state in admin detail views and the canonical host billing flow.
- [x] `19-05-PLAN.md` — Add rollout-safety and invalid-location recovery guidance to troubleshooting and live Stripe docs.

### Phase 20: Organization Billing With Sigra

**Goal:** A Sigra-backed Phoenix host can bill the active organization, while Accrue's generic billable model remains the public ownership contract for non-Sigra hosts.

**Depends on:** Phase 19

**Requirements:** ORG-01, ORG-02, ORG-03

**Success Criteria:**
1. A host organization schema can `use Accrue.Billable` and round-trip through `Accrue.Billing.customer/1` with `owner_type` and `owner_id` preserved.
2. Sigra organization scope, membership, and active organization context are used in the canonical host proof for org-owned billing.
3. Org admins can create/view/manage billing only for their allowed active organization; cross-org access attempts fail server-side and are covered by tests.
4. Public billing, admin UI, webhook replay, and finance handoff boundaries all respect the row-scoped owner contract instead of trusting client-selected organization IDs.

**Plans:** 6 plans

Plans:
- [x] `20-01-PLAN.md` — Add the local Sigra dependency, Sigra host wrapper, billable organization schemas, and the blocking host schema migration.
- [x] `20-02-PLAN.md` — Hydrate host scope with Sigra and route `/app/billing` through server-derived active-organization billing wrappers.
- [x] `20-03-PLAN.md` — Thread owner scope through the host-mounted admin session and prove it with `admin_mount_test.exs`.
- [ ] `20-04-PLAN.md` — Convert admin query modules to owner-aware customer, subscription, invoice, webhook, and event loaders.
- [ ] `20-05-PLAN.md` — Apply exact cross-org denial presentation to customer, subscription, and event admin LiveViews.
- [ ] `20-06-PLAN.md` — Finish webhook detail/bulk replay ambiguity handling and lock host-mounted denial proof end to end.

### Phase 21: Admin and Host UX Proof

**Goal:** The canonical host/admin demo proves user-owned and organization-owned billing with tax states in the way a real Phoenix SaaS team would evaluate it.

**Depends on:** Phase 20

**Requirements:** VERIFY-01

**Success Criteria:**
1. `examples/accrue_host` demonstrates user billing and organization billing through host-owned facades instead of private Accrue table queries.
2. Admin views expose enough tax and ownership context for operators to distinguish user-owned, org-owned, tax-enabled, tax-disabled, and invalid-location billing states.
3. Browser coverage exercises org-backed subscription creation, tax-state inspection, invalid-location messaging, and admin/webhook replay denial for out-of-scope orgs.
4. The canonical local verification path remains Fake-backed and deterministic, with live Stripe checks remaining advisory/provider-parity only.

**Plans:** TBD by `$gsd-plan-phase 21`

### Phase 22: Finance Handoff and Milestone Verification

**Goal:** Accrue gives developers safe Stripe-native finance handoff guidance without becoming an accounting system, then verifies the full v1.3 milestone.

**Depends on:** Phase 21

**Requirements:** FIN-01, FIN-02, VERIFY-01

**Success Criteria:**
1. Documentation explains when to use Stripe Revenue Recognition, Sigma scheduled queries, and Data Pipeline for finance workflows.
2. Finance handoff docs map Accrue billing objects, Stripe IDs, tax evidence, and event-ledger history to downstream reporting without promising GAAP/ASC 606 calculations.
3. Any export or handoff examples are explicitly host-authorized and preserve the `wrong-audience finance exports` boundary.
4. End-to-end verification proves all v1.3 requirements are mapped, tested, and ready for milestone archival.

**Plans:** TBD by `$gsd-plan-phase 22`

## Progress

**Execution Order:** Phases execute in numeric order: 18 -> 19 -> 20 -> 21 -> 22

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundations | v1.0 | 6/6 | Complete | 2026-04-11 |
| 2. Schemas + Webhook Plumbing | v1.0 | 6/6 | Complete | 2026-04-12 |
| 3. Core Subscription Lifecycle | v1.0 | 8/8 | Complete | 2026-04-14 |
| 4. Advanced Billing + Webhook Hardening | v1.0 | 8/8 | Complete | 2026-04-14 |
| 5. Connect | v1.0 | 7/7 | Complete | 2026-04-14 |
| 6. Email + PDF | v1.0 | 7/7 | Complete | 2026-04-15 |
| 7. Admin UI (accrue_admin) | v1.0 | 12/12 | Complete | 2026-04-15 |
| 8. Install + Polish + Testing | v1.0 | 9/9 | Complete | 2026-04-15 |
| 9. Release | v1.0 | 6/6 | Complete | 2026-04-16 |
| 10. Host App Dogfood Harness | v1.1 | 7/7 | Complete | 2026-04-16 |
| 11. CI User-Facing Integration Gate | v1.1 | 3/3 | Complete | 2026-04-16 |
| 11.1. Hermetic Host Flow Proofs | v1.1 | 1/1 | Complete | 2026-04-16 |
| 12. First-User DX Stabilization | v1.1 | 11/11 | Complete | 2026-04-16 |
| 13. Canonical Demo + Tutorial | v1.2 | 3/3 | Complete | 2026-04-17 |
| 14. Adoption Front Door | v1.2 | 3/3 | Complete | 2026-04-17 |
| 15. Trust Hardening | v1.2 | 3/3 | Complete | 2026-04-17 |
| 16. Expansion Discovery | v1.2 | 3/3 | Complete | 2026-04-17 |
| 17. Milestone Closure Cleanup | v1.2 | 1/1 | Complete | 2026-04-17 |
| 18. Stripe Tax Core | v1.3 | 4/4 | Complete | 2026-04-17 |
| 19. Tax Location and Rollout Safety | v1.3 | 5/5 | Complete | 2026-04-17 |
| 20. Organization Billing With Sigra | v1.3 | 3/6 | In Progress | |
| 21. Admin and Host UX Proof | v1.3 | 0/0 | Pending | |
| 22. Finance Handoff and Milestone Verification | v1.3 | 0/0 | Pending | |

---

For full archived phase details, decisions, and requirements traceability, see `.planning/milestones/`.
