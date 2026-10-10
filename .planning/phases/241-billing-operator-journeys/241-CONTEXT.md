# Phase 241: Billing Operator Journeys - Context

**Gathered:** 2026-10-09
**Status:** Ready for planning
**Decision authority:** The maintainer selected all three remaining areas and explicitly delegated focused subagent research, synthesis and automatic adoption of coherent recommendations. No additional product approval is pending.

**Continuation:** `$gsd-plan-phase 241`. This ready context and the latest STATE current-focus/session fields supersede earlier Phase 240 handoff prose that still names discussion; do not repeat this discussion.

<domain>
## Phase Boundary

Refine existing customer, subscription, invoice, payment and Recovery journeys: truthful scoped invoice destinations (JRN-01), bounded validated returns (JRN-02), campaign entry/Recovery-window continuity (JRN-03), and self-contained supported billing-action reviews (JRN-04). Propagate Phase 240's shared hierarchy, responsive/theme, focus, busy/reconnect and state contracts to each changed consumer. Preserve completed billing safety and provider boundaries.

Phase 240 is verified complete; its six plans, eight requirements and 47/47 must-haves are continuity, not work to repeat. This discussion resolves three presentation decisions within the approved roadmap. It does not reopen milestone discovery, Impeccable initialization, branding, backend capabilities or the earlier multi-lens review.
</domain>

<decisions>
## Implementation Decisions

### Subscription page emphasis and invoice destinations

- **D-01:** Lead subscription detail with identity/current owner, lifecycle, exact confirmed plan/amount/period/collection facts, material blockers or uncertainty, and the supported subscription action group. Follow with related billing and deeper evidence. Use the incumbent shared roles and existing components; no universal columns, extra dashboard chrome or rebrand.
- **D-02:** Consolidate repeated owner-wide invoice queue panels/primary CTAs into one secondary, visible related-billing group. Keep supported invoice-worklist access discoverable without making unrelated invoice records dominate this subscription. The full worklist remains on the existing Invoices route; a duplicated embedded owner preview is not required.
- **D-03:** Use the supported `customer_id` invoice filter and name its meaning, for example **Open invoices for this customer** when `status=open` is retained. A separate **All open invoices in current scope** link names the wider result set. Use the actual selected-owner wording when applicable; global Admin scope must not be described as one customer's or one owner's queue. Remove any promise of subscription-only filtering and the ignored `subscription_id` filter.
- **D-04:** Subscription-local invoice counts, customer-wide results and the owner/authorized-scope queue are distinct. If an existing subscription count is retained, label it as subscription-local and do not attach it as the count of a customer or scope link. Do not add a count/query solely for decoration. Never infer zero money or a healthy/completed state from missing amounts, absent records or unavailable evidence.

### Return labels, bounded context and Recovery

- **D-05:** Name the actual validated return destination: **Back to invoices**, **Back to payments**, **Back to subscriptions**, **Back to customers**, **Back to customer invoices/payments/subscriptions**, or **Back to Recovery** as appropriate. Derive destination and visible label from the same validated meaning; raw untrusted return text cannot determine either. Keep structural breadcrumbs separate from the explicit contextual return.
- **D-06:** Preserve only enumerated meanings that the existing destination decoders actually support: current owner, relevant search/status/customer/collection filters, lens, supported sort/direction, same-customer tab, and valid Recovery window. Inventory decoder/allowlist parity during focused planning; do not retain ignored parameters or claim restoration from URL equality alone. A recognized unfiltered local list is a valid origin even without a query string. Pagination/accumulated-row/scroll restoration is not a new acceptance promise.
- **D-07:** Reuse the existing `ScopedPath` ownership boundary. Local returns stay inside the configured Admin mount, approved route family and freshly resolved current scope. Strip caller-supplied owner/secrets/unsupported keys; customer-detail returns must match the loaded record's customer. Reject external/scheme-relative/ambiguous or cross-mount destinations and use the route's safe scoped fallback. Do not add arbitrary detail origins, nested return stacks, a session navigation service or a routing dependency. Preserve established safe scope-rebuilding behavior rather than weakening it.
- **D-08:** Campaign direct entry, absent/invalid origin or unrelated list origin returns to **scoped Recovery**. Entry from Recovery preserves only a valid existing `7d`, `30d` or `90d` window and current owner. Both breadcrumb and explicit return agree. A concise selected-window caption may orient the user; do not narrate URLs. Preserve the existing default window when no valid window is supplied. Keep **View subscription** a distinct destination.
- **D-09:** Keep current subscription state and historical campaign evidence distinct. Retaining a Recovery window does not mean the campaign's complete historical timeline has been filtered to that window. Missing, empty, loading and unavailable observations retain their supported meanings. Browser Back remains browser history, not an implementation substitute for the explicit return contract.

