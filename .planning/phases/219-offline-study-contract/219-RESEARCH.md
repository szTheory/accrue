# Phase 219: Offline study contract - Research

**Researched:** 2026-08-03  
**Domain:** Device-bound offline entitlement proofs, ES256/JWS, atomic reconciliation  
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Publish exactly four proof states: `fresh`, `stale_offline`, `denied`, and `invalid`. `reconnect_required` is a bounded next action derived from a state and attempted operation, not a fifth proof state.
- **D-02:** `fresh` requires a valid device-bound allow proof whose signed temporal bounds and monotonic high-water checks pass and whose `fresh_until` has not been crossed. It permits the proof's normalized entitled plans, features, and quantities.
- **D-03:** `stale_offline` requires the same valid allow proof after `fresh_until` but before any explicit signed `exp`, with no newer accepted denial or superseding revision. It preserves already-downloaded lessons and local learner-progress reads/writes; new premium downloads, enrollment, export, purchase, account or rail mutation, and every other value-expanding action require reconnect.
- **D-04:** An explicit signed `exp` is a real protocol or known provider/access bound. Crossing it yields `invalid` with reason `hard_expired`; it is never calculated as `fresh_until + 72 hours` and there is no independent post-freshness grace cutoff.
- **D-05:** `denied` requires a verified current signed deny tombstone and prevents reselection of an older positive proof. `invalid` means no usable authorization proof. Both preserve the app shell, downloaded local data, and unsynced progress, but fail closed for all entitlement-gated study and value expansion. Accrue does not delete host-owned local learner data.
- **D-06:** Reasons are a closed, bounded public taxonomy: `ok`, `revalidation_due`, `signed_denial`, `hard_expired`, `proof_unavailable`, `signature_invalid`, `unknown_key`, `wrong_algorithm`, `wrong_type`, `wrong_issuer`, `wrong_audience`, `device_mismatch`, `future_not_valid`, `clock_rollback`, `superseded`, `device_revoked`, and `malformed`.
- **D-07:** Add `Accrue.Entitlements.Offline` as the small public context for registration, issuance, reconnect, pure verification support, and public-key rendering. Return tagged results and typed values; do not expose schemas, JOSE structs, provider evidence, reducers, secrets, or workers.
- **D-08:** Preserve existing `entitled?/2`, `has_active_plan?/2`, `features_for/1`, and quantity gate boolean/scalar fail-closed semantics. Offline outcomes are additive and never become server-gate inputs.
- **D-09:** Publish a versioned compact ES256 JWS profile with protected `alg: "ES256"`, `typ: "accrue-entitlement-proof+jwt"`, and `kid`; payload includes version, issuer, audience, token ID, opaque account subject, P-256 JWK thumbprint confirmation, account revision, `iat`, `nbf`, `fresh_until`, explicit `exp`, allow/deny disposition, normalized entitlements, and bounded denial metadata.
- **D-10:** Publish a cacheable JWKS containing only public P-256 verification keys with distinct stable `kid` values and verification/signing-use metadata. The authenticated host chooses route mounting.
- **D-11:** Keep signing behind a host-implementable key-provider behaviour. Private JWKs never enter the database, JWKS, logs, telemetry, diagnostics, or production fixtures. Publish new public keys before issuing with them and retain prior verification keys until every actually-issued proof plus skew/reconnect buffer has elapsed.
- **D-12:** Verification is allowlist-based and fail-closed. It must reject token-directed key fetching, and validate fixed algorithm/type/version/issuer/audience, signature, key curve/use, claims, time bounds, account/device binding, recomputed thumbprint, disposition, and monotonic ordering; reject duplicate security-sensitive JSON members and unknown critical behavior.
- **D-13:** Publish synthetic versioned golden fixtures covering valid allow/deny, negative crypto/binding cases, stale/no-72-hour behavior, ordering, denial precedence, rotation, and replacement crashes. Private test keys stay explicitly test-only.
- **D-14:** Proofs, fixtures, issuance metadata, telemetry, and diagnostics contain no adopter identity, PII, raw provider bodies, transaction/notification identity, or device private key. Do not claim DRM, remote offline revocation, or hardware attestation.
- **D-15:** Reconnect is authenticated account + device proof-of-possession with installation ID, one-time nonce, idempotency key, and client high-water comparison hints only.
- **D-16:** Refresh due sources under their explicit schedules; reuse source registry, repair checkpoints, durable wakeups, backoff, rate budgets, and host-owned Oban. Bounded inline work only; longer work continues durably.
- **D-17:** Do not issue a positive proof while any required due source is retrying, quarantined, rate-limited, unavailable, or unresolved. Return typed bounded `pending`, retain the prior verified cache, and do not create partial allow policy.
- **D-18:** After convergence, one transaction locks/rereads account and device, reads canonical snapshot/revision, rechecks device, records privacy-safe issuance/high-water metadata, and produces fresh allow or signed denial.
- **D-19:** A locally authoritative revoked device may receive a bound deny tombstone after proof-of-possession; otherwise no-entitlement denial follows due-source convergence.
- **D-20:** The client verifies returned JWS before durable compare-and-replace. Ordering uses revision, denial precedence, issuance time, and freshness horizon; a crash cannot expose a partial candidate.
- **D-21:** Database locks and constraints are correctness authority. Oban uniqueness/idempotency only coalesce work. Retry has bounded exponential backoff, jitter, provider `Retry-After`, durable attempts, and terminal `needs_repair`.
- **D-22:** Emit allowlisted operational telemetry only; never emit proof bytes, key material, account tokens, raw evidence, or PII.
- **D-23:** Guidance names learner job/next action rather than proof/provider internals. Stale copy preserves downloaded lessons/progress; denial says access is unavailable and preserves local data.
- **D-24:** Phase 219 defines typed values, guidance keys, and copy seeds only; Phase 220/host renders accessible UI.

