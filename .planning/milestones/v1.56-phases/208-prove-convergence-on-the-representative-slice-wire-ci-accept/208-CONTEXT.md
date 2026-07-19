# Phase 208: prove-convergence-on-the-representative-slice-wire-ci-accept - Context

**Gathered:** 2026-07-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 208 turns the already-built admin UI ratchet into maintainer-accepted
evidence. It proves the `foundation` representative slice converges end to
end, freezes the first non-empty high-water ledger baseline, wires a
deterministic CI sibling gate, proves the gate fails for the two required
regression fixtures, keeps the existing UI guardrails green, and lands the
maintainer `ACCEPT` artifact plus a bounded follow-on runbook.

Requirements: **CONV-01, CONV-02, CONV-03, CONV-04, CONV-05, CONV-06,
CONV-07**.

**In scope:**
- Run `mix accrue_admin.ui.round --slice foundation` through `CONVERGED (2 dry rounds)`.
- Prove the slice is exactly `SLICES.foundation`: `component-kitchen`, `dashboard`,
  `subscription-detail`, and `subscriptions`.
- Freeze `accrue_admin/e2e/ratchet/ledger.baseline.json` explicitly with
  `phase-ratchet-ledger.mjs --freeze`, after the preflight proves the baseline
  is non-empty and freeze-eligible.
- Add `admin-ui-ratchet-guardrails` as a deterministic, key-free CI job.
- Prove synthetic `count-increase` and cross-persona/lens regression failures.
- Keep `admin-hardening-guardrails`, `admin-phase200-guardrails`, and asset drift green.
- Create `UI-RATCHET-SIGN-OFF.md` with exactly one final maintainer decision line
  beginning `Final maintainer decision: ACCEPT`.
- Include a follow-on runbook that graduates additional surfaces as bounded
  surface/slice runs, not as a Phase 208 full-surface mandate.

**Out of scope:**
- LLM in CI or any CI dependency on `ANTHROPIC_API_KEY`.
- Running the live evaluator/verifier or `ui.round`/`ui.fix` in the deterministic
  CI job.
- Freezing from a generic guardrail command or from CI.
- Full-surface convergence before v1.56 sign-off. That remains Phase 209 /
  SWEEP-01, optional and scope-gated.
- New billing primitives, public API/route changes, Tailwind/shadcn migration,
  `accrue_portal` work, or adopter-runtime ratchet code.

</domain>

<spec_lock>
## UI Design Contract (locked via UI-SPEC.md)

`208-UI-SPEC.md` is approved and locks the maintainer-facing evidence surfaces
for this phase. It creates no new adopter/operator admin screen; the user-facing
surfaces are Markdown evidence, runbook text, CI status copy, terminal readbacks,
and the already-built Phase 207 digest governed by `207-UI-SPEC.md`.

Downstream agents MUST read `208-UI-SPEC.md` before planning or implementing.
This context does not duplicate its section order, closed status vocabulary, copy
contract, typography/color rules, or final ACCEPT-line format.

**In scope from UI-SPEC:**
- `UI-RATCHET-SIGN-OFF.md` with required sections in locked order.
- Embedded or linked runbook with required headings.
- Deterministic-only `admin-ui-ratchet-guardrails` CI/terminal copy.
- Any incidental admin UI fixes must stay inside the existing `ax-*` token and
  component system.

**Out of scope from UI-SPEC:**
- New browser approve/reject controls.
- Tailwind, shadcn, external registries, or new runtime dependencies.
- Reopening the Phase 207 digest visual contract except to verify convergence.

</spec_lock>

<decisions>
## Implementation Decisions

All three gray areas were researched with parallel advisor subagents and checked
against local prompts, brandbook guidance, current ratchet code, Phase 200/206/207
precedents, and external baseline/CI/runbook/accessibility references. The
recommendations are coherent: evidence is structured first, Markdown summarizes it,
CI is deterministic and non-mutating, and maintainer ACCEPT is a proof line backed
by verifiers.

Decision IDs continue from Phase 207 (D-42..D-57). These are **D-58..D-70**,
binding for planning.

