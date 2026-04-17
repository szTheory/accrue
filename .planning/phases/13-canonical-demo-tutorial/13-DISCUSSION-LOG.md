# Phase 13: Canonical Demo + Tutorial - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-04-17
**Phase:** 13-canonical-demo-tutorial
**Areas discussed:** Demo Entry Path, Seeded Demo Story, Verification Command Contract, Tutorial Drift Guard

---

## Demo Entry Path

| Option | Description | Selected |
|--------|-------------|----------|
| Host README first | Make `examples/accrue_host/README.md` the primary entry. Strong for clone-to-running, weak for HexDocs/package readers unless mirrored. | |
| Package First Hour guide first | Make `accrue/guides/first_hour.md` primary. Strong ExDoc/Phoenix tutorial fit, less direct for repo clone evaluation. | |
| Root README front door first | Make the repository README primary. Useful for OSS orientation, but mostly Phase 14 adoption-front-door scope. | |
| Single blessed command first | Lead with `bash scripts/ci/accrue_host_uat.sh`. Strong verification, weak teaching surface. | |
| Hybrid ownership | Host README is executable clone path, First Hour is package mirror, root README orients, UAT script verifies. | yes |

**User's choice:** Discuss all with subagent-backed research and select a cohesive recommendation.
**Decision captured:** Hybrid ownership, with Phase 13 centered on host README + First Hour mirror + UAT verifier. Root README remains orient-and-link until Phase 14.
**Notes:** Research emphasized Phoenix generator norms, LiveDashboard/Oban-style mounted integration docs, and billing-library lessons from Pay, Cashier, and dj-stripe.

---

## Seeded Demo Story

| Option | Description | Selected |
|--------|-------------|----------|
| Subscribe-only | Smallest first success, but under-proves admin replay/history and DEMO-03. | |
| Subscribe + cancel | Public-boundary lifecycle proof, but cancellation adds policy noise to the main tutorial. | |
| Full user flow plus admin replay/history fixture | Covers the whole promise in one story, but risks teaching hidden fixture/private setup as normal usage. | |
| Guided pre-seeded billing history | Good deterministic admin state, but wrong as the main first-hour tutorial. | |
| Multiple modes | Public first-run tutorial plus explicit seeded-history evaluation mode. | yes |

**User's choice:** Discuss all with subagent-backed research and select a cohesive recommendation.
**Decision captured:** Use two named modes: `First run` for the public-boundary tutorial and `Seeded history` for deterministic admin replay/history evaluation.
**Notes:** Seeds may use private internals only for evaluation states users should not imitate. Subscription creation and signed webhook ingest stay on public host boundaries.

---

## Verification Command Contract

| Option | Description | Selected |
|--------|-------------|----------|
| One full CI-equivalent default command | Maximum parity, but too heavy and opaque as the first-user path. | |
| Fast command plus full command | Gives newcomers a short proof and maintainers a full parity gate. | yes |
| Split commands by concern | Precise but too fragmented for a canonical demo path. | |
| Makefile or just aliases | Convenient in some repos, but not idiomatic Elixir/Phoenix for this app-local path. | |
| Package-local Mix aliases | Most Phoenix-native interface; best when used to implement the fast/full contract. | yes |

**User's choice:** Discuss all with subagent-backed research and select a cohesive recommendation.
**Decision captured:** Implement `fast + full` through package-local Mix aliases: `mix setup`, `mix verify`, and `mix verify.full`; keep the root shell UAT as a thin CI/repo wrapper.
**Notes:** Do not introduce `make`, `just`, or public command sprawl.

---

## Tutorial Drift Guard

| Option | Description | Selected |
|--------|-------------|----------|
| ExUnit contract tests | Idiomatic and already present, but brittle if used as the only source of truth. | yes |
| Shared command manifest | Best source for ordered commands and mode labels across docs/scripts/tests. | yes |
| Script-generated docs sections | Eliminates copy-paste drift, but hurts reviewability and human-written tutorial quality. | |
| Literate executable docs | Strong for API examples, poor fit for shell/Postgres/Phoenix server setup. | |
| CI shell grep checks only | Useful for narrow fixed invariants, too shallow for tutorial drift. | |

**User's choice:** Discuss all with subagent-backed research and select a cohesive recommendation.
**Decision captured:** Use a small shared command manifest plus ExUnit docs contract tests. Keep docs human-written and shell grep checks narrow.
**Notes:** Do not adopt generated Markdown sections or Livebook/literate executable docs for this phase.

---

## the agent's Discretion

- Exact manifest file format/location.
- Exact Mix alias internals and names for helper aliases below the public contract.
- Exact wording of `First run` and `Seeded history` labels.
- Exact ExUnit helper/module naming.

## Deferred Ideas

- Root README as full public front door - Phase 14.
- Hosted public demo - future phase/backlog.
- Live Stripe tutorial as canonical demo path - out of Phase 13; keep advisory.
