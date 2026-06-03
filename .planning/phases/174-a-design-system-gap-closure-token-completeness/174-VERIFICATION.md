---
phase: 174-a-design-system-gap-closure-token-completeness
verified: 2026-06-03T22:00:00Z
status: gaps_found
score: 10/13 must-haves verified
overrides_applied: 0
gaps:
  - truth: "ComponentRegistry tokens field accurately documents the actual CSS tokens driving each variant (no phantom tokens)"
    status: failed
    reason: "Registry entries for status/slate, card/slate list --ax-neutral/--ax-neutral-readable (undefined in theme.css or app.css); status/ink, card/ink list --ax-ink/--ax-ink-readable (also undefined). status/cobalt and card/cobalt list --ax-info/--ax-info-readable but actual CSS uses --ax-accent/--ax-accent-readable. The drift test (174-04) only asserts on ax_class substrings, never on the tokens field, so this inaccuracy is invisible to CI."
    artifacts:
      - path: "accrue_admin/lib/accrue_admin/dev/component_registry.ex"
        issue: "Lines 70, 82-83, 88-89, 111, 123, 129: phantom tokens --ax-neutral, --ax-neutral-readable, --ax-ink, --ax-ink-readable listed; --ax-info listed for cobalt where --ax-accent is the actual token"
    missing:
      - "Fix status/slate tokens to [\"--ax-border\", \"--ax-muted\", \"--ax-elevated\"]"
      - "Fix status/ink tokens to [\"--ax-primary\", \"--ax-elevated\"]"
      - "Fix card/slate tokens to [\"--ax-primary\", \"--ax-muted\", \"--ax-transition-colors\"]"
      - "Fix card/ink tokens to [\"--ax-primary\", \"--ax-muted\", \"--ax-transition-colors\"]"
      - "Fix status/cobalt tokens to [\"--ax-accent\", \"--ax-accent-readable\", \"--ax-elevated\"]"
      - "Fix card/cobalt tokens to [\"--ax-accent\", \"--ax-accent-readable\", \"--ax-transition-colors\"]"
      - "Add a test assertion that every token listed in ComponentRegistry.entries() is actually defined in theme.css or app.css (grep-based or compile-time check)"

  - truth: "PackageDocsVerifierTest seed_tmp_dir! includes adoption-proof-matrix.md so the Stripe-only absence guard is enforced in negative tests"
    status: failed
    reason: "verify_package_docs.sh line 304 calls require_absent_regex against examples/accrue_host/docs/adoption-proof-matrix.md. seed_tmp_dir! (package_docs_verifier_test.exs) never copies this file. When require_absent_regex runs in negative tests, grep exits code 2 (file not found); inside an if condition, bash set -e is suppressed and the if evaluates false — the guard silently passes. The Stripe-only regression is unenforced in all test-based CI verification paths."
    artifacts:
      - path: "accrue/test/accrue/docs/package_docs_verifier_test.exs"
        issue: "seed_tmp_dir! (line 276-311) creates examples/accrue_host/ directory but does not copy adoption-proof-matrix.md; the Stripe-only guard at verify_package_docs.sh:304 is a dead check in tests"
    missing:
      - "Add File.mkdir_p!(Path.join(tmp_dir, \"examples/accrue_host/docs\")) to seed_tmp_dir!"
      - "Add copy_fixture!(\"examples/accrue_host/docs/adoption-proof-matrix.md\", tmp_dir) to seed_tmp_dir!"
      - "Add a negative test that injects 'Stripe-only' into the seeded adoption-proof-matrix.md and asserts the guard exits non-zero"

  - truth: "All 5 multi-line transition blocks collapsed (the .ax-search-trigger block is the 5th site)"
    status: failed
    reason: "The plan explicitly mandated 5 transition collapses (lines 270, 992, 1446, 1967, 2077). Only 4 were collapsed; .ax-search-trigger was left with a comment '/* Phase D: asymmetric speed — collapse pending */'. The plan permitted this deferral via its own judgment guidance, but the plan-frontmatter must_have truth 'All 5 multi-line transition blocks are collapsed to a single var(--ax-transition-*) reference' is not met. The ROADMAP SC-1 says 'pre-composed transition bundles' — the 5th block still has literal multi-property transitions."
    artifacts:
      - path: "accrue_admin/assets/css/app.css"
        issue: ".ax-search-trigger at line 1438/1450 retains multi-property transition literals instead of a var(--ax-transition-*) bundle"
    missing:
      - "Collapse .ax-search-trigger transition to var(--ax-transition-base) or create a --ax-transition-focus bundle for the asymmetric case, OR formally downgrade the must_have count from 5 to 4"
