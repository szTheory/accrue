# Phase 124: Enforcement Surfaces — Plug + LiveView Guards - Pattern Map

**Mapped:** 2026-05-23
**Files analyzed:** 14 (4 NEW source, 4 EDIT source, 5 NEW tests, 1 NEW CI script; plus doc-only edits)
**Analogs found:** 14 / 14 (every file has a verified in-tree analog)

> **Path correction (load-bearing):** RESEARCH.md and the prompt say the new CI gate goes at
> `accrue/scripts/ci/verify_core_liveview_runtime_free.sh`. That directory **does not exist**. All
> existing verify scripts live at **repo-root** `/Users/jon/projects/accrue/scripts/ci/` and are invoked
> from `.github/workflows/ci.yml` as `bash scripts/ci/<name>.sh` (cwd = repo root). Put the new gate at
> `scripts/ci/verify_core_liveview_runtime_free.sh` (repo root), not under `accrue/`. The script's `lib`
> variable must therefore point at `${repo_root}/accrue/lib` (repo_root is two levels up from `scripts/ci/`).

> **Second correction:** there is **no `accrue/test/accrue/router_test.exs`** today (verified missing).
> The macro-expansion test is a NEW file, not an extension.

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| NEW `accrue/lib/accrue/plug/require_entitlement.ex` | middleware (Plug) | request-response | `accrue/lib/accrue/plug/put_connected_account.ex` (init/raise) + `accrue/lib/accrue/webhook/plug.ex` (pure-Plug deny) | exact (role+flow) |
| NEW `accrue/lib/accrue/entitlements/guard.ex` | service (decision engine) | request-response / transform | `accrue/lib/accrue/entitlements.ex` (fail-closed gate + `span/5` builder) | role-match |
| NEW `accrue/lib/accrue/live/entitlements.ex` (cond-compiled) | middleware (LiveView `on_mount`) | event-driven (mount lifecycle) | `accrue/lib/accrue/integrations/sigra.ex` (cond-compile 4-pattern) + `accrue_admin/lib/accrue_admin/auth_hook.ex` (`on_mount/4` shape) | exact (composite) |
| EDIT `accrue/lib/accrue/router.ex` | route (router macro) | request-response | existing `accrue_webhook/2` macro in the same file (lines 45-49) | exact |
| EDIT `accrue/lib/accrue/config.ex` | config | n/a | existing `:entitlements` schema block (lines 356-401) + `validate_descending/1` custom validator (951) | exact |
| EDIT `accrue/lib/accrue/telemetry/otel.ex` | config (allowlist) | n/a | existing `@allowed_attributes` dual atom+string map (lines 12-41) | exact |
| EDIT `accrue/lib/accrue/entitlements.ex` (additive `opts`) | service | n/a | its own `entitled?/2` + `span/5` (lines 48-64, 213-224) | self |
| NEW `scripts/ci/verify_core_liveview_runtime_free.sh` | config (CI gate) | batch | `scripts/ci/verify_processor_support_matrix.sh` (grep merge-gate shape) | role-match |
| EDIT `.github/workflows/ci.yml` (`docs-contracts-shift-left`) | config (CI) | n/a | existing verify-step block (lines 41-65) | exact |
| NEW `accrue/test/accrue/plug/require_entitlement_test.exs` | test | request-response | (no plug test in-tree — use `Plug.Test`; see Shared Patterns) | role-partial |
| NEW `accrue/test/accrue/live/entitlements_test.exs` | test | event-driven | `accrue/test/accrue/integrations/sigra_test.exs` (source-assertion) | role-match |
| NEW `accrue/test/accrue/entitlements/guard_test.exs` | test | request-response | `accrue/test/property/entitlements_fail_closed_property_test.exs` (setup/env-restore idiom) | role-match |
| NEW `accrue/test/property/guard_fail_closed_property_test.exs` | test (property) | transform | `accrue/test/property/entitlements_fail_closed_property_test.exs` | exact (clone) |
| EDIT (doc-only) `accrue/lib/accrue/oban/middleware.ex` + `CLAUDE.md` + `.planning/{ROADMAP,REQUIREMENTS}.md` + `.planning/research/PITFALLS.md` + `accrue/mix.exs:78-80` | doc | n/a | the D-06 lockstep wording fix (see Shared Patterns → Doc reconciliation) | n/a |

