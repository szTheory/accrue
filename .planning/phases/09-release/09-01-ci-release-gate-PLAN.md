---
phase: 09-release
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - .github/workflows/ci.yml
autonomous: true
requirements: [OSS-02, OSS-03, OSS-04, OSS-05, OSS-06]
must_haves:
  truths:
    - "Both packages fail release CI on formatting drift, warnings, failing tests, Credo strict issues, Dialyzer warnings, ExDoc warnings, or retired Hex packages."
    - "The release gate runs across the supported Elixir and OTP matrix."
    - "Conditional compilation is exercised with and without Sigra and with and without OpenTelemetry."
  artifacts:
    - path: ".github/workflows/ci.yml"
      provides: "Unified release gate workflow for accrue and accrue_admin"
  key_links:
    - from: ".github/workflows/ci.yml"
      to: "accrue/mix.exs"
      via: "core package release commands"
      pattern: "cd accrue && mix docs --warnings-as-errors"
    - from: ".github/workflows/ci.yml"
      to: "accrue_admin/mix.exs"
      via: "admin package release commands"
      pattern: "cd accrue_admin && mix docs --warnings-as-errors"
---

<objective>
Harden the main CI workflow into the Phase 9 release gate.

Purpose: block v1.0.0 release work unless both packages satisfy the exact OSS release checks required by the roadmap.
Output: a package-aware GitHub Actions matrix that enforces the release gate for `accrue` and `accrue_admin`.
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
@.github/workflows/ci.yml
@accrue/mix.exs
@accrue_admin/mix.exs
@scripts/ci/compile_matrix.sh
</context>

<tasks>

<task type="auto">
  <name>Task 1: Expand the matrix axes and package coverage in ci.yml</name>
  <files>.github/workflows/ci.yml</files>
  <read_first>
    - .github/workflows/ci.yml
    - .planning/phases/09-release/09-RESEARCH.md
    - .planning/phases/09-release/09-VALIDATION.md
    - .planning/phases/09-release/09-PATTERNS.md
    - CLAUDE.md
    - accrue/mix.exs
    - accrue_admin/mix.exs
    - scripts/ci/compile_matrix.sh
  </read_first>
  <action>Rewrite `.github/workflows/ci.yml` so the primary job becomes a Phase 9 release gate for both packages per OSS-02 through OSS-06. Keep the existing `ubuntu-24.04`, Postgres service, `actions/checkout@v4`, and `erlef/setup-beam@v1` skeleton. Change the matrix name and include entries that cover the supported Elixir and OTP combinations plus conditional-compilation toggles: floor `elixir: '1.17.3', otp: '27.0', sigra: 'off', opentelemetry: 'off'`; primary `elixir: '1.18.0', otp: '27.0', sigra: 'off', opentelemetry: 'off'`; forward-compat `elixir: '1.18.0', otp: '28.0', sigra: 'off', opentelemetry: 'off'`; Sigra cell `elixir: '1.18.0', otp: '27.0', sigra: 'on', opentelemetry: 'off'`; OpenTelemetry cell `elixir: '1.18.0', otp: '27.0', sigra: 'off', opentelemetry: 'on'`. Keep `continue-on-error: true` only on the `sigra: 'on'` cell if the existing repo comment still applies. Export both `ACCRUE_CI_SIGRA` and `ACCRUE_CI_OPENTELEMETRY` from matrix values. Preserve the daily advisory `live-stripe` job exactly as advisory and non-blocking.</action>
  <acceptance_criteria>
    - `rg -n "opentelemetry|ACCRUE_CI_OPENTELEMETRY|sigra" .github/workflows/ci.yml` returns matches.
    - `rg -n "elixir: '1.17.3'|elixir: '1.18.0'|otp: '27.0'|otp: '28.0'" .github/workflows/ci.yml` returns matches.
    - `rg -n "continue-on-error: true" .github/workflows/ci.yml` returns at most the Sigra advisory cell comment or assignment, not a blanket workflow-level bypass.
  </acceptance_criteria>
  <verify>
    <automated>rg -n "mix format --check-formatted|mix compile --warnings-as-errors|mix test --warnings-as-errors|mix credo --strict|mix dialyzer|mix docs --warnings-as-errors|mix hex.audit|opentelemetry|sigra|accrue_admin" .github/workflows/ci.yml</automated>
  </verify>
  <done>The matrix explicitly covers OSS-03, OSS-05, and OSS-06 with concrete on/off cells and does not weaken the release gate.</done>
</task>

