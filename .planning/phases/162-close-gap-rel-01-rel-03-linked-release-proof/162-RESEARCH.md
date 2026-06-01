# Phase 162: Close gap: REL-01/REL-03 -- linked release proof - Research

**Researched:** 2026-06-01  
**Domain:** Linked release proof capture and release-truth mirror reconciliation  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Keep `.planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md` as the canonical append-only release-truth ledger. Phase 159 already owns the release proof contract, `scripts/ci/README.md` points REL-01/REL-03 there, and the current proof scripts are built around that file.
- **D-02:** Create `.planning/phases/162-close-gap-rel-01-rel-03-linked-release-proof/162-VERIFICATION.md` as a non-authoritative closeout/index file for Phase 162. It should record `PR_NUMBER`, `TARGET_VERSION`, `RUN_ID`, the GitHub Actions `linked-release-proof.md` artifact URL, and a pointer to the exact appended block in `159-VERIFICATION.md`.
- **D-03:** The Phase 162 verification file must say explicitly that it is an index/reconciliation record, not a second source of release truth. Downstream agents must avoid creating two competing proof ledgers.
- **D-04:** Do not retarget `capture_linked_release_proof.sh` or REL gate documentation away from `159-VERIFICATION.md` unless a future release-process phase deliberately migrates all canonical references atomically.
- **D-05:** Use full but narrow release-truth reconciliation as the closure bar. After canonical proof lands, reconcile the Phase 159 ledger, Phase 162 verification, v1.48 planning mirrors, package changelogs, `accrue/guides/release-notes.md`, GitHub release/tag state, Hex package state, HexDocs availability, host Hex smoke, and release-notes contract output.
- **D-06:** Public mirrors remain mirrors, not proof authority. If changelogs, release notes, GitHub releases, HexDocs, README references, or planning prose disagree with the canonical proof/public registry state, fix the mirror rather than weakening the proof requirement.
- **D-07:** README-style and broad posture documents should only be edited when they contain version-specific release claims that changed. Do not use Phase 162 to rewrite stable-core positioning, package ownership boundaries, or product scope.
- **D-08:** Reconciliation order should be: append/consume canonical proof first; update Phase 162 and v1.48 planning mirrors second; reconcile public version-truth mirrors third; run focused verifier/smoke checks last.
- **D-09:** If `linked-release-proof` fails before any package reaches public Hex, a raw CI failure URL plus failing step in the canonical ledger is enough to explain the blocked state.
- **D-10:** If the job fails after any package reaches public Hex, append a structured recovery block to the canonical ledger before retrying. Required fields: `target_version`, `run_id`, `pr_number`, per-package public state, failed package or proof step, chosen recovery path, next command, and timestamp.
- **D-11:** Recovery paths should preserve Phase 159 policy: retry the same version for downstream failures when upstream package state is correct; use Hex revert only for a clear mistake inside Hex's narrow allowed window; otherwise retire the bad line and ship a new linked patch line forward with changelog honesty.
- **D-12:** Do not create separate failed-attempt appendix files by default. They split authority and make retry state harder for downstream agents to reason about. A future compliance-driven phase may add incident files if it also adds strict cross-link verification.
- **D-13:** REL-01 closes when a real combined Release Please PR targets a version greater than `1.3.0`, `verify_release_pr_scope.sh --pr <pr> --version <target>` passes for that PR/version pair, and the canonical ledger records the exact PR number and target version.
- **D-14:** REL-03 closes when the `linked-release-proof` CI artifact succeeds for the same target version and targeted corroboration passes: `capture_linked_release_proof.sh`, `scripts/ci/accrue_host_hex_smoke.sh` in a clean context, and `scripts/ci/verify_release_notes_contract.sh`.
- **D-15:** CI proof is the primary evidence, but not the only evidence. The independent host Hex smoke protects the adopter install path, and the release-notes contract protects public mirror truth.
- **D-16:** Manual public-surface audit is anomaly-triggered, not mandatory for every release. Require it when proof scripts disagree, CI reruns are stale, release-process code changed materially, Hex/GitHub surfaces show propagation anomalies, or a prior failure/retry block exists for the same target version.
- **D-17:** Phase 162 should land as a tight proof-reconciliation slice: append real proof to the Phase 159 ledger, create a Phase 162 pointer verification, reconcile all release-truth mirrors narrowly, record any failure/retry state in the canonical ledger, and close REL-01/REL-03 only after CI proof plus targeted scripted corroboration.
- **D-18:** The architecture should optimize maintainer DX during a stressful release: one proof authority, one target version, one PR number, one run id, script-generated evidence, thin mirrors, and explicit recovery state.

