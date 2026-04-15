---
phase: 09-release
plan: 03
type: execute
wave: 1
depends_on: []
files_modified:
  - accrue/mix.exs
  - accrue/README.md
  - accrue/CHANGELOG.md
  - accrue/guides/quickstart.md
  - accrue/guides/configuration.md
autonomous: true
requirements: [OSS-01, OSS-15, OSS-16, OSS-17, OSS-18]
must_haves:
  truths:
    - "The core package has a copy-pasteable quickstart and release-managed changelog surface."
    - "The core ExDoc site exposes README, guides, and generated llms.txt."
    - "Public API stability and deprecation expectations are stated in package docs."
  artifacts:
    - path: "accrue/README.md"
      provides: "30-second quickstart and release surface"
    - path: "accrue/CHANGELOG.md"
      provides: "Release Please managed changelog file"
    - path: "accrue/mix.exs"
      provides: "ExDoc extras and llms.txt wiring"
    - path: "accrue/guides/quickstart.md"
      provides: "Quickstart guide"
    - path: "accrue/guides/configuration.md"
      provides: "Configuration and public API guidance"
  key_links:
    - from: "accrue/mix.exs"
      to: "accrue/README.md"
      via: "docs main extra"
      pattern: "README.md"
    - from: "accrue/mix.exs"
      to: "accrue/guides/quickstart.md"
      via: "docs extras"
      pattern: "guides/quickstart.md"
---

<objective>
Create the core package release docs surface for HexDocs and Hex.

Purpose: the `accrue` package must ship with a runnable README, ExDoc guide wiring, a changelog file for Release Please, and explicit public API stability guidance.
Output: `accrue` README, changelog, quickstart/config guides, and updated ExDoc config.
</objective>

<execution_context>
@/Users/jon/.codex/get-shit-done/workflows/execute-plan.md
@/Users/jon/.codex/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/ROADMAP.md
@.planning/REQUIREMENTS.md
@.planning/phases/09-release/09-RESEARCH.md
@.planning/phases/09-release/09-VALIDATION.md
@.planning/phases/09-release/09-PATTERNS.md
@accrue/mix.exs
@accrue/guides/testing.md
@accrue/guides/branding.md
@accrue/guides/auth_adapters.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add the core package README and changelog entrypoints</name>
  <files>accrue/README.md, accrue/CHANGELOG.md</files>
  <read_first>
    - .planning/phases/09-release/09-RESEARCH.md
    - .planning/phases/09-release/09-PATTERNS.md
    - accrue/guides/testing.md
    - accrue/guides/branding.md
    - accrue/mix.exs
  </read_first>
  <action>Create `accrue/README.md` and `accrue/CHANGELOG.md`. The README must open with `# Accrue`, include the tagline `Billing state, modeled clearly.`, and lead with a runnable 30-second quickstart that shows `{:accrue, "~> 1.0.0"}` in `deps/0`, `config :accrue, :processor, Accrue.Processor.Stripe`, and `mix accrue.install`. Add sections named exactly `## Quickstart`, `## What ships in v1.0.0`, `## Public API stability`, `## Guides`, and `## Security`. In `## Public API stability`, state that the public facades under `Accrue.Billing`, `Accrue.Checkout`, `Accrue.BillingPortal`, `Accrue.Connect`, `Accrue.Events`, and `Accrue.Test` are the supported surface for v1.x, and that breaking changes follow a deprecation cycle documented in `guides/upgrade.md`. In `## Guides`, link to `guides/quickstart.md`, `guides/configuration.md`, `guides/testing.md`, `guides/sigra_integration.md`, `guides/custom_processors.md`, `guides/custom_pdf_adapter.md`, `guides/branding.md`, `guides/webhook_gotchas.md`, and `guides/upgrade.md`. Create `accrue/CHANGELOG.md` as a Release Please managed placeholder containing `# Changelog` and `<!-- Release Please will add entries here. -->`.</action>
  <acceptance_criteria>
    - `test -f accrue/README.md && test -f accrue/CHANGELOG.md` exits 0.
    - `rg -n "^# Accrue$|Billing state, modeled clearly\\.|\\{:accrue, \"~> 1\\.0\\.0\"\\}|mix accrue.install|## Quickstart|## What ships in v1\\.0\\.0|## Public API stability|## Guides|## Security|Accrue\\.Billing|Accrue\\.Checkout|Accrue\\.BillingPortal|Accrue\\.Connect|Accrue\\.Events|Accrue\\.Test|guides/upgrade\\.md" accrue/README.md` returns matches.
    - `rg -n "^# Changelog$|Release Please will add entries here" accrue/CHANGELOG.md` returns matches.
  </acceptance_criteria>
  <verify>
    <automated>test -f accrue/README.md && test -f accrue/CHANGELOG.md && rg -n "Quickstart|Public API stability|guides/quickstart.md|guides/upgrade.md" accrue/README.md accrue/CHANGELOG.md</automated>
  </verify>
  <done>The core package has the required README and changelog entrypoint for Hex and Release Please.</done>
