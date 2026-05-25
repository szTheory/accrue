# Phase 130: Provider Honesty + Fake-Lane Proof + Example-Host Wiring — Pattern Map

**Mapped:** 2026-05-25
**Files analyzed:** 10 (3 new, 7 extended)
**Analogs found:** 10 / 10

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue/guides/dunning.md` | doc | — | `accrue/guides/entitlements.md` | exact (same pattern: own guide, cross-refs lifecycle SSOT) |
| `accrue/lib/accrue/processor/capabilities.ex` | config/utility | — | itself (`entitlements:` group, lines 60–126) | exact |
| `accrue/lib/accrue/processor/fake.ex` | adapter | — | itself (`capabilities/0`, lines 219–241) | exact |
| `accrue/lib/accrue/processor/stripe.ex` | adapter | — | itself (`capabilities/0`, lines 78–100) | exact |
| `accrue/lib/accrue/processor/braintree.ex` | adapter | — | itself (`capabilities/0`, lines 17–44) | exact |
| `.planning/processor-support-matrix.md` | doc/config | — | itself (entitlements rows, lines 59–60) | exact |
| `scripts/ci/verify_processor_support_matrix.sh` | ci/utility | — | itself (negative guard, lines 105–119) | exact |
| `accrue/test/accrue/dunning/dunning_full_journey_test.exs` | test | event-driven | `accrue/test/accrue/webhook/dunning_campaign_start_test.exs` | exact |
| `examples/accrue_host/config/config.exs` | config | — | itself (Oban block, lines 37–44) | exact |
| `examples/accrue_host/test/accrue_host/dunning_wiring_test.exs` | test | event-driven | `accrue/test/accrue/jobs/dunning_sweeper_test.exs` | role-match |
| `examples/accrue_host/docs/adoption-proof-matrix.md` | doc | — | itself (Blocking table, lines 14–26) | exact |
| `scripts/ci/verify_adoption_proof_matrix.sh` | ci/utility | — | itself (`require_substring` block) | exact |

---

## Pattern Assignments

### `accrue/guides/dunning.md` (new doc)

**Analog:** `accrue/guides/entitlements.md`

**Opening cross-reference pattern** (entitlements.md lines 1–7):
```markdown
For the canonical meaning of `active`, `trialing`, `paused`, `past_due`, and
ended states — and for *which* lifecycle states grant access — see
[Lifecycle Semantics](lifecycle_semantics.md). Use that guide for the truth of
"who is entitled"; use **this** guide for how to *ask* the question and how to
*enforce* the answer in a controller, a LiveView, and your config.
```
Apply to dunning.md: open with a cross-reference to `lifecycle_semantics.md` for `past_due`/`unpaid`/grace truth (section ~lines 150–211). Do NOT re-derive lifecycle truth inside the dunning guide.

**Convergence-before-divergence prose pattern** (based on processor-support-matrix.md lines 64–68, the Entitlements section):
```
The campaign cadence behaves identically across Stripe, Braintree, and Fake
because `Accrue.Dunning` drives steps off local `dunning_campaign_started_at`
/ `past_due_since` and `Accrue.Clock`, making zero processor calls.
```
Name this the CONVERGENCE claim first. Then present DIVERGENCE (smart retry alignment) as the honest contrast.

**Guide section ordering (planner discretion — recommended):**
1. Cross-reference to `lifecycle_semantics.md` (SSOT for lifecycle)
2. Overview: what dunning does (campaign = provider-independent email cadence)
3. Per-provider breakdown (Stripe, Braintree, Fake)
4. Configuration reference (`Accrue.Config.dunning_campaign_steps/0` shape, campaign DSL)
5. The four ledger events + telemetry family (link to `guides/telemetry.md`)
6. Over-email warning (D-04)
7. Lifecycle/capability truth note (`past_due_grace` interaction)

**Over-email warning pattern** (write as a blockquote `> **Warning:**` per Phoenix docs convention):
```markdown
> **Warning:** If your Stripe Dashboard has dunning emails enabled and Accrue's
> campaign is also enabled, customers may receive duplicate emails. Disable one
> side: either set `dunning: [campaign: [enabled: false]]` in your Accrue config,
> or turn off Stripe Dashboard dunning emails.
```

---

### `accrue/lib/accrue/processor/capabilities.ex` (extend — add `dunning:` group)

**Analog:** itself — `entitlements:` group (lines 60–126)

**`@support_labels` addition pattern** (lines 60–64):
```elixir
entitlements: %{
  local_mapping: "all first-party",
  stripe_native_sync: "Stripe-native advisory (observational)"
}
```
Mirror for dunning — add after the `entitlements:` block:
```elixir
dunning: %{
  campaign: "all first-party",
  smart_retry_alignment: "provider-divergent (see dunning guide)"
}
```

**`@provider_support_labels` convergence + divergence addition pattern** (lines 103–126):
```elixir
# CONVERGENCE row — unlike every divergence lane above, entitlement
# resolution is provider-INDEPENDENT local derivation (D-03), so all three
# providers carry the same "local-identical" lane. Never a native/
# unsupported/bounded label here (the drift gate enforces this).
entitlements: %{
  local_mapping: %{
    fake: "local-identical",
    stripe: "local-identical",
    braintree: "local-identical"
  },
  # DIVERGENCE row (D-10) — ...
  stripe_native_sync: %{
    fake: "out of slice",
    stripe: "native (advisory)",
    braintree: "unsupported"
  }
}
```
Mirror for dunning — add a sibling `dunning:` key with the SAME comment structure:
```elixir
# CONVERGENCE row — the Accrue dunning campaign cadence is provider-INDEPENDENT
# local derivation driven off `dunning_campaign_started_at` / `past_due_since`
# and `Accrue.Clock`, making zero processor calls. All three providers carry
# "local-identical". Never a native/unsupported/bounded label here (the drift
# gate enforces this).
dunning: %{
  campaign: %{
    fake: "local-identical",
    stripe: "local-identical",
    braintree: "local-identical"
  },
  # DIVERGENCE row — processor-native payment retry behavior differs across
  # providers. Stripe has adaptive Smart Retries running beneath Accrue's cadence;
  # Braintree is clock-driven only (no smart-retry overlay); Fake is the
  # deterministic proof lane.
  smart_retry_alignment: %{
    fake: "testing/local-only",
    stripe: "native (Smart Retries)",
    braintree: "unsupported (clock-driven only)"
  }
}
```

**`provider_support_label/2` function** (lines 160–170): no change — the function uses `get_in(@provider_support_labels, path ++ [provider])` which is path-generic; the new `dunning.*` paths work automatically.

---

### `accrue/lib/accrue/processor/fake.ex` (extend `capabilities/0`)

**Analog:** itself — `capabilities/0` (lines 219–241)

**Current shape** (lines 219–241):
```elixir
@impl Accrue.Processor
def capabilities do
  %{
    customer: %{create: true, retrieve: true, update: true},
    payment_method: %{vault_acquisition: true, list: true},
    checkout: %{create: true, fetch: true, hosted: true, embedded: true},
    subscription: %{
      direct_create: true,
      fetch: true,
      cancel: true,
      lifecycle_webhook_projection: true,
      update: true,
      cancel_at_period_end: true,
      cancel_immediately: true,
      pause: true,
      resume: true
    },
    billing_portal: %{create: true},
    invoice: %{lifecycle_webhook_projection: true},
    webhook: %{verify: true, parse: true},
    entitlements: %{local_mapping: true}
  }
