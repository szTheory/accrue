# Phase 228: Repair Stripe Webhook-Signing CI Boot Contract Under a Fresh Evidence Budget - Pattern Map

**Mapped:** 2026-08-28  
**Files analyzed:** 5  
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue/config/runtime.exs` | config | transform | `accrue/config/runtime.exs` | exact (extend existing test opt-in branch) |
| `.github/workflows/ci.yml` | config | event-driven | `.github/workflows/ci.yml` | exact (extend `live-stripe` job) |
| `scripts/ci/verify_provider_proof.mjs` | utility/test | file-I/O | `scripts/ci/verify_provider_proof.mjs` | exact (extend static contract fixtures) |
| `scripts/ci/verify_stripe_webhook_boot_evidence.mjs` | new utility/test | file-I/O + GitHub Actions API | `scripts/ci/verify_ci_critical_path.mjs` | role analog (repository-bound live verification, immutable URLs, job/artifact inventory, exhaustive fixtures) |
| `accrue/test/accrue/runtime_config_test.exs` | test | transform | `accrue/test/accrue/config_entitlements_test.exs` | role-match |
| `.planning/phases/228-repair-stripe-webhook-signing-ci-boot-contract-under-a-fresh/228-STRIPE-WEBHOOK-BOOT-EVIDENCE.md` (new, inferred) | model/document | event-driven | `.planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.md` | role-match |

The evidence-record filename is inferred because research requires a new sanitized Phase 228 record/schema but does not lock its exact filename. Keep it under this phase directory and do not alter Phase 227's historical record.

## Pattern Assignments

### `accrue/config/runtime.exs` (config, transform)

**Analog:** this file's existing live-Stripe test opt-in, lines 11-38.

**Environment-to-runtime-config pattern** (lines 22-38):

```elixir
if config_env() == :test do
  stripe_test_secret_key =
    "STRIPE_TEST_SECRET_KEY"
    |> System.get_env("")
    |> String.trim()

  if stripe_test_secret_key != "" do
    config :accrue,
      processor: Accrue.Processor.Stripe,
      stripe_secret_key: stripe_test_secret_key
  end
end
```

Extend this same branch: read `STRIPE_WEBHOOK_SECRET` once with the identical empty-default/trim pipeline, then configure it in the same `config :accrue` call as `webhook_signing_secrets: %{stripe: [stripe_webhook_secret]}`. Do not move this to `test_helper.exs`: runtime config is evaluated before application boot. Keep the no-key branch untouched so ordinary `mix test` remains Fake-backed.

**Boot validation consumer** (from `accrue/lib/accrue/config.ex`, lines 1243-1255):

```elixir
if Keyword.get(opts, :processor, Accrue.Processor.Fake) == Accrue.Processor.Stripe do
  _ = webhook_signing_secrets(:stripe)
end
```

The list value is intentional: `webhook_signing_secrets/1` accepts a nonempty list for secret rotation (`accrue/lib/accrue/config.ex`, lines 703-728).

---

### `.github/workflows/ci.yml` (config, event-driven)

**Analog:** the existing `live-stripe` job, lines 1262-1359.

**Job-level secret binding pattern** (lines 1284-1291):

```yaml
env:
  MIX_ENV: test
  PGUSER: postgres
  PGPASSWORD: postgres
  PGHOST: localhost
  STRIPE_TEST_SECRET_KEY: ${{ secrets.STRIPE_TEST_SECRET_KEY }}
  ACCRUE_LIVE_BASIC_PRICE: ${{ secrets.ACCRUE_LIVE_BASIC_PRICE }}
  ACCRUE_LIVE_PRO_PRICE: ${{ secrets.ACCRUE_LIVE_PRO_PRICE }}
