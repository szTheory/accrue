# Phase 113: Cancellation Semantics Closure - Discussion Log

**Date:** 2026-05-06
**Mode:** recommendation synthesis
**Status:** complete

## Request style

The user asked to discuss **all** remaining gray areas for Phase 113 in one pass and explicitly requested:

- subagent-backed research
- pros / cons / tradeoff comparison for each approach
- idiomatic Elixir / Plug / Ecto / Phoenix guidance
- lessons from strong billing libraries and apps in other ecosystems
- one coherent recommendation package instead of multiple unresolved choices
- future GSD passes to keep shifting low-impact processor-track forks left unless the choice is very impactful

## Areas covered

### 1. Braintree end-of-period contract

Options researched:
- Promote Braintree `cancel_at_period_end` as official first-party host-owned behavior
- Keep Braintree official truth as immediate-cancel-only
- Split contract: keep core truth immediate-only, leave softer scheduled-end policy to an explicit host-owned seam

Locked recommendation:
- Keep Braintree official first-party truth **immediate-only**
- Do **not** promote `cancel_at_period_end` as a Braintree core-facade capability
- If a host wants softer scheduled-end semantics on Braintree, treat that as a host-owned policy seam outside the official first-party contract

Why this won:
- strongest provider honesty
- best fit for Accrue's library/app boundary
- least risk of parity theater or desync footguns
- stays within a closure milestone instead of turning into a local orchestration feature

### 2. Public cancellation API shape

Options researched:
- Center one overloaded `cancel/2` contract and let provider behavior vary underneath
- Teach three first-class surfaces (`cancel`, `cancel_immediately`, `cancel_at_period_end`)
- Prefer an Elixir-idiomatic split with one default cancel path and one explicit immediate path

Locked recommendation for this milestone:
- Keep the current explicit runtime verbs and semantics:
  - `cancel/2` = immediate cancellation
  - `cancel_at_period_end/2` = scheduled-end cancellation where supported
- Do **not** silently reinterpret `cancel/2` by processor
- Do **not** add a third first-class public facade just to mirror matrix terminology in this closure pass
- `cancel_immediately` may remain capability/docs vocabulary that maps to `cancel/2`

Why this won:
- avoids semantic surprise and breaking churn in a closure milestone
- keeps explicit verbs at the Phoenix context boundary
- still lets docs and support labels distinguish immediate vs scheduled-end clearly

### 3. Unsupported lifecycle branch guidance

Options researched:
- terse runtime errors, fuller docs only
- heavy guidance directly in runtime errors
- layered approach: typed error + short next-step hint, fuller docs/UI elsewhere

Locked recommendation:
- Use the layered approach
- runtime failures should be typed and machine-readable, with one concrete actionable hint
- docs, support matrix, admin/portal copy, and example-host proof should expand the guidance

Why this won:
- best fit for Elixir/Phoenix context error conventions
- good DX without turning error strings into long-form documentation
- reduces support burden while keeping library errors stable and structured

## Cross-cutting ecosystem lessons adopted

- **Laravel Cashier / Pay:** bounded multi-provider support works when divergence is admitted explicitly
- **dj-stripe:** one overloaded cancellation surface accumulates caveats quickly
- **ActiveMerchant:** broad gateway sameness creates leaky abstractions and DX erosion
- **Phoenix / Elixir:** explicit verbs, explicit failures, and host-owned policy seams are preferable to hidden behavioral branching

## Final synthesis

The coherent recommendation package for Phase 113 is:

1. Keep the official Braintree runtime contract truthful: immediate cancellation yes, scheduled-end no.
2. Preserve explicit facade verbs instead of overloading `cancel/2`.
3. Align capability labels, docs, and proof lanes around that truth in one pass.
4. Use typed unsupported errors with one short next-step hint, then expand in docs/UI.
5. Preserve a clearly labeled host-owned seam for products that want softer Braintree cancellation policy above the library.

## Shift-left preference reinforced

This discussion reaffirmed the standing processor-track preference:

- low-impact forks should default to deep research plus one cohesive recommendation package
- interactive reopening should be reserved for materially impactful support-boundary, proof-philosophy, or public-API decisions
- future GSD passes should keep honoring this by default
