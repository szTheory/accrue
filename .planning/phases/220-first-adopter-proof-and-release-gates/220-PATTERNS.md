# Phase 220: First-adopter proof and release gates - Pattern Map

**Mapped:** 2026-08-04  
**Files analyzed:** 15 planned new or modified artifacts  
**Analogs found:** 15 / 15

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue/priv/entitlements/v1.59-reference-scenarios.json` | fixture | transform | `v1.59-offline-golden-vectors.json` | exact |
| `accrue/priv/entitlements/v1.59-public-contract.json` | fixture | transform | `v1.59-source-capabilities.json` | exact |
| `accrue/lib/accrue/entitlements/reference_scenarios.ex` | service | transform | `decision_cases.ex` | role-match |
| `accrue/lib/accrue/entitlements/reference_scenarios/markdown.ex` | generator | transform | `decision_cases/markdown.ex` | exact |
| `accrue/lib/accrue/entitlements/admin.ex` | service | request-response | `admin.ex` | exact (extend) |
| `accrue/test/accrue/entitlements/reference_scenarios_test.exs` | test | transform | `decision_cases_test.exs` | exact |
| `accrue/test/accrue/entitlements/admin_test.exs` | test | request-response | `admin_test.exs` | exact (extend) |
| `accrue/test/accrue/entitlements/reference_scenario_conformance_test.exs` | test | CRUD / transform | `apple_reconciliation_test.exs` | role-match |
| `accrue/test/accrue/entitlements/repair_drills_test.exs` | test | CRUD / event-driven | `apple_reconciliation_test.exs` | role-match |
| `examples/accrue_host/lib/accrue_host_web/live/entitlement_diagnostics_live.ex` | component | request-response | `subscription_live.ex` | role-match |
| `examples/accrue_host/test/accrue_host_web/live/entitlement_diagnostics_live_test.exs` | test | request-response | `org_billing_live_test.exs` | role-match |
| `examples/crosswake_tracer/Tests/AccrueOfflineClientTests/ReferenceScenarioTests.swift` | test | transform | `GoldenVectorTests.swift` | exact |
| `examples/accrue_host/docs/capability-limits-matrix.md` | documentation | transform | `adoption-proof-matrix.md` | role-match |
| `scripts/ci/verify_reference_scenario_contract.sh` | CI gate | batch | `verify_entitlement_source_matrix.sh` | exact |
| `accrue/guides/{entitlements,operator-runbooks,release-notes}.md` and `examples/accrue_host/docs/adoption-proof-matrix.md` | documentation | transform | existing same-named files | exact (extend) |

## Pattern Assignments

### Corpus, parser, and generated views

**Apply to:** both `priv/entitlements/v1.59-*.json` fixtures, `ReferenceScenarios`, its Markdown/export helper, and their ExUnit tests.

**Primary analog:** `accrue/lib/accrue/entitlements/decision_cases.ex`

**Closed vocabulary and typed shape** (lines 4-14, 32-74):

```elixir
@version "v1.59"
@rails [:stripe, :apple]
@environments [:production, :sandbox, :offline]

defmodule Expected do
  @enforce_keys [:disposition, :snapshot, :revision_delta, :eligibility,
                 :lease, :continuity, :repair, :reason]
  defstruct [:disposition, :snapshot, :revision_delta, :eligibility,
             :lease, :continuity, :repair, :reason, :atomic]
end
```

**Fail-closed validator** (lines 82-124):

```elixir
def valid?(%DecisionCase{} = value) do
  value.contract_version == @version and valid_id?(value.id) and
    valid_evidence?(value.evidence) and valid_prior?(value.prior) and
    valid_ordering?(value.ordering) and valid_expected?(value.expected)
end

def valid?(_), do: false
```

Copy this shape for stable scenario IDs, a closed evidence lane, frozen clock, ordered evidence/actions, expected bounded snapshot/revision/eligibility/offline/diagnostic fields, and required artifacts. Fixtures must declare expectations only; consumers invoke real contexts rather than calculate entitlement results.

**Fixture and generated-output drift test** (`accrue/test/accrue/entitlements/decision_cases_test.exs`, lines 7-22, 115-147):

```elixir
cases = DecisionCases.all()
ids = Enum.map(cases, & &1.id)
assert ids == Enum.sort(ids)
assert length(ids) == length(Enum.uniq(ids))
assert Enum.all?(cases, &(&1.contract_version == DecisionCases.version()))