end
```
Add `dunning: %{campaign: true, smart_retry_alignment: true}` at the end of the map, sibling to `entitlements:`.

---

### `accrue/lib/accrue/processor/stripe.ex` (extend `capabilities/0`)

**Analog:** itself — `capabilities/0` (lines 78–100)

**Same map shape as Fake** (lines 78–100). Add:
```elixir
dunning: %{campaign: true, smart_retry_alignment: true}
```
Same position: after `entitlements: %{local_mapping: true}`.

---

### `accrue/lib/accrue/processor/braintree.ex` (extend `capabilities/0`)

**Analog:** itself — `capabilities/0` (lines 17–44)

**Current shape** (lines 17–44): same structure. Add:
```elixir
dunning: %{campaign: true, smart_retry_alignment: false}
```
Note: Braintree has `smart_retry_alignment: false` because the label `"unsupported (clock-driven only)"` reflects genuine absence of processor-native smart retries. The `campaign: true` reflects that the Accrue campaign cadence works identically on Braintree.

---

### `.planning/processor-support-matrix.md` (extend — add dunning rows)

**Analog:** existing entitlements rows (lines 59–60):
```markdown
| entitlements.local_mapping | local-identical | local-identical | local-identical | all first-party |
| entitlements.stripe_native_sync | out of slice | native (advisory) | unsupported | Stripe-native advisory (observational) |
```

**Add dunning rows immediately after** the entitlements rows:
```markdown
| dunning.campaign | local-identical | local-identical | local-identical | all first-party |
| dunning.smart_retry_alignment | testing/local-only | native (Smart Retries) | unsupported (clock-driven only) | provider-divergent (see dunning guide) |
```

**Add a prose section** (mirror the Entitlements prose at lines 64–68):
```markdown
## Dunning

