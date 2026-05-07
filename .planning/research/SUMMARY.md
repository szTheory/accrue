# v1.36 Research Summary — Dual-Provider Core Completion

## Milestone Thesis

`v1.36` should close the remaining staged rows in Accrue's official Stripe + Braintree gateway-subscription-core contract. The repo already ships most of the runtime behavior; the remaining work is to make the contract honest, fully first-party where intended, and drift-resistant.

## Key Findings

**Stack additions:** none. This is brownfield contract closure using the existing capability map, adapters, billing facade, and proof lanes.

**Feature table stakes:**
- Promote `Accrue.Billing.update_customer/2` from staged to explicit first-party support.
- Normalize cancellation support language so shipped behavior and support labels agree.
- Align `.planning/processor-support-matrix.md`, runtime labels, docs, and example-host proof artifacts.
- Back the promoted rows with deterministic proof and drift gates.

**Watch out for:**
- Do not let cancellation cleanup turn into broad lifecycle expansion.
- Do not promote any row without merge-blocking proof.
- Do not leave matrix/runtime/doc mismatches after the milestone closes.

## Recommendation

Use a three-phase roadmap:
1. Customer update contract closure
2. Cancellation semantics closure
3. Contract drift gate closeout
