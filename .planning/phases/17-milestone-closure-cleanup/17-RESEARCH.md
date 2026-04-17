# Phase 17: Milestone Closure Cleanup - Research

**Researched:** 2026-04-17
**Domain:** milestone-close bookkeeping, docs-contract cleanup, and host browser-fixture scoping [VERIFIED: codebase grep][CITED: .planning/ROADMAP.md]
**Confidence:** HIGH [VERIFIED: codebase grep]

## User Constraints

No phase-specific `*-CONTEXT.md` exists for Phase 17, so there are no additional locked decisions, discretion areas, or deferred ideas beyond the roadmap/audit scope. [VERIFIED: codebase grep]

## Summary

Phase 17 is a cleanup-only phase that closes the six non-critical audit items recorded in `.planning/v1.2-MILESTONE-AUDIT.md`: one roadmap bookkeeping mismatch, one project-bookkeeping mismatch, one over-broad browser seed cleanup in `scripts/ci/accrue_host_seed_e2e.exs`, and three stale docs references in `RELEASING.md`, `guides/testing-live-stripe.md`, and `CONTRIBUTING.md`. No new product requirements are introduced, and the milestone audit explicitly says all 23 v1.2 requirements and all four completed phases already passed. [VERIFIED: codebase grep][CITED: .planning/v1.2-MILESTONE-AUDIT.md]

The highest-risk change is the browser seed cleanup. The current script disables the immutable trigger on `accrue_events` and deletes every `invoice.payment_failed` and `admin.webhook.replay.completed` row for `Subscription` or `WebhookEvent`, regardless of ownership. In a shared migrated test database, that can erase unrelated replay or payment-failed history. The safe pattern is to scope cleanup to the fixture's own webhook row, subscription row, and any events causally linked to those seeded records, mirroring the narrower intent already described in `examples/accrue_host/test/support/host_flow_proof_case.ex`. [VERIFIED: codebase grep][CITED: scripts/ci/accrue_host_seed_e2e.exs][CITED: examples/accrue_host/test/support/host_flow_proof_case.ex]

**Primary recommendation:** Keep this phase strictly on existing planning/docs/test infrastructure: update `.planning/PROJECT.md` bookkeeping, narrow `scripts/ci/accrue_host_seed_e2e.exs` to fixture-owned rows only, fix the three stale docs references, and prove the result with the existing focused docs contracts plus the host trust/browser lane. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Milestone bookkeeping parity | Planning artifacts | — | The mismatch lives in `.planning/PROJECT.md` and `.planning/ROADMAP.md`, not runtime code. [VERIFIED: codebase grep][CITED: .planning/PROJECT.md][CITED: .planning/ROADMAP.md] |
| Browser fixture cleanup safety | Database / Storage | Host test harness | The risk comes from destructive deletes against persisted `accrue_events`, `accrue_webhook_events`, and related host rows during seeded browser setup. [VERIFIED: codebase grep][CITED: scripts/ci/accrue_host_seed_e2e.exs] |
| Release/provider-parity wording | Repository docs | CI workflow | The stale references are in Markdown docs, but the truth source they must match is `.github/workflows/ci.yml`. [VERIFIED: codebase grep][CITED: RELEASING.md][CITED: guides/testing-live-stripe.md][CITED: CONTRIBUTING.md][CITED: .github/workflows/ci.yml] |
| Regression proof | Host integration lane | Docs-contract tests | Existing ExUnit docs contracts and the host integration workflow already enforce most of the target behavior. [VERIFIED: codebase grep][CITED: accrue/test/accrue/docs/release_guidance_test.exs][CITED: accrue/test/accrue/docs/package_docs_verifier_test.exs][CITED: .github/workflows/ci.yml] |

## Project Constraints (from CLAUDE.md)

