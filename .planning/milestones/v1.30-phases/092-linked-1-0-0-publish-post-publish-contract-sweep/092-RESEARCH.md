# Phase 92: Linked 1.0.0 publish + post-publish contract sweep - Research

**Researched:** 2026-04-28
**Domain:** Release automation, Hex publish sequencing, and post-publish docs/contracts verification for a linked Elixir monorepo. [VERIFIED: RELEASING.md] [VERIFIED: .github/workflows/release-please.yml]
**Confidence:** HIGH

<user_constraints>
## User Constraints

- No `092-CONTEXT.md` exists at research time; Phase 92 is constrained by the live milestone docs plus the user request. [VERIFIED: gsd-sdk init.phase-op] [VERIFIED: .planning/ROADMAP.md] [VERIFIED: user request]
- Focus on release ordering, Release Please behavior, and evidence shape for the linked `1.0.0` cut. [VERIFIED: user request]
- Identify the exact docs/verifier surfaces that must move from `0.3.1` to `1.0.0` in the same PR or same-day sequence. [VERIFIED: user request]
- Keep Phase 92 scoped to `REL-05` and `PPX-09..12`; do not leak `.planning/` Hex mirrors, friction-inventory maintainer pass, or planning tag work from Phase 93 into this phase. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/ROADMAP.md] [VERIFIED: user request]
- Nyquist validation is enabled, so Phase 92 needs an explicit validation artifact and a falsifiable verification ledger. [VERIFIED: .planning/config.json]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REL-05 | Linked `1.0.0` Hex publish for `accrue` and `accrue_admin` ships as one coordinated cut. [VERIFIED: .planning/REQUIREMENTS.md] | Release ordering, Release Please/Hex workflow semantics, same-day evidence shape, and publish edge cases below. [VERIFIED: RELEASING.md] [VERIFIED: .github/workflows/release-please.yml] [CITED: https://hex.pm/docs/publish] |
| PPX-09 | `verify_package_docs` re-runs clean at `1.0.0`. [VERIFIED: .planning/REQUIREMENTS.md] | Exact `0.3.1` install/pin literals and verifier ownership are enumerated below. [VERIFIED: scripts/ci/verify_package_docs.sh] [VERIFIED: accrue/README.md] [VERIFIED: accrue_admin/README.md] [VERIFIED: accrue/guides/first_hour.md] |
| PPX-10 | `verify_adoption_proof_matrix` re-runs clean at `1.0.0`. [VERIFIED: .planning/REQUIREMENTS.md] | Matrix script scope, same-PR coupling, and current non-versioned matrix state are documented below. [VERIFIED: scripts/ci/verify_adoption_proof_matrix.sh] [VERIFIED: examples/accrue_host/docs/adoption-proof-matrix.md] |
| PPX-11 | The full six-script `docs-contracts-shift-left` bundle re-runs clean at `1.0.0`. [VERIFIED: .planning/REQUIREMENTS.md] | Normative bundle membership comes from CI, with Phase 86 as evidence precedent. [VERIFIED: .github/workflows/ci.yml] [VERIFIED: .planning/milestones/v1.28-phases/086-post-publish-contract-alignment/086-VERIFICATION.md] |
| PPX-12 | First Hour + host README + adoption matrix needles refresh for the `0.3.1 -> 1.0.0` jump. [VERIFIED: .planning/REQUIREMENTS.md] | Exact literal-bearing files are identified; host README and matrix remain contract surfaces even where literals are currently generic. [VERIFIED: accrue/guides/first_hour.md] [VERIFIED: examples/accrue_host/README.md] [VERIFIED: examples/accrue_host/docs/adoption-proof-matrix.md] |
</phase_requirements>

## Summary

Phase 92 is not "publish first, clean up later." The clean plan is one combined release PR that already contains the `1.0.0` version bumps, manifest update, and all `PPX-09..12` doc/verifier edits, followed by a post-merge same-day verification pass that proves the GitHub release workflow actually published `accrue` first and `accrue_admin` second on Hex. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: RELEASING.md] [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: .github/workflows/ci.yml]

