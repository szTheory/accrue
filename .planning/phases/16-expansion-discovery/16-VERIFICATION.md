---
phase: 16-expansion-discovery
verified: 2026-04-17T14:33:21Z
status: gaps_found
score: 5/6 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 5/5 must-haves verified
  gaps_closed: []
  gaps_remaining:
    - "Checked-in docs contract and validation evidence do not reliably verify the exact ranked candidate-to-outcome mapping."
  regressions:
    - "The prior verification marked the docs contract as fully protective, but `accrue/test/accrue/docs/expansion_discovery_test.exs` only checks candidate names and ranking keywords independently."
gaps:
  - truth: "Checked-in docs contract and validation evidence reliably verify the exact ranked candidate-to-outcome mapping."
    status: failed
    reason: "The ExUnit docs contract passes when candidate names and outcome labels appear anywhere in the file, so a malformed, reordered, or mismatched ranked table can still satisfy the automated proof for DISC-05."
    artifacts:
      - path: "accrue/test/accrue/docs/expansion_discovery_test.exs"
        issue: "Lines 21-28 assert candidate names and `Next milestone`/`Backlog`/`Planted seed` separately rather than asserting the expected ranked rows or equivalent candidate-to-outcome bindings."
      - path: ".planning/phases/16-expansion-discovery/16-VALIDATION.md"
        issue: "DISC-05 points its automated proof at the loose docs contract, so the validation map inherits the same blind spot."
    missing:
      - "Assert exact ranked-table rows or equivalent candidate-to-outcome mapping for all four recommendations."
      - "Update DISC-05 validation evidence to reference the stronger ranking contract."
---

# Phase 16: Expansion Discovery Verification Report

**Phase Goal:** evaluate and rank tax, revenue/export, additional processor, and org/multi-tenant billing options for the next implementation milestone.
**Verified:** 2026-04-17T14:33:21Z
**Status:** gaps_found
**Re-verification:** Yes - previous report existed, but this pass rechecked the actual artifacts against the review warning.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Tax, revenue/export, additional processor, and org or multi-tenant options each have a decision-quality recommendation. | ✓ VERIFIED | The ranked table in `.planning/phases/16-expansion-discovery/16-EXPANSION-RECOMMENDATION.md` includes all four candidates with concrete entries at lines 30-33. |
| 2 | Recommendations identify user value, architecture impact, risk, and prerequisites. | ✓ VERIFIED | The `Ranked Recommendation` table includes `User Value`, `Architecture Impact`, `Risk`, and `Prerequisites` columns with substantive text for every candidate at lines 28-33 of `.planning/phases/16-expansion-discovery/16-EXPANSION-RECOMMENDATION.md`. |
| 3 | Expansion candidates are ranked into next milestone, backlog, or planted seed. | ✓ VERIFIED | The checked-in rows map `Stripe Tax support -> Next milestone`, `Organization / multi-tenant billing -> Backlog`, `Revenue recognition / exports -> Backlog`, and `Official second processor adapter -> Planted seed` in `.planning/phases/16-expansion-discovery/16-EXPANSION-RECOMMENDATION.md:30-33`. |
| 4 | No core billing API, schema, or processor abstraction changes are made beyond future migration-path notes. | ✓ VERIFIED | `.planning/phases/16-expansion-discovery/16-EXPANSION-RECOMMENDATION.md:37-43` states the phase is recommendation-only and preserves migration notes such as `customer location`, `recurring-item migration`, `host-authorized export delivery`, `owner_type`, `owner_id`, and `separate-package` thinking. |
| 5 | Roadmap, requirements, and project records preserve the recommendation-only outcome for later planning. | ✓ VERIFIED | `.planning/ROADMAP.md:124`, `.planning/REQUIREMENTS.md:51-54`, and `.planning/PROJECT.md:242-246` all carry the same ranking and explicitly say no v1.2 implementation is implied. |
| 6 | Checked-in docs contract and validation evidence reliably verify the exact ranked candidate-to-outcome mapping. | ✗ FAILED | `accrue/test/accrue/docs/expansion_discovery_test.exs:21-28` only checks that candidate names and ranking labels appear somewhere in the file. The review warning in `.planning/phases/16-expansion-discovery/16-REVIEW.md:31-43` is correct: the test does not bind each candidate to its expected outcome or order. |

