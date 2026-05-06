# Phase 107: Rendro Release & Optional Chromic Path - Research

**Researched:** 2026-05-06
**Domain:** Optional ChromicPDF invoice fallback hardening and Rendro Hex release handoff
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** `:invoice_pdf_adapter` remains the only invoice-renderer switch. Rendro stays the default; `Accrue.InvoiceRenderer.ChromicPDF` is an explicit opt-in compatibility path.
- **D-02:** Do **not** introduce any automatic runtime fallback chain such as “try Rendro, then silently retry ChromicPDF.” Optional fallback is a docs/config choice, not hidden runtime magic.
- **D-03:** Public docs and API wording should describe Chromic as an explicit compatibility path for hosts that want the previous HTML/Chrome rendering model, not as an automatic backup lane.
- **D-04:** Adopt a layered typed-contract posture for stable misconfiguration: boot warnings for high-confidence bad setup, typed terminal runtime errors when the optional Chromic path is invoked incorrectly, and retries only for genuinely unknown or transient failures.
- **D-05:** Replace the bare `:chromic_pdf_not_started` invoice-path error with a typed `%Accrue.Error.*{}` struct so hosts can pattern-match cleanly and docs/runbooks can map directly to code behavior.
- **D-06:** Keep `%Accrue.Error.PdfDisabled{}` for intentional PDF disablement; reserve the new typed “unavailable/misconfigured Chromic path” error for explicit fallback-path setup failures.
- **D-07:** Emit low-cardinality ops telemetry whenever Accrue actually degrades behavior because the Chromic fallback path is unavailable, not only in one mailer-specific lane.
- **D-08:** Unknown renderer failures may still raise or bubble into retry-oriented worker failure paths; stable misconfiguration should not create ambiguous retries or retry storms.
- **D-09:** Replace `{:rendro, path: "../../rendro"}` with a published Hex dependency in `accrue/mix.exs`.
- **D-10:** Use a narrow pre-1.0 compatibility window: `{:rendro, "~> 0.1.0"}` rather than an exact pin or an overly broad `~> 0.1`.
- **D-11:** Keep Rendro outside Accrue's linked Release Please group. Rendro is an independent library with its own cadence; Accrue should consume it as a normal published Hex dependency.
- **D-12:** The release handoff order is: publish Rendro, confirm Hex availability from a clean environment, update/use the published Rendro version in Accrue, then run release verification that resolves Rendro from Hex rather than from a sibling checkout.
- **D-13:** Keep a hard split between `:invoice_pdf_adapter` and `:pdf_adapter`. The first owns invoice rendering; the second remains the lower-level HTML-to-PDF seam used by `Accrue.PDF` and by Chromic-backed HTML renderers.
- **D-14:** Do **not** add inference rules that let `:pdf_adapter` silently control invoice rendering when `:invoice_pdf_adapter` is unset.
- **D-15:** Add a migration-focused warning when a host explicitly configures `:pdf_adapter` but leaves `:invoice_pdf_adapter` unset, because that host is the most likely to assume the legacy invoice behavior still applies.
- **D-16:** Rewrite remaining docs/examples so normal install and invoice-rendering guidance show only the Rendro-first `:invoice_pdf_adapter` path. Reposition `:pdf_adapter` as an advanced HTML seam only.
- **D-17:** Planning and implementation should optimize for least surprise, explicit configuration, strong host-side pattern matching, and docs that let a maintainer pick the right path without reading source.
- **D-18:** Low-impact forks should be auto-resolved toward the coherent Rendro-first default unless a choice would materially change release safety, public contract semantics, or migration posture.

### Claude's Discretion
- Exact naming of the new typed Chromic-unavailable error struct, provided it fits the existing `Accrue.Error.*` taxonomy and clearly distinguishes intentional disablement from misconfiguration.
- Whether the existing telemetry event name remains for compatibility or a clearer successor is added, as long as the docs explain the mapping cleanly.
- Exact warning text and guide structure for the migration note about `:pdf_adapter` versus `:invoice_pdf_adapter`.
- Exact verification artifact shape for the Rendro-release handoff, provided it proves Hex-backed dependency truth from a clean checkout.

