# Phase 130: Provider Honesty + Fake-Lane Proof + Example-Host Wiring — Research

**Researched:** 2026-05-25
**Domain:** Elixir/Phoenix dunning documentation, drift-gate CI, deterministic Oban testing, example-host wiring
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01** — New `accrue/guides/dunning.md` (not cramped into `lifecycle_semantics.md`). Auto-discovered by ExDoc `Path.wildcard("guides/*.md")` in `accrue/mix.exs:134-135` — no `mix.exs` edit needed.

**D-02** — Provider-honest doc spine: campaign is provider-INDEPENDENT (local-identical across Stripe/Braintree/Fake); smart-retry alignment is where providers DIVERGE (Stripe native Smart Retries, Braintree clock-driven-NOT-retry-aligned, Fake deterministic proof lane).

**D-03** — Document, don't re-spec. Describe the shipped contract only (default journey `[0, 5, 12]`, `campaign:` DSL, accessors, four ledger events + telemetry from Phase 129).

**D-04** — Over-email warning + opt-out posture: prominent warning that Stripe Dashboard dunning emails + Accrue cadence can double-email; recommend disabling one side. The *posture* shipped in Phase 128; this phase writes the warning only.

**D-05** — EXTEND the existing processor support-contract artifacts; do NOT create a dedicated dunning gate. Add `dunning:` group to `Accrue.Processor.Capabilities` + matching adapter rows + `.planning/processor-support-matrix.md` rows + extensions to `scripts/ci/verify_processor_support_matrix.sh`. Rides the existing `docs-contracts-shift-left` CI job — no new CI step.

**D-06** — Exactly ONE convergence row + ONE divergence row: `dunning.campaign` (local-identical, all first-party) and `dunning.smart_retry_alignment` (Stripe native, Braintree unsupported/clock-driven-only, Fake testing/local-only). Use established label vocabulary — do NOT invent new terms.

**D-07** — Gate assertions mirror Phase 125 D-08: `require_substring` pins for convergence + divergence labels + honest prose ("campaign cadence behaves identically across Stripe, Braintree, and Fake", "Braintree is not retry-aligned", "Stripe Smart Retries run beneath Accrue's cadence") + a NEGATIVE guard that fails the build if `dunning.campaign` convergence row sprouts a divergence label.

**D-08** — Public `guides/dunning.md` is drift-gated too (lightly): a small set of `require_substring` pins against the guide for the per-provider labels it claims. Co-updated same PR.

**D-09** — Code-side mirror in the Fake-lane proof: journey test additionally asserts the new `Capabilities` `dunning.*` labels equal the doc literals (mirrors Phase 125 D-05 entitlements label mirror).

**D-10** — Drive the full journey through `Accrue.Webhook.DefaultHandler`, not by enqueuing `DunningStep` directly. The four-stage proof: (1) `invoice.payment_failed` → anchor set + day-0 enqueued, (2) clock-advance + drain → step progression, (3) `invoice.paid`/active → cancel-on-recovery, (4) exhaustion via `DunningSweeper` drain.

**D-11** — "Merge-blocking" = untagged default test (no `:release_gate` tag exists). The test MUST stay deterministic (clock-advance + Oban drain, never `Process.sleep`, never network). Use `Accrue.BillingCase` with `:processor` = `Accrue.Processor.Fake`.

**D-12** — Assert the observable contract too: capture telemetry `[:accrue, :ops, :dunning_*]` and/or read `accrue_events` at each journey stage so the proof doubles as Phase-129 observability validation on the real path.

**D-13** — Wire the missing Oban plumbing: add `accrue_dunning: 2` queue and `Oban.Plugins.Cron` entry to `examples/accrue_host/config/config.exs`.

**D-14** — Wire `Accrue.Jobs.DunningSweeper` (required for exhaustion demonstration) and `Accrue.Jobs.DetectExpiringCards` (discretion — see below) as host cron entries.

**D-15** — Campaign stays ENABLED in the host (it is the demo); over-email warning is documentation only, not host config.

**D-16** — Demonstration vehicle = Fake-backed merge-blocking host proof + adoption-proof-matrix row + `verify_adoption_proof_matrix.sh` needle. No new LiveView/seed surface.

### Claude's Discretion (planner decides)

- Exact `guides/dunning.md` section ordering and inline vs. linked config reference depth.
- Exact capability-path atoms/label strings for `dunning.*` rows (one convergence + one divergence; planner MAY add at most one honesty row e.g. `dunning.test_clock_support` but should resist matrix bloat).
- Whether `DetectExpiringCards` is wired into the host cron (D-14) or scoped out — reversible.
- Whether the full-journey proof lives once in `accrue` + thin host wiring smoke, vs. duplicated — prefer the rich proof in `accrue` + focused host smoke to avoid duplication.
- Exact `require_substring` needles and their split across `.planning/` matrix vs. public guide.
- Cron schedule expression for the host sweeper (e.g., hourly/daily).

### Deferred Ideas (OUT OF SCOPE)