- Work inside the locked stack: Elixir 1.17+, OTP 27+, Phoenix 1.8+, Ecto 3.12+, PostgreSQL 14+. [VERIFIED: codebase grep][CITED: CLAUDE.md]
- Keep `accrue/` core LiveView-free; `phoenix_live_view` stays a hard dependency only in `accrue_admin`. [VERIFIED: codebase grep][CITED: CLAUDE.md]
- Webhook signature verification remains mandatory and non-bypassable; raw-body handling stays before `Plug.Parsers`. [VERIFIED: codebase grep][CITED: CLAUDE.md]
- Sensitive Stripe fields, webhook secrets, customer data, and PII must stay out of docs, logs, artifacts, and copied outputs. [VERIFIED: codebase grep][CITED: CLAUDE.md]
- Webhook request-path performance target remains `<100ms p99` for verify -> persist -> enqueue -> 200. [VERIFIED: codebase grep][CITED: CLAUDE.md]
- Shared workflow guidance says file edits should happen through GSD flow, and this phase is already being handled as a GSD research artifact. [VERIFIED: codebase grep][CITED: CLAUDE.md]

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | Local `1.19.5`; repo floor `1.17+` | Edit and validate planning/docs/test scripts in the existing repo toolchain | All affected scripts/tests are Elixir or Mix-driven. [VERIFIED: codebase grep][CITED: CLAUDE.md][VERIFIED: local command] |
| Ecto | `3.13.5` | Query/delete only the fixture-owned rows in the seed script | The risky cleanup is already implemented with `Ecto.Query` and should stay there. [VERIFIED: codebase grep][CITED: scripts/ci/accrue_host_seed_e2e.exs][CITED: examples/accrue_host/mix.lock] |
| PostgreSQL | Local `14.17`; repo floor `14+` | Backing store for the host test DB and immutable event trigger behavior | The cleanup risk exists because deletes hit persisted Postgres rows and toggle a trigger. [VERIFIED: local command][CITED: CLAUDE.md][CITED: scripts/ci/accrue_host_seed_e2e.exs] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| ExUnit docs contracts | Bundled with Elixir `1.19.5` | Lock release/docs wording and shell-verifier behavior | Use for any docs wording change in `RELEASING.md`, `guides/testing-live-stripe.md`, or `CONTRIBUTING.md`. [VERIFIED: codebase grep][CITED: accrue/test/accrue/docs/release_guidance_test.exs][CITED: accrue/test/accrue/docs/package_docs_verifier_test.exs][VERIFIED: local command] |
| `scripts/ci/verify_package_docs.sh` | Repo script | Fast fixed-invariant grep gate for README/release/trust docs | Use after docs edits or when adding one more invariant to keep wording from drifting again. [VERIFIED: codebase grep][CITED: scripts/ci/verify_package_docs.sh] |
| Playwright host lane | Declared `@playwright/test ^1.57.0`, lockfile `1.59.1`; `@axe-core/playwright ^4.11.1` | Proves the seeded browser trust flow still works after fixture cleanup changes | Use through `mix verify.full` or `bash scripts/ci/accrue_host_uat.sh`, not by inventing a new lane. [VERIFIED: codebase grep][CITED: examples/accrue_host/package.json][CITED: examples/accrue_host/package-lock.json][CITED: examples/accrue_host/mix.exs] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Narrow fixture-owned deletes | Full DB reset or broader type-based deletes | Faster to write, but it destroys shared history and repeats the exact audit risk. [VERIFIED: codebase grep][CITED: scripts/ci/accrue_host_seed_e2e.exs] |
| Existing docs contracts + verifier | Manual doc review only | Lower implementation effort, but drift already happened on three docs surfaces despite human review. [VERIFIED: codebase grep][CITED: .planning/v1.2-MILESTONE-AUDIT.md][CITED: accrue/test/accrue/docs/release_guidance_test.exs] |

**Installation:**
```bash
# No new packages required for Phase 17.
```

## Architecture Patterns

### System Architecture Diagram

```text
Milestone audit findings
        |
        v
  Planning/docs/test surfaces
  |          |             |
  |          |             +--> RELEASING.md / CONTRIBUTING.md / guides/testing-live-stripe.md
  |          |                     |
  |          |                     v
  |          |               ExUnit docs contracts + shell verifier
  |          |
  |          +--> scripts/ci/accrue_host_seed_e2e.exs
  |                              |
  |                              v
  |                       Ecto-scoped deletes against host test DB
  |                              |
  |                              v
  |                       mix verify.full / host-integration
  |
  +--> .planning/PROJECT.md and .planning/ROADMAP.md
             |
             v
      Milestone close bookkeeping parity
```

### Recommended Project Structure

```text
.planning/
├── PROJECT.md                     # milestone checklist/state summary
├── ROADMAP.md                     # milestone and phase status
└── phases/17-milestone-closure-cleanup/
    └── 17-RESEARCH.md             # this artifact

scripts/ci/
└── accrue_host_seed_e2e.exs       # browser fixture seeding + cleanup

accrue/test/accrue/docs/
├── release_guidance_test.exs      # wording contract
└── package_docs_verifier_test.exs # shell verifier wrapper

guides/
└── testing-live-stripe.md         # provider-parity docs
```

