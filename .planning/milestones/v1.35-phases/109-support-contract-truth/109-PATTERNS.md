# Phase 109: Support Contract Truth - Pattern Map

**Mapped:** 2026-05-06
**Files analyzed:** 15
**Analogs found:** 15 / 15

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/processor-support-matrix.md` | support-ssot | canonical contract | same file | exact |
| `README.md` | docs | repo front door | same file | exact |
| `accrue/README.md` | docs | package front door | same file | exact |
| `.planning/ROADMAP.md` | planning mirror | milestone truth | same file | exact |
| `.planning/PROJECT.md` | planning mirror | strategic posture | same file | exact |
| `accrue/guides/first_hour.md` | docs | onboarding spine | same file | exact |
| `accrue/guides/braintree-local-portal.md` | docs | canonical deep guide | same file | exact |
| `accrue/guides/production-readiness.md` | docs | checklist | same file | exact |
| `accrue/guides/telemetry.md` | docs | operator signals | same file | exact |
| `accrue_portal/README.md` | package docs | mounted package contract | same file | exact |
| `examples/accrue_host/README.md` | proof docs | host mirror | same file | exact |
| `examples/accrue_host/docs/adoption-proof-matrix.md` | proof docs | realism/proof matrix | same file | exact |
| `scripts/ci/README.md` | contributor map | co-update rulebook | same file | exact |
| `scripts/ci/verify_package_docs.sh`, `scripts/ci/verify_verify01_readme_contract.sh`, `scripts/ci/verify_adoption_proof_matrix.sh` | verifier | docs contract | same files | exact |
| `scripts/ci/verify_processor_support_matrix.sh` | verifier | support truth anchor | same file | exact |

## Pattern Assignments

### Public and planning mirrors

**Pattern:** one canonical wording, many mirrors

- `.planning/processor-support-matrix.md` is the support SSOT.
- `README.md`, `accrue/README.md`, `.planning/ROADMAP.md`, and `.planning/PROJECT.md` should mirror its contract without expanding scope or inventing new capability language.

**Execution implication:** write the provider-honest checkout/portal wording once in the matrix and then mirror it almost verbatim in the front-door and planning files.

### First Hour plus deep-guide layering

**Pattern:** short branch in the spine, detailed truth in one deep guide

- `accrue/guides/first_hour.md` should stay the spine and add one early Braintree branch plus minimum setup contract.
- `accrue/guides/braintree-local-portal.md` should own the deeper mounted-path explanation and failure-mode detail.
- `accrue_portal/README.md` should stay concise and package-scoped.

**Execution implication:** do not duplicate full Braintree setup prose in First Hour or the portal README; point both toward `braintree-local-portal.md` after introducing the key contract bullets.

### Checklist and telemetry surfaces

**Pattern:** operator prompts, not full tutorials

- `accrue/guides/production-readiness.md` should contain ship-order checklist bullets.
- `accrue/guides/telemetry.md` should anchor emitted tuples and operator signal interpretation, not become the main setup guide.

**Execution implication:** add mounted-path readiness and failure semantics as concise checklist/signal entries, then link to the deeper guide where needed.

### Example-host mirror discipline

**Pattern:** proof/reference mirror, never source-of-truth replacement

- `examples/accrue_host/README.md` should mirror package truth and remain explicit that Sigra-specific choices are demo-only.
- `examples/accrue_host/docs/adoption-proof-matrix.md` should describe realism/proof posture, not redefine capability boundaries.

**Execution implication:** update the host/example docs only after the package/support-matrix wording is settled, and keep them framed as proof/reference surfaces.

### Verifier update pattern

**Pattern:** same-PR doc and gate alignment

- `verify_processor_support_matrix.sh` already encodes the desired support truth.
- `verify_package_docs.sh`, `verify_verify01_readme_contract.sh`, and `verify_adoption_proof_matrix.sh` still pin stale Stripe-only wording.
- `scripts/ci/README.md` is the human explanation of the same co-update rule.

**Execution implication:** finish the phase by updating the bash needles and the contributor-map prose together, and preserve the exact string literals that the new docs should carry.

## Planner Notes

- Reference `.planning/processor-support-matrix.md` explicitly in every plan action that changes checkout/portal support wording.
- Keep the support-matrix/public-doc mirror work ahead of onboarding and example-host work.
- Put bash verifier changes in the final plan so they validate the final wording rather than a temporary intermediate state.

---

*Phase: 109-support-contract-truth*
*Pattern map completed: 2026-05-06*