### Billing-action review composition and truthful results

- **D-10:** Reuse the Phase 240 invoice review's semantic arrangement inside the existing subscription, payment/refund and customer payment-method forms/drawers. Share presentation only where genuine repetition warrants it. Keep action-specific inputs, validation, step-up, eligibility and results with their current owners; do not introduce a universal wizard/schema, action framework or duplicate billing rules.
- **D-11:** A review is self-contained: exact selected target and identifying record ID, material customer and owner/scope, current relevant state, exact requested money/currency when applicable, supported consequence/timing, and provider/observation limits. Human-readable identity is prominent; identifiers remain legible and exact. Material blockers, uncertainty and consequences remain visible. Do not require the user to remember facts hidden behind the overlay or expand diagnostic payloads to understand the action.
- **D-12:** Subscription reviews distinguish immediate versus scheduled effects and show a confirmed provider-backed preview only where supported. Refund reviews identify the payment and reviewed refund amount/currency. Payment-method reviews identify the selected method and customer and explain the supported default/removal consequence. A missing amount/preview is unavailable, not zero or an estimate. Preserve exact currency/minor-unit formatting and confirmed-versus-observed facts.
- **D-13:** Confirmation names the specific action; review dismissal is visibly different from cancellation of a subscription or another domain action. Extend the exemplar's **Back to invoice** pattern where suitable, such as **Back to subscription** or **Back to payment**. Dismissal/Escape cannot dispatch the billing action. Retain correction before submission, associated errors/status, overlay containment and logical focus restoration when a trigger is replaced or removed.
- **D-14:** Preserve fresh authorization, current owner, target/material-state revalidation, step-up, provider capability and duplicate protections through every touched action. Stale review/input must not silently act on a newly loaded target. Real busy states retain labels/icons and original disabled controls; reconnect cannot unlock prematurely or replay mutation. Form input recovery is not permission to replay a billing submission.
- **D-15:** Results state only the evidence-specific accepted, pending, completed, failed, denied or unknown outcome. A server acknowledgement or local update is not proof of settlement. Keep supported evidence/next-step links and prevent blind retries of uncertain outcomes. Provider-specific idempotency guidance does not expand Accrue's supported retry or processor contract.

### Delivery, automation and stopping rules

- **D-16:** Use Impeccable **Operate** and existing Emil motion principles: familiar controls, coherent content hierarchy, existing Cobalt/Geist/Geist Mono/`--ax-*` roles, restrained accent and immediate frequent keyboard work. Carry Phase 240's deliberate 2px dense/1px structural exceptions, coarse-pointer geometry, theme precedence and focus/state rules. No new motion, font or UI dependency.
- **D-17:** The maintainer prefers small, flat dependency trees: a small local presentation/helper is preferable to a new dependency when it faithfully solves this bounded problem. Reuse existing scope, money, auth and component owners; this preference does not justify copying or weakening their safety logic. A concrete unmet need must justify any proposed dependency.
- **D-18:** Each owning change includes recurring ExUnit/query/contract/browser proof and focused negative controls at existing owners. Prove exact destination result membership, retained filter/lens/tab/window behavior, alternate mounts, safe fallbacks, label/destination agreement and action target/money/safety/results. Exercise actual keyboard correction/dismissal, busy/reconnect replacement and changed consumer responsive/effective-theme behavior. Zero required human UAT remains the target; feedback after delivery is optional.
- **D-19:** Source advice is not current mounted proof. Confirm presentation candidates in served output before cosmetic edits; preserve source/fixture/built/compiled/served provenance. Build package assets explicitly. Keep mutation/reset fixtures separate from the feedback preview. Retain existing CI checks, complete-baseline guard and pixel thresholds; final reviewed Linux goldens remain Phase 243. No paid evaluator, new full-matrix workflow, hiding masks, fixed sleeps or blanket retries.
- **D-20:** This bounded three-advisor pass resolves the selected questions. No further broad milestone or sibling-project research is warranted. Reopen only for a named defect, safety/behavior failure, changed task requirement or explicit owner feedback. Preserve the delivery budget: one complete build/check plus one batched desktop/narrow/effective-theme inspection, one corrective batch and at most one confirming inspection per agreed batch. Actual browser zoom, physical devices, screen-reader speech and live-provider evidence remain accurately limited, without becoming confirmation-only owner UAT.

