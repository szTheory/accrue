---
phase: 159-linked-release-readiness-publish-proof
verified: 2026-05-31T18:26:27Z
status: gaps_found
score: 4/9 must-haves verified
overrides_applied: 0
gaps:
  - truth: "Maintainer can verify the next linked release line after 1.3.0 has coherent package versions, changelog entries, Release Please state, git tags, and runbook instructions across accrue, accrue_admin, and accrue_portal."
    status: failed
    reason: "No open combined Release Please PR exists for a version after 1.3.0; verification target line does not exist yet."
    artifacts:
      - path: ".planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md"
        issue: "PR_NUMBER/TARGET_VERSION fields remain unpopulated for a post-1.3.0 line."
    missing:
      - "A live combined Release Please PR for a target version > 1.3.0"
      - "Successful verify_release_pr_scope evidence for that PR/version pair"
  - truth: "The linked Hex release is published in documented order and canonical proof is recorded in planning, changelogs, and release notes."
    status: failed
    reason: "No valid Release Please publish RUN_ID exists for a post-1.3.0 line; post-publish proof capture cannot be truthfully completed."
    artifacts:
      - path: ".planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md"
        issue: "RUN_ID is empty and post-publish sections are placeholders for the next line."
      - path: "scripts/ci/capture_linked_release_proof.sh"
        issue: "Script is ready, but cannot run successfully without an actual merged release PR and successful release run for >1.3.0."
    missing:
      - "A successful release-please workflow run for target > 1.3.0"
      - "Captured proof block from capture_linked_release_proof.sh for that run"
  - truth: "Phase completion requires all three package tags, GitHub releases, Hex package versions, HexDocs pages, and host Hex smoke to agree with one target version."
    status: failed
    reason: "Host Hex smoke evidence is currently FAIL in ledger notes and no new post-1.3.0 line exists to reconcile."
    artifacts:
      - path: ".planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md"
        issue: "Host Hex smoke is recorded as failed due to local host route conflict."
    missing:
      - "Passing host Hex smoke in clean release-proof context"
      - "Full post-publish reconciliation for one target version > 1.3.0"
---

# Phase 159: Linked Release Readiness + Publish Proof Verification Report

**Phase Goal:** Verify and publish the next linked release line after `1.3.0` with one coherent release-truth artifact across all three packages.
**Verified:** 2026-05-31T18:26:27Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Package versions/changelog/Release Please state/tags/runbook agree for next linked line after `1.3.0` across all three packages. | ✗ FAILED | `gh pr list --repo szTheory/accrue --state open --json ...` returned `[]`; `.release-please-manifest.json` remains `1.3.0` for all three. |
| 2 | Deterministic release gate is run and documented (tests/docs/dialyzer/credo/package-docs/support/adoption/host-integration). | ✓ VERIFIED | Deterministic gate rows present in ledger and spot-check scripts pass: `verify_release_manifest_alignment`, `verify_release_contract`, `verify_release_notes_contract`. |
| 3 | Linked Hex release is published in documented order and canonical proof recorded in planning/changelogs/release notes. | ✗ FAILED | No post-`1.3.0` Release Please run ID available; `RUN_ID:` empty for target next line. |
| 4 | Canonical Phase 159 ledger reconciles release intent, deterministic gates, and post-publish public truth. | ✗ FAILED | Ledger schema exists, but intent/publish identifiers for next line are missing (`PR_NUMBER`, `TARGET_VERSION`, `RUN_ID`). |
| 5 | No release is treated as ready unless manifest/mix/changelog/release notes/runbook agree on same linked target version. | ✗ FAILED | Next linked target version does not exist yet; no auditable >`1.3.0` target to reconcile. |
| 6 | Deterministic release gate records pass/fail for release-manifest, release-contract, release-notes, package-docs, support/adoption drift, host integration. | ✓ VERIFIED | Rows present under deterministic gate bundle in phase ledger; scripts and job names are explicit. |
| 7 | `ACCRUE_ADMIN_HEX_RELEASE=1` and `ACCRUE_PORTAL_HEX_RELEASE=1` remain package-local publish-mode switches. | ✓ VERIFIED | `accrue_admin/mix.exs` and `accrue_portal/mix.exs` keep env-guarded Hex dependency resolution with local-path fallback. |
| 8 | Full post-publish proof is required; minimal Hex availability alone is insufficient. | ✓ VERIFIED | `capture_linked_release_proof.sh` enforces tags/releases/Hex/HexDocs and fails on mismatch or missing success run. |
| 9 | Phase completion requires tags/GitHub releases/Hex/HexDocs/host-smoke all aligned on one target version. | ✗ FAILED | Latest public line is `1.3.0`; no >`1.3.0` line exists, and host Hex smoke is recorded failed in ledger notes. |

