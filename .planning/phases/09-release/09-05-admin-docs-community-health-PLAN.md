---
phase: 09-release
plan: 05
type: execute
wave: 1
depends_on: []
files_modified:
  - accrue_admin/mix.exs
  - accrue_admin/README.md
  - accrue_admin/CHANGELOG.md
  - accrue_admin/guides/admin_ui.md
  - CONTRIBUTING.md
  - CODE_OF_CONDUCT.md
  - SECURITY.md
autonomous: true
requirements: [OSS-01, OSS-12, OSS-13, OSS-14, OSS-16, OSS-17, OSS-18]
must_haves:
  truths:
    - "The admin package can publish to Hex without retaining a local path dependency on `../accrue` when `ACCRUE_ADMIN_HEX_RELEASE=1` is set."
    - "The admin package has README, changelog, ExDoc config, and llms.txt generation."
    - "The repository root exposes contributing, conduct, and security files with non-placeholder content."
  artifacts:
    - path: "accrue_admin/mix.exs"
      provides: "Hex-safe package dependency and ExDoc config"
    - path: "accrue_admin/README.md"
      provides: "Admin package quickstart"
    - path: "accrue_admin/CHANGELOG.md"
      provides: "Admin package changelog"
    - path: "CONTRIBUTING.md"
      provides: "Contribution guide"
    - path: "CODE_OF_CONDUCT.md"
      provides: "Contributor Covenant 2.1"
    - path: "SECURITY.md"
      provides: "Vulnerability disclosure policy"
  key_links:
    - from: "accrue_admin/mix.exs"
      to: "accrue_admin/README.md"
      via: "version-pinned Hex dependency docs"
      pattern: "~> 1.0.0"
    - from: "accrue_admin/mix.exs"
      to: "accrue/README.md"
      via: "publish-mode dependency switch"
      pattern: "System.get_env(\"ACCRUE_ADMIN_HEX_RELEASE\") == \"1\""
---

<objective>
Finish the admin package release surface and root OSS health files.

