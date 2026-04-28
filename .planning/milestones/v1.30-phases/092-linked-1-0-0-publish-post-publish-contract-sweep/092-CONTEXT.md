# Phase 92: Linked 1.0.0 publish + post-publish contract sweep - Context

**Gathered:** 2026-04-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Cut the linked `1.0.0` release for `accrue` and `accrue_admin`, then prove that every public release contract is honest at `1.0.0`: package versions, Release Please manifest, package install literals, host-facing proof surfaces, and same-day post-publish evidence. This phase closes **REL-05** and **PPX-09..12** only after the release pair exists and the verification ledger proves it.

**Out of scope:** `.planning/PROJECT.md`, `.planning/MILESTONES.md`, and `.planning/STATE.md` mirror updates; the dated post-1.0 friction-inventory maintainer pass; planning tag work; any new billing/admin/product capability; reconsidering **PROC-08** or **FIN-03**.

</domain>

<decisions>
## Implementation Decisions

### Cross-cutting execution posture

- **D-01:** Treat Phase 92 as one coherent release-truth slice, not a version bump followed by cleanup. `mix.exs`, `.release-please-manifest.json`, package-doc install literals, host README / adoption-matrix proof needles, verifier updates, and the eventual verification ledger must all describe one `1.0.0` reality.
- **D-02:** Apply the user's standing preference for discuss-phase decisions here: default to research-backed, cohesive recommendations; auto-resolve low-impact choices; only surface forks that materially change release safety, public trust, or phase boundaries. No such fork remained after research, so the cohesive default package is locked as-is.

### Release choreography

- **D-03:** Use **one combined Release Please PR** for the `1.0.0` cut. That PR should already contain both package `@version` bumps, `.release-please-manifest.json`, the package-doc pin refresh, the explicit host/adoption `1.0.0` proof needles, and any matching verifier updates.
- **D-04:** Do **not** split the release into a version PR plus a same-day docs/proof follow-up PR unless Release Please or GitHub automation makes the combined path mechanically impossible. Split PRs are fallback-only because they create a temporary mismatch window between `main`, Hex, and the canonical proof surfaces.
- **D-05:** Do **not** plan around a manual publish-first path. Manual dispatch, publish-first recovery, or other operator-heavy paths remain disaster-recovery options only, not the intended Phase 92 architecture.

### Proof surface breadth at `1.0.0`

- **D-06:** Go beyond literal package-pin updates. Phase 92 must make `1.0.0` explicit on the canonical integrator-facing proof surfaces: `examples/accrue_host/README.md` and `examples/accrue_host/docs/adoption-proof-matrix.md`, with matching verifier updates in the same PR when new required needles are introduced.
- **D-07:** Keep the proof-surface refresh **tight and contract-first**. Update only the authoritative release surfaces that users actually rely on during install/proof: `accrue/README.md`, `accrue_admin/README.md`, `accrue/guides/first_hour.md`, `examples/accrue_host/README.md`, and `examples/accrue_host/docs/adoption-proof-matrix.md`. Do not turn Phase 92 into a broad repo-wide post-1.0 editorial sweep.
- **D-08:** Keep the existing `> **Hex vs \`main\`:**` framing and the current First Hour / host README structure intact. The goal is explicit `1.0.0` proof language with minimal surprise, not a narrative rewrite.

### Verification and failure posture

- **D-09:** Use a **URL-first same-day verification ledger** in `092-VERIFICATION.md`, following the established lean proof style from earlier release/post-publish phases, but require stronger pre-merge truth on this cut because `1.0.0` changes both version sources and public proof surfaces.
- **D-10:** Before merge, require green evidence for `release-manifest-ssot`, the full six-script `docs-contracts-shift-left` bundle as defined by `.github/workflows/ci.yml`, and the host proof wrapper if host README wording changes. Treat `.github/workflows/ci.yml` as the normative membership source, not a hand-picked subset.
- **D-11:** After merge/publish, `092-VERIFICATION.md` must record: reviewed merge SHA, explicit `Release-As: 1.0.0` proof, release workflow run id, green reviewed-SHA verifier evidence, Hex package URLs for both `1.0.0` releases, GitHub release/tag URLs for both packages, and UTC ordering proof that `accrue` published before `accrue_admin`.
- **D-12:** Do not over-rotate into a heavy rollback playbook for this phase. The right safety posture is to prevent drift before merge and prove ordered publish after merge; Hex rollback constraints mean retire/forward-fix is the realistic recovery model if automation fails.

