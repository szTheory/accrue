# Phase 90: Full Template Port & Cleanup - Context

**Gathered:** 2026-04-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Finish the Mailglass migration by porting the remaining email templates to Mailglass HEEx components, removing `mjml_eex` and `phoenix_swoosh` from `accrue/mix.exs`, and retiring the legacy `mix accrue.mail.preview` task. Phase 89 already established the Mailglass worker seam and the first two HEEx mailables.

</domain>

<decisions>
## Implementation Decisions

### Legacy template cleanup
- **D-01:** Port `Accrue.Emails.PaymentSucceeded` to Mailglass as well, so the `:payment_succeeded` alias stops being the last MJML-backed holdout.
- **D-02:** Remove the old MJML template files, their sibling `.text.eex` files, and `Accrue.Emails.HtmlBridge` once the Mailglass versions are in place.
- **D-03:** Keep `Accrue.Emails.Fixtures` as the deterministic data source for previews and tests; the fixture module is still useful after MJML is gone.

### Preview tooling retirement
- **D-04:** Retire `mix accrue.mail.preview` completely instead of keeping a compatibility shim or alternate CLI path.
- **D-05:** Keep `AccrueAdmin.Dev.EmailPreviewLive` as the supported human preview surface. That LiveView becomes the replacement for the retired CLI task.
- **D-06:** Remove preview-only helper code that exists solely for the CLI task, including `Accrue.Workers.Mailer.template_for/1`, if it is no longer used elsewhere.

### Verification shape
- **D-07:** Verify this phase with a broad fixture sweep across all email types, plus a small set of targeted regression assertions for the edge-case templates.
- **D-08:** Prefer render-structure and content assertions over byte-for-byte HTML equality. Mailglass output may differ in markup, but adopter-visible behavior must stay stable.
- **D-09:** Add explicit cleanup checks that `mjml_eex` and `phoenix_swoosh` no longer appear in `accrue/mix.exs`, and that the old CLI task module is gone.
- **D-10:** If `payment_succeeded` remains as the compatibility alias, include it in the Mailglass render sweep so the alias stays honest after the dependency purge.

### the agent's Discretion
- Exact file deletion order.
- Exact helper names and internal refactor shape inside the remaining mail modules.
- Whether any test files are consolidated or deleted as part of the cleanup, as long as coverage stays equivalent.

</decisions>

<specifics>
## Specific Ideas

- Keep the admin `/dev/email-preview` route as the long-term preview path; do not replace it with a new CLI equivalent.
- Treat the Mailglass-backed fixture sweep as the new source of truth for preview sanity checks.
- Preserve compatibility for the `:payment_succeeded` mailer type unless a later phase explicitly removes it.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap
- `.planning/ROADMAP.md` — Phase 90 goal, success criteria, and boundary.
- `.planning/REQUIREMENTS.md` — MG-07 locked requirement.
- `.planning/STATE.md` — current milestone/phase position and recent decisions.
- `.planning/milestones/v1.29-phases/089-proof-of-concept-templates-pipeline/089-CONTEXT.md` — the Mailglass seam, PDF attachment behavior, and the first two ported templates.

### Accrue mail pipeline
- `accrue/mix.exs` — dependency removal target.
- `accrue/lib/accrue/workers/mailer.ex` — template resolution, Mailglass delivery, and the remaining alias surface.
- `accrue/lib/accrue/emails/receipt.ex` — current Mailglass mailables pattern.
- `accrue/lib/accrue/emails/payment_failed.ex` — current Mailglass mailables pattern.
- `accrue/lib/accrue/emails/payment_succeeded.ex` — legacy MJML-backed alias to port or retire.
- `accrue/lib/accrue/emails/fixtures.ex` — deterministic fixture corpus for the full mail set.
- `accrue/lib/accrue/emails/html_bridge.ex` — MJML-only bridge slated for removal.
- `accrue/lib/mix/tasks/accrue.mail.preview.ex` — legacy CLI preview task slated for retirement.

### Admin preview surface
- `accrue_admin/lib/accrue_admin/dev/email_preview_live.ex` — supported preview UI built on fixtures.
- `accrue_admin/lib/accrue_admin/router.ex` — `/dev/email-preview` route wiring.
- `accrue_admin/test/accrue_admin/dev/dev_routes_test.exs` — route guard coverage for the preview surface.

### Mailglass contract
- `../mailglass/lib/mailglass/mailable.ex` — Mailglass mailable contract.
- `../mailglass/lib/mailglass/message.ex` — message wrapper and metadata surface.
- `../mailglass/lib/mailglass/outbound.ex` — delivery pipeline and idempotency behavior.
- `../mailglass/lib/mailglass/renderer.ex` — HEEx, plaintext, and inlining pipeline.
- `../mailglass/lib/mailglass/components/layout.ex` — shared email shell.
- `../mailglass/docs/api_stability.md` — public contract expectations.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Accrue.Emails.Fixtures` already covers the full 13-type fixture catalogue and is deterministic.
- `AccrueAdmin.Dev.EmailPreviewLive` already provides a browser-based preview path that reads fixtures directly.
- `Mailglass.Renderer` and `Mailglass.Components.Layout` already define the HEEx email pattern phase 90 should extend.

### Established Patterns
- The mail worker already routes through `Mailglass.deliver/1` for the Mailglass-backed types.
- The fixture tests already exercise every template module through the worker resolver.
- Phase 89 established that structure/content checks are enough for Mailglass parity; exact HTML bytes are not the right contract.

### Integration Points
- `accrue/mix.exs` is the dependency cleanup gate.
- `accrue/lib/mix/tasks/accrue.mail.preview.ex` and `accrue/lib/accrue/emails/html_bridge.ex` are the main legacy MJML holdouts.
- `accrue/lib/accrue/emails/payment_succeeded.ex` is the compatibility edge case that decides whether the old mailer surface is fully Mailglass-backed.

</code_context>

<deferred>
## Deferred Ideas

None — phase 90 stays within cleanup and dependency retirement.

</deferred>

---

*Phase: 90-full-template-port-cleanup*
*Context gathered: 2026-04-26*
