# UI quality engine: design and verification recommendation

Date: 2026-10-26. Status: research for a reviewed proposal; no product implementation or milestone activation.

## Recommendation

Extend the existing Storybook, token, copy, browser and visual machinery around **real production-owned compositions**, with a small recurring review loop. Start with the subscription investigation/change job, prove one useful area end to end, then extend through its collection toolbar/table. Keep mounted acceptance for behavior that needs LiveView, authorization, database state, hooks or navigation. Storybook should make these compositions inspectable; it must not become a second implementation of them.

Use broad scenario inventory and narrow, deliberate rendering coverage. A full Cartesian product is neither a reliable UX audit nor a sensible PR gate. Protect deterministic defects automatically, retain a few stable visual baselines, and make agent design review bounded and advisory. The owner's taste calibrates the system; it is not a recurring confirmation gate for machine-proven behavior.

This is a source-inspection recommendation. No browser was launched, screenshot visually assessed, current CI duration measured, or claim of present visual/UX conformance established in this research.

## Existing machinery: adopt, extend, new

| Layer | Disposition | Source evidence and consequence |
|---|---|---|
| Brand palette and semantic roles | ADOPT-EXISTING | `brandbook/tokens/tokens.json`, generated `tokens.css`, harness generator/parity/verifier and `brandbook/tokens/README.md`. The JSON is already DTCG v2025.10. Do not invent another token format or generator. |
| Admin implementation scales | ADOPT-EXISTING | `accrue_admin/assets/css/theme.css` owns `--ax-*` type, spacing, radius, layers, focus and motion. Brandbook explicitly calls these **reference-only** in brand JSON. |
| Admin/Portal ownership and target | ADOPT-EXISTING | `.planning/milestones/v1.63-phases/233-shared-direction-portal-contract/DESIGN.md`: semantic roles shared, styles and density package-owned; Admin is Geist/operator-dense, Portal host-branded. |
| Copy owners and brand voice | EXTEND | `brandbook/voice.md`, `brandbook/copy.md`, `accrue_admin/lib/accrue_admin/copy.ex`, related copy modules and generated copy strings. Add an audience-scoped UI glossary and scenario assertions beside these owners; do not lint developer docs using customer vocabulary. |
| Token and contrast checks | EXTEND | `scripts/ci/verify_foundation_contrast.mjs`; `accrue_admin/e2e/foundation-tokens.spec.js`; brand token harness. Existing static checker covers 17 semantic pairs in four scopes; use it instead of implementing new contrast math. Its simple parser is not a full rendered compositing oracle. |
| Storybook browser scan | EXTEND | `accrue_admin/e2e/admin-storybook-a11y-phase200.spec.js` + `phase200-storybook-helpers.js`: DOM URL discovery, served asset checks, settled light/dark, `.psb-sandbox` axe scan. Current scan runs desktop only and reduced motion; tags are `wcag2a`, `wcag2aa`; only critical/serious violations block. It does not prove every variation or state. |
| Registry/kitchen parity | ADOPT-EXISTING, then selectively EXTEND | `scripts/ci/verify_phase200_admin_guardrails.sh` explicitly runs registry/group drift tests and mounted group contracts. Keep the `/dev/components` renderer until a measured replacement preserves these purposes. |
| Browser interaction and mounted journeys | ADOPT-EXISTING | 24 `*.spec.js` files under `accrue_admin/e2e` at inspection. Existing group, page-flow, overlay, reduced-motion and mounted-host lanes own different behavior; do not reimplement all of them as generic sweeps. |
| Pixel regression | EXTEND selectively | `accrue_admin/e2e/visual-baseline-set.cjs` enumerates 12 PNGs, six surfaces × light/dark, present under `e2e/__screenshots__/visual-desktop`. `admin-visual-regression-phase211.spec.js` uses targeted timestamp masks and preserves identity/money/state/actions. Extend this owner for the first selected composition. |
| CI | EXTEND | `.github/workflows/ci.yml` `admin-phase200-guardrails`, `.github/workflows/accrue_admin_browser.yml` Browser UAT/visual jobs and existing host-integration proofs. Preserve ownership and path classifier coverage when root `storybook/`, tokens or manifests change. |
| Design rubric and decision history | ADOPT-EXISTING as reference | `accrue_admin/e2e/ratchet/DESIGN-LENS-RUBRIC.md`, provenance, ledgers and historical review evidence. The paid proposer uses an Anthropic key/model and remains parked. |
| Scenario-to-check metadata and triage | NEW, small extension | Add stable situation/actor/job/composition/caller/capability/variant IDs and check selection to existing registry/manifest owners. Add narrowly scoped finding dispositions only where existing evidence formats cannot hold them. No new quality platform. |

