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

## Milestone: v1.5 — Adoption proof hardening

**Shipped:** 2026-04-18  
**Phases:** 1 | **Plans:** inline (documentation-only)

### What Was Built

- Adoption proof matrix tying Fake VERIFY-01, bounded/full ExUnit, Playwright, and advisory Stripe test-mode parity.
- Evaluator screen-recording checklist linked from the host README alongside VERIFY-01 contract enforcement.
- CI job display naming and guide cross-links so contributors distinguish Fake gates from Stripe test-mode parity.

### What Worked

- README and shell contracts (`verify_verify01_readme_contract.sh`) already existed; v1.5 extended them with narrative glue for evaluators.
- Keeping the `live-stripe` job id stable while clarifying display copy avoided `act` and docs churn.

### What Was Inefficient

- `audit-open` reported Phase 21 as a UAT gap despite a fully automated VERIFY-01 manifest with zero manual scenarios.
- Two indexed quick tasks pointed at missing artifacts; closeout required explicit deferral rather than silent ignore.

### Patterns Established

- Treat adoption proof as a **matrix** artifact: one table maps archetypes to test lanes (ExUnit vs Playwright vs advisory Stripe).

### Key Lessons

1. Closeout tooling that keys off filenames should special-case **retired-to-automation** UAT manifests to avoid false open counts.
2. When `gsd-sdk query` is unavailable, milestone archival stays manual but should still follow the safety commit before `git rm` on requirements.

### Cost Observations

- Model mix: not tracked.
- Sessions: short documentation milestone after v1.4.
- Notable: highest leverage was cross-linking existing gates, not adding new CI topology.

---

## Milestone: v1.6 — Admin UI / UX polish

**Shipped:** 2026-04-20  
**Phases:** 5 | **Plans:** 16

### What Was Built

- Maintainer-facing inventory: route matrix, component kitchen vs production coverage, and Phase 20/21 UI-SPEC alignment tables (Phase 25).
- Visual hierarchy and token discipline across money indexes, detail pages, and webhooks, with documented theme exceptions (Phase 26).
- Operator microcopy pass and `AccrueAdmin.Copy` for stable Playwright and ExUnit literals (Phase 27).
- Accessibility hardening: step-up focus, table captions, contrast verification notes, and `@axe-core/playwright` on mounted customers index in VERIFY-01 (Phase 28).
- Mobile parity: overflow/nav checks, dedicated admin mobile Playwright spec, and README guidance for mounted admin on narrow viewports (Phase 29).

### What Worked

- Anchoring polish to existing Phase 20/21 UI-SPEC contracts avoided speculative redesign.
- Splitting inventory (25) before hierarchy (26) reduced churn before copy and a11y passes.
- Reusing VERIFY-01 and host Playwright for mounted-admin proofs kept CI semantics stable.

### What Was Inefficient

- `gsd-sdk query milestone.complete` failed in this environment (`version required for phases archive`), so archival steps were completed manually.
- `gsd-sdk summary-extract` returned no usable one-liners for automated accomplishment harvesting.
- `audit-open` still flags Phase 21 UAT metadata and missing quick-task stubs across milestone boundaries.

### Patterns Established

- Small copy module (`AccrueAdmin.Copy`) as the default way to keep operator strings and tests aligned.
- Theme exception registry / markdown appendix for unavoidable literals alongside UX-04 discipline.

### Key Lessons

1. Close planning state (`STATE.md` progress tables) when the roadmap table and disk status disagree, before running milestone workflows.
2. Keep milestone-close tooling (`milestone.complete`) verified on the installed `gsd-sdk` version before relying on it in CI or local close scripts.
3. Document mobile shell behavior (scroll owner, menu nav, org query param) in the host README alongside Playwright project names.

### Cost Observations

- Model mix: not tracked.
- Sessions: concentrated planning + verification passes across five short phases.
- Notable: highest leverage was tightening gates on surfaces evaluators already see (admin + VERIFY-01), not expanding CI topology.

---

## Milestone: v1.6 — audit gap closure (post-ship)

**Closed (planning):** 2026-04-21  
**Phases:** 2 | **Plans:** 5

### What Was Built

