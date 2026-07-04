# Phase 206: Adversarial verifier + finding ledger + deterministic gate - Research

**Researched:** 2026-07-04
**Domain:** Node.js/ESM deterministic-reducer tooling + Anthropic Messages API (structured tool output) for a dev/test-only "UI ratchet" gate, twinning existing Phase-200/205 machinery in the accrue_admin monorepo.
**Confidence:** HIGH (all twin targets read verbatim from the working tree; Anthropic API claims cross-checked against the bundled `claude-api` skill reference)

## Summary

Phase 206 is a **twin-and-extend** phase, not greenfield. Every load-bearing pattern it needs already exists in the repo and was read in full for this research: the asymmetric forward-only reducer (`phase200-scorecard.mjs`), its independent CI re-verifier (`scripts/ci/verify_phase200_scorecard.mjs`), the SDK-free identity SSOT (`region-tags.js`), and the Opus/Sonnet SDK-call shape to fork (`ratchet-propose.mjs`). A **live `candidates.ndjson`** already exists on disk (`accrue_admin/test-results/admin-visuals/candidates.ndjson`, 14 rows from a real Phase-205 run) and was inspected directly — its exact row shape (persona and design-lens variants) is reproduced verbatim below so the plan can write against real data, not a schema guess.

The phase splits cleanly into two deliverables that must never cross except through a committed file: (1) an Opus-based adversarial verifier (`ratchet-verify.mjs`) that collapses lens-frequency, runs a 3-role skeptic panel via one forced-tool-use call per image, and appends confirmed rows directly into a committed `findings.ledger.ndjson`; and (2) a pure Node reducer/verifier pair (`phase-ratchet-ledger.mjs` + `scripts/ci/verify_ratchet_ledger.mjs`) that recomputes per-lens open counts from raw ledger rows and never touches the network. Both halves are near-mechanical twins of the Phase-200 scorecard pair — same `mkdtemp`-fixture self-test discipline, same 0-byte-regressions-file contract, same path-safety helpers.

