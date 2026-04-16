# Phase 9: Release - Research

**Researched:** 2026-04-15
**Domain:** Elixir/Hex release automation, GitHub Actions CI, and OSS publication surface [VERIFIED: repo grep]
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

No Phase 09 `*-CONTEXT.md` exists in `.planning/phases/09-release/` at research time, so the effective constraints below are taken from the user prompt, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, and `CLAUDE.md`. [VERIFIED: gsd init phase-op 09][VERIFIED: repo grep]

### Locked Decisions

- Ship `accrue` `v1.0.0` and `accrue_admin` `v1.0.0` the same day to Hex through automated Release Please workflows. [VERIFIED: .planning/ROADMAP.md][VERIFIED: user prompt]
- CI must gate on `mix format --check-formatted`, `mix compile --warnings-as-errors`, `mix test --warnings-as-errors`, `mix credo --strict`, `mix dialyzer`, `mix docs --warnings-as-errors`, and `mix hex.audit`. [VERIFIED: .planning/ROADMAP.md][VERIFIED: .planning/REQUIREMENTS.md]
- CI must exercise Elixir/OTP version matrix coverage plus `with_sigra`/`without_sigra` and `with_opentelemetry`/`without_opentelemetry` compilation paths. [VERIFIED: .planning/ROADMAP.md][VERIFIED: .planning/REQUIREMENTS.md]
- The public OSS surface must include README quickstart, full ExDoc guide set, MIT license, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md` using Contributor Covenant 2.1, and `SECURITY.md`. [VERIFIED: .planning/ROADMAP.md][VERIFIED: .planning/REQUIREMENTS.md]
- The monorepo shape is fixed: sibling `accrue/` and `accrue_admin/` Mix projects, shared `.github/workflows/`, per-package `CHANGELOG.md`, MIT license. [VERIFIED: CLAUDE.md]

### Claude's Discretion

- Exact workflow split between CI, Release Please PR creation, and Hex publishing. [VERIFIED: user prompt]
- Exact Release Please manifest layout, publish ordering, and tag strategy, as long as both packages remain independently releasable and still ship same-day `1.0.0`. [VERIFIED: .planning/ROADMAP.md][VERIFIED: .planning/REQUIREMENTS.md]
- Exact ExDoc extras grouping, guide filenames, and README-to-guide link structure. [VERIFIED: .planning/ROADMAP.md]

### Deferred Ideas (OUT OF SCOPE)

- New billing or admin features are out of scope; Phase 9 is release machinery and OSS presentation only. [VERIFIED: .planning/phases/08-install-polish-testing/08-CONTEXT.md][VERIFIED: .planning/ROADMAP.md]
- Broad release work was explicitly deferred out of Phase 8 and belongs here. [VERIFIED: .planning/phases/08-install-polish-testing/08-CONTEXT.md]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OSS-01 | Monorepo with sibling mix projects, per-package `CHANGELOG.md`, shared `.github/workflows/` | Root manifest-based Release Please plus package-local changelogs and shared workflows are the standard shape for this repo. [VERIFIED: .planning/REQUIREMENTS.md][CITED: https://github.com/googleapis/release-please-action] |
| OSS-02 | Full GitHub Actions CI gate | Recommended matrix workflow covers all required checks for `accrue` and `accrue_admin`. [VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: repo grep][CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/run-job-variations] |
| OSS-03 | Elixir/OTP matrix in CI | GitHub Actions matrix is the standard implementation. [VERIFIED: .planning/REQUIREMENTS.md][CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/run-job-variations] |
| OSS-04 | Dialyzer PLT caching | Use split `actions/cache/restore@v4` and `actions/cache/save@v4` pattern keyed by OS, OTP, Elixir, and lockfile hash. [VERIFIED: .planning/REQUIREMENTS.md][CITED: https://github.com/actions/cache/blob/main/README.md] |
| OSS-05 | `with_sigra` and `without_sigra` matrix coverage | Keep explicit matrix cells; current repo already does this for `accrue` only and Phase 9 must harden it. [VERIFIED: repo grep][VERIFIED: .planning/REQUIREMENTS.md] |
| OSS-06 | `with_opentelemetry` and `without_opentelemetry` matrix coverage | Add explicit matrix cells or a secondary dimension; current repo does not have this yet. [VERIFIED: repo grep][VERIFIED: .planning/REQUIREMENTS.md] |
| OSS-07 | Release Please + Conventional Commits | Use Release Please v4 manifest mode with path-prefixed outputs. [VERIFIED: .planning/REQUIREMENTS.md][CITED: https://github.com/googleapis/release-please-action] |
| OSS-08 | Per-package Release Please configs | Implement as per-package entries inside one root manifest config file; this is the documented v4 monorepo model. [VERIFIED: .planning/REQUIREMENTS.md][CITED: https://github.com/googleapis/release-please-action] |
| OSS-09 | Hex publishing workflow with API token secret | Use `mix hex.publish --yes` in package directories with `HEX_API_KEY` provided by GitHub Actions secrets. [VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: local mix help hex.config][VERIFIED: local mix help hex.publish] |
| OSS-10 | Same-day v1.0 release runbook | Release Please does not enforce lockstep between package paths, so same-day `1.0.0` needs a documented operator runbook and explicit publish order. [VERIFIED: repo grep][CITED: https://github.com/googleapis/release-please-action] |
| OSS-12 | `CONTRIBUTING.md` | ExDoc extras and package files should include and surface it. [VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: local mix help hex.publish] |
| OSS-13 | `CODE_OF_CONDUCT.md` using Contributor Covenant 2.1 | Use the official 2.1 text and fill its reporting placeholders. [VERIFIED: .planning/REQUIREMENTS.md][CITED: https://www.contributor-covenant.org/version/2/1/code_of_conduct/] |
| OSS-14 | `SECURITY.md` disclosure process | Use GitHub-recognized `SECURITY.md` with supported versions and reporting instructions. [VERIFIED: .planning/REQUIREMENTS.md][CITED: https://docs.github.com/en/code-security/getting-started/adding-a-security-policy-to-your-repository] |
| OSS-15 | Public API facade docs with stability guarantees | ExDoc guides plus API docs need a clear public surface and deprecation policy. [VERIFIED: .planning/REQUIREMENTS.md][CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |
| OSS-16 | Full ExDoc guide set | ExDoc extras and groups are the standard implementation. [VERIFIED: .planning/REQUIREMENTS.md][CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |
| OSS-17 | README with 30-second quickstart | README must be package-local and linked from docs. [VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: local mix help hex.publish] |
| OSS-18 | `llms.txt` auto-generated via ExDoc | ExDoc 0.40.1 generates `llms.txt` and uses project `:description` in it. [VERIFIED: .planning/REQUIREMENTS.md][CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |
</phase_requirements>

## Summary

Phase 9 should be planned as four parallel tracks: `1)` CI hardening, `2)` Release Please + Hex publishing automation, `3)` package metadata and docs surface, and `4)` community-policy files plus release runbook. That split matches the repo boundary in the roadmap and avoids mixing release automation with docs authoring in the same plan. [VERIFIED: .planning/ROADMAP.md][VERIFIED: .planning/config.json]

The biggest implementation risk is not Release Please itself. It is the monorepo coupling between `accrue_admin` and `accrue`: the current `accrue_admin/mix.exs` uses a local `path: "../accrue"` dependency, while Release Please's Elixir updater only rewrites `@version` or inline `version:` strings in `mix.exs`. Phase 9 therefore needs an explicit strategy for publishable `accrue_admin` dependency metadata; otherwise the Hex package will be cut with the wrong dependency shape. [VERIFIED: repo grep][VERIFIED: https://raw.githubusercontent.com/googleapis/release-please/main/src/updaters/elixir/elixir-mix-exs.ts]

The second major planning point is that `mix hex.audit` is narrower than many teams expect: current Hex describes it as a retired-package check, not a vulnerability-advisory scanner. It still satisfies the locked requirement, but the plan should not assume it replaces Dependabot or advisory scanning. [VERIFIED: local mix help hex.audit]

**Primary recommendation:** Use one root Release Please v4 manifest with two package-path entries, one release workflow, and one publish workflow that publishes `accrue` first and `accrue_admin` second off path-prefixed outputs, while separately planning a deterministic fix for `accrue_admin`'s current `path:` dependency. [CITED: https://github.com/googleapis/release-please-action][VERIFIED: repo grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Conventional-commit versioning and changelog generation | GitHub Actions / Release Please | Git metadata | Release Please derives versions and changelog entries from commit history and opens release PRs; app code should not own this. [CITED: https://github.com/googleapis/release-please-action] |
| CI quality gates for `accrue` and `accrue_admin` | GitHub Actions / CI | Mix tasks inside each package | The gate is enforced in workflows, but the actual checks are package-local `mix` commands. [VERIFIED: repo grep][CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/run-job-variations] |
| Hex package publishing | Hex.pm registry | GitHub Actions | `mix hex.publish` runs inside CI, but the ownership boundary is Hex package metadata plus Hex API auth. [VERIFIED: local mix help hex.publish][VERIFIED: local mix help hex.config] |
| API docs, guides, and `llms.txt` | ExDoc config in each package | README/community docs at repo root | ExDoc owns generated docs output; root docs exist to route contributors and security reporters. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html][VERIFIED: repo grep] |
| Community health files (`CONTRIBUTING`, `CODE_OF_CONDUCT`, `SECURITY`) | Repo root | GitHub repository health surfaces | GitHub recognizes these files from standard locations and links them in repo UI. [CITED: https://docs.github.com/en/code-security/getting-started/adding-a-security-policy-to-your-repository][CITED: https://www.contributor-covenant.org/version/2/1/code_of_conduct/] |

## Project Constraints (from CLAUDE.md)

- Support floor is Elixir `1.17+`, OTP `27+`, Phoenix `1.8+`, Ecto `3.12+`, PostgreSQL `14+`; Phase 9 CI must not plan lower versions. [VERIFIED: CLAUDE.md]
- The repo is a monorepo with sibling `accrue/` and `accrue_admin/`, shared `.github/workflows/`, and per-package `CHANGELOG.md`. [VERIFIED: CLAUDE.md]
- First public release is conceptually `v1.0`; no public `v0.x` iteration cycle is planned. [VERIFIED: CLAUDE.md]
- MIT is the required license for both packages. [VERIFIED: CLAUDE.md]
- Security expectations already locked elsewhere still apply to docs and examples: webhook signature verification is mandatory, secrets must never be logged, and sensitive Stripe fields must not appear in docs snippets or CI output. [VERIFIED: CLAUDE.md]

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `googleapis/release-please-action` | `v4.4.1` (published 2026-04-13) [VERIFIED: GitHub API] | Release PRs, CHANGELOG generation, GitHub releases | Official v4 action supports manifest-based monorepos and path-prefixed outputs for per-package publishing. [CITED: https://github.com/googleapis/release-please-action] |
| `erlef/setup-beam` | `v1.24.0` (published 2026-03-30) [VERIFIED: GitHub API] | Install Elixir/OTP in Actions | This is the standard BEAM setup action already used in the repo. [VERIFIED: repo grep] |
| `actions/cache/restore` + `actions/cache/save` | `v4` interface; latest upstream release `v5.0.5` published 2026-04-13 [VERIFIED: GitHub API] | Dependency and PLT caching | The documented split restore/save pattern avoids unnecessary cache churn and is already partly adopted here for Dialyzer PLTs. [CITED: https://github.com/actions/cache/blob/main/README.md][VERIFIED: repo grep] |
| `ex_doc` | `0.40.1` (updated 2026-01-31) [VERIFIED: Hex API] | API docs, guides, `llms.txt` | Official ExDoc 0.40.1 documents `llms.txt`, `extras`, `groups_for_extras`, and `--warnings-as-errors`. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html][VERIFIED: local mix help docs] |
| Hex built-in tasks | Hex `2.4.1` locally [VERIFIED: local mix hex.info] | Publishing and retired-package auditing | `mix hex.publish` and `mix hex.audit` are official Hex tasks; no third-party publish wrapper is needed. [VERIFIED: local mix help hex.publish][VERIFIED: local mix help hex.audit] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `actions/checkout` | `v4` in current repo [VERIFIED: repo grep] | Repository checkout in workflows | Use in every CI and publish job before running `mix` commands. [VERIFIED: repo grep] |
| `actions/setup-node` | `v4` in current repo [VERIFIED: repo grep] | Playwright/browser workflow dependency setup | Keep for `accrue_admin` browser UAT and any docs asset generation that needs Node. [VERIFIED: repo grep] |
| Contributor Covenant | `2.1` [CITED: https://www.contributor-covenant.org/version/2/1/code_of_conduct/] | Code of conduct text | Use the official text and fill the contact placeholders before publish. [CITED: https://www.contributor-covenant.org/version/2/1/code_of_conduct/] |
| GitHub community health files | current GitHub docs checked 2026-04-15 [CITED: https://docs.github.com/en/code-security/getting-started/adding-a-security-policy-to-your-repository] | `SECURITY.md` repository recognition | Use standard root placement and link from README. [CITED: https://docs.github.com/en/code-security/getting-started/adding-a-security-policy-to-your-repository] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Release Please manifest monorepo | Two fully separate release workflows with manual version bumping | More moving parts and less consistent changelog/version logic for two sibling packages. [CITED: https://github.com/googleapis/release-please-action] |
| `mix hex.audit` only | `mix_audit` as an additional advisory check | `mix_audit` adds broader advisory scanning, but the locked requirement explicitly names `mix hex.audit`; treat `mix_audit` as optional extra safety, not the primary gate. [VERIFIED: local mix help hex.audit][VERIFIED: Hex API package mix_audit] |
| Package-local docs only | README-only documentation | README alone will not satisfy the required guide set or generated `llms.txt`. [VERIFIED: .planning/REQUIREMENTS.md][CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |

**Installation / tool verification:**

```bash
gh api repos/googleapis/release-please-action/releases/latest
gh api repos/actions/cache/releases/latest
gh api repos/erlef/setup-beam/releases/latest
curl -s https://hex.pm/api/packages/ex_doc | jq '.latest_version, .updated_at'
```

## Architecture Patterns

### System Architecture Diagram

```text
Conventional Commits on main
        |
        v
