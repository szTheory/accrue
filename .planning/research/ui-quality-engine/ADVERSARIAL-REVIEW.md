# UI quality engine: bounded adversarial review

**Date:** 2026-10-26. **Verdict:** Recommend the proposed v1.68 scope with two P2 plan clarifications below before activation. No P1 scope or architecture blocker found.
**Review scope:** Inventory, recommendations, milestone proposal, three research reports and owner direction. Source spot-checks covered review-host startup/isolation and CI workflow intake. This is a review of the proposal, not executed UI, security, accessibility, performance or CI acceptance.

## Findings requiring incorporation into the proposal

### AR-01 · P2 · Make review-lab startup and isolation an explicit first-slice deliverable

**Proposal locations:** `MILESTONE-PROPOSAL.md:31`, `MILESTONE-PROPOSAL.md:45`, `MILESTONE-PROPOSAL.md:67`; `ARCHITECTURE.md:97`.

The plan sensibly reuses the existing Admin endpoint, but currently specifies a review surface without an explicit safe launch/isolation contract. The existing launcher is not DB-free: `accrue_admin/test/support/e2e_server.ex:11` calls migration, Repo, Oban and Fake startup. It creates/migrates the configured database (`:50`), shares its sandbox (`:70`) and defaults to port4017 (`:103`). `accrue_admin/config/test.exs:6` derives the database name from `MIX_TEST_PARTITION`; `accrue_admin/playwright.config.js:30` reuses a running server outside CI. `test/support/e2e_plug.ex:36` exposes fixture reset to the local test process.

**Failure scenario:** an owner opens the lab using the usual E2E server and a local browser suite reuses that process or the same database and resets its fixtures. A supposedly reproducible visual situation changes underneath the reviewer. Separately, an implementer could describe DB-free stories as a DB-free lab launch even though the selected transport still boots persistence.

**Required plan correction:** Phase252 should deliver a documented, repeatable local launch with explicit prerequisites, loopback binding, a disposable review database namespace and a distinct port/process identity; tests must not accidentally reuse/reset an interactive review session. Distinguish **DB-free scenario rendering** from current **DB-backed endpoint bootstrap** and measure startup separately from warm preview. Reuse existing code rather than adding a second platform. Do not claim isolation until a negative control proves a normal test reset cannot alter review data. A minimal DB-free bootstrap is a later optimization only if startup cost demonstrates the need.

**Reason to keep the recommendation:** existing code is the cheapest starting transport and already binds loopback. The flaw is an unstated operational contract, not a reason to replace the lab or expose Storybook in the canonical host.

### AR-02 · P2 · Prove workflow intake as well as in-job affected-scenario selection

**Proposal locations:** `MILESTONE-PROPOSAL.md:50`, `RECOMMENDATIONS.md:29`; supporting design research already warns about path coverage at `DESIGN-AND-VERIFICATION.md:26`.

Fail-closed selection inside a job cannot protect changes that never trigger that job. The dedicated `.github/workflows/accrue_admin_browser.yml:5`–`:16` currently lists `accrue/**`, `accrue_admin/**` and its own workflow path. It omits the root `storybook/` and proposed `dev_support/ui_scenarios/` roots, and brand assets that a selected visual owner may consume. The main `ci.yml` has other guardrails, so this is not a claim that all current CI is skipped; it is a concrete risk when extending/reusing the selected browser/visual owner.

**Required plan correction:** add first-slice acceptance that every consumed story, scenario, token, shared component, generated-manifest and runner path triggers its required owner. Test path/classifier intake with representative root-story-only, shared-scenario-only and token-only change sets, plus a deliberate unrelated-path negative control. If another unconditional required job owns a check instead, name that owner and prove its invocation rather than widening every workflow unnecessarily. Keep intake and in-job impact selection as separate checks.

**Reason to keep the recommendation:** extending existing CI owners remains the right choice; explicit intake contracts make that reuse honest without another full job.

## Strongest objection to each major recommendation

