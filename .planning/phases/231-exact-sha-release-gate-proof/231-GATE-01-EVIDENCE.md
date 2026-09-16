# GATE-01 Cohort Evidence

Sanitized schema-v1 evidence proving the repository's own declared merge-blocking cohort ran (or was honestly dispositioned) in a fresh, cache-free clone at the exact candidate SHA. No raw payloads, actor identities, secret values, or absolute paths are present.

<!-- phase231-gate01-cohort:start -->

Candidate: `f524f2a6b16d3576829632ab6fa77d24b718e6f7` (observed 2026-09-15T22:53:02-04:00). Checkout: `git clone` from `local repository`, caches_restored=false, worktree_rows_delta=0.

## Failed

1 row(s).

| Job | Lane class | State | Exit code | Argv | Reason | Deferred to | Duration (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| docs-contracts-shift-left | merge-blocking | failed | 1 | `bash scripts/ci/verify_v1_17_friction_research_contract.sh` | First failing step in fail-fast step order (of ~30 total steps); message: 'STATE.md must reference canonical inventory path'. Real GitHub dispatch (GATE-02, plan 231-04) also failed this job. | — | 500 |

## Skipped

1 row(s).

| Job | Lane class | State | Exit code | Argv | Reason | Deferred to | Duration (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| live-stripe | credential-gated | skipped | — | — | Requires repository secrets STRIPE_TEST_SECRET_KEY, STRIPE_WEBHOOK_SECRET, ACCRUE_LIVE_BASIC_PRICE, ACCRUE_LIVE_PRO_PRICE (not present in this local run); the job's own header comment and if: condition additionally state it never runs on pull_request -- outside the merge-blocking cohort by design (D-11). | — | — |

## Non-run

6 row(s).

| Job | Lane class | State | Exit code | Argv | Reason | Deferred to | Duration (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| annotation-sweep | merge-blocking | non_run | — | — | Reads recorded GitHub Actions run annotations for the other 12 merge-blocking jobs via the Actions API against a real workflow run id and a GH token; it has no scratch-clone-local form because there is no local run to sweep annotations from. Its proof is the dispatch run GATE-02 (plan 231-04) produced against this candidate SHA. | GATE-02 | — |
| gh workflow run ci.yml | not-a-declared-gate | non_run | — | — | Corresponds to no job in ci.yml; not a repository-declared local-CI-equivalent gate (D-10). The actual GitHub Actions dispatch is GATE-02's own action (plan 231-04), not a GATE-01 lane. | — | — |
| ios-offline-client | pr-not-merge-blocking | non_run | — | — | Runs on pull_request (if: github.event_name != 'schedule', macos-15 runner) but is deliberately absent from annotation-sweep's needs: array -- outside the declared merge-blocking contract by the repository's own design (D-11), confirmed by declaredMergeBlockingJobs/annotationSweepNeeds live derivation. | — | — |
| mix hex.publish --dry-run | not-a-declared-gate | non_run | — | — | Corresponds to no job in ci.yml; not a repository-declared local-CI-equivalent gate (D-10). Recorded so the Phase 230 thirteen-lane table's disposition is visible, not silently dropped. | — | — |
| provider-proof-incident | scheduler-only | non_run | — | — | needs: [provider-proof-trigger, live-stripe], both of which are non_run/skipped above; never runs on pull_request. | — | — |
| provider-proof-trigger | scheduler-only | non_run | — | — | if: github.event_name == 'schedule' \|\| 'workflow_dispatch' \|\| 'push' -- never runs on pull_request, and this local scratch-clone run has no GitHub Actions event context at all. | — | — |

## Advisory

1 row(s).

| Job | Lane class | State | Exit code | Argv | Reason | Deferred to | Duration (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| admin-ui-ratchet-guardrails | merge-blocking | advisory | 1 | `npm run ratchet:ledger:verify-frozen` | This job's own continue-on-error: true is set in ci.yml (v1.56 ratchet PARKED) -- read live at the candidate SHA, so its failure is recorded advisory, never conflated with a required lane. ratchet:ledger:self-test passed (exit 0); ratchet:ledger:verify-frozen failed (exit 1): ledger.baseline.json frozen:false with confirmed_open findings across multiple lenses, a known pre-existing parked state, not a candidate regression. | — | 3000 |

## Proved

10 row(s).

| Job | Lane class | State | Exit code | Argv | Reason | Deferred to | Duration (ms) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| admin-drift-docs | merge-blocking | proved | 0 | `bash -c cd accrue_admin && mix deps.get && mix accrue_admin.assets.build && git diff --exit-code -- accrue_admin/priv/static/accrue_admin.css accrue_admin/priv/static/accrue_admin.js && grep -q 'accrue_admin "/billing"' accrue_admin/guides/admin_ui.md && grep -q 'accrue_admin.assets.build' accrue_admin/guides/admin_ui.md` | 4 sequential steps, all exit 0; committed asset bundle is fresh | — | 71000 |
| admin-group-contracts | merge-blocking | proved | 0 | `npm run e2e:group-contracts` | verify_phase190_automation_contract.sh ok; compile/npm ci/chromium install ok; 16 tests passed | — | 90000 |
| admin-hardening-guardrails | merge-blocking | proved | 0 | `bash -c bash scripts/ci/verify_phase192_ci_contract.sh && bash scripts/ci/verify_phase192_guardrail_contract.sh && (cd accrue_admin && npm run e2e:phase2142) && bash scripts/ci/verify_phase192_admin_guardrails.sh` | 4 sequential steps, all exit 0 | — | 10000 |
| admin-phase200-guardrails | merge-blocking | proved | 0 | `bash -c bash scripts/ci/verify_phase200_ci_contract.sh && bash scripts/ci/verify_phase200_guardrail_contract.sh && bash scripts/ci/verify_phase200_admin_guardrails.sh` | 3 sequential steps, all exit 0; Phase 200 scorecard/sign-off verifiers PASS, decision=ACCEPT | — | 90000 |
| host-docker-smoke | merge-blocking | proved | 0 | `bash -c docker network create proxy \|\| true; docker compose up --build -d; curl -fsS http://localhost:4000/; docker compose down --volumes --remove-orphans` | boot-ready at 145s (budget 900s); torn down cleanly afterward | — | 145000 |
| host-integration | merge-blocking | proved | 0 | `bash scripts/ci/accrue_host_uat.sh` | delegates to mix verify.full: 219 ExUnit tests + 21 Playwright tests passed (3 skipped); host Hex smoke cleanly skipped (candidate is unpublished, not a release tag) | — | 176000 |
| phase18-tax-gate | merge-blocking | proved | 0 | `mix test test/accrue/billing/invoice_projection_test.exs test/accrue/billing/subscription_projection_tax_test.exs test/accrue/billing/subscription_test.exs test/accrue/checkout_test.exs test/accrue/processor/fake_test.exs test/accrue/processor/stripe_test.exs` | 89 tests, 0 failures | — | 57739 |
| playwright-e2e | merge-blocking | proved | 0 | `bash -c npx playwright test --shard=1/3 && npx playwright test --shard=2/3 && npx playwright test --shard=3/3` | 3-shard matrix, each preceded by a fresh mix ecto.create/migrate + accrue_host_seed_e2e.exs fixture seed; shard 1: 17 passed; shard 2: 0 tests assigned by shard math (17+0+7=24 total); shard 3: 4 passed, 3 skipped | — | 45000 |
| release-gate | merge-blocking | proved | 0 | `bash -c for elixir in 1.19.0-otp-28 1.19.5-otp-28; do for otel in 0 1; do (cd accrue && mix format --check-formatted && mix compile --warnings-as-errors && mix test --warnings-as-errors && mix credo --strict && mix dialyzer --format github && MIX_ENV=dev mix docs --warnings-as-errors && mix hex.audit); done; done; bash scripts/ci/verify_exdoc_since_badges.sh; (cd accrue_admin && mix format --check-formatted && mix compile --warnings-as-errors && mix test --warnings-as-errors && mix credo --strict && mix dialyzer --format github && MIX_ENV=dev mix docs --warnings-as-errors && mix hex.audit); (cd accrue_portal && mix format --check-formatted && mix compile --warnings-as-errors && mix test --warnings-as-errors && mix hex.audit)` | 3 of 4 required/advisory matrix cells exercised for accrue -- Floor (elixir 1.19.0-otp-28, required), Primary (elixir 1.19.5-otp-28, required), Primary+OpenTelemetry (elixir 1.19.5-otp-28, required) -- all 3 fully clean (format/compile/test/credo/cold-PLT-dialyzer/docs/hex.audit); accrue_admin and accrue_portal each run once under Primary, also fully clean. The Primary+sigra advisory cell was not exercised (non-blocking by its own continue-on-error, no local proof value). KNOWN DISCREPANCY, recorded honestly per D-22: the real GATE-02 GitHub Actions dispatch (plan 231-04, run against this same candidate SHA f524f2a6) reported failures in the non-advisory release-gate matrix cells on GitHub-hosted runners; this local scratch-clone proof could NOT reproduce that failure in any of the 3 required cells it exercised. Plausible non-candidate-code explanations not eliminated by this run: local Postgres is 14.17 (Homebrew) vs ci.yml's postgres:15 service container; GitHub-hosted ubuntu-24.04 runner vs local macOS/aarch64; the Floor cell used a freshly-installed asdf Elixir 1.19.0-otp-28 build rather than erlef/setup-beam's exact toolchain. This local proof does not override or supersede GATE-02's real-runner finding -- both are recorded as independent evidence. | — | 420000 |
| release-manifest-ssot | merge-blocking | proved | 0 | `bash -c cd accrue && mix deps.get && bash scripts/ci/verify_release_manifest_alignment.sh && bash scripts/ci/verify_release_contract.sh` | 3 sequential steps, all exit 0 | — | 12000 |

<!-- phase231-gate01-cohort:end -->
