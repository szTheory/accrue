---
phase: 215
slug: research-contracts-and-crosswake-feasibility
status: verified
threats_open: 0
asvs_level: 1
security_block_on: high
created: 2026-08-02
updated: 2026-08-02
---

# Phase 215 — Security

> Per-phase security contract for the research contracts and Crosswake feasibility tracer.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| External research and provider notices → repository authority | Changing or untrusted claims cannot acquire policy authority without the versioned authority manifest and amendment ledger. | Research claims, provenance, policy decisions |
| Canonical DecisionCases → generated fixtures and language consumers | Derived Markdown/JSON and Elixir/Swift readers must preserve exact IDs, versions, bindings, and dispositions. | Contract metadata, signed test vectors |
| Signed server proof → verifier and high-water admission | Compact JWS and claims remain untrusted until cryptographic, identity, type, and monotonic-order validation succeeds. | Signed entitlement proof, account/device binding |
| Verified candidate → authenticated durable cache | Concurrent processes and crash recovery must expose only complete authenticated old-or-new state and preserve denial precedence. | Entitlement payload, revision, disposition, HMAC |
| Host configuration → entitlement source registry | Configured source data must resolve to closed typed outcomes and cannot grant Apple observations Stripe mutation authority. | Rail identity, capabilities, guidance |
| Capability report → feasibility decision | Caller-supplied labels, paths, and evidence cannot establish provenance or unlock runtime coupling. | Capability status, evidence kinds and paths |
| Checked-in report root → evidence artifacts | Only the canonical report may reach proven-producing evaluation; contained evidence must pass schema, path, kind, completion, and redaction checks. | Local test/build/device evidence |
| Host/device secure boundary → cache authentication | Cache keys are supplied externally and must not be embedded, persisted beside the cache, logged, or passed in argv. | HMAC key material |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-215-01 | Spoofing | device registration/reconnect | high | mitigate | `CapabilityReportTests` fails closed to `feasibility_blocked` unless authenticated Crosswake transport and physical-device account/device/key-thumbprint/nonce evidence is present; server/vector results are not reducer inputs. | closed |
| T-215-02 | Tampering | cached allow/deny replacement | high | mitigate | `CapabilityReportTests` requires Crosswake/client compile/unit and dated device atomic-replacement evidence for feasibility; Plan 215-05 separately merge-blocks monotonic denial/JWS/vector failures without translating them into feasibility status. | closed |
| T-215-03 | Information Disclosure | physical-device evidence | medium | mitigate | Commit only redacted device-class and result metadata; assert no device IDs, secrets, raw receipts/JWS, payloads, or PII. | closed |
| T-215-04 | Elevation of Privilege | feasibility report | high | mitigate | Overall proven requires all capability lanes; missing Crosswake or device evidence deterministically yields feasibility_blocked. | closed |
| T-215-SC | Tampering | package admission | high | mitigate | Install no package; authoritative Crosswake source remains an explicit unresolved input rather than an inferred dependency. | closed |
| T-215-05 | Tampering | authority precedence | high | mitigate | `bash scripts/ci/verify_v159_authority.sh` fails closed on altered precedence or missing accepted amendments, with mutation cases in `v159_authority_docs_test.exs`. | closed |
| T-215-06 | Repudiation | amendment ledger | medium | mitigate | Stable claim IDs, dates, sources, disposition, rationale, and downstream owner fields are mandatory. | closed |
| T-215-07 | Information Disclosure | authority/watchlist prose | medium | mitigate | Keep adopter identity, PII, secrets, receipts, and raw provider evidence out of the bundle and fixtures. | closed |
| T-215-08 | Denial of Service | malformed/empty watchlist | low | accept | Gate rejects incomplete data; a temporary failed docs build is tolerable and visible. | closed |
| T-215-09 | Tampering | generated fixtures | high | mitigate | `mix accrue.entitlements.decision_cases --check` and mutation-sensitive tests fail closed on byte, ID, version, or disposition drift. | closed |
| T-215-10 | Elevation of Privilege | case interpretation | high | mitigate | `decision_cases_test.exs` fails if renderer/exporter output diverges from case data or the corpus exposes a reducer/projector/public facade. | closed |
| T-215-11 | Repudiation | support outcomes | medium | mitigate | Stable case and reason IDs plus version fields identify every expected result. | closed |
| T-215-12 | Information Disclosure | case evidence/reasons | medium | mitigate | Schema admits bounded provenance and privacy-safe reason IDs, not raw provider payloads or PII. | closed |
| T-215-13 | Elevation of Privilege | Apple capability dispatch | high | mitigate | `source_test.exs` processor-call traps plus `entitlement_source_matrix_guard_test.exs` fail closed on every injected Apple-to-Stripe mutation family. | closed |
| T-215-14 | Tampering | capability vocabulary/docs | high | mitigate | `verify_entitlement_source_matrix.sh` and mutation tests fail closed on missing, reordered, booleanized, or divergent closed values. | closed |
| T-215-15 | Spoofing | configured source registry | medium | mitigate | Reject null/empty/duplicate/unknown sources and require typed source identity on every outcome/error. | closed |
| T-215-16 | Information Disclosure | guidance/outcomes | medium | mitigate | Return stable bounded guidance/reason fields only; no raw evidence or provider payloads. | closed |
| T-215-17 | Tampering | DecisionCase/vector binding | high | mitigate | `--check` and mutation-sensitive ExUnit fail closed on missing/duplicate IDs or version/disposition divergence. | closed |
| T-215-18 | Spoofing | compact JWS verification | high | mitigate | Both suites cryptographically pin ES256/public key and reject signature, issuer, audience, type, account, device, and thumbprint mismatch. | closed |
| T-215-19 | Elevation of Privilege | allow/deny high-water state | high | mitigate | Both suites fail on rollback/older inputs and prove equal/newer signed denial precedence without allow resurrection. | closed |
| T-215-20 | Tampering | durable replacement | high | mitigate | Before/after fault injection proves verified candidate durability plus atomic rename, with only old-or-new complete state observable. | closed |
| T-215-21 | Information Disclosure | deterministic fixture key/payloads | medium | mitigate | Key is explicitly test-only; automated scope checks reject production references and fixtures contain no PII/provider payloads. | closed |
| T-215-22 | Tampering | D-07 validator | high | mitigate | Closed vocabularies, binding checks, non-negative deltas, and one-field mutation tests reject contract drift. | closed |
| T-215-23 | Elevation of Privilege | contract consumer | high | mitigate | The consumer calls `valid?/1`, rejects mismatched evidence/prior state, and proves older/invalid evidence cannot emit a grant transition. | closed |
| T-215-24 | Repudiation | case/reason outputs | medium | mitigate | Stable case/reason IDs and computed transition assertions preserve an auditable result vocabulary. | closed |
| T-215-25 | Information Disclosure | generated evidence | low | accept | Tests use bounded synthetic account/device states and contain no PII or provider payloads. | closed |
| T-215-26 | Tampering | fixture expectation oracle | high | mitigate | Generator mutation tests and both language suites compare every expected field with observed output. | closed |
| T-215-27 | Spoofing | JWS header/claims | high | mitigate | Wrong account/audience/type/algorithm/signature/key/device vectors execute fixed-alg cryptographic and binding checks. | closed |
| T-215-28 | Elevation of Privilege | disposition/high-water parsing | high | mitigate | Closed disposition and integer claim validation reject unknown/malformed values before replacement. | closed |
| T-215-29 | Denial of Service | malformed compact/claims | medium | mitigate | Both readers return bounded rejection observations without uncaught exceptions. | closed |
| T-215-30 | Information Disclosure | fixture payload/key | medium | mitigate | Deterministic key remains test-only and corpus excludes adopter identity, PII, and raw provider evidence. | closed |
| T-215-31 | Tampering | candidate/rename sequence | high | mitigate | Per-path serialization, unique same-directory candidates, cleanup, and concurrent stress tests prevent cross-replacement. | closed |
| T-215-32 | Elevation of Privilege | allow/deny race | high | mitigate | Monotonic ordering plus same/newer denial precedence is asserted under concurrent handles and reopen. | closed |
| T-215-33 | Denial of Service | abandoned candidates/cache absence | medium | mitigate | Serialized recovery cleanup and old-or-new canonical reads reject missing/torn state. | closed |
| T-215-34 | Repudiation | durability claim | medium | mitigate | Subprocess fault points and ordered sync-event assertions provide repeatable crash/reopen evidence. | closed |
| T-215-35 | Information Disclosure | candidate filenames/data | low | accept | Candidates remain in the protected cache directory, use random names, and are removed after every path; test payloads contain no PII. | closed |
| T-215-36 | Tampering | Markdown semantic projection | high | mitigate | A case with differing lease/continuity values proves `Markdown.render/1` and the checked-in table expose the D-07 fields under distinct headings. | closed |
| T-215-37 | Tampering | offline drift oracle | high | mitigate | Complete schema/key/value comparison plus duplicate/missing/extra-vector mutation tests make every corpus field merge-blocking. | closed |
| T-215-38 | Elevation of Privilege | Elixir vector binding | high | mitigate | The reader rejects unknown case IDs and version/disposition drift before observing or accepting a signed allow. | closed |
| T-215-39 | Repudiation | vector identity | medium | mitigate | Unique vector IDs and stable field-specific diagnostics preserve one auditable result per fixture. | closed |
| T-215-40 | Information Disclosure | generated fixtures | low | accept | Existing test-only, privacy-safe corpus remains unchanged in sensitivity and contains no adopter identity or production keys. | closed |
| T-215-41 | Tampering | Swift vector metadata | high | mitigate | Exact structural key validation, identity-set equality, and field-complete comparison to the generated baseline reject unknown/missing keys, vector drift, and every field mutation before observation. | closed |
| T-215-42 | Elevation of Privilege | misbound allow vector | high | mitigate | Binding validation precedes `observe`, so an unknown or mismatched case cannot reach an accepted cache outcome. | closed |
| T-215-43 | Repudiation | duplicate vector identity | medium | mitigate | Duplicate IDs fail before sorting and bounded errors identify the duplicate. | closed |
| T-215-44 | Denial of Service | malformed schema metadata | medium | mitigate | Typed decoding and bounded contract errors fail cleanly without cache replacement. | closed |
| T-215-45 | Tampering | persisted revision/disposition | high | mitigate | HMAC-authenticated versioned envelope binds payload, revision, disposition, and path context; field/key mutation tests fail closed. | closed |
| T-215-46 | Elevation of Privilege | denial restart | high | mitigate | Fresh-process restoration precedes candidate comparison; denial-restart stale-allow regression proves access cannot resurrect. | closed |
| T-215-47 | Tampering | interprocess replacement race | high | mitigate | Per-cache POSIX lock encloses authenticated reload through durable rename/adoption, with concurrent child-process tests. | closed |
| T-215-48 | Information Disclosure | cache authentication key | high | mitigate | No hardcoded/persisted/logged/argv key; harness uses inherited environment or protected temp key and tests diagnostics for absence. | closed |
| T-215-49 | Denial of Service | malformed/tampered envelope | medium | mitigate | Typed bounded errors preserve canonical bytes and refuse exposure/rewrite until valid authenticated state is available. | closed |
| T-215-50 | Repudiation | restart ordering result | medium | mitigate | Child-process exit/result and exact persisted envelope assertions record the revision/disposition winner without sensitive material. | closed |
| T-215-51 | Tampering | ProofHighWater ordering | high | mitigate | One shared disposition-aware predicate plus focused equal/older/newer regressions prevents public/cache divergence. | closed |
| T-215-52 | Elevation of Privilege | equal-revision replacement | high | mitigate | Allow n → deny n → stale/equal allow tests prove denial wins and access cannot resurrect. | closed |
| T-215-53 | Tampering | restart/reconnect cache admission | high | mitigate | Separate processes restore the authenticated envelope under the existing path lock before comparing candidates. | closed |
| T-215-54 | Spoofing | capability schema | high | mitigate | Public report reduction and checked-in validation both require exact schema 1.0 before `.proven`. | closed |
| T-215-55 | Denial of Service | unsupported report input | low | accept | Unsupported schema returns the existing bounded feasibility_blocked outcome without throwing; no granting behavior occurs. | closed |
| T-215-56 | Repudiation | admission result | medium | mitigate | Tests assert the exact winning revision/disposition and persisted payload across process boundaries. | closed |
| T-215-57 | Tampering | public AtomicOfflineCache raw seam | critical | mitigate | Remove no-key/raw production entry points and prove an obsolete invocation cannot change exact authenticated denial bytes. | closed |
| T-215-58 | Elevation of Privilege | signed denial replacement | high | mitigate | Require key, disposition, and revision on every production write; preserve same-revision denial precedence and stale/equal allow rejection. | closed |
| T-215-59 | Spoofing | all-proven capability report | critical | mitigate | Validate complete rows, terminal reason, resolving contained locations, evidence-kind policy, and completed physical-device record before proven. | closed |
| T-215-60 | Tampering | evidence path resolution | high | mitigate | Reject absolute/path-escaping, missing, directory, empty, placeholder, and wrong-kind evidence locations. | closed |
| T-215-61 | Repudiation | physical-device evidence | high | mitigate | Require dated non-pending lanes, redaction attestation, and reviewer approval before the physical-device kind can support proven status. | closed |
| T-215-62 | Denial of Service | malformed report or obsolete harness invocation | low | accept | Both inputs fail with bounded validation/usage errors before changing entitlement state; no grant behavior occurs. | closed |
| T-215-63 | Spoofing | public CapabilityReport construction/reduction | critical | mitigate | Make caller-populated reports untrusted/fail-closed and prove full synthetic labels plus arbitrary locations cannot yield proven. | closed |
| T-215-64 | Tampering | decoded status and evidence-kind labels | high | mitigate | Reserve proven for `validate(reportURL:)`, which recomputes the decision from exact required kinds and validated artifacts rather than trusting encoded labels. | closed |
| T-215-65 | Elevation of Privilege | feasibility result consumed by later runtime | high | mitigate | Expose one provenance-validating public decision path and keep all data-only paths blocked per D-12. | closed |
| T-215-66 | Repudiation | evidence provenance | medium | mitigate | Retain report-root containment, kind-specific file checks, terminal reason checks, and physical-device completion validation. | closed |
| T-215-67 | Denial of Service | malformed or incomplete draft/report | low | accept | Bounded Swift validation returns feasibility_blocked or `ValidationError.invalid`; no entitlement state or runtime coupling changes. | closed |
| T-215-68 | Spoofing | `validate(reportURL:)` report identity | critical | mitigate | Compare the standardized caller URL with a validator-owned canonical checked-in report URL before reading or decoding it; reject every alternate root. | closed |
| T-215-69 | Tampering | caller-populated temporary report and evidence tree | high | mitigate | Add a complete exploit-shaped regression whose paths, file kinds, and physical-device text satisfy all legacy content checks but whose noncanonical root is rejected. | closed |
| T-215-70 | Elevation of Privilege | `.proven` runtime-coupling decision | high | mitigate | Require canonical report identity and all existing evidence checks before `.proven` can cross into later-phase feasibility assumptions. | closed |
| T-215-71 | Repudiation | checked-in evidence provenance | medium | mitigate | Preserve the single canonical report path plus deterministic focused/full-suite evidence in the plan summary. | closed |
| T-215-72 | Denial of Service | absent canonical source-tree artifact in a redistributed binary | low | accept | This is a checked-in feasibility tracer, not an Accrue runtime dependency; inability to locate the canonical artifact fails closed with `ValidationError.invalid`. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open high/critical threats count toward `threats_open`.*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party).*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-215-01 | T-215-08 | Malformed or empty watchlist data can temporarily fail the documentation gate; failure is explicit, bounded, and non-granting. | Phase 215 plan | 2026-08-02 |
| AR-215-02 | T-215-25 | Generated test evidence uses bounded synthetic account/device states and contains no production PII or provider payloads. | Phase 215 plan | 2026-08-02 |
| AR-215-03 | T-215-35 | Cache candidates use random names inside the protected cache directory and are cleaned after each path; fixtures contain no PII. | Phase 215 plan | 2026-08-02 |
| AR-215-04 | T-215-40 | Generated fixtures remain test-only, privacy-safe, and contain neither adopter identity nor production keys. | Phase 215 plan | 2026-08-02 |
| AR-215-05 | T-215-55 | Unsupported capability-report schemas return a bounded `feasibility_blocked` result without throwing or granting. | Phase 215 plan | 2026-08-02 |
| AR-215-06 | T-215-62 | Malformed reports and obsolete harness invocations stop with bounded validation/usage errors before entitlement state changes. | Phase 215 plan | 2026-08-02 |
| AR-215-07 | T-215-67 | Malformed or incomplete reports fail closed with bounded Swift validation and cannot alter entitlement state or runtime coupling. | Phase 215 plan | 2026-08-02 |
| AR-215-08 | T-215-72 | A redistributed tracer without its canonical source-tree artifact cannot prove feasibility and fails closed; the tracer is not a runtime dependency. | Phase 215 plan | 2026-08-02 |

