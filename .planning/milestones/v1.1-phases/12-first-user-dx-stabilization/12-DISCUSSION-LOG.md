# Phase 12: First-User DX Stabilization - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md -- this log preserves the alternatives considered.

**Date:** 2026-04-16
**Phase:** 12-First-User DX Stabilization
**Areas discussed:** Installer Rerun Behavior, Actionable Setup Failures, Quickstart And Troubleshooting Shape, Path Dependency And Hex Validation, Public API Clarity

---

## Installer Rerun Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Pristine-update default | Overwrite only stamped pristine files, skip user-edited generated files and unmarked files, let `--force` overwrite only unmarked files, and make `--write-conflicts` write sidecar artifacts. | yes |
| Strict skip-only | Keep current safest behavior with little recovery help; skip conflicts and mostly print snippets. | |
| Broad-force installer | Allow `--force` to overwrite user-edited generated files and unmarked files. | |

**User's choice:** User asked for one-shot perfect recommendations and delegated all decisions to research/subagents.

**Notes:** Recommendation chosen because it matches Phoenix generated-code ownership, Accrue's current fingerprinting model, and least-surprise DX. `--write-conflicts` is currently parsed/advertised but not implemented.

---

## Actionable Setup Failures

| Option | Description | Selected |
|--------|-------------|----------|
| Centralized setup-diagnostic contract | Shared diagnostic taxonomy across installer/preflight, boot checks, webhook/admin runtime checks, with stable code, summary, fix, docs path, and redaction. | yes |
| Improve existing messages only | Make current installer/errors clearer but leave most native Phoenix/Ecto/Plug failures alone. | |
| Dedicated doctor/check task only | Add explicit preflight while keeping runtime mostly native. | |

**User's choice:** User asked for one-shot perfect recommendations and delegated all decisions to research/subagents.

**Notes:** Recommendation preserves Phoenix/Plug/Ecto idioms: fail fast at boot for host setup, keep public webhook responses generic, and put actionable details in redacted diagnostics/logs/docs.

---

## Quickstart And Troubleshooting Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Compact quickstart | Short landing path only. | |
| Host-app-derived walkthrough | Long canonical guide directly mirroring `examples/accrue_host`. | |
| Troubleshooting matrix | Symptom/fix reference without changing the main quickstart shape. | |
| Guide split | Compact README, host-derived First Hour guide, troubleshooting matrix, and focused topic guides. | yes |

**User's choice:** User asked for one-shot perfect recommendations and delegated all decisions to research/subagents.

**Notes:** Recommendation follows successful ecosystem docs patterns: concise entry point, exact setup walkthrough, and failure lookup. It avoids turning quickstart into a dense all-in-one page.

---

## Path Dependency And Hex Validation

| Option | Description | Selected |
|--------|-------------|----------|
| Single checked-in host app with dependency-mode switch | Keep `examples/accrue_host` canonical, default to path deps, add explicit Hex validation mode. | yes |
| Path host plus ephemeral Hex app | Separate published-package proof in a temp Phoenix app. | |
| Dual committed host fixtures | Maintain separate checked-in path and Hex example apps. | |

**User's choice:** User asked for one-shot perfect recommendations and delegated all decisions to research/subagents.

**Notes:** Recommendation avoids Phase 13 scope creep and prevents fixture drift while proving both monorepo and published-package setup modes.

---

## Public API Clarity

| Option | Description | Selected |
|--------|-------------|----------|
| Host-first boundary | Document generated `MyApp.Billing`, `use Accrue.Webhook.Handler`, `use Accrue.Test`, `AccrueAdmin.Router.accrue_admin/2`, `Accrue.Auth`, and setup errors as the public host surface. | yes |
| Dual-layer contract | Document both host facade and selected raw package modules as advanced public APIs. | |
| Package-centric surface | Teach raw `Accrue.*` modules as the main integration API. | |

**User's choice:** User asked for one-shot perfect recommendations and delegated all decisions to research/subagents.

**Notes:** Recommendation keeps the public API small and Phoenix-context-shaped, and avoids teaching first users private schema/repo/worker/Fake internals.

---

## the agent's Discretion

- Exact implementation names for diagnostic modules and preflight task surfaces.
- Exact conflict artifact naming and directory layout, within the selected non-live-path constraint.
- Exact docs guide names/sidebar grouping.
- Exact narrow Hex-mode smoke suite.

## Deferred Ideas

- Phase 13 owns adoption/demo packaging and public tutorial polish beyond First Hour setup.
- Phase 14 owns security, performance, accessibility, responsive-browser, and compatibility hardening.
