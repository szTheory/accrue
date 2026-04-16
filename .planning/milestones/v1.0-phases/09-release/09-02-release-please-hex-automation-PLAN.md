---
phase: 09-release
plan: 02
type: execute
wave: 1
depends_on: []
files_modified:
  - .github/workflows/release-please.yml
  - .github/workflows/publish-hex.yml
  - release-please-config.json
  - .release-please-manifest.json
  - RELEASING.md
autonomous: true
requirements: [OSS-07, OSS-08, OSS-09, OSS-10]
must_haves:
  truths:
    - "Conventional Commits on main can open per-package release PRs for both packages."
    - "Hex publication is gated on real Release Please outputs inside one workflow/job graph and happens in same-day order."
    - "Release automation documents the exact bootstrap path to first public v1.0.0 for both packages."
  artifacts:
    - path: ".github/workflows/release-please.yml"
      provides: "Release Please workflow with least-privilege permissions"
    - path: ".github/workflows/publish-hex.yml"
      provides: "Automated Hex publish workflow for both packages"
    - path: "release-please-config.json"
      provides: "Root manifest package configuration"
    - path: ".release-please-manifest.json"
      provides: "Package version manifest"
    - path: "RELEASING.md"
      provides: "Same-day release runbook"
  key_links:
    - from: ".github/workflows/release-please.yml"
      to: "release-please-config.json"
      via: "config-file input"
      pattern: "config-file: release-please-config.json"
    - from: ".github/workflows/release-please.yml"
      to: ".github/workflows/release-please.yml"
      via: "release job outputs into publish jobs"
      pattern: "needs.release.outputs.accrue_release_created"
    - from: ".github/workflows/publish-hex.yml"
      to: "RELEASING.md"
      via: "manual recovery inputs"
      pattern: "workflow_dispatch"
---

<objective>
Automate Release Please and Hex publishing, and codify the same-day release procedure.

Purpose: make the first public release reproducible, least-privilege, and safe against wrong-ref publishing or package-order mistakes.
Output: Release Please workflow, publish workflow, manifest config, manifest versions, and same-day release runbook.
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
</context>

<tasks>

<task type="auto">
  <name>Task 1: Create root-manifest Release Please automation with least-privilege permissions</name>
  <files>.github/workflows/release-please.yml, release-please-config.json, .release-please-manifest.json</files>
  <read_first>
    - .planning/phases/09-release/09-RESEARCH.md
    - .planning/phases/09-release/09-VALIDATION.md
    - .planning/phases/09-release/09-PATTERNS.md
    - .github/workflows/ci.yml
    - accrue/mix.exs
    - accrue_admin/mix.exs
  </read_first>
  <action>Create `.github/workflows/release-please.yml`, `release-please-config.json`, and `.release-please-manifest.json` in manifest mode per OSS-07 and OSS-08, using the resolved bootstrap decision from `09-RESEARCH.md`. The workflow must run on pushes to `main` plus `workflow_dispatch`, use `googleapis/release-please-action@v4`, set `id: release`, and pass `token: ${{ secrets.RELEASE_PLEASE_TOKEN }}`, `config-file: release-please-config.json`, and `manifest-file: .release-please-manifest.json`. Set workflow `permissions` to exactly `contents: write`, `issues: write`, and `pull-requests: write`. Do not trigger from pull requests, forks, tags, or release events. In `release-please-config.json`, define two packages keyed by path: `accrue` and `accrue_admin`, each with `release-type: "elixir"`, `package-name` matching the Mix app name, `changelog-path` matching the package-local `CHANGELOG.md`, and `include-component-in-tag: true`. Seed `.release-please-manifest.json` from the current `0.1.0` state, but explicitly plan the first public release as `1.0.0`: document and implement a bootstrap path where the triggering Conventional Commit or manual bootstrap instructions use `Release-As: 1.0.0` for both package paths, and require the release PR review checklist in `RELEASING.md` to confirm both package release PRs show `@version "1.0.0"` before any publish job is allowed to run. In the same workflow, export path-scoped outputs from the release job and wire downstream publish jobs to `needs.release.outputs.accrue_release_created` and `needs.release.outputs.accrue_admin_release_created` rather than referencing `steps.release.outputs[...]` from another workflow.</action>
  <acceptance_criteria>
    - `test -f .github/workflows/release-please.yml && test -f release-please-config.json && test -f .release-please-manifest.json` exits 0.
    - `rg -n "googleapis/release-please-action@v4|RELEASE_PLEASE_TOKEN|config-file: release-please-config.json|manifest-file: .release-please-manifest.json" .github/workflows/release-please.yml` returns matches.
    - `rg -n "contents: write|issues: write|pull-requests: write" .github/workflows/release-please.yml` returns matches.
    - `rg -n "\"accrue\"|\"accrue_admin\"|\"release-type\": \"elixir\"|\"package-name\"|\"changelog-path\"|\"0\\.1\\.0\"" release-please-config.json .release-please-manifest.json` returns matches.
    - `rg -n "Release-As: 1\\.0\\.0|needs\\.release\\.outputs\\.(accrue_release_created|accrue_admin_release_created)" .github/workflows/release-please.yml RELEASING.md` returns matches.
    - `rg -n "pull_request|release:" .github/workflows/release-please.yml` returns no matches.
  </acceptance_criteria>
  <verify>
    <automated>test -f .github/workflows/release-please.yml && test -f release-please-config.json && test -f .release-please-manifest.json && rg -n "googleapis/release-please-action@v4|release-type|package-name|changelog-path|RELEASE_PLEASE_TOKEN|Release-As: 1\\.0\\.0|needs\\.release\\.outputs\\.(accrue_release_created|accrue_admin_release_created)" .github/workflows/release-please.yml release-please-config.json .release-please-manifest.json RELEASING.md</automated>
  </verify>
  <done>Release Please is configured in root-manifest mode for both packages with least-privilege permissions, same-workflow publish job wiring, and an explicit bootstrap path to `v1.0.0` for both packages.</done>
