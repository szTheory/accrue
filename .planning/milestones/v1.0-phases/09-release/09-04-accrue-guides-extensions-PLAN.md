---
phase: 09-release
plan: 04
type: execute
wave: 1
depends_on: []
files_modified:
  - accrue/guides/sigra_integration.md
  - accrue/guides/custom_processors.md
  - accrue/guides/custom_pdf_adapter.md
  - accrue/guides/webhook_gotchas.md
  - accrue/guides/upgrade.md
autonomous: true
requirements: [OSS-15, OSS-16]
must_haves:
  truths:
    - "The full core guide set covers Sigra, custom processors, custom PDF adapters, webhook gotchas, and upgrade rules."
    - "Docs explain extension points without leaking secrets or promising unsupported internals."
  artifacts:
    - path: "accrue/guides/sigra_integration.md"
      provides: "Sigra integration guide"
    - path: "accrue/guides/custom_processors.md"
      provides: "Custom processor adapter guide"
    - path: "accrue/guides/custom_pdf_adapter.md"
      provides: "Custom PDF adapter guide"
    - path: "accrue/guides/webhook_gotchas.md"
      provides: "Webhook gotchas field guide"
    - path: "accrue/guides/upgrade.md"
      provides: "Upgrade and deprecation guide"
  key_links:
    - from: "accrue/guides/sigra_integration.md"
      to: "accrue/guides/auth_adapters.md"
      via: "community auth adapter guidance"
      pattern: "Accrue.Integrations.Sigra"
    - from: "accrue/guides/custom_pdf_adapter.md"
      to: "accrue/guides/pdf.md"
      via: "custom adapter path"
      pattern: "Accrue.PDF"
---

<objective>
Finish the remaining core guide set required for release.

Purpose: Phase 9 needs complete extension and operations guidance, not just a README and install guide.
Output: five release guides covering Sigra, processor adapters, PDF adapters, webhook gotchas, and upgrade policy.
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
@accrue/guides/auth_adapters.md
@accrue/guides/pdf.md
@accrue/guides/branding.md
@accrue/guides/testing.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Write the extension-point guides for Sigra, processors, and PDF adapters</name>
  <files>accrue/guides/sigra_integration.md, accrue/guides/custom_processors.md, accrue/guides/custom_pdf_adapter.md</files>
  <read_first>
    - accrue/guides/auth_adapters.md
    - accrue/guides/pdf.md
    - accrue/guides/testing.md
    - .planning/phases/09-release/09-RESEARCH.md
    - .planning/phases/09-release/09-PATTERNS.md
  </read_first>
  <action>Create three guides. `accrue/guides/sigra_integration.md` must contain `# Sigra Integration`, `## Add the dependency`, `## Configure Accrue`, and `## Verify audit flow`, and include the exact config line `config :accrue, :auth_adapter, Accrue.Integrations.Sigra`. `accrue/guides/custom_processors.md` must contain `# Custom Processors`, `## Behaviour contract`, `## Wiring your adapter`, and `## Test with Accrue.Test`, and mention `@behaviour Accrue.Processor`, `config :accrue, :processor`, and `Accrue.Processor.Fake` as the primary test surface. `accrue/guides/custom_pdf_adapter.md` must contain `# Custom PDF Adapter`, `## Behaviour contract`, `## Runtime configuration`, `## Null adapter fallback`, and `## Dry-run verification`, and mention `@behaviour Accrue.PDF`, `config :accrue, :pdf_adapter`, `Accrue.PDF.Null`, and `mix docs --warnings-as-errors`. Keep all code snippets on placeholder keys and module names; do not include real webhook secrets, API keys, or Stripe object identifiers.</action>
  <acceptance_criteria>
    - `test -f accrue/guides/sigra_integration.md && test -f accrue/guides/custom_processors.md && test -f accrue/guides/custom_pdf_adapter.md` exits 0.
    - `rg -n "^# Sigra Integration$|## Add the dependency|## Configure Accrue|config :accrue, :auth_adapter, Accrue\\.Integrations\\.Sigra|## Verify audit flow" accrue/guides/sigra_integration.md` returns matches.
    - `rg -n "^# Custom Processors$|## Behaviour contract|@behaviour Accrue\\.Processor|config :accrue, :processor|Accrue\\.Processor\\.Fake|## Test with Accrue\\.Test" accrue/guides/custom_processors.md` returns matches.
    - `rg -n "^# Custom PDF Adapter$|## Behaviour contract|@behaviour Accrue\\.PDF|config :accrue, :pdf_adapter|Accrue\\.PDF\\.Null|## Dry-run verification|mix docs --warnings-as-errors" accrue/guides/custom_pdf_adapter.md` returns matches.
  </acceptance_criteria>
  <verify>
    <automated>rg -n "Accrue\\.Integrations\\.Sigra|@behaviour Accrue\\.Processor|@behaviour Accrue\\.PDF|Accrue\\.PDF\\.Null|Accrue\\.Processor\\.Fake" accrue/guides/sigra_integration.md accrue/guides/custom_processors.md accrue/guides/custom_pdf_adapter.md</automated>
  </verify>
  <done>The release docs clearly cover the main extension surfaces required for v1.0.0 adopters.</done>
