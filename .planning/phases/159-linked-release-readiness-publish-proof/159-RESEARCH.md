# Phase 159: Linked Release Readiness + Publish Proof - Research

**Researched:** 2026-05-31
**Domain:** Elixir monorepo linked-release orchestration (Release Please + Hex + CI proof)
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Use a composite release-truth artifact as the canonical pass/fail record for Phase 159. No single surface is authoritative under disagreement: `.release-please-manifest.json` and the combined Release Please PR are pre-publish intent; Hex package state plus git tags/GitHub releases are post-publish public fact; the release-truth artifact reconciles both.
- **D-02:** Treat changelogs, GitHub release notes, package docs, and planning mirrors as public mirrors of the release truth, not the proof authority. If they disagree with the artifact or public registry/tag state, downstream agents must fix the disagreement rather than rationalize it.
- **D-03:** Explicitly reject "manifest-only", "Hex-only", and "changelog-only" truth models for this linked release. They are useful inputs, but each leaves a known split-brain failure mode for a three-package Hex line.
- **D-04:** Produce one consolidated, machine-checkable release readiness / publish proof artifact for this phase, preferably `.planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md`, following the existing Phase 121 linked-release proof style.
- **D-05:** The artifact should have a fixed schema covering: target version, Release Please PR number, Release Please workflow run id, package `mix.exs` versions, `.release-please-manifest.json`, package changelog headings, Release Please job outputs, deterministic gate results, docs/support drift gates, host integration, git tags, GitHub release URLs/timestamps, Hex API truth, HexDocs availability, and any host Hex smoke result.
- **D-06:** Prefer script-generated or script-appended proof over hand-written prose. Human notes may explain unusual recovery, but mechanical facts should come from scripts such as `verify_release_pr_scope.sh`, `verify_release_manifest_alignment.sh`, and `capture_linked_release_proof.sh`.
- **D-07:** Tighten any release verifier that still checks only `accrue` / `accrue_admin` so it includes `accrue_portal` as a first-class linked package. Three-package lockstep is the Phase 159 contract.
- **D-08:** Preserve strict serialized publish order: publish `accrue` first, then `accrue_admin`, then `accrue_portal`. Do not parallelize admin and portal for speed; deterministic ordering and recovery clarity matter more than release throughput.
- **D-09:** Keep `ACCRUE_ADMIN_HEX_RELEASE=1` and `ACCRUE_PORTAL_HEX_RELEASE=1` as the package-local publish-mode switches so downstream packages resolve the just-published core package from Hex during dry-run and publish.
- **D-10:** Recovery policy is: retry the same version for downstream package failures when upstream `accrue` at version `V` is already correct on Hex; use `mix hex.publish --revert VERSION` only for a clear mistake inside Hex's narrow allowed update/revert window; otherwise retire the bad version and ship a new linked patch line forward with explicit changelog honesty.
- **D-11:** Manual `publish-hex.yml` remains a fallback/recovery path, not the primary release path. The primary path is the combined Release Please PR plus ordered publish jobs in `.github/workflows/release-please.yml`.
- **D-12:** Require full post-publish proof, not minimal Hex availability. The proof must show all three packages are available on Hex at the target version and must also reconcile HexDocs, git tags, GitHub releases, changelogs/release notes, workflow ordering, and deterministic gate outputs.
- **D-13:** Keep host Hex smoke as necessary-but-not-sufficient evidence. It proves consumer install behavior, but it does not replace registry/tag/release-note/gate reconciliation.
- **D-14:** Provider-backed Stripe/live lanes remain advisory and must not be introduced as package-release blockers. The Fake-backed deterministic gate remains the release readiness lane.

