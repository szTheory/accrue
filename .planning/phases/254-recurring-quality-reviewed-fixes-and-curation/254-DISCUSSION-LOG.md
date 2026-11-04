# Phase 254 Discussion Log

**Date:** 2026-10-27
**Mode:** Advisor (calibration `minimal_decisive`) overridden by explicit owner direction: fan out across specialist lenses, adversarial pass, primary sources, synthesize coherent one-shot recommendations and auto-follow them. Human reference only; downstream agents read `254-CONTEXT.md`.

## Areas researched (parallel gsd-advisor-researcher agents)

| Area | Options compared | Selected | Key reason |
|---|---|---|---|
| CIQ-02 selection & sentinels | per-case `depends_on` + fail-closed selector / always-full + report / tool-derived graph (`--only-changed`, Nx/Turbo) | per-case `depends_on` + fail-closed (D-09..D-14) | Extends CIQ-01 classifier; tool graphs fail open or can't see Elixir/CSS; isolation via 403 capability, not serial mode |
| CIQ-03 visual baselines | new spec in existing `visual-desktop` owner on DB-free story routes / re-seed mounted / second owner in phase252 config / DOM snapshots | existing owner + story routes (D-15..D-20) | Only option inside the "existing Linux owner"; fixed clock removes masks; identity manifest answers dead-CSS history |
| CIQ-04 cost & budget | committed budget + reporter timings, structure gated/timing warned / hard timing gate / jobs-API only / local only | budget JSON, structure-gated, timing-warned (D-21..D-25) | ~20% same-machine noise makes hard timing gates flap; reuses Phase 226/227 tools |
| UXQ-02 accessibility | a11y layer on 253 cells + mounted keyboard journey + disposition register / inline exceptions in admin-a11y spec | layer + journey + register (D-26..D-30) | Today: severity filter suppresses moderate/minor, `incomplete` never read, `wcag22aa`/`wcag21aa` tags absent |
| UXQ-04 design record | typed JSON + generated MD + verifier / markdown frontmatter / re-run gsd-ui-review | typed JSON record (D-31..D-36) | Must bind capture/asset digests; ui-review scores violate "no aesthetic score" |
| CURATE-01/02 | compiled ledger in `SubscriptionManifest` + verifier / hand-written CURATION.md / tombstones | compiled ledger (D-37..D-43) | Digest-bound, mechanically enforceable; tombstones = metadata-only coverage forbidden by SBK-02 |

## Cross-area conflicts resolved

- Budget research proposed baselines/a11y before design fixes; visual and design research showed minting first would freeze the compressed "Visuals 2/4" rhythm. Resolved: correct (W4) → mint once (W5) → confirm (D-08).
- Visual and design captures overlap: settled cells shared; mounted routes for review-open/focus (D-33).
- Story-route captures use `storybook.css`, not production CSS: assert embed bytes + keep mounted Phase 211 captures (D-07, D-15).

## Facts surfaced (source-grounded, not runtime-verified unless stated)

- Local measurement (dev Mac): Phase 252+253 gates ≈ 7 min > provisional 5 min; never run on a CI runner (D-24).
- Branch has no upstream; first CI observations need an owner-confirmed push (D-25).
- H1 finding from 253 review was half-wrong (responsive 24→28px); disclosure 20px is a valid scale step → contract amendments, not CSS changes (D-34).

## Owner questions

None asked: no one-way decision surfaced. The single outward-facing step (first push for CI measurement) is captured as an execution-time confirmation (D-25).

## Deferred

See `254-CONTEXT.md` `<deferred>`.
