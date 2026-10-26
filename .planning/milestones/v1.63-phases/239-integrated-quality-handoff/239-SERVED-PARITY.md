# Phase 239 Served Resource Parity

Evidence below separates source/build contracts, mounted responses, local test runs, and checked-in CI definitions. No remote GitHub Actions run was observed.

## Asset, font, and mount boundaries

| Package/resource | Source/build ownership | Served contract and mount | Local evidence | Recurring gate |
|---|---|---|---|---|
| Admin brand CSS | `accrue/priv/static/brand.css`; Admin uses `AccrueAdmin.Assets` | `/billing/assets/brand-<md5>`; exact CSS response is already exercised by `assets_test.exs` | `cd accrue_admin && mix test test/accrue_admin/assets_test.exs` — 4 tests, 0 failures | `release-gate` → `Accrue admin test` (`mix test --warnings-as-errors`) |
| Admin CSS/JS | `accrue_admin/priv/static/accrue_admin.css` and `.js`; reproducible via `mix accrue_admin.assets.build` | Hashed `/billing/assets/css-*` and `/billing/assets/js-*`; response bytes equal the package files, with content type checked | Same Admin focused suite — 4 tests, 0 failures | `release-gate` → `Accrue admin test`; `admin-drift-docs` also runs the asset build and checks generated CSS/JS have no diff |
| Admin Geist Sans/Mono fonts | `accrue_admin/priv/static/fonts/*.woff2`; Admin router serves self-hosted files | Fixed `/billing/assets/geist-{sans,mono}-vf.woff2`; new test checks status, cache header, `font/woff2; charset=utf-8`, and exact file bytes | Same Admin focused suite — 4 tests, 0 failures | `release-gate` → `Accrue admin test` |
| Portal brand CSS, package CSS/JS, Phoenix JS, LiveView JS | Brand source in `accrue/priv/static`; package bundles and vendored runtime files are the paths loaded by `AccruePortal.Assets` | New `csp_plug_test.exs` contract calls the mounted `/billing/assets/...` router paths and compares each body with the exact application file; checks status, MIME, and immutable caching | `cd accrue_portal && mix test test/accrue_portal/csp_plug_test.exs test/accrue_portal/live/checkout_live_test.exs` — 19 tests, 0 failures | `release-gate` → `Accrue portal test` (`mix test --warnings-as-errors`) |

The HTTP response tests establish the host-visible package route and exact served bytes. They do not assert that a browser rasterized CSS or loaded a font face; browser rendering belongs to the existing Playwright host lane.

## Generated copy export parity

`accrue_admin/test/accrue_admin/copy_test.exs` now invokes the existing `mix accrue_admin.export_copy_strings --out PATH` task with a unique file under the OS temporary directory, compares the complete generated JSON bytes with `examples/accrue_host/e2e/generated/copy_strings.json`, and registers cleanup before generation so ExUnit removes the output after both passing and failing assertions. The checked-in fixture is read-only in this contract.

- Local result: `cd accrue_admin && mix test test/accrue_admin/copy_test.exs --warnings-as-errors` — 14 tests, 0 failures.
- Recurring gate: `.github/workflows/ci.yml` `release-gate` → `Accrue admin test` runs `cd accrue_admin && mix test --warnings-as-errors`, so the full-export parity test runs in each required Admin compatibility cell.
- Remote CI remains unobserved.

## Independent security contracts

| Control | Existing contract | Independence and local result | Recurring gate |
|---|---|---|---|
| Portal CSP | `csp_plug_test.exs` asserts nonce creation/threading plus the Braintree origin allowlist | Kept separate from asset content/hash assertions; included in the 19-test Portal focused run (0 failures) | `release-gate` → `Accrue portal test` |
| External checkout SRI | `checkout_live_test.exs` checks pinned SHA-384 integrity values and `crossorigin="anonymous"` on each Braintree script | SRI is a markup contract, not derived from package asset hashes or CSP; included in the same 19-test Portal focused run (0 failures) | `release-gate` → `Accrue portal test` |

## Local and remote evidence

- Admin mounted CSS/JS and font responses: local focused test result above.
- Portal mounted static responses, CSP nonce/origins, and checkout SRI: local focused test result above.
- Admin full copy export equality: recorded with Task 2 below.
- `.github/workflows/ci.yml` defines `release-gate` as a required compatibility matrix for required cells, with named Admin and Portal test steps. This is source evidence for recurring CI coverage, not a remote CI result.
- No remote CI run was observed during this plan.
