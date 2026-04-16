# Phase 12: First-User DX Stabilization - Pattern Map

**Mapped:** 2026-04-16
**Files analyzed:** 18
**Analogs found:** 17 / 18

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue/lib/mix/tasks/accrue.install.ex` | controller | request-response | `accrue/lib/mix/tasks/accrue.install.ex` | exact |
| `accrue/lib/accrue/install/fingerprints.ex` | utility | file-I/O | `accrue/lib/accrue/install/fingerprints.ex` | exact |
| `accrue/lib/accrue/install/patches.ex` | service | file-I/O | `accrue/lib/accrue/install/patches.ex` | exact |
| `accrue/lib/accrue/setup_diagnostic.ex` | utility | transform | `accrue/lib/accrue/errors.ex` | partial |
| `accrue/test/mix/tasks/accrue_install_uat_test.exs` | test | request-response | `accrue/test/mix/tasks/accrue_install_uat_test.exs` | exact |
| `accrue/README.md` | config | request-response | `accrue/README.md` | exact |
| `accrue/guides/quickstart.md` | config | request-response | `examples/accrue_host/README.md` | role-match |
| `accrue/guides/first_hour.md` | config | request-response | `examples/accrue_host/README.md` | role-match |
| `accrue/guides/troubleshooting.md` | config | transform | `accrue/guides/testing.md` | role-match |
| `accrue/guides/webhooks.md` | config | request-response | `accrue/guides/testing.md` | partial |
| `accrue/guides/upgrade.md` | config | request-response | `accrue/guides/upgrade.md` | exact |
| `accrue/test/accrue/docs/first_hour_guide_test.exs` | test | transform | `accrue/test/accrue/docs/testing_guide_test.exs` | role-match |
| `accrue/test/accrue/docs/troubleshooting_guide_test.exs` | test | transform | `accrue/test/accrue/docs/community_auth_test.exs` | role-match |
| `scripts/ci/verify_package_docs.sh` | utility | batch | `scripts/ci/annotation_sweep.sh` | role-match |
| `examples/accrue_host/mix.exs` | config | request-response | `accrue_admin/mix.exs` | role-match |
| `scripts/ci/accrue_host_hex_smoke.sh` | utility | batch | `scripts/ci/accrue_host_uat.sh` | role-match |
| `.github/workflows/ci.yml` | config | batch | `.github/workflows/ci.yml` | exact |
| `examples/accrue_host/lib/accrue_host/billing.ex` | service | CRUD | `examples/accrue_host/lib/accrue_host/billing.ex` | exact |

## Pattern Assignments

### `accrue/lib/mix/tasks/accrue.install.ex` (controller, request-response)

**Analog:** `accrue/lib/mix/tasks/accrue.install.ex`

**Imports / entrypoint pattern** (lines 22-48):
```elixir
use Mix.Task

@impl Mix.Task
def run(argv) do
  loadpaths()

  opts = Accrue.Install.Options.parse!(argv)
  project = Accrue.Install.Project.discover!(opts)
  validate_planned_config!(project)

  print_intro(opts)
  print_orchestration(project)

  results =
    if opts.dry_run or opts.manual or project.manual? do
      report("manual: review generated snippets before applying")
      print_manual_snippets(project, opts)
      []
    else
      install(project, opts)
    end

  print_summary(results, opts, project)
end
```

**Per-result reporting pattern** (lines 104-124, 134-149):
```elixir
template_results =
  project
  |> Accrue.Install.Templates.render_all(opts)
  |> Enum.map(fn {path, content} ->
    {status, reason} =
      Accrue.Install.Fingerprints.write(path, content,
        force: opts.force,
        dry_run: opts.dry_run
      )

    report("#{status}: #{Path.relative_to_cwd(path)} #{reason}")
    {status, path, reason}
  end)
```

```elixir
defp report_patch_result({:manual, path, reason, snippet}) do
  report("manual: #{Path.relative_to_cwd(path)} #{reason}")
  report(snippet)
  {:manual, path, reason}