Release Please workflow
  - reads manifest config
  - updates per-package CHANGELOG + version
  - opens/updates release PRs
        |
        v
Merged release PR
        |
        v
Release workflow outputs
  - accrue--release_created
  - accrue_admin--release_created
  - path-specific versions/tags
        |
        +------------------------------+
        |                              |
        v                              v
Publish accrue to Hex          Publish accrue_admin to Hex
  - checkout tag/sha             - checkout same commit
  - mix deps.get                 - mix deps.get
  - mix hex.publish --yes        - mix hex.publish --yes
        |                              |
        +---------------+--------------+
                        |
                        v
ExDoc / HexDocs
  - package API docs
  - extras guides
  - llms.txt
                        |
                        v
Repo health surface
  README / CONTRIBUTING / CODE_OF_CONDUCT / SECURITY
```

### Recommended Project Structure

```text
.github/
└── workflows/
    ├── ci.yml                  # unified package/test/docs/audit matrix
    ├── release-please.yml      # Release Please PR + release creation
    └── publish-hex.yml         # publish from release outputs
release-please-config.json      # root manifest config
.release-please-manifest.json   # per-path versions
CONTRIBUTING.md                 # repo root
CODE_OF_CONDUCT.md              # repo root
SECURITY.md                     # repo root
accrue/
├── CHANGELOG.md
├── README.md
├── guides/
└── mix.exs
accrue_admin/
├── CHANGELOG.md
├── README.md
├── guides/
└── mix.exs
```

### Pattern 1: Root Manifest Release Please for Both Packages

**What:** One root `release-please-config.json` with two package entries and one `.release-please-manifest.json`. [CITED: https://github.com/googleapis/release-please-action]
**When to use:** Always for this repo; the sibling packages live in one git history and already share workflows. [VERIFIED: CLAUDE.md][VERIFIED: repo grep]
**Example:**

```yaml
# Source: https://github.com/googleapis/release-please-action
steps:
  - uses: googleapis/release-please-action@v4
    id: release
    with:
      token: ${{ secrets.RELEASE_PLEASE_TOKEN }}
      config-file: release-please-config.json
      manifest-file: .release-please-manifest.json