Purpose: the admin package must be publishable and documented, and the repository must expose the required public contribution and security policies.
Output: admin README/changelog/docs config, Hex-safe `accrue` dependency strategy, and root community health files.
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
@accrue_admin/mix.exs
@accrue_admin/guides/admin_ui.md
@guides/testing-live-stripe.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Make accrue_admin publishable on Hex and add its docs surface</name>
  <files>accrue_admin/mix.exs, accrue_admin/README.md, accrue_admin/CHANGELOG.md, accrue_admin/guides/admin_ui.md</files>
  <read_first>
    - accrue_admin/mix.exs
    - accrue_admin/guides/admin_ui.md
    - .planning/phases/09-release/09-RESEARCH.md
    - .planning/phases/09-release/09-VALIDATION.md
    - .planning/phases/09-release/09-PATTERNS.md
    - accrue/mix.exs
  </read_first>
  <action>Update `accrue_admin/mix.exs` so the sibling dependency is Hex-safe for publish per the resolved Phase 9 decision in `09-RESEARCH.md`, and so admin release verification covers Dialyzer for OSS-02. Replace the literal `{:accrue, path: "../accrue"}` tuple with a helper `accrue_dep()` that returns `{:accrue, "~> #{@version}"}` when `System.get_env("ACCRUE_ADMIN_HEX_RELEASE") == "1"` and returns `{:accrue, path: "../accrue"}` otherwise. Keep one dependency entry only, not both, so publish jobs and dry runs can force the Hex-safe dependency shape even inside the monorepo checkout. Add `{:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}` to `deps/0`, configure `dialyzer: [plt_local_path: "priv/plts"]` in `project/0` so the package matches the split-PLT cache pattern documented in `09-RESEARCH.md`, and add `docs: docs()` to `project/0`. Define `docs/0` with `main: "readme"`, `source_ref: "v#{@version}"`, `extras: ["README.md", "guides/admin_ui.md"]`, and `groups_for_extras: [Guides: ["guides/admin_ui.md"]]`. Create `accrue_admin/README.md` with `# AccrueAdmin`, a quickstart using `{:accrue_admin, "~> 1.0.0"}` and `accrue_admin "/billing"`, plus sections `## Quickstart`, `## Host setup`, `## Assets`, `## Browser UAT`, and `## Guides`. Create `accrue_admin/CHANGELOG.md` with the same Release Please placeholder used in the core package. Update `accrue_admin/guides/admin_ui.md` so it links to README quickstart, calls out the published dependency on `accrue ~> 1.0.0`, documents that CI/publish dry runs must set `ACCRUE_ADMIN_HEX_RELEASE=1`, documents the local admin release gate including `mix dialyzer --format github` and `mix hex.audit`, and preserves the existing host-setup-first structure.</action>
  <acceptance_criteria>
    - `rg -n "defp accrue_dep|System\\.get_env\\(\"ACCRUE_ADMIN_HEX_RELEASE\"\\) == \"1\"|\\{:accrue, path: \"\\.\\./accrue\"\\}|\\{:accrue, \"~> #\\{@version\\}\"\\}" accrue_admin/mix.exs` returns matches.
    - `rg -n "dialyxir|dialyzer: \\[plt_local_path: \"priv/plts\"\\]|docs: docs\\(\\)|main: \"readme\"|README\\.md|guides/admin_ui\\.md|groups_for_extras" accrue_admin/mix.exs` returns matches.
    - `rg -n "path: \"\\.\\./accrue\"" accrue_admin/mix.exs` returns exactly one match inside the helper and no top-level deps tuple remains.
    - `cd accrue_admin && mix dialyzer --format github` exits 0.
    - `cd accrue_admin && mix hex.audit` exits 0.
    - `cd accrue_admin && ACCRUE_ADMIN_HEX_RELEASE=1 mix hex.build` exits 0.
    - `cd accrue_admin && ACCRUE_ADMIN_HEX_RELEASE=1 mix hex.publish --dry-run` exits 0.
    - `test -f accrue_admin/README.md && test -f accrue_admin/CHANGELOG.md` exits 0.
    - `rg -n "^# AccrueAdmin$|\\{:accrue_admin, \"~> 1\\.0\\.0\"\\}|accrue_admin \"/billing\"|## Quickstart|## Host setup|## Assets|## Browser UAT|## Guides|ACCRUE_ADMIN_HEX_RELEASE=1|mix dialyzer --format github|mix hex.audit" accrue_admin/README.md accrue_admin/guides/admin_ui.md` returns matches.
    - `rg -n "^# Changelog$|Release Please will add entries here" accrue_admin/CHANGELOG.md` returns matches.
  </acceptance_criteria>
  <verify>
    <automated>cd accrue_admin && mix docs --warnings-as-errors && mix dialyzer --format github && mix hex.audit && ACCRUE_ADMIN_HEX_RELEASE=1 mix hex.build && ACCRUE_ADMIN_HEX_RELEASE=1 mix hex.publish --dry-run</automated>
  </verify>
  <done>`accrue_admin` has a deterministic publish-mode dependency switch, ships the Dialyzer tooling/config needed for release CI and readiness checks, its packaged metadata is Hex-safe when `ACCRUE_ADMIN_HEX_RELEASE=1`, and it has a release-grade docs surface.</done>
</task>