Count method: `rg --files accrue_admin/e2e | rg '\\.spec\\.js$' | wc -l` yielded 24; `rg --files accrue_admin/e2e/__screenshots__ | wc -l` yielded 12. The 17 static contrast pairs are seven `basePairs` plus five status text/background and five solid-status pairs, each evaluated across the four declared scopes. These are source counts, not executed passing checks.

## Locked decisions and methodology reconciliation

| Methodology statement | Existing authority | Disposition |
|---|---|---|
| “One source of truth for tokens, e.g. the brandbook.” | `brandbook/tokens/README.md`: “Typography, spacing, radius, focus-ring, and state tokens are **reference-only** in the brand layer.” | Keep established split ownership. Brand JSON generates brand roles; Admin `theme.css` owns implementation scales. Semantic consistency does not require every value in one file. |
| “Any second inventory ... gets ported, then retired.” | `.planning/PROJECT.md` v1.54: “The in-app `/dev/components` kitchen remains a second renderer backing drift tests.” | Make Storybook the preferred review entry. Generate the catalog from one registry, but retain the mounted renderer until its independent parity/interaction purpose has an equivalent owner. Retirement is a later explicit change, not an initial cleanup assumption. |
| “Ban ... inline `style=` ... raw hex ... arbitrary values.” | Current brand/host bridge, style tokens, breakpoints and intentional CSS exceptions in `app.css`; `DESIGN.md` keeps arbitrary host accent inputs. | Apply token discipline by semantic property and owner. Allow documented host-brand values, dynamic geometry and justified exceptions. No Tailwind reset: Admin uses custom `ax-*` CSS; a new utility migration is outside scope. |
| “L4 LLM design judge” and “L5 Owner.” | `.planning/PROJECT.md`: “v1.56 (Admin UI Ratchet) remains PARKED”; v1.64 excludes “parked paid-AI ratchet revival.” `CLAUDE.md`: “post-hoc human verification and manual UAT are not completion gates.” | Reuse rubric/calibration/disposition history for a fixed, on-demand agent review. No paid API/critic service or new CI judge; no repeated owner sign-off on automated outcomes. Subjective direction is captured once; confirmed bugs become ordinary owned work. |
| Globally ban internal vocabulary | `PRODUCT.md` gives engineers and operators equal primary standing; `brandbook/voice.md` developer voice uses “Ecto,” “telemetry,” “append-only ledger.” | Scope verbal tokens by audience and disclosure level. Routine operator/customer labels use their nouns; exact event keys, identifiers and technical diagnosis remain available in deliberate disclosure and copy controls. Do not strip useful engineering evidence. |
| Every page × every viewport × every theme × all states | Existing bounded-review rule in `.planning/PROJECT.md` and serial fixture-backed browser owners | Keep exhaustive **inventory accounting**; select representative renders and interactions by risk and impact. Expand independently runnable pure stories only after measuring their cost. |

The broad new owner request authorizes researching and proposing a stronger ongoing quality strategy. It does not silently erase brand identity, package boundaries, provider support or evidence rules. Historical screenshots calibrate taste only after checking source/capture provenance; they are not current visual truth.

## L1–L5: what to retain and correct

### L1: fast structural checks, useful scope

