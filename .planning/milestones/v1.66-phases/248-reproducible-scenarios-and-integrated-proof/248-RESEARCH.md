<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Use documented existing or minimal host-only commands to select ordinary, empty, failure and boundary states. Keep the ordinary Fake-host preview as the default; use separate isolated evaluation data/config for exceptional states. State selection must be explicit and inspectable, with no implicit destructive reset of the current preview or the protected Phase 243 host.
- **D-02:** Document exact state preconditions, launch/select command, expected route and visible result, cleanup and data custody for each state. Enforce `ACCRUE_HOST_SKIP_SEEDS=1` and the proper `ACCRUE_HOST` target at startup where applicable; never print credentials. Keep adversarial stress fixtures in their existing test owners and out of the ordinary preview.
- **D-03:** Treat the canonical owner feedback and Phase 245 findings ledger as the complete finding universe. Give each accepted finding one stable row with shared/page-specific owner, Phase 246/247 fix or justified disposition, and executed owning checks. Preserve distinctions between a product fix, an evidence limitation and a deferred idea; never imply subjective owner acceptance.
- **D-04:** Bind rendered confirmation to the exact tested source revision and served CSS/JS assets. Record route/state, scenario identity, viewport, theme and image inspection; use representative combinations and explicit uncovered/unsupported states. Prior Phase 245–247 manifests are historical receipts unless they match the current tested revision.
- **D-05:** Reuse existing capture, manifest, Playwright, seed-contract and verification owners. Add only the smallest contract/check needed to make the integrated proof auditable. Run current owning checks and report commands/results; do not duplicate the suite or make a new CI workflow.
- **D-06:** Keep scenario tooling outside production Admin and preserve existing owner scope, authorization, step-up, confirmation and action boundaries. Verification may inspect safe states but must not perform destructive preview reset or publish remotely.

### the agent's Discretion
Choose exact host-only command names, isolated dataset mechanism, representative capture selection, matrix format and test split from existing tooling. Prefer a small credible proof batch and make unavailable states explicit.

### Deferred Ideas (OUT OF SCOPE)
Rich interactive scenario selection, a production Admin scenario picker, new billing/Portal features, new Admin rooms, a further broad visual pass, remote tags and publication are outside this phase. A second owner feedback pass is a later decision.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DEMO-02 | Reviewers can reproduce the agreed ordinary, empty, failure and boundary evaluation states through documented existing or minimal host-only tooling without destructive implicit resets of the current preview. | Host README, Phase 245 ordinary seed/custody scripts and contracts, Phase 247 ordinary/held-out Playwright lanes, plus an explicit state/run/custody matrix. |
| PROOF-01 | Reviewers can trace every accepted owner finding to its shared/page-specific fix or justified disposition and its executed owning checks, including rendered confirmation of changed surfaces and evidence tied to the tested revision. | Canonical owner-feedback topic universe, Phase 245 findings ledger, Phase 246/247 validation records, Phase 247 capture manifest/spec/verifier, with current checks and revision-bound captures. |
</phase_requirements>

# Phase 248: Reproducible Scenarios and Integrated Proof - Research

**Researched:** 2026-10-11
**Domain:** Phoenix evaluation host scenarios, browser capture provenance, cross-phase acceptance evidence
**Confidence:** HIGH for existing owners and proof patterns; MEDIUM for the best minimal empty/failure scenario mechanism.

## Summary

Phase 248 is an integration and evidence phase. Accrue already has a separately seeded ordinary Fake-host preview, protected-preview custody checks, isolated Playwright lanes, a persisted Phase 245 finding ledger, and a Phase 247 manifest that binds browser images to source and served assets. Extend those owners with explicit, inspectable ordinary/empty/failure/boundary selection and a compact current-revision proof ledger; do not build a product feature or duplicate broad test suites. [VERIFIED: examples/accrue_host/README.md; scripts/ci/seed_phase245_ordinary.sh; scripts/ci/accrue_host_preview_custody.sh; examples/accrue_host/e2e/phase247-current-proof.spec.js; scripts/ci/verify_phase247_render_proof.mjs; .planning/phases/247-evidence-true-details-and-analytics/captures/phase247-current-proof/manifest.json]

