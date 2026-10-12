# Phase 245: Rendered Baseline and Realistic Preview - Pattern Map

**Mapped:** 2026-10-11  
**Files analyzed:** 5 anticipated files (3 phase artifacts/tooling owners, 2 host owners)  
**Related analogs found:** 5 / 5; no exact owner exists yet for the current exhaustive ledger or ordinary-only seed entrypoint.

The CONTEXT and RESEARCH do not lock new source paths. The following are the concrete file roles implied by BASE-01/02 and DEMO-01; planner may consolidate phase artifacts while keeping the route/state ledger, capture evidence, and ordinary preview owner explicit. Existing Phase 243 feedback DB is protected. No source/service/database changes are performed by this mapping.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/phases/245-rendered-baseline-and-realistic-preview/245-COVERAGE.md` (route/state ledger; exact artifact name to choose) | documentation / ledger | transform | `accrue_admin/lib/accrue_admin/router.ex` + `.planning/milestones/v1.64-phases/240-shared-system-and-real-billing-exemplar/240-COVERAGE.md` | exact source + role-match artifact |
| `.planning/phases/245-rendered-baseline-and-realistic-preview/captures/.../manifest.json` and capture owner | test / browser evidence | request-response, file-I/O | `examples/accrue_host/e2e/phase237-admin-billing.spec.js` | exact |
| `examples/accrue_host/priv/repo/seeds/phase245_ordinary_preview.exs` (or equivalent isolated ordinary seed owner) | utility / seed | transform, CRUD | `examples/accrue_host/priv/repo/seeds/showcase.exs` | role-match |
| `examples/accrue_host/README.md` | documentation / runbook | request-response, file-I/O | `examples/accrue_host/e2e/phase243-preview-preservation.spec.js` and current README preview workflow | role-match |
| `examples/accrue_host/priv/repo/seeds.exs` (only if a scoped entrypoint is required) | config / seed composition | transform, CRUD | same file | exact |

## Pattern Assignments

### Route/state ledger (phase artifact)

**Analogs:** `accrue_admin/lib/accrue_admin/router.ex` lines 43-103; tracked historical ledger `.planning/milestones/v1.64-phases/240-shared-system-and-real-billing-exemplar/240-COVERAGE.md`.

Build the route list from the package's mounted routes and reconcile it with the actual host mount. The package router defines asset and redirect routes separately from the `live_session`, lists production LiveViews at lines 68-95, and gates developer-only routes at 97-103. The host mounts `/admin` with SQL-sandbox test hooks at `examples/accrue_host/lib/accrue_host_web/router.ex:140-165`. Preserve distinctions among package route, actual `/admin` mount, dev-only route, redirect, and Portal `/billing` route. For each ledger row record route/state, primary rendered anchor, scenario, inspected/unavailable/not-applicable status and reason; include material overlays, disclosures, tabs, and scope/role variants only where they change appearance or actions. Treat historical route counts as reconciliation input, never current inspection proof.

**Concrete route excerpt** (`accrue_admin/lib/accrue_admin/router.ex:68-95`):

```elixir
live_session :accrue_admin,
  root_layout: {AccrueAdmin.Layouts, :root},
  on_mount: on_mount,
  session: {AccrueAdmin.Router, :__session__, [session_keys, mount_path]} do
  live("/", AccrueAdmin.Live.DashboardLive, :index)
  live("/customers", AccrueAdmin.Live.CustomersLive, :index)
  live("/customers/:id", AccrueAdmin.Live.CustomerLive, :show)
  live("/subscriptions", AccrueAdmin.Live.SubscriptionsLive, :index)
  # ...remaining mounted production routes and analytics scope...