</task>

<task type="auto">
  <name>Task 2: Write the webhook gotchas and upgrade guides</name>
  <files>accrue/guides/webhook_gotchas.md, accrue/guides/upgrade.md</files>
  <read_first>
    - accrue/guides/testing.md
    - accrue/guides/auth_adapters.md
    - .planning/phases/09-release/09-RESEARCH.md
    - CLAUDE.md
  </read_first>
  <action>Create `accrue/guides/webhook_gotchas.md` with sections `# Webhook Gotchas`, `## Raw body ordering`, `## Signature verification`, `## Secret rotation`, `## Re-fetch current objects`, and `## Replay and DLQ hygiene`. The guide must state that raw-body capture must run before `Plug.Parsers`, signature verification is mandatory, real webhook secrets are never committed, and replays must use the same reducer path. Create `accrue/guides/upgrade.md` with sections `# Upgrade Guide`, `## v1.0.0 baseline`, `## Deprecation window`, `## Release Please and changelog flow`, and `## Verifying an upgrade`. State that v1.x breaking changes require a deprecation cycle, that package consumers should read per-package `CHANGELOG.md`, and that upgrades should be verified with `mix compile --warnings-as-errors`, `mix test --warnings-as-errors`, and `mix docs --warnings-as-errors` in the consuming app. Do not promise silent compatibility with undocumented internals.</action>
  <acceptance_criteria>
    - `test -f accrue/guides/webhook_gotchas.md && test -f accrue/guides/upgrade.md` exits 0.
    - `rg -n "^# Webhook Gotchas$|## Raw body ordering|Plug\\.Parsers|## Signature verification|mandatory|## Secret rotation|## Re-fetch current objects|## Replay and DLQ hygiene" accrue/guides/webhook_gotchas.md` returns matches.
    - `rg -n "^# Upgrade Guide$|## v1\\.0\\.0 baseline|## Deprecation window|## Release Please and changelog flow|## Verifying an upgrade|mix compile --warnings-as-errors|mix test --warnings-as-errors|mix docs --warnings-as-errors|CHANGELOG\\.md" accrue/guides/upgrade.md` returns matches.
    - `rg -n "sk_live_|whsec_|acct_|price_" accrue/guides/webhook_gotchas.md accrue/guides/upgrade.md` returns no matches.
  </acceptance_criteria>
  <verify>
    <automated>cd accrue && mix docs --warnings-as-errors</automated>
  </verify>
  <done>The remaining release guides close the Phase 9 docs gaps without leaking secrets or overstating compatibility.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| guide snippets to production webhook setups | Developers may copy webhook and adapter examples directly into production configuration. |
| upgrade instructions to public API commitments | Upgrade docs can accidentally imply stability guarantees the package does not honor. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-09-04-01 | Information Disclosure | webhook and adapter guides | mitigate | Use placeholder config values only and explicitly forbid real webhook secrets, API keys, and Stripe identifiers in docs. |
| T-09-04-02 | Spoofing | webhook gotchas guide | mitigate | State that signature verification is mandatory and that raw body capture must precede `Plug.Parsers`. |
| T-09-04-03 | Repudiation | upgrade guide | mitigate | Document deprecation windows and changelog flow explicitly so compatibility guarantees are measurable. |
</threat_model>

<verification>
Run `cd accrue && mix docs --warnings-as-errors`.
</verification>

<success_criteria>
The `accrue` guide set is complete for release and covers extension points, webhook safety, and upgrade rules.
</success_criteria>

<output>
After completion, create `.planning/phases/09-release/09-04-SUMMARY.md`.
</output>