human_verification:
  - test: "Visit /dev/components and verify the token <dl> metadata for slate/ink/cobalt variants"
    expected: "The page shows --ax-neutral/--ax-ink for slate/ink rows and --ax-info for cobalt rows, which are inaccurate. After fixing CR-01, the page should show --ax-border/--ax-muted for slate, --ax-primary for ink, and --ax-accent for cobalt."
    why_human: "Visual inspection required to confirm phantom tokens are visible to maintainers and confirm the fix renders the correct token names in the UI"
  - test: "Confirm dunning banner renders correctly in dev without inline style override"
    expected: "The ax-banner-danger class should correctly apply background and text colors via CSS tokens with no inline style= fallback"
    why_human: "Visual rendering confirmation requires a live browser; the test only checks HTML string absence, not computed styles"
---

# Phase 174: A — Design-System Gap Closure & Token Completeness Verification Report

**Phase Goal:** A — Design-System Gap Closure & Token Completeness — Add line-height / letter-spacing / breakpoint / transition-bundle / reading-measure tokens, kill the remaining token bypasses, and publish a component-variants reference.
**Verified:** 2026-06-03T22:00:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (from ROADMAP Success Criteria + Plan frontmatter)

| #  | Truth | Status | Evidence |
|----|-------|--------|----------|
| 1  | theme.css exports --ax-leading-tight (1.2), --ax-leading-normal (1.4), --ax-leading-relaxed (1.5) inside html.accrue-admin | VERIFIED | Lines 71-73; values confirmed |
| 2  | theme.css exports --ax-tracking-tight (-0.02em), --ax-tracking-normal (0), --ax-tracking-wide (0.04em), --ax-tracking-caps (0.08em) | VERIFIED | Lines 75-78 |
| 3  | theme.css exports --ax-measure (68ch) | VERIFIED | Line 80 |
| 4  | theme.css exports all 4 --ax-transition-* bundles composed from existing dur/ease atoms, background-color (not background shorthand) | VERIFIED | Lines 85-98; no background shorthand, all values use var(--ax-dur-2)/var(--ax-ease-out) |
| 5  | Existing prefers-reduced-motion block contains overrides for all 4 --ax-transition-* bundles using --ax-dur-instant | VERIFIED | Lines 201-210 |
| 6  | app.css has no bare line-height numeric literals (1.2, 1.4, 1.5) — all 13 sites migrated | VERIFIED | `grep -E 'line-height: [0-9]\.[0-9]' app.css` returns 0 |
| 7  | app.css has no bare letter-spacing em literals — all 5 sites migrated | VERIFIED | `grep -E 'letter-spacing: -?[0-9.]+em' app.css` returns 0 |
| 8  | Every breakpoint @media in app.css carries an --ax-bp-* inline comment — all sites annotated | VERIFIED | `grep -E '@media ...' | grep -v '--ax-bp-'` returns 0 |
| 9  | dunning_banner.ex has no style= attribute | VERIFIED | `grep -rn 'style=' dunning_banner.ex` returns 0 lines; refute assertion present in test |
| 10 | verify_package_docs.sh fails if @media breakpoint in app.css lacks --ax-bp-* comment | VERIFIED | Guard at line 319-326 confirmed; `bash scripts/ci/verify_package_docs.sh` exits 0 |
| 11 | ComponentRegistry.entries() returns 15 entries covering 4 families with correct ax_class strings | VERIFIED | 15 entries: 4 button + 5 status + 6 card; ax_class strings confirmed against component source; danger variant present |
| 12 | ComponentRegistry tokens field accurately documents the actual CSS tokens (no phantom tokens) | FAILED | --ax-neutral, --ax-neutral-readable, --ax-ink, --ax-ink-readable not defined anywhere in CSS; cobalt entries list --ax-info but actual CSS uses --ax-accent |
| 13 | PackageDocsVerifierTest seed_tmp_dir! includes adoption-proof-matrix.md enabling the Stripe-only guard | FAILED | seed_tmp_dir! does not copy adoption-proof-matrix.md; guard silently passes on missing file in all negative tests |

