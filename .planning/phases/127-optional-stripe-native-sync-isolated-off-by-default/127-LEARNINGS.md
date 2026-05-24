---
phase: 127
phase_name: "optional-stripe-native-sync-isolated-off-by-default"
project: "Accrue"
generated: "2026-05-24T17:09:16Z"
counts:
  decisions: 9
  lessons: 8
  patterns: 8
  surprises: 5
missing_artifacts:
  - "UAT.md"
---

# Phase 127 Learnings: optional-stripe-native-sync-isolated-off-by-default

## Decisions

### Advisory cache is observational-only, never gate-consulted (D-01)
The optional Stripe-native entitlement-summary sync writes a local `accrue_entitlement_summaries` cache, but that cache is recorded/surfaced only — local plan→feature mapping stays canonical for every `entitled?`/`has_active_plan?` decision. `:advisory` does not change gating in v1.x.

**Rationale:** A stale or partial cache must never be able to grant or deny access. Keeping the cache out of the gate path makes "Stripe-native sync cannot block or regress the milestone's local-first core value" a structural guarantee rather than a runtime hope.
**Source:** 127-01-PLAN.md, 127-02-PLAN.md, 127-CONTEXT.md

### Config gate is an enum `{:disabled, :advisory}`, not a boolean (D-03)
The `:entitlements -> stripe_native_sync` key is a NimbleOptions enum defaulting to `:disabled`, boot-validated, with dual accessors `stripe_native_sync/0` (raw read supplying its own default) and `stripe_native_sync?/0` (predicate).

**Rationale:** An enum reserves room for future sync modes without a breaking change; RESEARCH's original `:boolean` draft was explicitly superseded by D-03. Boot validation makes a misconfigured value fail loudly rather than silently.
**Source:** 127-01-PLAN.md, 127-01-SUMMARY.md

### Cache keyed on `customer_id`, with no `processor_id` field (D-06/A4)
The schema is one-row-per-customer keyed on `customer_id`, deliberately dropping the `processor_id` field carried by its `SubscriptionSchedule` clone analog.

**Rationale:** The `entitlements.active_entitlement_summary` Stripe object has no top-level `id` — there is no processor-side identifier to key on. (This same property later turned out to be the root cause of the CR-01 production bug — see Surprises.)
**Source:** 127-01-PLAN.md, 127-01-SUMMARY.md

### Monotonic-snapshot reducer, not refetch-canonical (D-06)
Ordering is enforced by reusing `check_stale/2` on the event watermark (`last_stripe_event_ts`/`_id`) rather than re-fetching authoritative state from a Stripe API.

**Rationale:** `lattice_stripe` 1.1 has no Entitlements list API to refetch, so the webhook snapshot is the only source. A ConnectHandler-style comment block documents *why* this path is snapshot-based rather than refetch-based.
**Source:** 127-02-PLAN.md, 127-02-SUMMARY.md

### On-change-only ledger writes (D-08)
An `accrue_events` row (`entitlements.summary.synced`, idempotency-keyed, IDs/counts only) is appended ONLY on a material change — sorted `{feature_id, lookup_key}` pairs differ OR `truncated` differs; a first-ever write is material. Byte-identical re-delivery emits `result: :unchanged` telemetry and writes no row.

**Rationale:** Keeps the audit ledger a record of *changes* rather than a re-delivery firehose, while idempotency-keying lets Oban retries collapse cleanly.
**Source:** 127-02-PLAN.md, 127-02-SUMMARY.md

### Capability-matrix evolution: add a NEW row, never mutate the convergence row (D-10)
A new `entitlements.stripe_native_sync` divergence row was added as a sibling beneath the existing `entitlements.local_mapping` convergence row across all three SSOT locations (code labels, matrix markdown, drift gate); the convergence row stayed byte-for-byte identical.

**Rationale:** The convergence row is a protected contract ("all three providers local-identical"). Honest provider labeling (`stripe: native (advisory)`, `braintree: unsupported`) must not silently rewrite that contract.
**Source:** 127-03-PLAN.md, 127-03-SUMMARY.md

### Static isolation gate scoped to named gate-path files, not all of `accrue/lib` (D-04 layer 2)
`verify_entitlement_sync_isolation.sh` greps only the three always-on gate-path files (`entitlements.ex`, `resolver.ex`, `resolver/local_map.ex`) for cache references.