### the agent's Discretion

- Exact wording for the new explicit `1.0.0` host/adoption proof needles, as long as the language is concrete, verifier-friendly, and does not broaden scope into general post-1.0 marketing prose.
- Exact structure of `092-VERIFICATION.md` sections, provided it remains grep-friendly and preserves the required URL-first evidence chain.
- Whether fallback/recovery paths are documented as a short note in `092-VERIFICATION.md` or only implied by `RELEASING.md`, as long as the mainline execution path remains the combined Release Please PR.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/ROADMAP.md` — Phase 92 scope, plans, success criteria, and explicit Phase 93 boundary
- `.planning/REQUIREMENTS.md` — `REL-05`, `PPX-09`, `PPX-10`, `PPX-11`, `PPX-12`
- `.planning/PROJECT.md` — current milestone intent, non-goals, and `1.0.0` declaration framing
- `.planning/STATE.md` — current execution position (`Phase 91 complete — Phase 92 planning next`)

### Prior phase context and precedent

- `.planning/milestones/v1.30-phases/091-pre-publish-prep/091-CONTEXT.md` — locked pre-publish prose posture, changelog/release-cadence decisions, and Phase 92 handoff constraints
- `.planning/milestones/v1.30-phases/091-pre-publish-prep/091-DISCUSSION-LOG.md` — rationale for the pre-publish 1.0.0 narrative layer
- `.planning/milestones/v1.28-phases/086-post-publish-contract-alignment/086-CONTEXT.md` — post-publish contract alignment precedent and same-PR honesty discipline
- `.planning/milestones/v1.28-phases/086-post-publish-contract-alignment/086-DISCUSSION-LOG.md` — discussion precedent for post-publish proof coupling and verifier breadth
- `.planning/milestones/v1.28-phases/086-post-publish-contract-alignment/086-VERIFICATION.md` — lean verification spine with transcript annex when warranted
- `.planning/milestones/v1.19-phases/68-release-train/68-VERIFICATION.md` — release-train URL-first evidence precedent

### Phase 92 research and draft planning artifacts

- `.planning/milestones/v1.30-phases/092-linked-1-0-0-publish-post-publish-contract-sweep/092-RESEARCH.md` — repo-specific research on Release Please, Hex ordering, and exact `1.0.0` touch surfaces
- `.planning/milestones/v1.30-phases/092-linked-1-0-0-publish-post-publish-contract-sweep/092-PATTERNS.md` — current file-level analogs and structural constraints
- `.planning/milestones/v1.30-phases/092-linked-1-0-0-publish-post-publish-contract-sweep/092-VALIDATION.md` — validation expectations for this phase
- `.planning/milestones/v1.30-phases/092-linked-1-0-0-publish-post-publish-contract-sweep/092-01-PLAN.md` — current draft release-surface plan
- `.planning/milestones/v1.30-phases/092-linked-1-0-0-publish-post-publish-contract-sweep/092-02-PLAN.md` — current draft integrator/proof-surface plan
- `.planning/milestones/v1.30-phases/092-linked-1-0-0-publish-post-publish-contract-sweep/092-03-PLAN.md` — current draft publish-evidence / closeout plan

### Release automation and workflow contracts

- `RELEASING.md` — linked publish procedure, `Release-As: 1.0.0` bootstrap path, and publish-order contract
- `release-please-config.json` — linked-version manifest-mode configuration for the monorepo
- `.release-please-manifest.json` — lockstep release version source for `accrue` and `accrue_admin`
- `.github/workflows/release-please.yml` — actual release creation and ordered Hex publish workflow
- `.github/workflows/ci.yml` — authoritative `release-manifest-ssot`, `docs-contracts-shift-left`, and `host-integration` job definitions

### Verifier and proof-surface contracts

- `scripts/ci/verify_release_manifest_alignment.sh` — manifest ↔ `mix.exs` lockstep guard
- `scripts/ci/verify_package_docs.sh` — package README / First Hour install-literal contract
- `scripts/ci/verify_adoption_proof_matrix.sh` — adoption matrix contract
- `scripts/ci/verify_verify01_readme_contract.sh` — host README / VERIFY-01 contract
- `scripts/ci/verify_v1_17_friction_research_contract.sh` — friction / north-star SSOT contract in the docs bundle
- `scripts/ci/verify_production_readiness_discoverability.sh` — production-readiness doc discoverability contract
- `scripts/ci/verify_core_admin_invoice_verify_ids.sh` — admin invoice verify-id guard included in the docs bundle
- `scripts/ci/accrue_host_uat.sh` — host proof wrapper for the reviewed integrator slice
- `examples/accrue_host/README.md` — canonical host proof surface
- `examples/accrue_host/docs/adoption-proof-matrix.md` — canonical adoption proof surface
- `accrue/README.md` — package install/proof surface for `accrue`
- `accrue_admin/README.md` — package install/proof surface for `accrue_admin`
- `accrue/guides/first_hour.md` — First Hour install/proof surface

### External norms explicitly referenced during discussion

- `https://semver.org/` — stability semantics around `1.0.0`
- `https://keepachangelog.com/en/0.3.0/` — authoritative-release-surface bias and disciplined changelog scope
- `https://hex.pm/docs/publish` — Hex publish mechanics and package publication constraints
- `https://hex.pm/docs/faq` — Hex immutability / recovery context
- `https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md` — linked-version Release Please behavior in manifest mode
- `https://hexdocs.pm/phoenix_live_view/1.0.0/changelog.html` — focused 1.0 release communication precedent

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `release-please.yml` already encodes the required `accrue` → `accrue_admin` publish order and the `ACCRUE_ADMIN_HEX_RELEASE=1` gate, so Phase 92 should reuse that path rather than inventing a new release flow.
- The existing bash verifier suite under `scripts/ci/` already provides the contract scaffolding for package docs, host proof, adoption matrix, and manifest alignment; Phase 92 should tighten those contracts only where new `1.0.0` needles become necessary.
- Earlier verification artifacts (`068-VERIFICATION.md`, `086-VERIFICATION.md`, `091-VERIFICATION.md`) provide the project’s current proof style and should be reused rather than replaced with a new evidence format.