The `dunning.campaign` row is the matrix's second **convergence** row. Accrue's
multi-step email cadence is driven off local `dunning_campaign_started_at` /
`past_due_since` and `Accrue.Clock`, making **zero processor calls** — the
campaign cadence behaves identically across Stripe, Braintree, and Fake. That is
why every provider lane reads `local-identical` rather than the
`native`/`bounded first-party`/`unsupported` divergence labels used by the
gateway rows above.

The `dunning.smart_retry_alignment` row is a **divergence** row: Stripe has
adaptive Smart Retries (1–4 week payment retry schedule) running beneath
Accrue's email cadence; Braintree is not retry-aligned — the Accrue email
cadence is the only cadence (clock-driven only, no smart-retry overlay); and
Fake is the deterministic proof lane. The divergence in payment retry behavior
is honest and important, but it does not change the campaign cadence itself.
```

---

### `scripts/ci/verify_processor_support_matrix.sh` (extend)

**Analog:** itself — `require_substring` helper + negative guard pattern (lines 13–119)

**`require_substring` helper** (lines 13–20 — no change, reuse as-is):
```bash
require_substring() {
  local needle="$1"
  local label="$2"
  if ! grep -Fq "${needle}" "${matrix}"; then
    echo "verify_processor_support_matrix: matrix missing ${label} (expected substring: ${needle})" >&2
    exit 1
  fi
}
```

**New `require_substring` calls to add** (after line 64, before the stale-row guards):
```bash
require_substring "| dunning.campaign | local-identical | local-identical | local-identical | all first-party |" "dunning campaign convergence row"
require_substring "| dunning.smart_retry_alignment | testing/local-only | native (Smart Retries) | unsupported (clock-driven only) |" "dunning smart-retry-alignment divergence row"
require_substring "the campaign cadence behaves identically across Stripe, Braintree, and Fake" "dunning campaign-cadence convergence prose"
require_substring "Braintree is not retry-aligned" "dunning Braintree not-retry-aligned honest prose"
require_substring "Stripe has adaptive Smart Retries" "dunning Stripe smart-retries honest prose"
```

**Guide-side pins** (D-08) — add a `guide` variable and inline greps against the public guide:
```bash
guide="${repo_root}/accrue/guides/dunning.md"

if [[ ! -f "${guide}" ]]; then
  echo "verify_processor_support_matrix: missing ${guide}" >&2
  exit 1
fi

