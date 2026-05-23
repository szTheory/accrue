---
phase: 124-enforcement-surfaces-plug-liveview-guards
reviewed: 2026-05-23T00:00:00Z
depth: standard
files_reviewed: 19
files_reviewed_list:
  - .github/workflows/ci.yml
  - CLAUDE.md
  - accrue/lib/accrue/config.ex
  - accrue/lib/accrue/entitlements.ex
  - accrue/lib/accrue/entitlements/guard.ex
  - accrue/lib/accrue/live/entitlements.ex
  - accrue/lib/accrue/oban/middleware.ex
  - accrue/lib/accrue/plug/require_entitlement.ex
  - accrue/lib/accrue/router.ex
  - accrue/lib/accrue/telemetry/otel.ex
  - accrue/mix.exs
  - accrue/test/accrue/config_entitlements_test.exs
  - accrue/test/accrue/entitlements/guard_telemetry_test.exs
  - accrue/test/accrue/entitlements/guard_test.exs
  - accrue/test/accrue/entitlements_test.exs
  - accrue/test/accrue/live/entitlements_test.exs
  - accrue/test/accrue/plug/require_entitlement_test.exs
  - accrue/test/accrue/router_test.exs
  - accrue/test/property/guard_fail_closed_property_test.exs
  - scripts/ci/verify_core_liveview_runtime_free.sh
findings:
  critical: 0
  warning: 4
  info: 4
  total: 8
status: partially_addressed
resolved:
  - CR-01 (fixed in commit aecd640)
  - WR-01 (fixed in commit aecd640)
---

# Phase 124: Code Review Report

**Reviewed:** 2026-05-23
**Depth:** standard
**Files Reviewed:** 19
**Status:** partially_addressed (BLOCKER CR-01 + WR-01 resolved; 4 warnings + 4 info open)

> **Resolution (2026-05-23, commit `aecd640`):** CR-01 fixed — `Guard.resolve_once(:live, …)`
> now stashes the resolved billable onto the returned container's assigns via a plain,
> gate-clean map update (mirroring the `:plug` clause), so `Accrue.Live.Entitlements`'
> `assign_new` carries the real billable instead of `nil`. WR-01 fixed — the live allow
> test now asserts the stashed billable VALUE, and a new Guard-level `:live` resolve-once
> test locks the contract. The merge gate stays green; compile + affected suites pass.
> WR-02, WR-03, WR-04 and the four INFO findings remain open for follow-up.

## Summary

Phase 124 builds a shared fail-closed `Accrue.Entitlements.Guard` decision engine plus
two thin transport surfaces: `Accrue.Plug.RequireEntitlement` (plug) and the
conditionally-compiled `Accrue.Live.Entitlements` `on_mount` guard (LiveView). The core
fail-closed contract is well-engineered and well-tested: nil/raising/exception billables
all collapse to deny on both surfaces (property-tested), the deny body/flash is opaque
(no feature/plan leak), and the billable is resolved from server-side assigns only. The
conditional-compilation pattern, the `surface:` telemetry dimension, and the
`verify_core_liveview_runtime_free.sh` merge gate are all sound.

However, there is one real correctness defect that the test suite does not catch: the
**resolve-once stash is broken on the LiveView surface** — the billable the Guard resolves
is discarded, so downstream LiveViews read `@accrue_billable == nil`. This silently defeats
D-17 resolve-once on the entire `:live` path. The remaining findings are robustness and
maintainability concerns plus a notable test-coverage gap that allowed the BLOCKER to ship
green.

The fail-closed security posture itself is intact — the bug does NOT open a hole (a denied
mount stays denied). The damage is functional: hosts relying on the documented
"billable stashed once on the socket under `:accrue_billable`" contract get `nil`.

## Critical Issues

### CR-01 [RESOLVED — commit aecd640]: LiveView resolve-once stash always returns `nil` — the resolved billable is silently discarded

**File:** `accrue/lib/accrue/entitlements/guard.ex:99,108,228-239` and `accrue/lib/accrue/live/entitlements.ex:121-124`

**Issue:**
On the `:live` surface, `Guard.check/3` resolves the billable but never writes it back onto
the container, and then `Accrue.Live.Entitlements` tries to read it from the (unmodified)
socket — so the host always gets `nil`.

Trace:

