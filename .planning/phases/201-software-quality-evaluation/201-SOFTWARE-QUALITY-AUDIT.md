# Software Quality Audit: Accrue v1.55

**Date:** 2026-07-01  
**Status:** Phase 201 final audit  
**Scope:** `accrue`, `accrue_admin`, `accrue_portal`, `examples/accrue_host`, public docs, planning mirrors, CI/release posture.

## Executive Summary

**Weakest dimension:** CI/CD efficiency, signal fidelity, and release-lane truth  
**Score:** 3/5  
**Why weakest:** CI is serious and high-signal, but static inspection shows duplicated setup, repeated package gates across matrix cells, phase-specific browser guardrails that overlap, a long critical path, live-Stripe semantics that can appear green while skipping, and compatibility labels that may not prove what they claim.  
**If ignored:** Maintainers lose time, contributors wait longer for feedback, required checks become harder to trust, and release confidence degrades because "green" stops meaning one clear thing.

**Second-weakest:** First-time evaluator clarity and adoption path skimmability. The docs are rich, but there are many front doors and proof maps.  
**Third-weakest:** Public truth / package parity drift, especially toolchain version statements, portal parity, release-note coverage, and Hex/GitHub listing polish.

**Overall quality read:** **production-ready but audit-heavy**. Accrue looks much stronger than a typical rough OSS library, but its proof machinery is dense enough that the next failure mode is not "missing work"; it is "hard to tell what matters, what is current, and what green actually proves."

**Blunt diagnosis:** Accrue has a strong engine and unusually serious proof posture; the adoption risk is that the project now asks strangers and maintainers to navigate too much high-quality machinery without a sharp enough evaluator path.

## Dimension Ranking Table

