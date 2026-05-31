# Phase 160: Stable-Core Public Positioning - Research

**Researched:** 2026-05-31  
**Domain:** Public documentation posture alignment + docs CI contract hardening  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Public docs should explicitly say Accrue is stable-core / done enough for its declared scope and expands demand-driven from concrete evidence. Do not rely on quiet maintenance hints or release notes alone.
- **D-02:** Use "stable-core / demand-driven expansion" language, not "feature freeze", "maintenance only", or "no new features ever". The desired signal is stable public trust plus clear reopen criteria, not abandonment.
- **D-03:** The public posture should include the core reopen triggers already locked in project posture: concrete adopter failure mode, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change.
- **D-04:** Public copy should be adopter-facing and concrete: the canonical SaaS billing loop is complete, the documented facade is the stability boundary, and future work is proof, docs truth, support-contract hardening, maintenance, or justified expansion.
- **D-05:** Use a layered hub-and-spoke documentation spine rather than one giant canonical README. Each surface should own one job and link to the others.
- **D-06:** `README.md` owns first impression: project positioning, package map, proof posture summary, start-here links, and one concise stable-core statement.
- **D-07:** `accrue/README.md` owns the core package landing page: install contract, public API/support boundary summary, guide index, versioning expectations, and links to release notes / upgrade.
- **D-08:** `accrue/guides/first_hour.md` remains the canonical setup and evaluation spine: deps, install, runtime config, migrations, Oban, webhooks, admin, subscription proof, and bounded Braintree branch.
- **D-09:** `accrue/guides/jobs_to_be_done.md` owns the complete supported SaaS billing loop narrative: subscribe, change/cancel, recover failed payments, self-serve, gate access, operate with audit/proof.
- **D-10:** `accrue/guides/maturity-and-maintenance.md` owns the long-form stable-core / demand-driven expansion doctrine, evidence bar, stop rules, revisit triggers, and explicit non-goal posture.
- **D-11:** `accrue/guides/production-readiness.md` owns ship-readiness checklist and operational gates only; do not turn it into the posture SSOT.
- **D-12:** `accrue_admin/README.md` and `accrue_portal/README.md` should stay thin and package-specific: mount/config/ownership boundary plus links back to First Hour, Jobs to Be Done, and Maturity. They should not duplicate the full billing-loop narrative.
- **D-13:** `examples/accrue_host/README.md` and `examples/accrue_host/docs/adoption-proof-matrix.md` should remain proof vocabulary and evidence mirrors. They should point to canonical docs for semantics and policy instead of becoming their own support-boundary authorities.
- **D-14:** Public docs must carry all adopter-critical truth. `.planning/*` stays a maintainer mirror and should not be required reading for adopters.
- **D-15:** Keep one authoritative provider capability contract and thin mirrors. The existing `.planning/processor-support-matrix.md` remains the maintainer-facing capability SSOT unless downstream planning creates a generated/public excerpt; do not hand-maintain two full capability tables.
- **D-16:** Package READMEs own package-scope boundaries only: `accrue` owns billing engine/facades/docs, `accrue_admin` owns operator UI, `accrue_portal` owns mounted self-serve/local checkout UI, and host apps own Repo, migrations, Oban supervision, auth/session/runtime secrets, routing, and app-domain membership policy.
- **D-17:** Allowed mirrors are short: 3-6 lines in root/package READMEs and First Hour; proof-lane wording in host/adoption docs; release-note deltas for changed capabilities. Each mirror should link back to the canonical boundary source.
- **D-18:** Forbidden duplication: full row-by-row capability tables outside the canonical source; reworded support labels that introduce new synonyms; long planning-posture prose pasted into package docs; release notes pretending to be the static support contract.
- **D-19:** Provider labels must stay capability-explicit and provider-honest. Stripe remains the first-user production path, Fake remains deterministic merge-blocking proof, and Braintree remains the bounded gateway subscription core path. Any processor-surface change must update behavior, support matrix, docs, examples/verifiers, and release notes together.
- **D-20:** Add a dedicated stable-core posture verifier rather than stuffing this concern into `verify_package_docs.sh`. The recommended contract is a new `scripts/ci/verify_stable_core_posture.sh` with its own failure prefix and triage section.
- **D-21:** Wire the posture verifier into `docs-contracts-shift-left` and document it in `scripts/ci/README.md` alongside the existing package-doc, support-matrix, adoption-proof, and release-note gates.
- **D-22:** The verifier should use the repo's established bash style: `require_fixed`, `require_regex`, `require_absent_regex`, explicit stderr prefix, and narrow intentional substrings rather than broad terms like `stable`.
- **D-23:** The posture verifier should assert stable-core anchors across the public/mirror surfaces required by POS-03: root README, `accrue/README.md`, `accrue/guides/maturity-and-maintenance.md`, `accrue/guides/jobs_to_be_done.md`, `accrue/guides/release-notes.md`, `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/processor-support-matrix.md`, and `examples/accrue_host/docs/adoption-proof-matrix.md`.
- **D-24:** Extend `scripts/ci/verify_release_notes_contract.sh` only lightly: require a release-note posture token such as "stable-core posture" plus a pointer back to maturity/support-boundary docs. Do not couple all posture checks to version headings or force unrelated PRs through release-note edits.
- **D-25:** Optional ExUnit coverage, if added, should shell out to the bash verifier instead of re-encoding all needles in Elixir. Avoid dual-contract drift between bash and tests.
- **D-26:** Add negative guards for retired or dangerous posture terms if they appear during implementation, especially "feature freeze", "no new features ever", or public wording that implies planning internals are required to understand support boundaries.

