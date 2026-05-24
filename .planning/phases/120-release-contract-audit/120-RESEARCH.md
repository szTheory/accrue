# Phase 120: Release Contract Audit - Research

**Researched:** 2026-05-07
**Domain:** Release automation, package publish contract, maintainer runbook alignment
**Confidence:** HIGH

<user_constraints>
## User Constraints

No phase-specific `*-CONTEXT.md` file exists for Phase 120. [VERIFIED: `.planning/phases/120-release-contract-audit/`]

Use the active phase requirements and milestone framing as the binding scope:
- `REL-09`: the maintainer path across `RELEASING.md`, `release-please-config.json`, `.release-please-manifest.json`, and `.github/workflows/release-please.yml` must be unambiguous about participating packages, publish order, and proof. [VERIFIED: `.planning/REQUIREMENTS.md`]
- `PPX-15`: the release narrative must explicitly resolve whether `accrue_portal` is part of the linked release contract or should be removed from linked-version automation. [VERIFIED: `.planning/REQUIREMENTS.md`]
- Success criteria require the runbook, config, manifest, and workflow to stop contradicting each other about linked package scope and publish order. [VERIFIED: `.planning/ROADMAP.md`]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REL-09 | A maintainer can follow the runbook, config, manifest, and workflow without ambiguity about package set, publish order, and proof. | Sections: Summary, Architectural Responsibility Map, Standard Stack, Architecture Patterns, Common Pitfalls, Validation Architecture. |
| PPX-15 | The release narrative explicitly resolves the current `accrue_portal` package-set reality. | Sections: Summary, Standard Stack, Architecture Patterns, Open Questions, Validation Architecture. |
</phase_requirements>

## Summary

The repo currently has a three-package release automation contract but a two-package maintainer narrative. `release-please-config.json`, `.release-please-manifest.json`, and `.github/workflows/release-please.yml` all include `accrue_portal`, while `RELEASING.md` still describes recurring linked releases as `accrue` + `accrue_admin`, its checklist names only those two packages, and the manual recovery workflow only supports those two packages. [VERIFIED: `release-please-config.json`; `.release-please-manifest.json`; `.github/workflows/release-please.yml`; `RELEASING.md`; `.github/workflows/publish-hex.yml`]

Public release reality is also asymmetric today. Hex shows `accrue` at `1.0.0` updated on 2026-04-28 and `accrue_admin` at `1.0.0` updated on 2026-04-28, but `https://hex.pm/api/packages/accrue_portal` returns `404`, and this checkout has no `accrue_portal-v*` git tags. That means the planner should treat the `accrue_portal` question as a real contract decision, not a wording cleanup. [VERIFIED: hex.pm API `https://hex.pm/api/packages/accrue`; VERIFIED: hex.pm API `https://hex.pm/api/packages/accrue_admin`; VERIFIED: hex.pm API `https://hex.pm/api/packages/accrue_portal`; VERIFIED: git tags `accrue_portal*`]