### the agent's Discretion
- Downstream agents may choose the exact heading names in `162-VERIFICATION.md`, but must preserve the non-authoritative pointer/index role.
- Downstream agents may add a small verifier or checklist guard only if it reduces drift without introducing a second proof source. Prefer extending existing release scripts or docs-contract guidance over creating new ceremony.
- Downstream agents may decide whether the structured recovery block is written by script or by a carefully templated manual append. The default preference is script-friendly structure in the canonical ledger.

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within Phase 162 release-proof and reconciliation scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REL-01 | Verify next linked release line after `1.3.0` has coherent versions/changelogs/Release Please/tags/runbook across all three packages. | Canonical proof source sequencing, PR scope contract, and mirror reconciliation order are defined below. |
| REL-03 | Publish linked Hex release in documented order with canonical proof in planning/changelogs/release notes. | Workflow + script proof chain, post-publish corroboration checks, and failure/retry ledger policy are defined below. |
</phase_requirements>

## Summary

Phase 162 should be planned as a reconciliation-and-proof-consumption phase, not a release-automation redesign. Keep `159-VERIFICATION.md` as the single release-truth ledger and make `162-VERIFICATION.md` only a pointer/index closeout file. [VERIFIED: codebase grep]

The current workflow already encodes the required evidence chain: Release Please PR scope check, ordered publishes (`accrue` -> `accrue_admin` -> `accrue_portal`), and a `linked-release-proof` job that captures proof, runs host Hex smoke, and verifies release-notes contract. The planner should sequence tasks around consuming that evidence and reconciling mirrors after it exists. [VERIFIED: codebase grep]

**Primary recommendation:** Plan Phase 162 as a strict four-stage closeout: ingest canonical proof into `159-VERIFICATION.md`, write a non-authoritative `162-VERIFICATION.md` pointer, reconcile planning/public mirrors, then run focused verifier checks and requirement checkbox closure. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Release PR scope validation (`REL-01`) | CI/Automation | Planning ledger | CI scripts validate files/versions; ledger records immutable identifiers. [VERIFIED: codebase grep] |
| Linked publish ordering (`REL-03`) | CI/Automation | Hex registry | Workflow `needs` graph enforces ordering; Hex is public truth surface. [VERIFIED: codebase grep] |
| Canonical proof capture | Planning ledger | CI artifact | Script appends deterministic block to ledger; workflow artifact is source input. [VERIFIED: codebase grep] |
| Mirror reconciliation | Documentation/Planning mirrors | Public registries | Mirror docs/planning must be updated to match canonical proof + public state. [VERIFIED: codebase grep] |
| Failure/retry state | Planning ledger | Workflow logs | Recovery decisions must be append-only in canonical ledger with run links. [VERIFIED: codebase grep] |

## Project Constraints (from AGENTS.md)

`AGENTS.md` is not present in this repository root, so no additional project-level directives were discovered. [VERIFIED: codebase grep]

## Standard Stack

