# Phase 117: Contract Promotion + Preview Truth - Pattern Map

**Mapped:** 2026-05-07
**Files analyzed:** 13
**Analogs found:** 13 / 13

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue/lib/accrue/processor/capabilities.ex` | config | transform | `accrue/lib/accrue/processor/capabilities.ex` | exact |
| `accrue/guides/lifecycle_semantics.md` | config | transform | `accrue/guides/lifecycle_semantics.md` | exact |
| `.planning/processor-support-matrix.md` | config | transform | `.planning/processor-support-matrix.md` | exact |
| `accrue/README.md` | config | transform | `accrue/README.md` | exact |
| `accrue/guides/first_hour.md` | config | transform | `accrue/guides/first_hour.md` | exact |
| `examples/accrue_host/README.md` | config | transform | `examples/accrue_host/README.md` | exact |
| `examples/accrue_host/docs/adoption-proof-matrix.md` | config | transform | `examples/accrue_host/docs/adoption-proof-matrix.md` | exact |
| `accrue_admin/lib/accrue_admin/copy/subscription.ex` | utility | transform | `accrue_admin/lib/accrue_admin/copy/subscription.ex` | exact |
| `accrue_admin/lib/accrue_admin/live/subscription_live.ex` | component | request-response | `accrue_admin/lib/accrue_admin/live/subscription_live.ex` | exact |
| `scripts/ci/verify_processor_support_matrix.sh` | test | transform | `scripts/ci/verify_processor_support_matrix.sh` | exact |
| `scripts/ci/verify_package_docs.sh` | test | transform | `scripts/ci/verify_package_docs.sh` | exact |
| `scripts/ci/verify_verify01_readme_contract.sh` | test | transform | `scripts/ci/verify_verify01_readme_contract.sh` | exact |
| `scripts/ci/verify_adoption_proof_matrix.sh` | test | transform | `scripts/ci/verify_adoption_proof_matrix.sh` | exact |

## Pattern Assignments

### Runtime contract seam

**Public facade stays intent-first and thin**

**Source:** [`accrue/lib/accrue/billing.ex`](/Users/jon/projects/accrue/accrue/lib/accrue/billing.ex:79)

Use the existing wrapper pattern when Phase 117 references public APIs: the facade names the intent and delegates to `SubscriptionActions` inside telemetry spans.

```elixir
def swap_plan(sub, new_price_id, opts) do
  span_billing(:subscription, :swap_plan, sub, opts, fn ->
    SubscriptionActions.swap_plan(sub, new_price_id, opts)
  end)
end

def preview_upcoming_invoice(sub_or_customer, opts \\ []) do
  span_billing(:invoice, :preview_upcoming, sub_or_customer, opts, fn ->
    SubscriptionActions.preview_upcoming_invoice(sub_or_customer, opts)
  end)
