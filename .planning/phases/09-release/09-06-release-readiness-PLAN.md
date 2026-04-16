---
phase: 09-release
plan: 06
type: execute
wave: 2
depends_on: [09-01, 09-02, 09-03, 09-04, 09-05]
files_modified: []
autonomous: false
requirements: [OSS-07, OSS-08, OSS-09, OSS-10, OSS-15, OSS-16, OSS-17, OSS-18]
must_haves:
  truths:
    - "Both packages pass the release gate, build docs cleanly, and generate llms.txt."
    - "Both packages pass `mix hex.publish --dry-run` before any real publish."
    - "Release Please, publish workflow, docs, and root policies are ready for same-day v1.0.0 ship."
  artifacts:
    - path: ".github/workflows/ci.yml"
      provides: "Final release gate"
    - path: ".github/workflows/release-please.yml"
      provides: "Release PR automation"
    - path: ".github/workflows/publish-hex.yml"
      provides: "Publish automation"
    - path: "RELEASING.md"
      provides: "Operator runbook"
  key_links:
    - from: "RELEASING.md"
      to: ".github/workflows/publish-hex.yml"
      via: "same-day publish sequence"
      pattern: "mix hex.publish --dry-run"
    - from: "accrue/mix.exs"
      to: "doc/llms.txt"
      via: "mix docs output"
      pattern: "main: \"readme\""
---

<objective>
Perform final release readiness verification after all Phase 9 implementation tracks land.

Purpose: release-critical work needs a final dry-run wave that proves the automation, docs, and package contents are coherent before the real v1.0.0 release.
Output: automated verification results and a human checkpoint for secret availability and same-day ship approval.
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
@.github/workflows/release-please.yml
@.github/workflows/publish-hex.yml
@release-please-config.json
@.release-please-manifest.json
@RELEASING.md
@accrue/mix.exs
@accrue_admin/mix.exs
</context>

<tasks>

<task type="auto">
  <name>Task 1: Run the local release-gate and docs verification pass</name>
  <files>.github/workflows/ci.yml, accrue/mix.exs, accrue_admin/mix.exs, accrue/README.md, accrue_admin/README.md, CONTRIBUTING.md, CODE_OF_CONDUCT.md, SECURITY.md</files>
  <read_first>
    - .github/workflows/ci.yml
    - .github/workflows/release-please.yml
    - .github/workflows/publish-hex.yml
    - release-please-config.json
    - .release-please-manifest.json
    - RELEASING.md
    - accrue/mix.exs
    - accrue_admin/mix.exs
  </read_first>
  <action>Run the first half of the Phase 9 dry-run verification sequence after Plans 09-01 through 09-05 complete so failures isolate quickly. Execute the core package release gate `cd accrue && mix format --check-formatted && mix compile --warnings-as-errors && mix test --warnings-as-errors && mix credo --strict && mix dialyzer --format github && mix docs --warnings-as-errors && mix hex.audit`. Execute the admin package release gate `cd accrue_admin && mix format --check-formatted && mix compile --warnings-as-errors && mix test --warnings-as-errors && mix credo --strict && mix dialyzer --format github && mix docs --warnings-as-errors && mix hex.audit`. Confirm both packages generated `doc/llms.txt`, and confirm root release-policy files exist before moving to Hex dry runs. Record any failures in the summary instead of silently continuing.</action>
  <acceptance_criteria>
    - `cd accrue && mix docs --warnings-as-errors && test -f doc/llms.txt` exits 0.
    - `cd accrue_admin && mix dialyzer --format github && mix docs --warnings-as-errors && mix hex.audit && test -f doc/llms.txt` exits 0.
    - `test -f CONTRIBUTING.md && test -f CODE_OF_CONDUCT.md && test -f SECURITY.md` exits 0.
  </acceptance_criteria>
  <verify>
    <automated>cd accrue && mix format --check-formatted && mix compile --warnings-as-errors && mix test --warnings-as-errors && mix credo --strict && mix dialyzer --format github && mix docs --warnings-as-errors && mix hex.audit && test -f doc/llms.txt</automated>
    <automated>cd accrue_admin && mix format --check-formatted && mix compile --warnings-as-errors && mix test --warnings-as-errors && mix credo --strict && mix dialyzer --format github && mix docs --warnings-as-errors && mix hex.audit && test -f doc/llms.txt</automated>
    <automated>test -f CONTRIBUTING.md && test -f CODE_OF_CONDUCT.md && test -f SECURITY.md</automated>
  </verify>
  <done>Both packages pass the full release gate including Dialyzer and retired-package checks, root release-policy files exist, and any failures are captured explicitly before Hex dry runs begin.</done>
</task>

