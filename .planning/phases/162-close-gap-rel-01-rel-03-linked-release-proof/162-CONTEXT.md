# Phase 162: Close gap: REL-01/REL-03 -- linked release proof - Context

**Gathered:** 2026-06-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the v1.48 REL-01/REL-03 audit gap by consuming the first real post-`1.3.0` linked release proof for `accrue`, `accrue_admin`, and `accrue_portal`, preserving one canonical release-truth ledger, and reconciling release-truth mirrors without fabricating proof. This phase is release proof and reconciliation only: no new billing primitives, processor surface, admin/portal feature work, release architecture rewrite, or stable-core positioning expansion.

</domain>

<decisions>
## Implementation Decisions

### Proof Artifact Intake
- **D-01:** Keep `.planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md` as the canonical append-only release-truth ledger. Phase 159 already owns the release proof contract, `scripts/ci/README.md` points REL-01/REL-03 there, and the current proof scripts are built around that file.
- **D-02:** Create `.planning/phases/162-close-gap-rel-01-rel-03-linked-release-proof/162-VERIFICATION.md` as a non-authoritative closeout/index file for Phase 162. It should record `PR_NUMBER`, `TARGET_VERSION`, `RUN_ID`, the GitHub Actions `linked-release-proof.md` artifact URL, and a pointer to the exact appended block in `159-VERIFICATION.md`.
- **D-03:** The Phase 162 verification file must say explicitly that it is an index/reconciliation record, not a second source of release truth. Downstream agents must avoid creating two competing proof ledgers.
- **D-04:** Do not retarget `capture_linked_release_proof.sh` or REL gate documentation away from `159-VERIFICATION.md` unless a future release-process phase deliberately migrates all canonical references atomically.

### Release Mirror Reconciliation
- **D-05:** Use full but narrow release-truth reconciliation as the closure bar. After canonical proof lands, reconcile the Phase 159 ledger, Phase 162 verification, v1.48 planning mirrors, package changelogs, `accrue/guides/release-notes.md`, GitHub release/tag state, Hex package state, HexDocs availability, host Hex smoke, and release-notes contract output.
- **D-06:** Public mirrors remain mirrors, not proof authority. If changelogs, release notes, GitHub releases, HexDocs, README references, or planning prose disagree with the canonical proof/public registry state, fix the mirror rather than weakening the proof requirement.
- **D-07:** README-style and broad posture documents should only be edited when they contain version-specific release claims that changed. Do not use Phase 162 to rewrite stable-core positioning, package ownership boundaries, or product scope.
- **D-08:** Reconciliation order should be: append/consume canonical proof first; update Phase 162 and v1.48 planning mirrors second; reconcile public version-truth mirrors third; run focused verifier/smoke checks last.

### Failure and Retry Ledger
- **D-09:** If `linked-release-proof` fails before any package reaches public Hex, a raw CI failure URL plus failing step in the canonical ledger is enough to explain the blocked state.
- **D-10:** If the job fails after any package reaches public Hex, append a structured recovery block to the canonical ledger before retrying. Required fields: `target_version`, `run_id`, `pr_number`, per-package public state, failed package or proof step, chosen recovery path, next command, and timestamp.
- **D-11:** Recovery paths should preserve Phase 159 policy: retry the same version for downstream failures when upstream package state is correct; use Hex revert only for a clear mistake inside Hex's narrow allowed window; otherwise retire the bad line and ship a new linked patch line forward with changelog honesty.
- **D-12:** Do not create separate failed-attempt appendix files by default. They split authority and make retry state harder for downstream agents to reason about. A future compliance-driven phase may add incident files if it also adds strict cross-link verification.

### Requirement Closure Boundary
- **D-13:** REL-01 closes when a real combined Release Please PR targets a version greater than `1.3.0`, `verify_release_pr_scope.sh --pr <pr> --version <target>` passes for that PR/version pair, and the canonical ledger records the exact PR number and target version.
- **D-14:** REL-03 closes when the `linked-release-proof` CI artifact succeeds for the same target version and targeted corroboration passes: `capture_linked_release_proof.sh`, `scripts/ci/accrue_host_hex_smoke.sh` in a clean context, and `scripts/ci/verify_release_notes_contract.sh`.
- **D-15:** CI proof is the primary evidence, but not the only evidence. The independent host Hex smoke protects the adopter install path, and the release-notes contract protects public mirror truth.
- **D-16:** Manual public-surface audit is anomaly-triggered, not mandatory for every release. Require it when proof scripts disagree, CI reruns are stale, release-process code changed materially, Hex/GitHub surfaces show propagation anomalies, or a prior failure/retry block exists for the same target version.

