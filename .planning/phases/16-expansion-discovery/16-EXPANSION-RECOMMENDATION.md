---
phase: 16
slug: expansion-discovery
status: recommended
created: 2026-04-17
requirements:
  - DISC-01
  - DISC-02
  - DISC-03
  - DISC-04
  - DISC-05
---

# Phase 16 - Expansion Recommendation

> Canonical ranked recommendation for tax, revenue/export, processor, and organization expansion work without weakening Accrue's Stripe-first, host-owned architecture.

---

## Recommendation Rationale

Phase 16 is a ranking decision, not a feature build. The recommendation favors work that compounds the current Stripe-first billing surface, keeps host-owned boundaries intact, and gives future planners explicit user value, architecture impact, risk, and prerequisites instead of vague expansion intent.

Stripe Tax support is the strongest next milestone because it deepens the current Stripe Billing path without rewriting the processor contract. Organization / multi-tenant billing and Revenue Recognition / exports matter, but both need clearer prerequisites before they are safe to schedule. Official second processor adapter work stays a Planted seed because the current custom processor boundary is useful, while promising core parity beyond Stripe would create a processor-boundary downgrade.

## Ranked Recommendation

| Rank | Candidate | Outcome | User Value | Architecture Impact | Risk | Prerequisites |
|------|-----------|---------|------------|---------------------|------|---------------|
| 1 | Stripe Tax support | Next milestone | Helps teams launch in more jurisdictions with less manual finance handling and fewer tax surprises on subscriptions and invoices. | Extends existing Stripe flows with customer location capture, product or price tax-code policy, and tax enablement, while preserving the Stripe-first processor boundary. | tax rollout correctness depends on valid customer location data, disabled automatic tax states being surfaced, and recurring-item migration for existing subscriptions. | Finalize customer location capture, define defaults for automatic tax, and prepare recurring-item migration handling for legacy subscriptions and invoice templates. |
| 2 | Organization / multi-tenant billing | Backlog | Gives B2B teams a path to bill organizations instead of only individual users and matches the existing billable ownership story. | Adds row-scoped org tenancy using owner_type and owner_id semantics, host-owned auth context, and eventual Sigra organization support rather than a schema-prefix rewrite. | cross-tenant billing leakage becomes likely if tenant scoping, actor resolution, or billing ownership rules remain implicit. | Wait for Sigra org support or an equivalent host-owned org model, define org billing semantics, and require row-scoped tenancy checks before any org-wide billing UI ships. |
| 3 | Revenue recognition / exports | Backlog | Helps finance-heavy adopters get Revenue Recognition outputs and downstream reporting without forcing Accrue to become an accounting system. | Keeps Stripe as the reporting source of truth and prefers Sigma, Data Pipeline, or host-authorized export delivery over app-owned finance exports. | wrong-audience finance exports can expose billing data to the wrong operators if export audiences, storage, and delivery rules are not host-authorized first. | Decide whether the first consumer is Revenue Recognition CSV/API, Sigma scheduled queries, or Data Pipeline warehouse delivery, and document host-authorized export delivery plus audit expectations. |
| 4 | Official second processor adapter | Planted seed | Could widen future market reach for teams that cannot use Stripe, but it does not improve the mainline Accrue adoption path today. | Must remain separate-package thinking around the existing custom processor contract so the core billing API, schema, and Stripe-first defaults stay intact. | processor-boundary downgrade happens if Accrue promises weakest-common-denominator parity or bends the core model around non-Stripe constraints. | Keep the current custom processor guide, gather real demand, and require a separate-package or host-owned adapter strategy before considering any official second processor milestone. |

## Migration Path Notes

Phase 16 does not change the core billing API, schema, or processor abstraction. This recommendation only records migration-path notes for future planners.

- Stripe Tax work may add customer location capture and validation so automatic tax can be enabled safely without changing the current billing facade.
- Stripe Tax rollout must include recurring-item migration for existing subscriptions, invoices, and related templates that predate tax enablement.
- Revenue recognition / exports should start with host-authorized export delivery and Stripe-owned reporting paths before any app-level downloads are considered.
- Organization / multi-tenant billing should prefer row-scoped tenancy with owner_type and owner_id over schema prefixes, and should stay gated on host-owned auth plus Sigra org readiness.
- Any future processor beyond Stripe should begin as separate-package thinking around the documented custom processor seam, not as a core billing rewrite.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Stripe remains the only processor that needs first-party depth in the next milestone. | Ranked Recommendation | A near-term adopter could require another processor sooner than current evidence suggests. |
| A2 | Sigra remains the likely org boundary for host apps that want organization billing. | Ranked Recommendation | Org billing scope could drift if host apps need non-Sigra tenancy first. |
| A3 | Finance export demand is better served by Stripe-native paths before app-owned exports. | Ranked Recommendation | Maintainers could underinvest in a workflow that finance adopters need immediately. |
| A4 | The current custom processor seam is sufficient for host-specific experiments without an official adapter. | Migration Path Notes | Future adapter demand may expose missing hooks or parity assumptions. |

## Open Questions

1. What finance workflow should Accrue optimize first for Revenue Recognition and exports: dashboard CSV, Sigma scheduled queries, or Data Pipeline delivery?
2. What exact host-owned org semantics should gate organization billing before Sigra lands first-party org support?
3. Which Stripe Tax defaults should be surfaced first so tax rollout correctness stays obvious in host applications?
4. What demand threshold would justify a separate-package official second processor adapter without weakening the Stripe-first recommendation?

## Security And Boundary Checks

- cross-tenant billing leakage: require row-scoped tenant checks, explicit org ownership rules, and Sigra or equivalent host-owned authorization before any organization billing expansion.
- wrong-audience finance exports: require host-authorized export delivery, narrow operator audiences, and Stripe-owned reporting paths before app-level export surfaces.
- tax rollout correctness: require validated customer location capture, explicit disabled automatic tax handling, and recurring-item migration planning for existing subscriptions.
- processor-boundary downgrade: require separate-package or host-owned adapter strategy, keep custom processor wording intact, and forbid parity promises that rewrite the core Stripe-first model.

### Verification Runs

- `cd accrue && mix test test/accrue/docs/expansion_discovery_test.exs --trace`
- `rg -n "^## Ranked Recommendation$|^## Assumptions Log$|^## Open Questions$|^## Recommendation Rationale$|^## Migration Path Notes$" .planning/phases/16-expansion-discovery/16-EXPANSION-RECOMMENDATION.md`
- `rg -n "Stripe Tax|Revenue Recognition|Sigma|Data Pipeline|Official second processor adapter|Organization / multi-tenant billing|Sigra|owner_type|owner_id|custom processor|Next milestone|Backlog|Planted seed" .planning/phases/16-expansion-discovery/16-EXPANSION-RECOMMENDATION.md`

## Sign-Off

- [x] Four expansion candidates ranked with concrete user value, architecture impact, risk, and prerequisites
- [x] Migration path notes preserve the current core billing API, schema, and processor abstraction
- [x] Security and trust-boundary language records the blocking risks for future planners

**Approval:** recommended 2026-04-17