require_substring_in_guide() {
  local needle="$1"
  local label="$2"
  if ! grep -Fq "${needle}" "${guide}"; then
    echo "verify_processor_support_matrix: dunning guide missing ${label} (expected substring: ${needle})" >&2
    exit 1
  fi
}

require_substring_in_guide "local-identical" "dunning guide: local-identical label"
require_substring_in_guide "native (Smart Retries)" "dunning guide: Stripe smart-retries label"
require_substring_in_guide "unsupported (clock-driven only)" "dunning guide: Braintree not-retry-aligned label"
require_substring_in_guide "zero processor calls" "dunning guide: zero-processor-calls convergence claim"
```

**NEGATIVE convergence guard for `dunning.campaign`** (mirror of lines 105–119):
```bash
# NEGATIVE divergence guard: the dunning.campaign CONVERGENCE row must NEVER
# carry a per-provider native/unsupported/bounded label — the campaign cadence
# is always Accrue-clock-driven (local-identical). The smart_retry_alignment
# DIVERGENCE row is exempted by name (same pattern as entitlements.local_mapping
# vs entitlements.stripe_native_sync). The guard scans the WHOLE row so a
# divergence token in the Fake, Stripe, OR Braintree column is caught.
if grep -Eq '^\| dunning\.campaign \|.*\b(native|unsupported|bounded)\b' "${matrix}"; then
  echo "verify_processor_support_matrix: dunning.campaign convergence row sprouted a per-provider divergence label (broke the local-identical contract)" >&2
  exit 1
fi
```

---

### `accrue/test/accrue/dunning/dunning_full_journey_test.exs` (new test)

**Analog:** `accrue/test/accrue/webhook/dunning_campaign_start_test.exs` (entire file)

**Module header pattern** (lines 1–31):
```elixir
defmodule Accrue.Webhook.DunningCampaignStartTest do
  @moduledoc """
  Phase 128 Plan 06 — campaign start on the REAL webhook path
  ...
  """
  use Accrue.BillingCase, async: false
  use Oban.Testing, repo: Accrue.TestRepo

  import Ecto.Query, only: [from: 2]

  alias Accrue.Billing.Subscription
  alias Accrue.Events.Event, as: LedgerEvent
  alias Accrue.Webhook.DefaultHandler
  alias Accrue.Workers.DunningStep
```
Copy this header verbatim; also alias `Accrue.Processor.Capabilities`, `Accrue.Test.Clock`, `Accrue.Jobs.DunningSweeper`.

**`setup` + dunning-config guard pattern** (lines 39–71): copy the entire `setup` block. The `prev_dunning` save + `on_exit` restore is mandatory to avoid test pollution (Pitfall 2 in RESEARCH.md):
```elixir
setup do
  prev_dunning = Application.get_env(:accrue, :dunning, :__unset__)

  on_exit(fn ->
    case prev_dunning do
      :__unset__ -> Application.delete_env(:accrue, :dunning)
      value -> Application.put_env(:accrue, :dunning, value)
    end
  end)

  # ... customer + sub seed
end
```

**`stub_invoice_fetch/3` helper** (lines 75–93): copy verbatim — returns the canonical invoice map and installs a Fake stub for `:retrieve_invoice`.

**`fire_payment_failed/2` helper** (lines 95–102):
```elixir
defp fire_payment_failed(invoice_id, sub_id) do
  next_attempt_unix =
    DateTime.utc_now() |> DateTime.add(2 * 86_400, :second) |> DateTime.to_unix()

  canonical = stub_invoice_fetch(invoice_id, sub_id, next_attempt_unix)
  event = StripeFixtures.webhook_event("invoice.payment_failed", canonical)
  DefaultHandler.handle(event)
end
```
Add a sibling `fire_payment_succeeded/2` helper that fires `"invoice.paid"` through `DefaultHandler.handle/1` for the cancel-on-recovery stage.

**`attach_telemetry/2` helper** (lines 104–116):
```elixir
defp attach_telemetry(name, event) do
  test_pid = self()
  :ok =
    :telemetry.attach(
      name,
      event,
      fn evt, meas, meta, _ -> send(test_pid, {:telemetry, evt, meas, meta}) end,
      nil
    )
  ExUnit.Callbacks.on_exit(fn -> :telemetry.detach(name) end)
