# Phase 104: Connect Spike / Decision - Pattern Map

**Mapped:** 2026-05-02
**Files analyzed:** 9
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/processor-support-matrix.md` | config | transform | `.planning/processor-support-matrix.md` | exact |
| `accrue/guides/connect.md` | config | transform | `accrue/guides/connect.md` | exact |
| `accrue/lib/accrue/connect.ex` | service | request-response | `accrue/lib/accrue/connect.ex` | exact |
| `accrue/lib/accrue/processor/capabilities.ex` | utility | transform | `accrue/lib/accrue/processor/capabilities.ex` | exact |
| `accrue/lib/accrue/processor/braintree.ex` | service | request-response | `accrue/lib/accrue/processor/braintree.ex` | exact |
| `accrue/guides/custom_processors.md` | config | transform | `accrue/guides/custom_processors.md` | exact |
| `accrue/guides/operator-runbooks.md` | config | event-driven | `accrue/guides/operator-runbooks.md` | exact |
| `scripts/ci/verify_processor_support_matrix.sh` | utility | batch | `scripts/ci/verify_processor_support_matrix.sh` | exact |
| `accrue/test/accrue/docs/processor_support_matrix_test.exs` | test | batch | `accrue/test/accrue/docs/processor_support_matrix_test.exs` | exact |

## Pattern Assignments

### `.planning/processor-support-matrix.md` (config, transform)

**Analog:** `.planning/processor-support-matrix.md`

**Contract framing pattern** (lines 3-7):
```markdown
This matrix answers: **what does Accrue mean by official multi-processor support, and where does that promise stop?**

Phase 94 locks the contract before the runtime work is complete.

Accrue intentionally splits processor truth into a **deterministic Fake-first lane** and **provider-backed fidelity lanes**.
```

**Capability table pattern** (lines 29-50):
```markdown
### Capability contract

| Capability | Fake | Stripe | Braintree | Public label |
|------------|------|--------|-----------|--------------|
| subscription.direct_create | Required | Required | Required target | all first-party |
| checkout.hosted_handoff | Local proof helper | Supported | No | Stripe-only |
| billing_portal.hosted_self_serve | Local proof helper | Supported | No | Stripe-only |
```

**Boundary-list pattern** (lines 75-86, 99-106):
```markdown
## Explicit out-of-slice surfaces

- embedded checkout
- setup/payment intents
- refunds
- metering
- Connect

## Support-boundary rules

- Unsupported capabilities must **fail clearly and early**
- Accrue should avoid the **ActiveMerchant** trap of over-broad gateway sameness.
```

**Use in Phase 104:** If the spike ends in no-go, keep the matrix style identical and make the Braintree/Connect row loudly out-of-slice. If the spike ends in a narrow go, add provider-explicit wording here before touching runtime code.

---

### `accrue/guides/connect.md` (config, transform)

**Analog:** `accrue/guides/connect.md`

**Guide-intro pattern** (lines 1-14):
```markdown
# Accrue Connect - Marketplace Platforms Guide

Accrue's Connect surface (`Accrue.Connect`) gives Phoenix SaaS platforms
first-class support for Stripe Connect...

This guide walks through the full public API...
```

**Capability-explicit example pattern** (lines 66-107):
```elixir
{:ok, account} =
  Accrue.Connect.create_account(%{
    type: "standard",
    country: "US",
    email: "merchant@example.com"
  })

{:ok, %Accrue.Connect.AccountLink{} = link} =
  Accrue.Connect.create_account_link(account, ...)
```

**Honest semantics pattern** (lines 111-164):
```markdown
## Destination charges

A destination charge routes a single `charges.create` call through the
platform...

## Separate charges + transfers

Use a separate charge and transfer when you need more flexibility...
```

**Use in Phase 104:** Reuse this file's "name the exact semantic, then show the exact API" style. Do not describe Hyperwallet as if it inherits destination-charge, transfer, or login-link semantics unless the docs also name the exclusions right beside them.

---

### `accrue/lib/accrue/connect.ex` (service, request-response)

**Analog:** `accrue/lib/accrue/connect.ex`

**Imports/alias pattern** (lines 23-31):
```elixir
alias Accrue.Billing.Charge
alias Accrue.Connect.{Account, AccountLink, LoginLink, PlatformFee, Projection}
alias Accrue.Money
alias Accrue.Processor
alias Accrue.Repo

