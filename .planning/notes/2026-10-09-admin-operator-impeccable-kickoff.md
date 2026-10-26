---
date: 2026-10-09
status: consumed-by-kickoff
proposed_name: Admin Operator UI Cleanup
proposed_version: v1.64
formal_activation: true
approved_milestone: v1.64
---

# Accrue Admin Operator UI Cleanup: kickoff stocktake

The maintainer explicitly requested an **Accrue** Admin/operator UI cleanup using Impeccable and the installed Emil Kowalski skills. Names of other projects in the pasted prompt are references for lessons, not implementation targets. The latest instruction is to take stock before fully opening the milestone. This note preserves that work; it does not create requirements, a roadmap, execution plans, or an active milestone.

**Subsequent activation, 2026-10-09:** The maintainer invoked `$gsd-new-milestone Admin Operator UI Cleanup` and approved the compact v1.64 scope/version recommendation, adding one bounded multi-lens due diligence pass. This historical stocktake is now consumed by the active kickoff. [Focused diligence](../research/v1.64/) supplements it; requirements and roadmap retain their confirmation gates. The original pre-kickoff statements below describe the stocktake's state at capture, not a continuing activation block.

**Kickoff and Phase 240 planning complete, 2026-10-09:** All 18 requirements and the four-phase roadmap are approved. Six Phase 240 plans across four waves passed independent checking; the current next command is `$gsd-execute-phase 240`. Use [the decision summary](../research/v1.64/SUMMARY.md), [approved roadmap](../ROADMAP.md) and [planning verification](../phases/240-shared-system-and-real-billing-exemplar/240-PLAN-CHECK.md). No further kickoff, diligence, initialization interview or accepted-plan rewrite is needed.

## Settled intent and continuity

- Refine the existing operator interface toward familiar controls, clear task and information hierarchy, readable typography, coherent spacing, restrained state color, and consistent billing language. Serve common support work and deeper engineering investigation together.
- Make the shared building blocks stronger and propagate them through real journeys. Avoid forced columns, unnecessary nested cards, tiny text, gratuitous decoration, hidden routine controls, and automatic table treatment for every kind of content. Tables remain useful for comparing records; narrow screens need deliberate adaptation.
- Automate testable acceptance and agent visual inspection. Target zero required human UAT; owner feedback after delivery is optional input for a named correction or later iteration. Avoid paid visual judges and unbounded aesthetic scoring loops.
- This request is an explicit strategy decision to continue flagship Admin refinement after v1.63. **Formal milestone activation is deferred at the maintainer's request.** The proposed version is v1.64; phase numbering continues at 240 when the roadmap is approved.
- v1.63 completed Phases 233–239 and its scoped billing/authorization/coverage work. Preserve those completed contracts. The October 7 [kickoff brief](2026-10-07-accrue-ui-refinement-scope.md) was consumed by that milestone; it is historical input, not an unfinished plan to execute again.

## Existing Impeccable setup: reuse it

`PRODUCT.md` already exists, `.impeccable/config.json` records `"buildPath": "code"`, and the October 7 kickoff explicitly records completed Impeccable initialization. Do not repeat the audience, brand, or build-path interview. Engineers and support/billing operators are equal primary Admin audiences; customers use the separate Portal.