### Evidence depth and freeze bar (CONV-01, CONV-02, CONV-05, CONV-06)
- **D-58 - Freeze requires a Phase-200-style evidence bundle, not reducer-only convergence.**
  `CONVERGED (2 dry rounds)` is necessary but insufficient. The freeze preflight
  must prove: two committed dry `rounds.ndjson` rows for `scope=foundation`; zero
  folded `open` findings; `accrue_admin/e2e/ratchet/finding-regressions.ndjson`
  is 0 bytes; Phase 200 `regressions.ndjson` is 0 bytes; every in-scope
  foundation-slice cell is `coverage_status == "covered"` and has `score >= 2`;
  `ledger.baseline.json` is non-empty and will become `frozen: true`; the
  independent verifier is green; existing UI guardrails and asset drift are green;
  and the sign-off verifier sees exactly one ACCEPT line. This mirrors the
  project's Phase 200 closeout posture: structured artifacts are the evidence,
  Markdown is the maintainer-readable summary.
- **D-59 - Close the score-floor gap before freeze.** Current reducer dry clause
  checks coverage status but appears not to enforce the `score >= 2` floor itself.
  Planner must either tighten `phase-ratchet-ledger.mjs` coverage-floor logic or
  add a dedicated freeze/sign-off verifier check over the Phase 200 cell census.
  Do not allow `CONVERGED` to authorize freeze if a foundation cell is covered but
  scored below 2.
- **D-60 - Freeze is an explicit local act; CI never freezes and generic guardrails never hide it.**
  The frozen baseline is written only by an explicit command path equivalent to:
  `cd accrue_admin && node e2e/ratchet/phase-ratchet-ledger.mjs --freeze` after
  the preflight passes. Do not place `--freeze` in `npm run ratchet:ledger`,
  `admin-ui-ratchet-guardrails`, `phase200:guardrails`, or a broad guardrail
  runner. This keeps the baseline movement review-visible and follows the
  plan/apply discipline already chosen for `ui.round`/`ui.fix`.
- **D-61 - Freeze must be non-empty by real resolved/locked evidence, not an all-zero placeholder.**
  Phase 208 should not accept a frozen `ledger.baseline.json` whose
  `ledger_sha256` is the empty-file hash with all `confirmed_open` totals at 0 and
  no `resolved_locked` entries. If the representative slice genuinely has no
  remaining findings, the baseline still needs evidence from the converged rounds,
  cell floor, regression files, and freeze metadata. If the code's current
  baseline shape cannot distinguish "empty because no proof ran" from "empty
  because proof converged," the sign-off verifier must catch that via rounds,
  scope, bundle hash, and evidence artifact checks.

### Deterministic CI gate (CONV-03, CONV-04, CONV-05)
- **D-62 - Add a dedicated Node-only `admin-ui-ratchet-guardrails` job.**
  The new CI job is a fast deterministic baseline gate, not a live evaluator run.
  It should install only the Node dependencies needed for the ratchet scripts,
  run with `ANTHROPIC_API_KEY` unset, and avoid BEAM/Postgres/browser setup unless
  a future implementation proves the existing Phase 192/200 jobs no longer execute
  minted guard-home specs. Keep existing `admin-hardening-guardrails`,
  `admin-phase200-guardrails`, and asset-drift checks independent rather than
  making ratchet CI depend on them.
- **D-63 - CI is non-mutating against the frozen baseline.** The job must not
  regenerate or overwrite `ledger.baseline.json`. Planner should add a
  non-mutating verify mode or a CI wrapper that computes regressions/verifier
  results without writing a frozen baseline. CI may run self-tests and scratch
  fixtures; it must not run `--freeze`.
- **D-64 - CI contract script is required and should grep the job boundary.**
  Add a script in the Phase 192/200 style, e.g.
  `scripts/ci/verify_admin_ui_ratchet_ci_contract.sh`, that requires the stable
  job id `admin-ui-ratchet-guardrails`, display name `Admin UI ratchet guardrails`,
  deterministic self-tests, independent verifier invocation, artifact uploads or
  summaries if present, and annotation-sweep inclusion. It must reject
  `secrets.`, `ANTHROPIC_API_KEY`, `ratchet-propose`, `ratchet-verify`,
  `ui.round`, `ui.fix`, browser Playwright capture, and `--freeze` in that job.
