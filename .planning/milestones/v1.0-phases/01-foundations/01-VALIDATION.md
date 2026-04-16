---
phase: 1
slug: foundations
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-11
approved: 2026-04-11
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17+ stdlib) + StreamData 1.3 + Mox 1.2 |
| **Config file** | `accrue/test/test_helper.exs` (Wave 0 / Plan 01 creates) |
| **Quick run command** | `cd accrue && mix test --stale` |
| **Full suite command** | `cd accrue && mix test` |
| **Estimated runtime** | ~15 seconds (Phase 1 scope) |

Supplementary checks:
- `mix compile --warnings-as-errors` (must pass in both `with_sigra` and `without_sigra` matrices — Success Criterion #5)
- `mix credo --strict`
- `mix format --check-formatted`
- `mix dialyzer` (PLT built by Plan 06 / CI)

---

## Sampling Rate

- **After every task commit:** `mix test --stale && mix compile --warnings-as-errors`
- **After every plan wave:** `mix test` + `mix credo --strict` + `mix format --check-formatted`
- **Before `/gsd-verify-work`:** Full suite green on `with_sigra` AND `without_sigra` matrices
- **Max feedback latency:** ~20 seconds

---

## Per-Task Verification Map

Rows map each task in Phase 1's six plans to its requirement, wave, and automated verify command. Task IDs follow `{phase}-{plan}-{task}` convention (e.g. `1-02-01` = Phase 1, Plan 02, Task 1).

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|--------|
| 1-01-01 | 01 | 0 | FND-06 | T-FND-01 | Hex deps pinned, no ex_money_sql | smoke | `cd accrue && mix deps.get && mix compile --warnings-as-errors` | ⬜ pending |
| 1-01-02 | 01 | 0 | OSS-11, FND-06 | T-FND-03 | MIT LICENSE at root, admin path dep resolves | file + smoke | `test -f LICENSE && cd accrue_admin && mix deps.get` | ⬜ pending |
| 1-01-03 | 01 | 0 | TEST-01 | — | Mox harness staged w/ ensure_loaded guards | unit | `cd accrue && mix test` (1 smoke test) | ⬜ pending |
| 1-02-01 | 02 | 1 | FND-01 | T-FND-04 | Money rejects floats/Decimals on new/2; cross-currency raises; money_field/1 macro ships D-02 two-column shape | unit+property | `cd accrue && mix test test/accrue/money_test.exs test/accrue/money_property_test.exs` | ⬜ pending |
| 1-02-02 | 02 | 1 | FND-02, FND-03, OBS-06 | T-FND-05 | 7 defexception structs; SignatureError raise-only; NimbleOptions full Phase 1 schema | unit | `cd accrue && mix test test/accrue/errors_test.exs test/accrue/config_test.exs` | ⬜ pending |
| 1-02-03 | 02 | 1 | FND-04, OBS-01 | T-OBS-01 | Telemetry span emits start/stop/exception; current_trace_id returns nil without OTel | unit | `cd accrue && mix test test/accrue/telemetry_test.exs && mix compile --warnings-as-errors` | ⬜ pending |
| 1-03-01 | 03 | 2 | EVT-02, EVT-08 | T-EVT-01 | Migration creates trigger + actor_type CHECK + REVOKE stub template | integration | `cd accrue && MIX_ENV=test mix ecto.create && MIX_ENV=test mix ecto.migrate` | ⬜ pending |
| 1-03-02 | 03 | 2 | EVT-01, EVT-03, EVT-07 | T-EVT-01, T-EVT-04 | UPDATE/DELETE raises 45A01; Repo wrapper reraises EventLedgerImmutableError; idempotency dedupes | integration | `cd accrue && MIX_ENV=test mix test test/accrue/events/` | ⬜ pending |
| 1-04-01 | 04 | 2 | PROC-01, PROC-03 | — | Fake processor deterministic IDs (cus_fake_00001) + test clock; Mox-compatible behaviour | unit | `cd accrue && mix test test/accrue/processor/fake_test.exs test/accrue/processor/behaviour_test.exs` | ⬜ pending |
| 1-04-02 | 04 | 2 | PROC-07 | T-PROC-01, T-PROC-02, T-PROC-04 | Stripe errors mapped; lattice_stripe only in stripe.ex/error_mapper.ex; secret key runtime-only | unit | `cd accrue && mix test test/accrue/processor/stripe_test.exs && mix compile --warnings-as-errors` | ⬜ pending |
| 1-05-01 | 05 | 2 | MAIL-01 | T-MAIL-01, T-MAIL-02, T-MAIL-03 | Oban-safe args only (only_scalars!); kill switch; MjmlEEx corrected pattern | unit | `cd accrue && mix test test/accrue/mailer_test.exs` | ⬜ pending |
| 1-05-02 | 05 | 2 | PDF-01 | T-PDF-01 | Shape B HTML→PDF facade; Test adapter Chrome-free; ChromicPDF not started by Accrue | unit | `cd accrue && mix test test/accrue/pdf_test.exs` | ⬜ pending |
| 1-05-03 | 05 | 2 | AUTH-01, AUTH-02 | T-AUTH-01 | Default returns dev user in :dev/:test; do_boot_check!(:prod) raises; boot_check!/0 public | unit | `cd accrue && mix test test/accrue/auth_test.exs` | ⬜ pending |
| 1-06-01 | 06 | 3 | FND-05, FND-07 | T-FND-07, T-FND-09 | Accrue.Application boot_check first, empty supervisor, brand.css 7 vars | unit | `cd accrue && mix test test/accrue/application_test.exs && grep -c "^  --accrue-" priv/static/brand.css` | ⬜ pending |
| 1-06-02 | 06 | 3 | — | T-FND-08, T-OSS-01 | Conditional compile Sigra scaffold; CI matrix with sigra=on/off | integration | `cd accrue && mix test test/accrue/integrations/sigra_test.exs && test -f ../.github/workflows/ci.yml && test -x ../scripts/ci/compile_matrix.sh` | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

**Requirement coverage:** FND-01 (1-02-01), FND-02 (1-02-02), FND-03 (1-02-02), FND-04 (1-02-03), FND-05 (1-06-01), FND-06 (1-01-01, 1-01-02), FND-07 (1-06-01), PROC-01 (1-04-01), PROC-03 (1-04-01), PROC-07 (1-04-02), EVT-01 (1-03-02), EVT-02 (1-03-01), EVT-03 (1-03-02), EVT-07 (1-03-02), EVT-08 (1-03-01), AUTH-01 (1-05-03), AUTH-02 (1-05-03), MAIL-01 (1-05-01), PDF-01 (1-05-02), OBS-01 (1-02-03), OBS-06 (1-02-02), TEST-01 (1-01-03), OSS-11 (1-01-02). **23/23 requirements mapped.**

---

## Wave 0 Requirements (all shipped by Plan 01)

- [x] `accrue/mix.exs` — project scaffold with all locked deps from CLAUDE.md
- [x] `accrue/config/config.exs` — sets `config :accrue, :env, Mix.env()` + placeholder adapter keys
- [x] `accrue/config/dev.exs` — Swoosh.Adapters.Local
- [x] `accrue/config/test.exs` — FULL Accrue.TestRepo sandbox stanza + Swoosh.Adapters.Test + `:repo` key
- [x] `accrue/config/runtime.exs` — stub, no secrets
- [x] `accrue/test/test_helper.exs` — ExUnit.start, Mox setup via Accrue.MoxSetup
- [x] `accrue/test/support/mox_setup.ex` — `Mox.defmock` calls guarded by `Code.ensure_loaded?/1`
- [x] `accrue/test/support/data_case.ex` — minimal ExUnit.CaseTemplate; Plan 03 adds Accrue.RepoCase for Repo-backed tests
- [x] `accrue_admin/mix.exs` — scaffold with `{:accrue, path: "../accrue"}` + LiveView 1.1
- [ ] `.github/workflows/ci.yml` — ships in Plan 06 Wave 3
- [ ] `scripts/ci/compile_matrix.sh` — ships in Plan 06 Wave 3
- [ ] Dialyzer PLT priming — CI-side in Plan 06 Wave 3

Note: "Wave 0 Requirements" here means "artifacts that must exist before Wave 1 tests run against them." CI scripts (Plan 06 Wave 3) are genuinely later-wave, not Wave 0 gaps.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Host-app install flow feels ergonomic | FND-07 | DX judgment, not automatable | Scaffold a throwaway Phoenix app, add `{:accrue, path: "../accrue"}`, run `mix deps.get && mix compile`, verify zero warnings and that `Accrue.Money.new(1000, :usd)` works in iex |
| ChromicPDF adapter renders real PDF on developer machine | PDF-01 | Chrome not required in CI (uses test adapter) | Start `{ChromicPDF, on_demand: true}` in iex, call `Accrue.PDF.ChromicPDF.render("<h1>test</h1>", [])`, verify binary starts with `%PDF-` |
| MJML email renders to readable HTML in Swoosh preview | MAIL-01 | Visual inspection of rendered email | Call `Accrue.Emails.PaymentSucceeded.render(%{customer_name: "Test", amount: "$10", invoice_number: "INV-1", receipt_url: "http://x"})`, open preview in Swoosh Local mailbox |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 20s
- [x] `nyquist_compliant: true` set in frontmatter
- [x] All 23 Phase 1 requirement IDs mapped to exactly one plan

**Approval:** 2026-04-11 (revised per plan-checker blockers 1-9)
