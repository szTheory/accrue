---
milestone: v1.64
name: Admin Operator UI Cleanup
date: 2026-10-09
status: milestone-initialized-ready-to-plan-phase-240
review_type: bounded-three-lens-upstream-review
scope_version_approved: true
requirements_approved: true
roadmap_approved: true
roadmap_created: true
---

# v1.64 upstream decisions and delivery direction

## Outcome and stopping decision

The maintainer approved v1.64's Admin-only scope/version, then explicitly requested one additional fan-out to check breadth and depth before downstream work. Three independent reviews covered graphic design/type/color/layout/motion, UX/jobs/information architecture/content, and accessibility/LiveView/asset/verification/CI seams. They reused the [stocktake](../../notes/2026-10-09-admin-operator-impeccable-kickoff.md) and existing sibling lessons rather than repeating broad ecosystem research. Official W3C and Playwright references supported precise acceptance distinctions.

**Recommendation:** retain four delivery slices, strengthen the first real exemplar and add checks with each owning change. No new product decision blocks requirements. No new library, visual world, diagnosis capability, Portal work, paid visual evaluator, global accessibility certification campaign, or CI redesign is justified. The review is complete: further source scanning is unlikely to change scope, order, or acceptance. Next evidence comes from current mounted delivery, not another interview or upstream review.

**Evidence limits:** source review and inspected source-associated historical captures only. No app startup, fixture mutation, test execution, fresh browser inspection, remote CI, live-provider proof, actual browser zoom, screen-reader speech, or physical-touch observation occurred in this pass. Source navigation mismatches are concrete; apparent density/control/motion issues still need mounted confirmation. A candidate can be closed as unobserved or already adequate without a cosmetic edit.

## Review records

| Record | Lenses and useful depth |
|---|---|
| [Visual system](VISUAL-SYSTEM.md) | Owning type/spacing roles, density exceptions, task hierarchy, mobile/tablet/coarse-pointer controls, theme consumption, motion frequency and removal timers, asset ownership. |
| [Operator experience](OPERATOR-EXPERIENCE.md) | Equal engineer/support jobs, six families covering 21 routes, visible versus disclosed facts, queue/filter/return meaning, self-contained action reviews, diagnostic language and state-specific recovery. |
| [Automation and seams](AUTOMATION-AND-SEAMS.md) | Existing lane map, keyboard/ARIA/zoom limits, real busy/reconnect transitions, target/money invariants, source/build/compiled/served provenance, snapshot failure paths, preview custody, bounded cost/performance diagnostics. |

## Material decisions and dispositions