| Rank | Dimension | Score | Confidence | Evidence | Practical consequence | Highest-leverage fix | Priority |
|---:|---|---:|---|---|---|---|---|
| 1 | CI/CD and automation | 3 | High | `.github/workflows/ci.yml`; `scripts/ci/README.md`; `examples/accrue_host/mix.exs` | Slow or opaque required checks weaken trust and maintainer flow | Measure timings, split duplicated gates, clarify live/provider semantics | should fix before broad public push |
| 2 | Adoption ease | 3 | High | `README.md`; `accrue/README.md`; `examples/accrue_host/README.md`; adoption matrix | New evaluator may not know which path proves value fastest | One evaluator path with 3-5 commands and pass/fail criteria | should fix before broad public push |
| 3 | Documentation IA | 3 | High | 2,161 lines across sampled front-door docs/guides; several 293-483 line guides | Strong docs can still cost too much reader energy | Reshape docs index around onboarding/intermediate/advanced tasks | should fix before 1.0 polish line |
| 4 | Release quality / version truth | 3 | High | `CONTRIBUTING.md` says Elixir 1.17+/OTP 27+; packages use `~> 1.19`; CI uses OTP 28 | Public version truth drift damages trust | Public truth audit and same-source toolchain/version table | must fix before next release-readiness pass |
| 5 | Package parity (`accrue_portal`) | 3 | Medium | `accrue_portal/README.md`; no portal guides dir; release notes mainly core/admin | Portal may look less mature than core/admin | Portal adoption/readiness pass | should fix before heavy portal promotion |
| 6 | Provider-parity clarity | 3 | Medium | `live-stripe` scheduled job; `accrue/test/live_stripe`; `guides/testing-live-stripe.md` | Users may over- or under-trust Fake vs Stripe evidence | Provider proof matrix with proved/skipped states | should fix before public trust push |
| 7 | OSS polish / trust signals | 3 | High | `mix.exs` package links are empty; README has no badges; issue templates exist | Hex/GitHub first impression undersells maturity | Package metadata and listing polish | nice soon |
| 8 | Contributor experience | 3 | High | `CONTRIBUTING.md`; local gate list heavy; toolchain drift | New contributor setup path is accurate-ish but heavy | Update toolchain, add "fast local first" command | should fix before broad contributor push |
| 9 | Maintainer support burden | 3 | Medium | Many bash gates; overlapping docs contracts; CI maps | Support/debugging requires remembering too many ledgers | Consolidated support triage map | should fix before scale |
| 10 | Backward compatibility and API stability | 4 | High | `RELEASING.md`; `upgrade.md`; stable-core posture | Mostly strong; risk is hidden default/config drift | Keep deprecation and public-surface list current | maintain |
| 11 | Data model / DB hygiene | 4 | High | `Accrue.Schema`; `Accrue.Migration`; `configuration.md` | Current `billing` prefix solves public-schema pollution | Add prefix agreement guards, keep `billing` | should harden, not redesign |
| 12 | Functional suitability | 4 | Medium | 346 test files; host proof; billing/admin/portal docs | Appears broad and real; full audit still needed | Sample core JTBD against implementation | maintain |
| 13 | Reliability / resilience | 4 | Medium | webhook DLQ, Oban jobs, idempotency tests, runbooks | Strong, but complex async surfaces need proof clarity | Keep failure-mode docs tied to tests | maintain |
| 14 | SRE / observability | 4 | High | `telemetry.md`; `operator-runbooks.md`; admin UI | Better than typical OSS billing libs | Tighten "what to alert on first" summary | nice later |
| 15 | Testing / QA | 4 | High | 346 tests; Playwright; property tests; docs gates | Strong but likely expensive | Classify by value and runtime | should optimize |
| 16 | UI/UX quality | 4 | High | v1.53/v1.54 audits; Storybook; page specs | Recently hardened; residual risk in portal/admin parity | Keep screenshot/page-flow gates honest | maintain |
| 17 | Design-system coherence | 4 | High | `accrue_admin/guides/spec-*`; component lab; tokens | Strong after v1.53/v1.54 | Do not churn without evidence | nice later |
| 18 | Accessibility | 4 | Medium | axe gates, Playwright, UI reviews | Good signal, not full WCAG proof | Keep axe + keyboard flow coverage | maintain |
| 19 | Configuration quality | 4 | High | `Accrue.Config`; NimbleOptions; troubleshooting guide | Strong; many options require clear IA | Config quick reference | nice later |
| 20 | Security | 4 | Medium | `SECURITY.md`; webhook docs; secrets handling; auth boundaries | Strong posture, still worth periodic review | Security-focused audit before major release | maintain |
| 21 | Host-app compatibility | 4 | High | host-owned Repo/Oban/auth boundaries; `billing_schema` | Strong guest behavior | Prefix and generated-file guards | maintain |
| 22 | Architecture boundaries | 4 | Medium | package split; stable-core docs; repo facade | Looks coherent; audit should sample circular deps | xref/compile graph check later | nice later |
| 23 | Maintainability | 4 | Medium | tests + docs are extensive; config/gates complex | Main risk is proof/docs sprawl | Consolidate docs/gates, not architecture | should fix targeted |
| 24 | Performance / scalability | 4 | Low | analytics guide notes 100k event index; admin gates | No obvious repo evidence of app-runtime bottleneck | Measure realistic hot paths only if sourced | nice later |
| 25 | Privacy / data lifecycle | 4 | Medium | webhook retention config; SECURITY; telemetry docs | Good primitives; no legal deep dive needed | Add PII-safe support checklist | nice later |
| 26 | Dependency health | 4 | Medium | package deps are purposeful but broad | Billing lib has heavy deps by nature | Package dependency justification table | nice later |
| 27 | Ecosystem fit | 4 | High | Phoenix/Ecto/Oban/Telemetry idioms | Strong | Keep avoiding host ownership leaks | maintain |
| 28 | Portability / deployment | 4 | Medium | Docker host, releases docs, runtime config | Good Linux/Postgres/Phoenix story | Release/container checklist polish | nice later |
| 29 | Extensibility | 4 | Medium | behaviours/adapters for auth, processor, mailer, PDF | Strong, but extension docs spread out | Extension index | nice later |
| 30 | Safety of defaults | 4 | Medium | Fake in test, Stripe runtime secrets, `billing` schema | Strong; verify live/provider skip semantics | Provider/default truth table | should fix |
| 31 | Quality of examples/demos | 4 | High | `examples/accrue_host`; Docker; Playwright | Strong but heavy | Evaluator "fast proof" path | should fix |
| 32 | Product clarity/problem fit | 4 | High | root/core README; JTBD guide; brand prompt | Clear, but broad surface can overwhelm | "Use / do not use" box | nice soon |
| 33 | Public API design/DX | 4 | Medium | generated facade, public surface docs | Looks deliberate; needs API sample audit | API footgun sample pass | nice later |
| 34 | Internationalization | N/A | Medium | Billing lib has some locale/timezone, no broad i18n promise | Not core adoption blocker today | Do not overbuild | not worth now |
| 35 | Legal/licensing | 5 | High | MIT licenses, font license, code of conduct | Good enough | Maintain attribution | maintain |
| 36 | Intangible coherence/taste | 4 | Medium | stable-core posture, brand book, design docs | Strong point of view; risk is density | Consolidate front doors | should fix |

