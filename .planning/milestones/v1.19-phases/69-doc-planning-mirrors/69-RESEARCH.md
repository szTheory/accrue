# Phase 69 — Technical research

**Question:** What do we need to know to plan **doc + planning mirrors** well after **0.3.1** on Hex?

## Findings

### SSOT chain

1. **`accrue/mix.exs` and `accrue_admin/mix.exs`** — `@version` must stay **lockstep**; `verify_package_docs.sh` fails on divergence before any file checks.
2. **`scripts/ci/verify_package_docs.sh`** — Authoritative `require_fixed` / `require_regex` / `require_any_fixed` needles. Uses `ROOT_DIR` (default: repo root). Success ends with stdout lines:
   - `package docs verified for accrue {v} and accrue_admin {v}`
   - `fixed invariants checked: ...`
3. **`accrue/test/accrue/docs/package_docs_verifier_test.exs`** — Shells out to the script with `../scripts/ci/verify_package_docs.sh` from `accrue/`; negative tests copy fixture trees under `ROOT_DIR`. **Do not** duplicate every bash needle in Elixir (**69-CONTEXT** D-03).

### Surfaces DOC-01 / DOC-02 touch today

| Surface | Contract |
|---------|----------|
| `accrue/guides/first_hour.md` | Capsule H/M/R; `{:accrue, "~> $v"}` and `{:accrue_admin, "~> $v"}` where `$v` is parsed from mix |
| `accrue/README.md`, `accrue_admin/README.md` | Primary Hex install lines, Hex vs `main` callout, doc links |
| `examples/accrue_host/README.md` | Capsule sections + proof / verify strings |
| Root `README.md`, `RELEASING.md`, `CONTRIBUTING.md`, guides | Numerous fixed needles — see script |

### HYG-01 scope (locked in **69-CONTEXT** D-01)

Only **`.planning/PROJECT.md`**, **`.planning/MILESTONES.md`**, **`.planning/STATE.md`** — not a repo-wide version grep.

### Ecosystem pattern (Pay / Cashier / Hex)

- Public **copy-paste** deps stay **`~>`** on the published line; long SemVer essays live in CHANGELOG / upgrade guides.
- Maintainer narrative (**PROJECT**) vs position pointer (**STATE**) split reduces contradiction risk.

### Pitfalls

- Updating ExUnit expectations without re-running bash after script changes → false greens.
- Drifting **two** different version strings for the same release across PROJECT vs STATE vs README.
- Marking **REQUIREMENTS.md** checkboxes before `verify_package_docs` and ExUnit harness both pass.

## Recommendations for plans

- **Wave A:** Verifier + integrator markdown (DOC-01, DOC-02); create **`69-VERIFICATION.md`** with command transcripts or explicit “green at commit” record.
- **Wave B (can parallel A):** HYG-01 factual alignment in the three planning files; link to **ROADMAP** / **REQUIREMENTS** instead of duplicating paragraphs.
- Close **DOC-01**, **DOC-02**, **HYG-01** rows in **`.planning/REQUIREMENTS.md`** traceability only after evidence.

## Validation Architecture

Phase behavior is **deterministic doc + bash + ExUnit**:

| Dimension | Approach |
|-----------|----------|
| **Correctness** | `bash scripts/ci/verify_package_docs.sh` exit 0 from repo root; pins match `sed`-parsed `@version` from both `mix.exs` files |
| **Regression** | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` — success banner + negative cases still fail with `[verify_package_docs]` prefix |
| **Planning hygiene** | Grep **PROJECT** / **MILESTONES** / **STATE** for **`0.3.1`** (or current `@version`) where Hex “last published” is claimed; single coherent story with **STATE** |
| **Manual** | Optional: open Hex package pages to confirm public version matches narrative (already satisfied by Phase **68** evidence trail) |

Sampling: run bash script after every markdown edit under `verify_package_docs` paths; run full ExUnit file after bash changes or new `ROOT_DIR` fixture paths.

## RESEARCH COMPLETE
