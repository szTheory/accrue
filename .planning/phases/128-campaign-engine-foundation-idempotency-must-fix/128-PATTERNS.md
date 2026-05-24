# Phase 128: Campaign Engine Foundation + Idempotency Must-Fix - Pattern Map

**Mapped:** 2026-05-24
**Files analyzed:** 17 (6 new code + 1 new migration + 5 new tests + 5 modified)
**Analogs found:** 16 / 17 (1 pure module has a convention analog, not a 1:1 clone target)

> **Anchor source of truth:** all line numbers below were re-verified against the LIVE `accrue/` tree (2026-05-24), not copied from CONTEXT. Where RESEARCH's corrected drift table and CONTEXT disagreed, the live numbers here win. Key drift confirmed: `do_dispatch_invoice` *def* at **:1472** (the `payment_failed` *clause* of `maybe_dispatch_invoice_email` is at **:1466**); `validate_entitlements_price_ids!` *call* at **:958** / *def* at **:968**; `validate_descending` def at **:1047** (CONTEXT said ~1046); `dunning:` schema entry at **:228**; `past_due_grace/0` at **:784**; `dunning/0` at **:771**; `maybe_validate_boot_setup!/1` at **:947**; `maybe_bump_past_due_since/2` at **:969**; `maybe_emit_dunning_exhaustion/2` def at **:758** (call at :736); subscription `@cast_fields` at **:88**, `force_status_changeset/2` at **:106-113**, field block :57-86; `mailer/default.ex` `deliver/2` at **:33**; mailer worker `idempotency_key/2` family :292-314, `default_template/1` :319-332, `{:cancel, reason}` at :107.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| **NEW** `lib/accrue/dunning/campaign.ex` | service (pure domain) | transform | `lib/accrue/billing/dunning.ex` | role-match (pure-policy convention) |
| **NEW** `lib/accrue/workers/dunning_step.ex` | worker | event-driven (Oban) | `lib/accrue/jobs/dunning_sweeper.ex` + `lib/accrue/billing/metered_renewal_actions.ex` (enqueue helper) | exact (queue) + role (unique) |
| **NEW** `lib/accrue/emails/dunning_action_required.ex` | view/template | render | `lib/accrue/emails/card_expiring_soon.ex` | exact |
| **NEW** `lib/accrue/emails/dunning_final_notice.ex` | view/template | render | `lib/accrue/emails/card_expiring_soon.ex` | exact |
| **NEW** `priv/repo/migrations/XXXX_add_dunning_campaign_started_at_to_subscriptions.exs` | migration | DDL | `priv/repo/migrations/20260414130300_add_dunning_and_pause_columns_to_subscriptions.exs` | exact |
| **NEW** `test/property/dunning_campaign_property_test.exs` | test (property) | transform | `test/property/connect_platform_fee_property_test.exs` | exact |
| **NEW** `test/accrue/config_dunning_campaign_test.exs` | test (unit/property) | request-response | `test/accrue/config_entitlements_test.exs` | exact |
| **NEW** `test/accrue/webhook/dunning_campaign_start_test.exs` | test (integration) | event-driven | `test/accrue/webhook/dunning_exhaustion_test.exs` | exact |
| **NEW** `test/accrue/webhook/dunning_campaign_keying_test.exs` | test (integration) | event-driven | `test/accrue/webhook/dunning_exhaustion_test.exs` | exact |
| **NEW** `test/accrue/workers/mailer_idempotency_test.exs` | test (integration) | event-driven | `test/accrue/workers/mailer_dispatch_test.exs` | role-match |
| **MOD** `lib/accrue/config.ex` | config | request-response | self (`dunning:` :228, `validate_descending` :1047, `validate_entitlements_price_ids!` :968, `past_due_grace/0` :784) | self-precedent |
| **MOD** `lib/accrue/billing/subscription.ex` | model | CRUD | self (`dunning_sweep_attempted_at` field :65 + `@cast_fields` :88 + predicates :138+) | self-precedent |
| **MOD** `lib/accrue/webhook/default_handler.ex` | controller (webhook reducer) | event-driven | self (`maybe_bump_past_due_since/2` :969, `maybe_emit_dunning_exhaustion/2` :758, `do_dispatch_invoice` :1472) | self-precedent |
| **MOD** `lib/accrue/mailer/default.ex` | service (adapter) | event-driven | self (`deliver/2` :33) | self-precedent |
| **MOD** `lib/accrue/workers/mailer.ex` | worker | event-driven | self (`idempotency_key/2` :292-314, `default_template/1` :319-332) | self-precedent |

---

## Pattern Assignments — NEW files

### `lib/accrue/dunning/campaign.ex` (service, pure transform) — D-11 step resolution

**Analog:** `lib/accrue/billing/dunning.ex` (the sibling pure-policy module — same `lib/accrue/billing/`/`lib/accrue/dunning/` namespace family, same "no side effects, no DB, no Stripe" contract). No 1:1 clone exists for the next-step math; mirror this module's *shape*: typed pure functions, cond-based decisions, separate boundary helper.

