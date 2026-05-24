---
phase: 127-optional-stripe-native-sync-isolated-off-by-default
plan: 04
subsystem: docs
tags: [entitlements, stripe, docs, telemetry, doc-verifier, ci-gate]

# Dependency graph
requires:
  - phase: 127-02
    provides: "FINALIZED event/config names — entitlements.active_entitlement_summary.updated webhook, entitlements.summary.synced ledger type, [:accrue, :entitlements, :sync] span, [:accrue, :entitlements, :summary_synced] (result :written|:unchanged), [:accrue, :ops, :entitlement_summary_truncated], reused stale_event/orphan_entitlement_summary, Accrue.Entitlements.StripeSync.summary_for_customer/1 read seam"
  - phase: 127-03
    provides: "entitlements.stripe_native_sync capability row label 'Stripe-native advisory (observational)' (stripe native (advisory) / fake out-of-slice / braintree unsupported)"
provides:
  - "guides/entitlements.md 'Optional Stripe-native sync (advisory)' section: observational disclaimer (does NOT change entitled?), two-step enable (config :advisory + host Stripe Dashboard event-enable), eventual-consistency window, 10-entitlement inline cap (has_more/truncated/ops), deferred lattice_stripe >= 1.2 paginated read; references the Plan 03 capability-matrix row"
  - "guides/telemetry.md 'Entitlement sync events' catalog: [:accrue, :entitlements, :sync] span + [:accrue, :entitlements, :summary_synced] event + reused stale_event/orphan_entitlement_summary + truncated ops cross-ref; firehose entitlements bullet"
  - "verify_package_docs.sh needles pinning the Stripe-native section (stripe_native_sync, webhook event name, observational-disclaimer slice, telemetry sync span) — merge-blocking against silent regression"
affects: [entitlements, docs, doc-contracts]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Doc-needle pinning of an observational-overlay section: require_fixed (grep -F byte-exact) on the disclaimer + enable + event-name strings so the DX-critical 'advisory != gate-influencing' contract cannot silently regress (mirrors the Phase 126 entitlements-spine block idiom at 118-124)"
    - "Single-line needle slice of a wrapped Markdown blockquote: pin the part of the disclaimer that fits on one physical line (grep -Fq is line-oriented)"
    - "Avoid ExDoc autolink warnings for @doc false functions: describe Mod.fun/arity in prose ('the X module's fun/1 function') rather than a backtick-wrapped fully-qualified Mod.fun/arity reference"

key-files:
  created:
    - .planning/phases/127-optional-stripe-native-sync-isolated-off-by-default/127-04-SUMMARY.md
  modified:
    - accrue/guides/entitlements.md
    - accrue/guides/telemetry.md
    - scripts/ci/verify_package_docs.sh

key-decisions:
  - "Placed the new entitlements.md section AFTER 'Provider honesty' (which already forward-references the off-by-default overlay) and BEFORE 'Telemetry' — the natural narrative slot; the provider-honesty paragraph was extended to name the entitlements.stripe_native_sync row label from Plan 03"
  - "Catalogued the new sync events as a dedicated 'Entitlement sync events' subsection between the firehose section and the ops catalog table (the truncated ops row itself already lives in the ops catalog from Plan 02 — cross-referenced, NOT duplicated)"
  - "Pinned 4 needles (config key, webhook event name, byte-exact disclaimer slice, telemetry sync span) — the plan's stated minimum; chose the single-line disclaimer slice 'does NOT change `entitled?` /' since the blockquote wraps after the slash"
  - "Reworded the StripeSync read-seam mention to avoid an ExDoc autolink warning on the @doc false summary_for_customer/1 (self-corrected before any commit)"

patterns-established:
  - "Three distinct, intentionally-non-collapsed names documented side-by-side: the Stripe inbound webhook event (entitlements.active_entitlement_summary.updated), the internal ledger event type (entitlements.summary.synced), and the telemetry span/event ([:accrue, :entitlements, :sync] / :summary_synced)"

requirements-completed: [ENT-10]

# Metrics
duration: 2min
completed: 2026-05-24
---

# Phase 127 Plan 04: Document the optional Stripe-native advisory sync (D-12) Summary

**The human-facing half of D-12: guides/entitlements.md now tells the optional Stripe-native sync story end-to-end — the plain "advisory = observational, does NOT change `entitled?`" disclaimer, the two-step enable (config `:advisory` + host Stripe Dashboard event-enable), the eventual-consistency window, the 10-entitlement inline cap, and the deferred `lattice_stripe >= 1.2` paginated read — guides/telemetry.md catalogs the new sync span/event, and verify_package_docs.sh pins it all merge-blocking with four new byte-exact needles.**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-05-24T12:16:55Z
- **Tasks:** 2
- **Files modified:** 3 (0 created in code; 1 SUMMARY created)

