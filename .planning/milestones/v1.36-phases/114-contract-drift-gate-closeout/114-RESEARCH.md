# Phase 114: Contract Drift Gate Closeout - Research

**Researched:** 2026-05-07
**Domain:** Documentation contract closeout across canonical matrix, mirror docs, targeted CI verifiers, and planning mirrors
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Docs coverage
- **D-01:** `.planning/processor-support-matrix.md` remains the single canonical wording spine for the finalized dual-provider core contract.
- **D-02:** Package docs, host docs, and proof docs should mirror only the durable contract needles their audience needs, not restate the full matrix.
- **D-03:** The mirrored needles should stay focused on:
  - the supported slice name (`gateway subscription core`)
  - Fake-first merge-blocking proof posture
  - advisory provider-backed fidelity lanes
  - Stripe-hosted versus Braintree-mounted-local honesty
  - immediate cancel versus scheduled-end split
  - bounded `update_customer/2` semantics where that API is surfaced
- **D-04:** Do not optimize for every single doc page being self-contained if that requires restating the same support contract in multiple voices.
- **D-05:** Phase 114 should prefer layered documentation over duplicate documentation: one canonical contract source, then audience-specific teaching surfaces that link back to it.

### Example-host proof depth
- **D-06:** `examples/accrue_host` remains a thin adoption-facing proof surface, not a second authoritative contract mirror.
- **D-07:** The example host should prove installed-host ergonomics, host-owned seams, and realistic usage flows without re-explaining the entire provider contract inline.
- **D-08:** Host proof docs should repeat only the minimum semantics needed to prevent misuse:
  - `update_customer/2` is bounded and provider-neutral
  - `cancel/2` is the shared immediate path
  - `cancel_at_period_end/2` is not a Braintree first-party path
  - Fake is merge-blocking; provider-backed lanes are advisory where stated
- **D-09:** Host code and tests should stay thin and delegating. The canonical semantics still live in runtime code, the support matrix, and package guides.
- **D-10:** Avoid turning the example host README or adoption-proof matrix into a quasi-spec, because that creates a high-trust but fast-drifting second contract voice.

### Drift-gate shape
- **D-11:** Keep the drift gate as a named support-contract bundle composed of existing targeted verifiers, not a new mega-verifier.
- **D-12:** The core Phase 114 bundle should center on:
  - `scripts/ci/verify_processor_support_matrix.sh`
  - `scripts/ci/verify_package_docs.sh`
  - `scripts/ci/verify_verify01_readme_contract.sh`
  - `scripts/ci/verify_adoption_proof_matrix.sh`
- **D-13:** Runtime capability truth and adapter semantics remain proven in ExUnit; exact public contract wording remains proven by targeted bash/string-literal gates.
- **D-14:** Do not collapse docs, proof, and matrix drift into one broad owner script. Surface-local failures are easier to understand, maintain, and trust.
- **D-15:** The support-contract bundle should be documented clearly in `scripts/ci/README.md` and kept stable as a contributor-facing ritual.
- **D-16:** Extend or tighten the targeted verifiers only where Phase 114 surfaces actually move; do not widen the gate bundle into unrelated doc territory.

### Planning mirror hygiene
- **D-17:** `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` should behave as concise closeout mirrors, not second copies of the support contract.
- **D-18:** `REQUIREMENTS.md` should close `PROC-24` and update traceability, but not restate the detailed contract semantics already captured elsewhere.
- **D-19:** `ROADMAP.md` should mark Phase 114 and milestone `v1.36` complete with a short outcome summary and links/pointers, not another full contract narrative.
- **D-20:** `STATE.md` should be corrected to current live facts and remain the operational position mirror, not a second milestone brief.
- **D-21:** If a planning mirror needs to reference contract truth, it should point to the support matrix, docs, or context file rather than paraphrasing all semantics again.

### Architecture and DX posture
- **D-22:** Phase 114 should optimize for least surprise: the place where maintainers expect contract truth should actually be the place that owns it.
- **D-23:** Provider-honest semantics stay more important than local page convenience or documentation symmetry.
- **D-24:** Strong DX here means:
  - a single canonical contract spine
  - thin but trustworthy adoption-facing proof
  - fast, localizable CI failures
  - low-maintenance mirrors
  - explicit links between artifacts instead of hidden duplication
- **D-25:** This phase should preserve the repo’s existing “bounded first-party slice, no parity theater” philosophy rather than inventing a broader documentation architecture.

### Lessons to preserve from other ecosystems
- **D-26:** Copy Stripe’s layering model, not its breadth: canonical technical contract plus audience-specific guides.
- **D-27:** Preserve the Pay/Cashier lesson that processor divergence must be named honestly instead of flattened into a fake uniform story.
- **D-28:** Preserve the Phoenix/Rails example-app lesson that sample hosts should demonstrate usage and integration seams, not become the authoritative API spec.
- **D-29:** Preserve the ActiveMerchant warning already captured in strategy: broad abstraction and broad mirror surfaces create long-tail DX erosion and drift burden.

### GSD shift-left preference
- **D-30:** For low-impact implementation forks inside an already approved boundary, future GSD discuss/planning passes should default to researched synthesis and one cohesive recommendation package instead of reopening the fork interactively.
- **D-31:** Reopen decisions interactively only when the choice materially changes:
  - product boundary
  - first-party support promise
  - public API shape
  - verifier philosophy
  - support/operator obligations
- **D-32:** Existing config posture already points in this direction (`research_before_questions`, `discuss_auto_resolve_low_impact`, `discuss_high_impact_confirm`). Future phases should continue to honor that preference without inventing unnecessary new toggles.

