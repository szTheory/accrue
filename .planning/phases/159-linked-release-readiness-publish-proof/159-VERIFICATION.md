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
