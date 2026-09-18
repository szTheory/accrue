---
phase: quick-260917-l7v
plan: 01
subsystem: ci
tags: [ci, verification, node-test, shift-left, guards, leak-census, pr-body]
status: complete
human_judgment: false

requires:
  - phase: 232-bounded-hygiene-release-handoff
    provides: verify_pr_body_contract.mjs, verify_ci_script_contract.mjs, collect_window_dispositions.mjs (UNSAFE_PATH_PATTERN), the merged PR #45 the SL-C baseline is minted at
provides:
  - SL-E, a completion-mark evidence gate — a requirement marked Complete must carry verification and coverage evidence, bidirectionally
  - SL-A, a typed claims sidecar with a frozen evaluator table — the JSON is the authority, the markdown is a byte-exact projection, and CI never executes committed text
  - SL-B, claim ref fields must name explicit remote refs, never bare local branches
  - SL-C, a repo-wide sensitive-reference census, scope-locked to .planning/ with a one-directional count ratchet and no CI secrets
  - SL-D, a ban on the pipefail/SIGPIPE `grep -q` idiom in scripts/ci
  - SL-G, an artifact fixed-point and derivation-cycle guard whose covered-input digest is GSD's digest, byte-for-byte
  - SL-F, a committed-PR-body-matches-live-PR-body gate that fails closed on a missing credential
affects: [229, 230, 231, 232, release-integration-hygiene-milestone-closeout]

actuals:
  tasks: 7
  commits: 7

tech-stack:
  added: []
  patterns:
    - "A gate's oracle must be a different implementation than the thing under test. SL-G's first cut compared computeDigest(x) to computeDigest(x) — a self-referential oracle that holds for any deterministic formula, including the wrong one. Replaced with a golden vector cross-checked against the live GSD runtime, a canonicalization-equivalence case, and a negative control over the superseded formula."
    - "When two guards written in different files must agree on one definition, assert the agreement in a named scenario. SL-A renders the PR declaration from the sidecar and SL-F strips it before comparing; a CROSS-GATE scenario proves the two definitions round-trip."
    - "Measure the property, not a correlate. SL-C replaced a per-file `grep -c <one file> -> 0` with a repo-wide census whose primary invariant is a scope lock (never reaches a Hex tarball), not a count."
    - "A gate that reddens on a routine correct operation gets deleted. SL-C records per-path counts for diagnostics but enforces only the total, because milestone archiving moves every phase directory."
    - "Fail closed, never skip. SL-F treats an unavailable credential as a failure and says so in its own message; the header records the transient-red cost where a maintainer reads it before muting the gate."

key-files:
  created:
    - scripts/ci/verify_completion_evidence.mjs
    - scripts/ci/render_pr_claims.mjs
    - scripts/ci/verify_pr_claims.mjs
    - scripts/ci/verify_pipefail_grep_idiom.mjs
    - scripts/ci/verify_artifact_fixed_point.mjs
    - scripts/ci/verify_sensitive_token_census.mjs
    - scripts/ci/verify_pr_body_currency.mjs
    - .planning/hygiene/sensitive-token-census.json
  modified:
    - .github/workflows/ci.yml
    - scripts/ci/verify_ci_script_contract.mjs
    - scripts/ci/verify_provider_proof.mjs
    - .planning/phases/232-bounded-hygiene-release-handoff/232-INTEGRATION-PR.json
    - .planning/phases/232-bounded-hygiene-release-handoff/232-INTEGRATION-PR.md
---

# Quick task 260917-l7v — shift left seven phase-232 session failure modes

All seven guards are merge-blocking in `docs-contracts-shift-left`. None has
`continue-on-error`. Every one carries named negative controls that fail, and
positive controls that pass, in its own `node --test` suite plus a hermetic
`--fixtures` battery.

## What each guard measures

| Req | Guard | Measures |
|-----|-------|----------|
| SL-E | `verify_completion_evidence.mjs` | A requirement marked `Complete` carries a passing verification and a UAT/SUMMARY citation of its ID — bidirectionally. |
| SL-A | `verify_pr_claims.mjs` + `render_pr_claims.mjs` | A committed PR claim is a typed record evaluated by a frozen table; the markdown is byte-exactly re-derivable from the JSON sidecar; no committed string ever becomes a program name, a flag, or a shell word. |
| SL-B | (in SL-A's module) | A claim ref naming a bare local branch instead of an explicit `origin/` ref fails. |
| SL-C | `verify_sensitive_token_census.mjs` | The censused reference may appear only under `.planning/`, never in anything reaching a Hex tarball; the total may only decrease. |
| SL-D | `verify_pipefail_grep_idiom.mjs` | A newly written non-builtin-producer `grep -q`/`grep -v` pipeline under `set -euo pipefail` in `scripts/ci`. |
| SL-G | `verify_artifact_fixed_point.mjs` | No generated artifact derives from a field of the artifact that checksums it; a committed `covered_digest` matches GSD's own fingerprint formula. |
| SL-F | `verify_pr_body_currency.mjs` | A committed PR-body file declaring a PR number matches that PR's live body. |

## Findings the guards produced on their own first runs

- **SL-G found a defect in SL-G.** Its first cut invented a rolling `path \0 bytes \0`
  hash and stamped it `v1:sha256:` — the tag GSD's covered-input fingerprint already
  owns. Two writers, one field, one version namespace, and `FINGERPRINT_VERSION` could
  not arbitrate. SL-G read phase 232 as matching while GSD read it as permanently stale.
  The test that let it through compared `computeDigest(x)` to `computeDigest(x)`.
- **SL-F found real drift on its first live run.** PR #45's published body still claimed
  "documentation-only merges" where the committed copy had already corrected that to
  "later merges" because the original was measurably false. Reconciled with `gh pr edit`.
- **SL-C's live negative controls both trip.** A probe under `accrue/lib/` trips the
  scope lock naming the package glob; one extra occurrence inside `.planning/` trips the
  ratchet naming both counts. Neither message repeated the reference.
- **`verify_provider_proof.mjs` caught SL-F widening workflow permissions**, which is
  exactly what that interlock exists for. Updated deliberately, with a new assertion that
  no `write` scope may ever appear in the top-level permissions block.

## Measured baselines, recorded so a future audit re-measures rather than trusting them

- SL-C census at merge commit `3ccea474`: **57 occurrences across 18 files**, all under
  `.planning/`. `origin/main` has zero outside that tree.
- SL-D: **36** pipelines into `grep -q`/`-qv` under `scripts/ci`, of which **3** had
  non-builtin producers. All three were fixed, not allowlisted; the allowlist is empty.
- `COMMITTED_COHORT_FLOOR` re-measured live 2026-09-17: **41 → 55**.

## Deferred

- **Full shellcheck adoption for the 53 unlinted shell guards under `scripts/ci`.** A
  substantially larger win than SL-D's single rule. Mandatory caveat for whoever picks it
  up: shellcheck's own **SC2143 actively recommends the exact footgun SL-D bans**, so any
  adoption must include `disable=SC2143` or the linter will argue for reintroducing it.
- **Phases 230 and 231 carry an `advisory`**, not a clean pass. Each declares one
  phase-time proof that structurally cannot reproduce — 230's integration record binds to
  a mutable ref *name* that phase 232 re-cut, 231's window record asserts an exact 1:1
  join against an append-only ledger that phase 232 grew. Both are recorded in their
  `*-VERIFICATION.md`; neither is a behavior regression.