- Extend existing token/asset/copy parity tests. A syntactic ban on every literal would reject legitimate `0`, `auto`, border widths, inherited values, CSS calculations and dynamic positions without detecting bad hierarchy. Check newly introduced bypasses for the controlled properties, with owner/reason/reference for exceptions.
- Check **allowed semantic foreground/background pairs**, not every palette pair. An all-pairs matrix flags intentionally unused combinations and decorative colors. Cover text sizes/weights, essential boundaries and focus against actual adjacent backgrounds. Keep static role checks and targeted browser computed-style checks complementary.
- Do not write another generic CSS color parser. Current contrast helpers accept only bounded forms and omit alpha compositing. Inherited backgrounds, gradients, `color-mix()`, opacity and host accents require browser resolution and explicit compositing or a focused rendered check. A null/unsupported color is unverified, not a pass.
- Enforce glossary/voice rules on library-authored UI strings and accessible names. Keep locked legal/replay meaning and raw evidence unchanged. Sentence case and verb-led action labels are defaults, not regexes that outlaw noun tabs, grammatical translations or proper names.
- Check manifest determinism, nonempty selection, valid variation IDs, known composition/caller links, descriptions and no silently omitted story roots. Give each detector a failing fixture/negative control before trusting a zero-result scan, per `CLAUDE.md`.

### L2: generic sweeps complement interaction contracts

