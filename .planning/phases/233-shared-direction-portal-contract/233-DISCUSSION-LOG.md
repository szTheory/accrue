# Phase 233: Shared Direction & Portal Contract - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in 233-CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-07
**Phase:** 233-Shared Direction & Portal Contract
**Areas discussed:** shared visual foundation, billed identity/account switching, open forms/context changes, lost or revoked access

---

The user selected all proposed areas, asked for additional relevant UI/UX seams, requested broad specialist and primary-source research, and explicitly delegated synthesis and recommendation to the agent. The tables below record the comparison and recommendation applied under that instruction; they do not claim the user cast separate option-by-option votes.

## Shared visual foundation

| Option | Description | Selected |
|--------|-------------|----------|
| One shared shell and stylesheet | Maximize visual consistency by sharing package layout and implementation. Rejected because it conflicts with existing package asset boundaries, distinct brands, and audience-specific work. | |
| Shared semantic roles; separate package systems | Align role meaning and criteria while preserving Admin identity, Portal host branding, package-owned tokens, assets, and compositions. | ✓ Recommended and applied |
| Document-only guidance | Write visual principles but defer all source alignment and rendered checks. Rejected because downstream route phases would interpret roles inconsistently. | |

**User's choice:** All areas; use judgment and synthesize. This recommendation follows already accepted v1.63 decisions.
**Notes:** Define the shared direction and inspect representative current served renders, but leave route-family hierarchy to later phases. No current render was produced during this discussion.

---

## Billed identity and account switching

| Option | Description | Selected |
|--------|-------------|----------|
| Label only at entry or overview | Keep later billing pages visually lighter, but risk losing account context on detail and confirmation pages. | |
| Persistent billed-entity label plus optional host switch link | Identify the host-provided billed entity across Portal pages and confirmations; link to the host's own switcher only when supplied. | ✓ Recommended and applied |
| Embedded universal Portal selector | Make selection local to the package, at the cost of assuming a common account model and duplicating host selection/policy behavior. | |

**User's choice:** All areas; use judgment and synthesize. The persistent label and optional host-owned link align with POR-08 and the accepted context contract.
**Notes:** Display metadata remains presentation-only and distinct from the actor, Customer, provider, and host brand. Personal-only installs remain free of company vocabulary or a required picker.

---

## Open forms and context changes

| Option | Description | Selected |
|--------|-------------|----------|
| Retarget on submit to the host's latest global selection | Simple global switch behavior, but could apply an old form to a different billed entity. Rejected. | |
| Pin each flow to the displayed context and reauthorize that same target | Keep each page/form bound to the entity, Customer, and processor shown when opened; independently authorize at action time. | ✓ Recommended and applied |
| Invalidate every open tab on any selection change | Strongly synchronizes tabs but adds broad state machinery and discards useful context even when its original authorization remains valid. | |

**User's choice:** Additional area identified from the source-backed contract; apply the safest coherent recommendation.
**Notes:** Switching starts a fresh context. A revoked or mismatched context blocks the action, clears secure/payment state as appropriate, and never retargets or auto-replays. Independent tabs may remain pinned only while the host still authorizes their original context.

---

## Lost or revoked access

| Option | Description | Selected |
|--------|-------------|----------|
| Redirect every failure to the login path | Reuses an existing route but can mislead authenticated users or produce a login loop after membership revocation. | |
| Generic blocked state with optional existing host switch/return path | Explain that the billing context is unavailable without exposing another account; provide the host's existing recovery path when available. | ✓ Recommended and applied |
| Preserve the action and invite the customer to retry | Risks implying the action is still authorized or replaying a payment after an uncertain result. Rejected. | |

**User's choice:** Use judgment; choose the safe, understandable recovery behavior without widening the adapter.
**Notes:** Distinguish unauthenticated from authenticated-but-unauthorized cases. Denied mutations are not replayed; clear payment fields/nonces and announce in-place blocking messages accessibly. A separate recovery URL API is not justified by current host evidence.

---

## the agent's Discretion

- Exact resolver/authorizer callback and context-envelope shapes, after tracing HTTP, LiveView reconnect/events, POST controllers, host session boundaries, and ownership checks.
- Wording/placement details for a persistent host-provided billing label and host-owned switch link.
- Representative route/state render selection and a concise source inventory.
- Whether a separate host recovery destination is warranted only if concrete adopter evidence shows that the existing switch/return link cannot serve the flow.

## Deferred Ideas

- A new context-recovery URL callback, universal Portal account picker or role system, shared component framework, and global cross-tab account-selection mechanism remain out of scope absent a separately justified adopter need.
- Route-specific UI refinements and integrated all-route proof remain assigned to Phases 234–239.