---

## Pattern Assignments

### `accrue/lib/accrue/plug/require_entitlement.ex` (middleware, request-response)

**Analogs:** `accrue/lib/accrue/plug/put_connected_account.ex` (init validate-and-raise) + `accrue/lib/accrue/webhook/plug.ex` (pure-Plug `send_resp`+`Jason.encode!`+`halt`).

**Behaviour + import header — clone from `put_operation_id.ex:33-35` / `webhook/plug.ex:23-25`:**
```elixir
@behaviour Plug
import Plug.Conn
```

**`init/1` validate-and-raise — clone the exact `case … raise ArgumentError` shape from `put_connected_account.ex:33-48`:**
```elixir
@impl true
def init(opts) when is_list(opts) do
  case Keyword.fetch(opts, :from) do
    {:ok, {mod, fun, args}} when is_atom(mod) and is_atom(fun) and is_list(args) ->
      opts

    {:ok, other} ->
      raise ArgumentError,
            "Accrue.Plug.PutConnectedAccount expected `:from` to be an MFA tuple " <>
              "{Module, :function, args}, got: #{inspect(other)}"

    :error ->
      raise ArgumentError,
            "Accrue.Plug.PutConnectedAccount requires a `:from` MFA tuple option"
  end
end
```
> Mirror this for the "exactly one of `feature:`/`plan:`" rule (D-07): match on
> `{Keyword.fetch(opts, :feature), Keyword.fetch(opts, :plan)}`, return `opts` on the valid leg, `raise
> ArgumentError` on both-present / neither-present / wrong-type. Do NOT validate `billable:`/`on_deny:`/`status:`
> shapes beyond presence (D-08/D-14: bad runtime values fail closed by construction).

**`call/2` delegate-to-engine — keep it thin (RESEARCH Pattern 1); mirror `put_connected_account.ex:50-71` `apply`-then-`case` discipline but delegate to the Guard:**
```elixir
@impl true
def call(conn, opts) do
  case Accrue.Entitlements.Guard.check(:plug, conn, opts) do
    {:allow, conn}          -> conn
    {:deny, deny_form, ctx} -> Accrue.Entitlements.Guard.deny_plug(conn, deny_form, ctx, opts)
  end
end
```

**Pure-Plug deny — clone the JSON-vs-text idiom from `webhook/plug.ex:51-53` (NEVER `Phoenix.Controller`; `phoenix` is `optional: true`, mix.exs:77):**
```elixir
# webhook/plug.ex:51-53 — the proven bare send_resp + Jason.encode! + halt:
conn
|> send_resp(400, Jason.encode!(%{error: "signature_verification_failed"}))
|> halt()
```
> Content-negotiate by reading the accept header directly — `webhook/plug.ex:65` already uses
> `get_req_header(conn, "stripe-signature") |> List.first()`; the deny path uses
> `get_req_header(conn, "accept") |> Enum.any?(&String.contains?(&1, "json"))`. JSON → `Jason.encode!(%{error:
> "forbidden"})`; else `text/plain "Forbidden"`. Body stays **opaque** (D-10) — never echo feature/plan.

**Security-comment discipline:** every plug in this dir carries a `## Security` moduledoc note
(`put_operation_id.ex:26-30`: "untrusted attacker input … never for authorization"). Add the analogous note:
billable is resolved from server-side assigns only, never from params/headers; the `accept` header drives
negotiation only, never authz.

---

### `accrue/lib/accrue/entitlements/guard.ex` (service, decision engine — RESEARCH Pattern 3, RECOMMENDED)

**Analog:** `accrue/lib/accrue/entitlements.ex` — the always-compiled core fail-closed engine with NO LiveView refs. Clone its **delegate-then-decide** posture and its `try/rescue/catch → fail-closed` discipline.

