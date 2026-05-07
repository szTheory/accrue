# v1.36 Architecture Research — Dual-Provider Core Completion

## Integration Points

1. **Capability SSOT**
   - `accrue/lib/accrue/processor/capabilities.ex`
   - `.planning/processor-support-matrix.md`

2. **Facade semantics**
   - `accrue/lib/accrue/billing.ex`
   - `accrue/lib/accrue/billing/subscription_actions.ex`

3. **Adapter truth**
   - `accrue/lib/accrue/processor/fake.ex`
   - `accrue/lib/accrue/processor/stripe.ex`
   - `accrue/lib/accrue/processor/braintree.ex`

4. **Proof lanes**
   - `accrue/test/accrue/processor/capabilities_test.exs`
   - `accrue/test/accrue/billing/**/*`
   - `examples/accrue_host/test/**/*`

## Suggested Build Order

1. Close customer-update contract truth.
2. Normalize cancellation capability labels and facade semantics.
3. Update support matrix and public mirrors.
4. Tighten deterministic proof and drift gates.

## Architectural Rule

The milestone should promote already-supported behavior into an honest first-party contract. It should not create new broad lifecycle abstractions to make the matrix look cleaner.
