# Phase 215: Research, contracts, and Crosswake feasibility - Pattern Map

**Mapped:** 2026-07-31
**Files analyzed:** 16 logical new/modified artifacts
**Analogs found:** 13 / 16

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/research/v1.59-AUTHORITY.md` | config/documentation | transform | `.planning/research/RESEARCH-INDEX.md` | role-match |
| `.planning/research/RESEARCH-INDEX.md` | config/documentation | transform | itself | exact modification |
| `.planning/research/v1.59-DECISION-TABLE.md` | documentation (generated view) | transform | `.planning/processor-support-matrix.md` | role-match |
| authority amendment/claim ledger (authority section or adjacent `v1.59-AMENDMENTS.md`) | documentation | transform | `.planning/processor-support-matrix.md` | partial |
| `.planning/entitlement-source-capability-matrix.md` | documentation/config | transform | `.planning/processor-support-matrix.md` | role-match |
| `accrue/lib/accrue/entitlements/decision_cases.ex` | model/utility | transform | `accrue/lib/accrue/processor/capabilities.ex` | role-match |
| `accrue/lib/accrue/entitlements/decision_cases/markdown.ex` | utility | transform | `accrue/lib/accrue/processor/capabilities.ex` | partial |
| `accrue/lib/mix/tasks/accrue.entitlements.decision_cases.ex` | utility/config | transform/file-I/O | `accrue/lib/mix/tasks/accrue.webhooks.prune.ex` | role-match |
| `accrue/priv/entitlements/v1.59-decision-cases.json` | config/fixture | file-I/O | generated source artifacts under `priv/` | partial |
| `accrue/lib/accrue/entitlements/source.ex` | behaviour/provider | request-response | `accrue/lib/accrue/processor.ex` | role-match |
| `accrue/lib/accrue/entitlements/source/outcome.ex` (or equivalent closed value object) | model | request-response | `accrue/lib/accrue/processor.ex` | partial |
| `accrue/test/accrue/entitlements/decision_cases_test.exs` | test | transform | `accrue/test/accrue/entitlements/local_map_test.exs` | role-match |
| entitlement-case property test under `accrue/test/property/` | test | transform | `accrue/test/property/entitlement_summary_monotonic_property_test.exs` | exact data-flow |
| `accrue/test/accrue/entitlements/source_test.exs` | test | request-response | `accrue/test/accrue/entitlements/provider_honesty_test.exs` | exact data-flow |
| `scripts/ci/verify_v159_authority.sh` and source-matrix drift verifier | config/test gate | file-I/O | `scripts/ci/verify_processor_support_matrix.sh` | exact |
| `examples/crosswake_tracer/` Swift package, vectors, report/runbook | client reference target | event-driven/file-I/O | none | none |

File names for decision-case helper modules and the Mix task remain planner discretion. The table preserves the locked responsibility split: data-only contract, derived Markdown/JSON, source registry, independent gates, and a host-owned tracer.

## Pattern Assignments

### `.planning/research/v1.59-AUTHORITY.md` and `RESEARCH-INDEX.md` (documentation, transform)

**Analog:** `.planning/research/RESEARCH-INDEX.md`

**Entry-point and reading-order pattern** (lines 31-38):

```markdown
1. Read `.planning/PROJECT.md` and `.planning/STRATEGY.md` for active scope and reopen posture.
2. Read the latest versioned bundle for the target domain; for v1.59, use the canonical bundle above.
3. Read durable architecture/decision artifacts and relevant prior milestone audit/requirements.
4. Use generic `STACK/FEATURES/ARCHITECTURE/PITFALLS/SUMMARY` only as historical context, then explicitly record any supersession.
```

Place `v1.59-AUTHORITY.md` as the first v1.59 bundle item and link it from the index; retain existing source files rather than rewriting their historical text. The authority file/ledger must explicitly order scope guards, accepted amendments, summary + decision contract, provenance, specialist research, then historical generic research.

### `v1.59-DECISION-TABLE.md`, authority ledger, and source-capability matrix (documentation/config, transform)

**Analog:** `.planning/processor-support-matrix.md`

**Maintainer-facing SSOT framing** (lines 3-9):

```markdown
This file is the canonical support SSOT for Accrue's official dual-provider track.
It records the finalized `gateway subscription core` contract and the
provider-honest boundaries that ship with it.

This is the maintainer-facing capability SSOT. Public docs intentionally mirror
only short, capability-explicit summaries and link back here for the full contract.
```

**Table and explicit-boundary pattern** (lines 31-65 and 135-144): use a stable, literal table header and rows, followed by clear prose defining exclusions and the early-failure rule. For Phase 215, use source operations and closed state vocabulary, not processor support columns; never merge this matrix into the gateway matrix.

**Existing source-specific structure to retain/extend** (`.planning/entitlement-source-capability-matrix.md`, lines 1-24):

```markdown
**Status:** v1.59 design contract; no runtime support is claimed until the owning phase verifies it.
**Separate SSOT:** `.planning/processor-support-matrix.md` remains authoritative for the shipped Fake/Stripe/Braintree gateway-control facade.

