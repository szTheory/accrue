# Phase 32 — Pattern Map

Analogs and excerpts for executors replicating repo conventions.

## Doc SSOT layering

| Role | File | Pattern |
|------|------|---------|
| Monorepo index | `README.md` | Short “Start here” bullets; links into deeper SSOT (already matches Hex culture). |
| Runnable commands | `examples/accrue_host/README.md` | Code fences with `cd examples/accrue_host` before `mix` / `npm` (see First run / VERIFY-01). |
| Package pedagogy | `accrue/guides/first_hour.md` | Mirrors host order; references `mix verify` / `mix verify.full` without redefining CI matrix. |

## Doc-contract scripts (extend, do not bypass)

**Analog:** `scripts/ci/verify_verify01_readme_contract.sh` — substring + awk gates:

```bash
require_substring "host-integration" "GitHub Actions job name for PR CI"
```

**Analog:** `scripts/ci/verify_package_docs.sh` — `require_fixed` for canonical headings:

```bash
require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "## Verification modes"
```

> **Phase 32 change:** When host IA introduces a single parent `## Proof & verification` (or chosen title), replace fixed `## Verification modes` with the new invariant (e.g. require parent heading + `### Verification modes`) in the same commit as README edits.

## Approved merge-blocking vocabulary

Host README already contains the mapping sentence pattern (VERIFY-01 section):

> On every pull request, the GitHub Actions job `host-integration` runs the same contract as `cd examples/accrue_host && mix verify.full`

Phase 32 normalizes to the **single approved one-liner** from `32-CONTEXT.md` across root, host H2 lede, and guides — extend `verify_package_docs.sh` with `require_fixed` for that exact string on agreed files once finalized.
