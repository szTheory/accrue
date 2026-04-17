# Phase 17: Milestone Closure Cleanup - Pattern Map

**Mapped:** 2026-04-17
**Files analyzed:** 9
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/PROJECT.md` | config | request-response | `.planning/PROJECT.md` | exact |
| `.planning/ROADMAP.md` | config | request-response | `.planning/ROADMAP.md` | exact |
| `scripts/ci/accrue_host_seed_e2e.exs` | utility | file-I/O | `scripts/ci/accrue_host_seed_e2e.exs` | exact |
| `RELEASING.md` | config | request-response | `RELEASING.md` | exact |
| `guides/testing-live-stripe.md` | config | request-response | `guides/testing-live-stripe.md` | exact |
| `CONTRIBUTING.md` | config | request-response | `CONTRIBUTING.md` | exact |
| `accrue/test/accrue/docs/release_guidance_test.exs` | test | batch | `accrue/test/accrue/docs/release_guidance_test.exs` | exact |
| `accrue/test/accrue/docs/package_docs_verifier_test.exs` | test | batch | `accrue/test/accrue/docs/package_docs_verifier_test.exs` | exact |
| `scripts/ci/verify_package_docs.sh` | utility | batch | `scripts/ci/verify_package_docs.sh` | exact |

## Pattern Assignments

### `.planning/PROJECT.md` (config, request-response)

**Analog:** [`PROJECT.md:33`](/Users/jon/projects/accrue/.planning/PROJECT.md:33)

Use the existing milestone section and checkbox style in place. Phase 17 only needs a one-line bookkeeping parity update; do not restructure the milestone summary.

**Milestone goal + active requirements pattern** ([`PROJECT.md:33`](/Users/jon/projects/accrue/.planning/PROJECT.md:33)):
```md
## Current Milestone: v1.2 Adoption + Trust

**Goal:** Make Accrue feel ready for a new Phoenix team to evaluate, integrate, and trust by polishing the canonical demo/onboarding path, adding mature-library quality signals, and deciding the next expansion bet without partially implementing it.
```

**Checklist item shape to edit in place** ([`PROJECT.md:57`](/Users/jon/projects/accrue/.planning/PROJECT.md:57)):
```md
### Active

v1.2 active requirements are defined in `.planning/REQUIREMENTS.md`.

- [ ] Phoenix developers can clone the repository, run the canonical local demo, create a Fake-backed subscription, inspect/replay billing state in admin, and run the focused proof suite without hidden state.
```

For Phase 17, preserve the exact checklist voice and flip only the stale canonical-demo status to match the audit and roadmap.

---

### `.planning/ROADMAP.md` (config, request-response)

**Analog:** [`ROADMAP.md:36`](/Users/jon/projects/accrue/.planning/ROADMAP.md:36)

Keep the current roadmap structure: top milestone summary, then detailed phase section, then progress table. Any bookkeeping edit should update only the stale checkbox/status line and leave the detail block intact.

**Top milestone phase-list pattern** ([`ROADMAP.md:36`](/Users/jon/projects/accrue/.planning/ROADMAP.md:36)):
```md
<details open>
<summary>📋 v1.2 Adoption + Trust (Phases 13-17) — PLANNED</summary>

- [x] Phase 13: Canonical Demo + Tutorial — make `examples/accrue_host` the polished local demo and tutorial proof path. (completed 2026-04-17)
- [ ] Phase 17: Milestone Closure Cleanup — close v1.2 audit tech debt before archival without adding product scope.
```

**Phase detail + success criteria pattern** ([`ROADMAP.md:128`](/Users/jon/projects/accrue/.planning/ROADMAP.md:128)):
```md
### Phase 17: Milestone Closure Cleanup

**Goal:** Close the non-critical tech-debt items recorded by the v1.2 milestone audit so the milestone can be archived without stale planning or trust-lane cleanup risks.