Accepted risks are low-severity, fail-closed, non-granting conditions. They do not count toward the high-severity enforcement threshold.

---

## Verification Evidence

| Gate | Result | Coverage |
|------|--------|----------|
| `bash scripts/ci/verify_v159_authority.sh` | PASS — `verify_v159_authority: OK` | Authority precedence, amendment ledger, watchlist validation |
| `bash scripts/ci/verify_entitlement_source_matrix.sh` | PASS — `verify_entitlement_source_matrix: OK` | Closed source vocabulary, documentation/runtime drift |
| Phase 215 API coverage pre-check | PASS — no external API integration declared | Scope/admission boundary |
| Decision-case fixture check | PASS — fixtures current | Canonical corpus and generated-view drift |
| Focused Elixir security suite | PASS — 5 properties, 33 tests, 0 failures | Authority, registry, contract validation, signed-vector verification |
| Complete Swift tracer suite | PASS — 23 tests in 3 suites | JWS parity, high-water ordering, authenticated atomic cache, capability provenance |
| Capability-report terminal-state check | PASS — `overall_status == "feasibility_blocked"` | Fail-closed Crosswake/runtime feasibility |

The register was authored at plan time and all high/critical mitigations have current L1 executable evidence. Under the configured ASVS L1 workflow, the clean-register short-circuit applies and deeper auditor dispatch is not required.

---

## Security Audit 2026-08-02

| Metric | Count |
|--------|-------|
| Threats found | 73 |
| Closed | 73 |
| Open | 0 |
| Accepted low risks | 8 |
| Blocking high/critical threats | 0 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-02 | 73 | 73 | 0 | Codex L1 security audit |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-08-02
