# Requirements: Accrue v1.62 Release Integration & Repository Hygiene

**Defined:** 2026-09-12
**Core Value:** A Phoenix developer can install Accrue and its companion admin UI and launch a production-grade SaaS billing system without avoidable integration or release risk.

## v1.62 Requirements

### Repository Truth

- [x] **REPO-01**: Maintainers can inspect one committed, reproducible inventory of local and remote `main`, the v1.61 lineage and tag, release branches, worktrees, open PRs, untracked paths, ship windows, and relevant planning state.
- [x] **REPO-02**: Maintainers can recover every pre-existing divergent local ref and user-owned untracked artifact after synchronization work; no cleanup relies on force-push, tag movement, or unrecorded deletion.
- [x] **REPO-03**: Maintainers have one supported, observable command path for listing, inspecting, and monitoring GitHub Actions runs, with failure output that remains attributable to an exact repository SHA.

### History Integration

- [x] **INTG-01**: Maintainers can produce a reviewable integration candidate containing remote-`main` changes, all intended v1.61 work, and the four post-archive audit-closure commits without rewriting published history or moving the v1.61 tag.
- [x] **INTG-02**: Every integration conflict or intentionally excluded commit has an evidence-backed disposition, and retained runtime, documentation, release, and CI behavior remains covered by focused regression checks.
- [x] **INTG-03**: Maintainers can verify the candidate's ancestry, changed-file scope, milestone provenance, and rollback point before any pull request targets `main`.

### Release Proof

- [x] **GATE-01**: A fresh clean checkout of the exact integration candidate produces honest, re-verifiable, per-lane proof of the repository's complete local CI-equivalent gates — recorded argv and exit-code evidence at the exact candidate SHA under the closed `proved`/`failed`/`skipped`/`advisory`/`non_run` lexicon, with no aggregate green/passing boolean and no fabricated `proved` state — without depending on ignored caches, credentials, or another worktree.
- [x] **GATE-02**: Required GitHub Actions checks for the exact candidate SHA produce honest per-lane status with recorded evidence, and provider lanes retain explicit `proved`, `failed`, `skipped`, `advisory`, or `non_run` semantics rather than being relabeled as success; a green Actions conclusion alone is not accepted as provider proof.
- [x] **GATE-03**: Every open ship window has been fixed or explicitly waived with current evidence, owner, rationale, and release impact; no unexplained open window remains at the release handoff.

### Bounded Hygiene

- [x] **HYG-01**: Every untracked file, stale worktree, debug session, and remote maintenance or release branch is classified as retained, committed, archived, superseded, or authorized for removal before cleanup occurs.
- [ ] **HYG-02**: GSD health, planning mirrors, generated artifacts, package metadata, changelogs, and release documentation agree with the integration candidate and contain no release-blocking drift.
- [x] **HYG-03**: Cleanup changes are limited to objective test, lint, compiler, security, documentation-truth, dead-code, duplication, or comprehension findings in the release path, and stop when another pass yields only subjective nits.

### Release Handoff

- [ ] **REL-04**: Maintainers can review an integration pull request with a concise risk summary, exact verification evidence, preserved rollback instructions, and no unrelated feature scope.
- [x] **REL-05**: Release Please produces or is ready to produce a version-and-changelog-consistent release pull request after integration, without this milestone merging that PR or publishing packages.

## Future Requirements

### Publication

- **REL-06**: Maintainers publish the linked `accrue`, `accrue_admin`, and `accrue_portal` packages and verify their public artifacts after explicit release authorization.

### Product Expansion

- Backlogged ecosystem, Admin UI, StoreKit/Crosswake, and Google Play work remains governed by its planted-seed trigger and a separate milestone.

## Out of Scope

| Feature | Reason |
|---------|--------|
| New billing, entitlement, admin, portal, or mobile capability | This is release integration and maintenance, not product expansion. |
| Force-pushing shared branches or moving/recreating the published v1.61 tag | Published history and closeout evidence must remain immutable. |
| Repository-wide formatting, renaming, stylistic rewriting, or speculative abstraction | These create review churn without demonstrated release or maintenance value. |
| Deleting user-owned untracked files or remote branches without classification and explicit authorization | Cleanup must remain recoverable and auditable. |
| Weakening required checks, reducing matrix coverage, hiding artifacts, or promoting skipped/advisory provider lanes | v1.61's evidence contract remains binding. |
| Automatically resolving all 28 archived UAT items | Old debt is reconsidered only when it represents a current release risk. |
| Merging into `main`, merging a Release Please PR, creating a GitHub release, or publishing Hex packages | These are external release actions requiring an explicit final authorization gate. |

## Traceability

Roadmap phase ownership is populated during roadmap creation. Every v1.62 requirement must map to exactly one phase.

| Requirement | Phase | Status |
|-------------|-------|--------|
| REPO-01 | Phase 229 | Complete |
| REPO-02 | Phase 229 | Complete |
| REPO-03 | Phase 229 | Complete |
| INTG-01 | Phase 230 | Complete |
| INTG-02 | Phase 230 | Complete |
| INTG-03 | Phase 230 | Complete |
| GATE-01 | Phase 231 | Complete |
| GATE-02 | Phase 231 | Complete |
| GATE-03 | Phase 231 | Complete |
| HYG-01 | Phase 232 | Complete |
| HYG-02 | Phase 232 | Pending |
| HYG-03 | Phase 232 | Complete |
| REL-04 | Phase 232 | Pending |
| REL-05 | Phase 232 | Complete |

**Coverage:**

- v1.62 requirements: 14 total
- Mapped to phases: 14
- Unmapped: 0

---
*Requirements defined: 2026-09-12*
*Last updated: 2026-09-12 when v1.62 roadmap was created*
