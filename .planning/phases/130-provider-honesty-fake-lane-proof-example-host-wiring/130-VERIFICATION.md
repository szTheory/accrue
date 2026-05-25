---
phase: 130-provider-honesty-fake-lane-proof-example-host-wiring
verified: 2026-05-25T16:50:00Z
status: passed
score: 8/8 must-haves verified
overrides_applied: 0
re_verification: null
---

# Phase 130: Provider Honesty + Fake-Lane Proof + Example-Host Wiring Verification Report

**Phase Goal:** Dunning's per-provider behavior is documented honestly and drift-gated, the full journey is proven deterministically as a merge-blocking gate, and recovery is demonstrated end-to-end in the canonical example host instead of shipping as a dormant cron.
**Verified:** 2026-05-25T16:50:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

All four ROADMAP Success Criteria are verified against codebase evidence.

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Dunning behavior is documented provider-honest in `guides/`: Stripe (Smart Retries timing + Test Clocks advisory), Braintree (Accrue-clock-driven, explicitly NOT retry-aligned), Fake (deterministic proof lane) with lifecycle/capability truth note | VERIFIED | `accrue/guides/dunning.md` (193 lines): contains "local-identical", "native (Smart Retries)", "unsupported (clock-driven only)", "zero processor calls", "not retry-aligned" for Braintree, Test Clocks advisory framing, and lifecycle_semantics.md cross-reference |
| 2 | Where per-provider dunning labels are claimed, a merge-blocking drift check fails the build if the runtime labels and published doc diverge | VERIFIED | `scripts/ci/verify_processor_support_matrix.sh` exits 0; has `require_substring` pins for both dunning matrix rows + 3 prose pins + `require_substring_in_guide` for 4 guide-side claims + negative convergence guard for `dunning.campaign` row + missing-file guard for the guide |
| 3 | A deterministic Fake-lane test proves start → step progression → cancel-on-recovery → exhaustion through the real DefaultHandler entry point as a merge-blocking gate | VERIFIED | `accrue/test/accrue/dunning/dunning_full_journey_test.exs` (553 lines), 7 tests, 0 failures; 4 `DefaultHandler.handle` call sites; no `Process.sleep` in code; untagged; all 4 ledger event types and 4 telemetry events asserted; D-09 label mirror test included |
| 4 | Default campaign wired into `examples/accrue_host` so failed-payment recovery demonstrated end-to-end, closing dormant-cron gap | VERIFIED | `config/config.exs` has `accrue_dunning: 2` + `Oban.Plugins.Cron` DunningSweeper; `test.exs` has `testing: :manual`; `dunning_wiring_test.exs` (276 lines), 5 tests, 0 failures; `adoption-proof-matrix.md` has dunning row with all 4 required tokens; `verify_adoption_proof_matrix.sh` exits 0 |
| 5 | Capabilities.ex exposes a dunning group with campaign (local-identical x3) and smart_retry_alignment (provider-divergent) | VERIFIED | `capabilities.ex` @support_labels has `dunning: %{campaign: "all first-party", smart_retry_alignment: "provider-divergent (see dunning guide)"}` and @provider_support_labels has full dunning group with all 6 per-provider labels |
| 6 | Each adapter (Fake, Stripe, Braintree) declares dunning support in capabilities/0 | VERIFIED | fake.ex: `dunning: %{campaign: true, smart_retry_alignment: true}`; stripe.ex: `dunning: %{campaign: true, smart_retry_alignment: true}`; braintree.ex: `dunning: %{campaign: true, smart_retry_alignment: false}` |
| 7 | `.planning/processor-support-matrix.md` carries the two dunning rows + Dunning prose section | VERIFIED | Both rows confirmed exactly: `| dunning.campaign | local-identical | local-identical | local-identical | all first-party |` and `| dunning.smart_retry_alignment | testing/local-only | native (Smart Retries) | unsupported (clock-driven only) | provider-divergent (see dunning guide) |`; `## Dunning` prose section present with all 3 pinned substrings |
| 8 | Full journey test includes D-09 code-side label mirror asserting all 6 provider_support_label/2 values against doc literals | VERIFIED | Test at line 230 asserts all 6 labels; also asserts 2 public `support_label/1` values |