- **D-65 - Failure proofs live in scratch fixtures and must cover both required red paths.**
  Implement deterministic self-test fixtures that prove: (1) a synthetic ledger
  count increase makes the gate red; (2) a per-lens persona regression makes the
  gate red even if another persona/lens improved. The second proof must preserve
  the Phase 206 per-lens model: e.g. `persona:operator-founder` total falls while
  `persona:customer-support` total rises above baseline, and the job fails because
  any single lens count increase is enough.
- **D-66 - CI readback copy is exact but not decorative.** Required visible copy
  comes from `208-UI-SPEC.md`: no-key proof, 0-byte finding regressions,
  independent recompute match, synthetic count-increase proof, persona regression
  proof, existing UI gates, and bundle freshness. Use PASS/BLOCKED/PENDING/N/A as
  status words. A GitHub step summary is useful as a mirror, but committed files
  and verifier output remain canonical.

### Sign-off artifact and follow-on runbook (CONV-06, CONV-07)
- **D-67 - Structured evidence feeds one committed `UI-RATCHET-SIGN-OFF.md`.**
  Use a generated or verifier-read structured evidence package as the source of
  truth, then produce one Markdown sign-off artifact in the Phase 208 directory.
  Keep the runbook embedded under `## Follow-On Runbook` unless implementation
  pressure demands a linked file. If split later, `UI-RATCHET-SIGN-OFF.md` remains
  the sole decision surface and must verify the link and evidence agreement.
- **D-68 - Add a Phase-200-style sign-off verifier.** Implement a deterministic
  verifier, e.g. `scripts/ci/verify_ui_ratchet_signoff.mjs`, with fixture self-tests.
  It must fail on missing required sections, non-closed status values, missing
  foundation slice evidence, missing or duplicate final decision lines, missing
  exact ACCEPT prefix, non-empty regression files, unfrozen or all-zero/placeholder
  baseline, stale/missing runbook headings, missing synthetic failure proofs,
  missing existing-gate evidence, broad "run everything now" sweep language, and
  invalid evidence refs. CI should run it with `--require-accept` once Phase 208 is
  ready for final sign-off.
- **D-69 - The runbook is an executable maintainer procedure, not a narrative recap.**
  It must name `SLICES.foundation` as the proven slice, give exact commands, name
  expected artifacts and status values, and include recovery paths for non-empty
  `finding-regressions.ndjson`, non-empty Phase 200 `regressions.ndjson`, failed
  independent verifier, stale CSS bundle, cap reached, and sign-off missing. It
  should graduate another surface by selecting one bounded surface/slice, running
  the same round/fix/freeze pattern, and reviewing diffs. It must not turn Phase
  209 into an implicit full-surface requirement.
- **D-70 - Voice, UX, and accessibility follow brandbook + UI-SPEC, even in Markdown/CI text.**
  Use measured, exact, Phoenix-native copy: name artifacts, commands, and evidence
  mechanisms rather than adjectives. Keep status visible as text, never color
  alone. Use monospace for commands, paths, job ids, `finding_id`, `claim_key`,
  `ledger_sha256`, and status constants. Error copy states the fact and the next
  command/artifact to inspect. The sign-off is for a maintainer persona whose job
  is "can I accept this baseline and know what to run next?", not for an adopter
  operator persona.

### Claude's Discretion
- Exact structured evidence filename and schema shape are planner discretion, but
  keep it small, deterministic, and generated/verifiable without new dependencies.
- Whether the non-mutating CI path is a new `--check-frozen` flag, a separate script,
  or a wrapper around existing exported functions is planner discretion; it must
  not mutate frozen files.
- Exact GitHub artifact names and step-summary formatting are planner discretion,
  provided committed evidence and verifier output remain canonical.
- The full-surface graduation runbook can start with one named surface example
  (`dashboard` or `subscription-detail`) if that makes the procedure clearer, but
  it must describe the general bounded-surface pattern.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Locked phase scope and UI contract
- `.planning/ROADMAP.md` - Phase 208 goal and success criteria; Phase 209 scope gate.
- `.planning/REQUIREMENTS.md` - CONV-01..CONV-07 plus out-of-scope rules.
- `.planning/phases/208-prove-convergence-on-the-representative-slice-wire-ci-accept/208-UI-SPEC.md` - locked sign-off, runbook, CI status, copy, color, typography, and registry-safety contract.

