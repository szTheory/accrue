# Phase 124: Enforcement Surfaces — Plug + LiveView Guards - Research

**Researched:** 2026-05-23
**Domain:** Plug/LiveView authorization guards over a fail-closed entitlement gate (Elixir/Phoenix billing library)
**Confidence:** HIGH (all idioms grounded in cloned source; one external content-negotiation verification)

## Summary

Every WHAT for this phase is locked in `124-CONTEXT.md` (D-01..D-21). This research answers the HOW by grounding each decision in the actual source files to clone. The phase ships **two surfaces over one engine**: a plain-Plug controller guard (`Accrue.Plug.RequireEntitlement` + thin `require_feature`/`require_plan` router macros) and a conditionally-compiled LiveView `on_mount` guard (`Accrue.Live.Entitlements`). Both delegate the entire allow/deny to the Phase 123 fail-closed gate (`Accrue.entitled?/2` / `Accrue.has_active_plan?/2`) and share **one billable-resolution convention** (a single 1-arity fn) and **one deny convention** (tiered, declarative-first).

The single most important implementation insight: **the deny path must be pure Plug, not Phoenix.** The existing `Accrue.Webhook.Plug` (`lib/accrue/webhook/plug.ex:51-53`) already proves the idiom — `conn |> send_resp(status, Jason.encode!(...)) |> halt()` — with zero `Phoenix.Controller` dependency. `phoenix` is declared `optional: true` in `accrue/mix.exs:77`, so the plug MUST NOT call `Phoenix.Controller.get_format/1`; it negotiates JSON-vs-text by reading `get_req_header(conn, "accept")` directly. `phoenix_live_view` is a **hard, non-optional** core dep (`mix.exs:80`) purely for `Phoenix.Component`/`~H` (16 core modules `use Phoenix.Component` — the email/invoice spine), which is why the cond-compile guard always compiles and the merge gate is a cheap static grep, not a compile-matrix cell.

**Primary recommendation:** Clone `PutConnectedAccount` for the plug skeleton (init-validates-and-raises), clone `Sigra` for the cond-compile wrapper, clone `AccrueAdmin.AuthHook.on_mount/4` for the LiveView shape, clone `verify_processor_support_matrix.sh` + the `docs-contracts-shift-left` CI job for the static gate. Build a single private `Accrue.Entitlements.Guard` helper module (always-compiled core, no LiveView refs) that both surfaces call to resolve billable, run the gate, and translate the deny enum — keeping the two thin surface modules nearly logic-free.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

All 21 decisions D-01..D-21 in `124-CONTEXT.md` are LOCKED. This research does not relitigate them; it specifies HOW to execute them. Key locks restated for the planner's convenience (authoritative text is in CONTEXT.md):

- **D-01/D-02/D-06** — Relax "LiveView-FREE" → "LiveView-**runtime**-free". Keep `{:phoenix_live_view, "~> 1.1"}` non-optional. No dep change. Reconcile CLAUDE.md / ROADMAP SC#3 / REQUIREMENTS ENT-07 / PITFALLS.md wording **in this phase's PR**.
- **D-03/D-04** — Guard lives in core `accrue` at `lib/accrue/live/entitlements.ex`, cond-compiled via the Sigra 4-pattern (belt-and-suspenders; never load-bearing because the dep is hard). Add a source-assertion test.
- **D-05** — Merge gate = low-ceremony STATIC grep/Credo check; doc-comment allowlist; NOT a `without_live_view` compile cell.
- **D-07/D-08** — One workhorse plug `Accrue.Plug.RequireEntitlement` + thin `require_feature`/`require_plan` macros in `Accrue.Router`. Guard NEVER makes its own allow decision — delegates to Phase 123.
- **D-09/D-10/D-11/D-12/D-13** — Default deny = content-negotiated **opaque** 403 (`application/json` → `{"error":"forbidden"}`; else `text/plain "Forbidden"`). 402 only as opt-in `status: 402`. `on_deny` tiered: per-guard opt → config global → built-in 403. Forms: `:forbidden | {:redirect, path} | {status, body} | (container, ctx -> result) | {m,f,a}`. No redirect default. Bounded no-PII `ctx`. Redirect-loop guard documented + optional self-redirect fall-through.
- **D-14/D-15/D-16** — `billable:` is a SINGLE 1-arity fn `(conn | socket -> billable | nil)`. Default probes `current_scope.user → current_user → nil`. Global override via `config :accrue, :entitlements, billable:`. Never reuse `Accrue.Auth.current_user/1`. Never raises.
- **D-17/D-18/D-19** — Resolve-once via `assign_new(:accrue_billable, …)` (stash billable only, never the boolean). Reuse Phase 123 `[:accrue, :entitlements, :check]` event; add a `surface: :plug | :live` metadata key + OTel allowlist entry. ZERO ledger rows.
- **D-20/D-21** — `on_mount {Accrue.Live.Entitlements, {:require_feature, :api_access}}` / `{:require_plan, :pro}`. `{:cont, socket}` / `{:halt, …}`. Surface-symmetric deny: on LiveView `:forbidden` degrades to `{:halt, socket |> put_flash(...) |> redirect(to: deny_path)}` where `deny_path` defaults to `"/"`.

### Claude's Discretion

Per CONTEXT.md, all gray areas were auto-resolved into D-01..D-21 in cohesive-synthesis mode; **zero open forks**. This research has no decisions to surface to the user — only implementation tactics.

### Deferred Ideas (OUT OF SCOPE)

- Resolver provider-honesty + `entitlements:` capability-matrix rows + drift gate (ENT-08) → Phase 125.
- Lifecycle→entitlement truth-table SSOT + `past_due` grace knob (ENT-09) → Phase 125 (124 inherits whatever `Subscription.active?/1` decides).
- Admin entitlements view + `guides/entitlements.md` + JTBD flip (ENT-11/12) → Phase 126.
- Optional Stripe-native webhook→cache sync + `grant`/`revoke` + ledger writes (ENT-10) → Phase 127.
- Atomic seat *enforcement* / membership management — host-owned recipe, never a core API.
- A dedicated guard-deny telemetry event distinct from `:check` — additive later only.
- Decoupling email/invoice templating from `phoenix_live_view` — not worth it; no sourced need.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ENT-06 | Gate a Phoenix controller route with a Plug guard (`require_plan`/`require_feature`) that halts with a configurable fail response (redirect / 403) when not entitled. | `## Plug Guard Skeleton` (init/call/deny), `## Deny Convention`, `## Router Macros`. Cloned from `PutConnectedAccount` + `Webhook.Plug` + `Router.accrue_webhook`. |
| ENT-07 | Gate a host LiveView with an `on_mount` guard, shipped via conditional compilation so core stays runtime-LiveView-free; billable-resolution key is host-configurable, adapter-thin (no required Sigra/Lockspire coupling). | `## LiveView Guard Skeleton`, `## Conditional Compilation`, `## Static Merge Gate`, `## Billable Resolution`. Cloned from `Sigra` + `AccrueAdmin.AuthHook`. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Allow/deny decision | API/Backend (`Accrue.Entitlements`, Phase 123) | — | Already built and fail-closed; guards never re-decide (D-08). |
| HTTP route gating | Frontend Server (Plug pipeline) | — | `Accrue.Plug.RequireEntitlement` runs in the host's controller pipeline; pure Plug, Phoenix-optional. |
| LiveView mount gating | Frontend Server (LiveView lifecycle) | — | `on_mount` runs server-side at mount; host's auth `on_mount` must run first (D-20). |
| Billable resolution | Frontend Server (read from conn/socket assigns) | — | Pure read from assigns via host's 1-arity fn (D-14/D-16); never an effectful auth call. |
| Deny response | Frontend Server | — | Plug: `send_resp/halt`. LiveView: `redirect/put_flash` (cannot emit raw 403, D-21). |
| Merge-gate enforcement | CI / Static | — | grep over `lib/` source proves no socket-runtime coupling (D-05). |
| Telemetry emission | API/Backend (inherited from Phase 123 span) | — | Guard adds only a `surface:` metadata key (D-18); no new event. |

