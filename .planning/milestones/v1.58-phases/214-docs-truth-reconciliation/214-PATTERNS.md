# Phase 214: Docs & truth reconciliation - Pattern Map

**Mapped:** 2026-07-31
**Files analyzed:** 20
**Analogs found:** 20 / 20

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `CLAUDE.md` | doc | transform | `CLAUDE.md` stack + matrix rows | exact |
| `accrue/guides/jobs_to_be_done.md` | doc | transform | `accrue/guides/jobs_to_be_done.md` entitlements section | exact |
| `.planning/research/JTBD-FRONTIER.md` | doc | transform | `.planning/research/JTBD-FRONTIER.md` TL;DR + matrix row | exact |
| `.planning/processor-support-matrix.md` | doc | transform | `.planning/processor-support-matrix.md` entitlements rows | exact |
| `examples/accrue_host/docs/adoption-proof-matrix.md` | doc | transform | `examples/accrue_host/docs/adoption-proof-matrix.md` proof layering | exact |
| `.planning/ROADMAP.md` | doc | transform | `.planning/ROADMAP.md` Phase 214 success criteria | exact |
| `.planning/REQUIREMENTS.md` | doc | transform | `.planning/REQUIREMENTS.md` DOCS rows/status table | exact |
| `.planning/STATE.md` | doc | transform | `.planning/STATE.md` v1.58 phase summary | exact |
| `accrue/CHANGELOG.md` | doc | transform | `accrue/CHANGELOG.md` existing release headings | exact |
| `accrue_admin/CHANGELOG.md` | doc | transform | `accrue_admin/CHANGELOG.md` existing release headings | exact |
| `accrue_portal/CHANGELOG.md` | doc | transform | `accrue_portal/CHANGELOG.md` existing release headings | exact |
| `accrue/guides/release-notes.md` | doc | transform | `accrue/guides/release-notes.md` plain-language story | exact |
| `accrue/doc/release-notes.md` | generated doc | transform | `accrue/guides/release-notes.md` source guide | role-match |
| `accrue/lib/accrue/entitlements/stripe_sync.ex` | service | request-response | same file public `refresh/2` docs | exact |
| `accrue/lib/accrue/processor.ex` | service | request-response | same file optional callback + facade docs | exact |
| `accrue/lib/accrue/processor/fake.ex` | service | CRUD | same file test helper + GenServer state update | exact |
| `scripts/ci/verify_package_docs.sh` | test utility | batch | same file helper/assertion pattern | exact |
| `scripts/ci/verify_release_notes_contract.sh` | test utility | batch | same file release-note assertions | exact |
| `accrue/test/accrue/docs/package_docs_verifier_test.exs` | test | file-I/O | same file temp fixture red-path tests | exact |
| `accrue/test/accrue/docs/release_notes_contract_test.exs` | test | file-I/O | same file temp fixture red-path test | exact |

## Pattern Assignments

### Current Version Truth Docs (doc, transform)

**Applies to:** `CLAUDE.md`

**Analog:** `CLAUDE.md`

**Version row pattern** (lines 35-45):

```markdown
| `:lattice_stripe` | `~> 1.1` | Stripe API wrapper | Sibling lib, v1.1.0 shipped 2026-04-14 (Hex.pm). Full Billing ... Use `~> 1.1` to track 1.x patch/minor releases. `BillingPortal.Configuration` is deferred to lattice_stripe 1.2 ... |
```

Copy the existing table shape and update only the `:lattice_stripe` row to `~> 2.0` plus the shipped entitlement-surface/advisory-sync truth. Do not rewrite unrelated stack rows.

**Compatibility matrix pattern** (lines 79-90):

```markdown
## Version Compatibility Matrix
| Anchor Pin | Forces | Notes |
|------------|--------|-------|
| `lattice_stripe ~> 0.2` | `finch ~> 0.19`, `plug_crypto ~> 2.0` | Finch pulls in Mint/Mimir — ~4 transitive packages. Acceptable. |
```

Keep the table format; replace the stale `~> 0.2` cell with `lattice_stripe ~> 2.0` and notes that match Phase 212/213 current truth.

### JTBD Current Capability Docs (doc, transform)

**Applies to:** `accrue/guides/jobs_to_be_done.md`, `.planning/research/JTBD-FRONTIER.md`

**Analogs:** same files

**Public JTBD prose pattern** (`accrue/guides/jobs_to_be_done.md`, lines 378-388):

