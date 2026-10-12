# Phase 248: Reproducible Scenarios and Integrated Proof - Pattern Map

**Mapped:** 2026-10-11  
**Files analyzed:** 6 planned/modified artifacts (2 host docs/tools, 2 proof owners, 2 tests/contracts)  
**Analogs found:** 5 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `examples/accrue_host/README.md` | config/documentation | request-response | `examples/accrue_host/README.md` isolated ordinary preview section | exact |
| `scripts/ci/accrue_host_evaluation_scenario.sh` (if a selector is needed) | utility | batch / file-I/O | `scripts/ci/seed_phase245_ordinary.sh`; `scripts/ci/accrue_host_preview_custody.sh` | role-match |
| `examples/accrue_host/e2e/phase247-current-proof.spec.js` | test | request-response / file-I/O | same current-proof spec | exact |
| `scripts/ci/verify_phase247_render_proof.mjs` (extend only if required) | utility / verifier | file-I/O / transform | same verifier | exact |
| `examples/accrue_host/test/evaluation_scenario_contract_test.exs` (if a new contract is needed) | test | CRUD / transform | `ordinary_preview_seed_test.exs`; `ordinary_preview_story_contract_test.exs` | role-match |
| `.planning/phases/248-reproducible-scenarios-and-integrated-proof/248-PROOF.md` | documentation / evidence ledger | transform | `245-FINDINGS.md`, `246-VERIFICATION.md`, `247-VERIFICATION.md` | role-match |

The selector, its test, and proof ledger are implied by the decisions and research, not locked filenames. Reuse existing files where they can express the contract. No source analog can establish an isolated empty/failure evaluation dataset yet; use the closest seed and custody contracts, then call out any unavailable mounted state explicitly.

## Pattern Assignments

### `examples/accrue_host/README.md` (host documentation, request-response)

**Analog:** The existing isolated ordinary preview section in the same tracked file.

The section gives the reviewer a compact sequence: establish a named Compose project, disable automatic seeds, run an explicit ordinary seed wrapper, authenticate through the normal local flow, inspect the route, then stop only that isolated instance. Reuse this sequence for documented states and include each state's preconditions, route/result and explicit cleanup.

**Host selection and custody pattern** (lines 119-162):

```bash
cd examples/accrue_host
make proxy # only when the shared proxy is not running
ACCRUE_HOST_SKIP_SEEDS=1 make up INSTANCE=accrue-host-phase245-ordinary
cd ../..
scripts/ci/seed_phase245_ordinary.sh
```

The following paragraph explains that the wrapper inspects the Compose network, volume and Postgres fingerprint, snapshots Phase 243, seeds only the ordinary project, and checks preservation. For exceptional states, mirror the explicit named target and skip-seed guard; do not call broad `make reset` or place stress fixtures in ordinary data. The README also requires Fake processor and normal authentication, and says missing credentials make inspection unavailable.

### `scripts/ci/accrue_host_evaluation_scenario.sh` (host utility, batch / file-I/O)

**Analog:** `scripts/ci/seed_phase245_ordinary.sh` and `scripts/ci/accrue_host_preview_custody.sh`.

**Target fingerprint and snapshot pattern** (`seed_phase245_ordinary.sh`, lines 8-45):

```bash
project=accrue-host-phase245-ordinary
compose_file=examples/accrue_host/docker-compose.yml
snapshot="${TMPDIR:-/tmp}/accrue245-phase243.snapshot.json"
compose=(docker compose -p "$project" -f "$compose_file")

web_id=$("${compose[@]}" ps -q web)
db_id=$("${compose[@]}" ps -q db)
[[ -n "$web_id" && -n "$db_id" ]] || die "ordinary web and db containers must already be running"
```

The wrapper checks inspected container labels, expected network/volume, and the Repo's actual connected DB name/role/address before executing the seed. It snapshots protected state before mutation and verifies it after, including cleanup/error paths. A new selector should use a fixed allowlist of scenario-to-isolated-target mappings, print only non-secret target identity, require startup with `ACCRUE_HOST_SKIP_SEEDS=1`, and restrict cleanup to its named isolated target.

**Shared custody guard** (`scripts/ci/accrue_host_preview_custody.sh`, lines 119-196): `assertDistinct` requires complete preview and target identity and rejects aliases across database host/name/connection/instance, Compose project, volume, port, process and build path before allowing proof work. `snapshot` and `assert-preserved` compare authoritative sentinel/audit/dispatch state. Treat this as the safety pattern for any state command.

### `examples/accrue_host/e2e/phase247-current-proof.spec.js` (browser proof, request-response / file-I/O)

**Analog:** Same tracked spec, with ordinary and held-out lane fixtures.

**Imports and current-source provenance** (lines 1-48): Playwright `test`/`expect`, existing `support/fixture.js` login and route helpers, Node crypto/fs/path, and `git rev-parse HEAD`. `sourceDigests()` hashes the listed product, asset, fixture, seed and harness files. Preserve these existing owners and extend their source inventory when changed proof-relevant inputs require binding.

**Served assets and capture matrix** (lines 177-267): `fetchAssets` reads rendered CSS/JS URLs, requests the actual bytes, and asserts their SHA-256 equals the built package. `captureMatrix` records named lane/scenario, exact route, wide/narrow viewport, light/dark theme, source SHA/digests, served asset metadata, assertion results, screenshot digest/size and inspection status. It writes/replaces only the relevant manifest entries. Reuse this for representative 248 state captures and keep unavailable combinations explicit.

