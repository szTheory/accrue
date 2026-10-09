# Phase 239: Integrated Quality & Handoff - Pattern Map

**Mapped:** 2026-10-09  
**Files analyzed:** 4 likely phase outputs/touch points  
**Analogs found:** 4 / 4

Research leaves the exact gap-driven test files to planning. The concrete planned artifacts are a refreshed route/evidence disposition ledger, a small mounted browser smoke/current-render set only where the ledger finds a seam gap, and a stable preview/handoff note. Existing asset, CSP/SRI, component/doc, and per-slice tests should be extended in place only when reconciliation finds a missing assertion.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/phases/239-integrated-quality-handoff/239-COVERAGE.md` (or equivalent route/evidence ledger) | utility / evidence document | transform | `.planning/phases/233-shared-direction-portal-contract/233-INVENTORY.md` | role-match |
| `examples/accrue_host/e2e/phase239-integrated-quality.spec.js` (conditional, name subject to plan) | test | request-response / event-driven | `examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js` | exact |
| `examples/accrue_host/e2e/support/overflow.js` (extend only if missing helper) | utility | transform | same file | exact |
| `examples/accrue_host/README.md` or `accrue_admin/guides/local_demo.md` (handoff clarification only if needed) | config / documentation | request-response | `examples/accrue_host/README.md` | role-match |

## Pattern Assignments

### Route and evidence disposition ledger

**Analog:** `.planning/phases/233-shared-direction-portal-contract/233-INVENTORY.md` (tracked). Its introduction distinguishes source inventory from served-render evidence (lines 1-7), and its route-family tables connect routes, state owners, asset owners, and scope (lines 11-16, 30-48). The phase 239 ledger should update route ownership from current routers and add one row per unique interaction with the existing test/spec, verification layer, freshness, and disposition. Preserve the explicit distinction between source claims and current rendered evidence; the old SHA and screenshots are historical seeds, not current proof (lines 61-65).

### `examples/accrue_host/e2e/phase239-integrated-quality.spec.js` (conditional browser gap coverage)

**Analog:** `examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js` (tracked, same host consumer and mounted browser flow).

**Imports and helpers** (lines 1-29):

```javascript
const { test, expect } = require("./support/test.js");
const { readFixture, login, waitForLiveView } = require("./support/fixture.js");
const AxeBuilder = require("@axe-core/playwright").default;

async function openAdmin(page, fixture, sandboxId, path) {
  await login(page, fixture, fixture.admin_email, sandboxId);
  await page.goto(`/app/billing`);
  await waitForLiveView(page);
  await page.locator(`button[data-organization-slug="${fixture.admin_org_alpha_slug}"]`).click();
  await waitForLiveView(page);
  await page.goto(path, { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);
}
```

Reuse the shared host fixture/session and login helpers rather than booting a separate test app. Current representative browser checks use semantic roles, explicit focus assertions, and axe where rendered accessibility matters (for example lines 52-59, 79-108). At 320 CSS px, reuse the shared overflow helper instead of a second document-width implementation. Keep assertions focused on a ledger-identified integration seam; screenshots are attachments supporting inspection, not substitutes for assertions (line 134).

**Shared Playwright fixture pattern:** `examples/accrue_host/e2e/support/test.js` (tracked), lines 1-39, extends Playwright with the host SQL sandbox and adds the sandbox header to browser requests. Import `test`/`expect` from this module so browser journeys retain fixture isolation.

### `examples/accrue_host/e2e/support/overflow.js` (conditional utility extension)

**Analog:** same file (tracked), lines 10-40 and 46-56. It scrolls the target into view, checks its bounding box is inside the viewport with a 0.5px subpixel tolerance, and checks document width against `window.innerWidth` with a 1px tolerance. Use the existing `expectNoHorizontalOverflow(page, label)` and `expectVisibleInViewport(locator, label)` exports for 320px checks; only add a helper if the requested behavior cannot be expressed with these contracts.

```javascript
async function expectNoHorizontalOverflow(page, label) {
  const overflow = await page.evaluate(() => ({
    documentWidth: document.documentElement.scrollWidth,
    viewportWidth: window.innerWidth
  }));

  expect(
    overflow.documentWidth,
    `${label} should not hide text or actions behind horizontal overflow`
  ).toBeLessThanOrEqual(overflow.viewportWidth + 1);
}
```

### Preview and handoff documentation

**Analog:** `examples/accrue_host/README.md` (tracked), lines 8-25 and 44-63. It gives the stable preview URL, startup commands, operator/customer distinction, fallback URL, demo identities, and Fake-backed billing boundary. Follow this concise task-oriented structure for a Phase 239 handoff. If clarifying the safety boundary, say which path is the read-only evaluation preview and keep proof/reset instructions separate; `mix verify.full` invokes browser proof against a test DB that is dropped and reseeded, as documented in RESEARCH.md. Avoid copying credentials into new artifacts when a link to the existing README suffices.

### Existing contracts to extend only if the ledger finds a gap

- Admin asset response/hash: `accrue_admin/test/accrue_admin/assets_test.exs` (tracked), lines 6-43 checks hashes against committed bundle bodies and verifies mounted CSS/JS response status, content type, cache policy, and exact body.
- Portal CSP nonce/allowlist: `accrue_portal/test/accrue_portal/csp_plug_test.exs` (tracked), lines 4-19 asserts a nonce is generated/threaded and provider origins appear in the policy. External Braintree SRI remains a separate checkout markup contract; do not conflate the two.
- Admin component/example parity: `accrue_admin/test/accrue_admin/dev/component_registry_test.exs` and `storybook_coverage_test.exs` are the research-identified contracts; use these instead of introducing another hand-maintained component inventory.

## Shared Patterns

### Evidence tiering

Use ExUnit for deterministic state and authorization branches, LiveView tests for mount/event/rendered server HTML, and Playwright for actual focus, browser layout, theme handoff, network responses, and current mounted render behavior. This is encoded by the focused browser style above and the asset response test. Let the ledger link to prior phase validation artifacts rather than duplicating valid evidence.

### Mounted consumer and evidence freshness

The canonical `accrue_host` is the integrated package consumer. Start from its sandbox-backed Playwright test fixture and current route journeys. Tie fresh render evidence to the inspected source revision; the Phase 233 inventory explicitly labels itself source-only and historical (lines 3-7, 61-65).

### Asset boundaries

Admin CSS/JS are checked as exact mounted response bodies in `assets_test.exs`; Portal CSP is checked independently in `csp_plug_test.exs`; external script SRI and font fetches are distinct contracts. Add only the missing boundary identified by inventory, and generate copy exports to temporary output for comparison if the task supports it, protecting tracked authored exports.

### Preview versus proof

Use the existing stable Fake-backed host demo described in `examples/accrue_host/README.md`. Keep feedback evaluation away from test verification/reset commands and use the disposable test DB for proof. Human handoff should identify only subjective or external-provider judgment that deterministic tests cannot establish, with the specific reason.

## No Analog Found

None for the likely files above. The integrated disposition ledger is a new phase artifact, but Phase 233 provides the closest inventory/provenance structure.

## Metadata

**Analog search scope:** `.planning/phases/233-shared-direction-portal-contract/`, `.planning/phases/238-admin-events-webhooks-remaining-billing-surfaces/`, `examples/accrue_host/e2e/`, `examples/accrue_host/`, `accrue_admin/test/accrue_admin/`, `accrue_portal/test/accrue_portal/`.  
**Tracked-source verification:** all named code/document analogs checked with `git ls-files`; all are tracked.  
**Pattern extraction date:** 2026-10-09
