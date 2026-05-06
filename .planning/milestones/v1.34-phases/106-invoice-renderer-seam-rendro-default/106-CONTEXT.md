# Phase 106: Invoice Renderer Seam & Rendro Default - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 106 hardens and proves the already-landed invoice-renderer architecture:

- invoice PDFs stay routed through the dedicated `Accrue.InvoiceRenderer` seam
- Rendro remains the default invoice renderer
- the public `Accrue.Invoices` / `Accrue.Billing` invoice API stays unchanged
- lazy `render/store/fetch_invoice_pdf` semantics stay intact
- invoice-facing parity is proven across billing, mailer attachment, and admin download flows

This phase does **not** reopen the fallback/release questions reserved for Phase 107 or the broader migration/install-document rewrite reserved for Phase 108.

</domain>

<decisions>
## Implementation Decisions

### Parity proof depth

- **D-01:** Treat **invoice semantics parity** as the contract, not byte-for-byte PDF identity. The repo should prove that invoice number/date, customer line, item rows, totals, and footer/support branding survive the Rendro default path.
- **D-02:** Use a **hybrid proof strategy**:
  - keep the existing `%PDF` smoke check as the cheap end-to-end floor
  - add primary semantic assertions against deterministic pre-render structure
  - add only a small number of targeted rendered-output assertions for critical user-visible strings
- **D-03:** Do **not** use full golden-PDF or byte-snapshot approval files as the default proof mechanism. They are too brittle, too opaque in review, and too coupled to renderer internals.
- **D-04:** If any snapshot-style technique is used, it should target **normalized intermediate structure** only, never raw PDF bytes or incidental object ordering.

### Testability seam

- **D-05:** Keep `Accrue.InvoiceRenderer.render/2` and the public billing/invoice facade unchanged. Phase 106 must not widen the supported public API for test convenience.
- **D-06:** Extract or formalize a **hidden internal Rendro document-builder seam** so tests can assert invoice structure before binary rendering.
- **D-07:** Prefer a dedicated internal module with `@moduledoc false` over a same-module `@doc false` helper. The hidden module reduces the chance that callers start depending on an undocumented function as if it were part of the contract.
- **D-08:** Avoid test-only hooks, config branches, or any production-path special casing just to capture intermediate state.
- **D-09:** Keep the end-to-end `render/2` suite thinner and focused on adapter wiring plus valid-PDF output; move most semantic proof to the internal builder seam.

### Documentation scope for this phase

- **D-10:** Phase 106 owns only **contract-truth repair** for docs and tests that are actively misleading about invoice rendering.
- **D-11:** `:invoice_pdf_adapter` is the only invoice-renderer control key. `:pdf_adapter` remains the lower-level HTML seam and must not be described as the normal invoice-rendering switch.
- **D-12:** Limit doc changes in this phase to the canonical contract surfaces that would otherwise lie to maintainers or hosts.
- **D-13:** Defer the broader migration/install/default-story rewrite to Phases 107–108. Do not steal that work into Phase 106 just to make this phase feel more “complete.”

### Decision posture and DX

- **D-14:** Optimize for least surprise, stable public contracts, explicit configuration, and proof that a maintainer can understand in a normal ExUnit review without specialized PDF forensics.
- **D-15:** Favor proof styles that match idiomatic Elixir/Phoenix library practice: deterministic transform assertions, narrow output assertions, and small public surfaces.
- **D-16:** Low-impact forks in this phase should be auto-resolved toward the coherent default above unless a choice would materially change public contract semantics, phase boundaries, or release/migration posture.

### the agent's Discretion

- Exact naming and file placement of the hidden internal Rendro builder seam, provided it remains undocumented public surface.
- Whether targeted rendered-output assertions use extracted text or another narrow rendered-output check, provided the proof stays deterministic and reviewable.
- Exact normalized structure shape used in tests, provided it captures meaningful invoice invariants rather than incidental layout noise.
- Exact doc files touched in Phase 106, provided every change is justified by current contract drift rather than broader migration storytelling.

</decisions>

<specifics>
## Specific Ideas

- Recommended cohesive posture:
  - **Hybrid proof, not snapshots**: smoke test for “renders a PDF,” structural assertions for semantic truth, and a few narrow end-to-end content checks.
  - **Internal builder seam, not API growth**: library consumers should keep seeing one renderer contract while maintainers get an inspectable internal shape.
  - **Contract-truth docs only**: fix misleading adapter-key language now; save broad install/migration narrative for the dedicated later phases.
