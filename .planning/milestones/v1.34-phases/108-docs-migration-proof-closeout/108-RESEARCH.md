# Phase 108: Docs, Migration, and Proof Closeout - Research

**Researched:** 2026-05-06
**Domain:** Rendro-first docs closeout, legacy PDF migration guidance, and final proof posture
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Put the migration guidance in `accrue/guides/pdf.md` as a dedicated section; do not hide it in changelogs or scattered warnings.
- **D-02:** Cover exactly three host states:
  - no custom PDF config: no action needed, Rendro is the default invoice path
  - `:pdf_adapter` only: invoice PDFs no longer follow that key; set `:invoice_pdf_adapter, Accrue.InvoiceRenderer.ChromicPDF` for the legacy Chrome-backed invoice path
  - custom HTML seam users: `:pdf_adapter` still owns `Accrue.PDF`, but invoice rendering only changes when `:invoice_pdf_adapter` is set explicitly
- **D-03:** Keep the seam split explicit. `:invoice_pdf_adapter` owns invoice rendering; `:pdf_adapter` remains the lower-level HTML seam.
- **D-04:** Runtime warnings remain a safety net, but docs are the primary migration surface.
- **D-05:** Do not create a standalone migration guide for this phase.
- **D-06:** Keep the layered docs posture: short front-door pointers, one canonical deep guide.
- **D-07:** `accrue/README.md` should make the Rendro-first default visible and point to the PDF guide.
- **D-08:** `accrue/guides/first_hour.md` should set expectation that Chrome is not required on the default invoice path, but it must not become a deep PDF setup guide.
- **D-09:** `accrue/guides/production-readiness.md` should focus on operational checklist items only: `:invoice_pdf_adapter` posture, Chromic pool/supervision only for explicit compatibility mode, and asset/font validation for rendered invoices and email attachments.
- **D-10:** `accrue/guides/pdf.md` remains the canonical deep guide.
- **D-11:** `accrue/guides/configuration.md` stays the config SSOT for key ownership and examples, while behavior and migration detail stay in `guides/pdf.md`.
- **D-12:** `accrue/guides/custom_pdf_adapter.md` must be reframed as advanced HTML-seam guidance, not default invoice guidance.
- **D-13:** `accrue/guides/email.md` should document invoice-attachment interaction with the invoice renderer and make Chromic notes conditional on the explicit compatibility path.
- **D-14:** `accrue/guides/branding.md` should spell out renderer-specific asset and font constraints where Rendro and Chromic differ.
- **D-15:** Final closeout proof should center the three user-visible behavioral lanes:
  - `accrue/test/accrue/billing/pdf_test.exs`
  - `accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs`
  - `accrue_admin/test/accrue_admin/live/invoice_live_test.exs`
- **D-16:** `bash scripts/ci/verify_package_docs.sh` is supporting evidence, not the headline proof.
- **D-17:** `bash scripts/ci/verify_rendro_hex_resolution.sh` is inherited release proof from Phase 107 and only needs re-running if dependency or release-truth files change.
- **D-18:** Do not broaden the closeout into the full docs-contracts-shift-left bundle unless the touched surface expands materially.
- **D-19:** The closeout artifact should present behavioral proof first, docs/release proof second.

### the agent's Discretion

- Exact phrasing for README / First Hour / Production Readiness pointers.
- Exact wording and examples inside the migration section, as long as the three host states stay explicit.
- Exact verification-artifact layout, as long as it distinguishes primary behavioral proof from supporting docs/release proof.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PDF-08 | System MUST update Accrue's install and PDF docs so Rendro is the default recommendation and ChromicPDF is documented as an optional fallback. | The current deep PDF guide already tells the correct Rendro-first story, but the front-door docs and adjacent operational guides still need alignment. [VERIFIED: `accrue/README.md`, `accrue/guides/first_hour.md`, `accrue/guides/production-readiness.md`, `accrue/guides/configuration.md`, `accrue/guides/pdf.md`] |
| PDF-09 | System MUST document the migration posture for hosts currently using the legacy `:pdf_adapter` or ChromicPDF-based invoice path. | The migration contract already exists in runtime/code shape and in Phase 108 context, but `accrue/guides/pdf.md` does not yet have the dedicated three-state migration section, and adjacent guides still contain outdated Chromic-default cues. [VERIFIED: `accrue/guides/pdf.md`, `accrue/guides/email.md`, `accrue/guides/custom_pdf_adapter.md`, `accrue/guides/branding.md`, `accrue/guides/upgrade.md`] |
</phase_requirements>

## Summary

Phase 108 is a documentation-and-proof closeout, not a renderer redesign. The code already reflects the intended runtime contract after Phase 107: Rendro is the default invoice path, `:invoice_pdf_adapter` is the invoice-facing switch, `:pdf_adapter` remains the lower-level HTML seam, and a dedicated clean-checkout Rendro Hex proof script already exists. [VERIFIED: `accrue/lib/accrue/config.ex`, `accrue/lib/accrue/application.ex`, `accrue/lib/accrue/invoices.ex`, `accrue/mix.exs`, `scripts/ci/verify_rendro_hex_resolution.sh`]