### the agent's Discretion
- Exact wording of the short mirrored needles in package docs and example-host docs, as long as they stay faithful to the canonical matrix.
- Exact naming and presentation of the “support-contract bundle” in `scripts/ci/README.md`, as long as the underlying targeted-script posture remains unchanged.
- Exact terseness of the Phase 114 closeout edits in `REQUIREMENTS.md`, `ROADMAP.md`, and `STATE.md`, as long as those files stay concise mirrors instead of semantic duplicates.

### Deferred Ideas (OUT OF SCOPE)
- Turning the example host into a second full contract mirror or quasi-spec
- Creating one broad mega-verifier that centrally owns every support-contract literal
- Rewriting planning mirrors into long-form semantic docs
- Reopening broader lifecycle, scheduling, preview/proration, or processor-expansion scope in this phase
- Adding new GSD config toggles unless a real behavior gap appears beyond the existing low-impact/high-impact defaults
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROC-24 | Public docs, planning mirrors, example-host proofs, and merge-blocking verifiers repeat the finalized dual-provider core contract so staged-vs-first-party drift is caught automatically. | Use the matrix as SSOT, keep mirror docs thin, tighten only the four targeted verifiers, and close planning mirrors with concise status updates plus phase-local verification. [VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: .planning/processor-support-matrix.md][VERIFIED: scripts/ci/README.md][VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-CONTEXT.md] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- The project-level support floor remains Elixir `1.17+`, OTP `27+`, Phoenix `1.8+`, Ecto `3.12+`, and PostgreSQL `14+`; Phase 114 should not introduce guidance that contradicts those floors. [VERIFIED: CLAUDE.md]
- Webhook signature verification stays mandatory, sensitive Stripe fields stay out of logs, and payment-method details remain reference-only; doc changes in this phase must not weaken those security statements. [VERIFIED: CLAUDE.md]
- The repo’s strategic proof posture is Fake-first and deterministic, with provider-backed lanes used for fidelity rather than as the primary merge blocker. [VERIFIED: CLAUDE.md][VERIFIED: .planning/STRATEGY.md]
- No project-defined skills were found under `.claude/skills/` or `.agents/skills/`, so there are no extra local research rules beyond `CLAUDE.md` and the phase context. [VERIFIED: repo grep]

## Summary

Phase 114 is a documentation-and-gates closeout, not a runtime-expansion phase. The canonical contract already exists in `.planning/processor-support-matrix.md`, and the repo already has the exact four-script support-contract bundle the context locks in: `verify_processor_support_matrix.sh`, `verify_package_docs.sh`, `verify_verify01_readme_contract.sh`, and `verify_adoption_proof_matrix.sh`. Those scripts all pass on the current branch, and each already has a shell-out ExUnit harness except `verify_verify01_readme_contract.sh`, which is covered by `Accrue.Phase31NyquistValidationTest`. [VERIFIED: .planning/processor-support-matrix.md][VERIFIED: scripts/ci/verify_processor_support_matrix.sh][VERIFIED: scripts/ci/verify_package_docs.sh][VERIFIED: scripts/ci/verify_verify01_readme_contract.sh][VERIFIED: scripts/ci/verify_adoption_proof_matrix.sh][VERIFIED: accrue/test/accrue/docs/processor_support_matrix_test.exs][VERIFIED: accrue/test/accrue/docs/package_docs_verifier_test.exs][VERIFIED: accrue/test/accrue/docs/organization_billing_org09_matrix_test.exs][VERIFIED: accrue/test/accrue/phase_31_nyquist_validation_test.exs][VERIFIED: bash scripts/ci/verify_processor_support_matrix.sh][VERIFIED: bash scripts/ci/verify_package_docs.sh][VERIFIED: bash scripts/ci/verify_verify01_readme_contract.sh][VERIFIED: bash scripts/ci/verify_adoption_proof_matrix.sh]

The remaining work is drift cleanup at the seams. The matrix still contains stale milestone-era staging prose (`Phase 94`, `Phase 95`, `Phase 96`, `Phase 97`) even though Phase 114’s goal is a finalized contract. `accrue/guides/testing.md` and `guides/testing-live-stripe.md` still say checkout and billing portal remain Stripe-only, which now contradicts the matrix, `accrue/README.md`, and the example-host docs that describe provider-honest first-party checkout and portal behavior. The example-host README and adoption-proof matrix also enumerate an incomplete `docs-contracts-shift-left` membership list: CI runs `verify_processor_support_matrix.sh` and `verify_production_readiness_discoverability.sh`, but those two scripts are omitted from those docs today. [VERIFIED: .planning/processor-support-matrix.md][VERIFIED: accrue/guides/testing.md][VERIFIED: guides/testing-live-stripe.md][VERIFIED: accrue/README.md][VERIFIED: examples/accrue_host/README.md][VERIFIED: examples/accrue_host/docs/adoption-proof-matrix.md][VERIFIED: .github/workflows/ci.yml][VERIFIED: repo grep]

Planning mirrors are intentionally outside the merge-blocking support-contract bundle today. `REQUIREMENTS.md` still shows `PROC-24` pending, `ROADMAP.md` still marks Phase 114 active, and `STATE.md` still says the project is ready to start Phase 114 after Phase 113. That is correct before execution, but it means final closeout should happen only after the doc and verifier bundle is green; do not widen `docs-contracts-shift-left` just to police those internal mirrors. [VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: .planning/ROADMAP.md][VERIFIED: .planning/STATE.md][VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-CONTEXT.md]

