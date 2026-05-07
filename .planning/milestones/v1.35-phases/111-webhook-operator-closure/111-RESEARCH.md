# Phase 111: Webhook & Operator Closure - Research

**Researched:** 2026-05-06  
**Domain:** processor-aware webhook guidance, operator recovery documentation, telemetry references, and deterministic proof lanes for the shipped Stripe + Braintree surface  
**Confidence:** HIGH

<user_constraints>
## User Constraints

No phase-specific `111-CONTEXT.md` exists, so this research uses the locked milestone boundary from `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/PROJECT.md`, and the completed Phase 109/110 artifacts.

### Locked Milestone Boundary

- Phase 111 closes the supportability gap for the already-shipped Stripe + Braintree surface; it is not a new capability phase. [VERIFIED: `.planning/ROADMAP.md`, `.planning/PROJECT.md`]
- No new processors, Connect reopening, finance/export scope, or broad billing-primitive expansion. [VERIFIED: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`]
- UI work is only in scope if it improves recovery ergonomics or deterministic proof for the written operator story. [VERIFIED: `.planning/ROADMAP.md`]
- Stripe and Braintree must remain provider-honest rather than flattened into parity theater. [VERIFIED: `.planning/processor-support-matrix.md`, `.planning/STRATEGY.md`, `.planning/milestones/v1.35-phases/109-support-contract-truth/109-CONTEXT.md`]
- Fake remains the deterministic local proof lane; provider-backed Braintree behavior is documented and exercised where it changes the support contract. [VERIFIED: `.planning/milestones/v1.35-phases/109-support-contract-truth/109-RESEARCH.md`, `.planning/milestones/v1.35-phases/110-lifecycle-semantics-self-serve-clarity/110-RESEARCH.md`]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OPS-01 | Webhook docs, operator runbooks, and telemetry reference material MUST become processor-aware for the shipped Braintree slice, including replay/recovery, drift diagnosis, checkout completion ambiguity, and metered renewal recovery. | Existing runtime and tests already cover Braintree webhook normalization, local portal checkout completion, DLQ replay, and metered-renewal repair, but the docs are still skewed toward Stripe in the webhook/operator path. [VERIFIED: `accrue/lib/accrue/webhook/default_handler.ex`, `accrue/lib/accrue/webhook/plug.ex`, `accrue/lib/accrue/jobs/metered_renewal_reconciler.ex`, `accrue/test/accrue/webhooks/dlq_test.exs`, `accrue/test/accrue/telemetry/portal_checkout_completed_test.exs`, `accrue/guides/webhooks.md`, `accrue/guides/operator-runbooks.md`, `accrue/guides/telemetry.md`] |
| OPS-02 | Deterministic proof and verifier coverage MUST prevent support-contract drift and exercise the Braintree recovery/documentation paths that this milestone formalizes. | The repo already has strong targeted lanes for replay, portal completion, telemetry parity, and host admin replay, but the testing guide and doc assertions do not yet frame them as the required proof bundle for Braintree supportability. [VERIFIED: `accrue/test/accrue/webhooks/dlq_test.exs`, `accrue/test/mix/tasks/accrue_webhooks_replay_test.exs`, `accrue/test/accrue/webhook/default_handler_portal_event_test.exs`, `accrue/test/accrue/telemetry/portal_checkout_completed_test.exs`, `accrue/test/accrue/telemetry/ops_event_contract_test.exs`, `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs`, `scripts/ci/accrue_host_verify_test_bounded.sh`, `accrue/guides/testing.md`] |
</phase_requirements>

## Summary

The runtime surface is already richer than the operator docs. `guides/webhooks.md` still teaches a Stripe-only route example and generic replay guidance, while the codebase already supports Braintree webhook parsing, local portal checkout completion projection, DLQ replay, and metered-renewal repair semantics that materially affect support expectations. [VERIFIED: `accrue/guides/webhooks.md`, `accrue/lib/accrue/webhook/plug.ex`, `accrue/lib/accrue/webhook/default_handler.ex`, `accrue/lib/accrue/webhooks/dlq.ex`, `accrue/lib/accrue/jobs/metered_renewal_reconciler.ex`]

The telemetry and runbook story is partially there, but fragmented. `guides/telemetry.md` lists the relevant ops tuples, and `guides/operator-runbooks.md` already has a Braintree metered-renewal section, yet the docs do not currently form one processor-aware support narrative covering replay entry points, checkout completion ambiguity, DLQ triage, drift diagnosis, and when Braintree local truth is authoritative versus merely converging. [VERIFIED: `accrue/guides/telemetry.md`, `accrue/guides/operator-runbooks.md`, `accrue/guides/braintree-metered-billing.md`, `accrue/guides/braintree-local-portal.md`]

The proof lanes already exist and should be elevated rather than reinvented. Core ExUnit tests cover DLQ replay, the `mix accrue.webhooks.replay` task, local portal checkout completion telemetry, and Braintree default-handler projection; the example host already keeps admin webhook replay inside the bounded verifier slice. What is missing is a phase-owned plan that ties those lanes to the operator contract and prevents doc drift the same way earlier phases pinned support and lifecycle wording. [VERIFIED: `accrue/test/accrue/webhooks/dlq_test.exs`, `accrue/test/mix/tasks/accrue_webhooks_replay_test.exs`, `accrue/test/accrue/telemetry/portal_checkout_completed_test.exs`, `accrue/test/accrue/webhook/default_handler_portal_event_test.exs`, `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs`, `scripts/ci/accrue_host_verify_test_bounded.sh`]

**Primary recommendation:** split Phase 111 into three plans:

1. processor-aware webhook, telemetry, and runbook documentation
2. deterministic docs/test-gate coverage for the documented support story
3. targeted recovery and host proof lanes for replay plus local-checkout completion

That sequencing mirrors the repo’s recent planning pattern: settle the written contract first, pin it with doc assertions next, then harden the executable proof bundle last.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Webhook support contract | `accrue/guides/webhooks.md` | `accrue/lib/accrue/webhook/*` | The guide should describe the supported host boundary and replay/recovery story, while the webhook modules remain the runtime truth. |
| Ops tuple catalog | `accrue/guides/telemetry.md` | `accrue/lib/accrue/telemetry/*` | The telemetry guide is already the tuple SSOT and should explicitly anchor the Braintree recovery events Phase 111 depends on. |
| Ordered operator procedure | `accrue/guides/operator-runbooks.md` | `accrue/guides/braintree-metered-billing.md` | `operator-runbooks.md` should own sequence-sensitive triage; the Braintree metered guide should stay conceptual and link back into runbook order. |
| Deterministic replay and recovery proof | targeted ExUnit + bounded host verifier | docs/tests | The repo already prefers narrow, executable proof lanes over broad manual checklists. |

## Current-State Findings

### Webhook docs are not yet processor-aware enough

- `guides/webhooks.md` only shows a `/webhooks/stripe` route example and does not explain the Braintree parse/ingest path, local portal completion event shape, or when replay is useful for Braintree-specific recovery. [VERIFIED: `accrue/guides/webhooks.md`, `accrue/lib/accrue/webhook/plug.ex`]
- The runtime already normalizes Braintree subscription events and persists `accrue.portal.checkout.completed` through the default-handler path. [VERIFIED: `accrue/lib/accrue/webhook/default_handler.ex`, `accrue/test/accrue/webhook/default_handler_portal_event_test.exs`, `accrue/test/accrue/telemetry/portal_checkout_completed_test.exs`]

### Operator guidance is strong in pieces, not as one support story

- `guides/operator-runbooks.md` has good DLQ and metered-renewal material, but the Braintree-specific replay and checkout-completion ambiguity story is not surfaced as a first-class operator path. [VERIFIED: `accrue/guides/operator-runbooks.md`]
- `guides/braintree-metered-billing.md` explains local invoice first, settlement second, and renewal repair, but it does not itself anchor the exact replay and triage sequence. [VERIFIED: `accrue/guides/braintree-metered-billing.md`]

### Deterministic proof exists but is under-signaled

- `DLQ.requeue/1`, `requeue_where/2`, and the `mix accrue.webhooks.replay` task already have focused tests. [VERIFIED: `accrue/test/accrue/webhooks/dlq_test.exs`, `accrue/test/mix/tasks/accrue_webhooks_replay_test.exs`]
- Braintree local-checkout completion already has both default-handler and telemetry proof lanes. [VERIFIED: `accrue/test/accrue/webhook/default_handler_portal_event_test.exs`, `accrue/test/accrue/telemetry/portal_checkout_completed_test.exs`]
- The example host already proves admin replay inside the bounded host verifier, which is the right supportability-level integration lane to keep release-blocking. [VERIFIED: `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs`, `scripts/ci/accrue_host_verify_test_bounded.sh`]

## Validation Architecture

### Docs and contract lane

```bash
rg -n "Braintree|portal_base_url|portal_mount_path|accrue.portal.checkout.completed|metered_renewal_stale_repaired|webhook_dlq" \
  accrue/guides/webhooks.md \
  accrue/guides/telemetry.md \
  accrue/guides/operator-runbooks.md \
  accrue/guides/braintree-metered-billing.md \
  accrue/guides/testing.md
```

### Core recovery lane

```bash
cd accrue && mix test \
  test/accrue/webhooks/dlq_test.exs \
  test/mix/tasks/accrue_webhooks_replay_test.exs \
  test/accrue/webhook/default_handler_portal_event_test.exs \
  test/accrue/telemetry/portal_checkout_completed_test.exs \
  test/accrue/telemetry/ops_event_contract_test.exs \
  test/accrue/telemetry/metrics_ops_parity_test.exs \
  test/accrue/docs/testing_guide_test.exs \
  test/accrue/billing_portal_test.exs
```

### Host recovery lane

```bash
cd examples/accrue_host && ../../scripts/ci/accrue_host_verify_test_bounded.sh
```

## Open Questions (RESOLVED)

- **Does Phase 111 need new runtime webhook primitives?** No. The support gap is documentation, proof framing, and deterministic recovery coverage around already-shipped runtime behavior. [VERIFIED: `accrue/lib/accrue/webhook/default_handler.ex`, `accrue/lib/accrue/webhooks/dlq.ex`]
- **Should Phase 111 add broad live-provider end-to-end verification?** No. The repo’s locked proof posture stays Fake-first plus targeted Braintree runtime lanes where local behavior materially changes the support contract. [VERIFIED: `.planning/processor-support-matrix.md`, `.planning/milestones/v1.35-phases/109-support-contract-truth/109-RESEARCH.md`]
- **Should the docs duplicate full metered-billing explanations in multiple places?** No. `telemetry.md` owns the tuple catalog, `operator-runbooks.md` owns ordered response, and `braintree-metered-billing.md` should stay the conceptual architecture explainer. [VERIFIED: `accrue/guides/telemetry.md`, `accrue/guides/operator-runbooks.md`, `accrue/guides/braintree-metered-billing.md`]

## Plan Shape Recommendation

| Plan | Focus | Why it should be separate |
|------|-------|---------------------------|
| 111-01 | webhook docs + telemetry + runbooks | Settles the operator-facing contract before any proof lanes pin it. |
| 111-02 | testing guide + doc assertions | Makes the documented Braintree recovery story durable and grep/test enforced. |
| 111-03 | targeted replay + portal-completion proof + bounded host verifier | Exercises the concrete recovery paths and keeps them release-adjacent. |

---

*Phase: 111-webhook-operator-closure*  
*Research completed: 2026-05-06*