end
```

**Redaction pattern** (lines 179-187):
```elixir
defp redact(message) do
  message
  |> to_string()
  |> String.replace(~r/sk_(test|live)_[A-Za-z0-9_=-]+/, "sk_\\1_[REDACTED]")
  |> String.replace(~r/whsec_[A-Za-z0-9_=-]+/, "whsec_[REDACTED]")
  |> String.replace(~r/([A-Z0-9_]*(?:SECRET|KEY)[A-Z0-9_]*=)[^\s,}]+/, "\\1[REDACTED]")
end

defp report(message), do: IO.puts(redact(message))
```

**Apply to Phase 12:** keep this task as the orchestration surface for `--check` or richer rerun summaries. Add normalized outcome atoms here instead of inventing a second installer reporter.

---

### `accrue/lib/accrue/install/fingerprints.ex` (utility, file-I/O)

**Analog:** `accrue/lib/accrue/install/fingerprints.ex`

**Stamped generated-file contract** (lines 6-23):
```elixir
@marker "# accrue:generated"
@fingerprint_prefix "# accrue:fingerprint:"

def stamp(content) when is_binary(content) do
  body = strip_fingerprint(content)
  fingerprint = fingerprint(body)

  [@marker, "#{@fingerprint_prefix} #{fingerprint}", body]
  |> Enum.join("\n")
  |> ensure_trailing_newline()
end
```

**No-clobber decision tree** (lines 44-70):
```elixir
def write(path, content, opts \\ []) when is_binary(content) do
  stamped = stamp(content)

  cond do
    Keyword.get(opts, :dry_run, false) ->
      {:skipped, "dry-run"}

    not File.exists?(path) ->
      do_write(path, stamped)
      {:changed, "created"}

    pristine?(path) ->
      do_write(path, stamped)
      {:changed, "updated pristine"}

    user_edited?(path) ->
      {:skipped, "user-edited"}

    Keyword.get(opts, :force, false) ->
      do_write(path, stamped)
      {:changed, "overwrote unmarked"}

    true ->
      {:skipped, "exists"}
  end
end
```

**Apply to Phase 12:** preserve this exact conditional ordering when widening outcome taxonomy. Conflict-artifact behavior should extend this contract, not weaken the `user-edited` skip branch.

---

### `accrue/lib/accrue/install/patches.ex` (service, file-I/O)

**Analog:** `accrue/lib/accrue/install/patches.ex`

**Structured patch-plan pattern** (lines 28-55):
```elixir
def build(project, opts) do
  [
    %{
      name: "Patches.router_webhook",
      path: project.router_path,
      snippet: router_snippet(opts),
      apply: &patch_router/3
    },
    %{
      name: "Patches.auth",
      path: project.config_path,
      snippet: auth_snippet(project),
      apply: &patch_auth_config/3
    },
    %{
      name: "Patches.test_support",
      path: Path.join(project.root, "test/support/accrue_case.ex"),
      snippet: test_support_snippet(),
      apply: &patch_test_support/3
    }
  ] ++ admin_patch(project, opts)
end
```

**Manual-fallback tuple contract** (lines 165-189, 222-239):
```elixir
defp patch_router(_project, _opts, %{path: nil, snippet: snippet}) do
  {:manual, nil, "router missing", snippet}
end

defp patch_test_support(_project, _opts, %{path: path, snippet: snippet}) do
  cond do
    File.exists?(path) and File.read!(path) =~ "use Accrue.Test" ->
      {:skipped, path, "test support already configured"}

    File.exists?(path) ->
      {:manual, path, "test support exists", snippet}

    true ->
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, snippet)
      {:changed, path, "Accrue test support"}
  end
end
```

**Safe patch helpers** (lines 241-260):
```elixir
defp ensure_import(content, module) do
  import_line = "  import #{module}\n"

  cond do
    content =~ "import #{module}" -> content
    Regex.match?(~r/^\s*use\s+[^,\n]+,\s*:router\s*$/m, content) ->
      Regex.replace(~r/^(\s*use\s+[^,\n]+,\s*:router\s*)$/m, content, "\\1\n#{import_line}",
        global: false
      )
    true -> content
  end