assert :ok = Accrue.Entitlements.DecisionCases.Export.write(root)
assert :ok = Accrue.Entitlements.DecisionCases.Export.check(root)
```

Keep checked-in outputs deterministic and test their `--check` equivalent after intentional drift.

### Bounded multi-rail diagnostic and repair contexts

**Apply to:** `accrue/lib/accrue/entitlements/admin.ex`, its tests, and repair-drill/context tests.

**Primary analog:** `accrue/lib/accrue/entitlements/admin.ex`

**Imports and public read seam** (lines 37-65):

```elixir
alias Accrue.Entitlements.Resolver.LocalMap
alias Accrue.Entitlements.StripeSync

def diagnostic_for_customer(%Accrue.Billing.Customer{} = customer) do
  %{
    local: safe_local_diagnostic(customer),
    stripe_advisory: safe_stripe_advisory_diagnostic(customer)
  }
end
```

Extend this single seam with a canonical multi-rail projection. Do not create an Apple/offline raw-record explorer or return schemas.

**Contain failure while preserving independent safe data** (lines 68-83):

```elixir
defp safe_local_diagnostic(customer) do
  {resolved, unmapped_price_ids} = resolve_for_customer(customer)
  {:ok, %{resolved: resolved, unmapped_price_ids: unmapped_price_ids}}
rescue
  _ -> {:error, :unavailable}
end
```

**Normalize, never forward evidence** (lines 91-106, 146-167):

```elixir
with {:ok, keys} <- lookup_keys(summary.data) do
  advisory(state_for(summary), lookup_keys: keys, observed_at: observed_at)
else
  :error -> unavailable_advisory()
end
```

Expose only closed state, reason, next action, age/timestamp, and safe correlation. Tests must reject raw transaction/notification/proof data, tokens, PII, encrypted locators, provider payloads, Oban args/errors, exception text, and arbitrary metadata.

**Exact safe-map/degraded-state tests** (`accrue/test/accrue/entitlements/admin_test.exs`, lines 232-256, 351-410):

```elixir
assert %{local: {:ok, %{resolved: resolved, unmapped_price_ids: []}},
         stripe_advisory: advisory} = Admin.diagnostic_for_customer(customer)

assert %{local: {:ok, %{resolved: resolved}}, stripe_advisory: unavailable} =
         Admin.diagnostic_for_customer(customer)
assert unavailable == advisory(:unavailable)
```

Repair drills need real Repo transaction assertions for database-authoritative idempotency/audit and the post-action diagnostic/snapshot. Oban uniqueness is coalescing only, never the lock or authorization rule.

### Reference-host diagnostic / repair surface

**Apply to:** `EntitlementDiagnosticsLive` and its ConnTest/LiveView coverage.

**Primary analog:** `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex`

**Host-owned state and job-focused copy** (lines 1-33):

```elixir
defmodule AccrueHostWeb.SubscriptionLive do
  use AccrueHostWeb, :live_view
  alias AccrueHost.Billing

  @member_denial_copy "Billing is managed by workspace admins. You can review the current billing state, but you can't change it."

  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:page_title, "Workspace billing") |> load_state()}
  end
end
```

**Explicit confirm → authorized context call → safe branches** (lines 103-145):

```elixir
def handle_event("request_cancel", _params, socket) do
  if billing_locked?(socket.assigns.access_state),
    do: {:noreply, put_flash(socket, :error, access_message(socket.assigns.access_state))},
    else: {:noreply, assign(socket, :confirm_cancel, true)}
end

case Billing.cancel_active_organization(socket.assigns.current_scope, subscription,
       operation_id: operation_id(params, "cancel")) do
  {:ok, _updated_subscription} -> socket |> put_flash(:info, "...") |> load_state()
  {:error, :forbidden} -> put_flash(socket, :error, @member_denial_copy)
  {:error, _reason} -> put_flash(socket, :error, @error_copy)
end
```

The host owns authorization, actor identity, confirmation/dry run, routes, rendering, and focus restoration. Render semantic headings/tables and text-backed state/reason/next action; reasoned-disabled actions and post-mutation reloads are mandatory.

### Swift corpus consumer

**Apply to:** `examples/crosswake_tracer/Tests/AccrueOfflineClientTests/ReferenceScenarioTests.swift`.

**Analog:** `GoldenVectorTests.swift`

**Imports and deterministic assertions** (lines 1-6, 32-42):

```swift
import Testing
import Foundation
@testable import AccrueOfflineClient

