---
status: complete
updated: 2026-09-12
---

# GSD Debug Knowledge Base

Resolved debug sessions. Used by `gsd-debugger` to surface known-pattern hypotheses at the start of new investigations.

---

## phase227-format-verifier-gap — Accrue format drift and missing kept-only verifier guard
- **Date:** 2026-09-12
- **Error patterns:** required release lane, Accrue format, --require-kept, verifier option unavailable, rollback terminal
- **Root cause(s):** Committed format drift in `accrue/test/accrue/backend_automation_contract_test.exs`; strict CLI refactor removed the documented `--require-kept` terminal-state guard, leaving only weaker `--require-final-decision`.
- **Fix:** Formatted the reported Accrue test expression and restored `--require-kept` as a strict verifier modifier that rejects any terminal state other than kept.
- **Files changed:** accrue/test/accrue/backend_automation_contract_test.exs, scripts/ci/verify_ci_critical_path.mjs, scripts/ci/verify_ci_critical_path.test.mjs
- **Why not caught:** No pre-merge verifier CLI contract test covered the documented `--require-kept` option, and the committed Accrue test was not checked with the CI-pinned formatter before the candidate run.
- **Recurrence guard:** `scripts/ci/verify_ci_critical_path.test.mjs` test `requires a kept v2 terminal decision when requested`; the CI-pinned `mix format --check-formatted` lane rejects future Accrue format drift.
---