**Score:** 4/9 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `.planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md` | Canonical release-truth ledger | ⚠️ HOLLOW — wired but data disconnected | Schema exists; next-line identifiers/proof (`PR_NUMBER`, `TARGET_VERSION`, `RUN_ID`) not populated. |
| `scripts/ci/verify_release_manifest_alignment.sh` | 3-package lockstep verifier | ✓ VERIFIED | Includes `accrue_portal` manifest + mix checks and lockstep failure guards. |
| `scripts/ci/capture_linked_release_proof.sh` | Post-publish proof capture | ✓ VERIFIED | Enforces run identity, PR binding, tags/releases/Hex/HexDocs snapshot. |
| `scripts/ci/README.md` | REL gate map and triage | ✓ VERIFIED | REL-01/02/03 table references Phase 159 ledger and current proof chain. |
| `RELEASING.md` | Linked-release runbook | ✓ VERIFIED | Contains fallback-only `publish-hex.yml` guidance and ordered publish instructions. |
| `accrue/guides/release-notes.md` | Target-version release-notes mirror | ✓ VERIFIED (current line) | Current release notes include `1.3.0` headings for `accrue` and `accrue_admin` and mention `accrue_portal`. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `scripts/ci/verify_release_manifest_alignment.sh` | `.release-please-manifest.json` | `jq` package-version extraction | WIRED | Verified by `gsd-sdk query verify.key-links`. |
| `scripts/ci/capture_linked_release_proof.sh` | `.github/workflows/release-please.yml` | `gh run view` on exact `RUN_ID` | WIRED | Verified by `gsd-sdk query verify.key-links`. |
| `159-VERIFICATION.md` | `scripts/ci/verify_release_pr_scope.sh` | `PR_NUMBER`/`TARGET_VERSION` audit rows | WIRED | Verified by pattern presence. |
| `159-VERIFICATION.md` | `scripts/ci/accrue_host_hex_smoke.sh` | Host Hex smoke evidence block | WIRED | Verified by pattern presence. |
| `RELEASING.md` | `.github/workflows/publish-hex.yml` | fallback-only instructions | WIRED | Verified by explicit runbook wording. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `scripts/ci/verify_release_manifest_alignment.sh` | `m_accrue/m_admin/m_portal`, `mix_*` | `.release-please-manifest.json` + package `mix.exs` | Yes | ✓ FLOWING |
| `scripts/ci/capture_linked_release_proof.sh` | `RUN_JSON`, `PR_JSON`, `hex_json` | GitHub APIs (`gh`) + Hex API (`curl`) + git tags | Yes | ✓ FLOWING |
| `159-VERIFICATION.md` | `PR_NUMBER`, `TARGET_VERSION`, `RUN_ID` | Manual + release workflow proof capture | No (for >1.3.0 line) | ✗ DISCONNECTED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Manifest lockstep gate works | `bash scripts/ci/verify_release_manifest_alignment.sh` | `OK: ... aligned at 1.3.0` | ✓ PASS |
| Linked release contract gate works | `bash scripts/ci/verify_release_contract.sh` | `OK: linked release contract aligned ...` | ✓ PASS |
| Release-notes contract gate works | `bash scripts/ci/verify_release_notes_contract.sh` | `verify_release_notes_contract: OK (1.3.0)` | ✓ PASS |
| Next release intent exists | `gh pr list --repo szTheory/accrue --state open --json number,title,url` | `[]` | ✗ FAIL |

### Probe Execution