end
```
Copy verbatim — use for `[:accrue, :ops, :dunning_campaign_started]`, `[:accrue, :ops, :dunning_step_sent]`, `[:accrue, :ops, :dunning_recovered]`, `[:accrue, :ops, :dunning_exhausted]`.

**`ledger_events/2` helper** (lines 118–126):
```elixir
defp ledger_events(type, subject_id) do
  Repo.all(
    from(e in LedgerEvent,
      where:
        e.type == ^type and e.subject_type == "Subscription" and
          e.subject_id == ^subject_id
    )
  )
end
```
Copy verbatim — use with `"dunning.campaign_started"`, `"dunning.step_sent"`, `"dunning.recovered"`, `"dunning.exhausted"`.

**Clock-advance + drain pattern** (from RESEARCH.md Pattern 3):
```elixir
# After firing invoice.payment_failed and asserting stage 1:
{:ok, _} = Accrue.Test.Clock.advance([days: 5])   # absolute from anchor
Oban.drain_queue(queue: :accrue_dunning)
# assert :action_required step delivered + ledger event + telemetry

{:ok, _} = Accrue.Test.Clock.advance([days: 7])   # 5+7=12 total from anchor
Oban.drain_queue(queue: :accrue_dunning)
# assert :final_notice step delivered + ledger event + telemetry
```

**Capabilities label mirror test** (D-09 — from RESEARCH.md Pattern 3):
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

**DunningSweeper exhaustion pattern** (from `dunning_sweeper_test.exs` lines 109–135):
```elixir
# Exhaustion stage — call sweep/0 directly in the test
assert {:ok, _} = DunningSweeper.sweep()
# Then assert dunning.exhausted ledger event + telemetry
```

---

### `examples/accrue_host/config/config.exs` (extend Oban block)

**Analog:** itself — Oban config block (lines 37–44)

**Current state** (lines 37–44):
```elixir
config :accrue_host, Oban,
  repo: AccrueHost.Repo,
  queues: [
    accrue_webhooks: 10,
    accrue_mailers: 20,
    accrue_pdf: 5
  ],
  plugins: [{Oban.Plugins.Pruner, max_age: 60 * 60 * 24}]
```

**Target state** (add `accrue_dunning` queue + Cron plugin):
```elixir
config :accrue_host, Oban,
  repo: AccrueHost.Repo,
  queues: [
    accrue_webhooks: 10,
    accrue_mailers: 20,
    accrue_pdf: 5,
    accrue_dunning: 2
  ],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24},
    {Oban.Plugins.Cron,
     crontab: [
       {"*/15 * * * *", Accrue.Jobs.DunningSweeper}
       # {"0 7 * * *", Accrue.Jobs.DetectExpiringCards}  # planner discretion: needs accrue_scheduled: 5 queue too
     ]}
  ]
```

**Note:** `DetectExpiringCards` uses `queue: :accrue_scheduled` (not `:accrue_dunning`) — if included, add `accrue_scheduled: 5` to the queues list too (Pitfall 6 in RESEARCH.md).

---

### `examples/accrue_host/test/accrue_host/dunning_wiring_test.exs` (new test)

**Analog:** `accrue/test/accrue/jobs/dunning_sweeper_test.exs` (Fake-backed BillingCase pattern)

**Module header pattern** (dunning_sweeper_test.exs lines 1–27):
```elixir
defmodule Accrue.Jobs.DunningSweeperTest do
  use Accrue.BillingCase, async: false
  # ...
  @default_policy [
    mode: :stripe_smart_retries,
    grace_days: 14,
    terminal_action: :unpaid,
    telemetry_prefix: [:accrue, :ops]
  ]
