# Phase 14: Adoption Front Door - Pattern Map

**Mapped:** 2026-04-16
**Files analyzed:** 23
**Analogs found:** 18 / 23

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `README.md` | documentation | request-response | `accrue/README.md` | role-match |
| `accrue/README.md` | documentation | request-response | `accrue/README.md` | exact |
| `accrue_admin/README.md` | documentation | request-response | `accrue_admin/README.md` | exact |
| `examples/accrue_host/README.md` | documentation | request-response | `examples/accrue_host/README.md` | exact |
| `accrue/guides/first_hour.md` | documentation | request-response | `accrue/guides/first_hour.md` | exact |
| `accrue/guides/testing.md` | documentation | request-response | `accrue/guides/testing.md` | exact |
| `accrue/guides/webhooks.md` | documentation | request-response | `accrue/guides/webhooks.md` | exact |
| `accrue/guides/troubleshooting.md` | documentation | request-response | `accrue/guides/troubleshooting.md` | exact |
| `accrue/guides/upgrade.md` | documentation | request-response | `accrue/guides/upgrade.md` | exact |
| `accrue_admin/guides/admin_ui.md` | documentation | request-response | `accrue_admin/guides/admin_ui.md` | exact |
| `.github/ISSUE_TEMPLATE/config.yml` | config | request-response | none in repo | no-analog |
| `.github/ISSUE_TEMPLATE/bug.yml` | config | request-response | none in repo | no-analog |
| `.github/ISSUE_TEMPLATE/integration-problem.yml` | config | request-response | none in repo | no-analog |
| `.github/ISSUE_TEMPLATE/documentation-gap.yml` | config | request-response | none in repo | no-analog |
| `.github/ISSUE_TEMPLATE/feature-request.yml` | config | request-response | none in repo | no-analog |
| `RELEASING.md` | documentation | batch | `RELEASING.md` | exact |
| `CONTRIBUTING.md` | documentation | request-response | `CONTRIBUTING.md` | exact |
| `SECURITY.md` | documentation | request-response | `SECURITY.md` | exact |
| `scripts/ci/verify_package_docs.sh` | utility | transform | `scripts/ci/verify_package_docs.sh` | exact |
| `accrue/test/accrue/docs/package_docs_verifier_test.exs` | test | batch | `accrue/test/accrue/docs/package_docs_verifier_test.exs` | exact |
| `accrue/test/accrue/docs/first_hour_guide_test.exs` | test | transform | `accrue/test/accrue/docs/first_hour_guide_test.exs` | exact |
| `accrue/test/accrue/docs/canonical_demo_contract_test.exs` | test | transform | `accrue/test/accrue/docs/canonical_demo_contract_test.exs` | exact |
| `accrue/test/accrue/docs/root_readme_contract_test.exs` | test | transform | `accrue/test/accrue/docs/canonical_demo_contract_test.exs` | role-match |

## Pattern Assignments

### `README.md` (documentation, request-response)

**Analog:** `accrue/README.md`

**Front-door identity + route-map pattern** ([`accrue/README.md:1`](/Users/jon/projects/accrue/accrue/README.md:1), [`accrue/README.md:8`](/Users/jon/projects/accrue/accrue/README.md:8), [`accrue/README.md:58`](/Users/jon/projects/accrue/accrue/README.md:58))
```markdown
# Accrue

Billing state, modeled clearly.

## Start Here

- [First Hour](guides/first_hour.md)
- [Troubleshooting](guides/troubleshooting.md)
- [Webhooks](guides/webhooks.md)
- [Upgrade](guides/upgrade.md)

## Public API stability

The supported public setup surface for first-time integration is:
```

**Canonical verification-label pattern** ([`accrue/README.md:45`](/Users/jon/projects/accrue/accrue/README.md:45))
```markdown
- `mix verify` for the focused tutorial proof suite
- `mix verify.full` for the CI-equivalent local gate
- `bash scripts/ci/accrue_host_uat.sh` for the repo-root wrapper around that full gate
```

**Closest secondary analog for proof-first walkthrough wording:** [`examples/accrue_host/README.md:1`](/Users/jon/projects/accrue/examples/accrue_host/README.md:1)

---

### `accrue/README.md` (documentation, request-response)

**Analog:** `accrue/README.md`

