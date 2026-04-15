---
phase: 08-install-polish-testing
verified: 2026-04-15T22:41:22Z
status: gaps_found
score: 6/8 must-haves verified
overrides_applied: 0
gaps:
  - truth: "Fresh installs provide test-support wiring that lets host tests assert billing behavior without real SMTP"
    status: failed
    reason: "The installer snippet configures Accrue.Mailer.Test under :mailer_adapter, but Accrue.Mailer dispatches through :mailer, so host apps following the generated snippet will not route Accrue.Mailer.deliver/2 to the test adapter."
    artifacts:
      - path: "accrue/lib/accrue/install/patches.ex"
        issue: "test_support_snippet uses config :accrue, :mailer_adapter, Accrue.Mailer.Test"
      - path: "accrue/lib/accrue/mailer.ex"
        issue: "Accrue.Mailer.impl/0 reads Application.get_env(:accrue, :mailer, Accrue.Mailer.Default)"
    missing:
      - "Change the installer test-support snippet to use config :accrue, :mailer, Accrue.Mailer.Test"
      - "Add/adjust an installer regression test that reads generated test/support/accrue_case.ex and asserts the behavior-layer mailer key"
  - truth: "TEST-07 mock adapters are complete, including Accrue.Auth.Mock, Accrue.Mailer.Test, and Accrue.PDF.Test"
    status: failed
    reason: "Accrue.Mailer.Test and Accrue.PDF.Test exist, but no Accrue.Auth.Mock module or equivalent named mock auth adapter was found."
    artifacts:
      - path: "accrue/lib/accrue/mailer/test.ex"
        issue: "Mailer test adapter exists"
      - path: "accrue/lib/accrue/pdf/test.ex"
        issue: "PDF test adapter exists"
      - path: "accrue/lib/accrue/auth/mock.ex"
        issue: "Missing"
    missing:
      - "Add Accrue.Auth.Mock or document and test an accepted replacement for the TEST-07 named mock adapter"
---

# Phase 8: Install + Polish + Testing Verification Report

**Phase Goal:** A Phoenix developer can run `mix accrue.install` in a fresh app and be running against Stripe test mode within 30 seconds, with generated migrations + `MyApp.Billing` context + router mounts + webhook endpoint + admin routes when `accrue_admin` is present + Sigra wiring when present, and have a complete test helper suite to assert billing behavior without hitting Stripe, Chrome, or real SMTP.
**Verified:** 2026-04-15T22:41:22Z
**Status:** gaps_found
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Fresh install generates migrations, `MyApp.Billing`, router/webhook/admin wiring, and config validation | VERIFIED | Installer entrypoint, templates, patch builders, runtime config template, and config validation exist; targeted Phase 08 tests passed. |
| 2 | Re-running install is idempotent and avoids clobbering user edits | VERIFIED | `Accrue.Install.Fingerprints` stamps SHA-256 fingerprints, updates pristine generated files, skips user-edited files, and generator uses it. |
| 3 | `advance_clock/2` and `trigger_event/2` work without sleeps or bypassing webhook reducer path | VERIFIED | Clock uses Fake advance APIs with no `Process.sleep`; webhooks route through `Accrue.Webhook.Ingest` and `DefaultHandler`. Regression fix in `fd670f8` is present. |
| 4 | Email, PDF, and event assertion helpers are available and fail with useful diagnostics | VERIFIED | `use Accrue.Test` imports mail/PDF/event assertions; matcher helpers expose observed side-effect summaries. |
| 5 | Sigra is auto-wired when present and default auth warning exists when absent | VERIFIED | Installer patch builders emit `Accrue.Integrations.Sigra` when detected and `Accrue.Auth.Default` fallback with prod-safety warning otherwise. |
| 6 | OTel spans wrap Billing functions when available and compile cleanly with/without OTel | VERIFIED | `Accrue.Telemetry.span/3` calls optional OTel bridge; compile matrix commands passed. |
| 7 | Fresh install test-support wiring avoids real SMTP | FAILED | Installer snippet writes `config :accrue, :mailer_adapter, Accrue.Mailer.Test`, but `Accrue.Mailer.impl/0` reads `:mailer`. |
| 8 | TEST-07 named mock adapters are complete | FAILED | `Accrue.Mailer.Test` and `Accrue.PDF.Test` exist; `Accrue.Auth.Mock` was not found. |