end
```

**Apply to Phase 12:** conflict artifacts should be produced from this structured patch layer, keeping `{:manual, path, reason, snippet}` as the planner-visible source of rendered sidecar output.

---

### `accrue/lib/accrue/setup_diagnostic.ex` (utility, transform)

**Analog:** `accrue/lib/accrue/errors.ex`

**Exception-module pattern** (lines 113-124):
```elixir
defmodule Accrue.ConfigError do
  @type t :: %__MODULE__{}
  defexception [:message, :key]

  @impl true
  def message(%__MODULE__{message: m}) when is_binary(m) and m != "", do: m
  def message(%__MODULE__{key: key}), do: "missing accrue config key: #{inspect(key)}"
end
```

**Human-readable error-message override pattern** (lines 39-47, 58-61, 107-110):
```elixir
@impl true
def message(%__MODULE__{message: m}) when is_binary(m) and m != "", do: m
```

**Apply to Phase 12:** build the diagnostic carrier like the repo’s existing exception modules: small struct, explicit fields, custom `message/1`, and no hidden formatting logic. Then let `Accrue.ConfigError` wrap or consume it.

---

### `accrue/test/mix/tasks/accrue_install_uat_test.exs` (test, request-response)

**Analog:** `accrue/test/mix/tasks/accrue_install_uat_test.exs`

**Installer UAT harness pattern** (lines 10-31, 147-154):
```elixir
setup do
  Mix.shell(Mix.Shell.Process)
  on_exit(fn -> Mix.shell(Mix.Shell.IO) end)
  :ok
end
```

```elixir
defp run_install(app, argv) do
  Mix.Task.clear()

  capture_io(fn ->
    InstallFixture.cd_preserving_code_path!(app, fn ->
      apply(Mix.Tasks.Accrue.Install, :run, [argv])
    end)
  end)
end
```

**Copy-paste assertions on host-generated files** (lines 43-59, 121-130):
```elixir
assert InstallFixture.assert_contains!(
         app,
         "lib/my_app/billing.ex",
         "defmodule MyApp.Billing"
       )
```

```elixir
router = InstallFixture.read!(app, "lib/my_app_web/router.ex")
assert router =~ ~s(accrue_admin "/ops/billing")
assert count_occurrences(router, ~s(accrue_admin "/ops/billing")) == 1
```

**Apply to Phase 12:** extend this file for rerun semantics, conflict-artifact output, and `--check`/doctor behavior before adding broader CI coverage elsewhere.

---

### `accrue/README.md` (config, request-response)

**Analog:** `accrue/README.md`

**Compact landing-page pattern** (lines 5-26):
```markdown
## Quickstart

Add Accrue to `deps/0`, configure the Stripe processor, then run the installer:

```elixir
defp deps do
  [
    {:accrue, "~> 0.1.2"}
  ]
end
```
```

**Guide-link index pattern** (lines 41-51):
```markdown
## Guides

- [Quickstart](guides/quickstart.md)
- [Configuration](guides/configuration.md)
- [Testing](guides/testing.md)
- [Upgrade](guides/upgrade.md)
```

**Apply to Phase 12:** keep README short and link into the new First Hour + troubleshooting guides instead of moving the full host walkthrough here.

---

### `accrue/guides/quickstart.md` and `accrue/guides/first_hour.md` (config, request-response)

**Analog:** `examples/accrue_host/README.md`

**Executable host-path ordering** (lines 9-26):
```markdown
## Rebuild From A Clean Checkout

From `examples/accrue_host`:

```bash
mix deps.get
mix accrue.install --yes --billable AccrueHost.Accounts.User --billing-context AccrueHost.Billing --admin-mount /billing --webhook-path /webhooks/stripe
mix ecto.create
mix ecto.migrate
mix test
mix phx.server
```
```

**Proof-focused defaults section** (lines 28-38):
```markdown
## Local Defaults

