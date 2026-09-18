---
phase: 229-repository-truth-recovery-safety
plan: 20
subsystem: infra
tags: [ci, repository-inventory, handoff, capture-ancestry, attestation, recovery-capsule]

requires:
  - phase: 229-17
    provides: "Later-commit capture authority and proven same-ref ancestry for the live comparison"
  - phase: 229-18
    provides: "Stable private-input reading and the fixed workflow-metadata authorization input"
  - phase: 229-19
    provides: "Canonical output pinning, transactional publish with rollback, schema-v2 attestation binding"
provides:
  - "The final recovery-backed canonical repository inventory pair (REPO-01/02/03 evidence), captured live_remote"
  - "One schema-v2 round-3 handoff attestation, the sole addition to the immutable recovery capsule"
  - "assertCapturedRefContinuity: manifest-to-capture active-ref ancestry, replacing exact ref equality"
  - "CR-03 regression covering a capsule frozen before the capture commit, on a milestone branch distinct from main"
affects: [230, repository-inventory-verification, phase229-final-handoff]

actuals:
  tokens: 31000
  tasks: 2
  commits: 3

plan_head_before: 51dcddf6

tech-stack:
  added: []
  patterns:
    - "frozen-authority comparison that requires same-ref ancestry, not equality, for the one ref expected to advance while the phase runs"
    - "divergence negative built from a same-tree root commit, so working tree, index and tracked set stay byte-identical and only the ancestry check can reject it"

key-files:
  created:
    - .planning/phases/229-repository-truth-recovery-safety/229-20-SUMMARY.md
  modified:
    - .planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.json
    - .planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.md
    - scripts/ci/verify_repository_inventory.mjs
    - scripts/ci/phase229_gap_closure.test.mjs

key-decisions:
  - "Task 1 proved the A-to-B-to-C property (publish at A, commit the pair at B, commit a later phase artifact at C) in a generated repository before the real capsule was touched. This is the property Task 2 depends on: without it, the act of committing the inventory would invalidate the inventory."
  - "The generated-capsule fixtures mint the capsule and capture the inventory at the same commit, which made an entire class of gap invisible to them. A real capsule is minted once, early, and is then immutable for the rest of the phase, so at capture time the manifest has frozen the active execution ref many commits in the past. Task 1's A-to-B-to-C test covered ancestry AFTER capture and still could not see this."
  - "assertStrictRecovery compared the frozen manifest refs to the freshly captured refs with exact equality on every ref, so a capsule older than its capture could never verify - directly contradicting this plan's own must-have that strict verification survive later active-branch commits. Replaced with assertCapturedRefContinuity: missing, extra and changed stay exact for every frozen ref except the active one, which must instead prove that the frozen object is still reachable from the captured commit."
  - "Chose proven ancestry over a blanket active-ref exemption. A blanket skip would have accepted any object at all for the single ref the manifest exists to freeze. The regression's negative uses a same-tree root commit precisely because it leaves every other invariant satisfied, so only ancestry can reject it."
  - "The recovery bundle was mode 0644 and the hardened verifier requires 0600 or stricter, so the capsule predated its own access-control rule. Tightened the bundle to 0600 with maintainer approval. This is a deliberate, recorded exception to the mode-immutability criterion: it removes access rather than granting it, and leaves bytes, digest, type and owner unchanged."
  - "Remote facts were obtained under terminal proof, so the published inventory is live_remote rather than recording an honest-unavailable state."

requirements-completed: [REPO-01, REPO-02, REPO-03]

coverage:
  - id: D1
    description: "The published canonical pair stays strictly verifiable at its capture commit, after the pair itself is committed, and after later phase artifacts are committed, because capture ancestry and the external attestation bind the immutable inventory bytes."
    requirement: REPO-01
    verification:
      - kind: unit
        ref: "scripts/ci/phase229_gap_closure.test.mjs#CR-03 published canonical pair stays strictly verifiable after its own commit and later phase commits"
        status: pass
      - kind: integration
        ref: "verify_repository_inventory.mjs strict run against the real capsule at capture commit A, at canonical commit B, and at summary commit C"
        status: pass
    human_judgment: false
  - id: D2
    description: "Strict recovery accepts an active execution ref that advanced past the manifest freeze only when the frozen object remains an ancestor of the captured commit, and rejects a diverged ref whose working tree, index and tracked set are otherwise byte-identical."
    requirement: REPO-02
    verification:
      - kind: unit
        ref: "scripts/ci/phase229_gap_closure.test.mjs#CR-03 strict recovery accepts an active ref advanced past the manifest freeze and rejects a diverged one"
        status: pass
    human_judgment: false
  - id: D3
    description: "The original recovery capsule stays byte, type, owner and digest immutable across the real chain; exactly one pre-named absent round-3 attestation is added as a current-owner mode-0600 regular file whose schema-v2 body binds every capture, manifest, bundle, authorization, collection-attestation, records and rendered digest."
    requirement: REPO-02
    verification:
      - kind: integration
        ref: "node scripts/ci/verify_phase229_handoff_invariants.mjs --self-test (capsule identity invariants: content-digest, link-digest, type-swap, mode, owner, extra-entry, exclusive-attestation)"
        status: pass
      - kind: integration
        ref: "node --test scripts/ci/phase229_gap_closure.test.mjs#final handoff capsule snapshots reject real filesystem identity drift"
        status: pass
    human_judgment: false
  - id: D4
    description: "The final chain stays facts, recovery and read-only CI observation only, performing no integration, cleanup, remote mutation, window resolution, push, merge or publication."
    requirement: REPO-03
    verification:
      - kind: unit
        ref: "scripts/ci/verify_phase229_handoff_invariants.mjs --self-test (fixed read-only child/API registry)"
        status: pass
    human_judgment: false
duration: unknown (real-capsule session)
completed: 2026-09-15
status: complete
---

# 229-20: Final canonical repository-truth handoff

## What shipped

The authoritative Phase 229 evidence pair is published and independently verified
against the real recovery capsule, and the capsule gained exactly one round-3
attestation and nothing else.

Task 1 proved the whole transaction in a generated repository and capsule first:
capture at A, transactionally publish, commit the pair at B, commit a later phase
artifact at C, and rerun strict verification at each point, with byte-level
negatives for tampered records, tampered rendered output and a substituted
attestation. Task 2 then ran the real chain.

## Issues encountered

Two real blockers surfaced only against the real capsule, both invisible to the
generated fixtures.

The recovery bundle was mode 0644 while the hardened verifier requires 0600 or
stricter. The capsule was minted before the access-control rule that now governs
it. Resolved by tightening the bundle, with maintainer approval, to 0600.

More significantly, strict recovery required the frozen manifest refs to equal the
freshly captured refs exactly. Because the capsule is minted once and is then
immutable, the manifest had frozen the active execution ref 127 commits before
the capture, so the comparison could never pass for any real capsule. The
generated fixtures mint and capture at the same commit, which is exactly why
neither this plan's own Task 1 test nor any earlier suite caught it. Fixed by
requiring same-ref ancestry for the active ref instead of equality, and covered by
a regression that advances the active ref past the freeze before capturing.

## Follow-up

The canonical inventory faithfully records two pre-existing refs whose names
embed a downstream adopter's product name. Those refs exist locally and on the
public origin and predate this plan; the same names are already present in the
previously committed inventory. Renaming them is remote mutation and therefore
outside this phase's D-10 boundary, and it would additionally invalidate the
frozen manifest. Left for a later decision.