## Top 5 Weakness Deep Dives

### 1. CI/CD Efficiency and Signal Fidelity

**What I observed:** CI is comprehensive but likely over-coupled. Static dependency shape makes the critical path `release-gate -> admin-drift-docs -> host-integration -> playwright-e2e -> annotation-sweep`. `release-gate` repeats package work across four matrix cells. Host and Playwright lanes duplicate dependency/browser setup.

**Why it matters:** Required gates must be fast enough to respect maintainer time and precise enough that "green" means the promised risk was actually tested.

**Evidence from repo:** `.github/workflows/ci.yml`; `scripts/ci/accrue_host_uat.sh`; `scripts/ci/accrue_host_verify_browser.sh`; `examples/accrue_host/mix.exs`.

**User pain:** Contributors wait on expensive gates without knowing which failure matters.

**Maintainer pain:** Debugging CI drift becomes a release job, not a quick fix.

**Fix first:** Add timing/summary instrumentation and split compatibility-proof work from repeated lint/docs/audit work. Do not delete gates until measured.

**Do not over-fix:** Do not replace the pipeline with clever reusable workflow indirection before measuring.

### 2. First-Time Evaluator Clarity

**What I observed:** Accrue has a root README, package README, host README, proof matrix, testing docs, production docs, and scripts map. All are useful, but there are too many credible first reads.

**Why it matters:** A stranger gives an OSS billing library very little time before deciding it is too much.

**Evidence from repo:** `README.md`, `accrue/README.md`, `examples/accrue_host/README.md`, `examples/accrue_host/docs/adoption-proof-matrix.md`, `accrue/guides/first_hour.md`.

**Fix first:** Add one evaluator path: what to read, what to run, what success looks like, and when to stop.

**Do not over-fix:** Do not rewrite the whole docs corpus; the content is mostly good.

### 3. Public Truth Drift

**What I observed:** Some public surfaces lag the actual repo truth. Example: `CONTRIBUTING.md` still says Elixir 1.17+/OTP 27+, while package manifests and CI are on Elixir 1.19 / OTP 28.

**Why it matters:** Toolchain and release truth drift makes users doubt everything else.

**Evidence from repo:** `CONTRIBUTING.md`; `accrue/mix.exs`; `accrue_admin/mix.exs`; `accrue_portal/mix.exs`; `.github/workflows/ci.yml`; `RELEASING.md`.

**Fix first:** One public truth table for supported Elixir/OTP/Postgres/Node/Phoenix/Ecto/Oban and release-lane meaning.

**Do not over-fix:** Do not make this a governance ceremony. Keep it as simple docs + verifier needles.

### 4. Portal Parity

**What I observed:** `accrue_portal` exists as a sibling package and has tests, but its docs and public narrative are thinner than core/admin.

**Why it matters:** If Braintree/local portal is part of the official story, a thin portal surface can make the whole suite look uneven.

**Evidence from repo:** `accrue_portal/README.md`; `accrue_portal/mix.exs`; `accrue_portal/CHANGELOG.md`; `accrue/guides/release-notes.md`; `.github/ISSUE_TEMPLATE/bug.yml`.

**Fix first:** Portal readiness pass: install, auth/session, CSP, theming/customization, Braintree flow, troubleshooting, release notes.

**Do not over-fix:** Do not build new portal features until the existing contract is easier to adopt.

### 5. DB Schema Contract Hardening

**What I observed:** The dedicated-schema posture already exists and defaults to `billing`. That is good. The risk is contract drift across compile-time Ecto schema prefix, runtime migration helper prefix, docs, installer, and existing installs.

**Why it matters:** A billing library that loses track of which schema owns its tables can create scary data-migration failures.

**Evidence from repo:** `accrue/lib/accrue/schema.ex`; `accrue/lib/accrue/migration.ex`; `accrue/lib/accrue/config.ex`; `accrue/guides/configuration.md`; `accrue/guides/upgrade.md`.

