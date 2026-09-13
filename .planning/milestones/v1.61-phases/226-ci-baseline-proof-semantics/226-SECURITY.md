---
phase: 226
slug: ci-baseline-proof-semantics
status: verified
threats_open: 0
asvs_level: 1
block_on: high
created: 2026-08-12
---

# Phase 226 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| GitHub Actions APIs and historical workflow sources → collector | Remote run, job, attempt, topology, runner, timestamp, URL, and conclusion data are untrusted until repository-, revision-, schema-, and semantic validation succeeds. | Authenticated read-only CI metadata; no logs or artifact contents |
| Workflow and caller configuration → identity/provenance resolver | Trusted repository and workflow declarations must remain independent of persisted or remotely supplied identities. | Expected repository, workflow bytes, job identities, prerequisites, runner contracts |
| ExUnit/provider execution → formatter and proof classifier | Secret-bearing live execution may produce only bounded aggregate evidence, and cannot promote without the complete proof predicate. | Counts, timestamps, SHA, trigger, policy, outcome; no test names, messages, credentials, or payloads |
| Host and CI runtime → setup diagnostics | Commands, paths, environment values, and failures may contain sensitive or injection-capable text. | Fixed diagnostic codes, owners, commands, bounded evidence locations, exit status |
| NDJSON and manifests → semantic validators/renderers | Persisted or fixture-controlled records are untrusted and may attempt field, URL, Markdown, or control-sequence injection. | Allowlisted normalized records and aggregate manifests |
| Validated records → checked-in evidence and GitHub summaries | Durable evidence must be privacy-safe, deterministic, repository-bound, and no stronger than the verified facts. | Canonical NDJSON, Markdown, setup facts, provider summaries |

---

## Verification Evidence

Fresh verification on 2026-08-12 produced the following evidence:

| Surface | Command | Result |
|---------|---------|--------|
| Baseline schema, privacy, admission, provenance, injection, and negative fixtures | `node scripts/ci/verify_ci_baseline.mjs --fixtures --expected-repository acme/accrue` | PASS |
| Canonical repository-bound evidence, byte-render, and critical path | `node scripts/ci/verify_ci_baseline.mjs --records .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson --rendered .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md --require-critical-path --expected-repository szTheory/accrue` | PASS |
| Provider proof state machine, manifest validation, promotion negatives, and summary escaping | `node scripts/ci/verify_provider_proof.mjs --fixtures` | PASS |
| Fixed setup registry, privacy, ownership, delegation, and failure classification | `bash scripts/ci/verify_ci_setup_diagnostics.sh` | PASS |
| Inherited Phase 225 required-lane boundary | `bash scripts/ci/verify_phase225_required_lane_evidence.sh` | PASS |
| Aggregate-only real ExUnit formatter contract | `cd accrue && mix test test/accrue/live_proof_formatter_test.exs --warnings-as-errors` | PASS — 4 tests, 0 failures |