## Accomplishments

- **D-12 entitlements.md section:** Appended "Optional Stripe-native sync (advisory)" covering every D-12 required item:
  - **Observational disclaimer** as a prominent blockquote — `:advisory` records summaries to an advisory cache for audit/telemetry/the admin read-seam and does **NOT** change `entitled?`/`has_active_plan?` in v1.x (local mapping stays canonical; the sole path to `true` is an affirmative resolved local match). The read seam (`Accrue.Entitlements.StripeSync` `summary_for_customer/1`) is named as the one-way inspection point.
  - **Two-step enable** — (1) `config :accrue, entitlements: [stripe_native_sync: :advisory]` (default `:disabled` makes the path inert before any DB read; enum not boolean for future modes) AND (2) the host-owned Stripe Dashboard step of enabling `entitlements.active_entitlement_summary.updated` on the webhook endpoint.
  - **Eventual-consistency window** — webhooks have no order/lag SLA; local-first canonical means a stale advisory cache never produces a wrong gate decision; monotonic guard converges to the highest-timestamp summary.
  - **10-entitlement inline cap** — `has_more` → typed indexed `truncated` column; `[:accrue, :ops, :entitlement_summary_truncated]` fires only when partial; partiality can never affect a gate (observational).
  - **Deferred full paginated read** (`GET /v1/entitlements/active_entitlements`) as a `lattice_stripe >= 1.2` follow-up.
  - Extended the "Provider honesty" paragraph to name the **`entitlements.stripe_native_sync`** capability row label ("Stripe-native advisory (observational)") from Plan 03, distinct from the `entitlements.local_mapping` convergence row.
- **D-12 telemetry.md catalog:** Added an "Entitlement sync events" subsection cataloging `[:accrue, :entitlements, :sync]` (the state-change mirror of `:check`), `[:accrue, :entitlements, :summary_synced]` (`result: :written | :unchanged`), and the reused `[:accrue, :webhooks, :stale_event]` (`object_type: :entitlement_summary`) + `[:accrue, :webhooks, :orphan_entitlement_summary]`, with a cross-reference to the `entitlement_summary_truncated` ops row already in the ops catalog (from Plan 02 — not duplicated). Added an "Entitlements" bullet to the firehose section. Noted the OTel `@allowed_attributes` allowlist is intentionally not widened.
- **D-12 doc-verifier needles:** Added 4 `require_fixed` needles to `verify_package_docs.sh` after the existing entitlements-spine block (118-124, byte-for-byte intact): `stripe_native_sync` + `entitlements.active_entitlement_summary.updated` + the single-line disclaimer slice ``does NOT change `entitled?` /`` in entitlements.md, and `[:accrue, :entitlements, :sync]` in telemetry.md. The verifier stays green.

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend entitlements.md + telemetry.md with the Stripe-native sync story (D-12)** — `4e7b3b8` (docs)
2. **Task 2: Add verify_package_docs.sh needles for the Stripe-native section (D-12)** — `9fe7d09` (docs)

**Plan metadata:** (final docs commit — this SUMMARY + STATE/ROADMAP/REQUIREMENTS)

## Files Created/Modified

- `accrue/guides/entitlements.md` (modified) — new "Optional Stripe-native sync (advisory)" section (disclaimer + enable + window + 10-cap + deferred 1.2); provider-honesty paragraph extended to name the Plan 03 matrix row label. Existing needles (`entitled?`, `Accrue.Plug.RequireEntitlement`, `[:accrue, :entitlements, :check]`) untouched.
- `accrue/guides/telemetry.md` (modified) — new "Entitlement sync events" catalog subsection; firehose "Entitlements" bullet. The `entitlement_summary_truncated` ops-catalog row + remediation row added by Plan 02 are cross-referenced, not re-forked.
- `scripts/ci/verify_package_docs.sh` (modified) — 4 new `require_fixed` needles; existing entitlements-spine block byte-for-byte unchanged.

## Decisions Made