| Probe | Command | Result | Status |
| --- | --- | --- | --- |
| Step 7c | discovery (`find scripts -path '*/tests/probe-*.sh'`) | no probes found for this phase | ? SKIP |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| REL-01 | `159-01-PLAN.md` | Verify next post-`1.3.0` linked line coherence across packages and release truth surfaces. | ✗ BLOCKED | No open combined Release Please PR for >`1.3.0`; cannot verify target line. |
| REL-02 | `159-01-PLAN.md` | Run deterministic release gate and capture one pass/fail artifact. | ✓ SATISFIED | Gate scripts pass and ledger includes deterministic gate rows. |
| REL-03 | `159-01-PLAN.md` | Publish linked release in order with canonical proof in planning/changelogs/release notes. | ✗ BLOCKED | No valid post-`1.3.0` successful publish run ID/proof block; host Hex smoke not passing in recorded evidence. |

No orphaned Phase 159 requirement IDs were found in `.planning/REQUIREMENTS.md`.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| (none) | - | No `TBD`/`FIXME`/`XXX` debt markers or placeholder stubs in reviewed phase-modified files. | ℹ️ Info | No blocker anti-patterns detected. |

### Gaps Summary

Phase 159 is not complete because the required next linked release line after `1.3.0` is not present in live Release Please state. Deterministic readiness artifacts and scripts are implemented and functioning, but publish proof cannot be fabricated: there is no post-`1.3.0` combined release PR, no corresponding successful release workflow `RUN_ID`, and no full post-publish reconciliation for a new line. REL-01 and REL-03 therefore remain blocked.

---

_Verified: 2026-05-31T18:26:27Z_  
_Verifier: the agent (gsd-verifier)_

## Preserved Ledger Evidence (From Prior Append-Only Record)

The prior Phase 159 ledger evidence is preserved below verbatim for continuity:

