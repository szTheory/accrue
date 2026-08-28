# Phase 228: Repair Stripe Webhook-Signing CI Boot Contract Under a Fresh Evidence Budget - Research

**Researched:** 2026-08-28
**Domain:** GitHub Actions secret-to-runtime configuration contract for the live Stripe provider lane
**Confidence:** HIGH for repository diagnosis; MEDIUM for GitHub/Stripe operational semantics

## Summary

Phase 227's one authorized restoration dispatch is conclusive about the immediate fault. Run `33188858334` passed the three existing Stripe key/price checks, then its `live-stripe` job failed before selecting a test because boot raised `ACCRUE-DX-WEBHOOK-SECRET-MISSING`; its provider record is `misconfigured` / `manifest_invalid` with `selected_count: 0` and no manifest. The exhausted Phase 227 budget prohibits rerunning or reusing that phase’s restoration authority. [VERIFIED: .planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.md:64-72]

The defect is a broken four-part contract, not a Stripe API or critical-path regression: the test runtime promotes the processor to Stripe whenever the API key is present, Accrue boot then requires a Stripe webhook signing secret, but the runtime configuration does not read one and the workflow binds/checks only three secrets. The smallest production-quality repair is to bind one endpoint-specific sandbox signing secret to the provider job, configure it as `:webhook_signing_secrets` during the existing test-runtime opt-in, expand the existing fail-closed preflight, and prove those exact seams with deterministic tests before consuming a new Phase 228 run budget. [VERIFIED: accrue/config/runtime.exs:22-37; accrue/lib/accrue/config.ex:703-730; accrue/lib/accrue/config.ex:1243-1255; .github/workflows/ci.yml:1284-1333]

**Primary recommendation:** Add exactly one new repository secret contract, `STRIPE_WEBHOOK_SECRET`, to the existing `live-stripe` job and test runtime; fail closed before `mix test.live`, retain the existing provider-proof finalization/artifact behavior, then authorize one explicitly recorded Phase 228 first-attempt dispatch only after the maintainer configures a real Stripe test-mode endpoint secret.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Inject a CI-only endpoint signing secret | GitHub Actions / repository secret store | CI workflow | The job-level `env` is the trust boundary that makes repository secrets available to the process. [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets] |
| Select Stripe and map runtime configuration | Accrue runtime config | Accrue boot validator | `runtime.exs` selects Stripe for the opt-in; boot validates `webhook_signing_secrets(:stripe)`. [VERIFIED: accrue/config/runtime.exs:22-37; accrue/lib/accrue/config.ex:1243-1255] |
| Detect incomplete live-provider configuration | CI workflow preflight | Provider proof classifier | The preflight stops the suite; the finalizer classifies missing/invalid manifest configuration as `misconfigured`. [VERIFIED: .github/workflows/ci.yml:1320-1339; scripts/ci/provider_proof.mjs:105-132] |
| Preserve proof reporting after failure | CI workflow | provider_proof.mjs | Finalization, summary, and artifact upload use `if: always()` and must remain so. [VERIFIED: .github/workflows/ci.yml:1335-1358; scripts/ci/verify_provider_proof.mjs:63-80] |

## Standard Stack

### Core

| Component | Version | Purpose | Why Standard |
|---|---:|---|---|
| Existing GitHub Actions `CI` workflow | repository-local | Supplies the `live-stripe` job, its secret environment, preflight, and proof artifact. | The repair is a contract completion in the canonical workflow; no new workflow/action is warranted. [VERIFIED: .github/workflows/ci.yml:1262-1358] |
| `accrue/config/runtime.exs` | repository-local | Maps test-only environment to Accrue runtime configuration before application boot. | Boot-time configuration must exist before the application starts; test-helper mutation is too late for the CI boot contract. [VERIFIED: accrue/config/runtime.exs:22-37; accrue/lib/accrue/application.ex:50-53] |
| Existing provider proof tooling | dependency-free Node ESM | Retains `proved`, `misconfigured`, `failed`, and related proof facts. | Reusing it keeps the privacy-safe evidence grammar and avoids a parallel reporter. [VERIFIED: scripts/ci/provider_proof.mjs:105-132; scripts/ci/verify_provider_proof.mjs:55-88] |

