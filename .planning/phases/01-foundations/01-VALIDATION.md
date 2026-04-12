---
phase: 1
slug: foundations
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-11
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17+ stdlib) + StreamData 1.3 + Mox 1.2 |
| **Config file** | `accrue/test/test_helper.exs` (Wave 0 creates) |
| **Quick run command** | `cd accrue && mix test --stale` |
| **Full suite command** | `cd accrue && mix test` |
| **Estimated runtime** | ~15 seconds (Phase 1 scope) |

Supplementary checks:
- `mix compile --warnings-as-errors` (must pass in both `with_sigra` and `without_sigra` matrices — Success Criterion #5)
- `mix credo --strict`
- `mix format --check-formatted`
- `mix dialyzer` (PLT built in Wave 0)

---

## Sampling Rate

- **After every task commit:** `mix test --stale && mix compile --warnings-as-errors`
- **After every plan wave:** `mix test` + `mix credo --strict` + `mix format --check-formatted`
- **Before `/gsd-verify-work`:** Full suite green on `with_sigra` AND `without_sigra` matrices
- **Max feedback latency:** ~20 seconds

---

## Per-Task Verification Map

*Populated by planner. Rows below are placeholders mapped from Phase 1 success criteria to requirement IDs.*

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 1-01-01 | 01 | 0 | FND-01 | — | N/A | unit+property | `mix test test/accrue/money_test.exs` | ❌ W0 | ⬜ pending |
| 1-01-02 | 01 | 0 | FND-01 | — | Mismatched currency raises | property | `mix test test/accrue/money_property_test.exs` | ❌ W0 | ⬜ pending |
| 1-02-01 | 02 | 0 | FND-02 | — | N/A | unit | `mix test test/accrue/error_test.exs` | ❌ W0 | ⬜ pending |
| 1-02-02 | 02 | 0 | FND-03 | — | N/A | unit | `mix test test/accrue/config_test.exs` | ❌ W0 | ⬜ pending |
| 1-02-03 | 02 | 0 | OBS-01, OBS-06 | — | N/A | unit | `mix test test/accrue/telemetry_test.exs` | ❌ W0 | ⬜ pending |
| 1-03-01 | 03 | 0 | EVT-01, EVT-02, EVT-03 | T-EVT-01 (tamper) | Trigger raises on UPDATE/DELETE with SQLSTATE 45A01 | integration | `mix test test/accrue/events/immutability_test.exs` | ❌ W0 | ⬜ pending |
| 1-03-02 | 03 | 0 | EVT-07, EVT-08 | — | Idempotency key dedupes | integration | `mix test test/accrue/events/record_test.exs` | ❌ W0 | ⬜ pending |
| 1-04-01 | 04 | 0 | PROC-01, PROC-03, PROC-07 | — | Fake processor deterministic IDs + test clock | unit | `mix test test/accrue/processor/fake_test.exs` | ❌ W0 | ⬜ pending |
| 1-04-02 | 04 | 0 | PROC-01 | T-PROC-01 (error leakage) | Stripe errors mapped to Accrue.Error, no lattice_stripe leakage | unit (Mox) | `mix test test/accrue/processor/stripe_test.exs` | ❌ W0 | ⬜ pending |
| 1-05-01 | 05 | 0 | MAIL-01 | — | Oban-safe atoms+IDs only in worker args | unit (Mox) | `mix test test/accrue/mailer_test.exs` | ❌ W0 | ⬜ pending |
| 1-05-02 | 05 | 0 | PDF-01 | — | Shape B HTML→PDF, test adapter sends message | unit (Mox) | `mix test test/accrue/pdf_test.exs` | ❌ W0 | ⬜ pending |
| 1-05-03 | 05 | 0 | AUTH-01, AUTH-02 | T-AUTH-01 (prod no-auth) | Prod refuses to boot with Default adapter | unit | `mix test test/accrue/auth_test.exs` | ❌ W0 | ⬜ pending |
| 1-06-01 | 06 | 0 | FND-04, FND-05, FND-06, FND-07, OSS-11 | — | Conditional compile works in both matrices | integration | `scripts/ci/compile_matrix.sh` | ❌ W0 | ⬜ pending |
| 1-06-02 | 06 | 0 | TEST-01 | — | CI green on 1.17/27 and 1.18/27 | integration | `.github/workflows/ci.yml` exists + passes | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `accrue/mix.exs` — project scaffold with all locked deps from CLAUDE.md
- [ ] `accrue/test/test_helper.exs` — ExUnit.start, Mox setup, StreamData config
- [ ] `accrue/test/support/mox_setup.ex` — `Mox.defmock` for `Accrue.ProcessorMock`, `Accrue.MailerMock`, `Accrue.PDFMock`, `Accrue.AuthMock`
- [ ] `accrue/test/support/data_case.ex` — DB setup for event ledger tests (Postgres sandbox)
- [ ] `accrue/test/support/factories.ex` — minimal factory helpers (no ExMachina — hand-rolled to keep deps lean)
- [ ] `accrue_admin/mix.exs` — scaffold with `{:accrue, path: "../accrue"}` + LiveView 1.1
- [ ] `.github/workflows/ci.yml` — Elixir 1.17/27, 1.18/27, 1.18/28 matrix; `with_sigra` + `without_sigra` sub-matrix; PLT cache
- [ ] `scripts/ci/compile_matrix.sh` — runs `mix compile --warnings-as-errors` in both sigra conditions
- [ ] Dialyzer PLT priming (first-run, cached in CI)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Host-app install flow feels ergonomic | FND-07 | DX judgment, not automatable | Scaffold a throwaway Phoenix app, add `{:accrue, path: "../accrue"}`, run `mix deps.get && mix compile`, verify zero warnings and that `Accrue.Money.new(1000, :usd)` works in iex |
| ChromicPDF adapter renders real PDF on developer machine | PDF-01 | Chrome not required in CI (uses test adapter) | Start `{ChromicPDF, on_demand: true}` in iex, call `Accrue.PDF.ChromicPDF.render("<h1>test</h1>", [])`, verify binary starts with `%PDF-` |
| MJML email renders to readable HTML in Swoosh preview | MAIL-01 | Visual inspection of rendered email | Call `Accrue.Emails.PaymentSucceeded.build(%{...})`, open preview in Swoosh dev mailbox |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 20s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
