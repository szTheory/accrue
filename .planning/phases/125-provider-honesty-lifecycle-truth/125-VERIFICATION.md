---
phase: 125-provider-honesty-lifecycle-truth
verified: 2026-05-23T16:50:00Z
status: passed
score: 4/4 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: none
  note: "Initial verification — no prior VERIFICATION.md existed"
---

# Phase 125: Provider Honesty + Lifecycle Truth Verification Report

**Phase Goal:** Entitlement resolution behaves identically across Stripe, Braintree, and Fake via a documented provider-honest contract, and entitlement-vs-lifecycle truth is pinned as a single source of truth — both protected by merge-blocking drift gates.
**Verified:** 2026-05-23T16:50:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| #   | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| 1 | A Resolver behaviour + `entitlements:` capability-matrix rows make local plan→feature mapping behave identically across Stripe, Braintree, and Fake, with the Fake lane as a deterministic merge-blocking proof | ✓ VERIFIED | `resolver.ex:70` `@callback resolve/2`; `local_map.ex:46` `@behaviour` + `@impl true`. `capabilities.ex` has `entitlements: %{local_mapping: "all first-party"}` (@61) and all three provider lanes `"local-identical"` (@108-110). All 3 adapters return byte-identical `entitlements: %{local_mapping: true}` (fake@239, stripe@98, braintree@43). Runtime spot-check confirmed: `support_label` = `"all first-party"`, all three `provider_support_label` = `"local-identical"`, byte-identical adapter maps = `true`. `provider_honesty_test.exs` loops `[Fake, Stripe, Braintree]` as `:processor`, asserts the three `resolved` maps are `==`, and asserts zero processor telemetry fired (`refute_received {:processor_called, _}`). Test passes (part of 95-test run, 0 failures). |
| 2 | Drift between runtime capability labels and the published support-matrix doc fails the build before merge (mirroring SCM-06 / PROC-24) | ✓ VERIFIED | `scripts/ci/verify_processor_support_matrix.sh` has positive `require_substring` asserts for the entitlements row literal + 3 prose strings (@60-62) and a negative divergence guard (@109) rejecting `native`/`unsupported`/`bounded` on entitlements rows. Gate runs clean (`OK`, exit 0). Negative guard scratch-tested: injecting `native` into the Stripe column of the entitlements row trips the guard. Gate is wired into the merge-blocking `docs-contracts-shift-left` CI job (ci.yml:46-47), declared merge-blocking on pull_request (ci.yml:6). |
| 3 | Entitlement truth maps explicitly to lifecycle states (trialing ✅, canceling/paid-through ✅, paused ✗, canceled ✗) as a documented SSOT truth table, with past-due grace as a fail-safe configurable knob reusing the dunning grace overlay | ✓ VERIFIED | `Subscription.entitling?/1` (@226) = `active?(sub) and not paused?(sub) and not canceled?(sub)`. Runtime spot-check matches the table exactly: trialing/active/canceling → true; pause_collection/ended/paused/past_due/unpaid/canceled/incomplete/incomplete_expired → false. `Query.entitling/1` twin (@52) adds `is_nil(pause_collection)`+`is_nil(ended_at)`; resolver `fold_active` calls it (closing the paused fail-OPEN gap — confirmed live via the actual SQL emitted during the test run). Past-due grace: `Config.past_due_grace/0` (@771, default `:none`, boot-validated union @421-423); pure `PastDueGrace.within_grace?/2` (clock-driven via `Accrue.Clock`, fail-closed); reuses dunning grace via `:dunning` → `Config.dunning()[:grace_days]`. Runtime spot-check: default `:none`, nil→false, in-window→true, out-of-window→false, grace_days 0→false. `:unpaid` excluded from the widen status set. |
| 4 | An operator/developer can read one canonical truth table and know which lifecycle states grant entitlement and how the past-due grace knob behaves | ✓ VERIFIED | `accrue/guides/lifecycle_semantics.md:173-211` has the "Lifecycle → entitlement truth table" with all 8 statuses + modifiers (trialing ✅, active ✅, canceling ✅, pause_collection ✗, ended ✗, paused ✗, past_due ✗default/✅in-grace, unpaid ✗, canceled/incomplete_expired ✗, incomplete ✗) plus a `### entitling` glossary entry (@162). The `[^past_due_grace]` footnote (@193-211) documents: `:none` default fail-closed, `:dunning`/N policies, window measured from `past_due_since` via `Accrue.Clock`, `:past_due_grace`/`:past_due_expired` telemetry reasons, `:unpaid` exclusion, zero-cost when `:none`. |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `accrue/lib/accrue/processor/capabilities.ex` | `entitlements:` group in both label maps | ✓ VERIFIED | `entitlements: %{local_mapping: "all first-party"}` @61; provider lanes all `"local-identical"` @108-110 |
| `accrue/lib/accrue/processor/{fake,stripe,braintree}.ex` | byte-identical `entitlements: %{local_mapping: true}` | ✓ VERIFIED | fake@239, stripe@98, braintree@43; runtime equality confirmed |
| `.planning/processor-support-matrix.md` | convergence row + identity prose | ✓ VERIFIED | row @59; 3 gate-pinned prose strings present (1 each) |
| `scripts/ci/verify_processor_support_matrix.sh` | positive asserts + negative divergence guard | ✓ VERIFIED | @60-62 positive, @109-112 negative; gate exits 0; negative guard scratch-verified |
| `accrue/test/accrue/entitlements/provider_honesty_test.exs` | Fake-lane merge-blocking proof | ✓ VERIFIED | `==` across 3 processors + zero-processor-call telemetry guard; passes |
| `accrue/lib/accrue/billing/subscription.ex` | `entitling?/1` predicate | ✓ VERIFIED | @226, composes active?/paused?/canceled?; runtime truth table correct |
| `accrue/lib/accrue/billing/query.ex` | `entitling/1` twin + `entitling_with_grace_candidates/1` | ✓ VERIFIED | @52 (active/trialing + nil guards, no :paused OR-clause), @78 (adds :past_due only, no :unpaid); `active/1` untouched @30 |
| `accrue/lib/accrue/entitlements/resolver/local_map.ex` | retargeted fold + conditional grace widening | ✓ VERIFIED | calls `Query.entitling()` @166 / `Query.entitling_with_grace_candidates()` @178; branches on `Config.past_due_grace()` @151; no `Query.active`, no raw `status == :past_due` |
| `accrue/lib/accrue/entitlements/past_due_grace.ex` | pure clock-driven `within_grace?/2` | ✓ VERIFIED | fail-closed heads, uses `Accrue.Clock.utc_now`, zero `DateTime.utc_now` |
| `accrue/lib/accrue/entitlements/resolver.ex` | additive `:grace_plans` on resolved type | ✓ VERIFIED | `@type resolved` @52 with optional `:grace_plans`/`:grace_features`/`:expired_grace_plans` @57-59 |
| `accrue/lib/accrue/config.ex` | `past_due_grace` schema key + accessor | ✓ VERIFIED | schema @421-423 (`{:or, [{:in, [:dunning, :none]}, :pos_integer]}`, default `:none`); accessor @771 |
| `accrue/lib/accrue/entitlements.ex` | `:past_due_grace`/`:past_due_expired` reason selection | ✓ VERIFIED | @68-71, @109-110; reads grace_plans/grace_features/expired_grace_plans; zero `Telemetry.Ops.emit` |
| `accrue/guides/lifecycle_semantics.md` | entitling glossary + truth table + grace footnote | ✓ VERIFIED | @162 glossary, @173-191 table, @193-211 footnote |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| `verify_processor_support_matrix.sh` | `processor-support-matrix.md` | `grep -Fq` exact-literal row match | ✓ WIRED | Gate exits 0 against current doc; positive assert @60 byte-matches doc row @59 |
| `provider_honesty_test.exs` | `capabilities.ex` | `support_label`/`provider_support_label` assertions == doc literals | ✓ WIRED | Test @131-137 asserts the convergence labels; passes |
| `local_map.ex` | `query.ex` | `fold_active` base fetch uses `Query.entitling/1` | ✓ WIRED | @166; SQL `WHERE status IN ('active','trialing') AND pause_collection IS NULL AND ended_at IS NULL` observed in test run |
| `subscription.ex` | `query.ex` | predicate↔fragment twin invariant | ✓ WIRED | `query_test.exs` per-row twin cross-check passes |
| `local_map.ex` | `past_due_grace.ex` | per-row `within_grace?/2` on grace lane | ✓ WIRED | @195 references `PastDueGrace.within_grace?` |
| `entitlements.ex` | `resolver.ex` | `:grace_plans` selects grace reasons | ✓ WIRED | @199-203 read additive resolved fields |
| `past_due_grace.ex` | `clock.ex` | cutoff math via `Accrue.Clock.utc_now/0` | ✓ WIRED | confirmed; no raw `DateTime.utc_now` |
| `verify_processor_support_matrix.sh` | `ci.yml` | drift gate runs in merge-blocking CI job | ✓ WIRED | ci.yml:47 in `docs-contracts-shift-left` (merge-blocking @ci.yml:6) |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| `LocalMap.resolve/2` | `resolved.active_plans/features` | `Query.entitling/1` → `Accrue.Repo.all` (real DB query) | Yes — SQL with real WHERE clause observed in test output, returns seeded subscription items | ✓ FLOWING |
| `provider_honesty_test` | `resolved` (per provider) | `LocalMap.resolve/2` against seeded customer w/ 2 active subs | Yes — asserts `active_plans == [:p1,:p2]`, `features == [:reports,:export,:api]` | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Capability convergence labels + adapter equality | `MIX_ENV=test mix run -e` (Capabilities + adapters) | support_label="all first-party"; all lanes "local-identical"; adapters byte-identical=true | ✓ PASS |
| `entitling?/1` truth table (11 cases) | `MIX_ENV=test mix run -e` (struct literals) | trialing/active/canceling→true; pause/ended/paused/past_due/unpaid/canceled/incomplete/incomplete_expired→false | ✓ PASS |
| `within_grace?/2` + default config | `MIX_ENV=test mix run -e` (PastDueGrace) | default :none; nil→false; in-window→true; out-of-window→false; grace_days 0→false | ✓ PASS |
| Negative divergence guard | scratch-edit Stripe col to `native` + run guard regex | TRIPPED (exit 1) — catches native in Stripe column | ✓ PASS |
| Drift gate end-to-end | `bash scripts/ci/verify_processor_support_matrix.sh` | `verify_processor_support_matrix: OK`, exit 0 | ✓ PASS |
| Phase test suite | `mix test` (9 phase test files, `--warnings-as-errors`) | 95 tests, 0 failures | ✓ PASS |
| Credo strict | `mix credo --strict` | 3502 mods/funs, found no issues | ✓ PASS |

