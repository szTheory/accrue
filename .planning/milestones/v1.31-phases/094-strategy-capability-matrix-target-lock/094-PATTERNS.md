# Phase 94: Strategy + capability matrix + target lock - Pattern Map

**Mapped:** 2026-04-29
**Files analyzed:** 6 primary files + 3 conditional enforcement files
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/STRATEGY.md` | config | request-response | `.planning/STRATEGY.md` | exact |
| `.planning/processor-support-matrix.md` | config | transform | `examples/accrue_host/docs/adoption-proof-matrix.md` | role-match |
| `scripts/ci/verify_processor_support_matrix.sh` | utility | transform | `scripts/ci/verify_adoption_proof_matrix.sh` | exact |
| `accrue/test/accrue/docs/processor_support_matrix_test.exs` | test | request-response | `accrue/test/accrue/docs/organization_billing_org09_matrix_test.exs` | exact |
| `.github/workflows/ci.yml` | config | batch | `.github/workflows/ci.yml` | exact |
| `scripts/ci/verify_package_docs.sh` | utility | transform | `scripts/ci/verify_package_docs.sh` | exact |
| `accrue/test/accrue/docs/package_docs_verifier_test.exs` | test | request-response | `accrue/test/accrue/docs/package_docs_verifier_test.exs` | exact |
| `accrue/lib/accrue/processor/capabilities.ex` | utility | transform | `accrue/lib/accrue/processor/capabilities.ex` | exact |
| `accrue/lib/accrue/checkout/session.ex` | utility | request-response | `accrue/lib/accrue/checkout/session.ex` | exact |

## Pattern Assignments

### `.planning/STRATEGY.md` (config, request-response)

**Analog:** `.planning/STRATEGY.md`

**Strategic track structure** (`.planning/STRATEGY.md:3-18`):
```markdown
## Active Strategic Track

### PROC-08 — Official dual-provider core

**Status:** Active as of 2026-04-28
...
## Track Boundaries

- **In scope:** official second-processor work ...
- **Still out of scope:** **FIN-03** ...
- **Adopter posture:** Stripe remains the default first-user story ...
```

**Execution-shape pattern** (`.planning/STRATEGY.md:20-30`):
```markdown
## Execution Shape

### Phase 1 — `v1.31`

**Theme:** Boundary hardening + thin slice
**Goal:** Lock the capability model ...
```

**Decision-note tail** (`.planning/STRATEGY.md:38-42`):
```markdown
## Decision Notes

- The second processor should be **Stripe-like**, not merchant-of-record.
- The next milestone must ship runtime capability, not research alone.
```

Use this same shape for the new processor-support posture: top-level track statement, explicit boundaries, milestone shape, then short hard constraints.

---

### `.planning/processor-support-matrix.md` (config, transform)

**Analog:** `examples/accrue_host/docs/adoption-proof-matrix.md`

**Matrix intro + lane framing** (`examples/accrue_host/docs/adoption-proof-matrix.md:1-12`):
```markdown
# Adoption proof matrix (`examples/accrue_host`)

This matrix answers: **what is proven, where, and against what kind of “realism”?**

Accrue intentionally splits proof into a **deterministic Fake-first lane**
... and a **Stripe test-mode provider parity lane** ...

## Layering note (local proof vs merge-blocking CI)
```

**Tabular contract pattern** (`examples/accrue_host/docs/adoption-proof-matrix.md:14-26`):
```markdown
## Blocking: Fake-backed host + browser

| Concern | Proof | Where |
|--------|--------|--------|
| Billing **`Accrue.Billing.create_checkout_session/2`** facade + ... | ... | `accrue` package |
```

**Advisory-vs-blocking split** (`examples/accrue_host/docs/adoption-proof-matrix.md:47-63`):
```markdown
## Advisory: Stripe test mode (network)

| Concern | Proof | Where |
|--------|--------|--------|
| 3DS / proration / Connect shapes vs real Stripe | `:live_stripe` modules, `mix test.live` | ... |

Requires repository secrets; failures do not block merge (`continue-on-error: true`).
```

For Phase 94, copy the document pattern, but replace proof rows with capability rows. Keep semantic row names, explicit provider columns, and a separate support-label column.

---

### `scripts/ci/verify_processor_support_matrix.sh` (utility, transform)

**Analog:** `scripts/ci/verify_adoption_proof_matrix.sh`

**Script skeleton** (`scripts/ci/verify_adoption_proof_matrix.sh:1-20`):
```bash
#!/usr/bin/env bash
# Shift-left gate: ORG-09 literals in adoption-proof-matrix.md must stay aligned with docs + CI.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
matrix="${repo_root}/examples/accrue_host/docs/adoption-proof-matrix.md"

