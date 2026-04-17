# Phase 16: Expansion Discovery - Pattern Map

**Mapped:** 2026-04-17
**Files analyzed:** 9
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/phases/16-expansion-discovery/16-RESEARCH.md` | config | request-response | `.planning/phases/15-trust-hardening/15-TRUST-REVIEW.md` | role-match |
| `.planning/phases/16-expansion-discovery/16-EXPANSION-RECOMMENDATION.md` or in-place finalization of `16-RESEARCH.md` | config | request-response | `.planning/phases/15-trust-hardening/15-TRUST-REVIEW.md` | partial |
| `.planning/phases/16-expansion-discovery/16-VERIFICATION.md` | config | request-response | `.planning/phases/15-trust-hardening/15-VERIFICATION.md` | exact |
| `.planning/phases/16-expansion-discovery/16-VALIDATION.md` | config | request-response | `.planning/phases/16-expansion-discovery/16-VALIDATION.md` | exact |
| `accrue/test/accrue/docs/expansion_discovery_test.exs` | test | batch | `accrue/test/accrue/docs/trust_review_test.exs` | role-match |
| `scripts/ci/verify_package_docs.sh` | utility | batch | `scripts/ci/verify_package_docs.sh` | exact |
| `.planning/ROADMAP.md` | config | request-response | `.planning/ROADMAP.md` | exact |
| `.planning/REQUIREMENTS.md` | config | request-response | `.planning/REQUIREMENTS.md` | exact |
| `.planning/PROJECT.md` | config | request-response | `.planning/PROJECT.md` | exact |

## Pattern Assignments

### `.planning/phases/16-expansion-discovery/16-EXPANSION-RECOMMENDATION.md` or final `16-RESEARCH.md` (config, request-response)

**Closest analog:** [`15-TRUST-REVIEW.md`](/Users/jon/projects/accrue/.planning/phases/15-trust-hardening/15-TRUST-REVIEW.md:1)

There is no exact precedent for a standalone ranked expansion-decision document. Use a composite pattern:
- copy frontmatter, section discipline, verification-runs footer, and sign-off shape from [`15-TRUST-REVIEW.md`](/Users/jon/projects/accrue/.planning/phases/15-trust-hardening/15-TRUST-REVIEW.md:1)
- copy the ranking table, assumptions log, and open-questions structure already drafted in [`16-RESEARCH.md`](/Users/jon/projects/accrue/.planning/phases/16-expansion-discovery/16-RESEARCH.md:254)

**Frontmatter + checked-in artifact pattern** ([`15-TRUST-REVIEW.md:1`](/Users/jon/projects/accrue/.planning/phases/15-trust-hardening/15-TRUST-REVIEW.md:1)):
```md
---
phase: 15
slug: trust-hardening
status: verified
threats_open: 0
asvs_level: default
created: 2026-04-17
requirements:
  - TRUST-01
  - TRUST-05
  - TRUST-06
---
```

**Ranking table shape to preserve** ([`16-RESEARCH.md:254`](/Users/jon/projects/accrue/.planning/phases/16-expansion-discovery/16-RESEARCH.md:254)):
```md
## Ranked Recommendation

| Rank | Candidate | Outcome | User Value | Architecture Impact | Risk | Prerequisites |
|------|-----------|---------|------------|---------------------|------|---------------|
| 1 | Stripe Tax support | **Next milestone** | ... | ... | ... | ... |
| 2 | Organization / multi-tenant billing | **Backlog** | ... | ... | ... | ... |
| 3 | Revenue recognition / exports | **Backlog** | ... | ... | ... | ... |
| 4 | Official second processor adapter | **Planted seed** | ... | ... | ... | ... |
```

**Assumptions + open questions pattern** ([`16-RESEARCH.md:263`](/Users/jon/projects/accrue/.planning/phases/16-expansion-discovery/16-RESEARCH.md:263)):
```md
## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | ... | Ranked Recommendation | ... |

## Open Questions

1. **What finance workflow should Accrue optimize first...**
   - What we know: ...
   - What's unclear: ...
   - Recommendation: ...
```

**Verification-runs + sign-off pattern** ([`15-TRUST-REVIEW.md:62`](/Users/jon/projects/accrue/.planning/phases/15-trust-hardening/15-TRUST-REVIEW.md:62)):
```md
### Verification Runs

- `cd accrue && mix test test/accrue/docs/... --trace`
- `bash scripts/ci/verify_package_docs.sh`

## Sign-Off