**Rationale:** The cache *model* (schema, seam, reducer) legitimately lives in core `accrue/lib`; a whole-tree scan would produce false positives once Plans 01/02 landed. Only the gate-decision path must stay cache-free.
**Source:** 127-03-PLAN.md, 127-03-SUMMARY.md

### Reducer kept inline in `default_handler.ex`; `StripeSync` is its own module
The reducer is a private clause/helper set inside `default_handler.ex` (not a delegated module), while the read seam is a dedicated `Accrue.Entitlements.StripeSync` module rather than a sibling function in `Accrue.Entitlements.Admin`.

**Rationale:** Keeping the reducer inline preserves verbatim reuse of `check_stale/2`, `stamp_watermark/3`, dual `get/2`, and `record_event/5` in one file. A separate `StripeSync` module keeps the observational advisory-cache seam distinct from `Admin`'s resolver-drift diagnostic seam.
**Source:** 127-02-SUMMARY.md

### Defense in two layers: runtime off-lane DB-free + static merge gate (D-04)
Layer 1 — the dispatch clause checks `stripe_native_sync?/0` FIRST and early-returns `{:ok, :ignored}` before any `Repo` call. Layer 2 — a merge-blocking CI grep gate proves the cache is unreachable from the gate path.

**Rationale:** Layer 1 makes the disabled default provably free of any DB dependency at runtime; Layer 2 makes the isolation invariant non-regressing against future refactors. Neither alone is sufficient.
**Source:** 127-02-PLAN.md, 127-03-PLAN.md, 127-SECURITY.md

---

## Lessons

### A fully green suite can hide a feature that is dead on the production path (CR-01)
Every entitlement-summary test drove the raw-map `handle/1` entry, never the `handle_event/3`/`DispatchWorker` path real Stripe webhooks take. Because the summary object has no top-level `id`, the real `%Webhook.Event{}` carries `object_id: nil`, which hit a generic `object_id: nil` short-circuit *before* dispatch — so a real webhook wrote nothing even with `:advisory` enabled. The defect passed the suite precisely because the production entry point was never exercised.

**Context:** Caught by code review, not by the suite. Fix added a dedicated `handle_event/3` clause (pulling the object from `ctx.meter_error_object`, mirroring the meter-error/portal pattern) placed above the nil short-circuit, plus regression tests on the real path. Test the production entry point, not just the unit-level handler.
**Source:** 127-REVIEW.md (CR-01, WR-01), 127-VERIFICATION.md

### Accrue is a library — there is no `:repo` outside the `:test` env
`mix run` / `mix ecto.migrate` find no repo in dev because `Accrue.TestRepo` is configured only in `config/test.exs`, and `validate_at_boot!/0` requires a `:repo` only present in `:test`. All plan verify commands must run under `MIX_ENV=test`.

**Context:** Surfaced in Plan 01 and carried through every plan. A pre-existing property of the library, not a defect — but it silently breaks any verify command written assuming a dev-env repo.
**Source:** 127-01-SUMMARY.md, 127-02-SUMMARY.md

### Registering a new ops telemetry event is a 3-way merge-blocking co-update
Emitting `[:accrue, :ops, :entitlement_summary_truncated]` tripped two contract tests: `OpsEventContractTest` (every ops literal in `lib/` must be in `TelemetryOpsInventory.expected_ops_events/0` and documented in `guides/telemetry.md`) and `MetricsOpsParityTest` (every canonical ops tuple needs a `defaults/0` metric).

**Context:** A new ops event is not "just an emit" — it requires the inventory entry, a `counter(...)` in `Metrics.defaults/0`, and entries in both `guides/telemetry.md` tables in the same PR, or the suite fails.
**Source:** 127-02-SUMMARY.md (Rule 3 deviation)

### A nil/missing event timestamp wipes the watermark and weakens monotonicity (WR-02)
When `evt_ts` is `nil`, `check_stale/2` returns `:ok` and the write stamps `last_stripe_event_ts: nil`, disabling stale protection for that customer until a timestamped event re-stamps it — a hole in the "highest event timestamp always wins" invariant the phase promises.

**Context:** Fixed with a summary-scoped `stamp_summary_watermark/4` that refuses to overwrite a non-nil watermark with `nil` (shared `stamp_watermark/3` left untouched to avoid affecting other reducers). The reducer that *promises* monotonicity is the one that must harden the nil-timestamp edge.
**Source:** 127-REVIEW.md (WR-02), 127-SECURITY.md

### A static isolation gate is only as good as its grep alternation (WR-03)
The original gate matched `EntitlementSummary|StripeSync|accrue_entitlement_summaries` only. A gate-path file could fail-open by reading `Accrue.Config.stripe_native_sync?()` and widening a grant — without touching any scanned token.