**Success criteria:**
1. ROADMAP and PROJECT bookkeeping agree that Phase 13 and the canonical demo outcome are complete.
2. Browser E2E fixture cleanup only removes fixture-owned webhook/payment-failed rows and preserves unrelated shared test DB history.
```

Use the roadmap as the canonical statement of what Phase 17 closes; `PROJECT.md` should mirror it, not add nuance.

---

### `scripts/ci/accrue_host_seed_e2e.exs` (utility, file-I/O)

**Primary analog:** [`accrue_host_seed_e2e.exs:1`](/Users/jon/projects/accrue/scripts/ci/accrue_host_seed_e2e.exs:1)  
**Secondary analog for cleanup scoping:** [`host_flow_proof_case.ex:20`](/Users/jon/projects/accrue/examples/accrue_host/test/support/host_flow_proof_case.ex:20)

Retain the current top-level script style: aliases, `import Ecto.Query`, deterministic seeded IDs, delete-old/create-new, then write the fixture JSON. The Phase 17 change should narrow predicates, not refactor the script into modules.

**Imports + deterministic seed constants pattern** ([`accrue_host_seed_e2e.exs:1`](/Users/jon/projects/accrue/scripts/ci/accrue_host_seed_e2e.exs:1)):
```elixir
alias Accrue.Billing.Customer
alias Accrue.Billing.Subscription
alias Accrue.Billing.SubscriptionItem
alias Accrue.Events
alias Accrue.Events.Event
alias Accrue.Webhook.WebhookEvent
alias AccrueHost.Accounts
alias AccrueHost.Accounts.User
alias AccrueHost.Repo

import Ecto.Query
```

**Current cleanup block to replace with narrower predicates** ([`accrue_host_seed_e2e.exs:67`](/Users/jon/projects/accrue/scripts/ci/accrue_host_seed_e2e.exs:67)):
```elixir
Repo.query!("ALTER TABLE accrue_events DISABLE TRIGGER accrue_events_immutable_trigger")

try do
  Repo.delete_all(
    from(event in Event,
      where:
        event.type in ["invoice.payment_failed", "admin.webhook.replay.completed"] and
          event.subject_type in ["Subscription", "WebhookEvent"]
    )
  )
after
  Repo.query!("ALTER TABLE accrue_events ENABLE TRIGGER accrue_events_immutable_trigger")
end

Repo.delete_all(
  from(webhook in WebhookEvent,
    where: webhook.processor_event_id in ["evt_host_browser_replay", "evt_host_browser_first_run"]
  )
)
```

**Fixture-owned event linkage already available in the same script** ([`accrue_host_seed_e2e.exs:222`](/Users/jon/projects/accrue/scripts/ci/accrue_host_seed_e2e.exs:222)):
```elixir
{:ok, _event} =
  Events.record(%{
    type: "invoice.payment_failed",
    subject_type: "Subscription",
    subject_id: subscription.id,
    actor_type: "webhook",
    actor_id: webhook.processor_event_id,
    caused_by_webhook_event_id: webhook.id
  })
```

**Delete ordering pattern to preserve** ([`accrue_host_seed_e2e.exs:81`](/Users/jon/projects/accrue/scripts/ci/accrue_host_seed_e2e.exs:81)):
```elixir
Repo.delete_all(from(webhook in WebhookEvent, ...))
Repo.delete_all(from(item in SubscriptionItem, ...))
Repo.delete_all(from(subscription in Subscription, ...))
Repo.delete_all(from(customer in Customer, ...))
Repo.delete_all(from(user in User, ...))
```

**Closest scoping precedent from focused host proofs** ([`host_flow_proof_case.ex:20`](/Users/jon/projects/accrue/examples/accrue_host/test/support/host_flow_proof_case.ex:20)):
```elixir
@cleanup_event_types [
  "webhook.received",
  "host.webhook.handled",
  "invoice.payment_failed",
  "admin.webhook.replay.completed"
]

Repo.delete_all(
  from(webhook in WebhookEvent,
    where: like(webhook.processor_event_id, "evt_host_%")
  )
)
```

Copy the query style from the existing script, but scope Phase 17 deletes by fixture identity already present in the script: `processor_event_id`, seeded `subscription.id`, seeded `customer.id`, and `caused_by_webhook_event_id`. Do not leave any type-only delete in `accrue_events`.

---

### `RELEASING.md` (config, request-response)

**Analog:** [`RELEASING.md:5`](/Users/jon/projects/accrue/RELEASING.md:5)

Keep the existing three-lane release vocabulary and short checklist style. Phase 17 should only remove stale wording and keep references aligned with current CI job names and required/advisory boundaries.

**Release-lane vocabulary pattern** ([`RELEASING.md:5`](/Users/jon/projects/accrue/RELEASING.md:5)):
```md
## Release verification lanes

- `Canonical local demo: Fake` is the required deterministic gate for docs and release readiness.
- `Provider parity: Stripe test mode` is for optional/manual provider-parity checks.
- `Advisory/manual: live Stripe` is for final app-level confidence before shipping your app.
```

**Stale wording location to edit in place** ([`RELEASING.md:17`](/Users/jon/projects/accrue/RELEASING.md:17)):
```md
## Same-day `1.0.0` bootstrap

1. Confirm CI is green on `main`, especially the Phase 9 release gate for both packages.
```

**Required deterministic gate checklist pattern** ([`RELEASING.md:68`](/Users/jon/projects/accrue/RELEASING.md:68)):
```md
Run the required deterministic gate first:

