---
status: passed
phase: 32
verified: 2026-04-21
---

# Phase 32 — Verification

## Automated

| Check | Result |
|-------|--------|
| `bash scripts/ci/verify_package_docs.sh` | PASS |
| `bash scripts/ci/verify_verify01_readme_contract.sh` | PASS |
| `mix test test/accrue/docs/package_docs_verifier_test.exs` | PASS |

## ROADMAP success criteria

1. **Root → proof within two hops:** `README.md` has `## Proof path (VERIFY-01)` with `cd examples/accrue_host`, `mix verify.full`, `not CI-complete`, and a single link to `examples/accrue_host/README.md#proof-and-verification`. **Met.**
2. **Host coherent subsection:** `examples/accrue_host/README.md` has one `## Proof and verification` with lede + `### Verification modes` + `### VERIFY-01 (Phase 21)`. **Met.**
3. **No contradictory primary proof command across linked docs:** Same one-liner in host lede, root proof block, `accrue/guides/testing.md`; guides link to host fragment; live-Stripe guide states non-merge-blocking. **Met.**

## Requirements

| ID | Evidence |
|----|----------|
| ADOPT-01 | Root `## Proof path (VERIFY-01)` + doc contract lines in `verify_package_docs.sh` |
| ADOPT-02 | Host README structure + `verify_verify01_readme_contract.sh` awk / mobile substring updates |
| ADOPT-03 | `testing.md`, `first_hour.md`, `testing-live-stripe.md` + `require_fixed` on one-liner |

## Notes

- Full `mix test` in `accrue/` may fail locally if `.planning/phases/15-trust-hardening/15-TRUST-REVIEW.md` and `16-EXPANSION-RECOMMENDATION.md` are missing (ExUnit doc corpus tests). This is unrelated to Phase 32 deliverables; restore those files or adjust tests separately.

## human_verification

None required (docs + script invariants only).