import Ecto.Query, only: [from: 2]
```

**Facade + validation pattern** (lines 132-165):
```elixir
@spec create_account(map() | keyword(), keyword()) ::
        {:ok, Account.t()} | {:error, term()}
def create_account(params, opts \\ [])

def create_account(params, opts) when is_map(params) and is_list(opts) do
  case validate_create_params(params) do
    {:ok, {stripe_params, req_opts, owner}} ->
      final_opts = Keyword.merge(req_opts, opts)

      case Processor.__impl__().create_account(stripe_params, final_opts) do
        {:ok, stripe} -> upsert_local(stripe, owner, :connect_account_created)
        {:error, err} -> {:error, err}
      end

    {:error, _} = err ->
      err
  end
end
```

**Bang/tuple split pattern** (lines 167-175):
```elixir
def create_account!(params, opts \\ []) do
  case create_account(params, opts) do
    {:ok, acct} -> acct
    {:error, err} when is_exception(err) -> raise err
    {:error, other} -> raise "Accrue.Connect.create_account/2 failed: #{inspect(other)}"
  end
end
```

**Use in Phase 104:** If the decision requires any `Accrue.Connect` public-surface wording change, mirror this module's current tuple-first facade and do not introduce a fake provider-neutral account model.

---

### `accrue/lib/accrue/processor/capabilities.ex` (utility, transform)

**Analog:** `accrue/lib/accrue/processor/capabilities.ex`

**Support-label SSOT pattern** (lines 11-52):
```elixir
@support_labels %{
  subscription: %{
    direct_create: "all first-party",
    cancel: "staged first-party target",
    pause: "out of slice",
    resume: "out of slice"
  },
  checkout: %{
    create: "first-party local portal",
    embedded: "out of slice"
  }
}
```

**Capability-lookup pattern** (lines 68-92):
```elixir
def supports?(capabilities, path) when is_map(capabilities) and is_list(path) do
  case get_in(capabilities, path) do
    true -> true
    _ -> false
  end
end

def first_party_supported?(capabilities, path)
    when is_map(capabilities) and is_list(path) do
  support_label(path) == "all first-party" and supports?(capabilities, path)
end
```

**Use in Phase 104:** Any future Braintree/Hyperwallet marketplace slice should first appear here as explicit labels. This is the repo's real "loud exclusion" vocabulary.

---

### `accrue/lib/accrue/processor/braintree.ex` (service, request-response)

**Analog:** `accrue/lib/accrue/processor/braintree.ex`

**Module/import pattern** (lines 1-12):
```elixir
defmodule Accrue.Processor.Braintree do
  @moduledoc """
  Production Braintree adapter for the gateway subscription core slice.
  """

  @behaviour Accrue.Processor

  alias Accrue.APIError
  alias Accrue.Billing.Customer
  alias Accrue.Checkout.LocalSession
  alias Accrue.Config
```

**Adapter capability map pattern** (lines 16-44):
```elixir
@impl Accrue.Processor
def capabilities do
  %{
    subscription: %{
      direct_create: true,
      cancel: true,
      fetch: true,
      lifecycle_webhook_projection: true,
      update: true,
      cancel_at_period_end: false,
      pause: false,
      resume: false
    }
  }
end
```

**Unsupported-path error pattern** (lines 972-989):
```elixir
defp ensure_local_portal_available do
  case Config.portal_base_url() do
    base when is_binary(base) and base != "" -> :ok
    _ -> {:error, unsupported_gateway_portal()}
  end
end

defp unsupported_gateway_portal do
  %APIError{
    code: :unsupported_by_gateway,
    http_status: 422,
    message:
      "Braintree does not support a hosted billing portal unless the local Accrue portal is mounted and configured. See guides/braintree-local-portal.md."
  }