**Pure-module convention to copy** (`dunning.ex:1-83`):
- Moduledoc states the no-side-effects contract explicitly ("No side effects, no DB, no Stripe calls").
- `@type decision :: ...` + `@type policy :: keyword()` up top.
- A single `@spec`'d pure entry function using `cond do` over the inputs (`compute_terminal_action/2` at :47-68).
- A `nil`-tolerant boundary helper with a guard clause then a real clause (`grace_elapsed?/3` at :77-82 — `def grace_elapsed?(nil, _, _), do: false` then the `%DateTime{}` clause). The campaign resolver wants the analogous `next_step([], _, _)`/at-final-step → `nil`/`:done` clause.

**Time/elapsed math precedent** (`dunning.ex:79-81`):
```elixir
DateTime.diff(now, past_due_since, :second) > grace_days * 86_400
```
Campaign resolver computes `schedule_in` from `after_days[N] − elapsed` where `elapsed = DateTime.diff(now, campaign_started_at, :second)`. Keep it pure: signature `(steps, campaign_started_at, now)` per RESEARCH § Architectural Responsibility Map — both `campaign_started_at` and `now` are passed in (do NOT call `Accrue.Clock.utc_now/0` inside the pure module; the worker passes it). This is what makes the property test (`(steps, started_at, now)` generators) and the Phase-131 engine seam clean.

**Property-test target:** zero-elapsed (day-0), at-boundary, past-last-step, single-step list, ordering — clone generator structure from `connect_platform_fee_property_test.exs` (see test assignment below).

---

### `lib/accrue/workers/dunning_step.ex` (worker, event-driven) — D-10, D-11, D-16

**Primary analog:** `lib/accrue/jobs/dunning_sweeper.ex` (same `:accrue_dunning` queue, `max_attempts: 3`, `Accrue.Clock.utc_now/0` usage).
**Secondary analog:** `lib/accrue/billing/metered_renewal_actions.ex` (the `unique:` enqueue keyword + `maybe_iso8601/1` scalar coercion).

**Worker `use` + queue** (`dunning_sweeper.ex:46`):
```elixir
use Oban.Worker, queue: :accrue_dunning, max_attempts: 3
```
Reuse the EXACT same queue atom — already configured `accrue_dunning: 2` (dunning_sweeper.ex:32 moduledoc) and documented in operator-runbooks.md. `max_attempts: 3` matches the sweeper (light orchestration; heavy email retries live in the downstream `:accrue_mailers` worker at `max_attempts: 5`).

**`perform/1` job-middleware + entry** (`dunning_sweeper.ex:53-57`):
```elixir
@impl Oban.Worker
def perform(%Oban.Job{} = job) do
  Accrue.Oban.Middleware.put(job)
  sweep()
end
```
Note the `Accrue.Oban.Middleware.put(job)` call — established worker entry convention; carry it into `DunningStep.perform/1`.

**`unique:` enqueue keyword** (`metered_renewal_actions.ex:302-310`):
```elixir
defp enqueue_processing(%MeteredRenewal{} = renewal) do
  %{metered_renewal_id: renewal.id}
  |> Oban.Job.new(
    worker: "Accrue.Jobs.ProcessMeteredRenewal",
    queue: :accrue_meters,
    unique: [fields: [:worker, :args], keys: [:metered_renewal_id], period: 60]
  )
  |> Oban.insert()
end
```
For `DunningStep`, build via `DunningStep.new(args, schedule_in: delay, unique: [...])` (use the generated `.new/2` since the module IS the worker) and override per D-16:
```elixir
unique: [fields: [:worker, :args],
         keys: [:subscription_id, :step_key, :campaign_started_at],
         period: :infinity,
         states: [:available, :scheduled, :executing, :retryable, :completed]]
```
(`period: :infinity` + `:completed` — NOT the `:60` in the metered precedent — because Stripe Smart Retries span weeks; RESEARCH Pitfall 5. The keys/fields *shape* clones the precedent verbatim.)

**ISO8601 scalar arg coercion** (`metered_renewal_actions.ex:312-313`):
```elixir
defp maybe_iso8601(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
defp maybe_iso8601(_), do: nil
```
`campaign_started_at` MUST be an ISO8601 string in args (Oban args are JSON; `only_scalars!` forbids structs). Thread it through every chained enqueue verbatim (same value → same campaign identity). Parse back with `DateTime.from_iso8601/1` (NOT `String.to_atom`/`to_existing_atom` — RESEARCH Security Domain atom-exhaustion note).

**Clock for the anchor / `now`** (`dunning_sweeper.ex:101`):
```elixir
now_usec = %{Accrue.Clock.utc_now() | microsecond: {0, 6}}
```
Use `Accrue.Clock.utc_now/0` (NOT `DateTime.utc_now/0`) everywhere a wall-clock is needed in the worker, for Fake-lane determinism (Phase 130). The `microsecond: {0, 6}` normalization matches the anchor column's `:utc_datetime_usec` precision (same trick used at default_handler.ex:976 for `past_due_since`).