One product-context passage is now stale: `PRODUCT.md` still describes mixed-account Portal resolution as proposed. v1.63 implemented that contract; the current [host adoption example](../../examples/accrue_host/README.md#optional-customer-portal-context) documents it. Refresh that factual passage during subsequent authorized context work without reopening the product decisions or bringing Portal refinement into this Admin-only scope.

There is no root `DESIGN.md`. That does not make this a new visual world. The incumbent authority is Admin [`theme.css`](../../accrue_admin/assets/css/theme.css), the ratified Brand DNA/brandbook, and the archived [shared semantic direction](../milestones/v1.63-phases/233-shared-direction-portal-contract/DESIGN.md). Preserve Accrue's identity, Geist/Geist Mono, and package-owned `--ax-*` roles. Impeccable's **Operate** mode fits: scanability, consistency, standard affordances, and the operator's task outrank visual novelty. Record the incumbent system during the first delivery slice; avoid a separate rebrand or aesthetic workshop.

The context launcher was called once in this stocktake with an incorrect `packages/accrue_admin` target. The actual source target was then established directly as **`accrue_admin/`**. Its missing-target/new-world output is not evidence that Accrue lacks an implemented design system.

## Actual surface and workflow inventory

[`accrue_admin/lib/accrue_admin/router.ex`](../../accrue_admin/lib/accrue_admin/router.ex) owns **21 production LiveView routes**, relative to a configurable host mount. The canonical Cadence example mounts `/admin`; package fixtures also use `/billing`. Legacy `/charges` routes redirect to `/payments`.

| Task family | Existing operator work |
| --- | --- |
| Home, search, scope and navigation | Find a customer; retain owner/object/filter context; enter the appropriate task. |
| Customers and subscriptions | Inspect billing identity, lifecycle, invoices, methods, entitlements and activity; review an eligible existing subscription action. |
| Invoices and payments | Understand exact money and collection state; stage supported payment/finalization/void/refund work with the actual consequence. |
| Recovery | Review the selected time window and currency; investigate a campaign without conflating past failures with current state. |
| Events and webhooks | Trace local events and delivery evidence; select/confirm eligible replay; distinguish requeued, processed and unknown outcomes. |
| Coupons, promotion codes and Connect | Inspect existing provider-specific terms/relationships and stored observations; keep local fee overrides distinct from remote account readiness. |

Embedded controls need journey coverage too: filters, sort/pagination, selection, global search, theme preference, related-resource links, disclosures, payloads, drawers, confirmation, step-up, validation, and focus after LiveView patches.

Reuse the existing [component registry](../../accrue_admin/lib/accrue_admin/dev/component_registry.ex), [component parity ledger](../milestones/v1.63-phases/239-integrated-quality-handoff/239-COMPONENT-PARITY.md), and [coverage ledger](../milestones/v1.63-phases/239-integrated-quality-handoff/239-COVERAGE.md). They already describe 30 families, 42 variants and eight component-group contracts. Do not create a competing exhaustive inventory or new component framework.

## Current evidence and concrete cleanup candidates

No Accrue preview server was serving during this stocktake: the canonical proxy request returned HTTP 404 and no Accrue Docker service was running. No app was started, no fixture reset/reseed was performed, and no browser/test suite was run.

Instead, inspected the October 9 [invoice collection capture](../milestones/v1.63-phases/237-admin-invoices-payments-recovery/captures/237-08/invoice-collection.png) and [invoice review capture](../milestones/v1.63-phases/237-admin-invoices-payments-recovery/captures/237-08/invoice-review.png). All **nine recorded source fingerprints** in their [manifest](../milestones/v1.63-phases/237-admin-invoices-payments-recovery/captures/237-08/manifest.json) still match, and all **three PNG digests** match. Since its recorded source head `b113b182`, the relevant Admin source delta is formatting in DataTable and Dashboard only. These are useful source-associated captures, not a new observation of a running app. Older home/subscription goldens do not establish the current screens.

| Evidence | Candidate outcome |
| --- | --- |
| Invoice review capture exposes procedural copy about the "existing invoice workflow" and an "admin audit row", with repeated confirmation language. The helper is in `live/invoice_live.ex`. | Lead with the affected invoice/customer, exact amount/currency and supported consequence. Keep any required audit/safety meaning while removing routine implementation narration. |
| The 320px invoice collection has filter controls plus a separate filter panel, repeated clear/count treatments, a generic "ROW" label, and `charge_automatically` rendered as the collection value. | Simplify the hierarchy and reuse one human-readable billing vocabulary; retain applied-filter clarity and direct action access. |
| `assets/css/app.css` still gives detail sections 0–1px gaps, 0.5px heading padding, weights 850/900/950, and shared action-band buttons a 24px minimum height. | Confirm current mounted composition, then replace arbitrary compression with semantic type/spacing/control roles at the owning selector. Inspect desktop density and coarse-pointer/narrow behavior separately. |
| Staged drawers have both Close and Cancel dismissal labels; webhook unavailable/empty copy has drift from its declared resource vocabulary. | Distinguish dismissal/discard from an actual billing cancellation; consolidate copy without changing event semantics or implying complete history. |
| Token documentation allows a deliberate 2px dense rung, while one archived phase prohibited all spacing below 4px. | Resolve the documentation interpretation once. Preserve intentional dense inline spacing and remove unexplained subpixel section layout; do not blindly delete a valid global token. |

Source-only findings remain candidates until checked on current mounted output. A full-page screenshot of a viewport-fixed scrim does not prove that content below the capture's viewport leaks during real scrolling; verify that interaction in the browser before filing an overlay defect.

## Lessons transferred from sibling projects

These are observed sibling-project failures and proposed Accrue safeguards. They do not assert that Accrue currently has the same bugs.

| Observed lesson and source | Accrue safeguard |
| --- | --- |
| ScryPath `698013c`: pointer hover and keyboard navigation selected different command-palette rows. | One selection authority; exercise pointer → ArrowDown/Enter and assert visual selection plus ARIA. |
| ScryPath `b10ba7d` / `7abb4c9`: `phx-disable-with` replaced rich control markup and lost refresh icons; hooks needed stable IDs. | Test real idle → busy → idle activation and repeated LiveView updates, not just button presence. |
| ScryPath `961ecf4`: utility-layer rules overrode intended toast colors. | Check computed styles from the built and served stylesheet in each effective theme. Token declarations alone do not prove consumption. |
| ScryPath `2977c92`: Impeccable live edits left duplicate wrappers, nested cards and action-looking prose links. | Inspect shared component DOM and page hierarchy after edits; remove temporary preview structure at source before propagation. |
| ScryPath `1b2287e`: row replacement lost focus; errors outside an inert dialog were inaccessible. | Exercise validation → corrected submission, dismissal/success, Tab/Shift-Tab, competing overlays and focus return to a surviving element. |
| ScryPath's v1.43 feedback reopened overcolored states, decorative gradients and a mismatch between System preference and effective-theme selection. | Neutral resting surfaces, localized status cues, and one visibly selected stored preference; test OS theme changes separately. Zero errors/counts cannot imply overall billing health. |
| ScryPath evidence records: screenshot filename/width inventory, contrast-only axe and a single Tab were initially overclaimed. | Assert actual behavior, geometry, meaningful styles and full interaction sequences; inspect representative images for composition. |
| Threadline Phase 238: long filters overflowed at narrow widths; direct-entry clipboard paths differed from navigated paths. | Include fresh direct entry, long unbroken IDs/content, narrow drawers and clipboard success/failure where applicable. |
| Mailglass Phase 168: a reviewer reached Traefik rather than the application; historical scores could look current. | Identify the app, source revision, fixture and served asset digest before calling a capture current. |
| ScryPath preview/recovery notes: verification resets could disrupt retained review data. | Keep the dev feedback preview and disposable mutating proof fixture separate; record stop/reopen instructions and custody. |

Further local sources: ScryPath `.planning/reference/OPERATOR-UI-QUALITY.md`, `OPERATOR-UI-REFINEMENT.md`, `.planning/research/v1.42/UI-AUTOMATION.md`, and archived Phase 172 review/evidence; Mailglass `.planning/research/v2.9/SCOPE.md` and Phase 168 UI review; Threadline Phase 238 baseline findings/handoff. No sibling files were edited.

For conventional task patterns, [Oban Web](https://oban.pro/docs/web/overview.html) demonstrates filtered list → detailed investigation → bounded action in a mounted Phoenix operator interface. [Stripe's invoice Dashboard documentation](https://docs.stripe.com/invoicing/dashboard/manage-invoices) describes status-aware invoice lists/details and actions. These are functional references, not authority to copy a palette or add their capabilities. The [official Kowalski skills](https://github.com/emilkowalski/skills) and installed local motion guidance support purposeful feedback and restraint; do not transplant React/native dependencies into this LiveView package.

## Proposed delivery slices, not an approved roadmap

1. **Shared system and real exemplars.** Identify served-source truth, inspect representative light/dark desktop/narrow states, record the incumbent design, and deliver one coherent list/detail/action exemplar. Fix owning type/spacing/action rules in that same slice.
2. **Billing operator journeys.** Propagate the proven patterns through customer, subscription, invoice, payment and recovery work. Keep identity/state/amount/action/consequence in scan order and preserve related-resource/return context.
3. **Investigation and remaining surfaces.** Apply the system to events, webhook delivery/replay, coupons, promotion codes, Connect and shell controls. Keep diagnostic detail accessible through familiar disclosure and exact state language.
4. **Integrated evidence and feedback preview.** Close named regressions through the existing acceptance owners, inspect the final changed compositions, update justified Linux goldens, and leave a reachable Fake-backed preview with a concise changes/remaining-limits record.

Scope is the current `accrue_admin` UI and the example-host seams needed to view and prove it. Preserve custom mount paths, host auth/configuration, owner scope, fresh target authorization, step-up, duplicate protection, processor eligibility, exact money and lifecycle semantics. Keep customer Portal styling separate. The large SEED-004 blueprint is continuity context only: its M1 was shipped in v1.57; new diagnosis functions, causality graphs, Usage rooms and provider capabilities remain future scope choices. The parked v1.56 AI ratchet is not a default acceptance mechanism.

## Automated acceptance and bounded visual review

- Extend existing ExUnit/integration, mounted-host Playwright, Admin browser, axe, token/bundle and component/Storybook gates for named recurring defects. Do not add a parallel CI workflow merely to repeat existing proof.
- Measure current control activation, focus containment/return, direct-entry/reconnect behavior, dark/system preference, long and missing data, empty/no-match/unavailable distinctions, 320px reflow and actual zoom. Check computed contrast and touched type/spacing relationships. Use actual coarse-pointer target checks where relevant.
- Preserve authorization, exact money/currency, replay legal copy and honest accepted/pending/unknown outcomes as behavioral assertions. A snapshot change cannot waive those contracts.
- Capture route/state/theme/viewport/source and **served asset hashes**. Account for source ownership: `mix accrue_admin.assets.build` must rebuild the committed Admin bundle; host CSS watchers do not rebuild source `accrue_admin/assets/css` automatically.
- Use the existing Linux-native Admin pixel lane for selected stable goldens after inspecting intended changes. Stable screenshots catch regression; filename counts and scalar design scores cannot establish quality. Mask only volatile content, never status, amounts or actions.
- Declare one bounded review cycle for each agreed delivery batch: finish the batch, inspect desktop/mobile together, apply one corrective batch, confirm once, and record closure. Screenshots, defect scans, edits and rebuilds share that budget. Reopen only for named new evidence or explicit owner feedback; do not reset the budget under a new aesthetic label.
- No recurring paid AI visual evaluator. Agent inspection uses the existing tools; stable measurable behavior belongs in CI. Target zero required human UAT, with optional owner taste feedback after the finished baseline.

## Preview and evidence ownership

Use the canonical [host startup path](../../examples/accrue_host/README.md): `cd examples/accrue_host`, `make proxy` once, then `make up`. Its stable operator entry is `http://accrue.localhost/admin`, with a loopback fallback printed by the banner and the fictional operator login documented there. Keep observation read-only after login. Do not reset, reseed or run proof as feedback actions.

The normal example-host mount intentionally disables `/admin/dev/components` and Storybook. Use the separate package fixture endpoint for those laboratories. Preserve the distinction between fixture/kitchen evidence and mounted host evidence.

The current README link to the archived [Phase 239 preview handoff](../milestones/v1.63-phases/239-integrated-quality-handoff/239-HANDOFF.md) and its return link to the host README were repaired during this stocktake. Only link locations changed; archived closeout evidence remains historical.

## Exact next action

The stocktake and milestone kickoff are consumed. Phase 240 is planned and ready for execution. Run:

```text
$gsd-execute-phase 240
```

Reuse the settled product/brand/build-path context, closed v1.63 contracts and approved Phase 240 artifacts. No repeat stocktake, milestone/requirements/roadmap confirmation, Impeccable init, broad cross-project research, accepted planning or re-execution of Phases 233–239 is needed. Actual mounted delivery evidence remains execution work.

Stocktake verification: no implementation tests run; nine capture-source fingerprints and three image digests matched; covered post-capture source changes inspected as formatting only; preview HTTP 404 reported honestly. Documentation/link and GSD bookkeeping checks are recorded with the stocktake commit.