### Cohesive Recommendation
- **D-17:** Phase 162 should land as a tight proof-reconciliation slice: append real proof to the Phase 159 ledger, create a Phase 162 pointer verification, reconcile all release-truth mirrors narrowly, record any failure/retry state in the canonical ledger, and close REL-01/REL-03 only after CI proof plus targeted scripted corroboration.
- **D-18:** The architecture should optimize maintainer DX during a stressful release: one proof authority, one target version, one PR number, one run id, script-generated evidence, thin mirrors, and explicit recovery state.

### the agent's Discretion
- Downstream agents may choose the exact heading names in `162-VERIFICATION.md`, but must preserve the non-authoritative pointer/index role.
- Downstream agents may add a small verifier or checklist guard only if it reduces drift without introducing a second proof source. Prefer extending existing release scripts or docs-contract guidance over creating new ceremony.
- Downstream agents may decide whether the structured recovery block is written by script or by a carefully templated manual append. The default preference is script-friendly structure in the canonical ledger.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Locked Requirements
- `.planning/ROADMAP.md` -- Phase 162 goal, dependency on Phase 161, REL-01/REL-03 success criteria, and no-fabricated-proof boundary.
- `.planning/REQUIREMENTS.md` -- REL-01 and REL-03 definitions plus v1.48 out-of-scope boundaries.
- `.planning/PROJECT.md` -- stable-core / demand-driven expansion posture, package ownership boundaries, and release-readiness default posture.
- `.planning/STATE.md` -- current milestone cursor, Phase 162 state, and recent release-proof decisions.
- `prompts/MILESTONE-NEXT-STEP-ASSESSMENT.md` -- maintainer preference for research-backed cohesive recommendations, DX, least surprise, proof honesty, and adopter-first done criteria.

### Prior Release-Proof Decisions
- `.planning/phases/159-linked-release-readiness-publish-proof/159-CONTEXT.md` -- locked release architecture: composite release truth, canonical ledger, ordered publish, full post-publish proof, and recovery policy.
- `.planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md` -- canonical append-only release-truth ledger and current REL-01/REL-03 blocker state.
- `.planning/phases/159-linked-release-readiness-publish-proof/159-02-SUMMARY.md` -- CI-owned `linked-release-proof` handoff and warning that automation wiring alone does not close REL-01/REL-03.
- `.planning/phases/160-stable-core-public-positioning/160-CONTEXT.md` -- public mirror discipline, stable-core language, and verifier style; useful to avoid Phase 162 scope creep.
- `.planning/phases/161-backlog-anchor-closure-pause-rule/161-CONTEXT.md` -- post-v1.48 pause rule and planning-hygiene mirror policy.

### Release Runbook and Automation
- `RELEASING.md` -- linked release runbook, ordered publish guidance, fallback policy, deterministic gate expectations, and recovery instructions.
- `release-please-config.json` -- combined three-package Release Please config and linked-versions plugin.
- `.release-please-manifest.json` -- pre-publish version manifest for `accrue`, `accrue_admin`, and `accrue_portal`.
- `.github/workflows/release-please.yml` -- primary Release Please workflow, ordered publish jobs, and `linked-release-proof` job.
- `.github/workflows/publish-hex.yml` -- manual fallback/recovery workflow; fallback-only, not the primary path.
- `.github/workflows/release-pr-automation.yml` -- optional maintainer-reviewed Release Please PR merge automation.

### Package Version and Public Mirrors
- `accrue/mix.exs` -- core package `@version`, docs `source_ref`, and package metadata.
- `accrue_admin/mix.exs` -- admin package `@version`, publish-mode core dependency switch, docs `source_ref`.
- `accrue_portal/mix.exs` -- portal package `@version`, publish-mode exact core dependency switch, docs `source_ref`.
- `accrue/CHANGELOG.md` -- core package public changelog mirror.
- `accrue_admin/CHANGELOG.md` -- admin package public changelog mirror.
- `accrue_portal/CHANGELOG.md` -- portal package public changelog mirror.
- `accrue/guides/release-notes.md` -- public release-notes mirror checked by release-note verifier.
- `README.md` -- root public release/proof posture; edit only if version-specific claims change.

### Verification and Proof Scripts
- `scripts/ci/README.md` -- REL gate map, triage guidance, and current ownership of REL-01/REL-03 proof artifacts.
- `scripts/ci/verify_release_pr_scope.sh` -- pre-merge Release Please PR contract verifier for all three packages.
- `scripts/ci/verify_release_manifest_alignment.sh` -- manifest and package `mix.exs` lockstep verifier.
- `scripts/ci/capture_linked_release_proof.sh` -- canonical proof capture script; appends/produces proof keyed to one PR, target version, and run id.
- `scripts/ci/accrue_host_hex_smoke.sh` -- post-publish consumer install smoke for all three linked packages.
- `scripts/ci/verify_release_notes_contract.sh` -- release-notes freshness and mirror contract.
- `scripts/ci/verify_release_contract.sh` -- release contract verifier.
- `scripts/ci/verify_package_docs.sh` -- package docs drift gate.
- `scripts/ci/verify_processor_support_matrix.sh` -- support-matrix drift gate.
- `scripts/ci/verify_adoption_proof_matrix.sh` -- adoption proof drift gate.
- `scripts/ci/accrue_host_uat.sh` -- host integration proof wrapper.