The current public registry state is still `0.3.1` for both packages: `accrue` was published at `2026-04-22T22:56:10Z` and `accrue_admin` at `2026-04-22T22:59:03Z`. Workspace `@version` values and `.release-please-manifest.json` also still read `0.3.1`, so Phase 92 must move all four lockstep version sources together. [VERIFIED: https://hex.pm/api/packages/accrue] [VERIFIED: https://hex.pm/api/packages/accrue_admin] [VERIFIED: accrue/mix.exs] [VERIFIED: accrue_admin/mix.exs] [VERIFIED: .release-please-manifest.json]

The highest-risk footguns are operational, not editorial: the workflow only publishes `accrue_admin` safely because it waits on `publish-accrue`, and the admin package only becomes publishable because `ACCRUE_ADMIN_HEX_RELEASE=1` swaps its sibling `path:` dependency to `{:accrue, "~> #{@version}"}`. Separately, the merge-blocking docs bundle is six scripts from `ci.yml`, but Phase 92 also needs the `release-manifest-ssot` check because version/manifest drift is directly in scope even though that job is outside the six-script bundle. [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: accrue_admin/mix.exs] [VERIFIED: .github/workflows/ci.yml] [VERIFIED: scripts/ci/verify_release_manifest_alignment.sh] [CITED: https://hex.pm/docs/publish]

**Primary recommendation:** Plan Phase 92 as one release PR plus one post-merge same-day verification wave: bump `mix.exs` + manifest + version-literal docs together, require `release-manifest-ssot` and the full six-script docs bundle before merge, then record Hex/tag evidence and post-publish contract proofs after the release workflow finishes. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .github/workflows/ci.yml] [VERIFIED: .github/workflows/release-please.yml]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Open/update the linked release PR | GitHub / Release Please | Repo source | The repo uses Release Please manifest mode to author version bumps and numbered changelog sections from repo state. [VERIFIED: release-please-config.json] [VERIFIED: .release-please-manifest.json] [VERIFIED: .github/workflows/release-please.yml] |
| Publish `accrue` to Hex | GitHub Actions | Hex registry | `publish-accrue` runs first and publishes from the release SHA to Hex. [VERIFIED: .github/workflows/release-please.yml] [CITED: https://hex.pm/docs/publish] |
| Publish `accrue_admin` to Hex | GitHub Actions | Hex registry | The admin publish job depends on the release job and `publish-accrue`, and only becomes publishable with `ACCRUE_ADMIN_HEX_RELEASE=1`. [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: accrue_admin/mix.exs] |
| Keep package/version literals honest on `main` | Repo source | CI bash verifiers | `verify_package_docs.sh` derives expected versions from `mix.exs` and enforces the doc pins. [VERIFIED: scripts/ci/verify_package_docs.sh] |
| Keep adoption/integrator contract honest | Repo source | CI bash verifiers | The host README and matrix are repo-owned docs guarded by `verify_adoption_proof_matrix.sh` and `verify_verify01_readme_contract.sh`. [VERIFIED: scripts/ci/verify_adoption_proof_matrix.sh] [VERIFIED: scripts/ci/verify_verify01_readme_contract.sh] |
| Record public release evidence | Hex registry | GitHub releases/tags | Phase 92 completion is not real until Hex and tags exist at `1.0.0`. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: RELEASING.md] [VERIFIED: .github/workflows/release-please.yml] |

## Project Constraints (from CLAUDE.md)

- Stay inside the planned GSD phase workflow rather than making ad-hoc repo edits. [VERIFIED: CLAUDE.md]
- Monorepo shape is fixed: `accrue/` and `accrue_admin/` are sibling Mix projects sharing `.github/workflows/` and release tooling. [VERIFIED: CLAUDE.md] [VERIFIED: accrue/mix.exs] [VERIFIED: accrue_admin/mix.exs]
- The release model is a linked pair for the first public stable line; Phase 92 is the forcing function for that cut, not a feature phase. [VERIFIED: CLAUDE.md] [VERIFIED: .planning/REQUIREMENTS.md]
- Security guidance still applies during release work: secrets stay in runtime/GitHub Actions, not in docs, logs, or commits. [VERIFIED: CLAUDE.md] [VERIFIED: RELEASING.md]

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---------------|---------|---------|--------------|
| `release-please` CLI | `17.6.0` | Creates GitHub releases, tags, and release PR updates in the workflow. [VERIFIED: .github/workflows/release-please.yml] | The workflow hard-pins `npx --yes release-please@17.6.0`, so planning around any other release engine is wrong for this phase. [VERIFIED: .github/workflows/release-please.yml] |
| Release Please manifest mode | current manifest config in repo | Linked-version monorepo versioning and changelog generation. [VERIFIED: release-please-config.json] [VERIFIED: .release-please-manifest.json] | The repo already uses `linked-versions`, `separate-pull-requests: false`, and component tags. [VERIFIED: release-please-config.json] [CITED: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md] |
| Hex publish via `mix hex.publish` | Hex `2.4.1` locally; workflow installs latest Hex at runtime. [VERIFIED: mix hex.info] [VERIFIED: .github/workflows/release-please.yml] | Package publication and docs upload for both packages. [CITED: https://hex.pm/docs/publish] | This is the official Elixir/Hex publish path, and the workflow already uses `mix hex.publish --dry-run` then `--yes`. [VERIFIED: .github/workflows/release-please.yml] |
| GitHub Actions release workflow | `ubuntu-24.04`, `actions/checkout@v6`, `erlef/setup-beam@v1` pins in repo. [VERIFIED: .github/workflows/release-please.yml] | Runs release creation and Hex publish steps on merge to `main`. [VERIFIED: .github/workflows/release-please.yml] | This is where the real release happens; local-only planning is insufficient. [VERIFIED: .github/workflows/release-please.yml] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|---------------|---------|---------|-------------|
| `verify_package_docs.sh` | repo script | Enforces package README and First Hour version/pin literals from `mix.exs`. [VERIFIED: scripts/ci/verify_package_docs.sh] | Required for `PPX-09` and as part of `PPX-11`. [VERIFIED: .planning/REQUIREMENTS.md] |
| `verify_adoption_proof_matrix.sh` | repo script | Enforces adoption matrix contract literals. [VERIFIED: scripts/ci/verify_adoption_proof_matrix.sh] | Required for `PPX-10` and as part of `PPX-11`. [VERIFIED: .planning/REQUIREMENTS.md] |
| `verify_release_manifest_alignment.sh` | repo script | Enforces manifest and both `mix.exs` versions stay in lockstep. [VERIFIED: scripts/ci/verify_release_manifest_alignment.sh] | Always run for Phase 92 even though it is outside the six-script docs bundle. [VERIFIED: .github/workflows/ci.yml] |
| `bash scripts/ci/accrue_host_uat.sh` | repo script | Proves the host integration gate on the reviewed SHA. [VERIFIED: examples/accrue_host/README.md] [VERIFIED: .github/workflows/ci.yml] | Use when host-facing docs change or when Phase 92 needs the same evidence shape Phase 86/91 used. [VERIFIED: .planning/milestones/v1.28-phases/086-VERIFICATION.md] [VERIFIED: .planning/milestones/v1.30-phases/091-pre-publish-prep/091-VERIFICATION.md] |
| `gh` CLI | `2.89.0` locally | Inspect workflow runs, releases, and tags if same-day verification is done from the terminal. [VERIFIED: gh auth status] | Use for post-merge evidence collection if GitHub UI links are not enough. [VERIFIED: gh auth status] |
| `jq` | `1.7.1` locally | Reads manifest/version data and Hex API JSON. [VERIFIED: jq --version] | Use in verification and ad-hoc release checks. [VERIFIED: scripts/ci/verify_release_manifest_alignment.sh] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Workflow-driven publish on merge | Manual `publish-hex.yml` or local `mix hex.publish` | Keep as fallback only; it adds human sequencing risk and needs local Hex credentials. [VERIFIED: RELEASING.md] [CITED: https://hex.pm/docs/publish] |
| Release Please-authored numbered changelog sections | Manual `## 1.0.0` blocks on `main` | Wrong for this repo; Phase 91 explicitly prepared `## Unreleased` preambles so Release Please can render the public section. [VERIFIED: accrue/CHANGELOG.md] [VERIFIED: accrue_admin/CHANGELOG.md] [VERIFIED: .planning/milestones/v1.30-phases/091-pre-publish-prep/091-CONTEXT.md] |
| Full Phase 93 mirror/tag work in same phase | Keep HYG/INV/tag for Phase 93 | Required to prevent scope creep and to keep Phase 92 focused on publish plus public-contract honesty only. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/ROADMAP.md] |

**Operational setup:**

```bash
mix local.hex --force
bash scripts/ci/verify_release_manifest_alignment.sh
bash scripts/ci/verify_package_docs.sh
bash scripts/ci/verify_adoption_proof_matrix.sh
```

## Architecture Patterns

### System Architecture Diagram

```text
releasable merge commit on main
  |
  v
release-please.yml -> release job
  |
  +--> github-release (tags + GitHub releases for accrue/accrue_admin)
  |
  +--> release-pr refresh (next combined release PR state)
  |
  v
publish-accrue
  |
  v
Hex registry: accrue 1.0.0
  |
  v
publish-accrue-admin (needs: release + publish-accrue)
  |
  v
Hex registry: accrue_admin 1.0.0
  |
  v
same-day verification
  |
  +--> release-manifest-ssot
  +--> docs-contracts-shift-left (6 scripts)
  +--> host-integration evidence if host docs changed
  +--> Hex/tag URLs + timestamps in 092-VERIFICATION.md
```

### Recommended Project Structure

```text
.github/workflows/
├── release-please.yml      # Release creation + ordered Hex publish
└── ci.yml                  # Merge-blocking contract jobs

accrue/
├── mix.exs                 # core @version source
├── README.md               # PPX-09 version literal
└── guides/first_hour.md    # PPX-09 / PPX-12 version literals

accrue_admin/
├── mix.exs                 # admin @version source + ACCRUE_ADMIN_HEX_RELEASE gate
└── README.md               # PPX-09 version literals

scripts/ci/
├── verify_release_manifest_alignment.sh
├── verify_package_docs.sh
├── verify_adoption_proof_matrix.sh
├── verify_verify01_readme_contract.sh
├── verify_v1_17_friction_research_contract.sh
├── verify_production_readiness_discoverability.sh
└── verify_core_admin_invoice_verify_ids.sh

.planning/milestones/v1.30-phases/092-.../
├── 092-RESEARCH.md
├── 092-VALIDATION.md
└── 092-VERIFICATION.md
```

### Pattern 1: Combined Release PR, Post-Merge Publish

**What:** Put the `1.0.0` version bumps, `.release-please-manifest.json`, and every Phase 92 docs/verifier edit into one release PR, then let the push-to-`main` workflow do the actual publish. [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: .planning/ROADMAP.md]

**When to use:** Always for this phase; the workflow only publishes on `push` to `main` or `workflow_dispatch`, not from the open PR itself. [VERIFIED: .github/workflows/release-please.yml]

**Example:**

```yaml
# Source: .github/workflows/release-please.yml
publish-accrue-admin:
  needs: [release, publish-accrue]
  if: ${{ always() && needs.release.outputs.accrue_admin_release_created == 'true' && (needs.release.outputs.accrue_release_created != 'true' || needs.publish-accrue.result == 'success') }}
```

### Pattern 2: Version-Literal Edits Travel with Verifier-Proof Edits

**What:** Any file with a hard `0.3.1` pin must move in the same PR as the verifier(s) that derive expected versions from `mix.exs`. [VERIFIED: scripts/ci/verify_package_docs.sh] [VERIFIED: accrue/README.md] [VERIFIED: accrue_admin/README.md] [VERIFIED: accrue/guides/first_hour.md]

**When to use:** For `PPX-09` and `PPX-12`. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**

```bash
# Source: scripts/ci/verify_package_docs.sh
require_fixed "$ROOT_DIR/accrue/README.md" "{:accrue, \"~> $accrue_version\"}"
require_fixed "$ROOT_DIR/accrue_admin/README.md" "{:accrue_admin, \"~> $accrue_admin_version\"}"
require_fixed "$ROOT_DIR/accrue/guides/first_hour.md" "{:accrue, \"~> $accrue_version\"}"
require_fixed "$ROOT_DIR/accrue/guides/first_hour.md" "{:accrue_admin, \"~> $accrue_admin_version\"}"
```

### Pattern 3: Same-Day Post-Publish Evidence, Not Phase-93 Mirror Work

**What:** Record Hex URLs, tag URLs, and green verifier evidence in `092-VERIFICATION.md` the day the release lands, but leave `.planning/PROJECT.md`, `.planning/STATE.md`, friction inventory, and planning tag work to Phase 93. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/ROADMAP.md]

**When to use:** After the publish workflow completes successfully. [VERIFIED: RELEASING.md] [VERIFIED: .github/workflows/release-please.yml]

### Anti-Patterns to Avoid

- **Manual numbered changelog blocks on `main`:** Release Please owns the public `## [1.0.0]` sections. [VERIFIED: accrue/CHANGELOG.md] [VERIFIED: accrue_admin/CHANGELOG.md]
- **Publishing `accrue_admin` without the env gate:** the package keeps a `path:` sibling dependency unless `ACCRUE_ADMIN_HEX_RELEASE=1` is set. [VERIFIED: accrue_admin/mix.exs]
- **Treating the six-script docs bundle as the whole phase gate:** Phase 92 also needs `release-manifest-ssot` because manifest/version drift is part of the deliverable. [VERIFIED: .github/workflows/ci.yml] [VERIFIED: scripts/ci/verify_release_manifest_alignment.sh]
- **Pulling `.planning/` mirror updates into the release PR:** those are Phase 93 requirements, not Phase 92. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/ROADMAP.md]

