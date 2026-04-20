# Phase 29 — Technical Research

**Question:** What do we need to know to plan mobile parity + CI well?

## RESEARCH COMPLETE

### Playwright project semantics (locked in 21-CONTEXT + 29-CONTEXT)

- **`chromium-mobile`**: `devices["Pixel 5"]` — only valid lane for `scrollWidth` vs `innerWidth` overflow and real narrow-shell behavior (`playwright.config.js`).
- **`chromium-mobile-tagged`**: Desktop Chrome viewport + `grep: /@mobile/` — tag discovery only; must not be the sole proof for MOB-01/MOB-02 layout.
- **Per-project skips**: Mirror `verify01-admin-a11y.spec.js` (desktop-only) with the **inverse** — substantive MOB tests skip unless `testInfo.project.name === "chromium-mobile"`.

### Existing helpers

- `expectNoHorizontalOverflow` and `expectVisibleInViewport` live **inline** in `e2e/phase13-canonical-demo.spec.js` (lines ~16–47). CONTEXT calls for extraction to `e2e/support/` when reused by MOB specs to avoid drift.

### Fixture spine

- `readFixture`, `login`, `waitForLiveView`, `reseedFixture` from `e2e/support/fixture.js`.
- Fixture JSON includes `admin_denial_customer_id` and `admin_org_alpha_slug` — sufficient for a **deterministic** customer detail URL in the admin org: `/billing/customers/${admin_denial_customer_id}?org=${admin_org_alpha_slug}` (denial spec uses wrong org for negative case; positive path is alpha org).
- CI handoff: `ACCRUE_HOST_SKIP_PLAYWRIGHT_GLOBAL_SEED=1` — prefer **no** `reseedFixture()` in new MOB spec unless flakes force a documented exception.

### CI entrypoints

- `scripts/ci/accrue_host_verify_browser.sh` + `npm run e2e` / `mix verify.full` remain canonical; no new scheduled-only mobile gate required for v1.6.

### Host README anchor

- VERIFY-01 narrative begins `## VERIFY-01 (Phase 21)` in `examples/accrue_host/README.md` ~line 83 — add **“Mounted admin — mobile shell”** subsection nearby per D-02.

---

## Validation Architecture

**Automated proof stack:** Playwright (same install as existing host e2e).

| Dimension | Approach |
|-----------|----------|
| **Unit / integration** | Not primary for MOB; host `mix test` unchanged. |
**E2E** | New `@mobile` spec file; assertions gated to `chromium-mobile`. |
**CI** | Existing `npx playwright test` runs all projects; skipped tests add negligible cost on desktop/tagged. |

**Sampling during execution:**

- After tasks touching JS/specs: `cd examples/accrue_host && npx playwright test e2e/verify01-admin-mobile.spec.js --project=chromium-mobile` (or full `npm run e2e` before merge).
- Full gate: repo-root `bash scripts/ci/accrue_host_verify_browser.sh` or host `mix verify.full` per project docs.

**Manual-only:** Visual confirmation of shell drawer animation (optional); automated path covers links visible + Escape per CONTEXT.