**Context:** Fixed by adding `stripe_native_sync` to the alternation. A "cache cannot reach the gate" gate must also block references to the *config flag* that switches the cache on, not just the cache modules.
**Source:** 127-REVIEW.md (WR-03)

### Removing a test exclusion without scrubbing its tags/docs leaves actively misleading metadata (WR-04)
After `:pending_plan_02` was removed from the exclude list, all three test files still carried `@moduletag :pending_plan_02` and moduledocs asserting they were "EXCLUDED by default / RED this wave." The tests ran (the tag was no longer excluded), so the metadata was false — and a future reader could re-add the tag to the exclude list trusting the docs, silently disabling the only coverage for the feature.

**Context:** When a wave gate is lifted, scrub the tags and the "RED/EXCLUDED" prose together, not just the exclude list.
**Source:** 127-REVIEW.md (WR-04)

### `@doc false` functions referenced as backtick `Mod.fun/arity` trigger ExDoc autolink warnings
Writing a `@doc false` function as a backtick-wrapped fully-qualified `Mod.fun/arity` reference makes ExDoc treat it as an autolink target and warn. Describing it in prose ("the X module's `fun/1` function") avoids the warning.

**Context:** Caught and reworded before commit while documenting the `StripeSync` read seam, keeping `mix docs` warning-free.
**Source:** 127-04-SUMMARY.md

### Plan-referenced module attribute names can drift from the live source
The plan's `read_first` referenced `@core_capability_labels` (lines 60-62), but the live module actually names that attribute `@support_labels`. The plan also called it "code labels," so the new key landed in `@support_labels` as intended.

**Context:** Treat plan-cited attribute names / line numbers as approximate; confirm against the live file before editing.
**Source:** 127-03-SUMMARY.md

---

## Patterns

### RED-scaffold-then-GREEN across waves
Wave 0 (Plan 01) lands the executable contract — fixture + RED test files encoding every validation behavior — tagged `:pending_plan_02` and added to the `test_helper.exs` exclude list so the default suite stays green. The implementing wave (Plan 02) removes the exclusion as it turns the scaffolds GREEN.

**When to use:** Multi-plan/multi-wave phases where you want the behavioral contract checked in and compiling before the implementation exists, without redding the suite in the interim.
**Source:** 127-01-SUMMARY.md, 127-02-SUMMARY.md

### Config-gated webhook dispatch clause (gate checked first)
The dispatch clause evaluates the runtime config predicate FIRST and early-returns `{:ok, :ignored}` BEFORE any `Repo` call when the feature is off.

**When to use:** Any optional, off-by-default feature whose disabled state must be provably side-effect-free (no DB query, no Stripe call). Pairs with a runtime telemetry test that asserts zero queries on the off lane.
**Source:** 127-02-SUMMARY.md

### One-way observational read seam (clone the Admin stance)
Expose a cache/diagnostic read through a dedicated module with `@doc false` and a moduledoc declaring "one-way seam → billing read; the gate path MUST NOT reference this." Verify with a gate-path grep returning 0.

**When to use:** When you need to surface derived/auxiliary state (admin UI, audit, telemetry) without letting it leak into an authorization decision path.
**Source:** 127-02-SUMMARY.md

### NEW-row-not-mutation for capability-matrix evolution
Add a sibling divergence row and tighten the drift gate to exempt it *by name* (anchor the negative guard to the protected convergence row), pinning the new row with a positive `require_substring`. Never edit the protected convergence row.

**When to use:** Evolving an SSOT matrix that has a load-bearing "all-identical" convergence contract a broad drift guard protects.
**Source:** 127-03-SUMMARY.md

### Static merge-gate clone (comment-anchored grep, scoped to named files)
Clone `verify_core_liveview_runtime_free.sh`: keep `set -euo pipefail`, the `^[^#]*` comment-anchor (so doc-comments/strings don't trip it), and the trailing `|| true` (so a clean grep doesn't fail `set -e`) verbatim; swap the forbidden-reference alternation and scope to the specific files that must stay clean. Wire it merge-blocking in the `docs-contracts-shift-left` CI job.

**When to use:** Enforcing a "module X must never be referenced from path Y" invariant as a non-regressing CI gate.
**Source:** 127-03-SUMMARY.md, 127-03-PLAN.md