- Strict audit corpus: COPY-01..03 mapped in `27-VERIFICATION.md`; `requirements-completed` YAML on Phase **26** / **29** summaries (Phase **30**).
- Advisory integration: VERIFY-01 README/CI contract + `e2e:mobile`, step-up modal Copy SSOT, fixture Playwright + workflow + admin README alignment with host VERIFY-01 (Phase **31**).
- Canonical **passed** milestone audit under `.planning/milestones/v1.6-MILESTONE-AUDIT.md` (superseded root audit removed).

### What Worked

- Keeping post-ship work as numbered phases (**30–31**) preserved traceability without re-versioning Hex packages.
- Re-acknowledging the same three `audit-open` items at line close matched prior v1.6 ship policy: document carry-forward instead of pretending tooling is clean.

### What Was Inefficient

- `gsd-sdk query milestone.complete` still returned `version required for phases archive` on this install; closeout remained manual for archive moves and git steps.

### Key Lessons

1. When a git tag already exists for a shipped slice, treat post-ship planning closure as **documentation + audit state**, not a duplicate tag.
2. Refresh milestone audit YAML to **passed** immediately after remediation merges so `gaps_found` does not linger as a false signal.

### Cost Observations

- Model mix: not tracked.
- Sessions: short verification + integration passes tied to audit bullets.
- Notable: highest leverage was tightening README/shell contracts and Copy SSOT on operator chrome evaluators can see.

---

## Milestone: v1.7 — Adoption DX + operator admin depth

**Shipped:** 2026-04-21  
**Phases:** 5 | **Plans:** 14

### What Was Built

- Adoption **doc graph** and VERIFY-01 discoverability (root README, host README, guides) without changing merge-blocking CI semantics.
- **Installer + CI clarity:** rerun contracts, doc verifiers, stable job ids with explicit Fake vs advisory Stripe framing.
- **Operator admin:** home KPIs, customer→invoice drill, nav model + README route inventory.
- **Dashboard copy SSOT** via `AccrueAdmin.Copy` and aligned Playwright/ExUnit literals.
- **Audit corpus:** traceability matrix for shipped 32–33 plans, contributor verifier map, dual-contract documentation, OPS forward-coupling note.

### What Worked

- Splitting **functional ADOPT** (32–33) from **process/integration** closure (36) kept verification honest without reopening satisfied requirements.
- Centralizing dashboard strings in **Copy** early avoided another Playwright vs HEEx drift cycle.
- Refreshing **milestone audit YAML to `passed`** after Phase 35–36 landed removed a false `gaps_found` signal for closeout.

### What Was Inefficient

- **VALIDATION.md** front matter for Phases 35–36 stayed `draft` while **VERIFICATION.md** carried the real gate — planning metadata lagged implementation.
- **`gsd-sdk query milestone.complete`** unavailable on this install; archive + git steps stayed manual.

### Patterns Established

- Treat **`scripts/ci/README.md`** as the contributor-facing map from **REQ ids** to owning verifiers when one bash script pins many strings.
- Document **dual README gates** (package doc verifier vs host VERIFY-01 contract) wherever editorial changes could green one and red the other.

### Key Lessons

1. Close **audit YAML** the same day as the last verification file so milestone automation and humans see the same story.
2. For presentation-layer milestones, **Copy + Playwright** contracts are as load-bearing as domain code for regressions.

### Cost Observations

- Model mix: not tracked.
- Sessions: concentrated adoption + admin polish passes with a short audit-remediation tail.
- Notable: highest leverage was **routing evaluators to one proof story** and **making maintainer-facing CI intent legible**.

---

## Milestone: v1.8 — Org billing recipes & host integration depth

**Shipped:** 2026-04-22  
**Phases:** 3 | **Plans:** 8

### What Was Built

- Single **`organization_billing.md`** spine for non-Sigra **session → billable** with **ORG-03** boundaries; phx.gen.auth checklist; Pow and custom-org sections with anti-patterns and webhook/admin scoping obligations.
- Installer + README + quickstart + finance-handoff discoverability for the org billing path; guide ExUnit needles for doc drift.
- Adoption proof matrix **ORG-09** row for a non-Sigra org archetype; merge-blocking **`verify_adoption_proof_matrix.sh`**; contributor-facing map in **`scripts/ci/README.md`**.

### What Worked

- Treating **ORG-04** as **docs + proof contracts** (no billing schema churn) kept scope aligned with deferred **PROC-08** / **FIN-03** non-goals.
- Reusing v1.7 patterns (**scripts/ci/README.md** ownership map, VERIFY-01 merge-blocking vs advisory language) made ORG-09 legible to evaluators.

