---
phase: 219-offline-study-contract
reviewed: 2026-08-04T01:09:32Z
depth: deep
files_reviewed: 24
files_reviewed_list:
  - accrue/lib/accrue/entitlements/decision_cases/markdown.ex
  - accrue/lib/accrue/entitlements/device.ex
  - accrue/lib/accrue/entitlements/offline.ex
  - accrue/lib/accrue/entitlements/offline/challenge.ex
  - accrue/lib/accrue/entitlements/offline/issuance.ex
  - accrue/lib/accrue/entitlements/offline/issuer.ex
  - accrue/lib/accrue/entitlements/offline/key_provider.ex
  - accrue/lib/accrue/entitlements/offline/proof.ex
  - accrue/lib/accrue/entitlements/offline/reconnect.ex
  - accrue/lib/accrue/entitlements/offline/registration.ex
  - accrue/lib/accrue/entitlements/offline/source_coordinator.ex
  - accrue/mix.exs
  - accrue/mix.lock
  - accrue/priv/entitlements/v1.59-offline-golden-vectors.json
  - accrue/priv/repo/migrations/20260803040000_create_accrue_offline_proof_state.exs
  - accrue/test/accrue/entitlements/offline_golden_vectors_test.exs
  - accrue/test/accrue/entitlements/offline_protocol_test.exs
  - accrue/test/accrue/entitlements/offline_reconnect_test.exs
  - accrue/test/accrue/entitlements/offline_registration_test.exs
  - accrue/test/accrue/entitlements/offline_test.exs
  - accrue/test/mix/tasks/accrue_install_test.exs
  - accrue/test/support/entitlements/offline_golden_vector_verifier.ex
  - examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift
  - examples/crosswake_tracer/Tests/AccrueOfflineClientTests/GoldenVectorTests.swift
findings:
  critical: 7
  warning: 2
  info: 0
  total: 9
status: issues_found
---

# Phase 219: Code Review Report

**Reviewed:** 2026-08-04T01:09:32Z
**Depth:** deep
**Files Reviewed:** 24
**Status:** issues_found

## Summary

The offline protocol has serious correctness and security gaps across the reconnect, compact-JWS, and Swift cache boundaries. Most notably, the public API can never mint the reconnect challenge it requires, a due source can be relabeled non-due to bypass the no-partial-allow rule, duplicate JSON-member checks can be bypassed with escaped names, and the advertised independent Swift verifier does not execute cryptographic verification at all. Focused Elixir and Swift tests pass, but they do not cover these paths.

## Critical Issues

### CR-01: Reconnect can never receive a valid public challenge

**File:** `accrue/lib/accrue/entitlements/offline.ex:160-165`

**Issue:** The only public challenge producer always persists `purpose: :registration`. `Reconnect.consume_pop/4` accepts only `%Challenge{purpose: :reconnect}` at `offline/reconnect.ex:160-176`, and no reviewed caller creates that purpose. Consequently every public reconnect request rolls back as `:challenge_invalid`; the claimed authenticated reconnect flow is unreachable.

**Fix:** Add a separately authorized reconnect-challenge operation (or an explicit, validated purpose argument that only permits `:registration` and `:reconnect`) and have it persist `purpose: :reconnect`. Add an end-to-end reconnect test that obtains this challenge through the public facade, signs it, and reaches both pending and issued outcomes.

### CR-02: A refresh can bypass the no-partial-allow guard by clearing `due`

**File:** `accrue/lib/accrue/entitlements/offline/reconnect.ex:66-75,91-100`

**Issue:** `refresh_due/4` decides to refresh from the original status, but stores the coordinator-returned status unchanged. `settle/5` then filters only returned statuses with `due == true`. A required source initially reported as `%{due: true}` can return a valid `%SourceStatus{due: false, state: :pending}`; validation permits that combination, `unresolved` becomes empty, and `Issuer.issue/3` produces an allow proof even though the required refresh is unresolved. This violates D-17's explicit no-positive-proof-until-all-due-sources-converge rule.

**Fix:** Preserve the original due membership for this reconnect attempt (for example, replace only state/retry fields on the original status), or reject a refresh response that changes `due`. Calculate unresolved sources from the original due set and add a regression test for `due: true -> due: false, state: :pending`.

### CR-03: Escaped duplicate protected/payload member names evade the fail-closed duplicate check

**File:** `accrue/lib/accrue/entitlements/offline/proof.ex:216-227,534-537`

**Issue:** Duplicate-member detection is a regex over literal spellings such as `"iss"`. JSON permits escaped member names, so a signed payload/header containing both `"\\u0069ss"` and `"iss"` (or an escaped duplicate `alg`, `kid`, etc.) is decoded by JSON parsers as duplicate security-sensitive members but is not counted by this regex. Different JOSE/JSON stacks can select different duplicate values, defeating the specified cross-language ambiguity defense.

**Fix:** Use a JSON parser/tokenizer that rejects duplicate object keys after JSON unescaping at every object level, before semantic validation; do not infer JSON structure with regex. Add signed corpus/protocol cases for escaped duplicate header and payload keys (including `cnf.jkt`).

