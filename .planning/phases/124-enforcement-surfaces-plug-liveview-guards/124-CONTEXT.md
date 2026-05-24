# Phase 124: Enforcement Surfaces — Plug + LiveView Guards - Context

**Gathered:** 2026-05-23
**Status:** Ready for planning

<domain>
## Phase Boundary

A Phoenix developer can gate **both controller routes and host LiveViews** on
entitlement, with the same Phase 123 **fail-closed** contract, while core `accrue`
remains **runtime-LiveView-free** (no LiveView socket-lifecycle coupling) for
headless/API hosts. Covers **ENT-06** (controller Plug guard) and **ENT-07**
(conditionally-compiled LiveView `on_mount` guard + the "core stays runtime-LiveView-free"
merge-blocking check).

**In scope:**
- `Accrue.Plug.RequireEntitlement` — one workhorse controller Plug (`feature:`/`plan:` opts).
- `require_plan` / `require_feature` thin router macros in `Accrue.Router` (sugar over the plug).
- `Accrue.Live.Entitlements` — conditionally-compiled `on_mount` guard (host LiveViews).
- A **single shared billable-resolution convention** + **single shared deny convention** across both surfaces.
- A **low-ceremony static merge-blocking gate** proving no always-compiled core module references the LiveView socket runtime.
- A **lockstep doc/wording reconciliation** of the (now-corrected) "LiveView-free" constraint across CLAUDE.md / ROADMAP SC#3 / REQUIREMENTS ENT-07 / PITFALLS.md.

**Out of scope (later phases — do not build here):** Resolver behaviour provider-honesty
+ `entitlements:` capability-matrix rows + drift gate (125, ENT-08); lifecycle→entitlement
truth-table SSOT + `past_due` grace knob (125, ENT-09); admin entitlements view + `guides/entitlements.md`
+ JTBD flip (126, ENT-11/12); optional Stripe-native webhook→cache sync + `grant`/`revoke` + ledger
writes (127, ENT-10). Atomic seat *enforcement* stays host-owned (documented recipe, never a core API).
</domain>

<decisions>
## Implementation Decisions

> Ran in **cohesive-synthesis mode** (standing user preference, config-enforced via
> `discuss_auto_all_gray_areas` + `discuss_high_impact_confirm` + `discuss_auto_resolve_low_impact`).
> Four parallel `gsd-advisor-researcher` agents (2 first-pass + 2 deep-reframe) researched
> each gray area: pros/cons/tradeoffs, idiomatic Elixir/Plug/Phoenix/LiveView, cross-language/
> cross-lib lessons (Oban/Oban Web, Flop.Phoenix, phoenix_live_dashboard, petal_components,
> Bodyguard, pricing_plans, Cashier, Pundit/CanCanCan, Phoenix `phx.gen.auth` scopes,
> Stripe Entitlements, HTTP 402 revival), DX, security, principle-of-least-surprise, footguns,
> and `.planning/research/`. **Zero open forks.** The user explicitly delegated the one
> roadmap/doc-reconciling decision ("personally I don't care toooo much... research and decide"),
> so it is auto-resolved below with the doc reconciliation captured as a planned task.

### A — LiveView posture & the "core stays runtime-LiveView-free" gate (ENT-07, SC#2/#3) — THE REFRAME

