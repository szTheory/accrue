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

## Milestone: v1.12 — Admin & operator UX

**Shipped:** 2026-04-22  
**Phases:** 3 | **Plans:** 6

### What Was Built

- **Post-metering dashboard signal (ADM-01):** terminal-failed **MeterEvent** KPI on the default admin home with honest **`/events`** navigation and **`AccrueAdmin.Copy`** strings.
- **Drill/nav polish (ADM-02, ADM-03):** **SubscriptionLive** **`ScopedPath`** breadcrumbs + **Related billing** card; **LiveViewTest** + mounted-host proofs for drill href targets; admin **README** router vs sidebar ordering note.
- **Copy, tokens, VERIFY (ADM-04..ADM-06):** **`AccrueAdmin.Copy.Subscription`** + **`SubscriptionLive`** migration; checked-in **`theme-exceptions.md`** register + **CONTRIBUTING** contributor bullet; **`mix accrue_admin.export_copy_strings`** artifact wired into VERIFY-01 **subscriptions** Playwright + **axe** coverage.

### What Worked

- Reusing the **v1.11** close pattern (per-phase verification + traceability, no standalone milestone audit file) kept archival unblocked.
- **Copy-export → JSON → Playwright** closed the classic “duplicate English literal” drift class for one high-traffic admin surface.

### What Was Inefficient

- **`gsd-sdk query milestone.complete`** failed again (`version required for phases archive`); **`v1.12-*`** archives and **`git rm .planning/REQUIREMENTS.md`** were completed manually.
- Root **`.planning/REQUIREMENTS.md`** stayed partially unchecked until close despite **`PROJECT.md`** and plan YAML already asserting completion.

### Patterns Established

- **Meter-adjacent KPIs** reuse aggregate + **Copy** + **ScopedPath** deep links instead of inventing new index pages.
- **Allowlisted Mix export** of **Copy** strings as the VERIFY-01 anti-drift bridge for browser assertions.

### Key Lessons

1. Checkbox/traceability hygiene should follow **`requirements-completed`** YAML at each phase close, not only at milestone archive.
2. **Mounted-path inventory** docs pay off when expanding VERIFY-01 without guessing “what changed this milestone.”

### Cost Observations

- Model mix: not tracked.
- Sessions: three short phases (**48–50**) focused on admin UX + gates.
- Notable: majority of merge risk was **test + CI wiring** (export task, generated JSON, axe spec), not LiveView churn.

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

## Milestone: v1.13 — Integrator path + secondary admin parity

**Shipped:** 2026-04-23  
**Phases:** 3 | **Plans:** 8

### What Was Built

- **Phase 51:** Single **First Hour** ↔ **host README** integrator spine (H/M/R capsules), thin **quickstart** hub, repo-root **VERIFY-01** discoverability, and troubleshooting / webhook anchors with stable slugs (**INT-01..INT-03**).
- **Phase 52:** Honest **adoption proof matrix** + **Hex** / **`verify_package_docs`** alignment (**INT-04**, **INT-05**); **`AccrueAdmin.Copy.Coupon`** + **`Copy.PromotionCode`** with LiveView + test literal discipline (**AUX-01**, **AUX-02**).
- **Phase 53:** **`AccrueAdmin.Copy.Connect`** + **`Copy.BillingEvent`**; optional **`DataTable.filter_submit_label`**; **theme-exceptions** reviewer note; **VERIFY-01** Playwright + **axe** for auxiliary routes; **`export_copy_strings`** allowlist + **`copy_strings.json`** regeneration (**AUX-03..AUX-06**).

### What Worked

- Reusing the **v1.12** pattern (**Copy submodule** + **`defdelegate`** facade + export JSON for browser tests) extended cleanly to **coupon**, **promotion code**, **Connect**, and **events** surfaces.
- Treating **First Hour** and **`accrue_host` README** as one paired narrative reduced first-run contradiction drift.

### What Was Inefficient

- Root **`.planning/REQUIREMENTS.md`** traceability for **INT-04** / **INT-05** lagged **Pending** until milestone archive despite Phase **52** completion—same checkbox hygiene gap noted on **v1.12**.
- **`gsd-sdk query milestone.complete`** / **`roadmap.analyze`** remained unreliable for this repo layout; milestone files were authored manually again.

### Patterns Established

- **Per-surface `AccrueAdmin.Copy.*` modules** as the default shape for new admin English SSOT beyond **`Copy.Subscription`**.
- **Host seed + fixture IDs** for deterministic **VERIFY-01** URLs on **Connect** detail paths without live Stripe.

### Key Lessons

1. Sync **`REQUIREMENTS.md`** checkboxes when **`requirements-completed`** YAML lands in the last plan summary of a phase—not only at milestone close.
2. **Auxiliary** admin routes deserve the same **mounted-path inventory** + **axe** contract as money-spine pages whenever VERIFY-01 touches them.

### Cost Observations

- Model mix: not tracked.
- Sessions: three short phases (**51–53**) spanning docs + admin + CI gates.
- Notable: majority of merge risk was **generated `copy_strings.json`** + Playwright allowlist churn, not domain billing logic.

---

## Milestone: v1.14 — Companion admin + billing depth

**Shipped:** 2026-04-23  
**Phases:** 3 | **Plans:** 6

### What Was Built

- **Phase 54:** **`guides/core-admin-parity.md`** **ADM-07** matrix; **`AccrueAdmin.Copy.Invoice`** + invoice LiveView operator chrome (**ADM-08**).
- **Phase 55:** Merge-blocking **VERIFY-01** **`core-admin-invoices-*`** flows; **`verify_core_admin_invoice_verify_ids.sh`**; **`theme-exceptions.md`** + **`export_copy_strings`** / **`copy_strings.json`**; core list **org scoping** on **`DataTable`** (**ADM-09..ADM-11**).
- **Phase 56:** **`Accrue.Billing.list_payment_methods/2`** + **`!/2`** with **`span_billing(:payment_method, :list, …)`**, Fake **`payment_method_list_test.exs`**, **`guides/telemetry.md`** + **CHANGELOG** + installer **`billing.ex.eex`** + **`first_hour.md`** (**BIL-01**, **BIL-02**).

### What Worked

- Reusing the **v1.12 / v1.13** **Copy submodule + `defdelegate`** pattern on **invoices** kept core parity aligned with auxiliary work.
- **Router-derived parity matrix** as single SSOT reduced forked “what’s covered?” narratives.

### What Was Inefficient

- **`gsd-sdk query milestone.complete`** failed again (`version required for phases archive`); milestone archives were written manually (same as **v1.11–v1.13**).

### Patterns Established

- **CI drift guard** for named **VERIFY-01** flow ids (`verify_core_admin_invoice_verify_ids.sh`) when invoice E2E anchors are merge-blocking.

### Key Lessons

1. **`roadmap.analyze`** can surface unrelated legacy phases; treat **milestone-scoped** phase directories as the readiness source of truth.
2. Keep **telemetry catalog** rows in lockstep with **billing span** metadata when adding façade read APIs.

### Cost Observations

- Model mix: not tracked.
- Sessions: three short phases (**54–56**) spanning docs + admin + billing façade.
- Notable: majority of churn was **VERIFY-01** + **copy_strings.json** + CI wiring, not **`Accrue.Billing`** core logic.

---

## Milestone: v1.15 — Release / trust semantics

**Shipped:** 2026-04-23  
**Phases:** 2 | **Plans:** 0 (docs-only; no new phase directories)

### What Was Built

- **`accrue/guides/upgrade.md`**: accurate **Hex + `@version`** baseline; **`.planning/` vs SemVer** explanation; link to **`RELEASING.md`** **`1.0.0`** appendix.
- **`RELEASING.md`** + root **`README.md`**: explicit note that **internal planning milestone labels** are not the Hex major line.
- **`examples/accrue_host/README.md`**: **Sigra** framed as **demo convenience**; **`Accrue.Auth`** + **First Hour** / **organization billing** pointers.
- **`accrue/README.md`**: **Stability** ties **`0.x`** to deprecation discipline + maintainer bootstrap pointer.
- **`scripts/ci/verify_package_docs.sh`**: **extras** string aligned to **`accrue_admin/mix.exs`** (CI drift fix).

### What Worked

- Shipping **forcing function B** as a **thin doc milestone** avoided another multi-phase admin polish cycle.
- **`audit-open`** pre-close reported **all clear**, so closeout did not stall on tooling noise.

### What Was Inefficient

- **`verify_package_docs`** had drifted from **`mix.exs`** **extras** — caught only because this milestone touched release-adjacent docs.

### Key Lessons

1. When **planning speaks in `v1.x`** but **Hex is `0.x`**, put the disambiguation in **three obvious places**: **upgrade**, **RELEASING**, **root README**.
2. **Demo dependencies** (Sigra) need a **one-screen disclaimer** so library positioning is not misread as product coupling.

### Cost Observations

- Sessions: single closeout session after doc land.
- Notable: highest leverage was **wording**, not new APIs.

---

## Milestone: v1.16 — Integrator + proof continuity

**Shipped:** 2026-04-23  
**Phases:** 3 | **Plans:** 6

### What Was Built

- **Phase 59 (INT-06):** **First Hour** / **quickstart** / **CONTRIBUTING** coherence with **v1.15** trust messaging; **`verify_package_docs`** extended for quickstart hub + capsule literals with **`package_docs_verifier_test`** coverage.
- **Phase 60 (INT-07):** **Adoption proof matrix** + **evaluator walkthrough** trust stub and cross-links; **`scripts/ci/README.md`** INT-06/INT-07 contributor map rows aligned to **ADOPT**/**ORG** table shape.
- **Phase 61 (INT-08, INT-09):** Root **README** merge-blocking **VERIFY-01** line pinned in **`verify_package_docs.sh`**; **INT-09** dual-track (**`@version`** vs **public Hex**) in **PROJECT** / **MILESTONES** + **CONTRIBUTING** pre-publish **`mix deps.get`** note.

### What Worked

- **`audit-open`** pre-close was **all clear**, matching **v1.15** close hygiene.
- Splitting **INT-08** (verifier ownership + README pin) from **INT-09** (planning + contributor **Hex** SSOT) kept each phase reviewable.

### What Was Inefficient

- **`gsd-sdk query milestone.complete`** failed again (`version required for phases archive`); milestone archives were written manually (same as **v1.11–v1.15**).
- **`roadmap.analyze`** still picks up legacy phase rows (for example **Phase 24**) unrelated to the active milestone; human judgment on **59–61** remained the readiness source of truth.

### Patterns Established

- **Contributor map** rows for integrator milestones (**INT-***) live next to **ADOPT**/**ORG** gates in **`scripts/ci/README.md`**.
- **`verify_package_docs.sh`** as the home for **release-gate** vs **host-integration** verifier ownership comments plus **README** literal pins when hop budgets are load-bearing.

### Key Lessons

1. After any **trust SemVer** milestone (**v1.15**), schedule an explicit **integrator continuity** pass so **First Hour** / **quickstart** / proof matrix cannot drift silently.
2. When **`@version`** on **`main`** runs ahead of **Hex**, document the **dual authority** in **three places**: **PROJECT** Current State, **MILESTONES** header, and **CONTRIBUTING** sharp edges.

### Cost Observations

- Model mix: not tracked.
- Sessions: three short phases (**59–61**) spanning docs + CI scripts + planning mirrors.
- Notable: highest leverage was **verifier + README pins**, not new runtime code.

---

## Milestone: v1.17 — Friction-led developer readiness

**Shipped:** 2026-04-23  
**Phases:** 4 | **Plans:** 8

### What Was Built

