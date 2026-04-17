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

## Milestone: v1.1 — Stabilization + Adoption

**Shipped:** 2026-04-17  
**Phases:** 4 | **Plans:** 22 | **Tasks:** 42

### What Was Built

- A realistic Phoenix host app that installs `accrue` and `accrue_admin` through public APIs and proves signed-in billing, webhook ingest, admin auth, and audited replay.
- A canonical CI integration gate that runs the host UAT shell flow, Playwright browser proof, Hex dependency smoke, failure artifact upload, and annotation sweep.
- Hermetic focused host-flow proof files that can run directly after the canonical wrapper without deterministic processor-id collisions.
- First-user DX hardening: installer rerun safety, conflict artifacts, shared setup diagnostics, migration/webhook/auth/admin checks, host-first docs, and package-doc verification.

### What Worked

- The host app exposed real integration assumptions quickly: Oban supervision, admin session forwarding, clean-checkout migration order, and dev boot config all became executable contracts.
- Moving browser proof into host-local Playwright made the release gate easier to debug and decoupled it from the admin package's tooling.
- The milestone audit caught a real hermeticity issue, and the decimal gap-closure phase kept the fix scoped without renumbering the roadmap.
- Docs contracts and shell verifiers turned first-user guidance into CI-enforced behavior instead of prose drift.

### What Was Inefficient

- The milestone scope drifted: adoption, quality, and expansion work were listed under v1.1 but the auditable shipped slice was HOST/CI/DX.
- Generated milestone accomplishments were too noisy and needed manual editing before archive.
- `gsd-tools audit-open` failed with a tool bug at close, so the artifact audit gate could not produce its normal report.
- Phase 11.1 validation metadata lagged behind verification even though the implementation passed.

### Patterns Established

- Use the canonical host app as the user-facing contract for install, docs, CI, Hex dependency mode, and admin integration.
- Keep live Stripe advisory and Fake-backed host flows mandatory.
- Treat `MyApp.Billing` as the public host boundary for both writes and reads.
- Use decimal phases for audit gap closure when a small inserted fix is needed between completed phases.

### Key Lessons

1. Roadmap milestone boundaries need to be corrected before archive when planned follow-on work becomes next-milestone material.
2. Requirement traceability should be updated as soon as a gap-closure phase verifies, not left for milestone audit cleanup.
3. Playwright artifacts and server logs are worth the setup cost for user-facing host flows.
4. Validation metadata needs the same closeout discipline as verification reports.

### Cost Observations

- Model mix: not tracked.
- Sessions: one rapid stabilization chain across host, CI, gap closure, and docs/DX.
- Notable: the most valuable checks were full host UAT, wrapper/direct rerun agreement, docs drift verification, and the milestone integration audit.

---

## Milestone: v1.2 — Adoption + Trust

**Shipped:** 2026-04-17  
**Phases:** 5 | **Plans:** 13 | **Tasks:** 26

### What Was Built

- Canonical local demo and tutorial path around `examples/accrue_host`, with manifest-backed command parity and host-local `mix verify` / `mix verify.full`.
- Host-first adoption front door: root README, package docs, issue templates, release guidance, and provider-parity documentation.
- Trust hardening bundle: checked-in trust review, leakage contracts, seeded webhook/admin smoke checks, desktop/mobile Playwright trust flow, and CI support matrix/trust wiring.
- Expansion discovery record that ranks Stripe Tax as the next milestone candidate, keeps org billing and revenue/export in backlog, and preserves a second processor as a planted seed.
- Milestone closure cleanup that aligned planning records, narrowed host browser fixture cleanup to fixture-owned rows, refreshed stale trust-lane docs, and added phase security verification.

### What Worked

- Treating the host app as the canonical demo kept docs, UAT, CI, and release guidance anchored to one executable path.
- Docs contracts plus `verify_package_docs.sh` caught stale release wording and made trust-lane semantics enforceable.
- The milestone audit was useful even when it found only tech debt; it produced a small Phase 17 cleanup instead of letting bookkeeping drift enter the archive.
- Code review and security verification caught the remaining broad Oban job cleanup risk before the milestone closed.

### What Was Inefficient

- The first milestone audit returned `tech_debt` instead of `passed`, so milestone close needed an extra cleanup phase and re-verification cycle.
- Some GSD closeout tooling is conservative about literal gap strings; the verification report needed wording normalization after the gap was closed.
- `audit-open` produced no human-readable report in this runtime, so closeout relied on current-milestone UAT/security/verification checks plus direct artifact inspection.

### Patterns Established

- Use docs contracts for release-lane language, not just prose review.
- Keep provider-backed Stripe checks advisory while Fake-backed host proof remains the deterministic release blocker.
- Scope destructive demo seed cleanup by fixture identity across events, webhooks, subscriptions, and Oban jobs.
- Preserve expansion decisions as recommendation-only planning artifacts until a new milestone turns one into active requirements.

### Key Lessons

1. Milestone audits should be run early enough that non-critical tech debt can become a planned cleanup phase before archival.
2. Security gates are valuable even for docs/demo cleanup phases because destructive fixture cleanup crosses a real trust boundary.
3. Recommendation-only discovery needs exact docs contracts so future planning does not accidentally imply implementation scope.
4. The canonical demo should remain the first integration proof for new release-gate changes.

### Cost Observations

- Model mix: not tracked.
- Sessions: one concentrated v1.2 closeout sequence across execution, code review, verification, security, and milestone archival.
- Notable: the highest-signal checks were host UAT, docs verifier, code review, phase security audit, and milestone audit.

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Sessions | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.2 | concentrated closeout | 5 | Adoption and trust work became executable through the canonical host demo, docs contracts, and security/audit closeout gates. |
| v1.1 | multiple | 4 | Real host-app dogfood became the canonical user-facing integration and CI release gate. |
| v1.0 | multiple | 9 | Full greenfield build through public Hex release; planning archive introduced at close. |

### Cumulative Quality

| Milestone | Tests | Coverage | Zero-Dep Additions |
|-----------|-------|----------|-------------------|
| v1.2 | Host UAT, Playwright trust flow, docs verifier, release guidance tests, trust/security review artifacts | 23/23 audited requirements plus Phase 17 cleanup verification | Canonical demo/tutorial contracts, issue templates, trust review, expansion recommendation, security verification. |
| v1.1 | Host ExUnit, Playwright, shell UAT, docs verifier, Hex smoke | 21/21 audited scoped requirements | Host app, Playwright gate, setup diagnostics, conflict sidecars, package-doc verifier. |
| v1.0 | CI matrix plus package-local suites | Not tracked | Fake processor, test adapters, installer snippets, and docs-first release checks. |

### Top Lessons (Verified Across Milestones)

1. Warnings-as-errors should remain a release blocker.
2. Planning state needs to be updated at release boundaries, not just phase boundaries.
3. User-facing host-app proof catches integration gaps that package-local tests miss.
4. Docs and security contracts are worth writing for release-process wording, not only runtime code.