```

### Pattern 2: Path-Prefixed Publish Steps

**What:** Gate publish jobs on `steps.release.outputs['accrue--release_created']` and `steps.release.outputs['accrue_admin--release_created']`. [CITED: https://github.com/googleapis/release-please-action]
**When to use:** Every automated publish path after Release Please creates a release. [CITED: https://github.com/googleapis/release-please-action]
**Example:**

```yaml
# Source: https://github.com/googleapis/release-please-action
- name: Publish accrue
  if: ${{ steps.release.outputs['accrue--release_created'] }}
  run: cd accrue && mix hex.publish --yes
  env:
    HEX_API_KEY: ${{ secrets.HEX_API_KEY }}
```

### Pattern 3: Split Restore/Save PLT Cache

**What:** Restore PLTs first, build them only on cache miss, then save using the restore step's primary key. [CITED: https://github.com/actions/cache/blob/main/README.md]
**When to use:** Dialyzer jobs in CI. [VERIFIED: .planning/REQUIREMENTS.md]
**Example:**

```yaml
# Source: https://github.com/actions/cache/blob/main/README.md
- uses: actions/cache/restore@v4
  id: plt-cache
  with:
    path: accrue/priv/plts
    key: ${{ runner.os }}-${{ matrix.otp }}-${{ matrix.elixir }}-plt-${{ hashFiles('accrue/mix.lock') }}

