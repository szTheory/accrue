# Phase 61 — Pattern map

Analogs for files this phase touches.

| Planned surface | Role | Closest analog | Notes |
|-----------------|------|----------------|-------|
| `README.md` (root) | Proof-path front door | Current `README.md` § Proof path | Phase 51/57/58 trust edits; keep link to host `#proof-and-verification` |
| `scripts/ci/verify_package_docs.sh` | Doc needle SSOT | Existing `require_fixed` clusters | Phase 59 continuity for `@version` pins |
| `scripts/ci/verify_verify01_readme_contract.sh` | Host VERIFY-01 depth | Current awk + grep loops | Do not fold into package_docs |
| `accrue/test/accrue/docs/package_docs_verifier_test.exs` | ExUnit wrapper | Existing tests asserting script stdout | Update when `echo` trailer strings change |
| `scripts/ci/README.md` INT rows | Contributor registry | INT-06/07 table rows above line 33 | Replace Phase 61 placeholder with two rows |
| `.planning/PROJECT.md` / `MILESTONES.md` | Hex vs `main` honesty | § “Public Hex (last published)” in PROJECT | Two-authority pattern D-08–D-09 |

## Code excerpts (signatures)

**`extract_version` / `require_fixed`** — `scripts/ci/verify_package_docs.sh`:

```bash
extract_version() {
  local file=$1
  version=$(sed -n 's/^  @version "\([^"]*\)"/\1/p' "$file" | head -n 1)
  ...
}
```

**ExUnit invokes bash** — `package_docs_verifier_test.exs`:

```elixir
@script_path "../scripts/ci/verify_package_docs.sh"
{output, status} = System.cmd("bash", [@script_path], stderr_to_stdout: true)
```

## PATTERN MAPPING COMPLETE
