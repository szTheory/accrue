# Phase 243: Integrated Evidence and Feedback Preview - Pattern Map

**Mapped:** 2026-10-10  
**Files analyzed:** 15 likely existing owners/artifacts  
**Analogs found:** 15 / 15

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue_admin/e2e/admin-visual-regression-phase211.spec.js` | test | request-response / visual render | itself (selected screenshot owner) | exact |
| `accrue_admin/e2e/support/admin-visual-helpers.js` | utility | request-response | itself (fixture and capture helpers) | exact |
| `accrue_admin/e2e/visual-baseline-set.cjs` | utility | file-I/O | itself (expected-set guard) | exact |
| `accrue_admin/test/js/visual_baseline_set_test.mjs` | test | file-I/O | itself (positive and negative controls) | exact |
| `.github/workflows/accrue_admin_browser.yml` | config | CI / batch | itself (blocking Linux compare and manual mint) | exact |
| `accrue_admin/playwright.config.js` | config | request-response / visual render | itself (visual project and thresholds) | exact |
| `examples/accrue_host/README.md` | config/docs | request-response / operator workflow | itself (preview entry and recovery docs) | exact |
| `examples/accrue_host/Makefile` | utility | process / container lifecycle | itself (instance and destructive targets) | exact |
| `examples/accrue_host/docker-compose.yml` | config | process / database | itself (isolated Compose instance) | exact |
| `examples/accrue_host/bin/dev-entrypoint.sh` | utility | process / database / file-I/O | itself (bootstrap and skip-seed recovery) | exact |
| `scripts/ci/accrue_host_verify_dev_boot.sh` | utility | process / database | itself (dev create/migrate/server boot) | exact |
| `examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js` | test | request-response / browser | itself (mounted asset provenance and route inspection) | exact |
| `.planning/phases/240-shared-system-and-real-billing-exemplar/240-COVERAGE.md` | config/docs | evidence reconciliation | itself (route/state ledger) | exact |
| `.planning/phases/241-billing-operator-journeys/241-08-SUMMARY.md` | config/docs | evidence reconciliation | itself (corrected spacing evidence contract) | exact |
| `.planning/phases/242-investigations-and-remaining-admin-surfaces/242-EXECUTION-HANDOFF.md` | config/docs | evidence reconciliation | itself (current completion and named gaps) | exact |

The candidate change list is inferred from 243 CONTEXT D-01–D-16 and RESEARCH “Recommended Project Structure,” “Wave 0 Gaps,” and “Phase Requirements → Test Map.” Exact additions remain planner decisions: a new invoice snapshot is conditional on recurring protection value; a recovery test is needed only if the existing owner does not prove preservation. Do not create another route/state registry or CI workflow.

All named code analogs were checked with `git ls-files -- <path>` and are tracked source files, not `.gsd` runtime mirrors. No root or ancestor `AGENTS.md` and no `.codex/skills/` or `.agents/skills/` project skill directories were found.

## Pattern Assignments

### Selected screenshots, expected-set guard, and controls

**Analogs:** `accrue_admin/e2e/admin-visual-regression-phase211.spec.js`, `accrue_admin/e2e/visual-baseline-set.cjs`, `accrue_admin/test/js/visual_baseline_set_test.mjs`

The existing visual spec is the exact owner. Keep the fixture sequence and route loop together; extend only a justified composition. Current reset/seed/capture behavior:

```js
test.beforeEach(async ({ request }) => {
  await reset(request);
});

