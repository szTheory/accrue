# Phase 208: Prove convergence on the representative slice + wire CI + ACCEPT - Research

**Researched:** 2026-07-07
**Domain:** Admin UI ratchet convergence, deterministic CI guardrails, ledger baseline freeze, maintainer sign-off
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

The following locked decisions, discretion areas, and deferred ideas are copied from `.planning/phases/208-prove-convergence-on-the-representative-slice-wire-ci-accept/208-CONTEXT.md`. [VERIFIED: codebase grep]

### Locked Decisions

### Implementation Decisions

**D-58: Freeze only after Phase-200-style evidence bundle is complete.** The baseline freeze is acceptable only when: two committed dry `rounds.ndjson` rows for `scope=foundation` exist; folded open findings are zero; `finding-regressions.ndjson` is 0 bytes; Phase 200 `regressions.ndjson` is 0 bytes; every foundation slice cell has `coverage_status == "covered"` and `score >= 2`; `ledger.baseline.json` is non-empty and frozen; the independent verifier is green; existing UI guardrails/asset drift are green; the sign-off verifier sees exactly one ACCEPT line.

**D-59: Score-floor enforcement is a Phase 208 implementation requirement.** Today `phase-ratchet-ledger.mjs`'s dry-run clause checks foundation coverage only by `coverage_status`, not by `score >= 2`. Phase 208 must tighten either `phase-ratchet-ledger.mjs` itself or an explicit freeze/sign-off verifier so `CONVERGED`/freeze cannot happen when a slice cell is covered but scored below 2.

**D-60: Freeze remains an explicit local act, not a CI side effect.** The canonical freeze command is `cd accrue_admin && node e2e/ratchet/phase-ratchet-ledger.mjs --freeze`. Do not add freeze behavior to `npm run ratchet:ledger`, deterministic CI, or Phase 200 guardrails.

**D-61: Baseline must be materially non-empty.** A placeholder all-zero baseline with an empty-file hash is not acceptable even if the file validates structurally. If the representative slice genuinely has zero open items, the sign-off/freeze evidence still needs to distinguish "real resolved/locked baseline" from "never ran the ratchet."

**D-62: CI gets a dedicated deterministic-only job.** Add a stable job id/name `admin-ui-ratchet-guardrails` beside the existing UI guardrail jobs. It must pass without `ANTHROPIC_API_KEY`, avoid LLM proposer/verifier calls, and should remain Node-only unless a concrete existing verifier requires BEAM/Postgres/browser setup.

**D-63: CI is non-mutating against the frozen baseline.** The guardrail job may recompute and compare ledger totals, run self-tests, verify regression files, verify sign-off, and upload summaries/artifacts. It must not regenerate/overwrite/freeze `ledger.baseline.json` or mutate ratchet artifacts. If existing scripts mutate by default, add a read-only verify mode or wrapper.

**D-64: CI contract verifier is required.** Add `scripts/ci/verify_admin_ui_ratchet_ci_contract.sh` that checks the workflow contains the stable job id/name, deterministic self-tests, independent ledger verifier, required artifacts/summaries, and annotation-sweep wiring, and rejects usage of `secrets.`, `ANTHROPIC_API_KEY`, `ratchet-propose`, `ratchet-verify`, `ui.round`, `ui.fix`, browser Playwright capture commands, and `--freeze` inside the deterministic job.

**D-65: Failure proofs use scratch fixtures, not the real baseline.** Add deterministic tests proving: (1) a synthetic ledger count increase fails the gate, and (2) a persona/lens regression fails even when another persona improves. The invariant is "any single lens count increase relative to the frozen baseline makes the gate red."

**D-66: CI/status copy is explicit and accessibility-friendly.** The deterministic job and sign-off evidence must include the UI-SPEC wording: no-key proof, 0-byte finding regressions, independent recompute match, synthetic count-increase proof, persona regression proof, existing UI gates, and bundle freshness. Statuses use text values `PASS`, `BLOCKED`, `PENDING`, `N/A`.

**D-67: Sign-off is a structured evidence artifact plus a single ACCEPT decision.** Create `UI-RATCHET-SIGN-OFF.md` with required sections from the UI-SPEC, embedding the runbook unless a separate linked runbook is also verified. The final maintainer decision line remains the only human decision surface.

**D-68: Sign-off verifier mirrors Phase 200.** Add `scripts/ci/verify_ui_ratchet_signoff.mjs` with self-tests/fixtures. It must fail on missing required sections, invalid status tokens, missing foundation convergence evidence, missing ACCEPT line, non-empty regression files, unfrozen or placeholder baseline, missing runbook headings, missing synthetic failure proofs, missing existing gate evidence, forbidden full-sweep wording, or invalid artifact references.

**D-69: Runbook is executable and bounded.** The follow-on runbook must show exact commands/artifacts/statuses for graduating another surface/slice under the ratchet, including recovery when a regression file becomes non-empty. It must not imply an automatic full-admin sweep in Phase 208.

**D-70: Copy/UX/accessibility is part of the acceptance surface.** Evidence copy must match UI-SPEC strings closely enough for automated checks, use text status labels, keep commands/hashes/statuses monospace in Markdown, and make error states name the next artifact/command to inspect.

### the agent's Discretion

### Claude's Discretion

You may choose the exact implementation shape for the deterministic gate so long as it respects the locked behavior above:

- whether `phase-ratchet-ledger.mjs` gains a read-only `--verify-frozen` mode or the CI job uses a separate wrapper around `verify_ratchet_ledger.mjs`
- where scratch fixture generation lives for synthetic count-increase and persona-regression proofs
- whether the score-floor check is enforced in the reducer, the freeze verifier, the sign-off verifier, or more than one layer
- exact artifact filenames for CI summaries, as long as they are stable and referenced by sign-off/runbook/verifiers
- how much of the runbook lives in `UI-RATCHET-SIGN-OFF.md` versus a linked runbook file, provided the verifier enforces the required headings and paths

