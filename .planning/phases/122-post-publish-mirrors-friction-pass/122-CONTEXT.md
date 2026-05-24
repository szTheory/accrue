# Phase 122: Post-publish mirrors + friction pass - Context

**Gathered:** 2026-05-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Close `v1.38` after the successful public `1.1.1` linked trio release by aligning live `.planning/` mirrors to one truthful maintainer story, recording the required dated `INV-08` friction certification, and removing stale active-state cues that would mislead the next maintainer. This phase is a closeout/hygiene slice, not another release-recovery phase and not a new feature phase.

</domain>

<decisions>
## Implementation Decisions

### Planning mirror wording
- **D-01:** Use one shared public release-line sentence across active planning mirrors, but only when it explicitly names the package set and only when the statement is true on Hex/tags/workflow proof.
- **D-02:** The canonical wording model is: `Current public linked release line: accrue / accrue_admin / accrue_portal 1.1.1 (published 2026-05-08).`
- **D-03:** Do not restate all three package versions throughout planning prose unless a partial/superseded release forces per-package exception handling. Package-level precision stays in package docs, tags, GitHub releases, Hex, and `121-VERIFICATION.md`.

### Milestone closeout posture
- **D-04:** Keep the milestone in an explicit short post-publish closeout state until Phase 122 lands, then flip `v1.38` to shipped/archive posture. Do not archive immediately after Phase 121.
- **D-05:** Distinguish two truths clearly in live planning docs:
  - public release truth: the `1.1.1` trio shipped on 2026-05-08
  - milestone truth: `v1.38` closeout remained active until mirrors and `INV-08` were recorded
- **D-06:** After Phase 122 is complete, live planning mirrors should no longer imply “ready to begin Phase 121,” “next unused phase is 120,” or any other pre-closeout active-state residue.

### Friction certification posture
- **D-07:** Default `INV-08` to dated certification path `(b)` unless the `1.1.0` failure and `1.1.1` recovery exposed a genuinely new sourced integrator/adoption problem that escaped the release-proof lane.
- **D-08:** Treat maintainer-process roughness as inventory-worthy only if at least one of these becomes true:
  - it left a new user-facing falsehood in docs/Hex/install guidance after recovery
  - it revealed a new non-diagnostic verifier gap that now weakens trust in the published contract
  - it recurs enough to support a real downstream trust story rather than a one-off recovery event
- **D-09:** For the current evidence set, the failed `1.1.0` portal publish and superseding `1.1.1` recovery stay in `121-VERIFICATION.md` and inform future release-gate hardening, but do not create a new friction row by default.

### Cleanup scope
- **D-10:** Use bounded strict cleanup: fix every stale live active-phase marker and contradictory current-public-version/package-scope callout that affects present-tense maintainer reading.
- **D-11:** Strict cleanup is bounded to active maintainer-facing artifacts, especially `.planning/PROJECT.md`, `.planning/MILESTONES.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, and any live phase directories or closeout pointers that still imply pre-`1.1.1` truth.
- **D-12:** Do not rewrite archived milestone artifacts, `_stale-phase-overflow`, or historical verification trees unless this phase uncovers a concrete archive-integrity bug. History should remain historically accurate even when the live mirrors change.

### Decision philosophy for this phase family
- **D-13:** Favor deep synthesis and cohesive defaults over repeated user arbitration for low-impact release-hygiene choices.
- **D-14:** Escalate only forks that materially change public release truth, milestone auditability, or long-term maintainer trust. Otherwise choose the least-surprising default and document it.

### the agent's Discretion
- Exact wording for active-vs-shipped posture in `PROJECT.md`, `MILESTONES.md`, `ROADMAP.md`, and `STATE.md`, as long as the distinction in **D-05** remains explicit.
- Exact `INV-08` dated subsection prose, provided it follows the existing inventory pattern and stays evidence-bound.
- Exact list of stale active-state cues to remove, provided cleanup remains inside the bounded strict scope from **D-10** through **D-12**.

</decisions>

<specifics>
## Specific Ideas

- User preference for this decision family: research broadly, synthesize one coherent recommendation set, auto-resolve low-impact choices, and raise only the truly high-impact forks.
- Release-truth wording should optimize for maintainer clarity first: one current line, one active status story, one closeout path.
- The repo should preserve the distinction between “public packages shipped” and “planning milestone fully closed,” but that distinction must be brief and explicit rather than leaving the project in a fuzzy limbo state.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Active release-truth source
- `.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md` — canonical public release proof for the shipped `1.1.1` trio, including failed `1.1.0` history, recovery, mirror notes, and post-publish reruns
- `RELEASING.md` — current linked-release contract and maintainer release vocabulary

### Active milestone scope
- `.planning/ROADMAP.md` — `v1.38` Phase 122 goal and success criteria
- `.planning/REQUIREMENTS.md` — `HYG-03` and `INV-08`
- `.planning/STATE.md` — current live milestone cursor that needs closeout normalization
- `.planning/PROJECT.md` — current project narrative with active milestone and stale release-truth callouts that must be reconciled
- `.planning/MILESTONES.md` — shipped milestone ledger that must be extended to include the `v1.38` closeout cleanly

### Prior closeout precedents
- `.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-VERIFICATION.md` — closeout pattern separating publish proof from final mirror/inventory closure
- `.planning/milestones/v1.28-phases/087-friction-inventory-post-publish/087-CONTEXT.md` — inventory-path defaults, verifier bundle rule, and revisit-trigger discipline
- `.planning/research/v1.17-FRICTION-INVENTORY.md` — friction SSOT and dated maintainer-pass format
- `.planning/research/v1.17-north-star.md` — stop rules and anti-bloat discipline for friction/inventory work

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `121-VERIFICATION.md`: already contains the exact shipped identifiers (`PR_NUMBER: 23`, `TARGET_VERSION: 1.1.1`, `RUN_ID: 25554198977`) and the dated narrative needed to anchor all mirror updates.
- Existing inventory maintainer-pass subsections in `v1.17-FRICTION-INVENTORY.md`: reusable pattern for `INV-08` path `(b)`.
- `093-VERIFICATION.md`: reusable pattern for post-publish mirror alignment plus explicit milestone-close proof.

### Established Patterns
- Accrue treats publish proof and milestone closeout as separate but linked artifacts.
- Active planning mirrors are allowed to evolve; archived milestone artifacts are not rewritten casually.
- Release truth is proven from Hex/tags/workflow evidence rather than branch-local `@version` alone.

### Integration Points
- `.planning/PROJECT.md`, `.planning/MILESTONES.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` must converge on one active maintainer story after Phase 122.
- `v1.17-FRICTION-INVENTORY.md` must receive the dated `INV-08` closeout subsection or a sourced new row if the evidence unexpectedly demands one.
- The phase directory itself should become the canonical home for the closeout context and any resulting planning artifacts for Phase 122.

</code_context>

<deferred>
## Deferred Ideas

- Converting the recovered `1.1.0` publish failure into a new friction row without stronger downstream evidence — defer unless future releases show recurrence or a real trust/adoption symptom.
- Broad cleanup of archived milestone trees or `_stale-phase-overflow` — out of scope unless an archive-integrity bug is discovered.
- Additional general-purpose GSD preference plumbing beyond the already-aligned discuss config — unnecessary for this phase unless a future workflow shows the current defaults are insufficient.

</deferred>

---

*Phase: 122-post-publish-mirrors-friction-pass*
*Context gathered: 2026-05-08*