**Cancel-guard return convention** (`workers/mailer.ex:107` / :65-66): the Mailer worker returns `{:cancel, reason}` for a non-retryable skip. `DunningStep.perform/1` step (1) reloads the row and returns `{:cancel, :recovered}` when `not past_due? OR is_nil(dunning_campaign_started_at)`, delivering nothing — same `{:cancel, atom}` convention.

**Delivery call** (step 2): `Accrue.Mailer.deliver(type, assigns)` (the same behaviour entry the webhook reducer uses via `safe_deliver/2` at default_handler.ex:1552). Pass scalar assigns incl. `subscription_id`, `step_key`, `campaign_started_at`, `customer_id`, `invoice_id` (all IDs/strings — D-17).

---

### `lib/accrue/emails/dunning_action_required.ex` + `dunning_final_notice.ex` (template, render) — D-01, D-02

**Analog:** `lib/accrue/emails/card_expiring_soon.ex` (the `@update_pm_url` portal-CTA pattern — every dunning-step CTA deep-links the portal update-payment-method flow). Cross-reference `lib/accrue/emails/invoice_payment_failed.ex` (reused as step-1; the `template_assigns` + invoice-footer shape).

**Module preamble + put_function** (`card_expiring_soon.ex:1-36`):
```elixir
use Mailglass.Mailable, stream: :transactional
use Phoenix.Component

def message(assigns) when is_map(assigns) do
  assigns = template_assigns(assigns)
  new()
  |> from({map_get(assigns.branding, :from_name) || "Acme Billing",
           map_get(assigns.branding, :from_email) || "billing@example.test"})
  |> to(assigns.customer_email || assigns.to || map_get(assigns.customer, :email) || "")
  |> subject(assigns.subject)
  |> html_body(html(assigns) |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary())
  |> Mailglass.Message.put_function(:card_expiring_soon)   # ← use :dunning_action_required / :dunning_final_notice
end
```
Each new module exports the full quartet: `subject/1`, `message/1`, `render/1`, `render_text/1` (the last two delegate to `Mailglass.Renderer.render(message(assigns))` verbatim — `card_expiring_soon.ex:38-48`).

**Portal-CTA pattern — THE thing to copy** (`card_expiring_soon.ex:73-75` + assigns plumbing :106):
```elixir
<%= if @update_pm_url do %>
  <.button href={@update_pm_url}>Update payment method</.button>
<% end %>
```
and in `template_assigns/1`:
```elixir
update_pm_url: map_get(context, :update_pm_url) || map_get(assigns, :update_pm_url)
```
The CTA target is `accrue_portal/lib/accrue_portal/live/add_payment_method_live.ex` (verified present) — the highest-converting recovery action. The URL arrives via `context`/`assigns` (resolved upstream), exactly as `card_expiring_soon` already does.

**HEEx layout + footer** (`card_expiring_soon.ex:53-83`): wrap in `<Mailglass.Components.Layout.email_layout title={@subject}>` with `<.container>` / `<.section>` / `<.heading>` / `<.text>` / `<.button>` and close with `<Accrue.Invoices.Components.footer context={@context} />`. Reuse identically; only the copy changes (firmer for `:action_required`, urgent/last-chance for `:final_notice` per D-01 table).

**Helper footer** (`card_expiring_soon.ex:117-129`): copy `map_get/2` (map + keyword + fallback clauses) and `normalize_map/1` verbatim — both new templates need them.

---

### `priv/repo/migrations/XXXX_add_dunning_campaign_started_at_to_subscriptions.exs` (migration) — D-08

**Analog:** `priv/repo/migrations/20260414130300_add_dunning_and_pause_columns_to_subscriptions.exs` (the migration that added the sibling `dunning_sweep_attempted_at`).

**Column add pattern** (analog :20-27):
```elixir
def change do
  alter table(:accrue_subscriptions) do
    add :dunning_campaign_started_at, :utc_datetime_usec, null: true
  end
end
```
Forward-only, nullable (existing rows survive with `nil` anchor — RESEARCH Runtime State Inventory: no backfill). **Do NOT add the partial index** that the analog adds for `past_due_since` — D-08 says no index is required for correctness (an optional partial `WHERE dunning_campaign_started_at IS NOT NULL` is explicitly deferred to Phase 129). Pick a fresh timestamp prefix > existing migrations; moduledoc should note "nullable, forward-only, mirrors `dunning_sweep_attempted_at`."

---

### `test/property/dunning_campaign_property_test.exs` (property test) — DUN-02 pure resolver

**Analog:** `test/property/connect_platform_fee_property_test.exs` (the stream_data structure for a pure module).