### Deferred Ideas (OUT OF SCOPE)

## Deferred Ideas

- Full-admin-surface convergence sweep. This belongs to a later optional scope-gated phase, not Phase 208.
- LLM evaluator/proposer/verifier in CI. Deterministic CI remains key-free.
- New billing-domain product behavior, new adopter runtime APIs, `accrue_portal`, Tailwind/shadcn migration, or broader CSS architecture changes.
- Making the representative slice larger than the locked foundation slice unless needed to satisfy existing manifest semantics.
</user_constraints>

## Summary

Phase 208 should plan around the ratchet machinery delivered in Phase 207 rather than around new infrastructure. The representative slice is already defined as `SLICES.foundation = ["component-kitchen", "dashboard", "subscription-detail", "subscriptions"]`, `mix accrue_admin.ui.round` already supports `--slice foundation`, and `ui.fix` already applies decisions, rebuilds assets, commits static assets, recaptures, probes, and finalizes fixes. [VERIFIED: codebase grep]

The main planning risk is not missing infrastructure; it is acceptance hardening. The current ledger reducer treats a dry round as passing the slice coverage floor when all scoped cells have `coverage_status == "covered"`, but it does not enforce `score >= 2`, and the current committed baseline is an unfrozen placeholder with the empty-file hash. [VERIFIED: codebase grep] Phase 208 must therefore add preflight/read-only verification around score floors, non-placeholder frozen baselines, regression files, and synthetic failure proofs before exposing maintainer `ACCEPT`. [VERIFIED: 208-CONTEXT.md]

The deterministic CI job should be Node-only and non-mutating: run self-tests, read-only ledger verification, sign-off verification, CI contract verification, and artifact/status reporting. It must not run `ratchet-propose`, `ratchet-verify`, `ui.round`, `ui.fix`, Playwright capture, or `--freeze`, and it must not reference `ANTHROPIC_API_KEY` or `secrets.`. [VERIFIED: 208-CONTEXT.md]

**Primary recommendation:** Plan Phase 208 as a convergence acceptance phase: first tighten/read-only verify the ledger invariants, then prove failure modes with scratch fixtures, then add deterministic CI and sign-off/runbook verifiers, and only then perform the local `--freeze` and maintainer `ACCEPT`. [VERIFIED: codebase grep]

## Project Constraints (from CLAUDE.md)