end
```

### Capture owner and manifest

**Analog:** `examples/accrue_host/e2e/phase237-admin-billing.spec.js` lines 1-37, 64-85, 180-215, 291-310, 600-673. It is 674 lines, so these are the non-overlapping relevant sections already inspected.

Reuse the existing Playwright harness imports and fixture/login helpers at lines 1-8; bind a capture run to source files and their digests (`sourcePaths`, `sourceSha`) and to the served CSS/JS assets (manifest assembly at 606-620). The screenshot path stores actual screenshot bytes and route/viewport/theme, then hashes those bytes in the manifest (lines 291-300 and 653-673). Record scenario/fixture, exact URL/state, CSS viewport, effective theme and how theme was overridden, revision, served asset URL/identity, browser/runtime, command and capture hash. Label emulated theme as emulation. Use bounded representative combinations and explicit omissions; do not claim the existing phase237 captures provide complete Phase245 route coverage.

**Imports and existing fixture pattern** (`phase237-admin-billing.spec.js:1-8`):

```js
// @ts-check
const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const { execFileSync } = require("node:child_process");
const { devices } = require("@playwright/test");
const { test, expect } = require("./support/test.js");
const { readFixture, login, waitForLiveView } = require("./support/fixture.js");
```

**Capture and provenance excerpt** (`phase237-admin-billing.spec.js:298-300, 606-620, 653-673`):

```js
const collectionShot = await page.screenshot({ fullPage: true });
screenshots["invoice-collection.png"] = {
  bytes: collectionShot, route: page.url(),
  viewport: { width: 320, height: 800 }, theme: "light"
};
await testInfo.attach("phase237-invoice-collection.png", {
  body: collectionShot, contentType: "image/png"
});
// Manifest binds source_head/source_sha, sources, assets, browser_environment,
// theme_provenance, and per-image route, viewport, theme, sha256, and byte count.
for (const [name, shot] of Object.entries(screenshots)) {
  fs.writeFileSync(path.join(captureDir, name), shot.bytes);
}
fs.writeFileSync(path.join(captureDir, "manifest.json"),
  `${JSON.stringify(manifest, null, 2)}\n`);
```

The analog has assertions and interaction probes, but screenshot or detector success alone is not visual/behavioral acceptance. Findings belong in one source-linked ledger tied to route/state and capture evidence. Do not trigger state-changing actions during baseline capture.

### Isolated ordinary seed owner

**Analog:** `examples/accrue_host/priv/repo/seeds/showcase.exs` lines 1-108 and `examples/accrue_host/priv/repo/seeds.exs` lines 100-110.

The showcase seed demonstrates deterministic, idempotent Fake data: one time anchor, derived dates, helpers that resolve existing organization/customer/subscription records, and get-or-insert keyed by stable Fake processor IDs. Preserve those properties in any ordinary-only seed path, and cross-check relationships, money, dates, histories, and raw/normalized evidence. Retain valid unknown/unavailable facts. The current aggregator runs `hero_accounts`, `background_data`, `showcase`, `edge_states`, and `phase191_flow_states`; changing the Compose instance alone does not prevent adversarial phase fixture rows. Create a distinct explicit ordinary-only invocation on the isolated instance. Do not change/reset/reseed the Phase 243 instance.

**Imports, deterministic time and relationship lookup** (`showcase.exs:14-29, 35-67`):

```elixir
alias AccrueHost.Repo
alias Accrue.Billing.{Charge, Coupon, Customer, Invoice, PromotionCode, Refund, Subscription}
import Ecto.Query

now = Accrue.Clock.utc_now()
days_ago = fn days -> DateTime.add(now, -days * 86_400, :second) end

customer_for_slug = fn slug ->
  case Repo.get_by(AccrueHost.Accounts.Organization, slug: slug) do
    nil -> nil
    org -> Repo.one(from(c in Customer,
      where: c.owner_type == "Organization" and c.owner_id == ^to_string(org.id),
      limit: 1))
  end
end
```

**Idempotent record pattern** (`showcase.exs:69-83`):

```elixir
upsert = fn schema, changeset_fun, processor_id, attrs ->
  case Repo.get_by(schema, processor: "fake", processor_id: processor_id) do
    nil ->
      attrs = attrs |> Map.put(:processor, "fake") |> Map.put(:processor_id, processor_id)
      struct(schema) |> changeset_fun.(attrs) |> Repo.insert!()
    existing -> existing
  end