end
```

**Use in Phase 104:** This is the runtime pattern to copy if the decision stays no-go or narrow-go: explicit `capabilities/0` truth plus typed unsupported errors that point operators at the right guide instead of implying parity.

---

### `accrue/guides/custom_processors.md` (config, transform)

**Analog:** `accrue/guides/custom_processors.md`

**Boundary wording pattern** (lines 3-17):
```markdown
Accrue ships with Stripe, Braintree ..., and the Fake Processor.

Stripe remains the default first-user path.

Custom adapters are also **outside first-party support** unless Accrue names
them in the official processor-support matrix.
```

**Extension-point example pattern** (lines 21-48):
```elixir
defmodule MyApp.Billing.AcmePay do
  @behaviour Accrue.Processor

  @impl Accrue.Processor
  def create_customer(params, opts), do: {:ok, %{id: "cus_custom_123", params: params, opts: opts}}
end
```

**Testing posture pattern** (lines 67-94):
```markdown
`Accrue.Processor.Fake` remains the baseline for most host-app tests...

Treat your custom processor tests as adapter-contract tests and keep the main
billing suite on the Fake unless the external processor itself is the thing
under test.
```

**Use in Phase 104:** If the decision artifact needs to say "not first-party support," copy this wording discipline. It already states the repo's extension-point vs support-promise boundary cleanly.

---

### `accrue/guides/operator-runbooks.md` (config, event-driven)

**Analog:** `accrue/guides/operator-runbooks.md`

**Operational-boundary pattern** (lines 3-5):
```markdown
Use this document for **ordered triage**...

**Library vs host:** Accrue ships workers and suggested queue names; **your host application configures and starts Oban**
```

**Queue table pattern** (lines 7-20):
```markdown
## Oban queue topology

| Queue (default name) | Worker module | Role / when to look | Typical symptoms | Safe first checks |
| `:accrue_webhooks` | `Accrue.Webhook.DispatchWorker` | Async webhook handler dispatch after ingest | ... |
```

**Procedural playbook pattern** (lines 31-38):
```markdown
## Mini-playbook: [:accrue, :ops, :webhook_dlq, :dead_lettered]

1. Confirm scope...
2. Inspect the `accrue_webhook_events` row...
3. Check **Oban**...
```

**Use in Phase 104:** If a narrow go is approved, operator prerequisites and webhook/admin setup should be documented in this same host-vs-library, ordered-triage style. Do not bury Hyperwallet enablement as an implementation footnote.

---

### `scripts/ci/verify_processor_support_matrix.sh` (utility, batch)

**Analog:** `scripts/ci/verify_processor_support_matrix.sh`

**Verifier skeleton pattern** (lines 1-20):
```bash
#!/usr/bin/env bash
set -euo pipefail

repo_root="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
matrix="${repo_root}/.planning/processor-support-matrix.md"

require_substring() {
  local needle="$1"
  local label="$2"
  if ! grep -Fq "${needle}" "${matrix}"; then
    echo "verify_processor_support_matrix: matrix missing ${label} ..." >&2
    exit 1
  fi
}
```

**Literal-needle pattern** (lines 22-44):
```bash
require_substring "checkout.hosted_handoff" "checkout hosted handoff row"
require_substring "billing_portal.hosted_self_serve" "billing portal self-serve row"
require_substring "Stripe-only" "stripe-only support label"
require_substring "out of slice" "out-of-slice support label"
require_substring "fail clearly and early" "early failure support rule"
```

**Use in Phase 104:** If the decision becomes a public contract, enforce it here with literal needles instead of relying on prose review.

---

### `accrue/test/accrue/docs/processor_support_matrix_test.exs` (test, batch)

**Analog:** `accrue/test/accrue/docs/processor_support_matrix_test.exs`

**Script-smoke-test pattern** (lines 1-15):
```elixir
defmodule Accrue.Docs.ProcessorSupportMatrixTest do
  use ExUnit.Case, async: true

  defp repo_root, do: Path.expand("../../../..", __DIR__)

  test "processor support matrix script passes" do
    root = repo_root()
    script = Path.join(root, "scripts/ci/verify_processor_support_matrix.sh")
    assert File.exists?(script)

    assert {output, 0} = System.cmd("bash", [script], cd: root, stderr_to_stdout: true)
    assert output =~ "verify_processor_support_matrix: OK"
  end