### Probe Execution

| Probe | Command | Result | Status |
| ----- | ------- | ------ | ------ |
| Processor support matrix contract | `bash scripts/ci/verify_processor_support_matrix.sh` | exit 0, `OK` | PASS |

(The phase declares this script as the merge-blocking drift gate; executed directly, exit 0.)

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| ENT-08 | 125-01 | Provider-honest resolution via Resolver behaviour + capability-matrix rows; identical across Stripe/Braintree/Fake; merge-blocking drift gate (mirrors SCM-06/PROC-24) | ✓ SATISFIED | Truths 1+2. Resolver behaviour + convergence capability rows + Fake-lane proof + drift gate (positive+negative) wired into merge-blocking CI. REQUIREMENTS.md marks ENT-08 → Phase 125 Complete. |
| ENT-09 | 125-02, 125-03 | Lifecycle→entitlement truth mapping (trialing✅/canceling✅/paused✗/canceled✗); past-due grace as fail-safe configurable knob reusing dunning overlay; documented SSOT truth table | ✓ SATISFIED | Truths 3+4. `entitling?/1`+`Query.entitling/1` twin, paused-gap closure, truth table + footnote, `past_due_grace` knob (default :none, reuses dunning grace_days), additive `:past_due_grace`/`:past_due_expired` reasons. REQUIREMENTS.md marks ENT-09 → Phase 125 Complete. |