```markdown
**Core entitlements** ✅ **shipped** — first-party helpers to *gate features* on a
subscription. You get the fail-closed gate API (`has_active_plan?` / `entitled?`
/ `features_for` / `entitlement_quantity`), a `Accrue.Plug.RequireEntitlement`
controller plug plus `require_feature`/`require_plan` router macros, a
conditionally-compiled LiveView `on_mount` guard, and an admin entitlements view.
```

Keep the "core entitlements shipped" lead. Replace only the deferred Stripe-native sync sentence with shipped/observational/default-off/never-gate wording.

**Planning mirror pattern** (`.planning/research/JTBD-FRONTIER.md`, lines 21-23 and 85):

```markdown
The value curve has flattened, and the last user-flow gap is now closed: **6 of 6 shipped** ...
| Entitlements / plan-gating (`has_active_plan?`, plugs/guards) | ✅ | ... | v1.39. Local-identical across providers ... Optional Stripe-native sync deferred/off-by-default (Phase 127). |
```

Preserve current-feature matrix style and update the final status clause, not the historical entry at line 162 or archived evidence.

### Support And Proof Mirrors (doc, transform)

**Applies to:** `.planning/processor-support-matrix.md`, `examples/accrue_host/docs/adoption-proof-matrix.md`

**Analog:** `.planning/processor-support-matrix.md`

**Capability row/prose pattern** (lines 61-73):

```markdown
| entitlements.local_mapping | local-identical | local-identical | local-identical | all first-party |
| entitlements.stripe_native_sync | out of slice | native (advisory) | unsupported | Stripe-native advisory (observational) |

The `entitlements.local_mapping` row is the matrix's first **convergence** row ...
... advisory / observational only ... **never displaces the local-first resolution path** and **does NOT change `entitled?/2` or `has_active_plan?/2`**.
```

This is the strongest semantic analog for D-01. Copy its scoped authority language: local mapping is the convergence/gate row; Stripe-native sync is a separate advisory divergence row.

**Proof mirror pattern** (`examples/accrue_host/docs/adoption-proof-matrix.md`, lines 3-16):

```markdown
This matrix answers: **what is proven, where, and against what kind of “realism”?**
...
**Layer C (merge-blocking `docs-contracts-shift-left` + `host-integration`):** job `docs-contracts-shift-left` is the CI home for the support-contract bundle.
```

Use this structure when adding advisory-sync proof language: say what is proven, where it is proven, and which CI layer blocks merges.

### Active Planning Status Mirrors (doc, transform)

**Applies to:** `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`

**Analogs:** same files

**Roadmap criteria pattern** (`.planning/ROADMAP.md`, lines 218-228):

```markdown
### Phase 214: Docs & truth reconciliation
**Goal**: Every public and planning doc surface ...
**Success Criteria** (what must be TRUE):
  1. ...
```

Update active/current rows only. Phase 213's current status should reflect final passed verification rather than stale "gaps found" language.

**Requirements status pattern** (`.planning/REQUIREMENTS.md`, lines 44-46 and 83-93):

```markdown
- [ ] **DOCS-01**: ...
| SYNC-01 | Phase 213 — Stripe-native advisory entitlements sync (observational-only) | Gaps Found |
| DOCS-01 | Phase 214 — Docs & truth reconciliation | Pending |
```

Preserve requirement IDs and table shape. Correct current status mirrors, but do not rewrite completed phase artifacts or seed history.

**State summary pattern** (`.planning/STATE.md`, lines 44-54):

```markdown
| Phase | Name | Requirements | Status |
| 213 | Stripe-native advisory entitlements sync (observational-only) | SYNC-01, SYNC-02, SYNC-03, SYNC-04, SYNC-05 | Complete |
| 214 | Docs & truth reconciliation | DOCS-01, DOCS-02, DOCS-03 | Not started |
```

Use the concise status-table form. Keep guardrail prose scoped to active milestone truth.

### Changelogs (doc, transform)

**Applies to:** `accrue/CHANGELOG.md`, `accrue_admin/CHANGELOG.md`, `accrue_portal/CHANGELOG.md`

**Analogs:** same changelog files

**Core changelog pattern** (`accrue/CHANGELOG.md`, lines 1-19):

```markdown
# Changelog

## [1.4.0](https://github.com/szTheory/accrue/compare/accrue-v1.3.0...accrue-v1.4.0) (2026-06-01)

### Features
* **155-01:** add livemode omission fixture option ...
```

Insert a new `## Unreleased` block directly after `# Changelog`. Do not add `## [1.5.0]` or change package versions.

**Compatibility-only package pattern** (`accrue_admin/CHANGELOG.md`, lines 1-18; `accrue_portal/CHANGELOG.md`, lines 1-12):