end
```

**Stronger docs-drift analog** (from `accrue/test/accrue/docs/package_docs_verifier_test.exs` lines 32-83):
```elixir
test "package docs verifier rejects processor support drift in custom processor guidance" do
  tmp_dir = Path.join(System.tmp_dir!(), "accrue-docs-verifier-...")
  copy_fixture!("accrue/guides/custom_processors.md", tmp_dir)

  drifted_custom_processors =
    tmp_dir
    |> Path.join("accrue/guides/custom_processors.md")
    |> File.read!()
    |> String.replace("outside first-party support", "inside first-party support")

  {output, status} =
    System.cmd("bash", [@script_path], stderr_to_stdout: true, env: [{"ROOT_DIR", tmp_dir}])

  assert status != 0
  assert output =~ "outside first-party support"
end
```

**Use in Phase 104:** Start with the existing smoke test if only the matrix changes. If Phase 104 adds a new public guide or README claim, copy the tmp-fixture drift test pattern from `PackageDocsVerifierTest`.

## Shared Patterns

### Capability-first public truth
**Sources:** `.planning/processor-support-matrix.md` lines 18-54; `accrue/lib/accrue/processor/capabilities.ex` lines 11-52

Apply to any Phase 104 public claim before runtime work:
```markdown
The public matrix names supported, staged, Stripe-only, and out-of-slice rows.
```

```elixir
@support_labels %{...}
def first_party_supported?(capabilities, path), do: ...
```

### Typed unsupported failure path
**Sources:** `accrue/lib/accrue/processor/braintree.ex` lines 972-989; `.planning/processor-support-matrix.md` lines 99-106

Apply to any rejected or narrow-go marketplace surface:
```elixir
{:error, %APIError{code: :unsupported_by_gateway, http_status: 422, message: "..."}}
```

```markdown
Unsupported capabilities must **fail clearly and early**...
```

### Docs as merge-blocking contract
**Sources:** `scripts/ci/verify_processor_support_matrix.sh` lines 1-46; `accrue/test/accrue/docs/processor_support_matrix_test.exs` lines 1-15; `accrue/test/accrue/docs/package_docs_verifier_test.exs` lines 32-83

Apply to final BT-09 decision artifacts:
```bash
require_substring "..." "..."
```

```elixir
assert {output, 0} = System.cmd("bash", [script], ...)
```

### Provider-honest guide writing
**Sources:** `accrue/guides/connect.md` lines 1-14, 66-164; `accrue/guides/custom_processors.md` lines 3-17

Apply to any Connect/Hyperwallet docs update:
```markdown
Name the provider, name the exact semantic, and place exclusions next to the claim.
```

### Host-vs-library operational separation
**Sources:** `accrue/guides/operator-runbooks.md` lines 3-20

Apply if the phase documents Hyperwallet prerequisites:
```markdown
Accrue documents the pattern; the host owns running queues, URLs, secrets, and operator workflows.
```

## No Analog Found

None. Every likely Phase 104 touchpoint already exists as an exact truth surface in the repo. If the planner chooses to create a brand-new Braintree/Hyperwallet decision guide instead of updating `accrue/guides/connect.md`, use `accrue/guides/connect.md` plus `accrue/guides/braintree-local-portal.md` as the nearest documentation analogs.

## Metadata

**Analog search scope:** `accrue/lib`, `accrue/guides`, `accrue/test/accrue/docs`, `accrue/test/accrue/processor`, `scripts/ci`, `.planning`
**Files scanned:** 15+ candidate files via `rg --files` / `rg -n`, with 9 primary analog surfaces read
**Pattern extraction date:** 2026-05-02