**Preamble** (analog :19-22):
```elixir
use ExUnit.Case, async: true
use ExUnitProperties
alias Accrue.Dunning.Campaign
```
**Generator + property convention** (analog :29-44, :81-94): named `defp *_gen` generators composed via `StreamData.bind`/`map`, properties with `check all(... max_runs: 200)`. Generate ordered step lists (`after_days` strictly-increasing), random `campaign_started_at`/`now` offsets; assert next-step + `schedule_in` math is deterministic, day-0 returns step-1 immediately, past-last-step returns `nil`/`:done`. The pure-module signature `(steps, started_at, now)` keeps this independent of DB/Oban (no sandbox needed → `async: true`).

---

### `test/accrue/config_dunning_campaign_test.exs` (unit + property) — DUN-01 validation

**Analog:** `test/accrue/config_entitlements_test.exs` (the boot-validation test pattern for config that mutates app env).

**`async: false` + env save/restore** (analog :5, :28-39):
```elixir
use ExUnit.Case, async: false
alias Accrue.Config

setup do
  prev = Application.get_env(:accrue, :dunning, :__unset__)
  on_exit(fn ->
    case prev do
      :__unset__ -> Application.delete_env(:accrue, :dunning)
      value -> Application.put_env(:accrue, :dunning, value)
    end
  end)
  :ok
end
```
Mutating `:accrue` app env REQUIRES `async: false` (analog comment :2-4).

**Boot-validation assertion** (analog :41-49): `Config.validate_at_boot!()` returns `:ok` for valid config and `assert_raise Accrue.ConfigError, fn -> ... end` for the cross-field grace violation (last_step.after_days > grace_days). Test the intra-list `{:custom}` validator (`validate_dunning_campaign/1`) directly for strictly-increasing/unique `after_days`, unique `key`, `campaign: false` → `[enabled: false, steps: []]`, empty-steps-while-enabled = loud error. Add property generators for the strictly-increasing/unique invariants (stream_data is available; analog uses plain unit but the resolver-style generators from `connect_platform_fee_property_test.exs` apply here too).

---

### `test/accrue/webhook/dunning_campaign_start_test.exs` + `dunning_campaign_keying_test.exs` (integration) — DUN-02, DUN-05

**Analog:** `test/accrue/webhook/dunning_exhaustion_test.exs` (drives a webhook through `DefaultHandler`, seeds a `past_due` subscription, uses Fake stubs).

**Case + setup** (analog :18-47):
```elixir
use Accrue.BillingCase, async: false
alias Accrue.Billing.Subscription
alias Accrue.Webhook.DefaultHandler
```
Seed a customer + a local `past_due` subscription via `Subscription.force_status_changeset/2` (analog :38-44).

**Fake processor stub** (analog :51-69): `Fake.stub(:retrieve_invoice, fn _id, _opts -> {:ok, canonical} end)` with a canonical `invoice.payment_failed` map carrying `"subscription"` + `"next_payment_attempt"`. **Pitfall 1 (RESEARCH § Common Pitfalls):** drive the REAL entry point — push the webhook fixture through `DefaultHandler`, do NOT call `maybe_bump_past_due_since/2` directly — then assert a `DunningStep` job is enqueued.

**Oban enqueue assertions:** test_helper boots Oban `testing: :manual` (test_helper.exs:51-56) so `assert_enqueued`/`perform_job`/`all_enqueued` are available (already used in `test/accrue/mailer_test.exs` + `default_handler_mailer_dispatch_test.exs` — grep those for the exact `import Oban.Testing` / `use Oban.Testing, repo: Accrue.TestRepo` line to copy). For the `start_test`: assert one day-0 `DunningStep` enqueued; assert D-15 REPLACE (campaign enabled ⇒ NO standalone `:invoice_payment_failed` email; disabled ⇒ exactly one, deduped). For the `keying_test`: concurrent `update_all where is_nil(anchor)` exactly-one-winner (use `Task.async_stream` + shared sandbox per RESEARCH concurrency note), already-running no-op, cancel-on-recovery via `Oban.cancel_all_jobs` keyed on `campaign_started_at`, and the `perform_job` cancel-guard returning `{:cancel, :recovered}`.

---

### `test/accrue/workers/mailer_idempotency_test.exs` (integration) — DUN-04 immediate dedup

**Analog:** `test/accrue/workers/mailer_dispatch_test.exs` (mailer worker test scaffolding; `async: false`, env save/restore for `:mailer` adapter at :17-33). Pair with Oban.Testing helpers (test_helper.exs:46-56) for the `unique`/`conflict?` assertions.

**What to prove:** duplicate `Accrue.Mailer.deliver(:invoice_payment_failed, %{invoice_id: ...})` enqueue returns `{:ok, %Oban.Job{conflict?: true}}` (no second job, even across a simulated week-2 redelivery via `period: :infinity` + `:completed`); `idempotency_key(:invoice_payment_failed, assigns)` keys on `invoice_id` and returns `{:error, :missing_invoice_id}` on nil/empty; `dedup_unique/2` returns `false` for every non-`:invoice_payment_failed` type (no-regression). Flip `:mailer` to `Accrue.Mailer.Default` per-test (analog :22-23) so the real `Oban.insert` path with the derived `unique` runs.

