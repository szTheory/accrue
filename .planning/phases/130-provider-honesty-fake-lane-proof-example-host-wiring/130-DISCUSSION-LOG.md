# Phase 130 — Discussion Log

**Date:** 2026-05-25
**Mode:** Advisor / cohesive-one-shot-synthesis (calibration tier `minimal_decisive`; `opinionated` vendor philosophy). `NON_TECHNICAL_OWNER = false` (`technical_background: true` overrides inferred signals → technical framing kept).

> Human-reference record only. Not consumed by downstream agents — see `130-CONTEXT.md` for the canonical, agent-facing decisions.

## How this ran

Per `config.json` (`discuss_auto_all_gray_areas`, `discuss_high_impact_confirm`, `discuss_auto_resolve_low_impact`, bar `discuss_high_impact_confirm_bar`) and memory `feedback_decision_synthesis_style`, all gray areas were auto-selected and resolved into one coherent default package. Phase 130 was found **unusually pre-resolved** — Phase 125 is a near-exact drift-gate template, the `dunning-depth-milestone-prep` thread pre-resolved the provider-honesty framing, Phases 128/129 locked the engine + observability contracts, and `config.json` carries a `discuss_default_dunning_phase_boundary` key. Because every gray area auto-resolved against established precedent (none crossed the confirm bar), fresh parallel advisor agents would have re-derived known answers; the package was synthesized directly from the pre-resolved research + a codebase scout (re-verified `file:line` anchors). **Zero forks surfaced** — consistent with how Phases 125/128/129 ran.

## Gray areas considered (all auto-resolved)

### 1. Provider-honest docs home + structure (SC#1)
- **Options:** new `guides/dunning.md` vs extend `lifecycle_semantics.md`.
- **Resolved:** new `guides/dunning.md` (auto-discovered by ExDoc wildcard), cross-referencing the lifecycle SSOT's `past_due` section. Per-provider story = campaign is provider-independent (convergent), smart-retry alignment diverges (Stripe Smart Retries + Test Clocks; Braintree clock-only NOT retry-aligned; Fake proof lane). Over-email warning carried from Phase 128 D-03. → CONTEXT D-01..D-04.
- **Rationale:** internal file-org, reversible; dunning surface large enough for its own guide; lifecycle truth stays in the lifecycle SSOT.

### 2. Merge-blocking drift gate — shape + home (SC#2)
- **Options:** EXTEND the Phase-125 processor support-contract triplet (capabilities + `.planning/` matrix + `verify_processor_support_matrix.sh`) vs a dedicated `verify_dunning_docs.sh`.
- **Resolved:** extend the existing triplet; one convergence row (`dunning.campaign` → local-identical) + one divergence row (`dunning.smart_retry_alignment` → native/unsupported/testing); negative convergence guard; lightly pin the public `guides/dunning.md` labels too (the public guide is this phase's deliverable, unlike Phase 125); code-side label mirror in the Fake-lane proof. → CONTEXT D-05..D-09.
- **Rationale:** honors the locked `processor_support_matrix_public_ssot_capabilities_code_mirror_same_pr_co_update` rule; rides the existing merge-blocking CI job (no new step); reversible.

### 3. Deterministic Fake-lane full-journey proof (SC#3)
- **Options:** drive through the real `Accrue.Webhook.DefaultHandler` entry point vs enqueue `DunningStep` directly (unit-level).
- **Resolved:** drive `invoice.payment_failed` + `invoice.paid` through the real handler; advance `Accrue.Test.Clock` + drain the `:accrue_dunning` Oban queue to prove start → step progression → cancel-on-recovery → exhaustion; assert the Phase-129 observable contract too; merge-blocking by being an untagged deterministic test in the default suite. → CONTEXT D-10..D-12.
- **Rationale:** the explicit cross-phase graduation lesson — "a fully green suite can hide a feature dead on the production path" (caught at CR in Phases 126 & 127). Not a fork; a correctness requirement.

### 4. Example-host wiring + demonstration vehicle (SC#4)
- **Options/sub-decisions:** queue-only vs + recovery crons; test-only proof vs visible LiveView/seed demo; host campaign enabled vs disabled.
- **Resolved:** add the missing `accrue_dunning` queue + `Oban.Plugins.Cron` (`DunningSweeper`, plus `DetectExpiringCards` for completeness — the droppable discretion item); campaign stays enabled (it's the demo); demonstrate via a Fake-backed merge-blocking host proof + an adoption-proof-matrix row (no new visible UI surface — Phase 132 owns visible host demo work). → CONTEXT D-13..D-16.
- **Rationale:** the scout found a concrete gap (host has no `accrue_dunning` queue → campaign dead on the host path); host config is additive/reversible; the matrix Fake-first blocking lane is the canonical "demonstrated end-to-end" surface.

## Claude's discretion items (handed to planner)
- Guide section ordering / inline-vs-link config reference.
- Exact capability atoms/labels (keep to established vocabulary; resist matrix bloat).
- Whether `DetectExpiringCards` is wired alongside `DunningSweeper` or scoped out.
- Home/name of the journey test; rich proof in `accrue` vs a thinner host smoke (prefer non-duplicated).
- Split of `require_substring` needles across `.planning/` matrix vs public guide.
- Host cron schedule expression.

## Deferred / scope-creep redirects
- Engine behaviour + Chimeway adapter → Phase 131. Entitlements host demo → Phase 132. Visible host "watch a campaign" demo, dedicated dunning gate, provider-native email coordination, analytics dashboard, multi-channel → deferred (see CONTEXT `<deferred>`).

## Todos
`todo.match-phase 130` → 0 matches.