**Score: 10/13 truths verified**

Note: The must_have truth "All 5 multi-line transition blocks are collapsed" is assessed as FAILED (4 of 5 collapsed; .ax-search-trigger left with Phase D deferral comment). The ROADMAP SC-1 phrases this as "pre-composed transition bundles" which is largely satisfied by 4/5, so this gap is classified as partial rather than blocking the core ROADMAP goal. It is listed as a gap for plan-phase awareness.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `accrue_admin/assets/css/theme.css` | All new type micro-tokens and transition-bundle tokens | VERIFIED | 9 type tokens + 4 transition bundles + 4 reduced-motion overrides present |
| `accrue_admin/assets/css/app.css` | Migrated CSS with token references + breakpoint registry + .ax-measure | VERIFIED | Zero literal bypasses; .ax-measure exists; 10 breakpoints annotated |
| `accrue_admin/lib/accrue_admin/components/dunning_banner.ex` | Bypass-free banner component | VERIFIED | No style= attribute; class-only rendering |
| `scripts/ci/verify_package_docs.sh` | Breakpoint drift guard needle | VERIFIED | Guard at lines 319-326 using grep -qv pattern |
| `accrue/test/accrue/docs/package_docs_verifier_test.exs` | Negative test for breakpoint guard + adoption-proof-matrix seed | PARTIAL | Breakpoint negative test (900px) present and seeded; adoption-proof-matrix NOT seeded (CR-02 blocker) |
| `accrue_admin/priv/static/accrue_admin.css` | Rebuilt minified bundle | VERIFIED | Bundle rebuilt as commit d31f306d; zero literal line-height in output |
| `accrue_admin/lib/accrue_admin/dev/component_registry.ex` | ComponentRegistry data module | PARTIAL | Structure correct; ax_class strings correct; tokens field has phantom tokens for slate/ink and wrong tokens for cobalt |
| `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` | Extended LiveView with 4 variant-reference sections | VERIFIED | 4 sections; 8 data-ax-theme wrappers; 4 variants_for calls; ComponentRegistry alias present |
| `accrue_admin/test/accrue_admin/dev/component_registry_test.exs` | Drift-prevention test | VERIFIED | 2 tests: page render coverage + Button MapSet equality; danger variant explicit |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| theme.css --ax-leading-* tokens | app.css var() references | CSS custom property cascade | VERIFIED | `grep -c 'var(--ax-leading-' app.css` = 18 occurrences |
| app.css var(--ax-transition-base) | theme.css --ax-transition-base definition | var() resolution | VERIFIED | 3 collapse sites in app.css use var(--ax-transition-base) |
| verify_package_docs.sh guard | PackageDocsVerifierTest seed | D-04 coupling | PARTIAL | Breakpoint guard coupled to app.css seed (both present); adoption-proof-matrix guard NOT coupled to seed |
| ComponentRegistry.entries() | component_kitchen_live.ex render | variants_for/1 calls | VERIFIED | 4 variants_for calls rendering real component swatches |
| ComponentRegistry.entries() | ComponentRegistryTest | entries/0 and variants_for/1 | VERIFIED | Both test behaviors reference the registry |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|-------------------|--------|
| component_kitchen_live.ex | entry.tokens | ComponentRegistry.entries/0 static list | Yes (static curated data) | HOLLOW for slate/ink/cobalt — renders phantom token names to maintainer UI |
| component_registry_test.exs | registry_classes MapSet | ComponentRegistry.variants_for("button") | Yes | VERIFIED — ax_class strings are accurate for button family |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| No bare line-height literals in app.css | `grep -E 'line-height: [0-9]\.[0-9]' app.css` | 0 lines | PASS |
| No bare letter-spacing literals in app.css | `grep -E 'letter-spacing: -?[0-9.]+em' app.css` | 0 lines | PASS |
| No unguarded breakpoint @media in app.css | `grep -E '@media ...' app.css \| grep -v '--ax-bp-'` | 0 lines | PASS |
| No style= in dunning_banner.ex | `grep -rn 'style=' dunning_banner.ex` | 0 lines | PASS |
| verify_package_docs.sh passes | `bash scripts/ci/verify_package_docs.sh` | exit 0 | PASS |
| theme.css has all 9 type micro-tokens | grep for --ax-leading-tight/normal/relaxed/tracking-*/measure | All present | PASS |
| theme.css has 4 transition bundles + 4 reduced-motion overrides | grep -c --ax-transition-colors/transform/shadow/base | 2 each (def + reduced-motion) | PASS |
| --ax-transition-all forbidden token absent | `grep --ax-transition-all theme.css` | 0 lines | PASS |
| No background shorthand in transition bundles | `grep 'background ' theme.css \| grep transition` | 0 lines | PASS |
| ComponentRegistry has 15 entries | commit log + file content | 15 entries confirmed | PASS |