The real gaps are in the docs spine and the final proof story. The canonical PDF guide is already close to the target state, but it lacks the dedicated three-state migration section required by D-01/D-02. The front-door and operational docs are also inconsistent: `accrue/README.md` does not currently surface the Rendro-first invoice story, `accrue/guides/production-readiness.md` still names `:pdf_adapter` rather than `:invoice_pdf_adapter`, and `accrue/guides/email.md` still shows `pdf_adapter: Accrue.PDF.ChromicPDF` in its quickstart and states that the host starts ChromicPDF unconditionally. [VERIFIED: `accrue/README.md`, `accrue/guides/production-readiness.md`, `accrue/guides/email.md`]

Two advanced guides are also stale against the locked seam split. `accrue/guides/custom_pdf_adapter.md` still frames itself as replacing the "default ChromicPDF path," which is now wrong because custom `Accrue.PDF` adapters own only the HTML seam. `accrue/guides/branding.md` still describes PDF logo/font constraints primarily in Chromic terms and does not clearly contrast Rendro's stricter offline/base64 posture with the explicit Chromic compatibility lane. [VERIFIED: `accrue/guides/custom_pdf_adapter.md`, `accrue/guides/branding.md`, `accrue/guides/pdf.md`]

The final closeout should therefore be planned as two sequential slices. First, align the front-door docs and the canonical migration story around the Rendro-first default and the explicit `:invoice_pdf_adapter` vs `:pdf_adapter` split. Second, clean up the advanced guides and produce a proof artifact that re-runs the three behavioral invoice lanes plus `verify_package_docs.sh`, while treating `verify_rendro_hex_resolution.sh` as inherited prerequisite evidence unless dependency truth changes again. [VERIFIED: `accrue/test/accrue/billing/pdf_test.exs`, `accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs`, `accrue_admin/test/accrue_admin/live/invoice_live_test.exs`, `scripts/ci/verify_package_docs.sh`, `scripts/ci/verify_rendro_hex_resolution.sh`]

**Primary recommendation:** plan Phase 108 as two wave-ordered plans:
1. front-door docs + canonical migration contract
2. advanced guide cleanup + proof closeout artifact

That keeps the information architecture coherent, satisfies both PDF-08 and PDF-09, and preserves the required signal hierarchy of behavior-first proof with docs/release proof in support.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Rendro-first public story | package docs | code comments / runtime warnings | New adopters should learn the default from the front door, not by reading source or logs. [VERIFIED: `accrue/README.md`, `accrue/guides/first_hour.md`, `accrue/guides/pdf.md`] |
| Migration contract for legacy PDF users | canonical PDF guide | upgrade guide / runtime warning | D-01 and D-02 require one canonical migration section with short pointers elsewhere. [VERIFIED: `accrue/guides/pdf.md`, `accrue/guides/upgrade.md`, `accrue/lib/accrue/application.ex`] |
| Operational renderer readiness | production checklist | branding / email guides | Production guidance should stay checklist-shaped and defer deep renderer details to the specialized guides. [VERIFIED: `accrue/guides/production-readiness.md`, `accrue/guides/branding.md`, `accrue/guides/email.md`] |
| HTML seam customization posture | custom adapter guide | configuration guide | The repo still supports `Accrue.PDF` customization, but it is no longer the invoice default path. [VERIFIED: `accrue/guides/custom_pdf_adapter.md`, `accrue/guides/configuration.md`, `accrue/lib/accrue/pdf.ex`] |
| Final closeout proof | behavioral tests | docs and release scripts | D-15..D-19 require user-visible behavior to lead the artifact, with docs/release verification in support. [VERIFIED: `accrue/test/accrue/billing/pdf_test.exs`, `accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs`, `accrue_admin/test/accrue_admin/live/invoice_live_test.exs`, `scripts/ci/verify_package_docs.sh`, `scripts/ci/verify_rendro_hex_resolution.sh`] |

## Project Constraints

- Keep the existing layered docs architecture intact: README -> First Hour / Production Readiness -> deep guide. [VERIFIED: `accrue/README.md`, `accrue/guides/first_hour.md`, `accrue/guides/production-readiness.md`]
- Preserve the host-owned infrastructure posture. Docs must not imply that Accrue starts ChromicPDF or other runtime dependencies. [VERIFIED: `accrue/guides/pdf.md`, `accrue/lib/accrue/application.ex`]
- Treat behavioral proof as the primary closeout truth and docs/release scripts as supporting evidence. [VERIFIED: `.planning/milestones/v1.34-phases/108-docs-migration-proof-closeout/108-CONTEXT.md`, `scripts/ci/verify_package_docs.sh`, `scripts/ci/verify_rendro_hex_resolution.sh`]
- Avoid repo-wide verifier churn unless the touched surface demands it. Current CI already has a supporting package-doc gate. [VERIFIED: `.github/workflows/ci.yml`, `scripts/ci/verify_package_docs.sh`]

## Current-State Findings

### Front-door docs are only partially aligned