</task>

<task type="auto">
  <name>Task 2: Create publish workflow and same-day release runbook with explicit package order</name>
  <files>.github/workflows/publish-hex.yml, RELEASING.md</files>
  <read_first>
    - .planning/phases/09-release/09-RESEARCH.md
    - .planning/phases/09-release/09-VALIDATION.md
    - .planning/phases/09-release/09-PATTERNS.md
    - .github/workflows/release-please.yml
    - accrue/mix.exs
    - accrue_admin/mix.exs
  </read_first>
  <action>Create `.github/workflows/publish-hex.yml` and `RELEASING.md` per OSS-09 and OSS-10 using one coherent wiring model. Put the automated publish path in `.github/workflows/release-please.yml` as downstream jobs in the same workflow/job graph: export release-job outputs after the `id: release` step, gate publish jobs on `needs.release.outputs.accrue_release_created == 'true'` and `needs.release.outputs.accrue_admin_release_created == 'true'`, publish `accrue` before `accrue_admin`, and set `ACCRUE_ADMIN_HEX_RELEASE: "1"` on the admin dry-run/publish steps. Keep `.github/workflows/publish-hex.yml` only as a manual `workflow_dispatch` recovery/bootstrap workflow that accepts explicit `package`, `tag`, and `release_version` inputs, checks out the specified ref, never references `steps.release.outputs[...]`, and uses the same package order and env handling documented in the runbook. In `RELEASING.md`, document the same-day `v1.0.0` bootstrap sequence as numbered steps: 1. confirm CI green, 2. trigger or merge release PRs that explicitly carry `Release-As: 1.0.0` for both packages, 3. confirm both release PR diffs show `@version "1.0.0"` and package-local changelog updates, 4. let the same `release-please.yml` workflow publish `accrue`, 5. confirm Hex package availability, 6. let it publish `accrue_admin` with `ACCRUE_ADMIN_HEX_RELEASE=1`, 7. verify HexDocs and `llms.txt`, 8. verify repo health files and GitHub release notes. Also document the manual fallback: if Release Please dry-run cannot produce both `1.0.0` release PRs, use the manual `publish-hex.yml` recovery/bootstrap flow only after creating a reviewed manual release PR that sets both package versions and changelogs to `1.0.0`. State explicitly that `HEX_API_KEY` and `RELEASE_PLEASE_TOKEN` are GitHub Actions secrets, never checked into docs or echoed in workflow logs. Do not promise publish from `pull_request`, `pull_request_target`, or branch pushes.</action>
  <acceptance_criteria>
    - `test -f .github/workflows/publish-hex.yml && test -f RELEASING.md` exits 0.
    - `rg -n "workflow_dispatch|package|tag|release_version|HEX_API_KEY|mix hex.publish --yes" .github/workflows/publish-hex.yml` returns matches.
    - `rg -n "needs\\.release\\.outputs\\.(accrue_release_created|accrue_admin_release_created)|ACCRUE_ADMIN_HEX_RELEASE" .github/workflows/release-please.yml RELEASING.md` returns matches.
    - `rg -n "pull_request|pull_request_target" .github/workflows/publish-hex.yml` returns no matches.
    - `rg -n "same-day|1\\.0\\.0|Release-As: 1\\.0\\.0|mix hex.publish --dry-run|publish accrue|publish accrue_admin|RELEASE_PLEASE_TOKEN|HEX_API_KEY|llms.txt|manual fallback" RELEASING.md` returns matches.
  </acceptance_criteria>
  <verify>
    <automated>rg -n "workflow_dispatch|package|tag|release_version|HEX_API_KEY|mix hex.publish --yes|needs\\.release\\.outputs\\.(accrue_release_created|accrue_admin_release_created)|ACCRUE_ADMIN_HEX_RELEASE|same-day|1\\.0\\.0|Release-As: 1\\.0\\.0|mix hex.publish --dry-run|manual fallback" .github/workflows/release-please.yml .github/workflows/publish-hex.yml RELEASING.md</automated>
  </verify>
  <done>The release runbook and automation use one executable publish wiring model, preserve a manual recovery path without cross-workflow output coupling, and enforce same-day `v1.0.0` publish order for both packages.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Release Please job outputs to downstream publish jobs | Only trusted same-workflow outputs may trigger automated Hex publishing. |
