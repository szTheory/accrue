# Roadmap: Accrue

## Active Milestone

### v1.37 — Subscription Change Management

**Status:** Complete 2026-05-07
**Phases:** 117-119

**Goal:** Make Accrue feel complete for the most common post-checkout SaaS
billing work by promoting active subscription-change management into an
explicit first-party contract across the public billing facade, admin/operator
surfaces, and customer self-serve portal.

**Why now:** The dual-provider core closure work in `v1.35` and `v1.36`
finished the staged customer-update and cancellation rows. The next meaningful
confidence and “batteries included” gap is changing an already-active
subscription without parity theater: plan changes, supported seat/quantity
changes, and preview-before-commit guidance.

## Phases

### Phase 117: Contract Promotion + Preview Truth

**Status:** Complete 2026-05-07
**Goal**: Promote the active subscription-change bundle from scattered code paths into one explicit support contract centered on plan swap and preview-before-commit.
**Depends on**: v1.36 shipped
**Requirements**: SCM-01, SCM-02

**Success criteria:**

1. `swap_plan/3` and `preview_upcoming_invoice/2` are documented as official active-subscription-change APIs instead of implied or side-channel capabilities.
2. The processor support matrix and lifecycle docs define one provider-honest contract for supported plan-change and preview semantics.
3. Preview-before-commit guidance is explicit in the active docs and does not imply unsupported Braintree parity.

### Phase 118: Admin + Portal Change Flows

**Status:** Complete 2026-05-07
**Goal**: Expose the supported subscription-change bundle coherently across admin/operator and customer self-serve surfaces.
**Depends on**: Phase 117
**Requirements**: SCM-03, SCM-04, SCM-05

**Success criteria:**

1. Stripe/Fake-supported quantity and subscription-item changes are available through the official facade and reflected by touched UI flows.
2. Admin surfaces expose the supported actions, preview states, and setup gates per provider without leaking unsupported semantics.
3. Portal surfaces let customers preview and commit supported plan changes with provider-honest wording and no pause/resume or schedule implication creep.

### Phase 119: Braintree Bounded Plan-Swap Closeout

**Status:** Complete 2026-05-07
**Goal**: Finish the milestone by hardening the bounded Braintree plan-swap story and locking every public mirror to the same contract.
**Depends on**: Phase 118
**Requirements**: SCM-06

**Success criteria:**

1. Braintree plan swap is documented and surfaced only within the `:plan_resolver` contract, with actionable setup guidance when that contract is missing.
2. Unsupported Braintree quantity/item semantics fail clearly in runtime, docs, and touched UI surfaces.
3. Support-matrix verifiers, package-facing docs, and example-host guidance all point back to one coherent subscription-change contract.

## Milestone Guardrails

- Keep provider behavior honest: Stripe/Fake get the full active-change bundle, while Braintree remains bounded to plan-swap support plus typed unsupported guidance elsewhere.
- Do not widen this milestone into pause/unpause, schedule management, or release-readiness operations.
- Treat quantity and item-management support as subscription-change depth, not as a new seat-domain abstraction.

## Recent Milestones

- ✅ **v1.36 Dual-Provider Core Completion** — Phases **112–116** shipped **2026-05-07**. Promoted bounded first-party customer update, normalized provider-honest cancellation semantics, locked the support-contract verifier bundle, and restored the audit-required verification chain. Archives: [milestones/v1.36-ROADMAP.md](/Users/jon/projects/accrue/.planning/milestones/v1.36-ROADMAP.md), [milestones/v1.36-REQUIREMENTS.md](/Users/jon/projects/accrue/.planning/milestones/v1.36-REQUIREMENTS.md).
- ✅ **v1.35 Dual-Provider Supportability Closure** — Phases **109–111** shipped **2026-05-07**. Provider-honest support contract mirrors, lifecycle semantics SSOT, and Braintree webhook/operator recovery proof. Archives: [milestones/v1.35-ROADMAP.md](/Users/jon/projects/accrue/.planning/milestones/v1.35-ROADMAP.md), [milestones/v1.35-REQUIREMENTS.md](/Users/jon/projects/accrue/.planning/milestones/v1.35-REQUIREMENTS.md).
- ✅ **v1.34 Rendro Native Invoice PDF Default** — Phases **106–108** shipped **2026-05-06**. Rendro default invoice path, explicit Chromic compatibility path, and Hex-backed release proof. Archives: [milestones/v1.34-ROADMAP.md](/Users/jon/projects/accrue/.planning/milestones/v1.34-ROADMAP.md), [milestones/v1.34-REQUIREMENTS.md](/Users/jon/projects/accrue/.planning/milestones/v1.34-REQUIREMENTS.md).

## Notes

- The next unused planning phase is now **117**, and this roadmap consumes **117–119**.
- The linked release-readiness pass remains a valid follow-up, but it is intentionally outside this milestone’s feature scope.
- Advanced schedules, broader pause/resume promotion, Hyperwallet reopening, and `FIN-03` stay out of scope unless a later milestone explicitly reopens them.

---
*Last updated: 2026-05-07 — **v1.37** execution completed across Phases 117–119.*
