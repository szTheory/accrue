# Phase 108: Docs, Migration, and Proof Closeout - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 108 closes the Rendro-default invoice PDF milestone by making the docs, migration guidance, and final proof story match the already-landed runtime and dependency contract.

This phase should:
- rewrite install and PDF-facing guidance around Rendro as the normal invoice path
- document how existing hosts should think about `:invoice_pdf_adapter` versus the older `:pdf_adapter` seam
- revalidate the invoice, admin, and email proof lanes on the final Hex-backed dependency set

This phase should not:
- reopen the Phase 106 invoice-renderer seam
- reopen the Phase 107 Chromic fallback contract
- add hidden compatibility inference between `:pdf_adapter` and `:invoice_pdf_adapter`
- broaden into a repo-wide docs-verifier sweep beyond what the PDF/install/migration closeout actually needs

</domain>

<decisions>
## Implementation Decisions

### Migration posture

- **D-01:** Migration guidance should be explicit, not subtle. Phase 108 should add a dedicated migration section inside `accrue/guides/pdf.md` rather than relying on scattered warnings or changelog archaeology.
- **D-02:** The migration section should cover exactly three host states:
  - hosts that never customized PDF rendering: no action needed, Rendro is now the invoice default
  - hosts that set only `:pdf_adapter`: invoice PDFs no longer follow that setting; they must set `:invoice_pdf_adapter, Accrue.InvoiceRenderer.ChromicPDF` if they want the old invoice-rendering path
  - hosts using a custom HTML-to-PDF seam: `:pdf_adapter` still owns `Accrue.PDF`, but invoice rendering does not change unless they explicitly adopt an invoice renderer
- **D-03:** Keep the seam split explicit: `:invoice_pdf_adapter` owns invoice rendering; `:pdf_adapter` remains the lower-level HTML seam. Do not add compatibility inference rules.
- **D-04:** Keep the runtime warning for `:pdf_adapter` without `:invoice_pdf_adapter` as a supporting safety net, but treat docs as the primary migration surface.
- **D-05:** Do not create a standalone migration guide unless future milestones add materially more PDF migration surface. For Phase 108, that would be excess ceremony and duplicate the canonical PDF guide.

### Docs information architecture

- **D-06:** Use a layered docs posture, not `pdf.md` only and not broad duplication everywhere.
- **D-07:** `accrue/README.md` should own one high-signal statement that invoice PDFs are Rendro-first by default and no longer require Chrome on the normal path, plus a link to the PDF guide.
- **D-08:** `accrue/guides/first_hour.md` should set first-user expectations that ChromicPDF is not required for the default invoice path, then link to `guides/pdf.md` for deeper details. Do not turn First Hour into a PDF setup guide.
- **D-09:** `accrue/guides/production-readiness.md` should own operational checklist items only:
  - `:invoice_pdf_adapter` matches the intended production posture
  - Chromic supervision/pool sizing is correct only when the host explicitly opts into Chromic compatibility mode
  - branding/assets/fonts/logo constraints are verified for rendered invoices and email attachments
- **D-10:** `accrue/guides/pdf.md` remains the canonical deep guide and should own:
  - the Rendro-first default story
  - adapter matrix
  - `:invoice_pdf_adapter` versus `:pdf_adapter`
  - explicit Chromic compatibility path
  - null path
  - migration guidance
  - renderer-specific caveats
- **D-11:** `accrue/guides/configuration.md` should stay the config SSOT for key ownership and brief examples, but defer behavioral and migration detail to `guides/pdf.md`.
- **D-12:** `accrue/guides/custom_pdf_adapter.md` should be repositioned as advanced HTML/PDF seam guidance only. It should stop framing itself as the way to replace a default Chromic-backed invoice path.
- **D-13:** `accrue/guides/email.md` should document only the invoice-attachment interaction with the invoice renderer. Chromic-specific setup and concurrency notes should be conditional on explicitly choosing the Chromic compatibility path.
- **D-14:** `accrue/guides/branding.md` should describe renderer-specific asset and font constraints where Rendro and Chromic differ.

### Proof closeout posture

- **D-15:** The final Phase 108 closeout should use a layered proof posture centered on the three user-visible behavioral lanes:
  - `accrue/test/accrue/billing/pdf_test.exs`
  - `accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs`
  - `accrue_admin/test/accrue_admin/live/invoice_live_test.exs`
- **D-16:** `bash scripts/ci/verify_package_docs.sh` should be included as supporting doc-contract evidence because Phase 108 changes install/PDF/migration docs, but it should not be treated as the primary migration proof.
- **D-17:** `bash scripts/ci/verify_rendro_hex_resolution.sh` should be treated as Phase 107 dependency-handoff proof and carried forward as prerequisite evidence. Re-run it in Phase 108 only if `mix.exs`, lockfiles, or release truth changed after the Phase 107 cutover.
- **D-18:** Do not broaden the Phase 108 closeout into the full `docs-contracts-shift-left` bundle unless implementation expands beyond PDF/install/migration docs into broader repo-wide contract surfaces.
- **D-19:** The closeout artifact should keep behavioral proof as the headline acceptance story and docs/release scripts as supporting evidence, not the other way around.

### UX / DX posture

- **D-20:** Optimize for least surprise, explicit configuration, and front-door discoverability. New adopters should quickly learn that Rendro is the normal path; legacy Chromic users should quickly learn exactly what to change.
- **D-21:** Follow the project’s existing pattern of one canonical deep guide with shorter front-door pointers rather than repeating full explanations across every guide.
- **D-22:** Broader workflow preference reaffirmed: future discuss/planning passes should bias toward deep synthesized recommendation bundles, auto-resolve low-impact forks, and only escalate materially high-impact decisions. Current `.planning/config.json` already partially encodes this. Broader GSD-wide codification is outside Phase 108 scope.