- **D-01 — Relax "LiveView-FREE" → "LiveView-*runtime*-free" (CONFIRMED, decisive).** The literal
  constraint ("core compiles/loads with NO `phoenix_live_view` present") is **already false and was
  self-imposed purity theater.** Verified fact: `Phoenix.Component` + the `~H` sigil ship **only**
  inside the `phoenix_live_view` hex package, and core `accrue` already has **17 email modules + 3
  invoice-render modules** (`lib/accrue/emails/*.ex`, `lib/accrue/invoices/{components,layouts,styles}.ex`)
  that `use Phoenix.Component` — the single-source-of-truth HEEx→email+PDF spine, a headline feature.
  So `phoenix_live_view` is **already a hard, correct, non-optional core dependency**; removing it is
  infeasible without gutting email/invoice rendering. This is the ecosystem **norm**, not an anti-pattern:
  Flop.Phoenix, phoenix_live_dashboard, and petal_components all require `phoenix_live_view`
  **non-optionally** purely for `Phoenix.Component`. **Nobody is harmed** — it adds no socket runtime,
  no `extra_applications` entry (core's is `[:logger]` only), and no public-API coupling to the LiveView
  lifecycle. The real, valuable promise — "a host can run Accrue without serving LiveView, and Accrue's
  public APIs never assume a socket" — is fully preserved.
- **D-02 — `accrue/mix.exs`: KEEP `{:phoenix_live_view, "~> 1.1"}` non-optional. No dep change.**
  Do NOT make it optional (that path = conditionally-compile ~20 working templating modules = breaks the
  email/PDF value prop, out of phase domain, rejected). **Update the line-78–80 comment** to state plainly:
  it is a required core dep providing `Phoenix.Component`/`~H` for the email + invoice render spine and
  the cond-compiled guard; core uses **no** LiveView socket runtime (no `Phoenix.LiveView` / `on_mount` /
  `Socket` in always-compiled code) and it never appears in `extra_applications`.
- **D-03 — Guard lives in CORE `accrue`, NOT `accrue_admin`, NOT a new package.** File:
  `accrue/lib/accrue/live/entitlements.ex` (`Accrue.Live.Entitlements`). It gates the **host's own**
  LiveViews, so putting it in `accrue_admin` (PITFALLS.md's stale original stance) would force host
  route-gating to pull in the entire admin dashboard UI — a layering inversion + least-surprise
  violation. A 4th `accrue_live` package is over-engineering for one ~40-line module. (ARCHITECTURE.md
  Anti-Pattern 4 + the lines 253–306 reconciliation already supersede the stale PITFALLS stance.)
- **D-04 — Conditionally compile the guard via the canonical 4-pattern, cloned verbatim from
  `Accrue.Integrations.Sigra`:** `if Code.ensure_loaded?(Phoenix.LiveView) do defmodule … end` +
  `@compile {:no_warn_undefined, [Phoenix.LiveView, Phoenix.Component]}` + narrow
  `import Phoenix.LiveView, only: [redirect: 2]` / `import Phoenix.Component, only: [assign: 3, assign_new: 3]`.
  This is **belt-and-suspenders / self-documenting**, NOT load-bearing in CI: because `phoenix_live_view`
  is a hard dep, `Phoenix.LiveView` is always loadable, so the elision branch is never taken in practice.
  Keep it anyway — it makes the "no socket coupling in always-compiled code" intent grep-able, future-proofs
  against a host that excludes the dep via override/diamond edge cases, and costs ~3 lines. **No ExDoc/
  dialyzer edge cases** here precisely because the module always compiles (the genuine cond-compile
  pitfalls only bite when the dep can actually be absent). Add a **source-assertion test** mirroring
  `accrue/test/.../sigra_test.exs` (assert the module source contains the `Code.ensure_loaded?(Phoenix.LiveView)`
  guard) so the pattern can't silently regress.
- **D-05 — Merge gate = low-ceremony STATIC check, NOT a `without_live_view` compile matrix cell.**
  Add a merge-blocking grep/Credo check (same shape as Phase 123's **D-14 one-way-dependency** grep in the
  verify step) that fails the build if any **always-compiled** core module — i.e. anything outside the
  `if Code.ensure_loaded?(Phoenix.LiveView)` block under `lib/accrue/live/` — references `Phoenix.LiveView`,
  `on_mount`, `Phoenix.LiveView.Socket`, or `Phoenix.Socket`. (Allowlist: doc-comment hits like the one in
  `oban/middleware.ex` are fine; gate on real references.) This encodes the **actual invariant** ("no
  LiveView runtime coupling"), is cheap and deterministic, and is honest. **Optionally complement** with a
  cheap OTP-boot assertion that core boots without `:phoenix_live_view` in `extra_applications` (already
  true). Do **not** attempt a real "no phoenix_live_view present" compile cell — infeasible + ceremony.
- **D-06 — Doc/wording reconciliation (LOCKSTEP, a planned task in this phase, not just CONTEXT):**
  1. **CLAUDE.md** — the "core `accrue` stays LiveView-free / LiveView is hard dep in accrue_admin, not in
     core" claims → "core stays LiveView-**runtime**-free (uses `Phoenix.Component` for email/invoice
     rendering; no socket runtime; never in `extra_applications`)."
  2. **ROADMAP.md SC#3** + **REQUIREMENTS.md ENT-07** — "compiles and loads with no LiveView present
     (no required LiveView in core)" → "shipped via conditional compilation; a merge-blocking check proves
     **no always-compiled core module references the LiveView socket runtime** (`Phoenix.LiveView` /
     `on_mount` / `Socket`)."
  3. **PITFALLS.md** — the stale "guard must live in admin / `phoenix_live_view` must be absent or optional
     in core" stance is **corrected** to match ARCHITECTURE.md Anti-Pattern 4 (cond-compile-in-core).
  Treat exactly like Phase 123's plural-telemetry ROADMAP/ENT-05 reconcile (D-16): a small doc fix executed
  *within* this phase, in the same PR as the code.

### B — Controller Plug guard surface (ENT-06, SC#1)

- **D-07 — Ship ONE workhorse plug + thin named macros (mirrors the `accrue_webhook` precedent).**
  `Accrue.Plug.RequireEntitlement` (`@behaviour Plug`, lives at `accrue/lib/accrue/plug/require_entitlement.ex`
  next to `put_operation_id.ex` / `put_connected_account.ex`). `init/1` validates opts at compile time and
  **raises on bad opts** (clone `PutConnectedAccount`'s init-validation style): exactly one of
  `feature: atom` / `plan: atom | String.t()`; optional `billable:`; optional `on_deny:`; optional `status:`.
  Plus thin **`require_feature/1` / `require_plan/1` macros in `Accrue.Router`** (extend the existing
  `import Accrue.Router`) that expand to `plug Accrue.Plug.RequireEntitlement, feature: …`. Document the plug
  as canonical, macros as sugar. (`plug ~> 1.16` is a hard dep — the plug needs neither Phoenix nor LiveView,
  works in plain `Plug.Router` and Phoenix alike.)
- **D-08 — The guard NEVER makes its own allow decision.** It delegates the entire allow/deny to Phase 123's
  `try/rescue/catch`-wrapped `Accrue.entitled?/2` / `Accrue.has_active_plan?/2`. nil/unresolvable/wrong-type
  billable, resolver errors, exceptions → `false` → deny → halt. Fail-closed end-to-end by construction
  (PITFALLS #1).

### C — Deny semantics (SHARED across both surfaces) (SC#1)

- **D-09 — Default deny = `403 Forbidden`, content-negotiated, OPAQUE body. 403 beats 402 decisively.**
  `application/json` → `{"error":"forbidden"}`; otherwise `text/plain "Forbidden"` (via
  `Phoenix.Controller.get_format/1` / `accepts`). 403 is the correct authz semantic (the user *is*
  authenticated; they merely lack an entitlement — Bodyguard/Pundit/CanCanCan/every Phoenix authz lib lands
  here). **402 Payment Required is rejected as the default**: its 2025–26 revival (x402 / Stripe MPP) is about
  *agentic/on-chain micropayment negotiation*, not SaaS plan gating; browsers have no native 402 UX and many
  proxies/CDNs/clients mishandle it. Offer 402 only as an opt-in `status: 402` for pure-API hosts, documented
  as non-default. **No HTML templates** in the built-in deny (core stays Phoenix-view-free).
- **D-10 — Opaque body is a SECURITY decision.** The default deny body does **not** echo the required
  feature/plan/subscription — that would leak entitlement structure (which tiers gate what) to probing.
  Mirrors Bodyguard's "don't leak existence." Hosts that want a machine-readable reason opt in via `on_deny`
  (where they own the disclosure). No timing concern: the gate is a local DB read with no secret-dependent
  branch.
- **D-11 — `on_deny` override is TIERED + declarative-first (OVERTURNS the first pass's closure-only shape).**
  Resolution order: **per-guard opt → `config :accrue` global default → built-in 403** (the proven
  `pricing_plans` precedence). Value forms, declarative first, function/MFA as the escape hatch:
  `:forbidden` | `{:redirect, path}` | `{status, body}` | `(container, ctx -> result)` | `{m, f, a}`.
  Most hosts write `on_deny: {:redirect, "/pricing"}` or rely on the 403 default; only advanced hosts write a
  function. **No redirect default** — that avoids Laravel Cashier's classic hardcoded-`/billing` footgun and
  JSON-API 302 loops.
- **D-12 — Deny-context map `ctx` (bounded, no PII, no plan internals):**
  `%{guard: :feature | :plan, required: <atom>, reason: <telemetry-internal atom>, billable: <opaque term | nil>, surface: :plug | :live}`.
  `required` is the atom the host already declared in their own router (safe to hand back to *their* fn) but
  is **never** auto-serialized into the wire response. `reason` reuses the Phase 123 atom set
  (`:not_entitled | :no_active_subscription | :unmapped_plan | :error`). Never subscription ids / price_ids /
  customer PII.
- **D-13 — Redirect-loop guard.** Document that the deny destination MUST live outside the gated
  pipeline/`live_session`. Optionally detect a self-redirect and fall through to the plain 403/halt
  (PITFALLS #8).

### D — Billable resolution (SHARED, SINGLE clean idiom) (SC#2)

- **D-14 — `billable:` is a SINGLE 1-arity function `(conn | socket -> billable | nil)` (OVERTURNS the
  first pass's four-shape `atom | {assign,path} | fn | MFA` design — that was too clever, a least-surprise
  violation).** One mental model; the **same function works in both guards** (Plug receives `conn`, LiveView
  receives `socket`) — this solves the surface-symmetry problem for free. Nil-safe by construction: a missing
  assign / nil scope / scope without `.user` all collapse to `nil` → Phase 123 fail-closed `false`. **Never
  raises.**
- **D-15 — Default "just works" for Phoenix 1.8 with NO `billable:` opt:** probe
  `conn/socket.assigns.current_scope.user` (the 1.8 `phx.gen.auth` scopes convention) → fall back to
  `current_user` → fall back to `nil` (fail closed). Host overrides globally via `config :accrue, :entitlements,
  billable: &MyApp.billable/1` (or the per-guard `billable:` opt). Org-billed apps:
  `billable: &(&1.assigns.current_scope.org)`.
- **D-16 — Do NOT reuse `Accrue.Auth.current_user/1` as the resolver.** billable ≠ user in org/team/account-
  billed apps, and `Accrue.Auth` is an effectful facade. Billable resolution is a **pure read from assigns**;
  the host's 1-arity fn is the adapter-thin seam. No required Sigra/Lockspire coupling; billable stays opaque
  (Phase 123 D-09).

### E — Resolve-once + telemetry (SC#4)

- **D-17 — Resolve once per request/mount via `assign_new(:accrue_billable, …)`** (conn for Plug, socket for
  LiveView) so multiple `entitled?`/`features_for` checks downstream fold to a single resolution (PITFALLS #4).
  Stash the **billable only**, never the boolean decision (decisions are feature/plan-specific and checks are
  cheap local reads — Phase 123 D-09).
- **D-18 — Reuse the Phase 123 telemetry event; add NO new guard event.** The guard inherits
  `[:accrue, :entitlements, :check, :start | :stop | :exception]` for free by calling `Accrue.entitled?/2`.
  **Add a `surface: :plug | :live` key to the check metadata** so operators can distinguish a route/mount
  deny from an in-template `if`. This requires adding `:surface` (atom + string forms) to the OTel allowlist
  in `lib/accrue/telemetry/otel.ex` `@allowed_attributes` (small additive change, same as Phase 123 D-19).
- **D-19 — ZERO ledger rows (inherits Phase 123 D-21).** The guard path calls no `Accrue.Events.record/1`;
  per-check/per-gate decisions are telemetry-only. No new processor calls on the gate path.

### F — LiveView guard shape & surface-symmetry (SC#2/#4)

- **D-20 — `on_mount` shape:** `on_mount {Accrue.Live.Entitlements, {:require_feature, :api_access}}` and
  `{:require_plan, :pro}` clauses (the only shape that fits LiveView — billable is per-socket/session, not
  known at route-compile time). Each returns `{:cont, socket}` (entitled) or `{:halt, ...}` (deny), delegating
  to `Accrue.entitled?/2` / `Accrue.has_active_plan?/2`. Mirrors the existing
  `AccrueAdmin.AuthHook.on_mount/4` precedent. The guard gates **entitlement only** — authentication is the
  host's upstream `on_mount` / `live_session`; document the assign-ordering requirement (auth on_mount must
  run first to populate the billable assign).
- **D-21 — Surface-symmetric deny.** One billable fn + one deny enum across both surfaces; the library
  surface-translates the declarative forms. The one irreducible asymmetry: a LiveView socket cannot emit a raw
  403, so on the LiveView surface `:forbidden` **degrades to** `{:halt, socket |> put_flash(...) |> redirect(to: deny_path)}`,
  where `deny_path` comes from `config :accrue, :entitlements, deny_path:` (sane default `"/"`). `{:redirect, path}`
  → `{:halt, redirect(socket, to: path)}`. Hosts never see `conn`-vs-`socket` plumbing in their config.

### Config surface added this phase (extends Phase 123's `:entitlements` keyword list)
- `billable:` — global default billable resolver fn (optional; default probes `current_scope.user → current_user → nil`).
- `on_deny:` — global default deny handler (optional; default = content-negotiated 403).
- `deny_path:` — LiveView fallback redirect target for `:forbidden`/redirect denies (default `"/"`).
All remain **runtime** host-owned data (read via `Application.get_env`, boot-validated), consistent with
Phase 123 D-01. Extend the `:entitlements` NimbleOptions schema fragment accordingly.

### Claude's Discretion (auto-applied; no fork surfaced — user delegated)
All research-backed, mutually coherent, and either reversible/additive or explicitly delegated by the user:
relaxing "LiveView-free" → "LiveView-runtime-free" + the doc reconciliation (D-01/D-06), keeping
`phoenix_live_view` non-optional (D-02), guard-in-core cond-compiled (D-03/D-04), static merge gate
(D-05), one-plug-plus-macros (D-07), 403-not-402 opaque default (D-09/D-10), tiered declarative `on_deny`
(D-11), single 1-arity `billable:` fn (D-14/D-15), `surface` telemetry dimension (D-18).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope & requirements
- `.planning/ROADMAP.md` §"Phase 124" — goal, depends-on (Phase 123), the 4 success criteria. **NOTE:** SC#3
  wording is reconciled this phase per D-06 (literal "no LiveView present" → "no LiveView runtime coupling").
- `.planning/REQUIREMENTS.md` — ENT-06, ENT-07 (ENT-07 wording reconciled per D-06).

### Phase 123 (the contract this phase enforces — read first)
- `.planning/phases/123-config-core-gate-api-foundation/123-CONTEXT.md` — locked decisions: fail-closed
  contract (D-06..D-10), `:entitlements` config schema (D-01..D-05), Resolver seam (D-11..D-13), telemetry
  (D-16..D-20, plural `[:accrue, :entitlements, :check]`), ledger boundary (D-21), one-way dependency D-14.
- `accrue/lib/accrue/entitlements.ex` — the 4 gate fns the guards call (`entitled?/2`, `has_active_plan?/2`,
  `features_for/1`, `entitlement_quantity/2`).
- `accrue/lib/accrue.ex` — the 4 public delegates.

### Milestone research (HIGH confidence; convergent — already specifies this phase's design)
- `.planning/research/ARCHITECTURE.md` — §"runtime-LiveView-free reconciliation" (~lines 253–306),
  Anti-Pattern 4 (~461–469), enforcement-surface rows (~24, ~91, ~134), build-order step 4 (~382–386).
  This is the authoritative integration design; supersedes PITFALLS.md's stale guard-in-admin stance.
- `.planning/research/PITFALLS.md` — Pitfall #1 (fail-open), #4 (resolve-once), #8 (redirect loop /
  LiveView-free). **The Pitfall-8 "guard in admin / phoenix_live_view absent-or-optional" stance is STALE —
  correct it per D-06.**
- `.planning/research/SUMMARY.md`, `FEATURES.md`, `JTBD-FRONTIER.md` — convergent design, competitor delta,
  "thin layer over local state."

### Project guides & conventions
- `CLAUDE.md` — §"Conditional Compilation for Optional Deps" (the documented 4-step pattern);
  config-vs-runtime boundary; telemetry mandate; Monorepo Layout. **The "LiveView-FREE" claims are
  reconciled this phase per D-06.**
- `accrue/guides/lifecycle_semantics.md` — `active` = "counts for entitlement purposes."

### Source files to clone/extend (full paths)
- `accrue/lib/accrue/integrations/sigra.ex` — **the** conditional-compilation 4-pattern to clone for the
  LiveView guard (`Code.ensure_loaded?` + `@compile {:no_warn_undefined, …}`).
- `accrue/lib/accrue/plug/put_connected_account.ex` + `put_operation_id.ex` — existing core Plug idioms
  (`@behaviour Plug`, `init/1` opts-validation/raise-on-bad, MFA+conn convention, security comments).
- `accrue/lib/accrue/router.ex` — the `accrue_webhook` router-macro precedent for the `require_*` sugar.
- `accrue_admin/lib/accrue_admin/auth_hook.ex` — the `on_mount/4` precedent (`{:cont, …}`/`{:halt, redirect(…)}`).
- `accrue/lib/accrue/auth.ex` — host-auth facade (do NOT use as the billable resolver — D-16).
- `accrue/lib/accrue/config.ex` — `:entitlements` schema + boot validation (extend with `billable`/`on_deny`/`deny_path`).
- `accrue/lib/accrue/telemetry/otel.ex` — `@allowed_attributes` (add `:surface`, atom + string).
- `accrue/lib/accrue/oban/middleware.ex` — contains a *doc-comment* `Phoenix.LiveView` mention; the merge-gate
  allowlist must tolerate doc comments (gate on real refs only).
- `accrue/mix.exs` — line 77–80 dep block + comment to update (keep `phoenix_live_view` non-optional; D-02).
- `.github/workflows/ci.yml` — existing merge-blocking verify-script step to extend with the static gate (D-05).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`Accrue.Integrations.Sigra`** (`lib/accrue/integrations/sigra.ex`): the canonical cond-compile template —
  clone its `if Code.ensure_loaded?(...) do defmodule … end` + `@compile {:no_warn_undefined, …}` shape for
  `Accrue.Live.Entitlements`. Its test asserts the source contains the guard — mirror that.
- **`Accrue.Plug.PutConnectedAccount` / `PutOperationId`**: existing `@behaviour Plug` with `init/1`
  validation, MFA+conn convention, and security-comment discipline — the template for `RequireEntitlement`.
- **`Accrue.Router.accrue_webhook/2`**: the router-macro-over-a-plug precedent for `require_feature`/`require_plan`.
- **`AccrueAdmin.AuthHook.on_mount/4`**: the `on_mount` shape (`{:cont,…}` / `{:halt, redirect(…)}`).
- **`Accrue.entitled?/2` / `has_active_plan?/2`** (Phase 123): the fail-closed delegate the guards call —
  no re-implementation; the guard never makes its own allow decision.
- **`Accrue.Telemetry.span/3`** + the `[:accrue, :entitlements, :check]` event: inherited by the guard for free.

### Established Patterns
- **Conditional compilation (4-pattern):** optional dep → `@compile {:no_warn_undefined}` → `Code.ensure_loaded?`
  guard at `defmodule` → runtime dispatch by config. Documented in CLAUDE.md; used for `:sigra`/`:opentelemetry`.
- **Core Plug idiom:** `@behaviour Plug`, `init/1` validates+raises, `call/2` reads `conn.assigns`.
- **Config-vs-runtime:** adapter *modules* via `compile_env!`; host *data*/flags via runtime `get_env`,
  boot-validated. Guard config (`billable`/`on_deny`/`deny_path`) is runtime host data → extends `:entitlements`.
- **One-way dependency (Phase 123 D-14):** `Accrue.Entitlements.*` reads billing; nothing reverse. The new
  guards depend on `Accrue.Entitlements` only — keep acyclic.
- **Merge-blocking grep gates** already exist (D-14 dependency check; processor-support-matrix drift verifier)
  — model the LiveView-runtime-coupling gate on these.

### Integration Points
- New `accrue/lib/accrue/plug/require_entitlement.ex` (unconditional core).
- New `accrue/lib/accrue/live/entitlements.ex` (conditionally compiled).
- Edit `accrue/lib/accrue/router.ex` (add `require_feature`/`require_plan` macros).
- Edit `accrue/lib/accrue/config.ex` (`:entitlements` schema: `billable`/`on_deny`/`deny_path`).
- Edit `accrue/lib/accrue/telemetry/otel.ex` (`:surface` allowlist).
- Edit `.github/workflows/ci.yml` + a `scripts/`-style static gate (LiveView-runtime-coupling check).
- Doc edits: `CLAUDE.md`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/research/PITFALLS.md`,
  and the `accrue/mix.exs` comment (D-06).
- No migrations, no Ecto schema, no webhook code in this phase.
</code_context>

<specifics>
## Specific Ideas

- Caller ergonomics targets (least-surprise, copy-paste-able):
  - Controller: `plug Accrue.Plug.RequireEntitlement, feature: :api_access` — or sugar
    `require_feature :api_access` / `require_plan :pro` inside the router.
  - LiveView: `on_mount {Accrue.Live.Entitlements, {:require_feature, :api_access}}` in a `live_session`.
  - Override: `plug Accrue.Plug.RequireEntitlement, feature: :api_access, on_deny: {:redirect, "/pricing"}`.
  - Org-billed: `config :accrue, :entitlements, billable: &(&1.assigns.current_scope.org)`.
- The "one billable fn, one deny enum, surface-translated" model is the single mental model the docs should teach.
- Default 403 must be impossible to fail open: the deny path is the *easy* path (PITFALLS #1 mandate).

</specifics>

<deferred>
## Deferred Ideas

- **Resolver provider-honesty + `entitlements:` capability-matrix rows + merge-blocking drift gate (ENT-08)** → Phase 125.
- **Lifecycle→entitlement truth-table SSOT + `past_due` grace knob (ENT-09)** → Phase 125 (124 inherits whatever `Subscription.active?/1` decides).
- **Read-only admin entitlements view + `guides/entitlements.md` + JTBD ⛔→✅ flip (ENT-11/12)** → Phase 126.
- **Optional Stripe-native webhook→cache sync + `grant`/`revoke` + ledger writes (ENT-10)** → Phase 127 (off by default).
- **Atomic seat enforcement / membership management** — host-owned; documented recipe, never a core API.
- **`fetch_entitled/2` / `fetch_entitlement_quantity/2` `{:ok,bool}|{:error,_}` diagnostic API** — additive-only on a sourced host need (Phase 123 D-07; the denied-vs-couldn't-check distinction lives in telemetry `reason`).
- **Decoupling email/invoice templating from `phoenix_live_view`** (so a literal "no LiveView package" build becomes possible) — only if a real headless-host need is sourced; today it would gut the email/PDF spine for a dep nobody is harmed by. Not worth it.
- **A dedicated guard-deny telemetry event** (distinct from `:check`) — additive later only if operators need route-level deny analytics beyond the `surface` dimension.

### Reviewed Todos (not folded)
None — no pending todos matched this phase.

</deferred>

---

*Phase: 124-enforcement-surfaces-plug-liveview-guards*
*Context gathered: 2026-05-23*
</content>