### What Was Inefficient

- **`gsd-sdk query milestone.complete`** still failed on this install (`version required for phases archive`); archival + `git rm` stayed manual.
- No standalone **`v1.8-MILESTONE-AUDIT.md`**; closeout leaned on per-phase verification and the requirements traceability table.

### Patterns Established

- Bash verifier at repo root + **accrue** package ExUnit invoking **`System.cmd`** for smoke coverage of matrix paths (Phase 39).

### Key Lessons

1. After **Sigra-first** org proof (**v1.3**), **non-Sigra** teams still need an explicit **recipe + matrix** story—not only generic auth adapter mentions.
2. Milestone automation should not be assumed available; keep **archive file triple** (roadmap, requirements, milestones index) reproducible by hand.

### Cost Observations

- Model mix: not tracked.
- Sessions: focused doc + verifier passes across three short phases.
- Notable: highest leverage was **one spine doc** plus **one merge-blocking verifier** for evaluator trust.

---

## Milestone: v1.9 — Observability & operator runbooks

**Shipped:** 2026-04-22  
**Phases:** 3 | **Plans:** 8

### What Was Built

- **`guides/telemetry.md`** as catalog for **`[:accrue, :ops, :*]`** with firehose split, metadata/PII framing, and reconciliation to **`v1.9-TELEMETRY-GAP-AUDIT.md`**; contract test coverage against silent catalog drift; DLQ dead-letter ops emit on exhausted webhook dispatch.
- **Metrics parity** story: `Accrue.Telemetry.Metrics.defaults/0` aligned or omission-documented vs ops signals; **cross-domain** host `Telemetry` subscription example in package docs + **`examples/accrue_host`**.
- **`guides/operator-runbooks.md`**: Oban queue topology, Stripe verification pattern, D-09 mini-playbooks; **`telemetry.md`** links for on-call first actions (**RUN-01**).

### What Worked

- Reusing the **v1.8** pattern (requirements traceability + phase verification + research audit doc) avoided blocking close on a separate `MILESTONE-AUDIT.md` artifact.
- Tight scope (**no billing primitives**) kept telemetry/runbook work shippable without PROC-08/FIN-03 creep.

### What Was Inefficient

- **`gsd-sdk query milestone.complete`** failed again (`version required for phases archive`); archival + `git rm .planning/REQUIREMENTS.md` stayed manual.
- **`roadmap.analyze`** did not enumerate Phases 40–42 in this workspace snapshot, so readiness relied on filesystem checks for `*-SUMMARY.md`.

### Patterns Established

- **Ops catalog + ExUnit contract** as a guardrail for guide drift (`OpsEventContractTest` pattern).
- **Dedicated operator-runbooks guide** linked from telemetry (preface + per-row deep links) for evaluator and on-call ergonomics.

### Key Lessons

1. **Observability milestones** benefit from a **single research audit** file that the guide must explicitly supersede or reconcile — traceability stays falsifiable.
2. Treat **metrics defaults** as a **parity checklist** against ops emits, not an implied transitive guarantee.

### Cost Observations

- Model mix: not tracked.
- Sessions: three short phases (40–42) with concentrated guide + test work.
- Notable: highest leverage was **one catalog + one runbook** with **test-backed** catalog drift prevention.

---

## Milestone: v1.10 — Metered usage + Fake parity

**Shipped:** 2026-04-22  
**Phases:** 3 | **Plans:** 10

### What Was Built

- **Public metering API** on `Accrue.Billing.report_usage` with documented NimbleOptions, Fake-backed happy path, and `accrue_meter_events` lifecycle semantics (**MTR-01..MTR-03**).
- **Failure + recovery paths:** guarded meter failure telemetry (`:sync`, `:reconciler`, `:webhook`), idempotent retries on terminal rows, reconciler for stuck `pending`, webhook meter error handling (**MTR-04..MTR-06**).
- **Operator + host docs:** `guides/metering.md` for API vs persistence vs processor boundaries; `guides/telemetry.md` and `guides/operator-runbooks.md` aligned on `meter_reporting_failed` sources (**MTR-07..MTR-08**).

### What Worked

