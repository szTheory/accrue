# Phase 225: Required-Lane Signal Repair - Research

**Researched:** 2026-08-08
**Domain:** Deterministic CI failure repair: Ecto/Oban test isolation, Playwright test partitioning, and artifact-backed maintainer diagnostics
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Incident Record And Maintainer Experience
- **D-01:** Create one checked-in, human-readable phase-local incident record, `225-CI-INCIDENTS.md`, with one section per normalized failure signature—not per failed matrix cell. Each section must name an incident ID/status; normalized signature; classification and confidence; first/last run and SHA; affected required/advisory cells; canonical owner and repair surface; credential-free narrow repro; evidence/artifact links; ruled-out hypotheses; root cause; corrective change; negative-control proof; fresh repair-run evidence; and residual owner/status.
- **D-02:** Treat the incident record as the concise, durable causal index. Keep raw Playwright HTML reports, traces/test-results, screenshots, and relevant server logs as GitHub artifacts rather than checking log dumps into the repository. Keep records privacy-safe and link to immutable run/job/artifact evidence without copying secrets or user data.
- **D-03:** Preserve operational UX: lead each record and maintainer-facing entry with what failed, its precise classification, the one next command, and the evidence link. Use calm, exact, mechanism-led language; never label a failure merely "flaky" without evidence. No end-user/Admin visual work belongs in this phase.

### Shared Release-Matrix Incident
- **D-04:** Treat the identical `Accrue.Webhook.IngestTest` failures in every release-matrix cell as one **test-isolation / over-broad-observation** incident, not four compatibility incidents. The record must list every affected cell while retaining required/advisory support labels.
- **D-05:** Repair webhook tests by asserting facts owned by the event under test: `processor` + `processor_event_id` for `WebhookEvent`, the worker + `args["webhook_event_id"] == event.id` for Oban work, and the relevant ledger `type` + `subject_id`. Preserve idempotency and atomicity assertions, and add a deterministic negative control proving a duplicate for the same identity is rejected. Do not rely on global-table cardinality assumptions.
- **D-06:** Preserve release-gate job/check identity, all required cells, `fail-fast: false`, and explicitly advisory Sigra semantics. Do not resolve the incident by retries, global serialization, test deletion, matrix collapse, required-gate demotion, branch-protection edits, or cache/topology changes.
- **D-07:** Audit the test whose title claims rollback on Oban insertion failure: its current path exercises success only. Either rename it to a truthful successful-ingest co-presence/atomicity contract or add a deterministic failure seam and a real rollback test; planners must not claim rollback proof already exists.

### Admin Playwright Timeout
- **D-08:** Classify the Phase 192 Admin page-flow timeout as a trace-backed **capacity/topology versus whole-test-budget** failure, not an intermittent external/lifecycle failure. The current test performs 5 viewports × 2 themes × 21 flows (210 full login/navigate/check cycles) under one 60-second test budget; the trace reaches ordinary successful Dunning Timeline checks around 64 seconds rather than showing a stuck selector or network call.
- **D-09:** Retain all page-flow coverage but split the Cartesian traversal into bounded, independently reported Playwright tests, either per viewport or deterministic flow group. Keep CI single-worker execution, existing assertions, themes, viewports, screenshots, reports, and trace behavior. Set per-case budgets from observed timings; increase a timeout only when one coherent scenario needs it.
- **D-10:** Keep retries at zero for this required lane. A retry may help later diagnosis only when it records a flaky outcome and retains first-failure evidence; it must never make a required lane appear repaired. Prefer deterministic readiness/fixture/lifecycle boundaries and semantic user-facing locators over sleeps or global timeout inflation.
- **D-11:** Preserve useful Admin artifacts. Existing Phase 192 `if: always()` Playwright report and test-results uploads are a required trace-first affordance. Repair or explicitly replace the currently missing Phase 192 generated-evidence upload path before describing that generated evidence as available.

