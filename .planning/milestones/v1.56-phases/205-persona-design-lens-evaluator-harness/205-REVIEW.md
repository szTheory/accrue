---
phase: 205-persona-design-lens-evaluator-harness
reviewed: 2026-07-03T00:00:00Z
depth: deep
files_reviewed: 5
files_reviewed_list:
  - accrue_admin/e2e/ratchet/region-tags.js
  - accrue_admin/e2e/ratchet/ratchet-propose.mjs
  - accrue_admin/e2e/admin-visuals.spec.js
  - accrue_admin/e2e/ratchet/DESIGN-LENS-RUBRIC.md
  - accrue_admin/e2e/ratchet/exemplars/PROVENANCE.json
findings:
  blocker: 0
  critical: 0
  warning: 3
  info: 5
  total: 8
status: issues-found
---

# Phase 205: Code Review Report

**Reviewed:** 2026-07-03
**Depth:** deep (cross-file: proposer ↔ region-tags SSOT ↔ baseline-manifest ↔ capture spec ↔ rubric/provenance)
**Files Reviewed:** 5 source files (+2 PNG binaries, +package.json wiring verified)
**Status:** issues-found

## Summary

This is a dev/test-only evaluator harness with no adopter runtime, so severity is calibrated
accordingly (no BLOCKER-tier defects — nothing here ships into a customer runtime or can lose
data). The determinism-critical spine is **sound and empirically verified**:

- `--self-test` (both `ratchet-propose.mjs --self-test` and standalone `region-tags.js`) passes
  all 13 assertions including the pinned `GOLDEN_FINDING_ID` — confirming CJS→ESM named-export
  interop works, the sha256 identity is stable, and separators/field-order are locked.
