# Phase 121: Linked publish + proof sweep - Research

**Researched:** 2026-05-07
**Domain:** Release publication, public proof capture, post-publish docs/verifier sweep
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

No phase-specific `*-CONTEXT.md` file exists for Phase 121. [VERIFIED: `.planning/phases/121-linked-publish-proof-sweep/`]

Use the active phase requirements and milestone framing as the binding scope:
- `REL-10`: the next public release must land with matching package `@version`, git tags, GitHub releases, and changelog sections for every package intentionally included in the linked release. [VERIFIED: `.planning/REQUIREMENTS.md`]
- `REL-11`: the publish proof chain must record the ordered release outcome for the linked package set, including dependency ordering between `accrue` and UI packages. [VERIFIED: `.planning/REQUIREMENTS.md`]
- `PPX-13`: `bash scripts/ci/verify_package_docs.sh` must pass after release, and enforced install/version literals across package READMEs and First Hour must reflect the actual published package line. [VERIFIED: `.planning/REQUIREMENTS.md`]
- `PPX-14`: `bash scripts/ci/verify_adoption_proof_matrix.sh` and the merge-blocking `docs-contracts-shift-left` bundle must pass against the post-release docs state, with touched mirrors kept aligned in the same truth chain. [VERIFIED: `.planning/REQUIREMENTS.md`; `.github/workflows/ci.yml`; `scripts/ci/README.md`]
- This milestone is release-operational only: planning should optimize for publish proof sequencing, evidence capture, rerunnable verification, and minimal manual ambiguity rather than new product work. [VERIFIED: user prompt; `.planning/ROADMAP.md`; `.planning/STATE.md`]
- Phase 120 already locked the release-contract scope to `promote-three-package`: `accrue`, `accrue_admin`, and `accrue_portal` are the intended linked public release set. [VERIFIED: `.planning/phases/120-release-contract-audit/120-01-SUMMARY.md`; `.planning/phases/120-release-contract-audit/120-02-SUMMARY.md`; `.planning/phases/120-release-contract-audit/120-03-SUMMARY.md`]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REL-10 | Matching package `@version`, tags, GitHub releases, and changelog sections for every package in the linked release. | Summary; Standard Stack; Architecture Patterns; Common Pitfalls; Validation Architecture. |
| REL-11 | Ordered publish proof for the linked package set, including dependency ordering. | Summary; Architectural Responsibility Map; Architecture Patterns; Code Examples; Validation Architecture. |
| PPX-13 | `verify_package_docs.sh` passes post-release and enforced install/version literals reflect the published line. | Summary; Common Pitfalls; Validation Architecture. |
| PPX-14 | `verify_adoption_proof_matrix.sh` and the merge-blocking docs bundle pass against post-release docs state. | Summary; Architecture Patterns; Validation Architecture; Open Questions. |
</phase_requirements>

## Summary

As of **2026-05-07**, the repo’s internal release contract is already a three-package `1.0.0` line: `release-please-config.json`, `.release-please-manifest.json`, `RELEASING.md`, `.github/workflows/release-please.yml`, `.github/workflows/publish-hex.yml`, and all three package `mix.exs` files describe or encode `accrue`, `accrue_admin`, and `accrue_portal` together. [VERIFIED: `release-please-config.json`; `.release-please-manifest.json`; `RELEASING.md`; `.github/workflows/release-please.yml`; `.github/workflows/publish-hex.yml`; `accrue/mix.exs`; `accrue_admin/mix.exs`; `accrue_portal/mix.exs`] Public release truth is still incomplete: Hex and GitHub show `accrue` and `accrue_admin` at `1.0.0` published on **2026-04-28**, while `accrue_portal` still returns `404` from the Hex API and there is no `accrue_portal-v*` tag in the repo. [VERIFIED: hex.pm API `https://hex.pm/api/packages/accrue`; VERIFIED: hex.pm API `https://hex.pm/api/packages/accrue_admin`; VERIFIED: hex.pm API `https://hex.pm/api/packages/accrue_portal`; VERIFIED: local git tags `accrue_portal-v*`; VERIFIED: `gh release list --repo szTheory/accrue`]

There is also an already-open Release Please PR, **#18**, created on **2026-04-28**, with `autorelease: pending`. It proposes `1.0.1` for `accrue` and `accrue_admin` only and does not touch `accrue_portal`, which means the planner cannot assume “merge the existing release PR” satisfies the now-locked three-package contract. [VERIFIED: `gh pr view 18 --repo szTheory/accrue --json ...`] Official Release Please docs say stale `autorelease: pending` labels can block new release PR creation, and release PR generation depends on releasable units since the last release. [CITED: https://github.com/googleapis/release-please/blob/main/README.md] Phase 121 therefore needs a deliberate pre-publish step to refresh, replace, or otherwise repair the release PR so the publish artifact matches the current contract before any merge/publish proof begins. [VERIFIED: `gh pr view 18 --repo szTheory/accrue --json ...`; CITED: https://github.com/googleapis/release-please/blob/main/README.md]