**Score:** 8/8 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `accrue/lib/accrue/processor/capabilities.ex` | dunning group in @support_labels and @provider_support_labels | VERIFIED | Lines 64-66 (@support_labels), lines 136-153 (@provider_support_labels); `smart_retry_alignment` appears in both sections |
| `accrue/lib/accrue/processor/fake.ex` | `dunning: %{campaign: true, smart_retry_alignment: true}` | VERIFIED | Line 240 |
| `accrue/lib/accrue/processor/stripe.ex` | `dunning: %{campaign: true, smart_retry_alignment: true}` | VERIFIED | Line 99 |
| `accrue/lib/accrue/processor/braintree.ex` | `dunning: %{campaign: true, smart_retry_alignment: false}` | VERIFIED | Line 44 |
| `.planning/processor-support-matrix.md` | dunning.campaign + dunning.smart_retry_alignment rows + Dunning prose | VERIFIED | Both rows present verbatim; `## Dunning` section present with all 3 pinned prose substrings |
| `scripts/ci/verify_processor_support_matrix.sh` | require_substring pins + negative convergence guard + guide pins | VERIFIED | Lines 80-84 (matrix pins), lines 143-146 (guide pins), line 153 (negative guard), exits 0 |
| `accrue/guides/dunning.md` | Provider-honest guide, >=60 lines, 4 pinned labels, lifecycle cross-ref, Warning blockquote | VERIFIED | 193 lines; all required content present |
| `accrue/test/accrue/dunning/dunning_full_journey_test.exs` | Full-journey + label-mirror proof through DefaultHandler, >=120 lines | VERIFIED | 553 lines; 4 DefaultHandler.handle call sites; 7 tests pass |
| `examples/accrue_host/config/config.exs` | accrue_dunning queue + Oban.Plugins.Cron DunningSweeper | VERIFIED | Lines 43, 47-49 |
| `examples/accrue_host/config/test.exs` | testing: :manual | VERIFIED | Line 36 |
| `examples/accrue_host/test/accrue_host/dunning_wiring_test.exs` | Fake-backed host wiring proof, >=50 lines, drain_queue | VERIFIED | 276 lines; 5 tests pass; DefaultHandler.handle called >= 2 times |
| `examples/accrue_host/docs/adoption-proof-matrix.md` | dunning wiring row with 4 required tokens | VERIFIED | All 4 tokens present: `dunning_wiring_test.exs`, `accrue_dunning`, `Oban.Plugins.Cron`, `dunning_full_journey_test.exs` |
| `scripts/ci/verify_adoption_proof_matrix.sh` | 4 dunning needle pins | VERIFIED | Lines 63-66; exits 0 |
| `examples/accrue_host/priv/repo/migrations/20260525120000_add_dunning_campaign_started_at_to_subscriptions.exs` | Host migration for dunning_campaign_started_at column | VERIFIED | File exists (deviation noted in SUMMARY-04: was missing, auto-fixed) |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `.planning/processor-support-matrix.md` | `capabilities.ex` | `verify_processor_support_matrix.sh` require_substring pins | WIRED | Script pins match code labels verbatim; negative convergence guard exits 1 on drift |
| `accrue/guides/dunning.md` | `lifecycle_semantics.md` | markdown link at line 5 | WIRED | `[Lifecycle Semantics](lifecycle_semantics.md#past_due)` present |
| `scripts/ci/verify_processor_support_matrix.sh` | `accrue/guides/dunning.md` | require_substring_in_guide pins | WIRED | 4 guide-side pins + missing-file guard; exits 1 if guide missing or drops a label |
| `dunning_full_journey_test.exs` | `Accrue.Webhook.DefaultHandler` | `DefaultHandler.handle(event)` | WIRED | 4 actual code call sites at lines 134, 142, 169, 196 |
| `dunning_full_journey_test.exs` | `Accrue.Processor.Capabilities` | `provider_support_label/2` assertions | WIRED | 6 assertions at lines 232-248 |
| `examples/accrue_host/config/config.exs` | `Accrue.Jobs.DunningSweeper` | `Oban.Plugins.Cron` crontab | WIRED | `{"*/15 * * * *", Accrue.Jobs.DunningSweeper}` present |
| `examples/accrue_host/test/accrue_host/dunning_wiring_test.exs` | `:accrue_dunning` queue | `Oban.drain_queue(queue: :accrue_dunning)` | WIRED | drain_queue calls present; queue config confirmed in config.exs |

