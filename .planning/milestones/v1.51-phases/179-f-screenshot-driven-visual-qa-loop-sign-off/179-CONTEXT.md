# Phase 179: F — Screenshot-Driven Visual QA Loop & Sign-off - Context

**Gathered:** 2026-06-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove the milestone's "done" with evidence: build a Playwright screenshot harness that sweeps the full screen inventory (all ~20 screens incl. detail pages, driven by the Phase 178 STATE-MATRIX) across {desktop, mobile} × {light, dark}; add an LLM-analysis step that scores each screenshot against the 10-dimension rubric and emits structured findings driving a remediation loop until no dimension scores below 2; produce a final SIGN-OFF scorecard showing every dimension ≥2 across all four matrix cells with before/after evidence; and re-run axe in both light and dark across the inventory. **This phase BUILDS the QA system and the sign-off scaffold, runs what is runnable autonomously (axe, screenshot capture when a server is available), and the vision-LLM photographic sign-off run is the single consolidated human/CI gate** that closes all deferred 175–178 visual UATs. Motion (177) needs trace/video review (static PNGs can't see it), so a Playwright trace capture for motion surfaces is included. **No new product screens/features.** Satisfies QA-01, QA-02, QA-03.

</domain>

<decisions>
## Implementation Decisions

Three areas proposed as a synthesized package grounded in the locked design source (`v1.51-admin-ui-depth-design.md` §4 Phase F) + a codebase scout, accepted as-is by the user (calibration: `minimal_decisive`). Scout findings: `accrue_admin/e2e/admin-visuals.spec.js` already shoots light+dark per screen (via the `/__e2e__/seed/<fixture>` + `/__e2e__/login` helpers + a data-theme toggle) but does NOT yet iterate mobile viewport; `admin-a11y.spec.js` already runs axe in light+dark; npm scripts `e2e:visuals:png-only` / `e2e:a11y` / `e2e:install` exist; there is NO LLM-scoring infra yet (the novel deliverable). The user explicitly accepted the build-vs-run boundary.

### Sweep harness scope & matrix (QA-01)
- **Screen-inventory source:** drive the sweep from the Phase 178 `STATE-MATRIX.md` — all ~20 screens + detail pages + the key seeded states the matrix makes reachable.
- **Matrix cells:** {desktop 1280×800, mobile 360px} × {light, dark} = **4 cells per screen** — extend the existing light/dark spec with a mobile viewport iteration (use Playwright projects or a viewport loop).
- **Detail + states:** include all detail pages + the **populated baseline plus the seeded empty/overflow/edge states** from the matrix where cheap.
- **Output:** `test-results/admin-visuals/` (gitignored), organized by cell — never commit PNGs.

### LLM-scoring & remediation loop (QA-02)
- **Scoring mechanism:** a **Node scoring script** (e.g. `accrue_admin/e2e/score-visuals.mjs`) that feeds each PNG + the 10-dimension rubric to a vision LLM and emits structured JSON findings. It runs in CI/locally with an API key — it is NOT executed inline during this autonomous build (no key / vision loop here).
- **Findings schema:** JSON `{screen, viewport, theme, dimension, score 0–3, defect, suggested_fix}`, aggregated into the scorecard.
- **Remediation loop:** findings <2 → fix → re-shoot → re-score, **capped at ~3 rounds**. Because Phase 176 already lifted all 21 screens to ≥2 at the code level (the 176-SCORECARD), expect minimal remediation; the loop is documented and the actual run is human/CI.
- **Executability boundary (locked, user-accepted):** this phase BUILDS the harness + scoring script + scorecard scaffold + a documented run procedure, and runs what is runnable here (axe, screenshot capture if a server is up). The vision-scoring photographic sign-off run is the **consolidated human/CI gate** that closes the deferred 175–178 visual UATs. Do NOT claim a full autonomous vision run happened if it did not.