**Compact package landing pattern** ([`accrue/README.md:5`](/Users/jon/projects/accrue/accrue/README.md:5), [`accrue/README.md:15`](/Users/jon/projects/accrue/accrue/README.md:15))
```markdown
Accrue is the billing library. Your Phoenix app owns the generated `MyApp.Billing`
facade, router mounts, runtime config, and auth/session boundary.

The compact adoption path is:

1. Install `accrue` in your Phoenix app.
2. Follow the [First Hour](guides/first_hour.md) guide...
3. Compare that setup with the checked-in [`examples/accrue_host`](../examples/accrue_host) demo path.
```

**Public-boundary list pattern** ([`accrue/README.md:58`](/Users/jon/projects/accrue/accrue/README.md:58))
```markdown
- your generated `MyApp.Billing`
- `use Accrue.Webhook.Handler`
- `use Accrue.Test`
- `AccrueAdmin.Router.accrue_admin/2`
- `Accrue.ConfigError` for setup failures
```

**Guide index pattern** ([`accrue/README.md:70`](/Users/jon/projects/accrue/accrue/README.md:70))
```markdown
## Guides

- [Quickstart](guides/quickstart.md)
- [First Hour](guides/first_hour.md)
- [Troubleshooting](guides/troubleshooting.md)
- [Configuration](guides/configuration.md)
- [Testing](guides/testing.md)
```

---

### `accrue_admin/README.md` and `accrue_admin/guides/admin_ui.md` (documentation, request-response)

**Analogs:** `accrue_admin/README.md`, `accrue_admin/guides/admin_ui.md`

**Admin-specific quickstart pattern** ([`accrue_admin/README.md:5`](/Users/jon/projects/accrue/accrue_admin/README.md:5))
```markdown
## Quickstart

Add `accrue_admin` to your host application and mount the package router where operators manage billing:
```

**Auth/session boundary pattern** ([`accrue_admin/guides/admin_ui.md:48`](/Users/jon/projects/accrue/accrue_admin/guides/admin_ui.md:48))
```markdown
`Accrue.Auth` must be able to resolve the current operator from the forwarded
session data, and `session_keys: [:user_token]` is the supported host boundary
for the standard Phoenix auth flow.

Keep `accrue_admin "/billing"` inside the authenticated browser
scope so `/billing` inherits the same auth boundary as the rest of the app.
```