```
For the host test, use `AccrueHost.BillingCase` (or equivalent host test case) with `async: false`.

**`setup` pattern** (dunning_sweeper_test.exs lines 28–53): copy the `prev = Application.get_env` + `on_exit` + customer seed pattern verbatim. The host proof is a THIN wiring smoke (not a duplicate of the full accrue-layer journey):
- Seed ONE subscription in `past_due` state
- Fire `invoice.payment_failed` through `DefaultHandler` (or the host's webhook plug)
- Assert `accrue_dunning` queue has a job (`all_enqueued(worker: Accrue.Workers.DunningStep)`)
- `Oban.drain_queue(queue: :accrue_dunning)` and assert step delivered
- Assert `DunningSweeper.sweep/0` can run without error (wiring verification only)

**`seed_sub/2` helper** (dunning_sweeper_test.exs lines 55–77):
```elixir
defp seed_sub(customer, attrs) do
  {:ok, fake_sub} =
    Accrue.Processor.Fake.create_subscription(
      %{customer: customer.processor_id, items: [%{price: "price_basic"}]},
      []
    )

  row_attrs =
    attrs
    |> Map.put_new(:status, :past_due)
    |> Map.put(:processor_id, fake_sub.id)

  {:ok, sub} =
    %Subscription{customer_id: customer.id, processor: "fake"}
    |> Subscription.force_status_changeset(row_attrs)
    |> Repo.insert()

  sub
end
```
Copy this helper verbatim for the host test.

---

### `examples/accrue_host/docs/adoption-proof-matrix.md` (extend)

**Analog:** itself — Blocking table (lines 14–26)

**Existing row format** (lines 18–26):
```markdown
| Billing **`Accrue.Billing.create_checkout_session/2`** facade + ... | `checkout_session_facade_test.exs` + ... | `accrue` package |
```

**Add a dunning row** to the Blocking table:
```markdown
| Dunning campaign wiring: `accrue_dunning` queue + `Oban.Plugins.Cron` in host config; Fake-backed failed-payment → campaign-step → recovery loop through real webhook entry point | `dunning_wiring_test.exs` (host-level smoke) + `dunning_full_journey_test.exs` (accrue package, full journey) | `examples/accrue_host/test/`, `accrue/test/accrue/dunning/` |
```

---

### `scripts/ci/verify_adoption_proof_matrix.sh` (extend)

**Analog:** itself — existing `require_substring` calls (lines 22–62)

**Add dunning needle** (after line 62, before the negative guards):
```bash
require_substring "dunning_wiring_test.exs" "dunning host wiring proof path in matrix"
require_substring "accrue_dunning" "accrue_dunning queue mention in matrix"
require_substring "Oban.Plugins.Cron" "Oban Cron plugin mention in matrix"
require_substring "dunning_full_journey_test.exs" "dunning full journey proof path in matrix"
```

---

## Shared Patterns

### App-env guard for dunning config in tests
**Source:** `accrue/test/accrue/webhook/dunning_campaign_start_test.exs` lines 39–47
**Apply to:** `dunning_full_journey_test.exs`, `dunning_wiring_test.exs`
```elixir
setup do
  prev_dunning = Application.get_env(:accrue, :dunning, :__unset__)

  on_exit(fn ->
    case prev_dunning do
      :__unset__ -> Application.delete_env(:accrue, :dunning)
      value -> Application.put_env(:accrue, :dunning, value)
    end
  end)
  ...
end
```

### Telemetry capture in tests
**Source:** `accrue/test/accrue/webhook/dunning_campaign_start_test.exs` lines 104–116
**Apply to:** `dunning_full_journey_test.exs`
```elixir
defp attach_telemetry(name, event) do
  test_pid = self()
  :ok =
    :telemetry.attach(
      name,
      event,
      fn evt, meas, meta, _ -> send(test_pid, {:telemetry, evt, meas, meta}) end,
      nil
    )
  ExUnit.Callbacks.on_exit(fn -> :telemetry.detach(name) end)