- `Accrue.Dunning.Engine` behaviour + off-by-default Chimeway adapter → Phase 131.
- Entitlements adopter-proof demo → Phase 132.
- Visible host seed / LiveView "watch a campaign run" demo surface.
- A dedicated `verify_dunning_docs.sh` + standalone dunning support matrix.
- Provider-native dunning-email coordination beyond a doc warning.
- Full recovered-revenue analytics dashboard, multi-channel (SMS/push/in-app), per-customer cadence.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DUN-09 | Dunning behavior is provider-honest and documented — Stripe (Smart Retries timing + Accrue cadence; Test Clocks for real-Stripe E2E lane), Braintree (Accrue-clock-driven, explicitly not retry-aligned), Fake (deterministic proof lane) — in `guides/` with lifecycle/capability truth note and merge-blocking drift check where labels are claimed. | SC#1: new `guides/dunning.md` with per-provider prose; SC#2: `dunning:` capability group in `Capabilities` + adapter rows + matrix rows + `verify_processor_support_matrix.sh` extensions (D-05 through D-09). |
| DUN-10 | A deterministic, clock-advanceable Fake-lane test proves the full journey (start → step progression → cancel-on-recovery → exhaustion) as a merge-blocking gate, and the default campaign is wired into `examples/accrue_host` so recovery is demonstrated end-to-end (closing the dormant-cron gap). | SC#3: full-journey test through `DefaultHandler` + clock-advance + drain (D-10 through D-12); SC#4: host config + cron wiring + host-level proof + adoption-proof-matrix row (D-13 through D-16). |
</phase_requirements>

---

## Summary

Phase 130 is a documentation, drift-gate, proof, and wiring phase — it does NOT extend the campaign engine. The campaign engine shipped in Phase 128 (DUN-01/02/04/05) and the observability contract shipped in Phase 129 (DUN-08). This phase documents what exists honestly, gates the documentation against code drift, proves the full journey deterministically, and wires the host so recovery is no longer dormant.

The work divides into four tightly coupled deliverables: (A) `guides/dunning.md` with per-provider honest prose; (B) a `dunning:` capability group added to the existing processor support-contract stack (Capabilities module + adapters + `.planning/` matrix + `verify_processor_support_matrix.sh`); (C) a full-journey deterministic Fake-lane test through the real `DefaultHandler` entry point; (D) host Oban queue + cron wiring + a host-level Fake-backed proof + adoption-proof-matrix row.

The entire phase is additive-safe: no new tables, no new config keys, no new engine behavior, no schema migrations. The only runtime-visible change to a host is the `accrue_dunning` queue + cron entries added to `examples/accrue_host/config/config.exs`, which are absent today and cause the dunning campaign to be silently dead on the host path.

**Primary recommendation:** Mirror the Phase 125 entitlements drift-gate pattern exactly for dunning. The code, the planning matrix, and the public guide are co-updated in ONE PR gated by the existing `docs-contracts-shift-left` CI job — no new CI step is needed or correct.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Provider-honest dunning guide (`guides/dunning.md`) | Library docs | — | Describes the already-shipped engine; no new runtime code |
| Drift gate: `dunning:` capability rows in `Capabilities` | API / Library core | — | Code labels are the SSOT; the bash gate compares the matrix doc against these labels |
| Drift gate: processor-support-matrix rows + bash gate | CI / docs contract | — | The matrix is the public SSOT; the bash gate is the CI enforcer |
| Full-journey Fake-lane proof | Test layer (`accrue` package) | — | Proves the real webhook → Oban chain deterministically |
| Example-host Oban wiring (queue + cron) | Host application config | Oban | The host owns its Oban; Accrue never starts Oban |
| Host-level Fake-backed proof + adoption-proof-matrix row | Host test + docs contract | CI | Demonstrates the wiring works end-to-end from the host perspective |

---

## Standard Stack

This phase is primarily an Elixir/Oban/ExUnit phase. No new hex dependencies are introduced. All libraries listed below are already in `mix.lock`.

### Core (already installed)
| Library | Version in use | Purpose in this phase |
|---------|---------------|----------------------|
| `oban` | 2.22.1 (installed; CLAUDE.md says 2.21, but Phase 128 notes confirmed 2.22.1) | `Oban.drain_queue/2`, `Oban.Plugins.Cron`, `Oban.Testing` helpers |
| `ex_unit` | stdlib | Journey test + host proof |
| `:telemetry` | 1.3.x | Asserting `[:accrue, :ops, :dunning_*]` events in the journey proof |

### No new dependencies
This phase installs no new hex packages. The Package Legitimacy Audit section is omitted (no packages to audit).

---

## Architecture Patterns

### System Architecture Diagram

