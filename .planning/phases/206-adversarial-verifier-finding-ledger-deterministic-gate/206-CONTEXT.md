# Phase 206: Adversarial verifier + finding ledger + deterministic gate - Context

**Gathered:** 2026-07-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 206 delivers the **noisy-plane adversarial verifier** plus the **deterministic gate plane** of
the UI ratchet — the *pawl* that lets the admin UI only ever move forward. It takes Phase 205's
`candidates.ndjson` and:

1. **DEDUP-03 collapse** — findings raised by multiple persona/design lenses collapse into one work
   item keyed by `finding_id`, carrying `persona_frequency` + the union `raised_by_lenses` set.
2. **Adversarial verify** (`ratchet-verify.mjs`, Opus) — a 3-role skeptic panel (persona advocate,
   brand purist, operator-density defender); 2-of-3 confirm or the candidate is dropped;
   density-defender refutes air-ward fixes; deterministic justification-token re-gate.
3. **Committed forward-only ledger** (`findings.ledger.ndjson` + `ledger.baseline.json`) — an
   append-only lifecycle log (`open → resolved → verified-closed` / `suppressed`) with `cell_refs`
   FKs into the census, plus a per-lens high-water baseline.
4. **Deterministic sibling gate** (`phase-ratchet-ledger.mjs`) + **independent CI re-verifier**
   (`scripts/ci/verify_ratchet_ledger.mjs`) — the LLM never touches this plane; both carry a
   `--self-test` proving the three regression kinds fire and a clean ledger emits zero.

Requirements: **DEDUP-03, VERIFY-01, VERIFY-02, VERIFY-03, LEDGER-01, LEDGER-02, LEDGER-03,
LEDGER-04, LEDGER-05** (9 of 9 for this phase).

**In scope:** the DEDUP-03 collapse reducer; `ratchet-verify.mjs` (Opus panel + median-clamp
aggregation + deterministic token re-gate); the `findings.ledger.ndjson` event-row schema +
lifecycle; `ledger.baseline.json` per-lens shape + `--freeze` mechanism; `reopen-markers.ndjson`;
the suppress-list fold; the `phase-ratchet-ledger.mjs` reducer; the `scripts/ci/verify_ratchet_ledger.mjs`
independent re-verifier; a shared `ratchet-ledger.js` append-helper; two `--self-test` blocks; the
`guard_ref` presence contract (206 defines it; 207 mints the guards).

**Out of scope (later phases):** `mix accrue_admin.ui.round`/`ui.fix` orchestration, the HTML digest +
region overlay + decision queue, batch-approve/reject-to-suppress UI, auto-mint guard producers,
re-capture/re-score, dry-round detector + 6-round cap (all **Phase 207**); running the loop to
convergence, **freezing** the first baseline, wiring the `admin-ui-ratchet-guardrails` CI job, and
maintainer ACCEPT (all **Phase 208**); full-surface sweep (**Phase 209**). The LLM is never a CI merge
gate. No new billing primitives, no route/API changes, no Tailwind migration; core `accrue` stays
LiveView-runtime-free; `ax-*` stays the styling SSOT; ratchet tooling never leaks into adopter runtime.

</domain>

<decisions>
## Implementation Decisions

All four discussed gray areas were researched by parallel advisor subagents (pros/cons/tradeoffs,
Elixir/Phoenix OSS idiom, lessons from comparable ratchet/baseline/suppression systems, DX, footguns)
and synthesized into the cohesive package below. **The four areas cross-corroborate** — the per-lens
count, the live-`open`-write, the append-only ledger, and the phase200-twin discipline reinforce each
other. Two live cross-doc conflicts (baseline keying; the 206/207 "confirm" locus) were resolved in
favor of the **ratified requirements**, exactly as the D-01 claim-key conflict was resolved in Phase
205 — and in both cases the design doc's own prose corroborates the ratified side.

Decision IDs continue from Phase 205 (D-01..D-23). These are **D-24..D-41**, binding for planning.