**Fix first:** Keep `billing`. Add guards that schema prefix, migration helper prefix, installer docs, explicit `public`, and old `billing` compatibility stay aligned.

**Do not over-fix:** Do not rename default schema to `accrue`; `billing.accrue_customers` is cleaner than `accrue.accrue_customers` and avoids upgrade risk.

## Adoption Friction Audit

| Step | Friction | Likely confusion | Highest-leverage fix |
|---|---|---|---|
| Landing on README | Moderate | Proof-path detail appears before simplest mental model | Keep proof, add "30-second evaluator path" |
| Understanding problem | Low | Broad "everything SaaS billing" surface | Add "use / do not use" box |
| Deciding fit | Medium | Stripe/Braintree/Fake boundaries are long | Short provider truth matrix |
| Installing | Low | `mix accrue.install` clear | Keep |
| Configuring | Medium | Many runtime/compile-time settings | Config quick reference |
| Migrations | Medium | Dedicated schema is good but compile-time prefix matters | Schema ADR and warnings |
| Supervision/routes | Medium | Host owns Oban/auth/routes | One first-hour diagram |
| First useful example | Low/medium | Host demo is strong but heavy | Fast proof mode |
| Debugging first error | Low | Troubleshooting guide strong | Link earlier |
| Realistic app | Low/medium | Example host is rich | Keep focused walkthrough |
| Customizing | Medium | Extension docs spread out | Extension index |
| Upgrading | Medium | Good upgrade docs; version truth drift risk | Public truth pass |

## Production Readiness / SRE Audit

| Step | What works | Missing/risky | Risk reducer |
|---|---|---|---|
| Deploying | Runtime config docs, host-owned Repo/Oban | Toolchain truth drift | Public truth table |
| Safe config | NimbleOptions, boot guards | Many options spread over guides | Config index |
| Normal behavior | Telemetry and admin UI | Signal catalog can overwhelm | "Top first alerts" section |
| Detecting failures | Ops telemetry, DLQ, runbooks | Live/provider lane semantics need clarity | Provider proof state |
| Debugging failures | Troubleshooting guide | Too many docs paths | Triage landing page |
| Recovering bad state | Webhook replay/admin | Needs proof clarity | Runbook command snippets |
| Load/scale | Index guidance, queues | Sparse benchmark evidence | Measure sourced hot paths only |
| Retry/timeouts | Oban/idempotency patterns | Provider parity not always mandatory | Explicit lane labels |
| Data growth | Retention settings | Audit table growth needs periodic check | Ops checklist |
| Upgrading safely | Upgrade + release docs | Existing schema-prefix default needs pinning clarity | Schema ADR |

## UI/UX and Design-System Audit

Accrue has UI: `accrue_admin` and `accrue_portal`.

`accrue_admin` looks useful enough to ship and unusually coherent after v1.53/v1.54: design specs, Storybook, component lab, page-flow gates, and accessibility checks exist. The top UI risk is no longer obvious visual inconsistency; it is regression-gate cost and whether portal parity keeps up with admin polish.

Top UI fixes:
1. Keep the page-flow gate, but measure its CI cost.
2. Add a portal parity review.
3. Ensure theming/customization docs are easy to find from each package README.
4. Keep accessibility proof tied to real host routes.
5. Avoid new visual systems until adoption evidence demands them.

## Maintainer Friction Audit

| Activity | Friction | Risk | Highest-leverage fix |
|---|---|---|---|
| Setup repo | Medium | Toolchain drift | Update CONTRIBUTING |
| Run tests | Medium/high | Many gates and package dirs | Canonical local command map |
| Understand architecture | Medium | Broad package suite | Architecture one-pager |
| Small change | Medium | Docs contracts can fail unexpectedly | Script-to-owner map is good; surface it earlier |
| Add feature | Medium | Stable-core posture helps | Keep reopen triggers |
| Debug user report | Medium | Strong guides but spread out | Support triage index |
| Review PR | Medium | Many generated/proof artifacts | Reviewer checklist by file area |
| Cut release | Medium | Release Please path strong but complex | Recovery workflow guardrails |
| Support old versions | Medium | SemVer policy exists | Keep supported-lines table current |
| Keep deps current | Medium | Heavy ecosystem deps | Scheduled dependency review |

## GSD Sanity Check

