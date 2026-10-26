---
quick_id: 261008-ffy
phase: quick-261008-ffy
plan: 01
type: execute
wave: 1
slug: repair-phase-235-regression-gaps-by-isol
description: Isolate Phase 235 Braintree return tests, restore the generic host facade contract, and run the focused suite in required CI
date: 2026-10-08
status: planned
mode: quick-full
files_modified:
  - examples/accrue_host/test/accrue_host_web/live/subscription_live_braintree_test.exs
  - examples/accrue_host/lib/accrue_host/billing.ex
  - .github/workflows/ci.yml
depends_on: []
autonomous: true
estimate: {tokens: 9000, raw_tokens: 9000, tasks: 3, confidence: low}
must_haves:
  truths:
    - The default host test suite discovers no Braintree return tests and passes with the Fake processor; the same focused module runs all eight tests with ACCRUE_HOST_BROWSER_USE_BRAINTREE=1.
    - The generated host Billing facade's public documentation is processor neutral, its existing scoped checkout behavior is intact, and the installer facade template remains generic.
    - The existing merge-blocking playwright-e2e job runs the focused ExUnit module with the Braintree test processor before its Braintree browser lane; the workflow parses and the step contract is machine checked.
  artifacts:
    - examples/accrue_host/test/accrue_host_web/live/subscription_live_braintree_test.exs
    - examples/accrue_host/lib/accrue_host/billing.ex
    - accrue/priv/accrue/templates/install/billing.ex.eex
    - .github/workflows/ci.yml
  key_links:
    - ACCRUE_HOST_BROWSER_USE_BRAINTREE=1 selects the Braintree test processor and enables the Braintree-only ExUnit module.
    - The facade source and installer template both satisfy the existing BillingFacadeTest provider-neutral source contract.
    - The playwright-e2e Braintree step invokes the focused ExUnit file with the same processor flag used by the Braintree browser step.
---

<objective>
Repair the three Phase 235 regression gaps while preserving the existing provider-specific return proof.

Purpose: The default Fake-backed host suite must stay green, the generated facade contract must describe shared host policy, and recurring Braintree return coverage must run in the required CI lane.
Output: Three scoped source edits and an automated quick-task verification summary.
</objective>

<context>
@.planning/STATE.md
@.planning/PROJECT.md
@.planning/phases/235-customer-plan-selection-checkout/235-05-SUMMARY.md
@.planning/phases/235-customer-plan-selection-checkout/235-06-SUMMARY.md
@.planning/phases/235-customer-plan-selection-checkout/235-06-PLAN.md
@examples/accrue_host/test/accrue_host_web/live/subscription_live_braintree_test.exs
@examples/accrue_host/test/accrue_host/billing_facade_test.exs
@examples/accrue_host/lib/accrue_host/billing.ex
@accrue/priv/accrue/templates/install/billing.ex.eex
@.github/workflows/ci.yml
</context>

<tasks>

<task type="auto">
  <name>Task 1: Gate the Braintree return ExUnit module on the processor test flag</name>
  <files>examples/accrue_host/test/accrue_host_web/live/subscription_live_braintree_test.exs</files>
  <action>Wrap the entire existing AccrueHostWeb.SubscriptionLiveBraintreeTest module definition in a file-level conditional requiring System.get_env("ACCRUE_HOST_BROWSER_USE_BRAINTREE") == "1". Keep every existing test, fixture helper, and the setup assertion that Processor.name() == "braintree" inside the module unchanged. The default configuration in examples/accrue_host/config/test.exs selects Fake, so this module must define no tests in an ordinary host run; when the flag is exactly 1, the existing eight return proofs must execute.</action>
  <verify>
    <automated>cd examples/accrue_host && mix test test/accrue_host_web/live/subscription_live_braintree_test.exs</automated>
    <automated>cd examples/accrue_host && ACCRUE_HOST_BROWSER_USE_BRAINTREE=1 mix test test/accrue_host_web/live/subscription_live_braintree_test.exs</automated>
  </verify>
  <done>The unflagged focused command reports zero tests and exits successfully; the flagged command runs eight tests and passes without changing the Braintree return assertions.</done>
</task>

