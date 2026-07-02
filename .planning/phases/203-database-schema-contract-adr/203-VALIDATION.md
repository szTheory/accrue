---
phase: 203
slug: database-schema-contract-adr
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-02
---

# Phase 203 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Markdown/content smoke checks with `rg`; ExUnit via Mix 1.19.5 for optional code-evidence confidence if implementation files change. |
| **Config file** | `accrue/config/test.exs` for optional ExUnit checks; no config required for markdown checks. |
| **Quick run command** | Run the DB-01..DB-04 markdown checklist below. |
| **Full suite command** | `cd accrue && mix test test/mix/tasks/accrue_install_test.exs test/accrue/config_test.exs` if any code or public docs under `accrue/` change; otherwise run the DB-01..DB-04 markdown checks below. |
| **Estimated runtime** | ~10 seconds for markdown checks; app test runtime depends on local database startup/state. |

---

## Sampling Rate

- **After every task commit:** Run the DB-01..DB-04 markdown/content smoke checks in the map below.
- **After every plan wave:** Re-run the markdown/content smoke checks. If code or public docs under `accrue/` changed, also run `cd accrue && mix test test/mix/tasks/accrue_install_test.exs test/accrue/config_test.exs`.
- **Before `/gsd:verify-work`:** ADR file must exist and every DB-01..DB-04 smoke check must return at least one matching line.
- **Max feedback latency:** 60 seconds for markdown-only execution.

---

## DB-01..DB-04 Markdown Checklist

Run this checklist after every task commit, after every plan wave, and before `/gsd:verify-work`:

```bash
bash -lc 'set -euo pipefail
ADR=.planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md
test -f "$ADR"
require_literal() { rg -n --fixed-strings -- "$1" "$ADR" >/dev/null; }
require_regex() { rg -n "$1" "$ADR" >/dev/null; }

# DB-01: current schema contract and binding surfaces
require_literal "billing"
require_literal "public"
require_literal "compile-time"
require_literal "Accrue.Schema"
require_literal "Accrue.Migration"
require_literal "Accrue.Config"
require_literal "host-owned"
require_literal "search_path"

# DB-02: default-rename rejection and upgrade risk
require_literal "accrue.accrue_"
require_literal "Why Not"
require_literal "upgrade risk"
require_literal "rename"
require_literal "config :accrue, :billing_schema, \"public\""
require_literal "config :accrue, :billing_schema, \"billing\""
require_literal "before recompiling"

# DB-03: Phase 204 handoff table shape and hardening candidates
require_literal "Phase 204 Handoff"
require_literal "Evidence path"
require_literal "Current risk"
require_literal "Expected impact"
require_literal "Tradeoff"
require_literal "Implementation approach"
require_literal "Verification"
require_literal "Rollback"
require_literal "Metric/evidence-needed"
require_literal "Non-goals"
require_literal "prefix-agreement"
require_literal "raw SQL"
require_literal "--billing-schema public"
require_literal "First Hour"
require_literal "Upgrade"
require_literal "example-host"
require_literal "qualified"
require_literal "local DB-schema-contract"
require_literal "not final cross-audit ordering"

# DB-04: coverage rows and schema-push boundary
require_regex "^\\| DB-01 \\|"
require_regex "^\\| DB-02 \\|"
require_regex "^\\| DB-03 \\|"
require_regex "^\\| DB-04 \\|"
require_literal "Non-Goals"
require_literal "out of scope"
require_literal "implementation milestone"
require_literal "no schema push task is required"
test -z "$(git diff --name-only -- accrue accrue_admin accrue_portal examples .github scripts)"
'
```

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 203-01-01 | 01 | 1 | DB-01 | T-203-01 | ADR preserves current schema placement contract without relying on `search_path`. | markdown checklist | Run DB-01 block in the markdown checklist above. | yes | pending |
| 203-01-02 | 01 | 1 | DB-02 | T-203-02 | ADR rejects a default rename that could break existing installs. | markdown checklist | Run DB-02 block in the markdown checklist above. | yes | pending |
| 203-01-03 | 01 | 1 | DB-03 | T-203-03 | ADR hands future hardening checks to Phase 204 without implementing them now. | markdown checklist | Run DB-03 block in the markdown checklist above. | yes | pending |
| 203-01-04 | 01 | 1 | DB-04 | T-203-04 | ADR separates support contract, non-goals, and future implementation work. | markdown checklist | Run DB-04 block in the markdown checklist above. | yes | pending |

*Status: pending, green, red, flaky.*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. Phase 203 is docs-only and the current ADR draft already exists at `.planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md`.

---

## Manual-Only Verifications

All phase behaviors have automated markdown/content verification. Manual review is still useful for prose quality, but it is not the only proof for DB-01..DB-04.

---

## Validation Sign-Off

- [x] All tasks have automated verify commands or no Wave 0 dependency.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency under 60 seconds for markdown-only execution.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-07-02