- **Phase 62 (FRG-01..FRG-03):** **`research/v1.17-FRICTION-INVENTORY.md`** + **`v1.17-north-star.md`**; **FRG-03** backlog anchors mapping **P0** rows to **INT-10** / **BIL-03** / **ADM-12** (including explicit empty-queue rows).
- **Phase 63 (INT-10):** Package README + **First Hour** **Hex vs branch** clarity (**63-01**); **`[host-integration] phase=…`** stderr slugs across host verify helpers + contributor map (**63-02**); remaining integrator/VERIFY/docs **P0** closure per **63-VERIFICATION.md** (**63-03**).
- **Phase 64 (BIL-03):** Signed certification of **no billing P0** rows for this milestone + **`64-VERIFICATION.md`** + **`v1_17_friction_research_contract_test.exs`** / shell contract green.
- **Phase 65 (ADM-12):** **`65-VERIFICATION.md`** + inventory maintainer line; signed certification of **no admin P0** rows; verification table family aligned with **63/64**.

### What Worked

- **Triage-first** milestone shape prevented another unfocused doc sweep after **v1.16**.
- **Empty-queue certification** as an explicit ship path for **BIL-03** / **ADM-12** kept honesty high when **FRG-03** showed no billing/admin **P0** work.

### What Was Inefficient

- **`gsd-sdk query milestone.complete`** failed again (`version required for phases archive`); closeout archives were written manually (same as **v1.11–v1.16**).
- **`roadmap.analyze`** disagreed with on-disk verification for Phase **64** (summary count / disk status); humans relied on **`*-VERIFICATION.md`** + **REQUIREMENTS** traceability instead.
- **`audit-open`** reported a **Phase 62 UAT** gap at close; it was **acknowledged** and recorded in **STATE.md** rather than blocking archive.

### Key Lessons

1. When the milestone is **conditional axes** (**INT** / **BIL** / **ADM**), ship **FRG-03** anchors in the inventory doc *before* execution phases so empty queues are provable, not implied.
2. Keep **one verification SSOT per phase** (**`*-VERIFICATION.md`**) so **`gsd-sdk`** heuristics cannot become the release-of-truth.

### Cost Observations

- Sessions: four short phases after **`phases.clear`** reset.
- Notable: highest leverage was **inventory + contracts**, not new **Billing** APIs.

---

## Milestone: v1.18 — Onboarding confidence

**Shipped:** 2026-04-23  
**Phases:** 1 | **Plans:** 3

### What Was Built

- **`66-VERIFICATION.md`** as the single evidence ledger for **UAT-01..UAT-05** and **PROOF-01**, with merge-blocking command column and CI job citations.
- **`verify_v1_17_friction_research_contract.sh`** + **`v1_17_friction_research_contract_test.exs`** extended for **UAT-04** archive presence and friction/north-star SSOT invariants.
- **PROOF-01** alignment pass: adoption proof matrix, evaluator walkthrough, host README, **`verify_adoption_proof_matrix.sh`**, and org matrix ExUnit literals kept in one taxonomy change-set discipline.
- **`62-UAT.md`** supersession banner only — archived scenario body preserved under **`milestones/v1.17-phases/`**.

### What Worked

- Treating **REQUIREMENTS** as normative over legacy **`62-UAT`** prose avoided rewriting historical UAT while still closing the confidence gap.
- Reusing the **v1.17** friction script + shift-left CI lane gave binary invariants without over-automating subjective UAT rows.
- Three-wave plan split (ledger → STATE/script → PROOF + requirements flip) kept review scope bounded.

### What Was Inefficient

- **`gsd-sdk query milestone.complete`** remained unusable (`version required for phases archive`); manual archives + **`git rm` REQUIREMENTS** again.
- **`roadmap.analyze`** stayed on **planned** until plan **SUMMARY** files existed — easy to forget at close.

### Key Lessons

1. Backfill **`*-SUMMARY.md`** before calling milestone tooling so disk-derived progress matches verification SSOT.
2. When **`milestone.complete` CLI** fails, mirror the **v1.17** manual archive pattern and record the debt in the milestone archive **Technical debt** section.

### Cost Observations

- Sessions: single phase, three short execute plans after research/plan phase.
- Notable: mostly docs + CI contracts; no **Billing** API surface churn.

---

## Milestone: v1.19 — Release continuity + proof resilience

**Shipped:** 2026-04-24  
**Phases:** 3 | **Plans:** 5

### What Was Built

- Merge-blocking **`verify_adoption_proof_matrix.sh`** alignment with **`adoption-proof-matrix.md`** (Layer C script names, **ORG-05** / **ORG-06** taxonomy) plus contributor triage in **`scripts/ci/README.md`** (**PRF-01..02**).
- **`RELEASING.md`** publish-ordering clarity and **`68-VERIFICATION.md`** URL table for **0.3.1** Hex, GitHub release tags, and changelog blobs (**REL-01..03**).
- **`verify_package_docs`** / **`package_docs_verifier_test.exs`** continuity and **PROJECT** / **MILESTONES** / **STATE** Hex mirror pass (**DOC-01..02**, **HYG-01**).

### What Worked

- Sequencing **PRF** before **REL** prevented shipping while matrix ↔ verifier drift could still regress CI.
- URL-first verification tables made **REL-03** evidence reviewable without local Stripe or app boot.

### What Was Inefficient

- **`gsd-sdk query milestone.complete`** still cannot archive phases automatically; milestone close remained partially manual (**v1.18** precedent).

### Patterns Established

- Treat **matrix + bash verifier + ExUnit literal harness** as a single co-update surface for shift-left contributor docs.

### Key Lessons

1. When workspace **`@version`** runs ahead of Hex, planning hygiene (**HYG-01**) should follow immediately after publish evidence lands.
2. Keep **`audit-open`** in the pre-close checklist; it stayed green for **v1.19**.

### Cost Observations

- Model mix: not tracked.
- Sessions: short milestone spanning proof, publish evidence, and planning mirrors.

---

## Milestone: v1.20 — Professional adoption confidence

**Shipped:** 2026-04-24  
**Phases:** 2 | **Plans:** 0 (verification-only bootstrap)

### What Was Built

- **INV-01..02:** **`v1.17-P1-001`** row closed in **`.planning/research/v1.17-FRICTION-INVENTORY.md`** with pointers to **v1.19** **PRF** verification and a dated maintainer note when no new sourced **P0/P1** rows were added.
- **PRD-01..02:** **`accrue/guides/production-readiness.md`** checklist spine linking only to existing guides; cross-links from **First Hour**, **configuration**, and **`examples/accrue_host` README**.

### What Worked

- Keeping **v1.20** strictly **docs + planning evidence** preserved merge-blocking CI semantics while still shipping evaluator-facing production posture routing.
- Relocating Phases **70–71** to **`milestones/v1.20-phases/`** at close matches the **v1.19** durable execution-history pattern.

### What Was Inefficient

- **`gsd-sdk query milestone.complete`** still cannot drive full archival; manual **`milestones/v1.20-*`** + **`git mv`** + **`git rm` REQUIREMENTS** closeout (same debt as **v1.18–v1.19**).

### Key Lessons

1. **Bootstrap verification** phases (**`*-VERIFICATION.md`** only) are sufficient for small doc milestones when **REQUIREMENTS** traceability stays tight.
2. Record **`milestone.complete` CLI** limitation in each archive **Technical debt** section so the next close does not rediscover it.

### Cost Observations

- Model mix: not tracked.
- Sessions: short milestone after **v1.19** ship; no Hex or billing API churn.

---

## Milestone: v1.21 — Maturity posture and diminishing returns

**Shipped:** 2026-04-23  
**Phases:** 2 | **Plans:** 0 (verification-only bootstrap)

### What Was Built

- **MAT-01..MAT-02:** **`.planning/PROJECT.md`** maintenance posture (**FRG-01** intake, revisit triggers) with links to north star, friction inventory, **`production-readiness.md`**, and new **`accrue/guides/maturity-and-maintenance.md`**; discoverability cross-links from **First Hour**, **production-readiness**, and **CONTRIBUTING**.
- **INT-11:** **`scripts/ci/README.md`** **same-PR** contributor checklist for **First Hour** H/M/R capsules vs **`examples/accrue_host` README** proof spine; **`v1.17-P2-001`** closed in **`.planning/research/v1.17-FRICTION-INVENTORY.md`** with dated pointer to that checklist.

### What Worked

- Pairing **PROJECT** posture with a short integrator-facing **maturity-and-maintenance** guide kept **PROC-08** / **FIN-03** boundaries visible without new billing APIs.
- Closing **P2** friction rows with **CI README** contracts reuses the **v1.19** matrix/script co-update discipline at lower scope.

### What Was Inefficient

- **`gsd-sdk query milestone.complete`** still cannot drive full archival; manual **`milestones/v1.21-*`** + **`git rm` REQUIREMENTS** closeout (**v1.18–v1.20** precedent).

### Patterns Established

- Treat **capsule parity** (First Hour ↔ host README) as a **same-PR** maintainer checklist, not an implicit reviewer memory.

### Key Lessons

1. **Bootstrap verification** phases (**`*-VERIFICATION.md`** only) remain sufficient for small doc milestones when **REQUIREMENTS** traceability stays at **3/3** and **`audit-open`** is green.
2. Record **`milestone.complete` CLI** limitation in milestone archive **Technical debt** so the next close does not rediscover it.

### Cost Observations

- Model mix: not tracked.
- Sessions: short milestone; no Hex publish or **`Accrue.Billing`** surface churn.

---

## Milestone: v1.22 — Production path discoverability

**Shipped:** 2026-04-24  
**Phases:** 1 | **Plans:** 0 (bootstrap **74-VERIFICATION.md**)

### What Was Built

- Root **`README.md`** and **`accrue/README.md`** link **`accrue/guides/production-readiness.md`** with explicit production / live-Stripe promotion framing (**PRS-01**, **PRS-02**).
- Merge-blocking **`scripts/ci/verify_production_readiness_discoverability.sh`** in **`docs-contracts-shift-left`**: link needles plus **`### 1.`**–**`### 10.`** spine stability (**PRS-03**).
- **`scripts/ci/README.md`** PRS gate table + triage / same-PR co-update expectations for checklist edits.

### What Worked

- Shipping **PRS** as a narrow verifier plus CI lane avoided scope creep into **PROC-08** / **FIN-03** while reusing the **v1.20** production-readiness spine.

### What Was Inefficient

- **`gsd-sdk query milestone.complete`** still cannot drive full archival; manual **`milestones/v1.22-*`** plus **`git rm` REQUIREMENTS** closeout (**v1.19–v1.21** precedent).

### Patterns Established

- Treat **production-readiness** discoverability as a **merge-blocking** doc contract alongside package-doc verifiers, not optional README polish.

### Key Lessons

1. **Bootstrap verification** (**`*-VERIFICATION.md`** only) remains sufficient when **REQUIREMENTS** traceability is **3/3** and **`audit-open`** is green at close.
2. **`gsd-sdk query roadmap.analyze`** still does not parse this **ROADMAP** shape; rely on milestone archives and explicit progress tables for readiness.

### Cost Observations

- Model mix: not tracked.
- Sessions: single open commit carried **PRS** implementation; follow-up commits were unrelated hygiene.

---

## Milestone: v1.23 — Post-publish contract alignment

**Shipped:** 2026-04-24  
**Phases:** 1 | **Plans:** 0 (bootstrap **75-VERIFICATION.md**)

### What Was Built

- **PPX-01..04** — **`verify_package_docs`** + **`verify_adoption_proof_matrix`** + full **`docs-contracts-shift-left`** pass (including **production-readiness discoverability**) at **0.3.1** workspace / Hex alignment.
- **`verify_v1_17_friction_research_contract.sh`** + **`scripts/ci/README.md`** triage text aligned to **5** friction-inventory rows after **`v1.17-P1-002`** closure.
- **`.planning/`** mirror callouts (**PROJECT**, **MILESTONES**, **STATE**) consistent with published pair; **`v1.17-P1-002`** closed with **75-VERIFICATION** pointer.