- Extending the **v1.9** pattern (research spike + per-phase verification + traceability table) kept close scope without a separate `MILESTONE-AUDIT.md`.
- Centralizing failure telemetry in one choke preserved “emit once” semantics across sync, reconciler, and webhook.

### What Was Inefficient

- **`gsd-sdk query milestone.complete`** failed again (`version required for phases archive`); roadmap/requirements archives and `git rm .planning/REQUIREMENTS.md` stayed manual.
- **`roadmap.analyze`** still did not enumerate current-phase directories in this workspace snapshot, so readiness relied on filesystem checks for `*-SUMMARY.md`.

### Patterns Established

- **Metering guide** as the boundary doc between public `Accrue.Billing`, internal persistence, and processor `report_meter_event/1`.
- **Fake-first metering ExUnit** as the default proof path before any live-Stripe expansion.

### Key Lessons

1. **Revenue-adjacent async paths** benefit from a **single telemetry choke** tied to row state transitions, not ad-hoc emits per call site.
2. **Spike + falsifiable MTR IDs** kept metering scope from absorbing PROC-08/FIN-03 work.

### Cost Observations

- Model mix: not tracked.
- Sessions: three phases (43–45) with concentrated billing + docs + test work.
- Notable: highest leverage was **deterministic Fake tests** plus **guide alignment** with the v1.9 ops catalog.

---

## Milestone: v1.11 — Public Hex release + post-release continuity

**Shipped:** 2026-04-22  
**Phases:** 2 | **Plans:** 6

### What Was Built

- Maintainer-gated Release Please merge path (`workflow_dispatch`) with **`RELEASING.md`** aligned to the same contract (**REL-01**).
- Merge-blocking **`verify_release_manifest_alignment.sh`** + CI job for manifest ↔ **`mix.exs` `@version`** lockstep (**REL-02**).
- D-12-style **`46-VERIFICATION.md`** index for ship-time tag/Hex evidence (**REL-04**).
- Routine-first **`RELEASING.md`** with same-day **1.0.0** bootstrap demoted to appendix (**REL-03**).
- **`first_hour.md`** install fences pinned to **`~> 0.3.0`** with verifier-safe prose (**DOC-01**); **`verify_package_docs`** + ExUnit unchanged as merge-blocking contract (**DOC-02**).
- **`PROJECT`**, **`MILESTONES`**, **`STATE`** Hex mirrors at **0.3.0** (**HYG-01**).

### What Worked

- Treating doc verifiers and manifest scripts as **release SSOT** caught drift before it reached evaluators.
- Small phases (**46** release train, **47** continuity) kept operational work separable from feature milestones.

### What Was Inefficient

- **`gsd-sdk query milestone.complete`** failed again (`version required for phases archive`); **`v1.11-*`** archives and **`git rm .planning/REQUIREMENTS.md`** were completed manually.
- Root **`.planning/REQUIREMENTS.md`** lagged with unchecked boxes until milestone close despite phase summaries listing **`requirements-completed`**.

### Patterns Established

- **Human-intent gate** on release PR automation (no silent auto-merge of Release Please branches).
- **Planning archive + tag** as the durable “shipped” boundary for Hex-adjacent work.

### Key Lessons

1. **Close the requirements file** against plan YAML at the same time as verification — not only at milestone archive.
2. **Linked-versions monorepos** need one fast **manifest ↔ mix.exs** check on every **`main`** push, not only on release day.

### Cost Observations

- Model mix: not tracked.
- Sessions: two short phases focused on automation + docs.
- Notable: majority of wall-clock is maintainer **Hex + tag** verification, not code churn.

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Sessions | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.11 | short | 2 | Release train + manifest SSOT (46), post-release docs + planning mirrors (47). |
| v1.10 | short | 3 | Metering happy path + Fake determinism (43), failure/reconciler/webhook telemetry (44), metering + telemetry/runbook docs (45). |
| v1.9 | short | 3 | Telemetry catalog + metrics parity + cross-domain example (40–41), operator runbooks + telemetry links (42). |
| v1.8 | short | 3 | ORG-04 non-Sigra org billing spine (37–38), ORG-09 adoption matrix + `verify_adoption_proof_matrix.sh` + CI README map (39). |
| v1.7 | short | 5 | VERIFY-01/doc graph + installer CI clarity (32–33), operator home/drill/nav (34), Copy SSOT dashboard (35), audit corpus + verifier map (36). |
| v1.6 | short | 7 | Admin inventory → hierarchy → copy → a11y → mobile (25–29), then audit corpus + advisory integration closure (30–31) without new Hex tag. |
| v1.5 | short | 1 | Adoption proof documented as a matrix tying existing Fake, host, Playwright, and advisory Stripe lanes. |
| v1.2 | concentrated closeout | 5 | Adoption and trust work became executable through the canonical host demo, docs contracts, and security/audit closeout gates. |
| v1.1 | multiple | 4 | Real host-app dogfood became the canonical user-facing integration and CI release gate. |
| v1.0 | multiple | 9 | Full greenfield build through public Hex release; planning archive introduced at close. |

