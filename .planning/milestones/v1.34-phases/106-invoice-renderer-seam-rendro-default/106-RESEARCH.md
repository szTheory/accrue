# Phase 106: Invoice Renderer Seam & Rendro Default - Research

**Researched:** 2026-05-06
**Domain:** Invoice PDF rendering seam, Rendro default path, and invoice-facing parity proof
**Confidence:** HIGH

<user_constraints>
## User Constraints (from ROADMAP.md and REQUIREMENTS.md)

### Locked Scope

- **PDF-01:** System MUST introduce an invoice-specific PDF renderer seam that is separate from the existing HTML-oriented `Accrue.PDF.render/2` contract.
- **PDF-02:** System MUST route `Accrue.Invoices.render_invoice_pdf/2` through the invoice renderer seam without changing the public billing and invoice API surface.
- **PDF-03:** System MUST preserve lazy render and storage semantics for `render/store/fetch_invoice_pdf` flows when the default renderer changes.
- **PDF-04:** System MUST use Rendro as the default invoice PDF renderer and generate valid invoice PDFs without requiring Chrome.
- **PDF-05:** System MUST preserve invoice content and layout intent parity for branding, totals, line items, dates, footer semantics, email attachments, and admin download flows.

### Continue-Without-Context Decision

No `106-CONTEXT.md` exists yet. Planning proceeds from locked roadmap/requirements scope plus repo evidence, equivalent to the workflow's "Continue without context" branch.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PDF-01 | Invoice-specific renderer seam separate from `Accrue.PDF` | Already present in `Accrue.InvoiceRenderer`, but legacy tests/docs still leak the old seam in a few places. [VERIFIED: `accrue/lib/accrue/invoice_renderer.ex`] |
| PDF-02 | `render_invoice_pdf/2` routes through invoice seam with unchanged public API | Already present in `Accrue.Invoices` and `Accrue.Billing`, but proof lanes need to assert the new adapter key and seam explicitly. [VERIFIED: `accrue/lib/accrue/invoices.ex`, `accrue/lib/accrue/billing.ex`] |
| PDF-03 | Lazy render/store/fetch semantics preserved | Present in `Accrue.Invoices`; phase work should guard against regressions while default renderer changes. [VERIFIED: `accrue/lib/accrue/invoices.ex`, `accrue/test/accrue/billing/pdf_test.exs`] |
| PDF-04 | Rendro default without Chrome | Present in config and core adapter; phase work should strengthen proof beyond a bare `%PDF` smoke check. [VERIFIED: `accrue/lib/accrue/config.ex`, `accrue/lib/accrue/invoice_renderer/rendro.ex`, `accrue/config/config.exs`] |
| PDF-05 | Parity across branding/totals/line items/dates/footer/admin/email | Partially covered by current mailer/admin flows, but the strongest remaining gap is proof fidelity and legacy test drift. [VERIFIED: `accrue/lib/accrue/workers/mailer.ex`, `accrue_admin/lib/accrue_admin/live/invoice_live.ex`, `accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs`, `accrue_admin/test/accrue_admin/live/invoice_live_test.exs`] |
</phase_requirements>

## Summary

Phase 106 is not greenfield. The repo already contains the core architecture the roadmap asks for: `Accrue.InvoiceRenderer` is a dedicated invoice-PDF seam, `Accrue.Invoices.render_invoice_pdf/2` routes through that seam, `:invoice_pdf_adapter` defaults to `Accrue.InvoiceRenderer.Rendro`, and the legacy HTML `Accrue.PDF` seam remains available for ChromicPDF or custom HTML callers. [VERIFIED: `accrue/lib/accrue/invoice_renderer.ex`, `accrue/lib/accrue/invoices.ex`, `accrue/lib/accrue/pdf.ex`, `accrue/lib/accrue/config.ex`]

The real remaining work is alignment and proof. Two high-signal drifts already exist:

1. The admin invoice LiveView test still overrides `:pdf_adapter`, but the invoice path now resolves `:invoice_pdf_adapter`, so the test no longer controls the seam it claims to exercise. [VERIFIED: `accrue_admin/test/accrue_admin/live/invoice_live_test.exs`, `accrue_admin/lib/accrue_admin/live/invoice_live.ex`]
2. The webhook mailer dispatch tests also still override `:pdf_adapter` while invoice attachments are generated through `Accrue.Billing.render_invoice_pdf/2`, which resolves the invoice-specific adapter instead. [VERIFIED: `accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs`, `accrue/lib/accrue/workers/mailer.ex`]

There is also a documentation drift: `guides/configuration.md` still says `:pdf_adapter` is the optional adapter "for invoice rendering", which is no longer true after the seam split. That statement now conflicts with `guides/pdf.md` and `Accrue.Config`. [VERIFIED: `accrue/guides/configuration.md`, `accrue/guides/pdf.md`, `accrue/lib/accrue/config.ex`]