---

## Pattern Assignments — MODIFIED files

### `lib/accrue/config.ex` — D-04, D-05, D-06, D-07

**Self-precedents (all in this file):**

**1. Schema entry to extend** (`config.ex:228-242`) — the existing `dunning:` entry. Today it's `type: :keyword_list`. Give it an explicit `:keys` list (typing `mode`/`grace_days`/`terminal_action`/`telemetry_prefix`) and add the nested `campaign:` sub-key:
```elixir
campaign: [
  type: {:custom, __MODULE__, :validate_dunning_campaign, []},
  default: [enabled: true, steps: @default_dunning_steps],
  doc: "..."   # see D-04 text
]
```

**2. Per-field `{:custom}` validator** — clone `validate_descending/1` (`config.ex:1046-1063`):
```elixir
@spec validate_descending(term()) :: {:ok, [pos_integer()]} | {:error, String.t()}
def validate_descending(list) when is_list(list) and list != [] do
  cond do
    not Enum.all?(list, &(is_integer(&1) and &1 > 0)) ->
      {:error, "expected a list of positive integers, got: #{inspect(list)}"}
    not strictly_descending?(list) ->
      {:error, "expected a strictly descending list of positive integers, got: #{inspect(list)}"}
    true -> {:ok, list}
  end
end
def validate_descending(other), do: {:error, "..."}
```
`validate_dunning_campaign/1` mirrors this: a `cond do` returning `{:ok, normalized} | {:error, msg}`, validating each step against a private `@step_schema` (via `NimbleOptions.validate/2`), checking `after_days` strictly-increasing + unique, `key` unique, non-empty-when-enabled, and normalizing `campaign: false` → `[enabled: false, steps: []]` (D-05). Helper precedent `strictly_descending?/1` at :1119-1123 (recursive list-pair guard) — clone shape for `strictly_increasing?/1`.

**3. Cross-field boot validator** — clone `validate_entitlements_price_ids!/1` (`config.ex:968-998`) and CALL it from `maybe_validate_boot_setup!/1` directly after the entitlements call:
```elixir
defp maybe_validate_boot_setup!(opts) do
  _ = Keyword.fetch!(opts, :repo)
  if safe_mix_env() != :test, do: _ = ensure_migrations_current!()
  if Keyword.get(opts, :processor, Accrue.Processor.Fake) == Accrue.Processor.Stripe,
    do: _ = webhook_signing_secrets(:stripe)
  _ = validate_entitlements_price_ids!(opts)
  _ = validate_dunning_campaign_grace!(opts)   # ← D-06: ADD HERE (config.ex:958→959)
  :ok
end
```
The raise convention (from `validate_entitlements_price_ids!` at :984):
```elixir
raise Accrue.ConfigError, key: :dunning, message: "..."
```
(`Accrue.ConfigError` is `defexception [:message, :key, :diagnostic]` — verified errors.ex:112; passing `key:` + `message:` matches the entitlements precedent. The :963-967 comment on the entitlements validator already documents WHY cross-field can't be `{:custom}` — model the new validator's comment on it.) Reads sibling `grace_days` from `opts[:dunning][:grace_days]` (default 14) and the campaign's last step; raises if `last_step.after_days > grace_days`.

**4. Accessors** — clone `dunning/0` (`config.ex:771`) + `past_due_grace/0` (`config.ex:784`):
```elixir
def dunning, do: get!(:dunning)
def past_due_grace, do: entitlements() |> Keyword.get(:past_due_grace, :none)
```
Add (D-07, namespaced `dunning_campaign*`):
```elixir
def dunning_campaign, do: dunning() |> Keyword.get(:campaign, [enabled: true, steps: @default_dunning_steps])
def dunning_campaign_enabled?, do: Keyword.get(dunning_campaign(), :enabled, false)
def dunning_campaign_steps, do: if(dunning_campaign_enabled?(), do: Keyword.get(dunning_campaign(), :steps, []), else: [])
```

**5. Module attrs** — add `@step_schema` (private per-step NimbleOptions schema, shape `[after_days: [type: :non_neg_integer, required: true], key: [type: :atom, required: true], template: [type: :atom, required: true]]`) and `@default_dunning_steps` (the D-01 `[0,5,12]` cadence) near the top, beside the existing `@schema` definition. (Templates as `:atom` type since module names ARE atoms; `{:in,...}` not needed.)

---

### `lib/accrue/billing/subscription.ex` — D-08

**Self-precedent:** the sibling `dunning_sweep_attempted_at` column.

**Field** (`subscription.ex:64-65`):
```elixir
field(:past_due_since, :utc_datetime_usec)
field(:dunning_sweep_attempted_at, :utc_datetime_usec)
```
Add `field(:dunning_campaign_started_at, :utc_datetime_usec)` right after :65.