if [[ ! -f "${matrix}" ]]; then
  echo "verify_adoption_proof_matrix: missing ${matrix}" >&2
  exit 1
fi

require_substring() {
  local needle="$1"
  local label="$2"
  if ! grep -Fq "${needle}" "${matrix}"; then
    echo "verify_adoption_proof_matrix: matrix missing ${label} (expected substring: ${needle})" >&2
    exit 1
  fi
}
```

**Fixed-needle enforcement** (`scripts/ci/verify_adoption_proof_matrix.sh:22-49`):
```bash
require_substring "## Layering note (local proof vs merge-blocking CI)" "Layer B/C layering heading"
require_substring "**Layer B (local Fake-backed proof):**" "Layer B label"
...
require_substring 'linked `1.0.0` pair' "linked 1.0.0 pair proof needle"

echo "verify_adoption_proof_matrix: OK"
```

Copy this script almost verbatim for a processor-support matrix verifier. Change only the file path, the stderr prefix, and the required literals for capability rows, provider labels, Braintree target lock, and Fake/provider lane wording.

---

### `accrue/test/accrue/docs/processor_support_matrix_test.exs` (test, request-response)

**Primary analog:** `accrue/test/accrue/docs/organization_billing_org09_matrix_test.exs`

**Thin shell-out harness** (`accrue/test/accrue/docs/organization_billing_org09_matrix_test.exs:1-15`):
```elixir
defmodule Accrue.Docs.OrganizationBillingOrg09MatrixTest do
  @moduledoc false

  use ExUnit.Case, async: true

  defp repo_root, do: Path.expand("../../../..", __DIR__)

  test "ORG-09 adoption proof matrix script passes" do
    root = repo_root()
    script = Path.join(root, "scripts/ci/verify_adoption_proof_matrix.sh")
    assert File.exists?(script)

    assert {output, 0} = System.cmd("bash", [script], cd: root, stderr_to_stdout: true)
    assert output =~ "verify_adoption_proof_matrix: OK"
  end
end
```

**Richer drift-fixture variant if you extend existing verifier tests instead of adding a new file:** `accrue/test/accrue/docs/package_docs_verifier_test.exs:9-30,32-77`
```elixir
test "package docs verifier succeeds" do
  {output, status} = System.cmd("bash", [@script_path], stderr_to_stdout: true)
  ...
  assert output =~ "quickstart"
end

test "package docs verifier rejects missing canonical verification labels" do
  ...
  {output, status} =
    System.cmd("bash", [@script_path],
      stderr_to_stdout: true,
      env: [{"ROOT_DIR", tmp_dir}]
    )

  assert status != 0
  assert output =~ "[verify_package_docs]"
end
```

Recommendation: use the thin shell-out test for a new dedicated verifier file; use the package-docs fixture drift pattern only if Phase 94 folds needles into `verify_package_docs.sh`.

---

### `.github/workflows/ci.yml` (config, batch)

**Analog:** `.github/workflows/ci.yml`

**Stable job-id header + advisory lane wording** (`.github/workflows/ci.yml:3-10`):
```yaml
# Job id contract — stable YAML `jobs:` keys relied on by docs, `act`, and anchors:
# ...
# Advisory: `live-stripe` (Stripe test-mode parity) runs on `workflow_dispatch` and
# `schedule` only — not merge-blocking for PRs.
```

**Docs-contracts-shift-left wiring** (`.github/workflows/ci.yml:29-54`):
```yaml
jobs:
  docs-contracts-shift-left:
    name: Docs and bash contracts (shift-left)
    if: github.event_name != 'schedule'
    runs-on: ubuntu-24.04

    steps:
      - uses: actions/checkout@v6

      - name: verify_package_docs.sh
        run: bash scripts/ci/verify_package_docs.sh
      ...
      - name: Adoption proof matrix contract
        run: bash scripts/ci/verify_adoption_proof_matrix.sh
```

If Phase 94 adds a dedicated verifier script, wire it as another step in `docs-contracts-shift-left`. Keep the job id unchanged, and preserve the advisory-only live-provider wording.

---

### `scripts/ci/verify_package_docs.sh` (utility, transform)

**Analog:** `scripts/ci/verify_package_docs.sh`

**Shared helper pattern** (`scripts/ci/verify_package_docs.sh:5-27`):
```bash
ROOT_DIR=${ROOT_DIR:-$(
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
)}