### Probe Execution

No probe scripts defined for this phase. Step 7c: SKIPPED (no probe-*.sh files declared).

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| DSY-01 | Plans 01, 02 | Admin CSS resolves all type/line-height/letter-spacing/breakpoint/transition values from named ax-* tokens | SATISFIED | Zero literals in app.css; theme.css complete; breakpoint registry + guard |
| DSY-02 | Plan 02 | Dunning banner and invoice screens render via tokens, zero inline-hex fallbacks | SATISFIED | dunning_banner.ex has no style= attribute; refute assertion guards regression |
| DSY-03 | Plans 03, 04 | Maintainer can open /dev/components and see component-variants reference with token mapping | PARTIAL | Reference renders all 4 families with live swatches and token dl; BUT tokens listed for slate/ink variants are phantom tokens not defined in CSS, and cobalt lists wrong token names; drift test does not validate the tokens field |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `accrue_admin/lib/accrue_admin/dev/component_registry.ex` | 70 | `--ax-info` listed for cobalt — actual CSS uses --ax-accent | WARNING | Cobalt token mapping misleads maintainer; --ax-info is defined but is the wrong token |
| `accrue_admin/lib/accrue_admin/dev/component_registry.ex` | 82-83 | `--ax-neutral`, `--ax-neutral-readable` listed for slate — tokens not defined anywhere | BLOCKER | Phantom tokens; maintainer documentation is false; the reference page will show non-existent tokens |
| `accrue_admin/lib/accrue_admin/dev/component_registry.ex` | 88-89 | `--ax-ink`, `--ax-ink-readable` listed for ink — tokens not defined anywhere | BLOCKER | Same as above for ink variant |
| `accrue_admin/lib/accrue_admin/dev/component_registry.ex` | 111 | `--ax-info` listed for card/cobalt — actual CSS uses --ax-accent | WARNING | Same cobalt token mismatch in card family |
| `accrue_admin/lib/accrue_admin/dev/component_registry.ex` | 123 | `--ax-neutral` listed for card/slate — undefined | BLOCKER | Phantom token in card family |
| `accrue_admin/lib/accrue_admin/dev/component_registry.ex` | 129 | `--ax-ink` listed for card/ink — undefined | BLOCKER | Phantom token in card family |
| `accrue/test/accrue/docs/package_docs_verifier_test.exs` | 276-311 | seed_tmp_dir! missing adoption-proof-matrix.md | BLOCKER | Stripe-only absence guard silently passes in all negative-path tests |
| `accrue_admin/assets/css/app.css` | 1438-1450 | .ax-search-trigger retains multi-property transition literals | WARNING | 5th transition collapse site deferred; comment documents deferral to Phase D |