</task>

<task type="auto">
  <name>Task 2: Wire ExDoc extras and add quickstart/configuration guides</name>
  <files>accrue/mix.exs, accrue/guides/quickstart.md, accrue/guides/configuration.md</files>
  <read_first>
    - accrue/mix.exs
    - accrue/guides/testing.md
    - accrue/guides/branding.md
    - accrue/guides/auth_adapters.md
    - .planning/phases/09-release/09-RESEARCH.md
    - .planning/phases/09-release/09-VALIDATION.md
  </read_first>
  <action>Update `accrue/mix.exs` `docs/0` so ExDoc treats README as the main page, includes `README.md` plus `guides/*.md`, sets `groups_for_extras: [Guides: Path.wildcard("guides/*.md")]`, keeps `source_ref: "v#{@version}"`, and preserves the narrow undefined-reference skip callback. Create `accrue/guides/quickstart.md` with sections `# Quickstart`, `## Install`, `## Configure Stripe`, `## Run the installer`, and `## First subscription`. Create `accrue/guides/configuration.md` with sections `# Configuration`, `## Required runtime keys`, `## Optional adapters`, `## Telemetry and OpenTelemetry`, and `## Deprecation policy`. The configuration guide must mention runtime-only secrets `:stripe_secret_key` and `:webhook_signing_secret`, optional adapters `:auth_adapter`, `:pdf_adapter`, and `:mailer`, OpenTelemetry as optional, and the v1.x deprecation rule that public APIs are deprecated before removal rather than silently changed. Do not remove existing guides from extras and do not add docs suppressions beyond the existing `skip_undefined_reference_warning?/1` callback.</action>
  <acceptance_criteria>
    - `rg -n "main: \"readme\"|README\\.md|Path\\.wildcard\\(\"guides/\\*\\.md\"\\)|groups_for_extras|source_ref: \"v#\\{@version\\}\"|skip_undefined_reference_warning" accrue/mix.exs` returns matches.
    - `test -f accrue/guides/quickstart.md && test -f accrue/guides/configuration.md` exits 0.
    - `rg -n "^# Quickstart$|## Install|## Configure Stripe|## Run the installer|## First subscription" accrue/guides/quickstart.md` returns matches.
    - `rg -n "^# Configuration$|## Required runtime keys|:stripe_secret_key|:webhook_signing_secret|## Optional adapters|:auth_adapter|:pdf_adapter|:mailer|## Telemetry and OpenTelemetry|## Deprecation policy|deprecated before removal" accrue/guides/configuration.md` returns matches.
  </acceptance_criteria>
  <verify>
    <automated>cd accrue && mix docs --warnings-as-errors</automated>
  </verify>
  <done>ExDoc will build a README-first site with guide extras and generate `doc/llms.txt` for the core package.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| public package docs to downstream developers | Developers will copy README and guide snippets directly into production apps. |
| ExDoc build to published HexDocs | Broken links or overstated guarantees in docs become release-time public surface. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-09-03-01 | Information Disclosure | `accrue/README.md` and guides | mitigate | Use only placeholder env var names, example IDs, and no real API keys, webhook secrets, or Stripe identifiers. |
| T-09-03-02 | Repudiation | public API docs | mitigate | State the supported v1.x facades and deprecation policy explicitly so release guarantees are auditable. |
| T-09-03-03 | Tampering | ExDoc surface | mitigate | Keep `mix docs --warnings-as-errors` as the package verification step and do not widen warning suppressions. |
</threat_model>

<verification>
Run `cd accrue && mix docs --warnings-as-errors && test -f doc/llms.txt`.
</verification>

<success_criteria>
The `accrue` package has a release-grade README, changelog, and ExDoc guide surface that satisfies the core half of the Phase 9 docs requirements.
</success_criteria>

<output>
After completion, create `.planning/phases/09-release/09-03-SUMMARY.md`.
</output>