### Scorecard, axe & milestone sign-off (QA-03)
- **Final scorecard:** a **SIGN-OFF scorecard** — every screen × 10 dims × 4 cells, before (seeded from the 176-SCORECARD) / after, all ≥2, with before/after evidence links.
- **axe both themes:** extend `admin-a11y.spec.js` to the full inventory + mobile + the seeded edge states; assert 0 critical/serious violations in light AND dark.
- **Motion trace (Phase 177 deferred here):** add a Playwright trace/video capture for the motion surfaces (drawer / command palette / dropdown / nav-collapse) so motion can be reviewed (static PNGs can't see it).
- **Milestone "done" artifact:** a **v1.51 SIGN-OFF.md** (phase dir) aggregating: 176 rubric (21/21 ≥2) + 177 motion + reduced-motion + 178 state coverage + axe both themes + the screenshot evidence — the proof the milestone audit consumes.

### Claude's Discretion
- Exact Playwright projects/viewport-loop structure for the 4 cells; whether mobile is a separate project or an in-test loop.
- The scoring script's exact CLI/API shape (which vision model, how PNGs are batched) — provided the findings JSON schema is honored and an API key is the only missing runtime input.
- The exact set of seeded states swept per screen (baseline always; edge states per the matrix where cheap).
- Whether the motion trace is a dedicated spec or a flag on the visuals spec.
- The SIGN-OFF.md exact layout, as long as it aggregates the four prior phases' evidence + axe + screenshots into one milestone "done" proof.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`accrue_admin/e2e/admin-visuals.spec.js`** — `seed(request, fixture)` POSTs `/__e2e__/seed/<fixture>`; `/__e2e__/login?to=` for auth; captures light (`${name}.png`) + dark (`${name}-dark.png`) via the `data-theme` toggle, `fullPage: true`. Extend with a mobile viewport iteration + full inventory from the STATE-MATRIX.
- **`accrue_admin/e2e/admin-a11y.spec.js`** — axe (`@axe-core/playwright`) in light+dark, kills transitions for stable colours; asserts no critical/serious. Extend to full inventory + mobile.
- **npm scripts:** `e2e:visuals:png-only`, `e2e:a11y`, `e2e:install` (chromium). Add a `score-visuals` script for the LLM step.
- **Phase 178 `STATE-MATRIX.md` + the `/__e2e__/seed/<fixture>` fixtures** (operator-flows, edge-states, overflow) — the reachability substrate the sweep consumes.
- **Phase 176 `176-SCORECARD.md`** — the before-scores (21/21 ≥2) that seed the SIGN-OFF scorecard's "before" column.

### Established Patterns
- Custom `ax-*` CSS (no Tailwind). Committed asset bundle — if any remediation touches CSS/JS, run `cd accrue_admin && mix accrue_admin.assets.build` + commit `priv/static`.
- The E2E plug + login + seed endpoints are test/dev-only (compiled under `MIX_ENV=test`, excluded from the Hex package) — the sweep uses them; they must stay test-only.
- 262 admin tests + host tests green — do not regress.

### Integration Points
- The screenshot sweep consumes `/__e2e__/seed/<fixture>` (178) + the STATE-MATRIX rows; the scoring script consumes the PNGs + the rubric; the SIGN-OFF.md consumes the 176/177/178 evidence + axe + shots.
- The milestone audit (post-179) consumes the SIGN-OFF.md as the "done" proof.

</code_context>

<specifics>
## Specific Ideas

- **Authoritative design source:** `.planning/research/v1.51-admin-ui-depth-design.md` — §4 Phase F scope (lines 113–118), §6 the 10-dim rubric + verification commands (`npm run e2e:visuals:png-only`, `admin-a11y.spec.js`), §7 guardrails ("Motion needs trace/video review (static PNGs can't see it)"). Downstream agents MUST read it.
- **This phase produces the milestone's "done" evidence** — the SIGN-OFF.md consolidates all five prior phases (174 tokens, 175 IA, 176 rubric, 177 motion, 178 seed) + axe + screenshots.
- **Deferred 175–178 visual UATs** (in each phase's `*-HUMAN-UAT.md`) are the items the vision-scoring sign-off run closes — reference them.
- **Verification:** `cd accrue_admin && mix test --seed 0` (262 green — do not regress); `npm run e2e:a11y` (axe, light+dark); `npm run e2e:visuals:png-only` (capture — needs a live server); the scoring script + SIGN-OFF.md scaffold present. Admin mounts at `/billing`.

</specifics>

<deferred>
## Deferred Ideas

- **The actual vision-LLM photographic sign-off run** (capture 80+ shots across 4 cells, score them, remediate, human-review the scorecard) — this is the consolidated human/CI gate this phase scaffolds. It runs after the build, with a vision-model API key + a live server.
- Any product feature work — out of scope; this is pure QA tooling + evidence.
- Re-doing the rubric/motion/seed work — those are done (174–178); 179 only verifies + remediates anything the photographic pass surfaces below bar.

*Discussion stayed within phase scope — QA harness + scoring + sign-off evidence; the heavy build is runnable, the photographic run is the human gate.*

</deferred>

---

*Phase: 179-f-screenshot-driven-visual-qa-loop-sign-off*
*Context gathered: 2026-06-04*
