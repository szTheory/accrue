---
phase: 126
slug: admin-surface-docs-jtbd-spine
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-23
validated: 2026-05-24
---

# Phase 126 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `126-RESEARCH.md` § Validation Architecture (HIGH confidence; verifier RED state
> reproduced by the researcher). Task IDs are finalized at planning — the rows below are keyed by
> behavior/requirement and reconciled to plan task IDs during execute-phase.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17); `AccrueAdmin.LiveCase` (`accrue_admin/test/support/live_case.ex`) for LiveView tests |
| **Config file** | `accrue/test/test_helper.exs` + `accrue_admin/test/test_helper.exs` (existing — no install) |
| **Quick run command** | `cd accrue_admin && mix test test/accrue_admin/live/entitlements_live_test.exs` (admin tab) · `bash scripts/ci/verify_package_docs.sh` (doc tasks) |
| **Full suite command** | `cd accrue && mix test` && `cd accrue_admin && mix test` |
| **Estimated runtime** | doc verifier <5s · new LiveView/seam files ~5–15s · full both-package suite ~minutes |

---

## Sampling Rate

- **After every task commit:** Run the relevant quick command — the new LiveView/seam test file for admin work, or `bash scripts/ci/verify_package_docs.sh` for doc/needle work.
- **After every plan wave:** Run `cd accrue && mix test` && `cd accrue_admin && mix test`.
- **Before `/gsd:verify-work`:** Full suite green AND the D-15 phase gate (all three) passing.
- **Max feedback latency:** doc verifier <5s; admin tab quick test <15s.

---

## Per-Task Verification Map

| Behavior (→ reconciled to plan) | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|-------------------------------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| Read seam `Accrue.Entitlements.Admin.resolve_for_customer/1` returns `{resolved_map, unmapped_price_ids}`; reuses `LocalMap` fold (no drift) | 126-01 | 1 | ENT-11 | — | One-way dep admin→billing; no public gate API exposed | unit | `cd accrue && mix test test/accrue/entitlements/admin_test.exs` | ✅ exists | ✅ green (9 tests; mapped/unmapped/empty/grace + `:raise` WR-03) |
| Entitlements tab renders resolved active plans/features/quantities/grace for a mapped sub | 126-02 | 2 | ENT-11 | — | Read-only; opaque to non-authorized via existing `AuthHook` | LiveView | `cd accrue_admin && mix test test/accrue_admin/live/entitlements_live_test.exs` | ✅ exists | ✅ green (4 tests) |
| Tab badges an active sub whose `price_id` ∉ reverse-index with "⚠ Unmapped plan" | 126-02 | 2 | ENT-11 | — | Drift surfaced read-only (factory `price_basic` is unmapped → free fixture) | LiveView | same file, distinct test | ✅ exists | ✅ green |
| Empty / no-entitlements state renders the Copy line (no crash) | 126-02 | 2 | ENT-11 | — | N/A | LiveView | same file, distinct test | ✅ exists | ✅ green |
| `guides/entitlements.md` builds into HexDocs | 126-03 | 3 | ENT-12 | — | N/A | smoke | `cd accrue && mix docs` (exit 0, no new actionable warnings, `entitlements.html` present) | ✅ built | ✅ green (exit 0; `entitlements.html` 35294 B) |
| Package-doc verifier green end-to-end (8/0) after D-13 fix + new needles | 126-04 | 3 | ENT-12 | — | N/A | integration | `bash scripts/ci/verify_package_docs.sh` (exit 0) + `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` (8/0) | ✅ exists | ✅ green (verifier exit 0; verifier test 8/0) |
| JTBD flip-guard: old gap wording absent in body/scope (`require_absent_regex`) | 126-04 | 3 | ENT-12 | — | N/A | integration | covered by the verifier run (new flip-guard needle) | ✅ via verifier | ✅ green (verifier exit 0 — guard does not fire) |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `accrue/test/accrue/entitlements/admin_test.exs` — read-seam `resolve_for_customer/1` (mapped, unmapped, empty, grace + `:raise` WR-03). Cloned setup from `local_map_test.exs`. **9 tests, 0 failures.**
- [x] `accrue_admin/test/accrue_admin/live/entitlements_live_test.exs` — the ENT-11 render states (resolved, unmapped badge, empty + `:raise` error-copy render). Cloned structure from `customer_live_test.exs`. **4 tests, 0 failures.**
- [x] No framework install needed — ExUnit + `LiveCase` + `Factory` all exist.
- [ ] **Baseline caveat (project memory + research):** the `accrue` full `mix test` baseline carries 6 PRE-EXISTING `PackageDocsVerifierTest` failures (this exact verifier-RED state) plus a flaky `PdfTest`. The 6 verifier failures are EXPECTED to green via D-13 — that is the validation signal, not a regression. Do not re-triage them as new failures.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| HexDocs `entitlements.html` reads coherently (fail-closed opener, SSOT links resolve) | ENT-12 | Rendered-prose quality is not assertable beyond build success | After `cd accrue && mix docs`, open `doc/entitlements.html`; confirm the fail-closed snippet leads and the lifecycle/provider SSOT links resolve |

*All other phase behaviors have automated verification (LiveView tests, unit test for the seam, the doc verifier, and `mix docs`).*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (the two new test files — both now exist and green)
- [x] No watch-mode flags
- [x] Feedback latency < 15s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-05-24 (retroactive audit — all 7 behaviors COVERED, 0 MISSING, 0 PARTIAL)

---

## Validation Audit 2026-05-24

Retroactive Nyquist audit of the completed phase (State A — VALIDATION.md existed from planning).
All seven planned behaviors are COVERED by automated verification that runs green at audit time;
the implementation exceeded the plan by adding the `:raise` fail-closed path (WR-03) at both the
seam and the LiveView. No gaps → no `gsd-nyquist-auditor` spawn needed.

| Metric | Count |
|--------|-------|
| Behaviors audited | 7 |
| COVERED | 7 |
| PARTIAL | 0 |
| MISSING | 0 |
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

**Audit-time evidence (run fresh 2026-05-24):**

| Command | Result |
|---------|--------|
| `cd accrue && mix test test/accrue/entitlements/admin_test.exs test/accrue/docs/package_docs_verifier_test.exs --seed 0` | 17 tests, 0 failures (9 seam + 8 doc verifier) |
| `cd accrue_admin && mix test test/accrue_admin/live/entitlements_live_test.exs --seed 0` | 4 tests, 0 failures |
| `bash scripts/ci/verify_package_docs.sh` | exit 0 |
| `cd accrue && mix docs` | exit 0; `doc/entitlements.html` (35294 B) present |