The ordinary lane should continue using `accrue-host-phase245-ordinary.localhost` and the existing guarded ordinary seed story. Exceptional scenarios should be opt-in isolated evaluation datasets/configurations or existing test-owned fixtures, selected by documented host-only commands with a preflight that identifies the target and skips automatic seeds. Preserve existing preview data; cleanup must be explicit and limited to the isolated target. The precise empty/failure state mechanism is a project-specific choice that should be proven against current fixtures before being locked. [CITED: .planning/phases/248-reproducible-scenarios-and-integrated-proof/248-CONTEXT.md; examples/accrue_host/README.md; .planning/phases/245-rendered-baseline-and-realistic-preview/245-FINDINGS.md]

For PROOF-01, normalize accepted owner findings into one stable row per canonical topic from the owner feedback and `245-FINDINGS.md`. Link shared or page-specific owner, Phase 246/247 fix or evidence-limitation disposition, the owning executed checks and (for changed rendered surfaces) current capture/inspection evidence. A prior manifest is historical unless its recorded revision equals the current tested revision. Keep deferred suggestions and unavailable scenarios visible as such; the artifact must not imply subjective owner acceptance. [VERIFIED: .planning/notes/2026-10-11-admin-owner-feedback.md; .planning/phases/245-rendered-baseline-and-realistic-preview/245-FINDINGS.md; .planning/phases/246-collection-controls-and-search/246-VERIFICATION.md; .planning/phases/247-evidence-true-details-and-analytics/247-VERIFICATION.md; .planning/phases/247-evidence-true-details-and-analytics/captures/phase247-current-proof/manifest.json]