**Score:** 6/8 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `accrue/lib/mix/tasks/accrue.install.ex` | Installer CLI orchestration | VERIFIED | Parses options, discovers project, renders templates, applies fingerprints/patches, prints redacted reports. |
| `accrue/lib/accrue/install/patches.ex` | Router/admin/auth/test-support/Oban snippets | PARTIAL | Router/admin/auth/Oban snippets are present; test-support mailer config key is wrong. |
| `accrue/lib/mix/tasks/accrue.gen.handler.ex` | Handler generator | VERIFIED | Uses loadpaths, strict options, template rendering, fingerprint no-clobber policy. |
| `accrue/lib/accrue/test.ex` | Public testing facade | VERIFIED | Imports mail/PDF/event assertions and delegates action helpers. |
| `accrue/lib/accrue/test/clock.ex` | Deterministic clock helper | VERIFIED | Supports readable/keyword durations and subscription-aware Fake advancement. |
| `accrue/lib/accrue/test/webhooks.ex` | Synthetic webhook helper | VERIFIED | Ingests persisted webhook rows and propagates handler failures except accepted missing-resource cases. |
| `accrue/lib/accrue/test/event_assertions.ex` | Event ledger assertions | VERIFIED | Supports filters, subjects, partial maps, predicates, and observed summaries. |
| `accrue/lib/accrue/telemetry/otel.ex` | Optional OTel bridge | VERIFIED | Uses optional compile pattern and allowlisted attributes. |
| `accrue/guides/testing.md` | Fake-first testing guide | VERIFIED | Opens with a copy-paste Phoenix scenario and warns against Stripe/Chrome/SMTP/sleeps. |
| `accrue/guides/auth_adapters.md` | Community auth guide | VERIFIED | Covers PhxGenAuth, Pow, Assent, Sigra, default fallback, and callbacks. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Installer task | Options/Project/Templates/Fingerprints/Patches | Direct module calls | VERIFIED | `Mix.Tasks.Accrue.Install.run/1` calls all subsystems. |
| Templates | Fingerprints | Fingerprinted writes | VERIFIED | Installer writes rendered files through `Accrue.Install.Fingerprints.write/3`. |
| Patches | Router/admin/auth/test support | Patch builders | PARTIAL | Route-scoped webhook/admin/auth links are correct; mailer test config key is wrong. |
| `Accrue.Test.Clock` | `Accrue.Processor.Fake` | `advance/2`, `advance_subscription/2` | VERIFIED | Calls Fake APIs directly. |
| `Accrue.Test.Webhooks` | Ingest/DefaultHandler | Normal webhook path | VERIFIED | Uses `Accrue.Webhook.Ingest` and `Accrue.Webhook.DefaultHandler`. |
| `Accrue.Test` | Assertion modules | Imports/delegates | VERIFIED | Facade imports mail/PDF/event assertions and delegates actions. |
| `Accrue.Telemetry` | OTel bridge | `Accrue.Telemetry.OTel.span/3` | VERIFIED | OTel wraps work inside `:telemetry.span/3`. |
| `mix.exs` | Guides | ExDoc extras | VERIFIED | `guides/telemetry.md`, `guides/testing.md`, and `guides/auth_adapters.md` are listed. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `Accrue.Test.Webhooks` | `WebhookEvent` row | `Accrue.Webhook.Ingest.run/4` then `Repo.get_by/3` | Yes | VERIFIED |
| `Accrue.Test.EventAssertions` | observed events | `Accrue.Repo.all(from e in Event...)` | Yes | VERIFIED |
| `Accrue.Test.MailerAssertions` | observed emails | Process mailbox messages from `Accrue.Mailer.Test.deliver/2` | Yes when `:mailer` is configured | PARTIAL because installer snippet configures the wrong key |
| `Accrue.Test.PdfAssertions` | observed PDFs | Process mailbox messages from `Accrue.PDF.Test.render/2` | Yes | VERIFIED |
| `Accrue.Telemetry.OTel` | span attributes | Explicit metadata allowlist | Yes | VERIFIED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Full regression suite | `cd accrue && mix test --seed 440602` | 46 properties, 1055 tests, 0 failures, 10 excluded | PASS |
| Targeted Phase 08 contracts | `cd accrue && mix test test/mix/tasks/accrue_install_test.exs ... test/accrue/docs/community_auth_test.exs` | 40 tests, 0 failures | PASS |
| OTel without dependency matrix | `cd accrue && MIX_ENV=test ACCRUE_OTEL_MATRIX=without_opentelemetry mix compile --warnings-as-errors --force` | Compile passed | PASS |
| OTel with dependency matrix | `cd accrue && MIX_ENV=test ACCRUE_OTEL_MATRIX=with_opentelemetry mix compile --warnings-as-errors --force` | Compile passed | PASS |
| Docs warnings gate | `cd accrue && mix docs --warnings-as-errors` | Docs generated | PASS |
| Failed-test rerun sanity | `cd accrue && mix test --seed 440602 --failed` | No failed tests remained | PASS |