```markdown
# Phase 159 — Linked Release Readiness + Publish Proof — Verification

**Milestone:** v1.48  
**Status:** In progress

## Release identifiers

PR_NUMBER:
TARGET_VERSION:
RUN_ID:

- 2026-05-31T18:15:33Z: `gh pr list --repo szTheory/accrue --state open --json number,title` returned `[]`.
- 2026-05-31T18:15:33Z: `.release-please-manifest.json` is still `accrue=1.3.0`, `accrue_admin=1.3.0`, `accrue_portal=1.3.0` (already published line).
- Blocker: No live combined Release Please PR exists for a target version after `1.3.0`, so publish-phase identifiers cannot be populated yet.

## Pre-merge truth audit

| Check | Command / Source | Job | Timestamp (UTC) | Result | Notes |
|-------|------------------|-----|-----------------|--------|-------|
| release-pr-availability | `gh pr list --repo szTheory/accrue --state open --json number,title,headRefName,url` | release-manifest-ssot | 2026-05-31T18:15:33Z | FAIL | No open combined Release Please PR to audit. |
| release-target-availability | `cat .release-please-manifest.json` + `gh release list --repo szTheory/accrue --limit 3` | release-manifest-ssot | 2026-05-31T18:15:33Z | FAIL | Manifest target remains `1.3.0`, matching already-published latest line. |

## Deterministic gate bundle

| Check | Command / Source | Job | Timestamp (UTC) | Result | Notes |
|-------|------------------|-----|-----------------|--------|-------|
| release-manifest-alignment | `bash scripts/ci/verify_release_manifest_alignment.sh` | release-manifest-ssot | 2026-05-31T18:15:33Z | PASS | `OK: ... aligned at 1.3.0 (accrue, accrue_admin, accrue_portal)` |
| release-contract | `bash scripts/ci/verify_release_contract.sh` | release-manifest-ssot | 2026-05-31T18:15:33Z | PASS | Linked release contract aligned. |
| release-notes-contract | `bash scripts/ci/verify_release_notes_contract.sh` | docs-contracts-shift-left | 2026-05-31T18:15:33Z | PASS | `verify_release_notes_contract: OK (1.3.0)` |
| package-docs | `bash scripts/ci/verify_package_docs.sh` | docs-contracts-shift-left | 2026-05-31T18:15:33Z | PASS | Package docs verifier passed for 1.3.0 line. |
| support-matrix | `bash scripts/ci/verify_processor_support_matrix.sh` | docs-contracts-shift-left | 2026-05-31T18:15:33Z | PASS | Support matrix verifier passed. |
| adoption-proof-matrix | `bash scripts/ci/verify_adoption_proof_matrix.sh` | docs-contracts-shift-left | 2026-05-31T18:15:33Z | PASS | Adoption proof matrix verifier passed. |
| accrue mix test | `cd accrue && mix test --warnings-as-errors` | release-gate | 2026-05-31T18:15:33Z | PASS | Covered within `bash scripts/ci/accrue_host_uat.sh` release lane run. |
| accrue mix credo | `cd accrue && mix credo --strict` | release-gate | 2026-05-31T18:15:33Z | PASS | Covered by host release lane verification sweep for current branch state. |
| accrue mix dialyzer | `cd accrue && mix dialyzer --format github` | release-gate | 2026-05-31T18:15:33Z | PASS | Covered by host release lane verification sweep for current branch state. |
| accrue mix docs | `cd accrue && MIX_ENV=dev mix docs --warnings-as-errors` | release-gate | 2026-05-31T18:15:33Z | PASS | Covered by host release lane verification sweep for current branch state. |
| accrue_admin mix test | `cd accrue_admin && mix test --warnings-as-errors` | release-gate | 2026-05-31T18:15:33Z | PASS | Covered by host release lane verification sweep for current branch state. |
| accrue_admin mix credo | `cd accrue_admin && mix credo --strict` | release-gate | 2026-05-31T18:15:33Z | PASS | Covered by host release lane verification sweep for current branch state. |
| accrue_admin mix dialyzer | `cd accrue_admin && mix dialyzer --format github` | release-gate | 2026-05-31T18:15:33Z | PASS | Covered by host release lane verification sweep for current branch state. |
| accrue_admin mix docs | `cd accrue_admin && MIX_ENV=dev mix docs --warnings-as-errors` | release-gate | 2026-05-31T18:15:33Z | PASS | Covered by host release lane verification sweep for current branch state. |
| accrue_portal mix test | `cd accrue_portal && mix test --warnings-as-errors` | release-gate | 2026-05-31T18:15:33Z | PASS | Covered by host release lane verification sweep for current branch state. |
| host integration | `bash scripts/ci/accrue_host_uat.sh` | host-integration | 2026-05-31T18:15:33Z | PASS | Completed with 29 Playwright passed / 16 skipped in tagged lanes. |

## Publish execution

| Step | Evidence | Timestamp (UTC) | Result | Notes |
|------|----------|-----------------|--------|-------|
| release-please publish run | `.github/workflows/release-please.yml` run id for >1.3.0 line | 2026-05-31T18:15:33Z | BLOCKED | No eligible merged release PR / run for next linked line exists yet. |

## Post-publish public truth

### Workflow job ordering

_Populated by `scripts/ci/capture_linked_release_proof.sh`._

### Git tags

_Populated by `scripts/ci/capture_linked_release_proof.sh`._

### GitHub releases

_Populated by `scripts/ci/capture_linked_release_proof.sh`._

### Hex API truth

_Populated by `scripts/ci/capture_linked_release_proof.sh`._

### Release file snapshot

_Populated by `scripts/ci/capture_linked_release_proof.sh`._

### HexDocs availability

| Package | URL | HTTP |
|---------|-----|------|
| accrue | https://hexdocs.pm/accrue/readme.html | pending |
| accrue_admin | https://hexdocs.pm/accrue_admin/readme.html | pending |
| accrue_portal | https://hexdocs.pm/accrue_portal/readme.html | pending |

### Host Hex smoke

- Command: `bash scripts/ci/accrue_host_hex_smoke.sh`
- Timestamp (UTC): `2026-05-31T18:16:54Z`
- Result: `FAIL`
- Reason: local host workspace compile conflict (`attempting to redefine live_session :accrue_admin` in `examples/accrue_host/lib/accrue_host_web/router.ex`) after installer dry-run overlay; release proof remains blocked until clean publish run context is available.

## Notes

- Append-only ledger: add new dated blocks; do not rewrite prior proof rows.
- Recovery state:
  - Wait for a new combined Release Please PR that bumps all three packages past `1.3.0`.
  - Capture `PR_NUMBER` and `TARGET_VERSION`, run `bash scripts/ci/verify_release_pr_scope.sh --pr <pr> --version <target-version>`.
  - Merge PR, capture successful Release Please workflow `RUN_ID`, then run:
    - `bash scripts/ci/capture_linked_release_proof.sh --version <target-version> --run-id <run-id> --pr <pr> --output .planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md`
    - `bash scripts/ci/accrue_host_hex_smoke.sh`
    - `bash scripts/ci/verify_release_notes_contract.sh`
  - Run host Hex smoke from a clean host route state that does not redefine `live_session :accrue_admin`.

## Sign-off

- [ ] REL-01 complete (blocked: missing release PR and >1.3.0 target line)
- [x] REL-02 complete
- [ ] REL-03 complete
```

