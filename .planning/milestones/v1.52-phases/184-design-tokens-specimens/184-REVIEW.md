---
phase: 184-design-tokens-specimens
reviewed: 2026-06-13T00:00:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - brandbook/tokens/harness/lib.mjs
  - brandbook/tokens/harness/generate-tokens-css.mjs
  - brandbook/tokens/harness/verify-tokens.mjs
  - brandbook/tokens/harness/parity-check.mjs
  - brandbook/tokens/harness/generate-specimens.mjs
  - brandbook/tokens/harness/verify-specimens.mjs
  - brandbook/tokens/harness/svgo.config.mjs
  - brandbook/tokens/harness/package.json
  - .github/workflows/ci.yml
findings:
  critical: 2
  warning: 3
  info: 3
  total: 8
status: issues_found
---

# Phase 184: Code Review Report

**Reviewed:** 2026-06-13T00:00:00Z
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

This is a pure-JS (ESM) Node harness that drives Accrue's design-token pipeline:
tokens.json → CSS generation → specimen SVG generation → parity verification → CI gates.
The architecture is sound — the throw-don't-return-undefined discipline in `resolveColor`,
the two-layer alias resolution, and the parity engine's documented-divergence tolerance are
well-designed. The culori color-mix workaround is correctly implemented for the common
one-sided-percentage form.

Two blockers were found. The most consequential is that SC#1 (`verify-tokens.mjs`) and SC#3
(`verify-specimens.mjs`) are completely unwired from CI: no `npm` script entries and no
`ci.yml` invocations. The second is a structural false negative in the parity engine: token
**deletion** from `theme.css` passes silently, and no test case in `--test` mode covers
this path.

Three warnings cover real but lower-severity defects: a color-mix two-sided-percentage
parsing bug, missing cycle detection in alias resolution, and locale-dependent sort
used as the determinism mechanism.

---

## Critical Issues

### CR-01: SC#1 and SC#3 verifiers are entirely unwired from CI

**File:** `brandbook/tokens/harness/package.json` (all scripts), `.github/workflows/ci.yml:97-106`

