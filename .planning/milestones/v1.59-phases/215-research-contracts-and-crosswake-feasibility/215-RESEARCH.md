# Phase 215: Research, contracts, and Crosswake feasibility - Research

**Researched:** 2026-08-01
**Domain:** Versioned entitlement-policy contracts, source capabilities, and iOS client-boundary feasibility
**Confidence:** MEDIUM

## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Add a human-readable `v1.59-AUTHORITY.md` manifest as the first v1.59 entry from `RESEARCH-INDEX.md`. It defines the bundle, active policy, precedence, review state, and effective date; it does not duplicate every research document.
- **D-02:** Use this precedence: current `PROJECT.md`/`STRATEGY.md`/`ROADMAP.md`/`REQUIREMENTS.md` scope guards; accepted v1.59 authority amendments; `v1.59-SUMMARY.md` and the decision-table contract; source provenance; specialist v1.59 research; then generic research and prompts as historical context.
- **D-03:** Record material claims in an amendment/supersession ledger with a stable claim ID, active wording, disposition, confidence, source IDs, effective date, superseded locations, rationale, and downstream phases/tests. Seed an explicit claim that supersedes every independent 72-hour cutoff formulation. Watchlist or dependency changes open a dated reassessment; they never silently change entitlement behavior.
- **D-04:** Keep source material and rejected alternatives rather than rewriting history. Reject both “latest prose edit wins” and an ADR/RFC per routine provider finding; reserve standalone ADRs/RFCs for broad, stable public-contract decisions.
- **D-05:** Author the decision cases once as a versioned, data-only Elixir contract and deterministically render the maintainer-facing Markdown table plus a checked-in, language-neutral JSON fixture corpus. — **Reversibility:** costly — reducers, ExUnit cases, Crosswake vectors, documentation, and support reason IDs will all depend on the case schema.
- **D-06:** The contract is proof/policy data, not production decision logic and not a public runtime API. Production reducers consume production domain types; exhaustive ExUnit consumers prove every named case. Keep the renderer/exporter deliberately simple so it cannot become a second reducer.
- **D-07:** Each case has a stable ID and contract version plus rail/environment-qualified evidence, prior source state, ordering tuple, expected source disposition, effective snapshot and revision delta, purchase eligibility, lease/continuity outcome, repair result, and a privacy-safe support reason.
- **D-08:** Add permutation, duplicate, out-of-order, survivor-source, concurrency, and transaction-boundary properties around the named cases. Later projection work must commit source grants, effective snapshot/revision, and audit event atomically; support and diagnostics name the same stable case/reason vocabulary.
- **D-09:** Use a checked-in minimal iOS reference target with a narrow host-owned `AccrueOfflineClient`-style adapter, compiled against a pinned Crosswake shell/core. Do not add Crosswake as an Accrue runtime dependency and do not invent undocumented bridge APIs.
- **D-10:** The tracer must prove all of RAIL-05 plus authenticated host transport: StoreKit 2 purchase with the account UUID as `appAccountToken`; transaction update and restore/current-entitlement handling; non-exported Secure Enclave P-256 device key with public-key/thumbprint registration and nonce proof; Keychain `ThisDeviceOnly` secure state; durable local state; monotonic `iat`/revision/freshness high-water checks; verified atomic allow/deny replacement; foreground/background and reconnect recovery. Device evidence is submitted to the server and never grants locally by itself.
- **D-11:** Merge-block JSON/JWS golden vectors, server contract tests, Swift compile/unit tests, rollback/older-revision/wrong-key/wrong-device/deny-precedence tests, and crash/fault-injected atomicity tests. Simulator StoreKit/Keychain runs are useful but advisory. A dated physical-device proof is required for Secure Enclave behavior, Keychain migration exclusion, lifecycle recovery, atomic replacement after termination, and authenticated Crosswake shell transport.
- **D-12:** Any missing native transport, StoreKit bridge, device-key, secure-state atomicity, high-water, or lifecycle/reconnect proof blocks later mobile runtime coupling. Protocol vectors and server-side offline work may continue, but the project must report `feasibility_blocked` rather than relabel partial proof as runtime feasibility.
- **D-13:** `scenePhase` and network-path changes may coalesce an authenticated reconciliation attempt; reachability is never entitlement authority. Only a verified, server-issued newer allow or signed denial can atomically replace cached state.
- **D-14:** Add a small `Accrue.Entitlements.Source` behaviour/registry with closed capability and outcome value objects. Keep it separate from `Accrue.Processor`: the processor boundary controls gateway resources, while the source boundary observes, restores, reconciles, manages, and supplies entitlement evidence. Do not use a protocol for configured registry data or expose a loose public nested map.
- **D-15:** Use consumer/JTBD dimensions `observation`, `control`, `restore`, `reconciliation`, `management`, and `offline`. Use the closed state vocabulary `supported`, `externally_managed`, `host_owned`, `deferred`, `unavailable`, and `feasibility_blocked`; do not collapse these into booleans.
- **D-16:** Externally managed is a successful, actionable outcome rather than an error. For example, Apple management returns an `externally_managed` result with a stable guidance key and management URL; an actually unavailable operation returns a typed capability error naming source, capability, code, and next action. Apple capability results must never dispatch into Stripe cancellation, dunning, retry, swap, proration, invoice, or payment-method mutations.
- **D-17:** The runtime contract is authoritative for host inspection; the entitlement-source matrix and HexDocs mirror its public subset. Add source conformance fixtures, code-to-doc literal drift gates, and negative gateway-leakage tests. UI consumers render plain-language guidance with text and action labels—not color-only status or backend vocabulary—and follow the current `brandbook/` voice authority: measured, exact, native, and durable.

