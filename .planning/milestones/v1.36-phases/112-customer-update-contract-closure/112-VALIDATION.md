---
phase: 112
slug: customer-update-contract-closure
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-06
---

# Phase 112 — Validation Strategy

> Per-phase validation contract for promoting `Accrue.Billing.update_customer/2` to a narrow first-party Stripe/Fake/Braintree row without widening the shared customer-update surface. Source-of-truth detail lives in `112-RESEARCH.md` and `112-PATTERNS.md`.

---

## Coverage Audit

| Source | Item | Covered By |
|--------|------|------------|
| GOAL | Promote `Accrue.Billing.update_customer/2` from staged to explicit first-party support | Plans `112-01`, `112-02`, `112-03` |
| REQ | `PROC-21` host-facing shared customer-update contract with deterministic proof | Plans `112-01`, `112-02`, `112-03` |
| RESEARCH | bounded attr contract, remote write-through, explicit local-only API, projection/event semantics | Plan `112-01` |
| RESEARCH | capability-label and support-matrix promotion plus deterministic core proof | Plan `112-02` |
| RESEARCH | thin example-host helper and provider-neutral template alignment | Plan `112-03` |
| CONTEXT | D-01..D-05 narrow subset and separate specialized APIs | Plans `112-01`, `112-02`, `112-03` |
| CONTEXT | D-06..D-16 remote write-through, projection sync, typed rejection, bounded event semantics | Plan `112-01`, Plan `112-02` |
| CONTEXT | D-17..D-23 Fake-first core proof plus thin host-facing proof | Plan `112-02`, Plan `112-03` |
| CONTEXT | D-24..D-32 bounded multi-provider lessons and no parity theater | Plans `112-01`, `112-02`, `112-03` |

No deferred ideas are planned. Cancellation semantics remain in Phase 113. Docs-wide drift closeout remains in Phase 114 except for the minimal support-matrix alignment required by promoting this row.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit plus targeted `rg` drift checks |
| **Config file** | `accrue/test/*`, `examples/accrue_host/test/*` |
| **Quick run command** | `cd accrue && mix test test/accrue/billing/events_transaction_test.exs test/accrue/processor/capabilities_test.exs test/accrue/processor/fake_test.exs test/accrue/processor/braintree_test.exs test/accrue/processor/stripe_test.exs` |
| **Full suite command** | `cd accrue && mix test test/accrue/billing/events_transaction_test.exs test/accrue/processor/capabilities_test.exs test/accrue/processor/fake_test.exs test/accrue/processor/braintree_test.exs test/accrue/processor/stripe_test.exs && cd ../examples/accrue_host && mix test test/accrue_host/billing_facade_test.exs` |
| **Estimated runtime** | 2-5 minutes |

---

## Sampling Rate

- **After every task commit:** run that task’s focused `mix test` or `rg` command.
- **After Plan 01:** run the Plan 01 verification bundle before touching labels or host proof.
- **After Plan 02:** run the quick run command.
- **Before `$gsd-verify-work`:** run the full suite command plus the matrix/runtime drift grep.
- **Max feedback latency:** under 5 minutes.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 112-01-01 | 01 | 1 | PROC-21 | T-112-01 | `update_customer/2` enforces the narrow shared attr contract and performs remote write-through plus local projection sync, with executable billing-layer proof for dispatch, sanitized projection, and event meaning | unit | `cd accrue && mix test test/accrue/billing/events_transaction_test.exs` | ✅ | ⬜ pending |
| 112-01-02 | 01 | 1 | PROC-21 | T-112-02 | explicit local-only customer-row API remains separate from the promoted processor-backed contract, and projection-sync failure is deterministically proven with typed error plus telemetry/correlation evidence | unit | `cd accrue && mix test test/accrue/billing/events_transaction_test.exs` | ✅ | ⬜ pending |
| 112-02-01 | 02 | 2 | PROC-21 | T-112-03 | runtime support labels and the planning support matrix both promote `customer.update` to first-party truth | unit+static | `cd accrue && mix test test/accrue/processor/capabilities_test.exs && rg -n "customer.update|Accrue.Billing.update_customer/2|all first-party" lib/accrue/processor/capabilities.ex ../.planning/processor-support-matrix.md` | ✅ | ⬜ pending |
| 112-02-02 | 02 | 2 | PROC-21 | T-112-04 | Fake, Stripe, and Braintree proofs pin accepted attrs, rejected attrs, projection semantics, and adapter truth without network dependence | integration | `cd accrue && mix test test/accrue/billing/events_transaction_test.exs test/accrue/processor/fake_test.exs test/accrue/processor/braintree_test.exs test/accrue/processor/stripe_test.exs` | ✅ | ⬜ pending |
| 112-03-01 | 03 | 3 | PROC-21 | T-112-05 | example host exposes a thin provider-neutral helper adjacent to existing billing helpers | integration | `cd examples/accrue_host && mix test test/accrue_host/billing_facade_test.exs` | ✅ | ⬜ pending |
| 112-03-02 | 03 | 3 | PROC-21 | T-112-06 | installer template and host proof stay generic and do not leak Stripe/Braintree jargon into the shared helper | integration | `cd examples/accrue_host && mix test test/accrue_host/billing_facade_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `accrue/lib/accrue/billing.ex`, `accrue/lib/accrue/processor/capabilities.ex`, and `.planning/processor-support-matrix.md` all exist.
- [x] `accrue/test/accrue/processor/capabilities_test.exs`, `accrue/test/accrue/billing/events_transaction_test.exs`, `accrue/test/accrue/processor/fake_test.exs`, `accrue/test/accrue/processor/braintree_test.exs`, and `accrue/test/accrue/processor/stripe_test.exs` all exist.
- [x] `examples/accrue_host/lib/accrue_host/billing.ex`, `examples/accrue_host/test/accrue_host/billing_facade_test.exs`, and `accrue/priv/accrue/templates/install/billing.ex.eex` all exist.

---

## Manual-Only Verifications

All planned phase behaviors have automated verification. No manual-only gate is required for planning.

---

## Validation Sign-Off

- [x] All tasks have automated verification
- [x] Sampling continuity: no 3 consecutive tasks without automated verification
- [x] Wave 0 covers every referenced proof lane
- [x] No watch-mode flags
- [x] Feedback latency < 300 seconds
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