## Exact Touch Surfaces

### Must change from `0.3.1` to `1.0.0`

| File | Why it must change | Guard |
|------|--------------------|-------|
| `accrue/mix.exs` | Core package `@version` source of truth. [VERIFIED: accrue/mix.exs] | `release-manifest-ssot`; publish job greps version. [VERIFIED: scripts/ci/verify_release_manifest_alignment.sh] [VERIFIED: .github/workflows/release-please.yml] |
| `accrue_admin/mix.exs` | Admin package `@version` source of truth; also drives published `accrue ~> #{@version}` dep when `ACCRUE_ADMIN_HEX_RELEASE=1`. [VERIFIED: accrue_admin/mix.exs] | `release-manifest-ssot`; publish job greps version. [VERIFIED: scripts/ci/verify_release_manifest_alignment.sh] [VERIFIED: .github/workflows/release-please.yml] |
| `.release-please-manifest.json` | Manifest must stay aligned with both `mix.exs` files. [VERIFIED: .release-please-manifest.json] | `release-manifest-ssot`. [VERIFIED: scripts/ci/verify_release_manifest_alignment.sh] |
| `accrue/README.md` | Install snippet pins `{:accrue, "~> 0.3.1"}`. [VERIFIED: accrue/README.md] | `verify_package_docs.sh`. [VERIFIED: scripts/ci/verify_package_docs.sh] |
| `accrue_admin/README.md` | Install snippet pins `{:accrue_admin, "~> 0.3.1"}` and published-release prose says `accrue ~> 0.3.1`. [VERIFIED: accrue_admin/README.md] | `verify_package_docs.sh`. [VERIFIED: scripts/ci/verify_package_docs.sh] |
| `accrue/guides/first_hour.md` | Both install pins still read `0.3.1`. [VERIFIED: accrue/guides/first_hour.md] | `verify_package_docs.sh`. [VERIFIED: scripts/ci/verify_package_docs.sh] |