The formal plan-time register and completed summaries were also reviewed. No summary contained a `## Threat Flags` section. At configured ASVS L1, these implementation-facing contract checks are sufficient for the clean-register short circuit; no deeper L2/L3 auditor trace was required.

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation / Evidence | Status |
|-----------|----------|-----------|----------|-------------|-----------------------|--------|
| T-226-01 | Information Disclosure | collector/schema-v1 | high | mitigate | Strict record allowlist, branch classes, truncated SHA, and forbidden-field fixtures; baseline fixtures pass. | closed |
| T-226-02 | Tampering | API metadata → Markdown/CLI | high | mitigate | Enum/time/URL validation, inert rendering, argv-safe collection, and injection negatives; baseline fixtures pass. | closed |
| T-226-03 | Repudiation | cohort and rerun derivation | medium | mitigate | Immutable IDs/URLs, raw facts, fingerprints, attempts, and deterministic derivation retained and verified. | closed |
| T-226-04 | Denial of Service | pagination and malformed timestamps | low | accept | Bounded 90-day/sample collection and deterministic fail-closed errors; accepted as limited availability risk. | closed |
| T-226-05 | Information Disclosure | frozen NDJSON/Markdown | high | mitigate | Canonical records pass strict unknown/forbidden-field and repository-bound validation. | closed |
| T-226-06 | Tampering | frozen cohort selection | high | mitigate | Fingerprints, exclusions, immutable links, exact counts, and byte-reproducible render are verified. | closed |
| T-226-07 | Repudiation | critical-path claim | medium | mitigate | Claims bind to canonical records, immutable links, and exact reproduction commands; canonical verifier passes. | closed |
| T-226-08 | Spoofing | external evidence links | low | accept | Links are repository-bound and paired with IDs; residual compromise of GitHub-hosted evidence is accepted. | closed |
| T-226-09 | Information Disclosure | live proof formatter/record | high | mitigate | Aggregate-only manifest contract excludes names, messages, environment data, IDs, and payloads; 4 formatter tests pass. | closed |
| T-226-10 | Tampering | proof-state promotion | high | mitigate | Complete fail-closed predicate and exhaustive non-promotion fixtures pass. | closed |
| T-226-11 | Tampering | step-summary rendering | high | mitigate | Escaped local-file summary rendering and workflow-command/Markdown injection fixtures pass. | closed |
| T-226-12 | Repudiation | latest proved/freshness claim | medium | mitigate | Exact SHA/time/cadence/grace retained; stale is derived and proof never transfers between SHAs. | closed |
| T-226-13 | Information Disclosure | setup facts/diagnostics | high | mitigate | Fixed codes and bounded identities exclude URLs, tokens, env values, payloads, app data, and raw paths; setup verifier passes. | closed |
| T-226-14 | Tampering | next-command rendering | high | mitigate | Owner and next command derive only from the fixed registry; unknown codes reject. | closed |
| T-226-15 | Spoofing | host-versus-CI ownership | medium | mitigate | Seven-code single-owner contract retains Linux dependency provisioning in CI. | closed |
| T-226-16 | Repudiation | setup failure evidence | medium | mitigate | Command identity, code, duration/evidence location, and original nonzero status are retained. | closed |
| T-226-17 | Information Disclosure | workflow summary/artifacts | high | mitigate | Secrets remain env-only; only validated allowlisted records reach summaries/artifacts; static contracts pass. | closed |
| T-226-18 | Tampering | workflow proof-state wiring | high | mitigate | Finalization binds preflight, manifest, step/job outcomes and retains selected-run failure; provider fixtures pass. | closed |
| T-226-19 | Elevation of Privilege | workflow permissions/API | high | mitigate | Existing read-only permissions/authentication are preserved; no write token or mutation capability added. | closed |
| T-226-20 | Spoofing | docs owner/proof labels | medium | mitigate | Documentation assertions are checked against stable registries and executable workflow semantics. | closed |
| T-226-21 | Tampering | `summarizeCohorts` qualification | high | mitigate | Full-CI topology/event admission, 20-run thresholds, rerun isolation, and exclusion controls pass. | closed |
| T-226-22 | Tampering | timestamp validators | high | mitigate | Exact UTC grammar and ISO round-trip reject impossible timestamps before arithmetic; fixtures pass. | closed |
| T-226-23 | Information Disclosure | baseline record path | high | mitigate | Schema privacy allowlist and forbidden-field regressions pass without expanding persisted fields. | closed |
| T-226-24 | Spoofing | provider proof semantics | medium | mitigate | Ordinary CI remains `non_run`; exhaustive provider promotion-negative gate passes. | closed |
| T-226-25 | Information Disclosure | live recollection/frozen artifacts | high | mitigate | Read-only collection, strict privacy/schema validation, and canonical verification pass without credential output. | closed |
| T-226-26 | Tampering | staged-path percentile derivation | high | mitigate | Cohort, ordering, fingerprint, rerun, sample, and shard-arithmetic controls pass through production derivation. | closed |
| T-226-27 | Repudiation | critical-path conclusion | high | mitigate | Immutable links, exact fingerprint/count, percentiles, reproducible Markdown, and reproduction command are retained. | closed |
| T-226-28 | Spoofing | provider/setup boundaries | high | mitigate | Provider, real formatter, seven-code setup, and required-lane contracts all pass. | closed |
| T-226-29 | Denial of Service | GitHub API/auth/history | medium | mitigate | Collection is bounded and preserves prior canonical artifacts on auth/API/history failure. | closed |
| T-226-30 | Spoofing | `normalizeRun()` provider default | high | mitigate | Absent provider evidence defaults to `non_run`; push/PR no-promotion controls pass. | closed |
| T-226-31 | Tampering | dependency topology | high | mitigate | Unresolved or temporally invalid prerequisites reject before DAG arithmetic; live-path fixtures pass. | closed |
| T-226-32 | Spoofing | host UAT fallback classification | high | mitigate | Wrapper preserves inner facts and emits only the fixed aggregate fallback when none exists. | closed |
| T-226-33 | Repudiation | wrapper failure evidence | medium | mitigate | Delegated status and stable code/owner/command/evidence plus `FAILED_GATE` are fixture-verified. | closed |
| T-226-34 | Information Disclosure | setup fact inspection | low | accept | Inspection is limited to file state/bounded records and never prints payloads or env values; residual local metadata risk accepted. | closed |
| T-226-35 | Tampering | workflow prerequisite identity | high | mitigate | One normalized display namespace and positive/negative production-path fixtures reject invalid prerequisites. | closed |
| T-226-36 | Spoofing | provider freshness anchor | high | mitigate | Freshness binds only after all proof predicates pass using current SHA and validated completion. | closed |
| T-226-37 | Tampering | provider workflow finalizer link | high | mitigate | Static contracts preserve current SHA, runner-temp manifest, always-run order, read-only permissions, and stable identities. | closed |
| T-226-38 | Information Disclosure | provider record/summary | medium | mitigate | Allowlisted record/renderer and full provider fixtures prevent secrets, payloads, or raw provider output. | closed |
| T-226-39 | Repudiation | validation evidence | medium | accept | Repository-local deterministic fixtures and validation ledger provide proportionate ASVS L1 traceability. | closed |
| T-226-40 | Tampering | workflow display-name contract | high | mitigate | Literal workflow identity, bounded block assertion, production tracer, and unresolved/temporal controls pass. | closed |
| T-226-41 | Spoofing | injected live fixture | high | mitigate | Fixtures must match the real workflow display name; synthetic aliases cannot satisfy admission. | closed |
| T-226-42 | Information Disclosure | full regression surface | high | mitigate | Schema/privacy, provider, formatter, setup, and inherited evidence contracts all pass. | closed |
| T-226-43 | Repudiation | validation ledger | low | accept | Exact local commands, task rows, and atomic commits are adequate for the reversible identity correction. | closed |
| T-226-44 | Tampering | exact-attempt jobs endpoint | high | mitigate | Jobs bind to the exact run attempt; positive attempt validation and older-attempt negatives pass. | closed |
| T-226-45 | Spoofing | runner resolver | high | mitigate | Runner class/image derives only from checked workflow contracts; raw runner claims are ignored and ambiguity rejects. | closed |
| T-226-46 | Information Disclosure | runner/job normalization | high | mitigate | Only declared class/image fingerprint facts persist; raw names, labels, actors, logs, payloads, and artifacts reject. | closed |
| T-226-47 | Tampering | canonical pair replacement | high | mitigate | Temporary collection, full validation, dual-render equality, atomic paired replacement, and installed revalidation are enforced. | closed |
| T-226-48 | Elevation of Privilege | read-only GitHub collection | medium | mitigate | Existing read-only Actions access is reused; no mutation, token serialization, package install, or external write. | closed |
| T-226-49 | Repudiation | validation ledger | low | accept | Exact commands, immutable sanitized URLs, task rows, and atomic commits are adequate ASVS L1 evidence. | closed |
| T-226-50 | Spoofing | historical compatibility admission | high | mitigate | Exceptions bind to immutable workflow revision/content digest and exact tuples; unknown revisions/topologies reject. | closed |
| T-226-51 | Spoofing | shared workflow job resolver | high | mitigate | Exact identities or finite workflow-derived matrix expansions replace arbitrary prefix admission. | closed |
| T-226-52 | Tampering | cohort/DAG facts | high | mitigate | Missing or ambiguous revision/identity resolution fails before normalization; attempt and frozen-record validators pass. | closed |
| T-226-53 | Information Disclosure | readiness diagnostic | high | mitigate | Fixed registry facts and adversarial PG-environment tests prevent sensitive values reaching stderr or NDJSON. | closed |
| T-226-54 | Repudiation | host failure attribution | medium | mitigate | One stable fact, owner, command, evidence location, status, and gate marker are emitted before delegation. | closed |
| T-226-55 | Denial of Service | workflow revision lookup | low | accept | Bounded 90-day lookup fails precisely without weakening admission or writing partial canonical evidence. | closed |
| T-226-56 | Tampering | canonical NDJSON replacement | high | mitigate | Temporary collection must pass provenance, schema/privacy, critical-path, and exact sample gates before atomic replacement. | closed |
| T-226-57 | Spoofing | frozen cohort membership | high | mitigate | Every admitted job binds to immutable revision and exact/narrow identity; unknown topology rejects. | closed |
| T-226-58 | Information Disclosure | frozen records/report | high | mitigate | Strict allowlists and privacy fixtures permit only sanctioned fields and immutable links. | closed |
| T-226-59 | Tampering | Markdown critical-path claim | high | mitigate | Dual render, byte comparison, same-record validation, and measured conclusion are present and pass. | closed |
| T-226-60 | Repudiation | validation ledger | medium | mitigate | Exact commands, requirement/threat mappings, row count, and immutable links are recorded. | closed |
| T-226-61 | Elevation of Privilege | read-only GitHub access | low | accept | Existing read-only access is sufficient; no dispatch, rerun, cancellation, secret, permission, or branch mutation occurs. | closed |
| T-226-62 | Tampering | formatter outcome classification | high | mitigate | Excluded-event branch precedes selected outcome handling; direct and real Mix tests prove exact counters. | closed |
| T-226-63 | Spoofing | provider manifest promotion | high | mitigate | Real tagged-only manifest passes production finalizer; all negative promotion fixtures remain green. | closed |
| T-226-64 | Information Disclosure | formatter/manifest | high | mitigate | Aggregate counts/timestamps only; no traffic, credentials, details, or transient evidence retained. | closed |
| T-226-65 | Repudiation | live-provider policy | medium | mitigate | Guide language binds to literal triggers, required policy, proof predicates, always-run summary, and artifact. | closed |
| T-226-66 | Tampering | preservation evidence | medium | mitigate | Full baseline, provider, setup, formatter, and required-lane contracts pass. | closed |
| T-226-67 | Denial of Service | nested Mix integration | low | accept | Subprocess is focused, local, cleanup-bound, and uses compiled dependencies; limited test-runtime risk accepted. | closed |
| T-226-68 | Tampering | historical contract selection | high | mitigate | Contracts derive from exact head-SHA workflow bytes and thread through all admission decisions; divergence regression passes. | closed |
| T-226-69 | Spoofing | historical job/matrix/runner identity | high | mitigate | Closed alias resolution, declared runner classes, attempt isolation, and unresolved/ambiguous rejection pass. | closed |
| T-226-70 | Tampering | NDJSON → Markdown | high | mitigate | Complete per-kind semantic and URL/ID validation runs before rendering; forged production input leaves no output. | closed |
| T-226-71 | Information Disclosure | baseline/link surface | high | mitigate | D-06 allowlist and repository-bound destinations reject detailed/raw fields and foreign evidence. | closed |
| T-226-72 | Repudiation | frozen outcome/pair install | medium | mitigate | Immutable source links/digests, exact sample state, rollback-safe paired replacement, dual render, and installed verification are recorded. | closed |
| T-226-73 | Denial of Service | workflow retrieval/parsing | low | accept | History and caching are bounded by immutable SHA; precise failures cannot replace canonical evidence. | closed |
| T-226-74 | Tampering | provider/setup preservation | medium | mitigate | Complete provider, formatter, setup/readiness, required-lane, and API coverage contracts pass. | closed |
| T-226-21-01 | Spoofing | snapshot/run/job URL provenance | high | mitigate | Snapshot and URL repository must match independent caller context; forged persisted fields fail before rendering. | closed |
| T-226-21-02 | Tampering | persisted NDJSON → renderer | high | mitigate | Full record-set validation precedes Markdown construction and foreign evidence leaves no output. | closed |
| T-226-21-03 | Information Disclosure | validation errors/fixtures | medium | mitigate | Errors identify field/provenance failure without serializing credentials or raw sensitive data. | closed |
| T-226-21-04 | Denial of Service | malformed repository context | low | accept | Input fails closed with a bounded deterministic local error and performs no remote operation. | closed |
| T-226-21-SC | Tampering | package installs | high | mitigate | Phase plans and summaries introduce no package installation or dependency change. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*

