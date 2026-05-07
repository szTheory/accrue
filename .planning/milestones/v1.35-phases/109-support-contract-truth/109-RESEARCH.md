# Phase 109: Support Contract Truth - Research

**Researched:** 2026-05-06
**Domain:** provider-honest support contract, mounted Braintree setup guidance, and support-doc drift closure
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Public docs must describe checkout and billing portal as one shared facade with provider-honest behavior, not as Stripe-only surfaces.
- **D-02:** `Accrue.Billing.create_checkout_session/2` and `Accrue.Billing.create_billing_portal_session/2` must be described as first-party on both Stripe and Braintree:
  - Stripe returns upstream hosted URLs.
  - Braintree returns mounted first-party local URLs.
- **D-03:** Stripe remains the fastest first-user production path, but that framing cannot override the shipped dual-provider contract.
- **D-04:** Docs must avoid implying identical UX or full processor parity.
- **D-05:** `accrue/guides/first_hour.md` remains the canonical onboarding spine.
- **D-06:** First Hour should stay Fake/Stripe-first, then branch early and explicitly into the mounted Braintree contract.
- **D-07:** The Braintree branch must call out the minimum setup contract: `accrue_portal`, sibling mount, `portal_mount_path`, absolute `portal_base_url`, auth/session, and CSP / Hosted Fields.
- **D-08:** `accrue/guides/braintree-local-portal.md` stays the SSOT for the mounted Braintree path; hand-rolled guidance remains the escape hatch.
- **D-09:** High-probability Braintree failure modes belong in front-door docs, not only in troubleshooting.
- **D-10:** Setup-contract failures that must be surfaced early include `portal_base_url`, `portal_mount_path`, auth/session continuity, Hosted Fields CSP, no upstream hosted fallback, discount preview provisionality, and local completion semantics.
- **D-11:** Deep remediation belongs in troubleshooting/runbooks rather than duplicated inline.
- **D-12:** `examples/accrue_host` remains proof/reference, not the primary Hex-consumer install story.
- **D-13:** The example host should still demonstrate the mounted Braintree contract clearly.
- **D-14:** Package docs and guides remain the adoption SSOT; the example host mirrors and proves them.
- **D-16:** README, package README, First Hour, support matrix, Braintree guide, and example-host docs must move together when wording changes.
- **D-17:** One shared provider-behavior table should anchor the front-door docs.
- **D-18:** The support matrix remains the canonical support SSOT.

### the agent's Discretion

- Exact placement of the shared provider-behavior table.
- Exact phrasing in each doc, as long as the same support truth appears everywhere.
- Exact split between setup-contract bullets in front-door docs and deeper remediation in troubleshooting/runbooks.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SUP-01 | Public package docs, support matrix, and planning mirrors MUST state one provider-honest contract for checkout, billing portal, and the official Stripe + Braintree facade surface. | Several public and proof-facing docs still say checkout and billing portal are Stripe-only even though the support matrix and portal docs already describe the shipped provider-honest contract. [VERIFIED: `accrue/README.md`, `examples/accrue_host/README.md`, `examples/accrue_host/docs/adoption-proof-matrix.md`, `.planning/processor-support-matrix.md`] |
| SUP-02 | First-hour and host-facing guidance MUST document the mounted Braintree portal/checkout setup contract, including `portal_base_url`, `portal_mount_path`, auth/CSP expectations, and the sharp failure modes adopters need to diagnose. | The mounted-path details exist, but they are fragmented: `accrue_portal/README.md` and `braintree-local-portal.md` contain some of the truth while First Hour, production guidance, telemetry references, and example-host docs do not present one coherent setup contract. [VERIFIED: `accrue/guides/first_hour.md`, `accrue/guides/braintree-local-portal.md`, `accrue_portal/README.md`, `accrue/guides/production-readiness.md`, `accrue/guides/telemetry.md`] |
</phase_requirements>

## Summary

Phase 109 is a support-contract consolidation phase, not a capability phase. The codebase already ships the dual-provider truth: the processor support matrix explicitly says Stripe returns upstream hosted checkout/portal URLs while Braintree returns mounted first-party local checkout/portal URLs, and `accrue_portal` documents the Braintree mounted-path requirements. [VERIFIED: `.planning/processor-support-matrix.md`, `accrue_portal/README.md`]

The drift is mostly in public-facing mirrors and proof docs. `accrue/README.md`, `examples/accrue_host/README.md`, and `examples/accrue_host/docs/adoption-proof-matrix.md` still say checkout and billing portal are Stripe-only, which now contradicts the support matrix, portal package docs, and the v1.35 phase context. [VERIFIED: `accrue/README.md`, `examples/accrue_host/README.md`, `examples/accrue_host/docs/adoption-proof-matrix.md`, `.planning/milestones/v1.35-phases/109-support-contract-truth/109-CONTEXT.md`]