```markdown
# Changelog

## [1.4.0](https://github.com/szTheory/accrue/compare/accrue_admin-v1.3.0...accrue_admin-v1.4.0) (2026-06-01)
```

For admin and portal, add only a short `## Unreleased` compatibility note. Do not claim a new workflow, API, or grant authority.

### Plain-Language Release Notes (doc, transform)

**Applies to:** `accrue/guides/release-notes.md`; conditionally generated `accrue/doc/release-notes.md`

**Analog:** `accrue/guides/release-notes.md`

**Story/link pattern** (lines 1-17):

```markdown
# Release notes (plain-language)

This page is the **story** of what shipped—not a commit list. For every line item and hash, see the package changelogs and GitHub releases:

- [`accrue/CHANGELOG.md`](https://github.com/szTheory/accrue/blob/main/accrue/CHANGELOG.md) — machine-precise history for the core library
- [`accrue_admin/CHANGELOG.md`](https://github.com/szTheory/accrue/blob/main/accrue_admin/CHANGELOG.md) — same for the admin UI package
- [GitHub releases](https://github.com/szTheory/accrue/releases) — tags and generated notes (more technical)
```

Add the missing portal changelog link beside the core/admin links. Add a next-release `1.5.0` story in this hand-authored guide. If `accrue/doc/release-notes.md` is tracked, regenerate it through the normal ExDoc build; do not hand-edit generated output.

### ExDoc Public API Metadata (service, request-response)

**Applies to:** `accrue/lib/accrue/entitlements/stripe_sync.ex`, `accrue/lib/accrue/processor.ex`, `accrue/lib/accrue/processor/fake.ex`

**Analog:** same source files

**Public refresh contract pattern** (`accrue/lib/accrue/entitlements/stripe_sync.ex`, lines 44-55):

```elixir
@doc """
Refreshes the observational entitlement-summary cache for one customer.

The refresh is disabled by default ...
"""
@doc since: "1.4.0"
@spec refresh(Customer.t(), keyword()) ::
        {:ok, EntitlementSummary.t() | :disabled | :unchanged | :stale} | {:error, term()}
def refresh(%Customer{} = customer, opts \\ []) when is_list(opts) do
```

Keep the `@doc` block, then `@doc since: ...`, then `@spec`, then `def`. Change this family to `since: "1.5.0"`.

**Optional callback contract pattern** (`accrue/lib/accrue/processor.ex`, lines 210-213):

```elixir
# ---------------------------------------------------------------------------
# Entitlements
# ---------------------------------------------------------------------------

@callback list_active_entitlements(id(), opts()) :: {:ok, [map()]} | {:error, Exception.t()}
```

Add `@doc since: "1.5.0"` immediately before this callback per D-10.

**Facade contract pattern** (`accrue/lib/accrue/processor.ex`, lines 378-386):

```elixir
@doc """
Lists a customer's active processor-native entitlements.

This is an optional advisory read callback used by
`Accrue.Entitlements.StripeSync.refresh/2`. It returns a complete
materialized list and is never part of the local grant path.
"""
@spec list_active_entitlements(id(), opts()) :: {:ok, [map()]} | {:error, Exception.t()}
def list_active_entitlements(id, opts \\ []) when is_binary(id) and is_list(opts) do
```

Add `@doc since: "1.5.0"` between the doc block and spec.

**Fake test-helper contract pattern** (`accrue/lib/accrue/processor/fake.ex`, lines 286-295):

```elixir
@doc """
Seeds active entitlements for a customer processor id.

Test helper for the advisory Stripe-native sync path.
"""
@spec put_entitlements(String.t(), [map()]) :: :ok
def put_entitlements(customer_id, entitlements)
    when is_binary(customer_id) and is_list(entitlements) do
  call({:put_entitlements, customer_id, entitlements})
end
```

Add `@doc since: "1.5.0"` here. Do not add since badges to `active_entitlement_list_metadata/0`, `summary_for_customer/1`, adapter internals, Reconcile writers, or worker callbacks.

**Fake state update pattern** (`accrue/lib/accrue/processor/fake.ex`, lines 983-985 and 1420-1423):

```elixir
def handle_call({:put_entitlements, customer_id, entitlements}, _from, state) do
  {:reply, :ok, %{state | entitlements: Map.put(state.entitlements, customer_id, entitlements)}}
end

def handle_call({:list_active_entitlements, id, opts}, _from, state) do
  with_script_or_stub(state, :list_active_entitlements, [id, opts], fn state ->
    {{:ok, Map.get(state.entitlements, id, [])}, state}
  end)
end
```