| GitHub workflow_dispatch recovery workflow to Hex publishing | Manual bootstrap or recovery runs must use explicit reviewed refs, not implicit release outputs. |
| GitHub secrets to release automation | `HEX_API_KEY` and `RELEASE_PLEASE_TOKEN` enter workflow jobs and must not leak to logs or untrusted refs. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-09-02-01 | Information Disclosure | release and publish workflows | mitigate | Use GitHub Secrets only, avoid echoing tokens, and document secret handling in `RELEASING.md` without real values. |
| T-09-02-02 | Elevation of Privilege | `.github/workflows/release-please.yml` | mitigate | Restrict permissions to `contents`, `issues`, and `pull-requests`; use dedicated `RELEASE_PLEASE_TOKEN`; do not run from PRs or forks. |
| T-09-02-03 | Tampering | `.github/workflows/release-please.yml` publish jobs | mitigate | Wire automated publish only from same-workflow release outputs and enforce `accrue` before `accrue_admin` so admin never publishes against a missing Hex dependency. |
| T-09-02-04 | Spoofing | `.github/workflows/publish-hex.yml` | mitigate | Restrict the separate recovery workflow to explicit `workflow_dispatch` inputs and documented reviewed refs, with no dependency on foreign `steps.release.outputs[...]`. |
</threat_model>

<verification>
Run `test -f .github/workflows/release-please.yml && test -f .github/workflows/publish-hex.yml && test -f release-please-config.json && test -f .release-please-manifest.json && rg -n "googleapis/release-please-action@v4|RELEASE_PLEASE_TOKEN|HEX_API_KEY|needs\\.release\\.outputs\\.(accrue_release_created|accrue_admin_release_created)|workflow_dispatch|Release-As: 1\\.0\\.0|same-day|1\\.0\\.0|ACCRUE_ADMIN_HEX_RELEASE" .github/workflows/release-please.yml .github/workflows/publish-hex.yml release-please-config.json .release-please-manifest.json RELEASING.md`.
</verification>

<success_criteria>
Release Please and Hex publishing are automated in a way that can bootstrap both packages to `v1.0.0` on the same day without broken cross-workflow output wiring, untrusted publish events, or wrong package order.
</success_criteria>

<output>
After completion, create `.planning/phases/09-release/09-02-SUMMARY.md`.
</output>
