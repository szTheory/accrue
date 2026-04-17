# Phase 13: Canonical Demo + Tutorial - Pattern Map

**Mapped:** 2026-04-16
**Files analyzed:** 9
**Analogs found:** 9 / 9

## File Classification

> Note: Markdown tutorial files are classified as `utility` because the planner role set does not include a separate `docs` role.

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `examples/accrue_host/README.md` | utility | transform | `examples/accrue_host/README.md` | exact |
| `accrue/guides/first_hour.md` | utility | transform | `accrue/guides/first_hour.md` | exact |
| `examples/accrue_host/mix.exs` | config | batch | `examples/accrue_host/mix.exs` | exact |
| `scripts/ci/accrue_host_uat.sh` | utility | batch | `scripts/ci/accrue_host_uat.sh` | exact |
| `examples/accrue_host/demo/command_manifest.exs` | config | transform | `accrue/test/accrue/docs/first_hour_guide_test.exs` | partial |
| `accrue/test/accrue/docs/first_hour_guide_test.exs` | test | transform | `accrue/test/accrue/docs/first_hour_guide_test.exs` | exact |
| `accrue/test/accrue/docs/canonical_demo_contract_test.exs` | test | transform | `accrue/test/accrue/docs/package_docs_verifier_test.exs` | role-match |
| `scripts/ci/verify_package_docs.sh` | utility | batch | `scripts/ci/verify_package_docs.sh` | exact |
| `accrue/test/accrue/docs/package_docs_verifier_test.exs` | test | batch | `accrue/test/accrue/docs/package_docs_verifier_test.exs` | exact |

## Pattern Assignments

### `examples/accrue_host/README.md` (utility, transform)

**Analog:** `examples/accrue_host/README.md`

**Heading + command-block pattern** (`examples/accrue_host/README.md:5-35`):
```text
## Prerequisite

PostgreSQL 14+ must already be running before you execute setup or boot commands.

## First Hour Path

From `examples/accrue_host`:

mix deps.get
mix accrue.install --billable AccrueHost.Accounts.User --billing-context AccrueHost.Billing --admin-mount /billing --webhook-path /webhooks/stripe
mix ecto.create
mix ecto.migrate
mix test test/accrue_host/billing_facade_test.exs
mix test test/accrue_host_web/webhook_ingest_test.exs
mix test test/accrue_host_web/admin_mount_test.exs
mix phx.server
```

**Canonical references pattern** (`examples/accrue_host/README.md:24-35`):
```text
The package docs mirror this order:

- `../../accrue/guides/first_hour.md`
- `../../accrue/guides/troubleshooting.md`
- `../../accrue/guides/webhooks.md`
- `../../accrue_admin/guides/admin_ui.md`

For a CI-equivalent local check from the repository root:

bash scripts/ci/accrue_host_uat.sh
```

**Local defaults / proof bullets** (`examples/accrue_host/README.md:37-47`):
```markdown
## Local Defaults

- The default local setup uses `Accrue.Processor.Fake`
- The default webhook signing secret is `whsec_test_host`

## What The App Proves

- Host-owned Phoenix auth and session state gate the mounted admin UI at `/billing`.
- Signed webhook ingestion runs through the installed `/webhooks/stripe` route.
- Admin replay actions leave persisted audit evidence in `accrue_events`.
```

---

### `accrue/guides/first_hour.md` (utility, transform)

**Analog:** `accrue/guides/first_hour.md`

**Stepwise tutorial structure** (`accrue/guides/first_hour.md:7-58`):
```markdown
## 1. Add the dependency
...
## 2. Run the installer
...
## 3. Configure `config/runtime.exs`
...
## 4. Run database setup
```

**Public-boundary narrative pattern** (`accrue/guides/first_hour.md:102-155`):
```elixir
defmodule MyApp.BillingHandler do
  use Accrue.Webhook.Handler

  @impl Accrue.Webhook.Handler
  def handle_event(type, event, ctx) do
    MyApp.Billing.handle_webhook(type, event, ctx)
  end
end
```

```elixir
{:ok, subscription} =
  MyApp.Billing.subscribe(user, "price_basic", trial_end: {:days, 14})
```