- The default local setup uses `Accrue.Processor.Fake`
- The default webhook signing secret is `whsec_test_host`
```

**Apply to Phase 12:** the new First Hour guide should mirror this exact order, then map each step back to public package APIs and guides.

---

### `accrue/guides/troubleshooting.md` (config, transform)

**Analog:** `accrue/guides/testing.md`

**Task-oriented guide shape** (lines 54-126):
```markdown
## Successful checkout
## Trial conversion
## Failed renewal and retry
## Cancellation/grace period
## Invoice email/PDF
## Webhook replay
## Background jobs
## Provider-parity tests
## Footguns
```

**Docs-testable copy pattern** (testing guide backed by string assertions in `accrue/test/accrue/docs/testing_guide_test.exs:21-80`):
```elixir
assert guide =~ "use Accrue.Test"
assert guide =~ "Process.sleep"
assert guide =~ "real Stripe sandbox calls"
```

**Apply to Phase 12:** write troubleshooting as stable headings and literal diagnostic codes/phrases that docs tests can assert directly.

---

### `accrue/guides/webhooks.md` (config, request-response)

**Analog:** `examples/accrue_host/lib/accrue_host_web/router.ex`

**Scoped raw-body pipeline pattern** (lines 71-84):
```elixir
pipeline :accrue_webhook_raw_body do
  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["*/*"],
    json_decoder: Jason,
    body_reader: {Accrue.Webhook.CachingBodyReader, :read_body, []},
    length: 1_000_000
  )
end

scope "/webhooks" do
  pipe_through(:accrue_webhook_raw_body)
  accrue_webhook("/stripe", :stripe)
end
```

**Public-handler boundary pattern** from `examples/accrue_host/lib/accrue_host/billing_handler.ex:10-31`:
```elixir
use Accrue.Webhook.Handler

@impl Accrue.Webhook.Handler
def handle_event(type, event, ctx) do
  ...
end
```

**Apply to Phase 12:** webhook docs should teach only this public router + handler boundary, not reducer or worker internals.

---

### `accrue/guides/upgrade.md` (config, request-response)

**Analog:** `accrue/guides/upgrade.md`

**Public-vs-private contract language** (lines 1-31):
```markdown
This guide defines the public upgrade contract for Accrue consumers.
...
It does not extend a compatibility promise to undocumented internals, private modules, or generated snippets that callers modified in their own host app.
```

**Verification block pattern** (lines 48-60):
```markdown
```bash
mix compile --warnings-as-errors
mix test --warnings-as-errors
mix docs --warnings-as-errors
```
```

**Apply to Phase 12:** generated-file ownership and rerun behavior should be documented with this same boundary-first language.

---

### `accrue/test/accrue/docs/first_hour_guide_test.exs` (test, transform)

**Analog:** `accrue/test/accrue/docs/testing_guide_test.exs`

**Guide-string assertion pattern** (lines 6-19, 21-32):
```elixir
@guide "guides/testing.md"

test "testing guide contains copy-paste public helper strings" do
  guide = File.read!(@guide)

  assert guide =~ "use Accrue.Test"
  assert guide =~ "MyApp.Billing"
end
```

**Heading-order assertion helper** (lines 82-87):
```elixir
defp index_of(binary, pattern) do
  case :binary.match(binary, pattern) do
    {index, _length} -> index
    :nomatch -> nil
  end
end
```

**Apply to Phase 12:** First Hour docs tests should assert the Phoenix-order sequence from D-12 and key public API strings from the host app.

---

### `accrue/test/accrue/docs/troubleshooting_guide_test.exs` (test, transform)

**Analog:** `accrue/test/accrue/docs/community_auth_test.exs`

**Literal checklist assertion pattern** (lines 17-30):
```elixir
for callback <- [
      "current_user/1",
      "require_admin_plug/0",
      "user_schema/0"
    ] do
  assert guide =~ callback
