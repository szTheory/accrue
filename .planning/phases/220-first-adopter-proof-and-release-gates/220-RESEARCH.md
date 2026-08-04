# Phase 220: First-adopter proof and release gates - Research

**Researched:** 2026-08-04  
**Domain:** Deterministic multi-rail entitlement conformance, bounded operations diagnostics, and release-contract drift gates  
**Confidence:** HIGH for repository integration; MEDIUM for the public-process wording that remains hand-authored

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Reference-host proof and deterministic scenarios
- **D-01:** Phase 220 owns one versioned, synthetic, data-only reference-host scenario corpus. Host integration tests, Crosswake Swift-vector tests, generated proof-matrix material, and CI consume the same scenario IDs and expected results; production contexts remain the sole domain-decision authority, so the corpus never becomes a second reducer. — **Reversibility:** costly — scenario IDs, cross-language vectors, documentation, and merge gates will all depend on this contract.
- **D-02:** Every scenario declares its version, ordered evidence/actions, frozen clock, expected account snapshot/revision, purchase eligibility, offline action policy, redacted diagnostic fields, required artifacts, and exactly one evidence lane: `deterministic_conformance`, `runtime_capability`, or `advisory_parity`. Only synthetic, credential-free `deterministic_conformance` rows are merge-blocking.
- **D-03:** Apple-to-web and Stripe-to-iOS scenarios prove deterministic account-projection convergence now, but public material must not claim mobile/Crosswake runtime feasibility until the tracer's required bridge and physical-device evidence exists. Fake, browser, simulator, or vector output cannot promote a blocked runtime-capability claim.
- **D-04:** Browser/Playwright coverage is a complementary rendered-host proof for accessible copy and flows, not the semantic oracle for StoreKit, cryptographic proof, offline cache crash/rollback, ordering, or key rotation. Use focused ExUnit/ConnTest/Ecto transactional consumers for host boundaries and pure Swift consumers for language-neutral fixtures.

#### Operator diagnosis and safe repair
- **D-05:** Publish one internal, read-only, privacy-bounded entitlement diagnostic projection consumed by the reference host/admin, CLI/runbooks, and deterministic tests. It answers the operator's job-oriented questions: current canonical snapshot/revision; rail/environment and normalized provenance; provider/reconciliation freshness; eligibility; device/proof horizon; quarantine/retry state; and next safe action.
- **D-06:** The projection uses closed state, reason, next-action, timestamp/age, and safe-correlation fields. It never returns Ecto schemas, raw transaction/notification evidence, account tokens, proof bytes, PII, encrypted-evidence locators, provider payloads, Oban arguments/errors, exception text, or arbitrary metadata. It extends the entitlement diagnostic seam with canonical multi-rail state rather than folding Apple/offline facts into the existing Stripe-advisory branch.
- **D-07:** Each repair is a distinct host-authorized context action with a bounded target, database-lock/idempotency correctness, actor-and-reason audit, confirmation or dry-run where meaningful, and a post-action convergence assertion. A repair may enqueue/coalesce work but never routinely reconstructs an account or automatically transfers, merges, refunds, cancels, migrates, or prorates one.
- **D-08:** Deterministic repair drills prove missed-notification recovery, cursor recovery, provider outage/rate-limit behavior, ownership-conflict containment, duplicate-charge escalation without automatic finance mutation, stale/revoked-device replacement, signing-key compromise/rotation, and reconciliation-backlog drain. Durable `needs_repair`, bounded retry/backoff, and database authority remain visible; Oban uniqueness is coalescing only, never the correctness lock.

#### Public release contract and developer experience
- **D-09:** Use a versioned v1.59 public-contract fixture to generate the capability/compatibility matrix and power deterministic drift gates. Keep walkthroughs, App Review guidance, privacy/security limits, runbooks, threat/watchlist material, and release notes hand-authored; generated reference owns exact supported/unsupported assertions while prose owns explanation and procedure.
- **D-10:** Public and generated material must state one additive contract: legacy hosts remain compatible; Apple is externally managed; no cross-rail lifecycle migration/refund/proration occurs; stale offline permits downloaded-study/local-progress continuity only; and no diagnostic, fixture, telemetry, or guide exposes raw transaction data, signed proof material, tokens, or PII. Drift gates reject contrary claims.
- **D-11:** Developer UX follows a compact first-adopter path: adopt the reference-host recipe, run one deterministic verification command, use one capability/limits matrix, and follow a scenario/runbook by ID for failure resolution. Evidence lanes remain visible so a maintainer never mistakes advisory/live-store evidence for merge-blocking proof.