```

Add only `STRIPE_WEBHOOK_SECRET: ${{ secrets.STRIPE_WEBHOOK_SECRET }}` to this job environment. It must not be passed as a command-line argument, summary field, artifact field, or fixture value.

**Fail-closed preflight pattern** (lines 1320-1329):

```yaml
- id: provider_preflight
  name: Preflight live-Stripe provider configuration
  run: |
    if [ -n "${STRIPE_TEST_SECRET_KEY:-}" ] && [ -n "${ACCRUE_LIVE_BASIC_PRICE:-}" ] && [ -n "${ACCRUE_LIVE_PRO_PRICE:-}" ]; then
      echo "configured=true" >> "$GITHUB_OUTPUT"
    else
      echo "configured=false" >> "$GITHUB_OUTPUT"
      echo "Live-Stripe configuration is incomplete; no credential values were printed." >&2
      exit 1
    fi
```

Add the signing-secret nonempty check to this same compound predicate; retain the generic error text and the `configured=true|false` output used by the finalizer.

**Failure-evidence preservation pattern** (lines 1335-1359):

```yaml
- id: provider_proof_finalize
  if: always()
  run: >-
    node scripts/ci/provider_proof.mjs --finalize --trigger "${{ github.event_name }}"
    --sha "${{ github.sha }}" --policy required --raw-conclusion "${{ job.status }}"
    --configured "${{ steps.provider_preflight.outputs.configured }}"
    --manifest "$RUNNER_TEMP/accrue-provider-manifest.json"
    --out "$ACCRUE_PROVIDER_PROOF_RECORD"

- id: provider_proof_artifact
  if: always()
  uses: actions/upload-artifact@v7
  with:
    name: live-stripe-proof
```

Do not change the stable job/step IDs, `if: always()` finalizer/summary/artifact behavior, proof record path, or artifact identity.

---

### `scripts/ci/verify_provider_proof.mjs` (utility/test, file-I/O)

**Analog:** this file's existing workflow parser and negative mutation fixtures, lines 15-100.

**Workflow fixture structure** (lines 15-48):

```javascript
const root = path.resolve(path.dirname(new URL(import.meta.url).pathname), "../..");
const workflowPath = path.join(root, ".github/workflows/ci.yml");

function jobBody(workflow, jobId) {
  const marker = `  ${jobId}:`;
  const start = workflow.indexOf(marker);
  assert.notEqual(start, -1, `missing stable job id: ${jobId}`);
  const rest = workflow.slice(start + marker.length);
  const nextOffset = rest.search(/\n  [A-Za-z0-9_-]+:/);
  return workflow.slice(start, nextOffset === -1 ? workflow.length : start + marker.length + nextOffset);
}

function stepRegion(job, stepId) {
  const marker = `id: ${stepId}`;
  const start = job.indexOf(marker);
  assert.notEqual(start, -1, `missing required step id: ${stepId}`);
  const next = job.indexOf("\n      - ", start + marker.length);
  return job.slice(start, next === -1 ? job.length : next);
}
```

**Contract assertions and adversarial mutations** (lines 54-100):

```javascript
const provider = jobBody(workflow, "live-stripe");
for (const stepId of ["provider_preflight", "live_stripe_suite", "provider_proof_finalize", "provider_proof_summary", "provider_proof_artifact"]) {
  const region = stepRegion(provider, stepId);
  if (stepId !== "provider_preflight" && stepId !== "live_stripe_suite") {
    assert.match(region, /if: always\(\)/, `${stepId} must always run`);
  }
}

