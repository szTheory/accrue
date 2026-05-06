# Phase 108: Docs, Migration, and Proof Closeout - Pattern Map

**Mapped:** 2026-05-06
**Files analyzed:** 12
**Analogs found:** 12 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue/README.md` | docs | front-door | `accrue/README.md` | exact |
| `accrue/guides/first_hour.md` | docs | front-door | `accrue/guides/first_hour.md` | exact |
| `accrue/guides/production-readiness.md` | docs | checklist | `accrue/guides/production-readiness.md` | exact |
| `accrue/guides/configuration.md` | docs | config-ssot | `accrue/guides/configuration.md` | exact |
| `accrue/guides/pdf.md` | docs | canonical-deep-guide | `accrue/guides/pdf.md` | exact |
| `accrue/guides/upgrade.md` | docs | migration-pointer | `accrue/guides/upgrade.md` | exact |
| `accrue/guides/custom_pdf_adapter.md` | docs | advanced-guide | `accrue/guides/custom_pdf_adapter.md` | exact |
| `accrue/guides/email.md` | docs | operational-guide | `accrue/guides/email.md` | exact |
| `accrue/guides/branding.md` | docs | renderer-constraints | `accrue/guides/branding.md` | exact |
| `.planning/milestones/v1.34-phases/108-docs-migration-proof-closeout/108-VERIFICATION.md` | artifact | verification-ledger | existing phase `*-VERIFICATION.md` files | strong |
| `scripts/ci/verify_package_docs.sh` | verifier | static-contract | `scripts/ci/verify_package_docs.sh` | exact |
| `accrue/test/accrue/billing/pdf_test.exs`, `accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs`, `accrue_admin/test/accrue_admin/live/invoice_live_test.exs` | proof | behavioral | same files | exact |

## Pattern Assignments

### `accrue/README.md` + `accrue/guides/first_hour.md` + `accrue/guides/production-readiness.md`

**Pattern:** layered pointer docs

Use short, high-signal statements that point into deeper guides instead of duplicating full setup detail.

**Observed shape:**

- `accrue/README.md` carries the package front door and the "Start here" list.
- `accrue/guides/first_hour.md` carries the first-user narrative spine.
- `accrue/guides/production-readiness.md` carries checklist-only operational prompts.

**Execution implication:** add one Rendro-first statement in each layer, but keep detailed migration logic in `accrue/guides/pdf.md`.

### `accrue/guides/configuration.md`

**Pattern:** key-ownership SSOT

The file names config keys and their ownership in compact prose plus small snippets. It should not carry long behavioral narratives.

**Observed excerpt:**

```markdown
- `:invoice_pdf_adapter` for invoice rendering through `Accrue.InvoiceRenderer`.
- `:pdf_adapter` for the lower-level HTML-to-PDF seam used by ChromicPDF and custom HTML renderers.
```

**Execution implication:** keep this file brief and explicit; send deeper migration and renderer behavior back to `guides/pdf.md`.

### `accrue/guides/pdf.md`

**Pattern:** canonical deep guide

This file already owns the adapter matrix, explicit Chromic compatibility path, and typed unavailable error contract.

**Observed excerpt:**

```markdown
If you only read one section: Rendro is the default. Jump to
**ChromicPDF explicit compatibility path** only if you explicitly want the
old HTML-based path.
```

**Execution implication:** extend this file with a dedicated migration section rather than moving the canonical story elsewhere.

### `accrue/guides/custom_pdf_adapter.md` + `accrue/guides/email.md` + `accrue/guides/branding.md`

**Pattern:** specialized deep guides with one renderer-specific subsection

- `custom_pdf_adapter.md` should talk about `Accrue.PDF` and the HTML seam.
- `email.md` should only mention invoice PDF attachment behavior and explicit compatibility caveats.
- `branding.md` should explain asset/font differences by renderer.

**Execution implication:** do not turn any of these into duplicate copies of `guides/pdf.md`; make them narrowly complementary.

### Proof artifact pattern

**Pattern:** behavior-first closeout ledger

Existing phase verification artifacts lead with the primary commands/results and then cite supporting evidence.

**Execution implication:** `108-VERIFICATION.md` should headline:

1. `accrue/test/accrue/billing/pdf_test.exs`
2. `accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs`
3. `accrue_admin/test/accrue_admin/live/invoice_live_test.exs`

Then record `bash scripts/ci/verify_package_docs.sh`, and explicitly state whether `bash scripts/ci/verify_rendro_hex_resolution.sh` was rerun or inherited from Phase 107.