await seed(request, "operator-flows");
const dash = await seed(request, "dashboard");
await seed(request, "edge-states");
```

Source: `accrue_admin/e2e/admin-visual-regression-phase211.spec.js:95-110`.

Snapshots use both themes and the configured full-page choice, with masks supplied per surface:

```js
await expect(page).toHaveScreenshot(file, {
  fullPage,
  animations: "disabled",
  mask: maskLocators(page, name),
  maskColor: "#FF00FF"
});
```

Source: `accrue_admin/e2e/admin-visual-regression-phase211.spec.js:122-139`. The visual project and threshold owner is `accrue_admin/playwright.config.js:11-21,36-57`; preserve `threshold: 0.2` and `maxDiffPixelRatio: 0.01`.

The expected-set owner freezes names and returns all missing members:

```js
const EXPECTED_BASELINES = Object.freeze([
  "dashboard.png",
  "dashboard-dark.png",
  "subscriptions.png",
  "subscriptions-dark.png",
  "subscription-detail.png",
  "subscription-detail-dark.png",
  "component-kitchen.png",
  "component-kitchen-dark.png"
]);
```

Source: `accrue_admin/e2e/visual-baseline-set.cjs:4-13`. Any selected addition belongs in this array and the test's exact expected list. Preserve the Node test's complete, absent, empty, and individually omitted-file controls (`accrue_admin/test/js/visual_baseline_set_test.mjs:26-73`). The Linux workflow guard executes before comparison (`.github/workflows/accrue_admin_browser.yml:80-87`); the update/mint path remains separate (`:105-115,170-178`).

### Timestamp mask scope

**Analog:** `accrue_admin/e2e/admin-visual-regression-phase211.spec.js:25-79`

The incumbent helper returns locators selected by composition. Reuse its label-scoped style where possible:

```js
page
  .locator(".ax-summary-list-row")
  .filter({ hasText: /Current period|Renews \/ ends/ })
  .locator(".ax-summary-list-value")
```

This is a more useful starting point than the positional `tbody tr td:nth-child(4)`, whole renewal fact, or broad body-text selectors also present in the same file. For every changed/new mask, planning should assign rendered positive-match and protected-fact assertions at this browser owner; source selector presence alone is not evidence. Keep identity, money, state, action, errors, and contextual labels outside masks. Prefer deterministic fixture time for a new invoice example if feasible.

### Preview documentation, container identity, and warm recovery

**Analogs:** `examples/accrue_host/README.md`, `examples/accrue_host/Makefile`, `examples/accrue_host/docker-compose.yml`, `examples/accrue_host/bin/dev-entrypoint.sh`

The README is canonical for the Docker-first startup, stable URL, loopback fallback, operator audience, and optional feedback boundary (`README.md:14-34,48-67`). Keep the walkthrough framed as sign in → navigate/inspect/reload → record feedback outside the app. The entrypoint's seed gate is the established warm-recovery seam:

```sh
if [ "${ACCRUE_HOST_SKIP_SEEDS:-}" = "1" ]; then
  echo "[entrypoint] seeds skipped (ACCRUE_HOST_SKIP_SEEDS=1)"
else
  echo "[entrypoint] seeds (idempotent)"
  mix run priv/repo/seeds.exs
fi
```

Source: `examples/accrue_host/bin/dev-entrypoint.sh:71-76`; Compose forwards the variable and defines `PGHOST: db` (`docker-compose.yml:27-40`). Note that startup still performs `ecto.create` and `ecto.migrate` (`entrypoint.sh:65-69`).

Instance identity is controlled by the Makefile's `INSTANCE` / `COMPOSE_PROJECT_NAME` export (`examples/accrue_host/Makefile:3-10`), with persistent `pgdata` and host port mapping in Compose (`docker-compose.yml:6-17,38-45,78-95`). Keep `make reset` visibly destructive: it runs `docker compose down --volumes` (`Makefile:67-72`). Warm recovery is `ACCRUE_HOST_SKIP_SEEDS=1 make up`, only after establishing the intended instance/database/port/process. Do not infer preview safety from environment-variable labels alone.

### Full verifier isolation

**Analogs:** `scripts/ci/accrue_host_verify_browser.sh`, `scripts/ci/accrue_host_verify_dev_boot.sh`

The whole verifier contains separate proof custody. Browser setup drops/creates/migrates/seeds the test database (`accrue_host_verify_browser.sh:108-126`); the dev boot script separately checks a port, creates/migrates the dev database, and starts Phoenix:

```sh
ensure_port_available "$port"

MIX_ENV=dev mix ecto.create --quiet
MIX_ENV=dev mix ecto.migrate --quiet