| Capability | Stripe | Apple | Host/Fake proof |
|---|---|---|---|
```

The ledger should use stable claim IDs and fields required by D-03, including a disposition and superseded locations. It is an authority-record view, not an ADR/RFC replacement.

### `accrue/lib/accrue/entitlements/decision_cases.ex` and renderer/exporter (model/utility, transform)

**Analog:** `accrue/lib/accrue/processor/capabilities.ex`

**Closed data declaration pattern** (lines 11-68):

```elixir
@support_labels %{
  customer: %{create: "all first-party", retrieve: "all first-party"},
  entitlements: %{
    local_mapping: "all first-party",
    stripe_native_sync: "Stripe-native advisory (observational)"
  }
}
```

**Total, fail-closed lookup pattern** (lines 178-197):

```elixir
def support_label(path) when is_list(path) do
  case get_in(@support_labels, path) do
    label when is_binary(label) -> label
    _ -> nil
  end
end
```

Declare versioned structs/types and an explicitly ordered `all/0` corpus, then make render/export functions pure consumers of that corpus. Do not add Repo calls, runtime reducer calls, or a public `Accrue.Entitlements` facade. The case schema carries IDs, version, rail/environment evidence, prior state, ordering, expected disposition/snapshot/revision/eligibility/lease/repair, and support reason.

### Mix task and JSON fixture corpus (utility/config, transform/file-I/O)

**Analog:** `accrue/lib/mix/tasks/accrue.webhooks.prune.ex`

**Task skeleton** (lines 1-29):

```elixir
defmodule Mix.Tasks.Accrue.Webhooks.Prune do
  use Mix.Task

  @shortdoc "Prunes expired Accrue webhook events"

  @impl Mix.Task
  def run(_argv) do
    Mix.Task.run("app.start")
    # parse arguments, run one bounded operation, print result
  end
end
```

Use this small `Mix.Task` shape, but keep the decision-case task deterministic and data-only: sort stable IDs, render the Markdown table, encode checked-in JSON vectors, and fail clearly on invalid args/write paths. Do not start the app unless an existing project convention makes it necessary; the renderer must not become runtime logic.

### `accrue/lib/accrue/entitlements/source.ex` and closed outcome object (behaviour/model, request-response)

**Analog:** `accrue/lib/accrue/processor.ex`

**Behaviour, typed result, and callback pattern** (lines 119-155):

```elixir
@type id :: String.t()
@type params :: map()
@type opts :: keyword()
@type result :: {:ok, map()} | {:error, Exception.t()}

@callback create_customer(params(), opts()) :: result()
@callback retrieve_customer(id(), opts()) :: result()
```

**Configured-adapter defensive dispatch pattern** (lines 387-403):

```elixir
if function_exported?(adapter, :list_active_entitlements, 2) do
  adapter.list_active_entitlements(id, opts)
else
  {:error, %Accrue.APIError{code: "unsupported_operation", http_status: 501, message: "..."}}
end
```

Apply the typed specs and clear unavailable result pattern, but do **not** copy `Accrue.Processor`'s global processor configuration or gateway facade. Source registry data is closed and configured independently; outcomes must model `:supported`, `:externally_managed`, `:host_owned`, `:deferred`, `:unavailable`, and `:feasibility_blocked`, with source/capability/guidance/next-action fields. Apple management returns successful `:externally_managed` guidance, never a Stripe operation.

### Source and decision-case ExUnit tests (tests, request-response/transform)

**Analog:** `accrue/test/accrue/entitlements/provider_honesty_test.exs`

**Isolation/negative-regression test pattern** (lines 72-125):

```elixir
describe "entitlement resolution is provider-independent local derivation (D-03)" do
  test "resolved maps are byte-identical across Fake/Stripe/Braintree, with zero processor calls" do
    # attach telemetry, execute each provider lane, compare results
    refute_received {:processor_called, _event}
  end
end
```

**Literal mirror assertion pattern** (lines 129-145): assert code labels and configured adapters agree with the published contract. Source tests should instead enumerate every source/capability pair, assert the closed outcomes and guidance keys, and include a red test that Apple management cannot invoke cancellation/dunning/retry/swap/proration/invoice/payment-method gateway calls.

**Fixture-based shell-gate test pattern:** `accrue/test/accrue/entitlements/entitlement_sync_isolation_guard_test.exs` lines 13-49 runs a clean temp fixture, injects a forbidden executable edge, then asserts a non-zero result and diagnostic token. Use this exact red/green style for source gateway-leakage and documentation drift gates.

### Permutation/ordering/property tests (test, transform)

**Analog:** `accrue/test/property/entitlement_summary_monotonic_property_test.exs`

**ExUnitProperties setup and generator** (lines 15-17, 51-67):

```elixir
use Accrue.BillingCase, async: false
use ExUnitProperties