### Upstream decisions (do not re-litigate)
- `.planning/phases/207-orchestration-digest-one-command-round-fix-loop/207-CONTEXT.md` - D-47..D-52 round state, dry detection, two-command loop, slice filter; D-53..D-57 digest and cache decisions.
- `.planning/phases/206-adversarial-verifier-finding-ledger-deterministic-gate/206-CONTEXT.md` - D-24..D-27 per-lens baseline; D-35..D-41 ledger write boundary, freeze seam, guard refs, reopen markers.
- `.planning/phases/205-persona-design-lens-evaluator-harness/205-CONTEXT.md` - D-01 claim key, D-09 bbox sidecars, D-12 cell refs, D-13 severity, D-16 token gate, D-17 candidate schema, D-21 density defender.

### Current ratchet and CI code seams
- `accrue_admin/e2e/baseline-manifest.js` - `SLICES.foundation` single source of truth.
- `accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs` - reducer, `--freeze`, dry-round logic, 0-byte regression writer.
- `scripts/ci/verify_ratchet_ledger.mjs` - independent deterministic verifier and self-test fixture style.
- `accrue_admin/e2e/ratchet/ratchet-ledger.js` - append/fold helpers and `LENS_KEYS`.
- `accrue_admin/e2e/ratchet/rounds.ndjson` - committed dry-round evidence log.
- `accrue_admin/e2e/ratchet/ledger.baseline.json` - baseline to freeze.
- `accrue_admin/e2e/ratchet/finding-regressions.ndjson` - 0-byte finding regression contract.
- `.planning/milestones/v1.54-phases/200-idempotent-verification-sign-off/regressions.ndjson` - standing Phase 200 scorecard regression contract.
- `accrue_admin/package.json` - ratchet npm scripts and Phase 200 guardrail script precedent.
- `.github/workflows/ci.yml` - existing job ids, Phase 192/200 jobs, annotation sweep.
- `scripts/ci/verify_phase200_ci_contract.sh` and `scripts/ci/verify_phase200_guardrail_contract.sh` - CI contract-script patterns to twin.
- `scripts/ci/verify_phase200_signoff.mjs` - sign-off verifier structure, fixture self-tests, ACCEPT-line checks.
- `scripts/ci/verify_phase200_admin_guardrails.sh` - existing local deterministic guardrail runner.

### Local product, brand, and prompt guidance
- `brandbook/voice.md` - measured, exact, native, durable voice; proof-led claims; banned vague adjectives.
- `brandbook/README.md` - current brand source; supersedes older prompt-era brand material when conflicts exist.
- `brandbook/copy.md` - error and status microcopy posture.
- `prompts/accrue-library-summary-for-admin-ux-deep-research.md` - admin is an operator control plane; exact domain language; dense developer tooling, not fintech.
- `prompts/accrue_admin_operator_ui_journey_blueprint.md` - maintainer/operator UX principles: exceptions first, summary before drilldown, exact actions, WCAG-oriented status/copy.
- `prompts/GSD-REPO-HYGIENE.md` - green CI, explicit release/no-release decision, exact final-state reporting.
- `prompts/MILESTONE-NEXT-STEP-ASSESSMENT.md` - adopter/proof posture and repo-local truth first.

### External research references used for rationale
- `https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax` - GitHub Actions job failure semantics and `continue-on-error` behavior.
- `https://phpstan.org/user-guide/baseline` - baseline pattern: keep old known issues from hiding new violations; baseline is not a substitute for fixing an enormous problem set.
- `https://mix.hexdocs.pm/Mix.html` - Mix aliases and command/task composition idioms.
- `https://sre.google/sre-book/evolving-sre-engagement-model/` - production readiness evidence, training, and service-specific checklists.
- `https://gitlab-org.gitlab.io/release/docs/runbooks/incident/` - runbook as action reference manual.
- `https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html` - status messages should inform without unnecessary interruption.
- `https://www.w3.org/WAI/WCAG21/Understanding/use-of-color.html` - status must not depend on color alone.
- `https://docs.rundeck.com/docs/` - runbook automation docs as an action/procedure reference model.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `phase-ratchet-ledger.mjs`: already owns `--freeze`, regression computation,
  dry-round sealing, and baseline regeneration. Extend/check here only if it
  keeps the deterministic plane pure.