The onboarding and operator docs are also only partially aligned. First Hour still frames checkout and billing portal as Stripe-hosted helpers without an early Braintree branch or a minimum mounted-path setup checklist. `braintree-local-portal.md` has some of the right material, but it still overemphasizes the hand-rolled escape hatch and does not yet read like the canonical SSOT for the packaged mounted path. `production-readiness.md` and `telemetry.md` mention Stripe-first concerns but do not yet expose the Braintree mounted-path setup contract and sharp failure semantics prominently enough for adopters. [VERIFIED: `accrue/guides/first_hour.md`, `accrue/guides/braintree-local-portal.md`, `accrue/guides/production-readiness.md`, `accrue/guides/telemetry.md`]

The shift-left gates are part of the work, not afterthoughts. `verify_package_docs.sh`, `verify_verify01_readme_contract.sh`, and `verify_adoption_proof_matrix.sh` currently pin stale Stripe-only checkout/portal wording; `verify_processor_support_matrix.sh` already encodes the new contract and can act as the truth anchor. Phase 109 therefore needs one final slice that updates example-host mirrors and the bash gates together so the repo stops reintroducing stale support wording. [VERIFIED: `scripts/ci/verify_package_docs.sh`, `scripts/ci/verify_verify01_readme_contract.sh`, `scripts/ci/verify_adoption_proof_matrix.sh`, `scripts/ci/verify_processor_support_matrix.sh`, `scripts/ci/README.md`]

**Primary recommendation:** plan Phase 109 as three wave-ordered slices:
1. support-SSOT and public/planning mirrors
2. onboarding + mounted Braintree guidance
3. example-host mirrors + shift-left verifier alignment

That shape keeps the support truth stable before branching it into onboarding copy, then locks it in with example-host mirrors and CI gates.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Official provider-honest support contract | `.planning/processor-support-matrix.md` | package README, root README, planning mirrors | The support matrix is the canonical support SSOT; all mirrors should derive their wording from it. |
| First-user onboarding story | `accrue/guides/first_hour.md` | `accrue/guides/braintree-local-portal.md`, `accrue_portal/README.md` | First Hour should surface the branch and minimum contract, then point into the deeper Braintree guide. |
| Mounted Braintree integration truth | `accrue/guides/braintree-local-portal.md` | `accrue_portal/README.md` | One deep guide should own the packaged path, with the portal README carrying a concise package-level contract. |
| Host-facing proof/reference story | `examples/accrue_host/README.md` | `examples/accrue_host/docs/adoption-proof-matrix.md` | The example host proves and mirrors package truth; it must not redefine support boundaries. |
| Drift prevention | `scripts/ci/verify_processor_support_matrix.sh` plus updated docs gates | `scripts/ci/README.md` | The scripts are the merge-adjacent contract that prevents support wording regressions. |

## Project Constraints

- Preserve the existing strategy posture: Stripe-first first-user path, bounded dual-provider core, no parity theater, no new processors. [VERIFIED: `.planning/PROJECT.md`, `.planning/STRATEGY.md`]
- Keep package docs as the adoption SSOT; do not let `examples/accrue_host` become the primary install guide. [VERIFIED: `.planning/milestones/v1.35-phases/109-support-contract-truth/109-CONTEXT.md`, `accrue/README.md`]
- Present setup-contract failures early, but keep long remediation in troubleshooting/runbooks. [VERIFIED: `.planning/milestones/v1.35-phases/109-support-contract-truth/109-CONTEXT.md`, `accrue/guides/troubleshooting.md`]
- Maintain same-PR co-update discipline for First Hour, host README, adoption matrix, and bash verifiers. [VERIFIED: `scripts/ci/README.md`, `scripts/ci/verify_package_docs.sh`, `scripts/ci/verify_verify01_readme_contract.sh`, `scripts/ci/verify_adoption_proof_matrix.sh`]

## Current-State Findings

### Public support wording still drifts

- `accrue/README.md` still says `create_checkout_session/2` and `create_billing_portal_session/2` remain Stripe-only. [VERIFIED: `accrue/README.md`]
- `examples/accrue_host/README.md` repeats the same stale Stripe-only claim. [VERIFIED: `examples/accrue_host/README.md`]
- `examples/accrue_host/docs/adoption-proof-matrix.md` also repeats the stale Stripe-only claim. [VERIFIED: `examples/accrue_host/docs/adoption-proof-matrix.md`]

### Braintree mounted-path setup truth is fragmented

