# Phase 108 Verification

Date: 2026-05-06
Plan: `108-02`

## Primary behavioral proof

### 1. Invoice renderer lane

Command:

```bash
cd accrue && mix test test/accrue/billing/pdf_test.exs
```

Result: PASS

Evidence:
- `accrue/test/accrue/billing/pdf_test.exs`
- Finished in `0.4 seconds`
- `13 tests, 0 failures`

Behavior proven:
- Rendro-backed invoice rendering returns a real PDF binary without Chrome.
- Null and explicit `Accrue.InvoiceRenderer.ChromicPDF` unavailable-path behavior stay typed and non-ambiguous.

### 2. Invoice email / attachment lane

Command:

```bash
cd accrue && mix test test/accrue/webhook/default_handler_mailer_dispatch_test.exs
```

Result: PASS

Evidence:
- `accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs`
- Finished in `0.6 seconds`
- `10 tests, 0 failures`

Behavior proven:
- Invoice-carrying mail flows attach PDFs when rendering succeeds.
- Mail flows fall back to the hosted invoice URL when PDF rendering does not run.
- Mailglass dispatch keeps the explicit idempotency-key contract.

### 3. Admin invoice open / action lane

Command:

```bash
cd accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs
```

Result: PASS after clearing a local dependency blocker with `cd accrue_admin && mix deps.get`

Evidence:
- `accrue_admin/test/accrue_admin/live/invoice_live_test.exs`
- Initial run failed because `rendro` was not yet fetched in `accrue_admin`:

```text
Unchecked dependencies for environment test:
* rendro (Hex package)
  the dependency is not available, run "mix deps.get"
```

- Rerun finished in `0.4 seconds`
- `3 tests, 0 failures`

Behavior proven:
- Admin invoice LiveView still opens invoice detail successfully on the Hex-backed dependency set.
- Step-up and invoice action flows remain intact after the Rendro default-path cutover.

## Supporting docs proof

### Package-doc contract check

Command:

```bash
bash scripts/ci/verify_package_docs.sh
```

Result: PASS

Evidence:
- `package docs verified for accrue 1.0.0 and accrue_admin 1.0.0`
- The supporting `.planning/PROJECT.md` wording contract was repaired during milestone closeout, and the verifier now passes without exceptions.

### HexDocs build

Command:

```bash
cd accrue && MIX_ENV=dev mix docs --warnings-as-errors
```

Result: PASS

Evidence:
- HexDocs generated successfully after removing the stale `RELEASING.md` file anchor from `accrue/README.md`.
- `guides/testing.md` now refers to the invoice renderer test adapter without linking a hidden module.

## Docs-to-runtime parity check

Because the docs verifier and HexDocs build did not exercise the new Phase 108
guide snippets directly, the final closeout also included a manual parity pass
against the live implementation:

- `accrue/lib/accrue/config.ex` for supported branding and mailer config keys
- `accrue/lib/accrue/invoices/components.ex` for invoice branding fields used at render time
- `accrue/lib/accrue/invoice_renderer/rendro.ex` for the Rendro invoice path
- `accrue/lib/accrue/workers/mailer.ex` for invoice attachment and fallback behavior

Result:
- Final Phase 108 docs only describe config keys and attachment behavior that
  exist in the checked-in implementation.
- No dedicated automated docs/config smoke test exists yet, so this parity check
  should be treated as manual closeout evidence rather than a new merge-blocking
  contract.

## Rendro Hex release-truth proof

Command:

```bash
bash scripts/ci/verify_rendro_hex_resolution.sh
```

Result: PASS

Evidence:
- The script reapplied the current workspace diff into a temp clone, ran `mix deps.get`, verified `mix deps.tree`, and finished with `[verify_rendro_hex_resolution] ok`.
- Closeout now has direct same-run evidence that the Hex-backed Rendro resolution lane still passes after the final docs and planning updates.
