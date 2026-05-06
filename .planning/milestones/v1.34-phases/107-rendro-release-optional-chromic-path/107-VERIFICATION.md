# Phase 107 Verification

Date: 2026-05-06
Plans: `107-01`, `107-02`

## Primary behavioral proof

### 1. Invoice renderer typed-error lane

Command:

```bash
cd accrue && mix test test/accrue/billing/pdf_test.exs --trace
```

Result: PASS

Evidence:
- `accrue/test/accrue/billing/pdf_test.exs`
- Finished in `0.4 seconds`
- `13 tests, 0 failures`

Behavior proven:
- Rendro remains the default invoice renderer and returns a real PDF binary without Chrome.
- The explicit `Accrue.InvoiceRenderer.ChromicPDF` lane now returns `%Accrue.Error.InvoiceRendererUnavailable{}` when ChromicPDF is not running.
- Intentional PDF disablement still returns `%Accrue.Error.PdfDisabled{}` rather than the new unavailable error.

### 2. Boot warning and mailer degradation lane

Command:

```bash
cd accrue && mix test test/accrue/application_boot_guards_test.exs test/accrue/webhook/default_handler_mailer_dispatch_test.exs --trace
```

Result: PASS

Evidence:
- `accrue/test/accrue/application_boot_guards_test.exs`
- `accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs`
- Finished in `0.8 seconds`
- `18 tests, 0 failures`

Behavior proven:
- Boot warnings honor the `:invoice_pdf_adapter` / `:pdf_adapter` split and keep the migration-only warning narrow.
- Mailer dispatch treats `%Accrue.Error.InvoiceRendererUnavailable{adapter: Accrue.InvoiceRenderer.ChromicPDF}` as a terminal degrade-to-link path instead of a retry-shaped failure.
- Invoice mail flows still attach PDFs when rendering succeeds and fall back to hosted invoice URLs when rendering does not run.

## Supporting docs and release-truth proof

### 3. Narrow docs contract

Command:

```bash
rg -n "explicit compatibility path|InvoiceRendererUnavailable|invoice_pdf_adapter|pdf_adapter|pdf_adapter_unavailable" accrue/guides/pdf.md accrue/guides/configuration.md accrue/guides/telemetry.md accrue/guides/production-readiness.md
```

Result: PASS

Behavior proven:
- The docs describe ChromicPDF as an explicit compatibility path rather than an automatic fallback.
- The docs name `:invoice_pdf_adapter` as the invoice renderer switch and `:pdf_adapter` as the lower-level HTML seam.
- The typed unavailable error and `[:accrue, :ops, :pdf_adapter_unavailable]` telemetry contract are documented consistently with the implementation.

### 4. Rendro Hex dependency lane

Command:

```bash
cd accrue && mix deps.get && rg -n '\{:rendro, "~> 0\.1\.0"\}' mix.exs && ! rg -n 'path:\s*"../../rendro"' mix.exs && rg -n '"rendro": \{:hex, :rendro, "0\.1\.0"' mix.lock && mix deps.tree | rg 'rendro'
```

Result: PASS

Evidence:
- `accrue/mix.exs` contains `{:rendro, "~> 0.1.0"}`
- `accrue/mix.lock` contains a Hex-backed `rendro` `0.1.0` entry
- `mix deps.tree` reports `rendro ~> 0.1.0 (Hex package)`

Behavior proven:
- Accrue resolves Rendro from Hex at `~> 0.1.0`.
- The old `../../rendro` path dependency is no longer part of the active dependency contract.

### 5. Clean-checkout release-truth lane

Command:

```bash
bash scripts/ci/verify_rendro_hex_resolution.sh
```

Result: PASS

Evidence:
- The script cloned the repository into a temp directory.
- It applied the current workspace diff into the temp clone.
- It ran `mix deps.get` and verified `mix deps.tree` shows `rendro` as a Hex package.
- The script finished with `[verify_rendro_hex_resolution] ok`.

Behavior proven:
- Release proof no longer depends on a maintainer-local `../../rendro` checkout.
- The checked-in verification lane exercises public-registry resolution semantics from a clean checkout.

## Outcome

Phase 107 is verified for `PDF-06` and `PDF-07`.

Closed contracts:
- Optional Chromic invoice rendering is explicit, typed, observable, and migration-safe.
- Rendro now resolves from Hex with a checked-in clean-checkout proof lane.