### Ledger baseline keying — resolves LEDGER-02 "per lens" vs design-doc "[bucket]" (the linchpin)
- **D-24 — The gate's counted key is PER-LENS: a closed 7-value enum (6 `persona:<id>` + `design`),
  comparing severity-SUMMED per-lens open-finding totals.** Severity `{minor, real}` is retained ONLY
  as a non-gating sub-count breakdown inside `ledger.baseline.json` for digest/human legibility — it is
  never an independent gate key. This is the Codecov "per-file/patch, not global-%" lesson: a single
  scalar total masks compensating regressions; partitioning by lens catches the fix-a-few-break-a-few
  failure the ratchet exists to prevent.
- **D-25 — Conflict resolution: PER-LENS wins the gate key; the design doc's `confirmed_open[bucket]`
  reducer expression is downgraded to the informational sub-count.** Three ratified sources agree on
  per-lens — LEDGER-02 ("counts per lens"), LEDGER-03/SC-4 ("any lens's open count exceeds baseline"),
  and the dispositive **CONV-04** ("the regressed lens's open count rises → gate red") — plus the design
  doc's OWN §50 prose ("any new confirmed finding for persona B raises `confirmed_open[persona:B]`").
  Only the design doc's single line-43 `[bucket]` shorthand dissents. D-13's "two counted buckets" is
  **honored, not overridden**: severity survives as the per-lens `{minor,real}` sub-count; it just isn't
  an independent gate key — which BETTER serves D-13's stated purpose (avoid phantom count-gate
  regressions from severity drift) than gating on the bucket would.
- **D-26 — The count is over (finding, lens) pairs via a frozen `raised_by_lenses` set.** A finding that
  DEDUP-03 collapsed across N lenses contributes +1 to EACH of those N lens totals. `raised_by_lenses`
  is recorded on the ledger row at confirmation time and is **sticky — never mutated on re-propose** —
  so a cross-persona regression (improve A, break B) reliably trips persona B's lens. `theme` is NOT a
  lens key (D-17: theme excluded from identity); a both-themes defect is one finding counted once per
  lens. The gate compare is **asymmetric like phase200's `compareCells()`** — fires only on count
  *increase*; improvements ratchet silently (forward-only).