**Mounted route and assertions** (lines 355-510): ordinary tests use the ordinary host fixture; held-out tests import the isolated `support/test.js` lane and create scoped fixtures. Assertions verify visible state before capture. This is the model for the boundary of browser evidence: mounted rendered outcomes are asserted, while database fixture creation remains owned by its lane.

### `scripts/ci/verify_phase247_render_proof.mjs` (evidence verifier, file-I/O / transform)

**Analog:** Same tracked verifier.

**Validation and failure handling** (lines 1-122): Node built-ins only; `check` fails closed with a specific error, `repoFile` rejects absolute/traversal paths, and `noSecrets` recursively refuses secret-bearing manifest keys. The verifier checks manifest shape, source commit and source digests, current product source, CSS/JS hashes, allowed lane/scenario/route, complete viewport/theme matrix, image path/hash/PNG dimensions, timestamped checks and inspected status. Extend the allowed schema/expected scenario matrix for 248 only when the existing verifier cannot represent it; avoid an independent screenshot metadata writer.

The current validator is intentionally specific to Phase 247 and expects 20 captures across five scenarios. A Phase 248 verifier extension should make its phase/schema expectations explicit rather than silently weakening those checks.

### `examples/accrue_host/test/evaluation_scenario_contract_test.exs` (scenario contract, CRUD / transform)

**Analogs:** `examples/accrue_host/test/ordinary_preview_seed_test.exs` and `ordinary_preview_story_contract_test.exs`.

**Isolation and idempotence pattern** (`ordinary_preview_seed_test.exs`, lines 1-99): tests use `DataCase, async: false`, start/reset the Fake processor, temporarily set the expected host environment/project and `ACCRUE_HOST_SKIP_SEEDS=1`, and restore the prior environment in `on_exit`. They execute the explicit seed and compare facts across reruns, asserting both expected records and exclusions. Use this contract shape for deterministic exceptional fixtures, but give each fixture a separate isolated DB/config owner.

**Relational story assertions** (`ordinary_preview_story_contract_test.exs`, lines 1-90): setup applies the named ordinary seed, then tests cross-record relationships and exact boundary facts rather than merely asserting record existence. For empty/failure/boundary states, assert the exact fixture identity and meaningful state invariant; do not infer rendered claims from seed presence alone.

There is no close existing contract for a separately selectable empty/failure evaluation host. Treat exact scenario mapping and non-destructive selection as a small new contract, while reusing current database and custody guards.

### `.planning/phases/248-reproducible-scenarios-and-integrated-proof/248-PROOF.md` (evidence ledger, transform)

**Analogs:** `.planning/phases/245-rendered-baseline-and-realistic-preview/245-FINDINGS.md`, `.planning/phases/246-collection-controls-and-search/246-VERIFICATION.md`, and `.planning/phases/247-evidence-true-details-and-analytics/247-VERIFICATION.md`.

The findings ledger is the canonical finding universe; the later verification records show the useful row pattern: a stable finding/criterion, owner surface, exact disposition or behavior, and named executed checks. Normalize one row per accepted owner topic and retain evidence limitations and deferred ideas as separate statuses. Connect each changed rendered surface to the current 248 capture entry and manifest verification. Prior manifests are historical unless their source revision equals the revision under test. Passing tests establish behavior, not subjective owner acceptance.

## Shared Patterns

### Scenario isolation and protected preview custody

**Sources:** `examples/accrue_host/README.md` lines 119-162; `scripts/ci/seed_phase245_ordinary.sh` lines 8-45; `scripts/ci/accrue_host_preview_custody.sh` lines 119-196.  
**Apply to:** Scenario launch, seed, cleanup and verification commands.

Use an explicit scenario name and isolated target. Set `ACCRUE_HOST_SKIP_SEEDS=1` at startup where applicable. Establish identity from the actual container/database, reject protected-target aliases before mutation, and make cleanup an explicit command scoped to the selected isolated target. Never emit credentials.

### Revision-bound rendered evidence

**Sources:** `examples/accrue_host/e2e/phase247-current-proof.spec.js` lines 177-267; `scripts/ci/verify_phase247_render_proof.mjs` lines 31-122.  
**Apply to:** Current browser captures and any integrated evidence references.

Record route/state/scenario, viewport, theme, source revision and digests, served CSS/JS digest, screenshot digest and inspection result. Assert the mounted visible outcome before capture. Run the existing verifier against the current manifest and report uncovered states.

### Finding ownership and check traceability

**Sources:** `.planning/phases/245-rendered-baseline-and-realistic-preview/245-FINDINGS.md`; `.planning/phases/246-collection-controls-and-search/246-VERIFICATION.md`; `.planning/phases/247-evidence-true-details-and-analytics/247-VERIFICATION.md`.  
**Apply to:** Every row in the integrated proof ledger.

Keep the canonical topic as a stable row key. Link its shared/page-specific owner, Phase 246/247 fix or justified disposition, exact owning executed check, and current capture where applicable. Distinguish product fix, evidence limitation and deferred idea; do not claim subjective acceptance.

## No Analog Found

| File / capability | Role | Data Flow | Reason |
|---|---|---|---|
| Isolated empty/failure scenario selector and fixture owner | utility / test | batch / CRUD | Existing host owns ordinary and held-out test fixtures, but no current host-only command selects all four requested evaluation states. Use the seed/custody contracts and document any state that cannot be safely rendered. |

## Metadata

**Analog search scope:** `examples/accrue_host/README.md`, `examples/accrue_host/e2e/`, `examples/accrue_host/test/`, `scripts/ci/`, and Phase 245-247 planning evidence.  
**Files scanned:** 8 primary tracked code analogs plus README and prior ledger/verification artifacts.  
**Pattern extraction date:** 2026-10-11