- `verify_ratchet_ledger.mjs`: already independently recomputes counts, checks
  guard refs, and self-tests scratch fixtures. It is the closest pattern for the
  new non-mutating CI verifier/proof fixtures.
- `verify_phase200_signoff.mjs`: best local template for parsing Markdown,
  checking exact final decision lines, validating evidence refs, and self-testing
  ACCEPT/REJECT behavior.
- Phase 192/200 shell contract scripts: best pattern for grepping workflow job
  boundaries and preventing accidental browser/LLM/secret creep in the ratchet CI job.
- `baseline-manifest.js`: `SLICES.foundation` is already present and should stay
  the single source of truth.

### Established Patterns
- **Deterministic plane stays SDK-free and network-free.** CI reads committed
  artifacts and scratch fixtures; it never calls the LLM.
- **Structured evidence before prose.** Markdown is a maintainer-readable summary
  of files the verifier can inspect.
- **Explicit baseline movement.** Frozen baseline updates are human-visible local
  actions, not side effects of ordinary CI or guardrail aliases.
- **Contract scripts protect workflow shape.** The project already guards Phase
  192/200 CI jobs by grepping stable YAML boundaries; Phase 208 should do the same.
- **Exact status vocabulary.** PASS/BLOCKED/PENDING/N/A are text states, not color
  affordances.

### Integration Points
- `.github/workflows/ci.yml`: add job id `admin-ui-ratchet-guardrails`; add it
  to the top job-id contract comment and annotation sweep.
- `scripts/ci/verify_admin_ui_ratchet_ci_contract.sh`: new contract checker.
- `scripts/ci/verify_ui_ratchet_signoff.mjs`: new sign-off verifier.
- `accrue_admin/package.json`: likely add `ratchet:signoff` or
  `ratchet:signoff:self-test` scripts, plus a non-mutating frozen-check script if
  the implementation exposes one through npm.
- `phase-ratchet-ledger.mjs` / `verify_ratchet_ledger.mjs`: add score floor or
  verify-only support only if needed to satisfy D-59/D-63.
- `UI-RATCHET-SIGN-OFF.md`: new committed evidence surface in the Phase 208 dir.

</code_context>

<specifics>
## Specific Ideas

- Recommended happy-path commands should read like:
  1. `mix accrue_admin.ui.round --slice foundation`
  2. Repeat `mix accrue_admin.ui.fix` / `mix accrue_admin.ui.round --slice foundation`
     until the digest reports `CONVERGED (2 dry rounds)`.
  3. Run local freeze preflight.
  4. Run the explicit `--freeze` command.
  5. Run deterministic ratchet guardrails and existing UI guardrails.
  6. Generate/verify `UI-RATCHET-SIGN-OFF.md`.
- Required status copy should stay close to UI-SPEC:
  `PASS - deterministic ratchet guardrails are clean`,
  `BLOCKED - finding-regressions.ndjson is not empty`,
  `PENDING - maintainer ACCEPT line is not present`.
- `GITHUB_STEP_SUMMARY` is useful for PR scanning but is not durable evidence.
  The committed sign-off and verifier output are canonical.
- Use "foundation slice" or `SLICES.foundation`; avoid vague "representative set"
  where exact slice membership matters.
- Preserve the `ui.round` / `ui.fix` plan/apply split. The runbook should not
  suggest a one-command "fix everything and freeze" path.

</specifics>

<deferred>
## Deferred Ideas

- **Full ~19-surface sweep** - stays Phase 209 / SWEEP-01, optional and
  scope-gated. The Phase 208 runbook tees it up as bounded surface/slice
  graduation, not as a v1.56 acceptance requirement.
- **Pixel-diff service / visual-baseline SaaS** - remains TOOL-02/future work.
  It may become useful for a later full visual-regression layer, but it is out of
  scope for this deterministic finding-ledger ratchet proof.
- **Advisory LLM in CI** - remains deferred. Phase 208 CI is deterministic only.

No todos matched Phase 208, and no additional scope was folded in.

</deferred>

---

*Phase: 208-prove-convergence-on-the-representative-slice-wire-ci-accept*
*Context gathered: 2026-07-07*