**Primary recommendation:** Reuse the existing host README, seed/custody scripts and tests, Playwright capture spec, manifest validator and phase finding/validation records; add only a guarded host-only scenario selector/contract and an integrated proof ledger/check if the existing files cannot express the four states and traceability.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Choosing evaluation scenario and data custody | Browser / Client — host tooling | Database / Storage | The launcher selects a local host configuration; Repo/database guards must ensure the operation targets only its isolated evaluation database. |
| Rendering selected Admin state | Frontend Server (SSR) | Database / Storage | Existing mounted Phoenix LiveViews render records from the host Repo; state data belongs to the evaluation fixture owner. |
| Capturing rendered proof | Browser / Client | Frontend Server (SSR) | Playwright drives actual routes, viewport/theme and screenshot capture while reading served assets from the host. |
| Cross-phase finding traceability | CDN / Static — planning artifact | — | The integrated ledger is documentation/evidence, not runtime product behavior. |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Existing Elixir/Phoenix host and Repo tests | Existing project versions; no upgrade proposed | Isolated scenario data, guard checks and rendered Admin routes | Phase 245 and 247 already exercise the canonical `examples/accrue_host` evaluation path. [VERIFIED: examples/accrue_host/README.md; .planning/phases/245-rendered-baseline-and-realistic-preview/245-VERIFICATION.md] |
| Existing Playwright setup | Existing project version; no upgrade proposed | Mounted browser inspection and capture matrices | Phase 247 already separates ordinary and held-out lanes and writes current proof metadata. [VERIFIED: examples/accrue_host/playwright.phase247-ordinary.config.js; examples/accrue_host/playwright.phase247.config.js; examples/accrue_host/e2e/phase247-current-proof.spec.js] |
| Node.js built-in test/assert and filesystem APIs | Existing runtime; no new package | Deterministic manifest/custody validators | Existing verifier and custody test entrypoint use these owners. [VERIFIED: scripts/ci/verify_phase247_render_proof.mjs; scripts/ci/test_accrue_host_preview_custody.mjs] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Existing PostgreSQL/Compose host services | Existing project configuration | Isolated ordinary or exceptional evaluation database | Only where a scenario needs persisted records; verify actual target before setup/cleanup. [CITED: examples/accrue_host/README.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| A host-only command/config and scenario contract | Production Admin scenario picker | Adds runtime UI and product surface outside the approved boundary; do not choose. [CITED: .planning/phases/248-reproducible-scenarios-and-integrated-proof/248-CONTEXT.md] |
| Separate explicit isolated state data | Implicit reset/reseed of current ordinary preview | Reset risks destroying reviewer state and violates the no-destructive-implicit-reset contract; do not choose. [CITED: .planning/phases/248-reproducible-scenarios-and-integrated-proof/248-CONTEXT.md] |
| Existing package/test-owned adversarial fixtures | Copy fixtures into ordinary preview | Duplicates ownership and lets stress data distort ordinary reviewer evaluation; do not choose. [CITED: .planning/phases/245-rendered-baseline-and-realistic-preview/245-CONTEXT.md] |

**Installation:** None. No external package or runtime dependency is indicated by this phase. [CITED: .planning/phases/248-reproducible-scenarios-and-integrated-proof/248-CONTEXT.md]

## Package Legitimacy Audit

No external packages are proposed for installation in this phase; package legitimacy gate is not applicable. Keep `playwright`, Phoenix and project dependencies as existing owners and do not add dependencies to implement scenario selection or proof.

## Architecture Patterns

### System Architecture Diagram

```text
Reviewer
  │ chooses explicit scenario command
  ▼
Host-only launcher ──preflight target/skip-seed guards──► isolated Fake host + scenario data
  │                                                       │
  │                                                       ▼
  └── documented route/result/custody ◄──────────── mounted Admin LiveView
                                                          │
                                                          ▼
Playwright lane ── route/state/viewport/theme ──► screenshot + served CSS/JS digests
                                                          │
                                                          ▼
Manifest verifier ── source revision + asset/image checks ──► inspected proof receipts
                                                          │
                                                          ▼
Integrated finding ledger ◄── canonical owner topics + 246/247 checks/dispositions
```

### Recommended Project Structure

```text
examples/accrue_host/
├── README.md                         # state preconditions, select/run, visible outcome, cleanup/custody
├── e2e/phase247-current-proof.spec.js # existing mounted capture owner; extend only if needed
└── test/                             # scenario seed and contract owners
scripts/ci/
├── seed_phase245_ordinary.sh         # ordinary-state seed/custody owner
├── accrue_host_preview_custody.sh    # protected/current preview guard owner
└── verify_phase247_render_proof.mjs  # current rendered evidence validator
.planning/phases/248-reproducible-scenarios-and-integrated-proof/
├── 248-RESEARCH.md
├── 248-*-PLAN.md
└── 248-PROOF.md                      # recommended integrated finding-to-check/capture ledger
```

### Pattern 1: Guarded isolated scenario selection

**What:** Require an explicit state name and verify the selected host instance/database before any seed or cleanup operation. Startup uses the skip-seed flag where applicable; output may identify scenario and target but never credentials. Keep ordinary default selection unchanged.

**When to use:** Every reproducible evaluation state, especially empty/failure/boundary states that need separate data.

**Example:**

```sh
# Existing ordinary host setup pattern; exceptional lanes should follow its explicit target/guard shape.
ACCRUE_HOST_SKIP_SEEDS=1 make up INSTANCE=accrue-host-phase245-ordinary
```

Source: `examples/accrue_host/README.md`. This is an existing documented command, not a proposed new production interface. [VERIFIED: examples/accrue_host/README.md]

### Pattern 2: Revision and served-asset-bound capture

**What:** Capture the actual mounted route and record route, named scenario, origin lane, viewport, theme, source SHA/source digests, served CSS/JS path and digest, screenshot hash and inspection status. Validate current source and assets before treating images as evidence.

**When to use:** Rendered confirmation for each changed owner surface in the integrated proof; use a representative matrix and report uncovered combinations.

**Example:** Phase 247's current-proof spec implements `sourceSha()`, `sourceDigests()`, `fetchAssets()` and `captureMatrix()`; its manifest records `origin_lane`, `scenario`, `route`, `viewport`, `theme`, `source_sha`, `assets`, `screenshot.sha256` and `inspection_status`. [VERIFIED: examples/accrue_host/e2e/phase247-current-proof.spec.js; .planning/phases/247-evidence-true-details-and-analytics/captures/phase247-current-proof/manifest.json]

### Pattern 3: Finding ledger with owning evidence

**What:** Use one deterministic row per canonical accepted finding. Each row points to its shared/page owner, existing implementation phase, justified non-fix disposition when applicable, named executed checks and current rendered evidence where the surface changed. Give a reason for unavailable/unsupported rows instead of treating missing evidence as a pass.

**When to use:** Integrated acceptance spanning Phase 245–247 owner topics and DEMO-02 state coverage.

**Example:** Start from the deduplicated topic ledger and evidence indexes in `245-FINDINGS.md`; add links to Phase 246/247 verification owners and the exact current-proof manifest entry/check. [VERIFIED: .planning/phases/245-rendered-baseline-and-realistic-preview/245-FINDINGS.md; .planning/phases/247-evidence-true-details-and-analytics/247-VERIFICATION.md]

### Anti-Patterns to Avoid

- **Seeding exceptional data into the ordinary default:** breaks the reviewer story and can invalidate ordinary seed contracts.
- **Implicit reset before a scenario:** can destroy the current preview or reach the protected Phase 243 instance.
- **Treating old captures as current proof:** source and served assets may differ from the tested checkout.
- **Claiming owner acceptance from implementation evidence:** executed checks show behavior; they do not establish subjective approval.
- **Cloning stress fixtures into demo setup:** stress data remains owned by its existing tests.
- **Printing login values or credentials in logs/manifests:** the README explicitly says not to include operator credentials in capture output. [CITED: examples/accrue_host/README.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Protected preview custody | A new unguarded DB snapshot/reset mechanism | `scripts/ci/accrue_host_preview_custody.sh` and its tests | Existing code fingerprints target database/network/volume and checks protected snapshot preservation. [VERIFIED: scripts/ci/accrue_host_preview_custody.sh; scripts/ci/test_accrue_host_preview_custody.mjs] |
| Ordinary preview data | A second hand-curated copy of billing rows | `seed_phase245_ordinary.sh`, `priv/repo/seeds/ordinary.exs` and story/seed contracts | Existing owner protects Fake host selection, isolated target and story consistency. [VERIFIED: scripts/ci/seed_phase245_ordinary.sh; examples/accrue_host/priv/repo/seeds/ordinary.exs; examples/accrue_host/test/ordinary_preview_story_contract_test.exs] |
| Capture provenance | A second screenshot metadata writer/validator | Phase 247 current-proof spec, manifest and verifier | Existing format validates source and served assets plus image metadata. [VERIFIED: examples/accrue_host/e2e/phase247-current-proof.spec.js; scripts/ci/verify_phase247_render_proof.mjs] |
| Billing state and action behavior | New production Admin routes or scenario UI | Existing LiveView owners and host fixtures | Phase scope is existing Admin evaluation; action authorization and confirmation already have owning checks. [CITED: .planning/phases/248-reproducible-scenarios-and-integrated-proof/248-CONTEXT.md] |

**Key insight:** The evidence pipeline already exists. The planning risk is mislabeling fixtures or allowing a state-selection command to target shared/protected data, not a missing browser or manifest framework.

## Common Pitfalls

### Pitfall 1: Scenario command mutates the ordinary or protected preview

**What goes wrong:** State setup changes the current reviewer database or Phase 243 host.
**Why it happens:** A command assumes stack name/default DB, runs broad `make reset`, or doesn't skip ordinary automatic seeds.
**How to avoid:** Require explicit target identity; use `ACCRUE_HOST_SKIP_SEEDS=1` where applicable; reuse custody preflight; separate exceptional data/config; make cleanup explicit and isolated.
**Warning signs:** No printed target identity, no DB fingerprint, startup runs default seed aggregator, or test can pass against a different host.

### Pitfall 2: Empty/failure scenarios claim unsupported states

**What goes wrong:** A page that has no fixture data is described as a verified empty state, or an unavailable error path is described as a failure scenario.
**Why it happens:** Empty, unavailable and error outcomes are collapsed; static source assertions are treated as rendered evidence.
**How to avoid:** Define precondition, exact route, visible expected result, owner fixture and cleanup for each state; capture only states the host can render deterministically. State unavailability explicitly when it cannot be safely reproduced.
**Warning signs:** No persisted or controlled fixture identity, no mounted assertion of expected copy/row count, or vague “error page tested” language.

### Pitfall 3: Historical captures are counted as current proof

**What goes wrong:** Prior 245–247 receipts are presented as confirmation of current tested source.
**Why it happens:** Manifests remain valid for their recorded revision but are not regenerated after later changes.
**How to avoid:** Run the current owning capture lane, bind capture and served CSS/JS hashes to exact checkout, validate manifest, visually inspect images, and label old receipts historical unless revision matches.
**Warning signs:** Revision mismatch, asset digest mismatch, pending image inspection, or capture route/scenario metadata missing.

### Pitfall 4: Integrated finding rows lose ownership or disposition meaning

**What goes wrong:** Duplicate findings, missing checks, or deferred ideas are falsely represented as fixed.
**Why it happens:** Findings are copied from narrative feedback rather than normalized from the canonical ledger; disposition categories are flattened.
**How to avoid:** Derive the stable universe from canonical owner feedback and Phase 245 findings; preserve each row's owner and distinguish product fix, evidence limitation and deferred idea. Link the executed phase-owned checks.
**Warning signs:** Rows without a stable ID/topic, one check asserted for unrelated owners, “accepted” inferred from a passing test, or deferred items mixed into completed findings.

### Pitfall 5: Scenario fixture violates data custody or leaks credentials

**What goes wrong:** A fixture uses a live provider, targets customer data or exposes local login secrets in captured artifacts.
**Why it happens:** The browser lane inherits ambient config or serializes process environment into diagnostics.
**How to avoid:** Require Fake target and isolated host; keep secrets in process memory/environment and redact logs; authenticate normally; don't bypass owner scope/step-up/confirmation.
**Warning signs:** Credential-like values in output, target processor not verified, or capture flow submits a destructive/replay action.

## Code Examples

### Existing ordinary preview startup and seed path

```sh
cd examples/accrue_host
ACCRUE_HOST_SKIP_SEEDS=1 make up INSTANCE=accrue-host-phase245-ordinary
cd ../..
scripts/ci/seed_phase245_ordinary.sh
```

The README documents this as a separate Compose project/database; the wrapper checks target identity and protected Phase 243 custody before/after seeding. Do not use `make reset` for scenario selection. [VERIFIED: examples/accrue_host/README.md; scripts/ci/seed_phase245_ordinary.sh; scripts/ci/accrue_host_preview_custody.sh]

### Existing current proof invocation shape

```sh
cd examples/accrue_host
PHASE247_PROOF_LANE=ordinary ACCRUE_HOST_ORDINARY_BASE_URL=http://accrue-host-phase245-ordinary.localhost \
  npx playwright test --config=playwright.phase247-ordinary.config.js e2e/phase247-current-proof.spec.js
```

This illustrates the existing lane/config pattern only; planner should read the exact current README/run script before writing final commands because environment/password setup varies. Validator invocation from Phase 247 is `node scripts/ci/verify_phase247_render_proof.mjs --manifest <manifest>`. [VERIFIED: examples/accrue_host/e2e/phase247-current-proof.spec.js; scripts/ci/verify_phase247_render_proof.mjs; .planning/phases/247-evidence-true-details-and-analytics/247-VALIDATION.md]

## Environment Availability

No new external dependency has been identified. Phase 248 uses existing host tooling, Docker/Compose, Mix/Elixir, Node and Playwright. Availability is governed by the existing local host workflow; the planning artifact should report the exact commands used for the proof run and identify any unavailable lane rather than installing a replacement stack. [CITED: examples/accrue_host/README.md; .planning/phases/247-evidence-true-details-and-analytics/247-VALIDATION.md]

## Validation Architecture

Nyquist validation is enabled in `.planning/config.json`. Existing validation owners are sufficient; add only the smallest contract required for the new scenario selection/proof mapping.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit in host tests; Playwright in mounted browser proof; Node built-in test/assert for CI validators |
| Config file | `examples/accrue_host/playwright.phase247.config.js`, `examples/accrue_host/playwright.phase247-ordinary.config.js` |
| Quick run command | `cd examples/accrue_host && MIX_ENV=test mix test test/ordinary_preview_story_contract_test.exs test/ordinary_preview_seed_test.exs` (ordinary data contracts) |
| Full suite command | Use the current documented Phase 247 Admin and mounted lanes recorded in `247-VALIDATION.md`; do not replace with a duplicate broad suite. |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DEMO-02 | Ordinary state remains isolated, internally consistent and repeatable | ExUnit/host contract | `cd examples/accrue_host && MIX_ENV=test mix test test/ordinary_preview_story_contract_test.exs test/ordinary_preview_seed_test.exs` | Yes |
| DEMO-02 | Scenario selection rejects wrong target and avoids implicit seed/reset | Shell/Node guard contract | Existing custody wrapper/test plus minimal new selector contract if needed | Existing custody tests; selector contract may be Wave 0 |
| DEMO-02 | Empty/failure/boundary states show the declared result | Mounted Playwright + fixture contract | Existing Phase 247 lane/config/spec pattern; specific tests depend on selected fixture mechanism | Partial; state-specific assertions may be Wave 0 |
| PROOF-01 | Each canonical finding maps to owner, disposition/fix and executed check | Deterministic artifact verifier or documented ledger audit | Add small verifier only if stable row completeness cannot be checked by current validators | No integrated ledger yet |
| PROOF-01 | Changed rendered surfaces are captured for tested source and served assets | Playwright + Node manifest verifier | `node scripts/ci/verify_phase247_render_proof.mjs --manifest <current-manifest>` | Yes; capture spec exists |

### Sampling Rate

- **Per task commit:** Run the focused owning ExUnit/Node contract for changed scenario or ledger code.
- **Per wave merge:** Run the relevant ordinary and exceptional scenario lanes and their artifact verifier.
- **Phase gate:** Current Phase 245–247 owning checks required by changed rows, current mounted proof, manifest validation and final finding-ledger completeness review.

### Wave 0 Gaps

- [ ] Define deterministic, isolated fixture/config owners for empty, failure and boundary states and assert visible route outcomes.
- [ ] Define one stable finding row key/schema and verify every canonical accepted topic has an owner, disposition/fix and executed check.
- [ ] Connect current revision capture inspection to changed rows; existing manifests prove this pattern but not Phase 248's integrated mapping.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | Yes | Use existing authenticated operator flow; do not store/print credentials in proof artifacts. |
| V3 Session Management | Yes | Reuse normal session and CSRF-protected login flow in existing Playwright support. |
| V4 Access Control | Yes | Preserve current organization/owner scope and action authorization; fixtures must not widen reads. |
| V5 Input Validation | Yes | Validate scenario identifier against an explicit allowlist; reject arbitrary target/database input. |
| V6 Cryptography | No new crypto control | Use existing SHA-256 capture/asset provenance implementation; do not create a custom hashing scheme. |

### Known Threat Patterns for Phoenix host evaluation

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Wrong-host or shared-DB seed/reset | Tampering / Denial of Service | Exact target/instance/database preflight, isolated DB, skip automatic seeds, custody comparison. |
| Leaked operator secret in output | Information Disclosure | Keep credentials in process environment/memory; redact logs and manifests. |
| Scenario selector accepts arbitrary target | Elevation of Privilege / Tampering | Fixed scenario names, host-only command surface, explicit allowlist and fail-closed behavior. |
| Capture replays destructive action | Tampering | Capture pre-confirmation review state only; never submit confirmation/replay or perform preview reset. |
| Stale manifest treated as current | Spoofing | Verify exact source revision and served CSS/JS digest and record screenshot hash/inspection status. |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/248-reproducible-scenarios-and-integrated-proof/248-CONTEXT.md` — locked state, custody, finding and revision-bound proof decisions.
- `.planning/notes/2026-10-11-admin-owner-feedback.md` — canonical owner feedback universe and boundaries.
- `.planning/phases/245-rendered-baseline-and-realistic-preview/245-FINDINGS.md`, `245-ORDINARY-STORIES.md`, `245-VERIFICATION.md` — findings, ordinary story/custody and existing coverage limitations.
- `.planning/phases/246-collection-controls-and-search/246-VERIFICATION.md` — shared collection/search checks.
- `.planning/phases/247-evidence-true-details-and-analytics/247-VERIFICATION.md`, `247-VALIDATION.md` and current proof manifest — current owner checks and capture contract.
- `examples/accrue_host/README.md`, `scripts/ci/seed_phase245_ordinary.sh`, `scripts/ci/accrue_host_preview_custody.sh`, `examples/accrue_host/e2e/phase247-current-proof.spec.js`, `scripts/ci/verify_phase247_render_proof.mjs` — concrete implementation owners.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Existing tooling can host all four states by adding isolated data/config and minimal host-only selection, without a new package. | Summary/Architecture | Medium: one scenario may need a new fixture owner or may be unavailable; prove each state before promising it. |
| A2 | A stable integrated ledger can be checked with a small deterministic validator or a manual artifact audit. | Validation Architecture | Low: choose the smallest mechanism after inspecting canonical finding row count/shape. |

## Open Questions (RESOLVED)

1. **What deterministic isolated data mechanism best represents empty and failure states?** RESOLVED by Plan 248-01: use the existing 4102 SQL-sandbox browser fixture owner; assert a genuinely unfiltered zero-record scoped collection and an observed failed billing/webhook record before capture. If either assertion cannot be mounted safely, execution reports a gap instead of substituting a filtered-zero or host outage.
   - What we know: Phase 245 explicitly lists true unfiltered-empty and stable app-error among unverified states; Phase 247 has an isolated held-out lane and existing fixture setup patterns.
   - What's unclear: Whether the current host can safely select those states through a test-owned fixture, a separate seed file or a dedicated disposable DB without new infrastructure.
   - Recommendation: Inspect existing test fixture owners and choose one minimal explicit host-only command per state. If a state cannot be safely reproduced, document it as unavailable with a concrete reason; do not use a broad reset.

2. **Which owner findings need fresh rendered confirmation after the current Phase 247 checkout?** RESOLVED by Plan 248-02: map all 13 canonical owner topics and F01–F05 to changed shared/page owners, then select representative current Phase 248 captures from that map. Retain Phase 245–247 manifests as historical unless exact tested source and served-asset identities match.
   - What we know: Phase 247 current proof contains 20 inspected images at source revision `48a8d7fdde48`; these receipts bind images to source and served assets.
   - What's unclear: Which source changes occur during Phase 248 and which accepted findings can be covered by representative routes/states rather than a full combination matrix.
   - Recommendation: Use source diff/changed owner mapping to select a credible compact capture batch; mark remaining rows as behavior/test-only, historical, deferred or unavailable with reasons.

## Project Constraints (from AGENTS.md)

No `AGENTS.md` exists in the repository root. No additional project directives were found during this research.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all named tools are existing repo owners read during this session; no package installation is proposed.
- Architecture: HIGH — existing host/capture flow is explicit in README, Playwright code and manifests.
- Pitfalls: HIGH — protected custody, seed guards and stale-revision limits are documented and implemented; empty/failure fixture selection remains MEDIUM.

**Research date:** 2026-10-11
**Valid until:** 2026-11-10 (stable host/test ownership; recheck current manifests and run evidence during execution)