#### User-facing and operator experience
- **D-12:** Render diagnosis and repair outcomes in job-and-next-action language, never backend/worker/provider internals. Use text-backed states, literal action labels, semantic headings and tables, keyboard/focus-safe controls, reasoned disabled actions, focus return after mutation, and light/dark/system-safe styling; color only reinforces meaning. Current brandbook voice and copy authority supersede older prompt wording.

### the agent's Discretion
The planner may choose exact fixture schema/module names, generator implementation, scenario granularity, test/helper placement, CLI versus host-admin presentation split, telemetry names, CI job wiring, and documentation organization. These choices must preserve the shared-corpus/non-reducer boundary, closed evidence lanes, Crosswake feasibility truthfulness, host-owned runtime boundaries, privacy redaction, provider honesty, deterministic Fake-first merge proof, and accessible job-focused outcomes.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within Phase 220. Google Play, Family Sharing, offer authoring, automatic ownership transfer, migration/proration, broad fraud/risk controls, and any runtime claim beyond the Crosswake tracer's available evidence remain out of scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| PROOF-01 | Anonymized host proves Apple-to-web and Stripe-to-iOS coherent access. | Shared synthetic scenarios drive real Repo/host projection assertions; vectors may prove semantics but not mobile runtime feasibility. |
| PROOF-02 | CI proves all listed duplicate, offline, recovery, and rotation cases without credentials. | Versioned scenario schema, frozen clocks, ExUnit/Swift consumers, and a strict lane gate. |
| PROOF-03 | Solo operator diagnoses bounded account/rail/proof/repair state. | Extend the existing `Accrue.Entitlements.Admin` read-only seam with a closed multi-rail projection and host rendering. |
| PROOF-04 | Safe automated repair plus operational runbooks cover listed incidents. | Host-authorized context actions, lock/idempotency tests, drill scenarios, and post-action assertions. |
| PROOF-05 | Public material describes exactly one additive contract and limits. | Versioned fixture-generated matrix plus literal/scripted drift checks and hand-authored procedure material. |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Elixir 1.19+, OTP 27+, Phoenix 1.8+, Ecto 3.12+, and PostgreSQL 14+ are the project floor. [VERIFIED: codebase `CLAUDE.md`]
- The host owns Repo, Oban, supervision, authentication/authorization, routes, secrets, and rendering; the library remains a childless, host-integrated library. [VERIFIED: codebase `CLAUDE.md`, `accrue/mix.exs`]
- Signature verification is mandatory; sensitive provider fields must not be logged and payment details must remain provider references. [VERIFIED: codebase `CLAUDE.md`]
- From Phase 218 onward, acceptance is executable and merge-blocking: no manual UAT/tracer completion substitute for machine-verifiable behavior. [VERIFIED: codebase `CLAUDE.md`, `scripts/ci/README.md`]

## Summary

Phase 220 should be planned as a contract-integration phase, not as a new entitlement implementation. The core already contains a versioned decision-case corpus, an offline golden-vector corpus, deterministic Fake-backed host verification, Apple reconciliation/repair behavior, and a bounded diagnostic façade. The missing orchestration is one synthetic scenario contract that names the end-to-end proof cases and lets each appropriate consumer assert its own boundary without duplicating entitlement decisions. [VERIFIED: codebase `accrue/priv/entitlements/v1.59-decision-cases.json`, `accrue/priv/entitlements/v1.59-offline-golden-vectors.json`, `examples/accrue_host/mix.exs`]