### What Worked

- Narrow **publish-adjacent** scope kept **PROC-08** / **FIN-03** out while re-binding the same verifier bundle used since **v1.19–v1.22**.

### What Was Inefficient

- **`gsd-sdk query roadmap.analyze`** / **`milestone.complete`** still do not drive this repo’s **ROADMAP** closeout; manual **`milestones/v1.23-*`** archives remain the durable path.

### Patterns Established

- Treat **post-Hex publish** as an explicit revisit trigger for **PPX-** class contract passes, not only **HYG-01** mirror edits.

### Key Lessons

1. **Bootstrap verification** remains sufficient for single-phase milestones when traceability is **4/4** and **`audit-open`** is green at close.
2. Closing **P1 friction rows** in the same milestone that opens them is acceptable when scope stays verifier- and mirror-only.

### Cost Observations

- Model mix: not tracked.
- Sessions: short verification + planning hygiene pass.

---

## Milestone: v1.24 — Billing portal facade + customer PM operator surfaces

**Shipped:** 2026-04-24  
**Phases:** 3 | **Plans:** 6

### What Was Built

- **`Accrue.Billing.create_billing_portal_session/2`** (+ **`!`**) with **Fake** ExUnit, **`span_billing(:billing_portal, :create, …)`**, and metadata guards excluding portal URLs (**BIL-04**).
- **Telemetry + ops narrative** updates: **`guides/telemetry.md`**, **`operator-runbooks.md`**, **`CHANGELOG`** for billing portal + **payment_method** write spans (**BIL-05**).
- **Customer `payment_methods`** tab: **ADM-13** inventory, **ADM-14** **`AccrueAdmin.Copy`** / **`ax-*`** burn-down, **ADM-15** VERIFY-01 Playwright + **axe**, **ADM-16** theme exceptions + **`export_copy_strings`** hygiene.

### What Worked

- Six plan **`*-SUMMARY.md`** files plus **`*-VERIFICATION.md`** gave auditable closure without a separate milestone audit artifact.

### What Was Inefficient

- **`gsd-sdk query milestone.complete`** still not driving this repo’s closeout; manual **`milestones/v1.24-*`** + **`git rm` REQUIREMENTS** remains the durable path (**v1.19–v1.23** precedent).

### Patterns Established

- Treat **customer** mounted admin paths as first-class **VERIFY-01** citizens when **Copy** / theme work materially changes operator-visible chrome.

### Key Lessons

1. **Facade + span** pattern on **`Accrue.Billing`** keeps host entry consistent with other billing delegates while reusing **`BillingPortal.Session`** validation.
2. **`audit-open`** all clear remains a sufficient pre-close gate when **REQUIREMENTS** traceability is **6/6**.

### Cost Observations

- Model mix: not tracked.
- Sessions: three tight phases in one day; no **Hex** SemVer bump in this planning milestone.

---

## Milestone: v1.25 — Evidence-bound triad (friction + integrator + billing depth)

**Shipped:** 2026-04-24  
**Phases:** 3 | **Plans:** 3

### What Was Built

- **INV-03** path **(b)** — dated maintainer certification on **`v1.17-FRICTION-INVENTORY.md`** with **`079-VERIFICATION.md`** verifier transcripts.
- **`Accrue.Billing.create_checkout_session/2`** (+ **`!`**) — **NimbleOptions**, **`span_billing(:checkout_session, :create, …)`**, **PII-safe** metadata, **Fake** **`checkout_session_facade_test.exs`** (**BIL-06**).
- **BIL-07** + **INT-12** — **`guides/telemetry.md`** / **`operator-runbooks.md`** / **`CHANGELOG`**; **First Hour**, host README, adoption matrix, **`verify_package_docs`**, **`verify_adoption_proof_matrix`** needles aligned in one slice (**`081-VERIFICATION.md`**).

### What Worked

- **`audit-open`** all clear at pre-close gate; **4/4** requirements traceability once **`REQUIREMENTS.md`** table was aligned to **Phase 81** completion.
- Moving **79–81** execution trees to **`milestones/v1.25-phases/`** keeps **`phases/`** empty for the next milestone without losing evidence paths.

### What Was Inefficient

- **`gsd-sdk query milestone.complete`** still returns **`version required for phases archive`** — manual **`milestones/v1.25-*`** + **`git rm` REQUIREMENTS** remains the durable closeout path.
- **Phase 81** lacked a **`*-SUMMARY.md`** until milestone close backfill.

### Patterns Established

- Treat **INT-12** “same PR” integrator needle updates as mandatory whenever **`Accrue.Billing`** checkout is promoted on golden-path surfaces.

### Key Lessons

1. **Traceability tables** must be updated when the last phase closes, or milestone close surfaces false **Pending** rows against green verification.
2. Single-plan phases still benefit from a minimal **`*-01-SUMMARY.md`** for accomplishment extraction and audit consistency.

### Cost Observations

- Model mix: not tracked.
- Sessions: three phases same-day; no **Hex** **@version** bump in this planning milestone.

---

## Milestone: v1.26 — First-hour billing facade spine

**Shipped:** 2026-04-24  
**Phases:** 2 | **Plans:** 3

### What Was Built

- **INT-13** — **`create_billing_portal_session`** on **First Hour** + telemetry anchor **`#billing-billing-portal-create`**, host README observability + proof capsule, adoption proof matrix blocking row, **`verify_package_docs`** + **`verify_adoption_proof_matrix`** substring gates, **`CHANGELOG`** **[Unreleased]** slice (**`082-01`**, **`082-02`**, **`082-VERIFICATION.md`**).
- **INV-04** path **(b)** — **`### v1.26 INV-04 maintainer pass (2026-04-24)`** in **`v1.17-FRICTION-INVENTORY.md`** with reviewed SHA + verifier bundle pointers; **`083-VERIFICATION.md`** transcripts + closure checklist (**`083-01`**).

### What Worked

- Phase trees already lived under **`.planning/milestones/v1.26-phases/`** before close, avoiding a second move; archives **`v1.26-*`** mirror the **v1.25** manual closeout.
- **`audit-open`** all clear at pre-close gate; **2/2** requirements checked in **`REQUIREMENTS.md`** before archive.

### What Was Inefficient

- **`gsd-sdk query milestone.complete`** still returns **`version required for phases archive`** — manual **`milestones/v1.26-*`** + **`git rm` REQUIREMENTS** remains the durable path.

### Patterns Established

- **INT-13** extends the **INT-12** “golden path mentions facade → same-PR verifier needles” rule to **billing portal** after **checkout** landed in **v1.25**.

### Key Lessons

1. Two-plan phase **82** plus single-plan **83** still benefits from explicit **`*-VERIFICATION.md`** per phase for friction inventory attestation chains.
2. Optional **`v1.26-MILESTONE-AUDIT.md`** was not created; **traceability + `audit-open`** remained sufficient for this scope.

### Cost Observations

- Model mix: not tracked.
- Sessions: two phases same-day; no **Hex** **@version** bump in this planning milestone.

---

## Milestone: v1.27 — Pre-1.0 closure narrative

**Shipped:** 2026-04-24  
**Phases:** 2 | **Plans:** 0 (inline verification)

### What Was Built

- **CLS-01..03** — **Maintenance posture** on repo root **`README.md`**; **`accrue/README.md`** **Start here** + **Stability**; **`RELEASING.md`** **Pre-1.0 closure**; **`accrue/guides/upgrade.md`** **Pre-1.0 wrap-up semantics** — **`084-VERIFICATION.md`**.
- **INV-05** path **(b)** — **`### v1.27 INV-05 maintainer pass (2026-04-24)`** in **`v1.17-FRICTION-INVENTORY.md`** with verifier bundle pointers; **`085-VERIFICATION.md`** transcripts.

### What Worked

- **v1.26**-precedent manual **`milestones/v1.27-*`** archives + **`git rm` REQUIREMENTS** kept the close deterministic without **`gsd-sdk query milestone.complete`**.
- **`audit-open`** all clear at pre-close gate; **4/4** requirements checked before archive.

### What Was Inefficient

- No per-plan **`SUMMARY.md`** for phases **84–85** (inline close); evidence weight sits on **`084-` / `085-VERIFICATION.md`** alone.

### Patterns Established

- **CLS-** narrative is the integrator-facing complement to **v1.21** **MAT-** maintainer docs: same **PROC-08** / **FIN-03** parking lot, clearer **pre-1.0** SemVer story on front doors.

### Key Lessons

1. **`INV-05`** reuses the **INV-03** / **INV-04** verifier-bundle transcript family — keeps friction SSOT honest after doc-only milestones.
2. Optional **`v1.27-MILESTONE-AUDIT.md`** was not created; **traceability + `audit-open`** remained sufficient for doc + inventory scope.

### Cost Observations

- Model mix: not tracked.
- Sessions: two phases same-day; no **Hex** **@version** bump in this planning milestone.

---

## Milestone: v1.29 — Mailglass Integration

**Shipped:** 2026-04-26
**Phases:** 3 (88–90) | **Plans:** 8 | **Tasks:** ~18

### What Was Built

- Mailglass framework wired in as a sibling-repo path dependency (`{:mailglass, path: "../../mailglass"}`), with `mailglass_admin` mounted at `/dev/mail` in `accrue_admin` for instant template preview.
- Worker seam refactored: `Accrue.Workers.Mailer` now dispatches via `Mailglass.deliver/1` with explicit `idempotency_key`, replacing the in-process Oban `unique: [period: 60]` window with database-level deduplication.
- All 13 transactional templates ported from MJML to Mailglass HEEx mailables (Receipt, PaymentFailed, Trial-Ending, Trial-Ended, Subscription-Canceled/Paused/Resumed, Card-Expiring-Soon, Invoice-Finalized/Paid/Payment-Failed, Refund-Issued, Coupon-Applied, Payment-Succeeded). PDF attachment for Receipt preserved end-to-end.
- Hard cleanup: `mjml_eex` and `phoenix_swoosh` removed from `accrue/mix.exs`; 26 legacy `*.mjml.eex` / `*.text.eex` template assets deleted; `mix accrue.mail.preview`, `Accrue.Emails.HtmlBridge`, and `Accrue.Workers.Mailer.template_for/1` retired with no compatibility shim.
- `mailglass_cleanup_test` introduced as a permanent regression guard (5 assertions in CI) that the dropped deps, helpers, and assets stay gone — and that the email guide stays pointed at the supported `/dev/email-preview` LiveView.

### What Worked

- Phase-by-phase batches kept the port digestible: lifecycle group → invoice/refund/coupon group → cleanup. Each commit was independently revertible.
- Treating the Phase 90 `mailglass_cleanup_test` as a "merge gate" — not a one-shot check — encoded the cleanup intent into CI rather than relying on tribal memory. Future contributors can't accidentally reintroduce `mjml_eex`.
- Parity tests deliberately asserted adopter-visible content/structure rather than byte-for-byte HTML equality (D-07/D-08). This kept the port honest without bikeshedding markup differences between MJML and HEEx.
- Shift-left UAT taken to its conclusion in Phase 90: 7/7 truths automated, 0 human steps. The `email_preview_live_test` fixture-sweep proves every mail type renders through the admin LiveView in the same test pass that proves the cleanup landed.

### What Was Inefficient

- The pre-existing `milestones/v1.29-{ROADMAP,REQUIREMENTS}.md` archive stubs (created at milestone open) were stale by the time of close — they had to be fully overwritten with real archive content. Future milestones should either skip the open-time stubs or mark them clearly as "to-be-overwritten" so they aren't mistaken for current state.
- Phase 90 plan execution committed source-code work via `feat(90-XX)` commits but the per-plan SUMMARY.md / VERIFICATION.md files lagged until milestone close. Closing the loop required reconstructing summaries from commit messages and plan files — workable but slower than recording at completion time.
- v1.28 was opened then "transitioned" rather than formally closed (no `v1.28` git tag exists). Loss of bookkeeping is small, but it's a precedent worth flagging — milestones should either ship-and-tag or be explicitly skipped, not silently rolled into the next.

