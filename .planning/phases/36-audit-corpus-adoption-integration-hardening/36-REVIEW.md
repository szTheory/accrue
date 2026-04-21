---
status: clean
phase: 36
reviewed: 2026-04-21
depth: quick
---

# Phase 36 — Code review

## Scope

Doc-only and bash `fail()` helper change plus ExUnit assertion updates tied to Phase 36 plans.

## Findings

None blocking.

- **`scripts/ci/verify_package_docs.sh`:** `fail()` only prefixes stderr; no change to `require_fixed` / `require_regex` semantics.
- **`package_docs_verifier_test.exs`:** Negative-path assertions now require the triage prefix and tolerate CONTRIBUTING-first failure ordering; aligns with script behavior.
- **Planning / guides:** Forward-coupling and testing appendix reference existing modules and paths only.

## Notes

Full `mix test` for `accrue/` may still fail if optional `.planning` corpus fixtures referenced by unrelated doc tests are absent (pre-existing caveat in phase 32/33 verification).
