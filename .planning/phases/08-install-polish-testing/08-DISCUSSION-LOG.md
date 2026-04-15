# Phase 8: Install + Polish + Testing - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-15
**Phase:** 08-Install + Polish + Testing
**Areas discussed:** Installer Flow and Overwrite Safety, Generated Host-App Surface, Test Helper API, OpenTelemetry Span Policy, Testing Guide

---

## Installer Flow and Overwrite Safety

| Option | Description | Selected |
|--------|-------------|----------|
| Phoenix-style Mix generator | Familiar `Mix.Generator` prompts plus `--force` / `--no-*` flags. Simple, but weak for safe router/config mutations and re-run review. | |
| Igniter-backed installer | Diff/review patching, explicit apply, idempotent structured project/code changes, noninteractive flags. Best fit for safe host-app mutation. | yes |
| Two-phase custom dry-run/apply manifest | Strong auditability, but custom machinery risks plan/apply drift. | |
| Conservative generate-only installer | Lowest clobber risk, but misses the 30-second fresh install goal. | |

**User's choice:** User requested subagent research and one-shot recommendations; recommendation accepted as locked.
**Notes:** Recommended Igniter-style diff/review installer with Phoenix-like prompts only for true choices, flags for every prompt, `--dry-run`, `--yes`/`--non-interactive`, `--manual`, restricted `--force`, no silent clobbering, and skip-with-instructions on edited host files.

---

## Generated Host-App Surface

| Option | Description | Selected |
|--------|-------------|----------|
| Thin generated host facade over library-owned core | Host owns policy/wiring; Accrue owns payment/webhook/provider internals. | yes |
| Full host-generated implementation | Maximum hackability, but upgrade and security fixes drift across copied code. | |
| Library-owned drop-in routes/controllers | Small footprint and upgradeable, but too hidden for billing policy and host auth. | |
| Manual recipe plus migrations only | Low generator risk, but weak DX and easy to miswire. | |
| Aggressive automatic AST mutation | Best first-run DX, but brittle unless protected by diff/review and explicit flags. | |

**User's choice:** User requested subagent research and one-shot recommendations; recommendation accepted as locked.
**Notes:** Generate `MyApp.Billing`, host migrations, webhook scaffold, reviewable router/config/admin/Sigra/Oban wiring, and test support imports. Keep core billing logic and admin UI library-owned.

---

## Test Helper API

| Option | Description | Selected |
|--------|-------------|----------|
| Unified `Accrue.Test` facade | One host import over focused internals; best default DX. | yes |
| Separate modules only | Clear ownership but more ceremony and fragmented docs. | |
| Macro-heavy assertion DSL | Strong diagnostics but macro complexity and surprise risk. | |
| Function-first helpers | Simple composition, but poorer assertion failure messages. | |
| Global ETS capture registry | Useful for cross-process work, but risks async leakage unless explicit. | partial |

**User's choice:** User requested subagent research and one-shot recommendations; recommendation accepted as locked.
**Notes:** Use a unified `Accrue.Test` facade backed by focused modules. Action helpers are functions; assertions may be macros for better ExUnit failures. Process-local captures are default, with explicit owner/global mode for background processes.

---

## OpenTelemetry Span Policy

| Option | Description | Selected |
|--------|-------------|----------|
| Enrich existing telemetry only | Idiomatic and simple, but does not create true OTel spans. | |
| True OTel spans inside `Accrue.Telemetry.span/3` | Central policy and no-op fallback, but needs careful optional compile behavior. | partial |
| Explicit OTel spans at each Billing call site | Clear but repetitive and drift-prone. | |
| Macro-generated wrappers | Broad coverage but unsafe attribute extraction and opaque stack traces. | |
| Separate `Accrue.Telemetry.OTel` adapter called by `span/3` | Clean boundary, testable fallback, centralized attribute allowlist. | yes |

**User's choice:** User requested subagent research and one-shot recommendations; recommendation accepted as locked.
**Notes:** Implement true OTel spans through a small adapter invoked by existing telemetry. Keep telemetry primary. Enforce sanitized allowlisted attrs and compile cleanly with/without OpenTelemetry.

---

## Testing Guide

| Option | Description | Selected |
|--------|-------------|----------|
| Scenario Playbook, Fake Processor First | Shows complete realistic local billing tests and Accrue's DX differentiator. | yes |
| Capability Reference Guide | Easy lookup, weaker as a persuasive onboarding path. | |
| External Processor Parity Guide | Useful appendix, but should not be primary. | partial |
| Fake Processor Mini-Guide | Focused but too narrow for the complete Phase 8 story. | |

**User's choice:** User requested subagent research and one-shot recommendations; recommendation accepted as locked.
**Notes:** Testing guide opens with a complete copy-pasteable Phoenix test using Fake, clock advancement, synthetic events, Oban, mail, PDF, and event ledger assertions. Reference and Stripe parity material come after the local path.

---

## the agent's Discretion

- Exact Igniter dependency setup and fallback mechanics.
- Exact generated filenames and module naming beyond `MyApp.Billing` default.
- Exact assertion matcher syntax.
- Exact OTel adapter internals and status mapping.
- Exact testing guide prose/order after the Fake-first scenario opening.

## Deferred Ideas

- Phase 9 release machinery and full docs suite.
- Out-of-scope v2/non-Stripe/tax/revenue-recognition work from project requirements.