- **Section placement:** entitlements.md new section sits after "Provider honesty" (which already forward-references the overlay) and before "Telemetry" — the most coherent narrative slot, and lets the provider-honesty paragraph hand off to the new section by naming the Plan 03 row label.
- **Telemetry: cross-reference, don't duplicate:** the truncated ops row already lives in the ops catalog table (Plan 02). The new subsection documents the firehose sync span/event and reused webhook events, and points at the ops row rather than forking the ops table (the guide already warns "do not fork that table into a second inventory").
- **Disclaimer needle is a single physical-line slice:** `grep -Fq` is line-oriented and the disclaimer blockquote wraps after the `/`, so the pinned needle is ``does NOT change `entitled?` /`` (byte-exact present on line 244).
- **Three distinct names kept distinct:** documented the Stripe inbound webhook event, the internal ledger event type, and the telemetry span/event side by side — per the plan's explicit instruction not to collapse them.

## Deviations from Plan

None - plan executed exactly as written.

(Mid-Task-1, an ExDoc autolink warning surfaced because a `@doc false` function was written as a backtick-wrapped fully-qualified `Mod.fun/arity` reference, which ExDoc treats as an autolink target. This was reworded to prose before any commit — `mix docs` builds clean with zero warnings — so it never entered the commit history and is not a plan deviation. The plan's verify command (`mix docs 2>&1 | grep -qiv "error"`) would have passed regardless, but the project's docs are kept warning-free.)

## Authentication Gates

None — docs-only plan, no external service authentication required.

## Known Stubs

None — this is a documentation plan. The advisory cache's observational-only posture (never gate-consulted) is the locked D-01 design, not a stub; the full paginated read of >10 entitlements is the documented `lattice_stripe >= 1.2` deferral (carried in the project Deferred Items), and this plan documents that deferral honestly along with the `truncated` flag + truncation ops event that surface the gap.

## Threat Flags

None — no new network endpoints, auth paths, file-access patterns, or trust-boundary schema changes. This plan is docs + a CI doc-needle gate. The threat register's two `mitigate` dispositions are satisfied:
- **T-127-11** (operator misreads `:advisory` as gate-influencing): the plain "advisory = observational, does NOT change `entitled?`" disclaimer is documented AND pinned by the ``does NOT change `entitled?` /`` doc-verifier needle so it cannot silently regress.
- **T-127-12** (sync telemetry undocumented): telemetry.md catalogs all new + reused sync events with their `result`/`has_more` semantics.

## Verification Evidence

- `bash scripts/ci/verify_package_docs.sh` → exit 0 (all old + new needles satisfied).
- `cd accrue && mix docs` → exit 0, zero warnings; `doc/entitlements.html` (44KB) + `doc/telemetry.html` (69KB) built.
- entitlements.md: `stripe_native_sync` ×4, `entitlements.active_entitlement_summary.updated` ×2, observational disclaimer ×1, 10-cap (`has_more`/10 entitlement/truncat) ×7, deferred 1.2 (`1.2`/paginated/`active_entitlements`) ×5.
- telemetry.md: `[:accrue, :entitlements, :sync]` ×2, `[:accrue, :entitlements, :summary_synced]` present, `entitlement_summary_truncated` ×3.
- Existing entitlements.md needles intact: `entitled?` ×6, `Accrue.Plug.RequireEntitlement` ×4, `[:accrue, :entitlements, :check]` ×1.
- verify_package_docs.sh new needles present (×2 for event-name/config, ×1 for telemetry span); `git diff` on the script shows additions only — zero deletions in the 118-124 block.
- Needle negative-control proof: each new needle pins content byte-exact present; a deliberately-absent control string correctly fails `grep -Fq`.

## Issues Encountered

- **ExDoc autolink warning** for the `@doc false` `summary_for_customer/1` — resolved by prose rewording before commit (see Deviations). No other issues.

## Next Phase Readiness

- Plan 04 was the final plan of Phase 127 (wave 3). All four plans (01 schema/config/RED scaffolds, 02 reducer+seam, 03 provider-honesty row + isolation gate, 04 docs) are complete; ENT-10 is documented end-to-end with the observational disclaimer pinned merge-blocking.
- No blockers.

## Self-Check: PASSED

- Modified files exist on disk: `accrue/guides/entitlements.md`, `accrue/guides/telemetry.md`, `scripts/ci/verify_package_docs.sh`.
- Both task commits present in git history (`4e7b3b8`, `9fe7d09`).
- `verify_package_docs.sh` exit 0; `mix docs` exit 0 zero-warnings with both HTML files built; all acceptance-criteria greps satisfied; existing entitlements-spine needles byte-for-byte intact.

---
*Phase: 127-optional-stripe-native-sync-isolated-off-by-default*
*Completed: 2026-05-24*