end
```

### `require_substring` bash helper
**Source:** `scripts/ci/verify_processor_support_matrix.sh` lines 13–20
**Apply to:** both bash gate scripts (already present in both — extend in place, do not duplicate the helper function definition)

### Negative convergence guard pattern
**Source:** `scripts/ci/verify_processor_support_matrix.sh` lines 105–119
**Apply to:** `verify_processor_support_matrix.sh` — add a sibling guard for `dunning.campaign`
```bash
if grep -Eq '^\| entitlements\.local_mapping \|.*\b(native|unsupported|bounded)\b' "${matrix}"; then
  echo "verify_processor_support_matrix: entitlements.local_mapping convergence row sprouted a per-provider divergence label..." >&2
  exit 1
fi
```

### Fake-backed subscription seed
**Source:** `accrue/test/accrue/jobs/dunning_sweeper_test.exs` lines 55–77
**Apply to:** `dunning_wiring_test.exs`
```elixir
defp seed_sub(customer, attrs) do
  {:ok, fake_sub} =
    Accrue.Processor.Fake.create_subscription(
      %{customer: customer.processor_id, items: [%{price: "price_basic"}]},
      []
    )
  row_attrs = attrs |> Map.put_new(:status, :past_due) |> Map.put(:processor_id, fake_sub.id)
  {:ok, sub} =
    %Subscription{customer_id: customer.id, processor: "fake"}
    |> Subscription.force_status_changeset(row_attrs)
    |> Repo.insert()
  sub
end
```

### Clock-advance + drain (deterministic Oban in tests)
**Source:** `accrue/lib/accrue/test/clock.ex` + Oban `:manual` mode in `test_helper.exs:51`
**Apply to:** `dunning_full_journey_test.exs`
```elixir
{:ok, _} = Accrue.Test.Clock.advance([days: N])
Oban.drain_queue(queue: :accrue_dunning)
```
NEVER use `Process.sleep`. The advance is in absolute days from the campaign anchor (default journey `[0, 5, 12]` is `after_days` absolute, not relative).

---

## No Analog Found

None. All files have clear analogs in the codebase.

---

## Critical Anti-Patterns (extracted from RESEARCH.md)

| Anti-pattern | Why it fails | Correct pattern |
|---|---|---|
| Call `maybe_start_dunning_campaign/2` directly in the test | Bypasses the real webhook entry point; the suite can pass while the production path is dead | Always drive through `DefaultHandler.handle(StripeFixtures.webhook_event(...))` |
| `Process.sleep` for time advance | Non-deterministic, earns `:slow` tag, excluded from merge gate | `Accrue.Test.Clock.advance([days: N])` + `Oban.drain_queue/1` |
| Invent new label vocabulary | Breaks the label mirror test + bash gate | Use exactly: `"local-identical"`, `"native (Smart Retries)"`, `"unsupported (clock-driven only)"`, `"testing/local-only"`, `"all first-party"` |
| Create a dedicated `verify_dunning_docs.sh` | Split-brain SSOT against the shared processor script | Extend `verify_processor_support_matrix.sh` in place (D-05) |
| Re-derive `past_due`/`unpaid` lifecycle in dunning.md | Creates a split-brain SSOT with `lifecycle_semantics.md` | Cross-reference `lifecycle_semantics.md` lines ~150–211 |
| Wire `DetectExpiringCards` without `accrue_scheduled` queue | Job silently fails (uses `queue: :accrue_scheduled`, not `:accrue_dunning`) | If wired, add `accrue_scheduled: 5` to host queue config |
| Run `Oban.drain_queue` inside a `Repo.transact` call | Oban dispatches against `conf.repo`, may not see the wrapping transaction | Drain AFTER commits |

---

## Metadata

**Analog search scope:** `accrue/lib/accrue/processor/`, `accrue/test/accrue/webhook/`, `accrue/test/accrue/jobs/`, `accrue/guides/`, `scripts/ci/`, `examples/accrue_host/`
**Files scanned:** 14
**Pattern extraction date:** 2026-05-25
