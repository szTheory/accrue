---
phase: 08-install-polish-testing
verified: 2026-04-15T23:10:12Z
status: human_needed
score: 8/8 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 6/8
  gaps_closed:
    - "Fresh installs provide test-support wiring that lets host tests assert billing behavior without real SMTP"
    - "TEST-07 mock adapters are complete, including Accrue.Auth.Mock, Accrue.Mailer.Test, and Accrue.PDF.Test"
  gaps_remaining: []
  regressions: []
human_verification:
  - test: "Fresh Phoenix install timing"
    expected: "Run `mix accrue.install` in a new Phoenix app and reach Stripe test-mode-ready generated billing wiring in about 30 seconds, or get a clear actionable setup error."
    why_human: "The automated fixture verifies generated artifacts and wiring, but not real local developer timing in a freshly generated Phoenix project."
  - test: "Host DataCase copy-paste flow"
    expected: "Generated `test/support/accrue_case.ex` plus host test config lets `assert_email_sent/2`, `assert_pdf_rendered/1`, and `assert_event_recorded/1` pass without Stripe, Chrome, or SMTP."
    why_human: "The library tests verify the helpers and generated snippets separately; a copied host test-support flow should still be exercised in a real Phoenix app."
  - test: "Admin mount protection in host router"
    expected: "The generated Accrue Admin mount is protected by the host auth pipeline in an actual Phoenix router."
    why_human: "The installer emits the mount/auth snippets, but route protection depends on host router placement and policy decisions."
---

# Phase 8: Install + Polish + Testing Verification Report

**Phase Goal:** A Phoenix developer can run `mix accrue.install` in a fresh app and be running against Stripe test mode within 30 seconds, with generated migrations + `MyApp.Billing` context + router mounts + webhook endpoint + admin routes when `accrue_admin` is present + Sigra wiring when present, and have a complete test helper suite to assert billing behavior without hitting Stripe, Chrome, or real SMTP.
**Verified:** 2026-04-15T23:10:12Z
**Status:** human_needed
**Re-verification:** Yes - after gap closure plans 08-08 and 08-09.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Fresh install generates migrations, `MyApp.Billing`, router/webhook/admin wiring, and config validation | VERIFIED | Installer task calls Options/Project/Templates/Fingerprints/Patches; templates include migrations, billing context, handler, runtime config, Stripe test-mode readiness, and config validation. |
| 2 | Re-running install is idempotent and avoids clobbering user edits | VERIFIED | Fingerprint writer and installer tests cover pristine generated files and user-edited file skips. Custom admin mount idempotency remains a warning, not a default-flow blocker. |
| 3 | `advance_clock/2` and `trigger_event/2` work without sleeps or bypassing webhook reducer path | VERIFIED | `Accrue.Test.Clock` drives `Accrue.Processor.Fake`; `Accrue.Test.Webhooks` persists through `Accrue.Webhook.Ingest` and dispatches via `DefaultHandler`. |
| 4 | Email, PDF, and event assertion helpers are available and fail with useful diagnostics | VERIFIED | `use Accrue.Test` imports mail/PDF/event assertions; targeted helper tests passed. |
| 5 | Sigra is auto-wired when present and default auth warning exists when absent | VERIFIED | Installer emits `Accrue.Integrations.Sigra` when detected and `Accrue.Auth.Default` prod-safety warning otherwise. |
| 6 | OTel spans wrap Billing functions when available and compile cleanly with/without OTel | VERIFIED | `Accrue.Telemetry.span/3` delegates to optional `Accrue.Telemetry.OTel`; compile gate passed. |
| 7 | Fresh install test-support wiring avoids real SMTP | VERIFIED | `patches.ex` now emits `config :accrue, :mailer, Accrue.Mailer.Test`, matching `Accrue.Mailer.impl/0`; regression asserts absence of stale `:mailer_adapter` snippet. |
| 8 | TEST-07 named mock adapters are complete | VERIFIED | `Accrue.Auth.Mock`, `Accrue.Mailer.Test`, and `Accrue.PDF.Test` all load; auth mock exports the full callback/helper surface and refuses `:prod`. |

