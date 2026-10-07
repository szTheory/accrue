# Phase 233 current served Admin and Portal baseline

**Captured:** 2026-10-07 14:36–14:37 America/New_York (18:36–18:37 UTC)  
**Source SHA:** `03ddfedf8b9935e24ffce695ba70a044852ce70e`  
**Harness:** canonical `examples/accrue_host` test server, fixture seeded by `scripts/ci/accrue_host_seed_e2e.exs`, Chromium desktop project  
**Capture test:** `examples/accrue_host/e2e/phase233-baseline.spec.js` — 1 discovered test, passed; serves both package mounts and checks response bytes.

This is a rendering observation of the host's current compiled packages, not an accessibility certification or a claim that every route/state was exercised. The fixture is deterministic demo billing data. Images were inspected before retention; no payment credentials, card fields, or personal customer data are visible.

## Captures

| Artifact | Served route and fixture/state | Viewport and theme | Observed result |
|---|---|---|---|
| [`captures/admin-overview.png`](./captures/admin-overview.png) | `/admin?org=accrue-e2e-alpha`; seeded `Admin E2E Alpha Org`; operator dashboard with open invoice and failed webhook indicators | 1280 × 900 browser viewport; Admin system theme (rendered light); full-page image 1280 × 1609 | The dense operator shell exposes navigation, customer lookup, priority exceptions, and task links. Statuses include text and glyph cues as well as color. At-a-glance labels wrap tightly in two metric cards, a useful Phase 234/237 review point. |
| [`captures/portal-home.png`](./captures/portal-home.png) | `/billing`; seeded normal host user; home with zero subscriptions/invoices and two payment methods | 390 × 844 browser viewport; dark system preference emulated; full-page image 390 × 1168 | The host wordmark and customer billing shell remain distinct from Admin. Summary cards stack without horizontal overflow and the no-subscription state has text. Billed-entity identity is not yet shown; account context is a later Portal contract consumer. |
| [`captures/portal-state.png`](./captures/portal-state.png) | `/billing/subscriptions`; same seeded user; no-active-subscriptions state | 390 × 844 browser viewport; dark system preference emulated; full-page image 390 × 844 | Breadcrumb, page title, and explanatory empty-state copy are visible; the content remains readable at the narrow viewport. |

## Asset provenance

The Admin package was built with its declared `mix accrue_admin.assets.build` task before starting the canonical host. The host's test compilation loaded the current Portal/core CSS and JS into `AccruePortal.Assets`. For every row below the browser test extracted the URL actually referenced by the page, fetched that URL from the host, and asserted the served body equals the current checked-out source bytes and that its MD5 equals the URL suffix.

| Consumer | Served mount path | Source file | SHA-256 (source) | Served URL MD5 |
|---|---|---|---|---|
| Admin CSS | `/admin/assets/css-78ef060144d92bc6a3b5c54d80c2e7f8` | `accrue_admin/priv/static/accrue_admin.css` | `6c3d6d1484788e38d99232e93d1db1e312edb6ea6b5609c7153c90c190edea3b` | `78ef060144d92bc6a3b5c54d80c2e7f8` |
| Admin JS | `/admin/assets/js-e4db3e8e36975d6d2b08a3dd13e67de7` | `accrue_admin/priv/static/accrue_admin.js` | `f1d1fb4225deeb049981f8ebec0031086993e8df7230b17740e938ab98dc22f9` | `e4db3e8e36975d6d2b08a3dd13e67de7` |
| Portal brand CSS | `/billing/assets/brand-7a8ba12e41a8646d3f0c8820aea13418` | `accrue/priv/static/brand.css` | `82293fca63992d35b3ac86289a18a8a73f438fbdd196c90c195d0226fc14e6ce` | `7a8ba12e41a8646d3f0c8820aea13418` |
| Portal CSS | `/billing/assets/css-ca3bd6833456875a9f1588353bda05b8` | `accrue_portal/priv/static/accrue_portal.css` | `33a883a2d771eb3725431d62483a21bccad09bc9f49920c11645054c932a3ae2` | `ca3bd6833456875a9f1588353bda05b8` |
| Portal JS | `/billing/assets/js-cb3ae485bb61804ab4decbb4de88bb48` | `accrue_portal/priv/static/accrue_portal.js` | `f032bfad5b54e0ce01f1277f9455ab72abbb4c3b13cfb1c4ce861acaac3f4174` | `cb3ae485bb61804ab4decbb4de88bb48` |

## Verification

```text
cd accrue_admin && mix accrue_admin.assets.build                         PASS
cd examples/accrue_host && npm run e2e -- e2e/phase233-baseline.spec.js --workers=1  PASS (1 test)
```

The host logged PostgreSQL `too_many_connections` warnings from its Oban notifier during startup; the seeded host served the tested pages and the single browser test passed. Those startup warnings are not a claim about the rendered package assets. Earlier July screenshots and pass counts remain historical and are not used as current evidence.