Note: one initial `cd accrue && mix test` run failed once in `test/accrue/processor/fake_phase3_test.exs` because `Accrue.Processor.Fake` was not alive during setup. The file passed alone, and the same full-suite seed passed on rerun. I am treating this as a transient warning, not a Phase 08 blocker.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| INST-01 | 08-01/02 | Generate migrations | SATISFIED | Installer renders/copies migration templates. |
| INST-02 | 08-01/02 | Generate `MyApp.Billing` facade | SATISFIED | Billing facade EEx template and fixture tests exist. |
| INST-03 | 08-01/03 | Router/webhook scaffold | SATISFIED | Route-scoped webhook pipeline and `accrue_webhook "/stripe", :stripe`. |
| INST-04 | 08-01/03 | Admin routes when dep present | SATISFIED | `accrue_admin "/billing"` emitted only when `:accrue_admin` is detected. |
| INST-05 | 08-01/02 | Billable prompt/detection | SATISFIED | Project discovery detects `use Accrue.Billable`; options support `--billable`. |
| INST-06 | 08-01/03 | Sigra auto-detection/auth wiring | SATISFIED | Sigra config emitted when dep present; fallback otherwise. |
| INST-07 | 08-01/02 | Idempotent re-run/no clobber | SATISFIED | Fingerprints and tests cover pristine vs edited generated files. |
| INST-08 | 08-01/03 | `mix accrue.gen.handler` | SATISFIED | Generator and tests exist. |
| INST-09 | 08-01/02/03 | Config validation | SATISFIED | Installer validates planned config through `Accrue.Config.validate!/1`. |
| INST-10 | 08-01/02/03/07 | Config docs generation | SATISFIED | `NimbleOptions.docs/1` path and ExDoc guide wiring exist. |
| AUTH-04 | 08-01/03 | Installer auto-detects Sigra | SATISFIED | Sigra detection tests and patch builders. |
| AUTH-05 | 08-01/03/07 | Community auth adapter docs | SATISFIED | `guides/auth_adapters.md` covers PhxGenAuth, Pow, Assent, Sigra, callbacks. |
| TEST-02 | 08-01/04 | `advance_clock/2` | SATISFIED | Helper and tests pass, including post-review clock argument handling. |
| TEST-03 | 08-01/04 | `trigger_event/2` | SATISFIED | Helper routes through ingest/handler and tests pass. |
| TEST-04 | 08-01/05 | `assert_email_sent/1` | PARTIAL | Helper exists and works when `:mailer` is configured; installer snippet uses wrong key. |
| TEST-05 | 08-01/05 | `assert_pdf_rendered/1` | SATISFIED | PDF test adapter and assertions exist. |
| TEST-06 | 08-01/05 | `assert_event_recorded/1` | SATISFIED | Event assertion macros and matcher tests exist. |
| TEST-07 | 08-01/04/05 | Mock adapters | FAILED | `Accrue.Mailer.Test` and `Accrue.PDF.Test` exist; `Accrue.Auth.Mock` missing. |
| TEST-10 | 08-01/07 | Testing guide | SATISFIED | Fake-first guide and doc tests exist. |
| OBS-02 | 08-01/06/07 | Optional OTel spans for Billing | SATISFIED | OTel bridge, Billing wrappers, privacy tests, and compile matrix pass. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `accrue/lib/accrue/install/patches.ex` | 135 | Wrong config key for test mailer | Blocker | Fresh host apps following installer test-support snippet do not route `Accrue.Mailer.deliver/2` to `Accrue.Mailer.Test`. |
| `accrue/lib/accrue/auth/mock.ex` | n/a | Missing named mock adapter | Blocker | TEST-07 is not fully satisfied. |
| `accrue/test/accrue/telemetry/billing_span_coverage_test.exs` | 28 | Source-level coverage check is weak | Warning | Advisory review item remains: test can miss unspanned public functions if `Accrue.Telemetry.span` appears elsewhere in file. Current implementation appears wrapped through helper functions, so this is not counted as a goal blocker. |

### Human Verification Required

After the code gaps are fixed:

1. Run a real `phx.new` fixture install and verify the end-to-end first-run path completes in the intended 30-second range.
2. Exercise a copied host `DataCase` using the generated test support and confirm `assert_email_sent/2`, `assert_pdf_rendered/1`, and `assert_event_recorded/1` work without Stripe, Chrome, or SMTP.
3. Confirm the admin mount is protected by host auth in an actual Phoenix router, not only represented as a snippet.

### Gaps Summary

The core installer, generator, helper facade, webhook helper, OTel bridge, and guides are present and the targeted Phase 08 tests pass. The phase is not fully achieved because the fresh-install test-support snippet is wired to the wrong mailer config key, and TEST-07's named `Accrue.Auth.Mock` adapter is missing. These are not deferred to Phase 9 by the roadmap.

---

_Verified: 2026-04-15T22:41:22Z_
_Verifier: Claude (gsd-verifier)_
