# Phase 31 — Pattern map

Analogs and excerpts for executors.

## README ↔ CI contract

| New / touched | Analog | Pattern |
|---------------|--------|---------|
| `verify_verify01_readme_contract.sh` anchors | Lines 22–30 existing `require_substring` calls | Copy-paste one new `require_substring` per anchor; keep `set -euo pipefail` |

## npm `e2e:*` scripts

| Target | Analog | Excerpt |
|--------|--------|---------|
| `e2e:mobile` | `package.json` `"e2e:a11y"` | `"e2e:a11y": "env -u NO_COLOR playwright test e2e/verify01-admin-a11y.spec.js"` |

## Copy in HEEx

| Target | Analog | Pattern |
|--------|--------|---------|
| Step-up modal strings | `charge_live.ex` using `Copy.charge_*` | `<%= Copy.some_function() %>` — keep HTML attrs static |

## Playwright dedupe

| Target | Analog | Pattern |
|--------|--------|---------|
| Avoid duplicate literal vs host | Use `locator('[data-role=…]')` + visibility | Already used for `bulk-replay-confirm`, `confirm-panel` |

## PATTERN MAPPING COMPLETE