### Agent Discretion

Exact decomposition, faithful routine copy, use of existing shared components, small local helpers, representative fixtures and cheapest precise assertions are delegated. Close a visual candidate as already adequate or unobserved when current evidence supports that outcome. The three researched recommendations are adopted under the maintainer's delegation; no further approval interview is required. This context capture authorizes planning, not publication, a new milestone or a new capability.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents must read relevant sections before planning or implementation.** Current roadmap, requirements, product truth, package tokens and Phase 240 contracts outrank older aspirational prompts.

### Approved scope and incumbent authority

- `.planning/ROADMAP.md` — Phase 241 goal, JRN-01..04 and propagation obligation.
- `.planning/REQUIREMENTS.md` — approved requirements and acceptance constraints.
- `PRODUCT.md` — equal engineering/support operator audiences, ownership and product truth; earlier capability observations must be checked against delivered v1.63 code.
- `.planning/research/v1.64/SUMMARY.md` — completed upstream diligence, scope and stopping rules.
- `.planning/research/v1.64/OPERATOR-EXPERIENCE.md` — jobs, billing route families, destination/return and review findings.
- `.planning/research/v1.64/VISUAL-SYSTEM.md` — incumbent semantic hierarchy, density, typography and motion.
- `.planning/research/v1.64/AUTOMATION-AND-SEAMS.md` — existing acceptance owners, asset/fixture seams and precise evidence limits.
- `.planning/phases/240-shared-system-and-real-billing-exemplar/240-CONTEXT.md` — carried-forward decisions; Phase 241 closes its deferred billing-journey items.
- `.planning/phases/240-shared-system-and-real-billing-exemplar/240-UI-SPEC.md` — established invoice review and shared system contract.
- `.planning/phases/240-shared-system-and-real-billing-exemplar/240-UI-REVIEW.md` — post-audit disposition and subscription queue finding, not a fresh score.
- `.planning/phases/240-shared-system-and-real-billing-exemplar/240-VERIFICATION.md` — completed baseline; do not reexecute Phase 240.
- `.planning/phases/240-shared-system-and-real-billing-exemplar/240-COVERAGE.md` — current route/registry/provenance authority and existing owners.
- `.planning/milestones/v1.63-phases/233-shared-direction-portal-contract/DESIGN.md` — incumbent semantic direction, separate Admin/Portal consumers.
- `accrue_admin/assets/css/theme.css` — executable token authority.
- `brandbook/voice.md` — ratified measured, exact voice; routine operator copy uses understandable domain language.

### Requested prompt continuity, subordinate to current authority

- `prompts/accrue_admin_operator_ui_journey_blueprint.md` — job/detail/review/validation concepts only; proposed rooms, universal wizards and capabilities do not become Phase 241 scope.
- `prompts/accrue-library-summary-for-admin-ux-deep-research.md` — billing/projection/provider distinctions and operator jobs; verify historical claims against current owners.
- `prompts/GSD-REPO-HYGIENE.md` — hygiene/explicit-publication boundaries; not authorization to start a release campaign during discussion.

### Focused primary-source guidance, checked 2026-10-09