**Probably overkill now:** broad runtime performance benchmarking, full enterprise governance, i18n, pixel-diff visual regression, schema rename to `accrue`.

**Not optional:** CI signal truth, public version/toolchain truth, schema-prefix contract clarity, release recovery guardrails, first evaluator path.

**Accept rough edges:** deep advanced docs can stay verbose. Billing is complex.

**Rough edges that damage trust:** stale supported-version claims, "mandatory" jobs that skip, release workflows that rely on human order, schema-prefix ambiguity.

**Clean up now after GSD speed:** front-door docs, CI topology, old milestone-specific gates, release truth, package metadata.

**Do not prematurely formalize:** a giant governance process, heavyweight benchmark suite, or broad new feature roadmap.

## Missing-Dimension Discovery

Project-specific dimensions that matter beyond the generic checklist:

- **Provider proof semantics:** what Fake proves, what Stripe test mode proves, what Braintree hermetic tests prove, and what remains advisory.
- **Schema-prefix safety:** compile-time Ecto prefix vs runtime migration prefix.
- **Billing temporal correctness:** webhook ordering, dunning timing, metered usage windows, subscription lifecycle transitions.
- **Release train coherence:** lockstep core/admin/portal publish order and recovery.
- **Evaluator proof ergonomics:** the shortest path from clone to confidence.

## Evidence Appendix

This appendix is the QLT-05 evidence map. Static repository evidence is the primary source. Bounded command output supports confidence; it is not a full release proof. When a claim needs live CI history, a live provider account, branch-protection settings, external scorecards, or production traffic data, it is labeled **metrics-needed** or **Assumption**.

### Bounded Command Evidence

| Command or inspection | Result | Score impact | Boundary label |
|---|---|---|---|
| `wc -l README.md accrue/README.md accrue_admin/README.md accrue_portal/README.md examples/accrue_host/README.md accrue/guides/first_hour.md accrue/guides/production-readiness.md accrue/guides/operator-runbooks.md accrue/guides/telemetry.md accrue/guides/testing.md guides/testing-live-stripe.md` | 2,161 lines across sampled front-door docs and guides; largest sampled guides are `examples/accrue_host/README.md` (483), `accrue/guides/telemetry.md` (471), and `accrue/guides/first_hour.md` (293) | Supports Documentation IA and Adoption ease score 3 | Static sample, not a full docs information-architecture study |
| `find accrue/test -type f -name '*_test.exs'`, plus package/host equivalents | 236 core, 60 admin, 14 portal, 36 host test files; 346 total in the sampled test tree | Supports Testing/QA score 4 and "strong but expensive" risk | Static count; runtime value and slowest tests are metrics-needed for Phase 202/204 |
| `find accrue/test/live_stripe -maxdepth 1 -type f` | 3 `:live_stripe` test modules: `charge_3ds_live_test.exs`, `connect_test.exs`, `proration_fidelity_live_test.exs` | Supports Provider-parity clarity score 3 | Advisory Stripe test-mode/provider-parity proof, not a required Phase 201 gate |
| `rg -n "Elixir 1\\.17|OTP 27|elixir-version|otp-version|@version|elixir: \"~>" CONTRIBUTING.md .github/workflows/ci.yml accrue/mix.exs accrue_admin/mix.exs accrue_portal/mix.exs` | `CONTRIBUTING.md` names Elixir 1.17+/OTP 27+; all three packages use `elixir: "~> 1.19"`; CI cells use OTP 28 / Elixir 1.19.x | Supports Release quality/version truth and Contributor experience score 3 | Static docs/manifests evidence |
| `rg -n "live-stripe|continue-on-error|STRIPE_TEST_SECRET_KEY|schedule|workflow_dispatch" .github/workflows/ci.yml guides/testing-live-stripe.md` | CI and docs label `live-stripe` as manual/scheduled Stripe test-mode parity, with advisory/non-merge-blocking wording and skip/proved semantics | Supports Provider-parity clarity and Safety of defaults findings | Static semantics; proved-vs-skipped counts are metrics-needed |
| `git status --short` | Only the seeded Phase 201 audit is plan-owned before Task 1 edits; other dirty paths match the pre-existing baseline supplied to the executor | Supports phase boundary check | Adjusted boundary evidence because literal clean tree is intentionally false at executor start |

### Score 3 Evidence Map

