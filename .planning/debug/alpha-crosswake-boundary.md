---
status: resolved
trigger: "UAT gap G-220-1: Truth: Capability remains feasibility_blocked until both bridge-compile and physical-device evidence are present; no public material promotes it from fixture or server evidence. Actual user report: Alpha is a B2C offline language-learning app being developed in another repo; Accrue and CrossWake should prepare for a first/early adopter and any native or billing ties must match. Diagnose why Phase 220 artifacts did not make the Alpha readiness relationship and deliberate CrossWake boundary understandable."
created: 2026-08-05T14:58:13Z
updated: 2026-08-05T20:42:00Z
---

## Current Focus
<!-- OVERWRITE on each update - reflects NOW -->

bug_class: bohrbug
hypothesis: The Phase 220 human-verification/UAT wording reduces CrossWake evidence to a fail-closed promotion condition, while its Phase goal calls Alpha only an anonymized reference host; neither provides the missing integration narrative that distinguishes (1) Accrue's deterministic library/host contract proof, (2) CrossWake's separate runtime-feasibility proof, and (3) the real Alpha app in another repository.
test: Search the requested Phase 220, roadmap, state, and context artifacts for an explicit external-repository, real-Alpha, or Alpha-to-CrossWake relationship statement; compare the absence/presence with the report's confusion.
expecting: If the hypothesis is true, artifacts will state the blocked status and anonymized-reference scope but contain no relationship/ownership map explaining why evidence is needed or what it does not prove.
next_action: Closed by Phase 220 Plan 23; retain the external runtime and Alpha evidence boundaries as documented.

candidate_causes:
  - "docs: UAT and verification describe the gate result but not its product purpose or boundary among Accrue, CrossWake, and Alpha."
  - "data: the planning record deliberately anonymizes Alpha and contains no durable external-repo/integration mapping for the real first-adopter workflow."
and_gate: "no — the absent explanatory boundary is sufficient to cause the reported confusion; anonymization constrains detail but does not prevent a high-level ownership/evidence map."

## Symptoms
<!-- Written during gathering, then IMMUTABLE -->

expected: Phase 220 release/UAT artifacts explain that Accrue's capability proof is bounded to CrossWake feasibility evidence, while making clear how that work supports—but does not represent proof for—the separate Alpha B2C offline language-learning first adopter.
actual: The reporter cannot tell what capability evidence is sought or how CrossWake relates to Alpha, Accrue, and first-adopter production readiness.
errors: G-220-1 scope/communication gap; no runtime error reported.
reproduction: Read Phase 220 UAT and release artifacts without the reporter's cross-repo context, then attempt to identify the target first adopter, the purpose of CrossWake evidence, and what is deliberately out of scope.
started: Observed during Phase 220 UAT review on 2026-08-05.

## Eliminated
<!-- APPEND only - prevents re-investigating -->

## Evidence
<!-- APPEND only - facts discovered -->

- timestamp: 2026-08-05T14:59:34Z
  checked: Knowledge-base and semantic recall availability
  found: MemPalace is unavailable and no .planning/debug/knowledge-base.md exists, so no prior-resolution candidate was available.
  implication: Diagnosis relies on the current artifacts rather than a known-pattern match.

- timestamp: 2026-08-05T15:00:21Z
  checked: Requested UAT, verification report, roadmap, state, and Plan 220-20
  found: UAT test 1 and the retained human-verification item ask only whether CrossWake remains feasibility_blocked pending bridge/device evidence; Plan 220-20 similarly directs Swift to remain a fixture/vector decoder and assert the blocked status.
  implication: These artifacts correctly protect truthfulness but answer only whether promotion is allowed, not why this evidence is being sought for Alpha adoption.

- timestamp: 2026-08-05T15:00:57Z
  checked: Phase 220 context, roadmap, and architecture signal
  found: They call Alpha an anonymized reference host/driving scenario, state that CrossWake is a host-owned boundary with no Accrue runtime dependency, and require clear evidence lanes; the phrase search found no external-repository or real-Alpha/CrossWake relationship statement in the requested release artifacts.
  implication: The intended separation exists as technical constraints, but no audience-facing map connects it to the separate production application reported by the user.

- timestamp: 2026-08-05T15:01:31Z
  checked: Alternative hypothesis that a missing technical guard caused the concern
  found: The verification report records Swift tests and the checked-in report as fail-closed, and the context explicitly forbids fixtures, browser, simulator, or vector output from promoting runtime feasibility.
  implication: The concern is not an absent capability guard; it is a planning/release-communication omission.

## Resolution
<!-- OVERWRITE as understanding evolves -->

root_cause: Phase 220's UAT/release artifacts present CrossWake evidence only as a `feasibility_blocked` promotion gate and label Alpha only as an anonymized reference host. They omit a concise ownership/evidence map explaining that Accrue proves the reusable billing/offline contract, CrossWake evidence separately gates any real mobile-runtime claim, and the actual Alpha app remains a separate integration target. This made the evidence request appear disconnected from first-adopter readiness.
fix: Added the hand-authored Phase 220 readiness boundary, synchronized UAT/verification/roadmap references, and kept actual Alpha/Crosswake integration proof in its owning repository.
verification: `bash scripts/ci/verify_release_contract.sh` passed with the readiness-boundary contract and the Crosswake report still `feasibility_blocked`.
files_changed: [.planning/phases/220-first-adopter-proof-and-release-gates/220-ALPHA-CROSSWAKE-READINESS-BOUNDARY.md, .planning/phases/220-first-adopter-proof-and-release-gates/220-UAT.md, .planning/phases/220-first-adopter-proof-and-release-gates/220-VERIFICATION.md, .planning/ROADMAP.md]