- if: steps.plt-cache.outputs.cache-hit != 'true'
  run: cd accrue && mix dialyzer --plt

- if: steps.plt-cache.outputs.cache-hit != 'true'
  uses: actions/cache/save@v4
  with:
    path: accrue/priv/plts
    key: ${{ steps.plt-cache.outputs.cache-primary-key }}
```

### Pattern 4: ExDoc Extras as the Guide System

**What:** Use `docs: [extras: ..., groups_for_extras: ...]` in `mix.exs` instead of a hand-built docs site. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html]
**When to use:** All required release guides. [VERIFIED: .planning/REQUIREMENTS.md]
**Example:**

```elixir
# Source: https://hexdocs.pm/ex_doc/ExDoc.html
defp docs do
  [
    main: "readme",
    source_ref: "v#{@version}",
    extras: [
      "README.md",
      "guides/quickstart.md",
      "guides/testing.md"
    ],
    groups_for_extras: [
      Guides: Path.wildcard("guides/*.md")
    ]
  ]
end
```

### Anti-Patterns to Avoid

- **One workflow trying to do CI, open release PRs, and publish in one job:** It makes permissions and failure handling harder, and it obscures whether a failure is a test failure or a publish failure. [CITED: https://github.com/googleapis/release-please-action]
- **Using only `GITHUB_TOKEN` for Release Please when downstream workflows must react to release PRs or release events:** the Release Please README explicitly warns that events created by `GITHUB_TOKEN` do not trigger new workflow runs. [CITED: https://github.com/googleapis/release-please-action]
- **Assuming Release Please will fix `accrue_admin`'s local `path:` dependency:** the Elixir updater only rewrites version strings. [VERIFIED: repo grep][VERIFIED: https://raw.githubusercontent.com/googleapis/release-please/main/src/updaters/elixir/elixir-mix-exs.ts]
- **Assuming `mix hex.audit` is an advisory scanner:** current Hex says it reports retired packages only. [VERIFIED: local mix help hex.audit]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Automated changelog + release PR management | Custom changelog scripts | Release Please v4 manifest mode | It already handles Conventional Commits, per-path outputs, and release PR lifecycle. [CITED: https://github.com/googleapis/release-please-action] |
| Static docs site for guides | Custom docs generator | ExDoc extras and groups | ExDoc already generates API docs, extras, and `llms.txt`. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |
| Code-of-conduct prose | Hand-written conduct policy | Contributor Covenant 2.1 | The official template is standardized and GitHub-visible. [CITED: https://www.contributor-covenant.org/version/2/1/code_of_conduct/] |
| Security reporting page | Ad hoc README section | `SECURITY.md` at repo root | GitHub recognizes the standard file and links it in repository security surfaces. [CITED: https://docs.github.com/en/code-security/getting-started/adding-a-security-policy-to-your-repository] |
| Hex publish wrapper | Custom API client | `mix hex.publish --yes` | Official task already builds package and docs and publishes them. [VERIFIED: local mix help hex.publish] |

**Key insight:** Phase 9 is mostly about using the ecosystem's standard release surfaces correctly and filling the gaps in the current repo; custom automation increases the chance of a broken first public release. [CITED: https://github.com/googleapis/release-please-action][VERIFIED: repo grep]

## Common Pitfalls

### Pitfall 1: `accrue_admin` ships with a local path dependency

**What goes wrong:** The published `accrue_admin` tarball can reference `{:accrue, path: "../accrue"}`, which is valid in the monorepo but invalid for Hex consumers. [VERIFIED: repo grep]
**Why it happens:** Current `accrue_admin/mix.exs` is still in local-dev shape, and Release Please's Elixir updater only edits version strings. [VERIFIED: repo grep][VERIFIED: https://raw.githubusercontent.com/googleapis/release-please/main/src/updaters/elixir/elixir-mix-exs.ts]
**How to avoid:** Make dependency publication strategy a first-class plan item before the first release dry run. [VERIFIED: repo grep]
**Warning signs:** Release PR bumps `@version` but leaves the sibling dependency untouched. [VERIFIED: repo grep]

### Pitfall 2: Release Please PRs do not trigger the workflows you expect

**What goes wrong:** CI or publish workflows fail to run on Release Please-created PRs or release events. [CITED: https://github.com/googleapis/release-please-action]
**Why it happens:** The default `GITHUB_TOKEN` does not trigger new workflow runs for events it creates. [CITED: https://github.com/googleapis/release-please-action]
**How to avoid:** Use a dedicated PAT secret for Release Please and grant `contents`, `issues`, and `pull-requests` permissions in the workflow. [CITED: https://github.com/googleapis/release-please-action]
**Warning signs:** Release PR opens successfully, but required checks or follow-on publish workflows never start. [CITED: https://github.com/googleapis/release-please-action]

### Pitfall 3: CI covers only `accrue`

**What goes wrong:** `accrue` can pass release CI while `accrue_admin` still lacks docs, README, changelog, or compile/credo coverage. [VERIFIED: repo grep]
**Why it happens:** Current main CI is centered on `accrue`; admin checks are split across separate assets and browser workflows. [VERIFIED: repo grep]
**How to avoid:** Make the Phase 9 CI design package-aware and include admin documentation and compile checks in the release gate. [VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: repo grep]
**Warning signs:** `accrue_admin/mix.exs` has no `docs()` config and no `CHANGELOG.md` or `README.md` present. [VERIFIED: repo grep]

### Pitfall 4: Treating `mix hex.audit` as vulnerability scanning

**What goes wrong:** The release gate claims security coverage it does not actually provide. [VERIFIED: local mix help hex.audit]
**Why it happens:** The task name sounds broader than its current scope; Hex documents it as a retired-package check. [VERIFIED: local mix help hex.audit]
**How to avoid:** Keep the gate because it is required, but document its actual scope in the release guide and leave advisory scanning to Dependabot or optional `mix_audit`. [VERIFIED: local mix help hex.audit][VERIFIED: Hex API package mix_audit]
**Warning signs:** Planning text uses phrases like "dependency vulnerability scan" while the workflow only runs `mix hex.audit`. [VERIFIED: local mix help hex.audit]

### Pitfall 5: ExDoc warnings are suppressed instead of fixed

**What goes wrong:** Broken guide links or missing references ship in the first public docs set. [VERIFIED: repo grep][VERIFIED: local mix help docs]
**Why it happens:** Current `accrue` docs config already skips some undefined-reference warnings; expanding the docs surface increases the chance of papering over new issues. [VERIFIED: repo grep]
**How to avoid:** Keep skips narrowly scoped and treat new guide/reference warnings as release blockers. [VERIFIED: repo grep][VERIFIED: local mix help docs]
**Warning signs:** `mix docs --warnings-as-errors` fails only after adding the full guide set. [VERIFIED: local mix help docs]

## Code Examples

Verified patterns from official sources:

### Release Please Monorepo Outputs

```yaml
# Source: https://github.com/googleapis/release-please-action
- uses: googleapis/release-please-action@v4
  id: release
  with:
    token: ${{ secrets.RELEASE_PLEASE_TOKEN }}
    config-file: release-please-config.json
    manifest-file: .release-please-manifest.json