- `accrue/guides/pdf.md` already says "Rendro is the default" and documents the explicit Chromic compatibility path. [VERIFIED: `accrue/guides/pdf.md`]
- `accrue/README.md` still presents product polish as "transactional email, invoice PDFs, installer tasks" without surfacing the Rendro-first install story. [VERIFIED: `accrue/README.md`]
- `accrue/guides/first_hour.md` never tells a first-user that Chrome is no longer required for the default invoice path. [VERIFIED: `accrue/guides/first_hour.md`]
- `accrue/guides/production-readiness.md` still lists optional adapters as `:auth_adapter`, `:pdf_adapter`, `:mailer`, which is now incomplete and mildly misleading. [VERIFIED: `accrue/guides/production-readiness.md`]

### Migration guidance is not explicit enough yet

- `accrue/guides/pdf.md` describes the seam split but does not yet provide the dedicated three-host-state migration section required by D-01/D-02. [VERIFIED: `accrue/guides/pdf.md`]
- `accrue/guides/upgrade.md` currently discusses package/version posture only and does not point legacy PDF users to the new canonical migration section. [VERIFIED: `accrue/guides/upgrade.md`]

### Advanced guides still contain pre-Rendro assumptions

- `accrue/guides/custom_pdf_adapter.md` says hosts can replace the "default ChromicPDF path", which is no longer true. [VERIFIED: `accrue/guides/custom_pdf_adapter.md`]
- `accrue/guides/email.md` still uses `pdf_adapter: Accrue.PDF.ChromicPDF` in Quickstart and says the host application is responsible for starting ChromicPDF without qualifying that this is only for the explicit compatibility path. [VERIFIED: `accrue/guides/email.md`]
- `accrue/guides/branding.md` only names a ChromicPDF PDF row in the logo strategy table and points back to a "ChromicPDF font + image loading strategy," which misses the new Rendro-vs-Chromic distinction. [VERIFIED: `accrue/guides/branding.md`]

### Proof lanes are already in place

- The three required behavior lanes already exist and target the correct invoice/mailer/admin surfaces. [VERIFIED: `accrue/test/accrue/billing/pdf_test.exs`, `accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs`, `accrue_admin/test/accrue_admin/live/invoice_live_test.exs`]
- `scripts/ci/verify_package_docs.sh` is already the right supporting docs verifier for touched README/guide surfaces. [VERIFIED: `scripts/ci/verify_package_docs.sh`]
- `scripts/ci/verify_rendro_hex_resolution.sh` is a prerequisite proof artifact from Phase 107 and should be reused unless dependency or release truth changes. [VERIFIED: `scripts/ci/verify_rendro_hex_resolution.sh`, `RELEASING.md`]

## Validation Architecture

### Primary proof lane

Run the three behavioral invoice lanes on the final Hex-backed dependency set:

```bash
cd accrue && mix test test/accrue/billing/pdf_test.exs
cd accrue && mix test test/accrue/webhook/default_handler_mailer_dispatch_test.exs
cd accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs
```

These are the primary closeout commands because they prove user-visible invoice rendering, mail attachments/fallback, and admin open/download behavior.

### Supporting docs proof lane

```bash
bash scripts/ci/verify_package_docs.sh
cd accrue && MIX_ENV=dev mix docs --warnings-as-errors
```

Use this lane to catch front-door/docs drift after the guide rewrites. It supports PDF-08/PDF-09 but should not replace the primary behavior proof.

### Inherited release proof

```bash
bash scripts/ci/verify_rendro_hex_resolution.sh
```

Treat this as prerequisite evidence from Phase 107 unless `accrue/mix.exs`, `accrue/mix.lock`, `RELEASING.md`, or the script itself changes during Phase 108. If none of those files change, the Phase 108 verification artifact should explicitly say the proof was inherited rather than silently omitted.

## Open Questions (RESOLVED)

- **Should Phase 108 update verifier scripts?** Not by default. Current evidence shows `verify_package_docs.sh` is already the correct supporting gate, and the phase should avoid broader verifier churn unless a touched doc introduces a real contract gap. [VERIFIED: `scripts/ci/verify_package_docs.sh`, `.github/workflows/ci.yml`]
- **Should `verify_rendro_hex_resolution.sh` be re-run in a docs-only phase?** Only if dependency or release-truth files move again. Otherwise the phase should inherit the proof and cite the Phase 107 artifact explicitly. [VERIFIED: `scripts/ci/verify_rendro_hex_resolution.sh`, `RELEASING.md`, `.planning/milestones/v1.34-phases/107-rendro-release-optional-chromic-path/107-02-SUMMARY.md`]

## Plan Shape Recommendation

| Plan | Focus | Why it should be separate |
|------|-------|---------------------------|
| 108-01 | README / First Hour / Production Readiness / Configuration / canonical PDF migration section | Front-door docs and the canonical migration contract are tightly coupled and should land together before proof closeout. |
| 108-02 | Advanced guide cleanup + final proof artifact | The operational/deep-guide cleanup and the final behavior/docs proof should execute after the front-door contract is stable. |

---

*Phase: 108-docs-migration-proof-closeout*
*Research completed: 2026-05-06*