| Dimension | Local evidence | What it proves | Assumption / metrics-needed label |
|---|---|---|---|
| CI/CD and automation | `.github/workflows/ci.yml`; `scripts/ci/README.md`; `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md` | Many required jobs, matrix cells, docs gates, host/browser lanes, and a specialist audit identifying timing/cache/flake measurements still needed | **metrics-needed:** p50/p95 job runtime, cache hit rates, rerun/flake rate, branch-protection settings |
| Adoption ease | `README.md`; `accrue/README.md`; `examples/accrue_host/README.md`; `examples/accrue_host/docs/adoption-proof-matrix.md`; `accrue/guides/first_hour.md` | Several credible first reads exist: root proof path, package guide, host Start Here, proof matrix, and First Hour capsules | Direct repo fact; user attention cost is a reasoned release-readiness judgment |
| Documentation IA | Same sampled docs plus `scripts/ci/README.md`, `accrue/guides/production-readiness.md`, `accrue/guides/operator-runbooks.md`, `accrue/guides/telemetry.md` | The docs are rich and mechanism-led, but the support/proof material is spread across multiple long surfaces | **Assumption:** new-reader scan cost is inferred from static IA, not measured with users |
| Release quality / version truth | `CONTRIBUTING.md`; `accrue/mix.exs`; `accrue_admin/mix.exs`; `accrue_portal/mix.exs`; `.github/workflows/ci.yml`; `RELEASING.md` | Public setup says Elixir 1.17+/OTP 27+ while package manifests and CI are on Elixir 1.19/OTP 28 | Direct repo fact |
| Package parity (`accrue_portal`) | `accrue_portal/README.md`; `accrue_portal/lib/accrue_portal/live/subscriptions_live.ex`; `accrue_portal/priv/static/accrue_portal.css`; `.planning/todos/pending/2026-06-19-white-label-billing-portal-design-system.md` | Portal exists and works as a package surface, but its public docs/design-system depth is thinner than core/admin and a white-label portal pass is already captured | Direct repo fact; priority depends on Phase 204 ranking |
| Provider-parity clarity | `guides/testing-live-stripe.md`; `accrue/test/live_stripe/`; `.github/workflows/ci.yml`; `examples/accrue_host/docs/adoption-proof-matrix.md` | Fake remains merge-blocking; Stripe test-mode/live-Stripe checks are advisory provider-parity lanes; skip/proved state needs clearer public summary | **metrics-needed:** daily scheduled proved-vs-skipped history belongs to Phase 202 |
| OSS polish / trust signals | `brandbook/copy.md`; `README.md`; package `mix.exs` files; package READMEs | The approved public description/topics exist in brandbook copy, but package metadata and first-impression surfaces still need a consistency pass | **Assumption:** Hex/GitHub first-impression impact inferred from OSS norms and local metadata, not external scorecard |
| Contributor experience | `CONTRIBUTING.md`; `scripts/ci/README.md`; `.github/workflows/ci.yml`; `examples/accrue_host/README.md` | Contributor setup is detailed, but local gates and CI ownership maps are heavy for a first PR | Direct repo fact; actual newcomer failure rate is metrics-needed |
| Maintainer support burden | `scripts/ci/README.md`; `accrue/guides/operator-runbooks.md`; `accrue/guides/telemetry.md`; `SECURITY.md`; `RELEASING.md` | Support and release procedures are serious and detailed; risk is remembering which ledger/script owns a failure | Direct repo fact; support ticket volume is metrics-needed |

### Folded Todo Classification

| Todo | Evidence use in this audit | Current weakness? | Why |
|---|---|---|---|
| `.planning/todos/pending/2026-06-19-white-label-billing-portal-design-system.md` | Evidence for portal parity and customer-facing white-label UX risk | Yes, only as portal parity evidence | The todo cites `/billing/subscriptions` and `accrue_portal` component/style gaps, but Phase 201 does not implement it |
| `.planning/todos/pending/2026-06-21-shared-page-header-component-for-accrue-admin.md` | Resolved positive design-system evidence, paired with `accrue_admin/lib/accrue_admin/components/page_header.ex` and `storybook/components/page_header.story.exs` | No | PageHeader exists now; if anything, the pending todo is stale-todo hygiene evidence |
| `.planning/todos/pending/2026-06-19-brandbook-use-accrue-favicon.md` | Low-risk deferred public-trust polish evidence | No | Favicon alignment is real polish, but it does not reduce enough adoption, production, support, or maintenance risk to rank as a current weakness |