let observations = try OfflineGoldenVectorVerifier.verifyFixture()
#expect(observations.map(\.id) == observations.map(\.id).sorted())
#expect(observations.allSatisfy { [.accept, .reject].contains($0.result) })
```

**Closed-schema mutation coverage** (lines 82-98):

```swift
for field in ["purpose", "schema_version", "protocol_version", "public_jwks"] {
  var candidate = try corpusObject(fixture.corpus)
  candidate[field] = "mutated"
  #expect(!(try validationError(encode(candidate), fixture: fixture)).isEmpty)
}
```

Consume only language-neutral fields the Swift client can verify. Tests must not alter or imply runtime feasibility: keep the tracer `feasibility_blocked` until bridge and physical-device evidence exists.

### Matrix, guides, and CI drift gate

**Apply to:** public-contract fixture, generated capability/limits matrix, adoption matrix, entitlement/runbook/release guides, and `verify_reference_scenario_contract.sh`.

**Primary analog:** `scripts/ci/verify_entitlement_source_matrix.sh`

**Strict gate shell and required-file guard** (lines 1-19):

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
fail() { echo "verify_entitlement_source_matrix: FAIL: $1" >&2; exit 1; }
for file in "$matrix" "$guide" "$fixture" "$registry"; do [ -f "$file" ] || fail "missing $file"; done
```

**Exact fixture-to-doc checks plus negative boundary** (lines 15-40):

```bash
for state in supported externally_managed host_owned deferred unavailable feasibility_blocked; do
  grep -Fq "$state" "$fixture" || fail "fixture missing state $state"
  grep -Fq "\`$state\`" "$matrix" || fail "matrix missing state $state"
done

if grep -Eq 'true|false' "$fixture"; then
  fail "fixture contains booleanized capability state"
fi
```

Gate literal support/limit/lane assertions and negative claims for lifecycle migration/refund/proration, raw diagnostic data, and inflated Crosswake runtime claims. Wire it into existing release/adoption checks rather than marking doc checks advisory.

**Proof-lane documentation convention** (`examples/accrue_host/docs/adoption-proof-matrix.md`, lines 12-24):

```markdown
**Layer B (local Fake-backed proof):** running `mix verify` or `mix verify.full`...

**Layer C (merge-blocking ...):** job `docs-contracts-shift-left` is the CI home...

**Advisory Stripe-native entitlement sync proof:** the merge-blocking proof is deterministic docs/isolation coverage, not a live Stripe run.
```

Use the same visible split for `deterministic_conformance`, `runtime_capability`, and `advisory_parity`. Generated material owns exact compatibility cells; hand-authored guides own walkthrough, App Review, privacy/security limits, incident procedure, and release explanation.

## Shared Patterns

### Closed contracts and privacy

**Sources:** `decision_cases.ex` lines 82-124; `admin.ex` lines 91-167  
**Apply to:** fixtures, diagnostic projection, generator, tests, host rendering, and public docs.

Use versioned IDs, allowlists, tagged unavailable states, and validation rejecting unknown/malformed values. Only safe normalized values cross diagnostic or fixture boundaries.

### Authority separation

**Sources:** `admin.ex` lines 17-19; `subscription_live.ex` lines 115-145  
**Apply to:** repair contexts and host UI.

Library functions return bounded domain data/actions; host code supplies authorization, actor, routes, rendering, and confirmation. Production contexts are the sole semantic reducer; fixtures are inputs/assertions.

### Deterministic, visible proof lanes

**Sources:** `adoption-proof-matrix.md` lines 12-24; `verify_entitlement_source_matrix.sh` lines 15-40  
**Apply to:** corpus, Swift tests, generated matrix, docs, and CI.

Only synthetic credential-free deterministic rows are merge-blocking. Runtime capability retains the blocked tracer status, while live/provider parity remains advisory.

## No Analog Found

None. Exact Phase 220 names and schema are new, but every role has a direct repository precedent.

## Metadata

**Analog search scope:** `accrue/lib/accrue/entitlements`, `accrue/test/accrue/entitlements`, `accrue/priv/entitlements`, `examples/accrue_host`, `examples/crosswake_tracer`, `scripts/ci`  
**Files scanned:** 40+ candidate fixtures, contexts, tests, Swift consumers, host modules, docs, and CI scripts  
**Pattern extraction date:** 2026-08-04
