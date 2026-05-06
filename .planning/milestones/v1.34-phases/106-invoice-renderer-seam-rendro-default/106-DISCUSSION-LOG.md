# Phase 106: Invoice Renderer Seam & Rendro Default - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in `106-CONTEXT.md` are the planning input.

**Date:** 2026-05-06
**Phase:** 106-invoice-renderer-seam-rendro-default
**Mode:** discuss-all, advisor-synthesized
**Areas discussed:** parity proof depth, testability seam, docs scope

## Inputs considered

- Locked requirements in `.planning/REQUIREMENTS.md` (`PDF-01..05`)
- Existing phase artifacts:
  - `106-RESEARCH.md`
  - `106-01-PLAN.md`
  - `106-02-PLAN.md`
  - `106-PATTERNS.md`
- Active code/docs surfaces:
  - `accrue/lib/accrue/invoice_renderer.ex`
  - `accrue/lib/accrue/invoice_renderer/rendro.ex`
  - `accrue/lib/accrue/invoices.ex`
  - `accrue/test/accrue/billing/pdf_test.exs`
  - `accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs`
  - `accrue_admin/test/accrue_admin/live/invoice_live_test.exs`
  - `accrue/guides/configuration.md`
  - `accrue/guides/pdf.md`
- User instruction:
  - discuss all remaining gray areas
  - decide coherently without more back-and-forth
  - emphasize deep research, strong architecture, least surprise, and good DX
  - auto-resolve low-impact forks and only elevate materially important ones

## Advisor synthesis

### Parity proof depth

Recommendation:

- Keep `%PDF` smoke assertions as the floor.
- Make semantic pre-render structure assertions the primary proof layer.
- Add a few targeted end-to-end rendered-output assertions for critical strings.
- Reject whole-PDF golden snapshots as the default strategy.

Why:

- Better review signal than raw snapshots
- Stronger semantic coverage than smoke-only tests
- More stable and idiomatic for Elixir library maintenance

### Testability seam

Recommendation:

- Keep `render/2` as the only supported public renderer entry.
- Extract a hidden internal builder seam for Rendro document construction.
- Prefer a hidden internal module over a same-module `@doc false` helper.
- Avoid test-only hooks and public structured debug APIs.

Why:

- Preserves stable public surface
- Makes failures localizable and structural assertions easy
- Avoids turning renderer internals into semver obligations

### Docs scope

Recommendation:

- Limit Phase 106 docs work to contract-truth repair only.
- Fix any current lie about `:invoice_pdf_adapter` vs `:pdf_adapter`.
- Defer broader migration/install/default-story work to Phases 107–108.

Why:

- Matches locked phase boundary
- Prevents doc duplication and drift
- Keeps the public contract honest without phase creep

## Coherence check

The final recommendation set is intentionally mutually reinforcing:

- semantic proof requires an inspectable internal seam
- an inspectable internal seam only works cleanly if the public API stays narrow
- narrow public API and narrow contract-truth docs both reinforce least surprise
- deferring broader migration/release work keeps Phase 106 focused on truth and proof rather than storytelling

## Deferred process note

The user asked for a broader GSD preference shift toward:

- deep synthesis by default
- auto-resolution of low-impact forks
- resurfacing only genuinely high-impact decisions

Current `.planning/config.json` already partially encodes this. Broader workflow-level codification was noted but kept out of Phase 106 implementation scope.