*Severity: critical > high > medium > low — only open threats at or above `workflow.security_block_on` count toward `threats_open`.*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party).*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-226-01 | T-226-04 | Collection is deliberately bounded and fail-closed; transient API/timestamp availability cannot corrupt canonical evidence. | Phase 226 plan-time decision | 2026-08-11 |
| AR-226-02 | T-226-08 | Repository-bound immutable GitHub links plus retained IDs are proportionate for internal CI evidence. | Phase 226 plan-time decision | 2026-08-11 |
| AR-226-03 | T-226-34 | Local setup inspection is bounded to metadata and fixed registry values; raw content is never emitted. | Phase 226 plan-time decision | 2026-08-12 |
| AR-226-04 | T-226-39 | Deterministic repository-local tests and the validation ledger are proportionate; external signing is not warranted at ASVS L1. | Phase 226 plan-time decision | 2026-08-12 |
| AR-226-05 | T-226-43 | Atomic commits and exact validation commands adequately trace a reversible internal identity correction. | Phase 226 plan-time decision | 2026-08-12 |
| AR-226-06 | T-226-49 | Immutable sanitized links, exact commands, and atomic commits adequately trace a reversible evidence repair. | Phase 226 plan-time decision | 2026-08-12 |
| AR-226-07 | T-226-55 | Bounded workflow lookup may fail, but cannot weaken admission or partially replace evidence. | Phase 226 plan-time decision | 2026-08-12 |
| AR-226-08 | T-226-61 | Read-only GitHub availability risk is accepted because the phase introduces no mutation capability. | Phase 226 plan-time decision | 2026-08-12 |
| AR-226-09 | T-226-67 | The focused local subprocess may add bounded test runtime; it has deterministic scope and cleanup. | Phase 226 plan-time decision | 2026-08-12 |
| AR-226-10 | T-226-73 | Bounded historical retrieval may fail precisely, but cannot replace canonical evidence. | Phase 226 plan-time decision | 2026-08-12 |
| AR-226-11 | T-226-21-04 | Malformed trust context causes only a bounded deterministic local failure with no remote side effect. | Phase 226 plan-time decision | 2026-08-12 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-12 | 79 | 79 | 0 | Codex secure-phase orchestrator (ASVS L1 short circuit) |

## Security Audit 2026-08-12

| Metric | Count |
|--------|-------|
| Threats found | 79 |
| Closed | 79 |
| Open | 0 |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-08-12
