# Phase 207: Orchestration + digest + one-command round/fix loop - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-04
**Phase:** 207-orchestration-digest-one-command-round-fix-loop
**Areas discussed:** Approve/reject mechanism, Guard auto-mint, Round/loop state + convergence, Subset filter + digest split (all four selected)

**Method:** The maintainer selected all four gray areas and directed a deep, multi-lens investigation
("research each using subagents… pros/cons/tradeoffs… idiomatic for Elixir/Phoenix… lessons from other
libs/apps even other languages… great DX… one-shot a perfect cohesive set of recommendations so I don't
have to think… consider the prompts research + current brandbook… all relevant lenses/roles"). Four
parallel `gsd-advisor-researcher` subagents each investigated one area against the live codebase + the
research corpus; their decisive recommendations were synthesized into the cohesive D-42..D-57 package in
CONTEXT.md. Per the maintainer's standing preference (only escalate truly irreversible/published forks),
the one flagged "impactful fork" (guard-mint realness) was resolved in-synthesis — this is dev/test-only,
fully-reversible internal tooling — with its residual risk documented rather than surfaced as a question.

---

## Approve / reject checkpoint mechanism (ORCH-03)

| Option | Description | Selected |
|--------|-------------|----------|
| A. File-driven `decisions.json` | `ui.round` writes pre-filled (approve-all) transient file under gitignored `test-results/`; maintainer flips rejects + reason; `ui.fix` reads it; durable record = suppress events in committed ledger | ✓ |
| B. Interactive stdin prompt | `Mix.Shell`/`IO.gets` loop in the mix task | |
| C. HTML-form writeback | Digest POSTs to a local endpoint the task serves | |

**Choice:** A. Rationale: matches the repo's 100%-non-interactive mix-task idiom (all three existing tasks
are `OptionParser` + `File` + no prompts); git-visible durable audit via the committed ledger suppress
event (not a drift-prone second artifact); replayable; batch-approve is the zero-edit path. B is anti-idiom
(breaks non-TTY, not replayable); C adds server lifecycle to a CLI tool. Reject requires a closed-enum
reason; `ui.fix` `Mix.raise`s on invalid/missing; loud pre-apply banner + `--dry-run` guard mass-approve.
(D-42, D-43)

---

## Guard auto-mint producer (ORCH-05) — the flagged impactful fork

| Option | Description | Selected |
|--------|-------------|----------|
| A. Fully-synthesized executable assertion per finding | Generator writes a complete runnable assertion block | |
| B. Scaffolded stub the maintainer tightens per finding | Human authors each guard's assertion | |
| C. Route by kind: typed DATA ROW + one human-reviewed loop (real synth where a crisp post-fix invariant exists, else `ledger-count`) | Generator emits data from the fresh re-capture; assertion logic reviewed once; taste → sentinel | ✓ |

**Choice:** C (the data-row refinement). Rationale: A carries HIGH wrong-assertion/false-CI/vacuous risk
and breaks §49 taste routing; B defeats the "minimal toil / sign-off not per-issue" north-star. C emits
*data* derived from the freshly re-captured post-fix DOM/CSS (never a guess — inverts the characterization-
test footgun), asserts invariants not pixels, routes taste/IA findings to the honest `ledger-count`
sentinel, and gets real CI teeth from the existing admin e2e Playwright job while the ratchet's own gate
stays substring-only. **Accepted residual risk:** the ratchet gate can't detect a gutted loop body — a
deliberate, review-visible edit, same honest-residual class as `ledger-count`. Resolved in-synthesis (not
escalated) because it is reversible dev/test tooling. (D-44, D-45, D-46)

---

## Round/loop state, dry-round detection, convergence + hard cap (ORCH-01/04/06)

| Option | Description | Selected |
|--------|-------------|----------|
| Derive round state from finding ledger alone | No new file | |
| Count gitignored `round-NN` dirs | Free, but non-reproducible on clean clone/CI | |
| Separate mutable `ui-ratchet-state.json` | Simple, but hidden mutable state that drifts | |
| New committed append-only `rounds.ndjson` | Sibling to `reopen-markers.ndjson`; supplies the one underivable fact (dry-ness) | ✓ |

**Choice:** committed append-only `rounds.ndjson`. Dry-ness is genuinely underivable from the finding ledger
(a dry round appends nothing). DRY = 4-clause conjunction (zero new open + zero open remaining + both
regression files 0 bytes + all slice cells ≥2). K=2 consecutive dry → CONVERGED; 6-round cap escalates
unmissably (banner + terminal next-action + non-zero exit). `ui.round`/`ui.fix` stay two separate manual
commands (Terraform plan/apply split); mix tasks are thin `System.cmd` orchestrators; all file-reasoning
lives in the node reducer. (D-47..D-51)

---

## Surface/slice subset filter (ORCH-08) + digest structure (ORCH-02) + prompt caching (ORCH-07)

| Option | Description | Selected |
|--------|-------------|----------|
| Filter: `--slice` preset + `--surface=csv` → shared `RATCHET_SURFACES` env (both capture + proposer filter) | Slice list defined once in `baseline-manifest.js` `SLICES` | ✓ |
| Filter: Playwright `--grep`/`--project` | Wrong granularity (one looping test) | |
| Digest: Node `.mjs` twinning `phase192-gallery.mjs` (self-contained HTML + `--self-test`) | Decisions-needed = `effort_class==="ia-product-decision"`; overlay from `.bbox.json`; deterministic ranking; brand-aligned | ✓ |
| Cache: `cache_control` breakpoints on system + tools + target-image, no reorder | Exemplar-first reorder deferred as follow-on toggle | ✓ |

**Choice:** all three as above. Filter threads through capture + fan-out via one env; digest twins the
proven self-contained-gallery idiom with deterministic decisions-needed/ranking predicates and
`.bbox.json`-driven region overlays, brand-voiced per the current `brandbook/index.html`; cache_control
drops onto the already-stable-prefix-first request with no reorder and provably no identity impact.
(D-52..D-57)

---

## Claude's Discretion

- `rounds.ndjson` separate-file vs folded `round_sealed` events → chose separate (pure finding-fold; mirrors
  `reopen-markers.ndjson`). The single mildly-hard-to-reverse committed-schema choice; noted for plan time.
- ORCH-07 exemplar-first reorder → deferred as a cheap same-phase follow-on toggle on top of the no-reorder
  baseline.
- `decisions.json` field ordering; optional aggregate TTY `yes?`; exact auto-guard marker syntax;
  `bundle_sha256` capture point; digest `data:` URI vs relative paths; precise banner copy.

## Deferred Ideas

- Convergence run + baseline FREEZE + CI wiring + maintainer ACCEPT + runbook → Phase 208 (CONV-01..07).
- Full ~19-surface sweep → Phase 209 (optional, SWEEP-01).
- ORCH-07 exemplar-first reorder for cross-screenshot exemplar caching → same-phase follow-on toggle.