**Finish with boot + focused proof commands** (`accrue/guides/first_hour.md:157-177`):
```text
## 10. Inspect `/billing`

mix phx.server

## 11. Run focused tests

mix test test/accrue_host/billing_facade_test.exs
mix test test/accrue_host_web/webhook_ingest_test.exs
mix test test/accrue_host_web/admin_mount_test.exs
```

---

### `examples/accrue_host/mix.exs` (config, batch)

**Analog:** `examples/accrue_host/mix.exs`

**Alias block shape** (`examples/accrue_host/mix.exs:109-129`):
```elixir
# Aliases are shortcuts or tasks specific to the current project.
defp aliases do
  [
    setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
    "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
    "ecto.reset": ["ecto.drop", "ecto.setup"],
    test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
    "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
    "assets.build": ["compile", "tailwind accrue_host", "esbuild accrue_host"],
    "assets.deploy": [
      "tailwind accrue_host --minify",
      "esbuild accrue_host --minify",
      "phx.digest"
    ],
    precommit: ["compile --warnings-as-errors", "deps.unlock --unused", "format", "test"]
  ]
end
```

**Mix alias composition precedent from package root** (`accrue/mix.exs:103-116`):
```elixir
defp aliases do
  [
    "test.all": [
      "format --check-formatted",
      "credo --strict",
      "compile --warnings-as-errors",
      "test"
    ],
    "test.live": ["test --only live_stripe"]
  ]
end
```

**Pattern to copy:** keep alias values as ordered string task lists; compose `verify.full` out of smaller public aliases instead of embedding a second handwritten contract.

---

### `scripts/ci/accrue_host_uat.sh` (utility, batch)

**Analog:** `scripts/ci/accrue_host_uat.sh`

**Shell prologue + environment contract** (`scripts/ci/accrue_host_uat.sh:1-24`):
```bash
#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
host_dir="$repo_root/examples/accrue_host"
port="${ACCRUE_HOST_PORT:-4100}"
browser_port="${ACCRUE_HOST_BROWSER_PORT:-4101}"
```

**Stage-oriented verification pattern** (`scripts/ci/accrue_host_uat.sh:35-80`):
```bash
echo "--- documented setup: deps + installer idempotence ---"
mix deps.get
mix accrue.install --yes ...

echo "--- compile gate ---"
mix compile --warnings-as-errors

echo "--- browser asset build ---"
mix assets.build

echo "--- host UAT test suite ---"
MIX_ENV=test mix test --warnings-as-errors \
  test/install_boundary_test.exs \
  test/accrue_host/billing_facade_test.exs \
  test/accrue_host_web/subscription_flow_test.exs \
  test/accrue_host_web/webhook_ingest_test.exs \
  test/accrue_host_web/admin_webhook_replay_test.exs \
  test/accrue_host_web/admin_mount_test.exs
```

**Bounded dev-boot / browser-smoke cleanup pattern** (`scripts/ci/accrue_host_uat.sh:82-210`):
```bash
cleanup() {
  if [ -n "${server_pid:-}" ] && kill -0 "$server_pid" >/dev/null 2>&1; then
    kill "$server_pid" >/dev/null 2>&1 || true
    wait "$server_pid" >/dev/null 2>&1 || true
  fi
  rm -f "$log_file"
}
trap cleanup EXIT

PORT="$port" MIX_ENV=dev mix phx.server >"$log_file" 2>&1 &
...
cleanup_browser() {
  ...
}
trap cleanup_browser EXIT
```

---

### `examples/accrue_host/demo/command_manifest.exs` (config, transform)

**Analog:** `accrue/test/accrue/docs/first_hour_guide_test.exs`

**Data-list pattern to copy** (`accrue/test/accrue/docs/first_hour_guide_test.exs:4-34`):
```elixir
@guide "guides/first_hour.md"
@ordered_steps [
  "mix deps.get",
  "mix accrue.install",
  "config/runtime.exs",
  "mix ecto.migrate",
  "Oban",
  "/webhooks/stripe",
  ~s|accrue_admin "/billing"|,
  "MyApp.Billing.subscribe",
  "customer.subscription.created",
  "/billing",
  "mix test"
]
@public_surfaces [
  "MyApp.Billing",
  "use Accrue.Webhook.Handler",
  "use Accrue.Test"
]
```