### Pattern 1: Bookkeeping Parity Through Existing Planning Records
**What:** Update the one unchecked v1.2 demo requirement in `.planning/PROJECT.md` so it matches the already-complete status in `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, and the audit. [VERIFIED: codebase grep][CITED: .planning/PROJECT.md][CITED: .planning/ROADMAP.md][CITED: .planning/REQUIREMENTS.md][CITED: .planning/v1.2-MILESTONE-AUDIT.md]
**When to use:** Any milestone-close phase that resolves planning-state drift without changing product scope. [VERIFIED: codebase grep]
**Example:**
```text
.planning/PROJECT.md line 61 is still unchecked, while Phase 13 is already complete in ROADMAP line 39 and the audit says DEMO-01..06 plus ADOPT-02 are verified.
```
Source: `.planning/PROJECT.md`, `.planning/ROADMAP.md`, `.planning/v1.2-MILESTONE-AUDIT.md`. [VERIFIED: codebase grep]

### Pattern 2: Scope Fixture Cleanup by Fixture Identity, Not Event Type
**What:** Delete only rows owned by the seeded browser fixture, using stable processor IDs, seeded emails, known webhook IDs, or causal foreign keys such as `caused_by_webhook_event_id`, instead of deleting all rows of a matching event type. [VERIFIED: codebase grep][CITED: scripts/ci/accrue_host_seed_e2e.exs]
**When to use:** Any seed/reset script that runs against a migrated shared test database with durable history. [VERIFIED: codebase grep][CITED: examples/accrue_host/test/support/host_flow_proof_case.ex]
**Example:**
```elixir
# Source: scripts/ci/accrue_host_seed_e2e.exs / examples/accrue_host/test/support/host_flow_proof_case.ex
Repo.delete_all(
  from(webhook in WebhookEvent,
    where: webhook.processor_event_id in ["evt_host_browser_replay", "evt_host_browser_first_run"]
  )
)
```

### Pattern 3: Tie Docs Copy to Real Workflow Names
**What:** Docs should name the current CI jobs and trust lane exactly as they appear in `.github/workflows/ci.yml`, or stay generic enough that job renames do not invalidate them. [VERIFIED: codebase grep][CITED: .github/workflows/ci.yml]
**When to use:** Release guidance, contributor setup, and provider-parity guides. [VERIFIED: codebase grep]
**Example:**
```text
Current workflow jobs are `release-gate`, `admin-drift-docs`, `host-integration`, `annotation-sweep`, and `live-stripe`; there is no primary `test` job.
```
Source: `.github/workflows/ci.yml`. [VERIFIED: codebase grep]

### Anti-Patterns to Avoid

- **Broad event deletion after disabling immutability:** The current seed script deletes all matching payment-failed/replay events and can wipe unrelated test history. [VERIFIED: codebase grep][CITED: scripts/ci/accrue_host_seed_e2e.exs]
- **Fixing docs without strengthening the contracts:** The stale references already survived existing prose review once; keep the ExUnit + shell verifier path in the change. [VERIFIED: codebase grep][CITED: .planning/v1.2-MILESTONE-AUDIT.md]
- **Updating only one planning artifact:** `.planning/PROJECT.md` and `.planning/ROADMAP.md` are both milestone-close sources of truth and must remain consistent. [VERIFIED: codebase grep][CITED: .planning/PROJECT.md][CITED: .planning/ROADMAP.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Docs drift detection | A new bespoke docs checker | `accrue/test/accrue/docs/release_guidance_test.exs` plus `scripts/ci/verify_package_docs.sh` | The repo already has executable coverage for release/trust wording and fixed grep invariants. [VERIFIED: codebase grep][CITED: accrue/test/accrue/docs/release_guidance_test.exs][CITED: scripts/ci/verify_package_docs.sh] |
| Browser trust verification | A one-off Phase 17 browser command | `mix verify.full` and `bash scripts/ci/accrue_host_uat.sh` | The host lane already seeds browser state, runs smoke/browser checks, and is wired into CI. [VERIFIED: codebase grep][CITED: examples/accrue_host/mix.exs][CITED: scripts/ci/accrue_host_uat.sh][CITED: .github/workflows/ci.yml] |
| Shared DB cleanup | TRUNCATE/reset-all logic | Targeted `Repo.delete_all` queries keyed to fixture-owned rows | Shared-history preservation is the explicit success criterion, so destructive reset logic is the wrong tool. [VERIFIED: codebase grep][CITED: .planning/ROADMAP.md][CITED: scripts/ci/accrue_host_seed_e2e.exs] |

**Key insight:** This phase succeeds by tightening existing guardrails, not by expanding infrastructure. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Deleting Unrelated History While Reseeding Browser Fixtures
**What goes wrong:** Rerunning the browser seed script deletes unrelated `invoice.payment_failed` or `admin.webhook.replay.completed` rows from the shared test DB. [VERIFIED: codebase grep][CITED: scripts/ci/accrue_host_seed_e2e.exs]
**Why it happens:** The delete predicate filters by event type and subject type only, after disabling the immutable trigger. [VERIFIED: codebase grep][CITED: scripts/ci/accrue_host_seed_e2e.exs]
**How to avoid:** Scope deletes to the seeded webhook IDs, subscription/customer IDs, seeded emails, and event causal links created by the fixture. [VERIFIED: codebase grep][CITED: scripts/ci/accrue_host_seed_e2e.exs][CITED: examples/accrue_host/test/support/host_flow_proof_case.ex]
**Warning signs:** A rerun makes unrelated webhook replay or payment-failed history disappear from `/billing/events` or webhook detail pages. [VERIFIED: codebase grep][CITED: scripts/ci/accrue_host_browser_smoke.cjs]

### Pitfall 2: Leaving Milestone State Split Across Planning Files
**What goes wrong:** The milestone audit still reports bookkeeping debt even though execution and verification are complete. [VERIFIED: codebase grep][CITED: .planning/v1.2-MILESTONE-AUDIT.md]
**Why it happens:** `.planning/PROJECT.md` has one unchecked canonical-demo bullet while the roadmap, requirements, and audit all record completion. [VERIFIED: codebase grep][CITED: .planning/PROJECT.md][CITED: .planning/ROADMAP.md][CITED: .planning/REQUIREMENTS.md]
**How to avoid:** Treat `.planning/PROJECT.md`, `.planning/ROADMAP.md`, and the audit as a parity set during milestone close. [VERIFIED: codebase grep]
**Warning signs:** An audit mentions “bookkeeping debt” even though the phase detail and verification files are green. [VERIFIED: codebase grep][CITED: .planning/v1.2-MILESTONE-AUDIT.md]

### Pitfall 3: Naming CI Jobs That No Longer Exist
**What goes wrong:** Docs send maintainers to a “primary test job” or the wrong browser lane path. [VERIFIED: codebase grep][CITED: guides/testing-live-stripe.md][CITED: CONTRIBUTING.md]
**Why it happens:** Workflow job names changed to `release-gate` and `host-integration`, but docs still refer to older or generic names. [VERIFIED: codebase grep][CITED: .github/workflows/ci.yml]
**How to avoid:** Anchor docs to current job names or to stable lane descriptions already enforced by the release guidance tests. [VERIFIED: codebase grep][CITED: accrue/test/accrue/docs/release_guidance_test.exs]
**Warning signs:** Grepping docs for `Phase 9`, `primary \`test\` job`, or `accrue_admin` browser UAT returns stale matches. [VERIFIED: codebase grep]

