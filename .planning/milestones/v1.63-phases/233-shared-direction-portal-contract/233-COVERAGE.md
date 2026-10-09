# Phase 233 planning coverage ledger

## API scope and transport reachability

No new external API integration is introduced. The existing provider SDK and Hosted Fields remain within their current package boundary. The new optional surface is the local host-to-Portal `resolve(actor, selection)` / `authorize(actor, context, action, server_loaded_target)` contract. The exact action atoms below are the implementation contract; executor updates only if required by a discovered current callsite and updates docs/tests together.

| Action | HTTP GET | LiveView mount/reconnect/navigation | LiveView event | POST | Decision |
|---|---|---|---|---|---|
| `:read` | All seven entry routes | All seven | — | — | INTEGRATE; fresh read before provisioning |
| `:subscription_preview` | — | Detail target read | Plan preview | — | INTEGRATE |
| `:subscription_change` | — | Detail target read | Confirm change | — | INTEGRATE |
| `:subscription_cancel` | — | List/detail target read | Cancel/confirm | — | INTEGRATE |
| `:payment_method_create` | — | Add-card before client token/Hosted Fields | — | Rendered form to `/payment-methods` | INTEGRATE; fresh grant before capability issuance |
| `:payment_method_default` | — | Payment list renders pinned form | — | Rendered form to `/payment-methods/:id/default` | INTEGRATE |
| `:payment_method_delete` | — | Payment list renders pinned form | — | Rendered form to `/payment-methods/:id/delete` | INTEGRATE |
| `:checkout_read` | — | Checkout LocalSession read | — | — | INTEGRATE |
| `:checkout_validate_promo` | — | Checkout LocalSession read | Validate promo | — | INTEGRATE |
| `:checkout_complete` | — | Checkout before client token/Hosted Fields | Pinned `checkout_tokenized` | Rendered form to `/checkout/:token/complete` | INTEGRATE; fresh grant before capability issuance |
| Provider billing operations outside existing Portal journeys | — | — | — | — | OPT-OUT; no new billing/provider capability in Phase 233 |
| Universal account discovery, operator impersonation, dynamic provider routing | — | — | — | — | OPT-OUT; deferred by CONTEXT.md and REQUIREMENTS.md |

Every action receives the actor, resolved billable, exact Customer and configured processor; a server-loaded resource target is supplied where relevant. `:read` is checked before Customer provisioning and at reconnect. A hidden `context_pin` is minted by the rendered form using `Context.mint_pin/2`, signed with a dedicated Phoenix.Token salt and 20-minute lifetime, and verified by `Context.verify_pin/2` on the matching event/POST. It identifies the displayed context but is not permission. No missing/invalid/expired-pin fallback to current host selection exists; old-tab reconnect revalidates its pinned identity. Host policy is checked afresh before provider client-token issuance and every protected event/POST; existing Customer/target and provider guards remain. The provider-hosted scope and named actions above are unchanged.

## Assumption delta

Detector signal: chosen/custom selection changes the former single authenticated-user billable assumption. Primary noun: **resolved billable context**. Decision: **promote** this identity into the Portal boundary; personal billing is a variant of it, while the authenticated human actor remains separate. No Customer schema or data migration is needed: existing `owner_type`, lossless `owner_id` and configured `processor` already distinguish Customer rows. No adapter preserves current personal behavior.

## Spec-less fallback ledger

Input had 9 surfaced rows; 3 SAFE-02 rows are authored as explicit acceptance predicates in 233-01 `must_haves.truths`, and 6 unclassified rows remain flagged unresolved assumptions below. Equality: **9 surfaced = 3 explicit truths + 6 flagged assumptions**. None was dismissed or backstop-resolved.

| Requirement | Category | Disposition |
|---|---|---|
| BASE-01 | unclassified | Flagged assumption: bounded representative route/state capture is sufficient current baseline; Phase 239 owns exhaustive integrated coverage. |
| SYS-01 | unclassified | Flagged assumption: role alignment is judged through real changed consumers and current served evidence, with route-specific refinements in owning phases. |
| SYS-02 | unclassified | Flagged assumption: separate package CSS/token APIs and audience shells remain mandatory despite shared role naming. |
| POR-08 | unclassified | Flagged assumption: host supplies an explicit custom selection; library supplies no account discovery. |
| SAFE-02 | adjacency | Explicit: same owner ID with different owner type or processor stays separate. |
| SAFE-02 | empty | Explicit: nil/empty/invalid explicit custom selection blocks; no-adapter personal remains compatible. |
| SAFE-02 | ordering | Explicit: no first eligible organization/Customer fallback; explicit selection or personal default only. |
| SAFE-03 | unclassified | Flagged assumption: signed per-flow references are sufficient for independent tabs when host policy reauthorizes each context. |
| SHIP-04 | unclassified | Flagged assumption: canonical host and README examples cover personal/custom/mixed adoption without a new dependency. |

Prohibition recall was run over seven requirements. Kept project-specific value/scope constraints appear descriptor-less under `must_haves.prohibitions` in the plans with `status: unresolved`; the canonical projection uses `statement`/`status` and no fabricated `check_*` keys. Generic injection, access-control, CSRF, and provider-secret concerns are handled in the STRIDE registers and existing security gates, not minted as bespoke prohibitions.

## Multi-source audit

| Source | Items | Plan | Status |
|---|---|---|---|
| GOAL | Current coherent Admin/Portal baseline and one bounded selected billable contract | 01–07 | COVERED |
| REQ | BASE-01 | 04 | COVERED |
| REQ | SYS-01, SYS-02 | 04, 06 | COVERED |
| REQ | POR-08 | 01, 02, 03, 05, 07 | COVERED |
| REQ | SAFE-02 | 01, 02, 03, 05, 07 | COVERED |
| REQ | SAFE-03 | 02, 05, 07 | COVERED |
| REQ | SHIP-04 | 05 | COVERED |
| CONTEXT | D-01–D-05, baseline/visual semantics | 04, 06 | COVERED |
| CONTEXT | D-06–D-10, identity and optional host contract | 01, 02, 03, 05, 07 | COVERED |
| CONTEXT | D-11–D-17, transport/pinning/denial/reconnect | 01–03, 05, 07 | COVERED |
| RESEARCH | Existing stack; no new package, exact Customer triple, seven LVs/four POSTs, asset compilation, current served proof, personal/custom/mixed host examples | 01–07 | COVERED |

Deferred: route-specific redesign and action refinements 234–238; integrated all-route coverage 239; universal picker/roles/provider routing, separate recovery URL and new billing capabilities. These are excluded from this audit by source scope.