**Why this is the closest pattern:** there is no existing repo-readable command manifest, but this test already centralizes ordered tutorial strings and allowed/forbidden surfaces. The new manifest should externalize this data rather than inventing a new schema.

---

### `accrue/test/accrue/docs/first_hour_guide_test.exs` (test, transform)

**Analog:** `accrue/test/accrue/docs/first_hour_guide_test.exs`

**Guide-contract pattern** (`accrue/test/accrue/docs/first_hour_guide_test.exs:36-50`):
```elixir
test "first hour guide preserves the Phoenix-order host boundary contract" do
  guide = File.read!(@guide)

  assert_order!(guide, @ordered_steps)

  Enum.each(@public_surfaces, fn surface ->
    assert guide =~ surface
  end)

  Enum.each(@forbidden_surfaces, fn surface ->
    refute guide =~ surface
  end)

  refute guide =~ ~r/webhook_signing_secret(?!s)/
end
```

**Reusable order helper** (`accrue/test/accrue/docs/first_hour_guide_test.exs:52-69`):
```elixir
defp assert_order!(guide, [first | rest]) do
  Enum.reduce(rest, index_of(guide, first), fn step, previous_index ->
    current_index = index_of(guide, step, previous_index + 1)
    assert current_index
    assert previous_index
    assert previous_index < current_index
    current_index
  end)
end
```

---

### `accrue/test/accrue/docs/canonical_demo_contract_test.exs` (test, transform)

**Analog:** `accrue/test/accrue/docs/package_docs_verifier_test.exs`

**Executable verifier pattern** (`accrue/test/accrue/docs/package_docs_verifier_test.exs:4-11`):
```elixir
@script_path "../scripts/ci/verify_package_docs.sh"

test "package docs verifier succeeds" do
  {output, status} = System.cmd("bash", [@script_path], stderr_to_stdout: true)

  assert status == 0
  assert output =~ "package docs verified"
end
```

**Temp-dir mutation pattern for drift cases** (`accrue/test/accrue/docs/package_docs_verifier_test.exs:13-51`):
```elixir
tmp_dir = Path.join(System.tmp_dir!(), "accrue-docs-verifier-#{System.unique_integer([:positive])}")
File.rm_rf!(tmp_dir)
on_exit(fn -> File.rm_rf(tmp_dir) end)
File.mkdir_p!(Path.join(tmp_dir, "accrue/guides"))
...
File.write!(Path.join(tmp_dir, "accrue/guides/first_hour.md"), singular_guide)

{output, status} =
  System.cmd("bash", [@script_path],
    stderr_to_stdout: true,
    env: [{"ROOT_DIR", tmp_dir}]
  )
```

**Supplemental assertion style** (`accrue/test/accrue/docs/troubleshooting_guide_test.exs:47-70`):
```elixir
Enum.each(@verification_commands, fn command ->
  assert guide =~ command
end)

Enum.each(@required_webhook_fix, fn snippet ->
  assert guide =~ snippet
end)
```

---

### `scripts/ci/verify_package_docs.sh` (utility, batch)

**Analog:** `scripts/ci/verify_package_docs.sh`

**Small helper-function pattern** (`scripts/ci/verify_package_docs.sh:9-44`):
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

require_absent_regex() {
  local file=$1
  local pattern=$2
  if grep -Eq "$pattern" "$file"; then
    fail "$file must not match: $pattern"
  fi
}
```

**Narrow fixed-invariant pattern** (`scripts/ci/verify_package_docs.sh:67-75`):
```bash
for guide in \
  "$ROOT_DIR/accrue/guides/first_hour.md" \
  "$ROOT_DIR/accrue/guides/troubleshooting.md"; do
  require_fixed "$guide" 'config :accrue, :webhook_signing_secrets, %{'
  require_fixed "$guide" 'stripe: System.get_env("STRIPE_WEBHOOK_SECRET", "whsec_test_host")'
  require_absent_regex "$guide" 'webhook_signing_secret([^s]|$)'
done
```

**Pattern to copy:** keep this script limited to cheap, fixed-string invariants; move ordered command parity and public/private surface assertions into ExUnit.

---

### `accrue/test/accrue/docs/package_docs_verifier_test.exs` (test, batch)

**Analog:** `accrue/test/accrue/docs/package_docs_verifier_test.exs`

**Shell-verifier harness pattern** (`accrue/test/accrue/docs/package_docs_verifier_test.exs:6-11`):
```elixir
{output, status} = System.cmd("bash", [@script_path], stderr_to_stdout: true)