- The repository is a monorepo for `accrue` and `accrue_admin`; Phase 208 work is constrained to the admin ratchet/CI/sign-off surface. [VERIFIED: CLAUDE.md]
- `accrue_admin` uses Phoenix LiveView with a static CSS bundle owned by the existing asset pipeline; committed static bundle freshness must be preserved. [VERIFIED: CLAUDE.md]
- The admin UI uses the existing `ax-*` CSS system of record; no Tailwind or shadcn migration belongs in this phase. [VERIFIED: CLAUDE.md]
- Security-sensitive changes must respect the existing test and CI guardrail pattern rather than adding uncontrolled runtime dependencies. [VERIFIED: CLAUDE.md]
- No project-local GSD skills were found under `.claude/skills`, `.agents/skills`, or `.codex/skills` during research. [VERIFIED: codebase grep]
- No `AGENTS.md` exists at the repository root; project-specific instructions came from `CLAUDE.md`. [VERIFIED: codebase grep]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CONV-01 | Ratchet converges the representative slice with every slice cell score >= 2 and both regression files empty. | Existing `ui.round --slice foundation` supports the slice, but `phase-ratchet-ledger.mjs` must be tightened or wrapped for `score >= 2`. [VERIFIED: codebase grep] |
| CONV-02 | First non-empty `ledger.baseline.json` is frozen as the slice high-water mark. | Existing `--freeze` writes `frozen: true`, but current committed baseline is unfrozen and uses the empty-file hash, so freeze must be guarded by non-placeholder evidence. [VERIFIED: codebase grep] |
| CONV-03 | New deterministic-only CI job passes with no key and blocks synthetic ledger count increase. | Existing `verify_ratchet_ledger.mjs` has mismatch self-tests; Phase 208 needs a dedicated non-mutating CI wrapper/job and synthetic fixture proof. [VERIFIED: codebase grep] |
| CONV-04 | Cross-persona improvement/regression is caught by automated test. | Ledger counts are keyed by `(surface, persona, lens, viewport)` and compare exact open counts, so any single lens count increase can be tested in scratch fixtures. [VERIFIED: codebase grep] |
| CONV-05 | Existing UI gates remain green and `accrue_admin.css` stays fresh. | Current workflow has `admin-hardening-guardrails`, `admin-phase200-guardrails`, and asset diff checks for `accrue_admin/priv/static/accrue_admin.css`. [VERIFIED: codebase grep] |
| CONV-06 | `UI-RATCHET-SIGN-OFF.md` carries maintainer `ACCEPT` line enforced by Phase 200 style verifier. | `scripts/ci/verify_phase200_signoff.mjs` provides the local verifier pattern; Phase 208 needs a ratchet-specific verifier and fixtures. [VERIFIED: codebase grep] |
| CONV-07 | Runbook enables safe follow-on graduation of remaining admin surfaces. | UI-SPEC fixes required runbook headings, exact status tokens, and bounded follow-on language. [VERIFIED: 208-UI-SPEC.md] |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Live convergence rounds | Local developer CLI / Mix task | Browser capture, LLM evaluator | `mix accrue_admin.ui.round --slice foundation` orchestrates assets, Playwright capture, proposer, verifier, seal, and digest locally; it is explicitly excluded from deterministic CI. [VERIFIED: codebase grep] |
| Fix loop | Local developer CLI / Mix task | Static asset pipeline, Git | `mix accrue_admin.ui.fix` applies `decisions.json`, rebuilds assets, commits static assets, recaptures, and finalizes guards. [VERIFIED: codebase grep] |
| Ledger baseline freeze | Local Node script | Sign-off verifier | `phase-ratchet-ledger.mjs --freeze` is the canonical explicit local freeze command, not a CI side effect. [VERIFIED: 208-CONTEXT.md] |
| Deterministic ratchet gate | GitHub Actions Node job | Shell/Node verifiers | CI should recompute/read artifacts and run scratch proofs without LLM keys, BEAM, Postgres, or browser capture unless a concrete verifier requires them. [VERIFIED: 208-CONTEXT.md] |
| Maintainer acceptance | Markdown artifact plus verifier | CI contract job | `UI-RATCHET-SIGN-OFF.md` is the human decision surface; `verify_ui_ratchet_signoff.mjs` should enforce sections, statuses, evidence, and exactly one final `ACCEPT` line. [VERIFIED: 208-UI-SPEC.md] |
| Existing guardrails preservation | Existing GitHub Actions jobs | Phase 208 contract verifier | Existing `admin-hardening-guardrails`, `admin-phase200-guardrails`, and asset drift jobs remain independent and must stay green. [VERIFIED: codebase grep] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Node.js | v22.14.0 local | Run deterministic ratchet scripts and CI verifiers. | Existing ratchet scripts are `.mjs`/`.js` Node programs and the proposed CI job is Node-only. [VERIFIED: environment probe] |
| npm | 11.1.0 local | Run package scripts such as `ratchet:ledger:self-test` and Playwright commands. | Existing `accrue_admin/package.json` owns the ratchet scripts. [VERIFIED: environment probe] |
| Elixir / Mix | Elixir 1.19.5, Mix 1.19.5 local | Run local convergence/fix Mix tasks and task tests. | Existing one-command round/fix loop is implemented as Mix tasks. [VERIFIED: environment probe] |
| Playwright | 1.59.1 local via `npx playwright --version` | Capture/admin visual tests during local convergence only. | Existing visual capture spec and ratchet capture flow use Playwright; deterministic CI must avoid capture commands. [VERIFIED: environment probe] |
| GitHub Actions | Existing `.github/workflows/ci.yml` | Host dedicated deterministic guardrail job and preserve existing UI gates. | Current workflow already defines the Phase 192 and Phase 200 admin guardrail jobs and annotation sweep. [VERIFIED: codebase grep] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| `phase-ratchet-ledger.mjs` | Existing local script | Compute counts, regression deltas, baseline, and round reducer status. | Use for local freeze and for read-only verification only after preventing CI mutation. [VERIFIED: codebase grep] |
| `verify_ratchet_ledger.mjs` | Existing local script | Independent recompute of ledger totals and regression-file emptiness checks. | Extend or wrap for frozen/non-placeholder/score-floor checks and synthetic fixtures. [VERIFIED: codebase grep] |
| `verify_phase200_signoff.mjs` | Existing local script | Pattern for sign-off section/status/ACCEPT verification and fixtures. | Mirror its structure for `verify_ui_ratchet_signoff.mjs`. [VERIFIED: codebase grep] |
| `verify_phase200_ci_contract.sh` and guardrail contract scripts | Existing local scripts | Pattern for grepping stable workflow contracts. | Mirror for `verify_admin_ui_ratchet_ci_contract.sh`. [VERIFIED: codebase grep] |
| W3C status-message guidance | WCAG 2.2 official docs | Make generated status copy programmatically understandable when surfaced in HTML/digests. | Use text status and live/status semantics if Phase 208 adds HTML status output. [CITED: https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing Node verifiers | Add a new test framework dependency | Not needed; current scripts already have self-test modes and the phase forbids unnecessary dependencies. [VERIFIED: codebase grep] |
| Dedicated deterministic CI job | Reuse `admin-phase200-guardrails` | Phase 208 needs ratchet-specific contract checks and must not couple failure semantics to Phase 200. [VERIFIED: 208-CONTEXT.md] |
| Explicit `--freeze` command | Freeze inside `npm run ratchet:ledger` or CI | Locked out by D-60/D-63 because freeze must be a local maintainer act and CI must be non-mutating. [VERIFIED: 208-CONTEXT.md] |
| Representative slice | Full admin sweep | Full sweep is explicitly deferred to a later optional scope-gated phase. [VERIFIED: 208-CONTEXT.md] |

**Installation:**

```bash
# No new packages should be installed for Phase 208.
```

**Version verification:** Local versions were verified with `node --version`, `npm --version`, `elixir --version`, `mix --version`, and `cd accrue_admin && npx playwright --version`. [VERIFIED: environment probe]

## Package Legitimacy Audit

Phase 208 does not require installing external packages, so the package legitimacy gate is not triggered. Existing dependencies such as `@playwright/test`, `@axe-core/playwright`, and `@anthropic-ai/sdk` are already declared in `accrue_admin/package.json`; Phase 208 should not add new dependencies. [VERIFIED: codebase grep]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| None added | n/a | n/a | n/a | n/a | n/a | No install planned. [VERIFIED: codebase grep] |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: codebase grep]
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: codebase grep]

## Architecture Patterns

### System Architecture Diagram

```text
Local maintainer
  |
  | mix accrue_admin.ui.round --slice foundation
  v
Assets build -> Playwright capture (foundation slice) -> LLM propose -> LLM verify
  |                                                           |
  |                                                   findings.ledger.ndjson
  v                                                           v
phase-ratchet-ledger.mjs --seal-round -> rounds.ndjson -> ratchet-digest.mjs
  |                                                           |
  | if two dry rounds, score floor, no regressions            v
  v                                                   round-NN/digest.html
phase-ratchet-ledger.mjs --freeze
  |
  v
ledger.baseline.json (frozen, non-placeholder)
  |
  v
UI-RATCHET-SIGN-OFF.md + runbook + ACCEPT
  |
  v
GitHub Actions admin-ui-ratchet-guardrails
  |
  +-> self-tests and scratch failure proofs
  +-> independent read-only baseline recompute
  +-> sign-off verifier
  +-> CI contract verifier
  +-> artifact/status summary
```