<task type="auto">
  <name>Task 2: Run Hex dry-runs and workflow smoke checks</name>
  <files>.github/workflows/release-please.yml, .github/workflows/publish-hex.yml, release-please-config.json, .release-please-manifest.json, RELEASING.md, accrue/mix.exs, accrue_admin/mix.exs</files>
  <read_first>
    - .github/workflows/release-please.yml
    - .github/workflows/publish-hex.yml
    - release-please-config.json
    - .release-please-manifest.json
    - RELEASING.md
    - accrue/mix.exs
    - accrue_admin/mix.exs
  </read_first>
  <action>Run the second half of the dry run after Task 1 is green. Execute `cd accrue && mix hex.publish --dry-run`. Execute `cd accrue_admin && ACCRUE_ADMIN_HEX_RELEASE=1 mix hex.build && ACCRUE_ADMIN_HEX_RELEASE=1 mix hex.publish --dry-run` so the admin package is validated in the same publish mode that CI will use. Then verify the workflow and docs surfaces with `rg` checks for `RELEASE_PLEASE_TOKEN`, `HEX_API_KEY`, `needs.release.outputs.accrue_release_created`, `needs.release.outputs.accrue_admin_release_created`, `ACCRUE_ADMIN_HEX_RELEASE`, `Release-As: 1.0.0`, `same-day`, and `llms.txt`. Record any failures in the summary instead of silently continuing.</action>
  <acceptance_criteria>
    - `cd accrue && mix hex.publish --dry-run` exits 0.
    - `cd accrue_admin && ACCRUE_ADMIN_HEX_RELEASE=1 mix hex.build && ACCRUE_ADMIN_HEX_RELEASE=1 mix hex.publish --dry-run` exits 0.
    - `rg -n "RELEASE_PLEASE_TOKEN|HEX_API_KEY|needs\\.release\\.outputs\\.(accrue_release_created|accrue_admin_release_created)|ACCRUE_ADMIN_HEX_RELEASE|Release-As: 1\\.0\\.0|same-day|llms.txt" .github/workflows/release-please.yml .github/workflows/publish-hex.yml RELEASING.md` returns matches.
  </acceptance_criteria>
  <verify>
    <automated>cd accrue && mix hex.publish --dry-run</automated>
    <automated>cd accrue_admin && ACCRUE_ADMIN_HEX_RELEASE=1 mix hex.build && ACCRUE_ADMIN_HEX_RELEASE=1 mix hex.publish --dry-run</automated>
    <automated>rg -n "RELEASE_PLEASE_TOKEN|HEX_API_KEY|needs\\.release\\.outputs\\.(accrue_release_created|accrue_admin_release_created)|ACCRUE_ADMIN_HEX_RELEASE|Release-As: 1\\.0\\.0|same-day|llms.txt" .github/workflows/release-please.yml .github/workflows/publish-hex.yml RELEASING.md</automated>
  </verify>
  <done>The Hex publish dry-runs and workflow smoke checks pass in the same mode the release automation will use, or failures are captured explicitly for follow-up before ship.</done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <name>Task 3: Final same-day release approval checkpoint</name>
  <files>RELEASING.md, SECURITY.md, CODE_OF_CONDUCT.md, .github/workflows/release-please.yml, .github/workflows/publish-hex.yml</files>
  <read_first>
    - RELEASING.md
    - SECURITY.md
    - CODE_OF_CONDUCT.md
    - .github/workflows/release-please.yml
    - .github/workflows/publish-hex.yml
  </read_first>
  <action>Present the final human checkpoint after the automated dry run passes. Ask the user to confirm that the GitHub repository secrets `RELEASE_PLEASE_TOKEN` and `HEX_API_KEY` are configured, that the GitHub-based maintainer and private security reporting paths are acceptable for public release, and that they want to proceed with the same-day v1.0.0 release order documented in `RELEASING.md`. Do not attempt a real publish in this plan.</action>
  <acceptance_criteria>
    - The checkpoint instructions mention `RELEASE_PLEASE_TOKEN`, `HEX_API_KEY`, `szTheory`, GitHub private security advisories, and `RELEASING.md`.
    - The resume signal is exactly `approved` or a concrete issue list from the user.
  </acceptance_criteria>
  <verify>
    <automated>rg -n "RELEASE_PLEASE_TOKEN|HEX_API_KEY|szTheory|private GitHub security advisory|same-day|accrue then accrue_admin" RELEASING.md SECURITY.md CODE_OF_CONDUCT.md .github/workflows/release-please.yml .github/workflows/publish-hex.yml</automated>
  </verify>
  <what-built>Automated local release-readiness verification, publish-mode dry-run package builds, workflow smoke checks, and the same-day release runbook.</what-built>
  <how-to-verify>
    1. Open `RELEASING.md` and confirm the same-day publish order is `accrue` then `accrue_admin`.
    2. Confirm the repository secrets `RELEASE_PLEASE_TOKEN` and `HEX_API_KEY` exist in GitHub Actions settings.
    3. Confirm the GitHub-based public contact paths in `CODE_OF_CONDUCT.md` and `SECURITY.md` are final.
    4. Reply `approved` to continue to release execution, or reply with the exact issue list.
  </how-to-verify>
  <resume-signal>Type `approved` or provide the exact issue list.</resume-signal>
  <done>The user has either approved the same-day release setup or supplied a concrete blocker list for follow-up before any real publish.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| local dry-run verification to actual release execution | The final readiness pass must not accidentally publish packages or assume secrets exist. |
| human approval to public release | Public contact values and GitHub secrets are human-owned configuration outside the repo. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-09-06-01 | Tampering | dry-run vs real publish boundary | mitigate | Use `mix hex.publish --dry-run` only in the automated task and explicitly forbid real publish in this plan. |
| T-09-06-02 | Information Disclosure | final checkpoint and docs | mitigate | Verify secrets are configured in GitHub, not stored in repo files or logs, before approving release. |
| T-09-06-03 | Repudiation | public policy contacts | mitigate | Require human confirmation of the final contact addresses before same-day ship approval. |
</threat_model>

<verification>
Run the staged automated dry-run sequence from Tasks 1 and 2, then pause for human approval.
</verification>

<success_criteria>
Phase 9 ends with a green dry-run release gate and an explicit human approval checkpoint for the real same-day v1.0.0 release.
</success_criteria>

<output>
After completion, create `.planning/phases/09-release/09-06-SUMMARY.md`.
</output>