### Data-Flow Trace (Level 4)

Not applicable — this phase produces capability declarations, documentation, tests, and config wiring. No dynamic data rendering components. Tests are the runtime artifacts and they pass (7/7 and 5/5).

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| verify_processor_support_matrix.sh exits 0 | `bash scripts/ci/verify_processor_support_matrix.sh` | "verify_processor_support_matrix: OK" | PASS |
| verify_adoption_proof_matrix.sh exits 0 | `bash scripts/ci/verify_adoption_proof_matrix.sh` | "verify_adoption_proof_matrix: OK" | PASS |
| Full journey test passes | `cd accrue && mix test test/accrue/dunning/dunning_full_journey_test.exs --seed 0` | 7 tests, 0 failures | PASS |
| Host wiring test passes | `cd examples/accrue_host && mix test test/accrue_host/dunning_wiring_test.exs --seed 0` | 5 tests, 0 failures | PASS |
| accrue compiles without warnings | `cd accrue && mix compile --warnings-as-errors` | exit 0 | PASS |

### Probe Execution

No probe scripts declared for this phase. Step 7c: SKIPPED (no probe scripts defined).

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| DUN-09 | 130-01, 130-02 | Dunning behavior provider-honest and documented — drift-gated where labels are claimed | SATISFIED | SC#1: `guides/dunning.md` exists with honest per-provider story. SC#2: `verify_processor_support_matrix.sh` pins both code labels (capabilities.ex) and guide claims, with negative convergence guard |
| DUN-10 | 130-03, 130-04 | Deterministic Fake-lane full-journey gate + default campaign wired into `examples/accrue_host` | SATISFIED | SC#3: `dunning_full_journey_test.exs` — 7 tests, untagged, through DefaultHandler. SC#4: host accrue_dunning queue + Cron sweeper + 5-test wiring proof + adoption-proof-matrix row |

No orphaned requirements — both requirements mapped to exactly one phase (Phase 130) in REQUIREMENTS.md traceability table and both are covered by the four plans.

### Anti-Patterns Found

Scan of all 13 phase-modified files:

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| `dunning_full_journey_test.exs` | `Process.sleep` appears 2x in comments/docstrings, not in code | Info | No impact — both are in the `@moduledoc` prohibition reminder |
| (all others) | No TBD/FIXME/XXX/TODO/HACK/PLACEHOLDER found | — | — |

No blockers. No unresolved debt markers.

### Human Verification Required

None. All phase outputs are programmatically verifiable:
- Drift gate scripts: runnable and verified
- Tests: runnable and verified passing
- Capability declarations: grep-verifiable
- Documentation content: grep-verifiable against locked labels
- Compile: verified exit 0

No visual UI, real-time behavior, or external service integration was introduced.

### Gaps Summary

No gaps. All 8 truths verified, all 14 artifacts substantive and wired, both CI scripts exit 0, both test files pass. The phase goal is fully achieved.

---

_Verified: 2026-05-25T16:50:00Z_
_Verifier: Claude (gsd-verifier)_