### Established Patterns

- Combined Release Please PRs are the repo’s established linked-release pattern for `accrue` + `accrue_admin`.
- Merge-blocking CI jobs, not ad-hoc maintainer judgment, define what “honest docs” means for release-facing surfaces.
- The repo prefers phase-local, grep-friendly verification docs with durable links rather than screenshots or sprawling narrative closeout notes.

### Integration Points

- `accrue/mix.exs`, `accrue_admin/mix.exs`, and `.release-please-manifest.json` must move in lockstep for the publish workflow and manifest SSOT guard to stay green.
- `accrue/README.md`, `accrue_admin/README.md`, and `accrue/guides/first_hour.md` are coupled directly to `verify_package_docs.sh`.
- `examples/accrue_host/README.md` and `examples/accrue_host/docs/adoption-proof-matrix.md` are the right place to make `1.0.0` explicit for integrators, because the host proof layer is where users validate the library in practice.
- `092-VERIFICATION.md` is the phase-local handoff between the release slice and Phase 93’s planning mirror / inventory work.

</code_context>

<specifics>
## Specific Ideas

- User preference locked for this phase family: research deeply, synthesize pros/cons/tradeoffs across Elixir/Phoenix/Plug/Ecto and adjacent ecosystems, then recommend one cohesive, low-surprise path rather than forcing manual arbitration of every choice.
- The chosen architecture intentionally emphasizes developer ergonomics and user trust: one release unit, one coherent truth story, one same-day evidence ledger.
- Manual release flows, split PRs, and heavier rollback playbooks were explicitly considered and rejected as primary strategies because they add maintainer burden without improving the default outcome for this repo.

</specifics>

<deferred>
## Deferred Ideas

- Broader post-1.0 editorial sweeps across adjacent docs and planning mirrors belong to Phase 93 or a later docs-focused milestone, not this release-surface phase.
- Heavy recovery/rollback runbook expansion can be revisited later if release automation becomes unreliable; it is not justified as default Phase 92 process.

### Reviewed Todos (not folded)

- None — `todo.match-phase "92"` returned no matches.

</deferred>

---

*Phase: 092-linked-1-0-0-publish-post-publish-contract-sweep*
*Context gathered: 2026-04-28*