fail() {
  echo "[verify_package_docs] package docs verification failed: $*" >&2
  exit 1
}

require_fixed() {
  local file=$1
  local needle=$2

  grep -Fq "$needle" "$file" || fail "$file is missing: $needle"
}
```

**Co-update discipline pattern** (`scripts/ci/verify_package_docs.sh:121-128`):
```bash
# Intentional overlap ... remains so release-gate does not depend on
# host-integration alone.
# D-07 audit: no removals; release-gate retains full host structural pins
```

**Fixed invariant inventory style** (`scripts/ci/verify_package_docs.sh:167-201`):
```bash
require_fixed "$ROOT_DIR/RELEASING.md" "Canonical local demo: Fake"
require_fixed "$ROOT_DIR/RELEASING.md" "Provider parity: Stripe test mode"
...
echo "package docs verified for accrue $accrue_version and accrue_admin $accrue_admin_version"
echo "fixed invariants checked: README.md, RELEASING.md, ..."
```

If the planner chooses to extend an existing verifier instead of creating `verify_processor_support_matrix.sh`, copy this helper style and summary-output convention exactly.

---

### `accrue/test/accrue/docs/package_docs_verifier_test.exs` (test, request-response)

**Analog:** `accrue/test/accrue/docs/package_docs_verifier_test.exs`

**Success-path script assertion** (`accrue/test/accrue/docs/package_docs_verifier_test.exs:9-30`):
```elixir
test "package docs verifier succeeds" do
  {output, status} = System.cmd("bash", [@script_path], stderr_to_stdout: true)
  ...
  assert output =~ "release-gate"
  assert output =~ "host-integration"
end
```

**Fixture-drift failure harness** (`accrue/test/accrue/docs/package_docs_verifier_test.exs:32-77`):
```elixir
tmp_dir =
  Path.join(System.tmp_dir!(), "accrue-docs-verifier-#{System.unique_integer([:positive])}")

File.rm_rf!(tmp_dir)
on_exit(fn -> File.rm_rf(tmp_dir) end)
...
{output, status} =
  System.cmd("bash", [@script_path],
    stderr_to_stdout: true,
    env: [{"ROOT_DIR", tmp_dir}]
  )

