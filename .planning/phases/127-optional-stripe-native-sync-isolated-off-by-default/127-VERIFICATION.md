---
phase: 127-optional-stripe-native-sync-isolated-off-by-default
verified: 2026-05-24T12:33:53Z
status: passed
score: 4/4 must-haves verified
overrides_applied: 0
---

# Phase 127: Optional Stripe-Native Sync (isolated, off by default) Verification Report

**Phase Goal:** A Stripe shop can optionally let Stripe's native entitlement summaries reconcile a local advisory cache, without that path being able to block or regress the milestone's local-first core value.
**Verified:** 2026-05-24T12:33:53Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (Roadmap Success Criteria)

| #   | Truth | Status     | Evidence |
| --- | ----- | ---------- | -------- |
| 1   | When explicitly enabled (off by default), Accrue consumes `entitlements.active_entitlement_summary.updated` into a local cache as an advisory overlay; local mapping remains canonical default. | ✓ VERIFIED | Dedicated `handle_event/3` clause (`default_handler.ex:126-137`) + config-gated `dispatch/4` clause (`:300-306`) + `reduce_entitlement_summary/3` (`:489-550`) upserts `accrue_entitlement_summaries`. Cache is observational-only; gate-path files have ZERO refs (verified below). Tests green (12 tests, 1 property). |
| 2   | Cache writes apply monotonic event-ts/id ordering so out-of-order/replayed summaries cannot regress the cache, mirroring `last_stripe_event_ts`/`_id`. | ✓ VERIFIED | Reducer reuses `check_stale/2` (`:514`), `:lt` → `[:accrue, :webhooks, :stale_event]` + `{:ok, :stale}` no write (`:516-522`); `stamp_summary_watermark/4` (WR-02 fix, `:660-670`) refuses to clobber a non-nil watermark with nil. Property test `entitlement_summary_monotonic_property_test.exs` passes (final cache == highest-ts snapshot). |
| 3   | With sync disabled (default), the entire entitlements surface behaves exactly as after Phase 126 — no Stripe dependency on the core gate path. | ✓ VERIFIED | Off-lane `dispatch/4` clause early-returns `{:ok, :ignored}` BEFORE any Repo call (`:300-306`). Runtime test `stripe_sync_disabled_isolation_test.exs` attaches Ecto query telemetry, calls `entitled?/2`, asserts ZERO queries touch `accrue_entitlement_summaries` + surface parity with Phase-126 fixture (passes). Default is `:disabled` (`config.ex:797,806`). |
| 4   | The eventual-consistency window and the 10-entitlement inline cap are documented, with full paginated reads recorded as deferred follow-up (depends on `lattice_stripe ≥ 1.2`). | ✓ VERIFIED | `guides/entitlements.md`: eventual-consistency window (`:299-307`), 10-cap/`has_more`/`truncated` (`:317-327`), deferred `GET /v1/entitlements/active_entitlements` requiring `lattice_stripe >= 1.2` (`:331-339`), observational disclaimer (`:244-246`). `guides/telemetry.md` catalogs all new events. `verify_package_docs.sh` pins the section (passes). |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `accrue/lib/accrue/billing/entitlement_summary.ex` | Ecto schema keyed on customer_id, no processor_id, watermark cols, force_changeset | ✓ VERIFIED | `schema "accrue_entitlement_summaries"`; `belongs_to(:customer)` `:54`; `force_changeset/2` with `optimistic_lock`+`unique_constraint(:customer_id)`+`foreign_key_constraint(:customer_id)` `:82-88`; no `processor_id` field. |
| `accrue/priv/repo/migrations/20260524120000_*.exs` | CREATE TABLE, FK on_delete:delete_all, unique_index(:customer_id), partial truncated index | ✓ VERIFIED | `references(:accrue_customers, on_delete: :delete_all)` `:26`; `unique_index([:customer_id])` `:42`; `index([:truncated], where: "truncated = true")` `:44`. |
| `accrue/lib/accrue/config.ex` | stripe_native_sync enum key + accessors | ✓ VERIFIED | `:432` enum `{:in,[:disabled,:advisory]}` default `:disabled`; D-03 disclaimer doc `:439`; `stripe_native_sync/0` `:797`, `stripe_native_sync?/0` `:806`. |
| `accrue/lib/accrue/webhook/default_handler.ex` | config-gated dispatch + monotonic reducer + on-change ledger + telemetry + production-path handle_event/3 clause | ✓ VERIFIED | Reducer `:489-697`, gate-first off-lane `:300-306`, dedicated `handle_event/3` BEFORE nil short-circuit `:126-137 < :179`. |
| `accrue/lib/accrue/entitlements/stripe_sync.ex` | read-only observational seam | ✓ VERIFIED | `summary_for_customer/1` `Repo.get_by(EntitlementSummary, customer_id:)`, `@doc false`, one-way moduledoc; never referenced by gate path. |
| `accrue/lib/accrue/processor/capabilities.ex` | new stripe_native_sync row; convergence row untouched | ✓ VERIFIED | `:62` core label, `:120-123` provider label (`fake: out of slice`, `stripe: native (advisory)`, `braintree: unsupported`); `local_mapping` convergence row `:108-112` all `local-identical`. |
| `.planning/processor-support-matrix.md` | new sync row, convergence row byte-identical | ✓ VERIFIED | convergence row count=1, sync row present (2 refs). |
| `scripts/ci/verify_processor_support_matrix.sh` | new row needle + tightened drift guard | ✓ VERIFIED | Script exits 0 ("OK"). |
| `scripts/ci/verify_entitlement_sync_isolation.sh` | static gate over gate-path files | ✓ VERIFIED | Contains `^[^#]*` anchor, `|| true`, alternation `EntitlementSummary\|StripeSync\|accrue_entitlement_summaries\|stripe_native_sync` (WR-03 fix `:47`). Passes clean; negative-proof catches an injected leak. |
| `scripts/ci/verify_package_docs.sh` | new doc needles | ✓ VERIFIED | Script exits 0. |
| `accrue/guides/entitlements.md` | Stripe-native advisory section | ✓ VERIFIED | Full section `:233-339`. |
| `accrue/guides/telemetry.md` | new sync/ops event catalog | ✓ VERIFIED | `:74-78`, `:107`, `:455`. |
| `accrue/test/support/stripe_fixtures.ex` | entitlement_summary_event/2 fixture, no top-level id on summary object | ✓ VERIFIED | `:422-460`; summary object `:441` has NO top-level `id` (the `id` at `:433` is per-entitlement). |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| config.ex | :entitlements @schema | NimbleOptions stripe_native_sync key | ✓ WIRED | Pattern found in source. |
| entitlement_summary.ex | accrue_customers | belongs_to + foreign_key_constraint | ✓ WIRED | `belongs_to(:customer, ...)` `:54` + `foreign_key_constraint(:customer_id)` `:87`; migration references `accrue_customers`. (SDK reported a regex-escaping artifact `Invalid regex pattern`, NOT a missing link — confirmed present by direct grep.) |
| default_handler.ex | Accrue.Config.stripe_native_sync?/0 | dispatch clause runtime gate first | ✓ WIRED | Pattern found; off-lane returns `{:ok, :ignored}` pre-Repo. |
| default_handler.ex | EntitlementSummary | Repo.get_by + upsert | ✓ WIRED | Pattern found. |
| default_handler.ex | accrue_events | on-change record(entitlements.summary.synced) | ✓ WIRED | `maybe_record_summary_event/3` idempotency-keyed `:607-615`. |
| verify_entitlement_sync_isolation.sh | gate-path files | grep ^[^#]* over 3 files, exit 1 on hit | ✓ WIRED | Negative proof confirms exit 1 on injected leak. |
| ci.yml | verify_entitlement_sync_isolation.sh | docs-contracts-shift-left job step | ✓ WIRED | `ci.yml:53` inside `docs-contracts-shift-left` job, merge-blocking. |
| verify_package_docs.sh | entitlements.md | require_fixed needle | ✓ WIRED | Script passes. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| reduce_entitlement_summary | cache row | `Repo.get_by(EntitlementSummary, customer_id:)` + force_changeset upsert | Yes — real DB writes/reads observed in test query logs | ✓ FLOWING |
| StripeSync.summary_for_customer/1 | EntitlementSummary row | `Repo.get_by` | Yes — reads the persisted advisory cache | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Phase 127 test suite (reducer + monotonic property + disabled isolation) | `mix test --seed 0 <3 files>` | 1 property, 12 tests, 0 failures | ✓ PASS |
| Production-path handle_event/3 reachability (CR-01/WR-01) | grep + test review | `describe "real DispatchWorker path (handle_event/3)"` builds `%Event{object_id: nil}` + summary in ctx, asserts row written | ✓ PASS |
| Disabled lane DB-free (SC#3) | test attaches `[:*, :repo, :query]`, asserts 0 cache queries | `refute_received {:cache_query, _}` passes | ✓ PASS |

### Probe / Gate Execution

| Gate | Command | Result | Status |
| ---- | ------- | ------ | ------ |
| Isolation gate | `bash scripts/ci/verify_entitlement_sync_isolation.sh` | exit 0, "OK" | PASS |
| Isolation gate negative proof | inject `_leak = StripeSync` into entitlements.ex | exit 1, FAIL message lists offending line; revert → exit 0 | PASS (gate is real) |
| Support-matrix drift gate | `bash scripts/ci/verify_processor_support_matrix.sh` | exit 0, "OK" | PASS |
| Package docs gate | `bash scripts/ci/verify_package_docs.sh` | exit 0 | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| ENT-10 | 127-01,02,03,04 | Optional off-by-default Stripe-native advisory cache via webhook, monotonic, local mapping canonical, paginated read deferred to `lattice_stripe ≥ 1.2` | ✓ SATISFIED | All 4 SCs verified above. REQUIREMENTS.md `:36` + `:79` map ENT-10 → Phase 127 only (no orphans, no double-mapping). |

No orphaned requirements: ENT-10 is the sole requirement mapped to Phase 127 and is claimed by all four plans' `requirements:` frontmatter.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| (none) | — | No TBD/FIXME/XXX in any Phase 127 source file; no TODO/HACK/PLACEHOLDER in reducer/seam/schema | — | Clean |

### Gaps Summary

No gaps. The phase goal is achieved and observably true in the codebase.

The independently re-verified blocker (CR-01) is confirmed fixed: the entitlement-summary reducer is reachable on the REAL production path. A dedicated `handle_event/3` clause for `entitlements.active_entitlement_summary.updated` (`default_handler.ex:126-137`) pulls the full object from `ctx` (DispatchWorker's `:meter_error_object`, which is populated for any event carrying `data.object`) and dispatches, and it is positioned BEFORE the generic `object_id: nil` short-circuit at `:179`. A regression test drives the real `handle_event/3` path with `object_id: nil` and asserts a row is written. The summary object correctly has no top-level `id` (the production trigger for the original bug).

D-01 isolation is independently confirmed: the three gate-path files (`entitlements.ex`, `resolver.ex`, `resolver/local_map.ex`) contain ZERO references to `EntitlementSummary`/`StripeSync`/`accrue_entitlement_summaries`/`stripe_native_sync`, and the merge-blocking `verify_entitlement_sync_isolation.sh` genuinely fails (exit 1) when a leak is injected and passes after revert.

The disabled (default) lane short-circuits to `{:ok, :ignored}` BEFORE any Repo call, and a runtime telemetry test proves zero queries hit the cache table on the `entitled?/2` gate path — SC#3 (Phase-126 parity, no Stripe dependency) holds.

**Deferred (non-blocking, tracked):** The code-review's WR-05 (concurrent same-customer delivery raising `Ecto.StaleEntryError`, self-healing via Oban retry) and IN-01..04 (cosmetic/fidelity) are recorded in `.planning/todos/pending/2026-05-24-ent10-advisory-cache-followups.md`. Phase 127 is the final phase of the v1.39 milestone, so these remain post-milestone follow-ups; none affect the four success criteria. No human verification items: every truth was verifiable programmatically (config gate, monotonic ordering, DB-free disabled lane, and documentation are all grep/test/script-checkable).

---

_Verified: 2026-05-24T12:33:53Z_
_Verifier: Claude (gsd-verifier)_