### the agent's Discretion

- Exact wording of the migration subsection and its host-state examples, as long as it stays explicit and action-oriented.
- Exact short literals added to README / First Hour / Production Readiness, as long as they preserve the layered docs ownership above.
- Exact verification artifact structure, as long as it distinguishes primary behavioral proof from supporting docs/release evidence.

</decisions>

<specifics>
## Specific Ideas

- Ecosystem posture to emulate:
  - Phoenix / LiveView: explicit new paths, visible upgrade guidance, no silent inference
  - Oban: narrow install docs, explicit upgrade docs, config diffs called out directly
  - Ecto: light README, deeper guides for specialized behavior
  - Rails / Next.js / React: migration-safe default shifts work best when the new path is explicit, documented in normal upgrade surfaces, and not hidden behind compatibility magic
- The coherent public story should be:
  - Rendro is the default invoice renderer
  - Chromic is an explicit compatibility choice
  - `:invoice_pdf_adapter` controls invoices
  - `:pdf_adapter` remains an advanced lower-level HTML seam
  - final closeout proves visible behavior first, then doc and dependency truth
- User workflow preference captured here for downstream planning:
  - produce cohesive recommendation bundles
  - optimize for great DX and least surprise
  - shift low-impact decision-making left into research/synthesis whenever possible

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and prior context
- `.planning/ROADMAP.md` — active v1.34 scope and exact Phase 108 boundary
- `.planning/REQUIREMENTS.md` — `PDF-08`, `PDF-09`
- `.planning/PROJECT.md` — project goals, public-package posture, least-surprise expectations
- `.planning/STATE.md` — active milestone state
- `.planning/phases/107-rendro-release-optional-chromic/107-CONTEXT.md` — locked fallback/config/release decisions inherited from Phase 107
- `.planning/milestones/v1.34-phases/107-rendro-release-optional-chromic-path/107-02-SUMMARY.md` — Rendro Hex handoff already completed

### Docs and migration surfaces
- `accrue/README.md` — package front door
- `accrue/guides/first_hour.md` — first-user walkthrough spine
- `accrue/guides/production-readiness.md` — production checklist spine
- `accrue/guides/pdf.md` — canonical PDF guide
- `accrue/guides/configuration.md` — config-key ownership SSOT
- `accrue/guides/custom_pdf_adapter.md` — advanced HTML seam guide that needs repositioning
- `accrue/guides/email.md` — invoice-attachment behavior and legacy Chromic cues
- `accrue/guides/branding.md` — renderer-sensitive asset/font constraints
- `accrue/guides/upgrade.md` — migration/deprecation posture

### Runtime and contract code
- `accrue/lib/accrue/config.ex` — default adapter truth and config docs
- `accrue/lib/accrue/invoice_renderer.ex` — invoice-renderer seam
- `accrue/lib/accrue/invoices.ex` — invoice render/store/fetch contract
- `accrue/lib/accrue/application.ex` — migration-risk warning for stale `:pdf_adapter` assumptions
- `accrue/lib/accrue/workers/mailer.ex` — invoice attachment behavior
- `accrue_admin/lib/accrue_admin/live/invoice_live.ex` — admin invoice open/download behavior

### Proof and release surfaces
- `accrue/test/accrue/billing/pdf_test.exs` — invoice-path behavioral proof
- `accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs` — email attachment proof
- `accrue_admin/test/accrue_admin/live/invoice_live_test.exs` — admin invoice proof
- `scripts/ci/verify_package_docs.sh` — supporting doc-contract verifier
- `scripts/ci/verify_rendro_hex_resolution.sh` — dependency-handoff proof
- `.github/workflows/ci.yml` — current separation between behavioral and docs-contract proof lanes
- `RELEASING.md` — release philosophy and Rendro handoff runbook

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `accrue/lib/accrue/application.ex` already contains a boot warning for hosts likely carrying stale `:pdf_adapter` assumptions; Phase 108 should build docs around that rather than inventing new runtime behavior.
- `accrue/guides/pdf.md` already contains the strongest Rendro-first explanation and should be extended rather than replaced.
- `scripts/ci/verify_package_docs.sh` already acts as a package-doc contract gate and is the right supporting verifier when front-door docs move.
- Phase 107 already added `scripts/ci/verify_rendro_hex_resolution.sh`; Phase 108 should reuse that evidence pragmatically instead of duplicating the handoff story.

### Established Patterns
- Accrue’s docs spine is layered: README -> First Hour -> Production Readiness -> specialized guide. Phase 108 should preserve that information architecture.
- Accrue favors explicit configuration seams and typed behavior over hidden inference. The docs should teach that same posture.
- Release-sensitive closeout in this repo already separates behavioral proof from broader docs-contract sweeps; the final Phase 108 artifact should preserve that signal hierarchy.

### Integration Points
- Migration messaging must stay aligned across runtime warning text, PDF/config guides, email/install docs, and production-readiness checklists.
- Final proof must stay aligned across invoice rendering, mailer attachment behavior, admin download behavior, and the final Hex-backed dependency truth.
- Any new front-door wording may require verifier updates if those literals become part of the package-doc contract.

</code_context>

<deferred>
## Deferred Ideas

- Broader GSD-wide codification of the user’s “deep synthesis + auto-resolve low-impact forks” workflow preference remains outside Phase 108 scope. Current `.planning/config.json` already partially supports it.
- A standalone migration guide can be revisited later only if future milestones add materially broader PDF migration surface.
- Any reconsideration of automatic fallback chains or seam inference remains explicitly out of scope.

</deferred>

---

*Phase: 108-docs-migration-proof-closeout*
*Context gathered: 2026-05-06*