The existing shell verifier bundle is necessary but not sufficient. It passes locally today, which means the manifest/workflow/runbook contract is aligned, but it does not yet prove public release truth and it does not catch every lingering “pair” mirror in user-facing docs: the root README, First Hour, host README, and adoption proof matrix still describe a linked `accrue`/`accrue_admin` pair in places even though the maintainer-facing release contract now says trio. [VERIFIED: `bash scripts/ci/verify_release_manifest_alignment.sh`; `bash scripts/ci/verify_release_contract.sh`; `bash scripts/ci/verify_package_docs.sh`; `bash scripts/ci/verify_adoption_proof_matrix.sh`; `README.md`; `accrue/guides/first_hour.md`; `examples/accrue_host/README.md`; `examples/accrue_host/docs/adoption-proof-matrix.md`] Planning should therefore separate the phase into three proof stages: release-PR correctness before merge, ordered publish evidence during release, and post-publish docs/verifier reruns plus mirror cleanup after registry truth exists. [VERIFIED: repo release/workflow/docs state]

**Primary recommendation:** Refresh the release PR until it represents the three-package linked line, publish in the enforced order `accrue -> accrue_admin -> accrue_portal`, and record one dated evidence ledger that ties PR contents, tags, GitHub releases, Hex API responses, and post-publish verifier reruns to the same version. [VERIFIED: `.github/workflows/release-please.yml`; `accrue_admin/mix.exs`; `accrue_portal/mix.exs`; `.planning/REQUIREMENTS.md`]

## Project Constraints (from CLAUDE.md)