```
Phase 130 deliverable flow:

[guides/dunning.md] ──────────────────────────────────────────────────────┐
      (doc prose with per-provider labels)                                  │
                                                                            ▼
[Accrue.Processor.Capabilities] ◄── dunning: group added                  │
      @support_labels[:dunning][:campaign] = "all first-party"             │
      @provider_support_labels[:dunning][:campaign] = local-identical x3   │
      @provider_support_labels[:dunning][:smart_retry_alignment] = diverge  │
                                                                            │
[processor/{fake,stripe,braintree}.ex] ◄── dunning: %{...} rows added     │
                                                                            │
[.planning/processor-support-matrix.md] ◄── dunning rows added             │
                                                                            │
[scripts/ci/verify_processor_support_matrix.sh] ◄── require_substring pins │
      + NEGATIVE convergence guard for dunning.campaign                     │
      + guide-side require_substring pins for guides/dunning.md             │
      [All wired via existing docs-contracts-shift-left CI job]             │
                                                                            │
[Full-journey test (accrue/test/.../dunning_journey_test.exs)]             │
      invoice.payment_failed → DefaultHandler → anchor + day-0 job         │
      Accrue.Test.Clock.advance(days: 5) → Oban.drain_queue(:accrue_dunning)│
      → :reminder → :action_required → ...                                  │
      invoice.paid → DefaultHandler → cancel-on-recovery                    │
      DunningSweeper.sweep() → exhaustion                                   │
      At each stage: assert telemetry + ledger events fired                 │
      Also: assert Capabilities.dunning.* labels == doc literals (D-09)    │
                                                                            │
[examples/accrue_host/config/config.exs] ◄── accrue_dunning: 2 queue       │
      + Oban.Plugins.Cron wired (DunningSweeper [+ DetectExpiringCards])   │
                                                                            │
[Host-level proof test] ──── Fake-backed, clock-advance + drain            │
      failed-payment → campaign-step → recovery loop                        │
      (thin wiring smoke, not duplicate of accrue-layer journey)            │
                                                                            │
[examples/accrue_host/docs/adoption-proof-matrix.md] ◄── dunning row added │
[scripts/ci/verify_adoption_proof_matrix.sh] ◄── dunning needle added      │
                                                                            │
All above co-updated in ONE PR ─────────────────────────────────────────────┘
     gated by existing docs-contracts-shift-left + host-integration jobs
```

### Recommended Project Structure

No new directories are needed. Files to CREATE or EXTEND:

```
accrue/guides/
└── dunning.md                       ← NEW (D-01)

accrue/lib/accrue/processor/
├── capabilities.ex                  ← EXTEND (add dunning: group)
├── fake.ex                          ← EXTEND (add dunning: %{...} to capabilities/0)
├── stripe.ex                        ← EXTEND (add dunning: %{...} to capabilities/0)
└── braintree.ex                     ← EXTEND (add dunning: %{...} to capabilities/0)

.planning/
└── processor-support-matrix.md      ← EXTEND (add dunning rows)

scripts/ci/
└── verify_processor_support_matrix.sh  ← EXTEND (add require_substring + negative guard)

accrue/test/accrue/
└── dunning/                         ← NEW file (full-journey test)
    └── dunning_full_journey_test.exs

examples/accrue_host/config/
└── config.exs                       ← EXTEND (accrue_dunning queue + Cron plugin)

examples/accrue_host/test/accrue_host/
└── dunning_wiring_test.exs          ← NEW (host-level Fake-backed smoke proof)

examples/accrue_host/docs/
└── adoption-proof-matrix.md         ← EXTEND (dunning row)

scripts/ci/
└── verify_adoption_proof_matrix.sh  ← EXTEND (dunning needle)
```

### Pattern 1: Capability Group Addition (Phase 125 Template)

**What:** Add `dunning:` group to `@support_labels` and `@provider_support_labels` in `Accrue.Processor.Capabilities`, then add matching `dunning: %{...}` map inside each adapter's `capabilities/0`. The Phase 125 entitlements group is the exact template.

**Key insight from codebase:** The CONVERGENCE row (`dunning.campaign`) mirrors `entitlements.local_mapping` — all three providers carry the same label because the campaign is Accrue-clock-driven with zero processor calls. The DIVERGENCE row (`dunning.smart_retry_alignment`) mirrors `subscription.swap_plan` — each provider legitimately has a different label.

**Example (based on existing entitlements pattern):**
```elixir
# In capabilities.ex @support_labels:
dunning: %{
  campaign: "all first-party",
  smart_retry_alignment: "provider-divergent (see dunning guide)"
}

# In capabilities.ex @provider_support_labels:
# CONVERGENCE row — campaign cadence is Accrue-clock-driven,
# processor-independent; never carries native/unsupported/bounded.
dunning: %{
  campaign: %{
    fake: "local-identical",
    stripe: "local-identical",
    braintree: "local-identical"
  },
  # DIVERGENCE row — processor-native payment retry behavior differs.
  smart_retry_alignment: %{
    fake: "testing/local-only",
    stripe: "native (Smart Retries)",
    braintree: "unsupported (clock-driven only)"
  }
}

# In fake.ex / stripe.ex / braintree.ex capabilities/0:
dunning: %{campaign: true, smart_retry_alignment: true}
# (or appropriate boolean representing the adapter's support)
```

**Planner note:** The exact label strings for `smart_retry_alignment` are Claude's Discretion (must use established vocabulary — `native`, `unsupported`, `testing/local-only`). D-06 recommends "native (Smart Retries)" for Stripe and "unsupported (clock-driven only)" for Braintree. The planner should pick these and pin them in both the gate and the doc.

### Pattern 2: Bash Gate Extension (Phase 125 Template)

**What:** Extend `scripts/ci/verify_processor_support_matrix.sh` with new `require_substring` calls and a NEGATIVE convergence guard for `dunning.campaign`.