### the agent's Discretion
The planner may choose internal module/file names, final function arities, struct fields, JWKS Plug name, signing/audit record name, reconnect-attempt persistence, due intervals, inline timeout, backoff/page budgets, telemetry event names, and key-retirement buffer. These choices must preserve the closed four-state contract, ES256/JWKS semantics, gate compatibility, host-owned runtime, no-partial-allow rule, database correctness, privacy limits, fixtures, and atomic replacement.

### Deferred Ideas (OUT OF SCOPE)
No Crosswake core runtime dependency, adopter-facing UI/full operator runbooks, Google Play, arbitrary TTL/risk matrices, hardware attestation/DRM, or changed existing gate return types.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| OFF-01 | Independently verify compact ES256 proof with published versioned protocol/fixtures and no signing secret. | Strict JOSE verifier, public-only JWKS, protocol fixtures, and host key-provider boundary. |
| OFF-02 | 30-day revalidation shortened by an earlier known provider bound; stale after it, no 72-hour cutoff. | Separate `fresh_until` from explicit `exp`; derive expiry from snapshot authorization bounds. |
| OFF-03 | Preserve downloaded lessons/local progress while stale and pause all expansion. | Typed action-policy result maps `stale_offline` to local-continuity only. |
| OFF-04 | Four states + bounded reason metadata without gate compatibility break. | Additive `Offline` context/value objects; never alter existing facade. |
| OFF-05 | Authenticated, due-rail reconnect and atomic newer allow/deny replacement. | Existing account/device/projector/reconciliation lock-and-wakeup patterns. |
| OFF-06 | Resist protocol confusion, proof copy/replay/rollback/revocation/rotation and protect privacy. | Fixed verification profile, RFC-7638 binding, high-water ordering, denial precedence, public-key rotation. |
</phase_requirements>

## Summary