### the agent's Discretion

The planner may choose exact internal module/file names, the Mix task name for deterministic rendering, and whether the authority ledger is a section or adjacent amendment file. These choices must preserve the locked properties above: one discoverable authority entry point, stable claim/case IDs, a non-public/non-runtime decision-case source, language-neutral exported vectors, and a closed public source-capability vocabulary.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope. UI implementation belongs to the later portal/admin proof phases already present in the roadmap; no new UI capability was added here.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RSCH-01 | Current, versioned research bundle with provenance, choices, and confidence | Authority manifest, precedence/ledger schema, index/drift gates |
| RSCH-02 | One case contract for reducers, fixtures, docs, and support | Data-only Elixir source, deterministic Markdown/JSON render, exhaustive and property consumers |
| RSCH-03 | Dated provider/dependency/policy/privacy/security watchlist | Existing v1.59 watchlist retained beneath the authority manifest and amendment workflow |
| RAIL-04 | Dedicated source-capability inspection, separate from processor support | Closed `Source` behaviour/registry, outcomes, conformance fixtures, documentation mirror gate |
| RAIL-05 | Crosswake boundary proven or explicitly blocked before coupling | Checked-in iOS tracer, capability checklist, golden vectors, physical-device evidence, hard block status |

## Summary

Phase 215 is a contract-and-proof phase, not a multi-rail runtime phase. Make the already-researched v1.59 bundle discoverable through one authority manifest, record supersessions as durable claim records, and make the no-independent-72-hour rule mechanically visible in generated policy outputs. [VERIFIED: codebase grep]

Use one versioned data-only case corpus as the source for the rendered decision table, JSON vectors, and ExUnit/property proof. Do not put case interpretation into this corpus; `GrantProjector` and later runtime code own production decisions. The existing processor capability map and its shell drift verifier show the repository’s preferred pattern: executable typed contract plus a narrow documentation mirror and negative drift checks. [VERIFIED: codebase grep]

