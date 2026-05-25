---
phase: 130-provider-honesty-fake-lane-proof-example-host-wiring
reviewed: 2026-05-25T00:00:00Z
depth: standard
files_reviewed: 12
files_reviewed_list:
  - accrue/guides/dunning.md
  - accrue/lib/accrue/processor/braintree.ex
  - accrue/lib/accrue/processor/capabilities.ex
  - accrue/lib/accrue/processor/fake.ex
  - accrue/lib/accrue/processor/stripe.ex
  - accrue/test/accrue/dunning/dunning_full_journey_test.exs
  - examples/accrue_host/config/config.exs
  - examples/accrue_host/config/test.exs
  - examples/accrue_host/priv/repo/migrations/20260525120000_add_dunning_campaign_started_at_to_subscriptions.exs
  - examples/accrue_host/test/accrue_host/dunning_wiring_test.exs
  - scripts/ci/verify_adoption_proof_matrix.sh
  - scripts/ci/verify_processor_support_matrix.sh
findings:
  critical: 2
  warning: 4
  info: 3
  total: 9
status: issues_found
---

# Phase 130: Code Review Report

**Reviewed:** 2026-05-25
**Depth:** standard
**Files Reviewed:** 12
**Status:** issues_found

## Summary

Phase 130 delivers provider-honest capability declarations across three processor adapters, the
dunning guide, a Fake-lane full-journey test, example-host Oban queue wiring, and two CI
shift-left scripts. The convergence/divergence taxonomy in `capabilities.ex` is internally
consistent and well-documented. The migration is minimal and correct. The test structure follows
established project patterns and `async: false` is correctly applied.

Two blockers were found. The most significant is that `Fake.capabilities/0` reports
`smart_retry_alignment: true`, which is the same boolean value as the Stripe adapter and implies
the Fake has an adaptive payment-retry overlay — the opposite of the documented "testing/local-only"
label. The second blocker is a struct dot-access crash in `Braintree.translate_customer_payment_methods/1`
that will raise `KeyError` at runtime when Braintree cards are plain maps rather than Braintree
library structs. Four warnings address floating-point money arithmetic, a missing `translate_resource`
clause in the Stripe adapter, a hardcoded webhook secret in test config, and non-unique telemetry
handler names in the journey test. Three info items flag a duplicate prefix on the Fake, a
tagline imprecision in the dunning guide, and a script inconsistency between the two CI verifiers.

---

## Critical Issues

### CR-01: `Fake.capabilities/0` reports `smart_retry_alignment: true` — misrepresents the Fake as having adaptive retries

**File:** `accrue/lib/accrue/processor/fake.ex:240`

**Issue:** `Fake.capabilities/0` returns:

```elixir
dunning: %{campaign: true, smart_retry_alignment: true}
```

The Fake has no adaptive payment-retry overlay. Its documented role for the `smart_retry_alignment`
row is `"testing/local-only"` (the Fake is the proof lane for campaign step sequencing, not smart
retries). However `true` as a raw boolean capability value means any caller using
`Capabilities.supports?(fake_caps, [:dunning, :smart_retry_alignment])` returns `true`, implying
the Fake implements native Smart Retries.

Cross-adapter comparison shows the error clearly:

- `Braintree.capabilities/0` line 44: `dunning: %{campaign: true, smart_retry_alignment: false}` — correct (Braintree has no smart retries)
- `Stripe.capabilities/0` line 99: `dunning: %{campaign: true, smart_retry_alignment: true}` — correct (Stripe genuinely has Smart Retries)
- `Fake.capabilities/0` line 240: `dunning: %{campaign: true, smart_retry_alignment: true}` — wrong (same value as Stripe despite having no adaptive retries)

The label mirror test in `dunning_full_journey_test.exs` at line 248 tests
`Capabilities.provider_support_label(:fake, [:dunning, :smart_retry_alignment])` which reads
directly from the `@provider_support_labels` module attribute — it passes regardless of this bug.
The capability boolean is what `Capabilities.supports?/2` and `Capabilities.first_party_supported?/2`
operate on, so any future consumer checking whether the Fake supports smart_retry_alignment
receives an incorrect affirmative.

**Fix:**
```elixir
# fake.ex line 240
dunning: %{campaign: true, smart_retry_alignment: false}
```

---

### CR-02: Dot-access crash in `Braintree.translate_customer_payment_methods/1` when cards are plain maps

**File:** `accrue/lib/accrue/processor/braintree.ex:877`

**Issue:** Line 877 accesses `card.default` and `card.token` using Elixir struct dot-notation:

```elixir
|> Map.put(:default, card.default || card.token == default_token)
```