**The gate fns this engine calls (do NOT re-implement — D-08) — `entitlements.ex:48-64`:**
```elixir
@spec entitled?(term(), atom()) :: boolean()
def entitled?(billable, feature) do
  {result, reason} =
    case resolve(billable) do
      {:ok, %{features: features} = resolved} ->
        cond do
          MapSet.member?(features, feature) -> {true, :entitled}
          empty?(resolved) -> {false, :no_active_subscription}
          true -> {false, :not_entitled}
        end

      :error ->
        {false, :error}
    end

  span(billable, feature, result, reason, fn -> result end)
end
```

**Fail-closed wrapper to clone for the billable-resolution call (a raising `billable:` fn must also collapse to `nil`) — `entitlements.ex:143-153`:**
```elixir
defp resolve(billable) do
  case Resolver.__impl__().resolve(billable, []) do
    {:ok, resolved} -> {:ok, resolved}
    _ -> :error
  end
rescue
  _ -> :error
catch
  _ -> :error
  _, _ -> :error
end
```
> Wrap the host `billable_fn.(container)` call in this identical `rescue`/`catch` → `nil` so a raising
> resolver fails closed (PITFALLS #2). The resolved `nil` then flows straight into `Accrue.entitled?/2`,
> which already fails closed.

**`reason` atom set to reuse for `ctx` (D-12) — already produced by the gate:** `:entitled` /
`:not_entitled` / `:no_active_subscription` / `:unmapped_plan` / `:error` (see `entitlements.ex:54-90`).
`ctx` = `%{guard:, required:, reason:, billable:, surface:}` — bounded, no PII (mirror the `subject_id/1`
PII-discipline at `entitlements.ex:204-208`: only stringable ids, never email/struct internals).

**Default billable probe (D-15) — pure read from assigns, nil-safe:** probe
`container.assigns[:current_scope].user → container.assigns[:current_user] → nil`. Keep it total (never raises);
this is the same "total, never raises" contract documented at `entitlements.ex:198-203`.

**Resolve-once seam (D-17):** the Plug surface stashes via `Plug.Conn.assign(conn, :accrue_billable, …)`
(always available); the LiveView surface stashes via `assign_new(socket, :accrue_billable, fn -> … end)`
**inside** `live/entitlements.ex` (because `assign_new` is `Phoenix.Component`, which must stay out of
`guard.ex` to keep the merge gate trivially green). Stash the **billable only**, never the boolean (PITFALLS #3).

---

### `accrue/lib/accrue/live/entitlements.ex` (middleware, event-driven — cond-compiled; the ONLY file allowed LiveView refs)

**Analog 1 — cond-compile 4-pattern, clone verbatim from `integrations/sigra.ex:31-32,52`:**
```elixir
if Code.ensure_loaded?(Sigra) do
  defmodule Accrue.Integrations.Sigra do
    @behaviour Accrue.Auth
    @compile {:no_warn_undefined, [Sigra.Auth, Sigra.Audit]}
    # ...
  end
end
```
> Map directly to: `if Code.ensure_loaded?(Phoenix.LiveView) do defmodule Accrue.Live.Entitlements do … end
> end` + `@compile {:no_warn_undefined, [Phoenix.LiveView, Phoenix.Component]}`. **Divergence from Sigra
> (D-04):** `phoenix_live_view` is a HARD dep (mix.exs:80), so the branch is never elided in practice —
> belt-and-suspenders/self-documenting, not load-bearing.

**Analog 2 — `on_mount/4` shape, clone from `accrue_admin/lib/accrue_admin/auth_hook.ex:1-33`:**
```elixir
import Phoenix.LiveView, only: [redirect: 2]
import Phoenix.Component, only: [assign: 3]

@spec on_mount(atom(), map(), map(), Phoenix.LiveView.Socket.t()) ::
        {:cont, Phoenix.LiveView.Socket.t()} | {:halt, Phoenix.LiveView.Socket.t()}
def on_mount(:ensure_admin, params, session, socket) do
  case OwnerScope.resolve(session, params) do
    {:ok, owner_scope} ->
      {:cont, socket |> assign(:current_admin, owner_scope.current_admin) |> ...}

    {:error, _reason} ->
      {:halt, redirect(socket, to: "/")}
  end
end
```
> Map to the D-20 shape: `on_mount({:require_feature, feature}, _p, _s, socket)` and
> `on_mount({:require_plan, plan}, _p, _s, socket)` clauses, each delegating to
> `Accrue.Entitlements.Guard.check(:live, socket, [{kind, required}])` and returning `{:cont, socket}` /
> `{:halt, Accrue.Entitlements.Guard.deny_live(socket, deny_form, ctx)}`. Add `put_flash: 3` to the
> `Phoenix.LiveView` import for the `:forbidden`→flash+redirect degradation (D-21); the AuthHook only
> imports `redirect: 2`, so this is an additive import. Keep ALL decision logic in `guard.ex` — this file
> stays nearly logic-free (RESEARCH Anti-Pattern).

---

### `accrue/lib/accrue/router.ex` (route, request-response) — EDIT

**Analog:** the existing `accrue_webhook/2` macro in the SAME file (lines 45-49). Clone the `defmacro …
quote do … end` shape exactly:
```elixir
defmacro accrue_webhook(path, processor) do
  quote do
    forward(unquote(path), Accrue.Webhook.Plug, processor: unquote(processor))
  end
end
```
> Add `require_feature/1` and `require_plan/1` (D-07) that expand to
> `plug(Accrue.Plug.RequireEntitlement, feature: unquote(feature))` /
> `plug(Accrue.Plug.RequireEntitlement, plan: unquote(plan))`. Keep them single-arg (just the atom) for
> least-surprise; advanced `on_deny:`/`billable:` overrides go through the canonical `plug` form (RESEARCH
> Open Question 2). Extend the `import Accrue.Router` moduledoc usage example accordingly.

---

### `accrue/lib/accrue/config.ex` (config) — EDIT

**Analog:** the existing `:entitlements` schema block (lines 356-401) and the `validate_descending/1`
custom validator (lines 951-968) referenced via `type: {:custom, …}`.

**Existing `:entitlements` `keys:` to extend (config.ex:356-396):**
```elixir
entitlements: [
  type: :keyword_list,
  default: [],
  keys: [
    plans: [ ... ],          # existing
    resolver: [ ... ],       # existing (default Accrue.Entitlements.Resolver.LocalMap)
    unmapped_action: [type: {:in, [:deny, :raise]}, default: :deny, ...]   # existing
    # --- NEW (Phase 124): billable:, on_deny:, deny_path: ---
  ],
  ...
]
```
> Add `billable:` (`type: {:or, [nil, {:fun, 1}]}` if NimbleOptions 1.1 accepts it — RESEARCH A1 says
> fall back to `type: :any` + arity-check-at-use if not; default `nil`), `on_deny:` (`type: :any`, default
> `:forbidden`; the `:forbidden | {:redirect, path} | {status, body} | fun/2 | {m,f,a}` union is not
> NimbleOptions-expressible, so add a `{:custom, …}` validator cloned from `validate_descending/1` below to
> fail loud on a malformed global `on_deny` at boot), and `deny_path:` (`type: :string`, default `"/"`).

**Custom validator shape to clone (config.ex:951-968) for the `on_deny:` union check:**
```elixir
@spec validate_descending(term()) :: {:ok, [pos_integer()]} | {:error, String.t()}
def validate_descending(list) when is_list(list) and list != [] do
  cond do
    not Enum.all?(list, &(is_integer(&1) and &1 > 0)) ->
      {:error, "expected a list of positive integers, got: #{inspect(list)}"}
    # ...
    true -> {:ok, list}
  end
end

def validate_descending(other), do: {:error, "expected a non-empty list of positive integers, got: #{inspect(other)}"}
```

**Accessor — extend or read alongside `entitlements/0` (config.ex:849-850):**
```elixir
@spec entitlements() :: keyword()
def entitlements, do: get!(:entitlements)
```
> Boot validation is automatic: `validate_at_boot!/0` (config.ex:476-487) runs `NimbleOptions.validate!`
> over `@schema`, so the new keys are validated at boot for free (no extra wiring beyond the schema +
> custom validator).

---

### `accrue/lib/accrue/telemetry/otel.ex` (config, allowlist) — EDIT

**Analog:** the existing dual atom+string `@allowed_attributes` map (lines 12-41). The entitlement keys
added in Phase 123 (D-19) are the exact precedent:
```elixir
@allowed_attributes %{
  # ...
  :feature => "accrue.feature",
  :result => "accrue.result",
  :reason => "accrue.reason",
  # ... (atom block) ...
  "accrue.feature" => "accrue.feature",
  "accrue.result" => "accrue.result",
  "accrue.reason" => "accrue.reason"
  # ... (string block) ...
}
```
> Add BOTH `:surface => "accrue.surface"` (in the atom block, alongside `:reason`) AND `"accrue.surface"
> => "accrue.surface"` (in the string block) — mirror the dual-entry discipline exactly (D-18).

---

### `accrue/lib/accrue/entitlements.ex` (service) — EDIT (additive `opts`, RESEARCH OQ1 / A2)

**Self-analog:** `entitled?/2` (lines 48-64) + the `span/5` metadata builder (lines 213-224):
```elixir
defp span(billable, feature, result, reason, fun) do
  metadata = %{
    feature: feature,
    result: result,
    resolver: resolver_tag(),
    reason: reason,
    subject_type: subject_type(billable),
    subject_id: subject_id(billable)
  }

  Accrue.Telemetry.span([:accrue, :entitlements, :check], metadata, fun)
end
```
> To land `surface:` on the SAME `:check` span (D-18), thread an additive `opts \\ []` through
> `entitled?/2`/`has_active_plan?/2` and merge `surface:` into the `metadata` map. **Additive, non-breaking
> to Phase 123 callers** (RESEARCH recommends this over a guard-owned wrapper span). Planner: confirm this
> public-arity touch is acceptable (it is additive → within CONTEXT's reversible/additive posture).

---

### `scripts/ci/verify_core_liveview_runtime_free.sh` (config, CI gate) — NEW

**Analog:** `scripts/ci/verify_processor_support_matrix.sh` — the established merge-blocking grep-gate.
Clone its header + `repo_root` resolution + fail-with-stderr-and-`exit 1` shape:
```bash
#!/usr/bin/env bash
# Shift-left gate: processor-support matrix literals must stay aligned with strategy and CI.
set -euo pipefail

repo_root="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
matrix="${repo_root}/.planning/processor-support-matrix.md"
# ... require_substring helper that echoes to >&2 and exits 1 on miss ...
echo "verify_processor_support_matrix: OK"
```
> Adapt to D-05: `lib="${repo_root}/accrue/lib"` (repo_root resolves to repo root from `scripts/ci/`);
> `grep -rnE` for REAL refs only — `(import|alias) Phoenix.LiveView` / `Phoenix.LiveView.Socket` /
> `Phoenix.Socket` / `def on_mount` — `--include='*.ex'`, piped through `grep -v '/accrue/live/'` (the
> legitimate cond-compiled module). Fail (`exit 1`) if any hit; else `echo "...: OK"`. The `^[^#]*` anchor
> excludes the doc-comment hit at `oban/middleware.ex:21-24` (D-05 allowlist). **Re-validate the regex
> against the live tree at plan time** (RESEARCH A4): baseline (2026-05-23) confirms the ONLY
> `Phoenix.LiveView`/`on_mount` hit in `accrue/lib` is that doc comment.

---

### `.github/workflows/ci.yml` (config, CI) — EDIT

**Analog:** the `docs-contracts-shift-left` job step block (lines 41-65). Add a step mirroring the existing
shape:
```yaml
- name: Processor support matrix contract
  run: bash scripts/ci/verify_processor_support_matrix.sh
```
> Add (D-05): `- name: Core stays LiveView-runtime-free (ENT-07 D-05)` / `run: bash
> scripts/ci/verify_core_liveview_runtime_free.sh` into the same job (cwd = repo root → bare
> `scripts/ci/...` path). Job is already merge-blocking (ci.yml:6, 524, 541).

---

### Tests

**`accrue/test/property/guard_fail_closed_property_test.exs` (property)** — clone
`accrue/test/property/entitlements_fail_closed_property_test.exs` near-verbatim. Reuse:
- the `garbage_gen/0` generator (lines 87-95: `nil | StreamData.term() | integer | string | atom`);
- the `RaisingResolver` stub (lines 47-51) for the raising-resolver leg;
- the `setup` env-save/restore with `on_exit` (lines 67-80) — `async: false` because it mutates
  `:accrue, :entitlements`;
- `use Accrue.BillingCase, async: false` + `use ExUnitProperties` (line 30-31) + `alias Accrue.Test.Factory`.
> Adapt `assert_fail_closed/1` to drive through the GUARD (`Guard.check/3` deny + a raising `billable:` fn),
> proving both surfaces fail closed on nil billable / raising resolver / exception (SC#4).

**`accrue/test/accrue/live/entitlements_test.exs`** — clone the source-assertion test from
`accrue/test/accrue/integrations/sigra_test.exs:48-61`:
```elixir
test "source file exists and uses the 4-pattern conditional compile" do
  source = File.read!("lib/accrue/integrations/sigra.ex")
  assert source =~ "Code.ensure_loaded?(Sigra)"
  assert source =~ "@compile {:no_warn_undefined"
  assert source =~ "@behaviour Accrue.Auth"
end
```
> Adapt: read `"lib/accrue/live/entitlements.ex"`; assert `=~ "Code.ensure_loaded?(Phoenix.LiveView)"`,
> `=~ "@compile {:no_warn_undefined"`, `=~ "def on_mount"`. **Divergence (RESEARCH L447):** unlike Sigra
> (which accepts `:nofile`), `phoenix_live_view` is HARD, so ALSO assert the module is ALWAYS loaded —
> `assert {:module, Accrue.Live.Entitlements} = Code.ensure_loaded(Accrue.Live.Entitlements)` and
> `function_exported?(Accrue.Live.Entitlements, :on_mount, 4)`. Prefer stub-socket unit calls
> (`%Phoenix.LiveView.Socket{assigns: …}`) over a full live mount for the `{:cont}`/`{:halt}` legs (A3).

**`accrue/test/accrue/plug/require_entitlement_test.exs`** — no in-tree plug test analog; use `Plug.Test`
(ships with `:plug`): `conn(:get, "/")` + `put_req_header(conn, "accept", "application/json")`, then assert
`conn.status == 403`, `conn.halted == true`, `resp_body == ~s({"error":"forbidden"})` (JSON) vs `"Forbidden"`
(text); allow leg asserts `conn.halted == false`. Borrow the `setup` env-save/restore idiom from the property
test (lines 67-80) when exercising `config :accrue, :entitlements, billable:`/`on_deny:`.

**`accrue/test/accrue/entitlements/guard_test.exs`** — billable resolution (per-guard fn / config global /
default scope probe) + resolve-once (assert `:accrue_billable` assign present, `:accrue_entitled` ABSENT,
resolver invocation count == 1 across N checks). Reuse the property test's `TestUser`/`Factory`/`@plans`/setup
scaffolding (lines 35-80).

**`accrue/test/accrue/entitlements/guard_telemetry_test.exs`** — attach a `:telemetry` handler to
`[:accrue, :entitlements, :check, :stop]` and assert `metadata.surface in [:plug, :live]` (SC#4). The
`Accrue.Telemetry.span/3` plumbing already exists (telemetry.ex:40-49); just add the handler-attach pattern.

---

## Shared Patterns

### Fail-closed delegation (apply to: RequireEntitlement plug, Live.Entitlements, Guard)
**Source:** `accrue/lib/accrue/entitlements.ex:48-64` (`entitled?/2`) + `:143-153` (`resolve/1` rescue/catch).
The guards NEVER make their own allow decision (D-08): resolve billable → `Accrue.entitled?/2` /
`Accrue.has_active_plan?/2` → `false` is the easy/default path. Wrap the host `billable_fn` call in the same
`rescue`/`catch → nil`. Excerpt under `guard.ex` assignment above.

### Plug init validate-and-raise (apply to: RequireEntitlement)
**Source:** `accrue/lib/accrue/plug/put_connected_account.ex:33-48`. `init/1 when is_list(opts)` →
`case … raise ArgumentError`. Compile-time failure on bad opts. Excerpt under the plug assignment above.

### Pure-Plug deny (NO Phoenix) (apply to: RequireEntitlement)
**Source:** `accrue/lib/accrue/webhook/plug.ex:51-53`. `conn |> send_resp(status, Jason.encode!(%{error:
…})) |> halt()`. Content-negotiate via `get_req_header(conn, "accept")` (webhook/plug.ex:65 uses the same
`get_req_header |> List.first()` access pattern). `phoenix` is `optional: true` (mix.exs:77) → never call
`Phoenix.Controller.get_format/1` (PITFALLS #1).

### Cond-compile 4-pattern (apply to: Live.Entitlements only)
**Source:** `accrue/lib/accrue/integrations/sigra.ex:31-32,52`. `if Code.ensure_loaded?(Dep) do defmodule …
end` + `@compile {:no_warn_undefined, [...]}` + narrow `import … only:`. Excerpt under the Live assignment.

### `on_mount/4` cont/halt (apply to: Live.Entitlements)
**Source:** `accrue_admin/lib/accrue_admin/auth_hook.ex:1-33`. `{:cont, socket}` / `{:halt, redirect(socket,
to: …)}`; `import Phoenix.LiveView, only: [redirect: 2]` + `import Phoenix.Component, only: [assign: 3]`.
Excerpt under the Live assignment.

### Dual atom+string OTel allowlist (apply to: otel.ex)
**Source:** `accrue/lib/accrue/telemetry/otel.ex:12-41`. Every key appears twice (atom → dotted string, and
dotted string → itself). Add `:surface` in both blocks. Excerpt under the otel.ex assignment.

### NimbleOptions schema + custom validator (apply to: config.ex)
**Source:** `accrue/lib/accrue/config.ex:356-401` (the `:entitlements` block) + `:951-968`
(`validate_descending/1` `{:custom, …}` validator) + `:476-487` (`validate_at_boot!/0`). Excerpts under the
config.ex assignment.

### Grep merge-gate (apply to: verify script + ci.yml)
**Source:** `scripts/ci/verify_processor_support_matrix.sh` (header, `repo_root`, fail-to-stderr+`exit 1`,
`echo "...: OK"`) wired in `.github/workflows/ci.yml:46-47`. Excerpts under the script + ci.yml assignments.

### Property-test fail-closed scaffolding (apply to: all new tests)
**Source:** `accrue/test/property/entitlements_fail_closed_property_test.exs` — `TestUser` (35-42),
`RaisingResolver` (47-51), `@plans` (55-58), `setup` env-restore (67-80), `garbage_gen/0` (87-95),
`assert_fail_closed/1` (98-103). Excerpts under the Tests section.

### Doc reconciliation (D-06 lockstep — apply in THIS PR; doc-only, no behaviour change)
The literal "LiveView-FREE / no LiveView present / phoenix_live_view absent-or-optional in core" claims are
**factually false** (16+ core modules `use Phoenix.Component`, which ships only in `phoenix_live_view`; it is
a non-optional core dep at mix.exs:80). Reconcile to "LiveView-**runtime**-free" in lockstep:
- **`accrue/lib/accrue/oban/middleware.ex:19-24`** — moduledoc says *"LiveView is a hard dependency of
  `accrue_admin` only, never `accrue`."* → correct to "LiveView's *socket runtime* is never coupled in core;
  `phoenix_live_view` is a required core dep for `Phoenix.Component`." (EXTRA hit found in RESEARCH Pitfall 5,
  NOT in CONTEXT's enumerated list — add to the task.) Harmless to the gate (doc comment, allowlisted).
- **`CLAUDE.md`** — the "core stays LiveView-free / LiveView hard dep in admin not core" claims.
- **`.planning/ROADMAP.md` SC#3** (line ~59 "compiles and loads with no LiveView present") + the LiveView-free
  note (~line 125).
- **`.planning/REQUIREMENTS.md` ENT-07** — RESEARCH says line 27 may already read "runtime-LiveView-free";
  diff before editing, fix only what still says "no LiveView present".
- **`.planning/research/PITFALLS.md`** — Pitfall #8 stale "guard in admin / phoenix_live_view absent" stance.
- **`accrue/mix.exs:78-80`** — the `phoenix_live_view` comment (keep non-optional, D-02; clarify it provides
  `Phoenix.Component`/`~H` for the email+invoice spine + cond-compiled guard, no socket runtime, never in
  `extra_applications`).

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `accrue/test/accrue/plug/require_entitlement_test.exs` | test | request-response | No existing `Plug.Test`-based test in `accrue/test/accrue/plug/`. Use `Plug.Test` directly (`conn/3`, `put_req_header/3`); the assertion targets (`conn.status`, `conn.halted`, `resp_body`) are standard. Borrow only the env-save/restore `setup` from the property test. |

> Note: `accrue/test/accrue/router_test.exs` does NOT exist — the macro-expansion test is a NEW file
> (RESEARCH's "extend existing" assumption is wrong here). It has no direct analog; assert that
> `require_feature :x` / `require_plan :y` expand to `plug Accrue.Plug.RequireEntitlement, …` via macro
> expansion (`Macro.expand`/`quote` round-trip) or a behavioural mount test.

---

## Metadata

**Analog search scope:** `accrue/lib/accrue/{plug,live,integrations,webhook,entitlements,telemetry,oban}/`,
`accrue/lib/accrue/{router,config,entitlements,telemetry/otel}.ex`, `accrue_admin/lib/accrue_admin/`,
`accrue/test/{accrue/integrations,property}/`, `scripts/ci/`, `.github/workflows/`, `accrue/mix.exs`.
**Files read (full or targeted):** 17.
**Pattern extraction date:** 2026-05-23

---

## PATTERN MAPPING COMPLETE

**Phase:** 124 - enforcement-surfaces-plug-liveview-guards
**Files classified:** 14 (8 source create/edit, 5 tests, 1 CI script; + doc-only edits across 6 files)
**Analogs found:** 14 / 14

### Coverage
- Files with exact analog: 9 (plug init/deny, cond-compile, on_mount, router macro, config schema, otel allowlist, ci.yml step, property-test clone, entitlements self-edit)
- Files with role-match analog: 4 (guard engine, CI grep script, live source-assertion test, guard test scaffolding)
- Files with no direct analog: 1 (plug test — `Plug.Test` stdlib; router macro test is NEW, no analog)

### Key Patterns Identified
- All core Plugs use `@behaviour Plug` + `init/1 when is_list(opts)` validate-and-raise (`put_connected_account.ex`); the deny path is **pure Plug** (`webhook/plug.ex` `send_resp`+`Jason.encode!`+`halt`), never `Phoenix.Controller` (phoenix is `optional: true`).
- Conditional compilation is the CLAUDE.md 4-pattern, cloned verbatim from `integrations/sigra.ex`; here it is belt-and-suspenders (the dep is hard), and a source-assertion test (`sigra_test.exs` shape) locks the pattern in.
- The guards are transport adapters over the Phase 123 fail-closed engine (`entitlements.ex`): resolve billable (with `rescue`/`catch → nil`), call `Accrue.entitled?/2`/`has_active_plan?/2`, translate the result. They NEVER re-decide.
- Telemetry reuses the Phase 123 `[:accrue, :entitlements, :check]` event; the only additions are a `:surface` dual atom+string OTel allowlist entry (`otel.ex`) and an additive `opts` thread on the gate fns.
- The merge gate is the established repo-root `scripts/ci/verify_*.sh` grep-gate model wired into the `docs-contracts-shift-left` ci.yml job — NOT a compile-matrix cell.

### File Created
`/Users/jon/projects/accrue/.planning/phases/124-enforcement-surfaces-plug-liveview-guards/124-PATTERNS.md`

### Ready for Planning
Pattern mapping complete. Planner can reference per-file analog paths + concrete excerpts directly in PLAN.md action sections. Two path corrections flagged: (1) the CI script belongs at repo-root `scripts/ci/`, not `accrue/scripts/ci/`; (2) `accrue/test/accrue/router_test.exs` does not exist (macro test is NEW).
