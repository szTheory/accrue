# Phase 225 CI incidents

This is the privacy-safe causal index for the active required-lane signatures. Raw logs, browser reports, traces, screenshots, server output, payloads, secrets, and user data remain GitHub Actions artifacts.

## INC-225-RELEASE-WEBHOOK

**What failed:** `Accrue.Webhook.IngestTest` asserted suite-global row counts and therefore failed when unrelated sandbox-visible rows existed.

**Classification:** test-isolation / over-broad-observation; high confidence.

**Next command:** `cd accrue && mix test test/accrue/webhook/ingest_test.exs --warnings-as-errors`

**Evidence:** [run 31289155535](https://github.com/szTheory/accrue/actions/runs/31289155535), including the immutable [Floor job](https://github.com/szTheory/accrue/actions/runs/31289155535/job/93183274990) and [OpenTelemetry job](https://github.com/szTheory/accrue/actions/runs/31289155535/job/93183274973).

- **Incident ID/status:** `INC-225-RELEASE-WEBHOOK` — repaired.
- **Normalized signature:** whole-table `WebhookEvent`, `Oban.Job`, or `accrue_events` cardinality assertion in `Accrue.Webhook.IngestTest` observes rows not owned by the event under test.
- **Classification/confidence:** test-isolation / over-broad-observation; high, trace-backed by the identical focused-test failure in the affected release cells.
- **First run/SHA:** [run 31287555136](https://github.com/szTheory/accrue/actions/runs/31287555136) / `pending verification`.
- **Last run/SHA:** [run 31289155535](https://github.com/szTheory/accrue/actions/runs/31289155535) / `702dc482df0f65c332be1d4dfb821c4fe60aec49`.
- **Affected cells:** Floor `[required]`; Primary dev target `[required]`; Primary dev target with OpenTelemetry `[required]`; Primary dev target with Sigra `[advisory]`. Sigra is not required release proof.
- **Canonical owner and repair surface:** core webhook test contract — `accrue/test/accrue/webhook/ingest_test.exs`.
- **Narrow repro:** the next command above; it needs no credential or external service.
- **Immutable evidence/artifact links:** [run](https://github.com/szTheory/accrue/actions/runs/31289155535), [Floor job](https://github.com/szTheory/accrue/actions/runs/31289155535/job/93183274990), [Primary + OpenTelemetry job](https://github.com/szTheory/accrue/actions/runs/31289155535/job/93183274973), and the run's Actions artifacts.
- **Ruled-out hypotheses:** this is not four compatibility incidents, a processor-support defect, a retry need, or a reason to alter matrix cells, cache, serialization, release topology, or branch protection.
- **Root cause:** the tests read whole shared tables and asserted global cardinality even though SQL-sandbox isolation does not promise those tables are globally empty.
- **Corrective change:** select the event by `(processor, processor_event_id)`, then query its `DispatchWorker` job and `webhook.received` ledger event by the persisted event ID.
- **Negative-control proof:** a same `(processor, processor_event_id)` replay returns 200 while identity-scoped webhook, dispatch-job, and ledger predicates each remain exactly one.
- **Targeted/negative-control/full-local/fresh-run evidence:**
  - **Targeted reproduction:** `cd accrue && mix test test/accrue/webhook/ingest_test.exs --warnings-as-errors` — PASS at `2026-08-09T03:35:04Z` on `9d7b9ccb092ffcdeae71a2ca25dfa28fad18d8b0` (`5 tests, 0 failures`). This proves the repaired event-owned persistence contract.
  - **Negative control:** the same targeted command includes `duplicate POST returns 200 with one event-owned webhook, job, and ledger fact` — PASS at `2026-08-09T03:35:04Z` on `9d7b9ccb092ffcdeae71a2ca25dfa28fad18d8b0`. It proves replay for the same `(processor, processor_event_id)` cannot create a second identity-owned fact.
  - **Full local suite:** `cd accrue && mix test --warnings-as-errors` — PASS at `2026-08-09T03:34:23Z` on `9d7b9ccb092ffcdeae71a2ca25dfa28fad18d8b0`. The runner emitted its configured `test/fixtures/apple/server_evidence.exs` load-filter warning but exited zero; no suite count is claimed because the runner stream did not retain one in this evidence capture.
  - **Fresh repair SHA:** `ee940cf9e1f86b4d7c551b15ce113feb7f2a2997`.
  - **Fresh repair run ID:** [31322443304](https://github.com/szTheory/accrue/actions/runs/31322443304) — `workflow_dispatch`, completed `success`; this is a new run, not a rerun.
  - **Required jobs:** [Floor](https://github.com/szTheory/accrue/actions/runs/31322443304/job/93267406379), [Primary](https://github.com/szTheory/accrue/actions/runs/31322443304/job/93267406378), and [Primary + OpenTelemetry](https://github.com/szTheory/accrue/actions/runs/31322443304/job/93267406381) — all `success`.
  - **Advisory:** [Primary + Sigra](https://github.com/szTheory/accrue/actions/runs/31322443304/job/93267406380) — `success`, recorded separately and not used as required proof.
- **Residual owner/status:** Accrue maintainers — Status: repaired; continue normal regression monitoring.

## INC-225-ADMIN-PAGEFLOW

**What failed:** the Phase 192 page-flow traversal exhausted one whole-test budget while continuing through ordinary checks.

**Classification:** capacity/topology versus whole-test-budget; high confidence.

**Next command:** `bash scripts/ci/verify_phase192_admin_guardrails.sh`

**Evidence:** immutable [Admin hardening guardrails job](https://github.com/szTheory/accrue/actions/runs/31289155535/job/93183274999) in [run 31289155535](https://github.com/szTheory/accrue/actions/runs/31289155535).

- **Incident ID/status:** `INC-225-ADMIN-PAGEFLOW` — repaired.
- **Normalized signature:** one Phase 191 Playwright test traverses `5 viewports × 2 themes × 21 flows` (210 login/navigate/check cycles) under a 60-second test budget.
- **Classification/confidence:** capacity/topology versus whole-test-budget; high. The trace reached ordinary successful Dunning Timeline checks near 64 seconds rather than showing a stuck selector or network call.
- **First run/SHA:** [run 31289155535](https://github.com/szTheory/accrue/actions/runs/31289155535) / `702dc482df0f65c332be1d4dfb821c4fe60aec49`.
- **Last run/SHA:** [run 31289155535](https://github.com/szTheory/accrue/actions/runs/31289155535) / `702dc482df0f65c332be1d4dfb821c4fe60aec49`.
- **Affected cells:** `admin-hardening-guardrails` `[required]`; its report, test-results, and generated-evidence artifacts remain Actions-owned evidence.
- **Canonical owner and repair surface:** Admin page-flow test boundary — `accrue_admin/e2e/admin-page-flow-phase191.spec.js`.
- **Narrow repro:** the next command above; it is the credential-free canonical Phase 192 guardrail entrypoint.
- **Immutable evidence/artifact links:** [job](https://github.com/szTheory/accrue/actions/runs/31289155535/job/93183274999), [run](https://github.com/szTheory/accrue/actions/runs/31289155535), and that job's retained Actions report, test-results, and generated-evidence artifacts.
- **Ruled-out hypotheses:** no trace-backed browser lifecycle, external-service, selector-stall, or network-stall failure was observed; retries, sleeps, global timeout inflation, and topology changes are not corrective evidence.
- **Root cause:** a 210-cycle serial traversal was assigned one 60-second test budget despite ordinary progress beyond that budget.
- **Corrective change:** Plan 225-02 partitions the traversal into five bounded, independently reported viewport tests while preserving both themes, all 21 flows, single-worker execution, retries=0, assertions, and artifacts.
- **Negative-control proof:** `bash scripts/ci/verify_phase192_ci_contract.sh && bash scripts/ci/verify_phase192_guardrail_contract.sh` — PASS at `2026-08-09T03:34:23Z` on `9d7b9ccb092ffcdeae71a2ca25dfa28fad18d8b0`. The contracts prove five viewport partitions, `5 × 2 × 21` coverage, zero retries/single worker, stable Phase 192 check identity, report/generated artifact contracts, and first-failure `test-results` semantics.
- **Targeted/full-local/fresh-run evidence:**
  - **Targeted reproduction:** `bash scripts/ci/verify_phase192_admin_guardrails.sh` is the credential-free narrow gate retained by the incident. Its static contract companions above passed on the repair SHA and preserve the required report/generated evidence paths.
  - **Full local browser suite:** `cd accrue_admin && npm run e2e:phase191` — PASS at `2026-08-09T03:34:23Z` on `9d7b9ccb092ffcdeae71a2ca25dfa28fad18d8b0`. It ran the five independently reported viewport partitions with both themes and all 21 flows under one worker and zero retries. Local paths remain `accrue_admin/playwright-report` and `accrue_admin/test-results`; the latter is a preserved first-failure affordance and may contain no payload after a clean run.
  - **Fresh repair SHA:** `ee940cf9e1f86b4d7c551b15ce113feb7f2a2997`.
  - **Fresh repair run ID:** [31322443304](https://github.com/szTheory/accrue/actions/runs/31322443304) — `workflow_dispatch`, completed `success`; this is a new run, not a rerun.
  - **Required job:** [Admin hardening guardrails (Phase 192)](https://github.com/szTheory/accrue/actions/runs/31322443304/job/93267406377) — `success`.
  - **Artifacts:** [phase192-admin-playwright-report](https://api.github.com/repos/szTheory/accrue/actions/artifacts/9040670600/zip) and [phase192-generated-evidence](https://api.github.com/repos/szTheory/accrue/actions/artifacts/9040670771/zip). The retained test-results upload remains a first-failure affordance and may have no payload on a clean run.
- **Residual owner/status:** Admin maintainers — Status: repaired; continue normal bounded-suite monitoring.