### CR-04: The Swift "independent verifier" trusts fixture labels instead of verifying the JWS

**File:** `examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift:164-169,171-198`

**Issue:** `observe/1` derives accept/reject solely from `vector.expectedState` and returns `expectedReason` and `expectedCacheDisposition` verbatim. The CryptoKit verifier directly below it is never called. Therefore the Swift test at `GoldenVectorTests.swift:32-42` can pass when signatures, header/profile parsing, account/device binding, time checks, or high-water logic are broken or absent. This is the exact parity/safety evidence Phase 219 was meant to make merge-blocking.

**Fix:** Build the verification context and public key from each vector, call the CryptoKit verifier for every compact JWS, derive state/reason/next action/cache from that result, and compare that observation to fixture expectations only afterwards. Remove or wire up dead legacy claim shapes (`typ`, `account_id`, `device_id`, string `cnf`) so the Swift parser implements the published D-09 profile.

### CR-05: The durable Swift cache cannot enforce verified issuance/freshness ordering

**File:** `examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift:303-315,343-380,404-425`

**Issue:** `AtomicOfflineCache.replace` accepts arbitrary bytes plus caller-supplied disposition/revision and persists only those fields. It neither verifies a JWS nor receives/persists `iat` or `fresh_until`; `ProofReplacementOrder` compares only revision and denial precedence. Thus a caller can store unauthenticated bytes, and even a correctly verified candidate with a higher revision but older issuance/freshness replaces a newer cached proof. This contradicts D-20 and Plan 05's requirement to verify before comparison and retain revision, disposition, issuance time, and freshness horizon atomically.

**Fix:** Make replacement accept an internal verified-proof value containing compact bytes, revision, disposition, `iat`, and `fresh_until`; reject raw data. Persist and authenticate all high-water fields in the envelope, and use `ProofHighWater.accepts(newer:)` (or equivalent) for every replacement. Add restart and concurrent-process regressions for a higher-revision/older-iat candidate and for regressed freshness.

### CR-06: The Elixir verifier also admits higher-revision proofs with older issuance/freshness

**File:** `accrue/lib/accrue/entitlements/offline/proof.ex:389-410`

**Issue:** The `iat` and `fresh_until` high-water checks run only when `claims.revision == context.accepted_revision`. A proof with a greater revision but an older `iat` or a regressed freshness horizon passes. The phase contract explicitly says that no older issuance may replace accepted state, while client high-water values are the rollback defense. A valid-but-delayed proof can therefore roll a client back despite being older in issuance time.

**Fix:** Independently require candidate `iat >= accepted/high-water iat` and `fresh_until >= accepted/high-water freshness` before allowing any replacement, then apply revision and equal-revision denial precedence. Add vector and property cases for a greater revision paired with older `iat` and with lower `fresh_until`.

### CR-07: A superseded device is issued a fresh allow proof

**File:** `accrue/lib/accrue/entitlements/offline/issuer.ex:92-100`

**Issue:** `disposition/3` issues a denial for `:revoked` only. A `%Device{state: :superseded}` falls through to the normal snapshot check and can receive an allow proof bound to its old key. The issuer locks the device but does not enforce the active lifecycle state, so a replaced installation can continue acquiring fresh access.

**Fix:** Permit positive issuance only for `state: :active`; return an appropriate signed denial (or a bounded inactive-device error) for `:revoked` and `:superseded`. Cover both terminal states in issuance and reconnect tests.

## Warnings

### WR-01: Malformed reconnect request fields can raise instead of returning a tagged error

**File:** `accrue/lib/accrue/entitlements/offline/reconnect.ex:138-184,213-218`

**Issue:** The facade accepts any `%Reconnect.Request{}` without validating its field types or lengths. In `consume_pop/4`, `digest(request.nonce)` is evaluated before signature verification; `nil` or another non-binary value causes `:crypto.hash/2` to raise inside the transaction rather than yielding the documented `{:error, :invalid_request}`/`:challenge_invalid` result. A malformed external reconnect payload can become a 500 response.

**Fix:** Validate all request fields as bounded binaries before opening the transaction, and wrap/normalize invalid cryptographic input at the public boundary. Add tests for nil, non-binary, oversized nonce/signature/idempotency fields.

### WR-02: A malformed key-provider result can crash issuance through `Jason.decode!/1`

**File:** `accrue/lib/accrue/entitlements/offline/issuer.ex:150-156`

**Issue:** `kid/1` uses `Jason.decode!/1` while processing a provider-produced compact value. A provider outage/misconfiguration that returns a three-part token with non-JSON protected bytes raises out of `issue/3` rather than returning the advertised tagged `:config_invalid`/`:issuance_failed` failure.

**Fix:** Use `Jason.decode/1` in the `with` chain and validate a bounded string `kid`; normalize all parsing failures to a tagged issuance error. Add a provider test that returns malformed compact data.

---

_Reviewed: 2026-08-04T01:09:32Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep_
