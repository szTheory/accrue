# Phase 248: Reproducible Scenarios and Integrated Proof - Context

**Gathered:** 2026-10-11
**Status:** Ready for planning
**Mode:** Auto; the owner delegated recommendations and continuation. These are recommended choices under that authorization, not attributed individual answers.

<domain>
## Phase Boundary

Deliver DEMO-02 and PROOF-01: independently reproducible ordinary, empty, failure and boundary Admin evaluation states, and a complete finding-to-fix/disposition-to-executed-check trail at the tested revision. Preserve the current preview and completed Phase 245–247 product work. No product scenario picker, new room, billing feature, Portal change, dependency, broad redesign, remote tag or push.
</domain>

<decisions>
## Implementation Decisions

### Reproducible host states
- **D-01:** Use documented existing or minimal host-only commands to select ordinary, empty, failure and boundary states. Keep the ordinary Fake-host preview as the default; use separate isolated evaluation data/config for exceptional states. State selection must be explicit and inspectable, with no implicit destructive reset of the current preview or the protected Phase 243 host.
- **D-02:** Document exact state preconditions, launch/select command, expected route and visible result, cleanup and data custody for each state. Enforce `ACCRUE_HOST_SKIP_SEEDS=1` and the proper `ACCRUE_HOST` target at startup where applicable; never print credentials. Keep adversarial stress fixtures in their existing test owners and out of the ordinary preview.

### Integrated evidence
- **D-03:** Treat the canonical owner feedback and Phase 245 findings ledger as the complete finding universe. Give each accepted finding one stable row with shared/page-specific owner, Phase 246/247 fix or justified disposition, and executed owning checks. Preserve distinctions between a product fix, an evidence limitation and a deferred idea; never imply subjective owner acceptance.
- **D-04:** Bind rendered confirmation to the exact tested source revision and served CSS/JS assets. Record route/state, scenario identity, viewport, theme and image inspection; use representative combinations and explicit uncovered/unsupported states. Prior Phase 245–247 manifests are historical receipts unless they match the current tested revision.
- **D-05:** Reuse existing capture, manifest, Playwright, seed-contract and verification owners. Add only the smallest contract/check needed to make the integrated proof auditable. Run current owning checks and report commands/results; do not duplicate the suite or make a new CI workflow.

### Boundaries and handoff
- **D-06:** Keep scenario tooling outside production Admin and preserve existing owner scope, authorization, step-up, confirmation and action boundaries. Verification may inspect safe states but must not perform destructive preview reset or publish remotely.

### the agent's Discretion
Choose exact host-only command names, isolated dataset mechanism, representative capture selection, matrix format and test split from existing tooling. Prefer a small credible proof batch and make unavailable states explicit.
</decisions>

<canonical_refs>
## Canonical References

- `.planning/ROADMAP.md` — Phase 248 goal and three success criteria.
- `.planning/REQUIREMENTS.md` — DEMO-02 and PROOF-01; milestone exclusions.
- `.planning/notes/2026-10-11-admin-owner-feedback.md` — canonical owner findings and evidence contract.
- `.planning/phases/245-rendered-baseline-and-realistic-preview/245-CONTEXT.md` — preview custody and ordinary/held-out data boundary.
- `.planning/phases/245-rendered-baseline-and-realistic-preview/245-FINDINGS.md` — accepted owner-topic universe and original evidence limits.
- `.planning/phases/245-rendered-baseline-and-realistic-preview/245-VERIFICATION.md` — baseline proof boundaries.
- `.planning/phases/246-collection-controls-and-search/246-VERIFICATION.md` — shared control/search checks.
- `.planning/phases/247-evidence-true-details-and-analytics/247-VERIFICATION.md` — detail/analytics checks and 20-image historical proof.
- `.planning/phases/247-evidence-true-details-and-analytics/captures/phase247-current-proof/manifest.json` — prior revision-bound capture format.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/ci/seed_phase245_ordinary.sh` and ordinary seed contracts protect the realistic Fake-host story.
- `examples/accrue_host/e2e/phase247-current-proof.spec.js`, `scripts/ci/verify_phase247_render_proof.mjs` and prior manifests provide capture/asset provenance patterns.
- `scripts/ci/accrue_host_preview_custody.sh` and its tests own preview custody.

### Established Patterns
- Capture manifests list exact route/state/scenario, responsive/theme variant, source revision and served asset hashes; validators reject mismatches.
- Phase 245 findings and Phase 246/247 validation records retain actual owning checks and limitations.

### Integration Points
- Host Fake config and existing Playwright configuration select isolated evaluation targets; Phase 248 documentation/contract tests connect selection to observable Admin routes.
</code_context>

<specifics>
## Specific Ideas

The owner wants independent review of an ordinary billing story plus empty, failure and boundary examples, followed by a single traceable proof of all accepted feedback. The ordinary preview is `accrue-host-phase245-ordinary.localhost`; the protected Phase 243 preview must remain untouched. Separate held-out SQL stress fixtures belong in their sandbox, not the ordinary host.
</specifics>

<deferred>
## Deferred Ideas

Rich interactive scenario selection, a production Admin scenario picker, new billing/Portal features, new Admin rooms, a further broad visual pass, remote tags and publication are outside this phase. A second owner feedback pass is a later decision.
</deferred>