end
```

**Out-of-scope guard pattern** (lines 33-40):
```elixir
refute guide =~ "quickstart"
refute guide =~ "upgrade guide"
```

**Apply to Phase 12:** use this style to assert troubleshooting matrix rows contain stable diagnostic codes, fix text, and verification steps while excluding unrelated release messaging.

---

### `scripts/ci/verify_package_docs.sh` (utility, batch)

**Analog:** `scripts/ci/annotation_sweep.sh`

**Shell contract pattern** (lines 1-18, 39-55):
```bash
#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -eq 0 ]; then
  usage
  exit 2
fi
```

```bash
if [ -z "${GITHUB_REPOSITORY:-}" ] || [ -z "${GITHUB_RUN_ID:-}" ]; then
  echo "annotation_sweep.sh requires GITHUB_REPOSITORY and GITHUB_RUN_ID." >&2
  usage >&2
  exit 2
fi
```

**Structured parsing helper pattern** (lines 97-119, 134-167):
```bash
count="$(python3 - "$body_file" "$output_file" <<'PY'
import json
import sys
...
PY
)"
```

**Apply to Phase 12:** use a strict bash entrypoint with small embedded Python for metadata parsing instead of hand-rolled grep chains. This is the closest repo pattern for a release-facing verification script.

---

### `examples/accrue_host/mix.exs` (config, request-response)

**Analog:** `accrue_admin/mix.exs`

**Env-gated dependency-switch pattern** (lines 68-74):
```elixir
defp accrue_dep do
  if System.get_env("ACCRUE_ADMIN_HEX_RELEASE") == "1" do
    {:accrue, "~> #{@version}"}
  else
    {:accrue, path: "../accrue"}
  end
end
```

**Host deps list placement pattern** from `examples/accrue_host/mix.exs:41-72`:
```elixir
defp deps do
  [
    ...,
    {:accrue, path: "../../accrue"},
    {:accrue_admin, path: "../../accrue_admin"},
    ...
  ]
end
```

**Apply to Phase 12:** add dedicated helper functions like `accrue_dep/0` and `accrue_admin_dep/0` to the host app, matching `accrue_admin`’s env-switch style instead of inlining conditionals in the list.

---

### `scripts/ci/accrue_host_hex_smoke.sh` (utility, batch)

**Analog:** `scripts/ci/accrue_host_uat.sh`

**Release-facing shell style** (lines 19-26, 35-80):
```bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
host_dir="$repo_root/examples/accrue_host"

cd "$host_dir"

echo "--- documented setup: deps + installer idempotence ---"
mix deps.get
mix accrue.install --yes \
  --billable AccrueHost.Accounts.User \
  --billing-context AccrueHost.Billing \
  --admin-mount /billing \
  --webhook-path /webhooks/stripe
```

**Narrow proof-suite invocation pattern** (lines 67-76):
```bash
MIX_ENV=test mix test --warnings-as-errors \
  test/install_boundary_test.exs \
  test/accrue_host/billing_facade_test.exs \
  test/accrue_host_web/webhook_ingest_test.exs \
  test/accrue_host_web/admin_mount_test.exs
```

**Apply to Phase 12:** the Hex smoke should be a trimmed variant of this script, not a second full browser/UAT pipeline.

---

### `.github/workflows/ci.yml` (config, batch)

**Analog:** `.github/workflows/ci.yml`

**Multi-job release gate pattern** (lines 20-24, 215-217, 247-250):
```yaml
jobs:
  release-gate:
  admin-drift-docs:
  host-integration:
```

**Script-first workflow step pattern** (lines 315-316, 351-356):
```yaml
- name: Run host integration gate
  run: bash scripts/ci/accrue_host_uat.sh
```

```yaml
- name: Sweep release-facing annotations
  run: bash scripts/ci/annotation_sweep.sh release-gate admin-drift-docs host-integration
```

**Apply to Phase 12:** wire new docs verification and Hex smoke as explicit script steps, parallel to existing release-facing shell gates.

---

### `examples/accrue_host/lib/accrue_host/billing.ex` (service, CRUD)

**Analog:** `examples/accrue_host/lib/accrue_host/billing.ex`

**Thin host-facade pattern** (lines 3-30):
```elixir
defmodule AccrueHost.Billing do
  @moduledoc """
  Host-owned billing facade generated by `mix accrue.install`.
  """

  alias Accrue.Billing

  def subscribe(billable, price_id, opts \\ []) do
    Billing.subscribe(billable, price_id, opts)
  end

  def customer_for(billable) do
    Billing.customer(billable)
  end