### Must be inspected in the same PR / same-day sequence

| Surface | Current state | Why still in Phase 92 |
|---------|---------------|-----------------------|
| `examples/accrue_host/README.md` | No `0.3.1` literal found by current grep. [VERIFIED: rg search 2026-04-28] | It is part of the `PPX-12` integrator surface and is guarded by `verify_verify01_readme_contract.sh`; if any release-facing wording changes, it must ship with the same PR and be re-proved. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: scripts/ci/verify_verify01_readme_contract.sh] |
| `examples/accrue_host/docs/adoption-proof-matrix.md` | No `0.3.1` literal found by current grep. [VERIFIED: rg search 2026-04-28] | `PPX-10` and `PPX-12` still require the matrix evidence surface to be current at `1.0.0`, even if the edit is only a wording/evidence refresh or no-op plus proof rerun. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: scripts/ci/verify_adoption_proof_matrix.sh] |
| `accrue/CHANGELOG.md` and `accrue_admin/CHANGELOG.md` | Already prepared with `1.0.0 — Stable` under `## Unreleased`. [VERIFIED: accrue/CHANGELOG.md] [VERIFIED: accrue_admin/CHANGELOG.md] | Do not hand-edit numbered `1.0.0` sections; verify Release Please renders them in the release PR and after merge/tag. [VERIFIED: .planning/milestones/v1.30-phases/091-pre-publish-prep/091-CONTEXT.md] [CITED: https://github.com/googleapis/release-please] |

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Numbered `1.0.0` changelog sections | Manual release blocks on `main` | Release Please-rendered sections from `## Unreleased` | Avoids duplicate-heading and release-note drift. [VERIFIED: accrue/CHANGELOG.md] [VERIFIED: accrue_admin/CHANGELOG.md] |
| Custom admin publish dependency swapping | Manual file edits before publish | `ACCRUE_ADMIN_HEX_RELEASE=1` + existing `accrue_dep/0` logic | Hex packages cannot be published with `path:` dependencies. [VERIFIED: accrue_admin/mix.exs] [CITED: https://hex.pm/docs/publish] |
| Ad-hoc release evidence checklist | A one-off spreadsheet or PR comment | `092-VERIFICATION.md` with Hex/tag URLs and reviewed-SHA verifier evidence | Keeps release proof durable and phase-local. [VERIFIED: .planning/milestones/v1.28-phases/086-post-publish-contract-alignment/086-VERIFICATION.md] |
| Partial docs verification | Only the touched script | Full six-script `docs-contracts-shift-left` bundle plus `release-manifest-ssot` | CI, not intuition, defines the merge-blocking contract. [VERIFIED: .github/workflows/ci.yml] |

**Key insight:** Phase 92 already has the release machinery; the hard part is sequencing existing automation and contract checks so `main`, Hex, and the docs surface tell the same `1.0.0` story on the same day. [VERIFIED: RELEASING.md] [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: .github/workflows/ci.yml]

## Common Pitfalls

### Pitfall 1: Forgetting the manifest check

**What goes wrong:** The docs bundle passes, but `.release-please-manifest.json` and one `mix.exs` drift, so the release PR or publish workflow is wrong. [VERIFIED: scripts/ci/verify_release_manifest_alignment.sh]

**Why it happens:** `release-manifest-ssot` is merge-blocking in CI but is not part of the six-script `docs-contracts-shift-left` bundle. [VERIFIED: .github/workflows/ci.yml]

**How to avoid:** Treat `verify_release_manifest_alignment.sh` as a required Phase 92 gate alongside the six-script bundle. [VERIFIED: scripts/ci/verify_release_manifest_alignment.sh]

**Warning signs:** Manifest still says `0.3.1` after the PR claims `1.0.0`, or one package file differs from the other. [VERIFIED: scripts/ci/verify_release_manifest_alignment.sh]

### Pitfall 2: Admin publish silently blocked by local sibling dependency

**What goes wrong:** `accrue_admin` cannot publish as a Hex package because it still points at `{:accrue, path: "../accrue"}`. [VERIFIED: accrue_admin/mix.exs]

**Why it happens:** The package swaps to the Hex dependency only when `ACCRUE_ADMIN_HEX_RELEASE=1` is present. [VERIFIED: accrue_admin/mix.exs]

**How to avoid:** Do not redesign this; rely on the existing workflow env and confirm it remains in the publish job. [VERIFIED: .github/workflows/release-please.yml]

**Warning signs:** Dry-run publish fails with dependency validation complaints. [CITED: https://hex.pm/docs/publish]

### Pitfall 3: Treating host README and matrix as out-of-scope because they lack a literal `0.3.1`

**What goes wrong:** Version-literal files update, but the integrator proof surfaces or their scripts are not revalidated, leaving PPX-10/12 half-closed. [VERIFIED: .planning/REQUIREMENTS.md]

**Why it happens:** Current greps show no `0.3.1` literal in those files, so it is easy to mistake them for Phase 93 or for no-op territory. [VERIFIED: rg search 2026-04-28]

**How to avoid:** Keep them in the Phase 92 review checklist and either edit them in the same PR or explicitly record "no wording change, verification rerun only" in `092-VERIFICATION.md`. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/milestones/v1.28-phases/086-post-publish-contract-alignment/086-VERIFICATION.md]

**Warning signs:** `PPX-10` or `PPX-12` evidence only cites package README diffs and skips host/matrix proof entirely. [VERIFIED: .planning/REQUIREMENTS.md]

## Code Examples

Verified patterns from official and repo sources:

### Release Please monorepo path outputs

```yaml
# Source: https://github.com/googleapis/release-please-action
steps:
  - uses: googleapis/release-please-action@v4
    id: release
  - run: |
      echo "${{ steps.release.outputs['packages/core--release_created'] }}"
      echo "${{ steps.release.outputs['packages/core--version'] }}"
```

### Linked versions plugin

```json
// Source: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md
{
  "plugins": [
    {
      "type": "linked-versions",
      "groupName": "accrue-monorepo",
      "components": ["accrue", "accrue_admin"]
    }
  ]
}
```

### Hex CI publish pattern

```bash
# Source: https://hex.pm/docs/publish
HEX_API_KEY=... mix hex.publish --yes
mix hex.publish --revert VERSION
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Release Please action root outputs only | Monorepo/path outputs are path-prefixed like `<path>--release_created`. [CITED: https://github.com/googleapis/release-please-action] | v4 action docs current as of 2026-04-28. [CITED: https://github.com/googleapis/release-please-action] | This repo avoids that footgun by writing custom `accrue_*` outputs from its shell step. [VERIFIED: .github/workflows/release-please.yml] |
| Independent monorepo package bumping | `linked-versions` plugin keeps grouped components on the highest bumped version. [CITED: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md] | Current release-please manifest docs. [CITED: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md] | Supports the lockstep `1.0.0` pair without inventing new tooling. [VERIFIED: release-please-config.json] |
| Ad-hoc publish retries | Hex officially documents `--revert` and retirement windows. [CITED: https://hex.pm/docs/publish] [CITED: https://hex.pm/docs/faq] | Current Hex docs. [CITED: https://hex.pm/docs/publish] | Recovery can be planned concretely if one publish fails. [VERIFIED: RELEASING.md] |

**Deprecated/outdated:**

- Relying on plain `release_created` outputs for a monorepo path component is outdated; use path-prefixed outputs or a repo-local wrapper. [CITED: https://github.com/googleapis/release-please-action]
- Treating a Hex package with `path:` or Git dependencies as publishable is invalid. [CITED: https://hex.pm/docs/publish]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `PPX-12` may require only verification reruns, not new wording, in `examples/accrue_host/README.md` and `adoption-proof-matrix.md` because current grep shows no `0.3.1` literals there. [ASSUMED] | Exact Touch Surfaces | Planner may over- or under-scope host/matrix edits unless maintainer confirms desired 1.0.0 wording. |

## Open Questions (RESOLVED)

1. **What is the exact maintainer move that forces the release PR to `1.0.0`?**
   - **RESOLVED:** Use the repo's documented bootstrap path: the releasable Phase 92 commit or squash merge must explicitly carry `Release-As: 1.0.0` so Release Please opens or refreshes the combined release PR at `1.0.0` for both package paths. Planning should treat this as a mandatory pre-merge task, and verification should require proof that the open release PR or workflow output showed `1.0.0` for both packages before merge. [VERIFIED: RELEASING.md] [VERIFIED: .github/workflows/release-please.yml] [CITED: https://github.com/googleapis/release-please]
   - **Execution implication:** Phase 92 plans must include a concrete bootstrap task that performs and proves this `Release-As: 1.0.0` action; bumping files alone is not sufficient for REL-05.

2. **Does the team want explicit `1.0.0` wording added to the host README or adoption matrix, or just a proof rerun?**
   - **RESOLVED:** The roadmap success criterion is explicit that First Hour, host README, and adoption matrix needles all read `1.0.0`, so Phase 92 should plan actual `1.0.0` wording or needle updates on the host README and adoption matrix rather than allowing an inspection-only no-op. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md]
   - **Execution implication:** Plan 02 must treat those surfaces as required `1.0.0` touchpoints, with same-PR verifier updates if any corresponding script expectations change.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `gh` CLI with auth | Inspect release PRs, workflow runs, and post-merge evidence | ✓ | `2.89.0`; authenticated as `szTheory` | GitHub web UI |
| `jq` | Manifest/Hex API inspection | ✓ | `1.7.1` | `python -m json.tool` or manual inspection |
| `node` / `npm` | `npx release-please@17.6.0` in workflow model; optional local dry-runs | ✓ | `v22.14.0` / `11.1.0` | GitHub Actions only |
| `mix` / Hex | Local dry-run validation and publish semantics | ✓ | Hex `2.4.1`; Elixir toolchain installed locally | GitHub Actions only |
| GitHub Actions secrets `RELEASE_PLEASE_TOKEN` and `HEX_API_KEY` | Actual tag/release/publish execution | Unknown from local shell | — | Manual local publish only if maintainer has equivalent local credentials |

**Missing dependencies with no fallback:**

- None identified for planning. Actual publish still depends on GitHub secrets that are not inspectable from the repo checkout. [VERIFIED: RELEASING.md] [VERIFIED: .github/workflows/release-please.yml]

**Missing dependencies with fallback:**

- If the GitHub Actions publish path misfires, the runbook already defines manual fallback via `.github/workflows/publish-hex.yml` or local `mix hex.publish`. [VERIFIED: RELEASING.md] [CITED: https://hex.pm/docs/publish]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Bash verifier suite + GitHub Actions workflow contracts + ExUnit wrapper for `verify_package_docs`. [VERIFIED: scripts/ci/verify_package_docs.sh] [VERIFIED: accrue/test/accrue/docs/package_docs_verifier_test.exs] |
| Config file | `.github/workflows/ci.yml` plus phase-local `092-VALIDATION.md`. [VERIFIED: .github/workflows/ci.yml] |
| Quick run command | `bash scripts/ci/verify_release_manifest_alignment.sh && bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_adoption_proof_matrix.sh` |
| Full suite command | `bash scripts/ci/verify_release_manifest_alignment.sh && bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_v1_17_friction_research_contract.sh && bash scripts/ci/verify_verify01_readme_contract.sh && bash scripts/ci/verify_production_readiness_discoverability.sh && bash scripts/ci/verify_adoption_proof_matrix.sh && bash scripts/ci/verify_core_admin_invoice_verify_ids.sh` |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REL-05 | Combined release PR lands, workflow publishes `accrue` then `accrue_admin`, Hex shows both `1.0.0`. [VERIFIED: .planning/REQUIREMENTS.md] | operational + manual proof | Post-merge: GitHub release workflow run URL, Hex API/URL checks, tag URLs in `092-VERIFICATION.md` | ❌ Wave 0 |
| PPX-09 | Package docs pins match `1.0.0`. [VERIFIED: .planning/REQUIREMENTS.md] | bash + ExUnit | `bash scripts/ci/verify_package_docs.sh` and `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` | ✅ |
| PPX-10 | Adoption matrix contract still passes at `1.0.0`. [VERIFIED: .planning/REQUIREMENTS.md] | bash | `bash scripts/ci/verify_adoption_proof_matrix.sh` | ✅ |
| PPX-11 | Full docs-contracts bundle is green at reviewed SHA. [VERIFIED: .planning/REQUIREMENTS.md] | bash / CI | Full six-script bundle from `ci.yml` | ✅ |
| PPX-12 | First Hour + host README + matrix are reviewed and aligned for the `1.0.0` jump. [VERIFIED: .planning/REQUIREMENTS.md] | grep + bash + manual review | `bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_adoption_proof_matrix.sh && bash scripts/ci/verify_verify01_readme_contract.sh` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** quick run command above.
- **Per wave merge:** full suite command above.
- **Phase gate:** full suite green before merge, then same-day Hex/tag verification after publish workflow completion.

### Wave 0 Gaps

- [ ] `092-VALIDATION.md` — phase-local requirement-to-evidence plan for release plus post-publish proof.
- [ ] `092-VERIFICATION.md` — needs preconditions, reviewed merge SHA, Hex URLs, tag URLs, workflow run URL, and requirement sign-off.
- [ ] A defined post-merge evidence command set or checklist for querying Hex API / GitHub tags at `1.0.0`.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Release work does not change user auth flows. [VERIFIED: .planning/REQUIREMENTS.md] |
| V3 Session Management | no | Release work does not touch session code. [VERIFIED: .planning/REQUIREMENTS.md] |
| V4 Access Control | yes | Keep publish authority in GitHub Actions secrets and authenticated maintainer workflows only. [VERIFIED: RELEASING.md] [VERIFIED: .github/workflows/release-please.yml] |
| V5 Input Validation | yes | `verify_release_manifest_alignment.sh` and the docs bash verifiers validate release-critical file state before merge. [VERIFIED: scripts/ci/verify_release_manifest_alignment.sh] [VERIFIED: scripts/ci/verify_package_docs.sh] |
| V6 Cryptography | yes | `HEX_API_KEY` and `RELEASE_PLEASE_TOKEN` remain secret-managed; never echo or commit them. [VERIFIED: RELEASING.md] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Publishing admin package with wrong core dependency | Tampering | Preserve `ACCRUE_ADMIN_HEX_RELEASE=1` and verify published version before upload. [VERIFIED: accrue_admin/mix.exs] [VERIFIED: .github/workflows/release-please.yml] |
| Secret leakage in release troubleshooting | Information Disclosure | Keep `HEX_API_KEY` and `RELEASE_PLEASE_TOKEN` in GitHub Actions secrets only; omit them from docs/logs. [VERIFIED: RELEASING.md] |
| False-complete release where docs say `1.0.0` but registry does not | Repudiation | Same-day Hex API and tag URL evidence in `092-VERIFICATION.md`. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: RELEASING.md] |

## Sources

### Primary (HIGH confidence)

- `RELEASING.md` - release ordering, fallback policy, and `1.0.0` bootstrap runbook. [VERIFIED: RELEASING.md]
- `.github/workflows/release-please.yml` - actual release/publish ordering, env gates, and workflow pins. [VERIFIED: .github/workflows/release-please.yml]
- `.github/workflows/ci.yml` - normative merge-blocking job membership. [VERIFIED: .github/workflows/ci.yml]
- `scripts/ci/verify_package_docs.sh`, `verify_adoption_proof_matrix.sh`, `verify_release_manifest_alignment.sh`, `verify_verify01_readme_contract.sh` - exact contract surfaces. [VERIFIED: scripts/ci/verify_package_docs.sh] [VERIFIED: scripts/ci/verify_adoption_proof_matrix.sh] [VERIFIED: scripts/ci/verify_release_manifest_alignment.sh] [VERIFIED: scripts/ci/verify_verify01_readme_contract.sh]
- `accrue/mix.exs`, `accrue_admin/mix.exs`, `accrue/README.md`, `accrue_admin/README.md`, `accrue/guides/first_hour.md` - current `0.3.1` literals and publish/package behavior. [VERIFIED: accrue/mix.exs] [VERIFIED: accrue_admin/mix.exs] [VERIFIED: accrue/README.md] [VERIFIED: accrue_admin/README.md] [VERIFIED: accrue/guides/first_hour.md]
- Hex package API: `https://hex.pm/api/packages/accrue` and `https://hex.pm/api/packages/accrue_admin` - current public registry versions and publish timestamps. [VERIFIED: https://hex.pm/api/packages/accrue] [VERIFIED: https://hex.pm/api/packages/accrue_admin]
- Phase precedents: `086-VERIFICATION.md`, `091-CONTEXT.md`, `68-RESEARCH.md`, `68-01-PLAN.md`. [VERIFIED: .planning/milestones/v1.28-phases/086-post-publish-contract-alignment/086-VERIFICATION.md] [VERIFIED: .planning/milestones/v1.30-phases/091-pre-publish-prep/091-CONTEXT.md] [VERIFIED: .planning/milestones/v1.19-phases/68-release-train/68-RESEARCH.md] [VERIFIED: .planning/milestones/v1.19-phases/68-release-train/68-01-PLAN.md]

### Secondary (MEDIUM confidence)

- Release Please action docs - monorepo/path output naming in v4. [CITED: https://github.com/googleapis/release-please-action]
- Release Please manifest releaser docs - `linked-versions` plugin semantics. [CITED: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md]
- Release Please README - `Release-As:` version forcing. [CITED: https://github.com/googleapis/release-please]
- Hex publish docs - CI publish semantics and dependency restrictions. [CITED: https://hex.pm/docs/publish]
- Hex FAQ - revert/retire windows and immutability. [CITED: https://hex.pm/docs/faq]

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - the repo hard-pins the release workflow and verifiers, and external release semantics were cross-checked with official Release Please and Hex docs.
- Architecture: HIGH - Phase 92 sequencing is directly encoded in `release-please.yml`, `ci.yml`, and the live milestone requirements.
- Pitfalls: HIGH - the main failure modes are visible in the workflow, manifest, verifier scripts, and prior release-phase artifacts.

**Research date:** 2026-04-28
**Valid until:** 2026-05-05