Dot-notation access on a plain map raises `KeyError` at runtime. The `cards` list comes from
`Map.get(customer, :credit_cards) || Map.get(customer, :payment_methods) || []` (lines 869-872).
When cards arrive as plain maps (e.g., from a custom gateway implementation, partial fixture, or
future SDK version that returns maps instead of structs), this line crashes. The exception is not
caught — `list_payment_methods/2` returns `{:error, …}` only when the gateway call fails; this
crash propagates uncaught and is not translated to an `Accrue.APIError`.

The inconsistency is internal: `translate_payment_method/1` at line 897 uses `Map.get/2`
throughout, which is safe for both structs and maps. Line 877 accesses the raw card *before*
calling `translate_payment_method/1`, using the unsafe dot form. The correct pattern is to use
`Map.get` for both the `:default` and `:token` fields:

**Fix:**
```elixir
# braintree.ex lines 873-879 — replace dot-access with Map.get
cards
|> Enum.map(fn card ->
  raw_default = Map.get(card, :default) || Map.get(card, "default") || false
  token = Map.get(card, :token) || Map.get(card, "token")
  card
  |> translate_payment_method()
  |> Map.put(:default, raw_default || token == default_token)
end)
```

---

## Warnings

### WR-01: Floating-point arithmetic for Braintree money amounts introduces precision risk

**File:** `accrue/lib/accrue/processor/braintree.ex:312` and `916-917`

**Issue:** Both `create_refund/2` (line 312) and `money_string/1` (lines 916-917) convert
minor-unit integer amounts to decimal strings via IEEE 754 float division:

```elixir
# line 312 — inline in create_refund
a when is_integer(a) -> :erlang.float_to_binary(a / 100.0, [{:decimals, 2}])

# lines 916-917 — money_string/1
defp money_string(amount_minor) when is_integer(amount_minor) do
  :erlang.float_to_binary(amount_minor / 100.0, [{:decimals, 2}])
end
```

The same adapter already contains `minor_to_decimal_string/1` (lines 527-532) that uses
`div/2` and `rem/2` — exact integer arithmetic that cannot lose precision. CLAUDE.md explicitly
states: "Pin `:decimal` explicitly — money math correctness depends on it." Two competing
implementations for the same operation create a correctness hazard: a developer who adds a new
call site may use the float variant without realizing the safe variant already exists.

**Fix:** Replace both float-path callers with the integer approach already in `minor_to_decimal_string/1`,
or consolidate to a single `money_string/1` using integer arithmetic:

```elixir
defp money_string(amount_minor) when is_integer(amount_minor) and amount_minor >= 0 do
  dollars = div(amount_minor, 100)
  cents = amount_minor |> rem(100) |> Integer.to_string() |> String.pad_leading(2, "0")
  "#{dollars}.#{cents}"
end
```

---

### WR-02: `Stripe.translate_resource/1` has no clause for `{:ok, plain_map}` — FunctionClauseError on non-struct responses

**File:** `accrue/lib/accrue/processor/stripe.ex:911-912`

**Issue:** `translate_resource/1` only matches a struct in the ok branch:

```elixir
defp translate_resource({:ok, %_{} = result}), do: {:ok, Map.from_struct(result)}
defp translate_resource({:error, raw}), do: {:error, ErrorMapper.to_accrue_error(raw)}
```

If `LatticeStripe` ever returns `{:ok, %{}}` (a plain map — possible for list endpoints,
delete-confirmation responses, or a future minor version change in the library), this function
raises `FunctionClauseError` at the call site rather than propagating a structured error. Every
public callback in `stripe.ex` pipes through `translate_resource/1`, so a non-struct ok response
from any LatticeStripe module would be an unhandled exception rather than a graceful `{:error, …}`.

**Fix:** Add a plain-map passthrough clause between the struct clause and the error clause:

```elixir
defp translate_resource({:ok, %_{} = result}), do: {:ok, Map.from_struct(result)}
defp translate_resource({:ok, result}) when is_map(result), do: {:ok, result}
defp translate_resource({:error, raw}), do: {:error, ErrorMapper.to_accrue_error(raw)}
```

---

### WR-03: Hardcoded webhook signing secret in test config mismodels the correct runtime pattern

**File:** `examples/accrue_host/config/test.exs:26`

**Issue:**

```elixir
webhook_signing_secrets: %{stripe: "whsec_test_host"},
```

CLAUDE.md security requirements state: "Webhook signature verification mandatory and
non-bypassable." Hardcoding a webhook signing secret in a checked-in test config — even a
placeholder — establishes a visual pattern that a host developer may replicate in
`config/runtime.exs`, inadvertently bypassing the security requirement by using a static value
instead of `System.fetch_env!/1`. The example app is the primary reference for how hosts should
wire Accrue; the config files it ships should model correct patterns even for test-only values.

