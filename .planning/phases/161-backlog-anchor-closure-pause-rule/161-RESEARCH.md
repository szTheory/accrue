# Phase 161: Backlog Anchor Closure + Pause Rule - Research

**Researched:** 2026-06-01
**Domain:** Planning hygiene closure, backlog reclassification, and policy-verifier alignment [VERIFIED: codebase grep]
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Anchor and Seed Disposition
- **D-01:** Use a split-registry model for stale planning pressure. Historical friction anchors stay traceability-only; deferred seeds/ideas live in a separate trigger-bound bucket.
- **D-02:** Classify v1.17 FRG anchors as **Historical Anchors** unless a fresh sourced friction row reopens them. They should remain linked for audit history, but must not appear as active milestone pressure.
- **D-03:** Classify `SEED-001` as resolved historical context, not a live seed. Its linked-release purpose has already been superseded by later linked publish work and Phase 159 release-readiness context.
- **D-04:** Classify `SEED-002` and deferred feature ideas as dormant future-roadmap material with concrete reopen triggers. They are not v1.48 closeout blockers and do not create default next-milestone scope.
- **D-05:** Every deferred row that survives Phase 161 should carry: status, reason, future owner or category, and `revisit_trigger`. The trigger must match the stable-core evidence bar: concrete adopter failure, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change.
- **D-06:** Do not hard-delete historical anchors. The footgun is institutional memory loss and repeated re-triage; the cleaner approach is to mark them non-active and prove that active roadmap surfaces no longer imply broad feature work.

### Planning Hygiene Proof
- **D-07:** Adopt a hybrid hygiene proof: a human-readable planning hygiene ledger plus a fast Bash verifier wired into the existing docs-contract pattern.
- **D-08:** Do not introduce a separate machine-readable manifest for this phase. A manifest would add dual-SSOT drift for a small planning-hygiene closeout.
- **D-09:** Add or extend a verifier in the repo's existing style (`require_fixed`, `require_regex`, `require_absent_regex`, clear failure prefix) to prove:
  - broad-feature pointers are explicitly historical, deferred, or dormant;
  - no active roadmap pointer suggests broad feature work is currently open;
  - deferred seeds/ideas have concrete reopen triggers;
  - the pause rule is mirrored across `PROJECT.md`, `ROADMAP.md`, and `STATE.md`.
- **D-10:** The verifier should live with the current docs-contract scripts and be included in the existing `docs-contracts-shift-left` lane, not as a new heavyweight CI job.
- **D-11:** The hygiene proof should optimize for maintainer DX: fast local failure, grep-friendly diagnostics, and one obvious place to fix wording drift.

### Pause Rule
- **D-12:** Use a doctrine-plus-mirrors placement model. `PROJECT.md` owns the canonical pause doctrine; `ROADMAP.md` and `STATE.md` carry concise mirrors for milestone closeout and session continuity.
- **D-13:** The pause rule should be strong but not a feature freeze. Preferred wording: after v1.48, broad feature milestones remain closed by default unless reopened by concrete adopter failure, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change.
- **D-14:** Reopen decisions should be recorded in `PROJECT.md` or a future strategy artifact, then reflected in `ROADMAP.md`/`STATE.md`. Do not allow a deferred idea or stale seed alone to create milestone scope.
- **D-15:** Preserve the public stable-core / demand-driven expansion language from Phase 160. The pause rule is a maintainer decision about planning defaults, not public abandonment language.

### Cohesive Recommendation
- **D-16:** Phase 161 should land as one coherent maintenance-posture slice: split stale anchors from deferred seeds, add the hygiene ledger, add the verifier, mirror the pause rule, and update state. Splitting these into independent partial edits risks a contradictory planning surface.
- **D-17:** The planner should prefer small, auditable text changes plus one focused verifier over broad rewrites of historical planning docs.