### Human Verification Required

#### 1. /dev/components Token Metadata Accuracy

**Test:** Open /dev/components in a dev environment with Fake processor configured. In the "Badges" and "Status" sections, inspect the token `<dl>` rows for slate/ink/cobalt variants.
**Expected:** After fixing CR-01, the page should show `--ax-border`, `--ax-muted` for slate; `--ax-primary` for ink; `--ax-accent`, `--ax-accent-readable` for cobalt. In the current codebase, the page shows `--ax-neutral`, `--ax-ink`, `--ax-info` which are inaccurate.
**Why human:** Token <dl> content is rendered server-side and only visible in a live browser; grep confirms phantom tokens in the data but visual confirmation of what maintainers see is not automatable.

#### 2. Dunning Banner Visual Rendering

**Test:** In a dev environment with a dunning-active customer, render the dunning banner.
**Expected:** The banner should display with the danger styling (red background, appropriate text color) entirely via .ax-banner.ax-banner-danger CSS class tokens, with no inline style fallback.
**Why human:** Computed CSS styles require browser rendering; the test only asserts absence of style= in HTML, not that the CSS class actually provides equivalent styling.

### Gaps Summary

Three gaps block goal achievement:

**Gap 1 (BLOCKER) — Phantom tokens in ComponentRegistry (CR-01 from review):** The `tokens:` field in 6 of 15 registry entries lists CSS custom properties that either do not exist in the design system (`--ax-neutral`, `--ax-neutral-readable`, `--ax-ink`, `--ax-ink-readable`) or are the wrong token for the variant (`--ax-info`/`--ax-info-readable` for cobalt, where the actual CSS uses `--ax-accent`/`--ax-accent-readable`). The ROADMAP SC-3 states maintainers should see the component-variants reference "alongside its token mapping" — phantom tokens mean the mapping is false. The drift test (174-04) only validates ax_class substrings, never the tokens field, so this inaccuracy is undetected by CI.

**Gap 2 (BLOCKER) — adoption-proof-matrix.md not seeded in PackageDocsVerifierTest (CR-02 from review):** `verify_package_docs.sh` line 304 runs a Stripe-only absence guard on `examples/accrue_host/docs/adoption-proof-matrix.md`. The test's `seed_tmp_dir!` never copies this file. The guard silently passes in all test-based verification runs because bash's `set -e` is suppressed inside `if` conditions. A PR reintroducing "Stripe-only" language in that file will not be caught by the verifier tests, only by running the script against the real repo (which is not part of the test-isolation path).

**Gap 3 (PARTIAL / WARNING) — .ax-search-trigger transition not collapsed:** The plan mandated 5 transition block collapses; only 4 were done. The 5th site (.ax-search-trigger) was correctly identified as having asymmetric speeds and flagged for Phase D per plan guidance. This is a plan deviation rather than a regression, but the plan frontmatter truth "All 5 multi-line transition blocks are collapsed" is not met. Since this was explicitly permitted by plan guidance and documented with a comment, this should be assessed as a WARNING rather than a BLOCKER — but it is listed in gaps for phase plan awareness.

Both BLOCKER gaps are in DSY-03 territory (Gap 1) and the CI invariant layer (Gap 2). Gap 1 directly undermines the DSY-03 requirement: "A maintainer opening /dev/components sees a component-variants reference enumerating every button / badge / status / card variant alongside its token mapping" — the token mapping is wrong for 6 of 15 entries. DSY-01 and DSY-02 are fully satisfied.

---

_Verified: 2026-06-03T22:00:00Z_
_Verifier: Claude (gsd-verifier)_