This is the existing deterministic test seam. Phase 214 should document it; no behavior changes are required.

### Package Docs Verifier (test utility, batch)

**Applies to:** `scripts/ci/verify_package_docs.sh`

**Analog:** same file

**Imports/setup/error pattern** (lines 1-12):

```bash
#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=${ROOT_DIR:-$(
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
)}

fail() {
  echo "[verify_package_docs] package docs verification failed: $*" >&2
  exit 1
}
```

Keep the prefix stable so ExUnit red-path assertions can match it.

**Assertion helper pattern** (lines 23-44):

```bash
require_fixed() {
  local file=$1
  local needle=$2

  grep -Fq -- "$needle" "$file" || fail "$file is missing: $needle"
}

require_regex() {
  local file=$1
  local pattern=$2

  grep -Eq -- "$pattern" "$file" || fail "$file does not match: $pattern"
}

require_absent_regex() {
  local file=$1
  local pattern=$2

  if grep -Eq -- "$pattern" "$file"; then
    fail "$file must not match: $pattern"
  fi
}
```

Use `require_fixed` for canonical positive tokens and `require_absent_regex` for stale pins/forbidden authority wording. Scope checks to current surfaces, not historical phase/archive/seed files.

**Grouped guard pattern** (lines 311-317):

```bash
for guide in \
  "$ROOT_DIR/accrue/guides/first_hour.md" \
  "$ROOT_DIR/accrue/guides/troubleshooting.md"; do
  require_fixed "$guide" 'config :accrue, :webhook_signing_secrets, %{'
  require_absent_regex "$guide" 'webhook_signing_secret([^s]|$)'
done
```

Use this loop form for repeated current-surface semantic checks across JTBD/support/adoption docs.

### Release Notes Verifier (test utility, batch)

**Applies to:** `scripts/ci/verify_release_notes_contract.sh`

**Analog:** same file

**Setup/version pattern** (lines 1-30):

```bash
#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=${ROOT_DIR:-$(
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
)}

fail() {
  echo "verify_release_notes_contract: $*" >&2
  exit 1
}
```

Preserve prefix and `ROOT_DIR` override.

**Section scanner pattern** (lines 32-57):

```bash
grep -Fq "# Release notes (plain-language)" "$notes" || fail "release-notes.md missing title"
grep -Fq "accrue_portal" "$notes" || fail "release-notes.md must mention accrue_portal version-family context"

section_has_version() {
  local start_heading=$1
  local stop_heading=$2

  awk -v start="$start_heading" -v stop="$stop_heading" -v version="$accrue_version" '
    $0 == start { in_section = 1; next }
    stop != "" && $0 == stop { in_section = 0 }
    in_section && $0 == "### " version { found = 1 }
    END { exit found ? 0 : 1 }
  ' "$notes"
}
```

For Phase 214, add checks for portal changelog link and next-release `1.5.0` story. Because D-08 forbids package version bumps on main, do not rely only on current `@version` when checking the next-release story.

### Docs Contract Tests (test, file-I/O)

**Applies to:** `accrue/test/accrue/docs/package_docs_verifier_test.exs`, `accrue/test/accrue/docs/release_notes_contract_test.exs`

**Analogs:** same test files

**Success shell-out pattern** (`package_docs_verifier_test.exs`, lines 7-18):

```elixir
@script_path "../scripts/ci/verify_package_docs.sh"

test "package docs verifier succeeds" do
  {output, status} = System.cmd("bash", [@script_path], stderr_to_stdout: true)
  accrue_version = extract_version!("accrue/mix.exs")

  assert status == 0
  assert output =~ "package docs verified for accrue #{accrue_version}"
end
```

Keep direct shell-out tests for the live repo.

**Red-path fixture pattern** (`package_docs_verifier_test.exs`, lines 32-60):

```elixir
tmp_dir =
  Path.join(System.tmp_dir!(), "accrue-docs-verifier-#{System.unique_integer([:positive])}")

File.rm_rf!(tmp_dir)
on_exit(fn -> File.rm_rf(tmp_dir) end)
seed_tmp_dir!(tmp_dir)

drifted_custom_processors =
  tmp_dir
  |> Path.join("accrue/guides/custom_processors.md")
  |> File.read!()
  |> String.replace("outside first-party support", "inside first-party support")

File.write!(Path.join(tmp_dir, "accrue/guides/custom_processors.md"), drifted_custom_processors)

{output, status} =
  System.cmd("bash", [@script_path],
    stderr_to_stdout: true,
    env: [{"ROOT_DIR", tmp_dir}]
  )

assert status != 0
assert output =~ "[verify_package_docs]"
```

