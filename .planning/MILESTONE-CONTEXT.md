# Next milestone context: Admin and Portal UI refinement

Prepared 2026-10-07 for `$gsd-new-milestone`. Upstream research/discussion are complete. The user requested this stopping point before clearing context and formally creating the milestone. This file is planning input, not milestone activation or implemented UI.

## Required reading before requirements or roadmap

1. `PRODUCT.md` — product, audiences, ownership, voice and truthfulness.
2. `.planning/notes/2026-10-07-accrue-ui-refinement-scope.md` — full inventory, findings, 34 proposed requirements, seven phases, tradeoffs, acceptance, delivery and primary sources.
3. `.planning/notes/2026-10-07-portal-billable-context-contract.md` — accepted generic Portal approach, host resolve/authorize integration, compatibility and failure cases.
4. `.impeccable/config.json` — initialized code-first preference.
5. `CLAUDE.md` — local execution/evidence and repository discipline.

Include the two notes and PRODUCT.md in delegated planners'/roadmapper's required reading. No important signal depends on previous chat or temporary specialist reports. This entry file can be consumed/deleted by new-milestone; the notes persist.

## Status and proposed identity

- Proposed: **v1.63 — Admin and Portal UI refinement**, candidate phases **233–239**.
- v1.62 is complete/archived; phases 229–232. Continue numbering at 233; do not reset.
- Phase boundaries and requirement IDs are proposals for formal planning; preserve accepted outcomes if refining the split.
- Latest user acceptance: “okay that sounds good” after the generic personal/company Portal recommendation, followed by the request for this pre-milestone handoff.
- The September instruction excluding UI work is superseded by the October request. No unresolved personal-versus-workspace choice remains.
- No formal milestone files/state switch, application source implementation, app boot, test run or fresh UI capture was performed for this preparation.

## Goal

Deliver a coherent, readable, responsive and trustworthy baseline across all existing Admin and Portal journeys plus the relevant example-host billing entry/return paths. Use established patterns, consistent domain language and shared design rules. Automate routine acceptance and bounded visual inspection, then leave a working preview for optional owner feedback and later iteration.

## Accepted decisions — do not re-interview

- **Scope:** Admin and Portal together: 21 Admin + 7 Portal pages, four Portal POST paths, embedded actions and named host pricing/billing/auth-return/provider seams. Provider-owned pages remain external boundaries.
- **Audiences:** engineers and support/billing operators equally primary in Admin. Portal serves customers and their authorized company representatives. Customer billing managers do not gain vendor Admin privileges.
- **Library model:** one Portal for personal, organization/custom and mixed billables. Keep personal defaults; optional host billable resolver plus per-action authorizer. Host owns selection, membership and policy. Separate actor, billable, Customer, processor and target. No mandatory organization or universal picker.
- **Build method:** code-first. Impeccable initialization is complete (`PRODUCT.md`, `buildPath: code`). Do not repeat the init interview or impose generated-image comp approval.
- **Visual direction:** familiar readable operational UI, content-appropriate tables/lists/facts/forms/timelines, coherent type/spacing/padding/radii/shadows/layers/state colors. Preserve Admin identity and configured customer branding; they need not look identical.
- **Motion:** use Impeccable and installed Kowalski/Emil guidance in Phoenix/CSS/LiveView. Immediate repeated keyboard work; short purposeful interruptible motion and reduced-motion support. No animation dependency by default.
- **Dependencies:** small understandable local code/copied patterns with provenance first. Keep official payment SDK boundaries; no framework migration or homemade secure card inputs.
- **Autonomy/cost:** existing deterministic tests/browser tooling, real image inspection, finite named defects, no paid visual judge or endless aesthetic ratchet. Optional owner feedback follows objective acceptance; no recurring manual UAT labor.
- **Engineering scope:** bounded fixes to UI-derived state/money/date/scope, navigation, existing wiring/feedback, exact Customer lookup and the explicit generic Portal integration are part of refinement. New billing-engine/provider capabilities are not.

## Findings the plan must preserve

Source findings, not runtime-reproduced incidents:

1. Admin turns missing ancillary data into inactive billing; conflates draft/open; loses currencies; invents urgency from missing dates; subscription/customer link labels have reversed destinations.
2. Some summary query scope differs from destination scope; a mounted denial browser case is skipped after a reported 500. Reproduce/repair the seam, preserve server guards and do not call skipped proof passing.
3. Local density/control CSS defeats shared roles/mobile targets; nav/floating-surface/focus/motion contracts need current-browser evidence. Do not preserve unwanted geometry just because old tests assert it.
4. Portal flashes lack a package renderer; add-card markup lacks the existing checkout Hosted Fields binding. Existing browser tests do not prove card tokenization/submission. Secure fields have distinct provider styling/readiness/lifecycle constraints.
5. Checkout errors claim a charge without evidence; missing price can appear as zero USD; expiry/completed/promo guards differ between completion paths. Correct existing-flow boundaries and truthful outcomes.
6. Portal currently derives Customer from current_user. Extra mount hooks do not solve POST/action authorization. Implement the small generic contract, bind old forms to displayed accounts, reauthorize each action and prevent read-only access from minting broad provider-management grants.
7. Customer identity includes owner type/ID/processor, but some core/host lookup paths omit processor. Align them without adding dynamic provider routing.
8. Known Portal statuses, host access, recent invoice counts and retention wording overstate available evidence. Preserve provider-specific cancellation timing and action differences. No new Portal resume/local-PDF feature is implied.

