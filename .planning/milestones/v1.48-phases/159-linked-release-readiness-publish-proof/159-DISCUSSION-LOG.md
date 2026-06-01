# Phase 159: Linked Release Readiness + Publish Proof - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-31
**Phase:** 159-Linked Release Readiness + Publish Proof
**Areas discussed:** Release truth source-of-record, Deterministic gate artifact shape, Publish order and recovery policy, Post-publish proof depth

---

## Release Truth Source-of-Record

| Option | Description | Selected |
|--------|-------------|----------|
| Registry-first truth | Treat Hex and tags as canonical public fact, with repo files secondary. Strong after publish, weak before publish. | |
| Release-Please-state-first | Treat manifest and combined Release Please PR as pre-publish authority. Strong for choreography, insufficient after partial publish. | |
| Composite release truth artifact | Reconcile manifest, package versions, changelogs, tags, GitHub releases, Hex state, and gate outputs in one canonical artifact. | yes |
| GitHub-release/changelog-first | Treat human-facing release narrative as the primary source. Familiar but drift-prone. | |

**User's choice:** Asked the agent to research all options using subagents and produce one cohesive recommendation.
**Notes:** Selected recommendation is the composite release-truth artifact with a strict split between pre-publish intent and post-publish public fact.

---

## Deterministic Gate Artifact Shape

| Option | Description | Selected |
|--------|-------------|----------|
| One consolidated canonical artifact | Single `.planning/.../159-VERIFICATION.md`-style artifact generated/appended by scripts. | yes |
| Split artifacts plus index | Separate proof files per concern with an index. More modular, higher drift risk. | |
| CI-only evidence | Workflow summaries/artifacts as proof with little repo-local ledger. Strong provenance, weaker long-term local auditability. | |
| Changelog/release-notes-only evidence | Public narrative only. Familiar, not deterministic. | |

**User's choice:** Asked for deep research and a one-shot recommendation.
**Notes:** Selected recommendation is one consolidated canonical artifact following the existing Phase 121 proof style, with script-generated facts and all three packages included.

---

## Publish Order and Recovery Policy

| Option | Description | Selected |
|--------|-------------|----------|
| Strict serialized publish | Publish `accrue`, then `accrue_admin`, then `accrue_portal`; retry downstream failures first; retire/forward-fix when needed. | yes |
| Hybrid parallel downstream publish | Publish core first, then admin and portal in parallel. Faster, weaker proof and recovery story. | |
| Manual-first recovery | Use Release Please mostly for tags/notes and manually drive publishes. More control, more operator error. | |

**User's choice:** Asked for subagent-backed ecosystem and DX research.
**Notes:** Selected recommendation preserves current workflow ordering and formalizes recovery: retry same-version downstream failures first, use Hex revert only in the allowed mistake window, otherwise retire and ship a new linked patch line with explicit changelog honesty.

---

## Post-Publish Proof Depth

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal Hex availability | Confirm all three packages exist on Hex. Fast but weak auditability. | |
| Medium public proof | Confirm Hex, HexDocs, git tags, and GitHub releases. Good OSS hygiene but still distributed. | |
| Full canonical artifact | Append-only release-truth ledger with PR, target version, run id, job ordering, tags, releases, Hex API truth, HexDocs, and host Hex smoke. | yes |

**User's choice:** Asked to consider all options and make a cohesive recommendation.
**Notes:** Selected recommendation treats host Hex smoke as necessary but insufficient and requires full reconciliation across public and mechanical proof surfaces.

---

## the agent's Discretion

- Exact `159-VERIFICATION.md` section formatting can be chosen by the planner/executor if it stays machine-checkable, complete for all three packages, and aligned with Phase 121 proof precedent.
- Minor runbook/script wording fixes are allowed when needed to enforce release truth, but Phase 159 must not absorb Phase 160 stable-core positioning or Phase 161 backlog/pause-rule work.

## Deferred Ideas

None.