1. `check/3` (guard.ex:99) calls `resolve_once(:live, container, opts)`.
2. `resolve_once(:live, ...)` (guard.ex:228-239) for an unset stash returns
   `{resolve_billable(:live, container, opts), container}` — the resolved billable is
   returned as the *first* tuple element, but `container` is returned **unchanged**
   (no `assign`/`assign_new` of `@stash_key` onto it). Contrast the `:plug` clause
   (guard.ex:212-221) which DOES `Plug.Conn.assign(conn, @stash_key, billable)`.
3. `check/3` then returns `{:allow, container}` (guard.ex:108) — note the resolved
   `billable` binding is used only for the gate call and `ctx`; it is NOT threaded into the
   returned container. The function's return shape `{:allow, container()}` has no slot for
   the billable.
4. `Accrue.Live.Entitlements.decide/3` (live/entitlements.ex:121-124) then does:
   ```elixir
   socket = assign_new(socket, @stash_key, fn -> Map.get(socket.assigns, @stash_key) end)
   ```
   Because the Guard never set `socket.assigns[:accrue_billable]`, this callback returns
   `nil`, and `assign_new` stashes `nil`.

Result: the documented contract — guard.ex:42 "the resolved billable is stashed once on
the socket under `:accrue_billable`" and guard.ex:90-93 "the resolved billable is returned
inside the allowed container untouched" — is false. Any host LiveView reading
`@accrue_billable` after the guard runs gets `nil`, forcing it to re-resolve the billable
(extra DB/query work, and a second divergent resolution path the resolve-once design exists
to prevent). The docstring at guard.ex:92 ("returned inside the allowed container") does not
match the code: the billable is returned *beside* the container, not *inside* it, and the
container slot of the return tuple carries the original socket.

The bug is masked by a test gap (see WR-01): `live/entitlements_test.exs:124` asserts only
`Map.has_key?(socket2.assigns, :accrue_billable)`, which is true even when the value is
`nil`, and never asserts the stashed value equals the resolved billable.

**Fix:**
Make the `:live` `resolve_once` clause stash the resolved billable onto the container's
assigns (it can use plain `Map.put` on `container.assigns` — no Phoenix.Component reference,
so the Guard stays LiveView-runtime-free), and have the LiveView surface mirror from that
key. For a `%Socket{}` / `%{assigns: map}` container:

```elixir
defp resolve_once(:live, %{assigns: %{} = assigns} = container, opts) do
  case Map.get(assigns, @stash_key, :__unset__) do
    :__unset__ ->
      billable = resolve_billable(:live, container, opts)
      {billable, %{container | assigns: Map.put(assigns, @stash_key, billable)}}

    billable ->
      {billable, container}
  end
end
```

Then `Accrue.Live.Entitlements.decide/3` reads the already-set key (the `assign_new`
fallback now finds the real value). Alternatively, widen `check/3`'s allow return to
`{:allow, container, billable}` and have the surface call
`assign_new(socket, @stash_key, fn -> billable end)` with the actual value. Either way,
add a test that asserts `socket2.assigns[:accrue_billable] == the_resolved_billable`
(not just key presence). Mirror the existing plug test
(`guard_test.exs:143-144`, which DOES assert the value).

## Warnings

### WR-01: LiveView stash test asserts key presence, not value — masks CR-01

**File:** `accrue/test/accrue/live/entitlements_test.exs:124`

**Issue:**
```elixir
assert Map.has_key?(socket2.assigns, :accrue_billable)
```
This passes whether the stashed value is the resolved billable or `nil`, so it cannot
distinguish a working resolve-once stash from the broken one in CR-01. The analogous plug
test asserts the value (`guard_test.exs:144: assert conn.assigns[:accrue_billable] == b`),
so the live surface is held to a weaker bar than the plug surface for the identical contract.

**Fix:**
Assert the value, mirroring the plug test:
```elixir
b = entitled_billable()
socket = socket_with_billable(b)
assert {:cont, socket2} = LiveGuard.on_mount({:require_feature, :reports}, %{}, %{}, socket)
assert socket2.assigns[:accrue_billable] == b
refute Map.has_key?(socket2.assigns, :accrue_entitled)
```

### WR-02: `default_probe` only stashes on `%Plug.Conn{}` — the non-conn `:plug` fallback re-resolves every call

**File:** `accrue/lib/accrue/entitlements/guard.ex:223-226`

