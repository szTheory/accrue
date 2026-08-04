# Multi-rail and offline release guide (v1.59)

This guide is the hand-authored release procedure for the additive Stripe,
Apple, and offline-study contract. The generated
[capability and limits matrix](https://github.com/szTheory/accrue/blob/main/examples/accrue_host/docs/capability-limits-matrix.md)
is the exact authority for supported and unsupported cells. Do not replace it
with a copied table in a host runbook, ticket, or App Review submission.

## Start with the reference host

Use the anonymized reference host to prove the host boundary without live
provider credentials:

1. Follow the [adoption proof matrix](https://github.com/szTheory/accrue/blob/main/examples/accrue_host/docs/adoption-proof-matrix.md)
   and run `mix verify` in `examples/accrue_host`.
2. Run `cd accrue && mix accrue.entitlements.reference_scenarios --check` from
   the repository root. This is the merge-blocking semantic check.
3. Read the generated matrix for its exact compatibility, privacy, scenario,
   and evidence-lane facts.
4. When a scenario needs intervention, record its stable ID and open the
   matching [v1.59 runbook](operator-runbooks.md#v159-multi-rail-and-offline-runbooks).

Legacy hosts remain compatible. Apple subscriptions are externally managed.
Accrue does not perform cross-rail lifecycle migration, ownership transfer,
refund, cancellation, or proration. A stale offline lease continues downloaded
study and local progress only; new value waits for reconnect.

## Evidence and App Review

The `deterministic_conformance` lane proves account-projection semantics,
including Apple-to-web and Stripe-to-iOS convergence. It is merge-blocking, but
it is not a claim that a Crosswake mobile runtime is feasible. The Crosswake
tracer remains `feasibility_blocked` until its documented bridge and physical
device evidence is present. Fake, browser, simulator, and vector results cannot
promote that runtime claim.

`advisory_parity` is provider-comparison evidence and is not merge-blocking.
Browser/Playwright coverage is complementary rendered-host evidence for copy and
flows. It is not an oracle for StoreKit, proof verification, cache rollback,
ordering, or key rotation.

For App Review, describe Apple subscriptions as externally managed, explain the
in-app restore and access-state experience that the host actually renders, and
attach only redacted screenshots plus the relevant scenario ID. Do not claim an
external purchase path, a provider lifecycle control that Accrue does not own,
or Crosswake runtime capability while the tracer is blocked. Product and legal
owners approve storefront-specific wording before submission; `V159-RUN-APP-REVIEW`
records a rejection or policy change.

## Privacy and security limits

The operator surface is a bounded diagnostic, not a database or provider
explorer. Tickets and release evidence may contain a safe correlation, state,
reason, next action, timestamp/age, revision, and scenario or runbook ID. They
must not contain raw transaction or notification data, signed proof material,
tokens, credentials, PII, encrypted-evidence locations, provider payloads,
worker arguments, or exception text.

### STRIDE review

| Threat | Release control |
| --- | --- |
| Spoofed evidence claim | Keep deterministic, runtime-capability, advisory-parity, and browser lanes labeled; link the generated matrix and tracer report. |
| Tampered procedure or target | Require host authorization, a bounded target, dry-run or confirmation, actor/reason audit, and post-action revision check. |
| Repudiated support action | Record the actor, reason, safe correlation, before/after revision, scenario/runbook ID, and dated watchlist reassessment. |
| Information disclosure | Use only bounded diagnostic fields and redacted evidence; remove sensitive material from tickets and release notes. |
| Denial of service | Use bounded retry/backoff and backlog limits; pause when queue, provider, or key health remains unsafe. |
| Privilege escalation | Keep repair actions host-authorized and prohibit automatic account reconstruction, ownership transfer/merge, financial mutation, migration, and proration. |

## Release checklist

1. Confirm `mix verify` and the deterministic reference-scenario command pass.
2. Confirm the generated matrix is current; do not edit it by hand.
3. Review the Crosswake report and publish its actual status, including
   `feasibility_blocked` when its required evidence remains absent.
4. Run the relevant incident tabletop using the scenario and runbook IDs below.
5. Confirm App Review copy, privacy review, and the v1.59 watchlist each have a
   dated reassessment, owner, evidence ID, and next action.
6. Confirm release notes preserve additive compatibility, Apple external
   management, no cross-rail financial/lifecycle mutation, stale-study-only
   continuity, and the privacy boundary.

## Evidence collection

Keep a dated release record with the command result, generated-matrix revision,
tracer status, redacted scenario IDs, safe correlations, and the operator who
approved the checklist. Stop the release when a required semantic check fails,
the generated matrix drifts, a blocked runtime claim appears, or privacy review
finds sensitive evidence. Resume only after the named runbook records a bounded
resolution and post-convergence result.