defp snapshots_gen do
  gen all(count <- StreamData.integer(2..6)) do
    # build distinct, deterministic fixture inputs
  end
end
```

**Order-invariance property** (lines 69-101): generate fixtures, shuffle them, apply each input, then assert the known winner/invariant. Phase 215 properties should cover case ordering, duplicate delivery, out-of-order inputs, survivor sources, concurrency, and later transaction-boundary expectations without embedding a second reducer in the case renderer.

### Authority/source drift scripts and docs tests (test/config, file-I/O)

**Analog:** `scripts/ci/verify_processor_support_matrix.sh`

**Safe root and missing-file guard** (lines 1-17):

```bash
set -euo pipefail
repo_root="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

if [[ ! -f "${matrix}" ]]; then
  echo "verify_processor_support_matrix: missing ${matrix}" >&2
  exit 1
fi
```

**Required literal plus negative-drift pattern** (lines 19-25, 125-138): define `require_substring`, assert all required literals, then reject known stale/unsafe literals with an explicit failure message. `verify_v159_authority.sh` should require the manifest, precedence, claim/72-hour supersession, and watchlist fields. The source-matrix verifier should compare the closed runtime state/capability literals with the doc mirror and reject any Apple-to-processor leakage wording.

**Small documentation test pattern:** `accrue/test/accrue/docs/tax_rollout_docs_test.exs` lines 1-26 uses `ExUnit.Case, async: true`, a module attribute list of required phrases, `File.read!/1`, and `Enum.each/2`. Use it only for narrow, repository-local doc assertions; keep broad literal gates in scripts.

### `examples/crosswake_tracer/` (client reference target, event-driven/file-I/O)

**Analog:** none in this repository.

Create a self-contained, pinned Swift reference target with a narrow host-owned `AccrueOfflineClient` adapter, checked-in JSON/JWS vectors, unit tests, a machine-readable capability report, and a redacted physical-device runbook/evidence record. There is no existing Swift package, StoreKit, Secure Enclave, Keychain, or Crosswake code to copy. Treat the missing pinned Crosswake source/build interface as a first-class `feasibility_blocked` report—not an invented bridge or an Accrue runtime dependency.

## Shared Patterns

### Closed contracts and typed failure

**Sources:** `accrue/lib/accrue/processor/capabilities.ex` lines 156-206; `accrue/lib/accrue/processor.ex` lines 387-403.
**Apply to:** decision-case corpus and entitlement source registry.

Use explicit types/values, defensive lookup, and a typed unavailable result. Avoid boolean capability maps for source outcomes and avoid a loose public nested map.

### Provider/source separation and negative proof

**Sources:** `.planning/entitlement-source-capability-matrix.md` lines 1-24; `accrue/test/accrue/entitlements/provider_honesty_test.exs` lines 72-145.
**Apply to:** Source implementation, tests, matrix, and verifier.

Gateway controls remain under `Accrue.Processor`; entitlement sources observe/restore/reconcile/manage/supply evidence. Test that the non-overlap holds, rather than trusting documentation alone.

### Deterministic Fake-first and property proof

**Source:** `accrue/test/property/entitlement_summary_monotonic_property_test.exs` lines 51-101.
**Apply to:** decision cases, JSON vectors, ordering/duplicate/survivor scenarios.

Generate deterministic inputs, permute delivery, and assert a stable semantic outcome. Provider/device-backed proof is separate evidence, never a substitute for merge-blocking fixture coverage.

### Documentation drift gates

**Sources:** `scripts/ci/verify_processor_support_matrix.sh` lines 1-35 and 125-158; `accrue/test/accrue/docs/tax_rollout_docs_test.exs` lines 1-26.
**Apply to:** authority bundle/index, source matrix, and source contract literals.

Check both required current language and prohibited stale language. Use a script with a `ROOT_DIR` seam, then unit-test the gate against clean and intentionally-invalid fixtures.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `examples/crosswake_tracer/Package.swift`, Swift sources/tests, and device-evidence runbook | client reference target | event-driven/file-I/O | No Swift, iOS, Crosswake, StoreKit, Secure Enclave, Keychain, or native lifecycle target exists in the repository. |
| Crosswake transport adapter | client adapter | request-response/event-driven | The pinned Crosswake shell/core and documented bridge API are not available; implementation must stay blocked rather than infer an API. |

## Metadata

**Analog search scope:** `accrue/lib/accrue/{processor,entitlements}`, `accrue/lib/mix/tasks`, `accrue/test/{accrue/entitlements,accrue/docs,property}`, `.planning/{research,processor-support-matrix.md,entitlement-source-capability-matrix.md}`, and `scripts/ci`.
**Files scanned:** 15 focused analogs and supporting documentation artifacts.
**Pattern extraction date:** 2026-07-31