Crosswake feasibility is currently unproven: this research found no authoritative public Crosswake bridge API or repository describing the required StoreKit, Secure Enclave, Keychain, authenticated transport, or lifecycle operations. The tracer must therefore be planned as a hard acceptance gate, reporting `feasibility_blocked` if any required bridge cannot compile and pass its evidence lane. Apple-native APIs themselves are available and documented; the unknown is the Crosswake shell boundary, not StoreKit or iOS key-storage capability. [CITED: https://developer.apple.com/documentation/storekit/in-app-purchase] [CITED: https://developer.apple.com/documentation/security/protecting-keys-with-the-secure-enclave]

**Primary recommendation:** Create the authority/decision/source-contract artifacts first, then implement a minimal independently-buildable iOS tracer whose explicit capability report decides whether Crosswake runtime coupling may proceed.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| v1.59 authority, claim provenance, watchlist | Repository / documentation | CI | Policy is maintainer-owned; CI detects missing or stale required records. [VERIFIED: codebase grep] |
| Decision-case source and exports | API / Backend | Documentation | Elixir owns canonical policy test data; Markdown and JSON are derived views. [VERIFIED: codebase grep] |
| Source capability inspection | API / Backend | Portal/admin consumers | A typed source registry gives hosts an authoritative inspection boundary; UIs only render its public outcome. [VERIFIED: codebase grep] |
| Stripe gateway controls | API / Backend | — | `Accrue.Processor` remains the existing gateway-control seam. [VERIFIED: codebase grep] |
| Apple purchase, restore, device keys, secure cache | Browser / Client | API / Backend | StoreKit and device-bound key material are native-client responsibilities; backend verifies submitted evidence and issues proofs. [CITED: https://developer.apple.com/documentation/storekit/in-app-purchase] |
| Offline proof replacement and reconciliation request | Browser / Client | API / Backend | Client performs local verification/storage and submits authenticated refresh requests; server remains entitlement authority. [CITED: https://www.ietf.org/rfc/rfc8725.pdf] |

## Standard Stack

### Core

| Library / platform | Version | Purpose | Why standard |
|--------------------|---------|---------|--------------|
| Elixir + ExUnit | Existing `~> 1.19` / built in | Canonical data-only cases, renderer, exhaustive and property proof | Existing project test and contract stack. [VERIFIED: codebase grep] |
| `stream_data` | Existing `~> 1.3` | Permutation, duplicate, ordering, and transaction-boundary properties | Already installed for property tests. [VERIFIED: codebase grep] |
| Apple StoreKit 2 | Xcode SDK | Purchase with `appAccountToken`, transaction updates/current entitlement, restore | Apple’s native IAP boundary; StoreKit exposes purchase, `updates`, and `currentEntitlements`. [CITED: https://developer.apple.com/documentation/storekit/in-app-purchase] |
| Apple Security/CryptoKit | Xcode SDK | Secure Enclave P-256 signing key and Keychain state | Secure Enclave supports P-256 signing/key agreement; enclave keys are non-importable. [CITED: https://developer.apple.com/documentation/cryptokit/secureenclave/p256] [CITED: https://developer.apple.com/documentation/security/ksecattrtokenidsecureenclave] |
| RFC 7515/7519/8725-compatible verifier | Existing v1.59 protocol boundary | Offline JWS fixture and verification rules | Fixed algorithm plus issuer/audience/claim validation is required by JWT BCP. [CITED: https://www.ietf.org/rfc/rfc8725.pdf] |

### Supporting

| Library / platform | Version | Purpose | When to use |
|--------------------|---------|---------|-------------|
| Xcode + Swift | Installed Xcode 26.6 / Swift 6.3.3 | Compile/unit-test minimal tracer target | Required for the local native proof lane. [VERIFIED: local environment probe] |
| StoreKit configuration / simulator | Xcode-provided | Fast advisory StoreKit and Keychain exercises | Use for developer feedback, never as Secure Enclave or Crosswake transport proof. [ASSUMED] |
| Physical iOS device | Host-owned | Secure Enclave, migration exclusion, lifecycle and shell-transport proof | Required by locked decision D-11. |

### Alternatives Considered

| Instead of | Could use | Tradeoff |
|------------|-----------|----------|
| Typed source registry | Extend `Accrue.Processor.Capabilities` | Rejected: it merges gateway control and entitlement-source evidence, violating D-14. |
| Data-only case contract | Runtime reducer as documentation source | Rejected: makes docs/vectors dependent on production types and risks a second non-deterministic interpretation. |
| Native tracer with explicit report | Assumed Crosswake APIs | Rejected: no authoritative public bridge contract was found. [ASSUMED] |

**Installation:** No new Hex, npm, or Swift package should be admitted in Phase 215. The tracer must compile against the user-specified pinned Crosswake shell/core only after its source and version are supplied; do not infer a package identity. [ASSUMED]

## Package Legitimacy Audit

No external package installation is recommended by this phase. Existing `stream_data` and Apple SDK facilities are sufficient for contract/tracer work. Crosswake has no identified authoritative package/repository in this research, so it is intentionally excluded from any installation recommendation. [VERIFIED: codebase grep] [ASSUMED]

**Packages removed due to [SLOP] verdict:** none.

**Packages flagged as suspicious [SUS]:** none; Crosswake is unresolved rather than approved.

## Architecture Patterns

### System Architecture Diagram

```text
Maintainer sources + provider sources
              |
              v
  v1.59-AUTHORITY + amendment ledger + watchlist
              |
              v
  versioned decision-case source (Elixir data only)
        |                    |                   |
        v                    v                   v
 generated Markdown    JSON fixture corpus   ExUnit/property consumers
        |                    |                   |
        +--------------------+-------------------+
                             |
                             v
        later projector / docs / support reason vocabulary

Native iOS APIs --> narrow host-owned tracer adapter --> Crosswake shell/core
       |                    |                              |
 StoreKit, keys, cache   client capability report       compile/runtime proof
       |                    |                              |
       +-------------------- authenticated transport -------+

Canonical DecisionCases --> signed vectors --> independent Elixir/Swift contract-test gate
```

### Recommended Project Structure

```text
.planning/research/
├── v1.59-AUTHORITY.md                 # entry point, precedence, review state
├── v1.59-DECISION-TABLE.md            # generated maintainer view
└── v1.59-*.md                         # preserved sources/watchlist/specialist research
accrue/
├── lib/accrue/entitlements/           # case data, renderer, Source registry/value objects
├── priv/entitlements/                 # language-neutral JSON case/vector corpus
└── test/accrue/entitlements/          # case, property, source-contract and doc-drift tests
examples/crosswake_tracer/             # minimal pinned iOS reference target and evidence report
```

### Pattern 1: Canonical data with derived views

**What:** Define versioned cases in one Elixir module/struct family; export JSON and render Markdown from that list in a deterministic Mix task.

**When to use:** Every named v1.59 normalization, eligibility, repair, and continuity case.

```elixir
# Contract data only: no Repo, no reducer invocation, no public runtime API.
%DecisionCase{
  id: "v1.59.survivor.apple_after_stripe_revoke",
  version: 1,
  evidence: %{rail: :stripe, environment: :live, disposition: :revoked},
  prior: %{survivor_rail: :apple, effective: [:pro]},
  expected: %{revision_delta: :unchanged, lease: :allow, reason: :survivor_grant}
}
```

**Source:** Existing deterministic capability-map plus shell drift verifier pattern. [VERIFIED: codebase grep]

### Pattern 2: Closed source capabilities and typed outcomes

**What:** Let `Accrue.Entitlements.Source` enumerate closed source capabilities and return a typed outcome/value object; keep registry configuration separate from `Accrue.Processor`.

**When to use:** Host inspection and all source-specific operations (observation, control, restore, reconciliation, management, offline).

```elixir
@type state :: :supported | :externally_managed | :host_owned | :deferred |
                :unavailable | :feasibility_blocked

@type outcome :: %Outcome{state: state(), source: atom(), capability: atom(),
                           guidance_key: String.t() | nil, next_action: atom()}
```

**Source:** Locked D-14 through D-17; existing `Accrue.Processor.Capabilities` is the implementation analogue, not the boundary to extend. [VERIFIED: codebase grep]

### Pattern 3: Tracer as a capability-by-capability contract test

**What:** Produce a machine-readable report with one row per required bridge, evidence location, environment, and status—not a single “works” boolean.

**When to use:** Each native/Crosswake bridge named in RAIL-05.

```json
{"contract_version":1,"capability":"secure_enclave_nonce_proof","status":"feasibility_blocked","evidence":"missing_crosswake_bridge"}
```

**Source:** Apple supports the native primitives, but no Crosswake bridge was established by authoritative sources; explicit blocking preserves correctness. [CITED: https://developer.apple.com/documentation/security/ksecattrtokenidsecureenclave] [ASSUMED]

### Anti-Patterns to Avoid

- **Second reducer in renderer/exporter:** render the data; do not reimplement eligibility or projection. [VERIFIED: codebase grep]
- **Boolean capability flags:** lose the critical distinction between externally managed, unavailable, deferred, and blocked. [VERIFIED: codebase grep]
- **Processor leakage:** never dispatch an Apple capability result through Stripe cancellation, dunning, retry, swap, proration, invoice, or payment-method code. [VERIFIED: codebase grep]
- **Simulator-only proof:** it cannot close the locked physical-device evidence requirements. [ASSUMED]
- **Reachability-as-authority:** a scene or network event may request reconciliation but cannot replace cached proof; only a verified newer allow/deny response can. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't build | Use instead | Why |
|---------|-------------|-------------|-----|
| Apple purchase/restore state | Custom receipt/queue lifecycle | StoreKit 2 `updates`, `currentEntitlements`, user-initiated `AppStore.sync()` | StoreKit supplies the system transaction and restore model. [CITED: https://developer.apple.com/documentation/storekit/transaction/currententitlements] [CITED: https://developer.apple.com/documentation/storekit/appstore/sync()] |
| Device private key | Exportable software P-256 key | Secure Enclave P-256 private key plus public-key registration | The private key remains non-importable and device-bound. [CITED: https://developer.apple.com/documentation/security/ksecattrtokenidsecureenclave] |
| Backup-portable secure state | Plain files/UserDefaults | Keychain item with `ThisDeviceOnly` accessibility | ThisDeviceOnly prevents migration to a different device restore. [CITED: https://developer.apple.com/documentation/security/restricting-keychain-item-accessibility] |
| Offline token acceptance | Permissive JWT decode | Strict JWS verifier with fixed alg, issuer, audience, key, type, time, device, and revision checks | RFC 8725 requires algorithm verification and claim validation. [CITED: https://www.ietf.org/rfc/rfc8725.pdf] |
| Capability documentation | Independent prose matrix | Runtime registry + generated/mirrored matrix plus literal drift test | Existing project shell verifier demonstrates this drift-prevention pattern. [VERIFIED: codebase grep] |

**Key insight:** The phase’s value is in making policy and native boundaries falsifiable; custom “helpful” abstractions would erase the evidence paths needed to reject unsafe coupling. [ASSUMED]

## Common Pitfalls

### Pitfall 1: Historical policy silently overrides current policy

**What goes wrong:** A generic research file reintroduces a 72-hour offline cutoff.

**How to avoid:** Assert precedence, an explicit supersession claim, and generated table/vector text with “no independent 72-hour cutoff.” [VERIFIED: codebase grep]

### Pitfall 2: Apple revocation destroys a surviving Stripe grant (or inverse)

**What goes wrong:** The implementation treats rail evidence as one mutable subscription.

**How to avoid:** Include source-qualified lineage and a survivor-grant case; later projection proves the union snapshot changes only when effective output changes. [VERIFIED: codebase grep]

### Pitfall 3: StoreKit restore is called routinely

**What goes wrong:** The app triggers user-authentication prompts during normal refresh.

**How to avoid:** Read `currentEntitlements` normally; expose `AppStore.sync()` only as explicit Restore Purchases action. [CITED: https://developer.apple.com/documentation/storekit/appstore/sync()]

### Pitfall 4: `appAccountToken` is treated as unverified identity

**What goes wrong:** A client claim or email is used to bind Apple ownership.

**How to avoid:** Bind only after verified transaction evidence and UUID account-token match; quarantine mismatch/unlinked material. Apple documents the token as a UUID associated with transactions. [CITED: https://developer.apple.com/documentation/appstoreserverapi/set-app-account-token]

### Pitfall 5: The Crosswake unknown gets hidden behind a green simulator

**What goes wrong:** Later phases assume device storage, lifecycle, and transport are viable without a Crosswake proof.

**How to avoid:** Each Crosswake/client/device feasibility row must have its required compile/unit and physical-device evidence, otherwise emit `feasibility_blocked`. Run canonical vector/JWS parity as a separate mandatory merge gate; its absence or failure is a test failure, never a feasibility-report reason. [ASSUMED]

## Code Examples

### Deterministic renderer/exporter boundary

```elixir
def render! do
  DecisionCases.all()
  |> Enum.sort_by(& &1.id)
  |> DecisionCases.Markdown.render()
end

def export_json! do
  DecisionCases.all()
  |> Enum.sort_by(& &1.id)
  |> JSON.encode_to_iodata!()
end
```

The planned test should assert semantic snapshots and stable ordering; it must not exercise a production reducer from the renderer. [VERIFIED: codebase grep]

### StoreKit recovery boundary

```swift
for await result in Transaction.currentEntitlements {
  guard case .verified(let transaction) = result else { continue }
  await client.submitVerifiedTransaction(transaction)
}

// User action only:
try await AppStore.sync()
```

Source: Apple identifies `currentEntitlements` as the latest entitlement sequence and says `sync()` should follow explicit user action. [CITED: https://developer.apple.com/documentation/storekit/transaction/currententitlements] [CITED: https://developer.apple.com/documentation/storekit/appstore/sync()]

## State of the Art

| Old approach | Current approach | Impact |
|--------------|------------------|--------|
| Generic historical v1.59-like research | Versioned authority bundle with explicit precedence and supersession | Prevents outdated offline policy from being revived. [VERIFIED: codebase grep] |
| Processor-only support matrix | Separate source-capability contract | Keeps gateway lifecycle control distinct from entitlement evidence. [VERIFIED: codebase grep] |
| Assumed mobile boundary | Checked-in tracer with block state | Makes dependency uncertainty visible before runtime coupling. [ASSUMED] |

**Deprecated/outdated:** Any independent 72-hour offline cutoff is superseded by the locked v1.59 30-day revalidation/stale-study policy. [VERIFIED: codebase grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Simulator-only tests cannot satisfy every device/security acceptance item. | Standard Stack / Pitfalls | A plan could incorrectly accept incomplete device proof. |
| A2 | No authoritative public Crosswake bridge API/repository is available to plan against. | Summary / Alternatives | The tracer layout may need revision when the pinned shell source is supplied. |
| A3 | Crosswake can be represented by a minimal independently-built iOS target once its pinned source is supplied. | Recommended Structure | A different integration topology may be required. |

## Open Questions (RESOLVED)

1. **What exact Crosswake shell/core repository, version, and build invocation is authoritative?**
   - **Resolved 2026-07-31:** The checked-in Swift tracer and local environment probe found no authoritative repository, pinned version, or documented build/bridge invocation. `examples/crosswake_tracer/capability-report.json` records that evidence-unavailable result rather than inferring or installing a package. [VERIFIED: local environment probe] [ASSUMED]
   - **Consequence:** Crosswake-dependent client rows and the overall client/device feasibility report remain `feasibility_blocked`, so later mobile runtime coupling cannot begin. Plan 215-05's deterministic Elixir/Swift server/vector/JWS suites remain independently mandatory and merge-blocking; their absence or failure is not a feasibility-blocked report reason.
2. **Where should the physical-device attestation evidence live and how is it approved?**
   - **Resolved 2026-07-31:** The checked-in redacted template is `examples/crosswake_tracer/physical-device-evidence.md`, with reproducible commands and the machine-readable disposition in `examples/crosswake_tracer/capability-report.json`. Approval requires a dated reviewer entry covering every D-11 physical-device lane; device identifiers, raw proof material, secrets, and PII are excluded. [VERIFIED: planning contract]
   - **Consequence:** Until that approved evidence exists, the affected Crosswake/client/device rows and overall runtime-coupling result remain `feasibility_blocked`; simulator evidence remains advisory and cannot close the physical-device lane.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir / Mix | contract, renderer, ExUnit | ✓ | Elixir 1.19.5 / OTP 28 | — [VERIFIED: local environment probe] |
| Xcode | Swift tracer build | ✓ | 26.6 | — [VERIFIED: local environment probe] |
| Swift | Swift tracer build/tests | ✓ | 6.3.3 | — [VERIFIED: local environment probe] |
| Crosswake shell/core | Crosswake bridge proof | ✗ / unavailable as of 2026-07-31 | — | Explicit `feasibility_blocked`; continue independently merge-blocked server/vector work. [ASSUMED] |
| Physical iOS device evidence | Secure Enclave and lifecycle proof | ✗ / unavailable as of 2026-07-31 | — | Record only through the resolved redacted evidence/approval contract; no fallback for D-11 client feasibility acceptance. |

**Missing dependencies with no fallback:** pinned Crosswake source and physical-device proof are blocking only for mobile runtime coupling, not the authority/case/source-contract artifacts. [VERIFIED: codebase grep]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with `stream_data` property tests. [VERIFIED: codebase grep] |
| Config file | `accrue/test/test_helper.exs`. [VERIFIED: codebase grep] |
| Quick run command | `cd accrue && mix test test/accrue/entitlements` |
| Full suite command | `cd accrue && mix test --warnings-as-errors` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RSCH-01 | Authority index/manifest, precedence, claim ledger and no-72h supersession stay complete | ExUnit + shell drift | `cd accrue && mix test test/accrue/docs` | ❌ Wave 0 |
| RSCH-02 | Each named case renders deterministically and JSON vectors agree; ordering/duplicate/survivor properties hold | unit + property | `cd accrue && mix test test/accrue/entitlements/decision_cases_test.exs` | ❌ Wave 0 |
| RSCH-03 | Watchlist categories, owner and response are present | shell/doc drift | `bash scripts/ci/verify_v159_authority.sh` | ❌ Wave 0 |
| RAIL-04 | Closed source states, outcomes, conformance and no processor leakage | unit + negative contract | `cd accrue && mix test test/accrue/entitlements/source_test.exs` | ❌ Wave 0 |
| RAIL-05 | Crosswake/client/device report proves or blocks runtime coupling; independently, golden JWS/JSON vectors and Elixir/Swift contract tests must pass | unit + Swift | `cd examples/crosswake_tracer && swift test` plus the Plan-215-05 ExUnit suite | ❌ Wave 0; feasibility evidence unavailable, contract tests still mandatory |

### Sampling Rate

- **Per task commit:** targeted ExUnit/doc gate or tracer `swift test` as applicable.
- **Per wave merge:** `cd accrue && mix test --warnings-as-errors` plus authority/source shell gates.
- **Phase gate:** full suite green and a capability report that marks every RAIL-05 bridge `proven` or marks the overall result `feasibility_blocked`.

### Wave 0 Gaps

- [ ] Decision-case structs/data, deterministic renderer/exporter, JSON schema/fixtures, and ExUnit/property tests.
- [ ] Authority-manifest/ledger/watchlist verifier and source-matrix code-to-doc drift verifier.
- [ ] `Accrue.Entitlements.Source` registry/outcome/conformance test scaffold plus gateway-leakage negative tests.
- [ ] Minimal Swift target and golden-vector harness; pinned Crosswake input and physical-device runbook remain explicit blockers.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Authenticated account/device transport and nonce proof; client evidence does not grant itself. [VERIFIED: codebase grep] |
| V3 Session Management | yes | Account/device binding and authenticated reconciliation only. [VERIFIED: codebase grep] |
| V4 Access Control | yes | Source-qualified grants, fail-closed quarantine, and typed externally-managed outcomes. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Verify provider/JWS signature, fixed claims, rail/environment and case schema before use. [CITED: https://www.ietf.org/rfc/rfc8725.pdf] |
| V6 Cryptography | yes | Secure Enclave P-256, ES256 fixed-alg JWS verification, key/thumbprint binding, deny precedence. [CITED: https://developer.apple.com/documentation/security/ksecattrtokenidsecureenclave] [CITED: https://www.ietf.org/rfc/rfc8725.pdf] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Algorithm/key confusion | Spoofing | Pin allowed algorithm/key set and validate issuer/audience/type before accepting JWS. [CITED: https://www.ietf.org/rfc/rfc8725.pdf] |
| Copied or wrong-device proof | Spoofing | Bind proof to Secure Enclave-derived public-key thumbprint and require nonce proof on registration/reconnect. [VERIFIED: codebase grep] |
| Older allow proof wins a race | Tampering | Monotonic `iat`/revision/freshness high-water and atomic allow-or-deny replacement. [VERIFIED: codebase grep] |
| Apple evidence linked to wrong account | Elevation of privilege | Verified UUID `appAccountToken` only; quarantine mismatches; prohibit email matching. [CITED: https://developer.apple.com/documentation/appstoreserverapi/set-app-account-token] |
| Apple lifecycle action leaks to Stripe | Tampering | Separate source registry; negative dispatch tests. [VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)

- [Apple StoreKit In-App Purchase](https://developer.apple.com/documentation/storekit/in-app-purchase) — purchase, transaction updates, entitlement reads.
- [Apple currentEntitlements](https://developer.apple.com/documentation/storekit/transaction/currententitlements) and [AppStore.sync](https://developer.apple.com/documentation/storekit/appstore/sync()) — restore/current-state semantics.
- [Apple Secure Enclave key support](https://developer.apple.com/documentation/security/ksecattrtokenidsecureenclave) and [Keychain accessibility](https://developer.apple.com/documentation/security/restricting-keychain-item-accessibility) — device-bound P-256 and `ThisDeviceOnly` behavior.
- [RFC 8725](https://www.ietf.org/rfc/rfc8725.pdf) — strict JWT/JWS validation requirements.
- Repository authority: `.planning/research/v1.59-*`, `215-CONTEXT.md`, `REQUIREMENTS.md`, capability map, and existing verifier scripts. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)

- [Apple Set App Account Token](https://developer.apple.com/documentation/appstoreserverapi/set-app-account-token) — UUID transaction association and update path.

### Tertiary (LOW confidence)

- Crosswake public-surface absence — search result only; retained as an explicit feasibility question, not a claim that a private/internal bridge cannot exist. [ASSUMED]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH for existing Elixir/Xcode/Apple primitives; LOW-MEDIUM for Crosswake coupling because no authoritative bridge contract was found.
- Architecture: HIGH for repository patterns and locked boundaries.
- Pitfalls: HIGH for policy/ordering/source separation; MEDIUM for device-specific tracer behavior until physical proof.

**Research date:** 2026-08-01

**Valid until:** Crosswake and Apple feasibility findings: 7 days or next pinned SDK/source change; repository contract findings: 30 days.
