# Phase 31 — Technical research

**Phase:** 31 — Advisory integration alignment  
**Question:** What do we need to know to plan README ↔ CI parity, npm shortcuts, Copy SSOT, and dual Playwright posture?

## Summary

| Area | Finding | Planning implication |
|------|---------|----------------------|
| README contract | `verify_verify01_readme_contract.sh` anchors a11y spec + adoption matrix + `sk_live` negation; **does not** yet anchor mobile spec path or the `### Mounted admin — mobile shell` heading | Add **Tier A** `require_substring` for stable mobile anchors (`31-CONTEXT.md` D-01) |
| Tier B (optional) | Small bash loop: paths under `e2e/verify01-*.spec.js` mentioned in README must exist | Keeps rename drift from false-green without codegen |
| npm | `e2e:a11y` pattern is `env -u NO_COLOR playwright test <single-spec>` | Mirror as `e2e:mobile` → `e2e/verify01-admin-mobile.spec.js` |
| Copy / step-up | `StepUpAuthModal` uses `Copy.step_up_submit_label/0` but **eyebrow, title, Cancel** remain literals | Add `Copy` (or `Locked` for verbatim-stable titles) per D-03; update component only |
| Admin Playwright | `phase7-uat.spec.js` asserts **Locked** replay strings and **Step-up required** same way host `phase13-canonical-demo.spec.js` does | Prefer **data-role / dialog structure** for admin lane where host already proves literals; add maintainer note in workflow + README Browser UAT |
| CI | `accrue_admin_browser.yml` is path-filtered package smoke | Document **host VERIFY-01 is merge-blocking law**; no new deps between packages |

## File-level notes

### `scripts/ci/verify_verify01_readme_contract.sh`

- `require_substring` is the established extension point (lines 13–30).
- `awk` block (lines 32–47) is the **only** negative test — keep narrow per D-01.

### `examples/accrue_host/package.json`

- Scripts block is flat JSON; order `e2e`, `e2e:a11y`, then **`e2e:mobile`** keeps discoverability.

### `AccrueAdmin.Copy` / `Copy.Locked`

- `Copy.Locked.single_replay_confirmation/0` et al. already back host + phase13 expectations.
- Step-up strings are **operator trust** surface — belong in `Copy` or `Locked` per `27-CONTEXT.md` tier rules.

### `accrue_admin/e2e/phase7-uat.spec.js`

- Three tests; webhook + refund flows use longest literal overlaps with host VERIFY-01.
- Playwright already exposes `data-role` hooks from LiveViews (`confirm-replay`, `bulk-replay-confirm`, `confirm-panel`).

### `accrue_admin/README.md`

- “Browser UAT” exists but does not yet say host owns VERIFY-01 — one sentence closes D-04 documentation coherence.

## Risks / non-goals

- **No** `accrue_admin` → `examples/accrue_host` source imports (explicit boundary).
- **No** gettext / workspace packages in this phase (`31-CONTEXT.md` deferred).

## Validation Architecture

This phase validates **documentation + script contracts** and **admin UI copy**, not new billing algorithms.

| Dimension | Signal | Automated hook |
|-----------|--------|----------------|
| 1 — Contract | README substrings match CI expectations | `bash scripts/ci/verify_verify01_readme_contract.sh` (exit 0) |
| 2 — Mobile shortcut | `e2e:mobile` runs the canonical mobile spec | `cd examples/accrue_host && npm pack --dry-run 2>/dev/null; node -e "require('fs').readFileSync('package.json','utf8').includes('e2e:mobile')"` + optional `npx playwright test e2e/verify01-admin-mobile.spec.js --project=chromium-mobile` when env supports |
| 3 — Copy compile | Modal uses Copy functions | `mix compile --warnings-as-errors` in `accrue_admin` |
| 4 — Admin E2E smoke | Fixture server suite still passes | `cd accrue_admin && npm run e2e` |
| 5 — Regression | Host wide gate unchanged | Document executor runs `mix verify.full` / host `npm run e2e` per existing docs |

**Sampling rate (execution):**

- After **every** task touching `README.md` or the contract script: run `verify_verify01_readme_contract.sh`.
- After **wave 1** (host files): `cd examples/accrue_host && npm run e2e:mobile` (or full `npm run e2e` if mobile-only is flaky locally).
- After **wave 2** (admin): `cd accrue_admin && npm run e2e`.

**Wave 0:** Not required — existing Mix + Playwright + bash infrastructure covers the phase.

## RESEARCH COMPLETE