## Plan 02 Automation Handoff (2026-05-31)

Phase 159 Plan 02 moved the remaining live publish proof from manual UAT into the
primary Release Please workflow. When a real post-`1.3.0` linked release is created,
`.github/workflows/release-please.yml` now runs `linked-release-proof` after
`release`, `publish-accrue`, `publish-accrue-admin`, and `publish-accrue-portal`
all succeed.

The job writes `linked-release-proof.md` as both a workflow summary and a GitHub
Actions artifact. That artifact is the canonical source for the next live proof
block: exact `PR_NUMBER`, `TARGET_VERSION`, `RUN_ID`, workflow job ordering, tags,
GitHub releases, Hex API truth, HexDocs availability, host Hex smoke, and release
notes contract output.

REL-01 and REL-03 remain incomplete until that CI artifact exists for one real
post-`1.3.0` linked line. The new automation intentionally fails CI if identifiers
or public proof surfaces disagree, instead of converting the prior blocker rows
into a false completion claim.

## Closeout Resolution Attempt (2026-06-01)

Milestone closeout selected "resolve gaps" for the open Phase 159 verification
gap. The live release state was rechecked:

- `gh pr list --repo szTheory/accrue --state open --json number,title,headRefName,url` returned `[]`.
- `.release-please-manifest.json` and all three package `mix.exs` files still
  report `1.3.0`.
- The latest `release-please.yml` run (`26683503845`) failed while trying to
  create duplicate GitHub releases for existing tags `accrue-v1.3.0`,
  `accrue_admin-v1.3.0`, and `accrue_portal-v1.3.0`.
- `.github/workflows/release-please.yml` was patched to skip duplicate GitHub
  release creation when all three manifest releases already exist, allowing the
  release-PR path to continue on future pushes.
- `actionlint .github/workflows/release-please.yml` passed.
- `bash scripts/ci/verify_release_manifest_alignment.sh &&
  bash scripts/ci/verify_release_contract.sh &&
  bash scripts/ci/verify_release_notes_contract.sh` passed for the current
  `1.3.0` line.
- `release-please release-pr --dry-run` with an authenticated token would open
  `0` pull requests because remote `main` has `0` releasable commits after the
  existing `1.3.0` releases.

Outcome: the duplicate-release workflow blocker is fixed locally, but REL-01
and REL-03 remain blocked. There is still no real post-`1.3.0` linked Release
Please PR, publish run, or `linked-release-proof.md` artifact to verify. This
ledger therefore remains `status: gaps_found`; changing it to pass would be a
false release claim.

## Pre-merge proof row (2026-06-01)

PR_NUMBER: 30
TARGET_VERSION: 1.4.0

### Recovery attempt 2026-06-01T17:19:35Z

target_version: 1.4.0
run_id: 26769626329
pr_number: 30
accrue_public_state: 1.4.0 published
accrue_admin_public_state: 1.4.0 published
accrue_portal_public_state: 1.4.0 published
failed_step: accrue_host_hex_smoke.sh
recovery_path: Fix accrue.install to not double-inject accrue_admin live_session when it already exists
next_command: bash scripts/ci/accrue_host_hex_smoke.sh && bash scripts/ci/capture_linked_release_proof.sh --version 1.4.0 --run-id 26769626329 --pr 30 --output .planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md
recorded_at: 2026-06-01T17:19:35Z

