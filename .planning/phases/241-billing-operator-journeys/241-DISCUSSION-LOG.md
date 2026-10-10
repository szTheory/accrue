# Phase 241: Billing Operator Journeys - Discussion Log

> **Audit trail only.** Do not use as input to planning, research or execution agents. Decisions and primary references are captured in `241-CONTEXT.md`.

**Date:** 2026-10-09
**Phase:** 241-billing-operator-journeys
**Areas discussed:** Subscription page emphasis; return-link wording; action-review composition.
**Method:** User-selected all areas; one focused parallel pass by three typed `gsd-advisor-researcher` agents, then parent synthesis/source checks. No automatic default was substituted for an unanswered user question.

## Selection and delegation

The agent offered the three phase-specific areas after loading prior decisions and scouting code. The maintainer replied **discuss/consider all**, explicitly requested research using subagents across relevant roles, primary sources, tradeoffs/antipatterns and an adversarial pass, and instructed the agent to synthesize coherent recommendations and automatically follow them. The maintainer also prefers small, flat dependency trees and local code over an unnecessary dependency.

This authorized adoption of the recommendations below and context capture. It did not authorize publishing, new capabilities or a new aesthetic workshop. Previously approved milestone requirements, operator audiences, incumbent system and automated verification were carried forward.

## Subscription page emphasis

| Option | Description and tradeoff | Selected |
|--------|--------------------------|----------|
| Record-first; secondary related billing | Current subscription facts/actions first; one visible customer-versus-current-scope invoice group. Reduces duplication; requires precise scope wording and distinct local counts. | Yes |
| Peer customer and owner queue panels | Worklists equally prominent for invoice-first tasks; adds competing actions, count/query cost and cross-customer context. | No |

