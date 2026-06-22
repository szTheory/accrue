---
quick_id: 260622-h7h
slug: dsy01-theme-picker-media-annotation
date: 2026-06-22
status: complete
---

# Summary: Green the package-docs CI gate (DSY-01 + FND-02 + FND-01)

Started as a 1-line DSY-01 annotation fix; the fix **unmasked a stack of accumulated
doc-contract violations** in `accrue_admin/assets/css/app.css` (the `verify_package_docs.sh`
gate exits on the first failure, so each hid the next). All were introduced by pushed-backlog
tasks since the last-green commit `096256d0` and never caught locally (the gate is a CI-only bash
script + the core `accrue` `PackageDocsVerifierTest` — neither runs in `cd accrue_admin && mix
test`). Fixed all three to fully green the gate; on `main`, non-worktree, single code commit.

## Root cause + fixes

1. **DSY-01** (theme-picker, commit `ec45880e`): `@media (max-width: 767px)` lacked the
   `/* --ax-bp-* */` annotation the contract requires on every px breakpoint. → normalized to
   `767.98px` + `/* --ax-bp-md ↓ */` (matches the canonical md max-width guard at line 466).
2. **FND-02** (timeline, commit `260620-ps2`): the rail (`z-index:0`) / node (`z-index:1`)
   micro-stack lacked `ax-z-micro-stack` annotations and an `isolation: isolate` stacking owner.
   → annotated both z-indexes + added `.ax-timeline-item { isolation: isolate }` (the correct row
   stacking owner, within the contract's 25-line lookback).
3. **FND-01** (h72 `.ax-kpi-meta`, **my own olr `.ax-stat-value`**, ps2 `.ax-timeline-time`): raw
   `font-size`/`font-weight`/`line-height` declarations outside the `ax-type-exception` allowlist.
   → added a block-scoped `ax-type-exception` comment to each (the file's established pattern;
   69 already exist).

Two of these are **functional** CSS (the `767.98px` value + the `isolation: isolate` rule), so the
committed `priv/static/accrue_admin.css` bundle was **rebuilt** to stay in sync and actually ship
the fixes (`accrue_admin.js` unchanged).

## Result

`bash scripts/ci/verify_package_docs.sh` → **full PASS** (was failing on DSY-01→FND-02→FND-01 in
sequence). Core `accrue` `PackageDocsVerifierTest` → **29 tests, 0 failures**. Admin
`assets_test.exs` → **3/0** (rebuilt bundle md5 consistent). `mix compile --warnings-as-errors`
clean. This greens the package-docs gate in all three CI places: the bash contract job, the core
package test, and every Release-gate matrix config.

## Commit
- `<this task>` — fix(ci): green the package-docs gate (DSY-01 + FND-02 + FND-01) + rebuild bundle.

## Notes
- Lesson reinforced: per-task verification of `cd accrue_admin && mix test` does NOT run the
  core-package doc-contract tests or the CI bash gate — CSS/doc changes need `verify_package_docs.sh`
  run locally. (The browser UAT is the other CI-only gate — handled separately.)
- Remaining main-CI red after this: the Phase 190/191/192 **Playwright** browser gate (deterministic
  copy/DOM drift from the UI redesign) — being tackled in a separate debug session.
- Guardrails honored: no StatusBadge/CSP/host mix.lock/ROADMAP/JS touched; only app.css source +
  its rebuilt bundle.