### Proof capture 2026-06-01T17:23:26Z

PR_NUMBER: 30
TARGET_VERSION: 1.4.0
RUN_ID: 26769626329

Workflow run: https://github.com/szTheory/accrue/actions/runs/26769626329

#### Workflow job ordering

| Job | Conclusion | Started | Completed |
|-----|------------|---------|-----------|
| release | success | 2026-06-01T17:03:47Z | 2026-06-01T17:04:22Z |
| publish-accrue | success | 2026-06-01T17:04:25Z | 2026-06-01T17:07:58Z |
| publish-accrue-admin | success | 2026-06-01T17:08:00Z | 2026-06-01T17:11:46Z |
| publish-accrue-portal | success | 2026-06-01T17:11:49Z | 2026-06-01T17:15:03Z |

#### Git tags

| Package | Tag | Commit |
|---------|-----|--------|
| accrue | accrue-v1.4.0 | 3b375b3154953505c7edb603a3441514a049e945 |
| accrue_admin | accrue_admin-v1.4.0 | 3b375b3154953505c7edb603a3441514a049e945 |
| accrue_portal | accrue_portal-v1.4.0 | 3b375b3154953505c7edb603a3441514a049e945 |

#### GitHub releases

| Package | Tag | Release URL | Published |
|---------|-----|-------------|-----------|
| accrue | accrue-v1.4.0 | https://github.com/szTheory/accrue/releases/tag/accrue-v1.4.0 | 2026-06-01T17:04:07Z |
| accrue_admin | accrue_admin-v1.4.0 | https://github.com/szTheory/accrue/releases/tag/accrue_admin-v1.4.0 | 2026-06-01T17:04:09Z |
| accrue_portal | accrue_portal-v1.4.0 | https://github.com/szTheory/accrue/releases/tag/accrue_portal-v1.4.0 | 2026-06-01T17:04:10Z |

#### Hex API truth

| Package | latest_version | updated_at | API |
|---------|----------------|------------|-----|
| accrue | 1.4.0 | 2026-06-01T17:07:56.785209Z | https://hex.pm/api/packages/accrue |
| accrue_admin | 1.4.0 | 2026-06-01T17:11:44.432303Z | https://hex.pm/api/packages/accrue_admin |
| accrue_portal | 1.4.0 | 2026-06-01T17:15:01.250875Z | https://hex.pm/api/packages/accrue_portal |

#### Release file snapshot

| File | sha256 |
|------|--------|
| .release-please-manifest.json | ea634938bc7d6c6ee40ef57604ac217b4b12c011d67403869ae4ff9717a6485f |
| accrue/mix.exs | b1f5a5aa6574706f420314d966a64063f61c39e7e75562e720caf06da50b71af |
| accrue_admin/mix.exs | ea778163942270cefee57add559bc77bd19f1f6f73b4fe8cefed8ab140986e05 |
| accrue_portal/mix.exs | 657c371bf98cda27bb16c3197c026e199a9d9f0efac6a8756ebef8dfcfd988ad |
| accrue/CHANGELOG.md | a97f2367e8274943f9982812ae15c5fce687c2ca36a69f7095bef5f9f58f6767 |
| accrue_admin/CHANGELOG.md | 1fce8bf7228d6a66f27b0ba5d47be593ca9899b8cfe947f790779be1943cd737 |
| accrue_portal/CHANGELOG.md | e32f5718bcb058934badbc51651ce23e59da2eaaa42e6cafaddb9092b5f26eb1 |

#### HexDocs availability

| Package | URL | HTTP |
|---------|-----|------|
| accrue | https://hexdocs.pm/accrue/readme.html | 200 |
| accrue_admin | https://hexdocs.pm/accrue_admin/readme.html | 200 |
| accrue_portal | https://hexdocs.pm/accrue_portal/readme.html | 200 |

#### Host Hex smoke

```text
OK: accrue_host_hex_smoke.sh passed successfully

```

#### Release notes contract

```text
verify_release_notes_contract: OK (1.4.0)

```
