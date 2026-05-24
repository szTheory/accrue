# Phase 124: Enforcement Surfaces — Plug + LiveView Guards - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-23
**Phase:** 124-enforcement-surfaces-plug-liveview-guards
**Areas discussed:** LiveView posture / "core stays LiveView-free" gate, Controller Plug guard shape, Deny semantics (status + override), Billable resolution, Resolve-once + telemetry, Surface symmetry

**Mode:** Cohesive-synthesis (standing preference, config-enforced). 4 parallel `gsd-advisor-researcher` agents (2 first-pass scoping the gray areas, 2 deep-reframe after the user delegated). The user explicitly asked to research deeply and one-shot the cohesive recommendation rather than choose, "except for VERY impactful ones I might actually care about," and to shift that preference left within GSD.

---

## LiveView posture & "core stays runtime-LiveView-free" gate (the one item surfaced, then delegated)

| Option | Description | Selected |
|--------|-------------|----------|
| Reinterpret as runtime-coupling | Keep `phoenix_live_view` non-optional (templating needs it); merge gate = static check that no always-compiled core module references `Phoenix.LiveView`/`on_mount`/`Socket`; guard cond-compiled in core; reconcile SC#3/ENT-07/CLAUDE.md wording to "no LiveView *runtime* coupling" | ✓ |
| Literal "no LiveView package at all" | Make `phoenix_live_view` optional + conditionally-compile all ~20 `Phoenix.Component` users (emails + invoices + guard) so a true "no LiveView present" compile cell exists | |

**User's choice:** Delegated — "idk maybe the liveview not being needed isnt even important? ... research best practices ... split packages maybe that affects the situation too? personally i dont care tooooo much." Resolved via deep research to **relax "LiveView-FREE" → "LiveView-runtime-free"** (CONTEXT D-01..D-06).
**Notes:** Verified that `Phoenix.Component`/`~H` ship only inside `phoenix_live_view` and that 17 email + 3 invoice core modules already use them — so the literal constraint was already false / purity theater. Cross-lib precedent (Flop.Phoenix, phoenix_live_dashboard, petal_components) all require `phoenix_live_view` non-optionally for components. Guard stays in core (not admin — that would force host route-gating to depend on the admin UI). Merge gate is a low-ceremony static grep, not an infeasible "without_live_view" compile cell. Doc wording reconciled in-phase (PITFALLS.md Pitfall-8 stance was stale; ARCHITECTURE.md Anti-Pattern 4 already had it right).

---

## Controller Plug guard shape

| Option | Description | Selected |
|--------|-------------|----------|
| Single parameterized plug | `Accrue.Plug.RequireEntitlement, feature:`/`plan:` only | |
| Two named macros only | `require_plan`/`require_feature` via `import Accrue.Router` | |
| Both (workhorse plug + thin macros) | Plug as canonical + ergonomic macros expanding to it (mirrors `accrue_webhook`) | ✓ |

**User's choice:** Delegated → research-decided (CONTEXT D-07).
**Notes:** Matches the codebase's existing `accrue_webhook`-over-`Webhook.Plug` layering; ENT-06 names both `require_plan`/`require_feature`.

---

## Deny semantics (status code + override shape)

| Option | Description | Selected |
|--------|-------------|----------|
| 403 Forbidden, content-negotiated, opaque body | Authz-correct; no info leak; JSON+browser safe | ✓ |
| 402 Payment Required default | "Needs to pay" reading | (opt-in only) |
| Redirect to upgrade path default | Cashier-style browser UX | (opt-in only) |
| `on_deny`: closure-only `(conn, ctx -> conn)` | Maximally flexible | |
| `on_deny`: tiered declarative-first enum + fn/MFA escape hatch | `:forbidden`/`{:redirect,path}`/`{status,body}`/fn/MFA, per-guard→config→builtin | ✓ |

**User's choice:** Delegated → research-decided (CONTEXT D-09..D-13).
**Notes:** 403 beats 402 decisively — the 402 revival (x402/Stripe MPP) is agentic micropayment negotiation, not SaaS plan gating; browsers/proxies mishandle it. Opaque body is a security decision (don't leak entitlement structure). No redirect default avoids Cashier's hardcoded-path footgun. First pass proposed closure-only `on_deny`; deep pass overturned it to tiered declarative-first (least-surprise).

---

## Billable resolution

| Option | Description | Selected |
|--------|-------------|----------|
| Four shapes (atom \| `{assign,path}` \| fn \| MFA) | Maximal flexibility (first-pass recommendation) | |
| Single 1-arity fn `(conn\|socket -> billable\|nil)` + smart default | One idiom, same fn both surfaces, nil-safe | ✓ |
| Reuse `Accrue.Auth.current_user/1` | The existing auth seam | |

**User's choice:** Delegated → research-decided (CONTEXT D-14..D-16).
**Notes:** Deep pass **overturned** the first pass's four-shape design as "too clever / a least-surprise violation." Single fn solves Plug/LiveView symmetry for free. Default probes `current_scope.user → current_user → nil` (Phoenix 1.8 convention). Not `Accrue.Auth.current_user/1` because billable ≠ user for org-billed apps and Auth is effectful.

---

## Resolve-once + telemetry + surface symmetry

| Option | Description | Selected |
|--------|-------------|----------|
| `assign_new(:accrue_billable, …)` memoize; stash billable only | Fold multiple checks to one resolution | ✓ |
| Reuse Phase 123 `[:accrue,:entitlements,:check]` + add `surface` dimension | No new event; OTel allowlist add | ✓ |
| New guard-specific deny event | Distinct route-level deny analytics | (deferred) |
| Zero ledger rows | Inherit Phase 123 D-21 | ✓ |

**User's choice:** Delegated → research-decided (CONTEXT D-17..D-21).
**Notes:** One mental model across surfaces — "one billable fn, one deny enum, surface-translated." The single asymmetry (a LiveView socket can't emit a raw 403) degrades `:forbidden` to halt+flash+redirect to a configured `deny_path`.

## Claude's Discretion

Entire package auto-resolved via cohesive synthesis per the standing preference and the user's explicit "research and decide" delegation. The only item that would normally have tripped the confirm bar (reconciling the locked-roadmap SC#3 + CLAUDE.md "LiveView-FREE" wording) was delegated; the bar was subsequently sharpened so internal doc/spec/success-criterion *wording* reconciliation that is coherent with the phase goal auto-resolves and no longer prompts.

## Deferred Ideas

- Resolver provider-honesty + capability-matrix rows + drift gate (ENT-08) → Phase 125.
- Lifecycle→entitlement truth-table SSOT + `past_due` grace knob (ENT-09) → Phase 125.
- Admin entitlements view + `guides/entitlements.md` + JTBD flip (ENT-11/12) → Phase 126.
- Optional Stripe-native sync + `grant`/`revoke` + ledger writes (ENT-10) → Phase 127.
- Atomic seat enforcement — host-owned recipe, never a core API.
- `fetch_entitled/2` diagnostic API — additive on a sourced host need (Phase 123 D-07).
- Decoupling email/invoice templating from `phoenix_live_view` — only on a sourced headless-host need.
- Dedicated guard-deny telemetry event — additive later if operators need route-level deny analytics.
</content>
