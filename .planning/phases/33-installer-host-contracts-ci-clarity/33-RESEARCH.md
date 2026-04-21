# Phase 33 — Technical Research

**Question:** What do we need to know to plan installer rerun honesty, doc-contract drift, and CI semantics well?

## Summary

Phase 33 is **documentation + doc gates + CI prose**, with **optional** tightening of installer tests only when docs and behavior diverge. Runtime billing logic, admin UI, and new installer features are out of scope unless required to close an ADOPT-04 gap.

### Repo facts (verified)

- **`mix accrue.install`** implements `--check`, `--dry-run`, `--yes`, `--force`, `--write-conflicts`, and fingerprint-based writes (`accrue/lib/mix/tasks/accrue.install.ex`). Summary output distinguishes created / updated pristine / skipped user-edited / skipped exists / manual / conflict artifacts.
- **ExUnit already encodes rerun contracts:** `accrue/test/mix/tasks/accrue_install_test.exs` includes `"re-run updates pristine fingerprinted files and skips user-edited files even with --force"` and conflict artifact tests under `install_conflicts`.
- **`accrue/guides/upgrade.md`** documents rerun semantics (`## Installer rerun behavior`): pristine updates, user-edited skipped, unmarked skipped unless forced, `--write-conflicts` sidecars under `.accrue/conflicts/`.
- **`accrue/guides/first_hour.md`** ends at focused verification; it mentions `mix accrue.install` as production setup but does **not** link the rerun contract.
- **CI job ids** in `.github/workflows/ci.yml`: `release-gate` (matrix, blocking), `host-integration` (blocking deterministic gate), `live-stripe` (advisory; `workflow_dispatch` + schedule only; `continue-on-error: true`), `phase18-tax-gate`, `admin-drift-docs`, `annotation-sweep`. Comments document `live-stripe` / `act -j live-stripe` compatibility.
- **Annotation sweep** (`scripts/ci/annotation_sweep.sh`) is invoked with `release-gate phase18-tax-gate admin-drift-docs host-integration` — advisory `live-stripe` is intentionally absent.

### Planning implications

1. **ADOPT-04** — Prefer **docs + links** over new tests; add tests only when documenting newly discovered drift or missing coverage called out in roadmap success criteria.
2. **ADOPT-05** — Extend `verify_package_docs.sh` and/or `accrue/test/accrue/docs/*` with **stable substrings** for new cross-links and critical installer phrases.
3. **ADOPT-06** — Edits are **comments + guides + root README** clarifications; avoid changing `jobs:` keys and avoid changing `annotation_sweep.sh` selectors unless fixing an actual bug.

## Risks / footguns

- **first_hour guide test** (`accrue/test/accrue/docs/first_hour_guide_test.exs`) enforces **document order** of key markers; append new sections **after** the last ordered anchor (`mix verify.full` in the `assert_order!` chain) or update the test in the same PR.
- **Relative links** from `accrue/guides/first_hour.md` to `upgrade.md` must stay package-local (`upgrade.md`, not `accrue/guides/...` duplication).

## Validation Architecture

**Nyquist dimension 8 — executable verification for this phase**

| Dimension | How we sample |
|-----------|----------------|
| Doc contracts | After doc/script edits: `bash scripts/ci/verify_package_docs.sh` from repo root (exit 0). |
| VERIFY-01 host contract | When host README touched: `bash scripts/ci/verify_verify01_readme_contract.sh` (exit 0). |
| Installer regression | When installer or tests touched: `cd accrue && mix test test/mix/tasks/accrue_install_test.exs --warnings-as-errors` |
| Guide unit tests | When `first_hour.md` or doc tests touched: `cd accrue && mix test test/accrue/docs/first_hour_guide_test.exs --warnings-as-errors` |

**Quick command:** `bash scripts/ci/verify_package_docs.sh`

**Full command:** `bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_verify01_readme_contract.sh && cd accrue && mix test test/mix/tasks/accrue_install_test.exs test/accrue/docs/first_hour_guide_test.exs --warnings-as-errors`

**Wave sampling:** Run quick after each plan wave touching docs; add installer test command when `accrue.install` or `accrue_install_test.exs` changes.

---

## RESEARCH COMPLETE
