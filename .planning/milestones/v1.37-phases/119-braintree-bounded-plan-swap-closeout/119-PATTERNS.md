# Phase 119: Patterns

## Reusable Repo Patterns

### Pattern 1: Runtime/support truth first, mirrors second, gates third

Use recent support-contract phases as the planning analog:

- Phase 109: support-mirror coherence and example-host alignment
- Phase 114: canonical matrix + thin public mirrors + verifier bundle
- Phase 117: named active-subscription-change contract + support-contract bundle

For Phase 119, the analogous sequence is:

1. confirm and harden the bounded Braintree swap-only truth
2. align docs and proof mirrors
3. pin the final wording in drift gates

### Pattern 2: Shared copy seams for provider-honest UI wording

- `accrue_admin/lib/accrue_admin/copy/subscription.ex`
- `accrue_portal/lib/accrue_portal/copy.ex`

When Braintree operator or customer wording changes, update shared copy helpers
first and then refresh the LiveView tests that pin those strings.

### Pattern 3: Support matrix as public SSOT

`.planning/processor-support-matrix.md` is the canonical support contract. Thin
mirrors should defer to it rather than restating new taxonomy in each doc.

### Pattern 4: Thin host proof mirrors

`examples/accrue_host/README.md` and
`examples/accrue_host/docs/adoption-proof-matrix.md` are proof/reference
surfaces. They should mirror the package-facing contract and point back to the
matrix instead of becoming a second source of truth.

### Pattern 5: Bash verifiers as merge-blocking substring gates

The support-contract bundle already uses bash substring checks to make wording
drift merge-blocking:

- `scripts/ci/verify_processor_support_matrix.sh`
- `scripts/ci/verify_package_docs.sh`
- `scripts/ci/verify_verify01_readme_contract.sh`
- `scripts/ci/verify_adoption_proof_matrix.sh`

When the contract wording changes intentionally, update these needles in the
same PR.

## Phase-Specific Guidance

- Do not broaden Braintree support in order to make the wording simpler.
- Prefer explicit `:plan_resolver` setup guidance over vague "configure your
  app correctly" copy.
- Keep portal wording conservative; Phase 119 is a closeout pass, not a new
  self-serve Braintree product surface.
- Make CI fail on both parity creep and weakened bounded-swap wording.