**`@cast_fields`** (`subscription.ex:88-97`, the field is listed on :91):
```elixir
paused_at pause_behavior past_due_since dunning_sweep_attempted_at discount_id
```
Add `dunning_campaign_started_at` to this word-list (used by BOTH `force_status_changeset/2` :106-113 and `changeset/2` :122-130 — the recovery-clear path D-12 casts it; the START path D-09 is a sibling `update_all`, NOT a cast).

**Predicate** — clone the lifecycle-predicate shape (e.g. `dunning_sweepable?/1` at :239-241, or `past_due?/1` at :154-156):
```elixir
def dunning_sweepable?(%__MODULE__{status: :past_due}), do: true
def dunning_sweepable?(%{status: :past_due}), do: true
def dunning_sweepable?(_), do: false
```
Add beside these (after :256):
```elixir
def dunning_campaign_active?(%__MODULE__{dunning_campaign_started_at: %DateTime{}}), do: true
def dunning_campaign_active?(%{dunning_campaign_started_at: %DateTime{}}), do: true
def dunning_campaign_active?(_), do: false
```
(Dual `%__MODULE__{}` + bare-map clauses + catch-all — the established two-shape predicate convention used by every predicate :138-256.)

---

### `lib/accrue/webhook/default_handler.ex` — D-09, D-12, D-15

**Self-precedents (all in this file):**

**1. D-09 first-transition elector** — extend `maybe_bump_past_due_since/2` (`default_handler.ex:969-989`). Today:
```elixir
defp maybe_bump_past_due_since("payment_failed", canonical) do
  with sub_stripe_id when is_binary(sub_stripe_id) <- get(canonical, :subscription),
       %Subscription{} = sub <- Repo.get_by(Subscription, processor_id: sub_stripe_id),
       attempt_unix when is_integer(attempt_unix) <- get(canonical, :next_payment_attempt) do
    past_due_since = attempt_unix |> DateTime.from_unix!() |> Map.put(:microsecond, {0, 6})
    case sub |> Subscription.force_status_changeset(%{past_due_since: past_due_since}) |> Repo.update() do
      {:ok, _} -> :ok
      {:error, _} = err -> err
    end
  else
    _ -> :ok
  end
end
```
Keep the `past_due_since` bump UNCHANGED. Add a SIBLING atomic elector (sets one column, does not touch `lock_version`):
```elixir
now_usec = %{Accrue.Clock.utc_now() | microsecond: {0, 6}}
{count, _} =
  from(s in Subscription, where: s.id == ^sub.id and is_nil(s.dunning_campaign_started_at))
  |> Repo.update_all(set: [dunning_campaign_started_at: now_usec])
# count == 1 → won the edge → enqueue day-0 DunningStep with campaign_started_at: DateTime.to_iso8601(now_usec)
# count == 0 → already running → no-op
```
The `%{Accrue.Clock.utc_now() | microsecond: {0, 6}}` form is the verbatim clock idiom from dunning_sweeper.ex:101. Note the existing fn already loads the `%Subscription{} = sub` — D-09 reuses that loaded struct's `sub.id`. (`import Ecto.Query`/`from` is already in scope in this module — confirm at top; if not, the `update_all` needs the query import.)

**2. D-12 cancel-on-recovery** — clone `maybe_emit_dunning_exhaustion/2` (`default_handler.ex:756-775`) as a sibling, wired into `reduce_subscription/1`'s `with` chain at :736:
```elixir
defp maybe_emit_dunning_exhaustion(nil, _updated), do: :ok
defp maybe_emit_dunning_exhaustion(%Subscription{} = row, %Subscription{} = updated) do
  with true <- Subscription.dunning_sweepable?(row),
       to_status when not is_nil(to_status) <- Subscription.dunning_exhausted_status(updated) do
    :telemetry.execute([:accrue, :ops, :dunning_exhaustion], %{count: 1}, %{...})
  end
  :ok
end
```
`maybe_finalize_dunning_campaign/2` mirrors this signature `(row, updated)` and the `with true <- ...` guard shape — but the body, instead of telemetry (telemetry is Phase 129 — do NOT emit), does: when `row` WAS `dunning_campaign_active?/1` and `updated` is active/paid, in one transaction (a) nil the anchor via `force_status_changeset(%{dunning_campaign_started_at: nil})`, (b) `Oban.cancel_all_jobs/2` keyed on `worker` + `subscription_id` + `campaign_started_at` (D-12 query). Add to the `with` chain at :736 beside `maybe_emit_dunning_exhaustion(row, updated)`. (Open Question A1: the `invoice.paid` belt-and-suspenders wiring is optional — the per-step cancel-guard backstops it; plan recovery-cancel on the `subscription.updated → active` path as primary.)