### the agent's Discretion
- Downstream agents may choose exact copy as long as it preserves the decisions above, keeps the docs layered by ownership, and keeps wording adopter-facing rather than planning-jargon-heavy.
- Downstream agents may decide whether to introduce a public "support boundaries" guide or generated excerpt only if it does not create a second hand-maintained capability SSOT. The conservative default is thin public mirrors plus canonical matrix pointers.
- Downstream agents may choose exact verifier needles, but must keep them narrow, explainable, and low-churn. Prefer a small set of load-bearing posture phrases over brittle paragraph-length literals.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within Phase 160 stable-core public positioning scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| POS-01 | Public docs/READMEs communicate stable-core + demand-driven expansion posture. | Stable-core wording anchors + dedicated posture verifier contract. [VERIFIED: codebase grep] |
| POS-02 | Adopters can see complete billing loop + processor boundaries + ownership boundaries without planning docs. | Hub-and-spoke doc ownership map + thin mirror rules across READMEs and guides. [VERIFIED: codebase grep] |
| POS-03 | Release notes, package docs, support matrix, adoption proof docs, and planning mirrors stay aligned. | New `verify_stable_core_posture.sh` + CI wiring + light release-notes token extension. [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 160 should be planned as a docs-contract alignment phase, not a product phase: the repo already has stable-core language and support-boundary surfaces, but posture consistency is not yet enforced by a dedicated verifier. [VERIFIED: codebase grep]

The strongest implementation path is to keep the existing layered docs ownership, add one focused stable-core posture verifier, and wire it into `docs-contracts-shift-left` so drift is caught pre-merge. [VERIFIED: codebase grep]

**Primary recommendation:** Implement one small, explicit posture contract (`verify_stable_core_posture.sh`) and update only load-bearing public mirrors so POS-01/02/03 become mechanically verifiable. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Public positioning statement | Documentation tier (root/package READMEs + guides) | CI contract scripts | Public truth must be readable without planning internals. [VERIFIED: codebase grep] |
| Processor support boundary truth | Planning SSOT (`.planning/processor-support-matrix.md`) | Thin public mirrors | Existing model already uses one canonical matrix and mirror guards. [VERIFIED: codebase grep] |
| Posture drift prevention | CI (`docs-contracts-shift-left`) | Bash verifier scripts | Existing docs contracts run here; posture gate belongs in same lane. [VERIFIED: codebase grep] |
| Release-note posture continuity | `accrue/guides/release-notes.md` | `verify_release_notes_contract.sh` | Existing release-note gate is already active and can carry a light posture token check. [VERIFIED: codebase grep] |
| Planning/public mirror parity | `.planning/*` + public docs | Posture verifier | POS-03 requires explicit cross-surface consistency. [VERIFIED: codebase grep] |

## Standard Stack

### Core
| Library/Tool | Version | Purpose | Why Standard |
|--------------|---------|---------|--------------|
| Bash verifier pattern (`require_fixed/regex/absent`) | Existing repo pattern | Enforce deterministic doc substrings | Already used by `verify_package_docs.sh` and related gates. [VERIFIED: codebase grep] |
| GitHub Actions job `docs-contracts-shift-left` | Existing repo workflow | Merge-blocking docs/support contract execution | Canonical CI home for docs truth gates. [VERIFIED: codebase grep] |
| Markdown docs spine (`README`, package READMEs, guides) | Existing repo docs | Adopter-facing source of truth | Current phase scope is docs posture alignment only. [VERIFIED: codebase grep] |

### Supporting
| Library/Tool | Version | Purpose | When to Use |
|--------------|---------|---------|-------------|
| `scripts/ci/verify_package_docs.sh` | Existing repo script | Package docs + host/readme literals | Keep for package/link contract; do not overload with posture SSOT. [VERIFIED: codebase grep] |
| `scripts/ci/verify_release_notes_contract.sh` | Existing repo script | Release notes freshness | Add only a narrow posture token + pointer check. [VERIFIED: codebase grep] |
| `scripts/ci/README.md` | Existing repo doc | Gate map + triage rules | Add stable-core gate ownership and failure triage here. [VERIFIED: codebase grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Dedicated posture verifier | Add more checks inside `verify_package_docs.sh` | Higher coupling/churn and weaker triage clarity. [VERIFIED: codebase grep] |
| Thin mirrors + one matrix SSOT | Duplicate full matrix in public docs | Creates dual-SSOT drift risk, violating locked decisions. [VERIFIED: codebase grep] |

## Package Legitimacy Audit

No new external package installation is required for Phase 160; package legitimacy gate is not applicable to this phase scope. [VERIFIED: codebase grep]

## Architecture Patterns

### System Architecture Diagram

```text
Public docs surfaces (README + package READMEs + guides + host proof docs)
        |
        v
Stable-core posture literals + support-boundary mirror links
        |
        +----------------------+
        |                      |
        v                      v
verify_stable_core_posture.sh  verify_release_notes_contract.sh (light extension)
        |                      |
        +----------+-----------+
                   v
      GitHub Actions: docs-contracts-shift-left (merge-blocking)
                   |
                   v
        Drift prevented before merge (POS-03 proof)
```

### Recommended Project Structure
```text
scripts/ci/
├── verify_stable_core_posture.sh    # New dedicated posture gate
├── verify_package_docs.sh           # Existing package docs gate
├── verify_release_notes_contract.sh # Existing release-notes gate (light posture token check)
└── README.md                         # Contract map + triage
```

### Pattern 1: Load-Bearing Phrase Contract
**What:** Pin a small set of precise posture phrases across required surfaces, with explicit negative guards for disallowed phrasing. [VERIFIED: codebase grep]  
**When to use:** POS-01 and POS-03 guarantees across multi-doc mirrors. [VERIFIED: codebase grep]

### Pattern 2: Layered Docs Ownership
**What:** Keep each document surface scoped to one job and link outward instead of duplicating full narratives. [VERIFIED: codebase grep]  
**When to use:** POS-02 clarity for adopters across root/package/guides/proof docs. [VERIFIED: codebase grep]

### Anti-Patterns to Avoid
- **Posture in planning-only language:** violates adopter-facing requirement and D-14. [VERIFIED: codebase grep]
- **Broad keyword checks (e.g., `stable`)**: creates flaky/fuzzy verification and high churn. [VERIFIED: codebase grep]
- **Capability-table duplication:** creates second SSOT and drift risk. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Posture drift detection | Manual review checklist only | Bash verifier + CI gate | Deterministic and merge-blocking. [VERIFIED: codebase grep] |
| Release-note posture sync | Full new parser/framework | Small `grep`-based extension in existing verifier | Matches repo pattern and keeps maintenance low. [VERIFIED: codebase grep] |
| Support-boundary visibility | New duplicated docs tree | Existing SSOT matrix + thin mirrors | Preserves one contract source. [VERIFIED: codebase grep] |

## Common Pitfalls

### Pitfall 1: Abandonment wording drift
**What goes wrong:** Docs imply freeze/abandonment instead of demand-driven evolution. [VERIFIED: codebase grep]  
**Why it happens:** Unbounded copy edits across many surfaces. [VERIFIED: codebase grep]  
**How to avoid:** Add explicit disallowed-term guards in the posture verifier. [VERIFIED: codebase grep]  
**Warning signs:** Terms like “feature freeze” or “no new features ever” appear in public docs. [VERIFIED: codebase grep]

### Pitfall 2: Planning-internal dependency leak
**What goes wrong:** Adopters must read `.planning/*` to understand support boundaries. [VERIFIED: codebase grep]  
**Why it happens:** Public docs link to planning as normative source rather than mirror/pointer. [VERIFIED: codebase grep]  
**How to avoid:** Keep adopter-critical contract text on public surfaces and use planning as maintainer mirror. [VERIFIED: codebase grep]  
**Warning signs:** Package docs defer boundary truth to planning docs without local summary. [VERIFIED: codebase grep]

### Pitfall 3: Release notes become static contract
**What goes wrong:** Release notes drift into SSOT role and conflict with stable boundary docs. [VERIFIED: codebase grep]  
**Why it happens:** Over-expanding `verify_release_notes_contract.sh`. [VERIFIED: codebase grep]  
**How to avoid:** Keep release-note checks light: posture token + pointer to canonical docs. [VERIFIED: codebase grep]
**Warning signs:** Large policy text starts living only under version sections. [VERIFIED: codebase grep]

## Code Examples

### New posture verifier skeleton
```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}

fail() { echo "verify_stable_core_posture: $*" >&2; exit 1; }
require_fixed() { grep -Fq "$2" "$1" || fail "$1 missing: $2"; }
require_absent_regex() { grep -Eq "$2" "$1" && fail "$1 must not match: $2"; }

require_fixed "$ROOT_DIR/README.md" "stable-core / demand-driven expansion"
require_fixed "$ROOT_DIR/accrue/guides/maturity-and-maintenance.md" "done enough"
require_fixed "$ROOT_DIR/accrue/guides/jobs_to_be_done.md" "supported SaaS billing loop"
require_absent_regex "$ROOT_DIR/README.md" "feature freeze|no new features ever"
```
Source: existing script style in `scripts/ci/verify_package_docs.sh`. [VERIFIED: codebase grep]

### CI wiring pattern
```yaml
- name: Stable-core posture contract
  run: bash scripts/ci/verify_stable_core_posture.sh
```
Source: existing `docs-contracts-shift-left` step style in `.github/workflows/ci.yml`. [VERIFIED: codebase grep]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Posture mostly conveyed by prose and planning docs | Explicit stable-core posture in public docs + verifier-backed drift control | v1.48 Phase 160 target | Converts posture from narrative intent to executable contract. [VERIFIED: codebase grep] |
| Mixed docs ownership risk | Layered hub-and-spoke ownership with thin mirrors | Already established and reaffirmed in 160 context | Reduces duplication and adopter confusion. [VERIFIED: codebase grep] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Existing repository grep-based verification style remains preferred over parser-heavy alternatives for docs contracts. [ASSUMED] | Standard Stack | Low; if style changes, implementation can still satisfy POS requirements with another deterministic gate. |

## Open Questions

1. **Should public docs add a standalone support-boundaries guide?**
   - What we know: locked decisions allow it only if no second hand-maintained SSOT is created. [VERIFIED: codebase grep]
   - What's unclear: whether current thin-mirror coverage is sufficient after copy alignment. [VERIFIED: codebase grep]
   - Recommendation: default to thin mirrors in this phase; only add a guide if planner identifies a concrete adopter-comprehension gap. [VERIFIED: codebase grep]

## Environment Availability

Step 2.6: SKIPPED (no external runtime/service dependencies identified for Phase 160 beyond existing repo docs + CI script surfaces). [VERIFIED: codebase grep]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Bash contract scripts executed by GitHub Actions |
| Config file | `.github/workflows/ci.yml` |
| Quick run command | `bash scripts/ci/verify_stable_core_posture.sh && bash scripts/ci/verify_release_notes_contract.sh` |
| Full suite command | CI required jobs including `docs-contracts-shift-left`, `release-manifest-ssot`, `release-gate`, `host-integration` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| POS-01 | Public stable-core posture is explicit | contract | `bash scripts/ci/verify_stable_core_posture.sh` | ❌ Wave 0 |
| POS-02 | Billing loop/support/ownership boundaries are visible on adopter surfaces | contract | `bash scripts/ci/verify_stable_core_posture.sh` | ❌ Wave 0 |
| POS-03 | Mirrors stay aligned across docs/release notes/planning surfaces | contract | `bash scripts/ci/verify_stable_core_posture.sh && bash scripts/ci/verify_release_notes_contract.sh` | ❌ Wave 0 / ✅ existing release notes gate |

### Sampling Rate
- **Per task commit:** `bash scripts/ci/verify_stable_core_posture.sh`
- **Per wave merge:** run full `docs-contracts-shift-left` local equivalent
- **Phase gate:** required CI jobs green on PR

### Wave 0 Gaps
- [ ] `scripts/ci/verify_stable_core_posture.sh` — new posture contract gate
- [ ] `.github/workflows/ci.yml` — add stable-core posture step under `docs-contracts-shift-left`
- [ ] `scripts/ci/README.md` — triage + REQ mapping entry for POS-01..03

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | n/a (docs posture phase) |
| V3 Session Management | no | n/a |
| V4 Access Control | yes | Merge-blocking CI gates and protected PR workflow approvals. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Narrow literal/regex checks in bash verifiers reduce ambiguous policy interpretation. [VERIFIED: codebase grep] |
| V6 Cryptography | no | n/a |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Public claim drift vs actual support boundary | Tampering | Merge-blocking docs posture verifier + matrix verifier + release-notes gate. [VERIFIED: codebase grep] |
| Ambiguous support statements that over-promise | Repudiation | Capability-explicit labels + thin-mirror policy + disallowed-term checks. [VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)
- Repository sources inspected directly: `README.md`, `accrue/README.md`, `accrue_admin/README.md`, `accrue_portal/README.md`, `accrue/guides/*`, `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/processor-support-matrix.md`, `examples/accrue_host/*`, `.github/workflows/ci.yml`, `scripts/ci/README.md`, `scripts/ci/verify_package_docs.sh`, `scripts/ci/verify_release_notes_contract.sh`. [VERIFIED: codebase grep]
- `.planning/phases/160-stable-core-public-positioning/160-CONTEXT.md` locked decisions and canonical refs. [VERIFIED: codebase grep]
- Phase 159 dependency artifacts (`159-CONTEXT.md`, `159-RESEARCH.md`, `159-01-SUMMARY.md`, `159-02-SUMMARY.md`). [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)
- None.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - existing in-repo scripts/workflow patterns are explicit.
- Architecture: HIGH - doc ownership and CI integration points are already established.
- Pitfalls: HIGH - directly derived from locked decisions and current verifier boundaries.

**Research date:** 2026-05-31  
**Valid until:** 2026-06-30