**Operator-focused structure pattern** ([`accrue_admin/guides/admin_ui.md:27`](/Users/jon/projects/accrue/accrue_admin/guides/admin_ui.md:27), [`accrue_admin/guides/admin_ui.md:59`](/Users/jon/projects/accrue/accrue_admin/guides/admin_ui.md:59), [`accrue_admin/guides/admin_ui.md:75`](/Users/jon/projects/accrue/accrue_admin/guides/admin_ui.md:75))
```markdown
`accrue_admin "/billing"` creates:

- hashed package asset routes under `/billing/assets/*`
- the main billing LiveView routes under `/billing/*`
- compile-gated dev routes under `/billing/dev/*` only outside `MIX_ENV=prod`
```

---

### `examples/accrue_host/README.md` and `accrue/guides/first_hour.md` (documentation, request-response)

**Analogs:** `examples/accrue_host/README.md`, `accrue/guides/first_hour.md`

**Canonical local demo / mirrored guide split** ([`examples/accrue_host/README.md:1`](/Users/jon/projects/accrue/examples/accrue_host/README.md:1), [`accrue/guides/first_hour.md:1`](/Users/jon/projects/accrue/accrue/guides/first_hour.md:1))
```markdown
This checked-in Phoenix app is the canonical local evaluation path...

This guide mirrors the checked-in `examples/accrue_host` story in package-facing
terms.
```

**Ordered proof-story pattern** ([`examples/accrue_host/README.md:29`](/Users/jon/projects/accrue/examples/accrue_host/README.md:29), [`accrue/guides/first_hour.md:123`](/Users/jon/projects/accrue/accrue/guides/first_hour.md:123))
```markdown
1. Sign in, open the host-owned billing screen...
2. Post one signed webhook through the real `/webhooks/stripe` endpoint.
3. Visit `/billing` as a billing admin...
4. Run the focused proof suite...
```

**Copy-paste-safe public boundary pattern** ([`accrue/guides/first_hour.md:71`](/Users/jon/projects/accrue/accrue/guides/first_hour.md:71))
```elixir
defmodule MyApp.BillingHandler do
  use Accrue.Webhook.Handler

  @impl Accrue.Webhook.Handler
  def handle_event(type, event, ctx) do
    MyApp.Billing.handle_webhook(type, event, ctx)
  end
end
```

**Mode-label pattern** ([`examples/accrue_host/README.md:63`](/Users/jon/projects/accrue/examples/accrue_host/README.md:63), [`accrue/guides/first_hour.md:168`](/Users/jon/projects/accrue/accrue/guides/first_hour.md:168))
```markdown
- `mix verify` is the focused local proof suite...
- `mix verify.full` is the CI-equivalent local gate...
- `bash scripts/ci/accrue_host_uat.sh` is the thin repo-root wrapper...
```

---

### `accrue/guides/testing.md` (documentation, request-response)

**Analog:** `accrue/guides/testing.md`

**Fake-first / provider-parity split** ([`accrue/guides/testing.md:3`](/Users/jon/projects/accrue/accrue/guides/testing.md:3), [`accrue/guides/testing.md:92`](/Users/jon/projects/accrue/accrue/guides/testing.md:92), [`accrue/guides/testing.md:108`](/Users/jon/projects/accrue/accrue/guides/testing.md:108))
```markdown
## Fake-first Phoenix scenario
...
## Provider-parity tests
...
## External-provider appendix
```

**Host-visible helper pattern** ([`accrue/guides/testing.md:7`](/Users/jon/projects/accrue/accrue/guides/testing.md:7))
```elixir
defmodule MyApp.BillingTest do
  use MyApp.DataCase, async: true
  use Accrue.Test
  use Oban.Testing, repo: MyApp.Repo
```

**No-secrets / no-live-by-default warnings** ([`accrue/guides/testing.md:110`](/Users/jon/projects/accrue/accrue/guides/testing.md:110), [`accrue/guides/testing.md:118`](/Users/jon/projects/accrue/accrue/guides/testing.md:118))
```markdown
Never make real Stripe sandbox calls by default in the main unit or context suite.
...
Keep environment variable names explicit and never paste real keys into examples.
```

---

### `accrue/guides/webhooks.md` and `accrue/guides/troubleshooting.md` (documentation, request-response)

**Analogs:** `accrue/guides/webhooks.md`, `accrue/guides/troubleshooting.md`

**Webhook route/raw-body pattern** ([`accrue/guides/webhooks.md:10`](/Users/jon/projects/accrue/accrue/guides/webhooks.md:10), [`accrue/guides/troubleshooting.md:111`](/Users/jon/projects/accrue/accrue/guides/troubleshooting.md:111))
```elixir
pipeline :accrue_webhook_raw_body do
  plug Plug.Parsers,
    parsers: [:json],
    pass: ["*/*"],
    json_decoder: Jason,
    body_reader: {Accrue.Webhook.CachingBodyReader, :read_body, []}
end
```

**Diagnostic matrix pattern** ([`accrue/guides/troubleshooting.md:7`](/Users/jon/projects/accrue/accrue/guides/troubleshooting.md:7))
```markdown
| Code | What happened | Why Accrue cares | Fix | How to verify |
| --- | --- | --- | --- | --- |
```

**Stable-code / verify-command pattern** ([`accrue/guides/troubleshooting.md:132`](/Users/jon/projects/accrue/accrue/guides/troubleshooting.md:132))
```markdown
## `ACCRUE-DX-OBAN-NOT-SUPERVISED`
...
### How to verify

```bash
mix accrue.install --check
mix test test/accrue_host_web/webhook_ingest_test.exs
```
```

---

### `accrue/guides/upgrade.md`, `RELEASING.md`, `CONTRIBUTING.md`, `SECURITY.md` (documentation, batch/request-response)

**Analogs:** same-file exact matches

**Generated-files ownership pattern** ([`accrue/guides/upgrade.md:8`](/Users/jon/projects/accrue/accrue/guides/upgrade.md:8))
```markdown
`mix accrue.install` generates host-facing files such as `MyApp.Billing`,
router mounts, and starter config snippets. Those generated code paths are
host-owned after generation.
```

**Release-lane checklist pattern** ([`RELEASING.md:16`](/Users/jon/projects/accrue/RELEASING.md:16))
```markdown
## Release PR review checklist

- Both package release PRs show `@version "1.0.0"`...
- `accrue` publishes before `accrue_admin`.
- `RELEASE_PLEASE_TOKEN` and `HEX_API_KEY` exist only as GitHub Actions secrets.
```

**Contributor gate pattern** ([`CONTRIBUTING.md:42`](/Users/jon/projects/accrue/CONTRIBUTING.md:42))
```markdown
## Running the release gate locally

