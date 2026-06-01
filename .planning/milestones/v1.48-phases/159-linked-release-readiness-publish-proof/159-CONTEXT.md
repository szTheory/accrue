# Phase 159: Linked Release Readiness + Publish Proof - Context

**Gathered:** 2026-05-31
**Status:** Ready for planning

<domain>
## Phase Boundary

Verify, publish, and record the next linked release line after `1.3.0` for `accrue`, `accrue_admin`, and `accrue_portal` with one coherent release-truth artifact. This phase is release readiness and proof only: no new billing primitives, processor surface, admin/portal feature work, or stable-core positioning rewrite beyond the release evidence needed for REL-01, REL-02, and REL-03.

</domain>

<decisions>
## Implementation Decisions

### Release Truth Source of Record
- **D-01:** Use a composite release-truth artifact as the canonical pass/fail record for Phase 159. No single surface is authoritative under disagreement: `.release-please-manifest.json` and the combined Release Please PR are pre-publish intent; Hex package state plus git tags/GitHub releases are post-publish public fact; the release-truth artifact reconciles both.
- **D-02:** Treat changelogs, GitHub release notes, package docs, and planning mirrors as public mirrors of the release truth, not the proof authority. If they disagree with the artifact or public registry/tag state, downstream agents must fix the disagreement rather than rationalize it.
- **D-03:** Explicitly reject "manifest-only", "Hex-only", and "changelog-only" truth models for this linked release. They are useful inputs, but each leaves a known split-brain failure mode for a three-package Hex line.

### Deterministic Gate Artifact Shape
- **D-04:** Produce one consolidated, machine-checkable release readiness / publish proof artifact for this phase, preferably `.planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md`, following the existing Phase 121 linked-release proof style.
- **D-05:** The artifact should have a fixed schema covering: target version, Release Please PR number, Release Please workflow run id, package `mix.exs` versions, `.release-please-manifest.json`, package changelog headings, Release Please job outputs, deterministic gate results, docs/support drift gates, host integration, git tags, GitHub release URLs/timestamps, Hex API truth, HexDocs availability, and any host Hex smoke result.
- **D-06:** Prefer script-generated or script-appended proof over hand-written prose. Human notes may explain unusual recovery, but mechanical facts should come from scripts such as `verify_release_pr_scope.sh`, `verify_release_manifest_alignment.sh`, and `capture_linked_release_proof.sh`.
- **D-07:** Tighten any release verifier that still checks only `accrue` / `accrue_admin` so it includes `accrue_portal` as a first-class linked package. Three-package lockstep is the Phase 159 contract.

### Publish Order and Recovery Policy
- **D-08:** Preserve strict serialized publish order: publish `accrue` first, then `accrue_admin`, then `accrue_portal`. Do not parallelize admin and portal for speed; deterministic ordering and recovery clarity matter more than release throughput.
- **D-09:** Keep `ACCRUE_ADMIN_HEX_RELEASE=1` and `ACCRUE_PORTAL_HEX_RELEASE=1` as the package-local publish-mode switches so downstream packages resolve the just-published core package from Hex during dry-run and publish.
- **D-10:** Recovery policy is: retry the same version for downstream package failures when upstream `accrue` at version `V` is already correct on Hex; use `mix hex.publish --revert VERSION` only for a clear mistake inside Hex's narrow allowed update/revert window; otherwise retire the bad version and ship a new linked patch line forward with explicit changelog honesty.
- **D-11:** Manual `publish-hex.yml` remains a fallback/recovery path, not the primary release path. The primary path is the combined Release Please PR plus ordered publish jobs in `.github/workflows/release-please.yml`.

### Post-Publish Proof Depth
- **D-12:** Require full post-publish proof, not minimal Hex availability. The proof must show all three packages are available on Hex at the target version and must also reconcile HexDocs, git tags, GitHub releases, changelogs/release notes, workflow ordering, and deterministic gate outputs.
- **D-13:** Keep host Hex smoke as necessary-but-not-sufficient evidence. It proves consumer install behavior, but it does not replace registry/tag/release-note/gate reconciliation.
- **D-14:** Provider-backed Stripe/live lanes remain advisory and must not be introduced as package-release blockers. The Fake-backed deterministic gate remains the release readiness lane.

### the agent's Discretion
- Downstream agents may choose the exact formatting of `159-VERIFICATION.md` as long as it remains a single canonical artifact, is script-friendly, includes all three packages, and preserves the Phase 121 append-only proof style where useful.
- Downstream agents may update release verifier scripts, runbook wording, and planning mirrors as needed to make the above decisions enforceable, but must not widen Phase 159 into stable-core positioning or backlog cleanup work reserved for Phases 160 and 161.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Project Posture
- `.planning/ROADMAP.md` — Phase 159 goal, dependencies, success criteria, and one-plan boundary.
- `.planning/REQUIREMENTS.md` — REL-01, REL-02, REL-03 and v1.48 out-of-scope boundaries.
- `.planning/PROJECT.md` — stable-core / demand-driven expansion posture and package ownership boundaries.
- `.planning/STATE.md` — current milestone state and recent release-readiness decisions.
- `prompts/MILESTONE-NEXT-STEP-ASSESSMENT.md` — adopter-first, repo-local truth, overbuilding guardrails, and research/DX framing preferences that inform this context.