### Patterns Established

- **Cleanup-with-CI-guard:** when retiring a dependency or helper, ship a regression test in the same PR that asserts the dependency / helper stays gone (`mailglass_cleanup_test` is the canonical example).
- **Sibling-scope LiveView mounting:** when a sub-package exposes its own LiveView, mount it OUTSIDE the host's `live_session` block via a sibling scope. Phoenix forbids nested `live_session` blocks.
- **Path-dep first, Hex later:** integrating a sibling library can ship via `path:` dep first, with the Hex publish gating to a follow-up milestone. Avoids blocking the integration on the dependency's release cadence.
- **Explicit `idempotency_key` over Oban `unique:`:** when the work is meaningful enough to warrant database-level dedup, push idempotency into the persistence layer rather than the queue layer. Stronger guarantees, observable in DB.

### Key Lessons

1. Pre-built archive stubs at milestone-open create stale state that must be reconciled at close. Either skip them or treat them as ephemeral.
2. Plan SUMMARY/VERIFICATION files should land in the same commit as the source-code changes — reconstructing from commits is workable but error-prone.
3. Shift-left UAT (`mode: shift-left`, `human_steps_required: 0`) is achievable for cleanup-shaped phases when the assertions are file-system / dependency / content checks. Codify the pattern in `CONTRIBUTING.md` so future phases default to it.
4. Library cleanup commits should always include a regression-guard test (`mailglass_cleanup_test` as precedent). Otherwise CI will pass and the next contributor will reintroduce the dropped surface.

### Cost Observations

- Model mix: not tracked.
- Sessions: three phases over ~36 hours (Phase 88 → 89 → 90). Combined-commit pattern (one commit per plan instead of per task) kept git history readable.
- Notable: the cleanup phase was the largest by file-count (52 files in the single commit) but the lowest-risk by behavior — driven by deletes plus the `payment_succeeded` port.

---

## Milestone: v1.39 — Entitlements / Plan-Gating

**Shipped:** 2026-05-24
**Phases:** 5 (123–127) | **Plans:** 21 | **Tasks:** 53 | **Timeline:** 2026-05-22 → 2026-05-24 (3 days, 32 `feat` commits, +31,759/−252 across 194 files)

> Note: the retrospective was not maintained for v1.30–v1.38; this resumes the living log at v1.39.

### What Was Built

Closed the last open step of the canonical SaaS loop — gate features/access on what a customer has paid for — first-party, local-first, fail-closed. The headline JTBD shipped with **no new tables and no Stripe dependency** on the core gate path: a `NimbleOptions`-validated plan→feature/quota config, four fail-closed `Accrue.*` gate functions over local subscription state, a shared `Accrue.Entitlements.Guard` engine feeding a Plug guard + cond-compiled LiveView `on_mount` guard, a provider-honest Resolver + capability matrix, a lifecycle→entitlement truth-table SSOT (closing the paused fail-OPEN gap), a read-only admin entitlements tab, the `guides/entitlements.md` spine + JTBD ⛔→✅ flip, and an isolated off-by-default Stripe-native advisory-sync overlay.

### What Worked

- **Foundational correctness contracts (fail-closed boolean + lifecycle-predicate reuse) baked into Phase 123 exit criteria** — every downstream surface inherited them; the load-bearing property test asserts through the public `Accrue.*` delegates so it proves wiring + the contract in one pass.
- **Isolating the riskiest slice (Stripe-native sync) last and off-by-default** — the local-first headline value landed in Phases 123–126 before any Stripe-specific work; the isolation invariant is machine-enforced (`verify_entitlement_sync_isolation.sh`), so Phase 127 could never block or regress core value.
- **Merge-blocking static gates for cross-cutting invariants** — runtime-LiveView-free, processor support-matrix drift, and sync isolation are all grep-based CI gates cloned from the same proven pattern, keeping posture honest without runtime cost.
- **In-phase code review caught real BLOCKERs** — each of Phases 124/126/127 surfaced a genuine bug (live resolve-once nil; admin tab crash under `:raise`; reducer unreachable because the Stripe summary object has no top-level `id`) that was fixed and regression-pinned before completion, not deferred.

### What Was Inefficient

- **Nyquist validation left partial on Phases 123–125** — VALIDATION.md scaffolds stayed in `draft` (wave_0 not completed) while goals were otherwise fully verified; closing them retroactively via `/gsd:validate-phase` is now deferred tech debt.
- **The ENT-10 advisory cache shipped with known robustness gaps** — concurrent same-customer delivery raises `Ecto.StaleEntryError` (self-heals via Oban retry but noisy); a DB-level upsert (`on_conflict`) would have been cleaner up front. Tracked in a pending todo.
- **One exported seam (`StripeSync.summary_for_customer/1`) ships inert** — zero consumers until a deferred admin view / `lattice_stripe ≥ 1.2`; intentional but a loose end the audit flagged.

### Patterns Established

- **Telemetry/ledger split for high-frequency decisions** — per-check gate decisions emit telemetry only; only deliberate state changes (advisory sync writes) hit the immutable ledger, and only on-change.
- **Cond-compiled core surface (Sigra 4-pattern) for optional runtime coupling** — the LiveView `on_mount` guard lives in core but behind `Code.ensure_loaded?(Phoenix.LiveView)`, with a static gate exempting only that file.
- **Convergence row in the provider capability matrix** — entitlements is the first "local-identical across all providers" lane, contrasting every prior divergence lane; same-PR SSOT co-update with the drift gate.

### Key Lessons

- Putting the two highest-leverage correctness contracts in the *first* phase's exit criteria is the cheapest way to make an entire feature surface safe-by-construction.
- "Isolated, off-by-default, machine-enforced" is a repeatable recipe for shipping a risky optional dependency without it becoming a critical-path liability.
- A milestone can legitimately close at `tech_debt` (not `passed`) when the DoD is achieved and every open item is documented and non-fail-open — the status communicates "review these follow-ups," not "blocked."

### Cost Observations

- Model mix: not tracked.
- Sessions: 5 phases over ~3 days; phase execution times ranged 1–11 min/plan (per STATE.md velocity notes).
- Notable: the heaviest phase by file-count was 127 (advisory cache schema + reducer + isolation gate); the headline value (123–126) was almost entirely additive over existing billing state.

---

## Milestone: v1.46 — Maintenance & Closure

**Shipped:** 2026-05-30
**Phases:** 3 (151–153) | **Plans:** 8

### What Was Built

- ENT-10 webhook scoping fix: `customer` lookups now strictly scope by `processor_id + processor` to prevent cross-processor ID collisions; `dispatch/4` fallback preserved for legacy `handle/1` test interface.
- Dependency updates across accrue / accrue_admin / accrue_portal.
- All 8 malformed `@since` annotations fixed to canonical `@doc since: "1.3.0"` (dunning.ex ×7, funnel_chart.ex ×1) — eliminating compiler warnings and ExDoc junk text.
- Three Zeros gate fully green: all 13 `verify_*.sh` scripts + mix test/dialyzer/credo/coveralls exit 0 across all three packages.
- `accrue_portal` credo baseline established (`.credo.exs` mirroring accrue_admin).
- `accrue / accrue_admin / accrue_portal` 1.3.0 published to Hex.pm via Release Please.
- Phase 151 VERIFICATION.md synthesized retroactively from committed evidence (Phase 152 Three Zeros gate served as independent corroboration).
- Milestone audit trail closed (all documentation gaps from v1.46-MILESTONE-AUDIT.md resolved by Phase 153).

### What Worked

- The "close the audit gaps with follow-on phases" pattern (152 + 153 added after the original audit) worked cleanly — the audit enumerated the exact gaps, and the closure phases were mechanical.
- Release Please computed the 1.3.0 version automatically from accumulated `feat:` commits — no `Release-As:` trailer needed.
- Three Zeros gate (all 13 verify scripts + test/dialyzer/credo/coveralls) gave a crisp merge gate for the release.
- Retroactive VERIFICATION.md synthesis from committed evidence (D-01 pattern) worked well for a maintenance phase that ran before the formal verification workflow was in place.

### What Was Inefficient