**Tier-correctness note for the plan-checker:** No capability belongs in `accrue_admin` or a new package (D-03 explicitly rejects both). Everything lands in core `accrue`. The LiveView surface module is the *only* new file that may reference `Phoenix.LiveView` — and only inside the `Code.ensure_loaded?` block.

## Standard Stack

No new dependencies. Every required library is already in `accrue/mix.exs` and `mix.lock`.

### Core (already present — verified in `accrue/mix.lock`)
| Library | Resolved Version | Purpose | Posture |
|---------|------------------|---------|---------|
| `:plug` | 1.18.x (lock; `~> 1.16` in mix.exs:73) | `@behaviour Plug`, `Plug.Conn` (`send_resp`, `halt`, `get_req_header`, `assign`) | Hard dep. The plug needs ONLY this. |
| `:phoenix_live_view` | 1.1.30 (lock; `~> 1.1` mix.exs:80) | `Phoenix.Component` (`assign_new/3`), `Phoenix.LiveView` (`redirect/2`, `put_flash/3`), `Phoenix.LiveView.Socket` | **Hard, non-optional** core dep (D-02). Always loadable → cond-compile branch never elided in practice. |
| `:phoenix` | 1.8.7 (lock; `~> 1.8` **optional: true** mix.exs:77) | NOT used by the plug deny path. | Optional → the plug MUST NOT depend on `Phoenix.Controller`. |
| `:jason` | 1.4.x (`~> 1.4` mix.exs:66) | `Jason.encode!/1` for the JSON deny body | Hard dep; same idiom as `Webhook.Plug:52`. |
| `:nimble_options` | 1.1.x | Extend the `:entitlements` schema with `billable`/`on_deny`/`deny_path` | Hard dep. |
| `:telemetry` | 1.3+ | Inherited via Phase 123 span; add `surface:` key | Hard dep. |

### Alternatives Considered (and rejected per CONTEXT)
| Instead of | Could Use | Why rejected |
|------------|-----------|--------------|
| Pure-Plug accept-header parse | `Phoenix.Controller.get_format/1` | `phoenix` is `optional: true` (mix.exs:77); calling it would couple the plug to Phoenix, violating D-07 ("plug needs neither Phoenix nor LiveView"). |
| Single workhorse plug + macros | One macro-only API | D-07 locks "plug canonical, macros sugar" mirroring `accrue_webhook`. |
| Static merge grep gate | `without_live_view` compile matrix cell | Infeasible + ceremony (D-05); the dep is hard so the cell can't exist. |

**Installation:** None. No `mix deps.get` change.

## Package Legitimacy Audit

Not applicable — this phase installs **zero** external packages. All libraries used (`plug`, `phoenix_live_view`, `jason`, `nimble_options`, `telemetry`) are pre-existing, multi-year-old, multi-million-download ecosystem standards already locked in `accrue/mix.lock`. No registry verification needed for net-new packages because there are none.

## Architecture Patterns

### System Architecture Diagram

```
                    HOST APP
   ┌─────────────────────────────────────────────────────────────┐
   │                                                               │
   │  Controller pipeline                LiveView live_session     │
   │  ──────────────────                 ────────────────────      │
   │  plug AuthN (host)                  on_mount HostAuth (host)   │  ← auth runs FIRST
   │       │                                  │                     │     (D-20)
   │       ▼                                  ▼                     │
   │  plug Accrue.Plug.RequireEntitlement  on_mount {Accrue.Live.  │
   │  (feature:/plan:/billable:/on_deny:)   Entitlements,          │
   │       │                                {:require_feature, …}}  │
   │       │                                  │                     │
   └───────┼──────────────────────────────────┼────────────────────┘
           │                                  │
           ▼                                  ▼
   ┌───────────────────────────────────────────────────────────────┐
   │           Accrue.Entitlements.Guard  (always-compiled core,     │
   │                    NO LiveView socket refs)                      │
   │                                                                  │
   │   1. resolve billable  ──► billable_fn.(conn|socket)             │
   │        (assign_new :accrue_billable — resolve once, D-17)        │
   │   2. ── nil? ──► deny (fail-closed, D-08/D-14)                    │
   │   3. gate ──► Accrue.entitled?/2  OR  Accrue.has_active_plan?/2   │
   │        (Phase 123: try/rescue/catch, surface: :plug|:live D-18)  │
   │   4. true  ──► {:allow, container}                                │
   │      false ──► resolve on_deny (per-guard → config → 403, D-11)  │
   │                build ctx (bounded, no PII, D-12)                  │
   │                ──► {:deny, deny_form, ctx}                        │
   └───────────────────────────────────────────────────────────────┘
           │ allow                            │ deny
           ▼                                  ▼
   Plug:  conn (unchanged)            Plug:  send_resp(403|status,body)|halt
   Live:  {:cont, socket}                   OR redirect|halt  (surface-translate)
                                     Live:  {:halt, redirect/put_flash socket}
                                            (:forbidden degrades to deny_path, D-21)
```

Trace the deny case: a request with no entitlement enters either surface → `Guard` resolves billable (or `nil`) → calls Phase 123 gate (which fails closed on `nil`/error) → `false` → `Guard` resolves the tiered deny form and builds bounded `ctx` → each surface translates the form to its native halt (`send_resp/halt` vs `redirect/halt`).

### Recommended Project Structure
```
accrue/lib/accrue/
├── plug/
│   ├── put_connected_account.ex     # CLONE for init-validate-raise
│   ├── put_operation_id.ex          # reference (call/2 idiom)
│   └── require_entitlement.ex       # NEW (unconditional core, pure Plug)
├── live/
│   └── entitlements.ex              # NEW (cond-compiled; ONLY file allowed LiveView refs)
├── entitlements/
│   ├── guard.ex                     # NEW (RECOMMENDED) shared decision+deny+ctx engine,
│   │                                #   always-compiled core, NO LiveView refs
│   └── ...                          # (existing Phase 123 tree unchanged)
├── entitlements.ex                  # (existing) the gate fns; add surface: passthrough? (see note)
├── router.ex                        # EDIT: add require_feature/1, require_plan/1 macros
├── config.ex                        # EDIT: :entitlements schema += billable/on_deny/deny_path
├── telemetry/otel.ex                # EDIT: @allowed_attributes += :surface (atom + string)
└── oban/middleware.ex               # EDIT (doc-only): reconcile LiveView wording (D-06 hit, see Pitfall 5)
```

