---
phase: 194-exemplar-a-dashboard
plan: "03"
subsystem: ci-guards
tags: [ci, css-guard, test, d-08-coupling, spec-overview]
dependency_graph:
  requires: [scripts/ci/verify_package_docs.sh, accrue_admin/assets/css/app.css]
  provides: [Guard D — empty-rail non-interactivity source lint, D-08 ExUnit mirror test]
  affects: [scripts/ci/verify_package_docs.sh, accrue/test/accrue/docs/package_docs_verifier_test.exs]
tech_stack:
  added: []
  patterns: [perl -0ne block-scan (Guard C convention), append-with-trailing-newline negative test pattern (193-05 deviation)]
key_files:
  created: []
  modified:
    - scripts/ci/verify_package_docs.sh
    - accrue/test/accrue/docs/package_docs_verifier_test.exs
decisions:
  - Guard D uses perl -0ne block-scan over .ax-attention-rail--empty CSS rule blocks, mirroring Guard C convention, banning cursor:pointer in any such block
  - Fail message contains stable "empty-rail" substring so the D-08 ExUnit mirror can =~-assert without brittle full-string coupling
  - New test uses append-with-trailing-newline pattern (not full-replace) to preserve seeded app.css coverage for earlier token-consumption and Guard A/B/C checks
metrics:
  duration: 5m
  completed: "2026-06-25"
  tasks: 2
  files: 2
status: complete
requirements: [EXE-01]
---

# Phase 194 Plan 03: Empty-Rail Non-Interactivity Source Guard Summary

Guard D (`cursor:pointer` ban on `.ax-attention-rail--empty`) added to `verify_package_docs.sh` with its mandatory D-08 ExUnit mirror in `PackageDocsVerifierTest` — the SPEC-OVERVIEW non-interactive empty-rail invariant now enforced at CI source-lint, with coupled test suite evidence that the guard cannot be silently weakened.

## Tasks Completed

| Task | Description | Commit | Files |
|------|-------------|--------|-------|
| 1 | Add Guard D — empty-rail non-interactivity source guard | ea4cf66d | scripts/ci/verify_package_docs.sh |
| 2 | Add D-08 mirror — negative ExUnit test for Guard D | 32811518 | accrue/test/accrue/docs/package_docs_verifier_test.exs |

## What Was Built

### Guard D in `verify_package_docs.sh`

Placed in the Phase 193 RES-04 CSS source guards region, immediately after Guard C (truncation guard, ~L586), before the spec-guide existence checks. Uses the existing `$app_css` variable (defined at L323) and the `fail` helper (L9-12). Implementation:

```bash
# Guard D — Empty-rail non-interactivity (Phase 194, SPEC-OVERVIEW)
empty_rail_pointer_hit=$(
  perl -0ne '
    while (/\.ax-attention-rail--empty[^{]*\{([^}]*)\}/gs) {
      my $block = $1;
      if ($block =~ /cursor\s*:\s*pointer/) { print "found cursor:pointer on empty rail\n"; last; }
    }
  ' "$app_css" || true
)
[[ -z "$empty_rail_pointer_hit" ]] || fail "$app_css must not put cursor:pointer on .ax-attention-rail--empty (SPEC-OVERVIEW non-interactive empty-rail guard)"
```

The perl `-0ne` block-scan (same convention as Guard C) slurps the entire file and matches each `.ax-attention-rail--empty { ... }` block, failing if any block contains `cursor: pointer` (tolerating optional whitespace around the colon). Passes on the real app.css (no `cursor:pointer` on empty rail). Fires on a planted violation (`GUARD_FIRED` verified). The fail message contains the stable `"empty-rail"` substring.

### D-08 Mirror in `PackageDocsVerifierTest`

New test appended after the existing RES-04 negative tests (truncation guard test), before the private helpers. Follows the append-with-trailing-`\n` pattern established in 193-05 to preserve earlier token-consumption and Guard A/B/C coverage in the seeded app.css:

```elixir
test "package docs verifier rejects cursor:pointer on .ax-attention-rail--empty (Phase 194)" do
  tmp_dir = tmp_dir!()
  seed_tmp_dir!(tmp_dir)

  app_css_path = Path.join(tmp_dir, "accrue_admin/assets/css/app.css")
  File.write!(
    app_css_path,
    File.read!(app_css_path) <> "\n.ax-attention-rail--empty { cursor: pointer; }\n"
  )

  {output, status} = run_verifier(tmp_dir)

  assert status != 0
  assert output =~ "[verify_package_docs]"
  assert output =~ "empty-rail"
end
```

All 33 `package_docs_verifier_test.exs` tests pass (0 failures).

## Verification Results

- `bash scripts/ci/verify_package_docs.sh` — PASS (exit 0 on real app.css)
- Planted violation test (`cursor:pointer` appended) — `GUARD_FIRED` (fail message contains `"empty-rail"`)
- `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` — 33 tests, 0 failures

## Deviations from Plan

None — plan executed exactly as written. Both mechanisms added as specified (D-06 resolved discretion item: BOTH new). D-08 coupling honored: append-with-`\n` pattern used (not full-replace) per 193-05 deviation learnings.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. Guard D reads `app.css` via fixed perl patterns (no eval of file content) — T-194-05 mitigation honored. The D-08 ExUnit mirror ensures Guard D cannot be silently weakened without test-suite failure — T-194-06 mitigation honored.

## Self-Check: PASSED

- `scripts/ci/verify_package_docs.sh` — exists and passes
- `accrue/test/accrue/docs/package_docs_verifier_test.exs` — exists and all 33 tests pass
- Commit ea4cf66d — exists (Task 1)
- Commit 32811518 — exists (Task 2)