### Deferred Ideas (OUT OF SCOPE)
- Broad workflow-wide codification of the user's “deep synthesis + auto-resolve low-impact choices” preference beyond the existing `.planning/config.json` settings is outside Phase 107 scope. Current discuss config already partially encodes it.
- Larger migration and install-document rewrites belong to Phase 108; Phase 107 should only make the config/fallback/release contract honest enough for that docs phase to build on.
- Any reconsideration of the invoice-renderer seam itself, automatic multi-engine fallback, or linked Rendro/Accrue monorepo release choreography is explicitly out of scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PDF-06 | System MUST keep ChromicPDF available as an explicit optional fallback path with clear configuration and failure messaging. | Use `:invoice_pdf_adapter` as the only invoice switch, replace the atom misconfig result with a typed error, keep boot warnings host-focused, and extend ops telemetry beyond the current mailer-only degradation branch. [VERIFIED: `.planning/phases/107-rendro-release-optional-chromic/107-CONTEXT.md`, `accrue/lib/accrue/invoices.ex`, `accrue/lib/accrue/application.ex`, `accrue/lib/accrue/workers/mailer.ex`, `accrue/guides/pdf.md`] |
| PDF-07 | System MUST publish the required Rendro version to Hex and replace the temporary local path dependency before the milestone closes. | Replace `{:rendro, path: "../../rendro"}` with `{:rendro, "~> 0.1.0"}`, verify that `rendro` `0.1.0` is already published on Hex, and require a clean-checkout dependency proof lane before closeout. [VERIFIED: `accrue/mix.exs`] [CITED: https://hex.pm/api/packages/rendro] |
</phase_requirements>

## Summary

Phase 107 is not about inventing a second renderer path. The repo already has the correct high-level architecture for this phase: `Accrue.InvoiceRenderer.ChromicPDF` exists as an explicit compatibility adapter, `:invoice_pdf_adapter` is the invoice-facing config key, Rendro is the default, and `:pdf_adapter` remains the lower-level HTML seam. [VERIFIED: `accrue/lib/accrue/invoice_renderer/chromic_pdf.ex`, `accrue/lib/accrue/invoice_renderer.ex`, `accrue/lib/accrue/config.ex`, `accrue/config/config.exs`]

The real planning work splits into two tracks. First, harden the optional Chromic path so stable misconfiguration is typed, documented, and observable instead of leaking as a bare atom or a retry-shaped failure. Today `Accrue.Invoices.render_invoice_pdf/2` still returns `{:error, :chromic_pdf_not_started}` for the explicit Chromic path, while only the mailer degradation branch emits `[:accrue, :ops, :pdf_adapter_unavailable]`. [VERIFIED: `accrue/lib/accrue/invoices.ex`, `accrue/lib/accrue/workers/mailer.ex`, `accrue/lib/accrue/telemetry/ops.ex`, `accrue/guides/telemetry.md`]

Second, finish the dependency handoff from local development convenience to real release truth. Accrue still consumes Rendro as `{:rendro, path: "../../rendro"}`, but Rendro `0.1.0` was published to Hex on May 3, 2026 and Hex already advertises the exact Mix tuple `{:rendro, "~> 0.1.0"}`. [VERIFIED: `accrue/mix.exs`] [CITED: https://hex.pm/api/packages/rendro]

One current gap is already visible in the test suite: `Accrue.ApplicationBootGuardsTest` still mutates `:pdf_adapter`, but `warn_pdf_adapter_unavailable/0` now reads `:invoice_pdf_adapter`, so the warning contract is not actually under test. Running `mix test test/accrue/billing/pdf_test.exs test/accrue/application_boot_guards_test.exs test/accrue/config_test.exs` on 2026-05-06 produced 56 tests with 1 failure in that boot-guard case. [VERIFIED: `accrue/test/accrue/application_boot_guards_test.exs`, `accrue/lib/accrue/application.ex`, local command run 2026-05-06]

**Primary recommendation:** plan Phase 107 as two sequential slices: first normalize the optional Chromic contract around a typed error + warning + telemetry + migration warning package, then complete the Rendro Hex handoff with a clean-checkout verification artifact that proves `mix deps.get` resolves Rendro from Hex rather than from a sibling directory. [VERIFIED: `.planning/phases/107-rendro-release-optional-chromic/107-CONTEXT.md`, `accrue/lib/accrue/application.ex`, `accrue/mix.exs`] [CITED: https://hex.pm/api/packages/rendro]

## Project Constraints (from CLAUDE.md)

- Accrue targets Elixir `1.17+`, OTP `27+`, Phoenix `1.8+`, Ecto `3.12+`, and PostgreSQL `14+`. [VERIFIED: `CLAUDE.md`]
- `chromic_pdf` is still part of the required dependency set even though the normal invoice path is Rendro-first. This phase should keep the dependency and harden its optional invoice-facing use, not remove it. [VERIFIED: `CLAUDE.md`, `accrue/mix.exs`]
- Host-owned infrastructure is a locked project pattern: Accrue must not start ChromicPDF, Oban, Repo, or Finch itself. [VERIFIED: `CLAUDE.md`, `accrue/lib/accrue/application.ex`, `RELEASING.md`]
- Public entry points are expected to emit telemetry, and ops-grade signals should remain low-cardinality. [VERIFIED: `CLAUDE.md`, `accrue/lib/accrue/telemetry/ops.ex`, `accrue/guides/telemetry.md`]
- Security-sensitive guidance must keep webhook signature verification mandatory and avoid leaking sensitive processor data into logs; phase work should preserve that posture in any new warnings or release proof. [VERIFIED: `CLAUDE.md`]
- The repo is a monorepo with independent Hex packages and a linked Release Please group for `accrue`, `accrue_admin`, and `accrue_portal`; Rendro should remain outside that group. [VERIFIED: `CLAUDE.md`, `release-please-config.json`, `.planning/phases/107-rendro-release-optional-chromic/107-CONTEXT.md`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Invoice renderer selection | API / backend | Docs / config | `Accrue.Invoices.render_invoice_pdf/2` resolves `Accrue.InvoiceRenderer.impl/0`, so invoice path ownership sits in core backend config, not in the admin UI or mailer. [VERIFIED: `accrue/lib/accrue/invoices.ex`, `accrue/lib/accrue/invoice_renderer.ex`] |
| Optional Chromic availability warning | Backend boot validation | Operator docs | The host must supervise ChromicPDF, and `Accrue.Application.warn_pdf_adapter_unavailable/0` is the existing warning hook. [VERIFIED: `accrue/lib/accrue/application.ex`] [CITED: https://hexdocs.pm/chromic_pdf/ChromicPDF.html] |
| Stable fallback-path runtime failure | API / backend | Worker retry policy | The invoice facade should return a typed terminal error for stable Chromic misconfig so callers and workers can pattern-match cleanly. [VERIFIED: `.planning/phases/107-rendro-release-optional-chromic/107-CONTEXT.md`, `accrue/lib/accrue/invoices.ex`, `accrue/lib/accrue/workers/mailer.ex`] |
| Degradation telemetry | Backend ops layer | Mailer / admin callers | Current first-party emit happens in the mailer PDF fallback branch; Phase 107 should make the signal invoice-path-wide without increasing cardinality. [VERIFIED: `accrue/lib/accrue/workers/mailer.ex`, `accrue/lib/accrue/telemetry/ops.ex`, `accrue/guides/telemetry.md`] |
| Rendro dependency truth | Package / release layer | CI verification | `accrue/mix.exs` still points at a local sibling, while release closeout requires published Hex resolution. [VERIFIED: `accrue/mix.exs`, `RELEASING.md`] [CITED: https://hex.pm/api/packages/rendro] |
| Migration warning for legacy hosts | Backend boot validation | Docs | The dangerous case is a host that still sets `:pdf_adapter` and assumes invoice rendering follows it; warning logic belongs near other boot-time config checks. [VERIFIED: `.planning/phases/107-rendro-release-optional-chromic/107-CONTEXT.md`, `accrue/lib/accrue/application.ex`, `accrue/lib/accrue/config.ex`] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `rendro` | `0.1.0` | Default invoice PDF engine consumed from Hex instead of a local path. [CITED: https://hex.pm/api/packages/rendro] | Hex already publishes `{:rendro, "~> 0.1.0"}`, which matches the locked Phase 107 compatibility window and removes sibling-checkout coupling. [CITED: https://hex.pm/api/packages/rendro] |
| `chromic_pdf` | `1.17.1` | Explicit compatibility renderer for hosts that want the legacy HTML/Chrome invoice path. [CITED: https://hex.pm/api/packages/chromic_pdf] | The library remains the official first-party HTML-to-PDF fallback and its docs still require host-supervised startup and pool sizing. [CITED: https://hexdocs.pm/chromic_pdf/ChromicPDF.html] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `telemetry` | `~> 1.3` | Emit low-cardinality ops signals when the optional fallback path degrades. [VERIFIED: `accrue/mix.exs`, `accrue/lib/accrue/telemetry/ops.ex`] | Use for stable misconfiguration and degradation signals; do not invent per-caller bespoke metrics. [VERIFIED: `accrue/guides/telemetry.md`] |
| `oban` | `~> 2.21` | Preserve retry semantics by treating stable Chromic misconfig as terminal and unknown renderer failures as retry-worthy. [VERIFIED: `accrue/mix.exs`, `accrue/lib/accrue/workers/mailer.ex`] | Use anywhere worker behavior depends on the error taxonomy from the invoice renderer. [VERIFIED: `accrue/lib/accrue/workers/mailer.ex`] |
| `nimble_options` | `~> 1.1` | Keep adapter key boundaries explicit in config and boot-time validation. [VERIFIED: `accrue/mix.exs`, `accrue/lib/accrue/config.ex`] | Use for schema-backed config truth; Phase 107 warnings should complement, not replace, the existing config schema. [VERIFIED: `accrue/lib/accrue/config.ex`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `{:rendro, "~> 0.1.0"}` | keep `{:rendro, path: "../../rendro"}` | Local paths are convenient for development but cannot satisfy milestone-close release truth from a clean checkout. [VERIFIED: `accrue/mix.exs`, `RELEASING.md`] [CITED: https://hex.pm/api/packages/rendro] |
| Explicit `Accrue.InvoiceRenderer.ChromicPDF` opt-in | Automatic fallback chain | Automatic fallback would violate locked decision D-02 and would hide host misconfiguration behind surprising runtime behavior. [VERIFIED: `.planning/phases/107-rendro-release-optional-chromic/107-CONTEXT.md`] |
| Typed `%Accrue.Error.*{}` for stable Chromic misconfig | Bare atom `:chromic_pdf_not_started` | Atoms are easy internally but poor for host-side pattern matching, docs mapping, and worker retry branching. [VERIFIED: `.planning/phases/107-rendro-release-optional-chromic/107-CONTEXT.md`, `accrue/lib/accrue/invoices.ex`] |

**Installation:**
```bash
cd accrue
mix deps.unlock rendro
mix deps.get
```

**Version verification:** before changing `mix.exs`, verify published versions from the registry:
```bash
curl -s https://hex.pm/api/packages/rendro
curl -s https://hex.pm/api/packages/chromic_pdf
```
Rendro `0.1.0` was published on 2026-05-03 and ChromicPDF `1.17.1` was published on 2026-03-19. [CITED: https://hex.pm/api/packages/rendro] [CITED: https://hex.pm/api/packages/chromic_pdf]

## Architecture Patterns

### System Architecture Diagram

```text
Invoice request / mailer attachment / admin download
            |
            v
Accrue.Invoices.render_invoice_pdf/2
            |
            v
resolve :invoice_pdf_adapter ------------------------------+
            |                                              |
            | Rendro (default)                             | Chromic opt-in
            v                                              v
Accrue.InvoiceRenderer.Rendro                  ensure host ChromicPDF is available
            |                                              |
            v                                              +--> boot warning if configured + absent
native PDF binary                                           +--> typed terminal error if invoked + absent
            |                                              |
            +----------------------+-----------------------+
                                   |
                                   v
                     caller behavior / worker behavior
                                   |
                  +----------------+------------------+
                  |                                   |
                  v                                   v
         attach/download succeeds            degrade predictably + emit ops telemetry

Release handoff path:
local path dep in accrue/mix.exs -> publish Rendro on Hex -> clean checkout resolves Hex dep -> milestone close
```

### Recommended Project Structure

```text
accrue/
├── lib/accrue/
│   ├── application.ex              # boot warnings and host-owned infra checks
│   ├── invoices.ex                 # typed invoice render/store/fetch facade
│   ├── invoice_renderer/           # Rendro + Chromic + Null implementations
│   └── workers/mailer.ex           # retry/degrade behavior for PDF attachments
├── guides/
│   ├── pdf.md                      # Rendro-first story and Chromic fallback
│   ├── configuration.md            # adapter key boundaries
│   ├── custom_pdf_adapter.md       # advanced HTML seam, not invoice default
│   └── telemetry.md                # ops event contract
└── test/accrue/
    ├── billing/pdf_test.exs        # invoice facade and adapter contract
    ├── application_boot_guards_test.exs
    └── webhook/default_handler_mailer_dispatch_test.exs
```

### Pattern 1: Typed Optional-Adapter Failure
**What:** Keep boot-time warning, runtime typed error, and caller degradation behavior as three separate layers. [VERIFIED: `.planning/phases/107-rendro-release-optional-chromic/107-CONTEXT.md`, `accrue/lib/accrue/application.ex`, `accrue/lib/accrue/workers/mailer.ex`]

**When to use:** Any stable Chromic opt-in misconfiguration such as “configured Chromic invoice adapter but host did not start ChromicPDF.” [VERIFIED: `accrue/lib/accrue/application.ex`, `accrue/lib/accrue/invoices.ex`]

**Example:**
```elixir
# Source: local code + official ChromicPDF startup docs
config :accrue, :invoice_pdf_adapter, Accrue.InvoiceRenderer.ChromicPDF

children = [
  MyApp.Repo,
  {ChromicPDF, on_demand: true}
]
```
[VERIFIED: `accrue/guides/pdf.md`] [CITED: https://hexdocs.pm/chromic_pdf/ChromicPDF.html]

### Pattern 2: Clean-Checkout Hex Handoff
**What:** Prove the release closes on registry truth, not on a maintainer’s sibling checkout. [VERIFIED: `.planning/phases/107-rendro-release-optional-chromic/107-CONTEXT.md`, `RELEASING.md`, `accrue/mix.exs`] [CITED: https://hex.pm/api/packages/rendro]

**When to use:** Any package release phase replacing a local path dependency with a published Hex package. [VERIFIED: `RELEASING.md`]

**Example:**
```elixir
# Source: Hex package metadata
{:rendro, "~> 0.1.0"}
```
[CITED: https://hex.pm/api/packages/rendro]

### Anti-Patterns to Avoid

- **Silent fallback chain:** do not “try Rendro, then silently retry ChromicPDF”; this is explicitly out of bounds for the phase. [VERIFIED: `.planning/phases/107-rendro-release-optional-chromic/107-CONTEXT.md`]
- **Key inference between seams:** do not let `:pdf_adapter` implicitly drive invoice rendering. [VERIFIED: `.planning/phases/107-rendro-release-optional-chromic/107-CONTEXT.md`, `accrue/lib/accrue/config.ex`]
- **Atom-only misconfig contract:** do not keep `:chromic_pdf_not_started` as the host-facing runtime contract once a typed error exists. [VERIFIED: `.planning/phases/107-rendro-release-optional-chromic/107-CONTEXT.md`, `accrue/lib/accrue/invoices.ex`]
- **Local-path release proof:** do not close the milestone on tests that only pass with `../../rendro` present on the maintainer machine. [VERIFIED: `accrue/mix.exs`, `RELEASING.md`] [CITED: https://hex.pm/api/packages/rendro]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Optional fallback selection | hidden multi-engine retry logic | explicit `:invoice_pdf_adapter` opt-in | Hidden retries violate the locked behavior contract and make operator diagnosis worse. [VERIFIED: `.planning/phases/107-rendro-release-optional-chromic/107-CONTEXT.md`] |
| Browser supervision | custom Accrue-managed Chrome lifecycle | host-supervised `ChromicPDF` child | Official ChromicPDF startup expects supervision-tree ownership in the host app, matching Accrue’s existing empty-supervisor pattern. [VERIFIED: `accrue/lib/accrue/application.ex`] [CITED: https://hexdocs.pm/chromic_pdf/ChromicPDF.html] |
| Release truth | ad hoc maintainer machine checks | clean-checkout Hex resolution proof | Release closeout must prove public consumption semantics, not local workspace convenience. [VERIFIED: `RELEASING.md`, `accrue/mix.exs`] [CITED: https://hex.pm/api/packages/rendro] |
| Ops event sprawl | per-caller bespoke telemetry names | reuse or compatibly extend `[:accrue, :ops, :pdf_adapter_unavailable]` | Existing metrics/docs inventory already know about this event, so compatibility should be preserved unless there is a strong reason to rename. [VERIFIED: `accrue/lib/accrue/telemetry/ops.ex`, `accrue/test/support/telemetry_ops_inventory.ex`, `accrue/guides/telemetry.md`] |

**Key insight:** Phase 107 is about tightening existing seams, not about adding a smarter renderer. The highest-value work is contract honesty: one switch, one typed misconfig story, one ops signal family, and one registry-backed dependency truth. [VERIFIED: `.planning/phases/107-rendro-release-optional-chromic/107-CONTEXT.md`, `accrue/mix.exs`]

## Common Pitfalls

### Pitfall 1: Testing the Wrong Config Key
**What goes wrong:** Tests mutate `:pdf_adapter` while the invoice path now reads `:invoice_pdf_adapter`, so they stop proving the behavior they claim to cover. [VERIFIED: `accrue/test/accrue/application_boot_guards_test.exs`, `accrue/lib/accrue/application.ex`]

**Why it happens:** The repo still contains legacy PDF-seam muscle memory from the pre-Rendro invoice path. [VERIFIED: `accrue/guides/custom_pdf_adapter.md`, `accrue/test/accrue/application_boot_guards_test.exs`]

**How to avoid:** Audit every invoice-facing test, guide, and warning path for the new seam boundary before adding new code. [VERIFIED: `.planning/phases/107-rendro-release-optional-chromic/107-CONTEXT.md`, `accrue/lib/accrue/config.ex`]

**Warning signs:** The current test lane already shows this failure: `warn_pdf_adapter_unavailable/0 warns when queue concurrency > pool size` is green, but the PDF-adapter warning case does not log because the test sets the wrong env key. [VERIFIED: local command run 2026-05-06, `accrue/test/accrue/application_boot_guards_test.exs`]

### Pitfall 2: Stable Misconfig Masquerading as Retryable Failure
**What goes wrong:** A host opts into ChromicPDF without starting ChromicPDF and gets behavior that looks transient instead of terminal. [VERIFIED: `accrue/lib/accrue/invoices.ex`, `accrue/lib/accrue/workers/mailer.ex`]

**Why it happens:** The current invoice facade returns a bare atom, and only the mailer path has first-party degradation telemetry today. [VERIFIED: `accrue/lib/accrue/invoices.ex`, `accrue/lib/accrue/workers/mailer.ex`]

**How to avoid:** Introduce a typed `%Accrue.Error.*{}` for Chromic unavailability, treat it as terminal in worker lanes, and document it next to `%Accrue.Error.PdfDisabled{}`. [VERIFIED: `.planning/phases/107-rendro-release-optional-chromic/107-CONTEXT.md`, `accrue/lib/accrue/errors.ex`, `accrue/guides/pdf.md`]

**Warning signs:** Runtime branches that match only on `:chromic_pdf_not_started` or default all non-`PdfDisabled` errors into `RenderFailed` retries. [VERIFIED: `accrue/lib/accrue/workers/mailer.ex`, `accrue/lib/accrue/invoices.ex`]

### Pitfall 3: Closing on Local Dependency Truth
**What goes wrong:** Phase verification passes only because the maintainer has `../../rendro` checked out locally. [VERIFIED: `accrue/mix.exs`]

**Why it happens:** Path deps hide the difference between local development convenience and public installability. [VERIFIED: `accrue/mix.exs`, `RELEASING.md`]

**How to avoid:** Add a clean-checkout verification artifact that starts from a clone without the sibling repo and proves Hex resolution. [VERIFIED: `.planning/phases/107-rendro-release-optional-chromic/107-CONTEXT.md`, `RELEASING.md`] [CITED: https://hex.pm/api/packages/rendro]

**Warning signs:** Any proof step that depends on the filesystem path `../../rendro` or skips `mix deps.get` from a clean tree. [VERIFIED: `accrue/mix.exs`] 

### Pitfall 4: Blurring `:invoice_pdf_adapter` and `:pdf_adapter` in Docs
**What goes wrong:** Hosts keep configuring `:pdf_adapter` and assume invoice rendering still follows it. [VERIFIED: `.planning/phases/107-rendro-release-optional-chromic/107-CONTEXT.md`, `accrue/guides/configuration.md`, `accrue/guides/custom_pdf_adapter.md`]

**Why it happens:** The old HTML seam still exists and the advanced custom-adapter docs remain valid, so wording drift is easy. [VERIFIED: `accrue/guides/pdf.md`, `accrue/guides/custom_pdf_adapter.md`]

**How to avoid:** Put the migration warning in boot validation for legacy-host detection and keep invoice docs Rendro-first while moving `:pdf_adapter` guidance into “advanced HTML seam” language. [VERIFIED: `.planning/phases/107-rendro-release-optional-chromic/107-CONTEXT.md`, `accrue/lib/accrue/application.ex`, `accrue/guides/pdf.md`]

**Warning signs:** Configuration snippets that mention `:pdf_adapter` without also clarifying that invoice rendering is controlled by `:invoice_pdf_adapter`. [VERIFIED: `accrue/guides/configuration.md`, `accrue/guides/email.md`, `accrue/guides/custom_pdf_adapter.md`]

## Code Examples

Verified patterns from official sources and the local codebase:

### Explicit Chromic Opt-In
```elixir
config :accrue, :invoice_pdf_adapter, Accrue.InvoiceRenderer.ChromicPDF
```
[VERIFIED: `accrue/guides/pdf.md`, `accrue/lib/accrue/config.ex`]

### Host-Supervised ChromicPDF
```elixir
children = [
  MyApp.Repo,
  {ChromicPDF, on_demand: true},
  MyAppWeb.Endpoint
]
```
[VERIFIED: `accrue/guides/pdf.md`] [CITED: https://hexdocs.pm/chromic_pdf/ChromicPDF.html]

### Published Rendro Dependency
```elixir
{:rendro, "~> 0.1.0"}
```
[CITED: https://hex.pm/api/packages/rendro]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Invoice rendering implicitly lived on the legacy HTML PDF seam. [VERIFIED: older repo docs still describe this shape in places such as `guides/custom_pdf_adapter.md`] | `:invoice_pdf_adapter` now owns invoice rendering and `:pdf_adapter` is the lower-level HTML seam. [VERIFIED: `accrue/lib/accrue/config.ex`, `accrue/lib/accrue/invoice_renderer.ex`, `accrue/guides/pdf.md`] | Active milestone opened on 2026-05-06 and Phase 106 summary says the Rendro-first seam is already landed. [VERIFIED: `.planning/STATE.md`, `.planning/phases/106-invoice-renderer-seam-rendro-default/106-02-SUMMARY.md`] | Phase 107 should harden the new boundary, not reopen it. [VERIFIED: `.planning/phases/107-rendro-release-optional-chromic/107-CONTEXT.md`] |
| Accrue consumes Rendro from a local sibling checkout. [VERIFIED: `accrue/mix.exs`] | Rendro is publicly available on Hex as `0.1.0` with a published Mix tuple for `~> 0.1.0`. [CITED: https://hex.pm/api/packages/rendro] | Rendro was published on 2026-05-03. [CITED: https://hex.pm/api/packages/rendro] | Milestone closeout can now move from local-path truth to registry truth. [VERIFIED: `.planning/phases/107-rendro-release-optional-chromic/107-CONTEXT.md`, `RELEASING.md`] |
| Stable Chromic misconfig surfaces as the atom `:chromic_pdf_not_started`. [VERIFIED: `accrue/lib/accrue/invoices.ex`] | Locked decision is to expose a typed `%Accrue.Error.*{}` for that stable misconfig class while keeping `%Accrue.Error.PdfDisabled{}` for intentional disablement. [VERIFIED: `.planning/phases/107-rendro-release-optional-chromic/107-CONTEXT.md`, `accrue/lib/accrue/errors.ex`] | Planned in Phase 107. [VERIFIED: `.planning/REQUIREMENTS.md`, `.planning/phases/107-rendro-release-optional-chromic/107-CONTEXT.md`] | Host pattern matching, worker retry control, and docs/runbooks all become clearer. [VERIFIED: `.planning/phases/107-rendro-release-optional-chromic/107-CONTEXT.md`] |

**Deprecated/outdated:**
- Relying on `:pdf_adapter` as the invoice-renderer switch is outdated for the current invoice path. [VERIFIED: `accrue/lib/accrue/config.ex`, `accrue/guides/pdf.md`, `accrue/guides/configuration.md`]
- Closing release proof on a local Rendro checkout is outdated once the Hex package exists. [VERIFIED: `accrue/mix.exs`, `RELEASING.md`] [CITED: https://hex.pm/api/packages/rendro]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|

All material claims in this research were verified from the repo, local command output, or official package/documentation sources during this session. [VERIFIED: current research session]

## Open Questions (RESOLVED)

1. **Should the existing `[:accrue, :ops, :pdf_adapter_unavailable]` event name be preserved or aliased?**
   - Resolution: preserve the existing event name for compatibility and broaden its emission coverage to the invoice-path degradation cases defined in Phase 107 rather than introducing an invoice-specific successor in this slice. [VERIFIED: `.planning/milestones/v1.34-phases/107-rendro-release-optional-chromic-path/107-01-PLAN.md`, `accrue/guides/telemetry.md`, `accrue/test/support/telemetry_ops_inventory.ex`]

2. **Where should the clean-checkout Hex proof live?**
   - Resolution: use a reusable checked-in script at `scripts/ci/verify_rendro_hex_resolution.sh`, with `RELEASING.md` pointing to it as the required PDF-07 proof lane before milestone closeout. [VERIFIED: `.planning/milestones/v1.34-phases/107-rendro-release-optional-chromic-path/107-02-PLAN.md`, `RELEASING.md`]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | package build, tests, dependency resolution | ✓ | `1.19.5` | — [VERIFIED: local `elixir --version` 2026-05-06] |
| Erlang/OTP | Elixir runtime | ✓ | `28` | — [VERIFIED: local `elixir --version` 2026-05-06] |
| Mix | deps/test/release verification | ✓ | `1.19.5` | — [VERIFIED: local `mix --version` 2026-05-06] |
| Git | clean-checkout Hex proof | ✓ | `2.41.0` | — [VERIFIED: local `git --version` 2026-05-06] |
| curl | Hex API verification | ✓ | `8.7.1` | use browser/web lookup [VERIFIED: local `curl --version` 2026-05-06] |
| Chromium | optional Chromic smoke or host parity checks | ✓ | version not probed, binary present at `/opt/homebrew/bin/chromium` | skip live Chromic smoke and keep test-adapter proof [VERIFIED: local `command -v chromium` 2026-05-06] |
| GitHub CLI | optional release PR / workflow inspection | ✓ | `2.89.0` | GitHub web UI / manual verification [VERIFIED: local `gh --version` 2026-05-06] |
| Hex registry access | Rendro publish proof and dependency resolution | ✓ | `rendro` `0.1.0` reachable | none for public-release closeout [CITED: https://hex.pm/api/packages/rendro] |

**Missing dependencies with no fallback:**
- None identified. [VERIFIED: local environment audit 2026-05-06]

**Missing dependencies with fallback:**
- Chromium version was not probed, but its presence is enough for optional smoke coverage; first-party tests already avoid requiring Chrome in the deterministic lane. [VERIFIED: local environment audit 2026-05-06, `accrue/test/accrue/billing/pdf_test.exs`]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Ecto sandbox and Oban manual testing. [VERIFIED: `accrue/test/test_helper.exs`, `accrue_admin/test/test_helper.exs`] |
| Config file | `accrue/test/test_helper.exs`, `accrue_admin/test/test_helper.exs`. [VERIFIED: repo files] |
| Quick run command | `cd accrue && mix test test/accrue/billing/pdf_test.exs test/accrue/application_boot_guards_test.exs test/accrue/webhook/default_handler_mailer_dispatch_test.exs` [VERIFIED: local command runs 2026-05-06] |
| Full suite command | `cd accrue && mix test.all && cd ../accrue_admin && mix test` [VERIFIED: `accrue/mix.exs`, `accrue_admin/test/test_helper.exs`] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PDF-06 | Explicit Chromic opt-in remains available, warns clearly when unsupervised, and degrades with typed terminal behavior instead of ambiguous retries. [VERIFIED: `.planning/REQUIREMENTS.md`, `.planning/phases/107-rendro-release-optional-chromic/107-CONTEXT.md`] | unit + integration | `cd accrue && mix test test/accrue/billing/pdf_test.exs test/accrue/application_boot_guards_test.exs test/accrue/webhook/default_handler_mailer_dispatch_test.exs` | ✅ existing files, but boot-guard assertions need Phase 107 updates. [VERIFIED: local command runs 2026-05-06] |
| PDF-07 | Accrue resolves Rendro from Hex, not from `../../rendro`, in a clean checkout. [VERIFIED: `.planning/REQUIREMENTS.md`, `accrue/mix.exs`] | release / integration | `tmpdir=$(mktemp -d) && git clone . \"$tmpdir\" && cd \"$tmpdir/accrue\" && mix deps.get && mix deps.tree | rg rendro` | ❌ Wave 0 proof script / artifact missing. [ASSUMED] |

### Sampling Rate

- **Per task commit:** `cd accrue && mix test test/accrue/billing/pdf_test.exs test/accrue/application_boot_guards_test.exs test/accrue/webhook/default_handler_mailer_dispatch_test.exs` [VERIFIED: local command runs 2026-05-06]
- **Per wave merge:** `cd accrue && mix test.all` plus `cd ../accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs` when admin download behavior is touched. [VERIFIED: `accrue/mix.exs`, local command run 2026-05-06]
- **Phase gate:** full deterministic suite green and one clean-checkout Hex proof captured before `/gsd-verify-work`. [VERIFIED: `.planning/phases/107-rendro-release-optional-chromic/107-CONTEXT.md`, `RELEASING.md`] [ASSUMED]

### Wave 0 Gaps

- [ ] `accrue/test/accrue/application_boot_guards_test.exs` — switch stale `:pdf_adapter` setup to `:invoice_pdf_adapter` and add the new migration-warning scenario for hosts that set only `:pdf_adapter`. [VERIFIED: `accrue/test/accrue/application_boot_guards_test.exs`, `accrue/lib/accrue/application.ex`, local command run 2026-05-06]
- [ ] `accrue/test/accrue/billing/pdf_test.exs` — replace the atom assertion with the planned typed Chromic-unavailable error contract. [VERIFIED: `accrue/test/accrue/billing/pdf_test.exs`, `.planning/phases/107-rendro-release-optional-chromic/107-CONTEXT.md`]
- [ ] New release-handoff verification artifact — no current checked-in script proves Hex-backed Rendro resolution from a clean checkout. [VERIFIED: repo inspection 2026-05-06, `RELEASING.md`, `accrue/mix.exs`] [ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase 107 does not change auth flows. [VERIFIED: phase scope in `.planning/REQUIREMENTS.md`] |
| V3 Session Management | no | No session-layer behavior is in scope. [VERIFIED: phase scope in `.planning/REQUIREMENTS.md`] |
| V4 Access Control | no | The phase does not introduce new authorization decisions; it hardens renderer config/release behavior. [VERIFIED: phase scope in `.planning/REQUIREMENTS.md`] |
| V5 Input Validation | yes | Continue using `NimbleOptions`-backed config boundaries and explicit adapter keys; add warnings for risky-but-valid legacy host setup. [VERIFIED: `accrue/lib/accrue/config.ex`, `.planning/phases/107-rendro-release-optional-chromic/107-CONTEXT.md`] |
| V6 Cryptography | no | No crypto primitive or key-management change is part of this phase. [VERIFIED: phase scope in `.planning/REQUIREMENTS.md`] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| HTML/script injection through the optional Chromic path | Tampering | Keep invoice HTML on trusted HEEx/Phoenix escaping paths and follow ChromicPDF guidance to escape user data; do not broaden the HTML seam. [VERIFIED: `accrue/lib/accrue/invoice_renderer/chromic_pdf.ex`] [CITED: https://hexdocs.pm/chromic_pdf/ChromicPDF.html] |
| Retry storm from stable Chromic misconfiguration | Denial of service | Typed terminal error + low-cardinality ops telemetry + boot warning before first invoice job. [VERIFIED: `.planning/phases/107-rendro-release-optional-chromic/107-CONTEXT.md`, `accrue/lib/accrue/application.ex`, `accrue/lib/accrue/workers/mailer.ex`] |
| Local-path dependency shipping to users | Tampering / Supply chain | Replace path dep with Hex version constraint and prove clean-checkout dependency resolution before closeout. [VERIFIED: `accrue/mix.exs`, `RELEASING.md`] [CITED: https://hex.pm/api/packages/rendro] |

## Sources

### Primary (HIGH confidence)
- Local code and docs:
  - `accrue/lib/accrue/invoice_renderer.ex`
  - `accrue/lib/accrue/invoice_renderer/chromic_pdf.ex`
  - `accrue/lib/accrue/invoices.ex`
  - `accrue/lib/accrue/application.ex`
  - `accrue/lib/accrue/config.ex`
  - `accrue/lib/accrue/workers/mailer.ex`
  - `accrue/guides/pdf.md`
  - `accrue/guides/configuration.md`
  - `accrue/guides/custom_pdf_adapter.md`
  - `accrue/guides/telemetry.md`
  - `accrue/guides/operator-runbooks.md`
  - `accrue/mix.exs`
  - `RELEASING.md`
  - `release-please-config.json`
- Phase context and requirements:
  - `.planning/REQUIREMENTS.md`
  - `.planning/STATE.md`
  - `.planning/phases/107-rendro-release-optional-chromic/107-CONTEXT.md`
  - `.planning/phases/106-invoice-renderer-seam-rendro-default/106-RESEARCH.md`
  - `.planning/phases/106-invoice-renderer-seam-rendro-default/106-02-SUMMARY.md`
- Official package / docs:
  - https://hex.pm/api/packages/rendro
  - https://hex.pm/api/packages/chromic_pdf
  - https://hexdocs.pm/chromic_pdf/ChromicPDF.html

### Secondary (MEDIUM confidence)
- https://hex.pm/packages/rendro — human-readable package page confirming publish date and HexDocs presence. [CITED: https://hex.pm/packages/rendro]

### Tertiary (LOW confidence)
- None. [VERIFIED: current research session]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - package versions and publish dates were verified directly from Hex API and current repo deps. [CITED: https://hex.pm/api/packages/rendro] [CITED: https://hex.pm/api/packages/chromic_pdf] [VERIFIED: `accrue/mix.exs`]
- Architecture: HIGH - the invoice renderer seam, warning path, worker behavior, and release posture are all already encoded in the local code and phase context. [VERIFIED: `accrue/lib/accrue/invoices.ex`, `accrue/lib/accrue/application.ex`, `.planning/phases/107-rendro-release-optional-chromic/107-CONTEXT.md`, `RELEASING.md`]
- Pitfalls: HIGH - the most important pitfall was reproduced by a live test failure during research, and the others are directly visible in code/docs/release state. [VERIFIED: local command runs 2026-05-06, `accrue/test/accrue/application_boot_guards_test.exs`, `accrue/mix.exs`, `accrue/guides/configuration.md`]

**Research date:** 2026-05-06
**Valid until:** 2026-06-05 for repo-local architecture; 2026-05-13 for package-release details and dependency publish state. [ASSUMED]
