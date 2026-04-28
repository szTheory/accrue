# Phase 92: Linked 1.0.0 publish + post-publish contract sweep - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-28
**Phase:** 092-linked-1-0-0-publish-post-publish-contract-sweep
**Areas discussed:** Release choreography, Proof surface breadth at 1.0.0, Verification and failure posture
**Mode:** advisor-style deep synthesis — user requested research-backed one-shot recommendations with coherent defaults, broad ecosystem comparison, and low-impact choices shifted left. Existing config already favored `discuss_auto_all_gray_areas`, `discuss_auto_resolve_low_impact`, and `discuss_high_impact_confirm`, so all three areas were researched in parallel and then locked without surfacing additional forks.

---

## Release choreography

| Option | Description | Selected |
|--------|-------------|----------|
| One combined release PR, then same-day post-merge verification | Release Please PR carries both package version bumps, manifest bump, package-doc pins, host/adoption proof updates, and verifier changes before merge; verification ledger follows after publish. | ✓ |
| Split PRs: release first, same-day docs/proof follow-up | Version/release slice merges first, with public-proof cleanup in a second PR. | |
| Manual trigger-heavy / publish-first recovery path | Maintainer relies on manual workflow dispatch or publish-first operations, then documents/fixes state afterward. | |

**Selected:** One combined release PR, then same-day post-merge verification.

**Notes:** This matches the repo’s current Release Please + linked-version monorepo model, keeps `main`, Hex, and canonical proof surfaces aligned, and best fits least-surprise DX. Split or manual flows were retained only as fallback/recovery paths for automation failure or irreducible Release Please edge cases.

---

## Proof surface breadth at `1.0.0`

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal literal-only refresh | Update package pins and version literals only. | |
| Explicit contract-surface refresh | Update package pins plus explicit `1.0.0` proof language in First Hour, host README, and adoption matrix, with matching verifier needles. | ✓ |
| Broad narrative sweep across adjacent docs | Use the release to broadly rewrite adjacent post-1.0 docs and surrounding narrative surfaces. | |

**Selected:** Explicit contract-surface refresh.

**Notes:** This is the right middle path. It satisfies `PPX-09..12`, makes `1.0.0` visible where evaluators actually look, and preserves doc/script coupling without turning the phase into a repo-wide editorial pass. The minimal path was rejected as too weak for `PPX-12`; the broad sweep was rejected as Phase 93 / later-docs scope creep.

---

## Verification and failure posture

| Option | Description | Selected |
|--------|-------------|----------|
| Lean post-publish evidence only | Capture a minimal URL-first post-publish ledger, with little additional pre-merge discipline. | |
| URL-first same-day verification plus `release-manifest-ssot` + six-script docs bundle + host proof | Require manifest lockstep, full docs bundle, and host proof on the reviewed slice before merge; then capture Hex/tag/workflow evidence after merge. | ✓ |
| Heavy recovery/rollback-centric posture | Expand the release into a larger recovery/rollback process with stronger operational incident handling by default. | |

**Selected:** URL-first same-day verification plus `release-manifest-ssot` + six-script docs bundle + host proof.

**Notes:** This preserves the repo’s existing verification style while raising the bar appropriately for a `1.0.0` cut that changes both version sources and public proof surfaces. Heavy rollback posture was rejected because it adds process without improving the likely path; the minimal proof path was rejected because it is too easy to miss manifest/doc drift or partial-pair release errors.

---

## the agent's Discretion

- Exact wording for the explicit `1.0.0` proof needles in host/adoption surfaces, provided the language remains concrete and verifier-friendly.
- Exact organization of `092-VERIFICATION.md`, provided it remains URL-first, grep-friendly, and preserves the reviewed-SHA evidence chain.
- Minor wording and checklist ordering within the Phase 92 plans, so long as the locked execution posture is preserved.

## Deferred Ideas

- Broader post-1.0 editorial cleanup beyond the canonical proof surfaces.
- Heavier fallback/recovery runbook expansion if release automation becomes unreliable in future milestones.

## Research subagents spawned

Three parallel `gsd-advisor-researcher` agents were used on 2026-04-28:

1. **Release choreography** — compared one combined release PR, split PRs, and manual trigger-heavy paths; recommended the combined PR as the coherent default.
2. **Proof surface breadth** — compared literal-only updates, explicit contract-surface refresh, and broad narrative sweeps; recommended the contract-surface middle path.
3. **Verification and failure posture** — compared lean post-publish proof, the current repo’s URL-first same-day evidence plus CI gates, and heavier rollback-centric process; recommended the current repo pattern with stronger pre-merge truth.