end
```

**Bounded Braintree support is enforced at the action boundary**

**Source:** [`accrue/lib/accrue/billing/subscription_actions.ex`](/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_actions.ex:284)

Copy the current shape instead of inventing provider-specific facade verbs: branch once on processor, keep Stripe/Fake on the generic path, and make Braintree constraints explicit via typed errors.

Key lines:
- [`284-348`](/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_actions.ex:284): `swap_plan/3` branches by processor, preserves one public API, records `subscription.plan_swapped`.
- [`351-423`](/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_actions.ex:351): Braintree resolver/currency/billing-cycle checks.
- [`475-505`](/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_actions.ex:475): `preview_upcoming_invoice/2` builds preview params from subscription state and requested target price.

**Plan resolver is documented as a narrow Braintree enabler**

**Source:** [`accrue/lib/accrue/plan_resolver.ex`](/Users/jon/projects/accrue/accrue/lib/accrue/plan_resolver.ex:1)

Phase 117 should mirror the existing contract words already encoded here:
- [`11-14`](/Users/jon/projects/accrue/accrue/lib/accrue/plan_resolver.ex:11): Braintree-specific reason this resolver exists.
- [`27-34`](/Users/jon/projects/accrue/accrue/lib/accrue/plan_resolver.ex:27): required metadata contract.
- [`49-56`](/Users/jon/projects/accrue/accrue/lib/accrue/plan_resolver.ex:49): missing resolver returns typed `plan_resolution_unavailable`.

**Processor adapter errors are explicit, not parity theater**

**Source:** [`accrue/lib/accrue/processor/braintree.ex`](/Users/jon/projects/accrue/accrue/lib/accrue/processor/braintree.ex:447)

Keep Phase 117 docs aligned with these exact boundaries:
- [`449-454`](/Users/jon/projects/accrue/accrue/lib/accrue/processor/braintree.ex:449): quantity unsupported.
- [`473-481`](/Users/jon/projects/accrue/accrue/lib/accrue/processor/braintree.ex:473): multi-item unsupported.
- [`499-503`](/Users/jon/projects/accrue/accrue/lib/accrue/processor/braintree.ex:499): resolver metadata requirements.
- [`509-516`](/Users/jon/projects/accrue/accrue/lib/accrue/processor/braintree.ex:509): `:always_invoice` unsupported.

### Support-label and docs SSOT pattern

**Capability labels live in code as a small central map**

**Source:** [`accrue/lib/accrue/processor/capabilities.ex`](/Users/jon/projects/accrue/accrue/lib/accrue/processor/capabilities.ex:11)

Phase 117 should extend this map with finer-grained rows rather than overloading broad `subscription.update`.

```elixir
@support_labels %{
  subscription: %{
    direct_create: "all first-party",
    fetch: "all first-party",
    cancel: "all first-party",
    lifecycle_webhook_projection: "all first-party",
    update: "all first-party",
    cancel_at_period_end: "staged first-party target",
    cancel_immediately: "all first-party",
    pause: "out of slice",
    resume: "out of slice"
  }
}
```

**Semantic SSOT uses glossary sections with provider labels**

**Source:** [`accrue/guides/lifecycle_semantics.md`](/Users/jon/projects/accrue/accrue/guides/lifecycle_semantics.md:1)

Copy this structure for the Phase 117 contract promotion:
- action heading
- plain-language meaning
- primary wording
- customer/operator expectation
- provider labels
- boundary paragraph for Braintree/Fake honesty

Best existing analog:
- [`10-28`](/Users/jon/projects/accrue/accrue/guides/lifecycle_semantics.md:10): `swap_plan/3` section already uses the right glossary pattern.

**Support SSOT uses capability table + facade mapping table**

**Source:** [`.planning/processor-support-matrix.md`](/Users/jon/projects/accrue/.planning/processor-support-matrix.md:29)

Phase 117 should follow the existing two-table pattern:
- [`31-52`](/Users/jon/projects/accrue/.planning/processor-support-matrix.md:31): provider capability table.
- [`60-76`](/Users/jon/projects/accrue/.planning/processor-support-matrix.md:60): public facade mapping table.
- [`80-85`](/Users/jon/projects/accrue/.planning/processor-support-matrix.md:80): explicit out-of-slice list.

This is the right place to promote `swap_plan/3` and `preview_upcoming_invoice/2` without creating a third canonical contract doc.

### Docs mirror pattern

**Package README is a thin summary that points back to the support SSOT**

**Source:** [`accrue/README.md`](/Users/jon/projects/accrue/accrue/README.md:59)

Current mirror pattern:
- one compact “What you get” paragraph
- provider-honest summary
- explicit pointer back to the canonical matrix

Best analog:
- [`61-63`](/Users/jon/projects/accrue/accrue/README.md:61)

**First Hour mirrors only setup-critical needles**

**Source:** [`accrue/guides/first_hour.md`](/Users/jon/projects/accrue/accrue/guides/first_hour.md:19)

Best analog:
- [`19-27`](/Users/jon/projects/accrue/accrue/guides/first_hour.md:19): terse provider table plus “mirrors only the setup-critical needles” wording.
- [`52-75`](/Users/jon/projects/accrue/accrue/guides/first_hour.md:52): Stripe-first spine with early Braintree branch.

**Host README mirrors the same spine in host-facing language**

**Source:** [`examples/accrue_host/README.md`](/Users/jon/projects/accrue/examples/accrue_host/README.md:17)

Best analog:
- [`17-31`](/Users/jon/projects/accrue/examples/accrue_host/README.md:17): provider-honest summary plus matrix pointer.
- [`111-116`](/Users/jon/projects/accrue/examples/accrue_host/README.md:111): proof section points to `scripts/ci/README.md` instead of re-listing every script.

**Adoption proof matrix stays taxonomy-thin**

**Source:** [`examples/accrue_host/docs/adoption-proof-matrix.md`](/Users/jon/projects/accrue/examples/accrue_host/docs/adoption-proof-matrix.md:5)

Best analog:
- [`5-12`](/Users/jon/projects/accrue/examples/accrue_host/docs/adoption-proof-matrix.md:5): proof-lane framing with provider-honest wording.
- [`16-27`](/Users/jon/projects/accrue/examples/accrue_host/docs/adoption-proof-matrix.md:16): concise concern/proof/where table.

### Admin and copy pattern

**LiveView gates provider-specific actions in the template**

**Source:** [`accrue_admin/lib/accrue_admin/live/subscription_live.ex`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/subscription_live.ex:264)

Best analogs:
- [`264-318`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/subscription_live.ex:264): Braintree hides unsupported actions and shows setup guidance instead of fake affordances.
- [`567-579`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/subscription_live.ex:567): action execution converts UI params into facade calls and typed errors.
- [`732-745`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/subscription_live.ex:732): provider guidance and `swap_plan_available?/1` gating.

**Operator copy is centralized in `Copy.Subscription`**

**Source:** [`accrue_admin/lib/accrue_admin/copy/subscription.ex`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/copy/subscription.ex:12)

Best analogs:
- [`12-14`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/copy/subscription.ex:12): proration label helpers.
- [`33-43`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/copy/subscription.ex:33): provider-honest Braintree vs Stripe guidance copy.

### Verifier pattern

**Contributor-map pattern: docs move as a bundle**

**Source:** [`scripts/ci/README.md`](/Users/jon/projects/accrue/scripts/ci/README.md:56)

Phase 117 should follow the existing support-contract bundle rule, not invent a new verifier family.

Key analogs:
- [`56-79`](/Users/jon/projects/accrue/scripts/ci/README.md:56): same-PR co-update rule and full bundle command.
- [`84-108`](/Users/jon/projects/accrue/scripts/ci/README.md:84): surface-to-script map.

**Verifier scripts use substring pins plus stale-wording negatives**

**Sources:**
- [`scripts/ci/verify_processor_support_matrix.sh`](/Users/jon/projects/accrue/scripts/ci/verify_processor_support_matrix.sh:13)
- [`scripts/ci/verify_verify01_readme_contract.sh`](/Users/jon/projects/accrue/scripts/ci/verify_verify01_readme_contract.sh:13)
- [`scripts/ci/verify_adoption_proof_matrix.sh`](/Users/jon/projects/accrue/scripts/ci/verify_adoption_proof_matrix.sh:13)
- [`scripts/ci/verify_package_docs.sh`](/Users/jon/projects/accrue/scripts/ci/verify_package_docs.sh:23)

Reusable pattern:
- positive `require_substring` / `require_fixed` needles for must-keep contract text
- negative checks for stale parity language
- no parsing sophistication unless necessary

Best analogs:
- [`verify_processor_support_matrix.sh:22-55`](/Users/jon/projects/accrue/scripts/ci/verify_processor_support_matrix.sh:22): matrix literal pins.
- [`verify_processor_support_matrix.sh:56-84`](/Users/jon/projects/accrue/scripts/ci/verify_processor_support_matrix.sh:56): stale-row regression guards.
- [`verify_verify01_readme_contract.sh:22-42`](/Users/jon/projects/accrue/scripts/ci/verify_verify01_readme_contract.sh:22): host README proof wording pins.
- [`verify_verify01_readme_contract.sh:52-77`](/Users/jon/projects/accrue/scripts/ci/verify_verify01_readme_contract.sh:52): negative checks and scoped `sk_live` guard.
- [`verify_adoption_proof_matrix.sh:22-58`](/Users/jon/projects/accrue/scripts/ci/verify_adoption_proof_matrix.sh:22): proof-matrix wording pins.

### Proof pattern

**Fake proves flow shape; live Stripe proves fidelity**

**Sources:**
- [`accrue/test/accrue/billing/upcoming_invoice_test.exs`](/Users/jon/projects/accrue/accrue/test/accrue/billing/upcoming_invoice_test.exs:11)
- [`accrue/test/accrue/billing/proration_roundtrip_test.exs`](/Users/jon/projects/accrue/accrue/test/accrue/billing/proration_roundtrip_test.exs:18)
- [`accrue/test/live_stripe/proration_fidelity_live_test.exs`](/Users/jon/projects/accrue/accrue/test/live_stripe/proration_fidelity_live_test.exs:12)
- [`accrue_admin/test/accrue_admin/live/subscription_live_test.exs`](/Users/jon/projects/accrue/accrue_admin/test/accrue_admin/live/subscription_live_test.exs:252)

Use the same split in planning:
- Fake/ExUnit for merge-blocking contract shape
- live Stripe for preview-vs-commit fidelity evidence
- admin LiveView test for provider-honest copy/gating

## Shared Patterns

### One public API, honest provider divergence

Apply to runtime, docs, admin copy, and verifiers.

Primary sources:
- [`accrue/lib/accrue/billing/subscription_actions.ex:288`](/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_actions.ex:288)
- [`accrue/guides/lifecycle_semantics.md:3`](/Users/jon/projects/accrue/accrue/guides/lifecycle_semantics.md:3)
- [`.planning/processor-support-matrix.md:54`](/Users/jon/projects/accrue/.planning/processor-support-matrix.md:54)

### Canonical docs spine + thin mirrors

Apply to all doc edits in this phase.

Primary sources:
- [`accrue/guides/lifecycle_semantics.md:3`](/Users/jon/projects/accrue/accrue/guides/lifecycle_semantics.md:3)
- [`.planning/processor-support-matrix.md:3`](/Users/jon/projects/accrue/.planning/processor-support-matrix.md:3)
- [`accrue/guides/first_hour.md:26`](/Users/jon/projects/accrue/accrue/guides/first_hour.md:26)
- [`examples/accrue_host/README.md:30`](/Users/jon/projects/accrue/examples/accrue_host/README.md:30)

### Drift gate follows touched mirrors

Apply whenever support wording or proof wording changes.

Primary sources:
- [`scripts/ci/README.md:56`](/Users/jon/projects/accrue/scripts/ci/README.md:56)
- [`scripts/ci/README.md:84`](/Users/jon/projects/accrue/scripts/ci/README.md:84)

## Likely Files To Touch

- `accrue/lib/accrue/processor/capabilities.ex`
- `accrue/guides/lifecycle_semantics.md`
- `.planning/processor-support-matrix.md`
- `accrue/README.md`
- `accrue/guides/first_hour.md`
- `examples/accrue_host/README.md`
- `examples/accrue_host/docs/adoption-proof-matrix.md`
- `accrue_admin/lib/accrue_admin/copy/subscription.ex`
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex`
- `scripts/ci/verify_processor_support_matrix.sh`
- `scripts/ci/verify_package_docs.sh`
- `scripts/ci/verify_verify01_readme_contract.sh`
- `scripts/ci/verify_adoption_proof_matrix.sh`

## Metadata

**Analog search scope:** `accrue/lib`, `accrue/guides`, `accrue_admin/lib`, `accrue/test`, `accrue_admin/test`, `examples/accrue_host`, `.planning`, `scripts/ci`
**Pattern extraction date:** 2026-05-07