The second planning concern is parity-proof depth. Today the Rendro default is proven mainly by a smoke test that the returned binary starts with `%PDF`. That is enough to prove rendering occurs, but not enough to prove that header/body/footer semantics and invoice content intent stayed stable when the implementation moved off Chrome. [VERIFIED: `accrue/test/accrue/billing/pdf_test.exs`, `accrue/lib/accrue/invoice_renderer/rendro.ex`]

**Primary recommendation:** treat Phase 106 as a contract-hardening phase with two execution tracks:

- Plan 01 removes legacy seam drift from tests and core-facing docs so invoice-facing proof actually exercises `Accrue.InvoiceRenderer`.
- Plan 02 strengthens Rendro parity proof with adapter-level tests and small renderer refactors if needed, while keeping the public `Accrue.Billing` / `Accrue.Invoices` facade unchanged.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Invoice-PDF public entry points | API / backend | docs / validation | `Accrue.Billing.render_invoice_pdf/2`, `store_invoice_pdf/2`, and `fetch_invoice_pdf/1` are the public contract; tests/docs must describe the same adapter seam. |
| Invoice renderer selection | config / backend | boot validation | `:invoice_pdf_adapter` selects the invoice seam; boot warnings only matter for the explicit Chromic fallback path. |
| Legacy HTML rendering | backend utility | extension docs | `Accrue.PDF` remains valid for Chromic/custom HTML callers, but it is no longer the invoice default. |
| Email PDF attachment flow | worker / backend | docs / telemetry | `Accrue.Workers.Mailer` calls the billing facade and either attaches a PDF or degrades to the hosted URL note. |
| Admin invoice download flow | frontend-server / LiveView | backend facade | `AccrueAdmin.Live.InvoiceLive` calls `Billing.render_invoice_pdf/2`; its tests should force the invoice renderer seam, not the legacy HTML seam. |
| Rendro parity proof | backend tests | docs / validation | The phase needs stronger proof that branding, rows, totals, dates, and footer semantics survive the engine swap. |

## Standard Stack

### Core

| Module / Artifact | Status | Purpose | Why It Matters |
|-------------------|--------|---------|----------------|
| `Accrue.InvoiceRenderer` | shipped | Invoice-specific renderer behaviour/facade | This is the seam Phase 106 is formalizing and proving. |
| `Accrue.InvoiceRenderer.Rendro` | shipped | Native default invoice renderer | Satisfies the no-Chrome default path. |
| `Accrue.InvoiceRenderer.ChromicPDF` | shipped | Explicit HTML fallback | Preserves the previous path without making it the default. |
| `Accrue.Invoices` | shipped | Public lazy render/store/fetch facade | Owns the semantics that must remain stable across the engine swap. |
| `Accrue.Workers.Mailer` | shipped | Email attachment integration | One of the concrete parity lanes named in PDF-05. |
| `AccrueAdmin.Live.InvoiceLive` | shipped | Admin open/download integration | Another concrete parity lane named in PDF-05. |

### Supporting

| Module / Artifact | Status | Purpose | When to Touch |
|-------------------|--------|---------|---------------|
| `accrue/test/accrue/billing/pdf_test.exs` | shipped | Core billing/invoice PDF contract tests | Extend for stronger seam/default-path assertions. |
| `accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs` | drifted | Mailer attachment proof | Update to configure `:invoice_pdf_adapter` and prove the real seam. |
| `accrue_admin/test/accrue_admin/live/invoice_live_test.exs` | drifted | Admin invoice proof | Update to force the real invoice seam and preserve UI behavior. |
| `accrue/guides/configuration.md` | drifted | Adapter configuration guide | Must stop telling integrators that `:pdf_adapter` controls invoice rendering. |
| `accrue/guides/pdf.md` | mostly aligned | Invoice renderer guide | Useful analog for wording and config examples. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Fixing proof lanes to use `:invoice_pdf_adapter` | Leaving legacy `:pdf_adapter` overrides in place | This keeps tests green while no longer testing the phase-106 seam, which is exactly the wrong signal. |
| Adding adapter-level parity tests for Rendro | Relying only on `%PDF` smoke checks | Smoke checks prove rendering happens, but not that the rendered invoice semantics stayed intact. |
| Small internal refactors for inspectable Rendro proof | Public-facade changes | Unnecessary risk. The phase should keep the public invoice API stable and limit any refactor to internal renderer proofability. |

## Open Questions (RESOLVED)

### How much of Phase 106 is already implemented?

Resolved: most of the architecture is already in the repo. The phase is now mainly contract alignment and proof hardening rather than initial implementation.

### Where is the highest-value remaining gap?

Resolved: legacy proof lanes still configure the wrong adapter key, which means admin and mailer tests do not currently prove the invoice-specific seam.

### Does this phase need a broad docs rewrite?

Resolved: no. Full migration/install guidance belongs to Phases 107-108. Phase 106 only needs narrow contract-facing doc fixes where the current repo lies about which adapter owns invoice rendering.