- **Guard ordering is correct** (EVAL-03/SC#3): `--self-test` (line 51) is the first executable
  statement and is reachable with no key and no SDK import; the no-key `exit 0` (line 61) precedes
  the dynamic SDK import (line 70). Verified empirically — `env -u ANTHROPIC_API_KEY … ` exits 0.
- **Injection posture is sound.** No identity field derives from model free-text: `surface` comes
  from the filename, `dimension` is range-validated, `region_tag`/`overlay_tags` are coerced to
  closed enums. A prompt-injected model can at worst pick a *valid* enum value — it cannot inject
  arbitrary identity. `SYSTEM_PREAMBLE` is attached on every persona AND design call.
- **Sort is codepoint-stable** (default `.sort()`, all-ASCII-lowercase enum), `MAX_B64_BYTES` is
  enforced before every attach (target + both exemplars), the `tool_use` lookup is null-safe, and
  `OVERLAY_TAGS`/`slug` are currently byte-identical to `baseline-manifest.js`.

The findings below are robustness gaps, one concrete archetype-mismatch functional bug, and latent
maintainability/determinism-drift risks — none compromise the proven claim-key invariant.

## Warnings

### WR-01: Non-array `findings` from the model aborts the whole run

**File:** `accrue_admin/e2e/ratchet/ratchet-propose.mjs:439`, `:462`
**Issue:** The tool-use extraction is null-safe but not type-safe:
```js
const raw = response.content.find((b) => b.type === "tool_use")?.input?.findings ?? [];
for (const f of raw) { … }
```
`?? []` only substitutes for `null`/`undefined`. The file's own comment (Pitfall 2, line 245-247)
states Sonnet 4.5 "lacks strict structured outputs" — so the model can return `findings` as a
non-array (e.g. an object or string). If it does, `for (const f of raw)` throws `raw is not
iterable`. This is caught per-image (line 372-380) but increments `failedImages`, and the end-of-run
`if (failedImages > 0) process.exit(1)` (line 397-400) then **fails the entire proposer run** on a
single malformed response — exactly the scenario the code anticipates.
**Fix:**
```js
const block = response.content.find((b) => b.type === "tool_use");
const raw = Array.isArray(block?.input?.findings) ? block.input.findings : [];
```
Apply identically to the design-lens extraction at line 462.

### WR-02: `OVERLAY_TAGS` is a hand-copied mirror with no automated parity guard

**File:** `accrue_admin/e2e/ratchet/region-tags.js:60-75`
**Issue:** `OVERLAY_TAGS` is manually mirrored from `baseline-manifest.js:29-44` (14 values) and is
currently byte-identical (verified). But `region-tags.js` stays manifest-free by contract, and the
pure `runSelfTest()` only asserts `slug` parity — **not** overlay-enum parity. A future edit to
either list drifts them silently: overlay tags that validate in the proposer but don't exist in the
census (or vice-versa) would corrupt `claim_key`/`cell_refs` alignment and break DEDUP guarantees.
This is the one place where the "mirror rather than import" decision creates a latent correctness
hole with no tripwire.
**Fix:** Add a parity assertion in a test that *is allowed* to import both modules (not the pure
self-test — keep that manifest-free), e.g. a `region-tags.parity.test` that requires both and
asserts `deepEqual(regionTags.OVERLAY_TAGS, manifest.OVERLAY_TAGS)`. This preserves the SDK-free
self-test while catching drift in CI.

### WR-03: `component-kitchen` is unresolved in the manifest → empty `cell_refs` + wrong design archetype

**File:** `accrue_admin/e2e/ratchet/ratchet-propose.mjs:407-408`, `:588-589`, `:163-165`
**Issue:** `admin-visuals.spec.js:128` captures a `component-kitchen` surface, but `SURFACES` in
`baseline-manifest.js` has **no** `component-kitchen` entry (the `/dev/components` route is modeled
as 21 individual component families + 8 groups, not a single "component-kitchen" surface). Two
downstream effects for that captured PNG:
1. `SURFACES.find(e => e.surface === "component-kitchen")` → `undefined` → `surface_type =
   "unknown"` → `computeCellRefs` returns `[]` for **every** component-kitchen candidate, so those
   rows never link into the census lattice (D-12 foreign key permanently empty for this surface).
2. `selectExemplarPair("unknown")` falls to `DEFAULT_EXEMPLAR_PAIR` (`good/dashboard.png` +
   `bad/cramped.png`) — the **page-flow** archetype. Yet `PROVENANCE.json` and DESIGN-LENS-RUBRIC §5
   explicitly built `good/dev-components.png` + `bad/wasteful.png` for exactly the component
   archetype and name `component-kitchen` (surface_type `component`) as its target. So the one
   surface the `dev-components` GOOD exemplar exists to match is few-shot against the *opposite*
   archetype, directly contradicting the rubric's archetype-matching intent.
**Fix:** Either add a `component-kitchen` alias resolution in the proposer (map the captured screen
to `surface_type: "component"` before `selectExemplarPair`/`allowedSubsetFor`), or register a
`component-kitchen` surface in the manifest. Minimal proposer-side fix:
```js
const KNOWN_SURFACE_TYPE = { "component-kitchen": "component" };
const surface_type = surfaceInfo ? surfaceInfo.surface_type
  : (KNOWN_SURFACE_TYPE[surface] || "unknown");
```
Note this only fixes the exemplar archetype; `cell_refs` will still be `[]` unless the census
addresses `component-kitchen` (acceptable if intended, but document it).

## Info

### IN-01: `allowedSubsetFor` keys off the surface *name*, not `surface_type`

**File:** `accrue_admin/e2e/ratchet/region-tags.js:228-239`
**Issue:** The proposer calls `normalizeRegion(surface, …)` and `allowedSubsetFor(surface)` with the
surface *name* (e.g. `"customers"`, `"component-kitchen"`). It happens to work for page-flows
(detail names contain `"detail"`; list names fall to the safe `list` default), but
`component-kitchen` resolves to the `list` subset instead of `component`. Deterministic and never
escapes `REGION_TAGS`, so not a determinism bug — but the region vocabulary offered to the model is
subtly wrong for the component surface. Related to WR-03; fixing the `surface_type` resolution there
and passing `surface_type` here would make intent and behavior agree.

### IN-02: `RATCHET_ROUND` garbage serializes as `null` in every row

**File:** `accrue_admin/e2e/ratchet/ratchet-propose.mjs:77`
**Issue:** `const round = Number(process.env.RATCHET_ROUND || "1")`. A non-numeric env value yields
`NaN`, and `JSON.stringify({round: NaN})` emits `"round": null` on every candidate row. Provenance-
only (never in `claim_key`), so low impact.
**Fix:** `const round = Number.isFinite(+process.env.RATCHET_ROUND) ? +process.env.RATCHET_ROUND : 1;`

### IN-03: `MAX_B64_BYTES` measures base64 *string length*, not decoded bytes

**File:** `accrue_admin/e2e/ratchet/ratchet-propose.mjs:81`, `:174`, `:361`
**Issue:** The constant is named `…BYTES` and commented "5 MB", but every check compares
`b64.length` (base64 character count ≈ 1.33× the actual image byte size). The effective cap is
therefore ~3.75 MB of real image data. Consistent across target and exemplars (so deterministic and
harmless), purely a naming/accuracy imprecision. Rename to `MAX_B64_CHARS` or compare
`Buffer.byteLength(b64, "utf8")` if a true 5 MB byte cap is intended.

### IN-04: `justification_token` suffix is unvalidated free text passed through to output

**File:** `accrue_admin/e2e/ratchet/region-tags.js:313-318`, `ratchet-propose.mjs:686`
**Issue:** `isAdmissibleToken` accepts `persona-job-miss:<anything-non-empty>`, and the row stores
`f.justification_token` verbatim. The `<job>` suffix is model-influenced (and thus screenshot-text-
influenceable), so injected prose can ride into the human-reviewed digest via this field. It is
non-identity (excluded from `claim_key`) and human-gated, so risk is low — but if the Phase-207
digest renders `justification_token` without escaping, treat that as the mitigation point. Consider
clamping the stored token to the harness-supplied `persona-job-miss:${persona.job}` rather than the
model's echo.

### IN-05: `claimKey` does not normalize `region_tag` casing (exported footgun)

**File:** `accrue_admin/e2e/ratchet/region-tags.js:292-298`
**Issue:** `claimKey` normalizes `surface` (via `slug`) and `overlay_tags` (via `normalizeOverlays`)
but trusts `region_tag` verbatim — `claimKey("dashboard", 3, "KPI-Row", [])` would produce a
different key than the lowercase form. In-pipeline this is safe because `emitCandidates` always
passes `normalizeRegion(...)` output (already lowercased/enum-clamped), and the self-test only
exercises normalized inputs. But as an *exported* identity primitive it is an asymmetric footgun: a
future caller who hands `claimKey` a raw region string gets a divergent, non-canonical key. Consider
either documenting the precondition loudly or defensively lowercasing `region_tag` inside `claimKey`.

---

_Reviewed: 2026-07-03_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: deep_