- Phase 151 ran without producing a VERIFICATION.md or updating ROADMAP plan checkboxes — required Phase 153 to close retroactively. The maintenance/triage phase context should have prompted both during execution.
- `@since` annotations were using the wrong version (1.4.0) when 1.3.0 was the target — a review step at the time of annotation would have caught this.
- Several pre-publish blockers (chimeway cancel_signals key, stale asset bundle, host-integration warnings) emerged during the Task 2 pre-publish gate rather than being caught by Three Zeros in Phase 152 — suggests the pre-publish gate should run earlier in the release phase.
- MILESTONES.md v1.46 entry had empty "Plan:" lines (SDK couldn't extract accomplishments) — needed manual editing at close.

### Patterns Established

- `@doc since: "VERSION"` is the canonical ExDoc since-badge form — separate attribute after closing `"""`, before `@spec`. Never embed `@since` inside a heredoc body.
- `accrue_portal` now has a `.credo.exs` baseline mirroring accrue_admin. All three packages are credo --strict green.
- Retroactive VERIFICATION.md synthesis from VALIDATION.md + SUMMARY files + subsequent gate evidence is an acceptable D-01 pattern when a phase completes before formal verification runs.
- Audit-gap closure phases (Phase 152 + 153) are the right vehicle for addressing milestone audit findings — insert them after the original milestone phases, close cleanly, then archive.

### Key Lessons

1. Maintenance phases need the same documentation hygiene as feature phases: VERIFICATION.md, ROADMAP checkbox updates, and REQUIREMENTS traceability should be done at phase completion, not retroactively.
2. Version numbers in doc annotations should match the current release target — a `@doc since:` with the wrong version is worse than no badge (it silently ships wrong metadata to HexDocs).
3. Pre-publish CI gates (--warnings-as-errors, host-integration) should run as early as possible in the release phase, not only at the final gate.
4. The audit-gap closure pattern is lightweight and works: enumerate gaps precisely in the audit, close each with a targeted plan, archive.

### Cost Observations

- Model mix: not tracked.
- Sessions: 3 phases over ~2 days; phase execution times 2–25 min/plan (per STATE.md velocity notes).
- Notable: Phase 152-03 (release) was multi-session due to human checkpoint gates (Release Please PR merge + Hex publish confirmation) — these are expected and non-avoidable.

---

## Milestone: v1.47 — ENT-10 Polish + Adopter-Proof Completeness

**Shipped:** 2026-05-31
**Phases:** 5 | **Plans:** 5 | **Tasks:** 11

### What Was Built

- Advisory entitlement cache writes now use a DB-level monotonic upsert guard with stale handling, accurate processor attribution, and livemode carry-forward.
- Stripe entitlement-summary fixtures can model absent `livemode` directly, and default metrics now expose malformed/orphan entitlement-summary webhook signals.
- Fail-closed LiveView entitlement gating for unloaded organization billables, proven through the checked-in example host route.
- Example host metered usage proof now subscribes to the metered plan, clicks the visible LiveView action, and asserts the durable meter event value.
- Base host Oban config wiring is now validated directly for required cron workers and queues, with append-merge guidance anchored at the host crontab callsite.

### What Worked

- Closing the old ENT-10 todo through phases 154 and 155 made the advisory-cache fixes traceable instead of leaving them as code-review residue.
- The adopter-proof phases used the example host as the proof surface, which turned prior "built in core but not demonstrated" concerns into executable host checks.
- The milestone audit caught stale planning artifacts before archive: missing Phase 154 verification recognition, PRF-03 traceability, and queue wording drift.

### What Was Inefficient

- The audit command was not registered in this runtime, so the audit rerun had to be performed inline from the workflow contract and written manually.
- `milestone.complete` did not archive the doubled audit filename convention (`v1.47-v1.47-MILESTONE-AUDIT.md`), requiring a manual move to the milestone archive.
- `STATE.md` still carried stale "Not started" rows after phase completion, so closeout needed another planning hygiene pass.

### Patterns Established

- Treat example-host adopter proof as a closeout requirement for headline JTBDs, not a later documentation nicety.
- Keep required queue sets explicit in requirements, roadmap, host config proof, and adoption matrix so drift is easy to spot.
- Move future-roadmap seeds to `status: backlogged` when they are not active commitments, keeping `audit-open` focused on actual blockers.

### Key Lessons

1. Phase verification should be present before milestone audit, and audit reruns need a reliable CLI entry point.
2. Archive handlers should support the repo's actual audit filename convention or closeout will report false `audit: false`.
3. A clear adoption-proof matrix makes it possible to close old confidence threads with evidence rather than opinion.

### Cost Observations

- Model mix: not tracked.
- Sessions: one concentrated closeout plus prior phase execution sessions.
- Notable: highest-signal checks were targeted Phase 154 entitlement-summary tests, Phase 158 host recovery wiring test, `audit-open`, and `roadmap.analyze`.

---

## Milestone: v1.49 — Realistic Demo App & Adoption Evidence

**Shipped:** 2026-06-02
**Phases:** 4 | **Plans:** 10 | **Tasks:** 10

### What Was Built

- Rich PingPal-style demo data for `examples/accrue_host`, including deterministic hero accounts, realistic background accounts, subscriptions, events, and historical trend data.
- Docker-first local development and evaluation path with optimized dependency/build volume isolation and Docker-aware Phoenix endpoint binding.
- Deterministic Playwright coverage for onboarding, subscription start, upgrade, downgrade, cancellation, payment methods, and metered usage.
- CI enforcement through native Playwright shards, checked-in Docker boot smoke, and mandatory periodic live-Stripe parity.
- Host README Start Here and proof ladder that point adopters from local Docker boot to Fake-backed billing and admin inspection.

### What Worked

- The fresh milestone audit quickly distinguished real implementation gaps from stale planning metadata.
- Keeping the host README claims pinned in shell verifiers prevented the new evaluator path from becoming unenforced prose.
- Splitting native Playwright shards from Docker boot smoke kept CI fast while preserving the Docker DX contract.

### What Was Inefficient

- `REQUIREMENTS.md`, summary frontmatter, `ROADMAP.md`, and `STATE.md` lagged behind verified implementation and needed mechanical cleanup at close.
- The milestone archive handler created roadmap and requirements archives but did not move the audit file, phase directories, or fully collapse the active roadmap.
- Local Docker smoke was blocked by an occupied host port, so final proof relied on Compose config plus the CI smoke contract.

### Patterns Established

- Treat the example host as the adoption-evidence front door: realistic data, browser proof, Docker boot, and documentation all point to the same loop.
- Use `PGHOST=db` as the Docker-specific signal for dev endpoint behavior rather than introducing extra evaluator configuration.
- Keep subscription-mutating browser flows serial while allowing CI-level sharding around the suite.

### Key Lessons

1. Requirement checkboxes and summary frontmatter should be updated during phase verification, not deferred to milestone close.
2. Audit artifacts can become stale within hours; closeout should compare audit timestamps against phase verification timestamps before trusting status.
3. Local Docker smoke should either reserve a non-default port for verification or explicitly rely on CI for clean-host proof.

### Cost Observations

- Model mix: not tracked.
- Sessions: one concentrated closeout session after Phase 166 verification.
- Notable: most closeout time was spent repairing planning metadata, not verifying product behavior.

---

## Milestone: v1.50 — Admin UI Foundation

**Shipped:** 2026-06-02 (merged via PR #32) | **Archived:** 2026-06-03 (retroactive)
**Phases:** 7 (167–173) | **Requirements:** 7/7 (AUI-01..07)

### What Was Built

Raised the already-shipped `accrue_admin` UI to a coherent, distinctly-branded design system: tightened `ax-*` tokens + token-based motion (zero bypasses), self-hosted Geist display/body typefaces with tabular numerals, a uk.gov-style task-launcher home with regrouped nav and always-on Cmd-K, cross-screen "Related billing" threading (no dead ends), shared `<.detail_section>` components across the 6 large detail screens, enriched seeds + rebuilt component kitchen, and a 10-dimension rubric audit with desktop/mobile/dark screenshots + automated axe a11y.

### What Worked

- Foundation-first sequencing (tokens → typography → IA → threading → shared components → seeds → rubric audit) meant later phases inherited a stable substrate.
- A design source held outside `.planning/` (`~/.claude/plans/heres-what-we-were-majestic-spindle.md`) kept the milestone's intent legible across an autonomous multi-phase run.
- The screenshot + axe harness (`accrue_admin/e2e/`) gave objective, re-runnable visual/a11y evidence in lieu of manual review.

### What Was Inefficient

- v1.50 ran on a feature branch with per-phase planning trees never committed to `main`, and the GSD state was reconciled in a separate hygiene session rather than at merge. The formal milestone audit/archive then had to be produced **retroactively** (2026-06-03), and `gsd-sdk milestone.complete` was unusable because STATE had already advanced to v1.51 — archival had to be done by hand.
- Restoring main CI to green after merge required peeling several pre-existing, non-v1.50 gate layers (seed idempotency under `Code.require_file`, LiveView-sandbox E2E enrollment, advisory OTP-28 forward-compat, an upstream Oban deprecation annotation).

### Patterns Established

- **Archive at merge, not later.** Run `/gsd-complete-milestone` (or its manual equivalent) before opening the next milestone, while STATE still points at the milestone being closed — otherwise archival must be reconstructed by hand.
- **Custom `ax-*` CSS + design tokens** is the locked admin CSS architecture (Tailwind configured but inert); carried forward into v1.51 as an explicit non-decision.

### Key Lessons

- Building on a feature branch is fine, but the planning trees + a milestone tag should land on `main` at merge so the historical record isn't lossy (v1.50's phase SUMMARY/VERIFICATION trees are not recoverable on `main`).
- A demand-driven "stable core" project still benefits from completing the bookkeeping ritual promptly — deferring it compounds into manual reconstruction.

### Cost Observations

- Model mix: not tracked.
- Sessions: built autonomously across the v1.50 branch; merged + CI-repaired in a hygiene session; archived retroactively alongside opening v1.51.
- Notable: the retroactive archive was cheap because the design source and PR history were intact — the lesson is to not rely on that.

---

## Milestone: v1.51 — Admin UI: Depth Pass

**Shipped:** 2026-06-04
**Phases:** 6 (174–179) | **Plans:** 33

*(Section added retroactively 2026-06-14 — the v1.51 close archived ROADMAP/REQUIREMENTS but skipped the MILESTONES.md and RETROSPECTIVE.md entries.)*

### What Was Built

The second, depth-oriented pass on the v1.50 `accrue_admin` foundation: design-system token gap-closure (DSY), persona-driven IA reshape with attention badges + threading (IA), systematic per-screen rubric uplift to a 10-dimension baseline (SCR), restrained token-based motion (MOT), single-click-through seed state coverage (SEED), and a screenshot-driven visual-QA + axe loop (QA). 22/22 requirements.

### What Worked

- The anti-churn rule (every change cites a justification token: a below-bar rubric dimension, a failed persona-job, or an eliminated token bypass) kept a subjective "make it nicer" milestone disciplined and auditable.
- A frozen-screens list (Home, primary nav, global search) prevented re-thrashing already-good surfaces.

### Key Lessons

- A depth/polish milestone needs an explicit admissibility bar for changes, or it never converges. The justification-token rule is reusable.

---

## Milestone: v1.52 — Brand System

**Shipped:** 2026-06-14
**Phases:** 7 (180–186) | **Plans:** 29

### What Was Built

A brand/DX milestone (no billing primitives): a 14-section critical audit of the brand-book seed → ratified `BRAND-DNA.md` + binding logo brief; a reproducible opentype.js Geist-outline SVG harness with 6 automated pre-gate lints; a user-judged logo tournament (16 round-1 candidates × 4 directions → monotonic `TOURNAMENT.md` → locked winner R2-7, a two-tone stepped mark); the full production logo system at `brandbook/logo/` (21 outlined-path, svgo-optimized files); `brandbook/tokens/` with an automated admin `ax-*` parity check + specimens; a committed voice system + ready-to-paste copy for every adopter-facing surface; and a self-contained, file://-openable `brandbook/index.html` passing the quality gate within the ≤2 MB budget. 14/14 requirements.

### What Worked

- **Front-loading the disagreement** into Phase 180 (audit → ratified DNA → binding brief with 4 hard logo constraints) before any pixel was drawn meant the tournament judged against a fixed contract rather than re-litigating taste each round.
- **Automated pre-gate lints** (no-rect-background, 16px legibility, monochrome-derivable, no-subtitle) kept the human in the loop only for genuine aesthetic verdicts — no candidate that violated a hard constraint ever reached the user.
- **Monotonic `TOURNAMENT.md` ledger** — verdicts transcribed verbatim, constraints never re-opened — converged the tournament in 2 rounds (under the 3-round cap).
- **Evidence-gated seed latitude** (Geist + palette as defaults, changes only on a cited contrast/distinctiveness/16px failure) prevented scope-creep into a full rebrand.

### What Was Inefficient

- A coordinate-space bug in 181-06 rendered candidates near-blank; the first instinct was to *tune the legibility threshold* (3.0 → 1.75) to explain "thin marks" rather than look at the renders. The fix was a blank-render guard + reverting the threshold. **Lesson: visually inspect renders before tuning thresholds.**
- Two derivative-sheet defects (SVGO dropping a tiny outlined glyph; subtitle viewBox clipping) only surfaced at the Phase 183 eyeball checkpoint — caught, but late.
- Harness `node_modules` (~375M) accumulated untracked under `brandbook/logo/` and `brandbook/tokens/` without a gitignore rule.

### Patterns Established

- **Tournament-to-lock with a monotonic ledger** for any subjective single-winner selection (logo, naming, layout): pre-gate-lint → divergent gallery → user picks → convergent refinement rounds → explicit settle-or-extend cap.
- **Brand layer documents, never mutates, the app SSOT** — `brandbook/tokens/` mirrors admin `ax-*` via an automated parity check; admin `theme.css` stayed untouched.

### Key Lessons

- For generated visual artifacts, *always view the rendered output* before trusting a numeric quality gate — a green/red threshold is worthless if the renderer is broken.
- Skipping the formal milestone audit is defensible when requirements are 14/14 with all human checkpoints passed and downstream phases transitively confirm upstream gates — but the decision should be recorded (it is, in the MILESTONES.md entry).

### Cost Observations

- Model mix: not tracked (GSD model routing: mechanical agents on Sonnet, planning/verifier on inherited Opus).
- Notable: front-loaded human checkpoints (181 pick, 182 lock, 183/185/186 reviews) meant cheap autonomous execution between gates — the cost was concentrated at the conversational verdict points, not the harness runs.

---

## Milestone: v1.53 — Admin UI Design-System Hardening

**Shipped:** 2026-06-20
**Phases:** 6 (187–192) | **Plans:** 39

### What Was Built

A quality / interaction-correctness / design-system hardening pass on the already-shipped `accrue_admin` operator UI (no billing primitives, no breaking API/route changes, no Tailwind migration). A fractal audit (foundations → primitives → groups → pages → flows) produced a refreshed 12-dimension rubric and a 21,276-cell scored baseline + 800-row AX187 defect ledger (187); foundations were hardened to one styling SSOT with composed `ax-*` typography bundles, a tokenized z-index/layer scale, motion-token closure, and contrast-correct dark-mode roles (188); every primitive/form component was systematized in a registry-driven `/dev/components` state-matrix gallery (14 families, 8 new primitives) with component-root token fixes (189); recurring component *groups* were audited as units from a canonical group-contract registry (190); the Phase-187 behavioral interaction defects were fixed with a package-local FocusTrap + regression coverage, LiveView disconnected-state handling, an on-brand microcopy pass, and idempotent one-click seed reachability (191); and the whole thing was locked behind an idempotent only-forward scorecard ≥ baseline (zero regressions), merge-blocking CI guardrails, and maintainer sign-off (192). 33/33 requirements.

### What Worked

- **The only-forward baseline as a contract.** Phase 187's structured artifacts (`baseline.cells.json` 21,276 cells, `defects.ndjson` 800 rows with owner-phase routing) made every later phase's job concrete and made Phase 192's "≥ baseline, zero regressions" a mechanical check rather than a judgment call.
- **Fractal ordering (foundations → primitives → groups → pages → flows)** meant root-level fixes propagated: token/role fixes in 188–189 removed whole classes of defects downstream instead of per-page patching.
- **Catching what screenshots can't see.** Live interaction probes + a package-local FocusTrap with regression tests caught and locked the behavioral defects (modal-behind-scrim, scroll traps, post-LiveView-patch focus loss, overlay z-index) that v1.51's LLM-scored stills were blind to — directly discharging v1.51's photographic-sign-off tech-debt.
- **Shift-left on human gates.** Phase 190 converted its UAT to deterministic Playwright/bash gates (0 human steps); deterministic guardrails wired merge-blocking into CI.

### What Was Inefficient

- **The CSS bundle gotcha bit again.** The admin serves a committed Tailwind-built `priv/static/accrue_admin.css`, not source `app.css` — Phase 189 shipped dead CSS fixes until the rebuild step was understood (recorded in memory). Repeated friction across the admin-UI arc.
- **A disabled-specimen `pointer-events:none` interaction** caused the Phase-187 baseline e2e to hang >300s (unbounded `hover()`), needing a `/gsd-debug` session — a foreseeable consequence of adding disabled specimens without bounding actionability waits.
- **Documentation/traceability drift.** Phases 188 and 192 reached final evidence without writing their `VERIFICATION.md` files, REQUIREMENTS.md checkboxes lagged the sign-off, and 192-VALIDATION.md stayed `draft` — the milestone audit landed `gaps_found` on pure bookkeeping, all closed inline at milestone close. The implementation was done; the GSD artifacts hadn't caught up.

### Patterns Established

- **Idempotent only-forward verification:** a structured, re-runnable baseline + a scorecard reducer that fails closed on any score/coverage downgrade, so re-running the milestone only ever surfaces *new* gaps.
- **Component-root-only fixes (D-14)** with lockstep registry/schema updates (D-08) and a frozen cell-id grammar (D-12) — a discipline that keeps a component lab honest.
- **Test-only fixture endpoints in `test/support` E2E plug routes** (never production router/auth) for one-click matrix-cell reachability.

### Key Lessons

- **Write the VERIFICATION.md when the phase's evidence is green, not at milestone close.** Phase-boundary artifacts are cheap in the moment and expensive to reconstruct under an audit. The audit gate is only as trustworthy as the artifacts it reads.
- **Structured artifacts beat prose for "is it done?"** — `regressions.ndjson` with 0 rows is a far stronger close signal than any narrative, and it's what made the milestone audit's `gaps_found` obviously about bookkeeping rather than substance.
- **Re-litigated CSS-pipeline friction is a signal to encode the build step into the workflow,** not to keep paying the tax each phase.

### Cost Observations

- Model mix: not tracked (GSD routing: mechanical agents on Sonnet, planning/verifier/researcher on inherited Opus).
- Notable: the heaviest artifacts (21,276-cell matrices, 800-row ledgers) are generated, not authored — cost concentrated in harness/verifier authoring (187, 192) and the interaction-defect remediation (191), with cheap autonomous execution between deterministic gates.

---

## Milestone: v1.54 — Admin UI Page-Level Streamlining & Storybook

**Shipped:** 2026-07-01  
**Phases:** 8 (193–200) | **Plans:** 59 | **Tasks:** 97

### What Was Built

A page-level excellence pass on the already-shipped `accrue_admin` operator UI. The milestone locked the three archetype specs, extended v1.53's forward-only baseline to page-flow cells, adopted PhoenixStorybook dev/test-only, built gold-standard Dashboard/Subscription-detail/Subscriptions-list exemplars, propagated LIST and DETAIL/analytics patterns across the surface, hardened every overlay/focus/scroll/floating behavior, stress-tested deterministic multi-step and edge fixtures, swept page-level microcopy, and closed with a 30,348-cell zero-regression Phase 200 sign-off.

### What Worked

- **Exemplar-first propagation.** Locking one overview, one detail, and one list page before broad propagation kept later work coherent and reduced subjective redesign churn.
- **One canonical overlay primitive.** Routing drawers/modals through one primitive turned repeated modal-behind-scrim, scroll-lock, focus, and geometry bugs into a single contract with browser and source tests.
- **Storybook as a dev/test design lab.** The dependency stayed out of adopter runtime while giving components and groups a rendered state matrix beyond the in-app kitchen.
- **Forward-only verification scaled.** The union baseline and strict manifest-bound scorecard made page-level quality measurable without adopting pixel-diff tooling.

### What Was Inefficient

- The generated milestone accomplishment extraction was noisy and needed editorial replacement at close.
- Several closeout fixes were bookkeeping or copy-contract alignment discovered by the milestone audit rather than caught immediately at phase boundary.
- Heavy generated evidence artifacts are useful but large; they make archiving essential to keep active planning context manageable.

### Patterns Established

- Pattern specs → exemplar → propagation is now the preferred shape for broad UI quality passes.
- PhoenixStorybook is acceptable only as dev/test-only tooling with a guarded sibling-scope mount and host compile proof.
- Page-flow cells are first-class verification surfaces alongside component and group cells.
- Open-artifact carryover should be acknowledged explicitly in STATE.md at milestone close.

### Key Lessons

1. Keep SUMMARY one-liners written for humans; automation that harvests raw deviations produces poor milestone entries.
2. Page-level UI quality needs rendered route checks, not only component isolation or screenshots.
3. If a TODO is satisfied by milestone work, close or annotate the TODO immediately so the next closeout audit does not rediscover it.
4. Archiving phase trees is mandatory once generated evidence reaches hundreds of thousands of lines.

### Cost Observations

- Model mix: not tracked.
- Sessions: one long admin-UI milestone with audit closeout.
- Notable: Phase 200 evidence generation and browser/page-flow gates dominated artifact size and closeout time.

---

## Milestone: v1.55 - OSS Quality Evaluation & Hardening Roadmap

**Shipped:** 2026-07-03  
**Phases:** 4 (201-204) | **Plans:** 4 | **Tasks:** 9

### What Was Built

An audit-only maintenance milestone for release-readiness and support-contract hardening. Phase 201 produced an evidence-backed software-quality audit across adoption, production, maintenance, support, UI, release, upgrade, architecture, data, security, OSS trust, and Accrue-specific dimensions. Phase 202 produced a static-first CI/CD performance and determinism audit with explicit metrics-needed gaps. Phase 203 accepted the DB schema-contract ADR: keep `billing` as the default dedicated Postgres schema, preserve explicit `public`, and defer rename/data-movement work. Phase 204 ranked the top 10 follow-up hardening items into milestone-sized slices with impact, effort, risk reduction, done criteria, metrics needed, and non-goals.

### What Worked

- **Audit-only boundary stayed clean.** The milestone identified risk and ranked implementation work without changing runtime behavior, API surface, DB defaults, CI topology, or release automation.
- **Parallel evidence gathering paid off.** Phases 201, 202, and 203 could run independently, then Phase 204 integrated their findings into one ordered roadmap.
- **3-source requirement verification was useful.** REQUIREMENTS.md, VERIFICATION.md, and SUMMARY frontmatter now agree on all 18 requirements.
- **Open-artifact cleanup reduced future noise.** Stale quick-task and pending-todo metadata were resolved before archive, so `audit-open` is clean.

### What Was Inefficient

- Validation metadata lagged behind completed phase evidence for 201-203 and had to be normalized during milestone audit closeout.
- The generated MILESTONES entry omitted the Phase 204 accomplishment and needed editorial cleanup.
- The archive command moved core artifacts but left current planning prose describing v1.55 as active, requiring manual ROADMAP/PROJECT/STATE cleanup.

### Patterns Established

- Use audit-only milestones when the next implementation sequence is unclear; produce ranked slices before opening hardening work.
- Separate static CI evidence from run-history metrics that must be collected later, especially before cache, gate, topology, or branch-protection changes.
- Treat schema-prefix posture as a contract: default `billing`, explicit `public`, qualified migration helpers, no `search_path` reliance, and no rename/data movement without a dedicated future milestone.

### Key Lessons

1. A maintenance milestone can be valuable without code changes if it leaves behind a ranked, evidence-backed implementation roadmap.
2. Validation frontmatter should be refreshed immediately after verification, not only when the milestone audit complains.
3. Closeout must include artifact-audit cleanup; stale TODOs and quick-task metadata otherwise keep resurfacing as false blockers.
4. Archive tooling still needs a human editorial pass for current-state language and milestone accomplishments.

### Cost Observations

- Model mix: not tracked.
- Sessions: short audit/roadmap chain plus closeout cleanup.
- Notable: the highest-signal checks were the milestone integration audit, the 3-source requirements extraction, and the `audit-open` cleanup gate.

---

## Milestone: v1.57 — Admin Operator Control Plane (SEED-004 M1)

**Shipped:** 2026-07-30  
**Phases:** 3 (209-211) | **Plans:** 10 | **Tasks:** 19

### What Was Built

The first slice (M1) of the SEED-004 redesign of `accrue_admin` from a CRUD surface into an "operator control plane over billing state." Phase 209 reigned the Subscriptions list onto the canonical PageHeader/StatStrip/DataTable spine — one StatusBadge verdict, one primary CTA, a 4-stat StatStrip, compact cell idiom, zero bespoke worklist bands or in-cell buttons — resolving COMP-01 inline (no new component). Phase 210 recomposed Home onto `PageHeader` with a single verdict, one discoverable customer-search control, a primitive-built attention rail + EmptyState and launcher grid, and certified answer-first IA + plain-language `AccrueAdmin.Copy` strings + real-parent breadcrumbs across both pages (axe-clean, no density regression). Phase 211 grep-gated the retirement of 97 dead bespoke `.ax-*` selectors (detail-shared classes preserved), rebuilt both generated artifacts, recomposed storybook, and fixed the parked ratchet's dangling selector — full unit (514/0) + e2e (200/0) + storybook suites green.

### What Worked

- **Answer-first IA reign delivered directly, not via the ratchet.** The v1.56 ratchet had stalled non-converging on IA findings; treating those 23 round-99 findings as an explicit M1 acceptance checklist and reigning the two outlier pages by hand converged where the automated loop could not.
- **Sequencing the CSS retirement last (Phase 211) after both templates landed** made blind prefix-deletion safe — the grep-gate + orphan-guard census proved zero live-class over-deletion, and detail-page-shared classes were preserved.
- **The new deterministic Playwright pixel-diff gate closed UAT with zero human checkpoints.** The two former human-only visual checkpoints were replaced by a `toHaveScreenshot` gate (4 surfaces × light/dark), making the visual-regression posture reproducible in CI.
- **Compose-don't-fork discipline held.** COMP-01's one-new-component budget went unspent — the callout shape did not demonstrably repeat, so both pages composed from `.ax-card` directly.

### What Was Inefficient

- **Phase 211 execution shipped as 11 unpushed local-main commits** while origin/main had only the plans — a real origin/local skew that had to be caught and reconciled (CI-validated via PR #36) before the milestone could close cleanly.
- **VERIFICATION.md for Phase 211 was written retroactively during the milestone audit** (the recurring "write VERIFICATION when green, not at close" gotcha); substance was already covered by 211-UAT.md + approved 211-VALIDATION.md, but the artifact lagged.
- **210 SUMMARY frontmatter under-tagged `requirements_completed`** — traceability was sound via 210-VERIFICATION.md per-criterion evidence, but the frontmatter tags were incomplete.
- **Validation metadata was uneven across phases** (209 draft, 210 absent, 211 approved) — a coverage TODO the inactive Nyquist hook did not gate.

### Patterns Established

- **A deterministic pixel-diff gate can retire human visual checkpoints** for an admin surface once masks/baselines are minted (see `reference_admin_visual_regression_gate`).
- **For IA/grammar reigns, drive from a confirmed-findings checklist** (the ratchet's round-99 output) rather than looping the automated evaluator; the harness re-freezes the result afterward, it doesn't converge the redesign itself.
- **Grep-gated CSS retirement + an orphan/dangling census guard** is the safe pattern for deleting shared bespoke class families that source-text CI can't see.

### Key Lessons

1. When an automated evaluation loop stops converging, that non-convergence is itself signal — here it correctly identified that the work was a human IA redesign, not more ratchet rounds.
2. Push execution commits promptly: an 11-commit local-main skew silently left origin describing plans while the actual CSS retirement sat undeployed.
3. Write VERIFICATION.md at the moment a phase goes green, not at milestone close — the retroactive write is pure rework and risks under-capturing evidence.
4. Replacing human visual checkpoints with a deterministic gate is worth the setup cost: v1.57 closed UAT with 0 human steps and a reproducible CI guard.

### Cost Observations

- Model mix: GSD model routing in effect (high-volume mechanical agents on Sonnet, planning/verifier on inherit).
- Sessions: multi-session over 2026-07-19 → 2026-07-30, including a mid-flight main-skew reconciliation and the automated visual-gate build (quick-260729-rjo).
- Notable: the highest-signal steps were the round-99 findings checklist, the grep-gate/orphan-guard census, and the deterministic pixel-diff gate that eliminated human UAT.

---

## Milestone: v1.58 — lattice_stripe 2.x Bump & Stripe-Native Entitlements Sync

**Shipped:** 2026-07-31
**Phases:** 5 | **Plans:** 17 | **Tasks:** 33

### What Was Built

- Upgraded all resolving packages to `lattice_stripe ~> 2.0` with four aligned lockfiles and green package-specific quality gates.
- Added a default-off client-backed Stripe entitlement refresh, optional processor callback, shared pull/webhook reconciliation, deterministic ordering, and a host-owned worker.
- Proved advisory data cannot influence grants, then surfaced it separately through core diagnostics and the existing admin customer detail.
- Reconciled public/support/release/planning truth, including writer provenance, pagination semantics, `@since` metadata, and Release Please candidate handling.

### What Worked

- The static isolation gate plus contradictory-cache runtime tests made the observational-only boundary falsifiable instead of relying on architecture prose.
- Fake/local transport seams kept processor, reconciliation, and browser verification deterministic and credential-free.
- Independent milestone audits found two real integration/documentation gaps; decimal closure phases fixed both without diluting canonical requirement ownership.
- Executable desktop/mobile/accessibility UAT removed the final human-only closeout ambiguity.

### What Was Inefficient

- Initial completion metadata omitted Phase 214.2 and duplicated the audit filename prefix, so the archive dry run would have silently left out a verified closure phase and the audit.
- Nonstandard summary frontmatter caused the archive tool to undercount tasks (19 detected versus 33 recorded in phase metrics) and extract deviation headings as accomplishments.
- Documentation truth required two closure phases because writer provenance and pull/webhook completeness were not tested together early enough.

### Patterns Established

- Archive commands must be dry-run and checked for exact phase-directory and audit-file membership before mutation.
- Advisory provider data should flow through one reconciler, one diagnostic projection, and an explicit static/runtime non-authority boundary.
- Closure phases may supplement evidence for an existing requirement, but canonical traceability ownership remains singular.

### Key Lessons

1. Put production-doc claims under negative-fixture tests at the same time as the behavior they describe, especially writer provenance and completeness semantics.
2. Normalize summary metadata (`one-liner`, task count) before closeout so automatic milestone rollups remain trustworthy.
3. Treat phase scope discovered by the archive tool as an assertion to verify, not an implementation detail.

### Cost Observations

- Model mix and session count were not reliably recorded for this milestone.
- The main avoidable cost was audit-driven documentation and diagnostic closure, not the dependency bump itself.

---

## Milestone: v1.59 — Account-Scoped Multi-Rail & Offline Entitlements

**Shipped:** 2026-08-05
**Phases:** 8 (215-222) | **Plans:** 77 | **Tasks:** 135

### What Was Built

- Concurrent Stripe and Apple rail configuration, qualified durable entitlement records, and a survivor-safe revisioned account projection.
- Strict Apple notification/intake/reconciliation, reference-host ingress, and provider-honest lifecycle guidance.
- Device-bound ES256 offline proofs with stale-study continuity, authenticated reconnect, signed deny replacement, and scheduled recovery.
- Deterministic first-adopter scenarios, operator diagnostics/repairs/runbooks, and release-contract gates.

### What Worked

- The decision corpus kept projection, offline verification, fixtures, and support language aligned without becoming a second runtime reducer.
- Audit-driven closure phases isolated the two genuine host-composition gaps: Apple ingress and stranded reconnect recovery.
- Credential-free host integration proof caught boundary issues that core-only tests could not.

### What Was Inefficient

- The first audit occurred before the final closure phase, requiring a rerun to distinguish stale findings from remaining gaps.
- Summary metadata produced noisy archive accomplishments and undercounted tasks, requiring manual milestone statistics.
- Several resolved debugging and external-smoke items stayed open in planning state until closeout.

### Patterns Established

- Every provider-facing feature needs a host route/scheduler composition test in the release lane.
- Keep external-provider delivery smoke tests advisory and privacy-bounded; deterministic fake-backed tests remain merge authority.
- Treat `feasibility_blocked` as a successful prove-or-block result, never as runtime readiness.

### Key Lessons

1. Run the milestone audit after every closure phase, not merely after the nominal final phase.
2. Keep `VALIDATION.md`, `SUMMARY.md`, and requirement traceability synchronized while executing, not during archive preparation.
3. A dedicated host scheduling proof is required for durable recovery claims; worker implementation alone is insufficient.

### Cost Observations

- Model mix: not reliably recorded.
- Sessions: multi-session implementation, audit, closure, and archive cycle across 2026-07-31 to 2026-08-05.
- Notable: the largest avoidable cost was audit-driven host wiring closure; focused host proofs then made confirmation fast and deterministic.

---

## Milestone: v1.60 — First-Adopter iOS Bridge & Proof (Override Closeout)

**Closed:** 2026-08-08
**Delivered phases:** 2 (223–224) | **Plans:** 14 | **Tasks:** 13

### What Was Built

- An iOS-compatible SwiftPM offline client with canonical ES256 proof verification, authenticated cache replacement, and bounded failure handling.
- A route- and manifest-scoped Crosswake host-command seam with exact-revision, denial, replay, and route-epoch evidence.

### What Worked

- The phase verification records separated reusable package and bridge evidence from unproven device-runtime capability.
- Archiving phase directories retained the complete execution record while keeping active planning space clear.

### What Was Inefficient

- ROADMAP and REQUIREMENTS status drifted behind completed Phase 224 evidence, requiring reconciliation during closeout.
- The generated archive initially labeled an override closeout as shipped and needed an explicit editorial correction.

### Key Lessons

1. Keep requirement traceability synchronized with phase verification before running closeout.
2. A verified host seam is not equivalent to StoreKit integration or physical-device proof; preserve that boundary in every public summary.
3. Use an override closeout only when deferred scope is named precisely and re-entry requires fresh authorization.

### Cost Observations

- Model mix and session count: not tracked.
- Notable: the closeout was documentation/archive work; no unverified runtime claim was promoted.

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Sessions | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.59 | multi (2026-07-31→08-05) | 8 | **MULTI-RAIL/OFFLINE** — concurrent Stripe/Apple account projection, strict Apple intake/repair, device-bound offline proof/recovery, and first-adopter release proof. Audit `tech_debt`: 29/29 requirements, 11/11 integrations, 5/5 flows, and Nyquist validation passed; Crosswake runtime remains intentionally feasibility-blocked. |
| v1.58 | multi (2026-07-30→07-31) | 5 | **BUMP/SYNC/DOCS** — moved all packages to `lattice_stripe ~> 2.0`, shipped client-backed advisory entitlements with static/runtime grant isolation, surfaced diagnostics in the existing admin detail, and closed writer/pagination truth through two audit-driven decimal phases. Audit `tech_debt`: 11/11 requirements and 5/5 flows pass. |
| v1.57 | multi (2026-07-19→07-30) | 3 | **REIGN/IA/COPY/COMP** — SEED-004 M1: reigned the two outlier admin pages (Home + Subscriptions) onto the shared operator-first component vocabulary + answer-first IA, retired 97 dead bespoke `.ax-*` selectors (grep-gated), and closed UAT with **0 human checkpoints** via a new deterministic Playwright `toHaveScreenshot` pixel-diff gate. Reopen class: explicit strategy change. Non-convergence of the parked v1.56 ratchet on IA findings was the trigger. Audit `passed`; phases **209–211** under **`milestones/v1.57-phases/`**; archives **`milestones/v1.57-*`**. |
| v1.55 | short | 4 | **QLT/CI/DB/RD** - audit-only maintenance milestone: evidence-backed software-quality audit, static-first CI/CD audit, accepted DB schema-contract ADR, and ranked top-10 hardening roadmap. Audit `passed`; phases archived under **`milestones/v1.55-phases/`**; archives **`milestones/v1.55-*`**. |
| v1.54 | long | 8 | **RES/STY/EXE/PGH/PRP/IXN/FIX/CPY/VER** — page-level admin streamlining: archetype specs → gold-standard exemplars → LIST/DETAIL propagation, canonical overlay primitive, PhoenixStorybook dev/test-only, deterministic fixture stress, and a 30,348-cell zero-regression Phase 200 sign-off. Audit `passed`; phases archived under **`milestones/v1.54-phases/`**; archives **`milestones/v1.54-*`**. |
| v1.53 | short | 6 | **VER/FND/CMP/GRP/IXN/PAGE/CPY/SEED** — fractal admin design-system hardening (foundations→primitives→groups→pages→flows): 12-dimension rubric + 21,276-cell only-forward baseline + 800-row AX187 ledger; package-local FocusTrap + regression coverage for behavioral defects screenshots miss; idempotent scorecard ≥ baseline (0 regressions) + merge-blocking CI guardrails; maintainer sign-off discharged v1.51 photographic-sign-off tech-debt. Audit `gaps_found` (doc/traceability only) closed inline at close. Phases **187–192** under **`.planning/phases/`**; archives **`milestones/v1.53-*`**. |
| v1.29 | short | 3 | **MG-01..MG-07** — Mailglass framework integration replacing `mjml_eex` + `phoenix_swoosh`; explicit `Mailglass.deliver/1` `idempotency_key` replaces Oban `unique: [period: 60]`; `/dev/mail` LiveView replaces `mix accrue.mail.preview`; 13 templates ported, 26 MJML/text assets deleted; `mailglass_cleanup_test` enforces non-regression in CI; phases **88–90** under **`milestones/v1.29-phases/`**; archives **`milestones/v1.29-*`**. |
| v1.46 | ~2 days | 3 | **MNT-01** — maintenance release: ENT-10 dual-column webhook scope fix, dep updates, @since annotation cleanup, credo wired in accrue_portal, Three Zeros gate green across all 3 packages, 1.3.0 Hex publish. Audit-gap closure phases (152+153) added retroactively to close VERIFICATION.md + REQUIREMENTS gaps. |
| v1.47 | short | 5 | **ADV/POL/PRF** — closed ENT-10 advisory-cache correctness and polish, then made entitlements gating, metered usage, and Oban recovery wiring executable in `examples/accrue_host`; closed old adopter-proof thread and moved SEED-002 to future-roadmap backlog. |
| v1.39 | ~3 days | 5 | **ENT-01..12** — closed the canonical SaaS loop's last step (entitlements/plan-gating), local-first with no new tables / no Stripe dependency on the gate path. Correctness contracts (fail-closed + lifecycle-predicate reuse) baked into the first phase's exit criteria; risky Stripe-native sync isolated last + off-by-default behind a machine-enforced isolation gate; three new merge-blocking static gates (runtime-LiveView-free, support-matrix drift, sync isolation). Closed at `tech_debt` (DoD achieved, deferred non-fail-open follow-ups + partial Nyquist 123–125). Phases **123–127** under **`milestones/v1.39-*`**. |
| v1.27 | short | 2 | **CLS-01..03** + **INV-05** — pre-1.0 closure narrative on README / **`RELEASING`** / **`upgrade`** + post-touch friction certification **(b)**; **`*-VERIFICATION.md`** only (inline); phases **84–85** under **`milestones/v1.27-phases/`**; **`milestones/v1.27-*`** archives. |
| v1.26 | short | 2 | **INT-13** + **INV-04** — billing portal on First Hour + matrix + CI needles; post-touch friction certification **(b)**; **`*-VERIFICATION.md`** + **3** plan summaries; phases **82–83** under **`milestones/v1.26-phases/`**. |
| v1.25 | short | 3 | **INV-03** + **BIL-06..07** + **INT-12** — checkout **`Accrue.Billing`** facade + telemetry/docs + integrator verifiers; **`*-VERIFICATION.md`** + **3** plan summaries; phases **79–81** under **`milestones/v1.25-phases/`**. |
| v1.24 | short | 3 | **ADM-13..16** + **BIL-04..05** — billing portal facade + customer **PM** VERIFY/copy/theme; **`*-VERIFICATION.md`** + **6** plan summaries; phases **76–78** under **`milestones/v1.24-phases/`**. |
| v1.23 | short | 1 | **PPX-01..04** — **`docs-contracts-shift-left`** + friction script + **`v1.17-P1-002`** closure (**75-VERIFICATION**); phase under **`v1.23-phases/`**. |
| v1.22 | short | 1 | **PRS-01..03** — root + package README links; **`verify_production_readiness_discoverability.sh`** in shift-left; **`scripts/ci/README.md`** gate map (**74-VERIFICATION**); phase under **`v1.22-phases/`**. |
| v1.21 | short | 2 | **PROJECT** + **`maturity-and-maintenance.md`** maintenance bar (**72-VERIFICATION**); **`scripts/ci/README.md`** capsule parity checklist + **v1.17-P2-001** closure (**73-VERIFICATION**); phases under **`v1.21-phases/`**. |
| v1.20 | short | 2 | Friction inventory evidence refresh (**70-VERIFICATION**); **production-readiness** guide + integrator cross-links (**71-VERIFICATION**); phases moved to **`v1.20-phases/`**. |
| v1.19 | short | 3 | Proof needles + README triage (**67-01**); **RELEASING** + **68-VERIFICATION** Hex/tag evidence (**68-01..02**); doc verifier + planning mirrors (**69-01..02**). |
| v1.18 | short | 1 | Verification ledger for deferred **62-UAT** baseline (**66-01**); STATE + friction script archive gate (**66-02**); PROOF-01 matrix/script/README alignment + requirements close (**66-03**). |
| v1.17 | short | 4 | Friction inventory + north star + FRG-03 anchors (62); INT-10 README + host-integration slugs + integrator closure (63); BIL-03 empty-queue certification (64); ADM-12 empty-queue certification (65). |
| v1.16 | short | 3 | Golden path + quickstart + CONTRIBUTING coherence (59); matrix/walkthrough + CI README INT map (60); README VERIFY pin + Hex/`main` SSOT in planning + CONTRIBUTING (61). |
| v1.15 | single | 2 | Trust docs: upgrade + RELEASING + root README (57); demo Sigra vs Auth + package stability + verifier alignment (58). |
| v1.14 | short | 3 | Core-admin parity matrix + invoice Copy burn-down (54), VERIFY-01 invoice anchors + theme/copy CI (55), `list_payment_methods` + telemetry/docs (56). |
| v1.13 | short | 3 | Integrator spine + VERIFY-01 discoverability (51), proof matrix + package docs + coupon/promo Copy (52), Connect/events Copy + auxiliary VERIFY-01 + export allowlist (53). |
| v1.12 | short | 3 | Post-metering admin KPI (48), subscription drill + README nav honesty (49), Copy.Subscription + theme register + export_copy_strings VERIFY-01 wiring (50). |
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
| v1.59 | 8/8 phase verifications; reference-host Apple ingress/recovery, deterministic scenarios, and release-contract gates. | 29/29 requirements; 11/11 integrations; 5/5 flows; all phases Nyquist-compliant. | No required dependency addition; Apple/Crosswake remain bounded host/runtime evidence lanes. |
| v1.58 | Five phase verifications (63/63 combined must-haves), isolation verifier, package-doc verifier, 81 focused core tests, 37 focused admin/LiveView tests, and executable desktop/Pixel 5 browser UAT. | 11/11 requirements; 10/11 integrations; 5/5 flows | No new required dependency; existing `lattice_stripe` pin advanced to `~> 2.0`. Advisory sync remains default-off and non-authoritative. |
| v1.57 | Full `accrue_admin` unit suite 514/0 + e2e 200/0 + storybook gate green with zero regressions; new deterministic Playwright `toHaveScreenshot` pixel-diff gate (4 admin surfaces × light/dark) blocking in browser-uat; grep-gate + orphan/dangling `ax-*` census guard proving 97 selectors retired with zero live-class over-deletion. Milestone audit `passed` (11/11 reqs, 3/3 phases, 5/5 integration, 5/5 flows). | 11/11 requirements archived | No dependency changes; admin-only CSS/template reign (no core `accrue` change, no new nav rooms, no Tailwind migration); both generated artifacts (`accrue_admin.css`, `copy_strings.json`) rebuilt in-repo. |
| v1.55 | Milestone audit passed with 4/4 phase verifications, 18/18 requirements clean by REQUIREMENTS/VERIFICATION/SUMMARY extraction, 8/8 integration checks, 6/6 audit-only flows, zero blockers, and Nyquist-compliant validation metadata. | 18/18 requirements archived | No runtime/package dependency changes; audit-only roadmap and ADR artifacts. |
| v1.54 | Phase 200 union scorecard verifier (30,348 cells, 0 regressions), Storybook coverage/theming checks, axe/no-FOUC/reduced-motion browser guardrails, overlay/floating/focus lifecycle tests, and centralized LIST copy contract alignment | 23/23 requirements archived | PhoenixStorybook dev/test-only in `accrue_admin`; no adopter runtime dependency, no core `accrue` LiveView runtime leak. |
| v1.29 | New `mailglass_cleanup_test` (5 regression-guard assertions), `email_preview_live_test` fixture sweep (renders every type via admin LiveView), `mailglass_admin_routes/__routes__/0` ExUnit assertion in `accrue_admin`; 128 email tests pass post-cleanup | MG-01..MG-07 (7/7) archived | **Net dep removal:** `mjml_eex` + `phoenix_swoosh` removed from `accrue/mix.exs`; new `:mailglass` path dep replaces them. `accrue/priv/repo/migrations/20260426000000_create_mailglass_poc_tables.exs` for host bootstrap. |
| v1.26 | Extended **`verify_package_docs.sh`** + **`verify_adoption_proof_matrix.sh`** substring gates; no new ExUnit facade (portal facade shipped **v1.24**) | INT-13 + INV-04 (2/2) archived | Doc + CI needles only; **`milestones/v1.26-*`**; execution trees **`v1.26-phases/`**. |
| v1.24 | **`billing_portal_session_facade_test.exs`** + existing **VERIFY-01** / **host-integration** / **`verify_package_docs`** gates | ADM + BIL (6/6) archived | Public **`Accrue.Billing`** portal API; customer **PM** Playwright + **axe** row; **`milestones/v1.24-*`**; phases remain under **`.planning/phases/`**. |
| v1.23 | Existing **`docs-contracts-shift-left`** suite + **`verify_v1_17_friction_research_contract.sh`**; no new CI jobs | PPX (4/4) archived | Friction inventory **P1-002** closure note; **`75-VERIFICATION.md`**; phase tree **`v1.23-phases/75-*/`**. |
| v1.22 | Merge-blocking **`verify_production_readiness_discoverability.sh`** added to **`docs-contracts-shift-left`**; existing doc verifiers unchanged | PRS (3/3) archived | Bash verifier + CI wiring; **`scripts/ci/README.md`** PRS triage rows; phase tree **`v1.22-phases/74-*/`**. |
| v1.21 | Merge-blocking **`verify_package_docs`** / **`verify_v1_17_friction_research_contract.sh`** unchanged; **`*-VERIFICATION.md`** evidence only | MAT + INT-11 (3/3) archived | **`maturity-and-maintenance.md`**; **INT-11** checklist in **`scripts/ci/README.md`**; **v1.17-P2-001** closure note in friction inventory. |
| v1.20 | Merge-blocking doc contracts unchanged; **`*-VERIFICATION.md`** evidence only | INV + PRD (4/4) archived | **`production-readiness.md`** spine; inventory **§ v1.20 evidence refresh**; phase trees under **`milestones/v1.20-phases/`**. |
| v1.19 | **`verify_adoption_proof_matrix.sh`** needles + **`package_docs_verifier_test.exs`**; **`68-VERIFICATION.md`** external URL checks | PRF + REL + DOC + HYG (8/8) archived | **`scripts/ci/README.md`** triage for matrix/script/test co-update; **0.3.1** Hex + tag + changelog-at-tag evidence table. |
| v1.18 | **`v1_17_friction_research_contract_test.exs`**; bash **`verify_v1_17_friction_research_contract.sh`**; **`verify_adoption_proof_matrix.sh`** + **`organization_billing_org09_matrix_test.exs`** | UAT-01..UAT-05 + PROOF-01 (6/6) archived | **`66-VERIFICATION.md`** ledger; **`62-UAT.md`** banner errata; friction SSOT + archive presence gates in shift-left CI. |
| v1.16 | **`package_docs_verifier_test`** extensions; bash **`verify_package_docs`**, **`verify_verify01_readme_contract`**, **`verify_adoption_proof_matrix`** | INT-06..INT-09 (4/4) archived | Quickstart hub + capsule checks in **`verify_package_docs.sh`**; adoption matrix + walkthrough trust stub; root README VERIFY line pin; CI README INT rows; planning Hex mirror discipline. |
| v1.14 | ExUnit on invoice LiveViews; host VERIFY-01 **`core-admin-invoices-*`** + axe; Fake **`payment_method_list_test.exs`** | ADM-07..ADM-11 + BIL-01..BIL-02 (7/7) archived | `core-admin-parity.md`, `Copy.Invoice`, `verify_core_admin_invoice_verify_ids.sh`, billing `list` span + telemetry row. |
| v1.12 | ExUnit on **DashboardLive** + **SubscriptionLive**; host **admin_mount** smoke; VERIFY-01 Playwright + axe using **`e2e/generated/copy_strings.json`** | ADM-01..ADM-06 (6/6) archived | `mix accrue_admin.export_copy_strings`, `Copy.Subscription`, `theme-exceptions.md`, `verify01-v112-admin-paths.md`. |
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