Phase 219 should promote the checked-in test-only ES256 corpus into one public, versioned offline-proof protocol and a narrow `Accrue.Entitlements.Offline` facade. The existing `Device`, `Snapshot`, `Projector`, decision-case export, and Apple repair machinery already supply the durable identity, revision, canonical authorization, fixture, and due-work primitives. [VERIFIED: codebase grep]

Use JOSE for the compact JWS mechanics, but keep semantic validation in Accrue-owned typed code: JOSE's strict verifier can whitelist `ES256`, while the protocol must additionally enforce the fixed protected type, local `kid` lookup, exact bindings, bounded claims, duplicate-member checks, state calculation, and cache ordering. [CITED: https://jose.hexdocs.pm/JOSE.JWS.html] [CITED: https://www.rfc-editor.org/rfc/rfc7515.html] [CITED: https://www.rfc-editor.org/rfc/rfc8725.html]

**Primary recommendation:** Ship an additive proof issuer/verifier/key-provider/reconnect slice around the existing canonical snapshot; issue only from a transactionally reread, fully due-converged account and replace client cache only with a locally verified, ordering-newer proof.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Key custody, JWS issuance, due-source convergence | API / Backend | Database / Storage | The server owns billing truth, private keys, and final authorization. [VERIFIED: codebase grep] |
| Device registration and nonce proof-of-possession | API / Backend | Database / Storage | Durable device lifecycle and account-scoped uniqueness already live in PostgreSQL. [VERIFIED: codebase grep] |
| Independent proof verification/high-water/cache replacement | Browser / Client | — | A disconnected registered device must decide from public keys and retained state only. [ASSUMED] |
| Canonical entitlement/revision read | Database / Storage | API / Backend | `Projector` is the sole transactionally locked revision writer; issuer consumes that committed result. [VERIFIED: codebase grep] |
| JWKS delivery | CDN / Static | Frontend Server (SSR) | Public, cacheable verification material is host-routed, contains no private key, and is not billing authority. [CITED: https://www.rfc-editor.org/rfc/rfc7517.html] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---|---|---|---|
| `:jose` | `~> 1.11` (current 1.11.12, published 2025-11-20) | Compact JWS/JWK/JWKS signing and strict ES256 verification | Official Hex package documents `verify_strict/3` algorithm allowlisting; use it behind Accrue-owned semantics. [CITED: https://hex.pm/packages/jose] [CITED: https://jose.hexdocs.pm/JOSE.JWS.html] |
| OTP `:crypto` | OTP 28 available locally | SHA-256/thumbprint helpers and independent test cross-checks | Existing verifier already uses it; OTP documents `crypto:hash/2`. [VERIFIED: codebase grep] [CITED: https://www.erlang.org/doc/apps/crypto/crypto.html] |

### Supporting

| Library | Version | Purpose | When to Use |
|---|---|---|---|
| Existing Ecto/PostgreSQL | project `~> 3.13` / PostgreSQL 14+ | locks, constraints, issuance/attempt metadata | Final reconnect authorization/issuance transaction only. [VERIFIED: codebase grep] |
| Existing Oban | project `~> 2.21` | coalesce/continue due repair | Retryable or over-budget reconnect work; never as an authorization lock. [VERIFIED: codebase grep] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| ES256 public-key proof | HMAC token | Reject: every offline verifier would hold a minting secret. [VERIFIED: project authority] |
| JOSE plus Accrue semantic verifier | Hand-written JWS crypto | Reject: parsing/signature/serialization edge cases are security-sensitive; retain small explicit policy checks around JOSE. [CITED: https://www.rfc-editor.org/rfc/rfc8725.html] |
| Device-bound lease | DRM/hardware attestation | Out of scope; proof binding limits copying but cannot remotely revoke a disconnected device. [VERIFIED: project authority] |

**Installation:**

```bash
cd accrue && mix deps.get # after adding {:jose, "~> 1.11"}
```

**Version verification:** `mix hex.info jose` returned 1.11.12, released 2025-11-20, with HexDocs and source links. [CITED: https://hex.pm/packages/jose]

## Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---|---|---|---|---|---|---|
| `jose` | Hex | established | 250,285 / 7 days | `potatosalad/erlang-jose` | Approved | Add as `~> 1.11` after normal dependency review. [CITED: https://hex.pm/packages/jose] |

**Packages removed due to [SLOP] verdict:** none.

**Packages flagged as suspicious [SUS]:** none.

The shared legitimacy seam currently accepts only npm, PyPI, and crates ecosystems, so its required Hex invocation was attempted but cannot produce a Hex verdict; the package is instead verified against authoritative Hex registry and HexDocs records. [CITED: gsd-tools package-legitimacy CLI]

## Architecture Patterns

### System Architecture Diagram

```text
Authenticated host + device PoP
        │ installation_id, nonce signature, idempotency key
        ▼
Accrue.Entitlements.Offline.reconnect
        ├─ validate account/device lifecycle ──► durable Device row
        ├─ ask Source.Registry which rails are due
        ├─ inline bounded repair or durable wakeup ──► existing reconciliation/Oban
        │                                      │ unresolved
        │                                      └────────────► {:pending, reason, retry_after}
        ▼ all due sources converged
DB transaction: lock account + device → reread Snapshot/revision → issue allow or deny JWS
        ▼
Client verifies JWS against cached/published JWKS, bindings and high-water
        ▼
atomic compare-and-replace
        ├─ allow fresh ─────────► full normalized entitlement policy
        ├─ allow stale_offline ─► downloaded study + local progress only
        └─ deny/invalid ────────► app shell/local data retained, gated actions fail closed
```

### Recommended Project Structure

```text
accrue/lib/accrue/entitlements/offline/
├── proof.ex             # typed claims, strict parsing/state classification
├── issuer.ex            # snapshot-to-proof, self-verification
├── verifier.ex          # public-key verification and bounded reason mapping
├── key_provider.ex      # host behaviour + public JWKS renderer
├── reconnect.ex         # authenticated due-source coordination
└── issuance.ex          # privacy-safe durable issuance/high-water metadata
accrue/test/accrue/entitlements/
├── offline_test.exs
├── offline_reconnect_test.exs
└── offline_protocol_test.exs
accrue/priv/entitlements/
└── v1.59-offline-golden-vectors.json
```

### Pattern 1: Two-stage strict verification

**What:** Decode only enough protected-header data to choose a locally configured/cached `kid`; reject unknown/duplicate/header-confused input before `JOSE.JWS.verify_strict/3`; then validate every semantic claim and ordering rule before returning a public outcome. [CITED: https://jose.hexdocs.pm/JOSE.JWS.html] [CITED: https://www.rfc-editor.org/rfc/rfc7515.html]

**When to use:** Every client/server proof verification, including returned reconnect proof; never trust a token's `jku`, `x5u`, key, or labelled expected fixture result. [CITED: https://www.rfc-editor.org/rfc/rfc8725.html]

```elixir
# Source: https://jose.hexdocs.pm/JOSE.JWS.html
with {:ok, %{"alg" => "ES256", "typ" => @type, "kid" => kid}} <- protected_header(compact),
     {:ok, public_jwk} <- key_store.fetch(kid),
     {true, payload, _jws} <- JOSE.JWS.verify_strict(public_jwk, ["ES256"], compact),
     {:ok, claims} <- validate_profile(payload, expected_binding, high_water, now) do
  {:ok, classify(claims, now)}
else
  _ -> {:ok, %Decision{state: :invalid, reason: :malformed}}
end
```

### Pattern 2: Final issuance transaction, not a provider transaction

**What:** Run provider repair outside the lock. Once every required source is settled, lock and reread `Account` and `Device`, fetch the canonical snapshot, recheck lifecycle, persist only redacted issuance metadata, and issue allow/deny from that exact committed revision. [VERIFIED: codebase grep]

**When to use:** The terminal reconnect decision. It prevents a stale snapshot or revoked device from producing a positive proof. [ASSUMED]

### Pattern 3: Ordering-aware atomic cache replacement

**What:** Verify candidate first; compare `{revision, denial precedence, iat, fresh_until}` with persisted high-water; write a complete candidate to a same-directory temp path and atomically rename only when it wins. [VERIFIED: codebase grep]

**When to use:** Cross-language/reference-host client contract, including crash injection before and after replacement. [VERIFIED: project authority]

### Anti-Patterns to Avoid

- **Use `fresh_until + 72h` as expiry:** violates the explicit no-independent-grace policy. [VERIFIED: project authority]
- **Let JOSE/header choose the algorithm or remote key URL:** permits algorithm/key-confusion paths; fixed local policy must select both. [CITED: https://www.rfc-editor.org/rfc/rfc8725.html]
- **Issue after partial repair:** an unavailable/rate-limited due rail must produce `pending`, not a partial positive authorization. [VERIFIED: project authority]
- **Use Oban uniqueness as a lock:** retain PostgreSQL row locks/constraints as correctness authority. [VERIFIED: codebase grep]
- **Replace cache before verifying/comparing:** can downgrade a deny or reveal a crash-visible partial candidate. [VERIFIED: project authority]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Compact JWS signing/signature validation | custom base64/JWS/ECDSA implementation | `:jose` with explicit `verify_strict` allowlist | Standard compact serialization and ES256 crypto have non-obvious format/security rules. [CITED: https://jose.hexdocs.pm/JOSE.JWS.html] |
| Account authorization projection | parallel offline snapshot reducer | existing `Snapshot` + `Projector` | The existing projector is the sole revision writer. [VERIFIED: codebase grep] |
| Due-source retry | new offline scheduler | current reconciliation checkpoints/wakeups/Oban | Existing path already has locks, `Retry-After`, bounded retries, and `needs_repair`. [VERIFIED: codebase grep] |
| Key custody | database private-JWK column | host key-provider behaviour | Keeps private material out of billing persistence and supports KMS/HSM implementations. [VERIFIED: project authority] |

**Key insight:** cryptography should prove a bounded server decision; it must not create a second billing authority or a client-controlled source of truth. [VERIFIED: project authority]

## Common Pitfalls

### Pitfall 1: Conflating stale freshness with hard expiry

**What goes wrong:** Client treats `fresh_until` as an entitlement expiry or stacks an undocumented 72-hour grace timer. [VERIFIED: project authority]

**How to avoid:** Derive `fresh_until = min(iat + 30 days, earliest known provider/access bound)` and maintain explicit `exp` independently; only `exp` produces `invalid/hard_expired`. [VERIFIED: project authority]

### Pitfall 2: Parsing valid JSON as proof validity

**What goes wrong:** Duplicate sensitive fields, unexpected `crit`, a wrong key/type/audience, or a replayed lower proof wins due to permissive decode/order logic. [CITED: https://www.rfc-editor.org/rfc/rfc7515.html] [CITED: https://www.rfc-editor.org/rfc/rfc8725.html]

**How to avoid:** Check exact protected header and raw duplicate members, allowlisted local key, strict signature, all bounded claim types, exact binding, and persisted high-water before classification/replacement. [CITED: https://www.rfc-editor.org/rfc/rfc7638.html]

### Pitfall 3: Leaking proof/provider data

**What goes wrong:** JWS claims, telemetry, fixture metadata, or support diagnostics expose email, token bytes, raw receipt/JWS, provider identity, or public/private key bytes. [VERIFIED: project authority]

**How to avoid:** Use opaque account subject, hashed/redacted issuance correlation, bounded reason/action enums, and fixture-only synthetic keys. [VERIFIED: project authority]

### Pitfall 4: Retiring a key by fixed calendar arithmetic

**What goes wrong:** Removing an old public key strands a still-hard-valid offline proof, especially because `exp` is shortened by real provider bounds rather than an assumed 33-day period. [VERIFIED: project authority]

**How to avoid:** Record maximum actually-issued `exp` per `kid`; retain verification key through that horizon plus documented skew/reconnect buffer. [VERIFIED: project authority]

## Code Examples

### RFC-7638 P-256 thumbprint input

```elixir
# Source: https://www.rfc-editor.org/rfc/rfc7638.html
canonical = ~s({"crv":"P-256","kty":"EC","x":"#{x}","y":"#{y}"})
thumbprint = canonical |> :crypto.hash(:sha256) |> Base.url_encode64(padding: false)
```

For the protocol, independently validate `kty == "EC"`, `crv == "P-256"`, and each decoded coordinate length before generating this exact lexicographic JSON. [CITED: https://www.rfc-editor.org/rfc/rfc7518.html] [CITED: https://www.rfc-editor.org/rfc/rfc7638.html]

### State classification after verified proof

```elixir
def classify(%{disposition: :deny}, _now), do: {:denied, :signed_denial}
def classify(%{exp: exp}, now) when now >= exp, do: {:invalid, :hard_expired}
def classify(%{fresh_until: until}, now) when now >= until, do: {:stale_offline, :revalidation_due}
def classify(_proof, _now), do: {:fresh, :ok}
```

The real implementation must run this only after all cryptographic, binding, lifecycle, and ordering validation succeeds. [VERIFIED: project authority]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| Test-only fixed-key/offline verifier with legacy claim names | Public versioned ES256/JWKS profile with host key-provider and production-shaped fixtures | Phase 219 | Reconcile existing fixture producer/consumer rather than fork it. [VERIFIED: codebase grep] |
| Independent 72-hour cutoff formulations | 30-day revalidation with stale downloaded-study continuity; explicit `exp` only for real hard bounds | v1.59 authority | No `fresh_until + 72h` logic, fixture, or key-retirement calculation. [VERIFIED: project authority] |

**Deprecated/outdated:** the test-only embedded offline key/claim profile cannot be production issuer configuration; it remains only a synthetic fixture bootstrap. [VERIFIED: codebase grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | The reference host/client owns durable atomic filesystem/cache replacement, while core publishes the contract and server components. | Architectural Responsibility Map | Plan may misassign client implementation work to core. |
| A2 | `fresh_until` is computed as the minimum of 30 days and known provider/access bound. | Common Pitfalls | Exact existing snapshot-bound semantics may need an adapter. |

## Open Questions (RESOLVED)

1. **RESOLVED — Host-owned device proof-of-possession wire shape and nonce persistence interface.**
   - Selection: expose `Offline.challenge(account, installation_id, opts \\ [])` returning `%Offline.Challenge.Value{nonce, expires_at, purpose}` and `Offline.register_device(account, %Offline.Registration.Request{}, opts \\ [])`, where the request contains exactly `installation_id`, `device_public_jwk`, `challenge_id`, `nonce_signature`, and `idempotency_key`. The host authentication/authorization callback remains in `opts`; no controller or route is owned by Accrue.
   - Signed input: a canonical length-prefixed byte sequence over protocol version, purpose, opaque account UUID, installation ID, challenge ID, raw one-time nonce, and the idempotency-key digest. The server validates the submitted public P-256 JWK, recomputes its RFC-7638 thumbprint, verifies the signature, and never accepts a client-supplied thumbprint.
   - Persistence: `accrue_entitlement_offline_challenges` stores `id`, `account_id`, `installation_id`, `nonce_digest`, `purpose`, `expires_at`, `consumed_at`, `idempotency_digest`, and timestamps. The raw nonce is returned once and is not persisted; challenge consumption and device insertion occur under one database transaction/row lock.
   - Rationale: typed values preserve the small Phoenix-style public facade while binding PoP to account, installation, purpose, one-time state, and exact idempotent body without exposing transport or secret material. This is the exact interface used by Plan 219-03.
2. **RESOLVED — Persisted issuance/high-water/audit and key-retirement fields.**
   - Selection: `accrue_entitlement_offline_issuances` stores exactly `id`, `account_id`, `device_id`, `token_id_hash`, `kid`, `revision`, `disposition`, `issued_at`, `fresh_until`, nullable `expires_at`, `correlation_hash`, and timestamps. Existing `Device.last_accepted_revision` remains the device revision high-water; the Device extension stores only validated public `kty`, `crv`, `x`, and `y` plus the recomputed thumbprint.
   - Ordering/index contract: token identity is unique; `(device_id, revision, disposition, issued_at)` is indexed for deterministic ordering; database checks enforce closed disposition, nonnegative revision, and `issued_at <= fresh_until <= expires_at` when `expires_at` is present.
   - Rotation query: `Issuance.retirement_requirements(repo, now, opts)` groups actual rows by `kid`. Retirement eligibility is `max(expires_at) + 86,400 seconds` using the documented minimum clock-skew/reconnect buffer; if any issuance for the key has null `expires_at`, that key is `:never` eligible for normal retirement. `Offline.verification_keys/1` rejects provider omission of an active or not-yet-eligible key as `{:error, :config_invalid}`.
   - Rationale: this is the narrow durable set needed for atomic issuance ordering, privacy-safe correlation, denial precedence, and D-11 actual-proof retention. It supports before/at/after retirement queries without archiving compact proofs, raw nonce/idempotency values, account tokens, provider evidence, PII, or private keys. These are the exact fields and interfaces used by Plans 219-03 and 219-04.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| Elixir / OTP | core implementation/tests | ✓ | Elixir 1.19.5 / OTP 28 | — |
| Mix + Hex | add/verify `:jose` | ✓ | Mix 1.19.5 | — |
| PostgreSQL | Ecto transaction/reconnect tests | ✓ | local socket accepts connections | — |
| OpenSSL | OTP cryptographic backend | ✓ | 3.6.2 | use target OTP/OpenSSL compatibility matrix in CI |

**Missing dependencies with no fallback:** none.

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit + Mox + StreamData, existing project dependencies. [VERIFIED: codebase grep] |
| Config file | `accrue/test/test_helper.exs` |
| Quick run command | `cd accrue && mix test test/accrue/entitlements/offline_golden_vectors_test.exs` |
| Full suite command | `cd accrue && mix test.all` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| OFF-01 | compact proof/JWKS verifies with public key only | unit + fixture | `mix test test/accrue/entitlements/offline_protocol_test.exs` | ❌ Wave 0 |
| OFF-02 | fresh/stale/explicit-exp boundaries and no 72h cutoff | unit + property | `mix test test/accrue/entitlements/offline_test.exs` | ❌ Wave 0 |
| OFF-03 | stale permits only continuity policy | unit | `mix test test/accrue/entitlements/offline_test.exs` | ❌ Wave 0 |
| OFF-04 | four state/reason contract; legacy gates unchanged | unit + regression | `mix test test/accrue/entitlements/offline_test.exs test/accrue/entitlements_test.exs` | ❌ / ✅ |
| OFF-05 | due/pending/final lock and replacement ordering | integration + fault injection | `mix test test/accrue/entitlements/offline_reconnect_test.exs` | ❌ Wave 0 |
| OFF-06 | negative JWS/binding/rollback/revocation/rotation/privacy corpus | unit + property | `mix test test/accrue/entitlements/offline_protocol_test.exs` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** targeted ExUnit command for the changed module plus existing vector test. [VERIFIED: codebase grep]
- **Per wave merge:** `cd accrue && mix test.all`. [VERIFIED: codebase grep]
- **Phase gate:** full suite green and fixture drift/export checks green before verification. [VERIFIED: project authority]

### Wave 0 Gaps

- [ ] `accrue/test/accrue/entitlements/offline_protocol_test.exs` — public profile/JWKS/negative vectors.
- [ ] `accrue/test/accrue/entitlements/offline_test.exs` — state/action policy and compatibility.
- [ ] `accrue/test/accrue/entitlements/offline_reconnect_test.exs` — Ecto locking/due/pending/final issuance.
- [ ] Property cases for ordering/deny precedence/clock rollback and no-private-material regression.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | yes | Host-authenticated account plus server nonce/device proof-of-possession. [VERIFIED: project authority] |
| V3 Session Management | yes | One-time nonce, idempotency, and authenticated reconnect; do not treat reachability as authority. [VERIFIED: project authority] |
| V4 Access Control | yes | Server gates remain fail-closed; client proof supplies only offline study policy. [VERIFIED: project authority] |
| V5 Input Validation | yes | Strict compact/header/JWK/claims size/type/duplicate validation. [CITED: https://www.rfc-editor.org/rfc/rfc7515.html] |
| V6 Cryptography | yes | ES256 allowlist, published verification keys only, `kid` rotation, RFC-7638 binding. [CITED: https://www.rfc-editor.org/rfc/rfc8725.html] |

### Known Threat Patterns for offline proof stack

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| `alg=none`/HS-vs-ES confusion | Tampering | fixed `ES256` header plus JOSE strict algorithm allowlist. [CITED: https://www.rfc-editor.org/rfc/rfc8725.html] |
| Token-directed remote-key URL | Spoofing | only configured/cached `kid` lookup; reject `jku`/`x5u`. [VERIFIED: project authority] |
| Copied proof | Spoofing | exact account/installation and recomputed P-256 JWK thumbprint binding. [CITED: https://www.rfc-editor.org/rfc/rfc7638.html] |
| Replay/rollback/older allow beating deny | Tampering | persisted high-water and ordered deny-tombstone precedence. [VERIFIED: project authority] |
| Key compromise/early key removal | Elevation of Privilege | overlapping public JWKS, actual-expiry-based retirement, incident disable/deny procedure. [VERIFIED: project authority] |
| PII/provider evidence in proof or logs | Information Disclosure | opaque subject, bounded enums, redacted metadata and synthetic fixtures. [VERIFIED: project authority] |

## Sources

### Primary (HIGH confidence)

- [RFC 7515](https://www.rfc-editor.org/rfc/rfc7515.html) — compact serialization, protected headers, duplicate-header handling.
- [RFC 7517](https://www.rfc-editor.org/rfc/rfc7517.html) — JWKS/JWK `kid`, key metadata, and public material handling.
- [RFC 7638](https://www.rfc-editor.org/rfc/rfc7638.html) — EC P-256 JWK thumbprint canonical members.
- [RFC 8725](https://www.rfc-editor.org/rfc/rfc8725.html) — algorithm validation and JWT/JWS threat mitigations.
- [RFC 7518](https://www.rfc-editor.org/rfc/rfc7518.html) — EC P-256 public key representation.

### Secondary (MEDIUM confidence)

- [JOSE JWS API](https://jose.hexdocs.pm/JOSE.JWS.html) — strict algorithm whitelist/signing API.
- [JOSE on Hex](https://hex.pm/packages/jose) — package legitimacy/version/public metadata.
- [OTP crypto](https://www.erlang.org/doc/apps/crypto/crypto.html) — hash/crypto primitives.
- Current repository contexts, authority bundle, code, migrations, and tests — integration boundaries and locked policy.

## Metadata

**Confidence breakdown:**

- Standard stack: MEDIUM — JOSE package/version and API checked against authoritative Hex/HexDocs; the shared legitimacy seam does not support Hex. [CITED: https://hex.pm/packages/jose]
- Architecture: HIGH — driven by locked Phase 219 decisions and existing code seams. [VERIFIED: codebase grep]
- Pitfalls: HIGH — protocol risks are cross-checked against IETF BCP and locked policy. [CITED: https://www.rfc-editor.org/rfc/rfc8725.html]

**Research date:** 2026-08-03  
**Valid until:** 2026-09-02 (re-check immediately if JOSE/OTP security advisories or the v1.59 watchlist change).