- [x] ...
**Approval:** verified 2026-04-17
```

Use this artifact as the single human-readable recommendation source. Do not spread ranking conclusions across multiple phase files without one canonical table.

---

### `.planning/phases/16-expansion-discovery/16-VERIFICATION.md` (config, request-response)

**Analog:** [`15-VERIFICATION.md`](/Users/jon/projects/accrue/.planning/phases/15-trust-hardening/15-VERIFICATION.md:1)

**Verification frontmatter + goal block** ([`15-VERIFICATION.md:1`](/Users/jon/projects/accrue/.planning/phases/15-trust-hardening/15-VERIFICATION.md:1)):
```md
---
phase: 15-trust-hardening
verified: 2026-04-17T09:56:21Z
status: passed
score: 7/7 must-haves verified
overrides_applied: 0
---

# Phase 15: Trust Hardening Verification Report
```

**Observable truths table pattern** ([`15-VERIFICATION.md:16`](/Users/jon/projects/accrue/.planning/phases/15-trust-hardening/15-VERIFICATION.md:16)):
```md
## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | ... | ✓ VERIFIED | ... |
```

**Required artifacts + wiring table pattern** ([`15-VERIFICATION.md:32`](/Users/jon/projects/accrue/.planning/phases/15-trust-hardening/15-VERIFICATION.md:32), [`15-VERIFICATION.md:47`](/Users/jon/projects/accrue/.planning/phases/15-trust-hardening/15-VERIFICATION.md:47)):
```md
### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
```

**Requirements coverage pattern** ([`15-VERIFICATION.md:78`](/Users/jon/projects/accrue/.planning/phases/15-trust-hardening/15-VERIFICATION.md:78)):
```md
### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
```

For Phase 16, the evidence rows should point to the recommendation artifact, its docs contract, `16-VALIDATION.md`, and any roadmap/requirements updates. Keep the report artifact-centric; there should be no runtime-code claims here.

---

### `.planning/phases/16-expansion-discovery/16-VALIDATION.md` (config, request-response)

**Analog:** [`16-VALIDATION.md`](/Users/jon/projects/accrue/.planning/phases/16-expansion-discovery/16-VALIDATION.md:1)

**Frontmatter + quick/full commands pattern** ([`16-VALIDATION.md:1`](/Users/jon/projects/accrue/.planning/phases/16-expansion-discovery/16-VALIDATION.md:1), [`16-VALIDATION.md:16`](/Users/jon/projects/accrue/.planning/phases/16-expansion-discovery/16-VALIDATION.md:16)):
```md
---
phase: 16
slug: expansion-discovery
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-17
---

| **Framework** | ExUnit / Mix task contracts plus grep-backed docs contracts |
| **Quick run command** | `rg -n "DISC-0[1-5]" .planning/phases/16-expansion-discovery/*.md` |
| **Full suite command** | `cd examples/accrue_host && mix verify.full` |
```

**Per-task verification map pattern** ([`16-VALIDATION.md:37`](/Users/jon/projects/accrue/.planning/phases/16-expansion-discovery/16-VALIDATION.md:37)):
```md
| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 16-01-01 | 01 | 1 | DISC-01 | T-16-01 | ... | docs contract | `rg -n "Stripe Tax|automatic tax|customer location" ...` | no W0 | pending |
```

**Wave 0 checklist pattern** ([`16-VALIDATION.md:51`](/Users/jon/projects/accrue/.planning/phases/16-expansion-discovery/16-VALIDATION.md:51)):
```md
## Wave 0 Requirements

- [ ] Add or update a narrow docs-contract artifact that asserts the Phase 16 recommendation includes all four candidate areas plus ranking outcome.
- [ ] Decide whether the contract lives as an ExUnit docs test or a simple grep-backed script in `scripts/ci/`.
```

Keep the existing command vocabulary exactly aligned with the final recommendation artifact. If the planner renames the artifact, update the grep paths here in the same change.

---

### `accrue/test/accrue/docs/expansion_discovery_test.exs` (test, batch)

**Primary analog:** [`trust_review_test.exs`](/Users/jon/projects/accrue/accrue/test/accrue/docs/trust_review_test.exs:1)  
**Secondary analog if using shell delegation:** [`package_docs_verifier_test.exs`](/Users/jon/projects/accrue/accrue/test/accrue/docs/package_docs_verifier_test.exs:1)

**Direct file-read docs contract pattern** ([`trust_review_test.exs:4`](/Users/jon/projects/accrue/accrue/test/accrue/docs/trust_review_test.exs:4)):
```elixir
@trust_review_path Path.expand("../../../../.planning/phases/15-trust-hardening/15-TRUST-REVIEW.md", __DIR__)

test "checked-in trust review exists and covers required boundaries" do
  review = File.read!(@trust_review_path)

  assert review =~ "## Trust Boundaries"
  assert review =~ "webhook request -> raw-body verification"
