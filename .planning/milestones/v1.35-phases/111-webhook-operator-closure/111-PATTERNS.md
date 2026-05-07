# Phase 111: Webhook & Operator Closure - Pattern Map

**Mapped:** 2026-05-06  
**Files analyzed:** 14  
**Analogs found:** 14 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue/guides/webhooks.md` | docs | webhook contract | same file | exact |
| `accrue/guides/telemetry.md` | docs | ops tuple catalog | same file | exact |
| `accrue/guides/operator-runbooks.md` | docs | ordered operator procedure | same file | exact |
| `accrue/guides/braintree-metered-billing.md` | docs | conceptual Braintree recovery explainer | same file | exact |
| `accrue/guides/testing.md` | docs | proof-lane catalog | same file | exact |
| `accrue/test/accrue/docs/testing_guide_test.exs` | doc assertion | testing-guide drift | same file | exact |
| `accrue/test/accrue/billing_portal_test.exs` | doc assertion | adjacent guide truth | same file | exact |
| `accrue/test/accrue/telemetry/ops_event_contract_test.exs` | contract gate | telemetry tuple literals | same file | exact |
| `accrue/test/accrue/telemetry/metrics_ops_parity_test.exs` | contract gate | metrics parity | same file | exact |
| `accrue/test/accrue/webhooks/dlq_test.exs` | runtime proof | replay + DLQ behavior | same file | exact |
| `accrue/test/mix/tasks/accrue_webhooks_replay_test.exs` | CLI proof | replay task behavior | same file | exact |
| `accrue/test/accrue/webhook/default_handler_portal_event_test.exs` | runtime proof | local checkout completion reduction | same file | exact |
| `accrue/test/accrue/telemetry/portal_checkout_completed_test.exs` | runtime proof | portal-completion telemetry | same file | exact |
| `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs`, `scripts/ci/accrue_host_verify_test_bounded.sh` | host proof | admin replay integration lane | same files | exact |

## Pattern Assignments

### Webhook guide pattern

**Pattern:** one host-boundary guide, explicit processor deltas

- `guides/webhooks.md` should describe the shared host responsibilities once.
- Processor-specific divergence should be added as concise, explicit deltas:
  - Stripe raw-body route and signature flow
  - Braintree webhook parse/ingest shape
  - local checkout completion as a persisted Accrue event, not an upstream hosted redirect truth

**Execution implication:** do not split webhook truth across new files; extend the existing guide with one processor-aware section.

### Telemetry plus runbook layering

**Pattern:** tuple catalog in one file, sequence in another

- `guides/telemetry.md` owns the literal tuple inventory and semantics.
- `guides/operator-runbooks.md` owns ordered triage and replay/recovery procedure.
- `guides/braintree-metered-billing.md` stays conceptual and links back to runbook order instead of duplicating it.

**Execution implication:** keep tuple names and metric names in `telemetry.md`; keep step-by-step recovery in `operator-runbooks.md`.

### Deterministic proof pattern

**Pattern:** prove supportability with narrow, executable lanes

- `DLQTest` proves replay semantics.
- `ReplayTest` proves CLI operator entry points.
- `DefaultHandlerPortalEventTest` and `PortalCheckoutCompletedTest` prove Braintree local checkout completion and telemetry.
- Host admin replay remains the integration lane.

**Execution implication:** elevate these tests in docs and keep any new assertions narrow and behavior-linked.

### Drift-gate pattern

**Pattern:** adjacent-guide assertions plus contract parity tests

- `billing_portal_test.exs` already protects adjacent guide wording and is a good analog for Phase 111 guide assertions.
- `ops_event_contract_test.exs` and `metrics_ops_parity_test.exs` already prevent telemetry tuple drift.

**Execution implication:** add new Phase 111 wording checks to existing test seams rather than inventing a new docs harness.

### Host verifier pattern

**Pattern:** keep recovery proof inside the bounded host verify slice

- `scripts/ci/accrue_host_verify_test_bounded.sh` already enumerates the host’s deterministic billing test lane.
- `admin_webhook_replay_test.exs` is the correct host-level replay proof anchor.

**Execution implication:** if the operator-support story changes the expected host proof, update the bounded script in the same plan as the host test.

## Planner Notes

- Put webhook, telemetry, and runbook edits ahead of testing-guide and gate work.
- Reuse existing doc-assertion files before adding any new phase-specific doc test module.
- Keep replay and checkout-completion proof in the final plan so it validates the settled docs contract, not an intermediate draft.

---

*Phase: 111-webhook-operator-closure*  
*Pattern map completed: 2026-05-06*