| Recommendation | Strongest objection | Disposition |
|---|---|---|
| Start with one subscription job | The owner's ambition is all sections and personas; a tiny pilot could become a permanent ceiling. | Still recommend. Phase253 explicitly includes a whole job/page, and the rolling roadmap accounts for the remaining Admin and Portal work. Publish uncovered jobs and select the next job on measured value, not enthusiasm for infrastructure. |
| Share production presentation with stories | A mechanical extraction can obscure state, change tracking or action authority while creating little reuse. | Still recommend selectively. Explicit attrs/slots and the real copy/link/eligibility owners matter more than a universal page schema. Stateful DataTable and routed lifecycle remain stateful/mounted. |
| Use a registry-derived variation manifest | Another metadata layer can repeat the current mistake: claims of composition without rendered UI. | Still recommend only with discovery reconciliation and a negative control where metadata markers cannot satisfy actual-render coverage. No handwritten parallel component catalogue. |
| Share scenario facts across transports | One fixture graph can couple all packages, duplicate module compilation and make unit tests slow. | Still recommend narrow adoption. Compile/load once outside package allowlists, use separate adapters, retain local unit factories and require persisted constraint conformance. |
| Use realistic adopter profiles | Fictional industries can become decorative sprawl or imply unimplemented finance/self-hosted capabilities. | Still recommend briefs as equivalence-class filters; implement launch/team facts first. Actor, billable and product profile remain distinct. Do not create multiple industry demos. |
| Mobile/light/dark quality checks | A few widths/themes can be marketed as universal responsive or accessibility proof. | Still recommend scoped claims. Add real container/breakpoint edges and targeted zoom/motion/focus checks; retain unverified observations and evidence limits. Design quality still needs current rendered review. |
| Fast affected-consumer PR checks | Bad dependency maps can select zero tests or miss downstream consumers; exhaustive fallback can exceed CI cost. | Still recommend with AR-02, stable sentinels, broad fallback on uncertainty and first-slice measurement. Budget targets are provisional and mutually consistent across the current synthesis/proposal. Never weaken existing suites to satisfy a time target. |
| Selected screenshot baselines | Stable screenshots can preserve sparse fake data, broken hierarchy or a bad interface indefinitely. | Still recommend as a regression tool. Separate representative rich data from intentional missing-evidence cases, use unmasked design captures, and review intent before accepting differences. Baseline stability is not taste. |
| Bounded agent design review | “Advisory” could make the owner's desired craft optional, or subjective findings could turn into endless scoring. | Still recommend a required bounded review artifact with explicit evidence/limits, and ordinary verification of confirmed fixes. Do not claim aesthetic certainty or create a paid critic, score ratchet, mandatory owner-UAT loop or arbitrary defect quota. |
| Keep the kitchen | Retaining two review renderers appears to contradict pruning and single-surface intent. | Still recommend preserving its independent proof role under the locked decision. Consolidate human discovery; remove duplicate UI implementations, not purposeful test transports. Retirement needs evidence parity and an explicit decision. |
| Prune stale stories aggressively | Removing “impossible” states can delete protection for historical upstream data and future boundary regressions. | Still recommend evidence-backed retirement. Preserve surviving negative tests, caller/API examples and supported historical states. No deletion based on grep absence or similar screenshots alone. |
| Defer the event timestamp fix outside UI scope | A UI-quality campaign could consume attention while a known correctness issue remains. | Keep scope separate, but retain its HIGH priority and independent next-action candidate. Fixed story clocks cannot close that defect; the proposal already states this explicitly. |

## Coverage of owner intent and locked boundaries

The proposal preserves the full composition ladder and real page/job destination; ordinary, empty, error, boundary and power-user situations; actor/job/product distinctions; fixture-domain realism; professional typography, restrained color, hierarchy, microcopy and natural navigation; mobile-first container-aware layout; and both themes. It also preserves provider honesty, host authorization, package exclusions, held-out cleanup safety, current token owners, retained-kitchen purpose and the parked evaluator boundary.

The methodology's plan-only boundary is correctly reconciled with the milestone workflow: durable research and a reviewable proposal now, canonical milestone activation only after summary confirmation. No additional strategic owner fork is needed for AR-01 or AR-02; both are reversible implementation/acceptance refinements within the requested scope.

No additional fan-out is justified. Incorporate these two corrections, keep the scope bounded to proposed Phases252–254, and present the concrete summary for owner confirmation. During formal planning, convert outcomes into executable requirements; this report does not substitute for their tests or claim that the current UI passes.

## Synthesis dispositions — 2026-10-26

The orchestrator incorporated both corrections into the final proposal and recommendations. Original finding locations above refer to the draft reviewed; subsequent edits shift line numbers. Findings remain preserved rather than being rewritten as if the risks had never been found.

- **AR-01 — incorporated into plan.** Phase 252, acceptance outcome 7 and the cost/launch section now require a disposable DB, distinct loopback port/process, refusal of accidental server reuse, separate reset authority and a negative control proving that normal test reset cannot alter interactive review data. They distinguish DB-free rendering from DB-backed bootstrap. Isolation has **not** been implemented or tested in this research session.
- **AR-02 — incorporated into plan.** Phase 252, acceptance outcome 12 and cost/CI intake explicitly cover every consumed story, scenario, shared component, registry, manifest, token and runner root, with positive/negative path controls and a named required owner. Workflow filters have **not** been changed or verified in this research session.

**Final proposal disposition:** ready for owner scope confirmation, with no unresolved research blocker. Implementation acceptance remains future work; no runtime/security/CI pass is inferred from these planning edits.