mix format --check-formatted
mix compile --warnings-as-errors
mix test --warnings-as-errors
mix credo --strict
mix dialyzer
mix docs --warnings-as-errors
mix hex.audit
```

**Private-report / secret-redaction pattern** ([`SECURITY.md:14`](/Users/jon/projects/accrue/SECURITY.md:14), [`SECURITY.md:30`](/Users/jon/projects/accrue/SECURITY.md:30))
```markdown
Open a private GitHub security advisory...
Do not open a public GitHub issue for unpatched vulnerabilities.

Webhook secrets, Hex API keys, and Release Please tokens must never be
committed to the repository or printed in CI logs.
```

---

### `scripts/ci/verify_package_docs.sh` (utility, transform)

**Analog:** `scripts/ci/verify_package_docs.sh`

**Small helper + fixed-string invariant pattern** ([`scripts/ci/verify_package_docs.sh:9`](/Users/jon/projects/accrue/scripts/ci/verify_package_docs.sh:9), [`scripts/ci/verify_package_docs.sh:23`](/Users/jon/projects/accrue/scripts/ci/verify_package_docs.sh:23), [`scripts/ci/verify_package_docs.sh:46`](/Users/jon/projects/accrue/scripts/ci/verify_package_docs.sh:46))
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

**Contract-style assertions pattern** ([`scripts/ci/verify_package_docs.sh:71`](/Users/jon/projects/accrue/scripts/ci/verify_package_docs.sh:71), [`scripts/ci/verify_package_docs.sh:95`](/Users/jon/projects/accrue/scripts/ci/verify_package_docs.sh:95))
```bash
require_fixed "$ROOT_DIR/accrue/README.md" '[First Hour](guides/first_hour.md)'
...
require_fixed "$ROOT_DIR/accrue/guides/first_hour.md" "mix verify.full"
...
require_absent_regex "$guide" 'webhook_signing_secret([^s]|$)'
```

---

### `accrue/test/accrue/docs/*.exs` (test, transform/batch)

**Analogs:** `package_docs_verifier_test.exs`, `first_hour_guide_test.exs`, `canonical_demo_contract_test.exs`

**Shell-wrapper test pattern** ([`accrue/test/accrue/docs/package_docs_verifier_test.exs:6`](/Users/jon/projects/accrue/accrue/test/accrue/docs/package_docs_verifier_test.exs:6))
```elixir
{output, status} = System.cmd("bash", [@script_path], stderr_to_stdout: true)

assert status == 0
assert output =~ "package docs verified"
```

**Fixture-copy drift test pattern** ([`accrue/test/accrue/docs/package_docs_verifier_test.exs:14`](/Users/jon/projects/accrue/accrue/test/accrue/docs/package_docs_verifier_test.exs:14))
```elixir
tmp_dir = Path.join(System.tmp_dir!(), "accrue-docs-verifier-#{System.unique_integer([:positive])}")
...
copy_fixture!("examples/accrue_host/README.md", tmp_dir)
...
assert status != 0
assert output =~ "mix verify.full"
```

**Manifest-backed wording/order test pattern** ([`accrue/test/accrue/docs/first_hour_guide_test.exs:23`](/Users/jon/projects/accrue/accrue/test/accrue/docs/first_hour_guide_test.exs:23), [`accrue/test/accrue/docs/canonical_demo_contract_test.exs:9`](/Users/jon/projects/accrue/accrue/test/accrue/docs/canonical_demo_contract_test.exs:9))
```elixir
assert_order!(guide, [
  first_run.label,
  "MyApp.Billing.subscribe",
  ...
  seeded_history.label
])

Enum.each(@public_surfaces, fn surface ->
  assert guide =~ surface
end)
```

**Recommended copy target for a new root README contract test:** use the same `assert_order!/2`, fixture-copy, and `Enum.each` surface-list patterns from [`accrue/test/accrue/docs/canonical_demo_contract_test.exs:114`](/Users/jon/projects/accrue/accrue/test/accrue/docs/canonical_demo_contract_test.exs:114) and [`accrue/test/accrue/docs/first_hour_guide_test.exs:43`](/Users/jon/projects/accrue/accrue/test/accrue/docs/first_hour_guide_test.exs:43).

---

### `.github/ISSUE_TEMPLATE/*.yml` and `.github/ISSUE_TEMPLATE/config.yml` (config, request-response)

**Analog:** none in repo

**Use local tone sources instead of a structural analog:**
- Sanitization language from [`SECURITY.md:30`](/Users/jon/projects/accrue/SECURITY.md:30)
- Public-boundary wording from [`accrue/README.md:58`](/Users/jon/projects/accrue/accrue/README.md:58)
- Integration-failure framing from [`accrue/guides/troubleshooting.md:7`](/Users/jon/projects/accrue/accrue/guides/troubleshooting.md:7)

**Copyable content fragments**
```markdown
Do not paste API keys, webhook secrets, production payloads, or customer data.
```

```markdown
The supported public setup surface for first-time integration is:
- your generated `MyApp.Billing`
- `use Accrue.Webhook.Handler`
- `use Accrue.Test`
- `AccrueAdmin.Router.accrue_admin/2`
- `Accrue.ConfigError`
```

Planner note: issue forms are a platform-specific new surface here. Follow GitHub issue-form syntax from research, but keep wording aligned to the local docs above.

## Shared Patterns

### Public boundary contract
**Sources:** [`accrue/README.md:58`](/Users/jon/projects/accrue/accrue/README.md:58), [`accrue/guides/first_hour.md:71`](/Users/jon/projects/accrue/accrue/guides/first_hour.md:71), [`accrue/guides/upgrade.md:8`](/Users/jon/projects/accrue/accrue/guides/upgrade.md:8)
**Apply to:** `README.md`, `accrue/README.md`, `examples/accrue_host/README.md`, `accrue/guides/first_hour.md`, issue forms, `RELEASING.md`
```markdown
- generated `MyApp.Billing`
- `use Accrue.Webhook.Handler`
- `use Accrue.Test`
- `AccrueAdmin.Router.accrue_admin/2`
- `Accrue.ConfigError`
```

### Fake / provider-parity / advisory mode labeling
**Sources:** [`examples/accrue_host/README.md:63`](/Users/jon/projects/accrue/examples/accrue_host/README.md:63), [`accrue/guides/testing.md:92`](/Users/jon/projects/accrue/accrue/guides/testing.md:92), [`CONTRIBUTING.md:65`](/Users/jon/projects/accrue/CONTRIBUTING.md:65)
**Apply to:** `README.md`, `accrue/README.md`, `accrue/guides/testing.md`, `RELEASING.md`, `CONTRIBUTING.md`
```markdown
- `mix verify` ...
- `mix verify.full` ...
- Stripe test mode for provider parity only
- live Stripe as advisory/manual, not default CI or first-run guidance
```

### Secrets / sanitized intake
**Sources:** [`SECURITY.md:30`](/Users/jon/projects/accrue/SECURITY.md:30), [`accrue/guides/testing.md:123`](/Users/jon/projects/accrue/accrue/guides/testing.md:123), [`accrue/guides/troubleshooting.md:97`](/Users/jon/projects/accrue/accrue/guides/troubleshooting.md:97)
**Apply to:** issue forms, `SECURITY.md`, `CONTRIBUTING.md`, `RELEASING.md`, webhook docs
```markdown
Keep Stripe API keys, signing secrets, and release credentials in runtime
environment variables or the CI secret store.
```

### Drift-check implementation style
**Sources:** [`scripts/ci/verify_package_docs.sh:23`](/Users/jon/projects/accrue/scripts/ci/verify_package_docs.sh:23), [`accrue/test/accrue/docs/package_docs_verifier_test.exs:14`](/Users/jon/projects/accrue/accrue/test/accrue/docs/package_docs_verifier_test.exs:14)
**Apply to:** verifier-script extension and new/updated docs tests
```bash
require_fixed "$ROOT_DIR/<file>" "<needle>"
require_absent_regex "$ROOT_DIR/<file>" '<pattern>'
```

```elixir
copy_fixture!(relative_path, tmp_dir)
assert status != 0
assert output =~ "<missing invariant>"
```

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `.github/ISSUE_TEMPLATE/config.yml` | config | request-response | No existing issue-form or chooser config in repo. |
| `.github/ISSUE_TEMPLATE/bug.yml` | config | request-response | No existing issue-form YAML in repo. |
| `.github/ISSUE_TEMPLATE/integration-problem.yml` | config | request-response | No existing issue-form YAML in repo. |
| `.github/ISSUE_TEMPLATE/documentation-gap.yml` | config | request-response | No existing issue-form YAML in repo. |
| `.github/ISSUE_TEMPLATE/feature-request.yml` | config | request-response | No existing issue-form YAML in repo. |

## Metadata

**Analog search scope:** repo root docs, `accrue/`, `accrue_admin/`, `examples/`, `.github/`, `scripts/ci/`, `accrue/test/accrue/docs/`

**Files scanned:** 18 primary analog files plus phase inputs and repo guidance

**Pattern extraction date:** 2026-04-16