**Fix:** Add a comment that explicitly marks this as a test placeholder and shows the correct
production pattern:

```elixir
# test.exs — PLACEHOLDER ONLY. Production must use:
#   webhook_signing_secrets: %{stripe: System.fetch_env!("STRIPE_WEBHOOK_SECRET")}
webhook_signing_secrets: %{stripe: "whsec_test_host"},
```

---

### WR-04: Telemetry handler names in `dunning_full_journey_test.exs` are static strings — duplicate-attach risk across retries or parallel CI

**File:** `accrue/test/accrue/dunning/dunning_full_journey_test.exs:268-269`, `312`, `327`

**Issue:** Handler names like `"journey-campaign-started"`, `"journey-step-sent-day0"`,
`"journey-step-sent-day5"`, `"journey-step-sent-day12"` are static string literals. When
`telemetry.attach/4` is called with a name that is already registered, it returns
`{:error, :already_exists}`. The `attach_telemetry/2` helper asserts `:ok =` at line 204, so
a duplicate name raises `MatchError` with a misleading message. This can happen if:

1. The test process crashes mid-run without executing `on_exit` cleanup.
2. A CI retry re-runs the test in the same beam (e.g., `--max-failures 1` with re-run).

The test module uses `async: false`, which prevents intra-file concurrency, but the static names
are still risky across retries because telemetry handler registrations are global and persist
process lifetime.

**Fix:** Make handler names unique per invocation:

```elixir
defp attach_telemetry(name, event) do
  unique_name = "#{name}-#{System.unique_integer([:positive])}"
  test_pid = self()
  :ok = :telemetry.attach(
    unique_name, event,
    fn evt, meas, meta, _ -> send(test_pid, {:telemetry, evt, meas, meta}) end,
    nil
  )
  ExUnit.Callbacks.on_exit(fn -> :telemetry.detach(unique_name) end)
end
```

---

## Info

### IN-01: `@setup_intent_prefix` and `@subscription_item_prefix` both resolve to `"si_fake_"` — identical prefix makes IDs ambiguous

**File:** `accrue/lib/accrue/processor/fake.ex:70,75`

**Issue:**

```elixir
@setup_intent_prefix   "si_fake_"        # line 70
@subscription_item_prefix "si_fake_"     # line 75
```

Both resource types share the prefix `"si_fake_"`. A setup intent with counter value 1 and a
subscription item with counter value 1 both produce `"si_fake_00001"`. They use separate counter
slots (`:setup_intent` and `:subscription_item`), but since these counters are not synchronized,
the IDs will collide in practice (counter slots reset independently on `reset/0`). The module
docstring at line 48 documents `si_fake_` only for setup intents, suggesting subscription items
were added later without updating the prefix.

**Fix:** Give subscription items a distinct prefix:

```elixir
@subscription_item_prefix "subi_fake_"
```

---

### IN-02: Dunning guide tagline says "two per-provider retry stories" but there are three

**File:** `accrue/guides/dunning.md:9`

**Issue:** The tagline reads:

> **Tagline:** one provider-independent email cadence, **two per-provider retry stories**,
> zero processor calls on the campaign step path.

There are three per-provider retry stories: Stripe (native Smart Retries), Braintree
(unsupported / clock-driven only), and Fake (testing/local-only). The "two" is likely a
holdover from before Braintree was added as a first-party adapter. The guide correctly documents
all three providers in the per-provider breakdown section — the tagline is inconsistent with the
body.

**Fix:**

```markdown
> **Tagline:** one provider-independent email cadence, three per-provider retry stories,
> zero processor calls on the campaign step path.
```

---

### IN-03: `verify_adoption_proof_matrix.sh` does not accept the `ROOT_DIR` override that `verify_processor_support_matrix.sh` does — sibling script inconsistency

**File:** `scripts/ci/verify_adoption_proof_matrix.sh:5` vs `scripts/ci/verify_processor_support_matrix.sh:5`

**Issue:** `verify_processor_support_matrix.sh` line 5:

```bash
repo_root="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
```

`verify_adoption_proof_matrix.sh` line 5:

```bash
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
```

If CI runs these scripts with a `ROOT_DIR` environment variable override (e.g., from a matrix
build in a non-standard working directory), `verify_adoption_proof_matrix.sh` silently ignores
it and uses the wrong root. The two scripts are structural siblings that should behave the same
way.

**Fix:**

```bash
# verify_adoption_proof_matrix.sh line 5
repo_root="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
```

---

_Reviewed: 2026-05-25_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