for (const [name, mutate] of [
  ["write permission", (text) => text.replace("contents: read", "contents: write")],
  ["provider token", (text) => text.replace("id: provider_preflight", "id: provider_preflight\n        env:\n          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}")],
]) {
  rejects(() => assertWorkflowContract(mutate(workflow)), new RegExp(/* reason */));
}
```

Add positive literal assertions for the job environment binding and its preflight presence check, then negative mutations for a missing/renamed binding and a missing preflight term. Also assert the Phase 228 mandatory-provider shape: `workflow_dispatch.inputs` exposes exactly `run_live_stripe` for this path, the `live-stripe` manual branch is gated by `inputs.run_live_stripe`, and the `provider_proof.mjs --finalize` invocation passes neither `--bypass` nor a bypass-reason argument. The assertion messages and mutations must use secret/input/flag names only—never an environment value. Retain the existing read-only-token and no-mutation checks.

---

### `scripts/ci/verify_stripe_webhook_boot_evidence.mjs` (new utility/test, file-I/O + GitHub Actions API)

Use `scripts/ci/verify_ci_critical_path.mjs` as the role analog for dependency-free `gh api` access, current-repository binding, immutable run/job URLs, stable display-name normalization, bounded live inventory, artifact downloads in temporary directories, privacy field rejection, and mutation-driven fixtures. Keep Phase 228's verifier separate because its durable record is Markdown and its exact allowed tuples are provider-proof-specific.

Expose three explicit modes: `--fixtures`, `--verify-live-binding`, and `--verify-terminal`. Both live modes take explicit `--record`, `--repository`, `--sha`, `--dispatch-at`, and `--observed-at` arguments. Live binding independently proves workflow `CI`, event `workflow_dispatch`, attempt 1, SHA, immutable URL, creation inside the bounded window, the exact stable job `Stripe test-mode parity (mandatory periodic)`, and the named preflight/suite/finalizer/upload steps. The input consequence comes from execution of that input-gated job under a non-schedule event; record text is not input evidence.

Terminal mode independently fetches run, job, and artifact inventory, downloads `live-stripe-proof` to a temporary directory, parses `accrue-provider-proof.json` and `accrue-provider-manifest.json` when present, reconciles them to GitHub and the record, and leaves no downloaded raw artifact behind. Its fixtures cover positive and negative mutations for every exact-once field and every allowed tuple: complete proved evidence; the exact workflow-reachable created-run non-proved tuples (misconfigured, failed, and blocked variants with their canonical reason/raw/count/manifest/finalizer/artifact semantics); and a complete no-run rejection with all run/proof-only fields empty. Add `skipped` / `intentional_bypass` as an explicit negative fixture. Although the generic classifier can emit it, Phase 228 cannot reach it: the workflow has no bypass input, its workflow_dispatch run must execute the `run_live_stripe`-gated job, and its finalizer supplies no bypass flag or reason. Any such record is a blocking contract violation. Unknown, duplicate, conflicting, privacy-forbidden, retry, open-authority, count/manifest, identity, job/step, artifact, or bypass-impossibility mismatches fail closed.

### `accrue/test/accrue/runtime_config_test.exs` (test, transform)

**Analog:** `accrue/test/accrue/config_entitlements_test.exs`, lines 1-66.

**Process-global configuration isolation pattern** (lines 25-65):

```elixir
setup do
  prev_processor = Application.get_env(:accrue, :processor, :__unset__)

  prev_webhook_signing_secrets =
    Application.get_env(:accrue, :webhook_signing_secrets, :__unset__)

  Application.put_env(:accrue, :webhook_signing_secrets, %{
    stripe: ["whsec_config_entitlements_test"]
  })

  on_exit(fn ->
    for {key, value} <- [
          processor: prev_processor,
          webhook_signing_secrets: prev_webhook_signing_secrets
        ] do
      case value do
        :__unset__ -> Application.delete_env(:accrue, key)
        configured -> Application.put_env(:accrue, key, configured)
      end
    end
  end)

  :ok
end
```

The new focused test should be `async: false`, snapshot/restore every mutated environment and application-config key, use dummy `sk_test_...` and `whsec_...` inputs, evaluate the runtime-config path, and assert Stripe selection plus `%{stripe: [dummy_secret]}` before `Accrue.Config.validate_at_boot!/0`. It must make no Stripe/API request. The existing successful boot assertion is `assert Config.validate_at_boot!() == :ok` at lines 67-73 of that analog.

---

### `228-STRIPE-WEBHOOK-BOOT-EVIDENCE.md` (new inferred model/document, event-driven)

**Analog:** `.planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.md`, lines 1-15 and 64-72.

**Bounded-authority and immutable-evidence pattern** (lines 8-15):

```markdown
- state: `rollback_applied_unverified`
- owner: maintainer
- restoration run budget: `exhausted`
- additional dispatch authorized: `false`
- next command: none