**Issue:**
`verify-tokens.mjs` (SC#1 — structural completeness of tokens.css) and
`verify-specimens.mjs` (SC#3 — content coverage of specimen SVGs) are never invoked in CI.
Neither file has a corresponding entry in `package.json`'s `scripts` block, and neither
appears anywhere in `ci.yml`. The CI token pipeline runs only:

```
npm run generate      # generate-tokens-css.mjs
npm run specimens     # generate-specimens.mjs
git diff --exit-code  # determinism gate
npm run parity        # parity-check.mjs live mode
npm run parity-test   # parity-check.mjs --test mode
```

The determinism gate proves *stability of regeneration* — it cannot prove *content
correctness*. A tokens.json edit that drops `--accrue-surface-base` would regenerate
deterministically and pass all CI gates, because SC#1 is never evaluated. Similarly,
a broken `buildPaletteSvg` that emits no swatch text would pass the determinism gate
and never be caught by SC#3.

**Fix:**
Add npm scripts for the two verifiers, then wire them into the `docs-contracts-shift-left`
job immediately after the respective generators:

```jsonc
// package.json
"scripts": {
  "generate":          "node generate-tokens-css.mjs",
  "verify":            "node verify-tokens.mjs",
  "specimens":         "node generate-specimens.mjs",
  "verify-specimens":  "node verify-specimens.mjs",
  "parity":            "node parity-check.mjs",
  "parity-test":       "node parity-check.mjs --test"
}
```

```yaml
# ci.yml — docs-contracts-shift-left job, after the existing tokens steps
- name: Verify tokens completeness (SC#1)
  run: cd brandbook/tokens/harness && npm run verify

- name: Verify specimen content coverage (SC#3)
  run: cd brandbook/tokens/harness && npm run verify-specimens
```

The `verify` step should run after `Tokens/specimens are reproducible` (determinism gate)
and before `Brand↔admin token parity (SC#2)`, so failures are caught in correct phase order.

---

### CR-02: Parity check false negative — deleted admin token passes silently

**File:** `brandbook/tokens/harness/parity-check.mjs:111-114`

**Issue:**
The core comparison loop skips any `axMap`-carrying token whose value is absent from
`theme.css`:

```js
const adminRaw = adminScope[axMap];
// Token not defined in this scope — skip (not an error; dark block omits some tokens)
if (adminRaw == null) continue;
```

This comment is correct for intentional dark-scope omissions, but it also silently ignores
a developer who **deletes** a light-scope `--ax-success` line from `theme.css`. The parity
check sees `adminRaw == null` and records 0 failures. CI passes. The admin UI silently loses
its success color.

The `--test` mode's case `(b)` only exercises **value mutation** (injecting `#ff0000`). No
test case deletes an `axMap` declaration and expects a failure:

```js
// (b) Injected drift: mutated theme.css → >0 failures
// (c) Documented divergence: tolerated
// (d) Sanity: renaming unrelated font property → 0 failures
// MISSING: (e) Deleted ax-mapped color token → >0 failures
```

**Fix:**
The fix requires separating intentional dark-scope omissions (genuinely expected) from
accidental light-scope deletions. One approach: enumerate all `axMap` values that *should*
exist in the light scope from `tokens.json`, then check that each is present in
`lightScope` before comparing values. Add a test case `(e)` that removes an ax-mapped
declaration from the light scope and asserts `failures > 0`:

```js
// In runParity — after building scopes, audit expected light-scope declarations
const expectedLightAxMaps = new Set(
  [...iterAxMappedTokens(tokens)]
    .filter(t => t.axMap != null && t.scope === "light")
    .map(t => t.axMap)
);
for (const axMap of expectedLightAxMaps) {
  if (lightScope[axMap] == null) {
    if (verbose) console.error(`MISSING  ${axMap}: defined in tokens.json but absent from light scope in theme.css`);
    failures++;
  }
}
```

And add test case `(e)` to `runTests()`:

```js
// (e) Deleted light-scope token: remove --ax-success line → >0 failures
{
  const deletedCss = realCss.replace(/\s*--ax-success:[^\n]+\n/, "\n");
  const failures = runParity({ themeCss: deletedCss, tokens: realTokens, verbose: false });
  assertCase("(e) deleted-light-token — non-zero failures", failures, "nonzero");
}
```

---

## Warnings

### WR-01: `_resolveColorMix` corrupts `secondColorStr` for two-sided and second-only percentages

**File:** `brandbook/tokens/harness/lib.mjs:168-178`

**Issue:**
The parser handles `color-mix(in srgb, A p%, B)` correctly but fails for two valid CSS
color-mix forms:

1. **Two-sided percentages:** `color-mix(in srgb, red 40%, blue 60%)`
   After filtering, `rest = [red, "40%", blue, "60%"]`. The condition
   `rest.length >= 3 && rest[1].value.endsWith("%")` is true, so:
   `secondColorStr = rest.slice(2).map(...).join(" ") = "blue 60%"`.
   `resolveColor("blue 60%", ...)` → culori cannot parse `"blue 60%"` → throws.

2. **Second-only percentage:** `color-mix(in srgb, red, blue 60%)`
   `rest = [red, blue, "60%"]`. Condition: `rest[1]` is `"blue"`, not ending in `%`.
   Falls to else branch: `secondColorStr = "blue 60%"` → same throw.

Neither form currently appears in `tokens.json`, so this is a latent crash that will
surface the moment a token uses the standard two-sided form. The function should strip
a trailing `%`-word from `secondColorStr`:

```js
// After extracting secondColorStr, strip trailing percentage word if present
const secondParts = rest.slice(2).map(stringifyNode);
const lastPart = secondParts[secondParts.length - 1];
if (lastPart && /^\d+(\.\d+)?%$/.test(lastPart)) {
  secondParts.pop(); // discard explicit second percentage (1 - firstPercent implied)
}
secondColorStr = secondParts.join(" ").trim();
```

For the second-only percentage case:

```js
// In the else (50/50) branch, check if last node is a percentage
const restParts = rest.map(stringifyNode);
const lastPart = restParts[restParts.length - 1];
if (lastPart && /^\d+(\.\d+)?%$/.test(lastPart)) {
  // e.g. [A, B, "60%"] — interpret as A 40%, B 60%
  const secondPercent = parseFloat(lastPart);
  firstPercent = 100 - secondPercent;
  firstColorStr = stringifyNode(rest[0]);
  secondColorStr = restParts.slice(1, -1).join(" ").trim();
} else {
  firstColorStr = stringifyNode(rest[0]);
  secondColorStr = restParts.slice(1).join(" ").trim();
}
```

---

### WR-02: `_resolveAlias` has no cycle detection — circular aliases cause stack overflow

**File:** `brandbook/tokens/harness/lib.mjs:209-222`

**Issue:**
`_resolveAlias` recurses on nested aliases without a depth limit or visited-set guard:

```js
function _resolveAlias(aliasStr, root) {
  // ...
  if (typeof v === "string" && v.startsWith("{")) {
    return _resolveAlias(v, root); // nested alias — no cycle guard
  }
}
```

If `tokens.json` contains `A → {B}` and `B → {A}` (accidental copy-paste or merge
conflict), calling `flattenTokens` will stack-overflow Node.js without a meaningful
error message. This silently takes down the entire CI step.

**Fix:** Add a `seen` set and throw a descriptive error on re-visit:

```js
function _resolveAlias(aliasStr, root, seen = new Set()) {
  if (seen.has(aliasStr)) {
    throw new Error(`[lib.mjs] _resolveAlias: circular alias detected: ${[...seen, aliasStr].join(" → ")}`);
  }
  seen.add(aliasStr);
  const pathSegs = aliasStr.slice(1, -1).split(".");
  let node = root;
  for (const seg of pathSegs) {
    if (node == null || typeof node !== "object") return null;
    node = node[seg];
  }
  if (node == null || !node.$value) return null;
  const v = node.$value;
  if (typeof v === "string" && v.startsWith("{")) {
    return _resolveAlias(v, root, seen);
  }
  if (typeof v === "object" && v.hex) return v.hex.toLowerCase();
  return null;
}
```

---

### WR-03: `localeCompare` without locale pinning undermines the determinism gate

**File:** `brandbook/tokens/harness/generate-tokens-css.mjs:34`, `generate-specimens.mjs:137,141`

**Issue:**
Three sort calls use `localeCompare` without a pinned locale:

```js
// generate-tokens-css.mjs:34
.sort((a, b) => a.cssVar.localeCompare(b.cssVar))

// generate-specimens.mjs:137, 141
.sort((a, b) => a.name.localeCompare(b.name))
```

`String.prototype.localeCompare()` with no locale argument uses the runtime environment's
default locale. The generated output (token order in `tokens.css`, swatch order in
`palette.svg`) therefore depends on the runner's system locale. On GitHub Actions
`ubuntu-24.04` this is `en_US.UTF-8`, but any runner locale change would produce a
different sort order, causing the determinism gate (`git diff --exit-code`) to fail
spuriously — or worse, pass on one locale and fail on another, making the gate
non-reproducible across developer machines and CI.

All values being sorted are pure ASCII CSS variable names (`--accrue-*`), so in
practice all POSIX-locale and en-locale collations produce the same result. This
is currently low-risk but fragile by design when the comment explicitly claims
determinism as a design goal (D-17).

**Fix:** Pin locale and options explicitly:

```js
// generate-tokens-css.mjs
.sort((a, b) => a.cssVar.localeCompare(b.cssVar, "en", { sensitivity: "variant" }))

// generate-specimens.mjs
.sort((a, b) => a.name.localeCompare(b.name, "en", { sensitivity: "variant" }))
```

Or, simpler and fully locale-independent for ASCII-only strings:

```js
.sort((a, b) => (a.cssVar < b.cssVar ? -1 : a.cssVar > b.cssVar ? 1 : 0))
```

---

## Info

### IN-01: Dead `iy` parameter in `swatchGroup`

**File:** `brandbook/tokens/harness/generate-specimens.mjs:165`

**Issue:**
`swatchGroup(token, ix, iy, surfaceType)` accepts `iy` as its third parameter but never
references it in the function body. The dark-band caller always passes `0`:

```js
// line 202
const darkSwatches = allLightTokens.map((t, i) => swatchGroup(t, i, 0, "dark")).join("");
```

The band y-offset is applied via a `<g transform="translate(0, darkBandY)">` wrapper instead.
`iy` is dead code left from an earlier layout approach.

**Fix:** Remove the parameter:

```js
function swatchGroup(token, ix, surfaceType) { ... }
// callers:
allLightTokens.map((t, i) => swatchGroup(t, i, "light"))
allLightTokens.map((t, i) => swatchGroup(t, i, "dark"))
```

---

### IN-02: AA-FAIL assertions in `verify-specimens.mjs` match `<desc>` text, not swatch text

**File:** `brandbook/tokens/harness/verify-specimens.mjs:46-48,120-122`

**Issue:**
`REQUIRED_AA_FAIL_STRINGS` are checked with `assertContains(paletteSvg, needle, ...)`,
which does a bare `String.includes()`. The same strings appear verbatim in the `<desc>`
element injected by `injectMeta()`:

```
"Moss 3.03:1 AA-large (FAIL AA-body on light); Cobalt 3.66:1 AA-large (FAIL AA-body on light); ..."
```

This means the assertion passes as long as the `<desc>` text is present, even if every
swatch's AA `<text>` node is missing or empty. The verification proves the description
was written, not that the swatch labels were rendered.

Note: this finding is secondary to CR-01 (SC#3 is not run in CI at all).

**Fix:** If this check is promoted to blocking (after CR-01 is resolved), scope the
assertion to the SVG body after the `<desc>` element by splitting on `</desc>` and
checking only the tail, or use a regex that matches inside a `<text>` context.

---

### IN-03: Case-insensitive hex regex in `verify-tokens.mjs` is unnecessarily permissive

**File:** `brandbook/tokens/harness/verify-tokens.mjs:98`

**Issue:**
```js
const pattern = new RegExp(`${cssVar}:\\s*${hex}`, "i");
```

The `"i"` flag makes the hex match case-insensitive (`#5E9E84` would satisfy
`#5e9e84`). The generator (`generate-tokens-css.mjs`) always writes lowercase hex
(from culori's `formatHex`), and all entries in `REQUIRED_TOKENS` already use
lowercase hex. The flag is harmless but creates a false sense that uppercase output
would be acceptable, and could mask a future generator regression that emits
uppercase hex.

**Fix:** Remove the `"i"` flag:

```js
const pattern = new RegExp(`${cssVar}:\\s*${hex}`);
```

---

_Reviewed: 2026-06-13T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
