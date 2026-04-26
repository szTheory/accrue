# Phase 89: Proof of Concept Templates & Pipeline - Context

**Gathered:** 2026-04-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Refactor `Accrue.Workers.Mailer` to dispatch via `Mailglass.deliver/1` with an explicit `idempotency_key`, port `Accrue.Emails.Receipt` and `Accrue.Emails.PaymentFailed` to `Mailglass.Mailable`, and verify the first Mailglass email pipeline end-to-end, including PDF attachment behavior. Phase 90 handles the remaining templates and cleanup.

</domain>

<decisions>
## Implementation Decisions

### Mailer boundary
- **D-01:** Keep `Accrue.Workers.Mailer` as the orchestration seam. It hydrates assigns, resolves the template, builds the Mailglass message, adds any PDF attachment, and calls `Mailglass.deliver/1`.
- **D-02:** Keep `Accrue.Mailer.Default` enqueue-only. Do not introduce a second adapter layer or a new mail-specific boundary just for Phase 89.

### PDF attachment rule
- **D-03:** Treat `Receipt` as the attachment-bearing POC path for Phase 89. Attach the invoice PDF when `Accrue.Billing.render_invoice_pdf/2` succeeds.
- **D-04:** If the invoice PDF cannot be rendered, fall back to the hosted invoice URL note rather than failing the mail job.
- **D-05:** Keep `PaymentFailed` attachment-free. Do not generalize PDF attachment to every email type in this phase.

### Template fidelity
- **D-06:** Port `Receipt` and `PaymentFailed` as HEEx-based Mailglass mailables, preserving the current copy, CTA behavior, and content order from the MJML templates.
- **D-07:** Validate semantic/visual parity, not byte-for-byte HTML equality. Mailglass markup may differ, but adopter-visible output should not.
- **D-08:** Reuse the existing deterministic fixtures and invoice-rendering helpers as the source of truth for tests and snapshots.

### Idempotency key shape
- **D-09:** Use a business-event key, not a rendered-content hash. For this phase, derive the explicit key as `accrue:v1:<type>:<charge_id>` for both `Receipt` and `PaymentFailed`.
- **D-10:** Do not include rendered HTML, branding content, or recipient address in the idempotency key. Copy changes must not create duplicate sends.

### Verification strategy
- **D-11:** Verify the seam with layered automation: worker hydration tests, Mailglass delivery assertions, and PDF attachment assertions using the existing test adapters.
- **D-12:** Use normalized render comparisons and targeted structure assertions. Do not require raw HTML string equality.
- **D-13:** Keep the proof shift-left. Manual preview is optional for inspection, not the acceptance bar.

### the agent's Discretion
- Exact helper names and internal refactor shape inside `Accrue.Workers.Mailer`.
- Exact snapshot tooling as long as the observed output stays stable.
- Minor spacing/layout differences introduced by Mailglass rendering.

</decisions>

<specifics>
## Specific Ideas

- Preserve the current receipt/payment-failed copy as the adopter-facing baseline.
- Exercise the existing charge-based dispatch path from `Accrue.Webhook.DefaultHandler` rather than inventing a new send trigger.
- Keep this phase bounded to the first two templates; do not start the remaining MJML port work early.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and state
- `.planning/ROADMAP.md` — Phase 89 goal, success criteria, and phase boundary.
- `.planning/REQUIREMENTS.md` — MG-04, MG-05, MG-06 locked requirements.
- `.planning/STATE.md` — current phase position and prior Phase 88 decisions.
- `.planning/milestones/v1.29-phases/088-mailglass-foundation/088-03-VERIFICATION.md` — Phase 88 migration/doc deferral and what Phase 89 inherits.

### Accrue mail pipeline
- `accrue/lib/accrue/workers/mailer.ex` — current worker orchestration, PDF fallback, and Oban uniqueness behavior.
- `accrue/lib/accrue/mailer.ex` — facade contract and kill-switch semantics.
- `accrue/lib/accrue/mailer/default.ex` — enqueue-only adapter and scalar-assign guard.
- `accrue/lib/accrue/webhook/default_handler.ex` — current charge/invoice dispatch inputs and subject IDs.
- `accrue/lib/accrue/emails/receipt.ex` — current receipt source and current non-PDF expectation.
- `accrue/lib/accrue/emails/payment_failed.ex` — current payment-failed source.
- `accrue/lib/accrue/emails/fixtures.ex` — deterministic fixture data for tests and previews.
- `accrue/priv/accrue/templates/emails/receipt.mjml.eex` — current receipt MJML baseline.
- `accrue/priv/accrue/templates/emails/payment_failed.mjml.eex` — current payment-failed MJML baseline.
- `accrue/lib/accrue/billing.ex` — invoice PDF rendering facade.
- `accrue/lib/accrue/invoices.ex` — PDF rendering/storage semantics.
- `accrue/lib/accrue/pdf.ex` — PDF adapter contract and test adapter notes.

### Mailglass contract
- `../mailglass/lib/mailglass/mailable.ex` — Mailglass `use` contract and delivery surface.
- `../mailglass/lib/mailglass/message.ex` — message wrapper, metadata, and message-level idempotency inputs.
- `../mailglass/lib/mailglass/outbound.ex` — delivery pipeline and built-in idempotency computation.
- `../mailglass/lib/mailglass/renderer.ex` — HEEx, plaintext, and CSS-inlining pipeline.
- `../mailglass/lib/mailglass/components.ex` — HEEx email component primitives.
- `../mailglass/lib/mailglass/components/layout.ex` — Mailglass document shell.
- `../mailglass/docs/api_stability.md` — stable public contract and closed error sets.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Accrue.Emails.Fixtures` — deterministic input data for render and parity tests.
- `Accrue.Billing.render_invoice_pdf/2` — existing PDF rendering boundary; do not duplicate PDF logic in templates.
- `Accrue.PDF.Test` — existing Chrome-free test adapter for PDF capture.
- `Mailglass.MailerCase` / `Mailglass.Adapters.Fake` — Mailglass-side delivery testing patterns.

### Established Patterns
- `Accrue.Webhook.DefaultHandler` already dispatches `:receipt` and `:payment_failed` from charge reconciliation using `charge_id` and `customer_id`.
- `Accrue.Mailer.Default` already enforces scalar-only Oban args, so the worker should receive IDs and simple scalars only.
- `Mailglass.Renderer` already owns HEEx rendering, plaintext extraction, and CSS inlining, so the ported mailables should be thin wrappers around that model.

### Integration Points
- The phase-89 seam is `Accrue.Workers.Mailer -> Mailglass.deliver/1`.
- PDF attachment still flows through `Accrue.Billing.render_invoice_pdf/2` and should be added before delivery.
- The current MJML templates are the content baseline for parity checks, not the implementation target.

</code_context>

<deferred>
## Deferred Ideas

- Port the remaining 11 MJML templates to Mailglass.
- Remove `mjml_eex` and `phoenix_swoosh` from `accrue/mix.exs`.
- Retire `mix accrue.mail.preview`.
- Broader shared email-shell cleanup can wait for Phase 90 unless it is required to unblock the first two ports.

</deferred>

---

*Phase: 89-proof-of-concept-templates-pipeline*
*Context gathered: 2026-04-26*
