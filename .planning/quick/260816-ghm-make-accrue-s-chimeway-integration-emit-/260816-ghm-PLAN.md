---
quick_id: 260816-ghm
status: planned
mode: quick
description: Make Accrue's Chimeway integration emit a stable opaque recipient_ref and use that same ref for invoice.paid cancellation signals; add focused tests and prepare release artifacts for Chimeway Phase 98 compatibility.
autonomous: true
files_modified:
  - accrue/lib/accrue/integrations/chimeway.ex
  - accrue/test/accrue/integrations/chimeway_test.exs
  - accrue/guides/dunning.md
  - accrue/CHANGELOG.md
must_haves:
  truths:
    - Accrue derives one deterministic Chimeway-safe opaque recipient reference from the Accrue customer UUID and includes it as recipient_ref when starting dunning.
    - The invoice.paid cancellation signal uses exactly the same opaque reference as actor_id, so Chimeway can route it to the waiting workflow without persisting or correlating by customer email.
    - Focused tests prove reference stability, Chimeway Phase 98 recipient acceptance, and start/cancel identity equality while preserving the optional conditional-compilation boundary.
    - Local release notes describe the privacy/compatibility fix without publishing, tagging, version-bumping, or changing external release state.
  artifacts:
    - path: accrue/lib/accrue/integrations/chimeway.ex
      provides: Stable opaque recipient_ref generation shared by notifier output and cancellation signaling
    - path: accrue/test/accrue/integrations/chimeway_test.exs
      provides: Focused Phase 98 compatibility and cancellation-routing regression coverage
    - path: accrue/guides/dunning.md
      provides: Accurate adopter-facing opaque-recipient and invoice.paid signal contract
    - path: accrue/CHANGELOG.md
      provides: Unreleased local release note for the compatibility fix
  key_links:
    - from: Accrue.Integrations.Chimeway.DunningNotifier.recipients/1
      to: Chimeway.trigger/3
      via: Recipient map carries recipient_ref alongside the transient email delivery identity
    - from: Accrue.Integrations.Chimeway.cancel_campaign/3
      to: Chimeway.Signal.track/4
      via: actor_id is derived by the same customer-ref helper used by recipients/1
    - from: Chimeway.Signal.track/4 actor_id
      to: Chimeway.Workflows.route_signal/1
      via: tenant_id, opaque recipient reference, and invoice.paid select the waiting workflow run
---

# Quick Task 260816-ghm: Chimeway Phase 98 opaque-recipient compatibility

## Objective

Make the optional Accrue dunning adapter compatible with Chimeway Phase 98's privacy-safe recipient boundary: a campaign must carry a stable `cw_...` opaque `recipient_ref`, and recovery must emit `invoice.paid` with that identical reference as the signal actor. Preserve email only as transient delivery context, retain the existing customer-scoped tenant and campaign idempotency contracts, and prepare local documentation/release evidence without publishing anything.

## Context

- `accrue/lib/accrue/integrations/chimeway.ex` currently returns only `recipient_identity: customer.email` and repeats that email as `Signal.track/4`'s `actor_id`.
- Chimeway Phase 98 accepts explicit recipient maps with `recipient_ref` values matching its opaque `cw_[a-z0-9_-]+` grammar, persists that reference as notification identity, and routes waiting runs only when the signal actor resolves to the same safe recipient reference.
- Accrue customer IDs are stable UUIDs. Use a domain-prefixed form such as `cw_accrue_customer_<customer UUID>` as the shared reference; do not hash email or derive durable identity from mutable recipient data.
- The adapter stays conditionally compiled behind `Code.ensure_loaded?(Chimeway)` and remains absent from the default always-on dunning path.
- The repository owns Unreleased release truth in package-root changelogs. Do not edit package versions, `.release-please-manifest.json`, tags, release PRs, or remote state.

## Task 1 — Prove and implement one opaque identity across trigger and cancellation

**Type:** tracer, TDD

**Files:** `accrue/test/accrue/integrations/chimeway_test.exs`, `accrue/lib/accrue/integrations/chimeway.ex`

Begin with focused failing assertions in `Accrue.Integrations.ChimewayTest`. For a persisted Accrue customer/subscription, call `DunningNotifier.recipients/1` using both atom-keyed and string-keyed params and assert both return the same deterministic `recipient_ref`, that it starts with `cw_accrue_customer_`, that it contains no email, and that the transient `recipient_identity` is `user:<customer email>` so Phase 98 can hydrate the email address in memory without persisting it. Exercise the Chimeway-present lane against the local Phase 98 checkout: start a campaign, inspect the created Chimeway notification/workflow identity, cancel the campaign, and assert the persisted notification reference and the sole `invoice.paid` signal `actor_id` are byte-for-byte equal. Retain existing assertions for tenant ID, subscription payload, event name, idempotency, and the absence of the obsolete `payment_recovered` event.

