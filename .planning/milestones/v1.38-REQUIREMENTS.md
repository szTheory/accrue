# Requirements: Accrue — Milestone v1.38

**Defined:** 2026-05-07  
**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

## v1.38 — Linked release truth

**Goal:** Ship the next coherent public Accrue release and make the developer-facing release story true end-to-end: the linked package set, publish order, tags, changelogs, install docs, verifier lanes, and `.planning/` mirrors all need to agree with the actual published line. **No** new billing surface, lifecycle expansion, or strategy reopening in this milestone.

### Release contract and publish path (REL)

- [ ] **REL-09**: A maintainer can follow `RELEASING.md`, `release-please-config.json`, `.release-please-manifest.json`, and `.github/workflows/release-please.yml` without ambiguity about which packages participate in the linked release, what order they publish in, and what proof is required before and after publish.

- [ ] **REL-10**: The next public release lands with package `@version`, git tags, GitHub releases, and package changelog sections all matching the shipped registry versions for every package intentionally included in the linked release.

- [ ] **REL-11**: The publish proof chain records the ordered release outcome for the linked package set, including any required dependency ordering between `accrue` and its UI packages, so maintainers can prove the public line from tags and workflow evidence instead of branch assumptions.

### Post-publish contract sweep (PPX)

- [ ] **PPX-13**: `bash scripts/ci/verify_package_docs.sh` passes after the release, and all enforced install/version literals across package READMEs and First Hour reflect the actual published package line rather than stale pre-publish or branch-only values.

- [ ] **PPX-14**: `bash scripts/ci/verify_adoption_proof_matrix.sh` and the merge-blocking `docs-contracts-shift-left` bundle pass against the post-release docs state, with any touched host or package mirrors kept needle-aligned in the same release truth chain.

- [ ] **PPX-15**: The release narrative explicitly resolves the current package-set reality: if `accrue_portal` is in the linked-version automation, the docs and maintainer runbook must either include it honestly in the release contract or narrow the automation so the published story stays truthful.

### Planning hygiene and maintainer continuity

- [x] **HYG-03**: `.planning/PROJECT.md`, `.planning/MILESTONES.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` reflect the actual public release line and the chosen linked package scope after publish, with no stale “current public version” or package-set contradictions.

- [x] **INV-08**: After the release and mirror pass, the maintainer performs the required dated post-publish friction certification or adds new sourced friction rows if the release exposed fresh integrator-facing problems.

## Future requirements (deferred)

- Additional subscription lifecycle expansion beyond the shipped `v1.37` surface.
- New provider breadth, Hyperwallet reopening, or broader processor strategy changes.
- `FIN-03` app-owned finance exports.
- Any new billing, admin, or portal feature work that is not needed to make the public release line truthful.

## Out of scope

| Item | Reason |
|------|--------|
| New billing facade APIs or lifecycle capabilities | `v1.38` is release continuity and public truth, not feature expansion. |
| Broad doc rewrites without a release or verifier forcing function | Keep the milestone evidence-bound to publish continuity. |
| Reopening processor strategy boundaries | The active dual-provider strategy stays as-is; this milestone ships what already exists. |
| `FIN-03` finance exports | Explicit non-goal. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| REL-09 | Phase 120 | Planned |
| PPX-15 | Phase 120 | Planned |
| REL-10 | Phase 121 | Planned |
| REL-11 | Phase 121 | Planned |
| PPX-13 | Phase 121 | Planned |
| PPX-14 | Phase 121 | Planned |
| HYG-03 | Phase 122 | Complete |
| INV-08 | Phase 122 | Complete |

**Coverage:** v1.38 requirements **8** total · Mapped **8** · Unmapped **0** ✓

---
*Requirements defined: 2026-05-07 — `gsd-new-milestone` v1.38; domain research skipped because this is a release-operational milestone.*