- name: Publish accrue_admin
  if: ${{ steps.release.outputs['accrue_admin--release_created'] }}
  run: cd accrue_admin && mix hex.publish --yes
  env:
    HEX_API_KEY: ${{ secrets.HEX_API_KEY }}
```

### ExDoc Warning Gate

```bash
# Source: local `mix help docs`
cd accrue && mix docs --warnings-as-errors
cd ../accrue_admin && mix docs --warnings-as-errors
```

### Hex Publish Auth Surface

```bash
# Source: local `mix help hex.config` and `mix help hex.publish`
export HEX_API_KEY=...
cd accrue && mix hex.publish --yes
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Action-input-heavy Release Please config | v4 manifest config as the default advanced setup | Documented in Release Please v4 upgrade section, checked 2026-04-15. [CITED: https://github.com/googleapis/release-please-action] | Phase 9 should use root manifest files, not older action-input mapping. [CITED: https://github.com/googleapis/release-please-action] |
| Single `actions/cache` step everywhere | Split `restore` and `save` actions for controlled caching | Documented in current cache README, checked 2026-04-15. [CITED: https://github.com/actions/cache/blob/main/README.md] | Better PLT cache behavior and fewer unnecessary uploads. [CITED: https://github.com/actions/cache/blob/main/README.md] |
| README-only package docs | ExDoc extras plus generated `llms.txt` | Present in ExDoc 0.40.1 docs, checked 2026-04-15. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] | Phase 9 can satisfy both human docs and AI-friendly reference from one toolchain. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |

**Deprecated/outdated:**

- Configuring Release Please advanced monorepo behavior primarily through action inputs is outdated in v4; use manifest config files instead. [CITED: https://github.com/googleapis/release-please-action]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `accrue_admin` needs an explicit publish-mode switch rather than a file-system-only dependency helper, because GitHub Actions publish jobs run from a monorepo checkout where `../accrue` exists. [VERIFIED: plan-checker feedback][VERIFIED: repo grep] | Resolved Release Decisions | Low: execution can verify with `ACCRUE_ADMIN_HEX_RELEASE=1 mix hex.build` / `mix hex.publish --dry-run`. |

## Open Questions (RESOLVED)

1. **How will `accrue_admin` express its dependency on `accrue` at publish time?**
   - What we know: current source uses `path: "../accrue"`, and Release Please's Elixir updater only rewrites version strings. [VERIFIED: repo grep][VERIFIED: https://raw.githubusercontent.com/googleapis/release-please/main/src/updaters/elixir/elixir-mix-exs.ts]
   - Resolution: use a permanent dual-mode dependency helper with an explicit publish switch, not a directory-existence heuristic. `accrue_admin/mix.exs` should call `accrue_dep()` and return `{:accrue, "~> #{@version}"}` when `System.get_env("ACCRUE_ADMIN_HEX_RELEASE") == "1"`, otherwise return `{:accrue, path: "../accrue"}` for monorepo development. The publish workflow must set `ACCRUE_ADMIN_HEX_RELEASE: "1"` for admin package dry-run/build/publish steps. [VERIFIED: plan-checker feedback][VERIFIED: local mix help hex.publish]
   - Verification: require `cd accrue_admin && ACCRUE_ADMIN_HEX_RELEASE=1 mix hex.publish --dry-run` and a grep check proving the top-level deps list has only `accrue_dep()`, not a literal top-level `{:accrue, path: "../accrue"}` tuple. [VERIFIED: local mix help hex.publish]

2. **Will the team require broader advisory scanning beyond `mix hex.audit`?**
   - What we know: `mix hex.audit` currently checks retired packages only. [VERIFIED: local mix help hex.audit]
   - Resolution: keep `mix hex.audit` as the required Phase 9 release gate because it is the locked requirement. Do not claim it is vulnerability scanning. Broader advisory scanning can be captured as follow-up/backlog work rather than blocking Phase 9. [VERIFIED: local mix help hex.audit][VERIFIED: Hex API package mix_audit]

3. **What contact channel will go into Contributor Covenant and `SECURITY.md`?**
   - What we know: both templates require real reporting/contact details. [CITED: https://www.contributor-covenant.org/version/2/1/code_of_conduct/][CITED: https://docs.github.com/en/code-security/getting-started/adding-a-security-policy-to-your-repository]
   - Resolution: use concrete placeholder project addresses `maintainers@accrue.dev` for conduct/contribution contact and `security@accrue.dev` for vulnerability reports, with the final release checkpoint explicitly asking the maintainer to approve or replace them before public publish. [ASSUMED: project-owned domain/contact pending final release approval]

4. **How does the first public release become `v1.0.0` instead of a pre-1.0 bump?**
   - What we know: the current package versions are `0.1.0`, while the phase goal requires same-day `v1.0.0` releases for both packages. [VERIFIED: repo grep][VERIFIED: .planning/ROADMAP.md]
   - Resolution: plan the first-public release as an explicit bootstrap release. Seed `.release-please-manifest.json` from the current `0.1.0` state, then require the triggering Conventional Commit or manual release PR instructions to include a documented `Release-As: 1.0.0` footer for both package paths, and require the final release PR to show `@version "1.0.0"` plus `accrue` and `accrue_admin` GitHub release tags for `v1.0.0` before publishing. If Release Please cannot produce both path releases from that bootstrap path during dry-run review, the runbook must fall back to a manual release PR that sets both package versions and changelogs to `1.0.0` before invoking publish. [CITED: https://github.com/googleapis/release-please-action][VERIFIED: plan-checker feedback]
   - Recommendation: collect those values before doc-writing plans start so the files do not ship with placeholders. [CITED: https://www.contributor-covenant.org/version/2/1/code_of_conduct/]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `elixir` / `mix` | Local dry runs for CI and publish commands | ✓ [VERIFIED: local command] | Elixir `1.19.5`, Mix `1.19.5` [VERIFIED: local command] | — |
| `git` | Release/tag workflows and local validation | ✓ [VERIFIED: local command] | `2.41.0` [VERIFIED: local command] | — |
| `gh` | GitHub API verification and optional release artifact work | ✓ [VERIFIED: local command] | `2.89.0` [VERIFIED: local command] | Use raw `curl` to GitHub API if needed. [VERIFIED: local command] |
| `node` / `npm` | Existing admin browser workflow and docs/browser checks | ✓ [VERIFIED: local command] | Node `22.14.0`, npm `11.1.0` [VERIFIED: local command] | — |
| `jq` / `curl` | Registry/API verification scripts | ✓ [VERIFIED: local command] | `jq 1.7.1`, `curl 8.7.1` [VERIFIED: local command] | — |
| `HEX_API_KEY` | Automated Hex publish in CI | ✗ in local environment [VERIFIED: env grep] | — | Must be added as a GitHub Actions secret; no local fallback for automated publish. [VERIFIED: local mix help hex.config] |
| Release Please PAT secret | Release Please PRs that trigger downstream workflows | Unknown in repo settings; not present in local env [VERIFIED: env grep] | — | `GITHUB_TOKEN` works for basic operation but will not trigger downstream workflows created by Release Please. [CITED: https://github.com/googleapis/release-please-action] |

**Missing dependencies with no fallback:**

- `HEX_API_KEY` for automated `mix hex.publish --yes`. [VERIFIED: env grep][VERIFIED: local mix help hex.config]

**Missing dependencies with fallback:**

- Dedicated Release Please PAT secret. Basic Release Please can use `GITHUB_TOKEN`, but same-repo downstream workflow triggering needs a PAT. [CITED: https://github.com/googleapis/release-please-action]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit + package-local mix tasks + GitHub Actions workflow validation. [VERIFIED: repo grep] |
| Config file | No dedicated release-phase config file; package commands are driven from `mix.exs` and workflow YAML. [VERIFIED: repo grep] |
| Quick run command | `cd accrue && mix format --check-formatted && mix compile --warnings-as-errors && mix docs --warnings-as-errors && mix hex.audit` [VERIFIED: local mix help docs][VERIFIED: local mix help hex.audit] |
| Full suite command | `cd accrue && mix format --check-formatted && mix compile --warnings-as-errors && mix test --warnings-as-errors && mix credo --strict && mix dialyzer && mix docs --warnings-as-errors && mix hex.audit` plus equivalent admin package checks and browser/assets workflows. [VERIFIED: .planning/ROADMAP.md][VERIFIED: repo grep] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| OSS-01 | Both packages have release metadata and changelogs | smoke | `test -f accrue/CHANGELOG.md && test -f accrue_admin/CHANGELOG.md` | ❌ Wave 0 [VERIFIED: repo grep] |
| OSS-02 | CI enforces full release gate | workflow smoke | `actionlint .github/workflows/*.yml` [ASSUMED] | ❌ Wave 0 |
| OSS-03 | Elixir/OTP matrix expands correctly | workflow smoke | inspect matrix in `.github/workflows/ci.yml` plus local dry-run review [VERIFIED: repo grep] | ⚠ partial [VERIFIED: repo grep] |
| OSS-04 | Dialyzer uses split cache restore/save | workflow smoke | `rg -n "actions/cache/(restore|save)@v4|dialyzer" .github/workflows/ci.yml` | ✅ [VERIFIED: repo grep] |
| OSS-05 | Sigra on/off compilation is gated | workflow smoke | `bash scripts/ci/compile_matrix.sh` | ✅ [VERIFIED: repo grep] |
| OSS-06 | OTel on/off compilation is gated | test + workflow smoke | add explicit matrix entry and run compile/tests | ❌ Wave 0 [VERIFIED: repo grep] |
| OSS-07 | Release Please opens correct release PRs | manual + workflow smoke | merge a test Conventional Commit in a dry-run branch or sandbox repo [ASSUMED] | ❌ Wave 0 |
| OSS-08 | Per-package release config works | workflow smoke | validate `release-please-config.json` and `.release-please-manifest.json` presence and path entries | ❌ Wave 0 [VERIFIED: repo grep] |
| OSS-09 | Hex publish workflow uses token secret correctly | manual + workflow smoke | `cd accrue && mix hex.publish --dry-run` and inspect workflow env usage | ❌ Wave 0 [VERIFIED: local mix help hex.publish] |
| OSS-10 | Same-day v1.0 runbook is documented | docs smoke | `rg -n "same-day|runbook|1.0.0" -g '*.md'` | ❌ Wave 0 [VERIFIED: repo grep] |
| OSS-12 | Contributing guide exists and is linked | docs smoke | `test -f CONTRIBUTING.md && rg -n "CONTRIBUTING" accrue/README.md accrue_admin/README.md` | ❌ Wave 0 [VERIFIED: repo grep] |
| OSS-13 | Code of conduct exists and uses 2.1 | docs smoke | `test -f CODE_OF_CONDUCT.md && rg -n "version 2.1|Contributor Covenant" CODE_OF_CONDUCT.md` | ❌ Wave 0 [VERIFIED: repo grep] |
| OSS-14 | Security policy exists and is complete | docs smoke | `test -f SECURITY.md && rg -n "supported versions|report" SECURITY.md` | ❌ Wave 0 [VERIFIED: repo grep] |
| OSS-15 | Public API and deprecation policy are documented | docs smoke | `mix docs --warnings-as-errors` plus link checks in README/guides | ⚠ partial [VERIFIED: repo grep][VERIFIED: local mix help docs] |
| OSS-16 | Full guide set exists | docs smoke | `find accrue/guides accrue_admin/guides -type f` | ❌ Wave 0 [VERIFIED: repo grep] |
| OSS-17 | README quickstart exists | docs smoke | `test -f accrue/README.md && test -f accrue_admin/README.md` | ❌ Wave 0 [VERIFIED: repo grep] |
| OSS-18 | `llms.txt` is generated | docs smoke | `cd accrue && mix docs && test -f doc/llms.txt` [ASSUMED] | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** run the narrowest affected package command set, at minimum `mix compile --warnings-as-errors` or `mix docs --warnings-as-errors` in the touched package. [VERIFIED: local mix help docs]
- **Per wave merge:** run the full release-gate command set for both packages. [VERIFIED: .planning/ROADMAP.md]
- **Phase gate:** all release workflows, docs, and community files green before `/gsd-verify-work`. [VERIFIED: .planning/config.json]

### Wave 0 Gaps

- [ ] `.github/workflows/release-please.yml` - Release Please workflow. [VERIFIED: repo grep]
- [ ] `.github/workflows/publish-hex.yml` - automated publish workflow. [VERIFIED: repo grep]
- [ ] `release-please-config.json` - monorepo package config. [VERIFIED: repo grep]
- [ ] `.release-please-manifest.json` - per-path version manifest. [VERIFIED: repo grep]
- [ ] `accrue/README.md` and `accrue_admin/README.md` - package quickstarts. [VERIFIED: repo grep]
- [ ] `accrue/CHANGELOG.md` and `accrue_admin/CHANGELOG.md` - release-managed changelogs. [VERIFIED: repo grep]
- [ ] `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md` - repo health files. [VERIFIED: repo grep]
- [ ] `accrue_admin` docs config in `mix.exs` - docs are not configured there yet. [VERIFIED: repo grep]
- [ ] `with_opentelemetry` CI matrix coverage. [VERIFIED: repo grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Release phase does not add end-user auth flows. [VERIFIED: .planning/ROADMAP.md] |
| V3 Session Management | no | Not part of this phase. [VERIFIED: .planning/ROADMAP.md] |
| V4 Access Control | yes | Use least-privilege GitHub workflow permissions and separate secrets for Release Please and Hex publishing. [CITED: https://github.com/googleapis/release-please-action] |
| V5 Input Validation | yes | Keep docs/examples sanitized and let `mix docs --warnings-as-errors` catch broken references before publish. [VERIFIED: local mix help docs][VERIFIED: CLAUDE.md] |
| V6 Cryptography | yes | Do not hand-roll publish auth; use Hex API key handling and GitHub secret storage. [VERIFIED: local mix help hex.config] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Secret leakage in CI logs | Information Disclosure | Use GitHub Secrets, avoid echoing env vars, and keep docs/examples free of real keys. [VERIFIED: CLAUDE.md][VERIFIED: local mix help hex.config] |
| Over-privileged release workflow token | Elevation of Privilege | Scope workflow permissions to `contents`, `issues`, and `pull-requests`, and use PAT only where event propagation is required. [CITED: https://github.com/googleapis/release-please-action] |
| Publishing wrong package contents | Tampering | Run `mix hex.publish --dry-run` and inspect package files before first real publish. [VERIFIED: local mix help hex.publish] |
| Placeholder policy files shipping to public repo | Repudiation | Treat `CONTRIBUTING`, `CODE_OF_CONDUCT`, and `SECURITY` placeholders as release blockers. [CITED: https://www.contributor-covenant.org/version/2/1/code_of_conduct/][CITED: https://docs.github.com/en/code-security/getting-started/adding-a-security-policy-to-your-repository] |

## Sources

### Primary (HIGH confidence)

- `CLAUDE.md` - project constraints, monorepo shape, version floors, release model. [VERIFIED: repo file]
- `.planning/REQUIREMENTS.md` - Phase 9 requirement IDs and acceptance surface. [VERIFIED: repo file]
- `.planning/ROADMAP.md` - Phase 9 goal and success criteria. [VERIFIED: repo file]
- `.planning/STATE.md` - current phase state and prior decisions. [VERIFIED: repo file]
- `.planning/phases/08-install-polish-testing/08-CONTEXT.md` - explicit Phase 8 boundary and Phase 9 deferrals. [VERIFIED: repo file]
- `accrue/mix.exs`, `accrue_admin/mix.exs`, `.github/workflows/*.yml` - current repo implementation state. [VERIFIED: repo grep]
- Release Please Action README - manifest config, permissions, path outputs, token behavior. [CITED: https://github.com/googleapis/release-please-action]
- Release Please Elixir updater source - updater behavior for `mix.exs`. [VERIFIED: https://raw.githubusercontent.com/googleapis/release-please/main/src/updaters/elixir/elixir-mix-exs.ts]
- GitHub Docs: matrix strategies. [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/run-job-variations]
- GitHub Actions cache README. [CITED: https://github.com/actions/cache/blob/main/README.md]
- ExDoc 0.40.1 docs. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html]
- Local `mix help docs`, `mix help hex.publish`, `mix help hex.audit`, `mix help hex.config`, `mix hex.info`. [VERIFIED: local tool output]
- Contributor Covenant 2.1 official page. [CITED: https://www.contributor-covenant.org/version/2/1/code_of_conduct/]
- GitHub Docs: `SECURITY.md` policy guidance. [CITED: https://docs.github.com/en/code-security/getting-started/adding-a-security-policy-to-your-repository]
- GitHub API release metadata for `release-please-action`, `actions/cache`, `setup-beam`. [VERIFIED: GitHub API]
- Hex.pm API metadata for `ex_doc`, `credo`, `dialyxir`, `mix_audit`, `oban`, `phoenix_live_view`. [VERIFIED: Hex API]

### Secondary (MEDIUM confidence)

- Context7 CLI fallback for Release Please and Actions Cache examples. [VERIFIED: ctx7 CLI]

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all core tools were verified from official docs, APIs, or repo state.
- Architecture: HIGH - the repo boundary is explicit and Release Please monorepo behavior is documented.
- Pitfalls: HIGH - the biggest risks come directly from current repo code and official tool behavior.

**Research date:** 2026-04-15
**Valid until:** 2026-05-15