```bash
cd accrue
mix test --warnings-as-errors
bash ../scripts/ci/verify_package_docs.sh
```
```

When adjusting wording, keep the invariant phrases already asserted by the docs contracts: `required deterministic gate`, `provider-parity checks`, `advisory/manual before shipping your app`, and `guides/testing-live-stripe.md`.

---

### `guides/testing-live-stripe.md` (config, request-response)

**Analog:** [`testing-live-stripe.md:1`](/Users/jon/projects/accrue/guides/testing-live-stripe.md:1)

Keep the guide split into coverage, local run, `act`, GitHub Actions, schedule, and philosophy. Phase 17 should correct the stale CI reference without weakening the guide's advisory/manual stance.

**Guide framing pattern** ([`testing-live-stripe.md:16`](/Users/jon/projects/accrue/guides/testing-live-stripe.md:16)):
```md
This guide covers layer (2). Most contributors never need to run it;
it executes automatically on a daily GitHub Actions schedule and can
be triggered on demand via the Actions tab.

This lane uses Stripe test mode and should be treated as `provider-parity checks`, not as the canonical local demo or the required release lane.
```

**Current stale CI wording to replace** ([`testing-live-stripe.md:82`](/Users/jon/projects/accrue/guides/testing-live-stripe.md:82)):
```md
## Scheduled run

The `live-stripe` job also runs daily at 06:00 UTC via the workflow's
`schedule:` trigger. Failures are surfaced as annotated job summaries
and can be monitored alongside the primary `test` job.
```

**Authoritative workflow names to reference** ([`ci.yml:21`](/Users/jon/projects/accrue/.github/workflows/ci.yml:21), [`ci.yml:227`](/Users/jon/projects/accrue/.github/workflows/ci.yml:227), [`ci.yml:259`](/Users/jon/projects/accrue/.github/workflows/ci.yml:259), [`ci.yml:376`](/Users/jon/projects/accrue/.github/workflows/ci.yml:376), [`ci.yml:405`](/Users/jon/projects/accrue/.github/workflows/ci.yml:405)):
```yaml
jobs:
  release-gate:
  admin-drift-docs:
  host-integration:
  annotation-sweep:
  live-stripe:
```

Use either the exact current job names from `ci.yml` or wording that avoids naming a non-existent primary `test` job.

---

### `CONTRIBUTING.md` (config, request-response)

**Analog:** [`CONTRIBUTING.md:8`](/Users/jon/projects/accrue/CONTRIBUTING.md:8)

Keep the terse contributor checklist style. Phase 17 should correct the browser trust lane location while keeping the release-gate and provider-parity guidance already in place.

**Development setup bullet-list pattern** ([`CONTRIBUTING.md:8`](/Users/jon/projects/accrue/CONTRIBUTING.md:8)):
```md
## Development setup

Install the supported toolchain first:

- Elixir 1.17+
- OTP 27+
- PostgreSQL 14+
- Node.js for browser UAT in `accrue_admin`
```

**Bootstrap commands pattern** ([`CONTRIBUTING.md:17`](/Users/jon/projects/accrue/CONTRIBUTING.md:17)):
```md
Then bootstrap both packages:

```bash
cd accrue
mix deps.get

cd ../accrue_admin
mix deps.get
npm ci
```
```

**Current release-gate language to preserve** ([`CONTRIBUTING.md:42`](/Users/jon/projects/accrue/CONTRIBUTING.md:42)):
```md
## Running the release gate locally

Run the release gate from each package directory before opening a PR:
```

Correct the browser-UAT location to `examples/accrue_host` and keep the document routing contributors to the package-local READMEs and the live-Stripe guide rather than adding a new contributor workflow.

---

### `accrue/test/accrue/docs/release_guidance_test.exs` (test, batch)

**Analog:** [`release_guidance_test.exs:1`](/Users/jon/projects/accrue/accrue/test/accrue/docs/release_guidance_test.exs:1)

Use the existing direct-file-read ExUnit contract style. If Phase 17 adds or changes wording guarantees, extend these assertions instead of introducing a new docs test module.

**File path constants + file-read contract pattern** ([`release_guidance_test.exs:4`](/Users/jon/projects/accrue/accrue/test/accrue/docs/release_guidance_test.exs:4)):
```elixir
@releasing_path Path.expand("../../../../RELEASING.md", __DIR__)
@guide_path Path.expand("../../../../guides/testing-live-stripe.md", __DIR__)
@contributing_path Path.expand("../../../../CONTRIBUTING.md", __DIR__)