### the agent's Discretion
- Downstream agents may choose the exact formatting of `159-VERIFICATION.md` as long as it remains a single canonical artifact, is script-friendly, includes all three packages, and preserves the Phase 121 append-only proof style where useful.
- Downstream agents may update release verifier scripts, runbook wording, and planning mirrors as needed to make the above decisions enforceable, but must not widen Phase 159 into stable-core positioning or backlog cleanup work reserved for Phases 160 and 161.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within Phase 159 release-readiness scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REL-01 | Maintainer can verify coherent linked release truth across versions/changelog/Release Please/tags/runbook for all three packages. | Composite truth artifact, three-package verifiers, and public-mirror reconciliation model. |
| REL-02 | Maintainer can run deterministic release gate and get one pass/fail artifact for tests/docs/dialyzer/credo/package docs/support/adoption/host checks. | CI job map + exact script commands + fixed proof schema including gate outputs. |
| REL-03 | Maintainer can publish linked Hex release in documented order and record canonical proof in planning/changelogs/release notes. | Serialized publish workflow contract + fallback policy + post-publish capture script and evidence checklist. |
</phase_requirements>

## Summary

Phase 159 should be planned as a release-proof hardening phase, not a feature phase: the repository already has linked release mechanics across `accrue`, `accrue_admin`, and `accrue_portal`, but proof and verifier coverage are partially asymmetric and must be made explicitly three-package and artifact-driven. [VERIFIED: codebase grep]

The `release-please.yml` workflow already enforces serialized publish dependencies (`accrue` -> `accrue_admin` -> `accrue_portal`) and package-local Hex release switches; planning should focus on making one canonical, append-only verification ledger that captures pre-merge contract checks, deterministic CI gate results, and post-publish public truth. [VERIFIED: codebase grep]