### Proof And Completion Bar
- **D-12:** Completion requires each active red signature to map to exactly one classified incident record; a targeted reproduction and relevant negative control; full local suite evidence; and a fresh repair-commit Actions run—not merely a rerun—where every required release cell and the required Admin job pass while their assertions, check identity, matrix topology, and artifacts remain available.
- **D-13:** Required and advisory evidence must remain visibly distinct in the incident record and CI proof. The three required release cells prove repair; Sigra remains `[advisory]` and cannot be represented as required release proof.

### the agent's Discretion
- The researcher and planner may choose the record's exact Markdown layout, stable incident IDs, artifact retention duration, and deterministic test partitioning, provided every D-01 through D-13 constraint holds.
- The planner may choose whether the misleading rollback test is truthfully renamed or backed by a new deterministic failure seam after code inspection; either path must state the actual proven behavior.

### Deferred Ideas (OUT OF SCOPE)
- Comparable-run duration/cache/rerun baseline, provider-proof semantics expansion, and host/browser setup ownership documentation belong to Phase 226.
- Matrix reshaping, required-check or branch-protection changes, cache rewrites, and critical-path optimization belong to Phase 227 after baseline and negative-control evidence.
- Admin UI ratchet recovery or redesign, StoreKit/iPhone/Crosswake work, and any end-user visual change remain out of scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REL-01 | A maintainer can reproduce and classify each currently failing required CI signature as deterministic code/configuration, test-isolation, lifecycle, or external-infrastructure failure. | Incident record, narrow commands, test-isolation diagnosis, trace-backed capacity diagnosis, and artifact links. [VERIFIED: codebase grep] |
| REL-02 | Required release and admin checks pass with the repaired root cause, while their meaningful assertions and failure artifacts remain available. | Identity-scoped test assertions, bounded Playwright tests, preserved guardrail scripts/job IDs/artifact uploads, plus local/full/fresh-Actions proof. [VERIFIED: codebase grep] |
| REL-03 | A matrix-wide symptom is reported and triaged as one root-cause incident when its failing signature is the same across matrix cells. | One normalized webhook incident lists the three required release cells and advisory Sigra cell without multiplying root causes. [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

This phase should make two existing CI signals trustworthy without changing CI topology. The release failure is a test-isolation defect: `Accrue.Webhook.IngestTest` queries whole `WebhookEvent`, `Oban.Job`, and `accrue_events` tables and then asserts cardinality, while `Accrue.RepoCase` uses SQL-sandbox isolation rather than guaranteeing those tables are globally empty. The ingestion implementation already gives every produced fact a stable identity: `(processor, processor_event_id)` for the webhook row, `webhook_event_id` for the `DispatchWorker` job, and `subject_id` for the ledger event. [VERIFIED: codebase grep]

The Admin failure is a test-budget topology defect. The one test at `admin-page-flow-phase191.spec.js:219` executes the complete 5 viewport × 2 theme × 21 flow traversal under `test.setTimeout(60_000)`, while the project is deliberately single-worker and trace-on-failure. Playwright gives each test its own timeout; its supported test-level parameterization produces separately named test results. Partition the traversal deterministically (recommended: one test per viewport, retaining the two themes and all 21 flows) and choose a documented per-case budget from observed timings. [VERIFIED: codebase grep] [CITED: https://playwright.dev/docs/test-timeouts] [CITED: https://playwright.dev/docs/test-parameterize]

**Primary recommendation:** Make three focused plan slices: write the incident/proof index first, replace webhook global-count assertions with identity-scoped positive and duplicate-negative controls, then partition the Page 191 traversal and repair the missing generated-evidence producer/path while preserving the required CI contracts. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Webhook persistence/idempotency proof | Database / Storage | API / Backend | The contractual identities are persisted webhook, Oban, and ledger rows; `Ingest.run/4` supplies their shared transaction. [VERIFIED: codebase grep] |
| Webhook regression assertions | API / Backend | Database / Storage | ExUnit owns behavior verification and must query facts for the event it created rather than suite-global state. [VERIFIED: codebase grep] |
| Page-flow test duration boundary | Browser / Client | CI / Static | Playwright test declarations define the unit of timeout/reporting; the CI runner invokes the exact package script. [VERIFIED: codebase grep] |
| Required check identity and artifact availability | CI / Static | Browser / Client | `.github/workflows/ci.yml` owns `admin-hardening-guardrails`, `release-gate`, uploads, and matrix support labels. [VERIFIED: codebase grep] |
| Durable incident diagnosis | CI / Static | Repository documentation | A checked-in phase-local Markdown index links immutable run/artifact evidence without embedding raw sensitive logs. [VERIFIED: codebase grep] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir ExUnit + Ecto SQL Sandbox | project lockfile | Identity-scoped webhook persistence assertions | Existing test foundation; the focused ingest file runs locally in 0.2s. [VERIFIED: codebase grep] |
| Oban | project lockfile | Enqueued `DispatchWorker` row assertions | Existing persistence contract exposes the event ID in job args. [VERIFIED: codebase grep] |
| `@playwright/test` | 1.59.1, published 2026-04-01 | Browser test partitioning, trace/report artifacts | Exact version is pinned in `accrue_admin/package.json` and installed locally. [VERIFIED: npm registry] [VERIFIED: codebase grep] |
| GitHub Actions `actions/upload-artifact` | v7.0.1 (current action tag in workflow) | Always-uploaded reports, test results, and generated evidence | Existing required lane uses it with `if: always()` and explicit artifact names. [VERIFIED: codebase grep] [ASSUMED] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `scripts/ci/verify_phase192_ci_contract.sh` | repository script | Pins job identity, environment, command, and artifact contract | Update it in the same change if the intended generated-evidence contract changes. [VERIFIED: codebase grep] |
| `scripts/ci/verify_phase192_guardrail_contract.sh` | repository script | Pins Phase 192 runner command composition | Keep its no-broad-suite/no-signoff constraints while changing only the bounded Page 191 implementation. [VERIFIED: codebase grep] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Identity-scoped queries | Global serialization or suite-wide cardinality checks | Forbidden by locked scope and still couples independent tests. [VERIFIED: codebase grep] |
| Bounded individual Playwright tests | One long test with a global timeout increase | Masks capacity topology, weakens per-case reporting, and conflicts with D-09/D-10. [VERIFIED: codebase grep] |
| Existing workflow/artifact design | Retry, matrix collapse, cache or branch-protection change | Explicitly out of scope and prohibited by D-06/D-10. [VERIFIED: codebase grep] |

**Installation:** No package installation or version upgrade is needed. [VERIFIED: codebase grep]

## Architecture Patterns

### System Architecture Diagram

```text
Release-gate matrix
  ├─ required: Floor / Primary / OpenTelemetry
  └─ advisory: Sigra
          │
          ▼
  Accrue.Webhook.IngestTest
          │ event identity
          ▼
  WebhookEvent(processor, processor_event_id)
          ├─► Oban DispatchWorker(args.webhook_event_id)
          └─► ledger webhook.received(subject_id)
          │
          ▼
  identity-scoped assertions + duplicate negative control

admin-hardening-guardrails (stable job id)
          │
          ▼
  verify_phase192_admin_guardrails.sh
          │
          ▼
  Page 191 deterministic bounded test cases (workers=1, retries=0)
          │
          ├─► HTML report / test-results / screenshots/traces
          └─► generated evidence (produced or explicitly replaced)
          │
          ▼
  always-uploaded GitHub artifacts + 225-CI-INCIDENTS.md causal index
```

### Recommended Project Structure

```text
.planning/phases/225-required-lane-signal-repair/
├── 225-CI-INCIDENTS.md        # durable causal index and fresh-run proof
└── 225-RESEARCH.md            # planning evidence
accrue/test/accrue/webhook/
└── ingest_test.exs            # identity-scoped regression contracts
accrue_admin/e2e/
└── admin-page-flow-phase191.spec.js # bounded Page 191 traversal
scripts/ci/
├── verify_phase192_admin_guardrails.sh
├── verify_phase192_guardrail_contract.sh
└── verify_phase192_ci_contract.sh
```

### Pattern 1: Assert owned persisted facts, not table emptiness

**What:** Query the event under test by `(processor, processor_event_id)`, then query the worker by its worker name and `args["webhook_event_id"]`, and the ledger by `type` plus `subject_id`. [VERIFIED: codebase grep]

**When to use:** Every integration test sharing an Ecto repository or Oban database with concurrent/sandboxed test activity. [VERIFIED: codebase grep]

**Example:**

```elixir
# Source: accrue/lib/accrue/webhook/ingest.ex and Phase 225 locked D-05
event = Accrue.TestRepo.get_by!(WebhookEvent,
  processor: "stripe", processor_event_id: stripe_event.id)

job = Accrue.TestRepo.one!(from(job in Oban.Job,
  where: job.worker == "Accrue.Webhook.DispatchWorker" and
         job.args["webhook_event_id"] == ^event.id))

assert job.args["webhook_event_id"] == event.id
assert Accrue.TestRepo.exists?(from(e in Accrue.Events.Event,
  where: e.type == "webhook.received" and e.subject_id == ^to_string(event.id)))
```

### Pattern 2: Make each Playwright capacity unit a separately reported test

**What:** Generate uniquely named tests for a fixed partition (recommended one viewport per test), and perform reset/fixture setup inside each case before running both themes through all existing flows. [CITED: https://playwright.dev/docs/test-parameterize] [VERIFIED: codebase grep]

**When to use:** A deterministic loop exceeds one test’s budget but each coherent partition has bounded work and must preserve all coverage. [CITED: https://playwright.dev/docs/test-timeouts]

**Example:**

```javascript
// Source: Playwright parameterization docs; preserve existing helpers and projects.
for (const viewport of PHASE191_VIEWPORTS) {
  test(`Page flows remain usable at ${viewport.name}`, async ({ page, request }) => {
    test.setTimeout(/* measured bounded budget */);
    await reset(request);
    const fixtureData = await seedPhase191Matrix(request);
    await page.setViewportSize({ width: viewport.width, height: viewport.height });

    for (const theme of ["light", "dark"]) {
      for (const flow of phase191PageFlows()) {
        await login(page, resolvePhase191Route(flow, fixtureData));
        await setPhase191Theme(page, theme);
        // Retain every existing clip, focus, scroll, and copy assertion.
      }
    }
  });
}
```

### Anti-Patterns to Avoid

- **Whole-table `length == 1` or aggregate-count assertions:** They prove unrelated rows are absent, not that this event was ingested correctly. [VERIFIED: codebase grep]
- **Calling a successful path “rollback proof”:** The current test comment explicitly says it does not simulate Oban failure; rename it unless a deterministic failure seam and rollback assertion are actually added. [VERIFIED: codebase grep]
- **Raising one global/test timeout:** A test timeout applies to the whole test body, fixtures, and `beforeEach`; it does not create independently observable failure units. [CITED: https://playwright.dev/docs/test-timeouts]
- **Retries, sleeps, or work-serialization:** These obscure the relevant failure mode and violate D-06/D-10. [VERIFIED: codebase grep]
- **Describing `phase192-generated-evidence` as available because an upload step exists:** All five configured source files are absent locally, and `if-no-files-found: ignore` means the upload does not prove production. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Test partition/result reporting | Custom shell loop or CI matrix | Native Playwright uniquely named parameterized tests | Native test cases retain reporter, trace, screenshot, timeout, and failure attribution semantics. [CITED: https://playwright.dev/docs/test-parameterize] |
| Browser failure evidence | Custom log/archive collector | Existing Playwright report/test-results plus `actions/upload-artifact` steps | The workflow already has required always-run artifact affordances and contract checks. [VERIFIED: codebase grep] |
| Webhook identity proof | New transaction spy/mock framework | Existing persisted `WebhookEvent`, `Oban.Job`, and ledger records | The application makes these durable transactional outcomes queryable already. [VERIFIED: codebase grep] |

**Key insight:** This is not a need for a new CI framework or new testing dependency; the existing production identities and Playwright runner already provide the correct observability boundaries. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Fixing the symptom by reducing proof

**What goes wrong:** A retry, deleted assertion, serialized suite, or matrix/gate change turns red green while the causal defect remains. [VERIFIED: codebase grep]

**Why it happens:** Global-count assertions and a monolithic test produce frustrating failures, making mask-first changes look expedient. [VERIFIED: codebase grep]

**How to avoid:** Make only event-owned assertions and bounded test units; run the static CI contracts before and after workflow/script edits. [VERIFIED: codebase grep]

**Warning signs:** `fail-fast`, `continue-on-error`, required support labels, retries, workers, broad scripts, or artifact names change without an explicit locked decision. [VERIFIED: codebase grep]

### Pitfall 2: Losing coverage while partitioning Page 191

**What goes wrong:** A split changes the test count but silently omits a viewport, theme, flow, or assertion. [VERIFIED: codebase grep]

**Why it happens:** The current coverage is implicit in nested loops. [VERIFIED: codebase grep]

**How to avoid:** Keep the same exported viewport array, `phase191PageFlows()` source, both themes, per-case reset/seed, and original assertion body; add a static/testable coverage invariant if the split makes equivalence non-obvious. [VERIFIED: codebase grep]

**Warning signs:** Fewer than five named partitions, a changed flow length (21), removed dark theme loop, changed `workers: 1`, or changed trace/report configuration. [VERIFIED: codebase grep]

### Pitfall 3: Documenting unproduced evidence

**What goes wrong:** The incident record links an artifact name that CI silently skipped because no source file existed. [VERIFIED: codebase grep]

**Why it happens:** The workflow intentionally uses `if-no-files-found: ignore`, and all five Phase 192 generated-evidence inputs are currently absent locally. [VERIFIED: codebase grep]

**How to avoid:** Locate/recreate the real producer or replace the artifact contract with currently generated, privacy-safe evidence; update the CI contract script in the same patch and validate a fresh Actions run. [VERIFIED: codebase grep]

**Warning signs:** The upload step is green but the artifact browser has no `phase192-generated-evidence` payload. [VERIFIED: codebase grep]

## Code Examples

Verified patterns from official sources and the codebase:

### Per-test timeout boundary

```javascript
// Source: https://playwright.dev/docs/test-timeouts
test("coherent bounded scenario", async ({ page }) => {
  test.setTimeout(60_000);
  // Test body, fixture setup, and beforeEach share this test's budget.
});
```

### Existing CI artifact preservation shape

```yaml
# Source: .github/workflows/ci.yml
- name: Upload Phase 192 Playwright evidence
  if: always()
  uses: actions/upload-artifact@v7
  with:
    name: phase192-admin-playwright-evidence
    path: accrue_admin/test-results
    if-no-files-found: ignore
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| One test owns a full Cartesian browser traversal | Individually reported, bounded generated tests | Phase 225 | Failures identify a viewport/group without globally inflating the budget. [CITED: https://playwright.dev/docs/test-parameterize] |
| Global table cardinality treated as ingest proof | Event-identity-scoped persistence and duplicate-negative contracts | Phase 225 | Tests prove the webhook event’s own behavior despite unrelated suite rows. [VERIFIED: codebase grep] |

**Deprecated/outdated:**

- The current “Oban insert failure causes transaction rollback” test name is inaccurate because its implementation runs a successful insert path; use a truthful co-presence/atomicity name unless implementation adds a deterministic error seam. [VERIFIED: codebase grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `actions/upload-artifact` current upstream tag/version is 7.0.1; the phase does not install or upgrade it. | Standard Stack | None for implementation; retain the workflow’s existing pinned `@v7` reference rather than changing it. |

## Open Questions

1. **Should the misleading rollback test be renamed or receive a deterministic failure seam?**
   - What we know: Its present body proves successful co-presence of three writes, not an Oban insertion failure. [VERIFIED: codebase grep]
   - What's unclear: Whether the repository has an existing injectable repository/Oban failure seam that makes a true rollback test small and trustworthy. [VERIFIED: codebase grep]
   - Recommendation: Inspect `Accrue.Repo.transact/1` and test support before implementation; choose a truthful rename by default, and only add a failure seam if it is narrow, deterministic, and does not expand production API surface. [VERIFIED: codebase grep]

2. **Which generated Phase 192 evidence should be preserved?**
   - What we know: The configured legacy source paths are absent, although the upload step and CI contract require their names. [VERIFIED: codebase grep]
   - What's unclear: Whether an equivalent current generator/output should be restored or whether the artifact contract should point to a replacement. [VERIFIED: codebase grep]
   - Recommendation: Trace the historical generator before editing CI; preserve the report and test-results uploads regardless, then make the generated-evidence contract name and actual producer agree. [VERIFIED: codebase grep]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir / Mix | targeted and full ExUnit proof | ✓ | Erlang/OTP 28 | — [VERIFIED: local environment] |
| PostgreSQL | `Accrue.RepoCase` integration tests | ✓ | local port 5432 accepting connections | — [VERIFIED: local environment] |
| Node / npm | Admin runner and static contracts | ✓ | Node 22.14.0 / npm 11.1.0 | — [VERIFIED: local environment] |
| Playwright | Page 191 browser proof | ✓ | 1.59.1 installed | CI installs Chromium explicitly; local command can install it if absent. [VERIFIED: local environment] |
| Docker | CI service parity investigation only | ✓ | 29.5.2 | Not required for the recommended targeted local commands. [VERIFIED: local environment] |

**Missing dependencies with no fallback:** None. [VERIFIED: local environment]

**Missing dependencies with fallback:** None. [VERIFIED: local environment]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit/Ecto for core; Playwright Test 1.59.1 for Admin browser proof. [VERIFIED: codebase grep] |
| Config file | `accrue_admin/playwright.config.js`; project test configuration is in `accrue`. [VERIFIED: codebase grep] |
| Quick run command | `cd accrue && mix test test/accrue/webhook/ingest_test.exs --warnings-as-errors` (observed 5 tests, 0 failures, 0.2s). [VERIFIED: local command] |
| Full suite command | `cd accrue && mix test --warnings-as-errors`; `cd accrue_admin && npm run e2e:phase191`; then the required CI repair-commit Actions run. [VERIFIED: codebase grep] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REL-01 | Incident record gives each active signature a classification, narrow repro, evidence, and ruled-out causes. | documentation/static contract + manual Actions evidence | `rg -n "INC-.*|classification|narrow repro|fresh repair" .planning/phases/225-required-lane-signal-repair/225-CI-INCIDENTS.md` | ❌ Wave 0 |
| REL-01 | Webhook assertions prove only the created event’s owned rows. | integration | `cd accrue && mix test test/accrue/webhook/ingest_test.exs --warnings-as-errors` | ✅ |
| REL-02 | Page-flow traversal is bounded and retains all viewport/theme/flow coverage. | browser integration | `cd accrue_admin && npm run e2e:phase191` | ✅ |
| REL-02 | Phase 192 job identity, artifact uploads, and command composition remain stable. | static contract | `bash scripts/ci/verify_phase192_ci_contract.sh && bash scripts/ci/verify_phase192_guardrail_contract.sh` | ✅ |
| REL-03 | Same release signature is represented by one incident with required/advisory cells visibly separated. | documentation/static contract | `rg -n "release-gate|Sigra|advisory|Floor|OpenTelemetry" .planning/phases/225-required-lane-signal-repair/225-CI-INCIDENTS.md` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** Run the affected narrow command plus both Phase 192 static contract scripts when CI files/scripts change. [VERIFIED: codebase grep]
- **Per wave merge:** Run the full core suite and `npm run e2e:phase191`. [VERIFIED: codebase grep]
- **Phase gate:** A fresh repair-commit GitHub Actions run must show all three required release cells and `admin-hardening-guardrails` passing, with artifacts available; advisory Sigra remains visibly advisory. [VERIFIED: codebase grep]

### Wave 0 Gaps

- [ ] `.planning/phases/225-required-lane-signal-repair/225-CI-INCIDENTS.md` — durable incident/proof index for REL-01 and REL-03.
- [ ] A checked static invariant or reviewer checklist proving the partition retains 5 viewports × 2 themes × 21 flows and the original assertion set. [VERIFIED: codebase grep]
- [ ] Generated-evidence producer/path audit before asserting `phase192-generated-evidence` availability. [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No auth behavior changes; browser fixtures retain existing login path. [VERIFIED: codebase grep] |
| V3 Session Management | no | No session behavior changes; test partitioning must not alter fixture/login semantics. [VERIFIED: codebase grep] |
| V4 Access Control | no | No authorization behavior changes. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Use exact persisted event identities and do not place raw payloads, secrets, or user data into the incident record. [VERIFIED: codebase grep] |
| V6 Cryptography | no | No cryptographic behavior changes. [VERIFIED: codebase grep] |

### Known Threat Patterns for CI evidence

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Sensitive test/server content copied into repository evidence | Information Disclosure | Keep raw reports/traces/logs as access-controlled Actions artifacts; checked-in incident record contains privacy-safe links and concise classification only. [VERIFIED: codebase grep] |
| Green CI produced by masking instead of repair | Tampering | Preserve assertions, stable checks, required/advisory labels, zero retries, artifacts, and fresh-commit proof. [VERIFIED: codebase grep] |
| Misleading stale artifact link | Repudiation | Link immutable run/job/artifact URLs and record first/last SHA plus fresh repair-run evidence. [VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/225-required-lane-signal-repair/225-CONTEXT.md` - locked phase scope, failure classification, proof bar, and prohibitions. [VERIFIED: codebase grep]
- `.github/workflows/ci.yml` - release matrix, support labels, stable job ID, commands, and artifact configuration. [VERIFIED: codebase grep]
- `accrue/test/accrue/webhook/ingest_test.exs` and `accrue/lib/accrue/webhook/ingest.ex` - current global assertions and durable event/job/ledger identities. [VERIFIED: codebase grep]
- `accrue_admin/e2e/admin-page-flow-phase191.spec.js`, `accrue_admin/playwright.config.js`, and Phase 192 contract scripts - 210-case loop, timeout, one-worker/trace config, CI protection contract. [VERIFIED: codebase grep]
- Local commands - static Phase 192 contracts passed; focused ingest suite passed 5 tests in 0.2s; dependencies are present. [VERIFIED: local command]

### Secondary (MEDIUM confidence)

- [Playwright timeouts](https://playwright.dev/docs/test-timeouts) - timeout applies per test and includes test/fixture/`beforeEach` time. [CITED: https://playwright.dev/docs/test-timeouts]
- [Playwright parameterization](https://playwright.dev/docs/test-parameterize) - uniquely named generated tests and per-case hook pattern. [CITED: https://playwright.dev/docs/test-parameterize]

### Tertiary (LOW confidence)

- `actions/upload-artifact` version metadata is not implementation scope; no new package/action is recommended. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all required tools/dependencies already exist, are pinned locally, and no install is needed. [VERIFIED: local environment]
- Architecture: HIGH - both broken seams and their protected boundaries are directly visible in test/workflow source. [VERIFIED: codebase grep]
- Pitfalls: HIGH - phase decisions and CI contract scripts explicitly prohibit the common masking workarounds. [VERIFIED: codebase grep]

**Research date:** 2026-08-08
**Valid until:** 2026-09-07 (30 days; implementation relies primarily on repository-local contracts).