### External Release Semantics
- `https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html` -- Hex publish, update/revert windows, docs publish, and package constraints.
- `https://hex.pm/docs/publish` -- Hex package metadata, CI publish guidance, HexDocs behavior, and post-publish testing guidance.
- `https://github.com/googleapis/release-please-action` -- Release Please action behavior and outputs.
- `https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md` -- manifest releaser and monorepo release configuration.
- `https://docs.npmjs.com/policies/unpublish` -- ecosystem precedent for preferring additive remediation over destructive package removal.
- `https://doc.rust-lang.org/cargo/commands/cargo-yank.html` -- Cargo yank precedent for preserving immutable package history while steering users away from bad versions.
- `https://docs.pypi.org/project-management/yanking/` -- PyPI yank precedent for forward recovery and explicit public-state handling.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/ci/capture_linked_release_proof.sh`: already supports `--auto`, derives PR/version/run identifiers in GitHub Actions, validates target version is greater than `1.3.0`, and captures tags, GitHub releases, Hex API truth, HexDocs, release file snapshots, and workflow job ordering.
- `scripts/ci/verify_release_pr_scope.sh`: already proves a Release Please PR touches the required three-package manifest, `mix.exs`, and changelog files, with optional exact target-version validation.
- `scripts/ci/accrue_host_hex_smoke.sh`: already waits for all three linked Hex packages in GitHub Actions and proves the post-publish consumer install path.
- `.github/workflows/release-please.yml`: already runs `linked-release-proof` after the ordered `release`, `publish-accrue`, `publish-accrue-admin`, and `publish-accrue-portal` jobs.
- `scripts/ci/README.md`: already maps REL-01/REL-03 to Phase 159 verification and names the relevant proof scripts.

### Established Patterns
- Accrue release proof favors append-only planning ledgers plus script-generated mechanical evidence over hand-written claims.
- Public release surfaces are mirrors of registry/tag/proof truth, not proof authority by themselves.
- Linked package release work prioritizes deterministic ordering and recovery clarity over speed.
- Fake-backed host integration and host Hex smoke are first-class proof lanes; live provider lanes remain advisory.
- Existing docs-contract verifiers use lightweight Bash scripts, narrow needles, and grep-friendly triage rather than heavyweight framework-specific ceremony.

### Integration Points
- `159-VERIFICATION.md` remains the canonical proof sink and should receive the real post-`1.3.0` proof block or structured recovery block.
- `162-VERIFICATION.md` should summarize Phase 162 closure and point to canonical proof, but must not duplicate full proof authority.
- v1.48 planning mirrors (`ROADMAP.md`, `STATE.md`, `PROJECT.md`, milestone audit files if present) should be reconciled only after proof exists.
- Package changelogs and `accrue/guides/release-notes.md` should be checked against the target version after Release Please and publish complete.

</code_context>

<specifics>
## Specific Ideas

- User explicitly requested all four gray areas be researched with subagents, including pros/cons/tradeoffs, Elixir/Phoenix/Hex idioms, ecosystem lessons from other languages/frameworks, footguns, DX, least surprise, and a cohesive one-shot recommendation.
- Advisor researchers converged on one coherent release-proof shape:
  - keep the Phase 159 ledger canonical;
  - add a Phase 162 pointer/index verification;
  - reconcile all release-truth mirrors narrowly;
  - record partial-publish failures as structured recovery blocks in the canonical ledger;
  - close REL-01/REL-03 only with CI proof plus targeted scripted corroboration.
- The key footgun is splitting proof authority between Phase 159 and Phase 162. Phase 162 exists to close the audit gap, not to replace the proof architecture.
- The second footgun is treating one surface as enough: a manifest bump, changelog heading, GitHub release, Hex package, or CI run alone is not sufficient for linked release truth.
- The third footgun is overcorrecting with mandatory manual audits every release. Manual audit should be reserved for anomalies; routine closure should be script-first and repeatable.

</specifics>

<deferred>
## Deferred Ideas

None -- discussion stayed within Phase 162 release-proof and reconciliation scope.

</deferred>

---

*Phase: 162-Close gap: REL-01/REL-03 -- linked release proof*
*Context gathered: 2026-06-01*