- [W3C link purpose](https://www.w3.org/WAI/WCAG22/Understanding/link-purpose-in-context.html) — descriptive destination labels; this project's choice is an application of that guidance, not a mandated exact phrase.
- [GOV.UK links](https://design-system.service.gov.uk/styles/links/) — familiar link affordances, theme contrast and restrained new-tab behavior; no GOV.UK dependency or styling migration.
- [OWASP return destinations](https://cheatsheetseries.owasp.org/cheatsheets/Unvalidated_Redirects_and_Forwards_Cheat_Sheet.html) — constrain and authorize parsed return destinations; strengthen the existing local boundary.
- [W3C financial/data error prevention](https://www.w3.org/WAI/WCAG22/Understanding/error-prevention-legal-financial-data.html) — consequential submissions need appropriate correction/review/reversal safeguards, not confirmation of every routine interaction.
- [WAI-ARIA modal dialogs](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/) — contained focus, meaningful naming, visible dismissal and logical restoration for existing modal drawers.
- [Phoenix LiveView navigation](https://hexdocs.pm/phoenix_live_view/live-navigation.html), [forms](https://hexdocs.pm/phoenix_live_view/form-bindings.html), and [security](https://hexdocs.pm/phoenix_live_view/security-model.html) — validate params, preserve idiomatic navigation/forms and authorize events. Online docs currently report v1.2.12; local package/host locks are 1.1.31/1.1.32. Verify APIs against installed versions; no upgrade is implied. Do not reuse the advisor's older v0.14.1 form citation.
- [Stripe error handling](https://docs.stripe.com/error-handling?lang=node) — provider-specific uncertainty guidance only; supported Accrue action/duplicate/outcome contracts remain authoritative.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `accrue_admin/lib/accrue_admin/scoped_path.ex` — existing local return route/value allowlists and current-owner rebuilding. Its current invoice/payment allowlists omit some decoded filters and query-free recognized paths fall through. Expand only supported meanings; keep same-customer checks.
- `accrue_admin/lib/accrue_admin/components/detail.ex`, `detail_drawer.ex`, `related_resources.ex`, `step_up_auth_modal.ex`, `window_selector.ex`, and `money_formatter.ex` — existing facts, related links, review, step-up, window and exact-money presentation.
- `accrue_admin/lib/accrue_admin/copy.ex` and `copy/invoice.ex`, `copy/subscription.ex`, `copy/customer_payment_methods.ex` — routine copy owners; preserve locked legal/audit meaning.

### Established Patterns and Integration Points

- `accrue_admin/lib/accrue_admin/live/subscription_live.ex` currently repeats an owner invoice workspace/preview and includes misleading ignored subscription invoice parameters. `accrue_admin/lib/accrue_admin/queries/invoices.ex` supports `customer_id`, status and collection method, not subscription-only filtering.
- Existing customer peer-tab links carry a same-customer detail/tab origin. Subscription list identity links already use a bounded list origin; invoice/payment list links require their own supported origin mapping. Compare actual destination decoders rather than inventing a second query contract.
- `accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex` currently calls the generic Subscriptions fallback even when the visible destination is Recovery. `recovery_live.ex` owns the existing `7d`/`30d`/`90d` window and async observation states.
- `accrue_admin/lib/accrue_admin/live/invoice_live.ex`, `subscription_live.ex`, `charge_live.ex`, and `customer_live.ex` own invoice/subscription/refund/payment-method actions and their existing fresh review/scope/result checks. Preserve those owners.
- `accrue_admin/test/accrue_admin/scoped_path_test.exs`, `queries/query_modules_test.exs`, billing list/detail LiveView tests, and `live/analytics/recovery_live_test.exs` / `campaign_live_test.exs` are the cheap semantic owners. Map exact commands in phase research/planning.
- `accrue_admin/e2e/admin-page-flow-phase191.spec.js`, `admin-interaction-overlay-phase199.spec.js`, `test/js/focus_trap_test.mjs`, and `examples/accrue_host/e2e/phase234-admin-customers-subscriptions.spec.js` / `phase237-admin-billing.spec.js` are existing interaction/mounted owners; earlier passage alone does not cover each new consumer scenario.
- Host `/admin` is Admin; host `/billing` is Portal; package fixture `/billing` is Admin. `mix accrue_admin.assets.build` plus host compile/current served bytes is the freshness contract. Historical archived captures remain immutable; current proof uses its own provenance.
</code_context>

<specifics>
## Specific Ideas

Adopt all three researched recommendations: record-first subscription detail with secondary related billing; contextual returns derived from validated destinations; shared semantic reviews in existing action flows. Three independent advisors considered product/jobs, support/engineering, finance/error prevention, visual/content hierarchy, accessibility, security, Phoenix/DX, query/render cost and DevOps proof. No unresolved vision fork or new dependency need emerged. The human audit log preserves alternatives and adversarial cases; downstream agents consume this context.

Concrete journey examples: filtered invoices → invoice → same supported invoice results; customer Payments tab → payment/refund review → same customer's Payments tab; subscription → that customer's open invoices (possibly across multiple subscriptions); scoped 90-day Recovery → campaign → same scoped 90-day Recovery; bookmarked campaign → scoped default Recovery.

This pass used source inspection and primary online guidance. It did not start the app, run tests, inspect fresh screenshots, verify remote CI or exercise providers. Planning and delivery must establish those claims at the appropriate existing owners.
</specifics>

<deferred>
## Deferred Ideas

Events/webhooks/catalog/Connect/Home/navigation/search and cross-route language propagation remain Phase 242. Final integrated coverage, justified reviewed Linux goldens and feedback preview remain Phase 243. New subscription invoice filters, global queue redesign, Portal cleanup, diagnosis/causality/rooms, provider expansion, universal action frameworks, broad dependency migration, paid evaluators, CI redesign and publication remain outside this phase. No backlog capability was promoted.
</deferred>

---

*Phase: 241-billing-operator-journeys*
*Context gathered: 2026-10-09*