### Pattern 1: Plug Guard Skeleton (`Accrue.Plug.RequireEntitlement`)
**What:** `@behaviour Plug`; `init/1` validates opts at compile time and raises on bad opts (clone `PutConnectedAccount.init/1`); `call/2` resolves billable once, calls the gate, allows or denies.
**When to use:** Controller route gating (ENT-06).

```elixir
# Source idiom cloned from: lib/accrue/plug/put_connected_account.ex:33-48 (init validate/raise)
#                            lib/accrue/webhook/plug.ex:51-53 (pure-Plug deny send_resp|halt)
defmodule Accrue.Plug.RequireEntitlement do
  @behaviour Plug
  import Plug.Conn

  @impl true
  def init(opts) when is_list(opts) do
    # Exactly one of feature:/plan: — raise on bad opts at compile time (D-07).
    case {Keyword.fetch(opts, :feature), Keyword.fetch(opts, :plan)} do
      {{:ok, f}, :error} when is_atom(f) -> opts
      {:error, {:ok, p}} when is_atom(p) or is_binary(p) -> opts
      {{:ok, _}, {:ok, _}} ->
        raise ArgumentError,
          "Accrue.Plug.RequireEntitlement expects exactly one of `:feature` or `:plan`, got both"
      _ ->
        raise ArgumentError,
          "Accrue.Plug.RequireEntitlement requires `feature: atom` or `plan: atom | String.t()`"
    end
    # NOTE: do NOT validate billable:/on_deny:/status: shapes beyond presence here —
    # invalid runtime fn results fail closed by construction (D-08/D-14).
  end

  @impl true
  def call(conn, opts) do
    case Accrue.Entitlements.Guard.check(:plug, conn, opts) do
      {:allow, conn}              -> conn
      {:deny, deny_form, ctx}     -> Accrue.Entitlements.Guard.deny_plug(conn, deny_form, ctx, opts)
    end
  end
end
```

The `deny_plug/4` content negotiation (pure Plug, NO Phoenix — see Pitfall 1):

```elixir
# Source: verified pattern (WebSearch + lib/accrue/webhook/plug.ex precedent)
defp json_requested?(conn) do
  conn
  |> Plug.Conn.get_req_header("accept")
  |> Enum.any?(&String.contains?(&1, "json"))
end

defp builtin_403(conn, status) do
  if json_requested?(conn) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(status, Jason.encode!(%{error: "forbidden"}))  # OPAQUE (D-10)
    |> Plug.Conn.halt()
  else
    conn
    |> Plug.Conn.put_resp_content_type("text/plain")
    |> Plug.Conn.send_resp(status, "Forbidden")
    |> Plug.Conn.halt()
  end
end
```

### Pattern 2: LiveView Guard Skeleton (`Accrue.Live.Entitlements`)
**What:** `on_mount/4` with `{:require_feature, atom}` / `{:require_plan, atom|string}` first-arg clauses; `{:cont, socket}` on allow, `{:halt, …}` on deny; cond-compiled via the Sigra 4-pattern.
**When to use:** Host LiveView gating (ENT-07).

```elixir
# Source idiom cloned from: lib/accrue/integrations/sigra.ex:31-32,52 (cond-compile wrapper)
#                            accrue_admin/lib/accrue_admin/auth_hook.ex:1-33 (on_mount shape)
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Accrue.Live.Entitlements do
    @moduledoc """..."""
    @compile {:no_warn_undefined, [Phoenix.LiveView, Phoenix.Component]}
    import Phoenix.LiveView, only: [redirect: 2, put_flash: 3]
    import Phoenix.Component, only: [assign_new: 3]

    def on_mount({:require_feature, feature}, _params, _session, socket) do
      decide(:feature, feature, socket)
    end

    def on_mount({:require_plan, plan}, _params, _session, socket) do
      decide(:plan, plan, socket)
    end

    defp decide(kind, required, socket) do
      case Accrue.Entitlements.Guard.check(:live, socket, [{kind, required}]) do
        {:allow, socket}          -> {:cont, socket}
        {:deny, deny_form, ctx}   -> {:halt, Accrue.Entitlements.Guard.deny_live(socket, deny_form, ctx)}
      end
    end
  end
end
```

`deny_live/3` surface-translates (D-21): `{:redirect, path}` → `redirect(socket, to: path)`; `:forbidden` → `socket |> put_flash(:error, "...") |> redirect(to: deny_path)` where `deny_path = Accrue.Config` `:entitlements[:deny_path]` (default `"/"`). A `{status, body}` form is meaningless on a socket — degrade it to the `:forbidden` path (document this asymmetry).

### Pattern 3: Shared `Accrue.Entitlements.Guard` engine (RECOMMENDED)
**What:** An always-compiled core module (NO LiveView refs — it only takes an opaque `container` term) that both surfaces call. Holds: billable resolution (D-14/D-15), resolve-once (D-17, via a passed assign-fn), the gate call with `surface:` (D-18), tiered `on_deny` resolution (D-11), and `ctx` construction (D-12).
**Why:** Keeps the two surface modules nearly logic-free, makes the surface-symmetry guarantee (one billable fn, one deny enum) a single code path, and crucially keeps all decision logic OUT of the cond-compiled `live/entitlements.ex` so the merge gate stays trivially green.