**The existing negative guard pattern** (lines 105-119 in the script):
```bash
if grep -Eq '^\| entitlements\.local_mapping \|.*\b(native|unsupported|bounded)\b' "${matrix}"; then
  echo "..." >&2
  exit 1
fi
```
**Dun equivalent:**
```bash
# NEGATIVE divergence guard: dunning.campaign CONVERGENCE row must NEVER
# carry a per-provider native/unsupported/bounded label — the cadence is
# always Accrue-clock-driven (local-identical). The smart_retry_alignment
# DIVERGENCE row is exempted by name (matching the entitlements pattern).
if grep -Eq '^\| dunning\.campaign \|.*\b(native|unsupported|bounded)\b' "${matrix}"; then
  echo "verify_processor_support_matrix: dunning.campaign convergence row sprouted a per-provider divergence label" >&2
  exit 1
fi
```

**Guide-side pins** (D-08): add `require_substring` calls that target `accrue/guides/dunning.md` directly, or alternatively extend the matrix file to include guide cross-references. The simplest approach is separate `require_substring` calls against the guide path.

**Planner note:** The bash gate searches the `.planning/processor-support-matrix.md` file (variable `$matrix`). The guide-side pins either need a second variable pointing to `accrue/guides/dunning.md`, or the guide must be set as a second searched file. Look at how the script handles the single `$matrix` variable — a simple addition is to set `guide="${repo_root}/accrue/guides/dunning.md"` and add a `require_substring_in_guide()` helper.

### Pattern 3: Full-Journey Test (the load-bearing SC#3 pattern)

**What:** Clock-advanceable, drain-based, real-entry-point journey proof. Extends the `dunning_campaign_start_test.exs` precedent.

**Critical mechanics (verified from codebase):**
- `Oban.drain_queue(queue: :accrue_dunning)` in `:manual` testing mode drains synchronously
- `Accrue.Test.Clock.advance(days: N)` advances the Fake clock without sleeping
- `DefaultHandler.handle(event)` is the real entry point (not calling `maybe_start_dunning_campaign/2` directly)
- `StripeFixtures.webhook_event("invoice.payment_failed", canonical)` builds the fixture
- `StripeFixtures.webhook_event("invoice.paid", canonical)` for the recovery event
- `DunningSweeper.sweep()` for the exhaustion path (or drain a scheduled cron job)
- `Accrue.BillingCase` is the right base case (Fake-backed DB)
- `use Oban.Testing, repo: Accrue.TestRepo` enables `all_enqueued/1` and `drain_queue/1`

**The four-stage proof structure:**
```elixir
# Stage 1: Start
fire_payment_failed(invoice_id, sub_id)
assert anchor set + one DunningStep(:reminder) enqueued

# Stage 2: Step progression (clock-advance per step's after_days)
Accrue.Test.Clock.advance(days: 5)  # advance past :action_required boundary
Oban.drain_queue(queue: :accrue_dunning)
assert :action_required step delivered + ledger event + telemetry

Accrue.Test.Clock.advance(days: 7)  # advance past :final_notice boundary (day 12 total)
Oban.drain_queue(queue: :accrue_dunning)
assert :final_notice step delivered + ledger event + telemetry

# Stage 3: Cancel-on-recovery (alternative path — sibling scenario)
fire_payment_succeeded(invoice_id, sub_id)  # or subscription.updated → :active
assert anchor nilled + DunningStep jobs cancelled + dunning.recovered event

# Stage 4: Exhaustion (in a separate test/scenario)
# After :final_notice, no more steps enqueued.
# DunningSweeper.sweep() transitions to terminal.
# DefaultHandler handles customer.subscription.updated → :unpaid
# assert dunning.exhausted ledger event + telemetry
```

**Observability assertions (D-12):** At each stage, assert the expected `accrue_events` record type AND the `[:accrue, :ops, :dunning_*]` telemetry event fired. Use `:telemetry.attach/4` as in `dunning_campaign_start_test.exs:104-116`.

**Capabilities label mirror (D-09):**
```elixir
test "dunning.campaign is local-identical across all three providers (code-side label mirror)" do
  assert Capabilities.provider_support_label(:fake, [:dunning, :campaign]) == "local-identical"
  assert Capabilities.provider_support_label(:stripe, [:dunning, :campaign]) == "local-identical"
  assert Capabilities.provider_support_label(:braintree, [:dunning, :campaign]) == "local-identical"

  assert Capabilities.provider_support_label(:stripe, [:dunning, :smart_retry_alignment]) ==
    "native (Smart Retries)"
  assert Capabilities.provider_support_label(:braintree, [:dunning, :smart_retry_alignment]) ==
    "unsupported (clock-driven only)"
  assert Capabilities.provider_support_label(:fake, [:dunning, :smart_retry_alignment]) ==
    "testing/local-only"
end
```

### Pattern 4: Host Oban Wiring (D-13/D-14)

**The gap today** (verified from `examples/accrue_host/config/config.exs:37-44`):
```elixir
# CURRENT (missing accrue_dunning queue and Cron plugin)
config :accrue_host, Oban,
  repo: AccrueHost.Repo,
  queues: [
    accrue_webhooks: 10,
    accrue_mailers: 20,
    accrue_pdf: 5
  ],
  plugins: [{Oban.Plugins.Pruner, max_age: 60 * 60 * 24}]
```