<task type="auto">
  <name>Task 2: Restore processor-neutral generated facade documentation</name>
  <files>examples/accrue_host/lib/accrue_host/billing.ex</files>
  <read_first>examples/accrue_host/test/accrue_host/billing_facade_test.exs; accrue/priv/accrue/templates/install/billing.ex.eex</read_first>
  <action>Replace the provider name in checkout_session_for_scope/2's @doc with wording about a scoped checkout operation, current organization membership, billing permission, and processor Customer. Preserve the function body and its explicit processor lookup because the authorization and payment evidence boundary is unchanged. Inspect the corresponding installer billing.ex.eex template: it has no checkout_session_for_scope/2 hook and already uses generic facade prose, so there is no matching template text to edit. Keep the generated header and fingerprint lines intact. The BillingFacadeTest source assertions cover both files.</action>
  <verify><automated>cd examples/accrue_host && mix test test/accrue_host/billing_facade_test.exs</automated></verify>
  <done>The facade contract passes, including provider-neutral source assertions for the host file and installer template, and the scoped return function still resolves its existing processor Customer.</done>
</task>

<task type="auto">
  <name>Task 3: Add focused return proof to the required Braintree CI lane</name>
  <files>.github/workflows/ci.yml</files>
  <action>Within the existing merge-blocking playwright-e2e job, add a named step immediately before Refresh Braintree checkout browser fixture that runs `cd examples/accrue_host && mix test test/accrue_host_web/live/subscription_live_braintree_test.exs` with step-level ACCRUE_HOST_BROWSER_USE_BRAINTREE: "1". Keep the job's existing PostgreSQL service, shard matrix, required status identity, fixture seeding, browser step, and upload steps. Run this on every shard, matching the currently repeated Braintree browser lane; do not create a new job or weaken a required gate.</action>
  <verify>
    <automated>actionlint .github/workflows/ci.yml</automated>
    <automated>ruby -e 'require "yaml"; w=YAML.load_file(".github/workflows/ci.yml"); steps=w.fetch("jobs").fetch("playwright-e2e").fetch("steps"); i=steps.index { |s| s["name"] == "Run configured Braintree return ExUnit suite" }; abort("missing or misplaced Braintree ExUnit step") unless (i and steps[i+1]["name"] == "Refresh Braintree checkout browser fixture"); s=steps[i]; abort("missing Braintree processor flag or focused command") unless (s.fetch("env").fetch("ACCRUE_HOST_BROWSER_USE_BRAINTREE") == "1" and s.fetch("run").include?("mix test test/accrue_host_web/live/subscription_live_braintree_test.exs"))'</automated>
  </verify>
  <done>The existing required playwright-e2e job runs the exact focused file with the Braintree processor selected before the Braintree fixture/browser steps; actionlint and the job-step contract pass.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Host return query to scoped Billing facade | Untrusted plan and selection locators are accepted only through the already authorized Customer and persisted LocalSession checks. |
| CI processor flag to ExUnit/browser process | The environment flag selects processor behavior for deterministic tests; the default host suite must not inherit it. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-Q261008-FFY-01 | Spoofing | Braintree return tests | high | mitigate | Task 1 retains all eight scoped, forged-locator, and fresh-permission assertions; Task 3 makes them merge blocking under the required processor flag. |
| T-Q261008-FFY-02 | Tampering | CI workflow | medium | mitigate | Task 3 changes only the existing Braintree lane and checks workflow syntax plus exact job, step order, flag, and test path. |
| T-Q261008-FFY-03 | Information disclosure | Generated facade documentation | low | mitigate | Task 2 keeps public generated documentation processor neutral while leaving runtime Customer scoping intact. |
| T-Q261008-FFY-SC | Tampering | Package supply chain | low | accept | No package installation or dependency change is in scope. |
</threat_model>

<verification>
From the repository root, run `cd examples/accrue_host && mix test --warnings-as-errors` under the default environment to prove the full Fake-backed host suite passes with the Braintree module absent. Run `cd examples/accrue_host && ACCRUE_HOST_BROWSER_USE_BRAINTREE=1 mix test test/accrue_host_web/live/subscription_live_braintree_test.exs` for the eight focused returns, and `cd examples/accrue_host && mix test test/accrue_host/billing_facade_test.exs` for both facade sources. Run `actionlint .github/workflows/ci.yml` and Task 3's job-step contract. Record results in the quick SUMMARY; stable acceptance is automated with no human UAT.
</verification>

<success_criteria>
The default full host suite, flagged eight-test return suite, facade contract, workflow syntax, and CI step contract all pass. Runtime checkout evidence and authorization code remains unchanged.
</success_criteria>

<output>
Create .planning/quick/261008-ffy-repair-phase-235-regression-gaps-by-isol/261008-ffy-SUMMARY.md when done.
</output>