- The supported floor is Elixir `1.17+`, OTP `27+`, Phoenix `1.8+`, Ecto `3.12+`, PostgreSQL `14+`; release work must not introduce guidance that implies older support. [VERIFIED: `CLAUDE.md`]
- The repo is a monorepo with sibling packages and shared release/docs/workflow infrastructure; package release planning must treat cross-package drift as a monorepo concern, not as isolated packages. [VERIFIED: `CLAUDE.md`; repo layout]
- The release model is “ship complete,” not an open-ended `0.x` public iteration path. [VERIFIED: `CLAUDE.md`]
- Webhook signature verification is mandatory and non-bypassable, sensitive Stripe fields must never be logged, and payment-method PII must not be stored; release docs and proof artifacts must not weaken or leak this posture. [VERIFIED: `CLAUDE.md`; `RELEASING.md`]
- Observability is part of the public contract, so post-publish proof should preserve honest telemetry/proof wording rather than hand-wave it away. [VERIFIED: `CLAUDE.md`; `README.md`; `RELEASING.md`]
- Repo workflow guidance says direct file edits should normally stay inside GSD workflow context; planning should assume artifacts like research/plan/verification docs remain part of the maintained workflow chain. [VERIFIED: `CLAUDE.md`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Release PR generation | Release Please | GitHub PR state | Release Please owns changelog/version PR generation and GitHub release tagging mechanics, while GitHub stores the current open PR state. [CITED: https://github.com/googleapis/release-please/blob/main/README.md] [VERIFIED: `gh pr view 18 --repo szTheory/accrue --json ...`] |
| Linked-version scope | Manifest/config | Bash verifiers | The `linked-versions` plugin configuration and manifest define the intended package set, and Phase 120 verifiers enforce that contract. [CITED: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md] [VERIFIED: `release-please-config.json`; `.release-please-manifest.json`; `scripts/ci/verify_release_contract.sh`] |
| Ordered publication | GitHub Actions workflows | Package dependency graph | Publish order is enforced in workflow `needs:` chains, and the package dependency graph explains why `accrue` must publish first. [VERIFIED: `.github/workflows/release-please.yml`; `accrue_admin/mix.exs`; `accrue_portal/mix.exs`] |
| Public release truth | Hex registry | Git tags / GitHub releases | Registry availability is the consumer-facing truth, while tags/releases provide the corresponding git/GitHub evidence. [VERIFIED: hex.pm APIs; `gh release list --repo szTheory/accrue`; local git tags] |
| Post-publish doc truth | Package/host docs | Bash verifier bundle | Package READMEs, First Hour, and host proof docs must reflect the published line, and the bash bundle is the merge-blocking drift detector. [VERIFIED: `README.md`; `accrue/guides/first_hour.md`; `examples/accrue_host/README.md`; `examples/accrue_host/docs/adoption-proof-matrix.md`; `.github/workflows/ci.yml`; `scripts/ci/README.md`] |
| Recovery path | Manual workflow | Runbook | `.github/workflows/publish-hex.yml` is the executable recovery path and `RELEASING.md` is the maintainer narrative for when to use it. [VERIFIED: `.github/workflows/publish-hex.yml`; `RELEASING.md`] |
| Proof ledger | Phase verification artifact | CLI/API commands | The repo has workflow/docs/verifier primitives, but Phase 121 still needs one consolidated artifact that proves the shipped line end-to-end. [VERIFIED: Phase 120 artifacts; current absence of a Phase 121 verification artifact] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `release-please` CLI | `17.6.0` | Release PR generation, version bumps, changelog sections, GitHub releases/tags | The workflow already pins `release-please@17.6.0`, and `npm view` shows `17.6.0` published on **2026-04-13**. [VERIFIED: `.github/workflows/release-please.yml`; VERIFIED: npm registry] |
| Release Please manifest mode | current repo config | Multi-package release coordination | Official docs describe manifest mode as the monorepo path and the `linked-versions` plugin as the version-sync mechanism. [CITED: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md] |
| GitHub Actions release workflows | `ubuntu-24.04`, `actions/checkout@v6`, `erlef/setup-beam@v1` | Automated publish order, dry runs, and recovery path | This repo already encodes the publish path here; Phase 121 should use it rather than invent a second release mechanism. [VERIFIED: `.github/workflows/release-please.yml`; `.github/workflows/publish-hex.yml`] |
| Hex.pm API | current public registry | Registry truth checks after publish | Hex API responses are the fastest authoritative proof that package versions are publicly resolvable. [VERIFIED: hex.pm APIs] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `gh` CLI | `2.89.0` | Inspect release PRs, releases, checks, and workflow runs | Required for evidence capture around the open release PR, GitHub releases, and workflow/job outcomes. [VERIFIED: local env `gh version 2.89.0`; VERIFIED: local `gh auth status`] |
| `jq` | `1.7.1` | Parse manifest/API JSON | Needed by current verifiers and useful for repeatable release-proof commands. [VERIFIED: local env `jq-1.7.1-apple`; VERIFIED: `scripts/ci/verify_release_manifest_alignment.sh`] |
| Elixir / Mix | `1.19.5` locally; CI targets `1.17.3`, `1.18.0`, `1.18.4` | Publish dry runs and release-validation commands | Publish workflows call `mix deps.get`, `mix hex.publish --dry-run`, and `mix hex.publish --yes`; CI matrix defines the supported floor/target. [VERIFIED: local env `elixir -v`; VERIFIED: local env `mix --version`; VERIFIED: `.github/workflows/release-please.yml`; VERIFIED: `.github/workflows/ci.yml`] |
| `curl` | `8.7.1` | Fast registry/API checks | Best low-friction way to record version/timestamp proof in a verification ledger. [VERIFIED: local env `curl 8.7.1`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Merge the existing open Release Please PR `#18` as-is | Refresh or replace it before merge | PR `#18` currently proposes `1.0.1` for `accrue` and `accrue_admin` only, so merging it as-is would violate the current three-package contract. [VERIFIED: `gh pr view 18 --repo szTheory/accrue --json ...`; VERIFIED: Phase 120 summaries] |
| Publish `accrue_portal` as a standalone late `1.0.0` while core/admin stay on `1.0.0` | Ship a new synchronized trio line (likely `1.0.1`) | Standalone `accrue_portal 1.0.0` would close the missing-public-package gap with minimal version churn, but it would bypass the current combined release PR truth and requires explicit judgment about whether the “next public release” is remedial or a new linked line. [VERIFIED: current registry/tag state; VERIFIED: `gh pr view 18 --repo szTheory/accrue --json ...`] |
| Switch to `googleapis/release-please-action@v4` outputs directly | Keep the current custom CLI + `gh release view` workflow | Official action docs document monorepo path-prefixed outputs, but the repo already implemented custom outputs and fallback behavior; replacing that in Phase 121 would expand scope without directly solving the proof gap. [CITED: https://github.com/googleapis/release-please-action/blob/main/README.md] [VERIFIED: `.github/workflows/release-please.yml`] |

**Installation:** The repo uses `npx` rather than a checked-in dependency for Release Please. [VERIFIED: `.github/workflows/release-please.yml`]

```bash
npx --yes release-please@17.6.0 release-pr \
  --repo-url szTheory/accrue \
  --config-file release-please-config.json \
  --manifest-file .release-please-manifest.json
```

**Version verification:** `npm view release-please version time --json` returned current version `17.6.0` and publish time `2026-04-13T21:15:22.890Z`. [VERIFIED: npm registry]

## Architecture Patterns

### System Architecture Diagram

```text
commits on main
  ->
Release Please PR state
  -> open PR must reflect all linked packages and desired version
  ->
maintainer review / merge
  ->
.github/workflows/release-please.yml
  -> release-please github-release
  -> tags + GitHub releases
  -> custom per-package outputs
  ->
publish-accrue
  -> Hex API proof: accrue @ V exists
  ->
publish-accrue-admin
  -> Hex API proof: accrue_admin @ V exists
  ->
publish-accrue-portal
  -> Hex API proof: accrue_portal @ V exists
  ->
post-publish proof sweep
  -> tags/releases/registry ledger
  -> verify_package_docs.sh
  -> docs-contracts-shift-left bundle
  -> Phase 121 verification artifact
```

The key ownership boundary is unchanged from Phase 120: Release Please owns release PRs, tags, GitHub releases, and version/changelog bumps, while package publication and dependency-safe sequencing are owned by GitHub Actions workflow logic. [CITED: https://github.com/googleapis/release-please/blob/main/README.md] [VERIFIED: `.github/workflows/release-please.yml`]

### Recommended Project Structure

```text
repo root
├── RELEASING.md                                # maintainer runbook
├── release-please-config.json                  # linked package set
├── .release-please-manifest.json               # current version line
├── .github/workflows/release-please.yml        # automated publish path
├── .github/workflows/publish-hex.yml           # manual recovery path
├── scripts/ci/verify_release_manifest_alignment.sh
├── scripts/ci/verify_release_contract.sh
├── scripts/ci/verify_package_docs.sh
├── scripts/ci/verify_adoption_proof_matrix.sh
└── .planning/phases/121-linked-publish-proof-sweep/
    ├── 121-RESEARCH.md
    └── 121-VERIFICATION.md                     # recommended proof ledger
```

### Pattern 1: Refresh the Release PR Before Publish

**What:** Treat the currently-open Release Please PR as a mutable precondition, not as trusted truth. Confirm that the PR file set, version, and package list match the Phase 120 three-package contract before merge. [VERIFIED: `gh pr view 18 --repo szTheory/accrue --json ...`; VERIFIED: Phase 120 summaries]

**When to use:** Any time a release PR predates a contract change, carries `autorelease: pending`, or omits part of the intended linked package set. [VERIFIED: `gh pr view 18 --repo szTheory/accrue --json ...`; CITED: https://github.com/googleapis/release-please/blob/main/README.md]

**Example:**

```bash
# Source: local repo + gh CLI
gh pr view 18 --repo szTheory/accrue \
  --json number,title,labels,files,body
```

### Pattern 2: Publish in Dependency Order, Not Just Version Order

**What:** Respect the workflow’s publish chain because the UI packages depend on the core package being available on Hex first. `accrue_admin` resolves `{:accrue, "~> #{@version}"}` in publish mode, and `accrue_portal` resolves `{:accrue, "== #{@version}"}` in publish mode. [VERIFIED: `accrue_admin/mix.exs`; `accrue_portal/mix.exs`]

**When to use:** Every automated publish and every manual recovery run. [VERIFIED: `.github/workflows/release-please.yml`; `.github/workflows/publish-hex.yml`; `RELEASING.md`]

**Example:**

```yaml
# Source: .github/workflows/release-please.yml
publish-accrue-admin:
  needs: [release, publish-accrue]

publish-accrue-portal:
  needs: [release, publish-accrue, publish-accrue-admin]
```

### Pattern 3: Final Proof Uses Public APIs, Not Branch Files

**What:** After publish, prove the line using tags, GitHub releases, and Hex API responses, then rerun doc/verifier lanes against the post-release docs state. Branch-local `mix.exs` and manifest alignment is only the precondition. [VERIFIED: current local verifier bundle passes while public portal release is still missing]

**When to use:** Immediately after every publish attempt and after any recovery publish. [VERIFIED: `RELEASING.md`; current registry mismatch]

**Example:**

```bash
# Source: local release-proof checks against Hex API
for pkg in accrue accrue_admin accrue_portal; do
  curl -fsSL "https://hex.pm/api/packages/${pkg}" | \
    jq '{name, latest_version, updated_at, html_url}'
done
```

### Pattern 4: Keep the Post-Publish Sweep Separate From the Publish Step

**What:** Do not conflate “workflow published packages” with “all mirrors and merge-blocking docs now tell the same truth.” Publish proof and doc-proof are separate gates. [VERIFIED: current docs/verifier state]

**When to use:** This phase specifically, because `PPX-13` and `PPX-14` are post-publish contract-sweep requirements, not release-creation requirements. [VERIFIED: `.planning/REQUIREMENTS.md`]

### Anti-Patterns to Avoid

- **Merge the stale PR without inspection:** PR `#18` omits portal, so treating “open release PR exists” as sufficient would violate the current contract. [VERIFIED: `gh pr view 18 --repo szTheory/accrue --json ...`]
- **Assume passing shell verifiers means public release truth exists:** the verifier bundle passes locally today even though `accrue_portal` is not on Hex. [VERIFIED: local verifier runs; hex.pm API `accrue_portal` 404]
- **Publish UI packages before core availability:** `accrue_admin` and `accrue_portal` release-mode dependencies point at Hex `accrue`, so publishing them before core risks an immediately broken public install path. [VERIFIED: `accrue_admin/mix.exs`; `accrue_portal/mix.exs`] 
- **Leave pair-based mirrors unreviewed because CI is green:** root/docs/host surfaces still use “pair” wording that the current verifiers do not fail on. [VERIFIED: `README.md`; `accrue/guides/first_hour.md`; `examples/accrue_host/README.md`; `examples/accrue_host/docs/adoption-proof-matrix.md`] 

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Version/changelog/tag generation | Manual version edits on `main` | Release Please PR + merge flow | Official tool already owns release PRs, version bumps, changelog sections, tags, and GitHub releases. [CITED: https://github.com/googleapis/release-please/blob/main/README.md] |
| Linked version sync | Custom sync shell script | Manifest config + `linked-versions` plugin | Official manifest docs describe the plugin specifically for keeping grouped components in sync. [CITED: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md] |
| Registry proof | Handwritten prose asserting “published” | Hex API + `gh release list` + git tags | Public APIs and tags are the authoritative post-publish proof surfaces. [VERIFIED: hex.pm APIs; `gh release list --repo szTheory/accrue`; local git tags] |
| Recovery publish logic | Ad hoc local `mix hex.publish` steps outside workflow | `.github/workflows/publish-hex.yml` + `RELEASING.md` | The repo already has an explicit recovery path with tag/version verification and dry runs. [VERIFIED: `.github/workflows/publish-hex.yml`; `RELEASING.md`] |

**Key insight:** Phase 121 should compose existing Release Please, GitHub Actions, Hex APIs, `gh`, and the bash-verifier bundle into one repeatable evidence chain; it should not invent new release infrastructure. [VERIFIED: repo release tooling; CITED: official Release Please docs]

## Common Pitfalls

### Pitfall 1: Stale `autorelease: pending` PR Blocks the Real Release

**What goes wrong:** Maintainers think the repo is “ready to merge” because a Release Please PR already exists, but the PR predates the three-package contract and does not include portal. [VERIFIED: `gh pr view 18 --repo szTheory/accrue --json ...`]

**Why it happens:** Official docs note that stale `autorelease: pending` state can prevent new release PR creation, and the current PR was created on **2026-04-28** before the Phase 120 contract lock on **2026-05-07**. [CITED: https://github.com/googleapis/release-please/blob/main/README.md] [VERIFIED: `gh pr view 18 --repo szTheory/accrue --json ...`; Phase 120 summaries]

**How to avoid:** Make “release PR file set matches the current three-package contract” the first checklist item in the plan, with an explicit rerun/refresh path if it does not. [VERIFIED: current PR/file state]

**Warning signs:** Open PR `#18`, `autorelease: pending`, portal missing from `files`, portal missing from PR body. [VERIFIED: `gh pr view 18 --repo szTheory/accrue --json ...`]

### Pitfall 2: Three-Package Contract, Pair-Based Public Mirrors

**What goes wrong:** The maintainer runbook says trio, but user-facing docs still talk about a linked core/admin pair or only pin two package versions, so the public “truth chain” is still inconsistent after publish. [VERIFIED: `README.md`; `accrue/guides/first_hour.md`; `examples/accrue_host/README.md`; `examples/accrue_host/docs/adoption-proof-matrix.md`]

**Why it happens:** Phase 120 intentionally focused on maintainer contract alignment and CI wiring, not the full post-publish doc sweep. [VERIFIED: Phase 120 plan/summaries]

**How to avoid:** Budget PPX work as explicit post-publish mirror cleanup plus reruns of the docs-contracts bundle, and consider extending verifier coverage where the current pair wording is supposed to become merge-blocking. [VERIFIED: `.planning/REQUIREMENTS.md`; `.github/workflows/ci.yml`; `scripts/ci/README.md`]

**Warning signs:** “pair,” “both packages,” or two-package `~>` guidance remains in root/host/tutorial docs after the release contract is trio. [VERIFIED: cited docs above]

### Pitfall 3: Branch Truth Mistaken for Registry Truth

**What goes wrong:** Manifest, `mix.exs`, and changelog files look correct, but one package is still unpublished or missing a tag/release. [VERIFIED: current `accrue_portal` public state]

**Why it happens:** Release Please does not publish to package managers, and passing local verifiers only proves repo-local alignment. [CITED: https://github.com/googleapis/release-please/blob/main/README.md] [VERIFIED: local verifier runs; hex.pm API `accrue_portal` 404]

**How to avoid:** Require a proof ledger with Hex API timestamps, git tags, GitHub releases, and workflow/job links for the exact shipped version. [VERIFIED: available local tooling and current mismatch]

**Warning signs:** “release created” outputs are true, but Hex API or `gh release list` does not show all intended packages at the same version. [VERIFIED: workflow design; current public state]

### Pitfall 4: Publishing UI Packages Before Core Is Publicly Installable

**What goes wrong:** A maintainer recovers or retries admin/portal publish before core is available on Hex, producing a temporarily broken install path for users. [VERIFIED: `RELEASING.md`; `.github/workflows/publish-hex.yml`; package deps]

**Why it happens:** The UI packages read `accrue` from Hex in publish mode, and portal pins `== @version`, which is stricter than admin’s `~> @version`. [VERIFIED: `accrue_admin/mix.exs`; `accrue_portal/mix.exs`]

**How to avoid:** Keep the release order and recovery order identical: `accrue` first, then `accrue_admin`, then `accrue_portal`, with a Hex availability check between steps. [VERIFIED: `.github/workflows/release-please.yml`; `.github/workflows/publish-hex.yml`; `RELEASING.md`]

**Warning signs:** Manual recovery tries `accrue_admin` or `accrue_portal` first, or skips the “Confirm Hex availability” step. [VERIFIED: `RELEASING.md`]

## Code Examples

Verified patterns from official sources and the repo’s current release tooling:

### Inspect the Current Release PR Before Merging

```bash
# Source: local repo / gh CLI
gh pr view 18 --repo szTheory/accrue \
  --json number,title,labels,files,body,mergeStateStatus
```

### Verify Registry Truth for the Linked Package Set

```bash
# Source: local repo / Hex API
for pkg in accrue accrue_admin accrue_portal; do
  curl -fsSL "https://hex.pm/api/packages/${pkg}" | \
    jq '{name, latest_version, updated_at, html_url}'
done
```

### Monorepo Output Naming When Using the Official Action

```yaml
# Source: https://github.com/googleapis/release-please-action/blob/main/README.md
if: ${{ steps.release.outputs['packages/my-module--release_created'] }}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Treat release truth as a core/admin pair in public prose | Treat release truth as a three-package contract including `accrue_portal` | Locked in Phase 120 on **2026-05-07**. [VERIFIED: Phase 120 summaries] | Phase 121 must prove portal publicly, not leave it implied in automation only. |
| Use Release Please only for tags/releases and infer package publication from branch state | Use Release Please for PR/tag/release generation, then prove registry outcomes separately | This is the documented Release Please model today. [CITED: https://github.com/googleapis/release-please/blob/main/README.md] | Publish proof must include Hex API and workflow evidence, not only changelog/manifest diffs. |
| Use `GITHUB_TOKEN` and expect downstream workflows to trigger automatically | Use a PAT-style secret when Release Please-created resources must trigger further workflows | Current action docs warn that `GITHUB_TOKEN`-created events do not trigger new workflows. [CITED: https://github.com/googleapis/release-please-action/blob/main/README.md] | Keeping `RELEASE_PLEASE_TOKEN` is the correct posture for this repo’s workflow chain. [VERIFIED: `.github/workflows/release-please.yml`; `RELEASING.md`] |

**Deprecated/outdated:**
- Treating the current open PR `#18` as authoritative for the linked release scope is outdated relative to the Phase 120 decision and current release contract. [VERIFIED: `gh pr view 18 --repo szTheory/accrue --json ...`; Phase 120 summaries]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The cleanest execution path is to refresh or replace the existing Release Please PR rather than publishing from its current contents. [ASSUMED] | Summary; Architecture Patterns | If wrong, the plan may add unnecessary PR-regeneration work instead of using a simpler portal-only remediation path. |
| A2 | A dedicated `121-VERIFICATION.md` proof ledger is the best artifact shape for Phase 121 evidence capture. [ASSUMED] | Recommended Project Structure; Validation Architecture | If wrong, the plan may create the wrong artifact location or duplicate an existing house style. |

## Open Questions (RESOLVED)

1. **Phase 121 will ship a new synchronized trio line, expected to be `1.0.1`, not a portal-only `1.0.0` catch-up.**
   - Decision: treat the stale pair-only PR as invalid and refresh or replace it until the release artifact represents one linked three-package line for `accrue`, `accrue_admin`, and `accrue_portal`. [VERIFIED: Phase 120 summaries; current PR `#18`; current registry state]
   - Why: REL-10 and REL-11 are about the next public linked release landing honestly. A portal-only late `1.0.0` would repair one missing package, but it would leave the current open release PR, changelog flow, and linked-version proof chain split across two public stories. [VERIFIED: requirements shape; current PR mismatch]
   - Execution implication: Plan and verification must bind to the specific refreshed release PR and the exact trio version it produces. If Release Please computes a trio version other than `1.0.1`, execution should use that exact linked version consistently across proof capture rather than forcing a hard-coded number. [VERIFIED: Release Please ownership model]

2. **Phase 121 should extend verifier coverage to fail the remaining pair-based public mirrors.**
   - Decision: yes. PPX-13 and PPX-14 require post-publish docs and proof mirrors to tell the same three-package truth as the shipped line, and the remaining pair-only surfaces are not intentional exceptions. [VERIFIED: `.planning/REQUIREMENTS.md`; cited docs]
   - Execution implication: the docs update and verifier-needle update must happen in the same plan so the shift-left bundle becomes trio-honest immediately after publish. [VERIFIED: current verifier gap]

3. **The canonical release-proof artifact for this phase is `.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md`.**
   - Decision: use one append-only verification ledger with fixed sections for release PR evidence, publish-run evidence, public registry proof, touched mirror notes, and post-publish verifier reruns. [VERIFIED: current artifact inventory; Phase 121 planning needs]
   - Why: Phase 120 already used per-plan summaries, but this phase needs a single ordered proof chain that spans multiple plans and live publish events. A shared verification ledger is the smallest repo-consistent artifact that keeps the evidence deterministic and reviewable. [VERIFIED: Phase 120 artifact style; Phase 121 proof needs]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `gh` | PR/release/workflow evidence capture | ✓ | `2.89.0` | `curl` GitHub API, but worse ergonomics. [VERIFIED: local env `gh version 2.89.0`; local `gh auth status`] |
| `jq` | Manifest/API parsing | ✓ | `1.7.1` | `node`/shell parsing, but not recommended. [VERIFIED: local env `jq-1.7.1-apple`] |
| `node` / `npm` / `npx` | Release Please CLI | ✓ | `v22.14.0` / `11.1.0` / `11.1.0` | None needed; local workflow already uses `npx`. [VERIFIED: local env versions] |
| Elixir / Mix | Hex dry runs and verifier commands | ✓ | `1.19.5` / `1.19.5` | CI runners also cover supported lower versions. [VERIFIED: local env `elixir -v`; local env `mix --version`; `.github/workflows/ci.yml`] |
| `curl` | Hex API proof | ✓ | `8.7.1` | `gh api` or browser, but `curl` is simplest. [VERIFIED: local env `curl 8.7.1`] |
| GitHub auth | `gh` release/PR/check inspection | ✓ | account `szTheory` active | Browser UI only. [VERIFIED: local `gh auth status`] |

**Missing dependencies with no fallback:**
- None. [VERIFIED: local env audit]

**Missing dependencies with fallback:**
- None. [VERIFIED: local env audit]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Bash verifier bundle + GitHub Actions release/docs lanes + ExUnit-backed host/package suites. [VERIFIED: `.github/workflows/ci.yml`; `scripts/ci/README.md`] |
| Config file | `.github/workflows/ci.yml` plus package `mix.exs` alias/test config. [VERIFIED: `.github/workflows/ci.yml`; package `mix.exs` files] |
| Quick run command | `bash scripts/ci/verify_release_manifest_alignment.sh && bash scripts/ci/verify_release_contract.sh && bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_adoption_proof_matrix.sh` [VERIFIED: local run passed on 2026-05-07] |
| Full suite command | `bash scripts/ci/verify_release_manifest_alignment.sh && bash scripts/ci/verify_release_contract.sh && bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_verify01_readme_contract.sh && bash scripts/ci/verify_production_readiness_discoverability.sh && bash scripts/ci/verify_adoption_proof_matrix.sh && bash scripts/ci/verify_core_admin_invoice_verify_ids.sh && bash scripts/ci/accrue_host_uat.sh` [VERIFIED: `.github/workflows/ci.yml`; `scripts/ci/README.md`] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REL-10 | All linked packages ship with matching version, tag, GitHub release, and changelog truth | release-proof + API check | `for pkg in accrue accrue_admin accrue_portal; do curl -fsSL "https://hex.pm/api/packages/${pkg}" | jq '{name, latest_version, updated_at}'; git tag --list "${pkg}-v$V"; done && gh release list --repo szTheory/accrue --limit 20` | ❌ Wave 0 |
| REL-11 | Ordered publish proof exists for `accrue -> accrue_admin -> accrue_portal` | workflow evidence | `gh run list --repo szTheory/accrue --workflow 'Release Please' --branch main --limit 1 && gh run view "$RUN_ID" --repo szTheory/accrue --json jobs` | ❌ Wave 0 |
| PPX-13 | Package docs/install literals reflect published truth and package docs verifier passes | bash contract | `bash scripts/ci/verify_package_docs.sh` | ✅ |
| PPX-14 | Adoption matrix and docs-contracts bundle pass against the post-release docs state | bash contract bundle | `bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_verify01_readme_contract.sh && bash scripts/ci/verify_production_readiness_discoverability.sh && bash scripts/ci/verify_adoption_proof_matrix.sh && bash scripts/ci/verify_core_admin_invoice_verify_ids.sh` | ✅ |

### Sampling Rate

- **Per task commit:** `bash scripts/ci/verify_release_manifest_alignment.sh && bash scripts/ci/verify_release_contract.sh`
- **Per wave merge:** `bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_adoption_proof_matrix.sh`
- **Phase gate:** Full release-proof ledger + full docs-contracts bundle + host verification green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] No dedicated scripted proof command exists yet for `REL-10` that converts a target version into a single pass/fail check across Hex API, git tags, GitHub releases, and changelog surfaces. [VERIFIED: current script inventory]
- [ ] No dedicated scripted proof command exists yet for `REL-11` that captures publish-job ordering from the actual release workflow run into a deterministic artifact. [VERIFIED: current script inventory]
- [ ] Current docs verifiers do not fail the remaining pair-based truth surfaces in `README.md`, `accrue/guides/first_hour.md`, `examples/accrue_host/README.md`, and `examples/accrue_host/docs/adoption-proof-matrix.md`. [VERIFIED: cited docs; local verifier runs]
- [ ] No current gate checks that the open Release Please PR file set includes all three linked packages before merge. [VERIFIED: `gh pr view 18 --repo szTheory/accrue --json ...`; current script inventory]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | GitHub Actions auth via `RELEASE_PLEASE_TOKEN` / `HEX_API_KEY` secrets and authenticated `gh` access for maintainer evidence capture. [VERIFIED: `.github/workflows/release-please.yml`; `RELEASING.md`; local `gh auth status`] |
| V3 Session Management | no | Release work is not web-session management. [VERIFIED: phase scope] |
| V4 Access Control | yes | Branch protection, manual review of release PRs, and explicit `workflow_dispatch` for release PR auto-merge / recovery publish. [VERIFIED: `RELEASING.md`; `.github/workflows/release-pr-automation.yml`; `.github/workflows/publish-hex.yml`] |
| V5 Input Validation | yes | Manual recovery validates `tag` and `release_version` against package `mix.exs`, and verifiers use fixed-string/regex checks to reject contract drift. [VERIFIED: `.github/workflows/publish-hex.yml`; `scripts/ci/verify_release_contract.sh`; `scripts/ci/verify_release_manifest_alignment.sh`] |
| V6 Cryptography | yes | Secret handling relies on GitHub Actions secrets and Hex/GitHub token infrastructure; no custom crypto should be introduced. [VERIFIED: `RELEASING.md`; workflow secret usage] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Wrong-ref manual publish | Tampering | Require explicit `tag` + `release_version` verification in `.github/workflows/publish-hex.yml` before `mix hex.publish --yes`. [VERIFIED: `.github/workflows/publish-hex.yml`] |
| Secret leakage in release artifacts or logs | Information Disclosure | Keep `HEX_API_KEY` and `RELEASE_PLEASE_TOKEN` as secret names only; never print values in docs, scripts, or workflow logs. [VERIFIED: `RELEASING.md`; workflow env usage] |
| Partial linked release with missing downstream package | Repudiation / Tampering | Record tags, GitHub releases, Hex API responses, and job ordering in one dated proof ledger; do not rely on branch-local state. [VERIFIED: current public mismatch; current workflow structure] |
| Untrusted branch assumptions controlling publish order | Elevation of Privilege / Tampering | Keep publish jobs gated by same-workflow outputs and explicit `needs:` chains, not arbitrary branch state. [VERIFIED: `.github/workflows/release-please.yml`] |

## Sources

### Primary (HIGH confidence)

- Repo files at current checkout:
  - `RELEASING.md`
  - `release-please-config.json`
  - `.release-please-manifest.json`
  - `.github/workflows/release-please.yml`
  - `.github/workflows/publish-hex.yml`
  - `.github/workflows/ci.yml`
  - `scripts/ci/verify_release_contract.sh`
  - `scripts/ci/verify_release_manifest_alignment.sh`
  - `scripts/ci/verify_package_docs.sh`
  - `scripts/ci/verify_adoption_proof_matrix.sh`
  - `README.md`
  - `accrue/guides/first_hour.md`
  - `examples/accrue_host/README.md`
  - `examples/accrue_host/docs/adoption-proof-matrix.md`
  - `accrue/mix.exs`
  - `accrue_admin/mix.exs`
  - `accrue_portal/mix.exs`
- Official Release Please docs:
  - https://github.com/googleapis/release-please/blob/main/README.md
  - https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md
- Official Release Please Action docs:
  - https://github.com/googleapis/release-please-action/blob/main/README.md
- Public registries / APIs:
  - https://hex.pm/api/packages/accrue
  - https://hex.pm/api/packages/accrue_admin
  - https://hex.pm/api/packages/accrue_portal
  - https://hex.pm/docs/faq
  - npm registry via `npm view release-please version time --json`
- Live GitHub repo state:
  - `gh pr view 18 --repo szTheory/accrue --json ...`
  - `gh pr checks 18 --repo szTheory/accrue`
  - `gh release list --repo szTheory/accrue`

### Secondary (MEDIUM confidence)

- None. Most critical claims were verified directly from official docs, public APIs, or repo state. [VERIFIED: research record]

### Tertiary (LOW confidence)

- None. [VERIFIED: research record]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions, tooling, and workflow ownership were verified from current repo files, local environment, npm registry, and official Release Please docs.
- Architecture: HIGH - publish order, dependency rationale, and proof boundaries were verified from live workflows, package `mix.exs` files, and current public registry state.
- Pitfalls: HIGH - the stale open release PR, missing public portal release, and pair-based mirror drift were all verified directly in the current repo and GitHub/Hex state.

**Research date:** 2026-05-07
**Valid until:** 2026-05-14