### the agent's Discretion
- Downstream agents may choose exact section names, but should preserve the active/non-active distinction. Recommended labels are **Historical Anchors**, **Deferred Seeds and Ideas**, and **Pause Rule**.
- Downstream agents may choose whether to extend `verify_v1_17_friction_research_contract.sh` or create a separate `verify_roadmap_hygiene.sh`; the default recommendation is a separate small hygiene verifier to avoid overloading the v1.17-specific contract.
- Downstream agents may decide whether the hygiene ledger lives primarily in `ROADMAP.md` or `PROJECT.md`, as long as `PROJECT.md` remains the canonical doctrine home and the verifier proves the mirrors.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within Phase 161 backlog-anchor closure and pause-rule scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BAK-01 | Distinguish stale historical anchors from active scope | Split-registry model, historical vs dormant labels, and trigger schema for deferred rows [VERIFIED: codebase grep] |
| BAK-02 | Planning hygiene proof that no stale roadmap pointer implies active broad feature work | Add/extend Bash verifier in `scripts/ci` and wire into `docs-contracts-shift-left` [VERIFIED: codebase grep] |
| PAU-01 | Explicit post-v1.48 pause rule with reopen criteria | Canonical doctrine in `PROJECT.md` with mirrored wording in `ROADMAP.md` and `STATE.md` [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 161 is a documentation-contract and planning-state closure phase, not product behavior work. The correct implementation shape is one coherent documentation slice plus one focused verifier in the existing `scripts/ci` pattern and CI lane. [VERIFIED: codebase grep]

The repo already has the right primitives: prior posture verifier conventions (`require_fixed`, `require_regex`, `require_absent_regex`), existing planning SSOT checks for v1.17 anchors, and an established merge-blocking `docs-contracts-shift-left` lane. Reuse those directly to avoid policy drift and avoid introducing a new manifest. [VERIFIED: codebase grep]

**Primary recommendation:** Implement one new hygiene verifier (preferred: `scripts/ci/verify_roadmap_hygiene.sh`), update planning docs atomically, and assert pause-rule mirror parity across `PROJECT.md`, `ROADMAP.md`, and `STATE.md`. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Reclassify stale anchors/seeds | Documentation state (`.planning/*`) | CI verifier scripts | Source of truth is planning docs; scripts only enforce drift checks [VERIFIED: codebase grep] |
| Hygiene proof execution | CI/Bash contracts (`scripts/ci`) | GitHub Actions workflow | Existing docs-contract checks run from `scripts/ci` and are called by `docs-contracts-shift-left` [VERIFIED: codebase grep] |
| Pause rule doctrine | `PROJECT.md` | `ROADMAP.md`, `STATE.md` | Phase 161 decisions lock doctrine-plus-mirrors ownership [VERIFIED: codebase grep] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Bash (`grep`, `perl`) | system tools | Fast docs-contract assertions | Existing verifiers already use this exact style and failure ergonomics [VERIFIED: codebase grep] |
| GitHub Actions (`docs-contracts-shift-left` job) | workflow YAML | Merge-blocking policy enforcement | Existing lane already hosts planning/docs contracts [VERIFIED: codebase grep] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `scripts/ci/README.md` triage conventions | repo-local contract | Keeps failure diagnosis maintainable | Update when introducing new verifier or changing needles [VERIFIED: codebase grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Separate new manifest file | Markdown ledger + grep verifier | Manifest adds dual-SSOT drift for small scope [VERIFIED: codebase grep] |
| Extending v1.17 verifier | New focused hygiene verifier | Extending old verifier risks coupling unrelated invariants [VERIFIED: codebase grep] |

## Architecture Patterns

### System Architecture Diagram
```text
Planning docs (.planning/PROJECT.md, ROADMAP.md, STATE.md, seeds, friction inventory)
  -> Human-readable reclassification + pause rule mirrors
  -> scripts/ci/verify_roadmap_hygiene.sh (new, focused checks)
  -> .github/workflows/ci.yml: docs-contracts-shift-left
  -> merge gate verdict (pass/fail with grep-friendly diagnostics)
```

### Recommended Project Structure
```text
scripts/ci/
├── verify_roadmap_hygiene.sh      # New Phase 161 policy verifier
└── README.md                      # Add triage + scope mapping for BAK/PAU

.planning/
├── PROJECT.md                     # Canonical pause doctrine
├── ROADMAP.md                     # Historical vs dormant ledger mirrors
└── STATE.md                       # Session continuity mirror
```

### Pattern 1: Canonical Doctrine + Thin Mirrors
**What:** Keep policy ownership in one file (`PROJECT.md`) and mirrored concise wording elsewhere. [VERIFIED: codebase grep]
**When to use:** Any maintainer policy that must stay durable but visible in multiple planning surfaces. [VERIFIED: codebase grep]

### Pattern 2: Narrow Bash Contract
**What:** Check only load-bearing literals/regex and explicit absence terms; fail with prefixed diagnostics. [VERIFIED: codebase grep]
**When to use:** Planning/docs drift gates that should be quick and merge-blocking. [VERIFIED: codebase grep]

### Anti-Patterns to Avoid
- **Dual SSOT manifests:** Creates upkeep overhead and contradiction risk for small planning phases. [VERIFIED: codebase grep]
- **Hard delete historical anchors:** Removes traceability and encourages repeated re-triage. [VERIFIED: codebase grep]
- **“Feature freeze” language:** Conflicts with stable-core demand-driven posture conventions. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Planning hygiene assertions | New parser/service | Existing grep-based verifier style | Proven in repo, fast, and contributor-familiar [VERIFIED: codebase grep] |
| New CI lane for docs policy | Dedicated heavyweight workflow | Existing `docs-contracts-shift-left` lane | Avoids CI sprawl and preserves shift-left semantics [VERIFIED: codebase grep] |

**Key insight:** This phase is governance consistency, so reuse governance tooling already trusted by contributors. [VERIFIED: codebase grep]

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — verified: scope is repo planning docs and scripts, no DB/state migrations referenced in Phase 161 sources | Code edits only [VERIFIED: codebase grep] |
| Live service config | GitHub Actions workflow entry in `.github/workflows/ci.yml` is relevant | Add verifier step in existing job [VERIFIED: codebase grep] |
| OS-registered state | None — no systemd/launchd/task scheduler references for this phase | None [VERIFIED: codebase grep] |
| Secrets/env vars | None required for docs verifier path | None [VERIFIED: codebase grep] |
| Build artifacts | None — no compile/package rename involved | None [VERIFIED: codebase grep] |

## Common Pitfalls

### Pitfall 1: Historical Links Still Read as Active Scope
**What goes wrong:** Anchors remain linked but not explicitly marked historical/dormant. [VERIFIED: codebase grep]
**Why it happens:** Teams preserve links but forget active-status labeling. [ASSUMED]
**How to avoid:** Add explicit status taxonomy + verifier checks for active-language absence. [VERIFIED: codebase grep]
**Warning signs:** Roadmap text still implies broad feature work after closure. [VERIFIED: codebase grep]

### Pitfall 2: Policy Drift Across PROJECT/ROADMAP/STATE
**What goes wrong:** Canonical pause rule and mirrors diverge over time. [VERIFIED: codebase grep]
**Why it happens:** Manual edits without contract checks. [ASSUMED]
**How to avoid:** Require same reopen trigger set in all three files via verifier literals/regex. [VERIFIED: codebase grep]
**Warning signs:** One file contains fewer reopen criteria than others. [VERIFIED: codebase grep]

## Code Examples

### Existing Verifier Pattern to Reuse
```bash
# Source: scripts/ci/verify_stable_core_posture.sh
require_fixed "$ROOT_DIR/.planning/PROJECT.md" "stable-core / demand-driven expansion"
require_absent_regex "$ROOT_DIR/.planning/ROADMAP.md" "feature freeze|maintenance only"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Broad roadmap pressure via stale anchors | Stable-core posture + demand-driven reopen bar | 2026-05-31 (Phase 160/161 context) | Reduces scope creep and planning ambiguity [VERIFIED: codebase grep] |
| Implicit policy checks | Explicit docs-contract verifiers in CI | Existing before Phase 161; extended through v1.48 | Faster drift detection [VERIFIED: codebase grep] |

**Deprecated/outdated:**
- Treating deferred ideas as default next-milestone scope is out of policy under current posture. [VERIFIED: codebase grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Manual edits are the primary source of policy drift | Common Pitfalls | Verifier may miss real drift vectors |

## Open Questions

1. **Verifier placement choice**
   - What we know: Context allows either extending v1.17 verifier or creating a dedicated hygiene verifier, with dedicated script preferred. [VERIFIED: codebase grep]
   - What's unclear: Maintainer preference for script count vs script scope.
   - Recommendation: Use dedicated `verify_roadmap_hygiene.sh` unless maintainers request consolidation.

## Environment Availability

Step 2.6: SKIPPED (no external runtime/service dependencies beyond existing repo CI/Bash toolchain were identified). [VERIFIED: codebase grep]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Bash verifier scripts + GitHub Actions contract lane [VERIFIED: codebase grep] |
| Config file | `.github/workflows/ci.yml` [VERIFIED: codebase grep] |
| Quick run command | `bash scripts/ci/verify_roadmap_hygiene.sh` [ASSUMED] |
| Full suite command | `bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_processor_support_matrix.sh && bash scripts/ci/verify_verify01_readme_contract.sh && bash scripts/ci/verify_adoption_proof_matrix.sh && bash scripts/ci/verify_stable_core_posture.sh && bash scripts/ci/verify_v1_17_friction_research_contract.sh && bash scripts/ci/verify_roadmap_hygiene.sh` [ASSUMED] |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BAK-01 | Historical vs active scope is explicit | contract | `bash scripts/ci/verify_roadmap_hygiene.sh` | ❌ Wave 0 |
| BAK-02 | No stale pointer implies active broad feature work | contract | `bash scripts/ci/verify_roadmap_hygiene.sh` | ❌ Wave 0 |
| PAU-01 | Pause rule mirrored with reopen criteria | contract | `bash scripts/ci/verify_roadmap_hygiene.sh` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `bash scripts/ci/verify_roadmap_hygiene.sh` [ASSUMED]
- **Per wave merge:** `docs-contracts-shift-left` local bundle [VERIFIED: codebase grep]
- **Phase gate:** Full docs-contract bundle green before `$gsd-verify-work` [VERIFIED: codebase grep]

### Wave 0 Gaps
- [ ] `scripts/ci/verify_roadmap_hygiene.sh` — required for BAK-01/BAK-02/PAU-01
- [ ] `scripts/ci/README.md` triage section for new verifier
- [ ] `.github/workflows/ci.yml` step wiring for new verifier in `docs-contracts-shift-left`

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Not in phase scope (docs/verification only) [VERIFIED: codebase grep] |
| V3 Session Management | no | Not in phase scope [VERIFIED: codebase grep] |
| V4 Access Control | no | Not in phase scope [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Use exact-string/regex policy checks in verifier to prevent ambiguous wording drift [VERIFIED: codebase grep] |
| V6 Cryptography | no | Not in phase scope [VERIFIED: codebase grep] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Policy drift that reopens broad scope unintentionally | Tampering | Merge-blocking docs contracts with explicit negative guards [VERIFIED: codebase grep] |
| Ambiguous planning status leading to incorrect roadmap decisions | Repudiation | Historical/dormant classification + traceability retention [VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/161-backlog-anchor-closure-pause-rule/161-CONTEXT.md` - locked decisions, discretion, and phase boundaries.
- `.planning/REQUIREMENTS.md` - BAK-01, BAK-02, PAU-01 requirement wording and traceability.
- `.planning/STATE.md` - current milestone posture and current focus.
- `scripts/ci/verify_stable_core_posture.sh` - verifier style and negative-guard precedent.
- `scripts/ci/verify_v1_17_friction_research_contract.sh` - planning SSOT contract precedent.
- `scripts/ci/README.md` - docs-contracts-shift-left triage conventions.
- `.github/workflows/ci.yml` - existing merge-blocking lane integration.
- `.planning/research/v1.17-FRICTION-INVENTORY.md` - historical anchor model and trigger vocabulary.
- `.planning/seeds/SEED-001-post-v1-36-linked-release-window.md` and `.planning/seeds/SEED-002-ecosystem-integrations.md` - seed status and reopening context.

### Secondary (MEDIUM confidence)
- `.planning/phases/160-stable-core-public-positioning/160-CONTEXT.md` - posture-language constraints and verifier integration pattern.
- `.planning/phases/159-linked-release-readiness-publish-proof/159-CONTEXT.md` - release proof boundary for SEED-001 historical classification.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - existing verifier and CI patterns are explicit in-repo.
- Architecture: HIGH - scope is locked and file ownership is explicit in context decisions.
- Pitfalls: MEDIUM - some causal explanations are inferred though mitigations are evidence-backed.

**Research date:** 2026-06-01
**Valid until:** 2026-07-01