**3. D-15 REPLACE gate** — gate `do_dispatch_invoice/3` for the `:invoice_payment_failed` type at the `maybe_dispatch_invoice_email("payment_failed", ...)` clause (`default_handler.ex:1466-1468`):
```elixir
defp maybe_dispatch_invoice_email("payment_failed", {:ok, %Invoice{} = invoice}, obj) do
  do_dispatch_invoice(:invoice_payment_failed, invoice, obj)
end
```
Add the enabled-gate: when `Accrue.Config.dunning_campaign_enabled?/0` is true, SKIP the standalone dispatch (campaign step-1 owns day-0) → return `:ok`; when false, fall through to the existing `do_dispatch_invoice` (now deduped by D-13/D-14). Read inline or via a small helper (Claude's discretion per D-15). The `do_dispatch_invoice/3` def itself (:1472-1487) is UNCHANGED.

---

### `lib/accrue/mailer/default.ex` — D-13

**Self-precedent:** `deliver/2` (`mailer/default.ex:33-39`):
```elixir
@impl true
def deliver(type, assigns) when is_atom(type) and is_map(assigns) do
  scalar_assigns = only_scalars!(assigns)
  %{type: Atom.to_string(type), assigns: stringify_keys(scalar_assigns)}
  |> Accrue.Workers.Mailer.new()
  |> Oban.insert()
end
```
Add a derived `unique` to the `.new/1` call, mapping ONLY `:invoice_payment_failed` via a new `dedup_unique/2` (D-13):
```elixir
%{type: Atom.to_string(type), assigns: stringify_keys(scalar_assigns)}
|> Accrue.Workers.Mailer.new(unique: dedup_unique(type, assigns))
|> Oban.insert()

defp dedup_unique(:invoice_payment_failed, %{invoice_id: id}) when is_binary(id) and id != "",
  do: [fields: [:worker, :args], keys: [:type, :invoice_id], period: :infinity,
       states: [:available, :scheduled, :executing, :retryable, :completed]]
defp dedup_unique(_type, _assigns), do: false
```
`only_scalars!/1` (:48-79) + `stringify_keys/1` (:81-88) are UNCHANGED. (`Oban.Worker.new/2` accepts `unique: false` as a no-op — every non-`:invoice_payment_failed` type is unaffected, no regression.)

---

### `lib/accrue/workers/mailer.ex` — D-14, D-02

**Self-precedents (all in this file):**

**1. `idempotency_key/2` clause** — clone the `:payment_succeeded` clause (`mailer.ex:306-312`) and insert BEFORE the catch-all at :314:
```elixir
defp idempotency_key(:payment_succeeded, assigns) do
  case assigns[:invoice_number] || assigns["invoice_number"] do
    nil -> {:error, :missing_invoice_number}
    "" -> {:error, :missing_invoice_number}
    invoice_number -> "accrue:v1:payment_succeeded:#{invoice_number}"
  end
end
defp idempotency_key(_type, _assigns), do: {:error, :unsupported_type}   # catch-all :314
```
Add (D-14 — key on `invoice_id`, NOT `invoice_number` which is nullable/dropped by `drop_nils`):
```elixir
defp idempotency_key(:invoice_payment_failed, assigns) do
  case assigns[:invoice_id] || assigns["invoice_id"] do
    nil -> {:error, :missing_invoice_id}
    "" -> {:error, :missing_invoice_id}
    invoice_id -> "accrue:v1:invoice_payment_failed:#{invoice_id}"
  end
end
```
(Optional D-17 step-email clauses `accrue:v1:dunning_step:<sub>:<step_key>:<started_at>` — planner's discretion — would clone the same dual-key + error shape.) NOTE: this clause only fires for types routed through `deliver_mailglass` (mailer.ex:105-121, which calls `idempotency_key/2` at :106). `:invoice_payment_failed` currently routes through `deliver_swoosh` (the `deliver_email/4` dispatch at :72-78 only sends `:receipt`/`:payment_failed` to Mailglass). The primary dedup for `:invoice_payment_failed` is the D-13 enqueue-`unique`; this `idempotency_key/2` clause is the documented backstop — plan whether to also route the type to the Mailglass lane or rely on the enqueue-unique alone.

**2. `default_template/1` atoms** (`mailer.ex:319-332`):
```elixir
defp default_template(:invoice_payment_failed), do: Accrue.Emails.InvoicePaymentFailed   # :325
...
defp default_template(:card_expiring_soon), do: Accrue.Emails.CardExpiringSoon            # :331
```
Add two new clauses (D-02):
```elixir
defp default_template(:dunning_action_required), do: Accrue.Emails.DunningActionRequired
defp default_template(:dunning_final_notice), do: Accrue.Emails.DunningFinalNotice
```
Also add `Accrue.Emails.DunningActionRequired` + `Accrue.Emails.DunningFinalNotice` to the `@compile {:no_warn_undefined, [...]}` list (:34-49) so forward-references don't break `--warnings-as-errors` until the email modules land.

---

## Shared Patterns

### Oban `unique` (enqueue-time dedup) — D-13 + D-16
**Source:** `lib/accrue/billing/metered_renewal_actions.ex:307` (the keyword shape) + installed `deps/oban/lib/oban/job.ex:307` (verbatim example: `states = [:available, :scheduled, :executing, :retryable, :completed]`).
**Apply to:** `DunningStep` enqueue (keys `[:subscription_id, :step_key, :campaign_started_at]`) AND `Accrue.Mailer.Default.deliver/2` (keys `[:type, :invoice_id]`). BOTH use `period: :infinity` + `:completed` in states (NOT the `:60` in the metered precedent — Smart Retries span weeks). Disjoint keyspaces by construction.
```elixir
unique: [fields: [:worker, :args], keys: [...], period: :infinity,
         states: [:available, :scheduled, :executing, :retryable, :completed]]
```

### Oban-safe scalar args (ISO8601 datetimes) — D-10
**Source:** `lib/accrue/mailer/default.ex:48-79` (`only_scalars!/1`) + `lib/accrue/billing/metered_renewal_actions.ex:312` (`maybe_iso8601/1`).
**Apply to:** every `DunningStep` enqueue and every mailer assigns map — pass IDs + ISO8601 strings, never structs/`DateTime`s. `campaign_started_at` threads through the chain as a string; parse back with `DateTime.from_iso8601/1` (never `String.to_atom`).

### Fake-deterministic clock — D-09, D-10
**Source:** `lib/accrue/clock.ex:24-30` + usage `lib/accrue/jobs/dunning_sweeper.ex:101`.
**Apply to:** every "now" in new code (`maybe_bump_past_due_since/2` elector, `DunningStep` worker, anchor stamping):
```elixir
now_usec = %{Accrue.Clock.utc_now() | microsecond: {0, 6}}
```
NEVER `DateTime.utc_now/0` in Accrue code — breaks Phase 130's Fake-lane clock-advance proof. (The pure `Accrue.Dunning.Campaign` is the exception: it takes `now` as an argument, stays clock-free.)

### `force_status_changeset` + `optimistic_lock` boundary — D-08, D-09, D-12
**Source:** `lib/accrue/billing/subscription.ex:106-113`.
**Apply to:** the recovery-CLEAR path (D-12) casts `dunning_campaign_started_at` through `force_status_changeset/2` (it's in `@cast_fields`). The START path (D-09) MUST be a sibling `Repo.update_all` so it doesn't contend with `optimistic_lock(:lock_version)` (RESEARCH Anti-Pattern — never stamp the anchor on the same changeset as a status flip).

### `{:cancel, reason}` worker self-cancel — D-11
**Source:** `lib/accrue/workers/mailer.ex:107` (`{:cancel, reason}`) + :65 (`{:cancel, :missing_recipient}`).
**Apply to:** `DunningStep.perform/1` step (1) returns `{:cancel, :recovered}` on a recovered/nil-anchor reload — non-retryable, sends nothing.

### `Accrue.ConfigError` raise-on-boot — D-06
**Source:** `lib/accrue/config.ex:984` (`raise Accrue.ConfigError, key:, message:`), exception def `lib/accrue/errors.ex:112` (`defexception [:message, :key, :diagnostic]`).
**Apply to:** `validate_dunning_campaign_grace!/1` cross-field boot validator.

### Webhook test scaffolding — DUN-02, DUN-05 tests
**Source:** `test/accrue/webhook/dunning_exhaustion_test.exs:18-69` (`use Accrue.BillingCase, async: false`; seed customer + `past_due` sub via `force_status_changeset`; `Fake.stub(:retrieve_invoice/...)`).
**Apply to:** both new webhook integration tests. Drive the REAL `DefaultHandler` entry (Pitfall 1), pair with Oban.Testing (`testing: :manual` from test_helper.exs:51-56; copy the `use Oban.Testing, repo: Accrue.TestRepo` line from `test/accrue/mailer_test.exs`).

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/accrue/dunning/campaign.ex` (next-step math) | service (pure) | transform | No existing module resolves "next step + delay from an ordered offset list." The CONVENTION analog `lib/accrue/billing/dunning.ex` (pure-policy, `cond`, `nil`-tolerant boundary helpers) gives the SHAPE; the next-step/`schedule_in` arithmetic is net-new. Property-test it against `connect_platform_fee_property_test.exs` structure. |

(All other 16 files have a concrete clone target — this is a clone-heavy phase as flagged.)

## Metadata

**Analog search scope:** `accrue/lib/accrue/{dunning,billing,workers,jobs,emails,mailer,webhook}/`, `accrue/priv/repo/migrations/`, `accrue/test/{property,accrue/webhook,accrue/workers}/`, `accrue/lib/accrue/{config,clock,errors}.ex`, `accrue_portal/lib/accrue_portal/live/`.
**Files scanned:** ~22 (12 read in full, anchors verified by grep across config/subscription/default_handler).
**Pattern extraction date:** 2026-05-24
**Anchor verification:** every line number re-checked against live source this session; drift table in header.