end
```

**Required-evidence assertion pattern** ([`trust_review_test.exs:19`](/Users/jon/projects/accrue/accrue/test/accrue/docs/trust_review_test.exs:19)):
```elixir
test "trust review links concrete repo evidence and host-owned assumptions" do
  review = File.read!(@trust_review_path)

  assert review =~ "scripts/ci/accrue_host_uat.sh"
  assert review =~ ".github/workflows/ci.yml"
  assert review =~ "host-owned"
  assert review =~ "TRUST-01"
end
```

**Shell-wrapper test pattern if Phase 16 reuses the existing script** ([`package_docs_verifier_test.exs:6`](/Users/jon/projects/accrue/accrue/test/accrue/docs/package_docs_verifier_test.exs:6)):
```elixir
test "package docs verifier succeeds" do
  {output, status} = System.cmd("bash", [@script_path], stderr_to_stdout: true)

  assert status == 0
  assert output =~ "package docs verified"
end
```

Preferred shape for Phase 16: a narrow ExUnit test that reads the recommendation artifact directly and asserts:
- all four candidate areas appear
- ranking vocabulary includes `Next milestone`, `Backlog`, and `Planted seed`
- the doc carries user value, architecture impact, risk, and prerequisites
- processor guidance preserves Stripe-first/custom-processor language

---

### `scripts/ci/verify_package_docs.sh` (utility, batch)

**Analog:** [`verify_package_docs.sh`](/Users/jon/projects/accrue/scripts/ci/verify_package_docs.sh:1)

**Small helper-function pattern** ([`verify_package_docs.sh:9`](/Users/jon/projects/accrue/scripts/ci/verify_package_docs.sh:9)):
```bash
fail() {
  echo "package docs verification failed: $*" >&2
  exit 1
}

require_fixed() {
  local file=$1
  local needle=$2

  grep -Fq "$needle" "$file" || fail "$file is missing: $needle"
}
```

**Negative-match helper pattern** ([`verify_package_docs.sh:37`](/Users/jon/projects/accrue/scripts/ci/verify_package_docs.sh:37)):
```bash
require_absent_regex() {
  local file=$1
  local pattern=$2

  if grep -Eq "$pattern" "$file"; then
    fail "$file must not match: $pattern"
  fi
}
```

**Fixed-invariant scan pattern** ([`verify_package_docs.sh:106`](/Users/jon/projects/accrue/scripts/ci/verify_package_docs.sh:106)):
```bash
require_fixed "$ROOT_DIR/scripts/ci/accrue_host_uat.sh" "mix verify.full"
require_fixed "$ROOT_DIR/RELEASING.md" "required deterministic gate"
require_fixed "$ROOT_DIR/RELEASING.md" "15-TRUST-REVIEW.md"
```

If Phase 16 adds shell-backed checks, extend this script in place with the same `require_fixed` style. Do not add a second docs-verifier entrypoint unless the planner has a strong reason to separate package-doc and planning-artifact contracts.

---

### `.planning/ROADMAP.md` (config, request-response)

**Analog:** [`ROADMAP.md`](/Users/jon/projects/accrue/.planning/ROADMAP.md:36)

**Top-level phase checklist pattern** ([`ROADMAP.md:36`](/Users/jon/projects/accrue/.planning/ROADMAP.md:36)):
```md
<details open>
<summary>📋 v1.2 Adoption + Trust (Phases 13-16) — PLANNED</summary>

- [ ] Phase 16: Expansion Discovery — evaluate and rank tax, revenue/export, additional processor, and org/multi-tenant billing options for the next implementation milestone.
```

**Phase detail + success-criteria pattern** ([`ROADMAP.md:106`](/Users/jon/projects/accrue/.planning/ROADMAP.md:106)):
```md
### Phase 16: Expansion Discovery

**Goal:** Decide which mature-library expansion should come next without weakening the current Stripe-first, host-owned architecture.

**Requirements:** DISC-01, DISC-02, DISC-03, DISC-04, DISC-05

**Success criteria:**
1. Tax, revenue/export, additional processor, and org/multi-tenant options each have a decision-quality recommendation.
```

When Phase 16 is complete, update both the summary checklist row and the phase-detail section in place. Keep the success-criteria numbering style and one-line phase summary format unchanged.

---

### `.planning/REQUIREMENTS.md` (config, request-response)

**Analog:** [`REQUIREMENTS.md`](/Users/jon/projects/accrue/.planning/REQUIREMENTS.md:37)

**Discovery requirement list pattern** ([`REQUIREMENTS.md:37`](/Users/jon/projects/accrue/.planning/REQUIREMENTS.md:37)):
```md
### Expansion Discovery

