# Phase 106: Invoice Renderer Seam & Rendro Default - Pattern Map

**Mapped:** 2026-05-06
**Files analyzed:** 10 primary files
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `accrue/test/accrue/billing/pdf_test.exs` | test | request-response | `accrue/test/accrue/billing/pdf_test.exs` | exact |
| `accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs` | test | async worker proof | `accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs` | exact |
| `accrue_admin/test/accrue_admin/live/invoice_live_test.exs` | test | LiveView request-response | `accrue_admin/test/accrue_admin/live/invoice_live_test.exs` | exact |
| `accrue/lib/accrue/invoice_renderer/rendro.ex` | backend | transform | `accrue/lib/accrue/invoice_renderer/rendro.ex` | exact |
| `accrue/lib/accrue/invoices.ex` | backend facade | request-response | `accrue/lib/accrue/invoices.ex` | exact |
| `accrue/lib/accrue/workers/mailer.ex` | worker | async transform | `accrue/lib/accrue/workers/mailer.ex` | exact |
| `accrue/guides/configuration.md` | docs | contract truth | `accrue/guides/pdf.md` | role-match |
| `accrue/guides/testing.md` | docs | workflow truth | `accrue/guides/pdf.md` | role-match |

## Pattern Assignments

### `accrue/test/accrue/billing/pdf_test.exs`

**Analog:** same file

Use the existing style:

- per-adapter `describe` blocks
- `Application.put_env/3` + `on_exit/1` for adapter swapping
- assertions on returned tuples and mailbox messages for `Accrue.InvoiceRenderer.Test`

Phase 106 should extend this file rather than invent a new billing-PDF test style.

### `accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs`

**Analog:** same file

Use the current worker-proof pattern:

- set up `Accrue.Mailer.Default`
- execute an `Oban.Job` directly or through reducer handling
- inspect the delivered Mailglass/Swoosh message for attachments or hosted-URL fallback

Phase 106 changes here should be surgical: swap the correct invoice adapter key and keep the current delivery-proof shape.

### `accrue_admin/test/accrue_admin/live/invoice_live_test.exs`

**Analog:** same file

Use the current LiveView flow:

- mount route with session
- render click on the "Open PDF" button
- assert the UI exposes the rendered/open/download affordances

Phase 106 should keep this UX-level proof and only correct the seam configuration underneath it.

### `accrue/lib/accrue/invoice_renderer/rendro.ex`

**Analog:** same file

Use the current pure-helper structure:

- one `render/2` entry
- private section builders for header/body/footer
- formatting delegated through `Accrue.Invoices.Render`

If stronger parity proof needs inspectable state, prefer a small internal refactor or `@doc false` helper over public facade changes.

### `accrue/lib/accrue/invoices.ex`

**Analog:** same file

Use the existing contract style:

- public `render/store/fetch_invoice_pdf`
- explicit adapter availability guard
- `safe_build_assigns/2` error wrapping
- lazy derived storage key

Phase 106 should preserve this contract; plans should not widen the public API.

### `accrue/guides/configuration.md`

**Analogs:** `accrue/guides/pdf.md`, `accrue/lib/accrue/config.ex`

Follow the existing concise config-guide pattern:

- short bullets naming optional adapters
- direct wording aligned to actual config keys
- no broad migration narrative

For invoice rendering, `guides/configuration.md` should match `Accrue.Config` and defer deeper explanation to `guides/pdf.md`.
