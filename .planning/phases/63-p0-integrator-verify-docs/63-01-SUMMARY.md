---
phase: 63-p0-integrator-verify-docs
plan: "01"
requirements-completed: [INT-10]
key-files:
  created: []
  modified:
    - accrue/guides/first_hour.md
    - accrue/README.md
    - accrue_admin/README.md
    - accrue/test/accrue/docs/package_docs_verifier_test.exs
completed: "2026-04-23"
---

# Phase 63 plan 01 — summary

**Outcome:** First Hour and both package READMEs now state three skimmable facts—Hex line vs branch, `path:`/monorepo lockstep between `accrue` and `accrue_admin`, and pre-1.0 lockfile discipline—without new version SSOTs beyond `verify_package_docs.sh`.

## Self-Check: PASSED

- `bash scripts/ci/verify_package_docs.sh` — exit 0
- `PGUSER=$USER mix test test/accrue/docs/package_docs_verifier_test.exs` — green