## Code Examples

Verified patterns from the existing codebase:

### Fixture-Owned Webhook Cleanup
```elixir
# Source: scripts/ci/accrue_host_seed_e2e.exs
Repo.delete_all(
  from(webhook in WebhookEvent,
    where: webhook.processor_event_id in ["evt_host_browser_replay", "evt_host_browser_first_run"]
  )
)
```

### Existing Host Trust Lane Contract
```elixir
# Source: examples/accrue_host/test/mix_alias_contract_test.exs
assert source =~ "test/accrue_host_web/trust_smoke_test.exs"
assert source =~ ~s|"verify.full"|
assert source =~ "npm run e2e"
```

### Existing Release Guidance Contract
```elixir
# Source: accrue/test/accrue/docs/release_guidance_test.exs
assert releasing =~ "Provider parity: Stripe test mode"
assert releasing =~ "Advisory/manual: live Stripe"
refute releasing =~ "Stripe test mode is required for every release"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Generic or stale release-lane wording (`Phase 9 release gate`, `primary test job`, browser UAT in `accrue_admin`) | Docs must align to the current deterministic host lane and named CI jobs | Drift detected in the 2026-04-17 v1.2 audit | Phase 17 should correct wording and keep it under test so milestone-close docs stay trustworthy. [VERIFIED: codebase grep][CITED: .planning/v1.2-MILESTONE-AUDIT.md][CITED: .github/workflows/ci.yml] |
| Broad type-based event cleanup | Fixture-identity-scoped cleanup | Needed now; the audit flagged the broad delete on 2026-04-17 | Prevents the browser seed from erasing unrelated shared DB history. [VERIFIED: codebase grep][CITED: scripts/ci/accrue_host_seed_e2e.exs][CITED: .planning/v1.2-MILESTONE-AUDIT.md] |

**Deprecated/outdated:**
- `Phase 9 release gate` wording in `RELEASING.md` is stale against current CI and should be removed or renamed to the current deterministic gate language. [VERIFIED: codebase grep][CITED: RELEASING.md][CITED: .github/workflows/ci.yml]
- `primary test job` wording in `guides/testing-live-stripe.md` is stale because the workflow defines `release-gate`, `admin-drift-docs`, `host-integration`, `annotation-sweep`, and `live-stripe`, not `test`. [VERIFIED: codebase grep][CITED: guides/testing-live-stripe.md][CITED: .github/workflows/ci.yml]
- `Node.js for browser UAT in accrue_admin` in `CONTRIBUTING.md` is stale because the browser trust lane runs from `examples/accrue_host`. [VERIFIED: codebase grep][CITED: CONTRIBUTING.md][CITED: .github/workflows/ci.yml]

## Assumptions Log

All material claims in this research were verified in this session against the local codebase or local environment. [VERIFIED: codebase grep][VERIFIED: local command]

## Open Questions

1. **Which exact event linkage should the narrowed seed cleanup use for `accrue_events` deletes?**
   - What we know: broad type-based deletion is unsafe, and the fixture creates a known webhook row plus a known replay-visible event path. [VERIFIED: codebase grep][CITED: scripts/ci/accrue_host_seed_e2e.exs]
   - What's unclear: whether the cleanest query should key off `caused_by_webhook_event_id`, `actor_id`, explicit subject IDs, or a combination. [VERIFIED: codebase grep]
   - Recommendation: decide this in planning after reading the `Accrue.Events.Event` schema fields touched by the fixture and pick the narrowest predicate that still survives reruns. [VERIFIED: codebase grep]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Mix | ExUnit docs contracts, Mix aliases, seed script validation | ✓ | Elixir `1.19.5` | — [VERIFIED: local command] |
| Node.js | Host browser trust lane | ✓ | `v22.14.0` | — [VERIFIED: local command] |
| npm | Playwright install/run | ✓ | `11.1.0` | — [VERIFIED: local command] |
| PostgreSQL CLI | Local DB inspection and parity with repo floor | ✓ | `14.17` | — [VERIFIED: local command] |

**Missing dependencies with no fallback:**
- None found. [VERIFIED: local command]

**Missing dependencies with fallback:**
- None found. [VERIFIED: local command]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (bundled with Elixir `1.19.5`) + Playwright lockfile `1.59.1` [VERIFIED: local command][CITED: examples/accrue_host/package-lock.json] |
| Config file | `examples/accrue_host/playwright.config.js`; ExUnit via Mix projects [VERIFIED: codebase grep] |
| Quick run command | `cd accrue && mix test test/accrue/docs/release_guidance_test.exs test/accrue/docs/package_docs_verifier_test.exs --trace` [VERIFIED: codebase grep] |
| Full suite command | `bash scripts/ci/accrue_host_uat.sh` [VERIFIED: codebase grep][CITED: scripts/ci/accrue_host_uat.sh] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AUDIT-17-01 | Release/provider-parity/contributor docs match current lanes and wording | docs contract + shell verifier | `cd accrue && mix test test/accrue/docs/release_guidance_test.exs test/accrue/docs/package_docs_verifier_test.exs --trace && bash ../scripts/ci/verify_package_docs.sh` | ✅ [VERIFIED: codebase grep] |
| AUDIT-17-02 | Host trust/browser lane still passes after narrowing fixture cleanup | focused host + browser lane | `bash scripts/ci/accrue_host_uat.sh` | ✅ [VERIFIED: codebase grep] |
| AUDIT-17-03 | Seeded webhook ingest smoke still holds | focused host smoke | `cd examples/accrue_host && mix test test/accrue_host_web/trust_smoke_test.exs --trace` | ✅ [VERIFIED: codebase grep] |

### Sampling Rate

- **Per task commit:** `cd accrue && mix test test/accrue/docs/release_guidance_test.exs test/accrue/docs/package_docs_verifier_test.exs --trace` for docs changes, and `cd examples/accrue_host && mix test test/accrue_host_web/trust_smoke_test.exs --trace` when editing the seed script. [VERIFIED: codebase grep]
- **Per wave merge:** `bash scripts/ci/accrue_host_uat.sh`. [VERIFIED: codebase grep]
- **Phase gate:** Full host integration lane green plus docs verifier green before milestone archival. [VERIFIED: codebase grep][CITED: .planning/ROADMAP.md]

### Wave 0 Gaps

None — existing docs contracts, shell verifier, and host trust/browser lane cover the Phase 17 cleanup surface. [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase 17 does not change auth flows; it only touches docs and test cleanup. [VERIFIED: codebase grep] |
| V3 Session Management | no | No session code is in scope. [VERIFIED: codebase grep] |
| V4 Access Control | yes | Keep browser/admin trust verification on the existing host lane instead of bypassing it after fixture cleanup edits. [VERIFIED: codebase grep][CITED: .github/workflows/ci.yml] |
| V5 Input Validation | yes | Keep cleanup queries explicit and fixture-scoped through Ecto, rather than broad deletes driven by loose string matching. [VERIFIED: codebase grep][CITED: scripts/ci/accrue_host_seed_e2e.exs] |
| V6 Cryptography | no | No cryptography implementation changes are needed in this phase. [VERIFIED: codebase grep] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Shared-test-data destruction from broad cleanup | Tampering | Scope deletes to fixture-owned rows only; rerun `trust_smoke_test` and host browser lane after changes. [VERIFIED: codebase grep][CITED: scripts/ci/accrue_host_seed_e2e.exs] |
| Stale docs weaken release/operator trust decisions | Spoofing / Repudiation | Keep release wording under `release_guidance_test.exs` and `verify_package_docs.sh`. [VERIFIED: codebase grep][CITED: accrue/test/accrue/docs/release_guidance_test.exs][CITED: scripts/ci/verify_package_docs.sh] |
| Leakage through retained browser artifacts or copied logs | Information Disclosure | Preserve the existing failure-only trace/screenshot policy and no-secrets docs wording. [VERIFIED: codebase grep][CITED: examples/accrue_host/playwright.config.js][CITED: accrue/test/accrue/docs/trust_leakage_test.exs] |

## Sources

### Primary (HIGH confidence)

- `.planning/v1.2-MILESTONE-AUDIT.md` - exact tech-debt items and audit scope. [VERIFIED: codebase grep]
- `.planning/PROJECT.md` - canonical-demo checklist mismatch. [VERIFIED: codebase grep]
- `.planning/ROADMAP.md` - Phase 17 goal/success criteria and current phase statuses. [VERIFIED: codebase grep]
- `scripts/ci/accrue_host_seed_e2e.exs` - current broad cleanup behavior. [VERIFIED: codebase grep]
- `examples/accrue_host/test/support/host_flow_proof_case.ex` - existing narrow cleanup intent in host tests. [VERIFIED: codebase grep]
- `RELEASING.md`, `guides/testing-live-stripe.md`, `CONTRIBUTING.md` - stale wording targets. [VERIFIED: codebase grep]
- `.github/workflows/ci.yml` - current job names and trust-lane wiring. [VERIFIED: codebase grep]
- `accrue/test/accrue/docs/release_guidance_test.exs`, `accrue/test/accrue/docs/package_docs_verifier_test.exs`, `scripts/ci/verify_package_docs.sh` - existing verification surfaces. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)

- `examples/accrue_host/package.json` and `examples/accrue_host/package-lock.json` - declared and locked Playwright versions. [VERIFIED: codebase grep]
- Local environment probes (`elixir --version`, `node --version`, `npm --version`, `psql --version`) - execution environment availability. [VERIFIED: local command]

### Tertiary (LOW confidence)

- None. [VERIFIED: codebase grep]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Phase 17 uses existing repo tooling only, and versions/availability were verified locally or from lockfiles. [VERIFIED: codebase grep][VERIFIED: local command]
- Architecture: HIGH - The affected surfaces and verification hooks are explicit in the audit, workflow, and codebase. [VERIFIED: codebase grep]
- Pitfalls: HIGH - The key risks are directly named in the audit and reproducible from the current seed script/docs state. [VERIFIED: codebase grep]

**Research date:** 2026-04-17
**Valid until:** 2026-05-17
