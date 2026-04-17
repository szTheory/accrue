---
phase: 16-expansion-discovery
slug: expansion-discovery
status: verified
threats_open: 0
asvs_level: 1
created: 2026-04-17
verified: 2026-04-17
---

# Phase 16 - Security

> Per-phase security contract: threat register, accepted risks, and audit trail for expansion-discovery planning outputs.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| recommendation artifact -> future phase planners | Phase 16 conclusions steer milestone scope and must not misstate architecture, scope, or risk. | Planning guidance and ranked expansion decisions |
| finance recommendation -> export audiences | Planning language can normalize unsafe export surfaces if audience boundaries are vague. | Finance/export planning assumptions |
| org billing recommendation -> tenant boundaries | Planning language can under-specify tenant isolation and create future cross-tenant leakage risk. | Tenant ownership and authorization assumptions |
| processor recommendation -> core billing contract | Planning language can pressure Accrue into weakest-common-denominator abstractions. | Processor abstraction and parity assumptions |
| phase verification -> roadmap, requirements, and project records | Verification evidence must carry into durable planning sources without mutating discovery into implementation promises. | Durable milestone records |
| recommendation artifact -> docs contract | A weak contract can falsely validate the wrong ranked outcome and mislead future planning. | Checked-in recommendation artifact |
| docs contract -> validation evidence | Validation text can overclaim proof strength if it does not describe the exact mapping being tested. | Automated evidence claims |
| gap closure updates -> phase scope | Verification edits can accidentally broaden a test/docs fix into implementation claims or new roadmap intent. | Gap-closure planning evidence |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-16-01 | T | tax recommendation and migration notes | mitigate | The recommendation artifact explicitly records `tax rollout correctness`, customer location capture, disabled automatic tax states, and recurring-item migration prerequisites. Evidence: `16-EXPANSION-RECOMMENDATION.md` lines 30, 39-40, 65. | closed |
| T-16-02 | I | revenue/export recommendation | mitigate | The recommendation keeps export work host-authorized and prefers Stripe-owned reporting paths before app-level downloads. Evidence: `16-EXPANSION-RECOMMENDATION.md` lines 32, 41, 64. | closed |
| T-16-03 | I/E | org or multi-tenant recommendation | mitigate | The recommendation records cross-tenant leakage risk, row-scoped tenancy, `owner_type`, `owner_id`, and Sigra gating. Evidence: `16-EXPANSION-RECOMMENDATION.md` lines 31, 42, 63. | closed |
| T-16-04 | T | processor recommendation | mitigate | The recommendation keeps second processor work as `Planted seed`, preserves custom processor wording, and forbids core parity promises. Evidence: `16-EXPANSION-RECOMMENDATION.md` lines 24, 33, 43, 66. | closed |
| T-16-05 | T | roadmap and project ranking records | mitigate | Durable records state the Phase 16 output is recommendation-only and that no implementation, schema, API, or processor-abstraction change is implied for v1.2. Evidence: `.planning/ROADMAP.md` line 125 and `.planning/PROJECT.md` lines 238, 242-246. | closed |
| T-16-06 | I | backlog export guidance | mitigate | Project and requirements records preserve wrong-audience finance export language and host-authorized export prerequisites. Evidence: `.planning/REQUIREMENTS.md` line 52 and `.planning/PROJECT.md` line 244. | closed |
| T-16-07 | I/E | backlog org or multi-tenant guidance | mitigate | Durable records preserve cross-tenant leakage language, Sigra or equivalent host-owned org prerequisites, and row-scoped tenancy constraints. Evidence: `.planning/REQUIREMENTS.md` line 54 and `.planning/PROJECT.md` line 243. | closed |
| T-16-08 | T | planted second-processor seed | mitigate | Durable records preserve processor-boundary downgrade language and keep official second processor work as a planted seed rather than a current milestone promise. Evidence: `.planning/REQUIREMENTS.md` line 53 and `.planning/PROJECT.md` line 245. | closed |
| T-16-09 | T | tax milestone recommendation and durable records | mitigate | Durable records preserve tax rollout correctness, customer-location capture, and legacy recurring-item migration prerequisites. Evidence: `.planning/REQUIREMENTS.md` line 51 and `.planning/PROJECT.md` line 246. | closed |
| T-16-10 | T | `accrue/test/accrue/docs/expansion_discovery_test.exs` | mitigate | The ExUnit docs contract extracts `ranked_section` from `## Ranked Recommendation` and asserts all four exact ranked rows, so reordered or mismatched mappings fail. Evidence: `expansion_discovery_test.exs` lines 21-31; `mix test test/accrue/docs/expansion_discovery_test.exs --trace` passed. | closed |
| T-16-11 | R | `.planning/phases/16-expansion-discovery/16-VALIDATION.md` | mitigate | DISC-05 validation states the stronger exact candidate-to-outcome mapping proof and cites the same ExUnit command. Evidence: `16-VALIDATION.md` lines 45, 55. | closed |
| T-16-12 | T | `.planning/phases/16-expansion-discovery/16-VERIFICATION.md` | mitigate | Verification records the closed docs-contract gap narrowly and maintains recommendation-only, no-implementation scope. Evidence: `16-VERIFICATION.md` lines 25-27, 57-58, 88-90. | closed |
| T-16-13 | E | gap-closure scope | accept | This was test/docs-only work. Scope broadening is controlled by the plan's file list and confirmed by `16-03-SUMMARY.md`, which records no recommendation artifact change and no implementation claims. | closed |

*Status: open, closed*
*Disposition: mitigate (implementation required), accept (documented risk), transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-16-01 | T-16-13 | Gap closure intentionally touched only the docs test and planning evidence files. The accepted residual risk is that this phase does not add runtime implementation controls because Phase 16 is recommendation-only discovery work. | GSD phase plan | 2026-04-17 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-04-17 | 13 | 13 | 0 | Codex (gsd-secure-phase) |

---

## Verification Evidence

| Check | Result |
|-------|--------|
| `rg -n "tax rollout correctness|wrong-audience finance exports|cross-tenant billing leakage|processor-boundary downgrade" .planning/phases/16-expansion-discovery/16-EXPANSION-RECOMMENDATION.md` | Pass - canonical recommendation contains all security boundary phrases. |
| `rg -n "recommendation-only|no implementation|schema|API|processor-abstraction" .planning/ROADMAP.md .planning/PROJECT.md .planning/REQUIREMENTS.md` | Pass - durable records preserve recommendation-only scope. |
| `rg -n "ranked_section|String\\.split\\(\"## Ranked Recommendation\"\\)" accrue/test/accrue/docs/expansion_discovery_test.exs` | Pass - docs contract scopes assertions to the ranked recommendation section. |
| `cd accrue && mix test test/accrue/docs/expansion_discovery_test.exs --trace` | Pass - 3 tests, 0 failures. |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-04-17