**The fix:**
```elixir
config :accrue_host, Oban,
  repo: AccrueHost.Repo,
  queues: [
    accrue_webhooks: 10,
    accrue_mailers: 20,
    accrue_pdf: 5,
    accrue_dunning: 2                                          # ← ADD
  ],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24},
    {Oban.Plugins.Cron,                                       # ← ADD
      crontab: [
        {"*/15 * * * *", Accrue.Jobs.DunningSweeper},         # sweep every 15min
        # {"0 7 * * *", Accrue.Jobs.DetectExpiringCards}      # (planner discretion: include or omit)
      ]}
  ]
```

**Note on `DetectExpiringCards`:** This job uses `queue: :accrue_scheduled` (verified from `detect_expiring_cards.ex:25`) — NOT `accrue_dunning`. If the planner includes it, a separate `accrue_scheduled: 5` queue entry is required. The D-14 CONTEXT notes it is the most safely droppable discretion item.

### Anti-Patterns to Avoid

- **Driving the journey test through `maybe_start_dunning_campaign/2` directly** — this was the exact failure mode caught in Phase 126/127 code reviews. ALWAYS drive through `DefaultHandler.handle(event)`.
- **Using `Process.sleep/1` in the journey test** — NEVER acceptable; use `Accrue.Test.Clock.advance/2` + `Oban.drain_queue/2`.
- **Inventing new label vocabulary** — reuse exactly: `"local-identical"`, `"native"`, `"native (Smart Retries)"`, `"unsupported"`, `"testing/local-only"`, `"out of slice"`, `"all first-party"`.
- **Creating a dedicated `verify_dunning_docs.sh`** — rejected in D-05; extend the existing processor support matrix script.
- **Re-deriving lifecycle truth in `guides/dunning.md`** — cross-reference `lifecycle_semantics.md:150-211` instead (the `### past_due` section is the lifecycle SSOT).
- **Running `Oban.drain_queue` INSIDE a `Repo.transact` call** — Oban dispatches against `conf.repo` and is not guaranteed to enlist in a surrounding transaction. Always drain AFTER commits.
- **Putting `accrue_dunning` queue config in core `accrue` lib** — Accrue never starts its own Oban; the queue config belongs exclusively in the host app.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Deterministic time advance in tests | Custom `Process.sleep` loops | `Accrue.Test.Clock.advance/2` | Already ships; delegates to `Accrue.Processor.Fake`; `Accrue.Clock.utc_now/0` reads it in `:test` env |
| Draining Oban queues in tests | Custom polling | `Oban.drain_queue(queue: :accrue_dunning)` | Built-in Oban `:manual` testing mode; already configured in `test_helper.exs:51` |
| Detecting per-provider label drift | Custom hash | `verify_processor_support_matrix.sh` extension with `require_substring` | Existing merge-blocking bash gate; same mechanism as entitlements (Phase 125) |
| Asserting telemetry in tests | Custom event capture | `:telemetry.attach/4` pattern already in `dunning_campaign_start_test.exs:104-116` | Established pattern; no new infrastructure |
| ExDoc guide registration | `mix.exs` extras array edit | `Path.wildcard("guides/*.md")` in `accrue/mix.exs:134-135` | New guide is auto-discovered; no edit needed |

---

## Common Pitfalls

### Pitfall 1: Testing via the internal helper, not the real entry point
**What goes wrong:** A test calls `maybe_start_dunning_campaign/2` (or `DunningStep.enqueue_step/4`) directly. The suite passes green, but the actual `invoice.payment_failed` → `DefaultHandler` path is dead (wrong webhook event shape, missing canonical extraction, wrong condition guard).
**Why it happens:** Internal helpers are easier to call directly. The Phase 126/127 code review explicitly caught this.
**How to avoid:** ALWAYS fire `DefaultHandler.handle(StripeFixtures.webhook_event("invoice.payment_failed", canonical))`. The `dunning_campaign_start_test.exs` sets the pattern — extend it.
**Warning signs:** Test does not need a `stub_invoice_fetch` helper; test does not need to construct a canonical invoice map.

### Pitfall 2: Forgetting the `dunning_campaign_enabled?()` guard
**What goes wrong:** Journey test fails because `maybe_start_dunning_campaign/2` short-circuits on `dunning_campaign_enabled?() == false` — no campaign starts.
**Why it happens:** The test `setup` may inherit an `Application.get_env(:accrue, :dunning)` that has `campaign: [enabled: false]` from a prior test's `on_exit` cleanup race.
**How to avoid:** Explicitly set a known-good campaign config in `setup` (as `dunning_campaign_start_test.exs` does), and use `on_exit` to restore it. Pattern: `prev = Application.get_env(...); on_exit(fn -> restore(prev) end)`.
**Warning signs:** `dunning_campaign_started_at` stays `nil` after `fire_payment_failed`; `all_enqueued(worker: DunningStep)` returns `[]`.