- **D-27 — `ledger.baseline.json` shape** (native to the repo's small-keyed-JSON + `sha256()` idiom):
  `{schema_version, frozen: bool, epoch, frozen_round?, frozen_at?, ledger_sha256, bundle_sha256?,
  slice[], confirmed_open: {"<lens>": {total, minor, real}, …}, resolved_locked: [<claim_key>, …]}`.
  `resolved_locked` stores **claim_key strings** (human-auditable per D-01; the verifier re-derives
  `finding_id`). Lens-key format: `persona:<persona_id>` (prefixed) vs bare `design`.

### Adversarial skeptic panel — structure, vote aggregation, determinism (VERIFY-01..03)
- **D-28 — One Opus call PER IMAGE, three independently-reasoned role verdicts in a single
  strict-structured tool output.** NOT 3 separate calls/candidate (3× cost + re-sends the expensive
  screenshot); NOT one shared free-text verdict (loses perspective diversity, can't do ≥2-of-3). Tool
  schema top level: `{verdicts: [{finding_id, roles: [advocate, brand_purist, density_defender]}]}`,
  each role emitting `{role, bucket ∈ {not-a-defect, minor, real}, justification_token, rationale}`.
  This amortizes image tokens across every candidate on the image (~1 call/image, not 3×N), and orders
  the request **stable-prefix-first** (system preamble + 3-role rubric + tool schema, THEN image +
  candidate list) so ORCH-07 prompt-caching drops in later (Phase 207) without touching identity.
- **D-29 — Vote → outcome = MEDIAN-then-CLAMP.** Map buckets `not-a-defect=0 < minor=1 < real=2`; take
  the median of the 3 role votes. Median `≥ minor` ⇒ **confirmed** (exactly "≥2-of-3 non-refute");
  median `= not-a-defect` ⇒ **killed/suppressed** (handles ties and all-refute cleanly). Final severity
  = the median bucket, then **clamped to ≤ the candidate's proposer severity** (D-13 downgrade-only: the
  verifier may only lower `real→minor` or kill, NEVER invent/upgrade a level). Truth-table and clamp
  examples belong in the plan + the reducer `--self-test`.
- **D-30 — D-21 asymmetric bar is wired into the density-defender's VOTING INSTRUCTION, not the math.**
  For design candidates flagged `direction:"air"`, that role is told to vote `not-a-defect` unless the
  candidate carries a concrete task-completion justification (`job_blocking=true` or a
  `persona-job-miss:<job>` token). This makes VERIFY-02 one of the ≥2 votes needed to kill an
  over-whitespacing finding, while the aggregation stays uniform and deterministic.
- **D-31 — VERIFY-03 justification-token enforcement is a DETERMINISTIC parse-time re-gate, not LLM
  judgment.** Reuse `regionTags.isAdmissibleToken()` (`region-tags.js`) — the same closed-vocab gate
  D-16 uses in the proposer. After the Opus call returns, the harness validates the `justification_token`
  on every *confirmed* verdict; a row without an admissible token is dropped before it can reach the
  ledger.
- **D-32 — Determinism posture: temp-0 is UNAVAILABLE on Opus 4.x (`temperature`/`top_p`/`top_k` are
  removed and return 400).** Determinism leans on **strict structured outputs** (`strict: true`,
  `additionalProperties:false`, enum-constrained buckets) + the harness re-gate — exactly the posture the
  proposer already encodes via `supportsSampling()`. Recommended `VERIFY_MODEL` default `claude-opus-4-8`,
  reusing the proposer's sampling guard so no sampling param is ever sent to Opus 4.x.
- **D-33 — Raw verdicts are EPHEMERAL/regenerated; only the deterministic ledger EFFECT is committed.**
  Per-role verdicts live gitignored under `test-results/` (e.g. `verify-verdicts.ndjson`, twinning
  `candidates.ndjson`). What is committed + reviewed is the harness-computed confirmed set → the
  `open` ledger rows (identity re-derived via `claimKey`/`findingId`, never from the LLM) + the
  deterministic baseline, independently recomputed from raw rows by the gate (LEDGER-04). Reviewers
  trust the committed ledger, not the LLM. This satisfies the plane rule: "nothing crosses from the
  noisy plane to the gate plane except through a committed file."
- **D-34 — The panel inherits AND extends D-15's prompt-injection preamble.** In-screenshot text is
  untrusted; additionally each candidate's `defect`/`suggested_fix` free-text is treated as untrusted
  (that prose was generated by an LLM reading a possibly-injected screenshot — a second injection vector).

### 206/207 ledger-write boundary — resolves SC-3 "206 persists" vs design-doc "human confirms → open"
- **D-35 — HYBRID (option c): 206's verifier is the SINGLE writer that appends 2-of-3-panel-confirmed
  survivors DIRECTLY into the committed `findings.ledger.ndjson` as `open` rows, provenance-tagged.**
  This matches ROADMAP SC-3 + LEDGER-01 literally ("Confirmed findings persist to a committed ledger")
  and reflects that the ratified requirements deliberately relocate the word "confirm" from the human
  (design §Plane A step 5) to the **machine skeptic panel** (VERIFY-01..03) — the same requirement-wins
  precedent as D-01. Every `open` row carries `confirmed_by: [panel roles]` + `panel_votes` +
  `justification_token` + `persona_frequency`, so a maintainer reads *why* it is there and can veto it
  in Phase 207 — but 207 never needs to ADD an `open` row.
- **D-36 — 207 is a pure superset-layer: it only REMOVES (human reject → `suppressed`) or ADVANCES
  (batch-approve → `ui.fix` → `open→resolved` + minted guard → `verified-closed`).** 207 introduces
  ZERO new writers of `open`. This gives Phase 206 a real end-to-end path (candidates → confirmed →
  committed ledger → gate red/green) and avoids 207 re-work. The design-doc alternative ("emit an
  intermediate `verified.ndjson` that 207's human-confirm promotes") is explicitly REJECTED because it
  makes SC-3/LEDGER-01 a 207 deliverable and breaks GSD phase-independence.
- **D-37 — Baseline is NON-EMPTY-but-UNFROZEN in 206; first FROZEN in 208.** "Non-empty" and "frozen"
  are separate properties (the PHPStan/ESLint-baseline idiom). 206 commits an unfrozen
  (`"frozen": false`) baseline whose per-lens counts auto-match the committed ledger's open counts, so
  206's own committed pair is **gate-green by construction** (`open == baseline`); the RED paths are
  proven on synthetic fixtures via `--self-test`. **206 never runs the live LLM to satisfy its success
  criteria** (the phase200 precedent: the reducer/verifier prove themselves on fixtures). The
  `admin-ui-ratchet-guardrails` CI job is not wired until 208 (CONV-03), so an empty/self-matching
  baseline cannot fire a "regression-vs-zero" hazard in 206. 208 re-derives the baseline at the slice
  high-water mark, stamps `"frozen": true` (CONV-02), and only then wires CI. The reducer must refuse to
  WRITE a frozen baseline unless invoked with an explicit `--freeze` flag (208-only), so 207's `ui.fix`
  re-scoring can recompute the *unfrozen* baseline during iteration but can never silently move the
  frozen line.

### Ledger lifecycle, guard_ref & reopen contract (LEDGER-01, LEDGER-03, LEDGER-05)
- **D-38 — Strictly APPEND-ONLY NDJSON event log; one row per lifecycle EVENT with a monotonic `seq`
  int; reducer fold = latest-event-wins per `finding_id` in file order.** Never mutate/delete a row.
  The reducer + independent verifier assert `seq` strictly increasing as tamper-evidence against
  reorder/insertion. This matches forward-only ethos + the ndjson precedent, keeps each transition a
  single legible git-diff line, and preserves full audit history a rewrite-in-place ledger would destroy.
  `event ∈ {confirm, resolve, verify-close, suppress, reopen}` sets `status ∈ {open, resolved,
  verified-closed, suppressed}`. Row schema `ratchet-finding-event/1` carries the D-17 candidate identity
  fields VERBATIM (re-validated through `region-tags.js` — never re-derived from prose) plus lifecycle
  fields: `seq, event, status, round, persona_frequency, raised_by_lenses[], severity, job_blocking,
  effort_class, guard_ref, confirmed_by[], panel_votes, justification_token, suppressed_reason,
  suppressed_note, resolved_round?, bundle_sha256?` + human-only `defect`/`suggested_fix`.
- **D-39 — `guard_ref` is an INLINE greppable token co-located in a git-tracked guard-home spec:
  `"<repo-rel-spec-path>::@ratchet:<finding_id>"`.** The deterministic gate proves guard-presence by
  **static substring read of the committed file** — no Playwright, no test execution. Checks: path-safety
  (no absolute/`..`/backslash; must live under `accrue_admin/e2e/` AND be in a `GUARD_HOME_SPECS`
  allowlist — `foundation-tokens.spec.js`, `admin-interaction-overlay-phase199.spec.js`,
  `reduced-motion.spec.js`, `admin-page-flow-phase200.spec.js`, + the ratchet's own spec); token grammar
  `^@ratchet:f-[0-9a-f]{16}$` with the embedded id equal to the row's `finding_id` (prevents
  cross-wiring); presence (file exists + token substring present, else `guard-missing`). Inline token
  beats a central registry (a registry drifts; a token that lives IN the guarded file cannot claim a
  guard that was deleted — the Credo/Sobelow/ESLint inline-suppression lesson). Uses substring presence,
  NOT whole-file hashing (a guard-home spec legitimately grows as guards accumulate).
- **D-40 — `guard_ref: "ledger-count"` is the explicit no-real-guard SENTINEL** for pure-taste findings
  with no cheap deterministic encoding — the honest residual set, protected solely by the count-baseline
  + re-shoot (the gate SKIPS the file check for it). Documented honest residual: gutting an assertion
  body while keeping the tag is a deliberate, review-visible edit (same trust class as phase200 trusting
  evidence-JSON contents); the count-ledger is the backstop.
- **D-41 — Reopen marker = a SEPARATE committed `reopen-markers.ndjson`, keyed by `finding_id` and bound
  to the current baseline EPOCH (single-use per epoch, not a permanent backdoor).** A `resolved_locked`
  claim reappearing `open` without a matching current-epoch marker → `illegal-reopen` regression row.
  Keeping the marker out of the event-row (as a separate file) makes an illegitimate reopen starkly
  visible in review and impossible to slip in as an event side-effect (the anti-scope-creep guard).
  `suppressed_reason` is a CLOSED enum (`wont-fix-intentional | duplicate-of:<finding_id> | out-of-scope
  | false-positive | accepted-residual | wont-fix-cost`) + free-text `suppressed_note`; the suppress-list
  (fold of `suppress` events + claim_key set) feeds dedup deterministically so a suppressed claim is
  dropped by the verifier before it can re-enter as `open`. Pre-ledger machine kills (no admissible token
  / panel refute) are DROPPED, not written as `suppressed` (only human/maintainer rejects become
  terminal `suppressed` rows).

### Claude's Discretion (safe to leave to research/planning)
- Batch granularity: one Opus call per image (recommended, bounded by `MAX_B64_BYTES`) vs per surface
  (saves calls but risks multi-image payloads over the 5 MB guard).
- Whether per-role `rationale` strings persist to the ephemeral `verify-verdicts.ndjson` for the 207
  digest, or are dropped to save output tokens.
- Whether to set `thinking:{type:"adaptive"}` on the Opus panel (empirical; does not affect the
  committed ledger).
- DEDUP-03 collapse ORDERING — collapse persona-frequency **before** the panel (recommended: verify each
  distinct `finding_id` once, carry `persona_frequency` through, avoid paying Opus per duplicate).
- Exact `baseline.json` field ordering + which freeze-metadata to include; `epoch` as monotonic int vs
  sha256 of prior baseline; whether `persona_frequency` is stored or derived as `raised_by_lenses.length`.
- LEDGER-04 hand-edit catches the verifier should assert (`total == minor+real` per lens; lens keys ∈
  the 7-enum; `resolved_locked ⊆` claim_keys that appear resolved/verified-closed; non-negative ints;
  `seq` monotonic). Detecting an illegitimate cross-commit baseline RAISE (needs git history / re-freeze
  marker) may defer to the 208 re-freeze mechanism rather than the single-commit reducer.
- `resolved_locked` = `verified-closed` only vs `verified-closed ∪ resolved` (lean union); suppress-list
  as pure fold vs a materialized convenience file (must be regenerated, never authoritative); exact
  `GUARD_HOME_SPECS` allowlist membership and whether the ratchet gets its own dedicated guard spec.
- File layout under `accrue_admin/e2e/ratchet/` and whether a shared `ratchet-ledger.js` append-helper
  (typed `appendOpen/Resolved/VerifiedClosed/Suppressed` + fold reducer) is imported by both the gate and
  207's producers so 207 never re-implements transition logic (recommended).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone design & requirements (READ FIRST)
- `~/.claude/plans/ui-ratchet-txt-i-agile-honey.md` — the full v1.56 milestone design (Architecture
  Plane A/B, the ratchet pawl §48-51, maintainer experience, critical-files table, key footguns
  §99-108, verification §111-119). NOTE two supersessions this phase locks: (1) its line-43
  `confirmed_open[bucket]` reducer expression is superseded by **per-lens** keying (D-24/D-25;
  corroborated by its own §50 prose); (2) its §Plane-A-step-5 "maintainer confirms → open" is superseded
  by **machine-panel-confirms → open in 206** (D-35; VERIFY-01..03 relocate "confirm" to the panel).
- `.planning/REQUIREMENTS.md` — DEDUP-03 (line 30), VERIFY-01..03 (34-36), LEDGER-01..05 (40-44) are
  THIS phase; CONV-02/03/04 (freeze + wire + per-lens regression) for 208-handoff awareness.
- `.planning/ROADMAP.md` §"Phase 206" (lines 199-212, SC 1-5 are the binding contract); §"Phase 207"
  (214-229) and §"Phase 208" (231+) to place the 206/207/208 seam correctly.

### Locked upstream decisions (Phase 205 — do NOT re-litigate)
- `.planning/phases/205-persona-design-lens-evaluator-harness/205-CONTEXT.md` — D-01 (coarse 4-axis
  claim-key + `finding_id`), D-02/D-03 (over-collapse is gate-sound; defect_bucket non-identity), D-04
  (identity harness-injected/enum-validated, default codepoint sort), D-10 (region SSOT, orthogonal
  axes), D-12 (`cell_refs` FK, census coexist-by-reference), D-13 (severity 2-level downgrade-only),
  D-14 (`job_blocking` orthogonal), D-15 (persona prompts + injection preamble), D-16 (deterministic
  justification-token gate), D-17 (full `ratchet-candidate/1` row schema incl. `raised_by`, `direction`,
  `effort_hint`, `persona_frequency:1`), D-21 (density-defender higher bar for `direction:air`).

### Reuse / twin targets (promote + twin, don't reinvent)
- `accrue_admin/e2e/phase200-scorecard.mjs` — the forward-only reducer to TWIN: asymmetric
  `compareCells()` (~488-586), `runSelfTest()` (~846-946) on `mkdtemp` fixtures, `sha256()` (~238),
  `regressions.ndjson`-is-0-bytes contract (~755, 989-991).
- `scripts/ci/verify_phase200_scorecard.mjs` — the independent CI re-verifier to TWIN: recompute from
  raw rows (~459-508), `validateArtifactExists`/`validArtifactRef` path-safety (~220-282), `--self-test`
  (~632-746). (Lives at repo-root `scripts/ci/`, NOT under `accrue_admin/`.)
- `accrue_admin/e2e/phase200-judge.mjs` — the existing deterministic-judge pattern (pure evidence
  reducer, not an LLM call); the median-clamp aggregation twins this.
- `accrue_admin/e2e/ratchet/region-tags.js` — the SDK-free identity SSOT: `claimKey()`/`findingId()`
  (~288-306), `isAdmissibleToken()` (~313-318), `runSelfTest()` (~436-459). Consumed by verifier, ledger,
  gate — identity is ALWAYS re-validated here, never trusted from the LLM.
- `accrue_admin/e2e/ratchet/ratchet-propose.mjs` — the SDK call shape to fork for `ratchet-verify.mjs`:
  no-key exit-0 guard, `MAX_B64_BYTES` 5 MB image guard, `supportsSampling()` (~304-306), forced-tool
  structured output, D-15 injection preamble (~119-123), the emitted candidate row (~678-712).

### Guard homes (real spec files — ground `guard_ref` in files that exist)
- `accrue_admin/e2e/foundation-tokens.spec.js`, `accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js`
  (greppable `@phase199 @overlay` title tags ~line 706), `accrue_admin/e2e/reduced-motion.spec.js`,
  `accrue_admin/e2e/admin-page-flow-phase200.spec.js` — the `GUARD_HOME_SPECS` allowlist candidates.

### Vocab / rubric / census grammar
- `accrue_admin/e2e/baseline-manifest.js` — `DIMENSIONS` (12), `OVERLAY_TAGS` (14), `SURFACES`,
  `persona_job`, `surface_type`, `slug()`, `cellId()`, `PROJECTS`, `THEMES`. Source of the 6
  `persona:<id>` lens keys (D-24) + the `cell_refs` FK.
- `.planning/milestones/v1.53-phases/187-audit-baseline/187-RUBRIC.md` — 12-dim + overlay + severity
  meanings; brandbook-supersedes-prompts precedence note.
- `accrue_admin/e2e/ratchet/DESIGN-LENS-RUBRIC.md` — the design-lens sub-rubric (Phase 205 output) the
  brand-purist role draws on.

### Ecosystem idiom (detector-then-baseline / suppression / ratchet conventions)
- `../lattice_stripe/prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` and
  `elixir-best-practices-deep-research.md` — Elixir OSS gate/baseline conventions (Credo, Dialyxir
  `.dialyzer_ignore.exs`, Sobelow skips) that ground the append-only ledger + inline-suppression-token +
  frozen-baseline choices. Cross-language analogs cited in research: Codecov per-file (D-24), PHPStan/
  RuboCop-todo baselines (D-37), Betterer ratchet (D-26), Semgrep/`nosemgrep` inline tokens (D-39).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `phase200-scorecard.mjs` + `verify_phase200_scorecard.mjs`: the exact twin pair — asymmetric compare,
  `runSelfTest()` fixture pattern, `sha256()`/byte-count discipline, independent recompute-from-raw-rows,
  path-safety helpers. `phase-ratchet-ledger.mjs` and `verify_ratchet_ledger.mjs` are near-mechanical
  twins of these two.
- `region-tags.js`: `claimKey`/`findingId`/`isAdmissibleToken`/`runSelfTest` — the SDK-free SSOT the
  verifier + ledger + gate all re-validate identity and tokens through (no LLM-trusted identity).
- `ratchet-propose.mjs`: the SDK-call fork base for `ratchet-verify.mjs` (no-key exit-0, 5 MB guard,
  `supportsSampling()`, forced-tool structured output, injection preamble).
- `phase200-judge.mjs`: the pure deterministic-reducer pattern the median-clamp vote aggregation twins.

### Established Patterns
- **Deterministic gate discipline:** identity + counts from closed-enum structural coordinates; prose
  excluded; proven by fixture `--self-test`, never live API. The gate plane inherits this wholesale.
- **Two-layer census-vs-worklist:** the frozen 30,348-cell scored baseline (`phase200`) is the ≥2 floor
  CONV-01 depends on; the ratchet ledger is a forward-only defect worklist referencing it via `cell_refs`
  (never merged).
- **Detector-then-baseline (new, ecosystem-idiomatic):** machine detects (the panel) → machine
  auto-persists `open` → human accepts (advance) or suppresses; baseline moves only in the fewer-findings
  direction; FREEZING into CI enforcement is a separate deliberate act (208). Mirrors PHPStan/RuboCop-todo/
  Sobelow.
- **Committed-CSS-bundle discipline:** capture must follow `mix accrue_admin.assets.build`; the ledger
  row records `bundle_sha256`.

### Integration Points
- New files all under `accrue_admin/e2e/ratchet/` (`ratchet-verify.mjs`, `findings.ledger.ndjson`,
  `ledger.baseline.json`, `reopen-markers.ndjson`, `phase-ratchet-ledger.mjs`, shared `ratchet-ledger.js`
  append-helper) + `scripts/ci/verify_ratchet_ledger.mjs` — all dev/test-only, none in adopter runtime.
- `accrue_admin/package.json` — wire `ratchet:verify`, `ratchet:ledger` (+ `--self-test`) scripts
  alongside `ratchet:propose`, `phase200:*`.
- The `admin-ui-ratchet-guardrails` CI job (deterministic-only) is DEFINED conceptually here but WIRED in
  Phase 208 beside `admin-phase200-guardrails` in `.github/workflows/ci.yml`.

</code_context>

<specifics>
## Specific Ideas

- `VERIFY_MODEL` defaults to `claude-opus-4-8` (Opus reserved for the verifier per D-17); proposer stays
  on the cheaper `SCORE_MODEL`. Reuse `supportsSampling()` so no `temperature` param is ever sent to
  Opus 4.x (would 400).
- The 7 lens keys: `persona:<id>` for the 6 v1.51 operator personas (from `baseline-manifest.js`
  `persona_job`) + bare `design` for the graphic-design lens.
- Request ordering for the panel is stable-prefix-first specifically to make ORCH-07 prompt-caching a
  drop-in for Phase 207 without disturbing identity or the no-key/self-test paths.
- The honest residual set: `guard_ref: "ledger-count"` findings are the only ones with no real minted
  guard — protected by the count-baseline + re-shoot alone. Keep this set small and visible.

</specifics>

<deferred>
## Deferred Ideas

- **Orchestration `mix accrue_admin.ui.round`/`ui.fix` + HTML digest + region overlay + "decisions needed"
  queue + batch-approve/reject-to-suppress UI + auto-mint guard producers + re-capture/re-score + dry-round
  detector + 6-round cap + prompt-caching (ORCH-07) + surface-subset filter (ORCH-08)** — Phase 207. 206
  defines the contracts (ledger schema, guard_ref shape, effort_class stamp, suppress-list, stable-prefix
  ordering) that 207 fulfills.
- **Run the loop to convergence on the representative slice; FREEZE the first non-empty
  `ledger.baseline.json`; wire the `admin-ui-ratchet-guardrails` deterministic CI job; maintainer ACCEPT +
  runbook** — Phase 208.
- **Full ~19-surface sweep** — Phase 209 (optional/scope-gated).

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 206-adversarial-verifier-finding-ledger-deterministic-gate*
*Context gathered: 2026-07-04*
