# Requirements: Mailglass Integration — Milestone v1.29

**Core value:** Modernize the transactional email pipeline by replacing MJML and raw Swoosh with the HEEx-native Mailglass framework. This improves developer experience, adds built-in idempotency and event tracking, and provides a powerful dev-preview UI.

## v1.29 — Mailglass Integration

**Goal:** Integrate the mailglass packages (as path dependencies for now) to completely replace MJML and the raw Swoosh pipeline in accrue.

### Mailglass Foundation & Admin (MG)
- **MG-01**: Replace `mjml_eex` and `phoenix_swoosh` with `{:mailglass, path: "../mailglass"}` in `accrue` and `{:mailglass_admin, path: "../mailglass", only: [:dev]}` in `accrue_admin`.
- **MG-02**: Mount the `mailglass_admin` LiveView UI in `accrue_admin`'s router to provide an instantaneous visual feedback loop, replacing the old `mix accrue.mail.preview` command.
- **MG-03**: Update Accrue's installation instructions and/or `mix accrue.install` to apply the required Mailglass Postgres migrations (`mailglass_deliveries`, `mailglass_events`, `mailglass_suppressions`).

### Pipeline & Idempotency (MG)
- **MG-04**: Refactor `Accrue.Workers.Mailer` to build and dispatch via `Mailglass.deliver/1`, orchestrating dynamic assignment hydration and Multi-tenant PDF attachment logic before dispatch.
- **MG-05**: Implement database-level idempotency by passing an explicit `idempotency_key` to Mailglass messages, replacing the Oban `unique: [period: 60]` logic to prevent duplicate webhook dispatches.

### Template Porting (MG)
- **MG-06**: Port the Proof-of-Concept templates (`Accrue.Emails.Receipt` and `Accrue.Emails.PaymentFailed`) from MJML to `Mailglass.Mailable` using native Mailglass HEEx components.
- **MG-07**: Port the remaining 11 MJML templates in `priv/accrue/templates/emails/` to `Mailglass.Mailable` and completely remove the MJML compiler dependency.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| MG-01 | Phase 88 | Pending |
| MG-02 | Phase 88 | Pending |
| MG-03 | Phase 88 | Pending |
| MG-04 | Phase 89 | Pending |
| MG-05 | Phase 89 | Pending |
| MG-06 | Phase 89 | Pending |
| MG-07 | Phase 90 | Pending |

**Coverage:** v1.29 requirements **7** total · Mapped **7** · Unmapped **0** ✓