Keep the Crosswake runtime claim deliberately blocked. The checked-in report marks every listed capability `feasibility_blocked` pending bridge and/or physical-device evidence, while its Swift package can still consume language-neutral vectors for deterministic client semantics. Treat that split as a public release invariant: a passing Swift vector suite is conformance evidence, not proof that a Crosswake runtime integration exists. [VERIFIED: codebase `examples/crosswake_tracer/capability-report.json`, `examples/crosswake_tracer/README.md`]

**Primary recommendation:** Create one `v1.59` synthetic scenario fixture and validation/export path; have it feed focused Elixir/host/Swift tests, generated capability material, bounded diagnostics/repair drills, and existing CI contract gates—while retaining production contexts as the only reducer and database locks as the only correctness authority. [VERIFIED: codebase `220-CONTEXT.md`, `accrue/lib/accrue/entitlements/admin.ex`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Scenario corpus and fixture validation | API / Backend | CDN / Static | The library owns versioned data validation and exports; docs render a generated subset. [VERIFIED: codebase `v1.59-decision-cases.json`] |
| Canonical account convergence | Database / Storage | API / Backend | Persisted observations/snapshots and transactional locks provide authority; contexts orchestrate them. [VERIFIED: codebase `218-VERIFICATION.md`] |
| Offline proof conformance | Browser / Client | API / Backend | Swift independently verifies public fixtures; server issuance/reconnect remains authoritative. [VERIFIED: codebase `219-VERIFICATION.md`] |
| Operator diagnostic projection | API / Backend | Frontend Server (SSR) | Core returns only closed, bounded data; host/admin authorizes and renders it. [VERIFIED: codebase `admin.ex`, `220-CONTEXT.md`] |
| Safe repair | API / Backend | Database / Storage | Host authorization calls distinct context actions; locks and constraints decide idempotency. [VERIFIED: codebase `220-CONTEXT.md`, `218-VERIFICATION.md`] |
| Release matrix and drift checks | CDN / Static | API / Backend | Fixture-derived assertions are static public contract; scripts reject incoherent docs/code. [VERIFIED: codebase `scripts/ci/verify_entitlement_source_matrix.sh`, `scripts/ci/verify_release_contract.sh`] |

## Standard Stack

### Core

| Library / tool | Version | Purpose | Why Standard |
|---|---:|---|---|
| Existing Elixir/ExUnit + Ecto | Elixir ~> 1.19; Ecto ~> 3.13 | Deterministic fixture consumers, transaction/lock tests, and context boundary tests. | It is already the repository's executable conformance stack. [VERIFIED: codebase `accrue/mix.exs`] |
| Existing Phoenix host | Phoenix ~> 1.8.5 | Anonymized rendered/reference-host proof and authorized operator UI. | `examples/accrue_host` already has bounded and full verification aliases. [VERIFIED: codebase `examples/accrue_host/mix.exs`] |
| Existing Swift package | Swift 6.3.3 available | Pure language-neutral vector consumption and offline-cache behavior tests. | The tracer already separates Swift conformance from feasibility status. [VERIFIED: codebase `Package.swift`, environment audit] |
| Bash + jq CI gates | jq 1.7.1 available | Fixture/doc literal drift checks. | Existing CI scripts use `jq`, fixed literals, and exit-on-failure contract checks. [VERIFIED: codebase `scripts/ci/verify_release_contract.sh`, environment audit] |

### Supporting

| Tool | Purpose | When to Use |
|---|---|---|
| Playwright host suite | Rendered/accessibility and focus-flow confirmation. | Only as complementary proof after semantic ExUnit assertions. [VERIFIED: codebase `220-CONTEXT.md`, `examples/accrue_host/mix.exs`] |
| Existing `Accrue.Entitlements.Admin` | Read-only diagnostic seam. | Extend it with closed multi-rail values; do not expose schemas or raw evidence. [VERIFIED: codebase `admin.ex`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Shared data-only corpus | A new end-to-end reducer in test support | Rejected: it would disagree with production contexts and violate D-01/D-04. [VERIFIED: codebase `220-CONTEXT.md`] |
| Focused semantic tests | Browser-only E2E tests | Rejected: browser assertions cannot decide JWS, ordering, rollback, cache crash, or rotation semantics. [VERIFIED: codebase `220-CONTEXT.md`] |
| Generated exact matrix + hand-authored procedures | Fully generated release guide | Rejected: generators should own supported/unsupported facts, not explanatory walkthroughs or App Review procedure. [VERIFIED: codebase `220-CONTEXT.md`] |

**Installation:** None. This phase should reuse installed repository dependencies and must not introduce an external package. [VERIFIED: codebase `220-CONTEXT.md`]

## Architecture Patterns

### System Architecture Diagram

```text
Versioned synthetic scenario fixture
        │ validates IDs, lane, expected bounded outcome
        ├──────────────► ExUnit / Repo consumers ─► production contexts ─► snapshot + revision assertions
        ├──────────────► Reference-host consumers ─► authorized diagnostic/repair rendering
        ├──────────────► Swift vector consumers ───► offline proof/cache semantic assertions
        └──────────────► Matrix generator ─────────► public capability/limits table
                                                           │
Existing CI scripts ◄──────── literal/schema/drift checks ─┴─► merge-blocking only for deterministic lane

Runtime-capability rows ─► Crosswake capability report ─► `feasibility_blocked` until bridge + device evidence
Advisory-parity rows ────► optional live/provider evidence ─► never semantic merge oracle
```

### Recommended Project Structure

```text
accrue/
├── priv/entitlements/v1.59-reference-scenarios.json # new versioned data-only scenario contract
├── lib/accrue/entitlements/                          # fixture parser/exporter + bounded diagnostic extension
└── test/accrue/entitlements/                         # fixture shape, production-delegating, repair tests
examples/
├── accrue_host/test/                                 # authorized rendered host and integration consumers
└── crosswake_tracer/Tests/                           # pure Swift vector consumer only
scripts/ci/                                           # scenario/matrix/release-drift gates
```

### Pattern 1: Producer-independent scenario data
**What:** Define a strict fixture schema with stable `id`, `contract_version`, lane, ordered evidence/actions, frozen clock, expected snapshot/revision/eligibility/policy/diagnostic, and expected artifacts; each consumer invokes real production behavior rather than implementing a reducer. [VERIFIED: codebase `220-CONTEXT.md`, `decision_case_contract_consumer.ex`]

**When to use:** Every PROOF-01/02 scenario that crosses host, server, or client boundaries.

**Example:**

```elixir
# Source pattern: `accrue/test/support/entitlements/decision_case_contract_consumer.ex`
scenario = ReferenceScenarios.fetch!("apple_to_web_converges")
result = Accrue.Entitlements.Intake.ingest(account, scenario.evidence, now: scenario.now)
assert Snapshot.fetch!(account).revision == scenario.expected.revision
assert result.reason == scenario.expected.reason
```

### Pattern 2: Closed diagnostic projection and explicit repairs
**What:** The diagnostic context returns a closed map/value object using status, reason, next action, age/timestamp, and safe correlation. Repair commands are separate host-authorized actions with explicit target, actor, reason, optional dry-run/confirmation, durable audit, and post-action convergence assertion. [VERIFIED: codebase `220-CONTEXT.md`, `admin.ex`]

**When to use:** PROOF-03/04 operator surfaces and repair-drill tests.

**Anti-Patterns to Avoid**

- **Test reducer:** Never calculate grants, survivor state, or offline policy from fixture fields; call production contexts and compare their bounded outcomes. [VERIFIED: codebase `220-CONTEXT.md`]
- **Raw support explorer:** Never add raw evidence, provider payloads, account tokens, proof bytes, Oban args/errors, exception text, PII, or arbitrary metadata to diagnostic output. [VERIFIED: codebase `220-CONTEXT.md`]
- **Implicit financial repair:** Never hide refund/cancel/migration/proration/account reconstruction behind a “repair” action. [VERIFIED: codebase `220-CONTEXT.md`]
- **Runtime claim inflation:** Never allow simulator, vector, Fake, or browser success to modify the Crosswake feasibility report. [VERIFIED: codebase `capability-report.json`, `220-CONTEXT.md`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Entitlement semantics | Scenario-local evaluator/reducer | Existing projection, intake, offline, and purchase-decision contexts | A second evaluator will drift from the real decision authority. [VERIFIED: codebase `220-CONTEXT.md`] |
| Idempotency/concurrency | Oban-only uniqueness convention | Existing PostgreSQL constraints/locks plus transactional context calls; use Oban only to coalesce | Queue uniqueness does not supply authorization or correctness locking. [VERIFIED: codebase `220-CONTEXT.md`, `218-VERIFICATION.md`] |
| Mobile feasibility determination | An inferred score from tests | Existing capability report and required-evidence inventory | Runtime remains blocked until bridge/device evidence exists. [VERIFIED: codebase `capability-report.json`] |
| Documentation source of truth | Hand-edited capability cells | Versioned public-contract fixture + generator/gate | Exact support/limits need a deterministic drift target. [VERIFIED: codebase `220-CONTEXT.md`] |

**Key insight:** reuse deterministic fixtures as inputs and assertions, never as an authority that computes a user’s entitlement. [VERIFIED: codebase `215-CONTEXT.md`, `220-CONTEXT.md`]

## Common Pitfalls

### Pitfall 1: Treating conformance as runtime feasibility
**What goes wrong:** A green Swift/vector or simulator result is presented as proof that Crosswake can perform authenticated transport, StoreKit, or device lifecycle behavior.

**How to avoid:** Require the existing capability report’s exact bridge and physical-device evidence kinds before changing any `feasibility_blocked` status; gate public wording against that status. [VERIFIED: codebase `capability-report.json`, `README.md`]

### Pitfall 2: Expanding the diagnostic leak surface
**What goes wrong:** “Helpful” UI details expose private Ecto/provider/Oban data or raw proof material.

**How to avoid:** Test the projection’s allowed keys and recursively reject forbidden values/keys; render only closed state/reason/action/age/correlation values. [VERIFIED: codebase `220-CONTEXT.md`, `admin.ex`]

### Pitfall 3: Replacing database correctness with job uniqueness
**What goes wrong:** A repair drill passes once but duplicates, races, or partial writes later corrupt its state.

**How to avoid:** Exercise concurrent calls against a real test Repo, assert one durable outcome/audit trail, then assert post-repair snapshot convergence; jobs may be coalesced but cannot be the lock. [VERIFIED: codebase `218-VERIFICATION.md`, `220-CONTEXT.md`]

### Pitfall 4: Letting the release guide contradict fixture facts
**What goes wrong:** A prose change implies Apple lifecycle control, offline expansion, raw-data visibility, or mobile runtime support.

**How to avoid:** Generate exact matrix claims from a v1.59 fixture and add negative literal checks for forbidden claims; reserve prose for procedure and explanations. [VERIFIED: codebase `220-CONTEXT.md`, `scripts/ci/verify_entitlement_source_matrix.sh`]

## Code Examples

### Bounded diagnostic contract test

```elixir
# Source pattern: `accrue/test/accrue/entitlements/admin_test.exs`
diagnostic = Admin.diagnostic_for_account(account)
assert diagnostic.snapshot.revision == expected_revision
assert diagnostic.repair.next_action == :retry_reconciliation
refute inspect(diagnostic) =~ "raw_jws"
refute Map.has_key?(diagnostic, :oban_args)
```

### Evidence-lane merge policy

```elixir
# Source policy: `220-CONTEXT.md` D-02/D-03
for scenario <- ReferenceScenarios.all() do
  case scenario.evidence_lane do
    :deterministic_conformance -> assert_conformance(scenario)
    :runtime_capability -> assert_capability_report_is_truthful(scenario)
    :advisory_parity -> assert_labeled_advisory(scenario)
  end
end
```

## State of the Art

| Old Approach | Current Approach | Impact |
|---|---|---|
| Stripe-focused diagnostic pair | Extend one internal diagnostic seam with canonical multi-rail facts | Avoids a separate Apple/offline support model. [VERIFIED: codebase `admin.ex`, `220-CONTEXT.md`] |
| Isolated offline corpus rotation test | Shared proof scenario includes deterministic rotation/retirement evidence | Closes Phase 219’s explicitly deferred corpus-level rotation coverage. [VERIFIED: codebase `219-VERIFICATION.md`] |
| Informal docs alignment | Scripted fixture/code/docs release-contract gates | Public limits become maintainable merge contracts. [VERIFIED: codebase `scripts/ci/verify_release_contract.sh`] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| — | None. Research recommendations are constrained to existing repository assets and locked decisions. | — | — |

## Open Questions (RESOLVED)

1. **RESOLVED — Which bounded diagnostic action should be exposed through the reference host versus a CLI-only runbook?**
   - What we know: the host owns authorization/rendering and the planner has discretion over the presentation split. [VERIFIED: codebase `220-CONTEXT.md`]
   - Resolution: Plan 03 keeps every repair behavior in `Accrue.Entitlements.Repair` and exposes host controls only for the bounded actions that have a meaningful confirmation or dry-run. Review/escalation-only and non-interactive operational paths remain available through the typed context contract and scenario-ID-linked CLI/runbook procedures rather than arbitrary GUI controls. Both the context and each selected host wrapper receive focused automated coverage.

2. **RESOLVED — What is the exact public-contract fixture location/schema?**
   - What we know: v1.59 JSON fixture/export precedents already exist. [VERIFIED: codebase `accrue/priv/entitlements/`]
   - Resolution: Plan 04 uses `accrue/priv/entitlements/v1.59-public-contract.json`, a sibling versioned fixture with closed support, limit, and evidence-lane states plus references to unique scenario IDs and required public artifacts. `Accrue.Entitlements.ReferenceScenarios.Markdown` validates that schema and deterministically generates `examples/accrue_host/docs/capability-limits-matrix.md`; `mix accrue.entitlements.reference_scenarios --check` fails on malformed facts, broken cross-references, or generated-output drift.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| Elixir / OTP / Mix | Core, host, and ExUnit conformance | ✓ | OTP 28; project targets Elixir ~> 1.19 | — |
| Swift | Cross-language vector consumer | ✓ | Swift 6.3.3 | — |
| jq | Fixture/release drift scripts | ✓ | 1.7.1 | — |
| PostgreSQL client | Transactional host/core test support | ✓ | 14.17 client | Repo test configuration remains required | 
| Docker | Not required by the selected deterministic proof path | unavailable/not probed | — | No fallback needed |

**Missing dependencies with no fallback:** None identified for the deterministic implementation path. [VERIFIED: environment audit]

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit/Ecto, SwiftPM XCTest, and existing host browser checks. [VERIFIED: codebase `accrue/mix.exs`, `Package.swift`] |
| Config files | `accrue/test/test_helper.exs`; `examples/accrue_host/test/test_helper.exs`; `examples/crosswake_tracer/Package.swift`. [VERIFIED: codebase] |
| Quick run command | `cd accrue && mix test test/accrue/entitlements/<phase220 files> --seed 458442` |
| Full suite command | `cd accrue && mix test.all && cd ../examples/accrue_host && mix verify.full && cd ../crosswake_tracer && swift test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| PROOF-01 | Apple/web and Stripe/iOS scenario convergence | Repo + host integration | targeted `mix test` plus `cd examples/accrue_host && mix verify` | ❌ Wave 0 scenario consumer |
| PROOF-02 | Scenario set, lanes, duplicate/offline/reconnect/rotation cases | unit, integration, Swift vector | `mix test … && cd examples/crosswake_tracer && swift test` | ❌ Wave 0 scenario corpus/tests |
| PROOF-03 | Closed diagnostic projection and safe rendering | unit + LiveView/ConnTest | `mix test …admin…` and host targeted tests | ❌ Wave 0 multi-rail projection tests |
| PROOF-04 | Repair drills lock/idempotency/audit/convergence | integration + property | targeted `mix test` on repair drill scenarios | ❌ Wave 0 drill consumer |
| PROOF-05 | Fixture-to-matrix/public-contract drift | shell + docs tests | `bash scripts/ci/verify_*` | ❌ Wave 0 gate |

### Sampling Rate

- **Per task commit:** Focused ExUnit/Swift/script test for the modified consumer.
- **Per wave merge:** `cd accrue && mix test.all` plus the relevant host/Swift command.
- **Phase gate:** `mix test.all`, `mix verify.full`, `swift test`, and all newly wired release/documentation scripts green in CI. [VERIFIED: codebase `CLAUDE.md`, `examples/accrue_host/mix.exs`]

### Wave 0 Gaps

- [ ] `accrue/priv/entitlements/v1.59-reference-scenarios.json` and a strict parser/checker — stable schema, IDs, closed lanes, redaction contract.
- [ ] Elixir test consumer that invokes production contexts rather than interpreting fixture semantics.
- [ ] Host and Swift scenario consumers keyed by the same IDs.
- [ ] Bounded diagnostic projection allowlist/forbidden-field tests and repair-drill transaction tests.
- [ ] Fixture-to-public-matrix generator/check plus a CI script that rejects contradictory claims.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | Yes | Host authorizes every repair; offline reconnect requires authenticated account/device proof. [VERIFIED: codebase `offline.ex`, `220-CONTEXT.md`] |
| V3 Session Management | Yes | Host-owned sessions; no account token or proof material enters diagnostics. [VERIFIED: codebase `220-CONTEXT.md`] |
| V4 Access Control | Yes | Internal diagnostic seam plus host policy; repair actions have bounded targets and actor audit. [VERIFIED: codebase `220-CONTEXT.md`] |
| V5 Input Validation | Yes | Strict fixture schema/closed evidence lane and production verifier/context input validation. [VERIFIED: codebase `220-CONTEXT.md`, `offline.ex`] |
| V6 Cryptography | Yes | Reuse existing offline proof verification/key-retention implementation; no test-only crypto authority. [VERIFIED: codebase `219-VERIFICATION.md`] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Raw provider/proof data appears in diagnostics or fixtures | Information disclosure | Closed projection allowlist, forbidden-field tests, and public-only fixtures. [VERIFIED: codebase `220-CONTEXT.md`] |
| Race creates duplicate/incorrect repair state | Tampering | Database constraints/locks, idempotent actions, concurrent real-Repo tests, post-action convergence. [VERIFIED: codebase `218-VERIFICATION.md`] |
| Test evidence is relabeled as mobile-runtime proof | Spoofing | Closed lane labels and capability-report gate requiring bridge/device evidence. [VERIFIED: codebase `capability-report.json`] |
| Repair becomes a hidden financial/provider mutation | Elevation of privilege | Separate host-authorized actions and negative tests for transfer/refund/cancel/migrate/prorate paths. [VERIFIED: codebase `220-CONTEXT.md`] |

## Sources

### Primary (HIGH confidence)

- [VERIFIED: codebase] `220-CONTEXT.md` — locked implementation/release/operations decisions.
- [VERIFIED: codebase] `218-VERIFICATION.md` and `219-VERIFICATION.md` — completed Apple/offline behavior, including the deferred corpus-rotation gap.
- [VERIFIED: codebase] `examples/crosswake_tracer/capability-report.json` and `README.md` — present feasibility status and evidence rule.
- [VERIFIED: codebase] `accrue/lib/accrue/entitlements/admin.ex`, scenario/vector fixtures, host `mix.exs`, and CI scripts — reusable seams and gate patterns.

### Secondary (MEDIUM confidence)

- [CITED: local project policy `CLAUDE.md`] — project architecture, privacy, and executable-acceptance constraints.

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all components are installed and already used by the repository. [VERIFIED: codebase]
- Architecture: HIGH — fixed by Phase 220 decisions and predecessor implementation/verification artifacts. [VERIFIED: codebase]
- Pitfalls: HIGH — derived from locked failure boundaries and the tracer/verification reports. [VERIFIED: codebase]

**Research date:** 2026-08-04  
**Valid until:** 2026-09-03, unless the Crosswake capability report or v1.59 authority bundle changes.