### Supporting

| Component | Version | Purpose | When to Use |
|---|---:|---|---|
| Node.js | `v22.14.0` installed | Run the existing deterministic provider-workflow fixture verifier. | Before any live dispatch and after every workflow/proof change. [VERIFIED: environment probe 2026-08-28] |
| Elixir / OTP | Elixir `1.19.5` in CI; OTP `28` locally | Evaluate test runtime config and run the live suite. | Use dummy values only in local boot-contract tests; use the real endpoint secret only in GitHub Actions. [VERIFIED: .github/workflows/ci.yml:1300-1303; environment probe 2026-08-28] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| One `STRIPE_WEBHOOK_SECRET` mapped at runtime | Reuse the Stripe API secret as a signing secret | Reject. Stripe documents endpoint secrets as separate, endpoint-specific values; API keys do not establish webhook signature verification. [CITED: https://docs.stripe.com/keys; https://docs.stripe.com/webhooks/signature?lang=node&locale=en-GB] |
| Existing provider preflight/proof record | Let `mix test.live` discover the missing value during boot | Reject. It turns a missing CI contract into an opaque `manifest_invalid` outcome with zero selected tests. [VERIFIED: .planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.md:68-72] |
| Fresh Phase 228 evidence budget | Re-run Phase 227’s restoration dispatch | Reject. Phase 227 explicitly exhausted its budget and authorizes no replacement run. [VERIFIED: .planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.md:70-72] |

**Installation:** None. Do not add packages, actions, a Stripe SDK, or a second CI workflow. [VERIFIED: .github/workflows/ci.yml:1262-1358]

## Architecture Patterns

### System Architecture Diagram

```text
GitHub repository secret: STRIPE_WEBHOOK_SECRET
                     |
                     v
live-stripe job env + non-empty four-value preflight
                     |
                     v
MIX_ENV=test runtime.exs
  STRIPE_TEST_SECRET_KEY -> processor: Stripe + stripe_secret_key
  STRIPE_WEBHOOK_SECRET  -> webhook_signing_secrets: %{stripe: [...]}
                     |
                     v
Accrue.Config.validate_at_boot!
                     |
          +----------+----------+
          |                     |
       valid boot              missing/invalid
          |                     |
          v                     v
mix test.live             preflight failure; always-run proof finalizer
          |                     |
          +------> provider proof artifact / summary <------+
```

The new edge ends at configuration validation; it must not add webhook delivery calls, replace raw-body/signature tests, or expand the live suite’s provider scope. [VERIFIED: accrue/lib/accrue/config.ex:1243-1255; .github/workflows/ci.yml:1320-1358]

### Recommended Project Structure

```text
accrue/config/runtime.exs                  # test-mode API + signing-secret mapping
.github/workflows/ci.yml                   # existing live-stripe job secret binding and preflight
scripts/ci/verify_provider_proof.mjs        # extend existing static negative fixtures
.planning/phases/228-.../                   # fresh, sanitized run-budget/evidence record
```

### Pattern 1: Runtime-owned secret mapping before boot

**What:** In the existing `config_env() == :test` and non-empty live-key branch, read and trim the signing-secret environment variable once and set the `:accrue` `webhook_signing_secrets` map alongside `processor` and `stripe_secret_key`.

**When to use:** Only for `mix test.live` / the selected `live-stripe` CI lane, where Stripe processor boot is intentional. Normal test runs without a live API key remain Fake-backed. [VERIFIED: accrue/config/runtime.exs:20-37]

**Contract values (verbatim):**

DATA_H7Q2L9VW_START
`"STRIPE_TEST_SECRET_KEY"`, `"STRIPE_WEBHOOK_SECRET"`, `processor: Accrue.Processor.Stripe`, and `webhook_signing_secrets: %{stripe: [stripe_webhook_secret]}`.
DATA_H7Q2L9VW_END

The list shape preserves the existing configuration contract’s secret-rotation support. [VERIFIED: accrue/lib/accrue/config.ex:703-728]

### Pattern 2: Fail-closed preflight without value disclosure

**What:** Bind the GitHub secret only as job environment, test non-empty variables using shell parameter expansion, write only `configured=true|false` to `GITHUB_OUTPUT`, and retain the current generic error text.

**When to use:** Before the suite starts, so an absent repository secret produces a legible configuration failure without leaking credential material. GitHub returns an empty string for an unset secret expression and recommends passing secrets through environment variables rather than command lines. [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets]

### Pattern 3: Fresh, bounded evidence—not Phase 227 recovery

**What:** Create a Phase 228 evidence record that names the repaired SHA, manual event/input topology, first attempt, job URL, raw conclusion, provider proof state/counts, artifact presence, and whether the Phase 228 budget was consumed. Link the historical Phase 227 failure; never edit its records to imply recovery.

**When to use:** Only after deterministic checks pass and the maintainer has configured the repository secret. Treat one first-attempt `workflow_dispatch` with `run_live_stripe: true` as a new Phase 228 authorization, not an implied replacement for the prior phase. [VERIFIED: .planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.md:64-72]

### Anti-Patterns to Avoid

- **Checking only the API key and prices:** This repeats the defect; boot requires the signing-secret map once Stripe is selected. [VERIFIED: .github/workflows/ci.yml:1320-1329; accrue/lib/accrue/config.ex:1250-1252]
- **Putting the signing secret in a shell command, summary, artifact, or checked-in fixture:** GitHub advises using environment variables and avoiding command-line transfer; Stripe says the endpoint secret must be kept safe. [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets; https://docs.stripe.com/webhooks/handling-payment-events]
- **Using a CLI forwarding secret or a different Stripe endpoint’s secret:** Stripe documents that endpoint secrets differ by endpoint and that CLI and Dashboard secrets are not interchangeable. [CITED: https://docs.stripe.com/webhooks/signature?lang=node&locale=en-GB]
- **Making the preflight pass with a placeholder:** It would weaken boot-contract evidence and may produce a later signature verification failure. Use a real sandbox endpoint secret owned by the maintainer. [CITED: https://docs.stripe.com/webhooks?lang=node]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Provider-status reporting | A new status taxonomy or summary format | `scripts/ci/provider_proof.mjs` and its existing artifact | It already treats missing/invalid configuration as `misconfigured` and refuses to call a zero-selected suite proof. [VERIFIED: scripts/ci/provider_proof.mjs:105-132] |
| CI workflow parsing/testing | A new YAML parser or test framework | `scripts/ci/verify_provider_proof.mjs` Node `assert` fixture pattern | Existing checks verify stable job/step IDs, always-run proof steps, artifact identities, and no write-capable token/mutation. [VERIFIED: scripts/ci/verify_provider_proof.mjs:55-88] |
| Signing verification implementation | Custom HMAC/signature logic | Existing Accrue/LatticeStripe webhook configuration path | The phase repairs boot configuration, not cryptography; Stripe recommends its official verification path with raw payload, signature header, and endpoint secret. [CITED: https://docs.stripe.com/webhooks?lang=node] |

## Common Pitfalls

### Pitfall 1: Configuration exists only after application boot

**What goes wrong:** A test helper supplies a fixture secret, but live-test startup has already selected Stripe through runtime configuration and failed boot validation.

**Why it happens:** The test helper’s `Application.put_env` is process-local setup, whereas runtime config is read before the application starts. [VERIFIED: accrue/test/test_helper.exs:40-45; accrue/lib/accrue/application.ex:50-53]

**How to avoid:** Put the live-only map in `runtime.exs`, then add a deterministic boot-contract check that runs the runtime path with dummy `sk_test_...` / `whsec_...` values and makes no network call.

**Warning signs:** `ACCRUE-DX-WEBHOOK-SECRET-MISSING`, zero selected tests, and no provider manifest. [VERIFIED: .planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.md:68-70]

### Pitfall 2: Secret exposure while diagnosing a missing secret

**What goes wrong:** A diagnostic prints an environment value, stores it in NDJSON, or writes it to a summary/artifact.

**How to avoid:** Assert existence/shape only; preserve the existing generic preflight message and add negative tests that reject output/arguments containing the secret variable’s value. GitHub says unset secret expressions resolve empty and recommends environment variables instead of command-line transfer. [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets]

### Pitfall 3: Treating a repaired configuration as provider proof

**What goes wrong:** Static checks pass, but a later live suite is recorded as proved without selected, passing tests and a manifest.

**How to avoid:** Require the existing finalizer result `proof_state: "proved"`, nonzero selected/passed counts, a successful raw job conclusion, and `live-stripe-proof` artifact presence in the fresh evidence record. [VERIFIED: scripts/ci/provider_proof.mjs:116-132; .github/workflows/ci.yml:1350-1358]

## Code Examples

### Minimal runtime and CI contract shape

```elixir
# accrue/config/runtime.exs — inside the existing test-mode live-key branch
stripe_webhook_secret = System.get_env("STRIPE_WEBHOOK_SECRET", "") |> String.trim()

config :accrue,
  processor: Accrue.Processor.Stripe,
  stripe_secret_key: stripe_test_secret_key,
  webhook_signing_secrets: %{stripe: [stripe_webhook_secret]}
```

```yaml
# .github/workflows/ci.yml — live-stripe job env and existing preflight
STRIPE_WEBHOOK_SECRET: ${{ secrets.STRIPE_WEBHOOK_SECRET }}

if [ -n "${STRIPE_TEST_SECRET_KEY:-}" ] && [ -n "${STRIPE_WEBHOOK_SECRET:-}" ] && [ -n "${ACCRUE_LIVE_BASIC_PRICE:-}" ] && [ -n "${ACCRUE_LIVE_PRO_PRICE:-}" ]; then
  echo "configured=true" >> "$GITHUB_OUTPUT"
else
  echo "configured=false" >> "$GITHUB_OUTPUT"
  exit 1
fi
```

DATA_M4R8P1XC_START
The exact pre-existing identifiers are `"STRIPE_TEST_SECRET_KEY"`, `"ACCRUE_LIVE_BASIC_PRICE"`, `"ACCRUE_LIVE_PRO_PRICE"`, `"configured=true"`, and `"configured=false"`.
DATA_M4R8P1XC_END

The snippet is a planning skeleton: implementation must preserve the existing generic failure message and all always-run finalization/upload steps. [VERIFIED: .github/workflows/ci.yml:1284-1358]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| Three-value live-provider preflight | Four-value boot-contract preflight including endpoint signing secret | Phase 228 proposed | Detects the exact missing boot input before suite selection, while retaining provider-proof semantics. [VERIFIED: .github/workflows/ci.yml:1284-1329; .planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.md:68-70] |

**Deprecated/outdated:** The Phase 227 restoration command is not a valid recovery mechanism for this issue because its budget is exhausted. [VERIFIED: .planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.md:70-72]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | The repository secret should be named `STRIPE_WEBHOOK_SECRET`, matching the package’s documented runtime variable. | Architecture Patterns | A different existing secret name could require a mapping decision or duplicate secret. [ASSUMED] |
| A2 | One first-attempt manual live-Stripe dispatch is the appropriate fresh Phase 228 evidence budget after static checks. | Summary | The planner must make the run count/budget explicit so it cannot silently widen. [ASSUMED] |

## Resolved Questions

1. **RESOLVED — Which Stripe test-mode endpoint supplies the signing secret?**
   - What we know: Stripe endpoint secrets are endpoint-specific and begin with `whsec_`; Phase 227 failed because none was mapped into the CI boot path. [CITED: https://docs.stripe.com/webhooks/signature?lang=node&locale=en-GB]
   - Resolution: Plan 228-02 Task 1 owns this execution-time decision. Its blocking maintainer checkpoint requires the signing secret for the exact Stripe Dashboard test-mode endpoint used by this repository to be stored as `STRIPE_WEBHOOK_SECRET`, accepts only sanitized `configured` confirmation, and rejects a CLI forwarding secret, API key, or different endpoint secret. No secret value or endpoint identifier is exposed.

2. **RESOLVED — What is the Phase 228 live-run ceiling?**
   - What we know: Phase 227's budget is exhausted and cannot be borrowed. [VERIFIED: .planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.md:70-72]
   - Resolution: Plan 228-02 Task 2 owns the explicit authorization decision and locks the ceiling to exactly one new attempt-1 `workflow_dispatch` with `run_live_stripe: true` at the repaired committed SHA. A created run consumes the budget regardless of outcome; an API rejection that creates no run leaves `consumed:false`; neither branch authorizes a retry, replacement, alternate transport, or use of Phase 227 authority.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---:|---|---|
| Node.js | Static provider-workflow verifier | ✓ | v22.14.0 | — [VERIFIED: environment probe 2026-08-28] |
| Elixir/OTP | Runtime boot-contract check / live suite | ✓ | OTP 28; CI Elixir 1.19.5 | — [VERIFIED: environment probe 2026-08-28; .github/workflows/ci.yml:1300-1303] |
| GitHub CLI | Observe/dispatch fresh Actions evidence | ✓, API rate-limited | 2.95.0 | Wait for rate-limit reset; do not infer secret state. [VERIFIED: environment probe 2026-08-28] |
| GitHub repository secret | Live provider boot | Unknown | — | Maintainer configures `STRIPE_WEBHOOK_SECRET`; no code-only fallback. [ASSUMED] |
| Stripe sandbox endpoint secret | Signature-validation configuration | Unknown | — | Maintainer retrieves the matching endpoint secret from Stripe Dashboard; do not invent/placehold it. [CITED: https://docs.stripe.com/webhooks?lang=node] |

**Missing dependencies with no fallback:** repository access to a real test-mode endpoint signing secret and maintainer authority to set it.

**Missing dependencies with fallback:** GitHub API listing is rate-limited; static repository checks can proceed, but fresh live evidence must wait for API access/maintainer action.

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | Existing dependency-free Node `assert` fixtures plus ExUnit / Mix runtime check. [VERIFIED: scripts/ci/verify_provider_proof.mjs:1-15; accrue/mix.exs:128-141] |
| Config file | `accrue/config/runtime.exs` [VERIFIED: accrue/config/runtime.exs:1-38] |
| Quick run command | `node scripts/ci/verify_provider_proof.mjs --fixtures` |
| Full targeted suite | `cd accrue && mix test test/accrue/config_test.exs` plus a no-network runtime boot-contract command with dummy values |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| TBD-228-01 | Workflow binds/checks the signing-secret variable and preserves always-run proof steps. | static + negative fixture | `node scripts/ci/verify_provider_proof.mjs --fixtures` | ✅ extend existing |
| TBD-228-02 | Test runtime maps a nonempty signing secret before Stripe boot validation. | integration / no-network | targeted Mix/ExUnit runtime-config test | ❌ Wave 0 |
| TBD-228-03 | Fresh run is counted as provider proof only with selected passing tests and manifest. | live contract | existing provider finalizer + recorded Actions evidence | ✅ tooling; ❌ Phase 228 record |

### Sampling Rate

- **Per task commit:** `node scripts/ci/verify_provider_proof.mjs --fixtures`
- **Per wave merge:** targeted Mix configuration test
- **Phase gate:** exactly one newly authorized first-attempt dispatch; final record must show `proved`, nonzero selection, manifest presence, and the proof artifact.

### Wave 0 Gaps

- [ ] Extend `scripts/ci/verify_provider_proof.mjs` fixtures to reject missing/renamed signing-secret binding and preflight omission without exposing any value.
- [ ] Add a deterministic no-network runtime boot-contract test for the live-key-plus-webhook-secret path.
- [ ] Create a Phase 228 sanitized evidence record/schema before a live dispatch.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | No | CI credential injection is not end-user authentication. |
| V3 Session Management | No | No session handling changes. |
| V4 Access Control | Yes | Maintainer-only repository/Stripe secret administration; CI keeps read-only workflow permissions. [VERIFIED: scripts/ci/verify_provider_proof.mjs:55-56] |
| V5 Input Validation | Yes | Trim/nonempty preflight and Accrue boot validation reject missing signing configuration. [VERIFIED: .github/workflows/ci.yml:1320-1329; accrue/lib/accrue/config.ex:715-728] |
| V6 Cryptography | Yes | Reuse Stripe/Accrue webhook signature verification; do not implement HMAC or alter raw-body semantics. [CITED: https://docs.stripe.com/webhooks?lang=node] |

### Known Threat Patterns for this Stack

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Secret disclosure through shell/log/artifact | Information disclosure | Bind secret only in job env; test presence only; retain generic diagnostics; never serialize values. [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets] |
| Wrong endpoint/CLI signing secret | Spoofing | Use the exact test-mode endpoint secret; Stripe says endpoint secrets differ and CLI/Dashboard secrets are not interchangeable. [CITED: https://docs.stripe.com/webhooks/signature?lang=node&locale=en-GB] |
| Green but empty provider run | Repudiation | Require existing manifest counts, successful raw conclusion, and proof artifact before marking `proved`. [VERIFIED: scripts/ci/provider_proof.mjs:116-132] |
| Secretless boot failure hidden as test skip | Denial of service / integrity | Expand preflight and keep always-run finalizer/artifact to record `misconfigured` explicitly. [VERIFIED: .github/workflows/ci.yml:1320-1358; scripts/ci/provider_proof.mjs:107-114] |

## Sources

### Primary (HIGH confidence)

- Repository evidence: `.planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.md:64-72` — immutable failure, proof class, and exhausted Phase 227 authority.
- Runtime and boot source: `accrue/config/runtime.exs:22-37`; `accrue/lib/accrue/config.ex:703-730,1243-1255` — exact missing configuration edge and boot validation.
- CI/proof source: `.github/workflows/ci.yml:1284-1358`; `scripts/ci/provider_proof.mjs:105-132`; `scripts/ci/verify_provider_proof.mjs:55-88` — existing three-value preflight and evidence-preservation contract.

### Secondary (MEDIUM confidence)

- [GitHub Actions: Using secrets](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets) — empty unset-secret behavior and environment-variable handling.
- [Stripe: Receive webhook events](https://docs.stripe.com/webhooks?lang=node) — endpoint-specific signing secret and raw-body verification requirements.
- [Stripe: Resolve signature verification errors](https://docs.stripe.com/webhooks/signature?lang=node&locale=en-GB) — endpoint/CLI secret mismatch warning.

### Tertiary (LOW confidence)

- GitHub secret-name audit attempt, 2026-08-28 — unavailable due HTTP 403 API rate limit; no values accessed.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — all components are current repository-owned files; no packages are proposed.
- Architecture: HIGH — direct failure evidence traces the missing CI → runtime → boot edge.
- Pitfalls: MEDIUM — repository facts plus current GitHub/Stripe official documentation.

**Research date:** 2026-08-28
**Valid until:** 2026-09-27 for the repository diagnosis; recheck GitHub secret availability immediately before live execution.