Use this structure for negative guards: seed temp repo, mutate one current-surface fixture, run with `ROOT_DIR`, assert non-zero plus stable failure text.

**Release-notes fixture pattern** (`release_notes_contract_test.exs`, lines 14-49):

```elixir
File.mkdir_p!(Path.join(tmp_dir, "accrue/guides"))
File.mkdir_p!(Path.join(tmp_dir, "accrue_admin"))
File.mkdir_p!(Path.join(tmp_dir, "accrue_portal"))
File.mkdir_p!(Path.join(tmp_dir, "scripts/ci"))

copy_fixture!("accrue/mix.exs", tmp_dir)
copy_fixture!("accrue_admin/mix.exs", tmp_dir)
copy_fixture!("accrue_portal/mix.exs", tmp_dir)
copy_fixture!("accrue/guides/release-notes.md", tmp_dir)

{output, status} =
  System.cmd("bash", [@script_path],
    stderr_to_stdout: true,
    env: [{"ROOT_DIR", tmp_dir}]
  )

assert status != 0
assert output =~ "verify_release_notes_contract:"
```

Extend this with red paths for missing portal changelog link and missing `1.5.0` next-release story.

## Shared Patterns

### Canonical Authorization Wording

**Source:** `.planning/processor-support-matrix.md` lines 71-73; `accrue/lib/accrue/entitlements/stripe_sync.ex` lines 6-19
**Apply to:** all current public docs, support/adoption mirrors, release notes, and verifier needles

```markdown
Local plan-to-feature mapping behaves identically across Stripe, Braintree, and Fake ... with zero processor calls.
... advisory / observational only ... never displaces the local-first resolution path and does NOT change `entitled?/2` or `has_active_plan?/2`.
```

Required facts: local plan->feature map is the Accrue grant gate; Stripe-native sync is optional/default-off; it writes an advisory diagnostics/admin cache; it never changes `entitled?/2`, `has_active_plan?/2`, plugs, or LiveView guards.

### Scoped Current-Truth Sweep

**Source:** `214-CONTEXT.md` D-13..D-15; `.planning/ROADMAP.md` lines 225-228
**Apply to:** all grep/audit work

Current/public surfaces are edit targets. Completed phase plans, research, summaries, verifications, archived milestones, retrospectives, and fired seeds are dated evidence and should not be rewritten merely because they contain old pins or deferred wording.

### Existing CI Ownership

**Source:** `.github/workflows/ci.yml` lines 47-59 and 82-89
**Apply to:** verifier script changes

```yaml
- name: verify_package_docs.sh
  run: bash scripts/ci/verify_package_docs.sh
- name: Entitlement gate path stays advisory-cache-free (ENT-10 D-04)
  run: bash scripts/ci/verify_entitlement_sync_isolation.sh
- name: Release notes freshness contract
  run: bash scripts/ci/verify_release_notes_contract.sh
```

Extend existing scripts and tests. Do not create a new top-level truth verifier or CI lane.

### Release Please Boundary

**Source:** changelog files lines 1-3; `214-CONTEXT.md` D-08
**Apply to:** package changelogs, release notes, generated docs

Insert `## Unreleased` entries on main. Do not add numbered `1.5.0` changelog sections or bump package versions outside a Release Please PR.

### ExDoc Metadata Boundary

**Source:** `accrue/lib/accrue/entitlements/stripe_sync.ex` lines 44-55; `accrue/lib/accrue/processor.ex` lines 210-213 and 378-386; `accrue/lib/accrue/processor/fake.ex` lines 286-295
**Apply to:** D-10 public contracts only

Use `@doc since: "1.5.0"` immediately before the callback/function spec. Do not badge hidden/internal plumbing.

## No Analog Found

No implementation target lacks a local analog. The only special case is `accrue/doc/release-notes.md`, which is generated output: use `accrue/guides/release-notes.md` as the source analog and regenerate if the generated file is tracked.

## Metadata

**Analog search scope:** `CLAUDE.md`, `accrue/guides`, `.planning/{ROADMAP.md,REQUIREMENTS.md,STATE.md,research,processor-support-matrix.md}`, `examples/accrue_host/docs`, package changelogs, `accrue/lib/accrue`, `scripts/ci`, `accrue/test/accrue/docs`, `.github/workflows/ci.yml`
**Files scanned:** 220 listed source/script/doc paths plus targeted grep over phase-relevant files
**Pattern extraction date:** 2026-07-31