No candidate rerun or replacement was launched. Exactly one restoration run was created
after the contract correction, and no further dispatch is authorized.
```

**Concrete recorded-outcome pattern** (lines 64-72):

```markdown
[33188858334](https://github.com/szTheory/accrue/actions/runs/33188858334) is that sole
attempt-1 `workflow_dispatch`, with `run_live_stripe: true`.

The three key/price preflight inputs passed. The provider job then failed before selecting
any live test because application boot raised `ACCRUE-DX-WEBHOOK-SECRET-MISSING`.
The emitted proof classifies this as `misconfigured` / `manifest_invalid`, with zero
selected tests and no manifest written.
```

Create a fresh Phase 228 record rather than changing this historical document. It states the repaired SHA, dispatch-at/observed-at window, trigger/input intent, one-authorized-first-attempt budget, created/consumed state, immutable run/job identity, workflow/event/job/step facts, raw conclusion, proof state/reason, selected/passed/failed/skipped counts, manifest totals/timestamps, finalizer and `live-stripe-proof` artifact facts, retry/authority closure, and a clear outcome. Every applicable field occurs exactly once. A no-run rejection retains the full sanitized dispatch-intent tuple but leaves every run/job/conclusion/count/manifest/artifact/proof-only field empty. Keep it sanitized: no secret values, raw logs, payloads, actors, endpoint identifiers, or secret-presence details. Link the Phase 227 failure strictly as history.

## Shared Patterns

### Boot-time signing-secret validation

**Sources:** `accrue/config/runtime.exs:22-38`; `accrue/lib/accrue/config.ex:703-728,1243-1255`  
**Apply to:** runtime mapping and its no-network test.

```elixir
case Map.fetch(secrets_map, processor) do
  {:ok, secrets} when is_list(secrets) and secrets != [] ->
    secrets
  {:ok, secret} when is_binary(secret) and secret != "" ->
    secret
  _ ->
    raise Accrue.ConfigError, key: :webhook_signing_secrets, diagnostic: diagnostic
end
```

Supply the endpoint secret as a nonempty list under `:stripe`; do not weaken the existing fail-closed validator or substitute an API key.

### Privacy-safe CI configuration failure

**Sources:** `.github/workflows/ci.yml:1320-1329`; `scripts/ci/verify_provider_proof.mjs:83-100`  
**Apply to:** CI preflight, verifier fixtures, and Phase 228 record.

```sh
echo "configured=false" >> "$GITHUB_OUTPUT"
echo "Live-Stripe configuration is incomplete; no credential values were printed." >&2
exit 1
```

Check only nonempty presence via shell parameter expansion. Preserve generic diagnostics and test name-level strings, never value-level output.

### Always-run provider evidence

**Sources:** `.github/workflows/ci.yml:1335-1359`; `scripts/ci/verify_provider_proof.mjs:63-80`  
**Apply to:** the CI change and final evidence record.

The preflight may fail, but finalization, summary, and artifact upload remain `if: always()`. A raw successful job alone is not proof; only the existing finalizer can classify a selected, passed suite with a manifest as `proved`.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| None | — | — | Every production, test, and evidence responsibility has a close in-repository analog. |

## Metadata

**Analog search scope:** `accrue/config`, `accrue/lib/accrue`, `accrue/test`, `.github/workflows`, `scripts/ci`, and Phase 226–227 evidence artifacts.  
**Files scanned:** 10 focused files plus repository-wide pattern searches.  
**Pattern extraction date:** 2026-08-28