- `accrue_portal/README.md` already states `portal_mount_path`, absolute `portal_base_url`, and local checkout return-shape expectations. [VERIFIED: `accrue_portal/README.md`]
- `accrue/guides/braintree-local-portal.md` contains useful Braintree-specific detail, but it still frames the guide as the hand-rolled escape hatch instead of clearly leading with the packaged mounted path. [VERIFIED: `accrue/guides/braintree-local-portal.md`]
- `accrue/guides/first_hour.md` lacks the explicit early Braintree branch and minimum mounted-path checklist required by D-06/D-07. [VERIFIED: `accrue/guides/first_hour.md`]

### Failure-mode guidance is not surfaced consistently enough

- The mounted-path docs already mention `portal_mount_path`, `portal_base_url`, and Hosted Fields, but the support contract does not yet expose all high-probability failures in one early, front-door place. [VERIFIED: `accrue_portal/README.md`, `accrue/guides/braintree-local-portal.md`]
- `production-readiness.md` and `telemetry.md` still read mostly Stripe-first and do not yet clearly orient operators around mounted Braintree checkout/portal setup and local completion semantics. [VERIFIED: `accrue/guides/production-readiness.md`, `accrue/guides/telemetry.md`]

### The verifier scripts encode stale wording

- `verify_package_docs.sh` pins First Hour and host README literals for checkout and billing portal, so any support-contract rewrite must update it in the same PR. [VERIFIED: `scripts/ci/verify_package_docs.sh`]
- `verify_verify01_readme_contract.sh` and `verify_adoption_proof_matrix.sh` currently anchor stale host/example wording. [VERIFIED: `scripts/ci/verify_verify01_readme_contract.sh`, `scripts/ci/verify_adoption_proof_matrix.sh`]
- `verify_processor_support_matrix.sh` already represents the desired provider-honest wording and is the strongest existing truth anchor for the phase. [VERIFIED: `scripts/ci/verify_processor_support_matrix.sh`]

## Validation Architecture

### Primary docs-contract lane

```bash
bash scripts/ci/verify_processor_support_matrix.sh
bash scripts/ci/verify_package_docs.sh
bash scripts/ci/verify_verify01_readme_contract.sh
bash scripts/ci/verify_adoption_proof_matrix.sh
```

This is the primary verification lane because the phase is about support truth and drift prevention across docs, planning mirrors, and example-host proof surfaces.

### Focused contract grep lane

```bash
rg -n "Stripe returns upstream hosted URLs|Braintree returns mounted first-party local|portal_base_url|portal_mount_path|Hosted Fields|discount preview|checkout completion" \
  README.md \
  accrue/README.md \
  accrue/guides/first_hour.md \
  accrue/guides/braintree-local-portal.md \
  accrue/guides/production-readiness.md \
  accrue/guides/telemetry.md \
  accrue_portal/README.md \
  examples/accrue_host/README.md \
  examples/accrue_host/docs/adoption-proof-matrix.md \
  .planning/ROADMAP.md \
  .planning/PROJECT.md \
  .planning/processor-support-matrix.md
```

Use this lane to confirm the same support language and minimum setup-contract terms appear across every touched mirror.

### Negative drift lane

```bash
rg -n "Stripe-only|remain Stripe-only" \
  accrue/README.md \
  examples/accrue_host/README.md \
  examples/accrue_host/docs/adoption-proof-matrix.md
```

The phase should end with no stale Stripe-only checkout/portal wording in the public/package/example-host mirrors.

## Open Questions (RESOLVED)

- **Should Phase 109 update code or runtime behavior?** No. The shipped runtime contract already exists; the gap is documentation, support framing, and verifier drift. [VERIFIED: `.planning/processor-support-matrix.md`, `accrue_portal/README.md`]
- **Should example-host docs become the primary Braintree install story?** No. Package docs remain the adoption SSOT; example-host docs should mirror and prove, not lead. [VERIFIED: `.planning/milestones/v1.35-phases/109-support-contract-truth/109-CONTEXT.md`]
- **Should troubleshooting/runbook material be duplicated into First Hour?** No. First Hour should surface the setup-contract failures and point to deeper troubleshooting material instead of cloning it inline. [VERIFIED: `accrue/guides/first_hour.md`, `.planning/milestones/v1.35-phases/109-support-contract-truth/109-CONTEXT.md`]

## Plan Shape Recommendation

| Plan | Focus | Why it should be separate |
|------|-------|---------------------------|
| 109-01 | support SSOT + public/planning mirrors | Establish the canonical wording first so later docs and verifiers have a stable target. |
| 109-02 | First Hour + mounted Braintree setup/failure guidance | The onboarding and operator story should branch from the settled support contract rather than invent its own language. |
| 109-03 | example-host mirrors + bash gates | The proof docs and verifiers must update together at the end to prevent drift from reappearing. |

---

*Phase: 109-support-contract-truth*
*Research completed: 2026-05-06*