end
```

Avoid broadening the default seed aggregator to include test/stress owners in the ordinary dataset. `seeds.exs:100-110` explicitly documents why `Code.eval_file` is used and lists the composed sub-seeds; if it is modified, keep test semantics and an explicit ordinary-only route clear. Existing `bin/dev-entrypoint.sh:65-76` supports `ACCRUE_HOST_SKIP_SEEDS=1`; use that on warm recovery and avoid implicit reseed-on-start.

### Host preview runbook / preservation

**Analogs:** `examples/accrue_host/e2e/phase243-preview-preservation.spec.js` lines 9-23, 25-72, 74-114; `examples/accrue_host/Makefile` lines 3-18, 38-42, 67-72; `scripts/ci/accrue_host_preview_custody.sh` lines 119-178.

Document the isolated Compose `INSTANCE`, explicit ordinary seed operation, and warm-start command. The Makefile derives `COMPOSE_PROJECT_NAME` and host name from DNS-safe `INSTANCE`; the entrypoint skips seeds with `ACCRUE_HOST_SKIP_SEEDS=1`. Phase243's preservation spec captures an authoritative snapshot, warms the selected existing preview with seeds skipped, asserts preservation, and keeps credentials out of test output. The custody script verifies the preview and proof targets differ across database, Compose, volume, port, process, and build identity. Adapt this discipline to protect Phase 243 before any shared-tooling write. Never use `make reset` against the current feedback instance.

**Warm recovery excerpt** (`phase243-preview-preservation.spec.js:25-32, 67-71`):

```js
const warm = spawn("make", ["up", `INSTANCE=${previewProject}`], {
  cwd: hostRoot,
  env: { ...process.env, ACCRUE_HOST_SKIP_SEEDS: "1",
    ACCRUE_HOST: `${previewProject}.localhost`, COMPOSE_PROJECT_NAME: previewProject },
  detached: true,
  stdio: ["ignore", logFd, logFd]
});
// After readiness:
expect(launchOutput).toContain("seeds skipped (ACCRUE_HOST_SKIP_SEEDS=1)");
capturePreviewSnapshot("assert-preserved", snapshotPath);
```

## Shared Patterns

### Evidence provenance
**Sources:** `examples/accrue_host/e2e/phase237-admin-billing.spec.js:180-193,606-673`. Bind generated images and finding claims to the same run's revision, source list/digests, served assets, browser context, fixture, viewport, and theme override. Distinguish source assets from HTTP-served assets and rendered browser output.

### Preview isolation and no implicit reset
**Sources:** `examples/accrue_host/Makefile:3-18,38-42`; `examples/accrue_host/bin/dev-entrypoint.sh:65-76`; `examples/accrue_host/e2e/phase243-preview-preservation.spec.js:25-32,67-71`; `scripts/ci/accrue_host_preview_custody.sh:119-178`. Use a new instance identity, skip seeds on warm recovery, and preserve/snapshot the existing feedback database. No credentials, session tokens, PII, or live processor credentials in artifacts.

### Ordinary data truth and idempotency
**Sources:** `examples/accrue_host/priv/repo/seeds/showcase.exs:7-12,28-29,35-83`; `examples/accrue_host/priv/repo/seeds.exs:100-110`. Keep deterministic identifiers and times, idempotent inserts, linked records, and unknown/unavailable states. Exclude stress narratives from ordinary preview while retaining them under their current fixture owners.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| Phase245 current route/state and source-linked findings ledger (exact path TBD) | documentation / ledger | transform | Existing historical coverage ledgers inform the shape, but no tracked analog was confirmed in this mapping for a current exhaustive route/state plus finding-disposition ledger. |
| Phase245 ordinary-only seed command/entrypoint | utility / seed | CRUD | Showcase seed is a strong data-pattern analog; there is no existing ordinary-only seed owner because the default aggregator includes the stress seed. |

## Metadata

**Analog search scope:** package router, host router/README/Makefile/entrypoint, existing phase237 capture owner, phase243 preservation owner/custody, showcase/default seeds.  
**Files scanned:** 9 tracked source/tooling analogs.  
**Pattern extraction date:** 2026-10-11.