### Pitfall 3: Clock advance amounts don't match the configured step boundaries
**What goes wrong:** `Accrue.Test.Clock.advance(days: 5)` and then `drain_queue` produces no additional steps because the default journey is `[0, 5, 12]` — day 5 is the boundary for `:action_required`, meaning elapsed must be >= 5 days' seconds. The resolver uses `>=` semantics.
**Why it happens:** Confusion about absolute vs. relative offsets. The `after_days` values in the campaign config are ABSOLUTE from the campaign anchor, not relative to the previous step.
**How to avoid:** To advance to step 2 (day 5), advance the clock so total elapsed from anchor >= 5 days. To advance to step 3 (day 12), advance total elapsed from anchor >= 12 days. If you advance 5 days from the campaign start for step 2, then advance another 7 days for step 3.
**Warning signs:** `drain_queue` returns without any new enqueued jobs; the resolver reports `:done` prematurely.

### Pitfall 4: `Oban.drain_queue` drains all currently-enqueued jobs including scheduled-in-future ones
**What goes wrong:** `drain_queue/1` in Oban `:manual` mode drains all available jobs including those scheduled with `schedule_in`. Without advancing the clock first, a chained step that's scheduled 5 days from now won't be available. Or: draining too early fires a step whose clock guard (`campaign_active?`) returns false because the sub recovered between enqueue and drain.
**Why it happens:** The interaction between Oban's scheduling and the Fake clock requires care: `schedule_in: N` means the job is scheduled at `now + N seconds` in the real Oban clock. In test mode, `drain_queue` can execute scheduled jobs as if they're due. Verify with actual test runs.
**How to avoid:** Follow the Phase 128 test patterns: advance clock, then drain. If a step's delivery requires `campaign_active?` to be true, ensure the sub still has `dunning_campaign_started_at` set at drain time.
**Warning signs:** Steps fire out of order; exhaustion fires before the correct step.

### Pitfall 5: The guide creates a split-brain SSOT by re-deriving lifecycle truth
**What goes wrong:** `guides/dunning.md` restates the `past_due`/`unpaid` lifecycle semantics from scratch. Later, `lifecycle_semantics.md` is updated but `dunning.md` is not — two inconsistent docs.
**Why it happens:** Natural inclination to make each guide self-contained.
**How to avoid:** Cross-reference `lifecycle_semantics.md` for lifecycle truth (D-01). The dunning guide's lifecycle section should be: "For `past_due`/`unpaid` semantics, grace-period behavior, and the `past_due_grace` entitlements knob, see [lifecycle_semantics.md](./lifecycle_semantics.md#past_due)."

### Pitfall 6: `DetectExpiringCards` uses queue `:accrue_scheduled`, not `:accrue_dunning`
**What goes wrong:** If planner decides to wire `DetectExpiringCards` into the host (D-14), they add it to the Cron but forget that `DetectExpiringCards` uses `queue: :accrue_scheduled` — not `:accrue_dunning`. The job will silently fail to run because the `:accrue_scheduled` queue is not defined in the host config.
**Why it happens:** CONTEXT.md groups `DetectExpiringCards` with `DunningSweeper` as "sibling cron jobs," but they use different queues.
**How to avoid:** If wiring `DetectExpiringCards`, add both `accrue_dunning: 2` AND `accrue_scheduled: 5` to the host queues config.
**Verified from:** `accrue/lib/accrue/jobs/detect_expiring_cards.ex:25` — `use Oban.Worker, queue: :accrue_scheduled`.

### Pitfall 7: Forgetting that the bash gate operates on the `.planning/` matrix file path, not the guides path
**What goes wrong:** New `require_substring` calls for the public guide are added with the wrong file path (pointing to `$matrix` instead of `$guide`).
**Why it happens:** The existing `verify_processor_support_matrix.sh` uses a single `$matrix` variable pointing to `.planning/processor-support-matrix.md`. The guide-side pins (D-08) need a separate file reference.
**How to avoid:** Add a `guide="${repo_root}/accrue/guides/dunning.md"` variable and a `require_substring_in_guide()` helper function (or just inline the `grep -Fq` against the guide path). Ensure the script gracefully handles a missing guide file (exit with a clear message, not a silent pass).

---

## Code Examples

### Existing capabilities.ex entitlements group (template to mirror for dunning)
```elixir
# Source: accrue/lib/accrue/processor/capabilities.ex:60-126
# @support_labels convergence row:
entitlements: %{
  local_mapping: "all first-party",
  stripe_native_sync: "Stripe-native advisory (observational)"
}

# @provider_support_labels convergence + divergence:
entitlements: %{
  local_mapping: %{
    fake: "local-identical",
    stripe: "local-identical",
    braintree: "local-identical"
  },
  stripe_native_sync: %{
    fake: "out of slice",
    stripe: "native (advisory)",
    braintree: "unsupported"
  }
}
```

### Existing bash negative guard pattern (template for dunning.campaign)
```bash
# Source: scripts/ci/verify_processor_support_matrix.sh:105-119
if grep -Eq '^\| entitlements\.local_mapping \|.*\b(native|unsupported|bounded)\b' "${matrix}"; then
  echo "..." >&2
  exit 1
fi
```

### Existing real-entry-point test pattern (template for full journey)
```elixir
# Source: accrue/test/accrue/webhook/dunning_campaign_start_test.exs:95-102
defp fire_payment_failed(invoice_id, sub_id) do
  next_attempt_unix =
    DateTime.utc_now() |> DateTime.add(2 * 86_400, :second) |> DateTime.to_unix()

  canonical = stub_invoice_fetch(invoice_id, sub_id, next_attempt_unix)
  event = StripeFixtures.webhook_event("invoice.payment_failed", canonical)
  DefaultHandler.handle(event)
end
```