**Primary recommendation:** Fork `ratchet-propose.mjs` into `ratchet-verify.mjs` reusing its exact guard order (`--self-test` → no-key exit-0 → SDK import), its `supportsSampling()` gate, and its D-15 injection preamble; fork `phase200-scorecard.mjs`/`verify_phase200_scorecard.mjs` into `phase-ratchet-ledger.mjs`/`scripts/ci/verify_ratchet_ledger.mjs` reusing their `assertSelfTest`/`mkdtemp`/`sha256` fixture pattern verbatim. Default `VERIFY_MODEL=claude-opus-4-8`, which — unlike the proposer's `SCORE_MODEL` default (`claude-sonnet-4-5`) — genuinely supports `strict: true` structured tool outputs, making D-28's "strict-structured tool output" claim technically real for this model (see Code Examples).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| DEDUP-03 lens-frequency collapse | Noisy plane (Node script, pre-Opus-call) | — | Pure function over `candidates.ndjson` rows; must run before the panel call to avoid paying Opus per duplicate (Claude's Discretion, recommended ordering) |
| VERIFY-01..03 adversarial panel + token re-gate | Noisy plane (`ratchet-verify.mjs`, Opus call) + deterministic re-gate (harness, same file) | — | The LLM call is noisy; the harness-side re-derivation of identity/token validity via `region-tags.js` is deterministic and runs in the same process immediately after the API response |
| LEDGER-01/02 committed ledger + baseline | Deterministic plane (append-helper + `ratchet-verify.mjs` as sole `open`-writer) | — | D-35: the verifier is the single writer of `open` rows; no LLM call happens after this point |
| LEDGER-03/04/05 gate + CI re-verifier | Deterministic plane (`phase-ratchet-ledger.mjs` + `scripts/ci/verify_ratchet_ledger.mjs`) | — | Zero network calls, zero LLM — pure NDJSON/JSON reducers, twin of `phase200-scorecard.mjs`/verifier |
| `guard_ref` presence check | Deterministic plane (static substring read of committed spec files) | — | D-39: no Playwright, no test execution — a `fs.readFileSync` + regex check |
| CI wiring (`admin-ui-ratchet-guardrails` job) | Out of scope (Phase 208) | — | 206 defines the contracts the job will call in 208; do not add the GitHub Actions job itself |

## Package Legitimacy Audit

No new external packages are introduced by this phase. `@anthropic-ai/sdk` (`^0.100.1`, already a `devDependency` in `accrue_admin/package.json`) is reused as-is — the verifier forks `ratchet-propose.mjs`'s existing import, it does not add a new dependency. `node:crypto`, `node:fs`, `node:os`, `node:path`, `node:url` are Node built-ins.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `@anthropic-ai/sdk` | npm | (already installed, pinned `^0.100.1`) | high | github.com/anthropics/anthropic-sdk-typescript | OK | Reused, not newly added |

**Packages removed due to [SLOP] verdict:** none.
**Packages flagged as suspicious [SUS]:** none.

## Architecture Patterns

### System Architecture Diagram

```
candidates.ndjson (Phase 205 output, gitignored)
        │
        ▼
┌───────────────────────────────┐
│ DEDUP-03 collapse (pure fn)    │  groups rows by finding_id, unions raised_by_lenses,
│ inside ratchet-verify.mjs      │  computes persona_frequency = |raised_by_lenses|
└───────────────┬────────────────┘
                │  one distinct finding_id per iteration
                ▼
┌────────────────────────────────────────────┐
│ NOISY PLANE — ratchet-verify.mjs            │
│ 1 Opus call per SOURCE IMAGE (batches all    │
│ candidates on that image into one request)  │
│  • forced tool_use, strict:true schema       │
│  • system preamble = D-15 injection guard    │
│  • 3 role verdicts per finding:               │
│    persona-advocate / brand-purist /          │
│    operator-density-defender                 │
└───────────────┬──────────────────────────────┘
                │ raw verdicts (ephemeral, gitignored
                │ verify-verdicts.ndjson)
                ▼
┌────────────────────────────────────────────┐
│ DETERMINISTIC RE-GATE (same process,         │
│ region-tags.js re-validation)                │
│  • re-derive claim_key/finding_id — never     │
│    trust LLM identity                        │
│  • median-then-clamp vote aggregation         │
│    (bucket ints: not-a-defect=0,minor=1,real=2)│
│  • isAdmissibleToken() re-check per verdict   │
│  • drop if median < minor OR token missing    │
└───────────────┬──────────────────────────────┘
                │ confirmed survivors only
                ▼
┌────────────────────────────────────────────┐
│ COMMITTED LEDGER WRITE (D-35: single writer) │
│ findings.ledger.ndjson  — append `confirm`    │
│ event rows (schema ratchet-finding-event/1)   │
└───────────────┬──────────────────────────────┘
                │
                ▼
┌────────────────────────────────────────────┐
│ DETERMINISTIC PLANE — phase-ratchet-ledger.mjs│
│  • fold ledger events → latest-status-per-id  │
│  • recompute confirmed_open per lens           │
│  • compareCells-style asymmetric compare vs   │
│    ledger.baseline.json (only fires on increase)│
│  • guard_ref presence check (static grep)     │
│  • write finding-regressions.ndjson (0 bytes  │
│    on pass)                                    │
└───────────────┬──────────────────────────────┘
                │
                ▼
┌────────────────────────────────────────────┐
│ scripts/ci/verify_ratchet_ledger.mjs         │
│  independently recomputes counts from RAW    │
│  ledger rows (never trusts baseline.json's    │
│  own numbers) — a hand-edited baseline that   │
│  disagrees fails                              │
└────────────────────────────────────────────┘
```

### Recommended Project Structure
```
accrue_admin/e2e/ratchet/
├── region-tags.js            # EXISTING — identity SSOT, reused unmodified
├── ratchet-propose.mjs       # EXISTING — proposer, reused unmodified
├── ratchet-verify.mjs        # NEW — panel + median-clamp + committed-ledger writer
├── ratchet-ledger.js         # NEW — shared append/fold helper (appendOpen/Resolved/…, fold reducer)
├── phase-ratchet-ledger.mjs  # NEW — deterministic gate reducer (twin of phase200-scorecard.mjs)
├── findings.ledger.ndjson    # NEW — committed, append-only event log
├── ledger.baseline.json      # NEW — committed, unfrozen baseline (D-37)
├── reopen-markers.ndjson     # NEW — committed, epoch-scoped reopen markers
├── DESIGN-LENS-RUBRIC.md     # EXISTING — brand-purist role draws on this
└── exemplars/                # EXISTING — unused by 206 directly

scripts/ci/
└── verify_ratchet_ledger.mjs # NEW — independent CI re-verifier (repo-root, NOT accrue_admin/)
```

### Pattern 1: Guard ordering (fork from `ratchet-propose.mjs`)
**What:** Three guards run in this exact order, all before any SDK import: (1) `--self-test` branch calling a pure self-test with no key/SDK, (2) no-key `exit 0` guard reading `ANTHROPIC_API_KEY`, (3) dynamic `import()` of the manifest + `@anthropic-ai/sdk`.
**When to use:** Every entry point in `ratchet-verify.mjs` — this ordering is what makes `--self-test` runnable in CI with zero `ANTHROPIC_API_KEY` and no `ERR_MODULE_NOT_FOUND` risk.
**Example:**
```javascript
// Source: accrue_admin/e2e/ratchet/ratchet-propose.mjs:47-71 (verbatim pattern to fork)
if (process.argv.includes("--self-test")) {
  regionTags.runSelfTest();
  process.exit(0);
}
if (!process.env.ANTHROPIC_API_KEY) {
  console.log("[ratchet-verify] ANTHROPIC_API_KEY not set — skipping (human/CI gate only)");
  process.exit(0);
}
const { default: Anthropic } = await import("@anthropic-ai/sdk");
const client = new Anthropic();
```

### Pattern 2: Forced tool_use with `strict: true` (NEW capability vs. the proposer)
**What:** Unlike `ratchet-propose.mjs` (SCORE_MODEL defaults to `claude-sonnet-4-5`, which does **not** support `strict: true` — its enums are advisory-only per that file's own Pitfall-2 comment), the verifier's default `VERIFY_MODEL=claude-opus-4-8` **does** support strict structured tool outputs. This makes D-28's "strict-structured tool output" claim literally enforceable at the model level, not just advisory.
**When to use:** The panel's `emit_verdicts` tool definition.
**Example:**
```javascript
// Source: bundled claude-api skill — "Strict tool use (no beta): set strict: true as a
// top-level field on the tool definition... Schema must have additionalProperties:false + required."
// Structured Outputs support list explicitly includes Claude Opus 4.8.
const PANEL_TOOL = {
  name: "emit_verdicts",
  description: "Return one 3-role verdict set per candidate finding on this image.",
  strict: true,
  input_schema: {
    type: "object",
    additionalProperties: false,
    properties: {
      verdicts: {
        type: "array",
        items: {
          type: "object",
          additionalProperties: false,
          properties: {
            finding_id: { type: "string" },
            roles: {
              type: "array",
              items: {
                type: "object",
                additionalProperties: false,
                properties: {
                  role: { type: "string", enum: ["advocate", "brand_purist", "density_defender"] },
                  bucket: { type: "string", enum: ["not-a-defect", "minor", "real"] },
                  justification_token: { type: "string" },
                  rationale: { type: "string" },
                },
                required: ["role", "bucket", "justification_token"],
              },
            },
          },
          required: ["finding_id", "roles"],
        },
      },
    },
    required: ["verdicts"],
  },
};
```
Even with `strict: true` at the model level, the harness MUST still re-validate every field via `region-tags.js` (`isAdmissibleToken()`, closed-enum checks) before it reaches the ledger — `strict` guarantees the *shape* validates, not that a hallucinated `finding_id` that doesn't exist in `candidates.ndjson` is rejected. Treat strict output as a determinism upgrade, not a replacement for the harness re-gate.

### Pattern 3: Median-then-clamp vote aggregation (pure function, twin of `phase200-judge.mjs`'s discipline)
**What:** `phase200-judge.mjs` is not literally a voting reducer — it is table-driven (`REQUIRED_ARTIFACTS`, `BLOCKING_SEVERITIES` per `defect_bucket`) — but it establishes the pattern to twin: a **pure, deterministic function over structured input, never an LLM call**, that maps discrete inputs to a pass/fail plus severity via a lookup table. The median-clamp aggregation for VERIFY-01..03 follows this same discipline.
**When to use:** Immediately after parsing the Opus tool_use response, before any ledger write.
**Example:**
```javascript
// bucket ints per D-29
const BUCKET_RANK = { "not-a-defect": 0, minor: 1, real: 2 };
const RANK_BUCKET = ["not-a-defect", "minor", "real"];

function medianClamp(roleVerdicts, proposerSeverity) {
  const ranks = roleVerdicts.map((v) => BUCKET_RANK[v.bucket]).sort((a, b) => a - b);
  const median = ranks[1]; // 3 roles -> middle of sorted array
  if (median === 0) return { confirmed: false, severity: null };
  const proposerRank = proposerSeverity === "real" ? 2 : 1;
  const clamped = Math.min(median, proposerRank); // D-13: downgrade-only, never upgrade
  return { confirmed: true, severity: RANK_BUCKET[clamped] };
}
```

### Pattern 4: Asymmetric forward-only compare (fork from `phase200-scorecard.mjs:compareCells`, lines 488-586)
**What:** Only fires a regression when the current value is *worse* than baseline; never regresses on improvement. For 206 this becomes a per-lens count comparison instead of per-cell score/coverage comparison.
**When to use:** `phase-ratchet-ledger.mjs`'s core reducer.
**Example:**
```javascript
// Source: accrue_admin/e2e/phase200-scorecard.mjs:523-537 (pattern to port from score/coverage
// to per-lens open-count comparison)
for (const lens of LENS_KEYS) {
  const baselineCount = baseline.confirmed_open[lens]?.total ?? 0;
  const currentCount = currentOpenCounts[lens]?.total ?? 0;
  if (currentCount > baselineCount) {
    regressions.push(regressionRow("count-increase", lens, baselineCount, currentCount));
  }
  // currentCount < baselineCount → silent ratchet forward, NOT a regression
}
```

### Anti-Patterns to Avoid
- **Trusting LLM-supplied `finding_id`/`claim_key` in the panel response:** always re-derive via `region-tags.js` from the row's own identity fields (`surface`, `dimension`, `region_tag`, `overlay_tags`) that were already harness-validated at proposal time (D-17 fields carried verbatim) — never from the tool_use JSON the panel returned.
- **Writing `open` rows anywhere except `ratchet-verify.mjs`:** D-35/D-36 make this the sole writer; a second writer (e.g. an ad-hoc script) breaks the "one committed writer" invariant Phase 207 depends on.
- **Sending `temperature`/`top_p`/`top_k` to Opus 4.8:** returns HTTP 400. Reuse `supportsSampling(model)` from `ratchet-propose.mjs` verbatim (its regex already excludes `opus-4-6`/`opus-4-7`/`opus-4-8`/`sonnet-5`/`fable-5`) — do not add a special case, the existing gate already does the right thing for the recommended default model.
- **Regenerating a frozen baseline without `--freeze`:** D-37 requires the reducer to refuse writing `"frozen": true` unless invoked with an explicit `--freeze` flag reserved for Phase 208.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Claim-key / finding-id derivation | A new hashing scheme in `ratchet-verify.mjs` | `region-tags.js`'s `claimKey()`/`findingId()` (imported, not reimplemented) | Byte-identical determinism with the proposer is load-bearing — any drift breaks cross-file `finding_id` matching |
| Justification-token validation | A second regex for `persona-job-miss:<job>` | `region-tags.js`'s `isAdmissibleToken()` | Single source of truth already proven by Phase-205's self-test; a second implementation risks silent divergence |
| Path-safety / artifact-ref validation | New ad-hoc `path.isAbsolute` checks | Port `validArtifactRef`/`artifactRefPath`/`validateArtifactExists` from `scripts/ci/verify_phase200_scorecard.mjs:220-282` | These already handle `..`, backslashes, absolute paths, and byte/sha256 cross-checks against a manifest |
| Self-test fixture scaffolding | A custom temp-dir + assertion helper | `assertSelfTest()` + `fs.mkdtempSync(path.join(os.tmpdir(), ...))` + `fs.rmSync(..., {recursive:true, force:true})` pattern from `phase200-scorecard.mjs:841-946` | Exact twin already proven to work in CI; reinventing risks leaking temp dirs or missing the `finally` cleanup |
| Anthropic tool-call determinism | A custom retry/majority-vote loop across N separate API calls | Single call with `strict: true` + `additionalProperties: false` + enum-constrained buckets (Opus 4.8 supports this) | D-28's explicit rationale: 3 separate calls would 3x the cost and re-send the expensive screenshot each time |

**Key insight:** Every piece of "new" logic in this phase is a structural fork of code that already exists and already has a passing self-test in this repo. The main net-new logic is the median-clamp vote aggregation (a ~10-line pure function) and the ledger event-fold reducer (`latest-event-wins per finding_id in file order`) — both should be written as small, independently self-testable pure functions per the phase200 discipline, not as one monolithic script.

## Runtime State Inventory

Not applicable — this phase does not rename, refactor, or migrate any existing identifier, datastore key, or registered OS state. It adds new files under a new namespace (`accrue_admin/e2e/ratchet/`). Skipping this section per the greenfield-phase carve-out.

## Common Pitfalls

### Pitfall 1: Reading `content[0]` instead of the forced `tool_use` block
**What goes wrong:** Under forced `tool_choice: {type: "tool", name: ...}`, `response.content[0]` is not guaranteed to be the tool_use block (a `thinking` block, if enabled, precedes it).
**Why it happens:** Copy-pasting from non-forced-tool-use examples.
**How to avoid:** `response.content.find((b) => b.type === "tool_use")?.input` — exactly as `ratchet-propose.mjs:455` and `:480` already do. This is RESEARCH-documented Pitfall 6 from Phase 205 and applies unchanged here.
**Warning signs:** `undefined` where `.input.verdicts` is expected; crashes only when `thinking` happens to be enabled.

### Pitfall 2: Sending `thinking: {type: "adaptive"}` without also handling thinking blocks in the response parse
**What goes wrong:** If the plan opts into adaptive thinking (Claude's Discretion item), the response will include `thinking`-type content blocks that must be skipped when searching for `tool_use`, and by default (`display: "omitted"`) their `.thinking` field streams empty text.
**Why it happens:** Opus 4.8 does NOT enable thinking by default when the `thinking` param is omitted (unlike Sonnet 5) — so a plan that assumes "thinking is on because it's Opus" will silently get no thinking blocks at all unless the param is set explicitly.
**How to avoid:** Either omit `thinking` entirely (simplest, matches the proposer's behavior) or set `thinking: {type: "adaptive", display: "summarized"}` explicitly and keep the existing `.find((b) => b.type === "tool_use")` pattern, which already skips non-matching block types safely.
**Warning signs:** None if `thinking` is simply omitted — this is a "don't accidentally think you get it for free" pitfall, not a live bug in the twin pattern.

### Pitfall 3: Treating `guard_ref` presence as a Playwright assertion
**What goes wrong:** D-39 explicitly specifies a **static substring read** of the committed spec file (`fs.readFileSync` + regex on the token grammar `^@ratchet:f-[0-9a-f]{16}$`), not running the spec through Playwright.
**Why it happens:** The obvious-looking way to "check a guard exists" is to run the test and see if it passes — but that reintroduces browser/CI cost and non-determinism (D-40's honest-residual rationale explicitly rejects re-running tests as the check).
**How to avoid:** Grep the file text for the exact token string; verify (a) the file is inside `accrue_admin/e2e/` AND in the `GUARD_HOME_SPECS` allowlist, (b) no path traversal (`..`, absolute, backslash) per the existing `validArtifactRef`-style checks, (c) the embedded finding_id matches the row's own `finding_id`.
**Warning signs:** A plan task that says "run `npm run e2e:phase199`" as part of the gate reducer is a scope violation — that belongs to CI's existing test suites, not this deterministic gate.

### Pitfall 4: Confusing playwright `@phase199`-style test-filter tags with the `@ratchet:<finding_id>` guard token
**What goes wrong:** The existing guard-home spec files (`admin-interaction-overlay-phase199.spec.js` etc.) already use `@phase199 @overlay`-style tags inside `test("...")` title strings for Playwright's `--grep` filtering. The NEW `@ratchet:f-<16hex>` token is a **different, unrelated convention** — it is not meant to be grep-filterable by Playwright, it exists purely as a substring the deterministic gate reads from the raw file text (could live in a comment, an assertion message, anywhere in the file).
**Why it happens:** Both look like `@tag` strings inside spec files, inviting the assumption they serve the same purpose.
**How to avoid:** Document explicitly in the plan that `@ratchet:<finding_id>` need not be inside a `test(...)` title at all — it can be a code comment adjacent to the assertion that guards the finding. Confirmed via grep: the four candidate `GUARD_HOME_SPECS` files exist on disk (`foundation-tokens.spec.js`, `admin-interaction-overlay-phase199.spec.js`, `reduced-motion.spec.js`, `admin-page-flow-phase200.spec.js`) and already carry the `@phase199 @overlay`-style tags at e.g. line 706 — but none currently carry any `@ratchet:` token (expected — that's this phase's job to introduce, or to specify the contract that Phase 207's guard-minting will follow).
**Warning signs:** A plan or code review that expects `@ratchet:` tokens to show up in `npx playwright test --grep` output.

## Code Examples

### Real `candidates.ndjson` row shapes (live data, read directly from disk — not reconstructed from schema docs)

Persona-lens row (`accrue_admin/test-results/admin-visuals/candidates.ndjson`, row 1 of 14):
```json
{
  "schema_version": "ratchet-candidate/1",
  "run_id": "run-2026-07-04T01-34-40-359Z-408f7539",
  "round": 1,
  "model": "claude-sonnet-4-5",
  "bundle_sha256": "75f9dc74f8c97ed9270f9dd674ceb2e65be59381945be00a3e1269cc43f543c5",
  "png_ref": "chromium-desktop/component-kitchen-dark.png",
  "viewport": "chromium-desktop",
  "theme": "dark",
  "state": "default-populated",
  "cell_refs": [],
  "surface": "component-kitchen",
  "surface_type": "component",
  "dimension": 2,
  "dimension_name": "visual-hierarchy",
  "overlay_tags": [],
  "region_tag": "content-body",
  "claim_key": "component-kitchen__d02__content-body__ov-none",
  "finding_id": "f-011e039ee1aa7197",
  "severity": "real",
  "job_blocking": true,
  "defect_bucket": null,
  "justification_token": "persona-job-miss:Watch the dunning funnel + at-risk",
  "raised_by": { "lens_kind": "persona", "persona_id": "recovery-growth-ops", "job": "Watch the dunning funnel + at-risk" },
  "persona_frequency": 1,
  "effort_hint": null,
  "defect": "...",
  "suggested_fix": "..."
}
```

Design-lens row (row from the same file — note `direction`/`exemplar_ref` present, `raised_by.lens_kind: "design"` with no `persona_id`):
```json
{
  "schema_version": "ratchet-candidate/1",
  "surface": "component-kitchen",
  "dimension": 3,
  "dimension_name": "spacing-rhythm",
  "region_tag": "layer",
  "claim_key": "component-kitchen__d03__layer__ov-none",
  "finding_id": "f-bbeed3b6e423191d",
  "severity": "real",
  "job_blocking": false,
  "justification_token": "rubric-dim-below-bar",
  "raised_by": { "lens_kind": "design" },
  "direction": "air",
  "exemplar_ref": "exemplars/good/dev-components.png",
  "persona_frequency": 1
}
```
**Important for DEDUP-03:** these two rows have **different `finding_id`s** (different `dimension`/`region_tag`), so they do NOT collapse into one work item under this sample data — DEDUP-03 collapse only fires when two-or-more rows share the exact same `finding_id` (i.e., same `surface`+`dimension`+`region_tag`+`overlay_tags`). The plan's fixtures for DEDUP-03 must construct synthetic rows with matching identity fields to actually exercise the collapse path, since this live sample happens not to contain a naturally-occurring collision.

### `ratchet-finding-event/1` row shape (D-38, to implement)
```json
{
  "schema_version": "ratchet-finding-event/1",
  "seq": 1,
  "event": "confirm",
  "status": "open",
  "surface": "component-kitchen",
  "dimension": 2,
  "region_tag": "content-body",
  "overlay_tags": [],
  "claim_key": "component-kitchen__d02__content-body__ov-none",
  "finding_id": "f-011e039ee1aa7197",
  "round": 1,
  "persona_frequency": 1,
  "raised_by_lenses": ["persona:recovery-growth-ops"],
  "severity": "real",
  "job_blocking": true,
  "effort_class": null,
  "guard_ref": null,
  "confirmed_by": ["advocate", "brand_purist", "density_defender"],
  "panel_votes": { "advocate": "real", "brand_purist": "minor", "density_defender": "real" },
  "justification_token": "persona-job-miss:Watch the dunning funnel + at-risk",
  "suppressed_reason": null,
  "suppressed_note": null,
  "resolved_round": null,
  "bundle_sha256": "75f9dc74f8c97ed9270f9dd674ceb2e65be59381945be00a3e1269cc43f543c5",
  "defect": "...",
  "suggested_fix": "..."
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| Advisory-only enums on the proposer (Sonnet 4.5 lacks strict structured outputs) | `strict: true` + `additionalProperties:false` genuinely enforceable on the verifier's default model (Opus 4.8) | Phase 205 → 206 (model choice, not an API change) | The verifier can lean harder on model-level shape enforcement than the proposer could, while still keeping the harness re-gate as the real trust boundary |
| `temperature: 0` for determinism | Sampling params fully removed (400) on Opus 4.7/4.8, Sonnet 5, Fable 5; determinism instead comes from strict schemas + harness re-validation | Ongoing since Opus 4.7 | `ratchet-propose.mjs`'s `supportsSampling()` regex already correctly excludes the verifier's target model — reuse it unmodified |

**Deprecated/outdated:** Manual `budget_tokens` extended thinking is deprecated on Opus 4.6+ and fully removed (400) on Opus 4.7/4.8 — not relevant here since the plan should default to omitting `thinking` entirely (matching the proposer's behavior) rather than opting into adaptive thinking.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `VERIFY_MODEL` default `claude-opus-4-8` is available to the maintainer's API key at plan-execution time | Summary, Pattern 2 | If unavailable, the verifier's no-key/self-test paths still work (they never call the API); only a live run would fail, and would surface as an ordinary API error, not a design flaw |
| A2 | The 4 `GUARD_HOME_SPECS` candidate files' current line counts/structure remain stable through Phase 206's implementation window | Pitfall 4 | Low risk — these are Phase 199/200 artifacts already merged and stable; a plan task should re-verify file existence at execution time rather than trust this research's line numbers verbatim |

**If this table is empty:** N/A — two low-risk assumptions listed above; both are operational (verify-at-execution-time), not design-blocking.

## Open Questions

1. **Exact `GUARD_HOME_SPECS` allowlist membership and whether the ratchet gets its own dedicated guard-home spec file**
   - What we know: The four existing candidates all exist on disk and already carry Playwright `@phase199`-style filter tags unrelated to the new `@ratchet:` token grammar.
   - What's unclear: Whether 206 should also create a fifth dedicated guard-home spec (e.g., `ratchet-guards.spec.js`) for `ledger-count`-sentinel findings that have no natural home in an existing spec, versus requiring every real-guard finding to land in one of the four existing files.
   - Recommendation: Left as Claude's Discretion per CONTEXT.md — the plan should decide based on how many pure-taste vs. mechanically-guardable findings actually appear in the confirmed set, which won't be known until the verifier runs.

2. **Whether per-role `rationale` strings persist to the ephemeral `verify-verdicts.ndjson`**
   - What we know: D-33 marks raw verdicts as ephemeral/regenerated (gitignored under `test-results/`), twinning `candidates.ndjson`'s own gitignore status.
   - What's unclear: Whether Phase 207's digest needs the `rationale` text for human review, or whether the committed ledger's `defect`/`suggested_fix` fields (carried through from the candidate row) are sufficient.
   - Recommendation: Include `rationale` in the ephemeral file (low cost, no committed-artifact bloat) and let Phase 207 decide whether to surface it — deferring the decision costs nothing now.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | All new `.mjs` files | ✓ (repo already runs Node-based e2e tooling) | matches `accrue_admin/package.json` engine expectations (Node 22 in CI, per `.github/workflows/ci.yml`) | — |
| `@anthropic-ai/sdk` | `ratchet-verify.mjs` live-model path only | ✓ (already a devDependency, `^0.100.1`) | 0.100.1 | No-key guard makes this optional at runtime for CI/self-test paths |
| `ANTHROPIC_API_KEY` | Live verifier runs only | Not required for `--self-test` or CI | — | Exit-0 skip guard (EVAL-03 precedent, reused verbatim) |

**Missing dependencies with no fallback:** none — every new artifact this phase produces (ledger, baseline, gate, CI verifier) must be provable via `--self-test` fixtures with zero external dependencies, per D-37.

**Missing dependencies with fallback:** `ANTHROPIC_API_KEY` — the entire noisy-plane verifier gracefully no-ops without it (matches the existing `ratchet-propose.mjs` and `EVAL-03` precedent); the deterministic plane never depends on it at all.

## Validation Architecture

`workflow.nyquist_validation` is `true` in `.planning/config.json` — this section is required.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Plain Node.js scripts with hand-rolled `assertSelfTest()` helper (twin of `phase200-scorecard.mjs`/`verify_phase200_scorecard.mjs`) — no test runner (Jest/Mocha/Vitest) is used for this plane |
| Config file | none — self-tests are invoked via `node <file>.mjs --self-test` per the existing package.json script convention (`"ratchet:self-test": "node e2e/ratchet/ratchet-propose.mjs --self-test"`) |
| Quick run command | `node accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs --self-test` |
| Full suite command | `node accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs --self-test && node scripts/ci/verify_ratchet_ledger.mjs --self-test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DEDUP-03 | Two candidate rows with identical `finding_id` collapse into one work item with `persona_frequency` = union count | unit (fixture) | assertion inside `ratchet-verify.mjs`'s own `--self-test` block (or a dedicated `region-tags.js`-style pure-function test) | ❌ Wave 0 |
| VERIFY-01 | 2-of-3 panel roles voting `≥minor` confirms; 2-of-3 voting `not-a-defect` kills | unit (fixture, pure `medianClamp()` truth table) | `node accrue_admin/e2e/ratchet/ratchet-verify.mjs --self-test` | ❌ Wave 0 |
| VERIFY-02 | A `direction:"air"` candidate without `job_blocking`/`persona-job-miss` is voted `not-a-defect` by the density-defender role instruction (prompt-level; the deterministic-side assertion is that the median-clamp math correctly kills a 1-of-3-confirm case) | unit (fixture, math only — the actual density-defender voting behavior is LLM-side and NOT synthetically provable, see caveat below) | same self-test file | ❌ Wave 0 |
| VERIFY-03 | A verdict without an admissible `justification_token` is dropped before ledger write | unit (fixture) | `isAdmissibleToken()` fixtures already exist in `region-tags.js`'s own self-test (7 classes); extend or reuse | ✅ (existing `region-tags.js` self-test covers the token-gate function itself) |
| LEDGER-01 | Ledger event row folds correctly through `open → resolved → verified-closed` and `→ suppressed` | unit (fixture, `mkdtemp`) | `node accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs --self-test` | ❌ Wave 0 |
| LEDGER-02 | Baseline records `confirmed_open` per lens (7-enum) + `resolved_locked` claim-key set | unit (fixture) | same | ❌ Wave 0 |
| LEDGER-03 | Count-increase, missing-guard, and reopened-locked-claim each independently produce a regression row | unit (fixture, 3 distinct synthetic scenarios) | same | ❌ Wave 0 |
| LEDGER-04 | `finding-regressions.ndjson` 0 bytes on pass; CI script recomputes from raw rows and fails on hand-edited-baseline disagreement | unit (fixture) | `node scripts/ci/verify_ratchet_ledger.mjs --self-test` | ❌ Wave 0 |
| LEDGER-05 | Both reducer and verifier `--self-test` prove all 3 regression kinds fire + clean ledger emits zero | unit (fixture, twin of `phase200-scorecard.mjs:846-946` + `verify_phase200_scorecard.mjs:632-746`) | both commands above | ❌ Wave 0 |

**Nyquist caveat on VERIFY-02:** the *voting instruction* itself (telling the density-defender role to lean toward `not-a-defect` for `direction:"air"` candidates) is a prompt-engineering behavior that lives inside the Opus system/user prompt — it cannot be proven by a synthetic fixture without calling the live model, and per D-37 this phase's success criteria must NOT depend on a live LLM call. The **deterministic** half of VERIFY-02 that IS provable via `--self-test` is: given a synthetic 3-role vote array where the density-defender voted `not-a-defect`, the median-clamp math correctly produces `confirmed: false` when the other two roles split 1 `real` / 1 `minor` (median = minor... wait — actually median of [0,1,2] sorted is 1 = minor ⇒ confirmed). The plan should construct its self-test fixtures around vote *arrays*, not around "does Opus follow the density-defender instruction" — that instruction-following question is a live-model quality question for the maintainer to spot-check manually, not a gate criterion.

### Sampling Rate
- **Per task commit:** `node <changed-file>.mjs --self-test`
- **Per wave merge:** run both self-tests in sequence (reducer, then CI verifier)
- **Phase gate:** both self-tests green; `findings.ledger.ndjson` + `ledger.baseline.json` committed and self-matching (`open == baseline`, unfrozen) per D-37 — this phase never runs the live LLM to satisfy its own success criteria

### Wave 0 Gaps
- [ ] `accrue_admin/e2e/ratchet/ratchet-verify.mjs` — new file, no self-test yet exists (covers DEDUP-03, VERIFY-01..03)
- [ ] `accrue_admin/e2e/ratchet/ratchet-ledger.js` — new shared append/fold helper, no self-test yet exists
- [ ] `accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs` — new file, no self-test yet exists (covers LEDGER-01..05)
- [ ] `scripts/ci/verify_ratchet_ledger.mjs` — new file, no self-test yet exists (covers LEDGER-04/05)
- [ ] Framework install: none — reuses the already-installed `@anthropic-ai/sdk` and Node built-ins only

## Security Domain

`security_enforcement` is not set in `.planning/config.json` (absent = enabled). This phase is dev/test-only tooling with no production auth/session/data surface, so the ASVS table below is scoped to what actually applies: prompt-injection handling and path-safety, which are the two real threat surfaces this phase touches.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Local-maintainer-run tooling; `ANTHROPIC_API_KEY` is the only credential and is never persisted by this phase's code |
| V3 Session Management | No | N/A — no session concept in this tooling |
| V4 Access Control | No | N/A — CI-side gate has no privilege boundary beyond "is this file inside the repo" |
| V5 Input Validation | Yes | Every field entering the ledger is re-validated against `region-tags.js`'s closed enums (`REGION_TAGS`, `OVERLAY_TAGS`, dimension 1-12) and `isAdmissibleToken()` — never trust the LLM tool_use payload directly |
| V6 Cryptography | Partial | `sha256()` (via `node:crypto`, twin of `phase200-scorecard.mjs:238`) is used for `bundle_sha256`/artifact-integrity provenance only, not for any secret material |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Prompt injection via in-screenshot text (a persona/design candidate's `defect`/`suggested_fix` free-text was itself generated by an LLM reading a possibly-injected screenshot — a second-order injection vector, per D-34) | Tampering / Elevation of Privilege | Extend the existing D-15 system-preamble injection guard from `ratchet-propose.mjs:119-123` (treat in-image text as untrusted data) to explicitly also treat the *candidate row's own free-text fields* as untrusted when they are re-surfaced to the Opus panel as context |
| Path traversal via a hallucinated `guard_ref` spec path | Tampering | Reuse the `validArtifactRef`/`artifactRefPath` path-safety helpers ported from `scripts/ci/verify_phase200_scorecard.mjs:220-282` — reject `..`, absolute paths, backslashes; require membership in the `GUARD_HOME_SPECS` allowlist under `accrue_admin/e2e/` |
| Ledger tampering via out-of-order or reordered NDJSON rows | Tampering | D-38's monotonic `seq` assertion in both the reducer and the independent CI verifier — a reordered/inserted row breaks the strictly-increasing invariant and fails the gate |
| Illegitimate reopen of a `resolved_locked` claim | Tampering | D-41's epoch-scoped `reopen-markers.ndjson` — a `resolved_locked` claim reappearing `open` without a matching current-epoch marker fires `illegal-reopen` |

## Sources

### Primary (HIGH confidence)
- `accrue_admin/e2e/phase200-scorecard.mjs` (full file read) — forward-only reducer, `compareCells`, `sha256`, `runSelfTest`, `main()` regression-gate behavior
- `scripts/ci/verify_phase200_scorecard.mjs` (full file read) — independent re-verifier, path-safety helpers, `runSelfTest`
- `accrue_admin/e2e/phase200-judge.mjs` (partial read, structure confirmed) — table-driven deterministic evidence reducer pattern
- `accrue_admin/e2e/ratchet/region-tags.js` (full file read) — identity SSOT, closed enums, `runSelfTest` (7 DEDUP classes + golden-hash + slug parity)
- `accrue_admin/e2e/ratchet/ratchet-propose.mjs` (full file read) — SDK-call fork base, guard ordering, persona/design lens prompts, `supportsSampling()`, emitted row schema
- `accrue_admin/e2e/baseline-manifest.js` (partial read) — `DIMENSIONS`, `OVERLAY_TAGS`, `SURFACES`, `PROJECTS`, `cellId()`, `slug()`
- `accrue_admin/test-results/admin-visuals/candidates.ndjson` (live data, read directly) — real 14-row output from an actual Phase-205 proposer run, both persona and design-lens row shapes confirmed
- `accrue_admin/package.json` (read) — confirmed `ratchet:propose`/`ratchet:self-test` script wiring, `@anthropic-ai/sdk ^0.100.1`
- `.planning/phases/205-persona-design-lens-evaluator-harness/205-CONTEXT.md` (read) — locked upstream decisions D-01..D-23
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md` §Phase 206 (read) — binding success criteria SC1-5
- `.planning/config.json` (read) — `nyquist_validation: true` confirmed
- Bundled `claude-api` skill reference (Anthropic-maintained, current as of 2026-07) — model catalog, structured-outputs support list, sampling-parameter removal on Opus 4.7/4.8, strict tool use syntax

### Secondary (MEDIUM confidence)
- `accrue_admin/e2e/foundation-tokens.spec.js`, `admin-interaction-overlay-phase199.spec.js`, `reduced-motion.spec.js`, `admin-page-flow-phase200.spec.js` (existence + a sample of the `@phase199 @overlay` title-tag convention confirmed via `ls`/`grep`, not full-file read) — `GUARD_HOME_SPECS` allowlist candidates

### Tertiary (LOW confidence)
- None — every claim in this document was either read directly from the working tree or cross-checked against the bundled Anthropic API skill reference.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages; `@anthropic-ai/sdk` version and model IDs verified against the bundled skill reference
- Architecture: HIGH — every twin-target file was read in full or substantially, with line numbers cross-checked against canonical_refs (one minor line-range discrepancy flagged in Open Questions/Pitfalls is informational only, not blocking)
- Pitfalls: HIGH — Pitfalls 1 and 3 are drawn directly from code comments in the twin files (`ratchet-propose.mjs`'s own "RESEARCH Pitfall 6" annotation); Pitfall 2 and 4 are net-new observations from cross-referencing the Anthropic model-behavior skill against this phase's specific design (adaptive thinking defaults, guard-token vs. playwright-tag convention)

**Research date:** 2026-07-04
**Valid until:** 30 days (stable, internal-repo-based twin patterns); re-verify Anthropic model IDs/API behavior claims if this phase's implementation slips more than ~60 days past this research date, since the model catalog and API surface documented here (Opus 4.8 defaults, structured-outputs support, sampling-param removal) is dated to the skill's cached knowledge as of 2026-06-24 and could shift with a new model release.

---

## Drift Note for the Planner (read before writing tasks)

One line-number inaccuracy was found in `206-CONTEXT.md`'s `canonical_refs` section and should NOT be propagated into the plan: it cites `region-tags.js`'s `runSelfTest()` as living at **"~436-459"**. Reading the actual file, `runSelfTest()` is defined at **lines 345-433**; lines 436-459 are actually `module.exports = {...}` (436-453) followed by the standalone-runner `if (require.main === module) { runSelfTest(); }` block (457-459). This is purely a doc-accuracy issue — the function exists, is correctly named, and behaves exactly as described (7 DEDUP-02 assertion classes + golden-hash + slug parity) — only the cited line range is off by about 90 lines. If the plan references this function by line number, use **345-433**.

Every other line-range citation in `206-CONTEXT.md`'s `canonical_refs` (the `phase200-scorecard.mjs`/`verify_phase200_scorecard.mjs`/`ratchet-propose.mjs` ranges) was cross-checked against the actual file contents during this research and found accurate.