**Issue:**
The `resolve_once(:plug, container, opts)` fallback clause (for a `:plug` surface whose
container is not a `%Plug.Conn{}`) resolves the billable but does not stash it and returns
the container unchanged:
```elixir
defp resolve_once(:plug, container, opts) do
  {resolve_billable(:plug, container, opts), container}
end
```
A second `check(:plug, container, ...)` on the same non-conn container will re-run the
`billable:` fn, violating resolve-once (D-17). The resolve-once guarantee silently degrades
to "resolve-each-call" for any non-`Plug.Conn` plug container. While the only documented
`:plug` container is `%Plug.Conn{}`, the clause exists specifically to be "defensive"
(comment at guard.ex:224), and its behavior diverges from the contract the module advertises.

**Fix:**
Either drop the defensive clause and let a non-conn plug container fail loudly (clearer
contract), or document explicitly that resolve-once is only guaranteed for `%Plug.Conn{}`
containers and that the `billable:` fn may run more than once otherwise. If the clause stays,
update the resolve-once docstring (guard.ex:208-211) to scope the guarantee to conns.

### WR-03: `deny_plug/4` accepts negative / non-2xx-range integers for `status` without bounds

**File:** `accrue/lib/accrue/entitlements/guard.ex:179-183` (and `accrue/lib/accrue/config.ex:1028`)

**Issue:**
```elixir
def deny_plug(conn, {status, body}, _ctx, _opts) when is_integer(status) do
```
`is_integer(status)` admits negative integers and out-of-range values. `validate_on_deny/1`
(config.ex:1028) has the same unbounded guard (`is_integer(status)`). A configured
`on_deny: {-1, "x"}` or `{0, "x"}` passes boot validation and then raises inside
`Plug.Conn.send_resp/3` at request time (an `ArgumentError` on an invalid status), turning a
misconfiguration into a runtime 500 on the deny path. Because this only fires when a request
is already being denied, it does not fail open, but it converts a should-be-boot-time error
into a per-request crash.

**Fix:**
Constrain the status to a valid HTTP status range at validation time so misconfig fails loud
at boot:
```elixir
def validate_on_deny({status, body} = value)
    when is_integer(status) and status in 100..599 and is_binary(body),
    do: {:ok, value}
```
and tighten the `deny_plug/4` guard similarly (or document the assumption that the value is
boot-validated).

### WR-04: `verify_core_liveview_runtime_free.sh` is line-anchored and misses multi-line refs

**File:** `scripts/ci/verify_core_liveview_runtime_free.sh:34-39`

**Issue:**
The merge gate greps single lines with `^[^#]*(...)`. A LiveView socket-runtime coupling
split across two lines evades it, e.g.:
```elixir
import
  Phoenix.LiveView
```
or `alias Phoenix.LiveView.{Socket, Utils}` is matched (good), but
`alias Phoenix.LiveView, as: LV` then `LV.Socket` references would not be caught because the
`.Socket` literal never appears. The gate is a real defense-in-depth control for the
"core stays runtime-LiveView-free" invariant (CLAUDE.md / D-05), so an evadable pattern
weakens that guarantee. This is a robustness gap in a security-adjacent gate, not an active
vulnerability (the hard `phoenix_live_view` dep means the cond-compile branch is never elided
in practice).

**Fix:**
Either accept the residual risk and document it in the script header (the gate is
belt-and-suspenders given the hard dep), or strengthen it — e.g., also grep for `LiveView`
aliasing forms and any `def on_mount` outside `lib/accrue/live/`, and consider an AST-level
check via `mix` if the bash grep proves too coarse. At minimum add a comment noting the
single-line limitation so a future reader does not over-trust it.

### WR-05: `entitlements/0` surfaces guard-key defaults but NOT plan-nested defaults — split-default model is a footgun

**File:** `accrue/lib/accrue/config.ex:873-886` and `accrue/lib/accrue/entitlements.ex:188-200`

**Issue:**
`Config.entitlements/0` applies `Keyword.put_new` for the three guard keys
(`:billable`/`:on_deny`/`:deny_path`) but deliberately does NOT apply the per-plan nested
defaults (`features: []`, `limits: []`, `price_ids: []`), relying on every downstream reader
to tolerate missing nested keys via `Keyword.get/3`. `Accrue.Entitlements.reverse_index/0`
(entitlements.ex:193-197) does use `Keyword.get(entry, :price_ids, [])`, so it is safe today.
But this establishes a fragile contract: any future reader of `entitlements()[:plans]` that
does `entry[:features]` (returning `nil` instead of `[]`) will hit a silent `nil` and may
mis-resolve entitlements. The asymmetry (some defaults applied, some not, in the same
accessor) is a maintainability hazard for a security-relevant catalog.