test "release guidance separates deterministic, provider-parity, and advisory lanes" do
  releasing = File.read!(@releasing_path)
```

**Positive/negative docs assertion pattern** ([`release_guidance_test.exs:11`](/Users/jon/projects/accrue/accrue/test/accrue/docs/release_guidance_test.exs:11)):
```elixir
assert releasing =~ "Canonical local demo: Fake"
assert releasing =~ "Provider parity: Stripe test mode"
assert releasing =~ "Advisory/manual: live Stripe"

refute releasing =~ "live Stripe is required for clone-to-evaluate"
refute releasing =~ "Stripe test mode is required for every release"
```

**Guide and contributing coverage pattern** ([`release_guidance_test.exs:29`](/Users/jon/projects/accrue/accrue/test/accrue/docs/release_guidance_test.exs:29)):
```elixir
test "provider parity guide stays explicit about test mode and advisory status" do
  guide = File.read!(@guide_path)

  assert guide =~ "provider-parity checks"
  assert guide =~ "continue-on-error: true"
end

test "contributing routes contributors to the provider parity guide safely" do
  contributing = File.read!(@contributing_path)

  assert contributing =~ "guides/testing-live-stripe.md"
  assert contributing =~ "required deterministic release gate"
end
```

Phase 17 should add assertions here only if the planner decides the stale Phase 9 / CI-job / trust-lane wording needs an executable contract beyond the shell verifier.

---

### `accrue/test/accrue/docs/package_docs_verifier_test.exs` (test, batch)

**Analog:** [`package_docs_verifier_test.exs:1`](/Users/jon/projects/accrue/accrue/test/accrue/docs/package_docs_verifier_test.exs:1)

Keep the wrapper-test pattern: call the shell verifier, assert success output, then use temporary drifted fixtures to prove specific failures.

**Happy-path shell-wrapper pattern** ([`package_docs_verifier_test.exs:6`](/Users/jon/projects/accrue/accrue/test/accrue/docs/package_docs_verifier_test.exs:6)):
```elixir
test "package docs verifier succeeds" do
  {output, status} = System.cmd("bash", [@script_path], stderr_to_stdout: true)

  assert status == 0
  assert output =~ "package docs verified"
end
```

**Temporary fixture drift-test pattern** ([`package_docs_verifier_test.exs:25`](/Users/jon/projects/accrue/accrue/test/accrue/docs/package_docs_verifier_test.exs:25)):
```elixir
tmp_dir = Path.join(System.tmp_dir!(), "accrue-docs-verifier-#{System.unique_integer([:positive])}")
File.rm_rf!(tmp_dir)
on_exit(fn -> File.rm_rf(tmp_dir) end)

copy_fixture!("README.md", tmp_dir)
copy_fixture!("RELEASING.md", tmp_dir)
copy_fixture!("guides/testing-live-stripe.md", tmp_dir)
```

**Mutation + failure assertion pattern** ([`package_docs_verifier_test.exs:90`](/Users/jon/projects/accrue/accrue/test/accrue/docs/package_docs_verifier_test.exs:90)):
```elixir
drifted_releasing =
  tmp_dir
  |> Path.join("RELEASING.md")
  |> File.read!()
  |> String.replace("provider-parity checks", "optional checks")

{output, status} =
  System.cmd("bash", [@script_path], stderr_to_stdout: true, env: [{"ROOT_DIR", tmp_dir}])

assert status != 0
assert output =~ "RELEASING.md"
```

If Phase 17 adds a new fixed invariant to `verify_package_docs.sh`, add one narrow failing fixture test here rather than broadening the existing cases.

---

### `scripts/ci/verify_package_docs.sh` (utility, batch)

**Analog:** [`verify_package_docs.sh:1`](/Users/jon/projects/accrue/scripts/ci/verify_package_docs.sh:1)

Keep the current helper-heavy shell style and append fixed or regex invariants near the existing release/docs checks. Do not replace this with ad hoc `rg` one-liners in CI.

**Helper function pattern** ([`verify_package_docs.sh:9`](/Users/jon/projects/accrue/scripts/ci/verify_package_docs.sh:9)):
```bash
fail() {
  echo "package docs verification failed: $*" >&2
  exit 1
}

require_fixed() {
  local file=$1
  local needle=$2

  grep -Fq "$needle" "$file" || fail "$file is missing: $needle"
}
```

**Regex/negative-match helper pattern** ([`verify_package_docs.sh:30`](/Users/jon/projects/accrue/scripts/ci/verify_package_docs.sh:30)):
```bash
require_regex() {
  local file=$1
  local pattern=$2

  grep -Eq "$pattern" "$file" || fail "$file does not match: $pattern"
}