### Cumulative Quality

| Milestone | Tests | Coverage | Zero-Dep Additions |
|-----------|-------|----------|-------------------|
| v1.11 | `verify_release_manifest_alignment.sh`, `verify_package_docs` + ExUnit, CI release-automation wiring | REL/DOC/HYG (7/7) archived | Maintainer-dispatch release PR workflow, manifest SSOT job, `46-VERIFICATION.md` ship index. |
| v1.10 | ExUnit on Fake metering flows (happy, sync failure + idempotent retry, reconciler, webhook); guide cross-links | MTR-01..MTR-08 (8/8) archived | `guides/metering.md`, telemetry/runbook rows for `meter_reporting_failed` sources, guarded `MeterEvents` failure path. |
| v1.9 | `OpsEventContractTest`, `MetricsOpsParityTest`, guide + host wiring docs | OBS/RUN/TEL (6/6) archived | `operator-runbooks.md`, telemetry catalog rows + deep links, cross-domain host example. |
| v1.8 | Guide ExUnit (`organization_billing_*`), bash `verify_adoption_proof_matrix.sh`, host-integration wiring in CI README | ORG-05..ORG-09 (5/5) archived | Matrix ORG-09 section, root verifier script, contributor map rows for ORG gates. |
| v1.7 | Doc contract scripts, targeted ExUnit, VERIFY-01 Playwright lanes touching dashboard copy | ADOPT + OPS (11/11) archived | `scripts/ci/README.md` ADOPT map, dual-contract `testing.md` section, `36-FORWARD-COUPLING-OPS-34-35.md`, dashboard `Copy` + `copy_dashboard.js`. |
| v1.6 | VERIFY-01 Playwright (desktop + mobile), ExUnit/HTML assertions on touched LiveViews, axe on mounted customers index | INV/COPY/UX/A11Y/MOB (18/18) archived | `AccrueAdmin.Copy`, mobile admin spec, README mobile shell section, verification markdown per phase. |
| v1.5 | Existing VERIFY-01 contracts + docs guide tests; no new CI topology | PROOF-01..03 (3/3) archived | Adoption proof matrix, evaluator walkthrough script, guide + CI naming clarity. |
| v1.2 | Host UAT, Playwright trust flow, docs verifier, release guidance tests, trust/security review artifacts | 23/23 audited requirements plus Phase 17 cleanup verification | Canonical demo/tutorial contracts, issue templates, trust review, expansion recommendation, security verification. |
| v1.1 | Host ExUnit, Playwright, shell UAT, docs verifier, Hex smoke | 21/21 audited scoped requirements | Host app, Playwright gate, setup diagnostics, conflict sidecars, package-doc verifier. |
| v1.0 | CI matrix plus package-local suites | Not tracked | Fake processor, test adapters, installer snippets, and docs-first release checks. |

### Top Lessons (Verified Across Milestones)

1. Warnings-as-errors should remain a release blocker.
2. Planning state needs to be updated at release boundaries, not just phase boundaries.
3. User-facing host-app proof catches integration gaps that package-local tests miss.
4. Docs and security contracts are worth writing for release-process wording, not only runtime code.

---

## Documentation polish (2026-04-18)

Shipped a pass removing internal delivery traceability codes (`T-…`, `D…`,
`OBS-…`, `CHKT-…`, etc.) from `accrue` Hex-facing guides, `@moduledoc` /
`@doc` strings, `Accrue.Config` NimbleOptions docs, representative tests, and
related comments so public docs read as product documentation rather than
planning appendices. Follow-up: deeper editorial pass on remaining `lib/`
section comments and any straggling requirement shorthand if it resurfaces in
ExDoc output.