| Decision | Alternatives and tradeoff | Disposition / downstream consequence |
|---|---|---|
| Keep the incumbent system | A new scale/framework/palette creates migration and relearning; per-page patches perpetuate drift. | Use existing Cobalt, Geist/Geist Mono and package-owned `--ax-*` roles. Fix the owning shared selector/component and propagate. First slice records the incumbent authority, not a new aesthetic workshop. |
| Deliver a real exemplar early | A foundation-only phase postpones task evidence; polishing all pages before observing one multiplies mistakes. | First slice includes invoice list → detail → action review plus a dense subscription check. Establish current served truth and actual interaction there before propagation. |
| Density follows the job | Blanket larger spacing loses comparison density; unexplained compression buries task boundaries. | Preserve deliberate 2px dense/1px structural exceptions. Use existing larger roles between tasks and sections; inspect heading/body/label relationships and long-content behavior. Resolve the old 2px/4px wording once. |
| Input mode matters beyond width | Route-specific mobile overrides can miss other consumers and tablet touch. | Confirm action-band specificity/geometry in mounted narrow and intermediate/coarse-pointer contexts; retain the incumbent larger frequent-action targets without falsely naming them an AA threshold. |
| Simplify chrome, preserve control | Hidden filters lower initial chrome but increase repeated work; repeated panels/counts obscure the result set. | Consolidate one understandable filter/result hierarchy; keep routine filters, active queue/lens, scope and essential actions visible. Tables remain for comparison; details/timelines/payloads use appropriate existing forms. |
| Make destinations truthful | Adding a subscription filter would expand functionality; leaving the ignored parameter misleads. | Use supported customer-scoped invoice context and separately labeled owner queue. Correct campaign direct entry to scoped Recovery. Preserve supported list filters and customer tabs through bounded local returns. |
| Preserve both operator audiences | Closing every detail hides engineering evidence; leaving every fact equally prominent buries routine work. | Prioritize identity/scope → current facts → supported next action → related evidence. Keep blockers/uncertainty/consequences visible and exact diagnostic detail discoverable. Retain current Home and static nav families. |
| Copy follows billing truth | Internal implementation narration is costly to interpret; indiscriminate simplification can erase provider/audit meaning. | Align payments, invoices, events versus deliveries and collection terms via existing Copy owners. Preserve locked legal/audit strings and exact diagnostic terms. Never infer settlement, freshness or health from acceptance, missing evidence or zero counts. |
| Review the decision, not the procedure | Generic repeated confirmation is easy to reuse but can hide the actual target and consequence. | Make reviews self-contained: target/customer, exact money/currency when relevant, supported consequence/timing, and truthful result boundary. Preserve fresh revalidation, step-up and duplicate protection. |
| Motion serves state and orientation | Choreography adds latency to frequent work; blanket motion removal can discard useful feedback. | Keep repeated keyboard work immediate. Check real idle → busy → idle, patches, rapid dismissal and reduced-motion teardown. Do not animate routine counts/money/navigation or enable controls from network availability alone. |
| Test at existing semantic owners | A new full matrix/workflow duplicates fixture/setup cost; pixels or axe alone miss behavior. | Extend named existing ExUnit, package browser, mounted host, axe, registry/build and Linux pixel owners with each slice. Use focused negative controls for new guards. Retain required checks; no new sleeps/retries/tolerance increases to hide failures. |
| Close evidence blind spots | Any-PNG guards can skip pixels if all snapshots vanish; broad masks and HTTP-only observers can overclaim proof. | Fail on missing expected baseline set; mask only explicitly volatile values. Scope HTTP observations to HTTP or use authoritative state/dispatch/audit assertions in the disposable fixture. Distinguish source, current render, exercised behavior and local/remote outcomes. |
| Keep preview separate from proof | Reusing a feedback database for resets/mutations destroys review continuity. | Retain the documented Fake-backed `/admin` preview and disposable test fixtures. Package `/billing` labs and host `/billing` Portal are distinct; absent labs in the normal host are intentional. |
| Bound inspection and performance work | Paid scores, universal goldens and arbitrary timing thresholds add ongoing cost without a clear finish. | One inspection batch, one corrective batch, at most one confirming inspection per agreed delivery batch. Selected stable Linux goldens only. Record lightweight comparable diagnostics at the first fresh exemplar; investigate observed deterioration without building a new timing platform. |

## Specific source findings to carry into delivery

1. Subscription invoice links send ignored `subscription_id` but promise narrowing. Prefer supported `customer_id` plus truthful customer wording; keep an owner queue link separately when useful.
2. Campaign direct entry resolves a Recovery-labeled return through the generic Subscriptions fallback. Use scoped Recovery when origin context is absent/invalid; preserve an existing valid recovery window.
3. Invoice/payment list links omit contextual return, and return allowlists omit some existing decoded filters. Extend only bounded enumerated existing meanings; never accept arbitrary origins or foreign scope.
4. Detail/action-band compression and specificity may defeat shared control sizing outside customer/subscription pages. Confirm actual geometry before editing.
5. Current captures show redundant filter hierarchy, raw collection enums and procedural review copy. Confirm current composition, then fix shared presentation rather than adding wrappers.
6. Real busy markup, replaced controls during reconnect, System preference versus effective styles, and full overlay validation/focus paths need targeted coverage when touched. Existing named tests are starting owners, not proof that every new scenario is covered.
7. The pixel workflow's any-PNG gate is fail-open for deletion of the entire baseline set. Strengthen its expected-set contract in the existing owner; don't demote/skip pixels.
8. A page non-GET HTTP collector does not establish absence of LiveView mutations. Preserve the narrower claim or prove state/dispatch/audit invariants in disposable fixtures.

