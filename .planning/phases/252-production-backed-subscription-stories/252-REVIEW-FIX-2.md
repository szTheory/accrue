---
phase: 252
status: fixed
commit: 558b67b4
---

# Phase 252 Gap Review Corrections

## Fixed Issues

### CR-03: Extra malformed prohibition entries are silently ignored

The acceptance parser now counts every prohibition list item, requires the single original item, rejects unexpected metadata in other plans, and terminates a section at any sibling key. A regression adding a second statement-less item failed with a missing expected exception before the fix and passes after it.

### CR-04: Plans 09/10 used for coverage are absent from the freshness snapshot

The runner and acceptance validator now pin all ten plan files and the validation accounting artifact through archive-aware reads while retaining logical path keys. Every newly consumed path has required CI ownership and removal controls. Mutating plans 09/10 or validation after bundle creation failed to raise before the fix and is rejected after it. Mutable SUMMARY/UAT/output artifacts remain outside source snapshots.

## Verification

`node --test --test-reporter=tap scripts/ci/generate_phase252_acceptance.test.mjs scripts/ci/verify_phase252_ci_contract.test.mjs`: 46 tests, 46 pass, 0 fail. Direct current-source metadata validation: metadata_passed, two original descriptors. A fresh full aggregate is running against the correction; its final reference belongs in 252-10-SUMMARY.md and 252-UAT.md.