### Telemetry capture pattern (template for D-12 observability assertions)
```elixir
# Source: accrue/test/accrue/webhook/dunning_campaign_start_test.exs:104-116
defp attach_telemetry(name, event) do
  test_pid = self()
  :ok = :telemetry.attach(
    name,
    event,
    fn evt, meas, meta, _ -> send(test_pid, {:telemetry, evt, meas, meta}) end,
    nil
  )
  ExUnit.Callbacks.on_exit(fn -> :telemetry.detach(name) end)
end
```

### Oban drain in manual testing mode
```elixir
# Oban is configured in test_helper.exs:51 as testing: :manual
# To drain synchronously:
Oban.drain_queue(queue: :accrue_dunning)
# Returns {:ok, %{success: N, failure: 0, ...}}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Test dunning by calling internal helpers directly | Test through `DefaultHandler.handle(event)` | Phase 128/126 code review | Makes the merge gate actually prove the production path |
| All-or-nothing Oban queue config in host | Additive queue config; Accrue never starts Oban | Phase 128 design | Host controls Oban; `accrue_dunning` queue config is a simple additive change |
| Per-provider capability claims undocumented | Capability rows in `Capabilities` module + matrix doc + bash gate | Phase 125 (entitlements template) | Provider-honest and drift-gated; same pattern for dunning |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Oban.drain_queue(queue: :accrue_dunning)` in `:manual` testing mode drains scheduled-future jobs as well as immediately-available ones, when clock is advanced | Common Pitfalls #4 | If drain only processes immediately-available jobs, the journey test needs a different advance-then-drain sequencing; verify against actual Oban 2.22.1 test mode docs |
| A2 | The `dunning_campaign_start_test.exs` setup pattern (restore `Application.get_env(:accrue, :dunning)` in `on_exit`) is sufficient isolation for `async: false` tests | Code Examples | If other tests in the suite also mutate `:dunning` app env concurrently, tests may interfere; the `async: false` constraint should prevent this |
| A3 | `DunningSweeper` can be called directly as `DunningSweeper.sweep()` in the exhaustion stage of the journey test (rather than requiring an Oban job enqueue + drain) | Architecture Patterns / Pattern 3 | If the test environment requires the Oban job wrapper, a `Oban.drain_queue` call against a cron-triggered job may be needed instead |

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Oban (community) | Journey test drain, host cron | Yes | 2.22.1 (confirmed Phase 128 note) | — |
| `Accrue.Test.Clock.advance/2` | Clock-advance in tests | Yes (shipped in `accrue/lib/accrue/test/clock.ex`) | — | — |
| `Accrue.BillingCase` | Journey test base case | Yes (existing dunning tests use it) | — | — |
| `Oban.Testing` | `drain_queue/1`, `all_enqueued/1` | Yes (test_helper.exs configures Oban testing: :manual) | — | — |
| Chrome/Chromium | PDF rendering | Not required by this phase | — | Not applicable |

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (stdlib) |
| Config file | `accrue/test/test_helper.exs` |
| Quick run command | `mix test test/accrue/dunning/dunning_full_journey_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DUN-09 (SC#1) | Dunning guide exists with per-provider honest prose | Static bash gate (grep) | `bash scripts/ci/verify_processor_support_matrix.sh` | ❌ Wave 0: create `guides/dunning.md` |
| DUN-09 (SC#2) | `dunning.*` capability rows in code + matrix doc stay aligned | Bash shift-left gate | `bash scripts/ci/verify_processor_support_matrix.sh` | ❌ Wave 0: extend script + matrix |
| DUN-09 (SC#2 code-side) | `Capabilities.dunning.*` labels match doc literals | Unit (in journey test) | `mix test test/accrue/dunning/dunning_full_journey_test.exs` | ❌ Wave 0: create journey test |
| DUN-10 (SC#3) | Full journey: start → step progression → cancel-on-recovery → exhaustion | Integration (real entry point) | `mix test test/accrue/dunning/dunning_full_journey_test.exs` | ❌ Wave 0: create journey test |
| DUN-10 (SC#3 observability) | Telemetry + ledger events fire on real path at each stage | Integration (in journey test) | `mix test test/accrue/dunning/dunning_full_journey_test.exs` | ❌ Wave 0: create journey test |
| DUN-10 (SC#4 wiring) | `accrue_dunning` queue + Cron present in host config | Static bash gate | `bash scripts/ci/verify_adoption_proof_matrix.sh` | ❌ Wave 0: extend host config + matrix |
| DUN-10 (SC#4 proof) | Host-level Fake-backed failed-payment → recovery loop | Integration (host test) | `mix test test/accrue_host/dunning_wiring_test.exs` (from examples/accrue_host/) | ❌ Wave 0: create host test |

### Sampling Rate
- **Per task commit:** `mix test test/accrue/dunning/ --seed 0` (in `accrue/`)
- **Per wave merge:** `mix test --seed 0` (full suite; `bash scripts/ci/verify_processor_support_matrix.sh`)
- **Phase gate:** Full suite green + both bash gates green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `accrue/guides/dunning.md` — covers DUN-09 SC#1
- [ ] `accrue/test/accrue/dunning/dunning_full_journey_test.exs` — covers DUN-10 SC#3 + D-09 label mirror
- [ ] `examples/accrue_host/test/accrue_host/dunning_wiring_test.exs` — covers DUN-10 SC#4 proof
- [ ] Extensions to `accrue/lib/accrue/processor/capabilities.ex` — `dunning:` group
- [ ] Extensions to `accrue/lib/accrue/processor/{fake,stripe,braintree}.ex` — `dunning:` rows
- [ ] Extensions to `.planning/processor-support-matrix.md` — dunning rows
- [ ] Extensions to `scripts/ci/verify_processor_support_matrix.sh` — dunning pins + guard
- [ ] Extension to `examples/accrue_host/config/config.exs` — queue + cron
- [ ] Extension to `examples/accrue_host/docs/adoption-proof-matrix.md` — dunning row
- [ ] Extension to `scripts/ci/verify_adoption_proof_matrix.sh` — dunning needle

---

## Security Domain

This phase introduces no new security surface. The phase adds documentation, code labels (pure data, no execution), test code, and host Oban config entries. No new request handling, no new secrets, no new PII paths.

The over-email warning (D-04) is the security-adjacent concern: it documents that Stripe Dashboard dunning emails + Accrue cadence can double-email customers. The mitigation is configuration (disable one side), not a code change in this phase.

ASVS categories: Not applicable to this phase's deliverables.

---

## Sources

### Primary (HIGH confidence — verified from codebase in this session)
- `accrue/lib/accrue/processor/capabilities.ex` — exact `@support_labels` / `@provider_support_labels` structure, entitlements convergence/divergence pattern
- `accrue/lib/accrue/processor/{fake,stripe,braintree}.ex` — exact `capabilities/0` map shape in each adapter
- `scripts/ci/verify_processor_support_matrix.sh` — exact `require_substring` helper, negative guard pattern (lines 105-119)
- `.planning/processor-support-matrix.md` — current matrix rows, absence of any `dunning.*` rows confirmed
- `accrue/test/accrue/webhook/dunning_campaign_start_test.exs` — real-entry-point pattern, telemetry attach, `fire_payment_failed` helper, `Oban.Testing` usage
- `accrue/test/test_helper.exs` — `testing: :manual`, `ExUnit.configure(exclude: [:live_stripe, :slow, :compile_matrix])`
- `accrue/lib/accrue/workers/dunning_step.ex` — queue `:accrue_dunning`, `max_attempts: 3`, `unique` opts, `campaign_active?/1` guard
- `accrue/lib/accrue/jobs/dunning_sweeper.ex` — `sweep/0` entry point, queue `:accrue_dunning`, how to invoke directly in tests
- `accrue/lib/accrue/jobs/detect_expiring_cards.ex` — queue `:accrue_scheduled` (NOT `:accrue_dunning`) — critical Pitfall 6
- `accrue/lib/accrue/clock.ex` — `utc_now/0` reads `:test` env → `Fake.now/0`
- `accrue/lib/accrue/test/clock.ex` — `advance/2` interface
- `accrue/lib/accrue/dunning/campaign.ex` — `next_step/3` pure resolver, `>=` boundary semantics
- `examples/accrue_host/config/config.exs` — exact current Oban config (missing `accrue_dunning` queue and Cron plugin confirmed at lines 37-44)
- `examples/accrue_host/lib/accrue_host/application.ex` — `{Oban, Application.fetch_env!(:accrue_host, Oban)}` supervision wiring
- `examples/accrue_host/docs/adoption-proof-matrix.md` — current structure, Fake-backed blocking lane format
- `scripts/ci/verify_adoption_proof_matrix.sh` — existing needle pattern, `require_substring` helper

### Secondary (MEDIUM confidence — from CONTEXT.md canonical refs)
- `.planning/phases/128-campaign-engine-foundation-idempotency-must-fix/128-CONTEXT.md` — campaign engine contracts, default journey `[0, 5, 12]`, D-03 over-email posture
- `.planning/phases/129-customer-operator-surfaces-observability/129-CONTEXT.md` — observable contract: `[:accrue, :ops, :dunning_*]` telemetry + `dunning.*` ledger events
- `.planning/phases/125-provider-honesty-lifecycle-truth/125-CONTEXT.md` — Phase 125 drift-gate template (confirmed as exact analog)

### Tertiary (advisory — not verified in this session)
- Stripe Smart Retries: https://docs.stripe.com/billing/revenue-recovery/smart-retries — Oban 2.22.1 installed version confirmed from Phase 128 note; `drain_queue` `:manual` mode behavior per Oban docs

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries already installed and verified in codebase
- Architecture: HIGH — exact file locations, function signatures, and patterns verified from source
- Pitfalls: HIGH — most pitfalls directly derived from existing code review notes in CONTEXT.md and source code comments
- Oban drain behavior (Pitfall 4 / A1): MEDIUM — `[ASSUMED]` based on Oban `:manual` testing mode conventions; confirm in Wave 0

**Research date:** 2026-05-25
**Valid until:** 2026-06-25 (stable Elixir/Oban ecosystem; codebase itself changes only with new phases)