**Score:** 5/6 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `.planning/phases/16-expansion-discovery/16-EXPANSION-RECOMMENDATION.md` | Canonical ranked recommendation artifact for all four expansion candidates | ✓ VERIFIED | Exists, is substantive, and directly contains the exact ranked rows plus migration and security guidance. |
| `accrue/test/accrue/docs/expansion_discovery_test.exs` | Executable docs contract for the Phase 16 recommendation artifact | ⚠️ HOLLOW | Exists and runs, but its assertions do not prove the exact ranked mapping they are used to validate. |
| `.planning/phases/16-expansion-discovery/16-VALIDATION.md` | Per-task verification map aligned to the recommendation artifact and docs contract | ⚠️ PARTIAL | Exists and covers DISC-01 through DISC-05, but DISC-05 relies on the hollow docs contract for its automated proof. |
| `.planning/phases/16-expansion-discovery/16-VERIFICATION.md` | Artifact-centric verification report for the recommendation and planning records | ✓ VERIFIED | Updated by this pass to reflect the docs-contract gap instead of carrying forward the earlier pass result. |
| `.planning/ROADMAP.md` | Durable Phase 16 outcome summary | ✓ VERIFIED | Preserves the ranked recommendation and recommendation-only boundary language. |
| `.planning/REQUIREMENTS.md` | Requirement traceability for DISC-01 through DISC-05 plus future requirement handoff | ✓ VERIFIED | Accounts for DISC-01 through DISC-05 and records TAX-01, REV-01, PROC-08, and ORG-01 as future guidance. |
| `.planning/PROJECT.md` | Project-level milestone state and future guidance | ✓ VERIFIED | Carries the next-milestone/backlog/seed guidance and the security constraint language forward. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `.planning/phases/16-expansion-discovery/16-EXPANSION-RECOMMENDATION.md` | `accrue/test/accrue/docs/expansion_discovery_test.exs` | direct file-read docs contract | ⚠️ HOLLOW | The test reads the artifact directly, but its assertions only verify vocabulary presence, not the exact row-to-outcome mapping. |
| `.planning/phases/16-expansion-discovery/16-VALIDATION.md` | `accrue/test/accrue/docs/expansion_discovery_test.exs` | validation command map | ⚠️ PARTIAL | DISC-05 is wired to the docs test, but the linked test does not fully protect the ranked recommendation contract. |
| `.planning/phases/16-expansion-discovery/16-VERIFICATION.md` | `.planning/phases/16-expansion-discovery/16-EXPANSION-RECOMMENDATION.md` | artifact verification evidence | ✓ WIRED | This report now cites the exact ranked rows and recommendation-only boundary language from the artifact. |
| `.planning/REQUIREMENTS.md` | `.planning/PROJECT.md` | future milestone and product expansion recording | ✓ WIRED | Both files preserve TAX-01, REV-01, PROC-08, and ORG-01 with the same recommendation-only scope. |
| `.planning/ROADMAP.md` | `.planning/phases/16-expansion-discovery/16-EXPANSION-RECOMMENDATION.md` | phase detail and recommendation outcome | ✓ WIRED | The roadmap outcome matches the exact ranked entries in the phase artifact. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `accrue/test/accrue/docs/expansion_discovery_test.exs` | `recommendation` | `File.read!(@recommendation_path)` | Yes - reads the real phase artifact on disk | ⚠️ HOLLOW - real data flows into the test, but the assertions do not validate the full ranked mapping. |
| `.planning/phases/16-expansion-discovery/16-VALIDATION.md` | DISC-05 automated proof | `cd accrue && mix test test/accrue/docs/expansion_discovery_test.exs --trace` | Yes - executes the checked-in docs contract | ⚠️ PARTIAL - the upstream proof is weaker than the claim it supports. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Docs contract runs | `cd accrue && mix test test/accrue/docs/expansion_discovery_test.exs --trace` | `3 tests, 0 failures` | ✓ PASS |
| Ranked rows exist exactly as recommended | `rg -n '^\\| 1 \\| Stripe Tax support \\| Next milestone \\||^\\| 2 \\| Organization / multi-tenant billing \\| Backlog \\||^\\| 3 \\| Revenue recognition / exports \\| Backlog \\||^\\| 4 \\| Official second processor adapter \\| Planted seed \\|' .planning/phases/16-expansion-discovery/16-EXPANSION-RECOMMENDATION.md` | matched lines 30-33 | ✓ PASS |
| Validation contract references DISC coverage and threat language | `rg -n "16-EXPANSION-RECOMMENDATION\\.md|DISC-0\\[1-5\\]|Next milestone|Backlog|Planted seed|cross-tenant billing leakage|wrong-audience finance exports|tax rollout correctness|processor-boundary downgrade" .planning/phases/16-expansion-discovery/16-VALIDATION.md` | matched quick-run, DISC rows, and threat text | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| DISC-01 | 16-01, 16-02 | Tax support options are evaluated and captured as a future milestone recommendation. | ✓ SATISFIED | `.planning/phases/16-expansion-discovery/16-EXPANSION-RECOMMENDATION.md:30,39-40`; `.planning/REQUIREMENTS.md:39,51`; `.planning/PROJECT.md:242,246`. |
| DISC-02 | 16-01, 16-02 | Revenue recognition and export options are evaluated and captured as a future milestone recommendation. | ✓ SATISFIED | `.planning/phases/16-expansion-discovery/16-EXPANSION-RECOMMENDATION.md:32,41`; `.planning/REQUIREMENTS.md:40,52`; `.planning/PROJECT.md:244`. |
| DISC-03 | 16-01, 16-02 | Additional processor adapter candidates are evaluated without weakening the existing Stripe-first abstraction. | ✓ SATISFIED | `.planning/phases/16-expansion-discovery/16-EXPANSION-RECOMMENDATION.md:24,33,43,66`; `.planning/REQUIREMENTS.md:41,53`; `.planning/PROJECT.md:245`. |
| DISC-04 | 16-01, 16-02 | Organization and multi-tenant billing flows are evaluated against Sigra and host-owned schema constraints. | ✓ SATISFIED | `.planning/phases/16-expansion-discovery/16-EXPANSION-RECOMMENDATION.md:31,42,63`; `.planning/REQUIREMENTS.md:42,54`; `.planning/PROJECT.md:243`. |
| DISC-05 | 16-01, 16-02 | Expansion candidates are ranked into a recommended next implementation milestone, backlog, or planted seed. | ✓ SATISFIED | The artifact itself contains the exact ranked rows at `.planning/phases/16-expansion-discovery/16-EXPANSION-RECOMMENDATION.md:30-33`, and the same outcome is preserved in `.planning/ROADMAP.md:124`. The automated docs proof for this requirement is still too weak, which is the gap recorded above. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `accrue/test/accrue/docs/expansion_discovery_test.exs` | 21 | Keyword-only assertion for ranked recommendation | 🛑 Blocker | A malformed or reordered ranking can pass the docs contract, so the checked-in verification evidence does not fully protect the Phase 16 outcome. |
| `.planning/phases/16-expansion-discovery/16-VALIDATION.md` | 45 | DISC-05 relies on weak upstream proof | ⚠️ Warning | Validation inherits the same blind spot for the most important ranking contract. |

### Gaps Summary

Phase 16's recommendation artifact and the durable planning records do achieve the discovery goal: the options are evaluated, ranked, and carried into roadmap, requirements, and project context without implying v1.2 implementation. The blocking gap is narrower but still real: the checked-in docs contract does not actually verify the exact ranked mapping that the phase relies on for durable proof.

That matters because Plan 16-01 explicitly promised an executable docs contract for the recommendation artifact, and Plan 16-02 uses that contract as evidence for DISC-05. Right now the evidence would still pass if the document mentioned the same candidate names and ranking labels in the wrong rows or wrong order. Until the contract asserts the exact ranked rows, the phase cannot be marked fully verified.

---

_Verified: 2026-04-17T14:33:21Z_
_Verifier: Codex (gsd-verifier)_