**Fix:**
Either apply the nested per-plan defaults consistently in `entitlements/0` (so all readers
see normalized shape), or add a focused module doc / typespec on the `:plans` value making
the "nested keys may be absent — always use `Keyword.get/3` with the schema default" contract
explicit and visible at every call site. Prefer normalizing once over relying on N callers to
remember the convention.

## Info

### IN-01: `check/3` `@spec` and docstring describe arity-3 but the LiveView surface calls it correctly — doc/code drift on the live container

**File:** `accrue/lib/accrue/entitlements/guard.ex:75-93`

**Issue:**
The `check/3` doc (guard.ex:90-93) says the `:live` resolved billable "is returned inside the
allowed container untouched (no `assign_new`/Component reference) so the surface owns its own
`assign_new` stash." This describes the intended design but is contradicted by the actual
return shape (see CR-01). Once CR-01 is fixed, reconcile this docstring with the chosen
mechanism so it accurately states where the billable lands.

**Fix:**
Update the `check/3` doc to match the corrected behavior (billable stashed onto
`container.assigns` for `:live`, or returned as a third tuple element, depending on the CR-01
fix chosen).

### IN-02: `has_active_plan?` puts a price_id string into the `feature:` telemetry field on the unmapped leg

**File:** `accrue/lib/accrue/entitlements.ex:104,111`

**Issue:**
On the `:unmapped_plan` leg, `feature` is bound to the raw `plan` value
(`{false, :unmapped_plan, plan}`), so when `plan` is a price_id string like
`"price_garbage"`, the `:check` span's `feature:` metadata carries a price_id string rather
than a feature atom. Not PII (price_ids are non-sensitive Stripe identifiers) and not a bug,
but it muddies the `feature:` dimension's semantics (mixed atom/string, and a plan id in a
field named "feature"). The OTel allowlist (otel.ex:36) maps `:feature` and string-coerces
the value, so cardinality is bounded by the configured price_id set.

**Fix:**
Consider passing `nil` (or a dedicated `plan:` metadata key) on the unmapped leg instead of
overloading `feature:` with a price_id. Low priority — telemetry-only, no functional impact.

### IN-03: `socket_with_billable/2` test helper hand-builds a `%Socket{}` — brittle to LiveView internal struct changes

**File:** `accrue/test/accrue/live/entitlements_test.exs:77-79`

**Issue:**
```elixir
%Socket{assigns: %{__changed__: %{}, flash: %{}, current_user: billable}}
```
This relies on the private shape of `Phoenix.LiveView.Socket` (`__changed__`, `flash`)
needed by `put_flash`/`redirect`/`assign_new`. A LiveView 1.1.x patch that changes those
internals would break this test for reasons unrelated to the guard. Acceptable for a unit
test (the comment acknowledges the choice), but worth noting as a maintenance cost tied to a
`~> 1.1` dep that can drift on patch releases.

**Fix:**
None required. If the helper proves brittle across LiveView upgrades, switch to a real
`Phoenix.LiveViewTest`-built socket or a thin factory that LiveView blesses.

### IN-04: Duplicate alias entries in OTel `@allowed_attributes` / `@prohibited_keys` (atom + string keys) — intentional but verbose

**File:** `accrue/lib/accrue/telemetry/otel.ex:12-69`

**Issue:**
Each attribute is listed twice (atom key and dotted-string key), and prohibited keys are
listed twice (atom + string). This is intentional defense (callers may pass either form), but
the doubled literal maps are easy to update inconsistently — a new attribute added to the
atom half but forgotten in the string half would silently drop string-keyed callers. The
Phase 124 additions (`:surface`, `:feature`, `:result`, `:resolver`, `:reason`) are correctly
present in both halves here.

**Fix:**
Optional: derive the string-keyed entries from the atom-keyed ones programmatically
(`Map.new(base, fn {k, v} -> {to_string(k), v} end)`) so the two halves cannot drift. Purely
a maintainability improvement; current code is correct.

---

_Reviewed: 2026-05-23_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
