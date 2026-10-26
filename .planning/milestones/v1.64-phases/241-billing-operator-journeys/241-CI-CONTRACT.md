# Phase 241 executable UAT contract reconciliation

Date: 2026-10-10. This is acceptance-record serialization, not a new verification of archived product behavior.

## Discovery and correction

The current Phase 241 verification and generated UAT passed. The existing CI command `node scripts/ci/verify_executable_uat_contract.mjs --all-since 229` then rejected Phase 234's legacy `result: pass` format. A complete diagnostic found missing canonical UAT artifacts for Phases 235–240 and legacy SUMMARY metadata for 239-01, 239-03, 240-03 and 240-06.

- Preserved Phase 234's complete original acceptance and resolved-gap history as `.planning/milestones/v1.63-phases/234-admin-customers-subscriptions/234-UAT-LEGACY.md`.
- Promoted already-recorded completion status to top-level metadata for 239-01, 239-03 and 240-03. Added the existing Performance completion timestamps for 239-01 and 240-06. No coverage verdict changed.
- Used the existing `generateAutomatedUat` owner to serialize Phases 234–240 from their executable SUMMARY coverage. Its prerequisites require passed verification and `behavior_unverified: 0`; every generated item has passing recorded coverage.
- Left archived verification verdicts, digests, source evidence and milestone dispositions intact. Historical digests are historical provenance, not a fresh verification claim after serialization.
- Changed no CI guard, dependency, source behavior or required-check definition.

## Actual local CI contract results

The commands already wired at `.github/workflows/ci.yml` passed after reconciliation:

| Command | Result |
| --- | --- |
| `node scripts/ci/verify_executable_uat_contract.mjs --self-test` | PASS |
| `node scripts/ci/verify_executable_uat_contract.mjs --all-opted-in` | PASS: 2 opted-in phases, 1 complete, 3 summaries, 6 automated UAT items |
| `node scripts/ci/verify_executable_uat_contract.mjs --all-since 229` | PASS: 13 phases, 102 summaries, 302 automated UAT items |

These counts validate committed executable acceptance records. They do not mean 302 product tests were rerun, or that remote `main` CI was observed.

## Future completion rule

Keep completion status at the SUMMARY top level and record an actual completion timestamp. After a genuine verifier passes, generate canonical UAT with `node scripts/ci/verify_executable_uat_contract.mjs --phase PHASE --write`, then run the CI contract above before closing the phase. Retain genuine failures and any resolved-gap history; never convert an unresolved result into a pass to satisfy serialization. The existing Executable Acceptance Policy remains the authority for zero-human UAT.