**Score:** 8/8 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `accrue/lib/mix/tasks/accrue.install.ex` | Installer CLI orchestration | VERIFIED | Calls option parsing, project discovery, template rendering, fingerprinted writes, patches, config docs, and validation. |
| `accrue/lib/accrue/install/patches.ex` | Router/admin/auth/test-support/Oban snippets | VERIFIED | Emits scoped webhook route, admin mount, Sigra/default auth, Oban queues, and correct test mailer key. |
| `accrue/lib/mix/tasks/accrue.gen.handler.ex` | Handler generator | VERIFIED | Uses strict options, handler template rendering, and fingerprint no-clobber policy. |
| `accrue/lib/accrue/test.ex` | Public testing facade | VERIFIED | Imports assertions and exposes Fake setup/action helpers. |
| `accrue/lib/accrue/test/clock.ex` | Deterministic clock helper | VERIFIED | Uses Fake processor advancement, no sleeps found. |
| `accrue/lib/accrue/test/webhooks.ex` | Synthetic webhook helper | VERIFIED | Routes through ingest and default handler path. |
| `accrue/lib/accrue/test/event_assertions.ex` | Event ledger assertions | VERIFIED | Queries `Accrue.Repo` and supports filters/matchers. |
| `accrue/lib/accrue/auth/mock.ex` | Named auth mock adapter | VERIFIED | Implements `Accrue.Auth`, process-local state, production guard, and helper exports. |
| `accrue/lib/accrue/mailer/test.ex` | Named mail test adapter | VERIFIED | Implements `Accrue.Mailer` and sends process-local email messages. |
| `accrue/lib/accrue/pdf/test.ex` | Named PDF test adapter | VERIFIED | Implements `Accrue.PDF` and sends process-local PDF messages. |
| `accrue/lib/accrue/telemetry/otel.ex` | Optional OTel bridge | VERIFIED | Optional-compile pattern and sanitized attribute allowlist present. |
| `accrue/guides/testing.md` | Fake-first testing guide | VERIFIED | Linked in ExDoc extras and documents no Stripe/Chrome/SMTP/sleeps test flow. |
| `accrue/guides/auth_adapters.md` | Community auth guide | VERIFIED | Documents PhxGenAuth, Pow, Assent, Sigra, default warning, and callbacks. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Installer task | Options/Project/Templates/Fingerprints/Patches | Direct module calls | VERIFIED | `Mix.Tasks.Accrue.Install.run/1` wires all installer subsystems. |
| Templates | Fingerprints | Fingerprinted writes | VERIFIED | Rendered install outputs pass through `Accrue.Install.Fingerprints.write/3`. |
| Patches | Router/admin/auth/test support | Patch builders | VERIFIED | Webhook/admin/auth/test support snippets are emitted and tested. |
| Generated test support | `Accrue.Mailer.impl/0` | `config :accrue, :mailer` | VERIFIED | gsd key-link check passed; source and regression both use the behavior-layer key. |
| `Accrue.Auth.Mock` | `Accrue.Auth` | `@behaviour Accrue.Auth` | VERIFIED | gsd key-link check passed and callback exports are tested. |
| `Accrue.Test.Clock` | `Accrue.Processor.Fake` | Fake advance APIs | VERIFIED | Clock helper calls Fake directly. |
| `Accrue.Test.Webhooks` | Ingest/DefaultHandler | Normal webhook path | VERIFIED | Helper persists rows then dispatches through default handler. |
| `Accrue.Test` | Assertion modules | Imports/delegates | VERIFIED | Facade imports mail/PDF/event assertion modules. |
| `Accrue.Telemetry` | OTel bridge | `Accrue.Telemetry.OTel.span/3` | VERIFIED | OTel bridge wraps work inside telemetry span path. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `Accrue.Test.Webhooks` | `WebhookEvent` row | `Accrue.Webhook.Ingest.run/4` then repo lookup | Yes | VERIFIED |
| `Accrue.Test.EventAssertions` | observed events | `Accrue.Repo.all(...)` over `accrue_events` | Yes | VERIFIED |
| `Accrue.Test.MailerAssertions` | observed emails | Process mailbox messages from `Accrue.Mailer.Test.deliver/2` | Yes | VERIFIED |
| `Accrue.Test.PdfAssertions` | observed PDFs | Process mailbox messages from `Accrue.PDF.Test.render/2` | Yes | VERIFIED |
| `Accrue.Auth.Mock` | current user | Process dictionary or conn assigns/map values | Yes | VERIFIED |
| `Accrue.Telemetry.OTel` | span attributes | Explicit metadata allowlist | Yes | VERIFIED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Installer mailer gap closure | `cd accrue && mix test test/mix/tasks/accrue_install_test.exs --only install_patches` | 2 tests, 0 failures | PASS |
| Auth mock gap closure | `cd accrue && mix test test/accrue/auth/mock_test.exs test/accrue/auth_test.exs` | 20 tests, 0 failures | PASS |
| Public test helper suite | `cd accrue && mix test test/accrue/test/facade_test.exs test/accrue/test/clock_test.exs test/accrue/test/webhooks_test.exs test/accrue/test/mailer_assertions_test.exs test/accrue/test/pdf_assertions_test.exs test/accrue/test/event_assertions_test.exs` | 42 tests, 0 failures | PASS |
| Compile gate | `cd accrue && mix compile --warnings-as-errors` | Exit 0 | PASS |
| Full regression suite | `cd accrue && mix test` | 46 properties, 1061 tests, 0 failures, 10 excluded | PASS |
| Schema drift gate | Provided current gate result | `drift_detected=false` | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| INST-01 | 08-01/02 | Generate migrations | SATISFIED | Installer template set includes migration copies. |
| INST-02 | 08-01/02 | Generate `MyApp.Billing` facade | SATISFIED | Billing context template and tests exist. |
| INST-03 | 08-01/03 | Router/webhook scaffold | SATISFIED | Route-scoped raw-body pipeline and `accrue_webhook` snippet exist. |
| INST-04 | 08-01/03 | Admin routes when dep present | SATISFIED | `accrue_admin` snippet emitted when `:accrue_admin` is detected. |
| INST-05 | 08-01/02 | Billable prompt/detection | SATISFIED | Project discovery detects billable usage and CLI flags cover billable schema. |
| INST-06 | 08-01/03 | Sigra auto-detection/auth wiring | SATISFIED | Sigra auth config emitted when dependency is present. |
| INST-07 | 08-01/02/03 | Idempotent re-run/no clobber | SATISFIED | Fingerprint policy protects generated/user-edited files; custom admin mount duplicate warning remains advisory. |
| INST-08 | 08-01/03 | `mix accrue.gen.handler` | SATISFIED | Handler generator exists with fingerprinted writes. |
| INST-09 | 08-01/02/03 | Config validation | SATISFIED | Installer validates planned config through `Accrue.Config.validate!/1`. |
| INST-10 | 08-01/02/03/07 | Config docs generation | SATISFIED | Config docs path and ExDoc guide wiring exist. |
| AUTH-04 | 08-01/03 | Installer auto-detects Sigra | SATISFIED | Sigra detection and patch wiring verified. |
| AUTH-05 | 08-01/03/07 | Community auth adapter docs | SATISFIED | Auth adapter guide covers required callback patterns. |
| TEST-02 | 08-01/04 | `advance_clock/2` | SATISFIED | Clock helper and tests passed. |
| TEST-03 | 08-01/04 | `trigger_event/2` | SATISFIED | Webhook helper and tests passed. |
| TEST-04 | 08-01/05/08 | `assert_email_sent/1` | SATISFIED | Mailer assertion helper exists; generated test support now configures `:mailer`. |
| TEST-05 | 08-01/05 | `assert_pdf_rendered/1` | SATISFIED | PDF test adapter and assertions passed. |
| TEST-06 | 08-01/05 | `assert_event_recorded/1` | SATISFIED | Event assertion helpers query real event rows. |
| TEST-07 | 08-01/04/05/08/09 | Mock adapters | SATISFIED | `Accrue.Auth.Mock`, `Accrue.Mailer.Test`, and `Accrue.PDF.Test` all exist and load. |
| TEST-10 | 08-01/07 | Testing guide | SATISFIED | Fake-first testing guide exists and is linked. |
| OBS-02 | 08-01/06/07 | Optional OTel spans for Billing | SATISFIED | OTel bridge and Billing span wrapper exist; compile gate passed. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `accrue/lib/accrue/install/patches.ex` | 196 | Admin idempotency check hard-codes `accrue_admin "/billing"` | Warning | Custom `--admin-mount` re-runs can duplicate the custom admin mount. This does not block the default fresh-install phase goal, but should be fixed before release polish. |

