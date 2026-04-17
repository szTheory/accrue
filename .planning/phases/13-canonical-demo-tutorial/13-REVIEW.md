---
phase: 13-canonical-demo-tutorial
reviewed: 2026-04-17T02:00:05Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - accrue/README.md
  - accrue/guides/first_hour.md
  - accrue/lib/accrue/config.ex
  - accrue/test/accrue/docs/canonical_demo_contract_test.exs
  - accrue/test/accrue/docs/first_hour_guide_test.exs
  - accrue/test/accrue/docs/package_docs_verifier_test.exs
  - examples/accrue_host/README.md
  - examples/accrue_host/demo/command_manifest.exs
  - examples/accrue_host/mix.exs
  - examples/accrue_host/test/demo/command_manifest_test.exs
  - examples/accrue_host/test/mix_alias_contract_test.exs
  - examples/accrue_host/test/repo_wrapper_contract_test.exs
  - scripts/ci/accrue_host_uat.sh
  - scripts/ci/verify_package_docs.sh
findings:
  critical: 0
  warning: 2
  info: 0
  total: 2
status: issues_found
---

# Phase 13: Code Review Report

**Reviewed:** 2026-04-17T02:00:05Z
**Depth:** standard
**Files Reviewed:** 14
**Status:** issues_found

## Summary

Reviewed the canonical demo/tutorial docs, manifest, verification aliases, and the repo-root/package-docs wrapper scripts. The main issues are both reliability problems in the verification layer: one shell wrapper can fail on valid non-default Postgres setups, and two doc-contract tests can raise the wrong exception before they report the intended drift.

## Warnings

### WR-01: Repo-root UAT wrapper hard-codes the Postgres readiness probe to the default port

**File:** `scripts/ci/accrue_host_uat.sh:26-29`
**Issue:** The wrapper advertises support for overridden Postgres connection settings, but the optional `pg_isready` preflight only forwards `PGHOST` and `PGUSER`. When a developer or CI job uses a non-default `PGPORT` (or a connection that relies on other libpq env like `PGDATABASE`), `pg_isready` can fail even though the later `mix verify.full` step would have connected successfully. Because the script runs under `set -e`, that false negative aborts the whole wrapper before the actual verification command runs.
**Fix:**
```bash
if command -v pg_isready >/dev/null 2>&1; then
  echo "--- checking Postgres availability ---"
  pg_isready \
    -h "${PGHOST:-localhost}" \
    -p "${PGPORT:-5432}" \
    -U "${PGUSER:-postgres}" \
    ${PGDATABASE:+-d "$PGDATABASE"}
fi
```

### WR-02: Order-assertion helpers can crash with `ArithmeticError` before producing the intended drift failure

**File:** `accrue/test/accrue/docs/canonical_demo_contract_test.exs:92-108`
**File:** `accrue/test/accrue/docs/first_hour_guide_test.exs:72-88`
**Issue:** Both helpers seed `Enum.reduce/3` with `index_of(binary, first)` and then immediately evaluate `previous_index + 1` on the next iteration. If the first required label is missing, `index_of/3` returns `nil`, so the helper raises `ArithmeticError` instead of a useful assertion failure naming the missing label. That makes the docs-contract tests less reliable and defeats the goal of exact drift diagnostics.
**Fix:**
```elixir
defp assert_order!(binary, [first | rest]) do
  previous_index =
    index_of(binary, first) ||
      flunk("expected to find #{inspect(first)} in document")

  Enum.reduce(rest, previous_index, fn needle, previous_index ->
    current_index =
      index_of(binary, needle, previous_index + 1) ||
        flunk("expected to find #{inspect(needle)} after #{inspect(first)}")

    assert previous_index < current_index
    current_index
  end)
end

defp index_of(binary, pattern, offset \\ 0) when offset <= byte_size(binary) do
  case :binary.match(binary, pattern, [{:scope, {offset, byte_size(binary) - offset}}]) do
    {index, _length} -> index
    :nomatch -> nil
  end
end

defp index_of(_binary, _pattern, _offset), do: nil
```

---

_Reviewed: 2026-04-17T02:00:05Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