Release Please itself is not the owner of publish order. Official docs say Release Please creates release PRs, version bumps, tags, and GitHub releases, while package-manager publication is separate; the `linked-versions` plugin only keeps selected components on the same version. In this repo, publish sequencing is a custom GitHub Actions policy layered on top: `accrue` publishes first, then `accrue_admin`, then `accrue_portal`. [CITED: https://github.com/googleapis/release-please/blob/main/README.md] [CITED: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md] [VERIFIED: `.github/workflows/release-please.yml`]

**Primary recommendation:** Plan Phase 120 around one first task: explicitly choose whether the linked release scope is `{accrue, accrue_admin}` or `{accrue, accrue_admin, accrue_portal}`, then make every contract surface and verifier reflect only that choice. [VERIFIED: `RELEASING.md`; `release-please-config.json`; `.release-please-manifest.json`; `.github/workflows/release-please.yml`; `.github/workflows/publish-hex.yml`]

## Project Constraints (from CLAUDE.md)

- Tech floor is Elixir `1.17+`, OTP `27+`, Phoenix `1.8+`, Ecto `3.12+`, PostgreSQL `14+`; no legacy OTP support. [VERIFIED: `CLAUDE.md`]
- The repo is a monorepo with sibling Mix projects and shared workflow/docs infrastructure. `CLAUDE.md` still describes `accrue/` and `accrue_admin/` as the monorepo baseline, so any planner recommendation that now includes `accrue_portal` should treat that as a release-contract update that needs explicit mirror work. [VERIFIED: `CLAUDE.md`; `accrue_portal/mix.exs`]
- Release posture is “ship complete,” not open-ended public `0.x` iteration. [VERIFIED: `CLAUDE.md`]
- Security posture requires non-bypassable webhook verification, no sensitive Stripe field logging, and no payment-method PII storage; release docs must not weaken that language. [VERIFIED: `CLAUDE.md`; `RELEASING.md`]
- Observability is part of the public contract; release docs and proof lanes should keep telemetry-facing language honest. [VERIFIED: `CLAUDE.md`]
- Repo workflow guidance says file-changing work should normally flow through GSD commands so planning artifacts stay in sync. [VERIFIED: `CLAUDE.md`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Linked package scope SSOT | Repo source | Maintainer docs | The scope decision lives first in config/manifest/workflow files, then must be narrated consistently in the runbook. [VERIFIED: `release-please-config.json`; `.release-please-manifest.json`; `.github/workflows/release-please.yml`; `RELEASING.md`] |
| Version linking | Release Please manifest/config | Repo source | `linked-versions` is configured in `release-please-config.json`, and the manifest stores current package versions. [CITED: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md] [VERIFIED: `release-please-config.json`; `.release-please-manifest.json`] |
| Publish ordering | CI / automation | Package dependency graph | Release Please does not publish to registries; GitHub Actions jobs enforce the repo’s publish order. [CITED: https://github.com/googleapis/release-please/blob/main/README.md] [VERIFIED: `.github/workflows/release-please.yml`; `accrue_admin/mix.exs`; `accrue_portal/mix.exs`] |
| Release proof | Package registry | CI / automation | Final truth is Hex package existence/version plus workflow evidence and tags. [VERIFIED: hex.pm API `https://hex.pm/api/packages/accrue`; VERIFIED: hex.pm API `https://hex.pm/api/packages/accrue_admin`; VERIFIED: `.github/workflows/release-please.yml`] |
| Recovery path | CI / automation | Maintainer docs | Manual recovery is encoded in `.github/workflows/publish-hex.yml` and explained in `RELEASING.md`; both must cover the same package set. [VERIFIED: `.github/workflows/publish-hex.yml`; `RELEASING.md`] |
| Drift detection | Bash verifiers | CI / automation | Existing shell scripts and CI jobs catch some release drift, but they do not currently cover the full three-package contract. [VERIFIED: `scripts/ci/verify_release_manifest_alignment.sh`; `scripts/ci/verify_package_docs.sh`; `.github/workflows/ci.yml`] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `release-please` | `17.6.0` | Release PRs, changelog sections, tags, GitHub releases | Already pinned in the workflow, and `17.6.0` is the current npm version published on 2026-04-13. [VERIFIED: npm registry] [VERIFIED: `.github/workflows/release-please.yml`] |
| GitHub Actions workflow | `ubuntu-24.04` runners + `actions/checkout@v6` + `erlef/setup-beam@v1` | Release orchestration and Hex publishing | This repo already encodes the release path here; Phase 120 should align contracts around it instead of introducing a second mechanism. [VERIFIED: `.github/workflows/release-please.yml`; `.github/workflows/publish-hex.yml`] |
| Release Please manifest mode | current repo config | Multi-package monorepo release coordination | Official docs recommend manifest configuration for advanced multi-package setups. [CITED: https://github.com/googleapis/release-please-action] [VERIFIED: `release-please-config.json`; `.release-please-manifest.json`] |
| `linked-versions` plugin | current repo config | Lock selected components to one version line | Official docs say it synchronizes versions across configured components, but not publish order or dependency updates. [CITED: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md] [VERIFIED: `release-please-config.json`] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `jq` | `1.7.1` | Read manifest values in scripts/workflows | Required by current workflow logic and the manifest-alignment verifier. [VERIFIED: local env `jq-1.7.1-apple`; VERIFIED: `scripts/ci/verify_release_manifest_alignment.sh`; `.github/workflows/release-please.yml`] |
| `gh` | `2.89.0` | Check releases, queue release PR auto-merge | Used by the release workflow and `release-pr-automation.yml`; locally authenticated in this checkout. [VERIFIED: local env `gh version 2.89.0`; VERIFIED: local `gh auth status`; VERIFIED: `.github/workflows/release-please.yml`; `.github/workflows/release-pr-automation.yml`] |
| Elixir / Mix | `1.19.5` | `mix deps.get`, `mix hex.publish`, dry runs | Required for all publish jobs and recovery jobs. [VERIFIED: local env `elixir 1.19.5`; VERIFIED: `.github/workflows/release-please.yml`; `.github/workflows/publish-hex.yml`] |
| Hex.pm API | current public registry | Prove current published package truth | Best source for post-publish verification and for the current `accrue_portal` truth check. [VERIFIED: hex.pm API `https://hex.pm/api/packages/accrue`; VERIFIED: hex.pm API `https://hex.pm/api/packages/accrue_admin`; VERIFIED: hex.pm API `https://hex.pm/api/packages/accrue_portal`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Raw `npx release-please` CLI in workflow | `googleapis/release-please-action@v4` | The action has documented monorepo outputs, but this repo already relies on custom `jq` + `gh release view` logic and custom fallback writes to `$GITHUB_OUTPUT`; switching mechanisms would expand scope. [CITED: https://github.com/googleapis/release-please-action] [VERIFIED: `.github/workflows/release-please.yml`] |
| Three-package linked scope | Two-package linked scope | Narrowing to `{accrue, accrue_admin}` would match today’s runbook, manual recovery path, and historical paired proof, but would require removing portal from config/manifest/workflow. Keeping three packages would require documenting and proving portal honestly everywhere. [VERIFIED: `RELEASING.md`; `release-please-config.json`; `.release-please-manifest.json`; `.github/workflows/release-please.yml`; `.github/workflows/publish-hex.yml`; `.planning/REQUIREMENTS.md`] |
| Current `accrue -> admin -> portal` publish order | `accrue -> {admin, portal}` after core | `accrue_portal` only depends on `accrue`, not `accrue_admin`, so the current serial order is conservative policy rather than a dependency requirement. Changing it would be a phase-level policy decision, not a correctness fix. [VERIFIED: `accrue_admin/mix.exs`; `accrue_portal/mix.exs`; `.github/workflows/release-please.yml`] |

**Installation:**  
The repo does not install Release Please as a project dependency; the workflow executes it via `npx`. [VERIFIED: `.github/workflows/release-please.yml`]

```bash
npx --yes release-please@17.6.0 release-pr \
  --config-file release-please-config.json \
  --manifest-file .release-please-manifest.json
```

**Version verification:** `npm view release-please version` returned `17.6.0`, with publish time `2026-04-13T21:15:22.890Z`. [VERIFIED: npm registry]

## Architecture Patterns

### System Architecture Diagram

```text
merged commit on main
  ->
GitHub Actions: release-please.yml
  ->
release job
  -> reads release-please-config.json + .release-please-manifest.json
  -> runs release-please CLI
  -> creates/updates GitHub Release PRs
  -> creates GitHub releases/tags
  -> writes custom per-package outputs
  ->
publish jobs
  -> publish accrue first
  -> publish accrue_admin if enabled and core publish succeeded
  -> publish accrue_portal if enabled and upstream jobs succeeded
  ->
Hex registry truth
  -> package versions visible on hex.pm
  ->
post-publish proof
  -> runbook checklist
  -> bash verifiers / CI jobs
  -> planning mirrors in later phases
```

The important design boundary is that Release Please owns release PRs, tags, changelog generation, and GitHub releases, while the workflow owns package publication and sequencing. [CITED: https://github.com/googleapis/release-please/blob/main/README.md] [VERIFIED: `.github/workflows/release-please.yml`]

### Recommended Project Structure

```text
repo root
├── RELEASING.md                         # maintainer narrative and checklist
├── release-please-config.json          # linked scope and package metadata
├── .release-please-manifest.json       # current package versions
├── .github/workflows/release-please.yml # automated release + publish path
├── .github/workflows/publish-hex.yml   # recovery/manual publish path
└── scripts/ci/
    ├── verify_release_manifest_alignment.sh
    ├── verify_package_docs.sh
    └── verify_adoption_proof_matrix.sh
```

### Pattern 1: Decide Release Scope Once, Then Mirror It Everywhere

**What:** Treat “which packages participate in the linked public release” as the top-level decision, then update runbook, config, manifest, workflow, recovery path, and verifier scope in the same change set. [VERIFIED: `RELEASING.md`; `release-please-config.json`; `.release-please-manifest.json`; `.github/workflows/release-please.yml`; `.github/workflows/publish-hex.yml`]

**When to use:** Any time a package is added to or removed from linked-version automation. [VERIFIED: `.planning/REQUIREMENTS.md`; `.planning/STATE.md`]

**Example:**

```json
// Source: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md
{
  "plugins": [
    {
      "type": "linked-versions",
      "groupName": "accrue-monorepo",
      "components": ["accrue", "accrue_admin", "accrue_portal"]
    }
  ]
}
```

### Pattern 2: Keep Version Linking Separate From Publish Ordering

**What:** Let the manifest/plugin define which components share a version, and let the workflow define dependency-safe publish order. [CITED: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md] [CITED: https://github.com/googleapis/release-please/blob/main/README.md] [VERIFIED: `.github/workflows/release-please.yml`]

**When to use:** Multi-package repos where one package depends on another at publish time. [VERIFIED: `accrue_admin/mix.exs`; `accrue_portal/mix.exs`]

**Example:**

```yaml
# Source: .github/workflows/release-please.yml
publish-accrue-admin:
  needs: [release, publish-accrue]

publish-accrue-portal:
  needs: [release, publish-accrue, publish-accrue-admin]
```

### Pattern 3: Proof Uses Registry Reality, Not Branch Assumptions

**What:** After publish, verify packages via Hex and tags rather than assuming manifest values imply successful release. [VERIFIED: hex.pm API `https://hex.pm/api/packages/accrue`; VERIFIED: hex.pm API `https://hex.pm/api/packages/accrue_admin`; VERIFIED: git tags `accrue*`; VERIFIED: git tags `accrue_admin*`; VERIFIED: git tags `accrue_portal*`]

**When to use:** Every public release and especially any recovery run. [VERIFIED: `RELEASING.md`; `.github/workflows/publish-hex.yml`]

**Example:**

```bash
# Source: local verification against hex.pm API
curl -fsSL https://hex.pm/api/packages/accrue | jq '{name, latest_version, updated_at}'
curl -fsSL https://hex.pm/api/packages/accrue_admin | jq '{name, latest_version, updated_at}'
curl -fsSL https://hex.pm/api/packages/accrue_portal | jq '{name, latest_version, updated_at}'
```

### Anti-Patterns to Avoid

- **Automation-only truth:** Do not leave `accrue_portal` implied only in config/workflow while the human runbook still says the linked release is only core + admin. [VERIFIED: `RELEASING.md`; `release-please-config.json`; `.github/workflows/release-please.yml`]
- **Assuming linked-versions implies dependency order:** Official docs only promise synchronized versions, not publish sequencing. [CITED: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md]
- **Two-path drift:** Do not update `.github/workflows/release-please.yml` without also updating `.github/workflows/publish-hex.yml`, because recovery becomes dishonest immediately. [VERIFIED: `.github/workflows/release-please.yml`; `.github/workflows/publish-hex.yml`]
- **Verifier blind spot acceptance:** Do not leave `verify_release_manifest_alignment.sh` and `verify_package_docs.sh` unaware of portal if portal remains in the linked public contract. [VERIFIED: `scripts/ci/verify_release_manifest_alignment.sh`; `scripts/ci/verify_package_docs.sh`] 

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Monorepo version lockstep | Custom version-sync script | Release Please manifest + `linked-versions` plugin | Official plugin already solves “keep these components on one version.” [CITED: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md] |
| GitHub release/tag generation | Ad hoc tag/changelog shell scripts | Release Please CLI | Official tool already owns changelog sections, tags, and GitHub releases. [CITED: https://github.com/googleapis/release-please/blob/main/README.md] |
| Publish-proof inference | “Manifest says 1.0.0, so it shipped” | Hex API / Hex package pages / tags | This repo already shows why branch-local truth can diverge from public truth. [VERIFIED: hex.pm API `https://hex.pm/api/packages/accrue_portal`; VERIFIED: `.release-please-manifest.json`] |
| PR auto-merge on release branches | `pull_request`-triggered merge automation | Maintainer-dispatched `release-pr-automation.yml` | Existing repo policy is intentionally human-gated. [VERIFIED: `.github/workflows/release-pr-automation.yml`; `RELEASING.md`] |

**Key insight:** Phase 120 should compose existing Release Please, Hex, `gh`, and verifier primitives into one honest contract, not introduce new release infrastructure. [VERIFIED: repo release files; CITED: official Release Please docs]

## Common Pitfalls

### Pitfall 1: Three-Package Automation, Two-Package Runbook

**What goes wrong:** Maintainers follow `RELEASING.md` and believe only `accrue` and `accrue_admin` are linked, while automation may create or attempt to publish portal artifacts too. [VERIFIED: `RELEASING.md`; `release-please-config.json`; `.github/workflows/release-please.yml`]

**Why it happens:** The portal package was added to linked-version automation and publish jobs, but the runbook, checklist, and recovery workflow were not fully updated. [VERIFIED: `release-please-config.json`; `.release-please-manifest.json`; `.github/workflows/release-please.yml`; `.github/workflows/publish-hex.yml`; `RELEASING.md`]

**How to avoid:** Make release scope an explicit locked decision and then update all narrative, workflow, manifest, and recovery surfaces in one PR. [VERIFIED: `.planning/REQUIREMENTS.md`]

**Warning signs:** References to “both packages,” “two packages,” or “paired release” remain after portal is still present in config/manifest/workflow. [VERIFIED: `RELEASING.md`; `scripts/ci/verify_adoption_proof_matrix.sh`]

### Pitfall 2: Treating Publish Order As If Release Please Owns It

**What goes wrong:** Maintainers over-trust Release Please to infer dependency-safe registry ordering. [CITED: https://github.com/googleapis/release-please/blob/main/README.md]

**Why it happens:** Release Please and publish workflow concerns are conceptually adjacent, but the official tool boundary stops before package-manager publication. [CITED: https://github.com/googleapis/release-please/blob/main/README.md]

**How to avoid:** Keep publish order documented as a workflow contract, with rationale tied to Mix dependencies. [VERIFIED: `accrue_admin/mix.exs`; `accrue_portal/mix.exs`; `.github/workflows/release-please.yml`]

**Warning signs:** Runbook language says “Release Please publishes” instead of “the workflow publishes after Release Please creates releases.” [VERIFIED: `RELEASING.md`; `.github/workflows/release-please.yml`]

### Pitfall 3: Recovery Path Drift

**What goes wrong:** The happy path can publish portal, but manual fallback cannot recover it. [VERIFIED: `.github/workflows/release-please.yml`; `.github/workflows/publish-hex.yml`]

**Why it happens:** Recovery workflow inputs still only offer `accrue` and `accrue_admin`. [VERIFIED: `.github/workflows/publish-hex.yml`]

**How to avoid:** Keep fallback workflow scope identical to primary workflow scope, or explicitly document that portal is excluded from linked release truth. [VERIFIED: `.planning/REQUIREMENTS.md`]

**Warning signs:** Runbook says “manual fallback” without enumerating the same package set as the primary workflow. [VERIFIED: `RELEASING.md`; `.github/workflows/publish-hex.yml`]

### Pitfall 4: Verifier Coverage Stops At The Old Pair

**What goes wrong:** CI still passes even though portal-related release truth is drifting. [VERIFIED: `scripts/ci/verify_release_manifest_alignment.sh`; `scripts/ci/verify_package_docs.sh`; `.github/workflows/ci.yml`]

**Why it happens:** `verify_release_manifest_alignment.sh` checks only `accrue` and `accrue_admin`, and `verify_package_docs.sh` likewise reasons about the old pair. [VERIFIED: `scripts/ci/verify_release_manifest_alignment.sh`; `scripts/ci/verify_package_docs.sh`]

**How to avoid:** Extend an existing verifier or add a dedicated release-contract verifier that covers chosen package scope, publish order wording, recovery path scope, and proof checklist literals. [VERIFIED: existing verifier scripts]

**Warning signs:** CI is green while the runbook and workflow disagree about package scope. [VERIFIED: `RELEASING.md`; `.github/workflows/release-please.yml`; `.github/workflows/ci.yml`]

## Code Examples

Verified patterns from official sources and the repo:

### Manifest-mode multi-package configuration

```json
// Source: https://github.com/googleapis/release-please-action
{
  "config-file": "release-please-config.json",
  "manifest-file": ".release-please-manifest.json"
}
```

### Linked versions plugin

```json
// Source: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md
{
  "plugins": [
    {
      "type": "linked-versions",
      "groupName": "my group",
      "components": ["pkgA", "pkgB"]
    }
  ]
}
```

### Repo’s dependency-switched Hex publish pattern

```elixir
// Source: accrue_admin/mix.exs
defp accrue_dep do
  if System.get_env("ACCRUE_ADMIN_HEX_RELEASE") == "1" do
    {:accrue, "~> #{@version}"}
  else
    {:accrue, path: "../accrue"}
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Two-package linked release story (`accrue` + `accrue_admin`) | Three-package linked-version automation including `accrue_portal` | Portal package work shipped by v1.33; active mismatch is documented in v1.38 planning on 2026-05-07. [VERIFIED: `.planning/research/v1.33-PHASE-101-A-PORTAL-PACKAGE-HOME-ADVISOR.md`; `.planning/ROADMAP.md`; `.planning/STATE.md`] | Phase 120 must either promote portal into the release contract everywhere or remove it from automation. |
| Manual release proof inferred from repo files | Workflow-driven publish jobs plus registry proof | Existing workflow and Hex evidence are already the operative mechanism. [VERIFIED: `.github/workflows/release-please.yml`; hex.pm API] | Planner should prioritize proof-chain alignment, not new release tooling. |
| Pair-only recovery workflow | Incomplete against current automation scope | Current as of 2026-05-07. [VERIFIED: `.github/workflows/publish-hex.yml`; `.github/workflows/release-please.yml`] | Recovery is not trustworthy unless scope is reconciled. |

**Deprecated/outdated:**
- Two-package wording in `RELEASING.md` is outdated if portal remains in the linked release scope. [VERIFIED: `RELEASING.md`; `release-please-config.json`]
- Pair-only `verify_release_manifest_alignment.sh` is outdated if portal remains in the linked release scope. [VERIFIED: `scripts/ci/verify_release_manifest_alignment.sh`; `release-please-config.json`]
- Pair-only manual recovery in `.github/workflows/publish-hex.yml` is outdated if portal remains in the linked release scope. [VERIFIED: `.github/workflows/publish-hex.yml`; `.github/workflows/release-please.yml`]

## Assumptions Log

All material claims in this research were verified in-session or cited from official docs. No user-confirmation assumptions remain.

## Open Questions (RESOLVED)

1. **Is `accrue_portal` intentionally part of the next linked public release?**
   - What we know: It is in the linked-versions plugin, in the manifest at `1.0.0`, and in the automated publish workflow. [VERIFIED: `release-please-config.json`; `.release-please-manifest.json`; `.github/workflows/release-please.yml`]
   - What was unclear: The runbook, checklist, recovery path, and current public registry do not yet tell the same story. [VERIFIED: `RELEASING.md`; `.github/workflows/publish-hex.yml`; hex.pm API `https://hex.pm/api/packages/accrue_portal`]
   - **Resolution for planning:** Treat this as a required maintainer checkpoint, not an implicit research assumption. Plan `120-01` must force an explicit tokenized choice between `narrow-two-package` and `promote-three-package`, and Plans `120-02` and `120-03` must implement and enforce only the chosen scope. [VERIFIED: `.planning/REQUIREMENTS.md`; `.planning/phases/120-release-contract-audit/120-01-PLAN.md`]

2. **If portal stays in scope, should publish order remain `accrue -> accrue_admin -> accrue_portal`?**
   - What we know: `accrue_admin` and `accrue_portal` both depend on `accrue`; portal does not depend on admin. [VERIFIED: `accrue_admin/mix.exs`; `accrue_portal/mix.exs`]
   - What was unclear: Whether admin-before-portal is a trust/readability choice, or whether the repo wants to relax it to a simpler “core first, UI packages after” model. [VERIFIED: `.github/workflows/release-please.yml`]
   - **Resolution for planning:** Preserve the current publish order as the default contract if portal remains in scope. Phase 120 is a truth-alignment phase, not an order-optimization phase, so any ordering change would require a separate explicit maintainer decision outside this plan set. [VERIFIED: current workflow; `.planning/ROADMAP.md`]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | `npx release-please` in release workflow logic | ✓ | `v22.14.0` | — |
| npm | Release Please package resolution | ✓ | `11.1.0` | — |
| `gh` CLI | Release existence checks and release PR auto-merge workflow | ✓ | `2.89.0` | Manual GitHub UI checks/merge |
| `jq` | Manifest parsing in workflow and verifier | ✓ | `1.7.1` | none practical |
| Elixir | `mix deps.get`, `mix hex.publish`, local validation | ✓ | `1.19.5` | — |
| Mix | Publish and dry-run commands | ✓ | available with local Elixir install | — |
| Hex registry | Public release truth checks | ✓ | live API reachable | Package pages in browser |
| GitHub auth | Local maintainer helpers using `gh` | ✓ | authenticated as `szTheory` | GitHub web UI |
| GitHub Actions secrets `RELEASE_PLEASE_TOKEN`, `HEX_API_KEY` | Remote release workflow | ? | not locally inspectable | none |

**Missing dependencies with no fallback:**
- None on the local machine for planning research. [VERIFIED: local env probes]

**Missing dependencies with fallback:**
- GitHub Actions secrets are not locally inspectable, but the planner can assume they remain a remote prerequisite and keep secret verification as checklist work rather than local automation. [VERIFIED: `RELEASING.md`; `.github/workflows/release-please.yml`]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Bash verifier scripts + GitHub Actions YAML contracts [VERIFIED: `scripts/ci/*.sh`; `.github/workflows/ci.yml`] |
| Config file | none centralized; scripts are invoked directly from `.github/workflows/ci.yml` [VERIFIED: `.github/workflows/ci.yml`] |
| Quick run command | `bash scripts/ci/verify_release_manifest_alignment.sh && bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_adoption_proof_matrix.sh` [VERIFIED: existing scripts] |
| Full suite command | `bash scripts/ci/verify_release_manifest_alignment.sh && bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_adoption_proof_matrix.sh` plus release-workflow review and any new release-contract verifier added by this phase [VERIFIED: `.github/workflows/ci.yml`] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REL-09 | Runbook/config/manifest/workflow agree on participating package set and publish order | bash contract + review | `bash scripts/ci/verify_release_manifest_alignment.sh` plus a new or extended release-contract verifier | ❌ Wave 0 |
| PPX-15 | `accrue_portal` truth is explicit, not implicit in automation only | bash contract + registry check | `curl -fsSL https://hex.pm/api/packages/accrue_portal` and repo verifier coverage for chosen scope | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** run the quick release-contract verifier bundle. [VERIFIED: existing bash scripts]
- **Per wave merge:** re-run the quick bundle and inspect workflow/recovery YAML together. [VERIFIED: `.github/workflows/release-please.yml`; `.github/workflows/publish-hex.yml`]
- **Phase gate:** the chosen scope must be reflected consistently across runbook, manifest/config, workflow, recovery path, and verifier coverage before `/gsd-verify-work`. [VERIFIED: `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`]

### Wave 0 Gaps

- [ ] Extend `scripts/ci/verify_release_manifest_alignment.sh` to either include `accrue_portal` or assert its intentional exclusion. [VERIFIED: current script only checks `accrue` and `accrue_admin`]
- [ ] Extend `scripts/ci/verify_package_docs.sh` or add a dedicated `verify_release_contract.sh` that checks package-set wording in `RELEASING.md`, `release-please-config.json`, `.release-please-manifest.json`, `.github/workflows/release-please.yml`, and `.github/workflows/publish-hex.yml`. [VERIFIED: current verifier does not cover these surfaces end-to-end]
- [ ] Add one portal-aware recovery-path check if portal remains in scope. [VERIFIED: `.github/workflows/publish-hex.yml`]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Maintainer auth is delegated to GitHub/Hex accounts, not implemented in repo code. [VERIFIED: `RELEASING.md`] |
| V3 Session Management | no | No application session handling changes are in scope for this phase. [VERIFIED: phase description] |
| V4 Access Control | yes | Human-gated `workflow_dispatch` merge queue and GitHub token scopes control who can cut releases. [VERIFIED: `.github/workflows/release-pr-automation.yml`; `RELEASING.md`] |
| V5 Input Validation | yes | Version/publish scripts validate manifest values and `@version` matches before publish. [VERIFIED: `scripts/ci/verify_release_manifest_alignment.sh`; `.github/workflows/release-please.yml`] |
| V6 Cryptography | yes | Use GitHub Actions secrets and Hex API keys; do not hand-roll credential handling or print secrets. [VERIFIED: `RELEASING.md`; `.github/workflows/release-please.yml`; `.github/workflows/publish-hex.yml`] |

### Known Threat Patterns for release automation

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Secret leakage in docs/logs | Information disclosure | Keep `RELEASE_PLEASE_TOKEN` and `HEX_API_KEY` only in GitHub secrets and never echo or document raw values. [VERIFIED: `RELEASING.md`; workflow env usage] |
| Unintended auto-merge of release PRs | Elevation of privilege | Maintain `workflow_dispatch` human gating for release PR merge automation. [VERIFIED: `.github/workflows/release-pr-automation.yml`; `RELEASING.md`] |
| Publishing wrong version from wrong ref | Tampering | Verify `@version` against workflow output and manifest before `mix hex.publish`. [VERIFIED: `.github/workflows/release-please.yml`; `.github/workflows/publish-hex.yml`] |
| Drift between human docs and automation | Repudiation | Add explicit release-contract verifier coverage and keep the “Last verified against” line current. [VERIFIED: `RELEASING.md`; current verifier gaps] |

## Sources

### Primary (HIGH confidence)

- Repo files: `RELEASING.md`, `release-please-config.json`, `.release-please-manifest.json`, `.github/workflows/release-please.yml`, `.github/workflows/publish-hex.yml`, `.github/workflows/release-pr-automation.yml`, `scripts/ci/verify_release_manifest_alignment.sh`, `scripts/ci/verify_package_docs.sh`, `.github/workflows/ci.yml`, `accrue/mix.exs`, `accrue_admin/mix.exs`, `accrue_portal/mix.exs`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/PROJECT.md`, `.planning/MILESTONES.md`
- Release Please manifest docs: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md
- Release Please README: https://github.com/googleapis/release-please/blob/main/README.md
- Release Please Action docs: https://github.com/googleapis/release-please-action
- npm registry: `npm view release-please version time --json`
- Hex API: `https://hex.pm/api/packages/accrue`, `https://hex.pm/api/packages/accrue_admin`, `https://hex.pm/api/packages/accrue_portal`

### Secondary (MEDIUM confidence)

- Hex package pages: `https://hex.pm/packages/accrue`, `https://hex.pm/packages/accrue_admin`

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - current repo stack, current npm registry version, and official Release Please docs all agree. [VERIFIED: repo files; VERIFIED: npm registry; CITED: official docs]
- Architecture: HIGH - the workflow and package dependency graph make publish ownership and order explicit. [VERIFIED: `.github/workflows/release-please.yml`; `accrue_admin/mix.exs`; `accrue_portal/mix.exs`]
- Pitfalls: HIGH - contradictions are directly observable in current repo files and registry state. [VERIFIED: repo files; VERIFIED: Hex API]

**Research date:** 2026-05-07
**Valid until:** 2026-06-06