## Approved four-slice order

| Phase | Slice | First-order work and acceptance |
|---|---|---|
| 240 | Shared system and real exemplars | Record incumbent roles/exceptions and user-facing vocabulary; mount current invoice list/detail/review; fix owning shared layout/control rules; include theme/focus/busy/served-assets and expected-snapshot checks needed by the exemplar. |
| 241 | Billing operator journeys | Propagate through customer/subscription/invoice/payment/recovery; close truthful-destination and scoped return/window gaps; preserve self-contained action facts and existing safety evidence. |
| 242 | Investigation and remaining surfaces | Events/webhooks/catalog/Connect and shell/search; exact diagnostic disclosure, events-versus-deliveries, bounded relationships/returns, changing-state and keyboard acceptance. |
| 243 | Integrated evidence and feedback preview | Reconcile current coverage against the existing 21-route/registry owners; inspect final changed compositions within the budget, update justified reviewed Linux goldens, and leave reachable preview/remaining-limits handoff. |

The maintainer approved the concrete [roadmap](../../ROADMAP.md) on 2026-10-09, with all 18 requirements mapped exactly once. Every phase owns acceptance with its changes; Phase 243 aggregates closure. It must not be the first owner of authorization, keyboard, responsive or served-asset proof. Primary mappings and complete success criteria live in that roadmap and [REQUIREMENTS.md](../../REQUIREMENTS.md).

## Settled, deferred and reopening rules

- **Settled:** scope/version/requirements/roadmap approval, Admin-only refinement, equal operator audiences, incumbent identity, code-first Impeccable setup, four-slice order, zero required human UAT target and optional subjective feedback, existing acceptance owners, no paid evaluator.
- **Deferred:** Portal, core diagnosis/causality/new rooms (SEED-004 M2/M3), provider expansion/fidelity runs, global CI redesign, exhaustive snapshot matrix, unrelated release windows and historical verification debt. SEED-003 is a bounded hygiene constraint; its old release campaign is not new scope. Seeds remain unmodified.
- **Delivery evidence outstanding:** fresh mounted candidates, actual input/zoom methods and limitations, controlled busy/reconnect cases, current served asset digests, selected golden/mask changes and execution outcomes.
- **Owner decisions outstanding:** none at kickoff. All 18 requirements and the concrete four-phase roadmap were approved on 2026-10-09. No new product interview or aesthetic choice is needed.
- **Reopen only for:** a named new defect, safety/behavior failure, changed task requirement, or explicit owner feedback. Preserve the original review budget; do not reset it by renaming the polish task. Necessary repair of a failed behavioral gate is not another aesthetic round.

## Continuation checkpoint

The full approved list is in [REQUIREMENTS.md](../../REQUIREMENTS.md); the maintainer confirmed all 18 items and the concrete [roadmap](../../ROADMAP.md) on 2026-10-09. Phases 240–243 map 18/18 requirements exactly once. Milestone kickoff is complete. Next command: `$gsd-plan-phase 240`. Preserve v1.63's archive, use the recorded decisions, and continue without recreating the roadmap or repeating research, requirements/roadmap confirmation, or Impeccable init. A context clear is safe; these files retain the delivery and verification signal.

**Codex SDK dispatch:** Use `GSD_RUNTIME=codex` for GSD model/agent resolution calls in Codex sessions. The installed CLI otherwise resolved Claude models during this kickoff; the explicit runtime correctly resolved the roadmapper to the project's Codex model and effort. This is a per-command runtime selection, not a project/global config change.