### Human Verification Required

### 1. Fresh Phoenix install timing

**Test:** Run `mix accrue.install` in a newly generated Phoenix app with normal local dependencies.
**Expected:** The app reaches Stripe test-mode-ready generated billing wiring in about 30 seconds, or emits a clear actionable setup error.
**Why human:** Fixture tests verify artifacts and links, but not actual local first-run developer timing in a clean Phoenix project.

### 2. Host DataCase copy-paste flow

**Test:** Copy/use the generated `test/support/accrue_case.ex` and host test config, then assert an email, PDF, and event in a host billing test.
**Expected:** `assert_email_sent/2`, `assert_pdf_rendered/1`, and `assert_event_recorded/1` work without Stripe, Chrome, or SMTP.
**Why human:** The library verifies snippets and helpers separately; the host integration path should be exercised as a real copied workflow.

### 3. Admin mount protection in host router

**Test:** Inspect/run the generated router in a Phoenix app with `accrue_admin` present.
**Expected:** The Accrue Admin route is protected by a host auth pipeline before requests reach admin LiveViews.
**Why human:** Accrue emits snippets, but final route protection depends on host router placement and policy.

### Gaps Summary

No automated code gaps remain from the previous verification. The wrong generated mailer key is fixed, `Accrue.Auth.Mock` is implemented and production-guarded, targeted gap tests pass, gsd artifact/key-link checks pass, full regression tests pass, and schema drift is reported as false. The phase remains `human_needed` because the real fresh-Phoenix install timing and copied host workflow need manual confirmation.

---

_Verified: 2026-04-15T23:10:12Z_
_Verifier: Claude (gsd-verifier)_