<task type="auto">
  <name>Task 2: Add exact release-gate steps for both packages and split PLT caching</name>
  <files>.github/workflows/ci.yml</files>
  <read_first>
    - .github/workflows/ci.yml
    - .planning/phases/09-release/09-RESEARCH.md
    - .planning/phases/09-release/09-VALIDATION.md
    - accrue/mix.exs
    - accrue_admin/mix.exs
  </read_first>
  <action>In `.github/workflows/ci.yml`, keep the existing split `actions/cache/restore@v4` and `actions/cache/save@v4` PLT pattern for `accrue`, mirror the admin package's `priv/plts` cache once Plan 09-05 adds Dialyxir support, and make the release job enforce the exact required commands for both packages. The workflow must run `cd accrue && mix format --check-formatted`, `cd accrue && mix compile --warnings-as-errors`, `cd accrue && mix test --warnings-as-errors`, `cd accrue && mix credo --strict`, `cd accrue && mix dialyzer --format github`, `cd accrue && mix docs --warnings-as-errors`, and `cd accrue && mix hex.audit`. It must also run `cd accrue_admin && mix format --check-formatted`, `cd accrue_admin && mix compile --warnings-as-errors`, `cd accrue_admin && mix test --warnings-as-errors`, `cd accrue_admin && mix credo --strict`, `cd accrue_admin && mix dialyzer --format github`, `cd accrue_admin && mix docs --warnings-as-errors`, and `cd accrue_admin && mix hex.audit`. Keep step names explicit so failures are attributable by package. Do not move Hex publishing into this workflow, and do not claim `mix hex.audit` performs vulnerability scanning.</action>
  <acceptance_criteria>
    - `rg -n "cd accrue && mix format --check-formatted|cd accrue && mix compile --warnings-as-errors|cd accrue && mix test --warnings-as-errors|cd accrue && mix credo --strict|cd accrue && mix dialyzer --format github|cd accrue && mix docs --warnings-as-errors|cd accrue && mix hex.audit" .github/workflows/ci.yml` returns matches.
    - `rg -n "cd accrue_admin && mix format --check-formatted|cd accrue_admin && mix compile --warnings-as-errors|cd accrue_admin && mix test --warnings-as-errors|cd accrue_admin && mix credo --strict|cd accrue_admin && mix dialyzer --format github|cd accrue_admin && mix docs --warnings-as-errors|cd accrue_admin && mix hex.audit" .github/workflows/ci.yml` returns matches.
    - `rg -n "actions/cache/restore@v4|actions/cache/save@v4|accrue_admin/.*/plts|priv/plts|plt" .github/workflows/ci.yml` returns matches.
    - `rg -n "hex.publish|HEX_API_KEY" .github/workflows/ci.yml` returns no matches.
  </acceptance_criteria>
  <verify>
    <automated>rg -n "actions/cache/(restore|save)@v4|mix dialyzer --format github|mix docs --warnings-as-errors|mix hex.audit|cd accrue_admin && mix dialyzer --format github|cd accrue_admin && mix docs --warnings-as-errors|cd accrue_admin && mix hex.audit" .github/workflows/ci.yml</automated>
  </verify>
  <done>The main CI workflow is a complete release gate for both packages, including admin Dialyzer and retired-package checks, and preserves OSS-04's split PLT caching pattern.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| GitHub push and pull_request events to release CI | Untrusted code from branches or forks must not gain publish capability through the CI workflow. |
| Workflow environment to package commands | CI exports matrix variables and secrets into shell commands that must not broaden release scope. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-09-01-01 | Elevation of Privilege | `.github/workflows/ci.yml` | mitigate | Keep CI separate from publish automation, with no `HEX_API_KEY`, no release token use, and no publish steps. |
| T-09-01-02 | Tampering | `.github/workflows/ci.yml` matrix coverage | mitigate | Enforce both package command sets and explicit `with_sigra` and `with_opentelemetry` cells so unsupported conditional code cannot bypass the gate. |
| T-09-01-03 | Information Disclosure | CI logs and docs steps | mitigate | Do not echo secrets, and do not describe `mix hex.audit` as a broader security scan than its retired-package scope. |
</threat_model>

<verification>
Run `rg -n "mix format --check-formatted|mix compile --warnings-as-errors|mix test --warnings-as-errors|mix credo --strict|mix dialyzer|mix docs --warnings-as-errors|mix hex.audit|opentelemetry|sigra|accrue_admin" .github/workflows/ci.yml`.
</verification>

<success_criteria>
Phase 9 CI blocks release on the exact OSS release checks across both packages, with the required version matrix and conditional-compilation coverage in one workflow.
</success_criteria>

<output>
After completion, create `.planning/phases/09-release/09-01-SUMMARY.md`.
</output>