This flow separates local LLM/browser convergence from deterministic CI verification. [VERIFIED: 208-CONTEXT.md]

### Recommended Project Structure

```text
.github/workflows/
└── ci.yml                                      # Add admin-ui-ratchet-guardrails job beside existing admin UI gates.

scripts/ci/
├── verify_ratchet_ledger.mjs                  # Extend or wrap for read-only/frozen/scratch regression checks.
├── verify_admin_ui_ratchet_ci_contract.sh     # New workflow contract verifier.
└── verify_ui_ratchet_signoff.mjs              # New Phase 208 sign-off verifier with fixtures.

accrue_admin/e2e/ratchet/
├── phase-ratchet-ledger.mjs                   # Existing reducer/baseline/freeze implementation.
├── ratchet-ledger.js                          # Existing ledger row helpers.
├── findings.ledger.ndjson                     # Ratchet ledger input.
├── finding-regressions.ndjson                 # Must be 0 bytes at acceptance.
├── rounds.ndjson                              # Must include two dry foundation rows at acceptance.
└── ledger.baseline.json                       # Frozen representative-slice high-water mark.

.planning/phases/208-prove-convergence-on-the-representative-slice-wire-ci-accept/
├── UI-RATCHET-SIGN-OFF.md                     # New evidence and final ACCEPT artifact.
└── 208-RESEARCH.md                            # This research artifact.
```

### Pattern 1: Make Freeze A Guarded Local Transition

**What:** Treat `--freeze` as a final transition after preflight checks pass, not as an ordinary ledger recompute. [VERIFIED: codebase grep]

**When to use:** Only after representative-slice convergence evidence exists: two dry foundation rows, zero regression files, score floor, non-placeholder baseline content, existing gates green, and sign-off verifier green. [VERIFIED: 208-CONTEXT.md]

**Example:**

```bash
# Source: 208-CONTEXT.md and existing phase-ratchet-ledger.mjs
cd accrue_admin
node e2e/ratchet/phase-ratchet-ledger.mjs --freeze
node ../scripts/ci/verify_ratchet_ledger.mjs
```

### Pattern 2: Deterministic CI Uses Read-Only Recompute Plus Fixtures

**What:** The CI job should run verifier scripts against committed artifacts and scratch temp directories, then upload summaries/artifacts. [VERIFIED: 208-CONTEXT.md]

**When to use:** Every PR after the baseline is frozen; the job must pass without `ANTHROPIC_API_KEY`. [VERIFIED: 208-CONTEXT.md]

**Example:**

```yaml
# Source: 208-UI-SPEC.md and existing .github/workflows/ci.yml pattern
admin-ui-ratchet-guardrails:
  name: Admin UI ratchet guardrails
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v4
      with:
        node-version: 22
    - run: cd accrue_admin && npm run ratchet:ledger:self-test
    - run: node scripts/ci/verify_ratchet_ledger.mjs --verify-frozen
    - run: node scripts/ci/verify_ui_ratchet_signoff.mjs --require-accept
    - run: bash scripts/ci/verify_admin_ui_ratchet_ci_contract.sh
```

The exact CLI flags may differ, but the job must remain non-mutating and key-free. [VERIFIED: 208-CONTEXT.md]

### Pattern 3: Test Regression Semantics With Scratch Ledgers

**What:** Build temp fixture directories containing baseline and ledger rows, then assert verifier exit status rather than mutating committed artifacts. [VERIFIED: codebase grep]

**When to use:** Synthetic count-increase and cross-persona/lens regression tests. [VERIFIED: 208-CONTEXT.md]

**Example:**

```javascript
// Source: existing verify_ratchet_ledger.mjs self-test style
// Baseline: lens A has 1 open finding and lens B has 1 open finding.
// Test ledger: lens A drops to 0, lens B rises to 2.
// Expected: verifier fails because lens B increased.
```

### Pattern 4: Mirror Phase 200 Sign-Off Verification, But Do Not Reuse Phase 200 Semantics Blindly

**What:** Create a new `verify_ui_ratchet_signoff.mjs` that enforces Phase 208 UI-SPEC sections, statuses, exact final line shape, artifact references, frozen baseline, runbook headings, and failure proof evidence. [VERIFIED: codebase grep]

**When to use:** In local preflight and deterministic CI. [VERIFIED: 208-CONTEXT.md]

**Example:**

```text
Final maintainer decision: ACCEPT (maintainer approved YYYY-MM-DD). Evidence source: accrue_admin/e2e/ratchet/ledger.baseline.json and .planning/phases/208-prove-convergence-on-the-representative-slice-wire-ci-accept/UI-RATCHET-SIGN-OFF.md.
```

The date placeholder must be replaced by the actual maintainer approval date when the sign-off is created. [VERIFIED: 208-UI-SPEC.md]

### Anti-Patterns to Avoid

