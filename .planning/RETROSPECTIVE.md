# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.0 — Initial Release

**Shipped:** 2026-04-16  
**Phases:** 9 | **Plans:** 69 | **Tasks:** 117

### What Was Built

- Core billing library with money safety, processor behaviours, Fake and Stripe adapters, polymorphic customers, subscription lifecycle, invoices, charges, refunds, coupons, checkout, portal, and Connect.
- Durable webhook and event infrastructure: scoped raw-body plug, signature verification, transactional ingest, Oban dispatch, DLQ/replay, out-of-order handling, and append-only event history.
- Customer-facing communication layer with branded transactional emails, shared HEEx rendering, PDF adapters, storage abstraction, and test assertions.
- `accrue_admin` LiveView package with dashboard, billing detail pages, webhook inspector, replay controls, Connect administration, step-up auth, audit rows, and dev-only Fake tooling.
- Installer and DX layer with `mix accrue.install`, generated host wiring, test helpers, OpenTelemetry spans, and Fake-first testing docs.
- Public release machinery: CI matrix, warnings-as-errors gates, Release Please, Hex publishing, ExDoc/HexDocs, changelogs, and OSS policy files.

### What Worked

- Phase-by-phase summaries and verification files were useful when closing the milestone and reconstructing shipped scope.
- Treating warnings and GitHub annotations as blockers kept the release gate strict enough to trust.
- Fake-first testing and package-local admin harnesses let large workflow surfaces move without relying on live Stripe for every check.
- Release Please plus Hex publishing worked once repository secrets and same-workflow publish gating were configured.

### What Was Inefficient

- Several planning files lagged behind implementation state and needed manual cleanup at close.
- The milestone archive tool extracted noisy accomplishments from summaries, so the generated MILESTONES entry required pruning.
- Requirements checkboxes were not consistently updated as phases completed, creating stale unchecked rows despite verified implementation.

### Patterns Established

- Keep `STATE.md`, `ROADMAP.md`, validation, and verification current immediately after release events, not only after coding phases.
- Use relative ExDoc guide links for package docs so HexDocs resolves internal guides instead of GitHub blob URLs.
- Use package-specific release tags in `source_ref`: `accrue-v#{@version}` and `accrue_admin-v#{@version}`.
- Keep `.planning/` commits separate from release/code commits so public release history remains readable.

### Key Lessons

1. Archive workflows need a final sanity pass; generated milestone summaries can be structurally correct but editorially noisy.
2. Requirement status should be updated during phase verification, otherwise milestone close becomes a mechanical cleanup step.
3. Real publish verification should include Hex package metadata and rendered HexDocs pages, not just successful CI jobs.
4. Stale state files are a real continuity risk; update them before clearing the session.

### Cost Observations

- Model mix: not tracked.
- Sessions: multiple long-running implementation and release sessions.
- Notable: CI/Dialyzer and release verification dominated wall-clock time; compact status polling was more reliable than long GitHub watch streams.

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Sessions | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.0 | multiple | 9 | Full greenfield build through public Hex release; planning archive introduced at close. |

### Cumulative Quality

| Milestone | Tests | Coverage | Zero-Dep Additions |
|-----------|-------|----------|-------------------|
| v1.0 | CI matrix plus package-local suites | Not tracked | Fake processor, test adapters, installer snippets, and docs-first release checks. |

### Top Lessons (Verified Across Milestones)

1. Warnings-as-errors should remain a release blocker.
2. Planning state needs to be updated at release boundaries, not just phase boundaries.
