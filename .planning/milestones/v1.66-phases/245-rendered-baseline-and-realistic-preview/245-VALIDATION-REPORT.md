# Phase 245 Validation Audit

**Outcome:** Partial validation. The new ordinary-story contracts and current route/provenance verification pass. Route accounting and rendered evidence improved substantially, but some material states and interaction outcomes remain explicitly unavailable, so phase-wide Nyquist compliance remains false.

## Checks run in this audit

| Check | Result | What it establishes |
|---|---|---|
| `cd examples/accrue_host && MIX_ENV=test mix test test/ordinary_preview_story_contract_test.exs test/ordinary_preview_seed_test.exs test/seeds_idempotency_test.exs` | **11 tests, 0 failures** | Persisted seed contracts for ordinary Unicode identity and stable ownership; promotion/coupon consistency and rerun reconciliation; lifecycle markers; exact/adjacent UTC invoice/charge/refund timestamps; money in stored minor units; and refund limits plus preserved absent history. Uses SQL Sandbox; does not mutate the isolated ordinary preview DB. |
| `node scripts/ci/verify_phase245_baseline.mjs --coverage .planning/phases/245-rendered-baseline-and-realistic-preview/245-COVERAGE.md --routes-only` | **PASS** | All 21 production route templates reconcile with the host mount; route/state rows are classified and structurally valid. This does not make unavailable states rendered coverage. |
| `node scripts/ci/verify_phase245_baseline.mjs --self-test` | **PASS** | Negative cases rejected stale source digests, mismatched route references, duplicate owner topics and generic unavailable claims. |
| Full coverage/manifest/findings verifier | **PASS** | Route inventory, capture references and PNG hashes, source digest data, compiled/served asset identity, and finding-to-capture links are consistent. |

The final authenticated Playwright run is recorded in the execution summary and capture-debug log: **5/5 passed in 49.6 seconds**. It produced 24 PNGs at revision `a8d39ea4`, with `source_dirty: false`; protected Phase 243 custody also passed. The 24 images comprise 19 reachable route renders and five supplemental states. The browser suite was not rerun during this audit; the persisted manifest and summary are checked by the passing full verifier.

## Requirement coverage

**DEMO-01 data contracts improved.** The new five-test story-contract file covers the actual persisted Atelier Café customer identity and owner/subscription relationships across a seed rerun; coupon and promotion redemption totals, caps, eligibility and repair; paused/unpaid/incomplete lifecycle markers; UTC period, finalization, payment, event and fee-settlement equality/adjacency; minor-unit currency values; refund charge limits and fee effects; and absent provider event history. Together with the existing seed and idempotency contracts, the focused suite passes 11 tests. Local status fields without events/attempts remain classified as fixture state, which is the truthful coverage of the unknown case. Narrative plausibility still includes a judgment component, and the phase remains partial overall.

**BASE-01 route accountability passes; rendered state coverage is partial.** The current ledger reconciles all 21 mounted production route templates, tracks 31 route/state rows, and the route verifier plus negative self-tests pass. It contains 19 reachable route PNGs. Connect and webhook detail routes remain unavailable because this ordinary dataset has no detail IDs. Several variants are reasoned gaps rather than captured states.

**BASE-02 has bounded visual and representative interaction evidence.** The 19-route cohort received an image review and the five supplementary screenshots were opened for their stated evidence. The run exercised customer, Connect and webhook filtered-zero screens; global search open and focus; ArrowDown selection followed by pointer hover; the customer Invoices tab and matching URL; and opening the customer Activity disclosure. The Activity screenshot still shows its lazy-load prompt, so loaded activity is not established. The recorded critique and source-linked findings are handoff evidence, not a claim that all interaction behavior was accepted.

## Remaining gaps

- The unfiltered truly-empty Connect/Webhooks alternatives were not selected; their filtered-zero captures do not establish unfiltered empty behavior.
- Connect and webhook detail views have no ordinary IDs and therefore no Phase 245 rendered detail evidence.
- Overflow/long-text, one-versus-many relationship variants, alternate role/scope, physical touch, action outcomes, other detail disclosures, broad non-customer filter/query/result agreement, keyboard activation, and focus restoration remain unavailable or untested.
- Recovery ready state was captured after a bounded wait; an application-error state was not available.
- Some local invoice statuses intentionally have no attempt/event history. Tests and the story ledger preserve this absence without describing it as a provider outcome.

These limitations are explicitly represented in the coverage state matrix and omitted-combinations list. They do not invalidate the passing route/provenance checks, but they prevent marking every material behavior fully covered.

## TDD evidence boundary

The Plan 245-01 plaintext ExUnit RED output was not accepted by the TAP classifier. The later Phase 245 story-contract RED was classifier-accepted for the named ordinary Unicode name and coupon/code count contradictions before correction. No RED was claimed for lifecycle/refund/date checks that already passed against existing seed data.

No implementation or capture files were changed during this validation audit.

Final capture safeguard follow-up: source `a8d39ea4` independently checks the Fake processor before bulk capture; positive/negative guard test and authenticated suite passed (5/5, 49.6s). Refreshed evidence is committed in `da24ebf7`.
