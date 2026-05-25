# Phase 130: Provider Honesty + Fake-Lane Proof + Example-Host Wiring - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

> **How these decisions were made:** Per the project's standing cohesive-one-shot-synthesis posture
> (`.planning/config.json` → `discuss_auto_all_gray_areas` + `discuss_high_impact_confirm` +
> `discuss_auto_resolve_low_impact`, bar = `discuss_high_impact_confirm_bar`; memory
> `feedback_decision_synthesis_style`). This phase is **unusually pre-resolved**: Phase 125
> (Provider Honesty + Lifecycle Truth) is a near-exact template for the SC#1/SC#2 drift-gate work;
> the `dunning-depth-milestone-prep` thread pre-resolved the provider-honesty framing (Stripe Smart
> Retries + Test Clocks, Braintree clock-driven-NOT-retry-aligned, Fake deterministic proof lane);
> Phases 128/129 locked the campaign engine + observability contracts the docs/proof must describe;
> and `config.json` carries a `discuss_default_dunning_phase_boundary` key locking Phase 130 =
> DUN-09/DUN-10. All four gray areas were evaluated against the confirm bar and **all auto-resolve**
> (internal file-org, additive-safe public docs/labels, reversible host-config crons) — so fresh
> parallel advisor agents would re-derive established precedent. The synthesis below is grounded in
> the pre-resolved thread + the Phase 125 drift-gate template + the Phase 128/129 contexts + a
> codebase scout (re-verified `file:line` anchors). **ZERO open forks** — none crossed the bar.
> Build on this; do not re-derive.

<domain>
## Phase Boundary