- **Running LLM commands in deterministic CI:** `ratchet-propose`, `ratchet-verify`, `ui.round`, and `ui.fix` are explicitly forbidden in the new CI job. [VERIFIED: 208-CONTEXT.md]
- **Allowing CI to mutate or freeze artifacts:** CI must not regenerate, overwrite, or freeze `ledger.baseline.json`. [VERIFIED: 208-CONTEXT.md]
- **Freezing the current placeholder baseline:** The current baseline is unfrozen and uses the empty-file hash, which D-61 rejects. [VERIFIED: codebase grep]
- **Counting coverage without score:** The current reducer coverage clause does not check `score >= 2`, so a plan that relies only on current dry status is incomplete. [VERIFIED: codebase grep]
- **Using color-only statuses:** Status evidence must use the text tokens `PASS`, `BLOCKED`, `PENDING`, and `N/A`; WCAG use-of-color guidance says color cannot be the only visual means of conveying information. [VERIFIED: 208-UI-SPEC.md] [CITED: https://www.w3.org/WAI/WCAG21/Understanding/use-of-color.html]
- **Making the job advisory:** GitHub Actions `continue-on-error: true` prevents a failing job from failing the workflow, so the ratchet guardrail job must not be configured as advisory. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Ledger parsing and counts | A second ad hoc NDJSON counter | Extend or wrap `verify_ratchet_ledger.mjs` and existing ledger helpers | Existing verifier already independently recomputes exact open counts and has self-tests. [VERIFIED: codebase grep] |
| Round orchestration | A new shell script for capture/propose/verify/seal | `mix accrue_admin.ui.round --slice foundation` | Phase 207 already shipped the one-command sequence and tests. [VERIFIED: codebase grep] |
| Fix orchestration | Manual edit/commit/recapture sequence | `mix accrue_admin.ui.fix` | Existing task applies decisions, rebuilds assets, commits static assets, and finalizes fixes. [VERIFIED: codebase grep] |
| Sign-off parser | Informal Markdown review | `verify_ui_ratchet_signoff.mjs` modeled on `verify_phase200_signoff.mjs` | Phase 200 already has a tested verifier pattern for sections, statuses, evidence, and final decision line. [VERIFIED: codebase grep] |
| CI policy review | Manual workflow inspection | `verify_admin_ui_ratchet_ci_contract.sh` | Locked decision D-64 requires automated grep-style contract checks. [VERIFIED: 208-CONTEXT.md] |
| Accessibility/status semantics | Color badges only | Text status tokens and status-message semantics | W3C guidance requires status changes be programmatically determinable where applicable and not conveyed only by color. [CITED: https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html] |

**Key insight:** Phase 208 is an evidence and acceptance hardening phase; custom new infrastructure increases risk because the existing reducer, verifier, sign-off, and workflow patterns already define the control points. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Dry Round Says Covered But Score Is Below 2

**What goes wrong:** The reducer can treat a scoped dry round as passing coverage even if a foundation cell has `score < 2`. [VERIFIED: codebase grep]

**Why it happens:** `computeClauseCoverageFloor` currently checks `coverage_status === "covered"` but not the numeric score floor. [VERIFIED: codebase grep]

**How to avoid:** Add a score-floor preflight to the reducer, freeze verifier, sign-off verifier, or multiple layers; make the failure message name the exact census cell and required score. [VERIFIED: 208-CONTEXT.md]

**Warning signs:** A convergence banner or frozen baseline exists while `final.cells.json` still has scoped rows with `score` null, 0, or 1. [VERIFIED: codebase grep]

### Pitfall 2: Representative Slice Names Do Not Match Census Cell Surface Names

**What goes wrong:** `SLICES.foundation` includes `component-kitchen`, but Phase 200 cell census rows use component-level surface names such as design-system component surfaces, not necessarily the capture-page name `component-kitchen`. [VERIFIED: codebase grep]

**Why it happens:** Playwright capture surface names and Phase 200 scorecard cell `surface` values are different namespaces in at least some rows. [VERIFIED: codebase grep]

**How to avoid:** Before enforcing the score floor, define the mapping from `component-kitchen` to the component-family census surfaces and test it with a fixture that would fail if the kitchen page is treated as one exact census surface only. [VERIFIED: codebase grep]

**Warning signs:** Score-floor checks pass with zero component-family rows examined. [VERIFIED: codebase grep]

### Pitfall 3: Placeholder Baseline Looks Structurally Valid

**What goes wrong:** `ledger.baseline.json` can validate structurally while still representing no real ratchet run. [VERIFIED: codebase grep]

**Why it happens:** The current committed baseline has `frozen: false`, empty-file `ledger_sha256`, and all-zero counts. [VERIFIED: codebase grep]

**How to avoid:** Verify `frozen === true`, reject the empty-file hash, require real foundation round evidence, and require either non-zero locked/resolved evidence or another explicit non-placeholder proof defined by the phase. [VERIFIED: 208-CONTEXT.md]

**Warning signs:** `ledger_sha256` equals `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`. [VERIFIED: codebase grep]

### Pitfall 4: CI Accidentally Mutates The Baseline

**What goes wrong:** A PR job can rewrite `ledger.baseline.json` and hide the regression it should catch. [VERIFIED: 208-CONTEXT.md]

**Why it happens:** The existing `ratchet:ledger` script runs `phase-ratchet-ledger.mjs`, whose default path can regenerate the baseline. [VERIFIED: codebase grep]

**How to avoid:** Add a read-only verify mode or a wrapper that never calls the mutating path; have the CI contract reject `--freeze` and mutating round/fix commands. [VERIFIED: 208-CONTEXT.md]

**Warning signs:** The deterministic CI job runs `npm run ratchet:ledger` directly after a frozen baseline exists. [VERIFIED: codebase grep]

### Pitfall 5: Failure Proof Improves One Lens And Masks Another

**What goes wrong:** A total-count comparison can pass if one persona/lens improves while another regresses. [VERIFIED: 208-CONTEXT.md]

**Why it happens:** Aggregated totals lose the per-lens monotonic invariant. [VERIFIED: 208-CONTEXT.md]

**How to avoid:** Compare exact counts by `(surface, persona, lens, viewport)` and fail on any count increase, even if another key decreases. [VERIFIED: codebase grep]

**Warning signs:** Synthetic fixture only checks global totals. [VERIFIED: 208-CONTEXT.md]

### Pitfall 6: Existing UI Gates Are Treated As A Text Claim Only

**What goes wrong:** Sign-off says existing gates are green, but no verifier checks job names, command evidence, or asset freshness. [VERIFIED: 208-CONTEXT.md]

**Why it happens:** Phase 208 adds a new job beside existing jobs and can accidentally drift from workflow reality. [VERIFIED: codebase grep]

**How to avoid:** CI contract verifier should check stable job ids/names and annotation sweep wiring; sign-off verifier should require evidence rows for `admin-hardening-guardrails`, `admin-phase200-guardrails`, asset drift, and `accrue_admin.css` freshness. [VERIFIED: 208-UI-SPEC.md]

**Warning signs:** `UI-RATCHET-SIGN-OFF.md` contains `PASS` copy but no referenced command, run id, artifact, or verifier output. [VERIFIED: 208-UI-SPEC.md]

## Code Examples

Verified patterns from existing code and official sources:

### Slice Definition

```javascript
// Source: accrue_admin/e2e/baseline-manifest.js
export const SLICES = {
  foundation: ["component-kitchen", "dashboard", "subscription-detail", "subscriptions"],
};
```

This is the representative slice Phase 208 must converge. [VERIFIED: codebase grep]

### Current Dry Coverage Gap

```javascript
// Source: accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs
if (row.coverage_status !== "covered") {
  gaps.push(row);
}
```

This is the place where score-floor enforcement is missing today. [VERIFIED: codebase grep]

### Existing Independent Ledger Verification Pattern

```javascript
// Source: scripts/ci/verify_ratchet_ledger.mjs
if (currentCount > baselineCount) {
  regressions.push({ key, baselineCount, currentCount });
}
```

This per-key count comparison is the right primitive for synthetic count-increase and persona/lens regression fixtures. [VERIFIED: codebase grep]

### Phase 200 Sign-Off Verifier Pattern

```javascript
// Source: scripts/ci/verify_phase200_signoff.mjs
const matches = [...content.matchAll(/^Final maintainer decision: (ACCEPT|REJECT)\b.*$/gm)];
if (matches.length !== 1) {
  errors.push("Expected exactly one final maintainer decision line.");
}
```

Phase 208 should duplicate the pattern with ratchet-specific sections and the UI-SPEC final-line format. [VERIFIED: codebase grep]

### GitHub Actions Non-Advisory Gate

```yaml
# Source: GitHub Actions workflow syntax documentation
continue-on-error: false
```

GitHub documents that `continue-on-error: true` lets a job fail without failing the workflow run, so the ratchet guardrail job should not use advisory semantics. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual one-off UI review | Round/fix ratchet loop with ledger, digest, guard minting, and deterministic verification | Phase 207 | Phase 208 can focus on convergence proof and acceptance instead of inventing orchestration. [VERIFIED: 207-SUMMARY files] |
| Generic placeholder baseline | Explicit non-placeholder frozen baseline | Phase 208 locked decision | Acceptance must prove that the baseline came from real representative-slice evidence. [VERIFIED: 208-CONTEXT.md] |
| LLM checks as possible CI behavior | Deterministic-only CI job without API key | Phase 208 locked decision | PR gating must rely on committed artifacts, recompute, and fixtures only. [VERIFIED: 208-CONTEXT.md] |
| Full admin sweep pressure | Representative foundation slice first | Phase 208 locked decision | Full-surface graduation remains a follow-on runbook activity. [VERIFIED: 208-CONTEXT.md] |
| Color/visual status | Closed text status tokens | Phase 208 UI-SPEC | Status evidence can be validated and is not color-dependent. [VERIFIED: 208-UI-SPEC.md] |

**Deprecated/outdated:**

- Treating `coverage_status == "covered"` as sufficient for Phase 208 convergence is outdated because D-58 and CONV-01 require `score >= 2`. [VERIFIED: 208-CONTEXT.md]
- Treating `npm run ratchet:ledger` as a CI-ready command is outdated once a frozen baseline exists because its current first command can mutate ratchet artifacts. [VERIFIED: codebase grep]
- Treating the existing all-zero baseline as acceptable is outdated because D-61 rejects placeholder baselines. [VERIFIED: 208-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| n/a | No unverified assumptions are required for the planning-critical findings in this research. | All | n/a |

## Open Questions

1. **How should `component-kitchen` map to Phase 200 census surfaces for score-floor enforcement?**
   - What we know: The capture slice includes `component-kitchen`, while Phase 200 cell rows use surface names that can be individual component families. [VERIFIED: codebase grep]
   - What's unclear: The exact authoritative mapping for all design-system foundation cells is not encoded as a dedicated Phase 208 helper yet. [VERIFIED: codebase grep]
   - Recommendation: Plan a small helper and fixture that expands `component-kitchen` to the intended component-family census set, then fails if no rows are examined. [VERIFIED: codebase grep]

2. **What is the definitive non-placeholder proof when final open count is truly zero?**
   - What we know: D-61 rejects an all-zero empty-file baseline, but a genuinely converged slice may have zero open findings. [VERIFIED: 208-CONTEXT.md]
   - What's unclear: Whether the baseline file itself should gain explicit evidence metadata or whether sign-off evidence plus `rounds.ndjson` is sufficient. [VERIFIED: 208-CONTEXT.md]
   - Recommendation: Prefer a verifier-visible proof using frozen baseline hash, two dry foundation rounds, real bundle hash, non-empty round evidence, and non-empty resolved/locked or explicit convergence metadata. [VERIFIED: 208-CONTEXT.md]

3. **Should the CI job itself prove existing UI gates are green, or only verify that those independent jobs are wired and referenced?**
   - What we know: D-62 says the new ratchet job should remain Node-only unless a concrete verifier requires BEAM/Postgres/browser, and CONV-05 requires existing gates remain green. [VERIFIED: 208-CONTEXT.md]
   - What's unclear: Whether sign-off evidence should cite workflow run artifacts manually or whether CI should inspect current workflow job status. [VERIFIED: 208-CONTEXT.md]
   - Recommendation: Keep the new job Node-only, verify workflow wiring and sign-off evidence, and leave actual BEAM/browser work to the existing jobs. [VERIFIED: codebase grep]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Node.js | Deterministic scripts and CI parity | yes | v22.14.0 | GitHub Actions `setup-node` can install Node 22. [VERIFIED: environment probe] |
| npm | Ratchet package scripts | yes | 11.1.0 | Use direct `node` commands if npm script indirection is unsafe. [VERIFIED: environment probe] |
| Elixir | Local `ui.round`/`ui.fix` and task tests | yes | 1.19.5 | No fallback for local convergence; deterministic CI should avoid needing Elixir. [VERIFIED: environment probe] |
| Mix | Local task tests | yes | 1.19.5 | No fallback for Mix task tests. [VERIFIED: environment probe] |
| Playwright CLI | Local visual capture | yes | 1.59.1 | No fallback for local convergence capture; deterministic CI must not run capture. [VERIFIED: environment probe] |
| Git | Static asset freshness and commit-scoped checks | yes | 2.41.0 | No fallback for diff-based freshness. [VERIFIED: environment probe] |
| `ANTHROPIC_API_KEY` | Local live proposer/verifier only | not required for deterministic CI | n/a | Skip LLM proposer/verifier in CI. [VERIFIED: 208-CONTEXT.md] |

**Missing dependencies with no fallback:**

- None for deterministic Phase 208 CI research. [VERIFIED: environment probe]

**Missing dependencies with fallback:**

- `ANTHROPIC_API_KEY` may be absent in CI by design; deterministic guardrails rely on committed artifacts and fixture proofs. [VERIFIED: 208-CONTEXT.md]

## Validation Architecture

Nyquist validation is enabled in `.planning/config.json`, so planning must include automated validation tasks. [VERIFIED: codebase grep]

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Node script self-tests, ExUnit/Mix task tests, GitHub Actions workflow contract scripts. [VERIFIED: codebase grep] |
| Config file | `accrue_admin/package.json`, `accrue_admin/mix.exs`, `.github/workflows/ci.yml`. [VERIFIED: codebase grep] |
| Quick run command | `cd accrue_admin && npm run ratchet:ledger:self-test && npm run ratchet:digest:self-test && node e2e/ratchet/ratchet-fix.mjs --self-test && node e2e/ratchet/ratchet-guard-mint.mjs --self-test` [VERIFIED: command run] |
| Full suite command | `cd accrue_admin && mix test test/mix/tasks/accrue_admin_ui_round_test.exs test/mix/tasks/accrue_admin_ui_fix_test.exs` plus existing UI guardrail commands when Phase 208 implementation touches workflow/assets. [VERIFIED: command run] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| CONV-01 | Foundation slice has two dry rounds, zero regressions, and all scoped cells score >= 2. | unit/integration plus local manual convergence | New score-floor verifier command and `mix accrue_admin.ui.round --slice foundation` for real convergence. [VERIFIED: codebase grep] | Partial; score-floor verifier is a Wave 0 gap. [VERIFIED: codebase grep] |
| CONV-02 | Baseline is frozen and non-placeholder. | unit/self-test | New `verify_ratchet_ledger.mjs --verify-frozen` or wrapper fixture. [VERIFIED: 208-CONTEXT.md] | Missing; Wave 0 gap. [VERIFIED: codebase grep] |
| CONV-03 | CI passes without key and blocks synthetic count increase. | unit/CI contract | `npm run ratchet:ledger:self-test` plus new CI contract script. [VERIFIED: command run] | Partial; CI job/contract missing. [VERIFIED: codebase grep] |
| CONV-04 | Persona/lens regression fails even if another lens improves. | unit/self-test | New scratch fixture in ledger verifier self-test. [VERIFIED: 208-CONTEXT.md] | Missing; Wave 0 gap. [VERIFIED: codebase grep] |
| CONV-05 | Existing gates green and CSS bundle fresh. | CI/smoke | Existing Phase 192/200 guardrails and asset diff workflow commands. [VERIFIED: codebase grep] | Exists, but Phase 208 sign-off evidence missing. [VERIFIED: codebase grep] |
| CONV-06 | Maintainer ACCEPT line enforced. | unit/self-test | `node scripts/ci/verify_ui_ratchet_signoff.mjs --require-accept` after implementation. [VERIFIED: 208-UI-SPEC.md] | Missing; Wave 0 gap. [VERIFIED: codebase grep] |
| CONV-07 | Follow-on runbook headings and bounded language enforced. | unit/self-test | `node scripts/ci/verify_ui_ratchet_signoff.mjs --require-accept` after implementation. [VERIFIED: 208-UI-SPEC.md] | Missing; Wave 0 gap. [VERIFIED: codebase grep] |

### Sampling Rate

- **Per task commit:** Run the Node ratchet self-tests affected by the task. [VERIFIED: codebase grep]
- **Per wave merge:** Run ledger/digest/fix/guard-mint self-tests plus Mix task tests for round/fix orchestration. [VERIFIED: command run]
- **Phase gate:** Run deterministic CI contract, sign-off verifier, read-only frozen ledger verifier, existing UI guardrails, and asset freshness before `$gsd-verify-work`. [VERIFIED: 208-CONTEXT.md]

### Wave 0 Gaps

- [ ] `scripts/ci/verify_ui_ratchet_signoff.mjs` with fixtures for missing sections, invalid statuses, missing/duplicate ACCEPT, placeholder baseline, non-empty regressions, missing runbook headings, forbidden full-sweep language, and invalid refs. [VERIFIED: 208-CONTEXT.md]
- [ ] `scripts/ci/verify_admin_ui_ratchet_ci_contract.sh` to enforce job id/name, no-key/no-secret/no-mutating-command constraints, artifacts/summaries, and annotation-sweep wiring. [VERIFIED: 208-CONTEXT.md]
- [ ] Read-only frozen-baseline verification mode or wrapper around `verify_ratchet_ledger.mjs`. [VERIFIED: 208-CONTEXT.md]
- [ ] Score-floor enforcement helper that maps representative slice surfaces to Phase 200 cell census rows and requires `score >= 2`. [VERIFIED: codebase grep]
- [ ] Scratch fixture tests for synthetic count increase and cross-persona/lens regression. [VERIFIED: 208-CONTEXT.md]
- [ ] `UI-RATCHET-SIGN-OFF.md` with UI-SPEC sections, evidence rows, runbook headings, and final maintainer `ACCEPT` line. [VERIFIED: 208-UI-SPEC.md]

### Validation Already Run During Research

- `cd accrue_admin && npm run ratchet:ledger:self-test` passed. [VERIFIED: command run]
- `cd accrue_admin && npm run ratchet:digest:self-test` passed. [VERIFIED: command run]
- `cd accrue_admin && node e2e/ratchet/ratchet-fix.mjs --self-test && node e2e/ratchet/ratchet-guard-mint.mjs --self-test` passed. [VERIFIED: command run]
- `cd accrue_admin && mix test test/mix/tasks/accrue_admin_ui_round_test.exs test/mix/tasks/accrue_admin_ui_fix_test.exs` passed with 16 tests and 0 failures. [VERIFIED: command run]

## Security Domain

Security enforcement is enabled because `.planning/config.json` does not set `security_enforcement` to `false`. [VERIFIED: codebase grep]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | Phase 208 does not change runtime login behavior. [VERIFIED: 208-CONTEXT.md] |
| V3 Session Management | no | Phase 208 does not change admin session handling. [VERIFIED: 208-CONTEXT.md] |
| V4 Access Control | limited | CI must preserve existing guardrails and avoid widening workflow permissions; no new app runtime access path is introduced. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Verifiers must validate NDJSON, JSON baseline shape, Markdown sections/status tokens, workflow text contracts, and artifact references. [VERIFIED: 208-CONTEXT.md] |
| V6 Cryptography | limited | Existing SHA-256 hashes are integrity fingerprints, not authentication or secret storage; do not invent custom crypto. [VERIFIED: codebase grep] |

### Known Threat Patterns for Ratchet CI/Artifacts

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Baseline tampering hides new open findings | Tampering | Independent read-only recompute against committed ledger and exact per-key counts. [VERIFIED: codebase grep] |
| CI secret exposure through accidental LLM job wiring | Information Disclosure | Contract verifier rejects `secrets.`, `ANTHROPIC_API_KEY`, `ratchet-propose`, `ratchet-verify`, `ui.round`, and `ui.fix` in the deterministic job. [VERIFIED: 208-CONTEXT.md] |
| Advisory job fails but PR still passes | Elevation of Privilege / Tampering | Do not use `continue-on-error: true`; GitHub documents that it lets jobs fail without failing workflow runs. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax] |
| Malformed sign-off artifact claims acceptance | Repudiation | Enforce required sections, allowed status tokens, exactly one final ACCEPT line, artifact existence, and verifier self-tests. [VERIFIED: 208-UI-SPEC.md] |
| Digest/sign-off status is not perceivable | Accessibility / UX integrity | Use text status tokens and status-message semantics where HTML status output is generated. [CITED: https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html] |
| Artifact reference escapes expected workspace | Tampering | Sign-off verifier should reject invalid refs and keep references inside expected project artifact paths. [VERIFIED: 208-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/208-prove-convergence-on-the-representative-slice-wire-ci-accept/208-CONTEXT.md` - locked implementation decisions, discretion areas, and deferred ideas. [VERIFIED: codebase grep]
- `.planning/phases/208-prove-convergence-on-the-representative-slice-wire-ci-accept/208-UI-SPEC.md` - sign-off sections, final ACCEPT line, status tokens, CI copy, and runbook headings. [VERIFIED: codebase grep]
- `.planning/REQUIREMENTS.md` - CONV-01 through CONV-07 requirement text. [VERIFIED: codebase grep]
- `.planning/ROADMAP.md` and `.planning/STATE.md` - Phase 208 scope and dependency status. [VERIFIED: codebase grep]
- Phase 207 context, research, patterns, plans, and summaries - existing round/fix/digest/guard-mint orchestration. [VERIFIED: codebase grep]
- `accrue_admin/e2e/ratchet/*`, `scripts/ci/*`, `accrue_admin/package.json`, and `.github/workflows/ci.yml` - current implementation surface. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)

- GitHub Actions workflow syntax - `continue-on-error`, job failure semantics, and workflow syntax. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax]
- W3C WCAG 2.2 Status Messages understanding document - status message semantics. [CITED: https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html]
- W3C WCAG 2.1 Use of Color understanding document - color cannot be sole information channel. [CITED: https://www.w3.org/WAI/WCAG21/Understanding/use-of-color.html]
- AWS Incident Manager runbooks documentation - runbook as workflow of actions for operational response. [CITED: https://docs.aws.amazon.com/incident-manager/latest/userguide/runbooks.html]
- PHPStan baseline documentation - baseline records current violations so new violations surface. [CITED: https://phpstan.org/user-guide/baseline]

### Tertiary (LOW confidence)

- None used for planning-critical recommendations. [VERIFIED: codebase grep]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - based on local `package.json`, existing scripts, workflow files, and local version probes. [VERIFIED: codebase grep]
- Architecture: HIGH - based on Phase 207 completed summaries and current ratchet script implementation. [VERIFIED: codebase grep]
- Pitfalls: HIGH - based on direct inspection of current reducer, baseline, workflow, package scripts, and locked Phase 208 decisions. [VERIFIED: codebase grep]
- External documentation: MEDIUM - official docs were fetched through web search and used only for CI/status/runbook/baseline framing. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax]

**Research date:** 2026-07-07
**Valid until:** 2026-08-06 for local codebase findings; re-check GitHub Actions docs and local dependency versions if CI syntax or dependency versions change before implementation. [VERIFIED: codebase grep]