<task type="auto">
  <name>Task 2: Add root contributing, conduct, and security files with concrete release-era policy text</name>
  <files>CONTRIBUTING.md, CODE_OF_CONDUCT.md, SECURITY.md</files>
  <read_first>
    - .planning/phases/09-release/09-RESEARCH.md
    - .planning/phases/09-release/09-VALIDATION.md
    - guides/testing-live-stripe.md
    - accrue/README.md
    - accrue_admin/README.md
  </read_first>
  <action>Create `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, and `SECURITY.md`. `CONTRIBUTING.md` must include sections `# Contributing`, `## Development setup`, `## Conventional Commits`, `## Running the release gate locally`, and `## No CLA`, and explicitly name `mix format --check-formatted`, `mix compile --warnings-as-errors`, `mix test --warnings-as-errors`, `mix credo --strict`, `mix dialyzer`, `mix docs --warnings-as-errors`, and `mix hex.audit`. `CODE_OF_CONDUCT.md` must use Contributor Covenant 2.1 language and include a concrete project contact placeholder in the form `maintainers@accrue.dev` rather than leaving bracket placeholders. `SECURITY.md` must include sections `# Security Policy`, `## Supported Versions`, `## Reporting a Vulnerability`, and `## Secret Handling`, with the same contact address `security@accrue.dev`, supported versions table including `1.x` and `main`, and explicit text that webhook secrets, Hex API keys, and Release Please tokens must never be committed or printed in CI logs. Link these files from both package READMEs where relevant.</action>
  <acceptance_criteria>
    - `test -f CONTRIBUTING.md && test -f CODE_OF_CONDUCT.md && test -f SECURITY.md` exits 0.
    - `rg -n "^# Contributing$|## Development setup|## Conventional Commits|## Running the release gate locally|## No CLA|mix format --check-formatted|mix compile --warnings-as-errors|mix test --warnings-as-errors|mix credo --strict|mix dialyzer|mix docs --warnings-as-errors|mix hex.audit" CONTRIBUTING.md` returns matches.
    - `rg -n "Contributor Covenant|version 2\\.1|maintainers@accrue\\.dev" CODE_OF_CONDUCT.md` returns matches.
    - `rg -n "^# Security Policy$|## Supported Versions|1\\.x|main|## Reporting a Vulnerability|security@accrue\\.dev|webhook secrets|Hex API keys|Release Please tokens|never be committed|CI logs" SECURITY.md` returns matches.
    - `rg -n "\\[INSERT|TODO|TBD|@example\\.com|your@email" CONTRIBUTING.md CODE_OF_CONDUCT.md SECURITY.md` returns no matches.
  </acceptance_criteria>
  <verify>
    <automated>test -f CONTRIBUTING.md && test -f CODE_OF_CONDUCT.md && test -f SECURITY.md && rg -n "Conventional Commits|Contributor Covenant|Supported Versions|security@accrue.dev|maintainers@accrue.dev" CONTRIBUTING.md CODE_OF_CONDUCT.md SECURITY.md</automated>
  </verify>
  <done>The repo root exposes non-placeholder contribution, conduct, and security policies suitable for a public v1.0.0 release.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| published `accrue_admin` package to Hex consumers | The package dependency declaration must resolve on Hex when release jobs run inside the monorepo checkout. |
| public repository policy files to community and security reporters | Placeholder or misleading policy text would create false public assurances. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-09-05-01 | Tampering | `accrue_admin/mix.exs` | mitigate | Use one `accrue_dep()` helper gated by `System.get_env("ACCRUE_ADMIN_HEX_RELEASE") == "1"` so release jobs force the Hex version even though `../accrue` exists in CI checkouts. |
| T-09-05-02 | Repudiation | root policy files | mitigate | Ship concrete contact addresses and supported-version statements instead of placeholders or empty templates. |
| T-09-05-03 | Information Disclosure | `SECURITY.md` and README links | mitigate | State secret-handling rules explicitly and keep docs free of real webhook secrets, Hex keys, or Release Please tokens. |
</threat_model>

<verification>
Run `cd accrue_admin && mix docs --warnings-as-errors && ACCRUE_ADMIN_HEX_RELEASE=1 mix hex.build && ACCRUE_ADMIN_HEX_RELEASE=1 mix hex.publish --dry-run && test -f CONTRIBUTING.md && test -f CODE_OF_CONDUCT.md && test -f SECURITY.md`.
</verification>

<success_criteria>
The admin package is publishable on Hex from a monorepo checkout when `ACCRUE_ADMIN_HEX_RELEASE=1` is set, and the repository root exposes the required public OSS health files with concrete, non-placeholder text.
</success_criteria>

<output>
After completion, create `.planning/phases/09-release/09-05-SUMMARY.md`.
</output>
