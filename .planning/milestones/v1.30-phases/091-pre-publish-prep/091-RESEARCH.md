# Phase 91 — Pre-publish 1.0.0 prep — Research

**Question:** What must the planner/executor know to satisfy **REL-06**, **REL-07**, **DOC-03**, and **DOC-04** without bumping `@version` from `0.3.1`?

## Findings

### Project constraints

- Phase 91 is documentation/planning-only: both packages still declare `@version "0.3.1"`, and the roadmap explicitly says Phase 91 ends with those literals unchanged. [VERIFIED: accrue/mix.exs] [VERIFIED: accrue_admin/mix.exs] [VERIFIED: .planning/ROADMAP.md]
- Nyquist validation is enabled, so the phase needs a concrete verification artifact rather than prose-only sign-off. [VERIFIED: .planning/config.json]
- Repo workflow guidance requires the work to stay inside the planned phase rather than mixing in unrelated feature or release-bump edits. [VERIFIED: CLAUDE.md]

### 1. Current relevant text/state and exact drift

- Root `README.md` still says public releases are "`0.x` on Hex" and its `## Maintenance posture` section is explicitly "`pre-1.0`" and "`intake-gated`". Phase 91 must flip that posture to "`1.0.0` stable, post-1.0 cadence" while preserving the `PROC-08` / `FIN-03` non-goal warning. [VERIFIED: README.md]
- `accrue/README.md` still frames Maturity and maintenance as "`pre-1.0`", says the `mix.lock` guidance applies while Accrue is pre-1.0, and its `## Stability` section explains deprecation while public SemVer is still `0.x`. It also points readers at the `1.0.0` bootstrap appendix as future work. Phase 91 must rewrite that posture without changing the install snippet `{:accrue, "~> 0.3.1"}`. [VERIFIED: accrue/README.md] [VERIFIED: scripts/ci/verify_package_docs.sh]
- `RELEASING.md` is still organized around `## Pre-1.0 closure (maintainer intent)` and `## Routine pre-1.0 linked releases`, with `1.0.0` treated as an exceptional appendix. REL-07 requires a post-1.0 cadence section that supersedes this framing but leaves the bootstrap appendix available for the actual Phase 92 cut. [VERIFIED: RELEASING.md] [VERIFIED: .planning/REQUIREMENTS.md]
- `accrue/guides/maturity-and-maintenance.md` and `accrue/guides/upgrade.md` still contain pre-1.0 wording, so they are part of the same posture change and should be edited in the same pass as `RELEASING.md`. [VERIFIED: accrue/guides/maturity-and-maintenance.md] [VERIFIED: accrue/guides/upgrade.md]
- Neither package changelog currently carries any `1.0.0`-stable commitment. `accrue/CHANGELOG.md` has `## Unreleased` prose about checkout/billing docs; `accrue_admin/CHANGELOG.md` has an `## Unreleased` host-visible copy note. Phase 91 should preload the stable commitment in `## Unreleased` so Release Please can render it into `## [1.0.0]` during Phase 92, instead of hand-authoring a numbered release section on `main`. [VERIFIED: accrue/CHANGELOG.md] [VERIFIED: accrue_admin/CHANGELOG.md] [VERIFIED: .planning/milestones/v1.30-phases/091-pre-publish-prep/091-CONTEXT.md]
- `.planning/PROJECT.md` already says `1.0.0` does not reopen `PROC-08` or `FIN-03`, but the current non-goals section is generic rather than date-anchored. DOC-04 needs an explicit reaffirmation anchor under non-goals so verification can point to one falsifiable section. [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/milestones/v1.30-phases/091-pre-publish-prep/091-CONTEXT.md]

### 2. Verifier sensitivity and constraints