**DUN-09, DUN-10 only.** On top of the Phase 128 engine + Phase 129 observability, make dunning
**honest, provable, and demonstrated**:
- **Provider-honest docs (DUN-09, SC#1):** a `guides/` home that documents per-provider dunning
  behavior truthfully — Stripe (native Smart Retries timing **+** Accrue's email cadence on top;
  Stripe Test Clocks for the real-Stripe E2E lane), Braintree (Accrue-clock-driven cadence off
  `past_due_since`/anchor, explicitly **NOT** retry-aligned — Braintree has no smart-retry overlay),
  Fake (the deterministic proof lane) — with a lifecycle/capability truth note tying back to
  `lifecycle_semantics.md`.
- **Merge-blocking drift check (DUN-09, SC#2):** where per-provider dunning labels are claimed, a
  merge-blocking gate fails the build if the runtime capability labels and the published doc diverge —
  mirroring the SCM-06 / PROC-24 / Phase-125 entitlements support-contract pattern.
- **Deterministic Fake-lane journey gate (DUN-10, SC#3):** a clock-advanceable test proving the FULL
  journey (start → step progression → cancel-on-recovery → exhaustion) that runs as a merge-blocking
  gate, **exercised through the real webhook entry point** (the cross-phase graduation lesson:
  "a fully green suite can hide a feature dead on the production path").
- **Example-host wiring (DUN-10, SC#4):** the default campaign wired into `examples/accrue_host` so
  failed-payment recovery is demonstrated end-to-end, closing the dormant-cron gap (recovery is no
  longer invisible until an adopter reads a guide and adds a crontab).

**In scope:** a new `accrue/guides/dunning.md` (per-provider behavior + Test Clocks note + over-email
warning + lifecycle/capability truth note); a `dunning:` capability group in
`Accrue.Processor.Capabilities` + `capabilities/0` rows in Fake/Stripe/Braintree + the matching rows
in `.planning/processor-support-matrix.md`; an extension of `scripts/ci/verify_processor_support_matrix.sh`
(honest divergence labels + a convergence guard); a deterministic Fake-lane full-journey test driven
through `Accrue.Webhook.DefaultHandler`; the `accrue_dunning` queue + `Oban.Plugins.Cron`
(`DunningSweeper`, and proactively `DetectExpiringCards`) wired into `examples/accrue_host`; a
Fake-backed merge-blocking host proof of the failed-payment→campaign→recovery loop + an
adoption-proof-matrix row.

**Out of scope (explicitly later phases — do NOT pull forward):**
- `Accrue.Dunning.Engine` behaviour + off-by-default conditionally-compiled Chimeway adapter →
  DUN-03, **Phase 131** (verify Chimeway's published 1.0.0 API first; guide-vs-code mismatch).
- Entitlements adopter-proof demo (entitlement-gated route/page in the host + matrix row) → PROOF-03,
  **Phase 132** (independent of dunning).
- Full recovered-revenue analytics dashboard, multi-channel (SMS/push/in-app), per-customer cadence,
  provider-native dunning-email *coordination* beyond a doc warning → **milestone Out-of-Scope** (carried).
- New campaign engine behavior, new ledger/telemetry events, new config keys — those shipped in
  Phases 128/129. This phase **documents, gates, proves, and wires** what exists; it does not extend
  the engine. (Bug-fixes uncovered by the real-entry-point proof are in scope as corrections.)

</domain>

<decisions>
## Implementation Decisions

### A. Provider-honest docs home + structure (DUN-09, SC#1)

- **D-01 — NEW `accrue/guides/dunning.md` (do NOT cram it into `lifecycle_semantics.md`).** The dunning
  surface is now substantial — multi-step campaign, per-step copy, per-provider retry semantics, Stripe
  Test Clocks, the over-email warning, the recovery/exhaustion loop — large enough to warrant its own
  guide. `lifecycle_semantics.md` stays the **lifecycle SSOT** (its existing `### past_due` section at
  ~:150-211 already owns the `past_due`/`unpaid`/grace truth table); the new dunning guide
  **cross-references** that section rather than re-deriving lifecycle truth (PITFALLS #2). Auto-discovered
  by the ExDoc wildcard `Path.wildcard("guides/*.md")` (`accrue/mix.exs:134-135`) — no `mix.exs` edit
  needed for registration. *(Rationale: internal file-org, reversible, auto-resolves. Phase 125 extended
  an existing guide because the entitlements lifecycle truth literally belonged in the lifecycle SSOT;
  here the dunning *mechanism* is its own concern.)*
- **D-02 — The honest per-provider story (the doc's spine):**
  - **The campaign is provider-INDEPENDENT.** Accrue's multi-step email cadence is driven off local
    `dunning_campaign_started_at` / `past_due_since` and `Accrue.Clock`, making **zero processor calls** —
    so the cadence behaves **identically** across Stripe, Braintree, and Fake. This is a *strength* and
    the convergent claim (mirrors the Phase 125 entitlements `local-identical` framing).
  - **Smart-retry alignment is where providers DIVERGE (the honest caveat):**
    - **Stripe** — has native **Smart Retries** (1–4 week adaptive payment-retry schedule). Accrue's
      email cadence runs *on top of* it; document the coexistence + the over-email risk (D-04). Stripe
      **Test Clocks** are the tool for the real-Stripe E2E lane (advisory, network-gated — NOT the
      merge gate).
    - **Braintree** — **no smart-retry overlay**; Accrue's clock-driven cadence is the *only* cadence.
      Explicitly **NOT retry-aligned**. Honest and important: a Braintree host gets Accrue's emails but
      no processor-native payment retries beyond Braintree's own dunning settings.
    - **Fake** — the **deterministic proof lane**; clock-advanceable, the substrate for SC#3's gate.
  - A **lifecycle/capability truth note**: link `lifecycle_semantics.md` (`past_due`/`unpaid`/grace) +
    the `entitlements.past_due_grace` interaction (a past-due sub may still be *entitled* within grace
    while the campaign emails — they are orthogonal knobs).
- **D-03 — Document, don't re-spec.** The guide describes the SHIPPED contract (the D-01 default journey
  `[0, 5, 12]`, the `campaign:` config under `:dunning`, the `dunning_campaign_*` accessors, the four
  `dunning.*` ledger events + `[:accrue, :ops, :dunning_*]` telemetry from Phase 129). It does not invent
  new behavior. Use `Accrue.Config.dunning_campaign_steps/0` shape and the real module/atom names as the
  source of truth so prose can be drift-gated against code (D-06).
- **D-04 — Over-email warning + opt-out posture (the carried-forward note + Phase 128 D-03).** The guide
  carries a prominent warning: if a host has **Stripe Dashboard dunning emails** enabled, Accrue's cadence
  can double-email; recommend disabling one side (Accrue via `dunning: [campaign: [enabled: false]]` /
  `campaign: false`, or the Stripe Dashboard emails). The *posture* (ship `enabled: true`, deliberately
  sparse 0/5/12 spacing limits collision damage; full provider-native coordination deferred) was decided
  in Phase 128 D-03 — this phase only writes the warning.

### B. Merge-blocking drift gate — shape + home (DUN-09, SC#2)

- **D-05 — EXTEND the existing processor support-contract artifacts; do NOT create a dedicated dunning
  gate.** Add a `dunning:` group to `Accrue.Processor.Capabilities` (`@support_labels` +
  `@provider_support_labels`), matching `capabilities/0` rows in the three adapters, the rows in
  `.planning/processor-support-matrix.md`, and `require_substring`/stale-row guards in
  `scripts/ci/verify_processor_support_matrix.sh`. This is the **exact Phase 125 D-06 move** and honors
  the locked `processor_support_matrix_public_ssot_capabilities_code_mirror_same_pr_co_update` config rule
  (one code module → one doc SSOT → one gate, co-updated same PR). It rides the existing merge-blocking
  `docs-contracts-shift-left` CI job — **no new CI step** (`.github/workflows/ci.yml:30-47`).
  *(Considered + rejected: a dedicated `verify_dunning_docs.sh` — cleaner layer separation but a
  split-brain SSOT against shared code labels + a second artifact; revisit only if the dunning section
  materially bloats the processor script. Reversible.)*
- **D-06 — The honest capability rows = ONE convergence row + ONE divergence row** (resist matrix bloat):
  - `dunning.campaign` → **convergent**: Fake/Stripe/Braintree all `"local-identical"` (Accrue-clock-driven,
    processor-independent cadence); public label `"all first-party"`. Mirror the
    `entitlements.local_mapping` convergence row.
  - `dunning.smart_retry_alignment` → **divergent** (the honest contrast, like `subscription.swap_plan`):
    Stripe `"native (Smart Retries)"`, Braintree `"unsupported (clock-driven only)"`, Fake
    `"testing/local-only"` (or the established Fake lane term); public label honest about the divergence.
    Reuse the existing label vocabulary (`native` / `bounded first-party` / `unsupported` /
    `testing/local-only`) — do NOT invent new terms for the divergence row (the `local-identical` term
    already exists from Phase 125 for the convergence row).
- **D-07 — Gate assertions mirror the Phase 125 D-08 style:** `require_substring` pins for the
  convergence-row label + the divergence-row per-provider labels + the honest prose ("the campaign cadence
  behaves identically across Stripe, Braintree, and Fake", "Braintree is not retry-aligned", "Stripe Smart
  Retries run beneath Accrue's cadence"); **plus a NEGATIVE guard** that fails the build if the
  `dunning.campaign` convergence row ever sprouts a per-provider `native`/`unsupported`/`bounded`
  divergence label (drift back toward implied divergence) — exactly the entitlements-convergence guard
  pattern at `verify_processor_support_matrix.sh:105-119`.
- **D-08 — The PUBLIC guide is drift-gated too, lightly.** Unlike Phase 125 (which kept the gate at the
  `.planning/` SSOT only because Phase 126 owned the public guide), here the public `guides/dunning.md` IS
  this phase's deliverable AND SC#2 says "the published doc." So the same gate adds a small set of
  `require_substring` pins against `accrue/guides/dunning.md` for the per-provider labels it claims (the
  guide must restate the capability labels verbatim, or reference them). Keep it minimal — pin the
  load-bearing per-provider claims, not every sentence. The code labels, the `.planning/` matrix, and the
  public guide are co-updated in the SAME PR (the established co-update discipline).
- **D-09 — A code-side mirror in the Fake-lane proof (cheap, strong).** The SC#3 journey test (group C)
  additionally asserts the new `Capabilities` `dunning.*` labels equal the doc literals (the code-side
  mirror of the bash gate, exactly as Phase 125 D-05 did for entitlements) so a label change that misses
  the doc breaks `mix test`, not just the bash gate.

### C. Deterministic Fake-lane full-journey proof (DUN-10, SC#3) — through the REAL entry point

- **D-10 — Drive the journey through `Accrue.Webhook.DefaultHandler`, not by enqueuing `DunningStep`
  directly.** This is the load-bearing decision and the explicit cross-phase graduation lesson ("the
  Fake-lane gate must exercise the real entry point"; STATE.md Blockers/Concerns). The proof:
  1. Feed an `invoice.payment_failed` fixture through the real handler → assert the first-transition
     elector wins (`dunning_campaign_started_at` set, day-0 `DunningStep` enqueued). The
     `dunning_campaign_start_test.exs` precedent already drives this path — extend it to the full journey.
  2. **Advance the clock** via `Accrue.Test.Clock.advance/2` (which delegates to `Accrue.Processor.Fake`;
     `Accrue.Clock.utc_now/0` reads `:accrue, :env == :test` → `Fake.now/0`, `clock.ex:26-31`) and
     **drain** the `:accrue_dunning` queue (`Oban.drain_queue/2`; Oban runs `testing: :manual` per
     `test_helper.exs:51`) to fire each scheduled step → assert step progression (`:reminder` →
     `:action_required` → `:final_notice`) with the chained `schedule_in` honored.
  3. **Cancel-on-recovery:** feed an `invoice.paid` (or status→active) fixture through the real handler
     mid-journey → assert the anchor is nilled, scheduled steps are cancelled, no further emails, and the
     `dunning.recovered` event fired.
  4. **Exhaustion:** in a sibling scenario, let the journey run to the final step + the grace→terminal
     `DunningSweeper` (also drained) → assert `:unpaid`/`:canceled` transition + `dunning.exhausted`.
- **D-11 — It is "merge-blocking" by being an ordinary untagged test in the default suite.** The scout
  confirmed there is **no `:release_gate` tag** — the default `mix test` (the CI merge gate) runs
  everything except `@tag :live_stripe | :slow | :compile_matrix` (`test_helper.exs:70`). So the journey
  test is a normal `ExUnit` file under `accrue/test/.../dunning_*` that is simply **not** tagged slow/live.
  It MUST stay deterministic (clock-advance + drain, never `Process.sleep`, never a network call) so it
  never earns a `:slow`/`:live_stripe` tag. Use `Accrue.BillingCase` (the Fake-backed DB case the existing
  dunning tests use) with `:processor` = `Accrue.Processor.Fake`.
- **D-12 — Assert the OBSERVABLE contract too (ties SC#3 to Phase 129).** Capture telemetry
  (`[:accrue, :ops, :dunning_*]`) and/or read `accrue_events` (`dunning.campaign_started`/`step_sent`/
  `recovered`/`exhausted`) at each journey stage so the proof doubles as the end-to-end check that the
  Phase-129 observability fires on the real path — not just that emails send.

### D. Example-host wiring + demonstration vehicle (DUN-10, SC#4)

- **D-13 — Wire the missing Oban plumbing: `accrue_dunning` queue + `Oban.Plugins.Cron`.** The scout found
  the host's `examples/accrue_host/config/config.exs:37-44` has queues `accrue_webhooks`/`accrue_mailers`/
  `accrue_pdf` but **no `accrue_dunning`** and **no Cron plugin** — so a day-0 `DunningStep` cannot even
  enqueue today (the campaign is dead on the host path). Add `accrue_dunning: 2` (matching the documented
  recommendation) and an `Oban.Plugins.Cron` entry. The campaign itself is **webhook-triggered + Oban-self-
  chained** (not cron) — so the queue is the load-bearing fix; the cron is for the terminal sweeper that
  COMPLETES the journey.
- **D-14 — Wire the recovery crons so recovery is no longer dormant: `Accrue.Jobs.DunningSweeper` (and the
  sibling `Accrue.Jobs.DetectExpiringCards`).** The roadmap SC#4 + the `adopter-proof-gaps` thread both
  name the "dormant-cron gap" (recovery invisible until an adopter adds a crontab). `DunningSweeper` is the
  grace→terminal step that produces *exhaustion* end-to-end, so it is **required** for the journey to be
  demonstrable. `DetectExpiringCards` is a *proactive* (pre-failure, card-expiry) recovery axis — a
  sibling, not the failed-payment dunning loop; wire it too for completeness since it is the same
  "dormant cron" class, but it is the **discretion item** most safely droppable if the planner wants to
  scope tightly to the dunning loop (reversible host config either way — see Claude's Discretion).
- **D-15 — Campaign stays ENABLED in the host (it is the demo).** The host uses the shipped `enabled: true`
  default — no opt-out in the example. The over-email warning (D-04) is documentation, not host config.
- **D-16 — Demonstration vehicle = a Fake-backed merge-blocking host proof + an adoption-proof-matrix row
  (NOT a new visible LiveView/seed).** SC#4 says "demonstrated end-to-end"; the canonical proof surface is
  the adoption-proof matrix's **deterministic Fake-first blocking lane**
  (`examples/accrue_host/docs/adoption-proof-matrix.md`, gated by
  `scripts/ci/verify_adoption_proof_matrix.sh`). Add a host-level test that drives a failed-payment →
  campaign-step → recovery loop through the host's wired Oban (Fake processor, clock-advance + drain) and a
  matching matrix row (+ verifier needle). This matches the existing matrix structure (no new UI surface
  needed; the customer recovery banner already shipped in Phase 129, and Phase 132 owns the host's *visible*
  demo work for entitlements). A visible seed/LiveView demo is **deferred** unless the planner finds the
  test-only proof insufficient for the matrix contract.

### Claude's Discretion (planner decides)
- Exact `guides/dunning.md` section ordering and how much of the campaign config reference to inline vs link
  to the `Accrue.Config` moduledoc.
- Exact capability-path atoms/label strings for the `dunning.*` rows (D-06) — keep to the established
  vocabulary; one convergence + one divergence row is the target, a planner MAY add at most one honesty row
  (e.g. `dunning.test_clock_support`) but should resist matrix bloat.
- Whether `DetectExpiringCards` is wired into the host cron alongside `DunningSweeper` (D-14) or scoped out
  to keep the demo focused on the failed-payment dunning loop — reversible host config.
- The exact home/name of the Fake-backed host journey test and whether the full-journey proof lives once in
  `accrue` (core, against the real handler) with a thinner host-level "the wiring works" smoke, vs duplicated
  — prefer the rich proof in `accrue` (D-10) + a focused host wiring/smoke proof (D-16) to avoid duplication.
- Exact `require_substring` needles + their split across the `.planning/` matrix vs the public guide (D-08).
- Cron schedule expression for the host sweeper (e.g. hourly/daily) — match the operator-runbook guidance.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope & milestone context (read first)
- `.planning/ROADMAP.md` §"Phase 130" — goal, depends-on (128 engine, 129 events/surfaces), the 4 success
  criteria + the carried-forward over-email note (~:85-99).
- `.planning/REQUIREMENTS.md` — DUN-09, DUN-10 (this phase); DUN-03 / PROOF-03 (later-phase boundary).
- `.planning/threads/dunning-depth-milestone-prep.md` — the pre-resolved provider-honesty framing (Stripe
  Smart Retries + Test Clocks, Braintree not-retry-aligned, Fake proof lane), the over-email avoid-item,
  and the Test-Clocks-for-real-Stripe-only stance. **Authoritative.**

### The Phase 125 drift-gate template (mirror this EXACTLY for dunning)
- `.planning/phases/125-provider-honesty-lifecycle-truth/125-CONTEXT.md` — D-02 (capability group +
  `@support_labels`/`@provider_support_labels` + adapter `capabilities/0` rows), D-05 (Fake-lane code-side
  label mirror), D-06 (EXTEND the existing matrix/gate, don't create a dedicated one), D-08 (gate
  assertions: `require_substring` + stale-row + **negative convergence guard**), D-09 (CI wiring + same-PR
  co-update discipline). This phase is the dunning analog.

### Upstream engine + observability contracts (what the docs/proof describe)
- `.planning/phases/128-campaign-engine-foundation-idempotency-must-fix/128-CONTEXT.md` — the campaign
  engine: default journey `[0,5,12]` (D-01), `campaign:` config DSL under `:dunning` (D-04), anchor
  `dunning_campaign_started_at` + first-transition elector (D-08/D-09), `DunningStep` chaining + cancel
  guard (D-10/D-11), cancel-on-recovery (D-12), idempotency (D-13..D-17), and **D-03 (the over-email
  opt-out posture this phase documents)**.
- `.planning/phases/129-customer-operator-surfaces-observability/129-CONTEXT.md` — the observable contract
  the journey proof asserts: `[:accrue, :ops, :dunning_*]` telemetry family (D-01) + `dunning.*` ledger
  events (D-02) + emission points (D-03) + the drift-gate obligation (D-04).

### Source files to extend/clone (full relative paths, re-verified by scout)
- `accrue/lib/accrue/processor/capabilities.ex` — `@support_labels` (:11-64), `@provider_support_labels`
  (:66-126), the entitlements convergence block (:103-112) + divergence block (:113-125); add the
  `dunning:` group mirroring these.
- `accrue/lib/accrue/processor/{fake,stripe,braintree}.ex` — `capabilities/0` (Fake :220-241, Stripe
  :79-99, Braintree :17-45); add `dunning: %{...}` rows.
- `scripts/ci/verify_processor_support_matrix.sh` — `require_substring` (:13-20), stale-row guards
  (:65-103), the entitlements convergence NEGATIVE guard (:105-119), `: OK` (:121); extend in place.
- `.planning/processor-support-matrix.md` — the `| Capability | Fake | Stripe | Braintree | Public label |`
  table (:31-60); add the dunning rows (currently NONE exist).
- `.github/workflows/ci.yml` — the merge-blocking `docs-contracts-shift-left` job (:30-47, runs the matrix
  verifier at :47) + `verify_adoption_proof_matrix.sh` (:65); no new CI step needed.
- `accrue/lib/accrue/dunning/campaign.ex` — `next_step/3` (:79-94, `{:next, step, schedule_in} | :done`,
  pure) — the resolver the docs describe and the proof drains against.
- `accrue/lib/accrue/workers/dunning_step.ex` — queue `:accrue_dunning` + `max_attempts: 3` (:64),
  cancel-guard-first perform (:82-109), `unique` keys (:143-150).
- `accrue/lib/accrue/webhook/default_handler.ex` — `maybe_bump_past_due_since` + `maybe_start_dunning_campaign`
  (:1146-1212, the first-transition elector the proof drives), the recovery clear + cancel
  (:806-895/:925-946), `maybe_emit_dunning_exhaustion` (:758-781).
- `accrue/lib/accrue/clock.ex` — `utc_now/0` (:26-31, `:test` → `Fake.now/0`).
- `accrue/lib/accrue/test/clock.ex` — `advance/2` (the deterministic no-sleep clock advance for the proof).
- `accrue/lib/accrue/jobs/dunning_sweeper.ex` — the grace→terminal sweeper (drained in the exhaustion proof;
  wired as the host cron) + `Accrue.Clock.utc_now/0` (:101).
- `accrue/lib/accrue/jobs/detect_expiring_cards.ex` — the proactive-recovery sibling cron (D-14 discretion).
- `accrue/lib/accrue/billing/subscription.ex` — `past_due?/1` (:155-158), `dunning_campaign_active?/1`
  (:269-272), `dunning_campaign_started_at` (:66).
- `accrue/lib/accrue/events.ex` — `bucket_by/2` / `timeline_for/3` (read the `dunning.*` events in the proof).
- `accrue/guides/lifecycle_semantics.md` — the `### past_due` section (~:150-211) the new dunning guide
  cross-references (lifecycle SSOT — do NOT re-derive truth there).
- `accrue/mix.exs` — ExDoc `extras: [...] | Path.wildcard("guides/*.md")` (:134-135) — new guide
  auto-discovered.

### Example host (SC#4)
- `examples/accrue_host/config/config.exs` — Oban config (:37-44): queues missing `accrue_dunning`, no Cron
  plugin (the gap to close).
- `examples/accrue_host/lib/accrue_host/application.ex` — supervision tree (:10-21, `{Oban, ...}` :14).
- `examples/accrue_host/docs/adoption-proof-matrix.md` — the proof-posture contract (Fake-backed blocking
  lane :14-26; structure to add a dunning row to).
- `scripts/ci/verify_adoption_proof_matrix.sh` — the matrix drift gate (add the dunning needle).
- `examples/accrue_host/lib/accrue_host/billing.ex` — the host facade (what the host exercises).

### Established test patterns
- `accrue/test/accrue/webhook/dunning_campaign_start_test.exs` — the REAL-entry-point test precedent to
  extend to the full journey (drives `invoice.payment_failed` through `DefaultHandler`).
- `accrue/test/test_helper.exs` — Oban `testing: :manual` (:51), default-suite exclusions
  `[:live_stripe, :slow, :compile_matrix]` (:70) → "merge-blocking" = untagged default test.
- `accrue/test/accrue/jobs/dunning_sweeper_test.exs` — Fake-seed + `Accrue.BillingCase` pattern.

### External (verify-before-coding, advisory only)
- Stripe Smart Retries (cadence coexistence + over-email): https://docs.stripe.com/billing/revenue-recovery/smart-retries
- Stripe Test Clocks (real-Stripe E2E lane only, NOT the merge gate):
  https://docs.stripe.com/billing/testing/test-clocks
- Oban `drain_queue/2` + `:manual` testing: https://hexdocs.pm/oban/Oban.html — installed Oban is **2.22.1**
  (per Phase 128 note), not the 2.21 in CLAUDE.md.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets (clone, don't reinvent)
- **Phase 125 drift-gate triplet** — `Processor.Capabilities` group + `.planning/processor-support-matrix.md`
  rows + `verify_processor_support_matrix.sh` `require_substring`/stale-row/negative-convergence guards.
  The dunning gate is the exact analog (D-05..D-09).
- **`entitlements.local_mapping` convergence row + its negative guard** (`verify_processor_support_matrix.sh:105-119`)
  — the template for the `dunning.campaign` convergence row + guard (D-06/D-07).
- **`subscription.swap_plan` divergence rows** (`native`/`bounded`/`local-only`) — the template for the
  `dunning.smart_retry_alignment` divergence row (D-06).
- **`Accrue.Test.Clock.advance/2` + `Oban.drain_queue/2`** — the deterministic no-sleep journey-advance
  mechanics (D-10/D-11). `Accrue.Clock.utc_now/0` already reads `:test` env → `Fake.now/0`.
- **`dunning_campaign_start_test.exs`** — the real-webhook-entry-point precedent; extend, don't restart (D-10).
- **`Accrue.Jobs.DunningSweeper` + `DetectExpiringCards`** — existing cron jobs (built, host-unwired) to add
  to the host `Oban.Plugins.Cron` (D-13/D-14).
- **ExDoc `guides/*.md` wildcard** — new guide auto-registered (D-01).
- **Adoption-proof-matrix Fake-backed blocking lane + `verify_adoption_proof_matrix.sh`** — the demonstration
  contract surface (D-16).

### Established Patterns (constrain this phase)
- **Support-contract SSOT (SCM-06 / PROC-24 / Phase-125):** code labels ↔ published matrix doc ↔ (here also)
  public guide, pinned by a merge-blocking drift gate, co-updated same PR.
- **Real-entry-point testing (the graduation lesson):** prove features through `Accrue.Webhook.DefaultHandler`,
  not unit handlers — "a fully green suite can hide a feature dead on the production path."
- **Deterministic Fake lane is the merge gate; provider lanes are advisory** (`discuss_default_processor_fake_lane`,
  `discuss_default_processor_provider_lanes`) — Stripe Test Clocks are advisory/network-gated, never the merge gate.
- **No-new-table / reuse-existing / additive-safe** — this phase adds docs, capability rows, a test, and host
  config; no schema, no new engine behavior.
- **Host owns its Oban** (Accrue never starts Oban) — the queue + cron go in `examples/accrue_host`, not core.

### Integration Points
- Edit `processor/capabilities.ex` + `processor/{fake,stripe,braintree}.ex` (dunning capability rows).
- Edit `verify_processor_support_matrix.sh` + `.planning/processor-support-matrix.md` (drift gate + doc rows)
  + small public-guide needles (D-08).
- New `accrue/guides/dunning.md` (D-01..D-04).
- New deterministic full-journey test under `accrue/test/.../dunning_*` driven through `DefaultHandler` (D-10..D-12).
- Edit `examples/accrue_host/config/config.exs` (`accrue_dunning` queue + `Oban.Plugins.Cron`) + a host-level
  Fake-backed journey/wiring proof + `examples/accrue_host/docs/adoption-proof-matrix.md` row +
  `verify_adoption_proof_matrix.sh` needle (D-13..D-16).
- **Engine-seam readiness (Phase 131):** the docs/proof key on `step_key` + `campaign_started_at` + the pure
  `next_step/3` resolver so a later `Accrue.Dunning.Engine`/Chimeway adapter inherits the same documented
  contract + passes the same Fake-lane gate.

</code_context>

<specifics>
## Specific Ideas

- **The honesty statement is the convergence/divergence contrast made legible:** the `dunning.campaign` row
  (local-identical across all three) says "the cadence works the same everywhere"; the
  `dunning.smart_retry_alignment` row (Stripe native / Braintree unsupported / Fake testing) says "but
  processor-native payment retries differ." That contrast IS the provider-honest claim — exactly the Phase
  125 entitlements-convergence-vs-swap_plan-divergence pattern.
- **The one carried-forward must-say:** Braintree hosts get Accrue's email cadence but **no smart-retry
  overlay** — do not imply retry alignment. And Stripe hosts must read the over-email warning.
- **The proof's whole point is the real path:** if the journey test enqueued `DunningStep` directly it could
  pass while the webhook wiring is dead (the exact failure mode caught at code review in Phases 126 & 127).
  Drive `invoice.payment_failed` and `invoice.paid` through `DefaultHandler`; advance the clock; drain Oban.
- **The host gap is concrete, not theoretical:** today a failed payment on the example host cannot start a
  campaign step (no `accrue_dunning` queue) — wiring it is what makes "recovery demonstrated end-to-end" true.
- **Test Clocks are documented, not gated:** the merge gate is the deterministic Fake lane; Stripe Test
  Clocks are the *documented* tool for the advisory real-Stripe E2E lane only.

</specifics>

<deferred>
## Deferred Ideas

- **`Accrue.Dunning.Engine` behaviour + off-by-default conditionally-compiled Chimeway adapter** — DUN-03,
  **Phase 131** (verify Chimeway's published 1.0.0 API first; guide-vs-code mismatch). Keep the docs/proof
  keyed on the pure resolver + `step_key`/`campaign_started_at` so the adapter inherits the contract.
- **Entitlements adopter-proof demo (entitlement-gated route/page in the host + matrix row)** — PROOF-03,
  **Phase 132** (independent of dunning; owns the host's *visible* demo work).
- **A visible host seed / LiveView "watch a campaign run" demo surface** — deferred (D-16); the Fake-backed
  blocking test + matrix row is the SC#4 proof. Add a visible demo only on a sourced need.
- **A dedicated `verify_dunning_docs.sh` + standalone dunning support matrix** — the layer-separated
  alternative to D-05; revisit only if the dunning section bloats the processor script.
- **Provider-native dunning-email *coordination* beyond a doc warning** (e.g. auto-detecting Stripe Dashboard
  emails) — milestone Out-of-Scope; the over-email warning (D-04) is the v1.40 answer.
- **Full recovered-revenue analytics dashboard, multi-channel (SMS/push/in-app), per-customer cadence** —
  milestone Out-of-Scope (carried).
- **Wiring `DetectExpiringCards` into the host cron** — folded in by D-14 for completeness but flagged as the
  most safely droppable item if the planner scopes tightly to the failed-payment dunning loop (reversible).

### Reviewed Todos (not folded)
None — no pending todos matched this phase (`todo.match-phase 130` → 0 matches).

</deferred>

---

*Phase: 130-provider-honesty-fake-lane-proof-example-host-wiring*
*Context gathered: 2026-05-25*