- Ecosystem lessons carried into the recommendation:
  - Elixir/Phoenix libraries tend to reward **small public APIs + testable internal transforms** more than broad public “debug” seams.
  - Component/view ecosystems across languages repeatedly show that **focused semantic assertions** age better than giant snapshots.
  - Successful libraries document the new truth early, then layer migration guidance separately; they do not duplicate canon across every doc surface at once.
- User preference captured for downstream work:
  - research deeply, synthesize a cohesive default, and auto-resolve low-impact decisions without re-opening every fork
  - only resurface choices that materially affect contract semantics, migration posture, or milestone shape
- Current `.planning/config.json` already partially aligns with that preference through:
  - `workflow.discuss_auto_all_gray_areas`
  - `workflow.discuss_auto_resolve_low_impact`
  - `workflow.discuss_high_impact_confirm`
  - `workflow.discuss_publish_contracts_research_depth`

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and project posture
- `.planning/ROADMAP.md` — active v1.34 milestone scope and exact Phase 106 boundary
- `.planning/REQUIREMENTS.md` — `PDF-01` through `PDF-05`
- `.planning/PROJECT.md` — milestone intent and public-package posture
- `.planning/STATE.md` — active planning state for v1.34

### Phase research and existing plans
- `.planning/phases/106-invoice-renderer-seam-rendro-default/106-RESEARCH.md` — current repo evidence and identified proof/doc drift
- `.planning/phases/106-invoice-renderer-seam-rendro-default/106-01-PLAN.md` — proof-lane and contract-surface alignment plan
- `.planning/phases/106-invoice-renderer-seam-rendro-default/106-02-PLAN.md` — Rendro parity proof hardening plan
- `.planning/phases/106-invoice-renderer-seam-rendro-default/106-PATTERNS.md` — file analogs and modification patterns
- `.planning/phases/107-rendro-release-optional-chromic/107-CONTEXT.md` — confirms which fallback/release concerns are intentionally deferred to the next phase

### Core code and proof surfaces
- `accrue/lib/accrue/invoice_renderer.ex` — invoice-specific renderer seam and adapter resolution
- `accrue/lib/accrue/invoice_renderer/rendro.ex` — current native Rendro renderer implementation
- `accrue/lib/accrue/invoices.ex` — public lazy render/store/fetch facade and adapter-availability guard
- `accrue/test/accrue/billing/pdf_test.exs` — facade-level invoice PDF contract tests
- `accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs` — mailer attachment/fallback proof lane
- `accrue_admin/test/accrue_admin/live/invoice_live_test.exs` — admin open/download proof lane

### Contract-truth documentation
- `accrue/guides/configuration.md` — adapter-key contract wording
- `accrue/guides/pdf.md` — Rendro-first invoice rendering guide
- `accrue/guides/testing.md` — testing guidance that must align with the invoice seam

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Accrue.InvoiceRenderer` already provides the dedicated invoice-renderer seam required by the milestone.
- `Accrue.InvoiceRenderer.Rendro` already builds the document through helper-driven section assembly, which gives a natural place to extract a hidden internal builder seam.
- `Accrue.InvoiceRenderer.Test` and the existing facade tests already provide the right adapter-swapping pattern for invoice-path proofs.
- `Accrue.Invoices` already owns lazy render/store/fetch semantics and should remain the sole public invoice-PDF facade.

### Established Patterns
- Accrue prefers explicit adapter seams over hidden inference.
- The repo already uses `Application.put_env/3` + `on_exit/1` in ExUnit to prove adapter behavior without widening production APIs.
- Library-facing contracts in this repo are intentionally narrower than internal implementation detail; planning should preserve that discipline here.

### Integration Points
- The strengthened proof must stay aligned across:
  - `Accrue.Invoices.render_invoice_pdf/2`
  - `Accrue.Billing` invoice delegates
  - mailer invoice attachment generation
  - admin “Open PDF” / download flows
- Contract-truth docs must stay aligned with the real adapter split:
  - `:invoice_pdf_adapter` for invoice rendering
  - `:pdf_adapter` for the lower-level HTML seam
- Any internal Rendro builder seam introduced for proofability should remain local to the renderer implementation and not leak into the public API or host configuration model.

</code_context>

<deferred>
## Deferred Ideas

- Broad migration/install/default-story documentation rewrite — Phase 108
- Chromic fallback contract hardening, failure-messaging posture, and Rendro Hex release handoff — Phase 107
- Any automatic fallback chain, public structured renderer-debug API, or linked Rendro/Accrue release choreography
- Workflow-wide codification of the user's “deep synthesis + auto-resolve low-impact decisions” preference beyond the current `.planning/config.json` defaults

</deferred>

---

*Phase: 106-invoice-renderer-seam-rendro-default*
*Context gathered: 2026-05-06*