No orphaned requirements: REQUIREMENTS.md maps exactly ENT-08, ENT-09 to Phase 125, both claimed by the phase plans (125-01 → ENT-08; 125-02, 125-03 → ENT-09).

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| (none) | — | No TBD/FIXME/XXX in modified source files; no TODO/HACK/PLACEHOLDER/stub markers | — | Clean |

Debt-marker scan across all 12 modified source/script files: zero matches. No stub returns, no empty handlers, no hardcoded-empty render data. Credo strict clean.

### Human Verification Required

None. All four success criteria are programmatically verifiable (capability labels, predicate behavior, query SQL, config validation, drift-gate execution) and were confirmed by runtime spot-checks plus the merge-blocking test suite. No visual/UX/external-service surface in this phase.

### Gaps Summary

No gaps. All four ROADMAP success criteria are observably true in the codebase:

1. **SC#1 (provider honesty):** The Resolver behaviour exists and `LocalMap` implements it; the additive `entitlements:` capability group reads identical convergence labels (`local-identical`) across all three providers; all three adapters return byte-identical `entitlements: %{local_mapping: true}`; the Fake-lane proof asserts `==` resolved maps and zero processor calls and passes.
2. **SC#2 (drift gate):** The drift gate has positive byte-match asserts and a negative divergence guard (scratch-verified to trip on `native` in any provider column), runs clean, and is wired into the merge-blocking `docs-contracts-shift-left` CI job.
3. **SC#3 (lifecycle truth + grace knob):** `entitling?/1` and its `Query.entitling/1` SQL twin produce the documented allow/deny mapping (verified at runtime and via the live SQL); the paused fail-OPEN gap is closed in the actual read path; the `past_due_grace` knob is boot-validated, fail-closed by default, clock-driven, reuses the dunning grace window, and excludes `:unpaid`.
4. **SC#4 (canonical truth table):** `lifecycle_semantics.md` carries a single canonical truth table covering all statuses + modifiers plus a detailed footnote on the past-due grace knob behavior.

**Notes (non-blocking, informational):**
- The companion `125-REVIEW.md` raised 4 warnings (telemetry-reason accuracy on freshly-`:past_due` nil-`past_due_since` rows; partial-`:dunning` config raise; string-keyed-map twin drift; negative-guard regex missing uppercase/digit tokens) and 3 info items. None affect any allow/deny decision (all fail-closed) and none block the phase goal. WR-04 (the negative guard's `[a-z_]+` key class and lowercase-only token match) reflects the literal plan acceptance criterion as written; broadening it would be a hardening follow-up, not a goal gap. These are observability/robustness refinements appropriately tracked in the review, not phase-goal failures.
- The full `mix test` baseline carries 6 pre-existing `Accrue.Docs.PackageDocsVerifierTest` failures (PROJECT.md missing "gateway subscription core" needle since 2026-05-08) and a flaky PdfTest — documented baseline, NOT phase-125 regressions. The 95 phase-relevant tests pass cleanly with `--warnings-as-errors`.

---

_Verified: 2026-05-23T16:50:00Z_
_Verifier: Claude (gsd-verifier)_