- [ ] **DISC-01**: Tax support options are evaluated and captured as a future milestone recommendation.
- [ ] **DISC-05**: Expansion candidates are ranked into a recommended next implementation milestone, backlog, or planted seed.
```

**Future-requirements seed/backlog pattern** ([`REQUIREMENTS.md:45`](/Users/jon/projects/accrue/.planning/REQUIREMENTS.md:45)):
```md
## Future Requirements

### Product Expansion

- **TAX-01**: First-party tax calculation or Stripe Tax orchestration.
- **REV-01**: Revenue recognition exports or accounting-system handoff.
- **PROC-08**: First-party non-Stripe processor adapter.
- **ORG-01**: Organization-first billing flows once Sigra organization support is ready.
```

**Traceability table pattern** ([`REQUIREMENTS.md:68`](/Users/jon/projects/accrue/.planning/REQUIREMENTS.md:68)):
```md
## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DISC-01 | Phase 16 | Pending |
| DISC-05 | Phase 16 | Pending |
```

If the final recommendation explicitly promotes `TAX-01`, `REV-01`, `PROC-08`, or `ORG-01`, keep those requirement IDs as the future-work handles instead of inventing new labels.

---

### `.planning/PROJECT.md` (config, request-response)

**Analog:** [`PROJECT.md`](/Users/jon/projects/accrue/.planning/PROJECT.md:1)

**Current milestone and key-decision pattern** ([`PROJECT.md:16`](/Users/jon/projects/accrue/.planning/PROJECT.md:16), [`PROJECT.md:190`](/Users/jon/projects/accrue/.planning/PROJECT.md:190)):
```md
## Current Milestone: v1.2 Adoption + Trust

**Goal:** Make Accrue feel ready ...

## Key Decisions

| Decision | Rationale | Outcome |
|---|---|---|
| Keep v1.2 expansion to discovery only | ... | — Pending |
```

When Phase 16 records its ranking outcome in `.planning/PROJECT.md`, append or update a project-level milestone note or key-decision row instead of creating a new freeform section. Keep the wording recommendation-only, preserve `Stripe-first` and `host-owned`, and carry forward prerequisite language for `tax rollout correctness` rather than implying any tax, export, processor, or org feature shipped.

## Shared Patterns

### Checked-in Planning Artifact Frontmatter
**Source:** [`15-TRUST-REVIEW.md`](/Users/jon/projects/accrue/.planning/phases/15-trust-hardening/15-TRUST-REVIEW.md:1)  
**Apply to:** Phase-local recommendation or verification artifacts
```md
---
phase: 15
slug: trust-hardening
status: verified
created: 2026-04-17
requirements:
  - TRUST-01
---
```

### Evidence-First Docs Contract
**Source:** [`trust_review_test.exs`](/Users/jon/projects/accrue/accrue/test/accrue/docs/trust_review_test.exs:6)  
**Apply to:** Any Phase 16 ExUnit contract
```elixir
review = File.read!(@trust_review_path)
assert review =~ "## Trust Boundaries"
assert review =~ "host-owned"
assert review =~ "TRUST-01"
```

### Grep Vocabulary for Ranking
**Source:** [`16-VALIDATION.md`](/Users/jon/projects/accrue/.planning/phases/16-expansion-discovery/16-VALIDATION.md:41)  
**Apply to:** Docs tests, shell verifiers, and verification evidence
```text
"Stripe Tax|automatic tax|customer location"
"Revenue Recognition|Sigma|Data Pipeline|CSV"
"planted seed|single provider|separate package|custom processor"
"Sigra|owner_type|owner_id|foreign keys|query prefixes"
"Next milestone|Backlog|Planted seed|Ranked Recommendation"
```

### Single Canonical Table for Ranking
**Source:** [`16-RESEARCH.md`](/Users/jon/projects/accrue/.planning/phases/16-expansion-discovery/16-RESEARCH.md:254)  
**Apply to:** Recommendation artifact, verification report, roadmap handoff
```md
| Rank | Candidate | Outcome | User Value | Architecture Impact | Risk | Prerequisites |
```

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `.planning/phases/16-expansion-discovery/16-EXPANSION-RECOMMENDATION.md` as a standalone ranked decision doc | config | request-response | The repo has checked-in review and verification artifacts, but no exact precedent for a dedicated roadmap-ranking document. Use the trust-review artifact structure plus the ranking/assumptions tables already present in `16-RESEARCH.md`. |

## Metadata

**Analog search scope:** `.planning/phases/13-*`, `.planning/phases/14-*`, `.planning/phases/15-*`, `.planning/phases/16-*`, `.planning/milestones/`, `accrue/test/accrue/docs/`, `scripts/ci/`, repo-root docs  
**Files scanned:** 13  
**Pattern extraction date:** 2026-04-17