- `scripts/ci/verify_package_docs.sh` is the most sensitive Phase 91 gate. It checks root `README.md`, `accrue/README.md`, `RELEASING.md`, and exact install/version literals derived from `mix.exs`. Phase 91 can change narrative in those docs, but it must not change `{:accrue, "~> 0.3.1"}`, sibling package pins, or anything else that is supposed to keep matching the current `@version`. [VERIFIED: scripts/ci/verify_package_docs.sh] [VERIFIED: accrue/mix.exs] [VERIFIED: accrue_admin/mix.exs]
- `scripts/ci/verify_production_readiness_discoverability.sh` is mildly sensitive because it only enforces that the root/package READMEs still link `production-readiness.md` and that the guide keeps the stable `### 1.` through `### 10.` headings. Phase 91 can safely edit Maintenance/Stability prose if those links remain intact. [VERIFIED: scripts/ci/verify_production_readiness_discoverability.sh] [VERIFIED: README.md] [VERIFIED: accrue/README.md]
- `scripts/ci/verify_v1_17_friction_research_contract.sh` reads `.planning/PROJECT.md`, but only for canonical friction/north-star references, not for the non-goal wording Phase 91 will add. The DOC-04 edit is low-risk if it stays inside the existing non-goals area and leaves those references untouched. [VERIFIED: scripts/ci/verify_v1_17_friction_research_contract.sh] [VERIFIED: .planning/PROJECT.md]
- `scripts/ci/verify_adoption_proof_matrix.sh`, `scripts/ci/verify_verify01_readme_contract.sh`, and `scripts/ci/verify_core_admin_invoice_verify_ids.sh` are effectively unaffected because Phase 91 does not touch `examples/accrue_host` or the mounted-admin E2E docs/specs they pin. They still belong in the full `docs-contracts-shift-left` proof because CI treats that six-script bundle as normative. [VERIFIED: scripts/ci/verify_adoption_proof_matrix.sh] [VERIFIED: scripts/ci/verify_verify01_readme_contract.sh] [VERIFIED: scripts/ci/verify_core_admin_invoice_verify_ids.sh] [VERIFIED: .github/workflows/ci.yml]
- `host-integration` and `release-manifest-ssot` are unaffected by the planned prose changes, but the verification artifact should still cite them as unchanged merge-blocking context: `host-integration` depends on `docs-contracts-shift-left`, and `release-manifest-ssot` protects against accidental version drift. [VERIFIED: .github/workflows/ci.yml]

### 3. Cleanest decomposition into executable plans/waves

- **Plan 1 / Wave 1:** maintainer cadence + changelog preload. Edit `RELEASING.md`, `accrue/guides/maturity-and-maintenance.md`, `accrue/guides/upgrade.md`, `accrue/CHANGELOG.md`, and `accrue_admin/CHANGELOG.md` together so REL-06 and REL-07 land as one coherent posture change and any anchor renames stay in sync. [VERIFIED: RELEASING.md] [VERIFIED: accrue/guides/maturity-and-maintenance.md] [VERIFIED: accrue/guides/upgrade.md] [VERIFIED: accrue/CHANGELOG.md] [VERIFIED: accrue_admin/CHANGELOG.md] [VERIFIED: .planning/milestones/v1.30-phases/091-pre-publish-prep/091-CONTEXT.md]
- **Plan 2 / Wave 1:** public front-door posture flip. Edit root `README.md` and `accrue/README.md` after Plan 1 wording is settled, because both pages should point at the new cadence language and must preserve version-pinned install literals for Phase 92. [VERIFIED: README.md] [VERIFIED: accrue/README.md] [VERIFIED: scripts/ci/verify_package_docs.sh]
- **Plan 3 / Wave 2:** planning non-goal reaffirmation + validation/verification artifacts. Add the dated DOC-04 subsection to `.planning/PROJECT.md`, create `091-VALIDATION.md`, then author `091-VERIFICATION.md` with preconditions, requirement-to-evidence mapping, and verifier transcripts anchored to a reviewed `0.3.1` SHA. Run or cite the full six-script `docs-contracts-shift-left` bundle after the doc edits and require explicit reviewed-SHA `host-integration` evidence alongside it. [VERIFIED: .planning/PROJECT.md] [VERIFIED: .github/workflows/ci.yml] [VERIFIED: .planning/milestones/v1.28-phases/086-post-publish-contract-alignment/086-VERIFICATION.md] [VERIFIED: .planning/milestones/v1.27-phases/84-pre-1-0-closure-narrative/084-VERIFICATION.md] [VERIFIED: .planning/milestones/v1.27-phases/85-friction-inventory-post-closure/085-VERIFICATION.md]

### 4. Blockers / non-blockers

