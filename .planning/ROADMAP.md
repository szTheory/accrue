# Roadmap: Accrue

## Milestone: v1.42 — Ad-hoc Invoices & Adopter Confidence

**Goal**: Enhance adopter confidence through end-to-end demonstrations in the example host and provide support for ad-hoc invoice adjustments, while closing robustness gaps in the entitlement cache.

## Phases

- [x] **Phase 135: Adopter Confidence - Host Demos (Metered & Checkout)** - Demonstrate core billing features in the example host.
- [x] **Phase 136: Adopter Confidence - Recovery Wiring** - Wire recovery crons in the example host to prove failure-handling readiness.
- [ ] **Phase 137: Entitlement Cache Robustness & Fidelity** - Resolve WR-05 race conditions and improve sync fidelity.
- [ ] **Phase 138: Ad-hoc Invoices - Public API** - Implement first-party API for manual invoice line items.
- [ ] **Phase 139: Ad-hoc Invoices - Admin UI** - Add operator support for managing ad-hoc line items in the admin dashboard.

## Phase Details

### Phase 135: Adopter Confidence - Host Demos (Metered & Checkout)
**Goal**: Demonstrate core billing features in the example host to increase adopter confidence.
**Depends on**: Nothing
**Requirements**: PROOF-04, PROOF-05
**Success Criteria** (what must be TRUE):
  1. `examples/accrue_host` contains a functional demonstration of metered usage reporting.
  2. `examples/accrue_host` demonstrates calling the `create_checkout_session` facade directly.
  3. Adopters can see these features in action by following the host demo.
**Plans**: 1 plan
- [x] 135-01-PLAN.md — Implement metered usage and checkout facade demos.
**UI hint**: yes

### Phase 136: Adopter Confidence - Recovery Wiring
**Goal**: Wire recovery crons in the example host to prove failure-handling readiness.
**Depends on**: Phase 135
**Requirements**: PROOF-06
**Success Criteria** (what must be TRUE):
  1. `Accrue.Jobs.DetectExpiringCards` is wired into the `examples/accrue_host` Oban crontab.
  2. The example host documentation (or UI) explains how to verify card expiration recovery.
**Plans**: 2 plans
- [x] 136-01-PLAN.md — Wire recovery crons and verify via smoke tests.
- [x] 136-02-PLAN.md — Update host UI and documentation for recovery visibility.

### Phase 137: Entitlement Cache Robustness & Fidelity
**Goal**: Resolve WR-05 (StaleEntryError) and IN-01..04 fidelity fixes.
**Depends on**: Nothing
**Requirements**: FIX-01, FIX-02
**Success Criteria** (what must be TRUE):
  1. Concurrent webhook deliveries for the same customer's entitlement summary no longer raise `Ecto.StaleEntryError`.
  2. Entitlement advisory cache records include the correct `processor` name.
  3. Default telemetry includes a counter for successful entitlement summary syncs.
**Plans**: 2 plans
- [x] 137-01-PLAN.md — Implement entitlement sync fidelity fixes.
- [x] 137-02-PLAN.md — Resolve WR-05 (StaleEntryError) via race-safe upsert.

### Phase 138: Ad-hoc Invoices - Public API
**Goal**: Implement the public API for adding/removing items on draft invoices.
**Depends on**: Nothing
**Requirements**: BIL-08
**Success Criteria** (what must be TRUE):
  1. `Accrue.Billing` exposes functions to add and remove ad-hoc line items to a draft invoice.
  2. Manual adjustments are recorded in the event ledger.
  3. Ad-hoc items are correctly projected into the local `Invoice` and reflected in PDFs.
**Plans**: 2 plans
- [ ] 138-01-PLAN.md — Extend processor layer for invoice item operations.
- [ ] 138-02-PLAN.md — Implement billing context actions and public API.

### Phase 139: Ad-hoc Invoices - Admin UI
**Goal**: Provide an admin interface for managing ad-hoc line items.
**Depends on**: Phase 138
**Requirements**: ADM-17
**Success Criteria** (what must be TRUE):
  1. Admin can add a manual line item to a draft invoice from the invoice detail page.
  2. Admin can remove an existing manual line item from a draft invoice.
  3. UI feedback confirms adjustments are saved and will appear on the finalized invoice.
**Plans**: TBD
**UI hint**: yes

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 135. Adopter Confidence - Host Demos | 1/1 | Completed | 2026-05-26 |
| 136. Adopter Confidence - Recovery Wiring | 2/2 | Completed | 2026-05-26 |
| 137. Entitlement Cache Robustness | 2/2 | Completed | 2026-05-26 |
| 138. Ad-hoc Invoices - Public API | 0/2 | Not started | - |
| 139. Ad-hoc Invoices - Admin UI | 0/0 | Not started | - |
