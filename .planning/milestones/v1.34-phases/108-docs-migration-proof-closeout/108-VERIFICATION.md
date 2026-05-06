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

Result: FAIL, but only on an out-of-scope planning contract the plan explicitly excluded

Observed output:

```text
[verify_package_docs] package docs verification failed: /Users/jon/projects/accrue/.planning/PROJECT.md is missing: gateway subscription core
```

Interpretation:
- This failure did not point at `accrue/guides/custom_pdf_adapter.md`, `accrue/guides/email.md`, or `accrue/guides/branding.md`.
- Per the 108-02 execution constraints, `.planning/PROJECT.md` remained out of scope and was not changed here.

### HexDocs build

Command:

```bash
cd accrue && MIX_ENV=dev mix docs --warnings-as-errors
```

Result: FAIL on pre-existing doc warnings outside this plan's owned files

Observed warnings:
- `README.md` references `../RELEASING.md#post-1-0-cadence-maintainer-intent`, but that file anchor does not resolve.
- `guides/testing.md:128` references hidden module `Accrue.InvoiceRenderer.Test`.

Interpretation:
- The advanced-guide edits from Plan `108-02` did not introduce the reported warnings.
- The command still serves as supporting evidence that no new failure surfaced from the plan-owned guide changes.

## Rendro Hex release-truth proof

Command:

```bash
bash scripts/ci/verify_rendro_hex_resolution.sh
```

Result: inherited prerequisite evidence from Phase 107, not rerun in Plan `108-02`

Why inherited:
- This plan did not modify `accrue/mix.exs`
- This plan did not modify `accrue/mix.lock`
- This plan did not modify `RELEASING.md`
- This plan did not modify `scripts/ci/verify_rendro_hex_resolution.sh`

Source artifact:
- `.planning/milestones/v1.34-phases/107-rendro-release-optional-chromic-path/107-02-SUMMARY.md`

Inherited proof statement:
- Phase 107 already proved that `accrue` resolves Rendro from Hex at `~> 0.1.0` and that `bash scripts/ci/verify_rendro_hex_resolution.sh` passes against the Hex-backed handoff.