PORT="$port" MIX_ENV=dev mix phx.server >"$log_file" 2>&1 &
server_pid=$!
```

Source: `scripts/ci/accrue_host_verify_dev_boot.sh:60-66`. If changing isolation, modify/reuse this incumbent seam and reason about the complete wrapper and effective DB/instance/process targets. The historical Phase 239 test-only explanation is superseded by current code and the Phase 242 handoff.

### Mounted CSS evidence and inspection

**Analog:** `examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js`

Reuse `assertCurrentAdminAssets` for the source-to-browser provenance chain. It reads package and host-compiled bytes, fetches served bytes, checks browser resource use, compares SHA-256 at each boundary, and attaches a JSON manifest (`:16-57`). Its key equality assertions are:

```js
expect(sha256(packageBytes), `compiled host matches package build: ${packagePath}`).toBe(sha256(compiledBytes));
expect(sha256(servedBytes), `HTTP response matches package build: ${packagePath}`).toBe(sha256(packageBytes));
expect(browserRequested, `browser used current served asset ${servedPath}`).toBeTruthy();
```

Extend/re-run this owner to close the corrected CSS HTTP identity gap, after ensuring disposable host proof custody. Package asset source changes require explicit `mix accrue_admin.assets.build`; package/compiled parity does not prove HTTP-served bytes.

### Final coverage and evidence reconciliation

**Analogs:** `240-COVERAGE.md`, `241-08-SUMMARY.md`, `242-EXECUTION-HANDOFF.md`

Use Phase 240's existing route applicability/owner ledger (`240-COVERAGE.md:1-7,9-37`) and preserve its distinction between `exercised`, `source-only`, and `historical`. The final additions should link changed consumers to their actual recurring owners and results rather than turn eight screenshots or an aggregate suite into broad route coverage. Phase 241 Plan 08 demonstrates the preferred precision: owner, commands, exact evidence status, top-level `human_judgment: false`, and package-scoped limit (`241-08-SUMMARY.md:13-16,26-57`). Phase 242 handoff records the current corrected CSS source/package/compiled state while explicitly saying host HTTP identity remains unobserved (`242-EXECUTION-HANDOFF.md:15-26`). Preserve such boundaries rather than rewriting prior evidence.

## Shared Patterns

### Faithful evidence tiers

**Sources:** `examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js:16-57`; `240-COVERAGE.md:3-7`; `242-EXECUTION-HANDOFF.md:15-26`  
**Apply to:** visual, mounted-host, preview, and final handoff claims.

Record source, fixture, built, compiled, HTTP-served, browser-rendered, and exercised observations at the tier they actually establish, with revision/command provenance. Linux comparison is required for EVR-03; local macOS screenshots are inspection evidence. Fake preview does not establish provider parity. HTTP page observation does not prove absence of LiveView writes.

### Custody before mutation

**Sources:** `examples/accrue_host/Makefile:8-10,67-72`; `examples/accrue_host/docker-compose.yml:6-17,27-45`; `scripts/ci/accrue_host_verify_browser.sh:108-126`; `scripts/ci/accrue_host_verify_dev_boot.sh:60-66`  
**Apply to:** any proof/reset/restart command involving host or package fixtures.

Establish actual Compose instance, database host/name, volume, listener port, and process before running mutation proof. Use disposable proof databases and servers. The preview warm-recovery seam skips seeds but still migrates; `make reset` removes volumes.

### Acceptance generation order

**Sources:** `243-CONTEXT.md` D-16; `CLAUDE.md` Executable Acceptance Policy; `241-CI-CONTRACT.md`  
**Apply to:** phase closeout artifacts only.

Keep normal SUMMARY coverage (`human_judgment: false`) and independent verification (`status: passed`, `behavior_unverified: 0`) before generating Phase 243 automated UAT and running `--all-since 229`. Do not create a parallel metadata reconciliation loop.

## No Analog Found

None for the identified likely owners. Conditional new invoice snapshot or warm-recovery assertion should follow the incumbents above; if planning identifies a genuinely new file, classify it against the nearest owner and keep it within existing lanes.

## Metadata

**Analog search scope:** visual spec/config/guard/Node controls; host README/Makefile/Compose/entrypoint; mounted host browser tests; CI verifier scripts; 240–242 canonical evidence artifacts.  
**Files scanned:** 15 likely owner/artifact paths plus phase context/research and acceptance policy.  
**Pattern extraction date:** 2026-10-10.