- No repo blocker is visible. The phase is prose/planning-only, the current version is unambiguously `0.3.1`, and all required target files and verifier scripts exist in-tree. [VERIFIED: accrue/mix.exs] [VERIFIED: accrue_admin/mix.exs] [VERIFIED: scripts/ci/verify_package_docs.sh] [VERIFIED: .planning/milestones/v1.30-phases/091-pre-publish-prep/091-CONTEXT.md]
- The main execution risk is accidental Phase 92 leakage: any edit that changes install pins, adoption-matrix needles, host README version text, manifest/version files, or package `@version` literals would prematurely consume `PPX-09..12` or `REL-05` work. Keep those out of Phase 91. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: scripts/ci/verify_package_docs.sh] [VERIFIED: scripts/ci/verify_adoption_proof_matrix.sh] [VERIFIED: .release-please-manifest.json]

## Validation Architecture

- `091-VALIDATION.md` must exist before execution so Nyquist validation is explicit rather than implied. It should define the requirement-to-evidence map, the mandatory grep checks, and the reviewed-SHA CI evidence contract for this docs-only phase. [VERIFIED: .planning/config.json]
- `091-VERIFICATION.md` should use the lean Phase 86 spine: `Preconditions`, `Evidence checklist`, `Sign-off`, plus a short `Verifier transcripts` annex only if local command output is included instead of a CI link. [VERIFIED: .planning/milestones/v1.28-phases/086-post-publish-contract-alignment/086-VERIFICATION.md]
- Preconditions should prove Phase 91 stayed pre-publish: reviewed commit SHA recorded, `accrue/mix.exs` `@version "0.3.1"` recorded, `accrue_admin/mix.exs` `@version "0.3.1"` recorded, and an explicit note that Phase 91 does not bump package version or manifest state. [VERIFIED: accrue/mix.exs] [VERIFIED: accrue_admin/mix.exs] [VERIFIED: .planning/ROADMAP.md]
- `REL-06` evidence should be a diff or grep over `accrue/CHANGELOG.md` and `accrue_admin/CHANGELOG.md` proving the new stable commitment lives under `## Unreleased`, ready for Release Please to render later. [VERIFIED: accrue/CHANGELOG.md] [VERIFIED: accrue_admin/CHANGELOG.md]
- `REL-07` evidence should be a diff or grep over `RELEASING.md`, `accrue/guides/upgrade.md`, and `accrue/guides/maturity-and-maintenance.md` proving the post-1.0 cadence story and anchor rename landed together. [VERIFIED: RELEASING.md] [VERIFIED: accrue/guides/upgrade.md] [VERIFIED: accrue/guides/maturity-and-maintenance.md]
- `DOC-03` evidence should be a diff or grep over root `README.md` and `accrue/README.md` proving the posture flip landed while the root README preserved the explicit `PROC-08` / `FIN-03` warning, the wording still frames those as later-milestone-only work, and the current `0.3.1` install literal remained intact. [VERIFIED: README.md] [VERIFIED: accrue/README.md] [VERIFIED: scripts/ci/verify_package_docs.sh]
- `DOC-04` evidence should be a grep over `.planning/PROJECT.md` proving the dated reaffirmation subsection exists under non-goals and still frames `PROC-08` / `FIN-03` as explicit later-milestone-only work. [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/milestones/v1.30-phases/091-pre-publish-prep/091-CONTEXT.md]
- Regression proof should include the exact six-script `docs-contracts-shift-left` bundle from CI, because that bundle membership is the normative merge-blocking contract for Phase 91's touched docs. [VERIFIED: .github/workflows/ci.yml]

```bash
bash scripts/ci/verify_package_docs.sh
bash scripts/ci/verify_v1_17_friction_research_contract.sh
bash scripts/ci/verify_verify01_readme_contract.sh
bash scripts/ci/verify_production_readiness_discoverability.sh
bash scripts/ci/verify_adoption_proof_matrix.sh
bash scripts/ci/verify_core_admin_invoice_verify_ids.sh
```

- `091-VERIFICATION.md` should cite one branch-wide evidence anchor: a green `docs-contracts-shift-left` job on the reviewed SHA plus explicit reviewed-SHA evidence that `host-integration` remained green at `@version "0.3.1"`. Because the phase is docs-only, a CI run link is acceptable for `host-integration`; local transcripts are secondary. [VERIFIED: .github/workflows/ci.yml] [VERIFIED: .planning/milestones/v1.27-phases/85-friction-inventory-post-closure/085-VERIFICATION.md] [VERIFIED: .planning/milestones/v1.28-phases/086-post-publish-contract-alignment/086-VERIFICATION.md]

## RESEARCH COMPLETE