External release behavior assumptions in this phase are stable and well documented: Hex supports `--dry-run`, `--yes`, and narrow-time-window `--revert`; Release Please monorepo outputs are path/component-prefixed, and linked-versions keeps configured components in sync. [CITED:https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] [CITED:https://github.com/googleapis/release-please-action] [CITED:https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md]

**Primary recommendation:** Plan one execution path that first proves release intent (PR/manifests/versions), then proves deterministic readiness (CI gate bundle), then proves published reality (tags/releases/Hex/HexDocs) in a single machine-appended `159-VERIFICATION.md`. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Version/changelog intent generation | CI automation (GitHub Actions) | Repo files | Release Please updates manifest + mix/changelog files from automation. [VERIFIED: codebase grep] |
| Pre-merge linked contract validation | Repo scripts | GitHub API | `verify_release_pr_scope.sh` validates required files and version headings via `gh`. [VERIFIED: codebase grep] |
| Deterministic release readiness gate | CI automation | Package test/docs/lint toolchain | `ci.yml` wires release-manifest/docs-contracts/release-gate/host-integration as required jobs. [VERIFIED: codebase grep] |
| Package publish transaction ordering | CI automation | Hex registry | Workflow `needs` edges enforce ordered publish jobs; Hex is final package host. [VERIFIED: codebase grep] [CITED:https://hex.pm/docs/publish] |
| Post-publish proof capture | Repo scripts | GitHub + Hex APIs | `capture_linked_release_proof.sh` queries run jobs, tags/releases, and Hex API for truth rows. [VERIFIED: codebase grep] |
| Public mirrors (release notes/changelogs/runbook) | Repo docs | Verification scripts | Scripts enforce mirrors; planning must include reconciliation updates when drift appears. [VERIFIED: codebase grep] |

## Standard Stack

### Core
| Library/Tool | Version | Purpose | Why Standard |
|--------------|---------|---------|--------------|
| `release-please` (CLI via `npx ...@17.6.0` in workflow) | 17.6.0 in repo workflow | Linked release PR + GitHub release orchestration | Already production-wired in project release workflow; supports monorepo outputs and manifest mode. [VERIFIED: codebase grep] [CITED:https://github.com/googleapis/release-please-action] |
| GitHub Actions (`release-please.yml`, `ci.yml`) | Workflow-defined | Deterministic sequencing + required gates | Canonical execution plane for release readiness/publish proof in this repo. [VERIFIED: codebase grep] |
| Hex (`mix hex.publish`) | Hex docs v2.2.1 current docs | Dry-run/publish/revert semantics | Official package publication and revert/update behavior documented and script-compatible. [CITED:https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] |
| Bash + `gh` + `jq` + `curl` | Installed locally in this environment | Proof capture and contract validation scripts | Existing scripts depend on these directly; no new toolchain needed. [VERIFIED: codebase grep] [VERIFIED: codebase grep] |

### Supporting
| Library/Tool | Version | Purpose | When to Use |
|--------------|---------|---------|-------------|
| `scripts/ci/verify_release_manifest_alignment.sh` | repo script | Manifest↔`mix.exs` lockstep guard | Pre-merge and CI `release-manifest-ssot`. [VERIFIED: codebase grep] |
| `scripts/ci/verify_release_pr_scope.sh` | repo script | Combined release PR file/version contract | Before merge and in release workflow post-repair. [VERIFIED: codebase grep] |
| `scripts/ci/capture_linked_release_proof.sh` | repo script | Append canonical post-publish evidence block | After publish workflow success for REL-03 proof. [VERIFIED: codebase grep] |
| `scripts/ci/accrue_host_uat.sh` + `accrue_host_hex_smoke.sh` | repo scripts | Host integration + post-publish Hex consumer proof | Deterministic gate and supplementary publish confidence. [VERIFIED: codebase grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Composite proof ledger | “Hex-only success” check | Misses PR intent/gate/doc drift and creates split-brain truth risk. [VERIFIED: codebase grep] |
| Serialized publish in one workflow | Manual per-package ad hoc publishes | Increases ordering/recovery ambiguity and weakens reproducibility. [VERIFIED: codebase grep] |

## Package Legitimacy Audit

Not applicable for Phase 159: no new external package installation is required by this phase scope; this is release-process verification and proof hardening only. [VERIFIED: codebase grep]

## Architecture Patterns

### System Architecture Diagram

```text
Conventional commits on main
        |
        v
Release Please (manifest + linked-versions)
        |
        v
Combined Release PR ------------------> verify_release_pr_scope / manifest alignment checks
        |                                                |
        v                                                v
Merged PR -> release-please.yml run -> publish accrue -> publish accrue_admin -> publish accrue_portal
        |                                                                      |
        |                                                                      v
        |                                                        Hex + tags + GitHub releases
        v                                                                      |
Deterministic CI gate bundle (release-manifest-ssot, docs-contracts, release-gate, host-integration)
        \_____________________________________________________________________/
                                      |
                                      v
                capture_linked_release_proof.sh appends canonical 159-VERIFICATION.md
```

### Recommended Project Structure
```text
scripts/ci/                    # release and proof verifiers
.github/workflows/             # release and deterministic gate jobs
accrue*/mix.exs                # package versions + publish-mode deps
accrue*/CHANGELOG.md           # package release mirrors
.planning/phases/159-.../      # canonical phase verification artifact
```

### Pattern 1: Composite Truth Reconciliation
**What:** Treat pre-publish intent, deterministic gate results, and post-publish public registry/tag state as three required sections in one ledger. [VERIFIED: codebase grep]  
**When to use:** Every linked release line after 1.3.0. [VERIFIED: codebase grep]

### Pattern 2: Script-Appended Proof Blocks
**What:** Use append-only script output blocks keyed by `PR_NUMBER`, `TARGET_VERSION`, and `RUN_ID`. [VERIFIED: codebase grep]  
**When to use:** Post-publish capture and any recovery rerun documentation. [VERIFIED: codebase grep]

### Anti-Patterns to Avoid
- **Single-surface truth claims:** “manifest says X” or “Hex says X” alone is insufficient for REL-01..03. [VERIFIED: codebase grep]
- **Parallel downstream publishes:** breaks explicit recovery chain and contradicts locked decision D-08. [VERIFIED: codebase grep]
- **Manual prose-first verification:** increases drift versus script-checkable evidence. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Multi-package version orchestration | Custom version bump scripts | Release Please manifest + linked-versions | Already supports monorepo lockstep and outputs used by workflow. [CITED:https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md] |
| Hex publish lifecycle logic | Custom HTTP publish client | `mix hex.publish` with `--dry-run`/`--yes`/`--revert` | Official behavior, fewer edge-case mistakes. [CITED:https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] |
| Post-publish truth gathering | Hand-assembled markdown | `capture_linked_release_proof.sh` + API reads | Deterministic, auditable, and repeatable. [VERIFIED: codebase grep] |

## Common Pitfalls

### Pitfall 1: Two-package verifier drift
**What goes wrong:** Manifest alignment or release notes checks pass while portal coverage is incomplete. [VERIFIED: codebase grep]  
**Why it happens:** Legacy scripts historically validated only `accrue` and `accrue_admin`. [VERIFIED: codebase grep]  
**How to avoid:** Require `accrue_portal` in all release-contract verifiers and artifact rows. [VERIFIED: codebase grep]  
**Warning signs:** Script output references only two package names. [VERIFIED: codebase grep]

### Pitfall 2: Mistaking CI green for published truth
**What goes wrong:** Deterministic gates pass but publish evidence (Hex/tag/release) is absent or inconsistent. [VERIFIED: codebase grep]  
**Why it happens:** CI gates and publish jobs are distinct stages. [VERIFIED: codebase grep]  
**How to avoid:** Enforce post-publish capture step as required phase completion evidence. [VERIFIED: codebase grep]

### Pitfall 3: Overusing `--revert`
**What goes wrong:** Attempting revert outside allowed time windows or when forward-fix is the correct path. [CITED:https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]  
**Why it happens:** Treating Hex publish as fully mutable. [CITED:https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]  
**How to avoid:** Use documented recovery policy: retry downstream; revert only for clear immediate mistakes; otherwise retire/forward-fix. [VERIFIED: codebase grep] [CITED:https://hex.pm/docs/faq]

## Code Examples

### Verify release PR contract before merge
```bash
bash scripts/ci/verify_release_pr_scope.sh --pr <number> --version <x.y.z>
```
Source: repo script contract. [VERIFIED: codebase grep]

### Capture canonical post-publish proof
```bash
bash scripts/ci/capture_linked_release_proof.sh \
  --version <x.y.z> \
  --run-id <github-actions-run-id> \
  --pr <number> \
  --output .planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md
```
Source: repo script contract. [VERIFIED: codebase grep]

### Deterministic gate bundle (local mirror of CI intent)
```bash
bash scripts/ci/verify_release_manifest_alignment.sh && \
bash scripts/ci/verify_release_contract.sh && \
bash scripts/ci/verify_release_notes_contract.sh && \
bash scripts/ci/verify_package_docs.sh && \
bash scripts/ci/verify_processor_support_matrix.sh && \
bash scripts/ci/verify_adoption_proof_matrix.sh && \
bash scripts/ci/accrue_host_uat.sh
```
Source: `ci.yml` and script contracts. [VERIFIED: codebase grep]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual/partial linked proof | Scripted proof capture with workflow + Hex API reconciliation | Present in current repo scripts and release workflow | Lower ambiguity; easier recovery audits. [VERIFIED: codebase grep] |
| Two-package release assumptions | Three-package linked release (`accrue`, `accrue_admin`, `accrue_portal`) | Current release config/workflows | Required portal parity in verifiers and docs. [VERIFIED: codebase grep] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `release-please@17.6.0` pinned in workflow remains acceptable for this phase without version bump. [ASSUMED] | Standard Stack | Low; plan may need tiny update if maintainers require latest action/CLI sync. |

## Open Questions (RESOLVED)

1. RESOLVED: Expand `verify_release_manifest_alignment.sh` in place to include first-class `accrue_portal` coverage rather than adding a second three-package alignment script.
   - What we know: current script checks only `accrue` + `accrue_admin`. [VERIFIED: codebase grep]
   - Why this resolution: CI and existing runbooks already depend on `verify_release_manifest_alignment.sh` as the release-manifest source-of-truth gate, so changing it in place preserves the existing gate name while closing the two-package drift risk.
   - Plan contract: Task 1 of `159-01-PLAN.md` expands this script to parse `.accrue_portal`, read `accrue_portal/mix.exs`, enforce one lockstep version across all three packages, and emit an `OK:` line naming `accrue`, `accrue_admin`, and `accrue_portal`.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `gh` | PR/run/release queries in verifiers | ✓ | 2.93.0 | none |
| `jq` | JSON parsing in scripts | ✓ | 1.7.1 | none |
| `curl` | Hex API truth checks | ✓ | 8.7.1 | none |
| `mix`/Elixir | package gates/publish commands | ✓ | Elixir 1.19.5 (OTP 28) in env | CI pins known versions |

Missing dependencies with no fallback:
- None found for planning-time research and script execution in this environment. [VERIFIED: codebase grep]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit + bash contract scripts + GitHub Actions job gates |
| Config file | Workflow-driven (`.github/workflows/ci.yml`) |
| Quick run command | `bash scripts/ci/verify_release_manifest_alignment.sh && bash scripts/ci/verify_release_contract.sh` |
| Full suite command | GitHub Actions required jobs: `release-manifest-ssot`, `docs-contracts-shift-left`, `release-gate`, `phase18-tax-gate`, `admin-drift-docs`, `host-integration`, `annotation-sweep` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REL-01 | linked release truth coherence | contract | `bash scripts/ci/verify_release_pr_scope.sh --pr <n> --version <v>` | ✅ |
| REL-02 | deterministic gate with one artifact | integration + contract | required CI job bundle + proof append into `159-VERIFICATION.md` | ✅ (scripts exist; phase artifact to add) |
| REL-03 | ordered publish + canonical publish proof | workflow + post-publish capture | release workflow run + `bash scripts/ci/capture_linked_release_proof.sh ...` | ✅ |

### Sampling Rate
- **Per task commit:** quick command above (intent checks).
- **Per wave merge:** full required CI jobs green.
- **Phase gate:** published release evidence appended with PR/version/run-id and Hex/tag/release parity.

### Wave 0 Gaps
- [ ] `.planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md` scaffold with fixed schema for script append.
- [ ] Expand `verify_release_manifest_alignment.sh` in place to three-package coverage for `accrue`, `accrue_admin`, and `accrue_portal`.

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | n/a (release process phase) |
| V3 Session Management | no | n/a |
| V4 Access Control | yes | GitHub Actions secret scoping (`RELEASE_PLEASE_TOKEN`, `HEX_API_KEY`) + protected branch checks. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | strict script arg parsing (`--pr`, `--version`, `--run-id`) in release scripts. [VERIFIED: codebase grep] |
| V6 Cryptography | yes | rely on platform signing/auth (GitHub/Hex), never custom crypto. [ASSUMED] |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Publishing wrong ref/version | Tampering | grep/version checks in workflow + `verify_release_pr_scope.sh` + manifest alignment checks. [VERIFIED: codebase grep] |
| Secret leakage in release path | Information Disclosure | use GitHub secrets only; runbook explicitly forbids logging/pasting secrets. [VERIFIED: codebase grep] |
| Incomplete linked publish claimed as complete | Repudiation | append-only proof artifact with run id, tags, releases, and Hex API truth. [VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)
- Repository workflows/scripts/docs inspected directly (`.github/workflows/ci.yml`, `.github/workflows/release-please.yml`, `scripts/ci/*.sh`, `RELEASING.md`) — implementation contracts and gates. [VERIFIED: codebase grep]
- Hex publish task docs: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html
- Release Please action docs: https://github.com/googleapis/release-please-action
- Release Please manifest/linked-versions docs: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md

### Secondary (MEDIUM confidence)
- Hex publishing guide: https://hex.pm/docs/publish
- Hex FAQ (revert/retire context): https://hex.pm/docs/faq

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - mostly existing repo stack plus official Release Please/Hex docs.
- Architecture: HIGH - directly reflected by current workflows and scripts.
- Pitfalls: HIGH - observed from script coverage gaps and runbook/workflow boundaries.

**Research date:** 2026-05-31
**Valid until:** 2026-06-30