Detailed locations, alternatives, counterexamples and acceptance are in the notes. Fresh rendering, test health, SDK behavior and mounted scope behavior remain implementation probes. Historical PNGs and pass counts are not current proof.

## Candidate outcome phases

| Phase | Outcome |
| --- | --- |
| 233 | Current served-source baseline and shared visual direction in a real Admin detail and Portal overview; settle generic Portal context/action contract and exact provider identity early. |
| 234 | Admin customer/subscription investigation and supported lifecycle work; state truth, owner context and navigation. |
| 235 | Customer plan choice/checkout, host continuity, secure fields, failures/cancel/return and both completion paths. |
| 236 | Portal personal/company/custom/mixed self-service: methods, existing invoice access, supported changes/cancellation, feedback/context. |
| 237 | Admin invoices/payments/refunds/recovery with truthful states, amounts and resulting evidence. |
| 238 | Admin Events/Webhooks/replay and remaining Coupons/Promotion codes/Connect surfaces. |
| 239 | Integrated acceptance/current visuals/required gates/assets/copy/docs/CSS retirement and clean preview handoff. |

Each phase owns its relevant mobile/theme/keyboard/accessibility/copy/motion/state proof. Do not defer it wholesale to 239. Assign one owner per shared CSS/hook/copy file during parallel work.

## Execution rules worth carrying forward

- Create `DESIGN.md` from current rendered exemplars; it does not yet exist. PRODUCT owns product boundaries; actual tokens/components own implementation; phase UI-SPEC owns scoped application/acceptance. Link authorities instead of cloning conflicting token catalogs.
- Inspect every owned page once, then sample theme/viewport/state combinations and unique high-risk actions. Retain useful stable pixel anchors, avoiding the full Cartesian screenshot matrix.
- ExUnit/LiveView proves state, scope, policy and rendered form outcomes; Playwright proves actual navigation, hooks, focus/patch/overlay lifecycle and geometry. Reuse equivalent existing checks.
- Keep the retained feedback preview separate from reset/mutation proof. Host wrappers drop test DBs; fixture resets share state. Use existing instance mechanisms.
- Admin builds committed assets. Portal authors assets directly but embeds bytes/hashes at compile time. Verify actual mounted delivery after recompilation; preserve public tokens, host branding, alternate mounts, CSP/SRI/fonts.
- Portal needs explicit mobile coverage selection; Admin mobile/visual/build gates do not cover it automatically.
- Migrate stale tests using old assertion → protected invariant → replacement. Keep safety/legal/replay/auth checks. The v1.56 ratchet guardrail stays parked; machinery selftests/waiver/expiry checks remain blocking. Existing pixel baselines use their established Linux/browser environment.
- Keep executable UAT/SUMMARY/VERIFICATION and archive-aware evidence rules. Do not invent certification or recurring human testing gates.

## Research reuse and seeds

Product/design/delivery fan-out, adversarial synthesis and generic Portal architecture/security/UX research are complete. Primary sources and Scrypath lessons are recorded. Recommend reusing this evidence and proceeding to requirements/roadmap, with focused phase research for concrete unresolved implementation questions. Do not restart broad ecosystem research or change persistent research/model preferences to skip a one-time step.

Scrypath contributed shared-control/named-defect/finite-review/preview-isolation lessons. Its active UI milestone is not assumed finished; its palette/templates are not Accrue requirements. A fresh session need not broadly reread that sibling repository.

SEED-004 is historical input: M1 shipped in v1.57. M2/M3 diagnosis/causality/new rooms are not included. SEED-003 is not authorization for a broad hygiene project. Other seeds remain deferred unless explicitly necessary; do not auto-enroll unrelated seeds via --auto.

Excluded: new processors/billing capabilities, universal tenancy/roles/account discovery, consolidated payer arrangements, operator impersonation, dynamic provider routing, currency conversion/risk engines, unrelated host pages, rebrand/framework changes, provider-hosted visual redesign, paid evaluation and wholesale CI rearchitecture.

## State reconciliation and worktree

The local read-only GSD init reports latest completed v1.62 and zero active phase directories. Previous closeout records PR #45 merged, package release and successful CI at 210e9568; these are historical records, not a current remote check. Source head before this preparation checkpoint is 7971753a (the later resting-state handoff commit).

STATE.md, ROADMAP.md and parts of PROJECT.md retain superseded red-candidate/release-handoff prose. Reconcile current headings during normal formal activation via GSD's state switch. Do not resurrect completed release work, remint archived verification as current proof or enroll unrelated audit/deferred debt.

.planning/config.json already had a user-owned runtime/model change; this preparation does not own it. Preserve it. Read live git status; timestamped handoff snapshots are not a substitute.

## Exact next action

After clearing context:

```text
$gsd-new-milestone Admin and Portal UI refinement
```

GSD reads this file. Formalize the accepted direction into requirements and a dependency-aware roadmap. Version/phase layout and generated artifacts receive normal workflow review; do not repeat the audience/build-method/personal-company interview. UI implementation follows that planning transition.