Implement one internal `@doc false` customer-reference helper on `Accrue.Integrations.Chimeway` and call it from both `DunningNotifier.recipients/1` and `cancel_campaign/3` (the nested notifier cannot call a parent module's `defp`). Build the reference exclusively from `Customer.id`; add it as `recipient_ref` and encode the transient delivery identity as `user:<customer email>`, which Phase 98 consumes in memory and does not persist. Update module comments/moduledocs so they no longer claim email is durable workflow identity or the signal actor. Do not change `tenant_id`, `notification_key`, workflow version/steps, campaign idempotency keys, the `invoice.paid` event name, or conditional-compilation mechanics.

**Automated verification:**

```bash
test -d /Users/jon/projects/chimeway && cd accrue && CHIMEWAY_PATH=/Users/jon/projects/chimeway mix deps.get && CHIMEWAY_PATH=/Users/jon/projects/chimeway mix test test/accrue/integrations/chimeway_test.exs --warnings-as-errors
```

**Done:** The focused Chimeway-present test proves a campaign notification and its `invoice.paid` cancellation signal share one stable `cw_accrue_customer_...` reference, no durable routing assertion depends on customer email, and the conditional-compile tests remain green.

## Task 2 — Record the compatibility contract and run local release gates

**Files:** `accrue/guides/dunning.md`, `accrue/CHANGELOG.md`

Correct the Chimeway section of `dunning.md` to describe `recipient_ref` as the durable, customer-derived opaque correlation key and `invoice.paid` as the cancellation event whose actor is that same ref. Reconcile the currently stale statements that describe `payment_recovered`, email-backed actor matching, or immediate-only/no-WorkflowRun behavior with the shipped two-step `workflow/2` implementation. Keep host ownership explicit: email remains transient delivery context, Accrue owns customer/billing data, and Chimeway owns only the opaque lifecycle reference.

Add a concise entry under `accrue/CHANGELOG.md`'s existing `Unreleased` section, classified as a bug fix, naming Chimeway Phase 98 privacy-safe recipient compatibility and the unchanged `invoice.paid` termination contract. This is the complete local release artifact for the quick task: do not create a numbered release section, alter `@version`, update manifests, tag, publish, push, or create a release PR.

Run the focused integration lane plus Accrue's existing optional-dependency isolation and release-note gates. Format only the touched Elixir files.

**Automated verification:**

```bash
cd accrue && mix format --check-formatted lib/accrue/integrations/chimeway.ex test/accrue/integrations/chimeway_test.exs && CHIMEWAY_PATH=/Users/jon/projects/chimeway mix test test/accrue/integrations/chimeway_test.exs --warnings-as-errors && cd .. && bash scripts/ci/verify_dunning_chimeway_isolation.sh && bash scripts/ci/verify_release_notes_contract.sh && git diff --check
```

**Done:** Runtime, focused tests, adopter docs, and the Unreleased changelog agree on the opaque-ref/`invoice.paid` contract; isolation and release-note gates pass; package versions, manifests, tags, and remotes are untouched.

## Threat model

| Threat | Severity | Disposition | Mitigation |
|---|---|---|---|
| Customer email persists as Chimeway lifecycle identity or signal actor | high | mitigate | Supply a domain-prefixed customer-UUID `recipient_ref`, use it for cancellation, and assert stored notification/signal rows exclude email identity. |
| Start and cancel paths derive different references, leaving escalation active after payment | high | mitigate | One helper owns reference derivation; the integration test asserts exact notification-to-signal equality and `invoice.paid` routing inputs. |
| Cross-customer signal collision | high | mitigate | Include the full stable Accrue customer UUID in the opaque ref and retain the existing customer-scoped Chimeway `tenant_id`; test both fields. |
| Optional Chimeway code leaks into Accrue's always-on engine | medium | mitigate | Preserve the conditional compile boundary and run `verify_dunning_chimeway_isolation.sh`. |
| Local release preparation mutates external release state | medium | mitigate | Limit release work to Unreleased docs/changelog and explicitly prohibit version, manifest, tag, publish, push, and release-PR operations. |

## Source coverage audit

| Source | ID | Item | Task | Status | Notes |
|---|---|---|---|---|---|
| GOAL | — | Stable opaque recipient_ref on Accrue-triggered Chimeway dunning | 1 | COVERED | Shared helper plus Chimeway-present persistence proof. |
| GOAL | — | Same ref on invoice.paid cancellation signals | 1 | COVERED | Exact notification/signal equality assertion. |
| GOAL | — | Focused tests | 1 | COVERED | Atom/string params, stability, privacy, persistence, signal and conditional compile. |
| GOAL | — | Prepare local release artifacts for Phase 98 compatibility | 2 | COVERED | Guide and Unreleased changelog; no external state. |
| REQ | — | No roadmap requirement IDs assigned to this quick task | — | EXCLUDED | Quick-task description is the binding requirement source. |
| RESEARCH | — | No RESEARCH.md; no research phase requested | — | EXCLUDED | Local Chimeway Phase 98 code supplies the compatibility contract. |
| CONTEXT | — | No quick-task CONTEXT.md or D-XX decisions | — | EXCLUDED | User constraints are represented in Objective, Task 2, and the release-state threat. |

## Success criteria

- One deterministic, non-email `cw_accrue_customer_...` ref crosses both the notifier and cancellation seams.
- The focused test demonstrates Chimeway Phase 98 accepts/persists the ref and can correlate `invoice.paid` using it.
- Existing optional-dependency isolation remains intact.
- Documentation and Unreleased release notes accurately describe the compatibility fix.
- No publish, push, tag, version bump, manifest edit, release PR, or other external release mutation occurs.

## Output

After execution, create `.planning/quick/260816-ghm-make-accrue-s-chimeway-integration-emit-/260816-ghm-SUMMARY.md` with the test/gate results and the final commit IDs.