### Core
| Library/Tool | Version | Purpose | Why Standard |
|--------------|---------|---------|--------------|
| GitHub Actions workflow `release-please.yml` | repo-local workflow | Release orchestration + proof job pipeline | Already authoritative path for linked release + proof capture. [VERIFIED: codebase grep] |
| `scripts/ci/capture_linked_release_proof.sh` | repo-local script | Canonical deterministic proof append (PR/version/run/tags/releases/Hex/HexDocs) | Encodes exact REL-03 proof contract. [VERIFIED: codebase grep] |
| `scripts/ci/verify_release_pr_scope.sh` | repo-local script | REL-01 pre-merge PR contract check | Enforces three-package release PR coherence. [VERIFIED: codebase grep] |
| `.planning/.../159-VERIFICATION.md` | append-only ledger | Single proof authority | Locked by Phase 162 decisions. [VERIFIED: codebase grep] |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| `scripts/ci/accrue_host_hex_smoke.sh` | repo-local script | Consumer install smoke against Hex | Required corroboration after publish success. [VERIFIED: codebase grep] |
| `scripts/ci/verify_release_notes_contract.sh` | repo-local script | Release-note mirror freshness + stable-core token checks | Required corroboration for release-note truth. [VERIFIED: codebase grep] |
| `scripts/ci/verify_release_manifest_alignment.sh` | repo-local script | Lockstep manifest/mix check | Guard before/with release verification. [VERIFIED: codebase grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Canonical Phase 159 ledger | New Phase 162 standalone proof ledger | Rejected: creates split authority and audit ambiguity. [VERIFIED: codebase grep] |
| Script-derived proof | Manual prose-only proof block | Rejected: fragile, error-prone, easier to fabricate accidentally. [VERIFIED: codebase grep] |

**Installation:** No new external packages are required for this phase. [VERIFIED: codebase grep]

## Package Legitimacy Audit

Not applicable. This phase should not introduce new third-party packages. [VERIFIED: codebase grep]

## Architecture Patterns

### System Architecture Diagram

```text
Combined Release Please PR (>1.3.0)
  -> verify_release_pr_scope.sh (REL-01 gate)
    -> merge PR
      -> release-please workflow run
        -> publish-accrue
          -> publish-accrue-admin
            -> publish-accrue-portal
              -> linked-release-proof job
                -> capture_linked_release_proof.sh --auto (artifact + canonical ledger block)
                -> accrue_host_hex_smoke.sh
                -> verify_release_notes_contract.sh
                  -> append/reconcile 159-VERIFICATION.md
                    -> write 162-VERIFICATION.md pointer/index
                      -> reconcile ROADMAP/STATE/REQUIREMENTS/planning mirrors
                        -> close REL-01 and REL-03
```

### Recommended Project Structure
```text
.planning/phases/159-linked-release-readiness-publish-proof/
  159-VERIFICATION.md        # canonical append-only release truth
.planning/phases/162-close-gap-rel-01-rel-03-linked-release-proof/
  162-VERIFICATION.md        # non-authoritative pointer/index closeout
scripts/ci/
  capture_linked_release_proof.sh
  verify_release_pr_scope.sh
  accrue_host_hex_smoke.sh
  verify_release_notes_contract.sh
```

### Pattern 1: Canonical-Ledger-First Closeout
**What:** Treat Phase 159 ledger as SSOT, then write Phase 162 pointer file.  
**When to use:** Every REL-01/REL-03 closure attempt.  
**Example:**
```bash
bash scripts/ci/verify_release_pr_scope.sh --pr <pr> --version <target>
bash scripts/ci/capture_linked_release_proof.sh --version <target> --run-id <run> --pr <pr> --output .planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md
```
Source: [scripts/ci/README.md](scripts/ci/README.md) [VERIFIED: codebase grep]

### Anti-Patterns to Avoid
- **Competing ledgers:** Writing full proof in both 159 and 162 files causes divergence. [VERIFIED: codebase grep]
- **Surface-only proof:** Treating changelog/tag/Hex/release alone as sufficient evidence. [VERIFIED: codebase grep]
- **Early checkbox closure:** Marking REL-01/REL-03 complete before real post-`1.3.0` PR/run IDs exist. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| PR contract validation | Ad hoc manual file diff checklist | `verify_release_pr_scope.sh` | Script already enforces required file/version shape. [VERIFIED: codebase grep] |
| Linked release evidence capture | Custom markdown synthesis by hand | `capture_linked_release_proof.sh` | Deterministic, binds proof to one PR/version/run. [VERIFIED: codebase grep] |
| Hex propagation polling | New bespoke waiter script | `accrue_host_hex_smoke.sh` built-in wait loop | Existing script already handles CI timing race. [VERIFIED: codebase grep] |

**Key insight:** Phase 162 risk is truth drift, not missing mechanisms; reuse existing scripts and ledgers. [VERIFIED: codebase grep]

## Runtime State Inventory

Not a rename/refactor/migration phase. Omitted by design.

## Common Pitfalls

### Pitfall 1: Split Proof Authority
**What goes wrong:** Planner/tasks create a second “truth” ledger under Phase 162.  
**Why it happens:** Misreading Phase 162 as replacing Phase 159 instead of indexing it.  
**How to avoid:** Enforce explicit “non-authoritative index” language in `162-VERIFICATION.md`.  
**Warning signs:** Duplicate full proof tables in both files with unsynced timestamps.

### Pitfall 2: Incomplete Release Identity Binding
**What goes wrong:** Proof rows reference “latest run” or “latest PR” without exact IDs.  
**Why it happens:** Convenience shortcuts during release stress.  
**How to avoid:** Require exact `PR_NUMBER`, `TARGET_VERSION`, `RUN_ID` in every closure block.  
**Warning signs:** Empty identifier fields or references to mutable “latest”.

### Pitfall 3: Mirror-First Reconciliation
**What goes wrong:** Planning/docs updated before canonical proof is appended.  
**Why it happens:** Attempt to pre-close audit gaps quickly.  
**How to avoid:** Preserve order: canonical proof -> 162 pointer -> mirrors -> checks.  
**Warning signs:** REL checkboxes changed while 159 ledger still has placeholders.

## Code Examples

### REL-01 pre-merge gate
```bash
bash scripts/ci/verify_release_pr_scope.sh --pr <number-or-url> --version <x.y.z>
```
Source: [scripts/ci/verify_release_pr_scope.sh](scripts/ci/verify_release_pr_scope.sh) [VERIFIED: codebase grep]

### REL-03 canonical capture
```bash
bash scripts/ci/capture_linked_release_proof.sh \
  --version <x.y.z> --run-id <id> --pr <number-or-url> \
  --output .planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md
```
Source: [scripts/ci/capture_linked_release_proof.sh](scripts/ci/capture_linked_release_proof.sh) [VERIFIED: codebase grep]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual post-publish proof follow-up | CI-owned `linked-release-proof` job with artifact upload | 2026-05-31 (Phase 159 Plan 02) | Reduces manual drift and enforces fail-closed proof capture. [VERIFIED: codebase grep] |
| Two-package mindset | Three-package lockstep (`accrue`, `accrue_admin`, `accrue_portal`) | pre-Phase 159 to Phase 159 hardening | Prevents missing portal/admin release evidence. [VERIFIED: codebase grep] |

**Deprecated/outdated:**
- “Automation wiring alone closes REL-01/REL-03” is explicitly invalid. [VERIFIED: codebase grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `RELEASING.md` “Last verified” date (`2026-05-07`) is stale relative to proof-job wiring and may need mirror reconciliation. [ASSUMED] | Common Pitfalls / Mirror reconciliation | Low-medium; could leave runbook/date mirror inconsistent. |

## Open Questions

1. **Should Phase 162 update `RELEASING.md` “Last verified against” date?**
   - What we know: Current line is `2026-05-07`; workflow proof job wiring was added later. [VERIFIED: codebase grep]
   - What's unclear: Whether maintainers want date-only refresh in this phase or defer to a release-process maintenance phase.
   - Recommendation: Treat as conditional mirror update only if Phase 162 edits release-process semantics or if audit requires this specific mirror correction.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `gh` | PR/run/release queries | ✓ | 2.93.0 | none |
| `jq` | JSON parsing in scripts | ✓ | 1.7.1 | none |
| `curl` | Hex/GitHub API probes | ✓ | 8.7.1 | none |
| `git` | tag/sha checks | ✓ | 2.41.0 | none |
| `bash` | all CI verifier scripts | ✓ | 3.2.57 | none |
| `mix` | host Hex smoke + BEAM tasks | ✓ | OTP 28 / Elixir runtime detected | none |
| GitHub Actions environment vars (`GITHUB_RUN_ID`, `GITHUB_SHA`) | `--auto` proof capture path | Partial (CI-only) | runtime-provided | use manual `--version --run-id --pr` args outside CI |

**Missing dependencies with no fallback:**
- None found.

**Missing dependencies with fallback:**
- CI-only env vars for `--auto`; use explicit script flags locally.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Bash contract verifiers + GitHub Actions workflow validation |
| Config file | `.github/workflows/release-please.yml` |
| Quick run command | `bash scripts/ci/verify_release_pr_scope.sh --pr <pr> --version <target>` |
| Full suite command | `bash scripts/ci/verify_release_manifest_alignment.sh && bash scripts/ci/verify_release_contract.sh && bash scripts/ci/verify_release_notes_contract.sh` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REL-01 | Combined release PR has required files + target version coherence | contract | `bash scripts/ci/verify_release_pr_scope.sh --pr <pr> --version <target>` | ✅ |
| REL-03 | Post-publish proof for one exact PR/version/run + downstream corroboration | integration/contract | `bash scripts/ci/capture_linked_release_proof.sh --version <target> --run-id <run> --pr <pr> --output .planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md && bash scripts/ci/accrue_host_hex_smoke.sh && bash scripts/ci/verify_release_notes_contract.sh` | ✅ |

### Sampling Rate
- **Per task commit:** `bash -n scripts/ci/capture_linked_release_proof.sh && bash -n scripts/ci/verify_release_pr_scope.sh`
- **Per wave merge:** REL-01 and REL-03 map commands above
- **Phase gate:** Successful canonical proof + corroboration + mirror reconciliation checks

### Wave 0 Gaps

None -- existing release scripts/workflow already cover required verifier surfaces for this phase.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | GitHub token-based CLI/API access via Actions secrets and `gh` auth context |
| V3 Session Management | no | n/a |
| V4 Access Control | yes | Protected branch + workflow-gated publish order and conditions |
| V5 Input Validation | yes | Strict arg parsing/validation in release proof scripts |
| V6 Cryptography | no | No new crypto introduced in this phase |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Fabricated release evidence | Repudiation/Tampering | Script-derived proof bound to exact PR/version/run IDs in append-only canonical ledger |
| Split-brain release truth | Tampering | Single canonical ledger (159), 162 as pointer-only mirror |
| Premature requirement closure | Repudiation | Require proof artifact + corroboration commands before REL status changes |

## Sources

### Primary (HIGH confidence)
- Local repo sources inspected directly: `162-CONTEXT.md`, `159-CONTEXT.md`, `159-VERIFICATION.md`, `159-02-SUMMARY.md`, `RELEASING.md`, `.github/workflows/release-please.yml`, `scripts/ci/README.md`, `scripts/ci/capture_linked_release_proof.sh`, `scripts/ci/verify_release_pr_scope.sh`, `scripts/ci/accrue_host_hex_smoke.sh`, `scripts/ci/verify_release_notes_contract.sh`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)
- `https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html` (publish/revert semantics referenced by runbook). [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]
- `https://hex.pm/docs/publish` (Hex publish behavior referenced by runbook). [CITED: https://hex.pm/docs/publish]
- `https://github.com/googleapis/release-please-action` (Release Please behavior baseline). [CITED: https://github.com/googleapis/release-please-action]
- `https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md` (manifest releaser baseline). [CITED: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md]

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - validated from current repo workflow/scripts and locked context.
- Architecture: HIGH - derived from active workflow DAG and script contracts.
- Pitfalls: HIGH - explicitly documented in Phase 159/162 context and milestone audit notes.

**Research date:** 2026-06-01  
**Valid until:** 2026-07-01