require_absent_regex() {
  local file=$1
  local pattern=$2
```

**Existing docs invariant block to extend in place** ([`verify_package_docs.sh:108`](/Users/jon/projects/accrue/scripts/ci/verify_package_docs.sh:108)):
```bash
require_fixed "$ROOT_DIR/RELEASING.md" "Canonical local demo: Fake"
require_fixed "$ROOT_DIR/RELEASING.md" "Provider parity: Stripe test mode"
require_fixed "$ROOT_DIR/RELEASING.md" "Advisory/manual: live Stripe"
require_fixed "$ROOT_DIR/RELEASING.md" "required deterministic gate"
require_fixed "$ROOT_DIR/RELEASING.md" "provider-parity checks"
require_fixed "$ROOT_DIR/guides/testing-live-stripe.md" "STRIPE_TEST_SECRET_KEY"
```

For Phase 17, this is the right place to lock any newly corrected wording that is supposed to stay stable, especially current CI lane names or the host-lane path if the planner chooses shell-level drift protection.

## Shared Patterns

### Planning Bookkeeping Parity
**Sources:** [`PROJECT.md:57`](/Users/jon/projects/accrue/.planning/PROJECT.md:57), [`ROADMAP.md:136`](/Users/jon/projects/accrue/.planning/ROADMAP.md:136)

Apply the existing checklist style and keep wording synced across planning artifacts.

```md
### Active
- [ ] Phoenix developers can clone the repository, run the canonical local demo...

Planned work:
- [ ] 17-01-PLAN.md — Align milestone bookkeeping, narrow browser fixture cleanup, and fix stale release/contributor docs references.
```

### Fixture-Owned Cleanup Only
**Sources:** [`accrue_host_seed_e2e.exs:67`](/Users/jon/projects/accrue/scripts/ci/accrue_host_seed_e2e.exs:67), [`accrue_host_seed_e2e.exs:222`](/Users/jon/projects/accrue/scripts/ci/accrue_host_seed_e2e.exs:222), [`host_flow_proof_case.ex:81`](/Users/jon/projects/accrue/examples/accrue_host/test/support/host_flow_proof_case.ex:81)

Keep the immutable-trigger disable/enable bracket and delete ordering, but scope by seeded fixture IDs already available in the script.

```elixir
Repo.query!("ALTER TABLE accrue_events DISABLE TRIGGER accrue_events_immutable_trigger")

try do
  Repo.delete_all(from(event in Event, ...))
after
  Repo.query!("ALTER TABLE accrue_events ENABLE TRIGGER accrue_events_immutable_trigger")
end

Events.record(%{
  subject_id: subscription.id,
  actor_id: webhook.processor_event_id,
  caused_by_webhook_event_id: webhook.id
})
```

### Docs Contracts Prefer Direct Assertions
**Source:** [`release_guidance_test.exs:8`](/Users/jon/projects/accrue/accrue/test/accrue/docs/release_guidance_test.exs:8)

Use `File.read!/1` plus explicit `assert`/`refute` lines for prose that must stay human-readable and stable.

```elixir
releasing = File.read!(@releasing_path)
assert releasing =~ "required deterministic gate"
refute releasing =~ "Stripe test mode is required for every release"
```

### Shell Drift Guard Uses Fixed Invariants
**Source:** [`verify_package_docs.sh:108`](/Users/jon/projects/accrue/scripts/ci/verify_package_docs.sh:108)

Use `require_fixed` and `require_regex` for short, durable phrases that should fail fast in CI.

```bash
require_fixed "$ROOT_DIR/RELEASING.md" "provider-parity checks"
require_fixed "$ROOT_DIR/guides/testing-live-stripe.md" "STRIPE_TEST_SECRET_KEY"
```

### CI Job Names Must Come From Workflow Source
**Source:** [`ci.yml:20`](/Users/jon/projects/accrue/.github/workflows/ci.yml:20)

When docs mention workflow lanes, copy the current names from `.github/workflows/ci.yml`.

```yaml
jobs:
  release-gate:
  admin-drift-docs:
  host-integration:
  annotation-sweep:
  live-stripe:
```

## No Analog Found

None. Every Phase 17 target file already has a live in-repo analog because this phase is tightening existing planning/docs/test infrastructure rather than introducing a new subsystem.

## Metadata

**Analog search scope:** `.planning/`, `scripts/ci/`, `accrue/test/accrue/docs/`, `examples/accrue_host/test/support/`, `.github/workflows/`, `guides/`  
**Files scanned:** 12  
**Pattern extraction date:** 2026-04-17