**Resolve-once seam (D-17):** `Guard.check/3` cannot import `Phoenix.Component.assign_new` directly (that would put a Phoenix.Component ref in always-compiled core — tolerable since it's a hard dep, but `assign_new` differs for conn vs socket). Cleanest split:
- Plug surface: `conn = Plug.Conn.assign(conn, :accrue_billable, billable)` only when not already present (or `Map.get(conn.assigns, :accrue_billable)` first). `Plug.Conn` is always available.
- LiveView surface: `assign_new(socket, :accrue_billable, fn -> billable end)` — but `assign_new` lives in `Phoenix.Component`, so this single call belongs in `live/entitlements.ex` (inside the cond-compile block), with `Guard` returning the resolved billable for the surface to stash. Alternatively, `Guard` accepts a `stash_fn` closure from each surface. **Recommendation:** have each surface own its own stash idiom (one line each) and have `Guard.resolve_billable/2` read-then-resolve; this keeps `Phoenix.Component` out of `guard.ex` entirely.

### Pattern 4: Router Macros (sugar over the plug)
**What:** Extend `Accrue.Router` (cloned from `accrue_webhook/2` at `router.ex:45-49`) with `require_feature/1` and `require_plan/1` that expand to `plug Accrue.Plug.RequireEntitlement, feature: …`.

```elixir
# Source: lib/accrue/router.ex:45-49 (defmacro accrue_webhook expanding to forward/3)
defmacro require_feature(feature) do
  quote do: plug(Accrue.Plug.RequireEntitlement, feature: unquote(feature))
end

defmacro require_plan(plan) do
  quote do: plug(Accrue.Plug.RequireEntitlement, plan: unquote(plan))
end
```
Note: `plug/2` inside a router macro expands in the controller/router DSL context. Document that `require_feature`/`require_plan` are used inside a controller `plug` chain or a router pipeline, exactly as `plug Accrue.Plug.RequireEntitlement, …` would be — the macro is pure sugar. Keep `on_deny:`/`billable:` overrides available only via the explicit `plug` form (the macros take just the feature/plan atom; advanced opts use the canonical plug).

### Anti-Patterns to Avoid
- **Calling `Phoenix.Controller.get_format/1` in the plug** — `phoenix` is optional (mix.exs:77); breaks plain-`Plug.Router` hosts and violates D-07. Use `get_req_header(conn, "accept")`.
- **Putting decision/deny logic inside `live/entitlements.ex`** — bloats the cond-compiled module and risks the merge gate. Keep it in always-compiled `guard.ex`.
- **Echoing `required`/feature/plan into the deny body** — leaks entitlement structure (D-10). Body stays opaque; `required` goes only into `ctx` for the host's own `on_deny` fn.
- **Defaulting `on_deny` to a redirect** — Cashier's hardcoded-`/billing` footgun + JSON-API 302 loops (D-11). Default is the 403; redirect is opt-in.
- **Re-implementing the allow decision** — guards delegate to `Accrue.entitled?/2` / `has_active_plan?/2` (D-08); never re-derive from `.status` or query subscriptions directly.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Fail-closed allow/deny | Custom subscription/feature lookup in the guard | `Accrue.entitled?/2` / `Accrue.has_active_plan?/2` (Phase 123) | Already `try/rescue/catch`-wrapped, multi-active-plan correct, telemetry-emitting (entitlements.ex:48-94). |
| Opts validation | Ad-hoc `if`/`case` scatter | `PutConnectedAccount.init/1` raise pattern (put_connected_account.ex:33-48) | Established codebase idiom; raises at compile time. |
| Cond-compile wrapper | Custom `try/Code.ensure_loaded`/Mix.env logic | The Sigra 4-pattern verbatim (sigra.ex:31-32,52) | CLAUDE.md-blessed, source-asserted, regression-proof. |
| Content negotiation | A new content-negotiation lib/plug | `get_req_header(conn, "accept")` + `String.contains?(&1, "json")` | Two surfaces, one binary check; matches `Webhook.Plug` precedent. No dep. |
| Telemetry span | New `[:accrue, :entitlements, :guard]` event | Reuse Phase 123 `[:accrue, :entitlements, :check]` + `surface:` key (D-18) | One event, one OTel span; operators filter by `surface`. |
| Merge-gate runner | Bespoke CI tooling | Clone `verify_processor_support_matrix.sh` shape + wire into `docs-contracts-shift-left` job (ci.yml:30-66) | Established merge-blocking grep-gate model. |

**Key insight:** This phase is almost entirely *plumbing two thin surfaces onto an existing engine*. The temptation is to re-solve authorization in the guard; the discipline (D-08) is that the guard is a transport adapter — resolve billable, call the gate, translate the result.

## Common Pitfalls

### Pitfall 1: Coupling the plug to Phoenix for content negotiation
**What goes wrong:** Reaching for `Phoenix.Controller.get_format/1` to decide JSON-vs-HTML.
**Why it happens:** It's the "Phoenix way" and most examples assume Phoenix is loaded.
**How to avoid:** `phoenix` is `optional: true` (mix.exs:77). The plug parses `get_req_header(conn, "accept")` directly — exactly as `Accrue.Webhook.Plug` builds JSON responses with bare `send_resp` + `Jason.encode!` (webhook/plug.ex:51-53). `get_format/1` also requires the `:accepts` plug or a `_format` param to have run, which a headless API host won't have.
**Warning signs:** `import Phoenix.Controller` or `Phoenix.Controller.` anywhere in `require_entitlement.ex`; a compile warning about `Phoenix.Controller` being undefined in a without-Phoenix build.

### Pitfall 2: Fail-OPEN on billable resolution error (PITFALLS #1)
**What goes wrong:** A `billable:` fn that raises, or a `nil` billable that the guard treats as "allow".
**Why it happens:** Defensive code that `rescue`s and continues, or a missing-assign that defaults truthy.
**How to avoid:** D-14 mandates the billable fn "never raises" by construction (missing assign / nil scope / scope without `.user` all collapse to `nil`). The guard passes whatever it gets (incl. `nil`) straight to `Accrue.entitled?/2`, which fails closed on `nil`/garbage (entitlements.ex `resolve/1` rescue, lines 143-153). If the host's `billable:` fn itself raises, wrap the *resolution* call in the same `try/rescue/catch → nil` so a raising resolver also fails closed. Deny is the easy path.
**Warning signs:** Any `rescue -> conn` (allow) branch; a test where a raising resolver lets the request through.

### Pitfall 3: Resolve-once stash leaking the boolean decision (PITFALLS #4 / D-17)
**What goes wrong:** Caching `entitled?` result in `:accrue_billable` or a second assign, then a different feature check reads the stale boolean.
**Why it happens:** Over-eager memoization.
**How to avoid:** Stash the **billable only** (`assign_new(:accrue_billable, …)` / `Plug.Conn.assign`), never the decision. Decisions are feature/plan-specific and are cheap local reads (D-17). Multiple downstream `entitled?(billable, …)` calls then fold to a single billable resolution but each computes its own boolean.
**Warning signs:** An assign named `:accrue_entitled` or a boolean stored on conn/socket.

### Pitfall 4: LiveView assign-ordering — auth on_mount must run first (D-20)
**What goes wrong:** The entitlement `on_mount` runs before the host's auth `on_mount`, so `current_scope`/`current_user` isn't populated yet → billable resolves `nil` → spurious deny.
**Why it happens:** `on_mount` hooks run in declaration order; entitlement is listed before auth.
**How to avoid:** Document loudly in the `Accrue.Live.Entitlements` moduledoc and `guides/entitlements.md` (Phase 126) that the host's auth `on_mount` MUST precede the entitlement guard in the `live_session` `on_mount: [...]` list. The guard gates entitlement only, never authentication.
**Warning signs:** Authenticated users getting denied; `billable: nil` in the deny telemetry `subject_id`.

### Pitfall 5: Doc-comment drift — the merge gate must allowlist doc comments (D-05 + an extra hit found)
**What goes wrong:** A naive `grep -r "Phoenix.LiveView" lib/` gate fails on the doc-comment in `oban/middleware.ex:22` ("The on_mount hook equivalent ...").
**Why it happens:** The gate is text-based; doc comments are text.
**How to avoid:** The gate must (a) restrict to `.ex` source, (b) strip/skip comment lines, OR (c) match only *real* references (e.g. `import Phoenix.LiveView`, `Phoenix.LiveView.Socket`, `on_mount(` definitions, `alias Phoenix.LiveView`) rather than the bare string. Also EXCLUDE `lib/accrue/live/` (the legitimately-LiveView module). See `## Static Merge Gate` for the exact recipe.
**EXTRA FINDING (planner action):** `oban/middleware.ex:19-24` contains a doc comment stating *"LiveView is a hard dependency of `accrue_admin` only, never `accrue`."* This is now **factually wrong** per D-01/D-02 (LiveView IS a non-optional core dep). It is a **D-06 doc-reconciliation hit not listed in CONTEXT.md's enumerated list** — the planner should add it to the lockstep wording-fix task (correct to "LiveView's *socket runtime* is never coupled in core; `phoenix_live_view` is a required core dep for `Phoenix.Component`"). It is harmless to the gate (doc comment, allowlisted) but contradicts the reconciled posture.

### Pitfall 6: Redirect loop on the deny destination (PITFALLS #8 / D-13)
**What goes wrong:** `on_deny: {:redirect, "/pricing"}` where `/pricing` is itself behind the same guard → infinite redirect; or a LiveView `:forbidden` whose `deny_path` is inside the gated `live_session`.
**Why it happens:** Host misconfiguration.
**How to avoid:** Document that the deny destination MUST live outside the gated pipeline/`live_session`. Optionally (D-13) detect a self-redirect (deny target == current request path) and fall through to the plain 403/halt instead of redirecting.
**Warning signs:** Browser "too many redirects"; a LiveView that never mounts.

### Pitfall 7: `{status, body}` deny form on the LiveView surface (D-21 asymmetry)
**What goes wrong:** A host configures `on_deny: {403, "nope"}` globally and a LiveView guard tries to "send" it.
**Why it happens:** The deny enum is shared across surfaces but a socket can't emit a raw status.
**How to avoid:** On the LiveView surface, `{status, body}` and `:forbidden` both degrade to `{:halt, put_flash + redirect(to: deny_path)}` (D-21). Document the one irreducible asymmetry; hosts never see conn-vs-socket plumbing.

## Code Examples

### Extending the `:entitlements` NimbleOptions schema (config.ex)
```elixir
# Source: lib/accrue/config.ex:356-401 (existing :entitlements block) — add three keys.
# All three are RUNTIME host data (D-01 posture), read via Application.get_env, boot-validated.
entitlements: [
  type: :keyword_list,
  default: [],
  keys: [
    plans: [...],            # existing (123)
    resolver: [...],         # existing (123)
    unmapped_action: [...],  # existing (123)
    # --- NEW (Phase 124) ---
    billable: [
      type: {:or, [nil, {:fun, 1}]},
      default: nil,
      doc: "Global billable resolver: 1-arity fn (conn | socket -> billable | nil). " <>
           "Default probes current_scope.user -> current_user -> nil. Must never raise."
    ],
    on_deny: [
      # :forbidden | {:redirect, path} | {status, body} | (container, ctx -> result) | {m,f,a}
      type: :any,
      default: :forbidden,
      doc: "Global deny handler. Default content-negotiated opaque 403. " <>
           "Per-guard `on_deny:` opt overrides this; this overrides the built-in 403."
    ],
    deny_path: [
      type: :string,
      default: "/",
      doc: "LiveView fallback redirect target for :forbidden / non-redirectable denies."
    ]
  ]
]
```
Add a `defp` accessor (or extend `entitlements/0`) that reads these with their defaults. NOTE: `{:fun, 1}` is valid NimbleOptions 1.1 type; verify against the installed version — if it rejects, fall back to `type: :any` and validate arity at first use (fail-closed if not a 1-arity fn). `on_deny`'s union is not expressible in NimbleOptions, so `type: :any` + a `{:custom, ...}` validator (clone the `validate_descending/1` pattern at config.ex:951) is the cleanest way to fail loud on a malformed global `on_deny` at boot.

### Adding `:surface` to the OTel allowlist (otel.ex)
```elixir
# Source: lib/accrue/telemetry/otel.ex:12-41 — add BOTH the atom key and the string key
# (the @allowed_attributes map has dual atom+string entries; mirror Phase 123 D-19 exactly).
@allowed_attributes %{
  # ... existing entries (lines 13-27) ...
  :surface => "accrue.surface",          # NEW (D-18)
  # ... existing string entries (lines 28-40) ...
  "accrue.surface" => "accrue.surface"   # NEW (D-18)
}
```
The gate then passes `surface: :plug | :live` into the metadata map that reaches `Accrue.Telemetry.span/3`. **Wiring question for the planner:** Phase 123's `Accrue.Entitlements.entitled?/2` builds its own metadata internally (entitlements.ex:213-224) and does NOT accept a `surface:` opt today. To get `surface:` onto the *same* `:check` span (D-18), the gate must either (a) thread an optional `surface:` through `entitled?/2`/`has_active_plan?/2` (small additive arg or opts), or (b) the guard wraps its own thin span. Option (a) is truer to D-18 ("add to the check metadata"). Recommend a small additive `opts` param on the two gate fns defaulting to `[]`, with `surface:` merged into the span metadata — additive, non-breaking to Phase 123 callers. The planner should confirm whether to touch `entitlements.ex`'s public arity or pass via process dict; the additive-opts route is cleanest and matches house style.

### Static merge gate (clone verify_processor_support_matrix.sh)
```bash
#!/usr/bin/env bash
# scripts/ci/verify_core_liveview_runtime_free.sh  (NEW — D-05)
# Fails if any ALWAYS-COMPILED core module references the LiveView socket runtime.
set -euo pipefail
repo_root="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
lib="${repo_root}/accrue/lib"

# Match REAL refs only (not doc comments / strings):
#   import/alias Phoenix.LiveView, Phoenix.LiveView.Socket, Phoenix.Socket, `def on_mount`
# Exclusions:
#   - lib/accrue/live/  (the legitimately-cond-compiled guard, D-03/D-04)
#   - comment lines (leading optional whitespace then #)  → oban/middleware.ex:22 allowlist (D-05)
hits=$(grep -rnE \
  '^[^#]*((import|alias)[[:space:]]+Phoenix\.LiveView|Phoenix\.LiveView\.Socket|Phoenix\.Socket|def[[:space:]]+on_mount)' \
  "${lib}" \
  --include='*.ex' \
  | grep -v '/accrue/live/' \
  || true)

if [[ -n "${hits}" ]]; then
  echo "verify_core_liveview_runtime_free: FAIL — LiveView socket-runtime ref in always-compiled core:" >&2
  echo "${hits}" >&2
  exit 1
fi
echo "verify_core_liveview_runtime_free: OK"
```
Wire into `.github/workflows/ci.yml` `docs-contracts-shift-left` job (ci.yml:30-66) as a new merge-blocking step:
```yaml
      - name: Core stays LiveView-runtime-free (ENT-07 D-05)
        run: bash scripts/ci/verify_core_liveview_runtime_free.sh
```
**Baseline verified clean (2026-05-23):** `grep -rn "Phoenix.LiveView|Phoenix.Socket|on_mount" accrue/lib/` returns ONLY `oban/middleware.ex:22` (a doc comment, correctly allowlisted). The `^[^#]*` anchor handles same-line trailing comments; a leading-comment-line is excluded because the real-ref alternatives won't match a `#`-prefixed line after `^[^#]*` already consumed non-`#` start. Validate the regex against the live tree during planning (the `def on_mount` alternative will newly match `lib/accrue/live/entitlements.ex`, which is why the `/accrue/live/` exclusion is mandatory).

**Optional complement (D-05):** a cheap OTP-boot assertion that `:phoenix_live_view` is not in core's `extra_applications`. Verified: `accrue/mix.exs` `application/0` `extra_applications` is `[:logger]` only (CONTEXT D-05 states this; confirm in the `application` callback). A test asserting `Application.spec(:accrue, :applications)` / the `extra_applications` list excludes `:phoenix_live_view` is a 3-line belt-and-suspenders check.

### Source-assertion test for the cond-compile guard (clone sigra_test.exs)
```elixir
# Source: test/accrue/integrations/sigra_test.exs:48-61 (source-string assertions)
test "Accrue.Live.Entitlements uses the cond-compile 4-pattern" do
  source = File.read!("lib/accrue/live/entitlements.ex")
  assert source =~ "Code.ensure_loaded?(Phoenix.LiveView)"   # Pattern 1
  assert source =~ "@compile {:no_warn_undefined"            # Pattern 2
  assert source =~ "def on_mount"                            # the on_mount surface
end

test "the module IS loaded (hard dep) and exports on_mount/4" do
  # Unlike Sigra (which may be :nofile), phoenix_live_view is a HARD dep,
  # so this module is ALWAYS defined. Assert the happy case directly.
  assert {:module, Accrue.Live.Entitlements} = Code.ensure_loaded(Accrue.Live.Entitlements)
  assert function_exported?(Accrue.Live.Entitlements, :on_mount, 4)
end
```
Note the divergence from `sigra_test.exs`: Sigra accepts `:nofile` (dep absent); the LiveView guard's dep is hard, so it is ALWAYS loaded — assert the module exists rather than "loaded OR :nofile".

## Runtime State Inventory

Not applicable in the data-migration sense — this phase adds code and three config keys, no stored data, no live-service config, no OS-registered state, no secrets, no build artifacts that carry old names. The one "renamed string" surface is the **doc-wording reconciliation** (D-06), which is a documentation edit, not runtime state.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — no DB writes, no migrations, no schema (CONTEXT code_context: "No migrations, no Ecto schema"). | none |
| Live service config | None — no external service touched. | none |
| OS-registered state | None. | none |
| Secrets/env vars | None — `billable`/`on_deny`/`deny_path` are non-secret host config. | none |
| Build artifacts | None — no package rename, no compiled artifact carries an old name. | none |
| Doc/wording (D-06) | `CLAUDE.md` "LiveView-FREE" claims; `ROADMAP.md` SC#3 (lines 53, 59) + the line-125 "LiveView-free constraint" note; `REQUIREMENTS.md` ENT-07 (already says "runtime-LiveView-free" — verify, line 27); `PITFALLS.md` Pitfall #8; `accrue/mix.exs:78-80` comment; **`oban/middleware.ex:19-24` doc comment (EXTRA, found this session)**. | Lockstep doc edits in this phase's PR (D-06). |

**Verification note on REQUIREMENTS ENT-07:** line 27 already reads "...stays runtime-LiveView-free..." — it may already be reconciled. The planner should diff the current wording against the D-06 target and only edit what still says "no LiveView present". Same for ROADMAP SC#3 line 59 ("compiles and loads with no LiveView present (no required LiveView in core)") which DOES still need the D-06 fix.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir stdlib) + `stream_data` 1.3 (property tests) |
| Config file | `accrue/test/test_helper.exs` (existing) |
| Quick run command | `cd accrue && mix test test/accrue/plug/require_entitlement_test.exs` (single file, < 10s) |
| Full suite command | `cd accrue && mix test` |
| Merge gate (static) | `bash scripts/ci/verify_core_liveview_runtime_free.sh` |
| Plug test helper | `Plug.Test` (`conn/3`, `put_req_header/3`) — ships with `:plug` |
| LiveView test helper | `Phoenix.LiveViewTest` is available (hard dep); but `on_mount/4` is a plain function — prefer direct unit calls with a stub socket (`%Phoenix.LiveView.Socket{assigns: ...}`) over a full live mount for speed. |

### Phase Success Criteria → Test Map
| SC | Behavior | Test Type | Automated Command | File Exists? |
|----|----------|-----------|-------------------|-------------|
| SC#1 | Plug denies (content-negotiated 403; JSON vs text; opaque body; `status:`/`on_deny:` override) when not entitled; allows when entitled | unit (`Plug.Test`) | `mix test test/accrue/plug/require_entitlement_test.exs` | ❌ Wave 0 |
| SC#1 | `require_feature`/`require_plan` macros expand to the plug | unit | `mix test test/accrue/router_test.exs` (extend) | ❌ Wave 0 (or extend existing) |
| SC#2 | Host-configurable billable resolution works on BOTH surfaces (per-guard fn, config global, default `current_scope.user → current_user → nil`) | unit | `mix test test/accrue/entitlements/guard_test.exs` | ❌ Wave 0 |
| SC#2 | LiveView `on_mount` `{:require_feature,…}`/`{:require_plan,…}` → `{:cont,…}`/`{:halt,…}` with deny→redirect degradation | unit (stub socket) | `mix test test/accrue/live/entitlements_test.exs` | ❌ Wave 0 |
| SC#3 | Cond-compile 4-pattern present (source assertion) | source-assertion | `mix test test/accrue/live/entitlements_test.exs` | ❌ Wave 0 |
| SC#3 | No always-compiled core module references the LiveView socket runtime | CI-gate (grep) | `bash scripts/ci/verify_core_liveview_runtime_free.sh` | ❌ Wave 0 |
| SC#3 | (optional) core boots without `:phoenix_live_view` in `extra_applications` | unit | `mix test test/accrue/application_test.exs` (extend) | ❌ Wave 0 |
| SC#4 | Resolve-once: billable resolved exactly once per request/mount; stash is billable-only (not the boolean) | unit (assert assign present + resolver call count) | `mix test test/accrue/entitlements/guard_test.exs` | ❌ Wave 0 |
| SC#4 | Fail-closed: `nil` billable, raising resolver, exception → DENY (both surfaces) | property (`stream_data`) | `mix test test/property/guard_fail_closed_property_test.exs` | ❌ Wave 0 |
| SC#4 | `surface: :plug \| :live` reaches the `[:accrue, :entitlements, :check]` telemetry metadata | unit (`:telemetry` handler attach) | `mix test test/accrue/entitlements/guard_telemetry_test.exs` | ❌ Wave 0 |

### Observable signal per criterion
- **SC#1:** `conn.status == 403`, `conn.halted == true`, `resp_body == ~s({"error":"forbidden"})` for `accept: application/json` else `"Forbidden"`; entitled case `conn.halted == false`.
- **SC#2:** Denied/allowed correctly when the billable comes from a custom fn, from `config :accrue, :entitlements, billable:`, and from the default scope probe; the SAME fn drives both surfaces.
- **SC#3:** `verify_core_liveview_runtime_free.sh` exits 0; source assertions pass; `extra_applications == [:logger]`.
- **SC#4:** Resolver invocation count == 1 across N downstream checks; `:accrue_billable` assign present, `:accrue_entitled` absent; a raising resolver yields a deny; telemetry handler receives `metadata.surface in [:plug, :live]`.

### Sampling Rate
- **Per task commit:** the single relevant test file (`mix test test/accrue/<area>_test.exs`).
- **Per wave merge:** `cd accrue && mix test` (full core suite) + `bash scripts/ci/verify_core_liveview_runtime_free.sh`.
- **Phase gate:** full suite green + the new static gate green + `mix credo --strict` + `mix compile --warnings-as-errors`.

### Wave 0 Gaps
- [ ] `test/accrue/plug/require_entitlement_test.exs` — SC#1 (deny/allow/content-neg/override)
- [ ] `test/accrue/live/entitlements_test.exs` — SC#2/#3 (on_mount + source assertion)
- [ ] `test/accrue/entitlements/guard_test.exs` — SC#2/#4 (billable resolution + resolve-once)
- [ ] `test/accrue/entitlements/guard_telemetry_test.exs` — SC#4 (`surface:` dimension)
- [ ] `test/property/guard_fail_closed_property_test.exs` — SC#4 (fail-closed property; clone `test/property/entitlements_fail_closed_property_test.exs`)
- [ ] `scripts/ci/verify_core_liveview_runtime_free.sh` — SC#3 (static gate) + ci.yml wiring
- [ ] (extend) `test/accrue/router_test.exs` if it exists, else add macro-expansion test
- [ ] No framework install needed — ExUnit + stream_data already present.

## Security Domain

`security_enforcement` is not explicitly set in `.planning/config.json` → treat as enabled. This phase IS a security surface (authorization gating), so security analysis is load-bearing.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V1 Architecture | yes | Fail-closed by design (D-08); deny is the default/easy path; one decision engine (Phase 123). |
| V4 Access Control | **yes (core)** | The guards ARE access control. Authorization (entitlement) is enforced server-side, never client-trusted; billable resolved from server-side assigns only (D-14/D-16), never from request params/headers. |
| V5 Input Validation | yes | `init/1` raises on bad opts (compile-time). `billable:` fn output is untrusted-but-fail-closed; the `accept` header is read for negotiation only, never for authorization. |
| V7 Error Handling/Logging | yes | Errors/exceptions in resolution → deny (D-08). Telemetry metadata is PII-bounded (D-12/D-18); `subject_id` is internal UUID only. |
| V8 Data Protection | yes | Opaque deny body — never leaks which tier gates what (D-10), mirroring Bodyguard "don't leak existence". `ctx` carries no subscription ids / price_ids / PII (D-12). |
| V2 Authn / V3 Session | no | Out of scope — authentication is the host's upstream `on_mount`/pipeline (D-20). The guard gates entitlement only. |
| V6 Cryptography | no | No crypto in this phase. |

### Known Threat Patterns for Plug/LiveView authorization guards
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Fail-open on resolver error/exception | Elevation of Privilege | `try/rescue/catch → deny`; deny is the default path (D-08, PITFALLS #1). |
| Entitlement-structure enumeration via deny body | Information Disclosure | Opaque body; `required` only in host-owned `on_deny` ctx, never auto-serialized (D-10/D-12). |
| Billable spoofing via request input | Spoofing / Elevation | billable resolved from server-side assigns only; never from params/headers (D-14/D-16). `accept` header used for negotiation, never authz. |
| LiveView mount before auth populates scope | Elevation (bypass) | Document auth `on_mount` must precede entitlement guard (D-20, Pitfall 4). |
| Redirect loop / open redirect via `on_deny` | Denial of Service / (open-redirect if host passes user input) | No redirect default; document deny target must be outside the gate; optional self-redirect fall-through (D-13, Pitfall 6). Hosts own redirect targets (declarative paths, not user input). |
| Stashing the boolean decision (stale-grant) | Tampering / EoP | Stash billable only, never the decision (D-17, Pitfall 3). |

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| "Core `accrue` is LiveView-FREE (no `phoenix_live_view` present)" | "Core is LiveView-**runtime**-free; `phoenix_live_view` is a required core dep for `Phoenix.Component`" | This phase (D-01/D-06) | The literal claim was always false (16 core modules `use Phoenix.Component`). Reconciled in-PR. |
| Guard belongs in `accrue_admin` (stale PITFALLS #8) | Guard in core `accrue` (`lib/accrue/live/entitlements.ex`), cond-compiled (D-03) | This phase | Gating host LiveViews must not force pulling in the admin UI. |
| 402 Payment Required for plan gating | 403 Forbidden, opaque, content-negotiated (D-09) | This phase | 402's 2025-26 revival is agentic micropayments (x402/Stripe MPP), not SaaS gating; browsers/proxies mishandle 402. 402 only opt-in. |
| Multi-shape billable (`atom \| {assign,path} \| fn \| MFA`) | Single 1-arity fn `(conn\|socket -> billable\|nil)` (D-14) | This phase | One mental model; solves surface symmetry for free. |

**Deprecated/outdated:**
- The `oban/middleware.ex:19-24` doc comment ("LiveView is a hard dependency of `accrue_admin` only, never `accrue`") is now incorrect — reconcile per D-06 (EXTRA finding).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | NimbleOptions 1.1 supports `type: {:fun, 1}` for the `billable:` schema key | Config schema example | LOW — fallback is `type: :any` + arity-check at use; either way the value is validated. Verify against installed NimbleOptions during planning. |
| A2 | Adding an optional `opts`/`surface:` arg to Phase 123's `entitled?/2`/`has_active_plan?/2` is the cleanest way to get `surface:` onto the same `:check` span | OTel allowlist / D-18 wiring | LOW — additive, non-breaking; alternative is a guard-owned wrapper span. Planner picks; both satisfy D-18. |
| A3 | `Phoenix.LiveViewTest` full-mount is heavier than a stub-socket unit test for `on_mount/4` | Validation Architecture | LOW — `on_mount/4` is a plain function; stub-socket testing is standard and faster. Full live-mount can be added if desired. |
| A4 | The grep-gate regex `^[^#]*((import|alias) Phoenix.LiveView|...)` correctly excludes the `oban/middleware.ex:22` doc comment | Static merge gate | LOW — verified the only baseline hit is that doc comment; the regex must be re-tested against the live tree at plan time (and against the new `live/entitlements.ex`, which is why `/accrue/live/` is excluded). |
| A5 | `extra_applications` in `accrue/mix.exs` is `[:logger]` only (D-05 claim) | Static merge gate / optional boot assertion | LOW — CONTEXT D-05 asserts it; confirm by reading the `application/0` callback in `accrue/mix.exs` during planning. |

## Open Questions (RESOLVED)

1. **Where does `surface:` get merged into the `:check` span?**
   - What we know: D-18 says "add a `surface:` key to the check metadata"; Phase 123's `entitled?/2` builds metadata internally (entitlements.ex:213-224) and has no `surface:` param today.
   - What's unclear: whether the planner threads an additive `opts` through `entitled?/2`/`has_active_plan?/2` (touches Phase 123 public arity, additively) or has the guard emit its own wrapper span / use process-dict handoff.
   - Recommendation: additive `opts \ []` param on the two gate fns, merge `surface:` into span metadata. Truest to D-18, non-breaking, matches house style. Flag for the planner to confirm the public-arity touch is acceptable (it is additive, so within CONTEXT's reversible/additive posture).
   - **RESOLVED:** additive `surface:` opts go on the INTERNAL `Accrue.Entitlements.entitled?/3` + `has_active_plan?/3` predicates only; the public `Accrue` facade delegates stay arity 2. `surface:` is a library-internal telemetry dimension set by the guards, not a host-facing option, so it never reaches the public facade. The shared Guard engine calls `Accrue.Entitlements.entitled?(billable, feature, surface: surface)` directly (Plan 01 Task 3 builds the 3-arity internal predicates; Plan 02 Task 1 consumes them).

2. **Does `require_feature`/`require_plan` support per-call `on_deny:`/`billable:`?**
   - What we know: D-07 says macros are "thin" sugar over `feature:`; CONTEXT specifics show only `require_feature :api_access`.
   - What's unclear: whether the macros should accept an optional opts keyword (`require_feature :api_access, on_deny: …`).
   - Recommendation: keep the macros single-arg (just the atom) for least-surprise; route advanced opts through the canonical `plug Accrue.Plug.RequireEntitlement, …` form. Document this split. (Reversible — a `/2` macro can be added later.)
   - **RESOLVED:** single-arg `require_feature`/`require_plan` macros (the bare atom only); advanced `on_deny:`/`billable:`/`status:` overrides go through the canonical `plug Accrue.Plug.RequireEntitlement, …` form. A `/2` macro can be added additively later if a host need is sourced.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/Mix | all build/test | ✓ (assumed CI baseline) | 1.17+/1.18 | — |
| `:plug` | the plug guard | ✓ (mix.lock) | 1.18.x | — |
| `:phoenix_live_view` | the LiveView guard / `Phoenix.Component` | ✓ (mix.lock, hard dep) | 1.1.30 | — |
| `:jason` | JSON deny body | ✓ (mix.lock) | 1.4.x | — |
| `:stream_data` | fail-closed property test | ✓ (mix.exs, `:dev`/`:test`) | 1.3.0 | — |
| `bash` + `grep -E` | static merge gate (CI) | ✓ (ubuntu-24.04 runner, ci.yml:36) | — | — |

No missing dependencies. No external services. The phase is code + config + CI-script + docs only.

## Sources

### Primary (HIGH confidence — read this session)
- `124-CONTEXT.md` (D-01..D-21, canonical refs) — the authoritative WHAT.
- `123-CONTEXT.md` (D-06..D-10 fail-closed, D-16..D-21 telemetry, D-21 ledger boundary) — the contract enforced.
- `accrue/lib/accrue/integrations/sigra.ex` (cond-compile 4-pattern, lines 31-32, 52).
- `accrue/test/accrue/integrations/sigra_test.exs` (source-assertion test shape, lines 48-61).
- `accrue/lib/accrue/plug/put_connected_account.ex` (init validate/raise, lines 33-48).
- `accrue/lib/accrue/plug/put_operation_id.ex` (call/2 idiom).
- `accrue/lib/accrue/webhook/plug.ex` (pure-Plug `send_resp`+`Jason.encode!`+`halt` deny, lines 51-53; `get_req_header`, line 65).
- `accrue/lib/accrue/router.ex` (`accrue_webhook/2` macro precedent, lines 45-49).
- `accrue_admin/lib/accrue_admin/auth_hook.ex` (`on_mount/4` shape, `{:cont,…}`/`{:halt, redirect}`, lines 1-33).
- `accrue/lib/accrue/entitlements.ex` (the gate fns the guards call, lines 48-153; span builder 213-224).
- `accrue/lib/accrue.ex` (the 4 public delegates, lines 34-62).
- `accrue/lib/accrue/config.ex` (`:entitlements` schema 356-401; `validate_descending` custom-check 951; boot validation 476-487; `entitlements/0` accessor 849-850).
- `accrue/lib/accrue/telemetry/otel.ex` (`@allowed_attributes` dual atom+string map, lines 12-41).
- `accrue/lib/accrue/oban/middleware.ex` (the doc-comment LiveView mention, lines 19-24 — EXTRA D-06 hit).
- `accrue/mix.exs` (phoenix optional:true line 77; phoenix_live_view non-optional line 80).
- `accrue/mix.lock` (resolved versions: plug 1.18, phoenix_live_view 1.1.30, phoenix 1.8.7, jason 1.4).
- `scripts/ci/verify_processor_support_matrix.sh` (grep-gate model for D-05).
- `scripts/ci/compile_matrix.sh` (without-X cell model — rejected for this gate per D-05).
- `.github/workflows/ci.yml` (`docs-contracts-shift-left` merge-blocking job, lines 30-66).
- `.planning/REQUIREMENTS.md` (ENT-06 line 26, ENT-07 line 27).
- `.planning/ROADMAP.md` (Phase 124 lines 50-59; LiveView-free note line 125).

### Secondary (MEDIUM confidence — verified)
- WebSearch: Plug content negotiation via `conn.req_headers` accept-header parse (confirms pure-Plug approach over `Phoenix.Controller.get_format/1`; cross-checked against `Webhook.Plug` precedent). https://github.com/dwyl/content , https://github.com/dwyl/phoenix-content-negotiation-tutorial

### Tertiary (LOW confidence)
- None. All claims are grounded in source or a verified pattern; assumptions are catalogued in the Assumptions Log.

## Metadata

**Confidence breakdown:**
- Plug skeleton + deny: HIGH — directly cloned from `PutConnectedAccount` + `Webhook.Plug`; content-neg cross-verified.
- LiveView guard + cond-compile: HIGH — cloned from `Sigra` + `AuthHook`; baseline grep confirms clean core.
- Static merge gate: HIGH (mechanism) / MEDIUM (exact regex) — model is established; regex must be re-validated against the live tree at plan time (A4).
- Telemetry `surface:` wiring: MEDIUM — D-18 intent clear; the exact arity-vs-wrapper choice is an open question (A2/OQ1).
- Config schema additions: HIGH (structure) / MEDIUM (`{:fun, 1}` type, A1).
- Fail-closed/security: HIGH — inherits Phase 123's audited contract; deny is the default path.

**Research date:** 2026-05-23
**Valid until:** 2026-06-22 (30 days — stable; the only moving part is the upstream NimbleOptions `{:fun, 1}` type confirmation).

## RESEARCH COMPLETE