**User's choice:** Delegated researched recommendation; first option adopted.
**Disposition:** Keep full invoice work on its existing route and access discoverable. Use supported customer filter; do not promise subscription-only results. A subscription-local count cannot stand for customer/owner results. No extra count or queue framework is needed.
**Research basis:** Current subscription/query code, approved jobs, incumbent design and [GOV.UK link affordances](https://design-system.service.gov.uk/styles/links/). Exact group placement is project synthesis, not an externally mandated layout.

## Return-link wording

| Option | Description and tradeoff | Selected |
|--------|--------------------------|----------|
| Name validated destination | Back to invoices/customer invoices/Recovery; optional concise retained-window caption. Clear orientation; requires label/destination agreement. | Yes |
| Generic Back to results | Compact and consistent when adjacent context suffices; direct-entry fallbacks and customer tabs remain ambiguous. | No |

**User's choice:** Delegated researched recommendation; first option adopted.
**Disposition:** Derive labels from validated return meanings; preserve current mount/scope and supported filter/lens/tab/window context. Campaign fallback is scoped Recovery. No history reconstruction, multi-hop stack or arbitrary destination service.
**Research basis:** [W3C link purpose](https://www.w3.org/WAI/WCAG22/Understanding/link-purpose-in-context.html), [OWASP return validation](https://cheatsheetseries.owasp.org/cheatsheets/Unvalidated_Redirects_and_Forwards_Cheat_Sheet.html), and [Phoenix navigation](https://hexdocs.pm/phoenix_live_view/live-navigation.html). Exact labels/fallbacks follow the approved Accrue route contract.

## Action-review composition

| Option | Description and tradeoff | Selected |
|--------|--------------------------|----------|
| Shared semantic arrangement in existing forms/drawers | Common target/scope/money/consequence scan order; action-specific inputs and safety/outcome owners retained. Requires faithful per-action facts. | Yes |
| Universal wizard/schema | Uniform plumbing but broad rewiring, abstractions and risk of flattening provider/action distinctions. No current unmet need justifies it. | No |

**User's choice:** Delegated researched recommendation; first option adopted.
**Disposition:** Extend the existing invoice exemplar. Exact target/current owner and money matter; dismissal is separate from a cancellation action; input correction/step-up/fresh validation/results remain action-specific. No new dependency or backend rule copy.
**Research basis:** [W3C consequential submission safeguards](https://www.w3.org/WAI/WCAG22/Understanding/error-prevention-legal-financial-data.html), [WAI-ARIA dialogs](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/), [Phoenix forms](https://hexdocs.pm/phoenix_live_view/form-bindings.html) and [security](https://hexdocs.pm/phoenix_live_view/security-model.html), plus [Stripe error handling](https://docs.stripe.com/error-handling?lang=node). Stripe is a provider-truth reference, not the visual style target or authority for other processors.

## Role coverage and adversarial synthesis

| Lens | Subscription emphasis | Returns | Action reviews |
|------|-----------------------|---------|----------------|
| Product/support jobs | One record/customer investigation stays primary; wider work remains available. | Explicit origin/fallback destination reduces reorientation. | Review facts are understandable without memorizing the page behind the drawer. |
| Engineer/audit | Exact IDs, provider/local distinctions and related evidence remain discoverable. | Safe relation/tab links retain bounded meaningful context. | Existing exact diagnostic/audit terms and authoritative action owners remain intact. |
| Finance/error prevention | Local count cannot imply customer queue membership or money. | Correct result membership matters more than a matching URL. | Exact reviewed amount/currency and timing; unknown is not a zero/success/failure. |
| Visual/content hierarchy | Remove redundant queue chrome/primary accents; use shared task spacing. | Clear short labels; captions only when they orient. | Shared scan order, appropriate field groups, visible blockers and consequences. |
| Accessibility/motion | Related links stay visible/reachable at narrow/coarse-pointer widths. | Meaningful link names and effective-theme focus/contrast. | Contained focus, named errors/status, correction, dismissal/restoration and reduced motion. |
| Security | Customer/owner queries remain scoped; labels cannot advertise false narrowing. | External/ambiguous/cross-mount input and foreign-customer origins cannot select authority. | Fresh actor/owner/target/material state, eligibility, step-up and duplicate protection. |
| Phoenix/Elixir/DX | Existing Ecto filter/component owners; no new count dependency. | Existing ScopedPath/decoders, supported patch/navigation and small helpers. | Existing forms/drawers and action handlers; no universal action abstraction or rule duplication. |
| Query/render performance | Remove duplication; no decorative aggregates or unnecessary preview fetching. | Small bounded state, not accumulated history/cursor/scroll infrastructure. | Stable form/control identity through patches; busy/reconnect never means outcome. |
| DevOps/verification | Assert link query AND actual fixture membership/count semantics. | Exact owner/list/tab/window behavior and negative parsing controls at existing owners. | Exact review/safety results plus real keyboard/busy/reconnect proof at current browser owners. |

### Concrete footguns and required acceptance dispositions

- Customer with multiple subscriptions: customer invoice destination includes the supported customer set, never a falsely promised single-subscription set; unrelated customer's invoices stay excluded.
- Subscription-local open count differs from customer/owner queue: retain truthful separate labels or omit the unnecessary count; no shared badge pretending equal membership.
- Recognized unfiltered local return with no `?`: retain the valid list rather than silently falling through to Subscriptions.
- Forged external/scheme-relative/ambiguous paths, alternate mounts, oversized/control-character or unsupported query values: use the current safe local boundary and fallback; caller owner/secrets cannot survive as authority.
- Same-customer return: preserve supported tab; another customer's detail cannot be selected by the origin string.
- Direct/invalid campaign origin: scoped Recovery. Existing valid selected window persists; historical timeline is not falsely described as window-filtered.
- Long/missing identity or amount: readable exact target and explicit unavailable amount, not hidden IDs/zero money or inferred healthy state.
- Stale authorization/owner/target/material state after review: deny/review fresh state at existing owner, never silently retarget the action.
- Dismissal versus domain cancellation: distinct specific copy and authoritative no-dispatch proof for dismissal.
- Busy/reconnect with replaced controls or trigger: preserve original disabled state and logical focus; browser online/input recovery cannot unlock/replay the billing submission.
- Accepted/pending/unknown provider result: truthful current evidence, supported next step and no blind retry/completion/settlement claim.

## Source reconciliation and evidence limits

Parent checked primary W3C, GOV.UK, OWASP, Phoenix and Stripe sources. The advisor's v0.14.1 form citation was superseded with current official guidance. Current online Phoenix docs report v1.2.12; installed package/host locks are 1.1.31/1.1.32, and versioned online pages were unavailable to the browser tool. Planning must verify implementation APIs against installed versions, without upgrading as a side effect.

Requested `prompts/` material supplied job/domain/reference continuity. Its aspirational new rooms, expanded capability lists, generic action wizards and historical Home/brand claims do not outrank the current roadmap/product/token/delivered-code authorities. Existing v1.64 and Phase 240 lessons were reused; no new sibling-project review was run.

This was source/design research: no app startup, tests, fresh screenshots, remote CI or provider exercise. The existing semantic and browser owners are planning obligations, not already-green Phase 241 evidence. No unresolved product-vision fork or concrete dependency need remained after synthesis; further broad research would repeat settled decisions.

The registered GSD state handlers updated current focus, status, last activity and session/resume fields. The existing bulleted **Next command** field is not recognized by `state.patch`; its attempted update was reported as failed. Freeform Phase 240 continuation prose elsewhere is historical. The canonical continuation is explicitly recorded in this context and the latest STATE current-focus/session fields: `$gsd-plan-phase 241`. No direct STATE/ROADMAP write bypassed the registered handlers.

## Agent Discretion

Decomposition, exact truthful routine wording, minimal reuse/local presentation helpers and faithful fixtures/assertions are delegated within `241-CONTEXT.md`. Small copied presentation code is preferable to an unnecessary dependency; safety/authorization/money logic stays with existing owners. Optional post-delivery feedback remains available, with no required confirmation-only human UAT.

## Deferred Ideas

Phase 242 owns remaining investigation/catalog/Connect/shell and domain-language propagation. Phase 243 owns integrated coverage, reviewed intended Linux goldens and feedback preview. No new capability, universal wizard, backend diagnosis, rebrand, Portal work, paid evaluator, CI platform or publication was promoted. Continue with `$gsd-plan-phase 241`.
