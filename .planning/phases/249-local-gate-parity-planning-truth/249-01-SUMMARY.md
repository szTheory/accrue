---
phase: 249-local-gate-parity-planning-truth
plan: "01"
subsystem: ci-gates
status: complete
completed: 2026-10-24
requirements-completed: [GREEN-02, GREEN-03, GREEN-05]
tags: [compile-warning, formatter, css-guards, accrue_admin]
key-files:
  modified:
    - accrue_admin/lib/accrue_admin/live/subscription_live.ex
    - accrue_admin/assets/css/app.css
    - accrue_admin/priv/static/accrue_admin.css
    - accrue/test/accrue/docs/package_docs_verifier_test.exs
    - accrue_admin/test/accrue_admin/live/connect_accounts_live_test.exs
    - accrue_admin/test/support/e2e_fixtures.ex
    - accrue_admin/test/accrue_admin/components/theme_picker_test.exs
    - accrue_admin/test/accrue_admin/e2e_fixtures_test.exs
commits: 3
plan_head_before: 275e73ae
plan_head_after: 1a755b2d
actuals:
  tokens: 30000
  tasks: 3
  commits: 3
coverage:
  - id: C1
    description: Admin forced compile is warning-free
    requirement: GREEN-02
    verification:
      - {kind: command, ref: "cd accrue_admin && MIX_ENV=test mix compile --force --warnings-as-errors", status: pass}
    human_judgment: false
  - id: C2
    description: All four Mix projects pass format check
    requirement: GREEN-05
    verification:
      - {kind: command, ref: "mix format --check-formatted in accrue, accrue_admin, accrue_portal, examples/accrue_host", status: pass}
    human_judgment: false
  - id: C3
    description: Package docs verifier (DSY-01, FND-02, FND-01, RES-04 CSS guards) passes with guard script unchanged
    requirement: GREEN-03
    verification:
      - {kind: command, ref: "bash scripts/ci/verify_package_docs.sh", status: pass}
    human_judgment: false
  - id: C4
    description: Accrue suite green on random seeds
    requirement: GREEN-05
    verification:
      - {kind: command, ref: "cd accrue && mix test --warnings-as-errors (seeds 576061, 807522, 956638)", status: pass}
    human_judgment: false
---

# Phase 249 Plan 01: Admin source reds Summary

Cleared the unused-binding compile warning, formatter drift, and the cascade of CSS package-docs guard reds, all at source with no gate script changes.

## What was done

- **R8:** Positive control: forced compile failed with `variable "subscription" is unused` at subscription_live.ex:1286. Renamed to `_subscription`; compile exits 0.
- **R11:** Positive control named 5 files (the 3 expected plus `theme_picker_test.exs` and `e2e_fixtures_test.exs` in accrue_admin). Ran `mix format`; all four projects pass `--check-formatted`.
- **R4 and hidden follow-on guards:** Annotated 5 bare breakpoint `@media` lines (`--ax-bp-sm ↓` x2, `content ↓`, `content ↑`, `1000 ↑`) and added two registry lines. Negative control (scratch copy with one annotation removed) reported the bare breakpoint line.
- The verifier script exits at its first failure, so fixing DSY-01 exposed three further pre-existing reds that research had not seen. Each was fixed in app.css:
  - FND-02: `z-index: 1` on `.ax-timeline-marker` was outside the 25-line `isolation: isolate` window; added `isolation: isolate` to the parent `.ax-timeline-item-with-icon` row (real CSS, same visual).
  - FND-01: 8 raw type declarations annotated with the established `ax-type-exception` comment (1 inline, 7 more).
  - RES-04: 4 `text-overflow: ellipsis` blocks lacked literal `min-width: 0` (three had the logical `min-inline-size: 0`); added `min-width: 0`.
- The FND-02 `isolation` addition changed the compiled bundle by one line, so the rebuilt `priv/static/accrue_admin.css` was committed. The comment-only changes were stripped from the bundle.

## PdfTest flake measurement

10 random-seed PdfTest runs (19 tests, 0 failures each): 500900, 795277, 90754, 320327, 517134, 777561, 16876, 249078, 392375, 508779. 3 full-suite runs (70 properties, 2081 tests, 0 failures, 11 excluded): seeds 576061, 807522, 956638. Flake not reproducible in 13 seeds; the random-seed rule stands (no pinning, no retries). PackageDocsVerifierTest: 46 tests, 0 failures.

## Deviations from Plan

**1. [Rule 3 - Blocking] Three additional CSS guard reds (FND-02, FND-01, RES-04) and two extra unformatted files** found after DSY-01 cleared; fixed in app.css and via the formatter. The guard script is unmodified (`git diff 275e73ae..HEAD -- scripts/ci` is empty). The bundle was rebuilt and committed because of the isolation line.

## Known Stubs

None.

## Self-Check: PASSED

Commits cb3dc546, c6cab1e3, 1a755b2d exist; verify_package_docs.sh exits 0.