- Produce an explicit variation manifest using the installed Storybook API, cross-check it with mounted discovery, and exercise the bare supported story/iframe route. A parent page may show multiple variations; a page URL alone is not variation coverage. Record actual selected counts and skipped/nonapplicable reasons.
- Expand axe tags to the installed engine's supported WCAG 2.1/2.2 AA tags. Block new unwaived violations regardless of arbitrary severity filtering; migrate existing findings with narrow fingerprints and reasons. Store `incomplete` as **needs investigation**, not compliance failure or pass: axe defines it as undetermined. For important unresolved items, add a deterministic targeted assertion where feasible. An empty axe result cannot certify a workflow. [Playwright accessibility](https://playwright.dev/docs/accessibility-testing), [axe results API](https://github.com/dequelabs/axe-core/blob/develop/doc/API.md).
- Capture `pageerror`, unexpected console errors and failed required assets. Do not blanket-ignore warnings or simulated expected errors; classify known injected failures by scenario and assert their corresponding recovery.
- Test 320 CSS px reflow and the breakpoints actually used (e.g. 640/768/1024) with boundary widths just below/at/above where the component changes layout. Add 375 and wide desktop representatives. Tables and code may have a deliberate local scrolling region while the page stays usable; a simple `scrollWidth` check does not decide the full WCAG rule. [WCAG reflow](https://www.w3.org/WAI/WCAG21/Understanding/reflow).
- A 200% root-font injection is a useful **text stress** check but does not equal browser zoom or prove Resize Text. Track 200% text enlargement and 400%-equivalent reflow separately; fixed-pixel text can escape root-font stress. Check content and function, not merely rectangles. [WCAG Resize Text](https://www.w3.org/WAI/WCAG21/Understanding/resize-text).
- Validate target size with the standard's exceptions: 24 × 24 CSS px is the WCAG 2.2 AA base target, with spacing/equivalent/inline/user-agent/essential exceptions. Comfortable high-use mobile actions may target 44px by design without claiming that every inline link must be 44px. [WCAG target size](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum).
- Focus checks need representative interaction contracts for Tab/Shift-Tab, menus/dialogs, roving focus, Escape, trap release and return. Merely changing computed style does not prove a visible ring or sensible order. Check visible contrast separately from **2.4.11**, whose AA requirement is that author content does not entirely hide the focused component; do not mislabel it as a universal 3:1 rule. [WCAG Focus Not Obscured](https://www.w3.org/WAI/WCAG22/Understanding/focus-not-obscured-minimum).
- Navigation ARIA trees should be **contextually consistent**, not byte-identical: `aria-current`, permission-derived entries, account selection and collapsed mobile presentation legitimately differ. Assert stable permitted destinations, labels, ordering within each shell, current-page truth and absence of forbidden routes. Preserve the mount prefix.
- Reduced motion is an orthogonal interaction condition, not a second copy of every static screenshot. Run normal-motion lifecycle and reduced-motion behavior on motion owners, plus representative composed route checks. A reduced-motion-only scan misses interruption and cleanup defects.
- Use token membership checks at the owning role/component, not an every-element whitelist of computed values. `rem` resolution, zoom, interpolation, responsive geometry, `none` and inherited defaults otherwise produce noise. Check that production and story share the owning component and served CSS/JS first.

### L3: selected visuals, stable and reviewable

Extend the existing Linux baseline owner. Preserve its six-surface × two-theme set; add one selected production composition and its significant failure/boundary state at narrow and desktop sizes only when this detects a recurring risk. A screenshot assertion detects difference, not design quality. Changes need a source/scenario/theme/viewport/served-asset record and a deliberate reviewed update.

Pin browser/OS/container/font inputs, wait for fonts, use deterministic clock/locale/fixtures and disable motion for pixel comparisons. Prefer deterministic fixture times over broad masking. If masking is needed, keep the existing precise volatile-substring strategy: never mask action/error/money/identity facts to turn a failure green. Current config uses `threshold: 0.2` and `maxDiffPixelRatio: 0.01`; do not widen these to absorb a real change. [Playwright visual comparisons](https://playwright.dev/docs/test-snapshots).

The parent review inspected the committed subscription-detail light/dark goldens and observed a synthetic E2E customer, many unavailable facts and dense/repeated audit sections. This is historical-capture evidence, not a current mounted defect claim. It supports separating a representative richly populated subscription story from an intentional incomplete-evidence case. Magenta timestamp-mask pixels serve mechanical comparison only; use unmasked deterministic captures for design judging so capture artifacts do not become taste findings.

### L4: bounded advisory design review

Use the existing 12-dimension rubric and brandbook as the starting vocabulary. Do not add another scored-cell universe or claim that taste is proven by a judge. A session review receives current selected renders, scenario/persona/job, actual interaction evidence, rendered copy/accessibility tree, known locked decisions and L1–L3 findings. It reports only new evidence-backed design/IA/copy concerns, owned at token → primitive → pattern → area → page → copy level.

One batched review, one coherent correction batch and one confirmation pass are sufficient unless a named defect changes the scope. Record `pass/fail/n.a./unverified` per applicable criterion, evidence and limits; do not invent “award-winning 9/10” scores. Pairwise head/main assessment may reduce position bias but should be reserved for consequential visual changes, not multiply every routine story into four model passes.

Owner-labelled historical examples may calibrate this review, but stale captures remain historical and a tiny example set cannot support a precision/FPR statistic. Report sample sizes and uncertainty before promoting a repeated judgment into a deterministic rule. No new model dependency, API key, paid CI inference or open-ended critic loop.

### L5: durable owner intent, narrow dispositions

Record owner judgments about direction and disputed findings once. Rejection suppresses the **same evidence/context fingerprint**, not a whole issue class forever. Changes to source, shell, scenario, viewport or theme that materially affect the rationale may invalidate a suppression. Include owner, rationale, scope and a review trigger; a false-positive suppression and acceptance of a real defect are different dispositions.

A baseline should shrink in known debt, but cannot literally prohibit all new entries: a new rule or newly covered surface can reveal old unmeasured debt. Keep that explicit admission record, prohibit worsening existing fingerprints, and fail new regressions. Never rebaseline silently or call an unmeasured item fixed.

## PR budget and coverage proposal

These are **provisional acceptance targets to measure in the first slice**, not observed timings or promises:

| Loop | Initial selection | Target and action if exceeded |
|---|---|---|
| Local edit | One situation/variation, both themes at current size; nearest boundary when layout changed | Aim for <10s warm render/check response. If slow, separate pure presentation from data/mount work before adding infrastructure. |
| Fast contracts | Fixture invariants, manifest/drift, package exclusion, copy/token contracts | Aim for <30s incremental local, <60s warm CI. Publish durations and fail missing coverage independently of this target. |
| Incremental PR browser work | Changed scenarios plus consumers of changed primitive/token; selected at 320 and 1280 light/dark, with layout-boundary/normal/reduced-motion checks only where relevant | Aim for ≤3min additional warm browser execution and ≤5min incremental CI critical-path impact. Measure p50/p95 separately from setup. Do not weaken existing required suites to meet this budget. |
| Baseline comparison | Existing selected 12 PNGs, plus agreed first-slice narrow/desktop selected state(s) | Keep existing required comparisons. Track added baseline count, time and changed pixels. No auto-accept. |
| Full broad sweep | All reachable manifest variations at agreed widths/themes; focused zoom/motion/interaction owners; host route sentinels | Manual or scheduled initially with explicit completeness/failure artifacts; graduate stable, affordable portions to PR. Aim for ≤15min new pure-story sweep after measurement, not a global timeout increase. |

For example, 60 reachable variations × five widths × two themes is 600 render cells before interaction/zoom/motion. At an illustrative 0.5s/cell that is five minutes; at 2s/cell it is twenty. Neither timing is measured here. Avoid hiding them in one giant Playwright test: the present Storybook scan is one 120-second serial loop, and `playwright.config.js` sets `fullyParallel: false`, `workers: 1`. File-level sharding will not divide that loop. Pure presentation cases can become independently schedulable tests, but fixture-backed host tests reset shared data and must remain isolated until independent test databases/namespaces are proved. [Playwright sharding](https://playwright.dev/docs/test-sharding).

Selection must be conservative and auditable. Record selected/total IDs and why; shared tokens or foundational components may impact the entire consumer set, not only files directly edited. Keep sentinel journeys even on a nominally empty impact map. Treat missing/ambiguous dependency metadata as broad selection, not zero tests.

## Practical design rubric

**M** = deterministic machine check; **A** = bounded advisory agent assessment; **O** = owner direction for genuine taste/strategy decisions. O does not mean repeated manual UAT.

| Bar | M: recurring evidence | A: interpretation | O: direction |
|---|---|---|---|
| Light/dark are restrained and readable | Theme/asset parity; actual semantic contrast; selected screenshots | Color hierarchy and status emphasis suit the task | Preserve established Cobalt/quiet-confidence identity; no rebrand |
| Typography looks intentional | Correct fonts loaded; roles/scales and wrapping; long amounts/IDs; 200% stress | Heading rhythm, optical density, measure and emphasis | Calibrated examples of the desired professional finish |
| Information hierarchy is clear | One local primary action; heading relationships; disclosure/control contracts | Answer-first scan path; useful summary before evidence | Consequential task-priority fork only |
| Redundancy is absent | Detect repeated exact labels or contradictory count/state facts where meaningful | Distinguish useful reinforcement from duplicated chrome | Resolve genuinely disputed semantic duplication |
| Happy path and power use work | Job transitions, keyboard shortcuts, context-preserving return, loading/error recovery | Appropriate density and discoverability for operator/customer | New workflow or capability choice |
| Microcopy is consistent and truthful | Existing copy SSOT, accessible names, locked terms, result/effect assertions | Concision, recoverability, coherent user-facing domain language | Voice changes only; preserve existing voice |
| Personas/JTBD remain coherent | Every scenario names actor, billed entity, task, capability and provenance; fixture invariants | Scenario plausibility and distinct coverage value | Real adopter priority changes |
| Navigation feels natural | Scoped destinations, fresh authority, return state, current-page semantics, no dead ends | Journey cohesion and least surprise | IA strategy change outside existing surfaces |
| Mobile-first works across widths | 320px reflow, actual breakpoint boundaries, target/keyboard/zoom conditions | Deliberate stacking and information priority, no cramped desktop squeeze | Product tradeoff only where no sensible equivalent exists |
| System components pay off | Production/story component identity, shared pattern contracts, consumer coverage | One familiar pattern per job; appropriate restraint and affordance | Rare direction decision; fix shared owner instead of page patches |

## Ordered rollout and adversarial stopping rule

1. **Immediate:** agree actor/job/scenario metadata and first subscription composition, extend the existing story coverage contract and fixture invariants, render current real component in both themes at 320/desktop, test one real mounted interaction, and produce baseline timings. This proves value without a token migration or judge project.
2. **Near:** subscription collection toolbar/table and its meaningful empty/one/many/page-boundary/error states; shared pattern consumer checks, targeted copy/contrast fixes and the smallest useful visual baseline expansion. Fix confirmed findings at their lowest owning tier.
3. **Mid:** propagate the proved method to customer/invoice/payment/recovery/webhook jobs, with explicit mounted states and tenant/provider safety; curate redundant story groups and add Portal host-brand/context examples after the Admin foundation is measured.
4. **Long:** widen reachable composition coverage and optional browser-engine/device sentinels when real failures justify them, refine dependency-aware selection and calibrated advisory review. The outcome is sustainable coverage and better UI, not maximal story or baseline counts.

Adversarial objections and dispositions:

- **“This is another machinery milestone that never improves UI.”** Require the first slice to close named current design/behavior defects through the real composition and show the correction in a before/after evidence pair. Stop framework expansion until that value is observed.
- **“Storybook permits beautiful lies.”** Require shared production components plus reachable scenario provenance and mounted behavioral sentinels. Presentation stories never assert authorization, provider completion or persistence.
- **“A great mobile story can still fail at 641px.”** Add breakpoint boundary checks for affected layouts; sample intermediate widths when real content changes fit. Do not claim continuous-width proof from five presets.
- **“Generic automation will punish intentional design.”** Use semantic role ownership, explicit exceptions and actual rendered evidence. False-positive-heavy rules remain advisory until calibrated.
- **“The agent will over-whitespace our dense operator UI.”** Existing design lens penalizes both cramped and wasteful layouts. Compare to current valid operator density and job completion, not marketing-page taste or iOS visual imitation.
- **“Small helpers accumulate into an inaccessible home-grown framework.”** Reuse current helpers; copy only tiny well-understood code with tests/provenance. Security-sensitive parsing, accessibility semantics and mature browser tooling stay with existing maintained libraries. No new dependency unless a measured gap justifies ownership/maintenance cost.
- **“Suppressions hide regressions.”** Bind them to narrow fingerprints/context and preserve negative controls. No blanket selector/rule disables, no unreviewed baseline updates.
- **“Pruning erases boundary protection.”** Retire only after identifying impossible/duplicate/obsolete reachability and its remaining owner. Valid adversarial fixture controls may stay as non-user-facing tests even when removed from review stories.

Stop additional research when it no longer changes the first slice, a safety boundary, a coverage claim, or CI cost. Open a focused question only for irreversible action, brand/IA strategy, or removal of an adopter-visible surface; implementation details should follow these recommendations.

## Sources and evidence limits

Primary sources consulted 2026-10-26: [Playwright accessibility testing](https://playwright.dev/docs/accessibility-testing), [visual comparisons](https://playwright.dev/docs/test-snapshots), [sharding](https://playwright.dev/docs/test-sharding), [axe-core API](https://github.com/dequelabs/axe-core/blob/develop/doc/API.md), [WCAG target size](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum), [Focus Not Obscured](https://www.w3.org/WAI/WCAG22/Understanding/focus-not-obscured-minimum), [Resize Text](https://www.w3.org/WAI/WCAG21/Understanding/resize-text), [Reflow](https://www.w3.org/WAI/WCAG21/Understanding/reflow). Apple typography documentation was attempted but the returned page required JavaScript and its Markdown link errored; no Apple-specific technical claim depends on that unavailable content.

All local file statements above come from source reads and the stated file counts. Existing baseline files are present; their current visual quality and all-route coverage were not verified here. Existing source-side scripts are evidence of intended CI ownership; this research did not re-run them or live-read Actions status.