assert status != 0
assert output =~ "[verify_package_docs]"
```

Use this only if Phase 94 extends `verify_package_docs.sh`. It is overkill for a brand-new single-purpose verifier.

---

### `accrue/lib/accrue/processor/capabilities.ex` (utility, transform)

**Analog:** `accrue/lib/accrue/processor/capabilities.ex`

**Capability-map declaration** (`accrue/lib/accrue/processor/capabilities.ex:1-18`):
```elixir
defmodule Accrue.Processor.Capabilities do
  @moduledoc """
  Capability map for bounded processor slices.

  Accrue's processor behaviour is historically Stripe-shaped. This module
  lets first-party adapters declare the narrower subset they actually support
  ...
  """

  @legacy_default %{
    customer: %{create: true, retrieve: true, update: true},
```

**Support lookup + merge behavior** (`accrue/lib/accrue/processor/capabilities.ex:42-69`):
```elixir
@spec for(module()) :: map()
def for(adapter) when is_atom(adapter) do
  declared =
    cond do
      function_exported?(adapter, :capabilities, 0) -> adapter.capabilities()
      true -> %{}
    end

  deep_merge(@legacy_default, declared)
end

@spec supports?(map(), [atom()]) :: boolean()
def supports?(capabilities, path) when is_map(capabilities) and is_list(path) do
  case get_in(capabilities, path) do
    true -> true
    _ -> false
  end
end
```

Phase 94 should treat this file as the code-level counterpart of the written matrix. The matrix rows should stay semantic enough to map cleanly onto `supports?/2` paths.

---

### `accrue/lib/accrue/checkout/session.ex` (utility, request-response)

**Analog:** `accrue/lib/accrue/checkout/session.ex`

**Validate + capability-gate + delegate pattern** (`accrue/lib/accrue/checkout/session.ex:78-90`):
```elixir
@spec create(map() | keyword()) :: {:ok, t()} | {:error, term()}
def create(params) when is_list(params), do: create(Map.new(params))

def create(params) when is_map(params) do
  opts = NimbleOptions.validate!(Map.to_list(params), @create_schema)
  ensure_checkout_support!(:create)
  ensure_ui_mode_support!(opts[:ui_mode])
  {processor_params, request_opts} = build_processor_params(opts)

  case Processor.__impl__().checkout_session_create(processor_params, request_opts) do
    {:ok, processor_session} -> {:ok, from_processor(processor_session)}
    {:error, err} -> {:error, err}
  end
end
```

**Bang-wrapper error pattern** (`accrue/lib/accrue/checkout/session.ex:93-108`):
```elixir
def create!(params) do
  case create(params) do
    {:ok, session} -> session
    {:error, err} when is_exception(err) -> raise err
    {:error, other} -> raise "Accrue.Checkout.Session.create/1 failed: #{inspect(other)}"
  end
end
```

**Early unsupported-operation failure** (`accrue/lib/accrue/checkout/session.ex:181-209`):
```elixir
defp ensure_checkout_support!(:create) do
  unless Processor.supports?([:checkout, :create]) do
    raise Accrue.APIError,
      code: "processor_operation_unsupported",
      message: "#{Processor.name()} does not support checkout creation"
  end
end
```

This is the exact behavior precedent for Phase 94 wording: unsupported processor surfaces must fail clearly and early instead of implying parity.

## Shared Patterns

### Canonical Matrix + Verifier Pair

**Source:** `examples/accrue_host/docs/adoption-proof-matrix.md:1-12,14-26` and `scripts/ci/verify_adoption_proof_matrix.sh:13-49`

**Apply to:** `.planning/processor-support-matrix.md`, `scripts/ci/verify_processor_support_matrix.sh`

```markdown
This matrix answers: **what is proven, where, and against what kind of "realism"?**
...
| Concern | Proof | Where |
```

```bash
require_substring "..." "..."
```

The repo prefers one canonical truth doc plus one bash needle list, not support prose scattered across multiple files.

### Fake-First / Provider-Parity Lane Split

**Source:** `examples/accrue_host/docs/adoption-proof-matrix.md:5-12,47-54`, `guides/testing-live-stripe.md:7-24,119-136`, `accrue/guides/custom_processors.md:60-87`

**Apply to:** `.planning/STRATEGY.md`, `.planning/processor-support-matrix.md`, verifier copy

```markdown
Accrue intentionally splits proof into a **deterministic Fake-first lane**
... and a **Stripe test-mode provider parity lane** ...
```

```markdown
On pull requests, merge-blocking proof is job id `host-integration`;
`live-stripe` stays advisory (manual/cron only).
```

```markdown
`Accrue.Processor.Fake` remains the baseline for most host-app tests ...
```

Phase 94 strategy/docs should preserve this exact lane split: Fake is blocking truth, provider-backed runs are fidelity checks.

### Extension Point vs First-Party Support

**Source:** `accrue/guides/custom_processors.md:3-10,43-58`

**Apply to:** `.planning/STRATEGY.md`, `.planning/processor-support-matrix.md`

```markdown
Accrue ships with Stripe and the Fake Processor, but the processor boundary is
an explicit extension point.

Do not use a custom processor to fake undocumented parity with every Stripe
feature.
```

Keep `guides/custom_processors.md` as extension-point posture. Do not let it become the first-party support contract.

### Capability Naming + Early Failure

**Source:** `accrue/lib/accrue/processor/capabilities.ex:42-59` and `accrue/lib/accrue/checkout/session.ex:81-90,181-209`

**Apply to:** matrix row naming, future capability enforcement in Phase 95

```elixir
def supports?(capabilities, path) when is_map(capabilities) and is_list(path) do
  case get_in(capabilities, path) do
    true -> true
    _ -> false
  end
end
```

```elixir
raise Accrue.APIError,
  code: "processor_operation_unsupported",
  message: "#{Processor.name()} does not support ..."
```

Matrix rows should map cleanly to capability paths and to explicit unsupported-operation errors.

### ExUnit Shell-Out Contract Tests

**Source:** `accrue/test/accrue/docs/organization_billing_org09_matrix_test.exs:4-15` and `accrue/test/accrue/docs/package_docs_verifier_test.exs:32-77`

**Apply to:** `accrue/test/accrue/docs/processor_support_matrix_test.exs` or `package_docs_verifier_test.exs`

```elixir
assert {output, 0} = System.cmd("bash", [script], cd: root, stderr_to_stdout: true)
assert output =~ "..."
```

Use the small shell-out pattern by default. Add temp-dir drift fixtures only if the verifier grows enough behavior to justify it.

## No Analog Found

None. Every likely Phase 94 artifact has a close in-repo analog.

## Metadata

**Analog search scope:** `.planning/`, `scripts/ci/`, `accrue/lib/accrue/`, `accrue/test/accrue/docs/`, `examples/accrue_host/docs/`, `guides/`

**Files scanned:** 13

**Pattern extraction date:** 2026-04-29