### Defensive on-change comparison tolerant of malformed payloads
`summary_material_change?/3` + `entitlement_pairs/1` derive sorted `{feature, lookup_key}` pairs from the prior row's stored `data` and the incoming payload via the dual `get/2`, tolerating nil / non-list / missing-key shapes, and compare pairs + `truncated`.

**When to use:** Idempotent on-change ledgering where both the stored snapshot and the incoming untrusted payload may be partial or malformed.
**Source:** 127-02-SUMMARY.md

### Dedicated `handle_event/3` clause for objectless webhook events
For event types whose Stripe object has no usable top-level `id` (meter-error, portal-checkout, entitlement summary), add a dedicated `handle_event/3` clause that pulls the object out of `ctx` and dispatches explicitly — placed ABOVE the generic `object_id: nil` short-circuit.

**When to use:** Any webhook type that the standard `object_id`-derivation path would null out and silently drop. This is the production-path contract the CR-01 fix established.
**Source:** 127-REVIEW.md (CR-01), 127-VERIFICATION.md

### Doc-needle pinning of a DX-critical disclaimer
Pin the observational disclaimer with a `require_fixed` (byte-exact `grep -F`) needle in `verify_package_docs.sh`. Because `grep -Fq` is line-oriented, choose a substring that fits on one physical line of the (wrapped) Markdown blockquote.

**When to use:** Documentation whose exact wording is a correctness/authorization-expectation contract that must not silently regress.
**Source:** 127-04-SUMMARY.md

---

## Surprises

### The feature shipped green but was dead on the production path
The single most consequential finding: with the entire suite passing, a real Stripe webhook for `entitlements.active_entitlement_summary.updated` would have written nothing in production, because `object_id: nil` short-circuited before dispatch and no test exercised that path.

**Impact:** Blocker (CR-01) caught at code review. Required a new `handle_event/3` clause + real-path regression tests before the phase could be claimed working end-to-end. Reframed "tests green" as insufficient evidence of an end-to-end feature.
**Source:** 127-REVIEW.md (CR-01), 127-VERIFICATION.md

### The summary reducer's optimistic lock crashes on concurrent same-customer delivery (WR-05)
`force_changeset/2` carries `optimistic_lock(:lock_version)`; two Oban jobs processing summaries for the same customer concurrently will have the second `Repo.update` raise `Ecto.StaleEntryError` (and the insert path races the `unique_index`). Other reducers use plain `changeset/2` and don't hit this — the summary reducer is the only one that opted into the lock without a retry/recover path.

**Impact:** Self-healing via Oban retry, so non-blocking — but produces noisy crashes. Deferred (an `on_conflict` upsert or rescue+retry) as a post-milestone follow-up.
**Source:** 127-REVIEW.md (WR-05), 127-SECURITY.md

### The honest new label would have tripped the existing drift guard (pre-flagged conflict)
The new row's `native (advisory)` / `unsupported` labels matched the existing negative drift guard's `\b(native|unsupported|bounded)\b` scan over any `entitlements.*` row — a "PLANNER-CRITICAL CONFLICT" the Pattern Map flagged ahead of time.

**Impact:** Resolved exactly as planned, same-PR, by anchoring the guard to `entitlements.local_mapping`. A reminder that adding honest divergence labels can collide with the very drift guards meant to protect convergence.
**Source:** 127-03-PLAN.md, 127-03-SUMMARY.md

### Whole phase shipped with zero new dependencies
All four plans declared `tech-stack.added: []`; git log over the phase range shows no `mix.exs`/`mix.lock` changes. The entire optional Stripe-native sync was built by cloning existing patterns (SubscriptionSchedule schema, past_due_grace config, orphan_charge tolerance, check_stale/stamp_watermark helpers, the LiveView-runtime-free CI gate).

**Impact:** No supply-chain attack surface this phase (T-127-SC accepted on that basis). Evidence that mature in-repo patterns can absorb a substantial new feature without new deps.
**Source:** 127-SECURITY.md, all four SUMMARYs

### Plans executed in 2–6 minutes each
Reported durations: Plan 01 ~5 min, Plan 02 ~6 min, Plan 03 ~4 min, Plan 04 ~2 min.

**Impact:** Fast — but the speed is downstream of heavy front-loaded artifacts (CONTEXT, PATTERNS, RESEARCH, VALIDATION) that pre-resolved nearly every decision; the one thing those artifacts missed (the production-path reachability) became the blocker. Velocity reflects planning depth, not implementation simplicity.
**Source:** 127-01/02/03/04-SUMMARY.md