assert status == 0
assert output =~ "package docs verified for accrue"
```

**Fixture-copy helper pattern** (`accrue/test/accrue/docs/package_docs_verifier_test.exs:47-51`):
```elixir
defp copy_fixture!(relative_path, tmp_dir) do
  destination = Path.join(tmp_dir, relative_path)
  File.mkdir_p!(Path.dirname(destination))
  File.cp!(Path.expand("../../../../" <> relative_path, __DIR__), destination)
end
```

## Shared Patterns

### Focused Host Verification Contract
**Sources:** `scripts/ci/accrue_host_uat.sh:66-80`, `examples/accrue_host/test/install_boundary_test.exs:13-51`
**Apply to:** `examples/accrue_host/mix.exs`, `scripts/ci/accrue_host_uat.sh`, docs describing `mix verify`

```bash
MIX_ENV=test mix test --warnings-as-errors \
  test/install_boundary_test.exs \
  test/accrue_host/billing_facade_test.exs \
  test/accrue_host_web/subscription_flow_test.exs \
  test/accrue_host_web/webhook_ingest_test.exs \
  test/accrue_host_web/admin_webhook_replay_test.exs \
  test/accrue_host_web/admin_mount_test.exs
```

```elixir
assert billing =~ "def subscribe(billable, price_id, opts \\\\ []) do"
assert router =~ @webhook_route
assert runtime =~ "config :accrue, :processor, Accrue.Processor.Fake"
```

### Public-Boundary First-Run Proofs
**Sources:** `examples/accrue_host/test/accrue_host/billing_facade_test.exs:48-64`, `examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs:17-60`, `examples/accrue_host/test/accrue_host_web/admin_mount_test.exs:21-38`
**Apply to:** tutorial prose, manifest step labels, focused test docs

```elixir
assert {:ok, %Subscription{} = subscription} =
         Billing.subscribe(user, "price_basic", trial_end: {:days, 14})
```

```elixir
first_conn = post_webhook(payload, signature)
assert first_conn.status == 200
assert %{"ok" => true} = Jason.decode!(first_conn.resp_body)
```

```elixir
assert {:ok, _view, html} = live(conn, "/billing")
assert html =~ "Local billing projections at a glance"
```

### Seeded History Stays Separate From First Run
**Sources:** `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs:18-139`, `examples/accrue_host/e2e/phase11-host-gate.spec.js:69-117`
**Apply to:** README/guide labels, `verify.full`, browser smoke docs

```elixir
webhook =
  insert_webhook(%{
    type: "invoice.payment_failed",
    status: :dead,
    ...
  })
```

```javascript
await page.goto(`/billing/webhooks/${fixture.webhook_id}`);
await page.locator("[data-role='replay-single']").click();
await expect(page.getByText("Webhook replay requested.")).toBeVisible();
```

### Docs Contract Testing
**Sources:** `accrue/test/accrue/docs/first_hour_guide_test.exs:36-69`, `accrue/test/accrue/docs/troubleshooting_guide_test.exs:47-70`
**Apply to:** manifest parity tests and guide assertions

```elixir
guide = File.read!(@guide)
assert_order!(guide, @ordered_steps)

Enum.each(@public_surfaces, fn surface ->
  assert guide =~ surface
end)
```

### Shell Verifier Scope
**Sources:** `scripts/ci/verify_package_docs.sh:23-44`, `scripts/ci/verify_package_docs.sh:67-75`
**Apply to:** `scripts/ci/verify_package_docs.sh`

```bash
require_fixed "$guide" '...'
require_absent_regex "$guide" '...'
```

## No Analog Found

None. The only novel file is the command manifest, and the closest reusable data-shape already exists in `accrue/test/accrue/docs/first_hour_guide_test.exs`.

## Metadata

**Analog search scope:** `examples/accrue_host`, `accrue`, `scripts/ci`, `.github/workflows`
**Files scanned:** 20+ targeted files, plus repo-wide `rg` searches for aliases, docs contracts, and CI wrappers
**Pattern extraction date:** 2026-04-16
