# Phase 159 — Linked Release Readiness + Publish Proof — Verification

**Milestone:** v1.48  
**Status:** In progress

## Release identifiers

PR_NUMBER:
TARGET_VERSION:
RUN_ID:

## Pre-merge truth audit

| Check | Command / Source | Job | Timestamp (UTC) | Result | Notes |
|-------|------------------|-----|-----------------|--------|-------|
| pending | pending | pending | pending | pending | Fill during Task 2 |

## Deterministic gate bundle

| Check | Command / Source | Job | Timestamp (UTC) | Result | Notes |
|-------|------------------|-----|-----------------|--------|-------|
| pending | pending | pending | pending | pending | Fill during Task 2 |

## Publish execution

| Step | Evidence | Timestamp (UTC) | Result | Notes |
|------|----------|-----------------|--------|-------|
| pending | pending | pending | pending | Fill during Task 3 |

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

## Notes

- Append-only ledger: add new dated blocks; do not rewrite prior proof rows.

## Sign-off

- [ ] REL-01 complete
- [ ] REL-02 complete
- [ ] REL-03 complete