end
```

**Apply to Phase 12:** new host-facing read helpers should follow this exact pattern: a small host-owned wrapper around `Accrue.Billing`, not direct schema or Repo teaching in docs.

## Shared Patterns

### No-clobber generated files
**Source:** `accrue/lib/accrue/install/fingerprints.ex` lines 44-70
**Apply to:** installer template writes, rerun summaries, conflict-artifact decisions
```elixir
cond do
  not File.exists?(path) -> {:changed, "created"}
  pristine?(path) -> {:changed, "updated pristine"}
  user_edited?(path) -> {:skipped, "user-edited"}
  Keyword.get(opts, :force, false) -> {:changed, "overwrote unmarked"}
  true -> {:skipped, "exists"}
end
```

### Manual patch / snippet fallback
**Source:** `accrue/lib/accrue/install/patches.ex` lines 222-239
**Apply to:** router/auth/test-support patch failures and `--write-conflicts`
```elixir
File.exists?(path) ->
  {:manual, path, "test support exists", snippet}
```

### Secret redaction
**Source:** `accrue/lib/mix/tasks/accrue.install.ex` lines 179-187 and `accrue/lib/accrue/install/fingerprints.ex` lines 72-82
**Apply to:** installer output, diagnostics, logs, troubleshooting examples, conflict artifacts
```elixir
|> String.replace(~r/sk_(test|live)_[A-Za-z0-9_=-]+/, "sk_\\1_[REDACTED]")
|> String.replace(~r/whsec_[A-Za-z0-9_=-]+/, "whsec_[REDACTED]")
|> String.replace(~r/([A-Z0-9_]*(?:SECRET|KEY)[A-Z0-9_]*=)[^\s,}]+/, "\\1[REDACTED]")
```

### Host-owned public boundaries
**Source:** `examples/accrue_host/test/install_boundary_test.exs` lines 12-49
**Apply to:** README/guides, facade helpers, host smoke tests
```elixir
assert billing =~ "defmodule AccrueHost.Billing do"
assert billing =~ "alias Accrue.Billing"
assert handler =~ "use Accrue.Webhook.Handler"
assert router =~ "import AccrueAdmin.Router"
assert router =~ "accrue_webhook(\"/stripe\", :stripe)"
```

### Docs tests assert literal strings, not rendered HTML
**Source:** `accrue/test/accrue/docs/testing_guide_test.exs` lines 21-80 and `accrue/test/accrue/docs/community_auth_test.exs` lines 6-40
**Apply to:** First Hour docs, troubleshooting docs, package drift checks
```elixir
guide = File.read!(@guide)
assert guide =~ "use Accrue.Test"
refute guide =~ "quickstart"
```

### Env-gated Hex dependency mode
**Source:** `accrue_admin/mix.exs` lines 68-74
**Apply to:** `examples/accrue_host/mix.exs`, Hex smoke scripts, publish validation
```elixir
if System.get_env("ACCRUE_ADMIN_HEX_RELEASE") == "1" do
  {:accrue, "~> #{@version}"}
else
  {:accrue, path: "../accrue"}
end
```

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `accrue/lib/accrue/setup_diagnostic.ex` | utility | transform | No existing shared diagnostic struct/service yet; only exception modules and scattered checks exist. Planner should synthesize it from `Accrue.ConfigError` plus installer redaction/reporting patterns. |

## Metadata

**Analog search scope:** `accrue/`, `accrue_admin/`, `examples/accrue_host/`, `scripts/ci/`, `.github/workflows/`

**Files scanned:** 923 tracked files, with focused reads across installer, diagnostics, docs, host app, and CI surfaces.

**Pattern extraction date:** 2026-04-16