### Release Runbook and Automation
- `RELEASING.md` — linked release runbook, Release Please + Hex contract, deterministic gate expectations, manual fallback, and partial publish recovery.
- `release-please-config.json` — combined three-package Release Please config, linked-versions plugin, package changelog paths, and component tags.
- `.release-please-manifest.json` — current pre-publish version manifest for `accrue`, `accrue_admin`, and `accrue_portal`.
- `.github/workflows/release-please.yml` — primary release and ordered Hex publish workflow.
- `.github/workflows/publish-hex.yml` — manual fallback/recovery workflow.
- `.github/workflows/release-pr-automation.yml` — optional maintainer-reviewed release PR merge automation.

### Package Version and Public Mirrors
- `accrue/mix.exs` — core package `@version`, package files, docs `source_ref`, and release docs configuration.
- `accrue_admin/mix.exs` — admin package `@version`, publish-mode `accrue` dependency switch, docs `source_ref`.
- `accrue_portal/mix.exs` — portal package `@version`, publish-mode exact `accrue` dependency switch, docs `source_ref`.
- `accrue/CHANGELOG.md` — core package public changelog mirror.
- `accrue_admin/CHANGELOG.md` — admin package public changelog mirror.
- `accrue_portal/CHANGELOG.md` — portal package public changelog mirror.
- `accrue/guides/release-notes.md` — public release notes mirror checked by release-note verifier.

### Verification and Proof Scripts
- `scripts/ci/README.md` — CI gate map, release gate triage, and Phase 121 linked publish proof precedent.
- `scripts/ci/verify_release_pr_scope.sh` — pre-merge Release Please PR contract verifier.
- `scripts/ci/capture_linked_release_proof.sh` — post-publish linked release proof capture script; strongest existing model for Phase 159 proof.
- `scripts/ci/verify_release_manifest_alignment.sh` — manifest vs package version alignment; must be evaluated for `accrue_portal` coverage.
- `scripts/ci/verify_release_contract.sh` — release contract verifier.
- `scripts/ci/verify_release_notes_contract.sh` — release notes freshness gate.
- `scripts/ci/verify_package_docs.sh` — package docs drift gate.
- `scripts/ci/verify_processor_support_matrix.sh` — support-matrix drift gate.
- `scripts/ci/verify_adoption_proof_matrix.sh` — adoption proof drift gate.
- `scripts/ci/accrue_host_uat.sh` — host integration proof wrapper.
- `scripts/ci/accrue_host_hex_smoke.sh` — post-publish Hex consumer smoke.

### External Primary Sources Consulted
- `https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html` — Hex publish, dry-run, docs publish, update/revert windows, and package constraints.
- `https://hex.pm/docs/publish` — Hex package metadata, CI publish guidance, HexDocs behavior, and post-publish testing guidance.
- `https://github.com/googleapis/release-please-action` — Release Please outputs and path-prefixed monorepo output behavior.
- `https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md` — manifest releaser, combined PR behavior, and monorepo release configuration.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/ci/capture_linked_release_proof.sh`: already appends a deterministic proof block keyed by PR, target version, and Release Please run id, including job ordering, git tags, GitHub releases, and Hex API truth for all three packages. Use this as the proof artifact spine.
- `scripts/ci/verify_release_pr_scope.sh`: already enforces the Release Please PR file set for all three packages and optional exact target version. Use before merge.
- `.github/workflows/release-please.yml`: already serializes publish jobs as `accrue` -> `accrue_admin` -> `accrue_portal` and checks out the release SHA for each package before publishing.
- `.github/workflows/publish-hex.yml`: already supports explicit package/ref/version recovery publishes and should remain fallback-only.
- Package `mix.exs` files: admin and portal already switch from path dependency to Hex dependency under publish-mode environment variables.

### Established Patterns
- Release Please owns version bumps and package changelog sections through a combined linked release PR.
- Planning milestone labels are not public SemVer truth; public consumers resolve against Hex versions and package changelogs.
- Fake-backed host integration is the deterministic release lane; live Stripe/provider parity is advisory.
- Support/docs/adoption drift gates are intentionally shift-left bash scripts with human-readable triage in `scripts/ci/README.md`.
- Phase 121 established an append-only linked release proof pattern; Phase 159 should reuse and harden it rather than inventing a second proof format.

### Integration Points
- Planning output: `159-VERIFICATION.md` should become the canonical release-truth artifact for this phase.
- Runbook output: `RELEASING.md` may need small corrections if current workflow/script behavior has drifted, especially around three-package references.
- CI/script output: release alignment scripts may need `accrue_portal` coverage and a clearer consolidated gate command for REL-02.
- Public mirror output: package changelogs, `accrue/guides/release-notes.md`, HexDocs, and GitHub releases must agree with the artifact after publish.

</code_context>

<specifics>
## Specific Ideas

- The recommendations were researched in parallel across all four gray areas and intentionally collapsed into one coherent release architecture: composite artifact, strict serialized publish, full proof depth, and public mirrors as mirrors.
- The phase should optimize for maintainer DX during a stressful publish: one place to look, one target version, one PR number, one run id, one ledger that says what is fact.
- The main footgun to prevent is claiming a linked release is shipped because one surface advanced: a manifest bump, a GitHub release, a changelog heading, or a single Hex package is not enough.
- Hex immutability/revert windows make prevention and fast proof more valuable than broad manual recovery.
- Release Please is version/changelog/tag/release orchestration; it is not an atomic multi-package Hex publish transaction.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within Phase 159 release-readiness scope.

</deferred>

---

*Phase: 159-Linked Release Readiness + Publish Proof*
*Context gathered: 2026-05-31*