**Primary recommendation:** Use a 3-plan sequence: clean the canonical matrix first, align package/example mirrors second, then tighten only the existing targeted verifiers plus `scripts/ci/README.md`, and close the planning mirrors last after the support-contract bundle passes. [VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-PATTERNS.md][VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Canonical support wording ownership | Planning SSOT | — | `.planning/processor-support-matrix.md` is explicitly locked as the single wording spine for the dual-provider contract. [VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-CONTEXT.md][VERIFIED: .planning/processor-support-matrix.md] |
| Audience-facing contract needles | Package docs + example-host docs | Planning SSOT | Public docs are supposed to mirror only the durable needles their audience needs and link back to the matrix rather than duplicate it. [VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-CONTEXT.md][VERIFIED: accrue/README.md][VERIFIED: accrue/guides/first_hour.md][VERIFIED: examples/accrue_host/README.md] |
| Drift enforcement for wording | CI shell scripts | ExUnit shell-out harnesses | Exact string-literal contract drift is already enforced by the four targeted bash scripts and their repo-local test harnesses. [VERIFIED: scripts/ci/verify_processor_support_matrix.sh][VERIFIED: scripts/ci/verify_package_docs.sh][VERIFIED: scripts/ci/verify_verify01_readme_contract.sh][VERIFIED: scripts/ci/verify_adoption_proof_matrix.sh][VERIFIED: accrue/test/accrue/docs/processor_support_matrix_test.exs][VERIFIED: accrue/test/accrue/docs/package_docs_verifier_test.exs][VERIFIED: accrue/test/accrue/docs/organization_billing_org09_matrix_test.exs][VERIFIED: accrue/test/accrue/phase_31_nyquist_validation_test.exs] |
| Contributor ritual and bundle discoverability | `scripts/ci/README.md` | CI workflow | The context locks `scripts/ci/README.md` as the contributor-facing home for the support-contract bundle, while `.github/workflows/ci.yml` remains the normative execution order. [VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-CONTEXT.md][VERIFIED: scripts/ci/README.md][VERIFIED: .github/workflows/ci.yml] |
| Internal milestone closeout status | Planning mirrors | Planning SSOT | `REQUIREMENTS.md`, `ROADMAP.md`, and `STATE.md` should mirror status and pointers only, not become a second semantic contract source. [VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-CONTEXT.md][VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: .planning/ROADMAP.md][VERIFIED: .planning/STATE.md] |

## Standard Stack

No new third-party packages are recommended for Phase 114; the standard stack is the repo’s existing Markdown + bash + ExUnit + GitHub Actions contract machinery. [VERIFIED: repo grep]

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `.planning/processor-support-matrix.md` | current repo HEAD | Canonical dual-provider contract wording spine | The context explicitly locks it as the single canonical wording source. [VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-CONTEXT.md] |
| `scripts/ci/verify_processor_support_matrix.sh` | current repo HEAD | SSOT drift gate for matrix literals | It already checks the gateway-subscription-core slice, cancellation split, checkout/portal honesty, and support-boundary rules. [VERIFIED: scripts/ci/verify_processor_support_matrix.sh] |
| `scripts/ci/verify_package_docs.sh` | current repo HEAD | Package/public mirror gate | It already covers root/package docs, host README structure, and strategic mirror wording, and is the correct place to extend package-doc needles. [VERIFIED: scripts/ci/verify_package_docs.sh] |
| `scripts/ci/verify_verify01_readme_contract.sh` | current repo HEAD | Example-host README proof gate | It already owns VERIFY-01 prose, spec-path, and host proof wording checks. [VERIFIED: scripts/ci/verify_verify01_readme_contract.sh] |
| `scripts/ci/verify_adoption_proof_matrix.sh` | current repo HEAD | Example-host proof-matrix gate | It already owns adoption-proof matrix taxonomy and provider-honest proof-lane wording. [VERIFIED: scripts/ci/verify_adoption_proof_matrix.sh] |
| `.github/workflows/ci.yml` job `docs-contracts-shift-left` | current repo HEAD | Merge-blocking execution order | CI already runs the support-matrix gate, package-doc gate, VERIFY-01 gate, adoption-proof gate, and adjacent doc contracts in one dedicated job. [VERIFIED: .github/workflows/ci.yml] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `accrue/test/accrue/docs/processor_support_matrix_test.exs` | current repo HEAD | Shell-out harness for matrix verifier | Use when changing `verify_processor_support_matrix.sh` or the matrix literals it enforces. [VERIFIED: accrue/test/accrue/docs/processor_support_matrix_test.exs] |
| `accrue/test/accrue/docs/package_docs_verifier_test.exs` | current repo HEAD | Shell-out harness plus negative fixtures for package-doc drift | Use when adding or changing `verify_package_docs.sh` needles. [VERIFIED: accrue/test/accrue/docs/package_docs_verifier_test.exs] |
| `accrue/test/accrue/docs/organization_billing_org09_matrix_test.exs` | current repo HEAD | Shell-out harness for adoption-proof matrix verifier | Use when changing `verify_adoption_proof_matrix.sh`. [VERIFIED: accrue/test/accrue/docs/organization_billing_org09_matrix_test.exs] |
| `accrue/test/accrue/phase_31_nyquist_validation_test.exs` | current repo HEAD | Shell-out harness for VERIFY-01 README verifier | Use when changing `verify_verify01_readme_contract.sh` expectations. [VERIFIED: accrue/test/accrue/phase_31_nyquist_validation_test.exs] |
| `scripts/ci/README.md` | current repo HEAD | Contributor-facing bundle documentation | Use as the only place that enumerates the support-contract bundle ritual in full. [VERIFIED: scripts/ci/README.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| One canonical matrix + thin mirrors | Repeating the full contract in every README/guide | Repetition directly conflicts with locked layering decisions and creates more drift surfaces. [VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-CONTEXT.md] |
| Four surface-local verifiers | One mega-verifier for every contract literal | A mega-verifier violates the locked drift-gate philosophy and makes failures harder to localize. [VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-CONTEXT.md] |
| Phase-local planning mirror checks | Adding planning mirrors to `docs-contracts-shift-left` | Planning mirrors are internal closeout artifacts, not part of the locked public support-contract bundle. [VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-CONTEXT.md][VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: .planning/ROADMAP.md][VERIFIED: .planning/STATE.md] |

**Installation:**

```bash
# No package installation required for Phase 114.
```

**Version verification:** No new package versions are part of this phase; the relevant toolchain already exists locally as Bash 5.2.37, Elixir 1.19.5 / OTP 28, Mix 1.19.5, Node v22.14.0, npm 11.1.0, and a reachable local PostgreSQL on `/tmp:5432`. [VERIFIED: local command]

## Architecture Patterns

### System Architecture Diagram

```text
.planning/processor-support-matrix.md
        |
        v
  canonical contract wording
        |
        +------------------------------+
        |                              |
        v                              v
 package/public mirrors          example-host proof mirrors
 (README + guides)               (README + adoption matrix)
        |                              |
        +---------------+--------------+
                        |
                        v
             targeted bash verifiers
  verify_processor_support_matrix / verify_package_docs /
  verify_verify01_readme_contract / verify_adoption_proof_matrix
                        |
                        v
         ExUnit shell-out harnesses + CI job docs-contracts-shift-left
                        |
                        v
        planning mirrors close status and point back to the canon
     (.planning/REQUIREMENTS.md / ROADMAP.md / STATE.md)
```

### Recommended Project Structure

```text
.planning/
├── processor-support-matrix.md        # canonical support contract wording
├── REQUIREMENTS.md                    # concise requirement closeout mirror
├── ROADMAP.md                         # concise milestone/phase status mirror
└── STATE.md                           # concise current-position mirror

accrue/
├── README.md                          # package-facing contract needles
└── guides/
    ├── first_hour.md                  # first-user mirror
    └── testing.md                     # proof-lane mirror

guides/
└── testing-live-stripe.md             # advisory provider lane framing

examples/accrue_host/
├── README.md                          # host-facing proof mirror
└── docs/adoption-proof-matrix.md      # adoption/proof matrix

scripts/ci/
├── README.md                          # contributor-facing bundle documentation
├── verify_processor_support_matrix.sh
├── verify_package_docs.sh
├── verify_verify01_readme_contract.sh
└── verify_adoption_proof_matrix.sh
```

### Pattern 1: Canonical Matrix First
**What:** Edit `.planning/processor-support-matrix.md` before changing any mirror docs or verifier literals, and remove stale milestone-history phrasing so the matrix reads as present-tense contract truth. [VERIFIED: .planning/processor-support-matrix.md]

**When to use:** Any change to support wording, proof-lane posture, or provider-honest semantics. [VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-CONTEXT.md]

**Example:**

```bash
# Source: scripts/ci/verify_processor_support_matrix.sh
bash scripts/ci/verify_processor_support_matrix.sh
```

### Pattern 2: Thin Mirror Needles, Not Full Re-Specification
**What:** Public docs should state only the durable audience-facing needles, then link back to the matrix or `scripts/ci/README.md` instead of enumerating the full contract or full CI job membership inline. [VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-CONTEXT.md][VERIFIED: scripts/ci/README.md]

**When to use:** Root README, package README/guides, example-host README, and adoption-proof matrix. [VERIFIED: accrue/README.md][VERIFIED: accrue/guides/first_hour.md][VERIFIED: accrue/guides/testing.md][VERIFIED: examples/accrue_host/README.md][VERIFIED: examples/accrue_host/docs/adoption-proof-matrix.md]

**Example:**

```markdown
Merge-blocking support-contract checks live in `scripts/ci/README.md`.
This page keeps only the audience-facing proof summary and links back to the canonical matrix.
```

### Pattern 3: Extend Existing Verifiers Only At The Touched Surface
**What:** If Phase 114 changes package-doc needles, tighten `verify_package_docs.sh`; if it changes host README proof wording, tighten `verify_verify01_readme_contract.sh`; if it changes proof-matrix wording, tighten `verify_adoption_proof_matrix.sh`. [VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-CONTEXT.md][VERIFIED: scripts/ci/README.md]

**When to use:** Whenever a mirror surface changes in a way that could silently drift later. [VERIFIED: scripts/ci/README.md]

**Example:**

```bash
# Source: scripts/ci/README.md
bash scripts/ci/verify_processor_support_matrix.sh
bash scripts/ci/verify_package_docs.sh
bash scripts/ci/verify_verify01_readme_contract.sh
bash scripts/ci/verify_adoption_proof_matrix.sh
```

### Anti-Patterns to Avoid

- **Second spec in `examples/accrue_host`:** The context explicitly rejects turning the example host into another authoritative contract mirror. [VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-CONTEXT.md]
- **Mega-verifier expansion:** The locked drift-gate shape is a named bundle of targeted scripts, not a centralized owner script. [VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-CONTEXT.md]
- **Planning mirrors as semantic duplicates:** `REQUIREMENTS.md`, `ROADMAP.md`, and `STATE.md` should close status and point back, not paraphrase the full provider contract. [VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Support-contract drift gate | One new all-in-one contract verifier | The existing four-script bundle | The bundle is already locked by context, already wired into CI, and already produces surface-local failure messages. [VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-CONTEXT.md][VERIFIED: .github/workflows/ci.yml] |
| Host/example contract mirror | A second full capability table in host docs | Short proof needles plus links back to the matrix | Host docs are supposed to teach usage and proof posture, not become a second spec. [VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-CONTEXT.md] |
| Planning drift enforcement | A new merge-blocking planning verifier job | Phase-local `rg`/review checks plus final mirror edits | Planning mirrors are in scope for closeout but are not part of the locked public support-contract bundle. [VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-CONTEXT.md] |
| Provider wording repair | Broad wording rewrites across unrelated docs | Narrow same-PR edits at the touched mirror surface | The existing verifiers and context both expect surface-local edits and low-maintenance mirrors. [VERIFIED: scripts/ci/README.md][VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-CONTEXT.md] |

**Key insight:** Phase 114 should reduce duplication, not add another place that “owns” the contract. The repo already has enough machinery; the missing work is aligning stale mirrors and making the current targeted gates watch the right needles. [VERIFIED: repo grep][VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Leaving Milestone-History Wording In The Canonical Matrix
**What goes wrong:** The matrix reads like an in-progress roadmap (`Phase 94`, `Phase 95`, `Phase 96`, `Phase 97`) instead of present-tense contract truth. [VERIFIED: .planning/processor-support-matrix.md]

**Why it happens:** Earlier milestone closure text was never normalized after the runtime contract shipped. [VERIFIED: .planning/processor-support-matrix.md][VERIFIED: .planning/ROADMAP.md]

**How to avoid:** Rewrite the matrix intro and support-boundary prose in present-tense contract language before touching mirrors. [VERIFIED: .planning/processor-support-matrix.md]

**Warning signs:** The matrix still talks about future phases satisfying the contract instead of describing what the contract is now. [VERIFIED: .planning/processor-support-matrix.md]

### Pitfall 2: Provider-Honest Contract In One Doc, Stripe-Only Wording In Another
**What goes wrong:** Package/testing docs still tell readers that checkout and billing portal remain Stripe-only while the matrix, package README, and host docs say they are first-party with provider-honest behavior. [VERIFIED: accrue/guides/testing.md][VERIFIED: guides/testing-live-stripe.md][VERIFIED: accrue/README.md][VERIFIED: examples/accrue_host/README.md][VERIFIED: .planning/processor-support-matrix.md]

**Why it happens:** `verify_package_docs.sh` currently checks those files for proof-lane and structural pins, but not for checkout/portal support wording in the testing guides. [VERIFIED: scripts/ci/verify_package_docs.sh]

**How to avoid:** Update the testing guides to match the matrix, then add exact `require_fixed` or `require_absent_regex` coverage in `verify_package_docs.sh`. [VERIFIED: scripts/ci/verify_package_docs.sh]

**Warning signs:** `verify_package_docs.sh` passes while `guides/testing-live-stripe.md` or `accrue/guides/testing.md` still says “Stripe-only.” [VERIFIED: scripts/ci/verify_package_docs.sh][VERIFIED: guides/testing-live-stripe.md][VERIFIED: accrue/guides/testing.md][VERIFIED: bash scripts/ci/verify_package_docs.sh]

### Pitfall 3: Example-Host Docs Enumerate CI Membership Inline
**What goes wrong:** `examples/accrue_host/README.md` and `docs/adoption-proof-matrix.md` list a partial `docs-contracts-shift-left` membership and drift behind `.github/workflows/ci.yml`. [VERIFIED: examples/accrue_host/README.md][VERIFIED: examples/accrue_host/docs/adoption-proof-matrix.md][VERIFIED: .github/workflows/ci.yml]

**Why it happens:** Those docs duplicate workflow membership instead of deferring exact bundle inventory to `scripts/ci/README.md`. [VERIFIED: examples/accrue_host/README.md][VERIFIED: examples/accrue_host/docs/adoption-proof-matrix.md][VERIFIED: scripts/ci/README.md]

**How to avoid:** Keep host docs at the summary layer and point exact bundle membership to `scripts/ci/README.md`; if any inline inventory remains, update the matching verifier in the same PR. [VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-CONTEXT.md][VERIFIED: scripts/ci/README.md]

**Warning signs:** The host docs name some but not all `docs-contracts-shift-left` scripts, or CI gains a script without a same-PR host doc update. [VERIFIED: repo grep][VERIFIED: .github/workflows/ci.yml]

### Pitfall 4: Planning Mirrors Closed Too Early
**What goes wrong:** `PROC-24`, Phase 114, or milestone `v1.36` get marked complete before the support-contract bundle is actually green. [VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: .planning/ROADMAP.md][VERIFIED: .planning/STATE.md]

**Why it happens:** Planning mirrors are status files, not the source of proof, so they can be edited optimistically. [VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-CONTEXT.md]

**How to avoid:** Reserve final `REQUIREMENTS.md` / `ROADMAP.md` / `STATE.md` completion edits for the last plan after the doc/verifier changes are passing. [VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-PATTERNS.md]

**Warning signs:** `PROC-24` is checked off while the README/adoption/matrix verifiers still have pending edits or stale literals. [VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: scripts/ci/README.md]

## Code Examples

Verified patterns from current repo sources:

### Run The Named Support-Contract Bundle
```bash
# Source: scripts/ci/README.md
bash scripts/ci/verify_processor_support_matrix.sh
bash scripts/ci/verify_package_docs.sh
bash scripts/ci/verify_verify01_readme_contract.sh
bash scripts/ci/verify_adoption_proof_matrix.sh
```

### Keep CI Wiring Separate From Host Integration
```yaml
# Source: .github/workflows/ci.yml
docs-contracts-shift-left:
  steps:
    - run: bash scripts/ci/verify_package_docs.sh
    - run: bash scripts/ci/verify_processor_support_matrix.sh
    - run: bash scripts/ci/verify_verify01_readme_contract.sh
    - run: bash scripts/ci/verify_production_readiness_discoverability.sh
    - run: bash scripts/ci/verify_adoption_proof_matrix.sh

host-integration:
  needs: [admin-drift-docs, docs-contracts-shift-left]
```

### Shell-Out Harness Pattern For Bash Contracts
```elixir
# Source: accrue/test/accrue/docs/processor_support_matrix_test.exs
script = Path.join(root, "scripts/ci/verify_processor_support_matrix.sh")
assert {output, 0} = System.cmd("bash", [script], cd: root, stderr_to_stdout: true)
assert output =~ "verify_processor_support_matrix: OK"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Phase-history prose embedded in the support matrix | Present-tense canonical contract spine | Not fully completed yet; Phase 114 is the intended closeout. [VERIFIED: .planning/processor-support-matrix.md][VERIFIED: .planning/ROADMAP.md] | Plan 01 should normalize the matrix before mirror edits. [VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-PATTERNS.md] |
| Broad mirror duplication across host/package docs | One canonical matrix plus thin audience-specific needles | Locked in Phase 114 context on 2026-05-07. [VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-CONTEXT.md] | Docs should link back to canon instead of restating entire contracts or full CI inventories. [VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-CONTEXT.md] |
| Ad hoc contract enforcement | Targeted bash scripts + shell-out ExUnit harnesses + `docs-contracts-shift-left` job | Established before Phase 114 and reused by Phases 112 and 113. [VERIFIED: .github/workflows/ci.yml][VERIFIED: .planning/phases/113-cancellation-semantics-closure/113-03-SUMMARY.md][VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-PATTERNS.md] | Phase 114 should extend the existing bundle only at touched surfaces rather than invent new enforcement architecture. [VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-CONTEXT.md] |

**Deprecated/outdated:**
- Stale “checkout and billing portal remain Stripe-only” wording in `accrue/guides/testing.md` and `guides/testing-live-stripe.md`. [VERIFIED: accrue/guides/testing.md][VERIFIED: guides/testing-live-stripe.md]
- Incomplete inline enumeration of `docs-contracts-shift-left` membership in `examples/accrue_host/README.md` and `examples/accrue_host/docs/adoption-proof-matrix.md`. [VERIFIED: examples/accrue_host/README.md][VERIFIED: examples/accrue_host/docs/adoption-proof-matrix.md][VERIFIED: .github/workflows/ci.yml]

## Assumptions Log

All claims in this research were verified from the repo, local commands, or the locked phase context. No user confirmation is required for factual gaps in this document.

## Research Resolution

All planning-relevant questions for Phase 114 are resolved. No open questions remain that block planning.

### Resolved decision 1: host proof docs should stop enumerating full `docs-contracts-shift-left` membership inline

- Evidence: The host README and adoption-proof matrix currently enumerate workflow membership, and both are already stale relative to `.github/workflows/ci.yml`. [VERIFIED: examples/accrue_host/README.md][VERIFIED: examples/accrue_host/docs/adoption-proof-matrix.md][VERIFIED: .github/workflows/ci.yml]
- Resolution: Replace exhaustive inline membership lists in host proof docs with lean summary wording and pointers to `scripts/ci/README.md` for exact bundle membership and `.github/workflows/ci.yml` for CI-home truth. [VERIFIED: scripts/ci/README.md][VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-CONTEXT.md]
- Planning consequence: Phase 114 should both update the host proof docs and tighten the targeted verifiers so those docs fail if they drift back to stale partial inventory claims.

### Resolved decision 2: planning mirrors do not get a permanent support-contract CI gate in this phase

- Evidence: The context explicitly warns against widening the support-contract bundle into unrelated doc territory, and planning mirrors are operational closeout artifacts rather than external contract owners. [VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-CONTEXT.md]
- Resolution: Do not add planning mirrors to `docs-contracts-shift-left` in Phase 114. Close them in the final wave only after the documented support-contract bundle is green, and verify them with phase-local exact-line assertions instead. [VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-PATTERNS.md]
- Planning consequence: `REQUIREMENTS.md`, `ROADMAP.md`, and `STATE.md` should flip to complete only in the final wave, with plan-local validation rather than a new permanent merge-blocking script.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `bash` | All four targeted verifier scripts | ✓ | 5.2.37 | — [VERIFIED: local command] |
| Elixir | ExUnit shell-out harnesses and repo-local doc tests | ✓ | 1.19.5 | — [VERIFIED: local command] |
| `mix` | ExUnit shell-out harnesses and host aliases | ✓ | 1.19.5 | — [VERIFIED: local command] |
| Node.js | `examples/accrue_host` verification aliases and CI host browser lane | ✓ | v22.14.0 | — [VERIFIED: local command] |
| `npm` | `examples/accrue_host` browser install/run steps | ✓ | 11.1.0 | — [VERIFIED: local command] |
| PostgreSQL | Host integration and any local `mix verify.full` replay | ✓ | reachable on local socket | CI service container if local DB is unavailable. [VERIFIED: pg_isready] |

**Missing dependencies with no fallback:**
- None for Phase 114’s targeted bundle. [VERIFIED: local command]

**Missing dependencies with fallback:**
- None. [VERIFIED: local command]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit shell-out harnesses + bash verifiers + repo-local `rg` status checks. [VERIFIED: accrue/test/accrue/docs/processor_support_matrix_test.exs][VERIFIED: accrue/test/accrue/docs/package_docs_verifier_test.exs][VERIFIED: accrue/test/accrue/docs/organization_billing_org09_matrix_test.exs][VERIFIED: accrue/test/accrue/phase_31_nyquist_validation_test.exs] |
| Config file | `accrue/mix.exs` and `examples/accrue_host/mix.exs` aliases; workflow contract in `.github/workflows/ci.yml`. [VERIFIED: accrue/mix.exs][VERIFIED: examples/accrue_host/mix.exs][VERIFIED: .github/workflows/ci.yml] |
| Quick run command | `bash scripts/ci/verify_processor_support_matrix.sh && bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_verify01_readme_contract.sh && bash scripts/ci/verify_adoption_proof_matrix.sh` [VERIFIED: scripts/ci/README.md] |
| Full suite command | `bash scripts/ci/verify_processor_support_matrix.sh && bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_verify01_readme_contract.sh && bash scripts/ci/verify_adoption_proof_matrix.sh && cd accrue && mix test test/accrue/docs/processor_support_matrix_test.exs test/accrue/docs/package_docs_verifier_test.exs test/accrue/docs/organization_billing_org09_matrix_test.exs test/accrue/phase_31_nyquist_validation_test.exs` [VERIFIED: scripts/ci/README.md][VERIFIED: accrue/test/accrue/docs/processor_support_matrix_test.exs][VERIFIED: accrue/test/accrue/docs/package_docs_verifier_test.exs][VERIFIED: accrue/test/accrue/docs/organization_billing_org09_matrix_test.exs][VERIFIED: accrue/test/accrue/phase_31_nyquist_validation_test.exs] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROC-24 | Matrix remains the contract SSOT and no stale staged wording or row drift survives. | bash + ExUnit | `bash scripts/ci/verify_processor_support_matrix.sh` and `cd accrue && mix test test/accrue/docs/processor_support_matrix_test.exs` | ✅ [VERIFIED: scripts/ci/verify_processor_support_matrix.sh][VERIFIED: accrue/test/accrue/docs/processor_support_matrix_test.exs] |
| PROC-24 | Package/public docs mirror the provider-honest contract and Fake/advisory lane posture. | bash + ExUnit | `bash scripts/ci/verify_package_docs.sh` and `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` | ✅ [VERIFIED: scripts/ci/verify_package_docs.sh][VERIFIED: accrue/test/accrue/docs/package_docs_verifier_test.exs] |
| PROC-24 | Example-host README keeps VERIFY-01 proof wording aligned with current support contract. | bash + ExUnit | `bash scripts/ci/verify_verify01_readme_contract.sh` and `cd accrue && mix test test/accrue/phase_31_nyquist_validation_test.exs` | ✅ [VERIFIED: scripts/ci/verify_verify01_readme_contract.sh][VERIFIED: accrue/test/accrue/phase_31_nyquist_validation_test.exs] |
| PROC-24 | Example-host adoption proof matrix mirrors the same bounded proof posture. | bash + ExUnit | `bash scripts/ci/verify_adoption_proof_matrix.sh` and `cd accrue && mix test test/accrue/docs/organization_billing_org09_matrix_test.exs` | ✅ [VERIFIED: scripts/ci/verify_adoption_proof_matrix.sh][VERIFIED: accrue/test/accrue/docs/organization_billing_org09_matrix_test.exs] |
| PROC-24 | Planning mirrors close status cleanly without becoming a second semantic spec. | repo grep / review | `rg -n "PROC-24|Phase 114|v1.36|processor-support-matrix" .planning/REQUIREMENTS.md .planning/ROADMAP.md .planning/STATE.md` | ✅ [VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: .planning/ROADMAP.md][VERIFIED: .planning/STATE.md] |

### Sampling Rate

- **Per task commit:** Run the one verifier that matches the touched surface. [VERIFIED: scripts/ci/README.md]
- **Per wave merge:** Re-run the four-script support-contract bundle from the repo root. [VERIFIED: scripts/ci/README.md]
- **Phase gate:** Full bundle plus the four ExUnit shell-out harnesses; run `bash scripts/ci/accrue_host_uat.sh` only if example-host proof wording or VERIFY-01 flow guidance changes materially. [VERIFIED: scripts/ci/README.md][VERIFIED: examples/accrue_host/mix.exs][VERIFIED: .github/workflows/ci.yml]

### Wave 0 Gaps

- None for the targeted Phase 114 verifier bundle; the shell scripts, workflow job, and ExUnit shell-out harnesses already exist. [VERIFIED: scripts/ci/README.md][VERIFIED: .github/workflows/ci.yml][VERIFIED: accrue/test/accrue/docs/processor_support_matrix_test.exs][VERIFIED: accrue/test/accrue/docs/package_docs_verifier_test.exs][VERIFIED: accrue/test/accrue/docs/organization_billing_org09_matrix_test.exs][VERIFIED: accrue/test/accrue/phase_31_nyquist_validation_test.exs]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase 114 does not change auth flows; keep host-auth statements unchanged in docs. [VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-CONTEXT.md] |
| V3 Session Management | no | Phase 114 does not change session handling; host proof docs stay descriptive only. [VERIFIED: examples/accrue_host/README.md] |
| V4 Access Control | no | No access-control code or policy changes are in scope. [VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-CONTEXT.md] |
| V5 Input Validation | yes | Fixed-string verifier scripts are the standard control for contract wording drift at this phase boundary. [VERIFIED: scripts/ci/verify_processor_support_matrix.sh][VERIFIED: scripts/ci/verify_package_docs.sh][VERIFIED: scripts/ci/verify_verify01_readme_contract.sh][VERIFIED: scripts/ci/verify_adoption_proof_matrix.sh] |
| V6 Cryptography | no | No cryptographic behavior changes are in scope; existing webhook-secret guidance must remain intact. [VERIFIED: CLAUDE.md][VERIFIED: accrue/guides/first_hour.md] |

### Known Threat Patterns for docs/CI contract closeout

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Public contract wording drifts away from canonical runtime/support truth | Tampering | Keep `.planning/processor-support-matrix.md` as SSOT and extend only the surface-local verifier that matches the touched doc. [VERIFIED: .planning/processor-support-matrix.md][VERIFIED: scripts/ci/README.md] |
| Host/proof docs describe an incomplete CI ritual | Repudiation | Make `scripts/ci/README.md` the explicit bundle home and reduce inline script inventories elsewhere. [VERIFIED: scripts/ci/README.md][VERIFIED: examples/accrue_host/README.md][VERIFIED: examples/accrue_host/docs/adoption-proof-matrix.md] |
| Planning mirrors claim closure before proof exists | Integrity | Reserve final `PROC-24` / Phase 114 / `v1.36` completion edits for the final plan after verifier green. [VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: .planning/ROADMAP.md][VERIFIED: .planning/STATE.md][VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-PATTERNS.md] |

## Sources

### Primary (HIGH confidence)
- `CLAUDE.md` - project constraints, stack floors, security posture, and proof philosophy checked. [VERIFIED: CLAUDE.md]
- `.planning/phases/114-contract-drift-gate-closeout/114-CONTEXT.md` - locked decisions, scope boundary, canonical references, and drift-gate philosophy checked. [VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-CONTEXT.md]
- `.planning/phases/114-contract-drift-gate-closeout/114-PATTERNS.md` - recommended 3-plan decomposition and validation structure checked. [VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-PATTERNS.md]
- `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md` - active milestone state and closeout status checked. [VERIFIED: .planning/ROADMAP.md][VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: .planning/STATE.md]
- `.planning/processor-support-matrix.md` - canonical contract wording and stale historical phrasing checked. [VERIFIED: .planning/processor-support-matrix.md]
- `accrue/README.md`, `accrue/guides/first_hour.md`, `accrue/guides/testing.md`, `guides/testing-live-stripe.md` - package/public mirror wording checked. [VERIFIED: accrue/README.md][VERIFIED: accrue/guides/first_hour.md][VERIFIED: accrue/guides/testing.md][VERIFIED: guides/testing-live-stripe.md]
- `examples/accrue_host/README.md`, `examples/accrue_host/docs/adoption-proof-matrix.md` - example-host proof mirrors checked. [VERIFIED: examples/accrue_host/README.md][VERIFIED: examples/accrue_host/docs/adoption-proof-matrix.md]
- `scripts/ci/verify_processor_support_matrix.sh`, `scripts/ci/verify_package_docs.sh`, `scripts/ci/verify_verify01_readme_contract.sh`, `scripts/ci/verify_adoption_proof_matrix.sh`, `scripts/ci/README.md` - verifier coverage and bundle documentation checked. [VERIFIED: scripts/ci/verify_processor_support_matrix.sh][VERIFIED: scripts/ci/verify_package_docs.sh][VERIFIED: scripts/ci/verify_verify01_readme_contract.sh][VERIFIED: scripts/ci/verify_adoption_proof_matrix.sh][VERIFIED: scripts/ci/README.md]
- `.github/workflows/ci.yml` - `docs-contracts-shift-left` membership and host-integration dependency order checked. [VERIFIED: .github/workflows/ci.yml]
- `accrue/test/accrue/docs/processor_support_matrix_test.exs`, `accrue/test/accrue/docs/package_docs_verifier_test.exs`, `accrue/test/accrue/docs/organization_billing_org09_matrix_test.exs`, `accrue/test/accrue/phase_31_nyquist_validation_test.exs` - existing shell-out harnesses checked. [VERIFIED: accrue/test/accrue/docs/processor_support_matrix_test.exs][VERIFIED: accrue/test/accrue/docs/package_docs_verifier_test.exs][VERIFIED: accrue/test/accrue/docs/organization_billing_org09_matrix_test.exs][VERIFIED: accrue/test/accrue/phase_31_nyquist_validation_test.exs]
- `bash scripts/ci/verify_processor_support_matrix.sh`, `bash scripts/ci/verify_package_docs.sh`, `bash scripts/ci/verify_verify01_readme_contract.sh`, `bash scripts/ci/verify_adoption_proof_matrix.sh`, `bash --version`, `elixir --version`, `mix --version`, `node --version`, `npm --version`, `pg_isready` - current local pass/fail state and tool availability checked. [VERIFIED: local command]

### Secondary (MEDIUM confidence)
- None.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Phase 114 reuses existing repo-local bash, ExUnit, workflow, and doc machinery with no new third-party dependency choices. [VERIFIED: repo grep]
- Architecture: HIGH - The phase context, pattern map, and current file layout all point to the same canonical-matrix-plus-thin-mirrors design. [VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-CONTEXT.md][VERIFIED: .planning/phases/114-contract-drift-gate-closeout/114-PATTERNS.md][VERIFIED: repo grep]
- Pitfalls: HIGH - The concrete drift cases are visible in current files and reproducible against passing verifiers. [VERIFIED: accrue/guides/testing.md][VERIFIED: guides/testing-live-stripe.md][VERIFIED: examples/accrue_host/README.md][VERIFIED: examples/accrue_host/docs/adoption-proof-matrix.md][VERIFIED: bash scripts/ci/verify_package_docs.sh][VERIFIED: bash scripts/ci/verify_verify01_readme_contract.sh][VERIFIED: bash scripts/ci/verify_adoption_proof_matrix.sh]

**Research date:** 2026-05-07
**Valid until:** 2026-05-21