### Provider-Parity / Live-Stripe Label

`guides/testing-live-stripe.md` and `accrue/test/live_stripe` are advisory Stripe test-mode/provider-parity proof. They are useful evidence that Accrue watches real Stripe API drift for 3DS, Connect, and proration shapes. They are **not** a required Phase 201 gate, not the canonical local demo, and not the merge-blocking Fake-backed proof lane. The audit therefore ranks provider-proof semantics as a clarity/trust risk without asking Phase 201 to run live Stripe or change CI.

### Assumptions and Metrics-Needed Items

- **Assumption:** Branch protection required-check topology is inferred from `.github/workflows/ci.yml` comments and job names, not from live GitHub settings.
- **metrics-needed:** CI p50/p95 duration, cache hit/miss rates, slowest ExUnit tests, Playwright browser install cost, Docker smoke cold/warm duration, and retry/flake rates belong to Phase 202.
- **metrics-needed:** Live-Stripe scheduled proved-vs-skipped counts belong to Phase 202. Phase 201 records the lane semantics only.
- **metrics-needed:** Runtime app performance, real production traffic scale, webhook p99s, and database growth rates are not required for this audit-only phase.
- **Assumption:** External OpenSSF-style scorecards could improve OSS trust analysis later, but Phase 201 does not use them as evidence.

## Phase Handoff and Boundary

Phase 201 is an **audit-only** gate. Broad project verification, Docker boot proof, live provider proof, GitHub run-history metrics, flake-rate metrics, external scorecards, product behavior changes, public API changes, DB default changes, CI required-check topology changes, release automation changes, runtime UI changes, CSS changes, routes, and package metadata edits are **not required** and are not part of the **Phase 201 gate**.

| Handoff | Phase 201 finding | Owner for implementation-grade detail |
|---|---|---|
| Phase 202 | CI/CD signal fidelity is the weakest quality dimension because static topology suggests duplicated work and ambiguous provider/lane truth | `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md` owns timings, cache behavior, flake/rerun history, target pipeline, and proved-vs-skipped counts |
| Phase 203 | Schema-prefix safety is a data/upgrade risk because compile-time schema prefix, migration helpers, installer docs, explicit `public`, and existing installs must stay aligned | `.planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md` owns the accepted `billing` default, explicit `public`, non-goals, and hardening checks |
| Phase 204 | Follow-up work needs ranking by impact, effort, risk reduction, timing, and done criteria | `.planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md` consumes this audit plus Phases 202/203 so CI and DB risks are not double-counted |

## Top 10 Concrete Changes

| Rank | Area | Dimension improved | Why it matters | Impact | Effort | Risk reduction | Timing | Done looks like |
|---:|---|---|---|---|---|---|---|---|
| 1 | CI workflow | CI/CD | Shortens and clarifies required gates | High | Medium | High | before showing to strangers | timing baseline + target topology |
| 2 | README/host docs | Adoption | Gives evaluators one path | High | Low | High | before showing to strangers | 30-minute proof path |
| 3 | CONTRIBUTING/release docs | Public truth | Removes version/toolchain drift | High | Low | High | before Hex release | one current toolchain table |
| 4 | Provider proof docs | Trust | Prevents overclaiming Fake/live lanes | High | Medium | High | before Hex release | proved/skipped matrix |
| 5 | `publish-hex.yml` | Release | Prevents out-of-order recovery | Medium | Low | High | before Hex release | machine prerequisite checks |
| 6 | Schema prefix guards | DB safety | Prevents compile/migration prefix drift | Medium | Medium | High | before 1.0 hardening | explicit `billing`/`public` tests |
| 7 | Portal docs | Package parity | Makes portal feel first-class | Medium | Medium | Medium | before portal promotion | portal setup/troubleshooting guide |
| 8 | Package metadata | OSS polish | Improves Hex/GitHub first impression | Medium | Low | Medium | before showing to strangers | links/descriptions/badges |
| 9 | Support triage index | Supportability | Lowers maintainer issue round-trips | Medium | Low | Medium | before scale | symptom -> first check page |
| 10 | Test value classification | QA efficiency | Keeps high signal, demotes waste | Medium | Medium | Medium | later | keep/optimize/nightly/delete table |
