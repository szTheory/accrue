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
| **Quick run command** | `rg -n "billing|public|compile-time|Phase 204|search_path|host-owned|accrue" .planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md` |
| **Full suite command** | `cd accrue && mix test test/mix/tasks/accrue_install_test.exs test/accrue/config_test.exs` if any code or public docs under `accrue/` change; otherwise run the DB-01..DB-04 markdown checks below. |
| **Estimated runtime** | ~10 seconds for markdown checks; app test runtime depends on local database startup/state. |

---

## Sampling Rate

- **After every task commit:** Run the DB-01..DB-04 markdown/content smoke checks in the map below.
- **After every plan wave:** Re-run the markdown/content smoke checks. If code or public docs under `accrue/` changed, also run `cd accrue && mix test test/mix/tasks/accrue_install_test.exs test/accrue/config_test.exs`.
- **Before `/gsd:verify-work`:** ADR file must exist and every DB-01..DB-04 smoke check must return at least one matching line.
- **Max feedback latency:** 60 seconds for markdown-only execution.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 203-01-01 | 01 | 1 | DB-01 | T-203-01 | ADR preserves current schema placement contract without relying on `search_path`. | markdown smoke | `rg -n "billing|public|compile-time|Accrue\\.Schema|Accrue\\.Migration|host-owned" .planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md` | yes | pending |
| 203-01-02 | 01 | 1 | DB-02 | T-203-02 | ADR rejects a default rename that could break existing installs. | markdown smoke | `rg -n "accrue\\.accrue_|Why Not|out of scope|upgrade risk|rename" .planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md` | yes | pending |
| 203-01-03 | 01 | 1 | DB-03 | T-203-03 | ADR hands future hardening checks to Phase 204 without implementing them now. | markdown smoke | `rg -n "Phase 204|prefix-agreement|raw SQL|installer|docs|test|compatibility|qualified" .planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md` | yes | pending |
| 203-01-04 | 01 | 1 | DB-04 | T-203-04 | ADR separates support contract, non-goals, and future implementation work. | markdown smoke | `rg -n "Future Hardening|Non-Goals|not part|out of scope|implementation milestone" .planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md` | yes | pending |

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
